--!strict
-- lune run tests/wrap.spec
-- Laying the bubble wrap (L-14b2a): a sheet lies square across the hall just ahead of your toes,
-- the way you face, on the hall's centreline, unrolling from your left to your right; under your
-- feet at a dead end; never in a unit, on the tops or in the lobby; and on every floor, wherever
-- you stand in a hall and whichever way you face, the whole sheet lies on hall floor.
local fs = require("@lune/fs")

local Brix = require("../vendor/brix/src")
local Catalog = require("../src/shared/Tools/Catalog")
local Floor = require("../src/shared/Floor")
local Wrap = require("../src/shared/Tools/Wrap")

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

-- The generated Specs build Vector3s, which Lune hasn't: read the sheet's size from the text.
local SPECS = fs.readFile("src/shared/Tools/Specs/BubbleWrap.luau")
local sx, _, sz =
	string.match(SPECS, "Sheet = {%s*Size = Vector3.new%(([%d%.]+), ([%d%.]+), ([%d%.]+)%)")
assert(sx and sz, "no sheet size in the Specs")
local SHEET_X, SHEET_Z = tonumber(sx) :: number, tonumber(sz) :: number

local TOL = 1e-6
local function near(a: vector?, b: vector): boolean
	return a ~= nil and vector.magnitude(a - b) < TOL
end
local function v(x: number, y: number, z: number): vector
	return vector.create(x, y, z)
end

-- the catalog's row presses Lay, and the sheet's numbers are the art's
ok(Catalog.BubbleWrap.verb == "Lay", "the roll's press is Lay")
ok(math.abs(Wrap.Across - SHEET_X) < 0.01, "Across is the sheet's art")
ok(math.abs(Wrap.Deep - SHEET_Z) < 0.01, "Deep is the sheet's art")
ok(Wrap.Across < Floor.HallWidth, "the sheet fits across the hall")

-- one straight along X, x from -12 to 12, dead ends both ends
local alongX: { Wrap.Hall } = { { x = 0, z = 0, along = 0, half = 12 } }
do
	local p, a = Wrap.place(alongX, v(0, 3, 1), v(1, 0, 0))
	ok(near(p, v(Wrap.Ahead, 0, 0)), "facing +X: just ahead, on the centreline")
	ok(near(a, v(0, 0, 1)), "facing +X: across to your right (+Z)")
	p, a = Wrap.place(alongX, v(0, 3, -2), v(-1, 0, 0))
	ok(near(p, v(-Wrap.Ahead, 0, 0)), "facing -X: just ahead")
	ok(near(a, v(0, 0, -1)), "facing -X: across to your right (-Z)")
	p, a = Wrap.place(alongX, v(2, 3, 0), v(0.6, -0.3, 0.8))
	ok(near(p, v(2 + Wrap.Ahead, 0, 0)), "facing mostly across the hall: still along it, ahead")
	ok(near(a, v(0, 0, 1)), "facing a little +X: across to the +Z side")
	p, a = Wrap.place(alongX, v(0, 3, 0), v(0, 0, 1))
	ok(near(p, v(Wrap.Ahead, 0, 0)), "facing straight across: +X")
	-- crouched or crawling still lays; up on the tops doesn't
	ok(Wrap.place(alongX, v(0, 1, 0), v(1, 0, 0)) ~= nil, "crawling lays")
	ok(Wrap.place(alongX, v(0, 13, 0), v(1, 0, 0)) == nil, "up on the tops: no")
	-- in a unit beside the hall
	ok(Wrap.place(alongX, v(0, 3, 6), v(1, 0, 0)) == nil, "in a unit: no")
	ok(Wrap.place(alongX, v(0, 3, -4.5), v(1, 0, 0)) == nil, "past a door face: no")
	-- at a dead end: under your feet, or backed off the wall
	p = Wrap.place(alongX, v(10.5, 3, 0), v(1, 0, 0))
	ok(near(p, v(10.5, 0, 0)), "near a dead end: under your feet")
	p = Wrap.place(alongX, v(11.7, 3, 0), v(1, 0, 0))
	ok(near(p, v(11.7 - Wrap.Deep / 2, 0, 0)), "against a dead end: backed off its wall")
	p = Wrap.place(alongX, v(-11.7, 3, 0), v(-1, 0, 0))
	ok(near(p, v(-11.7 + Wrap.Deep / 2, 0, 0)), "against the other dead end")
end

