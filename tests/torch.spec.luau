--!strict
-- lune run tests/torch.spec
-- The flashlight's feel (L-11a): standing still it only breathes; walking it sways within its
-- bounds, more the faster you go and on the stride's beat, and settles when you stop; a turn
-- leaves it trailing, never past its limit, and it catches up; the click dips it and it comes
-- back; a hitch never makes it jump. The switch takes a fast thumb's blinks and no faster; a
-- client's pitch is checked and clamped; the aim is sent only when it moved and not too often;
-- the arm's raise; and the light budget lights the nearest friends' beams only.
local Torch = require("../src/shared/Flashlight/Torch")

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
local function near(a: number, b: number, what: string, tol: number?)
	ok(math.abs(a - b) <= (tol or 1e-6), `{what}: {a} vs {b}`)
end

local RAD = math.pi / 180
local DT = 1 / 60

-- Runs `seconds` of frames at `speed` with no turning; returns the biggest offsets seen.
local function run(s: Torch.Sway, seconds: number, speed: number): (number, number, number, number)
	local p = Torch.pose()
	local mx, my, mr, mp = 0, 0, 0, 0
	for _ = 1, math.round(seconds / DT) do
		Torch.step(s, DT, speed, 0, 0, p)
		mx = math.max(mx, math.abs(p.x))
		my = math.max(my, math.abs(p.y))
		mr = math.max(mr, math.abs(p.roll))
		mp = math.max(mp, math.abs(p.pitch))
	end
	return mx, my, mr, mp
end

-- Standing still: no stride, only the breath, and that small.
do
	local s = Torch.sway()
	local mx, my, mr, mp = run(s, 10, 0)
	near(mx, 0, "still: no sway across")
	near(mr, 0, "still: no roll")
	ok(my > 0 and my <= Torch.BreathDown + 1e-9, `still: it breathes, a little ({my})`)
	ok(mp > 0 and mp <= Torch.BreathNod * RAD + 1e-9, "still: the beam nods with the breath")
end

-- Walking: the sway grows to its full size and stays inside it.
do
	local s = Torch.sway()
	run(s, 3, Torch.WalkSpeed)
	ok(s.walk > 0.99, `walking: the sway is all in after three seconds ({s.walk})`)
	local mx, my, mr, mp = run(s, 4, Torch.WalkSpeed)
	ok(
		mx > Torch.BobAcross * 0.95 and mx <= Torch.BobAcross + 1e-9,
		`walking: full sway across ({mx})`
	)
	ok(
		my > Torch.BobDown * 0.95 and my <= Torch.BobDown + Torch.BreathDown + 1e-9,
		`walking: dips ({my})`
	)
	ok(
		mr <= Torch.BobRoll * RAD + 1e-9 and mr > Torch.BobRoll * RAD * 0.9,
		"walking: rolls, within its roll"
	)
	ok(mp <= (Torch.BobNod + Torch.BreathNod) * RAD + 1e-9, "walking: the beam nods within its nod")
	-- a slow walk sways less, and slower
	local slow = Torch.sway()
	run(slow, 3, Torch.WalkSpeed / 2)
	local sx = run(slow, 4, Torch.WalkSpeed / 2)
	ok(sx < mx * 0.6, `a slow walk sways less ({sx} vs {mx})`)
end

-- The stride's beat: down at each footfall, StepRate times a second at walking speed.
do
	local s = Torch.sway()
	run(s, 3, Torch.WalkSpeed)
	local p = Torch.pose()
	local dips, wasDown = 0, false
	for _ = 1, 600 do -- ten seconds
		Torch.step(s, DT, Torch.WalkSpeed, 0, 0, p)
		local down = p.y < -Torch.BobDown * 0.9
		if down and not wasDown then
			dips += 1
		end
		wasDown = down
	end
	-- two footfalls a stride (|cos| dips twice per cycle), StepRate strides a second
	near(dips, Torch.StepRate * 2 * 10, "a footfall's dip twice a stride", 2)
end

-- Stopping: it rocks once more and settles to the breath.
do
	local s = Torch.sway()
	run(s, 3, Torch.WalkSpeed)
	run(s, 2, 0)
	ok(s.walk < 0.001, `stopped: the sway has gone after two seconds ({s.walk})`)
	local mx = run(s, 1, 0)
	ok(mx < 0.001, "stopped: no sway across")
end

