--!strict
-- lune run tests/group.spec
-- Several things moved as one in Arrange (S5-03j6b1, Home/Group): a slide keeps the group's
-- places round each other and leaves a thing on a wall where it hangs; a quarter turn swings each
-- about the group's middle and turns it with it, four bring them home; a screen's group ask is
-- read only when well formed; and the move itself is all or none: riders come along, two things
-- can swap places, and one refusal leaves the whole room exactly as it stood. Test-only ids:
-- nothing here is a shipped find.
local Brix = require("../vendor/brix/src")
local Group = require("../src/shared/Home/Group")

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
local function pose(on: string, x: number, y: number, turn: number?): Group.Pose
	return { on = on, x = x, y = y, turn = turn or 0 }
end
local function find(list: { Group.Member }, id: string): Group.Pose?
	for _, m in list do
		if m.id == id then
			return m.pose
		end
	end
	return nil
end

-- A slide: every floor thing by the same amount; the clock on the wall stays.
do
	local members: { Group.Member } = {
		{ id = "Box1", pose = pose("Floor", 0, 0, 90) },
		{ id = "Box2", pose = pose("Floor", 2, 1) },
		{ id = "Clock1", pose = pose("Wall1", 1, 1) },
	}
	local out = Group.moved(members, "Floor", 1.5, -2)
	local a, b = find(out, "Box1"), find(out, "Box2")
	ok(#out == 2 and find(out, "Clock1") == nil, "a slide leaves the wall thing out")
	ok(a ~= nil and near(a.x, 1.5) and near(a.y, -2) and a.turn == 90, "the first slides, unturned")
	ok(b ~= nil and near(b.x, 3.5) and near(b.y, -1), "the second keeps its place round the first")
	ok(members[1].pose.x == 0, "the members aren't changed")
	local cx, cy = Group.middle(members, "Floor")
	ok(cx ~= nil and near(cx, 1) and cy ~= nil and near(cy, 0.5), "the middle is the floor box's")
	ok(Group.middle({ members[3] }, "Floor") == nil, "no middle with nothing on the floor")
end

-- A quarter turn about the middle: a place (dx, dy) from it goes to (-dy, dx), each turned 90.
do
	local members: { Group.Member } = {
		{ id = "Box1", pose = pose("Floor", 0, 0, 0) },
		{ id = "Box2", pose = pose("Floor", 4, 0, 270) },
	}
	local out = Group.turned(members, "Floor", 1)
	local a, b = find(out, "Box1"), find(out, "Box2")
	ok(a ~= nil and near(a.x, 2) and near(a.y, -2) and a.turn == 90, "the first swings round")
	ok(b ~= nil and near(b.x, 2) and near(b.y, 2) and b.turn == 0, "the second, its turn wrapped")
	local back = Group.turned(out, "Floor", -1)
	local a2 = find(back, "Box1")
	ok(a2 ~= nil and near(a2.x, 0) and near(a2.y, 0) and a2.turn == 0, "a turn back undoes it")
	local four = members
	for _ = 1, 4 do
		four = Group.turned(four, "Floor", 1)
	end
	local b4 = find(four, "Box2")
	ok(b4 ~= nil and near(b4.x, 4) and near(b4.y, 0) and b4.turn == 270, "four turns bring it home")
end

-- A screen's ask: read only when it's a short clean list.
do
	local good = Group.ask({
		{ what = "Box#1", on = "Floor", x = 1, y = 2, turn = 450 },
		{ what = "Teddy", on = "Floor", x = 0, y = 0, turn = 0 },
	})
	ok(
		good ~= nil and #good == 2 and good[1].to.turn == 90,
		"a clean ask reads, turns brought round"
	)
	ok(Group.ask({}) == nil, "an empty ask is nothing")
	ok(Group.ask("Box#1") == nil, "a word isn't a list")
	ok(
		Group.ask({ [1] = { what = "Box#1", on = "Floor", x = 1, y = 2, turn = 0 }, k = 1 }) == nil,
		"a stray key"
	)
	ok(
		Group.ask({ [2] = { what = "Box#1", on = "Floor", x = 1, y = 2, turn = 0 } }) == nil,
		"a hole"
	)
	ok(
		Group.ask({ { what = "Box#1", on = "Floor", x = 1 / 0, y = 2, turn = 0 } }) == nil,
		"far off"
	)
	local twice = { what = "Box#1", on = "Floor", x = 1, y = 2, turn = 0 }
	ok(Group.ask({ twice, twice }) == nil, "one thing twice")
	local long = {}
	for i = 1, Group.Most + 1 do
		long[i] = { what = `Box#{i}`, on = "Floor", x = 0, y = 0, turn = 0 }
	end
	ok(Group.ask(long) == nil, "too many")
	ok(#(Group.askIds({ "Box#1", "Box#2" }) or {}) == 2, "ids read")
	ok(
		Group.askIds({ "Box#1", "Box#1" }) == nil and Group.askIds({ "Box" }) == nil,
		"twice, or not set out"
	)
end

-- The move itself, on Brix's own judge.
local SMALL: Brix.PlacementShape = { width = 1, depth = 1, fits = { "floor", "top" } }
local TABLE: Brix.PlacementShape =
	{ width = 2, depth = 1, fits = { "floor" }, top = { kind = "top", width = 2, depth = 1 } }
local function shapeOf(id: string): Brix.PlacementShape
	return if string.find(id, "^Table") then TABLE else SMALL
end
local function room(): Brix.Placements
	local set = Brix.Placements.new({
		areas = { Floor = { kind = "floor", width = 10, depth = 10 } },
		limit = 20,
	})
	assert(set:place("Table1", TABLE, pose("Floor", 0, 0)) == nil)
	assert(set:place("Cup1", SMALL, pose("Table1", 0.5, 0)) == nil)
	assert(set:place("Box1", SMALL, pose("Floor", 3, 0)) == nil)
	assert(set:place("Box2", SMALL, pose("Floor", 3, 2)) == nil)
	assert(set:place("Wall9", SMALL, pose("Floor", -4, -4)) == nil)
	set:takeEvents()
	return set
end
local function same(a: Brix.Placements, b: Brix.Placements): boolean
	local ra, rb = a:save().rows, b:save().rows
	if #ra ~= #rb then
		return false
	end
	local by: { [string]: Brix.PlacementRow } = {}
	for _, r in rb do
		by[r.id] = r
	end
	for _, r in ra do
		local o = by[r.id]
		if not (o and o.on == r.on and near(o.x, r.x) and near(o.y, r.y) and o.turn == r.turn) then
			return false
		end
	end
	return true
end

do
	local set = room()
	local moves = Group.moved({
		{ id = "Table1", pose = set:poseOf("Table1") :: Group.Pose },
		{ id = "Box1", pose = set:poseOf("Box1") :: Group.Pose },
	}, "Floor", -1, 3)
	ok(Group.apply(set, moves, shapeOf) == nil, "a group move lands")
	local t, c, b = set:poseOf("Table1"), set:poseOf("Cup1"), set:poseOf("Box1")
	ok(t ~= nil and near(t.x, -1) and near(t.y, 3), "the table moved")
	ok(c ~= nil and c.on == "Table1" and near(c.x, 0.5), "the cup rode along on its top")
	ok(b ~= nil and near(b.x, 2) and near(b.y, 3), "the box kept its place round the table")
end

-- Two things swap places: lifted first, they never block each other.
do
	local set = room()
	local swap = {
		{ id = "Box1", pose = pose("Floor", 3, 2) },
		{ id = "Box2", pose = pose("Floor", 3, 0) },
	}
	ok(Group.apply(set, swap, shapeOf) == nil, "two can swap")
	local a = set:poseOf("Box1")
	ok(a ~= nil and near(a.y, 2), "and did")
end

-- One refusal and nothing moves: the box into the stranger in the corner, or off the room.
do
	local set, before = room(), room()
	local moves = {
		{ id = "Table1", pose = pose("Floor", 2, -2) },
		{ id = "Box1", pose = pose("Floor", -4, -4) }, -- where Wall9 stands
	}
	ok(Group.apply(set, moves, shapeOf) ~= nil, "a blocked one refuses the group")
	ok(same(set, before), "and the whole room stands as it did, the cup on its table")
	local off = { { id = "Table1", pose = pose("Floor", 40, 0) } }
	ok(Group.apply(set, off, shapeOf) ~= nil and same(set, before), "off the room, likewise")
end

-- Refused before anything changes: not set out, twice, or riding on another of the group.
do
	local set, before = room(), room()
	ok(
		Group.apply(set, { { id = "Box7", pose = pose("Floor", 0, 4) } }, shapeOf) == "notPlaced",
		"not out"
	)
	local dup =
		{ { id = "Box1", pose = pose("Floor", 0, 4) }, { id = "Box1", pose = pose("Floor", 1, 4) } }
	ok(Group.apply(set, dup, shapeOf) == "badAsk", "one thing twice")
	local riding = {
		{ id = "Table1", pose = pose("Floor", 0, 4) },
		{ id = "Cup1", pose = pose("Floor", 4, 4) },
	}
	ok(Group.apply(set, riding, shapeOf) == "badAsk", "a rider and its base")
	ok(same(set, before), "nothing changed")
end

-- A turn that won't fit tries the nearest nudges first (S5-03j7b2): every offset within `most`
-- steps, never no move, each once, sorted by distance so the group shifts the least it can.
do
	local list = Group.nudges(0.5, 2)
	ok(#list == 24, "five by five less the middle: 24 nudges")
	local seen, last, zero = {}, 0, false
	for _, n in list do
		local d = math.sqrt(n.dx * n.dx + n.dy * n.dy)
		ok(d >= last - 1e-9, "nearest first")
		last = d
		zero = zero or (n.dx == 0 and n.dy == 0)
		seen[string.format("%g,%g", n.dx, n.dy)] = true
	end
	ok(not zero, "never no move")
	ok(seen["0.5,0"] and seen["-1,-1"] and seen["1,1"], "steps of the size asked, both ways")
	ok(math.abs(list[1].dx) + math.abs(list[1].dy) == 0.5, "first a single step")
	ok(#Group.nudges(0.5, 0) == 0, "no steps, no nudges")
end

print(string.format("group: %d checks, %d failed", checks, failures))
if failures > 0 then
	error("group spec failed")
end
