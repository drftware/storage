--!strict
-- lune run tests/keepermap.spec
-- The keepers' map (L-06b1, D-068) on seeded floors of every plan: every unit has a doorway and
-- every hall is reachable from the lobby; Brix's Pathing promises hold (lengths never negative, 0
-- to the same point, the same both ways, never beaten by a detour; `advance` never overshoots and
-- leaves exactly the rest of the trip); no trip crosses a wall or goes through a shut door; a
-- keeper's route gets there, never further per step than it's given, and plans again when a door
-- shuts or opens; a passage that needs an ability is used only by keepers with it, and a raised
-- place holds only points up on it; and a warm route's steps allocate nothing.
local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local KeeperMap = require("../src/shared/KeeperMap")

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

-- a keeper's or player's middle stands about this far over the floor
local MIDDLE = 3
-- positions are vectors, 32-bit floats: a few hundred studs out they're good to about 3e-5
local function tol(x: number): number
	return 1e-4 + 1e-6 * math.abs(x)
end
local function flat(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

local rng = Brix.Random.new({ seed = 2026 })
local function pointIn(map: KeeperMap.Map, i: number): vector
	local x = map.minX[i] + rng:nextNumber() * (map.maxX[i] - map.minX[i])
	local z = map.minZ[i] + rng:nextNumber() * (map.maxZ[i] - map.minZ[i])
	return vector.create(x, map.y[i] + MIDDLE, z)
end
local function middleOf(map: KeeperMap.Map, i: number): vector
	return vector.create(
		(map.minX[i] + map.maxX[i]) / 2,
		map.y[i] + MIDDLE,
		(map.minZ[i] + map.maxZ[i]) / 2
	)
end
local function inPlace(map: KeeperMap.Map, i: number, p: vector): boolean
	local e = 1e-6
	return p.x >= map.minX[i] - e
		and p.x <= map.maxX[i] + e
		and p.z >= map.minZ[i] - e
		and p.z <= map.maxZ[i] + e
end
local function onMap(map: KeeperMap.Map, p: vector): boolean
	for i = 1, #map.minX do
		if inPlace(map, i, p) then
			return true
		end
	end
	return false
end

-- Whether the straight leg from a to b stays on one place a keeper may be on: a hall, an open
-- unit, or the unit the trip starts or ends in.
local function legOk(
	map: KeeperMap.Map,
	a: vector,
	b: vector,
	doorOpen: { [number]: boolean },
	ends: { [number]: boolean }
): boolean
	for i = 1, #map.minX do
		if inPlace(map, i, a) and inPlace(map, i, b) then
			local unit = map.unit[i]
			if unit == 0 or doorOpen[unit] or ends[i] then
				return true
			end
		end
	end
	return false
end

local floors, worstStep = 0, 0
local function checkFloor(seed: number, number: number)
	local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local where = `floor {number} seed {seed}`
	local map = KeeperMap.build(f)
	local walker = KeeperMap.pathing(map)
	local _: Brix.Pathing = walker -- the game's pathing is Brix's type
	floors += 1

	-- every unit has a doorway, and the lobby reaches every hall with every door down
	local lobbyPlace =
		KeeperMap.placeAt(map, vector.create(f.cells[f.lobby].x, MIDDLE, f.cells[f.lobby].z))
	local lobby = middleOf(map, lobbyPlace)
	for i, s in f.slots do
		if s.kind == "Unit" then
			ok(map.doorways[i] ~= nil, `{where}: unit {s.number} has a doorway`)
		end
	end
	for i = 1, #map.minX do
		local d = walker:length(lobby, middleOf(map, i))
		if map.unit[i] == 0 then
			ok(d < math.huge, `{where}: hall place {i} is reachable from the lobby`)
		else
			ok(d == math.huge, `{where}: unit place {i} is shut away while its door is down`)
		end
	end

	-- open about half the doors
	local doorOpen: { [number]: boolean } = {}
	for i, s in f.slots do
		if s.kind == "Unit" and rng:nextNumber() < 0.5 then
			KeeperMap.setDoor(map, i, true)
			doorOpen[i] = true
		end
	end
	for i = 1, #map.minX do
		local unit = map.unit[i]
		if unit ~= 0 then
			local d = walker:length(lobby, middleOf(map, i))
			ok(
				(d < math.huge) == (doorOpen[unit] == true),
				`{where}: a unit is reachable exactly while its door is up`
			)
		end
	end

	-- points: on random places, and a few off the map (behind the elevator, far out, under a wall)
	local points: { vector } = {}
	for _ = 1, 36 do
		table.insert(points, pointIn(map, rng:nextInteger(1, #map.minX)))
	end
	table.insert(points, lobby + vector.create(0, 0, 40))
	table.insert(points, vector.create(500, MIDDLE, -500))
	table.insert(points, vector.create(f.cells[f.lobby].x + 5.5, MIDDLE, f.cells[f.lobby].z - 30))

	-- Brix's Pathing promise 1
	for _, p in points do
		ok(walker:length(p, p) == 0, `{where}: 0 from a point to itself`)
	end
	for _ = 1, 120 do
		local p = points[rng:nextInteger(1, #points)]
		local q = points[rng:nextInteger(1, #points)]
		local r = points[rng:nextInteger(1, #points)]
		local pq, qp = walker:length(p, q), walker:length(q, p)
		ok(pq >= 0, `{where}: never negative`)
		local apart, slack = math.abs(pq - qp), tol(pq)
		ok(pq == qp or apart <= slack, `{where}: the same both ways ({pq} and {qp})`)
		local pr, rq = walker:length(p, r), walker:length(r, q)
		ok(pq <= pr + rq + tol(pq), `{where}: no detour is shorter ({pq} against {pr} + {rq})`)
	end

	-- Brix's Pathing promise 2: advance
	for _ = 1, 60 do
		local p = points[rng:nextInteger(1, #points)]
		local q = points[rng:nextInteger(1, #points)]
		local whole = walker:length(p, q)
		ok(
			walker:advance(p, q, 0) == p and walker:advance(p, q, -2) == p,
			`{where}: no studs, no move`
		)
		ok(walker:advance(p, q, 0 / 0) == p, `{where}: NaN studs, no move`)
		local studs = if rng:nextNumber() < 0.2
			then whole + 5
			else rng:nextNumber() * math.min(whole, 400)
		local r = walker:advance(p, q, studs)
		if whole == math.huge then
			ok(r == p, `{where}: nothing advances with no way there`)
		elseif studs > 0 then
			local gone, rest = walker:length(p, r), walker:length(r, q)
			local within = gone <= studs + tol(studs)
			ok(within, `{where}: advance never overshoots ({gone} for {studs} from {p} toward {q})`)
			local want = math.max(0, whole - studs)
			-- the slack in a local of its own: Lune 0.10.5 mis-compares it inline here (docs/STUDIO.md)
			local slack = tol(whole) * 10
			local miss = math.abs(rest - want)
			ok(miss <= slack, `{where}: the rest of the trip is left ({rest}, want {want})`)
			ok(math.abs(r.y - p.y) < 1e-9, `{where}: a traveller keeps its height on one level`)
		end
	end

	-- no trip crosses a wall or goes through a shut door
	for _ = 1, 50 do
		local P = rng:nextInteger(1, #map.minX)
		local Q = rng:nextInteger(1, #map.minX)
		local p, q = pointIn(map, P), pointIn(map, Q)
		local whole = walker:length(p, q)
		local trip = KeeperMap.trip(walker, p, q)
		ok((trip == nil) == (whole == math.huge), `{where}: a trip exactly when there's a way`)
		if trip then
			local ends = { [P] = true, [Q] = true }
			local sum, at, clean = 0, p, true
			for _, w in trip do
				clean = clean and legOk(map, at, w, doorOpen, ends)
				sum += flat(at, w)
				at = w
			end
			ok(clean, `{where}: every leg of a trip stays on a hall, an open unit or its own ends`)
			local miss, slack = math.abs(sum - whole), tol(whole) * 10
			ok(miss <= slack, `{where}: a trip is as long as its length ({sum}, {whole})`)
			ok(flat(at, q) < 1e-9, `{where}: a trip ends at its destination`)
		end
	end

	-- a route gets there, never more than its step at a time, always on the map
	for _ = 1, 12 do
		local p = pointIn(map, rng:nextInteger(1, #map.minX))
		local q = pointIn(map, rng:nextInteger(1, #map.minX))
		local whole = walker:length(p, q)
		if whole < math.huge then
			local route = walker:route()
			local step = 1.6
			local at, steps, bad = p, 0, nil :: string?
			while walker:length(at, q) > 1e-6 and steps < whole / step + 3 do
				local nextAt = route:advance(at, q, step)
				local moved = walker:length(at, nextAt)
				worstStep = math.max(worstStep, moved - step)
				if bad == nil and (moved > step + tol(step) or not onMap(map, nextAt)) then
					bad = `step {steps + 1} from {at} to {nextAt} moved {moved} toward {q} from {p}`
				end
				at = nextAt
				steps += 1
			end
			ok(bad == nil, `{where}: each route step is on the map and within its studs ({bad})`)
			ok(
				walker:length(at, q) <= 1e-6,
				`{where}: a route gets there ({steps} steps over {whole} studs)`
			)
			ok(
				steps <= math.ceil(whole / step) + 1,
				`{where}: a route takes no longer than its trip`
			)
			route:release()
			route:release()
		end
	end

	-- a route plans again when a door shuts and opens
	local unit, unitSlot = 0, 0
	for i = 1, #map.minX do
		if map.unit[i] ~= 0 and doorOpen[map.unit[i]] then
			unit, unitSlot = i, map.unit[i]
			break
		end
	end
	if unit ~= 0 then
		local inside = middleOf(map, unit)
		local route = walker:route()
		local at = route:advance(lobby, inside, 3)
		KeeperMap.setDoor(map, unitSlot, false)
		local held = route:advance(at, inside, 3)
		ok(held == at, `{where}: a keeper heading into a unit stops when its door comes down`)
		KeeperMap.setDoor(map, unitSlot, true)
		for _ = 1, 400 do
			at = route:advance(at, inside, 3)
		end
		ok(flat(at, inside) < 1e-6, `{where}: and goes on in once it's up again`)
		route:release()
	end
end

for seed = 1, 60 do
	checkFloor(seed, 1 + seed % 10) -- every floor's plan
end

-- Abilities: a passage that needs one is used only by keepers with it (owner, Nov 9: a keeper may
-- climb ladders or crawl through cut-outs).
do
	local f = Floor.generate(5, Brix.Random.new({ seed = 7 }))
	local map = KeeperMap.build(f)
	local walker = KeeperMap.pathing(map)
	local crawler = KeeperMap.pathing(map, { "Crawl" })
	local climber = KeeperMap.pathing(map, { "Climb" })
	ok(KeeperMap.pathing(map, {}) == walker, "keepers with the same abilities share a pathing")
	ok(
		KeeperMap.pathing(map, { "Crawl", "Climb" }) == KeeperMap.pathing(map, { "Climb", "Crawl" }),
		"in any order"
	)
	local from, into = 0, 0
	for i, s in f.slots do
		if s.kind == "Unit" then
			local next = Floor.crawlsTo(f, i)
			if #next > 0 then
				from, into = i, next[1]
				break
			end
		end
	end
	ok(from ~= 0, "the floor has two units side by side")
	local function unitPlace(slot: number): number
		for i = 1, #map.minX do
			if map.unit[i] == slot then
				return i
			end
		end
		return 0
	end
	local a, b = middleOf(map, unitPlace(from)), middleOf(map, unitPlace(into))
	local hole = KeeperMap.connect(map, a, b, { needs = "Crawl", slow = 2 })
	ok(walker:length(a, b) == math.huge, "a walker can't use a crawl hole")
	ok(climber:length(a, b) == math.huge, "nor can a climber")
	ok(
		math.abs(crawler:length(a, b) - 2 * flat(a, b)) < 1e-9,
		"a crawler goes through, slower than walking"
	)
	local through = KeeperMap.trip(crawler, a, b)
	ok(through ~= nil and #through == 3, "its trip is the hole's two ends and the far side")
	local route = crawler:route()
	local at = a
	for _ = 1, 100 do
		at = route:advance(at, b, 0.5)
	end
	ok(flat(at, b) < 1e-9, "a crawler's route crawls through")
	KeeperMap.setOpen(map, hole, false)
	ok(crawler:length(a, b) == math.huge, "a shut hole stops a crawler too")

	-- a raised place (the tops over a unit) and a ladder up to it
	local s = f.slots[from]
	local x0, x1, z0, z1 = Floor.footprint(s)
	local top = KeeperMap.addPlace(map, x0, x1, z0, z1, 10)
	local fx, fz = Floor.dir(s.facing)
	local foot = vector.create(s.x + fx, MIDDLE, s.z + fz)
	local up = vector.create((x0 + x1) / 2, 10 + MIDDLE, (z0 + z1) / 2)
	KeeperMap.connect(map, foot, up, { needs = "Climb" })
	local under = vector.create(up.x, MIDDLE, up.z)
	ok(KeeperMap.placeAt(map, up) == top, "a point up on the tops is on them")
	ok(select(2, KeeperMap.placeAt(map, under)) == from, "a point under them is in the unit")
	local lobby = vector.create(f.cells[f.lobby].x, MIDDLE, f.cells[f.lobby].z)
	ok(walker:length(lobby, up) == math.huge, "a walker can't reach the tops")
	ok(crawler:length(lobby, up) == math.huge, "nor a crawler")
	ok(climber:length(lobby, up) < math.huge, "a climber can")
	local climb = climber:route()
	local at2 = lobby
	for _ = 1, 2000 do
		at2 = climb:advance(at2, up, 1)
	end
	ok(
		flat(at2, up) < 1e-9 and math.abs(at2.y - up.y) < 1e-9,
		"a climber's route climbs to the tops"
	)
	ok(not pcall(function()
		KeeperMap.pathing(map, { "Fly" :: any }) -- any: a row with an ability that doesn't exist
	end), "an unknown ability is refused")
end

-- What a door lets through: only all the way up.
for _, state in
	{ "Closed", "Peeking", "Opening", "Lifting", "Open", "Closing", "Slamming", "Locked" }
do
	ok(
		KeeperMap.letsThrough(state :: any) == (state == "Open"),
		`a door {state} lets keepers through only when Open`
	) -- any: the names as text
end

-- A warm route's steps allocate nothing, nor do `length` and `advance`, even planning again.
local timing = 0
do
	local f = Floor.generate(9, Brix.Random.new({ seed = 3 }))
	local map = KeeperMap.build(f)
	for i, s in f.slots do
		if s.kind == "Unit" and i % 2 == 0 then
			KeeperMap.setDoor(map, i, true)
		end
	end
	local walker = KeeperMap.pathing(map)
	local far: { vector } = {}
	for i = 1, #map.minX, math.max(1, #map.minX // 6) do
		table.insert(far, middleOf(map, i))
	end
	local route = walker:route()
	local function run(steps: number)
		local at = far[1]
		for n = 1, steps do
			local target = far[(n // 40) % #far + 1] + vector.create(math.sin(n) * 0.5, 0, 0)
			at = route:advance(at, target, 1.6)
			walker:length(at, far[n % #far + 1])
			walker:advance(at, far[n % #far + 1], 2)
		end
	end
	run(4000) -- warm: every buffer grown
	local before = collectgarbage("count")
	run(4000)
	local grew = collectgarbage("count") - before
	ok(grew < 1, `a warm route allocates nothing ({grew} KB over 4000 steps)`)
	local clock = os.clock()
	for n = 1, 2000 do
		walker:length(far[n % #far + 1], far[(n * 7) % #far + 1])
	end
	timing = (os.clock() - clock) / 2000 * 1e6
end

if failures > 0 then
	error(`{failures} of {checks} keeper map checks failed`)
end
print(
	`keepermap: {checks} checks passed over {floors} floors (a step at most {string.format(
		"%.1e",
		worstStep
	)} `
		.. `over its studs; a length across a full floor takes {string.format("%.0f", timing)} µs)`
)
