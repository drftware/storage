--!strict
--[[
	Walls (S5-03h5, D-354): the partitions and the back wall where a smaller home ends. The moment:
	you buy your first unit and it's snug, the walls close round you; grow it and the room is
	plainly bigger (Animal Crossing's house rooms by size; real storage buildings make units of
	any size out of movable steel walls).

	Every lobby slot is built at XL (`Home.Sizes`), so a smaller home stands inside it behind three
	movable walls, each the unit kit's steel (a slab you can't walk or see through, `Thick` deep)
	under the home's plaster: the face is a clone of the home's own panel (`Specs.Panels`: the left
	partition, the back wall, the right partition) in a new home's look, set back by the panel's
	thickness so its face is where the lobby's wall's would be. A home's picked paint or paper
	still goes on Decorating's panels a hair proud of it, as over the lobby's walls. Each wall is
	the XL wall's whole length, so the side walls run on behind the back wall and the back wall on
	behind the partitions: the corners close at every size, and a wall only ever slides (h6).

	At XL the slot's own walls stand and the movable ones are put away. The unit's ceiling lamp
	rides with the room, over its middle (`Sizes.onWall`'s "Middle"). `size` stands them all for a
	size and says the room's width and depth to the door (`RollUpDoor.RoomWidth`, `RoomDepth`), so
	the door counts you in by the size's room.
]]

local Looks = require("./Looks")
local Sizes = require("./Sizes")
local Specs = require("./Specs")
local RollUpDoor = require("../StorageUnit/RollUpDoor")

local Walls = {}

-- The folder in a home's unit that holds them.
Walls.Folder = "Walls"
-- How thick the steel behind the plaster is: thick enough that nobody walks or looks through.
Walls.Thick = 1
-- The steel's colour, seen only at a wall's end through the doorway.
Walls.Steel = Color3.fromRGB(150, 152, 150)

-- The doorway's pieces that slide in for Small's narrower doorway (S5-03h5b, D-355): the two
-- sides of oak and the plaster strip beside each, built at the M's place; and its head, drawn
-- narrower. Each keeps where Home.dress laid it and its size there as these attributes.
Walls.Sides = table.freeze({ "CasingLeft", "CasingRight", "FillLeft", "FillRight" })
Walls.Head = "CasingHead"
Walls.WideAttribute = "Wide"
Walls.WideSizeAttribute = "WideSize"

-- A home that grew (S5-03h6, D-356): the size it grew from and the server time it grew, on the
-- unit, so everyone near sees the walls grind back and its holder sees it when they're next in.
-- Each piece of the home's that stood elsewhere before carries where (`GrewFromAttribute`).
Walls.GrewFromAttribute = "GrewFrom"
Walls.GrewAtAttribute = "GrewAt"

-- The grind's feel (S5-03h6): each number is what a player sees or hears as the walls slide out.
Walls.Grind = table.freeze({
	Seconds = 2.6, -- the slide, end to end: long enough to watch, short enough not to wait on
	Wait = 0.5, -- after you walk in to a home that grew while you were out, before it starts
	Fresh = 4, -- seconds a grow stays news to someone near who isn't its holder
	Watch = 36, -- how near (studs) someone else stands to a friend's home to see it grow
	PitchLow = 0.5, -- the steel's grind standing (the roll-up curtain's rumble, pitched down)
	PitchHigh = 0.78, -- ... and at its fastest
	Volume = 1.3, -- the grind at its fastest; it swells and dies with the slide's speed
	Lurch = 0.14, -- the camera's jolt as the walls break free (Shake trauma)
	Clunk = 0.32, -- ... and as they clunk home
	Dust = 10, -- dust puffs from each moving wall's top at the lurch, and again at the clunk
	DustRun = 4, -- puffs a second from each while it runs
})

