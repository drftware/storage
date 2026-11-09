--!strict
-- lune run tests/floor.spec
-- The floor generator (L-01a) over 200 seeds, on a short floor and a full one each: the same seed
-- gives the same floor, and every layout rule holds: a straight between two junctions, the kit's
-- slots at every junction, no unit in another or in a hall or over two decks' overlap, every
-- door onto a hall, every stretch of hall under a light that watches it, numbers unique and in
-- order, shared walls stood once, every hall reachable from the lobby, and every unit's neighbours
-- and top run (L-01d): crawl holes only between side-by-side units, enough of them on every floor
-- and, on floors 1 and 2, in the hall out of the lobby; no top run dropping into a plain wall's
-- empty slot; the tops closed by lids and panels, no drop left open (L-13a). First, the generator's
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
	teachHoles = S.boolean(),
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

local mostCutOff, fewestLinks, fewestFirst, shortestRun, longestRun =
	0, math.huge, math.huge, math.huge, 0
local SAME_SEED_ALIKE = 0
local seen: { [string]: boolean } = {}
local distinct, floors, atCap, maxUnits = 0, 0, 0, 0
local overlapsFound = 0
local mostPanels, mostLids = 0, 0

local function checkFloor(seed: number, number: number)
	local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local again = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local where = `floor {number} seed {seed}`
	floors += 1

	-- the same seed, the same floor
	local map = Floor.map(f)
	local alike = map == Floor.map(again)
		and Floor.map(f, "tops") == Floor.map(again, "tops")
		and #f.slots == #again.slots
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

	-- neighbours: what stands past each slot's walls, found again from the footprints
	local rects = {}
	for i, s in f.slots do
		rects[i] = footprint(s)
	end
	-- the stretch of slot i's wall on Dir d that slot j's footprint shares
	local function shares(i: number, j: number, d: number): number
		local a, b = rects[i], rects[j]
		if
			(d == 0 and math.abs(a.x1 - b.x0) < 0.01) or (d == 2 and math.abs(a.x0 - b.x1) < 0.01)
		then
			return math.max(0, math.min(a.z1, b.z1) - math.max(a.z0, b.z0))
		elseif
			(d == 1 and math.abs(a.z1 - b.z0) < 0.01) or (d == 3 and math.abs(a.z0 - b.z1) < 0.01)
		then
			return math.max(0, math.min(a.x1, b.x1) - math.max(a.x0, b.x0))
		end
		return 0
	end
	local SIDES: { Floor.Side } = { "left", "right", "back" }
	local function sideOf(s: Floor.Slot, side: Floor.Side): number?
		return if side == "left" then s.left elseif side == "right" then s.right else s.back
	end
	local links, backLinks, firstLinks, cutOff = 0, 0, 0, 0
	for i, s in f.slots do
		local anyUnit = false
		for _, side in SIDES do
			local d = Floor.sideDir(s, side)
			local j = sideOf(s, side)
			local longest, best = 0, nil
			for k in f.slots do
				local length = if k ~= i then shares(i, k, d) else 0
				if length > longest then
					longest, best = length, k
				end
			end
			if longest >= Floor.CrawlWidth then
				ok(
					j ~= nil,
					`{where}: slot {i}'s {side} wall shares {longest} studs, none recorded`
				)
				ok(
					j == nil or shares(i, j, d) == longest,
					`{where}: slot {i}'s {side} neighbour isn't the one sharing most of that wall`
				)
				local _ = best
			else
				ok(j == nil, `{where}: slot {i}'s {side} neighbour shares too little wall to crawl`)
			end
			if j and s.kind == "Unit" and f.slots[j].kind == "Unit" then
				anyUnit = true
				local o = f.slots[j]
				local back = (d + 2) % 4
				ok(
					(Floor.sideDir(o, "left") == back and o.left == i)
						or (Floor.sideDir(o, "right") == back and o.right == i)
						or (Floor.sideDir(o, "back") == back and o.back == i),
					`{where}: unit {s.number} crawls to {o.number}, not back`
				)
				if j > i then
					links += 1
					if side == "back" or Floor.sideDir(o, "back") == back then
						backLinks += 1
					end
					if f.cells[s.cell].zone == "Lobby" and f.cells[o.cell].zone == "Lobby" then
						firstLinks += 1
					end
				end
			end
		end
		if s.kind == "Unit" then
			ok(
				(#Floor.crawlsTo(f, i) > 0) == anyUnit,
				`{where}: unit {s.number}'s crawl holes miscounted`
			)
			if not anyUnit then
				cutOff += 1
			end
		end
	end
	-- holes only between side-by-side neighbours (OWNER.md's default): no unit backs onto another
	ok(backLinks == 0, `{where}: {backLinks} units back onto another`)
	local short = number <= 2
	ok(links >= (if short then 30 else 40), `{where}: only {links} crawl links`)
	ok(cutOff <= (if short then 0 else 2), `{where}: {cutOff} units with no neighbour to crawl to`)
	mostCutOff = math.max(mostCutOff, cutOff)
	fewestLinks = math.min(fewestLinks, links)
	if f.plan.teachHoles then
		-- floors 1 and 2 teach the hole trap on the way out of the lobby
		for _, s in f.slots do
			ok(
				f.cells[s.cell].zone ~= "Lobby" or s.kind == "Unit",
				`{where}: a plain wall between the lobby and the first fork`
			)
		end
		ok(firstLinks >= 4, `{where}: {firstLinks} crawl links before the first fork`)
		fewestFirst = math.min(fewestFirst, firstLinks)
	end

	-- the tops: every unit's and every lidded wall's in one run along its row, and no run's
	-- neighbour along the row left open for a friend running it to drop into
	local inRow = function(i: number, j: number?): boolean
		return j ~= nil and f.slots[j].facing == f.slots[i].facing
	end
	local seenIn: { [number]: number } = {}
	for r, run in f.runs do
		local length, unitsIn = 0, 0
		for k, i in run.slots do
			local s = f.slots[i]
			ok(seenIn[i] == nil, `{where}: slot {i} in two top runs`)
			seenIn[i] = r
			ok(s.top and s.run == r, `{where}: slot {i} in run {r} not marked so`)
			length += Floor.Sizes[s.size].width
			unitsIn += if s.kind == "Unit" then 1 else 0
			local nextIndex = run.slots[k + 1]
			if nextIndex then
				ok(
					s.left == nextIndex and f.slots[nextIndex].right == i and inRow(i, nextIndex),
					`{where}: run {r} skips along its row at slot {i}`
				)
			else
				ok(not inRow(i, s.left), `{where}: run {r} stops short of its row's end`)
			end
		end
		ok(not inRow(run.slots[1], f.slots[run.slots[1]].right), `{where}: run {r} starts mid-row`)
		ok(length == run.length and unitsIn == run.units, `{where}: run {r}'s length or units`)
		ok(run.units >= 1, `{where}: run {r} has no unit`)
		ok(run.length >= Floor.Cell, `{where}: run {r} only {run.length} studs`)
		shortestRun = math.min(shortestRun, run.length)
		longestRun = math.max(longestRun, run.length)
	end
	for i, s in f.slots do
		ok(s.top == (seenIn[i] ~= nil), `{where}: slot {i}'s top and its run disagree`)
		ok(s.kind ~= "Unit" or s.top, `{where}: unit {s.number} without a top`)
		for j = i + 1, #f.slots do
			local o = f.slots[j]
			if s.top and o.top and overlap(rects[i], rects[j]) then
				-- only two lids at a junction's back corner, under the halls' overlapping decks
				ok(s.kind == "Wall" and o.kind == "Wall", `{where}: a unit's top over another top`)
			end
		end
	end

	-- the tops closed (L-13a), on a 2-stud raster: every edge of a run's slots and of the lids is a
	-- unit's front onto its hall, a wall the junction or the lobby stands to the deck, a dead end,
	-- or a panel; no panel stands across the tops' way, hangs in a hall or looks away from the tops,
	-- and none turns its bare sheet into a unit;
	-- every lid is a free square of a junction, and it and the runs it joins agree
	local STEP = 2
	local function cellAt(x: number, z: number): number
		return (x // STEP + 4096) * 8192 + (z // STEP + 4096)
	end
	local onTop: { [number]: boolean } = {}
	local inHall: { [number]: boolean } = {}
	local inUnit: { [number]: boolean } = {}
	local function paint(into: { [number]: boolean }, r: Rect)
		for x = r.x0, r.x1 - STEP, STEP do
			for z = r.z0, r.z1 - STEP, STEP do
				into[cellAt(x, z)] = true
			end
		end
	end
	for _, c in f.cells do
		for _, r in walkable(c) do
			paint(inHall, r)
		end
	end
	type Top = { r: Rect, front: number? }
	local tops: { Top } = {}
	for i, s in f.slots do
		if s.top then
			table.insert(tops, { r = rects[i], front = s.facing })
		end
	end
	for li, l in f.lids do
		local c = f.cells[l.cell]
		local r = rect(Floor.footprint(l))
		ok(c.kind ~= "Lobby" and c.kind ~= "Straight", `{where}: lid {li} outside a junction`)
		ok(
			r.x0 >= c.x - HALF and r.x1 <= c.x + HALF and r.z0 >= c.z - HALF and r.z1 <= c.z + HALF,
			`{where}: lid {li} off its junction's square`
		)
		ok(l.size == "S" and r.x1 - r.x0 == 8 and r.z1 - r.z0 == 8, `{where}: lid {li} not 8 by 8`)
		for i in f.slots do
			ok(overlap(r, rects[i]) == nil, `{where}: lid {li} over slot {i}`)
		end
		for _, w in walkable(c) do
			ok(overlap(r, w) == nil, `{where}: lid {li} over the hall`)
		end
		ok(#l.runs > 0, `{where}: lid {li} reached by no run`)
		for _, run in l.runs do
			ok(table.find(f.runs[run].lids, li) ~= nil, `{where}: lid {li} and run {run} disagree`)
		end
		table.insert(tops, { r = r, front = nil })
	end
	for r, run in f.runs do
		for _, li in run.lids do
			ok(table.find(f.lids[li].runs, r) ~= nil, `{where}: run {r} and lid {li} disagree`)
		end
	end
	for _, t in tops do
		paint(onTop, t.r)
	end
	for i, s in f.slots do
		if s.kind == "Unit" then
			paint(inUnit, rects[i])
		end
	end
	local function onDeadEnd(vertical: boolean, line: number, t: number): boolean
		for _, e in f.deadEnds do
			local fx = dir(e.facing)
			if (fx ~= 0) == vertical then
				local eLine, eAlong = if vertical then e.x else e.z, if vertical then e.z else e.x
				if eLine == line and t >= eAlong - SPAN / 2 and t + STEP <= eAlong + SPAN / 2 then
					return true
				end
			end
		end
		return false
	end
	local function edge(vertical: boolean, line: number, t: number): string
		return `{if vertical then "x" else "z"}{line}:{t}`
	end
	-- the cells either side of an edge, the lower x (or z) first
	local function besideEdge(vertical: boolean, line: number, t: number): (number, number)
		if vertical then
			return cellAt(line - STEP, t), cellAt(line, t)
		end
		return cellAt(t, line - STEP), cellAt(t, line)
	end
	local panelled: { [string]: boolean } = {}
	for pi, p in f.panels do
		local fx, fz = dir(p.facing)
		local vertical = fx ~= 0
		local line = if vertical then p.x else p.z
		local middle = if vertical then p.z else p.x
		local half = Floor.Sizes[p.size].width / 2
		local looksAtTops = false
		for t = middle - half, middle + half - STEP, STEP do
			local k = edge(vertical, line, t)
			ok(not panelled[k], `{where}: two panels on one stretch, {k}`)
			panelled[k] = true
			local lo, hi = besideEdge(vertical, line, t)
			ok(not (onTop[lo] and onTop[hi]), `{where}: panel {pi} across the tops' way at {k}`)
			ok(not inHall[lo] and not inHall[hi], `{where}: panel {pi} in a hall at {k}`)
			local into = if fx + fz > 0 then hi else lo
			if onTop[into] then
				looksAtTops = true
			end
			ok(
				not (p.bare and inUnit[into]),
				`{where}: panel {pi}'s bare sheet inside a unit at {k}`
			)
		end
		ok(looksAtTops, `{where}: panel {pi} looks away from the tops`)
	end
	for _, t in tops do
		local r = t.r
		for d = 0, 3 do
			if d == t.front then
				continue
			end
			local vertical = d % 2 == 0
			local line = if d == 0 then r.x1 elseif d == 2 then r.x0 elseif d == 1 then r.z1 else r.z0
			local from, to = if vertical then r.z0 else r.x0, if vertical then r.z1 else r.x1
			for at = from, to - STEP, STEP do
				local lo, hi = besideEdge(vertical, line, at)
				local outside = if d == 0 or d == 1 then hi else lo
				if not (onTop[outside] or inHall[outside] or onDeadEnd(vertical, line, at)) then
					ok(
						panelled[edge(vertical, line, at)] == true,
						`{where}: the tops open at {edge(vertical, line, at)}`
					)
				end
			end
		end
	end
	mostPanels = math.max(mostPanels, #f.panels)
	mostLids = math.max(mostLids, #f.lids)

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

-- the side names: a door looking -Z, you face +Z to see it, so its left wall is toward +X
ok(Floor.sideDir({ facing = 3 } :: any, "left") == 0, "a slot's left is your left facing its door") -- any: only facing is read
ok(Floor.sideDir({ facing = 3 } :: any, "back") == 1, "a slot's back is away from the hall") -- any: as above

if failures > 0 then
	error(`{failures} of {checks} floor checks failed`)
end
print(
	`floor: {checks} checks passed over {floors} floors (at most {maxUnits} units; crawl links `
		.. `at least {fewestLinks}, {fewestFirst} before the first fork on floors 1 and 2; at most `
		.. `{mostCutOff} units cut off; top runs {shortestRun} to {longestRun} studs, closed by at most `
		.. `{mostPanels} panels and {mostLids} lids)`
)
