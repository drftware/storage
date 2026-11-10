--!strict
-- lune run tests/trapped.spec
-- Trapped (L-06b3d1): a door that came down from all the way up, by a slam or a close (the only
-- ways down from Open), traps an awake keeper standing in its unit, never a sleeping one, one
-- elsewhere or one already trapped. It walks to stand against the door, facing it, at no more
-- than its walk, and bangs on it from inside: the first blow at its row's `bangFirst`, then
-- gaps within its row's band that close in as its time runs out. At `breakOut` it bursts the door
-- up, once, and waits for it to be all the way up; out, it goes after the last thing it heard
-- through its door, or steps out to look. Its own door's sounds it doesn't count. A padlock holds
-- it: it gives one last blow at its break-out time and goes quiet, and bursts out at once when
-- the padlock is cut. Lift it yourself and it's just out, never bursting after. While trapped it
-- takes no place in the floor's cap (`loose`). The door's bang leaves it where it was, jolting it
-- a little, quieter than a slam; the burst is a fast, loud lift nobody outside can pull down.
-- And a warm trapped keeper's steps allocate nothing, its blows included.
local Brix = require("../vendor/brix/src")
local Door = require("../src/shared/StorageUnit/Door")
local DoorSound = require("../src/shared/StorageUnit/DoorSound")
local Floor = require("../src/shared/Floor")
local Keeper = require("../src/shared/Keeper")
local KeeperMap = require("../src/shared/KeeperMap")
local KeeperRows = require("../src/shared/KeeperRows")
local Motion = require("../src/shared/StorageUnit/Motion")

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

local RUN = 16
local DT = 1 / 60
local SLAM = DoorSound.Actions.Slam.Reach
local ROW = KeeperRows.Mannequin
local PACE = ROW.speed * ROW.looking * RUN
local TOL = 2e-3
local FULL = 9 -- a door's full stroke for the motion checks (studs)

