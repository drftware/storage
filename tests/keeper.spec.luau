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
-- the same seed roams the same way; shut in its unit, it watches until its door is up. And a warm
-- keeper's steps allocate nothing, a roam's picks included.
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
				local steps, longest, strayed = walkOut(k, map, "Going", 100000)
				ok(k.state == "Waiting", `{where}: it gets to the door ({k.state})`)
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

-- A warm keeper's steps allocate nothing: walking, waiting, roaming (its picks included) and
-- planning again.
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
	local n, roams = 0, 0
	local function run(steps: number)
		n = 0 -- the same trips each run, so the measured run's buffers are already grown
		for i = 1, steps do
			if i % 120 == 1 then -- a sound every 30 s; it roams between
				n += 1
				local spot, door = Keeper.front(f.slots[doors[n % #doors + 1]])
				Keeper.hear(k, door, 1e6, spot)
			end
			local was = k.state
			Keeper.step(k, 0.25, RUN) -- long steps: many trips in few steps
			if k.state == "Roaming" and was ~= "Roaming" then
				roams += 1
			end
		end
	end
	run(4000) -- warm: every buffer grown
	local before = collectgarbage("count")
	run(4000)
	local grew = collectgarbage("count") - before
	ok(grew < 1, `a warm keeper allocates nothing ({grew} KB over 4000 steps)`)
	ok(n > 10 and roams > 40, `it made enough trips and roams to check ({n}, {roams})`)
end

if failures > 0 then
	error(`keeper: {failures} of {checks} checks failed`)
end
print(
	`keeper: all {checks} checks passed ({floors} floors, {heardCount} heard, {wallCount} kept out by walls, {walks} walks to look)`
)
