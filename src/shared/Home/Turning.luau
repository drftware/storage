--!strict
--[[
	Turning (S5-03j2b2a): how a thing carried in Arrange, the room editor (D-436), turns. While
	you drag a chair, a second finger twisting round the first turns it with your fingers, clicking
	into quarters, as The Sims 4 turns a held object; with Free on (Alt on a keyboard, or the round
	switch in the corner on a phone, as The Sims' Alt does) it stops at any whole degree instead.
	A tap on Turn, R, or a wheel notch is a quarter anticlockwise, the same as a quarter's twist,
	so the two always agree.

	A turn is in degrees, anticlockwise as one looks at the face the thing stands on, as Brix's
	Placements turns a footprint; a twist is in radians, clockwise on the screen, as Brix's
	Gestures reports one. Seen from the face's own side (down at the floor or a top, at a wall
	from the room), a twist clockwise on the screen turns the thing clockwise there: the turn goes
	down by the twist. A camera looking at a face from behind it (the ceiling from above) sees
	that the other way round, so the screen hands such a twist over negated.

	Pure: numbers in, numbers out. ArrangeHand calls it as a twist goes on or Turn is pressed;
	Layout reads a turn's facing from it.
]]

local Turning = {}

-- A quarter turn (degrees): the grid's step, and one Turn press.
Turning.Quarter = 90

-- Turn `turn` (degrees, any number) brought round to 0 up to 360.
function Turning.round(turn: number): number
	local t = turn % 360
	return if t >= 360 then 0 else t
end

-- The quarter nearest turn `turn`, from 0 up to 360.
function Turning.nearest(turn: number): number
	return Turning.round(math.round(turn / Turning.Quarter) * Turning.Quarter)
end

-- The turn to show for a thing that stood at turn `start` (degrees) when two fingers began
-- twisting it, now they have twisted `twist` (radians, clockwise on the screen) all told since:
-- the nearest quarter, or with `free` the nearest whole degree. From 0 up to 360.
function Turning.twisted(start: number, twist: number, free: boolean): number
	local turn = start - math.deg(twist)
	return if free then Turning.round(math.round(turn)) else Turning.nearest(turn)
end

-- The turn after one Turn press from turn `turn`: a quarter anticlockwise; on the grid (not
-- `free`), on to the next quarter, so a thing set off it comes square. From 0 up to 360.
function Turning.press(turn: number, free: boolean): number
	if free then
		return Turning.round(turn + Turning.Quarter)
	end
	-- a hair under a quarter (a float's rounding) counts as on it
	local quarters = math.floor(turn / Turning.Quarter + 1e-6) + 1
	return Turning.round(quarters * Turning.Quarter)
end

-- The cosine and sine of turn `turn` (degrees), exact at every quarter, so a thing turned a
-- quarter lines up with the walls to the last digit (as Brix's own turn does).
function Turning.facing(turn: number): (number, number)
	local t = Turning.round(turn)
	if t == 0 then
		return 1, 0
	elseif t == 90 then
		return 0, 1
	elseif t == 180 then
		return -1, 0
	elseif t == 270 then
		return 0, -1
	end
	local r = math.rad(t)
	return math.cos(r), math.sin(r)
end

-- Free's soft tick (degrees): a turn by eye still clicks quietly every 15 degrees, so a twist
-- feels its way round as the grid's quarters do.
Turning.FreeTick = 15

-- Half of how far a footprint `width` by `depth` turned `turn` (degrees) reaches across its
-- area and along it, as Brix's judge measures a turned footprint: square on, half its width and
-- depth; a quarter round, swapped; askew, its corners reach farther both ways.
function Turning.reach(width: number, depth: number, turn: number): (number, number)
	local c, s = Turning.facing(turn)
	c, s = math.abs(c), math.abs(s)
	return (width * c + depth * s) / 2, (width * s + depth * c) / 2
end

-- Twist `twist` (radians, clockwise on the screen) as the face a thing stands on sees it, the
-- camera looking along `facing` (the camera's look dotted with the face's normal): seen from
-- its own side (negative, or edge on) as the screen shows it; from behind it (the ceiling from
-- above) the other way round.
function Turning.seen(twist: number, facing: number): number
	return if facing > 0 then -twist else twist
end

-- Which notch of `step` degrees turn `turn` is in, from 0 (0 up to `step`): a turn crossing
-- into another notch clicks. A hair under a notch (a float's rounding) counts as on it.
function Turning.notch(turn: number, step: number): number
	return math.floor(Turning.round(turn) / step + 1e-6) % math.round(360 / step)
end

return table.freeze(Turning)
