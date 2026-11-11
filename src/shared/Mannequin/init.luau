--!strict
-- The Mannequin (GDD Keepers, a Kept Thing): a shop mannequin left too long in storage. It moves
-- only while no light is on it and never trips a light (art/mannequin/README.md). Its fifteen
-- parts are R15's body parts, imported from art/mannequin/; `prepare` joins them with R15's
-- Motor6Ds, so code poses it (Pose.luau) and Roblox animations could play on it too. The
-- template lives in the place, at ReplicatedStorage.Keepers.Mannequin (D-009).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Specs = require(script.Specs)
local Pose = require(script.Pose)

local Mannequin = {}
Mannequin.Specs = Specs
Mannequin.Pose = Pose

-- Its paint, shown only if the maps fail to load.
local FALLBACK = Color3.fromRGB(222, 213, 194)

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function cframe(t: Pose.Transform): CFrame
	return CFrame.new(t[10], t[11], t[12], t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9])
end

local function part(model: Model, name: string): BasePart
	local p = model:FindFirstChild(name)
	assert(p and p:IsA("BasePart"), `the Mannequin has no {name}`)
	return p
end

function Mannequin.template(): Model?
	local keepers = ReplicatedStorage:FindFirstChild("Keepers")
	local m = keepers and keepers:FindFirstChild("Mannequin")
	return if m and m:IsA("Model") then m else nil
end

-- The import's last step, once, in Edit (CollisionFidelity can't be set while the game runs):
-- the FBX's fifteen MeshParts become an R15 figure standing on the origin, facing -Z. Every
-- part's pivot sits on the FBX's origin, but carries the FBX's Z-up turn; a part's own CFrame
-- carries the figure's axes (docs/STUDIO.md), so the frame is one's position and the other's
-- turn. A keeper is moved by its HumanoidRootPart (anchored); the body parts hang off it on
-- Motor6Ds, collide with nothing, and stay queryable for a flashlight's ray.
function Mannequin.prepare(model: Model)
	local lower = part(model, "LowerTorso")
	local frame = CFrame.new(lower:GetPivot().Position) * lower.CFrame.Rotation
	for _, d in model:GetDescendants() do
		if d:IsA("PackageLink") or d:IsA("Motor6D") or d:IsA("Attachment") then
			d:Destroy()
		end
	end
	local old = model:FindFirstChild("HumanoidRootPart")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = vec(Specs.RootPart.Size)
	root.CFrame = frame * CFrame.new(vec(Specs.RootPart.Centre))
	root.PivotOffset = CFrame.new(0, -Specs.RootPart.Centre[2], 0) -- its pivot on the floor
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Parent = model
	for name in Specs.Parts do
		local p = part(model, name) :: MeshPart
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = true
		p.Massless = true
		p.CollisionFidelity = Enum.CollisionFidelity.Box
		p.Color = FALLBACK
	end
	-- R15's joints: a RigAttachment in each part at the pivot, and the Motor6D between them,
	-- named and placed as Humanoid:BuildRigFromAttachments makes them.
	for _, j in Specs.Joints do
		local p0, p1 = part(model, j.Part0), part(model, j.Part1)
		local at = frame * CFrame.new(vec(j.At))
		local a0 = Instance.new("Attachment")
		a0.Name = j.Name .. "RigAttachment"
		a0.CFrame = p0.CFrame:ToObjectSpace(at)
		a0.Parent = p0
		local a1 = Instance.new("Attachment")
		a1.Name = j.Name .. "RigAttachment"
		a1.CFrame = p1.CFrame:ToObjectSpace(at)
		a1.Parent = p1
		local motor = Instance.new("Motor6D")
		motor.Name = j.Name
		motor.Part0 = p0
		motor.Part1 = p1
		motor.C0 = a0.CFrame
		motor.C1 = a1.CFrame
		motor.Parent = p1
	end
	model.Name = "Mannequin"
	model.PrimaryPart = root
	model:PivotTo(CFrame.new())
end

