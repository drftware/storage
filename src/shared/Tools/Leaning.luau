--!strict
--[[
	Leaning: the ladder leaned on a unit's front and climbed (L-13b2a), pure so Lune checks it
	(tests/leaning.spec.luau). The moment: a keeper's coming, one friend leans the ladder on a
	unit's front, it shoots up with a rattle, and the team climbs out of reach onto the wire top,
	as Lethal Company's extension ladder shoots up when placed and is climbed.

	Leaning it: the ladder swings up off your shoulder against the front beside the door, its feet
	in the hall at the 4-to-1 rule (a stud out for every four up, as a real ladder stands), its back
	resting on the front's top edge, then the fly runs out its travel and locks, so it reaches past
	the edge. Climbing it is a pressed move the game makes, as the crawl is (DOORS' and Pressure's
	vents): onto the ladder, up it rung over rung, and over the edge onto your belly on the wire top,
	where you lie until you climb back down. Each climber lies in their own spot along the front, so
	the whole team fits.

	Every number is in the front's frame (`RollUpDoor.frame`: origin at the door's bottom middle on
	its curtain, +Z into the unit, -Z out to the hall, +Y up); x is along the front. A body's pose is
	its root's place (x, y, z) and its pitch: turned to face into the unit, then tipped forward
	`pitch` radians about x (0 standing, -pi/2 flat on your belly, head into the unit).

	The ladder's own frame is the tool's (`Specs/Ladder`): its top towards -Z, its face (the fly's
	side) +Y, measured from the grip. Leaned, it's turned to face the hall and pitched up `Angle`, so
	a point (lx, ly, lz) of it lands at x = ox - lx, y = oy + ly cos - lz sin, z = oz - ly sin - lz cos.
]]

local Leaning = {}

-- The 4-to-1 rule: a ladder's feet a quarter of its height out from what it leans on.
Leaning.Ratio = 4
Leaning.Angle = math.atan(Leaning.Ratio) -- radians up from the floor, about 76 degrees
-- Studs in from the door's edge to the ladder's middle: beside the door, so the doorway stays clear.
Leaning.SideIn = 0.9

-- Raising it, as every screen plays it: up off the shoulder against the front, then the fly runs
-- out, accelerating, and stops dead as its locks catch.
Leaning.Swing = 0.4
Leaning.RunOut = 0.45
Leaning.Raised = Leaning.Swing + Leaning.RunOut

-- The climber, in the ladder's frame: your root this far in front of its middle (its face is 0.5
-- out, your root half a stud deep), so your hands and feet are on the rungs.
Leaning.Off = 1.1
-- At the top of the climb your root is this far below the edge: chest and head over it.
Leaning.TopRise = -0.3
-- Lying on the wire top: your root this far above it (Crawling's prone height), your feet just in
-- from the edge, the climbers side by side along the front.
Leaning.ProneUp = 0.8
Leaning.LieIn = 3.3 -- from the front's face to your root: your feet (3 behind it) just over the edge
Leaning.SpotStep = 2.2 -- between two climbers' roots, side by side
Leaning.SpotMargin = 1.3 -- a lying root's least distance from a side wall: half a body and a gap

-- The move up: onto the ladder from where you pressed, up it, over the edge.
Leaning.Mount = 0.25
Leaning.ClimbSpeed = 7 -- studs a second along the ladder: quick, it's the escape
Leaning.StepEvery = 2 -- studs along the ladder per step (two rungs: a hand and a foot)
Leaning.Surge = 0.5 -- how much each step surges (0 a steady glide, 1 stopping between steps)
Leaning.Roll = 0.6 -- over the edge onto your belly
Leaning.Hump = 0.5 -- studs your body lifts over the edge as it rolls
-- The move down: off the top back onto the ladder, down it, a step back into the hall.
Leaning.Slide = 0.5
Leaning.DownSpeed = 8
Leaning.Dismount = 0.3
Leaning.StepBack = 1.2 -- studs out from the ladder where you stand in the hall after

-- The buttons' reaches (studs from your root) and the server's checks.
Leaning.LeanReach = 10 -- the Lean button is up by the front's top edge: from the hall below it
Leaning.ClimbReach = 6 -- Climb and Take, at the ladder's foot
Leaning.DownReach = 5 -- Climb down, just ahead of you as you lie on the top
Leaning.RangeSlack = 3 -- past a reach the server still accepts: a moving player's lag
Leaning.RepeatSeconds = 0.3 -- a press closer than this to your last one is dropped
Leaning.EndSlack = 0.6 -- the server waits this long past a move for your screen to have moved you

-- Studs a keeper hears it from (L-06b): the ladder going up rings down the halls; a climb is quieter.
Leaning.RaiseHeard = 60
Leaning.ClimbHeard = 30

-- A friend's arms while they roll over and lie on the top (R15 shoulders, about X, as Crawling's):
-- reaching ahead, hands on the wire.
Leaning.ArmRest = math.rad(145)

