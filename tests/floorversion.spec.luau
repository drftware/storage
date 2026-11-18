--!strict
-- Each next-floor card felt on its floor (S4-03c1, D-406): the team picked a version on the ride
-- up, and the floor's deal is that version from the moment its gate opens. Twice the padlocks
-- padlocks twice the doors the floor rules would; twice the monsters puts twice the sleepers
-- behind its doors, twice the awake ones behind a door you lift, and lets twice as many loose at
-- once (never past what a phone carries). A floor nobody picked deals exactly as before. The gate
-- pays the version's coins on top of the floor's own. Run: lune run tests/floorversion.spec
local Brix = require("../vendor/brix/src")
local Deal = require("../src/shared/Deal")
local Floor = require("../src/shared/Floor")
local FloorRules = require("../src/shared/FloorRules")
local NextFloor = require("../src/shared/NextFloor")
local Pay = require("../src/shared/Pay")
local Waking = require("../src/shared/Waking")

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

local SEEDS = 150
local FLOORS = { 2, 3, 8, 15 }

local padlocks = NextFloor.find("TwicePadlocks") :: NextFloor.Version
local monsters = NextFloor.find("TwiceMonsters") :: NextFloor.Version
local powerOut = NextFloor.find("PowerOut") :: NextFloor.Version

local function lay(seed: number, number: number, version: NextFloor.Version?)
	local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
	return floor, Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }), nil, version)
end

local function count(set: { [number]: any }): number
	local n = 0
	for _ in set do
		n += 1
	end
	return n
end

-- 1. Twice the padlocks: twice the floor rules' share of doors (as many as there are doors past
--    the lobby's hall to lock), every door the plain floor padlocks still padlocked, the same code.
for _, number in FLOORS do
	for seed = 1, SEEDS do
		local floor, plain = lay(seed, number)
		local _, bent = lay(seed, number, padlocks)
		local units = #Deal.units(floor)
		local want = math.max(1, math.round(units * FloorRules.at(number).padlocks)) * 2
		local outside = 0
		for _, i in Deal.units(floor) do
			if not plain.firstHall[i] then
				outside += 1
			end
		end
		ok(
			count(bent.padlocked) == math.min(want, outside),
			`floor {number} seed {seed}: {count(bent.padlocked)} padlocked, want {math.min(
				want,
				outside
			)}`
		)
		ok(
			count(bent.padlocked) > count(plain.padlocked),
			`floor {number} seed {seed}: more padlocks`
		)
		for i in plain.padlocked do
			ok(bent.padlocked[i] == true, `floor {number} seed {seed}: unit {i} still padlocked`)
		end
		ok(
			table.concat(bent.code) == table.concat(plain.code),
			`floor {number} seed {seed}: the same code`
		)
	end
end

-- 2. A floor nobody picked, or a version that bends neither, deals exactly as before.
for seed = 1, 40 do
	local _, plain = lay(seed, 4)
	local _, dark = lay(seed, 4, powerOut)
	ok(
		table.concat(plain.code) == table.concat(dark.code),
		`seed {seed}: the power out keeps the code`
	)
	ok(count(plain.padlocked) == count(dark.padlocked), `seed {seed}: and the padlocks`)
	ok(count(plain.sleepers) == count(dark.sleepers), `seed {seed}: and the sleepers`)
	ok(plain.guarded == dark.guarded, `seed {seed}: and the guard`)
end

