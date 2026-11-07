--!strict
-- lune run tests/corridor.spec
-- The corridor kit's numbers (generated from art/corridor/spec.py) against the hall's light: the
-- haze must stay clear of the ceiling's steel, and pieces must tile without a seam. Both files
-- build Roblox values at load, so this reads their numbers as text.
local fs = require("@lune/fs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function number(path: string, pattern: string): number
	local found = string.match(fs.readFile(path), pattern)
	local n = found and tonumber(found)
	assert(n, `{path}: no match for {pattern}`)
	return n
end

local LIGHT = "src/shared/HallLight.luau"
local KIT = "src/shared/CorridorKit/Specs.luau"
local hazeTop = number(LIGHT, "HallLight%.HazeHeight = ([%d%.]+)")
	+ number(LIGHT, "HallLight%.HazeSizeEnd = ([%d%.]+)") / 2
local joists = number(KIT, "JoistBottom = ([%d%.]+)")
local tube = number(LIGHT, "HallLight%.Height = ([%d%.]+)")
local spacing = number(KIT, "JoistSpacing = ([%d%.]+)")
local tile = number(KIT, "FloorTile = ([%d%.]+)")
local straight = number(KIT, "Straight = {%s*Length = ([%d%.]+)")

ok(joists > hazeTop, `the haze reaches {hazeTop}, into the joists at {joists}`)
ok(tube < joists, `the tube at {tube} hangs below the joists at {joists}`)
ok(
	straight % tile == 0,
	`a straight piece ({straight}) meets the next on a floor joint (every {tile})`
)
ok(straight % spacing == 0, `joists keep their {spacing}-stud beat across pieces ({straight})`)
ok(straight % 24 == 0, `a straight piece holds whole hall lights (one every 24)`)

print(string.format("corridor: %d/%d checks passed", checks - failures, checks))
if failures > 0 then
	error("corridor spec failed")
end
