--!strict
-- The floor's monsters (S4-02, GDD "Floor rules"): each one never below its lowest floor, above it
-- mixed in at random from the climb's seed, so two climbs in a row meet them on different floors,
-- while one seed always lays the same floors. A floor version (S4-03) can lean the mix. Run:
-- lune run tests/keepermix.spec
local Brix = require("../vendor/brix/src")
local Deal = require("../src/shared/Deal")
local Floor = require("../src/shared/Floor")
local KeeperMix = require("../src/shared/KeeperMix")
local KeeperRows = require("../src/shared/KeeperRows")

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

local SEEDS = 300
local HIGH = 60

local function cast(seed: number, number: number, lean: KeeperMix.Lean?): KeeperMix.Cast
	return KeeperMix.on(number, Brix.Random.new({ seed = KeeperMix.seedOf(seed, number) }), lean)
end

local function names(c: KeeperMix.Cast): string
	local out = {}
	for _, name in KeeperMix.Order do
		if c[name] then
			table.insert(out, name)
		end
	end
	return table.concat(out, ",")
end

-- 1. Every monster's row is in the draw order once, with its lowest floor and its share.
local seen: { [string]: boolean } = {}
for _, name in KeeperMix.Order do
	ok(not seen[name], `{name} is in the draw order once`)
	seen[name] = true
	local row = KeeperRows[name]
	ok(row ~= nil, `{name} in the draw order has a row`)
	if row then
		ok(
			row.lowest >= 1 and row.lowest == math.floor(row.lowest),
			`{name}'s lowest floor is whole`
		)
		ok(row.share >= 0 and row.share <= 1, `{name}'s share is 0 to 1`)
	end
end
for name in KeeperRows do
	ok(seen[name] == true, `{name} is in the draw order`)
end

