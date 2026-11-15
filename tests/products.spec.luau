--!strict
-- lune run tests/products.spec
-- What this game sells (S3-02a): the product table holds together (titles, switches, names); and a
-- purchase through Brix's Purchases, over this game's own save and analytics plan, is granted once
-- and only once its save is written: a receipt sent again grants nothing more, a failed write grants
-- nothing until a later receipt writes it, and a second server holding the save never grants it
-- again. An offer switched off in the live config isn't on sale; an offer with no product id isn't
-- sold at all.
local Brix = require("../vendor/brix/src")
local Products = require("../src/shared/Products")
local Record = require("../src/shared/Record")
local Save = require("../src/shared/Save")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- The table: every row has a Dashboard title and a switch, none shared; Names lists every offer.
do
	local titles, switches, count = {}, {}, 0
	for name, row in Products.Rows do
		count += 1
		ok(#row.title > 0 and titles[row.title] == nil, `{name} has a title of its own`)
		ok(#row.switch > 0 and switches[row.switch] == nil, `{name} has a switch of its own`)
		titles[row.title], switches[row.switch] = true, true
		ok(table.find(Products.Names, name) ~= nil, `{name} is in Names`)
		ok(Products.switches()[row.switch] == true, `{name} is on by default`)
	end
	ok(#Products.Names == count, "Names lists every offer once")
	ok(Products.Rows.testPurchase.ownerOnly == true, "the test purchase is the owner's only")
	ok(next(Products.offers({})) == nil, "an offer with no product id isn't sold")
end

-- A store that fails every write while `failing.on`, as a DataStore outage would.
local failing = { on = false }
local inner = Brix.SaveStore.loopback()
local store: Brix.SaveStore = {
	update = function(_: any, key: string, change: Brix.SaveChange): string?
		if failing.on then
			return "made-up failure"
		end
		return inner:update(key, change)
	end,
}

local recorder = Brix.AnalyticsSink.recorder() :: Brix.AnalyticsRecorder<string>
local problems: { string } = {}
local analytics = Brix.Analytics.new({
	plan = Record.plan(Brix),
	sink = recorder,
	onProblem = function(problem: string)
		table.insert(problems, problem)
	end,
})

local live: { [string]: any } = Products.switches() -- any: config values as the live config holds them
local marketplace: Brix.Marketplace<string> = {
	price = function(_: any, _player: string, _product: number): (number?, string?)
		return 25, nil
	end,
	restrictsPaidRandom = function(_: any, _player: string): boolean
		return true
	end,
}

-- One server: its saves and its Purchases over the shared store.
local function server(name: string): (Brix.Saves<Save.Data>, Brix.Purchases<string>, { string })
	local saves = Brix.Saves.new({
		format = Save.format(Brix),
		store = store,
		now = function(): number
			return 1794800000
		end,
		server = name,
	})
	local heard: { string } = {}
	local purchases = Brix.Purchases.new({
		saves = saves,
		ledger = function(data: Save.Data): { string }
			return data.purchases
		end,
		recipients = function(data: Save.Data): { [string]: string }
			return data.recipients
		end,
		offers = Products.offers({ testPurchase = 9001 }) :: any, -- any: Brix's offer shape, same fields
		marketplace = marketplace,
		switchedOn = function(offer: string): boolean
			return Products.switchedOn(live, offer)
		end,
		analytics = analytics,
	})
	purchases:onGranted(function(sale: Brix.PurchaseSale<string>)
		table.insert(heard, sale.offer)
	end)
	return saves, purchases, heard
end

local key = Save.key(42)
local function receipt(id: string): Brix.PurchaseReceipt<string>
	return { id = id, buyer = "Ana", key = key, product = 9001, spent = 25 }
end

local saves, purchases, heard = server("one")
local _, claimProblem = saves:claim(key)
ok(claimProblem == nil, "the buyer's save is claimed")

-- Bought once: granted, counted once, heard once.
do
	local refusal = purchases:receive(receipt("p1"))
	local data = saves:data(key)
	ok(refusal == nil, `a purchase is granted ({refusal and refusal.message})`)
	ok(data ~= nil and data.bought.testPurchase == 1, "it's counted once")
	ok(data ~= nil and data.cash == 0, "the test purchase touches no cash")
	ok(#heard == 1, "the server hears it once")
end

-- The same receipt again, as Roblox sends it after a lost answer: granted, nothing more.
do
	local refusal = purchases:receive(receipt("p1"))
	local data = saves:data(key)
	ok(refusal == nil, "a receipt sent again is answered granted")
	ok(data ~= nil and data.bought.testPurchase == 1, "a receipt sent again grants nothing more")
	ok(#heard == 1, "a receipt sent again isn't heard again")
end

-- A write that fails: refused, so Roblox asks again; the next receipt writes it, granting once.
do
	failing.on = true
	local refusal = purchases:receive(receipt("p2"))
	ok(
		refusal ~= nil and refusal.reason == "unsaved",
		"a purchase whose save didn't write is refused"
	)
	ok(#heard == 1, "a purchase not yet saved isn't heard")
	failing.on = false
	local again = purchases:receive(receipt("p2"))
	local data = saves:data(key)
	ok(again == nil, `once the save writes, it's granted ({again and again.message})`)
	ok(data ~= nil and data.bought.testPurchase == 2, "the failed write's purchase is granted once")
	ok(#heard == 2, "it's heard once it's saved")
end

-- The player hops: another server holds the save, and Roblox sends p2 there too. Nothing more.
do
	ok(saves:release(key) == nil, "the first server lets the save go")
	local saves2, purchases2, heard2 = server("two")
	local _, problem = saves2:claim(key)
	ok(problem == nil, "the second server claims it")
	local refusal = purchases2:receive(receipt("p2"))
	local data = saves2:data(key)
	ok(refusal == nil, "a hopped receipt is answered granted")
	ok(data ~= nil and data.bought.testPurchase == 2, "a hopped receipt grants nothing more")
	ok(#heard2 == 0, "the second server hears nothing for a sale already made")
	ok(data ~= nil and table.find(data.purchases, "p1") ~= nil, "the ledger travels with the save")
end

-- Switched off in the live config: not on sale. A receipt still grants (the player paid).
do
	local listing = purchases:onSale("Ana", key, "testPurchase")
	ok(listing == nil, "a save this server let go of has nothing on sale")
	local saves3, purchases3 = server("three")
	ok(saves3 ~= nil, "a third server")
	live.sellTestPurchase = false
	local _, notOnSale = purchases3:onSale("Ana", key, "testPurchase")
	ok(
		notOnSale ~= nil and notOnSale.reason == "switchedOff",
		"an offer switched off isn't on sale"
	)
	live.sellTestPurchase = true
end

ok(#problems == 0, `every record fits the plan ({problems[1]})`)

print(`products.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
