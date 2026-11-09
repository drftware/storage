--!strict
-- lune run tests/crawlhole.spec
-- The crawl hole's numbers against the units and keepers they must suit, and the wall's collision
-- once it's cut.
local fs = require("@lune/fs")
local Boxes = require("../src/shared/StorageUnit/CrawlHole/Boxes")
local DealSpot = require("../src/shared/DealSpot")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- The generated Specs build Vector3s, which Lune hasn't: read the numbers from the text.
local function number(path: string, key: string): number
	local text = fs.readFile(path)
	local v = string.match(text, "\n%s*" .. key .. " = (%-?[%d%.]+)")
	assert(v, `{key} not in {path}`)
	return tonumber(v) :: number
end
local HOLE = "src/shared/StorageUnit/CrawlHole/Specs.luau"
local from, to = number(HOLE, "From"), number(HOLE, "To")
local bottom, top = number(HOLE, "Bottom"), number(HOLE, "Top")
local smallDepth = number("src/shared/StorageUnit/Specs/S.luau", "Depth")

-- where it is: past the door's guides, and a stud short of a small neighbour's back wall (two
-- units side by side in a row share at least a small unit's whole side, D-031)
ok(from >= DealSpot.Door, "the hole is past the doorway's clear strip")
ok(to + 1 <= smallDepth + 1e-6, "a stud of wall behind the hole in a small unit")
-- how big: clear of the bottom track, roomy for a crawl, and too low to walk through: a standing
-- player's body reaches 4 studs up and a keeper stands 6.3 tall
ok(bottom > 0.14, "above the wall's bottom track")
ok(top - bottom >= 2.4 and to - from >= 2.6, "big enough to crawl through")
ok(top < 4, "too low to walk through")
ok(top < DealSpot.Keeper.tall / 2, "far too low for a keeper")

-- the collision round it: covers the wall but the hole, nothing overlapping
local function area(r: Boxes.Rect): number
	return (r.along1 - r.along0) * (r.up1 - r.up0)
end
local function overlap(a: Boxes.Rect, b: Boxes.Rect): number
	local w = math.min(a.along1, b.along1) - math.max(a.along0, b.along0)
	local h = math.min(a.up1, b.up1) - math.max(a.up0, b.up0)
	return if w > 0 and h > 0 then w * h else 0
end
local wall = { along0 = -5.875, along1 = 5.875, up0 = -5, up1 = 5 }
local hole = { along0 = from - 6.125, along1 = to - 6.125, up0 = bottom - 5, up1 = top - 5 }
local pieces = Boxes.around(wall, hole)
ok(#pieces == 4, "four pieces round a hole in the middle of a wall")
local sum = 0
for i, p in pieces do
	sum += area(p)
	ok(overlap(p, hole) < 1e-9, `{p.name} keeps out of the hole`)
	ok(math.abs(overlap(p, wall) - area(p)) < 1e-9, `{p.name} stays on the wall`)
	for j = i + 1, #pieces do
		ok(overlap(p, pieces[j]) < 1e-9, `{p.name} and {pieces[j].name} don't overlap`)
	end
end
ok(math.abs(sum - (area(wall) - area(hole))) < 1e-6, "the pieces cover the wall but the hole")
-- a hole at the wall's end or past it leaves no empty pieces, and never reaches off the wall
local edge = Boxes.around(wall, { along0 = -7, along1 = -4, up0 = -6, up1 = -2 })
ok(#edge == 2, "a hole on the wall's corner leaves the wall behind it and over it")
for _, p in edge do
	ok(math.abs(overlap(p, wall) - area(p)) < 1e-9, `{p.name} of a corner hole stays on the wall`)
end

print(`crawlhole: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
