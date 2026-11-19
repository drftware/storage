--!strict
--[[
	Snapping (S5-03j3a, D-455): what makes Arrange, the room editor (D-436), feel smart rather than
	fiddly. The moments, all The Sims 4's: a chair pushed toward a wall swings round and backs up
	flush against it; a cup dragged over the table hops up onto it, and back down once it's
	clearly off the edge; a shelf slid along a row of shelves lines up with them. Each rule is
	help, never a fight: a piece turns only as it arrives at a wall, so a turn you give it there
	stays; a wall or a top holds on a little past where it took hold, so nothing flickers between
	two answers at an edge; Free (Alt, or the corner switch) skips all of it, as The Sims' Alt does.

	The half-stud grid itself is Brix's (`PlacementSnap.grid`, `Arrange.Step`); its line-up with
	neighbours is Brix's too (`placements:align`, ENG-26c). Snapping is the game's rules on top:
	which wall a piece on the floor is against, the turn and the flush spot that gives it, whether a
	find is over a top, and which of Brix's guide lines still hold.

	Floor coordinates as Brix's and Layout's: x across (the left wall at +width/2), y along the
	depth (the back wall at -depth/2, the door at +depth/2). A wall is named by the turn that puts a
	piece's back to it: the back wall 0, the left 90, the door's 180, the right 270 (Layout's).

	Pure: numbers in, numbers out, nothing allocated. ArrangeHand calls it as a carried thing
	settles (`settle`) and as the finger aims over the tops (`aim`). Its spec:
	tests/snapping.spec.luau.
]]

local Snapping = {}

-- How near a wall (studs, from the piece's edge) it has to come to be against it: two grid
-- steps, so it takes hold when you're clearly pushing it there, not when you pass by.
Snapping.Reach = 1
-- How much further off (studs) a piece against a wall has to be pulled before it lets go: the
-- give that stops it flickering on and off the wall at the reach.
Snapping.Give = 0.5
-- How far past a top's edge (studs) a find standing on it may be dragged before it steps back
-- down: entering takes its middle over the top, leaving takes this much more.
Snapping.Over = 0.4
-- How far (studs) a dragged thing moves to line an edge or its middle up with a neighbour's:
-- half a grid step, so the lines help without pulling it off the grid.
Snapping.Line = 0.25

-- The walls, by the turn that puts a piece's back to each.
Snapping.Back = 0
Snapping.Left = 90
Snapping.Door = 180
Snapping.Right = 270
-- The walls a piece backs onto: never the door's, which rolls up and lets everyone in.
Snapping.Walls = table.freeze({ Snapping.Back, Snapping.Left, Snapping.Right })

-- Pieces with no back: they lie flat, so they never turn to a wall (by furniture id).
Snapping.Flat = table.freeze({ Rug = true, Blanket = true }) :: { [string]: boolean }

-- The floor's size, as Brix and `Spots.room` give it.
export type Floor = { width: number, depth: number }
-- A guide line, as Brix's `align` answers one (`Brix.PlacementGuide`).
export type Guide = { axis: "x" | "y", at: number, from: number, to: number }

-- How far the edge of a piece at `x`, `y`, reaching `rx` across and `ry` deep (its footprint
-- turned, `Turning.reach`), stands off wall `wall` (studs; 0 flush).
function Snapping.gap(
	floor: Floor,
	wall: number,
	x: number,
	y: number,
	rx: number,
	ry: number
): number
	local hw, hd = floor.width / 2, floor.depth / 2
	if wall == Snapping.Back then
		return y - ry + hd
	elseif wall == Snapping.Left then
		return hw - x - rx
	elseif wall == Snapping.Door then
		return hd - y - ry
	end
	return x - rx + hw
end

-- The axis that runs across wall `wall`, out of it into the room: "y" for the back and the door,
-- "x" for the sides. Against a wall, a piece moves only along the other.
function Snapping.across(wall: number): "x" | "y"
	return if wall == Snapping.Back or wall == Snapping.Door then "y" else "x"
end

-- How far apart turns `a` and `b` are (degrees, 0 to 180).
local function apart(a: number, b: number): number
	local d = (a - b) % 360
	return if d > 180 then 360 - d else d
end

-- The wall a piece at `x`, `y` (reaching `rx`, `ry`, turned `turn`) is against, or nil out in
-- the room. Against `at` a moment ago, it stays against it until `Give` past the reach. Otherwise
-- the nearest wall within `Reach`; of walls about as near (within `Give` of it), the one its
-- back already faces most, so a piece pushed into a corner goes the way it was facing.
function Snapping.wall(
	floor: Floor,
	x: number,
	y: number,
	rx: number,
	ry: number,
	turn: number,
	at: number?
): number?
	if at and table.find(Snapping.Walls, at) then
		if Snapping.gap(floor, at, x, y, rx, ry) <= Snapping.Reach + Snapping.Give then
			return at
		end
	end
	local nearest, gap = nil :: number?, math.huge
	for _, wall in Snapping.Walls do
		local g = Snapping.gap(floor, wall, x, y, rx, ry)
		if g <= Snapping.Reach and g < gap then
			nearest, gap = wall, g
		end
	end
	if not nearest then
		return nil
	end
	local pick, least = nearest, apart(turn, nearest)
	for _, wall in Snapping.Walls do
		local g = Snapping.gap(floor, wall, x, y, rx, ry)
		if g <= Snapping.Reach and g <= gap + Snapping.Give and apart(turn, wall) < least then
			pick, least = wall, apart(turn, wall)
		end
	end
	return pick
end

-- `x`, `y` for a piece (reaching `rx`, `ry`) moved flush against wall `wall`: across the wall
-- its edge touches it; along the wall it stays where it was.
function Snapping.flush(
	floor: Floor,
	wall: number,
	x: number,
	y: number,
	rx: number,
	ry: number
): (number, number)
	local hw, hd = floor.width / 2, floor.depth / 2
	if wall == Snapping.Back then
		return x, -hd + ry
	elseif wall == Snapping.Left then
		return hw - rx, y
	elseif wall == Snapping.Door then
		return x, hd - ry
	end
	return -hw + rx, y
end

-- The turn of a piece turned `turn`, against wall `wall` (nil: in the room) after being against
-- `was`: arriving at a wall it turns its back to it; staying, or leaving, it keeps its turn, so a
-- turn the player gives it against a wall is theirs.
function Snapping.turned(turn: number, wall: number?, was: number?): number
	if wall and wall ~= was then
		return wall
	end
	return turn
end

-- Whether a find whose middle is at `x`, `y` on a top `width` by `depth` (from its middle)
-- stands on it: over it to stand on it from elsewhere; already `on` it, until `Over` past the
-- edge.
function Snapping.over(x: number, y: number, width: number, depth: number, on: boolean): boolean
	local give = if on then Snapping.Over else 0
	return math.abs(x) <= width / 2 + give and math.abs(y) <= depth / 2 + give
end

-- Drops the lines along `axis` from the first `count` of `guides`, the rest kept in order, in
-- place: every entry stays in the list (Brix fills them again next move). Answers how many are
-- left.
function Snapping.drop(guides: { Guide }, count: number, axis: "x" | "y"): number
	local kept = 0
	for i = 1, count do
		local g = guides[i]
		if g.axis ~= axis then
			kept += 1
			guides[kept], guides[i] = g, guides[kept]
		end
	end
	return kept
end

-- Where a thing the grid set at `x`, `y` settles once Brix's line-up (`ax`, `ay`) is taken
-- where it holds: each side's move only if it keeps the thing within `hx`, `hy` of its area's
-- middle, and never across a wall it stands against (`across`, from `across`; nil in the room).
-- A side's move not taken drops its lines from `guides`. Answers `x`, `y` and the lines left.
function Snapping.lineUp(
	x: number,
	y: number,
	ax: number,
	ay: number,
	hx: number,
	hy: number,
	across: ("x" | "y")?,
	guides: { Guide },
	count: number
): (number, number, number)
	local nx, ny = x, y
	if ax ~= x then
		if math.abs(ax) <= hx + 1e-9 and across ~= "x" then
			nx = ax
		else
			count = Snapping.drop(guides, count, "x")
		end
	end
	if ay ~= y then
		if math.abs(ay) <= hy + 1e-9 and across ~= "y" then
			ny = ay
		else
			count = Snapping.drop(guides, count, "y")
		end
	end
	return nx, ny, count
end

return table.freeze(Snapping)
