--!strict
--[[
	Tops: the unit tops as a place you crawl (L-13b2c), pure so Lune checks it (tests/tops.spec.luau).
	The moment: up on the steel in the dark, you creep along the tops over the units while a keeper
	stalks the hall below, round a corner, peek over a unit's front, and drop down behind it. Steered
	as Outlast's crawl spaces are: push the stick and creep, slow and low, the game keeping your body
	on the steel so nobody slides off or clips into a wall. The steel booms under you with every
	pull, heard in the halls below, as Alien: Isolation's vents.

	The map: every unit's top in a run and every lid (`Floor`'s runs and lids, D-055), as rectangles
	in the floor's own frame, plus a lip in front of every unit, the air over its hall, where your
	head may go so you can look down. A body lying on the steel is checked at three points along it
	(head, middle, feet), each a small square that must lie on the tops; only the head may reach out
	over a unit's front. Panels, junction walls and dead ends need no checks of their own: they stand
	on the map's edges. A top sawn through (L-13b2d2c) adds its hole: no longer steel, but, as a
	front's lip, air your head may go out over to look down into the unit. Every hole is bigger
	than any of the body's squares, so a square can't straddle one with its corners on the steel.

	Headings are yaws as Roblox's (CFrame.Angles(0, yaw, 0) looks along (-sin yaw, 0, -cos yaw)).
]]
local Floor = require("./Floor")

local Tops = {}

-- On a floor's model (or the test hall's folder), from the server: the tag, its map as text
-- (`Tops.encode`) and the frame the map is in, so every screen and the server find the tops.
Tops.Tag = "TopsMap"
Tops.MapAttribute = "TopsMap"
Tops.OriginAttribute = "TopsOrigin"

-- The crawl. Slow and low: about a quarter of a walk (16), so being up here is a commitment and a
-- keeper below outpaces you, but a unit's width still takes only a few seconds.
Tops.Speed = 4.5 -- studs a second, crawling the way you look
Tops.BackScale = 0.5 -- crawling backward: half that, your head still the way you look
Tops.TurnRate = math.rad(200) -- radians a second your body turns toward where you crawl
-- Studs from your root to your eye along your lying body: first person's camera spot (Roblox's
-- 1.5 above an R15 root). Your body turns about it, so turning never swings your view sideways
-- (owner, Nov 11: crawling "should be just as smooth as moving on the normal floor").
Tops.Eye = 1.5
Tops.Pull = 2.2 -- studs a pull (one arm hauls you on): each pull a soft boom on the steel
-- How much each pull surges (0 a steady slide, 1 stopping between pulls). Barely: the pulls are
-- heard and seen in the arms, while your view glides as a walk does (it was 0.55, a lurch).
Tops.Surge = 0.1
Tops.ArmSwing = math.rad(24) -- a friend's arms reaching and hauling in turn, about their rest
-- Each drawn frame's crawl is cut into steps no longer than one at 60 frames a second, the rate
-- the crawl was tuned at, so turning and sliding along an edge feel the same on any screen.
Tops.StepMax = 1 / 60
-- The longest frame the crawl catches up (seconds): past it, a hitch costs you the rest of the
-- way rather than throwing you across the steel in one frame.
Tops.FrameMax = 0.25

-- Your body lying on the steel, for the checks: points along your heading from your root (studs),
-- each a square of `half` studs that must lie on the tops. The head's may reach out over a unit's
-- front (its lip) so you can look down into the hall; the rest stays on the steel.
export type Point = { along: number, half: number, peek: boolean }
Tops.Body = {
	{ along = 1.6, half = 0.6, peek = true }, -- your head, where your view is (1.5 along)
	{ along = 0, half = 0.9, peek = false }, -- your shoulders and hips
	{ along = -2.2, half = 0.5, peek = false }, -- your feet
} :: { Point }
-- Studs out over a unit's front your head may go: your view (1.5 along) about 0.6 past the edge,
-- enough to look straight down into the hall.
Tops.Lip = 1.4

-- The server's checks of where a crawler's screen says they are.
Tops.CheckEvery = 0.2 -- seconds between checks
Tops.Slack = 1.5 -- studs off the map it still accepts: a body's edge, a moment's lag
Tops.FastSlack = 1.6 -- times the crawl's top speed (with its surge) it still accepts
Tops.LagStuds = 2.5 -- studs on top of that, for a late packet
Tops.HeightSlack = 2.5 -- studs above or below lying height it still accepts

