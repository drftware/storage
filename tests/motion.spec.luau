--!strict
-- lune run tests/motion.spec
local Motion = require("../src/shared/StorageUnit/Motion")

local FULL, PEEK = 7.65, 1.15
local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number, what: string, tol: number?)
	ok(math.abs(a - b) <= (tol or 1e-6), string.format("%s (%.5f vs %.5f)", what, a, b))
end

-- the GDD's door table, full strokes
near(Motion.duration("Peek", 0, PEEK, FULL), 1.0, "peek takes 1 s")
near(Motion.duration("Open", 0, FULL, FULL), 2.0, "open takes 2 s")
near(Motion.duration("LiftInside", 0, FULL, FULL), 6.0, "lift from inside takes 6 s")
near(Motion.duration("Close", FULL, 0, FULL), 1.6, "close takes 1.6 s")
local slam = Motion.duration("Slam", FULL, 0, FULL)
ok(slam < 0.6, "slam is near-instant")
near(
	Motion.duration("Open", PEEK, FULL, FULL),
	2.0 * (FULL - PEEK) / FULL,
	"open from a peek is shorter"
)
near(Motion.duration("Open", FULL, FULL, FULL), 0, "open when open is nothing")

-- endpoints, range and monotonic strokes
for _, kind in { "Peek", "Open", "Close", "LiftInside" } :: { Motion.Kind } do
	local from = if kind == "Close" then FULL else 0
	local to = Motion.target(kind, { Peek = PEEK, Open = FULL })
	local dur = Motion.duration(kind, from, to, FULL)
	near(Motion.sample(kind, from, to, 0, FULL), from, kind .. " starts at from")
	near(Motion.sample(kind, from, to, dur, FULL), to, kind .. " ends at to")
	near(Motion.sample(kind, from, to, dur + 5, FULL), to, kind .. " holds at to")
	local prev = from
	local mono = true
	for i = 1, 200 do
		local r = Motion.sample(kind, from, to, dur * i / 200, FULL)
		if (to - from) * (r - prev) < -1e-9 then
			mono = false
		end
		prev = r
	end
	ok(mono, kind .. " never reverses")
end

-- slam: lands on the floor at the end of its fall, bounces once, settles
local fall = math.sqrt(2 * FULL / 200)
near(Motion.sample("Slam", FULL, 0, fall, FULL), 0, "slam lands", 1e-4)
local peak = 0
for i = 0, 100 do
	peak = math.max(peak, Motion.sample("Slam", FULL, 0, fall + 0.26 * i / 100, FULL))
end
ok(peak > 0.05 and peak <= 0.32, string.format("slam bounces a little (%.3f)", peak))
near(Motion.sample("Slam", FULL, 0, slam, FULL), 0, "slam settles")

-- speed: the curve's slope, zero outside the motion
ok(Motion.speed("Open", 0, FULL, -0.1, FULL) == 0, "no speed before a motion starts")
ok(Motion.speed("Open", 0, FULL, 2.0, FULL) == 0, "no speed once it ends")
local mid = Motion.speed("Open", 0, FULL, 1.0, FULL)
ok(mid > FULL / 2 and mid > Motion.speed("Open", 0, FULL, 0.2, FULL), "an open is fastest mid-way")
ok(
	Motion.speed("Peek", 0, PEEK, 0.05, PEEK) > Motion.speed("Peek", 0, PEEK, 0.8, FULL),
	"a peek starts quick and slows"
)

-- strikes: when the door hits something
local function strikes(kind, from, to)
	return Motion.strikes(kind, from, to, FULL)
end
local s1 = strikes("Slam", FULL, 0)
local fallFull = math.sqrt(2 * FULL / 200)
ok(#s1 == 2 and s1[1].what == "Floor" and s1[2].what == "Bounce", "a slam lands, then bounces")
near(s1[1].at, fallFull, "a slam lands when its fall ends")
near(s1[2].at, fallFull + 0.26, "its bounce lands when the bounce ends")
near(s1[1].strength, 1, "a slam from open lands at full strength")
near(
	Motion.sample("Slam", FULL, 0, s1[1].at, FULL),
	0,
	"the floor strike is when it reaches the floor",
	1e-3
)
local s2 = strikes("Slam", PEEK, 0)
near(s2[1].strength, math.sqrt(PEEK / FULL), "a slam from a peek lands softer")
local s3 = strikes("Close", FULL, 0)
ok(#s3 == 1 and s3[1].what == "Floor", "a close settles on the floor")
near(s3[1].at, 1.6, "when the close ends")
local s4 = strikes("Open", 0, FULL)
ok(#s4 == 1 and s4[1].what == "Top", "an open meets the stop bolts")
near(s4[1].at, 2.0, "when the open ends")
ok(#strikes("Open", PEEK, FULL) == 1, "an open from a peek meets them too")
near(strikes("LiftInside", 0, FULL)[1].at, 6.0, "a lift from inside meets them after 6 s")
ok(#strikes("Peek", 0, PEEK) == 0, "a peek hits nothing")
ok(#strikes("Peek", FULL, PEEK) == 0, "dropping to a peek hits nothing")
ok(#strikes("Close", 0, 0) == 0, "closing a shut door hits nothing")
ok(#strikes("Slam", 0, 0) == 0, "slamming a shut door hits nothing")

-- the replicated attribute round-trips
local k, a, b, s = Motion.decode(Motion.encode("Slam", 7.65, 0, 12345.6789))
ok(k == "Slam", "decode kind")
near(a, 7.65, "decode from", 1e-4)
near(b, 0, "decode to", 1e-4)
near(s, 12345.6789, "decode start", 1e-4)
local k2 = Motion.decode(nil)
ok(k2 == "Close", "missing attribute reads as shut")

-- rattle: a padlocked door jerks a few centimetres against its bolt and ends where it began
local rattle = Motion.duration("Rattle", 0, 0, FULL)
ok(rattle > 0.4 and rattle < 1, "a rattle is a moment")
local high, low = 0, math.huge
for i = 0, 100 do
	local r = Motion.sample("Rattle", 0, 0, rattle * i / 100, FULL)
	high, low = math.max(high, r), math.min(low, r)
end
ok(high > 0.05 and high < 0.2 and low >= 0, string.format("a rattle lifts a little (%.3f)", high))
near(Motion.sample("Rattle", 0, 0, rattle, FULL), 0, "and drops back")
ok(#Motion.strikes("Rattle", 0, 0, FULL) == 0, "a rattle strikes nothing")
near(Motion.target("Rattle", { Peek = PEEK, Open = FULL }), 0, "a rattle stays shut")

print(string.format("motion: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("motion spec failed")
end
