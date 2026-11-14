--!strict
-- lune run tests/spread.spec
-- Monsters called to one spot spread round it (S2-07a2): a wrong code's alarm turns every monster
-- on the floor for the keypad, and they come to stand each in its own place round it, never one
-- body in another, the nearest on the spot itself. Each place is on the floor, clear of the walls
-- and in plain sight of the spot (never behind a wall or a shut door). One already standing keeps
-- its place when the noise goes on; one shut in is given a place for once it's out; one alone
-- looks from the spot itself, as before.
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
local MANNEQUIN = KeeperRows.Mannequin

local function flat(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

-- The places, from the map alone: the spot first, the rest apart, on the floor and in its sight.
local function checkPlaces(map: KeeperMap.Map, spot: vector, n: number, where: string)
	local places = KeeperMap.spread(map, spot, n, Keeper.Spread, Keeper.SpreadWall)
	ok(#places == n, `{where}: {n} places round the spot ({#places})`)
	ok(places[1] == spot, `{where}: the first is the spot itself`)
	for i, p in places do
		ok(KeeperMap.off(map, p) == 0, `{where}: place {i} is on the floor`)
		ok(KeeperMap.clear(map, spot, p), `{where}: place {i} is in sight of the spot`)
		for j = i + 1, #places do
			ok(flat(p, places[j]) >= Keeper.Spread - 1e-6, `{where}: places {i} and {j} apart`)
		end
	end
	local again = KeeperMap.spread(map, spot, n, Keeper.Spread, Keeper.SpreadWall)
	local same = #again == #places
	for i, p in places do
		same = same and again[i] == p
	end
	ok(same, `{where}: the same places every time`)
end

local floors = 0
local function checkFloor(seed: number, number: number)
	local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local where = `floor {number} seed {seed}`
	local map = KeeperMap.build(f)
	floors += 1
	-- the keypad's alarm in the lobby, and a sound in a hall straight
	local keypad = vector.create(0, 3, 0)
	local _, lobbySpot = Keeper.soundAt(map, keypad)
	checkPlaces(map, lobbySpot, 6, `{where} lobby`)
	local hallStop = map.stops[1 + (seed % #map.stops)]
	local hall = vector.create(
		(map.minX[hallStop] + map.maxX[hallStop]) / 2,
		0,
		(map.minZ[hallStop] + map.maxZ[hallStop]) / 2
	)
	checkPlaces(map, hall, 3, `{where} hall`)
	ok(#KeeperMap.spread(map, hall, 1, Keeper.Spread, Keeper.SpreadWall) == 1, `{where}: one place`)

	-- five monsters awake at stops round the floor, the alarm calls them all
	local ks: { Keeper.Keeper } = {}
	local starts = {}
	for i = 1, #map.stops do
		if #ks >= 5 then
			break
		end
		local s = map.stops[1 + (i * 7 + seed) % #map.stops]
		local p = vector.create((map.minX[s] + map.maxX[s]) / 2, 0, (map.minZ[s] + map.maxZ[s]) / 2)
		local fresh = true
		for _, q in starts do
			fresh = fresh and flat(p, q) > 1
		end
		if fresh then
			table.insert(starts, p)
			local k = Keeper.new(
				MANNEQUIN,
				map,
				Brix.Random.new({ seed = seed * 10 + i }),
				p,
				vector.create(1, 0, 0),
				true
			)
			k.state, k.wait, k.waited = "Waiting", 1e6, 0
			table.insert(ks, k)
		end
	end
	for _, k in ks do
		Keeper.alarm(k, keypad, 1)
	end
	Keeper.spread(ks, lobbySpot)
	local goals: { vector } = {}
	for _, k in ks do
		ok(k.state == "Going", `{where}: each turns for the keypad`)
		for _, g in goals do
			ok(flat(g, k.goal) >= Keeper.Spread - 1e-6, `{where}: each goes to its own place`)
		end
		table.insert(goals, k.goal)
	end
	-- the nearest takes the spot itself
	local nearest, best = nil :: Keeper.Keeper?, math.huge
	for _, k in ks do
		local d = k.pathing:length(k.at, lobbySpot)
		if d < best then
			nearest, best = k, d
		end
	end
	ok(nearest ~= nil and nearest.goal == lobbySpot, `{where}: the nearest takes the spot itself`)
	-- they walk there and stand apart, each facing the keypad
	-- (each is left standing as it gets there, so the first in doesn't roam off before the last)
	for _ = 1, 60 * 120 do
		local all = true
		for _, k in ks do
			if k.state ~= "Waiting" then
				Keeper.step(k, DT, RUN)
			end
			all = all and k.state == "Waiting"
		end
		if all then
			break
		end
	end
	for i, k in ks do
		ok(k.state == "Waiting", `{where}: monster {i} got there and looks round`)
		for j = i + 1, #ks do
			ok(
				flat(k.at, ks[j].at) >= Keeper.Spread - 1e-3,
				`{where}: monsters {i} and {j} stand apart ({flat(k.at, ks[j].at)})`
			)
		end
		local toward = lobbySpot - k.at
		local m = math.sqrt(toward.x * toward.x + toward.z * toward.z)
		ok(
			m < 1e-3 or (k.facing.x * toward.x + k.facing.z * toward.z) / m > 0.9,
			`{where}: monster {i} faces the keypad`
		)
	end
	-- the alarm again: those standing keep their places
	local stood: { vector } = {}
	for i, k in ks do
		stood[i] = k.at
		Keeper.alarm(k, keypad, 1)
	end
	Keeper.spread(ks, lobbySpot)
	for i, k in ks do
		ok(
			flat(k.goal, stood[i]) < 1e-2,
			`{where}: monster {i} keeps its place as the noise goes on`
		)
	end

	-- one shut in hears it too: it's given a place after the loose ones, and goes there once out
	local unitPlace = 0
	for i = 1, #map.minX do
		if map.unit[i] ~= 0 then
			unitPlace = i
			break
		end
	end
	local index = map.unit[unitPlace]
	local inUnit = vector.create(
		(map.minX[unitPlace] + map.maxX[unitPlace]) / 2,
		0,
		(map.minZ[unitPlace] + map.maxZ[unitPlace]) / 2
	)
	local shut = Keeper.new(
		MANNEQUIN,
		map,
		Brix.Random.new({ seed = seed }),
		inUnit,
		vector.create(1, 0, 0),
		true
	)
	ok(Keeper.trap(shut, f.slots[index], index), `{where}: one shut in`)
	local a = Keeper.new(
		MANNEQUIN,
		map,
		Brix.Random.new({ seed = 1 }),
		starts[1],
		vector.create(1, 0, 0),
		true
	)
	local b = Keeper.new(
		MANNEQUIN,
		map,
		Brix.Random.new({ seed = 2 }),
		starts[2],
		vector.create(1, 0, 0),
		true
	)
	for _, k in { a, b, shut } do
		Keeper.alarm(k, keypad, 1)
	end
	local against = shut.goal
	Keeper.spread({ shut, a, b }, lobbySpot)
	ok(shut.state == "Trapped" and shut.goal == against, `{where}: shut in, it stays at its door`)
	ok(
		shut.place ~= lobbySpot
			and flat(shut.place, a.goal) >= Keeper.Spread - 1e-6
			and flat(shut.place, b.goal) >= Keeper.Spread - 1e-6,
		`{where}: shut in, it's kept a place of its own`
	)
	Keeper.lookOut(shut, f.slots[index], index)
	ok(shut.state == "Going" and shut.goal == shut.place, `{where}: out, it goes to its place`)

	-- one alone looks from the spot itself
	local lone = Keeper.new(
		MANNEQUIN,
		map,
		Brix.Random.new({ seed = seed }),
		starts[1],
		vector.create(1, 0, 0),
		true
	)
	Keeper.alarm(lone, keypad, 1)
	Keeper.spread({ lone }, lobbySpot)
	ok(lone.goal == lobbySpot and lone.place == lobbySpot, `{where}: alone, it looks from the spot`)
end

for seed = 1, 10 do
	for _, number in { 1, 2, 3, 5, 9 } do
		checkFloor(seed, number)
	end
end

if failures > 0 then
	error(`spread: {failures} of {checks} checks failed`)
end
print(`spread: all {checks} checks passed ({floors} floors)`)
