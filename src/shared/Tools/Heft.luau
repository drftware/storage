--!strict
--[[
	How heavy a find feels in your hand (S1-05; the catalog row's `heft`, 0 to 1): only how it moves
	in your first-person view, never your walk. A tool snaps up into view with a little overshoot;
	a find comes up slower and with no spring in it, its weight lands in your hand with a sag and a
	small rebound, and it sways lazier as you walk, as a heavy thing does in Lethal Company's hands.
	Pure (Lune specs: tests/heft.spec.luau); ToolView draws it.
]]
local Heft = {}

-- The heaviest find (heft 1) takes this much longer to come up into view than a tool: the TV is
-- hauled up, the teddy barely slower than a tool.
Heft.Slow = 0.9
-- Studs (at full size) the heaviest find sags as its weight lands in your hand, and degrees its
-- front dips at the bottom of that sag.
Heft.Depth = 0.16
Heft.Tip = 7
-- The sag's bounce: one dip and a small rebound, gone in about two thirds of a second.
Heft.Freq = 13 -- radians a second
Heft.Damp = 6 -- of the bounce, a second
Heft.Settled = 0.7 -- seconds after it lands that the bounce is too small to see
-- How much more the heaviest find sways as you walk and turn than a tool does.
Heft.Sway = 0.8

-- The seconds `heft`'s thing takes to come up into view, from a tool's `seconds`.
function Heft.rise(seconds: number, heft: number): number
	return seconds * (1 + Heft.Slow * heft)
end

-- Of the way up into view at `t` (0 to 1 of the rise): a tool's back-out overshoot for no heft,
-- else an ease-out with no overshoot (a weight doesn't spring).
function Heft.ease(t: number, heft: number): number
	if heft <= 0 then
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
	end
	return 1 - (1 - t) ^ 3
end

-- The bounce's own deepest point, so the dip's bottom is 1: where its slope is flat.
local PEAK_AT = math.atan(Heft.Freq / Heft.Damp) / Heft.Freq
local PEAK = math.exp(-Heft.Damp * PEAK_AT) * math.sin(Heft.Freq * PEAK_AT)

-- The sag `since` seconds after it landed in your hand: 1 at the bottom of the heaviest's dip,
-- negative on the rebound, 0 once settled (and before it lands). Times `Depth` and `Tip`.
function Heft.sag(since: number, heft: number): number
	if heft <= 0 or since <= 0 or since >= Heft.Settled then
		return 0
	end
	return heft * math.exp(-Heft.Damp * since) * math.sin(Heft.Freq * since) / PEAK
end

-- The sway's scale for `heft`: 1 for a tool.
function Heft.swayScale(heft: number): number
	return 1 + Heft.Sway * heft
end

return Heft
