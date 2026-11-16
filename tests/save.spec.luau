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

-- A new player: nothing yet, at version 3.
do
	ok(format:latest() == 3, "the save is at version 3")
	local fresh = format:fresh()
	ok(fresh.cash == 0 and fresh.bestFloor == 0, "a new player has no cash and no best floor")
	ok(next(fresh.finds) == nil and next(fresh.sealed) == nil, "a new player keeps no finds")
	ok(
		next(fresh.stamps.finds) == nil
			and next(fresh.stamps.sealed) == nil
			and next(fresh.stamps.keepers) == nil,
		"a new player's book has no stamps"
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
	local back, decodeProblem = format:decode(3, stored)
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
	local newer, newerProblem = format:decode(4, v1)
	ok(newer == nil and newerProblem ~= nil, "a save from a newer version is refused")
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

print(`save.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
