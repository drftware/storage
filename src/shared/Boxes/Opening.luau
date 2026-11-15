--!strict
--[[
	Opening a marked box (B-02a), the pure part: the checks on a press, the rate, each screen's
	clock from the server's stamp, the sounds' beats and the hum going. No Roblox calls, so Lune
	tests it (tests/boxopen.spec).

	The moment: you press Open, the tape rips across the middle and the flaps burst up; everyone
	near hears the rip and the slap and sees it. The server checks the press and stamps the box
	with the time it opened (`OpenedAt`, server time) and who did (`OpenedBy`); it never moves a
	flap. Every screen plays `Specs.Marked.Motions.Open` from that stamp: one that sees it fresh
	plays it from its first frame where it lands, so the opener never misses the tear to their
	own ping; one that sees it late (streamed in, joined) runs from the server's time, so a box
	walked up to after it opened stands open.

	The reveal (B-02b): the server stamps the find inside and its grade with the open, never
	before (an exploiter reads attributes). The tape rips, then a held breath: the flaps stay shut
	for the grade's `Hold`, trembling and lifting at their edges, the box rocking on its base, a
	light in the grade's colour building inside and leaking out, its own sound rising, as Pet
	Simulator's eggs wobble and glow before they hatch. Then the flaps burst, the light flares and
	dies, and the find rises out, turns once and flies into the opener's hand (`handAt`, when the
	server puts it there). A Common holds a breath too, short, with the box's own warm light.
]]
local Art = require("../Finds/Art")

local Opening = {}

Opening.Tag = "MarkedBox" -- a marked box standing in a unit, shut or opened
Opening.OpenedAt = "OpenedAt" -- on the box: workspace:GetServerTimeNow() as it opened
Opening.OpenedBy = "OpenedBy" -- on the box: the UserId of whoever opened it
Opening.UnitValue = "Unit" -- an ObjectValue in the box: the unit it stands in

-- Studs from your middle to the box's button (on its lid): an arm's length and a step, a little
-- under a pile of coins' 8, so you're close enough to see inside as it bursts.
Opening.Reach = 7
Opening.Slack = 2 -- studs the server allows past that (lag, a long arm)

-- The rate: no more than `Rate` presses a second, `Burst` at once. A box opens once, so this
-- only stops a script hammering every box in reach.
Opening.Rate = 3
Opening.Burst = 2

