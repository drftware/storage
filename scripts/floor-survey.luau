--!strict
-- Measures the floors' crawl links and top runs over many seeds: lune run scripts/floor-survey
-- [seeds] (400 by default), each seed laying a short floor (1 or 2) and a full one (3 to 10).
-- Prints each measure's spread (lowest, 1 in 10, middle, highest) so the floor's limits can be
-- picked from numbers, not guesses.
local process = require("@lune/process")

local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")

local seeds = tonumber(process.args[1]) or 400

type Stats = { [string]: { number } }
local function add(stats: Stats, name: string, value: number)
	stats[name] = stats[name] or {}
	table.insert(stats[name], value)
end

local worst = { cutOff = -1, seed = 0, floor = 0 }

local function measure(f: Floor.Floor, stats: Stats, seed: number)
	local s = f.slots
	local pairs, backPairs, firstPairs, cutOff, lids, units = 0, 0, 0, 0, 0, 0
	for i, slot in s do
		if slot.kind == "Unit" then
			units += 1
			local any = false
			for _, side in { "left", "right", "back" } :: { Floor.Side } do
				local j = (slot :: any)[side] :: number? -- any: a field picked by name
				if j and s[j].kind == "Unit" then
					any = true
					if j > i then
						pairs += 1
						if side == "back" then
							backPairs += 1
						end
						if f.cells[slot.cell].zone == "Lobby" and f.cells[s[j].cell].zone == "Lobby" then
							firstPairs += 1
						end
					end
				end
			end
			if not any then
				cutOff += 1
			end
		elseif slot.top then
			lids += 1
		end
	end
	local longest, lone = 0, 0
	for _, run in f.runs do
		longest = math.max(longest, run.length)
		add(stats, "run length (studs)", run.length)
		add(stats, "run units", run.units)
		if run.units == 1 and #run.slots == 1 then
			lone += 1
		end
	end
	if cutOff > worst.cutOff then
		worst.cutOff, worst.seed, worst.floor = cutOff, seed, f.number
	end
	add(stats, "units", units)
	add(stats, "neighbour pairs", pairs)
	add(stats, "  of them back to back", backPairs)
	add(stats, "pairs lobby to first fork", firstPairs)
	add(stats, "units cut off", cutOff)
	add(stats, "runs", #f.runs)
	add(stats, "longest run (studs)", longest)
	add(stats, "lone tops (one unit, nothing beside)", lone)
	add(stats, "plain walls lidded", lids)
	local overlaps = 0
	for i, a in s do
		for j = i + 1, #s do
			local b = s[j]
			if a.top and b.top then
				local ax0, ax1, az0, az1 = Floor.footprint(a)
				local bx0, bx1, bz0, bz1 = Floor.footprint(b)
				if math.min(ax1, bx1) - math.max(ax0, bx0) > 0.01 and math.min(az1, bz1) - math.max(az0, bz0) > 0.01 then
					overlaps += 1
				end
			end
		end
	end
	add(stats, "tops overlapping another", overlaps)
end

local function report(title: string, stats: Stats)
	print(title)
	local names = {}
	for name in stats do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		local v = stats[name]
		table.sort(v)
		local function at(q: number): number
			return v[math.clamp(math.floor(q * (#v - 1)) + 1, 1, #v)]
		end
		print(string.format("  %-38s %5g %5g %5g %5g", name, v[1], at(0.1), at(0.5), v[#v]))
	end
end

local short, full = {}, {}
for seed = 1, seeds do
	measure(Floor.generate(1 + seed % 2, Brix.Random.new({ seed = seed })), short, seed)
	measure(Floor.generate(3 + seed % 8, Brix.Random.new({ seed = seed })), full, seed)
end
print(`{seeds} seeds; columns: lowest, 1 in 10, middle, highest`)
report("Short floors (1 and 2)", short)
report("Full floors (3 to 10)", full)
print(`Most units cut off: {worst.cutOff}, seed {worst.seed} floor {worst.floor}`)
