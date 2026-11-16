--!strict
--[[
	FloorBuilder: lays one floor of the building from its data (L-01c). `Floor.generate` says where
	every hall, unit, wall and light goes; this puts the real pieces there, so a seed becomes a
	floor you can walk: CorridorKit's straights, junctions, walls and dead ends; the M and S units
	from ReplicatedStorage.Units, in the floor's door colour and numbered; and a motion light over
	every hall piece, in its power zone. A plain wall in a top run gets a lid over the empty slot
	behind it, the unit's own steel top and floor, so a friend running the tops never drops in; a
	junction's square a run reaches gets the S unit's steel top, so the run turns the corner; and
	the kit's wall panel closes every other edge of the tops up to the deck (`Floor`'s lids and
	panels, D-055). Given
	the floor's deal, each door the deal padlocked is padlocked (the code's notes come in their
	units' marked boxes since B-04a: Deals), as the unit is laid: the floor
	arrives that way, without a sound. What's behind each door is dealt when it first lifts (Deals,
	L-04e). The lobby is a plain room, the freight elevator standing in its back wall and lit only by the car's
	lamp, until L-05 dresses the lobby.

	Laying yields. It works out from the lobby a hall piece at a time and waits a frame whenever it
	has spent its share of one, so the server never hitches: the climb lays the next floor while the
	team plays this one (Climbs). Each unit is dressed before it joins its hall piece, once: clients
	cache a door's frame and colours when its unit arrives.

	`unit` puts one unit at a door face; the test hall (DevCorridor) uses it too. Its door's buttons
	come from the Doors system once it's in the world.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Breaker = require(ReplicatedStorage.Shared.Breaker)
local CorridorKit = require(ReplicatedStorage.Shared.CorridorKit)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local FaintMark = require(ReplicatedStorage.Shared.FaintMark)
local NoteSpot = require(ReplicatedStorage.Shared.Elevator.NoteSpot)
local Floor = require(ReplicatedStorage.Shared.Floor)
local Machine = require(ReplicatedStorage.Shared.Machine)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local Tops = require(ReplicatedStorage.Shared.Tops)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

-- How long laying may take of each server frame (60 a second, about 16.7 ms each) before it waits
-- for the next: low enough that a laying floor never stutters the floor being played.
local FRAME_BUDGET = 0.004

-- The lobby stand-in, in studs and colours (L-05 dresses the real one). Its back wall is the
-- elevator's landing wall, as deep as the art was built for.
local LOBBY_HEIGHT = 14 -- up to the kit's deck, so the lobby's ceiling meets the hall's
local LOBBY_WALL = Elevator.Specs.Opening.Wall
local CONCRETE = Color3.fromRGB(120, 120, 118) -- the hall floor's grey
local CEILING_COLOUR = Color3.fromRGB(38, 38, 40)

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
	elevator: Model?, -- the lobby's freight elevator, its gate shut; nil if the place has none
	slots: { [Model]: number }, -- each unit laid, and its slot's index in the floor's `slots`
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

-- Where a unit's bulb hangs: under the middle of its steel top, from the underside of the channel
-- across it (the steel top's box bottoms out on its channels; CorridorKit.Specs.Bulb.ChannelDrop).
-- Read from the unit's own steel top, so it holds for every size.
local function bulbPoint(unit: Model): CFrame?
	local top = unit:FindFirstChild("Top", true)
	if not (top and top:IsA("BasePart")) then
		return nil
	end
	local cf, size = top.CFrame, top.Size
	local half = (
		math.abs(cf.RightVector.Y) * size.X
		+ math.abs(cf.UpVector.Y) * size.Y
		+ math.abs(cf.LookVector.Y) * size.Z
	) / 2
	return CFrame.new(cf.Position - Vector3.yAxis * half)
end

local warnedBulb = false
-- Studs a unit's drawn floor sits above the hall floor it may overlap (its collider stays at 0,
-- so feet and dealt things stand where they did; the lip at the door is too thin to see).
local FLOOR_LIFT = 0.03

