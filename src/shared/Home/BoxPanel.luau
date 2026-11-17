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
]]
local Grades = require("../Grades")

local BoxPanel = {}

BoxPanel.RemoteFolder = "Remotes"
-- Server to the holder, as their box opens: the box, then its finds by name with how many.
BoxPanel.ListRemote = "JobBoxList"
-- The holder's screen to the server, nothing carried: shut my open box (its X, or a tap outside).
BoxPanel.CloseRemote = "JobBoxClose"
BoxPanel.Limit = { perSecond = 3, burst = 4 } -- Close asks a player may make: mashing costs nothing

BoxPanel.SearchMax = 24 -- characters the search box takes: a find's name is never longer
BoxPanel.KindsMax = 2000 -- kinds a list carries at most: far past every find there is

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

-- The screen's feel.
BoxPanel.Words =
	table.freeze({ search = "Search", all = "All", none = "No match", empty = "Empty" })
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
