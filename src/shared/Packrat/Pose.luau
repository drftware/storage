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
	LeftShoulder = { x = 24, y = -50, z = -8 },
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
}
Poses.EmptyStepLeft = Rig.mirror(Poses.EmptyStepRight)
Poses.EmptyPassLeft = Rig.mirror(Poses.EmptyPassRight)
Poses.FullStepLeft = Rig.mirror(Poses.FullStepRight)
Poses.FullPassLeft = Rig.mirror(Poses.FullPassRight)
Pose.Poses = Poses

-- Each walk's keys in order: a stride is the four, then it starts again (S2-06a2 steps a screen
-- through them).
Pose.Walks = {
	Empty = { "EmptyStepRight", "EmptyPassRight", "EmptyStepLeft", "EmptyPassLeft" },
	Full = { "FullStepRight", "FullPassRight", "FullStepLeft", "FullPassLeft" },
}

Pose.Names = { "Still" }
for _, walk in { Pose.Walks.Empty, Pose.Walks.Full } do
	for _, name in walk do
		table.insert(Pose.Names, name)
	end
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

return Pose
