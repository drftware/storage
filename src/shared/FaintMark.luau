--!strict
--[[
	FaintMark: the small chalk ring on one note's door frame (S1-11, GDD "At most one faint mark on
	a floor"; which unit is `Deal.markFrom`). It shows only from a few steps away with your own
	torch on it, as Phasmophobia's fingerprints show on a door only under the light you hold: walk a
	hall sweeping your beam along the frames and now and then one has something scrawled on it.
	Nothing else says so, and the corner map knows nothing of notes.

	The server sticks it on the unit's jamb as the floor is laid, hidden, and tags it (FloorBuilder);
	each screen shows it in its own beam (FaintMarkView). The art is `art/mark/` (the generated
	`Specs`). Numbers only here, so Lune tests the seeing.
]]
local FaintMark = {}

-- The tag on the mark's part (CollectionService), so a screen finds it as it streams in.
FaintMark.Tag = "FaintMark"

--[[
	Where it sits, in the door's face frame (FloorBuilder.face: origin the doorway's middle on the
	floor at the facade's outer face, +Z into the unit). On the middle of a jamb's face, which is
	0.45 studs wide on every unit and stands 0.05 proud of the facade (art/unit's `trim`,
	`trim_proud`): the steel post cover beside the door, where a hand would scrawl it.
]]
FaintMark.Trim = 0.45 -- the jamb's face width, studs (art/unit/spec.py `trim`)
FaintMark.Height = 4.4 -- studs up: about eye height, so a beam aimed at the door crosses it
FaintMark.Proud = 0.058 -- studs out from the facade: a hair off the jamb's face (0.05 proud)
-- Which jamb along the face's X. The face looks out into the hall, so to you facing the door its
-- +X is your left.
FaintMark.Side = 1 -- the left jamb as you face the door

-- Seeing it. Your beam is a cone 54 degrees across (Torch.BeamAngle); the mark shows in its
-- middle and fades out toward its edge, and only from a few steps away.
FaintMark.Near = 5.5 -- studs: from this close, it shows its fullest
FaintMark.Far = 9.5 -- studs: about three steps; past this, nothing
FaintMark.Core = 14 -- degrees off your beam's middle: inside this, it shows its fullest
FaintMark.Edge = 25 -- degrees off: from here out (near the beam's edge), nothing
FaintMark.Most = 0.7 -- how solid it gets at its fullest (0 to 1): faint chalk, never paint
FaintMark.Rise = 7 -- how fast it comes up as your beam lands (per second): it blooms, never snaps
FaintMark.Fall = 4 -- how fast it goes as the beam moves off: it lingers a moment, then it's gone

local function smooth(t: number): number
	local x = math.clamp(t, 0, 1)
	return x * x * (3 - 2 * x)
end

local EDGE_COS = math.cos(math.rad(FaintMark.Edge))
local CORE_COS = math.cos(math.rad(FaintMark.Core))

-- How much of the mark at `point`, facing out along `facing` (a unit vector into the hall), your
-- beam shows: 0 to 1, from your `eye` aimed along `aim` (a unit vector). Nothing from behind its
-- face, past `Far`, or off the beam's middle by `Edge`; its fullest within `Near` and `Core`.
function FaintMark.seen(eye: vector, aim: vector, point: vector, facing: vector): number
	local d = point - eye
	local dist = vector.magnitude(d)
	if dist >= FaintMark.Far or dist < 1e-3 or vector.dot(d, facing) >= 0 then
		return 0
	end
	local cos = vector.dot(d, aim) / dist
	if cos <= EDGE_COS then
		return 0
	end
	local beam = smooth((cos - EDGE_COS) / (CORE_COS - EDGE_COS))
	local near = smooth((FaintMark.Far - dist) / (FaintMark.Far - FaintMark.Near))
	return beam * near
end

-- The mark as a screen shows it this frame: `shown` last frame, easing toward `target` (both 0
-- to 1) over `dt` seconds, quicker coming up than going.
function FaintMark.follow(shown: number, target: number, dt: number): number
	local rate = if target > shown then FaintMark.Rise else FaintMark.Fall
	return target + (shown - target) * math.exp(-rate * dt)
end

-- The mark's transparency for how much shows (0 to 1) and your torch's light this frame (0 to 1:
-- a dying torch's flicker takes the mark with it).
function FaintMark.transparency(shown: number, light: number): number
	return 1 - FaintMark.Most * math.clamp(shown, 0, 1) * math.clamp(light, 0, 1)
end

return FaintMark