-- A unit's door face: the middle of its doorway's outer face on the floor, looking into the hall
-- (NoteSpot's and DealSpot's frame: +Z into the unit).
function FloorBuilder.face(unit: Model): CFrame
	return RollUpDoor.frame(unit) * CFrame.new(0, 0, -specOf(unit).CurtainPlane)
end

-- A clone of `template` with its door's outer face at `face` (looking into the hall), painted,
-- numbered and with its bulb hung, ready to parent (the Doors system gives it its buttons once
-- it's in the world, UnitLights lights the bulb with the door). Units are dressed before they
-- reach Workspace: clients cache the door's frame and colours when a unit arrives.
function FloorBuilder.unit(template: Model, face: CFrame, number: string, colour: Color3): Model
	local unit = template:Clone()
	local outer = FloorBuilder.face(unit)
	unit:PivotTo(face * outer:ToObjectSpace(unit:GetPivot()))
	-- its floor drawn a hair over the hall's: a junction's concrete runs on under the front of the
	-- units round it at the same height, and two surfaces at one height flicker as the view turns
	local drawn = unit:FindFirstChild("Floor")
	if drawn and drawn:IsA("BasePart") then
		drawn.CFrame += Vector3.yAxis * FLOOR_LIFT
	end
	unit.Name = `Unit{number}`
	UnitKit.paint(unit, colour, UnitKit.Colours.Wall)
	UnitKit.number(unit, number)
	RollUpDoor.fitCollider(unit)
	local at = bulbPoint(unit)
	if not CorridorKit.template("Bulb") then
		-- a unit without its bulb still plays; it's only dark inside
		if not warnedBulb then
			warnedBulb = true
			warn(
				"FloorBuilder: units hang no bulb; the place lacks ReplicatedStorage.Corridor.Bulb"
			)
		end
	elseif at then
		CorridorKit.hangBulb(at, unit)
	end
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

-- The parts a plain wall's lid is made of: the unit's steel top to run across and its floor, so
-- the empty slot under the steel reads as an empty unit, not the void below the building. A
-- junction's square already has the junction's floor, so its lid is the S unit's steel top alone.
local LID_PARTS = { "Top", "Floor" }
local SQUARE_LID_PARTS = { "Top" }
local LID_SIZES: { Floor.Size } = { "M", "S" }

--[[
	A lid of the unit template's own `parts` and their colliders, made once, in a door face's frame
	(a plain wall's frame is a unit's door face, a junction lid's the same): pivot it to the face.
	Nil and the missing part's name if the template lacks one.
]]
local function lidOf(template: Model, parts: { string }): (Model?, string?)
	local outer = RollUpDoor.frame(template) * CFrame.new(0, 0, -specOf(template).CurtainPlane)
	local lid = Instance.new("Model")
	lid.Name = "Lid"
	local colliders = Instance.new("Folder")
	colliders.Name = "Colliders"
	colliders.Parent = lid
	local templateColliders = template:FindFirstChild("Colliders")
	for _, name in parts do
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

-- The lobby stand-in: its square (the hall leaving it toward -Z through an 8-stud mouth), its back
-- wall built round the landing's opening, and the freight elevator standing in it, the car
-- behind the wall in the floor's elevator space, its lamp the only light.
local function lobby(origin: CFrame): (Folder, Model?)
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	local half = Floor.LobbySize / 2
	local width = Floor.LobbySize
	local h = LOBBY_HEIGHT
	local t = LOBBY_WALL
	local length = Floor.LobbySize + t -- the back wall stands on the floor's far edge
	local middleZ = t / 2
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
	local opening = Elevator.Specs.Opening
	local ow, oh = opening.Width / 2, opening.Height
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
		-- the back wall either side of the landing's opening, its face where the threshold is
		put(
			"BackWall",
			Vector3.new(half - ow, h, t),
			side * (ow + half) / 2,
			h / 2,
			half + t / 2,
			UnitKit.Colours.Wall,
			Enum.Material.Concrete
		)
	end
	put(
		"BackWall",
		Vector3.new(ow * 2, h - oh, t),
		0,
		(h + oh) / 2,
		half + t / 2,
		UnitKit.Colours.Wall,
		Enum.Material.Concrete
	)
	-- its threshold on the back wall's face, the lobby before it, its gate shut until the code
	local elevator = Elevator.clone(origin * CFrame.new(0, 0, half), folder, 1)
	if elevator then
		Machine.place(elevator) -- the machine in its back corner, waking on the ride (S1-10b)
	end
	return folder, elevator
end

type Laying = {
	floor: Floor.Floor,
	origin: CFrame,
	units: Units,
	door: Color3,
	slots: { [number]: { Floor.Slot } },
	lids: { [Floor.Size]: Model }, -- a plain wall's lid per size (lidOf), missing if it can't be made
	squareLid: Model?, -- a junction square's lid, the S unit's steel top (lidOf)
	squares: { [number]: { Floor.Lid } }, -- each junction's lidded squares
	panels: { [number]: { Floor.Panel } }, -- the panels closing the tops, by the piece they close
	deadEnds: { [number]: { Floor.DeadEnd } },
	fixtures: { [number]: Floor.Fixture },
	padlocked: { [Floor.Slot]: boolean }, -- the doors the deal padlocked
	marked: Floor.Slot?, -- the unit whose jamb carries the floor's faint mark (S1-11)
	indexOf: { [Floor.Slot]: number }, -- each slot's index in the floor's `slots`
	laid: { [Model]: number }, -- each unit laid so far, and its slot's index
	breathe: () -> (), -- waits for the next frame once this one's share is spent
}

-- The code's note in unit `unit` (its number `number`, its size `size`), on its back wall where
-- NoteSpot says, `text` written on it ("_ 7 _ _"). Since B-04a a note comes in its unit's marked
-- box (Deals); this is where it goes only when no box can hold it, or its holder leaves (until
-- B-04b drops it where they were). Without the place's template Elevator.note warns.
function FloorBuilder.stickNote(unit: Model, size: Floor.Size, number: string, text: string)
	local face = FloorBuilder.face(unit)
	local spot = NoteSpot.inUnit(Specs[size].Depth, number)
	local pivot = face * CFrame.new(spot.x, spot.y, spot.z) * CFrame.Angles(0, 0, spot.tilt)
	local note = Elevator.note(pivot, unit, text)
	if note then
		note:ScaleTo(NoteSpot.Scale) -- about its pivot, so its back stays on the wall
	end
end

local warnedMark = false
-- The floor's faint mark (S1-11) on the left jamb of the unit at `face` (FaintMark), hidden until a
-- screen's beam finds it (FaintMarkView). In the hall piece's folder, not the unit, so nothing that
-- dresses or fades a unit's parts ever meets it. Without the place's template it warns once.
local function stampMark(face: CFrame, size: Floor.Size, parent: Instance)
	local props = ReplicatedStorage:FindFirstChild("Props")
	local template = props and props:FindFirstChild("FaintMark")
	if not (template and template:IsA("BasePart")) then
		if not warnedMark then
			warnedMark = true
			warn(
				"FloorBuilder: no faint mark at ReplicatedStorage.Props.FaintMark (art/mark/README.md)"
			)
		end
		return
	end
	local x = FaintMark.Side * (Specs[size].DoorWidth / 2 + FaintMark.Trim / 2)
	local mark = template:Clone()
	mark.Name = "FaintMark"
	-- its drawn face is its front (-Z), out into the hall like the face's
	mark.CFrame = face * CFrame.new(x, FaintMark.Height, -FaintMark.Proud)
	mark.Transparency = 1
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanQuery = false
	mark.CanTouch = false
	mark.CastShadow = false
	mark:AddTag(FaintMark.Tag)
	mark.Parent = parent
end

-- One hall piece and everything on it: its floor and deck (a junction with its walls), the units
-- and plain walls lining it, a dead end closing it, its light. Returns its folder, unparented, and
-- how many units it holds.
local function piece(laying: Laying, index: number, parent: Instance): (Folder, number)
	local cell = laying.floor.cells[index]
	local origin = laying.origin
	local paint = UnitKit.Colours.Wall
	local folder = Instance.new("Folder")
	folder.Name = `{cell.kind}{index}`
	-- in place first, empty: each unit then joins it whole as it's dressed, one at a time, so no
	-- frame takes a whole hall's worth into the game at once (a piece of eight units at once
	-- held the server 160 ms while the next floor laid during play, L-08b)
	folder.Parent = parent
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
			if laying.padlocked[s] then
				RollUpDoor.setLocked(unit, true)
			end
			if laying.marked == s then
				stampMark(face, s.size, folder)
			end
			laying.laid[unit] = laying.indexOf[s]
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
	-- the tops closed (D-055): a steel top over each of a junction's squares a run reaches, so the run
	-- goes on round the corner, and a panel wherever stepping off the tops drops into nothing
	local squareLid = laying.squareLid
	if squareLid then
		local squares: { Floor.Lid } = laying.squares[index] or {}
		for _, l in squares do
			local copy = squareLid:Clone()
			copy:PivotTo(origin * faceOf(l.x, l.z, l.facing))
			copy.Parent = folder
		end
	end
	local panels: { Floor.Panel } = laying.panels[index] or {}
	for _, p in panels do
		local name: CorridorKit.PanelName = if p.size == "M" then "Wall" else "ShortWall"
		CorridorKit.panel(name, origin * faceOf(p.x, p.z, p.facing), folder, p.bare)
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
	The floor's breaker box (S2-02b) at `face` (a wall's face, looking into the hall): a copy of
	`ReplicatedStorage.Props.Breaker`, the power on, tagged for the server's Breakers with the
	floor's power zones to cut. Warns and hangs none if the place lacks the template.
]]
local function hangBreaker(floor: Floor.Floor, face: CFrame, parent: Instance)
	local props = ReplicatedStorage:FindFirstChild("Props")
	local template = props and props:FindFirstChild("Breaker")
	if not (template and template:IsA("Model")) then
		warn("FloorBuilder: no ReplicatedStorage.Props.Breaker, so this floor has no breaker")
		return
	end
	local box = template:Clone()
	box:PivotTo(face)
	local zones: { string } = {}
	for _, zone in Breaker.zones(floor) do
		table.insert(zones, FloorBuilder.powerZone(floor.number, zone))
	end
	box:SetAttribute(Breaker.ZonesAttribute, table.concat(zones, ","))
	box:SetAttribute(Breaker.OnAttribute, true)
	box:AddTag(Breaker.Tag)
	box.Parent = parent
