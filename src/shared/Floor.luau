--!strict
--[[
	Floor: one floor of the building as plain data, laid out from a seed (L-01a). Every climb is a
	new floor to learn, so friends replay for the layout as much as for the scare. L-01b lays this
	data in Studio with CorridorKit and UnitKit; nothing here touches an Instance, so Lune tests it
	(tests/floor.spec.luau).

	The floor is halls on CorridorKit's 24-stud grid. Junctions (corners, Ts and crosses) and the
	elevator lobby sit on every other grid point, 48 studs apart, so exactly one straight joins
	two of them (two junctions side by side would put two girders on one edge, D-023) and parallel
	halls stand 48 apart with room for both rows of units. A junction point with two arms in line
	is a plain straight; one with a single arm is a straight closed by a dead end. The halls grow
	as a tree from the lobby, so every hall is reachable, then a few loops join near halls (each
	one closing a dead end) so a chase has somewhere to go.

	Each hall side is a row of slots, every slot a unit or a plain wall: two M slots (12 wide) or
	three S slots (8 wide) along a straight; two M slots across a T from its stub; two S slots along
	each outer side of a corner, 8 deep so they stay under the corner's deck. Where two halls leave
	a junction side by side, their first slots meet in the back corner behind the junction's block
	of wall, under a 4-stud square where both halls' decks overlap: an M slot there is always a
	plain wall, and such a side is often three S units instead (an S slot is too shallow to reach
	it), so a hall between two junctions doesn't stand blank.

	Units are numbered for the floor (floor 2's are 201, 202, ...) in the order you meet them walking
	out from the lobby, the units across the hall from each other back to back, the one on your
	left first. Every hall piece has a motion light over its middle: one every 24 studs of hall and
	one over each junction, so no stretch goes unwatched. Each light sits in a power zone for the
	breaker room to cut: the halls from the lobby to the first fork are "Lobby", and each wing past
	that fork is "A", "B", "C".

	Coordinates are studs on the floor, the lobby's middle at the origin; the floor spreads toward
	-Z and the elevator stands behind the lobby, toward +Z. A Dir is a side or a way along the floor:
	0 is +X, 1 is +Z, 2 is -X, 3 is -Z. A piece's turn is the Dir its frame's X points along, the
	way CorridorKit lays it: CFrame.fromMatrix(Vector3.new(x, 0, z), Vector3.new(dx, 0, dz),
	Vector3.yAxis), with (dx, dz) = Floor.dir(turn). A junction turned so turns its kit Arms
	(Specs.Junctions.<name>.Arms) onto its halls.
]]

-- The kit's and the units' sizes, in studs. tests/floor.spec checks them against the generated
-- specs (CorridorKit/Specs, StorageUnit/Specs), which build Roblox values and can't load here.
local CELL = 24 -- a straight's length, a junction's square: the floor's grid
local HALL = 8 -- door face to door face
local SPAN = 32 -- a straight's deck across: the hall and a row of M units each side

local Floor = {}
Floor.Cell = CELL
Floor.HallWidth = HALL
Floor.Span = SPAN

export type Size = "S" | "M"
-- A unit's footprint, door face to back wall and wall to wall (art/unit/spec.py; L doesn't fit a
-- hall's span, ROADMAP).
Floor.Sizes = {
	S = { width = 8, depth = 8 },
	M = { width = 12, depth = 12 },
} :: { [Size]: { width: number, depth: number } }

-- The lobby's floor is one junction square; the freight elevator stands behind it, its car this
-- deep (L-05 builds both, so these hold the room for them).
Floor.LobbySize = CELL
Floor.ElevatorDepth = CELL

--[[
	A floor plan: how big a floor is and how it reads. Each number changes what the climb feels like,
	so they live here with what they do. Floors 1 and 2 are short (GDD "The building": two notes,
	about 3 minutes); from floor 3 they're full size (four notes, 4 to 6 minutes).
]]
export type Plan = {
	columns: number, -- junction points across (odd: the lobby takes the middle one)
	rows: number, -- junction points deep, the lobby's row included
	straights: number, -- the tree's halls, 24 studs each: how far the floor sprawls
	loops: number, -- extra halls joining near ones: each turns a dead end into a way round
	keepOn: number, -- 0 to 1: how often a hall carries on straight rather than turning (long aisles)
	smallRows: number, -- 0 to 1: how often a straight's side is three S units, not two M
	plainWalls: number, -- 0 to 1: how often a slot is a plain wall: the rhythm of doors down a hall
}

Floor.Plans = {
	-- Floors 1 and 2 teach lights and doors: a few halls, a loop, a dead end or two to get caught in.
	Short = {
		columns = 5,
		rows = 3,
		straights = 8,
		loops = 1,
		keepOn = 0.6,
		smallRows = 0.25,
		plainWalls = 0.08,
	} :: Plan,
	-- Floors 3 and up: half as many halls again and a second loop, so four notes take searching
	-- for and a chase has room. About 80 units (60 to 99); the short plan about 60.
	Full = {
		columns = 5,
		rows = 4,
		straights = 11,
		loops = 2,
		keepOn = 0.6,
		smallRows = 0.25,
		plainWalls = 0.08,
	} :: Plan,
}

-- How often the tree grows from its newest hall rather than one picked at random: high gives long
-- winding halls, low gives many short stubs.
local GROW_NEWEST = 0.5

-- How often a hall side with a back corner (see above) is three S units rather than two M with
-- the corner's one a plain wall: between two junctions both ends can be back corners, and a side
-- of M slots there would be all wall.
local BACK_CORNER_SMALL = 0.5

-- A unit's number is its floor's followed by two digits (floor 2: 201 to 299), so a floor holds
-- at most this many units.
Floor.MaxUnits = 99

-- Each floor's doors wear one of the four colours (UnitKit.Colours.Door), in turn from floor 1, so
-- the floor you're on has a colour you can name ("the teal floor").
Floor.Paints = { "Oxblood", "Teal", "Mustard", "Navy" }

export type Kind = "Straight" | "Corner" | "T" | "Cross" | "Lobby"

-- A hall piece: a straight, a junction or the lobby, at its frame.
export type Cell = {
	kind: Kind,
	x: number, -- the middle of its floor
	z: number,
	gx: number, -- its grid point (x / 24, z / 24)
	gz: number,
	turn: number, -- the Dir its frame's X points along
	arms: { boolean }, -- arms[d + 1]: a hall leaves through side d
	deadEnd: boolean, -- a straight closed at one end
	zone: string, -- the power zone of the light over it
}

-- A slot along a hall: a unit, or a plain wall where none stands.
export type Slot = {
	kind: "Unit" | "Wall",
	size: Size,
	x: number, -- the middle of its hall face, on the floor (a door's outer face, a wall's frame)
	z: number,
	facing: number, -- the Dir its face looks into the hall
	cell: number, -- the hall piece it lines, an index into cells
	number: string?, -- a unit's number, "214"
	drops: { number }, -- the side walls a unit leaves out, as Dirs: its neighbour already stands them
}

-- A motion light over a hall piece's middle, its hall along `turn`.
export type Fixture = { x: number, z: number, turn: number, zone: string, cell: number }

-- A dead end's wall: the middle of its hall face, on the floor, looking down the hall.
export type DeadEnd = { x: number, z: number, facing: number, cell: number }

export type Floor = {
	number: number,
	paint: string, -- the doors' colour, a key of UnitKit.Colours.Door
	plan: Plan,
	cells: { Cell },
	slots: { Slot },
	fixtures: { Fixture },
	deadEnds: { DeadEnd },
	lobby: number, -- the lobby's index in cells
}

-- Brix's Random contract (Brix.Random.new({ seed = n }) makes one); typed here so this module
-- stays free of Roblox paths. any: the contract types its methods' self that way.
export type Random = {
	nextNumber: (self: any) -> number,
	nextInteger: (self: any, min: number, max: number) -> number,
}

-- The way Dir `d` points across the floor.
function Floor.dir(d: number): (number, number)
	d %= 4
	return if d == 0 then 1 elseif d == 2 then -1 else 0,
		if d == 1 then 1 elseif d == 3 then -1 else 0
end
local dir = Floor.dir

-- The plan for floor `number`.
function Floor.planFor(number: number): Plan
	return if number <= 2 then Floor.Plans.Short else Floor.Plans.Full
end

-- A slot's footprint on the floor: minX, maxX, minZ, maxZ (a plain wall's is the slot it fills).
function Floor.footprint(slot: Slot): (number, number, number, number)
	local size = Floor.Sizes[slot.size]
	local fx, fz = dir(slot.facing)
	-- the footprint runs back from the face, away from the hall
	local bx, bz = slot.x - fx * size.depth, slot.z - fz * size.depth
	local hw = size.width / 2
	if fx ~= 0 then
		return math.min(slot.x, bx), math.max(slot.x, bx), slot.z - hw, slot.z + hw
	end
	return slot.x - hw, slot.x + hw, math.min(slot.z, bz), math.max(slot.z, bz)
