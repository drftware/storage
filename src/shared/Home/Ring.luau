--!strict
--[[
	Ring (S5-03j2b1, D-450): where the round buttons sit round a thing selected in Arrange, the room
	editor (D-436). A tap on a find lifts it a hair and a few round buttons (Turn, Put away,
	Another) sit round it, as The Sims 4 rings a selected object with its buttons.

	They make one row bowed over the thing's box on the screen: a gap clear of its top, the ends
	dipping down round it so the row hugs it without covering it. Over the thing is clear of the
	thumb that tapped it, which comes up from below. With no room above (the thing high on the
	screen) the row sits under it, bowed up; slid sideways, it stays on the screen. Pure: points in,
	points out. ArrangeRing calls it each time the thing or the camera moves.
]]

export type Box = { left: number, top: number, right: number, bottom: number }
export type Point = { x: number, y: number }
export type Options = {
	size: number, -- a button's width and height (points)
	gap: number, -- between buttons, and between the row and the thing
	sag: number, -- how far each step out from the middle the row bows round the thing
	margin: number, -- kept clear inside the area's edges
}

local Ring = {}

local function finite(n: number): boolean
	return n == n and n > -math.huge and n < math.huge
end

-- Where `count` buttons sit round `box` (screen points), kept inside `area` (the part of the
-- screen they may use): their middles, left to right, and whether the row is over the thing or
-- under it. None for nonsense.
function Ring.place(box: Box, count: number, area: Box, o: Options): ({ Point }, "above" | "below")
	local out: { Point } = {}
	if
		not (finite(box.left) and finite(box.top) and finite(box.right) and finite(box.bottom))
		or not (finite(area.left) and finite(area.top) and finite(area.right) and finite(
			area.bottom
		))
		or not (o.size > 0 and finite(o.size) and finite(o.gap) and finite(o.sag) and finite(
			o.margin
		))
		or count < 1
	then
		return out, "above"
	end
	local r, step = o.size / 2, o.size + o.gap
	local low, high = area.top + o.margin + r, area.bottom - o.margin - r -- a middle's range up and down
	local half = (count - 1) / 2
	local bow = o.sag * half * half -- the ends' dip from the middle
	local side: "above" | "below" = "above"
	local y = box.top - o.gap - r
	if y < low then
		side = "below"
		y = box.bottom + o.gap + r
		if y > high then -- no room either side: over the thing, on the screen
			side = "above"
			y = math.clamp(box.top - o.gap - r, low, math.max(low, high - bow))
		end
	elseif y + bow > high then
		y = math.max(low, high - bow)
	end
	-- across: centred on the thing, slid on to the screen (centred on it when it won't fit)
	local x = (box.left + box.right) / 2
	local first, last = x - half * step - r, x + half * step + r
	local left, right = area.left + o.margin, area.right - o.margin
	if last - first > right - left then
		x = (left + right) / 2
	elseif first < left then
		x += left - first
	elseif last > right then
		x -= last - right
	end
	local dir = if side == "above" then 1 else -1 -- the ends dip toward the thing
	for i = 1, count do
		local k = i - 1 - half
		table.insert(out, { x = x + k * step, y = y + dir * o.sag * k * k })
	end
	return out, side
end

return Ring
