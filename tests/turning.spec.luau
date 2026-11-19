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

-- How far a turned footprint reaches (S5-03j2b2b): a 4 by 2 crate square on reaches 2 and 1;
-- a quarter round, 1 and 2; askew, its corners reach farther both ways, as Brix's judge sees it.
do
	local x, y = Turning.reach(4, 2, 0)
	ok(x == 2 and y == 1, "square on: half its width and depth")
	x, y = Turning.reach(4, 2, 90)
	ok(x == 1 and y == 2, "a quarter round: swapped, exactly")
	x, y = Turning.reach(4, 2, 270)
	ok(x == 1 and y == 2, "three quarters: swapped too")
	x, y = Turning.reach(4, 2, 45)
	local h = math.sqrt(0.5) * 3
	ok(near(x, h) and near(y, h), "45 degrees: both reach (4 + 2) times cos 45, halved")
	x, y = Turning.reach(4, 2, -30)
	local c, s = math.cos(math.rad(30)), math.sin(math.rad(30))
	ok(near(x, (4 * c + 2 * s) / 2) and near(y, (4 * s + 2 * c) / 2), "a turn back is as wide")
end

-- A twist as the face sees it: from its own side as the screen shows it; from behind (the
-- ceiling seen from above) the other way round.
do
	ok(Turning.seen(QUARTER, -0.8) == QUARTER, "the floor from above: as twisted")
	ok(Turning.seen(QUARTER, 0.8) == -QUARTER, "the ceiling from above: the other way")
	ok(Turning.seen(QUARTER, 0) == QUARTER, "edge on: as twisted")
	-- a quarter's twist clockwise on the screen turns a floor thing clockwise from above (down),
	-- and a ceiling thing seen from above clockwise too, which from below is up
	ok(Turning.twisted(90, Turning.seen(QUARTER, -1), false) == 0, "floor: clockwise is down")
	ok(Turning.twisted(90, Turning.seen(QUARTER, 1), false) == 180, "ceiling: clockwise is up")
end

-- Clicks: one each time the turn crosses into a new notch (a quarter on the grid, Free's soft
-- tick every 15 degrees), counted the same either side of a whole turn.
do
	ok(Turning.notch(0, 90) == 0 and Turning.notch(90, 90) == 1, "quarters count up")
	ok(Turning.notch(270, 90) == 3 and Turning.notch(360, 90) == 0, "a whole turn is notch 0")
	ok(Turning.notch(14, 15) == 0 and Turning.notch(15, 15) == 1, "15 is the next free notch")
	ok(Turning.notch(359, 15) == 23 and Turning.notch(-1, 15) == 23, "just under a whole turn")
	ok(Turning.notch(89.9999999, 90) == 1, "a hair under a quarter (a float) counts as on it")
	ok(Turning.notch(44, Turning.FreeTick) ~= Turning.notch(46, Turning.FreeTick), "45 ticks")
	ok(Turning.notch(31, Turning.FreeTick) == Turning.notch(44, Turning.FreeTick), "31 to 44: none")
end

print(`turning: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
