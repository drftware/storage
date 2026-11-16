--!strict
-- lune run tests/packedwalk.spec
-- A packed unit on the floor (B-05b2, D-216), over 900 unit numbers and a few floors: all it holds
-- stands in its clearing, clear of its stacks; the marked box stands just round the bend and a
-- sleeping keeper wholly out of the path's line; a box and a keeper fit together; and on the
-- keepers' map a keeper walks out of the clearing by the bend and down the path, its body never in
-- a stack, hidden from the hall until it turns into the path.
local Brix = require("../vendor/brix/src")
local DealSpot = require("../src/shared/DealSpot")
local Floor = require("../src/shared/Floor")
local KeeperMap = require("../src/shared/KeeperMap")
local PackedLayout = require("../src/shared/PackedLayout")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

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

local function load(path: string): any -- any: a generated table, read field by field below
	return luau.load(fs.readFile(path), {
		environment = { Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, CFrame = roblox.CFrame },
	})()
end

local Specs = load("src/shared/Packed/Specs.luau")
local Top = load("src/shared/StorageUnit/TopHole/Specs.luau")
local reach: { [string]: PackedLayout.Reach } = {}
for name, block in Specs.Blocks do
	reach[name] = PackedLayout.reachOf(block.Lo, block.Hi)
end
local PITCH: number = Specs.Pitch
local M = Floor.Sizes.M
local BOX: DealSpot.Size = { across = 1.8, along = 1.8, tall = 1.6 } -- the marked box
local COINS: DealSpot.Size = { across = 1.2, along = 1.2, tall = 0.3 }
local P = PackedLayout.Path / 2
local EPS = 1e-6

-- A medium unit as Deals' `shape` gives it, packed by `layout` (the corner's low stack left out).
local function unitOf(layout: PackedLayout.Layout): DealSpot.Unit
	local stacks: { { number } } = {}
	for _, b in layout.blocks do
		if b.name ~= "Half" then
			table.insert(stacks, PackedLayout.footprint(b, reach[b.name]))
		end
	end
	return {
		width = M.width,
		depth = M.depth,
		doorWidth = M.door,
		hole = { from = 4, to = 7.6 },
		landing = { x = 0, z = (Top.Front + Top.Back) / 2 + Top.Channel.M },
		room = layout.clearing,
		stacks = stacks,
		lure = layout.lure,
		nook = layout.nook,
		peek = layout.peek,
		hide = layout.hide,
		face = layout.face,
		walk = layout.walk,
	}
end

-- A sleeper as Deals lays it in a packed unit (D-219), then a box laid after it, behind it
-- (`layNoteBox`, `layCoinBox`): clear of the sleeper and of the path's end, nearest `nook`.
local function sleeperOf(unit: DealSpot.Unit, number: string): DealSpot.Spot?
	return DealSpot.inUnit(unit, "Keeper", DealSpot.Keeper, nil, number, nil, unit.hide, unit.face)
end
local function boxBehind(
	unit: DealSpot.Unit,
	number: string,
	sleeper: DealSpot.Spot
): DealSpot.Spot?
	local taken = { DealSpot.around(sleeper, DealSpot.Keeper), unit.walk :: { number } }
	return DealSpot.inUnit(unit, "Find", BOX, nil, number, taken, unit.nook)
end

local function rectOf(poly: { number }): (number, number, number, number)
	local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
	for i = 1, #poly, 2 do
		x0, x1 = math.min(x0, poly[i]), math.max(x1, poly[i])
		z0, z1 = math.min(z0, poly[i + 1]), math.max(z1, poly[i + 1])
	end
	return x0, x1, z0, z1
end

-- Whether a thing of `size` at `spot` stands in the clearing and clear of every stack.
local function standsWell(unit: DealSpot.Unit, spot: DealSpot.Spot, size: DealSpot.Size): boolean
	local poly = DealSpot.footprint(spot.x, spot.z, spot.yaw, size.across, size.along)
	local x0, x1, z0, z1 = rectOf(unit.room :: { number })
	for i = 1, #poly, 2 do
		local x, z = poly[i], poly[i + 1]
		if x < x0 - EPS or x > x1 + EPS or z < z0 - EPS or z > z1 + EPS then
			return false
		end
	end
	for _, stack in unit.stacks :: { { number } } do
		if DealSpot.near(poly, stack, DealSpot.Stack - EPS) then
			return false
		end
	end
	return true