-- Seconds a stamp may take to reach a screen and still play from its first frame there (a slow
-- phone's ping and a frame); later than that, the screen catches up to the server's time.
Opening.Fresh = 0.6

-- When each sound plays, seconds into the open (Specs.Marked.Motions.Open): the rip as the
-- tape snaps and its halves start to whip back (the seam's lines go out with it), the slap as
-- the flaps burst through upright (the sound's hit is 0.02 s into its window).
-- The flaps' slap and the reveal's sounds wait out the grade's hold: Hold starts its sound as
-- the hold begins, Flaps is the slap, Burst the grade's sound as the light flares.
Opening.Beats = { Tear = 0.1, Hold = 0.16, Flaps = 0.3, Burst = 0.16 }
Opening.Order = { "Tear", "Hold", "Burst", "Flaps" } -- the beats in time order
local AFTER_HOLD = { Flaps = true, Burst = true }
-- A beat this screen reaches more than this late is skipped: a sound out of step with the
-- flaps is worse than none.
Opening.Late = 0.25

-- Studs the rip and slap carry: friends in the same stretch of hall hear a box opened.
Opening.Heard = 40
-- The hum from a shut box: heard only up close, whole within `HumFull`, gone by `HumHeard`.
Opening.HumFull = 2
Opening.HumHeard = 12
Opening.HumFade = 0.08 -- seconds the hum takes to die as the tape tears: cut, not a fade-out
-- Studs from you a shut box starts its hum, and the nearest one in reach of `GlowNear` gets the
-- cue's warm light (one light on a screen, whichever box is nearest).
Opening.HumNear = 16
Opening.GlowNear = 10

-- The reveal (B-02b). The flaps that hold shut through the grade's hold, sampled at `flapTime`;
-- the tape and seam run straight on (the tape is torn: it whips back as it did).
Opening.TearAt = 0.16 -- seconds in: the tape is torn and the flaps would burst
Opening.Held = {
	Marked_FlapFront = true,
	Marked_FlapBack = true,
	Marked_FlapLeft = true,
	Marked_FlapRight = true,
} :: { [string]: boolean }

-- Each grade's reveal: the rarer, the longer the held breath, the brighter its light and the
-- further it's heard (a Legendary turns heads down the hall).
export type Reveal = {
	Hold: number, -- seconds the flaps hold shut after the tear
	Glow: number, -- the light's brightness at the end of the hold (it flares past it at the burst)
	Range: number, -- studs that light reaches
	Heard: number, -- studs its sounds carry
	Shake: number, -- degrees the flaps lift and tremble at most just before they burst
}
Opening.Reveals = {
	Common = { Hold = 0.14, Glow = 0.7, Range = 6, Heard = 30, Shake = 3 },
	Uncommon = { Hold = 0.3, Glow = 1, Range = 7, Heard = 40, Shake = 4 },
	Rare = { Hold = 0.5, Glow = 1.4, Range = 8, Heard = 50, Shake = 5 },
	Epic = { Hold = 0.7, Glow = 1.8, Range = 9, Heard = 64, Shake = 6 },
	Legendary = { Hold = 0.95, Glow = 2.4, Range = 11, Heard = 110, Shake = 8 },
	Secret = { Hold = 1.2, Glow = 2.8, Range = 12, Heard = 140, Shake = 9 },
} :: { [string]: Reveal }
Opening.Grade = "Grade" -- on the box, stamped with the open: the grade of what's inside
Opening.Find = "Find" -- on the box, stamped with the open: the find's catalog key
Opening.LaidAt = "LaidAt" -- on the box, if the opener's hands were full: where the find lands

-- The light through the hold and burst, as a share of the grade's `Glow`: a glimmer as the tape
-- tears, building to all of it at the burst, a flare past it, then gone as the find rises.
Opening.GlowFrom = 0.15
Opening.Flare = 2.2 -- times `Glow` at the flare's top
Opening.FlareRise = 0.05 -- seconds from the burst to the flare's top
Opening.FlareFade = 0.6 -- seconds the flare takes to die
-- The tremble's share at the hold's start: it grows from this to all of it at the burst.
Opening.ShakeFrom = 0.3
-- How the held box trembles on screens: the flaps lift at their edges up to the grade's `Shake`
-- degrees, `Rate` times a second, each out of step; the box rocks on its base by `Rock` of that,
-- `RockRate` times a second, as a hatching egg wobbles.
Opening.Tremble = { Rate = 13, Rock = 0.35, RockRate = 7 }

-- The find coming out, seconds after the burst: it rises out of the box (overshooting a hair)
-- to hover `Above` studs over the rim, turns once while it hangs, then flies into the opener's
-- hand, there at `Gone`, as the server puts it there.
Opening.Out = {
	Rise = 0.06,
	Risen = 0.46,
	Above = 0.55,
	Turn = 0.95, -- seconds its one turn takes, from `Rise`
	Go = 1.3,
	Gone = 1.55,
	Linger = 0.2, -- seconds the copy stays after `Gone`, so a find laid down never blinks out
}

Opening.Thinnest = 0.001 -- the smallest a part's side may be (Roblox clamps lower)

-- What a press is checked against, in the order it's checked.
export type Check = {
	opened: boolean, -- the box was opened already
	alive: boolean, -- the presser's character is alive
	wrapped: boolean, -- the presser is wrapped and caught (no hands)
	distance: number, -- studs from the presser's middle to the box's button
	apart: boolean, -- a shut door stands between them (RollUpDoor.keepsApart)
}
export type Refusal = "opened" | "dead" | "wrapped" | "far" | "door"

-- Why a press can't open the box, or nil if it opens it. Nothing is said on any screen: an
-- opened box has no button, and the rest can't press it from where they are.
function Opening.refuse(c: Check): Refusal?
	if c.opened then
		return "opened"
	elseif not c.alive then
		return "dead"
	elseif c.wrapped then
		return "wrapped"
	elseif c.distance > Opening.Reach + Opening.Slack then
		return "far"
	elseif c.apart then
		return "door"
	end
	return nil
end

-- Whether a press at `now` may go ahead given the last one let through and the burst left after
-- it; returns the burst left after this one.
function Opening.allow(last: number?, burst: number, now: number): (boolean, number)
	if last == nil then
		return true, Opening.Burst - 1
	end
	local left = math.min(Opening.Burst, burst + math.max(0, now - last) * Opening.Rate)
	if left < 1 then
		return false, left
	end
	return true, left - 1
end

-- The server time this screen plays the open from, given the stamp and the server time it saw
-- the stamp at.
function Opening.clock(openedAt: number, seenAt: number): number
	if seenAt - openedAt <= Opening.Fresh then
		return seenAt
	end
	return openedAt
end

-- The beats crossed going from `from` to `to` seconds into the open, in order, each skipped if
-- `to` is more than `Late` past it; the slap and burst wait out `hold`. Returns a shared list:
-- read it before the next call.
local due: { string } = {}
function Opening.due(from: number, to: number, hold: number?): { string }
	table.clear(due)
	for _, name in Opening.Order do
		local at = Opening.Beats[name] + (if AFTER_HOLD[name] then hold or 0 else 0)
		if at > from and at <= to and to - at <= Opening.Late then
			table.insert(due, name)
		end
	end
	return due
end

-- As Specs.Marked's (Finds/Art.luau's Track): a key is { time, value, style, direction }.
export type Track = { Part: string, Channel: "turn" | "scale", Keys: { { any } } }
export type Motion = { Duration: number, Tracks: { Track } }

-- Where a held flap's track is `t` seconds into an open that holds `hold`: on time through the
-- tear, stopped through the hold, then `hold` behind.
function Opening.flapTime(t: number, hold: number): number
	if t <= Opening.TearAt then
		return t
	elseif t <= Opening.TearAt + hold then
		return Opening.TearAt
	end
	return t - hold
end

-- Each moving part's value `t` seconds into `motion` (a turn in degrees, or a scale), into `into`
-- by part name, the flaps held for `hold`.
function Opening.pose(motion: Motion, t: number, into: { [string]: number }, hold: number?)
	local held = Opening.flapTime(t, hold or 0)
	for _, track in motion.Tracks do
		into[track.Part] = Art.sample(track.Keys, if Opening.Held[track.Part] then held else t)
	end
end

function Opening.settled(motion: Motion, t: number, hold: number?): boolean
	return t >= motion.Duration + (hold or 0)
end

-- Seconds into the open the flaps burst, after a hold of `hold`.
function Opening.burst(hold: number): number
	return Opening.TearAt + hold
end

-- Seconds into the open the find is in the opener's hand (the server gives it then).
function Opening.handAt(hold: number): number
	return Opening.burst(hold) + Opening.Out.Gone
end

-- Seconds into the open a screen is done with it: the find's copy gone.
function Opening.done(hold: number): number
	return Opening.handAt(hold) + Opening.Out.Linger
end

-- The grade's light `t` seconds into the open, as a share of its `Glow` (0 before the tear).
function Opening.glow(t: number, hold: number): number
	local tear = Opening.Beats.Tear
	local b = Opening.burst(hold)
	if t < tear then
		return 0
	elseif t < b then
		local into = (t - tear) / (b - tear)
		return Opening.GlowFrom + (1 - Opening.GlowFrom) * into * into
	end
	local after = t - b
	if after < Opening.FlareRise then
		return 1 + (Opening.Flare - 1) * after / Opening.FlareRise
	end
	local fade = (after - Opening.FlareRise) / Opening.FlareFade
	if fade >= 1 then
		return 0
	end
	return Opening.Flare * (1 - fade) * (1 - fade)
end

-- How hard the box trembles `t` seconds into the open, 0 to 1: only while the flaps are held,
-- growing to all of it at the burst.
function Opening.shake(t: number, hold: number): number
	local b = Opening.burst(hold)
	if t <= Opening.TearAt or t >= b then
		return 0
	end
	return Opening.ShakeFrom + (1 - Opening.ShakeFrom) * (t - Opening.TearAt) / hold
end

-- The find `t` seconds into the open: how far up out of the box (0 inside, 1 hovering over the
-- rim, a little past 1 as it overshoots), its turn in degrees (0 to 360), and how far on its
-- way to the opener's hand (0 to 1).
function Opening.lift(t: number, hold: number): (number, number, number)
	local after = t - Opening.burst(hold)
	local out = Opening.Out
	local up = math.clamp((after - out.Rise) / (out.Risen - out.Rise), 0, 1)
	-- out of the box with a little overshoot, then settling (Back, Out)
	local c = 1.70158
	local u = up - 1
	up = 1 + (c + 1) * u * u * u + c * u * u
	local turn = math.clamp((after - out.Rise) / out.Turn, 0, 1)
	turn = (1 - math.cos(math.pi * turn)) / 2 * 360
	local go = math.clamp((after - out.Go) / (out.Gone - out.Go), 0, 1)
	return up, turn, go * go
end

-- The hum's share of its volume `t` seconds into the open (1 while shut: t <= 0).
function Opening.hum(t: number): number
	local past = t - Opening.Beats.Tear
	if past <= 0 then
		return 1
	elseif past >= Opening.HumFade - 1e-9 then
		return 0
	end
	return 1 - past / Opening.HumFade
end

-- A side of `size` scaled by `v`, never below what a part can be.
function Opening.thin(size: number, v: number): number
	return math.max(size * v, Opening.Thinnest)
end

return Opening
