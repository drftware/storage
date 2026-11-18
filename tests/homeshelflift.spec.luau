--!strict
-- lune run tests/homeshelflift.spec
-- Lifting a find out of your shelf in Arrange (S5-03i2b, D-352): a tap on a cubby's find picks the
-- find, not its shelf (`Shelf.hit`: the ray against the find's box, since cubby finds stand
-- unpickable), and setting it down moves it off its spot onto a placed row in one step
-- (`Spots.offShelf`). Never lost or doubled: what you own never changes, it's in the box's count
-- only while the place is judged, and a refused place puts it back in its cubby as it stood.
local Save = require("../src/shared/Save")
local Shelf = require("../src/shared/Home/Shelf")
local Spots = require("../src/shared/Home/Spots")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function near(a: number?, b: number): boolean
	return a ~= nil and math.abs(a - b) < 1e-6
end

-- The pick: a ray from the camera against a find's box, in the box's own frame.
do
	local half = { 0.5, 0.75, 0.5 } -- a teddy-sized box, its middle at the origin
	ok(near(Shelf.hit({ 0, 0, -10 }, { 0, 0, 1 }, half), 9.5), "straight on, met at its front face")
	ok(near(Shelf.hit({ 0.4, 0.7, -10 }, { 0, 0, 1 }, half), 9.5), "near its corner still counts")
	ok(Shelf.hit({ 0.6, 0, -10 }, { 0, 0, 1 }, half) == nil, "just past its side misses")
	ok(Shelf.hit({ 0, 0.8, -10 }, { 0, 0, 1 }, half) == nil, "just over its top misses")
	ok(Shelf.hit({ 0, 0, 10 }, { 0, 0, 1 }, half) == nil, "a box behind the camera is never met")
	ok(near(Shelf.hit({ 0, 0, 0 }, { 0, 0, 1 }, half), 0), "a ray from inside meets it at once")
	local s = math.sqrt(0.5)
	local slant = Shelf.hit({ -10, 0, -10 }, { s, 0, s }, half)
	ok(near(slant, (10 - 0.5) / s), "a slanted ray meets the nearer face")
	ok(Shelf.hit({ -10, 0, -12 }, { s, 0, s }, half) == nil, "and a slanted ray beside it misses")
	-- the screen picks the nearer: a find whose box is met before the shelf's board wins
	local find = Shelf.hit({ 0, 0, -10 }, { 0, 0, 1 }, half) :: number
	ok(find < 10.6, "the teddy is met before the cubby's back board behind it")
end

-- Set out from its cubby: off the spot and onto a placed row in one step.
local function shelved(): Save.Data
	local data = Save.fresh()
	data.finds.Teddy = 2
	data.finds.Boombox = 1
	data.shelf = {
		{ find = "Teddy", fresh = Save.Fresh.Kind },
		{ find = "", fresh = Save.Fresh.Seen },
		{ find = "Boombox", fresh = Save.Fresh.Seen },
	}
	return data
end

do
	local data = shelved()
	ok(Save.boxed(data, {}).Teddy == 1, "one teddy in the box, one on the shelf")
	local inBox = 0
	local id, refusal = Spots.offShelf(data, 1, "Teddy", function(): (string, string)
		-- the place is judged as a find from the box's: it counts there while it's judged
		inBox = Save.boxed(data, {}).Teddy or 0
		table.insert(data.placed.rows, { id = "Teddy#1", on = "Floor", x = 0, y = 0, turn = 0 })
		return "Teddy#1", ""
	end)
	ok(inBox == 2, "while it's judged, both teddies count in the box")
	ok(id == "Teddy#1" and refusal == "", "it stands as Teddy#1")
	ok(data.shelf[1].find == "", "its cubby is empty")
	ok(data.finds.Teddy == 2 and data.finds.Boombox == 1, "what you own never changes")
	ok(Save.boxed(data, {}).Teddy == 1, "the box still holds the other teddy: nothing doubled")
	ok(Save.placedCounts(data).Teddy == 1, "one teddy set out")
	ok(data.shelf[3].find == "Boombox", "the boombox's cubby is untouched")
	local again, why = Spots.offShelf(data, 1, "Teddy", function(): (string, string)
		error("never asked: the cubby is empty")
	end)
	ok(again == "" and why == Spots.Refusals.NotShelved, "a second lift from the empty cubby fails")
	ok(Save.placedCounts(data).Teddy == 1, "and sets out nothing more")
