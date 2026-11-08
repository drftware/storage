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
	- The gate's motion is one replicated value (`Gate.Attribute`) that every screen folds the gate
	  from (ElevatorView); here only its collider follows, so the gap you see is the gap there is.
	- Every keypad sound fires `acted` with how far it's heard, as Doors does, so keepers (L-06b)
	  hear each beep and come running at the alarm.

	The code never leaves the server. Only gates in motion and dead keypads are stepped.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Gate = require(ReplicatedStorage.Shared.Elevator.Gate)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local MotionLights = require(script.Parent.MotionLights)

export type Action = "Press" | "Clear" | "Wrong" | "Right"

export type KeypadEvent = {
	elevator: Model,
	action: Action,
	player: Player?, -- nil when the game itself did it
	at: Vector3, -- the keypad's face
	reach: number, -- studs it's heard to (Keypad.Heard): a keeper within it hears it
}

export type Elevators = Brix.System & {
	-- Fires for every sound the keypad makes: each press, a clear, the alarm, the chime.
	acted: Brix.Signal<KeypadEvent>,
	-- Gives `elevator` its floor's code and the floor whose lights its alarm flashes, and clears
	-- its keypad.
	arm: (self: any, elevator: Model, code: { number }, floor: Instance) -> (),
	-- Opens the gate as the right code does, chime and all (tests; the dev hall).
	open: (self: any, elevator: Model) -> (),
}

-- Where the remote lives, for the clients: ReplicatedStorage.Remotes.Keypad.
local FOLDER, REMOTE = "Remotes", "Keypad"

-- Shut: the keypad takes digits. Alarm: dead until the alarm stops. Open: done for this floor.
type Phase = "Shut" | "Alarm" | "Open"

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
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local Elevators = {}

function Elevators.new(): Elevators
	local entries: { [Instance]: Entry } = {}
	local moving: { [Entry]: true } = {}
	local alarms: { [Entry]: true } = {}
	local lastPress: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local acted = Brix.Signal.new() :: Brix.Signal<KeypadEvent>
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

	-- Sends the gate toward `to`, starting `delay` seconds from now, from wherever it is.
	local function moveGate(entry: Entry, to: number, delay: number)
		local from = shutNow(entry)
		entry.gateFrom, entry.gateTo, entry.gateStart = from, to, now() + delay
		entry.model:SetAttribute(Gate.Attribute, Gate.encode(from, to, entry.gateStart))
		moving[entry] = true
	end

	local function open(entry: Entry, player: Player?)
		if entry.phase == "Open" then
			return
		end
		entry.phase = "Open"
		alarms[entry] = nil
		event(entry, "Right", player)
		moveGate(entry, 0, Gate.Delay)
	end

	-- A press of `key` on `elevator`'s keypad by `player`: checked, then done.
	local function press(player: Player, elevator: unknown, key: unknown)
		-- the payload's types: an elevator of ours, a key the keypad has
		if typeof(elevator) ~= "Instance" or not Keypad.isKey(key) then
			return
		end
		local entry = entries[elevator :: Instance]
		if not entry then
			return
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
			write(entry, "Clear", "")
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
		end
	end

	local system = {
		name = "Elevators",
		acted = acted,
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
		if next(moving) == nil and next(alarms) == nil then
			return
		end
		local t = now()
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
	end

	function system.arm(_: any, elevator: Model, code: { number }, floor: Instance)
		assert(Keypad.isCode(code), "Elevators: a code is four digits, 0 to 9")
		local entry = add(elevator)
		assert(entry, `Elevators: {elevator:GetFullName()} isn't an elevator in the world`)
		entry.code = table.clone(code)
		entry.floor = floor
		alarms[entry] = nil
		if entry.phase == "Alarm" then
			entry.phase = "Shut"
		end
		write(entry, "Rest", "")
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
