--!strict
--[[
	Boxes: a wall's collision once a crawl hole is cut in it. Pure, so Lune checks it.

	A wall's one collision box becomes up to four round the hole: the wall in front of it, the wall
	behind it, the wall over it and the lip under it, together covering the whole wall but the
	hole. Everything is a rectangle on the wall's face: `along` the wall and `up` it, in any one
	frame (CrawlHole uses the collider's own).
]]

local Boxes = {}

export type Rect = { along0: number, along1: number, up0: number, up1: number }
export type Piece = Rect & { name: string }

-- The pieces of `wall` left round `hole`, each named for where it is ("Front", "Behind", "Over",
-- "Under"), any that would be empty left out. The hole is clipped to the wall first.
function Boxes.around(wall: Rect, hole: Rect): { Piece }
	local a0 = math.clamp(hole.along0, wall.along0, wall.along1)
	local a1 = math.clamp(hole.along1, wall.along0, wall.along1)
	local u0 = math.clamp(hole.up0, wall.up0, wall.up1)
	local u1 = math.clamp(hole.up1, wall.up0, wall.up1)
	local out: { Piece } = {}
	local function add(name: string, along0: number, along1: number, up0: number, up1: number)
		if along1 - along0 > 1e-6 and up1 - up0 > 1e-6 then
			table.insert(
				out,
				{ name = name, along0 = along0, along1 = along1, up0 = up0, up1 = up1 }
			)
		end
	end
	add("Front", wall.along0, a0, wall.up0, wall.up1)
	add("Behind", a1, wall.along1, wall.up0, wall.up1)
	add("Over", a0, a1, u1, wall.up1)
	add("Under", a0, a1, wall.up0, u0)
	return out
end

return Boxes
