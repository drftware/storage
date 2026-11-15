--!strict
--[[
	PackedLayout: where a packed unit's blocks of boxes stand (B-05b1, D-216), the numbers alone, so
	Lune checks them (tests/packedlayout.spec.luau). The moment it serves: the door lifts on a wall
	of boxes to the ceiling with one dark path through. You squeeze in, the stacks close round the
	camera, and at the back the path turns once into a clearing the doorway can't see, where the
	marked box or a sleeping monster waits. The Mansion level's narrow halls in Piggy and DOORS'
	closets work the same way: you can't see what's round the corner until you're committed.

	The shape, in DealSpot's frame (x across, z in from the doorway's face, the back wall at the
	unit's depth): the path comes straight in up the middle, `Path` wide, from the doorway to the
	back wall, under the landing below the top's hole and under the bulb (both stay where they
	were). Near the back, the stacks on one side stop and the clearing opens off the path along
	the back wall, `Clearing` deep, to that side's wall. Which side, and which blocks, follow the
	unit's number, so a seed's floor looks the same twice.

	Blocks stand in lines, each line's fronts on one edge: across the doorway `DealSpot.Door` in
	(facing the hall), down both sides of the path (facing across it), and along the clearing's
	near side (facing the back wall). Each line starts flush where it meets the path, so the
	path's walls run unbroken, and spreads what's left of its length between its blocks and its
	far end, never a gap wider than `Gap`. Behind the lines is empty floor nobody sees. A low
	stack may stand in the clearing's far corner.

	Every block's reach is its boxes' real reach from its pivot (the generated `Lo`/`Hi`), so no
	two blocks ever run into each other, even at a corner. A block's pivot is the middle of its
	footprint on the floor; it stands at `face * CFrame.new(x, 0, z) * CFrame.Angles(0, rad(yaw), 0)`,
	its front (its -Z) toward the doorway at yaw 0, toward -X at 90 (DealSpot's turn).
]]
local DealSpot = require("./DealSpot")

local PackedLayout = {}

-- How far a block's boxes really reach from its pivot: `left`/`right` along its own X, `front`
-- (toward its LookVector) and `back` along its own Z, all positive. The server and the specs make
-- these from the generated Specs' `Lo` and `Hi` (`PackedLayout.reachOf`).
export type Reach = { left: number, right: number, front: number, back: number }
export type Block = { name: string, x: number, z: number, yaw: number }
export type Layout = {
	-- the side the clearing opens to: -1 toward -X, 1 toward +X
	side: number,
	blocks: { Block },
	-- the path's floor from the doorway's face to the clearing, and the clearing's, each a
	-- rectangle as a polygon (x1, z1, x2, z2, ...)
	path: { number },
	clearing: { number },
	-- where the path turns into the clearing, on the path's middle line: a keeper walking out of
	-- the clearing goes by it, so it never cuts the corner through a stack
	bend: { x: number, z: number },
}

-- Studs across the path. A player is 2 across, so a 3 wide path is a squeeze you walk without
-- scraping, and the Packrat (2.7 across its arms) still fits through. The landing under the top's
-- hole is 3 across too (DealSpot.LandSide), so the path takes it whole.
PackedLayout.Path = 3
-- Studs deep the clearing is, from the back wall in: room for the marked box and a sleeping
-- monster side by side, and for a player to turn round with a monster on them.
PackedLayout.Clearing = 3.2
-- The widest gap between two stacks in a line, studs: dark cracks are what real stacks have,
-- but a body (2 across) never fits through one and nobody reads it as a way in.
PackedLayout.Gap = 1.2
-- Units narrower than this, studs, stay open (D-205: small units are never packed): the path,
-- a stack on each side and the clearing's near stack need about this much.
PackedLayout.Narrowest = 10
-- Of the units, the share (by number) with a low stack in the clearing's far corner.
PackedLayout.HalfShare = 2 / 3

-- The blocks each line draws from. Columns are one box wide; wides two on a wardrobe box laid
-- down, deeper. A path side by the clearing takes columns only, so the clearing's near stack
-- always meets it at the same depth.
local COLUMNS = { "ColumnA", "ColumnB", "ColumnC" }
local WIDES = { "WideA", "WideB" }

