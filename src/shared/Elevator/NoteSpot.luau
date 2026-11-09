--!strict
--[[
	NoteSpot: where a floor's code note sticks in its unit (L-05b1b), the numbers alone, so Lune
	checks them (tests/notespot.spec.luau). The moment it serves: the door lifts, the unit's bulb
	comes on, and the first thing it finds is a yellow square on the back wall straight ahead, its
	digit plain enough that whoever lifted the door shouts it to the team.

	Always the back wall, facing the door, at the height of your eyes: one place to look, learned on
	the first floor, so finding a note is about which door, never about where in the unit. It sits
	on a rib of the corrugated wall, a little off the middle and a little crooked, as a hand would
	stick it, varied unit to unit.

	A spot is in the unit's door face frame (FloorBuilder's `face`): origin the middle of the
	doorway's outer face on the floor, -Z out into the hall, +Z into the unit. The note's pivot is
	`face * CFrame.new(x, y, z) * CFrame.Angles(0, 0, tilt)`, its face toward the hall.
]]

local NoteSpot = {}

-- The back wall's ribs stand this far proud of its line toward the door: 0.10 studs of rib and
-- half the 0.03 sheet (art/unit/parts.py, `corrugated`). The note's back lies on their crests.
NoteSpot.RibProud = 0.115
-- The crests' middles, across the wall from its centre line (one every stud, on the half). The
-- note sits on one of these, picked by the unit's number: near the middle, never at the door's
-- edge of view.
NoteSpot.Across = { -1.5, -0.5, 0.5, 1.5 }
-- The note's middle this high off the floor: first person's eye (the camera rides 4.5 studs up
-- on a standing R15 character), so it's straight ahead as you look in.
NoteSpot.Height = 4.5
-- How big the note is drawn, over the art's 0.7-stud square. Measured on the Galaxy A16 (L-05b1b):
-- the writing's digits stand about 0.107 studs tall at 1, too small to read from a doorway. At 1.6
-- the note is a plain yellow square from any doorway and its digit plain from a few steps in.
NoteSpot.Scale = 1.6
-- A digit's height on the note at Scale 1, measured in Studio (Kalam's digits are short for their
-- line, and the four slots across set the writing's size).
NoteSpot.DigitHeight = 0.107
-- A hand-stuck note sits crooked by up to this many degrees, one way or the other.
NoteSpot.Tilt = 4

export type Spot = {
	x: number,
	y: number,
	z: number,
	tilt: number, -- radians about the note's own Z (its face's normal)
}

-- Where the note goes in a unit `depth` studs deep (wall centre to wall centre, the unit's
-- Specs.Depth) numbered `number` ("214"): the same unit always gets the same spot.
function NoteSpot.inUnit(depth: number, number: string): Spot
	local n = tonumber(number) or 0
	local across = NoteSpot.Across[n % #NoteSpot.Across + 1]
	-- five tilts from -Tilt to +Tilt, stepped by a different count than the crests, so the two
	-- don't repeat together down a hall
	local step = (n * 3) % 5 - 2
	return {
		x = across,
		y = NoteSpot.Height,
		z = depth - NoteSpot.RibProud,
		tilt = math.rad(step * NoteSpot.Tilt / 2),
	}
end

return NoteSpot
