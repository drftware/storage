--!strict
--[[
	BuildView (S5-03j1a, D-439; `homeView` S5-03j1b, D-442): the build camera's sums, pure, in plain numbers so Lune proves
	them. The moment they serve: you pinch out over your home and the camera backs out through the
	door, the wall in front of you melting away, as The Sims cuts walls down; it never wanders into
	a neighbour's unit, and the walls you look past are the only ones that go.

	Both work in the room's own frame, flat: x across (left is +x, as `Arrange`'s areas lay it),
	z deep (the door at −z, the back at +z). `ArrangeCamera` (the client) turns world points into
	that frame and calls these.

	- `eyeBox` says where the eye may stand: over the room and out through the door (D-443).
	- `fade` says how far gone a wall is from where the eye stands.
	- `sideOf` says which of the room's four walls a piece of the home belongs to, from its box:
	  only the pieces flush with or beyond a wall's plane, so the floor, the lamp and furniture
	  standing in the room never fade with a wall.
	- `homeView` says which way the camera opens: from a front corner, so the room shows as a box.
- `fit` says how far back it stands then: as near as the whole room fits the band of the screen
  the tray and top bar leave clear (S5-03j1d2), so a Small home fills it as an XL does.
- `runs` says where a wall goes on past the room's corners (S5-03j1d2): a smaller home's walls
  run the XL's whole length (D-354), and the camera masks those ends so the room ends cleanly.
]]

local BuildView = {}

-- A flat box in the room's frame: its lowest and highest x and z.
export type Box = { left: number, right: number, front: number, back: number }

-- The four walls: +x, −x, +z (the back) and −z (the door's).
export type Side = "left" | "right" | "back" | "front"

-- Where the eye may stand (S5-03j1c, D-443): over the room itself, `gap` inside its walls, and
-- out through the door as far as `hall`. Never beside or behind the room, where a smaller home's
-- walls run on past its corners to the slot's (they only ever slide, D-354) and its floor goes on
-- under them: from there those would fill the view. Brix's orbit brings the eye in level, so at
-- the sides and back it looks down steeply into the room instead.
function BuildView.eyeBox(halfX: number, halfZ: number, gap: number, hall: number): Box
	local x = math.max(halfX - gap, 0)
	return { left = -x, right = x, front = -halfZ - hall, back = math.max(halfZ - gap, 0) }
end

-- How faded (0 to 1) a wall is with the eye `past` studs beyond its plane (less than 0 on the
-- room's side). Out past it, it goes over `depth`. With the eye over the room (`over`), a wall
-- the eye comes within `gap` of is gone too, fading in over `depth` before that: it stands just
-- behind the camera, which looks down past it.
function BuildView.fade(past: number, over: boolean, gap: number, depth: number): number
	local from = if over then -gap - depth else 0
	return math.clamp((past - from) / depth, 0, 1)
end

-- Which wall a piece spanning x `minX` to `maxX` and z `minZ` to `maxZ` belongs to, in a room
-- reaching `halfX` and `halfZ` each way from its middle: a piece whose near side is within `band`
-- of a wall's plane or past it (the door's wall takes `frontBand`: its coil and curtain hang
-- inside it). Nil for a piece of the room itself. A corner piece goes with the wall it stands
-- furthest past.
function BuildView.sideOf(
	minX: number,
	maxX: number,
	minZ: number,
	maxZ: number,
	halfX: number,
	halfZ: number,
	band: number,
	frontBand: number
): Side?
	local best: Side? = nil
	local most = -math.huge
	local function consider(side: Side, past: number, reach: number)
		if past >= -reach and past > most then
			best, most = side, past
		end
	end
	consider("left", minX - halfX, band)
	consider("right", -halfX - maxX, band)
	consider("back", minZ - halfZ, band)
	consider("front", -halfZ - maxZ, frontBand)
	return best
end

-- Where the camera stands when Arrange opens, and goes back to on a double tap (S5-03j1b): out
-- past the walls it looks over, as The Sims' build camera stands over a cut-away house, so the
-- whole room shows and the near walls are gone. A room reaching `halfX` and `halfZ` each way,
-- the eye `clear` past each near wall's plane, kept inside `box` (the slot, and the hall's
-- edge). Where the slot has room beside the home, a front corner, on the `side` the player
-- stands (1 is +x); else in from the hall through the door, turned `slant` toward that side as
-- far as the slot allows. Answers the eye's heading off straight in through the door (radians,
-- toward `side`) and its flat distance from the room's middle.
function BuildView.homeView(
	halfX: number,
	halfZ: number,
	clear: number,
	box: Box,
	side: number,
	slant: number
): (number, number)
	local sign = if side < 0 then -1 else 1
	local beside = if sign > 0 then box.right else -box.left
	local out = -box.front
	local dx, dz = halfX + clear, halfZ + clear
	if dx <= beside and dz <= out then
		return sign * math.atan2(dx, dz), math.sqrt(dx * dx + dz * dz)
	end
	local z = math.max(math.min(dz, out), 0)
	local angle = math.min(slant, math.atan2(math.max(beside, 0), z))
	return sign * angle, z / math.cos(angle)
end

