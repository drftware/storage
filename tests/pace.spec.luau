--!strict
-- lune run tests/pace.spec
local Pace = require("../src/shared/Pace")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- Runs `seconds` of frames `dt` long at `perSecond` from `carry`; returns events fired and the carry.
local function run(seconds: number, dt: number, perSecond: number, carry: number): (number, number)
	local fired = 0
	for _ = 1, math.round(seconds / dt) do
		local now: boolean
		now, carry = Pace.step(carry, dt, perSecond)
		if now then
			fired += 1
		end
	end
	return fired, carry
end

-- the hall's dust: 0.4 puffs a second, one every 2.5 s (101 s, so none lands on the last frame)
local fired60 = run(101, 1 / 60, 0.4, 0)
ok(fired60 == 40, "101 seconds at 60 fps fires 40 puffs (got " .. fired60 .. ")")
local fired15 = run(101, 1 / 15, 0.4, 0)
ok(fired15 == 40, "a slow phone at 15 fps fires the same 40 (got " .. fired15 .. ")")
local fired30, carry30 = run(1, 1 / 30, 0.4, 0)
ok(fired30 == 0, "nothing fires before the first full interval")
ok(math.abs(carry30 - 0.4) < 1e-6, "a second's fraction carries over (got " .. carry30 .. ")")

-- a frame that crosses the line fires once and keeps the remainder
local now, carry = Pace.step(0.9, 0.5, 0.4)
ok(now, "crossing a whole event fires")
ok(math.abs(carry - 0.1) < 1e-6, "the part past the line carries on (got " .. carry .. ")")

-- a hitch: ten seconds in one frame fires once, not four times, and keeps the rhythm
now, carry = Pace.step(0.5, 10, 0.4)
ok(now, "a hitch fires")
ok(
	math.abs(carry - 0.5) < 1e-6,
	"a hitch drops the backlog but keeps the phase (got " .. carry .. ")"
)
ok(carry >= 0 and carry < 1, "the carry stays under one event")

-- exactly one event's worth fires and leaves nothing
now, carry = Pace.step(0.5, 1.25, 0.4)
ok(now and carry == 0, "landing exactly on the line fires and carries nothing")

-- a zero rate never fires
local firedNone = run(60, 1 / 60, 0, 0)
ok(firedNone == 0, "a zero rate never fires")

print(string.format("pace: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("pace spec failed")
end