-- The ladder's shape from `Specs/Ladder`, in its own frame (studs from the grip).
export type Shape = {
	feetZ: number, -- the feet pads' middle, along it (Feet.Z)
	back: number, -- its back face (the wall side, -Y): Bounds' lowest y
	centreX: number, -- its middle across (Bounds.Centre.X)
	topZ: number, -- the fly's caps, collapsed (Top.Z)
	travel: number, -- how far the fly runs out (Travel)
}

-- A unit's front from its `Specs`, in the front's frame.
export type Front = {
	edgeY: number, -- the front's top edge (the header's top)
	faceZ: number, -- the front's outer face (negative: out from the curtain)
	wireY: number, -- the wire top's upper surface
	doorWidth: number,
	width: number, -- the unit's inside width
}

-- A ladder leaned on a front: where its grip is and what the climb needs.
export type Fit = {
	edgeY: number,
	faceZ: number,
	wireY: number,
	leanX: number, -- the ladder's middle along the front
	ox: number,
	oy: number,
	oz: number,
	contact: number, -- along the ladder (its z) where its back rests on the edge
	reach: number, -- along the ladder (its z) of the fly's caps, run out
	spots: { number }, -- each climber's lying root along the front (x), the ladder's own first
}

local function smooth(k: number): number
	local c = math.clamp(k, 0, 1)
	return c * c * (3 - 2 * c)
end

local function lerp(a: number, b: number, k: number): number
	return a + (b - a) * k
end

-- Where a point of the leaned ladder (its own frame) is in the front's frame.
function Leaning.point(fit: Fit, lx: number, ly: number, lz: number): (number, number, number)
	local s, c = math.sin(Leaning.Angle), math.cos(Leaning.Angle)
	return fit.ox - lx, fit.oy + ly * c - lz * s, fit.oz - ly * s - lz * c
end

--[[
	The ladder leaned on `front`: its feet on the floor, its back on the top edge, beside the door,
	and where its climbers lie on the top (as many as fit across the unit, a body apart).
]]
function Leaning.fit(shape: Shape, front: Front): Fit
	local s, c = math.sin(Leaning.Angle), math.cos(Leaning.Angle)
	local leanX = front.doorWidth / 2 - Leaning.SideIn
	-- the feet's pads (y 0 in its frame) on the floor
	local oy = shape.feetZ * s
	-- the back face (y = back) through the edge: where along it that is, then where it stands
	local contact = (oy + shape.back * c - front.edgeY) / s
	local oz = front.faceZ + shape.back * s + contact * c
	local spots = {}
	local limit = front.width / 2 - Leaning.SpotMargin
	local x = leanX
	while math.abs(x) <= limit + 1e-6 do
		table.insert(spots, x)
		x -= Leaning.SpotStep
	end
	return {
		edgeY = front.edgeY,
		faceZ = front.faceZ,
		wireY = front.wireY,
		leanX = leanX,
		ox = leanX + shape.centreX,
		oy = oy,
		oz = oz,
		contact = contact,
		reach = shape.topZ - shape.travel,
		spots = spots,
	}
end

-- A climber on the ladder `along` studs up it (its z: negative is up): root place and pitch.
function Leaning.onLadder(fit: Fit, along: number): (number, number, number, number)
	local _, y, z = Leaning.point(fit, 0, Leaning.Off, along)
	return fit.leanX, y, z, Leaning.Angle - math.pi / 2
end

-- Along the ladder where a climber stands on its foot (root `standUp` high), and where they reach
-- the top (root just under the edge).
function Leaning.span(fit: Fit, standUp: number): (number, number)
	local s, c = math.sin(Leaning.Angle), math.cos(Leaning.Angle)
	local base = fit.oy + Leaning.Off * c
	return (base - standUp) / s, (base - (fit.edgeY + Leaning.TopRise)) / s
end

-- A climber lying on the wire top in spot `spot`.
function Leaning.lying(fit: Fit, spot: number): (number, number, number, number)
	local x = fit.spots[spot] or fit.leanX
	return x, fit.wireY + Leaning.ProneUp, fit.faceZ + Leaning.LieIn, -math.pi / 2
end

-- Where a climber stands in the hall after coming down.
function Leaning.stood(fit: Fit, standUp: number): (number, number, number, number)
	local foot = Leaning.span(fit, standUp)
	local x, _, z = Leaning.onLadder(fit, foot)
	return x, standUp, z - Leaning.StepBack, 0
