--!strict
--[[
	TopHole: a saw's way down into a unit through its steel top, cut by someone lying up on the
	tops (L-13b2d, as Rainbow Six Siege's floor hatches). One spot per unit, in the middle of its
	width just behind the door's drum, across the first channel the steel rests on (D-061). `saw`
	swaps the unit's top for the same top with the hole cut through it, lays the bright cut edge
	with its tongues bent down into the unit, drops the cut-out panel (and the channel's stub still
	screwed under it) on the floor below, and opens the top's collision round the hole. Art and its
	numbers: art/tophole/README.md, Specs (generated).

		TopHole.saw(unit, at?)  -- on the server: true if it cut one; the swap replicates
		TopHole.frame(unit)     -- the hole's frame laid on a unit: hole numbers to the world
		TopHole.sawn(unit)      -- whether its top is cut already
		TopHole.prepare(kit)    -- once, in Studio's Edit, on the freshly imported kit

	The kit lives in the place at ReplicatedStorage.Props.TopHole (Rojo can't sync imported
	meshes, D-009). Its tops and panel wear the unit's own top texture, copied from
	ReplicatedStorage.Units.M by `prepare`, so a holed top is the top it replaces.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boxes = require(script.Parent.CrawlHole.Boxes)
local HoleSpecs = require(script.Specs)

local TopHole = {}

TopHole.Specs = HoleSpecs
-- Set (true) on a holed top, which also carries this tag, so a screen finds a hole as it
-- streams in.
TopHole.Attribute = "TopHole"
TopHole.Tag = "TopHole"
-- A panel a saw just cut out (a Model: the panel and its bright rim) carries this tag and the
-- server time it went through, so a screen shows it drop and clang once (a hole streaming in
-- later is old news).
TopHole.PanelTag = "TopPanel"
TopHole.CutAtAttribute = "TopCutAt"
-- The hole in its frame: across from the unit's middle, back from the first channel, and the
-- height of the ribs' top face.
TopHole.Rect = {
	left = HoleSpecs.Left,
	right = HoleSpecs.Right,
	front = HoleSpecs.Front,
	back = HoleSpecs.Back,
	top = HoleSpecs.Top,
}

local function kit(): Model?
	local props = ReplicatedStorage:FindFirstChild("Props")
	local found = props and props:FindFirstChild("TopHole")
	return if found and found:IsA("Model") then found else nil
end

local function piece(model: Instance, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

local function sizeOf(unit: Model): string
	local size = unit:GetAttribute("UnitSize")
	return if size == "S" then "S" else "M"
end

--[[
	The hole's frame laid on `unit`: its origin on the floor in the middle of the unit's width,
	under the first channel's middle; +X across, +Y up, +Z back from the hall. `Rect`'s numbers
	and the kit's Edge, Panel and PanelEdge are in this frame. Read from the unit's own top, which
	the holed one replaces at the same CFrame, so it's the same before and after the cut. Nil for a
	unit with no top.
]]
function TopHole.frame(unit: Model): CFrame?
	local top = piece(unit, "Top")
	if not top then
		return nil
	end
	local size = sizeOf(unit)
	local row = (HoleSpecs.Parts :: any)[`Top_{size}`] :: HoleSpecs.Piece
	local channel = (HoleSpecs.Channel :: any)[size] :: number
	-- the top's own frame is the unit's, its box's middle at the Specs' Centre
	return top.CFrame * CFrame.new(-row.Centre) * CFrame.new(0, 0, channel)
end

function TopHole.sawn(unit: Model): boolean
	local top = piece(unit, "Top")
	return top ~= nil and top:GetAttribute(TopHole.Attribute) == true
end

-- The top's collision box split round the hole, in the box's own frame.
local function openCollider(unit: Model, hole: CFrame)
	local folder = unit:FindFirstChild("Colliders")
	local old = folder and piece(folder, "Top")
	if not (folder and old) then
		return
	end
	-- the hole's corners in the box's frame, whichever way its axes run
	local a = old.CFrame:PointToObjectSpace(hole * Vector3.new(HoleSpecs.Left, 0, HoleSpecs.Front))
	local b = old.CFrame:PointToObjectSpace(hole * Vector3.new(HoleSpecs.Right, 0, HoleSpecs.Back))
	local size = old.Size
	local box = { along0 = -size.Z / 2, along1 = size.Z / 2, up0 = -size.X / 2, up1 = size.X / 2 }
	local cut = {
		along0 = math.min(a.Z, b.Z),
		along1 = math.max(a.Z, b.Z),
		up0 = math.min(a.X, b.X),
		up1 = math.max(a.X, b.X),
	}
	for _, p in Boxes.around(box, cut) do
		local part = old:Clone()
		part.Name = if p.name == "Front" then "Top" else "Top" .. p.name
		part.Size = Vector3.new(p.up1 - p.up0, size.Y, p.along1 - p.along0)
		part.CFrame = old.CFrame * CFrame.new((p.up0 + p.up1) / 2, 0, (p.along0 + p.along1) / 2)
		part.Parent = folder
	end
	old:Destroy()
end

--[[
	Cuts the hole in `unit`'s top. With `at` (the server time a saw went through), the fallen
	panel carries it, so screens show it drop and clang. False (and nothing changes) if the unit
	has no top, it's cut already, or the kit isn't in the place.
]]
function TopHole.saw(unit: Model, at: number?): boolean
	local template = kit()
	if not template then
		warn("TopHole: no kit at ReplicatedStorage.Props.TopHole (art/tophole/README.md)")
		return false
	end
	local top = piece(unit, "Top")
	local hole = TopHole.frame(unit)
	if not (top and hole) or TopHole.sawn(unit) then
		return false
	end
	local size = sizeOf(unit)
	local holed = piece(template, `Top_{size}`)
	local tEdge, tPanel, tRim =
		piece(template, "Edge"), piece(template, "Panel"), piece(template, "PanelEdge")
	if not (holed and tEdge and tPanel and tRim) then
		warn(`TopHole: the kit is missing Top_{size}, Edge, Panel or PanelEdge`)
		return false
	end

	-- the holed top stands where the whole one stood and behaves as it did
	local swapped = holed:Clone()
	swapped.Name = "Top"
	swapped.CFrame = top.CFrame
	swapped.CastShadow = top.CastShadow
	swapped.CanCollide = top.CanCollide
	swapped.CanQuery = top.CanQuery
	swapped.CanTouch = top.CanTouch
	swapped.CollisionGroup = top.CollisionGroup
	swapped:SetAttribute(TopHole.Attribute, true)
	swapped:AddTag(TopHole.Tag)

	-- the edge, the panel and its rim are in the hole's frame in the kit too
	local function lay(t: BasePart, as: string, parent: Instance): BasePart
		local p = t:Clone()
		p.Name = as
		p.CFrame = hole * t.CFrame
		p.Parent = parent
		return p
	end
	lay(tEdge, "TopEdge", unit)
	local fallen = Instance.new("Model")
	fallen.Name = "TopPanel"
	fallen.PrimaryPart = lay(tPanel, "Panel", fallen)
	lay(tRim, "PanelEdge", fallen)
	if at then
		fallen:SetAttribute(TopHole.CutAtAttribute, at)
		fallen:AddTag(TopHole.PanelTag)
	end
	fallen.Parent = unit

	openCollider(unit, hole)
	swapped.Parent = top.Parent
	top:Destroy()
	return true
end

--[[
	Run once in Studio's Edit on the freshly inserted kit (art/tophole/README.md, "In the place"):
	no package link or insert tag, every piece anchored and colliding with nothing (the unit's
	colliders do that), the tops and the panel wearing the unit's own top texture, and every piece
	where the kit's Specs put it. Then move the kit to ReplicatedStorage.Props.TopHole.
]]
function TopHole.prepare(model: Model)
	local link = model:FindFirstChildOfClass("PackageLink")
	if link then
		link:Destroy()
	end
	for _, tag in model:GetTags() do
		if string.sub(tag, 1, 10) == "Assistant:" then
			model:RemoveTag(tag)
		end
	end
	local units = ReplicatedStorage:FindFirstChild("Units")
	local m = units and units:FindFirstChild("M")
	local source = m and m:FindFirstChild("Top")
	local look = source and source:FindFirstChildOfClass("SurfaceAppearance")
	if not look then
		warn("TopHole.prepare: no ReplicatedStorage.Units.M.Top to take the top's look from")
	end
	-- the importer keeps the FBX's layout but turns the model as it inserts it (docs/STUDIO.md):
	-- square every piece to the kit's frame by its holed M top
	local anchor = piece(model, "Top_M")
	assert(anchor, "TopHole.prepare: the kit has no Top_M")
	local from = anchor.CFrame
	local to = CFrame.new(HoleSpecs.Parts.Top_M.Centre)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			d.CFrame = to * from:ToObjectSpace(d.CFrame)
			local row = (HoleSpecs.Parts :: any)[d.Name]
			if row and (d.Position - row.Centre).Magnitude > 0.01 then
				warn(`TopHole.prepare: {d.Name} is {d.Position}, its Specs say {row.Centre}`)
			end
			local isSheet = string.sub(d.Name, 1, 4) == "Top_" or d.Name == "Panel"
			if isSheet and look then
				local old = d:FindFirstChildOfClass("SurfaceAppearance")
				if old then
					old:Destroy()
				end
				look:Clone().Parent = d
			end
		end
	end
	model.WorldPivot = CFrame.identity
	model.Name = "TopHole"
end

return TopHole
