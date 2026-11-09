--!strict
--[[
	Deals: the deal on the floor (L-04e). Every door is a gamble, and this is where it's settled.
	A laid floor already has its code's notes stuck and its padlocked doors padlocked (FloorBuilder,
	from the floor's deck); this deals each unit the first time its door lifts, a peek or an open,
	and lays what it holds before anyone sees in, so even a peek shows it on the floor: a tool to
	pick up (Slots), a find standing behind the bulb, or the place a keeper stands, which `dealt`
	hands on (L-06b stands the keeper there). Left 4 Dead's director deals its items the same way,
	as the team moves rather than up front. Where in the unit is DealSpot's pure rule.

	A tool whose art isn't built yet (the saw, the ladder...) is dealt but lies nowhere; in Studio
	Output says so, and what every unit held, so a tester knows what each door was.

	Until the director exists (Phase 2) every door deals in its Build mood, and the keepers awake
	are those dealt awake on the floor so far (L-06b's keepers will say who is awake now).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local CrawlHoleSpecs = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Specs)
local Deal = require(ReplicatedStorage.Shared.Deal)
local DealSpot = require(ReplicatedStorage.Shared.DealSpot)
local Doors = require(script.Parent.Doors)
local Finds = require(ReplicatedStorage.Shared.Finds)
local FloorBuilder = require(script.Parent.FloorBuilder)
local NoteSpot = require(ReplicatedStorage.Shared.Elevator.NoteSpot)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local Tools = require(ReplicatedStorage.Shared.Tools)

-- The stretch of each side wall a crawl hole and its fallen panel take, along from the door's
-- curtain plane (D-052), with a little room either end: nothing is dealt there (DealSpot).
local HOLE_MARGIN = 0.2
local PANEL = CrawlHoleSpecs.Parts.Panel_Pos
local HOLE_FROM = math.min(CrawlHoleSpecs.From, PANEL.Centre.Z - PANEL.Size.Z / 2) - HOLE_MARGIN
local HOLE_TO = math.max(CrawlHoleSpecs.To, PANEL.Centre.Z + PANEL.Size.Z / 2) + HOLE_MARGIN

export type Dealt = {
	unit: Model,
	contents: Deal.Contents,
	-- where it was laid, on the floor, facing as it stands (a tool's middle, a find's or keeper's
	-- feet); nil when nothing was laid (nothing behind the door, or a tool not built yet)
	place: CFrame?,
}

export type Deals = Brix.System & {
	-- Fires as each unit is dealt, after what it holds is laid: L-06b stands a keeper at its place.
	dealt: Brix.Signal<Dealt>,
	-- A laid floor's deck and its units, each by its slot's index (FloorBuilder's `Laid.slots`).
	-- Its units are dealt as their doors first lift, until `floor` (the floor's model) is destroyed.
	add: (self: any, deck: Deal.Deck, units: { [Model]: number }, floor: Instance) -> (),
}

type Entry = { deck: Deal.Deck, index: number }

-- The door motions that first show a unit's inside: a peek, an open, a lift from inside.
local LIFTS = { Peek = true, Open = true, LiftInside = true } :: { [string]: boolean }

-- How a unit holds things, said for Output in Studio.
local function said(contents: Deal.Contents): string
	local kind = contents.kind
	if kind == "Tool" then
		return `a tool, {contents.tool}`
	elseif kind == "Find" then
		return `a find, the {contents.find}`
	elseif kind == "Asleep" or kind == "Awake" then
		return `the {contents.keeper}, {string.lower(kind)}`
	end
	return "nothing"
end

local Deals = {}

function Deals.new(): Deals
	local units: { [Model]: Entry } = {}
	local connections: { Brix.SignalConnection } = {}
	local dealt = Brix.Signal.new() :: Brix.Signal<Dealt>
	local slots: Slots.Slots? = nil

	-- The keepers dealt awake on `deck`'s floor so far.
	local function awakeOn(deck: Deal.Deck): number
		local count = 0
		for _, contents in deck.dealt do
			if contents.kind == "Awake" then
				count += 1
			end
		end
		return count
	end

	-- Lays what unit `unit` (slot `index` of `deck`'s floor) was dealt; returns where, or nil.
	local function lay(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		contents: Deal.Contents
	): CFrame?
		local slot = deck.floor.slots[index]
		local spec = Specs[slot.size]
		-- DealSpot's frame is the door's outer face, the curtain plane's in front of it
		local size: DealSpot.Unit = {
			width = spec.Width,
			depth = spec.Depth,
			doorWidth = spec.DoorWidth,
			hole = { from = HOLE_FROM + spec.CurtainPlane, to = HOLE_TO + spec.CurtainPlane },
		}
		local number = slot.number :: string
		local note: number? = nil
		for _, n in deck.notes do
			if n.slot == index then
				note = NoteSpot.inUnit(spec.Depth, number).x
			end
		end
		local face = FloorBuilder.face(unit)
		local function at(spot: DealSpot.Spot): CFrame
			return face * CFrame.new(spot.x, 0, spot.z) * CFrame.Angles(0, math.rad(spot.yaw), 0)
		end

		local kind = contents.kind
		if kind == "Tool" then
			local key: string? = contents.tool
			if not (key and Tools.Catalog[key] and Tools.template(key) and slots) then
				return nil -- not built yet (said in Output)
			end
			local body = Tools.specs(key).Body
			local spot = DealSpot.inUnit(
				size,
				"Tool",
				{ across = body.Size.X, along = body.Size.Z, tall = body.Size.Y },
				note,
				number
			)
			if not spot then
				return nil
			end
			local place = at(spot)
			local _, yaw = place:ToOrientation()
			slots:lay(key, place.Position, math.deg(yaw))
			return place
		elseif kind == "Find" then
			local name: Finds.Name? = nil
			for _, n in Finds.Names do
				if n == contents.find then
					name = n :: Finds.Name -- Names holds only Names; Luau widens them to string
				end
			end
			if not name then
				return nil
			end
			local find = Finds.Specs.Finds[name]
			local spot = DealSpot.inUnit(
				size,
				"Find",
				{ across = find.Size.X, along = find.Size.Z, tall = find.Size.Y },
				note,
				number
			)
			if not spot then
				return nil
			end
			local place = at(spot)
			Finds.clone(name, place, unit.Parent or unit)
			return place
		elseif kind == "Asleep" or kind == "Awake" then
			local spot = DealSpot.inUnit(size, "Keeper", DealSpot.Keeper, note, number)
			return if spot then at(spot) else nil
		end
		return nil
	end

	local function onActed(event: Doors.DoorEvent)
		local motion = event.motion
		if not (motion and LIFTS[motion]) then
			return
		end
		local entry = units[event.unit]
		if not entry then
			return
		end
		units[event.unit] = nil -- dealt once: lifted again, it holds what it held
		local deck, index = entry.deck, entry.index
		local contents = Deal.open(deck, index, { mood = "Build", awake = awakeOn(deck) })
		local place = lay(event.unit, deck, index, contents)
		if RunService:IsStudio() then
			local laid = if place or contents.kind == "Nothing"
				then ""
				else " (no art yet, so nothing laid)"
			print(`Deals: {event.unit.Name} held {said(contents)}{laid}`)
		end
		dealt:fire({ unit = event.unit, contents = contents, place = place })
	end

	local system = {
		name = "Deals",
		dealt = dealt,
	}

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back plain Systems; Doors and Slots fill these slots (init.server)
		local doors = (context.registry:get("doors") :: any) :: Doors.Doors
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		table.insert(connections, doors.acted:connect(onActed))
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		table.clear(units)
		dealt:disconnectAll()
	end

	function system.add(_: any, deck: Deal.Deck, laid: { [Model]: number }, floor: Instance)
		for unit, index in laid do
			if not deck.dealt[index] then
				units[unit] = { deck = deck, index = index }
			end
		end
		floor.Destroying:Once(function()
			for unit in laid do
				units[unit] = nil
			end
		end)
	end

	return system
end

return Deals
