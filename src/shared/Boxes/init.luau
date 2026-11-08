--!strict
-- The moving boxes every unit is full of (art/boxes/README.md): their real sizes, generated from
-- the art's spec, and the templates a unit's contents are cloned from. A box is one MeshPart whose
-- pivot is the middle of its bottom and whose labelled long side faces its front (LookVector).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specs = require(script.Specs)

export type Name = "Small" | "Medium" | "Large" | "Wardrobe" | "Open"

local Boxes = {}
Boxes.Specs = Specs
Boxes.Names = { "Small", "Medium", "Large", "Wardrobe", "Open" } :: { Name }

-- The kraft under the texture, shown only if the maps fail to load.
local KRAFT = Color3.fromRGB(165, 122, 78)

-- Where the templates live: in the place, since Rojo can't sync imported meshes (D-009).
local function templates(): Instance?
	local props = ReplicatedStorage:FindFirstChild("Props")
	return if props then props:FindFirstChild("Boxes") else nil
end

-- The import's last step, once per freshly imported box, from the command bar or the MCP
-- (CollisionFidelity can't be set while the game runs). A box is scenery until a keeper wakes it:
-- anchored, colliding as its box (the opened one as its hull, flaps and all), firing no touches.
-- Its pivot stays the middle of its bottom, turned square with the part.
function Boxes.prepare(part: MeshPart, name: Name)
	part.Name = name
	part.Anchored = true
	part.CanTouch = false
	part.CollisionFidelity = if Specs.Boxes[name].Open
		then Enum.CollisionFidelity.Hull
		else Enum.CollisionFidelity.Box
	part.Color = KRAFT
	part.PivotOffset = CFrame.new(part.PivotOffset.Position)
	part:SetAttribute("Box", name)
end

-- A copy of a box standing at `pivot` (its bottom's middle, its labelled side facing the pivot's
-- LookVector), parented last. Nil, with a warning, if the place is missing the template.
function Boxes.clone(name: Name, pivot: CFrame, parent: Instance): MeshPart?
	local folder = templates()
	local template = if folder then folder:FindFirstChild(name) else nil
	if not (template and template:IsA("MeshPart")) then
		warn(
			`Boxes: no template at ReplicatedStorage.Props.Boxes.{name}; import it (art/boxes/README.md)`
		)
		return nil
	end
	local box = template:Clone()
	box:PivotTo(pivot)
	box.Parent = parent
	return box
end

return Boxes
