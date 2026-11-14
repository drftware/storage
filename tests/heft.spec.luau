--!strict
-- lune run tests/heft.spec
-- A find's weight in your hand (S1-05): heavier comes up slower; a tool keeps its springy
-- overshoot, a find has none; its weight lands with a dip, deeper the heavier, then a smaller
-- rebound, settled within the bounce's time; a tool doesn't sag; heavier sways more.
local Catalog = require("../src/shared/Tools/Catalog")
local Heft = require("../src/shared/Tools/Heft")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- the rise: a tool's time for no heft, longer the heavier, under twice as long at the most
ok(Heft.rise(0.3, 0) == 0.3, "a tool comes up in its own time")
ok(Heft.rise(0.3, 1) > Heft.rise(0.3, 0.4), "heavier comes up slower")
ok(Heft.rise(0.3, 1) < 0.6, "even the heaviest under twice a tool's time")

-- the ease: a tool overshoots, a find never does; both start at 0 and end at 1
local toolPeak, findPeak = 0, 0
for i = 0, 100 do
	local t = i / 100
	toolPeak = math.max(toolPeak, Heft.ease(t, 0))
	findPeak = math.max(findPeak, Heft.ease(t, 0.6))
end
ok(toolPeak > 1.05, "a tool springs past its place")
ok(findPeak <= 1 + 1e-9, "a find doesn't")
ok(math.abs(Heft.ease(0, 0.6)) < 1e-9 and math.abs(Heft.ease(1, 0.6) - 1) < 1e-9, "0 to 1")

-- the sag: none for a tool, none before it lands or once settled
ok(Heft.sag(0.1, 0) == 0, "a tool doesn't sag")
ok(Heft.sag(0, 1) == 0 and Heft.sag(-1, 1) == 0, "nothing before it lands")
ok(Heft.sag(Heft.Settled, 1) == 0 and Heft.sag(5, 1) == 0, "nothing once settled")
-- the heaviest dips to 1 then rebounds less than half as far, and is near still by the end
local deepest, rebound, lateMax = 0, 0, 0
for i = 1, 699 do
	local s = Heft.sag(i / 1000, 1)
	deepest = math.max(deepest, s)
	rebound = math.min(rebound, s)
	if i > 500 then
		lateMax = math.max(lateMax, math.abs(s))
	end
end
ok(math.abs(deepest - 1) < 0.01, `the heaviest's dip bottoms at 1 ({deepest})`)
ok(rebound < 0 and -rebound < 0.5, `a smaller rebound ({rebound})`)
ok(lateMax < 0.1, `near still before it's settled ({lateMax})`)
ok(Heft.sag(0.09, 0.3) < Heft.sag(0.09, 1), "a lighter find dips less")
-- in studs: the heaviest's dip is felt but small next to the thing itself
ok(Heft.Depth > 0.05 and Heft.Depth < 0.4, "the dip is a few inches")

-- the sway
ok(Heft.swayScale(0) == 1, "a tool sways as the torch does")
ok(Heft.swayScale(1) > Heft.swayScale(0.2), "heavier sways more")

-- the finds' hefts read in order: the TV heaviest, the teddy lightest
local tv, teddy, box = Catalog.Television.heft, Catalog.Teddy.heft, Catalog.Boombox.heft
ok(tv ~= nil and teddy ~= nil and box ~= nil, "each find has a heft")
if tv and teddy and box then
	ok(tv > box and box > teddy, "TV heaviest, then the boombox, the teddy lightest")
end

print(`heft: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
