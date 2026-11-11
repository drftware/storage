--!strict
-- lune run tests/hearing.spec
-- Keepers hear the rest (L-15): every loud thing a player does reaches a keeper as far as players
-- hear it, along the halls. A sound up on a unit's top carries out over its front; one behind a
-- shut door gets out through it, muffled; a keeper in the same unit hears it where it is. A sound
-- new to a keeper stops it dead, turned to face it, before it goes; the same noise going on (a
-- code's presses, a crawl's pulls) doesn't stop it again. And the numbers that say how far each
-- noise carries keep their order.
local Brix = require("../vendor/brix/src")
local Carry = require("../src/shared/Tools/Carry")
local Crawling = require("../src/shared/StorageUnit/CrawlHole/Crawling")
local Floor = require("../src/shared/Floor")
local Horn = require("../src/shared/Tools/Horn")
local Keeper = require("../src/shared/Keeper")
local KeeperMap = require("../src/shared/KeeperMap")
local KeeperRows = require("../src/shared/KeeperRows")
local Keypad = require("../src/shared/Elevator/Keypad")
local Leaning = require("../src/shared/Tools/Leaning")
local Sawing = require("../src/shared/StorageUnit/CrawlHole/Sawing")
local Tops = require("../src/shared/Tops")
local Wrap = require("../src/shared/Tools/Wrap")

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
local MANNEQUIN = KeeperRows.Mannequin
local TOL = 2e-3

