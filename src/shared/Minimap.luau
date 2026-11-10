--!strict
--[[
	Minimap: the corner map's drawing as plain data (L-10). Deep in the building with a keeper behind
	you, a glance at the corner shows the way back to the lobby and the gate: the halls you've walked
	are drawn and the rest is dark, as R.E.P.O.'s map fills in the rooms you've found. Nothing here
	touches an Instance, so Lune tests it (tests/minimap.spec).

	A floor becomes pieces: each hall piece (a straight, or a junction's middle and arms), the lobby
	and the elevator's car. Walking onto a piece fills it in, with the units along it; the lobby and
	the car are always drawn. Each unit is its footprint, drawn with the hall it opens onto, so
	standing in one (or on its top) fills in that hall. Keepers, lights and what a unit holds are
	never in it: lit fixtures are the office light board's to show (GDD), and the layout reaches
	screens as shapes only, never the floor's seed, which would give away the code and every
	unit's contents (D-094).

	Coordinates are the floor's (Floor.luau): studs, the lobby's middle at the origin, the floor
	spreading toward -Z and the car behind the lobby toward +Z. On the map +X is right and +Z down,
	so the lobby and the gate are always at the bottom: the way back is always down.
]]
local ElevatorSpecs = require("./Elevator/Specs")
local Floor = require("./Floor")

local Minimap = {}

-- On a laid floor's model, from the server (`Minimaps`): the tag, its layout as text
-- (`Minimap.encode`), the frame the layout is in, and the units opened so far (`encodeOpened`).
Minimap.Tag = "Minimap"
Minimap.LayoutAttribute = "MinimapLayout"
Minimap.OriginAttribute = "MinimapOrigin"
Minimap.OpenedAttribute = "MinimapOpened"

-- What it does to the player. The window follows you, so it shows a stretch of the floor round
-- you large enough to read on a phone; the lobby, when it's off the window, waits on its edge.
Minimap.Span = 112 -- studs across the window: a junction and a half each way, halls 8 points wide or more
Minimap.Side = 0.3 -- the window's side as a share of the screen's height: on a phone, a third of it
Minimap.MinSide = 104 -- points: never smaller than this, or a unit's square stops reading
Minimap.MaxSide = 176 -- points: never larger, so on a big screen it stays a glance in the corner
Minimap.Reveal = 0.45 -- seconds a hall you walk onto (and its units) takes to ease in
Minimap.Tick = 0.3 -- seconds an opened unit's tick takes to pop in
Minimap.Slide = 0.5 -- seconds the map takes to slide in as you arrive on a floor, or out as you leave
Minimap.Margin = 8 -- studs off the floor's edge you can stand (a window's ledge) and still see it
Minimap.Height = 30 -- studs above or below the floor's level that still count as on it (the tops are 10 up)
Minimap.Friends = true -- friends as dots, as Lethal Company's ship radar shows the crew (owner, D-091)

export type Rect = { x0: number, x1: number, z0: number, z1: number }
export type Kind = "Hall" | "Lobby" | "Elevator"
-- A piece the map fills in at once: its rectangles, on the floor.
export type Piece = { kind: Kind, rects: { Rect } }
-- A unit: its slot in the floor (an index into `Floor.slots`, what the server's opened list
-- names), the piece it's drawn with, and its footprint.
export type Unit = { slot: number, piece: number, rect: Rect }
export type Map = {
	pieces: { Piece },
	units: { Unit },
	lobby: number, -- the lobby's piece: always drawn
	elevator: number, -- the car's piece: always drawn
	bounds: Rect, -- round every piece and unit
}

local HALL = Floor.HallWidth
local W = HALL / 2
local HALF = Floor.Cell / 2
local ARM = (HALF - W) / 2 -- half a junction arm's length, from its middle square to its edge
local EPS = 1e-3

local function rect(x: number, z: number, hx: number, hz: number): Rect
	return { x0 = x - hx, x1 = x + hx, z0 = z - hz, z1 = z + hz }
end

local function within(r: Rect, x: number, z: number, slack: number): boolean
	return x >= r.x0 - slack and x <= r.x1 + slack and z >= r.z0 - slack and z <= r.z1 + slack
