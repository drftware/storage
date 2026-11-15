--!strict
--[[
	DevCorridor: a test hall of real storage units, for trying every door action with a friend
	before the game's floors exist. The server's Host runs it in Studio only, now the lobby's cars
	are the way into a climb (L-08e1b1, D-109): you load in at the lobby, and its "Test hall" post
	brings you here.

	Eight units face each other across an 8-stud hall that runs along X, numbered 101 to 108 (odd
	numbers on one side) and painted in the four door colours; 105 and 108 start padlocked; no wall
	is holed until the saw by the spawn cuts one (L-12b2), then Crawl takes you through (L-12b3). Each door
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Climbs = require(script.Parent.Climbs)
local CorridorKit = require(ReplicatedStorage.Shared.CorridorKit)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Prompts = require(script.Parent.Prompts)
local Floor = require(ReplicatedStorage.Shared.Floor)
local FloorBuilder = require(script.Parent.FloorBuilder)
local FrontOffice = require(script.Parent.FrontOffice)
local HallLight = require(ReplicatedStorage.Shared.HallLight)
local Deals = require(script.Parent.Deals)
local Doors = require(script.Parent.Doors)
local Keepers = require(script.Parent.Keepers)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local MotionLights = require(script.Parent.MotionLights)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Slots = require(script.Parent.Slots)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)
local Wraps = require(script.Parent.Wraps)

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
-- The climb beside the hall (L-01c, L-08b), its first floor's lobby's middle here: far enough off
-- that the hall streams out while you walk it; each floor above is laid further on along -Z
-- (Climbs). Unless Workspace's DevFloorSeed and DevFloorNumber attributes say otherwise, it starts
-- on floor 3 from seed 7, the one `lune run scripts/floor-map 7 3` prints.
local FLOOR_ORIGIN = CFrame.new(0, 0, -600)
local FLOOR_SEED = 7
local FLOOR_NUMBER = 3
-- The test hall's tools (L-11b, L-11c): bolt cutters on the hall floor by the spawn and a pair in
-- the first unit on the right (open its door to find them); a padlock across the spawn from the
-- first pair, to lock any shut door with; a saw between them, to cut a hole between any two
-- units side by side (L-12b2: 106 into 108, say), then crawl through it (L-12b3); a ladder along
-- the hall beyond them (L-13b1), to carry; an air horn standing beside the first cutters (L-14a1),
-- and a roll of bubble wrap on its side beyond the horn (L-14b1).
local TOOLS = {
	{ key = "BoltCutters", at = Vector3.new(-28.5, FLOOR_TOP, 2.2), yaw = 64 },
	{ key = "AirHorn", at = Vector3.new(-26.3, FLOOR_TOP, 2.6), yaw = 160 },
	{ key = "BubbleWrap", at = Vector3.new(-24.2, FLOOR_TOP, 2.9), yaw = 100 },
	{ key = "BoltCutters", at = Vector3.new(-17, 0, 11), yaw = 205 },
	{ key = "Padlock", at = Vector3.new(-28.5, FLOOR_TOP, -2.6), yaw = 200 },
	{ key = "Saw", at = Vector3.new(-25.5, FLOOR_TOP, -0.2), yaw = 100 },
	{ key = "Ladder", at = Vector3.new(-20.5, FLOOR_TOP, 0.6), yaw = 84 },
}
-- Where bubble wrap may be laid in the test hall (L-14b2a), as `Wrap.halls` gives a floor's: the
-- hall from its west dead end through the T's stub, the T's middle, its two arms, the corner's
-- middle and the short east hall.
local TEST_HALLS: { Wrap.Hall } = {
	{ x = 4, z = 0, along = 0, half = 40 },
	{ x = 48, z = 0, along = -1, half = 4 },
	{ x = 48, z = -20, along = 1, half = 16 },
	{ x = 48, z = 24, along = 1, half = 20 },
	{ x = 48, z = 48, along = -1, half = 4 },
	{ x = 68, z = 48, along = 0, half = 16 },
}
local FLOOR_POST = CFrame.new(9, 0, 9) -- "Come back", in the lobby's corner by the elevator
-- "Stand one" (L-06b2a), across the lobby from "Come back": it stands a Mannequin in the hall this
-- far from the lobby along the halls, about two hall pieces past it, so a slam at a door by the
-- lobby is well within its hearing and you watch it come the whole way.
local MANNEQUIN_POST = CFrame.new(-9, 0, 9)
-- "Stand one" for the Packrat (S2-06b2), beside the Mannequin's: it opens the shut unit nearest
-- the lobby as its den, stands one in it facing the back, and lays a boombox in a hall this far
-- (studs) from the lobby, so a tester watches it come out, fetch it, carry it home and lay it.
local PACKRAT_POST = CFrame.new(-9, 0, 3)
local PACKRAT_FIND = 70
local PACKRAT_IN = 4 -- studs into its unit from the door's line
local DEV_PACKRAT = "StandPackrat" -- Workspace's attribute a test sets to press the post
-- the systems the Packrat's post works (set at start)
local devSlots: Slots.Slots? = nil
local devDoors: Doors.Doors? = nil
local devDeals: Deals.Deals? = nil
-- The way between the front office, where you load in (L-08e1b1), and this hall: a post behind the
-- hall's spawn point between the other two, and one in the lobby a stride right of where you land.
local LOBBY_POST = Vector3.new(-34, 0, 0)
local LOBBY_BACK = CFrame.new(-6, 0, -45) -- in the lobby's frame (Lobby.Specs)
local MANNEQUIN_OFF = 60

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

-- A post at `at` whose prompt sends you where `to` says; while it says nowhere, the prompt says
-- so instead. `key` and `pad` give it its own button when another post stands close by.
local function travelPost(
	name: string,
	at: Vector3,
	objectText: string,
	actionText: string,
	to: () -> CFrame?,
	parent: Instance,
	key: Enum.KeyCode?,
	pad: Enum.KeyCode?
): ProximityPrompt
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
	local p = Prompts.post(a, objectText, actionText, key, pad)
	local refuse = Prompts.refuser(p)
	p.Triggered:Connect(function(player: Player)
		local where = to()
		if not where then
			refuse("Still laying it", player)
			return
		end
		send(player, where)
	end)
	return p
end

local function fixed(to: CFrame): () -> CFrame?
	return function(): CFrame?
		return to
	end
end

-- A post in the walked floor's lobby that stands a Mannequin in a hall about two halls off,
-- facing back toward the lobby (L-06b2a): slam a door by the lobby and watch it come, wait, then
-- go back. Each press stands a fresh one in place of the last.
local function mannequinPost(model: Model, origin: CFrame, keepers: Keepers.Keepers)
	local at = (origin * MANNEQUIN_POST).Position
	local post = block(
		"StandMannequin",
		Vector3.new(0.4, 4, 0.4),
		CFrame.new(at.X, FLOOR_TOP + 2, at.Z),
		CONCRETE,
		model
	)
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, 1, 0)
	a.Parent = post
	local p = Prompts.post(a, "Mannequin", "Stand one")
	local refuse = Prompts.refuser(p)
	local stood: Model? = nil
	p.Triggered:Connect(function(player: Player)
		if stood then
			keepers:remove(stood)
			stood = nil
		end
		local spot, facing = keepers:hallOff(model, MANNEQUIN_OFF)
		stood = if spot and facing then keepers:stand("Mannequin", model, spot, facing) else nil
		if not stood then
			refuse("No Mannequin", player) -- Output says why
			return
		end
		print(
			`DevCorridor: a Mannequin stands in the hall {MANNEQUIN_OFF} studs from the lobby, facing it; slam a door by the lobby and watch it come`
		)
	end)
