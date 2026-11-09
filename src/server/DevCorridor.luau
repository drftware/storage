--!strict
--[[
	DevCorridor: a Studio-only test hall of real storage units, for trying every door action with a
	friend before the game's floors exist. The server's Host runs it only in Studio Play.

	Eight units face each other across an 8-stud hall that runs along X, numbered 101 to 108 (odd
	numbers on one side) and painted in the four door colours; 105 and 108 start padlocked. Each door
	has one prompt per action, each on its own key so none hides another: Peek Q, Open E, Close F,
	Slam G, Lock or Unlock R, and Lift T from inside. A refusal flashes on the prompt ("Padlocked",
	"Shut it first").

	A lone unit 700 studs down the hall tests streaming: "Go far" by the spawn sends you there and
	"Come back" returns you, so the hall's units stream out and back in with their doors as left.

	The hall's floor and ceiling are three of the corridor kit's straight pieces (P0-03a), its
	lights are the kit's fixtures (P0-03b), each midway between two joists, and past the last units
	each side is the kit's plain wall, with a dead end closing the spawn's end (P0-03c). At the far
	end the hall meets a T (P0-03d): one arm runs to a dead end, the other to a blind corner and a
	short dark hall beyond it. Every fixture is a motion light (L-03): the hall starts dark, its
	eyes open, and lights as you walk it. A breaker post in the T cuts the north arm's power, so its
	fixtures go blind. Without the kit's templates in the place it falls back to plain blocks and
	bare lit tubes, and a dead end where the T would be.
	The prompts call RollUpDoor directly; the GDD's door state machine replaces them (L-02).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CorridorKit = require(ReplicatedStorage.Shared.CorridorKit)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Elevators = require(script.Parent.Elevators)
local Prompts = require(script.Parent.Prompts)
local Floor = require(ReplicatedStorage.Shared.Floor)
local FloorBuilder = require(script.Parent.FloorBuilder)
local HallLight = require(ReplicatedStorage.Shared.HallLight)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local MotionLights = require(script.Parent.MotionLights)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Slots = require(script.Parent.Slots)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

-- The layout, in studs. The hall runs along X; doors face each other across Z.
local HALL_HALF_WIDTH = 4 -- an 8-stud hall: door faces at z = -4 and z = +4
local UNIT_XS = { -18, -6, 6, 18 } -- four 12-stud units a side, wall to wall
local UNITS_HALF_LENGTH = 24 -- the last units' outer walls
local BUILDING_HALF_LENGTH = 36 -- three 24-stud kit pieces; dead ends at x = -36 and 36
local BUILDING_HALF_DEPTH = 17 -- without the kit: side walls just behind the units' backs
local CEILING = 13.4 -- without the kit: a plain ceiling, as in the look sheets
local BAY_WALL = 0.5 -- without the kit: the plain blocks along the hall past the last units
local FLOOR_TOP = -0.05 -- just under the units' own floors (top at 0), so the two never flicker
local FAR_X = 700 -- far past the streaming target radius (256), so the hall streams out

-- The hall's fixtures, one every 24 studs: over 101 and 102 by the spawn, over 105 and 106, and
-- past the last units, with the exit sign's red at the far end. Each sits midway between two of
-- the kit's joists (6 studs off a piece's middle). Each is a motion light, dark until something
-- moves under it. `z` and `turned` hang one in a hall along Z; `power` puts it in a power zone.
type Fixture = { x: number, z: number?, turned: boolean?, power: string? }
local HALL_FIXTURES: { Fixture } = { { x = -18 }, { x = 6 }, { x = 30 } }
local EXIT_SIGN_SIZE = Vector3.new(0.2, 0.7, 1.8)
-- High on the far wall, just under its cap (9.88), where exit signs hang: lit from across the
-- hall's length, so you see where the hall stops (or turns) before you reach it.
local EXIT_SIGN_HEIGHT = 9.4
local POST_PROUD = 0.07 -- a wall's posts stand this far into the hall; the sign hangs clear of them

-- The turn past the hall's far end (P0-03d), on the kit's 24-stud grid: a T whose arms run along
-- Z, its stub towards the hall; the south arm ends in a dead end, the north arm in a corner that
-- turns east into a short dark hall and a dead end. Each piece is its frame: the middle of its
-- floor, its X along its hall (a junction's along its deck, Specs.Junctions).
local TURN_T = CFrame.fromMatrix(Vector3.new(48, 0, 0), Vector3.zAxis, Vector3.yAxis)
local TURN_CORNER = CFrame.fromMatrix(Vector3.new(48, 0, 48), -Vector3.zAxis, Vector3.yAxis)
local TURN_STRAIGHTS = {
	CFrame.fromMatrix(Vector3.new(48, 0, 24), Vector3.zAxis, Vector3.yAxis),
	CFrame.fromMatrix(Vector3.new(48, 0, -24), Vector3.zAxis, Vector3.yAxis),
}
-- The short hall past the corner, running east to a dead end: the cramped part of the building,
-- three small units a side (8 studs each, wall to wall from the corner to the dead end), 109 to
-- 114. Plain walls line it when the place has no small unit's template.
local EAST_HALL = CFrame.new(72, 0, 48)
local SMALL_XS = { 64, 72, 80 }
local TURN_DEAD_ENDS = {
	CFrame.lookAt(Vector3.new(48, 0, -36), Vector3.new(48, 0, -35)),
	CFrame.lookAt(Vector3.new(84, 0, 48), Vector3.new(83, 0, 48)),
}
-- A light over the T's middle, one down each arm, one over the corner and one in the east hall,
-- so every step of the turn is under a light that watches it. The north arm, the corner and the
-- east hall are on the breaker's zone. A junction's middle is midway between two of its joists,
-- like a straight's.
local BREAKER_ZONE = "NorthArm"
local TURN_FIXTURES: { Fixture } = {
	{ x = 48, z = 0, turned = true },
	{ x = 48, z = -24, turned = true },
	{ x = 48, z = 24, turned = true, power = BREAKER_ZONE },
	{ x = 48, z = 48, turned = true, power = BREAKER_ZONE },
	{ x = 72, z = 48, power = BREAKER_ZONE },
}
local TURN_WALL_X = 52 -- the T's far wall, across from the hall
-- The breaker post: in the T's south half against its west wall, out of the way of the turn, with
-- the north arm's fixture in sight up the arm.
local BREAKER_POST = Vector3.new(45, 0, -8)

local CONCRETE = Color3.fromRGB(74, 74, 76)
-- Light concrete, like the sheets' floor, so a fixture's pool reads on it, where the kit isn't.
local FLOOR_COLOUR = Color3.fromRGB(120, 120, 118)
local CEILING_COLOUR = Color3.fromRGB(38, 38, 40)
local SPAWN = CFrame.lookAt(Vector3.new(-32, 3, 0), Vector3.new(0, 3, 0))
local FAR_SPOT = CFrame.lookAt(Vector3.new(FAR_X + 6, 3, 0), Vector3.new(FAR_X, 3, -4))
-- The floor laid beside the hall (L-01c), its lobby's middle here: far enough off that the hall
-- streams out while you walk it. Unless Workspace's DevFloorSeed and DevFloorNumber attributes say
-- otherwise, it's floor 3 from seed 7, the one `lune run scripts/floor-map 7 3` prints.
local FLOOR_ORIGIN = CFrame.new(0, 0, -600)
local FLOOR_SEED = 7
local FLOOR_NUMBER = 3
local FLOOR_ARRIVAL = CFrame.lookAt(Vector3.new(0, 3, 6), Vector3.new(0, 3, -12)) -- in the lobby, facing the hall
-- The test hall's bolt cutters (L-11b): a pair on the hall floor by the spawn, a pair in the first
-- unit on the right (open its door to find them).
local CUTTERS = {
	{ at = Vector3.new(-28.5, FLOOR_TOP, 2.2), yaw = 64 },
	{ at = Vector3.new(-17, 0, 11), yaw = 205 },
}
local FLOOR_POST = CFrame.new(9, 0, 9) -- "Come back", in the lobby's corner by the elevator

local DOOR_COLOURS = {
	UnitKit.Colours.Door.Oxblood,
	UnitKit.Colours.Door.Teal,
	UnitKit.Colours.Door.Mustard,
	UnitKit.Colours.Door.Navy,
}
local PADLOCKED = { ["105"] = true, ["108"] = true, ["112"] = true }

local function block(
	name: string,
	size: Vector3,
	cframe: CFrame,
	colour: Color3,
	parent: Instance
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = colour
	p.Material = Enum.Material.Concrete
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Where a door's outer face goes: at x on one side of a hall along X (the main hall, or one
-- centred on z = hallZ), looking across it. A plain wall stands on the same line.
local function doorFace(x: number, side: number, hallZ: number?): CFrame
	local at = Vector3.new(x, 0, (hallZ or 0) + side * HALL_HALF_WIDTH)
	return CFrame.lookAt(at, at - Vector3.zAxis * side)
end

-- A hall light at f.x: the kit's fixture in a kit hall, a motion light the server and each
-- screen light (MotionLights, HallLights), or a bare lit tube where its lens would hang.
local function fixture(f: Fixture, kit: boolean, parent: Instance)
	if kit and CorridorKit.template("Fixture") then
		local at = CFrame.new(f.x, 0, f.z or 0)
		if f.turned then
			at *= CFrame.Angles(0, math.pi / 2, 0)
		end
		local hung = CorridorKit.hang(at, parent)
		if f.power then
			hung.model:SetAttribute(MotionLight.PowerAttribute, f.power)
		end
		hung.model:AddTag(MotionLight.Tag)
		return
	end
	local tube = block(
		"TubeLight",
		HallLight.TubeSize,
		CFrame.new(f.x, HallLight.Height, 0),
		HallLight.Colour,
		parent
	)
	tube.CanCollide = false
	HallLight.light(tube, 1)
end

-- Plain walls down both sides of a straight piece at `at` (its X along the hall).
local function sideWalls(at: CFrame, length: number, parent: Instance)
	local slot = CorridorKit.Specs.Walls.Wall.Width
	for _, side in { -1, 1 } do
		for i = 0, length // slot - 1 do
			local face = at.Position
				+ at.XVector * (-length / 2 + slot * (i + 0.5))
				+ at.ZVector * side * HALL_HALF_WIDTH
			CorridorKit.wall(
				"Wall",
				CFrame.lookAt(face, face - at.ZVector * side),
				UnitKit.Colours.Wall,
				parent
			)
		end
	end
end

-- A closed box around a stretch of hall: floor, ceiling, end walls and side walls. With `kit`,
-- the floor and ceiling are the corridor kit's straight pieces, the walls rise to their deck, the
-- kit's plain walls line the hall past the last units, where no unit closes its side, and its dead
-- ends close the hall's ends (plain blocks where the place lacks those templates).
local function building(
	name: string,
	centreX: number,
	halfLength: number,
	fixtures: { Fixture },
	kit: boolean,
	parent: Instance,
	openFarEnd: boolean? -- the far (+X) end runs on into the turn: no end wall there
): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	local length = halfLength * 2
	local depth = if kit then CorridorKit.Specs.Span else BUILDING_HALF_DEPTH * 2
	local top = if kit then CorridorKit.Specs.DeckTop else CEILING
	local height = top - FLOOR_TOP
	if kit then
		local piece = CorridorKit.Specs.Pieces.Straight.Length
		local count = length // piece
		assert(count * piece == length, `DevCorridor: {name} isn't a whole number of kit pieces`)
		for i = 0, count - 1 do
			local x = centreX - halfLength + piece * (i + 0.5)
			CorridorKit.place("Straight", CFrame.new(x, 0, 0), folder)
		end
		local bay = halfLength - UNITS_HALF_LENGTH
		local slot = CorridorKit.Specs.Walls.Wall.Width
		local walls = CorridorKit.template("Wall") ~= nil
		assert(bay % slot == 0, `DevCorridor: {name}'s end bays aren't whole plain walls`)
		for _, side in { -1, 1 } do
			for _, toEnd in { -1, 1 } do
				if walls then
					for i = 0, bay // slot - 1 do
						local x = centreX + toEnd * (UNITS_HALF_LENGTH + slot * (i + 0.5))
						CorridorKit.wall("Wall", doorFace(x, side), UnitKit.Colours.Wall, folder)
					end
					continue
				end
				block(
					"BayWall",
					Vector3.new(bay, height, BAY_WALL),
					CFrame.new(
						centreX + toEnd * (UNITS_HALF_LENGTH + bay / 2),
						FLOOR_TOP + height / 2,
						side * (HALL_HALF_WIDTH + BAY_WALL / 2)
					),
					CONCRETE,
					folder
				)
			end
		end
	else
		block(
			"Floor",
			Vector3.new(length, 1, depth),
			CFrame.new(centreX, FLOOR_TOP - 0.5, 0),
			FLOOR_COLOUR,
			folder
		)
		block(
			"Ceiling",
			Vector3.new(length, 1, depth),
			CFrame.new(centreX, CEILING + 0.5, 0),
			CEILING_COLOUR,
			folder
		)
	end
	local deadEnds = kit and CorridorKit.template("DeadEnd") ~= nil
	for _, side in { -1, 1 } do
		local endX = centreX + side * (halfLength + 0.5)
		local wallZ = side * (depth / 2 + 0.5)
		-- the far end stays open where the turn continues the hall
		local closed = not (side > 0 and openFarEnd)
		if closed and deadEnds then
			local face = Vector3.new(centreX + side * halfLength, 0, 0)
			CorridorKit.wall(
				"DeadEnd",
				CFrame.lookAt(face, face - Vector3.xAxis * side),
				UnitKit.Colours.Wall,
				folder
			)
		elseif closed then
			block(
				"EndWall",
				Vector3.new(1, height, depth),
				CFrame.new(endX, FLOOR_TOP + height / 2, 0),
				CONCRETE,
				folder
			)
		end
		block(
			"SideWall",
			Vector3.new(length, height, 1),
			CFrame.new(centreX, FLOOR_TOP + height / 2, wallZ),
			CONCRETE,
			folder
		)
	end
	for _, f in fixtures do
		fixture(f, kit, folder)
	end
	folder.Parent = parent
	return folder
end

-- The neighbour at lower X already stands a wall where this unit's lower-X wall would go.
local function dropSharedWall(unit: Model)
	local left = unit:FindFirstChild("WallLeft")
	local right = unit:FindFirstChild("WallRight")
	if left and right and left:IsA("BasePart") and right:IsA("BasePart") then
		UnitKit.dropWall(
			unit,
			if left.Position.X < right.Position.X then "WallLeft" else "WallRight"
		)
	end
end

-- Units of one size down both sides of a hall along X centred on z = hallZ, wall to wall with
-- door faces at `xs`: numbered up from `first` as you walk east, odd on the south (-Z) side, the
-- four door colours in turn from `placed` (units placed so far). Returns the new count.
local function unitRows(
	template: Model,
	xs: { number },
	hallZ: number,
	first: number,
	placed: number,
	parent: Instance
): number
	for row, side in { -1, 1 } do
		for i, x in xs do
			local number = tostring(first + (i - 1) * 2 + row - 1)
			placed += 1
			local unit = FloorBuilder.unit(
				template,
				doorFace(x, side, hallZ),
				number,
				DOOR_COLOURS[(placed - 1) % 4 + 1]
			)
			if i > 1 then
				dropSharedWall(unit)
			end
			if PADLOCKED[number] then
				RollUpDoor.setLocked(unit, true)
			end
			unit.Parent = parent
		end
	end
	return placed
end

local function send(player: Player, to: CFrame)
	local ok, err = pcall(function()
		player:RequestStreamAroundAsync(to.Position)
	end)
	if not ok then
		warn(`DevCorridor: couldn't stream around {to.Position}: {err}`)
	end
	local character = player.Character
	if character and character.Parent then
		character:PivotTo(to)
	end
end

-- The breaker post at `at`: "Cut power" blinds the north arm's fixtures (and the corner's and the
-- east hall's) as the breaker room will
-- (GDD Lights), and "Restore power" brings them back, dark.
local function breakerPost(at: Vector3, lights: MotionLights.MotionLights, parent: Instance)
	local post = block(
		"Breaker",
		Vector3.new(0.4, 4, 0.4),
		CFrame.new(at.X, FLOOR_TOP + 2, at.Z),
		CONCRETE,
		parent
	)
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, 1, 0)
	a.Parent = post
	local p = Prompts.post(a, "Breaker", "Cut power")
	local isCut = false
	p.Triggered:Connect(function()
		isCut = not isCut
		lights:cut(BREAKER_ZONE, isCut)
		p.ActionText = if isCut then "Restore power" else "Cut power"
	end)
end

-- The turn past the hall's far end: the T, its arms, the corner and the hall beyond, their walls
-- and dead ends, their fixtures and the breaker post. With `smallUnits`, the units line the hall
-- beyond (placed by the caller) instead of plain walls.
local function turn(parent: Instance, lights: MotionLights.MotionLights, smallUnits: boolean)
	local paint = UnitKit.Colours.Wall
	CorridorKit.junction("T", TURN_T, paint, parent)
	CorridorKit.junction("Corner", TURN_CORNER, paint, parent)
	local length = CorridorKit.Specs.Pieces.Straight.Length
	for _, at in TURN_STRAIGHTS do
		CorridorKit.place("Straight", at, parent)
		sideWalls(at, length, parent)
	end
	CorridorKit.place("Straight", EAST_HALL, parent)
	if not smallUnits then
		sideWalls(EAST_HALL, length, parent)
	end
	for _, at in TURN_DEAD_ENDS do
		CorridorKit.wall("DeadEnd", at, paint, parent)
	end
	for _, f in TURN_FIXTURES do
		fixture(f, true, parent)
	end
	breakerPost(BREAKER_POST, lights, parent)
end

-- A post at `at` whose prompt sends you to `to`; while `ready` says no, it says so instead.
local function travelPost(
	name: string,
	at: Vector3,
	objectText: string,
	actionText: string,
	to: CFrame,
	parent: Instance,
	ready: (() -> boolean)?
)
	local post = block(
		name,
		Vector3.new(0.4, 4, 0.4),
		CFrame.new(at.X, FLOOR_TOP + 2, at.Z),
		CONCRETE,
		parent
	)
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, 1, 0)
	a.Parent = post
	local p = Prompts.post(a, objectText, actionText)
	local refuse = Prompts.refuser(p, function()
		return objectText
	end)
	p.Triggered:Connect(function(player: Player)
		if ready and not ready() then
			refuse("Still laying it")
			return
		end
		send(player, to)
	end)
