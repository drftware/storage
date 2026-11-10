--!strict
--[[
	Keeper: one keeper's brain (L-06b2a, D-064). Pure: nothing here touches an Instance, so Lune
	tests it (tests/keeper.spec.luau). The server's `Keepers` system holds one of these per keeper,
	tells it what it hears and steps it on the Host's clock; this module decides what it does.

	The moment it serves: you slam a door and, two halls off, something starts walking toward it.
	Granny's way with a noise: it walks to where the sound was, stands there a while looking, then
	goes back to where it was. Its states:

	- Asleep: dealt asleep behind a door (L-06b2b, D-070), standing slack where it was put,
	  listening. The first loud sound that reaches it wakes it, as a noise startles Left 4 Dead's
	  sleeping Witch, and it goes to look; it never sleeps again.
	- Watching: awake and standing where it was put or went back to. Dealt awake, it steps out to
	  look the moment its own door is all the way up (`lookOut`).
	- Going: walking to look at a sound, at its row's walking pace.
	- Waiting: standing at the sound, facing it, for its row's `linger` seconds.
	- Returning: walking back to where it woke, then Watching again.

	It hears a door's open, slam or lift from inside (`Keeper.Hears`, the GDD's loud ones) as far as
	that sound carries for a player (DoorSound's reach, scaled by its row's `hearing`), measured
	along the map (`KeeperMap`), so no sound reaches it through a wall or a shut door. A newer sound
	it hears takes it there instead, as Granny turns to the latest noise; where it goes back to stays
	where it first woke.

	Coordinates are the floor's own (Floor: the lobby's middle at the origin, its floor at height 0),
	and a keeper's position is its feet. A step allocates nothing once its route is warm.
]]
local Floor = require("./Floor")
local KeeperMap = require("./KeeperMap")
local KeeperRows = require("./KeeperRows")

export type State = "Asleep" | "Watching" | "Going" | "Waiting" | "Returning"

export type Keeper = {
	row: KeeperRows.Row,
	map: KeeperMap.Map, -- the floor it's on
	pathing: KeeperMap.Pathing, -- the map as it walks it (its abilities)
	route: KeeperMap.Route, -- the trip it's on, planned again as doors change
	state: State,
	at: vector, -- where its feet are
	facing: vector, -- the way it faces: flat, length 1
	home: vector, -- where it woke: it goes back there
	homeFacing: vector,
	goal: vector, -- where it's walking to
	heard: vector, -- the sound it went to look at: it faces this while it waits
	waited: number, -- seconds it has stood looking
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

--- A keeper of `row` with its feet at `at`, facing `facing`, walking `map` with its row's
--- abilities: asleep, or watching if `awake`.
function Keeper.new(
	row: KeeperRows.Row,
	map: KeeperMap.Map,
	at: vector,
	facing: vector,
	awake: boolean?
): Keeper
	local pathing = KeeperMap.pathing(map, row.abilities)
	local f = flat(facing)
	return {
		row = row,
		map = map,
		pathing = pathing,
		route = pathing:route(),
		state = if awake then "Watching" else "Asleep",
		at = at,
		facing = f,
		home = at,
		homeFacing = f,
		goal = at,
		heard = at,
		waited = 0,
		travelled = 0,
	}
end

--- A sound at `from` carrying `reach` studs (DoorSound's), to be looked at from `spot`. If the
--- keeper hears it (its trip to the sound is no longer than the reach, scaled by its row's
--- hearing) it goes to look: returns how far off it heard it, along the map. Else nil.
function Keeper.hear(k: Keeper, from: vector, reach: number, spot: vector): number?
	local carries = reach * k.row.hearing
	if not (carries > 0) then
		return nil
	end
	local d = k.pathing:length(k.at, from)
	if d > carries then
		return nil
	end
	if k.state == "Asleep" or k.state == "Watching" then
		k.home, k.homeFacing = k.at, k.facing
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
--- away from the door, for its linger, then goes back in. Whether it went.
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
	k.home, k.homeFacing = k.at, k.facing
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
		if k.waited >= k.row.linger then
			k.state, k.goal = "Returning", k.home
			return true
		end
		return false
	end
	-- Going or Returning: along its route, at a walk
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
	if there or (studs > 0 and moved <= STUCK) then
		-- there, or a door came down across its way: it stops where it is
		if state == "Going" then
			k.state, k.waited = "Waiting", 0
			faceToward(k, k.heard)
		elseif there then
			k.state, k.facing = "Watching", k.homeFacing
		else
			-- no way home: it stands watching where it is
			k.state, k.home, k.homeFacing = "Watching", k.at, k.facing
		end
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
