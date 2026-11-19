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
	- `homeView` says where the camera opens: out past the near walls, so the room shows whole.
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

return table.freeze(BuildView)
