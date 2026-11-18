--!strict
--[[
	CardSales: the name card's other styles sold at the counter (S5-03g3d, D-360), beside the
	furniture. The moment: you see a friend's neon card glowing over their door, buy one at the
	counter, and the next time you open Arrange its chip is yours. The styles, prices and the buy's
	rules are `Home.CardSale`'s.

	`BuyCard` (`CardSale.Remote`, a style's id) is rate-limited before its payload is read, then
	checked (`CardSale.ask`: a style the counter sells). A cash style is bought as the furniture is
	(Furnishing): one buy at a time per player ("busy"), the price taken and the style added in one
	step (`CardSale.buy`), the save written at once, and only then is the buyer told
	(`CardSale.BoughtRemote`: the id, their cash, "" or why not); a write that fails undoes it whole
	("save"). The neon goes through Roblox's prompt from here (Purchasing's `prompt`, which refuses
	it once owned: "had"), answered "closed" when shut unbought and "" once its grant is written
	(`Products`' row owns it in the save Brix writes first). In Studio with no product of its title,
	Purchasing's `DevReceipt` runs the real grant from a made-up receipt.

	Every change to what a player owns is put on their Player (`CardSale.Attribute`), so the paint
	tab's marks (LooksTab) go the moment it's saved. `CardShelf` (a RemoteFunction) answers the
	counter's screen your cash, your styles and the neon's price on Roblox. In Studio,
	`ServerStorage.CardTest:Invoke(player, id)` buys as the remote does, unthrottled; `(player,
	id, false)` takes a style away again, for a fresh test.
]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brix = require(ReplicatedStorage.Brix)
local CardSale = require(ReplicatedStorage.Shared.Home.CardSale)
local Purchasing = require(script.Parent.Purchasing)
local Saving = require(script.Parent.Saving)

local REMOTE_FOLDER = "Remotes"
local STUDIO_TEST = "CardTest"
local STUDIO = RunService:IsStudio()
-- Seconds the neon's Roblox price is kept before it's asked for again.
local PRICE_FRESH = 60

local CardSales = {}

export type CardSalesSystem = Brix.System

function CardSales.new(): CardSalesSystem
	local connections: { RBXScriptConnection } = {}
	local signals: { Brix.SignalConnection } = {}
	local made: { Instance } = {}
	local limit = Brix.RateLimit.bucket(CardSale.Limit)
	local shelfLimit = Brix.RateLimit.bucket(CardSale.ShelfLimit)
	local saving: Saving.SavingSystem? = nil
	local purchasing: Purchasing.PurchasingSystem? = nil
	local bought: RemoteEvent? = nil
	local buying: { [Player]: true } = {} -- a cash buy's write is out
	local prompted: { [Player]: string } = {} -- the Robux style whose prompt is up
	local prices: { [Player]: { [string]: number } } = {}
	local pricedAt: { [Player]: number } = {}
	local fetching: { [Player]: true } = {}

	-- What `player` owns, on their Player for their screens.
	local function mark(player: Player)
		local data = if saving then saving:data(player) else nil
		if data and player.Parent then
			player:SetAttribute(CardSale.Attribute, CardSale.encode(data.cards))
		end
	end

	local function answer(player: Player, id: string, why: string)
		local data = if saving then saving:data(player) else nil
		local remote = bought
		if remote and player.Parent then
			remote:FireClient(player, id, if data then data.cash else 0, why)
		end
	end

	-- Buys cash style `id` for `player`: "" once bought and written, else why not. Yields.
	local function buy(player: Player, id: string): string
		local s = saving
		local data = if s then s:data(player) else nil
		if not (s and data) then
			return "notLoaded"
		end
		if buying[player] then
			return "busy"
		end
		local refusal = CardSale.buy(data, id, os.time())
		if refusal then
			return refusal
		end
		buying[player] = true
		local problem = s:save(player) -- yields while the store answers
		buying[player] = nil
		if problem then
			CardSale.unbuy(data, id) -- undone whole: the next write keeps neither
			warn(`CardSales: {player.Name}'s {id} undone, the save wasn't written: {problem}`)
			return "save"
		end
		mark(player)
		if STUDIO then
			print(`CardSales: {player.Name} bought the {id} card, cash now {data.cash}`)
		end
		return ""
	end

	-- Puts Roblox's prompt for Robux style `id` (offer `offer`) up for `player`: nil once it's up
	-- (or Studio's made-up receipt is out) and the grant answers; else why not. Yields.
	local function prompt(player: Player, id: string, offer: string): string?
		local data = if saving then saving:data(player) else nil
		if not data then
			return "notLoaded"
		end
		if data.cards[id] ~= nil then
			return "had"
		end
		if prompted[player] then
			return "busy"
		end
		local p = purchasing
		if p == nil then
			return "off"
		end
		if p:sells(offer) then
			prompted[player] = id
			local listing, refused = p:prompt(player, offer)
			if listing then
				return nil
			end
			prompted[player] = nil
			return if refused and refused.reason == "notBuyable" then "had" else "off"
		end
		local dev = if STUDIO then ServerStorage:FindFirstChild("DevReceipt") else nil
		if dev and dev:IsA("BindableFunction") then
			-- no product of its title on Roblox: a made-up receipt runs the real grant
			prompted[player] = id
			task.spawn(function()
				local said = dev:Invoke({ PlayerId = player.UserId, offer = offer })
				print(`[CardSales] {player.Name} bought {offer} (Studio receipt: {said})`)
				if said ~= "PurchaseGranted" and prompted[player] == id then
					prompted[player] = nil
					answer(player, id, "save")
				end
			end)
			return nil
		end
		return "off"
	end

	local function onBuy(player: Player, value: unknown)
		if not limit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local id = CardSale.ask(value)
		if not id then
			return
		end
		local offer = CardSale.offer(id)
		if offer then
			local why = prompt(player, id, offer) -- yields while Roblox puts it up
			if why then
				answer(player, id, why)
			end
			return
		end
		answer(player, id, buy(player, id))
	end

	-- A purchase granted and written (Purchasing): a Robux style's is owned in the save now.
	local function onGranted(sale: Purchasing.Sale)
		local id = CardSale.styleFor(sale.offer)
		if id == nil then
			return
		end
		local player = sale.buyer
		mark(player)
		if prompted[player] == id then
			prompted[player] = nil
			answer(player, id, "")
		end
	end

	-- The Robux styles' prices on Roblox for `player` now, by style (0 while it isn't in; missing
	-- when off sale). Fetches fresh prices in the background when they're old. Studio sells all.
	local function onSale(player: Player): { [string]: number }
		local out: { [string]: number } = {}
		local p = purchasing
		if p == nil then
			return out
		end
		if not fetching[player] and os.clock() - (pricedAt[player] or -math.huge) > PRICE_FRESH then
			fetching[player] = true
			task.spawn(function() -- Roblox's prices yield
				local got = p:shelf(player)
				fetching[player] = nil
				if player.Parent then
					prices[player] = got
					pricedAt[player] = os.clock()
				end
			end)
		end
		local known = prices[player] or {}
		for id, offer in CardSale.Offers do
			if p:sells(offer) then
				out[id] = known[offer] or 0
			elseif STUDIO then
				out[id] = 0 -- no product made yet: Studio's made-up receipt sells it
			end
		end
		return out
	end

	return {
		name = "CardSales",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			saving = (context.registry:get("saving") :: any) :: Saving.SavingSystem
			purchasing = (context.registry:get("purchasing") :: any) :: Purchasing.PurchasingSystem? -- any: as above

			local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = REMOTE_FOLDER
				folder.Parent = ReplicatedStorage
			end
			local ask = Instance.new("RemoteEvent")
			ask.Name = CardSale.Remote
			ask.Parent = folder
			local reply = Instance.new("RemoteEvent")
			reply.Name = CardSale.BoughtRemote
			reply.Parent = folder
			bought = reply
			local shelf = Instance.new("RemoteFunction")
			shelf.Name = CardSale.ShelfRemote
			shelf.OnServerInvoke = function(player: Player): CardSale.Shelf?
				if not shelfLimit:take(player, os.clock()) then
					return nil
				end
				local data = if saving then saving:data(player) else nil
				if data == nil then
					return nil
				end
				local owned: { [string]: boolean } = {}
				for _, id in CardSale.Sold do
					if data.cards[id] ~= nil then
						owned[id] = true
					end
				end
				return { cash = data.cash, owned = owned, robux = onSale(player) }
			end
			shelf.Parent = folder
			table.insert(made, ask)
			table.insert(made, reply)
			table.insert(made, shelf)
			table.insert(connections, ask.OnServerEvent:Connect(onBuy))

			local s = saving
			if s then
				table.insert(
					signals,
					s.loaded:connect(function(each: Saving.Loaded)
						mark(each.player)
					end)
				)
				for _, player in Players:GetPlayers() do
					mark(player) -- loaded before this started
				end
			end
			local p = purchasing
			if p then
				table.insert(signals, p.granted:connect(onGranted))
			end
			-- the neon's prompt closed unbought: its card settles at once
			table.insert(
				connections,
				MarketplaceService.PromptProductPurchaseFinished:Connect(
					function(userId: number, _product: number, wasBought: boolean)
						local who = Players:GetPlayerByUserId(userId)
						local id = if who then prompted[who] else nil
						if who and id and not wasBought then
							prompted[who] = nil
							answer(who, id, "closed")
						end
					end
				)
			)

			-- Studio only (see the header). No client reaches it.
			if STUDIO then
				local test = Instance.new("BindableFunction")
				test.Name = STUDIO_TEST
				-- any: a BindableFunction's arguments, checked here as a remote's are
				test.OnInvoke = function(player: any, id: any, keep: any): ...any
					if not (typeof(player) == "Instance" and player:IsA("Player")) then
						return nil
					end
					local style = CardSale.ask(id)
					if not style then
						return "unknown"
					end
					local data = if saving then saving:data(player) else nil
					if keep == false then
						if data then
							data.cards[style] = nil
							mark(player)
						end
						return "taken away"
					end
					if CardSale.offer(style) then
						if data then
							CardSale.own(data, style, os.time())
							mark(player)
						end
						return "owned (no purchase made)"
					end
					return buy(player, style)
				end
				test.Parent = ServerStorage
				table.insert(made, test)
			end

			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					limit:forget(player)
					shelfLimit:forget(player)
					buying[player] = nil
					prompted[player] = nil
					prices[player] = nil
					pricedAt[player] = nil
					fetching[player] = nil
				end)
			)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, c in signals do
				c:disconnect()
			end
			table.clear(signals)
			for _, m in made do
				m:Destroy()
			end
			table.clear(made)
			bought = nil
		end,
	}
end

return CardSales
