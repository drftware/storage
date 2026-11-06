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

-- the replicated attribute round-trips
local k, a, b, s = Motion.decode(Motion.encode("Slam", 7.65, 0, 12345.6789))
ok(k == "Slam", "decode kind")
near(a, 7.65, "decode from", 1e-4)
near(b, 0, "decode to", 1e-4)
near(s, 12345.6789, "decode start", 1e-4)
local k2 = Motion.decode(nil)
ok(k2 == "Close", "missing attribute reads as shut")

print(string.format("motion: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("motion spec failed")
end
