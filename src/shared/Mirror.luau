--!strict
--[[
	Mirror: the math of a mirror that shows you (S5-03b, D-280). Roblox has no real mirror and
	can't flip a picture (`ViewportFrame.IsMirrored` is locked to Roblox's own windows), so the
	glass carries a live picture (MirrorView, a ViewportFrame on the glass) of a world built
	behind it: a copy of each thing in front of the glass, standing where its reflection would,
	turned to face back out. Your eye looks at that world through the glass as through a window,
	so the reflection shifts as you step about, as a real one does.

	A copy can only turn, never flip, so each copy is turned over along the one direction the
	thing is the same both ways across: a body part across its own left and right, standing in
	for its partner (your right hand's reflection is drawn with the left hand, which is its mirror
	image); a wall along its length. Two flips make a turn, so every copy is a real rotation.
	Writing on clothes is the one thing that can't come out right: it reads the right way round.

	Pure: plain Vector3 maths, no instances, so the Lune spec runs it.
]]

local Mirror = {}

Mirror.Tag = "Mirror" -- the glass of every mirror (Home.mirror); its Front face is the glass

-- Feel and cost numbers.
Mirror.Live = 24 -- studs from your camera: the nearest mirror on screen moves with you every frame
Mirror.Still = 70 -- within this the nearest mirror holds a still picture of its room; past it, glass
Mirror.Reach = 34 -- studs round the glass whose room and people are copied behind it
Mirror.MaxParts = 900 -- the room's copy stops here, so a crowded floor can't flood a phone
Mirror.PixelsPerStud = 64 -- the glass's sharpness: 64 reads crisp on a phone a few studs off
-- Up close 64 goes to steps on your reflection's edges (S5-03b seen), so the picture sharpens as
-- you come up to it: pixels per stud = Sharpness / your distance from the glass, in steps of 32,
-- from PixelsPerStud up to PixelsPerStudMax (128 at 2 studs: about the phone's own pixels).
Mirror.Sharpness = 256
Mirror.PixelsPerStudMax = 128
Mirror.Pick = 0.2 -- seconds between choosing which mirror is live (and syncing what people wear)
Mirror.MaxFov = 118 -- a ViewportFrame's camera tops out at 120 degrees
Mirror.Near = 0.1 -- closer to the glass than this the picture isn't drawn (no room to see)
Mirror.Margin = 2 -- studs beside the glass a thing through it may stand and still be copied

-- `p` reflected through the plane through `c` with unit normal `n`.
function Mirror.point(p: Vector3, c: Vector3, n: Vector3): Vector3
	return p - n * (2 * (p - c):Dot(n))
end

-- A copy's rotation, as its X, Y and Z columns, for a thing whose rotation has columns `x`, `y`,
-- `z`: reflected through the glass (unit normal `n`), and turned over across `a`, a unit world
-- direction the thing is the same both ways along. The two flips make a real rotation.
function Mirror.columns(
	x: Vector3,
	y: Vector3,
	z: Vector3,
	n: Vector3,
	a: Vector3
): (Vector3, Vector3, Vector3)
	local x1 = x - a * (2 * x:Dot(a))
	local y1 = y - a * (2 * y:Dot(a))
	local z1 = z - a * (2 * z:Dot(a))
	return x1 - n * (2 * x1:Dot(n)), y1 - n * (2 * y1:Dot(n)), z1 - n * (2 * z1:Dot(n))
end

-- Which of a still thing's own axes (1 X, 2 Y, 3 Z) to turn it over along: of the two that lie
-- nearest level, the longer (a wall along its length, a rug along its long side), so its faces
-- still face the way their reflections do and only what's alike end to end is swapped.
function Mirror.axis(x: Vector3, y: Vector3, z: Vector3, size: Vector3, up: Vector3): number
	local axes = { x, y, z }
	local sizes = { size.X, size.Y, size.Z }
	local upright, most = 2, -1
	for i, v in axes do
		local u = math.abs(v:Dot(up))
		if u > most then
			upright, most = i, u
		end
	end
	local best, long = 0, -1
	for i = 1, 3 do
		if i ~= upright and sizes[i] > long then
			best, long = i, sizes[i]
		end
	end
	return best
end

-- A mirror's glass: its Front face's middle, its normal out into the room, its right and up as
-- someone facing it sees them, and its size in studs.
export type Glass = {
	c: Vector3,
	n: Vector3,
	right: Vector3,
	up: Vector3,
	width: number,
	height: number,
}

-- Whether a still thing (rotation columns `x`, `y`, `z`, `size`, middle `at`) may be copied
-- behind the glass. Its copy stands where its reflection would, so whatever of it reaches behind
-- the glass comes out in front of it, between your eye and the picture, and one such copy covers
-- the whole glass (S5-03b, seen: the lobby's merged walls run behind every unit's mirror). So:
-- wholly in front, yes; wholly behind, no; through the glass, only a floor or ceiling (level and
-- flat, which no line of sight through the glass meets) or something off to its side.
function Mirror.keeps(
	x: Vector3,
	y: Vector3,
	z: Vector3,
	size: Vector3,
	at: Vector3,
	g: Glass,
	level: Vector3
): boolean
	local function extent(v: Vector3): number
		return (
			math.abs(x:Dot(v)) * size.X
			+ math.abs(y:Dot(v)) * size.Y
			+ math.abs(z:Dot(v)) * size.Z
		) / 2
	end
	local ahead = (at - g.c):Dot(g.n)
	local e = extent(g.n)
	if ahead - e >= 0 then
		return true
	elseif ahead + e < 0 then
		return false
	end
	-- wholly below the glass's foot or above its top, as a floor or ceiling is: a line of sight
	-- from your eye through the glass never comes down or up that far in front of it
	local off = at - g.c
	local rise, tall = off:Dot(level), extent(level)
	local foot = (g.height / 2) * math.abs(g.up:Dot(level))
	if rise + tall <= -foot or rise - tall >= foot then
		return true
	end
	return math.abs(off:Dot(g.right)) - extent(g.right) > g.width / 2 + Mirror.Margin
		or math.abs(off:Dot(g.up)) - extent(g.up) > g.height / 2 + Mirror.Margin
end

-- The picture's pixels per stud with your eye `distance` studs off the glass (Mirror.Sharpness).
function Mirror.sharpness(distance: number): number
	local ppu = math.floor(Mirror.Sharpness / math.max(distance, 0.01) / 32) * 32
	return math.clamp(ppu, Mirror.PixelsPerStud, Mirror.PixelsPerStudMax)
end

-- A body part's partner across the body (an R15 or R6 part named Left or Right), or itself.
function Mirror.partner(name: string): string
	if name:sub(1, 4) == "Left" then
		return "Right" .. name:sub(5)
	elseif name:sub(1, 5) == "Right" then
		return "Left" .. name:sub(6)
	end
	-- R6's limbs name their side last
	if name:sub(-4) == "Left" or name:sub(-5) == " Left" then
		return name:sub(1, -5) .. "Right"
	elseif name:sub(-5) == "Right" then
		return name:sub(1, -6) .. "Left"
	end
	return name
end

-- How to draw the picture so the glass is a window into the world behind it, from `eye`. The
-- picture's camera looks square into the glass (its image plane parallel to it), so the glass
-- is a plain rectangle in the picture; the picture is sized and placed on the glass so that
-- rectangle lands exactly on the glass. `c` is the glass's middle, `n` its normal out into the
-- room, `right` and `up` its edges as someone facing it sees them, `width` and `height` its size.
-- Nil when the eye is at or behind the glass.
export type View = {
	fov: number, -- the camera's vertical field of view, degrees
	x: number, -- the picture's middle from the glass's middle, studs, to the right as you face it
	y: number, -- and up
	width: number, -- the picture's size, studs on the glass
	height: number,
}

function Mirror.view(
	eye: Vector3,
	c: Vector3,
	n: Vector3,
	right: Vector3,
	up: Vector3,
	width: number,
	height: number
): View?
	local d = (eye - c):Dot(n)
	if d < Mirror.Near then
		return nil
	end
	local x0 = (c - eye):Dot(right)
	local y0 = (c - eye):Dot(up)
	local hw = math.abs(x0) + width / 2
	local hh = math.abs(y0) + height / 2
	local fov = 2 * math.atan(hh / d)
	local cap = math.rad(Mirror.MaxFov)
	if fov > cap then
		-- right up against the glass the edges fall outside the widest view: they show the backing
		fov = cap
		hh = d * math.tan(cap / 2)
	end
	return { fov = math.deg(fov), x = -x0, y = -y0, width = 2 * hw, height = 2 * hh }
end

return Mirror
