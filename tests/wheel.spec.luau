--!strict
-- lune run tests/wheel.spec
-- The inventory wheel (L-20a): its slots fan out over the button on an arc, slot 1 on the left,
-- each a thumb apart, clear of the button and the box, on screen on the Galaxy A16; the d-pad steps
-- round them; a press switches, lifts or pockets as it should; and it opens in a beat.
local Wheel = require("../src/shared/Tools/Wheel")

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

-- The Galaxy A16 in Studio's Device Simulator: the button is 56 across (12% of 338, at least 56),
-- its middle 298 down (the old slots' row, measured: 267 to 328 with the lift).
local A16_SIZE = 56
local A16_MIDDLE = 298
local A16_TOP_INSET = 58 -- Roblox's top bar on the A16

for _, n in { 3, 6 } do
	for _, size in { 56, 70, 88 } do
		local slot = size * Wheel.SlotOfButton
		local box = math.floor(size * Wheel.BoxOfButton)
		local bx = Wheel.boxAt(size)
		local xs, ys = {}, {}
		for i = 1, n do
			local x, y = Wheel.place(i, n, size)
			xs[i], ys[i] = x, y
			ok(y < 0, `{n} slots, {size}: slot {i} above the button's middle`)
			ok(
				math.sqrt(x * x + y * y) >= size / 2 + slot / 2 + 4,
				`{n} slots, {size}: slot {i} clear of the button`
			)
			-- clear of the box: the slot's circle off the box's square, a few pixels spare
			local dx = math.max(math.abs(x - bx) - box / 2, 0)
			local dy = math.max(math.abs(y) - box / 2, 0)
			ok(
				math.sqrt(dx * dx + dy * dy) >= slot / 2 + 4,
				`{n} slots, {size}: slot {i} clear of the box`
			)
		end
		for i = 2, n do
			local d = math.sqrt((xs[i] - xs[i - 1]) ^ 2 + (ys[i] - ys[i - 1]) ^ 2)
			ok(
				d >= slot * Wheel.Room - 1e-6,
				`{n} slots, {size}: slots {i - 1} and {i} a thumb apart`
			)
			ok(xs[i] > xs[i - 1], `{n} slots, {size}: slot {i} right of slot {i - 1}`)
		end
		ok(math.abs(xs[1] + xs[n]) < 1e-6, `{n} slots, {size}: the arc is even about the button`)
	end
end

-- three slots: the middle one straight up
do
	local x, y = Wheel.place(2, 3, A16_SIZE)
	ok(math.abs(x) < 1e-6 and y < 0, "slot 2 of 3 straight over the button")
end

-- on the A16 the whole wheel is on screen, under the top bar
for _, n in { 3, 6 } do
	for i = 1, n do
		local x, y = Wheel.place(i, n, A16_SIZE)
		local slot = A16_SIZE * Wheel.SlotOfButton
		ok(
			A16_MIDDLE + y - slot / 2 >= A16_TOP_INSET + 8,
			`A16, {n} slots: slot {i} under the top bar`
		)
		ok(math.abs(x) + slot / 2 <= 685 / 2 - 8, `A16, {n} slots: slot {i} on screen across`)
	end
end

-- the d-pad steps round, wrapping
ok(Wheel.step(1, 1, 3) == 2 and Wheel.step(3, 1, 3) == 1, "right steps on and wraps to 1")
ok(Wheel.step(1, -1, 3) == 3 and Wheel.step(2, -1, 3) == 1, "left steps back and wraps to 3")

-- a press
ok(Wheel.press(2, 1, false, true, false) == "Switch", "another slot switches")
ok(Wheel.press(2, 1, true, false, true) == "Switch", "another slot switches, even pocketed")
ok(Wheel.press(1, 1, true, true, false) == "Lift", "your own pocketed slot on the wheel lifts")
ok(Wheel.press(1, 1, true, true, true) == "Lift", "your own pocketed slot's key lifts")
ok(Wheel.press(1, 1, false, true, true) == "Pocket", "your own slot's key again pockets")
ok(Wheel.press(1, 1, false, true, false) == "None", "your own slot on the wheel just folds it")
ok(Wheel.press(1, 1, false, false, true) == "None", "an empty hand has nothing to pocket")

-- the motion: in a beat, the last slot out within a fifth of a second
ok(Wheel.Open + Wheel.Stagger * 5 <= 0.25, "even six slots fan out in a quarter second")
ok(Wheel.Open + Wheel.Stagger * 2 <= 0.17, "three fan out in a beat")
ok(Wheel.Close < Wheel.Open and Wheel.Fly <= Wheel.Open, "folding is quicker than opening")

print(`wheel: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