end

-- Seconds to climb up, and down.
function Leaning.climbTime(fit: Fit, standUp: number): number
	local foot, top = Leaning.span(fit, standUp)
	return (foot - top) / Leaning.ClimbSpeed
end
function Leaning.downTime(fit: Fit, standUp: number): number
	local foot, top = Leaning.span(fit, standUp)
	return (foot - top) / Leaning.DownSpeed
end

function Leaning.upSeconds(fit: Fit, standUp: number): number
	return Leaning.Mount + Leaning.climbTime(fit, standUp) + Leaning.Roll
end
function Leaning.downSeconds(fit: Fit, standUp: number): number
	return Leaning.Slide + Leaning.downTime(fit, standUp) + Leaning.Dismount
end
-- How long the ladder is busy with a climber going up (onto it and up it, not the roll) or down.
function Leaning.upBusy(fit: Fit, standUp: number): number
	return Leaning.Mount + Leaning.climbTime(fit, standUp)
end

-- How far up the steps you are (0 to 1) at `u` (0 to 1) of the climb: always on, surging per step.
function Leaning.progress(u: number, steps: number): number
	local c = math.clamp(u, 0, 1)
	local w = 2 * math.pi * steps
	return c - Leaning.Surge * math.sin(w * c) / w
end

local function steps(fit: Fit, standUp: number): number
	local foot, top = Leaning.span(fit, standUp)
	return math.max(1, math.floor((foot - top) / Leaning.StepEvery + 0.5))
end

-- Between the top of the ladder and lying in `spot`, `k` (0 to 1) of the way: over the edge in an
-- arc, tipping forward onto your belly.
local function over(
	fit: Fit,
	spot: number,
	standUp: number,
	k: number
): (number, number, number, number)
	local _, top = Leaning.span(fit, standUp)
	local ax, ay, az, ap = Leaning.onLadder(fit, top)
	local bx, by, bz, bp = Leaning.lying(fit, spot)
	local m = smooth(k)
	-- the tip leads: you lean over the edge before your hips come up over it
	local tip = smooth(math.min(1, k * 1.4))
	return lerp(ax, bx, m),
		lerp(ay, by, m) + Leaning.Hump * math.sin(math.pi * m),
		lerp(az, bz, m),
		lerp(ap, bp, tip)
end

--[[
	The climb up, `t` seconds in: your root's place and pitch, and how far to go from where you
	stood as you pressed Climb toward that (`blend`, 0 to 1). Past its end you lie on the top.
]]
function Leaning.up(
	t: number,
	fit: Fit,
	spot: number,
	standUp: number
): (number, number, number, number, number)
	local foot, top = Leaning.span(fit, standUp)
	if t < Leaning.Mount then
		local x, y, z, p = Leaning.onLadder(fit, foot)
		return x, y, z, p, smooth(t / Leaning.Mount)
	end
	local climb = Leaning.climbTime(fit, standUp)
	local s = t - Leaning.Mount
	if s < climb then
		local k = Leaning.progress(s / climb, steps(fit, standUp))
		local x, y, z, p = Leaning.onLadder(fit, lerp(foot, top, k))
		return x, y, z, p, 1
	end
	local x, y, z, p = over(fit, spot, standUp, (s - climb) / Leaning.Roll)
	return x, y, z, p, 1
end

-- The climb down, `t` seconds in: off the top back onto the ladder, down it, a step back.
function Leaning.down(
	t: number,
	fit: Fit,
	spot: number,
	standUp: number
): (number, number, number, number)
	if t < Leaning.Slide then
		return over(fit, spot, standUp, 1 - t / Leaning.Slide)
	end
	local foot, top = Leaning.span(fit, standUp)
	local climb = Leaning.downTime(fit, standUp)
	local s = t - Leaning.Slide
	if s < climb then
		local k = Leaning.progress(s / climb, steps(fit, standUp))
		return Leaning.onLadder(fit, lerp(top, foot, k))
	end
	local k = smooth((s - climb) / Leaning.Dismount)
	local ax, ay, az, ap = Leaning.onLadder(fit, foot)
	local bx, by, bz, bp = Leaning.stood(fit, standUp)
	return lerp(ax, bx, k), lerp(ay, by, k), lerp(az, bz, k), lerp(ap, bp, k)
end

-- How far the raised ladder has come off your shoulder toward the front (0 to 1, a quick swing
-- that settles), and how far its fly has run out (0 to 1, speeding up until its locks catch).
function Leaning.raise(t: number): (number, number)
	local swing = math.clamp(t / Leaning.Swing, 0, 1)
	local eased = 1 - (1 - swing) ^ 3
	local run = math.clamp((t - Leaning.Swing) / Leaning.RunOut, 0, 1)
	return eased, run * run
