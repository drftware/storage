--!strict
-- lune run tests/dealspot.spec
-- Where the deal lays what a unit holds (L-04e), in both unit sizes, for every tool, find and the
-- keeper's footprint, with the unit's note and without, over 300 unit numbers: always somewhere;
-- on the floor inside the walls and clear of the door's line; tools in the bulb's pool at a
-- dropped angle; finds and keepers wholly behind the bulb, facing the doorway within a small turn;
-- every line from the doorway's eye to the note left clear (checked by walking the lines in 3D, not
-- by the rule's own geometry), so a keeper never stands in front of it; the same unit the same
-- spot; spots varied unit to unit; and the rule's numbers matching the art.
local fs = require("@lune/fs")
local DealSpot = require("../src/shared/DealSpot")
local ElevatorSpecs = require("../src/shared/Elevator/Specs")
local MannequinSpecs = require("../src/shared/Mannequin/Specs")
local NoteSpot = require("../src/shared/Elevator/NoteSpot")

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

-- A thing's size read from generated Specs (they build Vector3s, which Lune lacks).
local function sizeOf(path: string, name: string): DealSpot.Size
	local text = fs.readFile(path)
	local pattern = name .. " = {%s*Size = Vector3%.new%(([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+)%)"
	local x, y, z = string.match(text, pattern)
	return {
		across = assert(tonumber(x), `no {name} in {path}`),
		along = assert(tonumber(z), `no {name}`),
		tall = assert(tonumber(y), `no {name}`),
	}
end

type Item = { name: string, thing: DealSpot.Thing, size: DealSpot.Size }
local items: { Item } = {}
for _, key in { "BoltCutters", "Padlock" } do
	table.insert(
		items,
		{ name = key, thing = "Tool", size = sizeOf(`src/shared/Tools/Specs/{key}.luau`, "Body") }
	)
end
for _, find in { "Boombox", "Television", "Teddy", "Skates" } do
	table.insert(
		items,
		{ name = find, thing = "Find", size = sizeOf("src/shared/Finds/Specs.luau", find) }
	)
end
table.insert(items, { name = "Mannequin", thing = "Keeper", size = DealSpot.Keeper })

-- The rule's numbers match the art: the note as drawn, and the Mannequin standing at rest inside
-- the keeper's footprint.
ok(
	math.abs(DealSpot.NoteHalf - ElevatorSpecs.Note.Side * NoteSpot.Scale / 2) < 0.01,
	"the note's half width is the note's as drawn"
)
local wide, deep = 0, 0
for _, part in MannequinSpecs.Parts do
	wide = math.max(wide, math.abs(part.Centre[1]) + part.Size[1] / 2)
	deep = math.max(deep, math.abs(part.Centre[3]) + part.Size[3] / 2)
end
ok(
	wide * 2 <= DealSpot.Keeper.across
		and deep * 2 <= DealSpot.Keeper.along
		and math.abs(DealSpot.Keeper.tall - MannequinSpecs.Height) < 1e-6,
	"the Mannequin fits the keeper's size"
)
-- Under the line: nothing shorter than Under reaches the note's bottom edge.
ok(
	DealSpot.Under < NoteSpot.Height - DealSpot.NoteHalf,
	"things shorter than Under stay under the note"
)

-- Whether floor point (px, pz) is on a thing at (x, z) turned `yaw`, `across` by `along`.
local function covers(item: Item, spot: DealSpot.Spot, px: number, pz: number): boolean
	local c, s = math.cos(math.rad(spot.yaw)), math.sin(math.rad(spot.yaw))
	local dx, dz = px - spot.x, pz - spot.z
	-- into the thing's own frame: the inverse of CFrame.Angles(0, yaw, 0)
	local lx = dx * c - dz * s
	local lz = dx * s + dz * c
	return math.abs(lx) <= item.size.across / 2 and math.abs(lz) <= item.size.along / 2
end

