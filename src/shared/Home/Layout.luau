--!strict
--[[
	Layout, pure (S5-03i1a, D-346): where every home's own pieces stand. The moment: you walk into
	your new unit and it's a room, not a store: the shelf against the back wall, the job box along
	the left wall, the mirror on the right, nothing standing in your way; and every one of them is
	yours to lift, move and turn (D-345; Animal Crossing's house, where the pieces you start with
	move like anything you buy, and Bloxburg's build mode).

	The starter pieces (`Furniture.Starter`) are rows in the save's `placed`, under the furniture
	mark ("Shelf:Furniture#1"), so Brix judges them as it judges bought furniture. This file says
	where they start:

	- `default`: a size's layout, worked out from its floor: the shelf centred on the back wall, the
	  job box then the floor lamp along the left wall, the mirror then the clothes rail along the
	  right wall, each from the shelf's front toward the door; the rug in the floor that's left and
	  the beanbag on the rug's far corner. A piece the floor can't hold starts in the job box: Small
	  (8 by 8) holds the shelf, the box and the mirror.
	- `adopt`: a home laid before this (its save's `starterLaid` false): each piece where it stood
	  if the size holds it, else where the size's layout has it, else in the box; the finds on the
	  shelf's and the job box's tops move onto those pieces' rows, where they were.
	- `grow`: a home that changes size: a piece against a wall rides that wall, so the shelf on
	  Small's back wall is on Medium's back wall, never mid-room.

	Rows come out job box first, so Brix, loading in order, always stands it: it holds everything
	else and is never put away. Poses are on the room's areas (`Spots.room`): the floor's `x` runs
	to the left wall, its `y` toward the door; turn 0 faces the door, 90 the right wall.
]]
local Furniture = require("./Furniture")
local HomeSpecs = require("./Specs")
local Save = require("../Save")
local Sizes = require("./Sizes")
local Spots = require("./Spots")

local Layout = {}

-- A hair kept off a wall (studs), so a piece never sits in the plaster.
Layout.Gap = 0.05
-- Room left between pieces along a wall, and round the rug: a step to stand in.
Layout.Space = 0.3
-- The job box's back off its wall, so its lid opens upright clear of it (art/home/home_spec.py).
Layout.BoxOff = 0.8
-- How close to a wall a piece's back counts as against it when the home grows (the job box's
-- back stands `BoxOff` off its wall).
Layout.Touch = 0.9
-- The beanbag's turn on the floor: a little toward the room, as it always stood.
Layout.BeanbagTurn = 338

-- The order the starter pieces are laid in: the job box first (it always stands), the rug before
-- the beanbag on it.
Layout.Order = table.freeze({ "JobBox", "Shelf", "Mirror", "Rail", "FloorLamp", "Rug", "Beanbag" })

-- A starter piece's row id: "Shelf:Furniture#1".
function Layout.id(kind: string): string
	return Spots.id(Furniture.placed(kind), 1)
end

-- The starter piece a row id names, or nil for anything else.
function Layout.kind(id: string): string?
	local name = Spots.name(id)
	local piece = if name then Furniture.ofPlaced(name) else nil
	return if piece and piece.starter then piece.id else nil
end

-- Whether the save's `placed` rows hold a starter piece already.
local function has(rows: { Save.PlacedRow }, kind: string): boolean
	local id = Layout.id(kind)
	for _, row in rows do
		if row.id == id then
			return true
		end
	end
	return false
end
Layout.has = has

-- A piece's footprint across (floor x) and deep (floor y) at `turn`: its box's bounds turned.
local function extent(kind: string, turn: number): (number, number)
	local box = Spots.pieceBox(kind) or Spots.Unknown
	local t = math.rad(turn)
	local c, s = math.abs(math.cos(t)), math.abs(math.sin(t))
	return box[1] * c + box[3] * s, box[1] * s + box[3] * c
end

-- A footprint on the floor: its middle and its half sizes.
type Rect = { x: number, y: number, hx: number, hy: number }

local function rect(kind: string, x: number, y: number, turn: number): Rect
	local w, d = extent(kind, turn)
	return { x = x, y = y, hx = w / 2, hy = d / 2 }
end

local EPSILON = 1e-4

local function inside(r: Rect, floor: Spots.RoomArea): boolean
	return math.abs(r.x) + r.hx <= floor.width / 2 + EPSILON
		and math.abs(r.y) + r.hy <= floor.depth / 2 + EPSILON
end

local function overlaps(a: Rect, b: Rect): boolean
	return math.abs(a.x - b.x) < a.hx + b.hx - EPSILON
		and math.abs(a.y - b.y) < a.hy + b.hy - EPSILON
end

-- Where on the floor each piece sits by default at a floor `w` across and `d` deep, before
-- checking it fits: x, y, turn; the rug and the beanbag are worked out from what's laid.
local function wallPlaces(w: number, d: number): { [string]: { number } }
	local gap, space = Layout.Gap, Layout.Space
	local _, shelfDeep = extent("Shelf", 0)
	local line = -d / 2 + gap + shelfDeep + space -- the shelf's front: side pieces start here
	local boxX, boxY = extent("JobBox", 90)
	local lampX, lampY = extent("FloorLamp", 0)
	local _, mirrorY = extent("Mirror", 270)
	local _, railY = extent("Rail", 270)
	-- the mirror's foot and the rail's middle stand off their wall as they stood in XL's room
	local xlWall = -Sizes.of(Sizes.Biggest).across / 2
	local mirrorOff = HomeSpecs.Mirror.At[1] - xlWall
	local railOff = HomeSpecs.Rail.At[1] - xlWall
	local boxEnd = line + boxY
	local mirrorEnd = line + mirrorY
	return {
		Shelf = { 0, -d / 2 + gap + shelfDeep / 2, 0 },
		JobBox = { w / 2 - Layout.BoxOff - boxX / 2, line + boxY / 2, 90 },
		FloorLamp = { w / 2 - gap - lampX / 2, boxEnd + space + lampY / 2, 0 },
		Mirror = { -w / 2 + mirrorOff, line + mirrorY / 2, 270 },
		Rail = { -w / 2 + railOff, mirrorEnd + space + railY / 2, 270 },
	}
end

-- A pose on a piece's top from one on the floor: `dx`, `dy` from the piece's middle, the piece
-- turned `turn` (its top's `x` and `y` turn with it).
local function onTop(dx: number, dy: number, turn: number): (number, number)
	local t = math.rad(turn)
	local c, s = math.cos(t), math.sin(t)
	return dx * c + dy * s, -dx * s + dy * c
end

-- The beanbag on rug row `rug` (on the floor), in its far left corner facing the door, or nil
-- when it doesn't fit there.
local function beanbagOn(rug: Save.PlacedRow): Save.PlacedRow?
	local rw, rd = extent("Rug", rug.turn)
	local bw, bd = extent("Beanbag", Layout.BeanbagTurn)
	if bw > rw or bd > rd then
		return nil
	end
	local dx = rw / 2 - bw / 2 - math.min(Layout.Space, (rw - bw) / 2)
	local dy = -rd / 2 + bd / 2 + math.min(Layout.Space, (rd - bd) / 2)
	local x, y = onTop(dx, dy, rug.turn)
	return {
		id = Layout.id("Beanbag"),
		on = Layout.id("Rug"),
		x = x,
		y = y,
		turn = (Layout.BeanbagTurn - rug.turn) % 360,
	}
end

-- The rug in the floor the laid pieces leave (`laid`, footprints), turned whichever way fits,
-- clear of them by `Space` and of the shelf's front; nil when it doesn't fit.
local function rugIn(floor: Spots.RoomArea, laid: { Rect }): Save.PlacedRow?
	local low, high = -floor.width / 2, floor.width / 2
	local back = -floor.depth / 2
	for _, r in laid do
		if r.x + r.hx < 0 then
			low = math.max(low, r.x + r.hx + Layout.Space)
		elseif r.x - r.hx > 0 then
			high = math.min(high, r.x - r.hx - Layout.Space)
		else -- the shelf, across the back
			back = math.max(back, r.y + r.hy + Layout.Space)
		end
	end
	local front = floor.depth / 2
	for _, turn in { 0, 90 } do
		local w, d = extent("Rug", turn)
		if w <= high - low + EPSILON and d <= front - back + EPSILON then
			local row =
				{ id = Layout.id("Rug"), on = "Floor", x = (low + high) / 2, y = 0, turn = turn }
			row.y = math.clamp(0, back + d / 2, front - d / 2)
			local r = rect("Rug", row.x, row.y, turn)
			local clear = true
			for _, other in laid do
				clear = clear and not overlaps(r, other)
			end
			if clear then
				return row
			end
		end
	end
	return nil
end

-- Lays the starter pieces in `order`, each at the first of `places(kind)` that's wholly on the
-- floor and clear of those laid before; one with none fitting is left out (in the job box), but
-- the job box always stands (Brix boxes a find in its way). The beanbag goes on the rug.
local function lay(
	floor: Spots.RoomArea,
	places: (kind: string) -> { { number } }
): { Save.PlacedRow }
	local rows: { Save.PlacedRow } = {}
	local laid: { Rect } = {}
	local rug: Save.PlacedRow? = nil
	for _, kind in Layout.Order do
		if kind == "Rug" then
			rug = rugIn(floor, laid)
			if rug then
				table.insert(rows, rug)
			end
			continue
		elseif kind == "Beanbag" then
			local bag = if rug then beanbagOn(rug) else nil
			if bag then
				table.insert(rows, bag)
			end
			continue
		end
		local candidates = places(kind)
		for i, p in candidates do
			local r = rect(kind, p[1], p[2], p[3])
			local clear = inside(r, floor)
			for _, other in laid do
				clear = clear and not overlaps(r, other)
			end
			if clear or (kind == "JobBox" and i == #candidates) then
				table.insert(
					rows,
					{ id = Layout.id(kind), on = "Floor", x = p[1], y = p[2], turn = p[3] }
				)
				table.insert(laid, r)
				break
			end
		end
	end
	return rows
end

-- Size `size`'s layout of the starter pieces in room `room` (`Spots.room` at that size): new rows,
-- job box first. What the floor can't hold isn't listed: it starts in the job box.
function Layout.default(room: { [string]: Spots.RoomArea }): { Save.PlacedRow }
	local floor = room.Floor
	local at = wallPlaces(floor.width, floor.depth)
	return lay(floor, function(kind: string): { { number } }
		return { at[kind] }
	end)
end

-- Where each starter piece stood while the set was fixed (`Specs.Starter`, the mirror's and the
-- rail's own places), as floor poses in `floor`: its box's middle and its turn.
function Layout.stood(floor: Spots.RoomArea): { [string]: { number } }
	local out: { [string]: { number } } = {}
	local function put(kind: string, at: Spots.Vec, turn: number)
		local box, mid = Spots.pieceBox(kind)
		local ox, oz = if box and mid then mid[1] else 0, if box and mid then mid[3] else 0
		local t = math.rad(turn)
		local c, s = math.cos(t), math.sin(t)
		local px, pz = at[1] + ox * c + oz * s, at[3] - ox * s + oz * c
		out[kind] = { px - floor.origin[1], floor.origin[3] - pz, turn % 360 }
	end
	for _, s in HomeSpecs.Starter do
		put(s.Kind, s.At, s.Turn)
	end
	put("Mirror", HomeSpecs.Mirror.At, HomeSpecs.Mirror.Turn)
	put("Rail", HomeSpecs.Rail.At, HomeSpecs.Mirror.Turn)
	return out
end

-- The tops the fixed set offered (`Spots.Furniture`), by area name, and the piece each now is.
Layout.Tops = table.freeze({ ShelfTop = "Shelf", JobBoxTop = "JobBox" })

-- A home laid before the starter pieces were rows (its save's `starterLaid` false), laid in room
-- `room` at its size: the starter rows (each where it stood if the size holds it, else where the
-- size's layout has it, else left in the box), then the saved `rows` with every find on the
-- shelf's or the job box's top moved onto that piece's row, where it was (the pieces' tops are
-- the same areas, `Spots.StarterTops`). A find in a piece's way is Brix's to box as it loads.
-- New rows.
function Layout.adopt(
	rows: { Save.PlacedRow },
	room: { [string]: Spots.RoomArea }
): { Save.PlacedRow }
	local floor = room.Floor
	local stood = Layout.stood(floor)
	local at = wallPlaces(floor.width, floor.depth)
	local out = lay(floor, function(kind: string): { { number } }
		return { stood[kind], at[kind] }
	end)
	-- the beanbag stood half on the rug: if the rug kept its place, so does the beanbag, on it
	local rug: Save.PlacedRow?, bag: Save.PlacedRow? = nil, nil
	for _, row in out do
		if row.id == Layout.id("Rug") then
			rug = row
		elseif row.id == Layout.id("Beanbag") then
			bag = row
		end
	end
	local was, rugWas = stood.Beanbag, stood.Rug
	if rug and bag and rug.x == rugWas[1] and rug.y == rugWas[2] and rug.turn == rugWas[3] then
		local x, y = onTop(was[1] - rug.x, was[2] - rug.y, rug.turn)
		local w, d = extent("Beanbag", was[3] - rug.turn)
		local rw, rd = extent("Rug", 0)
		if math.abs(x) + w / 2 <= rw / 2 and math.abs(y) + d / 2 <= rd / 2 then
			bag.x, bag.y, bag.turn = x, y, (was[3] - rug.turn) % 360
		end
	end
	for _, row in rows do
		if Layout.kind(row.id) then
			continue -- never twice
		end
		local copy = table.clone(row)
		local piece = Layout.Tops[row.on]
		if piece then
			copy.on = Layout.id(piece)
		end
		table.insert(out, copy)
	end
	return out
end

-- Saved rows laid in room `from` as the home changes size to room `to` (`Spots.room` at each):
-- a starter piece on the floor whose back (or side) is against a wall of `from` rides that wall
-- to where it stands in `to`, as far along it; in a corner it rides both. Everything else is
-- carried as `Spots.carry` carries it. New rows.
function Layout.grow(
	rows: { Save.PlacedRow },
	from: { [string]: Spots.RoomArea },
	to: { [string]: Spots.RoomArea }
): { Save.PlacedRow }
	local out = Spots.carry(rows, from, to)
	local a, b = from.Floor, to.Floor
	if not (a and b) then
		return out
	end
	for i, row in rows do
		local kind = Layout.kind(row.id)
		if not (kind and row.on == "Floor") then
			continue
		end
		local r = rect(kind, row.x, row.y, row.turn)
		local new = out[i] -- carried: its place in the unit kept
		if r.x + r.hx >= a.width / 2 - Layout.Touch then -- the left wall
			new.x = b.width / 2 - (a.width / 2 - row.x)
		elseif r.x - r.hx <= -a.width / 2 + Layout.Touch then -- the right wall
			new.x = -b.width / 2 + (row.x + a.width / 2)
		end
		if r.y - r.hy <= -a.depth / 2 + Layout.Touch then -- the back wall
			new.y = -b.depth / 2 + (row.y + a.depth / 2)
		end
	end
	return out
end

return table.freeze(Layout)
