--!strict
--[[
	Deals: the deal on the floor (L-04e). Every door is a gamble, and this is where it's settled.
	A laid floor already has its code's notes stuck and its padlocked doors padlocked (FloorBuilder,
	from the floor's deck); this deals each unit the first time anyone can see into it, its door
	lifting (a peek or an open) or a saw's hole going through its wall or top (D-067),
	and lays what it holds before anyone sees in, so even a peek shows it: its one marked box behind
	the bulb holding its find or tool, unseen until someone opens it (MarkedBoxes, B-03a), or, for
	a find or tool too big for a box (`Deal.packs`), the thing itself loose on the floor (Slots);
	or the place a keeper stands, which `dealt` hands on (Keepers stands the keeper there); in a
	unit with nothing to take, sometimes
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
local Workspace = game:GetService("Workspace")

local Batteries = require(script.Parent.Batteries)
local BatterySpecs = require(ReplicatedStorage.Shared.Battery.Specs)
local Brix = require(ReplicatedStorage.Brix)
local CoinSpecs = require(ReplicatedStorage.Shared.Coins.Specs)
local Coins = require(script.Parent.Coins)
local CrawlHoleSpecs = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Specs)
local Deal = require(ReplicatedStorage.Shared.Deal)
local DealSpot = require(ReplicatedStorage.Shared.DealSpot)
local Doors = require(script.Parent.Doors)
local BoxSpecs = require(ReplicatedStorage.Shared.Boxes.Specs)
local FloorBuilder = require(script.Parent.FloorBuilder)
local MarkedBoxes = require(script.Parent.MarkedBoxes)
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
-- Studio only, for seeing any find's or tool's reveal: Workspace's `DevBox` set to a catalog key
-- deals the next unit that opens that, in its marked box even if it's too big for one (so the
-- lamps' gold and red reveals can be seen), in place of what it was dealt; then goes back to false.
local DEV_BOX = "DevBox"
-- The marked box (B-03a): its size for `Deal.packs`, and its footprint as DealSpot measures it.
local BOX = BoxSpecs.Marked.Size
local BOX_SIZE = { BOX.X, BOX.Y, BOX.Z }
local BOX_FOOTPRINT: DealSpot.Size = { across = BOX.X, along = BOX.Z, tall = BOX.Y }
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
	-- feet, or the middle of the bottom of the marked box its find or tool waits in, B-03a); nil
	-- when nothing was laid (nothing behind the door, or a tool not built yet)
	place: CFrame?,
	-- where the unit's keeper stands, feet on the floor, facing as laid: `place` for a unit that
	-- holds only a keeper, its own spot for one standing with a padlocked unit's find or tool
	-- (S1-07a); nil for none, or none with room to stand
	keeper: CFrame?,
	-- the middle of the Packrat's pile on the floor (S2-06b2b), the finds of its own laid round
	-- its feet; nil in any other unit, or with none laid
	pile: Vector3?,
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
	-- Deals unit `unit` now though its door is still shut (S2-03b): a sleeper behind it is waking,
	-- so it must stand where the deal lays it. Whether it was still to be dealt.
	dealShut: (self: any, unit: Model) -> boolean,
}

type Entry = { deck: Deal.Deck, index: number }

-- What the deal asks the keepers' brain. Keepers needs this module's `Dealt`, so this looks it up
-- by its slot rather than requiring it.
type Awake = { awakeOn: (self: any, unit: Model) -> number }

-- The door motions that first show a unit's inside: a peek, an open, a lift from inside.
local LIFTS = { Peek = true, Open = true, LiftInside = true } :: { [string]: boolean }

