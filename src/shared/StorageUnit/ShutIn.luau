--!strict
--[[
	ShutIn: who a shut roll-up door hides from whom. A shut door is solid metal, so someone in the
	unit and someone outside it can't see each other. BehindDoors uses this to stop drawing anyone
	a shut door stands between, which also hides a running arm that swings through the slats.

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

return ShutIn
