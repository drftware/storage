--!strict
--[[
	What's in your hands on your own screen (L-13b2c2, D-060): your torch and the tool in your other
	hand never poke through a wall, a door, the unit tops' steel or the ceiling.

	Roblox draws the things you hold in the world with everything else (it has no layer on top, the
	way shooters draw your gun), so a full-size torch reaching two studs out went through any door
	you stood near. Drawn at a third of the size and a third of the distance from your eye, a thing
	looks exactly the same on your screen (half as far and half as big fills the same part of your
	view), but it sits within about two thirds of a stud of your eye, nearer than a wall gets unless
	your nose is against it. Then it pulls back and ducks under your view, as the guns in Ready or
	Not and Escape from Tarkov pull in when you face a wall.

	The torch's beam still leaves where the full-size lens would be, so the light falls as it always
	did, but it never starts past a surface: on the line from the drawn lens to that spot it stops
	just short of whatever is in the way, so a torch at a lid or a door never lights the unit behind
	it, and looking down over a unit's front it still lights the hall below.

	Pure numbers and maths (Lune reads it in `tests/hands.spec.luau`); `HandRoom` (client) asks the
	world.
]]
local Hands = {}

-- How small, and how near your eye, what you hold is drawn. Smaller would cut the torch's tail at
-- the camera's near plane (0.1 studs: docs/STUDIO.md); this leaves it 0.19 from your eye.
Hands.Scale = 0.3
-- The room check starts this far behind your eye, inside your own head, so a wall you're pressed
-- against is still found (a cast never finds what it starts inside).
Hands.Back = 0.6
-- The room check's width: about how far out to the side the torch and a tool sit, so the edge of a
-- doorway catches them too, not only a wall straight ahead.
Hands.Radius = 0.25
-- Studs kept between what you hold and any surface.
Hands.Margin = 0.06
-- How quickly it comes back up once there's room again (per second; it pulls in at once, so it's
-- never seen through a wall even for a frame).
Hands.Return = 7
-- Of each stud it pulls back, how far it also drops: it ducks under your view instead of sliding
-- into your eye.
Hands.Duck = 0.7
-- The beam starts this far short of a surface the full-size lens would be past.
Hands.LightGap = 0.12

-- How far back what you hold must pull: `room` is how far ahead of your eye the nearest surface is
-- (nil: nothing within reach), `reach` how far ahead of your eye the held thing reaches.
function Hands.pull(room: number?, reach: number): number
	if room == nil then
		return 0
	end
	return math.max(0, reach + Hands.Margin - math.max(room, 0))
end

-- The pull shown this frame, from last frame's (`current`) toward the one wanted (`target`): in at
-- once, back out smoothly.
function Hands.follow(current: number, target: number, dt: number): number
	if target >= current then
		return target
	end
	return target + (current - target) * math.exp(-Hands.Return * math.max(dt, 0))
end

-- How far the beam starts along the line toward the full-size lens (`far` studs away): the lens
-- itself, or just short of a surface `hit` studs along the line (nil: none).
function Hands.lightAt(far: number, hit: number?): number
	if hit == nil or hit >= far then
		return far
	end
	return math.max(0, hit - Hands.LightGap)
end

return Hands