-- Somebody's stuff as a tester would say it, for Output in Studio.
-- Degrees each find of the Packrat's pile turns off how DealSpot stands it (S2-06b2b), in turn:
-- a heap dumped at its feet, each still facing about the doorway so you know it from there. Small
-- enough that the widest find (the boombox, 2.3 across) turned so reaches no more than 0.25 studs
-- further: inside the room `DealSpot.around` keeps round it, and short of a wall's ribs.
local PILE_TILT = { -10, 8, 13 }

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
	local with = if contents.beside
		then `, the {contents.keeper} standing with it, {string.lower(contents.beside)}`
		else ""
	if kind == "Tool" then
		return `a tool, {contents.tool}{with}`
	elseif kind == "Find" then
		return `a find, the {contents.find}{with}`
	elseif kind == "Asleep" or kind == "Awake" then
		local pile = contents.pile
		local among = if pile then `, among its pile: {table.concat(pile, ", ")}` else ""
		return `the {contents.keeper}, {string.lower(kind)}{among}`
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
	local batteries: Batteries.Batteries? = nil
	local keepers: Awake? = nil
	local markedBoxes: MarkedBoxes.MarkedBoxes? = nil

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

	-- Stands unit `unit`'s one marked box (B-03a) holding `key`, a find or tool, if it packs into
	-- one (`Deal.packs`; `forced`, Studio's `DevBox`, whatever its size), where a find would stand:
	-- behind the bulb, facing the doorway. Where it stands and the floor it takes, or nil if it
	-- doesn't pack or can't stand (no room, no template), and the thing is laid loose instead.
	local function layBoxed(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		key: string,
		forced: boolean
	): (CFrame?, { number }?)
		local boxes = markedBoxes
		local body = Tools.bounds(key).Size
		if not (boxes and (forced or Deal.packs({ body.X, body.Y, body.Z }, BOX_SIZE))) then
			return nil, nil
		end
		local size, number, note = shape(deck, index)
		local spot = DealSpot.inUnit(size, "Find", BOX_FOOTPRINT, note, number)
		if not spot then
			return nil, nil
		end
		local place = placed(unit, spot)
		if not boxes:stand(unit, place, key) then
			return nil, nil
		end
		return place, DealSpot.around(spot, BOX_FOOTPRINT)
	end

	-- Lays what unit `unit` (slot `index` of `deck`'s floor) was dealt, its tool, find or keeper;
	-- returns where, or nil, and the floor it takes with room round it (DealSpot.around), which a
	-- keeper standing with it and the unit's coins keep clear of; for a keeper, its spot; and
	-- whether its find or tool waits in a marked box. `forced`: Studio's `DevBox` (`layBoxed`).
	local function layOne(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		contents: Deal.Contents,
		forced: boolean
	): (CFrame?, { number }?, DealSpot.Spot?, boolean)
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
				return nil, nil, nil, false
			end
			local boxed, area = layBoxed(unit, deck, index, key, forced)
			if boxed then
				return boxed, area, nil, true
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
				return nil, nil, nil, false
			end
			local place = at(spot)
			local _, yaw = place:ToOrientation()
			slots:lay(key, place.Position, math.deg(yaw))
			return place,
				DealSpot.around(
					spot,
					{ across = body.Size.X, along = body.Size.Z, tall = body.Size.Y }
				),
				nil,
				false
		elseif kind == "Find" then
			-- in its box if it packs (`layBoxed`); else carried in a slot (S1-05): Slots lays it,
			-- standing, with its Take prompt
			local key: string? = contents.find
			local row = if key then Tools.Catalog[key] else nil
			if not (key and row and row.find and Tools.template(key) and slots) then
				-- its art isn't in the place (art/finds/README.md says how to import it)
				return nil, nil, nil, false
			end
			local boxed, area = layBoxed(unit, deck, index, key, forced)
			if boxed then
				return boxed, area, nil, true
			end
			local find = Tools.bounds(key)
			local box = { across = find.Size.X, along = find.Size.Z, tall = find.Size.Y }
			local spot = DealSpot.inUnit(size, "Find", box, note, number)
			if not spot then
				return nil, nil, nil, false
			end
			local place = at(spot)
			local _, yaw = place:ToOrientation()
			slots:lay(key, place.Position, math.deg(yaw))
			return place, DealSpot.around(spot, box), nil, false
		elseif kind == "Asleep" or kind == "Awake" then
			if contents.pile then
				-- the Packrat (S2-06b2b): at the back, the floor it takes reaching ahead of its feet
				-- where its long hands hang, so its pile lies clear of them
				local spot = DealSpot.inUnit(
					size,
					"Keeper",
					DealSpot.Packrat,
					note,
					number,
					nil,
					{ 0, size.depth }
				)
				if spot then
					local ahead = DealSpot.PackratAhead
					local middle = { x = spot.x, z = spot.z - ahead, yaw = spot.yaw }
					return at(spot), DealSpot.around(middle, DealSpot.Packrat), spot, false
				end
				return nil, nil, nil, false
			end
			local spot = DealSpot.inUnit(size, "Keeper", DealSpot.Keeper, note, number)
			if spot then
				return at(spot), DealSpot.around(spot, DealSpot.Keeper), spot, false
			end
			return nil, nil, nil, false
		end
		return nil, nil, nil, false
	end

	-- Lays the Packrat's pile (S2-06b2b) at its feet, standing at `spot` in unit `unit`, each find
	-- as near the floor just ahead of its hands as fits, clear of `taken` (which each joins), and
	-- turned a little off square, so it reads as dumped there, not shelved. The pile's middle, or
	-- nil if none fits.
	local function layPile(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		pile: { string },
		spot: DealSpot.Spot,
		taken: { { number } }
	): Vector3?
		local s = slots
		if not s then
			return nil
		end
		local size, number, note = shape(deck, index)
		local feet = { spot.x, spot.z - DealSpot.PackratAhead - DealSpot.Packrat.along }
		local sum, laid = Vector3.zero, 0
		for n, key in pile do
			local row = Tools.Catalog[key]
			if not (row and row.find and Tools.template(key)) then
				continue -- its art isn't in the place
			end
			local find = Tools.bounds(key)
			local box = { across = find.Size.X, along = find.Size.Z, tall = find.Size.Y }
			local at = DealSpot.inUnit(size, "Find", box, note, number, taken, feet)
			if at then
				table.insert(taken, DealSpot.around(at, box))
				local place = placed(unit, at)
				local _, yaw = place:ToOrientation()
				s:lay(key, place.Position, math.deg(yaw) + PILE_TILT[(n - 1) % #PILE_TILT + 1])
				sum += place.Position
				laid += 1
			end
		end
		return if laid > 0 then sum / laid else nil
	end

	-- Lays all a unit was dealt but its coins and stuff: what it holds (`layOne`), then a keeper
	-- standing with a padlocked unit's find or tool (S1-07a), behind the bulb where it fits, clear
	-- of the find or its box. Returns where the find, tool, box or keeper lies, where the keeper
	-- stands, the floor they take (which the coins keep clear of), the Packrat's pile's middle,
	-- and whether the find or tool waits in a marked box.
	local function lay(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		contents: Deal.Contents,
		forced: boolean
	): (CFrame?, CFrame?, { { number } }, Vector3?, boolean)
		local place, area, spot, boxed = layOne(unit, deck, index, contents, forced)
		local taken: { { number } } = if area then { area } else {}
		if Deal.keeperIn(contents) == nil then
			return place, nil, taken, nil, boxed
		elseif not contents.beside then
			local pile = contents.pile
			local middle = if pile and spot
				then layPile(unit, deck, index, pile, spot, taken)
				else nil
			return place, place, taken, middle, boxed
		end
		local size, number, note = shape(deck, index)
		local beside = DealSpot.inUnit(size, "Keeper", DealSpot.Keeper, note, number, taken)
		if not beside then
			return place, nil, taken, nil, boxed
		end
		table.insert(taken, DealSpot.around(beside, DealSpot.Keeper))
		return place, placed(unit, beside), taken, nil, boxed
	end

	-- Lays unit `unit`'s coins (S1-04a) in the bulb's pool, clear of `taken` (the floor its tool,
	-- find and keeper take). Whether they were laid, and the floor they take.
	local function layCoins(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		count: number,
		taken: { { number } }
	): (boolean, { number }?)
		local pile = CoinSpecs.Piles[count]
		if not (pile and coins) then
			return false, nil
		end
		local size, number, note = shape(deck, index)
		local footprint = { across = pile.Size.X, along = pile.Size.Z, tall = pile.Size.Y }
		local spot = DealSpot.inUnit(size, "Coins", footprint, note, number, taken)
		if not spot then
			return false, nil
		end
		return coins:lay(unit, count, placed(unit, spot)), DealSpot.around(spot, footprint)
	end

	-- Lays unit `unit`'s battery (S1-07b) on its side in the bulb's pool, clear of `taken` (the
	-- floor its tool, find, keeper and coins take). Whether it was laid.
	local function layBattery(
		unit: Model,
		deck: Deal.Deck,
		index: number,
		taken: { { number } }
	): boolean
		if not batteries then
			return false
		end
		local size, number, note = shape(deck, index)
		local cell = BatterySpecs.Battery.Size
		-- lying along the spot's X: its length across, its width along and up
		local footprint = { across = cell.Y, along = cell.X, tall = cell.X }
		local spot = DealSpot.inUnit(size, "Battery", footprint, note, number, taken)
		if not spot then
			return false
		end
		return batteries:lay(unit, placed(unit, spot))
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

	-- Studio's `DevBox` (above): deals `contents` the find or tool it names, in place of what
	-- the unit was dealt. Whether it did.
	local function devDeal(contents: Deal.Contents): boolean
		local asked = if RunService:IsStudio() then Workspace:GetAttribute(DEV_BOX) else nil
		if type(asked) ~= "string" or asked == "" then
			return false
		end
		Workspace:SetAttribute(DEV_BOX, false)
		local row = Tools.Catalog[asked]
		if not (row and Tools.template(asked)) then
			warn(`Deals: DevBox "{asked}" names no find or tool with its art in the place`)
			return false
		end
		contents.kind = if row.find then "Find" else "Tool"
		contents.find = if row.find then asked else nil
		-- any: a catalog key that isn't a find is a tool's (Deal.Tool's strings)
		contents.tool = if row.find then nil else (asked :: any) :: Deal.Tool
		contents.keeper, contents.beside, contents.pile, contents.stuff = nil, nil, nil, nil
		return true
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
		local dev = devDeal(contents)
		local place, keeper, taken, pileAt, boxed = lay(unit, deck, index, contents, dev)
		local paid, pile = false, nil
		if contents.coins > 0 then
			paid, pile = layCoins(unit, deck, index, contents.coins, taken)
		end
		if pile then
			table.insert(taken, pile)
		end
		local charged = contents.battery == true and layBattery(unit, deck, index, taken)
		local drawn = contents.stuff
		if drawn then
			-- what stands is what the unit holds: the next that fits, or nothing (said in Output)
			contents.stuff = layStuff(unit, deck, index, drawn)
		end
		if RunService:IsStudio() then
			local held = said(contents) .. if boxed then " in its box" else ""
			local laid = if boxed
					or place
					or contents.kind == "Nothing"
				then ""
				else " (no art yet, so nothing laid)"
			if dev then
				laid ..= " (DevBox)"
			end
			if contents.beside and not keeper then
				laid ..= " (no room for its keeper, so it stands nowhere)"
			end
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
			local batterySaid = if not contents.battery
				then ""
				elseif charged then " and a battery"
				else " and a battery (not laid)"
			print(`Deals: {unit.Name} held {held}{coinsSaid}{batterySaid}{guard}{laid}`)
		end
		dealt:fire({
			unit = unit,
			contents = contents,
			place = place,
			keeper = keeper,
			pile = pileAt,
			player = player,
		})
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
		batteries = (context.registry:get("batteries") :: any) :: Batteries.Batteries?
		keepers = (context.registry:get("keepers") :: any) :: Awake?
		markedBoxes = (context.registry:get("markedBoxes") :: any) :: MarkedBoxes.MarkedBoxes?
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

	function system.dealShut(_: any, unit: Model): boolean
		if not units[unit] then
			return false
		end
		open(unit, nil)
		return true
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
