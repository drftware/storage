--!strict
--[[
	DealSpot: where in a unit the deal lays what the unit holds (L-04e), the numbers alone, so Lune
	checks them (tests/dealspot.spec.luau). The moment it serves: the door lifts, the bulb comes on,
	and there in its light is what the building left you: bolt cutters on the floor, a teddy bear
	facing you from the back, something standing very still.

	Every spot is on the floor, clear of the walls and of the door's line, and never in the way of
	the unit's note (D-044): from anywhere across the doorway the yellow square on the back wall
	stays in plain sight. The eye looks at it from 4.5 studs up or higher, so a bear or a TV may
	stand under it; anything tall enough to reach the line (a keeper) keeps off the whole floor
	between the doorway and the note, so a mannequin never stands in front of the code. Finds and keepers
	stand behind the bulb, facing the doorway within a small turn, where a find shows its lit side
	(D-036) and a mannequin stares back. A tool lies anywhere in the bulb's light at a careless
	angle, dropped rather than placed, as Lethal Company's scrap lies about its rooms. Nothing lies
	at either side wall's crawl hole spot (L-12b2): the cut-out panel falls flat there on whichever
	side wasn't sawn from, and a player crawls through it, so a tool or a keeper there would be lain
	on or block the way; only where a unit is too tight to keep both clear does the deal use them
	(a small unit's keeper). Nor where someone dropping in through the unit's sawn top lands
	(L-13b2d3b): under the hole's middle and on to the door, so you come down on bare concrete with
	your way out clear, never onto a keeper; nor where the top's cut-out panel falls. The same unit
	always gets the same spot (picked by its number), so a seed's floor looks the same twice.
	Somebody's stuff (S1-04b2, `DealSpot.stuff`) stands only in a unit that holds nothing else, so
	it never shares a unit with any of these.

	A spot is in the unit's door face frame (FloorBuilder's `face`, NoteSpot's): origin the middle
	of the doorway's outer face on the floor, -Z out into the hall, +Z into the unit. What's laid
	stands with its middle at `face * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)`,
	its front (its -Z) toward the door at yaw 0.
]]

local DealSpot = {}

-- A unit's size in studs, as its generated Specs give it (`Width`, `Depth` wall to wall through
-- their middles, `DoorWidth` the opening), and the stretch of each side wall its crawl hole and
-- fallen panel take (in this frame's Z; nil keeps nothing clear). `landing` is the floor under the
-- middle of the hole a saw cuts in the unit's top, where someone dropping in comes down, and
-- `fallen` the floor that hole's cut-out panel falls on, a polygon (nil keeps neither clear).
export type Unit = {
	width: number,
	depth: number,
	doorWidth: number,
	hole: { from: number, to: number }?,
	landing: { x: number, z: number }?,
	fallen: { number }?,
}
export type Thing = "Tool" | "Find" | "Keeper" | "Coins" | "Battery"
-- A thing's size as it stands at yaw 0: X across, Z along (front to back), Y tall.
export type Size = { across: number, along: number, tall: number }
export type Spot = { x: number, z: number, yaw: number } -- yaw in degrees about +Y

-- Studs between what's laid and a wall's middle line: past the wall's ribs (0.115 proud), with a
-- gap that says it's on the floor, not in the wall.
DealSpot.Wall = 0.4
-- Nothing nearer the doorway's face than this: the door comes down 0.55 in, and the Lift button
-- for someone shut in stands just behind it, so nothing lies under the door or in the way out.
DealSpot.Door = 2.5
-- How deep a thing's nearest edge starts, and how deep its farthest edge may go, as shares of the
-- unit's depth. The bulb hangs at the middle, so a find or a keeper stands wholly behind it
-- (D-036). A tool lies in the bulb's pool, near enough to read on a phone from the doorway: at
-- the back wall of a big unit the bolt cutters were a red smear (L-04e, Galaxy A16).
-- Coins (S1-04a) lie in the bulb's pool as a tool does, where they catch its light from the doorway;
-- a battery (S1-07b) too, clear of the coins.
DealSpot.From = { Tool = 0.25, Find = 0.5, Keeper = 0.5, Coins = 0.25, Battery = 0.25 } :: {
	[string]: number,
}
DealSpot.To = { Tool = 0.7, Find = 1, Keeper = 1, Coins = 0.7, Battery = 0.7 } :: {
	[string]: number,
}
-- Studs kept between a unit's coins and the other thing it holds, all round, so a pile never lies
-- on a tool or against a keeper's feet, and each reads on its own.
DealSpot.Apart = 0.5
-- Half the note's width as drawn (the art's 0.7-stud note at NoteSpot.Scale 1.6).
DealSpot.NoteHalf = 0.56
-- Studs kept clear around the sight line from the doorway to the note, so nothing even brushes it.
DealSpot.Sight = 0.3
-- Anything shorter stays under every eye's line to the note, so it may stand in front of it: a
-- first-person eye rides 4.5 studs up, the note's bottom edge is 3.94 up, and the default
-- third-person camera looks from higher still.
DealSpot.Under = 3.5
-- How far apart the spots tried are, in studs. Finer looks no different in a unit.
DealSpot.Step = 0.5
-- A tool lies at one of these turns from square: never along a wall, so it looks dropped.
DealSpot.ToolYaws = { 20, 55, 80, 110, 145, 170 }
-- A find or keeper turns this many degrees from facing the doorway's middle, one way or the other.
DealSpot.Turns = { -8, -4, 0, 4, 8 }
-- Studs kept clear out from each side wall's middle line along its crawl hole's stretch: the
-- panel lying flat reaches 3.22 from the wall (art/hole), and a crawl starts as far out.
DealSpot.Hole = 3.3
-- Studs kept clear either side of where someone dropping in through the top lands, and behind it.
-- A body is 2 across and 1 deep; the rest is room for its arms coming down and for a landing a
-- little off the middle. In front it's kept clear all the way to the door: your step to the way out.
DealSpot.LandSide = 1.5
DealSpot.LandBack = 0.9
-- A keeper's size until each keeper brings its own (L-06b): the Mannequin standing at rest, arms
-- at its sides (1.89 across, its feet 1.34 heel to toe, 6.3 tall), with a little room round it.
DealSpot.Keeper = { across = 2.1, along = 1.5, tall = 6.3 } :: Size
-- The Packrat standing slack (S2-06b2b): 2.7 across its hanging arms, 7.3 tall, its long hands
-- hanging ahead of its feet, so the floor it takes is 2.5 deep with its middle `PackratAhead`
-- studs in front of where it stands (both measured from its Still pose, with a little room).
-- It stands at the back of its unit (`inUnit`'s `near`), its pile at its feet (`around` with
-- its middle moved ahead).
DealSpot.Packrat = { across = 2.75, along = 2.5, tall = 7.3 } :: Size
DealSpot.PackratAhead = 0.55

