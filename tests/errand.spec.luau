--!strict
-- lune run tests/errand.spec
-- The Mannequin cuts the power (S2-02c, GDD "The Mannequin cuts the power"): how keen it is goes
-- up with the floor, capped, and is nothing while the box is thrown or the power just came back.
-- Where it stands to throw it is in the hall in front of the box on every spot. Offered the box at
-- a sure chance, a Mannequin picking where to wander heads there, walks the halls at its walk,
-- throws it exactly once on arrival facing the box, then lingers; held by a light it doesn't move
-- or throw; an offer withdrawn calls the walk off; a sound calls it off; a keeper that doesn't
-- freeze in light never takes the errand; with no offer it never goes. And a warm errand
-- allocates nothing.
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

local floors, walks, throws = 0, 0, 0
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
	Keeper.offer(k, at, box, 1)
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
	ok(thrown == 1, `{where}: it throws the box once on arrival ({thrown})`)
	ok(flat(k.at, at) < 1e-2, `{where}: it's at the stand`)
	ok(k.state == "Waiting" and not k.errand, `{where}: it stands there after`)
	local toBox = vector.normalize(vector.create(box.x - k.at.x, 0, box.z - k.at.z))
	ok(vector.dot(k.facing, toBox) > 0.99, `{where}: facing the box`)
	throws += thrown
	for _ = 1, 30 do
		Keeper.step(k, DT, RUN)
		ok(not k.threw, `{where}: one throw, not one a step`)
	end

	-- held by a light, it neither moves nor throws
	local lit = fresh()
	Keeper.offer(lit, at, box, 1)
	Keeper.step(lit, DT, RUN)
	local stood = lit.at
	for _ = 1, 600 do
		Keeper.step(lit, DT, RUN, nil, true)
		ok(not lit.threw, `{where}: lit, it never throws`)
	end
	ok(lit.at == stood and lit.errand, `{where}: lit, it holds where it stands, still bound there`)

	-- the offer withdrawn on its way (the power went off or just came back): it never throws
	local off = fresh()
	Keeper.offer(off, at, box, 1)
	Keeper.step(off, DT, RUN)
	Keeper.offer(off, at, box, 0)
	ok(not off.errand, `{where}: withdrawn, the walk is off`)
	for _ = 1, 60 * 120 do
		Keeper.step(off, DT, RUN)
		ok(not off.threw, `{where}: withdrawn, it never throws`)
	end

	-- a sound calls it off: it goes to look instead, and doesn't throw on the way
	local called = fresh()
	Keeper.offer(called, at, box, 1)
	Keeper.step(called, DT, RUN)
	local heard = Keeper.heardAt(called, called.at + vector.create(0.5, 0, 0), 50)
	ok(heard ~= nil and called.state == "Going", `{where}: a sound calls it off`)
	Keeper.offer(called, at, box, 0) -- so the next pick isn't the box again
	for _ = 1, 60 * 30 do
		Keeper.step(called, DT, RUN)
		ok(not called.threw, `{where}: called off, it never throws`)
	end

	-- a keeper that doesn't freeze in light never takes it, and with no offer none goes
	local row = table.clone(MANNEQUIN)
	row.freezesInLight = false
	local other = fresh(row)
	Keeper.offer(other, at, box, 1)
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
	Keeper.offer(warm, at, box, 1)
	for _ = 1, 120 do
		Keeper.step(warm, DT, RUN)
	end
	local before = gcinfo()
	for _ = 1, 600 do
		Keeper.offer(warm, at, box, 1)
		Keeper.step(warm, DT, RUN)
	end
	ok(gcinfo() - before <= 1, `{where}: a warm errand allocates nothing`)
end

for seed = 1, 12 do
	for _, number in { 1, 2, 3, 5, 9 } do
		checkFloor(seed, number)
	end
end

if failures > 0 then
	error(`errand: {failures} of {checks} checks failed`)
end
print(
	`errand: all {checks} checks passed ({floors} floors, {walks} walks to the box, {throws} throws)`
)
