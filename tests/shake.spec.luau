--!strict
-- lune run tests/shake.spec
local Shake = require("../src/shared/Shake")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- still with no trauma
local p, y, r, x, z = Shake.offset(0, 1.234)
ok(p == 0 and y == 0 and r == 0 and x == 0 and z == 0, "no trauma, no shake")

-- never past its limits, and it really moves at full trauma
local most = 0
for i = 0, 2000 do
	local a, b, c, d, e = Shake.offset(1, i / 240)
	ok(
		math.abs(a) <= Shake.MaxAngle + 1e-9 and math.abs(b) <= Shake.MaxAngle + 1e-9,
		"angles in range"
	)
	ok(math.abs(c) <= Shake.MaxRoll + 1e-9, "roll in range")
	ok(
		math.abs(d) <= Shake.MaxOffset + 1e-9 and math.abs(e) <= Shake.MaxOffset + 1e-9,
		"shift in range"
	)
	most = math.max(most, math.abs(a))
end
ok(most > Shake.MaxAngle * 0.3, string.format("full trauma visibly tips the view (%.4f)", most))

-- a small hit barely moves it: the shake is trauma squared
local small = 0
for i = 0, 2000 do
	small = math.max(small, math.abs((Shake.offset(0.3, i / 240))))
end
ok(small <= most * 0.09 + 1e-9, "a third of the trauma, a ninth of the shake")

-- smooth: one frame to the next moves little
local a1 = Shake.offset(1, 0.5)
local a2 = Shake.offset(1, 0.5 + 1 / 60)
ok(math.abs(a2 - a1) < Shake.MaxAngle, "a shiver, not a jump")

-- hits pile up to a cap; it drains away
ok(Shake.add(0.8, 0.6) == 1, "trauma caps at 1")
ok(Shake.add(0.2, -1) == 0.2, "a negative hit adds nothing")
ok(math.abs(Shake.decay(1, 0.5) - (1 - Shake.Decay * 0.5)) < 1e-9, "it drains steadily")
ok(Shake.decay(0.1, 1) == 0, "and stops at none")
local t, settled = 0.6, 0
while t > 0 do
	t = Shake.decay(t, 1 / 60)
	settled += 1 / 60
end
ok(settled < 0.6, string.format("a slam's jolt settles quickly (%.2f s)", settled))

-- reach
ok(Shake.falloff(0, 5, 20) == 1 and Shake.falloff(25, 5, 20) == 0, "full near, none far")
ok(Shake.falloff(10, 5, 20) > Shake.falloff(15, 5, 20), "fades with distance")

print(string.format("shake: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("shake spec failed")
end
