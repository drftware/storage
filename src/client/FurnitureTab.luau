--!strict
--[[
	FurnitureTab: the counter's furniture, the shop's second tab (S5-03g4b, D-333, D-334). The
	moment: back from a climb you walk up to the counter, flip to Furniture, and this week's pieces
	turn slowly in their cards, each with its price; you tap the camp bed's, your cash ticks down
	in a rattle of coins, the bed drops into its box with the job box lid's clunk, and the card
	says it's in your box. Fortnite's item shop and Animal Crossing's Nook's Cranny (a stock that
	changes), Lethal Company's ship store (furniture bought with the run's pay).

	The stock is worked out here from the server's clock (`Furniture.stock`), as the server does;
	your cash and what you own come from the server (`Furniture.ShelfRemote`) each time the tab
	shows. Buy fires `Furniture.Remote` and the card stays pressed until `Furniture.BoughtRemote`
	answers, which it does only once the save is written: never yours before it says "". Any
	other answer settles the card back to what the server says ("notStocked": the week turned,
	so the tab deals this week's pieces). A price you can't pay is dimmed; pressing it nudges your
	cash with a dull click, no words. A piece at its cap says Owned, with no Buy.

	Each card's piece is the home's own art (`Home.template()`'s parts for its `Specs.Pieces`),
	in a ViewportFrame, framed from its parts' boxes in `Specs.Parts`. Floor pieces turn; wall and
	ceiling pieces (bare behind) sway either side of facing you. ShopView hosts it: the panel, the
	tabs, opening and closing; every feel number is `Shop`'s.

	After the pieces come the name card's styles for sale (StyleCards, S5-03g3d2), which share
	this purse: a style bought ticks it down, and a piece bought restates the styles' prices.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Cash = require(ReplicatedStorage.Shared.Cash)
local Coins = require(ReplicatedStorage.Shared.Coins)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local Home = require(ReplicatedStorage.Shared.Home)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Specs = require(ReplicatedStorage.Shared.Home.Specs)
local StyleCards = require(script.Parent.StyleCards)

local INK = Lobby.Ink
local FILL_WARM = Color3.fromRGB(CutFree.Fill.r, CutFree.Fill.g, CutFree.Fill.b)
local INK_WARM = Color3.fromRGB(CutFree.Ink.r, CutFree.Ink.g, CutFree.Ink.b)
local GOLD = Color3.fromRGB(240, 196, 92) -- money, as the job box's purse shows it
local CARD = Color3.fromRGB(40, 35, 31) -- warmer than a wrap's card: the home's calm
local WELL = Color3.fromRGB(12, 12, 14)
local PANEL = Color3.fromRGB(20, 20, 23)
local CAMERA_FOV = 30
-- Seconds a buy waits for its answer before the card settles back anyway (a lost answer).
local GIVE_UP = 8

local POP = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SPRING = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HOLD = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DROP = TweenInfo.new(Shop.DropTime, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local SETTLE = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local FurnitureTab = {}

-- What the tab needs from the shop hosting it.
export type Host = {
	click: (pitch: number) -> (), -- the shop's press click at a pitch
}
-- Your cash in the header, shared with the shop's other tabs that sell for cash (UnitsTab).
export type Wallet = {
	show: (on: boolean) -> (),
	set: (amount: number) -> (), -- shows `amount` at once
	spend: (to: number) -> (), -- ticks down to `to` in a rattle of coins
	nudge: () -> (), -- a press on a price you can't pay: the cash nudges with a dull click
}
export type Tab = {
	purse: Frame, -- your cash: the host places it in the panel's header
	wallet: Wallet,
	show: () -> (), -- deals this week's cards (made on the first show) and asks the server
	hide: () -> (),
	clear: () -> (), -- the cards gone: the shop shut
	layout: (cardHeight: number) -> (),
	step: (dt: number) -> (),
	destroy: () -> (),
}

type Card = {
	piece: Furniture.Piece,
	frame: Frame,
	pop: UIScale,
	stage: Frame, -- the piece's view: dropped into its box on a buy
	stageScale: UIScale,
	camera: Camera,
	centre: Vector3,
	dist: number,
	sway: boolean,
	phase: number,
	badge: TextLabel,
	badgePop: UIScale,
	button: TextButton,
	buttonPop: UIScale,
	buttonRing: UIStroke,
	state: Furniture.Card?,
	owned: number,
	waiting: number, -- os.clock a buy went out, or -1
	inBox: boolean, -- saying it's in your box
}

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function label(parent: Instance, name: string, colour: Color3): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	t.TextScaled = true
	t.TextColor3 = colour
	t.Parent = parent
	return t
end

-- Piece `id`'s parts' box in its own frame, from Specs (its middle and half its diagonal).
-- Piece `id`'s parts, painted as the template holds them, cloned into `viewport`: no lights,
-- scripts or sounds. Nothing when the place lacks its art.
local function dress(viewport: ViewportFrame, template: Model, id: string)
	if not Home.has(template, id) then
		return
	end
	local names: { string } = Specs.Pieces[id] or {}
	for _, name in names do
		local found = template:FindFirstChild(name, true)
		if found and found:IsA("BasePart") then
			local p = found:Clone()
			p.Anchored = true
			for _, d in p:GetDescendants() do
				if d:IsA("Light") or d:IsA("LuaSourceContainer") or d:IsA("Sound") then
					d:Destroy()
				end
			end
			p.Parent = viewport
		end
	end
end

local function bounds(id: string): (Vector3, number)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	local names: { string } = Specs.Pieces[id] or {}
	for _, name in names do
		local p = Specs.Parts[name]
		if p then
			local c = Vector3.new(p.Centre[1], p.Centre[2], p.Centre[3])
			local h = Vector3.new(p.Size[1], p.Size[2], p.Size[3]) / 2
			lo, hi = lo:Min(c - h), hi:Max(c + h)
		end
	end
	if lo.X > hi.X then
		return Vector3.new(0, 1, 0), 1.5
	end
	return (lo + hi) / 2, (hi - lo).Magnitude / 2
end

-- Piece `id` drawn still in `viewport` as its counter card shows it, seen from the front corner
-- (S5-03g4c2: the job box's card and Arrange's tray). Lit as the card is; framed to fill it.
function FurnitureTab.picture(viewport: ViewportFrame, id: string)
	viewport.Ambient = Color3.fromRGB(165, 155, 145)
	viewport.LightColor = Color3.fromRGB(255, 236, 210)
	viewport.LightDirection = Vector3.new(-0.5, -1, 0.6)
	local template = Home.template()
	if template then
		dress(viewport, template, id)
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = CAMERA_FOV
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local centre, radius = bounds(id)
	local a, tilt = math.rad(-35), math.rad(Shop.PieceTilt)
	local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
	local dist = radius / math.sin(math.rad(CAMERA_FOV / 2)) * 1.04
	camera.CFrame = CFrame.lookAt(
		centre + (dir * math.cos(tilt) + Vector3.yAxis * math.sin(tilt)) * dist,
		centre
	)
end

function FurnitureTab.new(panel: Frame, row: ScrollingFrame, host: Host): Tab
	local cards: { Card } = {}
	local byId: { [string]: Card } = {}
	local links: { RBXScriptConnection } = {}
	local cardLinks: { RBXScriptConnection } = {} -- the cards' buttons
	local cash = 0
	local known = false -- the server has answered the shelf since the tab showed
	local asking = false
	local shown = false
	local week = -1 -- the stock's week the cards show
	local bought: RBXScriptConnection? = nil
	local spending: Tween? = nil
	local spendFrom, spendTo, lastTick, tickTurn = 0, 0, -math.huge, 1
	local styles: StyleCards.Shelf -- the name card's styles after the pieces (made below)

	local purse = Instance.new("Frame")
	purse.Name = "Cash"
	purse.AnchorPoint = Vector2.new(1, 0)
	purse.BackgroundColor3 = PANEL
	purse.BackgroundTransparency = 0.08
	purse.Visible = false
	purse.Parent = panel
	corner(purse, UDim.new(0.5, 0))
	local purseRim = Instance.new("UIStroke")
	purseRim.Color = GOLD
	purseRim.Thickness = 1.5
	purseRim.Transparency = 0.35
	purseRim.Parent = purse
	local pursePop = Instance.new("UIScale")
	pursePop.Parent = purse
	local purseText = label(purse, "Figure", GOLD)
	purseText.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
	purseText.Size = UDim2.fromScale(1, 1)
	purseText.Text = ""
	local pp = Instance.new("UIPadding")
	pp.PaddingTop, pp.PaddingBottom = UDim.new(0.2, 0), UDim.new(0.2, 0)
	pp.PaddingLeft, pp.PaddingRight = UDim.new(0.12, 0), UDim.new(0.12, 0)
	pp.Parent = purseText
	local counted = Instance.new("NumberValue")
	counted.Name = "Counted"
	counted.Parent = purse

	local function sound(spec: {
		id: string,
		from: number,
		length: number,
		volume: number,
		pitch: number?,
	}): Sound
		local s = Instance.new("Sound")
		s.SoundId = spec.id
		s.Volume = spec.volume
		s.PlaybackSpeed = spec.pitch or 1
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
		s.Parent = purse
		return s
	end
	-- two ticks taking turns, so a fast run isn't cut short each time one starts again
	local ticks = { sound(Coins.Tick), sound(Coins.Tick) }
	local clunk = sound(Shop.Clunk)

	-- A card's button for its state: the price to Buy, the price dimmed, Owned; pressed while a
	-- buy is out; In your box just after one lands.
	local function paint(card: Card)
		local b, ring = card.button, card.buttonRing
		local state = card.state
		b.TextTransparency = 0
		if card.inBox then
			b.Text = Shop.Words.inBox
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = WELL, GOLD, 0.1
			ring.Color, ring.Transparency = GOLD, 0.15
		elseif state == "buy" then
			b.Text = Cash.text(card.piece.price)
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = FILL_WARM, INK_WARM, 0.05
			ring.Color, ring.Transparency = INK_WARM, 0.2
		elseif state == "short" then
			b.Text = Cash.text(card.piece.price)
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = WELL, INK, 0.3
			b.TextTransparency = Shop.TabDim
			ring.Color, ring.Transparency = INK, 0.8
		elseif state == "capped" then
			b.Text = Shop.Words.owned
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = WELL, INK, 1
			ring.Color, ring.Transparency = INK, 0.8
		else
			b.Text = ""
			b.BackgroundTransparency = 1
			ring.Transparency = 1
		end
		if card.waiting >= 0 then
			b.BackgroundTransparency = 1 - (1 - b.BackgroundTransparency) * Shop.Dim
			b.TextTransparency = 1 - Shop.Dim
		end
		card.badge.Visible = card.owned > 0
		card.badge.Text = `×{card.owned}`
	end

	-- Every card's state from your cash and what you own (the badge's count as the server said).
	local function restate()
		for _, card in cards do
			card.state = if known then Furniture.card(card.piece.id, cash, card.owned) else nil
			paint(card)
		end
		styles.restate(cash)
	end

	local function setPurse(amount: number)
		local run = spending
		if run then
			spending = nil
			run:Cancel()
		end
		counted.Value = amount
		purseText.Text = Cash.text(amount)
	end

	-- Your cash ticking down to `to`: a fast rattle, each tick lower, landing with a small pop.
	local function spend(to: number)
		local from = counted.Value
		if to >= from then
			setPurse(to)
			return
		end
		local run = spending
		if run then
			run:Cancel()
		end
		spendFrom, spendTo = from, to
		local tween = TweenService:Create(
			counted,
			TweenInfo.new(Shop.SpendTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Value = to }
		)
		spending = tween
		tween.Completed:Connect(function(state: Enum.PlaybackState)
			if state ~= Enum.PlaybackState.Completed or spending ~= tween then
				return
			end
			spending = nil
			purseText.Text = Cash.text(to)
			pursePop.Scale = 1.12
			TweenService:Create(pursePop, SETTLE, { Scale = 1 }):Play()
		end)
		tween:Play()
	end

	table.insert(
		links,
		counted.Changed:Connect(function(v: number)
			if spending == nil then
				return
			end
			purseText.Text = Cash.text(v)
			local now = os.clock()
			if now - lastTick < Cash.TickGap then
				return
			end
			lastTick = now
			local share = if spendFrom > spendTo then (spendFrom - v) / (spendFrom - spendTo) else 1
			local t = ticks[tickTurn]
			tickTurn = tickTurn % #ticks + 1
			t.PlaybackSpeed = (Coins.Tick.pitch or 1) * (1 - Shop.SpendFall * share)
			t.TimePosition = Coins.Tick.from
			t:Play()
		end)
	)

	-- Your cash nudged side to side with a dull click: the press on a price you can't pay.
	local function nudge()
		host.click(Shop.ShortPitch)
		local start = os.clock()
		task.spawn(function()
			while os.clock() - start < Shop.ShortNudge and purse.Parent do
				local t = (os.clock() - start) / Shop.ShortNudge
				purse.Rotation = math.sin(t * math.pi * 6) * 6 * (1 - t)
				task.wait()
			end
			purse.Rotation = 0
		end)
	end

	local function remote(name: string): Instance?
		local folder = ReplicatedStorage:FindFirstChild(Shop.RemoteFolder)
		return if folder then folder:FindFirstChild(name) else nil
	end

	-- Asks the server for your cash and what you own (yields in its own thread) and applies it.
	local function ask()
		if asking then
			return
		end
		asking = true
		task.spawn(function()
			local r = remote(Furniture.ShelfRemote)
			local answer: unknown = nil
			if r and r:IsA("RemoteFunction") then
				local ok, got = pcall(r.InvokeServer, r)
				answer = if ok then got else nil
			end
			asking = false
			local shelf = Furniture.read(answer)
			if shelf and shown then
				known = true
				cash = shelf.cash
				if spending == nil then
					setPurse(cash)
				end
				for _, card in cards do
					if card.waiting < 0 then
						card.owned = shelf.owned[card.piece.id] or 0
					end
				end
				restate()
			end
		end)
	end

	local press: (card: Card) -> () -- made below

	-- One card for `piece`, its art turning in a viewport from `template`.
	local function makeCard(piece: Furniture.Piece, order: number, template: Model?): Card
		local frame = Instance.new("Frame")
		frame.Name = piece.id
		frame.LayoutOrder = order
		frame.BackgroundColor3 = CARD
		frame.BorderSizePixel = 0
		corner(frame, UDim.new(0.08, 0))
		local rim = Instance.new("UIStroke")
		rim.Color = GOLD
		rim.Transparency = 0.75
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Parent = frame
		local pop = Instance.new("UIScale")
		pop.Scale = 0
		pop.Parent = frame

		local stage = Instance.new("Frame")
		stage.Name = "Stage"
		stage.BackgroundTransparency = 1
		stage.AnchorPoint = Vector2.new(0.5, 0)
		stage.Position = UDim2.fromScale(0.5, 0)
		stage.Size = UDim2.fromScale(1, 0.64)
		stage.Parent = frame
		local stageScale = Instance.new("UIScale")
		stageScale.Parent = stage
		local viewport = Instance.new("ViewportFrame")
		viewport.Name = "Piece"
		viewport.BackgroundTransparency = 1
		viewport.Size = UDim2.fromScale(1, 1)
		viewport.Ambient = Color3.fromRGB(165, 155, 145)
		viewport.LightColor = Color3.fromRGB(255, 236, 210)
		viewport.LightDirection = Vector3.new(-0.5, -1, 0.6)
		viewport.Parent = stage
		local camera = Instance.new("Camera")
		camera.FieldOfView = CAMERA_FOV
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		if template then
			dress(viewport, template, piece.id)
		end
		local centre, radius = bounds(piece.id)

		local badge = label(frame, "Owned", INK)
		badge.AnchorPoint = Vector2.new(1, 0)
		badge.Position = UDim2.fromScale(0.94, 0.04)
		badge.Size = UDim2.fromScale(0.3, 0.1)
		badge.BackgroundColor3 = WELL
		badge.BackgroundTransparency = 0.25
		badge.Visible = false
		badge.ZIndex = 2
		corner(badge, UDim.new(0.5, 0))
		local bpad = Instance.new("UIPadding")
		bpad.PaddingTop, bpad.PaddingBottom = UDim.new(0.14, 0), UDim.new(0.14, 0)
		bpad.Parent = badge
		local badgePop = Instance.new("UIScale")
		badgePop.Parent = badge

		local caption = label(frame, "Label", INK)
		caption.Position = UDim2.fromScale(0.04, 0.65)
		caption.Size = UDim2.fromScale(0.92, 0.12)
		caption.Text = piece.name

		local button = Instance.new("TextButton")
		button.Name = "Button"
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Position = UDim2.fromScale(0.5, 0.95)
		button.Size = UDim2.fromScale(0.84, 0.15)
		button.AutoButtonColor = false
		button.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		button.TextScaled = true
		button.Text = ""
		button.BackgroundTransparency = 1
		button.ZIndex = 2
		button.Parent = frame
		corner(button, UDim.new(0.5, 0))
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

		local card: Card = {
			piece = piece,
			frame = frame,
			pop = pop,
			stage = stage,
			stageScale = stageScale,
			camera = camera,
			centre = centre,
			dist = radius / math.sin(math.rad(CAMERA_FOV / 2)) * 1.04,
			sway = piece.stands ~= "Floor",
			phase = order * 0.9,
			badge = badge,
			badgePop = badgePop,
			button = button,
			buttonPop = buttonPop,
			buttonRing = ring,
			state = nil,
			owned = 0,
			waiting = -1,
			inBox = false,
		}
		table.insert(
			cardLinks,
			button.Activated:Connect(function()
				press(card)
			end)
		)
		paint(card)
		return card
	end

	local function clear()
		for _, c in cardLinks do
			c:Disconnect()
		end
		table.clear(cardLinks)
		for _, card in cards do
			card.frame:Destroy()
		end
		table.clear(cards)
		table.clear(byId)
		week = -1
	end

	-- This week's cards in the row, dealt out left to right.
	local function deal()
		local now = Workspace:GetServerTimeNow()
		local w = Furniture.week(now)
		if w ~= week then
			clear()
			week = w
			local template = Home.template()
			for i, id in Furniture.stock(now) do
				local piece = Furniture.byId(id)
				if piece then
					local card = makeCard(piece, 100 + i, template)
					table.insert(cards, card)
					byId[id] = card
				end
			end
		end
		for i, card in cards do
			card.frame.Parent = row
			card.frame.Visible = true
			card.pop.Scale = 0
			task.delay(Shop.SlideIn * 0.4 + (i - 1) * Shop.DealEvery, function()
				if shown and card.frame.Parent then
					TweenService:Create(card.pop, POP, { Scale = 1 }):Play()
				end
			end)
		end
		restate()
	end

	-- The buy landed: the piece drops into its box with the lid's clunk, the card says it's in
	-- your box and its owned count pops, then its price (or Owned) comes back.
	local function landed(card: Card, owned: number)
		local stage, scale = card.stage, card.stageScale
		TweenService:Create(stage, DROP, { Position = UDim2.fromScale(0.5, 0.42) }):Play()
		TweenService:Create(scale, DROP, { Scale = 0.12 }):Play()
		task.delay(Shop.DropTime, function()
			clunk.TimePosition = Shop.Clunk.from
			clunk:Play()
			card.inBox = true
			card.owned = owned -- the count goes up as the piece lands, not before
			card.state = Furniture.card(card.piece.id, cash, owned)
			paint(card)
			card.buttonPop.Scale = 1.12
			TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
			card.badgePop.Scale = 1.5
			TweenService:Create(card.badgePop, POP, { Scale = 1 }):Play()
			stage.Position = UDim2.fromScale(0.5, 0)
			scale.Scale = 0
			task.delay(0.25, function()
				TweenService:Create(scale, POP, { Scale = 1 }):Play()
			end)
			task.delay(Shop.InBoxFor, function()
				card.inBox = false
				paint(card)
			end)
		end)
	end

	-- The server's answer to a buy: the id, your cash, how many you own, and "" or why not.
	local function onBought(id: unknown, newCash: unknown, owned: unknown, refusal: unknown)
		if
			type(id) ~= "string"
			or type(newCash) ~= "number"
			or type(owned) ~= "number"
			or type(refusal) ~= "string"
		then
			return
		end
		local card = byId[id]
		if not (shown and card) then
			return
		end
		card.waiting = -1
		TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
		local was = cash
		cash = newCash
		known = true
		if refusal == "" then
			if newCash < was then
				spend(newCash)
			else
				setPurse(newCash)
			end
			landed(card, owned)
		else
			card.owned = owned
			setPurse(newCash) -- a settle: the coins never tick for a buy that didn't happen
			if refusal == "notStocked" then
				task.delay(0.3, function()
					if shown then
						week = -1
						deal()
					end
				end)
			end
		end
		restate()
	end

	function press(card: Card)
		if card.waiting >= 0 or card.inBox or card.pop.Scale < 0.9 then
			return
		end
		if card.state == "short" then
			nudge()
			return
		end
		if card.state ~= "buy" then
			return -- Owned, or not answered yet: nothing to fix, so nothing said
		end
		local r = remote(Furniture.Remote)
		if not (r and r:IsA("RemoteEvent")) then
			return
		end
		host.click(1)
		card.waiting = os.clock()
		card.buttonPop.Scale = Shop.Pressed
		TweenService:Create(card.buttonPop, HOLD, { Scale = 0.94 }):Play()
		paint(card)
		r:FireServer(card.piece.id)
		local sent = card.waiting
		task.delay(GIVE_UP, function()
			if card.waiting == sent then
				card.waiting = -1
				TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
				paint(card)
				ask()
			end
		end)
	end

	styles = StyleCards.new(row, {
		click = host.click,
		nudge = nudge,
		cash = function(amount: number, spent: boolean)
			cash = amount
			if spent then
				spend(amount)
			elseif spending == nil then
				setPurse(amount)
			end
			restate()
		end,
	})

	local tab = {} :: Tab
	tab.purse = purse
	tab.wallet = {
		show = function(on: boolean)
			purse.Visible = on
		end,
		set = setPurse,
		spend = spend,
		nudge = nudge,
	}

	function tab.show()
		shown = true
		known = false
		purse.Visible = true
		if not bought then
			local r = remote(Furniture.BoughtRemote)
			if r and r:IsA("RemoteEvent") then
				bought = r.OnClientEvent:Connect(onBought)
			end
		end
		deal()
		ask()
		styles.show(#cards)
	end

	function tab.hide()
		shown = false
		purse.Visible = false
		for _, card in cards do
			card.frame.Visible = false
		end
		styles.hide()
	end

	function tab.clear()
		tab.hide()
		clear()
		styles.clear()
	end

	function tab.layout(cardHeight: number)
		for _, card in cards do
			card.frame.Size = UDim2.fromOffset(math.floor(cardHeight * Shop.CardAspect), cardHeight)
		end
		styles.layout(cardHeight)
	end

	function tab.step(_: number)
		local t = os.clock() * Shop.PieceSpin * math.pi * 2
		local tilt = math.rad(Shop.PieceTilt)
		local sway = math.rad(Shop.PieceSway)
		for _, card in cards do
			local a = if card.sway then math.sin(t + card.phase) * sway else t + card.phase
			local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
			local eye = card.centre
				+ (dir * math.cos(tilt) + Vector3.yAxis * math.sin(tilt)) * card.dist
			card.camera.CFrame = CFrame.lookAt(eye, card.centre)
		end
		styles.step()
	end

	function tab.destroy()
		tab.clear()
		for _, c in links do
			c:Disconnect()
		end
		table.clear(links)
		if bought then
			bought:Disconnect()
			bought = nil
		end
		styles.destroy()
		purse:Destroy()
	end

	return tab
end

return FurnitureTab
