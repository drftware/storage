--!strict
-- lune run tests/left.spec
-- Left behind (L-08c): the sting's black is whole before the floor is cleared under you and lifts
-- on your friend as their car levels; the title reads before the black takes it; the motor is
-- gone before the bell; the follow camera's smoothing is the same at any frame rate and turns the
-- short way; switching friend walks every friend in a steady order and wraps.
local Climb = require("../src/shared/Climb")
local Left = require("../src/shared/Left")
local Ride = require("../src/shared/Elevator/Ride")

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
	return math.abs(a - b) <= (eps or 1e-6)
end

-- the sting
ok(Left.black(0) == 0, "the screen is clear as the gate hits its post")
ok(Left.black(Left.TitleAt - 0.01) == 0, "clear until the title")
ok(near(Left.black(Left.DarkAt), Left.Dim, 1e-3), "dimmed behind the title")
ok(Left.black(Climb.HandOff - 0.2) >= 0.999, "whole black before the floor is cleared under you")
ok(Left.DarkAt + Left.DarkIn < Climb.HandOff, "the black lands before the hand-off")
local last = 0
for i = 0, 1000 do
	local t = i * 0.01
	local b = Left.black(t)
	ok(b >= last - 1e-9 and b >= 0 and b <= 1, `the black only deepens through the sting ({t})`)
	last = b
end
local shown, size = Left.title(Left.TitleAt + Left.TitleIn)
ok(shown >= 0.999 and near(size, 1, 1e-6), "the title is up and settled")
ok(select(1, Left.title(Left.TitleAt - 0.01)) == 0, "no title before its moment")
ok(select(2, Left.title(Left.TitleAt)) > 1, "the title lands from a little bigger")
ok(select(1, Left.title(Left.DarkAt + Left.DarkIn)) <= 0.001, "the black takes the title")
ok(Left.TitleAt + Left.TitleIn < Left.DarkAt - 1.5, "the title holds long enough to read twice")
ok(Left.TitleAt < 0.3, "the title answers the gate at once")
ok(Left.HitAt >= Left.TitleAt + Left.TitleIn, "the hit lands after the title has settled")
ok(Left.Freeze == Left.HitAt, "the legs go with the hit")
ok(
	Left.edges(Left.TitleAt) == 0 and near(Left.edges(Left.Freeze), Left.Edges),
	"the bars are in as the legs go"
)

-- the lift lands as the friend's gate opens
ok(Left.LiftAt > Climb.HandOff, "the black lifts only after the friend's in the new car")
ok(
	Left.LiftAt < Ride.arrives() and Left.LiftAt + Left.LiftIn >= Ride.arrives(),
	"lifting as it levels"
)
ok(Left.LiftAt + Left.LiftIn <= Ride.opens() + 0.2, "clear as the gate folds open")
ok(Left.lift(0) == 1 and Left.lift(Left.LiftIn) == 0, "the lift runs black to clear")

-- the motor fades away up the shaft, gone before the bell
ok(Left.away(Ride.Wait) == 0, "silent before the brakes let go")
local loudest = 0
for i = 0, 400 do
	loudest = math.max(loudest, Left.away(i * 0.025))
end
ok(loudest > 0.5, "the motor is heard as the car gets going")
ok(Left.away(Ride.arrives()) < 0.01, "the motor's gone before the bell")
ok(Left.away(Climb.HandOff) < 0.25, "and nearly gone by the hand-off")

-- switching dips: holds black while waiting, lifts once the friend's in
ok(near(Left.dip(Left.DipIn, nil), 1), "black once the dip is down")
ok(near(Left.dip(5, nil), 1), "held black while the friend streams in")
ok(near(Left.dip(5, Left.DipOut), 0), "clear once they're in")

-- smoothing: the same path at any frame rate
local function run(rate: number, dt: number, seconds: number): number
	local x = 0
	local steps = math.floor(seconds / dt + 0.5)
	for _ = 1, steps do
		x += (1 - x) * Left.ease(rate, dt)
	end
	return x
