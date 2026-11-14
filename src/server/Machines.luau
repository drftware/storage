--!strict
--[[
	Machines: the vending machine in every floor's car, on the server (S1-10c, GDD "The ride").

	Each ride that wakes the machine (`Machine.Wake.wakes`: every ride but the first, up from the
	lobby) is dealt its stock once (`Machine.Stock.deal`) the moment the ride begins, and the
	stock is kept by the ride's own value (`Ride.Attribute`). Every machine whose car carries that
	ride shows it (`Stock.Attribute`): the car that leaves and, mid-way, the next floor's car that
	takes the ride over (Elevators' `takeOver` writes the same ride on it), so the coils are the
	same when the riders move across. As the car stands at a floor again (its ride cleared) the
	machine's stock goes with it, and a ride no car carries any more is forgotten.

	The buy (S1-10c2, `Machine.Buy`): a screen picks a bay on the machine's menu (S1-10d1: the
	machine's one button, drawn and opened on each screen by MachineMenu) and sends the pick
	(`Buy.Pick`). It's checked in order: a machine we know and a whole bay number (type), a living
	rider who isn't wrapped stands within reach of the machine's button (`Buy.point`, range),
	they're aboard that car (its `Aboard`) on that ride and the bay's row is open (ownership), the
	coil holds something and they can pay (state), then the rate. The
	price is the server's own. Then, with nothing in between that could yield: the thing first (a
	battery fills their torch, refused while its ring is full; a tool goes in a free slot, refused
	with no room; quietly, as the screens play its pick-up when it reaches the hand), and only if
	it went, the buyer's screen is told (`Buy.Remote`: its coins fly to the slot) and the coins
	taken (`Coins:spend`); the bay's count drops, the buy
	is stamped on the machine (`Buy.Attribute`) and the stock rewritten on every machine carrying
	the ride. A refused press costs nothing and says nothing: the price is in its window, the
	torch's ring and the slots on screen.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Machine = require(ReplicatedStorage.Shared.Machine)
local Prompts = require(script.Parent.Prompts)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local Stock = require(ReplicatedStorage.Shared.Machine.Stock)

local Buy = Machine.Buy
local STUDIO = RunService:IsStudio()

-- What the buy reaches through the registry (init.server fills each slot).
type Wallet = {
	countOf: (self: any, player: Player) -> number?,
	spend: (self: any, player: Player, coins: number, item: string) -> boolean,
}
type Filler = { fill: (self: any, player: Player) -> boolean }
type Giver = { give: (self: any, player: Player, key: string, quiet: boolean?) -> boolean }
type Rate = { last: number?, burst: number }

export type Machines = Brix.System & {
	-- The stock `machine` shows this ride, or nil while it's dark (the server's own copy).
	stockOf: (self: any, machine: Model) -> Stock.Stock?,
}

type Entry = {
	model: Model,
	car: Instance,
	ride: string?, -- the ride its car carries, if that ride wakes it
	at: number, -- when that ride left (server time)
	from: number, -- and the floor it left
	conn: RBXScriptConnection,
	serial: number, -- buys at this machine, for `Buy.Attribute`
}

-- Seconds into the ride that left at server time `at`. Studio only: Workspace's `Ride.Hold`
-- holds it there, as every screen does (RideClock).
local function rideClock(at: number): number
	local hold = if STUDIO then Workspace:GetAttribute(Ride.Hold) else nil
	if type(hold) == "number" then
		return hold
	end
	return Workspace:GetServerTimeNow() - at
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local Machines = {}

function Machines.new(): Machines
	local entries: { [Model]: Entry } = {}
	local rides: { [string]: Stock.Stock } = {} -- each waking ride's stock, by its value
	local connections: { RBXScriptConnection } = {}
	local rates: { [Player]: Rate } = {}
	local coins: Wallet? = nil
	local flashlights: Filler? = nil
	local slots: Giver? = nil
	local remote: RemoteEvent? = nil -- tells the buyer's screen of the spend (`Buy.Remote`)
	local picks: RemoteEvent? = nil -- a screen's pick on the menu (`Buy.Pick`)
	-- a fresh shuffle each server; any: Brix's Random fills the pure contract Stock types
	local random = (
		Brix.Random.new({ seed = Random.new():NextInteger(1, 2 ^ 30) }) :: any
	) :: Stock.Random

	-- Forgets the rides no car carries any more.
	local function prune()
		local used: { [string]: boolean } = {}
		for _, e in entries do
			if e.ride then
				used[e.ride] = true
			end
		end
		for value in rides do
			if not used[value] then
				rides[value] = nil
			end
		end
	end

	-- The stock of ride `value` on every machine carrying it.
	local function publish(value: string)
		local stock = rides[value]
		if not stock then
			return
		end
		local text = Stock.encode(stock)
		for _, e in entries do
			if e.ride == value then
				e.model:SetAttribute(Stock.Attribute, text)
			end
		end
	end

	local function press(e: Entry, i: number, player: Player)
		-- type: checked by the remote's handler. A machine we still know on a ride that wakes it.
		local value = e.ride
		if entries[e.model] ~= e or not value then
			return
		end
		-- range: a living rider, not wrapped, within reach of the machine's button
		if Prompts.wrapped(player) then
			return
		end
		local root = rootOf(player)
		if not root then
			return
		end
		if (root.Position - Buy.point(e.model:GetPivot())).Magnitude > Buy.Reach + Buy.Slack then
			return
		end
		-- ownership: aboard this car on this ride, its row lit and the power not about to cut
		if e.car:GetAttribute(Ride.Attribute) ~= value then
			return
		end
		local _, ids = Departure.decodeAboard(e.car:GetAttribute(Departure.AboardAttribute))
		if not table.find(ids, player.UserId) then
			return
		end
		local at, from = Ride.decode(value)
		if not (at and Buy.open(Machine.Specs.Bays[i].Row, rideClock(at), from)) then
			return
		end
		-- state: the coil holds something, they can pay
		local stock = rides[value]
		local bay = stock and stock[i]
		local wallet = coins
		if not (bay and wallet) or Buy.check(bay, wallet:countOf(player)) ~= "ok" then
			return
		end
		-- rate
		local rate = rates[player] or { last = nil, burst = 0 }
		local now = os.clock()
		local may, left = Buy.allow(rate.last, rate.burst, now)
		if not may then
			return
		end
		rates[player] = { last = now, burst = left }
		-- the thing, then the coins: nothing here yields, so both or neither
		local key = bay.key
		if key == Stock.Battery then
			if not (flashlights and flashlights:fill(player)) then
				return -- the torch is full: the battery stays in its coil
			end
		elseif not (slots and slots:give(player, key, true)) then
			return -- no room: it stays in its coil
		end
		-- the buyer's screen first, so their coins fly into the slot before their count drops
		if remote then
			remote:FireClient(player, e.model, i, bay.price)
		end
		local paid = wallet:spend(player, bay.price, key)
		if not paid then
			warn(`Machines: {player.Name} got {key} but the {bay.price} coins weren't taken`)
		end
		bay.count -= 1
		e.serial += 1
		e.model:SetAttribute(Buy.Attribute, Buy.encode(i, e.serial, player.UserId))
		publish(value)
		if STUDIO then
			print(`Machines: {player.Name} bought {key} from bay {i} for {bay.price}`)
		end
	end

	-- Its car's ride changed: deal the ride's stock if it's new and wakes the machine, and show
	-- it; or the car stands at a floor and the machine is empty.
	local function rideChanged(e: Entry)
		local value = e.car:GetAttribute(Ride.Attribute)
		local at, from = Ride.decode(value)
		if type(value) == "string" and at and Machine.Wake.wakes(from) then
			local stock = rides[value]
			if not stock then
				stock = Stock.deal(random)
				rides[value] = stock
			end
			e.ride = value
			e.at, e.from = at, from
			e.model:SetAttribute(Stock.Attribute, Stock.encode(stock))
		else
			e.ride = nil
			e.model:SetAttribute(Stock.Attribute, nil)
		end
		prune()
	end

	local function added(inst: Instance)
		local car = inst.Parent
		if not inst:IsA("Model") or entries[inst] or not car then
			return
		end
		local e: Entry
		e = {
			model = inst,
			car = car,
			conn = car:GetAttributeChangedSignal(Ride.Attribute):Connect(function()
				rideChanged(e)
			end),
			at = 0,
			from = 0,
			serial = 0,
		}
		entries[inst] = e
		rideChanged(e)
	end

	local function removed(inst: Instance)
		local e = entries[inst :: Model]
		if e then
			entries[inst :: Model] = nil
			e.conn:Disconnect()
			prune()
		end
	end

	local system = { name = "Machines" }

	function system.start(_: any, context: Brix.Context)
		local folder = ReplicatedStorage:FindFirstChild(Buy.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Buy.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local r = Instance.new("RemoteEvent")
		r.Name = Buy.Remote
		r.Parent = folder
		remote = r
		local pick = Instance.new("RemoteEvent")
		pick.Name = Buy.Pick
		pick.Parent = folder
		picks = pick
		table.insert(
			connections,
			-- type first: a machine we know, a whole bay it has (unknown: whatever a screen sends)
			pick.OnServerEvent:Connect(function(player: Player, machine: unknown, bay: unknown)
				if typeof(machine) ~= "Instance" or type(bay) ~= "number" then
					return
				end
				local e = entries[machine :: Model]
				if not e or bay ~= math.floor(bay) or not Machine.Specs.Bays[bay] then
					return
				end
				press(e, bay, player)
			end)
		)
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		coins = (context.registry:get("coins") :: any) :: Wallet?
		flashlights = (context.registry:get("flashlights") :: any) :: Filler? -- any: as above
		slots = (context.registry:get("slots") :: any) :: Giver? -- any: as above
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				rates[player] = nil
			end)
		)
		for _, inst in CollectionService:GetTagged(Machine.Tag) do
			added(inst)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Machine.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Machine.Tag):Connect(removed)
		)
	end

	function system.stockOf(_: any, machine: Model): Stock.Stock?
		local e = entries[machine]
		return if e and e.ride then rides[e.ride] else nil
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, e in entries do
			e.conn:Disconnect()
		end
		table.clear(entries)
		table.clear(rides)
		table.clear(rates)
		if remote then
			remote:Destroy()
			remote = nil
		end
		if picks then
			picks:Destroy()
			picks = nil
		end
	end

	return system :: any -- any: the table is the Machines shape built field by field above
end

return Machines
