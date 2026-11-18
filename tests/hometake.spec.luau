--!strict
-- lune run tests/hometake.spec
-- Taking a find from where it stands in your home (S5-03i2a, D-350): off a cubby of your shelf or
-- from where it's set out, straight into your hands. Nothing is ever lost or doubled: what you own
-- never changes, the find goes from its spot into the box's count and straight out of it into your
-- hand in the same step, and a press on a spot that doesn't hold it does nothing.
local Brix = require("../vendor/brix/src")
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

-- Off the shelf: the cubby empties, the find is one more in the box until the hand takes it.
do
	local data = Save.fresh()
	data.finds.Teddy = 2
	data.finds.Boombox = 1
	data.shelf = {
		{ find = "Teddy", fresh = Save.Fresh.Kind },
		{ find = "", fresh = Save.Fresh.Seen },
		{ find = "Boombox", fresh = Save.Fresh.Seen },
	}
	local before = Save.boxed(data, {})
	ok(before.Teddy == 1 and before.Boombox == nil, "one teddy in the box, the boombox shelved")
	ok(not Save.unshelf(data, 1, "Boombox"), "a cubby is never emptied of a find it doesn't hold")
	ok(not Save.unshelf(data, 2, "Teddy"), "an empty cubby gives nothing")
	ok(not Save.unshelf(data, 9, "Teddy"), "a cubby past the shelf gives nothing")
	ok(not Save.unshelf(data, 0, "Teddy"), "nor one before it")
	ok(not Save.unshelf(data, 1, ""), "nor a blank name")
	ok(data.shelf[1].find == "Teddy", "refused: the teddy still stands")
	ok(Save.unshelf(data, 1, "Teddy"), "the teddy comes off its cubby")
	ok(data.shelf[1].find == "" and data.shelf[1].fresh == Save.Fresh.Seen, "its cubby empty")
	ok(data.finds.Teddy == 2 and data.finds.Boombox == 1, "what you own never changes")
	local freed = Save.boxed(data, {})
	ok(freed.Teddy == 2, "off the shelf, it's in the box's count")
	-- the same step puts it in your hand (Slots:unbox), so it's out of the box again
	local held = Save.boxed(data, { Teddy = 1 })
	ok(held.Teddy == 1, "in your hand: the box holds what it held before")
	ok(not Save.unshelf(data, 1, "Teddy"), "a second press on the same cubby gives nothing")
	ok(Save.boxed(data, { Teddy = 1 }).Teddy == 1, "so nothing is doubled")
	-- a Gold stands as its own name and comes off as it
	data.finds["Teddy:Gold"] = 1
	data.shelf[2] = { find = "Teddy:Gold", fresh = Save.Fresh.Seen }
	ok(not Save.unshelf(data, 2, "Teddy"), "a Gold's cubby gives no plain teddy")
	ok(Save.unshelf(data, 2, "Teddy:Gold"), "the Gold comes off as itself")
	ok(Save.boxed(data, {})["Teddy:Gold"] == 1, "and is in the box's count")
end

-- From where it's set out: only a find (not furniture, not the home's own pieces), and whatever
-- stands on it goes back in the box with it, as a put-away does.
do
	ok(Spots.takeable("Teddy#1") == "Teddy", "a teddy set out can be taken")
	ok(Spots.takeable("Teddy:Gold#3") == "Teddy:Gold", "a Gold set out can be taken")
	ok(Spots.takeable("Pallet:Furniture#1") == nil, "furniture is never taken to hand")
	ok(Spots.takeable("Shelf:Furniture#1") == nil, "nor the shelf")
	ok(Spots.takeable("Floor") == nil, "an area names no find")

	local areas = { Floor = { kind = Spots.Kinds.Floor, width = 24, depth = 24 } }
	local function shapeOf(id: string): Brix.PlacementShape?
		local name = Spots.name(id)
		if not name then
			return nil
		end
		local piece = string.match(name, "^(.-):Furniture$")
		return Spots.shape(name, if piece then Spots.pieceBox(piece) else { 0.8, 1.6, 0.8 })
	end
	local set = Brix.Placements.new({ areas = areas, limit = 25 })
	local floor = { on = "Floor", x = 0, y = 0, turn = 0 }
	local palletId, lampId, teddyId = "Pallet:Furniture#1", "MoonLamp#1", "Teddy#1"
	set:place(palletId, shapeOf(palletId) :: any, floor)
	set:place(lampId, shapeOf(lampId) :: any, { on = palletId, x = 1, y = 0.5, turn = 0 })
	set:place(teddyId, shapeOf(teddyId) :: any, { on = "Floor", x = 6, y = 6, turn = 0 })

	local data = Save.fresh()
	data.furniture = { Pallet = 1 }
	data.finds = { MoonLamp = 1, Teddy = 1 }
	data.placed = { form = 1, rows = set:save().rows :: any }
	ok(Save.boxed(data, {}).Teddy == nil, "the teddy set out is out of the box")

	ok(Spots.lift(set, "Teddy#2") == nil, "a find not set out gives nothing")
	local gone = Spots.lift(set, teddyId)
	ok(gone ~= nil and #gone == 1 and gone[1] == teddyId, "the teddy lifted off the floor")
	ok(set:poseOf(teddyId) == nil and set:count() == 2, "only the teddy went")
	ok(Spots.lift(set, teddyId) == nil, "a second press gives nothing")
	data.placed = { form = 1, rows = set:save().rows :: any }
	ok(Save.boxed(data, {}).Teddy == 1, "lifted: in the box's count")
	ok(Save.boxed(data, { Teddy = 1 }).Teddy == nil, "in your hand: out of it again, once")
	ok(data.finds.Teddy == 1, "still owned, never doubled")

	-- whatever stands on it goes back in the box first, never lost
	local carried = Spots.lift(set, palletId)
	ok(
		carried ~= nil and #carried == 2 and carried[1] == lampId and carried[2] == palletId,
		"the lamp riding on it goes first, then the pallet"
	)
	ok(set:count() == 0, "nothing left standing")
	data.placed = { form = 1, rows = set:save().rows :: any }
	ok(Save.boxed(data, {}).MoonLamp == 1, "the lamp that rode on it is back in the box")
end

print(`hometake: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
