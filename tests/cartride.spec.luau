--!strict
-- lune run tests/cartride.spec
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

-- Runs `seconds` of frames of `dt`, pushing (wx, wz). Returns the distance and the plants.
local function run(
	s: Ride.State,
	wx: number,
	wz: number,
	seconds: number,
	dt: number?
): (number, number)
	local step = dt or 1 / 60
	local dist, plants = 0, 0
	local t = 0
	while t < seconds - 1e-9 do
		local dx, dz, e = Ride.advance(s, wx, wz, step)
		dist += math.sqrt(dx * dx + dz * dz)
		if e == "Plant" then
			plants += 1
		end
		t += step
	end
	return dist, plants
end

-- Headings: 0 rolls toward -Z, as a CFrame's LookVector.
do
	local x, z = Ride.way(0)
	ok(near(x, 0) and near(z, -1), "heading 0 rolls toward -Z")
	ok(near(Ride.headingOf(0, -1), 0), "and -Z is heading 0")
	local h = Ride.headingOf(1, 0)
	local ax, az = Ride.way(h)
	ok(near(ax, 1) and near(az, 0), "headingOf and way agree")
	ok(near(Ride.wrap(3 * math.pi), -math.pi) or near(Ride.wrap(3 * math.pi), math.pi), "wrap")
end

-- Holding forward: the first kick bites at once, then one each KickEvery, no faster.
do
	local s = Ride.new(0)
	local _, e1 = Ride.advance(s, 0, -1, Ride.Reach / 2)
	ok(s.speed == 0, "the foot is still on its way down")
	local _, _, e = Ride.advance(s, 0, -1, Ride.Reach)
	ok(e == "Plant", "it plants a reach after you push")
	local _, plants = run(s, 0, -1, 3)
	ok(
		plants == math.floor(3 / Ride.KickEvery),
		`a kick each {Ride.KickEvery} s while held ({plants})`
	)
	ok(s.speed > 16, `faster than a walk after three seconds ({s.speed})`)
	ok(s.speed <= Ride.Cap, "never past the cap")
	local _ = e1
end

-- Tapping is never faster than holding: a fresh push waits out the rhythm.
do
	local held = Ride.new(0)
	local _, heldPlants = run(held, 0, -1, 2.4)
	local tapped = Ride.new(0)
	local tapPlants = 0
	for _ = 1, 24 do
		local _, p = run(tapped, 0, -1, 0.05)
		local _, q = run(tapped, 0, 0, 0.05)
		tapPlants += p + q
	end
	ok(tapPlants <= heldPlants, `taps ({tapPlants}) no more kicks than holding ({heldPlants})`)
	ok(tapped.speed <= held.speed + 1e-6, "and no faster")
end

-- Each kick adds less as you near the cap; held long, it settles under the cap.
do
	ok(near(Ride.kickGain(0), Ride.Kick), "a full kick from a standstill")
	ok(Ride.kickGain(12) < Ride.kickGain(6), "less at speed")
	ok(Ride.kickGain(Ride.Cap) == 0, "nothing at the cap")
	local s = Ride.new(0)
	run(s, 0, -1, 20)
	ok(s.speed > 18 and s.speed < Ride.Cap, `cruising between 18 and the cap ({s.speed})`)
end

-- The push is a surge over Push seconds, not a jump.
do
	local s = Ride.new(0)
	Ride.advance(s, 0, -1, Ride.Reach + 0.001)
	local a = s.speed
	Ride.advance(s, 0, -1, Ride.Push / 2)
	local b = s.speed
	Ride.advance(s, 0, -1, Ride.Push / 2)
	ok(a < 1 and b > a and s.speed > b, `the speed climbs through the push ({a}, {b}, {s.speed})`)
end

-- Let go: it coasts, slowing, and stops; never rolls backward.
do
	local s = Ride.new(0)
	run(s, 0, -1, 6)
	local top = s.speed
	local d1 = run(s, 0, 0, 1)
	ok(s.speed < top and s.speed > 0, "coasting a second slows it")
	ok(d1 > 10, `and it covers ground (${d1})`)
	local coast = run(s, 0, 0, 15)
	ok(s.speed == 0, "it stops")
	ok(coast > 5 and coast < 80, `a long coast, not forever ({coast + d1} studs)`)
	run(s, 0, 0, 1)
	ok(s.speed == 0, "and stays stopped")
