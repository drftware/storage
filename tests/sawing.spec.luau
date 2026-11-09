--!strict
-- lune run tests/sawing.spec
-- Sawing a crawl hole (L-12b2): who may start, how long it takes, and the bright line round the
-- cut, every step of the way.
local Sawing = require("../src/shared/StorageUnit/CrawlHole/Sawing")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- who may start
for _, holding: Sawing.Holding in { "Hand", "Slot", "None" } :: { Sawing.Holding } do
	for _, holed in { false, true } do
		for _, busy in { false, true } do
			local v = Sawing.decide(holding, holed, busy)
			local where = `{holding} holed={holed} busy={busy}`
			ok(v.ok == (holding == "Hand" and not holed and not busy), `{where}: allowed or not`)
			if holed or busy then
				ok(v.refusal == nil, `{where}: refused silently, its button is going`)
			elseif holding == "Slot" then
				ok(v.refusal == "Hold the saw", `{where}: says hold it`)
			elseif holding == "None" then
				ok(v.refusal == "Need a saw", `{where}: says find one`)
			end
		end
	end
end

-- how long: a real hold cuts, a faked or short one doesn't
ok(
	Sawing.Seconds >= 2 and Sawing.Seconds <= 6,
	"a hold long enough to be heard, short enough to use"
)
ok(Sawing.finished(Sawing.Seconds), "a full hold cuts")
ok(Sawing.finished(Sawing.Seconds - Sawing.HoldSlack + 1e-3), "a hold a little early cuts")
ok(not Sawing.finished(Sawing.Seconds - Sawing.HoldSlack - 0.05), "a hold well short doesn't")
ok(not Sawing.finished(0), "a faked press at once doesn't")
ok(Sawing.HoldSlack < Sawing.Seconds / 4, "the slack is a network's, not a shortcut")
ok(Sawing.progress(-1) == 0 and Sawing.progress(0) == 0, "no cut before the hold")
ok(Sawing.progress(Sawing.Seconds * 2) == 1, "all the way round, then no further")
ok(near(Sawing.progress(Sawing.Seconds / 2), 0.5), "halfway at half the hold")

-- loud: the floor hears it, further than any door
ok(Sawing.Heard >= 150, "the saw is heard floor-wide")
ok(Sawing.Sounds.Whine.reach == Sawing.Heard, "players hear the motor as far as keepers do")
ok(Sawing.ClangHeard < Sawing.Heard, "the clang carries less than the motor")
for name, s in Sawing.Sounds :: { [string]: Sawing.Sound } do
	if s.loopFrom and s.loopTo then
		ok(s.loopTo > s.loopFrom and s.loopFrom >= s.from, `{name}: its loop runs forward`)
	else
		ok((s.length or 0) > 0, `{name}: a one-shot with a length`)
	end
end

-- the line round the cut: one blade, moving at one speed, never back
local hole: Sawing.Hole = { from = 3.75, to = 6.75, bottom = 0.3, top = 2.9 }
local w, h = hole.to - hole.from, hole.top - hole.bottom
local perimeter = 2 * (w + h)
local drawn = { 0, 0, 0, 0 }
local lastCut = -1
local lastAlong, lastUp = 0, 0
local steps = 400
for i = 0, steps do
	local p = i / steps
	local along, up = Sawing.line(p, hole, drawn)
	local where = `at {string.format("%.3f", p)}`
	local cut = h * drawn[1] + w * drawn[2] + h * drawn[3] + w * drawn[4]
	ok(near(cut, p * perimeter), `{where}: as much line as hold`)
	ok(cut >= lastCut - 1e-9, `{where}: the line only grows`)
	lastCut = cut
	-- edges in order: one isn't begun until the one before is through
	for e = 2, 4 do
		ok(drawn[e] == 0 or near(drawn[e - 1], 1), `{where}: edge {e} after edge {e - 1}`)
	end
	-- the blade on the hole's outline, within the hole's box
	local onSide = near(along, hole.from) or near(along, hole.to)
	local onEnd = near(up, hole.bottom) or near(up, hole.top)
	ok(onSide or onEnd, `{where}: the blade on the outline`)
	ok(
		along >= hole.from - 1e-9
			and along <= hole.to + 1e-9
			and up >= hole.bottom - 1e-9
			and up <= hole.top + 1e-9,
		`{where}: the blade within the hole`
	)
	if i > 0 then
		local step = math.abs(along - lastAlong) + math.abs(up - lastUp)
		ok(near(step, perimeter / steps), `{where}: the blade moves at one speed`)
	end
	lastAlong, lastUp = along, up
