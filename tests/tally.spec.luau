--!strict
--[[
	The haul valued one find at a time (S5-01a, D-428, src/shared/Tally.luau): each find kept on
	the climb is a card worth what it sells for at your chest (sealed three times, cracked half);
	the cards come cheapest first, the same on every screen whatever order they were kept in; a
	short haul takes its time, a long one rattles through its cheap cards and still fits, while
	the last few and every sting card keep their beat; the total ticks up to the haul's worth and
	never back; a tap skips to the next sting card, else the end; the list rides the car's results
	and comes back the same, junk left out.

		lune run tests/tally.spec
]]
local BoxPanel = require("../src/shared/Home/BoxPanel")
local Catalog = require("../src/shared/Tools/Catalog")
local ClimbEnd = require("../src/shared/ClimbEnd")
local Seal = require("../src/shared/Finds/Seal")
local Tally = require("../src/shared/Tally")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

-- One find of each grade from the catalog, its first by key, and a plain one to fill hauls with.
local byGrade: { [string]: string } = {}
local keys: { string } = {}
for key in Catalog do
	table.insert(keys, key)
end
table.sort(keys)
for _, key in keys do
	local row = Catalog[key]
	if row.find and row.grade and row.size ~= "Big" and not byGrade[row.grade] then
		byGrade[row.grade] = key
	end
end
local COMMON, RARE = byGrade.Common, byGrade.Rare
local LEGENDARY, SECRET = byGrade.Legendary, byGrade.Secret
ok(
	COMMON ~= nil and RARE ~= nil and LEGENDARY ~= nil and SECRET ~= nil,
	"the catalog deals every grade"
)

-- A card: the catalog's name, grade and the chest's price.
local plain = Tally.card({ userId = 1, key = RARE })
ok(plain ~= nil, "a plain find makes a card")
if plain then
	local row = Catalog[RARE]
	ok(plain.name == row.name and plain.grade == row.grade, "a card names its find and grade")
	ok(plain.worth == BoxPanel.price(row), "a card is worth the chest's price")
	ok(not plain.sealed and not plain.cracked and plain.sting == nil, "a plain Rare has no sting")
	ok(plain.find == RARE and plain.key == RARE, "a plain card's find is its key")
end
local sealed = Tally.card({ userId = 1, key = Seal.key(RARE) })
ok(
	sealed ~= nil and plain ~= nil and sealed.worth == plain.worth * Seal.Times,
	"sealed: three times"
)
ok(sealed ~= nil and sealed.sealed and sealed.sting == "Sealed", "sealed: its own sting")
ok(sealed ~= nil and sealed.find == RARE and sealed.key == Seal.key(RARE), "sealed: of its find")
local cracked = Tally.card({ userId = 1, key = RARE, cracked = true })
ok(cracked ~= nil and plain ~= nil and cracked.worth < plain.worth, "cracked: worth less")
ok(cracked ~= nil and cracked.cracked, "cracked: marked")
local juke = Tally.card({ userId = 1, key = "Jukebox" })
ok(
	juke ~= nil and juke.sting == "Big" and juke.worth == BoxPanel.price(Catalog.Jukebox),
	"the jukebox"
)
local secret = Tally.card({ userId = 1, key = SECRET })
ok(secret ~= nil and secret.sting == "Secret", "a Secret's sting")
local sealedSecret = Tally.card({ userId = 1, key = Seal.key(SECRET) })
ok(sealedSecret ~= nil and sealedSecret.sting == "Secret", "a sealed Secret stings as a Secret")
local legend = Tally.card({ userId = 1, key = LEGENDARY })
ok(legend ~= nil and legend.sting == "Legendary", "a Legendary's sting")
ok(Tally.card({ userId = 1, key = "NoSuchFind" }) == nil, "an unknown key makes no card")
ok(Tally.card({ userId = 1, key = "BoltCutters" }) == nil, "a tool makes no card")
ok(Tally.card({ userId = 1, key = COMMON .. ":Gold" }) == nil, "a Gold isn't a climb's find")