end

-- The tops' map (L-13b2c) on `container`, for the crawl along them: every screen and the server
-- find it by its tag and read where the steel is (`Tops`).
local function publishTops(
	container: Instance,
	origin: CFrame,
	tops: { Tops.Rect },
	lips: { Tops.Rect }
)
	container:SetAttribute(Tops.MapAttribute, Tops.encode(tops, lips))
	container:SetAttribute(Tops.OriginAttribute, origin)
	container:AddTag(Tops.Tag)
end

--[[
	The tops of the units standing under `container` (the test hall's, which aren't a floor's),
	published for the crawl: each unit's top and the lip over its hall, in the world's frame. A
	floor publishes its own runs and lids as it's laid.
]]
function FloorBuilder.unitTops(container: Instance)
	local tops: { Tops.Rect } = {}
	local lips: { Tops.Rect } = {}
	for _, d in container:GetDescendants() do
		if d:IsA("Model") and d:HasTag(UnitKit.Tag) then
			local face = FloorBuilder.face(d)
			local spec = specOf(d)
			local look = face.LookVector
			table.insert(
				tops,
				Tops.footprint(face.X, face.Z, look.X, look.Z, spec.Width, spec.Depth)
			)
			table.insert(lips, Tops.lip(face.X, face.Z, look.X, look.Z, spec.Width))
		end
	end
	publishTops(container, CFrame.identity, tops, lips)
end

--[[
	Lays `floor` with its lobby's middle at `origin` (on the floor, the halls spreading along its
	-Z) into a new model under `parent`, and returns the model and what it took. With the floor's
	`deck` (Deal.new), the doors it padlocked are padlocked and the floor's mark is stamped. Yields: the lobby
	comes first, then the hall pieces nearest it, each parented as it's finished. Errors if the place
	lacks a template (FloorBuilder.units says which).
]]
function FloorBuilder.lay(
	floor: Floor.Floor,
	origin: CFrame,
	parent: Instance,
	deck: Deal.Deck?
): (Model, Laid)
	local units, missing = FloorBuilder.units()
	assert(
		units,
		`FloorBuilder: no template at {missing}; import it (art/unit/README.md, art/corridor/README.md)`
	)
	local started = os.clock()

	local laid: Laid = {
		units = 0,
		pieces = 0,
		frames = 1,
		seconds = 0,
		working = 0,
		longest = 0,
		elevator = nil,
		slots = {},
	}
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
		squareLid = nil,
		squares = {},
		panels = {},
		deadEnds = {},
		fixtures = {},
		padlocked = {},
		marked = nil,
		indexOf = {},
		laid = laid.slots,
		breathe = breathe,
	}
	assert(laying.door, `FloorBuilder: no door colour {floor.paint}`)
	for _, size: Floor.Size in LID_SIZES do
		local lid, lacking = lidOf(if size == "S" then units.S else units.M, LID_PARTS)
		if lid then
			laying.lids[size] = lid
		else
			warn(
				`FloorBuilder: ReplicatedStorage.Units.{size} has no {lacking} with its collider, so `
					.. "its plain walls stay open on top: a friend running the tops drops in behind"
			)
		end
	end
	local squareLid, lacking = lidOf(units.S, SQUARE_LID_PARTS)
	laying.squareLid = squareLid
	if not squareLid then
		warn(
			`FloorBuilder: ReplicatedStorage.Units.S has no {lacking} with its collider, so the `
				.. "junctions' squares stay open on top: a friend running the tops drops in at a corner"
		)
	end
	for _, l in floor.lids do
		local list = laying.squares[l.cell] or {}
		laying.squares[l.cell] = list
		table.insert(list, l)
	end
	for _, p in floor.panels do
		local list = laying.panels[p.cell] or {}
		laying.panels[p.cell] = list
		table.insert(list, p)
	end
	for i, s in floor.slots do
		laying.indexOf[s] = i
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
	if deck then
		for i in deck.padlocked do
			laying.padlocked[floor.slots[i]] = true
		end
		laying.marked = if deck.marked then floor.slots[deck.marked] else nil
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
	-- publishing the tops and building the lobby each get a frame of their own when the slice runs
	-- over: together they made one long frame (46 ms laying floor 12 in Play; 6 ms at most after,
	-- S4-01b), and a team on the floor below must never feel the next one being laid
	local tops, lips = Tops.rects(floor)
	breathe()
	publishTops(model, origin, tops, lips)
	breathe()
	local hall, elevator = lobby(origin)
	hall.Parent = model
	laid.elevator = elevator
	model.Parent = parent
	breathe()

	for _, index in order do
		local _, count = piece(laying, index, model)
		laid.units += count
		laying.breathe()
	end
	local spot = deck and deck.breaker
	if spot then
		hangBreaker(floor, origin * faceOf(spot.x, spot.z, spot.facing), model)
	end
	endSlice()
	laid.seconds = os.clock() - started
	return model, laid
end

return FloorBuilder
