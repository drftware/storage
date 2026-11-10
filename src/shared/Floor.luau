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
-- hall's span, ROADMAP), and its door's opening across: a keeper sees into a unit only through
-- that, never through the posts either side.
Floor.Sizes = {
	S = { width = 8, depth = 8, door = 6 },
	M = { width = 12, depth = 12, door = 8 },
} :: { [Size]: { width: number, depth: number, door: number } }

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
	-- The hall from the lobby to the first fork teaches the hole trap (GDD: floors 1 and 2): no
	-- plain walls there but the ones a back corner needs, and a back-cornered side three small
	-- units, so the first doors you meet stand side by side, neighbours to saw between.
	teachHoles: boolean,
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
		teachHoles = true,
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
		teachHoles = false,
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
	-- What stands past each of its walls, as an index into slots: a unit or a plain wall's slot that
	-- shares at least a crawl hole's stretch of that wall, or nil where nothing does (a junction's
	-- block of wall, the gap behind a row, a dead end). Left and right as you see them from the
	-- hall, facing the door (Floor.sideDir).
	left: number?,
	right: number?,
	back: number?,
	top: boolean, -- closed on top: a unit's steel top, or a plain wall's lid in a run with units
	run: number?, -- the top run it's part of, an index into runs
}

-- A top run: slots side by side in one row, every one closed on top, so a friend up a ladder can
-- run its length while a keeper below loses them (GDD Tools, the ladder). In order along the
-- row, each slot the one on the previous one's left. A run ends at a junction's lid (and goes on
-- round the corner across it), a dead end or the lobby; panels close its back and any other drop.
export type Run = {
	slots: { number },
	length: number, -- studs along the row
	units: number, -- how many of its slots are units
	lids: { number }, -- the junction lids it reaches, indices into lids: the way round a corner
}

--[[
	A lid over one of a junction's hollow squares: the 8-by-8 block of wall between two of its
	halls, or a corner's outside square behind both its rows. The junction floors it and walls or
	units close it, so a friend who stepped off a run's end into it could never climb out; an S
	unit's steel top over it carries the run round the corner instead. Every such square a run
	reaches gets one. Its frame is a slot's: the middle of one side, looking out of the square,
	which runs back from it an S unit's depth.
]]
export type Lid = {
	x: number,
	z: number,
	facing: number,
	size: Size, -- always S: the square is an S unit's footprint, so its steel top fits
	cell: number, -- the junction it's in, an index into cells
	runs: { number }, -- the top runs that reach it, indices into runs
}

