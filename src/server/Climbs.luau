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
	- The instant a gate hits its post with friends aboard, `shut` fires (any floor, the top too):
	  they're paid and keep their finds (GatePay, S1-06).
	- Left behind (L-08c, Watching): as the car leaves with friends aboard, everyone else on the
	  floor (out in the halls, or kept in a unit) is out of the climb, and their screens start the
	  moment; as the floor is cleared under them they lose their character and watch a friend. A
	  ride that comes back after all leaves them in. Cut Free lets them back in on the floor the
	  climb is on (`Climbs.Arrival`), once there's one to stand on.
	- Carried up (S3-01a): nobody is out for longer than the ride. As the car arrives, each
	  watcher's screen dips to black a beat after its gate opens (`Left.carryAt`), and under it
	  they're stood wrapped in one of the new floor's units with empty hands (`carryUp`).
	- No top (S4-01a, D-226): every floor deals the one above it, as long as anyone rides. How each
	  floor plays is the floor rules' (`FloorRules`). The escape (`topped`, ClimbEnds' "Made it")
	  keeps its code but nothing fires it now; a way out, should the owner want one, would fire it.
	- Nobody aboard, or a next floor that isn't laid by `Climb.Latest`: the car arrives back at
	  its own lobby and is armed again for the same floor; a next floor already laid waits for the
	  next time it leaves.
	- `finish`, once the end covers every screen: the climb stops, its floors and the tools lying
	  on them go. `begin` starts the next one (ClimbEnds' "Again").
	- From the lobby (L-08e1b1, LobbyCars): `ready` lays floor 1 out of play as a car's count
	  starts, and `board` starts the climb on it as the car leaves: whatever climb ran goes, and
	  mid-cruise floor 1's car takes the lobby car's ride over and its riders are moved into it,
	  as at every floor's hand-off. It opens on floor 1 and shuts behind them, armed.
	- On a group's own server (L-08e1c, Trips): `ready` lays floor 1 as the server starts, and
	  `arrive` begins the climb on it with the group stood in its car mid-ride, as if they'd come
	  up the shaft from the lobby. `arrival` is where anyone joining late stands.

	Only the threads of a ride in progress run; nothing is stepped.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Climb = require(ReplicatedStorage.Shared.Climb)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Floor = require(ReplicatedStorage.Shared.Floor)
local KeeperMix = require(ReplicatedStorage.Shared.KeeperMix)
local NextFloor = require(ReplicatedStorage.Shared.NextFloor)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local Trip = require(ReplicatedStorage.Shared.Lobby.Trip)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)
local Deals = require(script.Parent.Deals)
local Elevators = require(script.Parent.Elevators)
local FindUses = require(script.Parent.FindUses)
local FloorBuilder = require(script.Parent.FloorBuilder)
local Keepers = require(script.Parent.Keepers)
local KeptPlayers = require(script.Parent.KeptPlayers)
local Minimaps = require(script.Parent.Minimaps)
local NextFloors = require(script.Parent.NextFloors)
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
	-- the version the team picked for it on the ride up (S4-03), nil for a floor nobody picked
	version: NextFloor.Version?,
}

-- A floor's halls built ahead of its deal (S4-03a): the deal goes on once the team has picked
-- its version on the ride (`deal`).
type Built = {
	number: number,
	seed: number,
	floor: Floor.Floor,
	random: Brix.Random, -- the layout's Random, carried on by the deal
	model: Model,
	origin: CFrame,
	laid: FloorBuilder.Laid,
}

export type Options = {
	seed: number,
	number: number, -- the floor it starts on
	origin: CFrame, -- where that floor's lobby stands; each next one Climb.Spacing on along its -Z
	parent: Instance, -- what floors are laid into
}

-- The team made it out: ClimbEnds' escape ("Made it"). Nothing fires it since the climb lost its
-- top (S4-01a, D-226); the escape's screen is kept for a way out the owner may want later.
export type Topped = {
	from: OnFloor,
	at: number, -- server time the gate hit its post
	riders: { Player },
	stranded: { Player }, -- left on the floor
}

