--!strict
--[[
	Infrared: the RC car's view in the dark (F-G1b3c2e, D-255), the numbers and sums its screen
	uses. Pure: nothing here touches Roblox.

	Where the lights near the car are on (a hall's motion light tripped and powered, the unit it's
	in with its bulb lit, the freight elevator's lamp), the hood view is in normal colour. Where
	they're out, it's infrared, as Outlast's camcorder and Phasmophobia's video cameras see: black
	and white with a green cast and grain, lit by a lamp only the driver's screen has, the
	monsters' eyes shining white in it. It switches with a small relay click and a quick flicker,
	as a security camera's night mode does. Back gives you your own eyes in colour at once.

	Here: when the screen judges, the slack at a pool's edge, the reach of the building's halls,
	the flicker's beats (`shown`), the look, the lamp, the click, and each monster's eyes
	(`Eyes`, `shine`).
]]

local MotionLight = require("../MotionLight")

local Infrared = {}

-- Seconds between the screen judging the light at the car: ten times a second, so a hall light
-- tripped ahead answers within a car's length and the judging costs nothing.
Infrared.Every = 0.1

-- Studs a car in colour must be past a lit pool's edge before the view goes infrared, so a car
-- parked on the edge of the light doesn't click back and forth.
Infrared.Margin = 2

-- Studs from the nearest hall light (lit or not, on the car's floor) within which the car is in
-- the building's halls, where dark is dark. Two lights' spacing (24 apart), so a unit's back wall
-- is still in; farther from every one (the lobby, lit by its own lamps) the view stays in colour.
Infrared.Building = 48

-- Of the freight elevator's lamp's range, how near it the car is in its light: the car inside, or
-- just out on the landing in the spill through its gate.
Infrared.LampShare = 0.5

-- The flicker as the view changes, seconds each: after the click the new view, then the old, the
-- new, the old, and the new holds. About a fifth of a second all told, as a camera's filter
-- snaps over.
Infrared.Flicker = table.freeze({ 0.05, 0.06, 0.04, 0.07 })

-- The look, a ColorCorrection on the driver's screen: no colour, a green cast, harder contrast,
-- a touch brighter (the camera's gain).
Infrared.Saturation = -1
Infrared.Tint = table.freeze({ 168, 255, 176 })
Infrared.Contrast = 0.3
Infrared.Brightness = 0.04
-- The grain over it (the security feed's specks and scanlines, `Feed.Grain`): its transparency,
-- lighter than the feed's, so the hall still reads on a phone.
Infrared.GrainSee = 0.6

-- The lamp only the driver's screen sees, on the hood: a wide cone lighting about 30 studs ahead
-- (the falloff takes it to black past that). Not a light in the game's rules: it holds nothing.
Infrared.LampRange = 30
Infrared.LampAngle = 84 -- degrees across: about the hood view's width
Infrared.LampBrightness = 2.4

-- The click: the hall light's relay ("Relay Clicks 15"), smaller and higher, flat in your ears.
Infrared.ClickVolume = 0.32
Infrared.ClickToDark = 1.4 -- its pitch going infrared
Infrared.ClickToColour = 1.22 -- and back to colour, a little lower

-- A monster's eyes, from its Head part's middle (studs; its face is -Z): how far up, how far
-- out in front of the face, and how far apart. Each row with eyes to light has one.
export type EyeSpot = { up: number, ahead: number, apart: number }
Infrared.Eyes = table.freeze({
	-- its blank face, about a third of the way down from the crown
	Mannequin = table.freeze({ up = 0.16, ahead = 0.3, apart = 0.18 }) :: EyeSpot,
	-- deep in its hood
	Packrat = table.freeze({ up = 0.06, ahead = 0.32, apart = 0.22 }) :: EyeSpot,
})
-- Eyes shine out to this many studs from the hood (a little past the lamp's reach: two pale
-- points at the edge of what the view shows), fading over the last `EyeFade`.
Infrared.EyeReach = 40
Infrared.EyeFade = 12
-- And only facing the car at least this much (the dot of its face and the way to the car):
-- side on, or turned away, no shine.
Infrared.EyeFacing = 0.2
-- Each eye's size on the screen: this many studs, but never under `EyeDot` pixels, so a pair far
-- down a hall still reads on a phone.
Infrared.EyeStuds = 0.09
Infrared.EyeDot = 4
-- How far past white each eye glows (its billboard's Brightness): the green cast tints anything
-- merely white, so they burn through it to white, as eyeshine does (seen in Studio Play).
Infrared.EyeGlow = 6

--- How near a lit hall light's spot the car's feet must be to be in its light: the pool's reach
--- (`MotionLight.PoolReach`), with `Margin` more while the view is already in colour.
function Infrared.reach(dark: boolean): number
	return MotionLight.PoolReach + (if dark then 0 else Infrared.Margin)
end

--- Whether feet at (x, y, z) are within `reach` across the floor of a spot on the floor at
--- (fx, fy, fz), on that floor (from a stud under it to the deck, as `MotionLight.inPool`).
function Infrared.near(
	fx: number,
	fy: number,
	fz: number,
	x: number,
	y: number,
	z: number,
	reach: number
): boolean
	local dx, dz, dy = x - fx, z - fz, y - fy
	return dx * dx + dz * dz <= reach * reach and dy >= -1 and dy <= MotionLight.WatchHeight
end

--- Whether the view shows its new look `since` seconds after it was switched (the flicker's
--- beats, `Flicker`): the new look first, then the old, the new, the old, and then the new holds.
function Infrared.shown(since: number): boolean
	if since < 0 then
		return false
	end
	local t = 0
	for i, beat in Infrared.Flicker do
		t += beat
		if since < t then
			return i % 2 == 1
		end
	end
	return true
end

--- How brightly a monster's eyes shine, 0 to 1, `distance` studs from the hood with its face
--- turned `facing` toward it (1 straight at it).
function Infrared.shine(distance: number, facing: number): number
	if facing < Infrared.EyeFacing or distance > Infrared.EyeReach then
		return 0
	end
	local fade = (Infrared.EyeReach - distance) / Infrared.EyeFade
	local turned = (facing - Infrared.EyeFacing) / (1 - Infrared.EyeFacing)
	return math.clamp(fade, 0, 1) * math.clamp(turned * 2, 0, 1)
end

return Infrared
