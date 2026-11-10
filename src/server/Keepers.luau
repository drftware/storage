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
	- `awakeOn` tells the deal how many keepers are awake on a floor now, for its cap.
	- Each keeper's body is an anchored model moved by its HumanoidRootPart, with no Humanoid, and
	  only while something about it changed. Its walk is posed on the server for now, at most
	  `POSE_EVERY` (L-06b4 poses it on each screen instead), so it may judder on a phone.
	- The brain works in the floor's own coordinates (its lobby's middle at the origin, its floor at
	  height 0); positions are turned from the world going in and back coming out.

	In Studio, Output says what each keeper hears, sees and does, and each body carries its state as the
	attribute `KeeperState`. `stand` puts a keeper on a laid floor (the dev command's).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Brix = require(ReplicatedStorage.Brix)
local Deals = require(script.Parent.Deals)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Doors = require(script.Parent.Doors)
local Floor = require(ReplicatedStorage.Shared.Floor)
local Keeper = require(ReplicatedStorage.Shared.Keeper)
local KeeperMap = require(ReplicatedStorage.Shared.KeeperMap)
local KeeperRows = require(ReplicatedStorage.Shared.KeeperRows)
local Mannequin = require(ReplicatedStorage.Shared.Mannequin)
local Pose = require(ReplicatedStorage.Shared.Mannequin.Pose)

-- How long a walking body holds a pose on the server before the next (seconds). Its stop-motion
-- walk holds each key and snaps to the next, so 20 a second reads as its walk; every pose sends its
-- joints to every player, until L-06b4 poses it on their screens instead.
local POSE_EVERY = 1 / 20
local TRACE = RunService:IsStudio() -- Output says what each keeper hears and does
local STATE_ATTRIBUTE = "KeeperState"

-- What each keeper's body is: its model, and its poses standing, walking and stopped.
type Kit = {
	clone: (pivot: CFrame, parent: Instance) -> Model?,
	pose: (model: Model, pose: Pose.Pose) -> (),
	still: Pose.Pose, -- as it's first stood up
	walk: (travelled: number) -> Pose.Pose, -- its walk once it has gone this far
	stop: (travelled: number) -> Pose.Pose, -- stopped after going this far: mid-stride, held
}
local KITS: { [string]: Kit } = {
	Mannequin = {
		clone = function(pivot: CFrame, parent: Instance): Model?
			return Mannequin.clone(pivot, parent)
		end,
		pose = Mannequin.pose,
		still = Pose.Poses.Still,
		walk = Pose.at,
		stop = function(travelled: number): Pose.Pose
			return Pose.Poses[Pose.freeze(travelled)]
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
	kit: Kit,
	posed: Pose.Pose?, -- the pose it was last given
	posedAt: number, -- when (the system's clock)
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
	local run = 16 -- a player's full run, studs a second (StarterPlayer's, read at start)
	local clock = 0
	local everyone: { Player } = {} -- kept as players come and go: no list made each step
	local joins: { RBXScriptConnection } = {}

	-- Where each living player's feet are on floor `on`, in its own coordinates. Allocates nothing.
	local function gather(on: OnFloor)
		local list = on.players
		local n = 0
		for _, player in everyone do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				local p = on.origin:PointToObjectSpace(root.Position)
				n += 1
				list.ids[n] = player.UserId
				list.at[n] = vector.create(p.X, p.Y - humanoid.HipHeight - root.Size.Y / 2, p.Z)
			end
		end
		list.count = n
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

	-- Moves its body to where the brain has it and poses it.
	local function place(entry: Entry, now: boolean?)
		local k, body = entry.keeper, entry.body
		-- any: the brain's vector is a Vector3 here, which the checker won't cast
		local at = (k.at :: any) :: Vector3
		local facing = (k.facing :: any) :: Vector3
		body.root.CFrame = entry.on.origin * CFrame.lookAt(at, at + facing) * body.rootOffset
		local walking = k.state == "Going"
			or k.state == "Roaming"
			or k.state == "Hunting"
			or k.state == "Searching"
		local kit = body.kit
		-- asleep, slack; awake, held on a stride: mid-step where it stopped, or, never yet moved,
		-- on its walk's first key, reaching at the doorway
		local pose = if walking
			then kit.walk(k.travelled)
			elseif k.state == "Asleep" then kit.still
			else kit.stop(k.travelled)
		if pose ~= body.posed and (now or not walking or clock - body.posedAt >= POSE_EVERY) then
			kit.pose(body.model, pose)
			body.posed, body.posedAt = pose, clock
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
		local entry: Entry = {
			keeper = k,
			body = {
				model = body,
				root = root,
				rootOffset = root.PivotOffset:Inverse(),
				kit = kit,
				posed = nil,
				posedAt = -math.huge,
			},
			on = on,
		}
		table.insert(on.keepers, entry)
		place(entry, true)
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
		clock += dt
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
				if Keeper.step(k, dt, run, list) then
					place(entry)
					changedState(entry, was)
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
