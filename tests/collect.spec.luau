--!strict
-- lune run tests/collect.spec
-- The Packrat carries finds home (S2-06b1, GDD "The Packrat collects things, not people"): its
-- row collects and light does nothing to it; told what lies loose on its floor (`Keeper.lying`)
-- it goes for the nearest it can walk to, never one on its own pile; stops short by its grab,
-- facing it, and stands with its arm out (Reaching); its hands close on it once (`took`, Taking);
-- walks home with its arms full, slower, seeing and hearing no one; crouches over its pile
-- (PuttingDown), lays it down once (`laid`) and comes out for the next. A find taken before it
-- gets there sends it to another; none left, it roams the halls. With empty arms it still hunts
-- a player it sees, and reaching one it takes the best thing they carry (`loot`, S2-06c) and goes
-- home with it, or with nothing to take catches them. The Mannequin never collects.
local Brix = require("../vendor/brix/src")
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
local PACKRAT = KeeperRows.Packrat
local COLLECT = assert(PACKRAT.collects, "the Packrat collects")

local function flat(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end
local function middleOf(map: KeeperMap.Map, i: number): vector
	return vector.create((map.minX[i] + map.maxX[i]) / 2, 0, (map.minZ[i] + map.maxZ[i]) / 2)
end

-- Its row
ok(PACKRAT.name == "Packrat", "the Packrat has a row")
ok(not PACKRAT.freezesInLight, "light does nothing to it")
ok(PACKRAT.speed > 0 and PACKRAT.speed < 1, "it comes at just under your run")
ok(KeeperRows.Mannequin.collects == nil, "the Mannequin collects nothing")
ok(COLLECT.grab > Keeper.Close and COLLECT.grab < 6, "it reaches for a find from arm's length")
ok(COLLECT.reach > 0 and COLLECT.take > 0 and COLLECT.putDown > 0, "each part takes a moment")
ok(COLLECT.laden > 0 and COLLECT.laden < 1, "its arms full, it walks slower")

local CONE = Brix.Reach.cone
local floors, trips, swaps, roams, robs = 0, 0, 0, 0, 0
local function checkFloor(seed: number, number: number)
	local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
	local where = `floor {number} seed {seed}`
	local map = KeeperMap.build(f)
	local walker = KeeperMap.pathing(map, PACKRAT.abilities)
	-- its own unit: the first ground unit off the hall, door up, the Packrat in its middle
	local homePlace = 0
	for i = 1, #map.minX do
		if map.unit[i] ~= 0 and map.y[i] == 0 then
			homePlace = i
			break
		end
	end
	if homePlace == 0 then
		return
	end
	local homeSlot = map.unit[homePlace]
	KeeperMap.setDoor(map, homeSlot, true)
	local home = middleOf(map, homePlace)
	local outside = Keeper.front(f.slots[homeSlot])
	-- two finds in the halls: one about 40 studs off along the halls, one about 120
	local nearAt = Keeper.hallAbout(map, walker, home, 40)
	local farAt = Keeper.hallAbout(map, walker, home, 120)
	if flat(nearAt, farAt) < 1 or walker:length(home, farAt) == math.huge then
		return
	end
	floors += 1
	local finds: Keeper.Finds = { ids = { 11, 22 }, at = { nearAt, farAt }, count = 2 }

	local function fresh(row: KeeperRows.Row?): Keeper.Keeper
		local k = Keeper.new(
			row or PACKRAT,
			map,
			Brix.Random.new({ seed = seed }),
			home,
			vector.create(outside.x - home.x, 0, outside.z - home.z),
			true
		)
		-- out of its unit's door, done looking: its next step picks where to go
		k.state, k.wait, k.waited = "Waiting", 0, 0
		return k
	end

	-- it goes for the nearer find along the halls
	local k = fresh()
	Keeper.lying(k, finds)
	Keeper.step(k, DT, RUN)
	ok(k.state == "Roaming" and k.fetch == 11, `{where}: it goes for the nearest find`)
	ok(Keeper.shown(k) == "Roaming", `{where}: empty-handed it walks as it roams`)
	local empty = Keeper.pace(k, RUN)

	-- walking there, it stops short by its grab and reaches, facing it
	local steps = 0
	while k.hands ~= "Reach" and steps < 60 * 120 do
		Keeper.step(k, DT, RUN)
		steps += 1
	end
	ok(k.hands == "Reach" and Keeper.shown(k) == "Reaching", `{where}: its arm goes out`)
	ok(flat(k.at, nearAt) <= COLLECT.grab + 0.1, `{where}: it stands within its grab`)
	ok(flat(k.at, nearAt) >= COLLECT.grab - 0.1, `{where}: its arm's length off, not on it`)
	ok(KeeperMap.clear(map, k.at, nearAt), `{where}: it reaches for it in plain line`)
	local d = nearAt - k.at
	ok(
		vector.dot(k.facing, vector.normalize(vector.create(d.x, 0, d.z))) > 0.999,
		`{where}: facing it`
	)
	-- its hands close on it once, then it pulls it in
	local took, tookAt = 0, 0
	steps = 0
	while k.hands ~= "None" and steps < 60 * 10 do
		Keeper.step(k, DT, RUN)
		steps += 1
		if k.took ~= 0 then
			took += 1
			tookAt = k.took
			ok(k.hands == "Take" and Keeper.shown(k) == "Taking", `{where}: taking it`)
		end
	end
	ok(took == 1 and tookAt == 11, `{where}: its hands close on that find once`)
	ok(k.holding == 11 and k.homing, `{where}: it turns for home with it`)
	ok(Keeper.shown(k) == "Carrying", `{where}: its arms full show`)
	local full = Keeper.pace(k, RUN)
	ok(full > 0 and full < empty, `{where}: slower with its arms full`)
	-- the find leaves the floor's loose ones (the server's)
	finds.ids[1], finds.at[1], finds.count = 22, farAt, 1
	Keeper.lying(k, finds)
	ok(k.holding == 11 and k.homing, `{where}: what lies loose doesn't turn it while full`)

	-- home, ignoring a player right in front of it and any sound
	local players = Keeper.players()
	players.ids[1], players.count = 7, 1
	players.aim[1], players.eye[1] = vector.zero, vector.zero
	local heard = Keeper.hear(k, k.at, 1e6, k.at)
	ok(heard == nil, `{where}: full, it hears nothing`)
	local hunted, laid, laidId = false, 0, 0
	steps = 0
	while k.hands ~= "PutDown" and steps < 60 * 120 do
		players.at[1] = k.at + k.facing * 4
		Keeper.step(k, DT, RUN, players)
		steps += 1
		hunted = hunted or k.state == "Hunting"
	end
	ok(not hunted, `{where}: full, it walks past a player`)
	ok(k.hands == "PutDown" and Keeper.shown(k) == "PuttingDown", `{where}: crouched at its pile`)
	ok(flat(k.at, home) < 1e-2, `{where}: at home`)
	steps = 0
	while k.hands ~= "None" and steps < 60 * 10 do
		Keeper.step(k, DT, RUN)
		steps += 1
		if k.laid ~= 0 then
			laid += 1
			laidId = k.laid
		end
	end
	ok(laid == 1 and laidId == 11 and k.holding == 0, `{where}: it lays the find down once`)
	ok(k.state == "Roaming" and k.fetch == 22, `{where}: out again for the next`)
	trips += 1

	-- empty-handed again, it hunts a player it sees
	players.at[1] = k.at + k.facing * 4
	Keeper.step(k, DT, RUN, players)
	if KeeperMap.clear(map, k.at, players.at[1]) then
		ok(k.state == "Hunting" and k.fetch == 0, `{where}: empty arms, it comes for you`)
	end

	-- reaching you with empty arms, it takes the best thing you carry rather than catching you
	-- (S2-06c): its hands close on it once, it pulls it in and walks home with it
	local huntAt, huntFace = Keeper.hallAbout(map, walker, home, 40)
	local you = huntAt + huntFace * 2
	if KeeperMap.clear(map, huntAt, you) then
		local function hunter(): Keeper.Keeper
			local h = Keeper.new(
				PACKRAT,
				map,
				Brix.Random.new({ seed = seed }),
				huntAt,
				huntFace,
				true,
				CONE
			)
			h.state, h.target, h.goal, h.seen = "Hunting", 7, you, you
			Keeper.nest(h, home, home) -- its own unit is where the trip home began
			return h
		end
		local robber = hunter()
		local carrying = Keeper.players()
		carrying.ids[1], carrying.at[1], carrying.count = 7, you, 1
		carrying.eye[1], carrying.aim[1] = vector.zero, vector.zero
		local loot = assert(carrying.loot)
		loot[1] = 9
		Keeper.step(robber, DT, RUN, carrying)
		ok(robber.robbed == 7 and robber.took == 9, `{where}: it takes your best thing`)
		ok(robber.caught == 0 and robber.target == 0, `{where}: robbed, you're let go, not caught`)
		ok(robber.holding == 9 and Keeper.shown(robber) == "Taking", `{where}: it pulls it in`)
		local again = 0
		steps = 0
		while robber.hands == "Take" and steps < 60 * 5 do
			Keeper.step(robber, DT, RUN, carrying)
			steps += 1
			if robber.took ~= 0 or robber.robbed ~= 0 then
				again += 1
			end
		end
		ok(again == 0, `{where}: it takes it once`)
		ok(robber.homing and robber.goal == home, `{where}: home with what it took`)
		ok(Keeper.shown(robber) == "Carrying", `{where}: it carries it off`)
		-- with nothing in your slots it catches you, as any monster
		local catcher = hunter()
		loot[1] = 0
		Keeper.step(catcher, DT, RUN, carrying)
		ok(catcher.caught == 7 and catcher.robbed == 0, `{where}: empty slots, it catches you`)
		ok(catcher.holding == 0 and catcher.took == 0, `{where}: and takes nothing`)
		robs += 1
	end

	-- a find taken before it gets there: it goes for another
	local swap = fresh()
	local both: Keeper.Finds = { ids = { 11, 22 }, at = { nearAt, farAt }, count = 2 }
	Keeper.lying(swap, both)
	Keeper.step(swap, DT, RUN)
	for _ = 1, 30 do
		Keeper.step(swap, DT, RUN)
	end
	both.ids[1], both.at[1], both.count = 22, farAt, 1
	Keeper.lying(swap, both)
	ok(swap.fetch == 22 and swap.goal == farAt, `{where}: it goes for the other`)
	swaps += 1
	both.count = 0
	Keeper.lying(swap, both)
	ok(swap.fetch == 0 and swap.state == "Roaming", `{where}: none left, it roams`)

	-- with none to start with it roams, and one dropped in the halls draws it
	local idle = fresh()
	local none: Keeper.Finds = { ids = {}, at = {}, count = 0 }
	Keeper.lying(idle, none)
	Keeper.step(idle, DT, RUN)
	ok(idle.state == "Roaming" and idle.fetch == 0, `{where}: nothing loose, it roams`)
	none.ids[1], none.at[1], none.count = 33, farAt, 1
	Keeper.lying(idle, none)
	ok(idle.fetch == 33 and idle.goal == farAt, `{where}: a find turns up and it goes`)
	roams += 1

	-- what's on its own pile it leaves be
	local own = fresh()
	local pile: Keeper.Finds = { ids = { 44 }, at = { home }, count = 1 }
	Keeper.lying(own, pile)
	Keeper.step(own, DT, RUN)
	ok(own.fetch == 0, `{where}: never what's on its own pile`)

	-- the Mannequin collects nothing
	local m = fresh(KeeperRows.Mannequin)
	local lure: Keeper.Finds = { ids = { 11 }, at = { nearAt }, count = 1 }
	Keeper.lying(m, lure)
	Keeper.step(m, DT, RUN)
	ok(m.fetch == 0 and m.holding == 0, `{where}: the Mannequin leaves finds be`)
	ok(Keeper.shown(m) == m.state, `{where}: the Mannequin shows its own state`)
end

for seed = 1, 6 do
	for _, number in { 3, 5, 9 } do
		checkFloor(seed, number)
	end
end
ok(floors >= 12, `enough floors had a trip to walk ({floors})`)
ok(trips == floors and swaps == floors and roams == floors, "every floor's checks ran")
ok(robs >= floors // 2, `enough floors had a take ({robs})`)

print(`collect: {checks - failures}/{checks} checks pass ({floors} floors, {trips} trips home)`)
if failures > 0 then
	error(`{failures} collect checks failed`)
end
