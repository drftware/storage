--!strict
--[[
	CorridorKit: the building's hall, as pieces built in Blender (art/corridor/README.md).

	The straight piece is 24 studs of hall: the concrete floor between the two rows of doors, and
	the steel ceiling over the hall and the units either side, a corrugated deck on open-web joists.
	The fixture, then the corner, T, cross and dead end, join it next (P0-03b, P0-03c).

	Each piece's template lives in the place at ReplicatedStorage.Corridor.<Piece>, because Rojo
	can't sync imported meshes (D-009). `place` clones one into a floor: the test hall (DevCorridor)
	does now, the floor generator (L-01) will. A piece's frame is the middle of its hall floor, on
	the floor, with the hall running along its X.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specs = require(script.Specs)

export type PieceName = "Straight"
export type Piece = typeof(Specs.Pieces.Straight)

local CorridorKit = {}
CorridorKit.Specs = Specs

local function pieceSpec(name: PieceName): Piece
	-- any: a piece's name keys the generated table, which strict mode can't index by a string
	local spec = (Specs.Pieces :: any)[name]
	assert(spec, `CorridorKit: no spec for the piece {name}`)
	return spec
end

-- A piece's template, or nil while the place doesn't have it.
function CorridorKit.template(name: PieceName): Model?
	local folder = ReplicatedStorage:FindFirstChild("Corridor")
	local template = folder and folder:FindFirstChild(name)
	return if template and template:IsA("Model") then template else nil
end

-- Where a piece's hall floor is: the top middle of its Floor part, with the hall along X. Read
-- from the floor's own box, so it holds whatever turn and pivots the importer gave the parts.
function CorridorKit.frame(piece: Model): CFrame
	local floor = piece:FindFirstChild("Floor", true)
	assert(floor and floor:IsA("BasePart"), `CorridorKit: {piece:GetFullName()} has no Floor`)
	local cf, size = floor.CFrame, floor.Size
	local axes = {
		{ dir = cf.RightVector, len = size.X },
		{ dir = cf.UpVector, len = size.Y },
		{ dir = cf.LookVector, len = size.Z },
	}
	-- up is the axis nearest the world's; the hall runs along the longer of the other two
	table.sort(axes, function(a, b)
		return math.abs(a.dir.Y) > math.abs(b.dir.Y)
	end)
	local up = if axes[1].dir.Y > 0 then axes[1].dir else -axes[1].dir
	local along = if axes[2].len >= axes[3].len then axes[2].dir else axes[3].dir
	local top = cf.Position + up * (axes[1].len / 2)
	return CFrame.fromMatrix(top, (along * Vector3.new(1, 0, 1)).Unit, Vector3.yAxis)
end

-- Makes an inserted piece a template: anchored, its meshes out of physics with plain boxes from
-- the spec to stand and bump on, pivoted on its frame, streamed whole. Run once in Edit, from the
-- command bar or Studio's MCP (art/corridor/README.md, "Into Studio").
function CorridorKit.prepare(piece: Model, name: PieceName)
	local spec = pieceSpec(name)
	local frame = CorridorKit.frame(piece)
	for _, d in piece:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	-- the floor is the ground: nothing lies under it to shade
	local floor = piece:FindFirstChild("Floor", true) :: BasePart
	floor.CastShadow = false

	local old = piece:FindFirstChild("Colliders")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Colliders"
	for colliderName, c in spec.Colliders :: any do
		local p = Instance.new("Part")
		p.Name = colliderName
		p.Anchored = true
		p.CanCollide = true
		p.CanTouch = false
		p.Transparency = 1
		p.CastShadow = false
		-- footsteps and anything that reads the ground's material hear concrete and steel
		p.Material = if colliderName == "Floor" then Enum.Material.Concrete else Enum.Material.Metal
		p.Size = c.Size
		p.CFrame = frame * CFrame.new(c.Position)
		p.Parent = folder
	end
	folder.Parent = piece

	piece.WorldPivot = frame
	piece.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	piece:SetAttribute("CorridorPiece", name)
end

-- A copy of a piece with its frame at `at`, parented to `parent`.
function CorridorKit.place(name: PieceName, at: CFrame, parent: Instance): Model
	local template = CorridorKit.template(name)
	assert(
		template,
		`CorridorKit: no template at ReplicatedStorage.Corridor.{name}; import it (art/corridor/README.md)`
	)
	local piece = template:Clone()
	piece:PivotTo(at)
	piece.Parent = parent
	return piece
end

return CorridorKit
