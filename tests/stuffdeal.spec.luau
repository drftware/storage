--!strict
-- lune run tests/stuffdeal.spec
-- Somebody's stuff dealt into units (S1-04b2, B-03b), over 200 seeds on floors 1, 3 and 6: about
-- `Deal.StuffShare` of the units with no keeper or note hold one thing, each thing about as often,
-- whatever find a unit holds; never a unit with a keeper or a note; the same seed the same stuff; and
-- every other thing a seed lays and deals is what it was before the stuff (a fingerprint of the
-- deal, taken last as S2-01 placed the sleepers with the floor: it changes only when a ticket means
-- to change the deal).
-- Where it stands, in both unit sizes over 300 unit numbers: back to a wall, inside the floor past
-- the door's line, wholly clear of both crawl hole spots, the landing under the top's hole and
-- where its panel falls, and of a note's sight line; too close to the wall for anyone to squeeze
-- behind; in a medium unit every thing fits, in a small one at least the rolled rug; and laid last
-- (B-03b), wholly clear of the floor the unit's marked box takes, in a medium unit still standing.
local Brix = require("../vendor/brix/src")
local Deal = require("../src/shared/Deal")
local DealSpot = require("../src/shared/DealSpot")
local Floor = require("../src/shared/Floor")
local NoteSpot = require("../src/shared/Elevator/NoteSpot")
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

-- The generated Specs build Vector3s and CFrames, which Lune lacks as globals: load them with
-- Lune's own.
local function load(path: string): any -- any: a generated table, read field by field below
	return luau.load(fs.readFile(path), {
		environment = {
			Vector3 = roblox.Vector3,
			CFrame = roblox.CFrame,
			Color3 = roblox.Color3,
			Vector2 = roblox.Vector2,
		},
	})()
end

local StuffSpecs = load("src/shared/Stuff/Specs.luau")
local Crawl = load("src/shared/StorageUnit/CrawlHole/Specs.luau")
local Top = load("src/shared/StorageUnit/TopHole/Specs.luau")

-- The names: every thing dealt is a piece or a stack, and every piece and stack is dealt.
local sizes: { [string]: DealSpot.Size } = {}
for _, name in Deal.Stuff do
	local spec = StuffSpecs.Pieces[name] or StuffSpecs.Stacks[name]
	ok(spec ~= nil, `{name} is a piece or a stack in Stuff/Specs`)
	if spec then
		sizes[name] = { across = spec.Size.X, along = spec.Size.Z, tall = spec.Size.Y }
	end
end
for _, list in { StuffSpecs.PieceOrder, StuffSpecs.StackOrder } do
	for _, name in list do
		ok(table.find(Deal.Stuff, name) ~= nil, `{name} is dealt`)
	end
end

