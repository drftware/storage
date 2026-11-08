--!strict
--[[
	LedReadout: the keypad's four seven-segment LED digits, drawn into any GuiObject: the wall's
	readout (ElevatorView) and the screen keypad's (KeypadPad). What each cell shows comes from
	the shared Readout rules, so the two always agree. A redraw touches only the cells that
	changed, so a screen can call it every frame while the digits blink.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Readout = require(ReplicatedStorage.Shared.Elevator.Readout)

-- The colours a readout lights in, and how faint its unlit segments show.
export type Look = {
	unlit: Color3,
	unlitTransparency: number,
	rest: Color3,
	lit: Color3,
	right: Color3,
}

-- Draws the keypad in `state`, `since` seconds after its last event.
export type Draw = (state: Keypad.State, since: number) -> ()

-- A digit's shape: as wide as this share of its height, its bars this share of its height thick,
-- with this gap where two bars meet, as a real seven-segment LED's.
local ASPECT = 0.56
local BAR = 0.1
local GAP = 0.012

local LedReadout = {}

-- Where each segment sits in its cell, a to g, in scale: { x, y, width, height }, by its middle.
local function layout(): { { number } }
	local barW, gapW = BAR / ASPECT, GAP / ASPECT
	local across = 1 - barW - 2 * gapW
	local upright = 0.5 - BAR / 2 - 2 * GAP
	local upper, lower = (BAR / 2 + 0.5) / 2, (1.5 - BAR / 2) / 2
	local left, right = barW / 2, 1 - barW / 2
	return {
		{ 0.5, BAR / 2, across, BAR }, -- a
		{ right, upper, barW, upright }, -- b
		{ right, lower, barW, upright }, -- c
		{ 0.5, 1 - BAR / 2, across, BAR }, -- d
		{ left, lower, barW, upright }, -- e
		{ left, upper, barW, upright }, -- f
		{ 0.5, 0.5, across, BAR }, -- g
	}
end
local SEGMENTS = layout()

--[[
	Fills `parent` with the four digits, centred, each `height` (a share of the parent's height)
	tall with `spacing` (a share of its width) between them. Returns the function that draws them.
]]
function LedReadout.new(parent: Instance, look: Look, height: number, spacing: number): Draw
	local row = Instance.new("Frame")
	row.Name = "Digits"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(spacing, 0)
	list.Parent = row

	local cells: { { Frame } } = table.create(Keypad.Length)
	for i = 1, Keypad.Length do
		local cell = Instance.new("Frame")
		cell.Name = `Cell{i}`
		cell.LayoutOrder = i
		cell.BackgroundTransparency = 1
		cell.Size = UDim2.fromScale(height * ASPECT, height)
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = ASPECT
		aspect.DominantAxis = Enum.DominantAxis.Height
		aspect.Parent = cell
		local segs: { Frame } = table.create(#SEGMENTS)
		for s, at in SEGMENTS do
			local seg = Instance.new("Frame")
			seg.Name = string.char(96 + s)
			seg.AnchorPoint = Vector2.new(0.5, 0.5)
			seg.Position = UDim2.fromScale(at[1], at[2])
			seg.Size = UDim2.fromScale(at[3], at[4])
			seg.BorderSizePixel = 0
			seg.BackgroundColor3 = look.unlit
			seg.BackgroundTransparency = look.unlitTransparency
			local round = Instance.new("UICorner")
			round.CornerRadius = UDim.new(0.5, 0)
			round.Parent = seg
			seg.Parent = cell
			segs[s] = seg
		end
		cell.Parent = row
		cells[i] = segs
	end
	row.Parent = parent

	local tones: { [Readout.Tone]: Color3 } =
		{ Off = look.unlit, Rest = look.rest, Lit = look.lit, Right = look.right }
	local chars: { string } = table.create(Keypad.Length, "")
	local shown: { Readout.Tone } = table.create(Keypad.Length, "Off" :: Readout.Tone)

	return function(state: Keypad.State, since: number)
		for i, segs in cells do
			local char: string, tone: Readout.Tone = Readout.cell(state, i, since)
			if chars[i] == char and shown[i] == tone then
				continue
			end
			chars[i], shown[i] = char, tone
			local pattern = Readout.pattern(char)
			local colour = tones[tone]
			for s, seg in segs do
				local on = pattern[s] and tone ~= "Off"
				seg.BackgroundColor3 = if on then colour else look.unlit
				seg.BackgroundTransparency = if on then 0 else look.unlitTransparency
			end
		end
	end
end

return LedReadout
