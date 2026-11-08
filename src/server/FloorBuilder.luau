--!strict
--[[
	FloorBuilder: lays one floor of the building from its data (L-01c). `Floor.generate` says where
	every hall, unit, wall and light goes; this puts the real pieces there, so a seed becomes a
	floor you can walk: CorridorKit's straights, junctions, walls and dead ends; the M and S units
	from ReplicatedStorage.Units, in the floor's door colour and numbered; and a motion light over
	every hall piece, in its power zone. A plain wall in a top run gets a lid over the empty slot
	behind it, the unit's own wire top and floor, so a friend running the tops never drops in. The
	lobby is a plain room with the elevator's space behind it, lit from there, until L-05 builds
	both.

	Laying yields. It works out from the lobby a hall piece at a time and waits a frame whenever it
	has spent its share of one, so the server never hitches: L-08 lays the next floor while the
	elevator rides. Each hall piece and everything on it is dressed before it is parented, once:
	clients cache a door's frame and colours when its unit arrives.

	`unit` puts one unit at a door face; the test hall (DevCorridor) uses it too. Its door's buttons
	come from the Doors system once it's in the world.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CorridorKit = require(ReplicatedStorage.Shared.CorridorKit)
local Floor = require(ReplicatedStorage.Shared.Floor)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

-- How long laying may take of each server frame (60 a second, about 16.7 ms each) before it waits
-- for the next: low enough that a laying floor never stutters the floor being played.
local FRAME_BUDGET = 0.004

-- The lobby stand-in, in studs and colours (L-05 builds the real one).
local LOBBY_HEIGHT = 14 -- up to the kit's deck, so the lobby's ceiling meets the hall's
local LOBBY_WALL = 0.5
local CONCRETE = Color3.fromRGB(120, 120, 118) -- the hall floor's grey
local CEILING_COLOUR = Color3.fromRGB(38, 38, 40)
local PLATE_COLOUR = Color3.fromRGB(88, 90, 94) -- the elevator car's steel floor
-- The car's lamp, the one light on the floor that's always on: the warm glow you arrive in and
-- run back to. Its spill reaches about halfway into the lobby, so the hall's mouth stays dark.
local LAMP_COLOUR = Color3.fromRGB(255, 206, 150)
local LAMP_BRIGHTNESS = 1.2
local LAMP_RANGE = 22

local FloorBuilder = {}

-- The unit templates a floor's slots are filled from.
export type Units = { M: Model, S: Model }

-- What laying a floor took, for Output: from start to finish, how much of that was work rather than
-- waiting for the next frame, and the most work done in one frame.
export type Laid = {
	units: number,
	pieces: number,
	frames: number,
	seconds: number,
	working: number,
	longest: number,
}

-- The kit's junction a hall piece is laid as, or nil for a straight or the lobby.
local function junctionOf(kind: Floor.Kind): CorridorKit.JunctionName?
	if kind == "Corner" then
		return "Corner"
	elseif kind == "T" then
		return "T"
	elseif kind == "Cross" then
		return "Cross"
	end
	return nil
end

-- The unit templates, once every piece a floor needs is in the place; otherwise nil and the path
-- of the first one missing.
function FloorBuilder.units(): (Units?, string?)
	local folder = ReplicatedStorage:FindFirstChild("Units")
	local m = folder and folder:FindFirstChild("M")
	local s = folder and folder:FindFirstChild("S")
	if not (m and m:IsA("Model")) then
		return nil, "ReplicatedStorage.Units.M"
	end
	if not (s and s:IsA("Model")) then
		return nil, "ReplicatedStorage.Units.S"
	end
	local kit = CorridorKit.missing()
	if kit then
		return nil, `ReplicatedStorage.Corridor.{kit}`
	end
	return { M = m, S = s }, nil
end

-- The name a floor's light zone goes by in MotionLights, so two floors laid at once (one being
-- played, the next during the ride) never share a breaker.
function FloorBuilder.powerZone(floorNumber: number, zone: string): string
	return `Floor{floorNumber}.{zone}`
end

local function specOf(unit: Model): Specs.Spec
	local size = unit:GetAttribute("UnitSize")
	return Specs[if type(size) == "string" then size else "M"]
end

-- A clone of `template` with its door's outer face at `face` (looking into the hall), painted and
-- numbered, ready to parent (the Doors system gives it its buttons once it's in the world). Units are dressed before they reach Workspace:
-- clients cache the door's frame and colours when a unit arrives.
function FloorBuilder.unit(template: Model, face: CFrame, number: string, colour: Color3): Model
	local unit = template:Clone()
	local outer = RollUpDoor.frame(unit) * CFrame.new(0, 0, -specOf(unit).CurtainPlane)
	unit:PivotTo(face * outer:ToObjectSpace(unit:GetPivot()))
	unit.Name = `Unit{number}`
	UnitKit.paint(unit, colour, UnitKit.Colours.Wall)
	UnitKit.number(unit, number)
	RollUpDoor.fitCollider(unit)
	return unit
end

-- A frame on the floor at (x, z) with its X along Dir `turn`, as Floor lays its pieces.
local function frameOf(x: number, z: number, turn: number): CFrame
	local dx, dz = Floor.dir(turn)
	return CFrame.fromMatrix(Vector3.new(x, 0, z), Vector3.new(dx, 0, dz), Vector3.yAxis)
end

-- A face on the floor at (x, z) looking along Dir `facing`: a door's, a wall's, a dead end's.
local function faceOf(x: number, z: number, facing: number): CFrame
	local dx, dz = Floor.dir(facing)
	local at = Vector3.new(x, 0, z)
	return CFrame.lookAt(at, at + Vector3.new(dx, 0, dz))
end

-- The parts a plain wall's lid is made of: the unit's wire top to run across and its floor, so
-- the empty slot under the wires reads as an empty unit, not the void below the building.
local LID_PARTS = { "WireTop", "Floor" }
local LID_SIZES: { Floor.Size } = { "M", "S" }

--[[
	A plain wall's lid, made once per size from the unit template's own parts and their colliders,
	in a door face's frame (a plain wall's frame is a unit's door face): pivot it to the wall's face.
	Nil and the missing part's name if the template lacks one.
]]
local function lidOf(template: Model): (Model?, string?)
	local outer = RollUpDoor.frame(template) * CFrame.new(0, 0, -specOf(template).CurtainPlane)
	local lid = Instance.new("Model")
	lid.Name = "Lid"
	local colliders = Instance.new("Folder")
	colliders.Name = "Colliders"
	colliders.Parent = lid
	local templateColliders = template:FindFirstChild("Colliders")
	for _, name in LID_PARTS do
		local part = template:FindFirstChild(name, true)
		local box = templateColliders and templateColliders:FindFirstChild(name)
		if not (part and part:IsA("BasePart") and box and box:IsA("BasePart")) then
			lid:Destroy()
			return nil, name
		end
		for _, p in { part, box } :: { BasePart } do
			local copy = p:Clone()
			copy.CFrame = outer:ToObjectSpace(p.CFrame)
			copy.Parent = if p == box then colliders else lid
		end
	end
	lid.WorldPivot = CFrame.identity
	return lid, nil
end

-- Leaves out the side walls a neighbour already stands. `drops` are floor Dirs; the unit's WallLeft
-- or WallRight is whichever stands toward one.
local function dropWalls(unit: Model, drops: { number }, origin: CFrame)
	if #drops == 0 then
		return
	end
	local left = unit:FindFirstChild("WallLeft")
	local right = unit:FindFirstChild("WallRight")
	if not (left and right and left:IsA("BasePart") and right:IsA("BasePart")) then
		return
	end
	local leftward = left.Position - right.Position
	for _, d in drops do
		local dx, dz = Floor.dir(d)
		local toward = origin:VectorToWorldSpace(Vector3.new(dx, 0, dz))
		UnitKit.dropWall(unit, if leftward:Dot(toward) > 0 then "WallLeft" else "WallRight")
	end
end

local function block(
	name: string,
	size: Vector3,
	at: CFrame,
	colour: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = at
	p.Color = colour
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- The lobby stand-in: its square (the hall leaving it toward -Z through an 8-stud mouth) and the
-- elevator's space behind it, one plain room lit only by the car's lamp.
local function lobby(origin: CFrame): Folder
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	local half = Floor.LobbySize / 2
	local back = half + Floor.ElevatorDepth -- the car's back wall, from the lobby's middle
	local length = back + half
	local middleZ = (back - half) / 2
	local width = Floor.LobbySize
	local h = LOBBY_HEIGHT
	local t = LOBBY_WALL
	local function put(
		name: string,
		size: Vector3,
		x: number,
		y: number,
		z: number,
		colour: Color3,
		material: Enum.Material
	): Part
		return block(name, size, origin * CFrame.new(x, y, z), colour, material, folder)
	end
	put("Floor", Vector3.new(width, 1, length), 0, -0.5, middleZ, CONCRETE, Enum.Material.Concrete)
	put(
		"Ceiling",
		Vector3.new(width, 1, length),
		0,
		h + 0.5,
		middleZ,
		CEILING_COLOUR,
		Enum.Material.Metal
	)
	for _, side in { -1, 1 } do
		put(
			"SideWall",
			Vector3.new(t, h, length),
			side * (half + t / 2),
			h / 2,
			middleZ,
			UnitKit.Colours.Wall,
			Enum.Material.Concrete
		)
		-- either side of the hall's mouth, inside the lobby so its back meets the first units' walls
		local mouth = Floor.HallWidth / 2
		put(
			"FrontWall",
			Vector3.new(half - mouth, h, t),
			side * (mouth + half) / 2,
			h / 2,
			-half + t / 2,
			UnitKit.Colours.Wall,
			Enum.Material.Concrete
		)
	end
	put(
		"BackWall",
		Vector3.new(width, h, t),
		0,
		h / 2,
		back + t / 2,
		UnitKit.Colours.Wall,
		Enum.Material.Concrete
	)
	put(
		"CarFloor",
		Vector3.new(width - 4, 0.1, Floor.ElevatorDepth - 2),
		0,
		0.05,
		half + Floor.ElevatorDepth / 2,
		PLATE_COLOUR,
		Enum.Material.DiamondPlate
	)
	local lamp = put(
		"CarLamp",
		Vector3.new(4, 0.2, 1),
		0,
		h - 0.1,
		half + 4,
		LAMP_COLOUR,
		Enum.Material.Neon
	)
	lamp.CanCollide = false
	lamp.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = LAMP_COLOUR
	light.Brightness = LAMP_BRIGHTNESS
	light.Range = LAMP_RANGE
	light.Parent = lamp
	return folder
end

type Laying = {
	floor: Floor.Floor,
	origin: CFrame,
	units: Units,
	door: Color3,
	slots: { [number]: { Floor.Slot } },
	lids: { [Floor.Size]: Model }, -- a plain wall's lid per size (lidOf), missing if it can't be made
	deadEnds: { [number]: { Floor.DeadEnd } },
	fixtures: { [number]: Floor.Fixture },
	breathe: () -> (), -- waits for the next frame once this one's share is spent
}

-- One hall piece and everything on it: its floor and deck (a junction with its walls), the units
-- and plain walls lining it, a dead end closing it, its light. Returns its folder, unparented, and
-- how many units it holds.
local function piece(laying: Laying, index: number): (Folder, number)
	local cell = laying.floor.cells[index]
	local origin = laying.origin
	local paint = UnitKit.Colours.Wall
	local folder = Instance.new("Folder")
	folder.Name = `{cell.kind}{index}`
	local slots: { Floor.Slot } = laying.slots[index] or {}
	local frame = frameOf(cell.x, cell.z, cell.turn)
	local junction: CorridorKit.JunctionName? = junctionOf(cell.kind)
	if junction then
		-- the junction's own walls stand where its slots are plain walls; a unit takes the place of one
		local units: { Vector3 } = {}
		for _, s in slots do
			if s.kind == "Unit" then
				table.insert(units, frame:PointToObjectSpace(Vector3.new(s.x, 0, s.z)))
			end
		end
		CorridorKit.junction(junction, origin * frame, paint, folder, units)
	else
		CorridorKit.place("Straight", origin * frame, folder)
	end
	local count = 0
	for _, s in slots do
		local face = origin * faceOf(s.x, s.z, s.facing)
		if s.kind == "Unit" then
			local unit = FloorBuilder.unit(
				if s.size == "S" then laying.units.S else laying.units.M,
				face,
				s.number :: string,
				laying.door
			)
			dropWalls(unit, s.drops, origin)
			unit.Parent = folder
			laying.breathe()
			count += 1
		else
			if not junction then
				CorridorKit.wall(if s.size == "M" then "Wall" else "ShortWall", face, paint, folder)
			end
			local lid = if s.top then laying.lids[s.size] else nil
			if lid then
				local copy = lid:Clone()
				copy:PivotTo(face)
				copy.Parent = folder
			end
		end
	end
	local deadEnds: { Floor.DeadEnd } = laying.deadEnds[index] or {}
	for _, e in deadEnds do
		CorridorKit.wall("DeadEnd", origin * faceOf(e.x, e.z, e.facing), paint, folder)
	end
	local f = laying.fixtures[index]
	if f then
		local hung = CorridorKit.hang(origin * frameOf(f.x, f.z, f.turn), folder)
		hung.model:SetAttribute(
			MotionLight.PowerAttribute,
			FloorBuilder.powerZone(laying.floor.number, f.zone)
		)
		hung.model:AddTag(MotionLight.Tag)
	end
	return folder, count
end

--[[
	Lays `floor` with its lobby's middle at `origin` (on the floor, the halls spreading along its
	-Z) into a new model under `parent`, and returns the model and what it took. Yields: the lobby
	comes first, then the hall pieces nearest it, each parented as it's finished. Errors if the place
	lacks a template (FloorBuilder.units says which).
]]
function FloorBuilder.lay(floor: Floor.Floor, origin: CFrame, parent: Instance): (Model, Laid)
	local units, missing = FloorBuilder.units()
	assert(
		units,
		`FloorBuilder: no template at {missing}; import it (art/unit/README.md, art/corridor/README.md)`
	)
	local started = os.clock()

	local laid: Laid = { units = 0, pieces = 0, frames = 1, seconds = 0, working = 0, longest = 0 }
	local slice = started
	local function endSlice()
		local spent = os.clock() - slice
		laid.working += spent
		laid.longest = math.max(laid.longest, spent)
	end
	-- a piece is parented once, when it's whole, but the work of dressing it can span frames
	local function breathe()
		if os.clock() - slice > FRAME_BUDGET then
			endSlice()
			task.wait()
			laid.frames += 1
			slice = os.clock()
		end
	end

	local laying: Laying = {
		floor = floor,
		origin = origin,
		units = units,
		door = (UnitKit.Colours.Door :: { [string]: Color3 })[floor.paint],
		slots = {},
		lids = {},
		deadEnds = {},
		fixtures = {},
		breathe = breathe,
	}
	assert(laying.door, `FloorBuilder: no door colour {floor.paint}`)
	for _, size: Floor.Size in LID_SIZES do
		local lid, lacking = lidOf(if size == "S" then units.S else units.M)
		if lid then
			laying.lids[size] = lid
		else
			warn(
				`FloorBuilder: ReplicatedStorage.Units.{size} has no {lacking} with its collider, so `
					.. "its plain walls stay open on top: a friend running the tops drops in behind"
			)
		end
	end
	for _, s in floor.slots do
		local list = laying.slots[s.cell] or {}
		laying.slots[s.cell] = list
		table.insert(list, s)
	end
	for _, e in floor.deadEnds do
		local list = laying.deadEnds[e.cell] or {}
		laying.deadEnds[e.cell] = list
		table.insert(list, e)
	end
	for _, f in floor.fixtures do
		laying.fixtures[f.cell] = f
	end

	-- out from the lobby, nearest first, so the floor fills in around the players arriving
	local order: { number } = {}
	for i in floor.cells do
		if i ~= floor.lobby then
			table.insert(order, i)
		end
	end
	local function reach(i: number): number
		local c = floor.cells[i]
		return c.x * c.x + c.z * c.z
	end
	laid.pieces = #order
	table.sort(order, function(a: number, b: number): boolean
		local ra, rb = reach(a), reach(b)
		return if ra ~= rb then ra < rb else a < b
	end)

	local model = Instance.new("Model")
	model.Name = `Floor{floor.number}`
	model.WorldPivot = origin
	lobby(origin).Parent = model
	model.Parent = parent
	breathe()

	for _, index in order do
		local folder, count = piece(laying, index)
		folder.Parent = model
		laid.units += count
		laying.breathe()
	end
	endSlice()
	laid.seconds = os.clock() - started
	return model, laid
end

return FloorBuilder
