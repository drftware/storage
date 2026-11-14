--!strict
--[[
	Deals: the deal on the floor (L-04e). Every door is a gamble, and this is where it's settled.
	A laid floor already has its code's notes stuck and its padlocked doors padlocked (FloorBuilder,
	from the floor's deck); this deals each unit the first time anyone can see into it, its door
	lifting (a peek or an open) or a saw's hole going through its wall or top (D-067),
	and lays what it holds before anyone sees in, so even a peek shows it on the floor: a tool to
	pick up (Slots), a find standing behind the bulb (Slots too, since S1-05), or the place a keeper stands, which `dealt`
	hands on (Keepers stands the keeper there); in a unit with nothing to take, sometimes
	somebody's stuff against a wall (S1-04b2). Left 4 Dead's director deals its items the same way,
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
local CoinSpecs = require(ReplicatedStorage.Shared.Coins.Specs)
local Coins = require(script.Parent.Coins)
local CrawlHoleSpecs = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Specs)
local Deal = require(ReplicatedStorage.Shared.Deal)
local DealSpot = require(ReplicatedStorage.Shared.DealSpot)
local Doors = require(script.Parent.Doors)
local FloorBuilder = require(script.Parent.FloorBuilder)
local NoteSpot = require(ReplicatedStorage.Shared.Elevator.NoteSpot)
local Saws = require(script.Parent.Saws)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local Stuff = require(ReplicatedStorage.Shared.Stuff)
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

-- Each thing of somebody's stuff's size as DealSpot measures it (S1-04b2).
local STUFF_SIZES: { [string]: DealSpot.Size } = {}
for _, name in Deal.Stuff do
	local v = Stuff.size(name :: Stuff.Name) -- Deal.Stuff holds only Names (tests/stuffdeal.spec)
	STUFF_SIZES[name] = { across = v.X, along = v.Z, tall = v.Y }
end

export type Dealt = {
	unit: Model,
	contents: Deal.Contents,
	-- where it was laid, on the floor, facing as it stands (a tool's middle, a find's or keeper's
	-- feet); nil when nothing was laid (nothing behind the door, or a tool not built yet)
	place: CFrame?,
	-- who opened it: the player whose door lift or saw first showed it; nil when the game did
	player: Player?,
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

-- Somebody's stuff as a tester would say it, for Output in Studio.
local STUFF_SAID = {
	Mattress = "an old mattress",
	Carpet = "a rolled rug",
	Tower = "a tower of boxes",
	Wall = "a wall of boxes",
	Heap = "a heap of boxes",
	Column = "a column of boxes",
} :: { [string]: string }

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
	if contents.stuff then
		return `nothing to take, only {STUFF_SAID[contents.stuff] or contents.stuff}`
	end
	return "nothing"
end

local Deals = {}

function Deals.new(): Deals
	local units: { [Model]: Entry } = {}
	local connections: { Brix.SignalConnection } = {}
	local dealt = Brix.Signal.new() :: Brix.Signal<Dealt>
	local slots: Slots.Slots? = nil
	local coins: Coins.CoinsSystem? = nil
	local keepers: Awake? = nil

	-- Unit `index` of `deck`'s floor as DealSpot measures it, its number, and its note's place
	-- across the back wall if it holds one.
	local function shape(deck: Deal.Deck, index: number): (DealSpot.Unit, string, number?)
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
		return size, number, note
	end

	-- Where a spot in unit `unit` is in the world, standing as DealSpot turns it.
	local function placed(unit: Model, spot: DealSpot.Spot): CFrame
		return FloorBuilder.face(unit)
			* CFrame.new(spot.x, 0, spot.z)
			* CFrame.Angles(0, math.rad(spot.yaw), 0)
	end

	-- Lays what unit `unit` (slot `index` of `deck`'s floor) was dealt; returns where, or nil, and
	-- the floor it takes with room round it (DealSpot.around), which its coins keep clear of.
	local function lay(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		contents: Deal.Contents
	): (CFrame?, { number }?)
		local size, number, note = shape(deck, index)
		local function at(spot: DealSpot.Spot): CFrame
			return placed(unit, spot)
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
			return place,
				DealSpot.around(
					spot,
					{ across = body.Size.X, along = body.Size.Z, tall = body.Size.Y }
				)
		elseif kind == "Find" then
			-- a find is carried in a slot (S1-05): Slots lays it, standing, with its Take prompt
			local key: string? = contents.find
			local row = if key then Tools.Catalog[key] else nil
			if not (key and row and row.find and Tools.template(key) and slots) then
				return nil -- its art isn't in the place (art/finds/README.md says how to import it)
			end
			local find = Tools.bounds(key)
			local box = { across = find.Size.X, along = find.Size.Z, tall = find.Size.Y }
			local spot = DealSpot.inUnit(size, "Find", box, note, number)
			if not spot then
				return nil
			end
			local place = at(spot)
			local _, yaw = place:ToOrientation()
			slots:lay(key, place.Position, math.deg(yaw))
			return place, DealSpot.around(spot, box)
		elseif kind == "Asleep" or kind == "Awake" then
			local spot = DealSpot.inUnit(size, "Keeper", DealSpot.Keeper, note, number)
			if spot then
				return at(spot), DealSpot.around(spot, DealSpot.Keeper)
			end
			return nil
		end
		return nil
	end

	-- Lays unit `unit`'s coins (S1-04a) in the bulb's pool, clear of `taken` (the floor its tool,
	-- find or keeper takes). Whether they were laid.
	local function layCoins(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		count: number,
		taken: { number }?
	): boolean
		local pile = CoinSpecs.Piles[count]
		if not (pile and coins) then
			return false
		end
		local size, number, note = shape(deck, index)
		local spot = DealSpot.inUnit(
			size,
			"Coins",
			{ across = pile.Size.X, along = pile.Size.Z, tall = pile.Size.Y },
			note,
			number,
			if taken then { taken } else nil
		)
		if not spot then
			return false
		end
		return coins:lay(unit, count, placed(unit, spot))
	end

	-- Stands somebody's stuff (S1-04b2) in unit `unit` with its back to a wall: the thing dealt,
	-- or the next in `Deal.Stuff` that fits (DealSpot.stuffIn), in the unit's hall piece as finds
	-- are, so it goes with the floor. The name stood, or nil if nothing fits or its art is missing.
	local function layStuff(unit: Model, deck: Deal.Deck, index: number, drawn: string): string?
		local size, number, note = shape(deck, index)
		local name, spot = DealSpot.stuffIn(size, Deal.Stuff, drawn, STUFF_SIZES, note, number)
		if not (name and spot) then
			return nil
		end
		local laid = Stuff.lay(name :: Stuff.Name, placed(unit, spot), unit.Parent or unit)
		return if laid then name else nil
	end

	-- Deals `unit` the first time anyone can see into it; after that it holds what it held.
	local function open(unit: Model, player: Player?)
		local entry = units[unit]
		if not entry then
			return
		end
		units[unit] = nil
		local deck, index = entry.deck, entry.index
		local awake = if keepers then keepers:awakeOn(unit) else 0
		local contents = Deal.open(deck, index, { mood = "Build", awake = awake })
		local place, taken = lay(unit, deck, index, contents)
		local paid = contents.coins > 0 and layCoins(unit, deck, index, contents.coins, taken)
		local drawn = contents.stuff
		if drawn then
			-- what stands is what the unit holds: the next that fits, or nothing (said in Output)
			contents.stuff = layStuff(unit, deck, index, drawn)
		end
		if RunService:IsStudio() then
			local laid = if place or contents.kind == "Nothing"
				then ""
				else " (no art yet, so nothing laid)"
			if drawn and not contents.stuff then
				laid ..= ` (its {drawn} fits against no wall, so it's bare)`
			elseif drawn and contents.stuff ~= drawn then
				laid ..= ` (drawn the {drawn}, which doesn't fit)`
			end
			local guard = if index == deck.guarded then ", guarding its note" else ""
			local coinsSaid = if contents.coins == 0
				then ""
				elseif paid then ` and {contents.coins} coins`
				else ` and {contents.coins} coins (not laid)`
			print(`Deals: {unit.Name} held {said(contents)}{coinsSaid}{guard}{laid}`)
		end
		dealt:fire({ unit = unit, contents = contents, place = place, player = player })
	end

	local function onActed(event: Doors.DoorEvent)
		local motion = event.motion
		if motion and LIFTS[motion] then
			open(event.unit, event.player)
		end
	end

	-- A saw's hole going through shows the unit it leads into as a lifted door does (D-067): what
	-- it holds is there as the panel falls, before anyone crawls or drops in.
	local function onSawn(event: Saws.SawEvent)
		if event.done then
			open(event.into, event.player)
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
		coins = (context.registry:get("coins") :: any) :: Coins.CoinsSystem?
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
