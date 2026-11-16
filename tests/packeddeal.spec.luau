--!strict
-- lune run tests/packeddeal.spec
-- Which units pack (B-05b1, D-216), over 200 seeds on floors 1, 3 and 6: only medium units, never
-- the lobby's hall on the floors that teach the doors nor the Packrat's unit; about
-- the floor rules' `packed` of the units that may, more higher up; the same seed the same units; and a
-- packed unit opened holds its marked box's find, tool, note or coins, or a monster, never
-- nothing, and never somebody's stuff.
local Brix = require("../vendor/brix/src")
local Deal = require("../src/shared/Deal")
local FloorRules = require("../src/shared/FloorRules")
local Floor = require("../src/shared/Floor")

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

ok(FloorRules.at(1).packed == FloorRules.PackedFirst, "floor 1 packs the first share")
ok(FloorRules.at(6).packed > FloorRules.at(1).packed, "more higher up")
ok(FloorRules.at(1000).packed == FloorRules.PackedMost, "never more than the most")

local SEEDS = 200
local BUILD: Deal.Situation = { mood = "Build", awake = 0 }
local shares: { [number]: number } = {}
for _, number in { 1, 3, 6 } do
	local packed, may = 0, 0
	for seed = 1, SEEDS do
		local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
		local deck = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
		local again = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
		local label = `seed {seed} floor {number}`
		for _, i in Deal.units(floor) do
			local slot = floor.slots[i]
			local unit = `{label} unit {slot.number}`
			ok(deck.packed[i] == again.packed[i], `{unit}: the same seed packs the same`)
			if Deal.canPack(deck, i) then
				may += 1
			end
			if deck.packed[i] then
				packed += 1
				ok(slot.size == "M", `{unit}: only a medium unit packs`)
				ok(deck.piles[i] == nil, `{unit}: never the Packrat's`)
				ok(
					not (FloorRules.at(number).teaching and deck.firstHall[i]),
					`{unit}: never the lobby's hall while the doors teach`
				)
			end
			local contents = Deal.open(deck, i, BUILD)
			if deck.packed[i] then
				local note = Deal.noteIn(deck, i) ~= nil
				local something = Deal.keeperIn(contents) ~= nil
					or contents.find ~= nil
					or contents.tool ~= nil
					or note
					or contents.coins > 0
				ok(something, `{unit}: a packed unit holds something ({contents.kind})`)
				ok(contents.stuff == nil, `{unit}: no stuff among the stacks`)
			end
		end
	end
	shares[number] = packed / math.max(1, may)
	local want = FloorRules.at(number).packed
	ok(
		math.abs(shares[number] - want) < 0.04,
		`floor {number} packs about {want} ({shares[number]})`
	)
end
ok(shares[6] > shares[1], `floor 6 packs more than floor 1 ({shares[6]} > {shares[1]})`)

print(
	`packeddeal: {checks - failures}/{checks} checks, packed {string.format("%.2f", shares[1])} / {string.format(
		"%.2f",
		shares[3]
	)} / {string.format("%.2f", shares[6])}`
)
if failures > 0 then
	error(`{failures} failed`)
end
