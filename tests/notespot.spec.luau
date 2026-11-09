--!strict
-- lune run tests/notespot.spec
-- Where a code note sticks in its unit (L-05b1b), in both unit sizes and for a thousand unit
-- numbers: its back on the back wall's rib crests, the whole note on the wall, seen whole through
-- the doorway from anywhere across it, a plain yellow square from the doorway, its digit big
-- enough to read on a Galaxy A16 from a couple of steps in, and the spots varied unit to unit.
local fs = require("@lune/fs")
local NoteSpot = require("../src/shared/Elevator/NoteSpot")
local ElevatorSpecs = require("../src/shared/Elevator/Specs")

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

local function number(text: string, pattern: string): number
	local found = string.match(text, pattern)
	return assert(found and tonumber(found), `no {pattern}`)
end

-- The ribs' crests stand d + t/2 proud of the back wall's line (art/unit/parts.py).
local parts = fs.readFile("art/unit/parts.py")
local d = number(parts, "RIB_DEPTH, SHEET_T = ([%d%.]+), [%d%.]+")
local t = number(parts, "RIB_DEPTH, SHEET_T = [%d%.]+, ([%d%.]+)")
ok(math.abs(NoteSpot.RibProud - (d + t / 2)) < 1e-9, "the note lies on the ribs' crests")

-- A phone's view: rows of the Galaxy A16's 1080 across first person's 70 degrees of view.
local function rows(size: number, distance: number): number
	return math.deg(2 * math.atan(size / (2 * distance))) / 70 * 1080
end

local side = ElevatorSpecs.Note.Side * NoteSpot.Scale
local half = side / 2
for _, size in { "S", "M" } do
	local spec = fs.readFile(`src/shared/StorageUnit/Specs/{size}.luau`)
	local width = number(spec, "\n\tWidth = ([%d%.]+)")
	local depth = number(spec, "\n\tDepth = ([%d%.]+)")
	local wallHeight = number(spec, "\n\tWallHeight = ([%d%.]+)")
	local doorWidth = number(spec, "\n\tDoorWidth = ([%d%.]+)")
	local doorHeight = number(spec, "\n\tDoorHeight = ([%d%.]+)")
	local tilts: { [number]: boolean } = {}
	local crests: { [number]: boolean } = {}
	local last: NoteSpot.Spot? = nil
	for n = 101, 1099 do
		local id = `{size} unit {n}`
		local spot = NoteSpot.inUnit(depth, tostring(n))
		ok(spot.z == depth - NoteSpot.RibProud, `{id}: its back on the back wall`)
		ok(math.abs((spot.x + 0.5) % 1) < 1e-9, `{id}: on a rib's crest`)
		ok(math.abs(math.deg(spot.tilt)) <= NoteSpot.Tilt + 1e-9, `{id}: no more crooked than Tilt`)
		tilts[math.floor(math.deg(spot.tilt) * 10 + 0.5)] = true
		crests[spot.x] = true

		-- the note's corners, tilted, on the wall: clear of the side walls and the kick and top
		-- tracks (0.7 and 0.12 studs), and seen through the doorway from a viewer standing a stud
		-- out in the hall anywhere across the door, past the outer face and the curtain's plane
		local c, s = math.cos(spot.tilt), math.sin(spot.tilt)
		for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
			local cx = spot.x + (corner[1] * c - corner[2] * s) * half
			local cy = spot.y + (corner[1] * s + corner[2] * c) * half
			ok(math.abs(cx) <= width / 2 - 0.5, `{id}: on the wall, clear of its sides`)
			ok(cy >= 0.7 and cy <= wallHeight - 0.12, `{id}: on the wall, clear of its tracks`)
			for _, vx in { -doorWidth / 2 + 0.5, 0, doorWidth / 2 - 0.5 } do
				for _, plane in { 0, 0.55 } do
					local f = (plane + 1) / (spot.z + 1) -- along the sight line from z = -1
					local x = vx + (cx - vx) * f
					local y = NoteSpot.Height + (cy - NoteSpot.Height) * f
					ok(
						math.abs(x) < doorWidth / 2 and y < doorHeight,
						`{id}: seen through the doorway from x {vx}`
					)
				end
			end
		end

		-- from a stud out in the hall: a plain square (16 rows or more), its digit plain from
		-- 5 studs (30 rows, about 2 mm on the phone): a couple of steps into a small unit
		ok(rows(side, spot.z + 1) >= 16, `{id}: the note stands out from the doorway`)
		ok(
			rows(NoteSpot.DigitHeight * NoteSpot.Scale, 5) >= 30,
			`{id}: its digit reads from 5 studs`
		)

		if last then
			ok(last.x ~= spot.x or last.tilt ~= spot.tilt, `{id}: not stuck like its neighbour's`)
		end
		last = spot
	end
	local count = 0
	for _ in tilts do
		count += 1
	end
	ok(count == 5, `{size}: five tilts`)
	count = 0
	for _ in crests do
		count += 1
	end
	ok(count == #NoteSpot.Across, `{size}: every crest used`)
end

-- the same unit always gets the same spot
local a, b = NoteSpot.inUnit(12, "214"), NoteSpot.inUnit(12, "214")
ok(a.x == b.x and a.y == b.y and a.z == b.z and a.tilt == b.tilt, "a unit's spot never changes")

print(`notespot: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`notespot: {failures} failed`)
end
