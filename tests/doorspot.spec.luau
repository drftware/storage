--!strict
-- lune run tests/doorspot.spec
local DoorSpot = require("../src/shared/StorageUnit/DoorSpot")
local Kneel = require("../src/shared/StorageUnit/Kneel")
local WorldButton = require("../src/shared/WorldButton")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local EPS = 1e-9

local H = DoorSpot.Height
local EYE = Kneel.standingEye(2, 2) -- 4.5, a standard avatar standing
local HALF_VIEW = math.rad(35) -- Roblox's 70-degree view, each way of a level gaze
-- The Galaxy A16 in Studio's Device Simulator, measured: points from the view's middle to its
-- edge (Camera:WorldToViewportPoint of a point dead ahead sits 179.5 down), and down to the top of
-- the tool slots at the bottom.
local PHONE_HALF = 179.5
local TO_HAND = 87.5

-- Points under the screen's middle a spot `h` off the floor shows, `d` out, for an eye at `eye`.
local function below(h: number, eye: number, d: number): number
	return (eye - h) / d / math.tan(HALF_VIEW) * PHONE_HALF
end

-- Standing: far back every spot sits on its handle; nearer, each rides up just into view.
for _, d in { 1.5, 2, 2.5, 3, 4, 5, 6, 7, 8 } do
	for _, spot in { "Middle", "Low", "Latch" } do
		local h = DoorSpot.height(spot, EYE, d)
		local under = math.atan((EYE - h) / d)
		ok(h >= H[spot] - EPS, `{spot} {d} studs out: never under where it belongs`)
		ok(under <= DoorSpot.Below[spot] + EPS, `{spot} {d} studs out: in view standing`)
		if h > H[spot] + EPS then
			ok(
				math.abs(under - DoorSpot.Below[spot]) < 1e-6,
				`{spot} {d} studs out: raised only as far as it must`
			)
		end
	end
	ok(DoorSpot.height("Middle", EYE, d) <= EYE + EPS, `{d} studs out: Open never over your eye`)
	-- Peek's chip clears Open's on a phone, even pressed to the door
	local open = below(DoorSpot.height("Middle", EYE, d), EYE, d)
	local peek = below(DoorSpot.height("Low", EYE, d), EYE, d)
	ok(peek - open >= WorldButton.TouchChip, `{d} studs out: Peek a chip under Open`)
	-- and its chip stays clear of the hand's buttons at the bottom (the slots, jump, thumbstick)
	ok(peek + WorldButton.TouchChip / 2 <= TO_HAND - 4, `{d} studs out: Peek clear of the slots`)
end
ok(DoorSpot.height("Low", EYE, 8) < DoorSpot.height("Low", EYE, 2), "Peek lower the further back")
ok(DoorSpot.height("Low", EYE, 16) <= H.Low + 0.5, "near the handle a few steps back")
ok(DoorSpot.height("Low", EYE, 20) == H.Low, "and on it further")
ok(DoorSpot.height("Latch", EYE, 20) == H.Latch, "Cut on the latch")
ok(DoorSpot.height("Middle", 3.8, 3) == H.Middle, "a short avatar: Open at the door's middle")
for spot, angle in DoorSpot.Below do
	ok(angle < HALF_VIEW, `{spot}'s Below is inside the view`)
end

-- Looking down at the door: the low spots come down with your gaze onto the handle and the latch,
-- staying where they were on the screen until they're there; looking up counts as level.
do
	local d = 3
	for _, deg in { 5, 10, 20, 30 } do
		local pitch = -math.rad(deg)
		for _, spot in { "Low", "Latch" } do
			local h = DoorSpot.height(spot, EYE, d, pitch)
			local under = math.atan((EYE - h) / d) - math.rad(deg) -- under the gaze, on screen
			ok(under <= DoorSpot.Below[spot] + 1e-6, `{spot} looking down {deg}: in view`)
			ok(h <= DoorSpot.height(spot, EYE, d) + EPS, `{spot} looking down {deg}: no higher`)
		end
	end
	ok(
		DoorSpot.height("Low", EYE, d, -math.rad(45)) == H.Low,
		"look down at it: Peek on the handle"
	)
	ok(DoorSpot.height("Latch", EYE, d, -math.rad(45)) == H.Latch, "and Cut on the padlock")
	ok(DoorSpot.height("Middle", EYE, d, -math.rad(15)) == H.Middle, "Open settles on the middle")
	ok(
		DoorSpot.height("Low", EYE, d, math.rad(20)) == DoorSpot.height("Low", EYE, d),
		"looking up: as if level, so nothing chases your gaze"
	)
	ok(DoorSpot.height("Low", EYE, d, -math.rad(89)) >= H.Low, "straight down: still on the handle")
