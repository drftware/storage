--!strict
--[[
	BigFinds (S4-05b1, D-415, GDD "The big find"): the floor's big find, a system. The moment it
	serves: the code goes into the keypad, and down the hall a unit nobody has touched rolls up by
	itself with its loud rattle, and there in the dark stands the jukebox, taller than you, as
	Lethal Company's apparatus waits in its socket for the crew brave enough to haul it out.

	- As each floor from `BigFind.From` is laid (Climbs' `laid`), its two rolls are drawn from the
	  floor's own seed (never the deal's, so they move nothing else a seed lays): what it will be,
	  a grade and a find (`BigFind.findFrom`), and which of the units left it goes into.
	- The right code on that floor's keypad (Elevators' `acted`, "Right"): of the units still shut
	  and to be dealt (Deals' `waiting`, so never one searched or holding a caught friend), the
	  pick chooses one that fits (`BigFind.unitFrom`), the deck is told (`deck.big`, so its deal is
	  the big find alone) and the building rolls its door up (Doors' `move` "Open": its rattle
	  heard down the halls, by keepers too). Its first lift deals it, and Deals stands the find
	  in it with its Take prompt, too big for any box.
	- Its slot goes on the floor's model (`BigFind.SlotAttribute`) for the corner map, and from then
	  on where it is (S4-05b2b): as anyone's slots or the finds lying loose change (Slots' `changed`,
	  `loose`), the floor point it lies on (`BigFind.AtAttribute`) or who hauls it
	  (`BigFind.HolderAttribute`), so MinimapView's mark follows it; all three go as it's kept at
	  the gate, lost or lifted by a monster, and the point comes back where a monster lays it down.
	- As the gate shuts, GatePay asks who holds it (`aboard`, S4-05b3): it counts, and pays
	  everyone aboard, only in a rider's arms; anywhere else it's left behind with the floor.

	Every value is the server's; nothing here listens to a client.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BigFind = require(ReplicatedStorage.Shared.BigFind)
local Brix = require(ReplicatedStorage.Brix)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Climbs = require(script.Parent.Climbs)
local Deals = require(script.Parent.Deals)
local Doors = require(script.Parent.Doors)
local Elevators = require(script.Parent.Elevators)
local Slots = require(script.Parent.Slots)

-- Mixed into a floor's seed for its big find's rolls, so they never repeat the deal's or the
-- keepers' draws from the same seed.
local SALT = 4051

local STUDIO = RunService:IsStudio()

-- Studs from its unit's pivot a lying find of its key may stand and be the one its unit dealt
-- (the deepest unit is under 20 deep).
local DEALT_NEAR = 24

type Entry = {
	on: Climbs.OnFloor,
	find: string, -- the big find's key
	pick: number, -- which unit, 0 to 1, among those that fit as the code goes in
	placed: boolean,
	unit: Model?, -- the unit it rolled up in
	model: Model?, -- the find itself once its unit has dealt it, in a hand or on a floor (Slots')
	gone: RBXScriptConnection,
}

local BigFinds = {}

-- A floor's big find as its gate shuts (S4-05b3): its key, and who holds it (nil: nobody, so
-- it's left behind on the floor, in a monster's arms or gone).
export type Shut = { key: string, holder: Player? }

export type BigFinds = Brix.System & {
	-- The big find out on floor `floor` (its model) as its gate shuts; nil while it has none out
	-- (floor 1, no unit was left for it, or the code never went in).
	aboard: (self: any, floor: Model) -> Shut?,
}

function BigFinds.new(): BigFinds
	local entries: { [Model]: Entry } = {}
	local signals: { Brix.SignalConnection } = {}
	local built: { BigFind.Find } = {}
	local doors: Doors.Doors? = nil
	local deals: Deals.Deals? = nil
	local slots: Slots.Slots? = nil

	local function onLaid(on: Climbs.OnFloor)
		if not BigFind.on(on.number) or entries[on.model] then
			return
		end
		local random = Brix.Random.new({ seed = on.seed * 7 + SALT })
		local roll, which, pick = random:nextNumber(), random:nextNumber(), random:nextNumber()
		local find = BigFind.findFrom(roll, which, built)
		if not find then
			return -- no big find's art in the place (said as the server started)
		end
		local model = on.model
		entries[model] = {
			on = on,
			find = find,
			pick = pick,
			placed = false,
			gone = model.Destroying:Connect(function()
				local e = entries[model]
				if e then
					e.gone:Disconnect()
					entries[model] = nil
				end
			end),
		}
	end

	-- Where `e`'s find is now, on its floor's model for the corner map: hauled, lying, or neither
	-- (kept, lost, in a monster's arms). The new one is set before the old is cleared, so a
	-- screen reading between the two never sees it back in its unit.
	local function track(e: Entry)
		local s, unit = slots, e.unit
		if not (s and unit) then
			return
		end
		if not e.model then
			-- dealt yet? its key lying in its unit (Deals stands it there on the door's first lift)
			local middle = unit:GetPivot().Position
			s:finds(function(_n: number, at: Vector3, m: Model)
				if
					e.model == nil
					and m:GetAttribute(Tools.KindAttribute) == e.find
					and (at - middle).Magnitude <= DEALT_NEAR
				then
					for _, other in entries do
						if other.model == m then
							return
						end
					end
					e.model = m
				end
			end)
		end
		local model = e.model
		if not model then
			return -- not dealt yet: the map marks its unit
		end
		local floor = e.on.model
		local holder = Players:GetPlayerFromCharacter(model.Parent)
		if holder then
			floor:SetAttribute(BigFind.HolderAttribute, holder.UserId)
			floor:SetAttribute(BigFind.AtAttribute, nil)
			return
		end
		local lying: Vector3? = nil
		s:finds(function(_n: number, at: Vector3, m: Model)
			if m == model then
				lying = at
			end
		end)
		if lying then
			floor:SetAttribute(BigFind.AtAttribute, lying)
			floor:SetAttribute(BigFind.HolderAttribute, nil)
			return
		end
		floor:SetAttribute(BigFind.SlotAttribute, nil)
		floor:SetAttribute(BigFind.AtAttribute, nil)
		floor:SetAttribute(BigFind.HolderAttribute, nil)
	end

	local function trackAll()
		for _, e in entries do
			track(e)
		end
	end

	-- The code is in: its unit rolls up with the big find standing inside.
	local function place(e: Entry)
		local d, dl = doors, deals
		if e.placed or not (d and dl) then
			return
		end
		e.placed = true
		local on = e.on
		local byIndex: { [number]: Model } = {}
		for unit, index in on.laid.slots do
			byIndex[index] = unit
		end
		local open: { number } = {}
		for _, index in Deal.units(on.floor) do
			local unit = byIndex[index]
			if unit and dl:waiting(unit) and d:stateOf(unit) == "Closed" then
				table.insert(open, index)
			end
		end
		local index = BigFind.unitFrom(on.deck, open, e.pick)
		local unit = if index then byIndex[index] else nil
		if not (index and unit) then
			if STUDIO then
				print(`BigFinds: floor {on.number} has no unit left for its {e.find}`)
			end
			return
		end
		on.deck.big[index] = e.find
		if not d:move(unit, "Open") then
			on.deck.big[index] = nil -- its door wouldn't lift: no big find this floor
			warn(`BigFinds: {unit.Name}'s door wouldn't roll up for floor {on.number}'s {e.find}`)
			return
		end
		e.unit = unit
		on.model:SetAttribute(BigFind.SlotAttribute, index)
		if STUDIO then
			print(`BigFinds: floor {on.number}'s {e.find} rolls up in {unit.Name}`)
		end
		track(e)
	end

	local function onKeypad(event: Elevators.KeypadEvent)
		if event.action ~= "Right" then
			return
		end
		for _, e in entries do
			if e.on.elevator == event.elevator then
				place(e)
				return
			end
		end
	end

	local system = { name = "BigFinds" }

	function system.aboard(_: any, floor: Model): Shut?
		local e = entries[floor]
		if not (e and e.unit) then
			return nil
		end
		if not e.model then
			track(e) -- dealt since anyone's slots last changed
		end
		local model = e.model
		local holder = if model and model.Parent
			then Players:GetPlayerFromCharacter(model.Parent)
			else nil
		return { key = e.find, holder = holder }
	end

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		doors = (registry:get("doors") :: any) :: Doors.Doors
		deals = (registry:get("deals") :: any) :: Deals.Deals -- any: as above
		local climbs = (registry:get("climbs") :: any) :: Climbs.Climbs -- any: as above
		local elevators = (registry:get("elevators") :: any) :: Elevators.Elevators -- any: as above
		local s = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
		slots = s
		-- only the big finds whose art is in the place, and the catalog can carry
		for _, f in BigFind.Finds do
			if Tools.Catalog[f.key] and Tools.template(f.key) then
				table.insert(built, f)
			else
				warn(`BigFinds: no art in the place for {f.key}, so no floor deals it`)
			end
		end
		table.insert(signals, climbs.laid:connect(onLaid))
		table.insert(signals, elevators.acted:connect(onKeypad))
		table.insert(signals, s.changed:connect(trackAll))
		table.insert(signals, s.loose:connect(trackAll))
	end

	function system.stop(_: any)
		for _, s in signals do
			s:disconnect()
		end
		table.clear(signals)
		for _, e in entries do
			e.gone:Disconnect()
		end
		table.clear(entries)
	end

	return system
end

return BigFinds
