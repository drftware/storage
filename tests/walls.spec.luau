--!strict
-- lune run tests/walls.spec
-- The walls drawn by size (S5-03h5, D-354): a smaller home's partitions and back wall stand in
-- from the XL slot's by just what the size is smaller, so the room between them is the size's
-- own box (`Sizes.inside`); the ceiling's lamp stays in the room's middle; the floor and the
-- front wall never move; XL's walls are the slot's own.
local Sizes = require("../src/shared/Home/Sizes")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- the slot's XL box as the lobby has it (its middle, its size), its front at z 0.29
local CENTRE, SIZE = { 0, 5, 0.29 + 29.585 / 2 }, { 19.75, 10, 29.585 }
-- the XL walls' inner faces in the unit's frame
local LEFT, RIGHT, BACK = 19.75 / 2, -19.75 / 2, 0.29 + 29.585

for _, size in Sizes.List do
	local c, box = Sizes.inside(size.name, CENTRE, SIZE)
	local l = Sizes.onWall(size.name, "Left", { LEFT, 5, 15 })
	local r = Sizes.onWall(size.name, "Right", { RIGHT, 5, 15 })
	local b = Sizes.onWall(size.name, "Back", { 0, 5, BACK })
	local n = size.name
	-- the walls stand where the size's box ends, so a wall's face is the room's edge
	ok(near(l[1], c[1] + box[1] / 2), `{n}: the left partition is the box's left edge`)
	ok(near(r[1], c[1] - box[1] / 2), `{n}: the right partition is the box's right edge`)
	ok(near(b[3], c[3] + box[3] / 2), `{n}: the back wall is the box's back edge`)
	-- a partition only moves across, the back wall only toward the door
	ok(near(l[3], 15) and near(r[3], 15) and near(l[2], 5), `{n}: the partitions slide across only`)
	ok(near(b[1], 0) and near(b[2], 5), `{n}: the back wall slides toward the door only`)
	-- the lamp stays halfway in (the XL lamp at the XL room's middle)
	local lamp = Sizes.onWall(n, "Middle", { 0, 9.92, CENTRE[3] })
	ok(near(lamp[3], c[3]) and near(lamp[1], 0), `{n}: the lamp hangs over the room's middle`)
	-- the floor and the front wall stay put
	local floor = Sizes.onWall(n, "Floor", { 1, 0, 2 })
	ok(floor[1] == 1 and floor[3] == 2, `{n}: the floor never moves`)
	-- the room the walls close is the size's across and deep, less the XL's 0.25 and 0.415
	ok(near(l[1] - r[1], size.across - 0.25), `{n}: {size.across} across between the partitions`)
	ok(near(b[3] - 0.29, size.deep - 0.415), `{n}: {size.deep} deep from the door`)
end

-- XL's walls are the slot's own: nothing moves
do
	local side, back = Sizes.inset("XL")
	ok(side == 0 and back == 0, "XL stands nothing in")
	local small, smallBack = Sizes.inset("Small")
	ok(small == 6 and smallBack == 22, "Small's partitions 6 in, its back wall 22 toward the door")
	local unknown = Sizes.inset("Huge")
	ok(unknown == small, "a name that isn't a size stands as Small")
end

-- each size bigger than the last, so a home only ever grows outward
for i = 2, #Sizes.List do
	local a, b = Sizes.List[i - 1].name, Sizes.List[i].name
	local sa, ba = Sizes.inset(a)
	local sb, bb = Sizes.inset(b)
	ok(sb < sa and bb < ba, `{b}'s walls stand further out than {a}'s`)
end

-- Small's doorway is the S door's 6 in the M's 8: each side a stud in; Medium and up the M's
do
	ok(Sizes.doorIn("Small") == 1, "Small's doorway stands a stud in each side")
	for _, name in { "Medium", "Large", "XL" } do
		ok(Sizes.doorIn(name) == 0, `{name} keeps the M's doorway`)
	end
	ok(Sizes.doorIn("Huge") == 1, "a name that isn't a size has Small's doorway")
	local side = Sizes.inset("Small")
	ok(
		Sizes.Door - 2 * Sizes.doorIn("Small") < 2 * (10 - side),
		"Small's doorway fits inside its room"
	)
end

print(`walls: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
