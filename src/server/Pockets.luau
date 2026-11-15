--!strict
--[[
	Pockets: the code's notes players carry (B-04a, B-04b; D-213, D-214), a system.

	The moment: you pull the note out of its box and it's yours to read; you run it to the car,
	where friends are piecing the code together, and it goes up on the wall beside the keypad for
	anyone there to read. Caught (or gone) holding one, it tumbles out where you were, for a friend
	to fetch.

	- `give`: a note goes into a player's pocket (the box's reveal brought it, or they took one off
	  the floor). The server keeps each player's notes and mirrors them on the player
	  (`NoteCard.Held`), so their screen shows a paper for each at its left edge (NoteView). A note
	  leaves the pocket with its floor (the climb moves on).
	- Walk up to a floor's keypad holding notes (`NoteCard.PinReach` of its face) and they go up:
	  each a copy of the note on the lobby wall beside it (`NoteCard.pinAt`, one after another in a
	  row), parented with the elevator so it goes with its floor. Tagged `CodeNote`, so NoteView
	  gives each its Read button. Every screen near flies it there from the hand and taps it in
	  (NotePlaces).
	- `drop`: caught (`Keepers.caught`) or leaving, every note you hold tumbles out where you were,
	  to lie flat on the floor under you (`NoteCard.scatter` spreads more than one), with a Take
	  button (`Prompts.make`): a tap puts it in that player's pocket, and their screen holds it up.
	  Take is checked on the server as every press is (not caught, alive, within reach, no faster
	  than `NoteCard.TakeSeconds`). A dropped note has no Read button (NoteView): Take reads it.
	- A note whose holder is gone before it reached them (the box's reveal outlived them) goes back
	  on its unit's back wall (FloorBuilder.stickNote), so the code is never lost.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Floor = require(ReplicatedStorage.Shared.Floor)
local FloorBuilder = require(script.Parent.FloorBuilder)
local NoteCard = require(ReplicatedStorage.Shared.Elevator.NoteCard)
local Prompts = require(script.Parent.Prompts)

-- The code's note: its writing ("_ 7 _ _"), and its unit's size and number, so it can go back
-- on the unit's back wall if it can't reach anyone.
export type Note = { text: string, size: Floor.Size, number: string }

export type Pockets = Brix.System & {
	-- Puts `note`, out of `unit`, in `player`'s pocket (or back on its wall if they've gone).
	give: (self: any, player: Player, note: Note, unit: Model) -> (),
	-- Every note `player` holds tumbles out at `at` (where they stood) onto the floor below.
	drop: (self: any, player: Player, at: Vector3) -> (),
	-- Every note `player` holds goes up on the wall beside `elevator`'s keypad.
	pin: (self: any, player: Player, elevator: Model) -> (),
}

-- What this needs of Keepers: its catches (`Keepers.caught`). Named here, not required: Keepers
-- requires Deals, which requires MarkedBoxes, which requires this.
type Catches = { caught: Brix.Signal<{ player: Player }> }

-- A note in a pocket, the unit it came out of, and the hook that takes it when its floor goes.
type Held = { note: Note, unit: Model, gone: RBXScriptConnection }

-- How often the walk to a keypad is checked, for players holding notes (seconds).
local CHECK_EVERY = 0.15
-- A dropped note is looked for under you this far down, from your middle (studs).
local FLOOR_BELOW = 12
-- Where the paper leaves your hand: this far over your middle.
local HAND_UP = 0.8
-- A note spread from where you stood stops this short of a wall in its way (studs).
local WALL_GAP = 0.45
-- Your middle is on the lobby's side of the elevator's opening while it's under this, in the
-- elevator's frame (the car starts at `Specs.Car.Front`, 0.62 in).
local LOBBY_SIDE = 0.3

local Pockets = {}

function Pockets.new(): Pockets
	local pockets: { [Player]: { Held } } = {}
	local lastAt: { [Player]: Vector3 } = {}
	local takes: { [Player]: number } = {}
	local pinned: { [Model]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local signals: { Brix.SignalConnection } = {}
	local elevators: { [Model]: true } = {}
	local since = 0
	local stopped = false
	local system = { name = "Pockets" } :: Pockets

	local function rootOf(player: Player): BasePart?
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root else nil
	end

	-- Mirrors what `player` holds onto them, for their screen (NoteView).
	local function mirror(player: Player)
		local texts: { string } = {}
		local list = pockets[player]
		if list then
			for _, h in list do
				table.insert(texts, h.note.text)
			end
		end
		if player.Parent then
			player:SetAttribute(NoteCard.Held, if #texts > 0 then NoteCard.pocket(texts) else nil)
		end
	end

	-- Takes everything out of `player`'s pocket, in the order taken.
	local function empty(player: Player): { Held }
		local list = pockets[player]
		pockets[player] = nil
		lastAt[player] = nil
		if not list then
			return {}
		end
		for _, h in list do
			h.gone:Disconnect()
		end
		mirror(player)
		return list
	end

	-- A note goes back on its unit's back wall: nobody can carry it.
	local function putBack(note: Note, unit: Model)
		if unit:IsDescendantOf(Workspace) then
			FloorBuilder.stickNote(unit, note.size, note.number, note.text)
		end
	end

	-- Stamps a placed note so every screen near plays its way there once (NotePlaces).
	local function stamp(m: Model, how: string, from: Vector3)
		m:SetAttribute(NoteCard.Placed, how)
		m:SetAttribute(NoteCard.PlacedAt, Workspace:GetServerTimeNow())
		m:SetAttribute(NoteCard.PlacedFrom, from)
	end

	-- What a dropped note's way is checked against: everything solid but everyone's bodies.
	local function solid(): RaycastParams
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local bodies: { Instance } = {}
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(bodies, p.Character)
			end
		end
		params.FilterDescendantsInstances = bodies
		params.RespectCanCollide = true
		return params
	end

	-- Where a note spread `by` from `at` comes to rest: short of any wall in its way, on the floor
	-- (or whatever stands) under it.
	local function restOf(at: Vector3, by: Vector3, params: RaycastParams): Vector3
		local wall = if by.Magnitude > 0 then Workspace:Raycast(at, by, params) else nil
		local over = if wall then at + by.Unit * math.max(0, wall.Distance - WALL_GAP) else at + by
		local hit = Workspace:Raycast(over, Vector3.new(0, -FLOOR_BELOW, 0), params)
		return if hit then hit.Position else over - Vector3.new(0, 3, 0)
	end

	local function give(player: Player, note: Note, unit: Model)
		if stopped then
			return
		end
		if not player.Parent then
			putBack(note, unit)
			return
		end
		local list = pockets[player] or {}
		pockets[player] = list
		local h: Held
		-- the floor it came from goes (the climb moves on): it leaves the pocket with it
		local gone = unit.AncestryChanged:Connect(function()
			if unit:IsDescendantOf(game) then
				return
			end
			h.gone:Disconnect()
			local now = pockets[player]
			local at = if now then table.find(now, h) else nil
			if now and at then
				table.remove(now, at)
				if #now == 0 then
					pockets[player] = nil
				end
				mirror(player)
			end
		end)
		h = { note = note, unit = unit, gone = gone }
		table.insert(list, h)
		local root = rootOf(player)
		if root then
			lastAt[player] = root.Position
		end
		mirror(player)
	end

	-- A dropped note: flat on the floor at `rest`, its Take button over it.
	local function lay(note: Note, unit: Model, rest: CFrame, from: Vector3)
		local m = Elevator.note(rest, unit.Parent or Workspace, note.text)
		if not m then
			putBack(note, unit)
			return
		end
		stamp(m, "Dropped", from)
		local paper = m:FindFirstChild("Paper")
		if not (paper and paper:IsA("BasePart")) then
			return
		end
		local at = Instance.new("Attachment")
		at.Name = "TakePrompt"
		at.Parent = paper
		at.WorldCFrame = CFrame.new(rest.Position + Vector3.new(0, NoteCard.TakeUp, 0))
		local prompt = Prompts.make(at, {
			actionText = "Take",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = NoteCard.TakeReach,
		})
		local done = false
		prompt.Triggered:Connect(function(player: Player)
			if done or stopped or Prompts.wrapped(player) then
				return
			end
			local root = rootOf(player)
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not (root and humanoid and humanoid.Health > 0) then
				return
			end
			-- the prompt's reach, plus a step for the client being ahead of the server
			if (root.Position - rest.Position).Magnitude > NoteCard.TakeReach + 2 then
				return
			end
			local now = os.clock()
			local last = takes[player]
			if last and now - last < NoteCard.TakeSeconds then
				return
			end
			local list = pockets[player]
			if list and #list >= NoteCard.Pocket then
				return
			end
			takes[player] = now
			done = true
			m:Destroy()
			if unit:IsDescendantOf(game) then
				give(player, note, unit)
			end
		end)
	end

	local function drop(player: Player, at: Vector3)
		local list = empty(player)
		if #list == 0 then
			return
		end
		local from = at + Vector3.new(0, HAND_UP, 0)
		local params = solid()
		for i, h in list do
			local dx, dz = NoteCard.scatter(i, #list)
			local ground = restOf(at, Vector3.new(dx, 0, dz), params)
			-- flat on its back, face up, turned whichever way it fell
			local turn = math.rad((i * 137 + math.floor(at.X * 13)) % 360)
			local rest = CFrame.new(ground + Vector3.new(0, 0.01, 0))
				* CFrame.Angles(0, turn, 0)
				* CFrame.Angles(math.pi / 2, 0, 0)
			lay(h.note, h.unit, rest, from)
		end
	end

	local function pin(player: Player, elevator: Model)
		local list = empty(player)
		if #list == 0 then
			return
		end
		local root = rootOf(player)
		local from = if root
			then root.Position + Vector3.new(0, HAND_UP, 0)
			else Elevator.keypadPoint(elevator)
		local frame = elevator:GetPivot()
		for _, h in list do
			local count = (pinned[elevator] or 0) + 1
			pinned[elevator] = count
			local x, y, crook = NoteCard.pinAt(count)
			-- the lobby is the elevator's LookVector, so a note facing it reads from the keypad
			local pivot = frame
				* CFrame.new(x, y, -NoteCard.PinOut)
				* CFrame.Angles(0, 0, math.rad(crook))
			local m = Elevator.note(pivot, elevator.Parent or Workspace, h.note.text)
			if m then
				stamp(m, "Pinned", from)
			else
				putBack(h.note, h.unit)
			end
		end
	end

	-- Leaving: your notes drop where you were (or, never seen standing, back on their walls).
	local function leave(player: Player)
		takes[player] = nil
		local root = rootOf(player)
		local at = if root then root.Position else lastAt[player]
		if at and not Prompts.wrapped(player) then
			drop(player, at)
		else
			for _, h in empty(player) do
				putBack(h.note, h.unit)
			end
		end
	end

	-- Anyone holding notes within reach of a floor's keypad pins them up.
	local function check()
		for player, _ in pockets do
			local root = rootOf(player)
			if not root or Prompts.wrapped(player) then
				continue
			end
			local p = root.Position
			lastAt[player] = p
			for elevator in elevators do
				-- the lobby's side only (its LookVector, -Z): never from inside the car as it rides
				local lobbySide = elevator:GetPivot():PointToObjectSpace(p).Z < LOBBY_SIDE
				if
					lobbySide
					and (Elevator.keypadPoint(elevator) - p).Magnitude <= NoteCard.PinReach
				then
					pin(player, elevator)
					break
				end
			end
		end
	end

	local function track(inst: Instance)
		if inst:IsA("Model") and inst:IsDescendantOf(Workspace) then
			elevators[inst] = true
		end
	end

	function system.give(_: any, player: Player, note: Note, unit: Model)
		give(player, note, unit)
	end

	function system.drop(_: any, player: Player, at: Vector3)
		drop(player, at)
	end

	function system.pin(_: any, player: Player, elevator: Model)
		pin(player, elevator)
	end

	function system.start(_: any, context: Brix.Context)
		local keepers = (context.registry:get("keepers") :: any) :: Catches? -- any: the registry is untyped
		if keepers then
			table.insert(
				signals,
				keepers.caught:connect(function(catch: { player: Player })
					local root = rootOf(catch.player)
					if root then
						drop(catch.player, root.Position)
					end
				end)
			)
		end
		table.insert(connections, Players.PlayerRemoving:Connect(leave))
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(track)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Elevator.Tag)
				:Connect(function(inst: Instance)
					if inst:IsA("Model") then
						elevators[inst] = nil
						pinned[inst] = nil
					end
				end)
		)
		for _, inst in CollectionService:GetTagged(Elevator.Tag) do
			track(inst)
		end
	end

	function system.step(_: any, dt: number)
		if next(pockets) == nil then
			return
		end
		since += dt
		if since < CHECK_EVERY then
			return
		end
		since = 0
		check()
	end

	function system.stop(_: any)
		stopped = true
		for _, c in signals do
			c:disconnect()
		end
		table.clear(signals)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for player in pockets do
			for _, h in pockets[player] do
				h.gone:Disconnect()
			end
		end
		table.clear(pockets)
		table.clear(lastAt)
		table.clear(takes)
		table.clear(pinned)
		table.clear(elevators)
	end

	return system
end

return Pockets
