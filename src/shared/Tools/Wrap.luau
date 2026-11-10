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

-- The pops (L-14b2b), as a Minecraft tripwire trips under any mob or player that walks into it:
-- a foot entering a laid sheet pops it, anyone's (a keeper's, a friend's, your own). The
-- sheet counts `Slack` studs round its edges (a foot reaches past the middle of you), which with
-- `Across` covers the hall wall to wall, so nobody slips by it. Feet more than `Lift` over it are
-- in the air: a jump clears it, as you can hop a tripwire; feet read up to `Under` below it
-- crawling. A step longer than `Stride` (flat) is a move (caught, a respawn), not a walk: it pops
-- nothing on the way.
Wrap.Slack = 0.4
Wrap.Lift = 1.2
Wrap.Under = 3
Wrap.Stride = 8

-- How far along the halls keepers hear the pops (studs): a door's open (DoorSound's, D-069), so
-- a sheet two halls off brings a keeper as an opened door there would.
Wrap.Reach = 110

-- A sheet pops `Uses` times, one walk across each, then lies spent: flat, dull, half clear and
-- silent (owner, 2026-11-10). It wears through in stages you can see, as Minecraft's anvil goes
-- chipped, then damaged, then breaks. A walk across within `Rest` seconds of the last pop pops
-- nothing and spends nothing (a second friend on your heels, a foot dithering at its edge): the
-- pops never pile up into one long crackle.
Wrap.Uses = 3
Wrap.Rest = 0.8

-- On a popped sheet: how many times it has popped (`PopsAttribute`), and the server's clock
-- (GetServerTimeNow) at the last (`PoppedAttribute`), so every screen plays that pop and wears it
-- down a step. The server sets the count first. A pop older than `Fresh` seconds when a screen
-- first sees it (streamed in late) just shows it worn.
Wrap.PopsAttribute = "Pops"
Wrap.PoppedAttribute = "Popped"

-- The pops on every screen, heard as far as keepers hear them (`Reach`): Pro Sound Effects'
-- "Plastic Bubble Wrap Short Fluttering Movements 2" from 3.34 s, a foot coming down on wrap: a
-- crackle (pops at 3.38, 3.45, 3.61 s) into one sharp pop at 3.94 s, -6 dB (measured for
-- L-14b2b, docs/STUDIO.md). Loud on purpose: it's an alarm. Each of the three is pitched a little
-- apart, so they don't sound like one clip again: the second a little higher, the last lower.
local function popSound(pitch: number)
	return { id = "rbxassetid://9125745015", from = 3.34, length = 1.05, volume = 2, pitch = pitch }
end
Wrap.PopSounds = { popSound(1), popSound(1.1), popSound(0.9) }
-- Each pop wears the sheet a step down, over `Flatten` seconds (fast, then settling): spent, its
-- bubbles are squashed to `Flat` of their height, its film tinted `Tint` (dulled, not dark) and
-- `Clear` see-through, the air gone out of it.
Wrap.Flatten = 0.6
Wrap.Flat = 0.3
Wrap.Tint = { r = 0.66, g = 0.66, b = 0.68 }
Wrap.Clear = 0.35
-- Your view jolts this much (Shake trauma, 0..1) if it popped under you: the horn's is 0.32.
Wrap.Kick = 0.16

-- A laid sheet, in its place's coordinates: its middle on the floor, and the way across the hall
-- (a flat unit vector, `Wrap.place`'s second answer).
export type Sheet = { at: vector, across: vector }

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

-- Narrows the part [t0, t1] of a step that lies between `lo` and `hi` on one axis, the step
-- starting at `a` and moving `d` along it. Nil if none of it does.
local function slab(
	t0: number,
	t1: number,
	a: number,
	d: number,
	lo: number,
	hi: number
): (number?, number)
	if math.abs(d) < 1e-9 then
		if a < lo or a > hi then
			return nil, t1
		end
		return t0, t1
	end
	local ta, tb = (lo - a) / d, (hi - a) / d
	if ta > tb then
		ta, tb = tb, ta
	end
	t0, t1 = math.max(t0, ta), math.min(t1, tb)
	if t0 > t1 then
		return nil, t1
	end
	return t0, t1
end

--- Whether a walk across a sheet that has popped `pops` times, the last `since` seconds ago
--- (math.huge if never), pops it again.
function Wrap.ready(pops: number, since: number): boolean
	return pops < Wrap.Uses and since >= Wrap.Rest
end

--- How worn a sheet that has popped `pops` times looks: 0 fresh, 1 spent (flat, dull, clear).
function Wrap.worn(pops: number): number
	return math.clamp(pops / Wrap.Uses, 0, 1)
end

--- Whether a foot at `p` (the sheet's place's coordinates) is on `sheet`, its slack counted.
function Wrap.on(sheet: Sheet, p: vector): boolean
	local a, o = sheet.across, sheet.at
	local rx, rz = p.x - o.x, p.z - o.z
	local y = p.y - o.y
	return math.abs(rx * a.x + rz * a.z) <= Wrap.Across / 2 + Wrap.Slack
		and math.abs(rz * a.x - rx * a.z) <= Wrap.Deep / 2 + Wrap.Slack
		and y >= -Wrap.Under
		and y <= Wrap.Lift
end

--- Whether a foot stepping from `from` to `to` (the sheet's place's coordinates) crosses `sheet`:
--- it starts off the sheet (or over it in the air) and some of its step is on it.
function Wrap.crosses(sheet: Sheet, from: vector, to: vector): boolean
	local dx, dz = to.x - from.x, to.z - from.z
	if dx * dx + dz * dz > Wrap.Stride * Wrap.Stride then
		return false
	end
	-- each end across the sheet, along it (the hall: across turned a quarter left) and over it
	local a, o = sheet.across, sheet.at
	local rx, rz = from.x - o.x, from.z - o.z
	local fu, fw, fy = rx * a.x + rz * a.z, rz * a.x - rx * a.z, from.y - o.y
	rx, rz = to.x - o.x, to.z - o.z
	local tu, tw, ty = rx * a.x + rz * a.z, rz * a.x - rx * a.z, to.y - o.y
	local hu, hw = Wrap.Across / 2 + Wrap.Slack, Wrap.Deep / 2 + Wrap.Slack
	if math.abs(fu) <= hu and math.abs(fw) <= hw and fy >= -Wrap.Under and fy <= Wrap.Lift then
		return false -- already on it (`Wrap.on`): leaving or shuffling about pops nothing
	end
	local t0: number?, t1 = 0, 1
	t0, t1 = slab(t0 :: number, t1, fu, tu - fu, -hu, hu)
	if t0 then
		t0, t1 = slab(t0, t1, fw, tw - fw, -hw, hw)
	end
	if t0 then
		t0, t1 = slab(t0, t1, fy, ty - fy, -Wrap.Under, Wrap.Lift)
	end
	return t0 ~= nil
end

return Wrap
