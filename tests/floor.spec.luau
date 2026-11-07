--!strict
-- lune run tests/floor.spec
-- The floor generator (L-01a) over 200 seeds, on a short floor and a full one each: the same seed
-- gives the same floor, and every layout rule holds: a straight between two junctions, the kit's
-- slots at every junction, no unit in another or in a hall or over two decks' overlap, every
-- door onto a hall, every stretch of hall under a light that watches it, numbers unique and in
-- order, shared walls stood once, every hall reachable from the lobby. First, the generator's
-- sizes against the kit's and the units' generated specs, read as text (they build Roblox values).
local fs = require("@lune/fs")

local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local MotionLight = require("../src/shared/MotionLight")

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

local dir = Floor.dir

-- 1. The generator's sizes are the kit's and the units'.
local KIT = fs.readFile("src/shared/CorridorKit/Specs.luau")
local UNIT_M = fs.readFile("src/shared/StorageUnit/Specs/M.luau")
local UNIT_ART = fs.readFile("art/unit/spec.py")
local UNIT_KIT = fs.readFile("src/shared/StorageUnit/UnitKit.luau")
local function number(text: string, pattern: string): number?
	local found = string.match(text, pattern)
	return found and tonumber(found)
end
ok(number(KIT, "Straight = {%s*Length = ([%d%.]+)") == Floor.Cell, "a straight is a grid cell long")
ok(number(KIT, "HallWidth = ([%d%.]+)") == Floor.HallWidth, "the hall's width is the kit's")
ok(number(KIT, "Span = ([%d%.]+)") == Floor.Span, "the deck's span is the kit's")
ok(
	number(KIT, "Wall = {%s*Width = ([%d%.]+)") == Floor.Sizes.M.width,
	"a plain wall is an M slot wide"
)
ok(
	number(KIT, "ShortWall = {%s*Width = ([%d%.]+)") == Floor.Sizes.S.width,
	"a short wall is an S slot wide"
)
ok(number(KIT, "DeadEnd = {%s*Width = ([%d%.]+)") == Floor.Span, "a dead end closes the whole span")
ok(number(UNIT_M, "\n\tWidth = ([%d%.]+)") == Floor.Sizes.M.width, "an M unit's width")
ok(number(UNIT_M, "\n\tDepth = ([%d%.]+)") == Floor.Sizes.M.depth, "an M unit's depth")
ok(number(UNIT_ART, '"S": dict%(width=([%d%.]+)') == Floor.Sizes.S.width, "an S unit's width")
ok(
	number(UNIT_ART, '"S": dict%(width=[%d%.]+, depth=([%d%.]+)') == Floor.Sizes.S.depth,
	"an S unit's depth"
)
ok(
	Floor.Sizes.M.depth == (Floor.Span - Floor.HallWidth) / 2,
	"an M row fills the deck behind the hall"
)
for _, paint in Floor.Paints do
	ok(string.find(UNIT_KIT, `\n\t\t{paint} = Color3`, 1, true) ~= nil, `{paint} is a door colour`)
end

-- Each junction's block of text in the kit: its size, arms (as local Dirs) and walls.
local function escape(text: string): string
	return (string.gsub(text, "[%(%)%.%-%+]", "%%%0"))
end
local function vector(x: number, z: number): string
	return `Vector3%.new%({escape(tostring(x))}, 0, {escape(tostring(z))}%)`
