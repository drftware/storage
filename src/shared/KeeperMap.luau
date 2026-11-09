--!strict
--[[
	KeeperMap: the floor as a map the keepers walk (L-06b1, D-064, D-068). Pure: nothing here
	touches an Instance, so Lune tests it (tests/keepermap.spec.luau).

	The map is places and the passages between them. A place is a stretch of floor a keeper crosses
	in a straight line, a plain rectangle: each straight hall piece, a junction's middle and each of
	its arms, the lobby, and each unit's floor. A passage joins two places: where two hall pieces
	meet, and each unit's doorway, which is shut while its door is down. A keeper crosses a place in
	a straight line from one passage to the next, so it walks down the middle of the halls and turns
	at the middle of each joint, and its shortest trip is found by A* over the passages (the GDD's
	tech plan: "A* over the tile graph"). The elevator car is not on the map: keepers can't ride it.

	Keepers differ in what they can do (the GDD: each keeper's row says how it climbs, and owner,
	Nov 9: some may climb ladders or crawl through cut-outs). So a passage may need an ability, and
	each keeper walks the map through a pathing made for its abilities, which uses only the passages
	it may: `KeeperMap.pathing(map, row.abilities)`. The floor's own passages need nothing. A crawl
	hole, a ladder or the tops join the map while the floor runs, as places (`addPlace`, with a
	height) and passages (`connect`, with the ability they need), so a keeper that climbs or crawls
	is its row plus the call that adds those, never a new map. A passage goes both ways at the same
	cost: Brix's Pathing contract measures every trip the same both ways, so a one-way drop is not
	a passage (D-068).

	Each pathing keeps Brix's Pathing contract (vendor/brix/src/Contracts/Pathing.luau): `length`,
	`advance`, and `route`, a trip one keeper keeps between steps that plans again when a door
	changes or its target moves into another place. Distances run across the floor, height counting
	for nothing within a place (as Brix's floor pathing measures), and a place is found for a point
	by its height too: the highest place whose floor is at or under the point (a stud of slack), so
	a raised place such as the tops holds only points up on it. A point off every place is measured
	from the nearest place's edge, the way out to it counted in. A trip with no way through (a shut
	door, a passage the keeper can't use) is math.huge long, and nothing advances along it.

	Coordinates are the floor's own (Floor: the lobby's middle at the origin, its floor at height 0);
	the server turns world positions into these. No step allocates once warm: the search's scratch
	is kept on the map, and each route keeps its own waypoints, reused in place.
]]

local Door = require("./StorageUnit/Door")
local Floor = require("./Floor")

local HALF = Floor.Cell / 2
local HALL = Floor.HallWidth
-- the middle of a junction's arm: halfway from its middle square's edge to the cell's edge
local ARM_MID = (HALL / 2 + HALF) / 2
-- how far over a place's floor a point may sit and still be on it: a keeper's or player's middle
-- stands a few studs up, so only a place whose floor is above the point by more than this is
-- above it (the tops, over a unit)
local LEVEL_SLACK = 1
-- the size of the squares places are filed under, to find the place a point is in quickly
local BUCKET = 8
-- how close the traveller must be to where its route last put it for the route to carry on
local SAME_SPOT = 1e-3

--- What a keeper can do beyond walking, each opening the passages that need it. A keeper's row
--- lists its abilities; a new ability is a name here and the passages that need it.
export type Ability = "Climb" | "Crawl"
local ABILITY_BITS: { [string]: number } = { Climb = 1, Crawl = 2 }

--- Brix's Route contract, as this game keeps it (structural, so it is Brix's type too).
export type Route = {
	advance: (self: any, from: vector, toward: vector, studs: number) -> vector,
	release: (self: any) -> (),
}

--- Brix's Pathing contract, as this game keeps it (structural, so it is Brix's type too).
export type Pathing = {
	length: (self: any, from: vector, to: vector) -> number,
	advance: (self: any, from: vector, toward: vector, studs: number) -> vector,
	route: (self: any) -> Route,
}

