--!strict
--[[
	Purchasing (S3-02b): Robux purchases on the server, a system. The moment it serves: a player
	pays and gets what they paid for at once, exactly once, never lost, even when a save fails or
	they change servers. Nothing is on sale to players yet; S3-03 and S3-04 put offers in front of
	them through `prompt`.

	At start it finds each product's id on Roblox: every developer product the experience has, its
	Creator Dashboard name matched against each `Products` row's `title`. A row with no product of
	that name isn't sold on this server. In Studio such a row gets a made-up id (1, 2 ... in the
	order of `Products.Names`), so made-up receipts can be tried before the product exists.

	Once the ids are found and Saving's saves are made, Brix's Purchases grants each purchase into
	the buyer's save (its ledger, `data.purchases`, holds every purchase id granted, so a receipt
	sent again grants nothing more), and Brix's `PlayerPurchases` takes Roblox's receipts: a
	purchase counts as granted only once its save is written; a failed write is tried again while
	the buyer stays, and on the server they next join. Each offer's switch in the live config (Live)
	takes it off sale without an update, and a purchase already paid for is still granted. Every
	purchase prints one line in the server's log, and `granted` tells the systems whose offers land
	at once (S3-03's Cut Free). Brix records each purchase (`offerBought`); this records each
	prompt put up (`offerShown`, through `shown`, which Recording hears).

	For the owner's tests:
	- Workspace's `DevPrompt` attribute, set to an offer's name, puts that offer's purchase prompt
	  in front of the place's owner (anyone, in Studio), owner-only offers included, and clears
	  itself. Only server code can set it: Studio's command bar in Play, or the owner in the
	  Developer Console's server command line (`workspace:SetAttribute("DevPrompt", "testPurchase")`).
	- Studio only: `ServerStorage.DevReceipt`, a BindableFunction taking a made-up receipt, as Roblox
	  hands one over, and answering the decision's name (`PurchaseGranted`, `NotProcessedYet`).
	  Missing fields are filled in: the first player as buyer, a fresh purchase id, 0 Robux spent;
	  `offer` (an offer name) stands in for `ProductId`, and `recipient` (a save key) names who a
	  purchase for a friend is for, as the prompt would have. While a save fails it waits and tries again,
	  as a real receipt does, so it answers once the write lands or the buyer leaves.
	- Saving's `DevSaveFails` makes every save write fail.
]]
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brix = require(ReplicatedStorage.Brix)
local Products = require(ReplicatedStorage.Shared.Products)
local Save = require(ReplicatedStorage.Shared.Save)
local Live = require(script.Parent.Live)
local Saving = require(script.Parent.Saving)

local STUDIO = RunService:IsStudio()
-- Tries at reading the experience's products before this server sells nothing, and the seconds
-- between: a short Roblox outage at start still ends with offers on sale.
local FIND_TRIES = 4
local FIND_WAIT = 5

export type Sale = Brix.PurchaseSale<Player>
-- A purchase prompt put up: who saw it and for which offer.
export type Shown = { player: Player, offer: string }

