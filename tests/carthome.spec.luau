--!strict
-- lune run tests/carthome.spec
local Home = require("../src/shared/Cart/Home")
local Ride = require("../src/shared/Cart/Ride")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) < (eps or 1e-6)
end

-- In the lobby's frame: the bay wall at Z 0, the rack's slots at Z -45.15, noses to -Z (h 0).
local SLOT1: Home.Pose = { x = -19.5, z = -45.15, h = 0 }
local SLOT_TURNED: Home.Pose = { x = -22.5, z = -45.15, h = math.rad(0.8) }

local function hub(x: number, z: number, h: number): (number, number)
	local wx, wz = Ride.way(h)
	return x - wx * Ride.Pivot, z - wz * Ride.Pivot
end

-- Walks a way in small steps: the biggest turn between steps, and whether the hub ever slid
-- sideways while rolling (it can't: its casters are fixed).
local function walk(way: Home.Way): (number, number)
	local most, slide = 0, 0
	local step = 0.05
	local s = 0
	local px, pz, ph = Home.pose(way, 0)
	while s < way.length do
		s = math.min(s + step, way.length)
		local x, z, h = Home.pose(way, s)
		most = math.max(most, math.abs(Ride.wrap(h - ph)))
		if s > way.swingLength + step then
			local ax, az = hub(px, pz, ph)
			local bx, bz = hub(x, z, h)
			local dx, dz = bx - ax, bz - az
			local d = math.sqrt(dx * dx + dz * dz)
			if d > 1e-4 then
				local wx, wz = Ride.way(h)
				-- sideways share of the hub's move
				slide = math.max(slide, math.abs(dx * wz - dz * wx) / d)
			end
		end
		px, pz, ph = x, z, h
	end
	return most, slide
end

-- Hopped off at a car's stripes, facing back into the room: one smooth curve home, no swing.
do
	local from: Home.Pose = { x = 27, z = -5.6, h = math.rad(10) }
	local way = Home.plan(from, SLOT1)
	ok(way.swing == 0, "band: no swing when it already faces home")
	local x, z, h = Home.pose(way, 0)
	ok(
		near(x, from.x, 1e-4) and near(z, from.z, 1e-4) and near(h, from.h, 1e-4),
		"band: starts where it stood"
	)
	x, z, h = Home.pose(way, way.length)
	ok(
		near(x, SLOT1.x, 1e-4) and near(z, SLOT1.z, 1e-4) and near(h, SLOT1.h, 1e-4),
		"band: ends in its slot"
	)
	ok(way.length > 50 and way.length < 90, `band: a sensible way ({way.length})`)
	local most, slide = walk(way)
	ok(most < math.rad(8), `band: it turns smoothly ({math.deg(most)} degrees a step)`)
	ok(slide < 0.1, `band: the hub never slides sideways ({slide})`)
	-- the last stretch is straight in, the hub on the slot's line
	local s = way.inFrom
	ok(
		near(way.length - way.inFrom, Home.Approach, 1e-6),
		"band: the straight run in is the approach"
	)
	while s <= way.length do
		local px, _, ph = Home.pose(way, s)
		ok(near(px, SLOT1.x, 1e-6) and near(ph, 0, 1e-6), `band: straight in at {s}`)
		s += 1
	end
end

-- Left facing the cars (away from home): it swings round on the spot first, about its hub.
do
	local from: Home.Pose = { x = -10, z = -25, h = math.pi }
	local way = Home.plan(from, SLOT1)
	ok(math.abs(way.swing) > Home.SwingFrom, "away: it swings round first")
	ok(
		near(way.swingLength, math.abs(way.swing) * Home.Arm),
		"away: the swing's length is the casters' arc"
	)
	local hx, hz = hub(from.x, from.z, from.h)
	for i = 1, 4 do
		local x, z, h = Home.pose(way, way.swingLength * i / 4)
		local bx, bz = hub(x, z, h)
		ok(
			near(bx, hx, 1e-6) and near(bz, hz, 1e-6),
			`away: the hub stays put through the swing ({i})`
		)
	end
	local x, z, h = Home.pose(way, way.length)
	ok(
		near(x, SLOT1.x, 1e-4) and near(z, SLOT1.z, 1e-4) and near(h, 0, 1e-4),
		"away: ends in its slot"
	)
	local most, slide = walk(way)
	ok(most < math.rad(8), "away: no jump in its turn")
	ok(slide < 0.1, `away: the hub never slides sideways ({slide})`)
end

-- Rolled a few studs out of its slot and left: straight back in, no swing, no curve.
do
	local from: Home.Pose = { x = -19.5, z = -42.15, h = 0 }
	local way = Home.plan(from, SLOT1)
	ok(way.swing == 0, "out: no swing")
	ok(near(way.length, 3, 1e-6), "out: three studs back in")
	local x, z = Home.pose(way, 1.5)
	ok(near(x, -19.5, 1e-6) and near(z, -43.65, 1e-6), "out: halfway back in")
	ok(near(way.inFrom, 0, 1e-6), "out: all of it is the run straight in")
end

-- Lined up but turned: squares up on the spot, then straight in.
do
	local from: Home.Pose = { x = -19.5 - 0.5 * Ride.Pivot, z = -40, h = math.rad(30) } -- its hub on the line
	local way = Home.plan(from, SLOT1)
	ok(near(way.swing, math.rad(-30), 1e-6), "lined up turned: squares up")
	local x, z, h = Home.pose(way, way.length)
	ok(
		near(x, SLOT1.x, 1e-4) and near(z, SLOT1.z, 1e-4) and near(h, 0, 1e-6),
		"lined up turned: in its slot"
	)
end

-- A slot a degree off square: the way ends on that slot's own line and turn.
do
	local from: Home.Pose = { x = 0, z = -20, h = math.rad(-40) }
	local way = Home.plan(from, SLOT_TURNED)
	local x, z, h = Home.pose(way, way.length)
	ok(
		near(x, SLOT_TURNED.x, 1e-4)
			and near(z, SLOT_TURNED.z, 1e-4)
			and near(h, SLOT_TURNED.h, 1e-6),
		"turned slot: parked square to it"
	)
	local _, _, hIn = Home.pose(way, way.inFrom + 1)
	ok(near(hIn, SLOT_TURNED.h, 1e-6), "turned slot: rolls in along its line")
	-- another shape still gets there
	local bent = Home.plan(from, SLOT_TURNED, 0.25)
	ok(math.abs(bent.length - way.length) > 1e-3, "turned slot: another shape is another way")
	x, z = Home.pose(bent, bent.length)
	ok(
		near(x, SLOT_TURNED.x, 1e-4) and near(z, SLOT_TURNED.z, 1e-4),
		"turned slot: the other shape ends there too"
	)
end

-- The run: sets off gently, never past its pace, eases in and meets the rack at the touch.
do
	local length = 40
	local r = Home.start(length, 100)
	local s0, v0, done0 = Home.at(r, length, 100.1)
	ok(s0 == 0 and v0 == 0 and not done0, "run: stands for the lead")
	local last, lastV = 0, 0
	local most = 0
	local smooth = true
	local t = 100 + Home.Lead
	local touch = 0
	local finished = false
	while t < 100 + Home.Lead + 30 do
		t += 1 / 60
		local s, v, done = Home.at(r, length, t)
		if s < last - 1e-9 then
			smooth = false
		end
		if math.abs(v - lastV) > math.max(Home.Accel, Home.Ease) / 60 + 1e-6 and not done then
			smooth = false
		end
		most = math.max(most, v)
		if done then
			finished = true
			ok(near(s, length), "run: arrives at the end")
			break
		end
		touch = v
		last, lastV = s, v
	end
	ok(finished, "run: gets there")
	ok(smooth, "run: never jumps or goes back")
	ok(most <= Home.Pace + 1e-9 and most > Home.Pace - 1e-6, `run: cruises at its pace ({most})`)
	ok(near(touch, Home.Touch, 0.1), `run: meets the rack at the touch ({touch})`)
	ok(near(Home.lasts(r, length), t - r.at, 1 / 30), "run: lasts as long as it takes")
end

-- Someone in its way: it brakes to a stop where it is, then sets off again and gets home.
do
	local length = 40
	local r = Home.start(length, 0)
	local t = 4
	local s, v = Home.at(r, length, t)
	ok(near(v, Home.Pace), "halt: at its pace before")
	local h = Home.halt(r, length, t)
	local hs, hv = Home.at(h, length, t)
	ok(near(hs, s, 1e-9) and near(hv, v, 1e-9), "halt: carries on from where it was")
	ok(Home.halting(h, length), "halt: stops short of home")
	ok(
		h.to - s <= Home.Pace * Home.Pace / (2 * Home.Brake) + 1e-9,
		"halt: stops within its braking"
	)
	local stopS, stopV, stopped = Home.at(h, length, t + 5)
	ok(stopped and stopV == 0 and near(stopS, h.to), "halt: stood still")
	local g = Home.go(h, length, t + 5)
	local gs = Home.at(g, length, t + 5)
	ok(near(gs, stopS, 1e-9), "go: sets off from where it stopped")
	ok(not Home.halting(g, length), "go: heads home")
	local es, _, done = Home.at(g, length, t + 5 + Home.lasts(g, length) + 0.01)
	ok(done and near(es, length), "go: gets home")
	-- braking on a short way: halting near the end still stops at the end, at most
	local late = Home.halt(r, length, Home.lasts(r, length) + r.at - 0.2)
	ok(late.to <= length, "halt: never past the end")
end

-- Short ways: a stud from home it still gets there, gently.
do
	local r = Home.start(0.5, 0)
	local s, v, done = Home.at(r, 0.5, Home.lasts(r, 0.5) + Home.Lead + 0.01)
	ok(done and near(s, 0.5) and v == 0, "short: gets there")
	local r0 = Home.start(0, 0)
	local s0, _, done0 = Home.at(r0, 0, 1)
	ok(done0 and s0 == 0, "none: already home")
end

-- In a slot, and carts meeting.
do
	ok(Home.slotted({ x = -19.3, z = -45.0, h = math.rad(5) }, SLOT1), "slotted: near enough")
	ok(not Home.slotted({ x = -18.5, z = -45.15, h = 0 }, SLOT1), "slotted: a stud over is out")
	ok(
		not Home.slotted({ x = -19.5, z = -45.15, h = math.rad(30) }, SLOT1),
		"slotted: turned is out"
	)
	local hw, hl = 1.125, 2.2
	ok(
		not Home.meet(SLOT1, { x = -22.5, z = -45.15, h = 0 }, hw, hl),
		"meet: neighbours in the rack don't"
	)
	ok(Home.meet(SLOT1, { x = -20.5, z = -44, h = 0 }, hw, hl), "meet: overlapping do")
	ok(
		Home.meet(SLOT1, { x = -19.5, z = -42, h = math.pi / 2 }, hw, hl),
		"meet: crossed at its handle do"
	)
	ok(
		not Home.meet(SLOT1, { x = -19.5, z = -40, h = math.pi / 2 }, hw, hl),
		"meet: crossed clear of it don't"
	)
end

print(`carthome: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
