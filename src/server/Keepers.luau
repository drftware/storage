--!strict
--[[
	Keepers: the keepers' brain on the server (L-06b2a, D-064), one system on the Host's clock. It
	keeps each laid floor's map (KeeperMap) in step with its doors, tells every keeper on a floor
	what it hears there, steps each one (the pure `Keeper`) and moves its body.

	- A floor joins with `add` as it's laid (FloorBuilder's `laid.slots`): its map is built once and
	  each door's state fed in as it changes (`Doors.changed` through `KeeperMap.letsThrough`), so a
	  doorway lets keepers through only while its door is all the way up. It brings a seeded Random
	  of its own, which its keepers share to pick where they roam. Its keepers go with it.
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
	  (L-15): the keypad (`Elevators.acted`), a dropped tool landing (`Slots.landed`), the saw
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
	the attribute `KeeperState`. `stand` puts a keeper on a laid floor (the dev command's).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Catalog = require(ReplicatedStorage.Shared.Tools.Catalog)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Chase = require(ReplicatedStorage.Shared.Chase)
local Crawls = require(script.Parent.Crawls)
local Deals = require(script.Parent.Deals)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Dent = require(ReplicatedStorage.Shared.StorageUnit.Dent)
local Doors = require(script.Parent.Doors)
local Elevators = require(script.Parent.Elevators)
local Flashlights = require(script.Parent.Flashlights)
local Floor = require(ReplicatedStorage.Shared.Floor)
local Horn = require(ReplicatedStorage.Shared.Tools.Horn)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Keeper = require(ReplicatedStorage.Shared.Keeper)
local Torch = require(ReplicatedStorage.Shared.Flashlight.Torch)
local KeeperMap = require(ReplicatedStorage.Shared.KeeperMap)
local KeeperMotion = require(ReplicatedStorage.Shared.KeeperMotion)
local KeeperRows = require(ReplicatedStorage.Shared.KeeperRows)
local KeeperTell = require(ReplicatedStorage.Shared.KeeperTell)
local Ladders = require(script.Parent.Ladders)
local Mannequin = require(ReplicatedStorage.Shared.Mannequin)
local MotionLights = require(script.Parent.MotionLights)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Saws = require(script.Parent.Saws)
local Slots = require(script.Parent.Slots)

local TRACE = RunService:IsStudio() -- Output says what each keeper hears and does
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

-- What each keeper's body is: a copy of its template, its joints at rest for screens to turn.
type Kit = {
	clone: (pivot: CFrame, parent: Instance) -> Model?,
}
local KITS: { [string]: Kit } = {
	Mannequin = {
		clone = function(pivot: CFrame, parent: Instance): Model?
			local body = Mannequin.clone(pivot, parent)
			if body then
				Mannequin.rest(body)
			end
			return body
		end,
	},
}

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
	players: Keeper.Players, -- where each living player's feet are this step, reused
	gone: RBXScriptConnection,
}
-- `quarry`: whom it hunted as last counted for screens (`tellHunted`), 0 for no one.
type Entry = { keeper: Keeper.Keeper, body: Body, on: OnFloor, quarry: number }

-- A keeper caught a player: its body, whom it caught, and the floor's model (FloorBuilder's).
export type Catch = { body: Model, player: Player, floor: Model }