--- What a passage is opened with: the ability it needs (none: any keeper may use it), how much
--- slower than walking crossing it is (1: as fast as walking its length), and whether it starts
--- open.
export type PassageOptions = { needs: Ability?, slow: number?, open: boolean? }

--- The map: plain arrays, one entry per place and per passage end (a "node"). A passage k has two
--- ends: node 2k - 1 in its first place, node 2k in its second.
export type Map = {
	version: number, -- bumped whenever a passage opens, shuts or is added: routes plan again
	-- places
	minX: { number },
	maxX: { number },
	minZ: { number },
	maxZ: { number },
	y: { number }, -- the height of the place's floor
	unit: { number }, -- a unit's place: its slot in the floor; a hall's: 0
	nodesOf: { { number } }, -- each place's passage ends
	buckets: { [number]: { number } }, -- places by BUCKET square, in the order they were added
	-- passages and their ends
	nodeX: { number },
	nodeY: { number },
	nodeZ: { number },
	nodePlace: { number },
	cost: { number }, -- what crossing the passage costs, in studs walked
	slow: { number },
	needs: { number }, -- the abilities it needs, as bits
	open: { boolean },
	doorways: { [number]: number }, -- a unit's slot: its doorway's passage
	-- the search's scratch, kept so a search allocates nothing once warm
	g: { number },
	came: { number },
	seen: { number },
	closed: { number },
	heapNode: { number },
	heapKey: { number },
	stamp: number,
	pathings: { [number]: Pathing },
}

local KeeperMap = {}
KeeperMap.Abilities = { "Climb", "Crawl" } :: { Ability }

local function bucketKey(bx: number, bz: number): number
	return (bx + 2048) * 4096 + (bz + 2048)
end

local function new(): Map
	return {
		version = 0,
		minX = {},
		maxX = {},
		minZ = {},
		maxZ = {},
		y = {},
		unit = {},
		nodesOf = {},
		buckets = {},
		nodeX = {},
		nodeY = {},
		nodeZ = {},
		nodePlace = {},
		cost = {},
		slow = {},
		needs = {},
		open = {},
		doorways = {},
		g = {},
		came = {},
		seen = {},
		closed = {},
		heapNode = {},
		heapKey = {},
		stamp = 0,
		pathings = {},
	}
end

-- Adds a rectangle of floor at height y and files it under every square it touches.
local function place(
	map: Map,
	x0: number,
	x1: number,
	z0: number,
	z1: number,
	y: number,
	unit: number
): number
	assert(x0 < x1 and z0 < z1, "a place is a rectangle with room in it")
	table.insert(map.minX, x0)
	table.insert(map.maxX, x1)
	table.insert(map.minZ, z0)
	table.insert(map.maxZ, z1)
	table.insert(map.y, y)
	table.insert(map.unit, unit)
	table.insert(map.nodesOf, {})
	local i = #map.minX
	for bx = x0 // BUCKET, x1 // BUCKET do
		for bz = z0 // BUCKET, z1 // BUCKET do
			local k = bucketKey(bx, bz)
			local list = map.buckets[k]
			if list then
				table.insert(list, i)
			else
				map.buckets[k] = { i }
			end
		end
	end
	return i
end

local function contains(map: Map, i: number, x: number, z: number): boolean
	return x >= map.minX[i] - 1e-9
		and x <= map.maxX[i] + 1e-9
		and z >= map.minZ[i] - 1e-9
		and z <= map.maxZ[i] + 1e-9
end

