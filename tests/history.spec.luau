--!strict
-- lune run tests/history.spec
-- Undo and redo in Arrange (S5-03j4a, Home/History): a move undone asks to go back where it stood
-- and redone asks to go again; a set-out undone is a Put away, a put-away undone sets it out by
-- name; a thing that comes back under a new id is followed by every older step; a refused ask
-- drops its step; one ask at a time; closing forgets everything.
local Brix = require("../vendor/brix/src")
local History = require("../src/shared/Home/History")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function pose(x: number, y: number): History.Pose
	return { on = "Floor", x = x, y = y, turn = 0 }
end

local function fresh(): History.History
	local list: Brix.UndoList<History.Step> = Brix.UndoList.new({ limit = 50 })
	return History.new(list)
end

local A, B, C = pose(1, 1), pose(2, 2), pose(3, 3)

-- A move undone goes back; redone, goes again.
do
	local h = fresh()
	ok(not h.canUndo() and h.undo() == nil, "nothing to undo at first")
	h.record("Crate", "Crate1", A, "Crate1", B)
	ok(h.canUndo() and not h.canRedo(), "a move can be undone")
	local ask = h.undo()
	ok(
		ask ~= nil and ask.id == "Crate1" and ask.to == A and ask.name == "Crate",
		"undo asks to go back"
	)
	ok(h.waiting() and h.undo() == nil and h.redo() == nil, "one ask at a time")
	h.answered(true, "Crate1")
	ok(not h.waiting() and h.canRedo() and not h.canUndo(), "undone, it can be redone")
	local again = h.redo()
	ok(again ~= nil and again.id == "Crate1" and again.to == B, "redo asks to go again")
	h.answered(true, "Crate1")
	ok(h.canUndo() and not h.canRedo(), "redone, it can be undone")
end

-- Out of the box and back: a set-out undone is a Put away; redone, it's set out by name.
do
	local h = fresh()
	h.record("Lamp", nil, nil, "Lamp1", A)
	local ask = h.undo()
	ok(ask ~= nil and ask.id == "Lamp1" and ask.to == nil, "a set-out undone puts it away")
	h.answered(true, nil)
	local again = h.redo()
	ok(
		again ~= nil and again.id == nil and again.name == "Lamp" and again.to == A,
		"redone, set out by name"
	)
	h.answered(true, "Lamp2") -- the server gave it another number
	local back = h.undo()
	ok(back ~= nil and back.id == "Lamp2", "the thing is followed under its new id")
	h.answered(true, nil)
end

-- A put-away undone sets it out; older steps follow its new id.
do
	local h = fresh()
	h.record("Bed", "Bed1", A, "Bed1", B) -- moved
	h.record("Bed", "Bed1", B, nil, nil) -- then put away
	local ask = h.undo()
	ok(
		ask ~= nil and ask.id == nil and ask.name == "Bed" and ask.to == B,
		"a put-away undone sets it out"
	)
	h.answered(true, "Bed3")
	local older = h.undo()
	ok(older ~= nil and older.id == "Bed3" and older.to == A, "the move before follows the new id")
	h.answered(true, "Bed3")
end

-- A refused ask drops its step; the rest stay in order.
do
	local h = fresh()
	h.record("Crate", "Crate1", A, "Crate1", B)
	h.record("Crate", "Crate1", B, "Crate1", C)
	local ask = h.undo()
	ok(ask ~= nil and ask.to == B, "undo the latest first")
	h.answered(false, nil) -- the spot was taken
	ok(not h.canRedo(), "a refused undo isn't redone")
	local older = h.undo()
	ok(older ~= nil and older.to == A, "the older step is still there")
	h.answered(true, "Crate1")
	local redo = h.redo()
	ok(redo ~= nil and redo.to == B, "and redoes")
	h.answered(false, nil)
	ok(not h.canRedo() and not h.canUndo(), "a refused redo is dropped too")
end

