--!strict
-- lune run tests/climb.spec
-- The climb (L-08b): a seed's first floor is the one floor-map prints for it, every floor above
-- gets a layout and a code of its own, floors laid one after another stand far enough apart that
-- a phone on one never streams the other, and the hand-off lands while the shaft hides
-- everything through the gate.
local Brix = require("../vendor/brix/src")
local Climb = require("../src/shared/Climb")
local Deal = require("../src/shared/Deal")
local Floor = require("../src/shared/Floor")
local Ride = require("../src/shared/Elevator/Ride")

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

-- A floor dealt as the climb deals it.
local function deal(seed: number, number: number): (Floor.Floor, Deal.Deck)
	local random = Brix.Random.new({ seed = Climb.seedOf(seed, number) })
	local floor = Floor.generate(number, random)
	return floor, Deal.new(floor, random)
end

local STREAMING = 256 -- the place's streaming target radius
local fewestApart = math.huge
local sameCodes = 0
local compared = 0
for seed = 1, 60 do
	ok(Climb.seedOf(seed, 1) == seed, `seed {seed}: floor 1 keeps the climb's seed`)
	local before: Floor.Floor? = nil
	local beforeCode = ""
	for number = 1, Climb.Top do
		local floor, deck = deal(seed, number)
		local code = table.concat(deck.code)
		local again = deal(seed, number)
		ok(Floor.map(again) == Floor.map(floor), `seed {seed} floor {number}: dealt the same twice`)
		if before then
			compared += 1
			ok(
				Floor.map(floor) ~= Floor.map(before),
				`seed {seed}: floor {number} has a layout of its own, not floor {number - 1}'s`
			)
			if code == beforeCode then
				sameCodes += 1
			end
			-- the floor below stands Spacing on along +Z: its nearest hall to this one's farthest
			local _, _, _, highHere = Climb.reach(floor)
			local _, _, lowBelow = Climb.reach(before)
			local apart = (lowBelow + Climb.Spacing) - highHere
			fewestApart = math.min(fewestApart, apart)
			ok(
				apart > STREAMING + 64,
				`seed {seed}: floors {number - 1} and {number} {apart} studs apart, inside streaming reach`
			)
		end
		before, beforeCode = floor, code
	end
end
ok(sameCodes <= compared * 0.01, `floors rarely share the code below's ({sameCodes} of {compared})`)
-- whoever stands in a floor's lobby, car or halls is on it; a step past its far ends isn't
do
	local floor = deal(7, 2)
	local lowX, highX, lowZ, highZ = Climb.reach(floor)
	ok(Climb.on(floor, 0, 0), "the lobby's middle is on the floor")
	ok(Climb.on(floor, 0, Floor.LobbySize / 2 + Floor.ElevatorDepth / 2), "so is the car")
	for _, c in floor.cells do
		ok(Climb.on(floor, c.x, c.z), `hall piece at ({c.x}, {c.z}) is on the floor`)
	end
	ok(not Climb.on(floor, highX + 10, 0), "past its east end isn't")
	ok(not Climb.on(floor, lowX - 10, 0), "past its west end isn't")
	ok(not Climb.on(floor, 0, lowZ - 10), "past its far end isn't")
	ok(not Climb.on(floor, 0, highZ + 10), "behind the car isn't")
	ok(not Climb.on(floor, 0, -Climb.Spacing), "the next floor up isn't")
end
ok(Climb.offset(3, 3) == 0, "the climb's first floor stands where it starts")
ok(Climb.offset(1, 4) == 3 * Climb.Spacing, "each floor stands Spacing on from the last")

-- the hand-off: the hall you left is black, the next one's dark hasn't begun to lift, and the move
-- has over a second to land on every screen before it does
ok(
	Ride.leaving(Climb.HandOff - Climb.Lead) == 1,
	"the hall you left is black as the car's taken over"
)
ok(Climb.Lead > 0.2, "screens have a few frames to lay the shaft at the new car first")
ok(Climb.HandOff < Climb.Latest, "a late floor still has time to hand off")
ok(Ride.arriving(Climb.Latest + 1.5) == 1, "a hand-off at the latest lands before the dark lifts")
ok(Climb.Latest < Ride.arrives(), "the hand-off comes before the car levels")
ok(table.find(Ride.Clanks, Climb.HandOff) ~= nil, "the move lands on a cable's knock")
ok(Climb.HandOff > Ride.cruising() and Climb.HandOff < Ride.tick(), "and inside the cruise")
ok(Climb.mayHandOff(Climb.HandOff) and Climb.mayHandOff(Climb.Latest), "the window's ends count")
ok(not Climb.mayHandOff(Climb.HandOff - 0.01), "no hand-off before the middle of the cruise")
ok(not Climb.mayHandOff(Climb.Latest + 0.01), "and none after the latest")

if failures > 0 then
	error(`{failures} of {checks} climb checks failed`)
end
print(
	`climb: {checks} checks passed over 60 climbs of {Climb.Top} floors (floors at least {fewestApart} studs apart; {sameCodes} of {compared} codes repeated the floor below's)`
)
