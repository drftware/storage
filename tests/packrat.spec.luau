--!strict
-- lune run tests/packrat.spec
-- The Packrat's poses (S2-06a1): at rest it stands on the floor untouched; every pose keeps its
-- joints inside their limits and never puts one part through another; and its two walks read
-- as opposites: arms full, both hands are up at its chest within reach of the find it carries,
-- the find clear of its chest; arms empty, both hands hang below its hips and out past its sides.
local Specs = require("../src/shared/Packrat/Specs")
local Pose = require("../src/shared/Packrat/Pose")
local Rig = require("../src/shared/Rig")

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

-- Parts a joint holds together may overlap: their domes sit inside each other.
local joined: { [string]: boolean } = {}
for _, j in Specs.Joints do
	joined[j.Part0 .. "|" .. j.Part1] = true
	joined[j.Part1 .. "|" .. j.Part0] = true
end

local function stands(name: string, pose: Rig.Pose)
	for _, problem in Pose.check(pose) do
		ok(false, `{name}: {problem}`)
	end
	local placed = Pose.solve(pose)
	local caps: { { part: string, a: { number }, b: { number }, r: number } } = {}
	for part, list in Specs.Capsules do
		for _, c in list do
			table.insert(caps, {
				part = part,
				a = Rig.apply(placed[part], c.A),
				b = Rig.apply(placed[part], c.B),
				r = c.Radius,
			})
		end
	end
	for i = 1, #caps do
		local p = caps[i]
		ok(math.min(p.a[2], p.b[2]) - p.r > -0.02, `{name}: {p.part} below the floor`)
		for k = i + 1, #caps do
			local q = caps[k]
			if p.part ~= q.part and not joined[p.part .. "|" .. q.part] then
				local gap = segments(p.a, p.b, q.a, q.b) - p.r - q.r
				ok(gap > 0, `{name}: {p.part} through {q.part} by {string.format("%.3f", -gap)}`)
			end
		end
	end
end

local function hand(placed: { [string]: Rig.Transform }, side: string): { number }
	local c = Specs.Capsules[side .. "Hand"][1]
	local a, b = Rig.apply(placed[side .. "Hand"], c.A), Rig.apply(placed[side .. "Hand"], c.B)
	return { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 }
end

-- At rest: on the floor, nothing moved.
local _, lift = Pose.solve({})
ok(math.abs(lift) < 1e-6, `at rest it stands on the floor (lift {lift})`)
stands("Rest", {})

for _, name in Pose.Names do
	stands(name, Pose.Poses[name])
end

local hipY = Specs.Joints[7].At[2] -- the LeftHip's height
for _, name in Pose.Walks.Full do
	local pose = Pose.Poses[name]
	local placed = Pose.solve(pose)
	local find = Pose.carry(pose)
	local at = { find[10], find[11], find[12] }
	local chest = Rig.apply(placed.UpperTorso, { 0, 5.4, 0 })
	ok(chest[3] - at[3] > 0.85, `{name}: the find held out ahead of its chest`)
	for _, side in { "Left", "Right" } do
		local h = hand(placed, side)
		local d = math.sqrt(dot(sub(h, at), sub(h, at)))
		ok(d < 1.1, `{name}: its {side} hand on the find ({string.format("%.2f", d)} off)`)
		ok(h[2] > 4.2, `{name}: its {side} hand up at its chest ({string.format("%.2f", h[2])})`)
	end
end
for _, name in Pose.Walks.Empty do
	local placed = Pose.solve(Pose.Poses[name])
	for _, side in { "Left", "Right" } do
		local h = hand(placed, side)
		ok(
			h[2] < hipY - 0.4,
			`{name}: its {side} hand hangs below its hips ({string.format("%.2f", h[2])})`
		)
		ok(
			math.abs(h[1]) > 1.0,
			`{name}: its {side} hand out past its sides ({string.format("%.2f", h[1])})`
		)
	end
end

print(`packrat: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
