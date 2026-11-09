--!strict
--[[
	Sawing: the rules and feel numbers of sawing a crawl hole (L-12b2), pure so Lune checks them
	(tests/sawing.spec.luau). The moment: you hold Saw at the wall, the motor screams through the
	whole floor, a bright line crawls round the cut, and the panel clangs down on the other side.
	Everything heard it.

	A held button, loud the whole time you hold it, as Dead by Daylight's generators are worked by
	holding and Granny hears every noise you make: the hole is a real choice because the floor's
	keepers hear you cut it. Let go early and the cut is lost; the next try starts over.

	The cut runs round the hole from its top front corner: down the side nearest the hall, along
	the bottom, up the far side, and back along the top, as a hand-held saw goes round a square.
	`line` says how much of each of those four edges is cut at a share of the hold, and where the
	blade is.
]]

local Sawing = {}

-- Seconds you hold Saw to cut through: long enough that the floor hears it and a keeper can
-- come, short enough to cut one while leading a keeper round (the hole trap).
Sawing.Seconds = 4
-- Studs from the button you can be to press it: standing at the wall, not across the unit.
Sawing.Reach = 6
-- Studs past the button's reach the server still accepts: a moving player's lag.
Sawing.RangeSlack = 3
-- A press closer than this to your last one is dropped: a double tap.
Sawing.RepeatSeconds = 0.3
-- The server cuts only if the hold began at least this much short of `Seconds` ago: a finished
-- hold arrives a little early or late over the network, a faked one far too early.
Sawing.HoldSlack = 0.35
-- A hold the server saw finish but never got the cut for is dropped this long after it should
-- have ended.
Sawing.StaleSeconds = 1
-- Studs a keeper hears the saw from (L-06b): the whole floor. The loudest thing a player does.
Sawing.Heard = 200
-- And the panel's clang on the far side.
Sawing.ClangHeard = 110

-- On a wall being sawn (the server's, for every screen): the tag, the server time the motor
-- started, the sawer's UserId, which side of the wall they're on (1 or -1 in the kit's frame's X)
-- and the kit's frame on that wall (`CrawlHole.frame`), so a screen draws the cut without the unit.
Sawing.Tag = "SawingWall"
Sawing.StartAttribute = "SawStart"
Sawing.ByAttribute = "SawBy"
Sawing.FromAttribute = "SawFrom"
Sawing.FrameAttribute = "SawFrame"

-- Your view while you saw: a steady buzz, then a jolt as the panel goes (Shake trauma).
Sawing.Buzz = 0.28 -- the trauma your view holds while your saw runs: the motor through your arms
Sawing.Jolt = 0.45 -- the panel's fall, near it (falls away with distance to ClangHeard)
Sawing.JoltNear = 8 -- studs within which the jolt is full
Sawing.JoltReach = 30 -- and beyond which it's gone, as a slammed door's (DoorSound.ShakeReach)

export type Holding = "Hand" | "Slot" | "None"
export type Verdict = { ok: boolean, refusal: string? }

--[[
	Whether a player may start sawing a wall: the saw in their hand, the wall not holed yet, nobody
	else sawing it. A saw in their other slot gets "Hold the saw"; none at all, "Need a saw" (the
	button shows only to someone carrying one, so that's a stale press). A holed wall or one being
	sawn is refused silently: its button is going.
]]
function Sawing.decide(holding: Holding, holed: boolean, busy: boolean): Verdict
	if holed or busy then
		return { ok = false }
	elseif holding == "Slot" then
		return { ok = false, refusal = "Hold the saw" }
	elseif holding == "None" then
		return { ok = false, refusal = "Need a saw" }
	end
	return { ok = true }
end

-- How far through the cut a hold is, 0 to 1, `elapsed` seconds in.
function Sawing.progress(elapsed: number): number
	local p = elapsed / Sawing.Seconds
	return if p < 0 then 0 elseif p > 1 then 1 else p
end

-- Whether a hold that began `elapsed` seconds ago has run long enough to cut.
function Sawing.finished(elapsed: number): boolean
	return elapsed >= Sawing.Seconds - Sawing.HoldSlack
end

-- The hole as a rectangle on the wall: along from the hall (from, to) and up (bottom, top).
export type Hole = { from: number, to: number, bottom: number, top: number }

--[[
	The cut at `progress` (0 to 1) round `hole`: fills `into` with how much of each edge is cut, in
	the order sawn (1 the front side, top to bottom; 2 the bottom, front to back; 3 the back side,
	bottom to top; 4 the top, back to front), each 0 to 1, and returns where the blade is (along,
	up). The blade moves at one speed all the way round.
]]
function Sawing.line(progress: number, hole: Hole, into: { number }): (number, number)
	local w, h = hole.to - hole.from, hole.top - hole.bottom
	local left = math.clamp(progress, 0, 1) * 2 * (w + h)
	for i = 1, 4 do
		local len = if i % 2 == 1 then h else w -- no table: this runs every frame of a cut
		local cut = math.clamp(left, 0, len)
		into[i] = if len > 0 then cut / len else 1
		left -= cut
	end
	-- the blade: at the end of the last edge begun
	local a, b, c, d = into[1], into[2], into[3], into[4]
	if d > 0 then
		return hole.to - w * d, hole.top
	elseif c > 0 then
		return hole.to, hole.bottom + h * c
	elseif b > 0 then
		return hole.from + w * b, hole.bottom
	end
	return hole.from, hole.top - h * a
end

-- A stretch of a recording, looped from `loopFrom` to `loopTo` (nil plays it once).
export type Sound = {
	id: string,
	from: number, -- where it starts: the motor spinning up
	loopFrom: number?,
	loopTo: number?,
	length: number?, -- how long a one-shot plays
	volume: number,
	pitch: number,
	near: number, -- full volume within this
	reach: number, -- heard to this many studs
}

Sawing.Sounds = {
	-- Pro Sound Effects' "Metal Blade Grind 1": a grinder turned on (spun up by 0.8 s) and held, a
	-- steady high whine (-12 to -6 dB) looped from 2 s to 7 s: the saw's motor
	Whine = {
		id = "rbxassetid://9116524165",
		from = 0.1,
		loopFrom = 2,
		loopTo = 7,
		volume = 0.75,
		pitch = 1.08,
		near = 10,
		reach = Sawing.Heard,
	} :: Sound,
	-- Pro Sound Effects' "Cold Saw Humming Whir 2": its harshest run grinding through pipe, 16.5 s
	-- to 20 s (-12 dB, steady), a little quicker: the blade chattering through the steel
	Chatter = {
		id = "rbxassetid://9113851035",
		from = 16.5,
		loopFrom = 16.5,
		loopTo = 20,
		volume = 0.9,
		pitch = 1.15,
		near = 10,
		reach = Sawing.Heard,
	} :: Sound,
	-- Pro Sound Effects' "Metal Lid Drop Hard Lid Close Drops 12": a flat metal sheet's hit at
	-- 0.40 s and its rattle to 1.35 s: the panel slapping flat on the concrete
	Clang = {
		id = "rbxassetid://9116737135",
		from = 0.36,
		length = 1.3,
		volume = 1,
		pitch = 0.92,
		near = 8,
		reach = Sawing.ClangHeard,
	} :: Sound,
}
-- When the motor stops (let go, or through): it winds down this long, dropping to this pitch.
Sawing.SpinDown = 0.4
Sawing.SpinDownPitch = 0.45

return Sawing
