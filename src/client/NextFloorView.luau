--!strict
--[[
	NextFloorView: the next-floor cards on a rider's screen (S4-03b2, D-405), the part of the
	team's vote players touch. The rules are the pure `NextFloorCards`; the vote is the server's
	NextFloors, read off the riding car's attributes (`NextFloor.OfferAttribute`,
	`PressesAttribute`, `PickedAttribute`).

	The moment: the car lurches off and three cards slide up from the bottom of your screen, each a
	picture of a version of the floor you're riding to (`art/cards/`) and the coins it pays. You
	tap one: it clunks, dips under your thumb, lights in its own colour, and your head drops onto
	it. Your friends' heads drop onto the cards they tap with a tick, so you watch the vote move,
	and changing your mind carries your head across. On the cable's second knock the losers go
	dark with a relay's thunk and sink away, and the winner flares with the elevator's ding,
	glides to the middle and stays lit, breathing, until the gate opens on its floor; the riders'
	change of cars at the third knock happens under it. Proven: Hades shows each door's reward
	before you pick; a lobby's map vote shows who voted for which map.

	The arrival (S4-03c2): as the gate starts to fold open, the winner, heads and all, lifts and
	flies into the gate's opening on your screen, shrinking and turning, and bursts there in its
	own colour: a ring and a wash of that light over your view, its own sound (`NextFloor`'s
	row), and the hall beyond the gate lit in it for a breath. You know which floor you chose
	before you see it, as Hades' door reward flies to you as you walk through.

	- Only riders see them: the ride's `Aboard` names you. They're drawn from the car the vote is
	  on and kept up on their own once that car's gone (the hand-off clears the floor below).
	- A press goes to the server (`NextFloor.Remote`) and shows at once; the car's word takes over
	  within `PREDICT` seconds, so a press the server dropped puts your head back where it was.
	- Keys 1, 2 and 3 (or the d-pad's left, up and right) press them on a computer or a pad while
	  the vote is open, a small key cap on each card when you last used a keyboard; the mouse goes
	  free for the vote (FreeCursor) and is handed back on the knock.
	- They tuck off the bottom while the machine's menu is up (Tools' `StowAttribute`), so it's
	  never covered, and come back as it shuts; the tool wheel stays down while the cards are up
	  (Tools' `CardsStowAttribute`), out from under them.
	Only stepped during a ride with a vote; a frame writes only what changed.
]]
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Buy = require(ReplicatedStorage.Shared.Machine.Buy)
local Cards = require(ReplicatedStorage.Shared.NextFloorCards)
local Coins = require(ReplicatedStorage.Shared.Coins)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local ElevatorSounds = require(ReplicatedStorage.Shared.Elevator.Sounds)
local FreeCursor = require(script.Parent.FreeCursor)
local NextFloor = require(ReplicatedStorage.Shared.NextFloor)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local RideClock = require(script.Parent.RideClock)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tools = require(ReplicatedStorage.Shared.Tools)

type Sound = Buy.Sound

local ACTION = "NextFloorCards"
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local HEAVY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
local INK = Color3.fromRGB(232, 226, 214) -- the coins' warm off-white, as the tool hints'
local STEEL = Color3.fromRGB(22, 22, 25) -- a card's frame: the car panel's dark steel
local RIM = Color3.fromRGB(58, 58, 64) -- its edge while it isn't lit
local DIM = Color3.new(0.8, 0.8, 0.8) -- an unlit picture: there, not glowing
local DARK = Color3.new(0.2, 0.2, 0.23) -- a loser's picture once the knock has gone
local MY_RING = Color3.fromRGB(255, 244, 222) -- the ring round your own head: find yourself
local THEIR_RING = Color3.fromRGB(20, 20, 24) -- a friend's

-- Seconds your own press shows before the car's word must agree with it (the server is the vote).
local PREDICT = 0.6
-- Seconds without any car carrying the ride before the cards go: a car that came back, or a
-- climb that ended under you.
local LOST = 1.5
-- Seconds between checks that a car still carries the ride.
local LOOK_EVERY = 0.25
-- Of a card's light: a card your friends are on but you aren't glows this much; yours fully.
local FRIENDS_LIT = 0.35
-- Pixels round a card its glow reaches.
local GLOW = 10

