--!strict
--[[
	StyleCards: the name card's other styles at the counter, on the Furniture tab after this
	week's pieces (S5-03g3d2, D-360, D-361). The moment: you see a friend's neon card glowing over
	their door, walk to the counter, flip to Furniture, and past this week's pieces there's your
	own name on a neon plate; you buy it, it swings down in its card with the clack it makes over
	a door, and the next time you open Arrange its chip is yours. Animal Crossing's Nook's Cranny
	sells wallpaper beside the furniture; Roblox games sell cosmetics for Robux bought once and
	kept, as this game's wraps are (S3-04a).

	Each card is the plate drawn flat (`LooksTab.plateFace`, the paint tab's own chip, larger),
	with your name in the style's font and ink: a ViewportFrame can't show the plate's lettering
	(a SurfaceGui never draws in one). It sways a little about its top edge, hung on the counter's
	rail, and the neon's letters breathe.

	What you own, your cash and the neon's Roblox price come from the server (`CardSale.
	ShelfRemote`) each time the tab shows. Buy fires `CardSale.Remote` and the button holds
	pressed until `CardSale.BoughtRemote` answers: "" and a cash style's price ticks off the shared
	purse with the coins' falling tick (FurnitureTab's), the plate swings down with the clack, and
	the button says Owned; "cash" nudges the purse; "had" says Owned; any other answer settles to
	the server's numbers, silent. No answer in `GIVE_UP` seconds settles and asks again. The neon
	goes through Roblox's own prompt from the server, at Roblox's price with the Robux mark; one
	that's off sale isn't dealt at all. FurnitureTab hosts it: the row, the purse, the deal.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CardSale = require(ReplicatedStorage.Shared.Home.CardSale)
local CardPlate = require(ReplicatedStorage.Shared.Home.CardPlate)
local Cash = require(ReplicatedStorage.Shared.Cash)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local Home = require(ReplicatedStorage.Shared.Home)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local LooksTab = require(script.Parent.LooksTab)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Specs = require(ReplicatedStorage.Shared.Home.Specs)

local INK = Lobby.Ink
local FILL_WARM = Color3.fromRGB(CutFree.Fill.r, CutFree.Fill.g, CutFree.Fill.b)
local INK_WARM = Color3.fromRGB(CutFree.Ink.r, CutFree.Ink.g, CutFree.Ink.b)
local GOLD = Color3.fromRGB(240, 196, 92) -- money, as the job box's purse shows it
local CARD = Color3.fromRGB(40, 35, 31) -- the furniture's cards' warm brown
local WELL = Color3.fromRGB(12, 12, 14)
local ROBUX = utf8.char(0xE002) -- Roblox's own Robux mark in its fonts
local PLATE = LooksTab.Plate
local SWING = Home.Holding.Card.Swing
-- Seconds a buy waits for its answer before the card settles back anyway (a lost answer).
local GIVE_UP = 8
-- Of the card's width, the plate's (and at most this much of the stage's height).
local PLATE_WIDE, PLATE_TALL = 0.84, 0.62

local POP = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SPRING = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HOLD = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FALL = TweenInfo.new(SWING.Seconds, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local GLINT = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local StyleCards = {}

-- What the cards need from the tab hosting them.
export type Host = {
	click: (pitch: number) -> (), -- the shop's press click at a pitch
	nudge: () -> (), -- the purse nudged with a dull click: a price you can't pay
	cash: (amount: number, spent: boolean) -> (), -- your cash now: ticked down to, or settled
}
export type Shelf = {
	show: (dealt: number) -> (), -- deals the cards in after `dealt` other cards, and asks
	hide: () -> (),
	clear: () -> (), -- the cards gone: the shop shut
	restate: (cash: number) -> (), -- your cash changed (a piece bought)
	layout: (cardHeight: number) -> (),
	step: () -> (),
	destroy: () -> (),
}

-- A card's state: its price to Buy, dimmed (short of cash), Owned, or off sale (not dealt).
type State = CardSale.Card | "off"

type Card = {
	id: string,
	robux: boolean, -- sold through Roblox's prompt, not for cash
	frame: Frame,
	pop: UIScale,
	rim: UIStroke,
	hang: Frame, -- the plate's pivot at its top edge: swayed and scaled to the card
	fit: UIScale,
	plate: Frame,
	shadow: Frame,
	glow: UIStroke?, -- the neon letters' glow
	button: TextButton,
	buttonPop: UIScale,
	buttonRing: UIStroke,
	state: State?,
	waiting: number, -- os.clock a buy went out, or -1
	landing: boolean, -- bought, the plate still swinging down: Owned shows as it lands
	phase: number,
}

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function styleOf(id: string): Specs.CardStyle?
	for _, style in Specs.Cards do
		if style.Id == id then
			return style
		end
	end
	return nil
end

function StyleCards.new(row: ScrollingFrame, host: Host): Shelf
	local cards: { Card } = {}
	local byId: { [string]: Card } = {}
	local links: { RBXScriptConnection } = {}
	local owned: { [string]: boolean } = {}
	local robux: { [string]: number } = {} -- the Robux styles' prices on Roblox, as last told
	local cash = 0
	local known = false -- the server has answered since the tab showed
	local asking = false
	local shown = false
	local bought: RBXScriptConnection? = nil

	local clack = Instance.new("Sound") -- the plate's clack as it lands, the hall's
	clack.SoundId = SWING.Sound
	clack.Volume = SWING.Volume
	clack.PlaybackSpeed = SWING.Pitch
	clack.PlaybackRegionsEnabled = true
	clack.PlaybackRegion = NumberRange.new(SWING.From, SWING.From + SWING.Length)
	clack.Parent = row

	local function remote(name: string): Instance?
		local folder = ReplicatedStorage:FindFirstChild(Shop.RemoteFolder)
		return if folder then folder:FindFirstChild(name) else nil
	end

	local function stateOf(card: Card): State?
		if not known then
			return nil
		elseif owned[card.id] then
			return "owned"
		elseif card.robux and robux[card.id] == nil then
			return "off"
		end
		return CardSale.card(card.id, cash, false)
	end

	-- A card's button for its state: the price to Buy (cash, or Robux with Roblox's mark), the
	-- price dimmed, Owned; pressed while a buy is out. A style off sale isn't dealt.
	local function paint(card: Card)
		local b, ring = card.button, card.buttonRing
		local state = card.state
		b.TextTransparency = 0
		if state == "buy" or state == "short" then
			local price = robux[card.id]
			b.Text = if not card.robux
				then Cash.text(CardSale.price(card.id) or 0)
				elseif price and price > 0 then `{ROBUX} {price}`
				else Shop.Words.buy
			if state == "buy" then
				b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency =
					FILL_WARM, INK_WARM, 0.05
				ring.Color, ring.Transparency = INK_WARM, 0.2
			else
				b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = WELL, INK, 0.3
				b.TextTransparency = Shop.TabDim
				ring.Color, ring.Transparency = INK, 0.8
			end
		elseif state == "owned" then
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
		card.frame.Visible = shown and state ~= "off"
	end

	local function restate()
		for _, card in cards do
			if card.waiting < 0 and not card.landing then
				card.state = stateOf(card)
			end
			paint(card)
		end
	end

	-- Asks the server what you own, your cash and the neon's price (in its own thread).
	local function ask()
		if asking then
			return
		end
		asking = true
		task.spawn(function()
			local r = remote(CardSale.ShelfRemote)
			local answer: unknown = nil
			if r and r:IsA("RemoteFunction") then
				local ok, got = pcall(r.InvokeServer, r)
				answer = if ok then got else nil
			end
			asking = false
			local shelf = CardSale.read(answer)
			if shelf and shown then
				known = true
				owned, robux, cash = shelf.owned, shelf.robux, shelf.cash
				host.cash(cash, false)
				restate()
			end
		end)
	end

	local press: (card: Card) -> () -- made below

	-- One card for `style`, its plate drawn from `template`'s art.
	local function makeCard(style: Specs.CardStyle, order: number, template: Model): Card
		local frame = Instance.new("Frame")
		frame.Name = `card{style.Id}`
		frame.LayoutOrder = order
		frame.BackgroundColor3 = CARD
		frame.BorderSizePixel = 0
		frame.Visible = false
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
		stage.Size = UDim2.fromScale(1, 0.64)
		stage.Parent = frame
		local hang = Instance.new("Frame") -- no size: its point is the plate's top edge
		hang.Name = "Hang"
		hang.BackgroundTransparency = 1
		hang.Size = UDim2.new()
		hang.Position = UDim2.fromScale(0.5, 0.3)
		hang.Parent = stage
		local fit = Instance.new("UIScale")
		fit.Parent = hang
		local shadow = Instance.new("Frame") -- the plate's shadow on the card, a little below
		shadow.Name = "Shadow"
		shadow.AnchorPoint = Vector2.new(0.5, 0)
		shadow.Position = UDim2.fromOffset(0, 3)
		shadow.Size = UDim2.fromOffset(PLATE.X, PLATE.Y)
		shadow.BackgroundColor3 = Color3.new(0, 0, 0)
		shadow.BackgroundTransparency = 0.55
		shadow.BorderSizePixel = 0
		corner(shadow, UDim.new(0, 6))
		shadow.Parent = hang
		local plate = Instance.new("Frame")
		plate.Name = "Plate"
		plate.AnchorPoint = Vector2.new(0.5, 0)
		plate.Size = UDim2.fromOffset(PLATE.X, PLATE.Y)
		LooksTab.plateFace(plate, style, template)
		plate.Parent = hang
		local name = plate:FindFirstChild("Name")
		local glow = if name then name:FindFirstChild("Glow") else nil

		local caption = Instance.new("TextLabel")
		caption.Name = "Label"
		caption.BackgroundTransparency = 1
		caption.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		caption.TextScaled = true
		caption.TextColor3 = INK
		caption.Position = UDim2.fromScale(0.04, 0.65)
		caption.Size = UDim2.fromScale(0.92, 0.12)
		caption.Text = CardSale.Names[style.Id] or style.Id
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
			id = style.Id,
			robux = style.Sold == "Robux",
			frame = frame,
			pop = pop,
			rim = rim,
			hang = hang,
			fit = fit,
			plate = plate,
			shadow = shadow,
			glow = if glow and glow:IsA("UIStroke") then glow else nil,
			button = button,
			buttonPop = buttonPop,
			buttonRing = ring,
			state = nil,
			waiting = -1,
			landing = false,
			phase = order * 1.3,
		}
		table.insert(
			links,
			button.Activated:Connect(function()
				press(card)
			end)
		)
		paint(card)
		return card
	end

	local function build()
		if #cards > 0 then
			return
		end
		local template = Home.template()
		if not template then
			return -- the place lacks the home's art: no plates to draw
		end
		for i, id in CardSale.Sold do
			local style = styleOf(id)
			if style then
				local card = makeCard(style, 200 + i, template)
				card.frame.Parent = row
				table.insert(cards, card)
				byId[id] = card
			end
		end
	end

	-- The buy landed: the plate swings out and falls back onto the card with the hall's clack, the
	-- rim glints and the button says Owned as it lands.
	local function landed(card: Card)
		local from = UDim2.fromOffset(PLATE.X, PLATE.Y * Shop.PlateSwingFrom)
		local to = UDim2.fromOffset(PLATE.X, PLATE.Y)
		card.landing = true
		card.plate.Size, card.shadow.Size = from, from
		TweenService:Create(card.plate, FALL, { Size = to }):Play()
		TweenService:Create(card.shadow, FALL, { Size = to }):Play()
		-- Bounce's first touch is at 1/2.75 of the fall: the clack lands on it, as over a door
		local touch = SWING.Seconds / 2.75
		task.delay(math.max(touch - SWING.Hit, 0), function()
			if shown then
				clack.TimePosition = SWING.From
				clack:Play()
			end
		end)
		task.delay(touch, function()
			card.landing = false
			card.state = stateOf(card)
			paint(card)
			card.buttonPop.Scale = 1.12
			TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
			card.rim.Transparency = 0.1
			TweenService:Create(card.rim, GLINT, { Transparency = 0.75 }):Play()
		end)
	end

	-- The server's answer to a buy: the style, your cash, and "" or why not.
	local function onBought(id: unknown, newCash: unknown, refusal: unknown)
		if type(id) ~= "string" or type(newCash) ~= "number" or type(refusal) ~= "string" then
			return
		end
		local card = byId[id]
		if not (shown and card) then
			return
		end
		card.waiting = -1
		TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
		if refusal == "notLoaded" then
			paint(card) -- no save to read numbers from: the card settles as it was
			ask()
			return
		end
		local was = cash
		cash, known = newCash, true
		if refusal == "" then
			owned[id] = true
			landed(card) -- first, so the restate below leaves its price showing until it lands
			host.cash(newCash, newCash < was) -- a cash style's price ticks off in coins
			paint(card)
			return
		end
		if refusal == "had" then
			owned[id] = true
		end
		host.cash(newCash, false) -- a settle: the coins never tick for a buy that didn't happen
		if refusal == "cash" then
			host.nudge()
		elseif refusal == "off" then
			ask() -- taken off sale since the tab showed: the card goes
		end
		restate()
	end

	function press(card: Card)
		if card.waiting >= 0 or card.pop.Scale < 0.9 then
			return
		end
		if card.state == "short" then
			host.nudge()
			return
		end
		if card.state ~= "buy" then
			return -- Owned, or not answered yet: nothing to fix, so nothing said
		end
		local r = remote(CardSale.Remote)
		if not (r and r:IsA("RemoteEvent")) then
			return
		end
		host.click(1)
		card.waiting = os.clock()
		card.buttonPop.Scale = Shop.Pressed
		TweenService:Create(card.buttonPop, HOLD, { Scale = 0.94 }):Play()
		paint(card)
		r:FireServer(card.id)
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

	local shelf = {} :: Shelf

	function shelf.show(dealt: number)
		shown = true
		known = false
		if not bought then
			local r = remote(CardSale.BoughtRemote)
			if r and r:IsA("RemoteEvent") then
				bought = r.OnClientEvent:Connect(onBought)
			end
		end
		build()
		for i, card in cards do
			card.pop.Scale = 0
			card.waiting = -1
			card.landing = false
			card.plate.Size, card.shadow.Size =
				UDim2.fromOffset(PLATE.X, PLATE.Y), UDim2.fromOffset(PLATE.X, PLATE.Y)
			card.state = nil
			paint(card) -- dealt with a blank button until the server answers
			task.delay(Shop.SlideIn * 0.4 + (dealt + i - 1) * Shop.DealEvery, function()
				if shown and card.frame.Parent then
					TweenService:Create(card.pop, POP, { Scale = 1 }):Play()
				end
			end)
		end
		ask()
	end

	function shelf.hide()
		shown = false
		for _, card in cards do
			card.frame.Visible = false
		end
	end

	function shelf.clear()
		shelf.hide()
		for _, c in links do
			c:Disconnect()
		end
		table.clear(links)
		for _, card in cards do
			card.frame:Destroy()
		end
		table.clear(cards)
		table.clear(byId)
	end

	function shelf.restate(amount: number)
		cash = amount
		restate()
	end

	function shelf.layout(cardHeight: number)
		local wide = math.floor(cardHeight * Shop.CardAspect)
		local k = math.min(wide * PLATE_WIDE / PLATE.X, cardHeight * 0.64 * PLATE_TALL / PLATE.Y)
		for _, card in cards do
			card.frame.Size = UDim2.fromOffset(wide, cardHeight)
			card.fit.Scale = k
			card.hang.Position = UDim2.new(0.5, 0, 0.5, -math.floor(PLATE.Y * k / 2))
		end
	end

	function shelf.step()
		local t = os.clock() * math.pi * 2
		for _, card in cards do
			card.hang.Rotation = math.sin(t * Shop.PlateSwayRate + card.phase) * Shop.PlateSway
			local glow = card.glow
			if glow then
				local breath = 0.5 + 0.5 * math.sin(t * Shop.PlateSwayRate * 0.8)
				glow.Transparency = CardPlate.Neon.Haze - Shop.PlateBreathe * breath
			end
		end
	end

	function shelf.destroy()
		shelf.clear()
		if bought then
			bought:Disconnect()
			bought = nil
		end
		clack:Destroy()
	end

	return shelf
end

return StyleCards
