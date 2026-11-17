--!strict
--[[
	UnitLight: the bulb in each unit and the light it throws (L-04b, D-033).

	The hall's light stops at a unit's doorway, so every unit has its own: a caged bulb on a short
	cord under its steel top (CorridorKit.hangBulb). It's wired to the door like a fridge's light
	(ShutIn.bulb): the door starts up, the switch clicks and a weak bulb stutters on over whatever's
	in there; the door lands and it's out. So a shut unit stays black but for the line under its
	door, and an open one shows what it holds in a dim, warm light that leaves its back corners
	dark, a different colour from the hall's cold tubes, so you can tell from down the hall which
	glow is a unit someone opened.

	`UnitLight.light(glass, level, real)` sets a bulb's glass glowing at `level` (0 to 1) and its
	light to match; with `real` false it glows but throws no light, because a phone draws real
	light only for the few lit bulbs nearest the camera (`NearBulbs`). Its light carries HallLight's
	tag and lit brightness, so BehindDoors dims it on the screen of someone shut in another unit:
	on a low-graphics phone a lit neighbour's bulb would otherwise shine through the wall
	(D-016). UnitLights (client) decides which bulbs are lit and plays the click, stutter and hum.
]]
local HallLight = require("./HallLight")

local UnitLight = {}

-- A low, dirty incandescent: amber against the hall's cold white, so wood, cardboard and skin go
-- warm under it and a lit unit reads as somebody's, not the building's.
UnitLight.Colour = Color3.fromRGB(255, 172, 104)
-- Its strength: what's at the back is plain from the doorway, never bright. Half the hall's tube
-- (1.2), so stepping out of a unit into a lit hall is stepping into the building's eye. At 1 an
-- M unit read as a lit room, walls to the corners (Studio, Galaxy A16, Level21).
UnitLight.Brightness = 0.6
-- How far it reaches, in studs from the glass (8.7 up, over the middle of the unit): the floor at
-- an M unit's back wall is about 10 away and its back corners about 12, and a light fades to
-- nothing at its range, so the boxes against the back wall show and the corners fall to dark.
UnitLight.Range = 11
-- Shadows on, so the boxes throw them across the floor (full quality; low graphics draws none).
-- The guard casts none (CorridorKit.prepare): from a point light its six wires threw hard black
-- bands across the whole room.
UnitLight.Shadows = true

-- The glass lit: a hot amber dot. Neon reads brighter than its colour, and a small bright one
-- blooms into a halo at low graphics, so it sits below white (docs/STUDIO.md, Lighting).
UnitLight.GlassLit = Color3.fromRGB(240, 170, 104)
-- The glass dead: grey, dusty, barely there in the dark.
UnitLight.GlassDark = Color3.fromRGB(58, 56, 52)

-- The bulb coming on: the switch clicks, the filament catches, drops out once on a bad contact,
-- catches again and holds: a stutter you see, steady within a third of a second (each step's
-- level, at seconds after it trips). Slower and lumpier than the hall's tube, so it reads as old
-- wiring rather than the building waking.
UnitLight.Flicker = table.freeze({
	{ at = 0, level = 0.5 },
	{ at = 0.05, level = 0 },
	{ at = 0.12, level = 0.85 },
	{ at = 0.19, level = 0.2 },
	{ at = 0.3, level = 1 },
})

-- How many lit bulbs throw real light on a player's screen: the ones nearest a point just ahead
-- of the camera. Three, as the hall's fixtures (HallLight.NearFixtures; GDD tech plan: cap real
-- lights for low-end phones); a lit bulb farther off is its glowing glass alone.
UnitLight.NearBulbs = 3
-- A bulb already throwing light keeps it until another is this many studs nearer, so two open
-- units about as far away don't trade their light back and forth as you walk past.
UnitLight.NearMargin = 4
-- Nearness is measured from this far ahead of the camera, along the floor: the unit you're
-- looking into wins over the one behind you.
UnitLight.NearLead = 6
-- How often each screen re-picks its nearest bulbs, in seconds.
UnitLight.NearSeconds = 0.25

