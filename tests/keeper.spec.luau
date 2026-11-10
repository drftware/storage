--!strict
-- lune run tests/keeper.spec
-- The keepers' brain (L-06b2a): every row keeps the GDD's speed rule; a keeper hears a door
-- exactly when its trip to the door along the map is within the sound's reach (DoorSound's, as a
-- player hears it), so never through a wall or a shut door; heard, it walks the halls to the
-- door's front, never faster than its walking pace and never into a unit whose door is down,
-- arriving when the trip's length says; stands there facing the door for its linger; then roams
-- (L-06b3a1, D-071). A newer sound takes it there, a roam included; a door coming down across its
-- way stops it where it is. Dealt (L-06b2b): asleep it stays still until a sound wakes it, and
-- never sleeps again; awake, it steps out to look once its own door is up, facing out of the
-- unit. Roaming: once out it never goes back into a unit, never stops for good, keeps to the
-- halls at its walk, goes some way off each time, never back to a place it stood in lately, and
-- the same seed roams the same way; shut in its unit, it watches until its door is up. Sight
-- (L-06b3a2): it notices exactly within its sight and view along a line the map clears, hunts at
-- no more than its top speed to arm's length, and, lost, searches where it saw you, then roams.
-- It says its pace and how far it walks before it stops (for screens, L-06b4a). The catch
-- (L-06b3c): hunting, it catches the one it hunts exactly within Brix's cone reach along its map,
-- along a clear line, never asleep, frozen or anyone else, then stands its linger and roams.
-- And a warm keeper's steps allocate nothing, a roam's picks and a hunt included.
local Brix = require("../vendor/brix/src")
local DoorSound = require("../src/shared/StorageUnit/DoorSound")
local Floor = require("../src/shared/Floor")
local Keeper = require("../src/shared/Keeper")
local KeeperMap = require("../src/shared/KeeperMap")
local KeeperRows = require("../src/shared/KeeperRows")

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

local RUN = 16 -- a player's full run (Roblox's default walk; there's no sprint)
local DT = 1 / 60 -- the Host's fixed step
local SLAM = DoorSound.Actions.Slam.Reach
local MANNEQUIN = KeeperRows.Mannequin
local PACE = MANNEQUIN.speed * MANNEQUIN.looking * RUN -- its walk, studs a second
local STEP = PACE * DT -- studs a step
-- positions are vectors, 32-bit floats: a few hundred studs out they're good to about 3e-5
local TOL = 2e-3
-- the Random keepers roam by in checks that don't look at where they roam
local RANDOM = Brix.Random.new({ seed = 1 })

