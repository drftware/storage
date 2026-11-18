--!strict
-- lune run tests/grow.spec
-- Growing your home at the counter (S5-03h2, ideas 30 and 31): Medium has a whole cash price and
-- nothing else does; a cash sale is refused when it isn't a size, when you're that size or bigger,
-- when it's a Robux size, or when you're short; else the cash taken and the size written in one
-- step, and undone whole when its save fails, keeping whatever else happened meanwhile. Large and
-- XL are Robux (S5-03h3a): an offer each, owned at that size or bigger (never prompted then), and
-- a grant that only ever grows the home, so a late receipt for a size you have changes nothing.
-- The counter's cards run from your size up, a Robux size only while it's on sale.
local Grow = require("../src/shared/Home/Grow")
local Sizes = require("../src/shared/Home/Sizes")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local MEDIUM = Grow.price("Medium") or 0

-- The prices: Medium's a whole number of cash; no other size is sold for cash.
do
	ok(MEDIUM > 0 and MEDIUM == math.floor(MEDIUM), "Medium has a whole cash price")
	ok(Grow.price("Small") == nil, "Small isn't sold: everyone starts there")
	ok(Grow.price("Large") == nil and Grow.price("XL") == nil, "Large and XL aren't sold for cash")
	ok(Grow.price("Huge") == nil, "a name that isn't a size has no price")
end

-- Why a sale can't happen.
do
	local function wallet(cash: number, size: string): Grow.Wallet
		return { cash = cash, homeSize = size }
	end
	ok(Grow.check(wallet(1e6, "Small"), "Huge") == "unknown", "not a size")
	ok(Grow.check(wallet(1e6, "Small"), "Small") == "had", "Small when you're Small")
	ok(Grow.check(wallet(1e6, "Medium"), "Medium") == "had", "Medium when you're Medium")
	ok(Grow.check(wallet(1e6, "Large"), "Medium") == "had", "never sold smaller than you have")
	ok(Grow.check(wallet(1e6, "XL"), "Medium") == "had", "nor from XL")
	ok(Grow.check(wallet(1e6, "Small"), "Large") == "robux", "Large is Robux")
	ok(Grow.check(wallet(1e6, "Medium"), "XL") == "robux", "XL is Robux")
	ok(Grow.check(wallet(MEDIUM - 1, "Small"), "Medium") == "cash", "one short")
	ok(Grow.check(wallet(0, "Small"), "Medium") == "cash", "no cash at all")
	ok(Grow.check(wallet(MEDIUM, "Small"), "Medium") == nil, "exactly the price")
	ok(Grow.check(wallet(MEDIUM * 3, "Small"), "Medium") == nil, "more than enough")
end

-- The sale: cash and size in one step, or neither.
do
	local data = { cash = MEDIUM + 40, homeSize = "Small" }
	local refusal, was = Grow.buy(data, "Medium")
	ok(refusal == nil and was == "Small", "sold, from Small")
	ok(data.cash == 40 and data.homeSize == "Medium", "the cash taken and the size written")

	local short = { cash = MEDIUM - 1, homeSize = "Small" }
	local no, from = Grow.buy(short, "Medium")
	ok(no == "cash" and from == "Small", "refused: short")
	ok(short.cash == MEDIUM - 1 and short.homeSize == "Small", "a refused sale touches nothing")

	local had = { cash = 1e6, homeSize = "Medium" }
	ok(Grow.buy(had, "Medium") == "had" and had.cash == 1e6, "a second sale charges nothing")
end

-- Undone when its save fails: the cash back, the size back, anything else that happened kept.
do
	local data = { cash = MEDIUM + 40, homeSize = "Small" }
	local _, was = Grow.buy(data, "Medium")
	data.cash += 7 -- a find sold from the job box while the write was out
	Grow.unbuy(data, "Medium", was)
	ok(
		data.cash == MEDIUM + 47 and data.homeSize == "Small",
		"undone whole, the sale meanwhile kept"
	)

	local granted = { cash = MEDIUM, homeSize = "Small" }
	local _, before = Grow.buy(granted, "Medium")
	granted.homeSize = "XL" -- a Robux size granted while the write was out (S5-03h3)
	Grow.unbuy(granted, "Medium", before)
	ok(granted.cash == MEDIUM and granted.homeSize == "XL", "the cash back, the bigger size kept")
end

-- What the remote carried: only a size's name.
do
	ok(Grow.ask("Medium") == "Medium", "a size's name")
	ok(Grow.ask("Large") == "Large", "a Robux size reads (the check refuses it)")
	ok(Grow.ask("Huge") == nil, "not a size")
	ok(Grow.ask(12) == nil and Grow.ask(nil) == nil, "not a string")
	ok(Grow.ask({ "Medium" }) == nil, "not a table")
	ok(Grow.ask(string.rep("M", 200)) == nil, "too long")
end

