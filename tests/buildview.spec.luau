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

print(`buildview: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
