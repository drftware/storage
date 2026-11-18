--!strict
--[[
	Looks: the paint, paper and floor a player gives their home (S5-03g2b, D-326; idea 18, Animal
	Crossing's wallpaper and flooring, Bloxburg's paint), and their door's colour (S5-03g3a,
	D-329). A save keeps ids from `Specs.Looks`: the paint (the walls' colour), the paper over it,
	the floor, the floor's colour (one of that floor's own, "" for the oak boards, whose colour is
	baked) and the door's. Every look is free for now. Pure: the server judges a pick with it, the
	screens draw with it, Lune tests it (homepick.spec).

	The door is the lobby's, seen by the whole hall, and travels apart from the room: its id on
	the unit (`DoorAttribute`), never in `encode`, so a door pick never stops a wall's wipe. Every
	screen rolls the new colour down the slats (`rollShare`, `DoorRoll`); the server paints the
	door itself `DoorAfter` seconds on, once every roll is done.

	The name card over the door is the hall's too (S5-03g3b, D-331): its style's id (`Specs.Cards`)
	rides on the unit as the door's does (`CardAttribute`), and the server hangs that style's plate
	over the door (CardPlate). Only the Starter styles can be picked until the counter sells the rest.

	A pick isn't instant. The server stamps the new look on the unit (`Attribute`, its start in
	`SinceAttribute`) and dresses the home's panels `Wipe` seconds later (`WornAttribute` then
	says so), while every screen near grows the new look over the old (LooksView): the walls from
	the back wall's middle round both ways to the door, the floor from the back wall to the door.

	Where the walls are, round the room: `around` is studs from the back wall's middle, rightward
	as you face each wall (the panels' U, art/home/panels.py), so a paper's rows carry on round
	the back corners; the left wall's are below zero, the front wall's past the right wall's.
]]
local Specs = require("./Specs")

