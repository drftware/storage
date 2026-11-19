--!strict
--[[
	WallHang (S5-03j3c, D-458): how a thing that hangs on a wall moves in Arrange, the room editor
	(D-436). The moment, The Sims 4's: you drag the neon moon along the wall and it glides at the
	height it hung, round a corner onto the next wall at that same height, never sliding down the
	wall because your finger dipped toward the floor; a small handle above it lifts or lowers it,
	a step at a time (Free: by eye), as The Sims 4's wall-height handle does.

	Which things hang is read from their shape, never their name: a thing whose shape fits only
	walls (`only`; `Spots.Rows` and the furniture rows give each one its spot). A wall's area runs
	`x` along it and `y` up it from its middle (`Spots.room`); a hung thing's footprint there is
	its width across and its height up (`Spots.shape`).

	Pure: numbers in, numbers out, nothing allocated. ArrangeHand calls `only` and `height` as the
	finger aims (`aim`), and `raise` as the height handle is dragged. Its spec:
	tests/wallhang.spec.luau.
]]

local WallHang = {}

-- Whether a thing that fits the kinds of area `fits` hangs only on walls (`wall`: the wall's
-- kind, `Spots.Kinds.Wall`). Things that also stand on floors or tops follow the finger freely.
function WallHang.only(fits: { string }, wall: string): boolean
	if #fits == 0 then
		return false
	end
	for _, kind in fits do
		if kind ~= wall then
			return false
		end
	end
	return true
end

-- How far up or down a thing `tall` high may hang from the middle of a wall `depth` high
-- (studs): its top and bottom stay on the wall. 0 when it's taller than the wall.
function WallHang.room(depth: number, tall: number): number
	return math.max(0, depth / 2 - tall / 2)
end

-- The height (a wall's `y`) a hung thing takes as the finger aims at height `aimed` on a wall
-- `depth` high: the height it already hangs at (`kept`) when it has one, so a drag only slides it
-- along; else where the finger is. Either way kept on the wall.
function WallHang.height(aimed: number, kept: number?, depth: number, tall: number): number
	local most = WallHang.room(depth, tall)
	return math.clamp(if kept then kept else aimed, -most, most)
end

-- The height the handle gives a thing that hung at `from` when it has been dragged `by` studs up
-- (down when negative): on the wall's steps of `step` studs from its middle (0: Free, by eye), and
-- kept on the wall, as `height` keeps it. A tick plays when the answer changes.
function WallHang.raise(from: number, by: number, step: number, depth: number, tall: number): number
	local most = WallHang.room(depth, tall)
	local to = from + by
	if step > 0 then
		to = math.round(to / step) * step
		if to > most then -- the top step that still fits, not one hanging off the wall
			to = math.floor(most / step) * step
		elseif to < -most then
			to = -math.floor(most / step) * step
		end
	end
	return math.clamp(to, -most, most)
end

return table.freeze(WallHang)
