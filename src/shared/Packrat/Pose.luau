--!strict
-- The Packrat's poses (GDD "The Packrat collects things, not people"). Its body tells players
-- what it's doing before anything else does: arms full, it's going home and ignores you; arms
-- empty, it's coming for you. So its two walks are built as opposites, read from the far end of
-- a hall on a phone (S2-06a1):
--
-- Full: hunched over the find, both pale arms hugged round it against its chest, the hood bowed
-- over it, short quick steps. A tight dark column with a pale knot at the chest, as Lethal
-- Company's Hoarding Bug scuttles home holding its scrap up.
--
-- Empty: upright and searching, the hood craned forward and turning, the long arms hanging wide
-- of the bundle and swinging past its knees, hands open. A wide shape, pale lines down both sides.
--
-- Pure: no Roblox types, so Lune checks every pose stands on the floor, stays inside its joints'
-- limits and never puts one part through another (tests/packrat.spec.luau). Angles as Rig's.

local Rig = require("../Rig")
local Specs = require("./Specs")

local Pose = {}

-- How far each joint turns, in degrees, low to high on each axis, for the middle and the right
-- side (the left mirrored in).
Pose.Limits = Rig.limits({
	Root = { x = { -25, 20 }, y = { -30, 30 }, z = { -15, 15 } },
	Waist = { x = { -45, 20 }, y = { -40, 40 }, z = { -20, 20 } },
	Neck = { x = { -50, 35 }, y = { -80, 80 }, z = { -35, 35 } },
	RightShoulder = { x = { -60, 170 }, y = { -90, 90 }, z = { -40, 170 } },
	RightElbow = { x = { 0, 150 }, y = { -60, 60 }, z = { -5, 5 } },
	RightWrist = { x = { -40, 40 }, y = { -30, 30 }, z = { -70, 70 } },
	RightHip = { x = { -40, 110 }, y = { -40, 40 }, z = { -25, 50 } },
	RightKnee = { x = { -140, 0 }, y = { -10, 10 }, z = { -5, 5 } },
	RightAnkle = { x = { -50, 30 }, y = { -20, 20 }, z = { -20, 20 } },
})

-- Both arms hugged round a find at its chest: elbows at its sides, forearms across its front,
-- the right a little higher so they pass one over the other rather than through each other
-- (solved for those places, then checked by tests/packrat.spec.luau).
local HUG: Rig.Pose = {
	RightShoulder = { x = 28, y = 50, z = 8 },
	RightElbow = { x = 95 },
	RightWrist = { z = -35 }, -- the hands curled back round it, toward the chest
	LeftShoulder = { x = 27, y = -50, z = -8 },
	LeftElbow = { x = 90 },
	LeftWrist = { z = 35 },
}

local function with(pose: Rig.Pose, more: Rig.Pose): Rig.Pose
	local out: Rig.Pose = table.clone(pose)
	for k, v in more do
		out[k] = v
	end
	return out
end

