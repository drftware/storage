--!strict
--[[
	A tool's or a find's 3D picture in a ViewportFrame, the way the slots show them: the thing
	tipped towards the camera by its catalog row's `icon` and filling the square. Shared by the
	slots (ToolView) and a kept find rising out of them (KeepView).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tools = require(ReplicatedStorage.Shared.Tools)

local Catalog = Tools.Catalog
local RAD = math.pi / 180

local ToolPicture = {}

-- Draws `key`'s tool in `frame` (empty for ""). Returns the model drawn, if any.
function ToolPicture.draw(frame: ViewportFrame, key: string): Model?
	frame:ClearAllChildren()
	local row = Catalog[key]
	if not row then
		return nil
	end
	local model = Tools.clone(key, CFrame.identity)
	if not model then
		return nil
	end
	local body = Tools.body(model)
	local length = if body then body.Size.Magnitude else 2
	local centre = if body then body.Position else Vector3.zero
	local i = row.icon
	-- the tool tipped towards the camera (its top to the front), then laid across the square
	model:PivotTo(CFrame.Angles(0, 0, i[4] * RAD) * CFrame.Angles(i[2] * RAD, i[3] * RAD, 0))
	centre = if body then body.Position else centre
	model.Parent = frame
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(0, 0, length * i[1] * 2.2), centre)
	cam.Parent = frame
	frame.CurrentCamera = cam
	return model
end

return ToolPicture
