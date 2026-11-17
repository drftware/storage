--!strict
-- lune run tests/rail.spec
-- What you wear stands on your clothes rail (S5-03f2b, Home/Rail): the hard hat (and its Gold) goes
-- on the hat shelf, nothing else is worn; each kind you own gets a place on its row, in name
-- order; a hat kept at the gate goes to the rail, never the shelf, and one already on the shelf
-- comes off it.
local Rail = require("../src/shared/Home/Rail")
local Save = require("../src/shared/Save")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

ok(Rail.row("HardHat") == "Shelf", "the hard hat goes on the hat shelf")
ok(Rail.row("HardHat:Gold") == "Shelf", "so does its Gold")
ok(Rail.row("Teddy") == nil, "a teddy isn't worn")
ok(Rail.row("Skates") == nil, "the skates aren't worn yet")

local places = Rail.places({ Teddy = 3, HardHat = 2, ["HardHat:Gold"] = 1 })
ok(#places == 2, "a place for each kind worn, none for the teddy")
ok(places[1].name == "HardHat" and places[1].i == 1 and places[1].x == 0, "the hat in the middle")
ok(places[2].name == "HardHat:Gold" and places[2].i == 2, "its Gold beside it")
ok(#Rail.places({ HardHat = 0 }) == 0, "none owned, no place")
ok(Rail.height("Shelf", { Shelf = 5, Bar = 4, Rack = 1 }) == 5, "the hat shelf's height")

-- kept at the gate: a hat goes to the rail (in the box's count), a teddy to the shelf
local data = Save.fresh()
Save.keep(data, { "HardHat", "Teddy" }, 100, 6)
ok(data.finds.HardHat == 1, "the hat is owned")
ok(data.shelf[1] ~= nil and data.shelf[1].find == "Teddy", "the teddy takes the first spot")
ok(data.shelf[2] == nil or data.shelf[2].find == "", "the hat never goes on the shelf")
ok(Save.boxed(data, {}).HardHat == 1, "so it counts as in the box, standing on the rail")
ok(Save.boxed(data, { HardHat = 1 }).HardHat == nil, "worn from the box, it's off the rail")

-- an old save's hat on the shelf comes off it onto the rail
local old = Save.fresh()
old.finds.HardHat = 1
old.finds.Teddy = 1
old.shelf = { { find = "HardHat", fresh = Save.Fresh.New }, { find = "Teddy", fresh = 0 } }
ok(Save.unshelve(old) == 1, "one worn find lifted off the shelf")
ok(old.shelf[1].find == "" and old.shelf[2].find == "Teddy", "the teddy stays")
ok(Save.boxed(old, {}).HardHat == 1, "the hat's in the box, on the rail")
ok(Save.unshelve(old) == 0, "nothing more to lift")

print(`rail: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