-- Park and Miller's generator (every product stays exact in a double), stepped a few times so
-- neighbouring units, lines and slots draw far apart.
local MODULUS = 2147483647
local MULTIPLIER = 48271
local STEPS = 3

-- `Lo` and `Hi` (a block's boxes' reach, Vector3s or anything with X and Z) as a Reach.
function PackedLayout.reachOf(lo: { X: number, Z: number }, hi: { X: number, Z: number }): Reach
	return { left = -lo.X, right = hi.X, front = -lo.Z, back = hi.Z }
end

-- A deterministic draw, 0 to 1, for unit `n`'s line `line`, slot `k`.
local function draw(n: number, line: number, k: number): number
	local s = (n * 7919 + line * 104729 + k * 1299709) % (MODULUS - 1) + 1
	for _ = 1, STEPS do
		s = (s * MULTIPLIER) % MODULUS
	end
	return s / MODULUS
end

-- The blocks for one line `length` studs long, by unit `n`'s draw: their names, front to far end,
-- and the space each takes along the line (at least `pitch`, or its boxes' real width).
local function choose(
	length: number,
	n: number,
	line: number,
	reach: { [string]: Reach },
	pitch: number,
	wides: boolean
): ({ string }, { number })
	local names: { string } = {}
	local widths: { number } = {}
	local used = 0
	local k = 0
	while true do
		k += 1
		local roll = draw(n, line, k)
		local name: string? = nil
		if wides and roll < 0.4 then
			local wide = WIDES[math.floor(roll / 0.4 * #WIDES) + 1]
			local r = reach[wide]
			if r and used + math.max(2 * pitch, r.left + r.right) <= length then
				name = wide
			end
		end
		if not name then
			name = COLUMNS[math.floor(roll * #COLUMNS) % #COLUMNS + 1]
		end
		local r = reach[name :: string]
		local width = math.max(pitch, r.left + r.right)
		if used + width > length + 1e-6 then
			break
		end
		table.insert(names, name :: string)
		table.insert(widths, width)
		used += width
	end
	return names, widths
end

--[[
	Lays one line of blocks: from `start` (where it meets the path, flush) along `dir` (1 or -1)
	for `length` studs, each block's front on the line `front` (at a fixed z with `across` false,
	or a fixed x with `across` true), facing `yaw`. What the length leaves over is spread after
	each block, the last share at the far end. Its blocks go in `out`; the deepest reach behind
	the line any of them has comes back.
]]
local function line(
	out: { Block },
	names: { string },
	widths: { number },
	reach: { [string]: Reach },
	start: number,
	dir: number,
	length: number,
	front: number,
	inward: number,
	yaw: number,
	alongX: boolean
): number
	local used = 0
	for _, w in widths do
		used += w
	end
	local spare = if #widths > 0 then (length - used) / #widths else 0
	local at = start
	local deepest = 0
	for i, name in names do
		local r = reach[name]
		local w = widths[i]
		-- the block's middle along the line; its boxes sit evenly in its share
		local mid = at + dir * w / 2
		-- the pivot sits its front reach behind the line, into the stack's side
		local depth = front + inward * r.front
		local block: Block = if alongX
			then { name = name, x = mid, z = depth, yaw = yaw }
			else { name = name, x = depth, z = mid, yaw = yaw }
		table.insert(out, block)
		deepest = math.max(deepest, r.front + r.back)
		at += dir * (w + spare)
	end
	return deepest
end

--[[
	The packed layout of unit `unit` (DealSpot's measure), number `number` ("214"), from the
	blocks' real reach (`reach`, by name: ColumnA to C, WideA and B, Half) and their `pitch`
	(`Packed.Specs.Pitch`). Nil for a unit too narrow to pack (`Narrowest`).
]]
function PackedLayout.lay(
	unit: DealSpot.Unit,
	number: string,
	reach: { [string]: Reach },
	pitch: number
): Layout?
	if unit.width < PackedLayout.Narrowest or unit.depth < PackedLayout.Narrowest then
		return nil
	end
	local n = math.floor(math.abs(tonumber(number) or 0))
	-- worked out with the clearing toward -X, then turned the unit's way: x times `m`, and a
	-- facing across (yaw 90 faces -X) turned round
	local side = if n % 2 == 0 then -1 else 1
	local m = -side
	local W = unit.width / 2 - DealSpot.Wall -- the floor's edge at the side walls
	local B = unit.depth - DealSpot.Wall -- and at the back wall
	local F = DealSpot.Door -- the doorway line's fronts
	local P = PackedLayout.Path / 2
	local blocks: { Block } = {}

	-- 1. Across the doorway, facing the hall: the clearing's side (-X) from the path out to the
	-- wall (columns only, so the path's side behind it starts at a column's depth), then the far
	-- side. Each meets the path flush.
	local nearNames, nearWidths = choose(W - P, n, 1, reach, pitch, false)
	local nearDeep = line(blocks, nearNames, nearWidths, reach, -P, -1, W - P, F, 1, 0, true)
	local farNames, farWidths = choose(W - P, n, 2, reach, pitch, true)
	local farDeep = line(blocks, farNames, farWidths, reach, P, 1, W - P, F, 1, 0, true)
	-- the first block of each line (the one at the path) decides where the path's sides start
	local function backOf(names: { string }, deepest: number): number
		local first = names[1]
		return F + (if first then reach[first].front + reach[first].back else deepest)
	end
	local nearBack, farBack = backOf(nearNames, nearDeep), backOf(farNames, farDeep)

	-- 2. The path's sides, facing across it, from behind the doorway line. The clearing's side is
	-- whole columns at the pitch, as many as reach nearest `Clearing` from the back wall, and the
	-- clearing starts where they stop; the far side runs to the back wall.
	local count = math.max(1, math.floor((B - PackedLayout.Clearing - nearBack) / pitch + 0.5))
	local C = nearBack + count * pitch -- the clearing's near edge
	local leftNames, leftWidths = choose(count * pitch, n, 3, reach, pitch, false)
	local leftDeep =
		line(blocks, leftNames, leftWidths, reach, nearBack, 1, count * pitch, -P, -1, -90, false)
	local rightLength = B - farBack
	local rightNames, rightWidths = choose(rightLength, n, 4, reach, pitch, true)
	line(blocks, rightNames, rightWidths, reach, farBack, 1, rightLength, P, 1, 90, false)

	-- 3. The clearing's near side, facing the back wall, from behind the path's side out to the
	-- wall (flush with that side's back, where the two stacks meet).
	local behind = -P - leftDeep
	local nearSideLength = behind + W
	if nearSideLength >= pitch then
		local names, widths = choose(nearSideLength, n, 5, reach, pitch, false)
		line(blocks, names, widths, reach, behind, -1, nearSideLength, C, -1, 180, true)
	end

	-- 4. A low stack in the clearing's far corner, facing the path, its back to the side wall.
	local half = reach.Half
	if half and draw(n, 6, 1) < PackedLayout.HalfShare then
		local along = math.max(pitch, half.left + half.right)
		table.insert(blocks, {
			name = "Half",
			x = -W + half.back,
			z = B - along / 2,
			yaw = -90,
		})
	end

	-- turn it the unit's way
	for _, b in blocks do
		b.x *= m
		if b.yaw == 90 or b.yaw == -90 then
			b.yaw *= m
		end
	end
	local function rect(x1: number, z1: number, x2: number, z2: number): { number }
		local lo, hi = math.min(x1 * m, x2 * m), math.max(x1 * m, x2 * m)
		return { lo, z1, hi, z1, hi, z2, lo, z2 }
	end
	return {
		side = side,
		blocks = blocks,
		path = rect(-P, 0, P, C),
		clearing = rect(-W, C, P, B),
		bend = { x = 0, z = (C + B) / 2 },
	}
end

-- The floor block `block` takes, with `reach` its boxes' reach: a polygon (x1, z1, ...) in the
-- unit's frame, turned as it stands.
function PackedLayout.footprint(block: Block, reach: Reach): { number }
	local across = reach.left + reach.right
	local along = reach.front + reach.back
	-- the footprint's middle, off the pivot toward the side that reaches further
	local lx = (reach.right - reach.left) / 2
	local lz = (reach.back - reach.front) / 2
	local c, s = math.cos(math.rad(block.yaw)), math.sin(math.rad(block.yaw))
	local x = block.x + lx * c + lz * s
	local z = block.z - lx * s + lz * c
	return DealSpot.footprint(x, z, block.yaw, across, along)
end

return PackedLayout
