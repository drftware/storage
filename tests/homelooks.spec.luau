--!strict
-- lune run tests/homelooks.spec
-- The looks a player gives their home (S5-03g1a, Home.Specs.Looks, D-321): a home's save keeps
-- these ids, so each list's ids are unique and every colour reads as Color3.fromHex wants it. Each
-- list starts with what a new home has: warm white walls, a clay door, oak boards, plain plaster.
-- Every floor or paper names a texture set the art bakes, and only a floor whose colours are the
-- part's lists colours to pick from.
local fs = require("@lune/fs")

local Specs = require("../src/shared/Home/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local Looks = Specs.Looks

local function hex(c: string): boolean
	return string.match(c, "^#%x%x%x%x%x%x$") ~= nil
end

local function unique(rows: { { Id: string } }, what: string)
	local seen: { [string]: boolean } = {}
	for _, r in rows do
		ok(not seen[r.Id], `{what}: {r.Id} appears once`)
		seen[r.Id] = true
	end
end

local function swatches(rows: { Specs.Swatch }, what: string, least: number)
	ok(#rows >= least, `{what}: at least {least} to pick from`)
	unique(rows, what)
	for _, s in rows do
		ok(hex(s.Colour), `{what}: {s.Id}'s colour is #RRGGBB`)
	end
end

swatches(Looks.Paints, "paints", 6)
swatches(Looks.Doors, "doors", 6)
ok(#Looks.Paints <= 8 and #Looks.Doors <= 8, "no more than eight paints or door colours")
ok(
	Looks.Paints[1].Id == "WarmWhite" and Looks.Paints[1].Colour == "#E8DFCF",
	"walls start warm white"
)
ok(Looks.Doors[1].Id == "Clay" and Looks.Doors[1].Colour == "#B5684E", "a door starts clay")

-- the sets the art bakes: its looks.py LOOKS table
local looks = fs.readFile("art/home/looks.py")
local function baked(set: string): boolean
	return string.find(looks, `"{set}": (`, 1, true) ~= nil
end

unique(Looks.Floors, "floors")
ok(Looks.Floors[1].Id == "Boards" and Looks.Floors[1].Set == "Wood", "a floor starts oak boards")
for _, f in Looks.Floors do
	ok(baked(f.Set), `floor {f.Id}: its set {f.Set} is baked`)
	if f.Set == "Wood" then
		ok(#f.Colours == 0, "the boards keep the oak's own colour")
	else
		swatches(f.Colours, `floor {f.Id}`, 3)
	end
end

unique(Looks.Papers, "papers")
ok(Looks.Papers[1].Id == "Plain" and Looks.Papers[1].Set == "Plaster", "walls start plain plaster")
for _, p in Looks.Papers do
	ok(baked(p.Set), `paper {p.Id}: its set {p.Set} is baked`)
end

ok(Looks.FloorTile == 8 and Looks.PaperTile == 4, "floors tile at 8 studs, papers at 4")

print(`homelooks.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