local function flat(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end
local function middleOf(map: KeeperMap.Map, i: number): vector
	return vector.create((map.minX[i] + map.maxX[i]) / 2, map.y[i], (map.minZ[i] + map.maxZ[i]) / 2)
end
local function facingToward(k: Keeper.Keeper, p: vector): boolean
	local d = vector.create(p.x - k.at.x, 0, p.z - k.at.z)
	local m = vector.magnitude(d)
	return m < 1e-6 or vector.dot(k.facing, d / m) > 0.999
end

-- The numbers: what each noise does to the player, in order.
ok(Keeper.Muffled > 0 and Keeper.Muffled < 1, "a shut door muffles a sound, never silences it")
ok(Keeper.OnTop > 7 and Keeper.OnTop < 10, "over a jump in a unit, under the steel of its top")
ok(Keeper.Same > 0 and Keeper.Same < Floor.Cell, "the same noise is nearer than a hall piece")
ok(MANNEQUIN.startle > 0 and MANNEQUIN.startle < 2, "its stop on a new sound is a beat, not a rest")
ok(
	Keypad.Heard.Press < Keypad.Heard.Right and Keypad.Heard.Right < Keypad.Heard.Wrong,
	"a beep is quieter than the chime, the chime quieter than the alarm"
)
ok(Sawing.Heard > Horn.Reach, "the saw is the loudest thing a player does")
ok(Sawing.DropHeard >= Sawing.ClangHeard, "a top's panel falling ten studs is louder than a wall's")
ok(Tops.Heard < Tops.DropHeard, "a crawl along the tops is quieter than a drop off them")
ok(Leaning.ClimbHeard < Leaning.RaiseHeard, "climbing a ladder is quieter than putting it up")
ok(Carry.DropHeard > 0 and Carry.DropHeard < Wrap.Reach, "a dropped tool is a clank, not an alarm")
ok(
	Crawling.Heard * Keeper.Muffled < Floor.Cell,
	"a crawl behind a shut door is heard only by a keeper near it"
)

-- A crawler's feet, as the pops read them: on what they lie on, whatever the avatar's size.
ok(
	Wrap.feetBelow(2, 1, false, Crawling.ProneUp) == 3,
	"standing, the feet are hips and half a root down"
)
for _, hip in { 1.35, 2, 2.4, 3.2, 4 } do
	local below = Wrap.feetBelow(hip, 1, true, Crawling.ProneUp)
	ok(below <= Wrap.Under, `lying (hips {hip}), the feet read within Under of the floor`)
	ok(below >= 0, `lying (hips {hip}), the feet are under the root`)
end

-- A unit by number on a floor, its slot and place.
local function unitNear(
	map: KeeperMap.Map,
	walker: KeeperMap.Pathing,
	from: vector,
	lo: number,
	hi: number
): (number, number)
	for i = 1, #map.minX do
		local s = map.unit[i]
		if s ~= 0 then
			local door = KeeperMap.doorFront(map, s, 0)
			local d = walker:length(from, door)
			if d >= lo and d <= hi then
				return s, i
			end
		end
	end
	return 0, 0
end

for _, case in { { 1, 7 }, { 2, 1 }, { 3, 2 } } do
	local where = `floor {case[1]} seed {case[2]}`
	local f = Floor.generate(case[1], Brix.Random.new({ seed = case[2] }))
	local map = KeeperMap.build(f)
	local walker = KeeperMap.pathing(map)
	local random = Brix.Random.new({ seed = case[2] })
	local lobby = vector.zero

	-- each door's front on the map is the keeper's own front for it
	for slot, s in f.slots do
		if s.kind == "Unit" then
			local door, front = KeeperMap.doorFront(map, slot, Keeper.Front)
			local spot, middle = Keeper.front(s)
			ok(
				flat(door, middle) < 1e-6 and door.y == 0,
				`{where}: unit {s.number}'s door is its middle`
			)
			ok(flat(front, spot) < 1e-6, `{where}: unit {s.number}'s front is the keeper's`)
		end
	end

	-- a wrong code's alarm reaches every hall on the floor
	local farthest = 0
	for _, i in map.stops do
		farthest = math.max(farthest, walker:length(lobby, middleOf(map, i)))
	end
	ok(
		farthest < Keypad.Heard.Wrong,
		`{where}: the alarm reaches the farthest hall ({math.round(farthest)})`
	)

	local slot, place = unitNear(map, walker, lobby, Floor.Cell * 0.75, Floor.Cell * 1.5)
	ok(slot ~= 0, `{where}: a unit about a hall piece from the lobby to test with`)
	if slot == 0 then
		continue
	end
	local door, front = KeeperMap.doorFront(map, slot, Keeper.Front)
	local inside = middleOf(map, place)
	local deep = flat(inside, door)
	local listener = Keeper.new(MANNEQUIN, map, random, lobby, vector.create(0, 0, -1), true)
	listener.state = "Roaming"
	local trip = walker:length(lobby, door)

	-- in a hall: the sound is where it is, at its whole reach
	do
		local from, spot, carries = Keeper.heardFrom(listener, vector.create(2, 3, 1), 50)
		ok(
			from.x == 2 and from.z == 1 and from.y == 0 and spot == from,
			`{where}: a hall's sound is where it is`
		)
		ok(carries == 50, `{where}: and carries its whole reach`)
	end

	-- in a unit, its door down: heard through the door, muffled, from the door's front
	KeeperMap.setDoor(map, slot, false)
	do
		local p = vector.create(inside.x, 2, inside.z)
		local from, spot, carries = Keeper.heardFrom(listener, p, 100)
		ok(
			flat(from, door) < 1e-6 and flat(spot, front) < 1e-6,
			`{where}: behind a shut door, heard from its front`
		)
		ok(
			math.abs(carries - (100 * Keeper.Muffled - deep)) < 1e-6,
			`{where}: muffled, less the way to the door ({carries})`
		)
		-- a keeper in that unit hears it where it is
		local inUnit = Keeper.new(
			MANNEQUIN,
			map,
			random,
			inside + vector.create(0.5, 0, 0),
			vector.create(0, 0, 1)
		)
		local f2, _, c2 = Keeper.heardFrom(inUnit, p, 100)
		ok(flat(f2, p) < 1e-6 and c2 == 100, `{where}: in the same unit it hears it where it is`)
		local d = Keeper.heardAt(inUnit, p, 100)
		ok(d ~= nil and inUnit.state == "Going", `{where}: and wakes to it, door down or not`)
	end

	-- up on its top: out over the front, its whole reach less the way to the door
	do
		local p = vector.create(inside.x, 11, inside.z)
		local from, spot, carries = Keeper.heardFrom(listener, p, 60)
		ok(
			flat(from, door) < 1e-6 and flat(spot, front) < 1e-6,
			`{where}: on the top, heard from the front`
		)
		ok(math.abs(carries - (60 - deep)) < 1e-6, `{where}: unmuffled, less the way to the door`)
	end

	-- its door up: the sound is in the unit, the keeper comes in to look as before
	KeeperMap.setDoor(map, slot, true)
	do
		local p = vector.create(inside.x, 2, inside.z)
		local from, _, carries = Keeper.heardFrom(listener, p, 100)
		ok(
			flat(from, p) < 1e-6 and carries == 100,
			`{where}: its door up, the sound is where it is`
		)
	end
	KeeperMap.setDoor(map, slot, false)

	-- a saw behind the shut door: a keeper in reach comes to stand outside it, facing the door
	do
		local p = vector.create(inside.x, 2, inside.z)
		local k = Keeper.new(MANNEQUIN, map, random, lobby, vector.create(0, 0, -1), true)
		k.state = "Roaming"
		local heard, news = Keeper.heardAt(k, p, Sawing.Heard)
		local need = trip + deep
		ok(
			heard ~= nil and news,
			`{where}: the saw behind a shut door is heard ({math.round(need)} away)`
		)
		ok(k.state == "Going" and flat(k.goal, front) < TOL, `{where}: it goes to the door's front`)
		ok(Keeper.pace(k, RUN) == 0, `{where}: but first it stops`)
		for _ = 1, 60 * 120 do
			Keeper.step(k, DT, RUN)
			if k.state ~= "Going" then
				break
			end
		end
		ok(
			k.state == "Waiting" and flat(k.at, front) < TOL,
			`{where}: it stands outside the door ({k.state})`
		)
		ok(facingToward(k, door), `{where}: facing the door`)
		ok(KeeperMap.placeAt(map, k.at) ~= place, `{where}: and never gets in`)
	end

	-- past the muffled reach, nothing
	do
		local p = vector.create(inside.x, 2, inside.z)
		local k = Keeper.new(MANNEQUIN, map, random, lobby, vector.create(0, 0, -1), true)
		k.state = "Roaming"
		local reach = (trip + deep) / Keeper.Muffled - 1 -- through an open door, it would carry
		ok(
			Keeper.heardAt(k, p, reach) == nil and k.state == "Roaming",
			`{where}: muffled out of reach, it roams on`
		)
	end

	-- news: a new sound stops it; the same one going on doesn't; one elsewhere does again
	do
		local k = Keeper.new(MANNEQUIN, map, random, lobby, vector.create(0, 0, -1), true)
		k.state = "Roaming"
		local a = vector.create(0, 3, 0)
		local _, news1 = Keeper.heardAt(k, a, 100)
		ok(
			news1 and k.startle == MANNEQUIN.startle,
			`{where}: the first sound is news, and stops it`
		)
		for _ = 1, math.ceil(MANNEQUIN.startle / DT) + 1 do
			Keeper.step(k, DT, RUN)
		end
		ok(k.startle == 0, `{where}: it stops for its startle, then goes`)
		local near = vector.create(Keeper.Same / 2, 3, 0)
		local heard2, news2 = Keeper.heardAt(k, near, 100)
		ok(heard2 ~= nil and not news2, `{where}: the same noise again isn't news`)
		ok(k.startle == 0, `{where}: and doesn't stop it again`)
		local there = vector.create(front.x, 3, front.z)
		if flat(front, a) > Keeper.Same then
			local heard3, news3 = Keeper.heardAt(k, there, 200)
			ok(
				heard3 ~= nil and news3 and k.startle > 0,
				`{where}: a sound elsewhere is news again`
			)
		end
		-- once it moves on to roam, the same spot is news again
		k.state, k.waited, k.wait = "Waiting", 0, 0
		Keeper.step(k, DT, RUN)
		ok(
			k.state == "Roaming" and not k.listening,
			`{where}: moved on, it's listening for anything`
		)
		local _, news4 = Keeper.heardAt(k, there, 200)
		ok(news4, `{where}: so a sound where it last looked is news`)
	end

	-- hunting, it hears none of it
	do
		local k = Keeper.new(MANNEQUIN, map, random, lobby, vector.create(0, 0, -1), true)
		k.state = "Hunting"
		local heard, news = Keeper.heardAt(k, vector.create(1, 3, 1), 400)
		ok(
			heard == nil and not news and k.state == "Hunting",
			`{where}: hunting, no noise turns it`
		)
	end

	-- a sleeper behind its own shut door hears nothing from the halls, as before
	do
		local sleeper = Keeper.new(MANNEQUIN, map, random, inside, vector.create(0, 0, 1))
		ok(
			Keeper.heardAt(sleeper, vector.create(0, 3, 0), 400) == nil,
			`{where}: shut in asleep, the alarm doesn't reach it`
		)
		ok(sleeper.state == "Asleep", `{where}: it sleeps on`)
	end
end

print(`hearing: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
