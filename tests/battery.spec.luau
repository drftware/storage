--!strict
-- lune run tests/battery.spec
-- Batteries (S1-07b) over 200 seeds on floors 1, 3 and 6: about one unit in ten has one; the same
-- seed lays the same; a door shows the battery it was laid with, the same each time it lifts; a
-- unit with one holds no stuff. They're drawn last, so everything else a seed lays is what it was
-- before them (deal.spec's fingerprint, every unit's coins included, is unchanged). Where it lies, in both unit sizes over 300
-- unit numbers: on the unit's floor past the door, clear of a tool, find or keeper and of the
-- coins beside it. A torch takes one only once its ring has lost a tick. The rate check lets a
-- quick take through and stops a script hammering the button.
local Battery = require("../src/shared/Battery")
local Brix = require("../vendor/brix/src")
local Charge = require("../src/shared/Flashlight/Charge")
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
local BUILD: Deal.Situation = { mood = "Build", awake = 0 }

local function lay(seed: number, number: number)
	local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
	return floor, Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
end

-- The deal's batteries.
local units, charged = 0, 0
for seed = 1, SEEDS do
	for _, number in FLOORS do
		local floor, deck = lay(seed, number)
		local _, again = lay(seed, number)
		for _, i in Deal.units(floor) do
			units += 1
			local has = deck.batteries[i] == true
			ok(
				has == (again.batteries[i] == true),
				`seed {seed}: the same seed, the same batteries`
			)
			if has then
				charged += 1
			end
			local c = Deal.open(deck, i, BUILD)
			ok((c.battery == true) == has, `seed {seed} unit {i}: the door shows the battery laid`)
			ok(
				Deal.open(deck, i, BUILD).battery == c.battery,
				`seed {seed}: lifted again, the same`
			)
			ok(not (c.battery and c.stuff), `seed {seed} unit {i}: a battery's unit holds no stuff`)
		end
	end
end
local share = charged / units
ok(math.abs(share - Deal.BatteryShare) < 0.01, `about {Deal.BatteryShare} of units: {share}`)

-- Where a battery lies: on the unit's floor past the door, never on the floor something else
-- takes, its coins' included.
local function number(text: string, pattern: string): number
	local found = string.match(text, pattern)
	return assert(found and tonumber(found), `no {pattern}`)
end
local cellSpec = fs.readFile("src/shared/Battery/Specs.luau")
local cx, cy = string.match(cellSpec, "Size = Vector3%.new%(([%d%.]+), ([%d%.]+), [%d%.]+%)")
local width, length = assert(tonumber(cx)), assert(tonumber(cy))
local cell: DealSpot.Size = { across = length, along = width, tall = width }
local coinSpec = fs.readFile("src/shared/Coins/Specs.luau")
local px, py, pz =
	string.match(coinSpec, "%[3%] = {%s*Size = Vector3%.new%(([%d%.]+), ([%d%.]+), ([%d%.]+)%)")
local pile: DealSpot.Size =
	{ across = assert(tonumber(px)), tall = assert(tonumber(py)), along = assert(tonumber(pz)) }
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
				local taken = { DealSpot.around(spot, other.size) }
				local held = {
					DealSpot.footprint(
						spot.x,
						spot.z,
						spot.yaw,
						other.size.across,
						other.size.along
					),
				}
				-- the unit's coins beside it, as Deals lays them
				local coins = DealSpot.inUnit(unit, "Coins", pile, note, label, taken)
				if coins then
					table.insert(taken, DealSpot.around(coins, pile))
					table.insert(
						held,
						DealSpot.footprint(coins.x, coins.z, coins.yaw, pile.across, pile.along)
					)
				end
				local at = DealSpot.inUnit(unit, "Battery", cell, note, label, taken)
				ok(at ~= nil, `{size} {label}: a battery finds room beside a {other.thing}`)
				if at then
					laid += 1
					local poly = DealSpot.footprint(at.x, at.z, at.yaw, cell.across, cell.along)
					for _, h in held do
						ok(
							not DealSpot.near(poly, h, DealSpot.Apart - 0.01),
							`{size} {label}: a battery keeps {DealSpot.Apart} from what else lies`
						)
					end
					local inside = true
					for k = 1, #poly, 2 do
						inside = inside
							and math.abs(poly[k]) <= side + 1e-6
							and poly[k + 1] <= back + 1e-6
							and poly[k + 1] >= DealSpot.Door - 1e-6
					end
					ok(inside, `{size} {label}: a battery on the unit's floor, past the door`)
				end
			end
		end
	end
end
ok(laid > 1000, `batteries laid in the spot checks: {laid}`)

-- A torch takes one only once its ring has lost a tick: never full, never for a few seconds.
local full = Charge.Full
ok(not Battery.wants(full, full), "a full torch leaves it")
ok(not Battery.wants(full - 1, full), "a second of light used: its ring is still full, it's left")
local tick = full / Charge.Ticks
ok(Battery.wants(full - tick, full), "a tick gone from the ring: it's taken")
ok(Battery.wants(Charge.Flicker, full), "a flickering torch takes it")
ok(Battery.wants(0, full), "a dead torch takes it")
ok(not Battery.wants(40, 40), "a full Studio torch (DevTorchSeconds) leaves it")

-- The rate check.
local fine, left = Battery.allow(nil, 0, 0)
ok(fine and left == Battery.Burst - 1, "the first take goes through")
local burst, t, last = left, 0.01, 0
local through = 1
for _ = 1, 10 do
	local may, rest = Battery.allow(last, burst, t)
	if may then
		through += 1
		last, burst = t, rest
	end
	t += 0.01
end
ok(through <= Battery.Burst + 1, `a burst lets about {Battery.Burst} through: {through}`)
ok(Battery.allow(last, 0, last + 1 / Battery.Rate + 0.001), "after a moment, another goes through")

if failures > 0 then
	print(`battery: {failures} of {checks} checks failed`)
	error("battery spec failed")
end
print(`battery: {checks} checks passed`)
