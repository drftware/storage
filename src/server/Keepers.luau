--!strict
--[[
	Keepers: the keepers' brain on the server (L-06b2a, D-064), one system on the Host's clock. It
	keeps each laid floor's map (KeeperMap) in step with its doors, tells every keeper on a floor
	what it hears there, steps each one (the pure `Keeper`) and moves its body.

	- A floor joins with `add` as it's laid (FloorBuilder's `laid.slots`): its map is built once and
	  each door's state fed in as it changes (`Doors.changed` through `KeeperMap.letsThrough`), so a
	  doorway lets keepers through only while its door is all the way up. It brings a seeded Random
	  of its own, which its keepers share to pick where they roam. Its keepers go with it.
	- A floor's sleepers come with it (S2-01): the units its deal placed a keeper asleep in as it
	  was laid (`Deal.Deck.sleepers`), known before any door lifts (`sleepers`), so one can wake
	  or be let out behind a door nobody opened (S2-03, S2-04). Each leaves that list as its door
	  first lifts, when its keeper stands where the deal laid it, as below.
	- A unit dealt a keeper (`Deals.dealt`, L-06b2b) has it stood where the deal laid it as its door
	  first lifts. Asleep, it stands slack, facing as laid, until a sound wakes it. Awake, it stands
	  mid-stride, square to the doorway, and steps out to look the moment its door is all the way
	  up (D-070).
	- A door's open, slam or lift from inside (`Keeper.Hears`) reaches every keeper on its floor
	  within that sound's reach (`Doors.acted` carries DoorSound's, the one players hear by),
	  measured along the halls, so no sound goes through a wall or a shut door. A keeper that hears
	  it (waking, if it slept) walks to the door's front, stands there looking, then roams the
	  halls between noises and never goes back into a unit (L-06b3a1, D-071).
	- Each step, every floor with a keeper awake is told where each living player's feet are (in its
	  own coordinates), and its keepers look: one that sees a player hunts them, and one that loses
	  them rushes to where it last saw them, looks, and roams again (L-06b3a2). Each player's screen
	  is told how many keepers hunt them (Remotes.Hunted to them alone, `Chase`), once each time
	  that changes, for the sting and the chase bed only they hear (L-06b4b1).
	- Light freezes a keeper whose row says so (the Mannequin, L-06b3b): each step it's told
	  whether a lit hall light's pool is where it stands (`MotionLights.lightOn`), and each living
	  player's torch, from their eyes along their facing at their aim (`Flashlights`), so it
	  decides whether a light is on it (`Keeper.step`). Frozen or let go, screens hear of it at
	  once, not after the records' usual gap, so it stops on the stride it was on.
	- A hunting keeper whose hand closes on the one it hunts catches them (L-06b3c; `Keeper.step`
	  decides, by Brix's cone reach along its map). The server then jolts the caught player's
	  screen and blacks it out (Remotes.Caught to them alone, `Caught`), fires `caught` (the
	  keeper's body, the player, the floor) for what follows, and marks them kept
	  (`Kept.Attribute`): out of every keeper's sight until KeptPlayers lets them out (L-07a).
	- A door that comes down from all the way up, by a slam or a close, traps an awake keeper
	  standing in its unit (L-06b3d; `Keeper.trap`; a peek lowered over one isn't a trap). It bangs
	  on the door from inside on its clock: each blow jolts the door on its rail with a boom and a
	  shake for anyone near (`Doors.move`, "Bang"), heard by other keepers as a door is. At about
	  90 s it bursts the door up ("Burst"), loud, and goes after the last thing it heard. A
	  padlock on its door holds it: it gives one last blow and goes quiet until the padlock is cut.
	- `awakeOn` tells the deal how many keepers are loose on a floor now, for its cap: a trapped
	  one takes no place (`Keeper.loose`).
	- `hear` is any loud thing off a door (the air horn, bubble wrap's pops): each keeper on that
	  floor whose way there along the halls is inside its reach comes to look (`Keeper.heardAt`:
	  up on a unit's top it carries out over the front; behind a shut door, muffled through it).
	  The rest of the loud things players do come the same way, each as far as players hear it
	  (L-15): the keypad (`Elevators.acted`; a wrong code's alarm calls every keeper awake on its
	  floor however far, `Keeper.alarm`, S2-04b), a dropped tool landing (`Slots.landed`), the saw
	  (`Saws.sawing`), a crawl through a hole (`Crawls.crawled`), and the ladder, a crawl along the
	  tops and a drop off them or into a unit (`Ladders.climbed`). A keeper that hears a sound new to
	  it stops and turns to it first (`Keeper.hear`), stamped on its body for screens to hear
	  (`KeeperTell.HeardAttribute`); the same noise going on is heard without either.
	  `feet` lets `Wraps` see where keepers tread, without reaching in.
	- Each keeper's body is an anchored model moved by its HumanoidRootPart, with no Humanoid, its
	  joints left at rest. The server tells screens how it moves (L-06b4a): a short record on the
	  body's `KeeperMotion` attribute, sent only when its motion changes (`KeeperMotion.due`), which
	  each screen's KeeperView carries on smoothly and poses through its joints' Transform. So no
	  joint replicates, and the root moves on the server only with each record, or once it has
	  walked `REFRESH` past the last: enough to stream it to whoever is near it.
	- The brain works in the floor's own coordinates (its lobby's middle at the origin, its floor at
	  height 0); positions are turned from the world going in and back coming out.

	Each body is tagged `Keeper` and carries its row's name (`Keeper` attribute) for screens. In
	Studio, Output says what each keeper hears, sees and does, and each body carries its state as
	the attribute `KeeperState`. `stand` puts a keeper on a laid floor (the dev command's). In
	Studio only, `ServerStorage.CatchTest` (a BindableFunction, server-side, so no client reaches
	it) has the standing keeper nearest a player catch them wherever they are, through the real
	catch: `Invoke(player)` returns "Caught", or why not (docs/STUDIO.md).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Breaker = require(ReplicatedStorage.Shared.Breaker)
local Breakers = require(script.Parent.Breakers)
local Brix = require(ReplicatedStorage.Brix)
local Catalog = require(ReplicatedStorage.Shared.Tools.Catalog)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Chase = require(ReplicatedStorage.Shared.Chase)
local Climb = require(ReplicatedStorage.Shared.Climb)
local Deal = require(ReplicatedStorage.Shared.Deal)
local FloorRules = require(ReplicatedStorage.Shared.FloorRules)
local Crawls = require(script.Parent.Crawls)
local Deals = require(script.Parent.Deals)
local Feed = require(ReplicatedStorage.Shared.Feed)
local Feeds = require(script.Parent.Feeds)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Dent = require(ReplicatedStorage.Shared.StorageUnit.Dent)
local Doors = require(script.Parent.Doors)
local Elevators = require(script.Parent.Elevators)
local Flashlights = require(script.Parent.Flashlights)
local Floor = require(ReplicatedStorage.Shared.Floor)
local FloorBuilder = require(script.Parent.FloorBuilder)
local Horn = require(ReplicatedStorage.Shared.Tools.Horn)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Keeper = require(ReplicatedStorage.Shared.Keeper)
local Torch = require(ReplicatedStorage.Shared.Flashlight.Torch)
local KeeperMap = require(ReplicatedStorage.Shared.KeeperMap)
local KeeperMotion = require(ReplicatedStorage.Shared.KeeperMotion)
local KeeperRows = require(ReplicatedStorage.Shared.KeeperRows)
local KeeperTell = require(ReplicatedStorage.Shared.KeeperTell)
local Ladders = require(script.Parent.Ladders)
local Mannequin = require(ReplicatedStorage.Shared.Mannequin)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local MotionLights = require(script.Parent.MotionLights)
local Packed = require(ReplicatedStorage.Shared.Packed)
local Packrat = require(ReplicatedStorage.Shared.Packrat)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Saws = require(script.Parent.Saws)
local Slots = require(script.Parent.Slots)
local Waking = require(ReplicatedStorage.Shared.Waking)
local WrongCode = require(ReplicatedStorage.Shared.WrongCode)

local TRACE = RunService:IsStudio() -- Output says what each keeper hears and does
-- Workspace's attribute the dev command sets (Studio only): every loose Mannequin heads for its
-- floor's breaker box now, the power's gap ignored (S2-02c)
local DEV_ERRAND = "SendToBreaker"
-- Studio only: set this Workspace attribute true and every floor with someone on it skips ahead to
-- its first wave of sleepers waking (S2-03b), so a test needn't wait four minutes.
local DEV_WAKE = "WakeSleepers"
-- Seconds between looks for a floor's breaker box until it's found (it hangs as the floor lays)
local BOX_LOOK = 1
local STATE_ATTRIBUTE = "KeeperState"
local MOTION_ATTRIBUTE = "KeeperMotion" -- its motion, for screens (KeeperMotion.encode)
local ROW_ATTRIBUTE = "Keeper" -- its row's name: how screens pose it
local TAG = "Keeper"
-- How far a walking keeper gets from where the server last put its root before the server moves
-- the root again (studs). Screens show it where its records say; the server's root is only what
-- streams it to players near it and what Studio's server view shows.
local REFRESH = 8
-- Moved less than this in a step (studs), it's standing.
local STILL = 1e-6
-- Where a torch's beam leaves from with no head to measure: this far over the root's middle (an
-- R15 head's middle, about where a first-person camera looks from).
local EYE_OVER_ROOT = 1.5

-- What each keeper's body is: a copy of its template, its joints at rest for screens to turn,
-- not yet in the world.
type Kit = {
	clone: (pivot: CFrame) -> Model?,
}
local KITS: { [string]: Kit } = {
	Mannequin = {
		clone = function(pivot: CFrame): Model?
			local body = Mannequin.clone(pivot, nil)
			if body then
				Mannequin.rest(body)
			end
			return body
		end,
	},
	Packrat = {
		clone = function(pivot: CFrame): Model?
			local body = Packrat.clone(pivot, nil)
			if body then
				Packrat.rest(body)
			end
			return body
		end,
	},
}
-- Where the Packrat lays each find on its pile (S2-06b2), studs across and back from the pile's
-- middle as it faces it, tried in turn from the next: a small heap, not one spot. A dealt pile
-- (S2-06b2b) already lies round its middle, so the ring goes on round it.
local PILE: { { number } } = {
	{ 0, 0 },
	{ -1.3, 0.4 },
	{ 1.3, 0.4 },
	{ -0.6, 1.4 },
	{ 0.7, 1.5 },
	{ -2.2, -0.4 },
	{ 2.2, -0.4 },
	{ -1.9, 1.5 },
	{ 1.9, 1.6 },
	{ 0, -1.2 },
}
-- A spot on the pile with no find lying within this (studs, middle to middle) is free: about a
-- boombox's width, so a laid find sits beside what's there rather than in it.
local PILE_CLEAR = 1.6
-- How far round a pile spot's middle must still be in its own unit (studs, across and along as it
-- faces): about half the widest find, so none is laid through a wall.
local PILE_SIDE, PILE_DEEP = 1, 0.6

-- Output's words for what it does next.
local DOING: { [Keeper.State]: string } = {
	Asleep = "sleeps",
	Watching = "stands still, watching",
	Going = "goes to look",
	Waiting = "stands there, looking",
	Roaming = "wanders off down the halls",
	Hunting = "hunts",
	Searching = "rushes to where it last saw them",
	Trapped = "is trapped",
}
local HEARD: { [string]: string } = {
	Open = "open",
	Slam = "slam",
	LiftInside = "lift from inside",
	Bang = "bang",
	Burst = "burst open",
	Drop = "bang down as a tap missed",
}
-- What Output calls each of the rest of the noises players make (L-15).
local KEYPAD: { [Elevators.Action]: string } = {
	Press = "a keypad beep",
	Clear = "a keypad beep",
	Wrong = "a wrong code's alarm",
	Right = "the keypad's chime",
}
local CLIMB: { [string]: string } = {
	Raise = "a ladder going up",
	Up = "someone climbing a ladder",
	Down = "someone climbing down a ladder",
	Crawl = "a crawl along the tops",
	Drop = "a drop off a top",
	In = "a drop into a unit",
}
-- A wall's hole is heard from the side it's sawn or crawled from: this far into that unit (studs),
-- off the wall's line between the two.
local SIDE_IN = 1

type Body = {
	model: Model,
	root: BasePart,
	rootOffset: CFrame, -- from the body's pivot (its feet) to its root part
	motion: KeeperMotion.Record?, -- the last record screens were sent, as they read it
	placed: vector, -- where the server last put its root (the floor's coordinates)
}
-- What stood a sleeper up awake behind its shut door early.
type Woken = "Wave" | "Code"
type OnFloor = {
	floor: Floor.Floor,
	map: KeeperMap.Map,
	random: Floor.Random, -- the floor's own, for its keepers' roams
	origin: CFrame, -- the lobby's middle on the floor: the map's origin
	slots: { [Model]: number }, -- each unit, its slot in the floor
	units: { [number]: Model }, -- and back: each slot's unit
	model: Model,
	folder: Folder, -- its keepers' bodies
	keepers: { Entry },
	-- the keepers asleep behind doors never lifted (S2-01): each unit's slot, its keeper's name
	asleep: { [number]: string },
	players: Keeper.Players, -- where each living player's feet are this step, reused
	gone: RBXScriptConnection,
	box: Model?, -- its breaker box (S2-02c), once found
	boxAt: vector, -- the box on the wall, the floor's coordinates: a Mannequin faces it there
	boxStand: vector, -- where a Mannequin stands to throw it (`Breaker.stand`)
	boxLooked: number, -- when it last looked for the box, the server's clock
	cut: boolean, -- a Mannequin has thrown the box on this floor (Breaker.ErrandFirst until then)
	-- seconds since the first player stood on the floor (S2-03b), -1 until anyone has: what
	-- `Waking` counts its waves from
	here: number,
	woken: number, -- how many of its sleepers have woken
	-- slots dealt early to wake, standing awake and shut in: woken by a wave (S2-03b) or let out
	-- by a wrong code (S2-04a)
	waking: { [number]: Woken },
	-- the players who rode out of it as its gate shut (S2-02d4): off it for its cameras, though
	-- their car climbs level with it for a while
	left: { [Player]: boolean },
	finds: Keeper.Finds, -- the finds lying loose on it (S2-06b2), the Packrat's to fetch; reused
}
-- `quarry`: whom it hunted as last counted for screens (`tellHunted`), 0 for no one.
-- `feed`: the security camera feed showing it walk up to throw the breaker (S2-02d), 0 for none.
-- `woke`: a wave woke it behind its shut door and it's still shut in there (S2-03b): the floor's
-- limit on loose keepers holds it in past its time (`holdWoken`, S2-07a2).
type Entry = {
	keeper: Keeper.Keeper,
	body: Body,
	on: OnFloor,
	quarry: number,
	feed: number,
	woke: boolean,
	piled: number, -- how many finds it has laid on its pile (S2-06b2)
}

-- A keeper caught a player: its body, whom it caught, and the floor's model (FloorBuilder's).
export type Catch = { body: Model, player: Player, floor: Model }

export type Keepers = Brix.System & {
	-- A keeper caught a player (L-06b3c), fired once per catch, after the caught player's screen
	-- has been told: what L-07's getting kept takes. Until then DevCorridor's stand-in does.
	caught: Brix.Signal<Catch>,
	-- Lays a floor's map for keepers to walk as FloorBuilder lays it: `slots` maps each unit to its
	-- slot (`laid.slots`), `origin` is where it was laid, and `random` (a fresh Brix Random from the
	-- floor's seed, not the deal's, so roams never change what the units hold) picks where its
	-- keepers roam. `asleep` is its deal's sleepers (`Deal.Deck.sleepers`: each unit's slot, its
	-- keeper's name), behind doors nobody has lifted yet. `packed` is its deal's packed units
	-- (`Deal.Deck.packed`, B-05b2): keepers walk their path and turn at the bend. Its keepers go
	-- when `model` is destroyed.
	add: (
		self: any,
		floor: Floor.Floor,
		slots: { [Model]: number },
		model: Model,
		origin: CFrame,
		random: Floor.Random,
		asleep: { [number]: string },
		packed: { [number]: boolean }?
	) -> (),
	-- `riders` rode out of laid floor `model` as its gate shut (Climbs' `shut`, S2-02d4): from now
	-- on they aren't on it for its security cameras though their car climbs level with it for a
	-- while, any of its feeds showing to them cuts out on their screens at once, and once nobody's
	-- on it its Mannequins stop setting off for its breaker.
	left: (self: any, model: Model, riders: { Player }) -> (),
	-- The units on laid floor `model` whose keeper has slept behind its shut door since the floor
	-- was laid (S2-01), each with its keeper's name: what S2-03 wakes and S2-04's wrong code lets
	-- out. Empty off any keepers' floor. A new table each call.
	sleepers: (self: any, model: Model) -> { [Model]: string },
	-- Stands a keeper (its row's name) on a laid floor, feet at `at`, facing `facing` (the world's),
	-- asleep unless `awake`. Returns its body, or nil (an unknown floor or keeper, or no template:
	-- Output says).
	stand: (
		self: any,
		name: string,
		model: Model,
		at: Vector3,
		facing: Vector3,
		awake: boolean?
	) -> Model?,
	-- A loud sound at `at` (the world's), heard by every keeper on the floor it's on as far as
	-- `reach` studs along the halls (L-14b2b): each comes to look where it was, waking if it slept
	-- (`Keeper.heardAt`). `what` names it in Output ("an air horn"). How many heard it.
	hear: (self: any, at: Vector3, reach: number, what: string) -> number,
	-- A blast of the air horn at `at` (the world's): `hear` as far as `Horn.Reach` (L-14a2).
	hearHorn: (self: any, at: Vector3) -> number,
	-- Calls `each` with every keeper's body and where its feet are (the world's), on every floor.
	-- Bubble wrap's pops read it (`Wraps`). Allocates nothing.
	feet: (self: any, each: (body: Model, at: Vector3) -> ()) -> (),
	-- How many keepers are loose now on the floor `unit` is on (0 off any keepers' floor): awake
	-- and not trapped behind a door. The deal's cap counts these (the floor rules' `awake`).
	awakeOn: (self: any, unit: Model) -> number,
	-- The keeper standing loose in `unit` (S2-05a, the tap): whether it's asleep, nil when none
	-- stands there, and whether it has seen `player` (it hunts them).
	inside: (self: any, unit: Model, player: Player) -> (boolean?, boolean),
	-- `unit`'s door banged down as its tap missed (S2-05a): its sleeper wakes shut in and pounds
	-- (`Keeper.wakeShut`). Whether one did.
	wakeShut: (self: any, unit: Model) -> boolean,
	-- Takes a keeper off its floor and destroys its body.
	remove: (self: any, body: Model) -> (),
	-- A spot in a hall about `studs` from a laid floor's lobby along the halls, and the way back
	-- toward the lobby from it (the world's): where a test stands a keeper "two halls off".
	hallOff: (self: any, model: Model, studs: number) -> (Vector3?, Vector3?),
}

local Keepers = {}

function Keepers.new(): Keepers
	local floors: { [Model]: OnFloor } = {}
	local floorOf: { [Model]: OnFloor } = {} -- each unit's floor
	-- doors a wrong code is rolling up (S2-04b): their open is the alarm's, and keepers it already
	-- turned for the keypad don't turn again for it; each leaves once all the way up
	local rolling: { [Model]: boolean } = {}
	local connections: { Brix.SignalConnection } = {}
	local doors: Doors.Doors? = nil
	local motionLights: MotionLights.MotionLights? = nil
	local flashlights: Flashlights.Flashlights? = nil
	local breakers: Breakers.Breakers? = nil
	local feeds: Feeds.Feeds? = nil
	local deals: Deals.Deals? = nil
	local devErrand = false -- the dev command: every loose Mannequin goes for the box now
	local toolSlots: Slots.Slots? = nil -- where every find lies (S2-06b2)
	local looseDirty = true -- the finds lying loose, or a door, changed: the Packrats are told
	local run = 16 -- a player's full run, studs a second (StarterPlayer's, read at start)
	local everyone: { Player } = {} -- kept as players come and go: no list made each step
	local caught = Brix.Signal.new() :: Brix.Signal<Catch>
	local caughtRemote: RemoteEvent? = nil
	local huntedRemote: RemoteEvent? = nil
	local catchTest: BindableFunction? = nil
	-- Whom keepers hunt: each player's screen is told how many keepers hunt them (Chase), once each
	-- time that changes. `recount` says a keeper's quarry may have changed since the last telling.
	local hunters: { [number]: number } = {} -- player id to keepers hunting them (reused)
	local told: { [Player]: number } = {} -- what each player's screen last heard
	local recount = false
	local joins: { RBXScriptConnection } = {}

	-- Where each living player's feet are on floor `on`, in its own coordinates, and their torch:
	-- from their eyes (their head), along where their screen last said it looks (its heading and
	-- pitch; before it has said, the way their character faces, tipped up by their pitch); a zero
	-- aim while it's off. Allocates nothing.
	local function gather(on: OnFloor, _now: number)
		local list = on.players
		local origin = on.origin
		local n = 0
		for _, player in everyone do
			if player:GetAttribute(Kept.Attribute) == true then
				continue -- kept: out of every keeper's sight until they're let out
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				local p = origin:PointToObjectSpace(root.Position)
				n += 1
				list.ids[n] = player.UserId
				list.at[n] = vector.create(p.X, p.Y - humanoid.HipHeight - root.Size.Y / 2, p.Z)
				local aim = vector.zero
				if flashlights and flashlights:isOn(player) then
					local head = (character :: Model):FindFirstChild("Head")
					local eye = if head and head:IsA("BasePart")
						then origin:PointToObjectSpace(head.Position)
						else p + Vector3.yAxis * EYE_OVER_ROOT
					list.eye[n] = vector.create(eye.X, eye.Y, eye.Z)
					local heading = flashlights:heading(player)
					if heading then
						-- where their screen looks, as it last said: their character's turn
						-- reaches the server late and eased in (Flashlights)
						local w = Torch.look(flashlights:aim(player), heading)
						local d = origin:VectorToObjectSpace(Vector3.new(w.x, w.y, w.z))
						aim = vector.create(d.X, d.Y, d.Z)
					else
						local look = root.CFrame.LookVector
						local across = math.sqrt(look.X * look.X + look.Z * look.Z)
						if across > 1e-6 then
							local up = math.rad(flashlights:aim(player))
							local c = math.cos(up) / across
							local d = origin:VectorToObjectSpace(
								Vector3.new(look.X * c, math.sin(up), look.Z * c)
							)
							aim = vector.create(d.X, d.Y, d.Z)
						end
					end
				end
				list.aim[n] = aim
				-- what the Packrat would take from them if it reached them (S2-06c)
				local loot = list.loot
				if loot then
					loot[n] = if toolSlots then toolSlots:prize(player) else 0
				end
			end
		end
		list.count = n
	end

	-- Output: a light froze a keeper, or let it go.
	local function traceLight(entry: Entry)
		local k = entry.keeper
		if k.lit == 0 then
			print(`Keepers: the {k.row.name} walks on`)
		elseif k.lit == Keeper.HallLight then
			print(`Keepers: the {k.row.name} freezes in the light`)
		else
			local player = Players:GetPlayerByUserId(k.lit)
			local whose = if player then `{player.Name}'s` else `player {k.lit}'s`
			print(`Keepers: the {k.row.name} freezes in {whose} torch`)
		end
	end

	-- Output: a keeper saw someone, or lost the one it hunted (`was`, their id).
	local function traceSight(entry: Entry, was: number)
		local k = entry.keeper
		local id = if k.target ~= 0 then k.target else was
		local player = Players:GetPlayerByUserId(id)
		local who = if player then player.Name else `player {id}`
		if k.target ~= 0 then
			local dx, dz = k.seen.x - k.at.x, k.seen.z - k.at.z
			local off = math.round(math.sqrt(dx * dx + dz * dz))
			print(`Keepers: the {k.row.name} sees {who}, {off} studs off, and comes at them`)
		elseif k.fetch ~= 0 then
			-- a find nearer than them, lying in its path (S2-06c2)
			print(`Keepers: the {k.row.name} turns off {who} for the find in its path`)
		else
			print(`Keepers: the {k.row.name} lost {who}; it rushes to where it last saw them`)
		end
	end

	-- A keeper caught player `id`: the jolt on their screen, Output's line, and `caught`, unless
	-- they're already kept (two keepers' hands closing in one step, or a catch while kept).
	local function catch(entry: Entry, id: number)
		local player = Players:GetPlayerByUserId(id)
		if not player then
			return
		end
		if player:GetAttribute(Kept.Attribute) == true then
			return
		end
		player:SetAttribute(Kept.Attribute, true)
		if caughtRemote then
			-- its body, so their screen throws that face at them (CaughtView)
			caughtRemote:FireClient(player, entry.body.model)
		end
		if TRACE then
			print(`Keepers: the {entry.keeper.row.name} catches {player.Name}`)
		end
		caught:fire({ body = entry.body.model, player = player, floor = entry.on.model })
	end

	-- Puts its body's root where the brain has it.
	local function putRoot(entry: Entry)
		local k, body = entry.keeper, entry.body
		-- any: the brain's vector is a Vector3 here, which the checker won't cast
		local at = (k.at :: any) :: Vector3
		local facing = (k.facing :: any) :: Vector3
		body.root.CFrame = entry.on.origin * CFrame.lookAt(at, at + facing) * body.rootOffset
		body.placed = k.at
	end

	-- Tells screens how it moves, walking at `speed` (0 standing), if that changed enough for a new
	-- record (`KeeperMotion.due`), or `now` (a light froze it or let it go); screens carry it on
	-- between records. The root follows each record, and between them once it has walked `REFRESH`
	-- from where it was put.
	local function publish(entry: Entry, speed: number, now: boolean)
		local k, body = entry.keeper, entry.body
		local origin = entry.on.origin
		-- any: as in `putRoot`
		local p = origin:PointToWorldSpace((k.at :: any) :: Vector3)
		local d = origin:VectorToWorldSpace((k.facing :: any) :: Vector3)
		local at, facing = vector.create(p.X, p.Y, p.Z), vector.create(d.X, 0, d.Z)
		local t = Workspace:GetServerTimeNow()
		local state = Keeper.shown(k) -- its hand on a breaker's lever shows (S2-02d2)
		if now or KeeperMotion.due(body.motion, t, at, facing, speed, state) then
			local left = if speed > 0 then Keeper.left(k) else 0
			local encoded = KeeperMotion.encode(t, at, facing, speed, left, k.travelled, state)
			local motion = body.motion or KeeperMotion.record()
			-- kept as screens read it, rounding and all, so `due` foresees exactly what they show
			KeeperMotion.decode(encoded, motion)
			body.motion = motion
			body.model:SetAttribute(MOTION_ATTRIBUTE, encoded)
			putRoot(entry)
		else
			local dx, dz = k.at.x - body.placed.x, k.at.z - body.placed.z
			if dx * dx + dz * dz > REFRESH * REFRESH then
				putRoot(entry)
			end
		end
	end

	local function changedState(entry: Entry, was: Keeper.State)
		local state: Keeper.State = entry.keeper.state
		if state == was then
			return
		end
		entry.body.model:SetAttribute(STATE_ATTRIBUTE, state)
		-- its stops on a roam go unsaid: each roam's start is enough; seeing and losing someone
		-- are said by `traceSight`
		if
			TRACE
			and state ~= "Going"
			and state ~= "Hunting"
			and state ~= "Searching"
			and not (state == "Waiting" and was == "Roaming")
		then
			local k = entry.keeper
			local doing = if state == "Waiting" and was == "Searching"
				then "stands where it lost them, looking about"
				elseif
					state == "Waiting"
					and was == "Hunting"
					and k.hands == "Take"
				then "pulls in what it took" -- S2-06c: robbed, not caught
				elseif
					state == "Waiting" and was == "Hunting"
				then "stands over where it caught them"
				elseif
					state == "Trapped" and k.trappedIn ~= 0
				then `is trapped in Unit {entry.on.floor.slots[k.trappedIn].number}; it bangs on the door until it bursts out at {k.row.breakOut} s`
				else DOING[state]
			print(`Keepers: the {entry.keeper.row.name} {doing}`)
		end
	end

	local function release(entry: Entry)
		Keeper.release(entry.keeper)
		entry.body.model:Destroy()
	end

	local function drop(on: OnFloor)
		if floors[on.model] ~= on then
			return
		end
		floors[on.model] = nil
		on.gone:Disconnect()
		for unit in on.slots do
			if floorOf[unit] == on then
				floorOf[unit] = nil
			end
			rolling[unit] = nil
		end
		for _, entry in on.keepers do
			release(entry)
		end
		table.clear(on.keepers)
		on.folder:Destroy()
		recount = true
	end

	-- Counts whom every keeper hunts and tells each player whose number changed: the sting and the
	-- chase bed on their screen alone (Chase). Only after a keeper's quarry changed.
	local function tellHunted()
		recount = false
		table.clear(hunters)
		for _, on in floors do
			for _, entry in on.keepers do
				local id = entry.keeper.target
				if id ~= 0 then
					hunters[id] = (hunters[id] or 0) + 1
				end
			end
		end
		for _, player in everyone do
			local n = hunters[player.UserId] or 0
			if (told[player] or 0) ~= n then
				told[player] = n
				if huntedRemote then
					huntedRemote:FireClient(player, n)
				end
			end
		end
	end

	-- Keeper `entry` heard `what`, `off` studs away along the halls; `news` if it's a sound it
	-- wasn't already going to (Keeper.hear). News is said in Output and stamped on its body, so
	-- every screen plays it stopping and turning to the sound (KeeperSounds' Heard beat); the same
	-- noise going on (a code's presses, a crawl's pulls) is neither. No `what`: the caller says it
	-- in one line for all of them (a wrong code's alarm).
	local function heardIt(
		entry: Entry,
		was: Keeper.State,
		what: string?,
		off: number,
		news: boolean
	)
		local k = entry.keeper
		if news and k.state ~= "Trapped" then
			entry.body.model:SetAttribute(KeeperTell.HeardAttribute, Workspace:GetServerTimeNow())
		end
		if TRACE and news and what then
			local doing = if k.state == "Trapped"
				then "it'll go there once out"
				elseif was == "Asleep" then "it wakes, turns to it and goes to look"
				else "it stops, turns to it and goes to look"
			print(
				`Keepers: the {k.row.name} heard {what} {math.round(off)} studs off along the halls; {doing}`
			)
		end
		changedState(entry, was)
	end

	-- Keepers on floor `on` called to one spot spread round it, each to its own place
	-- (`Keeper.spread`, S2-07a2): once for each of `spots` (where those that heard a sound look
	-- from), spots within `Keeper.Same` of one already done skipped. For a sound, never a step.
	local function spreadRound(on: OnFloor, spots: { vector })
		local ks: { Keeper.Keeper } = table.create(#on.keepers)
		for _, entry in on.keepers do
			table.insert(ks, entry.keeper)
		end
		local done: { vector } = {}
		for _, spot in spots do
			local again = false
			for _, d in done do
				local dx, dz = spot.x - d.x, spot.z - d.z
				again = again or dx * dx + dz * dz <= Keeper.Same * Keeper.Same
			end
			if not again then
				table.insert(done, spot)
				Keeper.spread(ks, spot)
			end
		end
	end

	-- A door made a sound: every keeper on its floor that hears it goes to look; not at the open
	-- of a door a wrong code rolls up (`rolling`), which is the alarm's.
	local function onActed(event: Doors.DoorEvent)
		local motion = event.motion
		if not (motion and Keeper.Hears[motion]) or (motion == "Open" and rolling[event.unit]) then
			return
		end
		local on = floorOf[event.unit]
		if not on then
			return -- a unit on no keepers' floor (the test hall's)
		end
		local slot = on.floor.slots[on.slots[event.unit]]
		local spot, door = Keeper.front(slot)
		local what = `Unit {slot.number}'s door {HEARD[motion]}`
		local any = false
		for _, entry in on.keepers do
			local was: Keeper.State = entry.keeper.state
			local heard, news = Keeper.hear(entry.keeper, door, event.reach, spot)
			if heard then
				any = true
				heardIt(entry, was, what, heard, news)
			end
		end
		if any then
			spreadRound(on, { spot })
		end
	end

	-- A loud thing at `at` (the world's), carrying `reach` studs: every keeper on the floor it's on
	-- that hears it comes to look (Keeper.heardAt), but `maker`, the one that made it. How many
	-- heard it.
	local function hearAt(at: Vector3, reach: number, what: string, maker: Entry?): number
		local count = 0
		for _, on in floors do
			local p = on.origin:PointToObjectSpace(at)
			local here = vector.create(p.X, p.Y, p.Z)
			if not Keeper.onFloor(on.map, here) then
				continue
			end
			local spots: { vector }? = nil
			for _, entry in on.keepers do
				if entry == maker then
					continue
				end
				local was: Keeper.State = entry.keeper.state
				local heard, news = Keeper.heardAt(entry.keeper, here, reach)
				if heard then
					count += 1
					heardIt(entry, was, what, heard, news)
					spots = spots or {}
					table.insert(spots :: { vector }, entry.keeper.heardSpot)
				end
			end
			if spots then
				spreadRound(on, spots)
			end
		end
		return count
	end

	-- `at` moved `SIDE_IN` studs toward `unit`'s middle, across the floor: a sound on the wall
	-- between two units, heard from `unit`'s side.
	local function sideOf(at: Vector3, unit: Model): Vector3
		local toward = (unit:GetPivot().Position - at) * Vector3.new(1, 0, 1)
		if toward.Magnitude < 1e-3 then
			return at
		end
		return at + toward.Unit * SIDE_IN
	end

	--[[
		The `nth` wrong code on floor `on` (S2-04): it rolls up that many units with a monster in
		them by themselves (`WrongCode`), sleepers first, then ones holding one awake behind a shut
		door; never a padlocked one. A picked sleeper is stood awake and shut in at once, as a
		waking one is (`dealShut`, `onDealt`), so it hears the alarm with the rest and comes for
		the keypad as its door goes up. Every picked one stands quiet behind its door (`Keeper.hush`),
		and keepers don't go to look at the doors' opens (`rolling`): either would pull the floor
		off the alarm. The doors start rolling one after another
		once the alarm has sounded (`WrongCode.rollAt`), each the slow, loud open players know. The
		numbers of
		the units it rolls up, for Output.
	]]
	local function letOut(on: OnFloor, nth: number): { string }
		local said: { string } = {}
		local d, dl = doors, deals
		if not (d and dl) then
			return said
		end
		local asleep: { number } = {}
		for slot in on.asleep do
			local unit = on.units[slot]
			if unit and d:stateOf(unit) ~= "Locked" then
				table.insert(asleep, slot)
			end
		end
		local held: { number } = {}
		local awake = 0
		for _, entry in on.keepers do
			local k = entry.keeper
			if Keeper.awake(k) then
				awake += 1
			end
			local index = k.trappedIn
			local unit = on.units[index]
			if index ~= 0 and not k.padlocked and unit and not table.find(held, index) then
				if d:stateOf(unit) ~= "Locked" then
					table.insert(held, index)
				end
			end
		end
		table.sort(asleep) -- fixed orders, so the floor's Random alone decides the pick
		table.sort(held)
		local random = on.random
		local picked = WrongCode.pick(
			asleep,
			held,
			nth,
			Waking.AwakeMost - awake,
			function(k: number): number
				return random:nextInteger(1, k)
			end
		)
		for i, slot in picked do
			local unit = on.units[slot]
			if on.asleep[slot] then
				on.asleep[slot] = nil
				on.waking[slot] = "Code"
				if not dl:dealShut(unit) then
					on.waking[slot] = nil
				end
			end
			for _, entry in on.keepers do
				if entry.keeper.trappedIn == slot then
					Keeper.hush(entry.keeper) -- its door goes up by itself: no blow on it first
				end
			end
			task.delay(WrongCode.rollAt(i), function()
				local dd = doors
				if dd and unit.Parent then
					rolling[unit] = true
					if not dd:move(unit, "Open") then
						rolling[unit] = nil
					end
				end
			end)
			table.insert(said, tostring(on.floor.slots[slot].number))
		end
		return said
	end

	-- A wrong code's alarm at `at` (the world's) on floor `on`, carrying `reach` (S2-04b): every
	-- keeper awake on that floor turns for the keypad, however far off (`Keeper.alarm`); a sleeper
	-- wakes to it only within `reach`. How many come now, and how many once out of the unit
	-- they're shut in.
	local function alarm(on: OnFloor, at: Vector3, reach: number): (number, number)
		local p = on.origin:PointToObjectSpace(at)
		local here = vector.create(p.X, p.Y, p.Z)
		local now, later = 0, 0
		local spots: { vector } = {}
		for _, entry in on.keepers do
			local k = entry.keeper
			local was: Keeper.State = k.state
			local heard, news = Keeper.alarm(k, here, reach)
			if heard then
				if k.state == "Trapped" then
					later += 1
				else
					now += 1
				end
				heardIt(entry, was, nil, heard, news)
				table.insert(spots, k.heardSpot)
			end
		end
		spreadRound(on, spots) -- they come to stand round the keypad, each in its own place
		return now, later
	end

	-- The rest of the noises players make (L-15), each heard as far as players hear it. A wrong
	-- code lets monsters out first, so the ones it stands up hear its alarm too; then the alarm
	-- calls every monster awake on its floor. One Output line a wrong code.
	local function onKeypad(event: Elevators.KeypadEvent)
		if event.action == "Wrong" and event.floor then
			for _, on in floors do
				if on.model == event.floor then
					local nth = event.wrongs
					local said = letOut(on, nth)
					local now, later = alarm(on, event.at, event.reach)
					if TRACE then
						local rolled = if #said > 0
							then `Units {table.concat(said, ", ")} roll up`
							else "nothing shut in to let out"
						print(
							`Keepers: wrong code {nth} on floor {on.floor.number}: {rolled}; {now} monsters turn for the keypad, {later} more once out; the keypad is dead {Keypad.dead(
								nth
							)} s`
						)
					end
					return
				end
			end
		end
		hearAt(event.at, event.reach, KEYPAD[event.action])
	end
	local function onLanded(event: Slots.Landed)
		local row = Catalog[event.key]
		hearAt(event.at, event.reach, `{string.lower(if row then row.name else event.key)} dropped`)
	end
	local function onSawing(event: Saws.SawEvent)
		local what = if not event.done
			then "a saw starting"
			elseif event.kind == "Top" then "a sawn top crashing in"
			else "a sawn wall falling"
		local at = if event.kind == "Top" then event.at else sideOf(event.at, event.from)
		hearAt(at, event.reach, what)
	end
	local function onCrawled(event: Crawls.CrawlEvent)
		hearAt(sideOf(event.at, event.from), event.reach, "a crawl through a hole")
	end
	local function onClimbed(event: Ladders.ClimbEvent)
		hearAt(event.at, event.reach, CLIMB[event.kind] or "a ladder")
	end

	-- Unit `index`'s door on floor `on` is all the way up: an awake keeper standing in it steps out
	-- to look.
	local function lookOut(on: OnFloor, index: number)
		local slot = on.floor.slots[index]
		for _, entry in on.keepers do
			local k = entry.keeper
			local was: Keeper.State = k.state
			if Keeper.lookOut(k, slot, index) then
				if TRACE then
					local doing = if was == "Trapped" and k.listening
						then "goes after what it heard shut in"
						else "steps out to look"
					print(`Keepers: Unit {slot.number}'s door is up; the {k.row.name} {doing}`)
				end
				changedState(entry, was)
			end
		end
	end

	-- Unit `index`'s door on floor `on` came down from all the way up: an awake keeper standing in
	-- it is trapped.
	local function trap(on: OnFloor, index: number)
		local slot = on.floor.slots[index]
		for _, entry in on.keepers do
			local k = entry.keeper
			local was: Keeper.State = k.state
			if Keeper.trap(k, slot, index) then
				changedState(entry, was)
			end
		end
	end

	-- A door's state changed: its doorway lets keepers through only while it's all the way up. One
	-- that was up and comes down traps whoever is in its unit; a padlock on it holds them.
	local function onChanged(change: Doors.DoorChange)
		local on = floorOf[change.unit]
		if on then
			local index = on.slots[change.unit]
			local through = KeeperMap.letsThrough(change.state)
			looseDirty = true -- a find behind it may now be reachable, or not
			local wasOpen = KeeperMap.doorOpen(on.map, index)
			KeeperMap.setDoor(on.map, index, through)
			if through then
				rolling[change.unit] = nil
				lookOut(on, index)
			elseif wasOpen then
				trap(on, index)
			end
			local locked = change.state == "Locked"
			for _, entry in on.keepers do
				if entry.keeper.trappedIn == index and entry.keeper.padlocked ~= locked then
					Keeper.padlock(entry.keeper, locked)
					if TRACE then
						local how = if locked then "padlocked: it'll never get out" else "unlocked"
						print(`Keepers: Unit {on.floor.slots[index].number}'s door is {how}`)
					end
				end
			end
		end
	end

	-- A trapped keeper hit its door from inside, burst it up, or gave its padlocked door one last
	-- blow: the door answers on every screen, and keepers that hear it come to look.
	-- The floor's breaker box (S2-02c), found once it hangs (it's hung as the floor lays): where
	-- it is and where a Mannequin stands to throw it, in the floor's coordinates.
	local function findBox(on: OnFloor, now: number): Model?
		local box = on.box
		if box and box.Parent then
			return box
		end
		local b = breakers
		if not b or now - on.boxLooked < BOX_LOOK then
			return nil
		end
		on.boxLooked = now
		on.box = nil
		local found = b:within(on.model)[1]
		if not found then
			return nil
		end
		local frame = on.origin:ToObjectSpace(found:GetPivot())
		local p, look = frame.Position, frame.LookVector -- it looks into the hall
		local out = Vector3.new(look.X, 0, look.Z)
		if out.Magnitude < 1e-3 then
			return nil
		end
		out = out.Unit
		on.box = found
		on.boxAt = vector.create(p.X, 0, p.Z)
		on.boxStand = Breaker.stand(p.X, p.Z, out.X, out.Z)
		return found
	end

	-- Whether `player` is on floor `on` for its security cameras (S2-02d): within 40 studs of its
	-- level and over its plan, and not one who rode out of it as its gate shut (S2-02d4: their car
	-- climbs level with it for a while, and would pass). Kept players count: they're on it, shut
	-- in. Allocates nothing.
	local function watches(on: OnFloor, player: Player): boolean
		if on.left[player] then
			return false
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return false
		end
		local p = on.origin:PointToObjectSpace(root.Position)
		return math.abs(p.Y) < 40 and Climb.on(on.floor, p.X, p.Z)
	end

	-- Whether nobody is on floor `on` for its cameras (`watches`). Allocates nothing.
	local function deserted(on: OnFloor): boolean
		for _, player in everyone do
			if watches(on, player) then
				return false
			end
		end
		return true
	end

	-- Offers loose Mannequin `k` its floor's box: the chance it heads there at its next pick of
	-- where to wander (`Breaker.errand`: none while thrown or just after the power came back),
	-- sure while the dev command stands.
	local function offer(on: OnFloor, k: Keeper.Keeper, now: number)
		local box = findBox(on, now)
		local b = breakers
		if not (box and b) then
			return
		end
		local powered, since = b:power(box)
		-- nobody on the floor any more (they all rode up, S2-02d4): no errand, nobody would see it
		local chance = if deserted(on)
			then 0
			elseif devErrand and powered then 1
			else Breaker.errand(on.floor.number, powered, since, on.cut)
		Keeper.offer(k, on.boxStand, on.boxAt, chance, Breaker.Grip)
	end

	-- The players standing on floor `on` (S2-02d): who sees its security camera feeds. Kept players
	-- too: they're on it, shut in.
	local function watchers(on: OnFloor): { Player }
		local found: { Player } = {}
		for _, player in everyone do
			if watches(on, player) then
				table.insert(found, player)
			end
		end
		return found
	end

	-- A Mannequin on its errand (S2-02d): as it sets off, the box's hall streams in on the floor's
	-- screens; with `Feed.Lead` seconds of its walk left, their corner maps cut to a security
	-- camera high in a corner of the box's hall, on the grip's side, showing it walk up and throw
	-- it (closed in `threw`).
	local function errandFeed(entry: Entry, set: boolean)
		local f, on, k = feeds, entry.on, entry.keeper
		local box = on.box
		if not (f and box and box.Parent) then
			return
		end
		if set then
			f:ready(watchers(on), box:GetPivot().Position)
			return
		end
		if entry.feed ~= 0 then
			return
		end
		local dx, dz = on.boxStand.x - k.at.x, on.boxStand.z - k.at.z
		if not Feed.due(math.sqrt(dx * dx + dz * dz), Keeper.pace(k, run)) then
			return
		end
		local grip = Breaker.Specs.GripDown
		local spot = box:GetPivot() * CFrame.new(grip[1], grip[2], grip[3])
		local camera = f:hang(spot, if grip[1] < 0 then -1 else 1, on.model, { on.folder, box })
		local p = on.origin:PointToObjectSpace(camera.Position)
		entry.feed = f:show({
			players = watchers(on),
			camera = camera,
			number = Feed.number(p.X, p.Z),
			watch = { entry.body.model, box },
			within = on.model,
		})
	end

	-- A Mannequin's hand is on the grip (S2-02c): the box is thrown (its slam and clunk are the
	-- box's own, BreakerView), and the keepers near it hear the clunk as they hear a slam, so
	-- whoever goes back to switch it on walks toward whatever came to look. Nothing if the power
	-- was already off.
	local function threw(entry: Entry)
		local on = entry.on
		local box, b = on.box, breakers
		if not (box and b) or not b:throw(box) then
			return
		end
		on.cut = true
		devErrand = false
		local f = feeds
		if f and entry.feed ~= 0 then
			-- the clunk through the camera, the picture dimming as the halls go dark
			f:close(entry.feed, Breaker.ClunkSound, true)
		end
		entry.feed = 0
		if TRACE then
			print(
				`Keepers: the {entry.keeper.row.name} threw the breaker on floor {on.floor.number}`
			)
		end
		-- the others; the one that threw it stands holding the lever down (S2-02d2)
		local p = on.boxStand
		hearAt(
			on.origin:PointToWorldSpace(Vector3.new(p.x, 1, p.z)),
			Breaker.ClunkHeard,
			"the breaker",
			entry
		)
	end

	local function onBlow(entry: Entry)
		local k = entry.keeper
		local blow = k.blow
		local on = entry.on
		local unit = on.units[k.trappedIn]
		if not (doors and unit) then
			return
		end
		local number = on.floor.slots[k.trappedIn].number
		-- every blow that lands dents the door as far as its time has run (L-06b3d2): the step
		-- changes on the blow itself, as the door jolts
		local share = Dent.share(k.trapped, k.row.breakOut)
		if blow == "Burst" then
			if doors:move(unit, "Burst") then
				RollUpDoor.dent(unit, share)
				if TRACE then
					print(`Keepers: the {k.row.name} bursts out of Unit {number}`)
				end
			elseif doors:stateOf(unit) == "Locked" then
				Keeper.padlock(k, true) -- padlocked as its time ran out: it holds
			end
		elseif doors:move(unit, "Bang") then
			RollUpDoor.dent(unit, share)
			-- one line a trap (its start, in `changedState`), not one a blow: only the padlock
			-- stopping it is news
			if TRACE and blow == "Held" then
				print(
					`Keepers: the {k.row.name} gives Unit {number}'s door one last blow; the padlock holds and it goes quiet`
				)
			end
		end
	end

	-- Tells every Packrat what lies loose on its floor (S2-06b2): each find Slots has lying on a
	-- floor, by the floor under it. Once a step at most, after a find or a door changed.
	local function tellLying()
		looseDirty = false
		for _, on in floors do
			on.finds.count = 0
		end
		local s = toolSlots
		if s then
			s:finds(function(n: number, at: Vector3)
				for _, on in floors do
					local p = on.origin:PointToObjectSpace(at)
					local here = vector.create(p.X, p.Y, p.Z)
					if Keeper.onFloor(on.map, here) then
						local f = on.finds
						f.count += 1
						f.ids[f.count], f.at[f.count] = n, here
						return
					end
				end
			end)
		end
		for _, on in floors do
			for _, entry in on.keepers do
				if entry.keeper.row.collects then
					Keeper.lying(entry.keeper, on.finds)
				end
			end
		end
	end

	-- Its hands closed on find `n` (S2-06b2): Slots lifts it into its arms, held against its chest
	-- behind its forearms (`Packrat.Chest`), and it rides there on every screen as the body walks.
	local function tookFind(entry: Entry, n: number)
		local s, body = toolSlots, entry.body.model
		local chest = body:FindFirstChild("UpperTorso")
		local weld = if s and chest and chest:IsA("BasePart") then s:lift(n, chest, body) else nil
		if not weld then
			Keeper.dropped(entry.keeper) -- gone from under its hands
			return
		end
		-- where it lay (`lift` keeps it there): screens ease it from there into the hands
		local held = weld.Part0
		if held then
			weld:SetAttribute(Packrat.FromAttribute, held.CFrame * weld.C0)
		end
		weld.C0 = Packrat.Chest
		if TRACE then
			print(`Keepers: the {entry.keeper.row.name} takes a find and heads home with it`)
		end
	end

	-- Its hands closed on thing `n` in player `id`'s slots (S2-06c): Slots takes it out of their
	-- hands into its arms, from where they held it, and every screen eases it into its hands as a
	-- find lifted off a floor (`Packrat.FromAttribute`). Their screen answers (ToolView's
	-- `snatched`); they're let go, not wrapped. Gone first, it sets off empty-handed.
	local function robbed(entry: Entry, id: number, n: number)
		local s, body = toolSlots, entry.body.model
		local player = Players:GetPlayerByUserId(id)
		local chest = body:FindFirstChild("UpperTorso")
		local weld: Weld?, from: CFrame? = nil, nil
		if s and player and chest and chest:IsA("BasePart") then
			weld, from = s:snatch(player, n, chest, body)
		end
		if not (weld and from and player) then
			Keeper.dropped(entry.keeper)
			return
		end
		weld:SetAttribute(Packrat.FromAttribute, from)
		weld.C0 = Packrat.Chest
		if TRACE then
			print(`Keepers: the {entry.keeper.row.name} takes from {player.Name} and heads home`)
		end
	end

	-- It laid find `n` on its pile (S2-06b2): Slots sets it down there, takeable again, easing
	-- it from between its hands as every screen shows them, crouched (`Packrat.Held`). The spot
	-- is the first round the pile, from the next, with no find lying within `PILE_CLEAR` (S2-06b2b:
	-- a dealt pile lies there already), else the least crowded; always wholly in its own unit.
	local function laidFind(entry: Entry, n: number)
		local s, k, on = toolSlots, entry.keeper, entry.on
		if not s then
			return
		end
		local ahead = k.pile - k.homeAt
		local m = vector.magnitude(ahead)
		local face = if m > 1e-3 then ahead / m else k.facing
		local side = vector.create(-face.z, 0, face.x)
		local finds = on.finds
		local function home(p: vector): boolean
			local _, unit = KeeperMap.placeAt(on.map, p)
			return unit == k.home
		end
		local best, room = k.pile, -1
		for i = 0, #PILE - 1 do
			local spot = PILE[(entry.piled + i) % #PILE + 1]
			local at = k.pile + side * spot[1] + face * spot[2]
			local across, along = side * PILE_SIDE, face * PILE_DEEP
			if
				not (
					home(at + across)
					and home(at - across)
					and home(at + along)
					and home(at - along)
				)
			then
				continue
			end
			local clear = math.huge
			for j = 1, finds.count do
				local d = finds.at[j] - at
				clear = math.min(clear, math.sqrt(d.x * d.x + d.z * d.z))
			end
			if clear > room then
				best, room = at, clear
			end
			if clear >= PILE_CLEAR then
				break
			end
		end
		entry.piled += 1
		-- any: as in `putRoot`
		local feet = on.origin
			* CFrame.lookAt((k.at :: any) :: Vector3, ((k.at + k.facing) :: any) :: Vector3)
		s:putDown(
			n,
			on.origin:PointToWorldSpace((best :: any) :: Vector3),
			math.random(0, 359),
			feet * Packrat.Held.PutDown
		)
		if TRACE then
			print(`Keepers: the {k.row.name} lays a find on its pile and goes out for the next`)
		end
	end

	-- Stands a keeper of row `name` on floor `on`, feet at `at`, facing `facing` (the floor's own
	-- coordinates), asleep or awake. Its body, or nil (Output says why).
	local function standOn(
		on: OnFloor,
		name: string,
		at: vector,
		facing: vector,
		awake: boolean,
		pile: vector?
	): Model?
		local row = KeeperRows[name]
		local kit = KITS[name]
		if not (row and kit) then
			warn(`Keepers: can't stand a {name}: no such keeper`)
			return nil
		end
		local k = Keeper.new(row, on.map, on.random, at, facing, awake, Brix.Reach.cone)
		if pile and row.collects then
			Keeper.nest(k, k.at, pile) -- dealt among its pile (S2-06b2b): it lays more there
		end
		-- any: as in `place`
		local a, f = (k.at :: any) :: Vector3, (k.facing :: any) :: Vector3
		local body = kit.clone(on.origin * CFrame.lookAt(a, a + f))
		local root = body and body.PrimaryPart
		if not (body and root) then
			if body then
				body:Destroy()
			end
			Keeper.release(k)
			return nil
		end
		-- the whole body streams in at once, so no screen ever has the body without its parts (set
		-- before it's in the world: a model already there streams its parts one by one)
		body.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		if row.tripsLights then
			root:AddTag(MotionLight.BodyTag) -- the halls light as it walks (S2-06b2b)
		end
		body:SetAttribute(STATE_ATTRIBUTE, k.state)
		body:SetAttribute(ROW_ATTRIBUTE, name)
		local entry: Entry = {
			keeper = k,
			body = {
				model = body,
				root = root,
				rootOffset = root.PivotOffset:Inverse(),
				motion = nil,
				placed = k.at,
			},
			on = on,
			quarry = 0,
			feed = 0,
			woke = false,
			piled = 0,
		}
		table.insert(on.keepers, entry)
		if row.collects then
			looseDirty = true -- told what lies loose before its first step
		end
		publish(entry, 0, false) -- its first record, before any screen sees it
		CollectionService:AddTag(body, TAG)
		body.Parent = on.folder -- last, whole, so every screen gets it as it is
		return body
	end

	-- A unit was dealt a keeper, alone or with a padlocked unit's find (S1-07a): it stands where
	-- the deal laid it, before anyone sees in. Asleep, it faces as laid; awake, it faces square to
	-- the doorway's middle, and if the door is already all the way up it steps out at once.
	local function onDealt(d: Deals.Dealt)
		local on = floorOf[d.unit]
		if not on then
			return -- a unit on no keepers' floor (the test hall's)
		end
		local index = on.slots[d.unit]
		on.asleep[index] = nil -- its door has lifted: its sleeper, if any, stands below
		-- or it's still shut and its sleeper woke (S2-03b): it stands awake, shut in
		local woken = on.waking[index]
		local waking = woken ~= nil
		on.waking[index] = nil
		local contents, laid = d.contents, d.keeper
		local kind, name = Deal.keeperIn(contents), contents.keeper
		if not (kind and name and laid) then
			return
		end
		local slot = on.floor.slots[index]
		local p = on.origin:PointToObjectSpace(laid.Position)
		local at = vector.create(p.X, p.Y, p.Z)
		local awake = kind == "Awake" or waking
		local facing: vector
		if awake then
			local _, door = Keeper.front(slot)
			facing = door - at
		else
			local l = on.origin:VectorToObjectSpace(laid.LookVector)
			facing = vector.create(l.X, 0, l.Z)
		end
		local pile: vector? = nil
		if d.pile then
			local q = on.origin:PointToObjectSpace(d.pile)
			pile = vector.create(q.X, at.y, q.Z)
		end
		if not standOn(on, name, at, facing, awake, pile) then
			return
		end
		if waking then
			-- shut in from the start: it pounds on the trapped keeper's clock (`Keeper.trap`) and
			-- bursts out at its row's `breakOut` unless the door is padlocked
			trap(on, index)
			local locked = doors ~= nil and doors:stateOf(d.unit) == "Locked"
			for _, entry in on.keepers do
				if entry.keeper.trappedIn == index then
					if locked then
						Keeper.padlock(entry.keeper, true)
					end
					entry.woke = woken == "Wave" -- a wave's: held in while the floor is full
				end
			end
			return
		end
		if TRACE then
			local how = if awake then "awake, facing its doorway" else "asleep"
			print(`Keepers: the {name} stands in Unit {slot.number}, {how}`)
		end
		if awake and doors and KeeperMap.letsThrough(doors:stateOf(d.unit)) then
			lookOut(on, index)
		end
	end

	-- Whether a living player who isn't kept stands on floor `on` (`Climb.stands`: its level and
	-- inside its reach, since the floor above is laid level with this one while the team is still
	-- here): the first one starts its waking clock. Allocates nothing.
	local function anyoneOn(on: OnFloor): boolean
		for _, player in everyone do
			if player:GetAttribute(Kept.Attribute) == true then
				continue
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				local p = on.origin:PointToObjectSpace(root.Position)
				if Climb.stands(on.floor, p.X, p.Y - humanoid.HipHeight - root.Size.Y / 2, p.Z) then
					return true
				end
			end
		end
		return false
	end

	-- The floor's limit on loose keepers holds in the ones a wave woke (S2-07a2, `Waking.free`):
	-- each still shut in is held past its time (`Keeper.hold`), pounding on, while the loose ones
	-- and the woken ones ahead of it (shut in longer, or bursting) fill the floor's cap; the longest
	-- shut in goes first when a place opens. Out, it counts as any loose one does. Allocates
	-- nothing.
	local function holdWoken(on: OnFloor)
		local loose, bursting, any = 0, 0, false
		for _, entry in on.keepers do
			local k = entry.keeper
			if entry.woke and k.trappedIn == 0 then
				entry.woke = false
			end
			if Keeper.loose(k) then
				loose += 1
			elseif k.burst then
				bursting += 1
			end
			any = any or entry.woke
		end
		if not any then
			return
		end
		local number = on.floor.number
		for i, entry in on.keepers do
			local k = entry.keeper
			if not entry.woke or k.burst or k.padlocked then
				continue
			end
			local ahead = bursting
			for j, other in on.keepers do
				local o = other.keeper
				if
					j ~= i
					and other.woke
					and not (o.burst or o.padlocked)
					and (o.trapped > k.trapped or (o.trapped == k.trapped and j < i))
				then
					ahead += 1
				end
			end
			local held = not Waking.free(number, loose, ahead)
			if held ~= k.held then
				Keeper.hold(k, held)
				if TRACE then
					local unit = on.floor.slots[k.trappedIn].number
					print(
						if held
							then `Keepers: the {k.row.name} in Unit {unit} is held in: floor {number} has its {FloorRules.at(
								number
							).awake} loose`
							else `Keepers: the {k.row.name} in Unit {unit} may break out now`
					)
				end
			end
		end
	end

	-- Wakes what floor `on` owes now (S2-03b; `Waking`, D-156): each picked sleeper's unit is dealt
	-- with its door still shut, so its keeper stands where the deal lays it, awake and shut in
	-- (`onDealt`), and starts pounding. Its unit leaves `asleep`. One Output line a wave.
	local function wakeDue(on: OnFloor)
		local number = on.floor.number
		local dl = deals
		if not dl or next(on.asleep) == nil or Waking.owed(number, on.here) <= on.woken then
			return
		end
		local awake, left = 0, 0
		for _, entry in on.keepers do
			if Keeper.awake(entry.keeper) then
				awake += 1
			end
		end
		for _ in on.asleep do
			left += 1
		end
		local n = Waking.now(number, on.here, on.woken, awake, left)
		if n <= 0 then
			return
		end
		local slots: { number } = {}
		for slot in on.asleep do
			table.insert(slots, slot)
		end
		table.sort(slots) -- a fixed order, so the floor's Random alone decides the pick
		local random = on.random
		local picked = Waking.pick(slots, n, function(k: number): number
			return random:nextInteger(1, k)
		end)
		local said: { string } = {}
		for _, slot in picked do
			on.woken += 1
			on.asleep[slot] = nil
			local unit = on.units[slot]
			if unit then
				on.waking[slot] = "Wave"
				if not dl:dealShut(unit) then
					on.waking[slot] = nil
				end
				table.insert(said, tostring(on.floor.slots[slot].number))
			end
		end
		if TRACE then
			print(
				`Keepers: {#picked} wake behind shut doors on floor {number}, {math.floor(on.here)} s in: Units {table.concat(
					said,
					", "
				)}`
			)
		end
	end

	local system = { name = "Keepers", caught = caught }

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Doors fills this slot (init.server)
		local d = (context.registry:get("doors") :: any) :: Doors.Doors
		doors = d
		-- any: as above; the lights fill these slots (init.server)
		motionLights = (context.registry:get("motionLights") :: any) :: MotionLights.MotionLights?
		flashlights = (context.registry:get("flashlights") :: any) :: Flashlights.Flashlights?
		-- any: as above; Breakers fills this slot (init.server)
		breakers = (context.registry:get("breakers") :: any) :: Breakers.Breakers?
		-- any: as above; Feeds fills this slot (init.server)
		feeds = (context.registry:get("feeds") :: any) :: Feeds.Feeds?
		run = StarterPlayer.CharacterWalkSpeed
		everyone = Players:GetPlayers()
		local folder = ReplicatedStorage:FindFirstChild(Caught.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Caught.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = Caught.Remote
		remote.Parent = folder
		caughtRemote = remote
		-- Chase's remote sits beside the catch's (both in `Caught.RemoteFolder`, "Remotes")
		local hunted = Instance.new("RemoteEvent")
		hunted.Name = Chase.Remote
		hunted.Parent = folder
		huntedRemote = hunted
		if RunService:IsStudio() then
			-- every loose Mannequin heads for its floor's box now (S2-02c): it picks where to go
			-- next at once, and the box is sure to be its pick while the power is on. One stood
			-- asleep in a hall (DevCorridor's "Stand one") wakes for it; sleepers behind doors don't.
			table.insert(
				joins,
				Workspace:GetAttributeChangedSignal(DEV_ERRAND):Connect(function()
					if Workspace:GetAttribute(DEV_ERRAND) ~= true then
						return
					end
					Workspace:SetAttribute(DEV_ERRAND, false)
					devErrand = true
					for _, on in floors do
						for _, entry in on.keepers do
							local k = entry.keeper
							local s = k.state
							local _, unit = KeeperMap.placeAt(on.map, k.at)
							if s == "Asleep" and unit == 0 and k.trappedIn == 0 then
								s = "Watching"
							end
							if
								k.row.freezesInLight
								and k.trappedIn == 0
								and (s == "Roaming" or s == "Waiting" or s == "Watching")
							then
								k.state, k.wait, k.waited = "Waiting", 0, 0 -- it picks now
							end
						end
					end
				end)
			)
			-- every floor with the team on it skips to its first wave of sleepers waking (S2-03b)
			table.insert(
				joins,
				Workspace:GetAttributeChangedSignal(DEV_WAKE):Connect(function()
					if Workspace:GetAttribute(DEV_WAKE) ~= true then
						return
					end
					Workspace:SetAttribute(DEV_WAKE, false)
					for _, on in floors do
						if on.here >= 0 then
							on.here = math.max(on.here, Waking.first(on.floor.number))
						end
					end
				end)
			)
			-- a catch wherever you are, for one-player tests of what a catch does to you
			local test = Instance.new("BindableFunction")
			test.Name = "CatchTest"
			-- any: a BindableFunction's argument, checked here
			test.OnInvoke = function(who: any): string
				if typeof(who) ~= "Instance" or not who:IsA("Player") then
					return "NotAPlayer"
				end
				local character = who.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not (root and root:IsA("BasePart")) then
					return "NoBody"
				end
				local nearest: Entry? = nil
				local best = math.huge
				for _, on in floors do
					for _, entry in on.keepers do
						local off = (entry.body.root.Position - root.Position).Magnitude
						if off < best then
							nearest, best = entry, off
						end
					end
				end
				if not nearest then
					return "NoKeeper"
				end
				if who:GetAttribute(Kept.Attribute) == true then
					return "AlreadyKept"
				end
				catch(nearest, who.UserId)
				return "Caught"
			end
			test.Parent = ServerStorage
			catchTest = test
		end
		table.insert(
			joins,
			Players.PlayerAdded:Connect(function(player: Player)
				table.insert(everyone, player)
			end)
		)
		table.insert(
			joins,
			Players.PlayerRemoving:Connect(function(player: Player)
				local i = table.find(everyone, player)
				if i then
					table.remove(everyone, i)
				end
				told[player] = nil
			end)
		)
		table.insert(connections, d.acted:connect(onActed))
		table.insert(connections, d.changed:connect(onChanged))
		-- any: as above; Deals fills this slot (init.server)
		local dl = (context.registry:get("deals") :: any) :: Deals.Deals?
		deals = dl
		if dl then
			table.insert(connections, dl.dealt:connect(onDealt))
		end
		-- the rest of what players do that's loud (L-15); any: as above, each fills its slot
		local elevators = (context.registry:get("elevators") :: any) :: Elevators.Elevators?
		if elevators then
			table.insert(connections, elevators.acted:connect(onKeypad))
		end
		local sl = (context.registry:get("slots") :: any) :: Slots.Slots?
		toolSlots = sl
		if sl then
			table.insert(connections, sl.landed:connect(onLanded))
			table.insert(
				connections,
				sl.loose:connect(function()
					looseDirty = true
				end)
			)
		end
		local saws = (context.registry:get("saws") :: any) :: Saws.Saws?
		if saws then
			table.insert(connections, saws.sawing:connect(onSawing))
		end
		local crawls = (context.registry:get("crawls") :: any) :: Crawls.Crawls?
		if crawls then
			table.insert(connections, crawls.crawled:connect(onCrawled))
		end
		local ladders = (context.registry:get("ladders") :: any) :: Ladders.Ladders?
		if ladders then
			table.insert(connections, ladders.climbed:connect(onClimbed))
		end
	end

	-- Only keepers awake change; a body moves only when its keeper did. Players are gathered only
	-- for a floor with a keeper awake to see them.
	function system.step(_: any, dt: number)
		local now = os.clock()
		if looseDirty then
			tellLying()
		end
		for _, on in floors do
			if on.here < 0 then
				if anyoneOn(on) then
					on.here = 0
					if TRACE then
						print(
							`Keepers: the team is on floor {on.floor.number}; its sleepers' clock starts`
						)
					end
				end
			else
				on.here += dt
				wakeDue(on)
			end
			holdWoken(on)
			local list = on.players
			list.count = 0
			for _, entry in on.keepers do
				if Keeper.awake(entry.keeper) then
					gather(on, now)
					break
				end
			end
			for _, entry in on.keepers do
				local k = entry.keeper
				local was: Keeper.State = k.state
				local target = k.target
				local before = k.at
				local wasLit = k.lit ~= 0
				local wasErrand = k.errand
				if k.row.freezesInLight and Keeper.loose(k) then
					offer(on, k, now)
				end
				local hallLit = false
				if motionLights and k.row.freezesInLight and Keeper.awake(k) then
					-- any: as in `putRoot`
					hallLit =
						motionLights:lightOn(on.origin:PointToWorldSpace((k.at :: any) :: Vector3))
				end
				local changed = Keeper.step(k, dt, run, list, hallLit)
				local froze = (k.lit ~= 0) ~= wasLit
				if changed or froze then
					local dx, dz = k.at.x - before.x, k.at.z - before.z
					publish(
						entry,
						if dx * dx + dz * dz > STILL * STILL then Keeper.pace(k, run) else 0,
						froze
					)
					if k.caught ~= 0 then
						catch(entry, k.caught) -- before its state's line: the catch, then the stand
					end
					changedState(entry, was)
					if TRACE and froze then
						traceLight(entry)
					end
					if TRACE and k.caught == 0 and k.robbed == 0 and k.target ~= target then
						traceSight(entry, target)
					end
				end
				if k.blow ~= "None" then
					onBlow(entry)
				end
				if k.errand then
					errandFeed(entry, not wasErrand)
				elseif not k.threw then
					entry.feed = 0 -- called off: an open feed shows it turn away, then cuts out
				end
				if k.took ~= 0 and k.robbed ~= 0 then
					robbed(entry, k.robbed, k.took)
				elseif k.took ~= 0 then
					tookFind(entry, k.took)
				elseif k.laid ~= 0 then
					laidFind(entry, k.laid)
				end
				if k.threw then
					threw(entry)
				elseif TRACE and k.errand and not wasErrand then
					print(`Keepers: the {k.row.name} heads for the breaker`)
				end
				if k.target ~= entry.quarry then -- it saw, lost or caught someone, or was trapped
					entry.quarry = k.target
					recount = true
				end
			end
		end
		if recount then
			tellHunted()
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		for _, c in joins do
			c:Disconnect()
		end
		table.clear(joins)
		table.clear(everyone)
		if caughtRemote then
			caughtRemote:Destroy()
			caughtRemote = nil
		end
		if huntedRemote then
			huntedRemote:Destroy()
			huntedRemote = nil
		end
		if catchTest then
			catchTest:Destroy()
			catchTest = nil
		end
		table.clear(told)
		for _, on in floors do
			drop(on)
		end
	end

	function system.add(
		_: any,
		floor: Floor.Floor,
		slots: { [Model]: number },
		model: Model,
		origin: CFrame,
		random: Floor.Random,
		asleep: { [number]: string },
		packed: { [number]: boolean }?
	)
		if floors[model] then
			return
		end
		local folder = Instance.new("Folder")
		folder.Name = "Keepers"
		folder.Parent = model
		local on: OnFloor
		local units: { [number]: Model } = {}
		for unit, slot in slots do
			units[slot] = unit
		end
		on = {
			floor = floor,
			map = KeeperMap.build(floor),
			random = random,
			origin = origin,
			slots = slots,
			units = units,
			model = model,
			folder = folder,
			keepers = {},
			asleep = table.clone(asleep),
			players = Keeper.players(),
			gone = model.Destroying:Once(function()
				drop(on)
			end),
			box = nil,
			boxAt = vector.zero,
			boxStand = vector.zero,
			boxLooked = -math.huge,
			cut = false,
			here = -1,
			woken = 0,
			waking = {},
			left = {},
			finds = { ids = {}, at = {}, count = 0 },
		}
		floors[model] = on
		-- a packed unit's floor is its path and its clearing, joined at the bend (B-05b2)
		local packedSlots: { [number]: boolean } = packed or {}
		for slot in packedSlots do
			local s = floor.slots[slot]
			local unit = units[slot]
			local layout = if s and s.number then Packed.layout(s.size, s.number) else nil
			if layout and unit then
				local bx, bz = KeeperMap.pack(on.map, slot, layout)
				if RunService:IsStudio() then
					-- the map's frame against the one the deal lays the stacks in
					local bend = layout.bend
					local want = origin:PointToObjectSpace(
						(FloorBuilder.face(unit) * CFrame.new(bend.x, 0, bend.z)).Position
					)
					if math.abs(want.X - bx) > 0.1 or math.abs(want.Z - bz) > 0.1 then
						warn(`Keepers: {unit.Name}'s bend is off the map's ({bx}, {bz} for {want})`)
					end
				end
			end
		end
		for unit, slot in slots do
			floorOf[unit] = on
			local state: Door.State = if doors then doors:stateOf(unit) else "Closed"
			KeeperMap.setDoor(on.map, slot, KeeperMap.letsThrough(state))
		end
		if TRACE then
			local said: { string } = {}
			for slot, name in on.asleep do
				table.insert(said, `{floor.slots[slot].number} ({name})`)
			end
			table.sort(said)
			print(
				if #said == 0
					then `Keepers: nobody asleep on floor {floor.number}`
					else `Keepers: asleep behind shut doors on floor {floor.number}: Units {table.concat(
						said,
						", "
					)}`
			)
		end
	end

	function system.inside(_: any, unit: Model, player: Player): (boolean?, boolean)
		local on = floorOf[unit]
		if not on then
			return nil, false
		end
		local index = on.slots[unit]
		for _, entry in on.keepers do
			local k = entry.keeper
			local _, at = KeeperMap.placeAt(on.map, k.at)
			if at == index and k.trappedIn == 0 then
				return k.state == "Asleep", k.target == player.UserId
			end
		end
		return nil, false
	end

	function system.wakeShut(_: any, unit: Model): boolean
		local on = floorOf[unit]
		if not on then
			return false
		end
		local index = on.slots[unit]
		local slot = on.floor.slots[index]
		local woke = false
		for _, entry in on.keepers do
			local was: Keeper.State = entry.keeper.state
			if Keeper.wakeShut(entry.keeper, slot, index) then
				woke = true
				if TRACE then
					print(
						`Keepers: Unit {slot.number}'s door banged down as its tap missed; the {entry.keeper.row.name} wakes shut in and pounds`
					)
				end
				changedState(entry, was)
			end
		end
		return woke
	end

	function system.left(_: any, model: Model, riders: { Player })
		local on = floors[model]
		if not on or #riders == 0 then
			return
		end
		for _, player in riders do
			on.left[player] = true
		end
		local f = feeds
		if f then
			f:cut(riders, model)
		end
		if TRACE then
			print(
				`Keepers: {#riders} rode out of floor {on.floor.number}; its cameras are done with them`
			)
		end
	end

	function system.sleepers(_: any, model: Model): { [Model]: string }
		local out: { [Model]: string } = {}
		local on = floors[model]
		if on then
			for slot, name in on.asleep do
				local unit = on.units[slot]
				if unit then
					out[unit] = name
				end
			end
		end
		return out
	end

	function system.stand(
		_: any,
		name: string,
		model: Model,
		at: Vector3,
		facing: Vector3,
		awake: boolean?
	): Model?
		local on = floors[model]
		if not on then
			warn(`Keepers: can't stand a {name} on {model:GetFullName()}: no keepers' floor`)
			return nil
		end
		local a = on.origin:PointToObjectSpace(at)
		local f = on.origin:VectorToObjectSpace(facing)
		return standOn(
			on,
			name,
			vector.create(a.X, a.Y, a.Z),
			vector.create(f.X, 0, f.Z),
			awake == true
		)
	end

	function system.hear(_: any, at: Vector3, reach: number, what: string): number
		return hearAt(at, reach, what)
	end

	function system.hearHorn(self: any, at: Vector3): number
		return system.hear(self, at, Horn.Reach, "an air horn")
	end

	function system.feet(_: any, each: (body: Model, at: Vector3) -> ())
		for _, on in floors do
			for _, entry in on.keepers do
				-- any: as in `putRoot`
				each(
					entry.body.model,
					on.origin:PointToWorldSpace((entry.keeper.at :: any) :: Vector3)
				)
			end
		end
	end

	function system.awakeOn(_: any, unit: Model): number
		local on = floorOf[unit]
		if not on then
			return 0
		end
		local count = 0
		for _, entry in on.keepers do
			if Keeper.loose(entry.keeper) then
				count += 1
			end
		end
		return count
	end

	function system.remove(_: any, body: Model)
		for _, on in floors do
			for i, entry in on.keepers do
				if entry.body.model == body then
					on.keepers[i] = on.keepers[#on.keepers]
					on.keepers[#on.keepers] = nil
					local holding, sl = entry.keeper.holding, toolSlots
					if holding ~= 0 and sl then
						-- its find stays on the floor where it stood, not gone with its body
						-- any: as in `putRoot`
						local feet =
							on.origin:PointToWorldSpace((entry.keeper.at :: any) :: Vector3)
						sl:putDown(holding, feet, 0)
					end
					release(entry)
					recount = true
					return
				end
			end
		end
	end

	function system.hallOff(_: any, model: Model, studs: number): (Vector3?, Vector3?)
		local on = floors[model]
		if not on then
			return nil, nil
		end
		local at, facing = Keeper.hallAbout(on.map, KeeperMap.pathing(on.map), vector.zero, studs)
		-- any: as in `place`
		return on.origin:PointToWorldSpace((at :: any) :: Vector3),
			on.origin:VectorToWorldSpace((facing :: any) :: Vector3)
	end

	return system
end

return Keepers
