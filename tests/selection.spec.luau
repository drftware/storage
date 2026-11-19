--!strict
-- lune run tests/selection.spec
-- Which things a box dragged in Arrange takes (S5-03j6a, Home/Selection): exactly the things
-- whose middle is in the box and ahead of the camera, nothing while the box is still small, the
-- box the same either way it's drawn; a thing riding on a chosen base counts once, through its
-- base, however high the stack; what lights up is the roots and all their riders; and the ticks
-- count only things that just joined. Test-only names: nothing here is a shipped find.
local Selection = require("../src/shared/Home/Selection")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function list(t: { string }): string
	return table.concat(t, ",")
end

-- A small room as the screen sees it: a crate with a lamp on it and a cup on the lamp's tray, a
-- rug, a chair far off, and a stool behind the camera.
local points: { Selection.Point } = {
	{ id = "Crate", x = 100, y = 100, ahead = true },
	{ id = "Lamp", x = 104, y = 80, ahead = true },
	{ id = "Cup", x = 106, y = 70, ahead = true },
	{ id = "Rug", x = 160, y = 140, ahead = true },
	{ id = "Chair", x = 400, y = 300, ahead = true },
	{ id = "Stool", x = 150, y = 120, ahead = false },
}
local bases: { [string]: string } = { Lamp = "Crate", Cup = "Lamp" }
local function baseOf(id: string): string?
	return bases[id]
end
local function standingOn(id: string): { string }
	local out = {}
	for _, p in points do
		if bases[p.id] == id then
			table.insert(out, p.id)
		end
	end
	return out
end

-- The box: either corner first gives the same box.
do
	local a = Selection.box(200, 50, 90, 150)
	local b = Selection.box(90, 150, 200, 50)
	ok(a.left == 90 and a.right == 200 and a.top == 50 and a.bottom == 150, "corners sorted")
	ok(
		b.left == a.left and b.top == a.top and b.right == a.right and b.bottom == a.bottom,
		"same box"
	)
	local into = { left = 0, top = 0, right = 0, bottom = 0 }
	ok(Selection.box(1, 2, 3, 4, into) == into, "fills the box it's given")
end

-- A box round three things takes exactly those, in the room's order; edges count.
do
	local got = Selection.inside(Selection.box(90, 60, 170, 150), points)
	ok(list(got) == "Crate,Lamp,Cup,Rug", "the box round crate, lamp, cup and rug: " .. list(got))
	local edge = Selection.inside(Selection.box(100, 100, 160, 140), points)
	ok(list(edge) == "Crate,Rug", "a middle on the edge counts: " .. list(edge))
	local behind = Selection.inside(Selection.box(140, 110, 160, 130), points)
	ok(#behind == 0, "a thing behind the camera never counts")
end

-- Nothing while the box is under the slop; past it either way, it takes.
do
	local s = Selection.Slop
	ok(#Selection.inside(Selection.box(99, 99, 99 + s - 1, 99 + s - 1), points) == 0, "small: none")
	ok(not Selection.big(Selection.box(0, 0, s - 1, s - 1)), "under the slop isn't big")
	ok(Selection.big(Selection.box(0, 0, s, 0)), "the slop across is big")
	ok(Selection.big(Selection.box(0, 0, 0, s)), "the slop down is big")
end

-- `inside` fills and empties the list it's given.
do
	local into = { "Old" }
	local got = Selection.inside(Selection.box(390, 290, 410, 310), points, into)
	ok(got == into and list(got) == "Chair", "fills the given list, emptied first")
end

-- Roots: a rider on a chosen base rides with it, however high; a rider alone is its own root.
do
	ok(
		list(Selection.roots({ "Crate", "Lamp", "Cup", "Rug" }, baseOf)) == "Crate,Rug",
		"stack: crate"
	)
	ok(list(Selection.roots({ "Lamp", "Cup" }, baseOf)) == "Lamp", "the lamp without its crate")
	ok(list(Selection.roots({ "Cup", "Crate" }, baseOf)) == "Crate", "cup two up rides the crate")
	ok(list(Selection.roots({ "Cup" }, baseOf)) == "Cup", "a rider alone is a root")
	local loop: { [string]: string } = { A = "B", B = "A" }
	local got = Selection.roots({ "A" }, function(id)
		return loop[id]
	end)
	ok(#got == 1, "a bad loop of bases ends")
end

-- Lit: the roots and every rider on them, each once, roots first.
do
	ok(
		list(Selection.lit({ "Crate", "Rug" }, standingOn)) == "Crate,Lamp,Cup,Rug",
		"crate lights all"
	)
	ok(list(Selection.lit({ "Lamp" }, standingOn)) == "Lamp,Cup", "the lamp lights its cup")
	ok(list(Selection.lit({ "Crate", "Crate" }, standingOn)) == "Crate,Lamp,Cup", "each once")
end

-- Joined and same: one tick for each thing that just joined; order doesn't matter.
do
	ok(Selection.joined({}, { "A", "B" }) == 2, "two joined")
	ok(Selection.joined({ "A" }, { "A", "B" }) == 1, "one joined")
	ok(Selection.joined({ "A", "B" }, { "A" }) == 0, "leaving isn't joining")
	ok(Selection.same({ "A", "B" }, { "B", "A" }), "same in any order")
	ok(not Selection.same({ "A" }, { "A", "B" }), "not the same")
end

print(string.format("selection: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("selection spec failed")
end
