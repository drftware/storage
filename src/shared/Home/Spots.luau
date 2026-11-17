--!strict
--[[
	Spots, pure (S5-03e2, D-308): where a find may stand when you set it out in your home, and how
	much room it takes there. The moment: you set your lava lamp on the job box and it stays,
	for you and every friend who walks in, after a rejoin too. Precedents: Bloxburg's build mode
	(floor, wall and tabletop items on a grid), Animal Crossing's things on tables.

	Brix's Placements judges every move (D-306); this file gives it the home's side:

	- Each find's spot (`spot`): Floor (it stands only on the floor), Tabletop (the floor, the
	  shelf's and the job box's tops, or a find's own top), Wall (hung, its back to a wall) or
	  Ceiling (hung from it). A find not listed is a Tabletop.
	- Its footprint (`shape`) from its art's box (Finds.box: across its front, up, front to back):
	  across by front-to-back on a floor, a top or the ceiling, across by up on a wall. A few finds
	  with a flat top offer it for others to stand on (`Rows`' `top`).
	- The room (`room`): the unit's floor, ceiling, back wall and side walls, from its XL slot's
	  inside box; the front wall is the door's. And the starter set's tops (`Furniture`).
	- The limit by the unit's size (`Sizes`): 25, 50, 100 and 150 (the home doc's idea 15).
	- A find set out is named by its id (`id`): its find's name and a number, "Teddy#2".
	- What a screen sends is checked here before anything reads it (`ask`).

	Areas are given in the unit's frame (the starter set's: X across, Y up, Z in from the door,
	`Home.Specs.Starter`): an origin, the face's normal (out of the surface, into the room) and
	`across`, the way an area's `x` runs. Its `y` runs square to both, `normal` crossed with
	`across`, so a find at turn 0 faces down `y`: toward the door on the floor and the ceiling, up
	on a wall, out of the front of the shelf and the job box. Turning these into the world is
	`Home.Arranged`'s.
]]
local Save = require("../Save")
local HomeSpecs = require("./Specs")

local Spots = {}

export type Vec = { number }

-- Where a find may stand.
export type Spot = "Floor" | "Tabletop" | "Wall" | "Ceiling"

-- A flat area, as Brix's Placements takes it (`Brix.PlacementArea`).
export type Area = { kind: string, width: number, depth: number }

-- A find's footprint and where it may stand, as Brix's Placements takes it (`Brix.PlacementShape`).
export type Shape = { width: number, depth: number, fits: { string }, top: Area? }

-- A pose, as Brix's Placements takes it (`Brix.PlacementPose`).
export type Pose = { on: string, x: number, y: number, turn: number }

-- One of the room's areas in the unit's frame: its Brix area, and where its face is.
export type RoomArea = Area & { origin: Vec, normal: Vec, across: Vec }

-- A find's own row: its spot, and whether it offers its top.
export type Row = { spot: Spot, top: boolean? }

-- The kinds of area Brix judges by (each shape's `fits` names them).
Spots.Kinds = table.freeze({ Floor = "floor", Top = "top", Wall = "wall", Ceiling = "ceiling" })

-- The kinds of area a find of `spot` fits, as a new list.
local function fits(spot: Spot): { string }
	if spot == "Floor" then
		return { Spots.Kinds.Floor }
	elseif spot == "Wall" then
		return { Spots.Kinds.Wall }
	elseif spot == "Ceiling" then
		return { Spots.Kinds.Ceiling }
	end
	return { Spots.Kinds.Floor, Spots.Kinds.Top }
end

-- Finds that aren't a Tabletop, and those whose flat top others stand on, by base name (a Gold
-- stands as its find). Everything else stands on the floor or on a top, and offers none.
Spots.Rows = table.freeze({
	NeonSign = { spot = "Wall" }, -- a sign hangs on a wall
	SingingFish = { spot = "Wall" }, -- a mounted fish's plaque goes on the wall
	DiscoBall = { spot = "Ceiling" }, -- turns hung from the ceiling
	RCCar = { spot = "Floor" }, -- a car on the floor, ready to drive
	Skates = { spot = "Floor" }, -- left by the door, not on a table
	Television = { spot = "Tabletop", top = true }, -- a portable TV's flat top holds a small find
	ToyDrum = { spot = "Tabletop", top = true }, -- the drum's skin is flat
} :: { [string]: Row })