end

-- Lays a floor from the data beside the hall (L-01c), prints its map, and opens the way there:
-- "Walk a floor" by the spawn, "Come back" in its lobby. Workspace's DevFloorSeed and
-- DevFloorNumber attributes pick which. Yields while it lays.
local function devFloor(folder: Folder, elevators: Elevators.Elevators)
	local units, missing = FloorBuilder.units()
	if not units then
		warn(
			`DevCorridor: no template at {missing}, so no floor to walk; import it (art/unit/README.md, art/corridor/README.md)`
		)
		return
	end
	local seed = Workspace:GetAttribute("DevFloorSeed")
	local number = Workspace:GetAttribute("DevFloorNumber")
	local s = if type(seed) == "number" then seed else FLOOR_SEED
	local n = if type(number) == "number"
		then math.clamp(math.floor(number), 1, 10)
		else FLOOR_NUMBER
	local ready = false
	travelPost(
		"WalkFloor",
		Vector3.new(-34, 0, -3),
		`Floor {n}`,
		"Walk a floor",
		FLOOR_ORIGIN * FLOOR_ARRIVAL,
		folder,
		function()
			return ready
		end
	)
	local random = Brix.Random.new({ seed = s })
	local floor = Floor.generate(n, random)
	-- the floor's code, from the same seed, as the deal will have it (L-04e lays the rest)
	local deck = Deal.new(floor, random)
	print(
		`DevCorridor: floor {n} from seed {s}, seen from above, the lobby (L) at the bottom:\n{Floor.map(
			floor
		)}`
	)
	local model, laid = FloorBuilder.lay(floor, FLOOR_ORIGIN, folder, deck)
	local elevator = laid.elevator
	if elevator then
		elevators:arm(elevator, deck.code, model)
		-- The stand-in ride (until L-08's): once the car leaves, those aboard arrive back by the
		-- spawn as their screens fade in (GateClock), and the elevator is armed again, shut and
		-- ready, so the floor can be run again without stopping Play.
		local riding = elevators.departed:connect(function(leaving: Elevators.Leaving)
			if leaving.elevator ~= elevator then
				return
			end
			local wait = leaving.at + Departure.Ride - Workspace:GetServerTimeNow()
			task.delay(math.max(wait, 0), function()
				for _, player in leaving.aboard do
					if player.Parent then
						send(player, SPAWN)
					end
				end
				if elevator.Parent then
					elevators:arm(elevator, deck.code, model)
				end
			end)
		end)
		model.Destroying:Once(function()
			riding:disconnect()
		end)
	end
	travelPost(
		"ComeBack",
		(FLOOR_ORIGIN * FLOOR_POST).Position,
		`Floor {n}`,
		"Come back",
		SPAWN,
		model
	)
	ready = true
	local work = string.format("%.0f ms", laid.working * 1000)
	local most = string.format("%.1f ms", laid.longest * 1000)
	local took = string.format("%.2f s", laid.seconds)
	print(
		`DevCorridor: floor {n} laid, {laid.units} units on {laid.pieces} hall pieces: {work} of work over {laid.frames} frames, at most {most} in one ({took} in all); "Walk a floor" is by the spawn`
	)
	-- Studio only: the code and where its notes are, so a tester can walk straight to them
	local where = {}
	for _, note in deck.notes do
		table.insert(where, `Unit{floor.slots[note.slot].number} ({Deal.noteText(deck, note)})`)
	end
	print(
		`DevCorridor: floor {n}'s code is {table.concat(deck.code)}; its notes: {table.concat(
			where,
			", "
		)}`
	)
end

-- Builds the whole corridor into one folder and parents it once. Returns nil, after a warning,
-- when the place has no unit template yet.
local function build(lights: MotionLights.MotionLights): Folder?
	local units = ReplicatedStorage:FindFirstChild("Units")
	local template = units and units:FindFirstChild("M")
	if not (template and template:IsA("Model")) then
		warn(
			'DevCorridor: no unit template at ReplicatedStorage.Units.M; import it (art/unit/README.md, "Into Studio")'
		)
		return nil
	end

	local kit = CorridorKit.template("Straight") ~= nil
	if not kit then
		warn(
			'DevCorridor: no corridor piece at ReplicatedStorage.Corridor.Straight, so the hall is plain blocks; import it (art/corridor/README.md, "Into Studio")'
		)
	end
	if kit and not (CorridorKit.template("Wall") and CorridorKit.template("DeadEnd")) then
		warn(
			'DevCorridor: no plain wall or dead end at ReplicatedStorage.Corridor, so the hall\'s ends are plain blocks; import them (art/corridor/README.md, "Into Studio")'
		)
	end
	if kit and not CorridorKit.template("Fixture") then
		warn(
			'DevCorridor: no fixture at ReplicatedStorage.Corridor.Fixture, so the hall lights are bare tubes; import it (art/corridor/README.md, "Into Studio")'
		)
	end

	local turns = kit
		and CorridorKit.template("T") ~= nil
		and CorridorKit.template("Corner") ~= nil
		and CorridorKit.template("ShortWall") ~= nil
		and CorridorKit.template("DeadEnd") ~= nil
	if kit and not turns then
		warn(
			'DevCorridor: no T, corner or short wall at ReplicatedStorage.Corridor, so the hall ends in a dead end; import them (art/corridor/README.md, "Into Studio")'
		)
	end

	local small = units and units:FindFirstChild("S")
	local smallUnits = turns and small ~= nil and small:IsA("Model")
	if turns and not smallUnits then
		warn(
			'DevCorridor: no small unit at ReplicatedStorage.Units.S, so plain walls line the hall past the corner; import it (art/unit/README.md, "Into Studio")'
		)
	end

	local folder = Instance.new("Folder")
	folder.Name = "DevCorridor"
	local hall = building("Hall", 0, BUILDING_HALF_LENGTH, HALL_FIXTURES, kit, folder, turns)
	if turns then
		turn(hall, lights, smallUnits)
	end
	-- on the far wall's face (the T's, or the dead end's), clear of its posts
	local farWall = if turns then TURN_WALL_X else BUILDING_HALF_LENGTH
	local sign = block(
		"ExitSign",
		EXIT_SIGN_SIZE,
		CFrame.new(farWall - POST_PROUD - EXIT_SIGN_SIZE.X / 2 - 0.01, EXIT_SIGN_HEIGHT, 0),
		HallLight.ExitColour,
		hall
	)
	sign.CanCollide = false
	HallLight.exitSign(sign, -Vector3.xAxis)
	building("FarHall", FAR_X, 12, { { x = FAR_X } }, false, folder)

	local count = unitRows(template, UNIT_XS, 0, 101, 0, folder)
	if smallUnits then
		count = unitRows(small :: Model, SMALL_XS, EAST_HALL.Position.Z, 109, count, folder)
	end
	FloorBuilder.unit(template, doorFace(FAR_X, -1), "901", UnitKit.Colours.Door.Teal).Parent =
		folder

	travelPost("GoFar", Vector3.new(-34, 0, 3), "Streaming test", "Go far", FAR_SPOT, folder)
	travelPost(
		"ComeBack",
		Vector3.new(FAR_X + 8, 0, 3),
		"Streaming test",
		"Come back",
		SPAWN,
		folder
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "DevSpawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(4, 0.2, 4)
	spawn.CFrame = CFrame.new(SPAWN.Position.X, FLOOR_TOP + 0.1, SPAWN.Position.Z)
	spawn.Parent = folder

	-- This runs only in Play, on the Play copy of the place: the place itself keeps its baseplate
	-- and spawn pad. The pad sits in the middle of the hall, so it goes too.
	for _, d in Workspace:GetDescendants() do
		if d:IsA("SpawnLocation") then
			d:Destroy()
		end
	end
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	folder.Parent = Workspace
	for _, player in Players:GetPlayers() do
		if player.Character then
			player.Character:PivotTo(SPAWN)
		end
	end
	print(`DevCorridor: {count + 1} units ready; "Go far" is by the spawn`)
	return folder
end

local DevCorridor = {}

function DevCorridor.new(): Brix.System
	local built: Folder? = nil
	local laying: thread? = nil
	return {
		name = "DevCorridor",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back a plain System; MotionLights fills this slot (init.server)
			local lights = (context.registry:get("motionLights") :: any) :: MotionLights.MotionLights
			-- any: as above; Elevators fills this slot
			local elevators = (context.registry:get("elevators") :: any) :: Elevators.Elevators
			-- any: as above; Slots fills this slot
			local slots = (context.registry:get("slots") :: any) :: Slots.Slots
			local folder = build(lights)
			built = folder
			if folder then
				-- bolt cutters to try the slots with (L-11b): one pair on the hall floor by the spawn,
				-- one in the first unit on the right
				for _, spot in CUTTERS do
					slots:lay("BoltCutters", spot.at, spot.yaw)
				end
				laying = task.spawn(devFloor, folder, elevators)
			end
		end,
		stop = function(_: any)
			if laying and coroutine.status(laying) ~= "dead" then
				task.cancel(laying)
			end
			laying = nil
			if built then
				built:Destroy()
				built = nil
			end
		end,
	}
end

return DevCorridor
