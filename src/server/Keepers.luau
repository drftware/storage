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
	  them rushes to where it last saw them, looks, and roams again (L-06b3a2).
	- Light freezes a keeper whose row says so (the Mannequin, L-06b3b): each step it's told
	  whether a lit hall light's pool is where it stands (`MotionLights.lightOn`), and each living
	  player's torch, from their eyes along their facing at their aim (`Flashlights`), so it
	  decides whether a light is on it (`Keeper.step`). Frozen or let go, screens hear of it at
	  once, not after the records' usual gap, so it stops on the stride it was on.
	- `awakeOn` tells the deal how many keepers are awake on a floor now, for its cap.
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
local Deals = require(script.Parent.Deals)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Doors = require(script.Parent.Doors)
local Flashlights = require(script.Parent.Flashlights)
local Floor = require(ReplicatedStorage.Shared.Floor)
local Keeper = require(ReplicatedStorage.Shared.Keeper)
local KeeperMap = require(ReplicatedStorage.Shared.KeeperMap)
local KeeperMotion = require(ReplicatedStorage.Shared.KeeperMotion)
local KeeperRows = require(ReplicatedStorage.Shared.KeeperRows)
local Mannequin = require(ReplicatedStorage.Shared.Mannequin)
local MotionLights = require(script.Parent.MotionLights)

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
	Waiting = "stands at the door, looking",
	Roaming = "wanders off down the halls",
	Hunting = "hunts",
	Searching = "rushes to where it last saw them",
}
local HEARD: { [string]: string } =
	{ Open = "open", Slam = "slam", LiftInside = "lift from inside" }

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
	model: Model,
	folder: Folder, -- its keepers' bodies
	keepers: { Entry },
	players: Keeper.Players, -- where each living player's feet are this step, reused
	gone: RBXScriptConnection,
}
type Entry = { keeper: Keeper.Keeper, body: Body, on: OnFloor }

export type Keepers = Brix.System & {
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
	-- How many keepers are awake now on the floor `unit` is on (0 off any keepers' floor): the
	-- deal's cap counts these (`Deal.awakeCap`).
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
	local joins: { RBXScriptConnection } = {}

	-- Where each living player's feet are on floor `on`, in its own coordinates, and their torch:
	-- from their eyes (their head), along the way they face (a first-person camera's), tipped up
	-- by their aim; a zero aim while it's off. Allocates nothing.
	local function gather(on: OnFloor)
		local list = on.players
		local origin = on.origin
		local n = 0
		for _, player in everyone do
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
			local doing = if state == "Waiting" and was == "Searching"
				then "stands where it lost them, looking about"
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
		for _, entry in on.keepers do
			local k = entry.keeper
			local was: Keeper.State = k.state
			local heard = Keeper.hear(k, door, event.reach, spot)
			if heard then
				if TRACE then
					local wakes = if was == "Asleep" then "wakes and goes" else "goes"
					print(
						`Keepers: the {k.row.name} heard Unit {slot.number}'s door {HEARD[motion]}, {math.round(
							heard
						)} studs off along the halls; it {wakes} to look`
					)
				end
				changedState(entry, was)
			end
		end
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

	-- A door's state changed: its doorway lets keepers through only while it's all the way up.
	local function onChanged(change: Doors.DoorChange)
		local on = floorOf[change.unit]
		if on then
			local index = on.slots[change.unit]
			local through = KeeperMap.letsThrough(change.state)
			KeeperMap.setDoor(on.map, index, through)
			if through then
				lookOut(on, index)
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
		local k = Keeper.new(row, on.map, on.random, at, facing, awake)
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

	local system = { name = "Keepers" }

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Doors fills this slot (init.server)
		local d = (context.registry:get("doors") :: any) :: Doors.Doors
		doors = d
		-- any: as above; the lights fill these slots (init.server)
		motionLights = (context.registry:get("motionLights") :: any) :: MotionLights.MotionLights?
		flashlights = (context.registry:get("flashlights") :: any) :: Flashlights.Flashlights?
		run = StarterPlayer.CharacterWalkSpeed
		everyone = Players:GetPlayers()
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
			end)
		)
		table.insert(connections, d.acted:connect(onActed))
		table.insert(connections, d.changed:connect(onChanged))
		-- any: as above; Deals fills this slot (init.server)
		local deals = (context.registry:get("deals") :: any) :: Deals.Deals?
		if deals then
			table.insert(connections, deals.dealt:connect(onDealt))
		end
	end

	-- Only keepers awake change; a body moves only when its keeper did. Players are gathered only
	-- for a floor with a keeper awake to see them.
	function system.step(_: any, dt: number)
		for _, on in floors do
			local list = on.players
			list.count = 0
			for _, entry in on.keepers do
				if Keeper.awake(entry.keeper) then
					gather(on)
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
					changedState(entry, was)
					if TRACE and froze then
						traceLight(entry)
					end
					if TRACE and k.target ~= target then
						traceSight(entry, target)
					end
				end
			end
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
		on = {
			floor = floor,
			map = KeeperMap.build(floor),
			random = random,
			origin = origin,
			slots = slots,
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

	function system.awakeOn(_: any, unit: Model): number
		local on = floorOf[unit]
		if not on then
			return 0
		end
		local count = 0
		for _, entry in on.keepers do
			if Keeper.awake(entry.keeper) then
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
