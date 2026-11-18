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

-- The walls grinding back (S5-03h6, D-356): part way between two sizes they stand part way
-- between, each wall only ever moving outward as the slide goes on
do
	for i = 1, #Sizes.List - 1 do
		for j = i + 1, #Sizes.List do
			local a, b = Sizes.List[i].name, Sizes.List[j].name
			local sa, ba = Sizes.inset(a)
			local sb, bb = Sizes.inset(b)
			local s0, b0, d0 = Sizes.between(a, b, 0)
			local s1, b1, d1 = Sizes.between(a, b, 1)
			ok(near(s0, sa) and near(b0, ba), `{a} to {b}: the slide starts at {a}'s walls`)
			ok(near(s1, sb) and near(b1, bb), `{a} to {b}: the slide ends at {b}'s walls`)
			ok(
				near(d0, Sizes.doorIn(a)) and near(d1, Sizes.doorIn(b)),
				`{a} to {b}: the doorway too`
			)
			local sh, bh = Sizes.between(a, b, 0.5)
			ok(near(sh, (sa + sb) / 2) and near(bh, (ba + bb) / 2), `{a} to {b}: halfway, halfway`)
			local lastSide, lastBack, lastDoor = math.huge, math.huge, math.huge
			local outward = true
			for n = 0, 20 do
				local s, bk, d = Sizes.between(a, b, Sizes.slide(n / 20))
				outward = outward and s <= lastSide + 1e-9 and bk <= lastBack + 1e-9
				outward = outward and d <= lastDoor + 1e-9
				lastSide, lastBack, lastDoor = s, bk, d
			end
			ok(outward, `{a} to {b}: the walls and the doorway only ever open outward`)
		end
	end
	local s, b = Sizes.between("Small", "Medium", 2)
	local sm, bm = Sizes.inset("Medium")
	ok(near(s, sm) and near(b, bm), "past the end of the slide the walls stand at the new size")
	-- a wall part way: the partition's place is the blend's, the floor still never moves
	local side, back = Sizes.between("Small", "Large", 0.25)
	local l = Sizes.onInset(side, back, "Left", { LEFT, 5, 15 })
	ok(near(l[1], LEFT - side) and near(l[3], 15), "a partition part way stands at the blend")
	local f = Sizes.onInset(side, back, "Floor", { 1, 0, 2 })
	ok(f[1] == 1 and f[3] == 2, "the floor never moves part way either")
	for _, size in Sizes.List do
		local si, bi = Sizes.inset(size.name)
		local w = Sizes.onWall(size.name, "Back", { 0, 5, BACK })
		ok(
			near(w[3], Sizes.onInset(si, bi, "Back", { 0, 5, BACK })[3]),
			`{size.name}: onWall is onInset`
		)
	end
end

-- The slide: still at both ends, fastest halfway, always moving on
do
	ok(Sizes.slide(0) == 0 and Sizes.slide(1) == 1, "the slide runs from none to all")
	ok(near(Sizes.slide(0.5), 0.5), "halfway in time is halfway along")
	ok(Sizes.slide(-1) == 0 and Sizes.slide(2) == 1, "the slide never runs past either end")
	local rising = true
	for n = 1, 40 do
		rising = rising and Sizes.slide(n / 40) >= Sizes.slide((n - 1) / 40)
	end
	ok(rising, "the slide never runs backward")
	ok(Sizes.slideSpeed(0) == 0 and near(Sizes.slideSpeed(1), 0), "standing at both ends")
	ok(near(Sizes.slideSpeed(0.5), 1), "fastest halfway")
	ok(Sizes.slideSpeed(0.25) < 1 and Sizes.slideSpeed(0.25) > 0, "getting going a quarter in")
end

print(`walls: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