end
-- where it starts and ends: the top front corner, all the way round
local a0, u0 = Sawing.line(0, hole, drawn)
ok(near(a0, hole.from) and near(u0, hole.top), "the cut starts at the top front corner")
local a1, u1 = Sawing.line(1, hole, drawn)
ok(near(a1, hole.from) and near(u1, hole.top), "and ends back there")
ok(
	near(drawn[1], 1) and near(drawn[2], 1) and near(drawn[3], 1) and near(drawn[4], 1),
	"every edge cut through"
)

-- a unit's top (L-13b2d2b): lying on the hole is refused out loud, after the saw's own refusals
ok(Sawing.decide("Hand", false, false, true).refusal == "Move off it", "lying on it: move off")
ok(not Sawing.decide("Hand", false, false, true).ok, "lying on it: no cut")
ok(Sawing.decide("Slot", false, false, true).refusal == "Hold the saw", "the saw comes first")
ok(Sawing.decide("Hand", true, false, true).refusal == nil, "a holed top: silent")
ok(Sawing.decide("Hand", false, false, false).ok, "lying beside it: cuts")

-- the line on a flat rectangle: the top's hole (the kit's numbers, D-061), laid in its cut frame
-- (X up, Y across the other way, Z back), mapped back to across (x = -up) and back (z = along)
local L, R, F, B = -1.4, 1.4, -0.5, 1.55
local flat = Sawing.flat(L, R, F, B)
ok(flat.to - flat.from > 0 and flat.top - flat.bottom > 0, "the flat hole has a size")
ok(near(flat.top - flat.bottom, R - L) and near(flat.to - flat.from, B - F), "and the hole's size")
local function onEdge(x: number, z: number): boolean
	local inX, inZ = x >= L - 1e-6 and x <= R + 1e-6, z >= F - 1e-6 and z <= B + 1e-6
	return (inX and (near(z, F) or near(z, B))) or (inZ and (near(x, L) or near(x, R)))
end
local flatPerimeter = 2 * ((R - L) + (B - F))
local lastX, lastZ = 0, 0
local firstLeg = (R - L) / flatPerimeter -- the share of the hold the front edge takes
for i = 0, steps do
	local p = i / steps
	local along, up = Sawing.line(p, flat, drawn)
	local x, z = -up, along
	local where = `top at {p}`
	ok(onEdge(x, z), `{where}: the blade is on the hole's edge`)
	if p <= firstLeg then
		ok(near(z, F), `{where}: the front edge first, the one nearest the hall`)
		ok(near(x, L + (R - L) * p / firstLeg), `{where}: left to right along it`)
	end
	if i > 0 then
		local step = math.abs(x - lastX) + math.abs(z - lastZ)
		ok(near(step, flatPerimeter / steps), `{where}: the blade moves at one speed`)
	end
	lastX, lastZ = x, z
end
local fa, fu = Sawing.line(0, flat, drawn)
ok(near(-fu, L) and near(fa, F), "a top's cut starts at the front edge's left end")
fa, fu = Sawing.line(1, flat, drawn)
ok(near(-fu, L) and near(fa, F), "and ends back there")

-- lying on the hole: your middle over it, or within half a body of it
ok(Sawing.onHole(0, 0.5, L, R, F, B), "your middle over the hole: on it")
ok(Sawing.onHole(R + Sawing.OffHole - 0.01, 0.5, L, R, F, B), "just past its side: still on it")
ok(not Sawing.onHole(R + Sawing.OffHole + 0.01, 0.5, L, R, F, B), "beside it: off")
ok(not Sawing.onHole(0, F - Sawing.OffHole - 0.01, L, R, F, B), "in front of it: off")
ok(not Sawing.onHole(0, B + Sawing.OffHole + 0.01, L, R, F, B), "behind it: off")
ok(Sawing.OffHole > 0 and Sawing.OffHole < 1.5, "half a lying body, not a whole one")
ok(
	Sawing.DropHeard >= Sawing.ClangHeard,
	"a panel dropped ten studs is heard further than one tipped"
)

if failures > 0 then
	print(`sawing: {failures} of {checks} checks failed`)
	error("sawing spec failed")
end
print(`sawing: {checks} checks passed`)
