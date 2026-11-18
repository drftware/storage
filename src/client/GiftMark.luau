--!strict
--[[
	GiftMark: the little wrapped box that means a gift (S5-03h3b2, D-344): on the Units tab's Gift
	pill, on a friend's card for a gift you already hold, and on the face of whoever grew your
	home. Drawn from plain frames (a box, its lid, a ribbon, a bow), so it sits in the home's own
	colours at any size rather than as an emoji in the phone's.
]]
local GiftMark = {}

export type Mark = {
	root: Frame, -- square, filling its parent's height
	paint: (box: Color3, ribbon: Color3) -> (),
}

local function part(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	w: number,
	h: number
): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function round(f: Frame, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(radius, 0)
	c.Parent = f
end

-- A gift mark inside `parent`, centred, as tall as it; `z` its ZIndex.
function GiftMark.new(parent: GuiObject, z: number): Mark
	local root = Instance.new("Frame")
	root.Name = "GiftMark"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.ZIndex = z
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.DominantAxis = Enum.DominantAxis.Height
	square.Parent = root

	local body = part(root, "Body", 0.5, 0.7, 0.76, 0.52)
	round(body, 0.12)
	local lid = part(root, "Lid", 0.5, 0.37, 0.92, 0.2)
	round(lid, 0.2)
	local band = part(root, "Band", 0.5, 0.63, 0.17, 0.72)
	local left = part(root, "BowLeft", 0.33, 0.17, 0.3, 0.2)
	left.Rotation = 28
	round(left, 0.5)
	local right = part(root, "BowRight", 0.67, 0.17, 0.3, 0.2)
	right.Rotation = -28
	round(right, 0.5)
	for _, each in { body, lid, band, left, right } do
		each.ZIndex = z
	end
	band.ZIndex = z + 1
	root.Parent = parent

	local mark = {} :: Mark
	mark.root = root
	function mark.paint(box: Color3, ribbon: Color3)
		body.BackgroundColor3, lid.BackgroundColor3 = box, box
		band.BackgroundColor3, left.BackgroundColor3, right.BackgroundColor3 =
			ribbon, ribbon, ribbon
	end
	return mark
end

return GiftMark
