--!strict
--[[
	BoxPanelView: the job box's panel on its holder's screen (S5-03c2b1, BoxPanel, D-291). The
	moment: you open the job box and, as the lid lifts, the panel rises with it, everything you own
	dealt onto it, each kind once with how many (x2); type, or tap a rarity, and it narrows at once;
	Close, a tap outside it, or walking off, and it falls away with the lid.

	It rides the lid: the server (JobBoxes) sends the box and your finds as the lid opens; the panel
	rises over the lid's own lift on the lid's own curve (eased in and out, `JobBox.Lid.Open`), and
	when the box's Lid goes to 0, for any reason, it falls on the lid's curve (gathering speed,
	`JobBox.landing`), gone as the clunk lands. Its X and a tap outside ask the server to shut the
	box (`BoxPanel.CloseRemote`): the panel goes with the lid, never before it.

	Each card is the find as your slots draw it (ToolPicture), its rim in its rarity's colour
	(Grades.Colours), its name, and x2 for two or more. Rarest first. On a computer the mouse goes
	free while it's open (FreeCursor's `need`). Nothing steps: tweens only, made as it opens.

	Taking one out (S5-03c2b2, D-293): tap a card and it lifts and glows, Take (and Shelf while a
	cubby is free) over its name. Over the panel's corner sit your three hands (your slots, as the
	wheel draws them), so you see where it goes. Take: its picture rises off the card at once and,
	when the server answers (`BoxPanel.TookRemote`), flies in an arc into the hand it went to,
	which pops as it lands with the find's own pick-up sound; until then your view holds the new
	find back (InFlight). Shelf: it flies up toward the cubby and lands with the shelf's tink. The
	card counts one fewer, and goes at none. With your hands full, Take shakes the three hands; a
	take the server refuses settles the picture back onto its card. Never a word.

	Selling one (S5-03c3a): over the panel's other top corner sits your cash, sent as the box
	opened. The picked card's Sell (its price on it) lifts its picture off the card, and when the
	server answers with your new cash it flies into your cash, which rings (the coins' chink) and
	counts up to the new total the way the results board does (Cash: fast, then slowing, a tick
	for each step, rising, landing with a swell and a jingle). The count ticks down; the last
	one's card shrinks away. A refused sale settles back onto its card.

	Four make a Gold (S5-03c3b2, D-298, Home.Gold's `Show`): a card with four or more that can be
	made Gold shows a third verb over Sell, Gold, a slow shine crossing it. Press it and the panel
	dims under a veil that swallows taps; four copies of the picture leave the card one after
	another, its count ticking down, each landing on a ring round the screen's middle with a chink
	a step higher; they swirl inward ever faster, turning gold, a glow growing between them, as
	the reveal's Legendary rattle and rising tone build to their loudest; then a white-gold flash, a
	ring of light and sparks, and the Gold pops up big at the middle, rays turning slowly behind it
	and its name under it, to the reveal's falling twinkles and the coins' jingle. It holds, then
	flies down onto its card, dealt beside the four (`BoxPanel.made`), which pops in with a chink.
	The server's answer is needed by the flash: refused, or none by then, and the four fly back
	onto their card, quietly.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Cash = require(ReplicatedStorage.Shared.Cash)
local Coins = require(ReplicatedStorage.Shared.Coins)
local FreeCursor = require(script.Parent.FreeCursor)
local Grades = require(ReplicatedStorage.Shared.Grades)
local Home = require(ReplicatedStorage.Shared.Home)
local InFlight = require(script.Parent.InFlight)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local ToolPicture = require(script.Parent.ToolPicture)
local Tools = require(ReplicatedStorage.Shared.Tools)

local BoxPanel = require(ReplicatedStorage.Shared.Home.BoxPanel)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local Boxes = require(ReplicatedStorage.Shared.Boxes)
local JobBox = Home.JobBox
local Gold = Home.Gold
local G = Gold.Show
local Carry = Tools.Carry
local me = Players.LocalPlayer

-- The box's own dusty blue (D-287), deepened: the panel reads as the box's inside, calm (D-263).
local PANEL = Color3.fromRGB(29, 40, 45)
local CARD = Color3.fromRGB(43, 57, 63)
local WELL = Color3.fromRGB(19, 27, 31)
local RIM = Color3.fromRGB(106, 138, 147)
local INK = Lobby.Ink
local DARK = Color3.fromRGB(24, 22, 20)
local GOLD = Color3.fromRGB(240, 196, 92) -- money: the Sell button's fill and your cash's figure

local RISE = TweenInfo.new(JobBox.Lid.Open, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local POP = TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SETTLE = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SPRING = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local GLOW = TweenInfo.new(0.15)
local LIFT = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FLY = TweenInfo.new(BoxPanel.Fly, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local BACK = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LAND = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local GONE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local SWELL = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local GILT = Color3.fromRGB(255, 203, 72) -- a Gold: its verb, its card's rim, the show's glow
local WHITE_GOLD = Color3.fromRGB(255, 245, 212) -- the flash, the shine crossing the Gold verb
local TINT = Color3.fromRGB(255, 212, 105) -- the four copies, gilded as they swirl
local SPREAD = TweenInfo.new(G.Spread, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local VEIL = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local rng = Random.new()

-- A card on the panel: what it shows and its parts.
type Shown = {
	card: BoxPanel.Card,
	frame: Frame,
	pop: UIScale,
	rim: UIStroke,
	picture: ViewportFrame,
	badge: TextLabel,
}
-- A take asked of the server and not yet answered: the find, the way, its card, and its picture
-- lifted off the card over everything.
type Ask = {
	key: string,
	way: BoxPanel.Way,
	shown: Shown,
	copy: ViewportFrame,
	scale: UIScale,
	done: boolean,
}
-- One of your hands over the panel's corner: its well, the find drawn in it, and its pop.
type Well = { frame: Frame, picture: ViewportFrame, rim: UIStroke, pop: UIScale, key: string }
-- A chip: its rarity (nil for All), its button, its pop.
type Chip = { grade: Grades.Grade?, button: TextButton, pop: UIScale, colour: Color3 }
-- Four of a find becoming one Gold on screen (S5-03c3b2): the find, the card the four leave and
-- what it counted, the four copies, the swirl's glow, its sounds building, everything else it
-- made, and the server's answer once it comes. `stage`: Spread, Orbit, Reveal, or Back (home).
type Show = {
	key: string,
	shown: Shown,
	count: number,
	copies: { ViewportFrame },
	core: Frame,
	veil: TextButton,
	sounds: { Sound },
	parts: { Instance },
	stage: string,
	answer: boolean?,
	target: Shown?, -- the Gold's card, once the server made it
	new: boolean, -- that card is new: it pops in as the Gold lands on it
	gone: boolean, -- the four were the card's last: it goes under the flash
	run: Tween?, -- the swirl's driver
	mine: number, -- the panel's opening it began in
}

local function colourOf(grade: Grades.Grade): Color3
	local c = Grades.Colours[grade] or Grades.Colours.Common
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- One of the coins' recordings (Coins' sounds) played on your screen: a cut of a longer file.
local function coinSound(spec: Coins.Sound, parent: Instance): Sound
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = spec.volume
	s.PlaybackSpeed = spec.pitch or 1
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
	s.Parent = parent
	return s
end

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

-- One of the reveal's recordings (Boxes' sounds) played on your screen from `from`, a second in
-- its file, to its end, then gone.
local function once(spec: Boxes.Sound, from: number, parent: Instance): Sound
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = spec.volume
	s.PlaybackSpeed = spec.pitch or 1
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(from, spec.from + spec.length)
	s.Parent = parent
	s:Play()
	task.delay((spec.from + spec.length - from) / (spec.pitch or 1) + 0.2, function()
		s:Destroy()
	end)
	return s
end

-- A piece of the show over everything: a plain frame anchored at its middle, `colour`, round
-- when `round`.
local function piece(z: number, colour: Color3, round: boolean, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BorderSizePixel = 0
	f.BackgroundColor3 = colour
	f.ZIndex = z
	if round then
		corner(f, UDim.new(0.5, 0))
	end
	f.Parent = parent
	return f
end

-- Where the show plays, the screen's middle a touch high, and the screen's height.
local function middle(): (Vector2, number)
	local camera = Workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	return Vector2.new(view.X / 2, view.Y * 0.45), view.Y
end

-- Where on the ring round the middle copy `i` of the four lands: up left, then round clockwise.
local function angleOf(i: number): number
	return -0.75 * math.pi + (i - 1) * 2 * math.pi / Gold.Need
end

local BoxPanelView = {}

function BoxPanelView.new(need: FreeCursor.Need): Brix.System
	local connections: { RBXScriptConnection } = {}
	local watching: { RBXScriptConnection } = {} -- the open box's lid and its leaving
	local gui: ScreenGui? = nil
	local box: Model? = nil -- the box the panel is open for
	local openedAt = 0
	local generation = 0 -- each open and close; a late deal from an older one does nothing
	local shown: { Shown } = {}
	local all: { BoxPanel.Card } = {} -- every card on the panel, in its order
	local chips: { Chip } = {}
	local grade: Grades.Grade? = nil
	local free = 0 -- the shelf's free spots, as the server said as the box opened
	local picked: Shown? = nil
	local asks: { Ask } = {} -- takes asked and not yet answered, oldest first
	local landing: { [number]: boolean } = {} -- a hand a find is flying into: drawn as it lands
	local wells: { Well } = {}
	local counting: Tween? = nil -- your cash counting up to a sale's new total
	local countFrom, countTotal = 0, 0 -- where that count started, and where it lands
	local countTurn, countLast = 0, -math.huge -- the tick sounds taking turns, and when one last played
	local guard = -math.huge -- until then taps on cards wait: one just left (BoxPanel.Guard)
	local show: Show? = nil -- four becoming a Gold on screen

	-- built in start
	local backdrop: TextButton
	local panel: Frame
	local search: TextBox
	local searchRim: UIStroke
	local chipRow: ScrollingFrame
	local closeButton: TextButton
	local closePop: UIScale
	local grid: ScrollingFrame
	local cells: UIGridLayout
	local message: TextLabel
	local click: Sound
	local hands: Frame
	local verbs: Frame
	local verbsPop: UIScale
	local takeButton: TextButton
	local takePop: UIScale
	local shelfButton: TextButton
	local shelfPop: UIScale
	local sellButton: TextButton
	local sellPop: UIScale
	local goldButton: TextButton
	local goldPop: UIScale
	local goldShine: Tween
	local purse: Frame -- your cash, over the panel's top right corner
	local purseText: TextLabel
	local pursePop: UIScale
	local purseValue: NumberValue
	local ticks: { Sound } = {}
	local chink: Sound
	local jingle: Sound
	local chinks: { Sound } = {} -- the four copies landing on the ring, each a step higher
	local layer: Frame

	local function play(pitch: number)
		click.PlaybackSpeed = BoxPanel.Click.pitch * pitch
		click.TimePosition = 0
		click:Play()
	end

	local function spring(scale: UIScale)
		scale.Scale = BoxPanel.Pressed
		TweenService:Create(scale, SPRING, { Scale = 1 }):Play()
	end

	local function size(): (number, number, number)
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local range = BoxPanel.HeightRange
		local width = math.floor(math.min(view.X * BoxPanel.Width, BoxPanel.WidthMax))
		local height = math.floor(math.clamp(view.Y * BoxPanel.Height, range[1], range[2]))
		return width, height, view.Y
	end

	-- Sizes everything for this screen: phone first (a Galaxy A16 is 685 by 338 points).
	local function layout()
		local width, height, screen = size()
		panel.Size = UDim2.fromOffset(width, height)
		local header = math.floor(math.clamp(height * 0.15, 30, 46))
		local pad = math.floor(header * 0.28)
		search.Position = UDim2.fromOffset(pad, pad)
		search.Size = UDim2.fromOffset(math.floor(math.min(width * 0.28, 220)), header)
		search.TextSize = math.floor(header * 0.48)
		closeButton.Size = UDim2.fromOffset(header, header)
		closeButton.Position = UDim2.new(1, -pad, 0, pad)
		closeButton.TextSize = math.floor(header * 0.5)
		local chipsAt = pad * 2 + search.Size.X.Offset
		chipRow.Position = UDim2.fromOffset(chipsAt, pad)
		chipRow.Size = UDim2.fromOffset(width - chipsAt - header - pad * 2, header)
		for _, chip in chips do
			chip.button.Size = UDim2.fromOffset(0, math.floor(header * 0.84))
			chip.button.TextSize = math.floor(header * 0.44)
		end
		local list = chipRow:FindFirstChildWhichIsA("UIListLayout")
		if list then
			list.Padding = UDim.new(0, math.floor(pad * 0.8))
		end
		local card = BoxPanel.Card
		local h = math.floor(math.clamp(screen * card.Height, card.Range[1], card.Range[2]))
		local gap = math.floor(h * card.Gap)
		cells.CellSize = UDim2.fromOffset(math.floor(h * card.Aspect), h)
		cells.CellPadding = UDim2.fromOffset(gap, gap)
		local top = header + pad * 2
		grid.Position = UDim2.fromOffset(pad, top)
		grid.Size = UDim2.fromOffset(width - pad * 2, height - top - pad)
		local gp = grid:FindFirstChildWhichIsA("UIPadding")
		if gp then
			gp.PaddingTop, gp.PaddingBottom = UDim.new(0, gap), UDim.new(0, gap)
			gp.PaddingLeft = UDim.new(0, math.floor(gap / 2))
		end
		message.TextSize = math.floor(header * 0.55)
		message.Position = UDim2.fromOffset(0, top)
		message.Size = UDim2.new(1, 0, 1, -top - pad)
		local well = math.floor(height * BoxPanel.Well)
		local wellGap = math.floor(well * 0.18)
		hands.Size = UDim2.fromOffset(well * Carry.Slots + wellGap * (Carry.Slots - 1), well)
		hands.Position = UDim2.fromOffset(pad, -wellGap)
		for i, w in wells do
			w.frame.Size = UDim2.fromOffset(well, well)
			w.frame.Position = UDim2.fromOffset((i - 1) * (well + wellGap), 0)
		end
		local tall = math.floor(well * 0.72)
		purse.Size = UDim2.fromOffset(math.floor(tall * 3.2), tall)
		purse.Position = UDim2.new(1, -pad, 0, -wellGap)
	end

	-- Takes asked and not yet answered, of find `key` (nil: any) going `way` (nil: either).
	local function pending(key: string?, way: BoxPanel.Way?): number
		local n = 0
		for _, a in asks do
			if (key == nil or a.key == key) and (way == nil or a.way == way) then
				n += 1
			end
		end
		return n
	end

	-- Draws hand `i` from your slot (unless a find is still flying into it), its rim lit while
	-- it's the hand you hold out. `landed`: a find from the panel has just arrived in it.
	local function drawWell(i: number, landed: boolean?)
		local w = wells[i]
		if not w or landing[i] then
			return
		end
		local value = me:GetAttribute(`{Tools.SlotAttribute}{i}`)
		local key = if type(value) == "string" then value else ""
		-- the server fills your slot just before it answers: an empty hand that a find asked for
		-- is filling stays empty until the picture lands in it
		if not landed and w.key == "" and key ~= "" and pending(key, BoxPanel.Ways.Hand) > 0 then
			return
		end
		if key ~= w.key then
			w.key = key
			w.picture:ClearAllChildren()
			if key ~= "" then
				ToolPicture.draw(w.picture, key)
			end
		end
		w.rim.Transparency = if me:GetAttribute(Tools.HandAttribute) == i and key ~= ""
			then 0.05
			else 0.5
	end

	local function drawWells()
		for i = 1, Carry.Slots do
			drawWell(i)
		end
	end

	-- Whether a hand is free for one more find: none holds a two-handed thing, and an empty slot
	-- is left once the finds already flying to you land.
	local function room(): boolean
		local held = me:GetAttribute(Tools.HandAttribute)
		local inHand = if type(held) == "number"
			then me:GetAttribute(`{Tools.SlotAttribute}{held}`)
			else nil
		local row = if type(inHand) == "string" then (Tools.Catalog :: any)[inHand] else nil -- any: keyed by text
		if row and row.bothHands and me:GetAttribute(Tools.PocketedAttribute) ~= true then
			return false
		end
		local empty = 0
		for i = 1, Carry.Slots do
			local key = me:GetAttribute(`{Tools.SlotAttribute}{i}`)
			if key == nil or key == "" then
				empty += 1
			end
		end
		return empty - pending(nil, BoxPanel.Ways.Hand) > 0
	end

	-- Your hands full: the three wells shake, as a head does.
	local function shake()
		hands.Position += UDim2.fromOffset(8, 0)
		local back = hands.Position - UDim2.fromOffset(8, 0)
		TweenService:Create(
			hands,
			TweenInfo.new(BoxPanel.Shake, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{ Position = back }
		):Play()
	end

	local function paintVerbs()
		local gold = picked ~= nil and picked.card.gold == true -- a Gold only sells, for now
		local both = not gold and free - pending(nil, BoxPanel.Ways.Shelf) > 0
		local offer = false
		if picked then
			local card = picked.card
			local row = (Tools.Catalog :: any)[card.key] -- any: keyed by text
			offer = BoxPanel.offers(card, row) and card.count - pending(card.key, nil) >= Gold.Need
		end
		takeButton.Visible = not gold
		shelfButton.Visible = both
		goldButton.Visible = offer
		-- two rows over the card's name (Sell; Take and Shelf), or three with Gold on top
		local row = if offer then 0.3 else 0.47
		local step = if offer then 0.35 else 0.53
		verbs.Position = UDim2.fromScale(0.05, if offer then 0.22 else 0.5)
		verbs.Size = UDim2.fromScale(0.9, if offer then 0.73 else 0.45)
		sellButton.Position = UDim2.fromScale(0, if offer then step else 0)
		sellButton.Size = UDim2.fromScale(1, row)
		local low = if offer then step * 2 else step
		takeButton.Position = UDim2.fromScale(0, low)
		takeButton.Size = if both then UDim2.new(0.5, -2, row, 0) else UDim2.fromScale(1, row)
		shelfButton.Position = UDim2.fromScale(1, low)
		shelfButton.Size = UDim2.new(0.5, -2, row, 0)
		goldButton.Size = UDim2.fromScale(1, row)
		if offer and goldShine.PlaybackState ~= Enum.PlaybackState.Playing then
			goldShine:Play()
		elseif not offer and goldShine.PlaybackState == Enum.PlaybackState.Playing then
			goldShine:Pause()
		end
	end

	-- Your cash counts up from what it shows to `total`, as the results board's does: fast, then
	-- slowing, a tick each step rising as it goes, landing with a swell and a jingle.
	local function countTo(total: number)
		local run = counting
		if run then
			run:Cancel()
		end
		local from = purseValue.Value
		if total <= from then
			counting = nil
			purseValue.Value = total
			purseText.Text = Cash.text(total)
			return
		end
		countFrom, countTotal = from, total
		local tween = TweenService:Create(
			purseValue,
			TweenInfo.new(
				Cash.countFor(total - from),
				Enum.EasingStyle.Cubic,
				Enum.EasingDirection.Out
			),
			{ Value = total }
		)
		counting = tween
		tween.Completed:Connect(function(state: Enum.PlaybackState)
			if state ~= Enum.PlaybackState.Completed or counting ~= tween then
				return
			end
			counting = nil
			purseText.Text = Cash.text(total)
			pursePop.Scale = Cash.Pop
			TweenService:Create(pursePop, SWELL, { Scale = 1 }):Play()
			jingle:Play()
		end)
		tween:Play()
	end

	-- The picked card set down again, its verbs gone.
	local function unpick()
		local s = picked
		picked = nil
		verbs.Visible = false
		verbs.Parent = panel
		if goldShine and goldShine.PlaybackState == Enum.PlaybackState.Playing then
			goldShine:Pause()
		end
		if s then
			TweenService:Create(s.pop, SETTLE, { Scale = 1 }):Play()
			TweenService:Create(s.rim, GLOW, { Thickness = 1.5, Transparency = 0.25 }):Play()
		end
	end

	-- A card tapped: it lifts and glows, its verbs over its name. Tapped again, it settles.
	local function pick(s: Shown)
		local now = os.clock()
		if now < guard then
			guard = now + BoxPanel.Guard -- still mashing: wait until the thumb rests
			return -- a card just left: this one slid under a thumb still tapping
		end
		if picked == s then
			unpick()
			play(0.9)
			return
		end
		unpick()
		picked = s
		TweenService:Create(s.pop, LIFT, { Scale = BoxPanel.Lift }):Play()
		TweenService:Create(s.rim, GLOW, { Thickness = BoxPanel.Glow, Transparency = 0 }):Play()
		paintVerbs()
		local row = (Tools.Catalog :: any)[s.card.base or s.card.key] -- any: keyed by text
		local price = BoxPanel.price(row or {}, s.card.gold)
		sellButton.Text = `{BoxPanel.Words.sell} {Cash.text(price)}`
		verbs.Parent = s.frame
		verbs.Visible = true
		verbsPop.Scale = 0.6
		TweenService:Create(verbsPop, POP, { Scale = 1 }):Play()
		play(1.1)
	end

	local function paintChips()
		for _, chip in chips do
			local on = chip.grade == grade
			local b = chip.button
			b.BackgroundColor3 = if on then chip.colour else WELL
			b.BackgroundTransparency = if on then 0 else 0.15
			b.TextColor3 = if on then DARK else chip.colour
			local rim = b:FindFirstChildWhichIsA("UIStroke")
			if rim then
				rim.Transparency = if on then 1 else 0.45
			end
		end
	end

	-- Shows the cards the search and the chip leave, re-dealt quickly so the change reads.
	local function narrow(ripple: boolean)
		if ripple then
			unpick()
		end
		local keep = BoxPanel.shown(all, search.Text, grade)
		local wanted: { [BoxPanel.Card]: true } = {}
		for _, card in keep do
			wanted[card] = true
		end
		local n = 0
		for _, s in shown do
			local on = wanted[s.card] == true
			s.frame.Visible = on
			if on and ripple then
				n += 1
				s.pop.Scale = 0.86
				local tween = TweenService:Create(s.pop, SETTLE, { Scale = 1 })
				task.delay(math.min(n, 24) * BoxPanel.Ripple, function()
					tween:Play()
				end)
			end
		end
		grid.CanvasPosition = Vector2.zero
		message.Visible = #keep == 0
		message.Text = if #shown == 0 then BoxPanel.Words.empty else BoxPanel.Words.none
	end

	local function makeCard(card: BoxPanel.Card, order: number): Shown
		local colour = if card.gold then GILT else colourOf(card.grade)
		local frame = Instance.new("Frame")
		frame.Name = card.key
		frame.LayoutOrder = order
		frame.BackgroundColor3 = CARD
		frame.BorderSizePixel = 0
		corner(frame, UDim.new(0.1, 0))
		local rim = Instance.new("UIStroke")
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Color = colour
		rim.Thickness = 1.5
		rim.Transparency = 0.25
		rim.Parent = frame
		local tint = Instance.new("UIGradient") -- its rarity's colour rising faintly from the foot
		tint.Rotation = 90
		tint.Color = ColorSequence.new(CARD, CARD:Lerp(colour, 0.22))
		tint.Parent = frame
		local pop = Instance.new("UIScale")
		pop.Scale = 0
		pop.Parent = frame

		local picture = Instance.new("ViewportFrame")
		picture.Name = "Picture"
		picture.BackgroundTransparency = 1
		picture.Position = UDim2.fromScale(0.06, 0.04)
		picture.Size = UDim2.fromScale(0.88, 0.7)
		picture.Ambient = Color3.fromRGB(150, 145, 140)
		picture.LightColor = Color3.fromRGB(255, 240, 220)
		picture.LightDirection = Vector3.new(-0.4, -1, -0.6)
		picture.Parent = frame
		ToolPicture.draw(picture, card.key)

		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromScale(0.06, 0.76)
		name.Size = UDim2.fromScale(0.88, 0.17)
		name.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		name.TextScaled = true
		name.TextColor3 = INK
		name.Text = card.name
		name.Parent = frame
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 17
		cap.MinTextSize = 8
		cap.Parent = name

		local b = Instance.new("TextLabel")
		b.Name = "Count"
		b.AnchorPoint = Vector2.new(1, 0)
		b.Position = UDim2.fromScale(0.95, 0.04)
		b.Size = UDim2.fromScale(0.36, 0.16)
		b.BackgroundColor3 = INK
		b.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
		b.TextScaled = true
		b.TextColor3 = DARK
		b.Text = BoxPanel.badge(card.count)
		b.Visible = b.Text ~= ""
		b.Parent = frame
		corner(b, UDim.new(0.5, 0))
		local bp = Instance.new("UIPadding")
		bp.PaddingTop, bp.PaddingBottom = UDim.new(0.12, 0), UDim.new(0.12, 0)
		bp.Parent = b

		-- the whole card is what you tap to pick it
		local hit = Instance.new("TextButton")
		hit.Name = "Pick"
		hit.AutoButtonColor = false
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.Size = UDim2.fromScale(1, 1)
		hit.ZIndex = 2
		hit.Parent = frame
		frame.Parent = grid
		local made: Shown =
			{ card = card, frame = frame, pop = pop, rim = rim, picture = picture, badge = b }
		table.insert(
			watching,
			hit.Activated:Connect(function()
				pick(made)
			end)
		)
		return made
	end

	local function makeChip(chipGrade: Grades.Grade?, order: number): Chip
		local colour = if chipGrade then colourOf(chipGrade) else INK
		local b = Instance.new("TextButton")
		b.Name = chipGrade or "All"
		b.LayoutOrder = order
		b.AutomaticSize = Enum.AutomaticSize.X
		b.AutoButtonColor = false
		b.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		b.Text = if chipGrade then chipGrade else BoxPanel.Words.all
		b.Parent = chipRow
		corner(b, UDim.new(0.5, 0))
		local p = Instance.new("UIPadding")
		p.PaddingLeft, p.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
		p.Parent = b
		local rim = Instance.new("UIStroke")
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Color = colour
		rim.Parent = b
		local pop = Instance.new("UIScale")
		pop.Parent = b
		local chip: Chip = { grade = chipGrade, button = b, pop = pop, colour = colour }
		table.insert(
			watching,
			b.Activated:Connect(function()
				-- the lit chip again goes back to All
				grade = if grade == chipGrade then nil else chipGrade
				spring(pop)
				play(if grade then 1 else 0.9)
				paintChips()
				narrow(true)
			end)
		)
		return chip
	end

	-- The Gold's show stops where it is, everything it made gone: done, or the panel closing.
	local function endShow()
		local s = show
		if not s then
			return
		end
		show = nil
		local run = s.run
		if run then
			run:Cancel()
		end
		for _, c in s.copies do
			c:Destroy()
		end
		for _, sound in s.sounds do
			sound:Stop()
		end
		for _, p in s.parts do
			p:Destroy()
		end
		s.core:Destroy()
		s.veil:Destroy()
	end

	local function clear()
		endShow()
		unpick()
		for _, c in watching do
			c:Disconnect()
		end
		table.clear(watching)
		for _, s in shown do
			s.frame:Destroy()
		end
		table.clear(shown)
		table.clear(all)
		for _, chip in chips do
			chip.button:Destroy()
		end
		table.clear(chips)
	end

	-- Falls away with the lid: on the lid's curve, as far as the lid has risen.
	local function close()
		local was = box
		if not was then
			return
		end
		box = nil
		generation += 1
		local mine = generation
		endShow()
		need("BoxPanel", false)
		search:ReleaseFocus()
		local up = JobBox.angle(true, 0, os.clock() - openedAt)
		local fall = math.max(JobBox.landing(up), 0.12)
		local _, height = size()
		local drop = TweenInfo.new(fall, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(panel, drop, { Position = UDim2.new(0.5, 0, 1, height + 12) }):Play()
		TweenService:Create(backdrop, drop, { BackgroundTransparency = 1 }):Play()
		task.delay(fall, function()
			if generation == mine then
				panel.Visible = false
				backdrop.Visible = false
				clear()
			end
		end)
	end

	-- The server opened `model` for us with `finds` in it and `spots` free on the shelf: rise with
	-- its lid.
	local function openFor(model: Model, finds: { [string]: number }, spots: number, cash: number)
		if box then
			close()
		end
		clear()
		box = model
		free = spots
		local run = counting
		counting = nil
		if run then
			run:Cancel()
		end
		purseValue.Value = cash
		purseText.Text = Cash.text(cash)
		pursePop.Scale = 1
		for i = 1, Carry.Slots do
			drawWell(i)
		end
		openedAt = os.clock()
		generation += 1
		local mine = generation
		grade = nil
		search.Text = ""
		all = BoxPanel.cards(finds, Tools.Catalog :: any) -- any: its rows carry more than Row
		for i, card in all do
			table.insert(shown, makeCard(card, i))
		end
		table.insert(chips, makeChip(nil, 0))
		for i, g in BoxPanel.grades(all) do
			table.insert(chips, makeChip(g :: Grades.Grade, i)) -- the frozen module widens it to string
		end
		paintChips()
		layout()
		narrow(false)
		table.insert(
			watching,
			model:GetAttributeChangedSignal(JobBox.LidAttribute):Connect(function()
				local lid = model:GetAttribute(JobBox.LidAttribute)
				if not (type(lid) == "number" and lid > 0) and box == model then
					close()
				end
			end)
		)
		table.insert(
			watching,
			model.AncestryChanged:Connect(function()
				if not model:IsDescendantOf(Workspace) and box == model then
					close()
				end
			end)
		)
		need("BoxPanel", true)
		local _, height = size()
		panel.Position = UDim2.new(0.5, 0, 1, height + 12)
		panel.Visible = true
		backdrop.BackgroundTransparency = 1
		backdrop.Visible = true
		TweenService:Create(panel, RISE, { Position = UDim2.new(0.5, 0, 1, -8) }):Play()
		TweenService:Create(backdrop, RISE, { BackgroundTransparency = BoxPanel.Dim }):Play()
		-- dealt as it rises, left to right, the whole deal never longer than DealMost
		local every = math.min(BoxPanel.DealEvery, BoxPanel.DealMost / math.max(#shown, 1))
		for i, s in shown do
			task.delay(JobBox.Lid.Open * BoxPanel.DealFrom + (i - 1) * every, function()
				if generation == mine then
					TweenService:Create(s.pop, POP, { Scale = 1 }):Play()
				end
			end)
		end
	end

	-- Card `s`, its last one gone, shrinks away; the cards after it settle into their places.
	local function drop(s: Shown)
		local i = table.find(shown, s)
		if i then
			table.remove(shown, i)
		end
		guard = os.clock() + BoxPanel.Guard
		if picked == s then
			unpick()
		end
		local order = s.frame.LayoutOrder
		TweenService:Create(s.pop, GONE, { Scale = 0 }):Play()
		task.delay(GONE.Time, function()
			s.frame:Destroy()
			for _, after in shown do
				if after.frame.LayoutOrder > order and after.frame.Visible then
					after.pop.Scale = 0.92
					TweenService:Create(after.pop, SETTLE, { Scale = 1 }):Play()
				end
			end
			if #all == 0 and box then
				message.Text = BoxPanel.Words.empty
				message.Visible = true
			end
		end)
	end

	-- One of `key` came out: its card counts one fewer and goes, shrinking, at none.
	local function tick(key: string)
		local card = BoxPanel.took(all, key)
		if not card then
			return
		end
		for _, s in shown do
			if s.card ~= card then
				continue
			end
			if card.count >= 1 then
				s.badge.Text = BoxPanel.badge(card.count)
				s.badge.Visible = s.badge.Text ~= ""
			else
				drop(s)
			end
			break
		end
	end

	-- A take that didn't happen (refused, or no answer in time): its picture settles back onto its
	-- card, or fades if the card is gone. Quietly.
	local function settle(a: Ask)
		if a.done then
			return
		end
		a.done = true
		local i = table.find(asks, a)
		if i then
			table.remove(asks, i)
		end
		if a.way == BoxPanel.Ways.Hand then
			InFlight.land(me, "tool")
			if box then
				drawWells() -- a hand held for it shows what's really there
			end
		end
		local pic = a.shown.picture
		if pic:IsDescendantOf(panel) then
			local at = pic.AbsolutePosition + pic.AbsoluteSize / 2
			TweenService:Create(a.copy, BACK, { Position = UDim2.fromOffset(at.X, at.Y) }):Play()
			TweenService:Create(a.scale, BACK, { Scale = 1 }):Play()
		else
			TweenService:Create(a.copy, BACK, { ImageTransparency = 1 }):Play()
		end
		task.delay(BACK.Time, function()
			a.copy:Destroy()
			pic.Visible = true
		end)
		if box then
			paintVerbs()
		end
	end

	-- Flies `a`'s picture in a bow from where it is to `target()` (followed as it moves: the hands
	-- fall with the panel), shrinking to the size given; `fade` thins it out at the end. Then
	-- `arrive`.
	local function fly(a: Ask, target: () -> (Vector2, number), fade: boolean, arrive: () -> ())
		local from = Vector2.new(a.copy.Position.X.Offset, a.copy.Position.Y.Offset)
		local base = math.max(a.copy.Size.X.Offset, 1)
		local rise = a.scale.Scale
		local camera = Workspace.CurrentCamera
		local bow = (if camera then camera.ViewportSize.Y else 400) * BoxPanel.Arc
		local t = Instance.new("NumberValue")
		local step = t.Changed:Connect(function(u: number)
			local to, wide = target()
			local mid = (from + to) / 2 - Vector2.new(0, bow)
			local at = from:Lerp(mid, u):Lerp(mid:Lerp(to, u), u)
			a.copy.Position = UDim2.fromOffset(at.X, at.Y)
			a.scale.Scale = rise + (wide / base - rise) * u
			if fade then
				a.copy.ImageTransparency = math.clamp((u - 0.65) / 0.35, 0, 1)
			end
		end)
		local tween = TweenService:Create(t, FLY, { Value = 1 })
		tween.Completed:Connect(function()
			step:Disconnect()
			t:Destroy()
			a.copy:Destroy()
			arrive()
		end)
		tween:Play()
	end

	-- The server's answer to a take: `key` went `way` (or didn't), to slot or spot `at`.
	local function took(key: string, way: BoxPanel.Way, ok: boolean, at: unknown)
		local a: Ask? = nil
		for _, x in asks do
			if x.key == key and x.way == way and not x.done then
				a = x
				break
			end
		end
		if not ok then
			if a then
				settle(a)
			end
			return
		end
		if way == BoxPanel.Ways.Shelf then
			free = math.max(free - 1, 0)
		end
		tick(key)
		local total = if way == BoxPanel.Ways.Sell
				and type(at) == "number"
				and at == at
			then math.max(math.floor(at), 0)
			else nil
		if not a then
			if box then
				paintVerbs()
				drawWells()
				if total then
					countTo(total)
				end
			end
			return -- answered after the screen gave up on it: counted, nothing left to fly
		end
		local ask = a :: Ask
		ask.done = true
		local i = table.find(asks, ask)
		if i then
			table.remove(asks, i)
		end
		if box then
			paintVerbs()
		end
		local pic = ask.shown.picture
		task.delay(BoxPanel.Fly * 0.5, function()
			if ask.shown.card.count >= 1 then
				pic.Visible = true
			end
		end)
		if way == BoxPanel.Ways.Sell then
			-- into your cash, shrinking to a coin, then the ring and the count
			fly(
				ask,
				function(): (Vector2, number)
					return purse.AbsolutePosition + purse.AbsoluteSize / 2,
						purse.AbsoluteSize.Y * 0.6
				end,
				true,
				function()
					chink:Play()
					if total and box then
						pursePop.Scale = 1.12
						TweenService:Create(pursePop, SETTLE, { Scale = 1 }):Play()
						countTo(total)
					end
				end
			)
			return
		end
		local slot = if way == BoxPanel.Ways.Hand and type(at) == "number" then at else nil
		local w = if slot then wells[slot] else nil
		if way == BoxPanel.Ways.Hand then
			if not (slot and w) then
				InFlight.land(me, "tool")
				ask.copy:Destroy()
				drawWells()
				return
			end
			local well = w :: Well
			landing[slot] = true
			fly(
				ask,
				function(): (Vector2, number)
					local p = well.picture
					return p.AbsolutePosition + p.AbsoluteSize / 2, p.AbsoluteSize.X
				end,
				false,
				function()
					landing[slot] = nil
					InFlight.land(me, "tool")
					drawWell(slot, true)
					well.pop.Scale = 1.3
					TweenService:Create(well.pop, LAND, { Scale = 1 }):Play()
					local row = (Tools.Catalog :: any)[key] -- any: the catalog is keyed by text
					if row and gui then
						Tools.play(row.pickUp, gui, 50)
					end
				end
			)
			return
		end
		local spot = if typeof(at) == "Vector3" then at else nil
		local base = ask.copy.Size.X.Offset
		fly(
			ask,
			function(): (Vector2, number)
				local camera = Workspace.CurrentCamera
				local view = if camera then camera.ViewportSize else Vector2.new(800, 600)
				if not (camera and spot) then
					return Vector2.new(view.X / 2, -40), base * 0.3
				end
				local p = camera:WorldToViewportPoint(spot)
				-- behind you: up off the top of the screen, on the side it's on
				local x = if p.Z < 0 then view.X - p.X else p.X
				local y = if p.Z < 0 then -40 else p.Y
				return Vector2.new(math.clamp(x, 0, view.X), math.clamp(y, -40, view.Y)), base * 0.3
			end,
			true,
			function()
				if spot then
					local mark = Instance.new("Attachment")
					mark.Name = "ShelfTink"
					mark.WorldPosition = spot
					mark.Parent = Workspace.Terrain
					Tools.play(Shelf.Tink, mark, Shelf.Hearing)
					task.delay(2, function()
						mark:Destroy()
					end)
				end
			end
		)
	end

	-- Take or Shelf pressed on the picked card: its picture rises off the card at once and the
	-- server is asked; the answer flies it (`took`). Hands full: the hands shake, nothing asked.
	local function takeOut(way: BoxPanel.Way, pop: UIScale)
		local s = picked
		if not (s and box) then
			return
		end
		spring(pop)
		local key = s.card.key
		if s.card.count - pending(key, nil) < 1 then
			return -- every one of it is already on its way out
		end
		if way == BoxPanel.Ways.Hand and not room() then
			play(0.7)
			shake()
			return
		end
		if way == BoxPanel.Ways.Shelf and free - pending(nil, way) < 1 then
			return
		end
		local folder = ReplicatedStorage:FindFirstChild(BoxPanel.RemoteFolder)
		local remote = folder and folder:FindFirstChild(BoxPanel.TakeRemote)
		if not (remote and remote:IsA("RemoteEvent")) then
			return
		end
		play(1.25)
		local pic = s.picture
		local copy = Instance.new("ViewportFrame")
		copy.Name = "Taking"
		copy.BackgroundTransparency = 1
		copy.Ambient = pic.Ambient
		copy.LightColor = pic.LightColor
		copy.LightDirection = pic.LightDirection
		copy.AnchorPoint = Vector2.new(0.5, 0.5)
		local at = pic.AbsolutePosition + pic.AbsoluteSize / 2
		copy.Position = UDim2.fromOffset(at.X, at.Y)
		copy.Size = UDim2.fromOffset(pic.AbsoluteSize.X, pic.AbsoluteSize.Y)
		local scale = Instance.new("UIScale")
		scale.Parent = copy
		copy.Parent = layer
		ToolPicture.draw(copy, key)
		TweenService:Create(scale, LIFT, { Scale = BoxPanel.Rise }):Play()
		local a: Ask = { key = key, way = way, shown = s, copy = copy, scale = scale, done = false }
		table.insert(asks, a)
		-- the last one lifts off its card: the card's own picture goes with it
		pic.Visible = s.card.count - pending(key, nil) > 0
		if way == BoxPanel.Ways.Hand then
			InFlight.hold(me, "tool")
		else
			paintVerbs()
		end
		remote:FireServer(key, way)
		task.delay(BoxPanel.Wait, function()
			settle(a)
		end)
	end

	-- Four of `key` made one Gold (the server said so): the cards learn it (`BoxPanel.made`) and
	-- every card goes to its place. During the show (`s`) the Gold's card waits unseen for the
	-- Gold to land on it and the four's card waits for the flash; answered after the show gave up,
	-- both happen at once.
	local function applyMade(key: string, s: Show?): (Shown?, boolean, boolean)
		local card, new = BoxPanel.made(all, Tools.Catalog :: any, key) -- any: its rows carry more than Row
		if not card then
			return nil, false, false
		end
		local gone = false
		for _, sh in shown do
			if sh.card.key ~= key then
				continue
			end
			gone = table.find(all, sh.card) == nil
			if not s then
				if gone then
					drop(sh)
				else
					sh.badge.Text = BoxPanel.badge(sh.card.count)
					sh.badge.Visible = sh.badge.Text ~= ""
				end
			end
			break
		end
		local target: Shown? = nil
		if new then
			target = makeCard(card, 0)
			table.insert(shown, target :: Shown)
		else
			for _, sh in shown do
				if sh.card == card then
					target = sh
					break
				end
			end
		end
		-- every other place, so a card the four emptied keeps its own (just after its Gold's)
		-- until it goes under the flash
		local order: { [BoxPanel.Card]: number } = {}
		for i, c in all do
			order[c] = i * 2
		end
		for _, sh in shown do
			sh.frame.LayoutOrder = order[sh.card] or (order[card] or 0) + 1
		end
		local t = target
		if t then
			t.frame.Visible = BoxPanel.match(card, search.Text, grade)
			if not s then
				t.badge.Text = BoxPanel.badge(card.count)
				t.badge.Visible = t.badge.Text ~= ""
				t.pop.Scale = if new then 0 else 1.15
				TweenService:Create(t.pop, POP, { Scale = 1 }):Play()
			end
		end
		return target, new, gone
	end

	-- The ask refused, or no answer by the flash: the four fly back onto their card and it counts
	-- what it did. Quietly.
	local function goHome(s: Show)
		if show ~= s or s.stage == "Reveal" or s.stage == "Back" then
			return
		end
		s.stage = "Back"
		local run = s.run
		if run then
			run:Cancel()
		end
		for _, sound in s.sounds do
			sound:Stop()
		end
		local pic = s.shown.picture
		local home = pic.AbsolutePosition + pic.AbsoluteSize / 2
		local wide = math.min(pic.AbsoluteSize.X, pic.AbsoluteSize.Y)
		for _, c in s.copies do
			TweenService:Create(c, BACK, {
				Position = UDim2.fromOffset(home.X, home.Y),
				Size = UDim2.fromOffset(wide, wide),
				ImageColor3 = Color3.new(1, 1, 1),
			}):Play()
		end
		TweenService:Create(s.core, BACK, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(s.veil, BACK, { BackgroundTransparency = 1 }):Play()
		task.delay(BACK.Time, function()
			if show ~= s then
				return
			end
			local sh = s.shown
			if sh.frame.Parent then
				sh.picture.Visible = sh.card.count >= 1
				sh.badge.Text = BoxPanel.badge(sh.card.count)
				sh.badge.Visible = sh.badge.Text ~= ""
			end
			endShow()
			guard = os.clock() + BoxPanel.Guard
			if box then
				paintVerbs()
			end
		end)
	end

	-- The Gold, landed on its card: the card pops in (new) or swells, its rim flaring gold.
	local function landGold(s: Show)
		local t = s.target
		if t and t.frame.Parent then
			t.picture.Visible = true
			t.badge.Text = BoxPanel.badge(t.card.count)
			t.badge.Visible = t.badge.Text ~= ""
			t.pop.Scale = if s.new then 0.4 else 1.2
			TweenService:Create(t.pop, if s.new then POP else SETTLE, { Scale = 1 }):Play()
			t.rim.Thickness = BoxPanel.Glow + 1
			t.rim.Transparency = 0
			TweenService:Create(t.rim, TweenInfo.new(0.7), { Thickness = 1.5, Transparency = 0.25 })
				:Play()
		end
		local c = chinks[1]
		c.PlaybackSpeed = 0.9
		c.TimePosition = 0
		c:Play()
		guard = os.clock() + BoxPanel.Guard
		task.delay(G.Fade, function()
			if show == s then
				endShow()
			end
		end)
	end

	-- The flash: the four are gone, and the Gold pops up big at the middle, rays turning behind
	-- it, its name under it; it holds, then flies onto its card.
	local function reveal(s: Show)
		s.stage = "Reveal"
		table.clear(s.sounds) -- the build rings out under the flash
		for _, c in s.copies do
			c:Destroy()
		end
		table.clear(s.copies)
		s.core.Visible = false
		if s.gone and s.shown.frame.Parent then
			drop(s.shown) -- the four were its last: it goes under the flash
		elseif s.shown.frame.Parent then
			s.shown.badge.Text = BoxPanel.badge(s.shown.card.count)
			s.shown.badge.Visible = s.shown.badge.Text ~= ""
		end
		local at, tall = middle()
		local here = UDim2.fromOffset(at.X, at.Y)
		local set = Boxes.Reveal.Legendary
		if gui then
			once(set.burst, set.burst.from, gui)
		end
		jingle.TimePosition = 0
		jingle:Play()

		local flash = piece(9, WHITE_GOLD, false, layer)
		flash.AnchorPoint = Vector2.zero
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundTransparency = 0.05
		table.insert(s.parts, flash)
		TweenService:Create(
			flash,
			TweenInfo.new(G.Flash, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		):Play()

		local ring = piece(5, GILT, true, layer)
		ring.BackgroundTransparency = 1
		ring.Position = here
		ring.Size = UDim2.fromOffset(tall * 0.12, tall * 0.12)
		local line = Instance.new("UIStroke")
		line.Color = WHITE_GOLD
		line.Thickness = 7
		line.Parent = ring
		table.insert(s.parts, ring)
		local burst = TweenInfo.new(G.Burst, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local far = tall * G.BurstSize
		TweenService:Create(ring, burst, { Size = UDim2.fromOffset(far, far) }):Play()
		TweenService:Create(line, burst, { Thickness = 1, Transparency = 1 }):Play()

		local spark = TweenInfo.new(G.SparkTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for i = 1, G.Sparks do
			local a = (i + rng:NextNumber(-0.3, 0.3)) * 2 * math.pi / G.Sparks
			local reach = tall * G.SparkFly * rng:NextNumber(0.7, 1.2)
			local wide = math.max(math.floor(tall * 0.024), 4)
			local sp = piece(5, if i % 2 == 0 then WHITE_GOLD else GILT, false, layer)
			sp.Position = here
			sp.Rotation = 45
			sp.Size = UDim2.fromOffset(wide, wide)
			table.insert(s.parts, sp)
			TweenService
				:Create(sp, spark, {
					Position = UDim2.fromOffset(
						at.X + math.cos(a) * reach,
						at.Y + math.sin(a) * reach
					),
					Size = UDim2.fromOffset(2, 2),
					BackgroundTransparency = 1,
					Rotation = 225,
				})
				:Play()
		end

		local rays: { Frame } = {}
		local spin = TweenInfo.new(G.Spin, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
		for k = 0, 3 do
			local ray = piece(2, GILT, false, layer)
			ray.Position = here
			ray.Size = UDim2.fromOffset(tall * G.Rays, math.max(math.floor(tall * 0.05), 8))
			ray.Rotation = k * 45
			ray.BackgroundTransparency = 1
			local fade = Instance.new("UIGradient") -- bright at the middle, gone at the tips
			fade.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.15),
				NumberSequenceKeypoint.new(1, 1),
			})
			fade.Parent = ray
			table.insert(s.parts, ray)
			table.insert(rays, ray)
			TweenService:Create(ray, TweenInfo.new(G.Pop), { BackgroundTransparency = 0.35 }):Play()
			TweenService:Create(ray, spin, { Rotation = k * 45 + 360 }):Play()
		end

		local big = math.floor(tall * G.Big)
		local gold = Instance.new("ViewportFrame")
		gold.Name = "Gold"
		gold.AnchorPoint = Vector2.new(0.5, 0.5)
		gold.BackgroundTransparency = 1
		gold.Position = here
		gold.Size = UDim2.fromOffset(big, big)
		gold.Ambient = Color3.fromRGB(170, 160, 140)
		gold.LightColor = Color3.fromRGB(255, 240, 210)
		gold.LightDirection = Vector3.new(-0.4, -1, -0.6)
		gold.ZIndex = 6
		local grow = Instance.new("UIScale")
		grow.Scale = 0
		grow.Parent = gold
		gold.Parent = layer
		ToolPicture.draw(gold, Gold.key(s.key))
		TweenService:Create(
			grow,
			TweenInfo.new(G.Pop, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()

		local t = s.target
		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.AnchorPoint = Vector2.new(0.5, 0)
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromOffset(at.X, at.Y + big * 0.5)
		title.Size = UDim2.fromOffset(tall * 1.4, math.floor(tall * 0.085))
		title.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
		title.TextScaled = true
		title.TextColor3 = GILT
		title.Text = if t then t.card.name else Gold.Word
		title.ZIndex = 7
		local edge = Instance.new("UIStroke")
		edge.Color = DARK
		edge.Thickness = 2
		edge.Parent = title
		local titlePop = Instance.new("UIScale")
		titlePop.Scale = 0
		titlePop.Parent = title
		title.Parent = layer
		table.insert(s.parts, title)
		task.delay(G.Pop * 0.4, function()
			if show == s then
				TweenService:Create(titlePop, POP, { Scale = 1 }):Play()
			end
		end)

		task.delay(G.Pop + G.Hold, function()
			if show ~= s then
				gold:Destroy()
				return
			end
			local fade = TweenInfo.new(G.Fade)
			for _, ray in rays do
				TweenService:Create(ray, fade, { BackgroundTransparency = 1 }):Play()
			end
			TweenService:Create(title, fade, { TextTransparency = 1 }):Play()
			TweenService:Create(edge, fade, { Transparency = 1 }):Play()
			TweenService:Create(s.veil, fade, { BackgroundTransparency = 1 }):Play()
			local dest = s.target
			if not (dest and dest.frame.Parent and dest.frame.Visible and box) then
				-- its card is filtered out of sight: it shrinks away where it is
				TweenService:Create(grow, GONE, { Scale = 0 }):Play()
				table.insert(s.parts, gold)
				task.delay(GONE.Time, function()
					if show == s then
						landGold(s)
					end
				end)
				return
			end
			local onto = dest :: Shown
			play(1.2)
			fly(
				{
					key = Gold.key(s.key),
					way = BoxPanel.Ways.Gold,
					shown = onto,
					copy = gold,
					scale = grow,
					done = true,
				},
				function(): (Vector2, number)
					local p = onto.picture
					return p.AbsolutePosition + p.AbsoluteSize / 2,
						math.min(p.AbsoluteSize.X, p.AbsoluteSize.Y)
				end,
				false,
				function()
					if show == s then
						landGold(s)
					end
				end
			)
		end)
	end

	-- The four swirl inward round the middle, ever faster, turning gold, a glow growing between
	-- them and shivering at the end; then the flash if the server made the Gold, else home.
	local function orbit(s: Show)
		if show ~= s or s.stage ~= "Spread" then
			return
		end
		s.stage = "Orbit"
		local driver = Instance.new("NumberValue")
		table.insert(s.parts, driver)
		-- the glow: a faint wide halo with a bright heart, so it reads as light, not a disc
		local heart = piece(3, WHITE_GOLD, true, s.core)
		heart.BackgroundTransparency = 1
		heart.Position = UDim2.fromScale(0.5, 0.5)
		heart.Size = UDim2.fromScale(0.45, 0.45)
		local white = Color3.new(1, 1, 1)
		driver.Changed:Connect(function(p: number)
			local at, tall = middle()
			local r = tall * G.Ring * (1 - p) ^ 0.75
			local turn = 2 * math.pi * G.Turns * p * p
			local wide = tall * G.Copy * (1 - (1 - G.Shrink) * p)
			local shiver = if p > 0.66 then G.Jitter * (p - 0.66) / 0.34 else 0
			local tint = white:Lerp(TINT, math.min(p * 1.5, 1))
			for i, c in s.copies do
				local a = angleOf(i) + turn
				c.Position = UDim2.fromOffset(
					at.X + math.cos(a) * r + rng:NextNumber(-shiver, shiver),
					at.Y + math.sin(a) * r + rng:NextNumber(-shiver, shiver)
				)
				c.Size = UDim2.fromOffset(wide, wide)
				c.ImageColor3 = tint
			end
			local glow = tall * G.Copy * G.Glow * p
			s.core.Position = UDim2.fromOffset(at.X, at.Y)
			s.core.Size = UDim2.fromOffset(glow, glow)
			s.core.BackgroundTransparency = 1 - 0.3 * p * p
			heart.BackgroundTransparency = 1 - 0.85 * p * p * p
		end)
		local tween = TweenService:Create(
			driver,
			TweenInfo.new(G.Orbit, Enum.EasingStyle.Linear),
			{ Value = 1 }
		)
		s.run = tween
		tween.Completed:Connect(function(state: Enum.PlaybackState)
			if state ~= Enum.PlaybackState.Completed or show ~= s or s.stage ~= "Orbit" then
				return
			end
			if s.answer == true and box and s.mine == generation then
				reveal(s)
			else
				goHome(s)
			end
		end)
		tween:Play()
	end

	-- Gold pressed on the picked card (four or more of it): the server is asked and the show
	-- begins at once, the four leaving the card one after another for the ring round the middle.
	local function makeGold()
		local s = picked
		if not (s and box) or show then
			return
		end
		spring(goldPop)
		local key = s.card.key
		local row = (Tools.Catalog :: any)[key] -- any: keyed by text
		if not BoxPanel.offers(s.card, row) or s.card.count - pending(key, nil) < Gold.Need then
			return
		end
		local folder = ReplicatedStorage:FindFirstChild(BoxPanel.RemoteFolder)
		local remote = folder and folder:FindFirstChild(BoxPanel.TakeRemote)
		if not (remote and remote:IsA("RemoteEvent")) then
			return
		end
		play(1.35)
		unpick()
		remote:FireServer(key, BoxPanel.Ways.Gold)

		local veil = Instance.new("TextButton") -- dims the panel and swallows every tap on it
		veil.Name = "Veil"
		veil.AutoButtonColor = false
		veil.Text = ""
		veil.BackgroundColor3 = Color3.new(0, 0, 0)
		veil.BackgroundTransparency = 1
		veil.Size = UDim2.fromScale(1, 1)
		veil.ZIndex = 1
		veil.Parent = layer
		TweenService:Create(veil, VEIL, { BackgroundTransparency = G.Veil }):Play()
		local core = piece(3, GILT, true, layer)
		core.BackgroundTransparency = 1
		local run: Show = {
			key = key,
			shown = s,
			count = s.card.count,
			copies = {},
			core = core,
			veil = veil,
			sounds = {},
			parts = {},
			stage = "Spread",
			answer = nil,
			target = nil,
			new = false,
			gone = false,
			run = nil,
			mine = generation,
		}
		show = run

		-- the reveal's Legendary rattle and rising tone, each at its loudest as the flash comes
		local flashAt = G.Stagger * (Gold.Need - 1) + G.Spread + G.Orbit
		local set = Boxes.Reveal.Legendary
		local build: { Boxes.Sound } = {}
		for _, spec in { set.hold, set.rise } :: { Boxes.Sound? } do
			if spec then
				table.insert(build, spec)
			end
		end
		for _, spec in build do
			local k = spec.pitch or 1
			local peak = spec.peak or spec.from
			local from = math.max(spec.from, peak - flashAt * k)
			task.delay(math.max(flashAt - (peak - from) / k, 0), function()
				if show == run and run.stage ~= "Back" and gui then
					table.insert(run.sounds, once(spec, from, gui))
				end
			end)
		end

		local pic = s.picture
		local from = pic.AbsolutePosition + pic.AbsoluteSize / 2
		local start = math.min(pic.AbsoluteSize.X, pic.AbsoluteSize.Y)
		local at, tall = middle()
		local ring, wide = tall * G.Ring, tall * G.Copy
		for i = 1, Gold.Need do
			local copy = Instance.new("ViewportFrame")
			copy.Name = `Four{i}`
			copy.AnchorPoint = Vector2.new(0.5, 0.5)
			copy.BackgroundTransparency = 1
			copy.Position = UDim2.fromOffset(from.X, from.Y)
			copy.Size = UDim2.fromOffset(start, start)
			copy.Ambient = pic.Ambient
			copy.LightColor = pic.LightColor
			copy.LightDirection = pic.LightDirection
			copy.ZIndex = 4
			copy.Visible = false
			copy.Parent = layer
			ToolPicture.draw(copy, key)
			table.insert(run.copies, copy)
			task.delay((i - 1) * G.Stagger, function()
				if show ~= run or run.stage ~= "Spread" then
					return
				end
				copy.Visible = true
				local left = run.count - i
				s.badge.Text = BoxPanel.badge(left)
				s.badge.Visible = s.badge.Text ~= ""
				if left < 1 then
					pic.Visible = false
				end
				local a = angleOf(i)
				local tween = TweenService:Create(copy, SPREAD, {
					Position = UDim2.fromOffset(
						at.X + math.cos(a) * ring,
						at.Y + math.sin(a) * ring
					),
					Size = UDim2.fromOffset(wide, wide),
				})
				tween.Completed:Connect(function(state: Enum.PlaybackState)
					if state == Enum.PlaybackState.Completed and show == run then
						local c = chinks[i] or chinks[1]
						c.PlaybackSpeed = 1 + G.Chink * (i - 1)
						c.TimePosition = 0
						c:Play()
					end
				end)
				tween:Play()
			end)
		end
		task.delay(flashAt - G.Orbit, function()
			orbit(run)
		end)
	end

	-- The server's answer to Gold: the four of `key` made one (`ok`), or didn't.
	local function goldTook(key: string, ok: boolean)
		local s = show
		if
			s
			and s.key == key
			and s.answer == nil
			and (s.stage == "Spread" or s.stage == "Orbit")
		then
			s.answer = ok
			if not ok then
				goHome(s)
				return
			end
			local target, new, gone = applyMade(key, s)
			s.target, s.new, s.gone = target, new, gone
			return
		end
		if ok and box then
			applyMade(key, nil) -- answered after the show gave up: the cards catch up at once
			paintVerbs()
		end
	end

	local function askClose()
		spring(closePop)
		play(0.8)
		local folder = ReplicatedStorage:FindFirstChild(BoxPanel.RemoteFolder)
		local remote = folder and folder:FindFirstChild(BoxPanel.CloseRemote)
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer()
		end
	end

	local system = { name = "BoxPanelView" }

	function system.start(_: any)
		local g = Instance.new("ScreenGui")
		g.Name = "JobBoxPanel"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.DisplayOrder = 18
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui = g

		click = Instance.new("Sound")
		click.SoundId = BoxPanel.Click.id
		click.Volume = BoxPanel.Click.volume
		click.Parent = g

		backdrop = Instance.new("TextButton")
		backdrop.Name = "Backdrop"
		backdrop.AutoButtonColor = false
		backdrop.Text = ""
		backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
		backdrop.BackgroundTransparency = 1
		backdrop.Size = UDim2.fromScale(1, 1)
		backdrop.Visible = false
		backdrop.Parent = g

		panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.AnchorPoint = Vector2.new(0.5, 1)
		panel.BackgroundColor3 = PANEL
		panel.BackgroundTransparency = 0.03
		panel.Visible = false
		panel.Parent = g
		corner(panel, UDim.new(0, 14))
		local ps = Instance.new("UIStroke")
		ps.Color = RIM
		ps.Transparency = 0.35
		ps.Thickness = 1.5
		ps.Parent = panel

		search = Instance.new("TextBox")
		search.Name = "Search"
		search.BackgroundColor3 = WELL
		search.ClearTextOnFocus = false
		search.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		search.PlaceholderText = BoxPanel.Words.search
		search.PlaceholderColor3 = INK:Lerp(PANEL, 0.5)
		search.Text = ""
		search.TextColor3 = INK
		search.TextXAlignment = Enum.TextXAlignment.Left
		search.Parent = panel
		corner(search, UDim.new(0.5, 0))
		local sp = Instance.new("UIPadding")
		sp.PaddingLeft, sp.PaddingRight = UDim.new(0, 14), UDim.new(0, 10)
		sp.Parent = search
		searchRim = Instance.new("UIStroke")
		searchRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		searchRim.Color = RIM
		searchRim.Transparency = 0.5
		searchRim.Parent = search

		chipRow = Instance.new("ScrollingFrame")
		chipRow.Name = "Chips"
		chipRow.BackgroundTransparency = 1
		chipRow.BorderSizePixel = 0
		chipRow.ScrollingDirection = Enum.ScrollingDirection.X
		chipRow.AutomaticCanvasSize = Enum.AutomaticSize.X
		chipRow.CanvasSize = UDim2.new()
		chipRow.ScrollBarThickness = 0
		chipRow.Parent = panel
		local cl = Instance.new("UIListLayout")
		cl.FillDirection = Enum.FillDirection.Horizontal
		cl.VerticalAlignment = Enum.VerticalAlignment.Center
		cl.SortOrder = Enum.SortOrder.LayoutOrder
		cl.Parent = chipRow
		local cp = Instance.new("UIPadding") -- room for a chip's pop and its rim
		cp.PaddingLeft, cp.PaddingRight = UDim.new(0, 2), UDim.new(0, 4)
		cp.Parent = chipRow

		closeButton = Instance.new("TextButton")
		closeButton.Name = "Close"
		closeButton.AnchorPoint = Vector2.new(1, 0)
		closeButton.AutoButtonColor = false
		closeButton.BackgroundColor3 = WELL
		closeButton.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
		closeButton.Text = "X"
		closeButton.TextColor3 = INK
		closeButton.Parent = panel
		corner(closeButton, UDim.new(0.5, 0))
		closePop = Instance.new("UIScale")
		closePop.Parent = closeButton

		grid = Instance.new("ScrollingFrame")
		grid.Name = "Finds"
		grid.BackgroundTransparency = 1
		grid.BorderSizePixel = 0
		grid.ScrollingDirection = Enum.ScrollingDirection.Y
		grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
		grid.CanvasSize = UDim2.new()
		grid.ScrollBarThickness = 4
		grid.ScrollBarImageColor3 = RIM
		grid.Parent = panel
		cells = Instance.new("UIGridLayout")
		cells.SortOrder = Enum.SortOrder.LayoutOrder
		cells.HorizontalAlignment = Enum.HorizontalAlignment.Left
		cells.Parent = grid
		local gp = Instance.new("UIPadding")
		gp.Parent = grid

		message = Instance.new("TextLabel")
		message.Name = "Message"
		message.BackgroundTransparency = 1
		message.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		message.TextColor3 = INK:Lerp(PANEL, 0.45)
		message.Visible = false
		message.Parent = panel

		-- your three hands, over the panel's corner: where a find you take goes
		hands = Instance.new("Frame")
		hands.Name = "Hands"
		hands.AnchorPoint = Vector2.new(0, 1)
		hands.BackgroundTransparency = 1
		hands.Parent = panel
		for i = 1, Carry.Slots do
			local f = Instance.new("Frame")
			f.Name = `Hand{i}`
			f.BackgroundColor3 = PANEL
			f.BackgroundTransparency = 0.08
			f.Parent = hands
			corner(f, UDim.new(0.5, 0))
			local rim = Instance.new("UIStroke")
			rim.Color = INK
			rim.Thickness = 1.5
			rim.Transparency = 0.5
			rim.Parent = f
			local pop = Instance.new("UIScale")
			pop.Parent = f
			local vf = Instance.new("ViewportFrame")
			vf.Name = "Picture"
			vf.AnchorPoint = Vector2.new(0.5, 0.5)
			vf.BackgroundTransparency = 1
			vf.Position = UDim2.fromScale(0.5, 0.5)
			vf.Size = UDim2.fromScale(0.8, 0.8)
			vf.Ambient = Color3.fromRGB(150, 145, 140)
			vf.LightColor = Color3.fromRGB(255, 240, 220)
			vf.LightDirection = Vector3.new(-0.4, -1, -0.6)
			vf.Parent = f
			table.insert(wells, { frame = f, picture = vf, rim = rim, pop = pop, key = "" })
		end

		-- the picked card's verbs, over its name: Take, and Shelf while a cubby is free; Sell above
		verbs = Instance.new("Frame")
		verbs.Name = "Verbs"
		verbs.BackgroundTransparency = 1
		verbs.Position = UDim2.fromScale(0.05, 0.5)
		verbs.Size = UDim2.fromScale(0.9, 0.45)
		verbs.ZIndex = 3
		verbs.Visible = false
		verbs.Parent = panel
		verbsPop = Instance.new("UIScale")
		verbsPop.Parent = verbs
		local function verb(name: string, text: string, fill: Color3, ink: Color3): TextButton
			local b = Instance.new("TextButton")
			b.Name = name
			b.AutoButtonColor = false
			b.BackgroundColor3 = fill
			b.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
			b.Text = text
			b.TextColor3 = ink
			b.TextScaled = true
			b.Parent = verbs
			corner(b, UDim.new(0.5, 0))
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize = 18
			cap.MinTextSize = 9
			cap.Parent = b
			local bp = Instance.new("UIPadding")
			bp.PaddingTop, bp.PaddingBottom = UDim.new(0.16, 0), UDim.new(0.16, 0)
			bp.Parent = b
			return b
		end
		sellButton = verb("Sell", BoxPanel.Words.sell, GOLD, DARK)
		sellButton.Size = UDim2.fromScale(1, 0.47)
		sellPop = Instance.new("UIScale")
		sellPop.Parent = sellButton
		takeButton = verb("Take", BoxPanel.Words.take, INK, DARK)
		takeButton.Position = UDim2.fromScale(0, 0.53)
		takePop = Instance.new("UIScale")
		takePop.Parent = takeButton
		shelfButton = verb("Shelf", BoxPanel.Words.shelf, WELL, INK)
		shelfButton.AnchorPoint = Vector2.new(1, 0)
		shelfButton.Position = UDim2.fromScale(1, 0.53)
		shelfButton.Size = UDim2.new(0.5, -2, 0.47, 0)
		local shelfRim = Instance.new("UIStroke")
		shelfRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		shelfRim.Color = INK
		shelfRim.Transparency = 0.4
		shelfRim.Parent = shelfButton
		shelfPop = Instance.new("UIScale")
		shelfPop.Parent = shelfButton
		-- Gold, on top while the card holds four: gold, a slow shine crossing it now and then
		goldButton = verb("Gold", BoxPanel.Words.gold, Color3.new(1, 1, 1), DARK)
		goldButton.Visible = false
		goldPop = Instance.new("UIScale")
		goldPop.Parent = goldButton
		local goldRim = Instance.new("UIStroke")
		goldRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		goldRim.Color = WHITE_GOLD
		goldRim.Thickness = 1.5
		goldRim.Parent = goldButton
		local shine = Instance.new("UIGradient")
		shine.Rotation = 15
		shine.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, GILT),
			ColorSequenceKeypoint.new(0.4, GILT),
			ColorSequenceKeypoint.new(0.5, WHITE_GOLD),
			ColorSequenceKeypoint.new(0.6, GILT),
			ColorSequenceKeypoint.new(1, GILT),
		})
		shine.Offset = Vector2.new(-1, 0)
		shine.Parent = goldButton
		goldShine = TweenService:Create(
			shine,
			TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.9),
			{ Offset = Vector2.new(1, 0) }
		)

		-- your cash, over the panel's top right corner: where a find you sell goes
		purse = Instance.new("Frame")
		purse.Name = "Cash"
		purse.AnchorPoint = Vector2.new(1, 1)
		purse.BackgroundColor3 = PANEL
		purse.BackgroundTransparency = 0.08
		purse.Parent = panel
		corner(purse, UDim.new(0.5, 0))
		local purseRim = Instance.new("UIStroke")
		purseRim.Color = GOLD
		purseRim.Thickness = 1.5
		purseRim.Transparency = 0.35
		purseRim.Parent = purse
		pursePop = Instance.new("UIScale")
		pursePop.Parent = purse
		purseText = Instance.new("TextLabel")
		purseText.Name = "Figure"
		purseText.BackgroundTransparency = 1
		purseText.Size = UDim2.fromScale(1, 1)
		purseText.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
		purseText.TextColor3 = GOLD
		purseText.TextScaled = true
		purseText.Text = Cash.text(0)
		purseText.Parent = purse
		local pp = Instance.new("UIPadding")
		pp.PaddingTop, pp.PaddingBottom = UDim.new(0.2, 0), UDim.new(0.2, 0)
		pp.PaddingLeft, pp.PaddingRight = UDim.new(0.12, 0), UDim.new(0.12, 0)
		pp.Parent = purseText
		purseValue = Instance.new("NumberValue")
		purseValue.Name = "Counted"
		purseValue.Parent = purse
		-- two ticks taking turns, so a fast run isn't cut short each time one starts again
		ticks = { coinSound(Coins.Tick, g), coinSound(Coins.Tick, g) }
		chink = coinSound(Coins.Chink, g)
		jingle = coinSound(Coins.Jingle, g)
		for _ = 1, Gold.Need do
			table.insert(chinks, coinSound(Coins.Chink, g))
		end
		table.insert(
			connections,
			purseValue.Changed:Connect(function(v: number)
				if not counting then
					return
				end
				local n = math.floor(v + 0.5)
				local text = Cash.text(n)
				if text == purseText.Text then
					return
				end
				purseText.Text = text
				local now = os.clock()
				if now - countLast >= Cash.TickGap then
					countLast = now
					countTurn = countTurn % #ticks + 1
					local beat = ticks[countTurn]
					local span = math.max(countTotal - countFrom, 1)
					beat.PlaybackSpeed = (Coins.Tick.pitch or 1)
						+ Cash.TickRise * math.clamp((n - countFrom) / span, 0, 1)
					beat:Play()
				end
			end)
		)

		-- over everything: a find's picture flying out of the panel
		layer = Instance.new("Frame")
		layer.Name = "Flying"
		layer.BackgroundTransparency = 1
		layer.Size = UDim2.fromScale(1, 1)
		layer.ZIndex = 5
		layer.Parent = g

		table.insert(
			connections,
			search:GetPropertyChangedSignal("Text"):Connect(function()
				local cut = BoxPanel.search(search.Text)
				if cut ~= search.Text then
					search.Text = cut -- comes straight back here, cut
					return
				end
				if box then
					narrow(true)
				end
			end)
		)
		table.insert(
			connections,
			search.Focused:Connect(function()
				play(1.3)
				TweenService:Create(searchRim, GLOW, { Transparency = 0, Thickness = 2 }):Play()
			end)
		)
		table.insert(
			connections,
			search.FocusLost:Connect(function()
				TweenService:Create(searchRim, GLOW, { Transparency = 0.5, Thickness = 1 }):Play()
			end)
		)
		table.insert(connections, closeButton.Activated:Connect(askClose))
		table.insert(connections, backdrop.Activated:Connect(askClose))
		table.insert(
			connections,
			takeButton.Activated:Connect(function()
				takeOut(BoxPanel.Ways.Hand, takePop)
			end)
		)
		table.insert(
			connections,
			shelfButton.Activated:Connect(function()
				takeOut(BoxPanel.Ways.Shelf, shelfPop)
			end)
		)
		table.insert(
			connections,
			sellButton.Activated:Connect(function()
				takeOut(BoxPanel.Ways.Sell, sellPop)
			end)
		)
		table.insert(connections, goldButton.Activated:Connect(makeGold))
		-- your hands follow your slots while the panel is up
		for i = 1, Carry.Slots do
			table.insert(
				connections,
				me:GetAttributeChangedSignal(`{Tools.SlotAttribute}{i}`):Connect(function()
					if box then
						drawWell(i)
					end
				end)
			)
		end
		table.insert(
			connections,
			me:GetAttributeChangedSignal(Tools.HandAttribute):Connect(function()
				if box then
					for i = 1, Carry.Slots do
						drawWell(i)
					end
				end
			end)
		)

		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(BoxPanel.RemoteFolder, 60)
			local remote = folder and folder:WaitForChild(BoxPanel.TookRemote, 60)
			if gui == g and remote and remote:IsA("RemoteEvent") then
				table.insert(
					connections,
					-- any: a remote's arguments, checked here
					remote.OnClientEvent:Connect(function(key: any, way: any, ok: any, at: any)
						local name, to = BoxPanel.name(key), BoxPanel.way(way)
						if not (name and to and type(ok) == "boolean") then
							return
						elseif to == BoxPanel.Ways.Gold then
							goldTook(name, ok)
						else
							took(name, to :: BoxPanel.Way, ok, at) -- the frozen module widens it to string
						end
					end)
				)
			end
		end)
		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(BoxPanel.RemoteFolder, 60)
			local remote = folder and folder:WaitForChild(BoxPanel.ListRemote, 60)
			if gui == g and remote and remote:IsA("RemoteEvent") then
				table.insert(
					connections,
					-- any: a remote's arguments, checked here
					remote.OnClientEvent:Connect(
						function(model: any, finds: any, spots: any, cash: any)
							local list = BoxPanel.read(finds)
							local n = if type(spots) == "number" and spots == spots
								then math.clamp(math.floor(spots), 0, 99)
								else 0
							local money = if type(cash) == "number" and cash == cash
								then math.max(math.floor(cash), 0)
								else 0
							if typeof(model) == "Instance" and model:IsA("Model") and list then
								openFor(model, list, n, money)
							end
						end
					)
				)
			end
		end)
		local camera = Workspace.CurrentCamera
		if camera then
			table.insert(
				connections,
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					if box then
						layout()
					end
				end)
			)
		end
		g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	function system.stop(_: any)
		close()
		clear()
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		if gui then
			gui:Destroy()
			gui = nil
		end
	end

	return system
end

return BoxPanelView
