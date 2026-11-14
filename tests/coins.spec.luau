--!strict
-- lune run tests/coins.spec
-- Coins (S1-04a) over 200 seeds on floors 1, 3 and 6: about seven units in ten have coins, one to
-- three, spread as `Deal.CoinSpread` says; the same seed lays the same coins; a door shows the
-- coins it was laid with, the same each time it lifts (that adding them moved nothing else a seed
-- lays, holetrap.spec's replayed seed checks). A pile lies in the unit, never on the floor its tool, find or keeper takes. The rate
-- check lets a few quick takes through and stops a script hammering the button.
local Brix = require("../vendor/brix/src")
local Coins = require("../src/shared/Coins")
local Deal = require("../src/shared/Deal")
local DealSpot = require("../src/shared/DealSpot")
local Floor = require("../src/shared/Floor")
local NoteSpot = require("../src/shared/Elevator/NoteSpot")
local fs = require("@lune/fs")

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

local SEEDS = 200
local FLOORS = { 1, 3, 6 }

local function lay(seed: number, number: number)
	local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
	return floor, Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
end

local BUILD: Deal.Situation = { mood = "Build", awake = 0 }

-- The deal's coins.
local units, paying = 0, 0
local byCount = { 0, 0, 0 }
for seed = 1, SEEDS do
	for _, number in FLOORS do
		local floor, deck = lay(seed, number)
		local _, again = lay(seed, number)
		local list = Deal.units(floor)
		for _, i in list do
			local n = deck.coins[i]
			ok(n ~= nil and n >= 0 and n <= 3 and n == math.floor(n), `seed {seed}: 0 to 3 coins`)
			ok(n == again.coins[i], `seed {seed} floor {number}: the same seed lays the same coins`)
			units += 1
			if n and n > 0 then
				paying += 1
				byCount[n] += 1
			end
		end
		-- a door shows its coins, the same each time it lifts
		for k = 1, math.min(6, #list) do
			local i = list[k]
			local first = Deal.open(deck, i, BUILD)
			ok(first.coins == deck.coins[i], `seed {seed}: the door shows the coins laid`)
			ok(
				Deal.open(deck, i, BUILD).coins == first.coins,
				`seed {seed}: lifted again, the same`
			)
		end
	end
end
local share = paying / units
ok(math.abs(share - Deal.CoinShare) < 0.02, `about {Deal.CoinShare} of units pay: {share}`)
local total = 0
for _, w in Deal.CoinSpread do
	total += w
end
for count, w in Deal.CoinSpread do
	local got = byCount[count] / paying
	ok(
		math.abs(got - w / total) < 0.03,
		`{count} coins in about {w / total} of paying units: {got}`
	)
end

-- The draw's edges.
ok(Deal.coinsFrom(Deal.CoinShare, 0) == 0, "at the share's edge, no coins")
ok(Deal.coinsFrom(0, 0) == 1, "the lowest spread is one coin")
ok(Deal.coinsFrom(0, 0.9999) == 3, "the highest spread is three")

-- Where a pile lies: in the unit's bulb's pool, never on the floor something else takes.
local function number(text: string, pattern: string): number
	local found = string.match(text, pattern)
	return assert(found and tonumber(found), `no {pattern}`)
end
local specs = fs.readFile("src/shared/Coins/Specs.luau")
local function pileSize(n: number): DealSpot.Size
	local pattern = "%[" .. n .. "%] = {%s*Size = Vector3%.new%(([%d%.]+), ([%d%.]+), ([%d%.]+)%)"
	local x, y, z = string.match(specs, pattern)
	return {
		across = assert(tonumber(x), `pile {n}'s size`),
		tall = assert(tonumber(y)),
		along = assert(tonumber(z)),
	}
end
local things: { { thing: DealSpot.Thing, size: DealSpot.Size } } = {
	{ thing = "Tool", size = { across = 0.6, along = 2.4, tall = 0.4 } }, -- about the bolt cutters
	{ thing = "Find", size = { across = 2.3, along = 0.7, tall = 1.1 } }, -- the boombox
	{ thing = "Keeper", size = DealSpot.Keeper },
}
local laid = 0
for _, size in { "S", "M" } do
	local spec = fs.readFile(`src/shared/StorageUnit/Specs/{size}.luau`)
	local unit: DealSpot.Unit = {
		width = number(spec, "\n\tWidth = ([%d%.]+)"),
		depth = number(spec, "\n\tDepth = ([%d%.]+)"),
		doorWidth = number(spec, "\n\tDoorWidth = ([%d%.]+)"),
	}
	local side, back = unit.width / 2 - DealSpot.Wall, unit.depth - DealSpot.Wall
	for n = 100, 399 do
		local label = tostring(n)
		local note = NoteSpot.inUnit(unit.depth, label).x
		for _, other in things do
			local spot = DealSpot.inUnit(unit, other.thing, other.size, note, label)
			if spot then
				local zone = DealSpot.around(spot, other.size)
				local held = DealSpot.footprint(
					spot.x,
					spot.z,
					spot.yaw,
					other.size.across,
					other.size.along
				)
				for count = 1, 3 do
					local pile = pileSize(count)
					local at = DealSpot.inUnit(unit, "Coins", pile, note, label, { zone })
					ok(at ~= nil, `{size} {label}: {count} coins find room beside a {other.thing}`)
					if at then
						laid += 1
						local poly = DealSpot.footprint(at.x, at.z, at.yaw, pile.across, pile.along)
						ok(
							not DealSpot.near(poly, held, DealSpot.Apart - 0.01),
							`{size} {label}: coins keep {DealSpot.Apart} from the {other.thing}`
						)
						local inside = true
						for k = 1, #poly, 2 do
							inside = inside
								and math.abs(poly[k]) <= side + 1e-6
								and poly[k + 1] <= back + 1e-6
								and poly[k + 1] >= DealSpot.Door - 1e-6
						end
						ok(inside, `{size} {label}: coins on the unit's floor, past the door`)
					end
				end
			end
		end
	end
end

-- The rate check.
local fine, left = Coins.allow(nil, 0, 0)
ok(fine and left == Coins.Burst - 1, "the first take goes through")
local burst, t, last = left, 0.01, 0
local through = 1
for _ = 1, 10 do
	local may, rest = Coins.allow(last, burst, t)
	if may then
		through += 1
		last, burst = t, rest
	end
	t += 0.01
end
ok(through <= Coins.Burst + 1, `a burst lets about {Coins.Burst} through: {through}`)
local may = Coins.allow(last, 0, last + 1 / Coins.Rate + 0.001)
ok(may, "after a moment, another take goes through")
ok(Coins.text(12.7) == "12" and Coins.text(-1) == "0", "the count reads as a whole number")

if failures > 0 then
	print(`coins: {failures} of {checks} checks failed`)
	error("coins spec failed")
end
print(`coins: {checks} checks passed ({laid} piles laid; {math.floor(share * 100)}% of units pay)`)