-- 2. Never below its lowest floor; always one that hunts (the guarded note's, D-072); one seed's
-- floors the same every time.
local hunters: { string } = {}
for _, name in KeeperMix.Order do
	if KeeperRows[name].collects == nil then
		table.insert(hunters, name)
	end
end
ok(#hunters > 0, "at least one monster hunts")
local inOn: { [string]: number } = {}
local could: { [string]: number } = {}
for seed = 1, SEEDS do
	for number = 1, HIGH do
		local c = cast(seed, number)
		local again = cast(seed, number)
		ok(names(c) == names(again), `seed {seed} floor {number}: the same monsters twice`)
		local hunting = false
		for name in c do
			ok(KeeperRows[name] ~= nil, `seed {seed} floor {number}: {name} has a row`)
			ok(
				number >= KeeperRows[name].lowest,
				`seed {seed} floor {number}: {name} below its lowest floor`
			)
			hunting = hunting or table.find(hunters, name) ~= nil
		end
		ok(hunting, `seed {seed} floor {number}: a monster that hunts`)
		for _, name in KeeperMix.Order do
			if number >= KeeperRows[name].lowest then
				could[name] = (could[name] or 0) + 1
				inOn[name] = (inOn[name] or 0) + (if c[name] then 1 else 0)
			end
		end
	end
end

-- 3. Above its lowest floor each turns up on about its share of floors.
for _, name in KeeperMix.Order do
	local share = (inOn[name] or 0) / math.max(1, could[name] or 0)
	ok(
		math.abs(share - KeeperRows[name].share) < 0.03,
		`{name} on {string.format("%.2f", share)} of its floors, its share {KeeperRows[name].share}`
	)
end

-- 4. Two climbs in a row meet different monsters on different floors: of every pair of seeds side
-- by side, nearly all differ somewhere in their first 12 floors, and every floor that mixes
-- differs between some seeds.
local differ = 0
for seed = 1, SEEDS - 1 do
	local same = true
	for number = 1, 12 do
		same = same and names(cast(seed, number)) == names(cast(seed + 1, number))
	end
	differ += if same then 0 else 1
end
ok(differ >= (SEEDS - 1) * 0.95, `{differ} of {SEEDS - 1} climbs in a row differ in floors 1 to 12`)
for number = 1, HIGH do
	local kinds: { [string]: boolean } = {}
	local count = 0
	for seed = 1, 40 do
		local n = names(cast(seed, number))
		if not kinds[n] then
			kinds[n] = true
			count += 1
		end
	end
	local mixes = false
	for _, name in KeeperMix.Order do
		local row = KeeperRows[name]
		mixes = mixes or (number >= row.lowest and row.share > 0 and row.share < 1)
	end
	ok(count > 1 or not mixes, `floor {number}: the monsters differ between seeds`)
end

-- 5. A floor version leans the mix (S4-03): it brings one or keeps it away, never below its lowest
-- floor, and moves no other monster; the floor keeps one that hunts whatever it asks.
for seed = 1, SEEDS do
	for number = 1, HIGH do
		local plain = cast(seed, number)
		for _, name in KeeperMix.Order do
			local low = KeeperRows[name].lowest
			local brought = cast(seed, number, { [name] = 1 })
			local away = cast(seed, number, { [name] = 0 })
			ok(
				brought[name] == (if number >= low then true else nil),
				`seed {seed} floor {number}: brings {name}`
			)
			if not table.find(hunters, name) then
				ok(away[name] == nil, `seed {seed} floor {number}: keeps {name} away`)
			end
			for _, other in KeeperMix.Order do
				if other ~= name and not table.find(hunters, other) then
					ok(
						brought[other] == plain[other],
						`seed {seed} floor {number}: bringing {name} moved {other}`
					)
					ok(
						away[other] == plain[other],
						`seed {seed} floor {number}: keeping {name} away moved {other}`
					)
				end
			end
		end
		local quiet: KeeperMix.Lean = {}
		for _, name in hunters do
			quiet[name] = 0
		end
		local c = cast(seed, number, quiet)
		local hunting = false
		for _, name in hunters do
			hunting = hunting or c[name] == true
		end
		ok(hunting, `seed {seed} floor {number}: one hunts even when a version keeps them all away`)
	end
end

-- 6. The deal follows the floor's mix: a floor without the Packrat has no Packrat or pile, and the
-- mix moves nothing else a seed lays (its code, padlocks, guard, coins, sleepers).
local packrat = Deal.Packrat.name
local withOut, withIn = 0, 0
for seed = 1, 40 do
	for _, number in { 3, 4, 7, 12 } do
		local where = `seed {seed} floor {number}`
		local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
		local all = Deal.new(floor, Brix.Random.new({ seed = seed + 1 }))
		local some = Deal.new(floor, Brix.Random.new({ seed = seed + 1 }), { Mannequin = true })
		local packrats = 0
		for _, name in some.sleepers do
			packrats += if name == packrat then 1 else 0
		end
		ok(
			packrats == 0 and next(some.piles) == nil,
			`{where}: no Packrat when the mix leaves it out`
		)
		ok(table.concat(all.code) == table.concat(some.code), `{where}: the same code`)
		ok(all.guarded == some.guarded, `{where}: the same guard`)
		for i, name in all.sleepers do
			if name ~= packrat then
				ok(some.sleepers[i] == name, `{where}: the same sleepers`)
			end
		end
		for i, coins in all.coins do
			ok(
				some.coins[i] == coins and some.padlocked[i] == all.padlocked[i],
				`{where}: the same coins`
			)
		end
		local c = cast(seed, number)
		local dealt = Deal.new(floor, Brix.Random.new({ seed = seed + 1 }), c)
		local has = false
		for _, name in dealt.sleepers do
			has = has or name == packrat
		end
		ok(
			has == (c[packrat] == true),
			`{where}: the Packrat sleeps here only when it's in the mix`
		)
		withIn += if has then 1 else 0
		withOut += if has then 0 else 1
	end
end
ok(withIn > 0 and withOut > 0, `the Packrat on some floors and not others ({withIn} and {withOut})`)

print(`keepermix.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