-- A find with no art box (not in the place yet): a stud each way, so it still stands somewhere.
Spots.Unknown = { 1, 1, 1 } :: Vec
-- No footprint is thinner than this (studs): a flat find still covers its spot.
Spots.Least = 0.25
-- What a top keeps clear round its edge (studs a side): a find set on one doesn't overhang.
Spots.Rim = 0.1

-- The unit's sizes (D-259 idea 30, S5-03h), smallest first, and how many finds each holds set
-- out (idea 15). Everyone starts Small.
Spots.Sizes = table.freeze({
	{ name = "Small", limit = 25 },
	{ name = "Medium", limit = 50 },
	{ name = "Large", limit = 100 },
	{ name = "XL", limit = 150 },
})
Spots.Start = "Small"

-- The starter set's pieces whose tops take a find (`Home.Specs.Starter`), by area name: the piece
-- and the part whose box is its top (`Home.Specs.Parts`).
Spots.Furniture = table.freeze({
	ShelfTop = { piece = "Shelf", part = "Shelf" },
	JobBoxTop = { piece = "JobBox", part = "JobBoxLid" },
} :: { [string]: { piece: string, part: string } })

-- The remotes (in ReplicatedStorage.Remotes): Place(what, on, x, y, turn) sets a find out of your
-- job box (`what` a find's name) or moves one set out (`what` its id); PutAway(id) puts it back in
-- the box; Arranged(what, id, refusal) answers the asker ("" when it stood).
Spots.RemoteFolder = "Remotes"
Spots.PlaceRemote = "ArrangePlace"
Spots.PutAwayRemote = "ArrangePutAway"
Spots.AnswerRemote = "Arranged"
-- Asks per player: a drag sends one Place as it's let go, so this is far past a fast hand.
Spots.Limit = { perSecond = 6, burst = 12 }
-- A find set out, drawn in its home: tagged, with its id and its owner's UserId.
Spots.Tag = "PlacedFind"
Spots.IdAttribute = "PlacedId"
Spots.OwnerAttribute = "PlacedOwner"
-- The refusals the home adds to Brix's: a find you have none of in your box, a find the game
-- doesn't know, a home that isn't yours (or a save newer than this server).
Spots.Refusals =
	table.freeze({ NotInBox = "notInBox", Unknown = "unknownFind", NotYours = "notYours" })

-- The longest name or id a screen may send, and how far from an area's middle a pose may be.
local LONGEST = 80
local FARTHEST = 100

-- A Gold ("Teddy:Gold") is its find's spot and size.
local function base(name: string): string
	return string.match(name, "^(.-):") or name
end

-- Where find `name` may stand.
function Spots.spot(name: string): Spot
	local row = Spots.Rows[base(name)]
	if row then
		return row.spot
	end
	return "Tabletop"
end

-- Up to the next twentieth of a stud, never under `Spots.Least`.
local function rounded(v: number): number
	return math.max(Spots.Least, math.ceil(v * 20 - 1e-6) / 20)
end

-- Find `name`'s footprint, from its art's box `box` (across its front, up, front to back; nil when
-- the place lacks its art), and the kinds of area it fits. A new table each call.
function Spots.shape(name: string, box: Vec?): Shape
	local b = box or Spots.Unknown
	local spot: Spot = Spots.spot(name)
	local shape: Shape = {
		width = rounded(b[1]),
		depth = rounded(if spot == "Wall" then b[2] else b[3]),
		fits = fits(spot),
	}
	local row = Spots.Rows[base(name)]
	if row and row.top then
		shape.top = {
			kind = Spots.Kinds.Top,
			width = math.max(Spots.Least, b[1] - 2 * Spots.Rim),
			depth = math.max(Spots.Least, b[3] - 2 * Spots.Rim),
		}
	end
	return shape
end

-- How far a find's top stands above what it stands on, from its art's box (studs): its height.
function Spots.topHeight(box: Vec?): number
	return (box or Spots.Unknown)[2]
end

-- The finds a home of size `name` holds set out; the smallest's for a size not known.
function Spots.limit(name: string): number
	for _, s in Spots.Sizes do
		if s.name == name then
			return s.limit
		end
	end
	return Spots.Sizes[1].limit
end

-- How many of a room's placed things (`rows`, as Placements saves them) are finds set out: the
-- room's own pieces never count against the limit.
function Spots.setOut(rows: { Save.PlacedRow }): number
	local n = 0
	for _, row in rows do
		if Spots.name(row.id) then
			n += 1
		end
	end
	return n
end

-- The limit bar (Bloxburg's build budget): how full it stands, 0 to 1, with `count` finds set out
-- of `limit`, and whether it's full (a find in the box can't come out; one set out still moves).
function Spots.fill(count: number, limit: number): (number, boolean)
	if limit <= 0 then
		return 1, true
	end
	return math.clamp(count / limit, 0, 1), count >= limit
end

-- The room's areas, in the unit's frame, from its inside box's middle `centre` and its size
-- `size` (across, tall, deep). The front wall is the door's, so it holds nothing.
function Spots.room(centre: Vec, size: Vec): { [string]: RoomArea }
	local cx, cy, cz = centre[1], centre[2], centre[3]
	local across, tall, deep = size[1], size[2], size[3]
	local floor, ceiling = Spots.Kinds.Floor, Spots.Kinds.Ceiling
	local wall = Spots.Kinds.Wall
	return {
		-- `y` toward the door, `x` across to the left as you look in
		Floor = {
			kind = floor,
			width = across,
			depth = deep,
			origin = { cx, cy - tall / 2, cz },
			normal = { 0, 1, 0 },
			across = { 1, 0, 0 },
		},
		Ceiling = {
			kind = ceiling,
			width = across,
			depth = deep,
			origin = { cx, cy + tall / 2, cz },
			normal = { 0, -1, 0 },
			across = { -1, 0, 0 },
		},
		-- each wall's `x` runs to your right as you face it, its `y` up
		BackWall = {
			kind = wall,
			width = across,
			depth = tall,
			origin = { cx, cy, cz + deep / 2 },
			normal = { 0, 0, -1 },
			across = { -1, 0, 0 },
		},
		LeftWall = {
			kind = wall,
			width = deep,
			depth = tall,
			origin = { cx + across / 2, cy, cz },
			normal = { -1, 0, 0 },
			across = { 0, 0, 1 },
		},
		RightWall = {
			kind = wall,
			width = deep,
			depth = tall,
			origin = { cx - across / 2, cy, cz },
			normal = { 1, 0, 0 },
			across = { 0, 0, -1 },
		},
	}
end

-- A starter piece's top as an area, from its top part's box (`Home.Specs.Parts`: its size and
-- middle in the piece's frame), and how high it stands in the piece's frame.
function Spots.furnitureTop(partSize: Vec, partCentre: Vec): (Area, number)
	return {
		kind = Spots.Kinds.Top,
		width = math.max(Spots.Least, partSize[1] - 2 * Spots.Rim),
		depth = math.max(Spots.Least, partSize[3] - 2 * Spots.Rim),
	},
		partCentre[2] + partSize[2] / 2
end

-- One of the room's own things a find can't stand in (`blocks`): its footprint posed on its area.
export type Block = { id: string, shape: Shape, pose: Pose }

-- The starter pieces that lie flat, so a find stands on them as on the floor.
Spots.Underfoot = table.freeze({ Rug = true })

-- Point `p` (the unit's frame) on area `area`'s face: its `x` and `y` from the area's middle.
local function onArea(area: RoomArea, p: Vec): (number, number)
	local o, a, n = area.origin, area.across, area.normal
	local dx, dy, dz = p[1] - o[1], p[2] - o[2], p[3] - o[3]
	local yx, yy, yz =
		n[2] * a[3] - n[3] * a[2], n[3] * a[1] - n[1] * a[3], n[1] * a[2] - n[2] * a[1]
	return dx * a[1] + dy * a[2] + dz * a[3], dx * yx + dy * yy + dz * yz
end

-- Something fixed in the room on one of its areas (the ceiling's lamp, the mirror): its id, its
-- area, its middle in the unit's frame, and its size along the area's `x` and `y`.
export type Fixed = { id: string, on: string, at: Vec, width: number, depth: number }

-- The room's own things (S5-03e2b): each starter piece that stands on the floor (`starter`, its
-- parts' boxes `parts` by the piece's part names `pieces`, as `Home.Specs` has them; the rug lies
-- flat) and what else is `fixed` in it, as footprints posed on `room`'s areas. Their ids are the
-- pieces' names, never a find's (`Spots.name` gives nil), so none is saved or put away. A new list.
function Spots.blocks(
	room: { [string]: RoomArea },
	starter: { HomeSpecs.Placed },
	pieces: { [string]: { string } },
	parts: { [string]: HomeSpecs.Part },
	fixed: { Fixed }
): { Block }
	local out: { Block } = {}
	local floor = room.Floor
	for _, s in starter do
		local names = pieces[s.Kind]
		if Spots.Underfoot[s.Kind] or not names or not floor then
			continue
		end
		local lowX, highX, lowZ, highZ = math.huge, -math.huge, math.huge, -math.huge
		for _, name in names do
			local p = parts[name]
			if p then
				lowX = math.min(lowX, p.Centre[1] - p.Size[1] / 2)
				highX = math.max(highX, p.Centre[1] + p.Size[1] / 2)
				lowZ = math.min(lowZ, p.Centre[3] - p.Size[3] / 2)
				highZ = math.max(highZ, p.Centre[3] + p.Size[3] / 2)
			end
		end
		if lowX >= highX or lowZ >= highZ then
			continue
		end
		-- its parts' middle, turned with the piece about Y, from its origin
		local ox, oz = (lowX + highX) / 2, (lowZ + highZ) / 2
		local t = math.rad(s.Turn)
		local c, sn = math.cos(t), math.sin(t)
		local at = { s.At[1] + ox * c + oz * sn, floor.origin[2], s.At[3] - ox * sn + oz * c }
		local x, y = onArea(floor, at)
		table.insert(out, {
			id = s.Kind,
			shape = { width = highX - lowX, depth = highZ - lowZ, fits = { Spots.Kinds.Floor } },
			pose = { on = "Floor", x = x, y = y, turn = s.Turn % 360 },
		})
	end
	for _, f in fixed do
		local area = room[f.on]
		if area then
			local x, y = onArea(area, f.at)
			table.insert(out, {
				id = f.id,
				shape = { width = f.width, depth = f.depth, fits = { area.kind } },
				pose = { on = f.on, x = x, y = y, turn = 0 },
			})
		end
	end
	return out
end

-- Find `name`'s `n`th set out: "Teddy#2".
function Spots.id(name: string, n: number): string
	return `{name}#{n}`
end

-- The find an id names, or nil when it names none (an area, or anything else).
Spots.name = Save.placedName

-- The first id of find `name` that `taken` says is free.
function Spots.nextId(name: string, taken: (id: string) -> boolean): string
	local n = 1
	while taken(Spots.id(name, n)) do
		n += 1
	end
	return Spots.id(name, n)
end

local function word(v: unknown): string?
	return if type(v) == "string" and #v >= 1 and #v <= LONGEST then v else nil
end

local function within(v: unknown, far: number): number?
	return if type(v) == "number" and v == v and v >= -far and v <= far then v else nil
end

-- A screen's ask checked before anything reads it: `what` and `on` short words, `x` and `y`
-- numbers near the area, `turn` a number of degrees, brought round to 0 up to 360. Nil if any is
-- wrong.
function Spots.ask(
	what: unknown,
	on: unknown,
	x: unknown,
	y: unknown,
	turn: unknown
): (string?, Pose?)
	local w, o = word(what), word(on)
	local px, py = within(x, FARTHEST), within(y, FARTHEST)
	local t = within(turn, 3600)
	if not (w and o and px and py and t) then
		return nil, nil
	end
	local round = t % 360
	return w, { on = o, x = px, y = py, turn = if round >= 360 then 0 else round }
end

-- A PutAway ask's id checked: a short word naming a find, or nil.
function Spots.askId(id: unknown): string?
	local w = word(id)
	return if w and Spots.name(w) then w else nil
end

-- Saved rows trimmed to what you may set out (`available` by name: what you own less your shelf
-- and what's out of your box), oldest first: a row past what you own, or one that names no find,
-- is left out and goes back in the box. The rows kept, as a new list.
function Spots.owned(rows: { Save.PlacedRow }, available: Save.Counts): { Save.PlacedRow }
	local used: Save.Counts = {}
	local kept: { Save.PlacedRow } = {}
	for _, row in rows do
		local name = Spots.name(row.id)
		if name and (used[name] or 0) < math.floor(available[name] or 0) then
			used[name] = (used[name] or 0) + 1
			table.insert(kept, row)
		end
	end
	return kept
end

return table.freeze(Spots)
