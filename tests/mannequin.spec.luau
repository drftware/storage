--!strict
-- lune run tests/mannequin.spec
-- The Mannequin's poses (L-06a): its rig is R15's; at rest it stands on the floor untouched;
-- every pose keeps its joints inside their limits, stands its lowest sole on the floor with
-- nothing below it, and never puts one part through another; the shop pose has both feet down;
-- a step's stride matches the walk's step, so its feet don't skate; the left keys are the right
-- keys mirrored, part for part; the walk holds each key, snaps to the next without a jump, never
-- breaks a limit or a body between keys, and a light always freezes it on a key.
local Specs = require("../src/shared/Mannequin/Specs")
local Pose = require("../src/shared/Mannequin/Pose")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end

-- R15: fifteen body parts under HumanoidRootPart, joined by its fifteen joints.
local R15 = {
	Root = "LowerTorso",
	Waist = "UpperTorso",
	Neck = "Head",
	LeftShoulder = "LeftUpperArm",
	LeftElbow = "LeftLowerArm",
	LeftWrist = "LeftHand",
	RightShoulder = "RightUpperArm",
	RightElbow = "RightLowerArm",
	RightWrist = "RightHand",
	LeftHip = "LeftUpperLeg",
	LeftKnee = "LeftLowerLeg",
	LeftAnkle = "LeftFoot",
	RightHip = "RightUpperLeg",
	RightKnee = "RightLowerLeg",
	RightAnkle = "RightFoot",
}
local seen = { HumanoidRootPart = true }
ok(#Specs.Joints == 15, "fifteen joints")
for _, j in Specs.Joints do
	ok(R15[j.Name] == j.Part1, `{j.Name} moves {R15[j.Name]}`)
	ok(seen[j.Part0] == true, `{j.Name}'s Part0 {j.Part0} placed before it`)
	ok(Specs.Parts[j.Part1] ~= nil, `{j.Part1} is a part`)
	seen[j.Part1] = true
	ok(Pose.Limits[j.Name] ~= nil, `{j.Name} has limits`)
end

-- Every pair of parts a joint joins: those may touch, as a shoulder's ball sits in the torso.
local joined: { [string]: boolean } = {}
for _, j in Specs.Joints do
	joined[j.Part0 .. "|" .. j.Part1] = true
	joined[j.Part1 .. "|" .. j.Part0] = true
end

local function sub(a: { number }, b: { number }): { number }
	return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
end
local function dot(a: { number }, b: { number }): number
	return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end
local function clamp01(v: number): number
	return math.max(0, math.min(1, v))
end

-- The closest two segments come (p1-q1 and p2-q2).
local function segments(p1: { number }, q1: { number }, p2: { number }, q2: { number }): number
	local d1, d2, r = sub(q1, p1), sub(q2, p2), sub(p1, p2)
	local a, e, f = dot(d1, d1), dot(d2, d2), dot(d2, r)
	local s, t
	if a <= 1e-9 and e <= 1e-9 then
		s, t = 0, 0
	elseif a <= 1e-9 then
		s, t = 0, clamp01(f / e)
	else
		local c = dot(d1, r)
		if e <= 1e-9 then
			s, t = clamp01(-c / a), 0
		else
			local b = dot(d1, d2)
			local den = a * e - b * b
			s = if den > 1e-9 then clamp01((b * f - c * e) / den) else 0
			t = (b * s + f) / e
			if t < 0 then
				s, t = clamp01(-c / a), 0
			elseif t > 1 then
				s, t = clamp01((b - c) / a), 1
			end
		end
	end
	local c1 = { p1[1] + d1[1] * s, p1[2] + d1[2] * s, p1[3] + d1[3] * s }
	local c2 = { p2[1] + d2[1] * t, p2[2] + d2[2] * t, p2[3] + d2[3] * t }
	local d = sub(c1, c2)
	return math.sqrt(dot(d, d))
end

-- Checks every pose must pass: limits, standing, nothing below the floor, nothing through anything.
local function stands(name: string, pose: Pose.Pose)
	local problems = Pose.check(pose)
	ok(#problems == 0, `{name}: {table.concat(problems, ", ")}`)
	local parts = Pose.solve(pose)
	local low = math.huge
	for foot, points in Specs.Soles do
		for _, p in points do
			low = math.min(low, Pose.apply(parts[foot], p)[2])
		end
	end
	ok(near(low, 0, 1e-9), `{name}: its lowest sole on the floor ({low})`)
	local placed: { [string]: { { a: { number }, b: { number }, r: number } } } = {}
	for part, caps in Specs.Capsules do
		placed[part] = {}
		for _, c in caps do
			local a, b = Pose.apply(parts[part], c.A), Pose.apply(parts[part], c.B)
			table.insert(placed[part], { a = a, b = b, r = c.Radius })
			ok(math.min(a[2], b[2]) - c.Radius >= -0.03, `{name}: {part} above the floor`)
		end
	end
	for p, caps in placed do
		for q, others in placed do
			if p < q and not joined[p .. "|" .. q] then
				for _, c in caps do
					for _, o in others do
						local gap = segments(c.a, c.b, o.a, o.b) - c.r - o.r
						ok(gap >= -0.02, `{name}: {p} through {q} by {string.format("%.3f", -gap)}`)
					end
				end
			end
		end
	end
end

-- At rest it stands exactly as built: nothing moves, its soles on the floor.
local rest, lift = Pose.solve({})
ok(near(lift, 0), "at rest its soles are on the floor")
for part, t in rest do
	ok(
		near(t[1], 1) and near(t[5], 1) and near(t[9], 1) and near(t[10], 0) and near(t[11], 0),
		`{part} unmoved at rest`
	)
end

for _, name in Pose.Names do
	stands(name, Pose.Poses[name])
end

-- The shop pose has both feet down.
do
	local parts = Pose.solve(Pose.Poses.Still)
	for foot, points in Specs.Soles do
		local low = math.huge
		for _, p in points do
			low = math.min(low, Pose.apply(parts[foot], p)[2])
		end
		ok(low < 0.08, `Still: {foot} down ({low})`)
	end
end

-- A step's stride matches the walk's step: the ankles are about one step apart, front to back,
-- the foot named in front.
local function ankle(parts: { [string]: Pose.Transform }, side: string): { number }
	for _, j in Specs.Joints do
		if j.Name == side .. "Ankle" then
			return Pose.apply(parts[j.Part1], j.At)
		end
	end
	error("no ankle")
end
for _, key in { { "StepRight", "Right", "Left" }, { "StepLeft", "Left", "Right" } } do
	local parts = Pose.solve(Pose.Poses[key[1]])
	local front, back = ankle(parts, key[2]), ankle(parts, key[3])
	local stride = back[3] - front[3] -- it faces -Z
	ok(
		stride > Pose.Walk.Step * 0.75 and stride < Pose.Walk.Step * 1.25,
		`{key[1]}: stride {stride} near its step {Pose.Walk.Step}`
	)
end

-- The left keys are the right keys mirrored: every part lands in the mirror of its twin.
do
	for _, pair in { { "StepRight", "StepLeft" }, { "PassRight", "PassLeft" } } do
		local a, b = Pose.solve(Pose.Poses[pair[1]]), Pose.solve(Pose.Poses[pair[2]])
		for part, t in a do
			local twin = if string.sub(part, 1, 4) == "Left"
				then "Right" .. string.sub(part, 5)
				elseif string.sub(part, 1, 5) == "Right" then "Left" .. string.sub(part, 6)
				else part
			local u = b[twin]
			ok(
				near(t[10], -u[10], 1e-6) and near(t[11], u[11], 1e-6) and near(t[12], u[12], 1e-6),
				`{pair[2]}: {twin} mirrors {part}`
			)
		end
		local back = Pose.mirror(Pose.mirror(Pose.Poses[pair[1]]))
		local same = true
		for joint, ang in Pose.Poses[pair[1]] do
			local m = back[joint]
			same = same
				and m ~= nil
				and (m.x or 0) == (ang.x or 0)
				and (m.y or 0) == (ang.y or 0)
				and (m.z or 0) == (ang.z or 0)
		end
		ok(same, `{pair[1]}: mirrored twice is itself`)
	end
end

-- The walk: each key held at its step's start, a snap to the next with no jump, and in between
-- never a broken limit or a body through itself; a light freezes it on a key.
do
	local step, keys = Pose.Walk.Step, Pose.Walk.Keys
	local function same(a: Pose.Pose, b: Pose.Pose): boolean
		local pa, pb = Pose.solve(a), Pose.solve(b)
		for part, t in pa do
			for i = 1, 12 do
				if not near(t[i], pb[part][i], 1e-3) then
					return false
				end
			end
		end
		return true
	end
	for k = 0, 7 do
		local key = keys[k % #keys + 1]
		local nextKey = keys[(k + 1) % #keys + 1]
		ok(same(Pose.at(k * step), Pose.Poses[key]), `walk: holds {key} at step {k}`)
		ok(
			same(Pose.at(k * step + step * Pose.Walk.Hold * 0.9), Pose.Poses[key]),
			`walk: still holds {key}`
		)
		ok(
			same(Pose.at((k + 1) * step - 1e-6), Pose.Poses[nextKey]),
			`walk: snaps into {nextKey} by the step's end`
		)
		ok(
			Pose.freeze(k * step + step * 0.3) == key,
			`walk: frozen while holding {key} stays {key}`
		)
		ok(
			Pose.freeze(k * step + step * 0.8) == nextKey,
			`walk: frozen mid-snap lands on {nextKey}`
		)
	end
	for i = 0, 159 do
		local d = i * step * 4 / 160 + 0.013
		stands(`walk at {string.format("%.2f", d)}`, Pose.at(d))
		local f = Pose.freeze(d)
		ok(table.find(keys, f) ~= nil, `walk: freezes on a key at {d}`)
	end
	ok(
		Pose.freeze(-0.5) == keys[4] or Pose.freeze(-0.5) == keys[1],
		"walk: a step back still freezes on a key"
	)
end

-- The frames each screen poses it in (L-06b4a): frame 1 is Still; stopped, its frame is exactly
-- the key a light freezes it on; walking, its frame is within half a step of the snap of its walk
-- at every joint; every frame stands and keeps its limits.
do
	ok(Pose.frame(12.3, "Still") == 1 and Pose.ofFrame(1) == Pose.Poses.Still, "frame 1 is Still")
	for f = 1, Pose.Frames do
		stands(`frame {f}`, Pose.ofFrame(f))
	end
	local worst = 0
	for i = 0, 1999 do
		local d = i * Pose.Walk.Step * 4 / 2000 + 0.0037
		local stop = Pose.frame(d, "Stop")
		ok(
			Pose.ofFrame(stop) == Pose.Poses[Pose.freeze(d)],
			`frames: stopped at {d}, it's on the key it freezes on`
		)
		local walk = Pose.frame(d, "Walk")
		ok(walk >= 2 and walk <= Pose.Frames, `frames: walking at {d}, a frame of the walk`)
		local a, b = Pose.ofFrame(walk), Pose.at(d)
		for joint in Pose.Limits do
			local p: Pose.Angles, q: Pose.Angles = a[joint] or {}, b[joint] or {}
			worst = math.max(
				worst,
				math.abs((p.x or 0) - (q.x or 0)),
				math.abs((p.y or 0) - (q.y or 0)),
				math.abs((p.z or 0) - (q.z or 0))
			)
		end
	end
	-- a frame is at most half a step of the snap off: the snap's steepest (smoothstep's 1.5) times
	-- the biggest swing between two keys (the reaching arm's, about 95 degrees), over 2 * Snaps
	local swing = 0
	local keys = Pose.Walk.Keys
	for k, key in keys do
		local a, b = Pose.Poses[key], Pose.Poses[keys[k % #keys + 1]]
		for joint in Pose.Limits do
			local p: Pose.Angles, q: Pose.Angles = a[joint] or {}, b[joint] or {}
			swing = math.max(
				swing,
				math.abs((p.x or 0) - (q.x or 0)),
				math.abs((p.y or 0) - (q.y or 0)),
				math.abs((p.z or 0) - (q.z or 0))
			)
		end
	end
	local bound = 1.5 * swing / (2 * Pose.Walk.Snaps) + 1e-6
	ok(worst <= bound, `frames: walking, every joint within {bound} degrees of its walk ({worst})`)
end

print(`mannequin: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
