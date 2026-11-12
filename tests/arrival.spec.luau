--!strict
-- lune run tests/arrival.spec
-- A press made the moment you arrive counts (L-16b2): judged where the server sees you, and where
-- you'll be over the next moment at the speed it sees you moving, since it sees a run late.
local Arrival = require("../src/shared/Arrival")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- A button's reach, as the server judges a press: someone the server sees at `at`, moving at
-- `velocity`, within `reach` of `button`.
local function reaches(at: vector, velocity: vector, button: vector, reach: number): boolean
	return Arrival.counts(function(seconds: number): boolean
		return vector.magnitude(at + velocity * seconds - button) <= reach
	end)
end

local still = vector.zero
local run = 16 -- studs a second, a full run (Studio, L-16b2)

-- the judged moments: where the server sees you first, out to the whole lag, evenly
ok(Arrival.ahead(0) == 0, "first where the server sees you")
ok(math.abs(Arrival.ahead(Arrival.Steps) - Arrival.Lag) < 1e-9, "last a whole lag on")
ok(Arrival.Lag >= 0.3 and Arrival.Lag <= 0.5, "covers the server's late view (0.22 to 0.27 s seen)")
ok(Arrival.Lag * run / Arrival.Steps <= 2, "at a full run, judged no more than 2 studs apart")
do
	local seen = {}
	Arrival.counts(function(seconds: number): boolean
		table.insert(seen, seconds)
		return false
	end)
	ok(#seen == Arrival.Steps + 1, "every moment judged when none counts")
	local order = true
	for i = 2, #seen do
		order = order and seen[i] > seen[i - 1]
	end
	ok(order, "judged in order, nearest first")
	local calls = 0
	ok(
		Arrival.counts(function(_: number): boolean
			calls += 1
			return true
		end),
		"counts when where it sees you counts"
	)
	ok(calls == 1, "and stops there")
end

-- Climb, measured in Studio: pressed 5.84 from the ladder's foot on screen (its reach 6); the
-- server saw 9.22 off, running at it at 16 (the server's reach 6 + 3 slack)
do
	local button = vector.create(0, 0.5, 0)
	local at = vector.create(9.2, 0, 0)
	local toward = vector.create(-run, 0, 0)
	ok(reaches(at, toward, button, 9), "ran at the ladder and pressed Climb at once: counts")
	ok(not reaches(at, still, button, 9), "standing that far off: no")
	ok(not reaches(at, -toward, button, 9), "running away from it: no")
	ok(not reaches(vector.create(20, 0, 0), toward, button, 9), "still well back up the hall: no")
end

-- Running past a button: off its reach where the server sees you and a whole lag on, in reach
-- between; the press still counts
do
	local button = vector.zero
	local at = vector.create(-3.2, 0, 2.6)
	local past = vector.create(run, 0, 0)
	ok(vector.magnitude(at - button) > 4, "(set-up) out of reach where it sees you")
	ok(vector.magnitude(at + past * Arrival.Lag - button) > 4, "(set-up) out of reach a lag on")
	ok(reaches(at, past, button, 4), "ran past it and pressed as it was nearest: counts")
end

-- Saw at a wall, measured in Studio: pressed just inside Unit 101 on screen, the server still saw
-- you in the hall 4.3 studs back. In the unit's door frame (+Z in, X across), a unit 12 wide and
-- 10 deep, its Saw button on the side wall 5 in: inside and in reach (6 + 3) both count.
do
	local W, D = 12, 10
	local button = vector.create(5.4, -0.8, 4.95)
	local function sawCounts(at: vector, velocity: vector): boolean
		return Arrival.counts(function(seconds: number): boolean
			local p = at + velocity * seconds
			return p.z > 0
				and p.z < D
				and math.abs(p.x) < W / 2
				and vector.magnitude(p - button) <= 9
		end)
	end
	local seen = vector.create(-0.3, 0, -3.5)
	ok(sawCounts(seen, vector.create(7.4, 0, 14.2)), "ran in and pressed Saw at once: counts")
	ok(not sawCounts(seen, still), "standing in the hall: no")
	ok(not sawCounts(seen, vector.create(run, 0, 0)), "running along the hall past the door: no")
	ok(sawCounts(vector.create(4, 0, 5), still), "standing at the wall: counts")
	ok(
		sawCounts(vector.create(4, 0, 5), vector.create(0, 0, -run)),
		"at the wall, running out: counts"
	)
end

print(`arrival: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