-- 3. Twice the monsters: every unit's chance of a sleeper doubles, so a floor holds about twice
--    the sleepers; nothing else the seed lays moves (code, padlocks, guard).
do
	local plainSleepers, bentSleepers = 0, 0
	for _, number in FLOORS do
		for seed = 1, SEEDS do
			local floor, plain = lay(seed, number)
			local _, bent = lay(seed, number, monsters)
			plainSleepers += count(plain.sleepers)
			bentSleepers += count(bent.sleepers)
			ok(
				table.concat(bent.code) == table.concat(plain.code),
				`floor {number} seed {seed}: twice the monsters keeps the code`
			)
			ok(bent.guarded == plain.guarded, `floor {number} seed {seed}: and the guard`)
			for _, i in Deal.units(floor) do
				local a, b = Deal.sleeperShare(plain, i), Deal.sleeperShare(bent, i)
				ok(
					math.abs(b - math.min(1, a * 2)) < 1e-9,
					`floor {number} seed {seed} unit {i}: sleeper share {b}, want twice {a}`
				)
			end
		end
	end
	local ratio = bentSleepers / math.max(1, plainSleepers)
	ok(ratio > 1.7 and ratio < 2.3, `about twice the sleepers: {ratio}`)
end

-- 4. Twice the monsters lifts a door's awake odds twice as high (out of its empty share) and lets
--    twice as many loose before a door deals one asleep instead.
do
	local floor, bent = lay(7, 8, monsters)
	local _, plain = lay(7, 8)
	local cap = FloorRules.at(8).awake
	for _, i in Deal.units(floor) do
		if i ~= bent.guarded and not bent.sleepers[i] and not bent.padlocked[i] then
			local p = Deal.odds(plain, i, { mood = "Build", awake = 0 })
			local b = Deal.odds(bent, i, { mood = "Build", awake = 0 })
			ok(b.Awake == p.Awake * 2, `unit {i}: awake odds {b.Awake}, want {p.Awake * 2}`)
			ok(b.Nothing == p.Nothing - p.Awake, `unit {i}: taken from the empty share`)
			-- the guard's place counts until its unit is dealt: cap - 1 loose fills a plain floor
			local full = Deal.odds(plain, i, { mood = "Build", awake = cap - 1 })
			local room = Deal.odds(bent, i, { mood = "Build", awake = cap - 1 })
			ok(full.Awake == 0, `unit {i}: a plain floor at its cap deals none awake`)
			ok(room.Awake > 0, `unit {i}: twice the monsters still has room`)
			local filled = Deal.odds(bent, i, { mood = "Build", awake = cap * 2 - 1 })
			ok(filled.Awake == 0, `unit {i}: and none past twice the cap`)
			break
		end
	end
end

-- 5. The cap on loose monsters: the floor rules' own, twice it for twice the monsters, never past
--    one short of the most awake a phone carries.
for number = 1, 30 do
	local cap = FloorRules.at(number).awake
	ok(Waking.cap(number) == cap, `floor {number}: the cap is the floor rules'`)
	ok(
		Waking.cap(number, 2) == math.min(cap * 2, Waking.AwakeMost - 1),
		`floor {number}: twice the monsters, {Waking.cap(number, 2)}`
	)
	ok(Waking.free(number, cap - 1, 0) and not Waking.free(number, cap, 0), `floor {number}: free`)
	ok(
		Waking.free(number, cap, 0, 2) == (cap < Waking.cap(number, 2)),
		`floor {number}: twice the monsters frees one past the plain cap`
	)
end
ok(Waking.cap(25, 2) == 5, "floor 25: five loose already, twice the monsters stays five")

-- 6. The gate pays the version's coins on top of the floor's own and its traps; not while
--    wrapped, and not again for a ride back.
do
	local paid = {}
	local bonus = NextFloor.payOf(monsters, 6)
	ok(bonus == Pay.forFloor(6), "twice the monsters pays the floor's own again")
	ok(
		Pay.owed(paid, 6, false, 1, bonus) == Pay.forFloor(6) + Pay.Trap + bonus,
		"floor, trap, version"
	)
	ok(Pay.owed(paid, 6, false, 1, bonus) == 0, "a ride back pays nothing again")
	ok(Pay.owed({}, 6, true, 1, bonus) == 0, "wrapped: nothing")
	ok(Pay.owed({}, 6, false, 0, nil) == Pay.forFloor(6), "no version: the floor's own")
	ok(
		Pay.owed({}, 6, false, 0, 0 / 0) == Pay.forFloor(6),
		"a version's pay that isn't a number: none"
	)
end

print(`floorversion.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
