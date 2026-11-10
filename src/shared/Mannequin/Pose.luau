--!strict
-- The Mannequin's poses (GDD Keepers): it moves only while no light is on it, so players never
-- see it walk. They see where it stopped: the next time a light finds it, it's a step closer and
-- standing differently, as Five Nights at Freddy's animatronics are somewhere new each time the
-- camera comes back, and SCP-173 in SCP: Containment Breach moves only while unseen.
--
-- So its walk is stop-motion: it holds each of four strong key poses, then snaps to the next,
-- and a light that catches it freezes it on a key, never in a blur between two (`freeze`). Those
-- keys are what players remember: mid-step, an arm reaching for whoever is holding the light.
--
-- Pure: no Roblox types, so Lune checks every pose stands on the floor, stays inside its joints'
-- limits and never puts one part through another (tests/mannequin.spec.luau). Angles are degrees
-- about the figure's own axes at rest (X its right, Y up, Z behind it): +X swings a hanging limb
-- forward and tips the head back, +Y turns to its left, +Z swings a hanging limb to its right.

local Specs = require("./Specs")

export type Angles = { x: number?, y: number?, z: number? }
export type Pose = { [string]: Angles } -- by R15 joint name; a joint left out stands at rest
export type Transform = { number } -- 12 numbers: a rotation row by row, then a position

local Pose = {}

-- How far each joint turns, in degrees, low to high on each axis, for the middle and the right
-- side; the left side's are these mirrored. A pose outside them would read as broken rather
-- than as a mannequin standing wrong.
local LIMITS: { [string]: { [string]: { number } } } = {
	Root = { x = { -20, 20 }, y = { -30, 30 }, z = { -15, 15 } },
	Waist = { x = { -40, 20 }, y = { -35, 35 }, z = { -20, 20 } },
	Neck = { x = { -45, 35 }, y = { -75, 75 }, z = { -35, 35 } },
	RightShoulder = { x = { -60, 170 }, y = { -80, 80 }, z = { -30, 170 } },
	RightElbow = { x = { 0, 145 }, y = { -60, 60 }, z = { -5, 5 } },
	RightWrist = { x = { -30, 30 }, y = { -20, 20 }, z = { -70, 70 } },
	RightHip = { x = { -35, 120 }, y = { -40, 40 }, z = { -25, 50 } },
	RightKnee = { x = { -150, 0 }, y = { -10, 10 }, z = { -5, 5 } },
	RightAnkle = { x = { -50, 25 }, y = { -20, 20 }, z = { -20, 20 } },
}

