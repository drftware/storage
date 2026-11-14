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
]]
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Coins = require(ReplicatedStorage.Shared.Coins)
local CoinSpecs = require(ReplicatedStorage.Shared.Coins.Specs)
local Minimap = require(ReplicatedStorage.Shared.Minimap)
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
local TICKS = 3 -- tick sounds taken in turn, so a quick run of landings never cuts one short
local TAU = 2 * math.pi
local EDGE = CFrame.Angles(math.pi / 2, 0, 0) -- a coin on its edge, face to the front (+Z)
local ICON_TURN = CFrame.Angles(0, math.rad(-22), 0) * CFrame.Angles(math.rad(8), 0, 0)
local SETTLE = TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local RIM_BACK = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

type Pile = {
	model: Model,
	coins: { BasePart },
	rest: { CFrame }, -- each coin where it lay
	edge: { CFrame }, -- each coin's turn stood on its edge (its lying yaw kept)
	sizes: { Vector3 },
	start: number?, -- when it was taken, on this screen's clock
	connection: RBXScriptConnection,
}

type Flyer = {
	launch: number, -- when it sets off
	from: BasePart?, -- the coin it flies on from (nil: from the pile's middle)
	at: Vector3, -- the pile's middle, if the coin's gone
	rise: number, -- its landing tick's pitch, against `Coins.Tick.pitch`
	view: ViewportFrame?,
	coin: BasePart?,
	start: Vector2?,
}

local CoinView = {}

local function ease(p: number): number
	return p * p * (3 - 2 * p)
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
	local connections: { RBXScriptConnection } = {}

	local target: number? = nil -- the count the server says
	local changedAt = 0
	local shown = 0 -- the count on screen
	local out = true -- slid off the screen
	local slideFrom, slideTo, slideAt = 1, 1, -math.huge -- 0 in place, 1 off the right edge
	local sliding = false
	local spinAt = -math.huge
	local tickTurn = 0

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

	local icon = Instance.new("ViewportFrame")
	icon.Name = "Coin"
	icon.LayoutOrder = 1
	icon.Parent = chip
	local iconCoin: BasePart? = nil

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
		local spot = Instance.new("Attachment")
		spot.Name = "CoinTake"
		spot.Parent = Workspace.Terrain
		spot.WorldPosition = at + Vector3.new(0, 0.3, 0)
		sound(Coins.Chink, spot, Coins.Heard):Play()
		local longest = Coins.Chink.length
		if n >= 2 then
			sound(Coins.Jingle, spot, Coins.Heard):Play()
			longest = math.max(longest, Coins.Jingle.length)
		end
		task.delay(longest + 0.3, function()
			spot:Destroy()
		end)
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
				coin.CFrame = CFrame.new(rest.Position + Vector3.new(0, Coins.Lift * e, 0))
					* spin
					* turn
			else
				local q = (u - Coins.LiftTime) / Coins.Vanish
				local size = math.max(1 - q * q, 0.02)
				coin.Size = pile.sizes[i] * size
				coin.CFrame = CFrame.new(rest.Position + Vector3.new(0, Coins.Lift + 0.2 * q, 0))
					* spin
					* pile.edge[i]
			end
		end
		return done
	end

	-- Moves a flying coin on your screen for this frame; true once it has landed.
	local function stepFlyer(f: Flyer, now: number): boolean
		if now < f.launch then
			return false
		end
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local size = icon.AbsoluteSize.X
		if not f.view then
			local from = if f.from and f.from.Parent then f.from.Position else f.at
			local point, onScreen = Vector3.new(view.X / 2, view.Y * 0.7, 1), true
			if camera then
				point, onScreen = camera:WorldToViewportPoint(from)
			end
			f.start = if onScreen and point.Z > 0
				then Vector2.new(point.X, point.Y)
				else Vector2.new(view.X / 2, view.Y * 0.7)
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
		local grow = math.min(1, p / 0.15)
		local across = size * (FLYER + (1 - FLYER) * t) * grow
		frame.Position = UDim2.fromOffset(point.X, point.Y)
		frame.Size = UDim2.fromOffset(across, across)
		local coin = f.coin
		if coin then
			coin.CFrame = CFrame.Angles(0, -p * TAU * 1.5, 0) * ICON_TURN * EDGE
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
		show(shown + 1, true)
		return true
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
			pile.connection:Disconnect()
			piles[model :: Model] = nil
		end
	end

	local system = { name = "CoinView" }

	function system.start(_: any, _context: Brix.Context)
		gui.Parent = me:WaitForChild("PlayerGui")
		layout()
		local coin = template()
		if coin then
			iconCoin = picture(icon, coin, 0.86)
		end
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
		task.spawn(SoundPrimer.prime, { Coins.Chink.id, Coins.Jingle.id })
	end

	function system.step(_: any, _dt: number)
		local now = os.clock()
		for i = #moving, 1, -1 do
			if stepPile(moving[i], now) then
				table.remove(moving, i)
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
		local spun = now - spinAt
		local c = iconCoin
		if c and spun < SPIN_BACK + 0.05 then
			local p = math.min(spun / SPIN_BACK, 1)
			local e = 1 - (1 - p) ^ 3
			c.CFrame = CFrame.Angles(0, e * TAU, 0) * ICON_TURN * EDGE
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
		table.clear(moving)
		table.clear(flyers)
		gui:Destroy()
	end

	return system :: any -- any: a plain Brix system built field by field
end

return CoinView