end

local function boundsOf(pieces: { Piece }, units: { Unit }): Rect
	local b = { x0 = math.huge, x1 = -math.huge, z0 = math.huge, z1 = -math.huge }
	local function grow(r: Rect)
		b.x0, b.x1 = math.min(b.x0, r.x0), math.max(b.x1, r.x1)
		b.z0, b.z1 = math.min(b.z0, r.z0), math.max(b.z1, r.z1)
	end
	for _, p in pieces do
		for _, r in p.rects do
			grow(r)
		end
	end
	for _, u in units do
		grow(u.rect)
	end
	return b
end

--- The map of `floor`: its pieces in the order of its cells, the car's last, and its units.
function Minimap.from(floor: Floor.Floor): Map
	local pieces: { Piece } = {}
	for _, c in floor.cells do
		local rects: { Rect } = {}
		if c.kind == "Lobby" then
			table.insert(rects, rect(c.x, c.z, Floor.LobbySize / 2, Floor.LobbySize / 2))
		elseif c.kind == "Straight" then
			local alongX = c.turn % 2 == 0
			table.insert(
				rects,
				rect(c.x, c.z, if alongX then HALF else W, if alongX then W else HALF)
			)
		else
			table.insert(rects, rect(c.x, c.z, W, W))
			for d = 0, 3 do
				if c.arms[d + 1] then
					local dx, dz = Floor.dir(d)
					table.insert(
						rects,
						rect(
							c.x + dx * (W + ARM),
							c.z + dz * (W + ARM),
							if dx ~= 0 then ARM else W,
							if dz ~= 0 then ARM else W
						)
					)
				end
			end
		end
		table.insert(
			pieces,
			{ kind = if c.kind == "Lobby" then "Lobby" else "Hall", rects = rects }
		)
	end
	-- the car, from the lobby's back wall to the car's back, wall to wall
	local lc = floor.cells[floor.lobby]
	local car = ElevatorSpecs.Car
	local back = lc.z + Floor.LobbySize / 2
	table.insert(pieces, {
		kind = "Elevator",
		rects = {
			{
				x0 = lc.x - car.Width / 2,
				x1 = lc.x + car.Width / 2,
				z0 = back,
				z1 = back + car.Back,
			},
		},
	})

	local units: { Unit } = {}
	for i, s in floor.slots do
		if s.kind == "Unit" then
			local x0, x1, z0, z1 = Floor.footprint(s)
			table.insert(
				units,
				{ slot = i, piece = s.cell, rect = { x0 = x0, x1 = x1, z0 = z0, z1 = z1 } }
			)
		end
	end
	return {
		pieces = pieces,
		units = units,
		lobby = floor.lobby,
		elevator = #pieces,
		bounds = boundsOf(pieces, units),
	}
end

--- The piece (x, z) is on, or nil: a hall, the lobby or the car, edges counted as on; inside a
--- unit, the hall it opens onto.
function Minimap.at(map: Map, x: number, z: number): number?
	for i, p in map.pieces do
		for _, r in p.rects do
			if within(r, x, z, EPS) then
				return i
			end
		end
	end
	for _, u in map.units do
		if within(u.rect, x, z, EPS) then
			return u.piece
		end
	end
	return nil
end

--- Whether (x, z) is on the floor's map or within `margin` studs of its edge.
function Minimap.near(map: Map, x: number, z: number, margin: number): boolean
	return within(map.bounds, x, z, margin)
end

--- Where a marker `dx`, `dy` from the window's middle sits in a square window `half` from its
--- middle to each edge: where it is, if that's inside; else on the edge, the same way from the
--- middle. The second answer says it was held on the edge.
function Minimap.edge(dx: number, dy: number, half: number): (number, number, boolean)
	local far = math.max(math.abs(dx), math.abs(dy))
	if far <= half then
		return dx, dy, false
	end
	local k = half / far
	return dx * k, dy * k, true
end

