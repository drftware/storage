--!strict
-- lune run tests/corridor.spec
-- The corridor kit's numbers (generated from art/corridor/spec.py) against the hall's light and
-- the units: the haze must stay clear of the ceiling's steel, pieces must tile without a seam, the
-- fixture's lens must sit exactly where the light was tuned, between two joists, and the hall's
-- walls must take a unit's place. These files build Roblox values at load, so this reads their
-- numbers as text.
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
local lens = number(KIT, "LensHeight = ([%d%.]+)")
local reach = number(KIT, "Reach = ([%d%.]+)")
local fixtureTop = number(KIT, "Fixture = {.-Top = ([%d%.]+)")
local deck = number(KIT, "DeckHeight = ([%d%.]+)")
local UNIT = "src/shared/StorageUnit/Specs/M.luau"
local unitWidth = number(UNIT, "\n\tWidth = ([%d%.]+)")
local unitWalls = number(UNIT, "WallHeight = ([%d%.]+)")
local plain = number(KIT, "Wall = {%s*Width = ([%d%.]+)")
local deadEnd = number(KIT, "DeadEnd = {%s*Width = ([%d%.]+)")
local span = number(KIT, "Span = ([%d%.]+)")
local wallHeight = number(KIT, "WallHeight = ([%d%.]+)")
local function size(path: string, pattern: string): string
	local found = string.match(fs.readFile(path), pattern)
	assert(found, `{path}: no match for {pattern}`)
	return (string.gsub(found, "%s", ""))
end
local tubeSize = size(LIGHT, "HallLight%.TubeSize = Vector3%.new%(([^)]+)%)")
local lensSize = size(KIT, "LensSize = Vector3%.new%(([^)]+)%)")

ok(joists > hazeTop, `the haze reaches {hazeTop}, into the joists at {joists}`)
ok(tube < joists, `the tube at {tube} hangs below the joists at {joists}`)
ok(
	straight % tile == 0,
	`a straight piece ({straight}) meets the next on a floor joint (every {tile})`
)
ok(straight % spacing == 0, `joists keep their {spacing}-stud beat across pieces ({straight})`)
ok(straight % 24 == 0, `a straight piece holds whole hall lights (one every 24)`)
ok(lens == tube, `the fixture's lens at {lens} is where the light was tuned ({tube})`)
ok(lensSize == tubeSize, `the fixture's lens ({lensSize}) is the tuned tube's size ({tubeSize})`)
-- a fixture hangs midway between two joists, which leaves it half a spacing either way
ok(
	reach < spacing / 2,
	`the fixture reaches {reach} along the hall, into a joist {spacing / 2} away`
)
ok(
	fixtureTop < joists and fixtureTop < deck,
	`the fixture's housing ({fixtureTop}) hangs under the steel`
)

ok(plain == unitWidth, `a plain wall ({plain}) takes one unit's place ({unitWidth})`)
ok(straight % plain == 0, `a straight piece ({straight}) holds whole plain walls ({plain})`)
ok(wallHeight == unitWalls, `the walls' cap ({wallHeight}) lines up with the units' ({unitWalls})`)
ok(deadEnd == span, `the dead end ({deadEnd}) closes the whole deck ({span})`)

-- The junctions sit on the straights' grid, and every wall they stand is a whole slot.
local KIT_SRC = fs.readFile(KIT)
local short = number(KIT, "ShortWall = {%s*Width = ([%d%.]+)")
local hall = number(KIT, "HallWidth = ([%d%.]+)")
local widths = { Wall = plain, ShortWall = short }
local junctions = 0
for name, body in string.gmatch(KIT_SRC, "\n\t\t(%a+) = {\n\t\t\tSize = ([^\n]+)") do
	junctions += 1
	local size = tonumber(string.match(body, "[%d%.]+")) or 0
	ok(size == straight, `the {name} ({size}) takes a straight's place on the grid ({straight})`)
end
ok(junctions == 3, `the kit has a corner, a T and a cross ({junctions} junctions)`)
ok(
	(straight / 2 - hall / 2) % short == 0,
	`a junction's corner block is whole short walls ({short})`
)
for wname, x, z, lx, lz in
	string.gmatch(
		KIT_SRC,
		'Name = "(%a+)", Position = Vector3%.new%(([%-%d%.]+), 0, ([%-%d%.]+)%), Look = Vector3%.new%(([%-%d%.]+), 0, ([%-%d%.]+)%)'
	)
do
	local w = widths[wname]
	ok(w ~= nil, `a junction stands a plain wall, not {wname}`)
	local px, pz, ax, az = tonumber(x) or 0, tonumber(z) or 0, tonumber(lx) or 0, tonumber(lz) or 0
	-- on a face line, looking into the hall, and inside the square
	local face = if ax ~= 0 then math.abs(px) else math.abs(pz)
	local along = if ax ~= 0 then math.abs(pz) else math.abs(px)
	ok(face == hall / 2, `a {wname} at ({px}, {pz}) stands on a face line ({hall / 2})`)
	ok(along + (w or 0) / 2 <= straight / 2, `a {wname} at ({px}, {pz}) stays inside the junction`)
end

print(string.format("corridor: %d/%d checks passed", checks - failures, checks))
if failures > 0 then
	error("corridor spec failed")
end
