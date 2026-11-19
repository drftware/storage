--!strict
--[[
	ArrangeTurn (S5-03j2b2b): the turn's keys and the Free switch in Arrange, the room editor
	(D-436), beside the fingers' twist and the ring's Turn button. R turns the selected or carried
	thing a quarter, as The Sims 4's turn key does. Alt held, or the round Free switch in the
	corner, places off the grid at any angle, as The Sims' Alt does; phones have no Alt, so they
	get the switch.

	Free shows at a glance: while it's on (by the switch or by Alt) the switch glows honey with its
	icon dark on it, a square knocked askew over the grid's dots; off, it's the ring's dark round
	button with the icon dim. Off by default, kept between opens. No words.

	ArrangeView makes one with its gui and opens it with Arrange; the hand asks `free()` as it
	settles a carried thing and hears `changed` to settle again at once. It listens to the keyboard
	only while Arrange is open.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)

local Feel = Arrange.Feel
local POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- How far off square the icon's square leans (degrees): plainly askew, nowhere near a quarter.
local ASKEW = 24
-- The grid's dots behind it: three by three, this far apart (points).
local DOTS, DOT_GAP = 3, 11

export type Options = {
	parent: Instance, -- the screen's gui
	at: UDim2, -- where the switch's top right corner stands
	colour: Color3, -- its fill while Free is off (the ring's buttons')
	rim: Color3, -- its edge
	ink: Color3, -- the icon
	lit: Color3, -- its fill while Free is on
	-- The pop and click of a press (the screen's own).
	press: (button: GuiObject) -> (),
	-- R: the selected or carried thing's Turn.
	turn: () -> (),
	-- Free went on or off, by the switch or by Alt.
	changed: (free: boolean) -> (),
}

export type ArrangeTurn = {
	-- Whether Free is on now: the switch, or Alt held.
	free: () -> boolean,
	-- Shows the switch and listens to the keys while Arrange is open; hides it and stops when not.
	open: (on: boolean) -> (),
	-- The switch, for the ring to keep off.
	button: GuiObject,
	destroy: () -> (),
}

local ArrangeTurn = {}

local function altDown(): boolean
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
end

function ArrangeTurn.new(options: Options): ArrangeTurn
	local b = Instance.new("TextButton")
	b.Name = "Free"
	b.Text = ""
	b.AutoButtonColor = false
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = options.at
	b.Size = UDim2.fromOffset(Feel.RingSize, Feel.RingSize)
	b.BackgroundColor3 = options.colour
	b.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = b
	local rim = Instance.new("UIStroke")
	rim.Color = options.rim
	rim.Transparency = 0.25
	rim.Thickness = 2
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = b
	local scale = Instance.new("UIScale")
	scale.Parent = b

	-- The icon: the grid's dots, and over them a square turned askew.
	local dots: { Frame } = {}
	for i = 0, DOTS * DOTS - 1 do
		local d = Instance.new("Frame")
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		d.Position = UDim2.new(0.5, (i % DOTS - 1) * DOT_GAP, 0.5, (i // DOTS - 1) * DOT_GAP)
		d.Size = UDim2.fromOffset(3, 3)
		d.BackgroundColor3 = options.ink
		d.BorderSizePixel = 0
		d.ZIndex = 2
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = d
		d.Parent = b
		table.insert(dots, d)
	end
	local square = Instance.new("Frame")
	square.AnchorPoint = Vector2.new(0.5, 0.5)
	square.Position = UDim2.fromScale(0.5, 0.5)
	square.Size = UDim2.fromOffset(20, 20)
	square.Rotation = ASKEW
	square.BackgroundTransparency = 1
	square.ZIndex = 3
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 3)
	sc.Parent = square
	local edge = Instance.new("UIStroke")
	edge.Thickness = 3
	edge.Color = options.ink
	edge.Parent = square
	square.Parent = b
	b.Parent = options.parent

	local switched = false -- the switch's own state (Alt aside)
	local alt = false
	local lit = false
	local inputs: { RBXScriptConnection } = {}

	-- The switch drawn as Free is: honey with a dark icon, or dark with the icon dim.
	local function paint(pop: boolean)
		local ink = if lit then options.colour else options.ink
		TweenService
			:Create(b, QUICK, { BackgroundColor3 = if lit then options.lit else options.colour })
			:Play()
		TweenService:Create(rim, QUICK, {
			Color = if lit then Color3.new(1, 1, 1) else options.rim,
			Transparency = if lit then 0 else 0.25,
		}):Play()
		TweenService:Create(edge, QUICK, { Color = ink, Transparency = if lit then 0 else 0.3 })
			:Play()
		for _, d in dots do
			TweenService:Create(
				d,
				QUICK,
				{ BackgroundColor3 = ink, BackgroundTransparency = if lit then 0.2 else 0.55 }
			):Play()
		end
		if pop then
			scale.Scale = if lit then 1.18 else 0.88
			TweenService:Create(scale, POP, { Scale = 1 }):Play()
		end
	end

	local function refresh(pop: boolean)
		local now = switched or alt
		if now == lit then
			return
		end
		lit = now
		paint(pop)
		options.changed(now)
	end

	b.Activated:Connect(function()
		options.press(b)
		switched = not switched
		refresh(true)
	end)

	local function stopListening()
		for _, c in inputs do
			c:Disconnect()
		end
		table.clear(inputs)
	end

	local function open(on: boolean)
		stopListening()
		if not on then
			b.Visible = false
			alt = false
			refresh(false)
			return
		end
		b.Visible = true
		scale.Scale = 0.5 -- pops in with Arrange
		TweenService:Create(scale, POP, { Scale = 1 }):Play()
		alt = altDown()
		refresh(false)
		table.insert(
			inputs,
			UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
				local k = input.KeyCode
				if k == Enum.KeyCode.LeftAlt or k == Enum.KeyCode.RightAlt then
					alt = true
					refresh(true)
				elseif
					k == Enum.KeyCode.R
					and not processed
					and not UserInputService:GetFocusedTextBox()
				then
					options.turn()
				end
			end)
		)
		table.insert(
			inputs,
			UserInputService.InputEnded:Connect(function(input: InputObject)
				local k = input.KeyCode
				if k == Enum.KeyCode.LeftAlt or k == Enum.KeyCode.RightAlt then
					alt = altDown()
					refresh(true)
				end
			end)
		)
		-- (Alt let go in another window never ends here)
		table.insert(
			inputs,
			UserInputService.WindowFocusReleased:Connect(function()
				alt = false
				refresh(false)
			end)
		)
	end

	return {
		free = function(): boolean
			return lit
		end,
		open = open,
		button = b,
		destroy = function()
			stopListening()
			b:Destroy()
		end,
	}
end

return ArrangeTurn
