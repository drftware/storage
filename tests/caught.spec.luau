--!strict
-- lune run tests/caught.spec
-- A keeper's catch on the caught player's screen (L-06b3c): the screen drops to `Jolt` at once,
-- closes to black by `Dark` (when the server stores them), stays black for `Hold`, and opens
-- again over `Lift`, never jumping once it has begun; "Caught" is up only in the dark; the wrap
-- is the GDD's 2 seconds.
local Caught = require("../src/shared/Caught")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local lifts = Caught.Dark + Caught.Hold
ok(Caught.blackout(-0.01) == 0 and Caught.headline(-0.01) == 0, "nothing before the catch")
ok(Caught.blackout(0) == Caught.Jolt, "the jolt drops the screen at once")
ok(Caught.Jolt > 0.3 and Caught.Jolt < 0.8, `a blink, not a cut to black ({Caught.Jolt})`)
ok(Caught.blackout(Caught.Dark) == 1, "black once it has closed")
ok(Caught.blackout(lifts) == 1, "black through the hold")
ok(Caught.blackout(Caught.Wrap) == 0, "clear once it's over")
ok(Caught.headline(0) == 0, "no word at the jolt")
ok(Caught.headline(Caught.Dark) == 1 and Caught.headline(lifts) == 1, '"Caught" in the dark')
ok(Caught.headline(lifts + Caught.Lift / 2) < 1e-9, "gone before the screen is clear")
ok(Caught.Wrap >= 1.5 and Caught.Wrap <= 2.5, `about the GDD's 2-second wrap ({Caught.Wrap} s)`)
ok(Caught.Kick > 0 and Caught.Kick <= 1, "a jolt CameraShake can take")
ok(Caught.showing(0) and Caught.showing(Caught.Wrap - 0.01), "on screen the whole time")
ok(not Caught.showing(Caught.Wrap) and not Caught.showing(-0.01), "and not after")

-- it closes, holds and opens without a jump, at 60 frames a second
local was = Caught.blackout(0)
local closing = true
for i = 1, math.ceil(Caught.Wrap * 60) + 10 do
	local t = i / 60
	local b = Caught.blackout(t)
	ok(b >= 0 and b <= 1, `between clear and black at {t}`)
	ok(math.abs(b - was) <= 0.1, `no jump at {t} ({was} to {b})`)
	if closing then
		ok(b >= was, `it only darkens while closing, at {t}`)
		closing = t < lifts
	else
		ok(b <= was, `it only clears while opening, at {t}`)
	end
	ok(Caught.headline(t) <= Caught.blackout(t) + 1e-9, `the word never outlasts the dark at {t}`)
	was = b
end

print(string.format("caught: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("caught spec failed")
end
