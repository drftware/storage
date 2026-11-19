--!strict
-- lune run tests/handplace.spec
-- Placing a held find where you look in your own home (S5-03j5a, D-463): the ask is checked before
-- anything reads it, the judge's word decides, and a find set down from your hand goes from your
-- hand onto its spot in one step: what you own never changes, it's never in your hand and set out
-- at once, and a refused ask leaves it in your hand.
local roblox = require("@lune/roblox")
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

local Brix = require("../vendor/brix/src")
local HandPlace = require("../src/shared/Home/HandPlace")
local Save = require("../src/shared/Save")
local Spots = require("../src/shared/Home/Spots")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- The ask: (on, x, y, turn), each checked for type and range; no find's name rides with it.
do
	local _, pose = Spots.ask("held", "Floor", 1.5, -2, 450)
	ok(pose ~= nil and pose.on == "Floor" and pose.x == 1.5 and pose.y == -2, "a fair ask reads")
	ok(pose ~= nil and pose.turn == 90, "its turn brought round under 360")
	ok(select(2, Spots.ask("held", 7, 0, 0, 0)) == nil, "an area that isn't a word is refused")
	ok(select(2, Spots.ask("held", "Floor", "1", 0, 0)) == nil, "a number sent as text is refused")
	ok(select(2, Spots.ask("held", "Floor", 0 / 0, 0, 0)) == nil, "not a number is refused")
	ok(select(2, Spots.ask("held", "Floor", 1e6, 0, 0)) == nil, "a spot miles off is refused")
	ok(select(2, Spots.ask("held", "Floor", 0, 0, nil)) == nil, "a missing turn is refused")
	ok(select(2, Spots.ask("held", string.rep("a", 200), 0, 0, 0)) == nil, "a long name is refused")
	ok(Spots.Refusals.Far ~= nil, "a spot out of reach has its own refusal")
	ok(HandPlace.Reach > 0 and HandPlace.Slack >= 0, "a reach, and the server's slack past it")
	ok(HandPlace.slotAttribute(1) ~= HandPlace.slotAttribute(2), "each slot its own mark")
end

-- The step: judged first; set out, it leaves the hand at once; refused, nothing changes.
do
	local areas = { Floor = { kind = Spots.Kinds.Floor, width = 12, depth = 12 } }
	local set = Brix.Placements.new({ areas = areas, limit = 25 })
	local function shapeOf(id: string): Brix.PlacementShape
		return Spots.shape(Spots.name(id) or id, { 0.8, 1.6, 0.8 })
	end
	local data = Save.fresh()
	data.finds = { Teddy = 2, ["Teddy:Gold"] = 1 }
	local hand: { [string]: number } = { Teddy = 1 } -- one teddy out of the box, in your hand
	local function owned(): number -- every teddy you own: in the box, set out, in your hand
		data.placed = { form = 1, rows = set:save().rows :: any }
		local boxed = Save.boxed(data, hand).Teddy or 0
		return boxed + Spots.setOut(data.placed.rows :: any) + (hand.Teddy or 0)
	end
	ok(owned() == 2, "two teddies: one in the box, one in your hand")

	-- the judge's word comes before anything changes
	local blocker = "Teddy#1"
	set:place(blocker, shapeOf(blocker), { on = "Floor", x = 0, y = 0, turn = 0 }) -- the box's one
	ok(owned() == 2, "the box's teddy set out by Arrange, the other still in your hand")
	local id = Spots.nextId("Teddy", function(each: string): boolean
		return set:poseOf(each) ~= nil
	end)
	ok(id == "Teddy#2", "the held teddy is checked as the next free id")
	local onTop = { on = "Floor", x = 0, y = 0, turn = 0 }
	ok(set:check(id, shapeOf(id), onTop) ~= nil, "where another stands, the judge says no")
	ok(set:poseOf(id) == nil and hand.Teddy == 1, "refused: still in your hand, nothing set out")

	local clear = { on = "Floor", x = 3, y = 3, turn = 0 }
	ok(set:place(id, shapeOf(id), clear) == nil, "a clear spot takes it")
	hand.Teddy = 0 -- Slots:setDown, in the same server step
	ok(owned() == 2, "set down: you own the same two, never doubled")
	ok((Save.boxed(data, hand).Teddy or 0) == 0, "and the box holds none: both set out")
	ok(Spots.setOut(data.placed.rows :: any) == 2, "two set out")

	-- a Gold goes down as itself
	local gold = Spots.nextId("Teddy:Gold", function(each: string): boolean
		return set:poseOf(each) ~= nil
	end)
	ok(Spots.name(gold) == "Teddy:Gold", "a held Gold stands as its own name")
