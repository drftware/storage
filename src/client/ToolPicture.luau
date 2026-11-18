--!strict
--[[
	A tool's or a find's 3D picture in a ViewportFrame, the way the slots show them: the thing
	tipped towards the camera by its catalog row's `icon` and filling the square. Shared by the
	slots (ToolView) and a kept find rising out of them (KeepView).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local Pack = require(ReplicatedStorage.Shared.Finds.Pack)
local Seal = require(ReplicatedStorage.Shared.Finds.Seal)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Catalog = Tools.Catalog
local RAD = math.pi / 180

local ToolPicture = {}

-- Draws `key`'s tool in `frame` (empty for ""), a Gold's ("Teddy:Gold") as its find gilded, a
-- sealed one's ("Teddy:Sealed", D-427) as its find in its pack, framed whole. Returns the model
-- drawn, if any.
function ToolPicture.draw(frame: ViewportFrame, key: string): Model?
	frame:ClearAllChildren()
	local base = Gold.base(key)
	local sealed = Seal.base(key)
	local find = base or sealed or key
	local row = Catalog[find]
	if not row then
		return nil
	end
	local model = Tools.clone(find, CFrame.identity)
	if not model then
		return nil
	end
	if base then
		Gold.gild(model)
	end
	local body = Tools.body(model)
	if sealed and body then
		Pack.wrap(model, body, row.size, Tools.bounds(find))
	end
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
