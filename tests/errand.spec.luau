--!strict
-- lune run tests/errand.spec
-- The Mannequin cuts the power (S2-02c, GDD "The Mannequin cuts the power"): how keen it is goes
-- up with the floor, capped, and is nothing while the box is thrown or the power just came back.
-- Where it stands to throw it is in the hall in front of the box on every spot. Offered the box at
-- a sure chance, a Mannequin picking where to wander heads there, walks the halls at its walk,
-- stands a beat facing the box with its hand on the grip, throws it exactly once, then lingers
-- holding the lever down (a light or a sound in the beat holds it or calls it off); held by a
-- light it doesn't move or throw; an offer withdrawn calls the walk off; a sound calls it off,
-- but on its way it hears a third as far (S2-07a2), so a far sound leaves it walking and throwing
-- while the alarm still calls it; a keeper that doesn't freeze in light never takes the errand;
-- with no offer it never goes.
-- And a warm errand allocates nothing.
local Brix = require("../vendor/brix/src")
local Breaker = require("../src/shared/Breaker")
local Floor = require("../src/shared/Floor")
local Keeper = require("../src/shared/Keeper")
local KeeperMap = require("../src/shared/KeeperMap")
local KeeperRows = require("../src/shared/KeeperRows")

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

local RUN = 16
local DT = 1 / 60
local MANNEQUIN = KeeperRows.Mannequin