-- Each movable wall: its name in the folder, the panel it wears, the wall it rides.
Walls.List = table.freeze({
	table.freeze({ name = "Left", part = "PanelLeft" }),
	table.freeze({ name = "Back", part = "PanelBack" }),
	table.freeze({ name = "Right", part = "PanelRight" }),
})

-- The wall `Sizes.onWall` moves panel `part` with, or "" for the floor and the front wall.
function Walls.wallOf(part: string): string
	for _, w in Walls.List do
		if w.part == part then
			return w.name
		end
	end
	return ""
end

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

-- Where panel `spec` stands in the unit (frame `frame`) at size `size`.
function Walls.panelFrame(spec: Specs.Panel, frame: CFrame, size: string): CFrame
	local side, back = Sizes.inset(size)
	return Walls.panelFrameAt(spec, frame, side, back)
end

-- `panelFrame` with the walls stood `side` and `back` in (`Sizes.between`, part way as it grows).
function Walls.panelFrameAt(spec: Specs.Panel, frame: CFrame, side: number, back: number): CFrame
	local at = Sizes.onInset(side, back, Walls.wallOf(spec.Part), spec.At)
	return frame * CFrame.new(vec(at)) * CFrame.Angles(0, math.rad(spec.Turn), 0)
end

-- The panel `spec` laid in the unit at `frame`, bare (its set and colour come with `wear`), at
-- size `size`: clicks, the screens' rays and the camera pass through it.
function Walls.panel(
	template: Model,
	spec: Specs.Panel,
	frame: CFrame,
	folder: Instance,
	size: string
): MeshPart?
	local source = template:FindFirstChild(spec.Part, true)
	if not (source and source:IsA("MeshPart")) then
		return nil
	end
	local p = source:Clone()
	for _, d in p:GetChildren() do
		d:Destroy()
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.CFrame = Walls.panelFrame(spec, frame, size)
	p.Parent = folder
	return p
end

-- Dresses `parts` in `w`: the set's swatch's SurfaceAppearance and the part's colour.
function Walls.wear(template: Model, parts: { MeshPart }, w: Looks.Wear)
	local swatch = template:FindFirstChild(Specs.Swatches[w.set] or "", true)
	local look = if swatch then swatch:FindFirstChildOfClass("SurfaceAppearance") else nil
	local colour = if w.colour ~= "" then Color3.fromHex(w.colour) else Color3.new(1, 1, 1)
	for _, p in parts do
		local old = p:FindFirstChildOfClass("SurfaceAppearance")
		if old then
			old:Destroy()
		end
		if look then
			look:Clone().Parent = p
		end
		p.Color = colour
	end
end

local function specOf(part: string): Specs.Panel?
	for _, spec in Specs.Panels.Walls do
		if spec.Part == part then
			return spec
		end
	end
	return nil
end