-- The walk (feel): `Step` is how far one step carries it (studs; about its stride, so its feet
-- don't skate far), `Hold` how much of each step it stands still on a key before snapping to
-- the next. More hold, a jerkier and more mannequin-like walk; how fast it goes is the hunt's
-- (L-06b), never faster than a player.
Pose.Walk = {
	Keys = { "StepRight", "PassRight", "StepLeft", "PassLeft" },
	Step = 2.7,
	Hold = 0.55,
	-- How many steps each screen shows a snap from one key to the next in (`Pose.frame`): at its
	-- top speed a snap takes about 0.08 s, five frames of a 60 Hz screen, so 8 never shows a
	-- stutter inside the snap. Fewer would read as a twitch, more costs nothing seen.
	Snaps = 8,
}

local function mirrorName(name: string): string
	if string.sub(name, 1, 4) == "Left" then
		return "Right" .. string.sub(name, 5)
	elseif string.sub(name, 1, 5) == "Right" then
		return "Left" .. string.sub(name, 6)
	end
	return name
end

-- The same pose for the other side: left and right swap, and turns about Y and Z reverse.
function Pose.mirror(pose: Pose): Pose
	local out: Pose = {}
	for joint, a in pose do
		out[mirrorName(joint)] =
			{ x = a.x, y = if a.y then -a.y else nil, z = if a.z then -a.z else nil }
	end
	return out
end

Pose.Limits = {} :: { [string]: { [string]: { number } } }
for joint, axes in LIMITS do
	Pose.Limits[joint] = axes
	if string.sub(joint, 1, 5) == "Right" then
		local y, z = axes.y, axes.z
		Pose.Limits[mirrorName(joint)] = { x = axes.x, y = { -y[2], -y[1] }, z = { -z[2], -z[1] } }
	end
end

local Poses: { [string]: Pose } = {
	-- As it's found: standing where it was left, its weight on one leg, its head hung and cocked
	-- to one side, one elbow bent: a shop's display pose gone slack.
	Still = {
		Root = { z = -3 },
		Waist = { y = 8, z = 4 },
		Neck = { x = -20, y = -18, z = 14 },
		RightShoulder = { x = 10, z = 10 },
		RightElbow = { x = 18 },
		RightWrist = { z = -8 },
		LeftShoulder = { x = -6, z = -8 },
		LeftElbow = { x = 35, y = -25 },
		LeftWrist = { z = 12 },
		RightHip = { x = 8, z = 5 },
		RightKnee = { x = -16 },
		RightAnkle = { x = 8, z = -5 },
		LeftHip = { z = -4 },
		LeftAnkle = { z = 4 },
	},
	-- Mid-step, leaning in, its right foot down ahead and its left arm out level at you, palm
	-- down, fingers drooping.
	StepRight = {
		Root = { x = -6 },
		Waist = { x = -6, y = -10 },
		Neck = { x = 6, y = 8, z = -6 },
		RightHip = { x = 30, z = 2 },
		RightKnee = { x = -10 },
		RightAnkle = { x = -12 },
		LeftHip = { x = -20, z = -2 },
		LeftKnee = { x = -24 },
		LeftAnkle = { x = 18 },
		LeftShoulder = { x = 95, y = -75, z = -4 },
		LeftElbow = { x = 8 },
		LeftWrist = { z = 25 },
		RightShoulder = { x = -25, z = 6 },
		RightElbow = { x = 18 },
	},
	-- On its right foot, the left swinging through, the reaching arm still up.
	PassRight = {
		Root = { x = -4 },
		Waist = { x = -4, y = -3 },
		Neck = { x = 4, y = 3, z = -3 },
		RightHip = { x = 6 },
		RightKnee = { x = -4 },
		RightAnkle = { x = 2 },
		LeftHip = { x = 24, z = -2 },
		LeftKnee = { x = -48 },
		LeftAnkle = { x = 8 },
		LeftShoulder = { x = 70, y = -60, z = -4 },
		LeftElbow = { x = 18 },
		LeftWrist = { z = 15 },
		RightShoulder = { x = 10, z = 6 },
		RightElbow = { x = 24 },
	},
}
Poses.StepLeft = Pose.mirror(Poses.StepRight)
Poses.PassLeft = Pose.mirror(Poses.PassRight)
Pose.Poses = Poses
Pose.Names = { "Still", "StepRight", "PassRight", "StepLeft", "PassLeft" }

-- What's wrong with a pose, if anything: joints it doesn't have, turns past a joint's limits.
function Pose.check(pose: Pose): { string }
	local out = {}
	for joint, a in pose do
		local lim = Pose.Limits[joint]
		if not lim then
			table.insert(out, `no joint {joint}`)
			continue
		end
		for _, axis in { "x", "y", "z" } do
			local v = (a :: any)[axis] :: number? -- any: indexing the record by a key from a list
			local r = lim[axis]
			if v and (v < r[1] or v > r[2]) then
				table.insert(out, `{joint}.{axis} {v} outside {r[1]}..{r[2]}`)
			end
		end
	end
	return out
end

-- Part way from one pose to another, every joint's angles straight between the two.
function Pose.blend(a: Pose, b: Pose, t: number): Pose
	local out: Pose = {}
	for joint in Pose.Limits do
		local p, q = a[joint], b[joint]
		if p or q then
			local p0: Angles, q0: Angles = p or {}, q or {}
			out[joint] = {
				x = (p0.x or 0) + ((q0.x or 0) - (p0.x or 0)) * t,
				y = (p0.y or 0) + ((q0.y or 0) - (p0.y or 0)) * t,
				z = (p0.z or 0) + ((q0.z or 0) - (p0.z or 0)) * t,
			}
		end
	end
	return out
end

local function keyAt(travelled: number): (number, number)
	local q = travelled / Pose.Walk.Step
	local k = math.floor(q)
	return k % #Pose.Walk.Keys + 1, q - k
end

-- Its walk once it has gone `travelled` studs: holding a key, or snapping to the next.
function Pose.at(travelled: number): Pose
	local keys, hold = Pose.Walk.Keys, Pose.Walk.Hold
	local k, f = keyAt(travelled)
	local a = Poses[keys[k]]
	if f <= hold then
		return a
	end
	local t = (f - hold) / (1 - hold)
	return Pose.blend(a, Poses[keys[k % #keys + 1]], t * t * (3 - 2 * t))
end

-- The key a light freezes it on after `travelled` studs: the one it holds, or, caught mid-snap,
-- the one it was snapping into, so it's always a step closer and never a blur.
function Pose.freeze(travelled: number): string
	local keys = Pose.Walk.Keys
	local k, f = keyAt(travelled)
	return if f <= Pose.Walk.Hold then keys[k] else keys[k % #keys + 1]
end

-- How a screen poses a keeper: slack as it's found (Still), walking (Walk), or stopped mid-stride
-- (Stop: frozen on a key, as `freeze` says).
export type How = "Still" | "Walk" | "Stop"

-- Every pose a screen shows is one of these frames (L-06b4a), so each screen works each one out
-- once and turns a body's joints only when its frame changes. Frame 1 is Still; then, for each of
-- the walk's keys, the key held and the `Walk.Snaps - 1` steps of the snap into the next.
Pose.Frames = 1 + #Pose.Walk.Keys * Pose.Walk.Snaps

-- The frame it shows after `travelled` studs: Still; its walk (the key it holds, or the nearest
-- step of the snap to the next); or stopped, on the key `freeze` says.
function Pose.frame(travelled: number, how: How): number
	if how == "Still" then
		return 1
	end
	local count, snaps, hold = #Pose.Walk.Keys, Pose.Walk.Snaps, Pose.Walk.Hold
	local k, f = keyAt(travelled)
	local s = 0
	if f > hold then
		s = if how == "Stop" then snaps else math.floor((f - hold) / (1 - hold) * snaps + 0.5)
	end
	if s >= snaps then
		k, s = k % count + 1, 0
	end
	return 2 + (k - 1) * snaps + s
end

-- The pose a frame shows.
function Pose.ofFrame(frame: number): Pose
	if frame <= 1 then
		return Poses.Still
	end
	local keys, snaps = Pose.Walk.Keys, Pose.Walk.Snaps
	local i = frame - 2
	local k, s = i // snaps + 1, i % snaps
	local a = Poses[keys[k]]
	if s == 0 then
		return a
	end
	local t = s / snaps
	return Pose.blend(a, Poses[keys[k % #keys + 1]], t * t * (3 - 2 * t))
end

-- A rotation from angles, applied about Z, then Y, then X (Roblox's CFrame.Angles), row by row.
function Pose.rotation(a: Angles): Transform
	local rx, ry, rz = math.rad(a.x or 0), math.rad(a.y or 0), math.rad(a.z or 0)
	local cx, sx, cy, sy, cz, sz =
		math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	-- Rx * Ry * Rz
	return {
		cy * cz,
		-cy * sz,
		sy,
		sx * sy * cz + cx * sz,
		-sx * sy * sz + cx * cz,
		-sx * cy,
		-cx * sy * cz + sx * sz,
		cx * sy * sz + sx * cz,
		cx * cy,
		0,
		0,
		0,
	}
end

-- a then b, as CFrames multiply (a * b).
local function mul(a: Transform, b: Transform): Transform
	local out = table.create(12, 0)
	for r = 0, 2 do
		for c = 1, 3 do
			out[r * 3 + c] = a[r * 3 + 1] * b[c] + a[r * 3 + 2] * b[3 + c] + a[r * 3 + 3] * b[6 + c]
		end
		out[10 + r] = a[r * 3 + 1] * b[10] + a[r * 3 + 2] * b[11] + a[r * 3 + 3] * b[12] + a[10 + r]
	end
	return out
end

-- A point moved by a transform.
function Pose.apply(t: Transform, p: { number }): { number }
	return {
		t[1] * p[1] + t[2] * p[2] + t[3] * p[3] + t[10],
		t[4] * p[1] + t[5] * p[2] + t[6] * p[3] + t[11],
		t[7] * p[1] + t[8] * p[2] + t[9] * p[3] + t[12],
	}
end

local REST: Angles = {}
local IDENTITY: Transform = { 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 }

-- Each joint's turn about its own pivot: the rotation, and where that leaves the pivot's centre.
local function turn(pose: Pose, joint: Specs.Joint): Transform
	local t = Pose.rotation(pose[joint.Name] or REST)
	local at = joint.At
	local moved = Pose.apply(t, at)
	t[10], t[11], t[12] = at[1] - moved[1], at[2] - moved[2], at[3] - moved[3]
	return t
end

-- Every part's place in the figure's frame for a pose, moved from where it stands at rest, and
-- how far the whole body was lifted (or dropped) so its lowest sole sits on the floor.
function Pose.solve(pose: Pose): ({ [string]: Transform }, number)
	local parts: { [string]: Transform } = { HumanoidRootPart = IDENTITY }
	for _, joint in Specs.Joints do
		parts[joint.Part1] = mul(parts[joint.Part0], turn(pose, joint))
	end
	local low = math.huge
	for foot, points in Specs.Soles do
		for _, p in points do
			low = math.min(low, Pose.apply(parts[foot], p)[2])
		end
	end
	for name, t in parts do
		if name ~= "HumanoidRootPart" then
			t[11] -= low
		end
	end
	return parts, -low
end

-- Each Motor6D's turn for a pose (C0 = its RigAttachment's CFrame * this), the root's carrying
-- the lift that keeps its feet on the floor.
function Pose.turns(pose: Pose): { [string]: Transform }
	local _, lift = Pose.solve(pose)
	local out: { [string]: Transform } = {}
	for _, joint in Specs.Joints do
		local t = Pose.rotation(pose[joint.Name] or REST)
		if joint.Name == "Root" then
			t[11] = lift
		end
		out[joint.Name] = t
	end
	return out
end

return Pose
