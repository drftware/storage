--!strict
--[[
	What one player carries (L-11b, GDD "Tools"): two slots for tools, and which of them is in your
	hand, as Lethal Company's slots are (one slot active; what's in it is in your hand, an empty slot
	is an empty hand). The flashlight is outside the slots: everyone has one in the other hand.

	Rules only, on ids the server gives each tool: picking up and being handed a tool both put it in
	your hand if your hand is empty, otherwise in your other slot and into your hand (you see what
	you just took); both refuse when both slots are full. Dropping and handing over take the tool in
	your hand. A switch picks a slot. Pure (Lune specs: tests/carry.spec.luau); `Slots` (server) does
	the instances, the checks on the wire and the sounds.
]]
local Carry = {}

Carry.Slots = 2 -- tools you carry, besides the torch (GDD: "two tools plus whatever's in your hands")
Carry.PickReach = 8 -- studs from your middle to a tool on the floor: about a door's reach
Carry.GiveReach = 10 -- studs to a friend you hand a tool to: an arm's length each, and a step
-- The rate a hand moves at: a burst of quick presses (pick up, switch, switch back) goes through,
-- then one per gap. Each gap earns one back.
Carry.Gap = 0.12 -- seconds
Carry.Burst = 4

export type Carry = {
	slots: { [number]: string }, -- slot (1 or 2) to the id of the tool in it
	active: number, -- the slot in your hand
}

function Carry.new(): Carry
	return { slots = {}, active = 1 }
end

-- The id of the tool in your hand, if any.
function Carry.held(c: Carry): string?
	return c.slots[c.active]
end

-- How many tools you carry.
function Carry.count(c: Carry): number
	local n = 0
	for i = 1, Carry.Slots do
		if c.slots[i] then
			n += 1
		end
	end
	return n
end

-- The slot a new tool would go into: your hand's if it's empty, else the first free one. Nil when
-- both are full.
function Carry.room(c: Carry): number?
	if c.slots[c.active] == nil then
		return c.active
	end
	for i = 1, Carry.Slots do
		if c.slots[i] == nil then
			return i
		end
	end
	return nil
end

-- The slot holding `id`, if any.
function Carry.find(c: Carry, id: string): number?
	for i = 1, Carry.Slots do
		if c.slots[i] == id then
			return i
		end
	end
	return nil
end

-- Takes `id` (picked up or handed over) into your hand. Returns its slot, or nil when your hands
-- are full or you already carry it.
function Carry.take(c: Carry, id: string): number?
	if Carry.find(c, id) then
		return nil
	end
	local slot = Carry.room(c)
	if slot == nil then
		return nil
	end
	c.slots[slot] = id
	c.active = slot
	return slot
end

-- A slot from the wire: a whole number from 1 to `Slots`. Nil if it isn't one.
function Carry.slot(value: unknown): number?
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
		return nil
	end
	if value < 1 or value > Carry.Slots then
		return nil
	end
	return value
end

-- Puts slot `slot`'s tool in your hand (or empties your hand, if that slot is empty). Returns
-- whether anything changed.
function Carry.select(c: Carry, slot: number): boolean
	if slot == c.active then
		return false
	end
	c.active = slot
	return true
end

-- Takes the tool in your hand out of the slots (to drop it or hand it over). Returns its id, or
-- nil if your hand is empty. Your hand stays on that slot, now empty, as Lethal Company's does.
function Carry.release(c: Carry): string?
	local id = c.slots[c.active]
	if id == nil then
		return nil
	end
	c.slots[c.active] = nil
	return id
end

-- Empties both slots (you died or left): every id, slot order.
function Carry.clear(c: Carry): { string }
	local out = {}
	for i = 1, Carry.Slots do
		local id = c.slots[i]
		if id then
			table.insert(out, id)
			c.slots[i] = nil
		end
	end
	c.active = 1
	return out
end

-- May a hand's move at `now` go through after the last ones? `burst` is how many are left in
-- hand; returns whether it may and what's left.
function Carry.allow(last: number?, burst: number, now: number): (boolean, number)
	if last == nil then
		return true, Carry.Burst - 1
	end
	local earned = math.floor((now - last) / Carry.Gap)
	local have = math.min(Carry.Burst, burst + math.max(earned, 0))
	if have <= 0 then
		return false, 0
	end
	return true, have - 1
end

return Carry
