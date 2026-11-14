--!strict
--[[
	HallLight: how a hall's ceiling fixture lights the building, matched to the look sheets
	(art/sheets/unit-hall.png and unit-hero.png; D-012, D-015).

	A fixture hangs over the middle of the hall, one every two units (24 studs), 2 studs above the
	units' unit tops. Lit, it pools hard cold light on the doors and floor below and leaves the
	stretch to the next fixture dark, so the far end of a hall is swallowed. The corridor kit's
	fixture (P0-03) and the motion lights (L-03) reuse these numbers; L-03 decides which fixture is
	lit.

	Below graphics quality about 10 (Studio's levels; a low-graphics phone) lights ignore their cone
	and shine through walls (D-015), and Automatic quality switches levels mid-play. So a fixture is
	two lights: the tube's short, shadowed pool on the floor, and a shadowless fill at door height
	that lights the walls and an open unit's inside alike at every quality (D-017). Under a lit
	tube a few slow puffs of dust glow grey in the air, the look sheets' haze (D-018).

	`HallLight.light(tube, level, real)` turns a fixture's diffuser part into a lit tube: level 1 is
	a fixture at full strength, `HallLight.Low` a weaker one far down the hall, 0 a dead one. With
	`real` false the tube glows but throws no light and no dust: a phone draws real lights only
	for the few lit fixtures nearest the camera (`NearFixtures`). `HallLight.glow` is the tube and
	its lights alone, for the frames of a tube flickering on (`Flicker`).
	`HallLight.eye(eye, state)` sets the dome of the fixture's motion sensor: the building's eye,
	open, seeing something, or blind (GDD Lights). The fixture itself is the corridor kit's
	(CorridorKit.hang); the server decides whether it's lit (MotionLights) and each player's
	screen draws it (HallLights).
]]
local HallLight = {}

-- Where the fixture's diffuser hangs (its centre, in studs above the floor). Low over the unit
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

-- How many lit fixtures throw real light on a player's screen: the ones nearest the camera. Each
-- is two lights (D-017), so three is six; a lit fixture farther out is its glowing tube alone,
-- which reads at that distance (GDD tech plan; the owner judges it, Nov 7).
HallLight.NearFixtures = 3
-- A fixture already throwing light keeps it until another is this many studs nearer, so two
-- fixtures about as far away don't trade their light back and forth as you walk.
HallLight.NearMargin = 8
-- Nearness is measured from this many studs ahead of the camera, along the floor, so the light
-- you're walking into gets real light before the one you've just left behind.
HallLight.NearLead = 12
-- How often each screen re-picks its nearest fixtures, in seconds.
HallLight.NearSeconds = 0.25

-- A tube coming on as a motion light trips: light at once, with the click, then one stutter as
-- the starter catches, steady within a tenth of a second (each step's level, at seconds after the
-- trip). Quick, so the light keeps up with you (the owner, Nov 7).
HallLight.Flicker = table.freeze({
	{ at = 0, level = 0.9 },
	{ at = 0.05, level = 0.3 },
	{ at = 0.1, level = 1 },
})

-- The alarm's lights out (S2-04c): a wrong code kills every hall light on the floor at once. Each
-- tube dies in a stutter as the power sags (each step's level, at seconds after the cut); a dark
-- fixture's red eye stutters out the same way. Each fixture starts up to `CutStagger` late, so
-- the halls drop to black raggedly around you, not like a switch. Short, so the dark you see is
-- the dark the Mannequins move in.
HallLight.CutFlicker = table.freeze({
	{ at = 0, level = 0.35 },
	{ at = 0.05, level = 0.9 },
	{ at = 0.1, level = 0.15 },
	{ at = 0.16, level = 0.6 },
	{ at = 0.22, level = 0 },
})
HallLight.CutStagger = 0.12
-- Its power coming back when the keypad clears: each eye stutters back to red and its tube gives
-- a faint surge (`BackSurge` of full) on each step, then settles to dark, or clicks on if someone
-- is under it. Raggeder than the cut (`BackStagger`), a building's power finding its way back.
HallLight.BackFlicker = table.freeze({
	{ at = 0, level = 0.7 },
	{ at = 0.05, level = 0 },
	{ at = 0.13, level = 1 },
	{ at = 0.18, level = 0.2 },
	{ at = 0.26, level = 1 },
})
HallLight.BackStagger = 0.3
HallLight.BackSurge = 0.4

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

-- The haze: dust hanging in the air under a lit tube, glowing grey as in the look sheets, so a
-- lit stretch of hall reads as somewhere you could be seen. A few slow puffs of Roblox's smoke
-- texture drift around a point under the tube (P0-02i).
-- Where the puffs gather, in studs above the floor: low enough that none reaches the ceiling's
-- lowest steel (the corridor kit's joists, 12.8), because low graphics draws a hard line where a
-- puff cuts into it. tests/corridor.spec.luau holds the two apart.
HallLight.HazeHeight = 9.6
-- Pale cold grey, like the tube. Dimmed with the fixture's level, so a weak tube's haze is faint.
HallLight.HazeColour = Color3.fromRGB(190, 195, 200)
-- How much the puffs take their brightness from the hall's lights rather than glowing by
-- themselves. Low graphics lights a puff about twice as brightly as full quality does, as it does
-- the walls (D-017), so most of it is their own glow: the two looks stay close.
HallLight.HazeLightInfluence = 0.4
-- A puff at its thickest: the far doors still show through the cloud.
HallLight.HazeTransparency = 0.5
-- A puff's width as it starts and as it spreads out, in studs: kept narrower than the hall
-- (8 studs), so it doesn't cut into the facades either.
HallLight.HazeSizeStart = 4
HallLight.HazeSizeEnd = 6
-- Puffs per second and how long each lives: about six in the air per lit fixture, few enough for
-- a low-end phone (each is see-through, so it costs its whole screen area to draw). Each player's
-- screen emits these itself (HallHaze), because Roblox thins an emitter's own rate on low graphics.
HallLight.HazeRate = 0.4
HallLight.HazeLifetime = NumberRange.new(12, 16)
-- How fast a puff drifts, in studs a second: slow enough that the cloud seems to hang.
HallLight.HazeDrift = NumberRange.new(0.12, 0.28)
-- Puffs thrown out at once when a fixture comes on, so the air is already dusty under it.
HallLight.HazeBurst = 5

-- The stairwell's exit sign at the end of a hall: the one warm thing in it, a red smear on the
-- last doors that pulls the eye down the hall.
HallLight.ExitColour = Color3.fromRGB(255, 42, 26)
-- A red wash on the wall the sign hangs on, so a dead end reads as a wall and not an opening; pale
-- walls beside it only take a tint, never a red room (tuned at Level21 on the A16, P0-03c).
HallLight.ExitBrightness = 0.2
HallLight.ExitRange = 10 -- the wall it hangs on and the last unit's width before it
-- The glow hangs this far out from the sign and below it: a light on the wall itself only grazes it.
HallLight.ExitGlowOut = 1.5
HallLight.ExitGlowDrop = 1

-- The line of light under a shut door, seen from inside: the lit hall floor through the door's
-- gap. Neon glows brighter than its colour, so this mid grey reads as a hard white line against
-- the dark; any brighter and low-graphics bloom smears it into blobs.
HallLight.UnderDoorColour = Color3.fromRGB(140, 145, 144)

-- The motion sensor's dome on each fixture's end: the building's eye (GDD Lights: the motion
-- lights are its eyes). Open, it glows red, so even a dark stretch of hall is dotted with eyes
-- looking down at you; when it sees something move it flares to full red; when the breaker room
-- cuts a zone's power it goes blind, dead grey plastic. The dome is small, so even full red stays
-- a clean dot at Level01 rather than blooming into a blob (Studio, Galaxy A16, P0-03b).
export type EyeState = "Watching" | "Seen" | "Blind"
-- Open in the dark: from the spawn the nearest eye is a sharp red dot, the next a pin-prick.
HallLight.EyeWatching = Color3.fromRGB(150, 16, 10)
-- It saw something move: a clear jump up from watching, so a flare reads from down the hall.
HallLight.EyeSeen = Color3.fromRGB(255, 40, 24)
-- Power cut: frosted plastic, barely there in the dark.
HallLight.EyeBlind = Color3.fromRGB(58, 58, 56)
-- The flare as it trips: a hot, nearly white red for an instant, the eye snapping open on you,
-- before it settles to Seen. It reads from down the hall, ahead of the tube's flicker.
HallLight.EyeFlare = Color3.fromRGB(255, 150, 120)
-- How long the flare takes to settle to Seen, in seconds.
HallLight.EyeFlareSeconds = 0.45
-- How long a seen eye takes to sink back to Watching as its light falls dark, in seconds: slower
-- than the flare, the building losing interest.
HallLight.EyeRelaxSeconds = 0.8

-- The sensor's relay clicking as the light trips, the GDD's click: a short clunky tick from
-- Roblox's audio library (Pro Sound Effects, "Relay Clicks 15"). It carries two halls over, so a
-- click with nobody in sight is a friend or a keeper, and you can't tell which.
HallLight.ClickSound = "rbxassetid://9118138693"
HallLight.ClickVolume = 0.7
-- Each click's pitch is picked within this, so a row of lights waking doesn't sound stamped out.
HallLight.ClickPitch = NumberRange.new(0.94, 1.06)
-- The same relay letting go as the light falls dark: quieter and lower, so you hear that you've
-- gone dark to it without it drawing the ear like a trip.
HallLight.ClickOffVolume = 0.3
HallLight.ClickOffPitch = 0.82
-- Full volume within this many studs; it fades out by ClickReach (about two halls over).
HallLight.ClickNear = 10
HallLight.ClickReach = 90

-- The alarm's lights out, heard by everyone on the floor (not placed: the whole floor's power).
-- The cut: a light's power dying, a falling whine from 4 kHz to 500 Hz in 1.6 s then a fade
-- ("light power off", 4.05 s, loud from its first moment). The return: a fluorescent tube's
-- flicker (2.26 s, quiet, so it plays louder). `OutGap` seconds keeps one floor's many fixtures to
-- one sound.
HallLight.CutSound = "rbxassetid://106554188841955"
HallLight.CutVolume = 0.8
HallLight.CutSpeed = 0.85 -- a touch slow: a building's mains, not a lamp
HallLight.BackSound = "rbxassetid://116266785932124"
HallLight.BackVolume = 1.6
HallLight.OutGap = 1

-- Every light the hall throws carries this tag, and its lit brightness in the attribute
-- `HallLight.LitAttribute`, so a client can scale it on its own screen and put it back exactly
-- (BehindDoors darkens them for a player shut in a unit).
HallLight.Tag = "HallLight"
HallLight.LitAttribute = "LitBrightness"
-- Every fixture's dust emitter carries this tag, so each client can keep its puffs coming
-- (HallHaze).
HallLight.HazeTag = "HallHaze"

local DEAD_TUBE = Color3.fromRGB(40, 42, 44) -- an unlit diffuser: dark plastic

local function mark(light: Light)
	light:SetAttribute(HallLight.LitAttribute, light.Brightness)
	light:AddTag(HallLight.Tag)
end

-- The attachment named `name` under `tube`, hanging `height` studs above the floor; made if missing.
local function under(tube: BasePart, name: string, height: number): Attachment
	local found = tube:FindFirstChild(name)
	local anchor: Attachment
	if found and found:IsA("Attachment") then
		anchor = found
	else
		anchor = Instance.new("Attachment")
		anchor.Name = name
		anchor.Parent = tube
	end
	anchor.Position = Vector3.new(0, height - HallLight.Height, 0)
	return anchor
end

local function fadeInOut(peak: number): NumberSequence
	-- A puff thickens in, hangs, and thins out again, so none pops in or out.
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, peak),
		NumberSequenceKeypoint.new(0.7, peak),
		NumberSequenceKeypoint.new(1, 1),
	})
