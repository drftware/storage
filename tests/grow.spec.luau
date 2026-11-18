--!strict
-- lune run tests/grow.spec
-- Growing your home for cash at the counter (S5-03h2, ideas 30 and 31): Medium has a whole cash
-- price and nothing else does (Large and XL are Robux, S5-03h3); a sale is refused when it isn't
-- a size, when you're that size or bigger, when it's a Robux size, or when you're short; else the
-- cash taken and the size written in one step, and undone whole when its save fails, keeping
-- whatever else happened meanwhile. The counter's cards run from your size up.
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
	ok(same(Grow.ladder("Medium"), { "Medium" }), "Medium: yours (Large and XL come with Robux)")
	ok(same(Grow.ladder("XL"), { "XL" }), "XL: nothing bigger")
	ok(same(Grow.ladder("Huge"), { "Small", "Medium" }), "a name not known reads as Small")
	for _, name in Sizes.Names do
		ok(Grow.ladder(name)[1] == name, `{name}'s cards start with it`)
	end

	ok(Grow.card("Small", "Small", 0) == "yours", "your own size")
	ok(Grow.card("Medium", "Small", MEDIUM) == "buy", "enough cash: Buy")
	ok(Grow.card("Medium", "Small", MEDIUM - 1) == "short", "short: dimmed")
	ok(Grow.card("Medium", "Large", 1e6) == "yours", "a size under yours reads as yours")
end

-- The shelf the screen is answered, read safely.
do
	local shelf = Grow.read(Grow.shelf({ cash = 321, homeSize = "Medium" }))
	ok(shelf ~= nil and shelf.cash == 321 and shelf.size == "Medium", "the shelf round trip")
	ok(Grow.read(nil) == nil and Grow.read("x") == nil, "not a table")
	ok(Grow.read({ cash = 0 / 0, size = "Small" }) == nil, "cash not a number")
	local odd = Grow.read({ cash = 12.7, size = "Huge" })
	ok(odd ~= nil and odd.cash == 12 and odd.size == "Small", "an odd size reads as Small")
end

print(`grow: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
