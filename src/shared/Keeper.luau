--!strict
--[[
	Keeper: one keeper's brain (L-06b2a, D-064). Pure: nothing here touches an Instance, so Lune
	tests it (tests/keeper.spec.luau). The server's `Keepers` system holds one of these per keeper,
	tells it what it hears and steps it on the Host's clock; this module decides what it does.

	The moments it serves: you slam a door and, two halls off, something starts walking toward it;
	it stands there looking, then wanders off down the halls, and now you don't know where it is.
	Then it rounds a corner, sees you, and comes at you; you duck out of its sight and it rushes to
	where it last saw you, looks about, and wanders off again. Granny's way: she walks to a noise,
	stands there looking, walks the house room to room, chases you on sight and searches where she
	lost you. Once out of its unit it never goes back (D-071). Its states:

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
	- Hunting (L-06b3a2): it saw a player and comes at them at its top speed (`speed`, never over
	  your run) along the halls, stopping at arm's length (`Close`) facing them. It keeps them
	  while it sees them any way it faces; no sound pulls it off. Its hand closes on them the
	  moment they're within its grasp (the catch, below): then it stands over where it caught
	  them for its linger, as if Waiting at a sound, and roams.
	- Searching: it lost the one it hunted and rushes, at its top speed, to where it last saw
	  them, then stands there for its `linger`, looking on the way it was going, then roams.
	- Trapped (L-06b3d): a unit's door came down on it from all the way up, by a slam or a close,
	  while it stood awake inside (`trap`). It walks to stand against the door, facing it, and
	  bangs on it from inside (`blow`) on its row's clock, the blows coming faster as its time runs
	  out; at its `breakOut` it bursts the door up, as Amnesia's monsters batter down a door you
	  shut, and once the door is up it goes after the last thing it heard while trapped, or steps
	  out to look and roams. Lift the door yourself and it's just out. A padlock on the door holds
	  it: at its break-out time it gives up and stands quiet, until the padlock comes off. While
	  trapped it hears through its own door (`hear`), and takes no place in the floor's cap of
	  awake keepers (`loose`).

	It sees a player (`step`'s `players`) awake in any state: within its row's `sight`, within its
	`sightAngle` either side of the way it faces, along a straight line the map clears
	(`KeeperMap.clear`): never through a wall, a shut door or a door's posts, and never up on the
	units' tops. It hunts the nearest it sees. Asleep, it sees nothing.

	Light freezes it (L-06b3b), if its row says so (`freezesInLight`, the GDD's Mannequin): it moves
	only while no light is on it, as SCP-173 in SCP: Containment Breach moves only while unseen and
	Five Nights at Freddy's animatronics never move while the camera is on them. A light is on it
	while it stands in a hall (not inside a unit, whose walls shade it) under a lit hall light's
	pool (`step`'s `hallLit`, the server's MotionLights), or while a player's torch beam reaches it
	(`inTorch`: within the beam's reach and cone, along a line the map clears). Lit, it holds where
	it stands, as it stands, keeping its state, its trip and its clocks: it doesn't walk or turn,
	but it still sees and hears, so it may start hunting you while frozen and comes the moment the
	light leaves it. Screens hold it on the key its stride was on (`Pose.freeze`).

	It catches the one it hunts (L-06b3c), as Granny's grab or Piggy's swing ends the chase the
	moment she reaches you: their feet within its row's `reach` along the halls and its
	`reachAngle` either side of the way it faces (Brix's cone reach, `Reach.cone`, measured along
	its map), along a line the map clears (never through a wall or a shut door, never from up on
	the tops), and no higher than its head. Never while a light holds it, never asleep, and never
	anyone but the one it hunts. A step's catch is `caught`; what follows is the server's (L-07).

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
local Torch = require("./Flashlight/Torch")

export type State =
	"Asleep"
	| "Watching"
	| "Going"
	| "Waiting"
	| "Roaming"
	| "Hunting"
	| "Searching"
	| "Trapped"

--- What a trapped keeper did to its door this step: nothing, a blow from inside, its burst up, or
--- its last blow as a padlock holds it at its break-out time.
export type Blow = "None" | "Bang" | "Burst" | "Held"

--- The players a keeper may see this step, as parallel arrays `count` long, which the caller fills
--- and reuses: each one's id (any number but 0; the server's are UserIds), where their feet are,
--- in the floor's coordinates, and their torch: where its beam leaves from (their eyes) and the
--- way it points (length 1), or a zero `aim` (or none) while it's off.
export type Players = {
	ids: { number },
	at: { vector },
	eye: { vector },
	aim: { vector },
	count: number,
}

--- A reach, Brix's contract (Contracts/Pursuit): how far `runner` is from being within reach of
--- a hunter at `hunter` heading along `heading`, in studs: 0 once within.
export type Reach = {
	distance: (self: any, hunter: vector, heading: vector, runner: vector) -> number, -- self: Brix's contract types it any
}
--- What makes a keeper's grasp: Brix's `Reach.cone`, handed in, since the pure brain doesn't
--- require Brix (the server and the specs do).
export type Cone = (
	options: { pathing: KeeperMap.Pathing, radius: number, halfAngle: number }
) -> Reach

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
	target: number, -- the id of the player it hunts, or 0
	seen: vector, -- where it last saw them
	widthCos: number, -- the cosine of its row's sightAngle: how wide it sees
	lit: number, -- the light on it: 0 none, `Keeper.HallLight`, or the id of whose torch it's in
	reach: Reach?, -- its grasp, along its map; none, it never catches (specs of the walk alone)
	caught: number, -- the id of the player it caught this step, or 0
	trappedIn: number, -- the unit (its slot in the floor) it's shut in by a door it was behind, or 0
	doorway: vector, -- that unit's door's middle, on the floor: where its blows land
	outside: vector, -- that door's front in the hall: whatever it hears, it hears through the door
	against: vector, -- where it stands to bang: just inside the door, square to it
	trapped: number, -- seconds since its door came down on it: its break-out clock
	nextBang: number, -- when on that clock it bangs next
	blow: Blow, -- what it did to its door this step
	burst: boolean, -- it burst its door and waits for it to be all the way up
	padlocked: boolean, -- its door is padlocked: it never bursts out
	heardOut: boolean, -- it heard something while trapped: it goes there once out
	heardSpot: vector, -- where it looks from at that sound (`heard` is the sound)
}

local Keeper = {}

-- Which door sounds (Motion.Kind) keepers hear: the GDD's loud ones. A peek is quiet on purpose
-- (the GDD's door table), and a close, a rattle at a padlock, a padlock going on and the cutters'
-- snap aren't in its list of what keepers hear (OWNER.md asks).
-- A trapped keeper's blows on its door and its burst are loud too (L-06b3d): others come to look.
Keeper.Hears = table.freeze({
	Open = true,
	Slam = true,
	LiftInside = true,
	Bang = true,
	Burst = true,
}) :: { [string]: boolean }

-- How far out in the hall from a door's face a keeper stands to look at it (studs): a stride
-- short of the door, square in front of it, on an 8-stud hall.
Keeper.Front = 3

-- How near it comes to the player it hunts, feet to feet (studs): face to face, arm's length.
-- Its grasp (its row's `reach`) is a little past this, so it catches whoever it stands at.
Keeper.Close = 2.5

-- `lit` while it stands under a lit hall light.
Keeper.HallLight = -1

-- How far inside its doorway a trapped keeper stands to bang on it, feet to the corridor wall's
-- face (studs). The Mannequin's walk holds an arm out level, its hand about 2.7 ahead of its feet,
-- and the slats are 0.55 behind the wall's face: at 3.4 its reaching hand meets the door at chest
-- height, where the dent bows out (L-06b3d2), rather than passing through into the hall (it did
-- at 1.2). A peek under the door shows its feet a few studs in.
Keeper.Against = 3.4

-- Feet more than this over or under its own are out of its sight (studs): up on the units' tops
-- (10 up) or on another floor. A jump (about 7 at the top) isn't.
local SIGHT_HEIGHT = 8
-- As good as there (studs): a route lands exactly on its end, so this is only float slack.
local ARRIVE = 1e-3
-- Moved less than this in a step that had studs to walk: there's no way there now.
local STUCK = 1e-6
-- A torch's beam reaches no further than this (Torch's), so a keeper further off isn't tested.
local BEAM_REACH = Torch.BeamRange
-- Points up its middle, feet to head, that a beam may catch: about a stud apart on the Mannequin.
Keeper.BeamPoints = 7

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

-- How far off it sees a player whose feet are at `p` (straight across the floor), or nil: within
-- its sight, within its view's width unless it looks `anyWay`, and along a line the map clears.
local function sees(k: Keeper, p: vector, anyWay: boolean): number?
	if math.abs(p.y - k.at.y) > SIGHT_HEIGHT then
		return nil
	end
	local dx, dz = p.x - k.at.x, p.z - k.at.z
	local d2 = dx * dx + dz * dz
	local range = k.row.sight
	if not (d2 <= range * range) then
		return nil
	end
	local d = math.sqrt(d2)
	if not anyWay and d > 1e-6 and dx * k.facing.x + dz * k.facing.z < k.widthCos * d then
		return nil
	end
	if not KeeperMap.clear(k.map, k.at, p) then
		return nil
	end
	return d
end

-- It looks for players. Hunting, it keeps its eyes on the one it hunts while it sees them any way
-- it faces. Else it notices the nearest it sees within its view, turns to them (unless it's held
-- `still` by a light) and hunts them. Hunting and seeing no one, it has lost them: it rushes to
-- where it last saw them. Returns whether its state or the one it hunts changed.
local function look(k: Keeper, players: Players, still: boolean): boolean
	local ids, at = players.ids, players.at
	if k.state == "Hunting" then
		for i = 1, players.count do
			if ids[i] == k.target then
				local p = at[i]
				if sees(k, p, true) then
					k.seen, k.goal = p, p
					return false
				end
				break
			end
		end
	end
	local best, nearest = 0, math.huge
	for i = 1, players.count do
		local d = sees(k, at[i], false)
		if d and d < nearest then
			best, nearest = i, d
		end
	end
	if best > 0 then
		local changed = k.state ~= "Hunting" or k.target ~= ids[best]
		k.state, k.target, k.waited = "Hunting", ids[best], 0
		k.seen, k.goal = at[best], at[best]
		if changed and not still then
			faceToward(k, k.seen) -- the turn: it has seen you
		end
		return changed
	elseif k.state == "Hunting" then
		k.state, k.target, k.goal = "Searching", 0, k.seen
		return true
	end
	return false
end

--- The id of the one it hunts if its hand would close on them where they all stand now, else 0:
--- hunting, their feet within its row's reach along the halls and ahead of it within its reach's
--- angle (`k.reach`, Brix's cone), no higher or lower than its height, along a line the map clears.
--- Only asks: `step` acts on it. Allocates nothing.
function Keeper.catches(k: Keeper, players: Players): number
	local reach = k.reach
	if not reach or k.state ~= "Hunting" then
		return 0
	end
	local ids = players.ids
	for i = 1, players.count do
		if ids[i] == k.target then
			local p, at, row = players.at[i], k.at, k.row
			local dy = p.y - at.y
			if dy > row.height or dy < -row.height then
				return 0
			end
			-- a walk along the halls is never shorter than the straight line: most steps end here
			local dx, dz = p.x - at.x, p.z - at.z
			local radius = row.reach
			if dx * dx + dz * dz > radius * radius then
				return 0
			end
			if reach:distance(at, k.facing, p) > 0 or not KeeperMap.clear(k.map, at, p) then
				return 0
			end
			return ids[i]
		end
	end
	return 0
end

-- It sets off roaming, or, with nowhere it can reach, stands watching where it is; shut in where
-- it was trapped (it hunted someone in there with it), it goes back to its door, trapped again.
local function roam(k: Keeper)
	local goal = pick(k)
	if goal then
		k.state, k.goal = "Roaming", goal
	elseif k.trappedIn ~= 0 then
		k.state, k.goal = "Trapped", k.against
	else
		k.state = "Watching"
	end
end

--- A keeper of `row` with its feet at `at`, facing `facing`, walking `map` with its row's
--- abilities and roaming by `random` (the floor's): asleep, or watching if `awake`. `cone` (Brix's
--- `Reach.cone`) makes its grasp from its row; with none it never catches.
function Keeper.new(
	row: KeeperRows.Row,
	map: KeeperMap.Map,
	random: Floor.Random,
	at: vector,
	facing: vector,
	awake: boolean?,
	cone: Cone?
): Keeper
	local pathing = KeeperMap.pathing(map, row.abilities)
	local reach = if cone
		then cone({ pathing = pathing, radius = row.reach, halfAngle = math.rad(row.reachAngle) })
		else nil
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
		target = 0,
		seen = at,
		widthCos = math.cos(math.rad(row.sightAngle)),
		lit = 0,
		reach = reach,
		caught = 0,
		trappedIn = 0,
		doorway = at,
		outside = at,
		against = at,
		trapped = 0,
		nextBang = 0,
		blow = "None",
		burst = false,
		padlocked = false,
		heardOut = false,
		heardSpot = at,
	}
end

--- A sound at `from` carrying `reach` studs (DoorSound's), to be looked at from `spot`. If the
--- keeper hears it (its trip to the sound is no longer than the reach, scaled by its row's
--- hearing) it goes to look, whatever it was doing but hunting: returns how far off it heard it,
--- along the map. Else nil. Hunting, its eyes are on you and it hears nothing, so a slammed door
--- never calls it off a chase; searching, it goes. Trapped, it hears through its own door (its
--- trip to the sound from the door's front, plus its own way to the door) and goes nowhere: it
--- remembers the sound, to go after once out. Its own door's sounds it doesn't count.
function Keeper.hear(k: Keeper, from: vector, reach: number, spot: vector): number?
	local carries = reach * k.row.hearing
	if not (carries > 0) or k.state == "Hunting" then
		return nil
	end
	if k.state == "Trapped" then
		if from == k.doorway then
			return nil
		end
		local d = flatDistance(k.at, k.doorway) + k.pathing:length(k.outside, from)
		if d > carries then
			return nil
		end
		k.heardOut, k.heard, k.heardSpot = true, from, spot
		return d
	end
	local d = k.pathing:length(k.at, from)
	if d > carries then
		return nil
	end
	k.state = "Going"
	k.goal, k.heard, k.waited = spot, from, 0
	return d
end

--- Whether it's awake: anything but dealt asleep and not yet woken.
function Keeper.awake(k: Keeper): boolean
	return k.state ~= "Asleep"
end

--- Whether it's loose on its floor: awake and not shut in where it was trapped. The deal's cap of
--- awake keepers counts these (the GDD: a trapped keeper takes no place), so the next door can
--- hold a fresh one; out again, it counts again.
function Keeper.loose(k: Keeper): boolean
	return k.state ~= "Asleep" and k.trappedIn == 0
end

--- Unit `index`'s door (its slot `slot`) just came down from all the way up, by a slam or a close.
--- An awake keeper standing in that unit is trapped: it goes to stand against the door, its
--- break-out clock started and its first blow due at its row's `bangFirst`. Whether it was.
function Keeper.trap(k: Keeper, slot: Floor.Slot, index: number): boolean
	local state = k.state
	if state == "Asleep" or state == "Trapped" then
		return false
	end
	local _, unit = KeeperMap.placeAt(k.map, k.at)
	if unit ~= index then
		return false
	end
	local outside, doorway = Keeper.front(slot)
	local fx, fz = Floor.dir(slot.facing)
	k.state, k.target = "Trapped", 0
	k.trappedIn, k.doorway, k.outside = index, doorway, outside
	k.against = vector.create(doorway.x - fx * Keeper.Against, 0, doorway.z - fz * Keeper.Against)
	k.goal, k.waited = k.against, 0
	k.trapped, k.nextBang = 0, k.row.bangFirst
	k.burst, k.padlocked, k.heardOut = false, false, false
	return true
end

--- The door it's trapped behind was padlocked (true) or the padlock cut off (false). Padlocked, it
--- never bursts out; off, it bursts out at once if its time is up.
function Keeper.padlock(k: Keeper, locked: boolean)
	if k.trappedIn ~= 0 then
		k.padlocked = locked
		if locked then
			k.burst = false
		end
	end
end

--- Unit `index`'s door (its slot `slot`) just got all the way up. An awake keeper standing in that
--- unit steps out to look: it walks to the door's front and stands there facing out into the hall,
--- away from the door, for its linger, then roams. One trapped in it is out: it goes after the last
--- thing it heard while trapped, or, having heard nothing, steps out to look. Whether it went.
function Keeper.lookOut(k: Keeper, slot: Floor.Slot, index: number): boolean
	if k.trappedIn == index then
		k.trappedIn = 0
		if k.state == "Trapped" then
			k.burst, k.padlocked = false, false
			if k.heardOut then
				k.state, k.goal, k.waited = "Going", k.heardSpot, 0
				return true
			end
			k.state = "Watching"
		end
	end
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

--- Whether a torch beam leaving `eye` along `aim` (length 1), held by a player whose feet are at
--- `from`, is on it: some point up its middle, feet to head, within the beam's reach and cone
--- (Torch's), along a line the map clears from their feet to its own, so never through a wall, a
--- shut door or round a corner. Allocates nothing.
function Keeper.inTorch(k: Keeper, eye: vector, aim: vector, from: vector): boolean
	local at = k.at
	local dx, dz = at.x - eye.x, at.z - eye.z
	if dx * dx + dz * dz > BEAM_REACH * BEAM_REACH then
		return false
	end
	local h = k.row.height
	for i = 1, Keeper.BeamPoints do
		if Torch.lights(eye, aim, Keeper.beamPoint(at, h, i)) then
			return KeeperMap.clear(k.map, from, at)
		end
	end
	return false
end

--- The `i`th point up the middle of a keeper `height` tall whose feet are at `at` that a beam may
--- catch (1 nearest its feet, `BeamPoints` nearest its head): where the server's brain
--- (`inTorch`) and your screen (KeeperView) both test a torch's beam.
function Keeper.beamPoint(at: vector, height: number, i: number): vector
	return at + vector.create(0, height * (i - 0.5) / Keeper.BeamPoints, 0)
end

-- The light on it now (`lit`'s values): none unless its row freezes in light and it's awake; a
-- hall light if `hallLit` (a lit fixture's pool is where it stands) and it's in a hall, not inside
-- a unit, whose walls shade it; else the first player whose torch is on it.
local function lightOn(k: Keeper, players: Players?, hallLit: boolean): number
	if not k.row.freezesInLight or k.state == "Asleep" then
		return 0
	end
	if hallLit then
		local _, unit = KeeperMap.placeAt(k.map, k.at)
		if unit == 0 then
			return Keeper.HallLight
		end
	end
	if players then
		local aims, eyes = players.aim, players.eye
		for i = 1, players.count do
			local aim: vector? = aims[i]
			if aim and aim ~= vector.zero and Keeper.inTorch(k, eyes[i], aim, players.at[i]) then
				return players.ids[i]
			end
		end
	end
	return 0
end

-- The gap to a trapped keeper's next blow: its row's `bangEvery` closing to `bangEveryLast` as its
-- break-out clock runs, a random share (`bangJitter`, the floor's Random) longer or shorter.
local function bangGap(k: Keeper): number
	local row = k.row
	local share = math.clamp(k.trapped / row.breakOut, 0, 1)
	local base = row.bangEvery + (row.bangEveryLast - row.bangEvery) * share
	return base * (1 + row.bangJitter * (2 * k.random:nextNumber() - 1))
end

-- Trapped: it walks to stand against its door, facing it, and bangs on it on its clock, from the
-- moment it's there; at its break-out time it bursts it up (`blow`), or, padlocked, gives it one
-- last blow and stands quiet. Burst, it waits for the door to be all the way up (`lookOut`).
-- Whether anything a body shows changed.
local function trappedStep(k: Keeper, dt: number, run: number): boolean
	local changed = false
	local there = flatDistance(k.at, k.goal) <= ARRIVE
	if not there then
		local before = k.at
		local after = k.route:advance(before, k.goal, Keeper.pace(k, run) * dt)
		local dx, dz = after.x - before.x, after.z - before.z
		local moved = math.sqrt(dx * dx + dz * dz)
		if moved > STUCK then
			k.at, k.travelled = after, k.travelled + moved
			k.facing = vector.create(dx / moved, 0, dz / moved)
		end
		there = moved <= STUCK or flatDistance(after, k.goal) <= ARRIVE
		if there then
			k.goal = k.at -- at its door, or as near as it gets: it stands here, facing the door
			faceToward(k, k.doorway)
		end
		changed = true
	end
	if k.burst then
		return changed
	end
	local row = k.row
	local was = k.trapped
	k.trapped += dt
	if k.trapped >= row.breakOut then
		if not k.padlocked then
			k.blow, k.burst = "Burst", true
		elseif was < row.breakOut then
			k.blow = "Held"
		end
	elseif k.trapped >= k.nextBang then
		if row.breakOut - k.trapped < row.bangEveryLast / 2 then
			k.nextBang = row.breakOut -- too near its burst: the burst is its next blow, not a double
		elseif there then
			k.blow = "Bang"
			k.nextBang = k.trapped + bangGap(k)
		else
			k.nextBang = k.trapped -- it hits the door the moment it gets there
		end
	end
	return changed
end

--- Steps it by `dt` seconds, `run` being a player's full run (studs a second; its row's speeds are
--- shares of it), with `players` those it may see (none: it sees no one) and `hallLit` whether a
--- lit hall light's pool is where it stands (the server's MotionLights). Returns whether anything
--- a body shows changed: where it stands, the way it faces or its state. Held by a light, it says
--- so every step; whether it is, and whose light, is `lit`. Whom it caught this step is `caught`
--- (0 for no one): it stands over where it caught them, waiting, the one it hunted let go. What a
--- trapped one did to its door this step is `blow`.
function Keeper.step(
	k: Keeper,
	dt: number,
	run: number,
	players: Players?,
	hallLit: boolean?
): boolean
	local lit = lightOn(k, players, hallLit == true)
	k.lit = lit
	k.caught = 0
	k.blow = "None"
	local looked = false
	if players and k.state ~= "Asleep" then
		looked = look(k, players, lit ~= 0)
	end
	if lit ~= 0 then
		-- held where it stands, as it stands, its clocks stopped: it only sees
		return true
	end
	local state = k.state
	if state == "Trapped" then
		return trappedStep(k, dt, run) or looked
	elseif state == "Asleep" or state == "Watching" then
		return looked
	elseif state == "Waiting" then
		k.waited += dt
		if k.waited >= k.wait then
			roam(k)
			return true
		end
		return looked
	end
	-- moving along its route: hunting and searching at its top speed, else at its walk
	local hunting = state == "Hunting"
	local studs = Keeper.pace(k, run) * dt
	if hunting then
		studs = math.min(studs, math.max(flatDistance(k.at, k.goal) - Keeper.Close, 0))
	end
	local before = k.at
	local after = if studs > 0 then k.route:advance(before, k.goal, studs) else before
	k.at = after
	local dx, dz = after.x - before.x, after.z - before.z
	local moved = math.sqrt(dx * dx + dz * dz)
	if moved > STUCK then
		k.travelled += moved
		k.facing = vector.create(dx / moved, 0, dz / moved)
	end
	local there = flatDistance(after, k.goal) <= ARRIVE
	local stuck = studs > 0 and moved <= STUCK
	if hunting then
		if moved <= STUCK then
			faceToward(k, k.goal) -- at arm's length: it stands facing them
		end
		local id = if players then Keeper.catches(k, players) else 0
		if id ~= 0 then
			-- its hand closes on them: it stands over the spot, then roams
			k.caught, k.target = id, 0
			stand(k, k.row.linger)
		end
	elseif (state == "Going" or state == "Searching") and (there or stuck) then
		-- there, or a door came down across its way: it looks from where it is, at the sound it
		-- heard, or, searching, on the way it was going
		stand(k, k.row.linger)
		if state == "Going" then
			faceToward(k, k.heard)
		end
	elseif there then
		stand(k, k.row.roamLinger)
	elseif stuck then
		roam(k) -- a door came down across its way: it picks another place
	end
	return true
end

--- How fast it walks in its state (studs a second), `run` being a player's full run: hunting and
--- searching at its top speed, going to look, roaming and going to its door trapped at its looking
--- pace; 0 standing.
function Keeper.pace(k: Keeper, run: number): number
	local state = k.state
	if state == "Hunting" or state == "Searching" then
		return k.row.speed * run
	elseif state == "Going" or state == "Roaming" then
		return k.row.speed * run * k.row.looking
	elseif state == "Trapped" and flatDistance(k.at, k.goal) > ARRIVE then
		return k.row.speed * run * k.row.looking -- on its way to stand against its door
	end
	return 0
end

--- How far it walks before it stops, if nothing changes (studs): its trip's length along the
--- halls, short of arm's length if it hunts; 0 standing; math.huge with no way there. Screens
--- never show it walking past this (`KeeperMotion`).
function Keeper.left(k: Keeper): number
	local state = k.state
	if state == "Asleep" or state == "Watching" or state == "Waiting" then
		return 0
	end
	local d = k.pathing:length(k.at, k.goal)
	if state == "Hunting" then
		d = math.max(d - Keeper.Close, 0)
	end
	return d
end

--- A new, empty list of players for `step`, to fill and reuse.
function Keeper.players(): Players
	return { ids = {}, at = {}, eye = {}, aim = {}, count = 0 }
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
