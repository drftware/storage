--!strict
-- lune run tests/wallhang.spec
-- How a thing that hangs on a wall moves in Arrange (S5-03j3c, Home/WallHang): only things that
-- fit walls alone hang; dragged, one keeps the height it hangs at and only slides along, kept on
-- the wall; fresh from the box it takes the finger's height; the handle raises and lowers it in
-- steps from the wall's middle (Free: by eye), never past the wall's top or bottom.
local WallHang = require("../src/shared/Home/WallHang")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

-- Which things hang: read from what they fit, no names.
do
	ok(WallHang.only({ "wall" }, "wall"), "a wall thing hangs")
	ok(not WallHang.only({ "floor", "top" }, "wall"), "a tabletop find doesn't")
	ok(not WallHang.only({ "floor", "wall" }, "wall"), "one that also stands doesn't")
	ok(not WallHang.only({ "ceiling" }, "wall"), "a ceiling thing doesn't")
	ok(not WallHang.only({}, "wall"), "nothing fits: not a wall thing")
end

-- A wall 8 high; a moon 2 tall can hang 3 up or down from the middle.
local DEPTH, TALL = 8, 2
do
	ok(near(WallHang.room(DEPTH, TALL), 3), "room either way")
	ok(near(WallHang.room(2, 3), 0), "taller than the wall: the middle only")
end

-- Dragged: the kept height wins over where the finger is.
do
	ok(near(WallHang.height(-2.7, 1.5, DEPTH, TALL), 1.5), "kept height, finger low")
	ok(near(WallHang.height(2.9, 1.5, DEPTH, TALL), 1.5), "kept height, finger high")
	ok(near(WallHang.height(-40, 1.5, DEPTH, TALL), 1.5), "finger far below the wall")
	ok(near(WallHang.height(0, 3.4, DEPTH, TALL), 3), "a kept height past the top is kept on")
	ok(near(WallHang.height(0, -9, DEPTH, TALL), -3), "past the bottom too")
	-- the same height carried round a corner onto a shorter wall still stays on it
	ok(near(WallHang.height(0, 2.5, 6, TALL), 2), "a shorter wall keeps it on")
end

-- Fresh from the box (nothing kept): where the finger is, kept on the wall.
do
	ok(near(WallHang.height(1.25, nil, DEPTH, TALL), 1.25), "the finger's height")
	ok(near(WallHang.height(5, nil, DEPTH, TALL), 3), "the finger above the top")
	ok(near(WallHang.height(-5, nil, DEPTH, TALL), -3), "the finger below the bottom")
end

-- The handle: half-stud steps from the wall's middle.
do
	ok(near(WallHang.raise(1, 0.2, 0.5, DEPTH, TALL), 1), "a small drag stays on its step")
	ok(near(WallHang.raise(1, 0.3, 0.5, DEPTH, TALL), 1.5), "past half a step: the next")
	ok(near(WallHang.raise(1, -1.1, 0.5, DEPTH, TALL), 0), "down two steps")
	ok(near(WallHang.raise(1, 10, 0.5, DEPTH, TALL), 3), "the top step")
	ok(near(WallHang.raise(1, -10, 0.5, DEPTH, TALL), -3), "the bottom step")
	-- a room that isn't a whole number of steps: the last step inside it, never off the wall
	ok(near(WallHang.raise(0, 10, 0.5, 7.5, TALL), 2.5), "top step inside an odd wall")
	ok(near(WallHang.raise(0, -10, 0.5, 7.5, TALL), -2.5), "bottom step inside an odd wall")
	-- a thing hung off the grid (Free) steps onto the grid as it's raised
	ok(near(WallHang.raise(1.13, 0.3, 0.5, DEPTH, TALL), 1.5), "onto the grid")
end

-- Free: by eye, still kept on the wall.
do
	ok(near(WallHang.raise(1, 0.37, 0, DEPTH, TALL), 1.37), "free follows the drag")
	ok(near(WallHang.raise(1, 9, 0, 7.5, TALL), 2.75), "free stops at the top")
	ok(near(WallHang.raise(1, -9, 0, DEPTH, TALL), -3), "free stops at the bottom")
end

print(string.format("wallhang: %d checks, %d failed", checks, failures))
if failures > 0 then
	error("wallhang spec failed")
end