local function flat(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end
local function inHall(map: KeeperMap.Map, p: vector): boolean
	local e = 1e-3
	for i = 1, #map.minX do
		if
			map.unit[i] == 0
			and p.x >= map.minX[i] - e
			and p.x <= map.maxX[i] + e
			and p.z >= map.minZ[i] - e
			and p.z <= map.maxZ[i] + e
		then
			return true
		end
	end
	return false
end

-- How keen it is
ok(Breaker.errand(1, false, 1e6) == 0, "thrown, no Mannequin heads for it")
ok(Breaker.errand(5, true, Breaker.ErrandGap - 0.01) == 0, "not straight after the power comes on")
ok(Breaker.errand(1, true, Breaker.ErrandGap) == Breaker.ErrandChance, "floor 1's chance")
local last = 0
for number = 1, 200 do
	local c = Breaker.errand(number, true, 1e6)
	ok(c > 0 and c <= Breaker.ErrandMost and c <= 1, `floor {number}: a chance, capped`)
	ok(c >= last, `floor {number}: never less keen than the floor below`)
	last = c
end
ok(Breaker.errand(10, true, 1e6) > Breaker.errand(1, true, 1e6), "keener higher up")
-- before the floor's first cut
ok(Breaker.errand(1, true, 1e6, false) == Breaker.ErrandFirst, "floor 1's first cut comes soon")
ok(Breaker.errand(1, true, 1e6, true) == Breaker.ErrandChance, "after it, floor 1's own chance")
ok(Breaker.errand(1, false, 1e6, false) == 0, "never while thrown, first cut or not")
ok(
	Breaker.errand(1, true, Breaker.ErrandGap - 0.01, false) == 0,
	"a floor still gets its lit start before the first cut"
)
ok(Breaker.ErrandFirst > Breaker.ErrandChance and Breaker.ErrandFirst <= 1, "the first is keener")
for number = 1, 40 do
	ok(
		Breaker.errand(number, true, 1e6, false) >= Breaker.errand(number, true, 1e6, true),
		`floor {number}: never less keen before the first cut`
	)
end

local floors, walks, throws, farOff = 0, 0, 0, 0
local function checkFloor(seed: number, number: number)
	local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local where = `floor {number} seed {seed}`
	local map = KeeperMap.build(f)
	local walker = KeeperMap.pathing(map, MANNEQUIN.abilities)
	local spots = Breaker.spots(f)
	floors += 1
	ok(#spots > 0, `{where}: a spot for the box`)
	-- every spot's stand is in the hall, in front of the box, and reachable from the lobby
	for _, spot in spots do
		local fx, fz = Floor.dir(spot.facing)
		local at = Breaker.stand(spot.x, spot.z, fx, fz)
		ok(inHall(map, at), `{where}: the stand at {spot.x},{spot.z} is in the hall`)
		ok(
			math.abs(
				vector.dot(at - vector.create(spot.x, 0, spot.z), vector.create(fx, 0, fz))
					- Breaker.ErrandStand
			) < 1e-3,
			`{where}: it stands out in front of the box`
		)
		ok(walker:length(vector.zero, at) < math.huge, `{where}: it can walk to the box`)
	end

	local spot = spots[1 + (seed % #spots)]
	local fx, fz = Floor.dir(spot.facing)
	local at = Breaker.stand(spot.x, spot.z, fx, fz)
	local box = vector.create(spot.x, 0, spot.z)
	local function fresh(row: KeeperRows.Row?): Keeper.Keeper
		local k = Keeper.new(
			row or MANNEQUIN,
			map,
			Brix.Random.new({ seed = seed }),
			vector.zero,
			vector.create(1, 0, 0),
			true
		)
		-- standing in the lobby, done looking: its next step picks where to wander
		k.state, k.wait, k.waited = "Waiting", 0, 0
		return k
	end

	-- offered at a sure chance: it heads for the box, walks the halls, throws it once, lingers
	local k = fresh()
	Keeper.offer(k, at, box, 1, Breaker.Grip)
	Keeper.step(k, DT, RUN)
	ok(k.state == "Roaming" and k.errand and k.goal == at, `{where}: it heads for the box`)
	local pace = Keeper.pace(k, RUN)
	ok(pace > 0 and pace <= MANNEQUIN.speed * RUN + 1e-6, `{where}: at its walk`)
	local thrown, strayed, steps, longest = 0, false, 0, 0
	while k.state == "Roaming" and steps < 60 * 300 do
		local before = k.at
		Keeper.step(k, DT, RUN)
		steps += 1
		longest = math.max(longest, flat(before, k.at))
		if k.threw then
			thrown += 1
		end
		if not inHall(map, k.at) then
			strayed = true
		end
	end
	walks += 1
	ok(not strayed, `{where}: it keeps to the halls on its way`)
	ok(longest <= pace * DT + 1e-3, `{where}: never faster than its walk`)
	ok(thrown == 0, `{where}: it doesn't throw the box as it arrives ({thrown})`)
	ok(flat(k.at, at) < 1e-2, `{where}: it's at the stand`)
	ok(k.state == "Waiting" and k.errand and k.lever == "Reach", `{where}: its hand up on the grip`)
	ok(Keeper.shown(k) == "Reaching", `{where}: screens show it reaching`)
	local toBox = vector.normalize(vector.create(box.x - k.at.x, 0, box.z - k.at.z))
	ok(vector.dot(k.facing, toBox) > 0.99, `{where}: facing the box`)
	-- it stands a beat with its hand on the grip (S2-02d2), then drags the lever down, once
	local beat = 0
	while not k.threw and beat < 60 * 10 do
		Keeper.step(k, DT, RUN)
		beat += 1
	end
	ok(math.abs(beat * DT - Breaker.Grip) <= 2 * DT, `{where}: a beat on the grip ({beat * DT} s)`)
	ok(flat(k.at, at) < 1e-2 and vector.dot(k.facing, toBox) > 0.99, `{where}: where it stood`)
	ok(k.state == "Waiting" and not k.errand, `{where}: it stands there after`)
	ok(k.lever == "Pull" and Keeper.shown(k) == "Pulling", `{where}: holding the lever down`)
	throws += 1
	for _ = 1, 30 do
		Keeper.step(k, DT, RUN)
		ok(not k.threw, `{where}: one throw, not one a step`)
	end
	-- after its linger it wanders off, its hand off the lever
	for _ = 1, 60 * 30 do
		Keeper.step(k, DT, RUN)
		if k.state ~= "Waiting" then
			break
		end
	end
	ok(k.state ~= "Waiting" and Keeper.shown(k) == k.state, `{where}: it lets go and moves on`)

	-- a light on it while its hand is on the grip holds it there, still reaching; let go, it throws
	-- once the rest of the beat is up
	local gripped = fresh()
	Keeper.offer(gripped, at, box, 1, Breaker.Grip)
	for _ = 1, 60 * 300 do
		Keeper.step(gripped, DT, RUN)
		if gripped.lever == "Reach" then
			break
		end
	end
	Keeper.step(gripped, Breaker.Grip / 2, RUN)
	for _ = 1, 600 do
		Keeper.step(gripped, DT, RUN, nil, true)
		ok(not gripped.threw, `{where}: lit on the grip, it doesn't throw`)
	end
	ok(Keeper.shown(gripped) == "Reaching", `{where}: lit, its hand stays up on the grip`)
	local rest = 0
	while not gripped.threw and rest < 600 do
		Keeper.step(gripped, DT, RUN)
		rest += 1
	end
	ok(
		math.abs(rest * DT - Breaker.Grip / 2) <= 2 * DT,
		`{where}: the rest of the beat, then the throw`
	)

	-- a sound while its hand is on the grip calls it off: it goes to look, and never throws
	local startled = fresh()
	Keeper.offer(startled, at, box, 1, Breaker.Grip)
	for _ = 1, 60 * 300 do
		Keeper.step(startled, DT, RUN)
		if startled.lever == "Reach" then
			break
		end
	end
	Keeper.heardAt(startled, startled.at + vector.create(0.5, 0, 0), 50)
	ok(Keeper.shown(startled) == "Going", `{where}: startled off the grip, it goes to look`)
	Keeper.offer(startled, at, box, 0, Breaker.Grip)
	for _ = 1, 60 * 30 do
		Keeper.step(startled, DT, RUN)
		ok(not startled.threw, `{where}: startled off the grip, it never throws`)
	end

	-- the offer withdrawn while its hand is on the grip (the power went off another way)
	local beaten = fresh()
	Keeper.offer(beaten, at, box, 1, Breaker.Grip)
	for _ = 1, 60 * 300 do
		Keeper.step(beaten, DT, RUN)
		if beaten.lever == "Reach" then
			break
		end
	end
	Keeper.offer(beaten, at, box, 0, Breaker.Grip)
	ok(Keeper.shown(beaten) ~= "Reaching", `{where}: withdrawn, its hand comes off the grip`)
	for _ = 1, 60 * 30 do
		Keeper.step(beaten, DT, RUN)
		ok(not beaten.threw, `{where}: withdrawn on the grip, it never throws`)
	end

	-- held by a light, it neither moves nor throws
	local lit = fresh()
	Keeper.offer(lit, at, box, 1, Breaker.Grip)
	Keeper.step(lit, DT, RUN)
	local stood = lit.at
	for _ = 1, 600 do
		Keeper.step(lit, DT, RUN, nil, true)
		ok(not lit.threw, `{where}: lit, it never throws`)
	end
	ok(lit.at == stood and lit.errand, `{where}: lit, it holds where it stands, still bound there`)

	-- the offer withdrawn on its way (the power went off or just came back): it never throws
	local off = fresh()
	Keeper.offer(off, at, box, 1, Breaker.Grip)
	Keeper.step(off, DT, RUN)
	Keeper.offer(off, at, box, 0, Breaker.Grip)
	ok(not off.errand, `{where}: withdrawn, the walk is off`)
	for _ = 1, 60 * 120 do
		Keeper.step(off, DT, RUN)
		ok(not off.threw, `{where}: withdrawn, it never throws`)
	end

	-- a sound calls it off: it goes to look instead, and doesn't throw on the way
	local called = fresh()
	Keeper.offer(called, at, box, 1, Breaker.Grip)
	Keeper.step(called, DT, RUN)
	local heard = Keeper.heardAt(called, called.at + vector.create(0.5, 0, 0), 50)
	ok(heard ~= nil and called.state == "Going", `{where}: a sound calls it off`)
	ok(not called.errand, `{where}: called off, it's off its errand at once (the camera cuts)`)
	Keeper.offer(called, at, box, 0, Breaker.Grip) -- so the next pick isn't the box again
	for _ = 1, 60 * 30 do
		Keeper.step(called, DT, RUN)
		ok(not called.threw, `{where}: called off, it never throws`)
	end

	-- S2-07a2: on its way it hears less (`Keeper.ErrandHearing`), so the throw usually happens. A
	-- hall stop well off along the halls: a sound there carrying half again as far as the walk
	-- reaches a wandering Mannequin, but not one on its errand, which walks on and throws.
	local busy = fresh()
	Keeper.offer(busy, at, box, 1, Breaker.Grip)
	Keeper.step(busy, DT, RUN)
	local far, off = nil :: vector?, 0
	for _, i in map.stops do
		local p = vector.create(
			(map.minX[i] + map.maxX[i]) / 2,
			map.y[i],
			(map.minZ[i] + map.maxZ[i]) / 2
		)
		local d = walker:length(busy.at, p)
		if d >= 40 and d <= 160 then
			far, off = p, d
			break
		end
	end
	if far then
		farOff += 1
		local reach = off * 1.5
		local idle = fresh()
		Keeper.step(idle, DT, RUN)
		ok(not idle.errand, `{where}: the other wanders, no errand`)
		ok(Keeper.heardAt(idle, far, reach) ~= nil, `{where}: wandering, it hears the far sound`)
		ok(
			Keeper.heardAt(busy, far, reach) == nil and busy.errand and busy.state == "Roaming",
			`{where}: on its errand, a sound {math.round(off)} off doesn't call it off`
		)
		local threw = false
		for _ = 1, 60 * 300 do
			Keeper.step(busy, DT, RUN)
			if busy.threw then
				threw = true
				break
			end
		end
		ok(threw, `{where}: it walks on and throws`)
		-- its hand on the grip, the same far sound leaves it there: it throws on the beat
		local steady = fresh()
		Keeper.offer(steady, at, box, 1, Breaker.Grip)
		for _ = 1, 60 * 300 do
			Keeper.step(steady, DT, RUN)
			if steady.lever == "Reach" then
				break
			end
		end
		local d = walker:length(steady.at, far)
		ok(Keeper.heardAt(steady, far, d * 1.5) == nil, `{where}: on the grip, the far sound fades`)
		local thrown2 = false
		for _ = 1, math.ceil(Breaker.Grip / DT) + 2 do
			Keeper.step(steady, DT, RUN)
			thrown2 = thrown2 or steady.threw
		end
		ok(thrown2, `{where}: on the grip, it throws on the beat`)
	end
	-- a wrong code's alarm still calls it off however far (S2-04b): every monster comes
	local alarmed = fresh()
	Keeper.offer(alarmed, at, box, 1, Breaker.Grip)
	Keeper.step(alarmed, DT, RUN)
	local heardAlarm = Keeper.alarm(alarmed, far or vector.create(0, 3, 0), 1)
	ok(
		heardAlarm ~= nil and alarmed.state == "Going" and not alarmed.errand,
		`{where}: the alarm calls it off its errand`
	)

	-- a keeper that doesn't freeze in light never takes it, and with no offer none goes
	local row = table.clone(MANNEQUIN)
	row.freezesInLight = false
	local other = fresh(row)
	Keeper.offer(other, at, box, 1, Breaker.Grip)
	ok(other.errandChance == 0, `{where}: a keeper that moves in light isn't offered it`)
	local none = fresh()
	for _ = 1, 60 * 60 do
		Keeper.step(none, DT, RUN)
		Keeper.step(other, DT, RUN)
		ok(not none.threw and not none.errand, `{where}: with no offer it never goes`)
		ok(not other.threw and not other.errand, `{where}: the other never goes`)
	end

	-- a warm errand allocates nothing
	local warm = fresh()
	Keeper.offer(warm, at, box, 1, Breaker.Grip)
	for _ = 1, 120 do
		Keeper.step(warm, DT, RUN)
	end
	local before = gcinfo()
	for _ = 1, 600 do
		Keeper.offer(warm, at, box, 1, Breaker.Grip)
		Keeper.step(warm, DT, RUN)
	end
	ok(gcinfo() - before <= 1, `{where}: a warm errand allocates nothing`)
end

for seed = 1, 12 do
	for _, number in { 1, 2, 3, 5, 9 } do
		checkFloor(seed, number)
	end
end

ok(farOff >= floors * 0.9, `a far sound tried on nearly every floor ({farOff} of {floors})`)

if failures > 0 then
	error(`errand: {failures} of {checks} checks failed`)
end
print(
	`errand: all {checks} checks passed ({floors} floors, {walks} walks to the box, {throws} throws)`
)
