--!strict
-- lune run tests/breaker.spec
-- The breaker (S2-02b): every floor hangs one box on a plain wall along a straight hall or a dead
-- end's face, never in the lobby's hall; the deal draws its spot last, the same for a seed every
-- time. A switch-on goes only for a full hold, within reach, from a player up and free, and not
-- twice in a breath; the lever creeps up under the hand, short of on.
local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local Deal = require("../src/shared/Deal")
local Breaker = require("../src/shared/Breaker")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function lay(seed: number, number: number)
	local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
	return floor, Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
end

-- Where it hangs, over many floors.
do
	local without, deadEnds, walls, total = 0, 0, 0, 0
	local spread: { [string]: true } = {}
	for seed = 1, 120 do
		for _, number in { 1, 2, 3, 6 } do
			local floor, deck = lay(seed, number)
			local where = `seed {seed} floor {number}`
			local spot = deck.breaker
			total += 1
			if not spot then
				without += 1
				ok(#Breaker.spots(floor) == 0, `{where}: no box only with nowhere to hang it`)
				continue
			end
			local cell = floor.cells[spot.cell]
			ok(cell.zone ~= "Lobby", `{where}: not in the lobby's hall`)
			ok(cell.kind == "Straight", `{where}: on a straight hall`)
			local onWall, onEnd = false, false
			for _, s in floor.slots do
				if
					s.kind == "Wall"
					and s.x == spot.x
					and s.z == spot.z
					and s.facing == spot.facing
				then
					onWall = true
				end
			end
			for _, e in floor.deadEnds do
				if e.x == spot.x and e.z == spot.z and e.facing == spot.facing then
					onEnd = true
				end
			end
			ok(onWall or onEnd, `{where}: on a plain wall or a dead end's face`)
			for _, s in floor.slots do
				ok(
					not (s.kind == "Unit" and s.x == spot.x and s.z == spot.z),
					`{where}: never on a unit's door`
				)
			end
			walls += if onWall then 1 else 0
			deadEnds += if onEnd then 1 else 0
			spread[`{number}:{spot.x},{spot.z}`] = true
			-- the same seed, the same spot
			local _, twin = lay(seed, number)
			local t = twin.breaker
			ok(
				t ~= nil and t.x == spot.x and t.z == spot.z and t.facing == spot.facing,
				`{where}: the same spot for the same seed`
			)
		end
	end
	ok(without <= total // 50, `almost every floor has a box ({without} of {total} without)`)
	ok(walls > 0 and deadEnds > 0, `both plain walls ({walls}) and dead ends ({deadEnds}) hold one`)
	local kinds = 0
	for _ in spread do
		kinds += 1
	end
	ok(kinds > total // 3, `somewhere different each climb ({kinds} spots over {total} floors)`)
end

-- Drawn last: the deck a seed lays is otherwise what it was (the sleepers, the last before it).
do
	local floor = Floor.generate(4, Brix.Random.new({ seed = 77 }))
	local deck = Deal.new(floor, Brix.Random.new({ seed = 78 }))
	ok(deck.breaker ~= nil, "seed 77 floor 4 has a box")
	local zones = Breaker.zones(floor)
	ok(zones[1] == "Lobby" and #zones >= 2, "the zones run from the lobby's out to the wings")
	local seen: { [string]: number } = {}
	for _, z in zones do
		seen[z] = (seen[z] or 0) + 1
	end
	for z, n in seen do
		ok(n == 1, `zone {z} listed once`)
	end
	for _, f in floor.fixtures do
		ok(seen[f.zone] ~= nil, `every light's zone is cut ({f.zone})`)
	end
end

-- Picking.
do
	ok(Breaker.pick({}, 0.5) == nil, "nowhere to hang it, no box")
	local spots: { Breaker.Spot } = {
		{ x = 1, z = 0, facing = 0, cell = 1 },
		{ x = 2, z = 0, facing = 0, cell = 1 },
		{ x = 3, z = 0, facing = 0, cell = 1 },
	}
	ok((Breaker.pick(spots, 0) :: Breaker.Spot).x == 1, "a roll of 0 takes the first")
	ok((Breaker.pick(spots, 0.999) :: Breaker.Spot).x == 3, "a roll near 1 takes the last")
	ok((Breaker.pick(spots, 1) :: Breaker.Spot).x == 3, "a roll of 1 stays in the list")
end

-- Judging a switch-on.
do
	local function press(): Breaker.Press
		return {
			on = false,
			wrapped = false,
			alive = true,
			held = Breaker.HoldSeconds,
			since = nil,
			reach = 3,
		}
	end
	ok(Breaker.judge(press()) == nil, "a full hold at the grip switches it on")
	local p = press()
	p.on = true
	ok(Breaker.judge(p) == "On", "on already")
	p = press()
	p.wrapped = true
	ok(Breaker.judge(p) == "Wrapped", "a wrapped player can't")
	p = press()
	p.alive = false
	ok(Breaker.judge(p) == "Dead", "a body down can't")
	p = press()
	p.held = nil
	ok(Breaker.judge(p) == "Short", "no hold seen, no switch")
	p.held = Breaker.HoldSeconds - Breaker.HoldSlack - 0.01
	ok(Breaker.judge(p) == "Short", "a hold let go early")
	p.held = Breaker.HoldSeconds - Breaker.HoldSlack
	ok(Breaker.judge(p) == nil, "a hold a little short on lag still counts")
	p = press()
	p.reach = Breaker.Reach + Breaker.ReachSlack + 0.1
	ok(Breaker.judge(p) == "Far", "out of reach")
	p.reach = Breaker.Reach + Breaker.ReachSlack
	ok(Breaker.judge(p) == nil, "at the edge of reach")
	p = press()
	p.since = Breaker.PressGap / 2
	ok(Breaker.judge(p) == "Soon", "not twice in a breath")
	p.since = Breaker.PressGap
	ok(Breaker.judge(p) == nil, "after the gap")
end

-- The lever under the hand.
do
	local Specs = Breaker.Specs
	ok(Breaker.strained(0) == Specs.Down, "a hold starts with the lever down")
	ok(Breaker.strained(-1) == Specs.Down, "before the hold, down")
	local top = Specs.Down + (Specs.Up - Specs.Down) * Breaker.Strain
	ok(
		math.abs(Breaker.strained(Breaker.HoldSeconds) - top) < 1e-9,
		"the hold's end: Strain of the way"
	)
	ok(
		Breaker.strained(Breaker.HoldSeconds * 3) == Breaker.strained(Breaker.HoldSeconds),
		"no further"
	)
	ok(Breaker.strained(Breaker.HoldSeconds) < Specs.Up, "short of on until the power catches")
	local last = Specs.Down - 1
	for i = 0, 10 do
		local a = Breaker.strained(Breaker.HoldSeconds * i / 10)
		ok(a > last, `it only rises ({i})`)
		last = a
	end
	ok(
		Breaker.strained(Breaker.HoldSeconds / 2) - Specs.Down > (top - Specs.Down) / 2,
		"eased out: most of the creep comes early"
	)
end

-- The red lamp's pulse: full at its start, faintest half-way, full again, never past PulseFaint.
do
	local s = Breaker.PulseSeconds
	ok(Breaker.pulse(0) == 0, "the pulse starts full")
	ok(math.abs(Breaker.pulse(s / 2) - Breaker.PulseFaint) < 1e-9, "faintest half-way")
	ok(math.abs(Breaker.pulse(s)) < 1e-9, "full again after one pulse")
	for i = 0, 40 do
		local t = Breaker.pulse(s * i / 17)
		ok(t >= 0 and t <= Breaker.PulseFaint + 1e-9, `the pulse stays lit ({i})`)
	end
end

print(string.format("breaker: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("breaker spec failed")
end
