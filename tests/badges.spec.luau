--!strict
-- lune run tests/badges.spec
-- Best floor and badges (S6-01a): a floor reached raises the best only upward; the book's monsters
-- page stamps a kind once; a badge is earned at floors 10, 25, 50 and 100, for each monster kind
-- stamped and each set whose every find the deal hands out is stamped; only badges with an id and
-- not already given are sent; every set the finds have, and every monster kind, has an id line.
local Badges = require("../src/shared/Badges")
local KeeperRows = require("../src/shared/KeeperRows")
local Rows = require("../src/shared/Finds/Rows")
local Save = require("../src/shared/Save")

-- any: a Save.Data, or a bare table with its best floor and the book's two pages
local function earned(data: any, sets: Badges.Sets): { string }
	return Badges.earned(data.bestFloor, data.stamps.finds, data.stamps.keepers, sets)
end

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

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

-- The best floor: up only, whole floors from 1.
do
	local data = Save.fresh()
	ok(data.bestFloor == 0, "a new player's best floor is 0")
	ok(Save.reached(data, 1) and data.bestFloor == 1, "floor 1 reached is a new best")
	ok(Save.reached(data, 7) and data.bestFloor == 7, "floor 7 reached is a new best")
	ok(not Save.reached(data, 7) and data.bestFloor == 7, "floor 7 again is no new best")
	ok(not Save.reached(data, 3) and data.bestFloor == 7, "a lower floor never lowers it")
	ok(not Save.reached(data, 0) and not Save.reached(data, -4), "no floor below 1")
	ok(not Save.reached(data, 9.5) and data.bestFloor == 7, "no part floors")
	ok(not Save.reached(data, 0 / 0) and data.bestFloor == 7, "not a number is ignored")
end

-- The monsters page: each kind stamped once, with when.
do
	local data = Save.fresh()
	local fresh = Save.trapped(data, { "Mannequin", "Mannequin", "" }, 1794700000.6)
	ok(same(fresh, { "Mannequin" }), "a first Mannequin is stamped once")
	ok(data.stamps.keepers.Mannequin == 1794700000, "stamped with the whole second")
	fresh = Save.trapped(data, { "Packrat", "Mannequin" }, 1794700100)
	ok(same(fresh, { "Packrat" }), "only the new kind is stamped")
	ok(data.stamps.keepers.Mannequin == 1794700000, "a stamp is never moved")
end

-- The sets, from the find rows the deal hands out.
local sets = Badges.sets(Rows)
do
	local made = Badges.sets({
		{ key = "A", set = "One", judged = true },
		{ key = "B", set = "One", judged = false },
		{ key = "C", set = "Two", judged = true },
	})
	ok(same(made.One, { "A" }) and same(made.Two, { "C" }), "a set holds only its judged finds")
	ok(sets.Lights ~= nil and #sets.Lights > 0, "the night-lights are a set")
end

-- What a save has earned.
do
	local data = Save.fresh()
	ok(#earned(data, sets) == 0, "a new player has earned nothing")
	data.bestFloor = 9
	ok(#earned(data, sets) == 0, "floor 9 earns no badge")
	data.bestFloor = 10
	ok(same(earned(data, sets), { "Floor10" }), "floor 10 earns its badge")
	data.bestFloor = 57
	ok(same(earned(data, sets), { "Floor10", "Floor25", "Floor50" }), "57 earns three")
	data.bestFloor = 100
	ok(#earned(data, sets) == 4, "floor 100 earns all four floor badges")
	Save.trapped(data, { "Packrat", "Mannequin" }, 1)
	ok(
		same(earned(data, sets), {
			"Floor10",
			"Floor25",
			"Floor50",
			"Floor100",
			"Trapped:Mannequin",
			"Trapped:Packrat",
		}),
		"the monsters follow the floors, in name order"
	)
	local small = { Tiny = { "A", "B" } }
	local book = { bestFloor = 0, stamps = { finds = { A = 1 }, keepers = {} } }
	ok(#earned(book, small) == 0, "half a set earns nothing")
	book.stamps.finds.B = 2
	ok(same(earned(book, small), { "Set:Tiny" }), "the whole set earns its badge")
	ok(#earned(book, { Empty = {} }) == 0, "an empty set is never finished")
	-- a sealed find's page is its find's name (Save.keep), so it finishes a set as well
	local real = Save.fresh()
	for _, name in sets.Lights do
		Save.keep(real, { name .. ":Sealed" }, 5)
	end
	ok(table.find(earned(real, sets), "Set:Lights") ~= nil, "sealed finds finish a set")
end

-- What's sent to Roblox.
do
	local earned = { "Floor10", "Floor25", "Trapped:Mannequin", "Set:Lights" }
	local ids = { Floor10 = 111, Floor25 = 0, ["Trapped:Mannequin"] = 333, ["Set:Lights"] = 4.5 }
	local awards = Badges.toAward(earned, ids, {})
	ok(#awards == 2, "only whole ids above 0 are sent")
	ok(awards[1].key == "Floor10" and awards[1].id == 111, "in earned order, with its id")
	ok(awards[2].key == "Trapped:Mannequin", "the monster after the floor")
	awards = Badges.toAward(earned, ids, { Floor10 = true })
	ok(#awards == 1 and awards[1].key == "Trapped:Mannequin", "one already given isn't sent again")
end

-- Every set and every monster kind has its line for the owner to fill.
do
	for set in sets do
		ok(Badges.Ids[Badges.setKey(set)] ~= nil, `the {set} set has an id line`)
	end
	for kind in KeeperRows do
		ok(Badges.Ids[Badges.trappedKey(kind)] ~= nil, `the {kind} has an id line`)
	end
	for _, floor in Badges.Floors do
		ok(Badges.Ids[Badges.floorKey(floor)] ~= nil, `floor {floor} has an id line`)
	end
end

print(`badges: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