-- two straights end to end: a sheet may lie across the joint
do
	local two: { Wrap.Hall } =
		{ { x = 0, z = 0, along = 0, half = 12 }, { x = 24, z = 0, along = 0, half = 12 } }
	local p = Wrap.place(two, v(11, 3, 0), v(1, 0, 0))
	ok(near(p, v(11 + Wrap.Ahead, 0, 0)), "across the joint between two straights")
end

-- a hall along Z
do
	local alongZ: { Wrap.Hall } = { { x = 24, z = 48, along = 1, half = 12 } }
	local p, a = Wrap.place(alongZ, v(25, 3, 48), v(0, 0, 1))
	ok(near(p, v(24, 0, 48 + Wrap.Ahead)), "along Z: on the centreline x = 24")
	ok(near(a, v(-1, 0, 0)), "facing +Z: across to your right (-X)")
	p, a = Wrap.place(alongZ, v(23, 3, 48), v(0, 0, -1))
	ok(near(a, v(1, 0, 0)), "facing -Z: across to your right (+X)")
end

-- a junction's middle square: either way, as you face
do
	local cross: { Wrap.Hall } = {
		{ x = 0, z = 0, along = -1, half = 4 },
		{ x = 8, z = 0, along = 0, half = 4 },
		{ x = -8, z = 0, along = 0, half = 4 },
		{ x = 0, z = 8, along = 1, half = 4 },
		{ x = 0, z = -8, along = 1, half = 4 },
	}
	local p, a = Wrap.place(cross, v(0, 3, 0), v(0.2, 0, 0.9))
	ok(near(p, v(0, 0, Wrap.Ahead)), "the middle square, facing +Z: along Z")
	ok(near(a, v(-1, 0, 0)), "the middle square, facing +Z: across to -X")
	p = Wrap.place(cross, v(0, 3, 0), v(-0.9, 0, 0.2))
	ok(near(p, v(-Wrap.Ahead, 0, 0)), "the middle square, facing -X: along X")
	p = Wrap.place(cross, v(9, 3, 1), v(1, 0, 0))
	ok(near(p, v(9 + Wrap.Ahead, 0, 0)), "an arm: along it")
end

-- real floors: every hall laid out; the lobby refused; and wherever you stand in a hall, facing
-- any way, the whole sheet lies on hall floor
local function onHalls(halls: { Wrap.Hall }, x: number, z: number): boolean
	for _, h in halls do
		local hx = if h.along == 1 then Floor.HallWidth / 2 else h.half
		local hz = if h.along == 0 then Floor.HallWidth / 2 else h.half
		if math.abs(x - h.x) <= hx + 1e-3 and math.abs(z - h.z) <= hz + 1e-3 then
			return true
		end
	end
	return false
end

local random = Brix.Random.new({ seed = 11 })
local function between(a: number, b: number): number
	return a + (b - a) * random:nextNumber()
end
for n = 1, 10 do
	local floor = Floor.generate(n, Brix.Random.new({ seed = 7 + n }))
	local halls = Wrap.halls(floor)
	local straights, junctions = 0, 0
	for _, c in floor.cells do
		if c.kind == "Straight" then
			straights += 1
		elseif c.kind ~= "Lobby" then
			junctions += 1
		end
	end
	ok(#halls >= straights + junctions, `floor {n}: a hall for every piece but the lobby`)
	for _, c in floor.cells do
		if c.kind == "Lobby" then
			ok(
				Wrap.place(halls, v(c.x, 3, c.z), v(0, 0, -1)) == nil,
				`floor {n}: the lobby refuses`
			)
		end
	end
	local bad = 0
	for _ = 1, 400 do
		local h = halls[random:nextInteger(1, #halls)]
		local hx = if h.along == 1 then Floor.HallWidth / 2 - 1 else h.half
		local hz = if h.along == 0 then Floor.HallWidth / 2 - 1 else h.half
		local at = v(h.x + between(-hx, hx), 3, h.z + between(-hz, hz))
		local turn = between(0, 2 * math.pi)
		local p, a = Wrap.place(halls, at, v(math.cos(turn), 0, math.sin(turn)))
		if not (p and a) then
			bad += 1
			continue
		end
		local along = vector.create(-a.z, 0, a.x)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = p + a * (sx * Wrap.Across / 2) + along * (sz * Wrap.Deep / 2)
				if not onHalls(halls, corner.x, corner.z) then
					bad += 1
				end
			end
		end
		if
			vector.magnitude(vector.create(p.x - at.x, 0, p.z - at.z))
			> Wrap.Ahead + Floor.HallWidth / 2
		then
			bad += 1
		end
	end
	ok(bad == 0, `floor {n}: every sheet laid whole on hall floor near you ({bad} not)`)
end

print(`wrap: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
