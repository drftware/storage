--!strict
--[[
	CoinView (S1-04a2): the coins on every screen, a client system. The moment it serves: the
	door goes up and there's a glint on the concrete; a tap, and the coins jump and spin and are
	gone with a chink, and on your own screen each coin flies to the little count in the corner,
	which swells and ticks up as it lands.

	The pile (tagged `Coins.Tag`, laid by the server's Coins system) is anchored, so moving its
	coins here stays on this screen. When the server stamps it taken (`Coins.TakenAttribute`),
	each coin, a beat (`Coins.Stagger`) after the one before, jumps `Coins.Lift` while it stands up
	on its edge and spins, then shrinks away; the glint throws off a few sparks and goes out; the
	chink sounds at the pile for everyone near (`Coins.Heard`), with the jingle under it for a
	handful. A pile already taken as it streams in is hidden at once.

	The count: a small coin and a number at the right end of Roblox's top bar, above the corner
	map, shown while your Player has a count (`Coins.Attribute`: only in a climb), sliding in as a
	climb begins. On the taker's screen, as each coin vanishes at the top of its jump, it flies on
	from there to the count (`Coins.Fly`), and each landing ticks the number up by one, higher
	each time (`Coins.Climb`), with a swell (`Coins.Pop`) and a spin of the count's coin. A rise
	with no flight (a pile taken off your screen) shows after `Coins.Grace`; a drop (a new climb)
	shows at once. Only what's moving is stepped.

	The pay at the gate (S1-06, `Pay`): as the gate slams with you aboard, the server tells your
	screen what you were paid, before your count changes. A beat after the slam (`Pay.Delay`) a
	handful of coins thrown on concrete sounds and coins burst out from a little above the middle of
	your view, overshooting and settling in a ring, glinting; then one after another they fly to
	your count, each landing worth its share of the pay (`Pay.split`), ticking higher and higher.
	A gold "+10" by the count says what came in, and fades once the last coin lands.

	Coins out of a marked box (B-03b): as its flaps burst (with the find, if it holds one) its
	coins jump out of it on every screen, fanning out round whatever rises between them, spinning
	up on their edges and gone, with the take's chink (and jingle for two or three) at the box. On
	the opener's screen each flies on to the count from the top of its jump and ticks it up, as a
	taken pile's do; the server put them in the count with the open, and the count waits for them.
	A box seen opened too late for its coins shows none.

	A buy at the car's machine (S1-10c2b, `Buy`): the server tells your screen of the spend before
	your count drops. One after another the coins leave the count, each ticking it down, a little
	lower each time, the count dipping; each drops out of the corner and curves into the machine's
	coin slot, shrinking and turning edge-on to go in, and clinks there (heard round the slot).
]]
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Boxes = require(ReplicatedStorage.Shared.Boxes)
local Brix = require(ReplicatedStorage.Brix)
local Coins = require(ReplicatedStorage.Shared.Coins)
local Machine = require(ReplicatedStorage.Shared.Machine)
local CoinSpecs = require(ReplicatedStorage.Shared.Coins.Specs)
local Minimap = require(ReplicatedStorage.Shared.Minimap)
local Opening = require(ReplicatedStorage.Shared.Boxes.Opening)
local Pay = require(ReplicatedStorage.Shared.Pay)
local SoundPrimer = require(script.Parent.SoundPrimer)

local me = Players.LocalPlayer

local INK = Color3.fromRGB(232, 226, 214) -- the hints' warm off-white, as every button's rim
local GOLD = Color3.fromRGB(255, 214, 120) -- the count's rim as a coin lands in it
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local GAP = 10 -- points from the top bar's free end, or the screen's edges, as the corner map
local CHIP = 0.72 -- the count's height as a share of the top bar's row
local CHIP_BARE = 34 -- points tall when there's no top bar
local FLYER = 1.5 -- a flying coin's size as it sets off, against the count's coin
local SPIN_BACK = 0.4 -- seconds the count's coin spins once as a coin lands in it
local ICON_FILL = 0.86 -- of the count's height the coin's picture fills
local ICON_EDGE = 0.08 -- the narrowest the picture gets as it flips: the coin's edge, never gone
local TICKS = 3 -- tick sounds taken in turn, so a quick run of landings never cuts one short
local TAU = 2 * math.pi
local EDGE = CFrame.Angles(math.pi / 2, 0, 0) -- a coin on its edge, face to the front (+Z)
local ICON_TURN = CFrame.Angles(0, math.rad(-22), 0) * CFrame.Angles(math.rad(8), 0, 0)
local SETTLE = TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
-- A coin paid at the machine: it shrinks to this (against the count's coin) going into the slot,
-- turning once and on to its edge (the count's coin is turned -22°: 112° more shows its edge).
local INTO_SIZE = 0.35
local INTO_TURN = TAU + math.rad(112)
local DIP = 0.88 -- the count squeezes to this as a coin leaves it, and springs back
local RIM_BACK = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PAY_CLIMB = 0.45 -- the pour's landing ticks climb this much in pitch, first to last
local PLUS_GAP = 8 -- points between the "+10" and the count
local PLUS_FADE = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

type Pile = {
	model: Model,
	coins: { BasePart },
	rest: { CFrame }, -- each coin where it lay
	edge: { CFrame }, -- each coin's turn stood on its edge (its lying yaw kept)
	sizes: { Vector3 },
	start: number?, -- when it was taken, on this screen's clock
	connection: RBXScriptConnection?, -- the server's pile: its take
	-- coins out of a marked box (B-03b): this screen's own, gone once they've vanished; each
	-- fans out by its `drift` as it jumps `lift` (else `Coins.Lift`)
	owned: boolean?,
	drift: { Vector3 }?,
	lift: number?,
}

-- A marked box's coins waiting to jump out as its flaps burst (B-03b).
type Pour = {
	box: Model,
	leave: number, -- when they jump, on this screen's clock
	rest: { CFrame }, -- each coin's start, just under the rim, lying flat
	drift: { Vector3 },
}

type Flyer = {
	launch: number, -- when it sets off for the count
	from: BasePart?, -- the coin it flies on from (nil: from the pile's middle)
	at: Vector3, -- the pile's middle, if the coin's gone
	rise: number, -- its landing tick's pitch, against `Coins.Tick.pitch`
	worth: number, -- what its landing adds to the count
	view: ViewportFrame?,
	coin: BasePart?,
	start: Vector2?,
	-- a coin of the pay (S1-06): from `born` it bursts out from `origin` to `spot` on the screen
	-- and hangs there until it sets off
	born: number?,
	origin: Vector2?,
	spot: Vector2?,
	-- a coin paid at the machine (S1-10c2b): at `launch` it leaves the count, ticking it down,
	-- and flies into the slot at `into` (world), where `clink` sounds
	into: Vector3?,
	clink: Sound?,
}

local CoinView = {}

local function ease(p: number): number
	return p * p * (3 - 2 * p)
end

-- Out past the end and back: a burst that overshoots and settles.
local function backOut(p: number): number
	local k = 1.9
	local q = p - 1
	return 1 + (k + 1) * q * q * q + k * q * q
end

local function sound(spec: Coins.Sound, parent: Instance, heard: number?): Sound
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = spec.volume
	s.PlaybackSpeed = spec.pitch or 1
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
	if heard then
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = heard
	end
	s.Parent = parent
	return s
end

-- A coin to look at in `frame`, on its edge and turned a little, filling `fill` of its height.
local function picture(frame: ViewportFrame, template: BasePart, fill: number): BasePart
	local coin = template:Clone()
	coin.CFrame = ICON_TURN * EDGE
	coin.Parent = frame
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local across = CoinSpecs.Coin.Size.X
	local away = (across / 2) / fill / math.tan(math.rad(cam.FieldOfView / 2))
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 0, away), Vector3.zero)
	cam.Parent = frame
	frame.CurrentCamera = cam
	frame.Ambient = Color3.fromRGB(190, 175, 150)
	frame.LightColor = Color3.fromRGB(255, 244, 222)
	frame.LightDirection = Vector3.new(-0.5, -0.8, -1)
	frame.BackgroundTransparency = 1
	return coin
end

function CoinView.new(): Brix.System
	local piles: { [Model]: Pile } = {}
	local moving: { Pile } = {}
	local flyers: { Flyer } = {}
	local pours: { Pour } = {}
	local boxes: { [Model]: RBXScriptConnection } = {}
	local connections: { RBXScriptConnection } = {}

	local target: number? = nil -- the count the server says
	local changedAt = 0
	local shown = 0 -- the count on screen
	local out = true -- slid off the screen
	local slideFrom, slideTo, slideAt = 1, 1, -math.huge -- 0 in place, 1 off the right edge
	local sliding = false
	local spinAt = -math.huge
	local tickTurn = 0
	local rng = Random.new()
	local plusUntil = -math.huge -- the "+10" shows until then (nil while no pour has landed)
	local pouring = 0 -- pay coins still to land

	local gui = Instance.new("ScreenGui")
	gui.Name = "CoinCount"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5 -- over the corner map, so a flying coin passes in front of it

	-- The count: a dark pill like every button of ours, the coin, the number.
	local chip = Instance.new("Frame")
	chip.Name = "Count"
	chip.AnchorPoint = Vector2.new(0.5, 0.5)
	chip.AutomaticSize = Enum.AutomaticSize.X
	chip.BackgroundColor3 = Color3.new(0, 0, 0)
	chip.BackgroundTransparency = 0.5
	chip.Visible = false
	chip.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = chip
	local rim = Instance.new("UIStroke")
	rim.Color = INK
	rim.Transparency = 0.7
	rim.Thickness = 1.5
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = chip
	local pad = Instance.new("UIPadding")
	pad.Parent = chip
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = chip
	local pop = Instance.new("UIScale")
	pop.Parent = chip

	-- the coin: a picture (Coins.Icon), not a 3D view, so it's as sharp as the number; it sits
	-- in a square of its own so its flip as a coin lands never moves the number
	local icon = Instance.new("Frame")
	icon.Name = "Coin"
	icon.LayoutOrder = 1
	icon.BackgroundTransparency = 1
	icon.Parent = chip
	local iconImage = Instance.new("ImageLabel")
	iconImage.Name = "Face"
	iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
	iconImage.Position = UDim2.fromScale(0.5, 0.5)
	iconImage.Size = UDim2.fromScale(ICON_FILL, ICON_FILL)
	iconImage.BackgroundTransparency = 1
	iconImage.Image = Coins.Icon
	iconImage.ScaleType = Enum.ScaleType.Fit
	iconImage.Parent = icon

	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.LayoutOrder = 2
	number.AutomaticSize = Enum.AutomaticSize.X
	number.BackgroundTransparency = 1
	number.FontFace = BOLD
	number.TextColor3 = INK
	number.TextXAlignment = Enum.TextXAlignment.Left
	number.Text = Coins.text(0)
	number.Parent = chip

	-- The pay's "+10", gold, just left of the count while the pour lands (S1-06).
	local plus = Instance.new("TextLabel")
	plus.Name = "Plus"
	plus.AnchorPoint = Vector2.new(1, 0.5)
	plus.AutomaticSize = Enum.AutomaticSize.X
	plus.BackgroundTransparency = 1
	plus.FontFace = BOLD
	plus.TextColor3 = GOLD
	plus.TextStrokeColor3 = Color3.new(0, 0, 0)
	plus.TextStrokeTransparency = 0.45
	plus.TextXAlignment = Enum.TextXAlignment.Right
	plus.Visible = false
	plus.Parent = gui
	local plusPop = Instance.new("UIScale")
	plusPop.Parent = plus
	local plusAt: number? = nil -- when the "+10" pops in
	local plusText = ""
	local pour = sound(Pay.Pour, gui)
	local pourAt: number? = nil -- when the pour sounds

	local ticks: { Sound } = {}
	for i = 1, TICKS do
		ticks[i] = sound(Coins.Tick, gui)
	end

	local function template(): BasePart?
		local props = ReplicatedStorage:FindFirstChild("Props")
		local found = props and props:FindFirstChild(Coins.Template)
		return if found and found:IsA("BasePart") then found else nil
	end

	local height = CHIP_BARE
	local right, middle = 0, 0

	-- The count's size and place for this screen: the right end of the top bar's free stretch.
	local function layout()
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local free = GuiService.TopbarInset
		if free.Height > 0 and free.Width > 0 then
			height = math.floor(free.Height * CHIP)
			right = free.Max.X - GAP
			middle = (free.Min.Y + free.Max.Y) / 2
		else
			-- no top bar: the top right, left of the corner map
			local side = math.clamp(view.Y * Minimap.Side, Minimap.MinSide, Minimap.MaxSide)
			height = CHIP_BARE
			right = view.X - GAP - side - GAP
			middle = GAP + height / 2
		end
		chip.Size = UDim2.fromOffset(0, height)
		icon.Size = UDim2.fromOffset(height, height)
		number.Size = UDim2.fromOffset(0, height)
		number.TextSize = math.floor(height * 0.66)
		plus.Size = UDim2.fromOffset(0, height)
		plus.TextSize = math.floor(height * 0.66)
		pad.PaddingRight = UDim.new(0, math.floor(height * 0.42))
		pad.PaddingLeft = UDim.new(0, 2)
		list.Padding = UDim.new(0, math.floor(height * 0.08))
	end

	-- Where the count sits now: its slide (0 in place, 1 off the right edge) read off the clock.
	local function place(now: number): boolean
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local width = chip.AbsoluteSize.X / math.max(pop.Scale, 0.01)
		local p = math.clamp((now - slideAt) / Coins.Show, 0, 1)
		local q = 1 - (1 - p) ^ 5 -- quint out, as the corner map slides
		local s = slideFrom + (slideTo - slideFrom) * q
		local inX = right - width / 2
		local offX = view.X + width / 2 + GAP
		chip.Position = UDim2.fromOffset(inX + (offX - inX) * s, middle)
		if p >= 1 and slideTo == 1 then
			chip.Visible = false
		end
		return p < 1
	end

	local function slide(on: boolean)
		if out == not on then
			return
		end
		out = not on
		local now = os.clock()
		local p = math.clamp((now - slideAt) / Coins.Show, 0, 1)
		local q = 1 - (1 - p) ^ 5
		slideFrom = slideFrom + (slideTo - slideFrom) * q
		slideTo = if on then 0 else 1
		slideAt = now
		if on then
			chip.Visible = true
		end
		sliding = place(now)
	end

	local function show(count: number, swell: boolean)
		shown = count
		number.Text = Coins.text(count)
		if swell then
			pop.Scale = Coins.Pop
			TweenService:Create(pop, SETTLE, { Scale = 1 }):Play()
			rim.Color = GOLD
			rim.Transparency = 0.15
			TweenService:Create(rim, RIM_BACK, { Color = INK, Transparency = 0.7 }):Play()
			spinAt = os.clock()
		end
	end

	local function counted()
		local value = me:GetAttribute(Coins.Attribute)
		local was = target
		target = if typeof(value) == "number" then value else nil
		changedAt = os.clock()
		if target and not was then
			show(target, false) -- a climb begins (or you join one): from what it says
			slide(true)
		elseif not target and was then
			slide(false)
		end
	end

	-- The pile's coins as they lie now, in order.
	local function gather(pile: Pile)
		local coins: { BasePart } = {}
		for _, part in pile.model:GetChildren() do
			if part:IsA("BasePart") then
				table.insert(coins, part)
			end
		end
		table.sort(coins, function(a: BasePart, b: BasePart): boolean
			return a.Name < b.Name
		end)
		pile.coins = coins
		table.clear(pile.rest)
		table.clear(pile.edge)
		table.clear(pile.sizes)
		for i, coin in coins do
			pile.rest[i] = coin.CFrame
			local _, yaw = coin.CFrame:ToOrientation()
			pile.edge[i] = CFrame.Angles(0, yaw, 0) * EDGE
			pile.sizes[i] = coin.Size
		end
	end

	-- A take's chink at `at`, heard by friends near, with the jingle under it for `n` of two or
	-- three: a pile taken, or a box's coins jumping out (B-03b).
	local function chink(at: Vector3, n: number)
		local spot = Instance.new("Attachment")
		spot.Name = "CoinTake"
		spot.Parent = Workspace.Terrain
		spot.WorldPosition = at
		sound(Coins.Chink, spot, Coins.Heard):Play()
		local longest = Coins.Chink.length
		if n >= 2 then
			sound(Coins.Jingle, spot, Coins.Heard):Play()
			longest = math.max(longest, Coins.Jingle.length)
		end
		task.delay(longest + 0.3, function()
			spot:Destroy()
		end)
	end

	-- The take, as everyone sees it.
	local function taken(pile: Pile)
		if pile.start then
			return
		end
		gather(pile) -- still lying where the server laid them
		local now = os.clock()
		pile.start = now
		table.insert(moving, pile)
		local at = pile.model:GetPivot().Position
		for _, coin in pile.coins do
			local glint = coin:FindFirstChild("Glint")
			if glint and glint:IsA("ParticleEmitter") then
				glint:Emit(Coins.Sparks)
				glint.Enabled = false
			end
		end
		local count = pile.model:GetAttribute(Coins.CountAttribute)
		local n = if typeof(count) == "number" then count else #pile.coins
		chink(at + Vector3.new(0, 0.3, 0), n)
		if pile.model:GetAttribute(Coins.TakenAttribute) ~= me.UserId then
			return
		end
		-- yours: each coin flies on to the count from the top of its jump
		for i = 1, n do
			table.insert(flyers, {
				launch = now + (i - 1) * Coins.Stagger + Coins.LiftTime,
				from = pile.coins[i],
				at = at,
				rise = 1 + (i - 1) * Coins.Climb,
				worth = 1,
				view = nil,
				coin = nil,
				start = nil,
			})
		end
	end

	-- Moves a taken pile's coins for this frame; true once every coin is gone.
	local function stepPile(pile: Pile, now: number): boolean
		local start = pile.start :: number
		if not pile.model.Parent then
			return true
		end
		local whole = Coins.LiftTime + Coins.Vanish
		local lift = pile.lift or Coins.Lift
		local drift = pile.drift
		local done = true
		for i, coin in pile.coins do
			local u = now - start - (i - 1) * Coins.Stagger
			if u >= whole then
				coin.Transparency = 1
				continue
			end
			done = false
			if u <= 0 then
				continue
			end
			local rest = pile.rest[i]
			local spin = CFrame.Angles(0, Coins.Spin * TAU * (u / whole), 0)
			if u < Coins.LiftTime then
				local p = u / Coins.LiftTime
				local e = 1 - (1 - p) * (1 - p)
				local turn = rest.Rotation:Lerp(pile.edge[i], e)
				local fan = if drift then drift[i] * e else Vector3.zero
				coin.CFrame = CFrame.new(rest.Position + Vector3.new(0, lift * e, 0) + fan)
					* spin
					* turn
			else
				local q = (u - Coins.LiftTime) / Coins.Vanish
				local size = math.max(1 - q * q, 0.02)
				local fan = if drift then drift[i] * (1 + 0.15 * q) else Vector3.zero
				coin.Size = pile.sizes[i] * size
				coin.CFrame = CFrame.new(rest.Position + Vector3.new(0, lift + 0.2 * q, 0) + fan)
					* spin
					* pile.edge[i]
			end
		end
		return done
	end

	-- A flying coin's picture, on the screen.
	local function frameFor(f: Flyer): ViewportFrame
		local frame = Instance.new("ViewportFrame")
		frame.Name = "Flying"
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.ZIndex = 2
		local coin = template()
		if coin then
			f.coin = picture(frame, coin, 0.8)
		end
		frame.Parent = gui
		f.view = frame
		return frame
	end

	-- A coin paid at the machine for this frame: off the count, into the slot; true once it's in.
	local function stepInto(f: Flyer, now: number, into: Vector3): boolean
		if now < f.launch then
			return false
		end
		local size = icon.AbsoluteSize.X
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		if not f.view then
			-- it leaves the count: down a tick, lower each coin, the count dipping
			f.start = icon.AbsolutePosition + icon.AbsoluteSize / 2 - gui.AbsolutePosition
			frameFor(f)
			tickTurn = tickTurn % TICKS + 1
			local tick = ticks[tickTurn]
			tick.PlaybackSpeed = (Coins.Tick.pitch or 1) * f.rise
			tick.TimePosition = Coins.Tick.from
			tick:Play()
			show(math.max(0, shown - f.worth), false)
			pop.Scale = DIP
			TweenService:Create(pop, SETTLE, { Scale = 1 }):Play()
		end
		local frame = f.view :: ViewportFrame
		local p = math.clamp((now - f.launch) / Machine.Buy.CoinFly, 0, 1)
		local t = ease(p)
		local s = f.start :: Vector2
		-- the slot where it is on your screen now; behind you, low in the middle
		local e = Vector2.new(view.X / 2, view.Y * 0.8)
		if camera then
			local point = camera:WorldToViewportPoint(into)
			if point.Z > 0 then
				e = Vector2.new(point.X, point.Y)
			end
		end
		local d = e - s
		local c = s:Lerp(e, 0.5) + Vector2.new(d.Y, -d.X) * 0.22 -- drops out of the corner first
		local point = s:Lerp(c, t):Lerp(c:Lerp(e, t), t)
		local across = size * (FLYER + (INTO_SIZE - FLYER) * t)
		frame.Position = UDim2.fromOffset(point.X, point.Y)
		frame.Size = UDim2.fromOffset(across, across)
		local coin = f.coin
		if coin then
			coin.CFrame = CFrame.Angles(0, INTO_TURN * t, 0) * ICON_TURN * EDGE
		end
		if p < 1 then
			return false
		end
		frame:Destroy()
		f.view = nil
		local clink = f.clink
		if clink then
			clink:Play()
		end
		return true
	end

	-- Moves a flying coin on your screen for this frame; true once it has landed.
	local function stepFlyer(f: Flyer, now: number): boolean
		local into = f.into
		if into then
			return stepInto(f, now, into)
		end
		local born = f.born
		local size = icon.AbsoluteSize.X
		if born then
			if now < born then
				return false
			end
			if now < f.launch then
				-- the pay's burst: out from the middle, overshooting, then hanging, turning
				local frame = f.view or frameFor(f)
				local p = math.clamp((now - born) / Pay.Scatter, 0, 1)
				local point = (f.origin :: Vector2):Lerp(f.spot :: Vector2, backOut(p))
				local across = size * FLYER * math.min(1, 0.3 + p * 1.4)
				frame.Position = UDim2.fromOffset(point.X, point.Y)
				frame.Size = UDim2.fromOffset(across, across)
				local coin = f.coin
				if coin then
					coin.CFrame = CFrame.Angles(0, (now - born) * TAU * 1.1, 0) * ICON_TURN * EDGE
				end
				return false
			end
			if not f.start then
				f.start = f.spot
				f.view = f.view or frameFor(f)
			end
		elseif now < f.launch then
			return false
		end
		if not f.view then
			local camera = Workspace.CurrentCamera
			local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
			local from = if f.from and f.from.Parent then f.from.Position else f.at
			local point, onScreen = Vector3.new(view.X / 2, view.Y * 0.7, 1), true
			if camera then
				point, onScreen = camera:WorldToViewportPoint(from)
			end
			f.start = if onScreen and point.Z > 0
				then Vector2.new(point.X, point.Y)
				else Vector2.new(view.X / 2, view.Y * 0.7)
			frameFor(f)
		end
		local frame = f.view :: ViewportFrame
		local p = math.clamp((now - f.launch) / Coins.Fly, 0, 1)
		local t = ease(p)
		local s = f.start :: Vector2
		local e = icon.AbsolutePosition + icon.AbsoluteSize / 2 - gui.AbsolutePosition
		local d = e - s
		local c = s:Lerp(e, 0.5) + Vector2.new(d.Y, -d.X) * 0.22 -- the arc bows up and out
		local a = s:Lerp(c, t)
		local b = c:Lerp(e, t)
		local point = a:Lerp(b, t)
		local grow = if born then 1 else math.min(1, p / 0.15)
		local across = size * (FLYER + (1 - FLYER) * t) * grow
		frame.Position = UDim2.fromOffset(point.X, point.Y)
		frame.Size = UDim2.fromOffset(across, across)
		local coin = f.coin
		if coin then
			-- a pay coin keeps turning the way it turned while it hung
			local turn = if born
				then (f.launch - born) * TAU * 1.1 + p * TAU * 1.5
				else -p * TAU * 1.5
			coin.CFrame = CFrame.Angles(0, turn, 0) * ICON_TURN * EDGE
		end
		if p < 1 then
			return false
		end
		frame:Destroy()
		f.view = nil
		tickTurn = tickTurn % TICKS + 1
		local tick = ticks[tickTurn]
		tick.PlaybackSpeed = (Coins.Tick.pitch or 1) * f.rise
		tick.TimePosition = Coins.Tick.from
		tick:Play()
		show(shown + f.worth, true)
		if born then
			pouring -= 1
			if pouring <= 0 then
				plusUntil = now + Pay.Plus
			end
		end
		return true
	end

	-- Paid at the gate (S1-06): `coins` burst out a beat after the slam and pour into the count.
	local function paid(coins: unknown)
		if typeof(coins) ~= "number" or coins ~= coins or coins < 1 then
			return
		end
		local shares = Pay.split(coins, Pay.Flyers)
		local n = #shares
		local now = os.clock()
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local origin = Vector2.new(view.X * Pay.From[1], view.Y * Pay.From[2])
		local reach = view.Y * Pay.Spread
		local born = now + Pay.Delay
		local twist = rng:NextNumber(0, TAU)
		for i, worth in shares do
			-- round a ring, a little ragged, flatter than tall so it reads as a spill
			local angle = twist + (i - 1) / n * TAU + rng:NextNumber(-0.3, 0.3)
			local r = reach * rng:NextNumber(0.55, 1)
			table.insert(flyers, {
				launch = born + Pay.Scatter + Pay.Hang + (i - 1) * Pay.Gap,
				from = nil,
				at = Vector3.zero,
				rise = 1 + PAY_CLIMB * (i - 1) / math.max(1, n - 1),
				worth = worth,
				view = nil,
				coin = nil,
				start = nil,
				born = born + rng:NextNumber(0, 0.05),
				origin = origin,
				spot = origin + Vector2.new(math.cos(angle) * r, math.sin(angle) * r * 0.7),
			})
		end
		pouring += n
		plusText = `+{Coins.text(coins)}`
		plusAt = born + Pay.Scatter + Pay.Hang
		plusUntil = math.huge
		pourAt = born
	end

	-- Paid at the car's machine (S1-10c2b): `price` coins leave the count for `machine`'s slot.
	local function spent(machine: unknown, bay: unknown, price: unknown)
		if
			typeof(machine) ~= "Instance"
			or not (machine :: Instance):IsA("Model")
			or type(bay) ~= "number"
			or type(price) ~= "number"
			or price ~= price
			or price < 1
		then
			return
		end
		local model = machine :: Model
		local spec = Machine.Specs.Slot
		local into = model:GetPivot():PointToWorldSpace(Vector3.new(spec[1], spec[2], spec[3]))
		local slot = Instance.new("Attachment")
		slot.Name = "CoinSlot"
		slot.WorldPosition = into
		slot.Parent = Workspace.Terrain
		local shares = Machine.Buy.coins(price)
		local n = #shares
		local now = os.clock()
		for i, worth in shares do
			local clink = sound(Coins.Chink, slot, Coins.Heard)
			clink.PlaybackSpeed = (Coins.Chink.pitch or 1) * rng:NextNumber(0.95, 1.15)
			table.insert(flyers, {
				launch = now + (i - 1) * Machine.Buy.CoinGap,
				from = nil,
				at = into,
				rise = 1 - Machine.Buy.CoinDown * (i - 1) / math.max(1, n - 1),
				worth = worth,
				view = nil,
				coin = nil,
				start = nil,
				into = into,
				clink = clink,
			})
		end
		local over = (n - 1) * Machine.Buy.CoinGap + Machine.Buy.CoinFly + Coins.Chink.length + 0.5
		task.delay(over, function()
			slot:Destroy()
		end)
	end

	local function added(model: Instance)
		if not model:IsA("Model") or piles[model] or not model:IsDescendantOf(Workspace) then
			return
		end
		local pile: Pile = {
			model = model,
			coins = {},
			rest = {},
			edge = {},
			sizes = {},
			start = nil,
			connection = nil :: any, -- any: set just below
		}
		piles[model] = pile
		if model:GetAttribute(Coins.TakenAttribute) ~= nil then
			-- taken before it reached this screen: hide it at once, glint and all
			gather(pile)
			pile.start = -math.huge
			for _, coin in pile.coins do
				coin.Transparency = 1
				local glint = coin:FindFirstChild("Glint")
				if glint and glint:IsA("ParticleEmitter") then
					glint.Enabled = false
				end
			end
		end
		pile.connection = model:GetAttributeChangedSignal(Coins.TakenAttribute):Connect(function()
			if model:GetAttribute(Coins.TakenAttribute) ~= nil then
				taken(pile)
			end
		end)
	end

	local function removed(model: Instance)
		local pile = piles[model :: Model]
		if pile then
			if pile.connection then
				pile.connection:Disconnect()
			end
			piles[model :: Model] = nil
		end
	end

	-- A marked box opened (B-03b): its coins wait to jump out as its flaps burst, and if it's
	-- yours, each is already on its way to the count (so the count waits for them).
	local function boxOpened(box: Model)
		local count = box:GetAttribute(Opening.Coins)
		local stamp = box:GetAttribute(Opening.OpenedAt)
		if typeof(count) ~= "number" or count < 1 or type(stamp) ~= "number" then
			return
		end
		local grade = box:GetAttribute(Opening.Grade)
		local reveal = Opening.Reveals[if type(grade) == "string" then grade else "Common"]
			or Opening.Reveals.Common
		-- on the box's own clock, as MarkedBoxView plays it (`Opening.clock`)
		local now = Workspace:GetServerTimeNow()
		local into = now - Opening.clock(stamp, now)
		local jump = Opening.burst(reveal.Hold) + Opening.Out.Rise
		if into > jump + Coins.LiftTime then
			return -- seen too late: they're gone
		end
		local leave = os.clock() + math.max(0, jump - into)
		local base = box:GetPivot()
		local _, yaw = base:ToOrientation()
		local mouth = base.Position + Vector3.new(0, Boxes.Marked.Size.Y - Coins.Box.Under, 0)
		local n = math.clamp(math.floor(count), 1, 3)
		local mine = box:GetAttribute(Opening.OpenedBy) == me.UserId
		local spill: Pour = { box = box, leave = leave, rest = {}, drift = {} }
		for i = 1, n do
			-- round the middle, the first toward the box's printed side
			local a = yaw + (i - 1) * TAU / n + (if n == 1 then 0.6 else 0)
			local dir = Vector3.new(-math.sin(a), 0, -math.cos(a))
			local rest = CFrame.new(mouth + dir * Coins.Box.Ring) * CFrame.Angles(0, a, 0)
			spill.rest[i] = rest
			spill.drift[i] = dir * Coins.Box.Fan
			if mine then
				table.insert(flyers, {
					launch = leave + (i - 1) * Coins.Stagger + Coins.LiftTime,
					from = nil,
					at = rest.Position + Vector3.new(0, Coins.Box.Lift, 0) + spill.drift[i],
					rise = 1 + (i - 1) * Coins.Climb,
					worth = 1,
					view = nil,
					coin = nil,
					start = nil,
				})
			end
		end
		table.insert(pours, spill)
	end

	-- A box's coins jump out now: this screen's own copies, moving as a taken pile's do.
	local function pourOut(spill: Pour, now: number)
		local coin = template()
		if not (coin and spill.box.Parent) then
			return
		end
		local model = Instance.new("Model")
		model.Name = "BoxCoins"
		for i, rest in spill.rest do
			local part = coin:Clone()
			part.Name = `Coin{i}`
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = false
			part.CFrame = rest
			part.Parent = model
		end
		model.Parent = Workspace
		local pile: Pile = {
			model = model,
			coins = {},
			rest = {},
			edge = {},
			sizes = {},
			start = now,
			owned = true,
			drift = spill.drift,
			lift = Coins.Box.Lift,
		}
		gather(pile)
		table.insert(moving, pile)
		local mouth = spill.box:GetPivot().Position + Vector3.new(0, Boxes.Marked.Size.Y + 0.3, 0)
		chink(mouth, #spill.rest)
	end

	local function boxAdded(inst: Instance)
		if not inst:IsA("Model") or boxes[inst] then
			return
		end
		-- a box streamed in already open stands open: its coins are long gone
		boxes[inst] = inst:GetAttributeChangedSignal(Opening.OpenedAt):Connect(function()
			boxOpened(inst)
		end)
	end

	local function boxRemoved(inst: Instance)
		local c = boxes[inst :: Model]
		if c then
			c:Disconnect()
			boxes[inst :: Model] = nil
		end
	end

	local system = { name = "CoinView" }

	function system.start(_: any, _context: Brix.Context)
		gui.Parent = me:WaitForChild("PlayerGui")
		layout()
		local camera = Workspace.CurrentCamera
		if camera then
			table.insert(
				connections,
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					layout()
					place(os.clock())
				end)
			)
		end
		table.insert(
			connections,
			GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
				layout()
				place(os.clock())
			end)
		)
		table.insert(
			connections,
			chip:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				place(os.clock())
			end)
		)
		table.insert(connections, me:GetAttributeChangedSignal(Coins.Attribute):Connect(counted))
		counted()
		for _, model in CollectionService:GetTagged(Coins.Tag) do
			added(model)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Coins.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Coins.Tag):Connect(removed)
		)
		-- marked boxes, for the coins in them (B-03b)
		for _, box in CollectionService:GetTagged(Opening.Tag) do
			boxAdded(box)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Opening.Tag):Connect(boxAdded)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Opening.Tag):Connect(boxRemoved)
		)
		task.spawn(SoundPrimer.prime, { Coins.Chink.id, Coins.Jingle.id, Pay.Pour.id })
		-- the pay at the gate: coins, then the finds kept (KeepView's)
		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(Pay.RemoteFolder)
			local remote = folder:WaitForChild(Pay.Remote)
			if remote:IsA("RemoteEvent") then
				table.insert(connections, remote.OnClientEvent:Connect(paid))
			end
		end)
		-- a buy at the car's machine: the coins into its slot
		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(Machine.Buy.RemoteFolder)
			local remote = folder:WaitForChild(Machine.Buy.Remote)
			if remote:IsA("RemoteEvent") then
				table.insert(connections, remote.OnClientEvent:Connect(spent))
			end
		end)
	end

	function system.step(_: any, _dt: number)
		local now = os.clock()
		for i = #pours, 1, -1 do
			local spill = pours[i]
			if now >= spill.leave then
				table.remove(pours, i)
				pourOut(spill, now)
			end
		end
		for i = #moving, 1, -1 do
			local pile = moving[i]
			if stepPile(pile, now) then
				table.remove(moving, i)
				if pile.owned then
					pile.model:Destroy()
				end
			end
		end
		for i = #flyers, 1, -1 do
			if stepFlyer(flyers[i], now) then
				table.remove(flyers, i)
			end
		end
		if sliding then
			sliding = place(now)
		end
		if pourAt and now >= pourAt then
			pourAt = nil
			pour.TimePosition = Pay.Pour.from
			pour:Play()
		end
		if plusAt and now >= plusAt then
			plusAt = nil
			plus.Text = plusText
			plus.TextTransparency = 0
			plus.TextStrokeTransparency = 0.45
			plus.Visible = true
			plusPop.Scale = 1.5
			TweenService:Create(plusPop, SETTLE, { Scale = 1 }):Play()
		end
		if plus.Visible then
			local at = chip.AbsolutePosition - gui.AbsolutePosition
			plus.Position = UDim2.fromOffset(at.X - PLUS_GAP, at.Y + chip.AbsoluteSize.Y / 2)
			if now >= plusUntil then
				plusUntil = math.huge
				local fade = TweenService:Create(
					plus,
					PLUS_FADE,
					{ TextTransparency = 1, TextStrokeTransparency = 1 }
				)
				fade.Completed:Once(function()
					if plusUntil == math.huge and not plusAt then
						plus.Visible = false
					end
				end)
				fade:Play()
			end
		end
		local spun = now - spinAt
		if spun < SPIN_BACK + 0.05 then
			-- the picture flips once round, as a coin spun on a table: narrowed by the turn
			local p = math.min(spun / SPIN_BACK, 1)
			local e = 1 - (1 - p) ^ 3
			local across = math.max(math.abs(math.cos(e * TAU)), ICON_EDGE)
			iconImage.Size = UDim2.fromScale(ICON_FILL * across, ICON_FILL)
		end
		-- the count catches up with the server's when nothing is flying to it
		local goal = target
		if goal and #flyers == 0 and goal ~= shown then
			if goal < shown then
				show(goal, false)
			elseif now - changedAt >= Coins.Grace then
				show(goal, true)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for model in piles do
			removed(model)
		end
		for model in boxes do
			boxRemoved(model)
		end
		for _, pile in moving do
			if pile.owned then
				pile.model:Destroy()
			end
		end
		table.clear(pours)
		table.clear(moving)
		table.clear(flyers)
		gui:Destroy()
	end

	return system :: any -- any: a plain Brix system built field by field
end

return CoinView
