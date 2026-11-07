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

	The hall's floor and ceiling are three of the corridor kit's straight pieces (P0-03a), with
	plain walls past the last units, and its lights are the kit's fixtures (P0-03b), each midway
	between two joists; without the kit's templates in the place it falls back to plain blocks and
	bare tubes. The kit's dead end replaces the end walls here (P0-03c).
	The prompts call RollUpDoor directly; the GDD's door state machine replaces them (L-02).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CorridorKit = require(ReplicatedStorage.Shared.CorridorKit)
local HallLight = require(ReplicatedStorage.Shared.HallLight)
local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

-- The layout, in studs. The hall runs along X; doors face each other across Z.
local HALL_HALF_WIDTH = 4 -- an 8-stud hall: door faces at z = -4 and z = +4
local UNIT_XS = { -18, -6, 6, 18 } -- four 12-stud units a side, wall to wall
local UNITS_HALF_LENGTH = 24 -- the last units' outer walls
local BUILDING_HALF_LENGTH = 36 -- three 24-stud kit pieces; end walls at x = -36 and 36
local BUILDING_HALF_DEPTH = 17 -- without the kit: side walls just behind the units' backs
local CEILING = 13.4 -- without the kit: a plain ceiling, as in the look sheets
local BAY_WALL = 0.5 -- the plain walls along the hall past the last units
local FLOOR_TOP = -0.05 -- just under the units' own floors (top at 0), so the two never flicker
local FAR_X = 700 -- far past the streaming target radius (256), so the hall streams out

-- The prompts.
-- In first person a prompt shows only while its point is on screen, so the points sit on the door
-- at about eye height: pressed against the door with a level gaze, they still show.
-- A point inside the door's invisible collider loses its sight line and hides, so both sit just
-- outside it (RollUpDoor.ColliderDepth).
local PROMPT_OUT = RollUpDoor.ColliderDepth / 2 + 0.1 -- the door's prompts hang just outside the collider, hall side
local PROMPT_HEIGHT = 4 -- just under a standing player's eyes (about 4.4)
local PROMPT_REACH = 8 -- close enough to touch the door, not the neighbour's
local LIFT_IN = RollUpDoor.ColliderDepth / 2 + 0.1 -- Lift hangs just behind the collider, so the shut door hides it from the hall
local LIFT_REACH = 5 -- only someone shut inside should see Lift
local REFUSAL_SECONDS = 1.2 -- how long "Padlocked" or "Shut it first" shows before the unit's name returns

-- The hall's fixtures, one every 24 studs, laid out like the look sheets' hall (HallLight): one lit
-- over 105 and 106 whose eye has seen you, a weaker one over 101 and 102 by the spawn, and a dead
-- one past the last units with its eye open, with the exit sign's red at the far end. Each sits
-- midway between two of the kit's joists (6 studs off a piece's middle).
type Fixture = { x: number, level: number, eye: HallLight.EyeState }
local HALL_FIXTURES: { Fixture } = {
	{ x = -18, level = HallLight.Low, eye = "Watching" },
	{ x = 6, level = 1, eye = "Seen" },
	{ x = 30, level = 0, eye = "Watching" },
}
local EXIT_SIGN_SIZE = Vector3.new(0.2, 0.7, 1.8)
local EXIT_SIGN_HEIGHT = 9.95 -- over the stairwell door's frame, as in the sheets

local CONCRETE = Color3.fromRGB(74, 74, 76)
-- Light concrete, like the sheets' floor, so a fixture's pool reads on it, where the kit isn't.
local FLOOR_COLOUR = Color3.fromRGB(120, 120, 118)
local CEILING_COLOUR = Color3.fromRGB(38, 38, 40)
local SPAWN = CFrame.lookAt(Vector3.new(-32, 3, 0), Vector3.new(0, 3, 0))
local FAR_SPOT = CFrame.lookAt(Vector3.new(FAR_X + 6, 3, 0), Vector3.new(FAR_X, 3, -4))

local DOOR_COLOURS = {
	UnitKit.Colours.Door.Oxblood,
	UnitKit.Colours.Door.Teal,
	UnitKit.Colours.Door.Mustard,
	UnitKit.Colours.Door.Navy,
}
local PADLOCKED = { ["105"] = true, ["108"] = true }

