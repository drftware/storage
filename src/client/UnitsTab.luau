--!strict
--[[
	UnitsTab: your home's sizes at the counter, the shop's third tab (S5-03h2, D-341; the home
	doc's ideas 30 and 31). The moment: back from a good climb you've saved up; you flip the
	counter's shop to Units and the Medium card's plan opens out from your little unit to its own;
	you tap its price, your cash ticks down, the room you have opens out to the new one over the
	steel's roll and lands on a knock, "More room!", and the card says it's yours. Bloxburg's and
	Adopt Me's house upgrades, Animal Crossing's house loan.

	The cards run from your size up (`Grow.ladder`): yours first, saying Yours, then each bigger
	size on sale with its price (Large and XL join with Robux, S5-03h3). Each card's plan is drawn
	from above, the door at its foot: the slot's whole box faint (room still to grow into), the
	card's size filled, and the size you have outlined inside it, so how much more room a size
	gives reads before any word. Your cash and size come from the server (`Grow.ShelfRemote`)
	each time the tab shows. Buy fires `Grow.Remote` and the card stays pressed until
	`Grow.GrownRemote` answers, which it does only once the save is written and your home is set
	up at its new size. A price you can't pay is dimmed; pressing it nudges your cash with a dull
	click, no words. ShopView hosts it, and FurnitureTab's purse is its cash (`Host.wallet`).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Cash = require(ReplicatedStorage.Shared.Cash)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local FurnitureTab = require(script.Parent.FurnitureTab)
local Grow = require(ReplicatedStorage.Shared.Home.Grow)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Sizes = require(ReplicatedStorage.Shared.Home.Sizes)

local INK = Lobby.Ink
local FILL_WARM = Color3.fromRGB(CutFree.Fill.r, CutFree.Fill.g, CutFree.Fill.b)
local INK_WARM = Color3.fromRGB(CutFree.Ink.r, CutFree.Ink.g, CutFree.Ink.b)
local GOLD = Color3.fromRGB(240, 196, 92) -- money, as the furniture's purse shows it
local CARD = Color3.fromRGB(40, 35, 31) -- the furniture's card: the home's calm
local WELL = Color3.fromRGB(12, 12, 14)
local FLOOR = Color3.fromRGB(196, 160, 118) -- a size's floor in its plan: the home's warm boards
-- Seconds a sale waits for its answer before the card settles back anyway (a lost answer).
local GIVE_UP = 8

local POP = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SPRING = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HOLD = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(0.3)
local PREVIEW = TweenInfo.new(Shop.GrowPreview, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local OPEN_OUT = TweenInfo.new(Shop.GrowTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local UnitsTab = {}

-- What the tab needs from the shop hosting it.
export type Host = {
	click: (pitch: number) -> (), -- the shop's press click at a pitch
	wallet: FurnitureTab.Wallet, -- your cash in the header
}
export type Tab = {
	show: () -> (), -- deals the cards from your size up and asks the server
	hide: () -> (),
	clear: () -> (), -- the cards gone: the shop shut
	layout: (cardHeight: number) -> (),
	destroy: () -> (),
}

type Card = {
	name: string,
	frame: Frame,
	pop: UIScale,
	rim: UIStroke,
	room: Frame, -- the card's size, filled
	have: Frame, -- the size you have, outlined
	headline: TextLabel,
	headlinePop: UIScale,
	button: TextButton,
	buttonPop: UIScale,
	buttonRing: UIStroke,
	state: Grow.Card?,
	waiting: number, -- os.clock a sale went out, or -1
	grown: boolean, -- just bought: the headline's up
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
	t.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
	t.TextScaled = true
	t.TextColor3 = colour
	t.Parent = parent
	return t
end

-- Size `name`'s box in its plan: a share of the slot's whole box across and deep.
local function footprint(name: string): UDim2
	local s, xl = Sizes.of(name), Sizes.of(Sizes.Biggest)
	return UDim2.fromScale(s.across / xl.across, s.deep / xl.deep)
end

function UnitsTab.new(panel: Frame, row: ScrollingFrame, host: Host): Tab
	local cards: { Card } = {}
	local byName: { [string]: Card } = {}
	local cardLinks: { RBXScriptConnection } = {}
	local cash = 0
	local size: string? = nil -- your home's size as the server last said
	local dealtFor = "" -- the size the cards were dealt from
	local known = false -- the server has answered since the tab showed
	local asking = false
	local shown = false
	local grownLink: RBXScriptConnection? = nil
	local tall = 0 -- the cards' height, from the host's last layout

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
		s.Parent = panel
		return s
	end
	local roll = sound(Shop.GrowRoll)
	local knock = sound(Shop.GrowKnock)

	-- A card's button for its state: the price to Buy, the price dimmed, Yours; pressed while a
	-- sale is out.
	local function paint(card: Card)
		local b, ring = card.button, card.buttonRing
		local state = card.state
		local price = Grow.price(card.name) or 0
		b.TextTransparency = 0
		if card.grown then
			b.Text = Shop.Words.yours
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = WELL, GOLD, 0.1
			ring.Color, ring.Transparency = GOLD, 0.15
		elseif state == "buy" then
			b.Text = Cash.text(price)
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = FILL_WARM, INK_WARM, 0.05
			ring.Color, ring.Transparency = INK_WARM, 0.2
		elseif state == "short" then
			b.Text = Cash.text(price)
			b.BackgroundColor3, b.TextColor3, b.BackgroundTransparency = WELL, INK, 0.3
			b.TextTransparency = Shop.TabDim
			ring.Color, ring.Transparency = INK, 0.8
		elseif state == "yours" then
			b.Text = Shop.Words.yours
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
	end

	local function restate()
		local have = size or Sizes.Start
		for _, card in cards do
			if not card.grown then
				card.state = if known then Grow.card(card.name, have, cash) else nil
			end
			paint(card)
		end
	end

	local function remote(name: string): Instance?
		local folder = ReplicatedStorage:FindFirstChild(Shop.RemoteFolder)
		return if folder then folder:FindFirstChild(name) else nil
	end

	local press: (card: Card) -> () -- made below

	-- One card for size `name`, its plan showing it against `have`, the size you have.
	local function makeCard(name: string, order: number, have: string): Card
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.LayoutOrder = order
		frame.BackgroundColor3 = CARD
		frame.BorderSizePixel = 0
		frame.Visible = false
		corner(frame, UDim.new(0.08, 0))
		local rim = Instance.new("UIStroke")
		rim.Color = GOLD
		rim.Transparency = 0.75
		rim.Thickness = 1.5
		rim.Parent = frame
		local pop = Instance.new("UIScale")
		pop.Scale = 0
		pop.Parent = frame

		local title = label(frame, "Title", INK)
		title.AnchorPoint = Vector2.new(0.5, 0)
		title.Position = UDim2.fromScale(0.5, 0.05)
		title.Size = UDim2.fromScale(0.8, 0.1)
		title.Text = name

		-- the plan from above, the door at its foot: the slot's whole box faint
		local plan = Instance.new("Frame")
		plan.Name = "Plan"
		plan.AnchorPoint = Vector2.new(0.5, 0)
		plan.Position = UDim2.fromScale(0.5, 0.19)
		plan.Size = UDim2.fromScale(0.8, 0.56)
		plan.BackgroundColor3 = WELL
		plan.BackgroundTransparency = 0.5
		plan.Parent = frame
		corner(plan, UDim.new(0, 3))
		local xl = Sizes.of(Sizes.Biggest)
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = xl.across / xl.deep
		aspect.Parent = plan
		local lot = Instance.new("UIStroke")
		lot.Color = INK
		lot.Transparency = 0.8
		lot.Thickness = 1
		lot.Parent = plan

		local room = Instance.new("Frame")
		room.Name = "Room"
		room.AnchorPoint = Vector2.new(0.5, 1)
		room.Position = UDim2.fromScale(0.5, 1)
		room.Size = footprint(name)
		room.BackgroundColor3 = FLOOR
		room.BackgroundTransparency = 0.2
		room.BorderSizePixel = 0
		room.Parent = plan
		local walls = Instance.new("UIStroke")
		walls.Color = INK_WARM
		walls.Thickness = 2
		walls.Transparency = 0.1
		walls.Parent = room

		local haveBox = Instance.new("Frame")
		haveBox.Name = "Have"
		haveBox.AnchorPoint = Vector2.new(0.5, 1)
		haveBox.Position = UDim2.fromScale(0.5, 1)
		haveBox.Size = footprint(have)
		haveBox.BackgroundTransparency = 1
		haveBox.Visible = name ~= have
		haveBox.Parent = plan
		local haveLine = Instance.new("UIStroke")
		haveLine.Color = INK
		haveLine.Thickness = 1.5
		haveLine.Transparency = 0.25
		haveLine.Parent = haveBox

		-- the door at the plan's foot, as wide as the units' roll-up door looks from above
		local door = Instance.new("Frame")
		door.Name = "Door"
		door.AnchorPoint = Vector2.new(0.5, 0.5)
		door.Position = UDim2.fromScale(0.5, 1)
		door.Size = UDim2.new(0.3, 0, 0, 4)
		door.BackgroundColor3 = GOLD
		door.BorderSizePixel = 0
		door.ZIndex = 2
		door.Parent = plan

		local headline = label(frame, "Headline", GOLD)
		headline.AnchorPoint = Vector2.new(0.5, 0.5)
		headline.Position = UDim2.fromScale(0.5, 0.45)
		headline.Size = UDim2.fromScale(0.9, 0.13)
		headline.Text = Shop.Words.grown
		headline.TextStrokeColor3 = WELL
		headline.TextStrokeTransparency = 0.2
		headline.ZIndex = 3
		headline.Visible = false
		local headlinePop = Instance.new("UIScale")
		headlinePop.Parent = headline

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
		bp.PaddingTop, bp.PaddingBottom = UDim.new(0.18, 0), UDim.new(0.18, 0)
		bp.Parent = button
		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Thickness = 1.5
		ring.Transparency = 1
		ring.Parent = button
		local buttonPop = Instance.new("UIScale")
		buttonPop.Parent = button

		local card: Card = {
			name = name,
			frame = frame,
			pop = pop,
			rim = rim,
			room = room,
			have = haveBox,
			headline = headline,
			headlinePop = headlinePop,
			button = button,
			buttonPop = buttonPop,
			buttonRing = ring,
			state = nil,
			waiting = -1,
			grown = false,
		}
		table.insert(
			cardLinks,
			button.Activated:Connect(function()
				press(card)
			end)
		)
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
		table.clear(byName)
		dealtFor = ""
	end

	-- The cards from your size up, dealt out left to right; each bigger size's plan opens out
	-- from yours to its own as it lands. Dealt again only when your size changed.
	local function deal()
		local have = size or Sizes.Start
		if have ~= dealtFor then
			clear()
			dealtFor = have
			for i, name in Grow.ladder(have) do
				local card = makeCard(name, 200 + i, have)
				table.insert(cards, card)
				byName[name] = card
			end
		end
		for i, card in cards do
			if tall > 0 then
				card.frame.Size = UDim2.fromOffset(math.floor(tall * Shop.CardAspect), tall)
			end
			card.frame.Parent = row
			card.frame.Visible = true
			card.pop.Scale = 0
			card.room.Size = if card.have.Visible then footprint(have) else footprint(card.name)
			task.delay(Shop.SlideIn * 0.4 + (i - 1) * Shop.DealEvery, function()
				if not (shown and card.frame.Parent) then
					return
				end
				TweenService:Create(card.pop, POP, { Scale = 1 }):Play()
				if card.have.Visible then
					TweenService:Create(card.room, PREVIEW, { Size = footprint(card.name) }):Play()
				end
			end)
		end
		restate()
	end

	-- Asks the server for your cash and size (yields in its own thread) and applies it.
	local function ask()
		if asking then
			return
		end
		asking = true
		task.spawn(function()
			local r = remote(Grow.ShelfRemote)
			local answer: unknown = nil
			if r and r:IsA("RemoteFunction") then
				local ok, got = pcall(r.InvokeServer, r)
				answer = if ok then got else nil
			end
			asking = false
			local shelf = Grow.read(answer)
			if not (shelf and shown) then
				return
			end
			known = true
			cash = shelf.cash
			host.wallet.set(cash)
			local moved = size ~= shelf.size
			size = shelf.size
			if moved or #cards == 0 then
				deal()
			else
				restate()
			end
		end)
	end

	-- The sale landed: the room you have opens out to the new one over the steel's roll, lands on
	-- a knock, "More room!" pops, the card says Yours; then the cards deal again from your size.
	local function landed(card: Card)
		roll.TimePosition = Shop.GrowRoll.from
		roll:Play()
		card.room.BackgroundTransparency = 0
		TweenService:Create(card.have, OPEN_OUT, { Size = card.room.Size }):Play()
		card.rim.Color, card.rim.Transparency = GOLD, 0
		task.delay(Shop.GrowTime, function()
			if not card.frame.Parent then
				return
			end
			roll:Stop()
			knock.TimePosition = Shop.GrowKnock.from
			knock:Play()
			card.grown = true
			paint(card)
			card.buttonPop.Scale = 1.12
			TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
			card.headline.Visible = true
			card.headline.TextTransparency = 0
			card.headlinePop.Scale = 0.4
			TweenService:Create(card.headlinePop, POP, { Scale = 1 }):Play()
			TweenService:Create(card.room, FADE, { BackgroundTransparency = 0.2 }):Play()
			TweenService:Create(card.rim, FADE, { Transparency = 0.75 }):Play()
			task.delay(Shop.GrowFor, function()
				if not (shown and card.frame.Parent) then
					return
				end
				TweenService:Create(card.headline, FADE, { TextTransparency = 1 }):Play()
				task.delay(FADE.Time, function()
					if shown and card.frame.Parent then
						deal() -- from your new size: the smaller card goes
					end
				end)
			end)
		end)
	end

	-- The server's answer to a sale: the size asked for, your cash, your size, "" or why not.
	local function onGrown(name: unknown, newCash: unknown, newSize: unknown, refusal: unknown)
		if
			type(name) ~= "string"
			or type(newCash) ~= "number"
			or type(newSize) ~= "string"
			or type(refusal) ~= "string"
		then
			return
		end
		local card = byName[name]
		if not (shown and card) then
			return
		end
		card.waiting = -1
		TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
		local was = cash
		cash = newCash
		known = true
		if refusal == "" then
			size = Sizes.of(newSize).name
			if newCash < was then
				host.wallet.spend(newCash)
			else
				host.wallet.set(newCash)
			end
			landed(card)
			restate()
			return
		end
		host.wallet.set(newCash) -- a settle: the coins never tick for a sale that didn't happen
		if refusal == "cash" then
			host.wallet.nudge()
		end
		if newSize ~= "" and Sizes.of(newSize).name ~= size then
			size = Sizes.of(newSize).name
			deal()
		else
			restate()
		end
	end

	function press(card: Card)
		if card.waiting >= 0 or card.grown or card.pop.Scale < 0.9 then
			return
		end
		if card.state == "short" then
			host.wallet.nudge()
			return
		end
		if card.state ~= "buy" then
			return -- Yours, or not answered yet: nothing to fix, so nothing said
		end
		for _, other in cards do
			if other.waiting >= 0 or other.grown then
				return -- one sale at a time
			end
		end
		local r = remote(Grow.Remote)
		if not (r and r:IsA("RemoteEvent")) then
			return
		end
		host.click(1)
		card.waiting = os.clock()
		card.buttonPop.Scale = Shop.Pressed
		TweenService:Create(card.buttonPop, HOLD, { Scale = 0.94 }):Play()
		paint(card)
		r:FireServer(card.name)
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

	local tab = {} :: Tab

	function tab.show()
		shown = true
		known = false
		host.wallet.show(true)
		if not grownLink then
			local r = remote(Grow.GrownRemote)
			if r and r:IsA("RemoteEvent") then
				grownLink = r.OnClientEvent:Connect(onGrown)
			end
		end
		if size then
			deal() -- the size last answered, put right when the server answers
		end
		ask()
	end

	function tab.hide()
		shown = false
		host.wallet.show(false)
		for _, card in cards do
			card.frame.Visible = false
		end
	end

	function tab.clear()
		tab.hide()
		clear()
	end

	function tab.layout(cardHeight: number)
		tall = cardHeight
		for _, card in cards do
			card.frame.Size = UDim2.fromOffset(math.floor(cardHeight * Shop.CardAspect), cardHeight)
		end
	end

	function tab.destroy()
		tab.clear()
		if grownLink then
			grownLink:Disconnect()
			grownLink = nil
		end
		roll:Destroy()
		knock:Destroy()
	end

	return tab
end

return UnitsTab