end

-- The same frames on a fast screen and a slow one cover the same ground.
do
	local a, b = Ride.new(0), Ride.new(0)
	local da = run(a, 0, -1, 3, 1 / 144)
	local db = run(b, 0, -1, 3, 1 / 30)
	ok(near(da, db, 0.6), `144 and 30 frames a second agree ({da}, {db})`)
	local c = Ride.new(0)
	local dx, dz = Ride.advance(c, 0, -1, 5)
	ok(math.sqrt(dx * dx + dz * dz) < Ride.Cap * Ride.FrameMax, "a hitch loses the rest")
end

-- It heads where you push: a turn eases round and settles without wobbling past.
do
	local s = Ride.new(0)
	run(s, 0, -1, 2)
	run(s, -1, 0, 2) -- push toward -X: heading +90 degrees
	ok(near(s.heading, math.pi / 2, 0.02), `turned to face -X ({math.deg(s.heading)})`)
	local s2 = Ride.new(0)
	run(s2, 0, -1, 2)
	local most = 0
	for _ = 1, 240 do
		Ride.advance(s2, -1, 0, 1 / 60)
		most = math.max(most, s2.heading)
	end
	ok(most < math.pi / 2 + math.rad(3), `no swing past (${math.deg(most)})`)
end

-- Turning, it swings about its fixed casters at the handle end: standing, they stay put.
do
	local s = Ride.new(0)
	local x, z = 0, 0
	local ax0, az0 = Ride.way(0)
	local wx, wz = Ride.way(math.rad(115))
	for _ = 1, 8 do
		local dx, dz = Ride.advance(s, wx, wz, 1 / 60)
		x += dx
		z += dz
	end
	ok(
		math.abs(s.heading) > 0.05 and s.speed == 0,
		`a standing cart swivels round ({s.heading}, {s.speed})`
	)
	local ax, az = Ride.way(s.heading)
	local px, pz = x + ax * Ride.Pivot, z + az * Ride.Pivot
	ok(
		near(px, ax0 * Ride.Pivot, 1e-6) and near(pz, az0 * Ride.Pivot, 1e-6),
		"about its fixed axle"
	)
end

-- A turn at speed is wider than one standing: the rate falls with speed.
do
	ok(Ride.turnLimit(0) > Ride.turnLimit(Ride.Cap), "slower to turn at speed")
	local s = Ride.new(0)
	local bx, bz = Ride.way(math.rad(115))
	run(s, bx, bz, 0.1)
	ok(s.speed == 0, "pushed well behind square, it doesn't kick until it's turned")
	run(s, bx, bz, 0.4)
	ok(math.abs(s.heading) > math.rad(30), "a standing cart swivels round")
	local across = Ride.new(0)
	run(across, -1, 0, 0.2)
	ok(across.speed > 0, "pushed square across, it kicks out straight as it turns")
end

-- Pushing back drags your foot: it slows in a straight line, then turns round.
do
	local s = Ride.new(0)
	run(s, 0, -1, 4)
	local h = s.heading
	local v = s.speed
	Ride.advance(s, 0, 1, 1 / 60)
	ok(s.dragging, "the foot goes down")
	run(s, 0, 1, 0.3)
	ok(s.speed < v - 5, "it slows hard")
	ok(near(s.heading, h, 0.01), "straight while fast")
	run(s, 0, 1, 3)
	ok(near(math.abs(s.heading), math.pi, 0.05), `then turns round ({math.deg(s.heading)})`)
	ok(s.speed > 0, "and kicks away the new way")
end

-- A head-on bump stops dead with a clank; a soft one stops quietly; never faster.
do
	local s = Ride.new(0)
	run(s, 0, -1, 4)
	local v = s.speed
	local kind, loud = Ride.hit(s, 0, 1) -- a wall facing +Z, met rolling -Z
	ok(kind == "Clank", "head on: a clank")
	ok(near(loud, v / Ride.Cap), "as loud as the speed into it")
	ok(s.speed == 0 and s.yawRate == 0, "stopped dead")
	local slow = Ride.new(0)
	slow.speed = 0.5
	local k2 = Ride.hit(slow, 0, 1)
	ok(k2 == "Stop" and slow.speed == 0, "a nudge stops it without a sound")
	local away = Ride.new(0)
	away.speed = 10
	local k3 = Ride.hit(away, 0, -1)
	ok(k3 == "None" and away.speed == 10, "a face behind it is no bump")
