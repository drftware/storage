--!strict
--[[
	ShutIn: who a shut roll-up door hides from whom, and how much of the hall's light gets in. A
	shut door is solid metal, so someone in the unit and someone outside it can't see each other,
	and the one inside sits in the dark. BehindDoors uses this to stop drawing anyone a shut door
	stands between (which also hides a running arm that swings through the slats) and to dim the
	hall's lights for whoever is shut in.

	Points are door-local (RollUpDoor.frame): +Z runs back into the unit from the curtain, +Y up
	from the floor, X across the opening. Pure, so the Lune tests cover it.
]]

export type Room = {
	Width: number, -- wall to wall
	Depth: number, -- facade face to back wall
	WallHeight: number,
	CurtainPlane: number, -- how far the curtain sits behind the facade face
}

local ShutIn = {}

-- How far a door may be lifted and still hide what's behind it. Any more shows feet under the
-- door, so the people inside appear the moment it starts to lift.
ShutIn.MaxRise = 0.05

-- Whether a door-local point is in the unit's room: behind the curtain, between the side walls,
-- above the floor and below the wall tops.
function ShutIn.inside(room: Room, x: number, y: number, z: number): boolean
	return z > 0
		and z < room.Depth - room.CurtainPlane
		and math.abs(x) < room.Width / 2
		and y > -1
		and y < room.WallHeight
end

-- Whether this door hides one point from the other: it's shut and exactly one of them is inside.
function ShutIn.hides(rise: number, aInside: boolean, bInside: boolean): boolean
	return aInside ~= bInside and rise <= ShutIn.MaxRise
end

-- How much of the hall's light still reaches you shut in: enough that the door's slats faintly
-- show, as in the look sheet (art/sheets/unit-inside.png), never enough to see the room by.
ShutIn.Dark = 0.06

-- The share of the hall's light (Dark to 1) that reaches someone inside a unit whose door is at
-- `rise`, for a door that opens to `openRise`. It floods in fast as the door starts to lift and
-- eases in to full as it opens, so a friend's peek lets in about half (the hall seen under the
-- door still reads bright) and a slam cuts it off as fast as the door falls. Low-graphics phones
-- light a unit's inside through its walls (D-016), so BehindDoors scales the hall's lights by
-- this on the shut-in player's own screen.
function ShutIn.light(rise: number, openRise: number): number
	if openRise <= 0 then
		return 1
	end
	local shut = 1 - math.clamp(rise / openRise, 0, 1)
	return ShutIn.Dark + (1 - ShutIn.Dark) * (1 - shut * shut * shut * shut)
end

return ShutIn
