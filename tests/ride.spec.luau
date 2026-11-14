--!strict
-- lune run tests/ride.spec
-- The ride (L-08a): the car sits, then climbs one floor on an S-curve and levels exactly; the
-- view never moves while the car stands, stays small, and never jumps between frames (no
-- jitter); the lamp dips as the brakes let go and is steady through the cruise; the halls go
-- dark and come back on time; the readout ticks over as the brakes bite; every sound lands on
-- its moment and fits its recording; and the ride's value round-trips.
local Gate = require("../src/shared/Elevator/Gate")
local Ride = require("../src/shared/Elevator/Ride")
local Specs = require("../src/shared/Elevator/Specs")

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

local FRAME = 1 / 60
local arrive = Ride.arrives()

-- The timeline.
do
	ok(Ride.moves() < Ride.cruising(), "it gathers speed before it cruises")
	ok(Ride.cruising() < Ride.tick() and Ride.tick() < arrive, "the tick comes as it slows")
	ok(arrive < Ride.opens(), "the gate opens after it levels")
	-- about 20 seconds (GDD "The ride"): time to spend coins at the car's machine
	ok(arrive >= 17 and arrive <= 21, `the breath between floors: {arrive} s to level`)
	ok(Ride.opens() + Gate.Delay + Gate.duration(1, 0) < 24, "the gate's open inside 24 s")
	ok(
		Ride.Speed >= 0.9 and Ride.Speed <= 1.4,
		`a slow old freight car: {Ride.Speed} studs a second`
	)
	for _, at in Ride.Clanks do
		ok(at > Ride.cruising() + 0.5 and at < Ride.tick() - 0.5, `clank at {at} is in the cruise`)
	end
end

-- The climb.
do
	ok(Ride.climbed(0) == 0, "still as the gate hits its post")
	ok(Ride.climbed(Ride.Wait) == 0, "still until the brakes let go")
	near(Ride.climbed(arrive), Ride.Rise, "level with the next floor")
	ok(Ride.climbed(arrive + 5) == Ride.Rise, "and stays there")
	near(
		Ride.climbed(Ride.cruising()),
		Ride.Speed * Ride.Speedup / 2,
		"half the ramp's distance at full speed's"
	)
	local was, worst = 0, 0
	for i = 0, math.ceil((arrive + 1) / FRAME) do
		local t = i * FRAME
		local c = Ride.climbed(t)
		ok(c >= was - 1e-9, "it only ever climbs")
		worst = math.max(worst, c - was)
		was = c
		local v = Ride.speed(t)
		ok(v >= 0 and v <= Ride.Speed + 1e-9, "never faster than full speed")
	end
	ok(worst <= Ride.Speed * FRAME + 1e-6, "no frame jumps further than full speed carries it")
	local v0 = Ride.speed(Ride.Wait)
	local v1 = Ride.speed(Ride.cruising())
	local v2 = Ride.speed(arrive - 1e-6)
	near(v0, 0, "it starts from rest")
	near(v1, Ride.Speed, "full speed by the cruise")
	near(v2, 0, "at rest as it levels", 1e-4)
	-- speed is the climb's slope
	for _, t in { 1.2, 2.0, 3.5, 7.5, 8.8 } do
		local slope = (Ride.climbed(t + 1e-4) - Ride.climbed(t - 1e-4)) / 2e-4
		near(Ride.speed(t), slope, `speed matches the climb at {t}`, 1e-3)
	end
	ok(Ride.share(5) == 1 and Ride.share(0) == 0, "the share of full speed")
end

-- The view: still, small, smooth.
do
	local l, n, r = Ride.sway(0)
	ok(l == 0 and n == 0 and r == 0, "the view is still before the brakes let go")
	l, n, r = Ride.sway(Ride.Wait)
	ok(l == 0 and n == 0 and r == 0, "and as they do: the lurch starts from where you are")
	local maxLift, maxAngle, stepLift, stepAngle = 0, 0, 0, 0
	local pl, pn, pr = 0, 0, 0
	for i = 0, math.ceil((arrive + 3) / FRAME) do
		local lift, nod, roll = Ride.sway(i * FRAME)
		maxLift = math.max(maxLift, math.abs(lift))
		maxAngle = math.max(maxAngle, math.abs(nod), math.abs(roll))
		stepLift = math.max(stepLift, math.abs(lift - pl))
		stepAngle = math.max(stepAngle, math.abs(nod - pn), math.abs(roll - pr))
		pl, pn, pr = lift, nod, roll
	end
	ok(maxLift <= 0.15, `the view moves at most 0.15 studs: {maxLift}`)
	ok(maxLift >= 0.05, `but the lurch is felt: {maxLift}`)
	ok(maxAngle <= math.rad(0.6), `and tips at most 0.6 degrees: {math.deg(maxAngle)}`)
	ok(stepLift <= 0.012, `no frame jumps more than 0.012 studs: {stepLift}`)
	ok(stepAngle <= math.rad(0.05), `or tips more than 0.05 degrees: {math.deg(stepAngle)}`)
	l, n, r = Ride.sway(arrive + 3)
	ok(math.abs(l) < 0.002 and math.abs(n) < 1e-3 and math.abs(r) < 1e-9, "settled after levelling")
	local dip = Ride.sway(Ride.Wait + 1 / (4 * Ride.LurchHz))
	ok(dip < -0.05, `the car drops on its cables first: {dip}`)
	local bob = Ride.sway(arrive + 1 / (4 * Ride.SettleHz))
	ok(bob > 0.02, `and bobs up as it levels: {bob}`)
end

