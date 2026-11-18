--!strict
--[[
	Tally (S5-01a, D-428): the haul valued one find at a time on the results, its order and its
	timing. The moment it serves: back in the lobby car after a climb, the team stands facing the
	board on its back wall and watches what they carried home flip up card by card, the cheap ones
	first and the best last, the total ticking up with each; a Secret, a find still sealed, a
	Legendary or the jukebox lands with its own sting and a beat of quiet. Lethal Company ends
	each day on a tally of the scrap brought in, Hades closes a run on what you earned, and the
	storage-auction shows open the unit first and value it afterwards (PROPOSAL idea 25).

	Each find kept on the climb (GatePay: what a rider carried aboard as a gate shut, not a friend's
	find taken up from home) is a card: its name, its grade and what it sells for at your chest
	(`BoxPanel.price`: sealed three times, cracked half, the jukebox its own worth). The cash itself
	comes when you sell (D-251); the total is what the haul is worth.

	It never drags: a short haul takes its time (`Beat` a card); a long one rattles through its
	cheap cards (never quicker than `Quick`) so the whole run fits `Within`, while the last `Slow`
	cards and every sting card keep their beat. A tap skips to the next sting card, else the end.

	The server sends the haul inside the car's results (`encode`, in `ClimbEnd.encodeResults`) and
	every screen orders and times it the same way. Nothing here touches an Instance, so Lune tests
	it (tests/tally.spec.luau).
]]
local BoxPanel = require("./Home/BoxPanel")
local Catalog = require("./Tools/Catalog")
local Grades = require("./Grades")
local Seal = require("./Finds/Seal")

local Tally = {}

-- One find kept on the climb: whose it is now, its name as kept ("Teddy", "Teddy:Sealed"), and
-- whether its glass cracked on the way.
export type Find = { userId: number, key: string, cracked: boolean? }

-- Why a card lands with its own sting: the top grade, the floor's big find, a find still in its
-- packaging, or a Legendary.
export type Sting = "Secret" | "Big" | "Sealed" | "Legendary"

-- A find on the board: whose, its key as kept, the catalog's find it is, its name and grade, and
-- what it sells for at the chest.
export type Card = {
	userId: number,
	key: string,
	find: string,
	name: string,
	grade: Grades.Grade,
	worth: number,
	sealed: boolean,
	cracked: boolean,
	sting: Sting?,
}

-- Seconds a card has to itself in a short haul: it flips up, and there's a breath to read its
-- name and worth before the next. Longer drags a three-find haul; shorter and nothing reads.
Tally.Beat = 0.62
-- The quickest a long haul's cheap cards come, in seconds: a rattle of cards, each still seen.
Tally.Quick = 0.14
-- The last cards of every haul that keep their full beat, so it slows into the best.
Tally.Slow = 3
-- Seconds the cards may take in all, at most, while the quickest beat allows: the car's count is
-- 20 (Boarding.Seconds), and the black's lift and each friend's line come out of the rest.
Tally.Within = 8
-- Seconds of quiet after a sting card lands, on top of its beat: the Secret longest.
Tally.Holds = {
	Secret = 1.4,
	Big = 1.0,
	Sealed = 0.7,
	Legendary = 0.7,
} :: { [string]: number }
-- The least of each hold a long haul keeps, as a share, when even its quickest beats overrun.
Tally.HoldLeast = 0.4
-- Seconds from a card's start to its landing, when its worth starts onto the total.
Tally.Land = 0.18
-- Seconds a card's worth takes to tick onto the total, fast and then the last dollars one by
-- one (sooner if the next card comes sooner). Land and Count stay inside a beat, so the total
-- is whole as the last card's beat ends.
Tally.Count = 0.4
-- The most cards a board shows: past it (a haul no climb keeps today), the cheapest are left off.
Tally.Cap = 60