-- The motions. Up from below with a little overshoot, as a lever-pulled sign; a card dips under
-- your thumb and springs back; heads drop with a bounce; the losers go dark fast and sink after
-- a beat, the winner punches out and glides to the middle.
local SLIDE_IN = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local DEAL_STAGGER = 0.07 -- seconds between the three arriving, left to right
local SLIDE_OUT = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local DIP_DOWN = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DIP_UP = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local DIP = 0.9 -- a pressed card's size at the bottom of its dip
local LIGHT = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HEAD_DROP = TweenInfo.new(0.38, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local HEAD_FROM = 28 -- pixels above its place a new head drops from
local HEAD_MOVE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HEAD_GONE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local GO_DARK = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SINK_AFTER = 0.75 -- seconds the dark losers stay before they sink away
local SINK = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FLARE = 0.15 -- the white over the winner's picture at the knock, fading out
local FLARE_FADE = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PUNCH = 1.14 -- the winner's size at the top of its flare
local PUNCH_OUT = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PUNCH_BACK = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CENTRE = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local BREATHE = TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local BREATHE_LOW = 0.35 -- the winner's glow at the low of its breath
local TUCK = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- The arrival (S4-03c2): the winner lifts a little, then flies into the gate, picking up speed
-- as a thrown thing does, small at the end as if far off; then its light bursts there.
local LIFT = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LIFT_SIZE = 1.1
local FLY = TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FLY_SIZE = 0.1 -- of its size as it goes in
local FLY_TURN = 8 -- degrees it turns on the way, tipping in
local INTO = 6 -- studs past the gate's opening it flies to: into the floor, not the gate
local RING = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RING_SIZE = 0.75 -- the ring's reach, of the screen's height
local WASH = 0.72 -- how see-through its light's wash over your view starts
local WASH_FADE = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- The hall beyond the gate lit in its colour for a breath: one light, on this screen only.
local HALL_UP = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HALL_DOWN = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local HALL_BRIGHT = 4
local HALL_RANGE = 30

-- The sounds, flat in your ears (the cards are on your screen): every one from Roblox's licensed
-- library the game already plays. The cards latching up, a tick as each lands; your press's heavy
-- clunk with the button's click; a friend's head landing, a lighter tick; at the knock the
-- relay's thunk as the losers go dark and the elevator's own ding for the winner.
local LATCH = ElevatorSounds.Sounds["Latch" :: ElevatorSounds.SoundName]
local DING = ElevatorSounds.Sounds["Ding" :: ElevatorSounds.SoundName]
local SLIDE: Sound = { id = LATCH.Id, from = LATCH.Start, length = 0.5, volume = 0.55, pitch = 1.3 }
local DEAL: Sound = { id = Buy.Click.id, from = 0, length = 0.2, volume = 0.3, pitch = 1.25 }
local DEAL_RISE = 0.12 -- each card's tick a little higher than the last
local CLUNK: Sound = { id = Buy.Knock.id, from = 0, length = 0.3, volume = 0.75, pitch = 0.55 }
local CLICK: Sound = { id = Buy.Click.id, from = 0, length = 0.2, volume = 0.45, pitch = 1 }
local FRIEND: Sound = { id = Buy.Click.id, from = 0, length = 0.2, volume = 0.22, pitch = 1.7 }
local THUNK: Sound = { id = LATCH.Id, from = LATCH.Start, length = 0.6, volume = 0.7, pitch = 0.7 }
local WIN: Sound = { id = DING.Id, from = 0, length = 1.6, volume = 5, pitch = 1 }

local KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.DPadLeft] = 1,
	[Enum.KeyCode.DPadUp] = 2,
	[Enum.KeyCode.DPadRight] = 3,
}

-- One card on the screen, kept from ride to ride; `name` is the version on it this ride.
type Card = {
	index: number,
	slot: Frame, -- its place: slides up, tucks, sinks; carries the heads
	body: TextButton, -- the card itself: tapped, dips, punches
	scale: UIScale,
	glow: CanvasGroup, -- its colour of light round it
	stroke: UIStroke,
	face: ImageLabel,
	flash: Frame,
	strip: Frame,
	coin: ImageLabel,
	pay: TextLabel,
	key: TextLabel,
	name: string?,
	light: Color3,
	lit: number, -- 0 to 1, as last drawn
	x: number, -- pixels right of the screen's middle it rests at
	shown: boolean, -- up on the screen (not under it)
	sunk: boolean, -- a loser gone under after the knock
	breathe: Tween?,
}

-- A rider's head on a card.
type Head = {
	image: ImageLabel,
	ring: UIStroke,
	card: Card,
}