-- The gate shutting on a floor of the climb with friends aboard: who rode, from which floor.
export type Shut = {
	from: OnFloor,
	riders: { Player },
	at: number, -- server time the gate hit its post
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
	-- Fires as a climb begins, on the floor it begins on (`begin`, `board`, `arrive`): everyone's
	-- coins start from zero (Coins, S1-04a).
	began: Brix.Signal<OnFloor>,
	-- Fires as riders are moved into the next floor's car.
	handedOff: Brix.Signal<HandOff>,
	-- Fires as the car leaves the top floor with friends aboard.
	topped: Brix.Signal<Topped>,
	-- Fires the instant a floor's gate hits its post with friends aboard, any floor, the top too,
	-- before the ride: they're paid and keep their finds (GatePay, S1-06).
	shut: Brix.Signal<Shut>,
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
	-- The climb's end has begun (ClimbEnds): the carries stop where they are. A watcher's screen
	-- may still dip, but nobody is taken out of their watch and given a new character while the
	-- end's black comes down over them; everyone goes at the end's cover (`finish`).
	ending: (self: any) -> (),
	-- The floor `player` is being carried up to (S3-01b): from their car's arrival there until
	-- they're stood wrapped in one of its units, or in its lobby with no unit free. Nil otherwise.
	-- The end counts them as kept on it (`ClimbEnd.look`).
	carrying: (self: any, player: Player) -> number?,
	-- Lays floor `options.number` of a new climb out of play, for a lobby car to carry its group
	-- to (L-08e1b1); nothing if one is laid or laying already. Doesn't yield.
	ready: (self: any, options: Options) -> (),
	-- The lobby's `car` left with `leaving.aboard`: whatever climb ran stops, and the climb begins
	-- on the floor `ready` laid as the car's ride is handed to that floor's car mid-cruise. False
	-- if no floor is laid or laying (the car comes back to the lobby). Doesn't yield.
	board: (self: any, car: Model, leaving: Elevators.Leaving) -> boolean,
	-- The car of the floor `ready` laid, once it's laid; nil before.
	readied: (self: any) -> Model?,
	-- A group come up from the lobby to a server of its own (L-08e1c): the climb begins on the
	-- floor `ready` laid, its car riding up to it `since` seconds into the ride with `riders`
	-- stood in it (Trip.spot, in their order). False if that floor isn't laid yet. Doesn't yield.
	arrive: (self: any, riders: { Player }, since: number) -> boolean,
	-- Where someone joining the climb stands (a late arrival, a friend cut free): in front of the
	-- car on the floor the climb is on, as if they'd just stepped out; nil while there's no floor
	-- to stand on (between floors, or no climb).
	arrival: (self: any) -> CFrame?,
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

-- Whether `at` (in the world) is inside the car of the elevator standing at `pivot`: the car's
-- box from its gate back (Departure.car), with a stud's slack all round.
local function inCar(pivot: CFrame, at: Vector3): boolean
	local centre, size = Departure.car()
	local p = pivot:PointToObjectSpace(at) - Vector3.new(centre[1], centre[2], centre[3])
	return math.abs(p.X) <= size[1] / 2 + 1
		and math.abs(p.Y) <= size[2] / 2 + 1
		and math.abs(p.Z) <= size[3] / 2 + 1
end

-- Where someone let back into the climb stands, in a floor's lobby (its origin's frame): in front
-- of the car, facing the hall, as if they'd just stepped out of it.
Climbs.Arrival = CFrame.lookAt(Vector3.new(0, 3, 6), Vector3.new(0, 3, -12))
-- The car's spots Cut Free picks from (Trip.spot's six: front row, then back), the emptiest.
Climbs.CarSpots = 6

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
	local began = Brix.Signal.new() :: Brix.Signal<OnFloor>
	local toppedSignal = Brix.Signal.new() :: Brix.Signal<Topped>
	local shut = Brix.Signal.new() :: Brix.Signal<Shut>
	local elevators: Elevators.Elevators? = nil
	local deals: Deals.Deals? = nil
	local keptPlayers: KeptPlayers.KeptPlayers? = nil
	local keepers: Keepers.Keepers? = nil
	local wraps: Wraps.Wraps? = nil
	local minimaps: Minimaps.Minimaps? = nil
	local slots: Slots.Slots? = nil
	local findUses: FindUses.FindUsesSystem? = nil
	local watching: Watching.Watching? = nil
	local nextFloors: NextFloors.NextFloors? = nil
	local options: Options? = nil
	local lastOptions: Options? = nil
	local started: number? = nil
	local playing: OnFloor? = nil
	local between = false -- a ride with riders is under way and hasn't handed them off yet
	local floors: { OnFloor } = {} -- every floor laid now: the one played, and the next once it's laid
	local ahead: OnFloor? = nil -- the floor above the one played, laid, dealt and waiting
	local built: Built? = nil -- the floor above's halls, built and waiting for its deal
	local layingAhead = false -- its halls are being built now
	-- the floor above's version, once the team's vote on a ride up to it has ended: a car that
	-- comes back keeps the pick for its next ride (S4-03a); `version` nil when none was offered
	local picked: { version: NextFloor.Version? }? = nil
	local climb = 0 -- which climb it is; a thread from an earlier one stops when it sees another
	local threads: { thread } = {}
	local departing: Brix.SignalConnection? = nil
	local opening: Brix.SignalConnection? = nil
	local reaching: Brix.SignalConnection? = nil
	local levelled: OnFloor? = nil -- the floor played whose car has reached it (Cut Free's spot)
	local waits: { Brix.SignalConnection } = {} -- cars waited on to arrive
	local carried: { [Player]: number } = {} -- who is being carried up, and to which floor
	local stopped = false -- the climb's end has begun: no more carries (`ending`)
	local first: OnFloor? = nil -- floor 1 laid out of play for the lobby's next car (`ready`)
	local firstOptions: Options? = nil
	local layingFirst: thread? = nil

	local function spawn(f: () -> ())
		local thread = task.spawn(f)
		if coroutine.status(thread) ~= "dead" then
			table.insert(threads, thread)
		end
	end

	-- Builds floor `number`'s halls, out of every floor system until it's dealt. Yields.
	local function build(o: Options, number: number): Built
		local seed = Climb.seedOf(o.seed, number)
		local random = Brix.Random.new({ seed = seed })
		local floor = Floor.generate(number, random)
		local origin = o.origin * CFrame.new(0, 0, -Climb.offset(o.number, number))
		local model, laid = FloorBuilder.lay(floor, origin, o.parent)
		return {
			number = number,
			seed = seed,
			floor = floor,
			random = random,
			model = model,
			origin = origin,
			laid = laid,
		}
	end

	-- Deals floor `b` as `version` (the team's pick, nil for none) and puts it in every floor
	-- system. Doesn't yield.
	local function deal(o: Options, b: Built, version: NextFloor.Version?): OnFloor
		local number, floor, seed, origin = b.number, b.floor, b.seed, b.origin
		-- the floor's deal carries on from its layout's Random: its code, notes and padlocks put
		-- on its halls, each unit's contents dealt as its door first lifts (Deals)
		-- the floor's monsters, mixed from the climb's seed (S4-02), leaned by the version (S4-03)
		local cast = KeeperMix.on(
			number,
			Brix.Random.new({ seed = KeeperMix.seedOf(o.seed, number) }),
			if version then version.lean else nil
		)
		local deck = Deal.new(floor, b.random, cast)
		if STUDIO then
			local names = {}
			for _, name in KeeperMix.Order do
				if cast[name] then
					table.insert(names, name)
				end
			end
			local as = if version then `, picked {version.name}` else ""
			print(`Climbs: floor {number} of climb {o.seed} has {table.concat(names, " and ")}{as}`)
		end
		local model, laid = b.model, b.laid
		FloorBuilder.dress(model, laid, floor, origin, deck)
		if version then
			model:SetAttribute(NextFloor.Attribute, version.name)
		end
		local on: OnFloor = {
			number = number,
			seed = seed,
			floor = floor,
			deck = deck,
			model = model,
			origin = origin,
			laid = laid,
			elevator = laid.elevator,
			version = version,
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
			keepers:add(
				floor,
				laid.slots,
				model,
				origin,
				Brix.Random.new({ seed = seed }),
				deck.sleepers,
				deck.packed
			)
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

	-- Builds and deals floor `number` as nobody picked it (a climb's first floor). Yields.
	local function lay(o: Options, number: number): OnFloor
		return deal(o, build(o, number), nil)
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

	-- Carried up (S3-01a, the GDD's "When the elevator leaves without you"): once `elevator`
	-- arrives at `on`, everyone watching the ride is on `on` too. Their screens dip to black a beat
	-- after the gate opens (`Left.carryAt`, `Watching:carry`); under it each gets a new character
	-- (`Watching:bring`), stood wrapped in one of the floor's units away from its lobby
	-- (`KeptPlayers:store`). With no unit free they stand in the lobby, as a late arrival does,
	-- each on a spot of their own (`ClimbEnd.spot`).
	local function carryUp(on: OnFloor, elevator: Model, mine: number)
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
			local w, k = watching, keptPlayers
			if not (w and k) or stopped then
				return
			end
			local at = Left.carryAt(arrival.at)
			spawn(function()
				local these: { Player } = {}
				for _, player in Players:GetPlayers() do
					if w:isOut(player) then
						table.insert(these, player)
						-- from here they count as kept on this floor: a wipe needn't wait for the unit
						carried[player] = on.number
					end
				end
				if #these == 0 then
					return
				end
				w:carry(these, at)
				task.wait(math.max(at + Left.CarryDip - now(), 0))
				local lobby = on.origin * Climbs.Arrival
				for n, player in these do
					-- with no unit to be had, each stands unwrapped on a spot of their own in
					-- front of the car, as a late arrival does: never two on one (S3-05a)
					local x, z = ClimbEnd.spot(n)
					local stand = lobby * CFrame.new(x, 0, z)
					spawn(function()
						if
							climb == mine
							and on.model.Parent
							and not stopped
							and w:isOut(player)
						then
							local character = w:bring(player)
							if
								character
								and climb == mine
								and not k:store(player, on.model, lobby.Position)
							then
								character:PivotTo(stand)
							end
						end
						if climb == mine and carried[player] == on.number then
							carried[player] = nil
						end
					end)
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

	-- Starts building the halls of the floor above `on` if they aren't built or being built: as
	-- the right code opens the gate, so they're up long before the car leaves (laying took 2 to
	-- 5 s in Studio). Its deal waits for the team's pick on the ride (`ride`).
	local function prepare(o: Options, on: OnFloor)
		if ahead or built or layingAhead then
			return
		end
		layingAhead = true
		local mine = climb
		spawn(function()
			local b = build(o, on.number + 1)
			if climb ~= mine then
				b.model:Destroy() -- a new climb began meanwhile
				return
			end
			layingAhead = false
			built = b
		end)
	end

	-- The team's pick on the ride up from `on` (S4-03a): the versions dealt for the floor above
	-- light up in its car as it leaves; on the cable's second knock the vote ends and the floor is
	-- dealt as picked. A car that came back keeps its first pick, with no second vote. Yields.
	local function pick(o: Options, on: OnFloor, leaving: Elevators.Leaving, mine: number)
		local car = on.elevator
		if not picked then
			local number = on.number + 1
			local random = Brix.Random.new({ seed = NextFloor.seedOf(o.seed, number) })
			local offered = NextFloor.deal(number, random)
			local v = nextFloors
			if v and car and #offered > 0 then
				v:open(car, leaving.aboard, offered, random)
				while climb == mine and rideSince(leaving.at) < NextFloor.Closes do
					task.wait()
				end
				if climb ~= mine then
					return
				end
				local name = v:close(car)
				picked = { version = if name then NextFloor.find(name) else nil }
			else
				picked = { version = nil }
			end
		end
		-- dealt as soon as its halls are up, by the latest the hand-off can wait for
		while climb == mine and not built and rideSince(leaving.at) < Climb.Latest - Climb.Lead do
			task.wait()
		end
		local b, p = built, picked
		if climb ~= mine or ahead or not (b and p) then
			return
		end
		built, picked = nil, nil
		ahead = deal(o, b, p.version)
	end

	-- Carries `leaving`'s riders from car `from` up into floor `above`'s car mid-cruise (L-08b):
	-- streams its lobby to their screens, has its car take the ride over, and on the cable's second
	-- knock moves each rider still where `still` says (on the floor they left, or in the lobby's
	-- car) and `standIns` to the same spot in it, in one frame. Returns the riders moved; nil and
	-- false if a new climb began meanwhile, nil and true if the new car couldn't take the ride over
	-- (the old one comes back). Yields.
	local function carry(
		leaving: Elevators.Leaving,
		from: Model,
		above: OnFloor,
		mine: number,
		still: (at: Vector3) -> boolean,
		standIns: { Model }
	): ({ Player }?, boolean)
		local e = elevators :: Elevators.Elevators
		local to = above.elevator :: Model
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
		local since = rideSince(leaving.at)
		if climb ~= mine then
			return nil, false
		end
		if not e:takeOver(from, to) then
			warn(
				`Climbs: floor {above.number}'s car couldn't take the ride over; the car comes back`
			)
			return nil, true
		end
		-- the move, on the cable's second knock (held with the ride in Studio)
		local moveAt = math.max(since + Climb.Lead, Climb.HandOff)
		repeat
			task.wait()
		until climb ~= mine or rideSince(leaving.at) >= moveAt
		if climb ~= mine then
			return nil, false
		end
		-- the move: each rider to the same spot in the new car (turned with it if it faces
		-- another way), in one frame so friends arrive together
		local fromPivot, toPivot = from:GetPivot(), to:GetPivot()
		local moved: { Player } = {}
		for _, player in leaving.aboard do
			local character = player.Character
			local root = rootOf(player)
			if player.Parent and character and root and still(root.Position) then
				character:PivotTo(toPivot * fromPivot:ToObjectSpace(character:GetPivot()))
				table.insert(moved, player)
			end
		end
		for _, model in standIns do
			if model.Parent then
				model:PivotTo(toPivot * fromPivot:ToObjectSpace(model:GetPivot()))
			end
		end
		return moved, false
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
		if not ahead then
			pick(o, on, leaving, mine)
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
		local moved, refused = carry(leaving, from, above, mine, function(at: Vector3): boolean
			return onFloor(on, at)
		end, standIns)
		if refused then
			ahead = above
			back()
			return
		elseif not moved then
			return -- a new climb cleared it
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
		-- whoever's still on it watches a friend ride up, and turns up wrapped on the new floor
		if watching then
			watching:watch(left, leaving.at)
		end
		armAfterArrival(above, to, mine)
		carryUp(above, to, mine)
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
		if #leaving.aboard > 0 then
			-- the riders are off this floor for its cameras now, before their car climbs past it
			if keepers then
				keepers:left(on.model, leaving.aboard)
			end
			shut:fire({ from = on, riders = leaving.aboard, at = leaving.at })
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
		if built then
			built.model:Destroy()
		end
		if nextFloors then
			nextFloors:clear()
		end
		playing, ahead, built, picked, layingAhead, between = nil, nil, nil, nil, false, false
		options, started = nil, nil
		table.clear(carried)
		stopped = false
	end

	-- Where someone joining the climb stands, or nil while there's no floor to stand on.
	local function arrivalSpot(): CFrame?
		local on = playing
		if between or not (on and on.model.Parent) then
			return nil
		end
		return on.origin * Climbs.Arrival
	end

	-- Where someone who Cut Free while out stands (S3-03a, the GDD: standing in the elevator when
	-- it reaches the next floor): in the played floor's car once it has reached the floor, at
	-- the car's spot furthest from anyone in it, facing its gate; nil before.
	local function carSpot(): CFrame?
		local on = playing
		local car = on and on.elevator
		if between or not (on and car and car.Parent and on.model.Parent) or levelled ~= on then
			return nil
		end
		local pivot = car:GetPivot()
		local best: Vector3? = nil
		local room = -1
		for i = 1, Climbs.CarSpots do
			local x, z = Trip.spot(i)
			local at = Vector3.new(x, 3, z)
			local world = pivot:PointToWorldSpace(at)
			local nearest = math.huge
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") then
					nearest = math.min(nearest, (root.Position - world).Magnitude)
				end
			end
			if nearest > room then
				best, room = at, nearest
			end
		end
		local at = best or Vector3.new(0, 3, 4)
		return pivot * CFrame.lookAt(at, at - Vector3.zAxis)
	end

	local system = {
		name = "Climbs",
		laid = laidSignal,
		handedOff = handedOff,
		began = began,
		topped = toppedSignal,
		shut = shut,
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
		findUses = (registry:get("findUses") :: any) :: FindUses.FindUsesSystem -- any: as above
		nextFloors = (registry:get("nextFloors") :: any) :: NextFloors.NextFloors -- any: as above
		local w = (registry:get("watching") :: any) :: Watching.Watching -- any: as above
		watching = w
		w:setArrival(arrivalSpot)
		w:setInCar(carSpot)
		local e = elevators :: Elevators.Elevators
		departing = e.departed:connect(departed)
		opening = e.acted:connect(acted)
		reaching = e.arrived:connect(function(a: Elevators.Arrival)
			local on = playing
			if on and a.elevator == on.elevator then
				levelled = on
			end
		end)
	end

	function system.stop(_: any)
		reset()
		if layingFirst and coroutine.status(layingFirst) ~= "dead" then
			task.cancel(layingFirst)
		end
		layingFirst = nil
		if first then
			first.model:Destroy()
			first, firstOptions = nil, nil
		end
		for _, c in { departing, opening, reaching } do
			if c then
				c:disconnect()
			end
		end
		departing, opening, reaching = nil, nil, nil
		laidSignal:disconnectAll()
		handedOff:disconnectAll()
		toppedSignal:disconnectAll()
		shut:disconnectAll()
		began:disconnectAll()
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
		began:fire(on)
		return on
	end

	function system.ready(_: any, o: Options)
		if first or layingFirst or not FloorBuilder.units() then
			return
		end
		layingFirst = task.spawn(function()
			local on = lay(o, o.number)
			layingFirst = nil
			-- out of play: no climb's reset clears it from under the group riding to it
			local i = table.find(floors, on)
			if i then
				table.remove(floors, i)
			end
			first, firstOptions = on, o
		end)
	end

	function system.board(_: any, car: Model, leaving: Elevators.Leaving): boolean
		if not (elevators and (first or layingFirst)) then
			return false
		end
		reset() -- whatever ran: the test hall's climb in Studio, or one that's over
		local mine = climb
		between = true
		local standIns = standInsIn(car)
		local here = car:GetPivot()
		spawn(function()
			while
				climb == mine
				and not first
				and rideSince(leaving.at) < Climb.Latest - Climb.Lead
			do
				task.wait()
			end
			local on, o = first, firstOptions
			if climb ~= mine then
				return
			end
			if not (on and o and on.elevator) then
				warn(
					`Climbs: floor 1 wasn't ready {string.format("%.1f", rideSince(leaving.at))} s into the lobby's ride; the car comes back`
				)
				between = false
				return
			end
			first, firstOptions = nil, nil
			table.insert(floors, on)
			options, lastOptions = o, o
			local moved = carry(leaving, car, on, mine, function(at: Vector3): boolean
				return inCar(here, at)
			end, standIns)
			if climb ~= mine then
				return
			end
			between = false
			if not moved then
				-- floor 1's car couldn't take the ride: the lobby car comes back, and the floor
				-- waits out of play for the next one
				local i = table.find(floors, on)
				if i then
					table.remove(floors, i)
				end
				first, firstOptions = on, o
				options = nil
				return
			end
			playing = on
			started = now()
			-- what they took up out of their job boxes is on the climb now, at risk (S5-03d2), and
			-- what they lit at home starts running down (S5-03f3)
			local s, u = slots, findUses
			for _, rider in moved do
				if s then
					s:up(rider)
				end
				if u then
					u:leave(rider)
				end
			end
			began:fire(on)
			armAfterArrival(on, on.elevator :: Model, mine)
			if STUDIO then
				print(
					`Climbs: {#moved} rode up from the lobby to floor {on.number} (seed {o.seed})`
				)
			end
		end)
		return true
	end

	function system.readied(_: any): Model?
		local on = first
		return if on and on.elevator and on.elevator.Parent then on.elevator else nil
	end

	function system.arrive(_: any, riders: { Player }, since: number): boolean
		local e = elevators
		local on, o = first, firstOptions
		local car = on and on.elevator
		if not (e and on and o and car and car.Parent) then
			return false
		end
		reset()
		local mine = climb
		first, firstOptions = nil, nil
		table.insert(floors, on)
		options, lastOptions = o, o
		-- everyone in the car at once, facing its gate, then the ride under them
		local pivot = car:GetPivot()
		for i, player in riders do
			local character = player.Character
			if player.Parent and character then
				local x, z = Trip.spot(i)
				local at = Vector3.new(x, 3, z)
				character:PivotTo(pivot * CFrame.lookAt(at, at - Vector3.zAxis))
			end
		end
		e:ride(car, riders, now() - since)
		playing = on
		started = now()
		began:fire(on)
		armAfterArrival(on, car, mine)
		if STUDIO then
			print(
				`Climbs: {#riders} arrived from the lobby, riding up to floor {on.number} (seed {o.seed})`
			)
		end
		return true
	end

	function system.arrival(_: any): CFrame?
		return arrivalSpot()
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

	function system.ending(_: any)
		stopped = true
	end

	function system.carrying(_: any, player: Player): number?
		return carried[player]
	end

	return system
end

return Climbs