-- Order: cheapest first, the same whatever order they were kept in.
local mixed = {
	{ userId = 2, key = SECRET },
	{ userId = 1, key = COMMON },
	{ userId = 3, key = Seal.key(RARE) },
	{ userId = 1, key = RARE },
	{ userId = 2, key = COMMON },
	{ userId = 1, key = "Jukebox" },
	{ userId = 3, key = RARE, cracked = true },
}
local cards = Tally.cards(mixed)
ok(#cards == #mixed, "every find a card")
for i = 2, #cards do
	ok(cards[i - 1].worth <= cards[i].worth, `cheapest first ({i})`)
end
ok(cards[1].key == COMMON and cards[1].userId == 1 and cards[2].userId == 2, "a tie: by who")
local reversed = table.clone(mixed)
for i = 1, #reversed // 2 do
	local j = #reversed - i + 1
	reversed[i], reversed[j] = reversed[j], reversed[i]
end
local again = Tally.cards(reversed)
local same = #again == #cards
for i, card in cards do
	local other = again[i]
	same = same
		and other ~= nil
		and other.key == card.key
		and other.userId == card.userId
		and other.cracked == card.cracked
end
ok(same, "the same order whatever order they were kept in")
ok(
	#Tally.cards({ { userId = 1, key = "NoSuchFind" }, { userId = 1, key = COMMON } }) == 1,
	"junk skipped"
)

-- Timing: a short haul takes its time.
local starts, ends = Tally.times(Tally.cards({
	{ userId = 1, key = COMMON },
	{ userId = 1, key = COMMON },
	{ userId = 1, key = RARE },
}))
ok(starts[1] == 0, "the first card comes at once")
ok(
	math.abs(starts[2] - Tally.Beat) < 1e-9 and math.abs(ends - 3 * Tally.Beat) < 1e-9,
	"a short haul: a beat each"
)
local none, noEnd = Tally.times({})
ok(#none == 0 and noEnd == 0, "no haul, no time")

-- A sting card holds its quiet after it lands.
local withSting = Tally.cards({ { userId = 1, key = COMMON }, { userId = 1, key = SECRET } })
local s2, e2 = Tally.times(withSting)
ok(math.abs(e2 - s2[2] - (Tally.Beat + Tally.Holds.Secret)) < 1e-9, "a Secret holds its quiet")

-- A long haul rattles through and still fits; the last few and the stings keep their beat.
local long: { Tally.Find } = {}
for i = 1, 30 do
	table.insert(long, { userId = 1 + i % 3, key = COMMON })
end
table.insert(long, { userId = 1, key = SECRET })
table.insert(long, { userId = 2, key = LEGENDARY })
local longCards = Tally.cards(long)
local ls, le = Tally.times(longCards)
ok(le <= Tally.Within + 1e-6, `a long haul fits ({le})`)
local n = #longCards
for i = 2, n do
	local gap = ls[i] - ls[i - 1]
	ok(gap >= Tally.Quick - 1e-9, `no card quicker than Quick ({i})`)
	if i - 1 > n - Tally.Slow then
		ok(gap >= Tally.Beat - 1e-9, `the last few keep their beat ({i})`)
	end
end
ok(ls[2] - ls[1] < Tally.Beat, "the cheap ones quicken")
ok(le - ls[n] >= Tally.Beat, "the last card keeps its beat")

-- A haul too long to fit even at the quickest still runs every card, no quicker than Quick.
local huge: { Tally.Find } = {}
for i = 1, Tally.Cap do
	table.insert(huge, { userId = 1, key = if i % 10 == 0 then LEGENDARY else COMMON })
end
local hs, he = Tally.times(Tally.cards(huge))
ok(#hs == Tally.Cap and he > 0, "a huge haul still runs")
for i = 2, #hs do
	ok(hs[i] > hs[i - 1], `still in order ({i})`)
end

-- The total: nothing before the first lands, the haul's worth at the end, never going back.
local sum = 0
for _, card in cards do
	sum += card.worth
end
local cs, ce = Tally.times(cards)
ok(Tally.total(cards, cs, ce, 0) == 0, "nothing counted before the first lands")
ok(
	Tally.total(cards, cs, ce, ce) == sum,
	`the haul's worth at the end ({Tally.total(cards, cs, ce, ce)} of {sum})`
)
ok(Tally.total(cards, cs, ce, ce + 5) == sum, "and after")
local last = -1
local rises = true
for step = 0, math.ceil(ce / 0.02) do
	local shown = Tally.total(cards, cs, ce, step * 0.02)
	rises = rises and shown >= last and shown == math.floor(shown)
	last = shown
end
ok(rises, "the total only ticks up, in whole dollars")
local ltotal = 0
for _, card in longCards do
	ltotal += card.worth
end
ok(Tally.total(longCards, ls, le, le) == ltotal, "a long haul's total lands whole")

-- A tap: to the next sting card, else the end.
local firstSting = 0
for i, card in cards do
	if card.sting then
		firstSting = i
		break
	end
end
ok(firstSting > 0, "the mixed haul has a sting")
ok(Tally.skip(cards, cs, ce, 0) == cs[firstSting], "a tap goes to the next sting card")
ok(Tally.skip(cards, cs, ce, cs[#cards] + 0.01) == ce, "after the last sting, to the end")
ok(Tally.skip(cards, cs, ce, ce + 1) == ce + 1, "at the end, nowhere")
ok(Tally.skip({}, {}, 0, 0) == 0, "no haul, no skip")

-- The list on the car's results comes back the same.
local value = Tally.encode(mixed)
ok(not string.find(value, "|", 1, true), "no bar in the list (the results' field mark)")
local back = Tally.decode(value)
local backCards = Tally.cards(back)
local alike = #backCards == #cards
for i, card in cards do
	local other = backCards[i]
	alike = alike
		and other ~= nil
		and other.key == card.key
		and other.userId == card.userId
		and other.cracked == card.cracked
		and other.worth == card.worth
end
ok(alike, "the list comes back the same")
local studio = Tally.decode(Tally.encode({ { userId = -1, key = COMMON } }))
ok(#studio == 1 and studio[1].userId == -1, "Studio's test players (negative ids) come back")
ok(#Tally.decode(nil) == 0 and #Tally.decode(42) == 0, "not a list, nothing")
local junk = Tally.decode(`1={COMMON},x=Teddy,2=NoSuchFind,3={COMMON}?,,4={RARE}!`)
ok(#junk == 2 and junk[2].cracked == true, "junk cells skipped, a cracked one kept")
local most = Tally.decode(Tally.encode(huge))
ok(#most == Tally.Cap, "a capped list comes back whole")
local over = table.clone(huge)
table.insert(over, { userId = 9, key = SECRET })
local capped = Tally.cards(Tally.decode(Tally.encode(over)))
ok(#capped == Tally.Cap and capped[#capped].key == SECRET, "past the cap, the cheapest go first")

-- Inside the car's results value, and the results still read without one.
local results = ClimbEnd.encodeResults("Kept", 7, 300, {
	{ userId = 1, fate = "Kept", floor = 7, cash = 12 },
}, value)
local read = ClimbEnd.decodeResults(results)
ok(
	read ~= nil and read.haul == value and #read.rows == 1 and read.rows[1].cash == 12,
	"the haul rides the results"
)
local old = ClimbEnd.decodeResults("Kept|7|300|1:Kept:7:12")
ok(old ~= nil and old.haul == "" and #old.rows == 1, "results with no haul read as none")
local empty = ClimbEnd.decodeResults(ClimbEnd.encodeResults("Kept", 3, 60, {}))
ok(empty ~= nil and empty.haul == "" and #empty.rows == 0, "no rows, no haul")

-- The row under the stage (S5-01b): every landed card fits it as a chip, as wide as allowed for a
-- short haul, crowding to slivers with a hairline gap for the longest, never past the row.
do
	local w0, g0 = Tally.row(0, 506)
	ok(w0 == 0 and g0 == 0, "no chips, no row")
	local w1 = Tally.row(1, 506)
	ok(w1 == Tally.ChipMost, "one chip is as wide as a chip gets")
	local w5, g5 = Tally.row(5, 506)
	ok(
		w5 == Tally.ChipMost and g5 == Tally.ChipGap,
		"a short haul's chips keep their width and gap"
	)
	for _, n in { 12, 20, 40, Tally.Cap } do
		local w, g = Tally.row(n, 506)
		ok(w > 0 and n * w + (n - 1) * g <= 506 + 1e-6, `{n} chips fit the row`)
	end
	local w60, g60 = Tally.row(Tally.Cap, 506)
	ok(g60 == 1 and w60 >= 6, "sixty crowd to slivers with a hairline gap, each still seen")
end

print(`tally.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
