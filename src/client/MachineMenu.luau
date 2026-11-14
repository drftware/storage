--!strict
--[[
	MachineMenu: the car's vending machine on your screen (S1-10d1; owner, Nov 14: "when you walk
	up you click a prompt that opens an overlay where you can make your selection"), as Dandy's
	World's elevator shop opens a panel between floors.

	The machine has one button ("Buy") on the middle of its glass. It reaches from the car's back
	half and through friends standing in front of it (no line of sight), and shows while you ride
	aboard on a ride that wakes the machine, from its bottom row lighting until the last buy before
	the cut. Pressing it slides the machine's front up from the bottom of the screen with a heavy
	clunk: its oxblood cabinet, its sign with the keyhole coin, its three rows of two bays in the
	machine's own order, each with the thing in its coil, a paper label with its name, its LED
	price and its chunky button. As it arrives its tubes stutter on with the starters' tinks and
	each lit row's LEDs test 88, then show the prices. Every row's light follows the real machine's
	tube on this ride (Wake), so a row that hasn't caught yet is dark here too and lights with it,
	and the panel dips with the car's lamp.

	- A bay shows its state (`Buy.tile`), never in words: a bright price for one you can buy, a dim
	  one for one you can't pay (or a battery your full torch won't take, or a tool with every
	  slot taken), dashes for an empty coil, all dark for a row not lit yet.
	- A pick presses the bay in and the real machine's button with its click (MachineView's
	  `Press`). One you can pay goes to the server (`Buy.Pick`); when the sale comes back
	  (`Buy.Remote`) the panel drops away and stays down (S1-10d3; owner, Nov 14: "You'd click
	  it again to buy another item") so you watch the coins fly, the coil turn and the thing drop
	  and fly to your hand; the Buy on the glass comes back once that's over. One you can't pay
	  buzzes on the machine and blinks its price on both, the bay shakes, and the panel stays up.
	  A dead bay barely moves.
	- It closes when you walk off, the buying ends, you leave the car, you're caught or you die;
	  or by its chrome knob, E, or B on a gamepad. The mouse goes free while it shows (FreeCursor).

	Only stepped while it's open; a frame writes only what changed.
]]
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Battery = require(ReplicatedStorage.Shared.Battery)
local Brix = require(ReplicatedStorage.Brix)
local Buy = require(ReplicatedStorage.Shared.Machine.Buy)
local Charge = require(ReplicatedStorage.Shared.Flashlight.Charge)
local Coins = require(ReplicatedStorage.Shared.Coins)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Machine = require(ReplicatedStorage.Shared.Machine)
local Readout = require(ReplicatedStorage.Shared.Elevator.Readout)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local Stock = require(ReplicatedStorage.Shared.Machine.Stock)
local Tools = require(ReplicatedStorage.Shared.Tools)
local FreeCursor = require(script.Parent.FreeCursor)
local LedReadout = require(script.Parent.LedReadout)
local MachineView = require(script.Parent.MachineView)
local RideClock = require(script.Parent.RideClock)
local ToolPicture = require(script.Parent.ToolPicture)

local Wake = Machine.Wake
local Specs = Machine.Specs

-- Walking this far from the machine's button closes the menu: past the button's reach, inside
-- the server's (`Buy.Reach` + `Buy.Slack`), so a pick made at the edge still counts.
local CLOSE_REACH = Buy.Reach + 1

-- The panel's design size in pixels before it's scaled to the screen: the sign over three rows
-- of two bays over the flap and the coin plate. It fills FILL of the screen's height, scaled no
-- smaller or larger than these: on the Galaxy A16 about 0.6, a bay about 108 by 60, a thumb's
-- width and more.
local EDGE = 12
local SIGN_H, UNDER_SIGN = 38, 8
local BAY_W, BAY_H, BAY_GAP = 180, 100, 10
local TUBE_H, ROW_GAP = 5, 8
local PICTURE_H, RAIL_H = 60, 36
local PLATE_H, OVER_PLATE = 30, 8
local WIDTH = EDGE * 2 + BAY_W * 2 + BAY_GAP
local ROWS_H = 3 * (TUBE_H + BAY_H) + 2 * ROW_GAP
local HEIGHT = EDGE + SIGN_H + UNDER_SIGN + ROWS_H + OVER_PLATE + PLATE_H + EDGE
local FILL = 0.94
local MIN_SCALE, MAX_SCALE = 0.5, 1.25
-- Its middle this far across the screen, so the real machine you face stays in view on its left,
-- and never nearer the right edge than the jump button's room.
local ACROSS = 0.6
local JUMP_ROOM = 110

