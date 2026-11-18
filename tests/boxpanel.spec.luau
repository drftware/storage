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
local Gold = require("../src/shared/Home/Gold")
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

-- Selling a cracked find (S5-03c3a2, D-296): a name with cracked ones sells a cracked one first,
-- at half (Chip.worth), one off `chipped`, so `chipped` never tops `finds`; the whole ones keep
-- their full price; the card's price says which is next.
do
	ok(BoxPanel.price({ worth = 20 }, nil, true) == 10, "a cracked one's price is half")
	ok(BoxPanel.price({ worth = 1 }, nil, true) == 1, "never under one")
	ok(BoxPanel.price({ worth = 21 }, nil, false) == 21, "a whole one's is its worth")

	local data = Save.fresh()
	data.cash = 0
	data.finds = { Lamp = 3 }
	data.chipped = { Lamp = 2 }
	local boxed = Save.boxed(data, {})
	ok(BoxPanel.sell(data, boxed, "Lamp", 20) == 10, "the first sells cracked, at half")
	ok(data.finds.Lamp == 2 and data.chipped.Lamp == 1, "one fewer owned, one fewer cracked")
	ok(BoxPanel.sell(data, Save.boxed(data, {}), "Lamp", 20) == 20, "the second cracked, at half")
	ok(data.finds.Lamp == 1 and data.chipped.Lamp == nil, "none cracked left: its name leaves")
	ok(BoxPanel.sell(data, Save.boxed(data, {}), "Lamp", 20) == 40, "the whole one, at full")
	ok(data.finds.Lamp == nil and data.cash == 40, "all three sold: 10, 10, 20")

	data.finds = { Lamp = 1 }
	data.chipped = { Lamp = 4 } -- more cracked than owned: a save that slipped
	ok(BoxPanel.sell(data, Save.boxed(data, {}), "Lamp", 20) == 50, "sold cracked")
	ok(data.chipped.Lamp == nil, "cracked never tops what you own")

	data.finds = { Lamp = 2 }
	data.chipped = { Lamp = 1 }
	ok(Save.shelve(data, "Lamp", Save.Fresh.Seen, 6) == 1, "one Lamp on the shelf")
	ok(BoxPanel.sell(data, Save.boxed(data, { Lamp = 1 }), "Lamp", 20) == nil, "none in the box")
	ok(data.chipped.Lamp == 1 and data.cash == 50, "a refused sale cracks nothing off")

	-- what the box sends as it opens: how many of each name in it are cracked, nothing else
	data.finds = { Lamp = 3, Teddy = 2, Vase = 1 }
	data.chipped = { Lamp = 2, Vase = 1 }
	data.shelf = {}
	local cracked = BoxPanel.cracked(data.chipped, Save.boxed(data, { Vase = 1 }))
	ok(cracked.Lamp == 2, "the box's cracked Lamps")
	ok(cracked.Teddy == nil, "no cracked Teddy")
	ok(cracked.Vase == nil, "the Vase is out in your hands: not the box's")
	data.finds.Lamp = 1
	ok(
		BoxPanel.cracked(data.chipped, Save.boxed(data, {})).Lamp == 1,
		"never more than the box holds"
	)

	-- the screen's count after its answers: a sale takes a cracked one first, a Gold four
	local left = BoxPanel.crackedLeft
	ok(left(2, BoxPanel.Ways.Sell) == 1 and left(1, BoxPanel.Ways.Sell) == 0, "a sale: one")
	ok(left(0, BoxPanel.Ways.Sell) == 0, "none cracked stays none")
	ok(left(5, BoxPanel.Ways.Gold) == 1 and left(3, BoxPanel.Ways.Gold) == 0, "a Gold: four")
	ok(left(2, BoxPanel.Ways.Hand) == 2, "taken out: the cracked ones stay in the box")
end

