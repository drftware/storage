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

	The stock never comes from a screen; the buy (S1-10c2) charges the price kept here.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Machine = require(ReplicatedStorage.Shared.Machine)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local Stock = require(ReplicatedStorage.Shared.Machine.Stock)

export type Machines = Brix.System & {
	-- The stock `machine` shows this ride, or nil while it's dark (the server's own copy).
	stockOf: (self: any, machine: Model) -> Stock.Stock?,
}

type Entry = {
	model: Model,
	car: Instance,
	ride: string?, -- the ride its car carries, if that ride wakes it
	conn: RBXScriptConnection,
}

local Machines = {}

function Machines.new(): Machines
	local entries: { [Model]: Entry } = {}
	local rides: { [string]: Stock.Stock } = {} -- each waking ride's stock, by its value
	local connections: { RBXScriptConnection } = {}
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

	function system.start(_: any, _context: Brix.Context)
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
	end

	return system :: any -- any: the table is the Machines shape built field by field above
end

return Machines
