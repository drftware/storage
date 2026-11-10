--!strict
--[[
	Keeper: one keeper's brain (L-06b2a, D-064). Pure: nothing here touches an Instance, so Lune
	tests it (tests/keeper.spec.luau). The server's `Keepers` system holds one of these per keeper,
	tells it what it hears and steps it on the Host's clock; this module decides what it does.

	The moment it serves: you slam a door and, two halls off, something starts walking toward it;
	it stands there looking, then wanders off down the halls, and now you don't know where it is.
	Granny's way with a noise: it walks to where the sound was, stands there a while looking, then
	walks the house room to room. Once out of its unit it never goes back (D-071). Its states:

	- Asleep: dealt asleep behind a door (L-06b2b, D-070), standing slack where it was put,
	  listening. The first loud sound that reaches it wakes it, as a noise startles Left 4 Dead's
	  sleeping Witch, and it goes to look; it never sleeps again.
	- Watching: awake and standing where it was put, never yet out. Dealt awake, it steps out to
	  look the moment its own door is all the way up (`lookOut`). One shut in its unit with no way
	  out (its door came down before it got out) stands watching too, until its door is up again.
	- Going: walking to look at a sound, at its row's walking pace.
	- Waiting: standing still a while: at a sound, facing it, for its row's `linger`; on a roam,
	  facing the way it came, for its `roamLinger`.
	- Roaming: walking the halls between noises (L-06b3a1), at the same pace, to the middle of a
	  hall piece some way off (`roamNear` to `roamFar` along the halls) that it hasn't stood in
	  lately (its last `roamMemory` places), picked by the floor's seeded Random. Never into a
	  unit. A door coming down across its way makes it pick again. Phase 2's director will steer
	  these picks, as Alien: Isolation's keeps the alien near you.

	It hears a door's open, slam or lift from inside (`Keeper.Hears`, the GDD's loud ones) as far as
	that sound carries for a player (DoorSound's reach, scaled by its row's `hearing`), measured
	along the map (`KeeperMap`), so no sound reaches it through a wall or a shut door. A newer sound
	it hears takes it there instead, as Granny turns to the latest noise, whatever it was doing.

	Coordinates are the floor's own (Floor: the lobby's middle at the origin, its floor at height 0),
	and a keeper's position is its feet. A step allocates nothing once its route is warm, a roam's
	pick included.
]]
local Floor = require("./Floor")
local KeeperMap = require("./KeeperMap")
local KeeperRows = require("./KeeperRows")

export type State = "Asleep" | "Watching" | "Going" | "Waiting" | "Roaming"

export type Keeper = {
	row: KeeperRows.Row,
	map: KeeperMap.Map, -- the floor it's on
	pathing: KeeperMap.Pathing, -- the map as it walks it (its abilities)
	route: KeeperMap.Route, -- the trip it's on, planned again as doors change
	random: Floor.Random, -- the floor's, shared by its keepers: where each roams next
	state: State,
	at: vector, -- where its feet are
	facing: vector, -- the way it faces: flat, length 1
	goal: vector, -- where it's walking to
	heard: vector, -- the sound it went to look at: it faces this while it waits there
	waited: number, -- seconds it has stood still this time
	wait: number, -- seconds it stands still this time: its linger at a sound, or on a roam
	recent: { number }, -- the map places it last stood still in, a ring of its row's `roamMemory`
	recentAt: number, -- the ring's newest
	trips: { number }, -- scratch for a roam's pick: each stop's trip from where it stands
	travelled: number, -- studs walked since it was stood up: its walk's pose (Pose.at)
}

local Keeper = {}

