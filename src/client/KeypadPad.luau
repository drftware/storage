--!strict
--[[
	KeypadPad: the freight elevator's keypad on your screen, the one way every device types a code
	(L-05b1c; owner, Nov 8). Walk up to the keypad and its prompt ("Use") opens it, as DOORS'
	padlock at door 50 opens its own pad: right of centre, clear of the jump button, keys laid out
	as the wall's (1 to 9 over the light, 0 and CLR) under a readout that mirrors the wall's.

	- A press answers at once: the key dips, the wall's key sinks with a beep (ElevatorView's
	  `press`), and the key goes to the server, which checks it (Elevators) and lights both
	  readouts. Presses come no faster than the server takes them (`Keypad.PressSeconds`).
	- While the alarm rings the keys go dead and dim. The right code turns the readout green, then
	  the pad slides away as the gate folds open.
	- You can still walk: walking off closes it, as do dying, E, or B on a gamepad. A keyboard's
	  digits and Backspace type on it; a gamepad's D-pad moves between keys and A presses.
	- On a computer the mouse goes free while it's open (FreeCursor's `need`), so you can click.
]]
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local ElevatorView = require(script.Parent.ElevatorView)
local FreeCursor = require(script.Parent.FreeCursor)
local LedReadout = require(script.Parent.LedReadout)

local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Readout = require(ReplicatedStorage.Shared.Elevator.Readout)

-- The prompt hangs this far in front of the keypad's face (studs), clear of the keys, and needs
-- a clear line from you, so it never shows through the wall from inside the car.
local PROMPT_OUT = 0.45
-- Walking this far from the keypad closes the pad: a stud inside the server's reach, so a press
-- made at the edge still counts.
local CLOSE_REACH = Keypad.Reach - 1
-- Seconds the green code shows on the pad before it slides away.
local CLOSE_AFTER_RIGHT = 0.9

-- The pad's design size, in pixels before it's scaled to the screen: the readout over four rows
-- of three keys. On the Galaxy A16 it scales to about 0.89, so a key is 44 points wide, a thumb's
-- width (at 0.72 they were 36 and too small to hit cleanly).
local EDGE = 12
local KEY_W, KEY_H, GAP = 50, 46, 9
local READOUT_H, UNDER_READOUT = 44, 10
local WIDTH = EDGE * 2 + KEY_W * 3 + GAP * 2
local HEIGHT = EDGE * 2 + READOUT_H + UNDER_READOUT + KEY_H * 4 + GAP * 3
-- It fills this share of the screen's height (below the top bar), scaled no smaller or larger
-- than these.
local FILL = 0.92
local MIN_SCALE, MAX_SCALE = 0.55, 1.25
-- Its left edge this far across the screen, so the wall's keypad in the middle stays in view
-- (you see its keys sink), and its middle this far down.
local ACROSS = 0.58
local DOWN = 0.5
-- Pixels kept clear on its right for the jump button.
local JUMP_ROOM = 110
-- Arriving it slides this many pixels in from the right as it fades up; leaving, back out.
local SLIDE = 24
local SLIDE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- A pressed key dips to this size and darkens at once, then springs back over KEY_BACK; a dead
-- key (during the alarm) barely moves, and makes no sound.
local KEY_DIP, DEAD_DIP = 0.88, 0.97
local KEY_BACK = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- How far the keys fade while they're dead, and how quickly.
local DEAD_TEXT, DEAD_BACKING = 0.6, 0.35
local DEAD_FADE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local STEEL = Color3.fromRGB(28, 28, 31)
local RIM = Color3.fromRGB(78, 78, 84)
local KEY = Color3.fromRGB(60, 60, 65)
local KEY_DOWN = Color3.fromRGB(36, 36, 40)
local KEY_RIM = Color3.fromRGB(100, 100, 106)
local INK = Color3.fromRGB(232, 226, 214) -- warm off-white, as FreeCursor's hint
local GLASS = Color3.fromRGB(22, 5, 5)
-- The screen's dashes a little brighter than the wall's: nothing on a screen glows, and the wall's
-- dim red all but vanished on a phone.
local SCREEN_REST = Color3.fromRGB(196, 36, 24)
local SCREEN_LOOK: LedReadout.Look = {
	unlit = Elevator.ReadoutUnlit,
	unlitTransparency = 0.7,
	rest = SCREEN_REST,
	lit = Elevator.ReadoutLit,
	right = Elevator.ReadoutRight,
}

