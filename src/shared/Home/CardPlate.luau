--!strict
--[[
	CardPlate: the plate a home's name card hangs on, over its door (S5-03g3b, D-331; idea 20,
	Bloxburg's and Animal Crossing's house signs). Walking out across the hall, your friends' names
	are stencilled, painted, chalked or lit over their doors, each in the style they chose.

	The lobby lays each home's card as an invisible writing face (Lobby.lay's `Card<UnitN>`) with
	its wall frame on it (`WallAttribute`: the point on the wall behind the card's middle, looking
	out). `hang` clones the style's parts (`Specs.Cards`) from the home template onto that frame,
	paints them, and moves the writing onto the plate's face in the style's font and ink. A blank
	home wears the Starter style's plate with nothing on it; the server hangs a held home's from
	its unit's `Looks.CardAttribute`, so every screen sees the same plate and the spray
	(HomeCards) still lands the name on it.

	The neon (S5-03g3b2, D-332) is the one plate that's a light: its name glows (the room's light
	doesn't shade it, a halo in the tube's pink round each letter), so down the floor it's the
	brightest thing on the wall. The wall's pink wash is a real light, thrown only by the neon
	cards nearest you (HomeCards, `Neon.Near`), so a hall of them stays in a phone's budget.
]]
local Looks = require("./Looks")
local Specs = require("./Specs")

local CardPlate = {}

CardPlate.WallAttribute = "CardWall" -- on a home's writing face: its wall frame (CFrame)
CardPlate.StyleAttribute = "CardStyle" -- on a home's writing face: the style it wears now
CardPlate.Plate = "Plate" -- the model of the style's parts, under the writing face
CardPlate.InkAttribute = "CardInk" -- on a home's writing face: its lettering's LightInfluence as laid
CardPlate.Halo = "Glow" -- the neon lettering's UIStroke

-- The neon's glow (D-322, D-332; Bloxburg's and Adopt Me's neon house signs).
CardPlate.Neon = {
	-- pixels of halo round each letter (the card's gui is 60 to a stud): it fattens the thin
	-- Nunito into a lit tube that reads from mid-floor without the letters running together
	Stroke = 3,
	Haze = 0.3, -- the halo's transparency: softer than the letters' white-hot core
	Near = 2, -- the neon cards nearest you that wash their wall in pink (D-271: the rest just glow)
	Reach = 48, -- studs from a point just ahead of you: the wash comes on as you cross the floor
	Fade = 0.6, -- seconds a card's wash takes to come or go, so the pick never pops
}

-- The parts a style's plate is imported with no map: the game gives them a material and colour.
-- "Paint" and "Glow" take the style's own colour.
local PLAIN: { [string]: { material: Enum.Material, colour: string } } = {
	CardSteelBolts = { material = Enum.Material.Metal, colour = "#3A3D42" }, -- graphite bolts
	CardBoardScrews = { material = Enum.Material.Metal, colour = "#B08A4A" }, -- brass
	CardChalkStick = { material = Enum.Material.SmoothPlastic, colour = "#F1F0E8" }, -- chalk
	CardNeonBack = { material = Enum.Material.SmoothPlastic, colour = "Paint" },
	CardNeonTube = { material = Enum.Material.Neon, colour = "Glow" },
}

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function weight(name: string): Enum.FontWeight
	for _, w in Enum.FontWeight:GetEnumItems() do
		if w.Name == name then
			return w
		end
	end
	return Enum.FontWeight.Regular
end

-- Style `id`'s row, or the Starter stencil's for nil or one not offered.
function CardPlate.style(id: unknown): Specs.CardStyle
	return (if type(id) == "string" then Looks.cardOf(id) else nil) or Specs.Cards[1]
end

local function inkLight(card: BasePart, style: Specs.CardStyle): number
	if style.Glow then
		return 0 -- the neon's letters glow
	end
	local laid = card:GetAttribute(CardPlate.InkAttribute)
	return if type(laid) == "number" then laid else 1
end

-- How much the room's light shades `card`'s lettering in the style it wears (its SurfaceGui's
-- LightInfluence): the neon's not at all, the rest as the lobby laid them.
function CardPlate.inkLight(card: BasePart): number
	return inkLight(card, CardPlate.style(card:GetAttribute(CardPlate.StyleAttribute)))
end

-- Where `card`'s neon light hangs: in front of its plate's middle (Specs.CardLight.Out), nil
-- for a card with no wall frame.
function CardPlate.lightAt(card: BasePart): CFrame?
	local wall = card:GetAttribute(CardPlate.WallAttribute)
	if typeof(wall) ~= "CFrame" then
		return nil
	end
	return wall * CFrame.new(0, 0, -Specs.CardLight.Out)
end

-- Hangs style `id` (nil: the Starter stencil) on `card`, a home's writing face with its
-- `WallAttribute`, from `template` (Home.template()): its parts over the door in place of what
-- was there, the writing on its face. Does nothing for a style it already wears.
function CardPlate.hang(card: BasePart, id: unknown, template: Model)
	local wall = card:GetAttribute(CardPlate.WallAttribute)
	if typeof(wall) ~= "CFrame" then
		return
	end
	local style = CardPlate.style(id)
	if card:GetAttribute(CardPlate.StyleAttribute) == style.Id then
		return
	end
	local plate = Instance.new("Model")
	plate.Name = CardPlate.Plate
	plate.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- the plate streams in whole
	for _, name in style.Parts do
		local from = template:FindFirstChild(name, true)
		if not (from and from:IsA("BasePart")) then
			warn(`CardPlate: the home template has no {name}`)
			plate:Destroy()
			return
		end
		local p = from:Clone()
		p.CFrame = wall * from.CFrame -- the template's parts are on the card's origin
		local plain = PLAIN[name]
		if plain then
			local hex = if plain.colour == "Paint"
				then style.Paint
				elseif plain.colour == "Glow" then style.Glow
				else plain.colour
			p.Material = plain.material
			p.Color = Color3.fromHex(hex or "#FFFFFF")
		elseif p:FindFirstChildOfClass("SurfaceAppearance") then
			-- the paint shows where the map is clear (the stencil's powder coat, the board's)
			p.Color = if style.Paint then Color3.fromHex(style.Paint) else Color3.new(1, 1, 1)
		end
		p.Parent = plate
	end
	local old = card:FindFirstChild(CardPlate.Plate)
	if old then
		old:Destroy()
	end
	plate.Parent = card
	card.Size = Vector3.new(style.FaceSize[1], style.FaceSize[2], card.Size.Z)
	card.CFrame = wall * CFrame.new(vec(style.Face))
	local label = card:FindFirstChildWhichIsA("TextLabel", true)
	if label then
		label.FontFace = Font.fromName(style.Font, weight(style.Weight))
		label.TextColor3 = Color3.fromHex(style.Ink)
		local halo = label:FindFirstChild(CardPlate.Halo)
		if style.Glow then
			local stroke = if halo and halo:IsA("UIStroke") then halo else Instance.new("UIStroke")
			stroke.Name = CardPlate.Halo
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual -- round the letters
			stroke.Color = Color3.fromHex(style.Glow)
			stroke.Thickness = CardPlate.Neon.Stroke
			stroke.Transparency = CardPlate.Neon.Haze
			stroke.Parent = label
		elseif halo then
			halo:Destroy()
		end
	end
	local gui = card:FindFirstChildOfClass("SurfaceGui")
	if gui then
		gui.LightInfluence = inkLight(card, style)
	end
	card:SetAttribute(CardPlate.StyleAttribute, style.Id)
end

return table.freeze(CardPlate)
