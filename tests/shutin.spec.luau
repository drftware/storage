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

-- light: how much of the hall's light reaches someone shut in, as the door lifts
local OPEN = 7.65 -- size M's open rise
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end
ok(near(ShutIn.light(0, OPEN), ShutIn.Dark), "a shut door lets in only the dark level")
ok(
	ShutIn.Dark > 0 and ShutIn.Dark < 0.15,
	"shut in is dark, but the door's slats still faintly show"
)
ok(near(ShutIn.light(OPEN, OPEN), 1), "a fully open door lets in all the hall's light")
ok(
	near(ShutIn.light(OPEN + 0.4, OPEN), 1),
	"a door bouncing past open lets in no more than all of it"
)
ok(near(ShutIn.light(-0.1, OPEN), ShutIn.Dark), "a door pressed below shut is still just dark")
local peek = ShutIn.light(1.15, OPEN)
ok(peek > 0.4 and peek < 0.6, "a friend's peek floods in about half the light, not all of it")
local rising = true
local last = ShutIn.light(0, OPEN)
for i = 1, 40 do
	local now = ShutIn.light(OPEN * i / 40, OPEN)
	rising = rising and now >= last
	last = now
end
ok(rising, "the light only grows as the door lifts")
ok(near(ShutIn.light(1, 0), 1), "a door with no open rise never darkens anything")

-- the unit's bulb, wired to the door like a fridge's light
local PEEK = 1.15
ok(not ShutIn.bulb(0, 0, false), "a shut door's bulb is out")
ok(not ShutIn.bulb(OPEN, 0, false), "an open about to start is still dark on its first frame")
ok(ShutIn.bulb(OPEN, 0.3, false), "the bulb comes on as the door starts up")
ok(ShutIn.bulb(PEEK, 0.3, false), "a peek lights it too, so a little spills out under the door")
ok(ShutIn.bulb(OPEN, OPEN, false), "a door held open has its bulb on")
ok(ShutIn.bulb(OPEN, PEEK, true), "opening from a peek keeps it on")
ok(ShutIn.bulb(0, 3, true), "a closing door's bulb burns until the door lands")
ok(not ShutIn.bulb(0, 0, true), "it goes out the frame the door lands")
ok(not ShutIn.bulb(0, 0.3, false), "and stays out as a slam bounces back up")
ok(not ShutIn.bulb(0, 0.12, false), "a padlocked door's rattle never lights it")
-- a whole slam from open, sampled as the client does: on until the bang, then out through the bounce
local Motion = require("../src/shared/StorageUnit/Motion")
local on, wentOut, relit = true, false, false
for i = 0, 60 do
	local rise = Motion.sample("Slam", OPEN, 0, i / 100, OPEN)
	local now = ShutIn.bulb(0, rise, on)
	if on and not now then
		wentOut = true
		ok(rise <= ShutIn.BulbOffRise, "the slam's bulb goes out only as the door lands")
	elseif now and not on then
		relit = true
	end
	on = now
end
ok(wentOut and not relit and not on, "a slam's bulb goes out on the bang and stays out")

print(string.format("shutin: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("shutin spec failed")
end
