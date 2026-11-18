--!strict
--[[
	UnitsTab: your home's sizes at the counter, the shop's third tab (S5-03h2, D-341; the home
	doc's ideas 30 and 31). The moment: back from a good climb you've saved up; you flip the
	counter's shop to Units and the Medium card's plan opens out from your little unit to its own;
	you tap its price, your cash ticks down, the room you have opens out to the new one over the
	steel's roll and lands on a knock, "More room!", and the card says it's yours. Bloxburg's and
	Adopt Me's house upgrades, Animal Crossing's house loan.

	The cards run from your size up (`Grow.ladder`): yours first, saying Yours, then each bigger
	size on sale with its price: Medium's in cash, Large's and XL's in Robux at Roblox's own price
	with the Robux mark, as the wraps show theirs (S5-03h3a, D-342; Adopt Me sells its bigger
	houses so). A Robux size switched off in the live config isn't dealt at all. Each card's plan is drawn
	from above, the door at its foot: the slot's whole box faint (room still to grow into), the
	card's size filled, and the size you have outlined inside it, so how much more room a size
	gives reads before any word. Your cash and size come from the server (`Grow.ShelfRemote`)
	each time the tab shows (a Robux price missing is asked for once more a moment later). Buy fires
	`Grow.Remote` and the card stays pressed until `Grow.GrownRemote` answers, which it does only
	once the save is written and your home is set up at its new size; for a Robux size the server
	puts Roblox's prompt up first, and closing it unbought settles the card at once ("closed"). A price you can't pay is dimmed; pressing it nudges your cash with a dull
	click, no words. ShopView hosts it, and FurnitureTab's purse is its cash (`Host.wallet`).

	A Large or XL can be given to a friend here too (S5-03h3b2, D-344), as Pet Simulator's and Adopt
	Me's gifts are: a giftable size's card carries a Gift pill (a little wrapped box) beside its
	price, or alone on a size under yours. Tap it and the other sizes fold away while the friends
	here deal in after it, a card each with their face, name and size and the gift's price (the box
	alone for a gift you hold already); one already that big is dimmed and its tap does nothing.
	Tap a friend and their card holds while Roblox's prompt is up (`Grow.Remote` with their
	UserId). Once their save holds it the friends fold away and the gift's plan opens out from
	their size to the one you gave over the steel's roll, their face over it, "Sent!". Closed,
	gone or had settles with no words and asks the shelf again. The Gift pill again goes back.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Cash = require(ReplicatedStorage.Shared.Cash)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local FurnitureTab = require(script.Parent.FurnitureTab)
local GiftMark = require(script.Parent.GiftMark)
local Grow = require(ReplicatedStorage.Shared.Home.Grow)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Shop = require(ReplicatedStorage.Shared.Shop)
local Sizes = require(ReplicatedStorage.Shared.Home.Sizes)

local INK = Lobby.Ink
local FILL_WARM = Color3.fromRGB(CutFree.Fill.r, CutFree.Fill.g, CutFree.Fill.b)
local INK_WARM = Color3.fromRGB(CutFree.Ink.r, CutFree.Ink.g, CutFree.Ink.b)
local ROBUX = utf8.char(0xE002) -- Roblox's own Robux mark in its fonts
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
	gift: TextButton, -- the Gift pill: the wrapped box
	giftPop: UIScale,
	giftRing: UIStroke,
	giftMark: GiftMark.Mark,
	face: ImageLabel, -- the friend's face over the plan as a gift to them lands
	facePop: UIScale,
	under: boolean, -- a size under yours, dealt only to be given
	sent: boolean, -- just given: "Sent!" is up
}

