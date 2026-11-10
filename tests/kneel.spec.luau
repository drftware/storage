--!strict
-- lune run tests/kneel.spec
local Kneel = require("../src/shared/StorageUnit/Kneel")

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

-- Tapping Peek: down at once while the server's lift is on its way, up if it never comes.
do
	local h = Kneel.start(10, 3, -5, 100)
	ok(not h.lifted, "a fresh tap waits for the door")
	ok(Kneel.holds(h, 100, 10, 3, -5), "down the moment you tap")
	ok(Kneel.holds(h, 100 + Kneel.Confirm, 10, 3, -5), "still down as the wait runs out")
	ok(not Kneel.holds(h, 100 + Kneel.Confirm + 0.01, 10, 3, -5), "no lift in time: up")
	ok(Kneel.doorMoved(h, "Peek"), "the door's peek is yours")
	ok(h.lifted, "and marks the door lifted")
	ok(Kneel.holds(h, 100 + 60, 10, 3, -5), "lifted, you stay down as long as you like")
	ok(not Kneel.doorMoved(h, "Peek"), "a second peek is someone else's move: up")
end

-- Every other move of the door stands you up, before or after its lift.
for _, kind in { "Open", "Close", "Slam", "Bang", "Burst", "Rattle", "LiftInside" } do
	local before = Kneel.start(0, 3, 0, 0)
	ok(not Kneel.doorMoved(before, kind), `{kind} before the lift stands you up`)
	local after = Kneel.start(0, 3, 0, 0)
	Kneel.doorMoved(after, "Peek")
	ok(not Kneel.doorMoved(after, kind), `{kind} after the lift stands you up`)
end

-- The server's hold starts lifted: it lifted the door itself.
do
	local h = Kneel.start(0, 3, 0, 0, true)
	ok(h.lifted, "the server's hold starts lifted")
	ok(Kneel.holds(h, 1000, 0, 3, 0), "and never times out")
	ok(not Kneel.doorMoved(h, "Peek"), "so any move of the door after it stands you up")
end

-- Staying where you knelt: a nudge stays down, a step or a jump stands you.
do
	local h = Kneel.start(10, 3, -5, 0, true)
	local m = Kneel.MoveOff
	ok(Kneel.holds(h, 1, 10 + m * 0.99, 3, -5), "a nudge just short of MoveOff stays down")
	ok(not Kneel.holds(h, 1, 10 + m * 1.01, 3, -5), "just past it stands you")
	local d = m * 0.99 / math.sqrt(2)
	ok(Kneel.holds(h, 1, 10 + d, 3, -5 - d), "the same nudge on a diagonal stays down")
	local e = m * 1.01 / math.sqrt(2)
	ok(not Kneel.holds(h, 1, 10 - e, 3, -5 + e), "and past it on a diagonal stands you")
	ok(Kneel.holds(h, 1, 10, 3 + Kneel.RiseOff, -5), "a settle of the body stays down")
	ok(not Kneel.holds(h, 1, 10, 3 + Kneel.RiseOff + 0.01, -5), "a jump stands you")
	ok(not Kneel.holds(h, 1, 10, 3 - Kneel.RiseOff - 0.01, -5), "a fall stands you")
end

-- The ease: Down seconds each way, eased at both ends, turning straight back halfway.
do
	ok(near(Kneel.weight(0), 0) and near(Kneel.weight(1), 1), "weight runs 0 to 1")
	ok(near(Kneel.weight(-1), 0) and near(Kneel.weight(2), 1), "and holds outside it")
	local level, steps, last = 0, 0, 0
	local dt = 1 / 60
	while level < 1 and steps < 1000 do
		level = Kneel.toward(level, true, dt)
		steps += 1
		local w = Kneel.weight(level)
		ok(w >= last, "dropping never rises")
		last = w
	end
	ok(near(steps * dt, Kneel.Down, dt + 1e-9), "all the way down in Down seconds")
	ok(Kneel.weight(Kneel.toward(0, true, dt)) < 0.01, "the first frame barely moves: eased in")
	ok(Kneel.toward(1, true, dt) == 1, "down holds")
	local half = Kneel.toward(0, true, Kneel.Down / 2)
	ok(near(Kneel.weight(half), 0.5), "halfway in time is halfway down")
	local back = Kneel.toward(half, false, Kneel.Down / 2)
	ok(near(back, 0), "standing halfway down takes as long back up")
	ok(Kneel.toward(0, false, dt) == 0, "standing holds")
end

-- The drop: a standard avatar's eye from 4.5 down to Eye; taller roots drop further.
do
	local std = Kneel.drop(2, 2)
	ok(near(std, 4.5 - Kneel.Eye), "a standard avatar drops from 4.5 to Eye")
	ok(near(Kneel.drop(2.5, 2) - std, 0.5), "longer legs drop as much further")
	ok(near(Kneel.drop(2, 2.4) - std, 0.4), "a taller root raises the camera twice its half")
	ok(Kneel.drop(0, 0) == 0, "never drops you up")
	ok(Kneel.Eye > 0.5 and Kneel.Eye <= 1.15, "the eye ends just under a peek's foot of gap (1.15)")
	local pose = Kneel.Pose
	ok(pose.Sink > 0 and pose.Sink < 1, "the body sinks a share of its hip height")
	ok(pose.Back >= 0 and pose.Back < 1, "and shifts back a share of it")
	ok(Kneel.Rustle.fade < Kneel.Rustle.length, "the rustle's fade fits inside it")
	ok(
		Kneel.Rustle.length / Kneel.Rustle.pitch <= Kneel.Down * 1.5,
		"the rustle ends about with the drop"
	)
end

-- The buttons while you're down: in view above a level gaze, never over the gap.
do
	local standing = 4
	for _, d in { 0, 0.5, 1, 1.5, 2, 3, 4, 6, 8, 12 } do
		local h = Kneel.buttonHeight(d, standing)
		ok(h >= Kneel.ButtonLowest - 1e-9 and h <= standing, `{d} studs out: between the gap and 4`)
		if h > Kneel.ButtonLowest + 1e-9 and h < standing - 1e-9 then
			local angle = math.atan((h - Kneel.Eye) / d)
			ok(near(angle, Kneel.ButtonAngle), `{d} studs out: ButtonAngle over a level gaze`)
		end
		-- in view: Roblox's 70-degree view is 35 degrees each way; keep within 30
		if d >= 2 then
			ok(math.atan((h - Kneel.Eye) / d) <= math.rad(30), `{d} studs out: on screen`)
		end
	end
	ok(
		Kneel.buttonHeight(0, standing) == Kneel.ButtonLowest,
		"pressed to the door: just over the gap"
	)
	ok(Kneel.buttonHeight(100, standing) == standing, "far back: no lower than standing")
	ok(Kneel.buttonHeight(3, 1) == 1, "never above where they stand")
	ok(Kneel.ButtonLowest > 1.15 + 0.5, "the lowest still clears the peek's gap")
end

print(`kneel: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