end

-- 1. What a packed unit holds, over every three-digit number.
local packedUnits = 0
for n = 100, 999 do
	local number = tostring(n)
	local layout = PackedLayout.lay(
		{ width = M.width, depth = M.depth, doorWidth = M.door },
		number,
		reach,
		PITCH
	)
	if not layout then
		continue
	end
	packedUnits += 1
	local unit = unitOf(layout)
	local side = layout.side
	local box = DealSpot.inUnit(unit, "Find", BOX, nil, number)
	ok(box ~= nil, `{number}: the marked box fits in the clearing`)
	if box then
		ok(standsWell(unit, box, BOX), `{number}: the box stands in the clearing, off the stacks`)
		local round = box.x * side
		ok(
			round > P and round < P + 2,
			`{number}: the box stands just round the bend ({box.x}, {box.z})`
		)
		-- a padlocked unit's keeper standing with its find
		local area = DealSpot.around(box, BOX)
		local beside = DealSpot.inUnit(unit, "Keeper", DealSpot.Keeper, nil, number, { area })
		ok(beside ~= nil, `{number}: a keeper fits beside the box ({box.x}, {box.z})`)
		if beside then
			ok(standsWell(unit, beside, DealSpot.Keeper), `{number}: the keeper beside stands well`)
		end
		local coins = DealSpot.inUnit(unit, "Coins", COINS, nil, number, { area })
		ok(coins ~= nil and standsWell(unit, coins, COINS), `{number}: loose coins fit too`)
	end
	-- a box with no guard (B-05b2b): round the corner, but its near edge inside the path's line,
	-- so it shows straight down the path from anywhere in the doorway
	local lone = DealSpot.inUnit(unit, "Find", BOX, nil, number, nil, unit.peek)
	ok(lone ~= nil, `{number}: a lone box fits at the peek`)
	if lone then
		ok(standsWell(unit, lone, BOX), `{number}: the lone box stands well`)
		local near = lone.x * side - BOX.across / 2
		ok(
			near < P - 0.3 and lone.x * side > P,
			`{number}: the lone box peeks into the path's line ({lone.x}, {lone.z})`
		)
	end
	-- a sleeper just round the bend, side-on and facing the path, with the code's note in a box
	-- behind it (D-219)
	local keeper = sleeperOf(unit, number)
	ok(keeper ~= nil, `{number}: a sleeping keeper fits in the clearing`)
	if keeper then
		ok(standsWell(unit, keeper, DealSpot.Keeper), `{number}: the sleeper stands well`)
		ok(keeper.yaw == layout.face, `{number}: the sleeper faces the path ({keeper.yaw})`)
		local body = DealSpot.footprint(
			keeper.x,
			keeper.z,
			keeper.yaw,
			DealSpot.Keeper.across,
			DealSpot.Keeper.along
		)
		local x0, x1 = rectOf(body)
		local nearEdge = math.min(x0 * side, x1 * side)
		ok(
			nearEdge > P - EPS and nearEdge < P + 0.3,
			`{number}: the sleeper stands just out of the path's line ({keeper.x})`
		)
		local note = boxBehind(unit, number, keeper)
		ok(note ~= nil, `{number}: the note's box fits behind the sleeper`)
		if note then
			ok(standsWell(unit, note, BOX), `{number}: the note's box stands well`)
			ok(
				note.x * side > keeper.x * side,
				`{number}: the box is behind the sleeper ({note.x}, {keeper.x})`
			)
		end
	end
end
ok(packedUnits == 900, `every medium number packs ({packedUnits})`)

-- 2. Keepers walk out by the bend, on real floors.
local function toFloor(s: Floor.Slot, ux: number, uz: number): vector
	local fx, fz = Floor.dir(s.facing)
	return vector.create(s.x - fz * ux - fx * uz, 3, s.z + fx * ux - fz * uz)
end
local function toUnit(s: Floor.Slot, p: vector): (number, number)
	local fx, fz = Floor.dir(s.facing)
	local dx, dz = p.x - s.x, p.z - s.z
	return -fz * dx + fx * dz, -fx * dx - fz * dz