end

-- Refused (no room, a wall, the limit): back in its cubby as it stood, still new.
do
	local data = shelved()
	local id, refusal = Spots.offShelf(data, 1, "Teddy", function(): (string, string)
		return "", "full"
	end)
	ok(id == "" and refusal == "full", "the refusal comes back as it was")
	ok(data.shelf[1].find == "Teddy", "the teddy is back on its spot")
	ok(data.shelf[1].fresh == Save.Fresh.Kind, "still marked a kind you'd never owned")
	ok(Save.boxed(data, {}).Teddy == 1, "the box holds what it held")
	ok(Save.placedCounts(data).Teddy == nil, "nothing set out")
	local _, blank = Spots.offShelf(data, 1, "Teddy", function(): (string, string)
		return "", ""
	end)
	ok(blank ~= "" and data.shelf[1].find == "Teddy", "a refusal without a reason still refuses")
end

-- A lift naming what the spot doesn't hold moves nothing.
do
	local data = shelved()
	local asked = false
	local function never(): (string, string)
		asked = true
		return "x", ""
	end
	ok(
		select(2, Spots.offShelf(data, 3, "Teddy", never)) == Spots.Refusals.NotShelved,
		"wrong find"
	)
	ok(
		select(2, Spots.offShelf(data, 2, "Teddy", never)) == Spots.Refusals.NotShelved,
		"empty spot"
	)
	ok(select(2, Spots.offShelf(data, 9, "Teddy", never)) == Spots.Refusals.NotShelved, "past it")
	ok(select(2, Spots.offShelf(data, 1, "", never)) == Spots.Refusals.NotShelved, "a blank name")
	ok(not asked, "the place is never judged")
	ok(data.shelf[1].find == "Teddy" and data.shelf[3].find == "Boombox", "every cubby as it was")
	-- a Gold comes off as itself only
	data.finds["Teddy:Gold"] = 1
	data.shelf[2] = { find = "Teddy:Gold", fresh = Save.Fresh.Seen }
	ok(select(2, Spots.offShelf(data, 2, "Teddy", never)) == Spots.Refusals.NotShelved, "no plain")
	local gid = Spots.offShelf(data, 2, "Teddy:Gold", function(): (string, string)
		return "Teddy:Gold#1", ""
	end)
	ok(gid == "Teddy:Gold#1" and data.shelf[2].find == "", "the Gold comes off as itself")
end

-- The spot a lift names: a whole number on the shelf, nothing else; a put-away's name a find's.
do
	ok(Spots.askName("Teddy") == "Teddy" and Spots.askName("Teddy:Gold") == "Teddy:Gold", "finds")
	ok(Spots.askName("Teddy#1") == nil, "never an id set out")
	ok(Spots.askName("") == nil and Spots.askName(7) == nil, "never blank or a number")
	ok(Spots.askName(string.rep("a", 81)) == nil, "never a flood")
	ok(Shelf.spot(3, 12) == 3, "spot 3 of 12")
	ok(Shelf.spot(0, 12) == nil and Shelf.spot(13, 12) == nil, "off the shelf")
	ok(Shelf.spot(1.5, 12) == nil and Shelf.spot(0 / 0, 12) == nil, "a fraction or NaN")
	ok(Shelf.spot("1", 12) == nil, "a word")
end

print(`homeshelflift: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
