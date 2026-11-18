--!strict
-- lune run tests/layout.spec
-- Every home's own pieces as rows (S5-03i1a, D-346): a layout per size that Brix accepts whole,
-- nothing mid-room, Small holding the shelf, the box and the mirror; a home laid before adopting
-- its pieces where they stood with the finds on their tops; a growing home's pieces riding their
-- walls; the starter pieces never sold, never counted against the limit.
local Brix = require("../vendor/brix/src")
local Furniture = require("../src/shared/Home/Furniture")
local Layout = require("../src/shared/Home/Layout")
local Save = require("../src/shared/Save")
local Sizes = require("../src/shared/Home/Sizes")
local Spots = require("../src/shared/Home/Spots")

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

local XC, XS = { 0, 5, 15.125 }, { 20, 10, 29.75 }
local function roomOf(size: string): { [string]: Spots.RoomArea }
	return Spots.room(Sizes.inside(size, XC, XS))
end

-- Loads `rows` into a Brix judge for `room` as the server will: every row's shape from its art.
local function judge(room: { [string]: Spots.RoomArea }, rows: { Save.PlacedRow }): { string }
	local areas: { [string]: Brix.PlacementArea } = {}
	for name, r in room do
		areas[name] = { kind = r.kind, width = r.width, depth = r.depth }
	end
	local set = Brix.Placements.new({ areas = areas, limit = 200 })
	local refused: { string } = {}
	for _, row in rows do
		local name = Spots.name(row.id) :: string
		local piece = Furniture.ofPlaced(name)
		local box = if piece then Spots.pieceBox(piece.id) else nil
		local refusal = set:place(row.id, Spots.shape(name, box), row)
		if refusal then
			table.insert(refused, `{row.id} {refusal}`)
		end
	end
	return refused
end

local function find(rows: { Save.PlacedRow }, kind: string): Save.PlacedRow?
	for _, row in rows do
		if row.id == Layout.id(kind) then
			return row
		end
	end
	return nil
end

