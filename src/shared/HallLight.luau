--!strict
--[[
	HallLight: how a hall's ceiling fixture lights the building, matched to the look sheets
	(art/sheets/unit-hall.png and unit-hero.png; D-012, D-015).

	A fixture hangs over the middle of the hall, one every two units (24 studs), 2 studs above the
	units' wire tops. Lit, it pools hard cold light on the doors and floor below and leaves the
	stretch to the next fixture dark, so the far end of a hall is swallowed. The corridor kit's
	fixture (P0-03) and the motion lights (L-03) reuse these numbers; L-03 decides which fixture is
	lit.

	The match holds only where Roblox draws its full lighting (graphics quality about 11 and up in
	Studio's levels): below that, lights ignore their cone and shine through thin walls (D-015).

	`HallLight.light(tube, level)` turns a fixture's diffuser part into a lit tube: level 1 is a
	fixture at full strength, `HallLight.Low` a weaker one far down the hall, 0 a dead one.
]]
local HallLight = {}

-- Where the fixture's diffuser hangs (its centre, in studs above the floor). Low over the wire
-- tops (10), so the walls shade the units' insides from it, as in the sheets.
HallLight.Height = 12.1
-- The diffuser: a long thin tube across the hall's length.
HallLight.TubeSize = Vector3.new(3.8, 0.1, 0.44)
-- Cold, nearly neutral white: concrete and paint keep their own colour under it.
HallLight.Colour = Color3.fromRGB(228, 236, 238)
-- A lit fixture's strength. The doors right under it read clearly, the facades between fixtures
-- fall to dark grey, nothing turns white.
HallLight.Brightness = 1.6
-- How far it reaches: the floor and both rows of doors, but not the next fixture's pool 24 studs
-- away, so the stretch between stays dark.
HallLight.Range = 22
-- The cone, in degrees: wide enough to catch the facade above each door, narrow enough that the
-- wall tops shade the units' insides.
HallLight.Angle = 130
-- A weaker fixture far down the hall, like the sheets' distant tubes: you can see doors under it
-- but it never competes with the one you're standing under.
HallLight.Low = 0.3

-- The stairwell's exit sign at the end of a hall: the one warm thing in it, a red smear on the
-- last doors that pulls the eye down the hall.
HallLight.ExitColour = Color3.fromRGB(255, 42, 26)
HallLight.ExitBrightness = 0.45 -- a tint on the far doors' edges, never a red room
HallLight.ExitRange = 12 -- reaches the last pair of units only

-- The line of light under a shut door, seen from inside: the lit hall floor through the door's
-- gap. Neon glows brighter than its colour, so this mid grey reads as a hard white line against
-- the dark; any brighter and low-graphics bloom smears it into blobs.
HallLight.UnderDoorColour = Color3.fromRGB(140, 145, 144)

-- Every light the hall throws carries this tag, and its lit brightness in the attribute
-- `HallLight.LitAttribute`, so a client can scale it on its own screen and put it back exactly
-- (BehindDoors darkens them for a player shut in a unit).
HallLight.Tag = "HallLight"
HallLight.LitAttribute = "LitBrightness"

local DEAD_TUBE = Color3.fromRGB(40, 42, 44) -- an unlit diffuser: dark plastic

local function mark(light: Light)
	light:SetAttribute(HallLight.LitAttribute, light.Brightness)
	light:AddTag(HallLight.Tag)
end

-- Turns `tube` (the fixture's diffuser part) into a lit tube at `level` (0 to 1).
function HallLight.light(tube: BasePart, level: number)
	local light = tube:FindFirstChildWhichIsA("SurfaceLight") or Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Color = HallLight.Colour
	light.Brightness = HallLight.Brightness * level
	light.Range = HallLight.Range
	light.Angle = HallLight.Angle
	light.Shadows = true
	light.Enabled = level > 0
	mark(light)
	light.Parent = tube
	tube.CastShadow = false
	if level > 0 then
		tube.Material = Enum.Material.Neon
		-- A weaker tube glows dimmer too, so its glow matches its light.
		tube.Color = HallLight.Colour:Lerp(Color3.new(), 1 - math.min(1, 0.25 + level))
	else
		tube.Material = Enum.Material.SmoothPlastic
		tube.Color = DEAD_TUBE
	end
end

-- Turns `sign` into a lit exit sign whose glow tints the hall around it.
function HallLight.exitSign(sign: BasePart)
	sign.Material = Enum.Material.Neon
	sign.Color = HallLight.ExitColour
	sign.CastShadow = false
	local glow = sign:FindFirstChildWhichIsA("PointLight") or Instance.new("PointLight")
	glow.Color = HallLight.ExitColour
	glow.Brightness = HallLight.ExitBrightness
	glow.Range = HallLight.ExitRange
	glow.Shadows = true
	mark(glow)
	glow.Parent = sign
end

return HallLight
