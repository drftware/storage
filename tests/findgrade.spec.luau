--!strict
-- lune run tests/findgrade.spec
-- Finds dealt by grade (F-G1a, D-188): each band's odds add to 100 and the Secret chance doubles
-- from floor 50; a unit's find is a grade rolled by the floor, then a find of that grade, so over
-- every pick each grade turns up at its odds and each find of a grade as often as the others; a
-- find is never dealt below its floor (the Secret lamp from 25); the Packrat's pile never
-- repeats; and every find dealt has a grade and a worth inside its grade's. S5-02a: each floor's
-- finds a little better than the floor below's, the catalog's odds on its own floors; a padlocked
-- unit's find a grade better; and the same seed dealing the same floor.
local Catalog = require("../src/shared/Tools/Catalog")
local Deal = require("../src/shared/Deal")
local Grades = require("../src/shared/Grades")

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

for _, band in Grades.Bands do
	local sum = 0
	for _, grade in Grades.Names do
		sum += band.odds[grade]
	end
	ok(math.abs(sum - 100) < 1e-9, `floor {band.from} up: the grades add to 100 ({sum})`)
end
ok(Grades.odds(1).Secret == 0 and Grades.odds(9).Secret == 0, "no Secret below floor 10")
ok(Grades.odds(10).Secret > 0, "a Secret can turn up from floor 10")
ok(Grades.odds(50).Secret == 2 * Grades.odds(49).Secret, "the Secret chance doubles at 50")
ok(Grades.odds(9).Legendary < Grades.odds(10).Legendary, "higher floors, rarer finds")

for _, name in Deal.Finds do
	local row = Catalog[name]
	ok(row ~= nil and row.find == true, `{name}: a find's row`)
	local range = if row and row.grade then Grades.Worth[row.grade] else nil
	ok(range ~= nil, `{name}: a grade`)
	ok(
		range ~= nil and row.worth ~= nil and row.worth >= range[1] and row.worth <= range[2],
		`{name}: worth inside its grade's`
	)
end

-- Over N evenly spread picks on floor `number`: how often each grade and each find comes.
local N = 20000
local function spread(number: number): ({ [string]: number }, { [string]: number })
	local grades, finds, missed = {}, {}, 0
	for i = 0, N - 1 do
		local find = Deal.findFrom(number, (i + 0.5) / N)
		missed += if find then 0 else 1
		if find then
			finds[find] = (finds[find] or 0) + 1
			local grade = Catalog[find].grade :: string
			grades[grade] = (grades[grade] or 0) + 1
		end
	end
	ok(missed == 0, `floor {number}: a find for every pick`)
	return grades, finds
end

-- the grades present on a floor, and their odds out of those present
local function present(number: number): { [string]: number }
	local odds, out, total = Grades.odds(number), {}, 0
	for _, name in Deal.Finds do
		local row = Catalog[name]
		if (row.from or 1) <= number and row.grade and odds[row.grade] > 0 then
			out[row.grade] = odds[row.grade]
		end
	end
	for _, o in out do
		total += o
	end
	for g, o in out do
		out[g] = o / total
	end
	return out
end

for _, number in { 1, 3, 12, 30, 60 } do
	local grades, finds = spread(number)
	local want = present(number)
	for _, grade in Grades.Names do
		local got = (grades[grade] or 0) / N
		ok(
			math.abs(got - (want[grade] or 0)) < 0.002,
			`floor {number}: {grade} about {want[grade] or 0} of finds ({got})`
		)
	end
	-- each find of a grade as likely as the others
	local byGrade: { [string]: { number } } = {}
	for name, count in finds do
		local g = Catalog[name].grade :: string
		byGrade[g] = byGrade[g] or {}
		table.insert(byGrade[g], count)
	end
	for grade, counts in byGrade do
		local lo, hi = math.huge, 0
		for _, c in counts do
			lo, hi = math.min(lo, c), math.max(hi, c)
		end
		ok(hi - lo <= 1, `floor {number}: each {grade} find as likely ({lo} to {hi})`)
	end
	ok(
		(finds.UnpluggedLamp ~= nil) == (number >= 25),
		`floor {number}: the Secret lamp only from floor 25`
	)
end

-- the commons are 62 in 100 on the first floors: the teddy is common, the glass lamp rare (13
-- commons share the 62 and 2 Legendaries the half, so about 19 teddies to a glass lamp, F-G1d)
do
	local _, finds = spread(1)
	ok(
		(finds.Teddy or 0) > 12 * (finds.StainedGlassLamp or 0),
		"a teddy far more often than the glass lamp"
	)
end

-- what's taken is left out; a pick of 0 or 1 still lands
do
	local all = table.clone(Deal.Finds)
	local only = table.remove(all, table.find(all, "Boombox") :: number)
	for _, pick in { 0, 0.3, 0.999, 1 } do
		ok(Deal.findFrom(1, pick, all) == only, `with all else taken, the boombox ({pick})`)
		ok(Deal.findFrom(1, pick) ~= nil, `a pick of {pick} lands`)
	end
	ok(Deal.findFrom(1, 0.5, Deal.Finds) == nil, "nothing left: nothing dealt")
end

-- Better finds every floor up (S5-02a): the catalog's odds stand on its own floors (1, 10, 25),
-- and between them each floor is a little better than the one below, never only at a step; no
-- Secret below floor 10.
for _, band in Grades.Bands do
	local odds = Grades.odds(band.from)
	for _, grade in Grades.Names do
		ok(
			math.abs(odds[grade] - band.odds[grade]) < 1e-9,
			`floor {band.from}: the catalog's {grade} ({odds[grade]})`
		)
	end
