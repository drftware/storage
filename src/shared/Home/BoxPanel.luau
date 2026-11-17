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
]]
local Grades = require("../Grades")

local BoxPanel = {}

BoxPanel.RemoteFolder = "Remotes"
-- Server to the holder, as their box opens: the box, then its finds by name with how many.
BoxPanel.ListRemote = "JobBoxList"
-- The holder's screen to the server, nothing carried: shut my open box (its X, or a tap outside).
BoxPanel.CloseRemote = "JobBoxClose"
BoxPanel.Limit = { perSecond = 3, burst = 4 } -- Close asks a player may make: mashing costs nothing
-- The holder's screen to the server (S5-03c2b2): take one find, by name, out of my open box, a way.
BoxPanel.TakeRemote = "JobBoxTake"
-- Server to the holder, every take answered: the name, the way, whether it came out, and where it
-- went (the slot it went into, or the shelf spot's place in the world).
BoxPanel.TookRemote = "JobBoxTook"
-- Takes a player may ask: three quick ones fill your hands, and a fourth tap never piles up more
BoxPanel.TakeLimit = { perSecond = 3, burst = 4 }

-- Where a find taken out goes: into your hands, or onto a free spot of your shelf.
export type Way = "Hand" | "Shelf"
BoxPanel.Ways = table.freeze({ Hand = "Hand" :: Way, Shelf = "Shelf" :: Way })

BoxPanel.SearchMax = 24 -- characters the search box takes: a find's name is never longer
BoxPanel.KindsMax = 2000 -- kinds a list carries at most: far past every find there is
BoxPanel.NameMax = 64 -- characters a find's name from the wire may have (the save's own limit)

-- A way from the wire, or nil when it isn't one.
function BoxPanel.way(value: unknown): Way?
	if value == "Hand" or value == "Shelf" then
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

-- A kind of find you own, as its card shows it.
export type Card = { key: string, name: string, grade: Grades.Grade, count: number }
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

-- One card for each kind in `finds` that the catalog knows as a find, rarest first, then by name.
function BoxPanel.cards(finds: { [string]: number }, catalog: { [string]: Row }): { Card }
	local out: { Card } = {}
	for key, count in finds do
		local row = catalog[key]
		if row and row.find and count >= 1 then
			table.insert(out, {
				key = key,
				name = row.name,
				grade = row.grade or "Common",
				count = count,
			})
		end
	end
	table.sort(out, function(a: Card, b: Card): boolean
		local ra, rb = RANK[a.grade] or 0, RANK[b.grade] or 0
		if ra ~= rb then
			return ra > rb
		end
		local na, nb = string.lower(a.name), string.lower(b.name)
		if na ~= nb then
			return na < nb
		end
		return a.key < b.key
	end)
	return out
end

-- The search as typed, cut to what the box takes.
function BoxPanel.search(text: string): string
	return string.sub(text, 1, BoxPanel.SearchMax)
end

-- Whether `card` is shown for the search `text` and the rarity `grade` (nil: every rarity).
function BoxPanel.match(card: Card, text: string, grade: Grades.Grade?): boolean
	if grade and card.grade ~= grade then
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
		have[card.grade] = true
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
