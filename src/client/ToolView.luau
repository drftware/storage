--!strict
--[[
	Client system: your tool slots on this screen (L-11b, D-048; the inventory wheel since L-20a,
	D-116), as Lethal Company's slots, picked from a wheel as GTA V's and Red Dead Redemption 2's
	weapons are.

	One round button sits at the bottom middle, three small dots on it for your three slots (lit
	where a tool is, brightest on the one in your hand). Tap it and your slots fan out over it on an
	arc, each a real 3D picture of its tool, with a tick each; tap one and it's in your hand, the
	wheel folds away and the slot flies into the small box beside the button. The box shows the
	slot your hand is on: tap it to pocket the tool (out of your hand and out of view, still yours)
	or to bring it back up. On a computer, Q opens the wheel and frees the mouse to click a slot;
	1, 2 and 3 pick a slot straight away, and a second press of the one you hold pockets it (as
	Rust's hotbar). A pad's d-pad steps left and right round the slots and up pockets or lifts.
	A tap anywhere in the world folds an open wheel away; so does leaving it alone (`Wheel.Linger`).

	G, the d-pad's down or the round Drop button beside the box drops what you hold at your feet;
	but while a button in the world that takes the same key is up (a door's Slam, G), the key is
	that button's and the tool stays in your hand: at an open door the slam is the moment (D-108).
	Q is a shut door's Peek as well: while Peek is up, Q peeks and the wheel stays shut (L-17).
	While the wheel is open, the buttons in the world step aside under it (ButtonView's `aside`).
	Kept in a unit your hands are empty, so the wheel slides off the bottom of the screen and
	leaves the Bang button alone until you're let out (L-17).
	A tool's name shows over the button for a moment as it comes into your hand, as Minecraft's
	hotbar names what you switch to; a friend's handover reads "Bolt cutters from Sam".

	What's in your hand is drawn low on the left of your first-person view (the torch has the right),
	swaying with the torch's own sway (`Torch.step`), drawn small and near your eye so it never pokes
	through a wall, a door or the steel, pulling back and ducking out of view with your nose to one
	(`Hands`, D-060). A new tool swings up into view from below; switching or pocketing swings the
	old one down. Your press answers at once on your screen (with a soft clank) and the server is
	told; the server decides pick-ups, drops and handovers, and their clanks are its sounds, heard
	by everyone near.

	Friends: a "Give" prompt on each friend while you hold a tool. If their hands are full it says
	so on the prompt.

	Tools wear out (S1-08, as Minecraft's do): a row of notches along the foot of the box and of
	each slot on the wheel shows the uses left (`Wear.mark`), the last one red and breathing; a use
	spent pops its notch out. When the server says the tool in your hand broke (ToolBroke), it
	shakes in your grip and tumbles down out of your view, your view kicks, and the box bursts red
	and shrinks away; its snap and its bits are the server's, heard and seen by everyone near.

	`new()` also returns your `Hand` for the systems that use a tool where you stand (HornView): the
	tool brought up into its row's `use` pose for a moment with a jerk, and a place beside the wheel's
	button for that tool's button. The wheel's shape and rules are the pure `Tools.Wheel`.
]]
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local ButtonView = require(script.Parent.ButtonView)
local Flashlight = require(ReplicatedStorage.Shared.Flashlight)
local FreeCursor = require(script.Parent.FreeCursor)
local HandRoom = require(script.Parent.HandRoom)
local InFlight = require(script.Parent.InFlight)
local Hands = require(ReplicatedStorage.Shared.Hands)
local Kept = require(ReplicatedStorage.Shared.Kept)
local SoundPrimer = require(script.Parent.SoundPrimer)
local ToolPicture = require(script.Parent.ToolPicture)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Heft = require(ReplicatedStorage.Shared.Tools.Heft)
local Wheel = require(ReplicatedStorage.Shared.Tools.Wheel)

local Torch = Flashlight.Torch
local Carry = Tools.Carry
local Catalog = Tools.Catalog
local Wear = Tools.Wear

local player = Players.LocalPlayer

local RENDER = "ToolHold"
local RAD = math.pi / 180
local INK = Color3.fromRGB(232, 226, 214) -- the hints' warm off-white, as the torch button's
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local SWING_IN = 0.3 -- seconds a tool takes to come up into your view
local SWING_OUT = 0.14 -- seconds it takes to drop out of it
local SWING_FROM = Vector3.new(0.2, -0.95, 0.3) -- where it comes up from: below your view
local SWING_TILT = -50 -- degrees it's pitched down there, jaw low
local PREDICT = 0.6 -- seconds your screen trusts your own press before the server's word
local SWITCH_VOLUME = 0.45 -- of the pick-up clank: drawing a tool from your belt is quieter
-- Pocketing: the same clank, softer and lower, a tool slid away rather than drawn.
local POCKET_VOLUME = 0.25
local POCKET_PITCH = 0.8
-- The wheel's button: its size, of the screen's height, in pixels at least and at most (a full
-- thumb on a phone, never a slab on a monitor). Its top stays where the old slots' was, which a
-- door's Peek is tuned to clear (`DoorSpot.Below`).
local BUTTON_OF_HEIGHT = 0.12
local BUTTON_MIN, BUTTON_MAX = 56, 88
local LIFT = 1.06 -- the box with the tool up in your hand, raised
-- Kept in a unit your hands are empty (everything dropped where you were caught), so the wheel
-- slides down off the screen and leaves the Bang button alone; it rises back when you're let out.
local STOWED = 2 -- of the button's size, below its place: off the bottom of the screen
local STOW = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local UNSTOW = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
-- The dots on the button: the arc's radius and a dot's size, of the button's.
local DOT_ARC = 0.26
local DOT_SIZE = 0.12
local DOT_ON = 1.35 -- the dot of the tool in your hand, grown
-- The wheel's tick as each slot fans out: Roblox's "UI Bright Click", soft, rising slot by slot.
local TICK_SOUND = "rbxassetid://15675059323"
local TICK_VOLUME = 0.16
local TICK_PITCH = 1.15
local TICK_RISE = 0.08
-- A press that can't go (the ladder takes both hands): the box shakes with a dull click.
local REFUSE_PITCH = 0.55
local REFUSE_VOLUME = 0.3
local SHAKE = { 5, -4, 3, -2, 0 } -- pixels across, a frame or two each
local NAME_SECONDS = 1.4 -- the name over the button, before it fades
local FADE = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUICK = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- At a door: while you hold Cut or Lock with the right tool, it comes down to the latch
-- (`Catalog` row's `use`), and the moment it works it jerks: the jaw clamping, the shackle shut.
local WORK_RATE = 9 -- how fast it moves to the latch and back (of the way, a second)
local WORK_LINGER = 0.3 -- seconds it stays at the latch after it worked
local KICK_DECAY = 6 -- of the jerk, a second
local KICK_PITCH = 9 -- degrees the jerk tips it
local KICK_PUSH = 0.07 -- studs it pushes forward
-- The buttons a tool works (a door's `DoorAction`, a wall's `Tools.ActionAttribute`), and the
-- tool each needs in your hand.
local WORKS: { [string]: string } = { Cut = "BoltCutters", Lock = "Padlock", Saw = "Saw" }
-- While a running saw is out at the wall it shakes in your hand: studs, and how fast it changes.
local SAW_SHAKE = 0.018
local SAW_SHAKE_TURN = 0.6 -- degrees
-- Tools wear out (S1-08): the notches along a slot's foot, one a use (sizes of the slot), the last
-- one red and breathing; a spent one flares and pops out as it goes.
local NOTCH_ROW = UDim2.fromScale(0.78, 0.13)
local NOTCH_FOOT = 0.95 -- the row's bottom edge, of the slot's height
local NOTCH_WIDE = 0.29 -- each notch, of the row's width
local NOTCH_GAP = 0.06
local WARN = Color3.fromRGB(236, 74, 54) -- the last use's red
local SPENT = Color3.fromRGB(16, 16, 16)
local SPENT_ALPHA = 0.45
local WARN_PULSE = 5.5 -- radians a second: its breath, a little under once a second
local WARN_FADE = 0.45 -- of its colour, at the bottom of a breath
local NOTCH_POP = 1.9 -- a spent notch's size as it pops, of its own
local POP = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MOST_USES = 0 -- the most notches any slot shows: the most uses a tool has
for _, row in Catalog do
	if row.wear then
		MOST_USES = math.max(MOST_USES, row.wear.uses)
	end
end
-- A tool breaking in your hand: your view's kick (CameraShake's trauma, 0 to 1: more than a
-- horn's blast), then the tool shakes in your grip for `BREAK_JOLT` seconds, is thrown up out of
-- it (studs a second at full size) and falls away spinning, gone after `BREAK_GONE`; the box
-- bursts to `CRACK_POP` and shrinks away.
local BREAK_KICK = 0.5
local BREAK_JOLT = 0.07
local BREAK_SHAKE = 0.05 -- studs at full size
local BREAK_THROW = Vector3.new(0.7, 1.8, -0.3)
local BREAK_FALL = 18 -- studs a second, each second
local BREAK_SPIN = Vector3.new(7, -4, 10) -- radians a second
local BREAK_GONE = 0.6
local GONE_TRUST = 0.4 -- seconds your screen takes the break's word before the slots catch up
local CRACK_SECONDS = 0.5 -- after a break, an emptied box bursts and shrinks rather than vanishing
local CRACK_POP = 1.2
local CRACK = TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local CURSOR = "ToolWheel" -- the name this screen asks FreeCursor for the mouse by
local ACTIONS =
	{ "ToolSlot1", "ToolSlot2", "ToolSlot3", "ToolStep", "ToolPocket", "ToolWheel", "ToolDrop" }
-- The number keys' actions, and the slot each picks.
local KEYS: { [string]: number } = { ToolSlot1 = 1, ToolSlot2 = 2, ToolSlot3 = 3 }

-- A slot's wear mark (S1-08): notches along its foot, and what they last showed.
type Notch = { frame: Frame, scale: UIScale }
type Marks = { row: Frame, notches: { Notch }, key: string, lit: number, last: boolean }

-- A slot on the wheel.
type SlotView = {
	button: TextButton,
	stroke: UIStroke,
	scale: UIScale,
	frame: ViewportFrame,
	hint: TextLabel,
	marks: Marks,
	key: string, -- what's drawn in it ("" for empty)
	x: number, -- its place on the open wheel, in the button's own pixels
	y: number,
}

-- A dot on the button.
type Dot = { dot: Frame, stroke: UIStroke, scale: UIScale }

-- Everything at the bottom of the screen. `hud` is the button's own square: the rest sits from it.
type Hud = {
	gui: ScreenGui,
	hud: Frame,
	wheel: TextButton,
	wheelStroke: UIStroke,
	wheelScale: UIScale,
	wheelHint: TextLabel,
	dots: { Dot },
	fan: Frame,
	slots: { SlotView },
	box: TextButton,
	boxStroke: UIStroke,
	boxScale: UIScale,
	boxFrame: ViewportFrame,
	boxHint: TextLabel,
	boxMarks: Marks,
	drop: TextButton,
	name: TextLabel,
}

type Give = { prompt: ProximityPrompt, friend: Player }

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

-- The slots as the server last said: the key in each ("" for empty), the slot your hand is on,
-- and whether its tool is pocketed.
local function serverSlots(): ({ string }, number, boolean)
	local keys = {}
	for i = 1, Carry.Slots do
		local k = player:GetAttribute(Tools.slotAttribute(i))
		keys[i] = if type(k) == "string" then k else ""
	end
	local hand = player:GetAttribute(Tools.HandAttribute)
	local pocketed = player:GetAttribute(Tools.PocketedAttribute) == true
	return keys, if type(hand) == "number" then hand else 1, pocketed
end

-- Whether `friend` has room for a tool, by their attributes.
local function hasRoom(friend: Player): boolean
	for i = 1, Carry.Slots do
		local k = friend:GetAttribute(Tools.slotAttribute(i))
		if type(k) ~= "string" or k == "" then
			return true
		end
	end
	return false
end

-- A 3D picture of `key`'s tool in `frame` (empty for "").
local function picture(frame: ViewportFrame, key: string)
	ToolPicture.draw(frame, key)
end

-- A dark button with a thin warm rim, as every button of ours: `round` of 0.5 is a circle.
local function button(
	name: string,
	round: number,
	parent: Instance
): (TextButton, UIStroke, UIScale)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.AutoButtonColor = false
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.BackgroundColor3 = Color3.new(0, 0, 0)
	b.BackgroundTransparency = 0.5
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(round, 0)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Color = INK
	stroke.Transparency = 0.7
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	local scale = Instance.new("UIScale")
	scale.Parent = b
	return b, stroke, scale
end

-- A tool's 3D picture inside a button, `fill` of it.
local function viewport(fill: number, parent: Instance): ViewportFrame
	local vf = Instance.new("ViewportFrame")
	vf.AnchorPoint = Vector2.new(0.5, 0.5)
	vf.Position = UDim2.fromScale(0.5, 0.5)
	vf.Size = UDim2.fromScale(fill, fill)
	vf.BackgroundTransparency = 1
	vf.Ambient = Color3.fromRGB(150, 145, 140)
	vf.LightColor = Color3.fromRGB(255, 240, 220)
	vf.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vf.Parent = parent
	return vf
end

-- A key's hint, small at the top of a button: keyboards only (`layout` shows it).
local function hint(text: string, parent: Instance): TextLabel
	local h = Instance.new("TextLabel")
	h.Name = "Key"
	h.AnchorPoint = Vector2.new(0.5, 0)
	h.Position = UDim2.fromScale(0.5, 0.05)
	h.Size = UDim2.fromScale(0.3, 0.26)
	h.BackgroundTransparency = 1
	h.FontFace = BOLD
	h.Text = text
	h.TextColor3 = INK
	h.TextTransparency = 0.3
	h.TextScaled = true
	h.ZIndex = 2
	h.Parent = parent
	return h
end

-- The uses left of the tool in slot `i`, as the server last said (0: none, or it never wears).
local function usesOf(i: number): number
	local u = player:GetAttribute(Wear.slotAttribute(i))
	return if type(u) == "number" then u else 0
end

-- A slot's wear mark (S1-08): a row of notches along its foot, as Minecraft's bar under a worn
-- tool, over its picture; hidden for a tool that never wears out.
local function notches(parent: Instance): Marks
	local row = Instance.new("Frame")
	row.Name = "Wear"
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.fromScale(0.5, NOTCH_FOOT)
	row.Size = NOTCH_ROW
	row.BackgroundTransparency = 1
	row.Visible = false
	row.ZIndex = 4
	row.Parent = parent
	local out: { Notch } = {}
	for i = 1, MOST_USES do
		local f = Instance.new("Frame")
		f.Name = `Notch{i}`
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromScale(NOTCH_WIDE, 1)
		f.BackgroundColor3 = INK
		f.BorderSizePixel = 0
		f.ZIndex = 4
		f.Parent = row
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = f
		-- a dark edge so a notch reads over any picture
		local edge = Instance.new("UIStroke")
		edge.Color = Color3.new(0, 0, 0)
		edge.Transparency = 0.35
		edge.Thickness = 1
		edge.Parent = f
		local scale = Instance.new("UIScale")
		scale.Parent = f
		table.insert(out, { frame = f, scale = scale })
	end
	return { row = row, notches = out, key = "", lit = 0, last = false }
end

-- Draws `m` for catalog key `key` with `left` uses: lit from the left, the last one red, the
-- spent ones dark. The same tool with one fewer: the notch just spent flares and pops out.
local function mark(m: Marks, key: string, left: number)
	local n, lit, last = Wear.mark(key, left)
	m.row.Visible = n > 0
	local spent = m.key == key and lit < m.lit
	for i, notch in m.notches do
		local f = notch.frame
		f.Visible = i <= n
		if i <= n then
			f.Position = UDim2.fromScale(0.5 + (i - (n + 1) / 2) * (NOTCH_WIDE + NOTCH_GAP), 0.5)
			local on = i <= lit
			local color = if not on then SPENT elseif last then WARN else INK
			local alpha = if on then 0 else SPENT_ALPHA
			if spent and i > lit and i <= m.lit then
				f.BackgroundColor3 = if lit == 0 then WARN else INK
				f.BackgroundTransparency = 0
				notch.scale.Scale = NOTCH_POP
				TweenService:Create(notch.scale, POP, { Scale = 1 }):Play()
				TweenService
					:Create(f, POP, { BackgroundColor3 = color, BackgroundTransparency = alpha })
					:Play()
			else
				f.BackgroundColor3 = color
				f.BackgroundTransparency = alpha
			end
		end
	end
	m.key, m.lit, m.last = key, lit, last
end

-- The last use's notch breathing (each frame, `t` the clock).
local function breathe(m: Marks, t: number)
	if m.last and m.row.Visible then
		local f = m.notches[1].frame
		f.BackgroundTransparency = WARN_FADE * (0.5 - 0.5 * math.cos(t * WARN_PULSE))
	end
end

local function makeHud(): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "Slots" -- WatchView hides the play HUD by name
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local hud = Instance.new("Frame")
	hud.Name = "Hud"
	hud.AnchorPoint = Vector2.new(0.5, 1)
	hud.BackgroundTransparency = 1
	hud.Parent = gui
	-- the round button, its dots, and Q on a keyboard
	local wheel, wheelStroke, wheelScale = button("Wheel", 0.5, hud)
	wheel.Position = UDim2.fromScale(0.5, 0.5)
	wheel.Size = UDim2.fromScale(1, 1)
	wheel.ZIndex = 2
	local dots: { Dot } = {}
	for i = 1, Carry.Slots do
		local d = Instance.new("Frame")
		d.Name = `Dot{i}`
		d.AnchorPoint = Vector2.new(0.5, 0.5)
		d.BackgroundColor3 = INK
		d.BackgroundTransparency = 1
		d.Parent = wheel
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = d
		local stroke = Instance.new("UIStroke")
		stroke.Color = INK
		stroke.Thickness = 1
		stroke.Transparency = 0.45
		stroke.Parent = d
		local scale = Instance.new("UIScale")
		scale.Parent = d
		table.insert(dots, { dot = d, stroke = stroke, scale = scale })
	end
	local wheelHint = hint("Q", wheel)
	wheelHint.AnchorPoint = Vector2.new(0.5, 1)
	wheelHint.Position = UDim2.fromScale(0.5, 0.9)
	-- the wheel's slots, folded into the button until it opens
	local fan = Instance.new("Frame")
	fan.Name = "Fan"
	fan.BackgroundTransparency = 1
	fan.Size = UDim2.fromScale(1, 1)
	fan.Visible = false
	fan.ZIndex = 3
	fan.Parent = hud
	local slots: { SlotView } = {}
	for i = 1, Carry.Slots do
		local b, stroke, scale = button(`Slot{i}`, 0.5, fan)
		local vf = viewport(0.78, b)
		table.insert(slots, {
			button = b,
			stroke = stroke,
			scale = scale,
			frame = vf,
			hint = hint(tostring(i), b),
			marks = notches(b),
			key = "",
			x = 0,
			y = 0,
		})
	end
	-- the box beside the button: the slot your hand is on
	local box, boxStroke, boxScale = button("Box", 0.22, hud)
	box.Visible = false
	local boxFrame = viewport(0.92, box)
	local boxHint = hint("1", box)
	boxHint.AnchorPoint = Vector2.new(0, 0)
	boxHint.Position = UDim2.fromScale(0.07, 0.04)
	boxHint.TextXAlignment = Enum.TextXAlignment.Left
	local boxMarks = notches(box)
	-- Drop: a round button beside the box, shown while you hold a tool
	local drop = Instance.new("TextButton")
	drop.Name = "Drop"
	drop.AutoButtonColor = false
	drop.AnchorPoint = Vector2.new(0, 0.5)
	drop.BackgroundColor3 = Color3.new(0, 0, 0)
	drop.BackgroundTransparency = 0.5
	drop.FontFace = BOLD
	drop.Text = "Drop"
	drop.TextColor3 = INK
	drop.TextScaled = true
	drop.Visible = false
	drop.Parent = hud
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0.5, 0)
	dc.Parent = drop
	local dpad = Instance.new("UIPadding")
	dpad.PaddingLeft = UDim.new(0.18, 0)
	dpad.PaddingRight = UDim.new(0.18, 0)
	dpad.PaddingTop = UDim.new(0.28, 0)
	dpad.PaddingBottom = UDim.new(0.28, 0)
	dpad.Parent = drop
	local ds = Instance.new("UIStroke")
	ds.Color = INK
	ds.Transparency = 0.6
	ds.Thickness = 1.5
	ds.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ds.Parent = drop
	-- the name over the button
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.BackgroundTransparency = 1
	name.FontFace = BOLD
	name.Text = ""
	name.TextColor3 = INK
	name.TextScaled = true
	name.TextTransparency = 1
	name.TextStrokeTransparency = 1
	name.TextStrokeColor3 = Color3.new(0, 0, 0)
	name.Parent = hud
	return {
		gui = gui,
		hud = hud,
		wheel = wheel,
		wheelStroke = wheelStroke,
		wheelScale = wheelScale,
		wheelHint = wheelHint,
		dots = dots,
		fan = fan,
		slots = slots,
		box = box,
		boxStroke = boxStroke,
		boxScale = boxScale,
		boxFrame = boxFrame,
		boxHint = boxHint,
		boxMarks = boxMarks,
		drop = drop,
		name = name,
	}
end

local ToolView = {}

-- Your view's tool, as the systems that use one where you stand see it.
export type Hand = {
	-- the tool in your hand used (the air horn blown): up into its row's `use` pose for `seconds`,
	-- jerking as it starts
	use: (seconds: number) -> (),
	-- puts `button` beside the wheel's button on its left, sized as the Drop button, kept there as
	-- the screen changes
	beside: (button: GuiButton) -> (),
}

-- `needCursor` frees a computer's mouse while the wheel is open, to click a slot; `jolt` kicks
-- your view (CameraShake) as a tool breaks in your hand.
function ToolView.new(
	needCursor: FreeCursor.Need?,
	jolt: ((amount: number) -> ())?
): (Brix.System, Hand)
	local connections: { RBXScriptConnection } = {}
	local ui: Hud? = nil
	local besideButton: GuiButton? = nil
	local nameShown = 0
	local switchRemote: RemoteEvent? = nil
	local pocketRemote: RemoteEvent? = nil
	local dropRemote: RemoteEvent? = nil
	local giveRemote: RemoteEvent? = nil
	-- your own press, trusted for a moment before the server's word: the slot and whether pocketed
	local predicted: { slot: number, pocketed: boolean }? = nil
	local predictedAt = -math.huge
	local lastKeys: { string } = {}
	local gives: { [Model]: Give } = {}
	local viewFolder: Folder? = nil
	-- the wheel
	local wheelOpen = false
	local wheelTurn = 0 -- counts opens and closes, so a late tween's end knows it's stale
	local size = BUTTON_MIN -- the button's size now (layout)
	local boxKey = "" -- what the box shows
	local boxShown = false
	local shaking = 0
	local ticks: { Sound } = {}
	local refuseSound: Sound? = nil
	-- your view's tool
	local sway = Torch.sway()
	local pose = Torch.pose()
	local lastYaw: number?, lastPitch = nil, 0
	local shownKey = ""
	local shownModel: Model? = nil
	local shownBody: BasePart? = nil
	local bodyOff = CFrame.identity
	-- the shown tool's box from its grip (drawn small), for how far ahead of your eye it reaches
	local boxOff = CFrame.identity
	local boxHalf = Vector3.zero
	local pull = 0 -- how far it's pulled back from a wall, studs
	local swing = 0
	local rising = true
	local landed = 0 -- when the shown thing finished coming up: a find's weight lands then (`Heft`)
	local flying = false -- a bought tool is still flying to your hand (InFlight, MachineVend)
	local switchSound: Sound? = nil
	-- at a door
	local working = false
	local workUntil = 0
	local work = 0
	local kick = 0
	-- the buttons shown only with the right tool (ButtonView hides the rest for "Hand")
	local lockReach: { [ProximityPrompt]: boolean } = {} -- each door's Lock
	local sawReach: { [ProximityPrompt]: boolean } = {} -- each wall's Saw
	local leanReach: { [ProximityPrompt]: boolean } = {} -- each front's Lean
	-- a tool breaking in your hand (S1-08): out of your view, its key not drawn again till the
	-- slots catch up, and the box cracking rather than vanishing
	local breaking: Model? = nil
	local breakFrom = CFrame.identity -- its pose from your eye as it went
	local breakAt = 0
	local gone = ""
	local goneUntil = 0
	local cracking = 0

	-- Your hands are your own: alive, and not kept in a unit.
	local function alive(): boolean
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil
			and humanoid.Health > 0
			and player:GetAttribute(Kept.Attribute) ~= true
	end

	-- The slot your hand is on and whether its tool is pocketed: your own press for a moment, then
	-- the server's word.
	local function current(): (number, boolean)
		local _, hand, pocketed = serverSlots()
		local p = predicted
		if p and os.clock() - predictedAt < PREDICT then
			return p.slot, p.pocketed
		end
		predicted = nil
		return hand, pocketed
	end

	local function heldKey(): string
		local keys = serverSlots()
		local slot, pocketed = current()
		return if pocketed then "" else keys[slot] or ""
	end

	local function keyboard(): boolean
		return UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
	end

	-- A line over the button for a moment: a tool's name, or a notice.
	local function say(text: string)
		local label = if ui then ui.name else nil
		if not label then
			return
		end
		nameShown += 1
		local mine = nameShown
		label.Text = text
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0.6
		task.delay(NAME_SECONDS, function()
			if nameShown == mine then
				TweenService
					:Create(label, FADE, { TextTransparency = 1, TextStrokeTransparency = 1 })
					:Play()
			end
		end)
	end

	-- The tool's clank as it comes out of your belt (`lift`) or slides back into it.
	local function clank(key: string, lift: boolean)
		local row = Catalog[key]
		local s = switchSound
		if not (row and s) then
			return
		end
		s.SoundId = row.pickUp.id
		s.PlaybackRegion = NumberRange.new(row.pickUp.from, row.pickUp.from + row.pickUp.length)
		s.Volume = row.pickUp.volume * (if lift then SWITCH_VOLUME else POCKET_VOLUME)
		s.PlaybackSpeed = if lift then 1 else POCKET_PITCH
		s.TimePosition = row.pickUp.from
		s:Play()
	end

	-- A press that can't go: the box shakes with a dull click.
	local function refuse()
		local s = refuseSound
		if s then
			s:Play()
		end
		local h = ui
		if not h then
			return
		end
		shaking += 1
		local mine = shaking
		local at = Wheel.boxAt(size)
		task.spawn(function()
			for _, dx in SHAKE do
				if shaking ~= mine then
					return
				end
				h.box.Position = UDim2.fromOffset(size / 2 + at + dx, size / 2)
				task.wait(0.03)
			end
		end)
	end

	-- Sizes everything for this screen: phone first.
	-- Where the wheel's button sits: low in the middle, or off the bottom while you're kept.
	local stowed = false
	local function restAt(): UDim2
		local y = if stowed then math.floor(size * STOWED) else -math.floor(size * 0.22)
		return UDim2.new(0.5, 0, 1, y)
	end

	local function layout()
		local h = ui
		local camera = Workspace.CurrentCamera
		if not (h and camera) then
			return
		end
		size =
			math.clamp(math.floor(camera.ViewportSize.Y * BUTTON_OF_HEIGHT), BUTTON_MIN, BUTTON_MAX)
		local gap = math.floor(size * Wheel.Gap)
		local mid = size / 2
		h.hud.Size = UDim2.fromOffset(size, size)
		h.hud.Position = restAt()
		local keys = keyboard()
		-- the dots: a small arc, the same shape as the wheel, lifted over Q on a keyboard
		local dot = math.max(5, math.floor(size * DOT_SIZE))
		local _, endY = Wheel.place(1, Carry.Slots, 1)
		local _, topY = Wheel.place(math.ceil(Carry.Slots / 2), Carry.Slots, 1)
		local r = Wheel.radius(Carry.Slots, 1)
		local lift = (endY + topY) / 2 / r -- the arc's own middle, to sit it on the button's
		for i, d in h.dots do
			local a = Wheel.angle(i, Carry.Slots)
			local x = math.sin(a) * size * DOT_ARC
			local y = (-math.cos(a) - lift) * size * DOT_ARC - (if keys then size * 0.1 else 0)
			d.dot.Size = UDim2.fromOffset(dot, dot)
			d.dot.Position = UDim2.fromOffset(mid + x, mid + y)
		end
		h.wheelHint.Visible = keys
		-- the wheel's slots
		local slot = math.floor(size * Wheel.SlotOfButton)
		for i, v in h.slots do
			local x, y = Wheel.place(i, Carry.Slots, size)
			v.x, v.y = mid + x, mid + y
			v.button.Size = UDim2.fromOffset(slot, slot)
			v.button.Position = if wheelOpen
				then UDim2.fromOffset(v.x, v.y)
				else UDim2.fromOffset(mid, mid)
			v.hint.Visible = keys
		end
		-- the box, then Drop, to the right; a tool's own button (HornView's) to the left
		local box = math.floor(size * Wheel.BoxOfButton)
		h.box.Size = UDim2.fromOffset(box, box)
		h.box.Position = UDim2.fromOffset(mid + Wheel.boxAt(size), mid)
		h.boxHint.Visible = keys
		local ds = math.floor(size * 0.62)
		h.drop.Size = UDim2.fromOffset(math.floor(ds * 1.25), ds)
		h.drop.Position = UDim2.fromOffset(size + gap + box + gap, mid)
		local u = besideButton
		if u then
			u.Size = h.drop.Size
			u.AnchorPoint = Vector2.new(1, 0.5)
			u.Position = UDim2.fromOffset(-gap, mid)
		end
		h.name.Size = UDim2.fromOffset(size * 6, math.floor(size * 0.3))
		h.name.Position = UDim2.fromOffset(mid, -math.floor(size * 0.12))
	end

	-- Draws it all from the slots: the dots, the wheel's slots, the box, Drop, and the buttons in
	-- the world that want a tool in your hand.
	local function refresh()
		local h = ui
		if not h then
			return
		end
		local keys = serverSlots()
		local slot, pocketed = current()
		local held = if pocketed then "" else keys[slot] or ""
		-- the dots: lit where a tool is, the one in your hand grown; gone while the wheel is open
		for i, d in h.dots do
			local filled = (keys[i] or "") ~= ""
			local on = filled and i == slot and not pocketed
			TweenService
				:Create(d.dot, QUICK, {
					BackgroundTransparency = if wheelOpen or not filled
						then 1
						elseif on then 0
						else 0.4,
				})
				:Play()
			TweenService:Create(d.stroke, QUICK, {
				Transparency = if wheelOpen then 1 elseif filled then 1 else 0.45,
			}):Play()
			TweenService:Create(d.scale, PRESS, { Scale = if on then DOT_ON else 1 }):Play()
		end
		h.wheelStroke.Transparency = if wheelOpen then 0.05 else 0.6
		h.wheelStroke.Thickness = if wheelOpen then 2.5 else 1.5
		-- the wheel's slots: the one your hand is on lit (softly while pocketed)
		for i, v in h.slots do
			local key = keys[i] or ""
			if v.key ~= key then
				v.key = key
				picture(v.frame, key)
			end
			mark(v.marks, key, usesOf(i))
			local on = i == slot
			v.stroke.Transparency = if on then (if pocketed then 0.45 else 0.05) else 0.7
			v.stroke.Thickness = if on then 2.5 else 1.5
			v.button.BackgroundTransparency = if on then 0.3 else 0.5
		end
		-- the box: the slot your hand is on, raised and lit while its tool's up, dim and sunk while
		-- it's pocketed, gone for an empty slot
		local key = keys[slot] or ""
		-- broken in your hand: the box keeps its picture and its spent notches as it cracks
		local cracked = key == "" and os.clock() < cracking
		if key ~= boxKey then
			boxKey = key
			if not cracked then
				picture(h.boxFrame, key)
			end
		end
		if not cracked then
			mark(h.boxMarks, key, usesOf(slot))
		end
		h.boxHint.Text = tostring(slot)
		local show = key ~= ""
		if show ~= boxShown then
			boxShown = show
			if show then
				h.box.Visible = true
				h.boxScale.Scale = 0.6
				h.boxStroke.Color = INK
			elseif cracked then
				-- it bursts red, then shrinks away
				h.boxStroke.Color = WARN
				h.boxStroke.Transparency = 0
				h.boxScale.Scale = CRACK_POP
				local shrink = TweenService:Create(h.boxScale, CRACK, { Scale = 0 })
				shrink.Completed:Once(function()
					if not boxShown then
						h.box.Visible = false
						h.boxStroke.Color = INK
					end
				end)
				shrink:Play()
			else
				h.box.Visible = false
			end
		end
		if show then
			TweenService:Create(h.boxScale, PRESS, { Scale = if pocketed then 0.94 else LIFT })
				:Play()
			TweenService:Create(h.boxStroke, QUICK, {
				Transparency = if pocketed then 0.7 else 0.05,
				Thickness = if pocketed then 1.5 else 2.5,
			}):Play()
			TweenService:Create(h.box, QUICK, {
				BackgroundTransparency = if pocketed then 0.6 else 0.3,
			}):Play()
			TweenService:Create(h.boxFrame, QUICK, {
				ImageTransparency = if pocketed then 0.55 else 0,
				Position = UDim2.fromScale(0.5, if pocketed then 0.62 else 0.5),
			}):Play()
		end
		h.drop.Visible = held ~= ""
		-- a Give prompt on each friend only while you hold something
		for _, g in gives do
			g.prompt.Enabled = held ~= ""
		end
		-- a door's Lock button only while a padlock's in your hand (on this screen only: the
		-- server never changes a button's reach, so this stays)
		for p in lockReach do
			ButtonView.hide(p, "Hand", held ~= "Padlock")
		end
		-- a wall's Saw button while you carry a saw in any slot: anywhere but your hand, the
		-- button says "Hold the saw"
		local saw = table.find(keys, "Saw") ~= nil
		for p in sawReach do
			ButtonView.hide(p, "Hand", not saw)
		end
		-- a front's Lean button only while the ladder's in your hand
		for p in leanReach do
			ButtonView.hide(p, "Hand", held ~= "Ladder")
		end
		-- a slot newly filled: name it as it comes into your hand
		for i = 1, Carry.Slots do
			local was, now = lastKeys[i] or "", keys[i] or ""
			if was == "" and now ~= "" and i == slot and not pocketed then
				local row = Catalog[now]
				if row then
					say(row.name)
				end
			end
		end
		lastKeys = keys
	end

	-- Folds the wheel away; the slot you `picked` (if a tool's in it) flies into the box.
	local function closeWheel(picked: number?)
		local h = ui
		if not (wheelOpen and h) then
			return
		end
		wheelOpen = false
		wheelTurn += 1
		ButtonView.aside(CURSOR, false)
		local mine = wheelTurn
		local mid = size / 2
		local box = math.floor(size * Wheel.BoxOfButton)
		local slot = math.floor(size * Wheel.SlotOfButton)
		local fly = TweenInfo.new(Wheel.Fly, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fold = TweenInfo.new(Wheel.Close, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local into = false
		for i, v in h.slots do
			if i == picked and v.key ~= "" then
				into = true
				TweenService:Create(v.button, fly, {
					Position = UDim2.fromOffset(mid + Wheel.boxAt(size), mid),
				}):Play()
				TweenService:Create(v.scale, fly, { Scale = box / slot }):Play()
			else
				TweenService:Create(v.button, fold, { Position = UDim2.fromOffset(mid, mid) })
					:Play()
				TweenService:Create(v.scale, fold, { Scale = Wheel.Folded }):Play()
			end
		end
		task.delay(math.max(Wheel.Fly, Wheel.Close), function()
			if wheelTurn ~= mine then
				return
			end
			h.fan.Visible = false
			if into then
				-- the box takes it with a pop
				h.boxScale.Scale = LIFT * 1.12
				refresh()
			end
		end)
		if needCursor then
			needCursor(CURSOR, false)
		end
		refresh()
	end

	-- Fans your slots out over the button, a tick each.
	local function openWheel()
		local h = ui
		if wheelOpen or not (h and alive()) then
			return
		end
		wheelOpen = true
		wheelTurn += 1
		-- the door's buttons under the fan step aside until it folds (L-17)
		ButtonView.aside(CURSOR, true)
		local mine = wheelTurn
		local mid = size / 2
		h.fan.Visible = true
		for i, v in h.slots do
			v.button.Position = UDim2.fromOffset(mid, mid)
			v.scale.Scale = Wheel.Folded
			local delay = (i - 1) * Wheel.Stagger
			local out = TweenInfo.new(
				Wheel.Open,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out,
				0,
				false,
				delay
			)
			TweenService:Create(v.button, out, { Position = UDim2.fromOffset(v.x, v.y) }):Play()
			TweenService:Create(v.scale, out, { Scale = 1 }):Play()
			task.delay(delay, function()
				local s = ticks[i]
				if s and wheelTurn == mine then
					s:Play()
				end
			end)
		end
		h.wheelScale.Scale = 0.9
		TweenService:Create(h.wheelScale, PRESS, { Scale = 1 }):Play()
		if needCursor and keyboard() then
			needCursor(CURSOR, true)
		end
		refresh()
		task.delay(Wheel.Linger, function()
			if wheelTurn == mine then
				closeWheel(nil)
			end
		end)
	end

	-- A press on slot `slot`: from the wheel (`again` false) or its key, the box or the d-pad
	-- (`again` true: a second press on your own slot pockets it).
	local function choose(slot: number, again: boolean)
		if not alive() then
			return
		end
		local keys = serverSlots()
		local active, pocketed = current()
		local what = Wheel.press(slot, active, pocketed, (keys[slot] or "") ~= "", again)
		if what == "None" then
			return
		end
		-- both hands on a big tool (the ladder): no switching away or pocketing; the server
		-- refuses too
		local big = Catalog[heldKey()]
		if big and big.bothHands then
			if what == "Switch" then
				say(`Drop the {string.lower(big.name)} first`)
			end
			refuse()
			return
		end
		if what == "Switch" then
			predicted, predictedAt = { slot = slot, pocketed = false }, os.clock()
			local r = switchRemote
			if r then
				r:FireServer(slot)
			end
		else
			predicted, predictedAt = { slot = active, pocketed = what == "Pocket" }, os.clock()
			local r = pocketRemote
			if r then
				r:FireServer(what == "Pocket")
			end
		end
		local key = keys[slot] or ""
		if what == "Pocket" then
			clank(key, false)
		else
			local row = Catalog[key]
			if row then
				say(row.name)
			end
			clank(key, true)
		end
		refresh()
	end

	-- The box: pocket the tool on your slot, or bring it back up.
	local function toggle()
		local active = current()
		choose(active, true)
	end

	local function drop()
		if not alive() or heldKey() == "" then
			return
		end
		local r = dropRemote
		if r then
			r:FireServer()
		end
	end

	-- The prompt on a friend: "Give" while you hold a tool.
	local function addFriend(friend: Player, character: Model)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not (root and root:IsA("BasePart")) or not character.Parent then
			return
		end
		local p = Instance.new("ProximityPrompt")
		p.Style = Enum.ProximityPromptStyle.Custom -- drawn by ButtonView
		p.Name = "Give"
		p.ActionText = "Give"
		p.ObjectText = friend.DisplayName
		p.KeyboardKeyCode = Enum.KeyCode.E
		p.GamepadKeyCode = Enum.KeyCode.ButtonX
		p.MaxActivationDistance = Carry.GiveReach
		p.RequiresLineOfSight = false
		p.HoldDuration = 0
		p.Enabled = heldKey() ~= ""
		p.Parent = root
		local g: Give = { prompt = p, friend = friend }
		gives[character] = g
		p.Triggered:Connect(function()
			if not hasRoom(friend) then
				ButtonView.refuse(p, "Hands full")
				return
			end
			local r = giveRemote
			if r then
				r:FireServer(friend)
			end
		end)
		character.Destroying:Connect(function()
			gives[character] = nil
		end)
	end

	local function watchFriend(friend: Player)
		if friend == player then
			return
		end
		table.insert(
			connections,
			friend.CharacterAdded:Connect(function(character: Model)
				addFriend(friend, character)
			end)
		)
		local character = friend.Character
		if character then
			task.spawn(addFriend, friend, character)
		end
	end

	-- Your view's tool: `key`'s model, or none.
	local function show(key: string)
		if shownModel then
			shownModel:Destroy()
		end
		shownModel, shownBody, shownKey = nil, nil, key
		if key == "" or not viewFolder then
			return
		end
		local model = Tools.clone(key, CFrame.identity)
		if not model then
			return
		end
		local body = Tools.body(model)
		if not body then
			model:Destroy()
			return
		end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CastShadow = false
			end
		end
		-- drawn small and near your eye (`Hands`): the same on your screen, never through a wall
		model:ScaleTo(Hands.Scale)
		local boxAt, boxSize = model:GetBoundingBox()
		boxOff = model:GetPivot():Inverse() * boxAt
		boxHalf = boxSize / 2
		bodyOff = body.PivotOffset:Inverse()
		model.Parent = viewFolder
		shownModel, shownBody = model, body
	end

	-- The server's word that the tool in your hand (`key`) just broke (S1-08): your view kicks, the
	-- tool you see goes from your grip to shake and fall away (`hold`), and the box cracks.
	local function broke(key: string)
		local clock = os.clock()
		gone, goneUntil = key, clock + GONE_TRUST
		cracking = clock + CRACK_SECONDS
		if jolt then
			jolt(BREAK_KICK)
		end
		local camera = Workspace.CurrentCamera
		local model = shownModel
		if model and shownKey == key and camera then
			if breaking then
				breaking:Destroy()
			end
			breaking = model
			breakFrom = camera.CFrame:ToObjectSpace(model:GetPivot())
			breakAt = clock
			shownModel, shownBody, shownKey = nil, nil, ""
			swing = 0
		end
		refresh()
	end

	-- Each frame, after the camera: the tool in your hand where your left hand holds it, swinging
	-- in and out as it changes.
	local function hold(dt: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local living = alive()
		if wheelOpen and not living then
			closeWheel(nil) -- caught or fallen: the wheel goes with your hands
		end
		local clock = os.clock()
		local hud = ui
		if hud then
			breathe(hud.boxMarks, clock)
			if wheelOpen then
				for _, v in hud.slots do
					breathe(v.marks, clock)
				end
			end
		end
		-- a broken tool: a shake in your grip, then thrown up out of it, falling away and spinning
		local broken = breaking
		if broken then
			local t = clock - breakAt
			if t >= BREAK_GONE then
				broken:Destroy()
				breaking = nil
			else
				local shake = if t < BREAK_JOLT
					then Vector3.new(math.random() * 2 - 1, math.random() * 2 - 1, 0) * BREAK_SHAKE
					else Vector3.zero
				local f = math.max(0, t - BREAK_JOLT)
				local move = shake + BREAK_THROW * f + Vector3.new(0, -0.5 * BREAK_FALL * f * f, 0)
				local turn = BREAK_SPIN * f
				broken:PivotTo(
					camera.CFrame
						* CFrame.new(move * Hands.Scale)
						* breakFrom
						* CFrame.Angles(turn.X, turn.Y, turn.Z)
				)
			end
		end
		local want = if living then heldKey() else ""
		if want == gone and clock < goneUntil then
			want = "" -- it broke: the slots haven't caught up yet
		end
		-- a tool bought at the car's machine is yours already but still on its way: your hand
		-- stays empty until it arrives, then it's simply there, where it flew to, with its weight
		local wasFlying = flying
		flying = InFlight.held(player, "tool")
		if flying then
			want = ""
		elseif wasFlying and want ~= "" and want ~= shownKey then
			show(want)
			swing = 1
			rising = true
			landed = os.clock()
		end
		if want ~= shownKey then
			-- the old one drops out of view, then the new one comes up
			rising = false
			swing -= dt / SWING_OUT
			if swing <= 0 or shownModel == nil then
				swing = 0
				rising = true
				show(want)
			end
		elseif swing < 1 then
			rising = true
			local r = Catalog[shownKey]
			swing =
				math.min(1, swing + dt / Heft.rise(SWING_IN, if r and r.heft then r.heft else 0))
			if swing >= 1 then
				landed = os.clock()
			end
		end
		local body = shownBody
		if not body then
			return
		end
		local cam = camera.CFrame
		local pitch, yaw = cam:ToOrientation()
		local turnYaw, turnPitch = 0, 0
		if lastYaw then
			turnYaw = (yaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
			turnPitch = pitch - lastPitch
		end
		lastYaw, lastPitch = yaw, pitch
		local speed = 0
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if
			root
			and root:IsA("BasePart")
			and humanoid
			and humanoid.FloorMaterial ~= Enum.Material.Air
		then
			local v = root.AssemblyLinearVelocity
			speed = Vector3.new(v.X, 0, v.Z).Magnitude
		end
		local p = Torch.step(sway, dt, speed, turnYaw, turnPitch, pose)
		local row = Catalog[shownKey]
		-- a find's weight: no spring as it comes up, a sag as it lands, a heavier sway (`Heft`)
		local heft = row.heft or 0
		local e = if rising then Heft.ease(swing, heft) else swing * swing
		local sag = if rising and swing >= 1 then Heft.sag(os.clock() - landed, heft) else 0
		local heavy = Heft.swayScale(heft)
		local away = 1 - e
		-- down to the door's latch while you hold its button, and the jerk as it works
		local target = if working or os.clock() < workUntil then 1 else 0
		work += (target - work) * math.min(1, dt * WORK_RATE)
		kick = math.max(0, kick - dt * KICK_DECAY)
		local w = work * work * (3 - 2 * work)
		local h = vec(row.hold):Lerp(vec(row.use), w)
		local t0, t1 = row.holdTurn, row.useTurn
		local yawT = t0[1] + (t1[1] - t0[1]) * w
		-- a running saw out at the wall shakes in your hand (its motor; SawView buzzes your view)
		local buzz, buzzTurn = Vector3.zero, 0
		if shownKey == "Saw" and working and w > 0.5 then
			buzz = Vector3.new(
				(math.random() * 2 - 1) * SAW_SHAKE,
				(math.random() * 2 - 1) * SAW_SHAKE,
				0
			)
			buzzTurn = (math.random() * 2 - 1) * SAW_SHAKE_TURN
		end
		local pitchT = t0[2] + (t1[2] - t0[2]) * w + KICK_PITCH * kick + buzzTurn - Heft.Tip * sag
		local rollT = t0[3] + (t1[3] - t0[3]) * w
		-- where your hand holds it at full size, from your eye; mirrored: the left hand's sway leans
		-- the other way
		local at = h
			+ SWING_FROM * away
			+ Vector3.new(0, 0, -KICK_PUSH * kick)
			+ buzz
			+ Vector3.new(0, -Heft.Depth * sag, 0)
			+ Vector3.new(-p.x, p.y, p.z) * heavy
		-- drawn small and near, it looks the same; nose to a wall it pulls back and ducks
		local small = CFrame.new(at * Hands.Scale)
			* CFrame.fromEulerAnglesYXZ(
				(pitchT + SWING_TILT * away) * RAD + p.pitch * heavy,
				yawT * RAD - p.yaw * heavy,
				rollT * RAD - p.roll * heavy
			)
		local reach = HandRoom.reach(small * boxOff, boxHalf)
		pull = Hands.follow(pull, Hands.pull(HandRoom.room(cam, reach), reach), dt)
		local grip = cam * CFrame.new(0, -Hands.Duck * pull, pull) * small
		-- the whole model, so a second part (the ladder's fly) moves with it
		local model = shownModel
		if model then
			model:PivotTo(grip)
		else
			body.CFrame = grip * bodyOff
		end
	end

	-- The buttons in the world on screen now (ProximityPromptService's shown prompts).
	local shown: { [ProximityPrompt]: true } = {}

	-- Whether a button on screen takes `key` (its keyboard or pad key): then the key is its.
	local function keyTaken(key: Enum.KeyCode): boolean
		for prompt in shown do
			if not prompt.Parent then
				shown[prompt] = nil -- gone without being hidden (its door's floor taken down)
			elseif
				prompt.Enabled and (prompt.KeyboardKeyCode == key or prompt.GamepadKeyCode == key)
			then
				return true
			end
		end
		return false
	end

	local function onAction(
		name: string,
		state: Enum.UserInputState,
		input: InputObject
	): Enum.ContextActionResult
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		local slot = KEYS[name]
		if slot then
			-- with the wheel open a number picks from it; else a second press pockets
			local open = wheelOpen
			choose(slot, not open)
			closeWheel(slot)
		elseif name == "ToolStep" then
			-- the d-pad's left and right step round the slots
			local active = current()
			local dir = if input.KeyCode == Enum.KeyCode.DPadLeft then -1 else 1
			choose(Wheel.step(active, dir, Carry.Slots), false)
		elseif name == "ToolPocket" then
			toggle()
		elseif name == "ToolWheel" then
			if not wheelOpen and keyTaken(input.KeyCode) then
				-- a door's Peek is up on Q: the peek is the moment (1, 2, 3 still pick), L-17
				return Enum.ContextActionResult.Pass
			end
			if wheelOpen then
				closeWheel(nil)
			else
				openWheel()
			end
		elseif name == "ToolDrop" then
			if keyTaken(input.KeyCode) then
				-- a door's Slam is up on the same key: the slam is the moment, the tool stays
				return Enum.ContextActionResult.Pass
			end
			drop()
		end
		return Enum.ContextActionResult.Sink
	end

	local system = { name = "ToolView" }

	function system.start(_: any, _context: Brix.Context)
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		task.spawn(SoundPrimer.prime, Tools.soundIds())
		task.spawn(SoundPrimer.prime, { TICK_SOUND })
		local folder = Instance.new("Folder")
		folder.Name = "YourTool"
		folder.Parent = Workspace
		viewFolder = folder
		local s = Instance.new("Sound")
		s.Name = "ToolSwitch"
		s.PlaybackRegionsEnabled = true
		s.Parent = folder
		switchSound = s
		for i = 1, Carry.Slots do
			local t = Instance.new("Sound")
			t.Name = `WheelTick{i}`
			t.SoundId = TICK_SOUND
			t.Volume = TICK_VOLUME
			t.PlaybackSpeed = TICK_PITCH + TICK_RISE * (i - 1)
			t.Parent = folder
			table.insert(ticks, t)
		end
		local no = Instance.new("Sound")
		no.Name = "WheelRefuse"
		no.SoundId = TICK_SOUND
		no.Volume = REFUSE_VOLUME
		no.PlaybackSpeed = REFUSE_PITCH
		no.Parent = folder
		refuseSound = no
		local h = makeHud()
		ui = h
		if besideButton then
			besideButton.Parent = h.hud
		end
		table.insert(
			connections,
			h.wheel.Activated:Connect(function()
				if wheelOpen then
					closeWheel(nil)
				else
					openWheel()
				end
			end)
		)
		for i, v in h.slots do
			table.insert(
				connections,
				v.button.Activated:Connect(function()
					if not wheelOpen then
						return -- folding away: too late
					end
					choose(i, false)
					closeWheel(i)
				end)
			)
		end
		table.insert(connections, h.box.Activated:Connect(toggle))
		table.insert(connections, h.drop.Activated:Connect(drop))
		-- a tap or click out in the world folds an open wheel away (and still turns the view)
		table.insert(
			connections,
			UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
				if
					wheelOpen
					and not processed
					and (
						input.UserInputType == Enum.UserInputType.Touch
						or input.UserInputType == Enum.UserInputType.MouseButton1
					)
				then
					closeWheel(nil)
				end
			end)
		)
		h.gui.Parent = player:WaitForChild("PlayerGui")
		h.gui.Enabled = true
		layout()
		local camera = Workspace.CurrentCamera
		if camera then
			table.insert(
				connections,
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
			)
		end
		table.insert(connections, UserInputService.LastInputTypeChanged:Connect(layout))
		-- kept in a unit, or the machine's menu up: the wheel slides down off the screen, and back
		-- up when you're let out or the menu shuts
		local function keptChanged()
			local now = player:GetAttribute(Kept.Attribute) == true
				or player:GetAttribute(Tools.StowAttribute) == true
			if now == stowed then
				return
			end
			stowed = now
			if now then
				closeWheel(nil)
			end
			TweenService:Create(h.hud, if now then STOW else UNSTOW, { Position = restAt() }):Play()
		end
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Kept.Attribute):Connect(keptChanged)
		)
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Tools.StowAttribute):Connect(keptChanged)
		)
		keptChanged()
		for i = 1, Carry.Slots do
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Tools.slotAttribute(i)):Connect(refresh)
			)
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Wear.slotAttribute(i)):Connect(refresh)
			)
		end
		-- the server agreed (or overruled): its word from here
		local function settled()
			local _, hand, pocketed = serverSlots()
			local p = predicted
			if p and p.slot == hand and p.pocketed == pocketed then
				predicted = nil
			end
			refresh()
		end
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Tools.HandAttribute):Connect(settled)
		)
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Tools.PocketedAttribute):Connect(settled)
		)
		-- the door buttons your tool works: your view follows your hold on them
		local function works(prompt: ProximityPrompt): boolean
			local action = prompt:GetAttribute("DoorAction")
				or prompt:GetAttribute(Tools.ActionAttribute)
			return type(action) == "string" and WORKS[action] ~= nil and WORKS[action] == heldKey()
		end
		table.insert(
			connections,
			ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
				shown[prompt] = true
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
				shown[prompt] = nil
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt)
				if works(prompt) then
					working = true
				end
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptButtonHoldEnded:Connect(function(_prompt: ProximityPrompt)
				working = false
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
				if works(prompt) then
					kick = 1
					workUntil = os.clock() + WORK_LINGER
				end
			end)
		)
		local function addLock(inst: Instance)
			if inst:IsA("ProximityPrompt") and lockReach[inst] == nil then
				lockReach[inst] = true
				ButtonView.hide(inst, "Hand", heldKey() ~= "Padlock")
			end
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Tools.LockTag):Connect(addLock)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Tools.LockTag)
				:Connect(function(inst: Instance)
					lockReach[inst :: ProximityPrompt] = nil
				end)
		)
		for _, inst in CollectionService:GetTagged(Tools.LockTag) do
			addLock(inst)
		end
		local function addSaw(inst: Instance)
			if inst:IsA("ProximityPrompt") and sawReach[inst] == nil then
				sawReach[inst] = true
				ButtonView.hide(inst, "Hand", table.find(serverSlots(), "Saw") == nil)
			end
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Tools.SawTag):Connect(addSaw)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Tools.SawTag)
				:Connect(function(inst: Instance)
					sawReach[inst :: ProximityPrompt] = nil
				end)
		)
		for _, inst in CollectionService:GetTagged(Tools.SawTag) do
			addSaw(inst)
		end
		local function addLean(inst: Instance)
			if inst:IsA("ProximityPrompt") and leanReach[inst] == nil then
				leanReach[inst] = true
				ButtonView.hide(inst, "Hand", heldKey() ~= "Ladder")
			end
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Tools.LeanTag):Connect(addLean)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Tools.LeanTag)
				:Connect(function(inst: Instance)
					leanReach[inst :: ProximityPrompt] = nil
				end)
		)
		for _, inst in CollectionService:GetTagged(Tools.LeanTag) do
			addLean(inst)
		end
		lastKeys = serverSlots()
		refresh()
		ContextActionService:BindAction("ToolSlot1", onAction, false, Enum.KeyCode.One)
		ContextActionService:BindAction("ToolSlot2", onAction, false, Enum.KeyCode.Two)
		ContextActionService:BindAction("ToolSlot3", onAction, false, Enum.KeyCode.Three)
		ContextActionService:BindAction(
			"ToolStep",
			onAction,
			false,
			Enum.KeyCode.DPadLeft,
			Enum.KeyCode.DPadRight
		)
		ContextActionService:BindAction("ToolPocket", onAction, false, Enum.KeyCode.DPadUp)
		ContextActionService:BindAction("ToolWheel", onAction, false, Enum.KeyCode.Q)
		ContextActionService:BindAction(
			"ToolDrop",
			onAction,
			false,
			Enum.KeyCode.G,
			Enum.KeyCode.DPadDown
		)
		RunService:BindToRenderStep(RENDER, Enum.RenderPriority.Camera.Value + 2, hold)
		table.insert(connections, Players.PlayerAdded:Connect(watchFriend))
		for _, friend in Players:GetPlayers() do
			watchFriend(friend)
		end
		task.spawn(function()
			local remotes = ReplicatedStorage:WaitForChild(Tools.RemoteFolder, 30)
			if not remotes then
				return
			end
			local function get(name: string): RemoteEvent?
				local r = remotes:WaitForChild(name, 30)
				return if r and r:IsA("RemoteEvent") then r else nil
			end
			switchRemote = get(Tools.SwitchRemote)
			pocketRemote = get(Tools.PocketRemote)
			dropRemote = get(Tools.DropRemote)
			giveRemote = get(Tools.GiveRemote)
			local brokeRemote = get(Tools.BrokeRemote)
			if brokeRemote then
				table.insert(
					connections,
					brokeRemote.OnClientEvent:Connect(function(key: unknown)
						if type(key) == "string" then
							broke(key)
						end
					end)
				)
			end
			local notice = get(Tools.NoticeRemote)
			if notice then
				table.insert(
					connections,
					notice.OnClientEvent:Connect(function(text: unknown)
						if type(text) == "string" then
							say(text)
						end
					end)
				)
			end
		end)
	end

	function system.stop(_: any)
		RunService:UnbindFromRenderStep(RENDER)
		for _, name in ACTIONS do
			ContextActionService:UnbindAction(name)
		end
		if wheelOpen then
			ButtonView.aside(CURSOR, false)
			if needCursor then
				needCursor(CURSOR, false)
			end
		end
		wheelOpen = false
		wheelTurn += 1
		shaking += 1
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		table.clear(shown)
		for _, g in gives do
			g.prompt:Destroy()
		end
		table.clear(gives)
		if ui then
			ui.gui:Destroy()
			ui = nil
		end
		if viewFolder then
			viewFolder:Destroy()
		end
		table.clear(ticks)
	end

	local hand: Hand = {
		use = function(seconds: number)
			kick = 1
			workUntil = math.max(workUntil, os.clock() + seconds)
		end,
		beside = function(b: GuiButton)
			besideButton = b
			b.Parent = if ui then ui.hud else nil
			layout()
		end,
	}

	return system :: any, hand -- any: a plain Brix system built field by field
end

return ToolView
