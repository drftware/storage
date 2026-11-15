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
	- Going: walking to look at a sound, at its row's walking pace. A new sound first stops it dead
	  for its row's `startle`, turned to face it, so you hear its walk stop and know it heard.
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
	  them, then stands there for its `linger`, looking on the way it was going, then roams. In a
	  unit it stops short of the walls (`Against`, its reaching arm's room) and looks at where
	  they were: in the hole trap (L-12c), the hole they crawled out through.
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

	It cuts the power (S2-02c), if its row freezes in light (the GDD's Mannequin, which wants the
	dark): offered the floor's breaker box (`offer`, the server's, while the box is on), each time
	it picks where to wander next it may head for the box instead, by the offer's chance from the
	floor's Random, as Phasmophobia's ghost goes to the fuse box. It walks there as it wanders,
	at its walk, held by any light as ever; there, it stands facing the box with its hand up on the
	grip a beat (`offer`'s grip; S2-02d2, so the security camera shows it), then drags the lever
	down with `threw` set for that step (the server throws it), and lingers holding it down
	(`lever`, which screens are shown as `Keeper.shown`). A light on it holds it in the beat;
	anything it hears or sees calls it off.

	It carries finds home (S2-06b1), if its row collects (`collects`, the GDD's Packrat), as Lethal
	Company's Hoarding Bug carries scrap to its nest. Told what lies loose on its floor (`lying`,
	the server's), each time it picks where to go next it goes for the nearest find it can walk to,
	never one on its own pile (in its own unit). It stops its grab short of it, facing it, and
	stands with its arm out (`hands` "Reach"); its hands close on it (`took` for that step: the
	server lifts it) and pull it in ("Take"); then it walks home with its arms full (`holding`),
	slower (`laden`), seeing and hearing no one; at home it crouches over its pile ("PutDown"),
	lays it there (`laid`: the server puts it on the pile) and comes out for the next. A find gone
	before it gets there sends it to another; none left, it roams. Its way home shut, it roams on,
	carrying, and heads home once there's a way. Screens are told its hands and full arms
	(`shown`). Its own unit and pile are where it was dealt, unless the server says (`nest`).

	It catches the one it hunts (L-06b3c), as Granny's grab or Piggy's swing ends the chase the
	moment she reaches you: their feet within its row's `reach` along the halls and its
	`reachAngle` either side of the way it faces (Brix's cone reach, `Reach.cone`, measured along
	its map), along a line the map clears (never through a wall or a shut door, never from up on
	the tops), and no higher than its head. Never while a light holds it, never asleep, and never
	anyone but the one it hunts. A step's catch is `caught`; what follows is the server's (L-07).
	A keeper that collects (S2-06c, the GDD's Packrat) takes rather than catches when they carry
	something it takes (`players.loot`, the server's pick from their slots): its hands close on it
	(`took`, with `robbed` the player) and pull it in, and it walks home with it as after a fetch,
	the player let go. With empty slots they're caught as by any keeper.

	It hears a door's open, slam or lift from inside (`Keeper.Hears`, the GDD's loud ones) as far as
	that sound carries for a player (DoorSound's reach, scaled by its row's `hearing`), measured
	along the map (`KeeperMap`), so no sound reaches it through a wall. Everything else players do
	that's loud reaches it the same way (`heardAt`, L-15): a sound up on a unit's top carries out
	over its front, and one behind a shut door gets out through it muffled (`Muffled`), so it comes
	to stand outside that door. A newer sound it hears takes it there instead, as Granny turns to
	the latest noise, whatever it was doing. A wrong code's alarm reaches it awake anywhere on its
	floor (`alarm`, S2-04b), as Left 4 Dead's car alarm calls the whole horde.

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
--- way it points (length 1), or a zero `aim` (or none) while it's off. `loot` is what a keeper
--- that collects takes from each when it reaches them (S2-06c): the number of the thing in their
--- slots it would carry off (any number but 0), or 0 (or none) for nothing it takes.
export type Players = {
	ids: { number },
	at: { vector },
	eye: { vector },
	aim: { vector },
	loot: { number }?,
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

--- The finds lying loose on its floor that a keeper which collects may pick up (S2-06b1), as
--- parallel arrays `count` long, which the server fills and reuses (`Keeper.lying`): each one's
--- id (any number but 0) and the floor under it, in the floor's coordinates (a find on a shelf:
--- the floor under the shelf), so a keeper's line to it can be cleared.
export type Finds = {
	ids: { number },
	at: { vector },
	count: number,
}

--- What a collecting keeper's hands are doing as it stands (S2-06b1): its arm out over a find,
--- its hands closed on it pulling it in, or crouched laying it on its pile.
export type Hands = "None" | "Reach" | "Take" | "PutDown"

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
	-- the floor has as many loose as it allows (S2-07a2, `hold`): past its time it pounds on
	held: boolean,
	heardOut: boolean, -- it heard something while trapped: it goes there once out
	heardSpot: vector, -- the spot a keeper looks from at that sound (`heard` is the sound)
	-- its own place round `heardSpot`, where it stands to look (`Keeper.spread`): the spot itself
	-- unless others came to look too
	place: vector,
	-- it's going to a sound it heard, or standing there looking: a newer one this near it (`Same`)
	-- is the same noise going on, and it walks on without stopping again
	listening: boolean,
	startle: number, -- seconds left standing where it heard a new sound, facing it, before it goes
	errandAt: vector, -- where it stands to throw the floor's breaker (`offer`, the floor's coords)
	errandBox: vector, -- the box itself: it faces it there
	errandChance: number, -- the chance it heads there each time it picks a wander; 0: never
	errandGrip: number, -- seconds it stands with its hand up on the grip before it throws (`offer`)
	errand: boolean, -- it's wandering to the box, or standing at it with its hand on the grip
	-- its hand on the box's lever while it stands there (S2-02d2): up on the grip the beat before
	-- it throws (Reach), then holding it down as it lingers (Pull); "None" anywhere else
	lever: Lever,
	threw: boolean, -- it dragged the lever down this step: the server throws the box
	-- Collecting (S2-06b1; only a row that `collects`):
	finds: Finds?, -- what lies loose on its floor, as the server last told it (`lying`)
	homeAt: vector, -- where it stands to lay a find on its pile: where it was dealt (`nest`)
	pile: vector, -- its pile: it faces it there
	home: number, -- its own unit (its slot in the floor), 0 for a hall: it never takes from it
	fetch: number, -- the id of the find it's going for or reaching for, or 0
	holding: number, -- the id of the find in its arms, or 0: while it holds one it sees no one
	homing: boolean, -- it's walking home with it
	hands: Hands, -- what its hands are doing as it stands
	took: number, -- the id of the find its hands closed on this step (the server lifts it), or 0
	-- the id of the player whose thing (`took`) its hands closed on this step (S2-06c: the server
	-- takes it out of their slots), or 0 for a find lying loose
	robbed: number,
	laid: number, -- the id of the find it laid on its pile this step (the server puts it there), or 0
}

export type Lever = "None" | "Reach" | "Pull"

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
	-- a missed tap's door banging down over a sleeper (S2-05a): heard as a slam is
	Drop = true,
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

-- How far ahead of where a collecting keeper stands at home its pile is (studs), S2-06b1: its
-- put-down lays a find low between its hands, a little ahead of its knees (the Packrat's PutDown).
Keeper.Pile = 1.5
-- Within this of its grab off a find, along a line the map clears, it's there to reach (studs).
local GRAB_SLACK = 0.05

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
	k.state, k.waited, k.wait, k.lever, k.hands = "Waiting", 0, seconds, "None", "None"
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
		k.listening, k.startle = false, 0
		k.fetch, k.hands = 0, "None" -- empty-armed, you before any find
		k.seen, k.goal = at[best], at[best]
		if changed and not still then
			faceToward(k, k.seen) -- the turn: it has seen you
		end
		return changed
	elseif k.state == "Hunting" then
		-- in a unit, it stops short of the walls: they may have crawled out through one (L-12c)
		k.state, k.target, k.goal =
			"Searching", 0, KeeperMap.offWalls(k.map, k.seen, Keeper.Against)
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

-- What a keeper that collects would take from player `id` (S2-06c): `players.loot`'s, or 0.
local function lootOf(players: Players, id: number): number
	local loot = players.loot
	if not loot then
		return 0
	end
	for i = 1, players.count do
		if players.ids[i] == id then
			return loot[i] or 0
		end
	end
	return 0
end

-- The find it goes for next (S2-06b1): the nearest along the halls it can walk to, never one in
-- its own unit (its pile). Its index in `finds`, or nil. Allocates nothing.
local function nearestFind(k: Keeper, finds: Finds): number?
	local best, nearest = nil, math.huge
	for i = 1, finds.count do
		local p = finds.at[i]
		local _, unit = KeeperMap.placeAt(k.map, p)
		if k.home == 0 or unit ~= k.home then
			local d = k.pathing:length(k.at, p)
			if d < nearest then
				best, nearest = i, d
			end
		end
	end
	return best
end

-- Where in `finds` the find `id` is, or nil.
local function findIndex(finds: Finds, id: number): number?
	for i = 1, finds.count do
		if finds.ids[i] == id then
			return i
		end
	end
	return nil
end

-- It sets off roaming, or, with nowhere it can reach, stands watching where it is; shut in where
-- it was trapped (it hunted someone in there with it), it goes back to its door, trapped again.
-- A collecting keeper (S2-06b1) heads home with a find it holds, else for the nearest find
-- lying loose; with neither, or no way home, it roams (carrying, if it holds one).
local function roam(k: Keeper)
	k.listening, k.startle, k.errand = false, 0, false
	k.fetch, k.hands, k.homing = 0, "None", false
	if k.row.collects then
		local finds = k.finds
		if k.holding ~= 0 then
			if k.pathing:length(k.at, k.homeAt) < math.huge then
				k.state, k.goal, k.homing = "Roaming", k.homeAt, true
				return
			end
		elseif finds then
			local i = nearestFind(k, finds)
			if i then
				k.state, k.goal, k.fetch = "Roaming", finds.at[i], finds.ids[i]
				return
			end
		end
	end
	-- the floor's Random is drawn only while an errand is offered, so floors without one roam
	-- exactly as they did
	if
		k.errandChance > 0
		and k.random:nextNumber() < k.errandChance
		and k.pathing:length(k.at, k.errandAt) < math.huge
	then
		k.state, k.goal, k.errand = "Roaming", k.errandAt, true
		return
	end
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
	local face = flat(facing)
	local _, home = KeeperMap.placeAt(map, at)
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
		facing = face,
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
		held = false,
		heardOut = false,
		heardSpot = at,
		place = at,
		listening = false,
		startle = 0,
		errandAt = at,
		errandBox = at,
		errandChance = 0,
		errandGrip = 0,
		errand = false,
		lever = "None",
		threw = false,
		finds = nil,
		homeAt = at,
		pile = at + face * Keeper.Pile,
		home = home,
		fetch = 0,
		holding = 0,
		homing = false,
		hands = "None",
		took = 0,
		laid = 0,
		robbed = 0,
	}
end

--- Where a collecting keeper's pile is (S2-06b1): it stands at `at` to lay a find there, facing
--- `pile` (the floor's coordinates), and never takes a find from the unit `at` is in. Dealt, it's
--- where it was put, its pile `Pile` studs ahead.
function Keeper.nest(k: Keeper, at: vector, pile: vector)
	local _, home = KeeperMap.placeAt(k.map, at)
	k.homeAt, k.pile, k.home = at, pile, home
end

--- What lies loose on its floor (`Finds`, the server's, filled and reused), told it each time that
--- changes: a find lifted, dropped or laid, a door going up or down. Only a row that collects
--- heeds it, and only with empty arms: going for a find that's gone (someone took it first), it
--- goes for the nearest left, or roams; going for one that moved, it follows it; roaming with
--- nothing to fetch, it goes for the nearest it can now walk to. Anything else it's doing (looking
--- at a sound, hunting, standing a while) it finishes first, and picks when it next picks.
function Keeper.lying(k: Keeper, finds: Finds)
	k.finds = finds
	if not k.row.collects or k.holding ~= 0 then
		return
	end
	if k.fetch ~= 0 then
		local i = findIndex(finds, k.fetch)
		if not i then
			roam(k)
		elseif finds.at[i] ~= k.goal then
			k.goal = finds.at[i]
			if k.hands == "Reach" then
				k.state, k.hands = "Roaming", "None" -- it moved from under its hand
			end
		end
	elseif k.state == "Roaming" then
		local i = nearestFind(k, finds)
		if i then
			k.goal, k.fetch = finds.at[i], finds.ids[i]
		end
	end
end

--- Offers it the floor's breaker box (S2-02c): it stands at `at` to throw it, facing `box` (the
--- floor's coordinates), and heads there with `chance` each time it picks where to wander next
--- (`Breaker.errand`: 0 while the box is thrown or the power just came back). Only a row that
--- freezes in light takes it; the server offers it every step, so a chance of 0 calls off a
--- walk already on its way.
function Keeper.offer(k: Keeper, at: vector, box: vector, chance: number, grip: number)
	if not k.row.freezesInLight then
		return
	end
	k.errandAt, k.errandBox, k.errandChance, k.errandGrip = at, box, chance, grip
	if chance <= 0 and k.errand then
		-- the power went off another way, or just came back: it wanders on, its hand off the grip
		k.errand = false
		if k.lever == "Reach" then
			k.lever = "None"
		end
	end
end

--- The state screens are told it's in (KeeperMotion): its own, but standing at a breaker box with
--- its hand on the lever, "Reaching" (up on the grip) or "Pulling" (holding it down), S2-02d2. A
--- collecting keeper (S2-06b1) shows its hands as it stands, "Reaching" (its arm out over a find),
--- "Taking" or "PuttingDown", and "Carrying" in any other state while it holds one.
function Keeper.shown(k: Keeper): string
	local hands = k.hands
	if hands == "Reach" then
		return "Reaching"
	elseif hands == "Take" then
		return "Taking"
	elseif hands == "PutDown" then
		return "PuttingDown"
	elseif k.holding ~= 0 then
		return "Carrying"
	end
	local lever = k.lever
	if k.state ~= "Waiting" or lever == "None" then
		return k.state
	end
	return if lever == "Reach" then "Reaching" else "Pulling"
end

-- A newer sound this near the one it's already going to (or standing at, looking), in studs, is
-- the same noise going on: a code's presses, a crawl's pulls, a door banged again. It walks on
-- toward it without stopping to turn again, and Output and screens don't hear of it again.
Keeper.Same = 12

-- How far it hears, as a share, while it's on its way to the breaker box or has its hand on the
-- grip (S2-07a2): a third. A door slammed in its own hall still turns it; one two halls off, or a
-- beep across the floor, doesn't, so the throw usually happens (four errands came to one clunk
-- before). A busy guard turns only for a noise close by, as a coin thrown in Hitman draws only the
-- guards it lands near (from memory). A wrong code's alarm carries past any of this.
Keeper.ErrandHearing = 1 / 3

--- A sound at `from` carrying `reach` studs (DoorSound's), to be looked at from `spot`. If the
--- keeper hears it (its trip to the sound is no longer than the reach, scaled by its row's
--- hearing) it goes to look, whatever it was doing but hunting: returns how far off it heard it,
--- along the map, and whether it's news to it (a sound it wasn't already going to, `Same`). Else
--- nil. Hunting, its eyes are on you and it hears nothing, so a slammed door never calls it off a
--- chase; searching, it goes. News stops it where it stands for its row's `startle`, turning to
--- face the sound, before it goes (Lethal Company's Eyeless Dogs stop and turn to a noise before
--- they come): the walk you were hearing stops dead, and you know it heard. Trapped, it hears
--- through its own door (its trip to the sound from the door's front, plus its own way to the
--- door) and goes nowhere: it remembers the sound, to go after once out. Its own door's sounds it
--- doesn't count. On its way to the breaker, or to a find (S2-06b1), it hears only
--- `ErrandHearing` as far; a sound that does reach it calls it off there and then. With a find
--- in its arms it hears nothing at all.
function Keeper.hear(k: Keeper, from: vector, reach: number, spot: vector): (number?, boolean)
	local busy = k.errand or k.fetch ~= 0
	local carries = reach * k.row.hearing * (if busy then Keeper.ErrandHearing else 1)
	if not (carries > 0) or k.state == "Hunting" or k.holding ~= 0 then
		return nil, false
	end
	if k.state == "Trapped" then
		if from == k.doorway then
			return nil, false
		end
		local d = flatDistance(k.at, k.doorway) + k.pathing:length(k.outside, from)
		if d > carries then
			return nil, false
		end
		local news = not (k.heardOut and flatDistance(from, k.heard) <= Keeper.Same)
		k.heardOut, k.heard, k.heardSpot, k.place = true, from, spot, spot
		return d, news
	end
	local d = k.pathing:length(k.at, from)
	if d > carries then
		return nil, false
	end
	local news = not (k.listening and flatDistance(from, k.heard) <= Keeper.Same)
	if news then
		k.startle = k.row.startle
	end
	k.state, k.listening = "Going", true
	k.goal, k.heard, k.waited = spot, from, 0
	k.heardSpot, k.place = spot, spot
	-- called off the breaker: its hand comes off the grip, and screens' cameras let it go
	k.errand, k.lever = false, "None"
	k.fetch, k.hands = 0, "None" -- or off the find it was going for
	return d, news
end

-- A sound counts as on a floor within this far off its map (studs: the elevator car beside the
-- lobby), and from `SoundBelow` under its floor to `SoundAbove` over it (a player's middle up on
-- the tops is about 13).
Keeper.SoundOffMap = 8
Keeper.SoundBelow = 4
Keeper.SoundAbove = 20
-- A sound more than this over the floor of the unit it's in is up on the unit's top (studs): the
-- steel is 10 up and a body lying on it about 11; a jump inside a unit reaches about 7.
Keeper.OnTop = 8.5
-- How much of a sound's reach gets out through a shut door, from inside its unit: half, as
-- Lethal Company halves how far a noise carries from inside the shut ship. Pulling the door down
-- behind you buys quiet, not silence: saw in there and a keeper still comes to stand outside it.
Keeper.Muffled = 0.5

--- Whether a sound at `p` (the floor's coordinates) is on the floor whose map is `map`.
function Keeper.onFloor(map: KeeperMap.Map, p: vector): boolean
	return p.y >= -Keeper.SoundBelow
		and p.y <= Keeper.SoundAbove
		and KeeperMap.off(map, p) <= Keeper.SoundOffMap
end

--- A sound at `p` (the floor's coordinates): where it is, on the floor of the place it's in, and
--- the spot a keeper comes to look from (clear of a unit's walls, as it searches, L-12c).
function Keeper.soundAt(map: KeeperMap.Map, p: vector): (vector, vector)
	local i = KeeperMap.placeAt(map, p)
	local at = vector.create(p.x, map.y[i], p.z)
	return at, KeeperMap.offWalls(map, at, Keeper.Against)
end

--- Where keeper `k` hears a sound at `p` (the floor's coordinates) carrying `reach` studs from:
--- the place on the map it comes from, the spot it looks from, and how far it carries from there.
--- A sound in a hall, in a unit whose door is all the way up, or in the unit the keeper itself
--- stands in is where it is (`soundAt`). One up on a unit's top carries out over its front into
--- the hall: it comes from that unit's door, with what's left of its reach once it has got there.
--- One in a unit whose door is down comes through the door the same way, `Muffled`. The keeper
--- then comes to stand in front of the door, as it does for a door's own sounds.
function Keeper.heardFrom(k: Keeper, p: vector, reach: number): (vector, vector, number)
	local map = k.map
	local i, slot = KeeperMap.placeAt(map, p)
	local at = vector.create(p.x, map.y[i], p.z)
	if slot ~= 0 and KeeperMap.placeAt(map, k.at) ~= i then
		local up = p.y - map.y[i] > Keeper.OnTop
		if up or not KeeperMap.doorOpen(map, slot) then
			local door, front = KeeperMap.doorFront(map, slot, Keeper.Front)
			local carries = if up then reach else reach * Keeper.Muffled
			return door, front, math.max(carries - flatDistance(at, door), 0)
		end
	end
	return at, KeeperMap.offWalls(map, at, Keeper.Against), reach
end

--- Keeper `k` hears a sound at `p` (the floor's coordinates) carrying `reach` studs along the
--- halls (`heardFrom`): it comes to look, waking if it slept, as for a door (`Keeper.hear`). How
--- far off it heard it along the map, or nil, and whether it's news to it. The horn, the bubble
--- wrap's pops, the keypad, a dropped tool, the saw, a crawl, the ladder and a drop (L-15).
function Keeper.heardAt(k: Keeper, p: vector, reach: number): (number?, boolean)
	local from, spot, carries = Keeper.heardFrom(k, p, reach)
	return Keeper.hear(k, from, carries, spot)
end

-- How far a wrong code's alarm carries for a keeper awake on its floor (studs): further than any
-- floor's halls (the farthest is under 400), so it reaches all of them (S2-04b).
Keeper.Anywhere = 1e6

--- A wrong code's alarm at `p` (the floor's coordinates), carrying `reach` studs as players hear
--- it (S2-04b, D-160). It calls every keeper awake on the floor, however far off, as Left 4 Dead's
--- car alarm brings the horde from all over the map: loose, it stops, turns and comes to look at
--- the keypad, then looks round there and roams (`hear`); shut in a unit, it remembers it and
--- comes once out; hunting a player it sees, it stays on them, as for any sound. Asleep, it wakes
--- only as near as the alarm carries (`heardAt`): the wrong code's own pick (`WrongCode`) says
--- which sleepers it lets out. One with no way there, or a row that hears nothing, stays put. As
--- `heardAt`: how far off it heard it along the map, or nil, and whether it's news to it.
function Keeper.alarm(k: Keeper, p: vector, reach: number): (number?, boolean)
	if k.state == "Asleep" then
		return Keeper.heardAt(k, p, reach)
	end
	return Keeper.heardAt(k, p, Keeper.Anywhere)
end

-- How far apart keepers called to one spot stand round it, feet to feet (studs, S2-07a2): the
-- Mannequin is about 2 across, so a crowd at 4 has a body's width between each and never one
-- body in another. And how far inside a place's edges each stands, its back clear of the wall.
Keeper.Spread = 4
Keeper.SpreadWall = 1.5
-- One standing this near a place round the spot is on it, and keeps it as the noise goes on.
local ON_PLACE = 0.5
-- Shut in, it takes a place after every loose one: it comes later.
local SHUT_LAST = 1e9

--[[
	Keepers called to one spot spread round it (S2-07a2), as Left 4 Dead's horde crowds round a
	car alarm instead of piling onto one point (from memory). Among `ks` (one floor's), every one
	going to the spot `spot` or standing looking from round it (`listening`), and every one shut
	in that will go there once out (`heardOut`), its `heardSpot` within `Same` of `spot`, takes its
	own place (`place`) from `KeeperMap.spread`: one already standing on a place keeps it; the rest
	take the places left, the nearest along its way first (the nearest of all gets the spot
	itself), those shut in last. A loose one walks to its place; one shut in goes there once out
	(`lookOut`). Alone, it looks from the spot itself, as it always did. Call it after a sound is
	heard. Allocates: for a sound, never a step.
]]
function Keeper.spread(ks: { Keeper }, spot: vector)
	local group: { Keeper } = {}
	for _, k in ks do
		local called = if k.state == "Trapped" then k.heardOut else k.listening
		if called and flatDistance(k.heardSpot, spot) <= Keeper.Same then
			table.insert(group, k)
		end
	end
	if #group < 2 then
		return
	end
	local places = KeeperMap.spread(group[1].map, spot, #group, Keeper.Spread, Keeper.SpreadWall)
	local taken: { boolean } = table.create(#places, false)
	local rest: { Keeper } = {}
	local far: { [Keeper]: number } = {}
	for _, k in group do
		local kept = false
		if k.state ~= "Trapped" then
			for j, p in places do
				if not taken[j] and flatDistance(k.at, p) <= ON_PLACE then
					taken[j], kept = true, true
					k.place, k.goal = p, p
					break
				end
			end
		end
		if not kept then
			table.insert(rest, k)
			far[k] = if k.state == "Trapped"
				then SHUT_LAST + flatDistance(k.at, k.doorway) + k.pathing:length(k.outside, spot)
				else k.pathing:length(k.at, spot)
		end
	end
	table.sort(rest, function(a: Keeper, b: Keeper): boolean
		return far[a] < far[b]
	end)
	local j, over = 1, 0
	for _, k in rest do
		while j <= #places and taken[j] do
			j += 1
		end
		local p: vector
		if j <= #places then
			p, taken[j] = places[j], true
		else
			-- the floor has no more room round it: the rest share the places, in turn
			p, over = places[1 + over % #places], over + 1
		end
		k.place = p
		if k.state ~= "Trapped" then
			k.goal = p
		end
	end
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
	k.burst, k.padlocked, k.heardOut, k.held = false, false, false, false
	k.listening, k.startle = false, 0
	-- a find it held stays in its arms; one it was going for or laying down waits
	k.fetch, k.hands, k.homing = 0, "None", false
	return true
end

--- Unit `index`'s door (its slot `slot`) banged down on it as a tap missed (S2-05a; the door was
--- already down to a foot as the bar ran, so it hears that bang as nobody else does). Asleep in
--- that unit, it wakes there, shut in, and pounds on the trapped clock (`trap`), as a sleeper
--- woken behind a shut door does (S2-03b). Awake in there and somehow not yet trapped, it's
--- trapped now. Whether it was.
function Keeper.wakeShut(k: Keeper, slot: Floor.Slot, index: number): boolean
	local _, unit = KeeperMap.placeAt(k.map, k.at)
	if unit ~= index then
		return false
	end
	local was: State = k.state
	if was == "Asleep" then
		k.state = "Watching"
	end
	if Keeper.trap(k, slot, index) then
		return true
	end
	k.state = was
	return false
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

--- The floor already has as many loose as it allows (true), or room again (false), S2-07a2. Held,
--- a keeper shut in gives its door one last blow at its break-out time and stands quiet, as a
--- padlocked one does (pounding on, it kept the loose ones looking at its door for good, seen in
--- Play); let go, it bursts out at once if its time is up: the quiet door was never safe. The server holds only the ones
--- a wave woke (`Waking.free`), so a wave never sets more loose than the floor's limit, as Left 4
--- Dead's director holds a special back until one of its places is free. Whether it's shut in.
function Keeper.hold(k: Keeper, held: boolean): boolean
	if k.trappedIn == 0 then
		return false
	end
	k.held = held
	return true
end

--- The door it's trapped behind is about to roll up by itself (a wrong code let it out, S2-04b):
--- it stops banging and stands quiet against it, so the door's own slow open is the scare and no
--- blow pulls the floor's keepers off the alarm. It still bursts at its break-out time, should the
--- door somehow not get up.
function Keeper.hush(k: Keeper)
	if k.state == "Trapped" then
		k.nextBang = math.huge
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
			if k.holding ~= 0 then
				roam(k) -- out with a find in its arms: it heads home with it
				return true
			elseif k.heardOut then
				k.state, k.goal, k.waited = "Going", k.place, 0
				k.listening = true
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
-- last blow and stands quiet, as it does held for the floor (`hold`) until let go. Burst,
-- it waits for the door to be all the way up (`lookOut`).
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
		if not (k.padlocked or k.held) then
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
	k.threw = false
	k.blow = "None"
	k.took, k.laid, k.robbed = 0, 0, 0
	local looked = false
	-- with a find in its arms it sees no one (S2-06b1)
	if players and k.state ~= "Asleep" and k.holding == 0 then
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
			if k.lever == "Reach" then
				-- its hand has been on the grip a beat: it drags the lever down (the server throws
				-- the box) and stands there a while holding it
				k.errand, k.threw = false, true
				k.waited, k.wait, k.lever = 0, k.row.linger, "Pull"
			elseif k.hands == "Reach" and k.row.collects then
				-- its arm has been out over the find a beat: its hands close on it (the server
				-- lifts it) and pull it in; `lying` already sent it on if the find went first
				k.holding, k.took, k.fetch = k.fetch, k.fetch, 0
				k.waited, k.wait, k.hands = 0, k.row.collects.take, "Take"
			elseif k.hands == "PutDown" then
				-- laid on its pile (the server puts it there): out for the next
				k.laid, k.holding = k.holding, 0
				roam(k)
			else
				roam(k) -- after the take, home with it (`roam`)
			end
			return true
		end
		return looked
	elseif state == "Going" and k.startle > 0 then
		-- a new sound: it stands where it heard it, turned to face it, then goes (`hear`)
		k.startle = math.max(k.startle - dt, 0)
		faceToward(k, k.heard)
		return true
	end
	-- moving along its route: hunting and searching at its top speed, else at its walk
	local hunting = state == "Hunting"
	local studs = Keeper.pace(k, run) * dt
	local collect = k.row.collects
	local grab = if collect and k.fetch ~= 0 then collect.grab else -1
	if hunting then
		studs = math.min(studs, math.max(flatDistance(k.at, k.goal) - Keeper.Close, 0))
	elseif grab >= 0 then
		-- going for a find: it stops its grab short, once it has a clear line to it
		local short = flatDistance(k.at, k.goal) - grab
		if short <= studs and KeeperMap.clear(k.map, k.at, k.goal) then
			studs = math.max(short, 0)
		end
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
	local reached = grab >= 0
		and flatDistance(after, k.goal) <= grab + GRAB_SLACK
		and KeeperMap.clear(k.map, after, k.goal)
	if hunting then
		if moved <= STUCK then
			faceToward(k, k.goal) -- at arm's length: it stands facing them
		end
		local id = if players then Keeper.catches(k, players) else 0
		local loot = if id ~= 0 and collect and players then lootOf(players, id) else 0
		if loot ~= 0 and collect then
			-- it takes rather than catches (S2-06c): its hands close on the best thing they
			-- carry (the server takes it out of their slots) and pull it in, and it goes home
			-- with it as after a fetch (Waiting, above); they're let go, not wrapped
			k.robbed, k.took, k.holding, k.target = id, loot, loot, 0
			stand(k, collect.take)
			k.hands = "Take"
		elseif id ~= 0 then
			-- its hand closes on them: it stands over the spot, then roams
			k.caught, k.target = id, 0
			stand(k, k.row.linger)
		end
	elseif (state == "Going" or state == "Searching") and (there or stuck) then
		-- there, or a door came down across its way: it looks from where it is, at the sound it
		-- heard, or, searching, at where it last saw them (on the way it was going, unless it
		-- stopped short of a unit's wall: then at the wall, or the hole they went through)
		stand(k, k.row.linger)
		faceToward(k, if state == "Going" then k.heard else k.seen)
	elseif reached and collect then
		-- at a find (S2-06b1): its arm goes out over it a beat, then it takes it (Waiting, above)
		stand(k, collect.reach)
		k.hands = "Reach"
		faceToward(k, k.goal)
	elseif there and k.homing and collect then
		-- home with it: it crouches over its pile and lays it down (Waiting, above)
		stand(k, collect.putDown)
		k.hands, k.homing = "PutDown", false
		faceToward(k, k.pile)
	elseif there and k.errand then
		-- at the box: its hand goes up on the grip and it stands a beat, so a camera watching shows
		-- it (S2-02d2), still on its errand; then it throws (Waiting, above)
		stand(k, k.errandGrip)
		k.lever = "Reach"
		faceToward(k, k.errandBox)
	elseif there then
		stand(k, k.row.roamLinger)
	elseif stuck then
		roam(k) -- a door came down across its way: it picks another place
	end
	return true
end

--- How fast it walks in its state (studs a second), `run` being a player's full run: hunting and
--- searching at its top speed, going to look, roaming and going to its door trapped at its looking
--- pace; 0 standing (startled by a sound included).
function Keeper.pace(k: Keeper, run: number): number
	local state = k.state
	if state == "Hunting" or state == "Searching" then
		return k.row.speed * run
	elseif state == "Going" and k.startle > 0 then
		return 0 -- standing where it heard a new sound, turned to it
	end
	-- its arms full it walks slower (S2-06b1)
	local collect = k.row.collects
	local laden = if collect and k.holding ~= 0 then collect.laden else 1
	if state == "Going" or state == "Roaming" then
		return k.row.speed * run * k.row.looking * laden
	elseif state == "Trapped" and flatDistance(k.at, k.goal) > ARRIVE then
		return k.row.speed * run * k.row.looking * laden -- on its way to stand against its door
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
	local collect = k.row.collects
	if state == "Hunting" then
		d = math.max(d - Keeper.Close, 0)
	elseif collect and k.fetch ~= 0 then
		d = math.max(d - collect.grab, 0) -- it stops its grab short of a find
	end
	return d
end

--- A new, empty list of players for `step`, to fill and reuse.
function Keeper.players(): Players
	return { ids = {}, at = {}, eye = {}, aim = {}, loot = {}, count = 0 }
end

--- The find in its arms is gone (S2-06b2): the server couldn't lift it, or took it from it. It
--- stands empty-handed and sets off again, for the next find or a roam.
function Keeper.dropped(k: Keeper)
	if k.holding == 0 and k.hands ~= "Take" then
		return
	end
	k.holding, k.took = 0, 0
	roam(k)
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