-- A convex polygon on the floor: x1, z1, x2, z2, ...
type Poly = { number }

-- A footprint's corners, as signs of its half sizes, in order round it.
local CORNERS = { -1, -1, 1, -1, 1, 1, -1, 1 }

local function project(poly: Poly, ax: number, az: number): (number, number)
	local lo, hi = math.huge, -math.huge
	for i = 1, #poly, 2 do
		local d = poly[i] * ax + poly[i + 1] * az
		lo = math.min(lo, d)
		hi = math.max(hi, d)
	end
	return lo, hi
end

-- Whether one of `edges`' sides keeps `a` and `b` more than `gap` apart (separating axes).
local function parted(edges: Poly, a: Poly, b: Poly, gap: number): boolean
	local n = #edges
	for i = 1, n, 2 do
		local j = if i + 2 > n then 1 else i + 2
		local ex, ez = edges[j] - edges[i], edges[j + 1] - edges[i + 1]
		local len = math.sqrt(ex * ex + ez * ez)
		if len > 1e-9 then
			local ax, az = -ez / len, ex / len
			local alo, ahi = project(a, ax, az)
			local blo, bhi = project(b, ax, az)
			if alo > bhi + gap or blo > ahi + gap then
				return true
			end
		end
	end
	return false
end

-- Whether two convex polygons come within `gap` of each other.
function DealSpot.near(a: { number }, b: { number }, gap: number): boolean
	return not parted(a, a, b, gap) and not parted(b, a, b, gap)
end

-- The floor a thing `across` by `along` studs covers with its middle at (x, z), turned `yaw`
-- degrees: its four corners as CFrame.Angles(0, yaw, 0) turns them.
function DealSpot.footprint(
	x: number,
	z: number,
	yaw: number,
	across: number,
	along: number
): { number }
	local c, s = math.cos(math.rad(yaw)), math.sin(math.rad(yaw))
	local hx, hz = across / 2, along / 2
	local poly = table.create(8, 0)
	for i = 1, 8, 2 do
		local lx, lz = CORNERS[i] * hx, CORNERS[i + 1] * hz
		poly[i] = x + lx * c + lz * s
		poly[i + 1] = z - lx * s + lz * c
	end
	return poly
