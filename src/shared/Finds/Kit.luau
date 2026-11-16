--!strict
-- Makes the templates of the finds built with the finds kit (art/finds/CRAFT.md, "Into Studio"),
-- from the uploaded art and the set's generated data (Finds/Sets/<Set>.luau, typed by Art). Run
-- in Studio's Edit view from the command bar or the MCP, never by the game: a glow mask and a
-- SurfaceAppearance's AlphaMode can't be written by game scripts (docs/STUDIO.md).
--
--     require(game.ReplicatedStorage.Shared.Finds.Kit).import("Lights")
--
-- A template is a Model named for the find in ReplicatedStorage.Props.Finds, as found in a unit:
-- its pivot the find's (on the floor, front to its LookVector), its root part anchored, every
-- other part held to the part it rides on by a Motor6D through its real hinge, so the game plays
-- a motion by writing each joint's Transform; its lights in place and off, its glow at 0.
-- Nothing deals these yet: a floor deals only the bedroom set (Finds/init.luau).

local InsertService = game:GetService("InsertService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Art = require(script.Parent.Art)
local Uploads = require(script.Parent.Uploads)

local Kit = {}

-- How far an imported part's pivot or size may stray from the build's numbers (studs) before
-- the import stops: more means the FBX and the generated Luau come from different builds.
local TOLERANCE = 0.005
-- A see-through part's own transparency: in AlphaMode Transparency the map's alpha cuts hard
-- unless the part is a hair transparent (docs/STUDIO.md).
local CLEAR = 0.02
-- A dull grey under the texture, shown only if the maps fail to load.
local FALLBACK = Color3.fromRGB(128, 124, 118)

local function setData(set: string): { [string]: Art.Find }
	local module = script.Parent.Sets:FindFirstChild(set)
	assert(module and module:IsA("ModuleScript"), `Kit: no generated set Finds.Sets.{set}`)
	-- any: a generated set chosen by name, typed by Art
	return (require :: any)(module)
end

-- The parts that ever glow: the find's glow part and any part a motion's glow track lights.
local function glowing(find: Art.Find): { [string]: true }
	local parts: { [string]: true } = {}
	if find.Glow then
		parts[find.Glow.Part] = true
	end
	for _, motion in find.Motions do
		for _, track in motion.Tracks do
			if track.Channel == "glow" then
				parts[track.Part] = true
			end
		end
	end
	return parts
end

-- A frame at `at` whose LookVector is `face`.
local function facing(at: Vector3, face: Vector3): CFrame
	local up = if math.abs(face.Unit.Y) > 0.99 then Vector3.zAxis else Vector3.yAxis
	return CFrame.lookAt(at, at + face, up)
end

-- Makes `model` (one find's import: its MeshParts named "<Find>_<Part>", anywhere inside it) the
-- find's template, standing at the origin. `emissive` is its glow mask's image. Parent the model
-- where it will live first: CollisionFidelity doesn't take on an unparented part. Returns a line
-- saying what it made.
function Kit.prepare(model: Model, set: string, name: string, emissive: string?): string
	local find = setData(set)[name]
	assert(find, `Kit: {set} has no find {name}`)
	for _, d in model:GetDescendants() do
		if d:IsA("PackageLink") then
			d:Destroy()
		end
	end
	for _, inst in { model :: Instance, unpack(model:GetDescendants()) } do
		for _, tag in CollectionService:GetTags(inst) do
			if string.sub(tag, 1, 10) == "Assistant:" then
				CollectionService:RemoveTag(inst, tag)
			end
		end
	end

	local parts: { [string]: MeshPart } = {}
	for _, spec in find.Parts do
		local part = model:FindFirstChild(spec.Name, true)
		assert(part and part:IsA("MeshPart"), `Kit: {name}'s import has no MeshPart {spec.Name}`)
		parts[spec.Name] = part
	end
	local root = parts[find.Parts[1].Name]
	-- The importer keeps each part's FBX frame, which is the find's (X across, Y up, front -Z),
	-- and each part's Blender origin as its pivot: the root's is the find's. A skinned part
	-- (one with bones, F-05a) has its root bone, "<Part>Root", on that origin instead.
	local function pivotOf(part: MeshPart): Vector3
		local held = part:FindFirstChild(part.Name .. "Root")
		return if held and held:IsA("Bone") then held.WorldPosition else part:GetPivot().Position
	end
	local frame = CFrame.new(pivotOf(root)) * root.CFrame.Rotation
	local wrong: { string } = {}
	local bones = find.Bones
	if bones then
		for _, bone in bones do
			local held = parts[bone.Part]:FindFirstChild(bone.Name, true)
			if not (held and held:IsA("Bone")) then
				table.insert(wrong, `{bone.Part} has no bone {bone.Name}`)
			else
				local at = frame:PointToObjectSpace(held.WorldPosition)
				if (at - bone.At).Magnitude > TOLERANCE then
					table.insert(wrong, `{bone.Name} at {at} not {bone.At}`)
				end
			end
		end
	end
	for _, spec in find.Parts do
		local part = parts[spec.Name]
		local pivot = frame:PointToObjectSpace(pivotOf(part))
		local turned = frame.Rotation:ToObjectSpace(part.CFrame.Rotation)
		if (pivot - spec.Pivot).Magnitude > TOLERANCE then
			table.insert(wrong, `{spec.Name} pivot {pivot} not {spec.Pivot}`)
		end
		if (part.Size - spec.Size).Magnitude > TOLERANCE then
			table.insert(wrong, `{spec.Name} size {part.Size} not {spec.Size}`)
		end
		if turned.LookVector:Dot(Vector3.new(0, 0, -1)) < 0.9999 then
			table.insert(wrong, `{spec.Name} is turned from the root`)
		end
	end
	assert(
		#wrong == 0,
		`Kit: {name}'s import doesn't match Finds.Sets.{set}: {table.concat(wrong, "; ")}`
	)

	-- Stand it at the origin, square, every part's pivot on its hinge.
	local lit = glowing(find)
	for _, spec in find.Parts do
		local part = parts[spec.Name]
		part.CFrame = frame:ToObjectSpace(part.CFrame)
		part.PivotOffset = part.CFrame:ToObjectSpace(CFrame.new(spec.Pivot))
		part.Parent = model
		part.Anchored = part == root
		part.Massless = part ~= root
		part.CanTouch = false
		part.CollisionFidelity = Enum.CollisionFidelity.Box
		part.Color = FALLBACK
		part.CastShadow = not spec.Clear
		part.Transparency = if spec.Clear then CLEAR else 0
		local look = part:FindFirstChildOfClass("SurfaceAppearance")
		if look then
			look.AlphaMode = if spec.Clear
				then Enum.AlphaMode.Transparency
				else Enum.AlphaMode.Overlay
			if lit[spec.Name] and emissive and find.Glow then
				look.EmissiveMaskContent = Content.fromUri(emissive)
				look.EmissiveTint = find.Glow.Tint
				look.EmissiveStrength = 0 -- off as found; the game raises it to Glow.Strength
			end
		end
		for _, old in part:GetChildren() do
			-- a Bone is an Attachment too: keep the bones a skinned part bends by (F-05a)
			if old:IsA("JointInstance") or (old:IsA("Attachment") and not old:IsA("Bone")) then
				old:Destroy()
			end
		end
	end
	for _, spec in find.Parts do
		if spec.Parent then
			local part, parent = parts[spec.Name], parts[spec.Parent]
			local hinge = CFrame.new(spec.Pivot)
			local joint = Instance.new("Motor6D")
			joint.Name = string.sub(spec.Name, #name + 2)
			joint.Part0 = parent
			joint.Part1 = part
			-- the joint's frame is the hinge with the find's axes, so a track's turn about the
			-- part's Axis is fromAxisAngle(Axis, angle) in its Transform
			joint.C0 = parent.CFrame:ToObjectSpace(hinge)
			joint.C1 = part.CFrame:ToObjectSpace(hinge)
			joint.Parent = part
		end
	end
	for i, spec in find.Lights do
		local part = parts[spec.Part]
		local at = Instance.new("Attachment")
		at.Name = `Light{i}`
		at.CFrame = part.CFrame:ToObjectSpace(facing(spec.At, spec.Face))
		local light: Light
		if spec.Kind == "Spot" then
			local spot = Instance.new("SpotLight")
			spot.Angle = spec.Angle or 90
			spot.Range = spec.Range
			light = spot
		elseif spec.Kind == "Surface" then
			local surface = Instance.new("SurfaceLight")
			surface.Angle = spec.Angle or 90
			surface.Range = spec.Range
			light = surface
		else
			local point = Instance.new("PointLight")
			point.Range = spec.Range
			light = point
		end
		light.Color = spec.Color
		light.Brightness = spec.Brightness -- fully on; the game scales it by the glow
		light.Shadows = spec.Shadows
		light.Enabled = false -- off as found
		light.Parent = at
		at.Parent = part
	end
	for _, child in model:GetChildren() do
		if not child:IsA("MeshPart") then
			child:Destroy()
		end
	end
	model.Name = name
	model.PrimaryPart = root
	model:SetAttribute("Find", name)
	model:SetAttribute("Set", set)
	return `{name}: {#find.Parts} parts, {if bones then #bones else 0} bones, {#find.Lights} lights{if emissive
		then ", glow mask"
		else ""}`
end

-- Brings every find of `set` (or only those named) from its uploaded Model asset
-- (Finds/Uploads.luau, written by scripts/upload_art.luau) into ReplicatedStorage.Props.Finds,
-- replacing the template there. A glow mask uploads as a Decal; its image is what the mask takes.
function Kit.import(set: string, only: { string }?): { string }
	local uploads = (Uploads :: any)[set] -- any: generated, keyed by set and find
	assert(uploads, `Kit: nothing of {set} is uploaded (lune run scripts/upload_art)`)
	local props = ReplicatedStorage:FindFirstChild("Props")
	assert(props, "Kit: ReplicatedStorage has no Props")
	local folder = props:FindFirstChild("Finds")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Finds"
		folder.Parent = props
	end
	local names: { string } = only or {}
	if not only then
		for name in uploads do
			table.insert(names, name)
		end
		table.sort(names)
	end
	local made: { string } = {}
	for _, name in names do
		local ids = uploads[name]
		local loaded = InsertService:LoadAsset(ids.Model)
		local model = loaded:FindFirstChild(name, true)
		assert(model and model:IsA("Model"), `Kit: asset {ids.Model} holds no Model {name}`)
		local emissive: string? = nil
		if ids.Emissive then
			local decal = InsertService:LoadAsset(ids.Emissive)
				:FindFirstChildWhichIsA("Decal", true)
			assert(decal, `Kit: asset {ids.Emissive} holds no Decal`)
			emissive = decal.Texture
		end
		local old = (folder :: Instance):FindFirstChild(name)
		if old then
			old:Destroy()
		end
		model.Parent = folder
		loaded:Destroy()
		table.insert(made, Kit.prepare(model, set, name, emissive))
	end
	return made
end

return Kit
