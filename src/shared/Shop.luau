--!strict
--[[
	Shop (S3-04b, GDD "Monetization", D-112): the counter's shop, its first shelf the wrap colours.
	The moment: back in the lobby after a climb you walk up to the front office's counter and the
	shop slides up, each colour a figure of you turning in its film with its price on Buy; you buy
	one and the film snaps tight round the figure with the film's squeal and the card says Worn.
	Fortnite's item shop and DOORS' shop are bought from a screen like it (cards in a row, a price
	on each, owned ones marked).

	Three remotes in ReplicatedStorage.Remotes, each checked on the server (Wearing):
	- `ShopShelf` (RemoteFunction, nothing carried): each colour's price, whether you own it, and
	  what you wear (`Shelf`). Asking it records one look at the shop (Brix's `shopViewed`).
	- `BuyWrap` (RemoteEvent, a colour's name): puts Roblox's purchase prompt for it up, through
	  the server (`Purchasing.prompt`), never the screen's own.
	- `WearWrap` (RemoteEvent, a colour's name or empty for the plain film): puts on one you own.
	A purchase or a change lands as the Player's `WrapColour` attribute (WrapColours), which the
	screen hears to flip the card.
	A fourth, `TryWrap` (RemoteEvent, a colour's name), is the cards' Try on (S5-03f4b, D-319): the
	server (TryOns) wraps you in that colour at the counter's mirror for a few seconds, free.

	Every feel number the screen uses is here.
]]
local WrapColours = require("./WrapColours")

local Shop = {}

Shop.RemoteFolder = "Remotes"
Shop.ShelfRemote = "ShopShelf"
Shop.BuyRemote = "BuyWrap"
Shop.WearRemote = "WearWrap"
Shop.TryRemote = "TryWrap"

-- Seconds between a player's asks the server takes, each remote alike: a mashed button costs
-- nothing, and a shop never needs answering faster.
Shop.AskEvery = 0.4

-- A card's state, as its button reads: Buy (with the price), Wear (owned, not worn), Worn.
export type State = "buy" | "wear" | "worn"

-- One colour on the shelf as the server answers it: its name, its price (nil while Roblox has
-- none for it, or it's owned), whether it's yours.
export type Item = { name: string, price: number?, owned: boolean }
export type Shelf = { worn: string, items: { Item } }

-- The longest name a remote takes: a colour's offer name is far shorter.
local NAME_MAX = 32

-- The words on screen (few words, one verb each: AGENTS.md).
Shop.Words = table.freeze({
	title = "Wraps",
	buy = "Buy",
	wear = "Wear",
	worn = "Worn",
	plain = "Plain",
	open = "Shop", -- the counter's prompt and the lobby's button
	try = "Try on", -- a card's figure: you in that colour at the mirror beside the counter
	furniture = "Furniture", -- the second tab: this week's pieces for your home (S5-03g4b)
	owned = "Owned", -- a piece you own as many of as you may
	inBox = "In your box", -- a piece just bought: it waits in your job box
	units = "Units", -- the third tab: your home's sizes, yours then the bigger ones (S5-03h2)
	yours = "Yours", -- the size your home is
	grown = "More room!", -- the headline on a size just bought
})

-- The counter's prompt: in the lobby's own frame, just in front of the counter's face (its front
-- is at x 51, the counter 14 long down z, from z -150 to -136; Lobby.Specs), at a hand's height,
-- toward its end by the front door: the end you reach first from the spawn, and the mirror's.
Shop.CounterAt = table.freeze({ 49.6, 3.2, -147.5 })
-- Studs from the counter its prompt shows: walking up to it, not across the room.
Shop.CounterReach = 9

-- The counter's mirror (S5-03f4b, idea 24): the home's framed floor mirror (Home.mirrorAt), its
-- foot in the lobby's frame, leaning on the front wall (its face at z -156) just past the counter's
-- door end, turned (degrees about Y) so its glass looks into the room. You see yourself in it as you
-- walk up to the counter, and from the shop you try a colour on in it.
-- Its x is the counter's button's (Shop.CounterAt), so standing there you're in line with the
-- glass and see yourself in it (TryOn.inLine; at x 47.5 you were a sliver at its edge).
Shop.Mirror = table.freeze({ At = table.freeze({ 49.6, 0, -155.2 }), Turn = 180 })
-- Studs across the floor from a mirror's glass that a card's Try on shows within, and works from
-- (the server forgives TryOn.Slack more): from anywhere you'd stand at the counter, you're
-- turned to face the glass and see yourself in it, without walking over.
Shop.TryReach = 12

-- The screen's feel.
-- Seconds the shop takes to slide up from the bottom, and to drop away.
Shop.SlideIn = 0.32
Shop.SlideOut = 0.2
-- How far down the screen the shop starts its slide (a share of its own height).
Shop.SlideFrom = 0.6
-- A card's width over its height, and the gap between cards (share of the row's height).
Shop.CardAspect = 0.66
Shop.CardGap = 0.05
-- Seconds between each card's pop as the shop opens, left to right: the row deals out.
Shop.DealEvery = 0.04
-- Turns a second each figure makes in its film: slow enough to read the colour, alive.
Shop.Spin = 0.12
-- Seconds after a shelf answer missing a price that the screen asks once more: Roblox's prices
-- reach the server a moment after the shop opens.
Shop.PriceWait = 1.2
-- A press: the button's scale at once, springing back.
Shop.Pressed = 0.88
-- Seconds a Buy stays dimmed after a press while Roblox's prompt comes up (a second press then is
-- ignored), and how dim.
Shop.AskDim = 1.6
Shop.Dim = 0.5
-- The film snapping tight on a bought or worn colour: the figure squeezed to this scale across,
-- then sprung back over this many seconds, with the film's squeal (`Kept.Squeal`) at this pitch
-- and volume (higher and shorter than a catch's: a snap, not a dread).
Shop.SnapSqueeze = 0.82
Shop.SnapTime = 0.42
Shop.SnapPitch = 1.25
Shop.SnapVolume = 0.7
Shop.SnapLength = 0.55
-- The card's flash as it flips to Worn: its rim lit in the colour, fading over this many seconds.
Shop.FlashTime = 0.6
-- A press's click (Roblox's "UI Bright Click", as the car's panel and Cut Free).
Shop.Click = table.freeze({ id = "rbxassetid://15675059323", pitch = 1, volume = 0.35 })
-- The shop's open: the click pitched down, a slide's thunk.
Shop.OpenPitch = 0.8

-- The furniture tab (S5-03g4b, FurnitureTab). The moment: you flip to Furniture and this week's
-- pieces turn slowly in their cards; Buy, and your cash ticks down, the piece drops into its box
-- with the job box lid's clunk and the card says it's in your box.
-- Turns a second a floor piece makes in its card, and how far (degrees) a wall or ceiling piece
-- sways either side of facing you (its back is bare, so it never turns round).
Shop.PieceSpin = 0.09
Shop.PieceSway = 35
-- Degrees the cards' cameras look down on a piece: you see its top, as you would standing by it.
Shop.PieceTilt = 18
-- Seconds the tabs' underline slides, and the cards' dim of a tab you're not on.
Shop.TabSlide = 0.22
Shop.TabDim = 0.55
-- The buy's answer: seconds the cash takes to tick down (a fast rattle of the coins' ticks, each
-- lower than the last), the piece's drop into its box, and how long the card says it's in your box
-- before its price comes back.
Shop.SpendTime = 0.55
Shop.SpendFall = 0.45 -- how much lower the last tick is than the first
Shop.DropTime = 0.32
Shop.InBoxFor = 1.6
-- The clunk as the piece lands: the job box lid's (JobBox.Clunk's cut), a touch lighter.
Shop.Clunk = table.freeze({
	id = "rbxassetid://9116436662",
	from = 1.45,
	length = 0.5,
	volume = 0.5,
	pitch = 0.8,
})
-- A press on a price you can't pay yet: no words, your cash nudges side to side (the cause, on
-- screen) with a dull click, as the vending machine's price blinks for too few coins.
Shop.ShortNudge = 0.3
Shop.ShortPitch = 0.6

