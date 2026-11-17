--!strict
-- lune run tests/boxpanel.spec
-- The job box's panel (S5-03c2b1): one card a kind you own with its count, rarest first, then by
-- name; finds the catalog doesn't know are left out; the search ignores case, spaces and dashes;
-- a rarity narrows to its own; the chips are the rarities you own; the screen refuses a list that
-- isn't one.
local BoxPanel = require("../src/shared/Home/BoxPanel")
local Catalog = require("../src/shared/Tools/Catalog")

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

print(`boxpanel: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