end

-- The floor between the doorway and a note `note` studs across the back wall: from the doorway's
-- whole width to the note's, everything an eye anywhere in the doorway looks through to see it.
function DealSpot.sightLine(unit: Unit, note: number): { number }
	local door = unit.doorWidth / 2
	return {
		-door,
		0,
		door,
		0,
		note + DealSpot.NoteHalf,
		unit.depth,
		note - DealSpot.NoteHalf,
		unit.depth,
	}
end

-- The yaw that turns a thing at (x, z) to face the doorway's middle.
function DealSpot.facing(x: number, z: number): number
	return math.deg(math.atan2(x, z))
end

-- Every spot in `unit` where a thing `across` by `along` studs fits, from `from` to `to` deep (shares
-- of the depth), in a fixed order. A tool lies at `yaw`; a find or keeper (`yaw` nil) faces the doorway turned `turn`,
-- or with `straight` faces straight out of the unit turned `turn`.
local function spots(
	unit: Unit,
	across: number,
	along: number,
	sight: { number }?,
	holes: { { number } },
	from: number,
	to: number,
	yaw: number?,
	turn: number,
	straight: boolean
): { Spot }
	local found: { Spot } = {}
	local side = unit.width / 2 - DealSpot.Wall
	local back = math.min(unit.depth - DealSpot.Wall, to * unit.depth)
	local front = math.max(DealSpot.Door, from * unit.depth)
	-- across from the middle out both ways alike, and in from the back wall, where things stand
	local reach = math.floor(side / DealSpot.Step)
	local z = back
	while z >= front do
		for column = -reach, reach do
			local x = column * DealSpot.Step
			local turned = yaw or (if straight then 0 else DealSpot.facing(x, z)) + turn
			local poly = DealSpot.footprint(x, z, turned, across, along)
			local fits = true
			for i = 1, #poly, 2 do
				local px, pz = poly[i], poly[i + 1]
				if math.abs(px) > side or pz > back or pz < front then
					fits = false
					break
				end
			end
			if fits and sight and DealSpot.near(poly, sight, DealSpot.Sight) then
				fits = false
			end
			for _, zone in holes do
				if fits and DealSpot.near(poly, zone, 0) then
					fits = false
				end
			end
			if fits then
				table.insert(found, { x = x, z = z, yaw = turned })
			end
		end
		z -= DealSpot.Step
	end
	return found
end

-- The floor kept clear at each side wall's crawl hole (nothing without `unit.hole`).
function DealSpot.holes(unit: Unit): { { number } }
	local hole = unit.hole
	if not hole then
		return {}
	end
	local wall = unit.width / 2
	local zones = {}
	for _, way in { 1, -1 } do
		local near, far = way * (wall - DealSpot.Hole), way * wall
		table.insert(zones, { near, hole.from, far, hole.from, far, hole.to, near, hole.to })
	end
	return zones
end

-- The floor kept clear under the top's hole (nothing without `unit.landing`): where a body dropping
-- in lands, and from there to the doorway's face.
function DealSpot.landing(unit: Unit): { { number } }
	local at = unit.landing
	if not at then
		return {}
	end
	local left, right = at.x - DealSpot.LandSide, at.x + DealSpot.LandSide
	local back = at.z + DealSpot.LandBack
	return { { left, 0, right, 0, right, back, left, back } }
end

