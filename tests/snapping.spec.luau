--!strict
-- lune run tests/snapping.spec
-- How a thing dragged in Arrange snaps (S5-03j3a, Home/Snapping): a piece whose edge comes within
-- `Reach` of the back wall or a side wall is against it (never the door's), and stays against it
-- until it's `Give` further off; in a corner the nearer wall wins, and walls about as near go to
-- the one its back already faces; against a wall it sits flush; only arriving at a wall turns
-- its back to it, so a turn the player gives it there stays. A find hops onto a top only when its
-- middle is over it, and steps down only past the top's edge by `Over`, so it never flickers at
-- the edge. Brix's line-up is kept only where it stays in the area and, against a wall, along it.
local Snapping = require("../src/shared/Home/Snapping")

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

-- A Medium-ish floor: 10 across (x, the left wall at +5), 12 deep (y, the back wall at -6, the
-- door at +6). A crate 2 wide, 1 deep, square on: it reaches 1 across and 0.5 deep.
local FLOOR = { width = 10, depth = 12 }
local RX, RY = 1, 0.5
local BACK, LEFT, DOOR, RIGHT = Snapping.Back, Snapping.Left, Snapping.Door, Snapping.Right

-- How far its edge is off each wall.
do
	ok(near(Snapping.gap(FLOOR, BACK, 0, -5, RX, RY), 0.5), "back: y -5 less its 0.5, off -6")
	ok(near(Snapping.gap(FLOOR, LEFT, 3, 0, RX, RY), 1), "left: x 3 plus its 1, short of 5")
	ok(near(Snapping.gap(FLOOR, RIGHT, -3.5, 0, RX, RY), 0.5), "right: x -3.5 less 1, off -5")
	ok(near(Snapping.gap(FLOOR, DOOR, 0, 5.5, RX, RY), 0), "door: flush at 5.5")
	ok(Snapping.across(BACK) == "y" and Snapping.across(DOOR) == "y", "back and door run along x")
	ok(Snapping.across(LEFT) == "x" and Snapping.across(RIGHT) == "x", "the sides run along y")
end

-- Which wall it's against.
do
	ok(Snapping.wall(FLOOR, 0, 0, RX, RY, 0, nil) == nil, "the room's middle: no wall")
	local inReach = -6 + RY + Snapping.Reach -- its edge exactly `Reach` off the back wall
	ok(Snapping.wall(FLOOR, 0, inReach, RX, RY, 0, nil) == BACK, "within reach: the back wall")
	ok(Snapping.wall(FLOOR, 0, inReach + 0.01, RX, RY, 0, nil) == nil, "just past reach: none")
	-- the give: once against it, it stays until `Give` further
	local held = inReach + Snapping.Give
	ok(Snapping.wall(FLOOR, 0, held, RX, RY, 0, BACK) == BACK, "against it: held to reach + give")
	ok(Snapping.wall(FLOOR, 0, held + 0.01, RX, RY, 0, BACK) == nil, "past the give: let go")
	ok(Snapping.wall(FLOOR, 0, held, RX, RY, 0, nil) == nil, "the give is only for one against it")
	-- the door's wall never counts
	ok(Snapping.wall(FLOOR, 0, 6 - RY, RX, RY, 0, nil) == nil, "flush at the door: no wall")
	ok(Snapping.wall(FLOOR, 0, 6 - RY, RX, RY, 0, DOOR) == nil, "nor held there")
	-- a side
	ok(Snapping.wall(FLOOR, 5 - RX - 0.2, 0, RX, RY, 0, nil) == LEFT, "near the left wall")
	ok(Snapping.wall(FLOOR, -5 + RX + 0.2, 0, RX, RY, 0, nil) == RIGHT, "near the right wall")
	-- a corner: the nearer wall wins
	ok(
		Snapping.wall(FLOOR, 5 - RX - 0.9, -6 + RY + 0.1, RX, RY, 90, nil) == BACK,
		"by the back-left corner, nearer the back: the back wall, though it faces the left"
	)
	-- walls about as near: the one its back already faces
	ok(
		Snapping.wall(FLOOR, 5 - RX, -6 + RY, RX, RY, 90, nil) == LEFT,
		"in the corner, back to the left wall: the left"
	)
	ok(
		Snapping.wall(FLOOR, 5 - RX, -6 + RY, RX, RY, 0, nil) == BACK,
		"in the corner, back to the back wall: the back"
	)
	ok(
		Snapping.wall(FLOOR, 5 - RX - 0.3, -6 + RY, RX, RY, 90, nil) == LEFT,
		"within give of the nearest, the wall it faces wins"
	)
	-- held against one wall, it keeps it right into the corner: no flip as it reaches the other
	for i = 0, 10 do
		local x = 5 - RX - 1 + i * 0.1
		ok(
			Snapping.wall(FLOOR, x, -6 + RY, RX, RY, 0, BACK) == BACK,
			"slid along the back wall into the corner keeps the back wall, x " .. x
		)
	end
	-- pulled out of the corner along the left wall, it goes over to the left wall
	local off = -6 + RY + Snapping.Reach + Snapping.Give + 0.5
	ok(Snapping.wall(FLOOR, 5 - RX, off, RX, RY, 0, BACK) == LEFT, "round the corner: the left")
end

-- No flicker at a wall's reach: back and forth across it, the answer changes only twice.
do
	local at: number? = nil
	local changes = 0
	local edge = -6 + RY + Snapping.Reach
	local path = { 0.3, 0.05, -0.05, 0.05, -0.05, 0.05, 0.3, 0.05, 0.3, 0.6, 0.7 }
	for _, d in path do
		local now = Snapping.wall(FLOOR, 0, edge + d, RX, RY, 0, at)
		if now ~= at then
			changes += 1
		end
		at = now
	end
	ok(changes == 2, "in at the reach, out past the give: two changes, saw " .. changes)
end

-- Flush against a wall: across it the edge touches; along it as it was.
do
	local x, y = Snapping.flush(FLOOR, BACK, 1.5, -4.8, RX, RY)
	ok(near(x, 1.5) and near(y, -5.5), "back: y to -5.5, x kept")
	x, y = Snapping.flush(FLOOR, LEFT, 3.4, 2, RY, RX) -- turned a quarter: reach swapped
	ok(near(x, 4.5) and near(y, 2), "left: x to 4.5, y kept")
	x, y = Snapping.flush(FLOOR, RIGHT, -3.4, 2, RY, RX)
	ok(near(x, -4.5) and near(y, 2), "right: x to -4.5")
	x, y = Snapping.flush(FLOOR, DOOR, 0, 5, RX, RY)
	ok(near(y, 5.5), "door: y to 5.5")
	ok(near(Snapping.gap(FLOOR, LEFT, 4.5, 2, RY, RX), 0), "flush is a gap of 0")
end

-- Only arriving at a wall turns its back to it.
do
	ok(Snapping.turned(37, nil, nil) == 37, "in the room: as it was")
	ok(Snapping.turned(180, BACK, nil) == 0, "arriving at the back wall: back to it")
	ok(Snapping.turned(0, LEFT, BACK) == 90, "round the corner to the left wall: back to that")
	ok(Snapping.turned(90, BACK, BACK) == 90, "turned by the player at the wall: theirs stays")
	ok(Snapping.turned(90, nil, BACK) == 90, "leaving the wall: keeps its turn")
end

-- Onto a top: a 3 by 2 table (half 1.5 by 1).
do
	ok(Snapping.over(0, 0, 3, 2, false), "the middle over its middle: onto it")
	ok(Snapping.over(1.5, 1, 3, 2, false), "right on its corner: onto it")
	ok(not Snapping.over(1.51, 0, 3, 2, false), "just past its edge: not yet")
	ok(Snapping.over(1.5 + Snapping.Over, 0, 3, 2, true), "on it, past the edge by the give: stays")
	ok(not Snapping.over(1.5 + Snapping.Over + 0.01, 0, 3, 2, true), "past the give: steps down")
	ok(
		not Snapping.over(0, -1 - Snapping.Over - 0.01, 3, 2, true),
		"past the give on y: steps down"
	)
	-- back and forth over the edge: up once, down once
	local on, changes = false, 0
	local path = { 1.2, 1.45, 1.55, 1.45, 1.55, 1.45, 1.55, 1.8, 2, 1.7, 1.6 }
	for _, x in path do
		local now = Snapping.over(x, 0, 3, 2, on)
		if now ~= on then
			changes += 1
		end
		on = now
	end
	ok(changes == 2, "onto it at once, off it past the give: two changes, saw " .. changes)
end

-- Brix's line-up, kept where it holds.
do
	local function guides(): { Snapping.Guide }
		return {
			{ axis = "x", at = 1, from = -2, to = 2 },
			{ axis = "x", at = 2, from = -2, to = 2 },
			{ axis = "y", at = -5, from = 0, to = 3 },
		}
	end
	-- in the room: both its moves taken, every line kept
	local g = guides()
	local x, y, count = Snapping.lineUp(1, 1, 1.2, 0.9, 4, 5, nil, g, 3)
	ok(near(x, 1.2) and near(y, 0.9) and count == 3, "in the room: lined up, three lines")
	-- against the back wall: it slides along it to line up, never off it
	g = guides()
	x, y, count = Snapping.lineUp(1, -5.5, 1.2, -5.3, 4, 5.5, "y", g, 3)
	ok(near(x, 1.2) and near(y, -5.5), "against the back wall: along it, still flush")
	ok(count == 2 and g[1].axis == "x" and g[2].axis == "x", "its across lines dropped")
	-- against the wall with the line-up already flush (a row of shelves): its lines stay
	g = guides()
	x, y, count = Snapping.lineUp(1, -5.5, 1, -5.5, 4, 5.5, "y", g, 3)
	ok(count == 3, "a row against the wall keeps the line along it")
	-- a line-up that would push it out of its area: not taken on that side
	g = guides()
	x, y, count = Snapping.lineUp(3.9, 0, 4.1, 0, 4, 5, nil, g, 3)
	ok(near(x, 3.9) and count == 1 and g[1].axis == "y", "out past the area: x lines dropped")
	-- dropping keeps the rest in order and every entry still in the list (reused next move)
	g = guides()
	local first, second, third = g[1], g[2], g[3]
	count = Snapping.drop(g, 3, "x")
	ok(count == 1 and g[1] == third, "the y line comes first")
	ok(#g == 3 and (g[2] == first or g[3] == first) and (g[2] == second or g[3] == second), "kept")
	ok(Snapping.drop(g, 0, "y") == 0, "nothing to drop")
end

print(string.format("snapping: %d checks, %d failed", checks, failures))
if failures > 0 then
	error("snapping spec failed")
end
