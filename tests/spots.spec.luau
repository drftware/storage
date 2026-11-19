--!strict
-- lune run tests/spots.spec
-- Finds set out in your home (S5-03e2): each find's spot and footprint from its art, a default
-- for one not listed, the room's areas from its XL box, the starter set's tops, the limit by size,
-- ids, a screen's asks checked, and saved rows trimmed to what you own.
local Brix = require("../vendor/brix/src")
local HomeSpecs = require("../src/shared/Home/Specs")
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
	local top = if tv.tops then tv.tops[1] else nil
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

-- The limit bar: finds set out count, the room's own pieces don't; how full, and full at the limit.
do
	local rows: { Save.PlacedRow } = {}
	for _, id in { "BlobLamp#1", "Shelf", "Teddy:Gold#2", "JobBox", "Floor" } do
		table.insert(rows, { id = id, on = "Floor", x = 0, y = 0, turn = 0 })
	end
	ok(Spots.setOut(rows) == 2, "two finds set out among the room's own pieces")
	ok(Spots.setOut({}) == 0, "an empty room: none set out")
	local f, full = Spots.fill(12, 25)
	ok(near(f, 0.48) and not full, "12 of 25: a little under half, not full")
	f, full = Spots.fill(25, 25)
	ok(near(f, 1) and full, "25 of 25: full")
	f, full = Spots.fill(30, 25)
	ok(near(f, 1) and full, "past a lowered limit: full, the bar no further")
	f, full = Spots.fill(0, 25)
	ok(near(f, 0) and not full, "none set out: empty")
	f, full = Spots.fill(0, 0)
	ok(near(f, 1) and full, "a limit of none: full")
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

-- Any angle (S5-03j2b2a): a find set out with Free at 37 degrees passes the server's ask and
-- Brix's judge, which holds it to its footprint turned 37 degrees: what's under the turned
-- corner is taken, what only the square footprint would cover is free, and a save keeps 37.
do
	local what, pose = Spots.ask("RCCar", "Floor", 0, 0, 37)
	ok(what == "RCCar" and pose ~= nil and pose.turn == 37, "an ask at 37 keeps 37")
	local _, part = Spots.ask("RCCar", "Floor", 0, 0, -322.5)
	ok(part ~= nil and near(part.turn, 37.5), "a part degree, brought round")
	local set = Brix.Placements.new({
		areas = { Floor = { kind = Spots.Kinds.Floor, width = 10, depth = 10 } },
		limit = 10,
	})
	local car = Spots.shape("RCCar", { 2, 0.5, 1 }) -- 2 across, 1 front to back
	ok(set:place("RCCar#1", car, pose :: Spots.Pose) == nil, "Brix takes it at 37")
	local kept = set:poseOf("RCCar#1")
	ok(kept ~= nil and kept.turn == 37, "and keeps 37")
	local probe = Spots.shape("Teddy", { 0.05, 0.05, 0.05 })
	local function at(x: number, y: number): Spots.Pose
		return { on = "Floor", x = x, y = y, turn = 0 }
	end
	-- the turned corner reaches (0.50, 1.00); unturned it would stop at y 0.5
	ok(set:check("Teddy#1", probe, at(0.45, 0.95)) == "overlaps", "under the turned corner: taken")
	-- unturned it would cover (0.95, -0.45); turned 37 that's clear of it
	ok(set:check("Teddy#1", probe, at(0.95, -0.45)) == nil, "where only square would reach: free")
	local saved = set:save()
	local again = Brix.Placements.new({
		areas = { Floor = { kind = Spots.Kinds.Floor, width = 10, depth = 10 } },
		limit = 10,
	})
	again:load(saved, function(): Spots.Shape?
		return car
	end)
	local back = again:poseOf("RCCar#1")
	ok(back ~= nil and back.turn == 37, "saved and loaded, still 37")
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

