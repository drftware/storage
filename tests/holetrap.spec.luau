--!strict
-- lune run tests/holetrap.spec
-- The hole trap, end to end (L-12c, GDD "The hole trap"): on seed 7's floor 1, as played in
-- Studio, the Mannequin hunts you up the hall into Unit 155; you crawl through the hole you sawed
-- into 153, run round and slam 155. It loses you through the wall, never gets into 153, rushes to
-- where it last saw you and stands there clear of the walls (its reaching arm never through the
-- wall or the hole), staring at the hole; it's still in 155 when your slam comes down, and the
-- slam traps it.
local Brix = require("../vendor/brix/src")
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

local RUN = 16
local DT = 1 / 60
local ROW = KeeperRows.Mannequin
local TOL = 1e-3

local f = Floor.generate(1, Brix.Random.new({ seed = 7 }))
local map = KeeperMap.build(f)
local function slotOf(number: string): number
	for i, s in f.slots do
		if s.number == number then
			return i
		end
	end
	error(`no unit {number}`)
end
local first, second = slotOf("155"), slotOf("153")
ok(f.slots[first].right == second, "155 and 153 stand side by side in a row")
local function placeOf(slot: number): number
	for i = 1, #map.minX do
		if map.unit[i] == slot then
			return i
		end
	end
	error(`no place for slot {slot}`)
end
local room = placeOf(first)
local minX, maxX, minZ, maxZ = map.minX[room], map.maxX[room], map.minZ[room], map.maxZ[room]
-- 155's door is on its -X side (it faces into the hall at x 52); the wall it shares with 153 is
-- its +Z side, and the hole is cut 3.75 to 6.75 in from the hall, its middle 5.25 in
local hole = vector.create(minX + 5.25, 0, maxZ)

-- Where the player's feet are at `t` seconds: seen at 155's front, they run into 155 to the hole,
-- press Crawl, drag themselves through the wall into 153, stand, run out of 153 and back down the
-- hall to 155's front. Mirrors the Studio run (L-12c): the press 0.07 s after reaching the hole,
-- the crawl 1.4 s, the slam 0.9 s after it.
local RUN_IN, PRESS, CRAWL, OUT, BACK = 0.45, 0.07, 1.4, 0.45, 0.4
local start = vector.create(49, 0, -24)
local mouth = vector.create(hole.x - 1.4, 0, hole.z - 1.8)
local through = vector.create(hole.x, 0, hole.z + 3.6)
local door153 = vector.create(49.5, 0, -16.5)
local slamAt = vector.create(49.5, 0, -22.5)
local function lerp(a: vector, b: vector, u: number): vector
	local c = math.clamp(u, 0, 1)
	return a + (b - a) * c
end
local function player(t: number): vector
	if t < RUN_IN then
		return lerp(start, mouth, t / RUN_IN)
	end
	t -= RUN_IN
	if t < PRESS then
		return mouth
	end
	t -= PRESS
	if t < CRAWL then
		-- down at the mouth, then two pulls through, then up in 153
		local entry = vector.create(hole.x, 0, hole.z - 2.6)
		if t < 0.3 then
			return lerp(mouth, entry, t / 0.3)
		end
		return lerp(entry, through, (t - 0.3) / (CRAWL - 0.3))
	end
	t -= CRAWL
	if t < OUT then
		return lerp(through, door153, t / OUT)
	end
	t -= OUT
	return lerp(door153, slamAt, t / BACK)
end
local SLAM = RUN_IN + PRESS + CRAWL + OUT + BACK

-- 155 and 153 open (the player opened both); the keeper comes up the hall from the junction
KeeperMap.setDoor(map, first, true)
KeeperMap.setDoor(map, second, true)
local k = Keeper.new(
	ROW,
	map,
	Brix.Random.new({ seed = 7 }),
	vector.create(48, 0, -46),
	vector.create(0, 0, 1),
	true
)
local players = Keeper.players()
players.count, players.ids[1], players.eye[1], players.aim[1] = 1, 7, vector.zero, vector.zero

local hunted, lost, inSecond, stood = false, false, false, false
local stoodAt, stoodFacing = vector.zero, vector.zero
local t = 0
while t < SLAM do
	players.at[1] = player(t)
	Keeper.step(k, DT, RUN, players)
	t += DT
	hunted = hunted or k.state == "Hunting"
	lost = lost or (hunted and k.state == "Searching")
	local _, unit = KeeperMap.placeAt(map, k.at)
	inSecond = inSecond or unit == second
	if not stood and k.state == "Waiting" then
		stood, stoodAt, stoodFacing = true, k.at, k.facing
	end
end
ok(hunted, "it sees you up the hall and hunts you")
ok(lost, "you crawl through the wall: it's lost you")
ok(not inSecond, "it never gets into 153: the hole is too small for it")
ok(stood, "it stands where it lost you before your slam")
local _, standsIn = KeeperMap.placeAt(map, stoodAt)
ok(standsIn == first, "where it lost you is in 155")
-- clear of the walls: its body and its reaching arm stay out of the wall and the hole
local clearOf = math.min(maxX - stoodAt.x, stoodAt.z - minZ, maxZ - stoodAt.z)
ok(
	clearOf >= Keeper.Against - TOL,
	`it stands clear of 155's walls ({clearOf} studs, its arm needs {Keeper.Against})`
)
local toHole = hole - stoodAt
local across = math.sqrt(toHole.x * toHole.x + toHole.z * toHole.z)
local facesHole = (stoodFacing.x * toHole.x + stoodFacing.z * toHole.z) / across
ok(facesHole > 0.9, `it stares at the hole you went through ({facesHole})`)

-- the run round: your slam comes down while it still stands in 155, and traps it
local _, at = KeeperMap.placeAt(map, k.at)
ok(at == first and k.state == "Waiting", `it's still in 155 as you slam ({k.state})`)
ok(k.wait - k.waited > 1, `with time to spare ({k.wait - k.waited} s of looking left)`)
KeeperMap.setDoor(map, first, false)
ok(Keeper.trap(k, f.slots[first], first), "your slam traps it")
ok(k.state == "Trapped" and k.trappedIn == first, "trapped in 155")

-- Clear of a unit's walls; a hall's spot comes back as it is.
do
	local mid = vector.create((minX + maxX) / 2, 0, (minZ + maxZ) / 2)
	local p = KeeperMap.offWalls(map, hole, Keeper.Against)
	ok(math.abs(p.z - (maxZ - Keeper.Against)) < TOL, "a spot on the shared wall is pulled in")
	ok(
		math.abs(p.x - math.min(hole.x, maxX - Keeper.Against)) < TOL,
		"along the wall it stays where it was, short of the back wall"
	)
	local wide = KeeperMap.offWalls(map, hole, 100)
	ok(
		math.abs(wide.x - mid.x) < TOL and math.abs(wide.z - mid.z) < TOL,
		"a unit too small for the margin: its middle"
	)
	ok(KeeperMap.offWalls(map, mid, Keeper.Against) == mid, "the middle stays the middle")
	local hallSpot = vector.create(44.5, 0, -30)
	local _, hallUnit = KeeperMap.placeAt(map, hallSpot)
	ok(hallUnit == 0, "a spot by the hall's wall is in the hall")
	ok(KeeperMap.offWalls(map, hallSpot, Keeper.Against) == hallSpot, "a hall's spot is kept")
end

if failures > 0 then
	error(`holetrap: {failures} of {checks} checks failed`)
end
print(`holetrap: all {checks} checks passed`)