local function flat(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

-- The door's side: a bang jolts it where it is and drops it back; a burst flings it to the top.
do
	local peak = 0
	for i = 0, 50 do
		local y = Motion.sample("Bang", 0, 0, i / 100, FULL)
		peak = math.max(peak, y)
		ok(y >= 0, "a bang never pushes the door below where it was")
	end
	ok(peak > 0.1 and peak < 0.4, `a bang jolts the door a little ({peak} studs)`)
	ok(Motion.sample("Bang", 1, 1, 1, FULL) == 1, "a bang on a peeked door leaves it peeked")
	ok(Motion.duration("Bang", 0, 0, FULL) == 0.5, "a bang lasts its boom")
	ok(#Motion.strikes("Bang", 0, 0, FULL) == 0, "a bang strikes nothing a slam does")
	for _, locked in { false, true } do
		local st = Door.stateOf("Bang", 0, 0, 0.1, FULL, locked)
		ok(st == (if locked then "Locked" else "Closed"), `mid-bang a shut door stays shut ({st})`)
	end
	ok(Door.stateOf("Bang", 1, 1, 0.1, FULL, false) == "Peeking", "mid-bang a peek stays a peek")
	ok(Motion.target("Burst", { Peek = 1, Open = FULL }) == FULL, "a burst goes all the way up")
	local burst = Motion.duration("Burst", 0, FULL, FULL)
	ok(burst < Motion.duration("Open", 0, FULL, FULL) / 2, `a burst is fast ({burst} s)`)
	ok(Door.stateOf("Burst", 0, FULL, 0.2, FULL, false) == "Lifting", "nobody outside can stop it")
	ok(Door.stateOf("Burst", 0, FULL, burst, FULL, false) == "Open", "then it's open")
	ok(Motion.sample("Burst", 0, FULL, burst / 4, FULL) > FULL / 2, "half way up in a quarter")
	ok(Motion.isKind("Bang") and Motion.isKind("Burst"), "both are door motions")
	ok(Keeper.Hears.Bang and Keeper.Hears.Burst, "keepers hear a bang and a burst")
	local bang, slam =
		DoorSound.cues("Bang", 0, 0, FULL)[1], DoorSound.cues("Slam", FULL, 0, FULL)[1]
	ok(bang.sound == "Bang" and bang.gain < slam.gain, "a bang booms, quieter than a slam")
	ok(bang.shake > 0 and bang.shake < slam.shake, "and shakes whoever is near, less than a slam")
	ok(DoorSound.Actions.Bang.Reach > 0, "a bang carries")
	ok(
		DoorSound.Actions.Burst.Reach > DoorSound.Actions.Open.Reach,
		"a burst carries further than an open"
	)
	-- the only ways down from all the way up are a close and a slam, and only Open lets through
	for _, state in Door.States do
		ok(KeeperMap.letsThrough(state) == (state == "Open"), `only an open door lets through`)
	end
	local down = Door.offers("Open", "Hall")
	ok(
		#down == 2 and table.find(down, "Close") and table.find(down, "Slam") ~= nil,
		"close or slam"
	)
end

-- A floor with a unit and a neighbour along its hall.
local f = Floor.generate(4, Brix.Random.new({ seed = 11 }))
local map = KeeperMap.build(f)
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
local slot, nearSlot = f.slots[inside], f.slots[near]
local unitPlace = 0
for i = 1, #map.minX do
	if map.unit[i] == inside then
		unitPlace = i
	end
end
local middle = vector.create(
	(map.minX[unitPlace] + map.maxX[unitPlace]) / 2,
	0,
	(map.minZ[unitPlace] + map.maxZ[unitPlace]) / 2
)
local front, doorway = Keeper.front(slot)
local nearSpot, nearDoor = Keeper.front(nearSlot)

-- An awake keeper in the unit, its door just come down from all the way up.
local function trapped(seed: number): Keeper.Keeper
	KeeperMap.setDoor(map, inside, false)
	local k =
		Keeper.new(ROW, map, Brix.Random.new({ seed = seed }), middle, vector.create(0, 0, 1), true)
	assert(Keeper.trap(k, slot, inside), "trapped")
	return k
end

-- Steps it `seconds`; returns the times of each blow of `kind`.
local function blows(k: Keeper.Keeper, seconds: number, kind: Keeper.Blow): { number }
	local times = {}
	local t = 0
	for _ = 1, math.round(seconds / DT) do
		Keeper.step(k, DT, RUN)
		t += DT
		if k.blow == kind then
			table.insert(times, t)
		end
	end
	return times
end

-- Who it traps.
do
	KeeperMap.setDoor(map, inside, false)
	local sleeper =
		Keeper.new(ROW, map, Brix.Random.new({ seed = 1 }), middle, vector.create(0, 0, 1))
	ok(not Keeper.trap(sleeper, slot, inside), "asleep, it isn't trapped")
	local k =
		Keeper.new(ROW, map, Brix.Random.new({ seed = 1 }), middle, vector.create(0, 0, 1), true)
	ok(not Keeper.trap(k, nearSlot, near), "another unit's door isn't its own")
	ok(Keeper.loose(k), "awake in its unit, never trapped, it counts toward the cap")
	ok(
		Keeper.trap(k, slot, inside),
		"awake in its unit, its door down from all the way up traps it"
	)
	ok(k.state == "Trapped" and k.trappedIn == inside, "trapped there")
	ok(not Keeper.trap(k, slot, inside), "already trapped, its clock doesn't start again")
	ok(Keeper.awake(k) and not Keeper.loose(k), "trapped, it's awake but takes no place in the cap")
	local outside =
		Keeper.new(ROW, map, Brix.Random.new({ seed = 1 }), front, vector.create(0, 0, 1), true)
	ok(not Keeper.trap(outside, slot, inside), "out in the hall, its door coming down leaves it")
end

-- It goes to its door and bangs on it, faster and faster, then bursts out at its time.
do
	local k = trapped(3)
	local fastest, strayed = 0, false
	local t = 0
	while flat(k.at, k.goal) > TOL and t < 10 do
		local before = k.at
		Keeper.step(k, DT, RUN)
		t += DT
		fastest = math.max(fastest, flat(before, k.at) / DT)
		local _, unit = KeeperMap.placeAt(map, k.at)
		strayed = strayed or unit ~= inside
	end
	ok(flat(k.at, k.against) < TOL, `it stands against its door ({flat(k.at, k.against)} off)`)
	ok(flat(k.at, doorway) <= Keeper.Against + TOL, "just inside it")
	ok(not strayed, "never leaving its unit")
	ok(fastest <= PACE + 1e-3, `at no more than its walk ({fastest} studs a second)`)
	local toDoor = vector.create(doorway.x - k.at.x, 0, doorway.z - k.at.z)
	ok(vector.dot(k.facing, toDoor / vector.magnitude(toDoor)) > 0.999, "facing the door")
	ok(Keeper.pace(k, RUN) == 0 and Keeper.left(k) == 0, "there, it stands")
	ok(t < ROW.bangFirst, `there before its first blow ({t} s)`)

	local k2 = trapped(3)
	local bangs = blows(k2, ROW.breakOut - DT / 2, "Bang")
	ok(
		math.abs(bangs[1] - ROW.bangFirst) <= DT + 1e-9,
		`its first blow at {ROW.bangFirst} s ({bangs[1]})`
	)
	local lo = math.min(ROW.bangEvery, ROW.bangEveryLast) * (1 - ROW.bangJitter) - DT
	local hi = math.max(ROW.bangEvery, ROW.bangEveryLast) * (1 + ROW.bangJitter) + DT
	local early, late = 0, 0
	for i = 2, #bangs do
		local gap = bangs[i] - bangs[i - 1]
		ok(gap >= lo and gap <= hi, `each gap in its band ({gap} s)`)
		if i <= 6 then
			early += gap / 5
		elseif i > #bangs - 5 then
			late += gap / 5
		end
	end
	ok(late < early * 0.75, `its blows come faster near the end ({early} s, then {late} s)`)
	ok(#bangs >= 20 and #bangs <= 35, `about a blow every few seconds ({#bangs} in 90 s)`)
	ok(
		ROW.breakOut - bangs[#bangs] >= ROW.bangEveryLast / 2 - DT,
		`its last blow comes a moment before its burst, never on top of it ({bangs[#bangs]} s)`
	)
	local bursts = blows(k2, 60, "Burst")
	ok(
		#bursts == 1 and bursts[1] <= DT + 1e-9,
		`it bursts out at {ROW.breakOut} s, once ({#bursts})`
	)
	ok(k2.state == "Trapped" and k2.burst, "and waits for its door to be up")

	-- its door up: having heard nothing, it steps out to look, and counts again
	ok(Keeper.lookOut(k2, slot, inside), "its door up, it's out")
	ok(k2.state == "Going" and k2.goal == front, "it steps out to look")
	ok(k2.trappedIn == 0 and Keeper.loose(k2), "out, it counts toward the cap again")
end

-- Trapped, it hears through its own door, never its own door, and goes after the last it heard.
do
	local k = trapped(5)
	ok(Keeper.hear(k, doorway, SLAM, front) == nil, "its own door's sounds it doesn't count")
	ok(Keeper.hear(k, nearDoor, 1, nearSpot) == nil, "a sound that doesn't carry to it, it misses")
	ok(not k.heardOut, "so it has nothing to go after")
	local d = Keeper.hear(k, nearDoor, SLAM, nearSpot)
	ok(d ~= nil and k.state == "Trapped", "it hears the slam next door through its own, and stays")
	ok(
		d ~= nil
			and math.abs(
					d - (flat(middle, doorway) + KeeperMap.pathing(map):length(front, nearDoor))
				)
				< TOL,
		`as far off as its way to its door and on from there ({d})`
	)
	blows(k, ROW.breakOut + 1, "Burst")
	ok(Keeper.lookOut(k, slot, inside), "burst up, it's out")
	ok(k.state == "Going" and k.goal == nearSpot, "going after the last thing it heard")
end

-- A padlock holds it: one last blow, then quiet; cut, it bursts out at once.
do
	local k = trapped(7)
	blows(k, 20, "Bang")
	Keeper.padlock(k, true)
	local bangs = blows(k, ROW.breakOut - 20 - DT / 2, "Bang")
	ok(#bangs > 5, "padlocked, it bangs on till its time")
	local held, bursts, more = 0, 0, 0
	for _ = 1, math.round(120 / DT) do
		Keeper.step(k, DT, RUN)
		if k.blow == "Held" then
			held += 1
		elseif k.blow == "Burst" then
			bursts += 1
		elseif k.blow == "Bang" then
			more += 1
		end
	end
	ok(
		held == 1 and bursts == 0 and more == 0,
		`padlocked, one last blow and quiet ({held}, {bursts}, {more})`
	)
	ok(
		k.state == "Trapped" and not Keeper.loose(k),
		"held for the floor, taking no place in the cap"
	)
	Keeper.padlock(k, false)
	Keeper.step(k, DT, RUN)
	ok(k.blow == "Burst", "the padlock cut, it bursts out at once")
end

-- Lift it yourself and it's just out: no burst after.
do
	local k = trapped(9)
	blows(k, 10, "Bang")
	ok(Keeper.lookOut(k, slot, inside), "you lift its door: it's out")
	ok(k.state == "Going" and k.trappedIn == 0, "stepping out to look")
	ok(not Keeper.lookOut(k, slot, inside), "and not sent twice")
	local any = 0
	for _ = 1, math.round(120 / DT) do
		Keeper.step(k, DT, RUN)
		if k.blow ~= "None" then
			any += 1
		end
	end
	ok(any == 0, "out, it never bangs or bursts")
end

-- Warm, a trapped keeper's steps allocate nothing, its blows and burst included.
do
	local k = trapped(11)
	blows(k, 5, "Bang")
	local before = collectgarbage("count")
	for _ = 1, math.round((ROW.breakOut + 5) / DT) do
		Keeper.step(k, DT, RUN)
	end
	local grew = collectgarbage("count") - before
	ok(grew < 1, `a trapped keeper's 90 s allocate nothing ({grew} KB)`)
end

if failures > 0 then
	error(`trapped: {failures} of {checks} checks failed`)
end
print(`trapped: all {checks} checks passed`)
