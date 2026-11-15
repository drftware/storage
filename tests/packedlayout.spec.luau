--!strict
-- lune run tests/packedlayout.spec
-- A packed unit's layout (B-05b1, D-216), over 900 unit numbers: small units stay open; in a medium
-- unit no two stacks run into each other or past the floor's edges; nothing stands in the path,
-- the clearing, the landing under the top's hole or the doorway's 2.5; the bulb hangs over the
-- path; every wall the path, the clearing and the doorway see is stacks with no gap over `Gap`;
-- from anywhere in the doorway the clearing's far side is hidden round the bend; the clearing
-- holds the Packrat; both sides get dealt; and a unit's stacks stay cheap for a phone.
local DealSpot = require("../src/shared/DealSpot")
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

-- The generated Specs build Vector3s, which Lune lacks as a global: load them with Lune's own.
local function load(path: string): any -- any: a generated table, read field by field below
	return luau.load(fs.readFile(path), {
		environment = { Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, CFrame = roblox.CFrame },
	})()
end

local Specs = load("src/shared/Packed/Specs.luau")
local Medium = load("src/shared/StorageUnit/Specs/M.luau")
local Small = load("src/shared/StorageUnit/Specs/S.luau")
local Top = load("src/shared/StorageUnit/TopHole/Specs.luau")

local reach: { [string]: PackedLayout.Reach } = {}
for name, block in Specs.Blocks do
	reach[name] = PackedLayout.reachOf(block.Lo, block.Hi)
end

local function unitOf(spec: any, channel: number): DealSpot.Unit -- any: a generated Specs table
	return {
		width = spec.Width,
		depth = spec.Depth,
		doorWidth = spec.DoorWidth,
		landing = { x = (Top.Left + Top.Right) / 2, z = (Top.Front + Top.Back) / 2 + channel },
	}
end

local medium = unitOf(Medium, Top.Channel.M)
local small = unitOf(Small, Top.Channel.S)

ok(PackedLayout.lay(small, "101", reach, Specs.Pitch) == nil, "a small unit stays open")

local W = medium.width / 2 - DealSpot.Wall
local B = medium.depth - DealSpot.Wall
local F = DealSpot.Door
local P = PackedLayout.Path / 2
local HALF_GAP = PackedLayout.Gap / 2
local TOUCH = -0.01 -- overlapping by more than a hundredth counts as running into it

-- Whether point (x, z) is within `gap` of any of `polys`.
local function nearAny(x: number, z: number, polys: { { number } }, gap: number): boolean
	for _, poly in polys do
		if DealSpot.near({ x, z }, poly, gap) then
			return true
		end
	end
	return false
end