local Poses: { [string]: Rig.Pose } = {
	-- As it's found, asleep in its unit: slumped, the hood hung low, arms hanging long.
	Still = {
		Root = { x = -3 },
		Waist = { x = -14 },
		Neck = { x = -28, z = 8 },
		RightShoulder = { x = 10, z = 6 },
		RightElbow = { x = 12 },
		LeftShoulder = { x = 6, z = -4 },
		LeftElbow = { x = 20 },
		RightHip = { x = 6 },
		RightKnee = { x = -12 },
		RightAnkle = { x = 6 },
		LeftHip = { x = 4 },
		LeftKnee = { x = -8 },
		LeftAnkle = { x = 4 },
	},
	-- Empty, its right foot planted ahead: the hood craned and turned, the arm opposite the leg
	-- swung forward, both held wide of the bundle and never behind it, so from ahead both pale
	-- arms catch the light (one swung back sat in its own shadow from a hall's end).
	EmptyStepRight = {
		Root = { x = -6, y = 4 },
		Waist = { x = -16, y = -6 },
		Neck = { x = -4, y = 14, z = -6 },
		RightHip = { x = 28 },
		RightKnee = { x = -4 },
		RightAnkle = { x = -16 },
		LeftHip = { x = -20 },
		LeftKnee = { x = -22 },
		LeftAnkle = { x = 8 },
		RightShoulder = { x = 2, z = 28 },
		RightElbow = { x = 14 },
		RightWrist = { z = -12 },
		LeftShoulder = { x = 30, z = -26 },
		LeftElbow = { x = 26 },
		LeftWrist = { z = 10 },
	},
	-- Empty, passing: up on its right leg, the left swinging through, the hood looking the other way.
	EmptyPassRight = {
		Root = { x = -5 },
		Waist = { x = -17, y = -2 },
		Neck = { x = -6, y = -10, z = 4 },
		RightHip = { x = 2 },
		RightKnee = { x = -6 },
		RightAnkle = { x = 4 },
		LeftHip = { x = 18 },
		LeftKnee = { x = -50 },
		LeftAnkle = { x = -6 },
		RightShoulder = { x = 14, z = 27 },
		RightElbow = { x = 16 },
		LeftShoulder = { x = 16, z = -27 },
		LeftElbow = { x = 18 },
	},
	-- Full, its right foot planted: hunched over the find, the hood bowed over it.
	FullStepRight = with({
		Root = { x = -4 },
		Waist = { x = -13, y = -4 },
		Neck = { x = -42, y = 4 },
		RightHip = { x = 22 },
		RightKnee = { x = -10 },
		RightAnkle = { x = -10 },
		LeftHip = { x = -14 },
		LeftKnee = { x = -20 },
		LeftAnkle = { x = 6 },
	}, HUG),
	-- Full, passing: the left leg through, short, the hug held.
	FullPassRight = with({
		Root = { x = -3 },
		Waist = { x = -14, y = -1 },
		Neck = { x = -42, y = -2 },
		RightHip = { x = 2 },
		RightKnee = { x = -8 },
		RightAnkle = { x = 4 },
		LeftHip = { x = 14 },
		LeftKnee = { x = -42 },
		LeftAnkle = { x = -4 },
	}, HUG),
	-- Reaching for a find held at a player's chest: one long pale arm straight out ahead and a
	-- little wide, nearly level, fingers spread; the bundle leaning after it, its right shoulder
	-- turned into the reach, the hood craned along the arm; the other arm trailing low and wide,
	-- the near foot stepped in. From across a hall it's one long pale line out of a dark lump.
	Reach = {
		Root = { x = -8, y = 8 },
		Waist = { x = -24, y = 10 },
		Neck = { x = 6, y = -16, z = -6 },
		RightShoulder = { x = 98, y = 0, z = 28 },
		RightElbow = { x = 6 },
		RightWrist = { x = -18 },
		LeftShoulder = { x = -16, z = -24 },
		LeftElbow = { x = 24 },
		LeftWrist = { z = 12 },
		RightHip = { x = 34 },
		RightKnee = { x = -34 },
		RightAnkle = { x = 8 },
		LeftHip = { x = -14 },
		LeftKnee = { x = 0 },
		LeftAnkle = { x = 22 },
	},
	-- Taking it: both hands closed on the find ahead of its chest and pulling it in, elbows
	-- bent and coming back to its sides, the bundle rocking back over its back foot, the hood
	-- bowed to look at what it has. Between the reach and the hug the full walk holds.
	Take = {
		Root = { x = -2 },
		Waist = { x = -10 },
		Neck = { x = -36 },
		RightShoulder = { x = 30, y = 22, z = 14 },
		RightElbow = { x = 90 },
		RightWrist = { z = -30 },
		LeftShoulder = { x = 28, y = -22, z = -14 },
		LeftElbow = { x = 88 },
		LeftWrist = { z = 30 },
		RightHip = { x = 24 },
		RightKnee = { x = -12 },
		RightAnkle = { x = -10 },
		LeftHip = { x = -10 },
		LeftKnee = { x = -12 },
		LeftAnkle = { x = 16 },
	},
	-- Putting a find down on its pile: crouched and folded over it, both long arms down ahead
	-- of its knees with the find low between its hands, the hood hung over it.
	PutDown = {
		Root = { x = -15 },
		Waist = { x = -42 },
		Neck = { x = -20 },
		RightShoulder = { x = 64, y = 34, z = 4 },
		RightElbow = { x = 16 },
		RightWrist = { z = -24 },
		LeftShoulder = { x = 64, y = -34, z = -4 },
		LeftElbow = { x = 16 },
		LeftWrist = { z = 24 },
		RightHip = { x = 54 },
		RightKnee = { x = -68 },
		RightAnkle = { x = 29 },
		LeftHip = { x = 54 },
		LeftKnee = { x = -68 },
		LeftAnkle = { x = 29 },
	},
	-- Wrapping you, the catch thrown at your eyes (S2-06c2, CaughtLunge): reared up over you,
	-- both long pale arms raised either side of the hood, elbows out, the open hands curled in to
	-- fold round you; the hood bowed down at you. Flown at your eye by its hood, the two pale hands
	-- frame it at the edges of a phone's screen as the dark bundle fills the middle.
	Lunge = {
		Root = { x = -4 },
		Waist = { x = -8 },
		Neck = { x = -10 },
		RightShoulder = { x = 105, y = 0, z = 40 },
		RightElbow = { x = 125 },
		RightWrist = { z = -24 },
		LeftShoulder = { x = 105, y = 0, z = -40 },
		LeftElbow = { x = 125 },
		LeftWrist = { z = 24 },
		RightHip = { x = 34 },
		RightKnee = { x = -34 },
		RightAnkle = { x = 8 },
		LeftHip = { x = -14 },
		LeftKnee = { x = 0 },
		LeftAnkle = { x = 22 },
	},
}
Poses.EmptyStepLeft = Rig.mirror(Poses.EmptyStepRight)
Poses.EmptyPassLeft = Rig.mirror(Poses.EmptyPassRight)
-- The hug isn't mirrored: its right forearm stays over its left the whole way, or the two
-- would pass through each other between a right step and a left one.
Poses.FullStepLeft = with(Rig.mirror(Poses.FullStepRight), HUG)
Poses.FullPassLeft = with(Rig.mirror(Poses.FullPassRight), HUG)
Pose.Poses = Poses

-- The poses it holds still in, standing in one place: as it's found, reaching, taking and
-- putting down. Each is one frame (`held`).
local HELD: { string } = { "Still", "Reach", "Take", "PutDown" }

-- Its walks (feel). Each is four keys to a stride, blended smoothly by how far it has walked,
-- so it glides where the Mannequin jerks: a long loping search with its arms empty, short quick
-- steps hunched over a find.
export type Walk = "Empty" | "Full"
Pose.Walk = {
	-- Each walk's keys in order: a stride is the four, then it starts again.
	Keys = {
		Empty = { "EmptyStepRight", "EmptyPassRight", "EmptyStepLeft", "EmptyPassLeft" },
		Full = { "FullStepRight", "FullPassRight", "FullStepLeft", "FullPassLeft" },
	},
	-- Studs one key carries it: half the spread of its feet in a step, so a planted foot stays
	-- where it landed instead of skating (tests/packrat.spec.luau holds both to the feet). Empty,
	-- a stride of 6.4 studs; full, 4.6, quicker and shorter, so it hurries home.
	Step = { Empty = 1.6, Full = 1.15 },
	-- How many frames a screen shows from one key to the next: at a hunting pace a key lasts
	-- about a tenth of a second, so 8 is smoother than a phone's frame rate shows. Fewer and the
	-- arms visibly tick from place to place.
	Frames = 8,
}

local function keysOf(walk: Walk): { string }
	return if walk == "Full" then Pose.Walk.Keys.Full else Pose.Walk.Keys.Empty
end

local function stepOf(walk: Walk): number
	return if walk == "Full" then Pose.Walk.Step.Full else Pose.Walk.Step.Empty
end

Pose.Names = table.clone(HELD)
for _, keys in { Pose.Walk.Keys.Empty, Pose.Walk.Keys.Full } do
	for _, name in keys do
		table.insert(Pose.Names, name)
	end
end

-- Every pose a screen shows is one of these frames, so each screen works each one out once and
-- turns a body's joints only when its frame changes (as the Mannequin's, L-06b4a). First the
-- held poses in `HELD`'s order (Still is 1); then the empty walk, `Walk.Frames` for each key;
-- then the full walk.
local PER_WALK = 4 * Pose.Walk.Frames
local EMPTY = #HELD + 1 -- the empty walk's first frame
Pose.Frames = #HELD + 2 * PER_WALK