-- Which door sounds (Motion.Kind) keepers hear: the GDD's loud ones. A peek is quiet on purpose
-- (the GDD's door table), and a close, a rattle at a padlock, a padlock going on and the cutters'
-- snap aren't in its list of what keepers hear (OWNER.md asks).
Keeper.Hears =
	table.freeze({ Open = true, Slam = true, LiftInside = true }) :: { [string]: boolean }

-- How far out in the hall from a door's face a keeper stands to look at it (studs): a stride
-- short of the door, square in front of it, on an 8-stud hall.
Keeper.Front = 3

-- As good as there (studs): a route lands exactly on its end, so this is only float slack.
local ARRIVE = 1e-3
-- Moved less than this in a step that had studs to walk: there's no way there now.
local STUCK = 1e-6

local function flat(v: vector): vector
	local m = math.sqrt(v.x * v.x + v.z * v.z)
	if m < 1e-9 then
		return vector.create(0, 0, -1)
	end
	return vector.create(v.x / m, 0, v.z / m)
end

local function flatDistance(a: vector, b: vector): number
	local dx, dz = a.x - b.x, a.z - b.z
	return math.sqrt(dx * dx + dz * dz)
end

-- Turns it toward `p`, unless it's standing on it.
local function faceToward(k: Keeper, p: vector)
	local dx, dz = p.x - k.at.x, p.z - k.at.z
	if dx * dx + dz * dz > 1e-6 then
		k.facing = flat(vector.create(dx, 0, dz))
	end
end

-- The middle of map place `i`, on its floor.
local function middle(map: KeeperMap.Map, i: number): vector
	return vector.create((map.minX[i] + map.maxX[i]) / 2, map.y[i], (map.minZ[i] + map.maxZ[i]) / 2)
end

-- Whether it stood still in place `i` lately.
local function stoodIn(k: Keeper, i: number): boolean
	for _, p in k.recent do
		if p == i then
			return true
		end
	end
	return false
end

-- It stands still where it is for `seconds`, and remembers the place, so it roams on elsewhere.
local function stand(k: Keeper, seconds: number)
	k.state, k.waited, k.wait = "Waiting", 0, seconds
	local n = #k.recent
	if n > 0 then
		k.recentAt = k.recentAt % n + 1
		k.recent[k.recentAt] = KeeperMap.placeAt(k.map, k.at)
	end
end

-- Where it roams next: a stop (a hall piece's middle, `KeeperMap`'s `stops`) other than the place
-- it's in, picked at random from the floor's Random among those whose trip is within its row's
-- roam band and that it hasn't stood in lately; with none of those, among any it can reach and
-- hasn't stood in lately; with none of those, among any it can reach. Nil when it can reach none:
-- shut in a unit.
local function pick(k: Keeper): vector?
	local map, row, trips = k.map, k.row, k.trips
	local stops = map.stops
	local here = KeeperMap.placeAt(map, k.at)
	local near, far = row.roamNear, row.roamFar
	local banded, fresh, reachable = 0, 0, 0
	for j, i in stops do
		local d = if i == here then math.huge else k.pathing:length(k.at, middle(map, i))
		trips[j] = d
		if d < math.huge then
			reachable += 1
			if not stoodIn(k, i) then
				fresh += 1
				if d >= near and d <= far then
					banded += 1
				end
			end
		end
	end
	local count = if banded > 0 then banded elseif fresh > 0 then fresh else reachable
	if count == 0 then
		return nil
	end
	local n = k.random:nextInteger(1, count)
	for j, i in stops do
		local d = trips[j]
		if
			d < math.huge
			and (
				(banded == 0 and fresh == 0)
				or (not stoodIn(k, i) and (banded == 0 or (d >= near and d <= far)))
			)
		then
			n -= 1
			if n == 0 then
				return middle(map, i)
			end
		end
	end
	return nil
end

-- It sets off roaming, or, with nowhere it can reach, stands watching where it is.
local function roam(k: Keeper)
	local goal = pick(k)
	if goal then
		k.state, k.goal = "Roaming", goal
	else
		k.state = "Watching"
	end
end

--- A keeper of `row` with its feet at `at`, facing `facing`, walking `map` with its row's
--- abilities and roaming by `random` (the floor's): asleep, or watching if `awake`.
function Keeper.new(
	row: KeeperRows.Row,
	map: KeeperMap.Map,
	random: Floor.Random,
	at: vector,
	facing: vector,
	awake: boolean?
): Keeper
	local pathing = KeeperMap.pathing(map, row.abilities)
	return {
		row = row,
		map = map,
		pathing = pathing,
		route = pathing:route(),
		random = random,
		state = if awake then "Watching" else "Asleep",
		at = at,
		facing = flat(facing),
		goal = at,
		heard = at,
		waited = 0,
		wait = 0,
		recent = table.create(math.max(row.roamMemory, 0), 0),
		recentAt = 0,
		trips = table.create(#map.stops, 0),
		travelled = 0,
	}
end

--- A sound at `from` carrying `reach` studs (DoorSound's), to be looked at from `spot`. If the
--- keeper hears it (its trip to the sound is no longer than the reach, scaled by its row's
--- hearing) it goes to look, whatever it was doing: returns how far off it heard it, along the
--- map. Else nil.
function Keeper.hear(k: Keeper, from: vector, reach: number, spot: vector): number?
	local carries = reach * k.row.hearing
	if not (carries > 0) then
		return nil
	end
	local d = k.pathing:length(k.at, from)
	if d > carries then
		return nil
	end
	k.state = "Going"
	k.goal, k.heard, k.waited = spot, from, 0
	return d
end

--- Whether it's awake: anything but dealt asleep and not yet woken. The deal's cap counts these.
function Keeper.awake(k: Keeper): boolean
	return k.state ~= "Asleep"
end

--- Unit `index`'s door (its slot `slot`) just got all the way up. An awake keeper standing in that
--- unit steps out to look: it walks to the door's front and stands there facing out into the hall,
--- away from the door, for its linger, then roams. Whether it went.
function Keeper.lookOut(k: Keeper, slot: Floor.Slot, index: number): boolean
	if k.state ~= "Watching" then
		return false
	end
	local _, unit = KeeperMap.placeAt(k.map, k.at)
	if unit ~= index then
		return false
	end
	local spot = Keeper.front(slot)
	local fx, fz = Floor.dir(slot.facing)
	k.state = "Going"
	k.goal, k.waited = spot, 0
	k.heard = vector.create(spot.x + fx * Keeper.Front, 0, spot.z + fz * Keeper.Front)
	return true
end

--- Steps it by `dt` seconds, `run` being a player's full run (studs a second; its row's speeds are
--- shares of it). Returns whether anything a body shows changed: where it stands, the way it faces
--- or its state.
function Keeper.step(k: Keeper, dt: number, run: number): boolean
	local state = k.state
	if state == "Asleep" or state == "Watching" then
		return false
	elseif state == "Waiting" then
		k.waited += dt
		if k.waited >= k.wait then
			roam(k)
			return true
		end
		return false
	end
	-- Going or Roaming: along its route, at a walk
	local studs = k.row.speed * k.row.looking * run * dt
	local before = k.at
	local after = k.route:advance(before, k.goal, studs)
	k.at = after
	local dx, dz = after.x - before.x, after.z - before.z
	local moved = math.sqrt(dx * dx + dz * dz)
	if moved > STUCK then
		k.travelled += moved
		k.facing = vector.create(dx / moved, 0, dz / moved)
	end
	local there = flatDistance(after, k.goal) <= ARRIVE
	if state == "Going" and (there or (studs > 0 and moved <= STUCK)) then
		-- there, or a door came down across its way: it looks from where it is
		stand(k, k.row.linger)
		faceToward(k, k.heard)
	elseif there then
		stand(k, k.row.roamLinger)
	elseif studs > 0 and moved <= STUCK then
		roam(k) -- a door came down across its way: it picks another place
	end
	return true
end

--- Lets go of its route (when its floor or body goes).
function Keeper.release(k: Keeper)
	k.route:release()
end

--- Where a keeper stands to look at a unit's door: `Front` studs out into the hall, square in front
--- of it. Returns that spot and the door's middle (on the floor, in the doorway).
function Keeper.front(slot: Floor.Slot): (vector, vector)
	local fx, fz = Floor.dir(slot.facing)
	return vector.create(slot.x + fx * Keeper.Front, 0, slot.z + fz * Keeper.Front),
		vector.create(slot.x, 0, slot.z)
end

--- The middle of the hall place (on the floor, not up on the tops) whose trip from `from` is
--- nearest `studs` long, and the way it would set off back toward `from`: where a test stands a
--- keeper "two halls off". Allocates: for setting up, never a step.
function Keeper.hallAbout(
	map: KeeperMap.Map,
	pathing: KeeperMap.Pathing,
	from: vector,
	studs: number
): (vector, vector)
	local own = KeeperMap.placeAt(map, from)
	local best, bestOff = vector.zero, math.huge
	for i = 1, #map.minX do
		if map.unit[i] == 0 and map.y[i] == 0 and i ~= own then
			local mid =
				vector.create((map.minX[i] + map.maxX[i]) / 2, 0, (map.minZ[i] + map.maxZ[i]) / 2)
			local off = math.abs(pathing:length(mid, from) - studs)
			if off < bestOff then
				best, bestOff = mid, off
			end
		end
	end
	local facing = vector.create(from.x - best.x, 0, from.z - best.z)
	local trip = KeeperMap.trip(pathing, best, from)
	if trip then
		for _, p in trip do
			if flatDistance(p, best) > 0.01 then
				facing = vector.create(p.x - best.x, 0, p.z - best.z)
				break
			end
		end
	end
	return best, flat(facing)
end

return table.freeze(Keeper)