end

-- The latch's spot slides in along the bar toward the door's middle just far enough to sit within
-- Aside of your gaze; facing the padlock it sits on it; looking away it stays put.
do
	-- a door along x at z = 0, its middle at x = 0, the latch at x = 3.78; you 3 studs out at z = -3
	local function angleTo(s: number, cx: number, cz: number, fx: number, fz: number): number
		local px, pz = 3.78 * (1 - s) - cx, -cz
		return math.atan2(math.abs(px * fz - pz * fx), px * fx + pz * fz)
	end
	local s = DoorSpot.slide(0, -3, 0, 1, 3.78, 0, 0, 0)
	ok(s > 0 and s < 1, "facing the door's middle: the latch slides in part way")
	ok(math.abs(angleTo(s, 0, -3, 0, 1) - DoorSpot.Aside) < 1e-3, "just far enough: at Aside")
	local fx, fz = 3.78 / math.sqrt(3.78 ^ 2 + 9), 3 / math.sqrt(3.78 ^ 2 + 9)
	ok(DoorSpot.slide(0, -3, fx, fz, 3.78, 0, 0, 0) == 0, "facing the padlock: on it")
	ok(DoorSpot.slide(0, -3, -1, 0, 3.78, 0, 0, 0) == 0, "looking away down the hall: left be")
	ok(DoorSpot.slide(0, -12, 0, 1, 3.78, 0, 0, 0) == 0, "far back: the latch is near your gaze")
	ok(DoorSpot.slide(3.78, -3, 0, 1, 3.78, 0, 0, 0) == 0, "standing at the latch: on it")
end

-- Kneeling to peek: the middle row comes down to sit over your gaze, never over the gap.
for _, d in { 0, 0.5, 1, 1.5, 2, 3, 4, 6, 8, 12 } do
	local h = DoorSpot.height("Middle", Kneel.Eye, d)
	ok(h >= DoorSpot.Lowest - EPS and h <= H.Middle, `kneeling {d} out: between the gap and 4`)
	if h > DoorSpot.Lowest + EPS and h < H.Middle - EPS then
		ok(
			math.abs(math.atan((h - Kneel.Eye) / d) - DoorSpot.Above) < 1e-6,
			`kneeling {d} out: Above over a level gaze`
		)
	end
	if d >= 2 then
		ok(math.atan((h - Kneel.Eye) / d) <= math.rad(30), `kneeling {d} out: on screen`)
	end
end
ok(DoorSpot.height("Middle", Kneel.Eye, 0) == DoorSpot.Lowest, "pressed to the door: over the gap")
ok(DoorSpot.height("Middle", Kneel.Eye, 100) == H.Middle, "far back: no lower than it belongs")
ok(DoorSpot.Lowest > 1.15 + 0.5, "the lowest still clears the peek's gap")
ok(DoorSpot.height("Low", Kneel.Eye, 2) == H.Low, "kneeling, a low spot stays put")

-- Every spot the server puts out has a height, and Lift's stays put.
for _, spot in { "Middle", "Low", "Latch", "Inside" } do
	ok(type(H[spot]) == "number", `{spot} has a height`)
end
ok(DoorSpot.Moves.Inside == nil, "Lift stays where it is")
ok(H.Latch < H.Low and H.Low < H.Middle, "latch, handle, middle: bottom to top")

print(`doorspot: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