export type Chosen = {
	paint: string,
	paper: string,
	floor: string,
	floorColour: string,
	door: string,
	card: string,
}
export type Kind = "paint" | "paper" | "floor" | "floorColour" | "door" | "card"
-- What one surface wears: its set's swatch (`Specs.Swatches`) and the part's colour (hex, or ""
-- for white: a baked set's colour is its own).
export type Wear = { set: string, colour: string }

local Looks = {}

Looks.Remote = "PickLook" -- (kind, id) from the Arrange screen, in `Spots.RemoteFolder`
Looks.Attribute = "Look" -- on a held home's unit: `encode` of the look it wears or is changing to
Looks.SinceAttribute = "LookSince" -- the server time the newest pick's wipe began
Looks.WornAttribute = "LookWorn" -- `encode` of what its panels wear now
Looks.FrameAttribute = "LookFrame" -- the unit's frame (CFrame), for the screens' wipes
Looks.Tag = "HomeLook" -- a held home's unit, with the attributes above
Looks.DoorAttribute = "LookDoor" -- on a held home's unit: its door's colour id
Looks.CardAttribute = "LookCard" -- on a held home's unit: its name card's style id
Looks.Folder = "Looks" -- its panels, in the unit
-- How long a new look takes to cross the room: long enough to watch it travel round you, short
-- enough that the next tap of a picker isn't kept waiting.
Looks.Wipe = 1.1
-- Picks a second, and in a burst: quick taps through the chips all land, a flood doesn't.
Looks.Limit = { perSecond = 3, burst = 6 }
-- A new door colour's roll down the slats, on every screen that has the door.
Looks.DoorRoll = table.freeze({
	Seconds = 0.5, -- top to foot: quick enough to watch whole, slow enough to see it travel
	Fade = 0.15, -- one slat's turn: a soft edge running down the door, not a hard line
	Coil = 12, -- slats round an open door's coil, about a wrap: what shows of it from inside
})
-- When the server paints the door itself, after a pick: past every screen's roll, so the
-- replicated colour lands on a door already that colour and nothing snaps.
Looks.DoorAfter = 0.8
-- How far the panels stand off the lobby's walls, and how thick they are (PANEL_PROUD).
Looks.Proud = 0.02

local function find<T>(list: { T }, id: string): T?
	for _, each in list do
		if (each :: any).Id == id then -- any: every list here is of rows with an Id
			return each
		end
	end
	return nil
end

-- Name card style `id`, or nil for one not offered.
function Looks.cardOf(id: string): Specs.CardStyle?
	return find(Specs.Cards, id)
end

-- What still stands between a player and name card style `id` (S5-03g3c): nil when it's theirs
-- (a Starter style, every home's), else how the counter will sell it ("Cash" or "Robux"), the
-- mark its chip wears. A style not offered is "Cash", never pickable. The counter doesn't sell
-- the rest yet, so only the Starter styles are anyone's.
function Looks.cardLock(id: string): ("Cash" | "Robux")?
	local style = Looks.cardOf(id)
	if style and style.Sold == "Starter" then
		return nil
	end
	return if style and style.Sold == "Robux" then "Robux" else "Cash"
end

-- The colour (hex) of door colour `id`, or the start's clay for one not offered.
function Looks.doorOf(id: string): string
	local door = find(Specs.Looks.Doors, id) or Specs.Looks.Doors[1]
	return door.Colour
end

function Looks.floorOf(id: string): Specs.Floor?
	return find(Specs.Looks.Floors, id)
end

-- The colour a floor starts in: its first, or "" for one whose colour is baked.
local function firstColour(floor: Specs.Floor): string
	local first = floor.Colours[1]
	return if first then first.Id else ""
end

-- A new home's look: the first of each list (warm white plaster on oak boards).
function Looks.start(): Chosen
	local floor = Specs.Looks.Floors[1]
	return {
		paint = Specs.Looks.Paints[1].Id,
		paper = Specs.Looks.Papers[1].Id,
		floor = floor.Id,
		floorColour = firstColour(floor),
		door = Specs.Looks.Doors[1].Id,
		card = Specs.Cards[1].Id,
	}
end

-- `chosen` with anything no longer offered put back to the start's (a look dropped in a later
-- update), and a floor colour that isn't that floor's put to its first.
function Looks.tidy(chosen: Chosen): Chosen
	local start = Looks.start()
	local floor = Looks.floorOf(chosen.floor)
	local floorId = if floor then floor.Id else start.floor
	local f = floor or (Looks.floorOf(start.floor) :: Specs.Floor)
	return {
		paint = if find(Specs.Looks.Paints, chosen.paint) then chosen.paint else start.paint,
		paper = if find(Specs.Looks.Papers, chosen.paper) then chosen.paper else start.paper,
		floor = floorId,
		floorColour = if find(f.Colours, chosen.floorColour)
			then chosen.floorColour
			else firstColour(f),
		door = if find(Specs.Looks.Doors, chosen.door) then chosen.door else start.door,
		card = if find(Specs.Cards, chosen.card) then chosen.card else start.card,
	}
end

local KINDS =
	{ paint = true, paper = true, floor = true, floorColour = true, door = true, card = true }

-- A remote's (kind, id), checked for type and length only: a kind of look and a short id.
function Looks.ask(kind: unknown, id: unknown): (Kind?, string?)
	if type(kind) ~= "string" or type(id) ~= "string" or #id == 0 or #id > 32 then
		return nil, nil
	end
	if not KINDS[kind] then
		return nil, nil
	end
	return kind :: Kind, id
end

-- `chosen` with `kind` set to `id`, or nil when `id` isn't one of that kind's looks (a floor
-- colour must be the chosen floor's own). A new floor keeps the colour when it has one by that
-- name (Sage carpet to Sage checker), else takes its first.
function Looks.pick(chosen: Chosen, kind: Kind, id: string): Chosen?
	local after = table.clone(chosen)
	if kind == "paint" then
		if not find(Specs.Looks.Paints, id) then
			return nil
		end
		after.paint = id
	elseif kind == "paper" then
		if not find(Specs.Looks.Papers, id) then
			return nil
		end
		after.paper = id
	elseif kind == "door" then
		if not find(Specs.Looks.Doors, id) then
			return nil
		end
		after.door = id
	elseif kind == "card" then
		if Looks.cardLock(id) then
			return nil -- the rest wait for the counter
		end
		after.card = id
	elseif kind == "floor" then
		local floor = Looks.floorOf(id)
		if not floor then
			return nil
		end
		after.floor = id
		if not find(floor.Colours, chosen.floorColour) then
			after.floorColour = firstColour(floor)
		end
	else
		local floor = Looks.floorOf(chosen.floor)
		if not (floor and find(floor.Colours, id)) then
			return nil
		end
		after.floorColour = id
	end
	return after
end

-- Whether two looks are the same, door and card and all.
function Looks.same(a: Chosen, b: Chosen): boolean
	return a.paint == b.paint
		and a.paper == b.paper
		and a.floor == b.floor
		and a.floorColour == b.floorColour
		and a.door == b.door
		and a.card == b.card
end

-- The room's look (walls and floor) as the unit carries it; the door goes on its own.
function Looks.encode(chosen: Chosen): string
	return `{chosen.paint}|{chosen.paper}|{chosen.floor}|{chosen.floorColour}`
end

-- A room's look from `encode`, with the unit's `door` (its `DoorAttribute`; clay when there's none)
-- and `card` (its `CardAttribute`; the stencil when there's none).
function Looks.decode(text: unknown, door: unknown?, card: unknown?): Chosen?
	if type(text) ~= "string" then
		return nil
	end
	local paint, paper, floor, colour = string.match(text, "^([^|]*)|([^|]*)|([^|]*)|([^|]*)$")
	if not (paint and paper and floor and colour) then
		return nil
	end
	return {
		paint = paint,
		paper = paper,
		floor = floor,
		floorColour = colour,
		door = if type(door) == "string" then door else Specs.Looks.Doors[1].Id,
		card = if type(card) == "string" then card else Specs.Cards[1].Id,
	}
end

-- What the walls and the floor wear for `chosen` (tidied first).
function Looks.wear(chosen: Chosen): (Wear, Wear)
	local c = Looks.tidy(chosen)
	local paint = find(Specs.Looks.Paints, c.paint) :: Specs.Swatch
	local paper = find(Specs.Looks.Papers, c.paper) :: Specs.Paper
	local floor = Looks.floorOf(c.floor) :: Specs.Floor
	local colour = find(floor.Colours, c.floorColour)
	return { set = paper.Set, colour = paint.Colour }, {
		set = floor.Set,
		colour = if colour then colour.Colour else "",
	}
end

-- Whether `before` and `after` differ on the walls, and on the floor.
function Looks.changes(before: Chosen, after: Chosen): (boolean, boolean)
	return before.paint ~= after.paint or before.paper ~= after.paper,
		before.floor ~= after.floor or before.floorColour ~= after.floorColour
end

-- How far a new door colour has turned slat `slat` (1 at the door's foot) `t` seconds into its
-- roll, from 0 to 1, when `hanging` slats hang below the coil: the hanging ones from the top
-- down, the coil's with the top; an open door (under two hanging) round its coil from the
-- outside wrap in, the part that shows from inside.
function Looks.rollShare(slat: number, hanging: number, t: number): number
	local roll = Looks.DoorRoll
	local place, places
	if hanging >= 2 then
		place, places = math.max(hanging - slat, 0), hanging
	else
		place, places = math.clamp(slat - 1, 0, roll.Coil - 1), roll.Coil
	end
	local start = place / (places - 1) * (roll.Seconds - roll.Fade)
	return math.clamp((t - start) / roll.Fade, 0, 1)
end

-- How far a wipe has reached at `t` seconds of `Wipe`, as a share from 0 to 1: it eases in and
-- out, so it sets off as a stroke does and settles as it reaches the door.
function Looks.reach(t: number): number
	local x = math.clamp(t / Looks.Wipe, 0, 1)
	return x * x * (3 - 2 * x)
end

-- The parts of a wall's stretch `from` to `to` (studs round the room, `around`) a wipe has
-- covered when it has gone `r` studs round both ways from the back wall's middle, in a room
-- `round` studs all the way round. The front wall's left half is reached the long way round,
-- past the left wall, as `round` less its own `around`. Each is { from, to }; none, one or two.
function Looks.covered(from: number, to: number, r: number, round: number): { { number } }
	local out = {}
	local half = math.min(r, round / 2) -- the door's middle is as far as either way goes
	local a, b = math.max(from, -half), math.min(to, half)
	if b > a then
		table.insert(out, { a, b })
	end
	a, b = math.max(from, round - half), to
	if b > a then
		table.insert(out, { a, b })
	end
	return out
end

-- The offset (studs, 0 to `tile`) that lines a texture's tiles, starting at a face's edge
-- `edge` studs along, up with tiles that start at multiples of `tile`.
function Looks.offset(edge: number, tile: number): number
	return -edge % tile
end

return table.freeze(Looks)