-- The keys, row by row as on the wall; "Light" is the status light's place.
type Slot = Keypad.Key | "Light"
local ROWS: { { Slot } } = { { 1, 2, 3 }, { 4, 5, 6 }, { 7, 8, 9 }, { "Light", 0, "Clear" } }

-- A keyboard's keys that type on the pad.
local TYPED: { [Enum.KeyCode]: Keypad.Key } = {
	[Enum.KeyCode.Zero] = 0,
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
	[Enum.KeyCode.KeypadZero] = 0,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.KeypadFive] = 5,
	[Enum.KeyCode.KeypadSix] = 6,
	[Enum.KeyCode.KeypadSeven] = 7,
	[Enum.KeyCode.KeypadEight] = 8,
	[Enum.KeyCode.KeypadNine] = 9,
	[Enum.KeyCode.Backspace] = "Clear",
}
local TYPE_ACTION, CLOSE_ACTION = "KeypadPadType", "KeypadPadClose"
-- Over the game's other bindings, so a digit types here instead of picking a tool.
local PRIORITY = Enum.ContextActionPriority.High.Value

type Entry = {
	model: Model,
	prompt: ProximityPrompt,
	at: Attachment,
	state: Keypad.State,
	since: number, -- os.clock() when its state last changed
	conns: { RBXScriptConnection },
}

type Button = {
	button: TextButton,
	scale: UIScale,
	tweens: { Tween },
}

local KeypadPad = {}

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function rim(parent: Instance, colour: Color3, thickness: number, transparency: number)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = colour
	s.Thickness = thickness
	s.Transparency = transparency
	s.Parent = parent
end

