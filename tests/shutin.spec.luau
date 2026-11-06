--!strict
-- lune run tests/shutin.spec
local ShutIn = require("../src/shared/StorageUnit/ShutIn")

-- Size M's numbers (src/shared/StorageUnit/Specs/M.luau).
local M = { Width = 12, Depth = 12, WallHeight = 10, CurtainPlane = 0.55 }
local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- inside the room: behind the curtain, between the walls, under the wall tops
ok(ShutIn.inside(M, 0, 3, 1.2), "a player pressed to the door from inside is inside")
ok(ShutIn.inside(M, 5.5, 4.5, 11), "the back corner is inside")
ok(not ShutIn.inside(M, 0, 3, -1.2), "a player pressed to the door from the hall is outside")
ok(not ShutIn.inside(M, 0, 3, 0), "the curtain plane itself is outside")
ok(not ShutIn.inside(M, 7, 3, 4), "past the side wall is the neighbour's, not this room")
ok(not ShutIn.inside(M, 0, 3, 11.6), "behind the back wall is outside")
ok(not ShutIn.inside(M, 0, 12, 4), "above the wall tops is outside")
ok(not ShutIn.inside(M, 0, -3, 4), "the floor below is outside")

-- hides: shut and exactly one of the two inside
ok(ShutIn.hides(0, true, false), "shut door hides the one inside from the hall")
ok(ShutIn.hides(0, false, true), "and the hall from the one inside")
ok(not ShutIn.hides(0, true, true), "two people shut in together see each other")
ok(not ShutIn.hides(0, false, false), "two people in the hall see each other")
ok(not ShutIn.hides(1.15, true, false), "a peeked door shows them")
ok(not ShutIn.hides(ShutIn.MaxRise + 0.01, true, false), "a door just starting to lift shows them")
ok(ShutIn.hides(ShutIn.MaxRise, true, false), "a door within MaxRise still counts as shut")

print(string.format("shutin: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("shutin spec failed")
end
