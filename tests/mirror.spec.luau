--!strict
-- lune run tests/mirror.spec
-- The mirror's math (S5-03b): a point lands as far behind the glass as it stood in front; every
-- copy's rotation is a real one; you facing the glass are drawn facing back, your right hand on
-- your right; a wall keeps its faces; partners swap; the picture fits the glass from any eye.
local roblox = require("@lune/roblox")

local Mirror = require("../src/shared/Mirror")

local Vector3 = roblox.Vector3

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end
local function near(a: Vector3, b: Vector3): boolean
	return (a - b).Magnitude < 1e-6
end

local X, Y, Z = Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)

-- the glass stands at z = 0 facing +Z; you stand 5 in front of it
local c, n = Vector3.new(0, 3, 0), Z
ok(
	near(Mirror.point(Vector3.new(2, 4, 5), c, n), Vector3.new(2, 4, -5)),
	"a point lands behind the glass"
)
ok(
	near(Mirror.point(Vector3.new(1, 1, 0), c, n), Vector3.new(1, 1, 0)),
	"a point on the glass stays"
)

-- you face the glass (look -Z): your copy faces back out (+Z), turned about Y
do
	local x, y, z = Mirror.columns(X, Y, Z, n, X)
	ok(near(x, -X) and near(y, Y) and near(z, -Z), "your copy is you turned about Y")
	ok(near(x:Cross(y), z), "a real rotation")
end

-- any turn of any part, across any direction: still a real rotation (right-handed, unit, square)
do
	local seed = 7
	local function r(): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648 * 2 - 1
	end
	for _ = 1, 50 do
		local x = Vector3.new(r(), r(), r()).Unit
		local y = x:Cross(Vector3.new(r(), r(), r())).Unit
		local z = x:Cross(y)
		local a = Vector3.new(r(), r(), r()).Unit
		local m = Vector3.new(r(), r(), r()).Unit
		local x1, y1, z1 = Mirror.columns(x, y, z, m, a)
		ok(near(x1:Cross(y1), z1), "proper")
		ok(math.abs(x1.Magnitude - 1) < 1e-6 and math.abs(x1:Dot(y1)) < 1e-6, "unit and square")
	end
end

-- your right hand (+X of you, facing -Z) is reflected on your right as you see it: its copy is the
-- left hand (the partner), standing at the right hand's reflection, which is still at +X
ok(
	Mirror.partner("RightHand") == "LeftHand" and Mirror.partner("LeftUpperLeg") == "RightUpperLeg",
	"R15 partners"
)
ok(
	Mirror.partner("Right Arm") == "Left Arm" and Mirror.partner("Left Leg") == "Right Leg",
	"R6 partners"
)
ok(
	Mirror.partner("Head") == "Head" and Mirror.partner("UpperTorso") == "UpperTorso",
	"middle parts stay"
)
ok(
	Mirror.point(Vector3.new(1.5, 3, 5), c, n).X > 0,
	"the right hand's reflection stays on the right"
)

-- a wall across the room facing the glass (its face -Z toward it, long along X): turned along X,
-- its face comes out facing the glass (+Z), so you see its painted side, not its back
do
	local i = Mirror.axis(X, Y, Z, Vector3.new(20, 10, 0.5), Y)
	ok(i == 1, "the far wall turns along its length")
	local _, _, z = Mirror.columns(X, Y, Z, n, X)
	ok(near(-z, Z), "its face looks back at the glass")
	-- a side wall square to the glass (long along Z): turned along Z, it keeps facing the same way
	local j = Mirror.axis(X, Y, Z, Vector3.new(0.5, 10, 30), Y)
	ok(j == 3, "a side wall turns along its length")
	local x = Mirror.columns(X, Y, Z, n, Z)
	ok(near(x, X), "its face keeps its side")
	-- an imported mesh lying on its side (its Z up): the level axes are X and Y
	ok(Mirror.axis(X, Y, Z, Vector3.new(2, 6, 9), Z) == 2, "the upright axis is never picked")
end

