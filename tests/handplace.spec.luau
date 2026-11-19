--!strict
-- lune run tests/handplace.spec
-- Placing a held find where you look in your own home (S5-03j5a, D-463): the ask is checked before
-- anything reads it, the judge's word decides, and a find set down from your hand goes from your
-- hand onto its spot in one step: what you own never changes, it's never in your hand and set out
-- at once, and a refused ask leaves it in your hand.
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

print(`handplace: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