end
local kitArms: { [string]: { boolean } } = {}
for name, slots in Floor.JunctionSlots do
	local start = string.find(KIT, `\n\t\t{name} = {"{"}`, 1, true)
	ok(start ~= nil, `the kit has a {name}`)
	if not start then
		continue
	end
	local block = string.sub(KIT, start, (string.find(KIT, "Colliders", start, true)))
	ok(number(block, "Size = ([%d%.]+)") == Floor.Cell, `a {name} is a grid cell square`)
	local arms = { false, false, false, false }
	local armsText = string.match(block, "Arms = {(.-)}%s*,%s*Walls") or ""
	for x, z in string.gmatch(armsText, "Vector3%.new%((%-?%d+), 0, (%-?%d+)%)") do
		for d = 0, 3 do
			local dx, dz = dir(d)
			if dx == tonumber(x) and dz == tonumber(z) then
				arms[d + 1] = true
			end
		end
	end
	kitArms[name] = arms
	local walls = 0
	for _ in string.gmatch(block, "Name = ") do
		walls += 1
	end
	local blocks = 0
	for d = 0, 3 do
		if arms[d + 1] and arms[(d + 1) % 4 + 1] then
			blocks += 1
		end
	end
	ok(walls == #slots + 2 * blocks, `a {name}'s walls are its slots and two per block of wall`)
	for _, s in slots do
		local fx, fz = dir(s.facing)
		local wall = if s.size == "M" then "Wall" else "ShortWall"
		local pattern =
			`Name = "{wall}",%s*Position = {vector(s.x, s.z)},%s*Look = {vector(fx, fz)}`
		ok(string.find(block, pattern) ~= nil, `the kit's {name} stands a {wall} at ({s.x}, {s.z})`)
	end
end

-- 2. The plans fit their shape (Brix Schema), so a typo in a row can't lay a broken floor.
local S = Brix.Schema
local chance = S.number({ min = 0, max = 1 })
local PLAN = S.shape({
	columns = S.number({ min = 3, max = 9, integer = true }),
	rows = S.number({ min = 2, max = 9, integer = true }),
	straights = S.number({ min = 1, integer = true }),
	loops = S.number({ min = 0, integer = true }),
	keepOn = chance,
	smallRows = chance,
	plainWalls = chance,
})
for name, plan in Floor.Plans do
	local problems = PLAN:validate(plan)
	ok(#problems == 0, `plan {name}: {S.format(problems)}`)
	ok(plan.columns % 2 == 1, `plan {name} has an odd number of columns, for the lobby's middle`)
end

-- 3. The floors.
type Rect = { x0: number, x1: number, z0: number, z1: number }
local function rect(x0: number, x1: number, z0: number, z1: number): Rect
	return { x0 = x0, x1 = x1, z0 = z0, z1 = z1 }
end
local function overlap(a: Rect, b: Rect): Rect?
	local x0, x1 = math.max(a.x0, b.x0), math.min(a.x1, b.x1)
	local z0, z1 = math.max(a.z0, b.z0), math.min(a.z1, b.z1)
	return if x1 - x0 > 0.01 and z1 - z0 > 0.01 then rect(x0, x1, z0, z1) else nil
end
local function inside(r: Rect, x: number, z: number): boolean
	return x >= r.x0 - 0.01 and x <= r.x1 + 0.01 and z >= r.z0 - 0.01 and z <= r.z1 + 0.01
end
local function anyInside(rs: { Rect }, x: number, z: number): boolean
	for _, r in rs do
		if inside(r, x, z) then
			return true
		end
	end
	return false
end
-- a box `along` long down Dir `turn` and `across` wide, centred on (x, z)
local function box(x: number, z: number, turn: number, along: number, across: number): Rect
	local hx = if turn % 2 == 0 then along / 2 else across / 2
	local hz = if turn % 2 == 0 then across / 2 else along / 2
	return rect(x - hx, x + hx, z - hz, z + hz)
end

local HALF, HALL, SPAN = Floor.Cell / 2, Floor.HallWidth, Floor.Span

-- Where you can walk (each hall piece's floor between its walls) and where its deck reaches.
local function walkable(c: Floor.Cell): { Rect }
	if c.kind == "Lobby" then
		return { rect(c.x - HALF, c.x + HALF, c.z - HALF, c.z + HALF) }
	elseif c.kind == "Straight" then
		return { box(c.x, c.z, c.turn, Floor.Cell, HALL) }
	end
	local rs = { rect(c.x - HALL / 2, c.x + HALL / 2, c.z - HALL / 2, c.z + HALL / 2) }
	for d = 0, 3 do
		if c.arms[d + 1] then
			local dx, dz = dir(d)
			local mid = (HALL / 2 + HALF) / 2
			table.insert(rs, box(c.x + dx * mid, c.z + dz * mid, d, HALF - HALL / 2, HALL))
		end
	end
	return rs
end
local function deck(c: Floor.Cell): Rect?
	if c.kind == "Lobby" then
		return nil
	elseif c.kind == "Straight" then
		return box(c.x, c.z, c.turn, Floor.Cell, SPAN)
	end
	-- a junction's deck reaches its square's edge on an open side and the span's on a closed one
	local reach = {}
	for d = 0, 3 do
		reach[d + 1] = if c.arms[d + 1] then HALF else SPAN / 2
	end
	return rect(c.x - reach[3], c.x + reach[1], c.z - reach[4], c.z + reach[2])
end
local function footprint(s: Floor.Slot): Rect
	return rect(Floor.footprint(s))
end

local SAME_SEED_ALIKE = 0
local seen: { [string]: boolean } = {}
local distinct, floors, atCap, maxUnits = 0, 0, 0, 0
local overlapsFound = 0

local function checkFloor(seed: number, number: number)
	local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local again = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local where = `floor {number} seed {seed}`
	floors += 1

	-- the same seed, the same floor
	local map = Floor.map(f)
	local alike = map == Floor.map(again) and #f.slots == #again.slots
	for i, s in f.slots do
		local t = again.slots[i]
		alike = alike
			and t ~= nil
			and s.kind == t.kind
			and s.x == t.x
			and s.z == t.z
			and s.number == t.number
	end
	ok(alike, `{where}: the same seed lays the same floor`)
	if alike then
		SAME_SEED_ALIKE += 1
	end
	if not seen[map] then
		seen[map] = true
		distinct += 1
	end
	ok(f.plan == Floor.planFor(number), `{where}: its plan`)
	ok(f.paint == Floor.Paints[(number - 1) % 4 + 1], `{where}: its paint`)

	-- the grid: pieces where they belong, arms that meet, a straight between two junctions
	local at: { [string]: Floor.Cell } = {}
	for _, c in f.cells do
		ok(c.x == c.gx * Floor.Cell and c.z == c.gz * Floor.Cell, `{where}: a piece off the grid`)
		local k = `{c.gx},{c.gz}`
		ok(at[k] == nil, `{where}: two pieces at {k}`)
		at[k] = c
	end
	local function neighbour(c: Floor.Cell, d: number): Floor.Cell?
		local dx, dz = dir(d)
		return at[`{c.gx + dx},{c.gz + dz}`]
	end
	local lobby = f.cells[f.lobby]
	ok(lobby.kind == "Lobby" and lobby.x == 0 and lobby.z == 0, `{where}: the lobby at the origin`)
	local deadEndCells = 0
	for _, c in f.cells do
		local n = 0
		for d = 0, 3 do
			if c.arms[d + 1] then
				n += 1
				local other = neighbour(c, d)
				ok(
					other ~= nil and other.arms[(d + 2) % 4 + 1],
					`{where}: a hall at {c.gx},{c.gz} leads nowhere`
				)
			end
		end
		local isPoint = c.gx % 2 == 0 and c.gz % 2 == 0
		if c.kind == "Lobby" then
			ok(c.arms[4] and n == 1, `{where}: the lobby has one hall, into the floor`)
			ok(c ~= lobby or isPoint, `{where}: the lobby on a junction point`)
		elseif c.kind == "Straight" then
			local axis = c.turn
			ok(axis == 0 or axis == 1, `{where}: a straight turned along a hall`)
			local across1, across2 = (axis + 1) % 4, (axis + 3) % 4
			ok(
				not c.arms[across1 + 1] and not c.arms[across2 + 1],
				`{where}: a straight with an arm across it`
			)
			ok(
				n == 2 or (n == 1 and c.deadEnd),
				`{where}: a straight open at both ends or closed by a dead end`
			)
			ok(isPoint or not c.deadEnd, `{where}: a dead end off a junction point`)
			if c.deadEnd then
				deadEndCells += 1
			end
		else
			ok(isPoint, `{where}: a {c.kind} off a junction point`)
			-- the kit's arms, turned, are the piece's
			local kit = kitArms[c.kind]
			for d = 0, 3 do
				ok(
					kit[d + 1] == c.arms[(d + c.turn) % 4 + 1],
					`{where}: a {c.kind} turned wrong at {c.gx},{c.gz}`
				)
			end
		end
		if isPoint then
			for d = 0, 3 do
				local other = if c.arms[d + 1] then neighbour(c, d) else nil
				ok(
					other == nil or other.kind == "Straight",
					`{where}: two junctions side by side at {c.gx},{c.gz}`
				)
			end
		end
	end
	ok(deadEndCells == #f.deadEnds, `{where}: a dead end for every closed straight`)
	for _, e in f.deadEnds do
		local c = f.cells[e.cell]
		local fx, fz = dir(e.facing)
		ok(c.deadEnd and c.arms[e.facing + 1], `{where}: a dead end looking down its hall`)
		ok(
			e.x == c.x - fx * HALF and e.z == c.z - fz * HALF,
			`{where}: a dead end at its straight's end`
		)
	end

	-- every piece reachable from the lobby
	local reached, queue = { [lobby] = true }, { lobby }
	local head = 1
	while head <= #queue do
		local c = queue[head]
		head += 1
		for d = 0, 3 do
			local other = if c.arms[d + 1] then neighbour(c, d) else nil
			if other and not reached[other] then
				reached[other] = true
				table.insert(queue, other)
			end
		end
	end
	ok(#queue == #f.cells, `{where}: every hall reachable from the lobby`)

	-- the slots: rows along straights, the kit's slots at junctions
	local walk, decks = {}, {}
	for _, c in f.cells do
		for _, r in walkable(c) do
			table.insert(walk, r)
		end
		local d = deck(c)
		if d then
			table.insert(decks, d)
		end
	end
	local elevator = rect(-HALF, HALF, HALF, HALF + Floor.ElevatorDepth)
	local bySide: { [string]: { Floor.Slot } } = {}
	for _, s in f.slots do
		local c = f.cells[s.cell]
		local fx, fz = dir(s.facing)
		local side = (s.facing + 2) % 4 -- the side of the hall it lines
		local sx, sz = dir(side)
		ok(not c.arms[side + 1], `{where}: a slot across a hall's mouth`)
		ok(
			math.abs((s.x - c.x) * sx + (s.z - c.z) * sz - HALL / 2) < 0.01,
			`{where}: a slot off its hall's side`
		)
		-- its door (or wall) opens onto the hall
		ok(anyInside(walk, s.x + fx, s.z + fz), `{where}: slot {s.number or "wall"} faces no hall`)
		if c.kind == "Straight" then
			local k = `{s.cell},{side}`
			bySide[k] = bySide[k] or {}
			table.insert(bySide[k], s)
		elseif c.kind == "T" then
			ok(s.size == "M", `{where}: a T's slots are M`)
		elseif c.kind == "Corner" then
			ok(s.size == "S", `{where}: a corner's slots are S`)
		else
			ok(false, `{where}: a slot in a {c.kind}`)
		end
		local fp = footprint(s)
		for _, r in walk do
			ok(overlap(fp, r) == nil, `{where}: slot {s.number or "wall"} stands in a hall`)
		end
		ok(overlap(fp, elevator) == nil, `{where}: a slot in the elevator's way`)
	end
	for k, row in bySide do
		local size = row[1].size
		local n = if size == "M" then 2 else 3
		local same = #row == n
		for _, s in row do
			same = same and s.size == size
		end
		ok(same, `{where}: side {k} isn't a row of two M or three S`)
	end
	local juncSlots: { [number]: number } = {}
	for _, s in f.slots do
		juncSlots[s.cell] = (juncSlots[s.cell] or 0) + 1
	end
	for i, c in f.cells do
		local want = if c.kind == "Corner" then 4 elseif c.kind == "T" then 2 else nil
		if want or c.kind == "Cross" or c.kind == "Lobby" then
			ok(
				(juncSlots[i] or 0) == (want or 0),
				`{where}: a {c.kind} with {juncSlots[i] or 0} slots`
			)
		end
	end

	-- units: none in another, none over two decks' overlap, all under a deck
	local overlaps: { Rect } = {}
	for i, a in decks do
		for j = i + 1, #decks do
			local o = overlap(a, decks[j])
			if o then
				table.insert(overlaps, o)
			end
		end
	end
	overlapsFound += #overlaps
	local units: { Floor.Slot } = {}
	for _, s in f.slots do
		if s.kind == "Unit" then
			table.insert(units, s)
		end
	end
	for i, a in ipairs(units) do
		local fa = footprint(a)
		for j = i + 1, #units do
			ok(
				overlap(fa, footprint(units[j])) == nil,
				`{where}: units {a.number} and {units[j].number} overlap`
			)
		end
		for _, o in overlaps do
			ok(overlap(fa, o) == nil, `{where}: unit {a.number} under two decks' overlap`)
		end
		for _, x in { fa.x0 + 0.5, fa.x1 - 0.5 } do
			for _, z in { fa.z0 + 0.5, fa.z1 - 0.5 } do
				ok(anyInside(decks, x, z), `{where}: unit {a.number} out from under the deck`)
			end
		end
	end

	-- numbers: unique, the floor's, from 01 with no gaps
	ok(#units <= Floor.MaxUnits, `{where}: more units than numbers`)
	maxUnits = math.max(maxUnits, #units)
	if #units == Floor.MaxUnits then
		atCap += 1
	end
	local numbers: { [string]: boolean } = {}
	for _, u in units do
		local text = u.number or ""
		ok(not numbers[text], `{where}: two units numbered {text}`)
		numbers[text] = true
	end
	for n = 1, #units do
		ok(numbers[string.format("%d%02d", number, n)] ~= nil, `{where}: no unit {number}{n}`)
	end

	-- shared walls: of two units side by side in a row, exactly one leaves out the wall between,
	-- the shallower; and no unit leaves out a wall with no unit beside it
	local dropped: { [Floor.Slot]: { [number]: boolean } } = {}
	for _, u in units do
		dropped[u] = {}
		for _, d in u.drops do
			dropped[u][d] = true
		end
	end
	local needed: { [Floor.Slot]: number } = {}
	for i, a in ipairs(units) do
		for j = i + 1, #units do
			local b = units[j]
			local ax, az = dir(a.facing + 1)
			local apart = (b.x - a.x) * ax + (b.z - a.z) * az
			local fx, fz = dir(a.facing)
			local off = (b.x - a.x) * fx + (b.z - a.z) * fz
			local reach = (Floor.Sizes[a.size].width + Floor.Sizes[b.size].width) / 2
			if
				a.facing == b.facing
				and math.abs(off) < 0.01
				and math.abs(math.abs(apart) - reach) < 0.01
			then
				local towardB = (if apart > 0 then a.facing + 1 else a.facing + 3) % 4
				local aDrops, bDrops =
					dropped[a][towardB] == true, dropped[b][(towardB + 2) % 4] == true
				ok(
					aDrops ~= bDrops,
					`{where}: units {a.number} and {b.number} both or neither stand their wall`
				)
				local deeper = if aDrops then b else a
				local shallower = if aDrops then a else b
				ok(
					Floor.Sizes[shallower.size].depth <= Floor.Sizes[deeper.size].depth,
					`{where}: unit {shallower.number}'s wall, deeper than {deeper.number}'s, left out`
				)
				local dropper = if aDrops then a else b
				needed[dropper] = (needed[dropper] or 0) + 1
			end
		end
	end
	for _, u in units do
		ok(
			#u.drops == (needed[u] or 0),
			`{where}: unit {u.number} leaves out a wall no neighbour stands`
		)
	end

	-- the lights: one over every hall piece's middle, and every step of hall watched
	local lit: { [number]: number } = {}
	local boxes = {}
	for _, fx in f.fixtures do
		local c = f.cells[fx.cell]
		lit[fx.cell] = (lit[fx.cell] or 0) + 1
		ok(
			fx.x == c.x and fx.z == c.z and fx.turn == c.turn,
			`{where}: a light off its piece's middle`
		)
		ok(fx.zone == c.zone, `{where}: a light in another zone than its piece`)
		table.insert(
			boxes,
			box(fx.x, fx.z, fx.turn, MotionLight.WatchLength, MotionLight.WatchWidth)
		)
	end
	for i, c in f.cells do
		ok(
			(lit[i] or 0) == (if c.kind == "Lobby" then 0 else 1),
			`{where}: a {c.kind} with {lit[i] or 0} lights`
		)
		if c.kind ~= "Lobby" then
			-- every stud of its floor, against the lights near enough to watch it
			local near = {}
			for _, b in boxes do
				if
					b.x0 < c.x + HALF
					and b.x1 > c.x - HALF
					and b.z0 < c.z + HALF
					and b.z1 > c.z - HALF
				then
					table.insert(near, b)
				end
			end
			local dark: string? = nil
			for _, r in walkable(c) do
				for x = r.x0 + 0.5, r.x1 - 0.5 do
					for z = r.z0 + 0.5, r.z1 - 0.5 do
						if not dark and not anyInside(near, x, z) then
							dark = `({x}, {z})`
						end
					end
				end
			end
			ok(dark == nil, `{where}: {dark} in the {c.kind} at {c.gx},{c.gz} unwatched`)
		end
	end

	-- power zones: the stretch from the lobby is "Lobby"; each wing past the fork is one piece
	local zoneCells: { [string]: { Floor.Cell } } = {}
	for _, c in f.cells do
		zoneCells[c.zone] = zoneCells[c.zone] or {}
		table.insert(zoneCells[c.zone], c)
	end
	ok(lobby.zone == "Lobby", `{where}: the lobby's zone`)
	for name, list in zoneCells do
		ok(name == "Lobby" or string.match(name, "^[A-D]$") ~= nil, `{where}: a zone named {name}`)
		local member = {}
		for _, c in list do
			member[c] = true
		end
		local got, q = { [list[1]] = true }, { list[1] }
		local h = 1
		while h <= #q do
			local c = q[h]
			h += 1
			for d = 0, 3 do
				local other = if c.arms[d + 1] then neighbour(c, d) else nil
				if other and member[other] and not got[other] then
					got[other] = true
					table.insert(q, other)
				end
			end
		end
		ok(#q == #list, `{where}: zone {name} in two pieces`)
	end
end

for seed = 1, 200 do
	checkFloor(seed, 1 + seed % 2) -- floors 1 and 2: the short plan
	checkFloor(seed, 3 + seed % 8) -- floors 3 to 10: the full one
end
ok(SAME_SEED_ALIKE == floors, "every seed lays its floor the same way twice")
ok(distinct >= floors * 0.95, `seeds lay different floors ({distinct} of {floors})`)
ok(overlapsFound > 0, "the back-corner deck overlaps were checked (some exist)")
ok(atCap <= floors * 0.02, `floors rarely reach the unit cap ({atCap} of {floors})`)

if failures > 0 then
	error(`{failures} of {checks} floor checks failed`)
end
print(`floor: {checks} checks passed over {floors} floors (at most {maxUnits} units)`)