-- The counter's cards: your size, then each bigger size on sale.
do
	local function same(a: { string }, b: { string }): boolean
		if #a ~= #b then
			return false
		end
		for i, v in a do
			if b[i] ~= v then
				return false
			end
		end
		return true
	end
	ok(same(Grow.ladder("Small"), { "Small", "Medium" }), "Small: yours, then Medium")
	ok(same(Grow.ladder("Medium"), { "Medium" }), "Medium: yours, no Robux size on sale")
	ok(same(Grow.ladder("XL"), { "XL" }), "XL: nothing bigger")
	ok(same(Grow.ladder("Huge"), { "Small", "Medium" }), "a name not known reads as Small")
	for _, name in Sizes.Names do
		ok(Grow.ladder(name)[1] == name, `{name}'s cards start with it`)
	end

	ok(Grow.card("Small", "Small", 0) == "yours", "your own size")
	ok(Grow.card("Medium", "Small", MEDIUM) == "buy", "enough cash: Buy")
	ok(Grow.card("Medium", "Small", MEDIUM - 1) == "short", "short: dimmed")
	ok(Grow.card("Medium", "Large", 1e6) == "yours", "a size under yours reads as yours")

	-- Robux sizes join while they're on sale (a price, 0 while Roblox's isn't in yet)
	local both = { Large = 0, XL = 400 }
	ok(
		same(Grow.ladder("Small", both), { "Small", "Medium", "Large", "XL" }),
		"Small: Medium for cash, Large and XL for Robux"
	)
	ok(same(Grow.ladder("Medium", both), { "Medium", "Large", "XL" }), "Medium: Large and XL")
	ok(same(Grow.ladder("Large", both), { "Large", "XL" }), "Large: XL")
	ok(same(Grow.ladder("XL", both), { "XL" }), "XL: still nothing bigger")
	ok(same(Grow.ladder("Small", { XL = 400 }), { "Small", "Medium", "XL" }), "Large switched off")
	ok(same(Grow.ladder("Small", { Medium = 5 }), { "Small", "Medium" }), "Medium never twice")
	ok(Grow.card("Large", "Small", 0) == "robux", "a Robux size: Buy at Roblox's price")
	ok(Grow.card("XL", "Large", 1e6) == "robux", "XL from Large, cash or none")
	ok(Grow.card("Large", "XL", 0) == "yours", "a Robux size under yours reads as yours")
end

-- The Robux sizes (S5-03h3a): an offer each, and nothing else is one.
do
	ok(Grow.offer("Large") == "homeLarge" and Grow.offer("XL") == "homeXL", "an offer each")
	ok(Grow.offer("Medium") == nil and Grow.offer("Small") == nil, "cash sizes aren't offers")
	ok(Grow.offer("Huge") == nil, "nor a name that isn't a size")
	ok(Grow.size("homeLarge") == "Large" and Grow.size("homeXL") == "XL", "an offer's size")
	ok(Grow.size("cutFree") == nil and Grow.size("Large") == nil, "other offers have no size")
	for name, offer in Grow.Robux do
		ok(Grow.price(name) == nil, `{name} has no cash price`)
		ok(Grow.size(offer) == name, `{offer} round trips`)
	end
end

-- Owned (never prompted): at that size or bigger.
do
	ok(not Grow.owns({ homeSize = "Small" }, "Large"), "Small doesn't own Large")
	ok(not Grow.owns({ homeSize = "Medium" }, "XL"), "Medium doesn't own XL")
	ok(Grow.owns({ homeSize = "Large" }, "Large"), "Large owns Large")
	ok(Grow.owns({ homeSize = "XL" }, "Large"), "XL owns Large: never sold smaller")
	ok(not Grow.owns({ homeSize = "Large" }, "XL"), "Large doesn't own XL")
	ok(not Grow.owns({ homeSize = "Small" }, "Huge"), "a name that isn't a size is never owned")
end

-- The grant: the home grows to the size, and never shrinks.
do
	local data = { homeSize = "Small", cash = 77 }
	ok(Grow.grant(data, "Large") == true, "Small to Large: grown")
	ok(data.homeSize == "Large" and data.cash == 77, "the size written, cash untouched")
	ok(Grow.grant(data, "XL") == true and data.homeSize == "XL", "Large to XL: grown")
	ok(Grow.grant(data, "Large") == false, "a late Large receipt: nothing to grow")
	ok(data.homeSize == "XL", "never shrinks")
	ok(Grow.grant(data, "XL") == false and data.homeSize == "XL", "the same size again: nothing")
	local medium = { homeSize = "Medium", cash = 0 }
	ok(Grow.grant(medium, "Huge") == false and medium.homeSize == "Medium", "not a size: nothing")
end

-- The shelf the screen is answered, read safely.
do
	local shelf = Grow.read(Grow.shelf({ cash = 321, homeSize = "Medium" }))
	ok(shelf ~= nil and shelf.cash == 321 and shelf.size == "Medium", "the shelf round trip")
	ok(Grow.read(nil) == nil and Grow.read("x") == nil, "not a table")
	ok(Grow.read({ cash = 0 / 0, size = "Small" }) == nil, "cash not a number")
	local odd = Grow.read({ cash = 12.7, size = "Huge" })
	ok(odd ~= nil and odd.cash == 12 and odd.size == "Small", "an odd size reads as Small")
	ok(odd ~= nil and next(odd.robux) == nil, "no Robux sizes said: none on sale")

	-- Robux prices: the sizes on sale to you, Roblox's price (0 while it isn't in yet)
	local priced = Grow.read(Grow.shelf({ cash = 5, homeSize = "Small" }, { Large = 0, XL = 799 }))
	ok(
		priced ~= nil and priced.robux.Large == 0 and priced.robux.XL == 799,
		"the Robux prices round trip"
	)
	local bad = Grow.read({
		cash = 5,
		size = "Small",
		robux = { Large = -3, XL = 0 / 0, Medium = 10, Huge = 10, [1] = 4 },
	})
	ok(bad ~= nil and next(bad.robux) == nil, "odd prices and sizes that aren't Robux are dropped")
	local whole = Grow.read({ cash = 5, size = "Small", robux = { XL = 99.6 } })
	ok(whole ~= nil and whole.robux.XL == 99, "a price reads whole")
	local notTable = Grow.read({ cash = 5, size = "Small", robux = "lots" })
	ok(notTable ~= nil and next(notTable.robux) == nil, "Robux prices not a table: none")
end

print(`grow: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