end
local HAZE_SHOWN = fadeInOut(HallLight.HazeTransparency)
local HAZE_HIDDEN = NumberSequence.new(1)

-- The dust under a fixture at `level`. A dead fixture's dust vanishes at once (a puff's look is
-- read from the emitter every frame, so hiding them reaches those already in the air).
local function haze(anchor: Attachment, level: number)
	local found = anchor:FindFirstChildWhichIsA("ParticleEmitter")
	local wasLit = found ~= nil and found.Enabled
	local dust = found or Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(HallLight.HazeColour:Lerp(Color3.new(), 1 - level))
	dust.LightInfluence = HallLight.HazeLightInfluence
	dust.LightEmission = 0
	dust.Size = NumberSequence.new(HallLight.HazeSizeStart, HallLight.HazeSizeEnd)
	dust.Transparency = if level > 0 then HAZE_SHOWN else HAZE_HIDDEN
	dust.Lifetime = HallLight.HazeLifetime
	-- Roblox thins an emitter's steady puffs to about (graphics level ÷ 21) of its Rate, leaving a
	-- low-graphics phone under one puff per tube, but never thins Emit. So the steady puffs come
	-- from each client, one Emit at a time (HallHaze), and the emitter's own rate stays 0.
	dust.Rate = 0
	dust.Speed = HallLight.HazeDrift
	-- Puffs drift outward in a flat fan, so the cloud spreads along the hall, not into the ceiling.
	dust.EmissionDirection = Enum.NormalId.Right
	dust.SpreadAngle = Vector2.new(180, 12)
	dust.Rotation = NumberRange.new(0, 360)
	dust.RotSpeed = NumberRange.new(-3, 3)
	dust.Enabled = level > 0
	dust:AddTag(HallLight.HazeTag)
	dust.Parent = anchor
	-- Emitting replicates to players already watching; the server is where fixtures are lit.
	if level > 0 and not wasLit then
		dust:Emit(HallLight.HazeBurst)
	end