-- It rises from below the screen like a drawer and drops back the same way.
local RISE = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local DROP = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- A picked bay dips to this size at once and springs back; a dead one barely moves.
local DIP, DEAD_DIP = 0.93, 0.985
local SPRING = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
-- Its tubes as it arrives: from each time (seconds), this share of their light; a starter's tink
-- at each flash. Then each lit row's LEDs test 88 for LED_TEST, as the real windows do.
local FLICKER =
	{ { 0, 0 }, { 0.05, 0.85 }, { 0.09, 0.1 }, { 0.15, 0.95 }, { 0.18, 0.3 }, { 0.24, 1 } }
local TINKS = { 0.05, 0.15 }
local LED_TEST = 0.18
-- A bay you can't pay for shakes side to side this long, this many pixels at first.
local SHAKE, SHAKE_PX = 0.3, 5
-- Seconds a pick waits for its sale before another may go, so a double tap never buys two.
local WAIT_SALE = 1
-- Seconds after your vend is over (the thing in your hand) before the Buy on the glass comes
-- back for another, so you never open the panel over your own vend or buy twice in one.
local BACK_AFTER = 0.3
-- Shares are drawn in steps this fine, so a frame writes only what visibly changed.
local STEPS = 48

-- The machine's own colours (art/machine): oxblood enamel shading down to its foot, a dark lip,
-- brushed steel rails, chrome collars, black plastic, the liner as the tubes light it, a paper
-- label, the price windows' LEDs (the screen's a touch brighter than the wall's, as KeypadPad's).
local ENAMEL = Color3.fromRGB(112, 32, 26)
local LIP = Color3.fromRGB(36, 9, 7)
local LINER_DARK = Color3.fromRGB(16, 16, 18)
local LINER_LIT = Color3.fromRGB(150, 156, 162)
local RAIL = Color3.fromRGB(132, 136, 140)
local CHROME = Color3.fromRGB(214, 218, 222)
local CAP = Color3.fromRGB(30, 30, 33)
local CAP_DOWN = Color3.fromRGB(8, 8, 9)
local PAPER = Color3.fromRGB(228, 220, 198)
local PLASTIC = Color3.fromRGB(18, 18, 20)
local LED: LedReadout.Look = {
	unlit = Color3.fromRGB(70, 12, 10),
	unlitTransparency = 0.6,
	rest = Color3.fromRGB(150, 30, 20),
	lit = Color3.fromRGB(255, 62, 42),
	right = Color3.fromRGB(255, 62, 42),
}

-- Its sounds on your screen alone: a heavy latch as the front comes up (the flap's knock pitched
-- right down) and each starter's tink as its tubes stutter on (the machine's own, quieter).
local CLUNK: Buy.Sound = { id = Buy.Knock.id, from = 0, length = 0.3, volume = 0.6, pitch = 0.5 }
local TINK: Buy.Sound = {
	id = Machine.Tink.id,
	from = Machine.Tink.from,
	length = Machine.Tink.length,
	volume = 0.22,
	pitch = Machine.Tink.pitch,
}

local CLOSE_ACTION = "MachineMenuClose"
-- Over the game's other bindings, so E closes the menu instead of reaching a button behind it.
local PRIORITY = Enum.ContextActionPriority.High.Value

type Entry = {
	model: Model,
	car: Instance,
	at: Attachment,
	prompt: ProximityPrompt,
	rideAt: number?, -- its car's ride, if it wakes the machine
	from: number,
	aboard: boolean, -- you're aboard its car
	window: boolean, -- the buying is open on it now
	restUntil: number, -- os.clock your own vend on it is over, its button hidden till then
	conns: { RBXScriptConnection },
}

type Bay = {
	i: number,
	x: number, -- its place in its row, pixels
	button: TextButton,
	scale: UIScale,
	picture: ViewportFrame,
	label: TextLabel,
	cap: Frame,
	capScale: UIScale,
	set: LedReadout.Set,
	tweens: { Tween },
	key: string?, -- what its picture shows
	named: string?, -- what its label names (the coil's thing, sold out or not)
	tile: string, -- a `Buy.Tile` (the checker widens it to text across the module)
	bright: number, -- its picture's brightness as last drawn
	lit: boolean, -- its row was open last frame
	testUntil: number, -- its LEDs show 88 until then
	blinkAt: number?, -- a pick you couldn't pay: its price blinks from then
	shakeAt: number?,
}

type Row = { liner: Frame, tube: Frame, glow: Frame, shown: number }

local MachineMenu = {}

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

-- A shine down a part's face: full colour at its top, `low` of it at its foot.
local function shade(parent: Instance, low: number)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(low, low, low))
	g.Parent = parent
