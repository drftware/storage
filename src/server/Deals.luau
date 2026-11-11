--!strict
--[[
	Deals: the deal on the floor (L-04e). Every door is a gamble, and this is where it's settled.
	A laid floor already has its code's notes stuck and its padlocked doors padlocked (FloorBuilder,
	from the floor's deck); this deals each unit the first time anyone can see into it, its door
	lifting (a peek or an open) or a saw's hole going through its wall or top (D-067),
	and lays what it holds before anyone sees in, so even a peek shows it on the floor: a tool to
	pick up (Slots), a find standing behind the bulb, or the place a keeper stands, which `dealt`
	hands on (Keepers stands the keeper there). Left 4 Dead's director deals its items the same way,
	as the team moves rather than up front. Where in the unit is DealSpot's pure rule.

	A tool whose art isn't built yet (the saw, the ladder...) is dealt but lies nowhere; in Studio
	Output says so, and what every unit held, so a tester knows what each door was.

	Until the director exists (Phase 2) every door deals in its Build mood, and the keepers awake
	are the brain's count of those awake on the floor now (`Keepers.awakeOn`: dealt awake, or woken
	by a noise), so the cap (`Deal.awakeCap`) sees what's really loose. The guarded note's unit is
	always dealt a keeper awake (D-072), and the deal keeps its place under the cap until then.
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
local Saws = require(script.Parent.Saws)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local Tools = require(ReplicatedStorage.Shared.Tools)
local TopHoleSpecs = require(ReplicatedStorage.Shared.StorageUnit.TopHole.Specs)

-- The stretch of each side wall a crawl hole and its fallen panel take, along from the door's
-- curtain plane (D-052), with a little room either end: nothing is dealt there (DealSpot).
local HOLE_MARGIN = 0.2
local PANEL = CrawlHoleSpecs.Parts.Panel_Pos
local HOLE_FROM = math.min(CrawlHoleSpecs.From, PANEL.Centre.Z - PANEL.Size.Z / 2) - HOLE_MARGIN
local HOLE_TO = math.max(CrawlHoleSpecs.To, PANEL.Centre.Z + PANEL.Size.Z / 2) + HOLE_MARGIN
-- Under the hole a saw cuts in a unit's top (D-067): the floor under its middle, where someone
-- dropping in lands, and the box its cut-out panel falls in, both in the hole's frame (which starts
-- `TopHoleSpecs.Channel` back from the doorway's face). Nothing is dealt on either.
local LAND_X = (TopHoleSpecs.Left + TopHoleSpecs.Right) / 2
local LAND_Z = (TopHoleSpecs.Front + TopHoleSpecs.Back) / 2
local FELL = TopHoleSpecs.Parts.PanelEdge

export type Dealt = {
	unit: Model,
	contents: Deal.Contents,
	-- where it was laid, on the floor, facing as it stands (a tool's middle, a find's or keeper's
	-- feet); nil when nothing was laid (nothing behind the door, or a tool not built yet)
	place: CFrame?,
}

export type Deals = Brix.System & {
	-- Fires as each unit is dealt, after what it holds is laid: Keepers stands a keeper at its place.
	dealt: Brix.Signal<Dealt>,
	-- A laid floor's deck and its units, each by its slot's index (FloorBuilder's `Laid.slots`).
	-- Its units are dealt as their doors first lift or a saw first holes them, until `floor` (the floor's model) is destroyed.
	add: (self: any, deck: Deal.Deck, units: { [Model]: number }, floor: Instance) -> (),
	-- Unit `unit` holds someone kept (L-07a): it's never dealt, so the friend who opens it finds
	-- only them, never a keeper beside them. Whether it was still to be dealt.
	hold: (self: any, unit: Model) -> boolean,
}

type Entry = { deck: Deal.Deck, index: number }

-- What the deal asks the keepers' brain. Keepers needs this module's `Dealt`, so this looks it up
-- by its slot rather than requiring it.
type Awake = { awakeOn: (self: any, unit: Model) -> number }

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
	local keepers: Awake? = nil

	-- Lays what unit `unit` (slot `index` of `deck`'s floor) was dealt; returns where, or nil.
	local function lay(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		contents: Deal.Contents
	): CFrame?
		local slot = deck.floor.slots[index]
		local spec = Specs[slot.size]
		local channel = if slot.size == "S" then TopHoleSpecs.Channel.S else TopHoleSpecs.Channel.M
		-- DealSpot's frame is the door's outer face, the curtain plane's in front of it
		local size: DealSpot.Unit = {
			width = spec.Width,
			depth = spec.Depth,
			doorWidth = spec.DoorWidth,
			hole = { from = HOLE_FROM + spec.CurtainPlane, to = HOLE_TO + spec.CurtainPlane },
			landing = { x = LAND_X, z = LAND_Z + channel },
			fallen = DealSpot.footprint(
				FELL.Centre.X,
				FELL.Centre.Z + channel,
				0,
				FELL.Size.X + 2 * HOLE_MARGIN,
				FELL.Size.Z + 2 * HOLE_MARGIN
			),
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
				-- not built yet (said in Output). Never on a floor since L-14e: the deal hands out
				-- only built tools (tests/carry.spec). Kept as a guard for a tool added half-built.
				return nil
			end
			local body = Tools.bounds(key)
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

	-- Deals `unit` the first time anyone can see into it; after that it holds what it held.
	local function open(unit: Model)
		local entry = units[unit]
		if not entry then
			return
		end
		units[unit] = nil
		local deck, index = entry.deck, entry.index
		local awake = if keepers then keepers:awakeOn(unit) else 0
		local contents = Deal.open(deck, index, { mood = "Build", awake = awake })
		local place = lay(unit, deck, index, contents)
		if RunService:IsStudio() then
			local laid = if place or contents.kind == "Nothing"
				then ""
				else " (no art yet, so nothing laid)"
			local guard = if index == deck.guarded then ", guarding its note" else ""
			print(`Deals: {unit.Name} held {said(contents)}{guard}{laid}`)
		end
		dealt:fire({ unit = unit, contents = contents, place = place })
	end

	local function onActed(event: Doors.DoorEvent)
		local motion = event.motion
		if motion and LIFTS[motion] then
			open(event.unit)
		end
	end

	-- A saw's hole going through shows the unit it leads into as a lifted door does (D-067): what
	-- it holds is there as the panel falls, before anyone crawls or drops in.
	local function onSawn(event: Saws.SawEvent)
		if event.done then
			open(event.into)
		end
	end

	local system = {
		name = "Deals",
		dealt = dealt,
	}

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back plain Systems; Doors, Slots and Keepers fill these (init.server)
		local doors = (context.registry:get("doors") :: any) :: Doors.Doors
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		keepers = (context.registry:get("keepers") :: any) :: Awake?
		table.insert(connections, doors.acted:connect(onActed))
		local saws = (context.registry:get("saws") :: any) :: Saws.Saws?
		if saws then
			table.insert(connections, saws.sawing:connect(onSawn))
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		table.clear(units)
		dealt:disconnectAll()
	end

	function system.hold(_: any, unit: Model): boolean
		if not units[unit] then
			return false
		end
		units[unit] = nil
		if RunService:IsStudio() then
			print(`Deals: {unit.Name} holds someone kept, so it's dealt nothing`)
		end
		return true
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