-- The lamp.
do
	ok(Ride.lamp(0) == 1 and Ride.lamp(Ride.Wait - 0.01) == 1, "steady while the car stands")
	near(Ride.lamp(Ride.Wait), Ride.ReleaseDip, "it dips as the brakes let go", 1e-3)
	ok(Ride.lamp(Ride.Wait + 0.21) < Ride.lamp(Ride.Wait + 0.15), "and flickers once more")
	ok(Ride.lamp(Ride.Wait + 1) > 0.98, "then it's steady")
	ok(Ride.lamp(Ride.Clanks[1]) < 0.85, "a clank jolts it")
	ok(Ride.lamp(5.2) > 0.99, "steady through the cruise")
	ok(Ride.lamp(arrive) < 0.7, "the brakes biting at the top dim it")
	ok(Ride.lamp(arrive + 1.5) > 0.99, "steady at the floor")
	for i = 0, 800 do
		local v = Ride.lamp(i * 0.0125)
		ok(v >= 0 and v <= 1, "a share of its brightness")
	end
end

-- The halls beyond the gate.
do
	ok(Ride.leaving(Ride.Wait) == 0, "the hall's there until the brakes let go")
	ok(Ride.leaving(Ride.Wait + Ride.DarkIn) == 1, "then it's dark")
	ok(Ride.arriving(0) == 1 and Ride.arriving(arrive) == 1, "the next hall's dark until level")
	near(Ride.arriving(arrive + Ride.Open / 2), 0.5, "lifting as the bell rings")
	near(Ride.arriving(Ride.opens()), 0, "gone as the gate folds", 1e-9)
end

-- The readout.
do
	ok(Ride.shown(0, 3, 4) == 3, "the floor you left")
	ok(Ride.shown(Ride.tick() - 0.01, 3, 4) == 3, "until the brakes bite")
	ok(Ride.shown(Ride.tick(), 3, 4) == 4, "then the next")
	ok(Ride.text(2) == " 2" and Ride.text(10) == "10", "a lone digit right-aligned")
	ok(Ride.text(Ride.Lobby) == " L", "the lobby reads L")
end

-- The sounds land on their moments and fit their recordings.
do
	local cues = Ride.cues()
	local was = -math.huge
	local seen: { [string]: boolean } = {}
	for _, cue in cues do
		ok(cue.at >= was, "in order")
		was = cue.at
		seen[cue.sound] = true
		local row = Ride.Sounds[cue.sound]
		ok(row ~= nil, `{cue.sound} has a recording`)
		ok(row.Start < row.Stop, `{cue.sound}'s stretch runs forward`)
		ok(cue.at >= 0 and cue.at <= Ride.opens() + 0.5, `{cue.sound} plays during the ride`)
		local clunk = (Ride.Clunk :: any)[cue.sound] -- any: Clunk names only some sounds
		if clunk then
			local lands = cue.at + (clunk - row.Start) / cue.pitch
			if cue.sound == "Release" then
				near(lands, Ride.Wait, "the release's clunk lands as the brakes let go")
			elseif cue.sound == "Clank" then
				local on = false
				for _, at in Ride.Clanks do
					on = on or math.abs(lands - at) < 1e-6
				end
				ok(on, `a clank's hit lands on its knock: {lands}`)
			else
				near(lands, arrive, `{cue.sound} lands as the car levels`)
			end
		end
	end
	for _, name in Ride.Names do
		ok(seen[name] == true, `{name} is played`)
	end
	-- the motor and the rumble go round a loop on their steady stretches, so they last any ride;
	-- a sound that doesn't loop runs out
	for _, row in { Ride.Motor, Ride.Rumble } do
		local loop = row.Loop
		ok(
			loop ~= nil and loop > row.Start and row.Stop - loop >= 5,
			`{row.Id} loops on 5 s or more`
		)
		local far = Ride.position(row, Ride.opens() * 1.2)
		ok(
			far ~= nil and far >= (loop or 0) and far < row.Stop,
			`{row.Id} is inside its loop late on`
		)
		ok(Ride.position(row, 0.5) == row.Start + 0.5, "and plays straight through at first")
	end
	ok(Ride.position(Ride.Sounds.Bell, 10) == nil, "the bell doesn't loop")
	local pitch, volume = Ride.motor(Ride.Wait)
	ok(pitch < 1 and volume < 0.5, "the motor starts low and quiet")
	pitch, volume = Ride.motor(5)
	ok(pitch == 1 and volume == 1, "its own at full speed")
	local _, gone = Ride.motor(Ride.motorStops() + Ride.MotorHandOver)
	ok(gone == 0, "and gone under its winding-down")
end

-- The shaft fits between the landing and the car.
do
	local s = Ride.Shaft
	ok(s.Plane - s.Depth / 2 > 0.5, "behind the landing's frame")
	ok(s.Plane + s.Depth / 2 < Specs.Car.Front, "in front of the car's front")
	ok(s.Width > Specs.Car.Width, "wider than the car")
	ok(s.Mouth == Specs.Opening.Height, "a landing's mouth is the lobby's opening")
	local bare = Ride.Rise - s.Mouth - s.Header - s.Apron - s.Sill
	ok(bare > s.Number.Above + s.Number.Height, "the number fits on the bare wall")
	for _, h in s.Seams do
		ok(h > 0 and h < bare, "each seam on the bare wall")
	end
end

-- The ride's value.
do
	local at, from, to = Ride.decode(Ride.encode(1234.5678, 3, 4))
	ok(at ~= nil and math.abs((at :: number) - 1234.568) < 1e-6, "when")
	ok(from == 3 and to == 4, "from and to")
	local none = Ride.decode(nil)
	ok(none == nil, "no value: no ride")
	local broken = Ride.decode("12|a|4")
	ok(broken == nil, "a broken value: no ride")
end

print(`ride: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
