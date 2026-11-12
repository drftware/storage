--!strict
--[[
	DoorSpotView: keeps a door's buttons on this screen where your hand would go (L-19b, the rule
	in `DoorSpot`).

	The server puts each door's button spots on the door: Open's at the middle, Peek's low by the
	lift handle, Lock and Cut on the latch. In first person a button shows only while its spot is
	on screen, so walk up to a shut door and Peek's spot by the ground would drop out of view just
	as you reach for it. This screen moves its own copy of each spot near you: a low one rides up
	the door just far enough to stay in view (step back, or look down at it, and it settles onto
	the handle again); the latch's slides in along the bottom bar until it's near your gaze, clear
	of a phone's torch and jump buttons; and while you kneel to peek the middle row comes down with
	your eye, never over the gap.

	Only spots near you are moved, and only when your eye moves them. Every other screen keeps its
	own; the server still judges a press from where it put the spot (with its slack for reach).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local DoorSpot = require(ReplicatedStorage.Shared.StorageUnit.DoorSpot)
local Kneel = require(ReplicatedStorage.Shared.StorageUnit.Kneel)

local NEAR = 14 -- studs from your eye a spot is looked after: past a button's reach (8), with room
local LOOK_EVERY = 0.2 -- seconds between looks for which spots are near
local SETTLE = 0.01 -- studs a spot must move before it's written again

-- A door's button spot this screen may move.
type Spot = {
	attachment: Attachment,
	home: Vector3, -- its position in its part, as the server put it
	spot: Door.Spot,
	height: number, -- studs off the floor it belongs (DoorSpot.Height)
	across: number, -- studs across the door from its middle (the latch's; 0 for the others)
	world: Vector3, -- where the server put it in the world (refreshed with each look)
	middle: Vector3, -- the door's middle at its height (the latch slides in toward it)
	out: Vector3, -- the way out of the door into the hall, flat
	shift: Vector3, -- how far this screen has it moved from there
}

local DoorSpotView = {}

function DoorSpotView.new(): Brix.System
	local player = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local spots: { [Attachment]: Spot } = {}
	local near: { Spot } = {}
	local since = LOOK_EVERY

	local function home(s: Spot)
		if s.shift ~= Vector3.zero then
			s.shift = Vector3.zero
			if s.attachment.Parent then
				s.attachment.Position = s.home
			end
		end
	end

	local function added(inst: Instance)
		if not inst:IsA("Attachment") or spots[inst] then
			return
		end
		local name = inst:GetAttribute(DoorSpot.Attribute)
		local spot: Door.Spot? = nil
		for _, s: Door.Spot in Door.Spots do
			if s == name then
				spot = s
			end
		end
		if not spot then
			return
		end
		local across = inst:GetAttribute(DoorSpot.Across)
		spots[inst] = {
			attachment = inst,
			home = inst.Position,
			spot = spot,
			height = DoorSpot.Height[spot],
			across = if type(across) == "number" then across else 0,
			world = inst.WorldPosition,
			middle = inst.WorldPosition,
			out = Vector3.zAxis,
			shift = Vector3.zero,
		}
	end

	local function removed(inst: Instance)
		local s = spots[inst :: Attachment]
		if not s then
			return
		end
		spots[inst :: Attachment] = nil
		home(s)
		local i = table.find(near, s)
		if i then
			table.remove(near, i)
		end
	end

	-- Which spots are near your eye now; any that's left goes back where the server put it.
	local function look(eye: Vector3)
		table.clear(near)
		for a, s in spots do
			if a.Parent then
				local world = a.WorldPosition - s.shift
				if (world - eye).Magnitude <= NEAR then
					local frame = a.WorldCFrame
					local out = frame.LookVector * Vector3.new(1, 0, 1)
					s.world = world
					s.middle = world - frame.RightVector * s.across
					s.out = if out.Magnitude > 1e-3 then out.Unit else Vector3.zAxis
					table.insert(near, s)
				else
					home(s)
				end
			end
		end
	end

	-- Where your eye would be standing, off the floor: so a jump or a step up doesn't lift a spot.
	local function standingEye(): number?
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (humanoid and root and root:IsA("BasePart")) then
			return nil
		end
		return Kneel.standingEye(humanoid.HipHeight, root.Size.Y)
	end

	local function step(_: any, dt: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local view = camera.CFrame
		local eye = view.Position
		local gaze = view.LookVector
		local pitch = math.asin(math.clamp(gaze.Y, -1, 1))
		local flat = gaze * Vector3.new(1, 0, 1)
		local facing = if flat.Magnitude > 1e-3 then flat.Unit else nil
		since += dt
		if since >= LOOK_EVERY then
			since = 0
			look(eye)
		end
		if #near == 0 then
			return
		end
		local standing = standingEye()
		for _, s in near do
			local d = (eye - s.world):Dot(s.out)
			if not standing or d <= 0 then
				-- no body to see with, or inside the unit: the server's spot is right
				home(s)
			else
				-- the latch's in along the bar toward your gaze, as far as it must
				local at = s.world
				if s.across ~= 0 and facing then
					local m = s.middle
					local f = facing :: Vector3
					at += (m - at) * DoorSpot.slide(eye.X, eye.Z, f.X, f.Z, at.X, at.Z, m.X, m.Z)
				end
				-- and up the door into view, or down with your eye as you kneel
				local floor = s.world.Y - s.height
				local h = DoorSpot.height(s.spot, math.min(eye.Y - floor, standing), d, pitch)
				local shift = at - s.world + Vector3.new(0, h - s.height, 0)
				if shift.Magnitude < SETTLE then
					home(s)
				elseif (shift - s.shift).Magnitude >= SETTLE then
					s.shift = shift
					s.attachment.WorldPosition = s.world + shift
				end
			end
		end
	end

	local system = {
		name = "DoorSpotView",
	}

	function system.start(_: any, _context: Brix.Context)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(DoorSpot.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(DoorSpot.Tag):Connect(removed)
		)
		for _, inst in CollectionService:GetTagged(DoorSpot.Tag) do
			added(inst)
		end
	end

	system.step = step

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, s in spots do
			home(s)
		end
		table.clear(spots)
		table.clear(near)
	end

	return system
end

return DoorSpotView
