--!strict
-- The finds: what's worth taking out of a unit (art/finds/README.md). The 1980s bedroom set came
-- first: a boombox, a portable TV, a mended teddy and a pair of roller skates, all wearing one
-- texture set, each one MeshPart. The finds built with the finds kit since (F-G1a: the Lights,
-- the cars, the wind-ups) are Models of jointed parts (`Kit`, `Art`), stood as they're found by
-- `pose`. The templates a unit's find is cloned from live in the place. A find's pivot is the
-- middle of its bottom and its front faces its LookVector: a mimic's tell is that it faces you.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Art = require(script.Art)
local Order = require(script.Order)
local Pose = require(script.Pose)
local Specs = require(script.Specs)

export type Name = "Boombox" | "Television" | "Teddy" | "Skates"
-- A find's box: its size, and its middle from its pivot.
export type Box = { Size: Vector3, Centre: Vector3 }

local Finds = {}
Finds.Specs = Specs
Finds.Pose = Pose
-- The bedroom set, one MeshPart each (`prepare`).
Finds.Names = { "Boombox", "Television", "Teddy", "Skates" } :: { Name }

-- On each part of a kit-built find's model: where it was drawn, in the find's frame, and its
-- size as drawn; on its root, where the root stands now, in the find's frame (`pose`).
local DRAWN = "FindDrawn"
local DRAWN_SIZE = "FindDrawnSize"
local POSED = "FindPosed"
Finds.PosedAttribute = POSED
-- The smallest a part is drawn (a MeshPart can't be size 0): a part scaled to nothing is hidden.
local TINY = 0.001

-- Every kit-built find's data by name, from the generated sets (Finds/Sets), read once.
local kitFinds: { [string]: Art.Find }? = nil

-- A kit-built find's data (its parts, lights and motions), nil for the bedroom set.
function Finds.art(name: string): Art.Find?
	if kitFinds then
		return kitFinds[name]
	end
	do
		local made: { [string]: Art.Find } = {}
		for _, m in script.Sets:GetChildren() do
			if m:IsA("ModuleScript") then
				-- any: a generated set, required by name, typed by Art
				for n, find in (require :: any)(m) :: { [string]: Art.Find } do
					made[n] = find
				end
			end
		end
		kitFinds = made
		return made[name]
	end
end

-- Each kit-built find's motions' lengths by motion name (what `Use` sums), read once.
local lengths: { [string]: { [string]: number } } = {}

-- A kit-built find's motions' lengths by name (empty for the bedroom set).
function Finds.durations(name: string): { [string]: number }
	local made = lengths[name]
	if made then
		return made
	end
	local out: { [string]: number } = {}
	local find = Finds.art(name)
	if find then
		for motion, m in find.Motions do
			out[motion] = m.Duration
		end
	end
	lengths[name] = out
	return out
end

-- A find's box (the bedroom set's from its Specs, a kit-built one's as drawn), nil if unknown.
function Finds.box(name: string): Box?
	local spec = Specs.Finds[name]
	if spec then
		return { Size = spec.Size, Centre = Vector3.new(0, spec.Size.Y / 2, 0) }
	end
	local find = Finds.art(name)
	return if find then { Size = find.Size, Centre = find.Centre } else nil
end

-- How a kit-built find is found (`Pose.rest`): its lid shut, its flame out.
function Finds.rest(name: string): Pose.Values
	local find = Finds.art(name)
	assert(find, `Finds: {name} isn't a kit-built find`)
	return Pose.rest(find, Order[name] or {})
end

-- The part's place, size and turn for how `moved` took it from where it was drawn.
local function placed(drawn: CFrame, drawnSize: Vector3, moved: Pose.Affine): (CFrame, Vector3)
	local p = drawn.Position
	local x, y, z = Pose.apply(moved, p.X, p.Y, p.Z)
	local right = Vector3.new(moved[1], moved[4], moved[7])
	local up = Vector3.new(moved[2], moved[5], moved[8])
	local sx, sy, sz = Pose.scales(moved)
	right = right.Unit
	up = (up - right * up:Dot(right)).Unit
	local back = right:Cross(up)
	local size = Vector3.new(
		math.max(drawnSize.X * sx, TINY),
		math.max(drawnSize.Y * sy, TINY),
		math.max(drawnSize.Z * sz, TINY)
	)
	return CFrame.fromMatrix(Vector3.new(x, y, z), right, up, back), size
end

-- The glow: a lit part's mask brightens, and each light follows its own part's glow if that
-- glows, else the find's glow part's. `lights` false keeps every light off (the glow still
-- shows): a screen lights only the few nearest finds.
local function shine(
	find: Art.Find,
	parts: { [string]: BasePart },
	values: Pose.Values,
	lights: boolean
)
	local glow = find.Glow
	local function glowOf(partName: string): number?
		local v = values[partName]
		return if v then v.glow else nil
	end
	if glow then
		for partName, part in parts do
			local g = glowOf(partName)
			local look = part:FindFirstChildOfClass("SurfaceAppearance")
			if g and look then
				look.EmissiveStrength = glow.Strength * g
			end
		end
	end
	for i, spec in find.Lights do
		local part = parts[spec.Part]
		local at = if part then part:FindFirstChild(`Light{i}`) else nil
		local light = if at then at:FindFirstChildWhichIsA("Light") else nil
		if light then
			local g = glowOf(spec.Part) or (if glow then glowOf(glow.Part) else nil) or 0
			light.Brightness = spec.Brightness * g
			light.Enabled = lights and g > 0.001
		end
	end
end

--[[
	Stands `model`, a kit-built find's model (its template, or a copy wherever it is), at `values`
	(`rest`, or a motion's frame by `Pose.at`): every part moved, turned and sized as the kit's
	sums say, its joints set to hold it there, its glow and lights as lit as the values say. The
	first call on a fresh copy of the art records where each part was drawn: make it before the
	copy is moved.
]]
function Finds.pose(model: Model, name: string, values: Pose.Values)
	local find = Finds.art(name)
	assert(find, `Finds: {name} isn't a kit-built find`)
	local parts: { [string]: BasePart } = {}
	for _, spec in find.Parts do
		local part = model:FindFirstChild(spec.Name)
		assert(part and part:IsA("BasePart"), `Finds: {name}'s model has no part {spec.Name}`)
		parts[spec.Name] = part
	end
	local root = parts[find.Parts[1].Name]
	local posed = root:GetAttribute(POSED)
	local frame = if typeof(posed) == "CFrame"
		then root.CFrame * posed:Inverse()
		else root:GetPivot()
	if typeof(posed) ~= "CFrame" then
		for _, part in parts do
			part:SetAttribute(DRAWN, frame:ToObjectSpace(part.CFrame))
			part:SetAttribute(DRAWN_SIZE, part.Size)
		end
	end
	local moved = Pose.solve(find, values)
	for _, spec in find.Parts do
		local part = parts[spec.Name]
		local drawn, drawnSize = part:GetAttribute(DRAWN), part:GetAttribute(DRAWN_SIZE)
		if typeof(drawn) == "CFrame" and typeof(drawnSize) == "Vector3" then
			local at, size = placed(drawn, drawnSize, moved[spec.Name])
			part.Size = size
			part.CFrame = frame * at
			if part == root then
				root:SetAttribute(POSED, at)
			end
		end
	end
	-- each joint holds its part where it now stands, so the root carries it (C1 left plain)
	for _, part in parts do
		for _, joint in part:GetChildren() do
			if joint:IsA("Motor6D") and joint.Part1 == part and joint.Part0 then
				joint.C0 = joint.Part0.CFrame:ToObjectSpace(part.CFrame)
				joint.C1 = CFrame.identity
			end
		end
	end
	shine(find, parts, values, true)
end

-- Whether a root's values take it over the floor or lean it (the toy car's x, z, yaw, pitch, roll;
-- the tin bird's hop, y).
local function travelling(v: { [string]: number }?): boolean
	return v ~= nil
		and (
			(v.x or 0) ~= 0
			or (v.y or 0) ~= 0
			or (v.z or 0) ~= 0
			or (v.yaw or 0) ~= 0
			or (v.pitch or 0) ~= 0
			or (v.roll or 0) ~= 0
		)
end

-- Where a kit-built find's root stands for `values`, in the find's frame (its travel over the
-- floor included), from where `model`'s root was drawn; nil before `pose` has stood it.
function Finds.rootAt(model: Model, name: string, values: Pose.Values): CFrame?
	local find = Finds.art(name)
	local root = if find then model:FindFirstChild(find.Parts[1].Name) else nil
	if not (find and root) then
		return nil
	end
	local drawn, drawnSize = root:GetAttribute(DRAWN), root:GetAttribute(DRAWN_SIZE)
	if typeof(drawn) ~= "CFrame" or typeof(drawnSize) ~= "Vector3" then
		return nil
	end
	return (placed(drawn, drawnSize, Pose.solve(find, values)[find.Parts[1].Name]))
end

--[[
	Stands a kit-built find at `values` by its joints alone, never moving a part: a find in a hand
	is in the character's assembly, and setting a part's CFrame there would drag the player. Each
	part's place in the find's frame comes from where it was drawn (`pose` recorded it) and the
	kit's sums; each Motor6D then holds its part there from its Part0. The root stays where it
	stands: a find whose root travels (the toy car rolling) keeps its shape round it, its wheels
	turning, unless `from` is given. `from` is where the find's frame stood as its motion began,
	for a find lying loose only: its root is moved along the travel from there, on this screen
	alone (never in a hand: that would drag the player). `scale` is the copy's size against the
	art (your view's copy is drawn at `Hands.Scale`); `lights` false leaves its lights off. Parts
	not yet streamed in are skipped.
]]
function Finds.joints(
	model: Model,
	name: string,
	values: Pose.Values,
	scale: number,
	lights: boolean,
	from: CFrame?
)
	local find = Finds.art(name)
	if not find then
		return
	end
	local moved = Pose.solve(find, values)
	local parts: { [string]: BasePart } = {}
	local places: { [BasePart]: CFrame } = {}
	local travels = from ~= nil or travelling(values[find.Parts[1].Name])
	for i, spec in find.Parts do
		local part = model:FindFirstChild(spec.Name)
		if part and part:IsA("BasePart") then
			parts[spec.Name] = part
			local drawn, drawnSize = part:GetAttribute(DRAWN), part:GetAttribute(DRAWN_SIZE)
			local posed = part:GetAttribute(POSED)
			if
				i == 1
				and travels
				and typeof(drawn) == "CFrame"
				and typeof(drawnSize) == "Vector3"
			then
				local at = placed(drawn, drawnSize, moved[spec.Name])
				places[part] = at.Rotation + at.Position * scale
				if from then
					part.CFrame = from * places[part]
				end
			elseif i == 1 and typeof(posed) == "CFrame" then
				places[part] = posed.Rotation + posed.Position * scale
			elseif i > 1 and typeof(drawn) == "CFrame" and typeof(drawnSize) == "Vector3" then
				local at, size = placed(drawn, drawnSize, moved[spec.Name])
				places[part] = at.Rotation + at.Position * scale
				part.Size = size * scale
			end
		end
	end
	for part, at in places do
		for _, joint in part:GetChildren() do
			if joint:IsA("Motor6D") and joint.Part1 == part then
				local held = joint.Part0 and places[joint.Part0]
				if held then
					joint.C0 = held:ToObjectSpace(at)
					joint.C1 = CFrame.identity
				end
			end
		end
	end
	shine(find, parts, values, lights)
end

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
