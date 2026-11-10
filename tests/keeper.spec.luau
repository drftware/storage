--!strict
-- lune run tests/keeper.spec
-- The keepers' brain (L-06b2a): every row keeps the GDD's speed rule; a keeper hears a door
-- exactly when its trip to the door along the map is within the sound's reach (DoorSound's, as a
-- player hears it), so never through a wall or a shut door; heard, it walks the halls to the
-- door's front, never faster than its walking pace and never into a unit whose door is down,
-- arriving when the trip's length says; stands there facing the door for its linger; walks back
-- and sleeps facing as it was. A newer sound takes it there, its home kept; a door coming down
-- across its way stops it where it is. And a warm keeper's steps allocate nothing.
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
			local k = Keeper.new(MANNEQUIN, map, at, vector.create(0, 0, -1))
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
			local deaf = Keeper.new(deafRow, map, at, vector.create(0, 0, -1))
			ok(Keeper.hear(deaf, door, SLAM, spot) == nil, `{where}: a deaf keeper hears nothing`)
		end
	end

	-- the walk there and back, from a few halls to a few doors
	for h = 1, #halls, math.max(1, #halls // 3) do
		local home = middleOf(map, halls[h])
		for d = 1, #doors, math.max(1, #doors // 3) do
			local slot = doors[d]
			local spot, door = Keeper.front(f.slots[slot])
			local homeFacing = vector.create(1, 0, 0)
			local k = Keeper.new(MANNEQUIN, map, home, homeFacing)
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
				-- it lingers, then goes back
				local waited = walkOut(k, map, "Waiting", 100000)
				local linger = math.ceil(MANNEQUIN.linger / DT - 1e-6)
				ok(math.abs(waited - linger) <= 1, `{where}: lingered {waited} steps, not {linger}`)
				ok(k.state == "Returning", `{where}: then it goes back`)
				local _, backLongest, backStrayed = walkOut(k, map, "Returning", 100000)
				ok(k.state == "Asleep", `{where}: and sleeps once home ({k.state})`)
				ok(flat(k.at, home) < TOL, `{where}: right where it woke`)
				ok(vector.dot(k.facing, homeFacing) > 0.9999, `{where}: facing as it was`)
				ok(
					backLongest <= STEP + TOL and not backStrayed,
					`{where}: the way back is a walk too`
				)
			end
		end
	end

	-- a newer sound takes it there, and home stays where it woke
	if #doors >= 2 then
		local home = middleOf(map, KeeperMap.placeAt(map, vector.zero))
		local a, b = doors[1], doors[#doors]
		local spotA, doorA = Keeper.front(f.slots[a])
		local spotB, doorB = Keeper.front(f.slots[b])
		local k = Keeper.new(MANNEQUIN, map, home, vector.create(0, 0, -1))
		local huge = 1e6 -- a sound heard anywhere: this checks the turn, not the reach
		Keeper.hear(k, doorA, huge, spotA)
		for _ = 1, 30 do
			Keeper.step(k, DT, RUN)
		end
		Keeper.hear(k, doorB, huge, spotB)
		ok(k.state == "Going" and k.goal == spotB, `{where}: a newer sound takes it there`)
		ok(k.home == home, `{where}: home stays where it woke`)
		walkOut(k, map, "Going", 100000)
		ok(flat(k.at, spotB) < TOL, `{where}: it looks at the newer sound`)
		walkOut(k, map, "Waiting", 100000)
		for _ = 1, 30 do
			Keeper.step(k, DT, RUN)
		end
		ok(k.state == "Returning", `{where}: going back`)
		Keeper.hear(k, doorA, huge, spotA)
		ok(k.state == "Going" and k.home == home, `{where}: going back, a sound turns it round`)
	end
end

for seed = 1, 30 do
	checkFloor(seed, 1 + seed % 10) -- every floor's plan
end
ok(heardCount > 100, `enough keepers heard to check ({heardCount})`)
ok(wallCount > 20, `enough sounds were kept out by walls to check ({wallCount})`)
ok(walks > 30, `enough walks to check ({walks})`)

-- Shut doors: a keeper in a unit hears nothing through its door; with it up, it hears and walks
-- out; a door coming down across its way stops it where it is, and with no way home it sleeps
-- where it stands.
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
	local home = middleOf(map, unitPlace)
	local spot, door = Keeper.front(f.slots[near])
	local k = Keeper.new(MANNEQUIN, map, home, vector.create(0, 0, 1))
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
	local stopped = k.at
	Keeper.step(k, DT, RUN)
	ok(k.state == "Asleep", `its home behind a shut door, it sleeps where it stands ({k.state})`)
	ok(flat(k.at, stopped) < TOL and k.home == k.at, "right where it stood")

	-- a door coming down across its way stops it where it is, facing the sound
	local k2 = Keeper.new(MANNEQUIN, map, home, vector.create(0, 0, 1))
	KeeperMap.setDoor(map, inside, true)
	Keeper.hear(k2, door, SLAM, spot)
	Keeper.step(k2, DT, RUN)
	KeeperMap.setDoor(map, inside, false)
	local at = k2.at
	Keeper.step(k2, DT, RUN)
	ok(k2.state == "Waiting", `a door down across its way stops it ({k2.state})`)
	ok(flat(k2.at, at) < TOL, "where it was")
	ok(facingToward(k2, door), "facing the sound")
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

-- A warm keeper's steps allocate nothing: walking, waiting, going back and planning again.
do
	local f = Floor.generate(9, Brix.Random.new({ seed = 3 }))
	local map = KeeperMap.build(f)
	local doors: { number } = {}
	for i, s in f.slots do
		if s.kind == "Unit" then
			table.insert(doors, i)
		end
	end
	local k =
		Keeper.new(MANNEQUIN, map, middleOf(map, KeeperMap.placeAt(map, vector.zero)), vector.one)
	local n = 0
	local function run(steps: number)
		n = 0 -- the same trips each run, so the measured run's buffers are already grown
		for _ = 1, steps do
			if k.state == "Asleep" then
				n += 1
				local spot, door = Keeper.front(f.slots[doors[n % #doors + 1]])
				Keeper.hear(k, door, 1e6, spot)
			end
			Keeper.step(k, 0.25, RUN) -- long steps: many trips in few steps
		end
	end
	run(4000) -- warm: every buffer grown
	local before = collectgarbage("count")
	run(4000)
	local grew = collectgarbage("count") - before
	ok(grew < 1, `a warm keeper allocates nothing ({grew} KB over 4000 steps)`)
	ok(n > 10, `it made enough trips to check ({n})`)
end

if failures > 0 then
	error(`keeper: {failures} of {checks} checks failed`)
end
print(
	`keeper: all {checks} checks passed ({floors} floors, {heardCount} heard, {wallCount} kept out by walls, {walks} walks there and back)`
)