-- The layout as text: the pieces, ";" between them, each its kind's letter and its rectangles,
-- "," between them; then "|" and the units, ";" between them, each its slot, its piece and its
-- rectangle. Numbers to 6 figures, so a floor's whole and half studs come back exact.
local LETTER = { Hall = "H", Lobby = "L", Elevator = "E" } :: { [Kind]: string }
local KIND = { H = "Hall", L = "Lobby", E = "Elevator" } :: { [string]: Kind }

local function rectText(r: Rect): string
	return string.format("%g %g %g %g", r.x0, r.x1, r.z0, r.z1)
end

function Minimap.encode(map: Map): string
	local pieces = table.create(#map.pieces)
	for i, p in map.pieces do
		local rects = table.create(#p.rects)
		for k, r in p.rects do
			rects[k] = rectText(r)
		end
		pieces[i] = LETTER[p.kind] .. " " .. table.concat(rects, ",")
	end
	local units = table.create(#map.units)
	for i, u in map.units do
		units[i] = string.format("%d %d ", u.slot, u.piece) .. rectText(u.rect)
	end
	return table.concat(pieces, ";") .. "|" .. table.concat(units, ";")
end

local NUM = "([%-%d%.e+]+)"
local RECT = "^%s*" .. NUM .. " " .. NUM .. " " .. NUM .. " " .. NUM .. "%s*$"

local function rectFrom(text: string): Rect?
	local a, b, c, d = string.match(text, RECT)
	local x0, x1, z0, z1 = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
	if not (x0 and x1 and z0 and z1) or x0 >= x1 or z0 >= z1 then
		return nil
	end
	return { x0 = x0, x1 = x1, z0 = z0, z1 = z1 }
end

--- The map a layout's text holds, or nil if it isn't one: one lobby, one car, every unit beside
--- a piece that's there.
function Minimap.decode(text: string): Map?
	local parts = string.split(text, "|")
	if #parts ~= 2 or parts[1] == "" then
		return nil
	end
	local pieces: { Piece } = {}
	local lobby, elevator = 0, 0
	for _, entry in string.split(parts[1], ";") do
		local letter, rest = string.match(entry, "^(%a) (.+)$")
		local kind: Kind? = if letter then KIND[letter] else nil
		if not (kind and rest) then
			return nil
		end
		local rects: { Rect } = {}
		for _, r in string.split(rest, ",") do
			local got = rectFrom(r)
			if not got then
				return nil
			end
			table.insert(rects, got)
		end
		local piece: Piece = { kind = kind, rects = rects }
		table.insert(pieces, piece)
		if kind == "Lobby" then
			if lobby ~= 0 then
				return nil
			end
			lobby = #pieces
		elseif kind == "Elevator" then
			if elevator ~= 0 then
				return nil
			end
			elevator = #pieces
		end
	end
	if lobby == 0 or elevator == 0 then
		return nil
	end
	local units: { Unit } = {}
	if parts[2] ~= "" then
		for _, entry in string.split(parts[2], ";") do
			local s, p, rest = string.match(entry, "^(%d+) (%d+) (.+)$")
			local slot, piece = tonumber(s), tonumber(p)
			local r = if rest then rectFrom(rest) else nil
			if not (slot and piece and r and pieces[piece]) then
				return nil
			end
			table.insert(units, { slot = slot, piece = piece, rect = r })
		end
	end
	return {
		pieces = pieces,
		units = units,
		lobby = lobby,
		elevator = elevator,
		bounds = boundsOf(pieces, units),
	}
end

--- The units opened so far (their slots), as the server lists them on the floor.
function Minimap.encodeOpened(slots: { number }): string
	local parts = table.create(#slots)
	for i, s in slots do
		parts[i] = string.format("%d", s)
	end
	return table.concat(parts, ",")
end

--- The opened units a list names, by slot; anything that isn't a whole slot number is skipped.
function Minimap.decodeOpened(text: string): { [number]: boolean }
	local set: { [number]: boolean } = {}
	for _, part in string.split(text, ",") do
		local n = if string.match(part, "^%d+$") then tonumber(part) else nil
		if n and n >= 1 then
			set[n] = true
		end
	end
	return set
end

return Minimap
