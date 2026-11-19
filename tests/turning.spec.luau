--!strict
-- lune run tests/turning.spec
-- How a thing carried in Arrange turns (S5-03j2b2a, Home/Turning): two fingers twisting turn it
-- the other way to their twist on the screen (Gestures' twists are clockwise, a turn anticlockwise
-- as one looks at the face it stands on); on the grid it clicks into quarters, Free stops at any
-- whole degree; a Turn press is a quarter, so presses and a twist agree; any number of turns either
-- way comes round to 0 up to 360; and a turn's facing is exact at every quarter.
local Turning = require("../src/shared/Home/Turning")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

local QUARTER = math.pi / 2 -- a twist of a quarter, clockwise on the screen
local function deg(d: number): number -- a twist of `d` degrees, clockwise on the screen
	return math.rad(d)
end

-- Any turn comes round to 0 up to 360.
do
	ok(Turning.round(0) == 0 and Turning.round(90) == 90, "0 and 90 as they are")
	ok(Turning.round(360) == 0 and Turning.round(720) == 0, "a whole turn is 0")
	ok(Turning.round(-90) == 270 and Turning.round(-720) == 0, "negative turns come round")
	ok(Turning.round(450) == 90 and Turning.round(37.5) == 37.5, "past 360, and a part degree kept")
	ok(Turning.nearest(44) == 0 and Turning.nearest(46) == 90, "the nearest quarter")
	ok(Turning.nearest(-44) == 0 and Turning.nearest(-46) == 270, "the nearest quarter, negative")
	ok(Turning.nearest(359) == 0 and Turning.nearest(315.5) == 0, "near a whole turn: 0, not 360")
end

-- On the grid: a twist clicks round in quarters, the nearest to where the fingers have it.
do
	ok(Turning.twisted(0, 0, false) == 0, "no twist: as it was")
	ok(Turning.twisted(0, -QUARTER, false) == 90, "a quarter anticlockwise on the screen: 90")
	ok(Turning.twisted(0, QUARTER, false) == 270, "a quarter clockwise: 270")
	ok(Turning.twisted(0, -deg(40), false) == 0, "under half a quarter: it holds")
	ok(Turning.twisted(0, -deg(50), false) == 90, "past half a quarter: it clicks round")
	ok(Turning.twisted(270, -math.pi, false) == 90, "past 360: round to 90")
	ok(Turning.twisted(90, -4 * math.pi, false) == 90, "two whole turns: home")
	ok(Turning.twisted(90, 7 * QUARTER, false) == 180, "seven quarters clockwise: 180")
	ok(Turning.twisted(37, 0, false) == 0, "a thing set off the grid comes square on it")
end

-- Free: any whole degree, never snapped.
do
	ok(Turning.twisted(0, -deg(37), true) == 37, "37 degrees anticlockwise: 37")
	ok(Turning.twisted(0, -deg(37.3), true) == 37, "whole degrees")
	ok(Turning.twisted(0, deg(37), true) == 323, "37 clockwise: 323")
	ok(Turning.twisted(37, -QUARTER, true) == 127, "a quarter on from 37: 127")
	ok(Turning.twisted(350, -deg(20), true) == 10, "past 360: 10")
	ok(Turning.twisted(10, deg(20), true) == 350, "under 0: 350")
	ok(Turning.twisted(37, -6 * math.pi, true) == 37, "three whole turns: home")
	ok(Turning.twisted(90, 0, true) == 90, "no twist: as it was")
end

-- A Turn press is a quarter anticlockwise, and a twist of a quarter agrees with it.
do
	for _, t in { 0, 90, 180, 270 } do
		local pressed = Turning.press(t, false)
		ok(pressed == Turning.round(t + 90), `a press from {t}`)
		ok(pressed == Turning.twisted(t, -QUARTER, false), `a press and a twist agree from {t}`)
		ok(Turning.press(t, true) == pressed, `Free or not, a press from a quarter: {t}`)
	end
	local t = 0
	for _ = 1, 3 do
		t = Turning.press(t, false)
	end
	ok(
		t == Turning.twisted(0, -3 * QUARTER, false),
		"three presses and three quarters' twist agree"
	)
	ok(Turning.press(t, false) == 0, "four presses: home")
	ok(Turning.press(37, true) == 127, "Free: a quarter on from 37")
	ok(Turning.press(37, true) == Turning.twisted(37, -QUARTER, true), "and the twist agrees")
	ok(Turning.press(37, false) == 90, "on the grid: on to the next quarter")
	ok(Turning.press(315, false) == 0, "the next quarter past 315 is 0")
	ok(Turning.press(89.9999999, false) == 180, "a hair under a quarter counts as on it")
	local free = 37
	for _ = 1, 4 do
		free = Turning.press(free, true)
	end
	ok(free == 37, "Free: four presses home")
end

-- A turn's facing, exact at every quarter.
do
	local c, s = Turning.facing(0)
	ok(c == 1 and s == 0, "0 faces straight")
	c, s = Turning.facing(90)
	ok(c == 0 and s == 1, "90 exact")
	c, s = Turning.facing(-90)
	ok(c == 0 and s == -1, "-90 is 270")
	c, s = Turning.facing(540)
	ok(c == -1 and s == 0, "540 is 180")
	c, s = Turning.facing(37)
	ok(near(c, math.cos(math.rad(37))) and near(s, math.sin(math.rad(37))), "37 by its cosine")
end

print(`turning: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