-- Turning: the torch trails, never past its limit, and catches up.
do
	local s = Torch.sway()
	local p = Torch.pose()
	Torch.step(s, DT, 0, 2 * RAD, 0, p)
	ok(
		p.yaw < 0 and p.yaw > -1 * RAD,
		`a small turn left leaves it a little to the right ({p.yaw})`
	)
	for _ = 1, 60 do -- a hard turn: 20 degrees a frame for a second
		Torch.step(s, DT, 0, 20 * RAD, -20 * RAD, p)
	end
	near(p.yaw, -Torch.LagMost * RAD, "a hard turn: it trails no further than its limit")
	near(
		p.pitch,
		Torch.LagMost * RAD,
		"a hard look down: the beam lags up, to its limit",
		Torch.BreathNod * RAD
	)
	for _ = 1, 60 do
		Torch.step(s, DT, 0, 0, 0, p)
	end
	ok(math.abs(p.yaw) < 0.01 * RAD, `a second after the turn it has caught up ({p.yaw})`)
end

-- The click: dips at once, back by ClickSeconds.
do
	local s = Torch.sway()
	local p = Torch.pose()
	run(s, 1, 0)
	Torch.click(s)
	Torch.step(s, DT, 0, 0, 0, p)
	ok(p.pitch < -Torch.ClickDip * RAD * 0.7, `the click dips the beam ({p.pitch / RAD} degrees)`)
	ok(p.y < -Torch.ClickDrop * 0.7, "the click drops the torch")
	run(s, Torch.ClickSeconds, 0)
	Torch.step(s, DT, 0, 0, 0, p)
	ok(p.pitch > -Torch.BreathNod * RAD - 1e-9, "after the click it's back")
end

-- A hitch: a half-second frame moves the sway on no more than a tenth of a second does.
do
	local a, b = Torch.sway(), Torch.sway()
	run(a, 3, Torch.WalkSpeed)
	run(b, 3, Torch.WalkSpeed)
	local pa, pb = Torch.pose(), Torch.pose()
	Torch.step(a, 0.5, Torch.WalkSpeed, 0, 0, pa)
	Torch.step(b, 0.1, Torch.WalkSpeed, 0, 0, pb)
	near(pa.x, pb.x, "a hitch is a tenth of a second")
	near(a.phase, b.phase, "a hitch keeps the stride")
	local c = Torch.sway()
	local pc = Torch.pose()
	Torch.step(c, -1, Torch.WalkSpeed, 0, 0, pc)
	near(c.phase, 0, "a negative frame moves nothing")
end

-- The switch: a burst, then the gap; three blinks in under a second go through.
do
	local may, left = Torch.allow(nil, Torch.Burst, 0)
	ok(may and left == Torch.Burst - 1, "the first switch goes through")
	local last, burst, t = 0, left, 0
	local through = 1
	for _ = 1, 20 do -- mashing at 100 a second for a fifth of a second
		t += 0.01
		local m, l = Torch.allow(last, burst, t)
		if m then
			last, burst = t, l
			through += 1
		end
	end
	ok(
		through >= Torch.Burst and through <= Torch.Burst + 3,
		`mashing: a burst then the gap ({through})`
	)
	-- three blinks (six switches) at a thumb's pace, 0.12 s apart
	local l2, b2, n = nil :: number?, Torch.Burst, 0
	for i = 0, 5 do
		local m, l = Torch.allow(l2, b2, 10 + i * 0.12)
		if m then
			l2, b2 = 10 + i * 0.12, l
			n += 1
		end
	end
	ok(n == 6, `three blinks at a thumb's pace all go through ({n})`)
	-- a long rest earns the whole burst back, never more
	local _, rested = Torch.allow(0, 0, 100)
	ok(rested == Torch.Burst - 1, "a rest earns the burst back")
end

-- The aim from a client.
ok(Torch.aim("12") == nil, "a pitch must be a number")
ok(Torch.aim(0 / 0) == nil, "not NaN")
ok(Torch.aim(math.huge) == nil, "not infinite")
ok(Torch.aim(12.4) == 12, "rounded to whole degrees")
ok(
	Torch.aim(500) == Torch.AimMost and Torch.aim(-500) == -Torch.AimMost,
	"clamped to how far you can look"
)
ok(Torch.heading("12") == nil and Torch.heading(0 / 0) == nil, "a heading must be a real number")
ok(Torch.heading(math.huge) == nil, "not infinite")
ok(Torch.heading(12.4) == 12 and Torch.heading(-12.6) == -13, "rounded to whole degrees")
ok(Torch.heading(190) == -170 and Torch.heading(-180) == -180, "brought round to -180..180")
ok(Torch.heading(180) == -180 and Torch.heading(725) == 5, "a full turn is no turn")
near(Torch.moved(0, 175, 0, -175), 10, "a turn across the back is the short way round")
near(Torch.moved(20, 0, 5, 3), 15, "the larger of up and round")