end

-- The Packrat's post (S2-06b2): see PACKRAT_POST. Each press stands a fresh one in a fresh den.
local function packratPost(on: Climbs.OnFloor, keepers: Keepers.Keepers)
	local model, origin = on.model, on.origin
	local at = (origin * PACKRAT_POST).Position
	local post = block(
		"StandPackrat",
		Vector3.new(0.4, 4, 0.4),
		CFrame.new(at.X, FLOOR_TOP + 2, at.Z),
		CONCRETE,
		model
	)
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, 1, 0)
	a.Parent = post
	local p = Prompts.post(a, "Packrat", "Stand one", Enum.KeyCode.R, Enum.KeyCode.ButtonY)
	local refuse = Prompts.refuser(p)
	local stood: Model? = nil
	local function standOne(player: Player?)
		local doors, deals, slots = devDoors, devDeals, devSlots
		if not (doors and deals and slots) then
			return
		end
		if stood then
			keepers:remove(stood)
			stood = nil
		end
		local den: Model?, best = nil, math.huge
		for unit in on.laid.slots do
			if doors:stateOf(unit) == "Closed" then
				local d = (RollUpDoor.frame(unit).Position - origin.Position).Magnitude
				if d < best then
					den, best = unit, d
				end
			end
		end
		local spot, facing = keepers:hallOff(model, PACKRAT_FIND)
		if not (den and spot and facing) then
			if player then
				refuse("No den", player)
			end
			return
		end
		local frame = RollUpDoor.frame(den)
		local inside = (frame * CFrame.new(0, 0, PACKRAT_IN)).Position
		local feet = Vector3.new(inside.X, origin.Position.Y, inside.Z)
		deals:hold(den) -- its own unit holds nothing the deal lays: only what it brings home
		stood = keepers:stand("Packrat", model, feet, -frame.LookVector, true)
		if not stood then
			if player then
				refuse("No Packrat", player) -- Output says why
			end
			return
		end
		doors:move(den, "Open")
		slots:lay("Boombox", spot, math.random(0, 359))
		print(
			`DevCorridor: a Packrat stands in {den.Name}, its door going up; a boombox lies in the hall {PACKRAT_FIND} studs from the lobby. Watch it fetch it home`
		)
	end
	p.Triggered:Connect(standOne)
	-- a test stands one with no one at the post: set this Workspace attribute true (Studio only)
	if RunService:IsStudio() then
		local watching = Workspace:GetAttributeChangedSignal(DEV_PACKRAT):Connect(function()
			if Workspace:GetAttribute(DEV_PACKRAT) == true then
				Workspace:SetAttribute(DEV_PACKRAT, false)
				standOne(nil)
			end
		end)
		model.Destroying:Connect(function()
			watching:Disconnect()
		end)
	end
