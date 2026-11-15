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
Opening.Beats = { Tear = 0.1, Flaps = 0.3 }
Opening.Order = { "Tear", "Flaps" } -- the beats in time order
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
-- `to` is more than `Late` past it. Returns a shared list: read it before the next call.
local due: { string } = {}
function Opening.due(from: number, to: number): { string }
	table.clear(due)
	for _, name in Opening.Order do
		local at = Opening.Beats[name]
		if at > from and at <= to and to - at <= Opening.Late then
			table.insert(due, name)
		end
	end
	return due
end

-- As Specs.Marked's (Finds/Art.luau's Track): a key is { time, value, style, direction }.
export type Track = { Part: string, Channel: "turn" | "scale", Keys: { { any } } }
export type Motion = { Duration: number, Tracks: { Track } }

-- Each moving part's value `t` seconds into `motion` (a turn in degrees, or a scale), into `into`
-- by part name.
function Opening.pose(motion: Motion, t: number, into: { [string]: number })
	for _, track in motion.Tracks do
		into[track.Part] = Art.sample(track.Keys, t)
	end
end

function Opening.settled(motion: Motion, t: number): boolean
	return t >= motion.Duration
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
