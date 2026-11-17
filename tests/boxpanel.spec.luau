--!strict
-- lune run tests/boxpanel.spec
-- The job box's panel (S5-03c2b1): one card a kind you own with its count, rarest first, then by
-- name; finds the catalog doesn't know are left out; the search ignores case, spaces and dashes;
-- a rarity narrows to its own; the chips are the rarities you own; the screen refuses a list that
-- isn't one. Taking one out (S5-03c2b2): what's in the box is owned less the shelf's and what's
-- out, so asks past that take nothing; the take's way and name from the wire are checked; a card
-- counts one fewer and goes at none.
local BoxPanel = require("../src/shared/Home/BoxPanel")
local Catalog = require("../src/shared/Tools/Catalog")
local Save = require("../src/shared/Save")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local catalog: { [string]: BoxPanel.Row } = {
	Teddy = { name = "Teddy bear", grade = "Common", find = true },
	NightLight = { name = "Night-light", grade = "Common", find = true },
	Boombox = { name = "Boombox", grade = "Uncommon", find = true },
	Crown = { name = "Crown", grade = "Legendary", find = true },
	Ladder = { name = "Ladder" }, -- a tool, not a find
}

-- Grouping: one card a kind, its count, rarest first, then by name.
do
	local cards = BoxPanel.cards({ Teddy = 2, NightLight = 1, Crown = 1, Boombox = 3 }, catalog)
	ok(#cards == 4, "one card for each kind owned")
	ok(cards[1].key == "Crown", "the rarest first")
	ok(cards[2].key == "Boombox" and cards[2].count == 3, "then Uncommon, with its count")
	ok(cards[3].key == "NightLight" and cards[4].key == "Teddy", "a grade's cards by name")
	ok(BoxPanel.badge(cards[2].count) == "x3", "a count of three reads x3")
	ok(BoxPanel.badge(1) == "", "one of a kind shows no badge")
	local odd = BoxPanel.cards({ Ladder = 1, Mystery = 2, Teddy = 0 }, catalog)
	ok(#odd == 0, "tools, unknown names and none held make no card")
end

-- The real catalog: every kit find it knows makes a card with a grade.
do
	local finds: { [string]: number } = {}
	for key, row in Catalog do
		if row.find then
			finds[key] = 1
		end
	end
	local cards = BoxPanel.cards(finds, Catalog :: any) -- any: Catalog's rows carry more than Row
	ok(#cards > 0, "the catalog's finds make cards")
	for _, card in cards do
		ok(card.name ~= "" and card.grade ~= nil, card.key .. " has a name and a grade")
	end
end

-- Search and rarity.
do
	local cards = BoxPanel.cards({ Teddy = 2, NightLight = 1, Crown = 1, Boombox = 3 }, catalog)
	ok(#BoxPanel.shown(cards, "", nil) == 4, "an empty search shows everything")
	local night = BoxPanel.shown(cards, "  NIGHT light ", nil)
	ok(#night == 1 and night[1].key == "NightLight", "case, spaces and dashes don't matter")
	ok(#BoxPanel.shown(cards, "b", nil) == 2, "a letter finds every name holding it")
	ok(#BoxPanel.shown(cards, "zzz", nil) == 0, "a search matching nothing shows nothing")
	local common = BoxPanel.shown(cards, "", "Common")
	ok(#common == 2 and common[1].key == "NightLight", "a rarity shows its own, in order")
	ok(#BoxPanel.shown(cards, "teddy", "Common") == 1, "search and rarity together")
	ok(#BoxPanel.shown(cards, "teddy", "Legendary") == 0, "and both must hold")
	ok(#BoxPanel.search(string.rep("a", 99)) == BoxPanel.SearchMax, "a search is cut to its box")
	local grades = BoxPanel.grades(cards)
	ok(
		#grades == 3 and grades[1] == "Common" and grades[3] == "Legendary",
		"chips: the rarities owned, commonest first"
	)
end

-- What the server sends and what the screen takes.
do
	local list = BoxPanel.list({ Teddy = 2, Crown = 0, Boombox = 1.6 })
	ok(list.Teddy == 2 and list.Crown == nil and list.Boombox == 1, "the list: held ones, whole")
	local read = BoxPanel.read(list)
	ok(read ~= nil and read.Teddy == 2, "the screen reads a list")
	ok(BoxPanel.read("Teddy") == nil, "not a table: refused")
	ok(BoxPanel.read({ Teddy = "2" }) == nil, "a count that isn't a number: refused")
	ok(BoxPanel.read({ 5 }) == nil, "a name that isn't a string: refused")
	ok(BoxPanel.read({ Teddy = 0 }) == nil, "a count under one: refused")
	local empty = BoxPanel.read({})
	ok(empty ~= nil and next(empty) == nil, "an empty box reads as empty")
end

-- What's in the box (S5-03c2b2, D-293): owned, less the shelf's and what's out of it.
do
	local data = Save.fresh()
	Save.keep(data, { "Teddy", "Teddy", "Boombox", "Crown", "Teddy" }, 100, 2)
	-- the shelf's two spots took the first Teddy and the second Teddy; the rest went in the box
	ok(data.shelf[1].find == "Teddy" and data.shelf[2].find == "Teddy", "the shelf filled first")
	local boxed = Save.boxed(data, {})
	ok(boxed.Teddy == 1 and boxed.Boombox == 1 and boxed.Crown == 1, "the box: owned less shelved")
	ok(Save.free(data, 2) == 0 and Save.free(data, 6) == 4, "free spots: full, and four of six")
	local out = Save.boxed(data, { Boombox = 1, Teddy = 1 })
	ok(out.Boombox == nil and out.Teddy == nil and out.Crown == 1, "one out of the box: none left")
	ok(BoxPanel.canTake(boxed, "Teddy"), "one in the box may come out")
	ok(not BoxPanel.canTake(out, "Teddy"), "all out or on the shelf: none may come out")
	ok(not BoxPanel.canTake(boxed, "Mystery"), "a find never owned never comes out")
	local over = Save.boxed(data, { Crown = 5 })
	ok(over.Crown == nil, "more out than owned never reads as less than none in the box")

	-- taking out every one there is, one at a time, never takes more than you own
	local finds = { Teddy = 3 }
	local held: { [string]: number } = {}
	local taken = 0
	local d = Save.fresh()
	d.finds = finds
	for _ = 1, 10 do
		if BoxPanel.canTake(Save.boxed(d, held), "Teddy") then
			held.Teddy = (held.Teddy or 0) + 1
			taken += 1
		end
	end
	ok(taken == 3 and d.finds.Teddy == 3, "ten asks take out the three owned, the save untouched")

	-- shelving one from the box: the save's count stays, the box holds one fewer
	local s = Save.fresh()
	s.finds = { Boombox = 2 }
	ok(Save.boxed(s, {}).Boombox == 2, "two in the box")
	ok(Save.shelve(s, "Boombox", Save.Fresh.Seen, 6) == 1, "onto the first free spot")
	ok(Save.boxed(s, {}).Boombox == 1 and s.finds.Boombox == 2, "the box one fewer, still owned")
	ok(Save.free(s, 6) == 5, "one spot fewer free")
end

-- The take from the wire: a way and a name, checked.
do
	ok(BoxPanel.way("Hand") == "Hand" and BoxPanel.way("Shelf") == "Shelf", "both ways read")
	ok(BoxPanel.way("hand") == nil and BoxPanel.way(1) == nil, "anything else is refused")
	ok(BoxPanel.name("Teddy") == "Teddy", "a name reads")
	ok(BoxPanel.name("") == nil and BoxPanel.name(5) == nil, "empty or not text: refused")
	ok(BoxPanel.name(string.rep("a", BoxPanel.NameMax + 1)) == nil, "too long: refused")
end

-- The card counts one fewer as one comes out, and goes at none.
do
	local cards = BoxPanel.cards({ Teddy = 2, Crown = 1 }, catalog)
	local teddy = BoxPanel.took(cards, "Teddy")
	ok(teddy ~= nil and teddy.count == 1 and #cards == 2, "two, one taken: one left")
	ok(BoxPanel.badge(teddy and teddy.count or 0) == "", "and its x2 goes")
	local crown = BoxPanel.took(cards, "Crown")
	ok(crown ~= nil and crown.count == 0 and #cards == 1, "the last one taken: its card goes")
	ok(BoxPanel.took(cards, "Crown") == nil, "no card: nothing")
end

-- Selling one from the box (S5-03c3a): its price is its catalog worth; one comes off what you own,
-- the price goes on your cash, in one step; never one on the shelf, out, or past what's in the box.
do
	ok(BoxPanel.way("Sell") == "Sell", "selling reads as a way")
	ok(BoxPanel.price({ grade = "Uncommon", worth = 12 }) == 12, "the price is its worth")
	ok(BoxPanel.price({ grade = "Rare", worth = 31.7 }) == 31, "a whole number")
	ok(BoxPanel.price({ grade = "Epic" }) == 90, "no worth: its grade's least")
	ok(BoxPanel.price({}) == 1, "no worth, no grade: one")
	ok(
		BoxPanel.price({ worth = 0 / 0 }) == 1 and BoxPanel.price({ worth = -5 }) == 1,
		"never nothing"
	)
	ok(BoxPanel.price({ worth = math.huge }) == BoxPanel.PriceMost, "never past the dearest find")

	local data = Save.fresh()
	data.cash = 10
	data.finds = { Teddy = 3, Crown = 1 }
	ok(Save.shelve(data, "Teddy", Save.Fresh.Seen, 6) == 1, "one Teddy on the shelf")
	local out = { Teddy = 1 } -- one in your hands
	local sold, cash = 0, data.cash
	for _ = 1, 10 do
		local total = BoxPanel.sell(data, Save.boxed(data, out), "Teddy", 4)
		if total then
			sold += 1
			cash = total
		end
	end
	ok(sold == 1, "ten asks sell only the one in the box, not the shelf's or the one out")
	ok(data.finds.Teddy == 2 and cash == 14 and data.cash == 14, "one fewer owned, its price paid")
	ok(BoxPanel.sell(data, Save.boxed(data, {}), "Crown", 300) == 314, "the last Crown sold")
	ok(data.finds.Crown == nil, "none left: its name leaves the save (counts are one or more)")
	ok(BoxPanel.sell(data, Save.boxed(data, {}), "Crown", 300) == nil, "none to sell: refused")
	ok(data.cash == 314, "and nothing paid")
	ok(BoxPanel.sell(data, Save.boxed(data, {}), "Teddy", 0) == nil, "no price: refused")
	ok(data.finds.Teddy == 2, "and nothing struck off")
end

print(`boxpanel: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