-- Lays the three movable walls in home `unit` (frame `frame`, the unit's `Arranged.face`) from
-- the place's Home `template`, in a new home's look, then stands them at size `size`. `width`
-- and `depth` are the XL room's across and from the door to the back wall, for the door's count.
function Walls.lay(
	template: Model,
	unit: Model,
	frame: CFrame,
	size: string,
	width: number,
	depth: number
)
	local old = unit:FindFirstChild(Walls.Folder)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = Walls.Folder
	folder:SetAttribute("Frame", frame)
	folder:SetAttribute("Width", width)
	folder:SetAttribute("Depth", depth)
	local lamp = unit:FindFirstChild("Lamp")
	if lamp and lamp:IsA("BasePart") then
		folder:SetAttribute("Lamp", lamp.CFrame) -- where it hangs at XL
	end
	local faces: { MeshPart } = {}
	for _, w in Walls.List do
		local spec = specOf(w.part)
		local model = Instance.new("Model")
		model.Name = w.name
		local face = if spec then Walls.panel(template, spec, frame, model, Sizes.Biggest) else nil
		if not (spec and face) then
			continue
		end
		face.Name = "Face"
		local p = face.Size.Z -- the panel's own thickness: its face goes where the lobby wall's is
		face.CFrame *= CFrame.new(0, 0, p)
		face.PivotOffset = CFrame.new(0, 0, -p) -- pivots where the panel would (`panelFrame`)
		local steel = Instance.new("Part")
		steel.Name = "Steel"
		steel.Anchored = true
		steel.CanTouch = false
		steel.CastShadow = false
		steel.Material = Enum.Material.DiamondPlate
		steel.Color = Walls.Steel
		steel.Size = Vector3.new(face.Size.X, face.Size.Y, Walls.Thick)
		steel.CFrame = face.CFrame * CFrame.new(0, 0, p / 2 + Walls.Thick / 2)
		steel.Parent = model
		table.insert(faces, face)
		model.PrimaryPart = face
		model:SetAttribute("Part", w.part)
		model.Parent = folder
	end
	Walls.wear(template, faces, (Looks.wear(Looks.start())))
	for _, name in { Walls.Head, table.unpack(Walls.Sides) } do
		local p = unit:FindFirstChild(name)
		if p and p:IsA("BasePart") and p:GetAttribute(Walls.WideAttribute) == nil then
			p:SetAttribute(Walls.WideAttribute, p.CFrame) -- where Home.dress laid it: the M's place
			p:SetAttribute(Walls.WideSizeAttribute, p.Size)
		end
	end
	folder.Parent = unit
	Walls.size(unit, size)
end

-- Stands home `unit`'s doorway (its unit frame `frame`) with each side `inset` studs in from the
-- M's place (`Sizes.doorIn`): the two sides and their plaster slide toward the middle, the head
-- drawn that much narrower each end, about its middle. Any inset between slides them part way.
function Walls.doorway(unit: Model, frame: CFrame, inset: number)
	for _, name in Walls.Sides do
		local p = unit:FindFirstChild(name)
		local wide = if p then p:GetAttribute(Walls.WideAttribute) else nil
		if p and p:IsA("BasePart") and typeof(wide) == "CFrame" then
			local here = frame:ToObjectSpace(wide)
			local side = if here.Position.X > 0 then 1 else -1
			p.CFrame = frame * CFrame.new(-side * inset, 0, 0) * here
		end
	end
	local head = unit:FindFirstChild(Walls.Head)
	local wide = if head then head:GetAttribute(Walls.WideSizeAttribute) else nil
	if head and head:IsA("BasePart") and typeof(wide) == "Vector3" then
		local k = 1 - inset / (wide.X / 2) -- its cornice's ends come in by `inset`
		head.Size = Vector3.new(wide.X * k, wide.Y, wide.Z)
	end
end

-- Where wall model `model` (a child of the folder) stands at size `size` in a unit at `frame`:
-- its pivot, the panel's own place (`panelFrame`).
function Walls.at(model: Model, frame: CFrame, size: string): CFrame?
	local side, back = Sizes.inset(size)
	return Walls.atInset(model, frame, side, back)
end

-- `at` with the walls stood `side` and `back` in.
function Walls.atInset(model: Model, frame: CFrame, side: number, back: number): CFrame?
	local part = model:GetAttribute("Part")
	local spec = if type(part) == "string" then specOf(part) else nil
	return if spec then Walls.panelFrameAt(spec, frame, side, back) else nil
end

-- The unit's ceiling lamp's frame at size `size`, from its XL frame `xl` in a unit at `frame`.
function Walls.lampAt(xl: CFrame, frame: CFrame, size: string): CFrame
	local _, back = Sizes.inset(size)
	return Walls.lampAtInset(xl, frame, back)
end

-- `lampAt` with the back wall stood `back` in.
function Walls.lampAtInset(xl: CFrame, frame: CFrame, back: number): CFrame
	local here = frame:ToObjectSpace(xl)
	local p = here.Position
	local at = Sizes.onInset(0, back, "Middle", { p.X, p.Y, p.Z })
	return frame * (CFrame.new(vec(at)) * here.Rotation)
end

-- The unit's frame its walls are laid in, or nil for a unit with none (not a home).
function Walls.frameOf(unit: Model): CFrame?
	local folder = unit:FindFirstChild(Walls.Folder)
	local frame = if folder then folder:GetAttribute("Frame") else nil
	return if typeof(frame) == "CFrame" then frame else nil
end

-- Stands home `unit`'s movable walls, doorway, lamp and the picked paint on its walls (Looks'
-- folder) with the walls `side` and `back` in and the doorway's sides `door` in: a size's
-- (`size`), or part way between two as the walls grind back (S5-03h6, `Sizes.between`).
function Walls.place(unit: Model, side: number, back: number, door: number)
	local folder = unit:FindFirstChild(Walls.Folder)
	local frame = Walls.frameOf(unit)
	if not (folder and frame) then
		return
	end
	for _, model in folder:GetChildren() do
		local at = if model:IsA("Model") then Walls.atInset(model, frame, side, back) else nil
		if at and model:IsA("Model") and model.PrimaryPart then
			model:PivotTo(at)
		end
	end
	Walls.doorway(unit, frame, door)
	local lamp, xlLamp = unit:FindFirstChild("Lamp"), folder:GetAttribute("Lamp")
	if lamp and lamp:IsA("BasePart") and typeof(xlLamp) == "CFrame" then
		lamp.CFrame = Walls.lampAtInset(xlLamp, frame, back)
	end
	local looks = unit:FindFirstChild(Looks.Folder)
	if looks then
		for _, p in looks:GetChildren() do
			local spec = if p:IsA("BasePart") and Walls.wallOf(p.Name) ~= ""
				then specOf(p.Name)
				else nil
			if spec and p:IsA("BasePart") then
				p.CFrame = Walls.panelFrameAt(spec, frame, side, back)
			end
		end
	end