-- The starter pieces are furniture: named with the mark, never sold, never on the bought counts.
do
	ok(Layout.id("Shelf") == "Shelf:Furniture#1", "a starter piece's id")
	ok(Layout.kind("Shelf:Furniture#1") == "Shelf", "read back")
	ok(Layout.kind("CampBed:Furniture#1") == nil and Layout.kind("Teddy#1") == nil, "only starters")
	local box = Furniture.byId("JobBox")
	ok(box ~= nil and box.kept == true and box.starter == true, "the job box is never put away")
	local shelf = Furniture.byId("Shelf")
	ok(shelf ~= nil and not shelf.kept, "the shelf may be put away")
	local wallet = { cash = 1e6, furniture = {} }
	ok(Furniture.check(wallet, "Shelf", 0) == "unknown", "a starter piece is never sold")
	ok(next(Furniture.settable({ Shelf = 1 })) == nil, "a starter in the bought counts is ignored")
	ok(next(Furniture.boxed({ Shelf = 1 }, {})) == nil, "nor boxed as bought")
	ok(#Furniture.Pieces == 8, "the counter still sells its eight")
	local rows = {
		{ id = "Shelf:Furniture#1", on = "Floor", x = 0, y = 0, turn = 0 },
		{ id = "CampBed:Furniture#1", on = "Floor", x = 0, y = 0, turn = 0 },
		{ id = "Teddy#1", on = "Floor", x = 0, y = 0, turn = 0 },
	}
	ok(Spots.setOut(rows) == 2, "a starter piece doesn't count against the limit")
	ok(Spots.spot("Mirror:Furniture") == "Floor", "the starter pieces stand on the floor")
end

-- The shelf's and the job box's tops as pieces are the tops they were fixed, so finds stay put;
-- the rug takes what stands on the floor.
do
	local area = Spots.pieceTop("Shelf")
	local old = Spots.furnitureTop({ 7, 0.2, 1.4 }, { 0, 5, 0 })
	ok(area ~= nil and area.kind == Spots.Kinds.Top, "the shelf offers a top")
	ok(area ~= nil and area.width > 1 and old.kind == area.kind, "a top a find fits")
	local lid = Spots.pieceTop("JobBox")
	ok(lid ~= nil and lid.kind == Spots.Kinds.Top, "the job box's lid is a top")
	local rug, at = Spots.pieceTop("Rug")
	ok(rug ~= nil and rug.kind == Spots.Kinds.Floor and near(rug.width, 8), "the rug is floor")
	ok(at ~= nil and near(at[1], 0) and at[2] < 0.1, "flat underfoot")
	local shape = Spots.shape("Beanbag:Furniture", Spots.pieceBox("Beanbag"))
	ok(table.find(shape.fits, rug and rug.kind or "") ~= nil, "the beanbag fits on the rug")
end

-- Each size's layout: Brix takes every row, job box first; nothing stands mid-room.
for _, size in Sizes.Names do
	local room = roomOf(size)
	local rows = Layout.default(room)
	ok(rows[1] and rows[1].id == Layout.id("JobBox"), `{size}: the job box first`)
	local refused = judge(room, rows)
	ok(#refused == 0, `{size}: Brix takes it all ({table.concat(refused, ", ")})`)
	local floor = room.Floor
	for _, row in rows do
		local kind = Layout.kind(row.id) :: string
		if row.on ~= "Floor" or kind == "Rug" then
			continue
		end
		local box = Spots.pieceBox(kind) :: { number }
		local t = math.rad(row.turn)
		local c, s = math.abs(math.cos(t)), math.abs(math.sin(t))
		local hx, hy = (box[1] * c + box[3] * s) / 2, (box[1] * s + box[3] * c) / 2
		local fromWall = math.min(
			floor.width / 2 - (row.x + hx),
			(row.x - hx) + floor.width / 2,
			(row.y - hy) + floor.depth / 2
		)
		ok(fromWall <= Layout.Touch, `{size}: the {kind} stands against a wall ({fromWall})`)
	end
	local shelf = find(rows, "Shelf")
	ok(shelf ~= nil and near(shelf.x, 0) and shelf.turn == 0, `{size}: shelf centred, to the door`)
	if size == "Small" then
		ok(#rows == 3 and find(rows, "Mirror") ~= nil, "small: the shelf, the box and the mirror")
		ok(find(rows, "Rug") == nil and find(rows, "Rail") == nil, "small: the rest in the box")
	else
		ok(#rows == #Layout.Order, `{size}: all seven`)
		local bag = find(rows, "Beanbag")
		ok(bag ~= nil and bag.on == Layout.id("Rug"), `{size}: the beanbag on the rug`)
	end
end

-- A home laid before: XL's pieces where they stood, finds on the tops moved onto the pieces.
do
	local room = roomOf("XL")
	local saved: { Save.PlacedRow } = {
		{ id = "Teddy#1", on = "ShelfTop", x = 1, y = 0.2, turn = 0 },
		{ id = "BlobLamp#1", on = "JobBoxTop", x = 0, y = 0, turn = 90 },
		{ id = "Skates#1", on = "Floor", x = -6, y = 10, turn = 0 },
		{ id = "Shelf:Furniture#1", on = "Floor", x = 0, y = 0, turn = 0 }, -- never twice
	}
	local rows = Layout.adopt(saved, room)
	local stood = Layout.stood(room.Floor)
	local shelf = find(rows, "Shelf")
	ok(
		shelf ~= nil and near(shelf.x, stood.Shelf[1]) and near(shelf.y, stood.Shelf[2]),
		"XL: the shelf where it stood"
	)
	local box = find(rows, "JobBox")
	ok(box ~= nil and near(box.y, stood.JobBox[2]) and box.turn == 90, "XL: the box where it stood")
	local bag = find(rows, "Beanbag")
	ok(bag ~= nil and bag.on == Layout.id("Rug"), "XL: the beanbag on the rug it stood on")
	local n = 0
	for _, row in rows do
		if row.id == "Shelf:Furniture#1" then
			n += 1
		end
		if row.id == "Teddy#1" then
			ok(
				row.on == "Shelf:Furniture#1" and row.x == 1 and row.y == 0.2,
				"the teddy rides the shelf"
			)
		elseif row.id == "BlobLamp#1" then
			ok(row.on == "JobBox:Furniture#1" and row.turn == 90, "the lamp rides the job box")
		end
	end
	ok(n == 1, "the shelf once")
	ok(rows[1].id == Layout.id("JobBox"), "the job box first")
	ok(#judge(room, rows) == 0, "Brix takes the adopted XL home whole")
	ok(#saved == 4 and saved[1].on == "ShelfTop", "the saved rows untouched")
end

-- At Small nothing stood inside: it takes Small's layout; the finds on the tops come along.
do
	local room = roomOf("Small")
	local rows = Layout.adopt({ { id = "Teddy#1", on = "ShelfTop", x = 0, y = 0, turn = 0 } }, room)
	local def = Layout.default(room)
	ok(#rows == #def + 1, "small: its layout and the teddy")
	for i, row in def do
		ok(rows[i].id == row.id and near(rows[i].x, row.x), `small: {row.id} as the layout has it`)
	end
	ok(#judge(room, rows) == 0, "Brix takes the adopted small home whole")
end

-- Growing: Small's pieces ride their walls into Medium; a find stays where it was in the unit.
do
	local small, medium = roomOf("Small"), roomOf("Medium")
	local rows = Layout.default(small)
	table.insert(rows, { id = "Teddy#1", on = "Shelf:Furniture#1", x = 1, y = 0, turn = 0 })
	table.insert(rows, { id = "Skates#1", on = "Floor", x = 0, y = 3, turn = 0 })
	local grown = Layout.grow(rows, small, medium)
	local shelf = find(grown, "Shelf") :: Save.PlacedRow
	local was = find(rows, "Shelf") :: Save.PlacedRow
	ok(
		near(shelf.y + medium.Floor.depth / 2, was.y + small.Floor.depth / 2),
		"the shelf rides back"
	)
	local box = find(grown, "JobBox") :: Save.PlacedRow
	local boxWas = find(rows, "JobBox") :: Save.PlacedRow
	ok(near(medium.Floor.width / 2 - box.x, small.Floor.width / 2 - boxWas.x), "the box rides left")
	local mirror = find(grown, "Mirror") :: Save.PlacedRow
	local mirrorWas = find(rows, "Mirror") :: Save.PlacedRow
	ok(
		near(mirror.x + medium.Floor.width / 2, mirrorWas.x + small.Floor.width / 2),
		"the mirror too"
	)
	ok(grown[4].on == "Shelf:Furniture#1" and grown[4].x == 1, "the teddy rides its shelf")
	local skates = grown[5]
	local dz = medium.Floor.origin[3] - small.Floor.origin[3]
	ok(near(skates.x, 0) and near(skates.y, 3 + dz), "the skates keep their place in the unit")
	ok(#judge(medium, grown) == 0, "Brix takes the grown home whole")
end

-- What's settable and what's in the box count every starter piece, one each (S5-03i1b).
do
	local can = Layout.settable({ MilkCrate = 2, Shelf = 3 })
	ok(can["MilkCrate:Furniture"] == 2, "bought furniture as owned")
	ok(can["Shelf:Furniture"] == 1 and can["JobBox:Furniture"] == 1, "a starter piece, one each")
	local boxed = Layout.boxed({ MilkCrate = 2 }, {
		["MilkCrate:Furniture"] = 1,
		["JobBox:Furniture"] = 1,
		["Shelf:Furniture"] = 1,
		["Mirror:Furniture"] = 1,
	})
	ok(boxed.MilkCrate == 1, "a crate left in the box")
	ok(boxed.Shelf == nil and boxed.JobBox == nil, "a piece set out isn't in the box")
	ok(boxed.Rug == 1 and boxed.Rail == 1 and boxed.FloorLamp == 1, "Small's leftovers are")
	local rows: { Save.PlacedRow } = {
		{ id = "Teddy#1", on = "Floor", x = 0, y = 0, turn = 0 },
		{ id = "JobBox:Furniture#1", on = "Floor", x = 1, y = 0, turn = 90 },
		{ id = "Lamp#1", on = "JobBox:Furniture#1", x = 0, y = 0, turn = 0 },
	}
	local first = Layout.boxFirst(rows)
	ok(first[1].id == "JobBox:Furniture#1" and first[2].id == "Teddy#1", "the job box loads first")
	ok(first[3].id == "Lamp#1" and #first == 3, "the rest keep their order")
end

-- The mirror leans on a wall (S5-03i1c, D-348): it stands only on the floor with its back to the
-- back wall or a side wall at its lean; carried near one it turns its back to it and settles.
do
	local function mirrorIn(rows: { Save.PlacedRow }): Save.PlacedRow?
		for _, row in rows do
			if Layout.kind(row.id) == "Mirror" then
				return row
			end
		end
		return nil
	end
	for _, size in Sizes.Names do
		local room = roomOf(size)
		local m = mirrorIn(Layout.default(room))
		ok(m ~= nil and Layout.stands("Mirror", m :: any, room.Floor), `{size}'s mirror leans`)
	end
	local small, medium, xl = roomOf("Small"), roomOf("Medium"), roomOf("XL")
	local floor = small.Floor
	local m = mirrorIn(Layout.default(small)) :: Save.PlacedRow
	ok(not Layout.stands("Mirror", { on = "Floor", x = 0, y = 0, turn = 270 }, floor), "mid-room")
	ok(not Layout.stands("Mirror", { on = "Floor", x = m.x, y = m.y, turn = 180 }, floor), "door")
	ok(
		not Layout.stands("Mirror", { on = "Rug:Furniture#1", x = m.x, y = m.y, turn = 270 }, floor),
		"on the rug it leans on nothing"
	)
	ok(
		not Layout.stands("Mirror", { on = "Floor", x = m.x - 0.5, y = m.y, turn = 270 }, floor),
		"pushed into its wall"
	)
	ok(
		not Layout.stands("Mirror", { on = "Floor", x = m.x, y = m.y, turn = 90 }, floor),
		"backwards"
	)
	ok(Layout.leanTo("Mirror", { on = "Floor", x = 0, y = 0, turn = 0 }, xl.Floor) == nil, "far")
	-- carried by the right wall, turned the wrong way, flush: it turns and stands off at its lean
	local right = Layout.leanTo("Mirror", { on = "Floor", x = -3.9, y = 1, turn = 0 }, floor)
	ok(right ~= nil and right.turn == 270 and near(right.x, m.x), "the right wall: turned, leant")
	ok(right ~= nil and near(right.y, 1) and Layout.stands("Mirror", right, floor), "and stands")
	local left = Layout.leanTo("Mirror", { on = "Floor", x = 3.5, y = 0.5, turn = 270 }, floor)
	ok(left ~= nil and left.turn == 90 and Layout.stands("Mirror", left, floor), "the left wall")
	local back = Layout.leanTo("Mirror", { on = "Floor", x = 3.5, y = -3.7, turn = 90 }, floor)
	ok(back ~= nil and back.turn == 0 and Layout.stands("Mirror", back, floor), "the back wall")
	local box = Spots.pieceBox("Mirror") :: { number }
	ok(back ~= nil and near(back.x, floor.width / 2 - box[1] / 2), "kept inside the floor")
	ok(
		Layout.leanTo("Mirror", { on = "Rug:Furniture#1", x = 0, y = 0, turn = 0 }, floor) == nil,
		"rug"
	)
	-- the near door: nearest the front wall, it goes to the nearest side wall instead
	local front = Layout.leanTo("Mirror", { on = "Floor", x = -3, y = 3.8, turn = 0 }, floor)
	ok(front ~= nil and front.turn == 270 and Layout.stands("Mirror", front, floor), "not the door")
	-- anything else stands anywhere Brix lets it, and is carried as it is
	local p = { on = "Floor", x = 0, y = 0, turn = 180 }
	ok(Layout.stands("Shelf", p, floor) and Layout.leanTo("Shelf", p, floor) == p, "not leaning")
	-- growing keeps it leaning, and an XL home laid before adopts it leaning where it stood
	local grown = mirrorIn(Layout.grow(Layout.default(small), small, medium))
	ok(grown ~= nil and Layout.stands("Mirror", grown :: any, medium.Floor), "grown, it leans")
	local adopted = mirrorIn(Layout.adopt({}, xl))
	ok(adopted ~= nil and Layout.stands("Mirror", adopted :: any, xl.Floor), "adopted, it leans")
end

-- The job box keeps its lid's room (S5-03i1c, D-348): its back stands at least `BoxOff` off the
-- wall behind it; pushed nearer in Arrange it stops at that line.
do
	local function boxIn(rows: { Save.PlacedRow }): Save.PlacedRow
		for _, row in rows do
			if Layout.kind(row.id) == "JobBox" then
				return row
			end
		end
		error("no job box")
	end
	for _, size in Sizes.Names do
		local room = roomOf(size)
		ok(Layout.stands("JobBox", boxIn(Layout.default(room)) :: any, room.Floor), `{size}'s box`)
		ok(
			Layout.stands("JobBox", boxIn(Layout.adopt({}, room)) :: any, room.Floor),
			`{size} adopted`
		)
	end
	local floor = roomOf("Small").Floor
	local deep = (Spots.pieceBox("JobBox") :: { number })[3]
	local flushX = floor.width / 2 - deep / 2 -- turned 90, its back on the left wall
	local flush = { on = "Floor", x = flushX, y = 0, turn = 90 }
	ok(not Layout.stands("JobBox", flush, floor), "flush on the left wall: no room for the lid")
	local pushed = Layout.clearOf("JobBox", flush, floor)
	ok(near(pushed.x, flushX - Layout.BoxOff) and pushed.y == 0, "pushed out to the line")
	ok(Layout.stands("JobBox", pushed, floor), "and stands there")
	local door = { on = "Floor", x = 0, y = floor.depth / 2 - deep / 2, turn = 180 }
	ok(not Layout.stands("JobBox", door, floor), "its back on the door")
	ok(near(Layout.clearOf("JobBox", door, floor).y, door.y - Layout.BoxOff), "pushed off the door")
	local back = { on = "Floor", x = 0, y = -floor.depth / 2 + deep / 2, turn = 0 }
	ok(near(Layout.clearOf("JobBox", back, floor).y, back.y + Layout.BoxOff), "off the back wall")
	local right = { on = "Floor", x = -flushX, y = 0, turn = 270 }
	ok(near(Layout.clearOf("JobBox", right, floor).x, -flushX + Layout.BoxOff), "off the right")
	local mid = { on = "Floor", x = 0, y = 0, turn = 90 }
	ok(Layout.stands("JobBox", mid, floor) and Layout.clearOf("JobBox", mid, floor) == mid, "mid")
	ok(Layout.clearOf("Shelf", flush, floor) == flush, "only the box keeps clear")
end

print(`layout: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
