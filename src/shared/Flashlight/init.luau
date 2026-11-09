--!strict
--[[
	The flashlight in the place (L-11a, D-047): an old plastic torch everyone carries
	(art/flashlight/README.md). Its template is two MeshParts at ReplicatedStorage.Props.Flashlight,
	imported once (Rojo can't sync imported meshes, D-009): the torch, wearing its texture set, and
	its lens, plain so the game can light it. Every point is measured from the grip, where the hand
	closes round the tube; the lens faces the torch's LookVector.

	`clone` gives a rigged torch: the two parts, the beam (a SpotLight on an attachment at the
	lens), the spill on your own (a faint PointLight), all off. `light` switches what a screen
	draws. The feel numbers are `Torch`'s.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specs = require(script.Specs)
local Torch = require(script.Torch)

local Flashlight = {}
Flashlight.Specs = Specs
Flashlight.Torch = Torch

export type Rig = {
	model: Model,
	body: MeshPart,
	lens: MeshPart,
	beam: SpotLight,
	spill: PointLight?,
}

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

-- Where the template lives: in the place, since Rojo can't sync imported meshes (D-009).
local function template(): Model?
	local props = ReplicatedStorage:FindFirstChild("Props")
	local t = if props then props:FindFirstChild("Flashlight") else nil
	return if t and t:IsA("Model") then t else nil
end

-- Scenery that never touches anything: welded in a hand or held to a camera, it must not push,
-- trip a zone, block a ray or shadow its own beam.
local function inert(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Massless = true
end

--[[
	The import's last step, once, in Edit from the command bar or the MCP: `import` is the inserted
	model (its PackageLink already removed) holding the parts `Flashlight` and `FlashlightLens`. It
	becomes the template: square to the world with the grip at the origin, each part's pivot the
	grip, the lens's SurfaceAppearance (if a later export adds one) stripped so its material shows.
]]
function Flashlight.prepare(import: Model): Model
	local body = import:FindFirstChild("Flashlight") :: MeshPart
	local lens = import:FindFirstChild("FlashlightLens") :: MeshPart
	assert(
		body and body:IsA("MeshPart") and lens and lens:IsA("MeshPart"),
		"Flashlight.prepare: not the import"
	)
	for _, part in { body, lens } :: { MeshPart } do
		inert(part)
	end
	body.CFrame = CFrame.new(Specs.Body.Centre)
	body.PivotOffset = CFrame.new(-Specs.Body.Centre)
	lens.CFrame = CFrame.new(Specs.Lens.Centre)
	lens.PivotOffset = CFrame.new(-Specs.Lens.Centre)
	local sa = lens:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		sa:Destroy()
	end
	lens.Material = Enum.Material.Glass
	lens.Color = rgb(Torch.LensOff)
	lens.Transparency = Torch.LensOffTransparency
	import.Name = "Flashlight"
	import.PrimaryPart = body
	import.WorldPivot = CFrame.identity
	return import
end

-- The light for a torch: the beam always; the spill only on your own (`own`).
local function rig(model: Model, own: boolean): Rig
	local body = model:FindFirstChild("Flashlight") :: MeshPart
	local lens = model:FindFirstChild("FlashlightLens") :: MeshPart
	local at = Instance.new("Attachment")
	at.Name = "Beam"
	-- just in front of the lens's face, so the light isn't born inside the glass
	at.CFrame = CFrame.new(Specs.LensFront - Specs.Body.Centre + Vector3.new(0, 0, -0.04))
	at.Parent = body
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Front
	beam.Angle = Torch.BeamAngle
	beam.Range = Torch.BeamRange
	beam.Brightness = Torch.BeamBrightness
	beam.Color = rgb(Torch.BeamColor)
	beam.Shadows = true
	beam.Enabled = false
	beam.Parent = at
	local spill: PointLight? = nil
	if own then
		local sat = Instance.new("Attachment")
		sat.Name = "Spill"
		local o = Torch.SpillOffset
		sat.CFrame = CFrame.new(Vector3.new(o[1], o[2], o[3]) - Specs.Body.Centre)
		sat.Parent = body
		local p = Instance.new("PointLight")
		p.Range = Torch.SpillRange
		p.Brightness = Torch.SpillBrightness
		p.Color = rgb(Torch.BeamColor)
		p.Shadows = false
		p.Enabled = false
		p.Parent = sat
		spill = p
	end
	return { model = model, body = body, lens = lens, beam = beam, spill = spill }
end

--[[
	A rigged copy of the template, its grip at `at`, parented last; `own` for your own torch (with
	the spill). Anchored: the server welds a hand's copy itself. Nil, with a warning, if the place
	is missing the template.
]]
function Flashlight.clone(at: CFrame, parent: Instance, own: boolean): Rig?
	local t = template()
	if not t then
		warn(
			"Flashlight: no template at ReplicatedStorage.Props.Flashlight; import it (art/flashlight/README.md)"
		)
		return nil
	end
	local model = t:Clone()
	model.Name = Torch.ModelName
	model:PivotTo(at)
	local r = rig(model, own)
	model.Parent = parent
	return r
end

-- The rig of a torch the server put in a character (found by name, its light made on this screen
-- the first time it's asked for). Nil if it isn't all there yet (streaming).
function Flashlight.rigOf(model: Model): Rig?
	local body = model:FindFirstChild("Flashlight")
	local lens = model:FindFirstChild("FlashlightLens")
	if not (body and body:IsA("MeshPart") and lens and lens:IsA("MeshPart")) then
		return nil
	end
	local at = body:FindFirstChild("Beam")
	local beam = if at then at:FindFirstChildOfClass("SpotLight") else nil
	if beam then
		return { model = model, body = body, lens = lens, beam = beam, spill = nil }
	end
	return rig(model, false)
end

--[[
	What a screen draws for a torch: the lens lit or dark, and its beam (`real`, within the light
	budget) on or off. Writes only what changes.
]]
function Flashlight.light(r: Rig, on: boolean, real: boolean)
	local material = if on then Enum.Material.Neon else Enum.Material.Glass
	if r.lens.Material ~= material then
		r.lens.Material = material
		r.lens.Color = rgb(if on then Torch.LensOn else Torch.LensOff)
		r.lens.Transparency = if on then 0 else Torch.LensOffTransparency
	end
	local beam = on and real
	if r.beam.Enabled ~= beam then
		r.beam.Enabled = beam
	end
	local spill = r.spill
	if spill and spill.Enabled ~= on then
		spill.Enabled = on
	end
end

return Flashlight
