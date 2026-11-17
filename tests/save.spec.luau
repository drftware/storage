--!strict
-- lune run tests/save.spec
-- A player's save (S1-01): a new player starts with nothing; a save keeps everything through a
-- round trip and through Brix's Saves over the loopback store, across two servers; a save the shape
-- refuses is never written; a sample of every shipped version still loads; and the format passes
-- Brix's SaveFormat conformance suite.
local Brix = require("../vendor/brix/src")
local Save = require("../src/shared/Save")
local Suite = require("../vendor/brix/tests/conformance/SaveFormat")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local format = Save.format(Brix)

-- A save with something in every field, as a player some climbs in would have.
local function played(): Save.Data
	local data = Save.fresh()
	data.cash = 1250
	data.finds.Boombox = 1
	data.finds.Teddy = 2
	data.sealed.Skates = 1
	data.stamps.finds.Boombox = 1794700000
	data.stamps.finds.Teddy = 1794700100
	data.stamps.finds.Skates = 1794700200
	data.stamps.sealed.Skates = 1794700200
	data.stamps.keepers.Mannequin = 1794700300
	data.bestFloor = 7
	data.purchases = { "a1b2c3", "d4e5f6" }
	data.recipients.freeAFriend = "player_42"
	data.bought.cutFree = 2
	data.spares.cutFree = 1
	data.wraps.wrapBlue = 1794700400
	data.wornWrap = "wrapBlue"
	data.shelf = {
		{ find = "Boombox", fresh = Save.Fresh.Seen },
		{ find = "", fresh = Save.Fresh.Seen },
		{ find = "Teddy", fresh = Save.Fresh.Kind },
	}
	data.boxFresh = Save.Fresh.New
	data.chipped.Teddy = 1
	data.placed = {
		form = 1,
		rows = {
			{ id = "Teddy#1", on = "Floor", x = 2.5, y = -4, turn = 90 },
			{ id = "Boombox#1", on = "JobBoxTop", x = 0, y = 0, turn = 0 },
		},
	}
	data.furniture.CampBed = 1
	data.furniture.MilkCrate = 2
	return data
end

-- Whether two values hold the same data.
local function same(a: unknown, b: unknown): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	local x = a :: { [unknown]: unknown }
	local y = b :: { [unknown]: unknown }
	for k, v in x do
		if not same(v, y[k]) then
			return false
		end
	end
	for k in y do
		if x[k] == nil then
			return false
		end
	end
	return true
end