type Action = { kind: Motion.Kind, text: string, key: Enum.KeyCode, pad: Enum.KeyCode }
local OUTSIDE_ACTIONS: { Action } = {
	{ kind = "Peek", text = "Peek", key = Enum.KeyCode.Q, pad = Enum.KeyCode.ButtonL1 },
	{ kind = "Open", text = "Open", key = Enum.KeyCode.E, pad = Enum.KeyCode.ButtonX },
	{ kind = "Close", text = "Close", key = Enum.KeyCode.F, pad = Enum.KeyCode.ButtonB },
	{ kind = "Slam", text = "Slam", key = Enum.KeyCode.G, pad = Enum.KeyCode.ButtonY },
}
local LIFT_ACTION: Action =
	{ kind = "LiftInside", text = "Lift", key = Enum.KeyCode.T, pad = Enum.KeyCode.ButtonX }
local LIFTS: { [Motion.Kind]: true } = { Peek = true, Open = true, LiftInside = true }

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

-- A hall light at f.x: the kit's fixture in a kit hall, or a bare tube where its lens would hang.
local function fixture(f: Fixture, kit: boolean, parent: Instance)
	if kit and CorridorKit.template("Fixture") then
		local hung = CorridorKit.hang(CFrame.new(f.x, 0, 0), parent)
		HallLight.light(hung.diffuser, f.level)
		HallLight.eye(hung.eye, f.eye)
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
	HallLight.light(tube, f.level)
end

