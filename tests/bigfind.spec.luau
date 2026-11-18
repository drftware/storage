--!strict
--[[
	The floor's big find (S4-05b1, D-415, src/shared/BigFind.luau): its grade roll, the find it
	deals with the jukebox standing in for grades none is built for, the unit it's dealt into as the
	code goes in (never one opened, padlocked, a note's, a sleeper's or packed; down the halls
	before the lobby's), and that unit dealt the big find alone, never in any other unit's deal.

		lune run tests/bigfind.spec
]]
local Brix = require("../vendor/brix/src")
local BigFind = require("../src/shared/BigFind")
local Deal = require("../src/shared/Deal")
local Floor = require("../src/shared/Floor")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

-- Floors: none on 1, one from 2.
ok(not BigFind.on(1), "floor 1 has no big find")
ok(BigFind.on(2) and BigFind.on(40), "floors 2 and up have one")

-- The grade roll: 75, 22 and 3 in 100, read off evenly spread rolls.
local counts: { [string]: number } = {}
local N = 10000
for i = 0, N - 1 do
	local g = BigFind.gradeFrom((i + 0.5) / N)
	counts[g] = (counts[g] or 0) + 1
end
ok(counts.Epic == 7500, `Epic 75 in 100 ({counts.Epic})`)
ok(counts.Legendary == 2200, `Legendary 22 in 100 ({counts.Legendary})`)
ok(counts.Secret == 300, `Secret 3 in 100 ({counts.Secret})`)
ok(BigFind.gradeFrom(0) == "Epic" and BigFind.gradeFrom(1) == "Secret", "the roll's ends")

-- The find: the jukebox is built, and stands in for every grade while it's the only one.
ok(#BigFind.Finds >= 1 and BigFind.Finds[1].key == "Jukebox", "the jukebox is the first built")
for _, roll in { 0, 0.5, 0.8, 0.99 } do
	ok(BigFind.findFrom(roll, 0.3) ~= nil, `a find for roll {roll}`)
end
local made: { BigFind.Find } = {
	{ key = "Jukebox", grade = "Legendary" },
	{ key = "Arcade", grade = "Epic" },
	{ key = "Fridge", grade = "Epic" },
}
ok(BigFind.findFrom(0.1, 0, made) == "Arcade", "an Epic roll, the first Epic")
ok(BigFind.findFrom(0.1, 0.99, made) == "Fridge", "an Epic roll, the last Epic")
ok(BigFind.findFrom(0.8, 0.5, made) == "Jukebox", "a Legendary roll, the Legendary")
ok(BigFind.findFrom(0.99, 0.5, made) == "Jukebox", "a Secret roll with none built: the first")
ok(BigFind.findFrom(0.5, 0.5, {}) == nil, "nothing built, nothing dealt")

-- No unit's own deal ever holds a big find.
for _, key in Deal.Finds do
	for _, f in BigFind.Finds do
		ok(key ~= f.key, `{key} is not in a unit's deal`)
	end
end

-- The unit, across many floors: one that fits, down the halls when any is left, dealt alone.
local placed, far = 0, 0
for seed = 1, 120 do
	local number = 2 + seed % 12
	local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local deck = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
	local units = Deal.units(floor)
	-- the team has opened the first few by the time the code goes in
	local BUILD: Deal.Situation = { mood = "Build", awake = 0 }
	for i = 1, math.min(3, #units) do
		Deal.open(deck, units[i], BUILD)
	end
	local open: { number } = {}
	local anyFar = false
	for _, index in units do
		if deck.dealt[index] == nil then
			table.insert(open, index)
			if BigFind.fits(deck, index) and not deck.firstHall[index] then
				anyFar = true
			end
		end
	end
	local index = BigFind.unitFrom(deck, open, (seed * 0.618) % 1)
	if not index then
		continue
	end
	placed += 1
	ok(deck.dealt[index] == nil, `seed {seed}: never a unit already opened`)
	ok(not deck.padlocked[index], `seed {seed}: never padlocked`)
	ok(deck.sleepers[index] == nil, `seed {seed}: never a sleeper's`)
	ok(Deal.noteIn(deck, index) == nil, `seed {seed}: never a note's`)
	ok(not deck.packed[index] and deck.guarded ~= index, `seed {seed}: never packed or guarded`)
	ok(not anyFar or not deck.firstHall[index], `seed {seed}: down the halls when one is left`)
	if not deck.firstHall[index] then
		far += 1
	end
	deck.big[index] = "Jukebox"
	ok(not BigFind.fits(deck, index), `seed {seed}: one big find a unit`)
	local got = Deal.open(deck, index, { mood = "Peak", awake = 9 })
	ok(got.kind == "Find" and got.find == "Jukebox", `seed {seed}: the big find is dealt`)
	ok(got.coins == 0 and got.stuff == nil and got.keeper == nil, `seed {seed}: alone`)
	ok(Deal.open(deck, index, BUILD) == got, `seed {seed}: dealt once`)
end
ok(placed >= 110, `nearly every floor has a unit for it ({placed} of 120)`)

-- None left: every unit opened.
do
	local floor = Floor.generate(4, Brix.Random.new({ seed = 77 }))
	local deck = Deal.new(floor, Brix.Random.new({ seed = 77 + 1000000 }))
	ok(BigFind.unitFrom(deck, {}, 0.5) == nil, "no unit left, no big find")
end

print(
	`bigfind.spec: {checks - failures}/{checks} passed ({placed} floors placed, {far} down the halls)`
)
if failures > 0 then
	error(`{failures} failed`)
end