-- Every spot that fits, by inUnit's order of preference, keeping clear of `holes`. `behind` keeps
-- a find or keeper behind the bulb (D-036), not trying in front of it.
local function search(
	unit: Unit,
	thing: Thing,
	size: Size,
	sight: { number }?,
	holes: { { number } },
	n: number,
	turn: number,
	behind: boolean
): { Spot }
	local across, along = size.across, size.along
	local found: { Spot } = {}
	if thing == "Tool" or thing == "Coins" or thing == "Battery" then
		-- in the bulb's pool at its unit's own turn, else at another; else anywhere past the door,
		-- the same way (a small unit's pool is mostly landing and hole spots, D-067). Coins take
		-- another turn than a tool in the same unit would, and a battery another again.
		local count = #DealSpot.ToolYaws
		local own = if thing == "Coins" then n + 2 elseif thing == "Battery" then n + 4 else n
		for _, deep in { { DealSpot.From[thing], DealSpot.To[thing] }, { 0, 1 } } do
			for k = 0, count - 1 do
				local yaw = DealSpot.ToolYaws[(own + k) % count + 1]
				found = spots(unit, across, along, sight, holes, deep[1], deep[2], yaw, 0, false)
				if #found > 0 then
					return found
				end
			end
		end
	else
		-- behind the bulb facing the doorway; else facing straight out, then square (a back corner
		-- of a small unit beside its note's line is too tight to turn in); else wherever it fits
		local to = DealSpot.To[thing]
		local tiers: { number } = if behind
			then { DealSpot.From[thing] }
			else { DealSpot.From[thing], 0 }
		for _, from in tiers do
			for way = 1, 3 do
				if #found == 0 then
					local straight = way > 1
					local turned = if way == 3 then 0 else turn
					found =
						spots(unit, across, along, sight, holes, from, to, nil, turned, straight)
				end
			end
		end
	end
	return found
end

--[[
	Where unit `number` ("214") lays a `thing` of `size`, its note `note` studs across the back wall
	(NoteSpot's x) or nil if it holds none. A tool tries its unit's own turn first, then the others,
	then anywhere; coins too, at their own turn. `taken` is floor something else is laid on (the
	unit's tool, find or keeper, `DealSpot.Apart` all round: `DealSpot.around`), never given up.
	A find or keeper faces the doorway, or straight out where it can't turn, and stands wholly
	behind the bulb unless it fits nowhere there. All of it off the crawl hole spots, the landing
	under the top's hole and where the top's panel falls. Where that fits nowhere it gives them up
	in that order, the crawl hole spots first and the landing last: a find or keeper rather stands
	on a crawl hole spot behind the bulb than in front of it, and nothing lies where you'd land
	while it fits anywhere else. Nil only if it fits nowhere past the door. `near` (x, z), if
	given, takes the spot that fits nearest it rather than the unit's own: the Packrat at the back
	of its unit and its pile at its feet (S2-06b2b).
]]
function DealSpot.inUnit(
	unit: Unit,
	thing: Thing,
	size: Size,
	note: number?,
	number: string,
	taken: { { number } }?,
	near: { number }?
): Spot?
	local n = math.floor(math.abs(tonumber(number) or 0))
	local turn = DealSpot.Turns[(n * 3) % #DealSpot.Turns + 1]
	local sight = if note and size.tall >= DealSpot.Under
		then DealSpot.sightLine(unit, note)
		else nil
	local land = DealSpot.landing(unit)
	local kept: { { number } } = taken or {}
	for _, zone in kept do
		table.insert(land, zone)
	end
	local top = table.clone(land)
	if unit.fallen then
		table.insert(top, unit.fallen)
	end
	local all = table.clone(top)
	for _, zone in DealSpot.holes(unit) do
		table.insert(all, zone)
	end
	local behind = thing == "Find" or thing == "Keeper"
	local found: { Spot } = {}
	for _, try in
		{
			{ keep = all, behind = behind },
			{ keep = top, behind = behind },
			{ keep = land, behind = behind },
			{ keep = land, behind = false },
			{ keep = kept, behind = false },
		}
	do
		found = search(unit, thing, size, sight, try.keep, n, turn, try.behind)
		if #found > 0 then
			break
		end
	end
	if #found == 0 then
		return nil
	end
	if near then
		local best, bestD = found[1], math.huge
		for _, spot in found do
			local dx, dz = spot.x - near[1], spot.z - near[2]
			local d = dx * dx + dz * dz
			if d < bestD then
				best, bestD = spot, d
			end
		end
		return best
	end
	-- Knuth's multiplier spreads neighbouring numbers across the list; coins and batteries use
	-- others, so they don't land where the unit's tool would
	local spread = if thing == "Coins"
		then 2246822519
		elseif thing == "Battery" then 3266489917
		else 2654435761
	return found[(n * spread) % #found + 1]
end

-- The floor a thing laid at `spot` takes, `DealSpot.Apart` all round: what `inUnit`'s `taken`
-- keeps clear of.
function DealSpot.around(spot: Spot, size: Size): { number }
	local gap = 2 * DealSpot.Apart
	return DealSpot.footprint(spot.x, spot.z, spot.yaw, size.across + gap, size.along + gap)
end

-- The walls stuff stands against: the back, then the sides. A thing's back goes to the wall, so
-- against the right wall (+X) it's turned 90 degrees, its front to the left wall.
type Wall = "Back" | "Right" | "Left"
local SIDE_YAW = { Right = 90, Left = -90 } :: { [string]: number }

-- Every spot along `wall` where a thing of `size` stands with its back to it, in the floor's
-- bounds past the door, clear of `keep` and of `sight` (nil for none), from one end to the other.
local function alongWall(
	unit: Unit,
	size: Size,
	wall: Wall,
	keep: { { number } },
	sight: { number }?
): { Spot }
	local found: { Spot } = {}
	local side = unit.width / 2 - DealSpot.Wall
	local back = unit.depth - DealSpot.Wall
	local front = DealSpot.Door
	local half, deep = size.across / 2, size.along
	local lo: number, hi: number
	if wall == "Back" then
		lo, hi = -side + half, side - half
	else
		lo, hi = front + half, back - half
	end
	if hi < lo then
		return found
	end
	local at: { number } = {}
	local t = lo
	while t < hi do
		table.insert(at, t)
		t += DealSpot.Step
	end
	table.insert(at, hi) -- both ends exact: the corners
	for _, a in at do
		local x: number, z: number, yaw: number
		if wall == "Back" then
			x, z, yaw = a, back - deep / 2, 0
		else
			local way = if wall == "Right" then 1 else -1
			x, z, yaw = way * (side - deep / 2), a, SIDE_YAW[wall]
		end
		local poly = DealSpot.footprint(x, z, yaw, size.across, deep)
		local fits = true
		for i = 1, #poly, 2 do
			local px, pz = poly[i], poly[i + 1]
			if math.abs(px) > side + 1e-6 or pz > back + 1e-6 or pz < front - 1e-6 then
				fits = false
				break
			end
		end
		if fits and sight and DealSpot.near(poly, sight, DealSpot.Sight) then
			fits = false
		end
		for _, zone in keep do
			if fits and DealSpot.near(poly, zone, 0) then
				fits = false
			end
		end
		if fits then
			table.insert(found, { x = x, z = z, yaw = yaw })
		end
	end
	return found
end

--[[
	Where unit `number` stands somebody's stuff (S1-04b2) of `size`: with its back to a wall and
	its front to the room, pushed as far into a corner as it goes, as people leave things in
	storage. The back wall first, where the doorway sees its face, toward the corner the unit's
	number picks (so a row of units alternates); else a side wall, the same way round, as near the
	back as it goes. It's solid and it stays, so it keeps wholly clear of everything a player needs
	the floor for, never giving any of it up as a tool or keeper may: the door's line, both crawl
	hole spots (a crawl comes out onto the floor there), the landing under the top's hole and where
	its panel falls, and the note's sight line if it's tall enough to block it (`note` as inUnit's).
	Nil if no wall has room clear of all that: a small unit's crawl hole spots leave only the
	middle of its back wall and the front of one side, room for the rolled rug alone.
]]
function DealSpot.stuff(unit: Unit, size: Size, note: number?, number: string): Spot?
	local n = math.floor(math.abs(tonumber(number) or 0))
	local way = if n % 2 == 0 then 1 else -1
	local keep = DealSpot.holes(unit)
	for _, zone in DealSpot.landing(unit) do
		table.insert(keep, zone)
	end
	if unit.fallen then
		table.insert(keep, unit.fallen)
	end
	local sight = if note and size.tall >= DealSpot.Under
		then DealSpot.sightLine(unit, note)
		else nil
	local found = alongWall(unit, size, "Back", keep, sight)
	if #found > 0 then
		local best = found[1]
		for _, spot in found do
			if way * spot.x > way * best.x then
				best = spot
			end
		end
		return best
	end
	for k = 1, 2 do
		local wall: Wall = if (k == 1) == (way > 0) then "Right" else "Left"
		found = alongWall(unit, size, wall, keep, sight)
		if #found > 0 then
			local best = found[1]
			for _, spot in found do
				if spot.z > best.z then
					best = spot
				end
			end
			return best
		end
	end
	return nil
end

-- The stuff unit `number` stands, and where: `drawn` if it fits (`DealSpot.stuff`), else the next
-- in `order` that does, round from it; `sizes` each one's size. Nil if none fits.
function DealSpot.stuffIn(
	unit: Unit,
	order: { string },
	drawn: string,
	sizes: { [string]: Size },
	note: number?,
	number: string
): (string?, Spot?)
	local start = table.find(order, drawn) or 1
	for k = 0, #order - 1 do
		local name = order[(start - 1 + k) % #order + 1]
		local size = sizes[name]
		local spot = if size then DealSpot.stuff(unit, size, note, number) else nil
		if spot then
			return name, spot
		end
	end
	return nil, nil
end

return DealSpot