-- The board (S5-01b, CarResults): the team's page holds this long once its photos are pinned and
-- its cash has landed, then turns over to the haul: long enough to see who made it, never a wait.
Tally.Read = 0.9
-- Seconds the page takes to turn from the team to the haul (the team lifts off, the haul rises).
Tally.Turn = 0.42
-- Seconds the card on the stage takes to drop into its chip in the row as the next flips up, at
-- most: quicker when a long haul's next card comes sooner, so the row never lags the stage.
Tally.Drop = 0.24
-- How big a sting card swells as it lands, before settling: it hits the board.
Tally.Swell = 1.24
-- Seconds a sting card's flash of its grade's colour takes to fade off the board.
Tally.Flash = 0.6
-- How strong that flash starts (0 a solid wash of colour, 1 none): the board still reads through.
Tally.FlashFrom = 0.4
-- The widest a chip in the row gets (px on the board's canvas), and the gap between two; once
-- they crowd (a long haul) the gap is a hairline, so even `Cap` chips fit.
Tally.ChipMost = 44
Tally.ChipGap = 4

-- The board's few words: the haul's total, and a cracked find's mark beside its grade.
Tally.Copy = table.freeze({ Total = "Total", Cracked = "Cracked" })

export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }
-- A card flipping up: "File Folder Movement 5", the sheet's sharp flap (NoteView's card, the
-- code's note coming out of its box), its flap 0.04 s in.
Tally.Flap = table.freeze({
	id = "rbxassetid://9114409576",
	from = 0.74,
	length = 0.26,
	volume = 0.55,
	pitch = 1.08,
}) :: Sound
-- How much lower each grade's flap is than the last: the better the find, the heavier the card.
Tally.FlapDrop = 0.04
-- A sting card hitting the board: the slam's bang (a gas tank dropped on loose metal, Pay's
-- PopBang), pitched well down, under the grade's own burst (Boxes.Reveal) or a sealed pack's
-- crinkle.
Tally.Hit = table.freeze({
	id = "rbxassetid://9120381070",
	from = 0.36,
	length = 0.75,
	volume = 0.8,
	pitch = 0.68,
}) :: Sound

-- The row under the stage: how wide each of `n` chips is, and the gap between two, to fit `width`
-- (px). As wide as `ChipMost` while they fit; past that they crowd, the gap a hairline.
function Tally.row(n: number, width: number): (number, number)
	if n <= 0 then
		return 0, 0
	end
	local gap = Tally.ChipGap
	local w = (width + gap) / n - gap
	if w < Tally.ChipGap * 3 then
		gap = 1
		w = (width + gap) / n - gap
	end
	return math.min(w, Tally.ChipMost), gap
end

local RANK: { [string]: number } = {}
for i, grade in Grades.Names do
	RANK[grade] = i
end

-- The card for one find kept, or nil when the key isn't a find (a tool, a Gold, junk).
function Tally.card(find: Find): Card?
	local base = Seal.base(find.key)
	local name = base or find.key
	local row = Catalog[name]
	if not row or not row.find or not row.grade then
		return nil
	end
	local sealed = base ~= nil
	local cracked = find.cracked == true
	local grade = row.grade :: Grades.Grade
	local sting: Sting? = if grade == "Secret"
		then "Secret"
		elseif row.size == "Big" then "Big"
		elseif sealed then "Sealed"
		elseif grade == "Legendary" then "Legendary"
		else nil
	local card: Card = {
		userId = find.userId,
		key = find.key,
		find = name,
		name = row.name or name,
		grade = grade :: Grades.Grade,
		worth = BoxPanel.price(row, false, cracked, sealed),
		sealed = sealed,
		cracked = cracked,
		sting = sting,
	}
	return card
end

-- Cheapest first; a tie by grade, then by find, a cracked one first, then by whose.
local function before(a: Card, b: Card): boolean
	if a.worth ~= b.worth then
		return a.worth < b.worth
	end
	local ra, rb = RANK[a.grade] or 0, RANK[b.grade] or 0
	if ra ~= rb then
		return ra < rb
	end
	if a.key ~= b.key then
		return a.key < b.key
	end
	if a.cracked ~= b.cracked then
		return a.cracked
	end
	return a.userId < b.userId
end

