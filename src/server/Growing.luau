--!strict
--[[
	Growing: a bigger home bought for cash at the counter (S5-03h2, D-341; the home doc's ideas 30
	and 31). The moment: back from a good climb you've saved up, and the counter sells you a bigger
	unit; your cash ticks down and your home is Medium, everything you'd set out where it was.
	Bloxburg's and Adopt Me's house upgrades, Animal Crossing's house loan. The sizes and the
	sale's rules are `Home.Grow`'s and `Home.Sizes`'.

	`GrowHome` (`Grow.Remote`, a size's name) is rate-limited before its payload is read, then
	checked: a short string naming a size (`Grow.ask`), then the buyer's size and cash
	(`Grow.buy`). One sale at a time per player: a second while the first's write is out is
	answered "busy". A sale takes the price and writes the size in one step, so any write of the
	save from that moment (this one, the autosave, a leave) holds both or neither; then the save is
	written at once, and only once the write is answered is the home set up again at its new size
	(`Arranging`'s relay, which carries the rows laid at the old size) and the buyer told
	(`Grow.GrownRemote`: the size asked for, their cash, their home's size, and "" or why not). A
	write that fails undoes the sale whole (`Grow.unbuy`), and the buyer is told "save": never a
	bigger home that a rejoin would take away, never cash gone with nothing for it. Growing only
	ever writes `homeSize` (D-340): if the server stops before the relay, the next lay, on any
	server, carries the rows.

	Large and XL are Robux (S5-03h3a, D-342), as Adopt Me sells its bigger houses: the same remote
	naming one is answered "had" when the home is that size or bigger, else Roblox's prompt goes up
	from here (Purchasing's `prompt`, which refuses it too once owned), or "off" when it isn't on
	sale. Nothing is answered while the prompt is up: closed unbought, the buyer is told "closed";
	bought, the purchase is granted through Purchasing (`Products`' row: the size written in the
	save Brix writes before the purchase counts, never lost on a failed write or a hop), and once
	Purchasing says it's granted the home is set up again at its new size and the buyer told "".
	A late receipt for a size the home has already (two prompts bought at once) is still granted
	and counted, changes nothing and is logged. In Studio, with no product of its title on Roblox,
	the press hands Purchasing's `DevReceipt` a made-up receipt instead, so the whole grant runs.

	Large and XL are gifts too (S5-03h3b, D-343), as Pet Simulator and Adopt Me let you gift Robux
	things: `GrowHome` carrying a friend's UserId after the size is checked (a whole UserId, a
	player here, not you, their save loaded, their home smaller: else "gone", "notLoaded", "had").
	A spare gift of that size in your save (one whose friend left before it landed) is given at
	once: the friend's home grows and their save is written first, then your spare is taken and
	yours written; the friend's write failing undoes it and keeps the spare ("save"). Otherwise
	Roblox's prompt goes up naming the friend (Brix's gift: their home grows in their save, written
	before your purchase counts); closed unbought, "closed". Granted, the friend's home is set up
	again at its new size, they're told (`Grow.GiftedRemote`: the size, your UserId and name) and
	you're answered "". A friend gone before it landed leaves a spare in your save ("gone").

	`HomeSizeShelf` (`Grow.ShelfRemote`, a RemoteFunction, rate-limited) answers the counter's
	screen (UnitsTab) the asker's cash, home's size, and each Robux size on sale to them now at
	the price Roblox last reported (0 until it's in; each ask fetches fresh ones in the background,
	at most every `PRICE_FRESH` seconds), the gifts the same way, your spare gifts, and the friends
	here with their homes' sizes (`Grow.friends`). In Studio, `ServerStorage.GrowTest:Invoke(player, name)`
	sells as the remote does, unthrottled, and answers "" or the refusal (a Robux size: "" once its
	made-up receipt is granted); `:Invoke(player)` answers the save's cash and home's size;
	`:Invoke(player, "cash", n)` sets the save's cash to `n` (for trying a sale) and answers it;
	`:Invoke(player, "price", n)` makes up a Robux price of `n` for the cards (0 clears it), so the
	look can be judged before the products exist; `:Invoke(player, "gift", size, friend)` gives
	`friend` (a Player) that size as the remote's gift does, answering "" or why not;
	`:Invoke(player, "friend", name, size)` lists a made-up friend on the Gift (one player can see
	the screen: a gift to them lands after a beat, no save), and `"friend"` alone clears them.
]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brix = require(ReplicatedStorage.Brix)
local Grow = require(ReplicatedStorage.Shared.Home.Grow)
local Save = require(ReplicatedStorage.Shared.Save)
local Arranging = require(script.Parent.Arranging)
local Purchasing = require(script.Parent.Purchasing)
local Saving = require(script.Parent.Saving)

local REMOTE_FOLDER = "Remotes"
local STUDIO_TEST = "GrowTest"
local STUDIO = RunService:IsStudio()
-- Seconds a player's Robux prices are kept before a shelf ask fetches them again: Roblox's prices
-- rarely move, and each fetch counts as a look at the shop in the analytics.
local PRICE_FRESH = 60

local Growing = {}

export type GrowingSystem = Brix.System

function Growing.new(): GrowingSystem
	local connections: { RBXScriptConnection } = {}
	local made: { Instance } = {}
	local limit = Brix.RateLimit.bucket(Grow.Limit)
	local shelfLimit = Brix.RateLimit.bucket(Grow.ShelfLimit)
	local saving: Saving.SavingSystem? = nil
	local arranging: Arranging.ArrangingSystem? = nil
	local purchasing: Purchasing.PurchasingSystem? = nil
	local grown: RemoteEvent? = nil
	local gifted: RemoteEvent? = nil
	local selling: { [Player]: true } = {} -- a sale's (or a spare gift's) write is out
	local prompted: { [Player]: string } = {} -- the Robux size whose prompt is up
	local giving: { [Player]: { name: string, friend: number } } = {} -- a gift's prompt is up
	local prices: { [Player]: { [string]: number } } = {} -- Robux by offer, as Roblox said
	local pricedAt: { [Player]: number } = {} -- os.clock the prices were fetched
	local fetching: { [Player]: true } = {}
	local madeUp = 0 -- Studio's made-up Robux price for the cards (GrowTest "price")
	-- Studio's made-up friends (GrowTest "friend"), by their made-up UserId: listed on the Gift
	-- like anyone here, and a gift to one lands after a beat with no save or prompt, so the Gift
	-- screen can be seen with one player.
	local madeUpFriends: { [number]: Grow.Friend } = {}
	local signals: { Brix.SignalConnection } = {}

	-- Sells size `name` to `player`: "" once sold, written and the home set up at it, else why not.
	local function sell(player: Player, name: string): string
		local s = saving
		local data = if s then s:data(player) else nil
		if not (s and data) then
			return "notLoaded"
		end
		if selling[player] then
			return "busy"
		end
		local refusal, was = Grow.buy(data, name)
		if refusal then
			return refusal
		end
		selling[player] = true
		local problem = s:save(player) -- yields while the store answers
		selling[player] = nil
		if problem then
			Grow.unbuy(data, name, was) -- undone whole: the next write keeps neither
			warn(`Growing: {player.Name}'s {name} undone, the save wasn't written: {problem}`)
			return "save"
		end
		if RunService:IsStudio() then
			print(`Growing: {player.Name}'s home is {name} now, cash {data.cash}`)
		end
		if arranging and player.Parent then
			arranging:relay(player) -- the rows carried to the new size, the save written so
		end
		return ""
	end

	-- Tells `player` how their ask for size `name` went: their cash and home's size, "" or why not,
	-- and the friend's UserId for a gift (0 for their own home).
	local function answer(player: Player, name: string, why: string, friend: number?)
		local data = if saving then saving:data(player) else nil
		local remote = grown
		if remote and player.Parent then
			local shelf = if data then Grow.shelf(data) else nil
			remote:FireClient(
				player,
				name,
				if shelf then shelf.cash else 0,
				if shelf then shelf.size else "",
				why,
				friend or 0
			)
		end
	end

	-- The player in this server whose save key is `key`, if any.
	local function whoseKey(key: string?): Player?
		if key == nil then
			return nil
		end
		for _, p in Players:GetPlayers() do
			if Save.key(p.UserId) == key then
				return p
			end
		end
		return nil
	end

	-- `friend`'s home just grew to `name`, a gift from `giver`: set up again at its new size and the
	-- friend told, for their own "More room!".
	local function gave(friend: Player, name: string, giver: Player)
		local data = if saving then saving:data(friend) else nil
		if not (data and friend.Parent) then
			return
		end
		print(`[Growing] {giver.Name} gave {friend.Name} a {name} home`)
		if arranging and data.placedSize ~= data.homeSize then
			arranging:relay(friend) -- the rows carried to the new size, the save written so
		end
		local remote = gifted
		if remote then
			remote:FireClient(friend, name, giver.UserId, giver.DisplayName)
		end
	end

	-- Gives one of `player`'s spare gifts of size `name` to `friend`: the friend's save written
	-- first, then the spare taken from `player`'s: "" once given, else why not.
	local function giveSpare(player: Player, friend: Player, name: string): string
		local s = saving
		local data = if s then s:data(player) else nil
		local theirs = if s then s:data(friend) else nil
		if not (s and data and theirs) then
			return "notLoaded"
		end
		if selling[player] or selling[friend] then
			return "busy"
		end
		local refusal, was = Grow.give(data, theirs, name)
		if refusal then
			return refusal
		end
		selling[player], selling[friend] = true, true
		local problem = s:save(friend) -- yields while the store answers
		if problem then
			selling[player], selling[friend] = nil, nil
			Grow.ungive(theirs, name, was) -- the spare kept for the next press
			warn(`Growing: {player.Name}'s {name} gift to {friend.Name} undone: {problem}`)
			return "save"
		end
		Grow.spend(data, name)
		local mine = s:save(player)
		selling[player], selling[friend] = nil, nil
		if mine then
			warn(`Growing: {player.Name}'s spent spare waits for their next write: {mine}`)
		end
		gave(friend, name, player)
		return ""
	end

	-- `player`'s Gift press for size `name`, `value` the friend's UserId (never trusted): a spare
	-- given at once, or Roblox's prompt up naming the friend. Nil when the grant (or the prompt's
	-- close) answers; else why not. Yields.
	local function gift(player: Player, name: string, value: unknown): (string?, number)
		local id = Grow.friendId(value)
		local offer = Grow.giftOffer(name)
		if id == nil or offer == nil then
			return "unknown", 0
		end
		local fake = madeUpFriends[id]
		if fake then
			if Grow.owns({ homeSize = fake.size }, name) then
				return "had", id
			end
			task.delay(1, function()
				fake.size = name
				print(`[Growing] {player.Name} gave made-up {fake.name} a {name} home`)
				answer(player, name, "", id)
			end)
			return nil, id
		end
		local friend = Players:GetPlayerByUserId(id)
		if friend == nil or friend == player then
			return "gone", id
		end
		local data = if saving then saving:data(player) else nil
		local theirs = if saving then saving:data(friend) else nil
		if not (data and theirs) then
			return "notLoaded", id
		end
		if Grow.owns(theirs, name) then
			return "had", id
		end
		if giving[player] or prompted[player] then
			return "busy", id
		end
		if Grow.spares(data, name) > 0 then
			return giveSpare(player, friend, name), id
		end
		local p = purchasing
		if p and p:sells(offer) then
			giving[player] = { name = name, friend = id }
			local listing, refused = p:prompt(player, offer, Save.key(friend.UserId))
			if listing then
				return nil, id
			end
			giving[player] = nil
			print(`[Growing] no {offer} prompt for {player.Name}: {refused and refused.reason}`)
			return "off", id
		end
		local dev = if STUDIO then ServerStorage:FindFirstChild("DevReceipt") else nil
		if dev and dev:IsA("BindableFunction") then
			-- no product of its title on Roblox: a made-up receipt runs Brix's real gift
			giving[player] = { name = name, friend = id }
			local key = Save.key(friend.UserId)
			task.spawn(function()
				local said =
					dev:Invoke({ PlayerId = player.UserId, offer = offer, recipient = key })
				print(`[Growing] {player.Name} gave {offer} (Studio receipt: {said})`)
				local still = giving[player]
				if said ~= "PurchaseGranted" and still and still.name == name then
					giving[player] = nil
					answer(player, name, "save", id)
				end
			end)
			return nil, id
		end
		return "off", id
	end

	-- Puts Roblox's prompt for Robux size `name` (offer `offer`) in front of `player`: nil once it's
	-- up (or Studio's made-up receipt is out), and the grant answers; else why not. Yields.
	local function prompt(player: Player, name: string, offer: string): string?
		local data = if saving then saving:data(player) else nil
		if not data then
			return "notLoaded"
		end
		if Grow.owns(data, name) then
			return "had"
		end
		local p = purchasing
		if p == nil then
			return "off"
		end
		if p:sells(offer) then
			prompted[player] = name
			local listing, refused = p:prompt(player, offer)
			if listing then
				return nil
			end
			prompted[player] = nil
			print(`[Growing] no {offer} prompt for {player.Name}: {refused and refused.reason}`)
			return if refused and refused.reason == "notBuyable" then "had" else "off"
		end
		local dev = if STUDIO then ServerStorage:FindFirstChild("DevReceipt") else nil
		if dev and dev:IsA("BindableFunction") then
			-- no product of its title on Roblox: a made-up receipt runs the real grant
			prompted[player] = name
			task.spawn(function()
				local said = dev:Invoke({ PlayerId = player.UserId, offer = offer })
				print(`[Growing] {player.Name} bought {offer} (Studio receipt: {said})`)
				if said ~= "PurchaseGranted" and prompted[player] == name then
					prompted[player] = nil
					answer(player, name, "save")
				end
			end)
			return nil
		end
		return "off"
	end

	local function onGrow(player: Player, value: unknown, friend: unknown)
		if not limit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local name = Grow.ask(value)
		if not name then
			return
		end
		if friend ~= nil then
			local why, id = gift(player, name, friend) -- yields while Roblox puts it up
			if why and why ~= "unknown" then
				answer(player, name, why, id)
			end
			return
		end
		local offer = Grow.offer(name)
		if offer then
			local why = prompt(player, name, offer) -- yields while Roblox puts it up
			if why then
				answer(player, name, why)
			end
			return
		end
		answer(player, name, sell(player, name))
	end

	-- A purchase granted and written (Purchasing): a home size's grows the home, set up again at
	-- its new size; a late one for a size the home has already is logged. The buyer's screen is
	-- told only when it's waiting on this size's prompt from this server: a grant landing as they
	-- join (a hop) isn't news to a counter they haven't opened, and Roblox would hold the answer
	-- for the Units tab's first look, playing "More room!" for nothing.
	-- A gift granted and written: the friend's home set up and the friend told; the buyer answered
	-- when their Gift is waiting on it. A late one (the friend already that big) changes nothing; a
	-- friend gone before it landed leaves a spare in the buyer's save.
	local function onGifted(sale: Purchasing.Sale, name: string)
		local buyer = sale.buyer
		local waiting = giving[buyer]
		local id = if waiting and waiting.name == name then waiting.friend else nil
		if id then
			giving[buyer] = nil
		end
		local friend = whoseKey(sale.recipient)
		local theirs = if friend and saving then saving:data(friend) else nil
		if not (sale.gifted and friend and theirs) then
			print(`[Growing] {buyer.Name}'s {name} gift waits as a spare: its friend left`)
			if id then
				answer(buyer, name, "gone", id)
			end
			return
		end
		if theirs.homeSize ~= name then
			print(`[Growing] {buyer.Name}'s late {name} gift: {friend.Name} is {theirs.homeSize}`)
			if id then
				answer(buyer, name, "had", id)
			end
			return
		end
		gave(friend, name, buyer)
		if id then
			answer(buyer, name, "", id)
		end
	end

	local function onGranted(sale: Purchasing.Sale)
		local giftOf = Grow.giftSize(sale.offer)
		if giftOf then
			onGifted(sale, giftOf)
			return
		end
		local name = Grow.size(sale.offer)
		if name == nil then
			return
		end
		local player = sale.buyer
		local waiting = prompted[player] == name
		if waiting then
			prompted[player] = nil
		end
		local data = if saving then saving:data(player) else nil
		if not data then
			return
		end
		if data.homeSize ~= name then
			print(
				`[Growing] {player.Name}'s late {name} granted, the home already {data.homeSize}: nothing changed`
			)
			if waiting then
				answer(player, name, "had")
			end
			return
		end
		print(`[Growing] {player.Name}'s home is {name} now (Robux)`)
		if arranging and player.Parent and data.placedSize ~= data.homeSize then
			arranging:relay(player) -- the rows carried to the new size, the save written so
		end
		if waiting then
			answer(player, name, "")
		end
	end

	-- The Robux sizes on sale to `player` now at Roblox's price, by size (0 while it isn't in), and
	-- the gifts the same way; fetches fresh prices in the background when they're old. In Studio
	-- every size is on sale.
	local function onSale(player: Player): ({ [string]: number }, { [string]: number })
		local out: { [string]: number } = {}
		local gifts: { [string]: number } = {}
		local p = purchasing
		if p == nil then
			return out, gifts
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
		for size, offer in Grow.Robux do
			if p:sells(offer) then
				out[size] = known[offer] or 0
			elseif STUDIO then
				out[size] = madeUp
			end
		end
		for size, offer in Grow.Gifts do
			if p:sells(offer) then
				gifts[size] = known[offer] or 0
			elseif STUDIO then
				gifts[size] = madeUp
			end
		end
		return out, gifts
	end

	-- The friends `player` could give to: everyone else here whose save is loaded, with their size.
	local function friendsOf(player: Player): { Grow.Friend }
		local here: { Grow.Friend } = {}
		for _, p in Players:GetPlayers() do
			local data = if saving then saving:data(p) else nil
			if data then
				table.insert(here, { id = p.UserId, name = p.DisplayName, size = data.homeSize })
			end
		end
		for _, fake in madeUpFriends do
			table.insert(here, fake)
		end
		return Grow.friends(here, player.UserId)
	end

	return {
		name = "Growing",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			saving = (context.registry:get("saving") :: any) :: Saving.SavingSystem
			arranging = (context.registry:get("arranging") :: any) :: Arranging.ArrangingSystem
			purchasing = (context.registry:get("purchasing") :: any) :: Purchasing.PurchasingSystem? -- any: as above

			local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = REMOTE_FOLDER
				folder.Parent = ReplicatedStorage
			end
			local ask = Instance.new("RemoteEvent")
			ask.Name = Grow.Remote
			ask.Parent = folder
			local reply = Instance.new("RemoteEvent")
			reply.Name = Grow.GrownRemote
			reply.Parent = folder
			grown = reply
			local shelf = Instance.new("RemoteFunction")
			shelf.Name = Grow.ShelfRemote
			shelf.OnServerInvoke = function(player: Player): Grow.Shelf?
				if not shelfLimit:take(player, os.clock()) then
					return nil
				end
				local data = if saving then saving:data(player) else nil
				if data == nil then
					return nil
				end
				local robux, gifts = onSale(player)
				return Grow.shelf(data, robux, gifts, friendsOf(player))
			end
			shelf.Parent = folder
			local told = Instance.new("RemoteEvent")
			told.Name = Grow.GiftedRemote
			told.Parent = folder
			gifted = told
			table.insert(made, ask)
			table.insert(made, reply)
			table.insert(made, shelf)
			table.insert(made, told)
			table.insert(connections, ask.OnServerEvent:Connect(onGrow))
			local p = purchasing
			if p then
				table.insert(signals, p.granted:connect(onGranted))
			end
			-- a Robux size's prompt closed unbought: its card settles at once; bought, it holds till
			-- the grant lands (or the screen's own wait runs out)
			table.insert(
				connections,
				MarketplaceService.PromptProductPurchaseFinished:Connect(
					function(userId: number, _product: number, bought: boolean)
						local who = Players:GetPlayerByUserId(userId)
						local name = if who then prompted[who] else nil
						if who and name and not bought then
							prompted[who] = nil
							answer(who, name, "closed")
						end
						local up = if who then giving[who] else nil
						if who and up and not bought then
							giving[who] = nil
							answer(who, up.name, "closed", up.friend)
						end
					end
				)
			)

			-- Studio only (see the header). No client reaches it.
			if RunService:IsStudio() then
				local test = Instance.new("BindableFunction")
				test.Name = STUDIO_TEST
				-- any: a BindableFunction's arguments, checked here as a remote's are
				test.OnInvoke = function(player: any, name: any, amount: any, friend: any): ...any
					if not (typeof(player) == "Instance" and player:IsA("Player")) then
						return nil
					end
					if name == "gift" then
						local size = Grow.ask(amount)
						if not (size and typeof(friend) == "Instance" and friend:IsA("Player")) then
							return "unknown"
						end
						local why = gift(player, size, friend.UserId)
						if why then
							return why
						end
						-- the made-up receipt's gift clears the prompt once written: wait for it
						local waited = 0
						while giving[player] and waited < 10 do
							waited += task.wait(0.1)
						end
						if giving[player] then
							return "pending"
						end
						local theirs = if saving then saving:data(friend) else nil
						return if theirs and theirs.homeSize == size then "" else "had"
					end
					if name == "friend" then
						-- a made-up friend (`amount` their name, `friend` their size), or none left
						if type(amount) ~= "string" then
							table.clear(madeUpFriends)
							return 0
						end
						local id = -(9000 + #Grow.friends(friendsOf(player), 0))
						madeUpFriends[id] = {
							id = id,
							name = string.sub(amount, 1, 20),
							size = Grow.ask(friend) or "Small",
						}
						return id
					end
					if name == "price" then
						if type(amount) == "number" and amount == amount and amount >= 0 then
							madeUp = math.floor(amount)
						end
						return madeUp
					end
					if name == "cash" then
						local data = if saving then saving:data(player) else nil
						if
							data
							and type(amount) == "number"
							and amount == amount
							and amount >= 0
						then
							data.cash = math.floor(amount)
						end
						return if data then data.cash else nil
					end
					if name == nil then
						local data = if saving then saving:data(player) else nil
						return if data then data.cash else nil, if data then data.homeSize else nil
					end
					local size = Grow.ask(name)
					if size == nil then
						return "unknown"
					end
					local offer = Grow.offer(size)
					if offer == nil then
						return sell(player, size)
					end
					local why = prompt(player, size, offer)
					if why then
						return why
					end
					-- the made-up receipt's grant clears the prompt once written: wait for it, 10 s at
					-- most ("pending" while the save fails: Brix holds the grant till a write lands)
					local waited = 0
					while prompted[player] == size and waited < 10 do
						waited += task.wait(0.1)
					end
					if prompted[player] == size then
						return "pending"
					end
					local data = if saving then saving:data(player) else nil
					return if data and data.homeSize == size then "" else "had"
				end
				test.Parent = ServerStorage
				table.insert(made, test)
			end

			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					limit:forget(player)
					shelfLimit:forget(player)
					selling[player] = nil
					prompted[player] = nil
					giving[player] = nil
					prices[player] = nil
					pricedAt[player] = nil
					fetching[player] = nil
				end)
			)
		end,
		stop = function(_: any)
			for _, c in signals do
				c:disconnect()
			end
			table.clear(signals)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, m in made do
				m:Destroy()
			end
			table.clear(made)
			grown = nil
			gifted = nil
		end,
	}
end

return Growing
