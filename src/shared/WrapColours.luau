--!strict
--[[
	Wrap colours (S3-04a, GDD "Monetization"): the colour of the film you're wrapped in when you're
	caught, bought once at the counter and yours for good. The moment it serves: a friend lifts your
	door and finds you wrapped in your colour, the one they know is you. Real pallet film comes in
	colours too, so a coloured wrap still looks like the stuff a storage building has on a roll.

	Each colour is one Robux product (`Products` makes a row of each), sold at the counter (S3-04b).
	Bought, it's owned for good (`wraps` in the save, by offer name, stamped with when) and worn at
	once (`wornWrap`); an owned colour is never sold again. The film itself stays the one model
	(art/keptwrap): its colour map is a near-white clear film, and a colour is the tint its
	SurfaceAppearance's `Color` multiplies that map by, set by the server as it wraps you
	(KeptPlayers), so every screen sees it with nothing more sent. Nothing random, ever: each colour
	is bought by name at a fixed price (GDD: nothing random is sold).

	Patterns (the GDD's "colour or pattern") need art of their own and come later (ROADMAP S3-04c).
]]

export type Colour = {
	-- The offer's name: its `Products` row, its key in the save.
	name: string,
	-- What the shop calls it, and the product's title on the Creator Dashboard with " Wrap" after.
	label: string,
	-- What the film's clear near-white colour map is multiplied by, as red, green and blue from 0
	-- to 255 (plain numbers, so the shelf loads under Lune; `tint` makes the Color3). Kept bright
	-- enough that the film still reads as film in a flashlight's beam at phone size.
	rgb: { number },
}

-- The player attribute (on the server's Player) naming the colour they wear: an offer name here,
-- or empty for the plain clear film. Set from the save as it loads and as a colour is bought, so
-- the server's wrap and every screen read it without the save.
local Attribute = "WrapColour"

-- The plain film's own tint, red, green and blue: no change to its colour map.
local PLAIN = table.freeze({ 255, 255, 255 })

-- The shelf, in the order the counter shows it (the owner sets each price on the Dashboard;
-- defaults are in OWNER.md). Six plain colours, the first ones real film comes in.
local Shelf: { Colour } = {
	{ name = "wrapBlue", label = "Blue", rgb = { 70, 140, 255 } },
	{ name = "wrapRed", label = "Red", rgb = { 255, 64, 56 } },
	{ name = "wrapGreen", label = "Green", rgb = { 80, 225, 96 } },
	{ name = "wrapPink", label = "Pink", rgb = { 255, 118, 196 } },
	{ name = "wrapOrange", label = "Orange", rgb = { 255, 140, 30 } },
	{ name = "wrapBlack", label = "Black", rgb = { 42, 42, 48 } },
}

local byName: { [string]: Colour } = {}
for _, colour in Shelf do
	table.freeze(colour.rgb)
	table.freeze(colour)
	byName[colour.name] = colour
end

-- What a save needs for wrap colours: the colours owned, by offer name, and the one worn.
type Holds = { wraps: { [string]: number }, wornWrap: string }

local WrapColours = {
	Attribute = Attribute,
	Shelf = table.freeze(Shelf),
	Plain = PLAIN,
}

-- The colour named `name`, or nil when it isn't one (the plain film's empty name included).
function WrapColours.get(name: string?): Colour?
	return if name then byName[name] else nil
end

-- Whether `data` owns the colour named `name`.
function WrapColours.owns(data: Holds, name: string): boolean
	return data.wraps[name] ~= nil
end

-- A colour bought: owned for good from `now` (the first time it was bought, should it come again)
-- and worn at once, as a bought thing is put straight on.
function WrapColours.own(data: Holds, name: string, now: number)
	if data.wraps[name] == nil then
		data.wraps[name] = math.max(0, math.floor(now))
	end
	data.wornWrap = name
end

-- Puts on the colour named `name` (empty for the plain film): why it can't, or nil once worn.
function WrapColours.wear(data: Holds, name: string): string?
	if name ~= "" then
		if byName[name] == nil then
			return "notAColour"
		elseif data.wraps[name] == nil then
			return "notOwned"
		end
	end
	data.wornWrap = name
	return nil
end

-- What `data` wears: an owned colour's name, or empty for the plain film (a worn name that's no
-- longer a colour, or no longer owned, is the plain film).
function WrapColours.worn(data: Holds): string
	local name = data.wornWrap
	return if byName[name] ~= nil and data.wraps[name] ~= nil then name else ""
end

-- The red, green and blue the film is tinted by for the colour named `name`: the plain film's
-- (white, no change) for anything that isn't a colour.
function WrapColours.rgb(name: string?): { number }
	local colour = WrapColours.get(name)
	return if colour then colour.rgb else PLAIN
end

-- The film's tint (its SurfaceAppearance's `Color`) for the colour named `name`. Roblox only.
function WrapColours.tint(name: string?): Color3
	local rgb = WrapColours.rgb(name)
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

return table.freeze(WrapColours)
