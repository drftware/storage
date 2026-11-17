--!strict
--[[
	MirrorView: the mirror in your home shows you (S5-03b, D-280; the maths is Shared.Mirror).

	The moment: you walk into your unit, turn to the mirror leaning on the wall, and there you are,
	the hard hat lit on your head, your unit and its lamps behind you, moving the right way round
	as you step and turn.

	The glass carries a ViewportFrame on a SurfaceGui. Inside it stands a copy of the room in
	front of the glass, built once, each piece where its reflection would stand; and a copy of
	each person near, posed every frame from them with left and right swapped. Its camera is your
	camera, looking square into the glass, and the picture is cut to the glass, so the glass is a
	window onto that copied world and the reflection shifts as you move.

	One mirror at a time: the nearest within Mirror.Still holds the room's copy, still; within
	Mirror.Live and on screen it moves with you every frame. Further off the glass is plain glass.
	The doors, the lamps and the switch in the room are copied every frame too, since they move.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local Mirror = require(ReplicatedStorage.Shared.Mirror)

local BIND = "MirrorView"
local INDEX = "MirrorIndex" -- set on a person's parts here only, to find each one's copy
local UP = Vector3.yAxis

-- the room's light in the picture: a ViewportFrame has no lamps, only an ambient and a sun
local LIT = { ambient = Color3.fromRGB(150, 138, 120), sun = Color3.fromRGB(255, 236, 205) }
local DARK = { ambient = Color3.fromRGB(34, 34, 42), sun = Color3.fromRGB(60, 60, 75) }

-- Parts of a home that move or light up, copied every frame (Home.DoorParts, the lamps, switch).
local MOVING: { [string]: boolean } = { Lamp = true, LampShade = true, SwitchToggle = true }
for _, name in Home.DoorParts do
	MOVING[name] = true
end

type Pair = { from: BasePart, to: BasePart, across: BasePart }
type Body = {
	character: Model,
	model: Model,
	pairs: { Pair },
	parts: { BasePart },
	cframes: { CFrame },
	dirty: boolean,
	connections: { RBXScriptConnection },
}
type Shown = {
	glass: BasePart,
	unit: Model?,
	gui: SurfaceGui,
	frame: ViewportFrame,
	world: WorldModel,
	camera: Camera,
	movers: { Pair },
	bodies: { [Model]: Body },
	live: boolean,
}

local MirrorView = {}

-- A copy for the picture: no physics, no sound, no scripts, nothing but how it looks.
local function strip(root: Instance)
	for _, d in root:GetDescendants() do
		if
			d:IsA("LuaSourceContainer")
			or d:IsA("Sound")
			or d:IsA("Light")
			or d:IsA("JointInstance")
			or d:IsA("Constraint")
			or d:IsA("WeldConstraint")
			or d:IsA("ProximityPrompt")
			or d:IsA("BillboardGui")
			or d:IsA("ParticleEmitter")
			or d:IsA("ForceField")
			or d:IsA("ClickDetector")
		then
			d:Destroy()
		elseif d:IsA("Decal") then
			d.LocalTransparencyModifier = 0
		elseif d:IsA("BasePart") then
			d.LocalTransparencyModifier = 0 -- your own head, hidden in first person, still shows here
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
end

-- `cf` as its reflection's copy stands: through the glass (`c`, `n`), turned over across `a`.
local function reflected(cf: CFrame, c: Vector3, n: Vector3, a: Vector3): CFrame
	local x, y, z = Mirror.columns(cf.XVector, cf.YVector, cf.ZVector, n, a)
	return CFrame.fromMatrix(Mirror.point(cf.Position, c, n), x, y, z)
end

local function looks(from: BasePart, to: BasePart)
	if to.Transparency ~= from.Transparency then
		to.Transparency = from.Transparency
	end
	if to.Color ~= from.Color then
		to.Color = from.Color
	end
	if to.Material ~= from.Material then
		to.Material = from.Material
	end
end

function MirrorView.new(): Brix.System
	local connections: { RBXScriptConnection } = {}
	local shown: Shown? = nil
	local untilPick = 0

	local function glassFrame(glass: BasePart): (Vector3, Vector3, Vector3, Vector3)
		local cf = glass.CFrame
		local n = cf.LookVector
		-- the Front face's middle; its right and up as someone facing it sees them
		return cf.Position + n * (glass.Size.Z / 2), n, -cf.RightVector, cf.UpVector
	end

	-- The home or climb unit a part belongs to (a lobby slot's front), if any.
	local function unitOf(p: Instance): Instance?
		local at = p.Parent
		while at and at ~= Workspace do
			if at:GetAttribute("LobbySlot") ~= nil then
				return at
			end
			at = at.Parent
		end
		return nil
	end

	-- The room in front of the glass, copied behind it once: everything of the glass's floor
	-- within Mirror.Reach whose middle is in front of the glass (or a floor or ceiling crossing
	-- it), but not the mirror itself nor the neighbours' units.
	local function copyRoom(s: Shown)
		local glass = s.glass
		local c, n = glassFrame(glass)
		local mine = glass.Parent
		local top: Instance = glass
		while top.Parent and top.Parent ~= Workspace do
			top = top.Parent :: Instance
		end
		local count = 0
		for _, d in top:GetDescendants() do
			if count >= Mirror.MaxParts then
				break
			end
			if
				not d:IsA("BasePart")
				or d.Transparency >= 0.99
				or d:IsDescendantOf(mine :: Instance)
			then
				continue
			end
			local p = d :: BasePart
			local owner = unitOf(p)
			if owner and owner ~= s.unit then
				continue -- a neighbour's unit: all behind the walls
			end
			local half = p.Size.Magnitude / 2
			local ahead = (p.Position - c):Dot(n)
			if (p.Position - c).Magnitude - half > Mirror.Reach or ahead + half < 0 then
				continue
			end
			local cf = p.CFrame
			local i = Mirror.axis(cf.XVector, cf.YVector, cf.ZVector, p.Size, UP)
			local across = if i == 1 then cf.XVector elseif i == 2 then cf.YVector else cf.ZVector
			if ahead < 0 then
				-- crossing the glass: only a floor or ceiling (flat, level) is let through
				local i2 = 0
				local most = -1
				for k, v in { cf.XVector, cf.YVector, cf.ZVector } do
					local u = math.abs(v:Dot(UP))
					if u > most then
						i2, most = k, u
					end
				end
				local sizes = { p.Size.X, p.Size.Y, p.Size.Z }
				if sizes[i2] > math.min(sizes[1], sizes[2], sizes[3]) + 1e-3 then
					continue
				end
			end
			p.Archivable = true
			local copy = p:Clone()
			if not copy then
				continue
			end
			copy:ClearAllChildren()
			for _, child in p:GetChildren() do
				if
					child:IsA("SurfaceAppearance")
					or child:IsA("Decal")
					or child:IsA("DataModelMesh")
				then
					(child :: Instance):Clone().Parent = copy
				end
			end
			copy.Anchored = true
			copy.CFrame = reflected(cf, c, n, across)
			copy.Parent = s.world
			count += 1
			if
				(MOVING[p.Name] or p.Name:sub(1, 4) == "Slat")
				and s.unit
				and p:IsDescendantOf(s.unit :: Model)
			then
				table.insert(s.movers, { from = p, to = copy, across = p })
			end
		end
	end

	local function dropBody(s: Shown, character: Model)
		local body = s.bodies[character]
		if body then
			for _, c in body.connections do
				c:Disconnect()
			end
			body.model:Destroy()
			s.bodies[character] = nil
		end
	end

	-- A person's copy: their character cloned, stripped, each part paired with the part whose
	-- pose it takes (a body part's partner across the body; anything worn, itself).
	local function addBody(s: Shown, character: Model): Body?
		local head = character:FindFirstChild("Head")
		if not (head and head:IsA("BasePart")) then
			return nil
		end
		local originals: { BasePart } = {}
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				table.insert(originals, d)
				d:SetAttribute(INDEX, #originals)
			end
		end
		local was = character.Archivable
		character.Archivable = true
		local model = character:Clone()
		character.Archivable = was
		if not model then
			return nil
		end
		local copied = model:FindFirstChildOfClass("Humanoid")
		if copied then
			-- it keeps the clothes on; with its joints gone it mustn't think it has died
			copied.RequiresNeck = false
			copied.BreakJointsOnDeath = false
		end
		strip(model)
		local root = model:FindFirstChild("HumanoidRootPart")
		if root then
			root:Destroy()
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		local copies: { [number]: BasePart } = {}
		for _, d in model:GetDescendants() do
			local i = d:GetAttribute(INDEX)
			if d:IsA("BasePart") and type(i) == "number" then
				copies[i] = d
			end
		end
		local body: Body = {
			character = character,
			model = model,
			pairs = {},
			parts = {},
			cframes = {},
			dirty = false,
			connections = {},
		}
		for i, from in originals do
			local to = copies[i]
			if not to then
				continue
			end
			local across: BasePart = head
			if from.Parent == character then
				-- a body part: drawn with its partner, turned over across its own left and right
				local partner = model:FindFirstChild(Mirror.partner(from.Name))
				if partner and partner:IsA("BasePart") then
					to = partner
				end
				across = from
			end
			table.insert(body.pairs, { from = from, to = to, across = across })
			table.insert(body.parts, to)
			table.insert(body.cframes, to.CFrame)
		end
		local function dirty()
			body.dirty = true
		end
		table.insert(body.connections, character.DescendantAdded:Connect(dirty))
		table.insert(body.connections, character.DescendantRemoving:Connect(dirty))
		model.Parent = s.world
		s.bodies[character] = body
		return body
	end

	local function lightOf(s: Shown)
		local on = if s.unit then s.unit:GetAttribute(Home.LightAttribute) ~= false else true
		local l = if on then LIT else DARK
		s.frame.Ambient = l.ambient
		s.frame.LightColor = l.sun
	end

	local function tearDown()
		local s = shown
		if not s then
			return
		end
		shown = nil
		RunService:UnbindFromRenderStep(BIND)
		for character in s.bodies do
			dropBody(s, character)
		end
		s.gui:Destroy()
	end

	-- Every frame while live: the picture's camera and cut from your eye, people posed.
	local function draw()
		local s = shown
		if not s then
			return
		end
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local c, n, right, up = glassFrame(s.glass)
		local eye = camera.CFrame.Position
		local v = Mirror.view(eye, c, n, right, up, s.glass.Size.X, s.glass.Size.Y)
		if not v then
			return
		end
		local ppu = Mirror.PixelsPerStud
		s.frame.Size = UDim2.fromOffset(v.width * ppu, v.height * ppu)
		s.frame.Position = UDim2.new(0.5, v.x * ppu, 0.5, -v.y * ppu)
		s.camera.FieldOfView = v.fov
		s.camera.CFrame = CFrame.fromMatrix(eye, right, up)
		for _, body in s.bodies do
			for i, pair in body.pairs do
				body.cframes[i] = reflected(pair.from.CFrame, c, n, pair.across.CFrame.XVector)
			end
			s.world:BulkMoveTo(body.parts, body.cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end
		for _, m in s.movers do
			local cf = m.from.CFrame
			local i = Mirror.axis(cf.XVector, cf.YVector, cf.ZVector, m.from.Size, UP)
			local across = if i == 1 then cf.XVector elseif i == 2 then cf.YVector else cf.ZVector
			m.to.CFrame = reflected(cf, c, n, across)
		end
	end

	-- A still picture from a step in front of the glass at eye height, for a mirror not live.
	local function still(s: Shown)
		local c, n, right, up = glassFrame(s.glass)
		local eye = c + n * 7
		local v = Mirror.view(eye, c, n, right, up, s.glass.Size.X, s.glass.Size.Y)
		if v then
			local ppu = Mirror.PixelsPerStud
			s.frame.Size = UDim2.fromOffset(v.width * ppu, v.height * ppu)
			s.frame.Position = UDim2.new(0.5, v.x * ppu, 0.5, -v.y * ppu)
			s.camera.FieldOfView = v.fov
			s.camera.CFrame = CFrame.fromMatrix(eye, right, up)
		end
	end

	local function build(glass: BasePart): Shown
		local player = Players.LocalPlayer
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Mirror"
		gui.Adornee = glass
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = Mirror.PixelsPerStud
		gui.LightInfluence = 0
		gui.ClipsDescendants = true
		gui.ResetOnSpawn = false
		local frame = Instance.new("ViewportFrame")
		frame.Name = "Picture"
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.BackgroundColor3 = Color3.fromRGB(40, 36, 32)
		frame.BackgroundTransparency = 0
		frame.BorderSizePixel = 0
		frame.ImageColor3 = Color3.fromRGB(236, 242, 244) -- a breath of the glass's own cool
		frame.LightDirection = Vector3.new(0.25, -1, 0.35)
		frame.Parent = gui
		local world = Instance.new("WorldModel")
		world.Parent = frame
		local camera = Instance.new("Camera")
		camera.Parent = frame
		frame.CurrentCamera = camera
		-- the unit it stands in, for its light and the parts of it that move
		local unit: Model? = nil
		local up = glass:FindFirstAncestorWhichIsA("Model")
		while up do
			if up:GetAttribute(Home.LightAttribute) ~= nil then
				unit = up
				break
			end
			up = up:FindFirstAncestorWhichIsA("Model")
		end
		local s: Shown = {
			glass = glass,
			unit = unit,
			gui = gui,
			frame = frame,
			world = world,
			camera = camera,
			movers = {},
			bodies = {},
			live = false,
		}
		copyRoom(s)
		lightOf(s)
		still(s)
		gui.Parent = player:WaitForChild("PlayerGui")
		return s
	end

	-- Which mirror holds the picture, whether it's live, and who stands in front of it.
	local function pick()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local eye = camera.CFrame.Position
		local best: BasePart? = nil
		local bestDistance = Mirror.Still
		for _, inst in CollectionService:GetTagged(Mirror.Tag) do
			if inst:IsA("BasePart") and inst:IsDescendantOf(Workspace) then
				local distance = (inst.Position - eye).Magnitude
				if distance < bestDistance then
					best, bestDistance = inst, distance
				end
			end
		end
		if shown and shown.glass ~= best then
			tearDown()
		end
		if not best then
			return
		end
		if not shown then
			shown = build(best)
		end
		local s = shown :: Shown
		local c, n = glassFrame(best)
		local _, onScreen = camera:WorldToViewportPoint(c)
		local live = bestDistance <= Mirror.Live and (eye - c):Dot(n) > Mirror.Near and onScreen
		if live ~= s.live then
			s.live = live
			if live then
				RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, draw)
			else
				RunService:UnbindFromRenderStep(BIND)
				for character in s.bodies do
					dropBody(s, character)
				end
				still(s)
			end
		end
		lightOf(s)
		if not live then
			return
		end
		-- people near and in front come and go; anyone whose clothes changed is copied again
		local near: { [Model]: boolean } = {}
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if character and root and root:IsA("BasePart") then
				local p = root.Position
				if (p - c).Magnitude <= Mirror.Reach and (p - c):Dot(n) > -1 then
					near[character] = true
				end
			end
		end
		for character, body in s.bodies do
			if not near[character] or body.dirty or not character.Parent then
				dropBody(s, character)
			end
		end
		for character in near do
			local body = s.bodies[character]
			if not body then
				addBody(s, character)
			else
				for _, pair in body.pairs do
					looks(pair.from, pair.to)
				end
			end
		end
	end

	return {
		name = "MirrorView",
		start = function(_: any, _context: Brix.Context) end,
		step = function(_: any, dt: number)
			untilPick -= dt
			if untilPick <= 0 then
				untilPick = Mirror.Pick
				pick()
			end
		end,
		stop = function(_: any)
			tearDown()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

return MirrorView