-- When your aim goes: the first at once; a look about each AimEvery once it has moved AimStep; a
-- big swing, or your screen seeing your beam land on a keeper, as soon as AimSoon.
ok(Torch.shouldSend(nil, math.huge, false), "the first aim is sent")
ok(not Torch.shouldSend(nil, Torch.AimSoon * 0.5, false), "but not straight after another")
ok(not Torch.shouldSend(30, Torch.AimSoon * 0.5, true), "nothing sooner than AimSoon")
ok(not Torch.shouldSend(Torch.AimStep, Torch.AimSoon, false), "a small move waits")
ok(not Torch.shouldSend(Torch.AimStep * 0.5, 1, false), "not for a twitch")
ok(Torch.shouldSend(Torch.AimStep, Torch.AimEvery, false), "a real move is sent")
ok(Torch.shouldSend(Torch.AimSwing, Torch.AimSoon, false), "a big swing goes soon")
ok(Torch.shouldSend(0.4, Torch.AimSoon, true), "a beam landing goes soon, however small")
ok(not Torch.shouldSend(0, Torch.AimSoon, true), "but not with nothing new")
ok(Torch.AimTake < Torch.AimSoon, "the server takes what the client sends soonest")

-- Where an aim points: level and round as a camera turned that way looks.
do
	local function close(a: vector, b: vector, what: string)
		ok(vector.magnitude(a - b) < 1e-6, what)
	end
	close(Torch.look(0, 0), vector.create(0, 0, -1), "no turn looks down -Z")
	close(Torch.look(0, 90), vector.create(-1, 0, 0), "a quarter turn left looks down -X")
	close(Torch.look(0, -90), vector.create(1, 0, 0), "and right, down +X")
	close(Torch.look(90, 0), vector.create(0, 1, 0), "straight up")
	near(vector.magnitude(Torch.look(-35, 123)), 1, "always length 1")
end

-- The beam on a point: within its reach and inside its cone, never behind the eye.
do
	local eye, aim = vector.create(0, 4.5, 0), vector.create(0, 0, -1)
	local half = math.rad(Torch.BeamAngle / 2)
	local function at(d: number, angle: number): vector
		return eye + vector.create(math.sin(angle) * d, 0, -math.cos(angle) * d)
	end
	ok(Torch.lights(eye, aim, at(10, 0)), "straight ahead")
	ok(Torch.lights(eye, aim, at(Torch.BeamRange - 0.01, 0)), "to the end of its reach")
	ok(not Torch.lights(eye, aim, at(Torch.BeamRange + 0.01, 0)), "not past it")
	ok(Torch.lights(eye, aim, at(10, half - 0.01)), "just inside the cone's edge")
	ok(not Torch.lights(eye, aim, at(10, half + 0.01)), "not just outside")
	ok(not Torch.lights(eye, aim, at(10, math.pi)), "never behind")
	ok(not Torch.lights(eye, aim, eye + vector.create(0, 6, -1)), "nor far over the cone")
end

-- The arm: hanging is 0; level is a quarter turn; looking up raises it further, within reach.
near(Torch.raise(0), math.pi / 2, "a level aim holds the arm straight out")
near(Torch.raise(30), (90 + 30) * RAD, "looking up raises it")
near(Torch.raise(-200), (90 - Torch.AimMost) * RAD, "never further down than you can look")

-- The light budget: your own takes one; the nearest lit friends within sight get the rest.
do
	local into = {}
	Torch.budget({ 50, 10, math.huge, 30, 20, 200 }, into)
	local lit = 0
	for _, v in into do
		lit += if v then 1 else 0
	end
	ok(lit == Torch.RealBeams - 1, `the budget lights {Torch.RealBeams - 1} friends ({lit})`)
	ok(into[2] and into[5] and into[4], "the nearest three")
	ok(
		not into[1] and not into[3] and not into[6],
		"not the far one, the dark one or the one past sight"
	)
	Torch.budget({ math.huge, 300 }, into)
	ok(not into[1] and not into[2] and #into == 2, "none when none is lit within sight")
	Torch.budget({}, into)
	ok(#into == 0, "no friends, nothing")
end

print(`torch: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} torch checks failed`)
end
