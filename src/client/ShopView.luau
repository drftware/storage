--!strict
--[[
	ShopView: the counter's shop (S3-04b, `Shop`). The moment: back in the lobby after a climb you
	walk up to the front office's counter, press Shop, and the shop slides up from the bottom, its
	cards dealt out left to right: you, turning slowly, wrapped in each colour's film, its price on
	Buy. Buy, pay, and that card's film snaps tight round you with the film's squeal, its rim
	flashes in the colour and its button says Worn. An owned colour says Wear; the first card, the
	plain clear film, is always yours.

	Three ways in, all only in the front office: the counter's prompt (made here, on this screen,
	in front of the counter: it opens a screen and needs nothing from the server), the Shop button
	at the left of Roblox's top bar row, and nothing else. It closes on its X, a tap outside it, or
	leaving the lobby.

	Every ask goes to the server (Wearing): the shelf (prices, owned, worn) as it opens and after
	each change; Buy puts Roblox's prompt up from the server; Wear puts on an owned colour. What's
	worn lands as this Player's `WrapColour`, which flips the cards. Every number is `Shop`'s.

	The figures are a copy of your character (scripts stripped) in a ViewportFrame per card, the
	film (`Props.KeptWrap`) fitted round it as the server fits it and tinted as it does. They're
	made as the shop opens and gone when it closes; only while it's open does anything step.

	Try on (S5-03f4b, D-319): standing in front of a mirror within `Shop.TryReach` (the counter's,
	beside it), each colour's figure carries a Try on. A tap anywhere on the figure pops the card
	and the shop slides away, and the server wraps you in exactly that colour at the mirror, your
	view turning to it (TryOns, TryOnView). Away from a mirror, or while a film is on you, there's
	no Try on to press.
]]
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local Kept = require(ReplicatedStorage.Shared.Kept)
local KeptWrap = require(ReplicatedStorage.Shared.KeptWrap.Specs)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Mirror = require(ReplicatedStorage.Shared.Mirror)
local Shop = require(ReplicatedStorage.Shared.Shop)
local TryOn = require(ReplicatedStorage.Shared.TryOn)
local WrapColours = require(ReplicatedStorage.Shared.WrapColours)

local INK = Lobby.Ink
local FILL_WARM = Color3.fromRGB(CutFree.Fill.r, CutFree.Fill.g, CutFree.Fill.b)
local INK_WARM = Color3.fromRGB(CutFree.Ink.r, CutFree.Ink.g, CutFree.Ink.b)
local PANEL = Color3.fromRGB(20, 20, 23)
local CARD = Color3.fromRGB(32, 32, 36)
local WELL = Color3.fromRGB(12, 12, 14)
local ROBUX = utf8.char(0xE002) -- Roblox's own Robux mark in its fonts

