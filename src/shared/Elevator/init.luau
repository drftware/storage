--!strict
-- The freight elevator (GDD: Codes, the elevator and the roof): the way up. The car stands
-- behind the lobby's back wall, lit by its caged lamp, with its folding gate, the landing's frame
-- and the keypad by the opening; the floor's code hides on sticky notes in the units. Imported
-- from art/elevator/ (its README); `prepare` readies the import once, in Edit, and the templates
-- live in the place at ReplicatedStorage.Props.Elevator and ReplicatedStorage.Props.Note (D-009).
-- The gate is one picket, the lead and one strap, cloned and posed by code (`Gate.luau`).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Specs = require(script.Specs)
local Gate = require(script.Gate)

local Elevator = {}
Elevator.Specs = Specs
Elevator.Gate = Gate

-- The car's lamp, the one light on a floor that's always on: the warm glow you arrive in and run
-- back to. It throws shadows, so it reaches the lobby only through the opening, the gate's lattice
-- printed on the floor; its spill reaches about halfway across the lobby, so the hall's mouth
-- stays dark.
Elevator.Lamp = {
	Colour = Color3.fromRGB(255, 206, 150),
	Brightness = 1.2,
	Range = 22,
}
-- The keypad's status light, the red pin-prick you see from the hall's mouth (the hall light's
-- eye showed this red stays a clean dot on a phone), and its readout's dark glass at rest.
Elevator.KeypadLight = Color3.fromRGB(255, 40, 24)
Elevator.Readout = Color3.fromRGB(46, 8, 8)
-- The keypad's own red glow. It hangs on the lobby's side of the wall, where the car's lamp
-- (behind the wall) never reaches once its shadows settle, and no hall light reaches that far, so
-- without this it goes black. Enough to read the keys up close and to show across the lobby as a
-- red glow; `Out` is how far in front of the panel it sits (studs), so it lights the keys' faces.
-- Kept tight: at 2.5 studs it threw a hard red disc across the wall, a spotlight, not a glow.
Elevator.KeypadGlow = {
	Colour = Color3.fromRGB(255, 70, 50),
	Brightness = 1,
	Range = 1.6,
	Out = 0.4,
}
-- The note's digits: how sharp (pixels a stud: 0.62 studs of writing is 250 pixels across) and
-- how far off they still draw (a note is read up close; past this it's a yellow square).
Elevator.NotePixels = 400
Elevator.NoteReach = 40

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function part(parent: Instance, name: string): BasePart
	local p = parent:FindFirstChild(name)
	assert(p and p:IsA("BasePart"), `the elevator has no {name}`)
	return p
end

local function props(): Instance?
	return ReplicatedStorage:FindFirstChild("Props")
end

function Elevator.template(): Model?
	local folder = props()
	local m = folder and folder:FindFirstChild("Elevator")
	return if m and m:IsA("Model") then m else nil
end

function Elevator.noteTemplate(): Model?
	local folder = props()
	local m = folder and folder:FindFirstChild("Note")
	return if m and m:IsA("Model") then m else nil
end

-- The gate's parts in pose order: the 12 pickets, the lead, then the 72 straps as `Gate.pose`
-- lists them (bay by bay, row by row, the rising strap then the falling one).
local function pickets(): number
	return Specs.Gate.Pickets
end
local function straps(): number
	return (Specs.Gate.Pickets - 1) * #Specs.Gate.Rows * 2
end
local function gatePartName(i: number): string
	local n = pickets()
	if i < n then
		return `Picket{i}`
	elseif i == n then
		return "Lead"
	end
	return `Strap{i - n}`
end

-- The keypad's glow (`KeypadGlow`): a light just in front of the panel, in the Keypad part, with
-- `frame` the elevator's. Part of `prepare`; replaces any glow already there.
function Elevator.glowKeypad(model: Model, frame: CFrame)
	local keypad = part(model, "Keypad")
	local old = keypad:FindFirstChild("Glow")
	if old then
		old:Destroy()
	end
	local g = Elevator.KeypadGlow
	local at = Instance.new("Attachment")
	at.Name = "Glow"
	at.CFrame = keypad.CFrame:ToObjectSpace(
		frame * CFrame.new(vec(Specs.Keypad.Centre) + Vector3.new(0, 0, -g.Out))
	)
	local light = Instance.new("PointLight")
	light.Color = g.Colour
	light.Brightness = g.Brightness
	light.Range = g.Range
	light.Shadows = false -- too small to need them; it barely reaches the car's corner post
	light.Parent = at
	at.Parent = keypad
end

-- The import's last step, once, in Edit (CollisionFidelity can't be set while the game runs).
-- Every part's pivot sits on the FBX's origin, the threshold's middle, but carries the FBX's Z-up
-- turn; a part's own CFrame carries the elevator's axes (docs/STUDIO.md), so the frame is one's
-- position and the other's turn. The meshes collide with nothing; invisible boxes from
-- `Specs.Colliders` do. Returns the note, taken out of the elevator to be its own template, at
-- the origin and unparented.
function Elevator.prepare(model: Model): Model
	local car = part(model, "Car")
	local frame = CFrame.new(car:GetPivot().Position) * car.CFrame.Rotation
	for _, d in model:GetDescendants() do
		if d:IsA("PackageLink") then
			d:Destroy()
		end
	end
	for _, tag in model:GetTags() do
		if tag:sub(1, 10) == "Assistant:" then
			model:RemoveTag(tag) -- the MCP's insert marks what it adds
		end
	end
	model.WorldPivot = frame
	for name, spec in Specs.Parts do
		local p = part(model, name) :: MeshPart
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CollisionFidelity = Enum.CollisionFidelity.Box
		p.PivotOffset = CFrame.new(-vec(spec.Centre)) -- its pivot on its origin, square to the car
		p.CFrame = frame * CFrame.new(vec(spec.Centre))
	end

	-- the lamp: its glass glows and holds the light; neither it nor the wire guard shadows it
	local glass = part(model, "LampGlass")
	glass.Material = Enum.Material.Neon
	glass.Color = Elevator.Lamp.Colour
	glass.CastShadow = false
	part(model, "Lamp").CastShadow = false
	local at = Instance.new("Attachment")
	at.Name = "LampLight"
	at.CFrame = glass.CFrame:ToObjectSpace(frame * CFrame.new(vec(Specs.Lamp)))
	local light = Instance.new("PointLight")
	light.Color = Elevator.Lamp.Colour
	light.Brightness = Elevator.Lamp.Brightness
	light.Range = Elevator.Lamp.Range
	light.Shadows = true
	light.Parent = at
	at.Parent = glass

	-- the keypad: its readout's dark glass and its red light; its small parts throw no shadow
	local readout = part(model, "KeypadReadout")
	readout.Material = Enum.Material.Glass
	readout.Color = Elevator.Readout
	local red = part(model, "KeypadLight")
	red.Material = Enum.Material.Neon
	red.Color = Elevator.KeypadLight
	for _, name in { "Keypad", "KeypadReadout", "KeypadLight" } do
		part(model, name).CastShadow = false
	end
	for d = 0, 9 do
		part(model, `Key{d}`).CastShadow = false
	end
	Elevator.glowKeypad(model, frame)

	-- the gate: one picket, the lead and one strap become 85 parts sharing their meshes (one draw)
	local gate = Instance.new("Folder")
	gate.Name = "Gate"
	local picket, lead, strap =
		part(model, "GatePicket"), part(model, "GateLead"), part(model, "GateStrap")
	for i = 1, pickets() + straps() do
		local source = if i < pickets() then picket elseif i == pickets() then lead else strap
		local p = source:Clone()
		p.Name = gatePartName(i)
		p.Parent = gate
	end
	picket:Destroy()
	lead:Destroy()
	strap:Destroy()
	gate.Parent = model

	local folder = Instance.new("Folder")
	folder.Name = "Colliders"
	for _, c in Specs.Colliders do
		local p = Instance.new("Part")
		p.Name = c.Name
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		-- footsteps aboard hear the car's steel plate
		p.Material = if c.Name == "CarFloor"
			then Enum.Material.DiamondPlate
			else Enum.Material.Metal
		p.Size = vec(c.Size)
		p.CFrame = frame * CFrame.new(vec(c.Centre))
		p.Parent = folder
	end
	folder.Parent = model

	-- the note leaves to be its own template: the paper and an invisible card its digits are
	-- written on, flat over the paper's writing area
	local note = Instance.new("Model")
	note.Name = "Note"
	local paper = part(model, "Note")
	paper.Name = "Paper"
	paper.CastShadow = false
	paper.Parent = note
	local w = Specs.Note.Write
	local card = Instance.new("Part")
	card.Name = "Writing"
	card.Size = Vector3.new(w.Size[1], w.Size[2], 0.002)
	-- its front face (the note's LookVector) 0.003 off the paper, clear of it at any distance
	card.CFrame = frame * CFrame.new(vec(w.Centre) + Vector3.new(0, 0, -0.002))
	card.Transparency = 1
	card.Anchored = true
	card.CanCollide = false
	card.CanTouch = false
	card.CanQuery = false
	card.CastShadow = false
	card.Massless = true
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Digits"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = Elevator.NotePixels
	gui.LightInfluence = 1 -- ink, not light: as dark as the paper's shadow
	gui.MaxDistance = Elevator.NoteReach
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = Font.new(Specs.Note.Font, Enum.FontWeight.Bold)
	label.TextColor3 = Color3.fromRGB(Specs.Note.Ink[1], Specs.Note.Ink[2], Specs.Note.Ink[3])
	label.TextScaled = true
	label.Text = ""
	-- the look sheets' hand: the digits fill 92% of the area's width. Kalam's line is tall for its
	-- digits, so the area's whole height is left to the line or the width never sets the size.
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.Parent = label
	label.Parent = gui
	gui.Parent = card
	card.Parent = note
	note.WorldPivot = frame -- the paper's back, where it sticks
	note:PivotTo(CFrame.new())

	-- the whole car streams in or out at once, never half a gate
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Name = "Elevator"
	Elevator.setGate(model, 0)
	model:PivotTo(CFrame.new())
	return note
end

-- Poses the gate `shut` of the way closed (0 folded open against the left post, 1 shut at the
-- keypad's post), every picket and strap where Gate.pose puts it, in one move.
-- Allocates the pose's tables: fine for a gate shutting once a floor (L-05b may cache them).
function Elevator.setGate(model: Model, shut: number)
	local folder = model:FindFirstChild("Gate")
	if not folder then
		return
	end
	local frame = model:GetPivot()
	local pose = Gate.pose(shut)
	local G = Specs.Gate
	local moved: { BasePart } = table.create(pickets() + straps())
	local to: { CFrame } = table.create(pickets() + straps())
	for i = 1, pickets() + straps() do
		local p = part(folder, gatePartName(i))
		local pivot
		if i <= pickets() then
			pivot = frame * CFrame.new(pose.Pickets[i], 0, G.Plane)
		else
			local s = pose.Straps[i - pickets()]
			pivot = frame * CFrame.new(s.X, s.Y, s.Z) * CFrame.Angles(0, 0, s.Angle)
		end
		table.insert(moved, p)
		table.insert(to, pivot * p.PivotOffset:Inverse())
	end
	Workspace:BulkMoveTo(moved, to, Enum.BulkMoveMode.FireCFrameChanged)
end

-- A copy of the template with its threshold's middle at `pivot`, the lobby toward its
-- LookVector, the gate folded open. Nil, after a warning, if the place has no template.
function Elevator.clone(pivot: CFrame, parent: Instance): Model?
	local template = Elevator.template()
	if not template then
		warn("Elevator: no template at ReplicatedStorage.Props.Elevator (art/elevator/README.md)")
		return nil
	end
	local m = template:Clone()
	m:PivotTo(pivot)
	m.Parent = parent
	return m
end

-- Writes `text` (a note's digits in their slots, like "_ 7 _ _") on a note.
function Elevator.write(note: Model, text: string)
	local card = note:FindFirstChild("Writing")
	local gui = card and card:FindFirstChild("Digits")
	local label = gui and gui:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

-- A note stuck at `pivot` (its back on the surface, its face toward the LookVector) with `text`
-- written on it. Nil, after a warning, if the place has no template.
function Elevator.note(pivot: CFrame, parent: Instance, text: string): Model?
	local template = Elevator.noteTemplate()
	if not template then
		warn("Elevator: no note at ReplicatedStorage.Props.Note (art/elevator/README.md)")
		return nil
	end
	local n = template:Clone()
	n:PivotTo(pivot)
	Elevator.write(n, text)
	n.Parent = parent
	return n
end

return Elevator
