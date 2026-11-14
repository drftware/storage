--!strict
--[[
	Elevators: every freight elevator laid in the world, its keypad and its gate (GDD "Codes, the
	elevator and the roof"), a system on the server's Host clock. Whoever lays a floor arms its
	elevator with the floor's code (`arm`), and from then on:

	- Anyone at the keypad punches digits through the `Keypad` remote. Brix's typed remotes
	  (ENG-09) aren't built yet, so this is the smallest stand-in, its checks in the order ENG-09
	  makes them: the payload's types (an elevator of ours, a key the keypad has), then its range
	  (the player within reach of the keypad), then the rate (no faster than a thumb), and only
	  then the keypad's own state (dead while the alarm rings, done once the gate is open).
	- The fourth digit is checked, as a real keypad does. Wrong: the alarm rings, every light on the
	  floor comes on (MotionLights.flash), and the keypad is dead for a moment, its readout blinking
	  the wrong digits, then it clears. Right: the chime, the latch, and the gate folds open.
	- Once it has slammed open the gate's clock runs (L-05b2, Departure): 30 s on every screen on
	  the floor, then the gate folds shut on its own, and the instant it hits its post a Zone over
	  the car says who rode (`Departure.AboardAttribute`, `departed`). Nobody can send it early.
	- Then the ride (L-08a, Ride): the car climbs one floor on the server's clock, one value
	  (`Ride.Attribute`) every rider's screen draws it from, and as it levels the gate folds open
	  on the next hall (`arrived`). The climb (Climbs, L-08b) hands the ride mid-way to the next
	  floor's car (`takeOver`): that car arrives and opens on the new floor, the one that left
	  never does. With no next floor the car arrives back at its own lobby, its number one
	  higher. Whoever runs the climb arms the car again (`arm`).
	- The gate's motion is one replicated value (`Gate.Attribute`) that every screen folds the gate
	  from (ElevatorView); here only its collider follows, so the gap you see is the gap there is.
	- Every keypad sound fires `acted` with how far it's heard, as Doors does, so keepers (L-06b)
	  hear each beep and come running at the alarm.
	- The lobby's cars (L-08e1b1, LobbyCars) are the same elevators with no code: `lobby` stands one
	  open in its bay, its keypad asleep, and `count` runs its clock from the first step in. At
	  zero its gate shuts and it leaves exactly as a floor's car does; who rides is the group's
	  pick of those inside, and nobody is left behind by it.

	The code never leaves the server. Only gates in motion, dead keypads and running clocks are
	stepped.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Gate = require(ReplicatedStorage.Shared.Elevator.Gate)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local MotionLights = require(script.Parent.MotionLights)

export type Action = "Press" | "Clear" | "Wrong" | "Right"

export type KeypadEvent = {
	elevator: Model,
	action: Action,
	player: Player?, -- nil when the game itself did it
	at: Vector3, -- the keypad's face
	reach: number, -- studs it's heard to (Keypad.Heard): a keeper within it hears it
}

-- The car leaving a floor: who rode, and who was on the floor (within the clock's reach) and
-- didn't.
export type Leaving = {
	elevator: Model,
	floor: Instance?,
	aboard: { Player },
	left: { Player },
	at: number, -- server time the gate hit its post
}

-- The car levelling with the next floor: who rode, and the floors from and to. Its gate folds
-- open `Ride.Open` seconds later.
export type Arrival = {
	elevator: Model,
	riders: { Player },
	from: number,
	to: number,
	at: number, -- server time it levelled
}

-- Who of those inside a lobby car rides as its gate hits its post (LobbyCars, Boarding.riders).
export type Pick = (inside: { Player }) -> { Player }

export type Elevators = Brix.System & {
	-- Fires for every sound the keypad makes: each press, a clear, the alarm, the chime.
	acted: Brix.Signal<KeypadEvent>,
	-- Fires the instant a gate shut by its clock hits its post: the car leaves.
	departed: Brix.Signal<Leaving>,
	-- Fires as the car levels with the next floor; its gate folds open a moment later.
	arrived: Brix.Signal<Arrival>,
	-- Gives `elevator` its floor's code, the floor whose lights its alarm flashes and that floor's
	-- number (1 if not given), clears its keypad and stops its clock and any ride: shut, ready for
	-- the floor.
	arm: (self: any, elevator: Model, code: { number }, floor: Instance, number: number?) -> (),
	-- Opens the gate as the right code does, chime and all (tests; the dev hall).
	open: (self: any, elevator: Model) -> (),
	-- `to` takes over `from`'s ride mid-way (the next floor's car, L-08b): the same ride and riders
	-- written on it, so riders' screens follow it once they stand in it, and it arrives and opens
	-- on the ride's clock; `from` is done and never arrives. False if `from` isn't riding.
	takeOver: (self: any, from: Model, to: Model) -> boolean,
	-- `elevator` rides up to the floor it stands at as if it had left the floor below at server
	-- time `at` with `riders` aboard (a group come up from the lobby to a server of its own,
	-- L-08e1c): shut, its keypad dead; it arrives and opens on the ride's clock.
	ride: (self: any, elevator: Model, riders: { Player }, at: number) -> (),
	-- Stands `elevator` in the lobby (L-08e1b1), or stands it there again after a trip: its gate
	-- folds open, its keypad asleep, no clock, at the lobby's floor (`Ride.Lobby`). `pick` says who
	-- rides of those inside as the shut gate hits its post (Boarding.riders).
	lobby: (self: any, elevator: Model, pick: Pick) -> (),
	-- A lobby car's count: its gate starts to shut at server time `departs`; nil stops it. Ignored
	-- once the gate is shutting, or for a car that isn't in the lobby.
	count: (self: any, elevator: Model, departs: number?) -> (),
}

-- Where the remote lives, for the clients: ReplicatedStorage.Remotes.Keypad.
local FOLDER, REMOTE = Keypad.RemoteFolder, Keypad.RemoteName

-- Shut: the keypad takes digits. Alarm: dead until the alarm stops. Open: the clock runs.
-- Leaving: the clock ran out and the gate is shutting. Riding: the car is climbing. Arrived: it
-- levelled and its gate is about to open. Gone: the gate's open on the next floor; done until the
-- climb arms it again.
type Phase = "Shut" | "Alarm" | "Open" | "Leaving" | "Riding" | "Arrived" | "Gone"

type Entry = {
	model: Model,
	code: { number }?,
	floor: Instance?,
	phase: Phase,
	state: Keypad.State,
	alarmEnds: number, -- server time the alarm stops
	gateFrom: number,
	gateTo: number,
	gateStart: number,
	departs: number, -- server time the clock runs out and the gate starts to shut
	car: Brix.Zone, -- the car from the gate back: whoever's middle is in it rides
	number: number, -- the floor it stands at
	leftAt: number, -- server time the car left, while it rides
	riders: { Player }, -- who rode, while it rides
	lobby: Pick?, -- a lobby car: who of those inside rides
}

local FREE = Brix.Pathing.free()

-- The car's zone for an elevator standing at `pivot`.
local function carOf(pivot: CFrame): Brix.Zone
	local at, x = pivot.Position, pivot.XVector
	return Brix.Zone.box(Departure.carBox(FREE, at.X, at.Y, at.Z, MotionLight.turnOf(x.X, x.Z)))
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Studio only: whether Workspace's `Ride.Hold` holds every ride where it is (the car doesn't
-- arrive while it's set), so a frame of the ride can be looked at.
local STUDIO = RunService:IsStudio()
local function held(): boolean
	return STUDIO and type(Workspace:GetAttribute(Ride.Hold)) == "number"
end

local Elevators = {}

function Elevators.new(): Elevators
	local entries: { [Instance]: Entry } = {}
	local moving: { [Entry]: true } = {}
	local alarms: { [Entry]: true } = {}
	local clocks: { [Entry]: true } = {}
	local lastPress: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local acted = Brix.Signal.new() :: Brix.Signal<KeypadEvent>
	local departed = Brix.Signal.new() :: Brix.Signal<Leaving>
	local arrived = Brix.Signal.new() :: Brix.Signal<Arrival>
	local lights: MotionLights.MotionLights? = nil
	local remote: RemoteEvent? = nil

	local function event(entry: Entry, action: Action, player: Player?)
		acted:fire({
			elevator = entry.model,
			action = action,
			player = player,
			at = Elevator.keypadPoint(entry.model),
			reach = Keypad.Heard[action],
		})
	end

	-- Writes the keypad's next state for every screen to draw.
	local function write(
		entry: Entry,
		what: Keypad.Event,
		typed: string,
		digit: number?,
		by: number?
	)
		local state = entry.state
		state.count += 1
		state.event, state.typed, state.digit, state.by = what, typed, digit, by
		entry.model:SetAttribute(Keypad.Attribute, Keypad.encode(state))
	end

	-- How far shut the gate is now.
	local function shutNow(entry: Entry): number
		return Gate.at(entry.gateFrom, entry.gateTo, now() - entry.gateStart)
	end

	-- Sends the gate toward `to`, starting at server time `start`, from wherever it is then.
	local function moveGate(entry: Entry, to: number, start: number)
		local from = Gate.at(entry.gateFrom, entry.gateTo, start - entry.gateStart)
		entry.gateFrom, entry.gateTo, entry.gateStart = from, to, start
		entry.model:SetAttribute(Gate.Attribute, Gate.encode(from, to, start))
		moving[entry] = true
	end

	-- The right code: the gate folds open and its clock is set to run out 30 s after it slams.
	local function open(entry: Entry, player: Player?)
		if entry.phase ~= "Shut" and entry.phase ~= "Alarm" then
			return
		end
		entry.phase = "Open"
		alarms[entry] = nil
		event(entry, "Right", player)
		local t = now()
		entry.departs = Departure.departs(t, shutNow(entry))
		moveGate(entry, 0, t + Gate.Delay)
		entry.model:SetAttribute(Departure.Attribute, entry.departs)
		clocks[entry] = true
	end

	-- The shut gate hit its post: whoever is inside the car rode; whoever else is on the floor
	-- (within the clock's reach) was left to the building.
	local function leave(entry: Entry, at: number)
		local inside: { Player } = {}
		local left: { Player } = {}
		local here = entry.model:GetPivot().Position
		local pick = entry.lobby
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if not root then
				continue
			end
			local p = root.Position
			if entry.car:contains((p :: any) :: vector) then
				table.insert(inside, player)
			elseif not pick and (p - here).Magnitude <= Departure.Heard then
				-- a lobby car leaves nobody behind: the lobby isn't a floor of the climb
				table.insert(left, player)
			end
		end
		local aboard: { Player } = inside
		if pick then
			aboard = pick(inside)
		end
		local ids: { number } = table.create(#aboard)
		for i, player in aboard do
			ids[i] = player.UserId
		end
		-- the ride first, so a rider's screen has its floors by the time it learns it rode
		entry.leftAt, entry.riders = at, aboard
		entry.model:SetAttribute(Ride.Attribute, Ride.encode(at, entry.number, entry.number + 1))
		entry.model:SetAttribute(Departure.AboardAttribute, Departure.encodeAboard(at, ids))
		departed:fire({
			elevator = entry.model,
			floor = entry.floor,
			aboard = aboard,
			left = left,
			at = at,
		})
	end

	-- The gate starts to shut on a floor with someone still in the car: they're stood on the
	-- landing in front of it, facing the hall, side by side (Departure.outAcross), and the gate
	-- folds shut behind them. A car that shuts here goes nowhere until the next code, so nobody is
	-- ever shut in it.
	local function stepOut(entry: Entry)
		local inside: { Player } = {}
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and entry.car:contains((root.Position :: any) :: vector) then
				table.insert(inside, player)
			end
		end
		local pivot = entry.model:GetPivot()
		for i, player in inside do
			local character = player.Character
			if character then
				local across = Departure.outAcross(i, #inside)
				character:PivotTo(pivot * CFrame.new(across, Departure.OutUp, -Departure.OutFront))
			end
		end
		if STUDIO and #inside > 0 then
			print(`Elevators: {#inside} stepped out as the gate shut on floor {entry.number}`)
		end
	end

	-- A press of `key` on `elevator`'s keypad by `player`: checked, then done.
	local function press(player: Player, elevator: unknown, key: unknown)
		-- the payload's types: an elevator of ours, a key the keypad has
		if typeof(elevator) ~= "Instance" or not Keypad.isKey(key) then
			return
		end
		local entry = entries[elevator :: Instance]
		if not entry or entry.lobby then
			return -- a lobby car's keypad is asleep (L-08e1b1)
		end
		-- range: the player stands at the keypad
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		if (root.Position - Elevator.keypadPoint(entry.model)).Magnitude > Keypad.Reach then
			return
		end
		-- rate: no faster than a thumb
		local t = os.clock()
		local last = lastPress[player]
		if last and t - last < Keypad.PressSeconds then
			return
		end
		lastPress[player] = t
		-- the keypad's state: dead while the alarm rings, done once the gate opens
		if entry.phase ~= "Shut" then
			return
		end
		if key == "Clear" then
			write(entry, "Clear", "", nil, player.UserId)
			event(entry, "Clear", player)
			return
		end
		local digit = key :: number
		local typed, verdict = Keypad.enter(entry.state.typed, digit, entry.code)
		local what: Keypad.Event = if verdict == "Wrong"
			then "Wrong"
			elseif verdict == "Right" then "Right"
			else "Press"
		write(entry, what, typed, digit, player.UserId)
		event(entry, "Press", player)
		if verdict == "Wrong" then
			entry.phase = "Alarm"
			entry.alarmEnds = now() + Keypad.AlarmSeconds
			alarms[entry] = true
			event(entry, "Wrong", player)
			if lights and entry.floor then
				lights:flash(entry.floor)
			end
		elseif verdict == "Right" then
			open(entry, player)
		end
	end

	local function add(inst: Instance): Entry?
		-- only elevators in the world: the template in ReplicatedStorage carries no tag, but a
		-- stray one would have no floor
		if not inst:IsA("Model") or not inst:IsDescendantOf(Workspace) then
			return nil
		end
		local found = entries[inst]
		if found then
			return found
		end
		local from, to, start = Gate.decode(inst:GetAttribute(Gate.Attribute))
		-- an elevator left open in the place (Edit's tests): no clock was set, so it never leaves
		local phase: Phase = if to < 1 then "Open" else "Shut"
		local entry: Entry = {
			model = inst,
			code = nil,
			floor = nil,
			phase = phase,
			state = Keypad.decode(inst:GetAttribute(Keypad.Attribute)),
			alarmEnds = 0,
			gateFrom = from,
			gateTo = to,
			gateStart = start,
			departs = math.huge,
			car = carOf(inst:GetPivot()),
			number = 1,
			leftAt = 0,
			riders = {},
			lobby = nil,
		}
		entries[inst] = entry
		if inst:GetAttribute(Keypad.Attribute) == nil then
			write(entry, "Rest", "")
		end
		return entry
	end

	local function remove(inst: Instance)
		local entry = entries[inst]
		if entry then
			entries[inst] = nil
			moving[entry] = nil
			alarms[entry] = nil
			clocks[entry] = nil
		end
	end

	local system = {
		name = "Elevators",
		acted = acted,
		departed = departed,
		arrived = arrived,
	}

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; MotionLights fills this slot (init.server)
		lights = (context.registry:get("motionLights") :: any) :: MotionLights.MotionLights
		local folder = ReplicatedStorage:FindFirstChild(FOLDER)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER
			folder.Parent = ReplicatedStorage
		end
		local r = Instance.new("RemoteEvent")
		r.Name = REMOTE
		r.Parent = folder
		remote = r
		table.insert(connections, r.OnServerEvent:Connect(press))
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				lastPress[player] = nil
			end)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(add)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(remove)
		)
		for _, inst in CollectionService:GetTagged(Elevator.Tag) do
			add(inst)
		end
	end

	function system.step(_: any, _dt: number)
		if next(moving) == nil and next(alarms) == nil and next(clocks) == nil then
			return
		end
		local t = now()
		-- the clocks first, so a gate set shutting this step is fitted this step
		for entry in clocks do
			if entry.phase == "Open" and t >= entry.departs then
				entry.phase = "Leaving"
				moveGate(entry, 1, entry.departs)
			elseif entry.phase == "Leaving" and t >= Departure.leaves(entry.departs) then
				entry.phase = "Riding"
				leave(entry, Departure.leaves(entry.departs))
			elseif
				entry.phase == "Riding"
				and t >= entry.leftAt + Ride.arrives()
				and not held()
			then
				-- level with the next floor: the bell, then the gate folds open on it
				entry.phase = "Arrived"
				local from = entry.number
				entry.number = from + 1
				entry.model:SetAttribute(Ride.FloorAttribute, entry.number)
				moveGate(entry, 0, entry.leftAt + Ride.opens())
				local riders = entry.riders
				entry.riders = {}
				arrived:fire({
					elevator = entry.model,
					riders = riders,
					from = from,
					to = entry.number,
					at = entry.leftAt + Ride.arrives(),
				})
			elseif entry.phase == "Arrived" and t >= entry.leftAt + Ride.opens() then
				-- the leaving's over: nobody's left behind by a car that's back at a floor
				entry.phase = "Gone"
				clocks[entry] = nil
				entry.model:SetAttribute(Departure.AboardAttribute, nil)
			end
		end
		for entry in moving do
			local elapsed = t - entry.gateStart
			if elapsed >= Gate.settles(entry.gateFrom, entry.gateTo) then
				Elevator.fitGate(entry.model, entry.gateTo)
				moving[entry] = nil
			elseif elapsed > 0 then
				Elevator.fitGate(entry.model, Gate.at(entry.gateFrom, entry.gateTo, elapsed))
			end
		end
		for entry in alarms do
			if t >= entry.alarmEnds then
				alarms[entry] = nil
				entry.phase = "Shut"
				write(entry, "Rest", "")
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		if remote then
			remote:Destroy()
			remote = nil
		end
		acted:disconnectAll()
		departed:disconnectAll()
		arrived:disconnectAll()
	end

	function system.arm(_: any, elevator: Model, code: { number }, floor: Instance, number: number?)
		assert(Keypad.isCode(code), "Elevators: a code is four digits, 0 to 9")
		local entry = add(elevator)
		assert(entry, `Elevators: {elevator:GetFullName()} isn't an elevator in the world`)
		entry.code = table.clone(code)
		entry.floor = floor
		entry.number = math.max(math.floor(number or 1), 1)
		entry.riders = {}
		entry.model:SetAttribute(Ride.FloorAttribute, entry.number)
		entry.model:SetAttribute(Ride.Attribute, nil)
		alarms[entry] = nil
		clocks[entry] = nil
		entry.phase = "Shut"
		entry.departs = math.huge
		entry.model:SetAttribute(Departure.Attribute, nil)
		entry.model:SetAttribute(Departure.AboardAttribute, nil)
		if entry.gateTo < 1 then
			stepOut(entry)
			moveGate(entry, 1, now())
		end
		write(entry, "Rest", "")
	end

	function system.takeOver(_: any, from: Model, to: Model): boolean
		local a = entries[from]
		local b = add(to)
		if not (a and b and a.phase == "Riding" and a ~= b) then
			return false
		end
		-- the new car: shut, its keypad dead, riding the same ride from the same floor
		alarms[b] = nil
		b.phase = "Riding"
		b.number = a.number
		b.leftAt = a.leftAt
		b.riders = a.riders
		b.departs = math.huge
		if b.gateTo < 1 then
			moveGate(b, 1, now())
		end
		b.model:SetAttribute(Ride.FloorAttribute, a.number)
		b.model:SetAttribute(Departure.Attribute, nil)
		-- the ride first, then who rode, as `leave` writes them
		b.model:SetAttribute(Ride.Attribute, a.model:GetAttribute(Ride.Attribute))
		b.model:SetAttribute(
			Departure.AboardAttribute,
			a.model:GetAttribute(Departure.AboardAttribute)
		)
		write(b, "Rest", "")
		clocks[b] = true
		-- the car that left is done: it never arrives (its floor is cleared under it)
		a.phase = "Gone"
		a.riders = {}
		clocks[a] = nil
		return true
	end

	function system.ride(_: any, elevator: Model, riders: { Player }, at: number)
		local entry = add(elevator)
		assert(entry, `Elevators: {elevator:GetFullName()} isn't an elevator in the world`)
		-- shut, its keypad dead, riding up from the floor below (the lobby, below floor 1)
		local from = if entry.number <= 1 then Ride.Lobby else entry.number - 1
		alarms[entry] = nil
		entry.lobby = nil
		entry.phase = "Riding"
		entry.number = from
		entry.leftAt = at
		entry.riders = table.clone(riders)
		entry.departs = math.huge
		if entry.gateTo < 1 then
			moveGate(entry, 1, now())
		end
		local ids: { number } = table.create(#riders)
		for i, player in riders do
			ids[i] = player.UserId
		end
		entry.model:SetAttribute(Ride.FloorAttribute, from)
		entry.model:SetAttribute(Departure.Attribute, nil)
		-- the ride first, then who rode, as `leave` writes them
		entry.model:SetAttribute(Ride.Attribute, Ride.encode(at, from, from + 1))
		entry.model:SetAttribute(Departure.AboardAttribute, Departure.encodeAboard(at, ids))
		write(entry, "Rest", "")
		clocks[entry] = true
	end

	function system.lobby(_: any, elevator: Model, pick: Pick)
		local entry = add(elevator)
		assert(entry, `Elevators: {elevator:GetFullName()} isn't an elevator in the world`)
		entry.lobby = pick
		entry.code = nil
		entry.floor = nil
		entry.number = Ride.Lobby
		entry.riders = {}
		alarms[entry] = nil
		clocks[entry] = nil
		entry.phase = "Open"
		entry.departs = math.huge
		entry.model:SetAttribute(Ride.FloorAttribute, Ride.Lobby)
		entry.model:SetAttribute(Ride.Attribute, nil)
		entry.model:SetAttribute(Departure.Attribute, nil)
		entry.model:SetAttribute(Departure.AboardAttribute, nil)
		if entry.gateTo > 0 then
			moveGate(entry, 0, now())
		end
		write(entry, "Rest", "")
	end

	function system.count(_: any, elevator: Model, departs: number?)
		local entry = entries[elevator]
		if not (entry and entry.lobby and entry.phase == "Open") then
			return
		end
		if departs then
			if departs ~= entry.departs then
				entry.departs = departs
				entry.model:SetAttribute(Departure.Attribute, departs)
			end
			clocks[entry] = true
		elseif entry.departs ~= math.huge then
			entry.departs = math.huge
			entry.model:SetAttribute(Departure.Attribute, nil)
			clocks[entry] = nil
		end
	end

	function system.open(_: any, elevator: Model)
		local entry = add(elevator)
		if entry then
			write(entry, "Right", entry.state.typed)
			open(entry, nil)
		end
	end

	return system
end

return Elevators
