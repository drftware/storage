--!strict
--[[
	A tool's or a find's 3D picture in a ViewportFrame, the way the slots show them: the thing
	tipped towards the camera by its catalog row's `icon` and filling the square. Shared by the
	slots (ToolView) and a kept find rising out of them (KeepView).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Catalog = Tools.Catalog
local RAD = math.pi / 180

local ToolPicture = {}

-- Solid gold that catches any light (the item catalog's Gold): the find's own shape, gilded.
local GOLD = Color3.fromRGB(255, 196, 64)

-- Every part of `model` turned to gold: its textures off, metal of one colour.
local function gild(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("SurfaceAppearance") or d:IsA("Decal") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Color = GOLD
			d.Material = Enum.Material.Metal
			if d:IsA("MeshPart") then
				d.TextureID = ""
			end
		end
	end
end

-- Draws `key`'s tool in `frame` (empty for ""), a Gold's ("Teddy:Gold") as its find gilded.
-- Returns the model drawn, if any.
function ToolPicture.draw(frame: ViewportFrame, key: string): Model?
	frame:ClearAllChildren()
	local base = Gold.base(key)
	local row = Catalog[base or key]
	if not row then
		return nil
	end
	local model = Tools.clone(base or key, CFrame.identity)
	if not model then
		return nil
	end
	if base then
		gild(model)
	end
	local body = Tools.body(model)
	local length = if body then body.Size.Magnitude else 2
	local centre = if body then body.Position else Vector3.zero
	local i = row.icon
	-- the tool tipped towards the camera (its top to the front), then laid across the square
	model:PivotTo(CFrame.Angles(0, 0, i[4] * RAD) * CFrame.Angles(i[2] * RAD, i[3] * RAD, 0))
	centre = if body then body.Position else centre
	if row.find and #model:GetChildren() > 1 then
		-- a find of many parts (the RC car and its transmitter): framed whole, not by its root
		local box, size = model:GetBoundingBox()
		centre, length = box.Position, size.Magnitude
	end
	model.Parent = frame
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(0, 0, length * i[1] * 2.2), centre)
	cam.Parent = frame
	frame.CurrentCamera = cam
	return model
end

return ToolPicture