-- Studs a keeper hears you from (L-06b): every other pull's boom, and your landing in the hall.
Tops.Heard = 30
Tops.DropHeard = 45

-- The drop off a unit's front into the hall, played by the game as the climb is (D-057): over the
-- edge, a short fall feet first, a crouch as you land. Under a second, so it's an escape.
Tops.Over = 0.3 -- sliding out over the edge
Tops.Fall = 0.3 -- the fall: about Roblox's gravity over the 8 studs down
Tops.Land = 0.3 -- the crouch as you land and stand
Tops.DropSeconds = Tops.Over + Tops.Fall + Tops.Land
Tops.EdgeIn = 2.2 -- studs in from the front where your root starts the drop (the path's start)
Tops.OverOut = 0.4 -- studs out past the front your root is as you tip over it
Tops.OverPitch = math.rad(-65) -- tipped over the edge, your legs coming down
Tops.Out = 1.8 -- studs out into the hall from the front where you land
Tops.Squat = 0.7 -- studs your body dips as your knees take the landing
Tops.DropEnds = 1.3 -- studs in from a front's corners you can drop at: clear of its posts
Tops.DropReach = 6 -- the Drop down button (middle of the front's edge): from anywhere along it
Tops.DropNear = 4.5 -- studs in from the front your root may be to drop
Tops.LandKick = 0.4 -- the jolt to your view as you land (Shake trauma)

-- The drop in through a sawn top's hole (L-13b2d3a), played by the game as the drop off a front
-- is: you tip up and slide your legs down through the hole's middle, hang a moment upright in it,
-- drop feet first with your arms up, and land in a crouch on the unit's floor, facing its door.
-- Under a second, as Rainbow Six Siege's drop through a hatch.
Tops.InOver = 0.36 -- tipping up and sliding your legs down the hole until you hang in it
Tops.InFall = 0.3 -- the fall: Roblox's gravity over the eight and a half studs left to the floor
Tops.InSeconds = Tops.InOver + Tops.InFall + Tops.Land
Tops.InClear = 0.25 -- studs your feet clear the steel by as they swing round to the hole
-- Studs over the steel the top of your head keeps under as you tip up: the halls' ceiling is 3.86
-- over a unit's top, too low to stand under, so your legs go down the hole as your body comes up.
Tops.InHead = 3.6
Tops.InHeadUp = 2.2 -- studs from your root to the top of your head
Tops.InBack = 1 -- studs toward the door your body's line may start from the hole's middle
Tops.InEdge = 0.3 -- studs short of a hole's edge your head still counts as out over it
Tops.InReach = 6.5 -- the Drop in button (down the hole's middle): from lying anywhere round its edge
Tops.InArm = math.rad(170) -- your arms up over your head as you go through
Tops.InKick = 0.5 -- the jolt to your view as you land (Shake trauma): a longer fall than the hall's
-- Your body going through the hole, for the checks: shoulders across, chest to back.
Tops.InWide = 2
Tops.InDeep = 1

-- Lying across a top as its hole goes through, you slide off its edge onto the steel (the server
-- moves you, your screen glides you there): the nearest place your body fits, this far at most.
Tops.SlideReach = 5 -- studs: a body across the middle of a hole is about 2.5 from clear
Tops.SlideSeconds = 0.25 -- the glide on your screen
Tops.SlideKick = 0.25 -- the jolt to your view as the steel gives under you (Shake trauma)
-- Studs of a sawn hole's edge a climber's roll from the ladder onto the top may brush past: the
-- roll takes 0.6 s, so a brush is never seen, but rolling across a hole would be.
Tops.RollBrush = 0.3

export type Rect = { x0: number, x1: number, z0: number, z1: number }

-- The tops of one floor (or test hall), in its own frame: the steel, the lips and the sawn
-- holes, and every rectangle filed by the 4-stud squares it touches so a point finds its few
-- quickly.
export type Map = {
	tops: { Rect },
	lips: { Rect },
	holes: { Rect },
	topCells: { [number]: { Rect } },
	lipCells: { [number]: { Rect } },
	holeCells: { [number]: { Rect } },
}

-- A crawler: where your root is on the map, your heading, and studs crawled (for the pulls).
-- `spin` is the way you're turning right round (1, -1), kept until you face about the way.
export type State = { x: number, z: number, yaw: number, travel: number, spin: number? }

local CELL = 4

local function key(gx: number, gz: number): number
	return (gx + 32768) * 65536 + (gz + 32768)
end

local function file(cells: { [number]: { Rect } }, r: Rect)
	for gx = math.floor(r.x0 / CELL), math.floor(r.x1 / CELL) do
		for gz = math.floor(r.z0 / CELL), math.floor(r.z1 / CELL) do
			local k = key(gx, gz)
			local list = cells[k]
			if not list then
				list = {}
				cells[k] = list
			end
			table.insert(list, r)
		end
	end
end

function Tops.map(tops: { Rect }, lips: { Rect }, holes: { Rect }?): Map
	local m: Map = {
		tops = tops,
		lips = lips,
		holes = holes or {},
		topCells = {},
		lipCells = {},
		holeCells = {},
	}
	for _, r in tops do
		file(m.topCells, r)
	end
	for _, r in lips do
		file(m.lipCells, r)
	end
	for _, r in m.holes do
		file(m.holeCells, r)
	end
	return m
end

-- A slot's footprint, from the middle of its hall face and the way it faces (a unit Dir vector),
-- and the lip in front of it over the hall.
function Tops.footprint(
	x: number,
	z: number,
	fx: number,
	fz: number,
	width: number,
	depth: number
): Rect
	local bx, bz = x - fx * depth, z - fz * depth
	local hw = width / 2
	if math.abs(fx) > 0.5 then
		return { x0 = math.min(x, bx), x1 = math.max(x, bx), z0 = z - hw, z1 = z + hw }
	end
	return { x0 = x - hw, x1 = x + hw, z0 = math.min(z, bz), z1 = math.max(z, bz) }
end
function Tops.lip(x: number, z: number, fx: number, fz: number, width: number): Rect
	local ox, oz = x + fx * Tops.Lip, z + fz * Tops.Lip
	local hw = width / 2
	if math.abs(fx) > 0.5 then
		return { x0 = math.min(x, ox), x1 = math.max(x, ox), z0 = z - hw, z1 = z + hw }
	end
	return { x0 = x - hw, x1 = x + hw, z0 = math.min(z, oz), z1 = math.max(z, oz) }
end

-- A floor's tops: every top run's slot and every lid, and a lip in front of every unit in a run.
function Tops.rects(floor: Floor.Floor): ({ Rect }, { Rect })
	local tops: { Rect } = {}
	local lips: { Rect } = {}
	for _, s in floor.slots do
		if s.top then
			local size = Floor.Sizes[s.size]
			local fx, fz = Floor.dir(s.facing)
			table.insert(tops, Tops.footprint(s.x, s.z, fx, fz, size.width, size.depth))
			if s.kind == "Unit" then
				table.insert(lips, Tops.lip(s.x, s.z, fx, fz, size.width))
			end
		end
	end
	for _, l in floor.lids do
		local size = Floor.Sizes[l.size]
		local fx, fz = Floor.dir(l.facing)
		table.insert(tops, Tops.footprint(l.x, l.z, fx, fz, size.width, size.depth))
	end
	return tops, lips
end

-- The map as text for an attribute, and back: "x0 x1 z0 z1" a rectangle, ";" between them, "|"
-- between the tops, the lips and the holes.
local function encodeList(list: { Rect }): string
	local parts = table.create(#list)
	for i, r in list do
		parts[i] = string.format("%.3f %.3f %.3f %.3f", r.x0, r.x1, r.z0, r.z1)
	end
	return table.concat(parts, ";")
end
function Tops.encode(tops: { Rect }, lips: { Rect }, holes: { Rect }?): string
	return encodeList(tops) .. "|" .. encodeList(lips) .. "|" .. encodeList(holes or {})
end
local function decodeList(text: string): { Rect }?
	local list: { Rect } = {}
	for part in string.gmatch(text, "[^;]+") do
		local a, b, c, d = string.match(part, "^([%-%d%.]+) ([%-%d%.]+) ([%-%d%.]+) ([%-%d%.]+)$")
		local x0, x1, z0, z1 = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
		if not (x0 and x1 and z0 and z1) then
			return nil
		end
		table.insert(list, { x0 = x0, x1 = x1, z0 = z0, z1 = z1 })
	end
	return list
end
function Tops.decode(text: string): Map?
	local parts = string.split(text, "|")
	if #parts ~= 2 and #parts ~= 3 then
		return nil
	end
	local tops, lips = decodeList(parts[1]), decodeList(parts[2])
	local holes = if parts[3] then decodeList(parts[3]) else {}
	if not (tops and lips and holes) then
		return nil
	end
	return Tops.map(tops, lips, holes)
end

-- Whether a point is in one of a square's rectangles: on its edge counts, or, `strict`, only
-- inside (the steel round a hole is still steel).
local function inList(list: { Rect }?, x: number, z: number, strict: boolean?): boolean
	if list then
		for _, r in list do
			if strict then
				if x > r.x0 and x < r.x1 and z > r.z0 and z < r.z1 then
					return true
				end
			elseif x >= r.x0 and x <= r.x1 and z >= r.z0 and z <= r.z1 then
				return true
			end
		end
	end
	return false
end

-- Whether a point is out over a sawn hole.
function Tops.overHole(m: Map, x: number, z: number): boolean
	return inList(m.holeCells[key(math.floor(x / CELL), math.floor(z / CELL))], x, z, true)
end

-- Whether a point is on the steel (or, with `peek`, out over a unit's front or a sawn hole too).
function Tops.within(m: Map, x: number, z: number, peek: boolean?): boolean
	local k = key(math.floor(x / CELL), math.floor(z / CELL))
	if inList(m.holeCells[k], x, z, true) then
		return peek == true
	end
	return inList(m.topCells[k], x, z) or (peek == true and inList(m.lipCells[k], x, z))
end

-- Whether a point is on the steel or within `slack` of it: the server's lenient check.
function Tops.near(m: Map, x: number, z: number, slack: number): boolean
	if Tops.within(m, x, z, true) then
		return true
	end
	for _, o in { { slack, 0 }, { -slack, 0 }, { 0, slack }, { 0, -slack } } do
		if Tops.within(m, x + o[1], z + o[2], true) then
			return true
		end
	end
	return false
end

function Tops.heading(yaw: number): (number, number)
	return -math.sin(yaw), -math.cos(yaw)
end
function Tops.yawOf(hx: number, hz: number): number
	return math.atan2(-hx, -hz)
end

-- Whether a body lying with its root at (x, z), heading `yaw`, is all on the tops.
function Tops.fits(m: Map, x: number, z: number, yaw: number): boolean
	local hx, hz = Tops.heading(yaw)
	for _, p in Tops.Body do
		local px, pz = x + hx * p.along, z + hz * p.along
		local h = p.half
		if
			not (
				Tops.within(m, px - h, pz - h, p.peek)
				and Tops.within(m, px + h, pz - h, p.peek)
				and Tops.within(m, px - h, pz + h, p.peek)
				and Tops.within(m, px + h, pz + h, p.peek)
			)
		then
			return false
		end
	end
	return true
end

-- Whether no part of a body lying at a pose is out over a sawn hole (its head neither), each part
-- `inset` studs smaller: where a climber may roll onto the top past a hole.
function Tops.clearOfHoles(m: Map, x: number, z: number, yaw: number, inset: number?): boolean
	if next(m.holeCells) == nil then
		return true
	end
	local hx, hz = Tops.heading(yaw)
	for _, p in Tops.Body do
		local px, pz = x + hx * p.along, z + hz * p.along
		local h = math.max(0, p.half - (inset or 0))
		if
			Tops.overHole(m, px, pz)
			or Tops.overHole(m, px - h, pz - h)
			or Tops.overHole(m, px + h, pz - h)
			or Tops.overHole(m, px - h, pz + h)
			or Tops.overHole(m, px + h, pz + h)
		then
			return false
		end
	end
	return true
end

-- Whether a body moved in a straight line from (ax, az) to (bx, bz), heading `yaw`, never
-- passes over a sawn hole, brushing its edge at most `Tops.RollBrush`: a climber's roll from the
-- ladder onto their spot.
function Tops.pathClear(
	m: Map,
	ax: number,
	az: number,
	bx: number,
	bz: number,
	yaw: number
): boolean
	local length = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
	local steps = math.max(1, math.ceil(length / 0.25))
	for i = 0, steps do
		local k = i / steps
		if
			not Tops.clearOfHoles(m, ax + (bx - ax) * k, az + (bz - az) * k, yaw, Tops.RollBrush)
		then
			return false
		end
	end
	return true
end

--[[
	Where a body that no longer fits (lying across a top as its hole goes through) slides to: the
	nearest root, the same heading, where it lies all on the steel, at most `Tops.SlideReach` off.
	Nil if there's none.
]]
function Tops.settle(m: Map, x: number, z: number, yaw: number): (number?, number?)
	if Tops.fits(m, x, z, yaw) then
		return x, z
	end
	local rings = math.ceil(Tops.SlideReach / 0.25)
	-- every way round at each distance in turn, so the first with room is off the nearest edge
	for ring = 1, rings do
		local d = ring * 0.25
		for i = 0, 31 do
			local a = i / 32 * 2 * math.pi
			local nx, nz = x + math.cos(a) * d, z + math.sin(a) * d
			if Tops.fits(m, nx, nz, yaw) then
				return nx, nz
			end
		end
	end
	return nil, nil
end

-- Which way from your root the body's points that are off the tops lie (summed), at a pose.
local function blocked(m: Map, x: number, z: number, yaw: number): (number, number)
	local hx, hz = Tops.heading(yaw)
	local bx, bz = 0, 0
	for _, p in Tops.Body do
		local px, pz = x + hx * p.along, z + hz * p.along
		local h = p.half
		for _, c in { { -h, -h }, { h, -h }, { -h, h }, { h, h } } do
			local cx, cz = px + c[1], pz + c[2]
			if not Tops.within(m, cx, cz, p.peek) then
				local ox, oz = cx - x, cz - z
				local l = math.sqrt(ox * ox + oz * oz)
				if l > 1e-6 then
					bx += ox / l
					bz += oz / l
				end
			end
		end
	end
	return bx, bz
end

local function wrap(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

-- How fast you crawl `travel` studs in: slow as an arm reaches, fast as it hauls.
function Tops.surge(travel: number): number
	return 1 - Tops.Surge * math.cos(2 * math.pi * travel / Tops.Pull)
end

--[[
	One step of the crawl, `dt` seconds: the stick's push (mx, mz, on the map, length up to 1) and
	the way you look (lx, lz). You move where you push at once, as you walk, and your body turns
	about your eye (`Eye`) toward where you crawl (the look's way when pulling back: you crawl
	backward, head first still), sliding along an edge it meets, never off the tops. Returns the
	new state and studs moved (the crawl alone, not the turn's swing).
]]
function Tops.step(
	m: Map,
	s: State,
	mx: number,
	mz: number,
	lx: number,
	lz: number,
	dt: number
): (State, number)
	local push = math.sqrt(mx * mx + mz * mz)
	if push < 0.05 or dt <= 0 then
		return s, 0
	end
	if push > 1 then
		mx, mz, push = mx / push, mz / push, 1
	end
	local look = math.sqrt(lx * lx + lz * lz)
	if look < 1e-3 then
		lx, lz = Tops.heading(s.yaw)
		look = 1
	end
	lx, lz = lx / look, lz / look
	-- how much of the push is back against your look
	local along = (mx * lx + mz * lz) / push
	local tx, tz = mx, mz
	if along < 0 then
		-- pulling back: face the push turned forward, so you crawl backward head first
		tx, tz = mx - 2 * along * push * lx, mz - 2 * along * push * lz
	end
	local back = math.max(0, -along)
	local speed = Tops.Speed * push * (1 + (Tops.BackScale - 1) * back) * Tops.surge(s.travel)

	local x, z, yaw = s.x, s.z, s.yaw
	local stuck = not Tops.fits(m, x, z, yaw)
	-- turn: the short way round, or the long way where a wall blocks your head or feet (lying by a
	-- run's end you turn round toward the unit's middle); once you're turning right round you keep
	-- on the way you started
	local want = wrap(Tops.yawOf(tx, tz) - yaw)
	local spin = s.spin or 0
	local rate = math.min(math.abs(want), Tops.TurnRate * dt)
	if math.abs(want) <= math.pi / 2 then
		spin = 0
	end
	if rate > 1e-6 then
		local first = if spin ~= 0 then spin elseif want > 0 then 1 else -1
		local ways: { number } = if math.abs(want) > math.pi / 2
			then { first, -first }
			else { first }
		-- each way in turn: your body swinging round behind your eye, so your view only turns;
		-- where that won't fit, round your middle; wedged by an edge, shuffling away from what
		-- blocks your head or feet as you turn, as a body squirms round
		local d = Tops.Speed * dt
		local ohx, ohz = Tops.heading(yaw)
		for _, w in ways do
			local ny = yaw + w * rate
			local nhx, nhz = Tops.heading(ny)
			local ex, ez = x + Tops.Eye * (ohx - nhx), z + Tops.Eye * (ohz - nhz)
			if not stuck and Tops.fits(m, ex, ez, ny) then
				x, z, yaw = ex, ez, wrap(ny)
				spin = if math.abs(want) > math.pi / 2 then w else 0
				break
			end
			if stuck or Tops.fits(m, x, z, ny) then
				yaw = wrap(ny)
				spin = if math.abs(want) > math.pi / 2 then w else 0
				break
			end
			local bx, bz = blocked(m, x, z, ny)
			local b = math.sqrt(bx * bx + bz * bz)
			if b > 1e-6 and Tops.fits(m, x - bx / b * d, z - bz / b * d, ny) then
				x, z, yaw = x - bx / b * d, z - bz / b * d, wrap(ny)
				spin = if math.abs(want) > math.pi / 2 then w else 0
				break
			end
		end
	end
	-- you crawl where you push at once, as you walk, your body catching up behind your eye; only
	-- with more than a quarter turn still to go are you slowed, to a stop facing right away
	local left = math.abs(wrap(Tops.yawOf(tx, tz) - yaw))
	speed *= math.clamp(1 + math.cos(left), 0, 1)
	-- move, sliding along an edge
	local dx, dz = mx / push * speed * dt, mz / push * speed * dt
	local nx, nz = x, z
	-- (studs moved is the crawl alone, not your hips swinging round: it times the pulls)
	if stuck then
		if Tops.within(m, x + dx, z + dz) then
			nx, nz = x + dx, z + dz
		end
	elseif Tops.fits(m, x + dx, z + dz, yaw) then
		nx, nz = x + dx, z + dz
	elseif math.abs(dx) > 1e-6 and Tops.fits(m, x + dx, z, yaw) then
		nx = x + dx
	elseif math.abs(dz) > 1e-6 and Tops.fits(m, x, z + dz, yaw) then
		nz = z + dz
	end
	local moved = math.sqrt((nx - x) ^ 2 + (nz - z) ^ 2)
	return { x = nx, z = nz, yaw = yaw, travel = s.travel + moved, spin = spin }, moved
end

-- The crawl over one drawn frame of `dt` seconds (L-16d): `Tops.step` in even steps of at most
-- `StepMax`, so every frame moves your view its own share at any frame rate (a screen at 144 used
-- to show a place twice, then jump, as the body moved only with physics' 60) and a slow frame
-- moves you just as the fast ones it stands for would. A hitch past `FrameMax` loses the rest.
function Tops.advance(
	m: Map,
	s: State,
	mx: number,
	mz: number,
	lx: number,
	lz: number,
	dt: number
): State
	local t = math.min(dt, Tops.FrameMax)
	if t <= 0 then
		return s
	end
	-- (the nudge keeps four steps of a sixtieth from reading as five)
	local n = math.max(1, math.ceil(t / Tops.StepMax - 1e-6))
	local h = t / n
	local st = s
	for _ = 1, n do
		st = Tops.step(m, st, mx, mz, lx, lz, h)
	end
	return st
end

-- Which pull you're in and how far through it (0 to 1), `travel` studs in.
function Tops.pull(travel: number): (number, number)
	local p = travel / Tops.Pull
	return math.floor(p), p - math.floor(p)
end

-- A crawler's shoulders (right, left: radians about X added to their rest) `travel` studs in:
-- one arm reaching while the other hauls.
function Tops.arms(travel: number): (number, number)
	local w = math.sin(2 * math.pi * travel / Tops.Pull) * Tops.ArmSwing
	return w, -w
end

local function smooth(k: number): number
	local c = math.clamp(k, 0, 1)
	return c * c * (3 - 2 * c)
end

local function lerp(a: number, b: number, k: number): number
	return a + (b - a) * k
end

-- How far under standing a landing's crouch has your root, `t` seconds into a drop off a front
-- ("Drop") or in through a hole ("In"): down fast as your knees take it, back up a little slower; 0
-- before you land and once you're standing.
function Tops.landDip(move: "Drop" | "In", t: number): number
	local landed = if move == "Drop" then Tops.Over + Tops.Fall else Tops.InOver + Tops.InFall
	local k = (t - landed) / Tops.Land
	if k <= 0 or k >= 1 then
		return 0
	end
	return Tops.Squat * math.sin(math.pi * k) * (1 - k * 0.3)
end

--[[
	Your legs taking a landing's crouch with your feet flat where they landed (L-16b1): your root
	`dip` studs under standing, a thigh `thigh` long (hip to knee) and a shin `shin` long (knee to
	ankle). Gives the hip's, knee's and ankle's turns (radians about each joint's X, positive
	swinging the leg forward): the thigh forward, the shin back so the ankle stays under the hip,
	the foot turned back flat. Your body was stiff as it landed, so the crouch pushed your feet
	0.6 studs into the floor on every screen (L-13b2d3a's note).
]]
function Tops.crouch(dip: number, thigh: number, shin: number): (number, number, number)
	if dip <= 0 then
		return 0, 0, 0
	end
	-- hip to ankle, straight down; never shorter than the folded leg allows
	local reach = math.max(thigh + shin - dip, math.abs(thigh - shin) + 1e-3)
	local hip = math.acos(
		math.clamp((thigh * thigh + reach * reach - shin * shin) / (2 * thigh * reach), -1, 1)
	)
	local back = math.asin(math.clamp(thigh * math.sin(hip) / shin, -1, 1))
	return hip, -(hip + back), back
end

--[[
	The drop off a front, `t` seconds in, in the front's frame (`Leaning`'s: x along it, +Z into the
	unit, the steel top at `topY`): your root's place and pitch (0 standing, -pi/2 on your belly),
	facing out into the hall, and how far from where you lay as you pressed to blend toward that (0
	to 1). `x` is where along the front you go over, `faceZ` the front's outer face, `standUp` your
	root's height standing.
]]
function Tops.drop(
	t: number,
	x: number,
	faceZ: number,
	topY: number,
	proneUp: number,
	standUp: number
): (number, number, number, number, number)
	local lyingY = topY + proneUp
	if t < Tops.Over then
		local k = smooth(t / Tops.Over)
		local z = lerp(faceZ + Tops.EdgeIn, faceZ - Tops.OverOut, k)
		return x, lyingY + 0.15 * math.sin(math.pi * k), z, lerp(-math.pi / 2, Tops.OverPitch, k), k
	end
	local s = t - Tops.Over
	if s < Tops.Fall then
		local k = s / Tops.Fall
		local z = lerp(faceZ - Tops.OverOut, faceZ - Tops.Out, smooth(k))
		-- falling from rest: the drop grows with the square of the time
		local y = lerp(lyingY, standUp, k * k)
		return x, y, z, lerp(Tops.OverPitch, 0, smooth(k * 1.6)), 1
	end
	return x, standUp - Tops.landDip("Drop", t), faceZ - Tops.Out, 0, 1
end

-- Where along a front of inside width `width` you go over, from where your root lies (x along it).
function Tops.dropX(x: number, width: number): number
	local limit = math.max(0, width / 2 - Tops.DropEnds)
	return math.clamp(x, -limit, limit)
end

--[[
	The drop in through a sawn hole, `t` seconds in, in the hole's frame (`TopHole.frame`: x across,
	y up from the unit's floor, +Z back from the hall): your root's place and pitch (0 standing,
	-pi/2 on your belly) facing the door, and how far from where you lay as you pressed to blend
	toward that (0 to 1). (`cx`, `cz`) is the hole's middle, `top` the steel's top face, `lieY` your
	root's height lying, `standUp` its height standing.

	You tip up about a point over the hole's middle, your head toward the door, so the line of your
	body always goes down through the middle of the hole. Your feet stay over the steel until
	you're steep enough to fit the hole front to back, then slide down it as your head comes up
	under the ceiling (`InHead`); upright, you hang in the hole and drop.
]]
function Tops.dropIn(
	t: number,
	cx: number,
	cz: number,
	top: number,
	lieY: number,
	standUp: number
): (number, number, number, number, number)
	local hang = top + Tops.InHead - Tops.InHeadUp -- upright in the hole, your head under the ceiling
	if t < Tops.InOver then
		local k = smooth(t / Tops.InOver)
		local tilt = math.pi / 2 * k -- 0 lying, a quarter turn upright
		local s, c = math.sin(tilt), math.cos(tilt)
		-- the point you tip about: at your lying height, coming down to the steel's face as you
		-- come upright, and set toward the door so your body's line meets that face mid-hole
		local up = (lieY - top) * (1 - s)
		local back = if up * c < Tops.InBack * s then up * c / s else Tops.InBack
		-- how far up your body's line from that point your root is: your feet just clear of the
		-- steel, or less once your head would reach the ceiling
		local along = standUp + Tops.InClear
		if s > 1e-3 then
			along = math.min(along, (Tops.InHead - up - c / 2) / s - Tops.InHeadUp)
		end
		return cx, top + up + along * s, cz - back - along * c, tilt - math.pi / 2, k
	end
	local f = t - Tops.InOver
	if f < Tops.InFall then
		local k = f / Tops.InFall
		-- falling from rest: the drop grows with the square of the time
		return cx, lerp(hang, standUp, k * k), cz, 0, 1
	end
	return cx, standUp - Tops.landDip("In", t), cz, 0, 1
end

-- A body dropping in's arms, `t` seconds in: how far they've gone from the crawl's reach to up
-- over your head (0 to 1; up only once you're falling, under the ceiling), and how much of the
-- pose they wear over their animation (1 to 0 as you land).
function Tops.inArms(t: number): (number, number)
	local f = t - Tops.InOver
	return smooth(2 * f / Tops.InFall), 1 - smooth((f - Tops.InFall) / Tops.Land)
end

--[[
	Whether a crawler lies at a sawn hole's edge with their head out over it, where Drop in is
	offered and taken: root at (x, z) heading (hx, hz), in any flat frame `hole` is a rectangle in.
	`slack` is studs past the edge's own allowance (the server's, for lag).
]]
function Tops.atHole(
	hole: Rect,
	x: number,
	z: number,
	hx: number,
	hz: number,
	slack: number?
): boolean
	local along = Tops.Body[1].along
	local px, pz = x + hx * along, z + hz * along
	local s = Tops.InEdge + (slack or 0)
	return px >= hole.x0 - s and px <= hole.x1 + s and pz >= hole.z0 - s and pz <= hole.z1 + s
end

-- A stretch of a recording (as Leaning's): played once from `from` for `length` seconds.
export type Sound = {
	id: string,
	from: number,
	length: number,
	volume: number,
	pitch: number,
	near: number, -- full volume within this
	reach: number, -- heard to this many studs
}

Tops.Sounds = {
	-- Pro Sound Effects' "Metal File Cabinet Body Impact Ringy Resonance 11" (the landing on the
	-- steel, D-058), its hit and first ring only, soft and low: the thin steel booming as you haul
	-- yourself on, every pull
	Boom = {
		id = "rbxassetid://9125668193",
		from = 0.13,
		length = 0.7,
		volume = 0.22,
		pitch = 0.62,
		near = 5,
		reach = Tops.Heard,
	} :: Sound,
	-- Pro Sound Effects' "Sand Bag Slide 6" (the hole crawl's drag), quiet: your body sliding on
	Drag = {
		id = "rbxassetid://9118767703",
		from = 0.62,
		length = 0.43,
		volume = 0.7,
		pitch = 1.2,
		near = 4,
		reach = 15,
	} :: Sound,
	-- the boom's ringing tail: the steel giving as you slide off it over the edge
	Shift = {
		id = "rbxassetid://9125668193",
		from = 0.75,
		length = 0.6,
		volume = 0.35,
		pitch = 1.1,
		near = 6,
		reach = Tops.Heard,
	} :: Sound,
	-- Pro Sound Effects' "Body Fall Master 28" (the hole crawl's thud), heavier: you landing in the
	-- hall from the tops
	Land = {
		id = "rbxassetid://9113475819",
		from = 0,
		length = 0.55,
		volume = 0.9,
		pitch = 0.9,
		near = 8,
		reach = Tops.DropHeard,
	} :: Sound,
}
-- A sound's last stretch fades this long rather than stopping dead.
Tops.Fade = 0.15
-- Every other pull's boom a little higher, so two pulls don't sound like one clip.
Tops.OtherPull = 1.13

-- The drop's sounds and kicks, as Leaning's cues.
export type Cue = { at: number, sound: Sound, kick: number }
function Tops.dropCues(): { Cue }
	return {
		{ at = 0, sound = Tops.Sounds.Shift, kick = 0 },
		{ at = Tops.Over + Tops.Fall - 0.02, sound = Tops.Sounds.Land, kick = Tops.LandKick },
	}
end

-- The drop in's: the steel giving as you push off it, your landing on the unit's floor.
function Tops.inCues(): { Cue }
	return {
		{ at = 0, sound = Tops.Sounds.Shift, kick = 0 },
		{ at = Tops.InOver + Tops.InFall - 0.02, sound = Tops.Sounds.Land, kick = Tops.InKick },
	}
end

return Tops
