--!strict
-- Pure: the math of a jointed monster's body, shared by every one built as R15's rigid parts
-- (the Packrat first; the Mannequin's Pose.luau holds its own copy, older). A pose is each
-- joint's turn from rest in degrees about the figure's own axes (X its right, Y up, Z behind
-- it): +X swings a hanging limb forward and tips the head back, +Y turns to its left, +Z swings a
-- hanging limb to its right. `solve` places every part and stands the lowest sole on the floor;
-- `turns` gives each Motor6D's turn. No Roblox types, so Lune checks poses.

export type Vec = { number } -- x, y, z
export type Joint = { Name: string, Part0: string, Part1: string, At: Vec }
export type Capsule = { A: Vec, B: Vec, Radius: number }
export type Part = { Size: Vec, Centre: Vec, Triangles: number, Stuff: string }
export type Angles = { x: number?, y: number?, z: number? }
export type Pose = { [string]: Angles } -- by R15 joint name; a joint left out stands at rest
export type Transform = { number } -- 12 numbers: a rotation row by row, then a position
export type Limits = { [string]: { [string]: { number } } }
export type Body = { Joints: { Joint }, Soles: { [string]: { Vec } } }

local Rig = {}

local function mirrorName(name: string): string
	if string.sub(name, 1, 4) == "Left" then
		return "Right" .. string.sub(name, 5)
	elseif string.sub(name, 1, 5) == "Right" then
		return "Left" .. string.sub(name, 6)
	end
	return name
end

-- The same pose for the other side: left and right swap, and turns about Y and Z reverse.
function Rig.mirror(pose: Pose): Pose
	local out: Pose = {}
	for joint, a in pose do
		out[mirrorName(joint)] =
			{ x = a.x, y = if a.y then -a.y else nil, z = if a.z then -a.z else nil }
	end
	return out
end

-- Limits written for the middle and the right side, with the left side's mirrored in.
function Rig.limits(right: Limits): Limits
	local out: Limits = {}
	for joint, axes in right do
		out[joint] = axes
		if string.sub(joint, 1, 5) == "Right" then
			local y, z = axes.y, axes.z
			out[mirrorName(joint)] = { x = axes.x, y = { -y[2], -y[1] }, z = { -z[2], -z[1] } }
		end
	end
	return out
end

-- What's wrong with a pose, if anything: joints it doesn't have, turns past a joint's limits.
function Rig.check(limits: Limits, pose: Pose): { string }
	local out = {}
	for joint, a in pose do
		local lim = limits[joint]
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
function Rig.blend(a: Pose, b: Pose, t: number): Pose
	local out: Pose = {}
	local seen: { [string]: boolean } = {}
	for _, side in { a, b } do
		for joint in side do
			if seen[joint] then
				continue
			end
			seen[joint] = true
			local p0: Angles, q0: Angles = a[joint] or {}, b[joint] or {}
			out[joint] = {
				x = (p0.x or 0) + ((q0.x or 0) - (p0.x or 0)) * t,
				y = (p0.y or 0) + ((q0.y or 0) - (p0.y or 0)) * t,
				z = (p0.z or 0) + ((q0.z or 0) - (p0.z or 0)) * t,
			}
		end
	end
	return out
end

-- A rotation from angles, applied about Z, then Y, then X (Roblox's CFrame.Angles), row by row.
function Rig.rotation(a: Angles): Transform
	local rx, ry, rz = math.rad(a.x or 0), math.rad(a.y or 0), math.rad(a.z or 0)
	local cx, sx, cy, sy, cz, sz =
		math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
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
function Rig.mul(a: Transform, b: Transform): Transform
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
function Rig.apply(t: Transform, p: Vec): Vec
	return {
		t[1] * p[1] + t[2] * p[2] + t[3] * p[3] + t[10],
		t[4] * p[1] + t[5] * p[2] + t[6] * p[3] + t[11],
		t[7] * p[1] + t[8] * p[2] + t[9] * p[3] + t[12],
	}
end

local REST: Angles = {}
local IDENTITY: Transform = { 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 }

-- Each joint's turn about its own pivot: the rotation, and where that leaves the pivot's centre.
local function turn(pose: Pose, joint: Joint): Transform
	local t = Rig.rotation(pose[joint.Name] or REST)
	local at = joint.At
	local moved = Rig.apply(t, at)
	t[10], t[11], t[12] = at[1] - moved[1], at[2] - moved[2], at[3] - moved[3]
	return t
end

-- Every part's place in the figure's frame for a pose, moved from where it stands at rest, and
-- how far the whole body was lifted (or dropped) so its lowest sole sits on the floor.
function Rig.solve(body: Body, pose: Pose): ({ [string]: Transform }, number)
	local parts: { [string]: Transform } = { HumanoidRootPart = IDENTITY }
	for _, joint in body.Joints do
		parts[joint.Part1] = Rig.mul(parts[joint.Part0], turn(pose, joint))
	end
	local low = math.huge
	for foot, points in body.Soles do
		for _, p in points do
			low = math.min(low, Rig.apply(parts[foot], p)[2])
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
function Rig.turns(body: Body, pose: Pose): { [string]: Transform }
	local _, lift = Rig.solve(body, pose)
	local out: { [string]: Transform } = {}
	for _, joint in body.Joints do
		local t = Rig.rotation(pose[joint.Name] or REST)
		if joint.Name == "Root" then
			t[11] = lift
		end
		out[joint.Name] = t
	end
	return out
end

return Rig