end

-- A friend's arms on the top (0 to 1 of the pose over their animation): coming in as they roll
-- over the edge, held while they lie, going as they slide back onto the ladder.
function Leaning.arms(move: "Up" | "Top" | "Down", t: number, fit: Fit, standUp: number): number
	if move == "Top" then
		return 1
	elseif move == "Up" then
		local start = Leaning.upBusy(fit, standUp)
		return smooth((t - start) / (Leaning.Roll * 0.5))
	end
	return 1 - smooth(t / Leaning.Slide)
end

-- A stretch of a recording (as Crawling's): played once from `from` for `length` seconds.
export type Sound = {
	id: string,
	from: number,
	length: number,
	volume: number,
	pitch: number,
	near: number, -- full volume within this
	reach: number, -- heard to this many studs
}

Leaning.Sounds = {
	-- Pro Sound Effects' "Metal Ladder Hits 1": a bang at 0 s and its ring (to 0.6 s), lower:
	-- the ladder's top landing on the front
	Lands = {
		id = "rbxassetid://9116718918",
		from = 0,
		length = 0.7,
		volume = 0.6,
		pitch = 0.85,
		near = 8,
		reach = Leaning.RaiseHeard,
	} :: Sound,
	-- Pro Sound Effects' "Chain Movement On Aluminum Ladder 13": a steady drag of metal on an
	-- aluminium ladder from 0.3 s, quicker: the fly and its rope running out
	RunOut = {
		id = "rbxassetid://9113761047",
		from = 0.35,
		length = 0.55,
		volume = 0.7,
		pitch = 1.2,
		near = 8,
		reach = Leaning.RaiseHeard,
	} :: Sound,
	-- the same bang, short and high: the fly's locks catching on a rung
	Locks = {
		id = "rbxassetid://9116718918",
		from = 0,
		length = 0.35,
		volume = 0.55,
		pitch = 1.45,
		near = 8,
		reach = Leaning.RaiseHeard,
	} :: Sound,
	-- Pro Sound Effects' "Fire Escape 2": a grab and climb up a metal ladder, two loud steps in its
	-- first 1.4 s and the rattle between: you on the rungs
	Climb = {
		id = "rbxassetid://9114437085",
		from = 0.15,
		length = 1.3,
		volume = 0.6,
		pitch = 1.15,
		near = 6,
		reach = Leaning.ClimbHeard,
	} :: Sound,
	-- Pro Sound Effects' "Chain- Link Fence Impacts Metal Rattle 1": a hit at 0.3 s, rattling to
	-- 1.6 s: your body landing on the wire top
	Wire = {
		id = "rbxassetid://9113755181",
		from = 0.28,
		length = 1.2,
		volume = 0.55,
		pitch = 1,
		near = 6,
		reach = Leaning.ClimbHeard,
	} :: Sound,
	-- its tail (from 0.9 s), quieter: the wire shifting as you slide off it
	Shift = {
		id = "rbxassetid://9113755181",
		from = 0.9,
		length = 0.6,
		volume = 0.35,
		pitch = 1.1,
		near = 6,
		reach = Leaning.ClimbHeard,
	} :: Sound,
}
-- A sound's last stretch fades this long rather than stopping dead.
Leaning.Fade = 0.15

-- What plays as a move goes, in order: each `at` seconds in, a sound, and a kick to the mover's
-- view (Shake trauma, 0 for none).
export type Cue = { at: number, sound: Sound, kick: number }

-- The ladder going up: its top landing on the front, the fly running out, the locks catching.
function Leaning.raiseCues(): { Cue }
	return {
		{ at = Leaning.Swing * 0.9, sound = Leaning.Sounds.Lands, kick = 0 },
		{ at = Leaning.Swing, sound = Leaning.Sounds.RunOut, kick = 0 },
		{ at = Leaning.Raised, sound = Leaning.Sounds.Locks, kick = 0 },
	}
end

-- A climb: up the rungs and onto the wire with a thump, or off the wire and down the rungs.
function Leaning.cues(move: "Up" | "Down", fit: Fit, standUp: number): { Cue }
	if move == "Up" then
		return {
			{ at = Leaning.Mount * 0.5, sound = Leaning.Sounds.Climb, kick = 0 },
			{
				at = Leaning.upBusy(fit, standUp) + Leaning.Roll * 0.7,
				sound = Leaning.Sounds.Wire,
				kick = 0.15,
			},
		}
	end
	return {
		{ at = 0, sound = Leaning.Sounds.Shift, kick = 0 },
		{ at = Leaning.Slide * 0.8, sound = Leaning.Sounds.Climb, kick = 0 },
	}
end

return Leaning
