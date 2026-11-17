--!strict
-- lune run tests/homepanels.spec
-- The panels a home's looks land on (S5-03g2a, Home.Specs.Panels and Swatches, D-325): every
-- floor's and paper's set has a swatch part in Home.fbx, so its SurfaceAppearance reaches Studio
-- for the game to clone onto a panel. The floor panel covers the unit's floor inside its walls and
-- the four wall panels its walls, floor to ceiling, meeting at the corners, each a hair proud of
-- the lobby's merged walls (which stay under them). The unit's frame: the doorway's outer face on
-- the floor, Z into the unit, Y up.
local Specs = require("../src/shared/Home/Specs")
local Lobby = require("../src/shared/Lobby/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 0.002
end

-- The XL slot's inside (art/lobby/spec.py): Inside runs from the front wall's outer face plus its
-- thickness to the back wall's middle, and across between the partitions' middles.
local inside = Lobby.Slots[1].Inside.Size
local WALL = 0.25 -- the facade's, partitions' and back wall's thickness (art/lobby, art/unit)
local half = (inside[3] - WALL) / 2 -- a partition's face, either side of the middle
local front = WALL + 0.04 -- the front wall's inside face (FacadeBack's, art/home/front.py)
local back = WALL + inside[1] - WALL / 2 -- the back wall's face
local height = inside[2]

type Box = { lo: { number }, hi: { number } }
local function placed(p: Specs.Panel): Box?
	local part = Specs.Parts[p.Part]
	if not part then
		return nil
	end
	local s = part.Size
	local turned = math.abs(p.Turn) == 90
	local e = if turned then { s[3], s[2], s[1] } else { s[1], s[2], s[3] }
	local lo, hi = {}, {}
	for i = 1, 3 do
		lo[i] = p.At[i] + part.Centre[i] - e[i] / 2
		hi[i] = p.At[i] + part.Centre[i] + e[i] / 2
	end
	return { lo = lo, hi = hi }
end

local floor = placed(Specs.Panels.Floor)
ok(floor ~= nil, "the floor panel is a part")
local proud = 0
if floor then
	proud = floor.hi[2] - floor.lo[2]
	ok(near(floor.lo[1], -half) and near(floor.hi[1], half), "the floor panel runs wall to wall")
	ok(
		near(floor.lo[3], front) and near(floor.hi[3], back),
		"the floor panel runs door to back wall"
	)
	ok(
		near(floor.lo[2], 0) and proud > 0 and proud <= 0.03,
		"the floor panel lies a hair on the floor"
	)
end

local walls: { [string]: Box } = {}
for _, p in Specs.Panels.Walls do
	local b = placed(p)
	ok(b ~= nil, `{p.Part} is a part`)
	if b then
		walls[p.Part] = b
		ok(near(b.lo[2], 0) and near(b.hi[2], height), `{p.Part} runs floor to ceiling`)
		local thin = math.min(b.hi[1] - b.lo[1], b.hi[3] - b.lo[3])
		ok(near(thin, proud), `{p.Part} is as proud as the floor panel`)
	end
end
local l, r, bk, fr = walls.PanelLeft, walls.PanelRight, walls.PanelBack, walls.PanelFront
ok(
	l ~= nil and r ~= nil and bk ~= nil and fr ~= nil,
	"a panel on each partition, the back and the front"
)
if l and r and bk and fr then
	-- as you walk in (facing +Z) your left is +X
	ok(near(l.hi[1], half) and near(r.lo[1], -half), "the side panels lie on the partitions' faces")
	ok(
		near(bk.hi[3], back) and near(fr.lo[3], front),
		"the back and front panels lie on their walls"
	)
	for _, b in { bk, fr } do
		ok(
			near(b.lo[1], -half) and near(b.hi[1], half),
			"the back and front panels run wall to wall"
		)
	end
	for _, b in { l, r } do
		ok(
			near(b.lo[3], fr.hi[3]) and near(b.hi[3], bk.lo[3]),
			"the side panels meet the front and back panels"
		)
	end
end

-- Every look's set has a swatch part, and every swatch is a look's set.
local sets: { [string]: boolean } = {}
for _, f in Specs.Looks.Floors do
	sets[f.Set] = true
end
for _, p in Specs.Looks.Papers do
	sets[p.Set] = true
end
for set in sets do
	local part = Specs.Swatches[set]
	ok(part ~= nil and Specs.Parts[part] ~= nil, `the set {set} has a swatch part`)
end
for set, part in Specs.Swatches do
	ok(sets[set] == true, `swatch {part} is a look's set`)
	local p = Specs.Parts[part]
	ok(p ~= nil and p.Triangles <= 12, `swatch {part} is a small part`)
end

print(`homepanels.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
