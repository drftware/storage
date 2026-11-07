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

	The same door keeps the hall's light out. Shut in, you sit in the dark with a bright line of
	light under the door, and a friend lifting it floods light in (ShutIn.light). Full graphics
	quality does that with real shadows; low-graphics phones light a unit through its walls
	(D-016), so on your own screen the hall's lights (HallLight.Tag) are scaled down while you're
	shut in and the line under the door is drawn as a thin glowing strip on the hall floor.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local HallLight = require(ReplicatedStorage.Shared.HallLight)
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

-- The line under the door: a strip on the hall floor just outside the curtain, where an eye
-- inside sees the floor through the door's gap (door-local, -Z is the hall).
local LINE_DEPTH = 0.5
local LINE_OUT = 0.3
local LINE_THICK = 0.01

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
	local lights: { Light } = {}
	local dimmed = false -- whether the hall's lights are scaled down on this screen now
	local line: Part? = nil -- the line under the door, made the first time you're shut in

	local function addLight(inst: Instance)
		if inst:IsA("Light") and not table.find(lights, inst) then
			table.insert(lights, inst)
		end
	end

	local function removeLight(inst: Instance)
		local i = table.find(lights, inst :: any) -- any: the removed signal hands back an Instance
		if i then
			lights[i] = lights[#lights]
			lights[#lights] = nil
		end
	end

	-- Scales a hall light to `level` of its lit brightness, writing only when it differs.
	local function scaleLight(light: Light, level: number)
		local lit = light:GetAttribute(HallLight.LitAttribute)
		if typeof(lit) == "number" then
			local want = lit * level
			if math.abs(light.Brightness - want) > 1e-3 then
				light.Brightness = want
			end
		end
	end

	-- How lit the hall is at `at`, 0 to 1: the strongest tube that reaches it. Only the tubes
	-- light the floor white; the exit sign's red glow doesn't draw a line.
	local function hallLitAt(at: Vector3): number
		local most = 0
		for _, light in lights do
			local tube = light.Parent
			local lit = light:GetAttribute(HallLight.LitAttribute)
			if
				light:IsA("SurfaceLight")
				and light.Enabled
				and typeof(lit) == "number"
				and tube
				and tube:IsA("BasePart")
				and (tube.Position - at).Magnitude < light.Range
			then
				most = math.max(most, lit / HallLight.Brightness)
			end
		end
		return math.min(most, 1)
	end

	-- Draws the line under `room`'s door at `alpha` (0 hides it).
	local function drawLine(room: Room?, alpha: number)
		if not room or alpha <= 0 then
			if line then
				line.Parent = nil
			end
			return
		end
		local strip: Part
		if line then
			strip = line
		else
			strip = Instance.new("Part")
			strip.Name = "LineUnderDoor"
			strip.Anchored = true
			strip.CanCollide = false
			strip.CanQuery = false
			strip.CanTouch = false
			strip.CastShadow = false
			strip.Material = Enum.Material.Neon
			strip.Color = HallLight.UnderDoorColour
			line = strip
		end
		local size = Vector3.new(room.spec.DoorWidth, LINE_THICK, LINE_DEPTH)
		local at = room.frame * CFrame.new(0, LINE_THICK / 2, -LINE_OUT)
		if strip.Size ~= size then
			strip.Size = size
		end
		if strip.CFrame ~= at then
			strip.CFrame = at
		end
		local transparency = 1 - alpha
		if math.abs(strip.Transparency - transparency) > 1e-3 then
			strip.Transparency = transparency
		end
		strip.Parent = Workspace
	end

	local function addRoom(inst: Instance)
		-- Only units in the world. The template in ReplicatedStorage carries the same tag and sits
		-- at the origin, mid-hall in DevCorridor: counted as a room, it "shut you in" as you walked
		-- through it, darkening the hall and drawing the line under its door (P0-02j).
		if
			not inst:IsA("Model")
			or not inst:IsDescendantOf(Workspace)
			or not inst:FindFirstChild("DoorOrigin", true)
		then
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
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(HallLight.Tag):Connect(addLight)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(HallLight.Tag):Connect(removeLight)
			)
			for _, light in CollectionService:GetTagged(HallLight.Tag) do
				addLight(light)
			end
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
			local shutIn: Room? = nil
			for _, r in rooms do
				local p = r.frame:PointToObjectSpace(eye)
				r.viewerInside = ShutIn.inside(r.spec, p.X, p.Y, p.Z)
				if r.viewerInside then
					shutIn = r
				end
			end
			-- The hall's light reaches you as far as your door lets it.
			local level, lineAlpha = 1, 0
			if shutIn then
				local rise = RollUpDoor.rise(shutIn.unit)
				level = ShutIn.light(rise, shutIn.spec.Rise.Open)
				-- The line fades as the door lifts and the real light pours under it.
				local closed = 1 - math.clamp(rise / shutIn.spec.Rise.Peek, 0, 1)
				if closed > 0 then
					lineAlpha = closed * hallLitAt(shutIn.frame.Position)
				end
			end
			if level < 1 or dimmed then
				for _, light in lights do
					scaleLight(light, level)
				end
				dimmed = level < 1
			end
			drawLine(shutIn, lineAlpha)
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
			for _, light in lights do
				scaleLight(light, 1)
			end
			dimmed = false
			if line then
				line:Destroy()
				line = nil
			end
			table.clear(lights)
			table.clear(rooms)
			table.clear(others)
		end,
	}
end

return BehindDoors