-- The counter's furniture set out (S5-03g4c, D-336): its spot from its row, never a find's of the
-- same name; its box from its parts; a floor footprint with no top; kept up to what you own.
do
	ok(Spots.spot("CampBed:Furniture") == "Floor", "a camp bed stands on the floor")
	ok(Spots.spot("NeonSign:Furniture") == "Wall", "the neon moon hangs on a wall")
	ok(Spots.spot("StringLights:Furniture") == "Ceiling", "the string lights hang from the ceiling")
	local box, mid = Spots.pieceBox("MilkCrate")
	ok(
		box ~= nil and near(box[1], 1.9) and near(box[2], 1.65) and near(box[3], 1.9),
		"a crate's box is its part's"
	)
	ok(mid ~= nil and near(mid[2], 0.825), "a crate's middle stands half its height up")
	local bed = Spots.pieceBox("CampBed")
	ok(
		bed ~= nil and near(bed[1], 6.54) and math.abs(bed[2] - 1.592) < 0.01,
		"a camp bed's box spans its frame and pillow"
	)
	ok(Spots.pieceBox("Teddy") == nil, "no piece: no box")
	local shape = Spots.shape("Pallet:Furniture", Spots.pieceBox("Pallet"))
	ok(
		has(shape.fits, Spots.Kinds.Floor) and not has(shape.fits, Spots.Kinds.Top),
		"a pallet stands only on the floor"
	)
	ok(
		shape.tops ~= nil
			and #shape.tops == 1
			and shape.tops[1].kind == Spots.Kinds.Top
			and near(shape.tops[1].width, 4.2)
			and near(shape.tops[1].depth, 3.4),
		"a pallet offers its top, kept a rim in"
	)
	local kept = Spots.owned({
		{ id = "CampBed:Furniture#1", on = "Floor", x = 0, y = 0, turn = 0 },
		{ id = "CampBed:Furniture#2", on = "Floor", x = 3, y = 0, turn = 0 },
	}, { ["CampBed:Furniture"] = 1 })
	ok(#kept == 1 and kept[1].id == "CampBed:Furniture#1", "only the beds you own stay set out")
end

-- A find on a piece's top (S5-03g4c3, D-338): the crate's, the pallet's, the table's and the
-- shelf's top tier, at the art's own height above the box's foot (the shelf's posts stand above
-- its top tier); the camp bed and the floor cushion are sat on, not set on.
do
	local function top(kind: string): (Spots.Area?, Spots.Vec?)
		return Spots.pieceTop(kind)
	end
	local _, pallet = top("Pallet")
	ok(
		pallet ~= nil and math.abs(pallet[2] - 1.204) < 0.002 and math.abs(pallet[1] - 0.03) < 0.002,
		"the pallet's boards stand 1.2 up, its middle the art's"
	)
	local _, crate = top("MilkCrate")
	ok(crate ~= nil and near(crate[2], 1.65), "a crate's rim stands 1.65 up")
	local _, tableTop = top("FoldingTable")
	ok(tableTop ~= nil and near(tableTop[2], 2.8), "the table's top stands 2.8 up")
	local shelfArea, shelf = top("SteelShelf")
	ok(
		shelf ~= nil and near(shelf[2], 5.9) and shelfArea ~= nil and near(shelfArea.width, 3.32),
		"the shelf's top tier, below its posts' tops"
	)
	ok(top("CampBed") == nil and top("Blanket") == nil, "a bed and a cushion are sat on")
	ok(Spots.shape("CampBed:Furniture", Spots.pieceBox("CampBed")).tops == nil, "no top on a bed")
	ok(top("Teddy") == nil, "no piece: no top")

	-- The save rule: a find riding on the pallet is never lost or doubled as the pallet moves,
	-- saves, loads and goes back to the box.
	local areas = { Floor = { kind = Spots.Kinds.Floor, width = 24, depth = 24 } }
	local function shapeOf(id: string): Brix.PlacementShape?
		local name = Spots.name(id)
		if not name then
			return nil
		end
		local piece = string.match(name, "^(.-):Furniture$")
		return Spots.shape(name, if piece then Spots.pieceBox(piece) else { 0.8, 1.6, 0.8 })
	end
	local set = Brix.Placements.new({ areas = areas, limit = 25 })
	local palletId, lampId = "Pallet:Furniture#1", "MoonLamp#1"
	ok(
		set:place(palletId, shapeOf(palletId) :: any, { on = "Floor", x = 0, y = 0, turn = 0 })
			== nil,
		"the pallet set out"
	)
	ok(
		set:place(lampId, shapeOf(lampId) :: any, { on = palletId, x = 1, y = 0.5, turn = 0 })
			== nil,
		"the moon lamp stands on the pallet"
	)
	ok(
		set:check(
			"Pallet:Furniture#2",
			shapeOf(palletId) :: any,
			{ on = palletId, x = 0, y = 0, turn = 0 }
		) == "wrongArea",
		"no pallet on a pallet"
	)
	ok(
		set:place(palletId, shapeOf(palletId) :: any, { on = "Floor", x = -6, y = 4, turn = 90 })
			== nil,
		"the pallet slides and turns with the lamp on it"
	)
	local lamp = set:poseOf(lampId)
	ok(
		lamp ~= nil and lamp.on == palletId and lamp.x == 1 and lamp.y == 0.5,
		"the lamp rides where it stood"
	)
	ok(set:count() == 2, "nothing doubled by the move")
	local saved = set:save()
	ok(#saved.rows == 2 and saved.rows[1].id == palletId, "saved: the pallet, then its lamp")
	local again = Brix.Placements.new({ areas = areas, limit = 25 })
	local dropped = again:load(saved, shapeOf)
	ok(
		dropped ~= nil and #dropped == 0 and (again:poseOf(lampId) :: any).on == palletId,
		"loaded: the lamp back on the pallet"
	)
	local data = Save.fresh()
	data.furniture = { Pallet = 1 }
	data.finds = { MoonLamp = 1 }
	data.placed = { form = saved.form, rows = saved.rows :: any }
	ok(
		(Save.boxed(data, {}).MoonLamp or 0) == 0 and Spots.setOut(data.placed.rows) == 2,
		"both out of the box while set out"
	)
	ok(again:remove(palletId) == "carrying", "the pallet can't leave its lamp behind")
	for _, rider in again:standingOn(palletId) do
		again:remove(rider)
	end
	ok(again:remove(palletId) == nil and again:count() == 0, "put away: the lamp, then the pallet")
	data.placed = { form = saved.form, rows = again:save().rows :: any }
	ok(
		Save.boxed(data, {}).MoonLamp == 1
			and (Save.placedCounts(data)["Pallet:Furniture"] or 0) == 0,
		"both back in the box, once each"
	)
	-- a pallet you no longer own goes; the lamp on it drops back to the box, never lost
	local owned = Spots.owned(saved.rows :: any, { MoonLamp = 1 })
	local lone = Brix.Placements.new({ areas = areas, limit = 25 })
	local gone = lone:load({ form = saved.form, rows = owned :: any }, shapeOf)
	ok(
		#owned == 1 and gone ~= nil and #gone == 1 and gone[1].id == lampId and lone:count() == 0,
		"no pallet: the lamp drops to the box"
	)
end

-- The lit pieces (S5-03g4d): the string lights hang from the ceiling, the neon moon on a wall,
-- each sized by its art, started on its own surface, and lit by its row in Specs.Glows.
do
	local lights = Spots.shape("StringLights:Furniture", Spots.pieceBox("StringLights"))
	ok(
		#lights.fits == 1 and lights.fits[1] == Spots.Kinds.Ceiling,
		"the string lights fit only the ceiling"
	)
	ok(near(lights.width, 9.65) and near(lights.depth, 0.3), "the lights' run across the ceiling")
	local moon = Spots.shape("NeonSign:Furniture", Spots.pieceBox("NeonSign"))
	ok(#moon.fits == 1 and moon.fits[1] == Spots.Kinds.Wall, "the moon fits only a wall")
	ok(near(moon.width, 2.9) and near(moon.depth, 2.8), "the moon's footprint is across by up")
	ok(Spots.glow("StringLights:Furniture") == HomeSpecs.Glows.StringLights, "the lights glow")
	ok(Spots.glow("NeonSign:Furniture") == HomeSpecs.Glows.NeonSign, "the moon glows")
	ok(Spots.glow("CampBed:Furniture") == nil, "a bed doesn't")
	ok(Spots.glow("NeonSign") == nil, "nor does the find called NeonSign")
	ok(Spots.starts("Floor")[1] == "Floor", "a floor piece starts on the floor")
	ok(Spots.starts("Ceiling")[1] == "Ceiling", "the lights start on the ceiling")
	local walls = Spots.starts("Wall")
	ok(walls[1] == "BackWall" and #walls == 3, "the moon starts on the back wall, facing the door")
	-- in a home, round the ceiling's lamp
	local room = Spots.room({ 0, 5, 14.875 }, { 20, 10, 29.75 })
	local areas = {}
	for name, r in room do
		areas[name] = { kind = r.kind, width = r.width, depth = r.depth }
	end
	local set = Brix.Placements.new({ areas = areas, limit = 25 })
	local lamp = HomeSpecs.Parts.Lamp
	local blocks = Spots.blocks(room, {}, HomeSpecs.Pieces, HomeSpecs.Parts, {
		{
			id = "Lamp",
			on = "Ceiling",
			at = HomeSpecs.Lamp,
			width = lamp.Size[1],
			depth = lamp.Size[3],
		},
	})
	for _, b in blocks do
		set:place(b.id, b.shape, b.pose)
	end
	local on = { on = "Ceiling", x = 0, y = 0, turn = 0 }
	ok(set:check("StringLights:Furniture#1", lights, on) ~= nil, "not through the lamp")
	on.y = 3
	ok(set:place("StringLights:Furniture#1", lights, on) == nil, "the lights strung past the lamp")
	ok(
		set:place("NeonSign:Furniture#1", moon, { on = "BackWall", x = 0, y = 1, turn = 0 }) == nil,
		"the moon hung on the back wall"
	)
	ok(
		set:check("NeonSign:Furniture#2", moon, { on = "Floor", x = 0, y = 0, turn = 0 }) ~= nil,
		"never stood on the floor"
	)
end

-- The four sizes (S5-03h1, D-340): each a box cut from the slot's XL one, its front at the door
-- and centred across; a size not known is the smallest. Rows laid at one size are carried to
-- another: on the floor or the ceiling a find keeps its place in the unit, on a wall it rides with
-- the wall; what the new room doesn't hold is dropped as it loads, back to the box.
do
	ok(#Spots.Sizes == 4 and Spots.Sizes[1].name == "Small", "four sizes, small first")
	ok(Spots.Sizes[4].name == "XL" and Sizes.Biggest == "XL", "XL the biggest")
	ok(Sizes.of("Small").across == 8 and Sizes.of("Small").deep == 8, "small 8 by 8")
	ok(Sizes.of("Medium").across == 12 and Sizes.of("Medium").deep == 12, "medium 12 by 12")
	ok(Sizes.of("Large").across == 16 and Sizes.of("Large").deep == 20, "large 16 by 20")
	ok(Sizes.of("XL").across == 20 and Sizes.of("XL").deep == 30, "XL 20 by 30")
	ok(Sizes.of("Huge").name == "Small", "a size not known: the smallest")
	ok(Sizes.rank("Small") == 1 and Sizes.rank("XL") == 4, "small first, XL last")
	ok(Sizes.rank("Huge") == 1, "a size not known ranks as the smallest")
	ok(Spots.limit("Medium") == Sizes.of("Medium").limit, "each size's limit is its own")
	ok(#Sizes.Names == 4 and Sizes.Names[2] == "Medium", "the names, smallest first")

	local xc, xs = { 0, 5, 15.125 }, { 20, 10, 29.75 }
	local c, s = Sizes.inside("XL", xc, xs)
	ok(
		near(c[1], 0) and near(c[3], 15.125) and near(s[1], 20) and near(s[3], 29.75),
		"XL: the whole slot"
	)
	ok(c ~= xc and s ~= xs, "new tables")
	c, s = Sizes.inside("Small", xc, xs)
	ok(
		near(s[1], 8) and near(s[2], 10) and near(s[3], 7.75),
		"small: 8 across, as tall, 8 in less the door's frame"
	)
	ok(
		near(c[1], 0) and near(c[2], 5) and near(c[3] - s[3] / 2, 0.25),
		"its front at the door, centred across"
	)
	local mc, ms = Sizes.inside("Medium", xc, xs)
	ok(near(ms[1], 12) and near(mc[3] + ms[3] / 2, 12), "medium's back wall 12 in")
	local lc, ls = Sizes.inside("Large", xc, xs)
	ok(near(ls[1], 16) and near(lc[3] + ls[3] / 2, 20), "large's back wall 20 in")
	c, s = Sizes.inside("Huge", xc, xs)
	ok(near(s[1], 8), "a size not known: small's box")

	-- carried from the XL room to the small one
	local xl = Spots.room(xc, xs)
	local small = Spots.room(Sizes.inside("Small", xc, xs))
	ok(near(small.Floor.width, 8) and near(small.BackWall.origin[3], 8), "small's back wall 8 in")
	local rows: { Save.PlacedRow } = {
		{ id = "BlobLamp#1", on = "Floor", x = 1, y = 12.125, turn = 90 }, -- 3 in from the door
		{ id = "BlobLamp#2", on = "Floor", x = 0, y = 0, turn = 0 }, -- the XL room's middle
		{ id = "NeonSign#1", on = "BackWall", x = 1.5, y = 2, turn = 0 }, -- rides the wall in
		{ id = "NeonSign#2", on = "LeftWall", x = -12, y = 1, turn = 0 }, -- 3 in, on the left
		{ id = "NeonSign#3", on = "LeftWall", x = 5, y = 1, turn = 0 }, -- 20 in: past small's wall
		{ id = "Teddy#1", on = "ShelfTop", x = 0.5, y = 0, turn = 0 }, -- the shelf's to carry
	}
	local carried = Spots.carry(rows, xl, small)
	ok(#carried == #rows and carried ~= rows and carried[1] ~= rows[1], "every row, as new tables")
	local lamp = carried[1]
	ok(
		lamp.on == "Floor" and near(lamp.x, 1) and near(lamp.y, 1.125) and lamp.turn == 90,
		"a lamp keeps its place on the floor"
	)
	ok(near(carried[2].y, -11), "the XL middle is 11 past small's back")
	ok(
		near(carried[3].x, 1.5) and near(carried[3].y, 2),
		"a sign on the back wall rides it, as far across and as high"
	)
	ok(
		near(carried[4].x, -1) and near(carried[4].y, 1),
		"a sign on a side wall keeps how far in it hangs"
	)
	ok(near(carried[6].x, 0.5) and carried[6].on == "ShelfTop", "a find on a top is left as it was")
	local back = Spots.carry(carried, small, xl)
	ok(
		near(back[1].y, 12.125) and near(back[2].y, 0) and near(back[4].x, -12),
		"carried back, where it was"
	)

	local areas: { [string]: Spots.Area } = {}
	for name, a in small do
		areas[name] = { kind = a.kind, width = a.width, depth = a.depth }
	end
	areas.ShelfTop = { kind = Spots.Kinds.Top, width = 7, depth = 1.2 }
	local set = Brix.Placements.new({ areas = areas, limit = Spots.limit("Small") })
	local function shapeOf(id: string): Spots.Shape?
		local name = Spots.name(id)
		local box = if name == "NeonSign" then { 2.4, 1.2, 0.3 } else { 0.61, 1.62, 0.583 }
		return if name then Spots.shape(name, box) else nil
	end
	local dropped = set:load({ form = 1, rows = carried }, shapeOf)
	local gone: { string } = {}
	for _, d in dropped or {} do
		table.insert(gone, d.id)
	end
	table.sort(gone)
	ok(
		#gone == 2 and gone[1] == "BlobLamp#2" and gone[2] == "NeonSign#3",
		"what small doesn't hold goes back in the box"
	)
	ok(
		set:poseOf("BlobLamp#1") ~= nil
			and set:poseOf("NeonSign#1") ~= nil
			and set:poseOf("Teddy#1") ~= nil,
		"the rest stays out"
	)

	-- the room's own things a size doesn't hold are left out of it
	local block: Spots.Block = {
		id = "Shelf",
		shape = { width = 7.46, depth = 1.6, fits = { Spots.Kinds.Floor } },
		pose = { on = "Floor", x = 0, y = -0.5, turn = 0 },
	}
	ok(Spots.within(small, block), "a shelf across small's middle stands in it")
	block.pose = { on = "Floor", x = 0, y = -11, turn = 0 }
	ok(not Spots.within(small, block), "one at the XL's back doesn't")
	block.pose = { on = "Floor", x = 0, y = -1, turn = 90 }
	ok(not Spots.within(small, block), "turned and set back, it pokes through the back wall")
	block.pose = { on = "Ceiling", x = 0, y = 0, turn = 0 }
	ok(Spots.within(small, block), "judged on its own area")
	block.pose = { on = "ShelfTop", x = 0, y = 0, turn = 0 }
	ok(not Spots.within(small, block), "an area the room hasn't: no")
end

print(`spots.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
