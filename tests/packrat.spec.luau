--!strict
-- lune run tests/packrat.spec
-- The Packrat's poses (S2-06a1, S2-06a3): at rest it stands on the floor untouched; every pose,
-- and every frame of both walks, keeps its joints inside their limits and never puts one part
-- through another; its two walks read as opposites: arms full, both hands are up at its chest
-- within reach of the find it carries, the find clear of its chest; arms empty, both hands hang
-- below its hips and out past its sides. Reaching, one hand is far out ahead of its chest at a
-- player's chest height; taking, both hands close on the find between there and its chest;
-- putting down, both hands are low ahead, below its hips. Frames number every pose a screen
-- shows, and the walks' steps match their feet.
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

-- The middle of a part's first capsule, posed.
local function middle(placed: { [string]: Rig.Transform }, name: string): { number }
	local c = Specs.Capsules[name][1]
	local a, b = Rig.apply(placed[name], c.A), Rig.apply(placed[name], c.B)
	return { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2, (a[3] + b[3]) / 2 }
end

local function hand(placed: { [string]: Rig.Transform }, side: string): { number }
	return middle(placed, side .. "Hand")
end

-- At rest: on the floor, nothing moved.
local _, lift = Pose.solve({})
ok(math.abs(lift) < 1e-6, `at rest it stands on the floor (lift {lift})`)
stands("Rest", {})

for _, name in Pose.Names do
	stands(name, Pose.Poses[name])
end

local hipY = Specs.Joints[7].At[2] -- the LeftHip's height

local function fullReads(name: string, pose: Rig.Pose)
	local placed = Pose.solve(pose)
	local find = Pose.carry(pose)
	local at = { find[10], find[11], find[12] }
	local chest = Rig.apply(placed.UpperTorso, { 0, 5.4, 0 })
	ok(chest[3] - at[3] > 0.6, `{name}: the find held ahead of its chest`)
	for _, side in { "Left", "Right" } do
		-- The pale forearms cross in front of the find, never through it: they're the read.
		local fore = middle(placed, side .. "LowerArm")
		ok(
			at[3] - fore[3] > 0.25,
			`{name}: its {side} forearm across the find's front ({string.format(
				"%.2f",
				at[3] - fore[3]
			)})`
		)
		local h = hand(placed, side)
		local d = math.sqrt(dot(sub(h, at), sub(h, at)))
		ok(d < 1.1, `{name}: its {side} hand on the find ({string.format("%.2f", d)} off)`)
		ok(h[2] > 4.2, `{name}: its {side} hand up at its chest ({string.format("%.2f", h[2])})`)
	end
end

local function emptyReads(name: string, pose: Rig.Pose)
	local placed = Pose.solve(pose)
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

for _, name in Pose.Walk.Keys.Full do
	fullReads(name, Pose.Poses[name])
end
for _, name in Pose.Walk.Keys.Empty do
	emptyReads(name, Pose.Poses[name])
end

-- Reach, take and put down (S2-06a3). The find's place in each is `Pose.grip`.
local function gripOf(name: string): { number }
	local t = Pose.grip(Pose.Poses[name], Pose.InHands[name])
	return { t[10], t[11], t[12] }
end
local function chestOf(name: string): { number }
	return Rig.apply(Pose.solve(Pose.Poses[name]).UpperTorso, { 0, 5.4, 0 })
end
local function ahead(name: string, p: { number }): number
	return chestOf(name)[3] - p[3]
end
local function f2(v: number): string
	return string.format("%.2f", v)
end

-- Reaching: one long arm far out ahead, nearly level, at a player's chest; the other well back.
do
	local placed = Pose.solve(Pose.Poses.Reach)
	local right, left = hand(placed, "Right"), hand(placed, "Left")
	ok(
		ahead("Reach", right) > 3.0,
		`Reach: its right hand well ahead of its chest ({f2(ahead("Reach", right))})`
	)
	ok(
		right[2] > 3.2 and right[2] < 4.6,
		`Reach: its right hand at a player's chest ({f2(right[2])})`
	)
	ok(
		ahead("Reach", left) < 0,
		`Reach: its left hand trailing behind ({f2(ahead("Reach", left))})`
	)
	local shoulder = Rig.apply(placed.RightUpperArm, Specs.Joints[11].At)
	local drop = shoulder[2] - right[2]
	local out = shoulder[3] - right[3]
	ok(
		drop < out * 0.6,
		`Reach: the arm nearly level, not hanging ({f2(drop)} down over {f2(out)} out)`
	)
	local g = gripOf("Reach")
	ok(
		ahead("Reach", g) > 3.3,
		`Reach: the find at its fingertips, further out ({f2(ahead("Reach", g))})`
	)
	local head = middle(placed, "Head")
	ok(
		ahead("Reach", head) > 0.6,
		`Reach: the hood craned after the arm ({f2(ahead("Reach", head))})`
	)
end