end

-- What a tester needs on each floor the climb lays (L-08b): "Come back" and "Stand one" in its
-- lobby, and in Output its map, how laying it went, its code and where its notes are (which is
-- guarded: always an awake keeper with it, D-072), and the doors the deal padlocked, so a tester
-- can walk straight to them.
local function dressFloor(on: Climbs.OnFloor, keepers: Keepers.Keepers)
	local floor, deck, laid, n = on.floor, on.deck, on.laid, on.number
	travelPost(
		"ComeBack",
		(on.origin * FLOOR_POST).Position,
		`Floor {n}`,
		"Come back",
		fixed(SPAWN),
		on.model
	)
	mannequinPost(on.model, on.origin, keepers)
	packratPost(on, keepers)
	print(
		`DevCorridor: floor {n} (seed {on.seed}), seen from above, the lobby (L) at the bottom:\n{Floor.map(
			floor
		)}`
	)
	local work = string.format("%.0f ms", laid.working * 1000)
	local most = string.format("%.1f ms", laid.longest * 1000)
	local took = string.format("%.2f s", laid.seconds)
	print(
		`DevCorridor: floor {n} laid, {laid.units} units on {laid.pieces} hall pieces: {work} of work over {laid.frames} frames, at most {most} in one ({took} in all)`
	)
	local where = {}
	for _, note in deck.notes do
		local guarded = if note.slot == deck.guarded then ", guarded" else ""
		local marked = if note.slot == deck.marked then ", marked" else ""
		table.insert(
			where,
			`Unit{floor.slots[note.slot].number} ({Deal.noteText(deck, note)}{guarded}{marked})`
		)
	end
	print(
		`DevCorridor: floor {n}'s code is {table.concat(deck.code)}; its notes: {table.concat(
			where,
			", "
		)}`
	)
	local locked = {}
	for i in deck.padlocked do
		table.insert(locked, `Unit{floor.slots[i].number}`)
	end
	table.sort(locked)
	print(`DevCorridor: floor {n}'s padlocked doors: {table.concat(locked, ", ")}`)
