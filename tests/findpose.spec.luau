--!strict
-- lune run tests/findpose.spec
-- How a kit-built find stands (F-G1a, Finds/Pose: the kit's own sums). Every built find's motion
-- order is the one its generated set wrote (Finds/Order), so its rest is the kit's; a turn is
-- right-handed about the part's pivot, as CFrame.fromAxisAngle; a child rides its parent's turn
-- and squash; and the finds are found the way their sheets show them: the jack-in-the-box shut
-- with the jack pressed in, the tea light and oil lamp unlit, the Secret lamp already lit.
local roblox = require("@lune/roblox")

local Fixture = require("./fixtures/finds")
local Order = require("../src/shared/Finds/Order")
local Pose = require("../src/shared/Finds/Pose")

local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame

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
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) < (eps or 1e-6)
end

-- the order: every kit-built find's, as its set wrote it
for name, order in Fixture.order do
	local mine = Order[name]
	ok(
		mine ~= nil and table.concat(mine, ",") == table.concat(order, ","),
		`{name}: its motion order`
	)
end
for name in Order do
	ok(Fixture.kit[name] ~= nil, `{name}: Order names a built find`)
end

-- a made-up find: a base, an arm hinged on it, a hand on the arm
local function find(): any
	return {
		Parts = {
			{ Name = "Base", Pivot = Vector3.new(0, 0, 0), Size = Vector3.one },
			{
				Name = "Arm",
				Parent = "Base",
				Pivot = Vector3.new(0, 1, 0),
				Axis = Vector3.new(0, 0.6, 0.8),
				Size = Vector3.one,
			},
			{
				Name = "Hand",
				Parent = "Arm",
				Pivot = Vector3.new(0, 2, 0),
				Axis = Vector3.new(1, 0, 0),
				Size = Vector3.one,
			},
		},
		Motions = {},
		Lights = {},
	}
end

-- a turn is CFrame.fromAxisAngle's, about the pivot
do
	local moved = Pose.solve(find(), { Arm = { turn = 37 } })
	local cf = CFrame.new(0, 1, 0)
		* CFrame.fromAxisAngle(Vector3.new(0, 0.6, 0.8).Unit, math.rad(37))
		* CFrame.new(0, -1, 0)
	for _, p in { Vector3.new(1, 2, 3), Vector3.new(-0.5, 0, 2), Vector3.zero } do
		local x, y, z = Pose.apply(moved.Arm, p.X, p.Y, p.Z)
		local want = cf * p
		ok(
			near(x, want.X) and near(y, want.Y) and near(z, want.Z),
			`a turn is fromAxisAngle's ({p})`
		)
	end
	local hx, hy, hz = Pose.apply(moved.Hand, 0, 2, 0)
	local want = cf * Vector3.new(0, 2, 0)
	ok(near(hx, want.X) and near(hy, want.Y) and near(hz, want.Z), "the hand rides the arm's turn")
	local bx, by, bz = Pose.apply(moved.Base, 1, 2, 3)
	ok(bx == 1 and by == 2 and bz == 3, "an unmoved part stays where it was drawn")
end

-- a squash about the pivot keeps the volume of a stretch; a child rides it
do
	local moved = Pose.solve(find(), { Arm = { stretch = 0.5, scale = 2 } })
	local sx, sy, sz = Pose.scales(moved.Arm)
	ok(
		near(sy, 1) and near(sx, 2 / math.sqrt(0.5)) and near(sz, sx),
		"stretch: tall times, wide over root"
	)
	local _, y = Pose.apply(moved.Hand, 0, 2, 0)
	ok(near(y, 1 + 1 * 2 * 0.5), "the hand's hinge rides the arm's squash")
	local _, hy = Pose.scales(moved.Hand)
	ok(near(hy, 1), "and the hand squashes with it")
end

-- travel: over the floor, then a yaw about the pivot
do
	local moved = Pose.solve(find(), { Base = { x = 2, z = -1, yaw = 90 } })
	local x, y, z = Pose.apply(moved.Base, 1, 0, 0)
	ok(near(x, 2) and near(y, 0) and near(z, -2), "travel moves, then yaws about the pivot")
end

-- found as the sheets show: rest from the order
local function rest(name: string): any
	return Pose.rest(Fixture.kit[name], Order[name])
end
do
	local jack = rest("JackInTheBox")
	ok(near(jack.JackInTheBox_Lid.turn, -112), "the jack's lid is shut")
	ok(
		near(jack.JackInTheBox_Jack.scale, 0.785) and near(jack.JackInTheBox_Jack.stretch, 0.56),
		"the jack is pressed in"
	)
	local moved = Pose.solve(Fixture.kit.JackInTheBox, jack)
	local _, sy = Pose.scales(moved.JackInTheBox_Head)
	ok(near(sy, 0.785 * 0.56, 1e-4), "its head squashes with it")
	local headPivot = Fixture.kit.JackInTheBox.Parts[6].Pivot
	local _, hy = Pose.apply(moved.JackInTheBox_Head, headPivot.X, headPivot.Y, headPivot.Z)
	ok(hy < 0.55, `its head is down in the box ({hy})`)
	ok(rest("TeaLight").TeaLight_Flame.scale == 0, "the tea light is found unlit")
	ok(rest("OilLamp").OilLamp_Flame.scale == 0, "the oil lamp is found unlit")
	ok(rest("UnpluggedLamp").UnpluggedLamp_Shade.glow == 1, "the Secret lamp is found lit")
	ok(((rest("DeskLamp").DeskLamp_Bulb or {}).glow or 0) == 0, "the desk lamp is found off")
end

-- a motion's frame over the rest keeps what the motion doesn't move
do
	local base = rest("JackInTheBox")
	local crank = (base.JackInTheBox_Crank or {}).turn
	local at = Pose.at(Fixture.kit.JackInTheBox.Motions.Wind, 3, base)
	ok(at.JackInTheBox_Lid.turn == base.JackInTheBox_Lid.turn, "winding leaves the lid shut")
	ok(at.JackInTheBox_Crank.turn ~= crank, "winding turns the crank")
	ok((base.JackInTheBox_Crank or {}).turn == crank, "and leaves the rest it started from alone")
end

print(`findpose: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
