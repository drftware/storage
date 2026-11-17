--!strict
-- lune run tests/spots.spec
-- Finds set out in your home (S5-03e2): each find's spot and footprint from its art, a default
-- for one not listed, the room's areas from its XL box, the starter set's tops, the limit by size,
-- ids, a screen's asks checked, and saved rows trimmed to what you own.
local Brix = require("../vendor/brix/src")
local HomeSpecs = require("../src/shared/Home/Specs")
local Save = require("../src/shared/Save")
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
local function has(list: { string }, v: string): boolean
	return table.find(list, v) ~= nil
end

-- Each find's spot: listed ones as listed, a Gold as its find, anything else a Tabletop.
do
	ok(Spots.spot("NeonSign") == "Wall", "a neon sign hangs on a wall")
	ok(Spots.spot("DiscoBall") == "Ceiling", "a disco ball hangs from the ceiling")
	ok(Spots.spot("RCCar") == "Floor", "an RC car stands on the floor")
	ok(Spots.spot("BlobLamp") == "Tabletop", "a lava lamp isn't listed: a Tabletop")
	ok(
		Spots.spot("Teddy:Gold") == "Tabletop" and Spots.spot("Skates:Gold") == "Floor",
		"a Gold as its find"
	)
	ok(Spots.spot("NeverMade") == "Tabletop", "a find nobody listed is a Tabletop")
end