end
-- the body a keeper walks with, square so its turn doesn't matter: narrower than the Mannequin's
-- 1.89 by the slack a stack's askew boxes leave
local BODY = 1.6

local walked, legs = 0, 0
for _, seed in { 2000013, 7, 2026, 31337 } do
	for number = 1, 3 do
		local f = Floor.generate(number, Brix.Random.new({ seed = seed }))
		local map = KeeperMap.build(f)
		local packs: { [number]: PackedLayout.Layout } = {}
		for i, s in f.slots do
			if s.kind == "Unit" and s.size == "M" and s.number then
				local layout = PackedLayout.lay(
					{ width = M.width, depth = M.depth, doorWidth = M.door },
					s.number,
					reach,
					PITCH
				)
				if layout then
					local bx, bz = KeeperMap.pack(map, i, layout)
					local want = toFloor(s, layout.bend.x, layout.bend.z)
					ok(
						math.abs(want.x - bx) < 1e-3 and math.abs(want.z - bz) < 1e-3,
						`unit {s.number}: the bend on the map ({bx}, {bz} for {want.x}, {want.z})`
					)
					KeeperMap.setDoor(map, i, true)
					packs[i] = layout
				end
			end
		end
		local walker = KeeperMap.pathing(map)
		for i, layout in packs do
			local s = f.slots[i]
			local number = s.number :: string
			local unit = unitOf(layout)
			local spot = sleeperOf(unit, number)
			if not spot then
				continue
			end
			walked += 1
			-- the code's note or the coins in a box, laid after it as Deals does
			local box = boxBehind(unit, number, spot)
			ok(box ~= nil, `unit {number}: a box fits behind the sleeper`)
			local boxFloor = if box
				then DealSpot.footprint(box.x, box.z, box.yaw, BOX.across, BOX.along)
				else nil
			local from = toFloor(s, spot.x, spot.z)
			local _, slot = KeeperMap.placeAt(map, from)
			ok(slot == i, `unit {number}: the sleeper stands on its own unit's map`)
			local fx, fz = Floor.dir(s.facing)
			local hall = vector.create(s.x + fx * 4, 3, s.z + fz * 4)
			ok(
				not KeeperMap.clear(map, from, hall),
				`unit {number}: the sleeper is hidden from the hall`
			)
			local bend = toFloor(s, layout.bend.x, layout.bend.z)
			ok(KeeperMap.clear(map, bend, hall), `unit {number}: the bend sees out the door`)
			local trip = KeeperMap.trip(walker, from, hall)
			ok(trip ~= nil, `unit {number}: the sleeper has a way out`)
			if not trip then
				continue
			end
			local passed, crossed = false, false
			local at = from
			for _, w in trip do
				if vector.magnitude(vector.create(w.x - bend.x, 0, w.z - bend.z)) < 0.05 then
					passed = true
				end
				local d = vector.create(w.x - at.x, 0, w.z - at.z)
				local steps = math.max(1, math.ceil(vector.magnitude(d) / 0.25))
				for k = 0, steps do
					local p = at + d * (k / steps)
					local ux, uz = toUnit(s, p)
					if uz > 0.5 and uz < M.depth then
						legs += 1
						local body = DealSpot.footprint(ux, uz, 0, BODY, BODY)
						for _, stack in unit.stacks :: { { number } } do
							if DealSpot.near(body, stack, 0) then
								ok(
									false,
									`unit {number}: the walk out crosses a stack at ({ux}, {uz})`
								)
								break
							end
						end
						if boxFloor and DealSpot.near(body, boxFloor, 0) then
							crossed = true
						end
					end
				end
				at = vector.create(w.x, at.y, w.z)
			end
			ok(passed, `unit {number}: the walk out turns at the bend`)
			ok(not crossed, `unit {number}: the sleeper's walk out crosses its box`)
		end
	end
end
ok(walked >= 20, `enough packed units walked ({walked})`)

print(`packedwalk: {checks} checks, {failures} failed, {walked} walks, {legs} body steps`)
if failures > 0 then
	error(`{failures} failed`)
end
