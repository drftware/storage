--!strict
-- lune run tests/infrared.spec
-- The RC car's infrared (F-G1b3c2e, Finds/Infrared): in a lit pool the view is in colour, and
-- once in colour it holds a little past the pool's edge, so it never chatters there; a light on
-- another floor doesn't count; the flicker shows the new look first and ends on it; the eyes
-- shine near and facing, fade toward their reach, and never turned away.
local Infrared = require("../src/shared/Finds/Infrared")
local MotionLight = require("../src/shared/MotionLight")

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

-- the pool's edge
do
	local pool = MotionLight.PoolReach
	ok(Infrared.reach(true) == pool, "dark, the car must come into the pool itself")
	ok(Infrared.reach(false) > pool, "in colour, it holds a little past the edge")
	local edge = pool + Infrared.Margin / 2
	ok(
		not Infrared.near(0, 0, 0, edge, 0.5, 0, Infrared.reach(true)),
		"just past the edge, a dark view stays dark"
	)
	ok(
		Infrared.near(0, 0, 0, edge, 0.5, 0, Infrared.reach(false)),
		"just past the edge, a view in colour stays in colour"
	)
	ok(
		not Infrared.near(0, 0, 0, pool + Infrared.Margin + 0.5, 0.5, 0, Infrared.reach(false)),
		"well past it, colour gives way"
	)
	ok(Infrared.near(0, 0, 0, 3, 0.5, 4, Infrared.reach(true)), "under the light: lit")
	ok(
		not Infrared.near(0, 0, 0, 0, MotionLight.WatchHeight + 2, 0, 50),
		"a light on the floor below doesn't light the car"
	)
	ok(not Infrared.near(0, 0, 0, 0, -3, 0, 50), "nor one on the floor above")
	ok(Infrared.Building > Infrared.reach(false), "the halls reach past a light's pool")
end

-- the flicker
do
	ok(Infrared.shown(0), "the click shows the new look at once")
	local first = Infrared.Flicker[1]
	ok(not Infrared.shown(first + 0.001), "then the old look")
	local all = 0
	for _, beat in Infrared.Flicker do
		all += beat
	end
	ok(Infrared.shown(all + 0.001), "and the new look holds")
	ok(Infrared.shown(10), "long after, still the new look")
	ok(all < 0.35, "the flicker is quick")
	ok(#Infrared.Flicker % 2 == 0, "it ends on the old look, so the new one is what holds")
end

-- the eyes
do
	ok(Infrared.shine(10, 1) == 1, "near and facing: full shine")
	ok(Infrared.shine(10, -1) == 0, "turned away: none")
	ok(Infrared.shine(10, Infrared.EyeFacing - 0.01) == 0, "side on: none")
	ok(Infrared.shine(Infrared.EyeReach + 1, 1) == 0, "past their reach: none")
	local far = Infrared.shine(Infrared.EyeReach - Infrared.EyeFade / 2, 1)
	ok(far > 0 and far < 1, "toward their reach they fade")
	ok(Infrared.EyeReach > Infrared.LampRange, "they shine a little past the lamp")
	for name, spot in Infrared.Eyes do
		ok(spot.ahead > 0 and spot.apart > 0, `{name}'s eyes are on its face`)
	end
end

if failures > 0 then
	error(`infrared: {failures} of {checks} checks failed`)
end
print(`infrared: {checks} checks passed`)
