--!strict
--[[
	Shake: the camera's jolt when something heavy hits nearby (a slammed door first). Pure maths,
	so the client's CameraShake system applies it and Lune tests it.

	It works on "trauma", 0..1: each hit adds some and it drains away over time. The shake you see is
	trauma squared, so a small hit barely moves the view and a big one rattles it, and smooth noise
	drives it so the view shivers rather than jumps between random poses (the well-worn technique
	from Squirrel Eiserloh's GDC 2016 talk on camera shake).

	A stand-in for Brix's presentation kit (ENG-15, "camera moves"): swap it out when that ships.
]]

local Shake = {}

-- The most the view tips up/down and side to side at full trauma. Smooth noise rarely swings past
-- half its range, so 3 degrees here shows as about a 0.7 degree jolt for a slam beside you
-- (measured in Play): felt on a phone, gone before it makes anyone queasy.
Shake.MaxAngle = math.rad(3)
-- The most the view rolls at full trauma: a little twist sells the hit as a shock through the floor.
Shake.MaxRoll = math.rad(1.2)
-- The most the camera itself jumps at full trauma, in studs.
Shake.MaxOffset = 0.1
-- How fast it shivers (noise steps per second): high for a hard, metallic hit, not a sway.
Shake.Frequency = 18
-- Trauma drained per second: a full hit settles in about 0.7 s, about as long as the bang rings.
Shake.Decay = 1.4

local function clamp01(x: number): number
	return if x < 0 then 0 elseif x > 1 then 1 else x
end

-- Trauma after a hit of `amount` (capped at 1, so hits pile up but never run away).
function Shake.add(trauma: number, amount: number): number
	return clamp01(trauma + math.max(amount, 0))
end

-- Trauma after `dt` seconds of settling.
function Shake.decay(trauma: number, dt: number): number
	return math.max(trauma - Shake.Decay * dt, 0)
end

-- How much of a hit reaches someone `distance` studs away: all of it within `near`, fading
-- smoothly to none at `reach`.
function Shake.falloff(distance: number, near: number, reach: number): number
	if distance <= near then
		return 1
	elseif distance >= reach then
		return 0
	end
	local u = 1 - (distance - near) / (reach - near)
	return u * u * (3 - 2 * u)
end

local function noise(t: number, seed: number): number
	-- Perlin noise is 0 on whole numbers, so sample between them; clamp, as it can stray past 1
	return math.clamp(math.noise(t, seed + 0.5, 0.25), -1, 1)
end

--[[
	The view's offset at `trauma` and `t` seconds: pitch, yaw and roll in radians, then a shift in
	studs, all in the camera's own frame. All zero at no trauma.
]]
function Shake.offset(trauma: number, t: number): (number, number, number, number, number)
	local amount = trauma * trauma
	if amount <= 0 then
		return 0, 0, 0, 0, 0
	end
	local s = t * Shake.Frequency
	return Shake.MaxAngle * amount * noise(s, 1),
		Shake.MaxAngle * amount * noise(s, 2),
		Shake.MaxRoll * amount * noise(s, 3),
		Shake.MaxOffset * amount * noise(s, 4),
		Shake.MaxOffset * amount * noise(s, 5)
end

return Shake
