--!strict
-- lune run tests/floorrules.spec
-- The floor rules (S4-01a, GDD "Floor rules"): one table says, for any floor number, how the
-- floor is laid and dealt, and the climb has no top, so every answer must hold from floor 1 to far
-- past 100. Each value stays in range; nothing gets easier as you climb (more loose, more locks,
-- more packed; the teaching floors never come back); the steps are in order and each changes
-- something; a floor's rules are the same frozen table every time. The other per-floor curves
-- (waking, pay, the Mannequin's breaker errands, find grades) hold far up too, never easier. Floors well past
-- 100 lay and deal like any other: their units numbered after the floor ("10001"), their notes
-- the rules' count.
local Brix = require("../vendor/brix/src")
local Breaker = require("../src/shared/Breaker")
local Climb = require("../src/shared/Climb")
local Deal = require("../src/shared/Deal")
local Floor = require("../src/shared/Floor")
local FloorRules = require("../src/shared/FloorRules")
local Grades = require("../src/shared/Grades")
local Pay = require("../src/shared/Pay")
local Waking = require("../src/shared/Waking")

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

local HIGH = 300 -- the floors checked one by one: three times the GDD's "about 100"
local CODE = 4 -- the code's digits, split evenly across the notes

-- 1. The steps: in order from floor 1, the first setting every rule, each one changing something.
local steps = FloorRules.Steps
ok(steps[1].from == 1, "the first step is floor 1's")
local first = steps[1]
ok(
	first.teaching ~= nil
		and first.plan ~= nil
		and first.units ~= nil
		and first.notes ~= nil
		and first.padlocks ~= nil
		and first.padlockedNote ~= nil
		and first.awake ~= nil,
	"the first step sets every rule"
)
for i = 2, #steps do
	local s = steps[i]
	ok(s.from > steps[i - 1].from, `step "{s.name}" comes after "{steps[i - 1].name}"`)
	ok(s.from == math.floor(s.from), `step "{s.name}" starts on a whole floor`)
	local below, at = FloorRules.at(s.from - 1), FloorRules.at(s.from)
	ok(at.step == s.name, `floor {s.from} is named for "{s.name}"`)
	local changed = below.teaching ~= at.teaching
		or below.plan ~= at.plan
		or below.units ~= at.units
		or below.notes ~= at.notes
		or below.padlocks ~= at.padlocks
		or below.padlockedNote ~= at.padlockedNote
		or below.awake ~= at.awake
	ok(changed, `step "{s.name}" changes something on floor {s.from}`)
end

-- 2. Every floor's rules in range, and nothing easier higher up.
local last: FloorRules.Rules? = nil
for n = 1, HIGH do
	local r = FloorRules.at(n)
	local where = `floor {n}`
	ok(r.number == n, `{where}: its own number`)
	ok(r == FloorRules.at(n), `{where}: the same rules every time`)
	ok(table.isfrozen(r), `{where}: its rules can't be changed`)
	ok(r.step ~= "", `{where}: named for a step`)
	ok(r.plan == "Short" or r.plan == "Full", `{where}: a plan Floor has`)
	ok(
		r.units >= 1 and r.units <= Floor.MaxUnits and r.units == math.floor(r.units),
		`{where}: keeps a whole number of doors, 1 to {Floor.MaxUnits} ({r.units})`
	)
	ok(
		r.notes >= 1 and CODE % r.notes == 0,
		`{where}: the code's digits split evenly ({r.notes} notes)`
	)
	ok(
		r.padlocks >= 0 and r.padlocks <= 0.5,
		`{where}: at most half its doors padlocked ({r.padlocks})`
	)
	ok(
		r.awake >= 1 and r.awake <= Waking.AwakeMost,
		`{where}: 1 to {Waking.AwakeMost} loose ({r.awake})`
	)
	ok(
		r.packed >= 0 and r.packed <= FloorRules.PackedMost,
		`{where}: packed at most {FloorRules.PackedMost}`
	)
	ok(not (r.teaching and r.plan ~= "Short"), `{where}: a teaching floor is short`)
	if last then
		ok(r.units >= last.units, `{where}: no fewer doors than the floor below`)
		ok(r.awake >= last.awake, `{where}: no fewer loose than the floor below`)
		ok(r.padlocks >= last.padlocks, `{where}: no fewer padlocks than the floor below`)
		ok(r.packed >= last.packed, `{where}: no less packed than the floor below`)
		ok(not (r.teaching and not last.teaching), `{where}: the teaching floors don't come back`)
		ok(
			r.padlockedNote or not last.padlockedNote,
			`{where}: a padlocked note stays once it's come`
		)
	end
	last = r
end
ok(FloorRules.at(1).teaching and FloorRules.at(2).teaching, "floors 1 and 2 teach")
ok(not FloorRules.at(3).teaching, "floor 3 is the first not to")
ok(FloorRules.at(1).packed == FloorRules.PackedFirst, "floor 1 packs the first share")
ok(FloorRules.at(6).packed > FloorRules.at(1).packed, "more packed higher up")
ok(FloorRules.at(1000).packed == FloorRules.PackedMost, "never more packed than the most")
ok(
	FloorRules.at(0) == FloorRules.at(1) and FloorRules.at(-3) == FloorRules.at(1),
	"below 1 is floor 1"
)
ok(FloorRules.at(3.7) == FloorRules.at(3), "part of a floor is the floor")
ok(FloorRules.at(100000).number == 100000, "a floor far up still has rules")

-- 3. The other per-floor curves hold far up: in range and never easier.
local lastFirst, lastGap, lastSize, lastPay, lastKeen = math.huge, math.huge, 0, 0, 0
local lastBest = 0
for n = 1, HIGH do
	local where = `floor {n}`
	local wakeFirst, gap, size = Waking.first(n), Waking.gap(n), Waking.size(n)
	ok(
		wakeFirst >= Waking.FirstLeast and wakeFirst <= lastFirst,
		`{where}: the first wave no sooner than its least`
	)
	ok(gap >= Waking.GapLeast and gap <= lastGap, `{where}: waves no closer than their least`)
	ok(size >= lastSize and size <= Waking.SizeMost, `{where}: a wave no bigger than its most`)
	lastFirst, lastGap, lastSize = wakeFirst, gap, size
	local pays = Pay.forFloor(n)
	ok(pays > lastPay and pays == math.floor(pays), `{where}: pays a whole number, more than below`)
	lastPay = pays
	local keen = Breaker.errand(n, true, math.huge, true)
	ok(
		keen >= lastKeen and keen <= Breaker.ErrandMost,
		`{where}: a Mannequin's breaker errands in range`
	)
	lastKeen = keen
	-- the grades are weights (out of 100, a little over past `Grades.SecretDoubles`)
	local odds = Grades.odds(n)
	local total = 0
	for _, chance in odds do
		ok(chance >= 0, `{where}: no grade below nothing`)
		total += chance
	end
	local best = ((odds.Legendary or 0) + (odds.Secret or 0)) / total
	ok(total > 0 and best >= lastBest - 1e-9, `{where}: the best finds no rarer than below`)
	lastBest = best
end

-- 4. Floors well past 100 lay and deal like any other.
local FLOORS = { 1, 2, 3, 4, 5, 6, 7, 10, 25, 50, 99, 100, 101, 150, 250 }
local laid = 0
for _, n in FLOORS do
	for seed = 1, 3 do
		local where = `seed {seed} floor {n}`
		local random = Brix.Random.new({ seed = Climb.seedOf(seed, n) })
		local fine, floor = pcall(Floor.generate, n, random)
		ok(fine, `{where}: lays ({if fine then "" else tostring(floor)})`)
		if not fine then
			continue
		end
		local dealt, deck = pcall(Deal.new, floor, random)
		ok(dealt, `{where}: deals ({if dealt then "" else tostring(deck)})`)
		if not dealt then
			continue
		end
		laid += 1
		local rules = FloorRules.at(n)
		ok(
			floor.plan == Floor.planFor(n) and floor.plan.units == rules.units,
			`{where}: laid to its rules' plan`
		)
		local units = Deal.units(floor)
		ok(
			#units >= 1 and #units <= Floor.MaxUnits,
			`{where}: 1 to {Floor.MaxUnits} units ({#units})`
		)
		local seen: { [string]: boolean } = {}
		for _, i in units do
			local number = floor.slots[i].number :: string
			ok(
				string.sub(number, 1, #tostring(n)) == tostring(n),
				`{where}: Unit {number} is numbered after its floor`
			)
			ok(#number == #tostring(n) + 2, `{where}: Unit {number} is its floor and two digits`)
			ok(not seen[number], `{where}: one Unit {number}`)
			seen[number] = true
		end
		ok(#deck.notes == rules.notes, `{where}: {rules.notes} notes ({#deck.notes})`)
		ok(#deck.code == CODE, `{where}: a {CODE}-digit code`)
		local locks = 0
		for _ in deck.padlocked do
			locks += 1
		end
		ok(
			locks >= 1 and locks <= math.max(1, math.round(#units * rules.padlocks)),
			`{where}: {locks} padlocks`
		)
	end
end
ok(laid == #FLOORS * 3, `every floor laid and dealt ({laid} of {#FLOORS * 3})`)

print(`floorrules.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