-- A friend here as the Gift dealt them: their card, tapped to give them the size.
type Friendly = {
	id: number,
	size: string,
	frame: TextButton,
	pop: UIScale,
	pill: Frame,
	dim: boolean, -- already that big: dimmed, its tap does nothing
	waiting: number, -- os.clock the gift went out, or -1
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

-- A player's face, as Roblox draws it.
local function headshot(id: number): string
	return `rbxthumb://type=AvatarHeadShot&id={math.abs(id)}&w=150&h=150`
end

-- Each size whose Gift shows on `shelf` now.
local function giftsOn(shelf: Grow.Shelf): { [string]: boolean }
	local out: { [string]: boolean } = {}
	for name in Grow.Gifts do
		if Grow.giftable(shelf, name) then
			out[name] = true
		end
	end
	return out
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
	local robux: { [string]: number } = {} -- each Robux size on sale, Roblox's price (0: not in)
	local reasked = false -- asked again for a missing Robux price since the tab showed
	local dealtFor = "" -- the cards dealt, by name (the ladder they came from)
	local known = false -- the server has answered since the tab showed
	local asking = false
	local shown = false
	local grownLink: RBXScriptConnection? = nil
	local tall = 0 -- the cards' height, from the host's last layout
	local shelfNow: Grow.Shelf? = nil -- the server's last answer: the gifts, spares and friends
	local giftable: { [string]: boolean } = {} -- each size whose Gift shows now
	local giving: Card? = nil -- the size whose friends are dealt (its Gift pressed in)
	local friends: { Friendly } = {}
	local friendLinks: { RBXScriptConnection } = {}
	local friendsFor = "" -- the friends dealt, by size, price and each friend's id and size

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
		elseif state == "robux" then
			local robuxPrice = robux[card.name] or 0
			b.Text = if robuxPrice > 0 then `{ROBUX} {robuxPrice}` else Shop.Words.buy
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
		-- the Gift pill: beside the price, or the whole row on a size under yours and while its
		-- friends are dealt (pressed in, gold: tapped again, back)
		local g, gRing = card.gift, card.giftRing
		local gift = known and giftable[card.name] == true and not (card.grown or card.sent)
		local wide = card.under or giving == card
		g.Visible = gift
		b.Visible = not (card.sent or (gift and wide) or (card.under and not gift))
		if gift and not wide then
			b.Position, b.Size = UDim2.fromScale(0.37, 0.95), UDim2.fromScale(0.58, 0.15)
			g.Position, g.Size = UDim2.fromScale(0.79, 0.95), UDim2.fromScale(0.24, 0.15)
		else
			b.Position, b.Size = UDim2.fromScale(0.5, 0.95), UDim2.fromScale(0.84, 0.15)
			g.Position, g.Size = UDim2.fromScale(0.5, 0.95), UDim2.fromScale(0.84, 0.15)
		end
		if giving == card then
			g.BackgroundColor3, g.BackgroundTransparency = GOLD, 0
			gRing.Color, gRing.Transparency = GOLD, 0
			card.giftMark.paint(WELL, FILL_WARM)
		else
			g.BackgroundColor3, g.BackgroundTransparency = FILL_WARM, 0.05
			gRing.Color, gRing.Transparency = INK_WARM, 0.2
			card.giftMark.paint(INK_WARM, GOLD)
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
	local pressGift: (card: Card) -> ()
	local pressFriend: (f: Friendly) -> ()
	local dealFriends: () -> ()
	local closeGift: () -> ()

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
		haveBox.Visible = Sizes.rank(name) > Sizes.rank(have)
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

		local gift = Instance.new("TextButton")
		gift.Name = "Gift"
		gift.AnchorPoint = Vector2.new(0.5, 1)
		gift.AutoButtonColor = false
		gift.Text = ""
		gift.BackgroundColor3 = FILL_WARM
		gift.Visible = false
		gift.ZIndex = 2
		gift.Parent = frame
		corner(gift, UDim.new(0.5, 0))
		local gp = Instance.new("UIPadding")
		gp.PaddingTop, gp.PaddingBottom = UDim.new(0.14, 0), UDim.new(0.14, 0)
		gp.Parent = gift
		local giftRing = Instance.new("UIStroke")
		giftRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		giftRing.Thickness = 1.5
		giftRing.Parent = gift
		local giftPop = Instance.new("UIScale")
		giftPop.Parent = gift
		local giftMark = GiftMark.new(gift, 3)

		-- the friend's face over the plan as a gift to them lands
		local face = Instance.new("ImageLabel")
		face.Name = "Face"
		face.AnchorPoint = Vector2.new(0.5, 0.5)
		face.Position = UDim2.fromScale(0.5, 0.28)
		face.Size = UDim2.fromScale(0.4, 0.4)
		face.SizeConstraint = Enum.SizeConstraint.RelativeXX
		face.BackgroundColor3 = WELL
		face.ZIndex = 3
		face.Visible = false
		face.Parent = frame
		corner(face, UDim.new(0.5, 0))
		local faceRing = Instance.new("UIStroke")
		faceRing.Color = GOLD
		faceRing.Thickness = 2
		faceRing.Parent = face
		local facePop = Instance.new("UIScale")
		facePop.Parent = face

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
			gift = gift,
			giftPop = giftPop,
			giftRing = giftRing,
			giftMark = giftMark,
			face = face,
			facePop = facePop,
			under = Sizes.rank(name) < Sizes.rank(have),
			sent = false,
		}
		table.insert(
			cardLinks,
			button.Activated:Connect(function()
				press(card)
			end)
		)
		table.insert(
			cardLinks,
			gift.Activated:Connect(function()
				pressGift(card)
			end)
		)
		return card
	end

	-- The friends' cards gone (the Gift closed, the tab hidden, the cards dealt again).
	local function dropFriends()
		for _, c in friendLinks do
			c:Disconnect()
		end
		table.clear(friendLinks)
		for _, f in friends do
			f.frame:Destroy()
		end
		table.clear(friends)
		friendsFor = ""
	end

	-- Whether anything is out or playing: a sale, a gift, a headline. One at a time.
	local function busy(): boolean
		for _, card in cards do
			if card.waiting >= 0 or card.grown or card.sent then
				return true
			end
		end
		for _, f in friends do
			if f.waiting >= 0 then
				return true
			end
		end
		return false
	end

	-- The cards for your size as they'd be dealt now (your size leads, as a size under yours can
	-- be dealt to be given).
	local function ladderKey(): string
		local have = size or Sizes.Start
		return `{have}: {table.concat(Grow.ladder(have, robux, giftable), " ")}`
	end

	local function clear()
		dropFriends()
		giving = nil
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
	-- from yours to its own as it lands. Dealt again only when the cards change (your size, or a
	-- Robux size coming on or going off sale).
	local function deal()
		local have = size or Sizes.Start
		local ladder = Grow.ladder(have, robux, giftable)
		local key = ladderKey()
		if giving then
			dropFriends() -- the Gift closed: every size dealt back in
			giving = nil
		end
		if key ~= dealtFor then
			clear()
			dealtFor = key
			for i, name in ladder do
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
			card.sent = false
			card.face.Visible = false
			card.have.Size = footprint(have)
			card.have.Visible = Sizes.rank(card.name) > Sizes.rank(have)
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
			size = shelf.size
			robux = shelf.robux
			shelfNow = shelf
			giftable = giftsOn(shelf)
			if ladderKey() ~= dealtFor or #cards == 0 then
				deal()
			else
				restate()
				local card = giving
				if card and giftable[card.name] then
					dealFriends() -- as they are now: a friend gone, one grown
				elseif card then
					closeGift() -- nobody here left to give it to
				end
			end
			-- Roblox's prices reach the server a moment after the tab asks: once more for any missing
			local missing = false
			for _, price in robux do
				missing = missing or price == 0
			end
			for _, price in shelf.gifts do
				missing = missing or price == 0
			end
			if missing and not reasked then
				reasked = true
				task.delay(Shop.PriceWait, function()
					if shown then
						ask()
					end
				end)
			end
		end)
	end

	-- The sale landed: the room you have opens out to the new one over the steel's roll, lands on
	-- a knock, "More room!" pops, the card says Yours; then the cards deal again from your size.
	-- A gift landing plays the same over the friend's size, their face over it, "Sent!".
	local function landed(card: Card)
		local gift = card.sent
		card.headline.Text = if gift then Shop.Words.sent else Shop.Words.grown
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
			if not gift then
				card.grown = true
				paint(card)
				card.buttonPop.Scale = 1.12
				TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
			end
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
				if gift then
					TweenService:Create(card.facePop, FADE, { Scale = 0 }):Play()
				end
				task.delay(FADE.Time, function()
					if shown and card.frame.Parent then
						deal() -- from your new size: the smaller card goes
						if gift then
							ask() -- the friend's new size: their Gift may go
						end
					end
				end)
			end)
		end)
	end

	local function settleFriend(f: Friendly)
		f.waiting = -1
		TweenService:Create(f.pop, SPRING, { Scale = 1 }):Play()
		f.pill.BackgroundTransparency = 0.05
	end

	-- The server's answer to a gift to friend `id`: "" once their save holds it, else why not.
	local function onGift(name: string, refusal: string, id: number)
		local card = giving
		if not (shown and card and card.name == name) then
			return
		end
		local f: Friendly? = nil
		for _, each in friends do
			if each.id == id and each.waiting >= 0 then
				f = each
			end
		end
		if f == nil then
			return
		end
		if refusal ~= "" then
			settleFriend(f)
			ask() -- closed, gone, had: the friends dealt again as they are now, no words
			return
		end
		-- given: the friends fold away, and the gift's plan opens out from their size to this one
		f.waiting = -1
		for _, each in friends do
			TweenService:Create(each.pop, FADE, { Scale = 0 }):Play()
		end
		task.delay(FADE.Time, function()
			if giving == nil then
				dropFriends()
			end
		end)
		giving = nil
		card.sent = true
		card.have.Size = footprint(f.size)
		card.have.Visible = true
		card.room.Size = footprint(card.name)
		card.face.Image = headshot(id)
		card.face.Visible = true
		card.facePop.Scale = 0.3
		TweenService:Create(card.facePop, POP, { Scale = 1 }):Play()
		paint(card)
		landed(card)
	end

	-- The server's answer to a sale: the size asked for, your cash, your size, "" or why not, and
	-- the friend's UserId when it was a gift (0 for your own home).
	local function onGrown(
		name: unknown,
		newCash: unknown,
		newSize: unknown,
		refusal: unknown,
		friend: unknown
	)
		if
			type(name) ~= "string"
			or type(newCash) ~= "number"
			or type(newSize) ~= "string"
			or type(refusal) ~= "string"
		then
			return
		end
		if friend ~= nil and friend ~= 0 then
			local id = Grow.friendId(friend)
			if id then
				onGift(name, refusal, id)
			end
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
		elseif refusal == "off" then
			ask() -- gone off sale: the cards dealt again without it
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
		local state = card.state
		if state ~= "buy" and state ~= "robux" or card.under or giving then
			return -- Yours, or not answered yet: nothing to fix, so nothing said
		end
		if busy() then
			return -- one sale at a time
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
		-- a Robux size waits on Roblox's prompt, which stays up while you decide
		task.delay(if state == "robux" then Shop.GrowPrompt else GIVE_UP, function()
			if card.waiting == sent then
				card.waiting = -1
				TweenService:Create(card.buttonPop, SPRING, { Scale = 1 }):Play()
				paint(card)
				ask()
			end
		end)
	end

	-- A friend here dealt after the gift's card: their face, name and size, and the price you'd
	-- pay to give it (the box alone for a gift you hold); dimmed when they're that big already.
	local function makeFriend(
		friend: Grow.Friend,
		gift: string,
		order: number,
		spare: boolean,
		price: number
	): Friendly
		local frame = Instance.new("TextButton")
		frame.Name = `Friend{order}`
		frame.Text = ""
		frame.AutoButtonColor = false
		frame.LayoutOrder = order
		frame.BackgroundColor3 = CARD
		frame.BorderSizePixel = 0
		if tall > 0 then
			frame.Size = UDim2.fromOffset(math.floor(tall * Shop.CardAspect), tall)
		end
		corner(frame, UDim.new(0.08, 0))
		local rim = Instance.new("UIStroke")
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Color = GOLD
		rim.Transparency = 0.75
		rim.Thickness = 1.5
		rim.Parent = frame
		local pop = Instance.new("UIScale")
		pop.Scale = 0
		pop.Parent = frame
		local dim = Grow.owns({ homeSize = friend.size }, gift)

		local face = Instance.new("ImageLabel")
		face.Name = "Face"
		face.AnchorPoint = Vector2.new(0.5, 0)
		face.Position = UDim2.fromScale(0.5, 0.07)
		face.Size = UDim2.fromScale(0.74, 0.74)
		face.SizeConstraint = Enum.SizeConstraint.RelativeXX
		face.BackgroundColor3 = WELL
		face.Image = headshot(friend.id)
		face.ImageTransparency = if dim then 0.6 else 0
		face.Parent = frame
		corner(face, UDim.new(0.5, 0))
		local ring = Instance.new("UIStroke")
		ring.Color = if dim then INK else GOLD
		ring.Transparency = if dim then 0.8 else 0.3
		ring.Thickness = 1.5
		ring.Parent = face

		local name = label(frame, "Name", INK)
		name.AnchorPoint = Vector2.new(0.5, 0)
		name.Position = UDim2.fromScale(0.5, 0.6)
		name.Size = UDim2.fromScale(0.9, 0.12)
		name.Text = friend.name
		local theirs = label(frame, "Size", INK)
		theirs.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		theirs.AnchorPoint = Vector2.new(0.5, 0)
		theirs.Position = UDim2.fromScale(0.5, 0.72)
		theirs.Size = UDim2.fromScale(0.6, 0.08)
		theirs.Text = friend.size
		theirs.TextTransparency = if dim then 0.8 else 0.4
		if dim then
			name.TextTransparency = Shop.TabDim
		end

		local pill = Instance.new("Frame")
		pill.Name = "Pill"
		pill.AnchorPoint = Vector2.new(0.5, 1)
		pill.Position = UDim2.fromScale(0.5, 0.95)
		pill.Size = UDim2.fromScale(0.84, 0.15)
		pill.BackgroundColor3 = FILL_WARM
		pill.BackgroundTransparency = 0.05
		pill.Visible = not dim
		pill.Parent = frame
		corner(pill, UDim.new(0.5, 0))
		local pad = Instance.new("UIPadding")
		pad.PaddingTop, pad.PaddingBottom = UDim.new(0.16, 0), UDim.new(0.16, 0)
		pad.Parent = pill
		if spare then
			GiftMark.new(pill, 2).paint(INK_WARM, GOLD)
		else
			local text = label(pill, "Price", INK_WARM)
			text.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
			text.Size = UDim2.fromScale(1, 1)
			text.Text = if price > 0 then `{ROBUX} {price}` else Shop.Words.buy
		end
		frame.Parent = row

		local f: Friendly = {
			id = friend.id,
			size = friend.size,
			frame = frame,
			pop = pop,
			pill = pill,
			dim = dim,
			waiting = -1,
		}
		table.insert(
			friendLinks,
			frame.Activated:Connect(function()
				pressFriend(f)
			end)
		)
		return f
	end

	-- The friends here dealt after the gift's card, left to right; dealt again only when they
	-- change, never while one's gift is out.
	function dealFriends()
		local card, shelf = giving, shelfNow
		if not (card and shelf) then
			return
		end
		for _, f in friends do
			if f.waiting >= 0 then
				return
			end
		end
		local spare = (shelf.spares[card.name] or 0) > 0
		local price = shelf.gifts[card.name] or 0
		local parts = { card.name, if spare then "spare" else tostring(price) }
		for _, friend in shelf.friends do
			table.insert(parts, `{friend.id}={friend.size}`)
		end
		local key = table.concat(parts, " ")
		if key == friendsFor then
			return
		end
		dropFriends()
		friendsFor = key
		for i, friend in shelf.friends do
			local f = makeFriend(friend, card.name, 300 + i, spare, price)
			table.insert(friends, f)
			task.delay(0.05 + (i - 1) * Shop.DealEvery, function()
				if shown and f.frame.Parent then
					TweenService:Create(f.pop, POP, { Scale = 1 }):Play()
				end
			end)
		end
	end

	function closeGift()
		dropFriends()
		giving = nil
		deal() -- every size dealt back in
	end

	-- The Gift pill: the other sizes fold away and the friends here deal in; again, back.
	function pressGift(card: Card)
		if card.pop.Scale < 0.9 or busy() then
			return
		end
		card.giftPop.Scale = Shop.Pressed
		TweenService:Create(card.giftPop, SPRING, { Scale = 1 }):Play()
		if giving == card then
			host.click(0.9)
			closeGift()
			return
		end
		host.click(1.12)
		dropFriends()
		giving = card
		for _, other in cards do
			if other ~= card then
				other.frame.Visible = false
			end
		end
		card.pop.Scale = 0.94
		TweenService:Create(card.pop, SPRING, { Scale = 1 }):Play()
		paint(card)
		dealFriends()
	end

	-- A friend's card: the gift goes out for them and their card holds till it's answered.
	function pressFriend(f: Friendly)
		local card = giving
		if card == nil or f.dim or f.pop.Scale < 0.9 or busy() then
			return -- one that big already: nothing to fix, so nothing said
		end
		local r = remote(Grow.Remote)
		if not (r and r:IsA("RemoteEvent")) then
			return
		end
		host.click(1.05)
		f.waiting = os.clock()
		f.pop.Scale = Shop.Pressed
		TweenService:Create(f.pop, HOLD, { Scale = 0.94 }):Play()
		f.pill.BackgroundTransparency = 1 - 0.95 * Shop.Dim
		r:FireServer(card.name, f.id)
		local sent = f.waiting
		-- Roblox's prompt stays up while you decide; this only settles a lost answer
		task.delay(Shop.GrowPrompt, function()
			if f.waiting == sent then
				settleFriend(f)
				ask()
			end
		end)
	end

	local tab = {} :: Tab

	function tab.show()
		shown = true
		known = false
		reasked = false
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
		dropFriends()
		giving = nil
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
		for _, f in friends do
			f.frame.Size = UDim2.fromOffset(math.floor(cardHeight * Shop.CardAspect), cardHeight)
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