export type Keepers = Brix.System & {
	-- A keeper caught a player (L-06b3c), fired once per catch, after the caught player's screen
	-- has been told: what L-07's getting kept takes. Until then DevCorridor's stand-in does.
	caught: Brix.Signal<Catch>,
	-- Lays a floor's map for keepers to walk as FloorBuilder lays it: `slots` maps each unit to its
	-- slot (`laid.slots`), `origin` is where it was laid, and `random` (a fresh Brix Random from the
	-- floor's seed, not the deal's, so roams never change what the units hold) picks where its
	-- keepers roam. Its keepers go when `model` is destroyed.
	add: (
		self: any,
		floor: Floor.Floor,
		slots: { [Model]: number },
		model: Model,
		origin: CFrame,
		random: Floor.Random
	) -> (),
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
	-- and not trapped behind a door. The deal's cap counts these (`Deal.awakeCap`).
	awakeOn: (self: any, unit: Model) -> number,
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
	local connections: { Brix.SignalConnection } = {}
	local doors: Doors.Doors? = nil
	local motionLights: MotionLights.MotionLights? = nil
	local flashlights: Flashlights.Flashlights? = nil
	local run = 16 -- a player's full run, studs a second (StarterPlayer's, read at start)
	local everyone: { Player } = {} -- kept as players come and go: no list made each step
	local caught = Brix.Signal.new() :: Brix.Signal<Catch>
	local caughtRemote: RemoteEvent? = nil
	local huntedRemote: RemoteEvent? = nil
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
		if now or KeeperMotion.due(body.motion, t, at, facing, speed, k.state) then
			local left = if speed > 0 then Keeper.left(k) else 0
			local encoded = KeeperMotion.encode(t, at, facing, speed, left, k.travelled, k.state)
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
	-- noise going on (a code's presses, a crawl's pulls) is neither.
	local function heardIt(
		entry: Entry,
		was: Keeper.State,
		what: string,
		off: number,
		news: boolean
	)
		local k = entry.keeper
		if news and k.state ~= "Trapped" then
			entry.body.model:SetAttribute(KeeperTell.HeardAttribute, Workspace:GetServerTimeNow())
		end
		if TRACE and news then
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

	-- A door made a sound: every keeper on its floor that hears it goes to look.
	local function onActed(event: Doors.DoorEvent)
		local motion = event.motion
		if not (motion and Keeper.Hears[motion]) then
			return
		end
		local on = floorOf[event.unit]
		if not on then
			return -- a unit on no keepers' floor (the test hall's)
		end
		local slot = on.floor.slots[on.slots[event.unit]]
		local spot, door = Keeper.front(slot)
		local what = `Unit {slot.number}'s door {HEARD[motion]}`
		for _, entry in on.keepers do
			local was: Keeper.State = entry.keeper.state
			local heard, news = Keeper.hear(entry.keeper, door, event.reach, spot)
			if heard then
				heardIt(entry, was, what, heard, news)
			end
		end
	end

	-- A loud thing at `at` (the world's), carrying `reach` studs: every keeper on the floor it's on
	-- that hears it comes to look (Keeper.heardAt). How many heard it.
	local function hearAt(at: Vector3, reach: number, what: string): number
		local count = 0
		for _, on in floors do
			local p = on.origin:PointToObjectSpace(at)
			local here = vector.create(p.X, p.Y, p.Z)
			if not Keeper.onFloor(on.map, here) then
				continue
			end
			for _, entry in on.keepers do
				local was: Keeper.State = entry.keeper.state
				local heard, news = Keeper.heardAt(entry.keeper, here, reach)
				if heard then
					count += 1
					heardIt(entry, was, what, heard, news)
				end
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

	-- The rest of the noises players make (L-15), each heard as far as players hear it.
	local function onKeypad(event: Elevators.KeypadEvent)
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
					print(
						`Keepers: Unit {slot.number}'s door is up; the {k.row.name} steps out to look`
					)
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
			local wasOpen = KeeperMap.doorOpen(on.map, index)
			KeeperMap.setDoor(on.map, index, through)
			if through then
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

	-- Stands a keeper of row `name` on floor `on`, feet at `at`, facing `facing` (the floor's own
	-- coordinates), asleep or awake. Its body, or nil (Output says why).
	local function standOn(
		on: OnFloor,
		name: string,
		at: vector,
		facing: vector,
		awake: boolean
	): Model?
		local row = KeeperRows[name]
		local kit = KITS[name]
		if not (row and kit) then
			warn(`Keepers: can't stand a {name}: no such keeper`)
			return nil
		end
		local k = Keeper.new(row, on.map, on.random, at, facing, awake, Brix.Reach.cone)
		-- any: as in `place`
		local a, f = (k.at :: any) :: Vector3, (k.facing :: any) :: Vector3
		local body = kit.clone(on.origin * CFrame.lookAt(a, a + f), on.folder)
		local root = body and body.PrimaryPart
		if not (body and root) then
			Keeper.release(k)
			return nil
		end
		body.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- the whole body streams in at once
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
		}
		table.insert(on.keepers, entry)
		publish(entry, 0, false) -- its first record, before any screen sees it
		CollectionService:AddTag(body, TAG)
		return body
	end

	-- A unit was dealt a keeper: it stands where the deal laid it, before anyone sees in. Asleep, it
	-- faces as laid; awake, it faces square to the doorway's middle, and if the door is already all
	-- the way up it steps out at once.
	local function onDealt(d: Deals.Dealt)
		local contents, laid = d.contents, d.place
		local kind, name = contents.kind, contents.keeper
		if not ((kind == "Asleep" or kind == "Awake") and name and laid) then
			return
		end
		local on = floorOf[d.unit]
		if not on then
			return -- a unit on no keepers' floor (the test hall's)
		end
		local index = on.slots[d.unit]
		local slot = on.floor.slots[index]
		local p = on.origin:PointToObjectSpace(laid.Position)
		local at = vector.create(p.X, p.Y, p.Z)
		local awake = kind == "Awake"
		local facing: vector
		if awake then
			local _, door = Keeper.front(slot)
			facing = door - at
		else
			local l = on.origin:VectorToObjectSpace(laid.LookVector)
			facing = vector.create(l.X, 0, l.Z)
		end
		if not standOn(on, name, at, facing, awake) then
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

	local system = { name = "Keepers", caught = caught }

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Doors fills this slot (init.server)
		local d = (context.registry:get("doors") :: any) :: Doors.Doors
		doors = d
		-- any: as above; the lights fill these slots (init.server)
		motionLights = (context.registry:get("motionLights") :: any) :: MotionLights.MotionLights?
		flashlights = (context.registry:get("flashlights") :: any) :: Flashlights.Flashlights?
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
		local deals = (context.registry:get("deals") :: any) :: Deals.Deals?
		if deals then
			table.insert(connections, deals.dealt:connect(onDealt))
		end
		-- the rest of what players do that's loud (L-15); any: as above, each fills its slot
		local elevators = (context.registry:get("elevators") :: any) :: Elevators.Elevators?
		if elevators then
			table.insert(connections, elevators.acted:connect(onKeypad))
		end
		local slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		if slots then
			table.insert(connections, slots.landed:connect(onLanded))
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
		for _, on in floors do
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
					if TRACE and k.caught == 0 and k.target ~= target then
						traceSight(entry, target)
					end
				end
				if k.blow ~= "None" then
					onBlow(entry)
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
		random: Floor.Random
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
			players = Keeper.players(),
			gone = model.Destroying:Once(function()
				drop(on)
			end),
		}
		floors[model] = on
		for unit, slot in slots do
			floorOf[unit] = on
			local state: Door.State = if doors then doors:stateOf(unit) else "Closed"
			KeeperMap.setDoor(on.map, slot, KeeperMap.letsThrough(state))
		end
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
