--!strict
--[[
	CorridorKit: the building's hall, as pieces built in Blender (art/corridor/README.md).

	The straight piece is 24 studs of hall: the concrete floor between the two rows of doors, and
	the steel ceiling over the hall and the units either side, a corrugated deck on open-web joists.

	The junctions are where halls meet: the corner, the T and the cross, each a 24-stud square on
	the straights' grid. A straight's deck runs along its hall; a junction's continues its arms on
	X, and a joist girder carries it across the mouth of each arm on Z, where the deck turns.
	`junction` lays one with the walls it needs, turned however the floor needs it.

	The hall's walls are a unit's front without the door, so the hall reads as one building: the
	plain wall (Wall) stands where no unit does, one M unit wide; the short wall (ShortWall), an S
	unit wide, fills what a junction leaves of a hall side; the dead end (DeadEnd) closes the hall's
	end and the deck over it. `wall` puts one up, painted like the units on its floor.

	The hall light fixture is the building's eye: a steel strip light hung on two chains from the
	deck, its lens the part HallLight lights, and a motion sensor on one end whose dome glows when
	the building is watching (HallLight.eye). `hang` puts one up; it belongs midway between two
	joists, which sit every 6 studs from 3 studs off a piece's middle.

	Each template lives in the place at ReplicatedStorage.Corridor.<Name>, because Rojo can't sync
	imported meshes (D-009). `place` clones one into a floor: the test hall (DevCorridor) does now,
	the floor generator (L-01) will. A piece's frame is the middle of its hall floor, on the floor,
	with the hall running along its X (a junction's is the middle of its square, its deck along X);
	a wall's is the middle of its hall face, on the floor,
	looking into the hall, as a unit's door face is; the fixture's is on the floor under its lens's
	middle, with its sensor towards +X.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specs = require(script.Specs)

export type PieceName = "Straight"
export type JunctionName = "Corner" | "T" | "Cross"
export type WallName = "Wall" | "ShortWall" | "DeadEnd"
export type TemplateName = PieceName | JunctionName | WallName | "Fixture"
export type Piece = typeof(Specs.Pieces.Straight)
export type Junction = typeof(Specs.Junctions.Corner)
export type Wall = typeof(Specs.Walls.Wall)
-- A hung fixture and the two parts the game lights: the lens (HallLight.light) and the sensor's
-- dome (HallLight.eye).
export type Fixture = { model: Model, diffuser: BasePart, eye: BasePart }

local CorridorKit = {}
CorridorKit.Specs = Specs

-- A piece's or a wall's colliders, from the generated spec.
local function collidersOf(name: TemplateName): { [string]: { Position: Vector3, Size: Vector3 } }
	-- any: a name keys the generated tables, which strict mode can't index by a string
	local spec = (Specs.Pieces :: any)[name]
		or (Specs.Junctions :: any)[name]
		or (Specs.Walls :: any)[name]
	assert(spec, `CorridorKit: no spec for {name}`)
	return spec.Colliders
end

-- A template, or nil while the place doesn't have it.
function CorridorKit.template(name: TemplateName): Model?
	local folder = ReplicatedStorage:FindFirstChild("Corridor")
	local template = folder and folder:FindFirstChild(name)
	return if template and template:IsA("Model") then template else nil
end

local function part(model: Model, name: string): BasePart
	local found = model:FindFirstChild(name, true)
	assert(found and found:IsA("BasePart"), `CorridorKit: {model:GetFullName()} has no {name}`)
	return found
end

-- A part's box as the hall sees it: its middle; the axis nearest the world's up and the box's
-- height along it; and the longer of the other two, flat, which the hall runs along. Read from
-- the box itself, so it holds whatever turn and pivots the importer gave the parts.
local function box(p: BasePart): (Vector3, Vector3, number, Vector3)
	local cf, size = p.CFrame, p.Size
	local axes = {
		{ dir = cf.RightVector, len = size.X },
		{ dir = cf.UpVector, len = size.Y },
		{ dir = cf.LookVector, len = size.Z },
	}
	table.sort(axes, function(a, b)
		return math.abs(a.dir.Y) > math.abs(b.dir.Y)
	end)
	local up = if axes[1].dir.Y > 0 then axes[1].dir else -axes[1].dir
	local along = if axes[2].len >= axes[3].len then axes[2].dir else axes[3].dir
	return cf.Position, up, axes[1].len, (along * Vector3.new(1, 0, 1)).Unit
end

-- Where a template's frame is. A hall piece's or a junction's is the top middle of its Floor, in
-- the Floor's own turn: the importer keeps each part's axes as the FBX has them, so the Floor's X
-- is the piece's hall (or a junction's deck) whatever turn the insert gave it. A wall's is the bottom middle of its Facade, flat on the face, looking into the hall: away
-- from the Panel, whose middle lies behind the face (the export checks it). The fixture's is on
-- the floor under its lens's middle, with its sensor's eye towards +X.
function CorridorKit.frame(model: Model): CFrame
	if model:FindFirstChild("Floor", true) then
		local floor = part(model, "Floor")
		local middle, up, height = box(floor)
		local along = (floor.CFrame.RightVector * Vector3.new(1, 0, 1)).Unit
		return CFrame.fromMatrix(middle + up * (height / 2), along, Vector3.yAxis)
	end
	if model:FindFirstChild("Facade", true) then
		local middle, up, height, along = box(part(model, "Facade"))
		local hall = along:Cross(Vector3.yAxis)
		if (middle - part(model, "Panel").Position):Dot(hall) < 0 then
			hall = -hall
		end
		local floor = middle - up * (height / 2)
		return CFrame.lookAt(floor, floor + hall)
	end
	local middle, _, _, along = box(part(model, "Diffuser"))
	if (part(model, "Eye").Position - middle):Dot(along) < 0 then
		along = -along
	end
	local floor = middle - Vector3.yAxis * Specs.Fixture.LensHeight
	return CFrame.fromMatrix(floor, along, Vector3.yAxis)
end

-- Makes an inserted model a template: anchored, its meshes out of physics, pivoted on its frame,
-- streamed whole. A hall piece or a wall gets plain boxes from the spec to stand and bump on. Run once in
-- Edit, from the command bar or Studio's MCP (art/corridor/README.md, "Into Studio").
function CorridorKit.prepare(piece: Model, name: TemplateName)
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
	piece.WorldPivot = frame
	piece.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	piece:SetAttribute("CorridorPiece", name)
	if name == "Fixture" then
		for _, d in piece:GetDescendants() do
			if d:IsA("BasePart") then
				-- overhead and out of every light's way: the tube shines down from below it, the
				-- fill casts no shadow
				d.CastShadow = false
			end
		end
		-- the lens and the dome are coloured by the game (HallLight), so nothing may cover them
		for _, partName in { "Diffuser", "Eye" } do
			for _, d in part(piece, partName):GetChildren() do
				if d:IsA("SurfaceAppearance") then
					d:Destroy()
				end
			end
		end
		return
	end

	local floor = piece:FindFirstChild("Floor", true)
	if floor and floor:IsA("BasePart") then
		-- the floor is the ground: nothing lies under it to shade
		floor.CastShadow = false
	end

	local old = piece:FindFirstChild("Colliders")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Colliders"
	for colliderName, c in collidersOf(name) do
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
end

-- A copy of a template with its frame at `at`, parented to `parent`.
function CorridorKit.place(name: TemplateName, at: CFrame, parent: Instance): Model
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

-- Lays a copy of a junction with its frame at `at` (the middle of its square, on the floor, turned
-- so its arms point down the halls it joins: Specs.Junctions.<name>.Arms, in its frame), and stands
-- the walls it needs inside it, painted `paint` like the floor's units.
function CorridorKit.junction(
	name: JunctionName,
	at: CFrame,
	paint: Color3,
	parent: Instance
): Model
	local model = CorridorKit.place(name, at, parent)
	-- any: a name keys the generated table, which strict mode can't index by a string
	local spec: Junction = (Specs.Junctions :: any)[name]
	for _, w in spec.Walls do
		local face = at * CFrame.lookAt(w.Position, w.Position + w.Look)
		CorridorKit.wall(w.Name :: WallName, face, paint, model)
	end
	return model
end

-- Puts up a copy of a wall with its frame at `at`: the middle of its hall face, on the floor,
-- looking into the hall (a unit's door face). `paint` is the floor's wall paint, as its units wear.
function CorridorKit.wall(name: WallName, at: CFrame, paint: Color3, parent: Instance): Model
	local model = CorridorKit.place(name, at, parent)
	part(model, "Facade").Color = paint
	return model
end

-- Hangs a copy of the hall light fixture with its frame at `at`: on the floor under where its
-- lens should be, midway between two joists. Light it with HallLight.light and HallLight.eye.
function CorridorKit.hang(at: CFrame, parent: Instance): Fixture
	local model = CorridorKit.place("Fixture", at, parent)
	return { model = model, diffuser = part(model, "Diffuser"), eye = part(model, "Eye") }
end

return CorridorKit