-- Stands it in a pose: each Motor6D turned from its RigAttachment, the root lifting or dropping
-- the body so its lowest sole is on the floor. In Edit, where joints don't move parts, the parts
-- are placed too, so a template or a shot shows the pose.
function Mannequin.pose(model: Model, pose: Pose.Pose)
	local turns = Pose.turns(pose)
	for _, j in Specs.Joints do
		local p0, p1 = part(model, j.Part0), part(model, j.Part1)
		local motor = p1:FindFirstChild(j.Name)
		local a0 = p0:FindFirstChild(j.Name .. "RigAttachment")
		if motor and motor:IsA("Motor6D") and a0 and a0:IsA("Attachment") then
			motor.C0 = a0.CFrame * cframe(turns[j.Name])
		end
	end
	if not RunService:IsRunning() then
		local root = part(model, "HumanoidRootPart")
		local frame = root.CFrame * CFrame.new(-vec(Specs.RootPart.Centre))
		local placed = Pose.solve(pose)
		for name, spec in Specs.Parts do
			part(model, name).CFrame = frame * cframe(placed[name]) * CFrame.new(vec(spec.Centre))
		end
	end
end

-- Every joint back at rest (each Motor6D's C0 its RigAttachment's CFrame), for a body each
-- screen poses through its joints' `Transform` (L-06b4a): the server never turns a joint, so no
-- joint replicates.
function Mannequin.rest(model: Model)
	for _, j in Specs.Joints do
		local motor = part(model, j.Part1):FindFirstChild(j.Name)
		local a0 = part(model, j.Part0):FindFirstChild(j.Name .. "RigAttachment")
		if motor and motor:IsA("Motor6D") and a0 and a0:IsA("Attachment") then
			motor.C0 = a0.CFrame
		end
	end
end

-- Its joints in `Specs.Joints`' order, as `transforms` lists their turns; nil if one is missing.
function Mannequin.motors(model: Model): { Motor6D }?
	local out: { Motor6D } = table.create(#Specs.Joints)
	for i, j in Specs.Joints do
		local p1 = model:FindFirstChild(j.Part1)
		local motor = p1 and p1:FindFirstChild(j.Name)
		if not (motor and motor:IsA("Motor6D")) then
			return nil
		end
		out[i] = motor
	end
	return out
end

-- Each joint's `Transform` for one of Pose's frames (`Pose.frame`), in `Specs.Joints`' order, over
-- a body at rest (`rest`): worked out the first time a screen shows that frame, then kept, so
-- posing a body never builds anything.
local framed: { [number]: { CFrame } } = {}
function Mannequin.transforms(frame: number): { CFrame }
	local kept = framed[frame]
	if kept then
		return kept
	end
	local turns = Pose.turns(Pose.ofFrame(frame))
	local out: { CFrame } = table.create(#Specs.Joints)
	for i, j in Specs.Joints do
		out[i] = cframe(turns[j.Name])
	end
	framed[frame] = out
	return out
end

-- Where its head sits in a pose, from its HumanoidRootPart: the head's middle, turned as the
-- head is (its blank face toward the frame's LookVector). The catch flies the body by its head.
function Mannequin.head(pose: Pose.Pose): CFrame
	local placed = Pose.solve(pose)
	return CFrame.new(-vec(Specs.RootPart.Centre))
		* cframe(placed.Head)
		* CFrame.new(vec(Specs.Parts.Head.Centre))
end

-- A copy of the template standing at `pivot` (its feet on it, facing its LookVector), posed, and
-- put in `parent`; with none, left out of the world for the caller to finish and put in last.
function Mannequin.clone(pivot: CFrame, parent: Instance?, pose: Pose.Pose?): Model?
	local template = Mannequin.template()
	if not template then
		warn("Mannequin: no template at ReplicatedStorage.Keepers.Mannequin (save the place)")
		return nil
	end
	local m = template:Clone()
	m:PivotTo(pivot)
	Mannequin.pose(m, pose or Pose.Poses.Still)
	m.Parent = parent
	return m
end

return Mannequin
