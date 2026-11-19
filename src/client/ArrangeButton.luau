--!strict
--[[
	ArrangeButton (S5-03j7b, taken out of ArrangeView): the Arrange button, top right, where Done
	stands while arranging (the torch's switch is under it, S5-03e3a2). Four squares, one lifted and
	outlined (a find picked up), its word under. It pops in while you stand in your own home and
	shrinks away when you step out or Arrange opens.

	ArrangeView makes one with its gui, shows it as you stand in or out, and hears `pressed`.
]]
local TweenService = game:GetService("TweenService")

local POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

export type Options = {
	parent: Instance, -- the screen's gui
	colour: Color3, -- its fill
	rim: Color3, -- its edge and three squares
	ink: Color3, -- the lifted square and the word
	font: Font,
	press: (button: GuiObject) -> (), -- the screen's pop and click
	pressed: () -> (), -- opens Arrange
}

export type ArrangeButton = {
	-- Pops it in (true) or shrinks it away (false).
	show: (on: boolean) -> (),
}

local ArrangeButton = {}

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

function ArrangeButton.new(o: Options): ArrangeButton
	local shown = false
	local group = Instance.new("CanvasGroup")
	group.BackgroundTransparency = 1
	group.AnchorPoint = Vector2.new(1, 0)
	group.Position = UDim2.new(1, -14, 0, 4)
	group.Size = UDim2.fromOffset(74, 92)
	group.GroupTransparency = 1
	group.Visible = false
	group.Parent = o.parent
	local scale = Instance.new("UIScale")
	scale.Scale = 0.7
	scale.Parent = group
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = ""
	b.Size = UDim2.fromOffset(66, 66)
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.Position = UDim2.fromScale(0.5, 0)
	b.BackgroundColor3 = o.colour
	b.BackgroundTransparency = 0.1
	corner(b, UDim.new(0.5, 0))
	local stroke = Instance.new("UIStroke")
	stroke.Color = o.rim
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	Instance.new("UIScale").Parent = b
	for i, at in { { -9, 9 }, { 9, 9 }, { -9, -9 }, { 10, -11 } } do
		local sq = Instance.new("Frame")
		sq.AnchorPoint = Vector2.new(0.5, 0.5)
		sq.Position = UDim2.new(0.5, at[1], 0.5, at[2])
		sq.Size = UDim2.fromOffset(14, 14)
		sq.BackgroundColor3 = if i == 4 then o.ink else o.rim
		sq.BorderSizePixel = 0
		corner(sq, UDim.new(0, 3))
		if i == 4 then
			local outline = Instance.new("UIStroke")
			outline.Color = Color3.new(1, 1, 1)
			outline.Thickness = 2
			outline.Parent = sq
		end
		sq.Parent = b
	end
	b.Parent = group
	local word = Instance.new("TextLabel")
	word.BackgroundTransparency = 1
	word.AnchorPoint = Vector2.new(0.5, 1)
	word.Position = UDim2.fromScale(0.5, 1)
	word.Size = UDim2.new(1, 0, 0, 22)
	word.FontFace = o.font
	word.TextSize = 16
	word.TextColor3 = o.ink
	word.TextStrokeTransparency = 0.6
	word.Text = "Arrange"
	word.Parent = group
	b.Activated:Connect(function()
		if shown then
			o.press(b)
			o.pressed()
		end
	end)

	return {
		show = function(on: boolean)
			if on == shown then
				return
			end
			shown = on
			group.Visible = true
			TweenService:Create(group, QUICK, { GroupTransparency = if on then 0 else 1 }):Play()
			local t = TweenService:Create(
				scale,
				if on then POP else QUICK,
				{ Scale = if on then 1 else 0.7 }
			)
			t.Completed:Once(function()
				if not shown then
					group.Visible = false
				end
			end)
			t:Play()
		end,
	}
end

return ArrangeButton