-- A fresh change empties the redo side; two things keep their own steps.
do
	local h = fresh()
	h.record("Crate", "Crate1", A, "Crate1", B)
	h.record("Lamp", "Lamp1", A, "Lamp1", C)
	local ask = h.undo()
	ok(ask ~= nil and ask.id == "Lamp1", "the lamp's move first")
	h.answered(true, "Lamp1")
	h.record("Crate", "Crate1", B, "Crate1", C)
	ok(not h.canRedo(), "a fresh move empties redo")
	local crate = h.undo()
	ok(crate ~= nil and crate.id == "Crate1" and crate.to == B, "the crate's newest move")
	h.answered(true, "Crate1")
end

-- A new set-out under an id a put-away thing once had is a new thing.
do
	local h = fresh()
	h.record("Lamp", nil, nil, "Lamp1", A)
	h.record("Lamp", "Lamp1", A, nil, nil) -- put away
	h.record("Lamp", nil, nil, "Lamp1", B) -- another set out, numbered 1 again
	local ask = h.undo()
	ok(ask ~= nil and ask.id == "Lamp1" and ask.to == nil, "the new one goes back in the box")
	h.answered(true, nil)
	local older = h.undo()
	ok(older ~= nil and older.id == nil and older.to == A, "the old one comes back out by name")
	h.answered(true, "Lamp1")
end

-- Box to box is no step; an answer with nothing waiting does nothing; clear forgets all.
do
	local h = fresh()
	h.record("Lamp", nil, nil, nil, nil)
	ok(not h.canUndo(), "box to box records nothing")
	h.answered(true, "Lamp1")
	ok(not h.waiting(), "a stray answer changes nothing")
	h.record("Crate", "Crate1", A, "Crate1", B)
	h.undo()
	h.clear()
	ok(not h.canUndo() and not h.canRedo() and not h.waiting(), "clear forgets everything")
end

-- A group (S5-03j6b1): moved together is one step; undo asks for all of them at once, and one
-- answer follows every thing; a group put away and undone sets each out by name, and the new ids
-- the answer gives are followed by the redo; a refused group drops its one step.
do
	local h = fresh()
	h.recordGroup({
		{ name = "Crate", idBefore = "Crate#1", before = A, idAfter = "Crate#1", after = B },
		{ name = "Lamp", idBefore = "Lamp#1", before = B, idAfter = "Lamp#1", after = C },
	})
	local ask = h.undo()
	ok(ask ~= nil and ask.id == "Crate#1" and ask.to == A, "a group undo asks for the first")
	local more = if ask then ask.more else nil
	ok(more ~= nil and #more == 1 and more[1].id == "Lamp#1" and more[1].to == B, "and the rest")
	h.answered(true, "Crate#1", { "Lamp#1" })
	ok(h.canRedo() and not h.canUndo(), "the whole group is one step")
	local again = h.redo()
	ok(
		again ~= nil and again.to == B and again.more ~= nil and again.more[1].to == C,
		"redone as one"
	)
	h.answered(true, "Crate#1", { "Lamp#1" })
end
do
	local h = fresh()
	h.recordGroup({
		{ name = "Crate", idBefore = "Crate#1", before = A },
		{ name = "Lamp", idBefore = "Lamp#1", before = B },
	})
	local ask = h.undo()
	ok(
		ask ~= nil and ask.id == nil and ask.name == "Crate" and ask.to == A,
		"a group put away undone sets out by name"
	)
	ok(
		ask ~= nil and ask.more ~= nil and ask.more[1].id == nil and ask.more[1].name == "Lamp",
		"every one of it"
	)
	h.answered(true, "Crate#4", { "Lamp#2" })
	local redo = h.redo()
	ok(redo ~= nil and redo.id == "Crate#4" and redo.to == nil, "redone, it puts away the new ids")
	ok(redo ~= nil and redo.more ~= nil and redo.more[1].id == "Lamp#2", "each followed")
	h.answered(false)
	ok(
		not h.canUndo() and not h.canRedo() and not h.waiting(),
		"a refused group drops its one step"
	)
end
do
	local h = fresh()
	h.recordGroup({})
	ok(not h.canUndo(), "an empty group is no step")
end

print(string.format("history: %d checks, %d failed", checks, failures))
if failures > 0 then
	error("history spec failed")
end
