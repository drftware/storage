--!strict
-- lune run tests/guard.spec
-- The guarded note (L-06b5, D-072) over 400 seeds on every floor: exactly one guarded unit, always
-- holding a note, behind an unlocked door wherever a note is, never in the lobby's hall, never a
-- sleeper's unit (S2-01), the same
-- for the same seed whatever the bag holds; its keeper is always dealt awake, whatever the mood or the cap, and is the
-- same keeper whatever order the doors lift in. Played out with the doors lifted in a shuffled
-- order and the deal told how many are loose (as `Keepers.awakeOn` tells it), the guard trapped
-- partway: the cap is never passed with the guard's place counted from the floor's start, and on
-- floors 1 and 2 every other keeper is dealt asleep until the guard is trapped.
local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local Deal = require("../src/shared/Deal")

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

local SEEDS = 400
local FLOORS = 10

-- A floor's deck from its seed; a floor is laid once and dealt afresh as often as needed.
local function deal(floor: Floor.Floor, seed: number): Deal.Deck
	return Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
end

local SITUATIONS: { Deal.Situation } = {
	{ mood = "Build", awake = 0 },
	{ mood = "Build", awake = 3 }, -- every floor's cap or past it
	{ mood = "Build", awake = 9 },
	{ mood = "Peak", awake = 0 },
	{ mood = "Relief", awake = 0 },
}

local guards, lockedGuards, othersAsleep, othersAwakeAfterTrap = 0, 0, 0, 0
local guardKeepers: { [string]: number } = {}

for seed = 1, SEEDS do
	for number = 1, FLOORS do
		local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
		local deck = deal(floor, seed)
		local where = `seed {seed} floor {number}`
		local units = Deal.units(floor)
		local cap = Deal.awakeCap(number)

		-- Exactly one guarded unit, holding a note.
		local guard = deck.guarded
		ok(guard ~= nil, `{where}: a guarded unit`)
		if not guard then
			continue
		end
		guards += 1
		ok(table.find(units, guard) ~= nil, `{where}: the guarded unit is a unit`)
		local holding = 0
		local unlockedNote = false
		for _, note in deck.notes do
			if note.slot == guard then
				holding += 1
			end
			unlockedNote = unlockedNote or not deck.padlocked[note.slot]
		end
		ok(holding == 1, `{where}: the guarded unit holds a note`)
		if deck.padlocked[guard] then
			lockedGuards += 1
			ok(not unlockedNote, `{where}: a guard behind a padlock only when every note is`)
		end
		ok(not deck.firstHall[guard], `{where}: no guard in the lobby's hall`)
		local twin = deal(floor, seed)
		ok(twin.guarded == guard, `{where}: the same seed guards the same unit`)
		ok(deck.sleepers[guard :: number] == nil, `{where}: no sleeper in the guard's unit (S2-01)`)

		-- Its keeper is always awake, in every mood, at the cap and past it.
		for _, situation in SITUATIONS do
			local fresh = deal(floor, seed)
			local got = Deal.open(fresh, guard, situation)
			ok(
				got.kind == "Awake",
				`{where}: the guard is awake ({situation.mood}, {situation.awake})`
			)
			ok(got.keeper ~= nil, `{where}: the guard is a keeper`)
		end
		local first = Deal.open(twin, guard, { mood = "Build", awake = 0 })
		guardKeepers[first.keeper or "none"] = (guardKeepers[first.keeper or "none"] or 0) + 1

		-- Played out: doors in a shuffled order, the guard trapped at a random point once dealt.
		local order = table.clone(units)
		local shuffler = Brix.Random.new({ seed = seed * 31 + number })
		for i = #order, 2, -1 do
			local j = shuffler:nextInteger(1, i)
			order[i], order[j] = order[j], order[i]
		end
		local trapAfter = shuffler:nextInteger(1, #order)
		local loose, trapped = 0, false
		for k, i in order do
			local got = Deal.open(deck, i, { mood = "Build", awake = loose })
			if got.kind == "Awake" then
				loose += 1
			end
			local held = if deck.dealt[guard] then 0 else 1
			ok(loose + held <= cap, `{where}: never past the cap with the guard's place kept`)
			if i == guard then
				ok(got.kind == "Awake", `{where}: the guard is awake when its door lifts`)
				ok(got.keeper == first.keeper, `{where}: the same guard whatever the order`)
			elseif got.kind == "Asleep" and not trapped then
				othersAsleep += 1
			elseif got.kind == "Awake" then
				if number <= 2 then
					ok(
						trapped,
						`{where}: on floors 1 and 2 only the guard is awake until it's trapped`
					)
				end
				if trapped then
					othersAwakeAfterTrap += 1
				end
			end
			if deck.dealt[guard] and not trapped and k >= trapAfter then
				trapped = true
				loose -= 1 -- a trapped keeper takes no place (`Keeper.loose`)
			end
		end
	end
end

-- The guard is drawn before the bag (D-098), so changing the bag's tools or counts never moves a
-- seed's guard (the Studio recipes and the owner's steps lean on seed 7, floor 1's in Unit 157).
do
	local saved = table.clone(Deal.Bag)
	local floors: { Floor.Floor } = {}
	local before: { number } = {}
	for seed = 1, 100 do
		for number = 1, 3 do
			local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
			table.insert(floors, floor)
			table.insert(before, deal(floor, seed).guarded :: number)
		end
	end
	Deal.Bag.Saw += 3
	Deal.Bag.Ladder += 1
	for k, floor in floors do
		local seed = (k - 1) // 3 + 1
		ok(
			deal(floor, seed).guarded == before[k],
			`seed {seed} floor {floor.number}: a bigger bag moved the guard`
		)
	end
	for key, count in saved do
		Deal.Bag[key] = count
	end
end

-- Enough of every case to judge.
ok(guards == SEEDS * FLOORS, `a guard on every floor: {guards}`)
ok(guardKeepers.Mannequin == guards, "the guard is a keeper that has joined")
ok(othersAsleep > 1000, `other keepers dealt asleep while the guard is loose: {othersAsleep}`)
ok(
	othersAwakeAfterTrap > 50,
	`others dealt awake once the guard is trapped: {othersAwakeAfterTrap}`
)

if failures > 0 then
	print(`guard: {failures} of {checks} checks failed`)
	error("guard spec failed")
end
print(
	`guard: {checks} checks passed ({lockedGuards} of {guards} guards behind a padlock, every note locked)`
)