end

-- The slots a junction lines, in its own frame (hall along X): where each face's middle sits, the
-- local Dir it faces, its size. The rest of a junction's walls are its blocks of wall, which the
-- kit always stands. These match the kit's junction walls (Specs.Junctions; the spec checks).
type LocalSlot = { x: number, z: number, facing: number, size: Size }
local JUNCTION_SLOTS: { [string]: { LocalSlot } } = {
	-- the outer side of the turn: two S slots along each closed side
	Corner = {
		{ x = 8, z = -4, facing = 1, size = "S" },
		{ x = 0, z = -4, facing = 1, size = "S" },
		{ x = -4, z = 0, facing = 0, size = "S" },
		{ x = -4, z = 8, facing = 0, size = "S" },
	},
	-- across from the stub: two M slots
	T = {
		{ x = 6, z = -4, facing = 1, size = "M" },
		{ x = -6, z = -4, facing = 1, size = "M" },
	},
	Cross = {},
}
-- L-01b reads these to leave out the kit's wall where a unit stands instead.
Floor.JunctionSlots = JUNCTION_SLOTS

-- Along a straight's side, where each slot's face middle sits, from the piece's middle.
local ROW: { [Size]: { number } } = { M = { -6, 6 }, S = { -8, 0, 8 } }

-- A local frame's point (lx, lz) and Dir k, turned `turn` and put at (x, z).
local function toWorld(x: number, z: number, turn: number, lx: number, lz: number): (number, number)
	local ax, az = dir(turn)
	local bx, bz = dir(turn + 1)
	return x + lx * ax + lz * bx, z + lx * az + lz * bz