-- A closed box around a stretch of hall: floor, ceiling, end walls and side walls. With `kit`,
-- the floor and ceiling are the corridor kit's straight pieces, the walls rise to their deck, and
-- plain walls line the hall past the last units, where no unit closes its side.
local function building(
	name: string,
	centreX: number,
	halfLength: number,
	fixtures: { Fixture },
	kit: boolean,
	parent: Instance
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
		for _, side in { -1, 1 } do
			for _, toEnd in { -1, 1 } do
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
	for _, side in { -1, 1 } do
		local endX = centreX + side * (halfLength + 0.5)
		local wallZ = side * (depth / 2 + 0.5)
		block(
			"EndWall",
			Vector3.new(1, height, depth),
			CFrame.new(endX, FLOOR_TOP + height / 2, 0),
			CONCRETE,
			folder
		)
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

-- Where a door's outer face goes: at x on one side of the hall, looking across it.
local function doorFace(x: number, side: number): CFrame
	local at = Vector3.new(x, 0, side * HALL_HALF_WIDTH)
	return CFrame.lookAt(at, at - Vector3.zAxis * side)
end

local function specOf(unit: Model): Specs.Spec
	local size = unit:GetAttribute("UnitSize")
	return Specs[if type(size) == "string" then size else "M"]
end

local function prompt(
	at: Attachment,
	objectText: string,
	action: Action,
	reach: number
): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ObjectText = objectText
	p.ActionText = action.text
	p.KeyboardKeyCode = action.key
	p.GamepadKeyCode = action.pad
	p.HoldDuration = 0
	p.MaxActivationDistance = reach
	p.RequiresLineOfSight = true
	p.Parent = at
	return p
end

-- Shows `text` on the prompt for a moment in place of the unit's name. A newer refusal wins.
local function refuser(p: ProximityPrompt, objectText: string): (text: string) -> ()
	local shown = 0
	return function(text: string)
		shown += 1
		local mine = shown
		p.ObjectText = text
		task.delay(REFUSAL_SECONDS, function()
			if shown == mine and p.Parent then
				p.ObjectText = objectText
			end
		end)
	end
end

-- An attachment at a world frame, on the unit's own part, so its prompts stream with the unit.
local function pointOn(unit: Model, at: CFrame): Attachment
	local a = Instance.new("Attachment")
	a.Parent = unit.PrimaryPart
	a.WorldCFrame = at
	return a
end

local function addDoorPrompts(unit: Model, number: string)
	local frame = RollUpDoor.frame(unit)
	local objectText = `Unit {number}`

	local function act(kind: Motion.Kind, refuse: (string) -> ())
		if LIFTS[kind] and unit:GetAttribute("DoorLocked") == true then
			refuse("Padlocked")
			return
		end
		RollUpDoor.play(unit, kind)
	end

	local outside = pointOn(unit, frame * CFrame.new(0, PROMPT_HEIGHT, -PROMPT_OUT))
	for _, action in OUTSIDE_ACTIONS do
		local p = prompt(outside, objectText, action, PROMPT_REACH)
		local refuse = refuser(p, objectText)
		p.Triggered:Connect(function()
			act(action.kind, refuse)
		end)
	end

	local lock = prompt(
		outside,
		objectText,
		{ kind = "Close", text = "Lock", key = Enum.KeyCode.R, pad = Enum.KeyCode.ButtonR1 },
		PROMPT_REACH
	)
	local refuseLock = refuser(lock, objectText)
	local function showLock()
		lock.ActionText = if unit:GetAttribute("DoorLocked") == true then "Unlock" else "Lock"
	end
	showLock()
	unit:GetAttributeChangedSignal("DoorLocked"):Connect(showLock)
	lock.Triggered:Connect(function()
		local locked = unit:GetAttribute("DoorLocked") == true
		if not RollUpDoor.setLocked(unit, not locked) then
			refuseLock("Shut it first")
		end
	end)

	local inside = pointOn(unit, frame * CFrame.new(0, PROMPT_HEIGHT, LIFT_IN))
	local lift = prompt(inside, objectText, LIFT_ACTION, LIFT_REACH)
	local refuseLift = refuser(lift, objectText)
	lift.Triggered:Connect(function()
		act("LiftInside", refuseLift)
	end)
end

-- A clone of the template with its door's outer face at `face`, painted, numbered and with its
-- prompts, ready to parent. Units are dressed before they reach Workspace: clients cache the door's
-- frame and colours when a unit arrives.
local function placeUnit(template: Model, face: CFrame, number: string, colour: Color3): Model
	local unit = template:Clone()
	local outer = RollUpDoor.frame(unit) * CFrame.new(0, 0, -specOf(unit).CurtainPlane)
	unit:PivotTo(face * outer:ToObjectSpace(unit:GetPivot()))
	unit.Name = `Unit{number}`
	UnitKit.paint(unit, colour, UnitKit.Colours.Wall)
	UnitKit.number(unit, number)
	RollUpDoor.fitCollider(unit)
	addDoorPrompts(unit, number)
	return unit
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

local function travelPost(
	name: string,
	at: Vector3,
	actionText: string,
	to: CFrame,
	parent: Instance
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
	local p = prompt(
		a,
		"Streaming test",
		{ kind = "Close", text = actionText, key = Enum.KeyCode.E, pad = Enum.KeyCode.ButtonX },
		PROMPT_REACH
	)
	p.Triggered:Connect(function(player: Player)
		send(player, to)
	end)
end

-- Builds the whole corridor into one folder and parents it once. Returns nil, after a warning,
-- when the place has no unit template yet.
local function build(): Folder?
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
	if kit and not CorridorKit.template("Fixture") then
		warn(
			'DevCorridor: no fixture at ReplicatedStorage.Corridor.Fixture, so the hall lights are bare tubes; import it (art/corridor/README.md, "Into Studio")'
		)
	end

	local folder = Instance.new("Folder")
	folder.Name = "DevCorridor"
	local hall = building("Hall", 0, BUILDING_HALF_LENGTH, HALL_FIXTURES, kit, folder)
	local sign = block(
		"ExitSign",
		EXIT_SIGN_SIZE,
		CFrame.new(BUILDING_HALF_LENGTH - EXIT_SIGN_SIZE.X / 2, EXIT_SIGN_HEIGHT, 0),
		HallLight.ExitColour,
		hall
	)
	sign.CanCollide = false
	HallLight.exitSign(sign)
	building("FarHall", FAR_X, 12, { { x = FAR_X, level = 1, eye = "Watching" } }, false, folder)

	local count = 0
	for row, side in { -1, 1 } do
		for i, x in UNIT_XS do
			local number = tostring(100 + (i - 1) * 2 + row)
			count += 1
			local unit =
				placeUnit(template, doorFace(x, side), number, DOOR_COLOURS[(count - 1) % 4 + 1])
			if i > 1 then
				dropSharedWall(unit)
			end
			if PADLOCKED[number] then
				RollUpDoor.setLocked(unit, true)
			end
			unit.Parent = folder
		end
	end
	placeUnit(template, doorFace(FAR_X, -1), "901", UnitKit.Colours.Door.Teal).Parent = folder

	travelPost("GoFar", Vector3.new(-34, 0, 3), "Go far", FAR_SPOT, folder)
	travelPost("ComeBack", Vector3.new(FAR_X + 8, 0, 3), "Come back", SPAWN, folder)

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
	return {
		name = "DevCorridor",
		start = function(_: any, _context: Brix.Context)
			built = build()
		end,
		stop = function(_: any)
			if built then
				built:Destroy()
				built = nil
			end
		end,
	}
end

return DevCorridor
