--!strict
-- The things in a unit that are only there to look at (art/stuff/README.md): a mattress stood on
-- its end and a rolled-up carpet, leaning back against a wall, and stacks of the moving boxes.
-- Their sizes and the stacks' layouts are generated from the art's spec. A piece is one MeshPart
-- whose pivot is the middle of its bottom, its front facing its LookVector and its back meant
-- for a wall; a stack is a Model of box clones laid the same way.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boxes = require(script.Parent.Boxes)
local Specs = require(script.Specs)

export type Piece = "Mattress" | "Carpet"
export type Stack = "Tower" | "Wall" | "Heap" | "Column"
export type Name = Piece | Stack

local Stuff = {}
Stuff.Specs = Specs
Stuff.Pieces = { "Mattress", "Carpet" } :: { Piece } -- the spec's PieceOrder
Stuff.Stacks = { "Tower", "Wall", "Heap", "Column" } :: { Stack } -- the spec's StackOrder

-- What shows under the texture if its maps fail to load.
local FALLBACK: { [Piece]: Color3 } = {
	Mattress = Color3.fromRGB(214, 202, 178),
	Carpet = Color3.fromRGB(122, 44, 36),
}

-- Where the templates live: in the place, since Rojo can't sync imported meshes (D-009).
local function templates(): Instance?
	local props = ReplicatedStorage:FindFirstChild("Props")
	return if props then props:FindFirstChild("Stuff") else nil
end

-- The import's last step, once per freshly imported piece, from the command bar or the MCP in
-- Edit. A piece is scenery: anchored, colliding as its box, firing no touches, its pivot the
-- middle of its bottom turned square with the part.
function Stuff.prepare(part: MeshPart, name: Piece)
	part.Name = name
	part.Anchored = true
	part.CanTouch = false
	part.CollisionFidelity = Enum.CollisionFidelity.Box
	part.Color = FALLBACK[name]
	part.PivotOffset = CFrame.new(part.PivotOffset.Position)
	part:SetAttribute("Stuff", name)
end

-- The size a thing takes up: across, tall, deep (its back the deep side's far end).
function Stuff.size(name: Name): Vector3
	local piece = Specs.Pieces[name]
	if piece then
		return piece.Size
	end
	return Specs.Stacks[name].Size
end

local function piece(name: Piece, pivot: CFrame, parent: Instance): MeshPart?
	local folder = templates()
	local template = if folder then folder:FindFirstChild(name) else nil
	if not (template and template:IsA("MeshPart")) then
		warn(
			`Stuff: no template at ReplicatedStorage.Props.Stuff.{name}; import it (art/stuff/README.md)`
		)
		return nil
	end
	local part = template:Clone()
	part:PivotTo(pivot)
	part.Parent = parent
	return part
end

local function stack(name: Stack, pivot: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = name
	for _, row in Specs.Stacks[name].Boxes do
		local at = pivot * CFrame.new(row.Position) * CFrame.Angles(0, math.rad(row.Turn), 0)
		Boxes.clone(row.Box :: Boxes.Name, at, model)
	end
	model:SetAttribute("Stuff", name)
	model.WorldPivot = pivot
	model.Parent = parent
	return model
end

-- Lays a thing with its middle on the floor at `pivot`, its front facing the pivot's LookVector:
-- a piece's clone, or a stack's boxes in a Model. Parented last. Nil, with a warning, if the
-- place is missing a piece's template.
function Stuff.lay(name: Name, pivot: CFrame, parent: Instance): Instance?
	if Specs.Pieces[name] then
		return piece(name :: Piece, pivot, parent)
	end
	return stack(name :: Stack, pivot, parent)
end

return Stuff
