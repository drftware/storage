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
	- `leanTo`, `stands` (S5-03i1c): the mirror leans on a wall, so it stands only on the floor
	  with its back to the back wall or a side wall, its foot its lean off it; carried near one it
	  turns its back to that wall and settles there, as Animal Crossing's wall pieces find a wall.

	Rows come out job box first, so Brix, loading in order, always stands it: it holds everything
	else and is never put away. Poses are on the room's areas (`Spots.room`): the floor's `x` runs
	to the left wall, its `y` toward the door; turn 0 faces the door, 90 the right wall.
]]
local Furniture = require("./Furniture")
local HomeSpecs = require("./Specs")
local Save = require("../Save")
local Sizes = require("./Sizes")
local Spots = require("./Spots")
local Turning = require("./Turning")

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

-- How far a leaning piece's back stands off the wall it leans on, at its foot (studs), so its top
-- rests on the wall: the mirror's, as it stood in XL's room (D-348).
Layout.Lean = table.freeze({
	Mirror = HomeSpecs.Mirror.At[1] + Sizes.of(Sizes.Biggest).across / 2 - (Spots.pieceBox(
		"Mirror"
	) or Spots.Unknown)[3] / 2,
}) :: { [string]: number }
-- How near its wall a leaning piece carried in Arrange finds it (studs, from where it would lean
-- to where the finger holds it): farther out it shows red, leaning on nothing.
Layout.LeanReach = 2
-- Pieces whose back keeps clear of the wall behind it (studs): the job box's lid opens upright,
-- so it stands at least `BoxOff` off a wall, as the layout lays it; pushed nearer in Arrange it
-- stops at that line (`clearOf`), and the server refuses one nearer (D-348).
Layout.Clear = table.freeze({ JobBox = Layout.BoxOff }) :: { [string]: number }
-- How far off its lean a leaning piece may stand and still lean (studs): the wire's rounding, and
-- the fixed set's mirror, adopted where it stood (`stood`), 0.02 nearer its wall than `default`'s.
Layout.LeanSlack = 0.05

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

-- What may be set out, by placed name (S5-03i1b): the furniture you own (`Furniture.settable`)
-- and every starter piece, one each, free.
function Layout.settable(furniture: { [string]: number }): { [string]: number }
	local out = Furniture.settable(furniture)
	for _, piece in Furniture.Starter do
		out[Furniture.placed(piece.id)] = 1
	end
	return out
end

-- The pieces in your job box, by id (S5-03i1b): the furniture you own less what's set out
-- (`Furniture.boxed`), and each starter piece not set out (`placed`, counts by placed name as
-- `Save.placedCounts` gives them): put away, or one the floor couldn't hold.
function Layout.boxed(
	furniture: { [string]: number },
	placed: { [string]: number }
): { [string]: number }
	local out = Furniture.boxed(furniture, placed)
	for _, piece in Furniture.Starter do
		if (placed[Furniture.placed(piece.id)] or 0) < 1 then
			out[piece.id] = 1
		end
	end
	return out
end

-- `rows` with the job box's first (S5-03i1b): Brix loads in order and always stands the first, and
-- the job box holds everything else. The rest keep their order (a piece before what stands on it).
-- A new list.
function Layout.boxFirst(rows: { Save.PlacedRow }): { Save.PlacedRow }
	local box = Layout.id("JobBox")
	local out: { Save.PlacedRow } = {}
	for _, row in rows do
		if row.id == box then
			table.insert(out, 1, row)
		else
			table.insert(out, row)
		end
	end
	return out
end

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

-- `rows` with the job box among them: it holds everything, so a save that lost it (the shrink
-- before D-349 boxed it) gets it back first, where room `room`'s size lays it. New rows when it
-- was missing; else `rows` itself.
function Layout.withBox(
	rows: { Save.PlacedRow },
	room: { [string]: Spots.RoomArea }
): { Save.PlacedRow }
	local id = Layout.id("JobBox")
	for _, row in rows do
		if row.id == id then
			return rows
		end
	end
	local floor = room.Floor
	local at = if floor then wallPlaces(floor.width, floor.depth).JobBox else nil
	if not at then
		return rows
	end
	local out = { { id = id, on = "Floor", x = at[1], y = at[2], turn = at[3] } }
	for _, row in rows do
		table.insert(out, row)
	end
	return out
