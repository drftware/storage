--!strict
-- lune run tests/tryon.spec
-- Trying a wrap colour on at a mirror (S5-03f4a, idea 24): each press tries the next colour on
-- the counter's shelf, round and round; the film winds on from the ankles as you turn once round
-- to face the glass, stays a few seconds, then peels down to a heap and fades; nobody starts a
-- second one while the first is on.
local roblox = require("@lune/roblox")

local Kept = require("../src/shared/Kept")
local LobbySpecs = require("../src/shared/Lobby/Specs")
local Shop = require("../src/shared/Shop")
local TryOn = require("../src/shared/TryOn")
local WrapColours = require("../src/shared/WrapColours")

local Vector3 = roblox.Vector3

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number, by: number?): boolean
	return math.abs(a - b) <= (by or 1e-6)
end

-- The colours: the shelf's, in its order, back to the first after the last.
do
	local shelf = WrapColours.Shelf
	ok(TryOn.next(nil) == shelf[1].name, "the first press tries the shelf's first colour")
	ok(TryOn.next("") == shelf[1].name, "after the plain film, the first colour")
	ok(TryOn.next("nonsense") == shelf[1].name, "after something that isn't a colour, the first")
	ok(TryOn.next(shelf[1].name) == shelf[2].name, "then the next")
	ok(TryOn.next(shelf[#shelf].name) == shelf[1].name, "after the last, round to the first")
	local seen: { [string]: boolean } = {}
	local last: string? = nil
	for _ = 1, #shelf do
		last = TryOn.next(last)
		seen[last :: string] = true
	end
	local count = 0
	for _ in seen do
		count += 1
	end
	ok(count == #shelf, "a press for each colour tries every one once")
end

-- How long: a few seconds wrapped, the whole thing over in a handful.
do
	ok(TryOn.Show >= 2, "you stand wrapped a few seconds")
	ok(
		near(TryOn.length(), TryOn.Wind + TryOn.Show + Kept.tearLength(TryOn.Peel)),
		"the length is the wind, the show and the peel"
	)
	ok(TryOn.length() <= 8, "it's over in a handful of seconds")
	local P = TryOn.Peel
	ok(
		near(Kept.tearLength(P), P.yank + P.fall + P.settle + P.rest + P.fade),
		"a peel of its own times its own length"
	)
	ok(Kept.tearLength(P) < Kept.tearLength(), "the peel is quicker than a rip")
end

-- The pose along the way.
do
	local start = TryOn.pose(0)
	ok(near(start.height, Kept.WindFrom), "it starts as a band round the ankles")
	ok(near(start.see, 1), "and clear")
	ok(near(start.turned, 0), "facing the way you stood")
	local half = TryOn.pose(TryOn.Wind / 2)
	ok(half.height > start.height and half.height < 1, "it climbs")
	ok(half.turned > 0 and half.turned < 1, "you're turning")
	local on = TryOn.pose(TryOn.Wind)
	ok(near(on.height, 1) and near(on.see, Kept.WrapBlend), "wound on and drawn")
	ok(near(on.turned, 1), "turned to the glass")
	local held = TryOn.pose(TryOn.Wind + TryOn.Show / 2)
	ok(
		near(held.height, 1) and near(held.wide, 1) and near(held.see, Kept.WrapBlend),
		"it stays on"
	)
	local peelAt = TryOn.Wind + TryOn.Show
	local P = TryOn.Peel
	local down = TryOn.pose(peelAt + P.yank + P.fall)
	ok(near(down.height, P.heap, 0.02), "it peels down to a heap at the ankles")
	ok(down.wide < 1 and down.deep > 1, "a heap round the ankles, not a flat body")
	ok(TryOn.pose(peelAt + P.yank + P.fall / 2).height < 1, "peeling")
	ok(near(TryOn.pose(TryOn.length()).see, 1), "gone at the end")
	ok(near(TryOn.pose(-1).height, Kept.WindFrom), "before it starts, as it starts")
	ok(near(TryOn.pose(TryOn.length() + 5).see, 1), "long after, still gone")
end

-- The turn: once round, in the shorter way's direction, ending facing the glass.
do
	local tau = 2 * math.pi
	ok(near(TryOn.turn(0.4, 1.2, 0), 0.4), "it starts where you faced")
	ok(near(TryOn.turn(0, 0.5, 1), 0.5 + tau), "a little left: once round to the left")
	ok(near(TryOn.turn(0, -0.5, 1), -0.5 - tau), "a little right: once round to the right")
	ok(
		near(TryOn.turn(3, -3, 1), 3 + (tau - 6) + tau),
		"across the back: the short way, once round"
	)
	local to = TryOn.turn(1, 2, 1)
	ok(
		near(math.cos(to), math.cos(2)) and near(math.sin(to), math.sin(2)),
		"it ends facing the glass"
	)
end

-- Busy: one try-on at a time each.
do
	ok(not TryOn.busy(nil, 100), "nothing on: free")
	ok(TryOn.busy(100, 100 + TryOn.length() / 2), "while it's on: busy")
	ok(not TryOn.busy(100, 100 + TryOn.length() + 0.01), "once it's off: free")
end

-- In front of a glass (S5-03f4b): within reach across the floor, on its picture's side, and not
-- standing in it; how high you stand doesn't matter.
do
	local c, n = Vector3.new(10, 3, 0), Vector3.new(0, 0, 1)
	ok(TryOn.before(c, n, Vector3.new(10, 0, 5), 7), "five studs in front: yes")
	ok(TryOn.before(c, n, Vector3.new(14, 6, 5), 7), "off to one side and higher, still in reach")
	ok(not TryOn.before(c, n, Vector3.new(10, 0, 8), 7), "eight studs off: out of reach")
	ok(not TryOn.before(c, n, Vector3.new(10, 0, -3), 7), "behind the glass: no")
	ok(not TryOn.before(c, n, Vector3.new(10, 0, 0.2), 7), "in the glass itself: no way to face it")
end

-- In line with a glass (S5-03f4b2): you see yourself only standing within half its width of its
-- middle, to either side; how far out or how high doesn't matter.
do
	local c, right = Vector3.new(10, 3, 0), Vector3.new(1, 0, 0)
	ok(TryOn.inLine(c, right, Vector3.new(10, 0, 8), 1.2), "straight out: yes")
	ok(TryOn.inLine(c, right, Vector3.new(8.9, 6, 3), 1.2), "a little aside: yes")
	ok(not TryOn.inLine(c, right, Vector3.new(11.7, 0, 7), 1.2), "1.7 aside: off its edge")
	ok(not TryOn.inLine(c, right, Vector3.new(7, 0, 2), 1.2), "3 aside the other way: no")
end

-- The counter's shop and its mirror (S5-03f4b): the counter's button stands just in front of the
-- counter's face as the lobby is now (it once stood where the old, shorter lobby had it), and
-- from where you'd stand to press it you're in front of the counter's mirror, within the shop's
-- Try on reach, so every card's Try on shows.
do
	local front = LobbySpecs.Parts.CounterFront
	local at = Shop.CounterAt
	ok(
		math.abs(at[3] - front.Centre[3]) <= front.Size[3] / 2,
		"the counter's button stands along the counter's face"
	)
	ok(
		at[1] < front.Centre[1] and at[1] > front.Centre[1] - 2,
		"just in front of the counter's face, on the room's side"
	)
	local m = Shop.Mirror
	local turn = math.rad(m.Turn)
	-- the glass looks along the foot's front (-Z) turned about Y
	local look = Vector3.new(-math.sin(turn), 0, -math.cos(turn))
	local glass = Vector3.new(m.At[1], 3, m.At[3])
	for _, step in { Vector3.new(-1.5, 0, 0), Vector3.new(-3, 0, 2), Vector3.new(-2, 0, -1) } do
		local stand = Vector3.new(at[1], 0, at[3]) + step
		ok(
			TryOn.before(glass, look, stand, Shop.TryReach),
			`standing at the counter {step}: in front of the mirror`
		)
	end
	-- standing at the counter's button you're in line with the glass (2.4 wide), so you see yourself
	local right = Vector3.new(math.cos(turn), 0, -math.sin(turn))
	ok(
		TryOn.inLine(glass, right, Vector3.new(at[1], 0, at[3]), 1.2),
		"standing at the counter's button: in line with the glass"
	)
	-- clear of the counter one way or the other: aside of it, or past its end (frame 3.2 wide, its
	-- foot and lean 1 deep)
	local wall = LobbySpecs.Parts.Counter
	ok(
		math.abs(m.At[1] - wall.Centre[1]) > wall.Size[1] / 2 + 1.6
			or math.abs(m.At[3] - wall.Centre[3]) > wall.Size[3] / 2 + 1,
		"the mirror stands clear of the counter"
	)
end

print(`tryon.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
