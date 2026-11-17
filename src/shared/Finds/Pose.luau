--!strict
--[[
	Where each part of a kit-built find stands for a set of track values (F-G1a): the same sums as
	the kit's `pose` (art/finds/kit/kit.py), so the game shows a find the way its sheets did. A
	part turns or slides about its own pivot and axis, scales and stretches about its pivot, and
	travels over the floor and leans (the RC car), all carried by its parent's motion, so the
	jack-in-the-box's head rides its spring. Pure numbers: Lune tests it (tests/findpose.spec).

	`rest` is how a find is found: its lid shut, its flame out, the Secret lamp already lit. It's
	the kit's rule: each part's channel at the first key of the first motion that moves it, the
	motions in the order the build wrote them (`Finds/Order.luau`, since a Luau table forgets it).
]]

local Art = require("./Art")

-- A part's channel values by part name, then channel ("turn", "glow", "x"). A channel left out
-- is at its default: no turn, move, travel or glow, and a scale and stretch of 1.
export type Values = { [string]: { [string]: number } }
-- How a part moved from where it was drawn, in the find's frame: a 3x3 (row by row), which may
-- scale, then the translation. Twelve numbers.
export type Affine = { number }

local Pose = {}

Pose.Identity = { 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0 } :: Affine

-- Below this a scale hides a part (a MeshPart can't be size 0), as the kit clamps it.
local SMALLEST = 1e-4

-- `a` then `b` applied first: a @ b.
function Pose.mul(a: Affine, b: Affine): Affine
	local r = table.create(12, 0)
	for i = 0, 2 do
		for j = 0, 2 do
			r[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1]
				+ a[i * 3 + 2] * b[3 + j + 1]
				+ a[i * 3 + 3] * b[6 + j + 1]
		end
		r[10 + i] = a[i * 3 + 1] * b[10] + a[i * 3 + 2] * b[11] + a[i * 3 + 3] * b[12] + a[10 + i]
	end
	return r
end

-- Where `a` takes the point (x, y, z).
function Pose.apply(a: Affine, x: number, y: number, z: number): (number, number, number)
	return a[1] * x + a[2] * y + a[3] * z + a[10],
		a[4] * x + a[5] * y + a[6] * z + a[11],
		a[7] * x + a[8] * y + a[9] * z + a[12]
end

-- How much `a` stretches each of the find's axes (X, Y, Z): its columns' lengths.
function Pose.scales(a: Affine): (number, number, number)
	return math.sqrt(a[1] * a[1] + a[4] * a[4] + a[7] * a[7]),
		math.sqrt(a[2] * a[2] + a[5] * a[5] + a[8] * a[8]),
		math.sqrt(a[3] * a[3] + a[6] * a[6] + a[9] * a[9])
end

local function move(x: number, y: number, z: number): Affine
	return { 1, 0, 0, 0, 1, 0, 0, 0, 1, x, y, z }
end

local function size(x: number, y: number, z: number): Affine
	return { x, 0, 0, 0, y, 0, 0, 0, z, 0, 0, 0 }
end

-- A right-handed turn of `degrees` about the axis (x, y, z), as CFrame.fromAxisAngle turns.
local function turn(x: number, y: number, z: number, degrees: number): Affine
	local l = math.sqrt(x * x + y * y + z * z)
	x, y, z = x / l, y / l, z / l
	local a = math.rad(degrees)
	local c, s = math.cos(a), math.sin(a)
	local k = 1 - c
	-- stylua: ignore
	return {
		c + x * x * k, x * y * k - z * s, x * z * k + y * s,
		y * x * k + z * s, c + y * y * k, y * z * k - x * s,
		z * x * k - y * s, z * y * k + x * s, c + z * z * k,
		0, 0, 0,
	}
end

local DEFAULTS: { [string]: number } = { scale = 1, stretch = 1 }

-- A channel's value when no track sets it.
function Pose.default(channel: string): number
	return DEFAULTS[channel] or 0
end

--[[
	How a find is found (the kit's rest): each part's channel at the first key of the first motion
	in `order` that moves it. A motion missing from `order` counts after those in it, by name.
]]
function Pose.rest(find: Art.Find, order: { string }): Values
	local names = table.clone(order)
	local extra: { string } = {}
	for name in find.Motions do
		if not table.find(names, name) then
			table.insert(extra, name)
		end
	end
	table.sort(extra)
	for _, name in extra do
		table.insert(names, name)
	end
	local values: Values = {}
	for _, name in names do
		local motion = find.Motions[name]
		if motion then
			for _, track in motion.Tracks do
				local part = values[track.Part] or {}
				values[track.Part] = part
				if part[track.Channel] == nil then
					part[track.Channel] = track.Keys[1][2]
				end
			end
		end
	end
	return values
end

-- Every track of `motion` at `t` seconds over `base` (a copy: `base` is left alone), so a
-- channel the motion doesn't move stays where `base` has it.
function Pose.at(motion: Art.Motion, t: number, base: Values): Values
	local values: Values = {}
	for part, channels in base do
		values[part] = table.clone(channels)
	end
	for _, track in motion.Tracks do
		local part = values[track.Part] or {}
		values[track.Part] = part
		part[track.Channel] = Art.sample(track.Keys, t)
	end
	return values
end

-- `values` with `part`'s `channels` taken from `from` (a wind-up stopped by a wall: where it is
-- over the floor held, its legs and bob playing on, `Use.Holds`). That part's channels are a copy,
-- so a `values` shared with others (a find's rest) is left alone.
function Pose.hold(values: Values, from: Values, part: string, channels: { string }): Values
	local mine = table.clone(values[part] or {})
	local theirs = from[part] or {}
	for _, ch in channels do
		mine[ch] = theirs[ch] or Pose.default(ch)
	end
	local out = table.clone(values)
	out[part] = mine
	return out
end

-- How each part moved from where it was drawn, for `values`. Parents come before their children
-- in a find's Parts (the kit writes them so).
function Pose.solve(find: Art.Find, values: Values): { [string]: Affine }
	local out: { [string]: Affine } = {}
	for _, p in find.Parts do
		local v: { [string]: number } = values[p.Name] or {}
		local base = if p.Parent then out[p.Parent] else Pose.Identity
		local sc = math.max(v.scale or 1, SMALLEST)
		local st = math.max(v.stretch or 1, SMALLEST)
		local wide = sc / math.sqrt(st)
		local pv = p.Pivot
		local onto, off = move(pv.X, pv.Y, pv.Z), move(-pv.X, -pv.Y, -pv.Z)
		local grow = size(wide, sc * st, wide)
		local own: Affine
		local axis = p.Axis
		if axis then
			local slide = v.move or 0
			own = Pose.mul(
				onto,
				Pose.mul(
					turn(axis.X, axis.Y, axis.Z, v.turn or 0),
					Pose.mul(
						grow,
						Pose.mul(off, move(axis.X * slide, axis.Y * slide, axis.Z * slide))
					)
				)
			)
		else
			own = Pose.mul(onto, Pose.mul(grow, off))
		end
		local x, y, z = v.x or 0, v.y or 0, v.z or 0
		local yaw, pitch, roll = v.yaw or 0, v.pitch or 0, v.roll or 0
		if x ~= 0 or y ~= 0 or z ~= 0 or yaw ~= 0 or pitch ~= 0 or roll ~= 0 then
			local lean =
				Pose.mul(turn(0, 1, 0, yaw), Pose.mul(turn(1, 0, 0, pitch), turn(0, 0, 1, roll)))
			own = Pose.mul(move(x, y, z), Pose.mul(onto, Pose.mul(lean, Pose.mul(off, own))))
		end
		out[p.Name] = Pose.mul(base, own)
	end
	return out
end

return Pose
