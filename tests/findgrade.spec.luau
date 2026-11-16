--!strict
-- lune run tests/findgrade.spec
-- Finds dealt by grade (F-G1a, D-188): each band's odds add to 100 and the Secret chance doubles
-- from floor 50; a unit's find is a grade rolled by the floor, then a find of that grade, so over
-- every pick each grade turns up at its odds and each find of a grade as often as the others; a
-- find is never dealt below its floor (the Secret lamp from 25); the Packrat's pile never
-- repeats; and every find dealt has a grade and a worth inside its grade's.
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

print(`findgrade: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
