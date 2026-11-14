--!strict
-- lune run tests/shuttap.spec
-- The tap when you pull a door down on a sleeping monster (S2-05a, the GDD's "The tap"), as Dead
-- by Daylight's skill checks: a bar comes up by itself, a marker sweeps it once, one tap in its
-- zone and the door settles soft; miss, or don't tap, and it bangs and the monster wakes shut in
-- and pounds. A pull earns the tap only from well up, over a monster asleep or one that hasn't
-- seen the puller. The door eases down to hang a foot up while the bar runs, longer than the bar
-- and the tap's way to the server, so it never comes to rest there; a hit settles it from where
-- it is, slowly and nearly silent, and keepers don't hear it; a miss drops it with a slam's bang,
-- which they do.
local Brix = require("../vendor/brix/src")
local Door = require("../src/shared/StorageUnit/Door")
local DoorSound = require("../src/shared/StorageUnit/DoorSound")
local Floor = require("../src/shared/Floor")
local Keeper = require("../src/shared/Keeper")
local KeeperMap = require("../src/shared/KeeperMap")
local KeeperRows = require("../src/shared/KeeperRows")
local Motion = require("../src/shared/StorageUnit/Motion")
local ShutTap = require("../src/shared/StorageUnit/ShutTap")

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

local FULL = 9 -- a door's full stroke (studs)
local RISE = { Peek = 1.15, Open = FULL }

-- When a pull earns the tap.
do
	ok(ShutTap.earns(true, false, FULL), "pulled down from all the way up on a sleeper: a tap")
	ok(ShutTap.earns(false, false, FULL), "awake, but it hasn't seen you: a tap")
	ok(not ShutTap.earns(false, true, FULL), "it's seen you: no tap, the door just comes down")
	ok(not ShutTap.earns(nil, false, FULL), "nothing inside: no tap")
	ok(not ShutTap.earns(true, false, RISE.Peek), "a peek's short drop: no tap, it's quiet already")
	ok(ShutTap.earns(true, false, ShutTap.MinRise), "from far enough up: a tap")
end

-- The bar: the marker waits for the lead, sweeps once at an even speed, and stops at the end.
do
	ok(ShutTap.marker(0) == 0 and ShutTap.marker(ShutTap.Lead) == 0, "still through the lead")
	local mid = ShutTap.marker(ShutTap.Lead + ShutTap.Sweep / 2)
	ok(math.abs(mid - 0.5) < 1e-9, `half way at half the sweep ({mid})`)
	ok(ShutTap.marker(ShutTap.Window) == 1, "at the end when the window ends")
	ok(ShutTap.marker(ShutTap.Window + 5) == 1, "and stays there")
	ok(ShutTap.marker(-1) == 0, "never before the start")
	ok(math.abs(ShutTap.Window - (ShutTap.Lead + ShutTap.Sweep)) < 1e-9, "window = lead + sweep")
	ok(ShutTap.Lead >= 0.3, `long enough to get a thumb ready ({ShutTap.Lead} s)`)
	ok(ShutTap.Sweep >= 0.8 and ShutTap.Sweep <= 1.6, `a skill check's sweep ({ShutTap.Sweep} s)`)
end

-- The zone: never at the very start, always wholly on the bar, anywhere between.
do
	local lo, hi = math.huge, -math.huge
	for i = 0, 100 do
		local at = ShutTap.zone(i / 100)
		lo, hi = math.min(lo, at), math.max(hi, at)
		ok(at >= ShutTap.ZoneEarliest - 1e-9, "never before its earliest")
		ok(at + ShutTap.ZoneWidth <= 1 + 1e-9, "always wholly on the bar")
	end
	ok(math.abs(lo - ShutTap.ZoneEarliest) < 1e-9, "a roll of 0 is the earliest")
	ok(math.abs(hi - ShutTap.ZoneLatest) < 1e-9, "a roll of 1 is the latest")
	ok(ShutTap.ZoneEarliest >= 0.3, "it never comes up before you've seen the marker go")
	local zoneTime = ShutTap.ZoneWidth * ShutTap.Sweep
	ok(zoneTime >= 0.12 and zoneTime <= 0.3, `the zone lasts a fair beat ({zoneTime} s)`)
end

-- Hit or miss, from when the tap came (seconds after the pull), against a zone.
do
	local zone = ShutTap.zone(0.5)
	local function at(share: number): number
		return ShutTap.Lead + share * ShutTap.Sweep
	end
	ok(ShutTap.judge(zone, at(zone + ShutTap.ZoneWidth / 2)) == "Hit", "in the middle: a hit")
	ok(ShutTap.judge(zone, at(zone + 1e-6)) == "Hit", "just inside its left edge: a hit")
	ok(ShutTap.judge(zone, at(zone + ShutTap.ZoneWidth - 1e-6)) == "Hit", "just inside its right")
	ok(ShutTap.judge(zone, at(zone - 0.02)) == "Miss", "a hair early: a miss")
	ok(ShutTap.judge(zone, at(zone + ShutTap.ZoneWidth + 0.02)) == "Miss", "a hair late: a miss")
	ok(ShutTap.judge(zone, 0.05) == "Miss", "a tap before the marker moves: a miss")
	ok(ShutTap.judge(zone, nil) == "Miss", "no tap: a miss")
	ok(ShutTap.judge(zone, ShutTap.Window + 1) == "Miss", "after the end: a miss")
end

-- When the server believes a tap came: what the screen says, held to its window and how late a
-- message can fairly be; nil for nonsense.
do
	local start, now = 100, 101
	ok(ShutTap.heard(start, now, 100.9) == 100.9, "a tap just sent is believed as it says")
	ok(ShutTap.heard(start, now, now) == now, "one at the server's own moment")
	local old = ShutTap.heard(start, now, 100.1)
	ok(old == now - ShutTap.MaxLag, `one claiming too long ago is held to the lag allowed ({old})`)
	local ahead = ShutTap.heard(start, now, now + 3)
	ok(ahead == now + ShutTap.Ahead, `one claiming the future is held to now ({ahead})`)
	ok(ShutTap.heard(start, 100.1, 99) == start, "never before the pull")
	ok(ShutTap.heard(start, now, 0 / 0) == nil, "not a number: refused")
	ok(ShutTap.heard(start, now, math.huge) == nil, "infinite: refused")
	ok(ShutTap.MaxLag >= 0.15 and ShutTap.MaxLag <= 0.4, `a phone's fair lag ({ShutTap.MaxLag})`)
	ok(ShutTap.due(start, start + ShutTap.Window + ShutTap.MaxLag), "no tap by then: it's due")
	ok(not ShutTap.due(start, start + ShutTap.Window), "a late message may still be on its way")
end

-- The door: it eases down to hang a foot up for longer than the bar and a late tap, so it's
-- still coming down (and its state still Closing) whenever the tap lands.
do
	ok(Motion.isKind("Ease") and Motion.isKind("Settle") and Motion.isKind("Drop"), "three motions")
	local hover = Motion.target("Ease", RISE)
	ok(hover == Motion.Hover and hover > 0.5 and hover < RISE.Peek, `hangs a foot up ({hover})`)
	local ease = Motion.duration("Ease", FULL, hover, FULL)
	ok(ease >= ShutTap.Window + ShutTap.MaxLag, `eases longer than the bar and its lag ({ease})`)
	ok(Motion.duration("Ease", 4, hover, FULL) == ease, "the same however high it started")
	local last = FULL
	for i = 1, 40 do
		local y = Motion.sample("Ease", FULL, hover, ease * i / 40, FULL)
		ok(y <= last + 1e-9 and y >= hover - 1e-9, "it only comes down, never past its foot")
		last = y
	end
	local early = Motion.speed("Ease", FULL, hover, 0.1, FULL)
	local late = Motion.speed("Ease", FULL, hover, ShutTap.Lead + ShutTap.Sweep / 2, FULL)
	ok(late < early / 4, `fast at first, a creep by the zone ({early} then {late} studs/s)`)
	local creep = Motion.sample("Ease", FULL, hover, ShutTap.Lead + ShutTap.Sweep / 2, FULL)
	ok(creep - hover < 0.6, `about a foot up while the marker crosses ({creep})`)
	for _, t in { 0.1, ShutTap.Window, ShutTap.Window + ShutTap.MaxLag } do
		ok(Door.stateOf("Ease", FULL, hover, t, FULL, false) == "Closing", `closing at {t} s`)
	end
	ok(#Motion.strikes("Ease", FULL, hover, FULL) == 0, "hanging there, it strikes nothing")

	-- a hit: it settles from where it is, slowly, landing soft
	local settle = Motion.duration("Settle", hover, 0, FULL)
	ok(settle >= 0.6, `the last stretch is slow ({settle} s)`)
	ok(Motion.target("Settle", RISE) == 0 and Motion.target("Drop", RISE) == 0, "both land shut")
	local landing = Motion.speed("Settle", hover, 0, settle - 0.02, FULL)
	ok(landing < 0.3, `and lands soft ({landing} studs/s)`)
	ok(Door.stateOf("Settle", hover, 0, settle / 2, FULL, false) == "Closing", "closing as it goes")
	ok(Door.stateOf("Settle", hover, 0, settle, FULL, false) == "Closed", "then shut")
	local soft = DoorSound.cues("Settle", hover, 0, FULL)
	local close = DoorSound.cues("Close", FULL, 0, FULL)
	local loud, closeLoud = 0, 0
	for _, c in soft do
		loud = math.max(loud, c.gain)
		ok(c.shake == 0 and c.sound ~= "Bang", "no bang, no shake")
	end
	for _, c in close do
		closeLoud = math.max(closeLoud, c.gain)
	end
	ok(#soft >= 1 and loud < closeLoud / 3, `a soft touch, far quieter than a close ({loud})`)
	local latched = false
	for _, c in soft do
		latched = latched or (c.sound == "Latch" and c.at > 0)
	end
	ok(latched, "and its latch catches as it lands")
	ok(not Keeper.Hears.Settle and not Keeper.Hears.Ease, "keepers hear neither")
	ok(DoorSound.Actions.Settle.Reach < DoorSound.Actions.Close.Reach, "it carries less")

	-- a miss: it drops from where it is with a slam's bang, as hard as a slam from all the way up
	local drop = Motion.duration("Drop", hover, 0, FULL)
	ok(drop > 0 and drop < 0.5, `it falls at once ({drop} s)`)
	ok(Door.stateOf("Drop", hover, 0, 0.01, FULL, false) == "Slamming", "slamming as it falls")
	ok(Door.stateOf("Drop", hover, 0, drop, FULL, false) == "Closed", "then shut")
	local bang = DoorSound.cues("Drop", hover, 0, FULL)
	local slam = DoorSound.cues("Slam", FULL, 0, FULL)
	local banged = false
	for _, c in bang do
		if c.sound == "Bang" then
			banged = c.gain >= slam[1].gain - 1e-9 and c.shake >= slam[1].shake - 1e-9
		end
	end
	ok(banged, "it bangs as loud as a slam, shaking whoever's near as much")
	ok(Keeper.Hears.Drop, "keepers hear it")
	ok(DoorSound.Actions.Drop.Reach == DoorSound.Actions.Slam.Reach, "as far as a slam")
end

-- The monster behind it: a miss wakes a sleeper shut in its unit, and it pounds.
local f = Floor.generate(4, Brix.Random.new({ seed = 11 }))
local map = KeeperMap.build(f)
local inside: number?, near: number? = nil, nil
for i, s in f.slots do
	if s.kind == "Unit" and not inside then
		for j, t in f.slots do
			if j ~= i and t.kind == "Unit" and t.cell == s.cell then
				inside, near = i, j
				break
			end
		end
	end
end
assert(inside and near, "a hall piece with two units")
local slot, nearSlot = f.slots[inside], f.slots[near]
local unitPlace = 0
for i = 1, #map.minX do
	if map.unit[i] == inside then
		unitPlace = i
	end
end
local middle = vector.create(
	(map.minX[unitPlace] + map.maxX[unitPlace]) / 2,
	0,
	(map.minZ[unitPlace] + map.maxZ[unitPlace]) / 2
)
local front = Keeper.front(slot)
local ROW = KeeperRows.Mannequin
do
	KeeperMap.setDoor(map, inside, false)
	local function sleeper(at: vector): Keeper.Keeper
		return Keeper.new(ROW, map, Brix.Random.new({ seed = 2 }), at, vector.create(0, 0, 1))
	end
	local k = sleeper(middle)
	ok(not Keeper.wakeShut(k, nearSlot, near), "another unit's door doesn't wake it")
	ok(k.state == "Asleep", "it sleeps on")
	ok(Keeper.wakeShut(k, slot, inside), "its own door's bang wakes it")
	ok(k.state == "Trapped" and k.trappedIn == inside, "shut in")
	ok(Keeper.awake(k) and not Keeper.loose(k), "awake, but takes no place in the cap")
	ok(k.nextBang == ROW.bangFirst, "its first blow on the trapped clock")
	ok(not Keeper.wakeShut(k, slot, inside), "already shut in: nothing more")
	local out = sleeper(front)
	ok(not Keeper.wakeShut(out, slot, inside), "asleep out in the hall: not shut in by it")
	ok(out.state == "Asleep", "and still asleep")
	local awake =
		Keeper.new(ROW, map, Brix.Random.new({ seed = 2 }), middle, vector.create(0, 0, 1), true)
	ok(Keeper.wakeShut(awake, slot, inside), "awake in there and not yet trapped: trapped now")
end

if failures > 0 then
	error(`shuttap: {failures} of {checks} checks failed`)
end
print(`shuttap: all {checks} checks passed`)