-- A new player: nothing yet, at version 12.
do
	ok(format:latest() == 12, "the save is at version 12")
	local fresh = format:fresh()
	ok(fresh.cash == 0 and fresh.bestFloor == 0, "a new player has no cash and no best floor")
	ok(next(fresh.finds) == nil and next(fresh.sealed) == nil, "a new player keeps no finds")
	ok(
		next(fresh.stamps.finds) == nil
			and next(fresh.stamps.sealed) == nil
			and next(fresh.stamps.keepers) == nil,
		"a new player's book has no stamps"
	)
	ok(
		next(fresh.wraps) == nil and fresh.wornWrap == "",
		"a new player owns no wrap colours and wears the plain film"
	)
	ok(#fresh.shelf == 0, "a new player's shelf is empty")
	ok(fresh.boxFresh == Save.Fresh.Seen, "a new player's job box is quiet")
	ok(next(fresh.chipped) == nil, "a new player has nothing cracked")
	ok(fresh.placed.form == 1 and #fresh.placed.rows == 0, "a new player has nothing set out")
	ok(next(fresh.furniture) == nil, "a new player owns no furniture")
	ok(
		fresh.looks.paint == "WarmWhite"
			and fresh.looks.floor == "Boards"
			and fresh.looks.door == "Clay"
			and fresh.looks.card == "Stencil",
		"a new home is warm white on boards behind a clay door, its name stencilled"
	)
	ok(fresh ~= format:fresh(), "each new save is its own table")
	local stored, problem = format:encode(fresh)
	ok(stored ~= nil and problem == nil, `a new save can be stored ({problem})`)
end

-- A round trip keeps everything.
do
	local data = played()
	local stored, problem = format:encode(data)
	ok(stored ~= nil, `a played save can be stored ({problem})`)
	local back, decodeProblem = format:decode(12, stored)
	ok(back ~= nil and same(back, data), `a played save comes back the same ({decodeProblem})`)
end

-- What the shape refuses is never stored.
do
	local function refused(what: string, change: (data: any) -> ())
		local data = played()
		change(data)
		local stored, problem = format:encode(data)
		ok(stored == nil and problem ~= nil, `refuses {what}`)
	end
	refused("negative cash", function(data)
		data.cash = -5
	end)
	refused("cash that isn't whole", function(data)
		data.cash = 2.5
	end)
	refused("cash that isn't a number", function(data)
		data.cash = math.huge
	end)
	refused("a find kept zero times", function(data)
		data.finds.Boombox = 0
	end)
	refused("a find with no name", function(data)
		data.finds[""] = 1
	end)
	refused("a piece of furniture owned zero times", function(data)
		data.furniture.CampBed = 0
	end)
	refused("half a piece of furniture", function(data)
		data.furniture.CampBed = 1.5
	end)
	refused("a field the save doesn't have", function(data)
		data.gems = 3
	end)
	refused("a missing field", function(data)
		data.bestFloor = nil
	end)
	refused("a best floor below zero", function(data)
		data.bestFloor = -1
	end)
	refused("a stamp that isn't a time", function(data)
		data.stamps.keepers.Mannequin = true
	end)
end

-- Every shipped version's sample still loads, and a save from a newer game is refused.
do
	-- Version 1 as the DataStore holds it (Nov 14).
	local v1 = {
		cash = 40,
		finds = { Television = 1 },
		sealed = {},
		stamps = { finds = { Television = 1794700000 }, sealed = {}, keepers = {} },
		bestFloor = 3,
	}
	local data, problem = format:decode(1, v1)
	ok(
		data ~= nil and data.cash == 40 and data.finds.Television == 1 and data.bestFloor == 3,
		`version 1 loads ({problem})`
	)
	ok(
		data ~= nil
			and #data.purchases == 0
			and next(data.recipients) == nil
			and next(data.bought) == nil,
		"version 1 comes up with no purchases"
	)
	-- Version 2 as the DataStore holds it (Nov 15): a Test purchase granted.
	local v2 = {
		cash = 12,
		finds = {},
		sealed = {},
		stamps = { finds = {}, sealed = {}, keepers = {} },
		bestFloor = 2,
		purchases = { "p1" },
		recipients = {},
		bought = { testPurchase = 1 },
	}
	local two, twoProblem = format:decode(2, v2)
	ok(
		two ~= nil
			and two.purchases[1] == "p1"
			and two.bought.testPurchase == 1
			and next(two.spares) == nil,
		`version 2 loads with its purchases and no spares ({twoProblem})`
	)
	-- Version 3 as the DataStore holds it (Nov 15): a Cut Free waiting as a spare.
	local v3 = {
		cash = 7,
		finds = {},
		sealed = {},
		stamps = { finds = {}, sealed = {}, keepers = {} },
		bestFloor = 3,
		purchases = { "p1", "p2" },
		recipients = {},
		bought = { cutFree = 2 },
		spares = { cutFree = 1 },
	}
	local three, threeProblem = format:decode(3, v3)
	ok(
		three ~= nil
			and three.spares.cutFree == 1
			and three.bought.cutFree == 2
			and next(three.wraps) == nil
			and three.wornWrap == "",
		`version 3 loads with its spares, no wrap colours and the plain film ({threeProblem})`
	)
	-- Version 4 as the DataStore holds it (Nov 15): a wrap colour worn.
	local v4 = {
		cash = 7,
		finds = { Teddy = 1 },
		sealed = {},
		stamps = { finds = { Teddy = 1794700100 }, sealed = {}, keepers = {} },
		bestFloor = 3,
		purchases = {},
		recipients = {},
		bought = { wrapBlue = 1 },
		spares = {},
		wraps = { wrapBlue = 1794700400 },
		wornWrap = "wrapBlue",
	}
	local four, fourProblem = format:decode(4, v4)
	ok(
		four ~= nil and four.wornWrap == "wrapBlue" and four.finds.Teddy == 1 and #four.shelf == 0,
		`version 4 loads with its wrap and an empty shelf ({fourProblem})`
	)
	-- Version 5 as the DataStore holds it (Nov 17): finds on the shelf, one still new.
	local v5 = {
		cash = 7,
		finds = { Teddy = 2 },
		sealed = {},
		stamps = { finds = { Teddy = 1794700100 }, sealed = {}, keepers = {} },
		bestFloor = 3,
		purchases = {},
		recipients = {},
		bought = {},
		spares = {},
		wraps = {},
		wornWrap = "",
		shelf = { { find = "Teddy", fresh = 1 }, { find = "", fresh = 0 } },
	}
	local five, fiveProblem = format:decode(5, v5)
	ok(
		five ~= nil
			and #five.shelf == 2
			and five.shelf[1].find == "Teddy"
			and five.shelf[1].fresh == Save.Fresh.New
			and five.boxFresh == Save.Fresh.Seen,
		`version 5 loads with its shelf and a quiet job box ({fiveProblem})`
	)
	-- Version 6 as the DataStore holds it (Nov 17): the job box new; nothing cracked yet.
	local v6 = table.clone(v5)
	v6.boxFresh = 1
	local six, sixProblem = format:decode(6, v6)
	ok(
		six ~= nil
			and six.boxFresh == Save.Fresh.New
			and six.finds.Teddy == 2
			and #six.shelf == 2
			and next(six.chipped) == nil,
		`version 6 loads with its job box and nothing cracked ({sixProblem})`
	)
	-- Version 7 as the DataStore holds it (Nov 17): a Teddy cracked; nothing set out yet.
	local v7 = table.clone(v6)
	v7.chipped = { Teddy = 1 }
	local seven, sevenProblem = format:decode(7, v7)
	ok(
		seven ~= nil
			and seven.chipped.Teddy == 1
			and seven.finds.Teddy == 2
			and #seven.shelf == 2
			and seven.placed.form == 1
			and #seven.placed.rows == 0,
		`version 7 loads with its cracks and nothing set out ({sevenProblem})`
	)
	local v8 = table.clone(v7)
	v8.placed = { form = 1, rows = { { id = "Teddy#1", on = "Floor", x = 1, y = 2, turn = 90 } } }
	local eight, eightProblem = format:decode(8, v8)
	ok(
		eight ~= nil
			and #eight.placed.rows == 1
			and eight.chipped.Teddy == 1
			and eight.looks.paint == "WarmWhite"
			and eight.looks.paper == "Plain"
			and eight.looks.floor == "Boards"
			and eight.looks.floorColour == "",
		`version 8 loads with what's set out and the home as it always looked ({eightProblem})`
	)
	-- Version 9 as the DataStore holds it (Nov 17): a home in sage leaves; its door as it was.
	local v9 = table.clone(v8)
	v9.looks = { paint = "Sage", paper = "Leaves", floor = "Carpet", floorColour = "Rose" }
	local nine, nineProblem = format:decode(9, v9)
	ok(
		nine ~= nil
			and nine.looks.paper == "Leaves"
			and nine.looks.floorColour == "Rose"
			and nine.looks.door == "Clay"
			and #nine.placed.rows == 1,
		`version 9 loads with its look and a clay door ({nineProblem})`
	)
	-- Version 10 as the DataStore holds it (Nov 17): a mustard door; its card as it was.
	local v10 = table.clone(v9)
	v10.looks = table.clone(v9.looks)
	v10.looks.door = "Mustard"
	local ten, tenProblem = format:decode(10, v10)
	ok(
		ten ~= nil
			and ten.looks.door == "Mustard"
			and ten.looks.paper == "Leaves"
			and ten.looks.card == "Stencil"
			and #ten.placed.rows == 1,
		`version 10 loads with its door and the stencilled card ({tenProblem})`
	)
	-- Version 11 as the DataStore holds it (Nov 17): a chalk card; no furniture yet.
	local v11 = table.clone(v10)
	v11.looks = table.clone(v10.looks)
	v11.looks.card = "Chalk"
	local eleven, elevenProblem = format:decode(11, v11)
	ok(
		eleven ~= nil
			and eleven.looks.card == "Chalk"
			and eleven.looks.door == "Mustard"
			and eleven.cash == v11.cash
			and #eleven.placed.rows == 1
			and next(eleven.furniture) == nil,
		`version 11 loads with its card and no furniture ({elevenProblem})`
	)
	local dressed = format:fresh()
	dressed.looks = {
		paint = "Sage",
		paper = "Leaves",
		floor = "Carpet",
		floorColour = "Rose",
		door = "Mustard",
		card = "Chalk",
	}
	local kept = format:encode(dressed)
	local dressedBack = format:decode(12, kept)
	ok(
		dressedBack ~= nil
			and dressedBack.looks.paper == "Leaves"
			and dressedBack.looks.floorColour == "Rose"
			and dressedBack.looks.door == "Mustard"
			and dressedBack.looks.card == "Chalk",
		"a home's look, its door and its card are kept"
	)
	local newer, newerProblem = format:decode(13, v1)
	ok(newer == nil and newerProblem ~= nil, "a save from a newer version is refused")
end

-- Finds kept at the gate land on the shelf (D-284): the first empty spot of the unit's, new, or a
-- kind never owned; past the unit's spots they're kept but not shown; a spot is seen once.
do
	local data = Save.fresh()
	local stamped = Save.keep(data, { "Teddy", "Teddy", "Boombox" }, 100, 2)
	ok(#stamped == 2 and stamped[1] == "Teddy" and stamped[2] == "Boombox", "two kinds stamped")
	ok(data.finds.Teddy == 2 and data.finds.Boombox == 1, "every kept find is counted")
	ok(
		#data.shelf == 2
			and data.shelf[1].find == "Teddy"
			and data.shelf[1].fresh == Save.Fresh.Kind
			and data.shelf[2].find == "Teddy"
			and data.shelf[2].fresh == Save.Fresh.New,
		"the first teddy is a new kind, the second only new, and the boombox finds the shelf full"
	)
	ok(data.boxFresh == Save.Fresh.Kind, "the boombox went in the job box, a kind never owned")
	ok(Save.open(data) == Save.Fresh.Kind, "opening the box finds the new kind in it")
	ok(data.boxFresh == Save.Fresh.Seen and Save.open(data) == Save.Fresh.Seen, "then it's quiet")
	ok(Save.seen(data, 1) and data.shelf[1].fresh == Save.Fresh.Seen, "walking up marks it seen")
	ok(not Save.seen(data, 1), "a spot is seen once")
	ok(not Save.seen(data, 5), "a spot past the shelf is never seen")
	data.shelf[1].find = ""
	Save.keep(data, { "Teddy" }, 200, 2)
	ok(
		data.shelf[1].find == "Teddy" and data.shelf[1].fresh == Save.Fresh.New,
		"an emptied spot takes the next find, a kind you own now only new"
	)
	Save.keep(data, { "Boombox" }, 300)
	ok(#data.shelf == 2 and data.finds.Boombox == 2, "with no spots given, nothing lands")
	ok(data.boxFresh == Save.Fresh.New, "it goes in the job box, only new: a kind you own")
	Save.keep(data, { "Teddy" }, 400, 2)
	ok(data.boxFresh == Save.Fresh.New, "the box stays as new as the newest that went in")
	local stored, problem = format:encode(data)
	ok(stored ~= nil, `a save with a shelf can be stored ({problem})`)
	local full = Save.fresh()
	for _ = 1, Save.ShelfMost + 3 do
		Save.keep(full, { "Teddy" }, 1, 99)
	end
	ok(#full.shelf == Save.ShelfMost, "the shelf never holds more than the largest unit's")
end

-- Keys: one per player, under the 50 characters a DataStore key may have, and back to the UserId.
do
	ok(Save.key(1234567) == "player_1234567", "a save's key names the player")
	ok(#Save.key(9007199254740991) <= 50, "the longest UserId's key fits a DataStore")
	ok(Save.userId(Save.key(81234567)) == 81234567, "a key gives back its UserId")
	ok(Save.userId("other") == nil, "a key that isn't a player's has no UserId")
end

-- Held by one server at a time through Brix's Saves: claimed fresh, kept, let go, found by the next.
do
	local store = Brix.SaveStore.loopback()
	local clock = 1000
	local function now(): number
		return clock
	end
	local first = Brix.Saves.new({ format = format, store = store, now = now, server = "first" })
	local second = Brix.Saves.new({ format = format, store = store, now = now, server = "second" })
	local key = Save.key(1234567)

	local data, refusal = first:claim(key)
	ok(
		data ~= nil and refusal == nil and (data :: Save.Data).cash == 0,
		"a new player's save is claimed fresh"
	)
	local _, held = second:claim(key)
	ok(held ~= nil and held.reason == "held", "a second server can't claim a held save")

	local mine = data :: Save.Data
	mine.cash = 75
	mine.bestFloor = 4
	ok(first:save(key) == nil, "a changed save is written")

	-- A bad change is refused, and the last good save stays.
	mine.cash = -1
	local bad = first:save(key)
	ok(bad ~= nil and bad.reason == "unsaveable", "a save the shape refuses isn't written")
	mine.cash = 75

	ok(first:release(key) == nil, "the save is let go as the player leaves")
	local again, againRefusal = second:claim(key)
	ok(
		again ~= nil and (again :: Save.Data).cash == 75 and (again :: Save.Data).bestFloor == 4,
		`the next server finds what the first saved ({againRefusal and againRefusal.message})`
	)
end

-- Brix's SaveFormat conformance suite: every promise a save format makes.
do
	local cases = Suite.cases({
		name = "Save",
		make = function()
			return Save.format(Brix) :: any
		end,
		samples = { Save.fresh(), played() },
	})
	for label, case in cases do
		local passed, err = pcall(case)
		ok(passed, `{label}: {err}`)
	end
end

-- Finds kept with cracked glass (F-G1e5e): counted per name, never more than you keep.
do
	local data = Save.fresh()
	Save.keep(data, { "OilLamp", "OilLamp" }, 1794700000, 0)
	Save.chip(data, { "OilLamp" })
	ok(data.finds.OilLamp == 2 and data.chipped.OilLamp == 1, "one of two oil lamps kept cracked")
	Save.chip(data, { "OilLamp", "OilLamp" })
	ok(data.chipped.OilLamp == 2, "never more cracked than kept")
	Save.chip(data, { "Teddy" })
	ok(data.chipped.Teddy == nil, "a find you don't keep is never marked cracked")
	local stored = format:encode(data)
	local back = format:decode(format:latest(), stored)
	ok(back ~= nil and back.chipped.OilLamp == 2, "the cracks are saved")
end

-- Finds set out in your home (S5-03e2, D-308): still yours, never in the box as well, never two;
-- a broken row is never stored.
do
	local data = Save.fresh()
	data.finds.Teddy = 3
	data.finds["Teddy:Gold"] = 1
	data.shelf = { { find = "Teddy", fresh = Save.Fresh.Seen } }
	data.placed.rows = {
		{ id = "Teddy#1", on = "Floor", x = 0, y = 0, turn = 0 },
		{ id = "Teddy:Gold#1", on = "ShelfTop", x = 1, y = 0, turn = 45 },
	}
	local counts = Save.placedCounts(data)
	ok(counts.Teddy == 1 and counts["Teddy:Gold"] == 1, "set out counted by name, a Gold its own")
	local boxed = Save.boxed(data, { Teddy = 1 })
	ok(boxed.Teddy == nil, "three teddies: one shelved, one set out, one in hand, none in the box")
	ok(boxed["Teddy:Gold"] == nil, "the Gold set out is out of the box")
	ok(data.finds.Teddy == 3, "a find set out is still owned")
	ok(Save.placedName("Teddy:Gold#12") == "Teddy:Gold", "a Gold's id names the Gold")
	ok(Save.placedName("Floor") == nil and Save.placedName("#3") == nil, "an area is no find")
	local stored, problem = format:encode(data)
	ok(stored ~= nil, `what's set out can be stored ({problem})`)
	local back = format:decode(format:latest(), stored)
	ok(back ~= nil and #back.placed.rows == 2 and back.placed.rows[2].turn == 45, "set out, saved")
	data.placed.rows[1].x = 0 / 0
	local nan = format:encode(data)
	ok(nan == nil, "a pose that isn't a number is never stored")
	data.placed.rows[1].x = 0
	data.placed.rows[1].turn = 720
	ok(format:encode(data) == nil, "a turn past a whole turn is never stored")
end

print(`save.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
