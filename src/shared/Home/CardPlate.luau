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
]]
local Looks = require("./Looks")
local Specs = require("./Specs")

local CardPlate = {}

CardPlate.WallAttribute = "CardWall" -- on a home's writing face: its wall frame (CFrame)
CardPlate.StyleAttribute = "CardStyle" -- on a home's writing face: the style it wears now
CardPlate.Plate = "Plate" -- the model of the style's parts, under the writing face

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
	end
	card:SetAttribute(CardPlate.StyleAttribute, style.Id)
end

return table.freeze(CardPlate)