end

-- Saved rows laid in room `from` as the home changes size to room `to` (`Spots.room` at each).
-- Grown, your arrangement keeps: a starter piece on the floor whose back (or side) is against a
-- wall of `from` rides that wall to where it stands in `to`, as far along it (in a corner it
-- rides both), kept inside the floor. Shrunk (D-349), the size's own layout comes first: Small
-- sits at the door's end of the unit, so carried, every piece fell outside it. Either way a piece
-- takes the first of its own place and the size's layout spot that's on the floor and clear of
-- the pieces laid before it (`Order`, the job box first, so it always stands); with neither, it's
-- left where it rode, for Brix to box. Everything else is carried as `Spots.carry` carries it,
-- and what stands on a piece rides it. New rows.
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
	local shrank = b.width < a.width - EPSILON or b.depth < a.depth - EPSILON
	local at = wallPlaces(b.width, b.depth)
	local laid: { Rect } = {}
	local function clear(r: Rect): boolean
		if not inside(r, b) then
			return false
		end
		for _, other in laid do
			if overlaps(r, other) then
				return false
			end
		end
		return true
	end
	-- `v` kept so a half size `h` stays within `half` of the middle (the middle when it can't)
	local function within(v: number, h: number, half: number): number
		return if h > half then 0 else math.clamp(v, -(half - h), half - h)
	end
	for _, kind in Layout.Order do
		local i: number? = nil
		for j, row in rows do
			if row.id == Layout.id(kind) and row.on == "Floor" then
				i = j
				break
			end
		end
		if not i then
			continue -- in the box, or on a top: it rides what it stands on
		end
		local row, new = rows[i], out[i] -- carried: its place in the unit kept
		local r = rect(kind, row.x, row.y, row.turn)
		local left = r.x + r.hx >= a.width / 2 - Layout.Touch
		local right = r.x - r.hx <= -a.width / 2 + Layout.Touch
		if left and not right then -- the left wall
			new.x = b.width / 2 - (a.width / 2 - row.x)
		elseif right and not left then -- the right wall
			new.x = -b.width / 2 + (row.x + a.width / 2)
		end -- across both (Small's shelf): it keeps its middle
		if r.y - r.hy <= -a.depth / 2 + Layout.Touch then -- the back wall
			new.y = -b.depth / 2 + (row.y + a.depth / 2)
		end
		new.x, new.y = within(new.x, r.hx, b.width / 2), within(new.y, r.hy, b.depth / 2)
		local mine = { new.x, new.y, new.turn }
		local size: { number }? = at[kind]
		if kind == "Rug" then
			local rug = rugIn(b, laid)
			size = if rug then { rug.x, rug.y, rug.turn } else nil
		end
		local first: { number }?, second: { number }? = mine, size
		if shrank then
			first, second = size, mine
		end
		for n = 1, 2 do
			local p = if n == 1 then first else second
			local pr = if p then rect(kind, p[1], p[2], p[3]) else nil
			if p and pr and clear(pr) then
				new.x, new.y, new.turn = p[1], p[2], p[3]
				table.insert(laid, pr)
				break
			end
		end
	end
	return out
end

-- A pose on one of the room's areas, as Brix takes it.
export type Pose = { on: string, x: number, y: number, turn: number }
-- The floor's size, as Brix and `Spots.room` give it.
export type Floor = { width: number, depth: number }

-- How far one corner of a piece's back, at `px`, `py` on floor `floor`, has straight back (the
-- way `bx`, `by` its back faces) before a wall.
local function roomFrom(px: number, py: number, bx: number, by: number, floor: Floor): number
	local room = math.huge
	if bx > 0 then
		room = (floor.width / 2 - px) / bx
	elseif bx < 0 then
		room = (-floor.width / 2 - px) / bx
	end
	if by > 0 then
		room = math.min(room, (floor.depth / 2 - py) / by)
	elseif by < 0 then
		room = math.min(room, (-floor.depth / 2 - py) / by)
	end
	return room
end

-- How far piece `kind` at `pose` stands with its back off the walls behind it: from each corner
-- of its back straight back to the nearest wall, the nearer of the two. A piece's back is its
-- box's far side from the way it faces: the back wall at turn 0, the left wall at 90, the door's
-- wall at 180, the right wall at 270; set at any angle with Free (S5-03j2b2a), it backs onto a
-- corner and both its walls count.
local function backGap(kind: string, pose: Pose, floor: Floor): number
	local box = Spots.pieceBox(kind) or Spots.Unknown
	local c, s = Turning.facing(pose.turn)
	local bx, by = s, -c -- the way its back faces
	local w, d = box[1] / 2, box[3] / 2
	local x, y = pose.x + d * bx, pose.y + d * by -- its back's middle
	return math.min(
		roomFrom(x + w * c, y + w * s, bx, by, floor),
		roomFrom(x - w * c, y - w * s, bx, by, floor)
	)
end

-- Whether piece `kind` may stand at `pose` in a room with floor `floor`: a leaning piece
-- (`Lean`) only on the floor itself, its back to the back wall or a side wall at its lean; any
-- other piece wherever Brix lets it. The server refuses a Place that breaks this (D-348).
function Layout.stands(kind: string, pose: Pose, floor: Floor): boolean
	local clear = Layout.Clear[kind]
	if clear then -- the job box's lid opens upright behind it
		local gap = if pose.on == "Floor" then backGap(kind, pose, floor) else nil
		return gap == nil or gap >= clear - Layout.LeanSlack
	end
	local lean = Layout.Lean[kind]
	if not lean then
		return true
	end
	local turn = Turning.round(pose.turn)
	if pose.on ~= "Floor" or turn % Turning.Quarter ~= 0 or turn == 180 then
		return false -- on the rug or a top, turned off square, or against the door: it leans on nothing
	end
	return math.abs(backGap(kind, pose, floor) - lean) <= Layout.LeanSlack
end

-- `pose` for piece `kind` (`Clear`) pushed out from the wall behind it, so its back stands at
-- least its clearance off it: the job box slides up to that line and stops, its lid's room kept.
-- Any other piece's pose, or one on a top, as it is.
function Layout.clearOf(kind: string, pose: Pose, floor: Floor): Pose
	local clear = Layout.Clear[kind]
	local gap = if clear and pose.on == "Floor" then backGap(kind, pose, floor) else nil
	if not (clear and gap and gap < clear) then
		return pose
	end
	local push = clear - gap
	-- out along its front, the way its back doesn't face, at whatever turn it stands
	local c, sn = Turning.facing(pose.turn)
	return { on = pose.on, x = pose.x - sn * push, y = pose.y + c * push, turn = pose.turn }
end

-- `pose` for leaning piece `kind` carried to the wall nearest its middle (the back wall or a
-- side; never the door's): turned to face the room, its back at its lean off that wall, as far
-- along it as it was and kept inside the floor. Nil when no wall is within `LeanReach` or it
-- isn't on the floor. Any other piece's pose as it is.
function Layout.leanTo(kind: string, pose: Pose, floor: Floor): Pose?
	local lean = Layout.Lean[kind]
	if not lean then
		return pose
	elseif pose.on ~= "Floor" then
		return nil
	end
	local on: string = pose.on
	local box = Spots.pieceBox(kind) or Spots.Unknown
	local off, along = lean + box[3] / 2, box[1] / 2 -- its middle off the wall; half its width
	local hw, hd = floor.width / 2, floor.depth / 2
	local back, left, right = pose.y + hd, hw - pose.x, pose.x + hw
	local nearest = math.min(back, left, right)
	if nearest - off > Layout.LeanReach then
		return nil
	end
	local function within(v: number, half: number): number
		return math.clamp(v, -math.max(0, half - along), math.max(0, half - along))
	end
	if nearest == back then
		return { on = on, x = within(pose.x, hw), y = -hd + off, turn = 0 }
	elseif nearest == left then
		return { on = on, x = hw - off, y = within(pose.y, hd), turn = 90 }
	end
	return { on = on, x = -hw + off, y = within(pose.y, hd), turn = 270 }
end

return table.freeze(Layout)
