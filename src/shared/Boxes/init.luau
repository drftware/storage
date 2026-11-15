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

-- The marked box (B-01): the one box in a unit with something in it, a Model of parts whose Open
-- motion tears the tape and springs the flaps (Specs.Marked; art/boxes/README.md).
Boxes.Marked = Specs.Marked

-- Its sounds, from Roblox's licensed library (measured in docs/STUDIO.md "The marked box's
-- sounds"): `from` and `length` in seconds of the file, played as a Sound's TimePosition window.
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }
Boxes.Sounds = {
	-- the tape snapping in the middle: a short zippy rip, all of it in its first 75 ms
	Tear = { id = "rbxassetid://9113836687", from = 0, length = 0.15, volume = 0.8, pitch = 1.1 },
	-- the flaps bursting up: a cardboard slap, its hit 0.82 s into the file
	Flaps = { id = "rbxassetid://9113579352", from = 0.8, length = 0.4, volume = 0.9 },
	-- something inside: a soft, airy pulsing hum, looped, heard only up close
	Hum = { id = "rbxassetid://9116732713", from = 0, length = 18, volume = 0.18 },
} :: { [string]: Sound }

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

-- The marked box's import step, once, from the command bar or the MCP, on a Model holding the
-- eight freshly imported `Marked_*` parts (art/boxes/README.md "Into Studio"). Only the body is
-- solid, as a box; the flaps and tape are thin and moving, so nothing touches, collides with or
-- raycasts against them. Each part's pivot goes on its hinge, turned square with the box, so a
-- motion turns it with `part:PivotTo(box:GetPivot() * CFrame.new(Pivot) * fromAxisAngle(Axis, a))`.
-- The seam's lines become the cue: Neon in its colour, hidden until something lights them.
function Boxes.prepareMarked(model: Model)
	local body = model:FindFirstChild(Specs.Marked.Parts[1].Name)
	assert(body and body:IsA("MeshPart"), "Boxes.prepareMarked: no Marked_Body in the model")
	-- the import puts the body's pivot on the box's (the middle of its bottom); square it
	body.PivotOffset = CFrame.new(body.PivotOffset.Position)
	local pivot = body:GetPivot()
	for _, spec in Specs.Marked.Parts do
		local part = model:FindFirstChild(spec.Name)
		assert(part and part:IsA("MeshPart"), `Boxes.prepareMarked: no {spec.Name} in the model`)
		local solid = part == body
		part.Anchored = true
		part.CanTouch = false
		part.CanCollide = solid
		part.CanQuery = solid
		part.CollisionFidelity = Enum.CollisionFidelity.Box
		part.PivotOffset = part.CFrame:ToObjectSpace(pivot * CFrame.new(spec.Pivot))
		if spec.Name == Specs.Marked.Cue.Part then
			local look = part:FindFirstChildOfClass("SurfaceAppearance")
			if look then
				look:Destroy() -- the lines are plain light, never textured
			end
			part.Material = Enum.Material.Neon
			part.Color = Specs.Marked.Cue.Color
			part.Transparency = 1
			part.CastShadow = false
		else
			part.Color = KRAFT
			-- the tape is too thin to throw a shadow worth its cost on a phone
			part.CastShadow = part.Size.Y > Specs.Board / 2
		end
	end
	model.Name = "Marked"
	model.PrimaryPart = body
	-- its parts stream in together, so a client never sees a box without its flaps
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Box", "Marked")
end

-- A copy of the marked box standing at `pivot` (its bottom's middle, its printed side facing the
-- pivot's LookVector), parented last. Nil, with a warning, if the place is missing the template.
function Boxes.cloneMarked(pivot: CFrame, parent: Instance): Model?
	local folder = templates()
	local template = if folder then folder:FindFirstChild("Marked") else nil
	if not (template and template:IsA("Model")) then
		warn(
			"Boxes: no template at ReplicatedStorage.Props.Boxes.Marked; import it (art/boxes/README.md)"
		)
		return nil
	end
	local box = template:Clone()
	box:PivotTo(pivot)
	box.Parent = parent
	return box
end

return Boxes
