--!strict
--[[
	DoorSpot: how high each of a door's button spots sits for the eye looking at it (L-19b). Pure.

	The server puts each spot where the hand would go (`Height`): Open's at the door's middle,
	Peek's low at the lift handle, Lock and Cut on the latch. But in first person a button shows
	only while its spot is on screen (Roblox's view is 70 degrees tall, 35 each way of a level
	gaze), so each screen moves its own copy of the spots to stay in view: one too low for the eye
	rides up the door just as far as it must (`Below`), and while you kneel to peek the spots above
	come down with you (`Above`), never so low they hide what's under the door (`Lowest`). Far
	enough back, every spot sits on its handle.
]]
-- a string require, as Brix's modules do, so Lune can load this module for its tests too
local Door = require("./Door")

local DoorSpot = {}

-- Studs off the floor each spot sits, standing in the hall far enough back to see it there.
DoorSpot.Height = {
	Middle = 4, -- the door's middle: just under a standing player's eyes (about 4.5)
	Low = 1, -- by the ground, a hand over the lift handle (0.4) so the chip doesn't sit on the seam
	Latch = 0.5, -- the padlock's height on the bottom bar
	Inside = 4, -- Lift, behind the door at the middle
} :: { [Door.Spot]: number }

-- The spots a screen moves. Lift's stays put: someone shut in stands at a door at eye height.
DoorSpot.Moves = { Middle = true, Low = true, Latch = true } :: { [Door.Spot]: true }

-- How far under a level gaze each spot may sit. The view's edge is 35 degrees, but the bottom of
-- the screen is the hand's: on the Galaxy A16 the tool slots' top is 87 points under the view's
-- middle (the jump button and thumbstick beside them), so a low spot stops where its chip clears
-- them. The middle row stops a chip above that, at a standing eye: Open sits at your eye whatever
-- the distance, and Peek a chip under it.
DoorSpot.Below = {
	Middle = 0,
	Low = math.rad(12),
	Latch = math.rad(12),
	Inside = math.rad(12),
} :: { [Door.Spot]: number }
-- How far over a level gaze the spots sit while you kneel to peek: just above where you look, so
-- Open, Close and Slam stay on screen while you look under the door.
DoorSpot.Above = math.rad(16)
-- And never lower than this off the floor, so they never hide what's under the peek's gap (1.15).
DoorSpot.Lowest = 1.8

-- How far to the side of your gaze the latch's buttons may sit. The latch is at the door's
-- corner, and facing the door from a step or two back that's the right edge of a phone's screen,
-- under the torch and jump buttons. So the latch's spot slides in along the bottom bar just far
-- enough to sit this close to your gaze (Cut's chip clear of Peek's word, its refusal short of
-- the jump button), and back out onto the padlock as you turn to face it.
DoorSpot.Aside = math.rad(24)

-- Each spot carries this tag and its name as this attribute, so a screen can find and move them;
-- the latch's spot carries how far across the door it sits (studs, door-local X) as `Across`.
DoorSpot.Tag = "DoorSpot"
DoorSpot.Attribute = "DoorSpot"
DoorSpot.Across = "DoorAcross"

--[[
	How high `spot` sits for an eye `eye` studs off the door's floor, `distance` studs out from the
	door, looking `pitch` radians up (negative down): where it belongs, raised into view if that's
	under the screen, brought down to the eye if that's over it. Looking down at the door lets a low
	spot come down with your gaze onto its handle; looking up counts as level, so the buttons never
	chase your gaze up the door.
]]
function DoorSpot.height(spot: Door.Spot, eye: number, distance: number, pitch: number?): number
	local height = DoorSpot.Height[spot]
	local d = math.max(distance, 0)
	local down = math.max(-(pitch or 0), 0)
	local lowest = eye - d * math.tan(math.min(down + DoorSpot.Below[spot], math.rad(80)))
	local highest = math.max(eye + d * math.tan(DoorSpot.Above), DoorSpot.Lowest)
	return math.max(lowest, math.min(height, highest))
end

--[[
	How far (0 to 1) a spot that belongs at (hx, hz) slides toward (mx, mz), the door's middle, to
	sit within `Aside` of a flat gaze from (cx, cz) along the unit (fx, fz): 0 when it's already
	there, or when even the middle isn't (you've looked away from the door), so it's never dragged
	about by a glance elsewhere.
]]
function DoorSpot.slide(
	cx: number,
	cz: number,
	fx: number,
	fz: number,
	hx: number,
	hz: number,
	mx: number,
	mz: number
): number
	local reach = math.tan(DoorSpot.Aside)
	local function inside(s: number): boolean
		local px = hx + (mx - hx) * s - cx
		local pz = hz + (mz - hz) * s - cz
		local ahead = px * fx + pz * fz
		return ahead > 0 and math.abs(px * fz - pz * fx) <= ahead * reach
	end
	if inside(0) or not inside(1) then
		return 0
	end
	local lo, hi = 0, 1
	for _ = 1, 16 do
		local mid = (lo + hi) / 2
		if inside(mid) then
			hi = mid
		else
			lo = mid
		end
	end
	return hi
end

return DoorSpot