-- Four make a Gold (S5-03c3b, D-298): four of one find in the box become one of its Gold in one
-- step, never from the shelf's or one out; cracked ones go first; a Gold sells at five times;
-- the card counts four fewer and the Gold's is dealt beside it.
do
	ok(BoxPanel.way("Gold") == "Gold", "making a Gold reads as a way")
	ok(Gold.key("Teddy") == "Teddy:Gold" and Gold.base("Teddy:Gold") == "Teddy", "a Gold's key")
	ok(Gold.base("Teddy") == nil and Gold.base(":Gold") == nil, "a find's own key isn't a Gold's")
	ok(
		Gold.can(catalog.Crown) and not Gold.can({ name = "x", grade = "Secret", find = true }),
		"no Secret Golds"
	)
	ok(not Gold.can(catalog.Ladder) and not Gold.can(nil), "a tool, or nothing, can't be")
	ok(BoxPanel.price({ worth = 12 }, true) == 60, "a Gold sells for five times its find")

	local data = Save.fresh()
	data.finds = { Teddy = 3 }
	ok(
		BoxPanel.gold(data, Save.boxed(data, {}), "Teddy", data.stamps.finds, 100) == nil,
		"three: refused"
	)
	ok(data.finds.Teddy == 3 and data.finds["Teddy:Gold"] == nil, "and nothing changed")

	data.finds = { Teddy = 9 }
	data.chipped = { Teddy = 5 }
	ok(Save.shelve(data, "Teddy", Save.Fresh.Seen, 6) == 1, "one Teddy on the shelf")
	local made = 0
	for _ = 1, 5 do
		if BoxPanel.gold(data, Save.boxed(data, {}), "Teddy", data.stamps.finds, 100) then
			made += 1
		end
	end
	ok(made == 2, "eight in the box make two in two asks, the shelf's left alone")
	ok(data.finds.Teddy == 1 and data.finds["Teddy:Gold"] == 2, "nine owned: one left, two Golds")
	ok(data.chipped.Teddy == nil, "the cracked ones went first, and chipped never tops finds")
	ok(data.stamps.finds["Teddy:Gold"] == 100, "the book's page stamped the first time")

	data.finds = { Crown = 5 }
	data.chipped = { Crown = 2 }
	data.shelf = {}
	ok(
		BoxPanel.gold(data, Save.boxed(data, { Crown = 2 }), "Crown", data.stamps.finds, 200) == nil,
		"two out: three in the box"
	)
	ok(
		BoxPanel.gold(data, Save.boxed(data, {}), "Crown", data.stamps.finds, 200) == "Crown:Gold",
		"all back: made"
	)
	ok(
		data.finds.Crown == 1 and data.chipped.Crown == nil,
		"two cracked of the four, gone with them"
	)
	data.finds["Crown:Gold"] = 4
	ok(
		BoxPanel.gold(data, Save.boxed(data, {}), "Crown:Gold", data.stamps.finds, 200) == nil,
		"a Gold of a Gold: never"
	)

	local cards =
		BoxPanel.cards({ Teddy = 5, Crown = 1, ["Teddy:Gold"] = 1, ["Ladder:Gold"] = 1 }, catalog)
	ok(#cards == 3, "a Gold's card, none for a tool's")
	ok(
		cards[2].key == "Teddy:Gold" and cards[2].name == "Gold Teddy bear",
		"a Gold beside its find"
	)
	ok(BoxPanel.offers(cards[3], catalog.Teddy), "five Teddies: Gold offered")
	ok(not BoxPanel.offers(cards[2], catalog.Teddy), "never on a Gold's card")
	ok(not BoxPanel.offers(cards[1], catalog.Crown), "one Crown: not offered")
	local gold, new = BoxPanel.made(cards, catalog, "Teddy")
	ok(gold == cards[2] and not new and gold.count == 2, "a second Gold counts on its card")
	ok(cards[3].count == 1, "four off the Teddies")
	ok(BoxPanel.made(cards, catalog, "Teddy") == nil, "one left: nothing made")
	local fresh = BoxPanel.cards({ NightLight = 4, Teddy = 1 }, catalog)
	local light, dealt = BoxPanel.made(fresh, catalog, "NightLight")
	ok(dealt and light ~= nil and #fresh == 2, "the last four: their card goes, the Gold's dealt")
	ok(fresh[1].key == "NightLight:Gold" and fresh[2].key == "Teddy", "in its place by name")
end

do -- the furniture in the box (S5-03g4c2): a card a piece, in the counter's order, Set out for floor pieces
	local pieces =
		BoxPanel.pieces({ CampBed = 1, MilkCrate = 2, NeonSign = 1, Chair = 3, Pallet = 0 })
	ok(#pieces == 3, "three pieces: an unknown id and none of one are left out")
	ok(
		pieces[1].piece == "MilkCrate" and pieces[1].count == 2,
		"the crate first, as the counter lists it"
	)
	ok(
		pieces[2].piece == "CampBed" and pieces[3].piece == "NeonSign",
		"then the bed, then the moon"
	)
	ok(pieces[1].key == "MilkCrate:Furniture", "keyed by its placed name, never a find's")
	ok(
		pieces[3].key ~= "NeonSign" and pieces[3].name == "Neon moon",
		"the moon isn't the find NeonSign"
	)
	ok(
		BoxPanel.settable(pieces[2]) and BoxPanel.settable(pieces[3]),
		"a bed sets out, and the moon (S5-03g4d)"
	)
	local finds = BoxPanel.cards({ Teddy = 1, Crown = 1 }, catalog)
	ok(not BoxPanel.settable(finds[1]), "a find is never set out from the panel")
	local all = table.clone(pieces)
	for _, card in finds do
		table.insert(all, card)
	end
	local grades = BoxPanel.grades(all)
	ok(#grades == 2, "the pieces add no rarity chip")
	ok(#BoxPanel.shown(all, "", "Common") == 1, "a rarity shows finds only")
	ok(#BoxPanel.shown(all, "bed", nil) == 1, "the search finds the camp bed")
	ok(BoxPanel.took(all, "CampBed:Furniture") ~= nil and #all == 4, "one set out: its card goes")
	local read = BoxPanel.read({ CampBed = 1 })
	ok(read ~= nil and read.CampBed == 1, "the box's pieces read as a list")
end

-- A sealed find's card (S5-02b2c, D-427): its own, named so, just before its loose ones, priced
-- three times; never made Gold.
do
	local cards = BoxPanel.cards({ Teddy = 5, ["Teddy:Sealed"] = 4, Boombox = 1 }, catalog)
	ok(#cards == 3, "a sealed teddy has a card of its own")
	ok(cards[1].key == "Boombox", "the boombox is rarer")
	local sealed, loose = cards[2], cards[3]
	ok(
		sealed.key == "Teddy:Sealed" and sealed.sealed == true,
		"the sealed one before its loose ones"
	)
	ok(sealed.name == "Sealed Teddy bear" and sealed.base == "Teddy", "named so, of the teddy")
	ok(loose.key == "Teddy" and loose.sealed == nil, "then the loose teddies")
	ok(not BoxPanel.offers(sealed, catalog.Teddy), "four sealed teddies are never made Gold")
	ok(BoxPanel.offers(loose, catalog.Teddy), "five loose ones can be")
	local row = { grade = "Common" :: any, worth = 40 }
	ok(BoxPanel.price(row, false, false, true) == 120, "sealed, three times")
	ok(BoxPanel.price(row) == 40, "loose, its worth")
	local data = Save.fresh()
	data.finds["Teddy:Sealed"] = 4
	ok(
		BoxPanel.gold(data, Save.boxed(data, {}), "Teddy:Sealed", data.stamps.finds, 1) == nil,
		"the server melts no sealed one down either"
	)
	ok(data.finds["Teddy:Sealed"] == 4, "and they're all still there")
end

print(`boxpanel: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
