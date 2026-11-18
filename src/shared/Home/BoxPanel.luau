--!strict
--[[
	BoxPanel: the job box's panel, the rules for looking through it (S5-03c2b1, D-291), pure so Lune
	tests them. The moment: you open the job box and, as the lid lifts, a panel slides up with
	everything you own, each kind once with how many (x2); type, or tap a rarity, and it narrows at
	once; Close, or walking off, and it drops away as the lid falls. Precedents: Resident Evil's item
	box (one box, everything in it), Animal Crossing's house storage, Pet Simulator's inventory
	(rarest first, a search box and rarity filters).

	The server (JobBoxes) sends the holder their finds (`list`) as the lid opens; the screen
	(BoxPanelView) reads them (`read`), deals one card a kind (`cards`) and narrows them (`shown`).
	Every feel number the screen uses is here.

	Taking one out (S5-03c2b2, D-293): what's listed is what's in the box (Save.boxed: owned, less
	the shelf's and what's out). Tap a card, Take or Shelf; the screen asks `TakeRemote` with the
	name and the way, the server checks it (`way`, `name`, `canTake`) and answers on `TookRemote`,
	and the card counts one fewer (`took`).

	Selling one (S5-03c3a): Sell is the take's third way. The server prices it at its catalog worth
	(`price`), strikes one off what you own and puts the price on your cash in one step (`sell`),
	so a save written at any moment holds both or neither; it answers with your new cash. Only one
	in the box sells: never the shelf's, never one out in someone's hands. A name with cracked ones
	(the save's `chipped`, D-296) sells a cracked one first, at half (S5-03c3a2): the box sends how
	many of each are cracked (`cracked`), and the card's price says which is next.

	Making a Gold (S5-03c3b, D-298): Gold is the take's fourth way. With four of one find in the box
	(Gold.Need), the server strikes the four and adds one of its Gold (Gold.key) in one step
	(`gold`), so a save written at any moment holds the four or the Gold, never both or neither.
	The screen counts the four off its card and deals the Gold's (`made`). A Gold sells at five
	times its find's price; it doesn't come out into your hands or onto the shelf yet.

	Furniture in the box (S5-03g4c2, D-337): the counter's pieces you own and haven't set out
	(`Furniture.boxed`) come with the list, dealt first, a card a piece (`pieces`), keyed by the
	name they're set out under so a piece is never a find. A floor piece's only verb is Set out
	(`settable`), which opens Arrange holding it; no sale, no hand, no shelf. Wall and ceiling
	pieces wait for their lights (g4d). They show under All and in a search, never under a rarity.
]]
local Chip = require("../Finds/Chip")
local Furniture = require("./Furniture")
local Gold = require("./Gold")
local Grades = require("../Grades")

local BoxPanel = {}

BoxPanel.RemoteFolder = "Remotes"
-- Server to the holder, as their box opens: the box, its finds by name with how many, the free
-- shelf spots, their cash, and how many of each find are cracked (`cracked`).
BoxPanel.ListRemote = "JobBoxList"
-- The holder's screen to the server, nothing carried: shut my open box (its X, or a tap outside).
BoxPanel.CloseRemote = "JobBoxClose"
BoxPanel.Limit = { perSecond = 3, burst = 4 } -- Close asks a player may make: mashing costs nothing
-- The holder's screen to the server (S5-03c2b2): take one find, by name, out of my open box, a way.
BoxPanel.TakeRemote = "JobBoxTake"
-- Server to the holder, every take answered: the name, the way, whether it came out, and where it
-- went (the slot it went into, or the shelf spot's place in the world).
BoxPanel.TookRemote = "JobBoxTook"
-- Takes and sales a player may ask: three quick ones fill your hands, a run of sales sells at a
-- brisk tap, and mashing never piles up more
BoxPanel.TakeLimit = { perSecond = 4, burst = 5 }
-- Seconds after a sale before the server writes the save, so a run of sales is one write (a
-- DataStore key takes one write in six seconds). The sale is in the save it holds at once: a crash
-- in between only undoes the whole sale, the find back and the cash with it.
BoxPanel.SellSave = 6
-- The most one find sells for: the dearest Secret's worth (Grades.Worth).
BoxPanel.PriceMost = 12000

-- Where a find taken out goes: into your hands, onto a free spot of your shelf, sold for cash, or,
-- four of it, into one Gold.
export type Way = "Hand" | "Shelf" | "Sell" | "Gold"
BoxPanel.Ways = table.freeze({
	Hand = "Hand" :: Way,
	Shelf = "Shelf" :: Way,
	Sell = "Sell" :: Way,
	Gold = "Gold" :: Way,
})

BoxPanel.SearchMax = 24 -- characters the search box takes: a find's name is never longer
BoxPanel.KindsMax = 2000 -- kinds a list carries at most: far past every find there is
BoxPanel.NameMax = 64 -- characters a find's name from the wire may have (the save's own limit)

-- A way from the wire, or nil when it isn't one.
function BoxPanel.way(value: unknown): Way?
	if value == "Hand" or value == "Shelf" or value == "Sell" or value == "Gold" then
		return value :: Way
	end
	return nil
end

-- A find's name from the wire, or nil when it isn't one (text, 1 to NameMax characters).
function BoxPanel.name(value: unknown): string?
	if type(value) ~= "string" or #value < 1 or #value > BoxPanel.NameMax then
		return nil
	end
	return value
end

-- Whether one of `name` may come out of a box holding `boxed` (Save.boxed): one at least is in it.
function BoxPanel.canTake(boxed: { [string]: number }, name: string): boolean
	local n = boxed[name]
	return type(n) == "number" and n >= 1
end

-- What one find sells for (S5-03c3a): its catalog worth, as the Packrat weighs it and the item
-- catalog prices it, whole; with none, its grade's least (Grades.Worth); never under 1 or over
-- PriceMost. Its Gold (`gold`) sells for Gold.Times that; a cracked one (`cracked`, D-296) for half
-- (Chip.worth).
function BoxPanel.price(
	row: { grade: Grades.Grade?, worth: number? },
	gold: boolean?,
	cracked: boolean?
): number
	local worth = row.worth
	if type(worth) ~= "number" or worth ~= worth then
		local range = if row.grade then Grades.Worth[row.grade] else nil
		worth = if range then range[1] else 1
	end
	local price = math.clamp(math.floor(worth :: number), 1, BoxPanel.PriceMost)
	price = if gold then price * Gold.Times else price
	return Chip.worth(price, cracked == true)
end

-- What a sale changes: what you own, which of it is cracked, and your cash (the save's Data is
-- one of these).
export type Sellable = {
	finds: { [string]: number },
	chipped: { [string]: number },
	cash: number,
}

-- Sells one `name` from a box holding `boxed` (Save.boxed), whole, for `price`: one fewer owned
-- (its name gone at none) and the price on the cash, together. With cracked ones of it
-- (`chipped`, S5-03c3a2), a cracked one goes first, at half (Chip.worth), one off `chipped`, so it
-- never tops what's left. Returns the cash after, or nil, changing nothing, when none is in the
-- box or the price isn't one.
function BoxPanel.sell(
	data: Sellable,
	boxed: { [string]: number },
	name: string,
	price: number
): number?
	local owned = data.finds[name]
	if
		not BoxPanel.canTake(boxed, name)
		or type(owned) ~= "number"
		or owned < 1
		or price ~= price
		or price < 1
	then
		return nil
	end
	local left = math.floor(owned) - 1
	if left >= 1 then
		data.finds[name] = left
	else
		data.finds[name] = nil -- the save's counts are one or more
	end
	local cracked = math.floor(data.chipped[name] or 0)
	if cracked >= 1 then
		price = Chip.worth(price, true)
		local still = math.min(cracked - 1, left)
		if still >= 1 then
			data.chipped[name] = still
		else
			data.chipped[name] = nil
		end
	end
	data.cash = math.floor(data.cash) + math.floor(price)
	return data.cash
end

-- How many of each name in a box holding `boxed` (Save.boxed) are cracked, as the box sends them
-- when it opens (S5-03c3a2): the save's `chipped`, never more than the box holds, and only names
-- in it. Cracked ones are kept in the box: one taken out is whole (D-296).
function BoxPanel.cracked(
	chipped: { [string]: number },
	boxed: { [string]: number }
): { [string]: number }
	local out: { [string]: number } = {}
	for name, n in chipped do
		local inBox = boxed[name]
		if type(n) == "number" and type(inBox) == "number" then
			local count = math.floor(math.min(n, inBox))
			if count >= 1 then
				out[name] = count
			end
		end
	end
	return out
end

-- How many of a card's are cracked after the server took one `way` (S5-03c3a2): a sale takes a
-- cracked one first, a Gold four, cracked first (`gold`); taken out or shelved, the cracked ones
-- stay in the box.
function BoxPanel.crackedLeft(cracked: number, way: Way): number
	if way == BoxPanel.Ways.Sell then
		return math.max(cracked - 1, 0)
	elseif way == BoxPanel.Ways.Gold then
		return math.max(cracked - Gold.Need, 0)
	end
	return cracked
end

-- What making a Gold changes (the save's Data is one of these): what you own and which of it is
-- cracked.
export type Goldable = {
	finds: { [string]: number },
	chipped: { [string]: number },
}

-- Makes one Gold of `name` from Gold.Need of it in a box holding `boxed` (Save.boxed), at `now`
-- (os.time): the four struck off what you own (its name gone at none), cracked ones first so
-- `chipped` never tops `finds`, and one Gold added, its page in the book (`book`, the save's
-- `stamps.finds`) stamped the first time, all together. Returns the Gold's key, or nil, changing nothing, when fewer than four are in the
-- box or `name` is a Gold's already. The server checks the find may be made Gold (Gold.can).
function BoxPanel.gold(
	data: Goldable,
	boxed: { [string]: number },
	name: string,
	book: { [string]: number },
	now: number
): string?
	local inBox, owned = boxed[name], data.finds[name]
	if
		Gold.base(name) ~= nil
		or type(inBox) ~= "number"
		or inBox < Gold.Need
		or type(owned) ~= "number"
		or owned < Gold.Need
	then
		return nil
	end
	local left = math.floor(owned) - Gold.Need
	if left >= 1 then
		data.finds[name] = left
	else
		data.finds[name] = nil -- the save's counts are one or more
	end
	local cracked = math.floor(data.chipped[name] or 0) - Gold.Need
	if cracked >= 1 then
		data.chipped[name] = math.min(cracked, left)
	else
		data.chipped[name] = nil
	end
	local key = Gold.key(name)
	data.finds[key] = math.floor(data.finds[key] or 0) + 1
	if book[key] == nil then
		book[key] = math.floor(now)
	end
	return key
end

-- A kind of find you own, as its card shows it. A Gold's card (`gold`) is its find's, gilded:
-- `base` is the find it's made of.
export type Card = {
	key: string,
	name: string,
	grade: Grades.Grade,
	count: number,
	gold: boolean?,
	base: string?,
	piece: string?, -- a piece of the counter's furniture: its id (S5-03g4c2); its grade means nothing
}
-- What the screen needs from a find's catalog row (Tools.Catalog): its name and grade.
export type Row = { name: string, grade: Grades.Grade?, find: boolean? }

local RANK: { [string]: number } = {}
for i, grade in Grades.Names do
	RANK[grade] = i
end

-- What the server sends: each name in the save's `finds` held one or more times, with how many.
function BoxPanel.list(finds: { [string]: number }): { [string]: number }
	local out: { [string]: number } = {}
	for name, count in finds do
		if type(name) == "string" and type(count) == "number" and count >= 1 then
			out[name] = math.floor(count)
		end
	end
	return out
end

-- The list as the screen received it, or nil when it isn't one (names to whole counts from 1).
function BoxPanel.read(value: unknown): { [string]: number }?
	if type(value) ~= "table" then
		return nil
	end
	local out: { [string]: number } = {}
	local kinds = 0
	for name, count in value :: { [unknown]: unknown } do
		if type(name) ~= "string" or type(count) ~= "number" or count < 1 or count ~= count then
			return nil
		end
		kinds += 1
		if kinds > BoxPanel.KindsMax then
			return nil
		end
		out[name] = math.floor(count)
	end
	return out
end

-- How a name or a search is compared: lower case, letters and digits only, so "night light"
-- finds the Night-light.
local function plain(text: string): string
	return (string.gsub(string.lower(text), "[^%w]", ""))
end

-- The card for `count` of `key` (a find's, or a Gold's) when the catalog knows its find.
local function cardOf(key: string, count: number, catalog: { [string]: Row }): Card?
	local base = Gold.base(key)
	local row = catalog[base or key]
	if not (row and row.find and count >= 1) or (base and not Gold.can(row)) then
		return nil
	end
	return {
		key = key,
		name = if base then `{Gold.Word} {row.name}` else row.name,
		grade = row.grade or "Common",
		count = count,
		gold = base ~= nil,
		base = base or key,
	}
end

-- A card's find's own name, a Gold's without its word: what the cards are sorted by.
local function nameOf(card: Card): string
	if card.gold then
		return string.sub(card.name, #Gold.Word + 2)
	end
	return card.name
end

-- Rarest first, then by its find's name, a Gold just before its find (made beside the four).
local function before(a: Card, b: Card): boolean
	local ra, rb = RANK[a.grade] or 0, RANK[b.grade] or 0
	if ra ~= rb then
		return ra > rb
	end
	local na, nb = string.lower(nameOf(a)), string.lower(nameOf(b))
	if na ~= nb then
		return na < nb
	end
	if (a.gold == true) ~= (b.gold == true) then
		return a.gold == true
	end
	return a.key < b.key
end

-- One card for each kind in `finds` that the catalog knows as a find, rarest first, then by name.
function BoxPanel.cards(finds: { [string]: number }, catalog: { [string]: Row }): { Card }
	local out: { Card } = {}
	for key, count in finds do
		local card = cardOf(key, count, catalog)
		if card then
			table.insert(out, card)
		end
	end
	table.sort(out, before)
	return out
end

-- The furniture in the box (S5-03g4c2): a card each piece with one at least, in the counter's order
-- (`Furniture.Pieces`), keyed by its placed name ("CampBed:Furniture", never a find's).
function BoxPanel.pieces(furniture: { [string]: number }): { Card }
	local out: { Card } = {}
	for _, p in Furniture.Pieces do
		local n = furniture[p.id]
		if type(n) == "number" and n >= 1 then
			table.insert(out, {
				key = Furniture.placed(p.id),
				name = p.name,
				grade = "Common",
				count = math.floor(n),
				piece = p.id,
			})
		end
	end
	return out
end

-- Whether the panel offers Set out for `card`: any piece of furniture, on the floor, a wall or the
-- ceiling (S5-03g4d); a find is never set out from here.
function BoxPanel.settable(card: Card): boolean
	return card.piece ~= nil and Furniture.byId(card.piece) ~= nil
end

-- Whether the panel offers to make `card` Gold: four or more of a find that can be, not a Gold.
function BoxPanel.offers(card: Card, row: Row?): boolean
	return card.gold ~= true and card.count >= Gold.Need and Gold.can(row)
end

-- Four of `name` made one Gold (S5-03c3b): its card counts four fewer, and goes at none; the
-- Gold's card counts one more, dealt into its place among `cards` if it's new. Returns the Gold's
-- card and whether it's new, or nil, changing nothing, when no card held four.
function BoxPanel.made(cards: { Card }, catalog: { [string]: Row }, name: string): (Card?, boolean)
	local at: number? = nil
	for i, card in cards do
		if card.key == name and card.count >= Gold.Need then
			at = i
			break
		end
	end
	local key = Gold.key(name)
	local new = cardOf(key, 1, catalog)
	if not (at and new) then
		return nil, false
	end
	local four = cards[at]
	four.count -= Gold.Need
	if four.count < 1 then
		table.remove(cards, at)
	end
	for _, card in cards do
		if card.key == key then
			card.count += 1
			return card, false
		end
	end
	table.insert(cards, new)
	table.sort(cards, before)
	return new, true
end

-- The search as typed, cut to what the box takes.
function BoxPanel.search(text: string): string
	return string.sub(text, 1, BoxPanel.SearchMax)
end

-- Whether `card` is shown for the search `text` and the rarity `grade` (nil: every rarity).
function BoxPanel.match(card: Card, text: string, grade: Grades.Grade?): boolean
	if grade and (card.grade ~= grade or card.piece) then
		return false
	end
	local want = plain(BoxPanel.search(text))
	return want == "" or string.find(plain(card.name), want, 1, true) ~= nil
end

-- The cards shown for a search and a rarity, in the cards' order.
function BoxPanel.shown(cards: { Card }, text: string, grade: Grades.Grade?): { Card }
	local out: { Card } = {}
	for _, card in cards do
		if BoxPanel.match(card, text, grade) then
			table.insert(out, card)
		end
	end
	return out
end

-- The rarities you own any of, commonest first: one chip each after All.
function BoxPanel.grades(cards: { Card }): { Grades.Grade }
	local have: { [string]: true } = {}
	for _, card in cards do
		if not card.piece then
			have[card.grade] = true
		end
	end
	local out: { Grades.Grade } = {}
	for _, grade in Grades.Names do
		if have[grade] then
			table.insert(out, grade)
		end
	end
	return out
end

-- A card's count badge: none for one, "x2" for two.
function BoxPanel.badge(count: number): string
	return if count > 1 then `x{count}` else ""
end

-- One of `key` came out (S5-03c2b2): its card counts one fewer, and goes from `cards` at none.
-- The card, or nil when there was none for it.
function BoxPanel.took(cards: { Card }, key: string): Card?
	for i, card in cards do
		if card.key == key then
			card.count -= 1
			if card.count < 1 then
				table.remove(cards, i)
			end
			return card
		end
	end
	return nil
end

-- The screen's feel.
BoxPanel.Words = table.freeze({
	search = "Search",
	all = "All",
	none = "No match",
	empty = "Empty",
	take = "Take",
	shelf = "Shelf",
	sell = "Sell", -- with its price after it: "Sell $4"
	gold = "Gold", -- four of one find into one Gold
	setOut = "Set out", -- a piece of furniture out of the box and into Arrange (S5-03g4c2)
})
-- Taking one out (S5-03c2b2): tap a card and it lifts and glows, its verbs over its name; Take, and
-- its picture flies out of the panel into a free one of your hands (the three wells over the
-- panel's corner, your slots), or Shelf, up to the cubby it lands in, the count ticking down.
BoxPanel.Lift = 1.08 -- a picked card's scale: lifted off the panel
BoxPanel.Glow = 3 -- a picked card's rim, points thick, fully lit
BoxPanel.Rise = 1.18 -- the picture's scale the moment Take or Shelf is pressed, before it flies
BoxPanel.Fly = 0.42 -- seconds the picture takes from its card to your hand or the cubby
BoxPanel.Arc = 0.16 -- of the screen's height: how high the flight bows over a straight line
BoxPanel.Wait = 1.5 -- seconds the screen waits for the server's answer before giving up quietly
-- Seconds the cards ignore taps after one leaves the panel (S5-03c3a), each ignored tap starting
-- them again: the next card slides into its place under your thumb, so a mashed Sell never picks
-- it, and then sells it, by mistake. Rest your thumb this long and you can pick again.
BoxPanel.Guard = 0.6
BoxPanel.Well = 0.17 -- a hand's well, a share of the panel's height (44 points on a Galaxy A16)
BoxPanel.Shake = 0.24 -- seconds the wells shake when your hands are full and Take is pressed
BoxPanel.Height = 0.76 -- the panel's height, a share of the screen's: the lid shows above it
BoxPanel.HeightRange = { 230, 470 } -- points: a phone's 338-point-tall screen gets 257
BoxPanel.Width = 0.94 -- of the screen's width, up to WidthMax points
BoxPanel.WidthMax = 900
BoxPanel.Card = { Height = 0.3, Range = { 92, 136 }, Aspect = 0.84, Gap = 0.07 } -- of the screen
BoxPanel.DealFrom = 0.35 -- the first card pops this far into the panel's rise (a share of it)
BoxPanel.DealEvery = 0.035 -- seconds between cards dealt, left to right, top row first
BoxPanel.DealMost = 0.6 -- seconds the whole deal takes at most, however many kinds
BoxPanel.Ripple = 0.012 -- seconds between cards re-dealt as a search or a chip narrows them
BoxPanel.Dim = 0.82 -- the screen behind the panel, darkened a touch (1 clear)
BoxPanel.Pressed = 0.88 -- a press: the button's scale at once, springing back
BoxPanel.Click = table.freeze({ id = "rbxassetid://15675059323", volume = 0.3, pitch = 1.15 })

return table.freeze(BoxPanel)