-- The switch catching as the door lifts it: a sharp toggle click (Pro Sound Effects, "Moviola
-- Toggle Switch Single Clicks Sharp 8"), its faint release a quarter second later. Quieter than
-- the door's rattle, which it rides on; heard across the hall, not down it.
UnitLight.ClickSound = "rbxassetid://9117028600"
UnitLight.ClickVolume = 0.45
UnitLight.ClickPitch = NumberRange.new(0.92, 1.08) -- each click picked within this
UnitLight.ClickNear = 6 -- full volume within this many studs
UnitLight.ClickReach = 36 -- gone by here: a hall's width and a few units along

-- A lit bulb's hum: a filament's faint buzz (Pro Sound Effects, "Light Bulb Buzz 2", a 49 s
-- loop), only heard standing in or at the door of the unit, so a lit unit sounds occupied even
-- when it's empty. Only the bulbs throwing real light hum.
UnitLight.HumSound = "rbxassetid://9112823813"
UnitLight.HumVolume = 0.12
UnitLight.HumNear = 3
UnitLight.HumReach = 14

-- A home's bulb: the ground floor's units (Lobby.front marks its lamp with this attribute). An XL
-- unit is three times an M's depth and someone keeps their things in it, so it hangs stronger and
-- reaches further: lit, it fills the unit and spills a warm pool out of the doorway onto the
-- lobby's cold-lit concrete, so every open unit reads from the spawn as a lit doorway (the home's
-- point, D-259: everyone sees everyone's units on the way to the cars). It casts no shadow, so all
-- twelve can throw real light at once on a phone without the shadow cost: a home bulb is never
-- one of the NearBulbs, it throws light whenever it's lit. With no shadow it reaches through the
-- unit's walls; its neighbours are homes too, and the warm wash on the lobby's wall between two
-- open doors reads as more of the same light.
UnitLight.HomeAttribute = "HomeBulb"
UnitLight.Home = table.freeze({
	Range = 22, -- from the glass (15 in, 9.8 up) to the floor a few studs out of the doorway
	Strength = 1.7, -- times a climb bulb's brightness: about 1, just under the hall tube's 1.2
	-- A home's round ceiling lamp (Home, S5-03a2b3) is a clean, warm white, not the climb bulb's
	-- dirty amber: the oak and the plaster read as themselves, softly warmed.
	Colour = Color3.fromRGB(255, 214, 168),
	GlassLit = Color3.fromRGB(255, 240, 220), -- its diffuser lit: a soft cream disc
	GlassDark = Color3.fromRGB(214, 208, 196), -- off: white plastic in shadow, not a dead bulb
})

-- Whether `glass` is a home's bulb (UnitLight.Home).
function UnitLight.isHome(glass: BasePart): boolean
	return glass:GetAttribute(UnitLight.HomeAttribute) == true
end

local function lightOf(glass: BasePart): PointLight
	local found = glass:FindFirstChildWhichIsA("PointLight")
	if found then
		return found
	end
	local light = Instance.new("PointLight")
	local home = UnitLight.isHome(glass)
	light.Color = if home then UnitLight.Home.Colour else UnitLight.Colour
	light.Range = if home then UnitLight.Home.Range else UnitLight.Range
	light.Shadows = UnitLight.Shadows and not home
	light:AddTag(HallLight.Tag)
	light.Parent = glass
	return light
end

-- Sets `glass` (a bulb's glass part) glowing at `level` (0 to 1) and its light to match, or
-- throwing none when `real` is false.
function UnitLight.light(glass: BasePart, level: number, real: boolean?)
	local light = lightOf(glass)
	light.Brightness = UnitLight.Brightness
		* level
		* (if UnitLight.isHome(glass) then UnitLight.Home.Strength else 1)
	light:SetAttribute(HallLight.LitAttribute, light.Brightness)
	light.Enabled = level > 0 and real ~= false
	glass.CastShadow = false
	local home = UnitLight.isHome(glass)
	local dark = if home then UnitLight.Home.GlassDark else UnitLight.GlassDark
	if level > 0 then
		glass.Material = Enum.Material.Neon
		-- a stuttering bulb glows dimmer too, so its glow matches its light
		local lit = if home then UnitLight.Home.GlassLit else UnitLight.GlassLit
		glass.Color = dark:Lerp(lit, math.min(1, 0.2 + level))
	else
		glass.Material = Enum.Material.SmoothPlastic
		glass.Color = dark
	end
end

return UnitLight
