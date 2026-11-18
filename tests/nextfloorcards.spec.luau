--!strict
-- The next-floor cards on a rider's screen (S4-03b2): three cards between the thumbstick and the
-- jump button, big enough to tap on a phone; each card carries the heads of whoever pressed it,
-- yours first; they come up with the lurch, take presses until the cable's second knock, show
-- the winner and go as the gate opens. Run: lune run tests/nextfloorcards.spec
local Cards = require("../src/shared/NextFloorCards")
local NextFloor = require("../src/shared/NextFloor")
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

-- 1. On a Galaxy A16 in landscape (the gui is 685 by 280 under the top bar), three cards a thumb
-- can't miss, clear of the jump button and the thumbstick, under the screen's middle.
do
	local l = Cards.layout(685, 280)
	ok(#l.xs == NextFloor.Offered, "three cards laid out")
	ok(l.cardW >= 70 and l.cardH >= 100, `A16 cards big enough to tap ({l.cardW} by {l.cardH})`)
	ok(l.cardH <= 280 * 0.45, "A16 cards leave the top of the screen for the shaft")
	local right = l.xs[#l.xs] + l.cardW / 2
	ok(685 / 2 + right <= 685 - Cards.Clear, "A16 cards clear of the jump button")
	ok(685 / 2 - right >= Cards.Clear, "A16 cards clear of the thumbstick's corner")
	ok(l.gap >= 8, "A16 cards far enough apart for a thumb")
	ok(l.faceH < l.cardH, "room under the picture for the coins")
	ok(math.abs(l.faceH * Cards.Aspect - l.cardW) <= 1, "the picture keeps its 4:5 shape")
	ok(l.head >= Cards.MinHead and l.head <= l.cardW / 2, "a head fits on a card")
	ok(math.abs(l.xs[1] + l.xs[3]) < 1e-9 and l.xs[2] == 0, "the three sit centred")
end

-- 2. A big monitor doesn't get a wall of cards; a tiny window still gets tappable ones; a
-- narrow screen shrinks them to fit, but never below a thumb's width.
do
	local big = Cards.layout(2560, 1300)
	ok(big.cardH <= Cards.MaxTall, "a monitor's cards stay a sensible size")
	local tiny = Cards.layout(500, 150)
	ok(tiny.cardH >= Cards.MinTall * 0.5, "a tiny window's cards still tall enough")
	local narrow = Cards.layout(420, 400)
	ok(narrow.cardW >= Cards.MinWide, "a narrow screen's cards never under a thumb's width")
	local across = 3 * narrow.cardW + 2 * narrow.gap
	ok(
		across <= 420 - 2 * Cards.Clear or narrow.cardW == Cards.MinWide,
		"a narrow screen's cards shrink to fit"
	)
	for _, size in { { 685, 280 }, { 1280, 720 }, { 844, 390 }, { 2560, 1300 } } do
		local l = Cards.layout(size[1], size[2])
		ok(
			l.cardW == math.floor(l.cardW) and l.cardH == math.floor(l.cardH),
			"whole pixels, crisp edges"
		)
		ok(l.bottom >= 0 and l.bottom + l.cardH < size[2], "the cards stay on the screen")
	end
end

-- 3. Each card carries the heads of who pressed it: yours first, then by UserId; a press for
-- something not offered counts for nothing; every offered card has its list.
do
	local offered = { "PowerOut", "TwicePadlocks", "TwiceMonsters" }
	local on = Cards.heads(
		{ [30] = "PowerOut", [10] = "PowerOut", [20] = "PowerOut", [5] = "TwiceMonsters" },
		offered,
		20
	)
	ok(#on.PowerOut == 3 and on.PowerOut[1] == 20, "my head first on my card")
	ok(on.PowerOut[2] == 10 and on.PowerOut[3] == 30, "the rest by UserId")
	ok(#on.TwicePadlocks == 0, "an unpressed card carries none")
	ok(#on.TwiceMonsters == 1 and on.TwiceMonsters[1] == 5, "a friend's press on its card")
	local junk = Cards.heads({ [1] = "CaughtToLobby", [2] = "Nonsense" }, offered, 1)
	local count = 0
	for _, list in junk do
		count += #list
	end
	ok(count == 0, "presses for cards not offered carry no head")
	-- changing your mind moves your head: the old card loses it, the new one gains it
	local before = Cards.heads({ [7] = "PowerOut", [8] = "PowerOut" }, offered, 7)
	local after = Cards.heads({ [7] = "TwicePadlocks", [8] = "PowerOut" }, offered, 7)
	ok(
		#before.PowerOut == 2 and #after.PowerOut == 1 and after.TwicePadlocks[1] == 7,
		"a change of mind moves the head"
	)
end

-- 4. Heads along a card's top edge: one in the middle, a few side by side, many overlapping but
-- never past the card's edges.
do
	ok(Cards.headX(1, 1, 80, 24) == 0, "one head in the middle")
	local a, b = Cards.headX(1, 2, 80, 24), Cards.headX(2, 2, 80, 24)
	ok(math.abs(a + b) < 1e-9 and b - a == 24 + Cards.HeadGap, "two side by side, centred")
	for n = 1, 8 do
		for i = 1, n do
			local x = Cards.headX(i, n, 80, 24)
			ok(math.abs(x) + 12 <= 40 + 1e-9, `head {i} of {n} within the card`)
		end
	end
	ok(Cards.headX(2, 6, 80, 24) > Cards.headX(1, 6, 80, 24), "crowded heads still in order")
end

-- 5. The cards come up with the lurch, take presses until the cable's second knock, show the
-- winner once the server names it, and go as the gate opens.
do
	ok(Cards.phase(0, false) == "waiting", "under the floor before the lurch")
	ok(Cards.phase(Ride.moves(), false) == "voting", "up with the lurch")
	ok(Cards.phase(NextFloor.Closes - 0.01, false) == "voting", "presses until the knock")
	ok(Cards.phase(NextFloor.Closes, false) == "closed", "no presses from the knock")
	ok(Cards.phase(NextFloor.Closes + 0.05, true) == "picked", "the winner once named")
	ok(
		Cards.phase(Ride.Clanks[3] + 1, true) == "picked",
		"still lit across the riders' change of cars"
	)
	ok(Cards.phase(Ride.opens(), true) == "gone", "gone as the gate opens")
	ok(Cards.phase(0.2, true) == "waiting", "a car back with its pick waits for the lurch too")
	ok(Cards.phase(2, true) == "picked", "a car back with its pick shows it")
end

-- 6. Every version's card glows in its own colour of light (D-404).
do
	local seen: { [string]: boolean } = {}
	for _, version in NextFloor.Versions do
		local light = version.light
		local fine = #light == 3
		for _, c in light do
			fine = fine and c >= 0 and c <= 1
		end
		ok(fine, `{version.name}'s light is a colour`)
		local key = table.concat(light, ",")
		ok(not seen[key], `{version.name}'s light is its own`)
		seen[key] = true
	end
end

print(`nextfloorcards: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