-- `press` beeps and sinks the wall's key (ElevatorView); `need` frees the mouse (FreeCursor).
function KeypadPad.new(press: ElevatorView.Press, need: FreeCursor.Need): Brix.System
	local entries: { [Model]: Entry } = {}
	local connections: { RBXScriptConnection } = {}
	local openOn: Entry? = nil
	local closing: thread? = nil -- the slide away after the right code
	local lastPress = -math.huge
	local remote: RemoteEvent? = nil

	local gui: ScreenGui? = nil
	local panel: CanvasGroup? = nil
	local scale: UIScale? = nil
	local lamp: Frame? = nil
	local lampTone: Readout.Tone? = nil
	local drawReadout: LedReadout.Draw? = nil
	local buttons: { [Keypad.Key]: Button } = {}
	local shownDead: boolean? = nil
	local slide: Tween? = nil

	local function keypadRemote(): RemoteEvent?
		if remote and remote.Parent then
			return remote
		end
		local folder = ReplicatedStorage:FindFirstChild(Keypad.RemoteFolder)
		local r = folder and folder:FindFirstChild(Keypad.RemoteName)
		remote = if r and r:IsA("RemoteEvent") then r else nil
		return remote
	end

	-- The pad's size for this screen: FILL of its height, never wider than the room on its right,
	-- so it stays clear of the jump button.
	local function fit()
		local g, s = gui, scale
		if not (g and s) then
			return
		end
		local size = g.AbsoluteSize
		local tall = size.Y * FILL / HEIGHT
		local wide = (size.X * (1 - ACROSS) - JUMP_ROOM) / WIDTH
		s.Scale = math.clamp(math.min(tall, wide), MIN_SCALE, MAX_SCALE)
	end

	local function showLamp(tone: Readout.Tone)
		local l = lamp
		if not l or lampTone == tone then
			return
		end
		lampTone = tone
		local colour = if tone == "Right"
			then Elevator.KeypadRight
			elseif tone == "Off" then Elevator.KeypadDark
			else Elevator.KeypadLight
		l.BackgroundColor3 = colour
		local glow = l:FindFirstChildWhichIsA("UIStroke")
		if glow then
			glow.Color = colour
			glow.Transparency = if tone == "Off" then 1 else 0.55
		end
	end

	-- The keys dead (dim) while the keypad takes no presses, alive otherwise.
	local function showDead(dead: boolean)
		if shownDead == dead then
			return
		end
		shownDead = dead
		for _, b in buttons do
			TweenService:Create(b.button, DEAD_FADE, {
				TextTransparency = if dead then DEAD_TEXT else 0,
				BackgroundTransparency = if dead then DEAD_BACKING else 0,
			}):Play()
		end
	end

	local function redraw()
		local entry = openOn
		if not entry then
			return
		end
		local since = os.clock() - entry.since
		local d = drawReadout
		if d then
			d(entry.state, since)
		end
		showLamp(Readout.light(entry.state, since))
	end

	-- A key dips and darkens at once, then springs back.
	local function dip(b: Button, depth: number)
		for _, t in b.tweens do
			t:Cancel()
		end
		table.clear(b.tweens)
		b.scale.Scale = depth
		b.button.BackgroundColor3 = KEY_DOWN
		local s = TweenService:Create(b.scale, KEY_BACK, { Scale = 1 })
		local c = TweenService:Create(b.button, KEY_BACK, { BackgroundColor3 = KEY })
		table.insert(b.tweens, s)
		table.insert(b.tweens, c)
		s:Play()
		c:Play()
	end

	local function pressKey(key: Keypad.Key)
		local entry = openOn
		local b = buttons[key]
		if not (entry and b) then
			return
		end
		if not Readout.live(entry.state) then
			dip(b, DEAD_DIP)
			return
		end
		local t = os.clock()
		if t - lastPress < Keypad.PressSeconds then
			return
		end
		lastPress = t
		dip(b, KEY_DIP)
		press(entry.model, key)
		local r = keypadRemote()
		if r then
			r:FireServer(entry.model, key)
		end
	end

	local close: () -> ()

	local function typed(_: string, input: Enum.UserInputState, object: InputObject)
		if input == Enum.UserInputState.Begin then
			local key: Keypad.Key? = TYPED[object.KeyCode]
			if key ~= nil then
				pressKey(key)
			end
		end
		return Enum.ContextActionResult.Sink
	end

	local function closeKey(_: string, input: Enum.UserInputState, _object: InputObject)
		if input == Enum.UserInputState.Begin then
			close()
		end
		return Enum.ContextActionResult.Sink
	end

	-- The prompt shows while the keypad takes a code and the pad isn't open on it.
	local function showPrompt(entry: Entry)
		entry.prompt.Enabled = openOn ~= entry and entry.state.event ~= "Right"
	end

	local function slideTo(shown: boolean)
		local p = panel
		if not p then
			return
		end
		if slide then
			slide:Cancel()
		end
		local tween = TweenService:Create(p, if shown then SLIDE_IN else SLIDE_OUT, {
			GroupTransparency = if shown then 0 else 1,
			Position = UDim2.new(ACROSS, if shown then 0 else SLIDE, DOWN, 0),
		})
		slide = tween
		if shown then
			p.Visible = true
		else
			tween.Completed:Once(function(status: Enum.PlaybackState)
				if status == Enum.PlaybackState.Completed and not openOn then
					p.Visible = false
				end
			end)
		end
		tween:Play()
	end

	close = function()
		local entry = openOn
		if not entry then
			return
		end
		openOn = nil
		if closing then
			task.cancel(closing)
			closing = nil
		end
		ContextActionService:UnbindAction(TYPE_ACTION)
		ContextActionService:UnbindAction(CLOSE_ACTION)
		need("KeypadPad", false)
		local selected = GuiService.SelectedObject
		if selected and panel and selected:IsDescendantOf(panel) then
			GuiService.SelectedObject = nil
		end
		slideTo(false)
		showPrompt(entry)
	end

	local function open(entry: Entry)
		if openOn or not panel then
			return
		end
		openOn = entry
		showPrompt(entry)
		fit()
		redraw()
		showDead(not Readout.live(entry.state))
		need("KeypadPad", true)
		local keys: { Enum.KeyCode } = {}
		for code in TYPED do
			table.insert(keys, code)
		end
		ContextActionService:BindActionAtPriority(
			TYPE_ACTION,
			typed,
			false,
			PRIORITY,
			table.unpack(keys)
		)
		ContextActionService:BindActionAtPriority(
			CLOSE_ACTION,
			closeKey,
			false,
			PRIORITY,
			Enum.KeyCode.E,
			Enum.KeyCode.ButtonB
		)
		local five = buttons[5]
		if five and UserInputService:GetLastInputType().Name:find("Gamepad") then
			GuiService.SelectedObject = five.button
		end
		slideTo(true)
	end

	-- The server wrote this keypad's state: the prompt, and the pad if it's open on it.
	local function changed(entry: Entry)
		local state = Keypad.decode(entry.model:GetAttribute(Keypad.Attribute))
		if state.count == entry.state.count then
			return
		end
		entry.state, entry.since = state, os.clock()
		showPrompt(entry)
		if openOn ~= entry then
			return
		end
		redraw()
		showDead(not Readout.live(state))
		if state.event == "Right" and not closing then
			closing = task.delay(CLOSE_AFTER_RIGHT, function()
				closing = nil
				if openOn == entry then
					close()
				end
			end)
		end
	end

	local function remove(inst: Instance)
		local entry = entries[inst :: Model]
		if not entry then
			return
		end
		if openOn == entry then
			close()
		end
		entries[inst :: Model] = nil
		for _, c in entry.conns do
			c:Disconnect()
		end
		entry.at:Destroy()
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or entries[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local keypad = inst:FindFirstChild("Keypad")
		if not (keypad and keypad:IsA("BasePart")) then
			return
		end
		local at = Instance.new("Attachment")
		at.Name = "KeypadPrompt"
		at.Parent = keypad
		at.WorldCFrame =
			CFrame.new(Elevator.keypadPoint(inst) + inst:GetPivot().LookVector * PROMPT_OUT)
		local p = Instance.new("ProximityPrompt")
		p.Style = Enum.ProximityPromptStyle.Custom -- drawn by ButtonView
		p.ObjectText = ""
		p.ActionText = "Use"
		p.KeyboardKeyCode = Enum.KeyCode.E
		p.GamepadKeyCode = Enum.KeyCode.ButtonX
		p.HoldDuration = 0
		p.MaxActivationDistance = Keypad.PromptReach
		p.RequiresLineOfSight = true
		p.Parent = at
		local entry: Entry = {
			model = inst,
			prompt = p,
			at = at,
			state = Keypad.decode(nil),
			since = os.clock(),
			conns = {},
		}
		entries[inst] = entry
		table.insert(
			entry.conns,
			p.Triggered:Connect(function()
				open(entry)
			end)
		)
		table.insert(
			entry.conns,
			inst:GetAttributeChangedSignal(Keypad.Attribute):Connect(function()
				changed(entry)
			end)
		)
		changed(entry)
		showPrompt(entry)
	end

	local function build(): ScreenGui
		local screen = Instance.new("ScreenGui")
		screen.Name = "KeypadPad"
		screen.ResetOnSpawn = false
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local p = Instance.new("CanvasGroup")
		p.Name = "Pad"
		p.AnchorPoint = Vector2.new(0, 0.5)
		p.Position = UDim2.new(ACROSS, SLIDE, DOWN, 0)
		p.Size = UDim2.fromOffset(WIDTH, HEIGHT)
		p.BackgroundTransparency = 1
		p.GroupTransparency = 1
		p.Visible = false
		local s = Instance.new("UIScale")
		s.Parent = p
		scale = s

		-- the steel plate, inset so its rim isn't clipped by the group
		local body = Instance.new("Frame")
		body.Name = "Body"
		body.AnchorPoint = Vector2.new(0.5, 0.5)
		body.Position = UDim2.fromScale(0.5, 0.5)
		body.Size = UDim2.new(1, -4, 1, -4)
		body.BackgroundColor3 = STEEL
		body.SelectionGroup = true -- a gamepad's D-pad stays among the keys
		corner(body, UDim.new(0, 14))
		rim(body, RIM, 1.5, 0.2)
		body.Parent = p

		local well = Instance.new("Frame")
		well.Name = "Readout"
		well.Position = UDim2.fromOffset(EDGE - 2, EDGE - 2)
		well.Size = UDim2.fromOffset(WIDTH - EDGE * 2, READOUT_H)
		well.BackgroundColor3 = GLASS
		corner(well, UDim.new(0, 6))
		rim(well, Color3.new(0, 0, 0), 1, 0.3)
		well.Parent = body
		drawReadout = LedReadout.new(well, SCREEN_LOOK, 0.72, 0.06)

		local top = EDGE - 2 + READOUT_H + UNDER_READOUT
		for r, row in ROWS do
			for c, slot in row do
				local x = EDGE - 2 + (c - 1) * (KEY_W + GAP)
				local y = top + (r - 1) * (KEY_H + GAP)
				if slot == "Light" then
					local l = Instance.new("Frame")
					l.Name = "Light"
					l.AnchorPoint = Vector2.new(0.5, 0.5)
					l.Position = UDim2.fromOffset(x + KEY_W / 2, y + KEY_H / 2)
					l.Size = UDim2.fromOffset(13, 13)
					l.BackgroundColor3 = Elevator.KeypadLight
					corner(l, UDim.new(0.5, 0))
					rim(l, Elevator.KeypadLight, 4, 0.55)
					l.Parent = body
					lamp = l
					continue
				end
				local key: Keypad.Key = if slot == "Clear" then "Clear" else slot :: number
				local b = Instance.new("TextButton")
				b.Name = if key == "Clear" then "Clear" else `Key{key}`
				b.Position = UDim2.fromOffset(x, y)
				b.Size = UDim2.fromOffset(KEY_W, KEY_H)
				b.AutoButtonColor = false
				b.BackgroundColor3 = KEY
				b.Font = Enum.Font.GothamBold
				b.Text = if key == "Clear" then "CLR" else tostring(key)
				b.TextSize = if key == "Clear" then 17 else 26
				b.TextColor3 = INK
				corner(b, UDim.new(0, 8))
				rim(b, KEY_RIM, 1, 0.4)
				local dipScale = Instance.new("UIScale")
				dipScale.Parent = b
				b.Parent = body
				buttons[key] = { button = b, scale = dipScale, tweens = {} }
				b.Activated:Connect(function()
					pressKey(key)
				end)
			end
		end

		p.Parent = screen
		panel = p
		return screen
	end

	return {
		name = "KeypadPad",
		start = function(_: any, _context: Brix.Context)
			local screen = build()
			screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
			gui = screen
			table.insert(connections, screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
			fit()
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Elevator.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, _dt: number)
			local entry = openOn
			if not entry then
				return
			end
			-- walking off, dying or losing the character closes it
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if
				not (root and root:IsA("BasePart"))
				or not humanoid
				or humanoid.Health <= 0
				or (root.Position - Elevator.keypadPoint(entry.model)).Magnitude > CLOSE_REACH
			then
				close()
				return
			end
			if Readout.blinking(entry.state) then
				redraw()
			end
		end,
		stop = function(_: any)
			close()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in entries do
				remove(model)
			end
			if gui then
				gui:Destroy()
				gui = nil
			end
			panel, scale, lamp, drawReadout, slide = nil, nil, nil, nil, nil
			table.clear(buttons)
		end,
	}
end

return KeypadPad