export type PurchasingSystem = Brix.System & {
	-- A purchase was granted and its save written; heard once per purchase.
	granted: Brix.Signal<Sale>,
	-- A purchase prompt was put up in front of a player.
	shown: Brix.Signal<Shown>,
	-- Puts the purchase prompt for the offer named `offer` (a `Products` name) in front of `player`,
	-- for `recipient` (another player's save key) when it's bought for a friend: answers its listing
	-- (with the price Roblox showed) once the prompt is up, or nil and why it isn't on sale, in
	-- `reason` a code can branch on. An owner-only offer is never prompted to anyone else. A
	-- listing means the prompt went up, not that they bought it. May yield; never throws.
	prompt: (
		self: any,
		player: Player,
		offer: string,
		recipient: string?
	) -> (Brix.PurchaseListing?, Brix.PurchaseNotOnSale?),
	-- Whether the offer named `offer` can be prompted here now: a product of its title exists on
	-- Roblox (a made-up Studio id doesn't count), this server sells, and its switch is on. For
	-- a screen deciding whether to show the offer's button at all.
	sells: (self: any, offer: string) -> boolean,
	-- Every offer on sale to `player` now, by name, at the Robux Roblox reports to them (an offer
	-- their save can't buy, such as a wrap colour they own, isn't there), recorded as one look at
	-- the shop (`shopViewed`, Brix's `viewShop`). Empty while nothing is on sale. May yield.
	shelf: (self: any, player: Player) -> { [string]: number },
}

-- The part of Recording this reads: its Analytics, made in its start.
type Recorder = { analytics: (self: any) -> Brix.Analytics<Player>? }

local Purchasing = {}

-- Whether `player` may use the dev prompt and owner-only offers: anyone in Studio; on a live
-- server, the place's owner when a user (not a group) owns it.
local function isDev(player: Player): boolean
	return STUDIO or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId)
end

-- Every developer product's id by its Dashboard name, every page; or nil and why. Yields.
local function productsByTitle(): ({ [string]: number }?, string?)
	local byTitle: { [string]: number } = {}
	local read, err = pcall(function()
		local pages = MarketplaceService:GetDeveloperProductsAsync()
		while true do
			-- any: each entry is Roblox's product info, a dictionary
			for _, entry: any in pages:GetCurrentPage() do
				local name, id = entry.Name, entry.ProductId
				if type(name) == "string" and type(id) == "number" then
					byTitle[name] = id
				end
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
	if not read then
		return nil, tostring(err)
	end
	return byTitle, nil
end

-- A refusal for `offer` with `reason`, as Brix's would read.
local function notOnSale(
	offer: string,
	reason: Brix.PurchaseNotOnSaleReason,
	message: string
): Brix.PurchaseNotOnSale
	return { offer = offer, reason = reason, message = message }
end

function Purchasing.new(): PurchasingSystem
	local granted = Brix.Signal.new() :: Brix.Signal<Sale>
	local shown = Brix.Signal.new() :: Brix.Signal<Shown>
	local saving: Saving.SavingSystem? = nil
	local live: Live.LiveSystem? = nil
	local recorder: Recorder? = nil
	local ids: { [string]: number }? = nil
	local real: { [string]: true } = {} -- offers with a product on Roblox, not made up
	local saves: Brix.Saves<Save.Data>? = nil
	local playerPurchases: Brix.PlayerPurchases? = nil
	local shop: Brix.Purchases<Player>? = nil -- the Purchases PlayerPurchases takes receipts for
	local stopped = false
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local devReceipt: BindableFunction? = nil

	local system = {
		name = "Purchasing",
		granted = granted,
		shown = shown,
	}

	-- Whether the offer named `offer` is switched on in the live config now.
	local function switchedOn(offer: string): boolean
		return if live then Products.switchedOn(live:current(), offer) else true
	end

	-- Once both the ids and the saves are there: Purchases over them, taking Roblox's receipts.
	local function build()
		local found, held = ids, saves
		if stopped or playerPurchases ~= nil or found == nil or held == nil then
			return
		end
		local offers = Products.offers(found)
		if next(offers) == nil then
			print("[Purchasing] no product on Roblox has a Products title, so nothing is sold here")
			return
		end
		local analytics = if recorder then recorder:analytics() else nil
		if analytics == nil then
			warn("[Purchasing] Recording has no analytics, so nothing is sold here")
			return
		end
		local purchases = Brix.Purchases.new({
			saves = held,
			ledger = function(data: Save.Data): { string }
				return data.purchases
			end,
			-- any: Products' offers are Brix's PurchaseOffer<Save.Data, Player>, typed loosely there
			offers = offers :: any,
			marketplace = Brix.Roblox.Marketplace.services(),
			switchedOn = switchedOn,
			analytics = analytics,
			recipients = function(data: Save.Data): { [string]: string }
				return data.recipients
			end,
		})
		table.insert(
			signals,
			purchases:onGranted(function(sale: Sale)
				local data = if saving then saving:data(sale.buyer) else nil
				local count = if data then data.bought[sale.offer] else nil
				print(
					`[Purchasing] granted {sale.offer} to {sale.buyer.Name} (bought {count or "?"})`
				)
				granted:fire(sale)
			end)
		)
		local made = Brix.Roblox.PlayerPurchases.new({
			purchases = purchases,
			keyFor = function(player: Player): string
				return Save.key(player.UserId)
			end,
			onProblem = function(message: string)
				warn(`[Purchasing] {message}`)
			end,
		})
		playerPurchases = made
		shop = purchases
		made:start()
	end

	-- Finds each offer's product id on Roblox, trying again a few times, then builds.
	local function findIds()
		local byTitle: { [string]: number }? = nil
		local problem: string? = nil
		for try = 1, FIND_TRIES do
			byTitle, problem = productsByTitle()
			if byTitle or stopped then
				break
			end
			if try < FIND_TRIES then
				task.wait(FIND_WAIT)
			end
		end
		if stopped then
			return
		end
		if byTitle == nil then
			warn(
				`[Purchasing] can't read the experience's products, so nothing is sold here ({problem})`
			)
			byTitle = {}
		end
		local titles = byTitle :: { [string]: number }
		local found: { [string]: number } = {}
		local said: { string } = {}
		for index, name in Products.Names do
			local id = titles[Products.Rows[name].title]
			if id then
				found[name] = id
				real[name] = true
				table.insert(said, `{name} {id}`)
			elseif STUDIO then
				found[name] = index
				table.insert(said, `{name} {index} (made up)`)
			else
				table.insert(said, `{name} not on Roblox`)
			end
		end
		print(`[Purchasing] products: {table.concat(said, ", ")}`)
		ids = found
		build()
	end

	function system.prompt(
		_: any,
		player: Player,
		offer: string,
		recipient: string?
	): (Brix.PurchaseListing?, Brix.PurchaseNotOnSale?)
		local row = Products.Rows[offer]
		if row == nil or (row.ownerOnly and not isDev(player)) then
			return nil, notOnSale(offer, "unknownOffer", `{offer} isn't an offer for {player.Name}`)
		end
		-- a thing bought once and kept (a wrap colour) is never sold to its owner again
		local owned = row.owned
		local data = if owned and saving then saving:data(player) else nil
		if owned and data and owned(data) then
			return nil, notOnSale(offer, "notBuyable", `{player.Name} already owns {offer}`)
		end
		local made = playerPurchases
		if made == nil then
			return nil, notOnSale(offer, "notHeld", "nothing is on sale on this server yet")
		end
		local listing, refused = made:prompt(player, offer, recipient)
		if listing then
			shown:fire({ player = player, offer = offer })
		end
		return listing, refused
	end

	function system.sells(_: any, offer: string): boolean
		return playerPurchases ~= nil and real[offer] == true and switchedOn(offer)
	end

	function system.shelf(_: any, player: Player): { [string]: number }
		local prices: { [string]: number } = {}
		local p = shop
		if p == nil or playerPurchases == nil then
			return prices
		end
		local asked, listings = pcall(p.viewShop, p, player, Save.key(player.UserId))
		if asked and type(listings) == "table" then
			for _, listing in listings do
				prices[listing.offer] = listing.price
			end
		end
		return prices
	end

	-- The dev prompt: the offer named in Workspace's DevPrompt, to every dev player here.
	local function devPrompt()
		local asked = workspace:GetAttribute("DevPrompt")
		if asked == nil then
			return
		end
		workspace:SetAttribute("DevPrompt", nil)
		if type(asked) ~= "string" then
			warn("[Purchasing] DevPrompt takes an offer's name, such as testPurchase")
			return
		end
		for _, player in Players:GetPlayers() do
			if isDev(player) then
				task.spawn(function()
					local listing, refused = system:prompt(player, asked)
					if listing then
						print(
							`[Purchasing] prompted {player.Name} for {asked} at {listing.price} Robux`
						)
					elseif refused then
						warn(`[Purchasing] DevPrompt {asked} for {player.Name}: {refused.message}`)
					end
				end)
			end
		end
	end

	-- Studio's made-up receipts: fills in what's missing and hands it to PlayerPurchases.
	local function takeDevReceipt(receipt: unknown): string
		local made, found = playerPurchases, ids
		if made == nil or found == nil then
			return "nothing is on sale yet"
		end
		if type(receipt) ~= "table" then
			return "DevReceipt takes a receipt table"
		end
		local info = receipt :: { [string]: any } -- any: a receipt, as Roblox hands one over
		local first = Players:GetPlayers()[1]
		if info.PlayerId == nil and first then
			info.PlayerId = first.UserId
		end
		if info.ProductId == nil and type(info.offer) == "string" then
			info.ProductId = found[info.offer]
		end
		info.offer = nil
		-- `recipient`, a save key: who the purchase is for, named in the buyer's save as a prompt
		-- would (Free a Friend, S3-03b); Studio can't prompt a made-up product, so this stands in
		local recipient = info.recipient
		info.recipient = nil
		local s = saving
		local buyer = Players:GetPlayerByUserId(info.PlayerId)
		local data = if s and buyer then s:data(buyer) else nil
		if type(recipient) == "string" and data and type(info.ProductId) == "number" then
			for name, id in found do
				if id == info.ProductId then
					data.recipients[name] = recipient
				end
			end
		end
		info.PurchaseId = info.PurchaseId or HttpService:GenerateGUID(false)
		info.CurrencySpent = info.CurrencySpent or 0
		info.CurrencyType = info.CurrencyType or Enum.CurrencyType.Robux
		info.PlaceIdWherePurchased = info.PlaceIdWherePurchased or game.PlaceId
		return made:process(info).Name
	end

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		saving = (registry:get("saving") :: any) :: Saving.SavingSystem? -- any: registry hands back Systems
		live = (registry:get("live") :: any) :: Live.LiveSystem? -- any: as above
		recorder = (registry:get("recording") :: any) :: Recorder? -- any: as above

		local s = saving
		if s then
			saves = s:saves()
			table.insert(
				signals,
				s.began:connect(function(made: Brix.Saves<Save.Data>)
					saves = made
					build()
				end)
			)
		else
			warn("[Purchasing] no Saving system, so nothing is sold here")
		end

		table.insert(
			connections,
			workspace:GetAttributeChangedSignal("DevPrompt"):Connect(devPrompt)
		)
		if STUDIO then
			local fn = Instance.new("BindableFunction")
			fn.Name = "DevReceipt"
			fn.OnInvoke = takeDevReceipt
			fn.Parent = ServerStorage
			devReceipt = fn
		end

		task.spawn(findIds)
	end

	function system.stop(_: any)
		stopped = true
		for _, signal in signals do
			signal:disconnect()
		end
		table.clear(signals)
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		if devReceipt then
			devReceipt:Destroy()
			devReceipt = nil
		end
		if playerPurchases then
			playerPurchases:stop()
			playerPurchases = nil
			shop = nil
		end
	end

	return system
end

return Purchasing
