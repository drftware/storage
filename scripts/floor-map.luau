--!strict
-- Prints a floor's layout as a text map: lune run scripts/floor-map [seed] [floor]
-- (seed 1 and floor 3 by default). Legend: L the lobby, E its elevator, . hall, + junction,
-- * a motion light, M/m and S/s units (case alternates so neighbours read apart), x a unit no
-- crawl hole leads from, # a plain wall, | or - a dead end. Seen from above: +X to the right, +Z
-- down the page. Under it, the tops: each top run in a letter of its own, capital over a unit and
-- small over a plain wall's lid.
local process = require("@lune/process")

local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")

local seed = tonumber(process.args[1]) or 1
local number = tonumber(process.args[2]) or 3

local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))

local units, walls, kinds = 0, 0, {} :: { [string]: number }
local first, last = math.huge, 0
for _, s in floor.slots do
	if s.kind == "Unit" then
		units += 1
		local n = tonumber(s.number) or 0
		first, last = math.min(first, n), math.max(last, n)
	else
		walls += 1
	end
end
for _, c in floor.cells do
	kinds[c.kind] = (kinds[c.kind] or 0) + 1
end
local zones = {}
for _, f in floor.fixtures do
	zones[f.zone] = (zones[f.zone] or 0) + 1
end
local zoneText = {}
for name, n in zones do
	table.insert(zoneText, `{name} {n}`)
end
table.sort(zoneText)

local links, nearLobby, cutOff, lids, longest = 0, 0, 0, 0, 0
for i, s in floor.slots do
	if s.kind == "Unit" then
		local into = Floor.crawlsTo(floor, i)
		if #into == 0 then
			cutOff += 1
		end
		for _, j in into do
			if j > i then
				links += 1
				local zone = floor.cells[floor.slots[j].cell].zone
				if floor.cells[s.cell].zone == "Lobby" and zone == "Lobby" then
					nearLobby += 1
				end
			end
		end
	elseif s.top then
		lids += 1
	end
end
for _, run in floor.runs do
	longest = math.max(longest, run.length)
end

print(`Floor {number}, seed {seed}: {floor.paint} doors`)
print(Floor.map(floor))
print(
	`{units} units ({first} to {last}), {walls} plain walls, {#floor.deadEnds} dead ends, `
		.. `{kinds.Corner or 0} corners, {kinds.T or 0} Ts, {kinds.Cross or 0} crosses, `
		.. `{#floor.fixtures} lights (zones: {table.concat(zoneText, ", ")})`
)
print(
	`{links} crawl links ({nearLobby} from the lobby to the first fork), {cutOff} units cut off; `
		.. `{#floor.runs} top runs, the longest {longest} studs, {lids} plain walls lidded`
)
print("\nThe tops")
print(Floor.map(floor, "tops"))
