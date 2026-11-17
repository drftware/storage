--!strict
-- lune run tests/shelf.spec
-- The home's shelf (S5-03c1b): a find too big for its cubby is shrunk to fit, a small one is never
-- grown, a long thing lying deep turns a quarter to stand bigger, its bottom's middle lands on the
-- spot; and a Seen ask names a spot only as a whole number in range.
local Shelf = require("../src/shared/Home/Shelf")
local Specs = require("../src/shared/Home/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local room = Specs.Shelf.Room

-- a small find stands at its own size, square to the shelf, its bottom's middle on the spot
do
	local fit = Shelf.fit({ -0.5, 0, -0.3 }, { 0.5, 0.8, 0.3 }, room)
	ok(fit.scale == 1, "a small find is never grown")
	ok(fit.turn == 0, "a find that fits stands square")
	ok(
		near(fit.offset[1], 0) and near(fit.offset[2], 0) and near(fit.offset[3], 0),
		"a centred find needs no offset"
	)
end

-- a tall find is shrunk until it fits the cubby's height
do
	local fit = Shelf.fit({ -0.5, 0, -0.3 }, { 0.5, 4, 0.3 }, room)
	ok(near(fit.scale, room[2] / 4), "a tall find shrinks to the cubby's height")
	ok(fit.scale < 1, "a big find is shrunk")
end

-- a long thing lying deep turns a quarter: it stands bigger across than deep
do
	local fit = Shelf.fit({ -0.2, 0, -1.5 }, { 0.2, 0.4, 1.5 }, room)
	ok(fit.turn == 90, "a long thing lying deep turns a quarter")
	ok(near(fit.scale, math.min(1, room[1] / 3)), "turned, its length fits across")
	local square = Shelf.fit({ -1.5, 0, -0.2 }, { 1.5, 0.4, 0.2 }, room)
	ok(square.turn == 0, "a long thing lying across stays square")
end

-- the pivot sits so the box's bottom middle lands on the spot, scaled
do
	local fit = Shelf.fit({ 1, 0.5, -2 }, { 3, 4.5, -1 }, room)
	local s = fit.scale
	ok(near(s, 0.5), "a 2 by 4 by 1 find fits a 2 by 2 cubby at half")
	ok(near(fit.offset[1], -2 * s), "its middle across goes over the spot")
	ok(near(fit.offset[2], -0.5 * s), "its bottom goes on the board")
	ok(near(fit.offset[3], 1.5 * s), "its middle deep goes over the spot")
end

-- Seen names a spot only as a whole number in range
do
	local n = #Specs.Shelf.Spots
	ok(Shelf.spot(1, n) == 1 and Shelf.spot(n, n) == n, "every spot is named")
	ok(Shelf.spot(0, n) == nil and Shelf.spot(n + 1, n) == nil, "out of range is refused")
	ok(Shelf.spot(1.5, n) == nil, "a fraction is refused")
	ok(Shelf.spot(0 / 0, n) == nil and Shelf.spot(math.huge, n) == nil, "NaN and huge are refused")
	ok(Shelf.spot("1", n) == nil and Shelf.spot(nil, n) == nil, "other types are refused")
end

print(`shelf: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