-- The parts of a wall's box `wall` outside the room's box `room` (its walls' outer faces), each a
-- run past a corner (S5-03j1d2): past the room's sides across the wall's whole depth, past its
-- front and back only where the wall is beside the room. A run shorter than `least` (a trim's
-- lip, a wall's end meeting the door's) doesn't count.
function BuildView.runs(room: Box, wall: Box, least: number): { Box }
	local out: { Box } = {}
	local function keep(b: Box)
		local across, deep = b.right - b.left, b.back - b.front
		if across > 0 and deep > 0 then
			table.insert(out, b)
		end
	end
	if room.left - wall.left > least then
		keep({
			left = wall.left,
			right = math.min(wall.right, room.left),
			front = wall.front,
			back = wall.back,
		})
	end
	if wall.right - room.right > least then
		keep({
			left = math.max(wall.left, room.right),
			right = wall.right,
			front = wall.front,
			back = wall.back,
		})
	end
	local l, r = math.max(wall.left, room.left), math.min(wall.right, room.right)
	if room.front - wall.front > least then
		keep({ left = l, right = r, front = wall.front, back = math.min(wall.back, room.front) })
	end
	if wall.back - room.back > least then
		keep({ left = l, right = r, front = math.max(wall.front, room.back), back = wall.back })
	end
	return out
end

-- The screen the home view fits into: the viewport (points) and the tangent of half its height's
-- field of view; the clear band's top and bottom; the highest the walls' tops may reach (`roof`:
-- over the band's top, where the top bar's middle is free); and how many points to keep clear
-- inside the band and at the sides.
export type Screen = {
	width: number,
	tall: number,
	tanHalf: number,
	top: number,
	bottom: number,
	roof: number,
	edge: number,
}

-- Where the home view stands so the whole room fills `screen`'s band (S5-03j1d2): the floor,
-- reaching `halfX` and `halfZ` each way, `below` under the focus, and what stands on it up to
-- `high` over the floor; the walls' tops, `walls` over the floor, no higher than the roof. The eye looks from `heading` (radians off straight in through the door,
-- as `homeView` answers) down at `tilt`; the camera pitches on as Brix's orbit does to show the
-- focus at an aim point mid-screen across. Answers the eye's distance from the focus, as near as
-- the room fits, and where down the screen the focus shows (points) so the room sits in the
-- band's middle: what stands on the floor rises above the focus, so the focus shows lower.
function BuildView.fit(
	halfX: number,
	halfZ: number,
	below: number,
	high: number,
	walls: number,
	heading: number,
	tilt: number,
	screen: Screen
): (number, number)
	local half = screen.tall / 2
	local sa, ca = math.sin(heading), math.cos(heading)
	local ct, st = math.cos(tilt), math.sin(tilt)
	-- From the focus to the eye, and the camera's right (the room's frame).
	local bx, by, bz = sa * ct, st, -ca * ct
	local rx, rz = -ca, -sa
	local scale = half / screen.tanHalf
	local band = screen.bottom - screen.top - 2 * screen.edge
	local leftMost, rightMost = screen.edge, screen.width - screen.edge
	local aim = (screen.top + screen.bottom) / 2
	local roof = screen.roof + screen.edge
	-- The room's highest and lowest point down the screen from `d` away with the focus at `at`;
	-- nil when it can't fit across, stands behind the eye, or its walls reach over the roof.
	local function span(d: number, at: number): (number?, number)
		local v = (half - at) / half * screen.tanHalf
		local p = tilt + math.atan(v)
		local cp, sp = math.cos(p), math.sin(p)
		local fx, fy, fz = -sa * cp, -sp, ca * cp
		local ux, uy, uz = -fy * rz, rz * fx - rx * fz, rx * fy -- right × facing
		local highest, lowest = math.huge, -math.huge
		for i = 0, 11 do
			local x = if i % 2 == 0 then halfX else -halfX
			local z = if i % 4 < 2 then halfZ else -halfZ
			local tier = i // 4 -- the floor, what stands on it, the walls' tops
			local y = (if tier == 0 then 0 elseif tier == 1 then high else walls) - below
			local qx, qy, qz = x - bx * d, y - by * d, z - bz * d
			local depth = qx * fx + qy * fy + qz * fz
			if depth <= 0.01 then
				return nil, 0
			end
			local sy = half - (qx * ux + qy * uy + qz * uz) / depth * scale
			if tier == 2 then
				if sy < roof then
					return nil, 0
				end
				continue
			end
			local sx = screen.width / 2 + (qx * rx + qz * rz) / depth * scale
			if sx < leftMost or sx > rightMost then
				return nil, 0
			end
			highest, lowest = math.min(highest, sy), math.max(lowest, sy)
		end
		return highest, lowest
	end
	local d = 500
	-- Fit the distance, centre the room on it, and again: the pitch follows the aim a little.
	for _ = 1, 3 do
		local lo, hi = 0.5, 500
		for _ = 1, 40 do
			local mid = (lo + hi) / 2
			local a, b = span(mid, aim)
			if a and b - a <= band then
				hi = mid
			else
				lo = mid
			end
		end
		d = hi
		local a, b = span(d, aim)
		if a then
			aim = math.clamp(
				aim + (screen.top + screen.bottom) / 2 - (a + b) / 2,
				screen.top,
				screen.bottom
			)
		end
	end
	return d, aim
end

return table.freeze(BuildView)