end

local function count(arms: { boolean }): number
	local n = 0
	for _, a in arms do
		if a then
			n += 1
		end
	end
	return n
end

-- The kind of hall piece a junction point is, from its arms, and the turn that fits the kit's.
local function shapeOf(arms: { boolean }): (Kind, number, boolean)
	local n = count(arms)
	if n == 1 then
		for d = 0, 3 do
			if arms[d + 1] then
				return "Straight", d % 2, true
			end
		end
	elseif n == 2 then
		for d = 0, 3 do
			if arms[d + 1] and arms[(d + 1) % 4 + 1] then
				-- the kit's corner leaves along its X and Z: Dirs turn and turn + 1
				return "Corner", d, false
			end
		end
		return "Straight", if arms[1] then 0 else 1, false
	elseif n == 3 then
		for d = 0, 3 do
			if not arms[d + 1] then
				-- the kit's T has no arm on its -Z (local Dir 3), so its turn is the missing Dir + 1
				return "T", (d + 1) % 4, false
			end
		end
	end
	return "Cross", 0, false
end

local function key(gx: number, gz: number): number
	return gx * 4096 + gz
end

--[[
	Lays out floor `number` with choices drawn from `random`: the same seed gives the same floor,
	under Lune and in Roblox alike. Errors if the plan can't fit its halls on its grid.
]]
function Floor.generate(number: number, random: Random): Floor
	local plan = Floor.planFor(number)
	local half = (plan.columns - 1) // 2
	assert(
		plan.straights <= plan.columns * plan.rows - 1,
		"Floor: more halls than the grid has room for"
	)

	-- 1. The halls, as links between junction points (i across, j deep; the lobby at 0, 0).
	local points: { [number]: { boolean } } = {}
	local pointOrder: { { i: number, j: number } } = {}
	local function addPoint(i: number, j: number)
		points[key(i, j)] = { false, false, false, false }
		table.insert(pointOrder, { i = i, j = j })
	end
	local function inGrid(i: number, j: number): boolean
		return i >= -half and i <= half and j >= 0 and j < plan.rows
	end
	-- a junction point's neighbour across Dir d: deeper rows lie toward -Z
	local function step(i: number, j: number, d: number): (number, number)
		local sx, sz = dir(d)
		return i + sx, j - sz
	end
	local links = 0
	local function link(i: number, j: number, d: number)
		local ni, nj = step(i, j, d)
		points[key(i, j)][d + 1] = true
		points[key(ni, nj)][(d + 2) % 4 + 1] = true
		links += 1
	end

	addPoint(0, 0) -- the lobby: one hall, straight into the floor
	addPoint(0, 1)
	link(0, 0, 3)
	type Growing = { i: number, j: number, came: number }
	local growing: { Growing } = { { i = 0, j = 1, came = 3 } }
	while links < plan.straights and #growing > 0 do
		local pick = if random:nextNumber() < GROW_NEWEST
			then #growing
			else random:nextInteger(1, #growing)
		local from = growing[pick]
		local open = {}
		for d = 0, 3 do
			local ni, nj = step(from.i, from.j, d)
			if inGrid(ni, nj) and points[key(ni, nj)] == nil then
				table.insert(open, d)
			end
		end
		if #open == 0 then
			table.remove(growing, pick)
			continue
		end
		local d = open[random:nextInteger(1, #open)]
		if table.find(open, from.came) and random:nextNumber() < plan.keepOn then
			d = from.came
		end
		local ni, nj = step(from.i, from.j, d)
		addPoint(ni, nj)
		link(from.i, from.j, d)
		table.insert(growing, { i = ni, j = nj, came = d })
	end
	assert(links == plan.straights, "Floor: the grid ran out of room for the plan's halls")

	-- The loops: each joins two near halls not yet joined, a dead end first where one can be.
	for _ = 1, plan.loops do
		local candidates, fromDeadEnds = {}, {}
		for _, p in pointOrder do
			if p.i == 0 and p.j == 0 then
				continue -- the lobby keeps its one hall
			end
			local arms = points[key(p.i, p.j)]
			for d = 0, 3 do
				local ni, nj = step(p.i, p.j, d)
				local other = points[key(ni, nj)]
				-- each pair once: from the point whose neighbour lies at +X or deeper
				if
					(d == 0 or d == 3)
					and other
					and not arms[d + 1]
					and not (ni == 0 and nj == 0)
				then
					local option = { i = p.i, j = p.j, d = d }
					table.insert(candidates, option)
					if count(arms) == 1 or count(other) == 1 then
						table.insert(fromDeadEnds, option)
					end
				end
			end
		end
		local pool = if #fromDeadEnds > 0 then fromDeadEnds else candidates
		if #pool == 0 then
			break
		end
		local chosen = pool[random:nextInteger(1, #pool)]
		link(chosen.i, chosen.j, chosen.d)
	end

	-- 2. The hall pieces: every junction point, and a straight on every link between two.
	local cells: { Cell } = {}
	local at: { [number]: number } = {}
	local function addCell(
		kind: Kind,
		gx: number,
		gz: number,
		turn: number,
		arms: { boolean },
		deadEnd: boolean
	)
		table.insert(cells, {
			kind = kind,
			x = gx * CELL,
			z = gz * CELL,
			gx = gx,
			gz = gz,
			turn = turn,
			arms = arms,
			deadEnd = deadEnd,
			zone = "Lobby",
		})
		at[key(gx, gz)] = #cells
	end
	for _, p in pointOrder do
		local arms = points[key(p.i, p.j)]
		local gx, gz = p.i * 2, 0 - p.j * 2 -- (0 - keeps the lobby row at 0, not -0)
		if p.i == 0 and p.j == 0 then
			addCell("Lobby", gx, gz, 3, arms, false)
		else
			local kind, turn, deadEnd = shapeOf(arms)
			addCell(kind :: Kind, gx, gz, turn, arms, deadEnd)
		end
		for _, d in { 0, 3 } do
			if arms[d + 1] then
				local sx, sz = dir(d)
				local both = { false, false, false, false }
				both[d + 1], both[(d + 2) % 4 + 1] = true, true
				addCell("Straight", gx + sx, gz + sz, d % 2, both, false)
			end
		end
	end
	local function neighbour(c: Cell, d: number): Cell?
		local sx, sz = dir(d)
		local index = at[key(c.gx + sx, c.gz + sz)]
		return if index then cells[index] else nil
	end

	-- 3. The slots along every hall side, units or plain walls.
	local slots: { Slot } = {}
	local function addSlot(
		cell: number,
		size: Size,
		x: number,
		z: number,
		facing: number,
		wall: boolean
	)
		table.insert(slots, {
			kind = if wall or random:nextNumber() < plan.plainWalls then "Wall" else "Unit",
			size = size,
			x = x,
			z = z,
			facing = facing % 4,
			cell = cell,
			drops = {},
		})
	end
	for index, c in cells do
		if c.kind == "Straight" then
			local ax, az = dir(c.turn)
			for _, side in { c.turn + 1, c.turn + 3 } do
				side %= 4
				-- a back corner: another hall leaves the junction at this end on this side, so an M
				-- slot here would reach under the two halls' overlapping decks
				local function backCornerAt(toward: number): boolean
					local junction = neighbour(c, toward)
					return junction ~= nil and junction.arms[side + 1]
				end
				local corners = backCornerAt(c.turn) or backCornerAt(c.turn + 2)
				local small = if corners then BACK_CORNER_SMALL else plan.smallRows
				local size: Size = if random:nextNumber() < small then "S" else "M"
				local sx, sz = dir(side)
				for _, along in ROW[size] do
					local backCorner = size == "M"
						and backCornerAt(if along > 0 then c.turn else c.turn + 2)
					local x = c.x + along * ax + (HALL / 2) * sx
					local z = c.z + along * az + (HALL / 2) * sz
					addSlot(index, size, x, z, side + 2, backCorner)
				end
			end
		elseif c.kind ~= "Lobby" then
			for _, s in JUNCTION_SLOTS[c.kind] do
				local x, z = toWorld(c.x, c.z, c.turn, s.x, s.z)
				addSlot(index, s.size, x, z, s.facing + c.turn, false)
			end
		end
	end
	-- A floor's numbers have two digits after the floor's (MAX_UNITS): past that, units picked at
	-- random become plain walls. The plans keep this rare (tests/floor.spec counts).
	local units = {}
	for i, s in slots do
		if s.kind == "Unit" then
			table.insert(units, i)
		end
	end
	while #units > Floor.MaxUnits do
		local cut = table.remove(units, random:nextInteger(1, #units)) :: number
		slots[cut].kind = "Wall"
	end

	-- 4. The dead ends and the lights.
	local deadEnds: { DeadEnd } = {}
	local fixtures: { Fixture } = {}
	for index, c in cells do
		if c.deadEnd then
			for d = 0, 3 do
				if c.arms[d + 1] then
					local fx, fz = dir(d + 2)
					table.insert(deadEnds, {
						x = c.x + fx * CELL / 2,
						z = c.z + fz * CELL / 2,
						facing = d,
						cell = index,
					})
				end
			end
		end
		if c.kind ~= "Lobby" then
			table.insert(
				fixtures,
				{ x = c.x, z = c.z, turn = c.turn, zone = "Lobby", cell = index }
			)
		end
	end

	-- 5. Walk out from the lobby: number the units as you meet them, and zone the lights.
	local lobby = at[key(0, 0)]
	local slotsOf: { { number } } = {}
	for i in cells do
		slotsOf[i] = {}
	end
	for i, s in slots do
		table.insert(slotsOf[s.cell], i)
	end
	-- the ways on from a piece, walking `walk`: left, ahead, right
	local function waysOn(c: Cell, walk: number): { number }
		local ways = {}
		for _, d in { walk + 3, walk, walk + 1 } do
			if c.arms[d % 4 + 1] then
				table.insert(ways, d % 4)
			end
		end
		return ways
	end
	local nextNumber = 1
	local visited: { [number]: boolean } = {}
	local function walkFrom(index: number, walk: number)
		visited[index] = true
		local c = cells[index]
		local wx, wz = dir(walk)
		local lx, lz = dir(walk + 3)
		local here = table.clone(slotsOf[index])
		-- nearer first; across from each other, your left first
		table.sort(here, function(a, b)
			local sa, sb = slots[a], slots[b]
			local da = (sa.x - c.x) * wx + (sa.z - c.z) * wz
			local db = (sb.x - c.x) * wx + (sb.z - c.z) * wz
			if math.abs(da - db) > 0.01 then
				return da < db
			end
			return (sa.x - c.x) * lx + (sa.z - c.z) * lz > (sb.x - c.x) * lx + (sb.z - c.z) * lz
		end)
		for _, i in here do
			if slots[i].kind == "Unit" then
				slots[i].number = string.format("%d%02d", number, nextNumber)
				nextNumber += 1
			end
		end
		for _, d in waysOn(c, walk) do
			local n = neighbour(c, d)
			local ni = n and at[key(n.gx, n.gz)]
			if ni and not visited[ni] then
				walkFrom(ni, d)
			end
		end
	end
	walkFrom(lobby, 3)

	-- The zones: from the lobby to the first fork is "Lobby"; past it, each way on is a wing.
	local zoneOf: { [number]: string } = {}
	local index, walk = lobby, 3
	while true do
		zoneOf[index] = "Lobby"
		local c = cells[index]
		local ways = waysOn(c, walk)
		if c.kind ~= "Lobby" and #ways ~= 1 then
			break
		end
		local n = neighbour(c, ways[1])
		if not n then
			break
		end
		index, walk = at[key(n.gx, n.gz)], ways[1]
	end
	local queue: { number } = {}
	local fork = cells[index]
	for w, d in waysOn(fork, walk) do
		local n = neighbour(fork, d)
		local ni = n and at[key(n.gx, n.gz)]
		if ni and not zoneOf[ni] then
			zoneOf[ni] = string.char(64 + w)
			table.insert(queue, ni)
		end
	end
	local head = 1
	while head <= #queue do
		local ci = queue[head]
		head += 1
		for d = 0, 3 do
			local n = if cells[ci].arms[d + 1] then neighbour(cells[ci], d) else nil
			local ni = n and at[key(n.gx, n.gz)]
			if ni and not zoneOf[ni] then
				zoneOf[ni] = zoneOf[ci]
				table.insert(queue, ni)
			end
		end
	end
	for i, c in cells do
		c.zone = zoneOf[i] or "Lobby"
	end
	for _, f in fixtures do
		f.zone = cells[f.cell].zone
	end

	-- 6. Shared walls: of two units side by side in one row, the shallower (or the later) leaves out
	-- the wall between them, so the two never stand one in the same place.
	for i, a in slots do
		for j = i + 1, #slots do
			local b = slots[j]
			if a.kind == "Unit" and b.kind == "Unit" and a.facing == b.facing then
				local ax, az = dir(a.facing + 1) -- along the row
				local fx, fz = dir(a.facing)
				local apart = (b.x - a.x) * ax + (b.z - a.z) * az
				local off = (b.x - a.x) * fx + (b.z - a.z) * fz
				local reach = (Floor.Sizes[a.size].width + Floor.Sizes[b.size].width) / 2
				if math.abs(off) < 0.01 and math.abs(math.abs(apart) - reach) < 0.01 then
					local da, db = Floor.Sizes[a.size].depth, Floor.Sizes[b.size].depth
					local aDrops = da < db
						or (da == db and (a.number :: string) > (b.number :: string))
					local towardB = if apart > 0 then a.facing + 1 else a.facing + 3
					if aDrops then
						table.insert(a.drops, towardB % 4)
					else
						table.insert(b.drops, (towardB + 2) % 4)
					end
				end
			end
		end
	end

	return {
		number = number,
		paint = Floor.Paints[(number - 1) % #Floor.Paints + 1],
		plan = plan,
		cells = cells,
		slots = slots,
		fixtures = fixtures,
		deadEnds = deadEnds,
		lobby = lobby,
	}
end

--[[
	The floor as a small text map, seen from above (+X to the right, +Z down the page), 4 studs a
	column and 8 a line: for the owner to judge a layout, and for Output while L-01b lays one.
]]
function Floor.map(floor: Floor): string
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, c in floor.cells do
		minX, maxX = math.min(minX, c.x - SPAN / 2), math.max(maxX, c.x + SPAN / 2)
		minZ, maxZ = math.min(minZ, c.z - SPAN / 2), math.max(maxZ, c.z + SPAN / 2)
	end
	maxZ = math.max(maxZ, Floor.LobbySize / 2 + Floor.ElevatorDepth)
	minZ = math.floor(minZ / 8) * 8
	local cols = math.ceil((maxX - minX) / 4)
	local rows = math.ceil((maxZ - minZ) / 8) + 1
	local grid: { { string } } = {}
	for r = 1, rows do
		grid[r] = table.create(cols, " ")
	end
	-- a character's sample point: the middle of its 4 studs across, and its line's z, a multiple
	-- of 8 studs, which never falls on a piece's or a unit's edge (those sit 4 off one)
	local function fill(x0: number, x1: number, z0: number, z1: number, ch: string)
		for r = 1, rows do
			local z = minZ + (r - 1) * 8
			if z > z0 and z < z1 then
				for col = 1, cols do
					local x = minX + (col - 1) * 4 + 2
					if x >= x0 and x < x1 then
						grid[r][col] = ch
					end
				end
			end
		end
	end
	local function mark(x: number, z: number, ch: string)
		local col = math.clamp(math.floor((x - minX) / 4) + 1, 1, cols)
		local r = math.clamp(math.floor((z - minZ) / 8 + 0.5) + 1, 1, rows)
		grid[r][col] = ch
	end

	for _, c in floor.cells do
		local h = CELL / 2
		if c.kind == "Lobby" then
			fill(c.x - h, c.x + h, c.z - h, c.z + h, "L")
			fill(c.x - h, c.x + h, c.z + h, c.z + h + Floor.ElevatorDepth, "E")
		elseif c.kind == "Straight" then
			local hx = if c.turn == 0 then h else HALL / 2
			local hz = if c.turn == 0 then HALL / 2 else h
			fill(c.x - hx, c.x + hx, c.z - hz, c.z + hz, ".")
		else
			fill(c.x - HALL / 2, c.x + HALL / 2, c.z - HALL / 2, c.z + HALL / 2, "+")
			for d = 0, 3 do
				if c.arms[d + 1] then
					local sx, sz = dir(d)
					local cx, cz = c.x + sx * (HALL / 2 + 4), c.z + sz * (HALL / 2 + 4)
					local hx = if sx ~= 0 then 4 else HALL / 2
					local hz = if sz ~= 0 then 4 else HALL / 2
					fill(cx - hx, cx + hx, cz - hz, cz + hz, "+")
				end
			end
		end
	end
	for _, s in floor.slots do
		local x0, x1, z0, z1 = Floor.footprint(s)
		if s.kind == "Wall" then
			-- a plain wall is its face: the first character behind it
			local fx, fz = dir(s.facing)
			local bx, bz = s.x - fx * 4, s.z - fz * 8
			if fx ~= 0 then
				fill(math.min(s.x, bx), math.max(s.x, bx), z0, z1, "#")
			else
				fill(x0, x1, math.min(s.z, bz), math.max(s.z, bz), "#")
			end
		else
			-- neighbours alternate case so each unit reads on its own
			local ax, az = dir(s.facing + 1)
			local along = s.x * math.abs(ax) + s.z * math.abs(az)
			local k = math.floor(along / Floor.Sizes[s.size].width)
			fill(x0, x1, z0, z1, if k % 2 == 0 then s.size else string.lower(s.size))
		end
	end
	for _, e in floor.deadEnds do
		local fx, fz = dir(e.facing)
		mark(e.x - fx * 2, e.z - fz * 4, if fx ~= 0 then "|" else "-")
	end
	for _, f in floor.fixtures do
		mark(f.x, f.z, "*")
	end

	local lines = {}
	for r = 1, rows do
		lines[r] = (string.gsub(table.concat(grid[r]), "%s+$", ""))
	end
	return table.concat(lines, "\n")
end

return Floor
