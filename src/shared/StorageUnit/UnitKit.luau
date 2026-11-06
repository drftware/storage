--!strict
--[[
	UnitKit: turn an imported StorageUnit_<Size>.fbx into a game-ready unit, and dress units.

	Once, in Studio, right after the 3D Importer (command bar):
		local SU = require(game.ReplicatedStorage.Shared.StorageUnit)
		SU.UnitKit.prepare(workspace.StorageUnit_M, "M")
	then keep the result as the template (e.g. ReplicatedStorage.Units.M).

	Per placed unit, on the server:
		UnitKit.paint(unit, doorColour, wallColour)   -- Overlay tints, one texture set for all
		UnitKit.number(unit, "214")                   -- unit number on its plate
		UnitKit.dropWall(unit, "WallLeft")            -- a neighbour already has this wall
]]

local CollectionService = game:GetService("CollectionService")

local Motion = require(script.Parent.Motion)
local RollUpDoor = require(script.Parent.RollUpDoor)
local Specs = require(script.Parent.Specs)

local UnitKit = {}

UnitKit.Tag = "StorageUnit"
UnitKit.Colours = {
	Door = {
		Oxblood = Color3.fromRGB(126, 42, 34),
		Teal = Color3.fromRGB(47, 100, 102),
		Mustard = Color3.fromRGB(176, 131, 44),
		Navy = Color3.fromRGB(52, 80, 127),
	},
	Wall = Color3.fromRGB(207, 202, 192),
}

local MOVING =
	{ "Slat_A", "Slat_B", "Slat_C", "CurtainClosed", "BottomBar", "LatchBolt", "Padlock", "Drum" }
local TINTED = { Slat_A = true, Slat_B = true, Slat_C = true, CurtainClosed = true, Facade = true }

local function find(unit: Model, name: string): BasePart?
	return unit:FindFirstChild(name, true) :: BasePart?
end

--[[
	Run once on the freshly imported model (door shut and locked, as exported). Safe to run
	again: calibrations already stored are kept.
]]
function UnitKit.prepare(unit: Model, size: string?)
	local sz = size or (unit:GetAttribute("UnitSize") :: string?) or "M"
	unit:SetAttribute("UnitSize", sz)
	local spec = Specs[sz]
	assert(spec, `UnitKit: no spec for size {sz}`)
	local frame = RollUpDoor.frame(unit)

	for _, name in MOVING do
		local p = find(unit, name)
		if p and p:GetAttribute("DoorOffset") == nil then
			p:SetAttribute("DoorOffset", RollUpDoor.offset(p, frame, spec, name))
		end
	end

	for _, d in unit:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		elseif d:IsA("SurfaceAppearance") then
			-- Overlay shows MeshPart.Color where the ColorMap's alpha is 0. Plugin security:
			-- works from the command bar, harmless to skip at runtime.
			pcall(function()
				(d :: any).AlphaMode = Enum.AlphaMode.Overlay
			end)
		end
	end
	local origin = find(unit, "DoorOrigin")
	if origin then
		origin.Transparency = 1
		origin.CastShadow = false
	end
	local plate = find(unit, "NumberPlate")
	if plate then
		plate.CastShadow = false
	end
	-- a door at rest is the merged CurtainClosed; the slat templates are clone sources only
	if find(unit, "CurtainClosed") then
		for _, v in { "A", "B", "C" } do
			local t = find(unit, "Slat_" .. v)
			if t then
				t.Transparency = 1
			end
		end
	end

	-- collision: plain boxes from the spec, in the unit's frame (the doorway's outer face)
	local unitFrame = frame * CFrame.new(0, 0, -spec.CurtainPlane)
	local old = unit:FindFirstChild("Colliders")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Colliders"
	for name, c in spec.Colliders :: any do
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = c.Size
		p.CFrame = unitFrame * CFrame.new(c.Position)
		p.Parent = folder
	end
	folder.Parent = unit
	local door = unit:FindFirstChild("DoorCollider") :: BasePart?
	if not door then
		local p = Instance.new("Part")
		p.Name = "DoorCollider"
		p.Anchored = true
		p.CanQuery = true
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Parent = unit
		door = p
	end
	local col = door :: BasePart
	local h = spec.DoorHeight - spec.Gap
	col.CanCollide = true
	col.Size = Vector3.new(spec.DoorWidth, h, 0.4)
	col.CFrame = frame * CFrame.new(0, spec.Gap + h / 2, 0)

	unit:SetAttribute("DoorMotion", Motion.encode("Close", 0, 0, 0))
	unit:SetAttribute("DoorLocked", false)
	unit.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	if origin then
		unit.PrimaryPart = origin
	end
	CollectionService:AddTag(unit, UnitKit.Tag)
	UnitKit.paint(unit, UnitKit.Colours.Door.Oxblood, UnitKit.Colours.Wall)
end

-- Door and corridor-wall colours. Every other part keeps white (its texture is opaque).
function UnitKit.paint(unit: Model, door: Color3, wall: Color3?)
	for _, d in unit:GetDescendants() do
		if
			d:IsA("BasePart")
			and d.Name ~= "DoorCollider"
			and d.Parent
			and d.Parent.Name ~= "Colliders"
		then
			if d.Name == "Facade" then
				d.Color = wall or UnitKit.Colours.Wall
			elseif
				TINTED[d.Name] or (d.Parent.Name == "Curtain" and d.Name:sub(1, 4) == "Slat")
			then
				d.Color = door
			else
				d.Color = Color3.new(1, 1, 1)
			end
		end
	end
end

-- The unit number, on whichever face of the plate looks out to the hallway.
function UnitKit.number(unit: Model, text: string)
	local plate = find(unit, "NumberPlate")
	if not plate then
		return
	end
	local look = plate.CFrame:VectorToObjectSpace(RollUpDoor.frame(unit).LookVector)
	local best, bestDot = Enum.NormalId.Front, -math.huge
	for _, id in Enum.NormalId:GetEnumItems() do
		local d = Vector3.FromNormalId(id :: Enum.NormalId):Dot(look)
		if d > bestDot then
			best, bestDot = id :: Enum.NormalId, d
		end
	end
	local gui = plate:FindFirstChild("Number") :: SurfaceGui?
	if not gui then
		local g = Instance.new("SurfaceGui")
		g.Name = "Number"
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 120
		g.LightInfluence = 1
		g.MaxDistance = 80
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
		label.TextColor3 = Color3.fromRGB(228, 225, 216)
		label.TextScaled = true
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0.16, 0)
		pad.PaddingBottom = UDim.new(0.12, 0)
		pad.PaddingLeft = UDim.new(0.1, 0)
		pad.PaddingRight = UDim.new(0.1, 0)
		pad.Parent = label
		label.Parent = g
		g.Parent = plate
		gui = g
	end
	local g = gui :: SurfaceGui
	g.Face = best
	local label = g:FindFirstChild("Label") :: TextLabel
	label.Text = text
end

-- Remove a wall a neighbour already provides (WallLeft, WallRight, WallBack, WireTop), with
-- its collider.
function UnitKit.dropWall(unit: Model, name: string)
	local part = unit:FindFirstChild(name)
	if part then
		part:Destroy()
	end
	local cols = unit:FindFirstChild("Colliders")
	local c = cols and cols:FindFirstChild(name)
	if c then
		c:Destroy()
	end
end

return UnitKit