--[[
	A panel that closes the tops up to the deck wherever stepping off them would drop you into
	nothing or into a pit: a row's back over the gap behind it, a deep unit's side beside a shallow
	one's back, a run's end beside the lobby, a lid's side over an empty slot. It is the plain
	wall's panel above its cap, an M's or an S's width; where only 4 studs are open it reaches 4
	on past them into the dark behind the tops, where nobody sees it. Where the tops have no wall
	of their own under it (a plain wall's lid, a junction's square), it turns its bare sheet to
	them, down to the floor, as a plain wall does to the empty slot behind it: looking down
	past the tops' edges shows a wall, not the sky under the building. Its frame is a wall's: the
	middle of its face, on the floor, looking into the tops it closes.
]]
export type Panel = {
	x: number,
	z: number,
	facing: number,
	size: Size,
	bare: boolean, -- its bare sheet to the tops, down to the floor: they have no wall of their own
	cell: number, -- the hall piece whose slot or lid it closes, laid with it
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
	runs: { Run },
	lids: { Lid },
	panels: { Panel },
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

-- Anything laid out from a face like a unit: a slot, a junction's lid.
export type Placed = { x: number, z: number, facing: number, size: Size }

-- A slot's footprint on the floor: minX, maxX, minZ, maxZ (a plain wall's is the slot it fills;
-- a lid's the square it covers).
function Floor.footprint(slot: Placed): (number, number, number, number)
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

-- The least stretch of wall two slots must share for a crawl hole between them: the saw's hole is
-- about 3 studs wide and needs a stud of wall each side of it.
Floor.CrawlWidth = 4

export type Side = "left" | "right" | "back"

-- The Dir a slot's wall on `side` faces outward, as you see it from the hall facing the door.
function Floor.sideDir(slot: Slot, side: Side): number
	return (slot.facing + (if side == "left" then 1 elseif side == "right" then 3 else 2)) % 4
end

-- How long a stretch of slot a's wall on Dir d slot b's footprint shares (0 if none). Footprints
-- are given as { minX, maxX, minZ, maxZ }.
local function sharedWall(a: { number }, b: { number }, d: number): number
	local line, other, lo, hi
	if d % 2 == 0 then
		line, other = if d == 0 then a[2] else a[1], if d == 0 then b[1] else b[2]
		lo, hi = math.max(a[3], b[3]), math.min(a[4], b[4])
	else
		line, other = if d == 1 then a[4] else a[3], if d == 1 then b[3] else b[4]
		lo, hi = math.max(a[1], b[1]), math.min(a[2], b[2])
	end
	return if math.abs(line - other) < 0.01 then math.max(0, hi - lo) else 0
end

-- Fills in what stands past each slot's walls (left, right, back), from the footprints alone.
local function findNeighbours(slots: { Slot })
	local rects = {}
	for i, s in slots do
		rects[i] = { Floor.footprint(s) }
	end
	local function across(i: number, d: number): number?
		local best, longest = nil, Floor.CrawlWidth - 0.01
		for j in slots do
			if j ~= i then
				local length = sharedWall(rects[i], rects[j], d)
				if length > longest then
					best, longest = j, length
				end
			end
		end
		return best
	end
	for i, s in slots do
		s.left = across(i, Floor.sideDir(s, "left"))
		s.right = across(i, Floor.sideDir(s, "right"))
		s.back = across(i, Floor.sideDir(s, "back"))
	end
end

--[[
	Finds the floor's top runs and closes their tops. A run is a row's slots linked side by side;
	every plain wall in a run that has a unit gets a lid, so a friend running the tops never drops
	into the empty slot behind it.
]]
local function findRuns(slots: { Slot }): { Run }
	-- the next slot along the row on the left: the same row (facing the same way), each the other's
	local function leftInRow(i: number): number?
		local j = slots[i].left
		if j and slots[j].facing == slots[i].facing and slots[j].right == i then
			return j
		end
		return nil
	end
	local rightOf: { [number]: boolean } = {}
	for i in slots do
		local j = leftInRow(i)
		if j then
			rightOf[j] = true
		end
	end
	local runs: { Run } = {}
	for i in slots do
		if rightOf[i] then
			continue -- not a row's right-hand end
		end
		local run: Run = { slots = {}, length = 0, units = 0, lids = {} }
		local at: number? = i
		while at do
			table.insert(run.slots, at)
			run.length += Floor.Sizes[slots[at].size].width
			if slots[at].kind == "Unit" then
				run.units += 1
			end
			at = leftInRow(at)
		end
		if run.units > 0 then
			table.insert(runs, run)
			for _, j in run.slots do
				slots[j].top = true
				slots[j].run = #runs
			end
		end
	end
	return runs
end

local JUNCTIONS: { [Kind]: boolean } = { Corner = true, T = true, Cross = true }

-- The middle of the square a junction leaves between Dirs a and a + 1 from its middle: 8 studs out
-- along each, past the hall's half width.
local function quadrant(c: Cell, a: number): (number, number)
	local ax, az = dir(a)
	local bx, bz = dir(a + 1)
	return c.x + 8 * (ax + bx), c.z + 8 * (az + bz)
end

--[[
	Lids every junction square a run reaches (Lid) and tells each run which lids it reaches. Of a
	junction's four corner squares, those a slot stands in are the slot's; the rest are its blocks
	of wall and a corner's outside square.
]]
local function findLids(cells: { Cell }, slots: { Slot }, runs: { Run }): { Lid }
	local rects = {}
	for i, s in slots do
		rects[i] = { Floor.footprint(s) }
	end
	local lids: { Lid } = {}
	for ci, c in cells do
		if not JUNCTIONS[c.kind] then
			continue
		end
		for a = 0, 3 do
			local mx, mz = quadrant(c, a)
			local square = { mx - 4, mx + 4, mz - 4, mz + 4 }
			local taken = false
			local reached: { number } = {}
			for i, s in slots do
				local r = rects[i]
				if
					r[1] < square[2]
					and r[2] > square[1]
					and r[3] < square[4]
					and r[4] > square[3]
				then
					taken = true
					break
				end
				local run = s.run
				if run and not table.find(reached, run) then
					for d = 0, 3 do
						if sharedWall(square, r, d) > 0 then
							table.insert(reached, run)
							break
						end
					end
				end
			end
			if taken or #reached == 0 then
				continue
			end
			table.sort(reached)
			-- its frame on the side toward the junction's middle, where a block's kit wall stands
			local ax, az = dir(a)
			table.insert(lids, {
				x = mx - 4 * ax,
				z = mz - 4 * az,
				facing = (a + 2) % 4,
				size = "S",
				cell = ci,
				runs = reached,
			})
			for _, r in reached do
				table.insert(runs[r].lids, #lids)
			end
		end
	end
	return lids
end

-- Every hall, slot and square edge on a floor lies on a multiple of this many studs.
local GRID = 4

--[[
	Finds where the tops (the top runs' slots and the lids) would drop a friend into nothing or into
	a pit, and closes each stretch with a panel (Panel). Stepping off a unit's front into the hall
	is the way down, and a junction's walls, a dead end and the lobby already reach the deck; every
	other edge of the tops needs one.
]]
local function findPanels(
	cells: { Cell },
	slots: { Slot },
	lids: { Lid },
	deadEnds: { DeadEnd }
): { Panel }
	-- each 4-stud square of the floor: on the tops, in a hall (or the lobby), or nil: anywhere else
	local ON_TOP, IN_HALL = 1, 2
	local grid: { [number]: number } = {}
	local function fill(x0: number, x1: number, z0: number, z1: number, value: number)
		for gx = x0 // GRID, x1 // GRID - 1 do
			for gz = z0 // GRID, z1 // GRID - 1 do
				grid[key(gx, gz)] = value
			end
		end
	end
	for _, c in cells do
		local h = CELL / 2
		if c.kind == "Lobby" then
			fill(c.x - h, c.x + h, c.z - h, c.z + h, IN_HALL)
		elseif c.kind == "Straight" then
			local hx = if c.turn % 2 == 0 then h else HALL / 2
			local hz = if c.turn % 2 == 0 then HALL / 2 else h
			fill(c.x - hx, c.x + hx, c.z - hz, c.z + hz, IN_HALL)
		else
			local w = HALL / 2
			fill(c.x - w, c.x + w, c.z - w, c.z + w, IN_HALL)
			for d = 0, 3 do
				if c.arms[d + 1] then
					local sx, sz = dir(d)
					local mx, mz = c.x + sx * (w + 4), c.z + sz * (w + 4)
					local hx = if sx ~= 0 then 4 else w
					local hz = if sz ~= 0 then 4 else w
					fill(mx - hx, mx + hx, mz - hz, mz + hz, IN_HALL)
				end
			end
		end
	end
	type Piece = { rect: { number }, front: number?, cell: number, bare: boolean }
	local pieces: { Piece } = {}
	for _, s in slots do
		if s.top then
			table.insert(pieces, {
				rect = { Floor.footprint(s) },
				front = s.facing,
				cell = s.cell,
				bare = s.kind == "Wall",
			})
		end
	end
	for _, l in lids do
		table.insert(
			pieces,
			{ rect = { Floor.footprint(l) }, front = nil, cell = l.cell, bare = true }
		)
	end
	for _, p in pieces do
		fill(p.rect[1], p.rect[2], p.rect[3], p.rect[4], ON_TOP)
	end

	-- whether the 4 studs from `t` along a line (x = line if `vertical`, else z = line) are a dead
	-- end's, whose wall closes the rows' ends up to the deck
	local function onDeadEnd(vertical: boolean, line: number, t: number): boolean
		for _, e in deadEnds do
			local fx = dir(e.facing)
			if (fx ~= 0) == vertical then
				local eLine, eAlong = if vertical then e.x else e.z, if vertical then e.z else e.x
				if eLine == line and t >= eAlong - SPAN / 2 and t + GRID <= eAlong + SPAN / 2 then
					return true
				end
			end
		end
		return false
	end
	-- the squares either side of those 4 studs: the lower x (or z) first
	local function beside(vertical: boolean, line: number, t: number): (number, number)
		local a, b = line // GRID, t // GRID
		if vertical then
			return key(a - 1, b), key(a, b)
		end
		return key(b, a - 1), key(b, a)
	end
	-- whether a panel can reach on along those 4 studs unseen: nothing but the dark either side
	local function dark(vertical: boolean, line: number, t: number): boolean
		local p, q = beside(vertical, line, t)
		return grid[p] == nil and grid[q] == nil and not onDeadEnd(vertical, line, t)
	end

	-- every open 4 studs of the tops' edges, gathered by the line they lie on: the Dir a panel
	-- there looks (into the tops) and the hall piece it closes, by where the 4 studs start
	type Edge = { facing: number, cell: number, bare: boolean }
	type Line = { vertical: boolean, line: number, open: { [number]: Edge } }
	local lines: { Line } = {}
	local lineOf: { [string]: Line } = {}
	for _, p in pieces do
		local r = p.rect
		for d = 0, 3 do
			if d == p.front then
				continue
			end
			local vertical = d % 2 == 0
			local line = if d == 0 then r[2] elseif d == 2 then r[1] elseif d == 1 then r[4] else r[3]
			local from, to = if vertical then r[3] else r[1], if vertical then r[4] else r[2]
			for t = from, to - GRID, GRID do
				local below, above = beside(vertical, line, t)
				if
					grid[if d == 0 or d == 1 then above else below] == nil
					and not onDeadEnd(vertical, line, t)
				then
					local name = `{if vertical then "x" else "z"}{line}`
					if not lineOf[name] then
						local made: Line = { vertical = vertical, line = line, open = {} }
						lineOf[name] = made
						table.insert(lines, made)
					end
					lineOf[name].open[t] = { facing = (d + 2) % 4, cell = p.cell, bare = p.bare }
				end
			end
		end
	end

	-- each line's open stretches closed end to end, a stretch being the open studs that face the
	-- same way and want the same sheet: 12-stud panels while they fit, 8s for the rest (every
	-- stretch is a multiple of 4, and 8 or more of them is 12s and 8s); a lone 4 studs takes an 8
	-- that reaches 4 on into the dark, past whichever end is dark and has no panel yet
	local panels: { Panel } = {}
	for _, l in lines do
		local starts = {}
		for t in l.open do
			table.insert(starts, t)
		end
		table.sort(starts)
		local covered: { [number]: boolean } = {}
		local function put(lo: number, width: number, edge: Edge)
			for t = lo, lo + width - GRID, GRID do
				covered[t] = true
			end
			local middle = lo + width / 2
			table.insert(panels, {
				x = if l.vertical then l.line else middle,
				z = if l.vertical then middle else l.line,
				facing = edge.facing,
				size = if width == 12 then "M" else "S",
				bare = edge.bare,
				cell = edge.cell,
			})
		end
		local function free(t: number): boolean
			return not covered[t] and dark(l.vertical, l.line, t)
		end
		-- closes start..stop with panels of one sheet
		local function close(start: number, stop: number, edge: Edge)
			if stop - start == GRID then
				put(if free(stop) or not free(start - GRID) then start else start - GRID, 8, edge)
				return
			end
			local at = start
			while at < stop do
				local left = stop - at
				local width = if left == 8 or left % 12 == 4 then 8 else 12
				put(at, width, edge)
				at += width
			end
		end
		for _, start in starts do
			if covered[start] then
				continue
			end
			local first = l.open[start]
			local stop = start
			while l.open[stop] and l.open[stop].facing == first.facing do
				stop += GRID
			end
			-- the stretch in lengths of one sheet; a lone 4 studs of them with no dark to reach into
			-- puts the units' sheet over the whole stretch (a bare one would stand inside a unit)
			type Sheet = { from: number, to: number }
			local sheets: { Sheet } = {}
			local at = start
			while at < stop do
				local from, bare = at, l.open[at].bare
				while at < stop and l.open[at].bare == bare do
					at += GRID
				end
				table.insert(sheets, { from = from, to = at })
			end
			local stuck = false
			for _, sheet in sheets do
				local reaches = (sheet.from == start and free(start - GRID))
					or (sheet.to == stop and free(stop))
				if #sheets > 1 and sheet.to - sheet.from == GRID and not reaches then
					stuck = true
				end
			end
			if stuck then
				close(start, stop, { facing = first.facing, cell = first.cell, bare = false })
			else
				for _, sheet in sheets do
					close(sheet.from, sheet.to, l.open[sheet.from])
				end
			end
		end
	end
	return panels
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
	-- The first stretch: the pieces from the lobby to the first fork, the fork included.
	local lobby = at[key(0, 0)]
	local firstStretch: { [number]: boolean } = {}
	local fork, forkWalk = lobby, 3
	while true do
		firstStretch[fork] = true
		local c = cells[fork]
		local ways = waysOn(c, forkWalk)
		if c.kind ~= "Lobby" and #ways ~= 1 then
			break
		end
		local n = neighbour(c, ways[1])
		if not n then
			break
		end
		fork, forkWalk = at[key(n.gx, n.gz)], ways[1]
	end

	-- 3. The slots along every hall side, units or plain walls.
	local slots: { Slot } = {}
	local picked: { [number]: boolean } = {} -- the plain walls picked at random, not needed
	local function addSlot(
		cell: number,
		size: Size,
		x: number,
		z: number,
		facing: number,
		wall: boolean
	)
		-- the draw is made even where its answer is ignored, so every other choice stays the seed's
		local pick = random:nextNumber() < plan.plainWalls and not wall
		if pick and plan.teachHoles and firstStretch[cell] then
			pick = false
		end
		if pick then
			picked[#slots + 1] = true
		end
		table.insert(slots, {
			kind = if wall or pick then "Wall" else "Unit",
			size = size,
			x = x,
			z = z,
			facing = facing % 4,
			cell = cell,
			drops = {},
			top = false,
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
				if corners and plan.teachHoles and firstStretch[index] then
					size = "S" -- three small units side by side, none of them walled
				end
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
	-- What stands past each slot's walls. A plain wall picked at random never leaves a unit beside
	-- it with no neighbour to crawl to: it stays a unit instead.
	findNeighbours(slots)
	local function cutOff(i: number): boolean
		for _, j in { slots[i].left, slots[i].right, slots[i].back } do
			if j and slots[j].kind == "Unit" then
				return false
			end
		end
		return true
	end
	for i, s in slots do
		if picked[i] then
			for _, j in { s.left, s.right, s.back } do
				if j and slots[j].kind == "Unit" and cutOff(j) then
					s.kind = "Unit"
					break
				end
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
	local slotsOf: { { number } } = {}
	for i in cells do
		slotsOf[i] = {}
	end
	for i, s in slots do
		table.insert(slotsOf[s.cell], i)
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
	for i in firstStretch do
		zoneOf[i] = "Lobby"
	end
	local queue: { number } = {}
	for w, d in waysOn(cells[fork], forkWalk) do
		local n = neighbour(cells[fork], d)
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

	-- 7. The top runs: the rows of tops a ladder reaches.
	local runs = findRuns(slots)
	-- 8. The tops closed: lids carry runs round junctions' corners, panels close every drop.
	local lids = findLids(cells, slots, runs)
	local panels = findPanels(cells, slots, lids, deadEnds)

	return {
		number = number,
		paint = Floor.Paints[(number - 1) % #Floor.Paints + 1],
		plan = plan,
		cells = cells,
		slots = slots,
		fixtures = fixtures,
		deadEnds = deadEnds,
		runs = runs,
		lids = lids,
		panels = panels,
		lobby = lobby,
	}
end

-- The units a crawl hole from slot `index` can lead into: its neighbours that are units.
function Floor.crawlsTo(floor: Floor, index: number): { number }
	local s = floor.slots[index]
	local into = {}
	for _, j in { s.left, s.right, s.back } do
		if j and floor.slots[j].kind == "Unit" then
			table.insert(into, j)
		end
	end
	return into
end

--[[
	The floor as a small text map, seen from above (+X to the right, +Z down the page), 4 studs a
	column and 8 a line: for the owner to judge a layout, and for Output while L-01b lays one. Two
	views: "units" (the default) shows each unit's size, a unit no crawl hole leads from as x;
	"tops" shows each top run in a letter of its own, capital over a unit and small over a plain
	wall's lid, so a run reads as one letter along its row, and = over a junction's lid.
]]
export type MapView = "units" | "tops"
function Floor.map(floor: Floor, view: MapView?): string
	local tops = view == "tops"
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
	for i, s in floor.slots do
		local x0, x1, z0, z1 = Floor.footprint(s)
		if tops and s.run then
			local letter = string.char(65 + (s.run - 1) % 26)
			fill(x0, x1, z0, z1, if s.kind == "Unit" then letter else string.lower(letter))
		elseif s.kind == "Wall" then
			-- a plain wall is its face: the first character behind it
			local fx, fz = dir(s.facing)
			local bx, bz = s.x - fx * 4, s.z - fz * 8
			if fx ~= 0 then
				fill(math.min(s.x, bx), math.max(s.x, bx), z0, z1, "#")
			else
				fill(x0, x1, math.min(s.z, bz), math.max(s.z, bz), "#")
			end
		else
			if not tops and #Floor.crawlsTo(floor, i) == 0 then
				fill(x0, x1, z0, z1, "x")
				continue
			end
			-- neighbours alternate case so each unit reads on its own
			local ax, az = dir(s.facing + 1)
			local along = s.x * math.abs(ax) + s.z * math.abs(az)
			local k = math.floor(along / Floor.Sizes[s.size].width)
			fill(x0, x1, z0, z1, if k % 2 == 0 then s.size else string.lower(s.size))
		end
	end
	if tops then
		for _, l in floor.lids do
			local x0, x1, z0, z1 = Floor.footprint(l)
			fill(x0, x1, z0, z1, "=")
		end
	end
	for _, e in floor.deadEnds do
		local fx, fz = dir(e.facing)
		mark(e.x - fx * 2, e.z - fz * 4, if fx ~= 0 then "|" else "-")
	end
	for _, f in floor.fixtures do
		if not tops then
			mark(f.x, f.z, "*")
		end
	end

	local lines = {}
	for r = 1, rows do
		lines[r] = (string.gsub(table.concat(grid[r]), "%s+$", ""))
	end
	return table.concat(lines, "\n")
end

return Floor
