--!strict
-- lune run tests/buildview.spec
-- The build camera's sums (S5-03j1a, Home/BuildView, D-439): the eye pulled in along its line of
-- sight to stay in the slot, never past the focus, and smoothly; each piece of the home sorted to
-- the wall it belongs to, the room's own things to none.
local BuildView = require("../src/shared/Home/BuildView")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

local slot: BuildView.Box = { left = -9.4, right = 9.4, front = -10, back = 23 }

-- keepIn
ok(BuildView.keepIn(2, -3, 0, 0, slot) == 1, "an eye inside the box stays where it is")
ok(near(BuildView.keepIn(20, 0, 0, 0, slot), 9.4 / 20), "past the side: pulled in to the side")
ok(near(BuildView.keepIn(0, -20, 0, 0, slot), 10 / 20), "out into the hall: pulled to its edge")
ok(near(BuildView.keepIn(-18.8, 46, 0, 0, slot), 0.5), "past two sides: the nearer crossing wins")
ok(
	near(BuildView.keepIn(14, 0, 12, 0, slot), 1),
	"a focus pushed past the box keeps its eye beyond it"
)
ok(BuildView.keepIn(0, 0, 0, 0, slot) == 1, "an eye on the focus stays")
local last = 1
local smooth = true
for i = 0, 200 do
	local share = BuildView.keepIn(5 + i * 0.1, -2, 0, 0, slot)
	if share > last + 1e-12 or last - share > 0.02 then
		smooth = false
	end
	last = share
end
ok(smooth, "the share falls a little at a time as the eye goes out, never jumping")

-- sideOf: a Medium room, 12 across and 11.75 deep (half 6 and 5.875)
local function side(minX: number, maxX: number, minZ: number, maxZ: number): string
	return BuildView.sideOf(minX, maxX, minZ, maxZ, 6, 5.875, 0.3, 1.75) or "none"
end
ok(side(5.9, 6.9, -5.8, 23.7) == "left", "the left wall's steel, running on behind the back")
ok(side(-6.9, -5.9, -5.8, 23.7) == "right", "the right wall's steel")
ok(side(-9.9, 9.9, 5.8, 6.8) == "back", "the back wall, as wide as the slot")
ok(side(-6, 6, -6.15, -5.85) == "front", "the front wall's face")
ok(side(-4.4, 4.4, -5.7, -4.3) == "front", "the door's coil, hanging inside the door's wall")
ok(side(-9.9, 9.9, -5.8, 23.8) == "none", "the floor's panel, under every wall")
ok(side(-1.1, 1.1, -1.2, 1.0) == "none", "the lamp in the middle")
ok(side(-5.6, -4.6, 3, 4) == "none", "a shelf standing a little off the right wall")
ok(side(5.5, 6.0, 5.6, 6.2) == "back", "a corner piece goes with the wall it's furthest past")

-- homeView: the eye clears the near walls (S5-03j1b): a front corner where the slot has room
-- beside the home, else from the hall through the door at a slant.
do
	local clear, slant = 1.3, 0.4
	-- a Small home (8 by 7.75) in its XL slot (20 by 29.75): the room and slot share the door's line
	local box: BuildView.Box = { left = -9.4, right = 9.4, front = -8.875, back = 25.3 }
	local a, r = BuildView.homeView(4, 3.875, clear, box, 1, slant)
	local x, z = r * math.sin(a), -r * math.cos(a)
	ok(
		a > 0 and near(x, 4 + clear) and near(z, -(3.875 + clear)),
		"a Small home: its left front corner"
	)
	local a2 = BuildView.homeView(4, 3.875, clear, box, -1, slant)
	ok(near(a2, -a), "the right front corner on the right side")
	-- an XL home is its slot: no room beside it, so in from the hall at the slant
	local xl: BuildView.Box = { left = -9.4, right = 9.4, front = -19.875, back = 14.275 }
	local a3, r3 = BuildView.homeView(10, 14.875, clear, xl, 1, slant)
	ok(near(a3, slant), "an XL home: from the door at the slant")
	ok(near(r3 * math.cos(a3), 14.875 + clear), "just past the door's wall")
	ok(r3 * math.sin(a3) <= 9.4, "and inside the slot's side")
	-- a narrow hall: the slant shrinks so the eye stays in the slot
	local tight: BuildView.Box = { left = -3, right = 3, front = -19.875, back = 14.275 }
	local a4, r4 = BuildView.homeView(10, 14.875, clear, tight, 1, slant)
	ok(a4 < slant and r4 * math.sin(a4) <= 3 + 1e-9, "a tight slot keeps the eye in it")
	-- a hall too short to clear the door's wall: as far out as the slot goes
	local short: BuildView.Box = { left = -9.4, right = 9.4, front = -15.5, back = 14.275 }
	local a5, r5 = BuildView.homeView(10, 14.875, clear, short, 1, slant)
	ok(near(r5 * math.cos(a5), 15.5), "no further out than the hall allows")
end

print(`buildview: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
