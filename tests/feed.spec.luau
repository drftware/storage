--!strict
-- lune run tests/feed.spec
-- Feed (S2-02d): a security camera hangs inside the hall it watches, off every wall and the
-- ceiling, out far enough to see and close enough to read at phone size, straight out when
-- there's no room along the wall; its number is steady for a spot; it cuts in a few steps early.
local Feed = require("../src/shared/Feed")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- a roomy hall: it hangs as far as it's allowed, inside the room
do
	local side, up, out = Feed.hang(20, 20, 20)
	ok(out == Feed.OutMost, "a wide hall: out as far as it reads")
	ok(side == Feed.SideMost, "a long wall: along it as far as it's allowed")
	ok(up == Feed.UpMost, "a high ceiling: up as far as it's allowed")
end

-- a hall 10 studs across, 8 along the wall, a ceiling 3 up: it keeps off each
do
	local side, up, out = Feed.hang(10, 8, 3)
	ok(out <= 10 - Feed.WallGap + 1e-9, "never into the far wall")
	ok(side <= 8 - Feed.WallGap + 1e-9, "never into the wall along it")
	ok(up <= 3 - Feed.WallGap + 1e-9 or up == Feed.UpLeast, "under the ceiling, or at its least")
	ok(up >= Feed.UpLeast, "it looks down at the spot")
end

-- a dead end's wall, nothing along it: straight out
do
	local side = Feed.hang(12, 0.3, 6)
	ok(side == 0, "no room along the wall: straight out from the spot")
end

-- a narrow place: still far enough out to see the thing
do
	local _, _, out = Feed.hang(2, 5, 6)
	ok(out == Feed.OutLeast, "a narrow hall: out at its least")
end

-- no ceiling found, nothing measured
do
	local _, up = Feed.hang(10, 5, math.huge)
	ok(up == Feed.UpMost, "no ceiling: up as far as it's allowed")
	local side, up2, out = Feed.hang(0 / 0, 0 / 0, 0 / 0)
	ok(side == 0 and up2 == Feed.UpLeast and out == Feed.OutLeast, "nothing measured: the least")
end

-- the camera's number
do
	ok(Feed.number(12.5, -40) == Feed.number(12.5, -40), "a spot reads the same number")
	local n = Feed.number(-317.2, 88.9)
	ok(n >= 1 and n <= 16 and n == math.floor(n), "a number 1 to 16")
	ok(Feed.number(0 / 0, 3) == 1, "a spot gone wrong reads 1")
	local seen: { [number]: boolean } = {}
	for x = -40, 40, 3 do
		seen[Feed.number(x, x * 0.5)] = true
	end
	local count = 0
	for _ in seen do
		count += 1
	end
	ok(count >= 8, "spots around a floor read different numbers")
end

-- when it cuts in
do
	ok(Feed.due(5, 2.5), "five studs at 2.5 a second: under its lead, cut in")
	ok(not Feed.due(30, 2.5), "thirty studs off: not yet")
	ok(Feed.due(0.3, 0), "standing there: cut in")
	ok(not Feed.due(4, 0), "held still short of it: not yet")
	ok(not Feed.due(0 / 0, 2), "a distance gone wrong: never")
end

-- riders whose gate shut leave a feed of the floor they left (S2-02d4); the rest keep it
do
	local watching = { "ana", "ben", "cal" }
	local cut = Feed.leave(watching, { "ben", "dee" })
	ok(#cut == 1 and cut[1] == "ben", "only a watcher who left is cut")
	ok(#watching == 2 and watching[1] == "ana" and watching[2] == "cal", "the rest keep watching")
	ok(#Feed.leave(watching, {}) == 0 and #watching == 2, "nobody leaving cuts nobody")
	local all = Feed.leave(watching, { "cal", "ana" })
	ok(#all == 2 and #watching == 0, "everyone leaving: nobody's left watching")
end

-- the look's numbers stay sensible
ok(Feed.SnowIn > 0 and Feed.SnowOut > 0 and Feed.After > Feed.SnowOut, "the snow is brief")
ok(Feed.Most > Feed.Lead + Feed.After, "a feed's longest outlasts a full walk-up and the moment")
ok(
	Feed.InFrom >= 0 and Feed.InTail > 0 and Feed.OutCut > Feed.SnowOut + 0.5,
	"the hiss slices sit inside their recordings"
)
ok(Feed.OutLeast < Feed.OutMost and Feed.UpLeast < Feed.UpMost, "least under most")

print(`feed: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