-- Taking: both hands on the find, nearer its chest than the reach, further than the hug.
do
	local placed = Pose.solve(Pose.Poses.Take)
	local g = gripOf("Take")
	for _, side in { "Left", "Right" } do
		local h = hand(placed, side)
		local d = math.sqrt(dot(sub(h, g), sub(h, g)))
		ok(d < 0.6, `Take: its {side} hand on the find ({f2(d)} off)`)
	end
	local carried = Pose.carry(Pose.Poses.FullStepRight)
	local hug = Rig.apply(Pose.solve(Pose.Poses.FullStepRight).UpperTorso, { 0, 5.4, 0 })[3]
		- carried[12]
	local reach = ahead("Reach", gripOf("Reach"))
	local take = ahead("Take", g)
	ok(
		take > hug + 0.6 and take < reach - 0.8,
		`Take: the find on its way in ({f2(hug)} < {f2(take)} < {f2(reach)})`
	)
	ok(g[2] > 4.2, `Take: the find up at its chest ({f2(g[2])})`)
	ok(
		math.abs(hand(placed, "Left")[1] - hand(placed, "Right")[1]) > 0.6,
		"Take: its hands either side of the find"
	)
end

-- Putting down: folded over, both hands low ahead, below its hips.
do
	local placed = Pose.solve(Pose.Poses.PutDown)
	local hips = Rig.apply(placed.LowerTorso, Specs.Joints[13].At)
	for _, side in { "Left", "Right" } do
		local h = hand(placed, side)
		ok(
			h[2] < hips[2] - 1.0,
			`PutDown: its {side} hand below its hips ({f2(h[2])} under {f2(hips[2])})`
		)
		ok(ahead("PutDown", h) > 1.0, `PutDown: its {side} hand ahead ({f2(ahead("PutDown", h))})`)
	end
	ok(gripOf("PutDown")[2] < 2.0, `PutDown: the find low ({f2(gripOf("PutDown")[2])})`)
	ok(
		chestOf("PutDown")[2] < chestOf("Still")[2] - 0.6,
		"PutDown: folded over it, lower than standing"
	)
end

-- Frames: every one is a pose that stands, the held poses and the walks' keys are exactly their
-- own pose, and a walk's frames read as that walk.
ok(Pose.Frames == 4 + 2 * 4 * Pose.Walk.Frames, `{Pose.Frames} frames`)
for _, name in { "Still", "Reach", "Take", "PutDown" } do
	local frame = Pose.held(name)
	ok(frame ~= nil and Pose.ofFrame(frame) == Pose.Poses[name], `{name} has its own frame`)
end
ok(Pose.held("FullStepRight") == nil, "a walk's key isn't held")
local seen: { [number]: boolean } = {}
for _, walk in { "Empty", "Full" } :: { Pose.Walk } do
	local step = Pose.Walk.Step[walk]
	local keys = Pose.Walk.Keys[walk]
	for k = 0, 7 do
		local frame = Pose.frame(walk, k * step)
		ok(
			Pose.ofFrame(frame) == Pose.Poses[keys[k % 4 + 1]],
			`{walk}: key {k} lands on {keys[k % 4 + 1]}`
		)
	end
	local last = -1
	for i = 0, 400 do
		local travelled = i * step / 10
		local along = Pose.along(walk, travelled)
		ok(along >= last, `{walk}: along never goes back at {travelled}`)
		last = along
		local frame = Pose.frameAt(walk, along)
		seen[frame] = true
		ok(frame >= 5 and frame <= Pose.Frames, `{walk}: frame {frame} in range`)
	end
	-- A planted foot stays put: one key carries it half the spread of its feet in a step.
	local placed = Pose.solve(Pose.Poses[keys[1]])
	local spread = middle(placed, "LeftFoot")[3] - middle(placed, "RightFoot")[3]
	ok(
		math.abs(step - spread / 2) < 0.12 * step,
		`{walk}: a key carries it half its feet's spread ({f2(step)} against {f2(spread / 2)})`
	)
end
ok(Pose.Walk.Step.Full < Pose.Walk.Step.Empty * 0.8, "full steps are shorter than empty")
local first = 5
for frame = first, Pose.Frames do
	ok(seen[frame] == true, `frame {frame} is shown on a walk`)
	local pose = Pose.ofFrame(frame)
	stands(`frame {frame}`, pose)
	if frame < first + 4 * Pose.Walk.Frames then
		emptyReads(`frame {frame}`, pose)
	else
		fullReads(`frame {frame}`, pose)
	end
end

-- Smooth: no joint turns more than a few degrees from one frame to the next, round the cycle.
for _, base in { first, first + 4 * Pose.Walk.Frames } do
	local worst = 0
	for i = 0, 4 * Pose.Walk.Frames - 1 do
		local a = Pose.ofFrame(base + i)
		local b = Pose.ofFrame(base + (i + 1) % (4 * Pose.Walk.Frames))
		for joint in Pose.Limits do
			local p, q = a[joint] or {}, b[joint] or {}
			worst = math.max(
				worst,
				math.abs((p.x or 0) - (q.x or 0)),
				math.abs((p.y or 0) - (q.y or 0)),
				math.abs((p.z or 0) - (q.z or 0))
			)
		end
	end
	ok(worst < 12, `the walk from frame {base} turns at most {f2(worst)} degrees a frame`)
end

print(`packrat: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
