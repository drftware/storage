--!strict
-- A packed unit's stacks (art/packed/README.md, B-05): blocks of moving boxes stacked to the
-- ceiling that make the walls of the one path through a packed unit. A block is one MeshPart whose
-- pivot is the middle of its footprint on the floor and whose front (the side meant to face the
-- path or the doorway) is its LookVector. Every block wears the boxes' own SurfaceAppearance, so a
-- unit full of them costs no texture memory the boxes don't already hold.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Floor = require(script.Parent.Floor)
local PackedLayout = require(script.Parent.PackedLayout)
local Specs = require(script.Specs)

export type Name = "ColumnA" | "ColumnB" | "ColumnC" | "WideA" | "WideB" | "Half" | "Toppled"

local Packed = {}

Packed.Specs = Specs
-- The attribute a packed unit's Model carries (true) once its stacks stand (B-05b2): a crawl
-- hole into it opens onto boxes, so nobody crawls through (Crawls).
Packed.UnitAttribute = "PackedUnit"
Packed.Names = { "ColumnA", "ColumnB", "ColumnC", "WideA", "WideB", "Half", "Toppled" } :: { Name }

-- Each block's boxes' real reach from its pivot (PackedLayout.reachOf), made once.
local REACH: { [string]: PackedLayout.Reach } = {}
for name, block in Specs.Blocks do
	local lo, hi = block.Lo, block.Hi
	REACH[name] = PackedLayout.reachOf({ X = lo.X, Z = lo.Z }, { X = hi.X, Z = hi.Z })
end
Packed.Reach = REACH

local KRAFT = Color3.fromRGB(165, 122, 78) -- the boxes' own (Boxes.prepare), under the Overlay map

local function props(): Instance?
	return ReplicatedStorage:FindFirstChild("Props")
end

local function templates(): Instance?
	local folder = props()
	return if folder then folder:FindFirstChild("Packed") else nil
end

-- The import's last step, once per freshly imported block, from the command bar or the MCP
-- (CollisionFidelity and a SurfaceAppearance's maps can't be set while the game runs). A block is
-- scenery: anchored, colliding as its box (the fallen pair as its hull, so you can step round
-- it), firing no touches. Its pivot stays the middle of its footprint, turned square with the
-- part. It takes a copy of `skin`, the boxes' SurfaceAppearance (from the Medium box's template),
-- in place of any it came with.
function Packed.prepare(part: MeshPart, name: Name, skin: SurfaceAppearance)
	part.Name = name
	part.Anchored = true
	part.CanTouch = false
	part.CollisionFidelity = if Specs.Blocks[name].Kind == "Toppled"
		then Enum.CollisionFidelity.Hull
		else Enum.CollisionFidelity.Box
	part.Color = KRAFT
	part.PivotOffset = CFrame.new(part.PivotOffset.Position)
	for _, child in part:GetChildren() do
		if child:IsA("SurfaceAppearance") then
			child:Destroy()
		end
	end
	skin:Clone().Parent = part
	part:SetAttribute("Packed", name)
end

-- How unit `number` of size `size` packs (B-05b2, D-216): its blocks, path, clearing and bend in
-- its own frame (DealSpot's), or nil if it's too small to pack. The deal lays its stacks by this
-- and the keepers' map walks its path by it, so both see the same unit.
function Packed.layout(size: Floor.Size, number: string): PackedLayout.Layout?
	local unit = Floor.Sizes[size]
	return PackedLayout.lay(
		{ width = unit.width, depth = unit.depth, doorWidth = unit.door },
		number,
		REACH,
		Specs.Pitch
	)
end

-- A copy of a block standing at `pivot` (the middle of its footprint, its front facing the
-- pivot's LookVector), parented last. Nil, with a warning, if the place is missing the template.
function Packed.clone(name: Name, pivot: CFrame, parent: Instance): MeshPart?
	local folder = templates()
	local template = if folder then folder:FindFirstChild(name) else nil
	if not (template and template:IsA("MeshPart")) then
		warn(
			`Packed: no template at ReplicatedStorage.Props.Packed.{name}; import it (art/packed/README.md)`
		)
		return nil
	end
	local block = template:Clone()
	block:PivotTo(pivot)
	block.Parent = parent
	return block
end

return Packed
