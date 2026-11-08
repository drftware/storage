--!strict
-- The finds: what's worth taking out of a unit (art/finds/README.md). The 1980s bedroom set comes
-- first: a boombox, a portable TV, a mended teddy and a pair of roller skates, all wearing one
-- texture set. Their sizes are generated from the art's spec; the templates a unit's find is
-- cloned from live in the place. A find is one MeshPart whose pivot is the middle of its bottom
-- and whose front faces its LookVector: a mimic's tell is that it faces you (GDD).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specs = require(script.Specs)

export type Name = "Boombox" | "Television" | "Teddy" | "Skates"

local Finds = {}
Finds.Specs = Specs
Finds.Names = { "Boombox", "Television", "Teddy", "Skates" } :: { Name }

-- A dull grey under the texture, shown only if the maps fail to load.
local FALLBACK = Color3.fromRGB(128, 124, 118)

-- Where the templates live: in the place, since Rojo can't sync imported meshes (D-009).
local function templates(): Instance?
	local props = ReplicatedStorage:FindFirstChild("Props")
	return if props then props:FindFirstChild("Finds") else nil
end

-- The import's last step, once per freshly imported find, from the command bar or the MCP
-- (CollisionFidelity can't be set while the game runs). A find is scenery until someone picks it
-- up: anchored, colliding as its box (the teddy and the skates as their hulls), firing no touches.
-- Its pivot stays the middle of its bottom, turned square with the part.
function Finds.prepare(part: MeshPart, name: Name)
	local spec = Specs.Finds[name]
	part.Name = name
	part.Anchored = true
	part.CanTouch = false
	part.CollisionFidelity = if spec.Hull
		then Enum.CollisionFidelity.Hull
		else Enum.CollisionFidelity.Box
	part.Color = FALLBACK
	part.PivotOffset = CFrame.new(part.PivotOffset.Position)
	part:SetAttribute("Find", name)
	part:SetAttribute("Set", spec.Set)
end

-- A copy of a find standing at `pivot` (its bottom's middle, its front facing the pivot's
-- LookVector), parented last. Nil, with a warning, if the place is missing the template.
function Finds.clone(name: Name, pivot: CFrame, parent: Instance): MeshPart?
	local folder = templates()
	local template = if folder then folder:FindFirstChild(name) else nil
	if not (template and template:IsA("MeshPart")) then
		warn(
			`Finds: no template at ReplicatedStorage.Props.Finds.{name}; import it (art/finds/README.md)`
		)
		return nil
	end
	local find = template:Clone()
	find:PivotTo(pivot)
	find.Parent = parent
	return find
end

return Finds
