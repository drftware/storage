--!strict
-- The power's out (S4-03c3, D-408): the team picked the dead-bulb card, so the floor's gate opens
-- on dark halls and dark units. Its breaker is hung thrown, and throwing it back on brings the
-- lights back, so every floor the card can be dealt for must have a breaker to find. The units'
-- bulbs follow that breaker on that floor only: a cut breaker on any other floor leaves them lit.
-- Run: lune run tests/powerout.spec
local Brix = require("../vendor/brix/src")
local Deal = require("../src/shared/Deal")
local Floor = require("../src/shared/Floor")
local NextFloor = require("../src/shared/NextFloor")

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

local powerOut = NextFloor.find("PowerOut") :: NextFloor.Version

-- 1. The rule: dark only while the floor was dealt as the power's out and its breaker is off.
ok(powerOut.dark == true, "the power-out card is the dark one")
ok(NextFloor.dark("PowerOut", false), "power's out, breaker off: dark")
ok(not NextFloor.dark("PowerOut", true), "power's out, breaker back on: lit")
ok(not NextFloor.dark("PowerOut", nil), "power's out, no word from its breaker yet: lit")
for _, v in NextFloor.Versions do
	if v.name ~= "PowerOut" then
		ok(not v.dark, `{v.name} isn't dark`)
		ok(not NextFloor.dark(v.name, false), `{v.name} with its breaker cut keeps its units lit`)
	end
end
ok(not NextFloor.dark(nil, false), "a floor nobody picked keeps its units lit through a cut")
ok(not NextFloor.dark("NoSuchCard", false), "an unknown version is lit")
ok(not NextFloor.dark(7, false), "a number for a version is lit")
ok(not NextFloor.dark("PowerOut", 0), "a breaker attribute that isn't false is lit")

-- 2. The deal is untouched: the dark card deals the same floor (its code, its box).
for seed = 1, 60 do
	for _, number in { 2, 5, 12 } do
		local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
		local plain = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
		local dark = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }), nil, powerOut)
		ok(
			table.concat(plain.code) == table.concat(dark.code),
			`seed {seed} floor {number}: same code`
		)
		local a, b = plain.breaker, dark.breaker
		ok(
			a ~= nil and b ~= nil and a.x == b.x and a.z == b.z and a.facing == b.facing,
			`seed {seed} floor {number}: the box hangs in the same spot`
		)
	end
end

-- 3. Every floor the card can be dealt for has a breaker to bring the lights back.
local missing = 0
for number = powerOut.lowest, 60 do
	for seed = 1, 12 do
		local floor = Floor.generate(number, Brix.Random.new({ seed = seed * 7919 + number }))
		local deck = Deal.new(floor, Brix.Random.new({ seed = seed }), nil, powerOut)
		if deck.breaker == nil then
			missing += 1
			ok(false, `seed {seed} floor {number}: a power-out floor with no breaker`)
		end
	end
end
ok(missing == 0, `{missing} power-out floors had no breaker`)

print(`powerout.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