local function flat(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end
local function middleOf(map: KeeperMap.Map, i: number): vector
	return vector.create((map.minX[i] + map.maxX[i]) / 2, 0, (map.minZ[i] + map.maxZ[i]) / 2)
end
local function inPlace(map: KeeperMap.Map, i: number, p: vector): boolean
	local e = 1e-3
	return p.x >= map.minX[i] - e
		and p.x <= map.maxX[i] + e
		and p.z >= map.minZ[i] - e
		and p.z <= map.maxZ[i] + e
end
-- on a hall place's floor (not in a unit, not off the map)
local function inHall(map: KeeperMap.Map, p: vector): boolean
	for i = 1, #map.minX do
		if map.unit[i] == 0 and inPlace(map, i, p) then
			return true
		end
	end
	return false
end
local function facingToward(k: Keeper.Keeper, p: vector): boolean
	local d = vector.create(p.x - k.at.x, 0, p.z - k.at.z)
	local m = vector.magnitude(d)
	return m < 1e-6 or vector.dot(k.facing, d / m) > 0.999
end
local function unitLength(v: vector): boolean
	return math.abs(vector.magnitude(v) - 1) < 1e-4 and v.y == 0
end

-- Rows: the GDD's speed rule (no keeper outruns a running player) and sane numbers.
for name, row in KeeperRows do
	ok(row.name == name, `row {name} is named for itself`)
	ok(row.speed > 0 and row.speed <= 1, `{name}'s top speed is within a player's run`)
	ok(row.looking > 0 and row.looking <= 1, `{name} looks at a pace within its top speed`)
	ok(row.hearing >= 0, `{name}'s hearing isn't negative`)
	ok(row.linger > 0, `{name} lingers a while`)
	ok(row.roamNear >= 0 and row.roamFar > row.roamNear, `{name} roams some way off`)
	ok(row.roamLinger > 0, `{name} stops a while on a roam`)
	ok(row.roamMemory >= 1 and row.roamMemory % 1 == 0, `{name} remembers where it's been`)
	for _, a in row.abilities do
		ok(table.find(KeeperMap.Abilities, a) ~= nil, `{name}'s ability {a} is one the map knows`)
	end
end
ok(#MANNEQUIN.abilities == 0, "the Mannequin only walks")

-- What keepers hear: the GDD's loud door sounds, never a peek.
ok(
	Keeper.Hears.Open and Keeper.Hears.Slam and Keeper.Hears.LiftInside,
	"keepers hear the loud ones"
)
ok(not Keeper.Hears.Peek, "a peek is quiet")

-- Walks a keeper until it's no longer in `state` (or `cap` steps). Returns the steps it took, the
-- longest flat move in one step, and whether it ever left the halls.
local function walkOut(
	k: Keeper.Keeper,
	map: KeeperMap.Map,
	state: Keeper.State,
	cap: number
): (number, number, boolean)
	local steps, longest, strayed = 0, 0, false
	while k.state == state and steps < cap do
		local before = k.at
		Keeper.step(k, DT, RUN)
		steps += 1
		longest = math.max(longest, flat(before, k.at))
		if not inHall(map, k.at) then
			strayed = true
		end
	end
	return steps, longest, strayed
end

-- Steps a keeper `seconds` with no sounds. Returns whether it ever left the halls (went into a
-- unit or off the map), and the longest it stood without moving (seconds).
local function roamFor(k: Keeper.Keeper, map: KeeperMap.Map, seconds: number): (boolean, number)
	local strayed, stood, still = false, 0, 0
	for _ = 1, math.ceil(seconds / DT) do
		local before = k.at
		Keeper.step(k, DT, RUN)
		if flat(before, k.at) > 1e-6 then
			stood = 0
		else
			stood += DT
			still = math.max(still, stood)
		end
		if not inHall(map, k.at) then
			strayed = true
		end
	end
	return strayed, still
end

local floors, heardCount, wallCount, walks = 0, 0, 0, 0
local function checkFloor(seed: number, number: number)
	local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local where = `floor {number} seed {seed}`
	local map = KeeperMap.build(f)
	local walker = KeeperMap.pathing(map, MANNEQUIN.abilities)
	floors += 1

	-- the halls' places to stand keepers in, and the units' doors
	local halls: { number } = {}
	for i = 1, #map.minX do
		if map.unit[i] == 0 then
			table.insert(halls, i)
		end
	end
	local doors: { number } = {}
	for i, s in f.slots do
		if s.kind == "Unit" then
			table.insert(doors, i)
		end
	end

	-- every door's front is in the hall, square in front of it
	for _, i in doors do
		local spot, door = Keeper.front(f.slots[i])
		local fx, fz = Floor.dir(f.slots[i].facing)
		ok(inHall(map, spot), `{where}: unit {f.slots[i].number}'s front is in the hall`)
		ok(
			math.abs(flat(spot, door) - Keeper.Front) < 1e-4
				and vector.dot(spot - door, vector.create(fx, 0, fz)) > 0,
			`{where}: unit {f.slots[i].number}'s front is out from its door`
		)
	end

	-- hearing: exactly when the trip along the map is within the reach
	for h = 1, #halls, math.max(1, #halls // 8) do
		local at = middleOf(map, halls[h])
		for d = 1, #doors, math.max(1, #doors // 12) do
			local slot = doors[d]
			local spot, door = Keeper.front(f.slots[slot])
			local k = Keeper.new(MANNEQUIN, map, RANDOM, at, vector.create(0, 0, -1))
			local trip = walker:length(at, door)
			local heard = Keeper.hear(k, door, SLAM, spot)
			ok(
				(heard ~= nil) == (trip <= SLAM),
				`{where}: heard a slam {trip} studs off along the map`
			)
			if heard then
				heardCount += 1
				ok(math.abs(heard - trip) < 1e-6, `{where}: says how far off it heard`)
				ok(
					k.state == "Going" and k.goal == spot,
					`{where}: heard, it goes to the door's front`
				)
			else
				ok(k.state == "Asleep", `{where}: unheard, it sleeps on`)
				if flat(at, door) <= SLAM then
					wallCount += 1 -- in a straight line it's in reach: the walls kept it out
				end
			end
			-- a deaf row hears nothing
			local deafRow = table.clone(MANNEQUIN)
			deafRow.hearing = 0
			local deaf = Keeper.new(deafRow, map, RANDOM, at, vector.create(0, 0, -1))
			ok(Keeper.hear(deaf, door, SLAM, spot) == nil, `{where}: a deaf keeper hears nothing`)
		end
	end

	-- the walk there and back, from a few halls to a few doors
	for h = 1, #halls, math.max(1, #halls // 3) do
		local home = middleOf(map, halls[h])
		for d = 1, #doors, math.max(1, #doors // 3) do
			local slot = doors[d]
			local spot, door = Keeper.front(f.slots[slot])
			local k = Keeper.new(MANNEQUIN, map, RANDOM, home, vector.create(1, 0, 0))
			if Keeper.hear(k, door, SLAM, spot) then
				walks += 1
				local trip = walker:length(home, spot)
				ok(
					math.abs(Keeper.left(k) - trip) < 1e-6,
					`{where}: it says how far it walks before it stops`
				)
				ok(math.abs(Keeper.pace(k, RUN) - PACE) < 1e-9, `{where}: it says its walking pace`)
				local steps, longest, strayed = walkOut(k, map, "Going", 100000)
				ok(k.state == "Waiting", `{where}: it gets to the door ({k.state})`)
				ok(
					Keeper.left(k) == 0 and Keeper.pace(k, RUN) == 0,
					`{where}: standing, it walks no further`
				)
				ok(flat(k.at, spot) < TOL, `{where}: it stands at the door's front`)
				ok(
					longest <= STEP + TOL,
					`{where}: never faster than its walk ({longest} > {STEP})`
				)
				ok(not strayed, `{where}: never off the halls with every door down`)
				-- it arrives when the trip's length says, at its walking pace
				local expected = math.ceil(trip / STEP - 1e-6)
				ok(
					math.abs(steps - expected) <= 1,
					`{where}: a {trip}-stud trip took {steps} steps, not {expected}`
				)
				ok(facingToward(k, door), `{where}: it waits facing the door`)
				ok(unitLength(k.facing), `{where}: its facing is flat and length 1`)
				-- it lingers, then wanders off to a stop some way off
				local waited = walkOut(k, map, "Waiting", 100000)
				local linger = math.ceil(MANNEQUIN.linger / DT - 1e-6)
				ok(math.abs(waited - linger) <= 1, `{where}: lingered {waited} steps, not {linger}`)
				ok(k.state == "Roaming", `{where}: then it roams ({k.state})`)
				ok(Keeper.awake(k), `{where}: woken, it stays awake`)
				local goalPlace = KeeperMap.placeAt(map, k.goal)
				ok(
					table.find(map.stops, goalPlace) ~= nil
						and flat(k.goal, middleOf(map, goalPlace)) < TOL,
					`{where}: to a hall piece's middle`
				)
				ok(
					goalPlace ~= KeeperMap.placeAt(map, spot),
					`{where}: not the place it just looked from`
				)
				local trip2 = walker:length(k.at, k.goal)
				ok(
					trip2 >= MANNEQUIN.roamNear and trip2 <= MANNEQUIN.roamFar,
					`{where}: some way off ({trip2} studs)`
				)
				local _, roamLongest, roamStrayed = walkOut(k, map, "Roaming", 100000)
				ok(k.state == "Waiting" and flat(k.at, k.goal) < TOL, `{where}: it gets there`)
				ok(
					roamLongest <= STEP + TOL and not roamStrayed,
					`{where}: a roam is a walk along the halls too`
				)
				waited = walkOut(k, map, "Waiting", 100000)
				linger = math.ceil(MANNEQUIN.roamLinger / DT - 1e-6)
				ok(
					math.abs(waited - linger) <= 1,
					`{where}: stopped {waited} steps on its roam, not {linger}`
				)
				ok(k.state == "Roaming", `{where}: and walks on`)
			end
		end
	end

	-- a newer sound takes it there, and one cuts a roam short
	if #doors >= 2 then
		local home = middleOf(map, KeeperMap.placeAt(map, vector.zero))
		local a, b = doors[1], doors[#doors]
		local spotA, doorA = Keeper.front(f.slots[a])
		local spotB, doorB = Keeper.front(f.slots[b])
		local k = Keeper.new(MANNEQUIN, map, RANDOM, home, vector.create(0, 0, -1))
		local huge = 1e6 -- a sound heard anywhere: this checks the turn, not the reach
		Keeper.hear(k, doorA, huge, spotA)
		for _ = 1, 30 do
			Keeper.step(k, DT, RUN)
		end
		Keeper.hear(k, doorB, huge, spotB)
		ok(k.state == "Going" and k.goal == spotB, `{where}: a newer sound takes it there`)
		walkOut(k, map, "Going", 100000)
		ok(flat(k.at, spotB) < TOL, `{where}: it looks at the newer sound`)
		walkOut(k, map, "Waiting", 100000)
		for _ = 1, 30 do
			Keeper.step(k, DT, RUN)
		end
		ok(k.state == "Roaming", `{where}: roaming`)
		Keeper.hear(k, doorA, huge, spotA)
		ok(k.state == "Going" and k.goal == spotA, `{where}: roaming, a sound turns it round`)
		walkOut(k, map, "Going", 100000)
		ok(flat(k.at, spotA) < TOL, `{where}: and it goes to look`)
	end
end

for seed = 1, 30 do
	checkFloor(seed, 1 + seed % 10) -- every floor's plan
end
ok(heardCount > 100, `enough keepers heard to check ({heardCount})`)
ok(wallCount > 20, `enough sounds were kept out by walls to check ({wallCount})`)
ok(walks > 30, `enough walks to check ({walks})`)

-- Shut doors: a keeper in a unit hears nothing through its door; with it up, it hears and walks
-- out; a door coming down across its way stops it where it is. Once out it roams and never goes
-- back in, its own door up or down; shut in before it got out, it watches until its door is up.
do
	local f = Floor.generate(4, Brix.Random.new({ seed = 11 }))
	local map = KeeperMap.build(f)
	-- a unit with a neighbour door along the hall within a slam's reach
	local inside: number?, near: number? = nil, nil
	for i, s in f.slots do
		if s.kind == "Unit" and not inside then
			for j, t in f.slots do
				if j ~= i and t.kind == "Unit" and t.cell == s.cell then
					inside, near = i, j
					break
				end
			end
		end
	end
	assert(inside and near, "a hall piece with two units")
	local unitPlace = 0
	for i = 1, #map.minX do
		if map.unit[i] == inside then
			unitPlace = i
		end
	end
	local dealt = middleOf(map, unitPlace)
	local spot, door = Keeper.front(f.slots[near])
	local k = Keeper.new(MANNEQUIN, map, RANDOM, dealt, vector.create(0, 0, 1))
	ok(Keeper.hear(k, door, SLAM, spot) == nil, "shut in a unit, it hears nothing through the door")
	KeeperMap.setDoor(map, inside, true)
	ok(Keeper.hear(k, door, SLAM, spot) ~= nil, "with the door up it hears the slam next door")
	-- it walks out, and its door comes down behind it once it's in the hall
	local out = 0
	while not inHall(map, k.at) and out < 10000 do
		Keeper.step(k, DT, RUN)
		out += 1
	end
	for _ = 1, 3 do
		Keeper.step(k, DT, RUN) -- clear of the doorway's line
	end
	KeeperMap.setDoor(map, inside, false)
	walkOut(k, map, "Going", 100000)
	ok(k.state == "Waiting" and flat(k.at, spot) < TOL, "out in the hall, it still gets there")
	walkOut(k, map, "Waiting", 100000)
	ok(k.state == "Roaming", `its own door shut behind it, it roams ({k.state})`)
	-- it roams on, its door down for a minute, then up for two: it never goes back in
	local strayed, still = roamFor(k, map, 60)
	KeeperMap.setDoor(map, inside, true)
	local strayed2, still2 = roamFor(k, map, 120)
	ok(not strayed and not strayed2, "out, it never goes back into a unit, its own door up or down")
	ok(
		math.max(still, still2) <= MANNEQUIN.linger + 2 * DT,
		`it never stops for good ({math.max(still, still2)} s still)`
	)

	-- a door coming down across its way stops it where it is, facing the sound
	local k2 = Keeper.new(MANNEQUIN, map, RANDOM, dealt, vector.create(0, 0, 1))
	Keeper.hear(k2, door, SLAM, spot)
	Keeper.step(k2, DT, RUN)
	KeeperMap.setDoor(map, inside, false)
	local at = k2.at
	Keeper.step(k2, DT, RUN)
	ok(k2.state == "Waiting", `a door down across its way stops it ({k2.state})`)
	ok(flat(k2.at, at) < TOL, "where it was")
	ok(facingToward(k2, door), "facing the sound")
	-- still in its unit with the door down, it has nowhere to roam: it stands watching
	walkOut(k2, map, "Waiting", 100000)
	ok(k2.state == "Watching" and Keeper.awake(k2), `shut in, it watches ({k2.state})`)
	ok(flat(k2.at, at) < TOL, "where it stopped")
	-- its door up as it sets off to roam and down across its way: it picks again, and shut in
	-- again, it watches
	KeeperMap.setDoor(map, inside, true)
	ok(Keeper.lookOut(k2, f.slots[inside], inside), "its door up, it steps out to look")
	KeeperMap.setDoor(map, inside, false)
	Keeper.step(k2, DT, RUN)
	ok(k2.state == "Waiting", "stopped in its unit again")
	while k2.waited + DT < k2.wait do
		Keeper.step(k2, DT, RUN)
	end
	KeeperMap.setDoor(map, inside, true)
	Keeper.step(k2, DT, RUN)
	ok(k2.state == "Roaming", `the door up again as it stops looking, it roams ({k2.state})`)
	Keeper.step(k2, DT, RUN)
	KeeperMap.setDoor(map, inside, false)
	local before = k2.at
	Keeper.step(k2, DT, RUN)
	ok(
		k2.state == "Watching" and flat(k2.at, before) < TOL,
		`its door down across its roam, with nowhere else to go it watches ({k2.state})`
	)

	-- Dealt in the unit (L-06b2b): asleep, it's still and not awake; awake, it watches.
	local own, ownDoor = Keeper.front(f.slots[inside])
	local fx, fz = Floor.dir(f.slots[inside].facing)
	local out3 = vector.create(fx, 0, fz) -- out of the unit, into the hall
	local towardDoor = vector.create(ownDoor.x - dealt.x, 0, ownDoor.z - dealt.z)
	towardDoor = towardDoor / vector.magnitude(towardDoor)
	KeeperMap.setDoor(map, inside, false)
	local sleeper = Keeper.new(MANNEQUIN, map, RANDOM, dealt, towardDoor)
	local watcher = Keeper.new(MANNEQUIN, map, RANDOM, dealt, towardDoor, true)
	ok(sleeper.state == "Asleep" and not Keeper.awake(sleeper), "dealt asleep, it sleeps")
	ok(watcher.state == "Watching" and Keeper.awake(watcher), "dealt awake, it watches")
	for _ = 1, 120 do
		ok(not Keeper.step(sleeper, DT, RUN), "asleep, nothing about it changes")
		ok(not Keeper.step(watcher, DT, RUN), "watching, it stands where it is")
	end
	ok(flat(sleeper.at, dealt) < TOL and flat(watcher.at, dealt) < TOL, "both stand where dealt")

	-- its door all the way up: an asleep one stays asleep; an awake one steps out to look
	KeeperMap.setDoor(map, inside, true)
	ok(not Keeper.lookOut(sleeper, f.slots[inside], inside), "asleep, its door going up leaves it")
	ok(sleeper.state == "Asleep", "still asleep")
	ok(not Keeper.lookOut(watcher, f.slots[near], near), "another unit's door isn't its own")
	ok(Keeper.lookOut(watcher, f.slots[inside], inside), "awake, it steps out as its door gets up")
	ok(watcher.state == "Going" and watcher.goal == own, "to its own door's front")
	ok(
		not Keeper.lookOut(watcher, f.slots[inside], inside),
		"already on its way, it isn't sent twice"
	)
	local _, longest, _ = walkOut(watcher, map, "Going", 100000)
	ok(watcher.state == "Waiting" and flat(watcher.at, own) < TOL, "it stands at its door's front")
	ok(longest <= STEP + TOL, "at a walk")
	ok(vector.dot(watcher.facing, out3) > 0.999, "facing out into the hall, away from its door")
	walkOut(watcher, map, "Waiting", 100000)
	ok(watcher.state == "Roaming", `then it wanders off ({watcher.state})`)
	local watcherStrayed = roamFor(watcher, map, 90)
	ok(not watcherStrayed, "and never goes back in, its door up the whole time")
	ok(
		not Keeper.lookOut(watcher, f.slots[inside], inside),
		"out in the hall, its door going up again doesn't send it"
	)
	-- out in the hall, an awake keeper isn't in that unit: its door going up again leaves it
	local roamer = Keeper.new(MANNEQUIN, map, RANDOM, own, out3, true)
	ok(not Keeper.lookOut(roamer, f.slots[inside], inside), "a keeper in the hall isn't sent")

	-- a sound wakes the sleeper, and once woken it never sleeps again, nor goes back in
	ok(Keeper.hear(sleeper, door, SLAM, spot) ~= nil, "a slam next door reaches it, door up")
	ok(sleeper.state == "Going" and Keeper.awake(sleeper), "it wakes and goes to look")
	walkOut(sleeper, map, "Going", 100000)
	walkOut(sleeper, map, "Waiting", 100000)
	ok(sleeper.state == "Roaming", `woken, it roams after looking ({sleeper.state})`)
	local sleeperStrayed, sleeperStill = roamFor(sleeper, map, 90)
	ok(not sleeperStrayed, "never back in where it slept")
	ok(sleeperStill <= MANNEQUIN.roamLinger + 2 * DT, "and never stops for good")
	ok(Keeper.awake(sleeper), "awake for good")
	KeeperMap.setDoor(map, inside, false)
end

-- Roaming, on every floor's plan: an awake keeper stood in the lobby looks at a far door, then
-- roams for four minutes with no more sounds. It keeps to the halls at its walk, never stands
-- still longer than a linger, goes some way off each time, and never stops where it stood in its
-- last few stops. The same seed roams the same way.
do
	local roams, banded, floorsRoamed = 0, 0, 0
	for seed = 1, 30 do
		local f = Floor.generate(1 + seed % 10, Brix.Random.new({ seed = seed }))
		local where = `roaming, floor {1 + seed % 10} seed {seed}`
		local map = KeeperMap.build(f)
		local walker = KeeperMap.pathing(map, MANNEQUIN.abilities)
		local lobby = middleOf(map, KeeperMap.placeAt(map, vector.zero))
		local last = 0
		for i, s in f.slots do
			if s.kind == "Unit" then
				last = i
			end
		end
		local spot, door = Keeper.front(f.slots[last])
		local function oneRoam(): (Keeper.Keeper, boolean, number, number, { number })
			local k = Keeper.new(
				MANNEQUIN,
				map,
				Brix.Random.new({ seed = seed }),
				lobby,
				vector.one,
				true
			)
			Keeper.hear(k, door, 1e6, spot)
			walkOut(k, map, "Going", 100000)
			walkOut(k, map, "Waiting", 100000)
			-- each roam's trip, measured as it sets off
			local was = k.state
			local count, inBand = 0, 0
			local strayed, still, longest = false, 0, 0
			local stops: { number } = {}
			local stood = 0
			for _ = 1, math.ceil(240 / DT) do
				if k.state == "Roaming" and was ~= "Roaming" then
					count += 1
					local d = walker:length(k.at, k.goal)
					if d >= MANNEQUIN.roamNear and d <= MANNEQUIN.roamFar then
						inBand += 1
					end
				end
				was = k.state
				local before = k.at
				Keeper.step(k, DT, RUN)
				local moved = flat(before, k.at)
				longest = math.max(longest, moved)
				if moved > 1e-6 then
					stood = 0
				else
					stood += DT
					still = math.max(still, stood)
				end
				if not inHall(map, k.at) then
					strayed = true
				end
				if k.state == "Waiting" and was == "Roaming" then
					table.insert(stops, (KeeperMap.placeAt(map, k.at)))
				end
			end
			roams += count
			banded += inBand
			return k, strayed, still, longest, stops
		end
		local k, strayed, still, longest, stops = oneRoam()
		floorsRoamed += 1
		ok(not strayed, `{where}: it keeps to the halls`)
		ok(
			still <= math.max(MANNEQUIN.linger, MANNEQUIN.roamLinger) + 2 * DT,
			`{where}: it never stops for good ({still} s still)`
		)
		ok(longest <= STEP + TOL, `{where}: at its walk ({longest})`)
		ok(Keeper.awake(k) and k.state ~= "Watching", `{where}: still roaming ({k.state})`)
		ok(#stops >= 8, `{where}: it stopped at enough places to check ({#stops})`)
		for i, p in stops do
			ok(table.find(map.stops, p) ~= nil, `{where}: each stop is a hall piece's middle`)
			for j = math.max(1, i - MANNEQUIN.roamMemory), i - 1 do
				ok(stops[j] ~= p, `{where}: stop {i} isn't one of its last few ({j})`)
			end
		end
		-- the same seed, the same roam
		local _, _, _, _, again = oneRoam()
		local same = #again == #stops
		for i, p in stops do
			same = same and again[i] == p
		end
		ok(same, `{where}: the same seed roams the same way`)
	end
	ok(floorsRoamed == 30, "every floor roamed")
	ok(banded >= roams * 0.95, `nearly every roam goes some way off ({banded} of {roams})`)
end

-- Two halls off: the hall middle whose trip from the lobby is nearest the asked length.
do
	local f = Floor.generate(3, Brix.Random.new({ seed = 7 }))
	local map = KeeperMap.build(f)
	local walker = KeeperMap.pathing(map)
	local at, facing = Keeper.hallAbout(map, walker, vector.zero, 60)
	local best = math.huge
	local lobby = KeeperMap.placeAt(map, vector.zero)
	for i = 1, #map.minX do
		if map.unit[i] == 0 and i ~= lobby then
			best = math.min(best, math.abs(walker:length(middleOf(map, i), vector.zero) - 60))
		end
	end
	ok(
		math.abs(math.abs(walker:length(at, vector.zero) - 60) - best) < 1e-6,
		"the nearest to 60 studs off"
	)
	ok(inHall(map, at), "in a hall")
	ok(unitLength(facing), "facing flat, length 1")
	local back = KeeperMap.trip(walker, at, vector.zero)
	ok(back ~= nil and vector.dot(facing, back[1] - at) > 0, "facing the way back to the lobby")
end

-- Sight and the hunt (L-06b3a2), on seeded floors of every plan. An awake keeper notices a player
-- exactly when they're within its sight and its view's width and the map clears the line between
-- them (so never through a wall or a shut door, `KeeperMap.clear`), never up on the tops, and
-- never while asleep; it hunts the nearest. Hunting, it comes at them along the halls no faster
-- than its top speed (never over a player's run) and stops at arm's length facing them; no sound
-- pulls it off. Lost, it rushes to where it last saw them, stands there its linger, then roams; a
-- sound while it searches takes it to look.
local noticed, hunts, searches = 0, 0, 0
do
	local SIGHT = MANNEQUIN.sight
	local TOP = MANNEQUIN.speed * RUN * DT -- studs a step at its top speed
	local srng = Brix.Random.new({ seed = 99 })
	local players = Keeper.players()
	local function only(id: number, p: vector)
		players.ids[1], players.at[1], players.count = id, p, 1
	end
	local function turned(v: vector, degrees: number): vector
		local r = math.rad(degrees)
		local c, sn = math.cos(r), math.sin(r)
		return vector.create(v.x * c - v.z * sn, 0, v.x * sn + v.z * c)
	end
	for seed = 1, 10 do
		local number = (seed - 1) % 10 + 1
		local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
		local map = KeeperMap.build(f)
		local where = `floor {number} seed {seed}`
		local halls: { number } = {}
		for i = 1, #map.minX do
			if map.unit[i] == 0 then
				table.insert(halls, i)
			end
		end
		local function hallPoint(): vector
			local i = halls[srng:nextInteger(1, #halls)]
			local x = map.minX[i] + srng:nextNumber() * (map.maxX[i] - map.minX[i])
			local z = map.minZ[i] + srng:nextNumber() * (map.maxZ[i] - map.minZ[i])
			return vector.create(x, 0, z)
		end

		-- noticing: exactly within its sight and view, along a line the map clears
		local long: { vector }? = nil -- a keeper's spot and a player's, clear and far apart
		for _ = 1, 150 do
			local a = hallPoint()
			local r = math.rad(srng:nextNumber() * 360)
			local b = a
				+ vector.create(math.cos(r), 0, math.sin(r)) * (srng:nextNumber() * SIGHT * 1.4)
			local d = flat(a, b)
			if d > 0.1 then
				local toward = vector.create(b.x - a.x, 0, b.z - a.z) / d
				local clear = KeeperMap.clear(map, a, b)
				if clear and d >= SIGHT * 0.6 and d <= SIGHT then
					long = { a, b }
				end
				for _, angle in { 0, 50, -55, 70, -110, 180 } do
					local k = Keeper.new(MANNEQUIN, map, RANDOM, a, turned(toward, angle), true)
					only(7, b)
					Keeper.step(k, DT, RUN, players)
					local expect = clear and d <= SIGHT and math.abs(angle) <= MANNEQUIN.sightAngle
					ok(
						(k.state == "Hunting") == expect,
						`{where}: a keeper at {a} turned {angle} from a player {d} off ({clear}) {if expect
							then "sees"
							else "doesn't see"} them`
					)
					if expect then
						noticed += 1
						ok(k.target == 7, `{where}: it hunts the one it saw`)
						ok(flat(k.seen, b) < 1e-6, `{where}: it knows where it saw them`)
					end
					Keeper.release(k)
				end
				-- asleep, it sees nothing; up on the tops, nobody is seen; a jump still is
				local asleep = Keeper.new(MANNEQUIN, map, RANDOM, a, toward, false)
				Keeper.step(asleep, DT, RUN, players)
				ok(asleep.state == "Asleep", `{where}: asleep, it sees nothing`)
				Keeper.release(asleep)
				local up = Keeper.new(MANNEQUIN, map, RANDOM, a, toward, true)
				only(7, b + vector.create(0, 10, 0))
				Keeper.step(up, DT, RUN, players)
				ok(up.state == "Watching", `{where}: a player up on the tops is out of its sight`)
				Keeper.release(up)
				local jump = Keeper.new(MANNEQUIN, map, RANDOM, a, toward, true)
				only(7, b + vector.create(0, 6, 0))
				Keeper.step(jump, DT, RUN, players)
				ok(
					(jump.state == "Hunting") == (clear and d <= SIGHT),
					`{where}: a jumping player is seen as one standing`
				)
				Keeper.release(jump)
			end
		end

		-- the hunt: no faster than its top speed, to arm's length, facing them; then lost
		if long then
			local a, b = long[1], long[2]
			local k = Keeper.new(MANNEQUIN, map, RANDOM, a, b - a, true)
			only(3, b)
			local fastest, closest = 0, math.huge
			for _ = 1, math.ceil(SIGHT / TOP) + 120 do
				local before = k.at
				Keeper.step(k, DT, RUN, players)
				fastest = math.max(fastest, flat(before, k.at))
				closest = math.min(closest, flat(k.at, b))
				ok(k.state == "Hunting", `{where}: it keeps hunting someone it sees`)
				ok(Keeper.hear(k, b, 1e6, b) == nil, `{where}: no sound calls it off a hunt`)
			end
			hunts += 1
			ok(fastest <= TOP + TOL, `{where}: it hunts no faster than its top speed ({fastest})`)
			ok(closest >= Keeper.Close - TOL, `{where}: it stops at arm's length ({closest})`)
			ok(flat(k.at, b) <= Keeper.Close + 0.05, `{where}: it gets to arm's length`)
			ok(facingToward(k, b), `{where}: it stands facing them`)
			-- they climb onto the tops: lost, it rushes to where it last saw them
			only(3, b + vector.create(0, 10, 0))
			Keeper.step(k, DT, RUN, players)
			ok(
				k.state == "Searching" and k.target == 0,
				`{where}: out of its sight, it's lost them`
			)
			local steps, longest, strayed = walkOut(k, map, "Searching", 2000)
			searches += 1
			ok(longest <= TOP + TOL, `{where}: it searches no faster than its top speed`)
			ok(not strayed and steps < 2000, `{where}: it gets to where it saw them`)
			ok(flat(k.at, b) <= 1e-2, `{where}: it stands where it last saw them`)
			ok(k.state == "Waiting", `{where}: it stands there looking`)
			local waited = walkOut(k, map, "Waiting", 2000)
			ok(
				math.abs(waited * DT - MANNEQUIN.linger) <= DT * 1.5,
				`{where}: it looks there for its linger ({waited * DT} s)`
			)
			ok(k.state == "Roaming", `{where}: then it roams`)
			Keeper.release(k)

			-- the nearest of two it sees
			local near = a + (b - a) * 0.4
			local two = Keeper.new(MANNEQUIN, map, RANDOM, a, b - a, true)
			players.ids[1], players.at[1] = 1, b
			players.ids[2], players.at[2] = 2, near
			players.count = 2
			Keeper.step(two, DT, RUN, players)
			ok(two.target == 2, `{where}: it hunts the nearest it sees`)
			-- lost while searching, a sound takes it to look
			players.count = 0
			Keeper.step(two, DT, RUN, players)
			ok(two.state == "Searching", `{where}: it searches`)
			local spot, door = Keeper.front(f.slots[next(map.doorways) :: number])
			ok(
				Keeper.hear(two, door, 1e6, spot) ~= nil and two.state == "Going",
				`{where}: searching, a sound takes it to look`
			)
			Keeper.release(two)
		end

		-- a keeper in its unit, facing the doorway: a player in the hall in front is hidden while
		-- the door is down, seen once it's up, and never seen past the door's posts
		for slot in map.doorways do
			local s = f.slots[slot]
			local fx, fz = Floor.dir(s.facing)
			local out = vector.create(fx, 0, fz)
			local door = vector.create(s.x, 0, s.z)
			local k = Keeper.new(MANNEQUIN, map, RANDOM, door - out * 2, out, true)
			only(5, door + out * 3)
			KeeperMap.setDoor(map, slot, false)
			Keeper.step(k, DT, RUN, players)
			ok(k.state == "Watching", `{where}: unit {s.number}'s shut door hides you from it`)
			KeeperMap.setDoor(map, slot, true)
			Keeper.step(k, DT, RUN, players)
			ok(k.state == "Hunting", `{where}: unit {s.number}'s door up, it sees you in front`)
			Keeper.release(k)
			local across = vector.create(-fz, 0, fx) * (Floor.Sizes[s.size].width / 2 - 0.4)
			local beside = door + out * 3 + across
			if inHall(map, beside) then
				local post = Keeper.new(MANNEQUIN, map, RANDOM, door - out + across, out, true)
				only(5, beside)
				Keeper.step(post, DT, RUN, players)
				ok(post.state == "Watching", `{where}: unit {s.number}'s post hides you`)
				Keeper.release(post)
			end
			KeeperMap.setDoor(map, slot, false)
		end
	end
	ok(noticed > 300 and hunts >= 8, `enough sightings and hunts to check ({noticed}, {hunts})`)
end

-- Light (L-06b3b): the Mannequin moves only while no light is on it. In a hall under a lit hall
-- light's pool, or in a torch's beam that reaches it along a line the map clears, it holds where
-- it stands, facing as it was, keeping its state, its trip and its clocks, however long; the
-- light gone, it carries on exactly as a twin never lit does. Frozen, it still sees, so it may
-- start hunting you, but it never turns. A beam lights it exactly within its reach and cone
-- (Torch's), never through a wall, a shut door or round a corner; a hall light never lights it
-- inside a unit; asleep it's never lit; and a row that doesn't freeze in light never does.
local frozenRuns, torchHits, torchMisses, torchWalled = 0, 0, 0, 0
do
	local Torch = require("../src/shared/Flashlight/Torch")
	local lrng = Brix.Random.new({ seed = 77 })
	local EYE = 4.5 -- a player's eyes over their feet
	local HALF = Torch.BeamAngle / 2
	local REACH = Torch.BeamRange
	local players = Keeper.players()
	-- one player, feet at `feet`, their torch pointing `aim` (length 1; zero: off)
	local function holding(id: number, feet: vector, aim: vector)
		players.ids[1], players.at[1] = id, feet
		players.eye[1], players.aim[1] = feet + vector.create(0, EYE, 0), aim
		players.count = 1
	end
	local function toward(from: vector, to: vector): vector
		return vector.normalize(to - from)
	end
	-- `v` turned `yaw` degrees about the vertical and tipped `pitch` degrees up
	local function swung(v: vector, yaw: number, pitch: number): vector
		local r = math.rad(yaw)
		local c, s = math.cos(r), math.sin(r)
		local x, z = v.x * c - v.z * s, v.x * s + v.z * c
		local across = math.sqrt(x * x + z * z)
		local up = math.atan2(v.y, across) + math.rad(pitch)
		return vector.create(x / across * math.cos(up), math.sin(up), z / across * math.cos(up))
	end

	for seed = 1, 10 do
		local number = (seed - 1) % 10 + 1
		local f = Floor.generate(number, Brix.Random.new({ seed = seed + 300 }))
		local map = KeeperMap.build(f)
		local where = `floor {number} seed {seed + 300}`
		local halls: { number } = {}
		for i = 1, #map.minX do
			if map.unit[i] == 0 and map.y[i] == 0 then
				table.insert(halls, i)
			end
		end
		local function hallPoint(): vector
			local i = halls[lrng:nextInteger(1, #halls)]
			local x = map.minX[i] + lrng:nextNumber() * (map.maxX[i] - map.minX[i])
			local z = map.minZ[i] + lrng:nextNumber() * (map.maxZ[i] - map.minZ[i])
			return vector.create(x, 0, z)
		end
		local units: { number } = {}
		for i, s in f.slots do
			if s.kind == "Unit" then
				table.insert(units, i)
			end
		end

		-- held and carried on: twins hear the same slam and roam on the same seed; one is held by
		-- a hall light now and then, however long, and comes out of it exactly where its twin is
		do
			local start = hallPoint()
			local r = math.rad(lrng:nextNumber() * 360)
			local face = vector.create(math.cos(r), 0, math.sin(r))
			local a =
				Keeper.new(MANNEQUIN, map, Brix.Random.new({ seed = seed }), start, face, true)
			local b =
				Keeper.new(MANNEQUIN, map, Brix.Random.new({ seed = seed }), start, face, true)
			local spot, door = Keeper.front(f.slots[units[lrng:nextInteger(1, #units)]])
			Keeper.hear(a, door, 1e6, spot)
			Keeper.hear(b, door, 1e6, spot)
			local held, same, states = true, true, {}
			for _ = 1, 12 do
				for _ = 1, lrng:nextInteger(1, 400) do
					Keeper.step(a, DT, RUN, nil, false)
					Keeper.step(b, DT, RUN, nil, false)
					same = same
						and a.at == b.at
						and a.facing == b.facing
						and a.state == b.state
						and a.travelled == b.travelled
						and a.lit == 0
				end
				local _, unit = KeeperMap.placeAt(map, a.at)
				if unit == 0 then
					local at, facing, state, goal = a.at, a.facing, a.state, a.goal
					local travelled, waited = a.travelled, a.waited
					states[state] = true
					for i = 1, lrng:nextInteger(1, 300) do
						-- now and then a very long step: however long it's held
						local changed =
							Keeper.step(a, if i % 97 == 0 then 1000 else DT, RUN, nil, true)
						held = held
							and changed
							and a.lit == Keeper.HallLight
							and a.at == at
							and a.facing == facing
							and a.state == state
							and a.goal == goal
							and a.travelled == travelled
							and a.waited == waited
					end
					frozenRuns += 1
				end
			end
			ok(held, `{where}: a hall light holds it where it stands, as it stands, however long`)
			ok(same, `{where}: the light gone, it carries on exactly as its twin`)
			ok(b.travelled > 100, `{where}: the twins walked far enough to check ({b.travelled})`)
		end

		-- a beam lights it exactly within its reach and cone, and only along a line the map clears
		for _ = 1, 400 do
			local a = hallPoint()
			local r = math.rad(lrng:nextNumber() * 360)
			local feet = a
				+ vector.create(math.cos(r), 0, math.sin(r)) * (3 + lrng:nextNumber() * 52)
			local eye = feet + vector.create(0, EYE, 0)
			local h = MANNEQUIN.height
			local aim = swung(
				toward(eye, a + vector.create(0, h * 0.6, 0)),
				(lrng:nextNumber() * 2 - 1) * 45,
				(lrng:nextNumber() * 2 - 1) * 25
			)
			local k = Keeper.new(MANNEQUIN, map, RANDOM, a, vector.one, true)
			local facing = k.facing
			holding(5, feet, aim)
			Keeper.step(k, DT, RUN, players, false)
			-- the truth, finely: the least angle off the beam of any point up its middle in reach,
			-- and how far a point of it is from being caught (degrees, given the points' spacing)
			local best = math.huge
			for j = 0, 280 do
				local p = a + vector.create(0, h * j / 280, 0)
				local d = vector.magnitude(p - eye)
				if d <= REACH then
					local cos = math.clamp(vector.dot(p - eye, aim) / d, -1, 1)
					best = math.min(best, math.deg(math.acos(cos)))
				end
			end
			local margin = math.deg(math.atan2(h / 14 + 0.05, vector.magnitude(a - feet)))
			local reachOk = vector.magnitude(a + vector.create(0, EYE, 0) - eye) < REACH - 1
			if not KeeperMap.clear(map, feet, a) then
				torchWalled += 1
				ok(
					k.lit == 0,
					`{where}: no torch lights it through a wall, a shut door or a corner`
				)
			elseif best <= HALF - margin and reachOk then
				torchHits += 1
				ok(k.lit == 5, `{where}: a torch on it, {best} degrees off, lights it`)
				ok(k.at == a and k.facing == facing, `{where}: held as it was`)
			elseif best > HALF + 0.5 then
				torchMisses += 1
				ok(k.lit == 0, `{where}: a torch {best} degrees off misses it`)
			end
			Keeper.release(k)
		end

		-- a shut door: a player in a unit's doorway shines out at it standing in the hall in front
		do
			local slot = units[lrng:nextInteger(1, #units)]
			local spot, door = Keeper.front(f.slots[slot])
			local fx, fz = Floor.dir(f.slots[slot].facing)
			local inside = door - vector.create(fx, 0, fz) * 3
			local _, unit = KeeperMap.placeAt(map, inside)
			ok(unit == slot, `{where}: the spot inside is in unit {slot}`)
			local k = Keeper.new(MANNEQUIN, map, RANDOM, spot, vector.create(fx, 0, fz), true)
			local eye = inside + vector.create(0, EYE, 0)
			holding(6, inside, toward(eye, spot + vector.create(0, 3, 0)))
			KeeperMap.setDoor(map, slot, true)
			Keeper.step(k, DT, RUN, players, false)
			ok(k.lit == 6, `{where}: its door up, a torch from inside lights it`)
			KeeperMap.setDoor(map, slot, false)
			Keeper.step(k, DT, RUN, players, false)
			ok(k.lit == 0, `{where}: its door down, the same torch doesn't`)
			-- a hall light: in the hall it's lit, inside the unit it isn't
			players.count = 0
			Keeper.step(k, DT, RUN, players, true)
			ok(k.lit == Keeper.HallLight, `{where}: in the hall under a lit hall light, it's lit`)
			local shut =
				Keeper.new(MANNEQUIN, map, RANDOM, inside, vector.create(-fx, 0, -fz), true)
			Keeper.step(shut, DT, RUN, players, true)
			ok(shut.lit == 0, `{where}: inside a unit, a hall light doesn't reach it`)
			-- asleep, nothing lights it; a row that doesn't freeze in light never is
			local sleeper = Keeper.new(MANNEQUIN, map, RANDOM, spot, vector.create(fx, 0, fz))
			holding(6, inside, toward(eye, spot + vector.create(0, 3, 0)))
			KeeperMap.setDoor(map, slot, true)
			Keeper.step(sleeper, DT, RUN, players, true)
			ok(sleeper.lit == 0 and sleeper.state == "Asleep", `{where}: asleep, it's never lit`)
			local row = table.clone(MANNEQUIN)
			row.freezesInLight = false
			local other = Keeper.new(row, map, RANDOM, spot, vector.create(fx, 0, fz), true)
			Keeper.step(other, DT, RUN, players, true)
			ok(other.lit == 0, `{where}: a keeper that doesn't freeze in light never is`)
			KeeperMap.setDoor(map, slot, false)
			for _, x in { k, shut, sleeper, other } do
				Keeper.release(x)
			end
		end
	end
	ok(frozenRuns > 60, `enough freezes to check ({frozenRuns})`)
	ok(
		torchHits > 200 and torchMisses > 200 and torchWalled > 200,
		`enough beams to check ({torchHits} on it, {torchMisses} off it, {torchWalled} walled)`
	)

	-- frozen, it still sees but never turns: a roamer held in the light notices a player off to
	-- one side and hunts them where it stands; their torch on it holds it; off, it comes at them
	do
		local f = Floor.generate(2, Brix.Random.new({ seed = 8 }))
		local map = KeeperMap.build(f)
		local found = false
		for _ = 1, 2000 do
			local i = lrng:nextInteger(1, #map.minX)
			if map.unit[i] == 0 and map.y[i] == 0 then
				local a = middleOf(map, i)
				local r = math.rad(lrng:nextNumber() * 360)
				local ahead = vector.create(math.cos(r), 0, math.sin(r))
				local b = a
					+ vector.create(
							ahead.x * 0.9 - ahead.z * 0.45,
							0,
							ahead.z * 0.9 + ahead.x * 0.45
						)
						* 20
				if KeeperMap.clear(map, a, b) and inHall(map, b) then
					found = true
					local k = Keeper.new(MANNEQUIN, map, RANDOM, a, ahead, true)
					k.state = "Roaming"
					holding(4, b, vector.zero)
					Keeper.step(k, DT, RUN, players, true)
					ok(
						k.state == "Hunting" and k.target == 4,
						`held, it still sees them ({k.state})`
					)
					ok(k.facing == ahead and k.at == a, "but it doesn't turn or move")
					for _ = 1, 600 do
						Keeper.step(k, DT, RUN, players, true)
					end
					ok(k.at == a and k.facing == ahead, "however long the light holds it")
					local eye = b + vector.create(0, EYE, 0)
					holding(4, b, toward(eye, a + vector.create(0, 3, 0)))
					for _ = 1, 600 do
						Keeper.step(k, DT, RUN, players, false)
					end
					ok(
						k.lit == 4 and k.at == a,
						`the hall light gone, their torch holds it ({k.lit})`
					)
					holding(4, b, vector.zero)
					Keeper.step(k, DT, RUN, players, false)
					ok(
						k.lit == 0 and flat(k.at, b) < flat(a, b),
						"their torch off, it comes at them"
					)
					for _ = 1, 300 do
						Keeper.step(k, DT, RUN, players, false)
					end
					ok(
						math.abs(flat(k.at, b) - Keeper.Close) < 0.01,
						`and reaches arm's length ({flat(k.at, b)})`
					)
					Keeper.release(k)
					break
				end
			end
		end
		ok(found, "found a hall to hold a hunter in")
	end

	-- a warm keeper held and let go by lights and torches allocates nothing
	do
		local f = Floor.generate(5, Brix.Random.new({ seed = 4 }))
		local map = KeeperMap.build(f)
		local k = Keeper.new(
			MANNEQUIN,
			map,
			Brix.Random.new({ seed = 2 }),
			middleOf(map, KeeperMap.placeAt(map, vector.zero)),
			vector.one,
			true
		)
		k.state = "Roaming"
		local function run(steps: number)
			for i = 1, steps do
				local feet = k.at + k.facing * 10
				if i % 60 < 20 then
					holding(3, feet, toward(feet + vector.create(0, EYE, 0), k.at))
				else
					holding(3, feet, vector.zero)
				end
				Keeper.step(k, 0.1, RUN, players, i % 50 < 10)
			end
		end
		run(3000)
		local before = collectgarbage("count")
		run(3000)
		local grew = collectgarbage("count") - before
		ok(grew < 1, `a keeper in and out of the light allocates nothing ({grew} KB)`)
		Keeper.release(k)
	end
end

-- The catch (L-06b3c): hunting, its hand closes on the one it hunts exactly when Brix's cone reach
-- along its map has them (its row's reach and angle), the map clears the line between them (never
-- through a wall or a shut door, never up on the tops) and they're no higher or lower than its
-- height; never anyone else, never while a light holds it, never asleep. Caught, it stands over
-- the spot its linger, the one it hunted let go, then roams. A warm catch check allocates nothing.
local caughtCount, missedCount, walledCount = 0, 0, 0
do
	local CONE = Brix.Reach.cone
	local REACH = MANNEQUIN.reach
	local EYE = 4.5 -- a player's eyes over their feet
	for name, row in KeeperRows do
		ok(
			row.reach > Keeper.Close and row.reach <= Keeper.Close + 2,
			`{name}: it grasps a little past arm's length ({row.reach})`
		)
		ok(
			row.reachAngle > 0 and row.reachAngle <= 90,
			`{name}: it grasps ahead of it, not behind ({row.reachAngle})`
		)
	end
	local players = Keeper.players()
	local function only(id: number, p: vector)
		players.ids[1], players.at[1], players.eye[1], players.aim[1] = id, p, p, vector.zero
		players.count = 1
	end
	local function hunter(map: KeeperMap.Map, at: vector, facing: vector, id: number, p: vector)
		local k = Keeper.new(MANNEQUIN, map, RANDOM, at, facing, true, CONE)
		k.state, k.target, k.seen, k.goal = "Hunting", id, p, p
		return k
	end
	local function way(degrees: number): vector
		local r = math.rad(degrees)
		return vector.create(math.cos(r), 0, math.sin(r))
	end

	-- exactly Brix's cone along its map, a clear line and its height, on seeded floors
	local crng = Brix.Random.new({ seed = 31 })
	for seed = 1, 8 do
		local number = (seed + 2) % 10 + 1
		local f = Floor.generate(number, Brix.Random.new({ seed = seed + 40 }))
		local map = KeeperMap.build(f)
		local where = `floor {number} seed {seed + 40}`
		local cone = CONE({
			pathing = KeeperMap.pathing(map, MANNEQUIN.abilities),
			radius = REACH,
			halfAngle = math.rad(MANNEQUIN.reachAngle),
		})
		local halls: { number } = {}
		for i = 1, #map.minX do
			if map.unit[i] == 0 and map.y[i] == 0 then
				table.insert(halls, i)
			end
		end
		for _ = 1, 500 do
			local i = halls[crng:nextInteger(1, #halls)]
			local a = vector.create(
				map.minX[i] + crng:nextNumber() * (map.maxX[i] - map.minX[i]),
				0,
				map.minZ[i] + crng:nextNumber() * (map.maxZ[i] - map.minZ[i])
			)
			local ups = { 0, 0, 0, 0, 3, 6, 6.5, 10 }
			local b = a
				+ way(crng:nextNumber() * 360) * (crng:nextNumber() * REACH * 1.5)
				+ vector.create(0, ups[crng:nextInteger(1, #ups)], 0)
			local k = hunter(map, a, way(crng:nextNumber() * 360), 7, b)
			only(7, b)
			local clear = KeeperMap.clear(map, a, b)
			local expect = math.abs(b.y - a.y) <= MANNEQUIN.height
				and cone:distance(a, k.facing, b) == 0
				and clear
			ok(
				(Keeper.catches(k, players) == 7) == expect,
				`{where}: a hunter at {a} facing {k.facing} {if expect
					then "catches"
					else "doesn't catch"} its quarry at {b}`
			)
			if expect then
				caughtCount += 1
			else
				missedCount += 1
			end
			if not clear and flat(a, b) <= REACH and b.y == 0 then
				walledCount += 1
			end
			only(8, b)
			ok(Keeper.catches(k, players) == 0, `{where}: never someone it doesn't hunt`)
			k.state = "Searching"
			only(7, b)
			ok(Keeper.catches(k, players) == 0, `{where}: never unless it hunts`)
			Keeper.release(k)
		end
	end
	ok(
		caughtCount > 300 and missedCount > 300 and walledCount > 20,
		`enough grasps, misses and walls between to check ({caughtCount}, {missedCount}, {walledCount})`
	)

	-- along one straight hall: its reach and its angle, to the hundredth
	local f = Floor.generate(2, Brix.Random.new({ seed = 8 }))
	local map = KeeperMap.build(f)
	local pathing = KeeperMap.pathing(map)
	local hall, along = 0, vector.zero
	for i = 1, #map.minX do
		local w, d = map.maxX[i] - map.minX[i], map.maxZ[i] - map.minZ[i]
		if map.unit[i] == 0 and map.y[i] == 0 and math.min(w, d) >= 7 and math.max(w, d) >= 14 then
			hall = i
			along = if w >= d then vector.create(1, 0, 0) else vector.create(0, 0, 1)
			break
		end
	end
	ok(hall > 0, "found a straight hall to grasp in")
	if hall > 0 then
		local a = middleOf(map, hall) - along * 4
		local side = vector.create(-along.z, 0, along.x)
		local function grasps(p: vector): boolean
			local k = hunter(map, a, along, 7, p)
			only(7, p)
			local got = Keeper.catches(k, players) == 7
			Keeper.release(k)
			return got
		end
		local ahead = a + along * REACH
		ok(math.abs(pathing:length(a, ahead) - REACH) < 1e-6, "in one hall the walk is straight")
		ok(grasps(a + along * (REACH - 0.01)), "it catches just inside its reach")
		ok(not grasps(a + along * (REACH + 0.01)), "but not just past it")
		local edge = MANNEQUIN.reachAngle
		local function at(degrees: number): vector
			local r = math.rad(degrees)
			return a + (along * math.cos(r) + side * math.sin(r)) * 3
		end
		ok(grasps(at(edge - 1)) and grasps(at(1 - edge)), "it catches just inside its angle")
		ok(not grasps(at(edge + 1)) and not grasps(at(-1 - edge)), "but not just outside it")
		ok(not grasps(a - along * 1), "nor behind it, however near")
		ok(not grasps(a + along * 2 + vector.create(0, 10, 0)), "nor up on the tops")
		ok(grasps(a + along * 2 + vector.create(0, 6, 0)), "a jump at its face is caught")

		-- a light holds it: no catch while it's lit, the moment it isn't
		local b = a + along * 3
		local k = hunter(map, a, along, 7, b)
		only(7, b)
		local eye = b + vector.create(0, EYE, 0)
		players.eye[1] = eye
		players.aim[1] = vector.normalize(a + vector.create(0, 3, 0) - eye)
		for _ = 1, 120 do
			Keeper.step(k, DT, RUN, players)
		end
		ok(
			k.lit == 7 and k.caught == 0 and k.state == "Hunting",
			`a torch on it, it never catches ({k.lit}, {k.caught}, {k.state})`
		)
		players.aim[1] = vector.zero
		for _ = 1, 120 do
			Keeper.step(k, DT, RUN, players, true)
		end
		ok(
			k.lit == Keeper.HallLight and k.caught == 0 and k.state == "Hunting",
			"under a lit hall light, it never catches"
		)
		Keeper.step(k, DT, RUN, players, false)
		ok(
			k.caught == 7 and k.state == "Waiting" and k.target == 0,
			`no light on it, its hand closes at once ({k.caught}, {k.state})`
		)
		ok(
			flat(k.at, b) <= REACH and facingToward(k, b),
			"a stride on, its hand closes, facing the one it caught"
		)
		-- caught, the server takes them out of its sight; it stands its linger, then roams
		players.count = 0
		Keeper.step(k, DT, RUN, players)
		ok(k.caught == 0, "a catch is said once")
		local stood = 0
		while k.state == "Waiting" and stood < 100 do
			Keeper.step(k, 0.1, RUN, players)
			stood += 1
		end
		ok(
			k.state == "Roaming" and math.abs(stood * 0.1 - MANNEQUIN.linger) < 0.15,
			`it stands over the spot its linger, then roams ({k.state} after {stood * 0.1} s)`
		)
		Keeper.release(k)

		-- asleep, a player in its face is never caught; awake, one stepping in front is at once,
		-- one behind it never
		local sleeper = Keeper.new(MANNEQUIN, map, RANDOM, a, along, false, CONE)
		only(7, a + along * 2)
		for _ = 1, 120 do
			Keeper.step(sleeper, DT, RUN, players)
		end
		ok(sleeper.state == "Asleep" and sleeper.caught == 0, "asleep, it never catches")
		Keeper.release(sleeper)
		local watcher = Keeper.new(MANNEQUIN, map, RANDOM, a, along, true, CONE)
		only(7, a - along * 2)
		for _ = 1, 120 do
			Keeper.step(watcher, DT, RUN, players)
		end
		ok(watcher.state == "Watching" and watcher.caught == 0, "behind it, unseen, you're safe")
		only(7, a + along * 3)
		Keeper.step(watcher, DT, RUN, players)
		ok(watcher.caught == 7, "step in front of it and it has you")
		Keeper.release(watcher)

		-- only the one it hunts: a friend in its face is let be while it hunts another
		local chaser = hunter(map, a, along, 7, a + along * 9)
		players.ids[1], players.at[1], players.aim[1] = 7, a + along * 9, vector.zero
		players.ids[2], players.at[2], players.aim[2] = 8, a + along * 2 + side * 0.5, vector.zero
		players.count = 2
		Keeper.step(chaser, DT, RUN, players)
		ok(chaser.caught == 0 and chaser.target == 7, "a friend in its face isn't the one it hunts")
		Keeper.release(chaser)

		-- standing still in its sight: it comes, and its hand closes at arm's length
		local runner = Keeper.new(MANNEQUIN, map, RANDOM, a - along * 2, along, true, CONE)
		local stand = a + along * 8
		only(7, stand)
		local steps = 0
		while runner.caught == 0 and steps < 600 do
			Keeper.step(runner, DT, RUN, players)
			steps += 1
		end
		local off = flat(runner.at, stand)
		ok(
			runner.caught == 7 and off <= REACH + 1e-6 and off >= Keeper.Close - TOL,
			`stand still and it comes and catches you ({runner.caught}, {off} studs off)`
		)
		Keeper.release(runner)

		-- a warm catch check allocates nothing, catching or not
		local warm = hunter(map, a, along, 7, a)
		local spots = { 1, 2, 3, 3.4, 3.6, 5 }
		local function run(times: number)
			for i = 1, times do
				only(7, a + along * spots[i % #spots + 1] + side * ((i % 5) - 2) * 0.5)
				Keeper.catches(warm, players)
			end
		end
		run(2000)
		local before = collectgarbage("count")
		run(4000)
		local grew = collectgarbage("count") - before
		ok(grew < 1, `a warm catch check allocates nothing ({grew} KB)`)
		Keeper.release(warm)
	end

	-- never through a shut door: at a unit's doorway, the door up, it catches you just inside;
	-- the door down, never
	local unit = 0
	for i, s in f.slots do
		if s.kind == "Unit" then
			unit = i
			break
		end
	end
	if unit > 0 then
		local slot = f.slots[unit]
		local fx, fz = Floor.dir(slot.facing)
		local out = vector.create(fx, 0, fz)
		local door = vector.create(slot.x, 0, slot.z)
		local a, b = door + out * 1.5, door - out * 1.5
		local function grasps(): boolean
			local k = hunter(map, a, -out, 7, b)
			only(7, b)
			local got = Keeper.catches(k, players) == 7
			Keeper.release(k)
			return got
		end
		KeeperMap.setDoor(map, unit, true)
		ok(grasps(), "its door up, it catches you just inside a unit")
		KeeperMap.setDoor(map, unit, false)
		ok(not grasps(), "its door down between you, never")
	end
end

-- A warm keeper's steps allocate nothing: walking, waiting, roaming (its picks included),
-- looking for players, hunting, searching and planning again.
do
	local f = Floor.generate(9, Brix.Random.new({ seed = 3 }))
	local map = KeeperMap.build(f)
	local doors: { number } = {}
	for i, s in f.slots do
		if s.kind == "Unit" then
			table.insert(doors, i)
		end
	end
	local k = Keeper.new(
		MANNEQUIN,
		map,
		Brix.Random.new({ seed = 5 }),
		middleOf(map, KeeperMap.placeAt(map, vector.zero)),
		vector.one
	)
	local players = Keeper.players()
	local n, roams, hunted = 0, 0, 0
	local function run(steps: number)
		n = 0 -- the same trips each run, so the measured run's buffers are already grown
		for i = 1, steps do
			if i % 120 == 1 then -- a sound every 30 s; it roams between
				n += 1
				local spot, door = Keeper.front(f.slots[doors[n % #doors + 1]])
				Keeper.hear(k, door, 1e6, spot)
			end
			-- a player stands a few studs ahead of it now and then, and goes up on the tops
			if i % 90 == 1 then
				players.ids[1], players.at[1], players.count = 9, k.at + k.facing * 6, 1
			elseif i % 90 == 20 then
				players.at[1] += vector.create(0, 10, 0)
			end
			local was = k.state
			Keeper.step(k, 0.25, RUN, players) -- long steps: many trips in few steps
			if k.state == "Roaming" and was ~= "Roaming" then
				roams += 1
			elseif k.state == "Hunting" and was ~= "Hunting" then
				hunted += 1
			end
		end
	end
	run(4000) -- warm: every buffer grown
	local before = collectgarbage("count")
	run(4000)
	local grew = collectgarbage("count") - before
	ok(grew < 1, `a warm keeper allocates nothing ({grew} KB over 4000 steps)`)
	ok(
		n > 10 and roams > 40 and hunted > 40,
		`it made enough trips, roams and hunts to check ({n}, {roams}, {hunted})`
	)
end

if failures > 0 then
	error(`keeper: {failures} of {checks} checks failed`)
end
print(
	`keeper: all {checks} checks passed ({floors} floors, {heardCount} heard, {wallCount} kept out by walls, {walks} walks to look, {noticed} sightings, {hunts} hunts, {searches} searches, {frozenRuns} freezes, {torchHits} beams on it, {caughtCount} grasps, {missedCount} misses)`
)