local SLIDE_IN = TweenInfo.new(Shop.SlideIn, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(Shop.SlideOut, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local POP = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SPRING = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(0.16)
local FLASH = TweenInfo.new(Shop.FlashTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- How often (seconds) the lobby check runs while the shop is shut.
local LOOK_EVERY = 0.25
-- The front office in its own frame: "in the lobby" inside this box (the floor's 120 by 156, from
-- the bay wall at z 0 to the front wall at -156; the homes are past the side walls).
local ROOM_X, ROOM_Z, ROOM_Y = 60, 157, 20
-- Seconds after a Try on's pop that the shop starts to slide away: the pop reads first.
local TRY_SHUT = 0.12
local CAMERA_FOV = 30

-- A card on the shelf: its colour's name (empty for the plain film), its parts, and its figure.
type Card = {
	name: string,
	frame: Frame,
	pop: UIScale,
	rim: UIStroke,
	button: TextButton,
	buttonPop: UIScale,
	buttonRing: UIStroke,
	try: TextButton?, -- the figure as a Try on (none on the plain film)
	tryPill: Frame?,
	tryPop: UIScale?,
	viewport: ViewportFrame,
	camera: Camera,
	centre: number, -- the film's middle height, for the camera's aim
	wrap: BasePart?,
	wrapSize: Vector3,
	state: Shop.State?,
	price: number?,
	asked: number, -- os.clock of the last Buy press
	snap: number, -- seconds into its snap, or -1
}

local ShopView = {}

local function box(size: Vector3, centre: Vector3): Kept.Box
	return { size = { size.X, size.Y, size.Z }, centre = { centre.X, centre.Y, centre.Z } }
end
local DRAWN = box(KeptWrap.Body.Size, KeptWrap.Body.Centre)
local WRAP = box(KeptWrap.Wrap.Size, KeptWrap.Wrap.Centre)

-- A copy of `character` to stand in a viewport: scripts and tools gone, anchored, its root at
-- the origin facing -Z; and its body's box from its root (nil if it has none).
local function figure(character: Model?): (Model?, Kept.Box?)
	if character == nil then
		return nil, nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil, nil
	end
	local was = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = was
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	local rootAt = root.CFrame
	for _, d in copy:GetDescendants() do
		if
			d:IsA("LuaSourceContainer")
			or d:IsA("Tool")
			or d:IsA("ForceField")
			or d:IsA("Sound")
		then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			if d.Parent == copy and d.Name ~= "HumanoidRootPart" then
				local cf = rootAt:ToObjectSpace(d.CFrame)
				local h = d.Size / 2
				for _, c in
					{
						Vector3.new(1, 1, 1),
						Vector3.new(1, 1, -1),
						Vector3.new(1, -1, 1),
						Vector3.new(1, -1, -1),
					}
				do
					local p, q = cf * (h * c), cf * (-h * c)
					lo, hi = lo:Min(p):Min(q), hi:Max(p):Max(q)
				end
			end
		end
	end
	local humanoid = copy:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	-- the root to the origin: a pivot P with the root at R moves to R⁻¹·P
	copy:PivotTo(rootAt:Inverse() * copy:GetPivot())
	return copy, if lo.X <= hi.X then box(hi - lo, (hi + lo) / 2) else nil
end

function ShopView.new(): Brix.System
	local player = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local gui: ScreenGui? = nil
	local counter: Part? = nil
	local stepping: RBXScriptConnection? = nil
	local open = false
	local cards: { Card } = {}
	local byName: { [string]: Card } = {}
	local worn = "" -- what the server last said we wear
	local asking = false -- a shelf ask is out
	local again = false -- another ask wanted once it's back
	local reasked = false -- asked again for a missing price since it opened
	local cardLinks: { RBXScriptConnection } = {} -- the open shop's buttons
	local since = 0 -- seconds since the lobby check
	local inLobby = false
	local openedAt = -math.huge -- os.clock the shop last opened
	local canTry = false -- the cards' Try on shows: in front of a mirror, no film on

	-- built in start
	local topButton: TextButton
	local topPop: UIScale
	local backdrop: TextButton
	local panel: Frame
	local row: ScrollingFrame
	local closeButton: TextButton
	local click: Sound
	local squeal: Sound

	local function play(pitch: number)
		click.PlaybackSpeed = Shop.Click.pitch * pitch
		click.TimePosition = 0
		click:Play()
	end

	local function spring(scale: UIScale)
		scale.Scale = Shop.Pressed
		TweenService:Create(scale, SPRING, { Scale = 1 }):Play()
	end

	-- The film's squeal, short and high: a snap, not a catch.
	local function snapSound()
		squeal.TimePosition = Kept.Squeal.from
		squeal:Play()
		task.delay(Shop.SnapLength, function()
			if squeal.IsPlaying then
				TweenService:Create(squeal, FADE, { Volume = 0 }):Play()
				task.delay(FADE.Time, function()
					squeal:Stop()
					squeal.Volume = Shop.SnapVolume
				end)
			end
		end)
	end

	-- The card's button for its state: Buy with the price, Wear, or Worn.
	local function paint(card: Card)
		local b, ring = card.button, card.buttonRing
		local state = card.state
		b.TextTransparency = 0
		if state == "buy" then
			b.Text = if card.price then `{ROBUX} {card.price}` else Shop.Words.buy
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = FILL_WARM, INK_WARM, 0.05
			ring.Color, ring.Transparency = INK_WARM, 0.2
		elseif state == "wear" then
			b.Text = Shop.Words.wear
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = WELL, INK, 0.1
			ring.Color, ring.Transparency = INK, 0.25
		elseif state == "worn" then
			b.Text = Shop.Words.worn
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = WELL, INK, 1
			ring.Color, ring.Transparency = INK, 0.8
		else
			b.Text = ""
			b.BackgroundTransparency = 1
			ring.Transparency = 1
		end
		card.rim.Transparency = if state == "worn" then 0.05 else 0.7
		card.rim.Thickness = if state == "worn" then 2 else 1
	end

	-- The film snapping tight on `card`: squeezed, springing back; its rim flashing; the squeal.
	local function snap(card: Card)
		card.snap = 0
		card.pop.Scale = 1.06
		TweenService:Create(card.pop, POP, { Scale = 1 }):Play()
		card.rim.Thickness = 5
		TweenService:Create(card.rim, FLASH, { Thickness = 2 }):Play()
		snapSound()
	end

	local refresh: (before: string) -> () -- asks for the shelf; made below

	-- The shelf the server answered: each card's state and price; a newly worn one snaps.
	local function apply(shelf: Shop.Shelf, before: string)
		worn = shelf.worn
		for _, item in shelf.items do
			local card = byName[item.name]
			if card then
				card.state = Shop.state(item, worn)
				card.price = item.price
			end
		end
		local plain = byName[""]
		if plain then
			plain.state = if worn == "" then "worn" else "wear"
		end
		local missing = false
		for _, card in cards do
			paint(card)
			missing = missing or (card.state == "buy" and card.price == nil)
		end
		if missing and not reasked then
			reasked = true
			task.delay(Shop.PriceWait, function()
				if open then
					refresh(worn)
				end
			end)
		end
		if worn ~= before then
			local card = byName[worn]
			if card then
				snap(card)
			end
		end
	end

	-- Asks the server for the shelf (yields in its own thread) and applies it.
	function refresh(before: string)
		if asking then
			again = true
			return
		end
		asking = true
		task.spawn(function()
			local folder = ReplicatedStorage:FindFirstChild(Shop.RemoteFolder)
			local remote = folder and folder:FindFirstChild(Shop.ShelfRemote)
			local answer: unknown = nil
			if remote and remote:IsA("RemoteFunction") then
				local ok, got = pcall(remote.InvokeServer, remote)
				answer = if ok then got else nil
			end
			asking = false
			local shelf = Shop.read(answer)
			if shelf and open then
				apply(shelf, before)
			end
			if again and open then
				again = false
				refresh(worn)
			end
		end)
	end

	local function fire(name: string, value: string)
		local folder = ReplicatedStorage:FindFirstChild(Shop.RemoteFolder)
		local remote = folder and folder:FindFirstChild(name)
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer(value)
		end
	end

	-- A press on a card's button: Buy asks the server for the prompt; Wear puts it on; Worn and a
	-- Buy already out are ignored (nothing to fix, so nothing said).
	local function press(card: Card)
		local state = card.state
		local t = os.clock()
		if state == "worn" or state == nil or (state == "buy" and t - card.asked < Shop.AskDim) then
			return
		end
		spring(card.buttonPop)
		play(1)
		if state == "buy" then
			card.asked = t
			card.button.BackgroundTransparency = 1
				- (1 - card.button.BackgroundTransparency) * Shop.Dim
			card.button.TextTransparency = 1 - Shop.Dim
			task.delay(Shop.AskDim, function()
				if card.state == "buy" then
					paint(card)
				end
			end)
			fire(Shop.BuyRemote, card.name)
		else
			fire(Shop.WearRemote, card.name)
		end
	end

	local close: () -> () -- shuts the shop; made below

	-- A card's Try on: its figure pops, the shop slides away, and the server wraps you in that
	-- colour at the mirror. Ignored when there's no Try on to press.
	local function tryOn(card: Card)
		if not (open and canTry) or os.clock() - openedAt < Shop.SlideIn then
			return
		end
		card.pop.Scale = 1.08
		TweenService:Create(card.pop, POP, { Scale = 1 }):Play()
		local pill = card.tryPop
		if pill then
			spring(pill)
		end
		play(1.1)
		fire(Shop.TryRemote, card.name)
		task.delay(TRY_SHUT, close)
	end

	-- Whether the cards' Try on shows: you stand in front of a mirror's glass within
	-- `Shop.TryReach` and in line with it, so you'd see yourself (as the server checks), with no
	-- try-on film on you already.
	local function nearMirror(): boolean
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (character and root and root:IsA("BasePart")) then
			return false
		end
		if character:FindFirstChild("TryOnFilm") then
			return false
		end
		for _, glass in CollectionService:GetTagged(Mirror.Tag) do
			if
				glass:IsA("BasePart")
				and TryOn.before(
					glass.Position,
					glass.CFrame.LookVector,
					root.Position,
					Shop.TryReach
				)
				and TryOn.inLine(
					glass.Position,
					glass.CFrame.RightVector,
					root.Position,
					glass.Size.X / 2
				)
			then
				return true
			end
		end
		return false
	end

	-- Every colour card's Try on shown or hidden as `canTry` is now; popping in when it appears.
	local function showTry()
		for _, card in cards do
			local b, pill, pop = card.try, card.tryPill, card.tryPop
			if b and pill and pop then
				if canTry and not b.Visible then
					pop.Scale = 0.6
					TweenService:Create(pop, POP, { Scale = 1 }):Play()
				end
				b.Visible = canTry
				pill.Visible = canTry
			end
		end
	end

	-- One card for the colour named `name` (empty for the plain film), its figure in its film.
	local function makeCard(name: string, label: string, order: number, character: Model?): Card
		local frame = Instance.new("Frame")
		frame.Name = if name == "" then "Plain" else name
		frame.LayoutOrder = order
		frame.BackgroundColor3 = CARD
		frame.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.08, 0)
		corner.Parent = frame
		local rim = Instance.new("UIStroke")
		rim.Color = if name == "" then INK else WrapColours.tint(name)
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Parent = frame
		local pop = Instance.new("UIScale")
		pop.Scale = 0
		pop.Parent = frame

		local viewport = Instance.new("ViewportFrame")
		viewport.Name = "Figure"
		viewport.BackgroundTransparency = 1
		viewport.Size = UDim2.fromScale(1, 0.66)
		viewport.Ambient = Color3.fromRGB(150, 150, 160)
		viewport.LightColor = Color3.fromRGB(255, 240, 220)
		viewport.LightDirection = Vector3.new(-0.6, -1, -0.8)
		viewport.Parent = frame
		local camera = Instance.new("Camera")
		camera.FieldOfView = CAMERA_FOV
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		local world = Instance.new("WorldModel")
		world.Parent = viewport

		local body, bodyBox = figure(character)
		if body then
			body.Parent = world
		end
		local fit = Kept.fit(bodyBox or DRAWN, DRAWN, WRAP)
		local size = Vector3.new(fit.size[1], fit.size[2], fit.size[3])
		local props = ReplicatedStorage:FindFirstChild("Props")
		local template = props and props:FindFirstChild(Kept.Wrap)
		local wrap: BasePart? = nil
		if template and template:IsA("BasePart") then
			local w = template:Clone()
			w.Anchored = true
			w.Size = size
			w.CFrame = CFrame.new(fit.centre[1], fit.centre[2], fit.centre[3])
			w.Transparency = Kept.WrapBlend
			local look = w:FindFirstChildWhichIsA("SurfaceAppearance")
			if look then
				look.Color = WrapColours.tint(name)
			end
			w.Parent = world
			wrap = w
		end

		local caption = Instance.new("TextLabel")
		caption.Name = "Label"
		caption.BackgroundTransparency = 1
		caption.Position = UDim2.fromScale(0, 0.66)
		caption.Size = UDim2.fromScale(1, 0.12)
		caption.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		caption.TextScaled = true
		caption.TextColor3 = INK
		caption.Text = label
		caption.Parent = frame

		local button = Instance.new("TextButton")
		button.Name = "Button"
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.fromScale(0.5, 0.95)
		button.Size = UDim2.fromScale(0.84, 0.15)
		button.AutoButtonColor = false
		button.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold) -- it draws the Robux mark
		button.TextScaled = true
		button.Text = ""
		button.BackgroundTransparency = 1
		button.Parent = frame
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0.5, 0)
		bc.Parent = button
		local bp = Instance.new("UIPadding")
		bp.PaddingTop, bp.PaddingBottom = UDim.new(0.2, 0), UDim.new(0.2, 0)
		bp.Parent = button
		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Thickness = 2
		ring.Transparency = 1
		ring.Parent = button
		local buttonPop = Instance.new("UIScale")
		buttonPop.Parent = button

		-- the figure as a Try on: the whole figure takes the tap, a pill at its foot says it
		local try: TextButton? = nil
		local tryPill: Frame? = nil
		local tryPop: UIScale? = nil
		if name ~= "" then
			local t = Instance.new("TextButton")
			t.Name = "TryOn"
			t.BackgroundTransparency = 1
			t.AutoButtonColor = false
			t.Text = ""
			t.Size = UDim2.fromScale(1, 0.66)
			t.ZIndex = 2
			t.Visible = false
			t.Parent = frame
			local pill = Instance.new("Frame")
			pill.Name = "TryPill"
			pill.AnchorPoint = Vector2.new(0.5, 1)
			pill.Position = UDim2.fromScale(0.5, 0.64)
			pill.Size = UDim2.fromScale(0.7, 0.12)
			pill.BackgroundColor3 = WELL
			pill.BackgroundTransparency = 0.25
			pill.ZIndex = 3
			pill.Visible = false
			pill.Parent = frame
			local pc = Instance.new("UICorner")
			pc.CornerRadius = UDim.new(0.5, 0)
			pc.Parent = pill
			local ps = Instance.new("UIStroke")
			ps.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			ps.Color = WrapColours.tint(name)
			ps.Thickness = 1.5
			ps.Parent = pill
			local words = Instance.new("TextLabel")
			words.Name = "Words"
			words.BackgroundTransparency = 1
			words.Size = UDim2.fromScale(1, 1)
			words.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
			words.TextScaled = true
			words.TextColor3 = INK
			words.Text = Shop.Words.try
			words.ZIndex = 3
			words.Parent = pill
			local wp = Instance.new("UIPadding")
			wp.PaddingTop, wp.PaddingBottom = UDim.new(0.18, 0), UDim.new(0.18, 0)
			wp.Parent = words
			local popScale = Instance.new("UIScale")
			popScale.Parent = pill
			try, tryPill, tryPop = t, pill, popScale
		end

		local card: Card = {
			name = name,
			frame = frame,
			pop = pop,
			rim = rim,
			button = button,
			buttonPop = buttonPop,
			buttonRing = ring,
			try = try,
			tryPill = tryPill,
			tryPop = tryPop,
			viewport = viewport,
			camera = camera,
			centre = fit.centre[2],
			wrap = wrap,
			wrapSize = size,
			state = nil,
			price = nil,
			asked = -math.huge,
			snap = -1,
		}
		table.insert(
			cardLinks,
			button.Activated:Connect(function()
				press(card)
			end)
		)
		if try then
			table.insert(
				cardLinks,
				try.Activated:Connect(function()
					tryOn(card)
				end)
			)
		end
		paint(card)
		return card
	end

	-- Sizes the panel and the cards for this screen: phone first.
	local function layout()
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local width = math.min(view.X * 0.9, 920)
		local height = math.clamp(view.Y * 0.62, 210, 420)
		panel.Size = UDim2.fromOffset(width, height)
		local header = math.floor(height * 0.16)
		local pad = math.floor(height * 0.05)
		row.Position = UDim2.fromOffset(pad, header)
		row.Size = UDim2.fromOffset(width - pad * 2, height - header - pad)
		local cardHeight = height - header - pad * 2
		for _, card in cards do
			card.frame.Size = UDim2.fromOffset(math.floor(cardHeight * Shop.CardAspect), cardHeight)
		end
		local list = row:FindFirstChildWhichIsA("UIListLayout")
		if list then
			list.Padding = UDim.new(0, math.floor(cardHeight * Shop.CardGap))
		end
		local free = GuiService.TopbarInset
		local h = if free.Height > 0 then math.floor(free.Height * 0.72) else 36
		topButton.Size = UDim2.fromOffset(h * 2.3, h)
		topButton.Position = if free.Width > 0
			then UDim2.fromOffset(free.Min.X + 8, (free.Min.Y + free.Max.Y) / 2 - h / 2)
			else UDim2.fromOffset(12, 12)
	end

	local function step(dt: number)
		local spin = os.clock() * Shop.Spin * math.pi * 2
		for i, card in cards do
			local a = spin + i * 0.7
			local dist = 12
			local eye = Vector3.new(math.sin(a) * dist, card.centre + 0.4, -math.cos(a) * dist)
			card.camera.CFrame = CFrame.lookAt(eye, Vector3.new(0, card.centre, 0))
			local wrap = card.wrap
			if card.snap >= 0 and wrap then
				card.snap += dt
				local t = card.snap
				local s = if t >= Shop.SnapTime
					then 1
					else 1 - (1 - Shop.SnapSqueeze) * math.exp(-7 * t) * math.cos(22 * t)
				local size = card.wrapSize
				wrap.Size = Vector3.new(size.X * s, size.Y, size.Z * s)
				if t >= Shop.SnapTime then
					card.snap = -1
				end
			end
		end
	end

	local function clear()
		for _, c in cardLinks do
			c:Disconnect()
		end
		table.clear(cardLinks)
		again = false
		for _, card in cards do
			card.frame:Destroy()
		end
		table.clear(cards)
		table.clear(byName)
	end

	function close()
		if not open then
			return
		end
		open = false
		if stepping then
			stepping:Disconnect()
			stepping = nil
		end
		play(Shop.OpenPitch)
		TweenService:Create(backdrop, SLIDE_OUT, { BackgroundTransparency = 1 }):Play()
		local out = TweenService:Create(
			panel,
			SLIDE_OUT,
			{ Position = UDim2.fromScale(0.5, 1 + Shop.SlideFrom) }
		)
		out:Play()
		task.delay(Shop.SlideOut, function()
			if not open then
				backdrop.Visible = false
				panel.Visible = false
				clear()
			end
		end)
	end

	local function openShop()
		if open or not inLobby then
			return
		end
		open = true
		openedAt = os.clock()
		reasked = false
		clear()
		local mine = player:GetAttribute(WrapColours.Attribute)
		worn = if type(mine) == "string" then mine else ""
		local character = player.Character
		local plain = makeCard("", Shop.Words.plain, 0, character)
		table.insert(cards, plain)
		byName[""] = plain
		for i, colour in WrapColours.Shelf do
			local card = makeCard(colour.name, colour.label, i, character)
			table.insert(cards, card)
			byName[colour.name] = card
		end
		for _, card in cards do
			card.frame.Parent = row
		end
		canTry = nearMirror()
		showTry()
		layout()
		row.CanvasPosition = Vector2.zero
		backdrop.Visible = true
		panel.Visible = true
		backdrop.BackgroundTransparency = 1
		TweenService:Create(backdrop, SLIDE_IN, { BackgroundTransparency = 0.55 }):Play()
		panel.Position = UDim2.fromScale(0.5, 1 + Shop.SlideFrom)
		TweenService:Create(panel, SLIDE_IN, { Position = UDim2.new(0.5, 0, 1, -10) }):Play()
		for i, card in cards do
			task.delay(Shop.SlideIn * 0.4 + (i - 1) * Shop.DealEvery, function()
				if open then
					TweenService:Create(card.pop, POP, { Scale = 1 }):Play()
				end
			end)
		end
		play(Shop.OpenPitch)
		step(0)
		stepping = RunService.RenderStepped:Connect(step)
		-- answered states only: the buttons stay blank until the server says
		refresh(worn)
	end

	local function look()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local was = inLobby
		if root and root:IsA("BasePart") then
			local p = Lobby.Origin:PointToObjectSpace(root.Position)
			inLobby = math.abs(p.X) <= ROOM_X
				and p.Z <= 0
				and p.Z >= -ROOM_Z
				and math.abs(p.Y) <= ROOM_Y
		else
			inLobby = false
		end
		if inLobby ~= was then
			topButton.Visible = inLobby
			if inLobby then
				topPop.Scale = 0.6
				TweenService:Create(topPop, POP, { Scale = 1 }):Play()
			end
			local p = counter
			local prompt = p and p:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Enabled = inLobby
			end
			if not inLobby then
				close()
			end
		end
		if open then
			local could = canTry
			canTry = nearMirror()
			if canTry ~= could then
				showTry()
			end
		end
	end

	local system = { name = "ShopView" }

	function system.start(_: any)
		local g = Instance.new("ScreenGui")
		g.Name = "Shop"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.DisplayOrder = 20
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui = g

		topButton = Instance.new("TextButton")
		topButton.Name = "ShopButton"
		topButton.AutoButtonColor = false
		topButton.BackgroundColor3 = Color3.new(0, 0, 0)
		topButton.BackgroundTransparency = 0.3
		topButton.Font = Enum.Font.GothamBold
		topButton.Text = Shop.Words.open
		topButton.TextColor3 = INK
		topButton.TextScaled = true
		topButton.Visible = false
		topButton.Parent = g
		local tc = Instance.new("UICorner")
		tc.CornerRadius = UDim.new(0.5, 0)
		tc.Parent = topButton
		local tp = Instance.new("UIPadding")
		tp.PaddingTop, tp.PaddingBottom = UDim.new(0.24, 0), UDim.new(0.24, 0)
		tp.Parent = topButton
		topPop = Instance.new("UIScale")
		topPop.Parent = topButton

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
		panel.BackgroundTransparency = 0.04
		panel.Visible = false
		panel.Parent = g
		local pc = Instance.new("UICorner")
		pc.CornerRadius = UDim.new(0, 14)
		pc.Parent = panel
		local ps = Instance.new("UIStroke")
		ps.Color = Color3.fromRGB(70, 70, 76)
		ps.Thickness = 1
		ps.Parent = panel

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromScale(0.035, 0.03)
		title.Size = UDim2.fromScale(0.5, 0.11)
		title.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = INK
		title.Text = Shop.Words.title
		title.Parent = panel

		closeButton = Instance.new("TextButton")
		closeButton.Name = "Close"
		closeButton.AnchorPoint = Vector2.new(1, 0)
		closeButton.Position = UDim2.new(1, -10, 0, 10)
		closeButton.Size = UDim2.fromScale(0.1, 0.1)
		closeButton.AutoButtonColor = false
		closeButton.BackgroundColor3 = WELL
		closeButton.Font = Enum.Font.GothamBold
		closeButton.Text = "X"
		closeButton.TextColor3 = INK
		closeButton.TextScaled = true
		closeButton.Parent = panel
		local ca = Instance.new("UIAspectRatioConstraint")
		ca.Parent = closeButton
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0.5, 0)
		cc.Parent = closeButton
		local cp = Instance.new("UIPadding")
		cp.PaddingTop, cp.PaddingBottom = UDim.new(0.28, 0), UDim.new(0.28, 0)
		cp.Parent = closeButton

		row = Instance.new("ScrollingFrame")
		row.Name = "Row"
		row.BackgroundTransparency = 1
		row.BorderSizePixel = 0
		row.ScrollingDirection = Enum.ScrollingDirection.X
		row.AutomaticCanvasSize = Enum.AutomaticSize.X
		row.CanvasSize = UDim2.new()
		row.ScrollBarThickness = 0
		row.ElasticBehavior = Enum.ElasticBehavior.Always
		row.Parent = panel
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Parent = row

		click = Instance.new("Sound")
		click.Name = "ShopClick"
		click.SoundId = Shop.Click.id
		click.Volume = Shop.Click.volume
		click.Parent = g
		squeal = Instance.new("Sound")
		squeal.Name = "ShopSnap"
		squeal.SoundId = Kept.Squeal.id
		squeal.PlaybackSpeed = Shop.SnapPitch
		squeal.Volume = Shop.SnapVolume
		squeal.Parent = g

		g.Parent = player:WaitForChild("PlayerGui")
		layout()

		-- the counter's prompt, on this screen only: it opens a screen, nothing more
		local at = Lobby.Origin
			* CFrame.new(Shop.CounterAt[1], Shop.CounterAt[2], Shop.CounterAt[3])
		local part = Instance.new("Part")
		part.Name = "ShopCounter"
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Transparency = 1
		part.Size = Vector3.one * 0.2
		part.CFrame = at
		local attachment = Instance.new("Attachment")
		attachment.Parent = part
		local prompt = Instance.new("ProximityPrompt")
		prompt.Style = Enum.ProximityPromptStyle.Custom -- drawn by ButtonView, as every button
		prompt.ActionText = Shop.Words.open
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.MaxActivationDistance = Shop.CounterReach
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = attachment
		part.Parent = Workspace
		counter = part

		table.insert(connections, prompt.Triggered:Connect(openShop))
		table.insert(
			connections,
			topButton.Activated:Connect(function()
				spring(topPop)
				openShop()
			end)
		)
		-- a press that shuts it, once it's up: the click that opened it can land on the backdrop
		-- appearing under it in the same beat
		local function shut()
			if os.clock() - openedAt >= Shop.SlideIn then
				close()
			end
		end
		table.insert(connections, closeButton.Activated:Connect(shut))
		table.insert(connections, backdrop.Activated:Connect(shut))
		table.insert(
			connections,
			player:GetAttributeChangedSignal(WrapColours.Attribute):Connect(function()
				if open then
					refresh(worn)
				end
			end)
		)
		local cam = Workspace.CurrentCamera
		if cam then
			table.insert(connections, cam:GetPropertyChangedSignal("ViewportSize"):Connect(layout))
		end
		table.insert(
			connections,
			GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layout)
		)
		table.insert(
			connections,
			RunService.Heartbeat:Connect(function(dt: number)
				since += dt
				if since >= LOOK_EVERY then
					since = 0
					look()
				end
			end)
		)
	end

	function system.stop(_: any)
		open = false
		if stepping then
			stepping:Disconnect()
			stepping = nil
		end
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		clear()
		if gui then
			gui:Destroy()
			gui = nil
		end
		if counter then
			counter:Destroy()
			counter = nil
		end
	end

	return system
end

return ShopView