for _, size in { "S", "M" } do
	local spec = fs.readFile(`src/shared/StorageUnit/Specs/{size}.luau`)
	local unit: DealSpot.Unit = {
		width = number(spec, "\n\tWidth = ([%d%.]+)"),
		depth = number(spec, "\n\tDepth = ([%d%.]+)"),
		doorWidth = number(spec, "\n\tDoorWidth = ([%d%.]+)"),
	}
	local side, back = unit.width / 2 - DealSpot.Wall, unit.depth - DealSpot.Wall
	for _, item in items do
		local seen: { [string]: boolean } = {}
		local distinct = 0
		for n = 100, 399 do
			local label = tostring(n)
			local noteX = NoteSpot.inUnit(unit.depth, label).x
			for _, note: number? in { nil, noteX } :: { number? } do
				local where =
					`{size} {item.name} unit {label}{if note then " with its note" else ""}`
				local spot = DealSpot.inUnit(unit, item.thing, item.size, note, label)
				ok(spot ~= nil, `{where}: laid somewhere`)
				if not spot then
					continue
				end
				local again = DealSpot.inUnit(unit, item.thing, item.size, note, label)
				ok(
					again ~= nil
						and again.x == spot.x
						and again.z == spot.z
						and again.yaw == spot.yaw,
					`{where}: the same unit, the same spot`
				)
				local poly =
					DealSpot.footprint(spot.x, spot.z, spot.yaw, item.size.across, item.size.along)
				local nearest = math.huge
				local inside = true
				for i = 1, #poly, 2 do
					inside = inside
						and math.abs(poly[i]) <= side + 1e-9
						and poly[i + 1] <= back + 1e-9
					nearest = math.min(nearest, poly[i + 1])
				end
				ok(inside, `{where}: inside the walls`)
				ok(nearest >= DealSpot.Door - 1e-9, `{where}: clear of the door's line`)
				local farthest = -math.huge
				for i = 2, #poly, 2 do
					farthest = math.max(farthest, poly[i])
				end
				local from, to = DealSpot.From[item.thing], DealSpot.To[item.thing]
				ok(
					nearest >= from * unit.depth - 1e-9 and farthest <= to * unit.depth + 1e-9,
					`{where}: as deep as its kind lies`
				)
				if item.thing == "Tool" then
					ok(table.find(DealSpot.ToolYaws, spot.yaw) ~= nil, `{where}: lies dropped`)
				else
					ok(nearest >= unit.depth / 2 - 1e-9, `{where}: wholly behind the bulb`)
					local toDoor = math.deg(math.atan2(spot.x, spot.z))
					ok(
						math.abs(spot.yaw - toDoor) <= 8 + 1e-6 or math.abs(spot.yaw) <= 8 + 1e-6,
						`{where}: faces the doorway or straight out, within a small turn`
					)
				end
				if note then
					-- walk every line from a first-person eye anywhere across the doorway to the
					-- note's corners and middle: blocked where the line passes over the thing's
					-- footprint lower than its top
					local blocked = false
					for e = 0, 8 do
						local ex = -unit.doorWidth / 2 + unit.doorWidth * e / 8
						for k = 0, 2 do
							local nx = note - DealSpot.NoteHalf + DealSpot.NoteHalf * k
							for j = 0, 2 do
								local ny = NoteSpot.Height
									- DealSpot.NoteHalf
									+ DealSpot.NoteHalf * j
								for step = 0, 200 do
									local f = step / 200
									local px, pz = ex + (nx - ex) * f, unit.depth * f
									local py = NoteSpot.Height + (ny - NoteSpot.Height) * f
									blocked = blocked
										or (py <= item.size.tall and covers(item, spot, px, pz))
								end
							end
						end
					end
					ok(not blocked, `{where}: the note stays in sight from the doorway`)
				end
				local key = `{spot.x},{spot.z},{spot.yaw}`
				if not seen[key] then
					seen[key] = true
					distinct += 1
				end
			end
		end
		ok(distinct >= 12, `{size} {item.name}: varied unit to unit ({distinct} spots)`)
	end
end

if failures > 0 then
	print(`dealspot: {failures} of {checks} checks failed`)
	error("dealspot spec failed")
end
print(`dealspot: {checks} checks passed`)