-- Footprints from the art's box: across by front-to-back, across by up on a wall, rounded up.
do
	local lamp = Spots.shape("BlobLamp", { 0.61, 1.62, 0.583 })
	ok(near(lamp.width, 0.65) and near(lamp.depth, 0.6), "a lamp's footprint, up to a twentieth")
	ok(
		has(lamp.fits, "floor") and has(lamp.fits, "top") and #lamp.fits == 2,
		"a Tabletop fits floor and tops"
	)
	ok(lamp.top == nil, "a lamp offers no top")
	local sign = Spots.shape("NeonSign", { 2.4, 1.2, 0.3 })
	ok(near(sign.width, 2.4) and near(sign.depth, 1.2), "a wall find covers across by up")
	ok(#sign.fits == 1 and sign.fits[1] == "wall", "a wall find fits walls alone")
	local thin = Spots.shape("PaperSquishy", { 0.8, 0.05, 0.02 })
	ok(near(thin.depth, Spots.Least), "a flat find still covers a little")
	local unknown = Spots.shape("Mystery", nil)
	ok(near(unknown.width, 1) and near(unknown.depth, 1), "a find with no art: a stud each way")
	local tv = Spots.shape("Television", { 1.62, 2.5, 1.2 })
	local top = tv.top
	ok(
		top ~= nil and top.kind == "top" and near(top.width, 1.42) and near(top.depth, 1.0),
		"a TV's top, its rim kept clear"
	)
	ok(near(Spots.topHeight({ 1.62, 2.5, 1.2 }), 2.5), "its top at its height")
	local again = Spots.shape("BlobLamp", { 0.61, 1.62, 0.583 })
	ok(again.fits ~= lamp.fits, "each shape is its own table")
end

-- The limit by size, and the save holds the biggest.
do
	ok(Spots.limit("Small") == 25 and Spots.limit("Medium") == 50, "small 25, medium 50")
	ok(Spots.limit("Large") == 100 and Spots.limit("XL") == 150, "large 100, XL 150")
	ok(Spots.limit("Huge") == 25, "a size not known: the smallest's")
	ok(Spots.limit(Spots.Start) == 25, "everyone starts small")
	local most = 0
	for _, s in Spots.Sizes do
		most = math.max(most, s.limit)
	end
	ok(most <= Save.PlacedMost, "the save holds every size's limit")
end

-- The room from an XL box (20 across, 10 tall, 29.75 deep, its middle 15.125 in): its floor,
-- ceiling, back and side walls, each face into the room.
do
	local room = Spots.room({ 0, 5, 15.125 }, { 20, 10, 29.75 })
	local floor = room.Floor
	ok(
		floor.kind == "floor" and near(floor.width, 20) and near(floor.depth, 29.75),
		"the floor: across by deep"
	)
	ok(near(floor.origin[2], 0) and floor.normal[2] == 1, "the floor's face up, at the bottom")
	ok(
		room.Ceiling.kind == "ceiling"
			and room.Ceiling.normal[2] == -1
			and near(room.Ceiling.origin[2], 10),
		"the ceiling faces down"
	)
	local back = room.BackWall
	ok(
		back.kind == "wall" and near(back.width, 20) and near(back.depth, 10),
		"the back wall: across by tall"
	)
	ok(
		near(back.origin[3], 30) and back.normal[3] == -1,
		"the back wall at the back, facing the door"
	)
	ok(
		near(room.LeftWall.width, 29.75) and room.LeftWall.normal[1] == -1,
		"a side wall: deep by tall, facing in"
	)
	ok(room.RightWall.normal[1] == 1 and near(room.RightWall.origin[1], -10), "the other side wall")
	ok(room.FrontWall == nil, "the front wall is the door's")
	-- each area's y (normal crossed with across) is square to both, so a pose is a place on it
	for name, a in room do
		local n, x = a.normal, a.across
		local dot = n[1] * x[1] + n[2] * x[2] + n[3] * x[3]
		ok(near(dot, 0), `{name}: across lies in its face`)
	end
	-- a wall's y runs up: normal x across
	local n, x = back.normal, back.across
	local up = n[3] * x[1] - n[1] * x[3]
	ok(near(up, 1), "a wall's y runs up")
	-- Brix takes the room
	local areas: { [string]: Spots.Area } = {}
	for name, a in room do
		areas[name] = { kind = a.kind, width = a.width, depth = a.depth }
	end
	local set = Brix.Placements.new({ areas = areas, limit = Spots.limit("Small") })
	local sign = Spots.shape("NeonSign", { 2.4, 1.2, 0.3 })
	ok(
		set:check("NeonSign#1", sign, { on = "BackWall", x = 0, y = 2, turn = 0 }) == nil,
		"a sign on the back wall"
	)
	ok(
		set:check("NeonSign#1", sign, { on = "Floor", x = 0, y = 0, turn = 0 }) == "wrongArea",
		"a sign on the floor: no"
	)
	local lamp = Spots.shape("BlobLamp", { 0.61, 1.62, 0.583 })
	ok(
		set:check("BlobLamp#1", lamp, { on = "Floor", x = 0, y = 15, turn = 0 }) == "outOfBounds",
		"a lamp in the wall: no"
	)
end

-- The starter set's tops: the shelf's and the job box's, each a top a Tabletop find fits.
do
	local parts = HomeSpecs.Parts
	for name, f in Spots.Furniture do
		local part = parts[f.part]
		ok(part ~= nil, `{name}'s part is in the home's art`)
		if part then
			local area, height = Spots.furnitureTop(part.Size, part.Centre)
			ok(
				area.kind == "top" and area.width > 1 and area.depth > 0.5,
				`{name} is a top a find stands on`
			)
			ok(height > 1, `{name} stands above the floor`)
		end
		local found = false
		for _, s in HomeSpecs.Starter do
			found = found or s.Kind == f.piece
		end
		ok(found, `{name}'s piece is in the starter set`)
	end
	local area, height = Spots.furnitureTop({ 4.52, 0.84, 2.35 }, { 0, 2.32, -0.015 })
	ok(
		near(area.width, 4.32) and near(area.depth, 2.15) and near(height, 2.74),
		"the job box's top"
	)
end

-- Ids: a find's name and a number, the first free one, and back.
do
	ok(Spots.id("Teddy", 2) == "Teddy#2", "Teddy#2")
	ok(Spots.name("Teddy:Gold#3") == "Teddy:Gold", "a Gold's id names the Gold")
	ok(
		Spots.name("Floor") == nil and Spots.name("Teddy#") == nil,
		"an area or a broken id names none"
	)
	local taken = { ["Teddy#1"] = true, ["Teddy#2"] = true }
	ok(Spots.nextId("Teddy", function(id)
		return taken[id] == true
	end) == "Teddy#3", "the first free number")
end

-- A screen's ask: words short, numbers real and near, the turn brought round.
do
	local what, pose = Spots.ask("BlobLamp", "JobBoxTop", 0.5, -0.25, -90)
	ok(
		what == "BlobLamp" and pose ~= nil and pose.on == "JobBoxTop" and near(pose.turn, 270),
		"an ask, its turn brought round"
	)
	local _, whole = Spots.ask("BlobLamp", "Floor", 0, 0, 720)
	ok(whole ~= nil and near(whole.turn, 0), "two whole turns is none")
	ok(Spots.ask("BlobLamp", "Floor", 0 / 0, 0, 0) == nil, "not a number: refused")
	ok(Spots.ask("BlobLamp", "Floor", 1e9, 0, 0) == nil, "far past any area: refused")
	ok(Spots.ask("BlobLamp", "Floor", 0, 0, math.huge) == nil, "an endless turn: refused")
	ok(
		Spots.ask("", "Floor", 0, 0, 0) == nil and Spots.ask(5, "Floor", 0, 0, 0) == nil,
		"no find: refused"
	)
	ok(Spots.ask(string.rep("a", 81), "Floor", 0, 0, 0) == nil, "a name too long: refused")
	ok(Spots.ask("BlobLamp", {}, 0, 0, 0) == nil, "an area that isn't a word: refused")
	ok(Spots.askId("BlobLamp#1") == "BlobLamp#1", "a put-away names a find set out")
	ok(Spots.askId("Floor") == nil and Spots.askId(nil) == nil, "a put-away naming none: refused")
end

-- Saved rows trimmed to what you own: past it, or naming no find, back in the box.
do
	local rows: { Save.PlacedRow } = {
		{ id = "Teddy#1", on = "Floor", x = 0, y = 0, turn = 0 },
		{ id = "Teddy#2", on = "Floor", x = 2, y = 0, turn = 0 },
		{ id = "Boombox#1", on = "Floor", x = 4, y = 0, turn = 0 },
		{ id = "Lamp", on = "Floor", x = 6, y = 0, turn = 0 },
	}
	local kept = Spots.owned(rows, { Teddy = 1, Boombox = 1 })
	ok(
		#kept == 2 and kept[1].id == "Teddy#1" and kept[2].id == "Boombox#1",
		"one teddy and the boombox stay"
	)
	ok(#Spots.owned(rows, {}) == 0, "owning none, nothing stays")
	ok(#rows == 4, "the saved rows are left alone")
end

-- The room's own things (S5-03e2b): the starter pieces on the floor (not the rug), the lamp in the
-- ceiling and the mirror all stand in the small room, never overlapping, and a find set inside the
-- shelf is refused while one beside it stands.
do
	local room = Spots.room({ 0, 5, 15.125 }, { 20, 10, 29.75 })
	local fixed: { Spots.Fixed } = {
		{ id = "Lamp", on = "Ceiling", at = HomeSpecs.Lamp, width = 2.2, depth = 2.2 },
		{ id = "Mirror", on = "RightWall", at = { -9.25, 3.02, 12.5 }, width = 2.84, depth = 6.04 },
		{ id = "MirrorFoot", on = "Floor", at = { -9.25, 0, 12.5 }, width = 1.5, depth = 2.84 },
	}
	local blocks = Spots.blocks(room, HomeSpecs.Starter, HomeSpecs.Pieces, HomeSpecs.Parts, fixed)
	local areas = {}
	for name, r in room do
		areas[name] = { kind = r.kind, width = r.width, depth = r.depth }
	end
	local set = Brix.Placements.new({ areas = areas, limit = 25 + #blocks })
	local ids = {}
	for _, b in blocks do
		ids[b.id] = true
		local refusal = set:place(b.id, b.shape, b.pose)
		ok(refusal == nil, `the room's {b.id} stands ({refusal})`)
		ok(Spots.name(b.id) == nil, `{b.id} is never a find's id`)
	end
	ok(
		ids.Shelf and ids.JobBox and ids.Beanbag and ids.FloorLamp,
		"the starter pieces stand on the floor"
	)
	ok(not ids.Rug, "the rug lies flat: finds stand on it")
	ok(ids.Lamp and ids.Mirror and ids.MirrorFoot, "the lamp and the mirror are the room's")
	local shelf = set:poseOf("Shelf")
	ok(
		shelf ~= nil and math.abs(shelf.x) < 0.01 and math.abs(shelf.y + 0.075) < 0.02,
		"the shelf stands mid-room"
	)
	local lamp = Spots.shape("LavaLamp", { 0.8, 1.6, 0.8 })
	ok(
		set:check("LavaLamp#1", lamp, { on = "Floor", x = 0, y = 0, turn = 0 }) == "overlaps",
		"not inside the shelf"
	)
	ok(
		set:check("LavaLamp#1", lamp, { on = "Floor", x = -4, y = 8, turn = 0 }) == nil,
		"out on the floor"
	)
	ok(
		set:check("LavaLamp#1", lamp, { on = "Ceiling", x = 0, y = 0, turn = 0 }) == "wrongArea",
		"a lamp isn't hung"
	)
	local sign = Spots.shape("NeonSign", { 3, 1.5, 0.3 })
	local mirror = set:poseOf("Mirror")
	ok(
		mirror ~= nil
			and set:check(
					"NeonSign#1",
					sign,
					{ on = "RightWall", x = mirror.x, y = mirror.y, turn = 0 }
				)
				== "overlaps",
		"a sign can't cover the mirror"
	)
end

print(`spots.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
