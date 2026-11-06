--!strict
--[[
	BehindDoors: on this client, anyone a shut roll-up door stands between you and isn't drawn.
	A friend shut in a unit is a sound behind the door (their footsteps still play), never a hand
	through it: a running arm swings about 0.8 studs past the slats even against the thick collider
	(docs/STUDIO.md, "Arms through a shut door"). The rule is ShutIn's; the moment the door starts
	to lift, they appear. Their name tag goes with them: it belongs to the Humanoid, not the parts,
	so hiding sets this client's copy of DisplayDistanceType to None and puts the old value back
	(docs/STUDIO.md, "Hiding a character's name"). Your own character is first person's business
	and is never touched.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local ShutIn = require(ReplicatedStorage.Shared.StorageUnit.ShutIn)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)

local RollUpDoor = StorageUnit.RollUpDoor

type Room = {
	unit: Model,
	frame: CFrame,
	spec: Specs.Spec,
	viewerInside: boolean, -- refreshed each step from the camera
}

-- A character hidden now.
type Hidden = {
	added: RBXScriptConnection, -- hides anything added to the character while hidden (a tool)
	humanoid: Humanoid?, -- whose name display was turned off
	display: Enum.HumanoidDisplayDistanceType, -- what it was before, put back on show
}

local BehindDoors = {}

local function fade(inst: Instance, amount: number)
	-- Two classes share the property but no type, so each branch narrows on its own.
	-- selene: allow(if_same_then_else)
	if inst:IsA("BasePart") then
		inst.LocalTransparencyModifier = amount
	elseif inst:IsA("Decal") then
		inst.LocalTransparencyModifier = amount
	end
end

function BehindDoors.new(): Brix.System
	local rooms: { Room } = {}
	local others: { Player } = {}
	local hidden: { [Model]: Hidden } = {}
	local connections: { RBXScriptConnection } = {}

	local function addRoom(inst: Instance)
		if not inst:IsA("Model") or not inst:FindFirstChild("DoorOrigin", true) then
			return
		end
		for _, r in rooms do
			if r.unit == inst then
				return
			end
		end
		table.insert(rooms, {
			unit = inst,
			frame = RollUpDoor.frame(inst),
			spec = RollUpDoor.spec(inst),
			viewerInside = false,
		})
	end

	local function removeRoom(inst: Instance)
		for i, r in rooms do
			if r.unit == inst then
				rooms[i] = rooms[#rooms]
				rooms[#rooms] = nil
				return
			end
		end
	end

	local function addPlayer(player: Player)
		if player ~= Players.LocalPlayer then
			table.insert(others, player)
		end
	end

	local function removePlayer(player: Player)
		local i = table.find(others, player)
		if i then
			others[i] = others[#others]
			others[#others] = nil
		end
	end

	local function hide(character: Model)
		for _, d in character:GetDescendants() do
			fade(d, 1)
		end
		-- This write stays on this client: the friend and everyone else still see the name.
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local display = Enum.HumanoidDisplayDistanceType.Viewer
		if humanoid then
			display = humanoid.DisplayDistanceType
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		hidden[character] = {
			added = character.DescendantAdded:Connect(function(d: Instance)
				fade(d, 1)
			end),
			humanoid = humanoid,
			display = display,
		}
	end

	local function show(character: Model)
		local was = hidden[character]
		if was then
			was.added:Disconnect()
			if was.humanoid then
				was.humanoid.DisplayDistanceType = was.display
			end
			hidden[character] = nil
		end
		for _, d in character:GetDescendants() do
			fade(d, 0)
		end
	end

	-- Whether a shut door stands between the camera and this point (rooms' viewerInside is fresh).
	local function behindShutDoor(at: Vector3): boolean
		for _, r in rooms do
			local p = r.frame:PointToObjectSpace(at)
			local inside = ShutIn.inside(r.spec, p.X, p.Y, p.Z)
			-- Only a room exactly one of you is in can hide; read the door only then.
			if
				inside ~= r.viewerInside
				and ShutIn.hides(RollUpDoor.rise(r.unit), inside, r.viewerInside)
			then
				return true
			end
		end
		return false
	end

	return {
		name = "BehindDoors",
		start = function(_: any, _context: Brix.Context)
			local tag = StorageUnit.UnitKit.Tag
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(tag):Connect(function(unit: Instance)
					-- Deferred so a streamed unit's parts are all in place before its frame is read.
					task.defer(addRoom, unit)
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(tag):Connect(removeRoom)
			)
			table.insert(connections, Players.PlayerAdded:Connect(addPlayer))
			table.insert(connections, Players.PlayerRemoving:Connect(removePlayer))
			for _, unit in CollectionService:GetTagged(tag) do
				addRoom(unit)
			end
			for _, player in Players:GetPlayers() do
				addPlayer(player)
			end
		end,
		step = function(_: any, _dt: number)
			local camera = Workspace.CurrentCamera
			if not camera then
				return
			end
			local eye = camera.CFrame.Position
			for _, r in rooms do
				local p = r.frame:PointToObjectSpace(eye)
				r.viewerInside = ShutIn.inside(r.spec, p.X, p.Y, p.Z)
			end
			for _, player in others do
				local character = player.Character
				local root = character and character.PrimaryPart
				if character and root then
					local shouldHide = behindShutDoor(root.Position)
					if shouldHide ~= (if hidden[character] then true else false) then
						if shouldHide then
							hide(character)
						else
							show(character)
						end
					end
				end
			end
			-- Forget characters that are gone (respawned or left); their name went with them.
			for character, was in hidden do
				if not character.Parent then
					was.added:Disconnect()
					hidden[character] = nil
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for character in hidden do
				show(character)
			end
			table.clear(rooms)
			table.clear(others)
		end,
	}
end

return BehindDoors