local sides = { [-1] = 0, [1] = 0 }
local mostTris, mostBlocks = 0, 0
for number = 100, 999 do
	local label = `unit {number}`
	local layout = PackedLayout.lay(medium, tostring(number), reach, Specs.Pitch)
	ok(layout ~= nil, `{label}: a medium unit packs`)
	if not layout then
		continue
	end
	local again =
		PackedLayout.lay(medium, tostring(number), reach, Specs.Pitch) :: PackedLayout.Layout
	ok(#again.blocks == #layout.blocks and again.side == layout.side, `{label}: the same twice`)
	sides[layout.side] += 1
	local m = -layout.side -- canonical x (clearing toward -X) to the unit's

	local polys: { { number } } = {}
	local tris = 0
	for i, block in layout.blocks do
		local r = reach[block.name]
		ok(r ~= nil, `{label}: block {i} is a built block ({block.name})`)
		if not r then
			continue
		end
		tris += Specs.Blocks[block.name].Tris
		local poly = PackedLayout.footprint(block, r)
		for k = 1, #poly, 2 do
			local x, z = poly[k], poly[k + 1]
			ok(math.abs(x) <= W + 1e-3, `{label}: {block.name} {i} inside the side walls ({x})`)
			ok(
				z >= F - 1e-3 and z <= B + 1e-3,
				`{label}: {block.name} {i} past the door, short of the back ({z})`
			)
		end
		ok(not DealSpot.near(poly, layout.path, TOUCH), `{label}: {block.name} {i} off the path`)
		-- the low stack in the clearing's far corner is the one block in it (the Packrat's room is
		-- checked below)
		if block.name ~= "Half" then
			ok(
				not DealSpot.near(poly, layout.clearing, TOUCH),
				`{label}: {block.name} {i} off the clearing`
			)
		end
		for _, zone in DealSpot.landing(medium) do
			ok(not DealSpot.near(poly, zone, TOUCH), `{label}: {block.name} {i} off the landing`)
		end
		for j, other in polys do
			ok(
				not DealSpot.near(poly, other, TOUCH),
				`{label}: {block.name} {i} clear of block {j}`
			)
		end
		table.insert(polys, poly)
	end
	mostTris = math.max(mostTris, tris)
	mostBlocks = math.max(mostBlocks, #layout.blocks)

	-- the bulb hangs over the path's middle
	ok(DealSpot.near({ 0, medium.depth / 2 }, layout.path, 0), `{label}: the bulb over the path`)

	-- the clearing's near edge, from the path's rectangle
	local C = layout.path[6]
	local deep = B - C
	ok(deep >= 2.8 and deep <= 3.6, `{label}: the clearing about 3 deep ({deep})`)

	-- the walls: just outside every edge the path, the clearing and the doorway see, a stack
	-- within half the widest gap
	local z = F + 0.05
	while z <= B - 0.05 do
		if z <= C - 0.05 then
			ok(
				nearAny(-(P + 0.1) * m, z, polys, HALF_GAP),
				`{label}: the clearing side's wall at {z}`
			)
		end
		ok(nearAny((P + 0.1) * m, z, polys, HALF_GAP), `{label}: the far side's wall at {z}`)
		z += 0.25
	end
	local x = P + 0.05
	while x <= W - HALF_GAP do
		ok(nearAny(x, F + 0.1, polys, HALF_GAP), `{label}: the doorway's stacks at {x}`)
		ok(nearAny(-x, F + 0.1, polys, HALF_GAP), `{label}: the doorway's stacks at {-x}`)
		x += 0.25
	end
	x = -(P + 0.05)
	while x >= -(W - HALF_GAP) do
		ok(
			nearAny(x * m, C - 0.1, polys, HALF_GAP),
			`{label}: the clearing's near stacks at {x * m}`
		)
		x -= 0.25
	end

	-- round the bend: from every eye across the doorway, the clearing's far side is behind a stack
	for _, eye in { -4, -2, 0, 2, 4 } do
		for _, at in { { -W + 0.5, C + 0.5 }, { -W + 0.5, (C + B) / 2 }, { -W + 1.5, B - 0.5 } } do
			local seen = { eye, 0, at[1] * m, at[2] }
			local hidden = false
			for _, poly in polys do
				if DealSpot.near(seen, poly, 0) then
					hidden = true
					break
				end
			end
			ok(
				hidden,
				`{label}: the clearing at ({at[1] * m}, {at[2]}) hidden from the doorway at {eye}`
			)
		end
	end

	-- the clearing holds the Packrat standing (the biggest sleeper), clear of every stack
	local size = DealSpot.Packrat
	local fits = false
	local cx = -W + size.across / 2
	while cx <= P - size.across / 2 and not fits do
		local spot = DealSpot.footprint(cx * m, (C + B) / 2, 0, size.across, size.along)
		local clear = true
		for _, poly in polys do
			if DealSpot.near(spot, poly, 0) then
				clear = false
				break
			end
		end
		fits = clear
		cx += 0.25
	end
	ok(fits, `{label}: the Packrat fits in the clearing`)

	-- the bend is on the path's middle line, in the clearing's depth
	ok(
		layout.bend.x == 0 and layout.bend.z > C and layout.bend.z < B,
		`{label}: the bend in the clearing`
	)
end

ok(sides[-1] > 300 and sides[1] > 300, `both sides dealt ({sides[-1]}, {sides[1]})`)
-- about twenty blocks at about 5,000 triangles (D-215): never much more on a phone
ok(mostTris <= 6000, `a unit's stacks at most 6,000 triangles ({mostTris})`)
ok(mostBlocks <= 24, `a unit's stacks at most 24 blocks ({mostBlocks})`)

print(
	`packedlayout: {checks - failures}/{checks} checks, most {mostBlocks} blocks, {mostTris} triangles`
)
if failures > 0 then
	error(`{failures} failed`)
end