-- The draw's edges.
ok(Deal.stuffFrom(Deal.StuffShare) == nil, "at the share's edge, a bare unit")
ok(Deal.stuffFrom(0) == Deal.Stuff[1], "the lowest pick is the first thing")
ok(Deal.stuffFrom(Deal.StuffShare - 1e-9) == Deal.Stuff[#Deal.Stuff], "the highest the last")

-- The deal.
local SEEDS = 200
local FLOORS = { 1, 3, 6 }
local BUILD: Deal.Situation = { mood = "Build", awake = 0 }
-- the deal of seeds 1 to 60 since B-04a (a note's unit holds its note, never a find or tool; F-G1a's
-- was 2876030496, S2-06b2b's 2130601506; with the Packrat switched off, S2-01's 3999933310)
local FINGERPRINT = 1444159843
local SEEDS_PRINTED = 60

local print_ = 7
local function feed(s: string)
	for i = 1, #s do
		print_ = (print_ * 131 + string.byte(s, i)) % 4294967291
	end
end

local empty, stuffed = 0, 0 -- units with no keeper or note, and those of them with stuff
local finds, findStuffed = 0, 0
local byName: { [string]: number } = {}
for seed = 1, SEEDS do
	for _, number in FLOORS do
		local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
		local deck = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
		local again = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
		local noted: { [number]: boolean } = {}
		for _, note in deck.notes do
			noted[note.slot] = true
		end
		local printed = seed <= SEEDS_PRINTED
		if printed then
			feed(table.concat(deck.code, ","))
			for _, note in deck.notes do
				feed(`n{note.slot}:{table.concat(note.places, ",")}`)
			end
			feed(`g{deck.guarded}`)
		end
		for _, i in Deal.units(floor) do
			local c = Deal.open(deck, i, BUILD)
			local twin = Deal.open(again, i, BUILD)
			ok(c.stuff == twin.stuff, `seed {seed} floor {number}: the same seed, the same stuff`)
			if printed then
				local lock = if deck.padlocked[i] then "L" else ""
				feed(`{i}{c.kind}{c.tool or ""}{c.find or ""}{c.keeper or ""}{c.beside or ""}`)
				feed(`{c.coins}{lock}`)
			end
			local open = Deal.keeperIn(c) == nil and not noted[i]
			if open then
				empty += 1
				if c.stuff then
					stuffed += 1
					byName[c.stuff] = (byName[c.stuff] or 0) + 1
				end
				if c.kind == "Find" then
					finds += 1
					findStuffed += if c.stuff then 1 else 0
				end
			else
				ok(
					c.stuff == nil,
					`seed {seed}: a unit with a keeper or note holds no stuff ({c.kind})`
				)
			end
		end
	end
end
ok(
	print_ == FINGERPRINT,
	`every seed lays and deals what it did before the stuff ({print_}, was {FINGERPRINT})`
)
local share = stuffed / empty
ok(
	math.abs(share - Deal.StuffShare) < 0.05,
	`about {Deal.StuffShare} of units with no keeper or note hold stuff: {share}`
)
-- the scramble: a find unit's pick chose its find, and its stuff mustn't follow it
ok(
	math.abs(findStuffed / finds - Deal.StuffShare) < 0.08,
	`about {Deal.StuffShare} of find units hold stuff too: {findStuffed / finds}`
)
for _, name in Deal.Stuff do
	local got = (byName[name] or 0) / stuffed
	ok(math.abs(got - 1 / #Deal.Stuff) < 0.05, `{name} in about 1/{#Deal.Stuff} of them: {got}`)
end

-- Where it stands. The unit as Deals measures it (Deals' `shape`).
local HOLE_MARGIN = 0.2
local PANEL = Crawl.Parts.Panel_Pos
local HOLE_FROM = math.min(Crawl.From, PANEL.Centre.Z - PANEL.Size.Z / 2) - HOLE_MARGIN
local HOLE_TO = math.max(Crawl.To, PANEL.Centre.Z + PANEL.Size.Z / 2) + HOLE_MARGIN
local FELL = Top.Parts.PanelEdge

local function unitOf(size: string): DealSpot.Unit
	local spec = load(`src/shared/StorageUnit/Specs/{size}.luau`)
	local channel = Top.Channel[size]
	return {
		width = spec.Width,
		depth = spec.Depth,
		doorWidth = spec.DoorWidth,
		hole = { from = HOLE_FROM + spec.CurtainPlane, to = HOLE_TO + spec.CurtainPlane },
		landing = { x = (Top.Left + Top.Right) / 2, z = (Top.Front + Top.Back) / 2 + channel },
		fallen = DealSpot.footprint(
			FELL.Centre.X,
			FELL.Centre.Z + channel,
			0,
			FELL.Size.X + 2 * HOLE_MARGIN,
			FELL.Size.Z + 2 * HOLE_MARGIN
		),
	}
end

local EPS = 1e-6
local stood = 0
local withBox, boxTries = 0, 0
local boxSpecs = load("src/shared/Boxes/Specs.luau")
local BOX: DealSpot.Size = {
	across = boxSpecs.Marked.Size.X,
	along = boxSpecs.Marked.Size.Z,
	tall = boxSpecs.Marked.Size.Y,
}
for _, size in { "S", "M" } do
	local unit = unitOf(size)
	local side, back = unit.width / 2 - DealSpot.Wall, unit.depth - DealSpot.Wall
	local keep = DealSpot.holes(unit)
	for _, zone in DealSpot.landing(unit) do
		table.insert(keep, zone)
	end
	table.insert(keep, unit.fallen :: { number })
	for n = 100, 399 do
		local label = tostring(n)
		local note = NoteSpot.inUnit(unit.depth, label).x
		for _, name in Deal.Stuff do
			local thing = sizes[name]
			for _, withNote in { false, true } do
				local spot = DealSpot.stuff(unit, thing, if withNote then note else nil, label)
				if size == "M" and not withNote then
					ok(spot ~= nil, `M {label}: the {name} stands against a wall`)
				end
				if size == "S" and name == "Carpet" and not withNote then
					ok(spot ~= nil, `S {label}: the rolled rug stands against a wall`)
				end
				if spot then
					stood += 1
					local poly =
						DealSpot.footprint(spot.x, spot.z, spot.yaw, thing.across, thing.along)
					local inside = true
					for k = 1, #poly, 2 do
						inside = inside
							and math.abs(poly[k]) <= side + EPS
							and poly[k + 1] <= back + EPS
							and poly[k + 1] >= DealSpot.Door - EPS
					end
					ok(inside, `{size} {label}: the {name} is on the floor, past the door`)
					local clear = true
					for _, zone in keep do
						clear = clear and not DealSpot.near(poly, zone, 0)
					end
					ok(clear, `{size} {label}: the {name} keeps off the crawl holes and landing`)
					if withNote and thing.tall >= DealSpot.Under then
						ok(
							not DealSpot.near(poly, DealSpot.sightLine(unit, note), DealSpot.Sight),
							`{size} {label}: the {name} keeps out of the note's sight`
						)
					end
					-- back to a wall, flush: nobody squeezes in behind (a body is 1 deep)
					local yaw = math.round(spot.yaw)
					local backEdge = if yaw == 0
						then spot.z + thing.along / 2 - back
						elseif yaw == 90 then spot.x + thing.along / 2 - side
						elseif yaw == -90 then -side - (spot.x - thing.along / 2)
						else math.huge
					ok(
						math.abs(backEdge) < EPS,
						`{size} {label}: the {name}'s back is flush to a wall (yaw {spot.yaw})`
					)
				end
			end
			-- laid last, round the unit's marked box where a find stands (B-03b)
			local box = DealSpot.inUnit(unit, "Find", BOX, nil, label)
			if box then
				local taken = { DealSpot.around(box, BOX) }
				local spot = DealSpot.stuff(unit, thing, nil, label, taken)
				if spot then
					local poly =
						DealSpot.footprint(spot.x, spot.z, spot.yaw, thing.across, thing.along)
					ok(
						not DealSpot.near(poly, taken[1], 0),
						`{size} {label}: the {name} keeps clear of the box`
					)
				end
				local name3 = DealSpot.stuffIn(unit, Deal.Stuff, name, sizes, nil, label, taken)
				if size == "M" then
					ok(name3 ~= nil, `M {label}: drawn the {name}, something stands by the box`)
				end
				withBox += if name3 then 1 else 0
				boxTries += 1
			end
			-- whatever is drawn, a small unit stands something
			local name2, spot2 = DealSpot.stuffIn(unit, Deal.Stuff, name, sizes, nil, label)
			ok(name2 ~= nil and spot2 ~= nil, `{size} {label}: drawn the {name}, something stands`)
			if size == "M" then
				ok(name2 == name, `M {label}: the {name} drawn is the {name} stood`)
			end
		end
	end
end

if failures > 0 then
	print(`stuffdeal: {failures} of {checks} checks failed`)
	error("stuffdeal spec failed")
end
print(
	`stuffdeal: {checks} checks passed ({math.floor(share * 100)}% of {empty} units hold stuff; {stood} spots; {withBox} of {boxTries} stand by a box)`
)
