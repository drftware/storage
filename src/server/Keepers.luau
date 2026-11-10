--!strict
--[[
	Keepers: the keepers' brain on the server (L-06b2a, D-064), one system on the Host's clock. It
	keeps each laid floor's map (KeeperMap) in step with its doors, tells every keeper on a floor
	what it hears there, steps each one (the pure `Keeper`) and moves its body.

	- A floor joins with `add` as it's laid (FloorBuilder's `laid.slots`): its map is built once and
	  each door's state fed in as it changes (`Doors.changed` through `KeeperMap.letsThrough`), so a
	  doorway lets keepers through only while its door is all the way up. Its keepers go with it.
	- A door's open, slam or lift from inside (`Keeper.Hears`) reaches every keeper on its floor
	  within that sound's reach (`Doors.acted` carries DoorSound's, the one players hear by),
	  measured along the halls, so no sound goes through a wall or a shut door. A keeper that hears
	  it walks to the door's front, stands there looking, and goes back.
	- Each keeper's body is an anchored model moved by its HumanoidRootPart, with no Humanoid, and
	  only while something about it changed. Its walk is posed on the server for now, at most
	  `POSE_EVERY` (L-06b4 poses it on each screen instead), so it may judder on a phone.
	- The brain works in the floor's own coordinates (its lobby's middle at the origin, its floor at
	  height 0); positions are turned from the world going in and back coming out.

	In Studio, Output says what each keeper hears and does, and each body carries its state as the
	attribute `KeeperState`. `stand` puts a keeper on a laid floor (a dev command until L-06b2b
	stands the dealt ones).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Brix = require(ReplicatedStorage.Brix)
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
	Asleep = "is still again",
	Going = "goes to look",
	Waiting = "stands at the door, looking",
	Returning = "goes back",
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
	origin: CFrame, -- the lobby's middle on the floor: the map's origin
	slots: { [Model]: number }, -- each unit, its slot in the floor
	model: Model,
	folder: Folder, -- its keepers' bodies
	keepers: { Entry },
	gone: RBXScriptConnection,
}
type Entry = { keeper: Keeper.Keeper, body: Body, on: OnFloor }

export type Keepers = Brix.System & {
	-- Lays a floor's map for keepers to walk as FloorBuilder lays it: `slots` maps each unit to its
	-- slot (`laid.slots`), `origin` is where it was laid. Its keepers go when `model` is destroyed.
	add: (
		self: any,
		floor: Floor.Floor,
		slots: { [Model]: number },
		model: Model,
		origin: CFrame
	) -> (),
	-- Stands a keeper (its row's name) on a laid floor, feet at `at`, facing `facing` (the world's).
	-- Returns its body, or nil (an unknown floor or keeper, or no template: Output says).
	stand: (self: any, name: string, model: Model, at: Vector3, facing: Vector3) -> Model?,
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

	-- Moves its body to where the brain has it and poses it.
	local function place(entry: Entry, now: boolean?)
		local k, body = entry.keeper, entry.body
		-- any: the brain's vector is a Vector3 here, which the checker won't cast
		local at = (k.at :: any) :: Vector3
		local facing = (k.facing :: any) :: Vector3
		body.root.CFrame = entry.on.origin * CFrame.lookAt(at, at + facing) * body.rootOffset
		local walking = k.state == "Going" or k.state == "Returning"
		local kit = body.kit
		local pose = if walking
			then kit.walk(k.travelled)
			elseif k.travelled > 0 then kit.stop(k.travelled)
			else kit.still
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
		if TRACE and state ~= "Going" then
			print(`Keepers: the {entry.keeper.row.name} {DOING[state]}`)
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
					print(
						`Keepers: the {k.row.name} heard Unit {slot.number}'s door {HEARD[motion]}, {math.round(
							heard
						)} studs off along the halls; it goes to look`
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
			KeeperMap.setDoor(on.map, on.slots[change.unit], KeeperMap.letsThrough(change.state))
		end
	end

	local system = { name = "Keepers" }

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Doors fills this slot (init.server)
		local d = (context.registry:get("doors") :: any) :: Doors.Doors
		doors = d
		run = StarterPlayer.CharacterWalkSpeed
		table.insert(connections, d.acted:connect(onActed))
		table.insert(connections, d.changed:connect(onChanged))
	end

	-- Only keepers awake change; a body moves only when its keeper did.
	function system.step(_: any, dt: number)
		clock += dt
		for _, on in floors do
			for _, entry in on.keepers do
				local k = entry.keeper
				local was: Keeper.State = k.state
				if Keeper.step(k, dt, run) then
					place(entry)
					changedState(entry, was)
				end
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		for _, on in floors do
			drop(on)
		end
	end

	function system.add(
		_: any,
		floor: Floor.Floor,
		slots: { [Model]: number },
		model: Model,
		origin: CFrame
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
			origin = origin,
			slots = slots,
			model = model,
			folder = folder,
			keepers = {},
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

	function system.stand(_: any, name: string, model: Model, at: Vector3, facing: Vector3): Model?
		local on = floors[model]
		local row = KeeperRows[name]
		local kit = KITS[name]
		if not (on and row and kit) then
			warn(`Keepers: can't stand a {name} on {model:GetFullName()}: no such keeper or floor`)
			return nil
		end
		local a = on.origin:PointToObjectSpace(at)
		local f = on.origin:VectorToObjectSpace(facing)
		local k = Keeper.new(row, on.map, vector.create(a.X, a.Y, a.Z), vector.create(f.X, 0, f.Z))
		local body = kit.clone(CFrame.lookAt(at, at + facing), on.folder)
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