end

-- At a slant it scrapes along the face, slower, turned along it.
do
	local s = Ride.new(0)
	s.speed = 20
	-- a wall on its -X side, its face toward +X, met 20 degrees in
	local a = math.rad(20)
	local nx, nz = 1, 0
	s.heading = Ride.headingOf(-math.sin(a), -math.cos(a)) -- 20 degrees toward the wall
	local kind = Ride.hit(s, nx, nz)
	ok(kind == "Scrape", "a slant: a scrape")
	ok(s.speed > 10 and s.speed < 20, `slower but rolling ({s.speed})`)
	local wx, wz = Ride.way(s.heading)
	ok(near(wx * nx + wz * nz, 0, 1e-6), "now along the face")
end

-- Nothing in the ride is up or down: a bump never adds speed, at any angle.
do
	for deg = 0, 175, 5 do
		local s = Ride.new(0)
		s.speed = Ride.Cap
		local a = math.rad(deg)
		Ride.hit(s, math.sin(a), math.cos(a))
		ok(s.speed <= Ride.Cap and s.speed >= 0, `bump at {deg} keeps the speed in range`)
	end
	local s = Ride.new(0)
	s.speed = 10
	local kind = Ride.hit(s, 0, 0)
	ok(kind == "Clank" and s.speed == 0, "a face with no way along the floor stops it")
end

-- The footprint's reach toward the cars' band.
do
	ok(near(Ride.reachZ(0, 1.1, 2.15), 2.15), "lengthwise along Z: half its length")
	ok(near(Ride.reachZ(math.pi / 2, 1.1, 2.15), 1.1), "across: half its width")
	ok(Ride.reachZ(math.pi / 4, 1.1, 2.15) > 2.15, "corner first reaches furthest")
end

-- The server's check: a cart's pace, with the network's slack, passes; a teleport doesn't.
do
	ok(not Ride.tooFast(Ride.Cap * 0.5, 0.5), "the cap's pace passes")
	ok(not Ride.tooFast(Ride.Cap * 0.5 + 3, 0.5), "a bunched update passes")
	ok(Ride.tooFast(40, 0.5), "40 studs in half a second doesn't")
end

-- The casters' rattle: silent standing, rising with speed in both volume and pitch.
do
	local v0, p0 = Ride.rumble(0)
	local v1, p1 = Ride.rumble(10)
	local v2, p2 = Ride.rumble(Ride.Cap)
	local v3 = Ride.rumble(Ride.Cap * 2)
	ok(v0 == 0, "silent standing")
	ok(v1 > v0 and v2 > v1 and p2 > p1 and p1 > p0, "louder and higher with speed")
	ok(v3 == v2, "no louder past the cap")
	for name, snd in Ride.Sounds do
		ok(snd.id:match("^rbxassetid://%d+$") ~= nil and snd.length > 0, `{name} is a sound`)
	end
end

-- The kicking leg: at rest between kicks, down and back through one, never jumping a frame.
do
	local h0, o0, k0, d0 = Ride.leg(nil, false)
	local rest = Ride.Legs[1]
	ok(h0 == rest.hip and o0 == rest.out and k0 == rest.knee and d0 == 0, "no kick: at rest")
	local hp = Ride.leg(Ride.Reach, false)
	ok(hp > 0, "planted ahead at the reach")
	local hb = Ride.leg(Ride.Reach + Ride.Push, false)
	ok(hb < -30, "pushed back by the push's end")
	local _, _, _, dip = Ride.leg(Ride.Reach + Ride.Push / 2, false)
	ok(dip < -0.1, "the body sinks through the push")
	local worst = 0
	local ph = Ride.leg(0.001, false)
	for i = 2, 1000 do
		local h = Ride.leg(i * Ride.KickEvery / 1000, false)
		worst = math.max(worst, math.abs(h - ph))
		ph = h
	end
	ok(worst < 2, `the swing is smooth (most {worst} degrees a step)`)
	local hd = Ride.leg(0.2, true)
	ok(hd == Ride.LegDrag.hip, "dragging: planted ahead")
end

print(`cartride: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