end
do
	local last = Grades.odds(1)
	for n = 2, 60 do
		local odds = Grades.odds(n)
		local sum = 0
		for _, grade in Grades.Names do
			sum += odds[grade]
		end
		local want = if n >= Grades.SecretDoubles then 100 + odds.Secret / 2 else 100
		ok(math.abs(sum - want) < 1e-9, `floor {n}: the grades add to {want} ({sum})`)
		ok(n >= 10 or odds.Secret == 0, `floor {n}: no Secret below floor 10`)
		ok(odds.Common <= last.Common + 1e-9, `floor {n}: no more commons than below`)
		local best, lastBest = odds.Legendary + odds.Secret, last.Legendary + last.Secret
		if n <= 25 then
			ok(odds.Common < last.Common, `floor {n}: fewer commons than the floor below`)
			ok(best > lastBest, `floor {n}: the best finds likelier than the floor below`)
		else
			ok(best >= lastBest - 1e-9, `floor {n}: the best finds no rarer than below`)
		end
		last = odds
	end
end

-- The grades floor `number` deals, commonest first: each with a find and a chance there.
local function ladder(number: number): { string }
	local odds, out = Grades.odds(number), {}
	for _, grade in Grades.Names do
		for _, name in Deal.Finds do
			local row = Catalog[name]
			if row.grade == grade and (row.from or 1) <= number and odds[grade] > 0 then
				table.insert(out, grade)
				break
			end
		end
	end
	return out
end

-- A padlocked unit's find, a grade better (S5-02a, GDD "Doors": the best chance of something
-- great): the same pick lands on the plain roll's grade one up the floor's ladder, its top grade
-- staying its top; never a common, never a Secret below floor 10; and each find of the better
-- grade still as likely as the others.
for _, number in { 1, 2, 9, 10, 12, 24, 25, 30, 60 } do
	local rungs = ladder(number)
	local top = #rungs
	local bad, commons, secrets = 0, 0, 0
	local finds: { [string]: number } = {}
	for i = 0, N - 1 do
		local pick = (i + 0.5) / N
		local plain = Deal.findFrom(number, pick)
		local locked = Deal.findFrom(number, pick, nil, Deal.PadlockedBetter)
		local from = if plain then table.find(rungs, Catalog[plain].grade :: string) else nil
		local to = if locked then table.find(rungs, Catalog[locked].grade :: string) else nil
		if not (from and to and to == math.min(top, from + 1)) then
			bad += 1
		end
		if locked then
			finds[locked] = (finds[locked] or 0) + 1
			local grade = Catalog[locked].grade
			commons += if grade == "Common" then 1 else 0
			secrets += if grade == "Secret" then 1 else 0
		end
	end
	ok(bad == 0, `floor {number}: a padlock's find one grade better, every pick ({bad} not)`)
	ok(commons == 0, `floor {number}: never a common behind a padlock ({commons})`)
	ok(number >= 10 or secrets == 0, `floor {number}: no Secret behind a padlock below 10`)
	local byGrade: { [string]: { number } } = {}
	for name, count in finds do
		local g = Catalog[name].grade :: string
		byGrade[g] = byGrade[g] or {}
		table.insert(byGrade[g], count)
	end
	for grade, counts in byGrade do
		local lo, hi = math.huge, 0
		for _, c in counts do
			lo, hi = math.min(lo, c), math.max(hi, c)
		end
		ok(hi - lo <= 1, `floor {number}: behind a padlock, each {grade} as likely ({lo}, {hi})`)
	end
end
ok(Deal.findFrom(1, 1, nil, 1) ~= nil and Deal.findFrom(1, 0, nil, 3) ~= nil, "the ends land")

-- The same seed deals the same floor (S5-02a): every unit opened twice from one seed holds the
-- same, a padlocked unit's find is its pick rolled a grade better and an ordinary one's its pick
-- rolled plain, as the server deals a climb's floor (`Climbs`: the layout's Random carries on).
do
	local Brix = require("../vendor/brix/src")
	local Climb = require("../src/shared/Climb")
	local Floor = require("../src/shared/Floor")
	local situation: Deal.Situation = { mood = "Build", awake = 0 }
	local function dealt(seed: number, number: number): (Deal.Deck, { [number]: Deal.Contents })
		local random = Brix.Random.new({ seed = Climb.seedOf(seed, number) })
		local deck = Deal.new(Floor.generate(number, random), random)
		local out = {}
		for _, index in Deal.units(deck.floor) do
			out[index] = Deal.open(deck, index, situation)
		end
		return deck, out
	end
	local lockedFinds = 0
	for _, number in { 2, 10, 12 } do
		for seed = 1, 4 do
			local deck, first = dealt(seed, number)
			local _, again = dealt(seed, number)
			local same = 0
			for index, c in first do
				local d = again[index]
				if
					d.kind == c.kind
					and d.find == c.find
					and d.tool == c.tool
					and d.keeper == c.keeper
					and d.coins == c.coins
				then
					same += 1
				end
				if c.kind == "Find" and c.find and not deck.big[index] then
					local better = if deck.padlocked[index] then Deal.PadlockedBetter else 0
					ok(
						c.find == Deal.findFrom(number, deck.picks[index], nil, better),
						`seed {seed} floor {number} unit {index}: its pick's find`
					)
					lockedFinds += if deck.padlocked[index] then 1 else 0
				end
			end
			local count = 0
			for _ in first do
				count += 1
			end
			ok(same == count, `seed {seed} floor {number}: the same seed, the same deal`)
		end
	end
	ok(lockedFinds > 0, `some padlocked units dealt a find ({lockedFinds})`)
end

print(`findgrade: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
