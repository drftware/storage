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
-- the ladder by its whole collapsed box (both sections), as Deals lays it
for _, key in { "BoltCutters", "Padlock", "Ladder" } do
	local part = if key == "Ladder" then "Bounds" else "Body"
	table.insert(
		items,
		{ name = key, thing = "Tool", size = sizeOf(`src/shared/Tools/Specs/{key}.luau`, part) }
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

-- The stretch of a side wall the crawl hole and its fallen panel take, as Deals works it out:
-- along from the curtain plane, the hole or the panel's ends, 0.2 more each way.
local holeText = fs.readFile("src/shared/StorageUnit/CrawlHole/Specs.luau")
local holeFrom = number(holeText, "\n%s*From = ([%d%.]+)")
local holeTo = number(holeText, "\n%s*To = ([%d%.]+)")
local panelZ = number(holeText, "Panel_Pos = {%s*Size = Vector3%.new%([^,]+, [^,]+, ([%d%.]+)%)")
local panelC = number(
	holeText,
	"Panel_Pos = {%s*Size = Vector3%.new%([^)]+%),%s*Centre = Vector3%.new%([^,]+, [^,]+, ([%d%.]+)%)"
)
local stretchFrom = math.min(holeFrom, panelC - panelZ / 2) - 0.2
local stretchTo = math.max(holeTo, panelC + panelZ / 2) + 0.2
ok(stretchFrom > 3 and stretchTo < 7.5, "the crawl hole's stretch read from its Specs")
local onHole = { S = 0, M = 0 } :: { [string]: number }
local laidCount = { S = 0, M = 0 } :: { [string]: number }

-- The hole a saw cuts in a unit's top and where its cut-out panel falls, as Deals works them out
-- from the top hole's Specs: the landing under the hole's middle, the panel's box 0.2 bigger all
-- round. The hole's frame starts `Channel` back from the doorway's outer face.
local topText = fs.readFile("src/shared/StorageUnit/TopHole/Specs.luau")
local topLeft = number(topText, "\n\tLeft = ([%-%d%.]+)")
local topRight = number(topText, "\n\tRight = ([%-%d%.]+)")
local topFront = number(topText, "\n\tFront = ([%-%d%.]+)")
local topBack = number(topText, "\n\tBack = ([%-%d%.]+)")
local fellAcross, fellAlong, fellX, fellZ = string.match(
	topText,
	"PanelEdge = {%s*Size = Vector3%.new%(([%-%d%.]+), [^,]+, ([%-%d%.]+)%),"
		.. "%s*Centre = Vector3%.new%(([%-%d%.]+), [^,]+, ([%-%d%.]+)%)"
)
ok(
	topRight - topLeft > 2 and topBack - topFront > 2 and fellAcross ~= nil,
	"the top hole and its fallen panel read from their Specs"
)
local onPanel = { S = 0, M = 0 } :: { [string]: number }
local onLanding = { S = 0, M = 0 } :: { [string]: number }
local everything = { S = 0, M = 0 } :: { [string]: number }

for _, size in { "S", "M" } do
	local spec = fs.readFile(`src/shared/StorageUnit/Specs/{size}.luau`)
	local plane = number(spec, "\n\tCurtainPlane = ([%d%.]+)")
	local channel = number(topText, `Channel = \{[^}]*{size} = ([%d%.]+)`)
	local landing = { x = (topLeft + topRight) / 2, z = channel + (topFront + topBack) / 2 }
	local unit: DealSpot.Unit = {
		width = number(spec, "\n\tWidth = ([%d%.]+)"),
		depth = number(spec, "\n\tDepth = ([%d%.]+)"),
		doorWidth = number(spec, "\n\tDoorWidth = ([%d%.]+)"),
		hole = { from = stretchFrom + plane, to = stretchTo + plane },
		landing = landing,
		fallen = DealSpot.footprint(
			assert(tonumber(fellX)),
			assert(tonumber(fellZ)) + channel,
			0,
			assert(tonumber(fellAcross)) + 0.4,
			assert(tonumber(fellAlong)) + 0.4
		),
	}
	local zones = DealSpot.holes(unit)
	ok(#zones == 2, `{size}: a hole spot on each side wall`)
	-- the floor kept clear under the top's hole: a body 2 across by 1 deep standing under the
	-- hole's middle, with room to spare, and every step from there to the door's line
	local land = DealSpot.landing(unit)
	ok(#land == 1, `{size}: a landing under the top's hole`)
	local body = DealSpot.footprint(landing.x, landing.z, 0, 2, 1)
	local path = DealSpot.footprint(landing.x, (landing.z + DealSpot.Door) / 2, 0, 2, 1)
	ok(
		land[1] ~= nil
			and DealSpot.near(body, land[1], -0.3)
			and DealSpot.near(path, land[1], -0.3)
			and landing.z - 0.5 > plane
			and landing.z + DealSpot.LandBack < unit.depth / 2,
		`{size}: the landing holds a body under the hole and the step to the door, in front of the bulb`
	)
	local fallen = assert(unit.fallen)
	local side, back = unit.width / 2 - DealSpot.Wall, unit.depth - DealSpot.Wall
	for _, item in items do
		local seen: { [string]: boolean } = {}
		local distinct = 0
		for n = 100, 399 do
			local label = tostring(n)
			local noteX = NoteSpot.inUnit(unit.depth, label).x
			for pass = 1, 2 do
				local note: number? = if pass == 2 then noteX else nil
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
				-- off both side walls' hole spots: always for a tool, and for anything in a
				-- medium unit; a small unit's find or keeper may stand on one behind the bulb
				local clear = not DealSpot.near(poly, zones[1], 0)
					and not DealSpot.near(poly, zones[2], 0)
				if item.thing ~= "Tool" then
					laidCount[size] += 1
					if not clear then
						onHole[size] += 1
					end
				end
				-- the ladder spans a small unit wall to wall, so there it lies over a hole spot
				-- (the rule's own fallback: nowhere else fits)
				local wide = item.name == "Ladder" and size == "S"
				if (item.thing == "Tool" and not wide) or size == "M" then
					ok(clear, `{where}: off the crawl hole spots`)
				end
				-- nothing where someone dropping in through the top lands, or between there and
				-- the door; nor where the top's cut-out panel falls
				everything[size] += 1
				if DealSpot.near(poly, land[1], 0) then
					onLanding[size] += 1
				end
				ok(
					not DealSpot.near(poly, land[1], 0),
					`{where}: off the landing under the top's hole`
				)
				if DealSpot.near(poly, fallen, 0) then
					onPanel[size] += 1
				end
				if size == "M" then
					ok(
						not DealSpot.near(poly, fallen, 0),
						`{where}: not where the top's panel falls`
					)
				end
				ok(nearest >= DealSpot.Door - 1e-9, `{where}: clear of the door's line`)
				local farthest = -math.huge
				for i = 2, #poly, 2 do
					farthest = math.max(farthest, poly[i])
				end
				-- the ladder is too long for the bulb's pool clear of the hole spots: it lies
				-- deeper, big enough to read anywhere (the pool keeps small tools from a smear)
				local from, to = DealSpot.From[item.thing], DealSpot.To[item.thing]
				if item.name == "Ladder" then
					from, to = 0, 1
				end
				-- a small unit's pool is mostly the landing and the holes' spots, so a tool too
				-- long for what's left of it lies deeper, clear of them all (still nearer the
				-- door than a medium unit's pool reaches)
				local deeper = size == "S"
					and item.thing == "Tool"
					and clear
					and not DealSpot.near(poly, fallen, 0)
				ok(
					deeper
						or (
							nearest >= from * unit.depth - 1e-9
							and farthest <= to * unit.depth + 1e-9
						),
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
		-- a small unit's tool keeps off both hole spots, the landing and where the top's panel
		-- falls, which leaves it a patch by the door and a strip up the middle: the bolt cutters
		-- have four places there, and the ladder, wall to wall, just the one; a find loses a
		-- place or two behind the bulb to the top's panel
		local least = if size == "S" and item.name == "Ladder"
			then 1
			elseif size == "S" and item.thing == "Tool" then 4
			elseif size == "S" then 10
			else 12
		ok(distinct >= least, `{size} {item.name}: varied unit to unit ({distinct} spots)`)
	end

	-- The Packrat's unit (S2-06b2b): it stands at the back, nearer its middle than wherever the
	-- unit's own spot would be, and a pile of the three biggest finds lies round its feet, clear
	-- of it and of each other, every one inside the unit. A small unit has room at the back for
	-- it and one big find, so the deal puts it in a medium one (Deal.packratUnits).
	local finds: { Item } = {}
	for _, item in items do
		if item.thing == "Find" and item.name ~= "Teddy" then
			table.insert(finds, item)
		end
	end
	local backMiddle = { 0, unit.depth }
	for n = 100, 399 do
		local label = tostring(n)
		local note = nil -- never a note's unit (Deal.packratUnits)
		local where = `{size} Packrat unit {label}`
		local spot = DealSpot.inUnit(unit, "Keeper", DealSpot.Packrat, note, label, nil, backMiddle)
		local own = DealSpot.inUnit(unit, "Keeper", DealSpot.Packrat, note, label)
		ok(spot ~= nil and own ~= nil, `{where}: it stands somewhere`)
		if not (spot and own) then
			continue
		end
		local function far(s: DealSpot.Spot): number
			return (s.x - backMiddle[1]) ^ 2 + (s.z - backMiddle[2]) ^ 2
		end
		ok(far(spot) <= far(own) + 1e-9, `{where}: at the back`)
		local ahead = { x = spot.x, z = spot.z - DealSpot.PackratAhead, yaw = spot.yaw }
		local taken = { DealSpot.around(ahead, DealSpot.Packrat) }
		local feet = { spot.x, spot.z - DealSpot.PackratAhead - DealSpot.Packrat.along }
		local body = DealSpot.footprint(ahead.x, ahead.z, ahead.yaw, 2.72, 2.48) -- as measured
		local piled = 0
		for _, find in finds do
			local at = DealSpot.inUnit(unit, "Find", find.size, note, label, taken, feet)
			if at then
				piled += 1
				local poly =
					DealSpot.footprint(at.x, at.z, at.yaw, find.size.across, find.size.along)
				ok(not DealSpot.near(poly, body, 0.3), `{where}: its {find.name} clear of it`)
				for i = 1, #poly, 2 do
					ok(
						math.abs(poly[i]) <= side + 1e-9 and poly[i + 1] <= back + 1e-9,
						`{where}: its {find.name} inside the unit`
					)
				end
				table.insert(taken, DealSpot.around(at, find.size))
			end
		end
		local least = if size == "S" then 1 else 3
		ok(piled >= least, `{where}: {least} of its pile laid, got {piled}`)
	end
end

-- a small unit is tight: say how often its finds and keepers stand on a hole spot
print(
	`dealspot: {onHole.S} of {laidCount.S} small-unit spots on a crawl hole spot (finds, keepers)`
)
print(
	`dealspot: {onPanel.S} of {everything.S} small-unit spots where the top's panel falls, {onLanding.S} on the landing`
)
if failures > 0 then
	print(`dealspot: {failures} of {checks} checks failed`)
	error("dealspot spec failed")
end
print(`dealspot: {checks} checks passed`)