end

-- Sets `tube` (the fixture's diffuser part) glowing at `level` (0 to 1) and its two lights to
-- match, or off when `real` is false. No dust: this is the light alone, for a tube flickering on.
function HallLight.glow(tube: BasePart, level: number, real: boolean?)
	local on = level > 0 and real ~= false
	local light = tube:FindFirstChildWhichIsA("SurfaceLight") or Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Color = HallLight.Colour
	light.Brightness = HallLight.Brightness * level
	light.Range = HallLight.Range
	light.Angle = HallLight.Angle
	light.Shadows = true
	light.Enabled = on
	mark(light)
	light.Parent = tube
	tube.CastShadow = false

	-- The fill hangs at door height on an attachment under the tube, so it moves with the fixture.
	local anchor = under(tube, "Fill", HallLight.FillHeight)
	local fill = anchor:FindFirstChildWhichIsA("PointLight") or Instance.new("PointLight")
	fill.Color = HallLight.Colour
	fill.Brightness = HallLight.FillBrightness * level
	fill.Range = HallLight.FillRange
	fill.Shadows = false
	fill.Enabled = on
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

-- Turns `tube` into a lit tube at `level` (0 to 1): its glow, its two lights and the dust under
-- it. With `real` false it only glows, with no light thrown and no dust (a far fixture).
function HallLight.light(tube: BasePart, level: number, real: boolean?)
	HallLight.glow(tube, level, real)
	haze(under(tube, "Haze", HallLight.HazeHeight), if real == false then 0 else level)
end

-- Sets a fixture's sensor dome to show what the building's eye is doing there.
function HallLight.eye(eye: BasePart, state: EyeState)
	eye.CastShadow = false
	if state == "Blind" then
		eye.Material = Enum.Material.SmoothPlastic
		eye.Color = HallLight.EyeBlind
	else
		eye.Material = Enum.Material.Neon
		eye.Color = if state == "Seen" then HallLight.EyeSeen else HallLight.EyeWatching
	end
end

-- Turns `sign` into a lit exit sign whose glow washes the wall it hangs on and tints the hall
-- around it. `facing` points from the wall into the hall.
function HallLight.exitSign(sign: BasePart, facing: Vector3)
	sign.Material = Enum.Material.Neon
	sign.Color = HallLight.ExitColour
	sign.CastShadow = false
	local found = sign:FindFirstChild("Glow")
	local at: Attachment = if found and found:IsA("Attachment")
		then found
		else Instance.new("Attachment")
	at.Name = "Glow"
	at.Position = sign.CFrame:VectorToObjectSpace(
		facing.Unit * HallLight.ExitGlowOut - Vector3.yAxis * HallLight.ExitGlowDrop
	)
	at.Parent = sign
	local glow = at:FindFirstChildWhichIsA("PointLight") or Instance.new("PointLight")
	glow.Color = HallLight.ExitColour
	glow.Brightness = HallLight.ExitBrightness
	glow.Range = HallLight.ExitRange
	glow.Shadows = true
	mark(glow)
	glow.Parent = at
end

return HallLight
