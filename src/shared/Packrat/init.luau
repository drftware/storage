--!strict
-- The Packrat (GDD "The Packrat collects things, not people"): a tall, faceless bundle of grey
-- moving blankets bound in packing tape, two long pale arms out of it, carrying the floor's finds
-- home one at a time (art/packrat/README.md). Its fifteen parts are R15's body parts, imported
-- from art/packrat/; `prepare` joins them with R15's Motor6Ds, as the Mannequin's does, so code
-- poses it (Pose.luau, on the shared Rig.luau). The template lives in the place, at
-- ReplicatedStorage.Keepers.Packrat (D-009).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Rig = require(script.Parent.Rig)
local Specs = require(script.Specs)
local Pose = require(script.Pose)

local Packrat = {}
Packrat.Specs = Specs
Packrat.Pose = Pose

-- Its paint by what a part is made of, shown only if the maps fail to load: the bundle's
-- middling grey and the arms' pale skin, so even then the arms are the only pale thing on it.
local FALLBACK: { [string]: Color3 } = {
	blanket = Color3.fromRGB(94, 97, 100),
	skin = Color3.fromRGB(206, 196, 184),
}

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function cframe(t: Rig.Transform): CFrame
	return CFrame.new(t[10], t[11], t[12], t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8], t[9])
end

local function part(model: Model, name: string): BasePart
	local p = model:FindFirstChild(name)
	assert(p and p:IsA("BasePart"), `the Packrat has no {name}`)
	return p
end

-- Where a carried find's middle sits, in the UpperTorso's own frame: the chest carries it, so
-- it rides every turn of the waist and root a screen gives the body.
local CHEST = CFrame.new(vec(Specs.Carry) - vec(Specs.Parts.UpperTorso.Centre))
Packrat.Chest = CHEST

-- Where a find held in its hands sits in each pose that holds one there (S2-06b2b,
-- `Pose.InHands`): reaching, at the right hand's fingertips; taking and putting down, between
-- both palms. `Grip` is its middle in the UpperTorso's own frame, as `Chest` is (a carried find's
-- weld `C0` on screens, KeeperView); `Held` is from the floor between its feet, facing as it does
-- (where the server sets a find down from).
-- The attribute on a carried find's weld saying where it lay as the hands closed, a CFrame in
-- the world (the server's Keepers sets it): a screen holds the find there until it shows the
-- hands close on it.
Packrat.FromAttribute = "From"
-- Seconds a screen takes to ease a find it holds (KeeperView): up from where it lay into its
-- closing hands, quick, a snatch; from its hands to its chest as it turns for home; from its
-- chest down into its hands as it crouches over its pile, unhurried.
Packrat.Ease = { Take = 0.22, Chest = 0.3, PutDown = 0.4 } :: { [string]: number }
Packrat.Grip = {} :: { [string]: CFrame }
Packrat.Held = {} :: { [string]: CFrame }
for name, hands in Pose.InHands do
	local pose = Pose.Poses[name]
	local chest = cframe(Pose.solve(pose).UpperTorso)
		* CFrame.new(vec(Specs.Parts.UpperTorso.Centre))
	local held = cframe(Pose.grip(pose, hands))
	Packrat.Grip[name] = CFrame.new(chest:PointToObjectSpace(held.Position))
	Packrat.Held[name] = held
end

function Packrat.template(): Model?
	local keepers = ReplicatedStorage:FindFirstChild("Keepers")
	local m = keepers and keepers:FindFirstChild("Packrat")
	return if m and m:IsA("Model") then m else nil
end

-- The import's last step, once, in Edit (CollisionFidelity can't be set while the game runs):
-- the FBX's fifteen MeshParts become an R15 figure standing on the origin, facing -Z. Every
-- part's pivot sits on the FBX's origin; a part's own CFrame carries the figure's axes
-- (docs/STUDIO.md), so the frame is one's pivot position and the other's turn. It's moved by
-- its HumanoidRootPart (anchored); the body parts hang off it on Motor6Ds, collide with nothing,
-- and stay queryable for a flashlight's ray.
function Packrat.prepare(model: Model)
	local lower = part(model, "LowerTorso")
	local frame = CFrame.new(lower:GetPivot().Position) * lower.CFrame.Rotation
	for _, d in model:GetDescendants() do
		if d:IsA("PackageLink") or d:IsA("Motor6D") or d:IsA("Attachment") then
			d:Destroy()
		end
	end
	for _, tag in CollectionService:GetTags(model) do
		if string.sub(tag, 1, 10) == "Assistant:" then
			CollectionService:RemoveTag(model, tag)
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
	for name, spec in Specs.Parts do
		local p = part(model, name) :: MeshPart
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = true
		p.Massless = true
		p.CollisionFidelity = Enum.CollisionFidelity.Box
		p.Color = FALLBACK[spec.Stuff] or FALLBACK.blanket
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
	model.Name = "Packrat"
	model.PrimaryPart = root
	model:PivotTo(CFrame.new())
