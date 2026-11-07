--!strict
--[[
	HallLight: how a hall's ceiling fixture lights the building, matched to the look sheets
	(art/sheets/unit-hall.png and unit-hero.png; D-012, D-015).

	A fixture hangs over the middle of the hall, one every two units (24 studs), 2 studs above the
	units' wire tops. Lit, it pools hard cold light on the doors and floor below and leaves the
	stretch to the next fixture dark, so the far end of a hall is swallowed. The corridor kit's
	fixture (P0-03) and the motion lights (L-03) reuse these numbers; L-03 decides which fixture is
	lit.

	Below graphics quality about 10 (Studio's levels; a low-graphics phone) lights ignore their cone
	and shine through walls (D-015), and Automatic quality switches levels mid-play. So a fixture is
	two lights: the tube's short, shadowed pool on the floor, and a shadowless fill at door height
	that lights the walls and an open unit's inside alike at every quality (D-017).

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
-- A lit fixture's strength. The floor right under it reads as a pool of light; the doors and
-- facades take most of their light from the fill below (FillBrightness).
HallLight.Brightness = 1.2
-- How far it reaches: the floor and both rows of doors under it, and no farther. Low graphics
-- ignores shadows, so a longer reach floods the open units behind the doors (22 lit a unit's back
-- wall; 14 leaves it to the fill) and the stretch to the next fixture.
HallLight.Range = 14
-- The cone, in degrees: wide enough to catch the facade above each door, narrow enough that the
-- wall tops shade the units' insides.
HallLight.Angle = 130
-- A weaker fixture far down the hall, like the sheets' distant tubes: you can see doors under it
-- but it never competes with the one you're standing under.
HallLight.Low = 0.3

-- The fill: a soft light at door height under each fixture, standing in for the light the pool
-- bounces off the floor. It casts no shadow, so at full quality it reaches into an open unit and
-- its walls read dimly, as they do at low graphics (the owner's pick, Nov 6). It sits low
-- because low graphics lights an upright wall as brightly as a floor while full quality barely
-- lights a wall from overhead; a light level with the walls lights them at both. Together with
-- the short tube this brings the two looks within about 1.7x of each other (P0-02h), so
-- Automatic quality switching mid-play shows as a small dimming, not a different hall.
HallLight.FillHeight = 5
-- Its strength: an open unit's back wall is dimly readable, the facades stay below white.
HallLight.FillBrightness = 0.9
-- Its reach: past a unit's back wall (16 studs from the hall's middle; a light fades to nothing
-- at its range, so 16 left the weak fixture's units black at full quality), and short of the
-- next fixture's stretch. Low graphics spreads light farther than full quality in the same range.
HallLight.FillRange = 20

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

	-- The fill hangs at door height on an attachment under the tube, so it moves with the fixture.
	local found = tube:FindFirstChild("Fill")
	local anchor: Attachment
	if found and found:IsA("Attachment") then
		anchor = found
	else
		anchor = Instance.new("Attachment")
		anchor.Name = "Fill"
		anchor.Parent = tube
	end
	anchor.Position = Vector3.new(0, HallLight.FillHeight - HallLight.Height, 0)
	local fill = anchor:FindFirstChildWhichIsA("PointLight") or Instance.new("PointLight")
	fill.Color = HallLight.Colour
	fill.Brightness = HallLight.FillBrightness * level
	fill.Range = HallLight.FillRange
	fill.Shadows = false
	fill.Enabled = level > 0
	mark(fill)
	fill.Parent = anchor

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
