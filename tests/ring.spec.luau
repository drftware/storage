--!strict
-- lune run tests/ring.spec
-- Where the round buttons sit round a selected thing (S5-03j2b1, Home/Ring): a row bowed over the
-- thing's box on screen, clear of it and of the thumb under it; below it when there's no room
-- above; slid sideways to stay on screen; spaced a button and a gap apart.
local Ring = require("../src/shared/Home/Ring")

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

local SIZE, GAP, SAG, MARGIN = 52, 10, 8, 8
local O: Ring.Options = { size = SIZE, gap = GAP, sag = SAG, margin = MARGIN }
local SCREEN: Ring.Box = { left = 0, top = 0, right = 685, bottom = 338 }
local R = SIZE / 2

-- A thing in the middle of the screen: three buttons over it.
do
	local box: Ring.Box = { left = 300, top = 150, right = 380, bottom = 220 }
	local at, side = Ring.place(box, 3, SCREEN, O)
	ok(#at == 3, "three buttons for three")
	ok(side == "above", "over a thing in the middle")
	ok(near(at[2].x, 340), "the middle one over the thing's middle")
	ok(
		near(at[1].x, 340 - SIZE - GAP) and near(at[3].x, 340 + SIZE + GAP),
		"a button and a gap apart"
	)
	ok(near(at[2].y + R, box.top - GAP), "the middle one a gap clear of the thing's top")
	ok(at[1].y > at[2].y and near(at[1].y, at[3].y), "the ends bow down round it, alike")
	ok(at[1].y + R <= box.top - GAP + SAG + 1e-6, "the ends no lower than the bow")
	for i, p in at do
		ok(p.x - R >= MARGIN and p.x + R <= 685 - MARGIN, `button {i} on the screen across`)
		ok(p.y - R >= MARGIN, `button {i} under the screen's top`)
	end
end

-- Two and one: centred on the thing.
do
	local box: Ring.Box = { left = 300, top = 150, right = 380, bottom = 220 }
	local two = Ring.place(box, 2, SCREEN, O)
	ok(#two == 2 and near((two[1].x + two[2].x) / 2, 340), "two centred over the thing")
	ok(near(two[2].x - two[1].x, SIZE + GAP), "two a button and a gap apart")
	local one = Ring.place(box, 1, SCREEN, O)
	ok(#one == 1 and near(one[1].x, 340) and near(one[1].y + R, box.top - GAP), "one straight over")
	ok(#Ring.place(box, 0, SCREEN, O) == 0, "none for none")
end

-- High on the screen: no room above, so they sit under it, bowed up round it.
do
	local box: Ring.Box = { left = 300, top = 20, right = 380, bottom = 90 }
	local at, side = Ring.place(box, 3, SCREEN, O)
	ok(side == "below", "under a thing at the screen's top")
	ok(near(at[2].y - R, box.bottom + GAP), "the middle one a gap under the thing")
	ok(at[1].y < at[2].y, "the ends bow up round it")
end

-- At the screen's left and right edges: the row slides on, keeping its spacing.
do
	local left = Ring.place({ left = 0, top = 150, right = 30, bottom = 200 }, 3, SCREEN, O)
	ok(near(left[1].x - R, MARGIN), "slid on from the left edge to the margin")
	ok(near(left[2].x - left[1].x, SIZE + GAP), "spacing kept at the left edge")
	local right = Ring.place({ left = 660, top = 150, right = 700, bottom = 200 }, 3, SCREEN, O)
	ok(near(right[3].x + R, 685 - MARGIN), "slid on from the right edge to the margin")
end

-- A thing filling the screen: they stay on the screen, over it if they must.
do
	local at = Ring.place({ left = -50, top = -40, right = 735, bottom = 400 }, 3, SCREEN, O)
	for i, p in at do
		ok(
			p.y - R >= MARGIN - 1e-6 and p.y + R <= 338 - MARGIN + 1e-6,
			`button {i} on screen, up and down`
		)
	end
end

-- An area that isn't the whole screen (the band the menus leave): kept inside it.
do
	local band: Ring.Box = { left = 0, top = 60, right = 685, bottom = 338 }
	local at, side = Ring.place({ left = 300, top = 70, right = 380, bottom = 140 }, 3, band, O)
	ok(side == "below", "below when the band's top leaves no room above")
	ok(at[1].y - R >= 60 + MARGIN - 1e-6, "under the band's top")
end

-- Nonsense in, nothing out.
do
	ok(#Ring.place({ left = 0 / 0, top = 0, right = 1, bottom = 1 }, 3, SCREEN, O) == 0, "NaN box")
	ok(
		#Ring.place(
				{ left = 0, top = 0, right = 1, bottom = 1 },
				3,
				SCREEN,
				{ size = 0, gap = 1, sag = 0, margin = 0 }
			) == 0,
		"zero size"
	)
end

print(`ring: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