end

-- Stands it in a pose: each Motor6D turned from its RigAttachment, the root lifting or dropping
-- the body so its lowest sole is on the floor. In Edit, where joints don't move parts, the parts
-- are placed too, so a template or a shot shows the pose.
function Packrat.pose(model: Model, pose: Rig.Pose)
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
-- screen poses through its joints' `Transform`: the server never turns a joint, so no joint
-- replicates.
function Packrat.rest(model: Model)
	for _, j in Specs.Joints do
		local motor = part(model, j.Part1):FindFirstChild(j.Name)
		local a0 = part(model, j.Part0):FindFirstChild(j.Name .. "RigAttachment")
		if motor and motor:IsA("Motor6D") and a0 and a0:IsA("Attachment") then
			motor.C0 = a0.CFrame
		end
	end
end

-- Its joints in `Specs.Joints`' order, as `transforms` lists their turns; nil if one is missing.
function Packrat.motors(model: Model): { Motor6D }?
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

-- Each joint's `Transform` for one of Pose's frames (`Pose.frame`, or `Pose.held` for a pose it
-- holds still in), in `Specs.Joints`' order, over a body at rest (`rest`): worked out the first
-- time a screen shows that frame, then kept, so posing a body never builds anything (the
-- KeeperView `Kit` shape, as the Mannequin's).
local posed: { { CFrame } } = table.create(Pose.Frames)
function Packrat.transforms(frame: number): { CFrame }
	local kept = posed[frame]
	if kept then
		return kept
	end
	assert(
		frame >= 1 and frame <= Pose.Frames and frame // 1 == frame,
		`the Packrat has no frame {frame}`
	)
	local turns = Pose.turns(Pose.ofFrame(frame))
	local out: { CFrame } = table.create(#Specs.Joints)
	for i, j in Specs.Joints do
		out[i] = cframe(turns[j.Name])
	end
	posed[frame] = out
	return out
end

-- Where a carried find's middle sits now, in the world: on its chest, turned as the chest is.
-- Read from the UpperTorso's CFrame, so it follows the pose wherever the body is posed (in Edit
-- by `pose`, on a screen by its joints' Transforms; on the server, at rest).
function Packrat.carry(model: Model): CFrame
	return part(model, "UpperTorso").CFrame * CHEST
end

-- A copy of the template standing at `pivot` (its feet on it, facing its LookVector), posed, and
-- put in `parent`; with none, left out of the world for the caller to finish and put in last.
function Packrat.clone(pivot: CFrame, parent: Instance?, pose: Rig.Pose?): Model?
	local template = Packrat.template()
	if not template then
		warn("Packrat: no template at ReplicatedStorage.Keepers.Packrat")
		return nil
	end
	local m = template:Clone()
	m:PivotTo(pivot)
	Packrat.pose(m, pose or Pose.Poses.Still)
	m.Parent = parent
	return m
end

return Packrat