-- The vote on this player's ride.
type Session = {
	at: number, -- the ride's start, server time: its identity across the hand-off
	to: number, -- the floor it rides to (the pay is that floor's)
	car: Model, -- the car the vote is on
	offered: { string },
	presses: { [number]: string },
	picked: string?,
	phase: Cards.Phase,
	seen: number, -- os.clock() a car was last seen carrying the ride
	lookedAt: number,
	mine: string?, -- my own press, shown before the car's word
	minedAt: number,
}

local NextFloorView = {}

-- `need` frees the mouse for the vote (FreeCursor).
function NextFloorView.new(need: FreeCursor.Need): Brix.System
	local player = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local watched: { [Model]: { RBXScriptConnection } } = {}
	local gui: ScreenGui? = nil
	local cards: { Card } = {}
	local heads: { [number]: Head } = {}
	local layout: Cards.Layout = Cards.layout(685, 280)
	local session: Session? = nil
	local stepping: RBXScriptConnection? = nil
	local tucked = false
	local bound = false
	local freed = false
	local stowed = false
	local remote: RemoteEvent? = nil

	local function play(spec: Sound, pitch: number?)
		local s = Instance.new("Sound")
		s.SoundId = spec.id
		s.Volume = spec.volume
		s.PlaybackSpeed = pitch or spec.pitch
		s.TimePosition = spec.from
		s.Parent = SoundService
		s:Play()
		task.delay(spec.length / s.PlaybackSpeed + 0.2, function()
			s:Destroy()
		end)
	end

	local function tween(
		inst: Instance,
		info: TweenInfo,
		goal: { [string]: any }
	): Tween -- any: a tween's property table
		local t = TweenService:Create(inst, info, goal)
		t:Play()
		return t
	end

	local function getRemote(): RemoteEvent?
		local r = remote
		if r and r.Parent then
			return r
		end
		local folder = ReplicatedStorage:FindFirstChild(NextFloor.RemoteFolder)
		local found = folder and folder:FindFirstChild(NextFloor.Remote)
		remote = if found and found:IsA("RemoteEvent") then found else nil
		return remote
	end

	-- Where a card's slot rests: up on the screen, or under its bottom edge.
	local function restAt(card: Card, up: boolean): UDim2
		local below = if up then 0 else layout.cardH + layout.bottom + layout.head + 12
		return UDim2.new(0.5, card.x, 1, -layout.bottom + below)
	end

	-- Where head `i` of `n` sits on a card: along its top edge, a little over the picture.
	local function headAt(i: number, n: number): UDim2
		local x = Cards.headX(i, n, layout.cardW, layout.head)
		return UDim2.fromOffset(layout.cardW / 2 + x, math.floor(layout.head * 0.15))
	end

	local function keyboard(): boolean
		local t = UserInputService:GetLastInputType()
		return t == Enum.UserInputType.Keyboard
			or t == Enum.UserInputType.MouseButton1
			or t == Enum.UserInputType.MouseMovement
			or t == Enum.UserInputType.MouseWheel
	end

	-- Sizes every card and head for this screen, without motion.
	local function fit()
		local g = gui
		if not g then
			return
		end
		local size = g.AbsoluteSize
		if size.X < 2 or size.Y < 2 then
			return
		end
		layout = Cards.layout(size.X, size.Y)
		local stripH = layout.cardH - layout.faceH
		for i, card in cards do
			card.x = if card.sunk
					or not (session and session.picked and card.name == session.picked)
				then layout.xs[i]
				else 0
			card.slot.Size = UDim2.fromOffset(layout.cardW, layout.cardH)
			card.slot.Position = restAt(card, card.shown and not tucked and not card.sunk)
			card.glow.Size = UDim2.fromOffset(layout.cardW + GLOW * 2, layout.cardH + GLOW * 2)
			card.face.Size = UDim2.fromOffset(layout.cardW - 6, layout.faceH - 3)
			card.flash.Size = card.face.Size
			card.strip.Position = UDim2.fromOffset(0, layout.faceH)
			card.strip.Size = UDim2.fromOffset(layout.cardW, stripH)
			local icon = math.floor(stripH * 0.62)
			card.coin.Size = UDim2.fromOffset(icon, icon)
			card.pay.TextSize = icon
			local cap = math.max(14, math.floor(layout.head * 0.7))
			card.key.Size = UDim2.fromOffset(cap, cap)
			card.key.TextSize = math.floor(cap * 0.75)
		end
		for _, head in heads do
			head.image.Size = UDim2.fromOffset(layout.head, layout.head)
		end
	end

	local function makeCard(screen: ScreenGui, index: number): Card
		local slot = Instance.new("Frame")
		slot.Name = `Card{index}`
		slot.AnchorPoint = Vector2.new(0.5, 1)
		slot.BackgroundTransparency = 1
		slot.Parent = screen

		-- its light: three soft rings, white, tinted by the group, faded in as it lights
		local glow = Instance.new("CanvasGroup")
		glow.Name = "Glow"
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.Position = UDim2.fromScale(0.5, 0.5)
		glow.BackgroundTransparency = 1
		glow.GroupTransparency = 1
		glow.ZIndex = 0
		for ring, see in { 0.88, 0.74, 0.55 } do
			local f = Instance.new("Frame")
			local inset = (ring - 1) * GLOW * 0.4
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
			f.BackgroundColor3 = Color3.new(1, 1, 1)
			f.BackgroundTransparency = see
			f.BorderSizePixel = 0
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 8 + GLOW - inset)
			c.Parent = f
			f.Parent = glow
		end
		glow.Parent = slot

		local body = Instance.new("TextButton")
		body.Name = "Body"
		body.Text = ""
		body.AutoButtonColor = false
		body.AnchorPoint = Vector2.new(0.5, 0.5)
		body.Position = UDim2.fromScale(0.5, 0.5)
		body.Size = UDim2.fromScale(1, 1)
		body.BackgroundColor3 = STEEL
		body.BorderSizePixel = 0
		body.ZIndex = 1
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = body
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = RIM
		stroke.Thickness = 2
		stroke.Parent = body
		local scale = Instance.new("UIScale")
		scale.Parent = body

		local face = Instance.new("ImageLabel")
		face.Name = "Face"
		face.BackgroundColor3 = Color3.new(0, 0, 0)
		face.BorderSizePixel = 0
		face.Position = UDim2.fromOffset(3, 3)
		face.ScaleType = Enum.ScaleType.Crop
		face.ImageColor3 = DIM
		face.ZIndex = 2
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0, 6)
		fc.Parent = face
		face.Parent = body

		local flash = Instance.new("Frame")
		flash.Name = "Flash"
		flash.Position = face.Position
		flash.BackgroundColor3 = Color3.new(1, 1, 1)
		flash.BackgroundTransparency = 1
		flash.BorderSizePixel = 0
		flash.ZIndex = 3
		local flc = Instance.new("UICorner")
		flc.CornerRadius = UDim.new(0, 6)
		flc.Parent = flash
		flash.Parent = body

		-- the coins it pays, under the picture
		local strip = Instance.new("Frame")
		strip.Name = "Pay"
		strip.BackgroundTransparency = 1
		strip.ZIndex = 2
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 3)
		list.Parent = strip
		local coin = Instance.new("ImageLabel")
		coin.Name = "Coin"
		coin.Image = Coins.Icon
		coin.BackgroundTransparency = 1
		coin.LayoutOrder = 1
		coin.ZIndex = 2
		coin.Parent = strip
		local pay = Instance.new("TextLabel")
		pay.Name = "Amount"
		pay.BackgroundTransparency = 1
		pay.AutomaticSize = Enum.AutomaticSize.X
		pay.Size = UDim2.fromScale(0, 1)
		pay.FontFace = HEAVY
		pay.TextColor3 = INK
		pay.LayoutOrder = 2
		pay.ZIndex = 2
		pay.Parent = strip
		strip.Parent = body

		-- the key that presses it on a keyboard, in the picture's corner
		local key = Instance.new("TextLabel")
		key.Name = "Key"
		key.Text = tostring(index)
		key.FontFace = BOLD
		key.TextColor3 = INK
		key.BackgroundColor3 = Color3.new(0, 0, 0)
		key.BackgroundTransparency = 0.35
		key.Position = UDim2.fromOffset(6, 6)
		key.ZIndex = 4
		key.Visible = false
		local kc = Instance.new("UICorner")
		kc.CornerRadius = UDim.new(0, 4)
		kc.Parent = key
		key.Parent = body

		body.Parent = slot
		return {
			index = index,
			slot = slot,
			body = body,
			scale = scale,
			glow = glow,
			stroke = stroke,
			face = face,
			flash = flash,
			strip = strip,
			coin = coin,
			pay = pay,
			key = key,
			name = nil,
			light = Color3.new(1, 1, 1),
			lit = 0,
			x = 0,
			shown = false,
			sunk = false,
			breathe = nil,
		}
	end

	-- A card's light, 0 (unlit) to 1 (yours, or the winner), eased.
	local function light(card: Card, level: number)
		if math.abs(card.lit - level) < 1e-3 then
			return
		end
		card.lit = level
		tween(card.glow, LIGHT, { GroupTransparency = 1 - level })
		tween(card.stroke, LIGHT, {
			Color = if level >= 1 then card.light else RIM,
			Thickness = if level >= 1 then 3 else 2,
		})
		tween(card.face, LIGHT, { ImageColor3 = if level >= 1 then Color3.new(1, 1, 1) else DIM })
	end

	local function dip(card: Card)
		local down = tween(card.scale, DIP_DOWN, { Scale = DIP })
		down.Completed:Once(function()
			tween(card.scale, DIP_UP, { Scale = 1 })
		end)
	end

	-- The presses as this screen shows them: the car's, with my own press laid over it until
	-- the car agrees or `PREDICT` runs out.
	local function shownPresses(s: Session): { [number]: string }
		local mine = s.mine
		if not mine then
			return s.presses
		end
		if s.presses[player.UserId] == mine or os.clock() - s.minedAt > PREDICT then
			s.mine = nil
			return s.presses
		end
		local presses = table.clone(s.presses)
		presses[player.UserId] = mine
		return presses
	end

	-- Every rider's head onto the card they pressed: new ones drop on, a change of mind carries
	-- the head across, a press gone lifts it off. Each card lights for who's on it.
	local function drawHeads(s: Session, quiet: boolean?)
		local on = Cards.heads(shownPresses(s), s.offered, player.UserId)
		local still: { [number]: boolean } = {}
		for _, card in cards do
			local name = card.name
			local list = if name then on[name] else nil
			if not list then
				continue
			end
			for i, id in list do
				still[id] = true
				local at = headAt(i, #list)
				local head = heads[id]
				if head and head.card == card then
					tween(head.image, HEAD_MOVE, { Position = at })
				elseif head then
					-- carried across from the card it was on, from where it is now
					local centre = head.image.AbsolutePosition + head.image.AbsoluteSize / 2
					local from = centre - card.slot.AbsolutePosition
					head.image.Parent = card.slot
					head.image.Position = UDim2.fromOffset(from.X, from.Y)
					head.card = card
					tween(head.image, HEAD_MOVE, { Position = at })
				else
					local image = Instance.new("ImageLabel")
					image.Name = `Head{id}`
					image.AnchorPoint = Vector2.new(0.5, 0.5)
					image.Size = UDim2.fromOffset(layout.head, layout.head)
					image.Position = at - UDim2.fromOffset(0, HEAD_FROM)
					image.Image = `rbxthumb://type=AvatarHeadShot&id={math.abs(id)}&w=48&h=48`
					image.BackgroundColor3 = Color3.fromRGB(60, 58, 56)
					image.ImageTransparency = 1
					image.BackgroundTransparency = 1
					image.ZIndex = 6
					local c = Instance.new("UICorner")
					c.CornerRadius = UDim.new(0.5, 0)
					c.Parent = image
					local ring = Instance.new("UIStroke")
					ring.Thickness = if id == player.UserId then 2.5 else 2
					ring.Color = if id == player.UserId then MY_RING else THEIR_RING
					ring.Transparency = 1
					ring.Parent = image
					image.Parent = card.slot
					heads[id] = { image = image, ring = ring, card = card }
					tween(image, HEAD_DROP, { Position = at })
					tween(image, LIGHT, { ImageTransparency = 0, BackgroundTransparency = 0 })
					tween(ring, LIGHT, { Transparency = 0 })
					if id ~= player.UserId and not quiet then
						play(FRIEND)
					end
				end
			end
			if not s.picked then
				local mineHere = list[1] == player.UserId
				light(card, if mineHere then 1 elseif #list > 0 then FRIENDS_LIT else 0)
			end
		end
		for id, head in heads do
			if not still[id] then
				heads[id] = nil
				local image = head.image
				tween(image, HEAD_GONE, {
					Position = image.Position - UDim2.fromOffset(0, HEAD_FROM * 0.6),
					ImageTransparency = 1,
					BackgroundTransparency = 1,
				})
				tween(head.ring, HEAD_GONE, { Transparency = 1 })
				task.delay(HEAD_GONE.Time + 0.05, function()
					image:Destroy()
				end)
			end
		end
	end

	local function clearHeads()
		for _, head in heads do
			head.image:Destroy()
		end
		table.clear(heads)
	end

	-- The tool wheel down while the cards are up; the mouse free and the keys taken for the vote.
	local function stow(on: boolean)
		if stowed ~= on then
			stowed = on
			player:SetAttribute(Tools.CardsStowAttribute, if on then true else nil)
		end
	end

	local press: (index: number) -> ()

	local function bind(on: boolean)
		if bound == on then
			return
		end
		bound = on
		if on then
			ContextActionService:BindActionAtPriority(
				ACTION,
				function(_: string, state: Enum.UserInputState, input: InputObject)
					if state == Enum.UserInputState.Begin then
						local i = KEYS[input.KeyCode]
						if i then
							press(i)
						end
					end
					return Enum.ContextActionResult.Sink
				end,
				false,
				Enum.ContextActionPriority.High.Value,
				Enum.KeyCode.One,
				Enum.KeyCode.Two,
				Enum.KeyCode.Three,
				Enum.KeyCode.DPadLeft,
				Enum.KeyCode.DPadUp,
				Enum.KeyCode.DPadRight
			)
		else
			ContextActionService:UnbindAction(ACTION)
		end
		local caps = on and keyboard()
		for _, card in cards do
			card.key.Visible = caps
		end
	end

	local function free(on: boolean)
		if freed ~= on then
			freed = on
			need(ACTION, on)
		end
	end

	-- Your press: the card clunks and dips, lights, and your head drops onto it; the server
	-- hears it. The same card again only dips; nothing after the knock.
	press = function(index: number)
		local s = session
		local card = cards[index]
		if not (s and card and card.name and s.phase == "voting" and card.shown) then
			return
		end
		local now = shownPresses(s)[player.UserId]
		if now == card.name then
			dip(card)
			play(CLICK, 1.2)
			return
		end
		local r = getRemote()
		if not r then
			return
		end
		r:FireServer(card.name)
		s.mine, s.minedAt = card.name, os.clock()
		dip(card)
		play(CLUNK)
		play(CLICK)
		drawHeads(s)
	end

	-- Slides a card up to its place, or down under the screen.
	local function slide(card: Card, up: boolean, info: TweenInfo)
		tween(card.slot, info, { Position = restAt(card, up) })
	end

	-- The three come up with the lurch, left to right, each with a tick.
	local function deal(s: Session)
		play(SLIDE)
		for i, card in cards do
			local name = s.offered[i]
			local version = if name then NextFloor.find(name) else nil
			card.name = name
			card.sunk = false
			card.x = layout.xs[i]
			card.slot.Visible = version ~= nil
			if not version then
				card.shown = false
				continue
			end
			card.face.Image = version.face
			local c = version.light
			card.light = Color3.new(c[1], c[2], c[3])
			card.glow.GroupColor3 = card.light
			card.pay.Text = `+{NextFloor.payOf(version, s.to)}`
			card.pay.TextTransparency = 0
			card.coin.ImageTransparency = 0
			card.lit = 0
			card.glow.GroupTransparency = 1
			card.stroke.Color = RIM
			card.stroke.Thickness = 2
			card.face.ImageColor3 = DIM
			card.flash.BackgroundTransparency = 1
			card.scale.Scale = 1
			card.shown = true
			card.slot.Position = restAt(card, false)
			if not tucked then
				task.delay((i - 1) * DEAL_STAGGER, function()
					if session == s and card.shown and not tucked then
						slide(card, true, SLIDE_IN)
						play(DEAL, DEAL.pitch + (i - 1) * DEAL_RISE)
					end
				end)
			end
		end
		drawHeads(s, true)
	end

	-- The knock: the losers go dark and sink away after a beat; the winner flares, glides to the
	-- middle and breathes its light until the gate opens.
	local function pick(s: Session)
		local winner = s.picked
		play(THUNK)
		play(WIN)
		for _, card in cards do
			if not card.shown or not card.name then
				continue
			end
			if card.name == winner then
				card.lit = 1
				tween(card.glow, LIGHT, { GroupTransparency = 0 })
				tween(card.stroke, LIGHT, { Color = card.light, Thickness = 3 })
				tween(card.face, LIGHT, { ImageColor3 = Color3.new(1, 1, 1) })
				card.flash.BackgroundTransparency = FLARE
				tween(card.flash, FLARE_FADE, { BackgroundTransparency = 1 })
				local out = tween(card.scale, PUNCH_OUT, { Scale = PUNCH })
				out.Completed:Once(function()
					tween(card.scale, PUNCH_BACK, { Scale = 1 })
				end)
				task.delay(SINK_AFTER + 0.1, function()
					if session ~= s or not card.shown then
						return
					end
					card.x = 0
					if not tucked then
						tween(card.slot, CENTRE, { Position = restAt(card, true) })
					end
					card.breathe = tween(card.glow, BREATHE, { GroupTransparency = BREATHE_LOW })
				end)
			else
				card.lit = 0
				tween(card.glow, GO_DARK, { GroupTransparency = 1 })
				tween(card.stroke, GO_DARK, { Color = THEIR_RING, Thickness = 2 })
				tween(card.face, GO_DARK, { ImageColor3 = DARK })
				tween(card.pay, GO_DARK, { TextTransparency = 0.6 })
				tween(card.coin, GO_DARK, { ImageTransparency = 0.6 })
				task.delay(SINK_AFTER, function()
					if session ~= s or not card.shown then
						return
					end
					card.sunk = true
					if not tucked then
						slide(card, false, SINK)
					end
				end)
			end
		end
	end

	local function stopStepping()
		local c = stepping
		if c then
			c:Disconnect()
			stepping = nil
		end
	end

	-- Where the gate of the car carrying ride `at` opens, in the world: a little past its opening,
	-- into the floor (nil if no such car is here).
	local function gateOf(at: number): Vector3?
		local camera = Workspace.CurrentCamera
		local best: Vector3? = nil
		local bestAway = math.huge
		for model in watched do
			local a = Ride.decode(model:GetAttribute(Ride.Attribute))
			if not (a and math.abs(a - at) < 1e-3) then
				continue
			end
			local colliders = model:FindFirstChild("Colliders")
			local left = colliders and colliders:FindFirstChild("PostLeft")
			local right = colliders and colliders:FindFirstChild("PostRight")
			local back = colliders and colliders:FindFirstChild("CarBack")
			if
				not (
					left
					and right
					and back
					and left:IsA("BasePart")
					and right:IsA("BasePart")
					and back:IsA("BasePart")
				)
			then
				continue
			end
			local opening = left.Position:Lerp(right.Position, 0.5)
			local out = (opening - back.Position) * Vector3.new(1, 0, 1)
			if out.Magnitude < 1e-3 then
				continue
			end
			local spot = opening + out.Unit * INTO
			local away = if camera then (camera.CFrame.Position - spot).Magnitude else 0
			if away < bestAway then
				best, bestAway = spot, away
			end
		end
		return best
	end

	-- Plays a version's own sound, flat in your ears.
	local function hits(version: NextFloor.Version)
		for _, h in version.sound do
			task.delay(h.at, function()
				play({
					id = h.id,
					from = h.from,
					length = h.length,
					volume = h.volume,
					pitch = h.pitch,
				})
			end)
		end
	end

	-- The arrival (S4-03c2): `card`, the winner of `s`, flies into the gate and bursts in its light.
	local function arrive(s: Session, card: Card)
		local screen = gui
		local version = card.name and NextFloor.find(card.name)
		if not (screen and version) then
			return
		end
		local colour = card.light
		local size = screen.AbsoluteSize
		local from = card.slot.AbsolutePosition - screen.AbsolutePosition
		local w, h = card.slot.AbsoluteSize.X, card.slot.AbsoluteSize.Y
		-- where the gate is on your screen; the middle of it if you're looking away
		local spot = gateOf(s.at)
		local target = Vector2.new(size.X / 2, size.Y * 0.42)
		local camera = Workspace.CurrentCamera
		if spot and camera then
			local p = camera:WorldToViewportPoint(spot)
			local inset = GuiService:GetGuiInset()
			local q = Vector2.new(p.X, p.Y) - inset
			if p.Z > 0 and q.X > 0 and q.X < size.X and q.Y > 0 and q.Y < size.Y then
				target = q
			end
		end
		-- a copy flies, heads and all; the card itself is put away for the next ride
		local fly = card.slot:Clone()
		card.slot.Visible = false
		card.shown = false
		local b = card.breathe
		if b then
			b:Cancel()
			card.breathe = nil
		end
		fly.Name = "Arriving"
		fly.Position = UDim2.fromOffset(from.X + w / 2, from.Y + h)
		local grow = Instance.new("UIScale")
		grow.Parent = fly
		local glow = fly:FindFirstChild("Glow")
		if glow and glow:IsA("CanvasGroup") then
			glow.GroupTransparency = 0
		end
		fly.Parent = screen
		local turn = if target.X < from.X + w / 2 then -FLY_TURN else FLY_TURN
		local lift = tween(grow, LIFT, { Scale = LIFT_SIZE })
		lift.Completed:Once(function()
			tween(grow, FLY, { Scale = FLY_SIZE })
			tween(fly, FLY, {
				Position = UDim2.fromOffset(target.X, target.Y + h * FLY_SIZE / 2),
				Rotation = turn,
			})
		end)
		task.delay(LIFT.Time + FLY.Time - 0.06, function()
			hits(version)
		end)
		task.delay(LIFT.Time + FLY.Time, function()
			fly:Destroy()
			-- its light bursts where it went in: a ring, and a wash over your view
			local ring = Instance.new("Frame")
			ring.AnchorPoint = Vector2.new(0.5, 0.5)
			ring.Position = UDim2.fromOffset(target.X, target.Y)
			ring.Size = UDim2.fromOffset(8, 8)
			ring.BackgroundTransparency = 1
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0.5, 0)
			rc.Parent = ring
			local edge = Instance.new("UIStroke")
			edge.Color = colour
			edge.Thickness = 4
			edge.Parent = ring
			ring.Parent = screen
			local reach = math.floor(size.Y * RING_SIZE)
			tween(ring, RING, { Size = UDim2.fromOffset(reach, reach) })
			tween(edge, RING, { Transparency = 1, Thickness = 1 })
			local inset = GuiService:GetGuiInset()
			local wash = Instance.new("Frame")
			wash.Position = UDim2.fromOffset(0, -inset.Y)
			wash.Size = UDim2.new(1, 0, 1, inset.Y)
			wash.BackgroundColor3 = colour
			wash.BackgroundTransparency = WASH
			wash.BorderSizePixel = 0
			wash.ZIndex = 0
			wash.Parent = screen
			tween(wash, WASH_FADE, { BackgroundTransparency = 1 })
			task.delay(math.max(RING.Time, WASH_FADE.Time) + 0.05, function()
				ring:Destroy()
				wash:Destroy()
			end)
			-- and the hall beyond the gate takes its colour for a breath
			if spot then
				local bulb = Instance.new("Part")
				bulb.Name = "ArrivalLight"
				bulb.Anchored = true
				bulb.CanCollide = false
				bulb.CanQuery = false
				bulb.CanTouch = false
				bulb.CastShadow = false
				bulb.Transparency = 1
				bulb.Size = Vector3.one
				bulb.Position = spot
				local lamp = Instance.new("PointLight")
				lamp.Color = colour
				lamp.Brightness = 0
				lamp.Range = HALL_RANGE
				lamp.Shadows = false
				lamp.Parent = bulb
				bulb.Parent = Workspace
				local up = tween(lamp, HALL_UP, { Brightness = HALL_BRIGHT })
				up.Completed:Once(function()
					tween(lamp, HALL_DOWN, { Brightness = 0 })
				end)
				task.delay(HALL_UP.Time + HALL_DOWN.Time + 0.1, function()
					bulb:Destroy()
				end)
			end
		end)
	end

	-- The cards go: down under the screen, the wheel back up, the mouse and keys handed back.
	local function finish()
		local s = session
		session = nil
		stopStepping()
		bind(false)
		free(false)
		stow(false)
		if not s then
			return
		end
		for _, card in cards do
			local b = card.breathe
			if b then
				b:Cancel()
				card.breathe = nil
			end
			if card.shown and not card.sunk then
				slide(card, false, SLIDE_OUT)
			end
			card.shown = false
		end
		task.delay(SLIDE_OUT.Time + 0.05, function()
			if session == nil then
				clearHeads()
				for _, card in cards do
					card.slot.Visible = false
				end
			end
		end)
	end

	-- Whether any car carries the ride that began at `at`.
	local function carried(at: number): boolean
		for model in watched do
			local a = Ride.decode(model:GetAttribute(Ride.Attribute))
			if a and math.abs(a - at) < 1e-3 then
				return true
			end
		end
		return false
	end

	local function step()
		local s = session
		if not s then
			stopStepping()
			return
		end
		local now = os.clock()
		if now - s.lookedAt >= LOOK_EVERY then
			s.lookedAt = now
			if carried(s.at) then
				s.seen = now
			elseif now - s.seen > LOST then
				finish()
				return
			end
		end
		if s.mine and now - s.minedAt > PREDICT then
			drawHeads(s) -- the car never agreed: my head goes back where the vote has it
		end
		local phase: Cards.Phase = Cards.phase(RideClock(s.at), s.picked ~= nil)
		local was = s.phase
		if phase == was then
			return
		end
		s.phase = phase
		if phase == "gone" then
			-- the gate opens: the winner flies into the floor it picked (S4-03c2)
			if s.picked and not tucked then
				for _, card in cards do
					if card.shown and not card.sunk and card.name == s.picked then
						arrive(s, card)
					end
				end
			end
			finish()
			return
		end
		if was == "waiting" then
			stow(true)
			deal(s)
		end
		bind(phase == "voting")
		free(phase == "voting")
		if phase == "picked" then
			if was == "waiting" then
				task.delay(SLIDE_IN.Time, function()
					if session == s then
						pick(s)
					end
				end)
			else
				pick(s)
			end
		end
	end

	-- Reads the vote off the car it's on: the presses and, once the knock has gone, the winner.
	local function readVote(s: Session)
		local car = s.car
		local p = car:GetAttribute(NextFloor.PressesAttribute)
		s.presses = if type(p) == "string" then NextFloor.decodePresses(p) else {}
		local w = car:GetAttribute(NextFloor.PickedAttribute)
		if type(w) == "string" and w ~= "" and table.find(s.offered, w) and not s.picked then
			s.picked = w
		end
		if s.phase ~= "waiting" and not s.picked then
			drawHeads(s)
		end
	end

	local function check(model: Model)
		local s = session
		if s and s.car == model then
			readVote(s)
		end
		local at, _, to = Ride.decode(model:GetAttribute(Ride.Attribute))
		if not at or RideClock(at) >= Ride.opens() then
			return
		end
		if s and math.abs(s.at - at) < 1e-3 then
			return -- the same ride (on the next floor's car, after the hand-off)
		end
		local leftAt, ids = Departure.decodeAboard(model:GetAttribute(Departure.AboardAttribute))
		if not (leftAt and math.abs(leftAt - at) < 1e-3 and table.find(ids, player.UserId)) then
			return
		end
		local text = model:GetAttribute(NextFloor.OfferAttribute)
		local offered = if type(text) == "string" then NextFloor.decodeOffer(text) else {}
		if #offered == 0 then
			return
		end
		if s then
			finish()
		end
		local fresh: Session = {
			at = at,
			to = to,
			car = model,
			offered = offered,
			presses = {},
			picked = nil,
			phase = "waiting" :: Cards.Phase,
			seen = os.clock(),
			lookedAt = os.clock(),
			mine = nil,
			minedAt = 0,
		}
		session = fresh
		readVote(fresh)
		if not stepping then
			stepping = RunService.Heartbeat:Connect(step)
		end
	end

	local function watch(inst: Instance)
		if not inst:IsA("Model") or watched[inst] then
			return
		end
		local model = inst
		local function changed()
			check(model)
		end
		watched[model] = {
			model:GetAttributeChangedSignal(Ride.Attribute):Connect(changed),
			model:GetAttributeChangedSignal(Departure.AboardAttribute):Connect(changed),
			model:GetAttributeChangedSignal(NextFloor.OfferAttribute):Connect(changed),
			model:GetAttributeChangedSignal(NextFloor.PressesAttribute):Connect(changed),
			model:GetAttributeChangedSignal(NextFloor.PickedAttribute):Connect(changed),
		}
		check(model)
	end

	local function unwatch(inst: Instance)
		local conns = watched[inst :: Model]
		if not conns then
			return
		end
		watched[inst :: Model] = nil
		for _, c in conns do
			c:Disconnect()
		end
	end

	-- The machine's menu up: the cards tuck under the screen so it's never covered.
	local function tuckChanged()
		local now = player:GetAttribute(Tools.StowAttribute) == true
		if now == tucked then
			return
		end
		tucked = now
		for _, card in cards do
			if card.shown and not card.sunk then
				slide(card, not now, if now then TUCK else SLIDE_IN)
			end
		end
	end

	local system = { name = "NextFloorView" }

	function system.start(_: any, _context: Brix.Context)
		local screen = Instance.new("ScreenGui")
		screen.Name = "NextFloorCards"
		screen.ResetOnSpawn = false
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.DisplayOrder = 2 -- under the machine's menu (3) and the coins flying (5)
		for i = 1, NextFloor.Offered do
			local card = makeCard(screen, i)
			card.slot.Visible = false
			table.insert(cards, card)
			table.insert(
				connections,
				card.body.Activated:Connect(function()
					press(i)
				end)
			)
		end
		screen.Parent = player:WaitForChild("PlayerGui")
		gui = screen
		fit()
		table.insert(connections, screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
		table.insert(
			connections,
			UserInputService.LastInputTypeChanged:Connect(function()
				local caps = bound and keyboard()
				for _, card in cards do
					card.key.Visible = caps
				end
			end)
		)
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Tools.StowAttribute):Connect(tuckChanged)
		)
		tuckChanged()

		-- fetched now, so the faces are there the moment the cards come up
		local ids: { string } = { Coins.Icon }
		for _, version in NextFloor.Versions do
			table.insert(ids, version.face)
		end
		task.spawn(function()
			ContentProvider:PreloadAsync(ids)
		end)
		local sounds = { LATCH.Id, DING.Id, Buy.Click.id, Buy.Knock.id }
		for _, version in NextFloor.Versions do
			for _, h in version.sound do
				if not table.find(sounds, h.id) then
					table.insert(sounds, h.id)
				end
			end
		end
		task.spawn(SoundPrimer.prime, sounds)

		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(watch)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(unwatch)
		)
		for _, inst in CollectionService:GetTagged(Elevator.Tag) do
			watch(inst)
		end
	end

	function system.stop(_: any)
		finish()
		stopStepping()
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for model in watched do
			unwatch(model)
		end
		clearHeads()
		table.clear(cards)
		local g = gui
		if g then
			g:Destroy()
			gui = nil
		end
	end

	return system :: any -- any: the table is filled in above to the System shape
end

return NextFloorView
