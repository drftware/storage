--!strict
--[[
	BuildView (S5-03j1a, D-439): the build camera's two sums, pure, in plain numbers so Lune proves
	them. The moment they serve: you pinch out over your home and the camera backs out through the
	door, the wall in front of you melting away, as The Sims cuts walls down; it never wanders into
	a neighbour's unit, and the walls you look past are the only ones that go.

	Both work in the room's own frame, flat: x across (left is +x, as `Arrange`'s areas lay it),
	z deep (the door at −z, the back at +z). `ArrangeCamera` (the client) turns world points into
	that frame and calls these.

	- `keepIn` says how much of the way from the focus out to the eye stays inside a box: the
	  camera pulls its eye in along its own line of sight to there, as a third-person camera pulls
	  in from a wall, so the picture never jumps (the share moves smoothly as the eye does).
	- `sideOf` says which of the room's four walls a piece of the home belongs to, from its box:
	  only the pieces flush with or beyond a wall's plane, so the floor, the lamp and furniture
	  standing in the room never fade with a wall.
]]

local BuildView = {}

-- A flat box in the room's frame: its lowest and highest x and z.
export type Box = { left: number, right: number, front: number, back: number }

-- The four walls: +x, −x, +z (the back) and −z (the door's).
export type Side = "left" | "right" | "back" | "front"

-- The share (0 to 1) of the way from the focus (`fx`, `fz`) to the eye (`ex`, `ez`) that stays
-- inside `box`. Where the focus has already strayed past a side (pushed past a soft stop, and
-- springing back), that side doesn't pull, so the eye never falls onto the focus.
function BuildView.keepIn(ex: number, ez: number, fx: number, fz: number, box: Box): number
	local share = 1
	local dx, dz = ex - fx, ez - fz
	if dx > 0 then
		local hi = if fx > box.right then math.huge else box.right
		if ex > hi then
			share = math.min(share, (hi - fx) / dx)
		end
	elseif dx < 0 then
		local lo = if fx < box.left then -math.huge else box.left
		if ex < lo then
			share = math.min(share, (lo - fx) / dx)
		end
	end
	if dz > 0 then
		local hi = if fz > box.back then math.huge else box.back
		if ez > hi then
			share = math.min(share, (hi - fz) / dz)
		end
	elseif dz < 0 then
		local lo = if fz < box.front then -math.huge else box.front
		if ez < lo then
			share = math.min(share, (lo - fz) / dz)
		end
	end
	return math.clamp(share, 0, 1)
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

return table.freeze(BuildView)
