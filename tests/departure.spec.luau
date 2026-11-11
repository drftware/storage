--!strict
-- lune run tests/departure.spec
-- The gate's clock (L-05b2): it starts once the gate has slammed open and runs 30 s; the gate
-- starts to shut at zero and the car leaves as it hits its post; the clock shows 30 down to 0;
-- the lamp is steady until the warning, then blinks ever faster and is steady again at zero; the
-- heartbeat swells and quickens through the warning and fades as the gate shuts; the bell rings
-- each of the last five seconds; the car's box holds a player inside the gate and not one in the
-- lobby, however the elevator is turned; and the leaving's value round-trips.
local Brix = require("../vendor/brix/src")
local Departure = require("../src/shared/Elevator/Departure")
local Gate = require("../src/shared/Elevator/Gate")
local Specs = require("../src/shared/Elevator/Specs")

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
local function near(a: number, b: number, what: string, tol: number?)
	ok(math.abs(a - b) <= (tol or 1e-6), `{what}: {a} vs {b}`)
end

-- The timeline from a right code at t = 100 with the gate shut.
local departs = Departure.departs(100, 1)
near(
	Departure.starts(departs),
	100 + Gate.Delay + Gate.OpenSeconds,
	"the clock starts as the gate slams open"
)
near(departs - Departure.starts(departs), 30, "it runs 30 s")
near(Departure.leaves(departs) - departs, Gate.ShutSeconds, "the car leaves as the shut gate hits")
-- A gate caught half open opens faster, so the clock starts sooner.
ok(Departure.departs(100, 0.5) < departs, "a half-open gate starts its clock sooner")

-- Phases, second by second.
ok(Departure.phase(31) == "Folding", "before the clock: the gate's folding")
ok(Departure.phase(30) == "Counting", "at 30: counting")
ok(Departure.phase(10.01) == "Counting", "just over 10: still counting")
ok(Departure.phase(10) == "Warning", "at 10: the warning")
ok(Departure.phase(5) == "Final", "at 5: the final seconds")
ok(Departure.phase(0.01) == "Final", "just before zero: final")
ok(Departure.phase(0) == "Shutting", "at zero: shutting")
ok(Departure.phase(-Gate.ShutSeconds + 0.01) == "Shutting", "until it hits: shutting")
ok(Departure.phase(-Gate.ShutSeconds) == "Gone", "once it hits: gone")

-- The clock's face.
ok(Departure.shown(30) == 30, "30 at its start")
ok(Departure.shown(29.99) == 30, "30 through its first second")
ok(Departure.shown(29) == 29, "29 a second in")
ok(Departure.shown(0.01) == 1, "1 in its last second")
ok(Departure.shown(0) == 0, "0 at zero")
ok(Departure.shown(-3) == 0, "0 after")
ok(Departure.shown(40) == 30, "never more than 30")
ok(Departure.text(30) == "30", "two digits")
ok(Departure.text(9) == " 9", "a lone digit right-aligned, no leading zero")
ok(Departure.text(0) == " 0", "zero alone")

