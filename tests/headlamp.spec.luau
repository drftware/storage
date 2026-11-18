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

-- F-G1b4b: its minute runs down as the torch dies, then its bulb sputters out
local Charge = require("../src/shared/Flashlight/Charge")
local K = Headlamp.Shape
ok(Headlamp.minute(nil, 60) == 60, "the minute as pressed")
ok(Headlamp.minute(8, 60) == 8, "Studio's dev seconds")
ok(Headlamp.minute(0 / 0, 60) == 60 and Headlamp.minute(-2, 60) == 60, "nonsense ignored")
ok(Headlamp.minute(8, math.huge) == math.huge, "at home it burns for good")

local f = Charge.flicker(7)
local l, st = Headlamp.light(f, 40, 1 / 30, nil)
ok(l == 1 and not st, "steady before its last stretch")
l, st = Headlamp.light(f, K.flicker - 0.01, 1 / 30, nil)
ok(st and l < 1.0001, "the first stutter as its last stretch opens: you notice")
ok(K.flicker < Charge.Flicker and K.flicker >= 10, "a shorter warning than the torch's half minute")

-- through its last stretch at 30 frames a second: stutters close in, it sags, moments of black
f = Charge.flicker(11)
local dt = 1 / 30
local starts = { 0, 0 } -- stutters starting in the stretch's first half and second half
local was, darkLate, most = false, false, 0
local sumFirst, nFirst, sumLast, nLast = 0, 0, 0, 0
local left = K.flicker
while left > 0 do
	local lv, s2 = Headlamp.light(f, left, dt, nil)
	most = math.max(most, lv)
	if s2 and not was then
		local half = if left > K.flicker / 2 then 1 else 2
		starts[half] += 1
	end
	was = s2
	if left < 3 and lv < 0.05 then
		darkLate = true
	end
	if not s2 then
		if left > K.flicker - 3 then
			sumFirst += lv
			nFirst += 1
		elseif left < 1 then
			sumLast += lv
			nLast += 1
		end
	end
	left -= dt
end
ok(starts[2] > starts[1], "the stutters close in toward the end")
ok(darkLate, "moments of black near the end")
ok(most <= 1, "never brighter than full")
ok(nFirst > 0 and nLast > 0 and sumLast / nLast < sumFirst / nFirst - 0.2, "it sags as it starves")
ok(nLast > 0 and math.abs(sumLast / nLast - (1 - K.sag)) < 0.05, "it ends at its sag")

-- its run-down: the beam follows the bulb from where the sag left it, so the two go out together
l, st = Headlamp.light(f, 0, dt, 1)
ok(math.abs(l - (1 - K.sag)) < 1e-9 and st, "the run-down starts where the minute ended")
l, st = Headlamp.light(f, -1, dt, 0.5)
ok(math.abs(l - 0.5 * (1 - K.sag)) < 1e-9 and st, "it follows the bulb's sputter")
l, st = Headlamp.light(f, -2.9, dt, 0)
ok(l == 0 and not st, "the bulb out: dark and quiet")
l, st = Headlamp.light(f, -4, dt, nil)
ok(l == 0 and not st, "spent: dark")

-- the torch's own flicker is the same as before (its shape is the default)
local a, b = Charge.flicker(5), Charge.flicker(5)
local same = true
left = Charge.Flicker
while left > 0 do
	local x1, y1 = Charge.glow(a, left, dt)
	local x2, y2 = Charge.glow(b, left, dt, Charge.Torch)
	if x1 ~= x2 or y1 ~= y2 then
		same = false
	end
	left -= dt
end
ok(same, "the torch's run-down unchanged")

-- the break: a crack and its bits, as D-141's
ok(#Headlamp.Bits >= 2 and Headlamp.Crack.id ~= "", "it cracks apart in its colours")
ok(Headlamp.FallUp > 0 and Headlamp.FallUp < 8, "it slips off with a hop, not a tool's jump")

print(`headlamp: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