end

-- Shows home `unit`'s movable walls (`shown`), solid steel behind them, or puts them away as XL's
-- are (the slot's own walls stand). The grind shows them sliding all the way out to XL's.
function Walls.show(unit: Model, shown: boolean)
	local folder = unit:FindFirstChild(Walls.Folder)
	if not folder then
		return
	end
	for _, model in folder:GetChildren() do
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") and (p.Name == "Face" or p.Name == "Steel") then
				p.Transparency = if shown then 0 else 1
				p.CanCollide = shown and p.Name == "Steel"
				p.CanQuery = shown and p.Name == "Steel"
			end
		end
	end
end

-- Stands home `unit`'s movable walls and its lamp for size `size` at once (no walls at XL: the
-- slot's own stand), and tells the door how wide and deep the room it counts you in is.
function Walls.size(unit: Model, size: string)
	local folder = unit:FindFirstChild(Walls.Folder)
	if not (folder and Walls.frameOf(unit)) then
		return
	end
	local side, back = Sizes.inset(size)
	Walls.place(unit, side, back, Sizes.doorIn(size))
	Walls.show(unit, Sizes.of(size).name ~= Sizes.Biggest)
	local width, depth = folder:GetAttribute("Width"), folder:GetAttribute("Depth")
	if type(width) == "number" and type(depth) == "number" then
		unit:SetAttribute(RollUpDoor.RoomWidth, width - 2 * side)
		unit:SetAttribute(RollUpDoor.RoomDepth, depth - back)
	end
end

-- The size home `unit` stands at now: its holder's (`Spots.SizeAttribute`, "HomeSize") or, for a
-- spare, the size everyone starts at.
function Walls.sizeOf(unit: Instance): string
	local size = unit:GetAttribute("HomeSize")
	return if type(size) == "string" then Sizes.of(size).name else Sizes.Start
end

return table.freeze(Walls)
