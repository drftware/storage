--!strict
--[[
	Climbs: the climb, floor after floor (L-08b, D-104), as Dandy's World's elevator opens on a new
	floor at every stop. The smallest stand-in for Brix's round loop (ENG-13, not built yet:
	docs/FRAMEWORK.md): it deals and lays floors and hands the team up them; the end and its
	results are ClimbEnds' (L-08d); no lobby yet.

	- `begin` starts a climb on a floor: deals it from its own seed (`Climb.seedOf`), lays it, puts
	  it in every floor system (the deal, kept players, keepers, bubble wrap, the corner map) and
	  arms its elevator with its code and number.
	- The right code opening the gate: the next floor is dealt (`Deal`'s harder odds for its
	  number) and laid, `Climb.Spacing` studs on, so a phone never streams both; it waits there
	  with nobody on it (keepers only wake as its doors are opened). The car leaving with riders
	  aboard: their screens are asked to stream its lobby in. Mid-cruise, while the shaft hides
	  everything through the gate, the new car takes the ride over (`Elevators:takeOver`, its
	  screens laying the shaft outside it), and on the cable's second knock every rider is moved
	  to the same spot in it, and the floor below is cleared in the same frame. It levels and opens
	  on the new floor. `Ride.Linger` after the gate opens it shuts behind the team, armed with the
	  new floor's code.
	- Left behind (L-08c, Watching): as the car leaves with friends aboard, everyone else on the
	  floor (out in the halls, or kept in a unit) is out of the climb, and their screens start the
	  moment; as the floor is cleared under them they lose their character and watch a friend. A
	  ride that comes back after all leaves them in. Cut Free lets them back in on the floor the
	  climb is on (`Climbs.Arrival`), once there's one to stand on.
	- The top (`Climb.Top`): the car leaving it with friends aboard ends the climb, an escape
	  (`topped`; ClimbEnds shows it). Whoever's left on the floor is left behind as at any floor,
	  and loses their character at the cable's second knock, as at a hand-off.
	- Nobody aboard, or a next floor that isn't laid by `Climb.Latest`: the car arrives back at
	  its own lobby and is armed again for the same floor; a next floor already laid waits for the
	  next time it leaves.
	- `finish`, once the end covers every screen: the climb stops, its floors and the tools lying
	  on them go. `begin` starts the next one (ClimbEnds' "Again").

	Only the threads of a ride in progress run; nothing is stepped.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Climb = require(ReplicatedStorage.Shared.Climb)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Floor = require(ReplicatedStorage.Shared.Floor)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)
local Deals = require(script.Parent.Deals)
local Elevators = require(script.Parent.Elevators)
local FloorBuilder = require(script.Parent.FloorBuilder)
local Keepers = require(script.Parent.Keepers)
local KeptPlayers = require(script.Parent.KeptPlayers)
local Minimaps = require(script.Parent.Minimaps)
local Slots = require(script.Parent.Slots)
local Watching = require(script.Parent.Watching)
local Wraps = require(script.Parent.Wraps)
local Left = require(ReplicatedStorage.Shared.Left)

-- A floor of the climb, laid and in every floor system.
export type OnFloor = {
	number: number,
	seed: number, -- its own (Climb.seedOf)
	floor: Floor.Floor,
	deck: Deal.Deck,
	model: Model,
	origin: CFrame, -- its lobby's middle, on the floor
	laid: FloorBuilder.Laid,
	elevator: Model?,
}

export type Options = {
	seed: number,
	number: number, -- the floor it starts on
	origin: CFrame, -- where that floor's lobby stands; each next one Climb.Spacing on along its -Z
	parent: Instance, -- what floors are laid into
}

-- The car leaving the top floor with friends aboard: the team made it.
export type Topped = {
	from: OnFloor,
	at: number, -- server time the gate hit its post
	riders: { Player },
	stranded: { Player }, -- left on the floor
}

-- Riders moved into the next floor's car.
export type HandOff = {
	from: OnFloor,
	to: OnFloor,
	riders: { Player },
	at: number, -- server time of the move
	since: number, -- seconds into the ride
}

export type Climbs = Brix.System & {
	-- Fires as each floor is laid and in every floor system, before riders reach it.
	laid: Brix.Signal<OnFloor>,
	-- Fires as riders are moved into the next floor's car.
	handedOff: Brix.Signal<HandOff>,
	-- Fires as the car leaves the top floor with friends aboard.
	topped: Brix.Signal<Topped>,
	-- Starts a climb on its first floor (yields while it's laid), clearing any before it; nil,
	-- after a warning, when the place lacks a template.
	begin: (self: any, options: Options) -> OnFloor?,
	-- The floor the team plays now: its car is the one they board.
	current: (self: any) -> OnFloor?,
	-- The server time the climb began (its first floor armed); nil with no climb.
	startedAt: (self: any) -> number?,
	-- The options the latest climb began with (kept after it's finished, for the next).
	last: (self: any) -> Options?,
	-- Stops the climb: its threads end, the tools lying on its floors and the floors themselves go
	-- (every floor system lets go of them; a kept player is let out).
	finish: (self: any) -> (),
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Seconds into the ride that left at `at`. Studio only: Workspace's `Ride.Hold` holds it there,
-- as it holds the car and every screen (DevRideHold), so the hand-off waits on it too.
local STUDIO = RunService:IsStudio()
local function rideSince(at: number): number
	local since = now() - at
	local hold = if STUDIO then Workspace:GetAttribute(Ride.Hold) else nil
	return if type(hold) == "number" then math.min(since, hold) else since
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local Climbs = {}

-- Where someone let back into the climb stands, in a floor's lobby (its origin's frame): in front
-- of the car, facing the hall, as if they'd just stepped out of it.
Climbs.Arrival = CFrame.lookAt(Vector3.new(0, 3, 6), Vector3.new(0, 3, -12))

-- Studio only: the stand-in friends (Left.StandInTag) standing in `elevator`'s car, who ride with
-- it as a player would, so one player can be left behind (docs/STUDIO.md).
local function standInsIn(elevator: Model): { Model }
	local out: { Model } = {}
	if not RunService:IsStudio() then
		return out
	end
	local pivot = elevator:GetPivot()
	for _, inst in CollectionService:GetTagged(Left.StandInTag) do
		local root = inst:IsA("Model") and inst:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			-- the car from the gate back (Elevator's car: 12.5 wide, 11 deep, 9.6 high)
			local p = pivot:PointToObjectSpace(root.Position)
			if math.abs(p.X) < 6 and p.Z > 0.8 and p.Z < 12 and p.Y > -1 and p.Y < 9.6 then
				table.insert(out, inst :: Model)
			end
		end
	end
	return out
end

function Climbs.new(): Climbs
	local laidSignal = Brix.Signal.new() :: Brix.Signal<OnFloor>
	local handedOff = Brix.Signal.new() :: Brix.Signal<HandOff>
	local toppedSignal = Brix.Signal.new() :: Brix.Signal<Topped>
	local elevators: Elevators.Elevators? = nil
	local deals: Deals.Deals? = nil
	local keptPlayers: KeptPlayers.KeptPlayers? = nil
	local keepers: Keepers.Keepers? = nil
	local wraps: Wraps.Wraps? = nil
	local minimaps: Minimaps.Minimaps? = nil
	local slots: Slots.Slots? = nil
	local watching: Watching.Watching? = nil
	local options: Options? = nil
	local lastOptions: Options? = nil
	local started: number? = nil
	local playing: OnFloor? = nil
	local between = false -- a ride with riders is under way and hasn't handed them off yet
	local floors: { OnFloor } = {} -- every floor laid now: the one played, and the next once it's laid
	local ahead: OnFloor? = nil -- the floor above the one played, laid and waiting
	local layingAhead = false -- it's being laid now
	local climb = 0 -- which climb it is; a thread from an earlier one stops when it sees another
	local threads: { thread } = {}
	local departing: Brix.SignalConnection? = nil
	local opening: Brix.SignalConnection? = nil
	local waits: { Brix.SignalConnection } = {} -- cars waited on to arrive

	local function spawn(f: () -> ())
		local thread = task.spawn(f)
		if coroutine.status(thread) ~= "dead" then
			table.insert(threads, thread)
		end
	end

	-- Deals and lays floor `number` and puts it in every floor system. Yields.
	local function lay(o: Options, number: number): OnFloor
		local seed = Climb.seedOf(o.seed, number)
		local random = Brix.Random.new({ seed = seed })
		local floor = Floor.generate(number, random)
		-- the floor's deal carries on from its layout's Random: its code, notes and padlocks laid
		-- with it, each unit's contents dealt as its door first lifts (Deals)
		local deck = Deal.new(floor, random)
		local origin = o.origin * CFrame.new(0, 0, -Climb.offset(o.number, number))
		local model, laid = FloorBuilder.lay(floor, origin, o.parent, deck)
		local on: OnFloor = {
			number = number,
			seed = seed,
			floor = floor,
			deck = deck,
			model = model,
			origin = origin,
			laid = laid,
			elevator = laid.elevator,
		}
		if deals then
			deals:add(deck, laid.slots, model)
		end
		-- a player a keeper catches here is wrapped and stored in one of its units (L-07a)
		if keptPlayers then
			keptPlayers:add(deck, laid.slots, model)
		end
		-- the keepers' roams draw from a fresh Random from the floor's seed, not the deal's, so
		-- where they wander never changes what a unit holds
		if keepers then
			keepers:add(floor, laid.slots, model, origin, Brix.Random.new({ seed = seed }))
		end
		if wraps then
			wraps:add(Wrap.halls(floor), model, origin)
		end
		if minimaps then
			minimaps:add(floor, laid.slots, model, origin)
		end
		table.insert(floors, on)
		laidSignal:fire(on)
		return on
	end

	local function arm(on: OnFloor)
		local elevator = on.elevator
		if elevators and elevator and elevator.Parent then
			elevators:arm(elevator, on.deck.code, on.model, on.number)
		end
	end

	-- Whether `at` (in the world) is on floor `on`.
	local function onFloor(on: OnFloor, at: Vector3): boolean
		local p = on.origin:PointToObjectSpace(at)
		return math.abs(p.Y) < 40 and Climb.on(on.floor, p.X, p.Z)
	end

	-- Clears floor `on` away: its model goes (every floor system lets go of it, a kept player is let
	-- out) and the tools lying on it go. Returns whoever was still on it.
	local function clear(on: OnFloor): { Player }
		local i = table.find(floors, on)
		if i then
			table.remove(floors, i)
		end
		local stranded: { Player } = {}
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root and onFloor(on, root.Position) then
				table.insert(stranded, player)
			end
		end
		on.model:Destroy()
		-- its lying tools go once the units' removal has been handled: a ladder stood on a unit
		-- falls flat as its unit goes (Ladders), and goes with the rest
		local s = slots
		if s then
			task.defer(function()
				s:clear(function(at: Vector3): boolean
					return onFloor(on, at)
				end)
			end)
		end
		return stranded
	end

	-- Once `elevator` arrives, arms `on` again `Ride.Linger` after its gate opens: the gate shuts
	-- behind the team.
	local function armAfterArrival(on: OnFloor, elevator: Model, mine: number)
		local e = elevators
		if not e then
			return
		end
		local waiting: Brix.SignalConnection
		waiting = e.arrived:connect(function(arrival: Elevators.Arrival)
			if arrival.elevator ~= elevator then
				return
			end
			waiting:disconnect()
			local i = table.find(waits, waiting)
			if i then
				table.remove(waits, i)
			end
			local wait = arrival.at + Ride.Open + Ride.Linger - now()
			spawn(function()
				task.wait(math.max(wait, 0))
				if climb == mine and elevator.Parent and on.model.Parent then
					arm(on)
				end
			end)
		end)
		table.insert(waits, waiting)
	end

	-- The car left `on` with nobody aboard, or the next floor came too late: it arrives back at
	-- this lobby and is armed again for it.
	local function comeBack(on: OnFloor, mine: number)
		local elevator = on.elevator
		if elevator then
			armAfterArrival(on, elevator, mine)
		end
	end

	-- Starts laying the floor above `on` if it isn't laid or being laid: as the right code opens
	-- the gate, so it's ready long before the car leaves (laying took 2 to 5 s in Studio).
	local function prepare(o: Options, on: OnFloor)
		if ahead or layingAhead or on.number >= Climb.Top then
			return
		end
		layingAhead = true
		local mine = climb
		spawn(function()
			local above = lay(o, on.number + 1)
			if climb ~= mine then
				return -- a new climb cleared it
			end
			layingAhead = false
			ahead = above
		end)
	end

	-- The ride from `on` to the floor above, from the car leaving to its riders stepping out;
	-- `stranded` were left on the floor as it left, `standIns` (Studio) ride with it.
	local function ride(
		o: Options,
		on: OnFloor,
		leaving: Elevators.Leaving,
		mine: number,
		stranded: { Player },
		standIns: { Model }
	)
		local e = elevators
		local from = on.elevator
		-- the car comes back after all: nobody was left behind
		local function back()
			between = false
			if watching then
				watching:unstrand(stranded)
			end
			comeBack(on, mine)
		end
		if not (e and from) then
			between = false
			if watching then
				watching:unstrand(stranded)
			end
			return
		end
		prepare(o, on)
		while climb == mine and not ahead and rideSince(leaving.at) < Climb.Latest - Climb.Lead do
			task.wait()
		end
		local above = ahead
		if climb ~= mine then
			return -- a new climb cleared it
		end
		local to = above and above.elevator
		local since = rideSince(leaving.at)
		if not (above and to) then
			-- it stays laid, or keeps laying, for the next time the car leaves
			warn(
				`Climbs: floor {on.number + 1} wasn't ready {string.format("%.1f", since)} s into the ride; the car comes back to floor {on.number}`
			)
			back()
			return
		end
		ahead = nil
		-- ask each rider's screen for the new lobby: now, so it's there when they are, and again
		-- as the new car takes the ride over (a long hold, or a phone short of memory, may have let
		-- it go), so its car is on their screen with the shaft laid outside it before they're moved
		local target = to:GetPivot().Position
		local streaming = 0
		local function stream()
			for _, player in leaving.aboard do
				streaming += 1
				task.spawn(function()
					local ok, err = pcall(function()
						player:RequestStreamAroundAsync(target, Climb.StreamWait)
					end)
					if not ok and player.Parent then
						warn(`Climbs: couldn't stream floor {above.number} to {player.Name}: {err}`)
					end
					streaming -= 1
				end)
			end
		end
		-- waits until the streams are in, or the latest the takeover may come
		local function streamed()
			while climb == mine and streaming > 0 do
				if rideSince(leaving.at) >= Climb.Latest - Climb.Lead then
					return
				end
				task.wait()
			end
		end
		stream()
		local takeAt = Climb.HandOff - Climb.Lead
		while climb == mine and rideSince(leaving.at) < takeAt do
			task.wait()
		end
		streamed()
		stream()
		streamed()
		since = rideSince(leaving.at)
		if climb ~= mine then
			return
		end
		if not e:takeOver(from, to) then
			warn(
				`Climbs: floor {above.number}'s car couldn't take the ride over; the car comes back`
			)
			ahead = above
			back()
			return
		end
		-- the move, on the cable's second knock (held with the ride in Studio)
		local moveAt = math.max(since + Climb.Lead, Climb.HandOff)
		repeat
			task.wait()
		until climb ~= mine or rideSince(leaving.at) >= moveAt
		if climb ~= mine then
			return
		end
		-- the move: each rider to the same spot in the new car (turned with it if it faces
		-- another way), in one frame so friends arrive together
		local fromPivot, toPivot = from:GetPivot(), to:GetPivot()
		local moved: { Player } = {}
		for _, player in leaving.aboard do
			local character = player.Character
			local root = rootOf(player)
			if player.Parent and character and root and onFloor(on, root.Position) then
				character:PivotTo(toPivot * fromPivot:ToObjectSpace(character:GetPivot()))
				table.insert(moved, player)
			end
		end
		for _, model in standIns do
			if model.Parent then
				model:PivotTo(toPivot * fromPivot:ToObjectSpace(model:GetPivot()))
			end
		end
		playing = above
		between = false
		local movedAt = now()
		handedOff:fire({
			from = on,
			to = above,
			riders = moved,
			at = movedAt,
			since = rideSince(leaving.at),
		})
		-- the floor below goes in the same frame: its riders are off it, and the frame the move
		-- costs a screen (about 0.3 s in Studio) is spent once, under the cable's knock; every
		-- rider's screen has the shaft laid outside the new car already (RideView)
		local left = clear(on)
		-- whoever's still on it is out of the climb, and watches a friend
		if watching then
			watching:watch(left, leaving.at)
		end
		armAfterArrival(above, to, mine)
	end

	-- The right code: the floor above starts laying.
	local function acted(event: Elevators.KeypadEvent)
		local o, on = options, playing
		if event.action == "Right" and o and on and event.elevator == on.elevator then
			prepare(o, on)
		end
	end

	local function departed(leaving: Elevators.Leaving)
		local o, on = options, playing
		if not (o and on and leaving.elevator == on.elevator) then
			return
		end
		local mine = climb
		local elevator = on.elevator
		local standIns = if elevator then standInsIn(elevator) else {}
		if #leaving.aboard == 0 and #standIns == 0 then
			comeBack(on, mine)
			return
		end
		-- everyone else on the floor, in the halls or kept in a unit, is left behind
		local stranded: { Player } = {}
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if
				root
				and not table.find(leaving.aboard, player)
				and not (watching and watching:isOut(player))
				and onFloor(on, root.Position)
			then
				table.insert(stranded, player)
			end
		end
		between = true
		if watching then
			watching:strand(stranded, leaving.at)
		end
		if on.number >= Climb.Top then
			-- the top: the team made it (ClimbEnds ends the climb). Whoever's left on the floor
			-- loses their character at the cable's second knock, as at a hand-off, so nothing
			-- reaches them before the end covers every screen.
			toppedSignal:fire({
				from = on,
				at = leaving.at,
				riders = leaving.aboard,
				stranded = stranded,
			})
			spawn(function()
				while climb == mine and rideSince(leaving.at) < Climb.HandOff do
					task.wait()
				end
				local w = watching
				if climb ~= mine or not w then
					return
				end
				local still: { Player } = {}
				for _, player in stranded do
					if player.Parent and w:isOut(player) then
						table.insert(still, player)
					end
				end
				w:watch(still, leaving.at)
			end)
			return
		end
		spawn(function()
			ride(o, on, leaving, mine, stranded, standIns)
		end)
	end

	-- Stops whatever climb is running and clears its floors.
	local function reset()
		climb += 1
		for _, thread in threads do
			if coroutine.status(thread) ~= "dead" then
				task.cancel(thread)
			end
		end
		table.clear(threads)
		for _, c in waits do
			c:disconnect()
		end
		table.clear(waits)
		local gone = table.clone(floors)
		for _, on in floors do
			if on.model.Parent then
				on.model:Destroy()
			end
		end
		table.clear(floors)
		-- the tools lying on its floors go with them (a new floor 1 is laid where the last one
		-- was), once the units' removal has been handled: a ladder stood on a unit falls flat as
		-- its unit goes (Ladders), and goes with the rest
		local s = slots
		if s and #gone > 0 then
			task.defer(function()
				s:clear(function(at: Vector3): boolean
					for _, on in gone do
						if onFloor(on, at) then
							return true
						end
					end
					return false
				end)
			end)
		end
		playing, ahead, layingAhead, between = nil, nil, false, false
		options, started = nil, nil
	end

	local system = {
		name = "Climbs",
		laid = laidSignal,
		handedOff = handedOff,
		topped = toppedSignal,
	}

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back a plain System; each slot is filled by its system (init.server)
		elevators = (registry:get("elevators") :: any) :: Elevators.Elevators
		deals = (registry:get("deals") :: any) :: Deals.Deals -- any: as above
		keptPlayers = (registry:get("keptPlayers") :: any) :: KeptPlayers.KeptPlayers -- any: as above
		keepers = (registry:get("keepers") :: any) :: Keepers.Keepers -- any: as above
		wraps = (registry:get("wraps") :: any) :: Wraps.Wraps -- any: as above
		minimaps = (registry:get("minimaps") :: any) :: Minimaps.Minimaps -- any: as above
		slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
		local w = (registry:get("watching") :: any) :: Watching.Watching -- any: as above
		watching = w
		w:setArrival(function(): CFrame?
			local on = playing
			if between or not (on and on.model.Parent) then
				return nil
			end
			return on.origin * Climbs.Arrival
		end)
		local e = elevators :: Elevators.Elevators
		departing = e.departed:connect(departed)
		opening = e.acted:connect(acted)
	end

	function system.stop(_: any)
		reset()
		for _, c in { departing, opening } do
			if c then
				c:disconnect()
			end
		end
		departing, opening = nil, nil
		laidSignal:disconnectAll()
		handedOff:disconnectAll()
		toppedSignal:disconnectAll()
	end

	function system.begin(_: any, o: Options): OnFloor?
		reset()
		local units, missing = FloorBuilder.units()
		if not units then
			warn(
				`Climbs: no template at {missing}, so no floor to climb; import it (art/unit/README.md, art/corridor/README.md)`
			)
			return nil
		end
		options, lastOptions = o, o
		local mine = climb
		local on = lay(o, o.number)
		if climb ~= mine then
			return nil
		end
		playing = on
		arm(on)
		started = now()
		return on
	end

	function system.current(_: any): OnFloor?
		return playing
	end

	function system.startedAt(_: any): number?
		return started
	end

	function system.last(_: any): Options?
		return lastOptions
	end

	function system.finish(_: any)
		reset()
	end

	return system
end

return Climbs