-- The haul's cards in the order they come up, cheapest first; keys that aren't finds left out.
function Tally.cards(finds: { Find }): { Card }
	local cards: { Card } = {}
	for _, find in finds do
		local card = Tally.card(find)
		if card then
			table.insert(cards, card)
		end
	end
	table.sort(cards, before)
	return cards
end

-- Seconds of quiet a card holds after it lands (none for a plain one).
function Tally.hold(card: Card): number
	local sting = card.sting
	return if sting then Tally.Holds[sting] or 0 else 0
end

-- When each card comes up, in seconds from the tally's start, and when the run is over (the last
-- card's beat and hold done).
function Tally.times(cards: { Card }): ({ number }, number)
	local n = #cards
	local starts: { number } = table.create(n)
	if n == 0 then
		return starts, 0
	end
	local slowFrom = n - math.min(Tally.Slow, n) + 1
	local steady, quickOnes, holds = 0, 0, 0
	for i, card in cards do
		if i >= slowFrom or card.sting then
			steady += 1
		else
			quickOnes += 1
		end
		holds += Tally.hold(card)
	end
	local quick = Tally.Beat
	if quickOnes > 0 then
		local room = Tally.Within - steady * Tally.Beat - holds
		quick = math.clamp(room / quickOnes, Tally.Quick, Tally.Beat)
	end
	local beats = steady * Tally.Beat + quickOnes * quick
	local share = 1
	if holds > 0 and beats + holds > Tally.Within then
		share = math.clamp((Tally.Within - beats) / holds, Tally.HoldLeast, 1)
	end
	local t = 0
	for i, card in cards do
		starts[i] = t
		local beat = if i >= slowFrom or card.sting then Tally.Beat else quick
		t += beat + Tally.hold(card) * share
	end
	return starts, t
end

-- The haul's worth shown `t` seconds into the tally: each landed card's worth ticking on, fast
-- and then the last dollars one by one, in whole dollars.
function Tally.total(cards: { Card }, starts: { number }, ends: number, t: number): number
	local sum = 0
	for i, card in cards do
		local start = starts[i]
		local land = start + Tally.Land
		if t <= land then
			break
		end
		local gap = (starts[i + 1] or ends) - start
		local span = math.min(Tally.Count, gap * 0.9)
		local u = if span > 0 then math.clamp((t - land) / span, 0, 1) else 1
		local rest = 1 - u
		sum += card.worth * (1 - rest * rest * rest)
	end
	return math.floor(sum + 1e-6)
end

-- Where a tap `t` seconds in skips the tally to: the next sting card's start, else the end.
function Tally.skip(cards: { Card }, starts: { number }, ends: number, t: number): number
	for i, card in cards do
		if card.sting and starts[i] > t + 1e-3 then
			return starts[i]
		end
	end
	return math.max(ends, t)
end

-- The haul as it rides in the car's results: "<userId>=<key>" each, "!" after a cracked one,
-- comma separated; at most `Cap`, the cheapest left off past it.
function Tally.encode(finds: { Find }): string
	local cards = Tally.cards(finds)
	local cells: { string } = {}
	for i = math.max(#cards - Tally.Cap, 0) + 1, #cards do
		local card = cards[i]
		table.insert(
			cells,
			string.format("%d=%s%s", card.userId, card.key, if card.cracked then "!" else "")
		)
	end
	return table.concat(cells, ",")
end

-- The haul read back from the car's results; a cell that doesn't read, or isn't a find, is
-- skipped. Never more than `Cap`.
function Tally.decode(value: unknown): { Find }
	local finds: { Find } = {}
	if type(value) ~= "string" then
		return finds
	end
	for cell in string.gmatch(value, "[^,]+") do
		if #finds >= Tally.Cap then
			break
		end
		local id, key, mark = string.match(cell, "^(%-?%d+)=([%w:]+)(!?)$")
		local userId = if id then tonumber(id) else nil
		if userId and key then
			local find: Find =
				{ userId = userId, key = key, cracked = if mark == "!" then true else nil }
			if Tally.card(find) then
				table.insert(finds, find)
			end
		end
	end
	return finds
end

return table.freeze(Tally)