end

-- The kept spot (S5-03j5b1, D-465): where a Taken find stood rides as text on its slot, read back
-- only when it's whole; a look near it snaps, a look beside it or behind a wall doesn't.
do
	local pose = { on = "JobBoxTop", x = 0.25, y = -1.5, turn = 90 }
	local back = HandPlace.decode(HandPlace.encode(pose))
	ok(
		back ~= nil and back.on == pose.on and back.x == 0.25 and back.y == -1.5 and back.turn == 90,
		"a kept spot reads back as it was written"
	)
	local onTop = HandPlace.decode(HandPlace.encode({ on = "Lamp#2", x = 0, y = 0, turn = 0 }))
	ok(onTop ~= nil and onTop.on == "Lamp#2", "a spot on a find's own top keeps its name")
	ok(HandPlace.decode(nil) == nil, "no spot kept: nothing")
	ok(HandPlace.decode(7) == nil, "a number isn't a spot")
	ok(HandPlace.decode("Floor|1|2") == nil, "a spot missing its turn isn't one")
	ok(HandPlace.decode("Floor|x|2|0") == nil, "a spot with a word for a number isn't one")
	ok(HandPlace.decode("Floor|nan|2|0") == nil, "not a number isn't one")
	ok(HandPlace.decode("Floor|1e9|2|0") == nil, "a spot miles off isn't one")
	ok(HandPlace.decode(string.rep("a", 200)) == nil, "a long text isn't one")
	ok(HandPlace.keptAttribute(1) ~= HandPlace.slotAttribute(1), "the kept spot has its own mark")
	ok(HandPlace.keptAttribute(1) ~= HandPlace.keptAttribute(2), "each slot its own kept spot")
	ok(HandPlace.KeptFaint > HandPlace.Faint, "the kept copy is fainter than where you look")

	local eye = Vector3.new(0, 5, 0)
	local ahead = Vector3.new(0, 0, -1)
	local spot = Vector3.new(0, 5, -6)
	ok(HandPlace.snaps(eye, ahead, 20, spot), "a look straight at it snaps")
	ok(
		HandPlace.snaps(eye, ahead, 20, spot + Vector3.new(HandPlace.Snap * 0.9, 0, 0)),
		"a look within a step of it snaps"
	)
	ok(
		not HandPlace.snaps(eye, ahead, 20, spot + Vector3.new(HandPlace.Snap * 1.5, 0, 0)),
		"a look beside it doesn't"
	)
	ok(not HandPlace.snaps(eye, -ahead, 20, spot), "a look away from it doesn't")
	ok(not HandPlace.snaps(eye, ahead, 2, spot), "behind what you see, it doesn't")
	ok(HandPlace.snaps(eye, ahead, 5, spot), "just past what you see (its own top), it does")

	local face = CFrame.new(10, 0, 10)
	local middle, size = Vector3.new(0, 4, 0), Vector3.new(12, 8, 10)
	ok(HandPlace.inside(face, middle, size, Vector3.new(12, 3, 8)), "standing in the room: in")
	ok(not HandPlace.inside(face, middle, size, Vector3.new(17, 3, 10)), "out the door: out")
	ok(not HandPlace.inside(face, middle, size, Vector3.new(10, 20, 10)), "on the floor above: out")
end

print(`handplace: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
