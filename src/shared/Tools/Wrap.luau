--!strict
--[[
	Laying the bubble wrap (L-14b2a, D-090), an alarm you set behind you, as Minecraft's tripwire is
	set off by any mob or player that walks through it: with the roll in your hand you press Lay,
	and the whole roll unrolls into one sheet across the hall just in front of your toes, square to
	the hall whichever way you face. Only in a hall: not in a unit, not up on the tops, not in the
	lobby or the elevator's car. (The pops it makes when crossed are L-14b2b's.)

	Pure: the numbers and where a sheet lies, Lune-tested (tests/wrap.spec.luau). The server's
	`Wraps` checks a press and lays the sheet; `WrapView` unrolls it on every screen.
]]
local Floor = require("../Floor")

local Wrap = {}

-- The catalog key of the tool this is.
Wrap.Key = "BubbleWrap"

-- What your screen says when a Lay is refused (Slots' short line): the fix.
Wrap.NotHere = "Lay it in a hall"

-- The sheet's size on the floor (studs): across the 8-stud hall, short of each door face, and as
-- deep along the hall as the roll is long (art/bubblewrap, `Specs/BubbleWrap.Sheet`).
Wrap.Across = 7.35
Wrap.Deep = 1.8

-- How far ahead of your middle the sheet's middle lies, along the hall the way you face (studs):
-- its near edge just in front of your toes, so you watch it unroll and step back off nothing.
Wrap.Ahead = 1.7

-- Where you may be (your middle's height over the hall's floor, studs): standing, kneeling or
-- crawling in the hall, never up on the tops (their deck is over 10 up).
Wrap.Low = -1
Wrap.High = 6

-- The unroll on every screen: the roll rolls across the hall from your left to your right in
-- `Unroll` seconds, the sheet laid out behind it, then the spent core sinks away in `Gone`. A lay
-- older than `Fresh` seconds when a screen first sees the sheet (streamed in late) shows it laid.
Wrap.Unroll = 0.55
Wrap.Gone = 0.18
Wrap.Fresh = 1

-- The unroll's crinkle at the sheet, heard `Heard` studs: the pick-up's crinkle (Pro Sound Effects'
-- "Plastic Bubble Wrap Short Fluttering Movements 12" from 0.2 s, measured for L-14b1) slowed to
-- last the unroll. A real unrolling rustle is in ROADMAP's polish list.
Wrap.Crinkle =
	{ id = "rbxassetid://9125745465", from = 0.2, length = 0.45, volume = 0.8, pitch = 0.85 }
Wrap.Heard = 40
-- The spent core at the end of the unroll, as a share of the full roll's girth.
Wrap.Core = 0.4

-- Your view: the roll brought out ahead and down as you lay it (the row's `use` pose), seconds.
Wrap.Down = 0.45

-- On a laid sheet: the server's clock (GetServerTimeNow) when it was laid, so every screen
-- unrolls it; and the tag every laid sheet carries, so screens find them as they stream in.
Wrap.LaidAttribute = "Laid"
Wrap.Tag = "BubbleSheet"

-- A stretch of hall a sheet may lie in, in the floor's coordinates: its middle, which way it runs
-- (0 along X, 1 along Z, -1 a junction's middle square, either way), and half its length. Every
-- hall is `Floor.HallWidth` across.
export type Hall = { x: number, z: number, along: number, half: number }

local HALL = Floor.HallWidth
local W = HALL / 2
local HALF = Floor.Cell / 2
local ARM = (HALF - W) / 2 -- half a junction arm's length, from the middle square to the edge
local EPS = 1e-3

--- The halls of `floor` a sheet may lie in: each straight, and each junction's middle square and
--- arms. Not the lobby: it's a room, not a hall, and the elevator's car opens off it.
function Wrap.halls(floor: Floor.Floor): { Hall }
	local list: { Hall } = {}
	for _, c in floor.cells do
		if c.kind == "Straight" then
			table.insert(list, { x = c.x, z = c.z, along = c.turn % 2, half = HALF })
		elseif c.kind ~= "Lobby" then
			table.insert(list, { x = c.x, z = c.z, along = -1, half = W })
			for d = 0, 3 do
				if c.arms[d + 1] then
					local dx, dz = Floor.dir(d)
					table.insert(list, {
						x = c.x + dx * (W + ARM),
						z = c.z + dz * (W + ARM),
						along = if dx ~= 0 then 0 else 1,
						half = ARM,
					})
				end
			end
		end
	end
	return list
end

-- Whether (x, z) is on hall `h`, `slack` studs in from its edges counted as on.
local function on(h: Hall, x: number, z: number, slack: number): boolean
	local hx = if h.along == 0 then h.half else if h.along == 1 then W else h.half
	local hz = if h.along == 1 then h.half else if h.along == 0 then W else h.half
	return math.abs(x - h.x) <= hx + slack and math.abs(z - h.z) <= hz + slack
end

-- The hall (x, z) is on, or nil.
local function hallAt(halls: { Hall }, x: number, z: number): Hall?
	for _, h in halls do
		if on(h, x, z, EPS) then
			return h
		end
	end
	return nil
end

-- Whether a point along a hall's line, `t` along its axis (X when `alongX`), `c` its centreline
-- across, is on any hall.
local function onAny(halls: { Hall }, alongX: boolean, t: number, c: number): boolean
	if alongX then
		return hallAt(halls, t, c) ~= nil
	end
	return hallAt(halls, c, t) ~= nil
end

--- Where a sheet lies when someone stands at `at` (their middle, the floor's coordinates) facing
--- `facing` (flat or not) in `halls`: its middle on the floor, and the way across the hall (its
--- X, to their right as they face), so it unrolls from their left to their right. Nil, nil if
--- they're not in a hall.
function Wrap.place(halls: { Hall }, at: vector, facing: vector): (vector?, vector?)
	if at.y < Wrap.Low or at.y > Wrap.High then
		return nil, nil
	end
	local h = hallAt(halls, at.x, at.z)
	if not h then
		return nil, nil
	end
	local alongX = if h.along == -1 then math.abs(facing.x) >= math.abs(facing.z) else h.along == 0
	local f = if alongX then facing.x else facing.z
	local s = if f < 0 then -1 else 1
	local here = if alongX then at.x else at.z
	local centre = if alongX then h.z else h.x -- across: the hall's centreline
	-- just ahead of your toes if the hall goes on that far; else under your feet (a dead end)
	local mid = here
	local ahead = here + s * Wrap.Ahead
	local d = Wrap.Deep / 2
	if onAny(halls, alongX, ahead - d, centre) and onAny(halls, alongX, ahead + d, centre) then
		mid = ahead
	elseif
		not (onAny(halls, alongX, here - d, centre) and onAny(halls, alongX, here + d, centre))
	then
		-- your feet within half a sheet of a dead end's wall: back off it
		for _, try in { here - s * d, here + s * d } do
			if onAny(halls, alongX, try - d, centre) and onAny(halls, alongX, try + d, centre) then
				mid = try
				break
			end
		end
	end
	local point = if alongX then vector.create(mid, 0, centre) else vector.create(centre, 0, mid)
	-- across, to your right: the right of facing along X is -Z, along Z it's +X
	local across = if alongX then vector.create(0, 0, s) else vector.create(-s, 0, 0)
	return point, across
end

return Wrap