-- the picture fits the glass (2 wide, 5 tall, seen from in front: its right is -X)
do
	local right, up = -X, Y
	local v = Mirror.view(Vector3.new(0, 3, 4), c, n, right, up, 2, 5)
	ok(v ~= nil, "seen from in front")
	if v then
		ok(math.abs(v.x) < 1e-9 and math.abs(v.y) < 1e-9, "dead ahead: centred")
		ok(
			math.abs(v.fov - math.deg(2 * math.atan(2.5 / 4))) < 1e-6,
			"dead ahead: just the glass tall"
		)
		ok(
			math.abs(v.width - 2) < 1e-9 and math.abs(v.height - 5) < 1e-9,
			"dead ahead: just the glass"
		)
	end
	-- step 3 to your right (-X) and stand tall (y 5): the picture's middle is ahead of you
	local w = Mirror.view(Vector3.new(-3, 5, 4), c, n, right, up, 2, 5)
	if w then
		ok(
			math.abs(w.x - 3) < 1e-9 and math.abs(w.y - 2) < 1e-9,
			"the picture's middle is in front of your eye"
		)
		ok(
			w.width >= 2 * (3 + 1) - 1e-9 and w.height >= 2 * (2 + 2.5) - 1e-9,
			"it still covers the glass"
		)
		ok(
			math.abs(math.tan(math.rad(w.fov) / 2) * 4 - w.height / 2) < 1e-9,
			"its scale is the glass's"
		)
	end
	ok(
		Mirror.view(Vector3.new(0, 3, -1), c, n, right, up, 2, 5) == nil,
		"behind the glass: nothing"
	)
	local close = Mirror.view(Vector3.new(0, 3, 0.2), c, n, right, up, 2, 5)
	ok(
		close ~= nil and (close :: Mirror.View).fov <= Mirror.MaxFov + 1e-9,
		"nose to the glass: capped"
	)
end

-- What of the room may be copied (S5-03b seen): a copy reaching out in front of the glass hides
-- the whole picture, as the lobby's merged walls did. Glass at z = 0 facing +Z, 2.4 by 5.6.
do
	local g: Mirror.Glass =
		{ c = Vector3.new(0, 3, 0), n = Z, right = X, up = Y, width = 2.4, height = 5.6 }
	local function keeps(at: Vector3, size: Vector3): boolean
		return Mirror.keeps(X, Y, Z, size, at, g, Y)
	end
	ok(keeps(Vector3.new(0, 3, 5), Vector3.new(2, 2, 2)), "keeps: a box wholly in front")
	ok(not keeps(Vector3.new(0, 3, -3), Vector3.new(2, 2, 2)), "keeps: not a box wholly behind")
	ok(
		not keeps(Vector3.new(0, 5, -0.5), Vector3.new(40, 10, 0.25)),
		"keeps: not the wall it leans on"
	)
	ok(
		not keeps(Vector3.new(0, 5, 10), Vector3.new(30, 10, 40)),
		"keeps: not a merged mesh through it"
	)
	ok(keeps(Vector3.new(0, 0, 0), Vector3.new(40, 0.2, 40)), "keeps: a floor through it")
	ok(keeps(Vector3.new(0, 10, 0), Vector3.new(40, 0.2, 40)), "keeps: a ceiling through it")
	ok(
		keeps(Vector3.new(15, 5, 3), Vector3.new(0.25, 10, 8)),
		"keeps: a wall through it, off to the side"
	)
	ok(
		not keeps(Vector3.new(1.5, 3, 0), Vector3.new(1, 1, 1)),
		"keeps: not a box poking through beside it"
	)
end

-- the picture sharpens as you come up to the glass, in steps, between its two bounds
ok(Mirror.sharpness(10) == Mirror.PixelsPerStud, "sharpness: far off, the plain picture")
ok(Mirror.sharpness(2) == 128, "sharpness: 2 studs off, 128")
ok(Mirror.sharpness(2.5) == 96, "sharpness: 2.5 studs off, 96")
ok(Mirror.sharpness(0.2) == Mirror.PixelsPerStudMax, "sharpness: right up close, the most")

print(`mirror: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