end

local function box(
	name: string,
	parent: Instance,
	x: number,
	y: number,
	w: number,
	h: number,
	colour: Color3
): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = colour
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function quantize(share: number): number
	return math.floor(math.clamp(share, 0, 1) * STEPS + 0.5) / STEPS
end

-- The tubes' share `t` seconds after the panel arrived.
local function flicker(t: number): number
	local share = 0
	for _, f in FLICKER do
		if t >= f[1] then
			share = f[2]
		end
	end
	return share
end

-- A battery standing in `frame`, turned a little to show its label, filling its height.
local function batteryPicture(frame: ViewportFrame)
	frame:ClearAllChildren()
	local props = ReplicatedStorage:FindFirstChild("Props")
	local template = props and props:FindFirstChild(Battery.Template)
	if not (template and template:IsA("BasePart")) then
		return
	end
	local b = template:Clone()
	b.Anchored = true
	b.CFrame = CFrame.Angles(math.rad(8), math.rad(-28), math.rad(-14))
	b.Parent = frame
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	local tall = math.max(b.Size.X, b.Size.Y, b.Size.Z)
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0, tall * 1.75), Vector3.zero)
	cam.Parent = frame
	frame.CurrentCamera = cam
end

-- `press` sinks the real machine's button (MachineView); `need` frees the mouse (FreeCursor).
function MachineMenu.new(press: MachineView.Pick, need: FreeCursor.Need): Brix.System
	local me = Players.LocalPlayer
	local entries: { [Model]: Entry } = {}
	local connections: { RBXScriptConnection } = {}
	local openOn: Entry? = nil
	local shownAt = 0 -- os.clock it last arrived, for its flicker
	local waiting = -math.huge -- os.clock a pick was last sent
	local stockText: unknown = nil
	local stock: Stock.Stock? = nil
	local pickRemote: RemoteEvent? = nil

	local gui: ScreenGui? = nil
	local panel: Frame? = nil
	local scale: UIScale? = nil
	local sign: Frame? = nil
	local signShown = -1
	local bays: { [number]: Bay } = {}
	local rows: { [number]: Row } = {}
	local slide: Tween? = nil
	local shown, hidden = UDim2.fromScale(ACROSS, 0.5), UDim2.fromScale(ACROSS, 1.5)

	local function remote(): RemoteEvent?
		if pickRemote and pickRemote.Parent then
			return pickRemote
		end
		local folder = ReplicatedStorage:FindFirstChild(Buy.RemoteFolder)
		local r = folder and folder:FindFirstChild(Buy.Pick)
		pickRemote = if r and r:IsA("RemoteEvent") then r else nil
		return pickRemote
	end

	local function blip(spec: Buy.Sound)
		local g = gui
		if not g then
			return
		end
		local s = Instance.new("Sound")
		s.SoundId = spec.id
		s.Volume = spec.volume
		s.PlaybackSpeed = spec.pitch
		s.TimePosition = spec.from
		s.Parent = g
		s:Play()
		task.delay(spec.length / spec.pitch + 0.3, function()
			s:Destroy()
		end)
	end

	-- Its size and place for this screen: FILL of the height, its middle at ACROSS but its right
	-- edge clear of the jump button.
	local function fit()
		local g, s = gui, scale
		if not (g and s) then
			return
		end
		local size = g.AbsoluteSize
		local k = math.clamp(size.Y * FILL / HEIGHT, MIN_SCALE, MAX_SCALE)
		s.Scale = k
		local half = WIDTH * k / 2
		local x = math.min(size.X * ACROSS, size.X - JUMP_ROOM - half)
		x = math.max(x, half)
		shown = UDim2.new(0, x, 0.5, 0)
		hidden = UDim2.new(0, x, 1.5, 0)
		local p = panel
		if p and not slide then
			p.Position = if openOn then shown else hidden
		end
	end

	local function move(up: boolean)
		local p = panel
		if not p then
			return
		end
		if slide then
			slide:Cancel()
		end
		local tween = TweenService:Create(
			p,
			if up then RISE else DROP,
			{ Position = if up then shown else hidden }
		)
		slide = tween
		if up then
			p.Visible = true
		end
		tween.Completed:Once(function(status: Enum.PlaybackState)
			if slide == tween then
				slide = nil
			end
			if status == Enum.PlaybackState.Completed and not openOn then
				p.Visible = false
			end
		end)
		tween:Play()
	end

	-- It arrives: up from below with its latch's clunk, its tubes stuttering on.
	local function arrive()
		shownAt = os.clock()
		for _, b in bays do
			b.testUntil = shownAt + FLICKER[#FLICKER][1] + LED_TEST
		end
		blip(CLUNK)
		for _, t in TINKS do
			task.delay(t, function()
				if openOn then
					blip(TINK)
				end
			end)
		end
		need("MachineMenu", true)
		move(true)
	end

	local function dip(b: Bay, depth: number)
		for _, t in b.tweens do
			t:Cancel()
		end
		table.clear(b.tweens)
		b.scale.Scale = depth
		local deep = depth < DEAD_DIP
		if deep then
			b.capScale.Scale = 0.8
			b.cap.BackgroundColor3 = CAP_DOWN
		end
		local tweens = {
			TweenService:Create(b.scale, SPRING, { Scale = 1 }),
			TweenService:Create(b.capScale, SPRING, { Scale = 1 }),
			TweenService:Create(b.cap, SPRING, { BackgroundColor3 = CAP }),
		}
		for _, t in tweens do
			table.insert(b.tweens, t)
			t:Play()
		end
	end

	-- A bay picked on the panel.
	local function pick(i: number)
		local entry, b = openOn, bays[i]
		if not (entry and b) then
			return
		end
		local clock = os.clock()
		if b.tile == "ok" and clock - waiting >= WAIT_SALE then
			waiting = clock
			dip(b, DIP)
			press(entry.model, i)
			local r = remote()
			if r then
				r:FireServer(entry.model, i)
			end
		elseif b.tile == "poor" then
			dip(b, DIP)
			press(entry.model, i) -- the click, the machine's buzz, its window blinking
			b.blinkAt, b.shakeAt = clock, clock
		else
			dip(b, DEAD_DIP)
		end
	end

	local close: () -> ()

	local function closeKey(_: string, input: Enum.UserInputState, _object: InputObject)
		if input == Enum.UserInputState.Begin then
			close()
		end
		return Enum.ContextActionResult.Sink
	end

	close = function()
		if not openOn then
			return
		end
		openOn = nil
		me:SetAttribute(Tools.StowAttribute, nil) -- the wheel comes back up
		ContextActionService:UnbindAction(CLOSE_ACTION)
		need("MachineMenu", false)
		local selected = GuiService.SelectedObject
		if selected and panel and selected:IsDescendantOf(panel) then
			GuiService.SelectedObject = nil
		end
		move(false)
	end

	local function open(entry: Entry)
		if openOn or not panel then
			return
		end
		openOn = entry
		entry.prompt.Enabled = false
		me:SetAttribute(Tools.StowAttribute, true) -- the wheel slides away, clear of the panel
		stockText, stock = nil, nil
		waiting = -math.huge
		fit()
		ContextActionService:BindActionAtPriority(
			CLOSE_ACTION,
			closeKey,
			false,
			PRIORITY,
			Enum.KeyCode.E,
			Enum.KeyCode.ButtonB
		)
		arrive()
		if UserInputService:GetLastInputType().Name:find("Gamepad") then
			local first = bays[5] or bays[1]
			GuiService.SelectedObject = if first then first.button else nil
		end
	end

	-- The sale of your pick reached this screen: the panel drops away for its vend and stays
	-- down; the Buy on the glass comes back once the vend is over.
	local function sold(machine: unknown)
		local entry = openOn
		if not entry or typeof(machine) ~= "Instance" or machine ~= entry.model then
			return
		end
		waiting = -math.huge
		entry.restUntil = os.clock() + Buy.ends() + BACK_AFTER
		close()
	end

	local function rideChanged(e: Entry)
		local at, from = Ride.decode(e.car:GetAttribute(Ride.Attribute))
		e.rideAt = if at and Wake.wakes(from) then at else nil
		e.from = from
	end

	local function aboardChanged(e: Entry)
		local _, ids = Departure.decodeAboard(e.car:GetAttribute(Departure.AboardAttribute))
		e.aboard = table.find(ids, me.UserId) ~= nil
	end

	local function remove(inst: Instance)
		local e = entries[inst :: Model]
		if not e then
			return
		end
		if openOn == e then
			close()
		end
		entries[inst :: Model] = nil
		for _, c in e.conns do
			c:Disconnect()
		end
		e.at:Destroy()
	end

	local function add(inst: Instance)
		local car = inst.Parent
		if
			not inst:IsA("Model")
			or entries[inst]
			or not car
			or not inst:IsDescendantOf(Workspace)
		then
			return
		end
		-- on the glass, which never moves (a coil turns as it vends, a button sinks)
		local body = inst:FindFirstChild("Glass")
		if not (body and body:IsA("BasePart")) then
			return
		end
		local at = Instance.new("Attachment")
		at.Name = "BuyPrompt"
		at.Parent = body
		at.WorldPosition = Buy.point(inst:GetPivot())
		local p = Instance.new("ProximityPrompt")
		p.Style = Enum.ProximityPromptStyle.Custom -- drawn by ButtonView
		p.ObjectText = ""
		p.ActionText = "Buy"
		p.KeyboardKeyCode = Enum.KeyCode.E
		p.GamepadKeyCode = Enum.KeyCode.ButtonX
		p.HoldDuration = 0
		p.MaxActivationDistance = Buy.Reach
		p.RequiresLineOfSight = false -- friends crowding the machine never hide it
		p.Enabled = false
		p.Parent = at
		local e: Entry = {
			model = inst,
			car = car,
			at = at,
			prompt = p,
			rideAt = nil,
			from = Ride.Lobby,
			aboard = false,
			window = false,
			restUntil = -math.huge,
			conns = {},
		}
		entries[inst] = e
		table.insert(
			e.conns,
			p.Triggered:Connect(function()
				open(e)
			end)
		)
		table.insert(
			e.conns,
			car:GetAttributeChangedSignal(Ride.Attribute):Connect(function()
				rideChanged(e)
			end)
		)
		table.insert(
			e.conns,
			car:GetAttributeChangedSignal(Departure.AboardAttribute):Connect(function()
				aboardChanged(e)
			end)
		)
		rideChanged(e)
		aboardChanged(e)
	end

	-- The keyhole coin on the sign, as the real sign's (Machine's emblem): a coin's ring, a
	-- keyhole through it, a rule out to either side.
	local function emblem(parent: Frame, w: number, h: number)
		local cx, cy, d = w / 2, h / 2, h * 0.74
		local function mark(
			name: string,
			x: number,
			y: number,
			mw: number,
			mh: number,
			round: number
		): Frame
			local f = box(name, parent, x - mw / 2, y - mh / 2, mw, mh, Machine.Ink)
			corner(f, UDim.new(round, 0))
			return f
		end
		local ring = mark("Coin", cx, cy, d, d, 0.5)
		ring.BackgroundTransparency = 1
		rim(ring, Machine.Ink, d * 0.11, 0)
		mark("KeyHead", cx, cy - d * 0.09, d * 0.26, d * 0.26, 0.5)
		mark("KeyFoot", cx, cy + d * 0.12, d * 0.13, d * 0.34, 0.15)
		local gap, edge = d * 0.75, w * 0.08
		local len = cx - gap - edge
		mark("RuleLeft", edge + len / 2, cy, len, h * 0.06, 0.5)
		mark("RuleRight", w - edge - len / 2, cy, len, h * 0.06, 0.5)
	end

	local function buildBay(i: number, parent: Frame, x: number): Bay
		local b = Instance.new("TextButton")
		b.Name = `Bay{i}`
		b.Position = UDim2.fromOffset(x, TUBE_H)
		b.Size = UDim2.fromOffset(BAY_W, BAY_H)
		b.BackgroundTransparency = 1
		b.AutoButtonColor = false
		b.Text = ""
		b.Parent = parent
		local s = Instance.new("UIScale")
		s.Parent = b

		local picture = Instance.new("ViewportFrame")
		picture.Name = "Picture"
		picture.Position = UDim2.fromOffset(6, 2)
		picture.Size = UDim2.fromOffset(BAY_W - 12, PICTURE_H)
		picture.BackgroundTransparency = 1
		picture.Ambient = Color3.fromRGB(150, 156, 166)
		picture.LightColor = Machine.Light.Colour
		picture.LightDirection = Vector3.new(0.3, -1, -0.7)
		picture.Parent = b

		-- the steel rail along the row's front: the label, the price window, the button
		local rail = box("Rail", b, 0, BAY_H - RAIL_H, BAY_W, RAIL_H, RAIL)
		corner(rail, UDim.new(0, 3))
		rim(rail, Color3.new(0, 0, 0), 1, 0.5)
		shade(rail, 0.62)
		local KNOB, WINDOW_W, WINDOW_H, PAD = 28, 42, 24, 6
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Position = UDim2.fromOffset(PAD, 5)
		label.Size = UDim2.fromOffset(BAY_W - PAD * 4 - WINDOW_W - KNOB, RAIL_H - 10)
		label.BackgroundColor3 = PAPER
		label.BorderSizePixel = 0
		label.FontFace =
			Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
		label.TextColor3 = Machine.Ink
		label.TextScaled = true
		label.TextWrapped = true
		label.Text = ""
		local most = Instance.new("UITextSizeConstraint")
		most.MaxTextSize = 17
		most.Parent = label
		local inset = Instance.new("UIPadding")
		inset.PaddingLeft = UDim.new(0, 4)
		inset.PaddingRight = UDim.new(0, 4)
		inset.Parent = label
		corner(label, UDim.new(0, 2))
		label.Parent = rail

		local window = box(
			"Price",
			rail,
			BAY_W - PAD * 2 - KNOB - WINDOW_W,
			(RAIL_H - WINDOW_H) / 2,
			WINDOW_W,
			WINDOW_H,
			Machine.PriceGlass
		)
		corner(window, UDim.new(0, 3))
		rim(window, Color3.new(0, 0, 0), 1, 0.2)
		local set = LedReadout.row(window, LED, 0.74, 0.1, 2)

		local collar =
			box("Button", rail, BAY_W - PAD - KNOB, (RAIL_H - KNOB) / 2, KNOB, KNOB, CHROME)
		corner(collar, UDim.new(0.5, 0))
		shade(collar, 0.55)
		local cap = box("Cap", collar, 0, 0, KNOB - 9, KNOB - 9, CAP)
		cap.AnchorPoint = Vector2.new(0.5, 0.5)
		cap.Position = UDim2.fromScale(0.5, 0.5)
		corner(cap, UDim.new(0.5, 0))
		rim(cap, Color3.fromRGB(70, 70, 76), 1, 0.3)
		local capScale = Instance.new("UIScale")
		capScale.Parent = cap

		b.Activated:Connect(function()
			pick(i)
		end)
		return {
			i = i,
			x = x,
			button = b,
			scale = s,
			picture = picture,
			label = label,
			cap = cap,
			capScale = capScale,
			set = set,
			tweens = {},
			key = nil,
			named = nil,
			tile = "dark",
			bright = -1,
			lit = false,
			testUntil = 0,
			blinkAt = nil,
			shakeAt = nil,
		}
	end

	local function build(): ScreenGui
		local screen = Instance.new("ScreenGui")
		screen.Name = "MachineMenu"
		screen.ResetOnSpawn = false
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.DisplayOrder = 3 -- under CoinView's 5, so the paid coins fly over it

		-- the cabinet's front, its lip round it
		local p = Instance.new("Frame")
		p.Name = "Machine"
		p.AnchorPoint = Vector2.new(0.5, 0.5)
		p.Position = hidden
		p.Size = UDim2.fromOffset(WIDTH, HEIGHT)
		p.BackgroundColor3 = ENAMEL
		p.BorderSizePixel = 0
		p.Visible = false
		p.SelectionGroup = true -- a gamepad's D-pad stays among the bays
		corner(p, UDim.new(0, 14))
		rim(p, LIP, 2.5, 0)
		shade(p, 0.66)
		local s = Instance.new("UIScale")
		s.Parent = p
		scale = s

		local inner = WIDTH - EDGE * 2
		local sg = box("Sign", p, EDGE, EDGE, inner, SIGN_H, Machine.SignDark)
		corner(sg, UDim.new(0, 5))
		rim(sg, LIP, 2, 0)
		emblem(sg, inner, SIGN_H)
		sign = sg

		local glassY = EDGE + SIGN_H + UNDER_SIGN
		local glass = box("Glass", p, EDGE, glassY, inner, ROWS_H, LIP)
		corner(glass, UDim.new(0, 5))
		rim(glass, Color3.new(0, 0, 0), 2, 0.3)
		for r = 3, 1, -1 do
			local y = (3 - r) * (TUBE_H + BAY_H + ROW_GAP)
			local liner = box(`Row{r}`, glass, 0, y, inner, TUBE_H + BAY_H, LINER_DARK)
			corner(liner, UDim.new(0, 4))
			local glow = box("Glow", liner, 0, TUBE_H, inner, BAY_H * 0.7, Machine.TubeLit)
			glow.BackgroundTransparency = 1
			local fall = Instance.new("UIGradient")
			fall.Rotation = 90
			fall.Transparency = NumberSequence.new(0.35, 1)
			fall.Parent = glow
			local tube = box("Tube", liner, 10, 0, inner - 20, TUBE_H, Machine.TubeDark)
			corner(tube, UDim.new(0.5, 0))
			rows[r] = { liner = liner, tube = tube, glow = glow, shown = -1 }
			local col = 0
			for i, bay in Specs.Bays do
				if bay.Row == r then
					bays[i] = buildBay(i, liner, col * (BAY_W + BAY_GAP))
					col += 1
				end
			end
		end

		-- under the glass: the flap over the bin, the coin slot's chrome boss, and a chrome knob
		-- that shuts the menu
		local plateY = glassY + ROWS_H + OVER_PLATE
		local flap = box("Flap", p, EDGE + 24, plateY, inner - 150, PLATE_H, PLASTIC)
		corner(flap, UDim.new(0, 5))
		rim(flap, Color3.fromRGB(70, 70, 76), 1, 0.4)
		local boss = box("Slot", p, WIDTH - EDGE - 96, plateY + 2, PLATE_H - 4, PLATE_H - 4, CHROME)
		corner(boss, UDim.new(0.5, 0))
		shade(boss, 0.55)
		local slot = box("Mouth", boss, 0, 0, 4, PLATE_H - 14, PLASTIC)
		slot.AnchorPoint = Vector2.new(0.5, 0.5)
		slot.Position = UDim2.fromScale(0.5, 0.5)
		corner(slot, UDim.new(0.5, 0))

		local shut = Instance.new("TextButton")
		shut.Name = "Shut"
		shut.Size = UDim2.fromOffset(48, 48)
		shut.AnchorPoint = Vector2.new(0.5, 0.5)
		shut.Position = UDim2.fromOffset(WIDTH - EDGE - 22, plateY + PLATE_H / 2)
		shut.BackgroundTransparency = 1
		shut.Text = ""
		shut.Parent = p
		local knob = box("Knob", shut, 0, 0, 32, 32, CHROME)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Position = UDim2.fromScale(0.5, 0.5)
		corner(knob, UDim.new(0.5, 0))
		shade(knob, 0.5)
		rim(knob, LIP, 1.5, 0.2)
		for _, turn in { 45, -45 } do
			local bar = box("Cross", knob, 0, 0, 4, 17, Color3.fromRGB(46, 46, 50))
			bar.AnchorPoint = Vector2.new(0.5, 0.5)
			bar.Position = UDim2.fromScale(0.5, 0.5)
			bar.Rotation = turn
			corner(bar, UDim.new(0.5, 0))
		end
		shut.Activated:Connect(function()
			blip(Buy.Click)
			close()
		end)

		p.Parent = screen
		panel = p
		return screen
	end

	-- Draws the open panel `clock`: its lights as the real machine's on this ride, each bay's
	-- picture, price and state.
	local function draw(e: Entry, at: number, clock: number)
		local since = RideClock(at)
		local f = flicker(clock - shownAt)
		local text = e.model:GetAttribute(Stock.Attribute)
		if text ~= stockText then
			stockText = text
			stock = Stock.decode(text)
		end
		local coins = me:GetAttribute(Coins.Attribute)
		local left = me:GetAttribute(Charge.Attribute)
		local dev = if RunService:IsStudio() then Workspace:GetAttribute(Charge.Dev) else nil
		local wants = type(left) == "number" and Battery.wants(left, Charge.full(dev))
		local room = false -- a free tool slot, as the server last said (`Slots`): no room dims tools
		for n = 1, Tools.Carry.Slots do
			local k = me:GetAttribute(Tools.slotAttribute(n))
			if not (type(k) == "string" and k ~= "") then
				room = true
				break
			end
		end

		local sg = sign
		local signShare = quantize(Wake.sign(since, e.from) * f)
		if sg and signShare ~= signShown then
			signShown = signShare
			sg.BackgroundColor3 = Machine.SignDark:Lerp(Machine.SignLit, signShare)
		end
		for r, row in rows do
			local share = quantize(Wake.tube(r, since, e.from) * f)
			if share ~= row.shown then
				row.shown = share
				row.liner.BackgroundColor3 = LINER_DARK:Lerp(LINER_LIT, share)
				row.tube.BackgroundColor3 = Machine.TubeDark:Lerp(Machine.TubeLit, share)
				row.glow.BackgroundTransparency = 1 - share * 0.6
			end
		end

		for i, b in bays do
			local row = Specs.Bays[i].Row
			local lit = Buy.open(row, since, e.from)
			if lit and not b.lit and clock - shownAt > 0.3 then
				b.testUntil = clock + LED_TEST -- its row just caught: its LEDs check themselves
			end
			b.lit = lit
			local s = stock and stock[i]
			local tile =
				Buy.tile(s, lit, if type(coins) == "number" then coins else nil, wants, room)
			b.tile = tile
			local key = if s and s.count > 0 then s.key else nil
			if key ~= b.key then
				b.key = key
				if key == Stock.Battery then
					batteryPicture(b.picture)
				elseif key then
					ToolPicture.draw(b.picture, key)
				else
					b.picture:ClearAllChildren()
				end
			end
			local named = if s then s.key else nil
			if named ~= b.named then
				b.named = named
				local item = if named then (Tools.Catalog :: any)[named] else nil -- any: keyed by text
				b.label.Text = if named == Stock.Battery
					then "Battery"
					elseif item then item.name
					else named or ""
			end
			local share = rows[row] and rows[row].shown or 0
			local bright = quantize(
				(0.1 + 0.9 * share) * (if tile == "poor" or tile == "full" then 0.55 else 1)
			)
			if bright ~= b.bright then
				b.bright = bright
				b.picture.ImageColor3 = Color3.new(bright, bright, bright)
			end

			local blink = b.blinkAt
			if blink and clock - blink >= Buy.Blink then
				b.blinkAt, blink = nil, nil
			end
			if tile == "dark" or not s then
				b.set(1, " ", "Off")
				b.set(2, " ", "Off")
			elseif clock < b.testUntil then
				b.set(1, "8", "Lit")
				b.set(2, "8", "Lit")
			elseif tile == "empty" then
				b.set(1, "-", "Rest")
				b.set(2, "-", "Rest")
			else
				local tens, ones = Stock.digits(s.price)
				local on = not blink or math.floor((clock - blink) * Buy.BlinkHz * 2) % 2 == 0
				local tone: Readout.Tone = if blink or tile == "ok" then "Lit" else "Rest"
				b.set(1, if on then tens else " ", if on then tone else "Off")
				b.set(2, if on then ones else " ", if on then tone else "Off")
			end

			local shake = b.shakeAt
			if shake then
				local t = clock - shake
				local dx = 0
				if t >= SHAKE then
					b.shakeAt = nil
				else
					dx = math.sin(t * 55) * SHAKE_PX * (1 - t / SHAKE)
				end
				b.button.Position = UDim2.fromOffset(b.x + dx, TUBE_H)
			end
		end
	end

	return {
		name = "MachineMenu",
		start = function(_: any, _context: Brix.Context)
			local screen = build()
			screen.Parent = me:WaitForChild("PlayerGui")
			gui = screen
			table.insert(connections, screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
			fit()
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Buy.RemoteFolder, 30)
				local r = folder and folder:WaitForChild(Buy.Remote, 30)
				if r and r:IsA("RemoteEvent") then
					table.insert(connections, r.OnClientEvent:Connect(sold))
				end
			end)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Machine.Tag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Machine.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Machine.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, _dt: number)
			-- each machine's button: there while you ride aboard and the buying is open
			local kept = me:GetAttribute(Kept.Attribute) == true
			local clock = os.clock()
			for _, e in entries do
				local at = e.rideAt
				e.window = at ~= nil
					and e.aboard
					and not kept
					and Buy.open(1, RideClock(at), e.from)
				local show = e.window and openOn ~= e and clock >= e.restUntil
				if e.prompt.Enabled ~= show then
					e.prompt.Enabled = show
				end
			end
			local e = openOn
			if not e then
				return
			end
			-- walking off, the buying ending, leaving the car, being caught or dying closes it
			local character = me.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local at = e.rideAt
			if
				not at
				or not e.window
				or not (root and root:IsA("BasePart"))
				or not humanoid
				or humanoid.Health <= 0
				or (root.Position - Buy.point(e.model:GetPivot())).Magnitude > CLOSE_REACH
			then
				close()
				return
			end
			draw(e, at, clock)
		end,
		stop = function(_: any)
			close()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			local all = {}
			for model in entries do
				table.insert(all, model)
			end
			for _, model in all do
				remove(model)
			end
			if gui then
				gui:Destroy()
				gui = nil
			end
			panel, scale, sign, slide = nil, nil, nil, nil
			table.clear(bays)
			table.clear(rows)
		end,
	}
end

return MachineMenu
