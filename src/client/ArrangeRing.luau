--!strict
--[[
	ArrangeRing (S5-03j2b1, D-450): the round buttons round a thing selected in Arrange, the room
	editor (D-436). A tap lifts a find a hair and these sit round it, as The Sims 4 rings a selected
	object: Put away (into the box), Turn (a quarter turn) and Another (one more of the same from
	your box, The Sims' eyedropper). Icons, no words; each 52 points, over the phone's 48-point
	target. A tap on the empty room lets the thing go and the ring with it.

	A thing that hangs on a wall also gets the height handle (S5-03j3c2, D-459): a round button
	with an up-down arrow just over it (`Ring.handle`), the row then going over both. Dragged, it
	lifts or lowers the thing along the wall, as The Sims 4's wall-height handle does: its drag is
	its own (the button sinks the press, so the build camera never pans meanwhile), measured from
	where the finger went down, and the handle rides up with the thing under the finger.

	The row hugs the thing on the screen (`Ring.place`, pure) and moves with it and the camera:
	it steps only while shown, and lays out again only when the camera or the thing has moved.
	ArrangeView makes one with its gui and shows it for the hand's selected thing.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Ring = require(ReplicatedStorage.Shared.Home.Ring)

local Feel = Arrange.Feel
local POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Which buttons the selected thing has.
export type Which = { away: boolean, turn: boolean, another: boolean, raise: boolean }

-- The height handle's drag, as the hand takes it: `start` as the finger goes down (false: no
-- drag, the thing isn't on a wall), `move` with how far it has gone since (screen points), `stop`
-- as it lifts.
export type Raise = {
	start: () -> boolean,
	move: (dx: number, dy: number) -> (),
	stop: () -> (),
}

export type Options = {
	parent: Instance, -- the screen's gui
	colour: Color3, -- the buttons' fill
	rim: Color3, -- their edge
	ink: Color3, -- the icons
	-- The pop and click of a press (the screen's own).
	press: (button: GuiObject) -> (),
	away: () -> (),
	turn: () -> (),
	another: () -> (),
	raise: Raise,
	-- The part of the screen the ring may use, in gui points.
	area: () -> Ring.Box,
	-- The screen's own buttons the ring keeps off (Done, the limit bar), in gui points.
	avoid: (() -> { Ring.Box })?,
}

export type ArrangeRing = {
	-- Rings `thing` with the buttons `which` names; nil puts them away.
	show: (thing: Model?, which: Which?) -> (),
	destroy: () -> (),
}

local ArrangeRing = {}

-- One stroke of an icon: a rounded bar `w` by `h` at `x`, `y` from the button's middle.
local function bar(
	parent: Instance,
	ink: Color3,
	w: number,
	h: number,
	x: number,
	y: number,
	turn: number?
)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.new(0.5, x, 0.5, y)
	f.Size = UDim2.fromOffset(w, h)
	f.Rotation = turn or 0
	f.BackgroundColor3 = ink
	f.BorderSizePixel = 0
	f.ZIndex = 3
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = f
	f.Parent = parent
	return f
end

-- Turn: a ring with a gap at its top left and an arrowhead going round anticlockwise, the way a
-- quarter turn goes as the camera sees it from above (S5-03j2b1b).
local function turnIcon(b: GuiObject, ink: Color3, colour: Color3)
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.new(0.5, 0, 0.5, 1)
	ring.Size = UDim2.fromOffset(22, 22)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 2
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = ink
	stroke.Parent = ring
	ring.Parent = b
	local gap = Instance.new("Frame") -- the gap the arrow points across
	gap.AnchorPoint = Vector2.new(0.5, 0.5)
	gap.Position = UDim2.new(0.5, -9, 0.5, -7)
	gap.Size = UDim2.fromOffset(10, 10)
	gap.BackgroundColor3 = colour
	gap.BorderSizePixel = 0
	gap.ZIndex = 2
	gap.Parent = b
	bar(b, ink, 8, 3, -3.5, -12.5, -35)
	bar(b, ink, 8, 3, -3.5, -7.5, 35)
end

-- Put away: an arrow down into an open box, its flaps folded out (without them it read as a
-- download tray at phone size, S5-03j2b1b).
local function awayIcon(b: GuiObject, ink: Color3)
	bar(b, ink, 22, 3, 0, 10)
	bar(b, ink, 3, 10, -9.5, 6)
	bar(b, ink, 3, 10, 9.5, 6)
	bar(b, ink, 3, 8, -12.1, -2.1, -40)
	bar(b, ink, 3, 8, 12.1, -2.1, 40)
	bar(b, ink, 3, 13, 0, -6)
	bar(b, ink, 9, 3, -2.8, -1, 40)
	bar(b, ink, 9, 3, 2.8, -1, -40)
end

-- The height handle: an arrow pointing up and down.
local function raiseIcon(b: GuiObject, ink: Color3)
	bar(b, ink, 3, 22, 0, 0)
	bar(b, ink, 9, 3, -2.8, -7.5, -40)
	bar(b, ink, 9, 3, 2.8, -7.5, 40)
	bar(b, ink, 9, 3, -2.8, 7.5, 40)
	bar(b, ink, 9, 3, 2.8, 7.5, -40)
end

-- Another: a plus.
local function anotherIcon(b: GuiObject, ink: Color3)
	bar(b, ink, 22, 4, 0, 0)
	bar(b, ink, 4, 22, 0, 0)
end

function ArrangeRing.new(options: Options): ArrangeRing
	local holder = Instance.new("Frame")
	holder.Name = "Ring"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.Active = false
	holder.Parent = options.parent

	local function button(name: string, act: (() -> ())?): TextButton
		local b = Instance.new("TextButton")
		b.Name = name
		b.Text = ""
		b.AutoButtonColor = false
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Size = UDim2.fromOffset(Feel.RingSize, Feel.RingSize)
		b.BackgroundColor3 = options.colour
		b.Visible = false
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = b
		local stroke = Instance.new("UIStroke")
		stroke.Color = options.rim
		stroke.Transparency = 0.25
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = b
		Instance.new("UIScale").Parent = b
		if act then
			b.Activated:Connect(function()
				options.press(b)
				act()
			end)
		end
		b.Parent = holder
		return b
	end
	-- left to right: Turn in the middle, nearest the thing, the one most pressed
	local away = button("Away", options.away)
	awayIcon(away, options.ink)
	local turn = button("Turn", options.turn)
	turnIcon(turn, options.ink, options.colour)
	local another = button("Another", options.another)
	anotherIcon(another, options.ink)
	local handle = button("Raise", nil)
	raiseIcon(handle, options.ink)

	-- The handle's drag: the press that began it, where it went down, and the two connections
	-- that follow it (made as it goes down, gone as it lifts).
	local raising: InputObject? = nil
	local raisedFrom = Vector2.zero
	local raiseWatch: { RBXScriptConnection } = {}
	local function endRaise()
		for _, c in raiseWatch do
			c:Disconnect()
		end
		table.clear(raiseWatch)
		if raising then
			raising = nil
			local scale = handle:FindFirstChildOfClass("UIScale")
			if scale then
				TweenService:Create(scale, POP, { Scale = 1 }):Play()
			end
			options.raise.stop()
		end
	end
	local function same(input: InputObject, down: InputObject): boolean
		return input == down
			or (
				input.UserInputType == Enum.UserInputType.MouseMovement
				and down.UserInputType == Enum.UserInputType.MouseButton1
			)
	end
	handle.InputBegan:Connect(function(input: InputObject)
		local t = input.UserInputType
		if
			raising
			or not (t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1)
			or not options.raise.start()
		then
			return
		end
		raising = input
		raisedFrom = Vector2.new(input.Position.X, input.Position.Y)
		options.press(handle)
		local scale = handle:FindFirstChildOfClass("UIScale")
		if scale then -- held: a little bigger, under the finger
			TweenService:Create(scale, POP, { Scale = 1.12 }):Play()
		end
		table.insert(
			raiseWatch,
			UserInputService.InputChanged:Connect(function(moved: InputObject)
				local down = raising
				if down and same(moved, down) then
					options.raise.move(
						moved.Position.X - raisedFrom.X,
						moved.Position.Y - raisedFrom.Y
					)
				end
			end)
		)
		table.insert(
			raiseWatch,
			UserInputService.InputEnded:Connect(function(up: InputObject)
				local down = raising
				if down and up == down then
					endRaise()
				end
			end)
		)
	end)
	local raiseShown = false

	local shown: { TextButton } = {}
	local thing: Model? = nil
	local step: RBXScriptConnection? = nil
	local seenFrom, seenAt = CFrame.identity, CFrame.identity
	local ringOptions: Ring.Options =
		{ size = Feel.RingSize, gap = Feel.RingGap, sag = Feel.RingSag, margin = Feel.RingMargin }

	-- Lays the shown buttons round the thing's box on the screen; hides them while any of it is
	-- behind the camera.
	local function layout()
		local t, camera = thing, Workspace.CurrentCamera
		if not (t and camera and t.Parent) then
			return
		end
		local cf, size = t:GetBoundingBox()
		local h = size / 2
		local left, top, right, bottom = math.huge, math.huge, -math.huge, -math.huge
		for i = 0, 7 do
			local corner = cf
				* Vector3.new(
					if i % 2 == 0 then -h.X else h.X,
					if i // 2 % 2 == 0 then -h.Y else h.Y,
					if i // 4 == 0 then -h.Z else h.Z
				)
			-- (the second value WorldToScreenPoint gives means on the screen, not ahead: a tall
			-- thing's top off the screen's edge still gets its ring, S5-03j2b1b)
			local p = camera:WorldToScreenPoint(corner)
			if p.Z <= 0 then
				holder.Visible = false
				return
			end
			left, top = math.min(left, p.X), math.min(top, p.Y)
			right, bottom = math.max(right, p.X), math.max(bottom, p.Y)
		end
		holder.Visible = true
		ringOptions.avoid = if options.avoid then options.avoid() else nil
		local area = options.area()
		local box = { left = left, top = top, right = right, bottom = bottom }
		local hp = if raiseShown then Ring.handle(box, area, ringOptions) else nil
		if hp then
			handle.Position = UDim2.fromOffset(hp.x, hp.y)
			local r = Feel.RingSize / 2 -- the row goes round the thing and the handle together
			box.left, box.right = math.min(left, hp.x - r), math.max(right, hp.x + r)
			box.top, box.bottom = math.min(top, hp.y - r), math.max(bottom, hp.y + r)
		end
		local at = Ring.place(box, #shown, area, ringOptions)
		for i, b in shown do
			local p = at[i]
			if p then
				b.Position = UDim2.fromOffset(p.x, p.y)
			end
		end
	end

	local function stop()
		if step then
			step:Disconnect()
			step = nil
		end
	end

	local function show(t: Model?, which: Which?)
		local was = table.clone(shown)
		table.clear(shown)
		thing = t
		if t and which then
			if which.away then
				table.insert(shown, away)
			end
			if which.turn then
				table.insert(shown, turn)
			end
			if which.another then
				table.insert(shown, another)
			end
		end
		local wasRaise = raiseShown
		raiseShown = t ~= nil and which ~= nil and which.raise
		if not raiseShown then
			endRaise()
		end
		for _, b in { away, turn, another, handle } do
			local on = if b == handle then raiseShown else table.find(shown, b) ~= nil
			local before = if b == handle then wasRaise else table.find(was, b) ~= nil
			if on and not before then -- pops in round the thing
				local scale = b:FindFirstChildOfClass("UIScale")
				if scale then
					scale.Scale = 0.5
					TweenService:Create(scale, POP, { Scale = 1 }):Play()
				end
			end
			b.Visible = on
		end
		if #shown == 0 and not raiseShown then
			stop()
			return
		end
		layout()
		local camera = Workspace.CurrentCamera
		seenFrom = if camera then camera.CFrame else CFrame.identity
		seenAt = if t then t:GetPivot() else CFrame.identity
		if not step then
			step = RunService.RenderStepped:Connect(function()
				local now, cam = thing, Workspace.CurrentCamera
				if not (now and cam) then
					return
				end
				local from, at = cam.CFrame, now:GetPivot()
				if from ~= seenFrom or at ~= seenAt then
					seenFrom, seenAt = from, at
					layout()
				end
			end)
		end
	end

	return {
		show = show,
		destroy = function()
			endRaise()
			stop()
			holder:Destroy()
		end,
	}
end

return ArrangeRing
