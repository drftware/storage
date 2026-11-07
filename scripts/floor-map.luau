--!strict
-- Prints a floor's layout as a text map: lune run scripts/floor-map [seed] [floor]
-- (seed 1 and floor 3 by default). Legend: L the lobby, E its elevator, . hall, + junction,
-- * a motion light, M/m and S/s units (case alternates so neighbours read apart), # a plain wall,
-- | or - a dead end. Seen from above: +X to the right, +Z down the page.
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

print(`Floor {number}, seed {seed}: {floor.paint} doors`)
print(Floor.map(floor))
print(
	`{units} units ({first} to {last}), {walls} plain walls, {#floor.deadEnds} dead ends, `
		.. `{kinds.Corner or 0} corners, {kinds.T or 0} Ts, {kinds.Cross or 0} crosses, `
		.. `{#floor.fixtures} lights (zones: {table.concat(zoneText, ", ")})`
)
