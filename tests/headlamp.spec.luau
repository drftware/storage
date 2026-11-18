--!strict
-- lune run tests/headlamp.spec
-- The hard hat's own beam (F-G1b4a2, Finds/Headlamp): tighter and whiter than the torch's; it
-- swings up from your feet into place as the hat goes on; it nods with your stride but never lags
-- your look; a friend's hat drops onto their head and settles; only the nearest few are real.
local Headlamp = require("../src/shared/Finds/Headlamp")
local Torch = require("../src/shared/Flashlight/Torch")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- tighter and whiter than the torch
ok(Headlamp.Angle < Torch.BeamAngle * 0.75, "a tighter cone than the torch's")
local c, w = Headlamp.Color, Torch.BeamColor
ok(c[3] >= c[1] and c[3] > w[3], "whiter: no warm yellow, bluer than the torch")
ok(Headlamp.Range >= Torch.BeamRange, "it throws at least as far")

-- the pull-on: dark before its bulb, then up from your feet, a touch past, and level
local down, light = Headlamp.swing(-0.1)
ok(down == Headlamp.SwingFrom and light == 0, "before the bulb lights: dark, at your feet")
down, light = Headlamp.swing(0)
ok(math.abs(down - Headlamp.SwingFrom) < 1e-6 and light == 0, "it starts at your feet")
_, light = Headlamp.swing(Headlamp.RampSeconds)
ok(light == 1, "the LED is full within its ramp")
local past, was = false, Headlamp.SwingFrom
local rising = true
for i = 1, 100 do
	local t = Headlamp.SwingSeconds * i / 100
	local d = Headlamp.swing(t)
	if d < -0.5 then
		past = true
	end
	if not past and d > was + 1e-6 then
		rising = false
	end
	was = d
end
ok(rising, "it only rises until it's past your look")
ok(past, "it rises a touch past your look")
local most = 0
for i = 1, 100 do
	local d = Headlamp.swing(Headlamp.SwingSeconds * i / 100)
	most = math.min(most, d)
end
ok(most > -8, "but only a touch: under 8 degrees")
down = Headlamp.swing(Headlamp.SwingSeconds)
ok(down == 0, "level with your look once it's in place")
down = Headlamp.swing(5)
ok(down == 0, "and stays there")

-- the stride: nods and weaves with the torch's sway, never lags a turn
local s, p = Torch.sway(), Torch.pose()
for _ = 1, 120 do
	Torch.step(s, 1 / 60, 0, 0, 0, p)
end
local nod, weave = Headlamp.bob(p)
ok(math.abs(nod) < 0.5 * math.pi / 180 and weave == 0, "standing still: only a breath")
local biggest = 0
for _ = 1, 240 do
	Torch.step(s, 1 / 60, Torch.WalkSpeed, 0, 0, p)
	local n, wv = Headlamp.bob(p)
	biggest = math.max(biggest, math.abs(n), math.abs(wv))
end
ok(biggest > 0.3 * math.pi / 180, "walking: it nods and weaves with the stride")
ok(biggest < 3 * math.pi / 180, "but never wanders off your look")
s = Torch.sway()
Torch.step(s, 1 / 60, 0, 0, 0, p)
ok(p.yaw == 0 and math.abs(p.pitch) < 0.01, "no turn fed in: no lag")

-- a friend's hat drops onto their head and settles
local up, tilt, done = Headlamp.settle(0, 1)
ok(math.abs(up - Headlamp.DropFrom) < 1e-6 and tilt > 0 and not done, "it starts over the head")
local u2 = Headlamp.settle(Headlamp.DropSeconds * 0.5, 1)
ok(u2 < up and u2 > 0, "it falls")
local landed = Headlamp.settle(Headlamp.DropSeconds, 1)
ok(math.abs(landed) < 1e-6, "it lands on its seat")
local hopTop = Headlamp.settle(Headlamp.DropSeconds + Headlamp.HopSeconds / 2, 1)
ok(hopTop > 0 and hopTop <= Headlamp.Hop + 1e-6, "a small hop as it lands")
up, tilt, done = Headlamp.settle(Headlamp.DropSeconds + Headlamp.HopSeconds, 1)
ok(up == 0 and tilt == 0 and done, "then still, level on its seat")
local big = Headlamp.settle(0, 1.5)
ok(math.abs(big - Headlamp.DropFrom * 1.5) < 1e-6, "a bigger head's hat drops from higher")
ok(Headlamp.DropSeconds + Headlamp.HopSeconds < 0.6, "the whole settle is quick")

-- the phone's cap: the nearest few friends only, none past Seen
local into = {}
Headlamp.budget({ 30, 10, math.huge, 20, 200 }, into)
ok(into[2] and into[4] and not into[1], "the nearest two friends' are real")
ok(not into[3] and not into[5], "an unlit one and one past Seen never are")
local n = 0
for _, real in into do
	if real then
		n += 1
	end
end
ok(n == Headlamp.RealBeams - 1, "yours and the nearest friends': the cap")
local torch = {}
Torch.budget({ 30, 10, 20, 25, 5 }, torch)
local t = 0
for _, real in torch do
	if real then
		t += 1
	end
end
ok(t == Torch.RealBeams - 1, "the torch keeps its own cap")

print(`headlamp: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
