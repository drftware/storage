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

-- eyeBox: over the room, inside its walls, and out through the door (D-443)
local eb = BuildView.eyeBox(4, 3.875, 0.6, 5)
ok(near(eb.left, -3.4) and near(eb.right, 3.4), "across: the room's width, a gap inside each wall")
ok(
	near(eb.front, -8.875) and near(eb.back, 3.275),
	"deep: out the door to the hall's reach, a gap short of the back"
)
local tiny = BuildView.eyeBox(0.4, 0.4, 0.6, 5)
ok(
	tiny.left == 0 and tiny.right == 0 and tiny.back == 0,
	"a room narrower than the gap: the middle line"
)

-- fade: out past a wall, and close inside it while over the room
ok(
	BuildView.fade(-3, false, 0.6, 1.2) == 0 and BuildView.fade(1.2, false, 0.6, 1.2) == 1,
	"outside: none on the room's side, gone at depth"
)
ok(near(BuildView.fade(0.6, false, 0.6, 1.2), 0.5), "outside: halfway at half depth")
ok(
	near(BuildView.fade(-0.6, true, 0.6, 1.2), 1),
	"over the room: gone once the eye is within the gap"
)
ok(
	BuildView.fade(-1.8, true, 0.6, 1.2) == 0 and near(BuildView.fade(-1.2, true, 0.6, 1.2), 0.5),
	"over the room: fades in over depth before the gap"
)

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

-- runs: the ends of a wall past the room's corners (S5-03j1d2): a smaller home's walls run the
-- XL's whole length (D-354), and those ends are masked so the room ends at its corners
local room = { left = -5, right = 5, front = -6, back = 7 }
local side = BuildView.runs(room, { left = 4, right = 5, front = -6, back = 15 }, 0.25)
ok(
	#side == 1
		and near(side[1].left, 4)
		and near(side[1].right, 5)
		and near(side[1].front, 7)
		and near(side[1].back, 15),
	"a side wall's run behind the back wall"
)
local backRuns = BuildView.runs(room, { left = -10, right = 10, front = 6, back = 7 }, 0.25)
ok(#backRuns == 2, "the back wall runs on past both side walls")
ok(
	near(backRuns[1].left, -10) and near(backRuns[1].right, -5) and near(backRuns[2].left, 5),
	"each run from the corner to the wall's end"
)
ok(
	#BuildView.runs(room, { left = -5, right = 5, front = 6, back = 7 }, 0.25) == 0,
	"a wall within the corners: none"
)
ok(
	#BuildView.runs(room, { left = 4, right = 5.2, front = -6, back = 7 }, 0.25) == 0,
	"a hair past (a trim's lip): none"
)

-- fit: the home view stands as near as the whole room fits the clear band (S5-03j1d2)
local A16 = {
	width = 685,
	tall = 338,
	tanHalf = math.tan(math.rad(35)),
	top = 58,
	bottom = 186,
	roof = 0,
	edge = 6,
}
local small, smallAim = BuildView.fit(4.4, 6, 1, 4, 4, 0.6, 0.95, A16)
local large = BuildView.fit(8, 11, 1, 4, 4, 0.6, 0.95, A16)
ok(small > 5 and large > small, "a bigger room stands the eye further back")
ok(
	smallAim > 122 and smallAim < 186,
	"what stands on the floor rises above it: the focus shows lower"
)
local tall =
	{ width = 685, tall = 338, tanHalf = A16.tanHalf, top = 20, bottom = 318, roof = 0, edge = 6 }
ok((BuildView.fit(4.4, 6, 1, 4, 4, 0.6, 0.95, tall)) < small, "a taller band lets it come nearer")
-- straight down on a flat floor, the band mid-screen: the floor's edges touch the band's
local flat =
	{ width = 2000, tall = 400, tanHalf = 0.5, top = 100, bottom = 300, roof = 0, edge = 0 }
local roofed =
	{ width = 685, tall = 338, tanHalf = A16.tanHalf, top = 58, bottom = 186, roof = 40, edge = 6 }
ok(
	(BuildView.fit(4.4, 6, 1, 4, 10, 0.6, 0.95, roofed)) > small,
	"tall walls kept under the roof stand the eye further back"
)
local d, at = BuildView.fit(5, 5, 1, 0, 0, 0, math.pi / 2, flat)
ok(math.abs(d - 19) < 1e-3 and math.abs(at - 200) < 1e-3, `straight down: {d} {at}`)

print(`buildview: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