local heldFrames: { [string]: number } = {}
for i, name in HELD do
	heldFrames[name] = i
end

-- The frame for a pose it holds still in (Still, Reach, Take or PutDown); nil for any other.
function Pose.held(name: string): number?
	return heldFrames[name]
end

-- A smooth curve through four values a key apart, at `t` (0 to 1) between the middle two:
-- Catmull-Rom, so every joint keeps moving through each key instead of stopping on it.
local function spline(p0: number, p1: number, p2: number, p3: number, t: number): number
	local t2 = t * t
	return 0.5
		* (
			2 * p1
			+ (p2 - p0) * t
			+ (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
			+ (3 * p1 - p0 - 3 * p2 + p3) * t2 * t
		)
end

local REST: Rig.Angles = {}

-- A walk `t` of the way from key `k` (counted from its first, 0) to the next.
local function between(walk: Walk, k: number, t: number): Rig.Pose
	local keys = keysOf(walk)
	local n = #keys
	local p1 = Poses[keys[k % n + 1]]
	if t <= 0 then
		return p1
	end
	local p0, p2, p3 =
		Poses[keys[(k - 1) % n + 1]], Poses[keys[(k + 1) % n + 1]], Poses[keys[(k + 2) % n + 1]]
	local out: Rig.Pose = {}
	for joint in Pose.Limits do
		if p0[joint] or p1[joint] or p2[joint] or p3[joint] then
			local a, b, c, d =
				p0[joint] or REST, p1[joint] or REST, p2[joint] or REST, p3[joint] or REST
			out[joint] = {
				x = spline(a.x or 0, b.x or 0, c.x or 0, d.x or 0, t),
				y = spline(a.y or 0, b.y or 0, c.y or 0, d.y or 0, t),
				z = spline(a.z or 0, b.z or 0, c.z or 0, d.z or 0, t),
			}
		end
	end
	return out
end

-- Its walk once it has gone `travelled` studs.
function Pose.at(walk: Walk, travelled: number): Rig.Pose
	local q = travelled / stepOf(walk)
	local k = math.floor(q)
	return between(walk, k, q - k)
end

-- How far along a walk it is after `travelled` studs, in frames, never going back: a screen
-- keeps the furthest it has shown.
function Pose.along(walk: Walk, travelled: number): number
	return math.floor(travelled / stepOf(walk) * Pose.Walk.Frames + 0.5)
end

-- The frame for a walk shown `along` its keys (Pose.along).
function Pose.frameAt(walk: Walk, along: number): number
	return (if walk == "Full" then EMPTY + PER_WALK else EMPTY) + along % PER_WALK
end

-- The frame it shows walking after `travelled` studs.
function Pose.frame(walk: Walk, travelled: number): number
	return Pose.frameAt(walk, Pose.along(walk, travelled))
end

-- The pose a frame shows.
function Pose.ofFrame(frame: number): Rig.Pose
	if frame <= #HELD then
		return Poses[HELD[math.max(frame, 1)]]
	end
	local n = frame - EMPTY
	local walk: Walk = if n < PER_WALK then "Empty" else "Full"
	n %= PER_WALK
	local per = Pose.Walk.Frames
	return between(walk, n // per, (n % per) / per)
end

function Pose.check(pose: Rig.Pose): { string }
	return Rig.check(Pose.Limits, pose)
end

function Pose.solve(pose: Rig.Pose): ({ [string]: Rig.Transform }, number)
	return Rig.solve(Specs, pose)
end

function Pose.turns(pose: Rig.Pose): { [string]: Rig.Transform }
	return Rig.turns(Specs, pose)
end

-- Where a carried find's middle sits in a pose, from the floor between its feet: the Carry point
-- riding its UpperTorso, turned as the chest is.
function Pose.carry(pose: Rig.Pose): Rig.Transform
	local placed = Pose.solve(pose)
	local t = table.clone(placed.UpperTorso)
	local at = Rig.apply(t, Specs.Carry)
	t[10], t[11], t[12] = at[1], at[2], at[3]
	return t
end

-- Which hands hold the find in a pose that holds one in its hands: reaching, it's in the right
-- hand's fingers; taking and putting down, between both hands.
Pose.InHands = {
	Reach = { "Right" },
	Take = { "Left", "Right" },
	PutDown = { "Left", "Right" },
} :: { [string]: { string } }

-- Where a find held in the hands sits in a pose, from the floor between its feet, turned as the
-- chest is: at one hand's fingertips, or between two hands' palms.
function Pose.grip(pose: Rig.Pose, hands: { string }): Rig.Transform
	local placed = Pose.solve(pose)
	local t = table.clone(placed.UpperTorso)
	local at = { 0, 0, 0 }
	for _, side in hands do
		local c = Specs.Capsules[side .. "Hand"][1]
		local p = if #hands == 1
			then Rig.apply(placed[side .. "Hand"], c.B)
			else Rig.apply(
				placed[side .. "Hand"],
				{ (c.A[1] + c.B[1]) / 2, (c.A[2] + c.B[2]) / 2, (c.A[3] + c.B[3]) / 2 }
			)
		for i = 1, 3 do
			at[i] += p[i] / #hands
		end
	end
	t[10], t[11], t[12] = at[1], at[2], at[3]
	return t
end

return Pose
