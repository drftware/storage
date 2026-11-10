--!strict
-- lune run tests/horn.spec
-- Blowing the air horn (L-14a2): one blow every `Gap` seconds; a friend's arm eased up, held
-- through the blast and down; a blast heard along the halls by every keeper in reach, which comes
-- to where it was blown (a sleeper in an open unit wakes and comes), never through a shut door,
-- never by a keeper hunting; and whether a point is on a floor at all.
local Brix = require("../vendor/brix/src")
local DoorSound = require("../src/shared/StorageUnit/DoorSound")
local Floor = require("../src/shared/Floor")
local Horn = require("../src/shared/Tools/Horn")
local Keeper = require("../src/shared/Keeper")
local KeeperMap = require("../src/shared/KeeperMap")
local KeeperRows = require("../src/shared/KeeperRows")
local Catalog = require("../src/shared/Tools/Catalog")

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
local RANDOM = Brix.Random.new({ seed = 1 })
local TOL = 2e-3

local function flat(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end
local function middleOf(map: KeeperMap.Map, i: number): vector
	return vector.create((map.minX[i] + map.maxX[i]) / 2, map.y[i], (map.minZ[i] + map.maxZ[i]) / 2)
end

-- The press: once every Gap seconds, the server a little lenient.
ok(Horn.allow(nil, 0), "the first blow is always allowed")
ok(not Horn.allow(10, 10 + Horn.Gap - 0.01), "not again before the gap")
ok(Horn.allow(10, 10 + Horn.Gap), "again once the gap is up")
ok(Horn.allow(10, 10 + Horn.Gap - Horn.Slack, Horn.Slack), "the server takes it a little early")
ok(not Horn.allow(10, 10 + Horn.Gap - Horn.Slack - 0.01, Horn.Slack), "but no earlier")
ok(Horn.Gap > Horn.Up, "the horn is down again before the next blow")
ok(Horn.Gap <= 4, "a second blow soon enough to pull a keeper on")

-- The row: a press of its own, one word.
local row = Catalog[Horn.Key]
ok(row ~= nil and row.verb == "Blow", "the air horn's press is Blow")
for key, r in Catalog do
	if r.verb then
		ok(not string.find(r.verb, " "), `{key}'s press is one word ({r.verb})`)
	end
end

-- A friend's arm: up quickly, held through the blast, down after.
ok(Horn.arm(-0.1) == 0, "down before the blast")
ok(Horn.arm(0) == 0, "starting down")
ok(Horn.arm(Horn.ArmIn) == 1 and Horn.arm(Horn.Up - 0.01) == 1, "up through the blast")
ok(Horn.arm(Horn.Up + Horn.ArmOut) == 0, "down once it's over")
local last, smooth = 0, true
for i = 1, 100 do
	local t = Horn.ArmIn * i / 100
	local w = Horn.arm(t)
	if w < last - 1e-9 then
		smooth = false
	end
	last = w
end
ok(smooth, "rising, it never drops back")

-- How far: louder than any door's open or slam, and more than two hall pieces.
ok(Horn.Reach > DoorSound.Actions.Open.Reach, "louder than a door opening")
ok(Horn.Reach > DoorSound.Actions.Slam.Reach, "louder than a slam")
ok(Horn.Reach > 2 * Floor.Cell, "reaches past two hall pieces")
ok(Horn.Near < Horn.Reach, "full loudness only close by")

-- On floor 1 of seed 7, "Walk a floor"'s.
local f = Floor.generate(1, Brix.Random.new({ seed = 7 }))
local map = KeeperMap.build(f)
local walker = KeeperMap.pathing(map)
local lobby = vector.zero

-- whether a point is on the floor at all
ok(Horn.onFloor(map, vector.create(0, 3, 0)), "a player's middle in the lobby is on the floor")
ok(not Horn.onFloor(map, vector.create(0, 40, 0)), "a floor up isn't")
ok(not Horn.onFloor(map, vector.create(5000, 3, 0)), "far off the map isn't")
ok(Horn.onFloor(map, vector.create(0, 13, 0)), "up as high as the tops is")

-- a blast where you stand: the sound on the floor under you; in a hall, the keeper's spot is it
local at, spot = Horn.where(map, vector.create(1, 5, 2))
ok(at.y == 0 and at.x == 1 and at.z == 2, "the sound is dropped to the floor you stand on")
ok(spot == at, "in a hall the keeper comes to where you blew it")

-- A keeper walking two halls off hears it and comes to the spot.
do
	local two, facing = Keeper.hallAbout(map, walker, lobby, 2 * Floor.Cell)
	local trip = walker:length(two, lobby)
	ok(trip < Horn.Reach, `two hall pieces off is inside the reach ({math.round(trip)} studs)`)
	local k = Keeper.new(MANNEQUIN, map, RANDOM, two, facing, true)
	k.state = "Roaming"
	local heard = Horn.heard(k, vector.create(0, 4.5, 0))
	ok(
		heard ~= nil and math.abs((heard :: number) - trip) < 1,
		"it hears it, as far off as its trip"
	)
	ok(k.state == "Going" and flat(k.goal, lobby) < TOL, "it goes to where you blew it")
	for _ = 1, 60 * 60 do
		Keeper.step(k, DT, RUN)
		if k.state ~= "Going" then
			break
		end
	end
	ok(k.state == "Waiting" and flat(k.at, lobby) < TOL, `it stands there looking ({k.state})`)
	ok(k.at.y == 0, "on the floor, not at the horn's height")
end

-- Beyond its reach, a keeper hears nothing.
do
	local far, facing = Keeper.hallAbout(map, walker, lobby, Horn.Reach + 40)
	local trip = walker:length(far, lobby)
	if trip > Horn.Reach then
		local k = Keeper.new(MANNEQUIN, map, RANDOM, far, facing, true)
		k.state = "Roaming"
		ok(Horn.heard(k, lobby) == nil and k.state == "Roaming", "out of reach, it roams on")
	else
		ok(false, `the floor has a hall beyond the reach to test with ({math.round(trip)})`)
	end
end

-- A hunting keeper keeps its eyes on whom it hunts.
do
	local two, facing = Keeper.hallAbout(map, walker, lobby, 2 * Floor.Cell)
	local k = Keeper.new(MANNEQUIN, map, RANDOM, two, facing, true)
	k.state = "Hunting"
	ok(Horn.heard(k, lobby) == nil and k.state == "Hunting", "hunting, it doesn't turn to it")
end

-- A sleeper in a unit near the blast: its door up, it wakes and comes; its door down, it sleeps.
do
	local slot, inside = 0, vector.zero
	for i = 1, #map.minX do
		local s = map.unit[i]
		if s ~= 0 then
			KeeperMap.setDoor(map, s, true)
			local m = middleOf(map, i)
			local d = walker:length(m, lobby)
			if d < Horn.Reach - 10 and d > Floor.Cell then
				slot, inside = s, m
				break
			end
			KeeperMap.setDoor(map, s, false)
		end
	end
	ok(slot ~= 0, "a unit inside the reach to test with")
	if slot ~= 0 then
		local sleeper = Keeper.new(MANNEQUIN, map, RANDOM, inside, vector.create(0, 0, 1))
		ok(sleeper.state == "Asleep", "dealt asleep")
		ok(Horn.heard(sleeper, lobby) ~= nil, "its door up, it hears the blast")
		ok(sleeper.state == "Going" and Keeper.awake(sleeper), "and wakes, coming to look")
		KeeperMap.setDoor(map, slot, false)
		local shut = Keeper.new(MANNEQUIN, map, RANDOM, inside, vector.create(0, 0, 1))
		ok(Horn.heard(shut, lobby) == nil and shut.state == "Asleep", "its door down, it sleeps on")
		-- blown inside the unit: the spot is kept off its walls, where a keeper can stand
		KeeperMap.setDoor(map, slot, true)
		local i = KeeperMap.placeAt(map, inside)
		local corner = vector.create(map.minX[i] + 0.2, 4, map.minZ[i] + 0.2)
		local _, s2 = Horn.where(map, corner)
		ok(
			s2.x >= map.minX[i] + Keeper.Against - TOL or s2.x == (map.minX[i] + map.maxX[i]) / 2,
			"blown in a unit's corner, the keeper looks from off its walls"
		)
	end
end

print(`horn: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