-- The place a point stands in, where it meets the map (the point itself when it's on a place) and
-- how far that is from the point (0 on a place). Allocates nothing.
local function locate(map: Map, p: vector): (number, number, number, number)
	local x, z, top = p.x, p.z, p.y + LEVEL_SLACK
	local best = 0
	local list = map.buckets[bucketKey(x // BUCKET, z // BUCKET)]
	if list then
		for _, i in list do
			if
				map.y[i] <= top
				and (best == 0 or map.y[i] > map.y[best])
				and contains(map, i, x, z)
			then
				best = i
			end
		end
	end
	if best ~= 0 then
		return best, x, z, 0
	end
	-- off every place: the nearest one at or under the point, else the nearest of all
	local bestD, bx, bz = math.huge, x, z
	for pass = 1, 2 do
		for i = 1, #map.minX do
			if pass == 2 or map.y[i] <= top then
				local cx = math.clamp(x, map.minX[i], map.maxX[i])
				local cz = math.clamp(z, map.minZ[i], map.maxZ[i])
				local dx, dz = x - cx, z - cz
				local d = math.sqrt(dx * dx + dz * dz)
				if d < bestD then
					best, bestD, bx, bz = i, d, cx, cz
				end
			end
		end
		if best ~= 0 then
			break
		end
	end
	assert(best ~= 0, "the map has no places")
	return best, bx, bz, bestD
end

local function addPassage(
	map: Map,
	a: number,
	ax: number,
	ay: number,
	az: number,
	b: number,
	bx: number,
	by: number,
	bz: number,
	needs: number,
	slow: number,
	open: boolean
): number
	assert(slow >= 1, "a passage is never quicker than walking its length")
	local dx, dy, dz = bx - ax, by - ay, bz - az
	table.insert(map.cost, math.sqrt(dx * dx + dy * dy + dz * dz) * slow)
	table.insert(map.slow, slow)
	table.insert(map.needs, needs)
	table.insert(map.open, open)
	local k = #map.cost
	for e = 1, 2 do
		local n = 2 * k - 2 + e
		local at = if e == 1 then a else b
		map.nodeX[n] = if e == 1 then ax else bx
		map.nodeY[n] = map.y[at]
		map.nodeZ[n] = if e == 1 then az else bz
		map.nodePlace[n] = at
		table.insert(map.nodesOf[at], n)
		map.g[n], map.came[n], map.seen[n], map.closed[n] = 0, 0, 0, 0
	end
	map.version += 1
	return k
end

-- The hall place a point is in (the first filed, so a point on the line between two is the
-- earlier one's), or nil.
local function hallAt(map: Map, x: number, z: number): number?
	local list = map.buckets[bucketKey(x // BUCKET, z // BUCKET)]
	if list then
		for _, i in list do
			if map.unit[i] == 0 and contains(map, i, x, z) then
				return i
			end
		end
	end
	return nil
end

--- Lays the floor's map: every hall piece and the lobby, every unit, the joints between hall
--- pieces (always open) and each unit's doorway (shut, as every door starts down; `setDoor` opens
--- it). Hall places come first, so a point on a doorway's line is in the hall.
function KeeperMap.build(floor: Floor.Floor): Map
	local map = new()
	local dir = Floor.dir
	-- each hall piece's place at each of its ends, by Dir
	local ends: { { number } } = {}
	local byGrid: { [number]: number } = {}
	for i, c in floor.cells do
		byGrid[bucketKey(c.gx, c.gz)] = i
		if c.kind == "Lobby" or c.kind == "Straight" then
			local hx = if c.kind == "Lobby" or c.turn % 2 == 0 then HALF else HALL / 2
			local hz = if c.kind == "Lobby" or c.turn % 2 == 1 then HALF else HALL / 2
			local p = place(map, c.x - hx, c.x + hx, c.z - hz, c.z + hz, 0, 0)
			ends[i] = { p, p, p, p }
		else
			local w = HALL / 2
			local middle = place(map, c.x - w, c.x + w, c.z - w, c.z + w, 0, 0)
			local these = { 0, 0, 0, 0 }
			for d = 0, 3 do
				if c.arms[d + 1] then
					local dx, dz = dir(d)
					local mx, mz = c.x + dx * ARM_MID, c.z + dz * ARM_MID
					local hx = if dx ~= 0 then (HALF - w) / 2 else w
					local hz = if dz ~= 0 then (HALF - w) / 2 else w
					local arm = place(map, mx - hx, mx + hx, mz - hz, mz + hz, 0, 0)
					local jx, jz = c.x + dx * w, c.z + dz * w
					addPassage(map, middle, jx, 0, jz, arm, jx, 0, jz, 0, 1, true)
					these[d + 1] = arm
				end
			end
			ends[i] = these
		end
	end
	-- the joints between hall pieces, each once (from the piece on its -X or -Z side)
	for i, c in floor.cells do
		for d = 0, 1 do
			if c.arms[d + 1] then
				local dx, dz = dir(d)
				local j = byGrid[bucketKey(c.gx + dx, c.gz + dz)]
				assert(j, `a hall leaves cell {i} toward Dir {d} into nothing`)
				local a, b = ends[i][d + 1], ends[j][(d + 2) % 4 + 1]
				assert(a ~= 0 and b ~= 0, `cells {i} and {j} don't meet`)
				local jx, jz = c.x + dx * HALF, c.z + dz * HALF
				addPassage(map, a, jx, 0, jz, b, jx, 0, jz, 0, 1, true)
			end
		end
	end
	-- the units and their doorways, onto the hall just outside each door
	for i, s in floor.slots do
		if s.kind == "Unit" then
			local x0, x1, z0, z1 = Floor.footprint(s)
			local u = place(map, x0, x1, z0, z1, 0, i)
			local fx, fz = dir(s.facing)
			local hall = hallAt(map, s.x + fx * 0.5, s.z + fz * 0.5)
			assert(hall, `unit {s.number}'s door opens onto no hall`)
			map.doorways[i] = addPassage(map, hall, s.x, 0, s.z, u, s.x, 0, s.z, 0, 1, false)
		end
	end
	return map
end

--- Adds a rectangle of floor at a height, such as a stretch of the tops, for keepers able to
--- reach it. Returns its place. Join it to the rest with `connect`.
function KeeperMap.addPlace(
	map: Map,
	x0: number,
	x1: number,
	z0: number,
	z1: number,
	y: number
): number
	local i = place(map, x0, x1, z0, z1, y, 0)
	map.version += 1
	return i
end

-- Takes any text, as a keeper's row is data: a name that isn't an ability is refused.
local function bitsOf(needs: string?): number
	if needs == nil then
		return 0
	end
	local bit = ABILITY_BITS[needs]
	assert(bit, `unknown ability "{needs}"`)
	return bit
end

--- Joins the places two points stand in with a passage from one point to the other, such as a
--- crawl hole between two units or a ladder up to the tops. Returns the passage, to open or shut
--- with `setOpen`.
function KeeperMap.connect(map: Map, a: vector, b: vector, options: PassageOptions?): number
	local pa, ax, az = locate(map, a)
	local pb, bx, bz = locate(map, b)
	assert(pa ~= pb, "a passage joins two places")
	local o: PassageOptions = options or {}
	local open = if o.open == nil then true else o.open
	return addPassage(
		map,
		pa,
		ax,
		map.y[pa],
		az,
		pb,
		bx,
		map.y[pb],
		bz,
		bitsOf(o.needs),
		o.slow or 1,
		open
	)
end

--- Opens or shuts a passage. Every route plans again on its next step.
function KeeperMap.setOpen(map: Map, passage: number, open: boolean)
	if map.open[passage] ~= open then
		map.open[passage] = open
		map.version += 1
	end
end

--- Opens or shuts a unit's doorway, by its slot in the floor.
function KeeperMap.setDoor(map: Map, slot: number, open: boolean)
	local k = map.doorways[slot]
	assert(k, `slot {slot} is not a unit`)
	KeeperMap.setOpen(map, k, open)
end

--- Whether a keeper can walk through a door in this state: only when it's all the way up. A door
--- peeking, rising or coming down is shut to keepers, so pulling a door down is always safety.
function KeeperMap.letsThrough(state: Door.State): boolean
	return state == "Open"
end

--- The place a point stands in (its index), and whether it's a unit's (the unit's slot) or a
--- hall's (0).
function KeeperMap.placeAt(map: Map, p: vector): (number, number)
	local i = locate(map, p)
	return i, map.unit[i]
end

-- The search -------------------------------------------------------------------------------------

local function usable(map: Map, n: number, mask: number): boolean
	local k = (n + 1) // 2
	local needs = map.needs[k]
	return map.open[k] and bit32.band(needs, mask) == needs
end

local function push(map: Map, size: number, n: number, key: number): number
	local nodes, keys = map.heapNode, map.heapKey
	size += 1
	local i = size
	while i > 1 do
		local parent = i // 2
		if keys[parent] <= key then
			break
		end
		nodes[i], keys[i] = nodes[parent], keys[parent]
		i = parent
	end
	nodes[i], keys[i] = n, key
	return size
end

local function pop(map: Map, size: number): (number, number, number)
	local nodes, keys = map.heapNode, map.heapKey
	local top, topKey = nodes[1], keys[1]
	local lastNode, lastKey = nodes[size], keys[size]
	size -= 1
	local i = 1
	while true do
		local child = i * 2
		if child > size then
			break
		end
		if child < size and keys[child + 1] < keys[child] then
			child += 1
		end
		if keys[child] >= lastKey then
			break
		end
		nodes[i], keys[i] = nodes[child], keys[child]
		i = child
	end
	if size > 0 then
		nodes[i], keys[i] = lastNode, lastKey
	end
	return top, topKey, size
end

local function between(map: Map, n: number, x: number, z: number): number
	local dx, dz = map.nodeX[n] - x, map.nodeZ[n] - z
	return math.sqrt(dx * dx + dz * dz)
end

-- The shortest trip from (px, pz) in place P to (qx, qz) in place Q, both on their places, for a
-- keeper with these ability bits: its length (math.huge with no way) and the last passage end it
-- passes before Q (0 when it goes straight). The ends it passes are chained back through
-- `map.came`. A* over the passage ends; across a place a trip is a straight line, so the straight
-- distance to the goal never overestimates. Allocates nothing once warm.
local function search(
	map: Map,
	mask: number,
	P: number,
	px: number,
	pz: number,
	Q: number,
	qx: number,
	qz: number
): (number, number)
	if P == Q then
		local dx, dz = qx - px, qz - pz
		return math.sqrt(dx * dx + dz * dz), 0
	end
	map.stamp += 1
	local stamp = map.stamp
	local g, came, seen, closed = map.g, map.came, map.seen, map.closed
	local size = 0
	local best, bestNode = math.huge, 0
	for _, n in map.nodesOf[P] do
		if usable(map, n, mask) then
			local d = between(map, n, px, pz)
			if seen[n] ~= stamp or d < g[n] then
				seen[n], g[n], came[n] = stamp, d, 0
				size = push(map, size, n, d + between(map, n, qx, qz))
			end
		end
	end
	while size > 0 do
		local n, key
		n, key, size = pop(map, size)
		if key >= best then
			break
		end
		if closed[n] ~= stamp then
			closed[n] = stamp
			local gn = g[n]
			local at = map.nodePlace[n]
			if at == Q then
				local total = gn + between(map, n, qx, qz)
				if total < best then
					best, bestNode = total, n
				end
			end
			-- through the passage to its other end
			local m = if n % 2 == 1 then n + 1 else n - 1
			if closed[m] ~= stamp then
				local gm = gn + map.cost[(n + 1) // 2]
				if seen[m] ~= stamp or gm < g[m] then
					seen[m], g[m], came[m] = stamp, gm, n
					size = push(map, size, m, gm + between(map, m, qx, qz))
				end
			end
			-- across this place to its other passages
			local x, z = map.nodeX[n], map.nodeZ[n]
			for _, o in map.nodesOf[at] do
				if o ~= n and closed[o] ~= stamp and usable(map, o, mask) then
					local go = gn + between(map, o, x, z)
					if seen[o] ~= stamp or go < g[o] then
						seen[o], g[o], came[o] = stamp, go, n
						size = push(map, size, o, go + between(map, o, qx, qz))
					end
				end
			end
		end
	end
	return best, bestNode
end

-- Trips -------------------------------------------------------------------------------------------

-- A pathing's state: the map, the ability bits it walks with, and the waypoints `advance` works in.
type PathingState = {
	length: (self: any, from: vector, to: vector) -> number,
	advance: (self: any, from: vector, toward: vector, studs: number) -> vector,
	route: (self: any) -> Route,
	map: Map,
	mask: number,
	points: { vector },
	slows: { number },
}

-- A route's state: its pathing, its waypoints (at their places' heights), how far along them it
-- is, and what its plan was made for.
type RouteState = {
	advance: (self: any, from: vector, toward: vector, studs: number) -> vector,
	release: (self: any) -> (),
	pathing: PathingState,
	points: { vector },
	slows: { number }, -- each leg's slowness: 1 across a place, a passage's own across it
	count: number, -- waypoints planned; 0 with no way there
	at: number, -- the waypoint it is heading for
	here: vector, -- where it is, at its place's height
	lift: number, -- how far above its place's floor the traveller stands
	last: vector, -- where it last put the traveller
	goal: number, -- the place its destination was in
	goalOff: boolean, -- its destination was off the map
	version: number, -- the map's version it was planned on
	planned: boolean,
}

-- Writes the trip from `from` to `toward` into `points` and `slows`: each waypoint after `from`,
-- at its place's height, ending over `toward`. Returns how many (0 with no way there), the
-- trip's length, `from` brought down to its place's floor, and toward's place. Allocates nothing
-- once `points` and `slows` have grown to the trip.
local function plan(
	pathing: PathingState,
	from: vector,
	toward: vector,
	points: { vector },
	slows: { number }
): (number, number, vector, number, boolean)
	local map = pathing.map
	local P, px, pz, dp = locate(map, from)
	local Q, qx, qz, dq = locate(map, toward)
	local start = vector.create(from.x, map.y[P], from.z)
	if P == Q and px == qx and pz == qz then
		-- one point, or two meeting the map at one spot: straight there, as `length` measures it
		points[1], slows[1] = vector.create(toward.x, map.y[Q], toward.z), 1
		local dx, dz = toward.x - from.x, toward.z - from.z
		return 1, math.sqrt(dx * dx + dz * dz), start, Q, dq > 0
	end
	local total, last = search(map, pathing.mask, P, px, pz, Q, qx, qz)
	if total == math.huge then
		return 0, math.huge, start, Q, dq > 0
	end
	local count = 0
	if dp > 0 then
		count += 1
		points[count], slows[count] = vector.create(px, map.y[P], pz), 1
	end
	local chain, n = 0, last
	while n ~= 0 do
		chain += 1
		n = map.came[n]
	end
	n = last
	for i = count + chain, count + 1, -1 do
		local before = map.came[n]
		points[i] = vector.create(map.nodeX[n], map.nodeY[n], map.nodeZ[n])
		-- the leg into a passage's far end crosses the passage
		local crossed = before ~= 0 and (if before % 2 == 1 then before + 1 else before - 1) == n
		slows[i] = if crossed then map.slow[(n + 1) // 2] else 1
		n = before
	end
	count += chain
	if dq > 0 then
		count += 1
		points[count], slows[count] = vector.create(qx, map.y[Q], qz), 1
	end
	count += 1
	points[count], slows[count] = vector.create(toward.x, map.y[Q], toward.z), 1
	return count, total + dp + dq, start, Q, dq > 0
end

-- Moves `here` up to `studs` along the waypoints from `at`. Returns the waypoint it now heads for
-- (past the last once there) and where it is. Allocates nothing.
local function walk(
	points: { vector },
	slows: { number },
	count: number,
	at: number,
	here: vector,
	studs: number
): (number, vector)
	local left = studs
	while at <= count do
		local target = points[at]
		local d = vector.magnitude(target - here)
		local cost = d * slows[at]
		if cost <= left then
			left -= cost
			here = target
			at += 1
		else
			return at, here + (target - here) * (left / cost)
		end
	end
	return at, here
end

local function length(
	self: any,
	from: vector,
	to: vector
): number -- self: Brix's contract types it any
	local pathing = self :: PathingState
	local map = pathing.map
	local P, px, pz, dp = locate(map, from)
	local Q, qx, qz, dq = locate(map, to)
	if P == Q and px == qx and pz == qz then
		-- one point, or two that meet the map at one spot (off its edge, in line with it, or off
		-- the same corner): straight from one to the other
		local dx, dz = to.x - from.x, to.z - from.z
		return math.sqrt(dx * dx + dz * dz)
	end
	return search(map, pathing.mask, P, px, pz, Q, qx, qz) + dp + dq
end

local function advance(
	self: any,
	from: vector,
	toward: vector,
	studs: number
): vector -- self: Brix's contract types it any
	if not (studs > 0) then
		return from
	end
	local pathing = self :: PathingState
	local count, _, start = plan(pathing, from, toward, pathing.points, pathing.slows)
	if count == 0 then
		return from
	end
	local _, here = walk(pathing.points, pathing.slows, count, 1, start, studs)
	return vector.create(here.x, from.y + (here.y - start.y), here.z)
end

local function routeAdvance(
	self: any,
	from: vector,
	toward: vector,
	studs: number
): vector -- self: Brix's contract types it any
	if not (studs > 0) then
		return from
	end
	local route = self :: RouteState
	local pathing = route.pathing
	local map = pathing.map
	local Q = locate(map, toward)
	local moved = vector.magnitude(vector.create(from.x - route.last.x, 0, from.z - route.last.z))
		> SAME_SPOT
	if
		not route.planned
		or route.version ~= map.version
		or route.goal ~= Q
		or route.goalOff
		or moved
	then
		local count, _, start, goal, goalOff =
			plan(pathing, from, toward, route.points, route.slows)
		route.count, route.at, route.here, route.lift = count, 1, start, from.y - start.y
		route.goal, route.goalOff, route.version, route.planned = goal, goalOff, map.version, true
	elseif route.count > 0 then
		-- the destination moved within its place: the last waypoint follows it
		local last = route.points[route.count]
		route.points[route.count] = vector.create(toward.x, last.y, toward.z)
		if route.at > route.count then
			route.at = route.count
		end
	end
	if route.count == 0 then
		route.last = from
		return from
	end
	local at, here = walk(route.points, route.slows, route.count, route.at, route.here, studs)
	route.at, route.here = at, here
	local out = vector.create(here.x, here.y + route.lift, here.z)
	route.last = out
	return out
end

local function routeRelease(self: any) -- self: Brix's contract types it any
	local route = self :: RouteState
	route.planned = false
	route.count = 0
end

local function route(self: any): Route -- self: Brix's contract types it any
	local state: RouteState = {
		advance = routeAdvance,
		release = routeRelease,
		pathing = self :: PathingState,
		points = {},
		slows = {},
		count = 0,
		at = 1,
		here = vector.zero,
		lift = 0,
		last = vector.zero,
		goal = 0,
		goalOff = false,
		version = -1,
		planned = false,
	}
	return state
end

--- The map as one keeper walks it: a Brix Pathing that uses only the passages these abilities
--- open (none: walking only). Keepers with the same abilities share one.
function KeeperMap.pathing(map: Map, abilities: { Ability }?): Pathing
	local mask = 0
	if abilities then
		for _, a in abilities do
			mask = bit32.bor(mask, bitsOf(a))
		end
	end
	local cached = map.pathings[mask]
	if cached then
		return cached
	end
	local state: PathingState = {
		length = length,
		advance = advance,
		route = route,
		map = map,
		mask = mask,
		points = {},
		slows = {},
	}
	map.pathings[mask] = state
	return state
end

--- The waypoints of the trip a keeper with this pathing takes from one point to another, ending
--- over the destination, or nil with no way there. Allocates: for checks and for drawing a trip
--- in Studio, never a step.
function KeeperMap.trip(pathing: Pathing, from: vector, to: vector): { vector }?
	local state = pathing :: PathingState
	local points, slows = {}, {}
	local count = plan(state, from, to, points, slows)
	if count == 0 then
		return nil
	end
	return points
end

return table.freeze(KeeperMap)