-- A bigger home bought (S5-03h2, D-341). As a size's card deals in, its plan opens out from your
-- size to its own in `GrowPreview` seconds: the card shows how much more room before a word is
-- read. On the sale the room you have opens out to the new one in `GrowTime`, over the steel's
-- roll (the roll-up door's own curtain, DoorSound.Roll, cut short), landing on the stop bolts'
-- knock (DoorSound.Thump pitched up), and the headline stays `GrowFor` seconds. The walls'
-- grind in your home itself is S5-03h6's.
Shop.GrowPreview = 0.7
-- Seconds a Large or XL card's Buy stays pressed while Roblox's prompt is up and no answer has
-- come (S5-03h3a): closing the prompt answers at once; this only settles a lost answer.
Shop.GrowPrompt = 30
Shop.GrowTime = 1.1
Shop.GrowFor = 2.2
Shop.GrowRoll = table.freeze({
	id = "rbxassetid://9120273047",
	from = 1.2,
	length = 1.2,
	volume = 0.55,
	pitch = 1.08,
})
Shop.GrowKnock = table.freeze({
	id = "rbxassetid://9120370893",
	from = 0.07,
	length = 0.6,
	volume = 0.45,
	pitch = 1.5,
})

-- The value a remote carried, as a colour's name for `WearWrap` (empty for the plain film) or
-- `BuyWrap` (`plain` false: a colour only), or nil when it isn't one: never trusts the client.
function Shop.name(value: unknown, plain: boolean): string?
	if type(value) ~= "string" or #value > NAME_MAX then
		return nil
	end
	if value == "" then
		return if plain then "" else nil
	end
	return if WrapColours.get(value) then value else nil
end

-- A card's state for the colour named `name`, given what the server answered.
function Shop.state(item: Item, worn: string): State
	if item.name == worn and item.owned then
		return "worn"
	end
	return if item.owned then "wear" else "buy"
end

-- What the server answers for a save: each colour on the shelf in order, priced from `prices`
-- (offer name to Robux, as Purchasing's shelf answers), owned or not, and what's worn.
function Shop.shelf(
	data: { wraps: { [string]: number }, wornWrap: string },
	prices: { [string]: number }
): Shelf
	local items: { Item } = {}
	for _, colour in WrapColours.Shelf do
		local owned = WrapColours.owns(data, colour.name)
		table.insert(items, {
			name = colour.name,
			price = if owned then nil else prices[colour.name],
			owned = owned,
		})
	end
	return { worn = WrapColours.worn(data), items = items }
end

-- The shelf the screen was answered, read safely (a RemoteFunction's answer is plain data, but
-- typed here at the one boundary): nil if it isn't a shelf.
function Shop.read(value: unknown): Shelf?
	if type(value) ~= "table" then
		return nil
	end
	local t = value :: { [string]: unknown }
	local worn, items = t.worn, t.items
	if type(worn) ~= "string" or type(items) ~= "table" then
		return nil
	end
	local out: { Item } = {}
	for _, raw in items :: { unknown } do
		if type(raw) == "table" then
			local i = raw :: { [string]: unknown }
			local name, price, owned = i.name, i.price, i.owned
			if type(name) == "string" and WrapColours.get(name) and type(owned) == "boolean" then
				table.insert(out, {
					name = name,
					price = if type(price) == "number" then price else nil,
					owned = owned,
				})
			end
		end
	end
	return { worn = worn, items = out }
end

return table.freeze(Shop)