-- The lamp: steady, then blinking faster, then steady.
ok(Departure.lamp(25) == 1, "steady before the warning")
ok(Departure.lamp(10) == 1, "lit as the warning starts")
ok(Departure.lamp(0) == 1, "steady once the gate shuts")
ok(Departure.lamp(-1) == 1, "steady after")
-- Walk the warning in small steps, noting each lit and dim stretch between changes.
do
	local step = 1 / 600
	local runs: { { lit: boolean, length: number, at: number } } = {}
	local wasLit, length = true, 0
	local s = 0
	while s < Departure.Warning do
		local v = Departure.lamp(Departure.Warning - s)
		ok(v == 1 or v == Departure.BlinkLow, "the lamp is lit or dim, nothing between")
		local isLit = v == 1
		if isLit ~= wasLit then
			table.insert(runs, { lit = wasLit, length = length, at = s })
			wasLit, length = isLit, 0
		end
		length += step
		s += step
	end
	-- whole blinks: a dim start to the next dim start
	local starts: { number } = {}
	for _, r in runs do
		if r.lit then
			table.insert(starts, r.at)
		end
	end
	ok(#starts >= 20, `it blinks 20 or more times in the warning (got {#starts})`)
	near(
		starts[1],
		Departure.SlowBlink * Departure.BlinkOn,
		"the first blink dims after its lit stretch",
		0.05
	)
	for i = 3, #starts do
		local this, last = starts[i] - starts[i - 1], starts[i - 1] - starts[i - 2]
		ok(this <= last + 2 * step, `blink {i} is no longer than the one before ({this} vs {last})`)
	end
	local lastBlink = starts[#starts] - starts[#starts - 1]
	ok(lastBlink < 0.25, `the last blinks are quick (got {lastBlink})`)
	-- every lit stretch between two dims lasts a frame or more at 60 fps, so none is lost
	for i = 2, #runs do
		if runs[i].lit then
			ok(runs[i].length >= 1 / 60, `lit stretch {i} lasts a frame or more ({runs[i].length})`)
		end
	end
end

-- The heartbeat.
do
	local v, pace = Departure.heart(20)
	ok(v == nil and pace == 1, "silent before the warning")
	v, pace = Departure.heart(10)
	near(v :: number, Departure.HeartQuiet, "quiet as the warning starts")
	near(pace, 1, "at its own pace")
	local v5, p5 = Departure.heart(5)
	local v1, p1 = Departure.heart(1)
	ok((v5 :: number) < (v1 :: number) and p5 < p1, "louder and faster toward zero")
	local v0, p0 = Departure.heart(0)
	near(v0 :: number, Departure.HeartLoud, "loudest at zero")
	near(p0, Departure.HeartFast, "fastest at zero")
	local vf = Departure.heart(-Departure.HeartFade / 2)
	ok(vf ~= nil and (vf :: number) < Departure.HeartLoud, "fading as the gate shuts")
	ok(Departure.heart(-Departure.HeartFade) == nil, "gone once faded")
	ok(Departure.HeartFade <= Gate.ShutSeconds + 0.2, "faded about as the gate hits")
end

-- The bell: once each of the last five seconds.
do
	local bells = Departure.bells()
	ok(#bells == Departure.Final, "five bells")
	ok(bells[1] == 5 and bells[#bells] == 1, "from 5 down to 1")
	for i, s in bells do
		ok(Departure.shown(s - 0.001) == s, `bell {i} rings as the clock shows {s}`)
	end
	ok(Departure.bellPitch(5) == 1, "the first bell at its own pitch")
	ok(Departure.bellPitch(1) > Departure.bellPitch(2), "each bell higher than the last")
	ok(Departure.Bell.Stop - Departure.Bell.Start <= 1, "a bell ends before the next rings")
end

-- The car's box: inside the gate is aboard, the lobby isn't, at every turn.
do
	local FREE = Brix.Pathing.free()
	local _, size = Departure.car()
	near(size[1], Specs.Car.Width, "wall to wall")
	near(size[3], Specs.Car.Back - Specs.Gate.Plane, "the gate's pickets to the back wall")
	for _, degrees in { 0, 90, -90, 180, 37 } do
		local turn = math.rad(degrees)
		local ox, oy, oz = 40, 10, -600
		local zone = Brix.Zone.box(Departure.carBox(FREE, ox, oy, oz, turn))
		-- a point in the elevator's frame (x across, z into the car), in the world
		local function world(x: number, y: number, z: number): vector
			-- the frame's X axis is (cos, 0, -sin), its Z axis (sin, 0, cos)
			return vector.create(
				ox + x * math.cos(turn) + z * math.sin(turn),
				oy + y,
				oz - x * math.sin(turn) + z * math.cos(turn)
			)
		end
		ok(zone:contains(world(0, 3, 6)), `{degrees}°: the car's middle is aboard`)
		ok(zone:contains(world(5.5, 3, 11.5)), `{degrees}°: a back corner is aboard`)
		ok(zone:contains(world(-5.5, 3, 1.2)), `{degrees}°: just inside the gate is aboard`)
		ok(not zone:contains(world(0, 3, 0.5)), `{degrees}°: on the gate's lobby side isn't`)
		ok(not zone:contains(world(0, 3, -4)), `{degrees}°: the lobby isn't`)
		ok(
			not zone:contains(world(7, 3, 6)),
			`{degrees}°: beside the car (through its wall) isn't`
		)
		ok(not zone:contains(world(0, 3, 13)), `{degrees}°: behind its back wall isn't`)
	end
end

-- The car leaving: its lamp draws away for those left behind; the ride's fade for those aboard.
do
	ok(Departure.away(0) == 1, "the lamp's lit as the car leaves")
	ok(Departure.away(Departure.LampAway / 2) > 0.5, "it holds at first, as the car starts")
	ok(Departure.away(Departure.LampAway) == 0, "then it's gone")
	ok(Departure.away(99) == 0, "and stays gone")
	local was = 1
	for i = 1, 40 do
		local v = Departure.away(Departure.LampAway * i / 40)
		ok(v <= was, "it only ever dims")
		was = v
	end
end

-- The leaving's value.
do
	local at, ids = Departure.decodeAboard(Departure.encodeAboard(1234.5678, { 11785587236, 42 }))
	near(at :: number, 1234.568, "when, to the millisecond", 1e-3)
	ok(#ids == 2 and ids[1] == 11785587236 and ids[2] == 42, "who, every id whole")
	local at2, none = Departure.decodeAboard(Departure.encodeAboard(5, {}))
	ok(at2 == 5 and #none == 0, "nobody aboard still says when")
	local at3, ids3 = Departure.decodeAboard(nil)
	ok(at3 == nil and #ids3 == 0, "no value: no leaving")
	local at4 = Departure.decodeAboard("junk|1,2")
	ok(at4 == nil, "a broken value: no leaving")
end

print(`departure: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