end
ok(
	near(run(Left.Follow, 1 / 60, 0.6), run(Left.Follow, 1 / 15, 0.6), 1e-6),
	"follow: 60 fps = 15 fps"
)
ok(Left.ease(Left.Follow, 0) == 0, "no time, no move")
-- turning takes the short way round
local h = Left.turn(math.rad(170), math.rad(-170), 1000, 1)
ok(
	near(math.cos(h), math.cos(math.rad(-170)), 1e-6)
		and near(math.sin(h), math.sin(math.rad(-170)), 1e-6),
	"turns to the target"
)
local half = Left.turn(math.rad(170), math.rad(-170), math.log(2), 1)
ok(near(half, math.rad(180), 1e-6), "170 to -170 goes through 180, not through 0")
ok(
	near(Left.heading(0, -1), 0) and near(Left.heading(-1, 0), math.pi / 2),
	"headings: -Z is 0, -X is a left turn"
)

-- cycling friends
ok(Left.cycle({}, nil, 1) == nil, "nobody to watch")
ok(Left.cycle({ "b", "a" }, nil, 1) == "a", "the first in order to start")
ok(Left.cycle({ "b", "a", "c" }, "a", 1) == "b", "next")
ok(Left.cycle({ "b", "a", "c" }, "c", 1) == "a", "next wraps")
ok(Left.cycle({ "b", "a", "c" }, "a", -1) == "c", "back wraps")
ok(Left.cycle({ "b", "a" }, "gone", -1) == "a", "a friend gone: the first")
ok(Left.cycle({ "a" }, "a", 1) == "a", "one friend stays")
local seen: { [string]: boolean } = {}
local k: string? = nil
local keys = { "p000000000000042", "p000000000000007", "sStandIn" }
for _ = 1, 3 do
	k = Left.cycle(keys, k, 1)
	seen[k :: string] = true
end
ok(
	seen.p000000000000042 and seen.p000000000000007 and seen.sStandIn or false,
	"three nexts visit all three"
)

-- back in
local t, why = Left.decodeBack(Left.encodeBack(1234.5, "CutFree"))
ok(t ~= nil and near(t :: number, 1234.5, 1e-3) and why == "CutFree", "back in: when and why")
ok(select(1, Left.decodeBack(nil)) == nil, "nothing to decode")
ok(select(1, Left.decodeBack("x|y")) == nil, "a bad value")

-- the follow camera stays in front of what it pulls in to
ok(Left.Near < Left.Back and Left.Clear < Left.Near, "the camera never nearer than Near")
ok(Left.PitchLow < Left.Pitch and Left.Pitch < Left.PitchHigh, "the resting pitch is in range")

-- carried up (S3-01a): the dip waits for the gate to be all the way open and comes before it
-- shuts again; it only darkens, goes whole, and the door slams in the black, not in view
local arrived = 100
ok(Left.carryAt(arrived) > arrived + Ride.Open, "the carry waits for the gate to open")
ok(
	Left.carryAt(arrived) + Left.CarryDip < arrived + Ride.Open + Ride.Linger,
	"the black is whole before the gate shuts behind the team"
)
ok(Left.carry(-0.1) == 0 and Left.carry(0) == 0, "clear before the dip")
ok(Left.carry(Left.CarryDip / 2) > 0 and Left.carry(Left.CarryDip / 2) < 1, "dipping")
ok(Left.carry(Left.CarryDip) >= 0.999 and Left.carry(30) == 1, "whole black from the dip's end")
local last, rising = 0, true
for i = 1, 40 do
	local b = Left.carry(i * Left.CarryDip / 40)
	if b < last then
		rising = false
	end
	last = b
end
ok(rising, "the dip only darkens")
ok(Left.CarrySlam > Left.CarryDip, "the door slams in the black")
ok(Left.Copy.Until == "", "no line on the bar explains how you get back in")

if failures > 0 then
	error(`left: {failures} of {checks} checks failed`)
end
print(`left: {checks} checks passed`)