end

-- Starts the climb beside the hall (L-01c, L-08b) and opens the way there: "Walk a floor" by the
-- spawn takes you to the lobby of the floor it's on, each floor is dressed for testing as it's
-- laid (`dressFloor`), and the car carries you up from floor to floor. Workspace's DevFloorSeed and
-- DevFloorNumber attributes pick the seed and the floor it starts on. Yields while it lays.
local function devFloor(folder: Folder, climbs: Climbs.Climbs, keepers: Keepers.Keepers)
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
	local walk = travelPost(
		"WalkFloor",
		Vector3.new(-34, 0, -3),
		`Floor {n}`,
		"Walk a floor",
		function(): CFrame?
			local on = climbs:current()
			return if on then on.origin * Climbs.Arrival else nil
		end,
		folder
	)
	local function named(on: Climbs.OnFloor)
		walk.ObjectText = `Floor {on.number}`
	end
	local dressing = climbs.laid:connect(function(on: Climbs.OnFloor)
		dressFloor(on, keepers)
	end)
	local moving = climbs.handedOff:connect(function(h: Climbs.HandOff)
		named(h.to)
		print(
			`DevCorridor: {#h.riders} rode up to floor {h.to.number}, moved into its car {string.format(
				"%.2f",
				h.since
			)} s into the ride`
		)
	end)
	folder.Destroying:Once(function()
		dressing:disconnect()
		moving:disconnect()
	end)
	climbs:begin({
		seed = s,
		number = n,
		origin = FLOOR_ORIGIN,
		parent = folder,
	})
	print(`DevCorridor: "Walk a floor" is by the spawn`)
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
	-- the tops you can crawl along once up a ladder (L-13b2c)
	FloorBuilder.unitTops(folder)

	travelPost("GoFar", Vector3.new(-34, 0, 3), "Streaming test", "Go far", fixed(FAR_SPOT), folder)
	travelPost(
		"ComeBack",
		Vector3.new(FAR_X + 8, 0, 3),
		"Streaming test",
		"Come back",
		fixed(SPAWN),
		folder
	)

	-- everyone loads in at the lobby (FrontOffice), whose post brings you here
	folder.Parent = Workspace
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
			-- any: as above; Slots fills this slot
			local slots = (context.registry:get("slots") :: any) :: Slots.Slots
			-- any: as above; Keepers fills this slot
			local keepers = (context.registry:get("keepers") :: any) :: Keepers.Keepers
			-- any: as above; Wraps fills this slot
			local wraps = (context.registry:get("wraps") :: any) :: Wraps.Wraps
			-- any: as above; Climbs fills this slot
			local climbs = (context.registry:get("climbs") :: any) :: Climbs.Climbs
			devSlots = slots
			-- any: as above; Doors and Deals fill these slots
			devDoors = (context.registry:get("doors") :: any) :: Doors.Doors
			devDeals = (context.registry:get("deals") :: any) :: Deals.Deals
			local folder = build(lights)
			built = folder
			if folder then
				-- tools to try the slots and the doors with (L-11b, L-11c)
				for _, spot in TOOLS do
					slots:lay(spot.key, spot.at, spot.yaw)
				end
				wraps:add(TEST_HALLS, folder, CFrame.identity)
				laying = task.spawn(devFloor, folder, climbs, keepers)
				-- any: as above; FrontOffice fills this slot, and starts before this system
				local office = (
					context.registry:get("frontOffice") :: any
				) :: FrontOffice.FrontOffice
				local lobby = office:laid()
				if lobby then
					local pivot = lobby.pivot
					travelPost(
						"GoLobby",
						LOBBY_POST,
						"Lobby",
						"Go to the lobby",
						fixed(Lobby.spawn(pivot)),
						folder,
						-- its own button: "Walk a floor" and "Go far" stand 3 studs either side on E
						Enum.KeyCode.R,
						Enum.KeyCode.ButtonY
					)
					travelPost(
						"LobbyBack",
						(pivot * LOBBY_BACK).Position,
						"Test hall",
						"Come back",
						fixed(SPAWN),
						folder
					)
				end
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
