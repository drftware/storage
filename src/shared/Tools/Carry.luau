--!strict
--[[
	What one player carries (L-11b, GDD "Tools"; three slots since L-20a): slots for tools, and
	which of them is in your hand, as Lethal Company's slots are (one slot active; what's in it is in
	your hand, an empty slot is an empty hand). The flashlight is outside the slots: everyone has
	one in the other hand.

	Rules only, on ids the server gives each tool: picking up and being handed a tool both put it in
	your hand if your hand is empty, otherwise in a free slot and into your hand (you see what you
	just took); both refuse when every slot is full. Dropping and handing over take the tool in your
	hand. A switch picks a slot and brings its tool up. The tool on your slot can be pocketed (L-20a,
	as Rust's and Red Dead Redemption 2's holstering): still yours and still on that slot, but out of
	your hand, so your hand is empty until you bring it back up. Pure (Lune specs:
	tests/carry.spec.luau); `Slots` (server) does the instances, the checks on the wire and the
	sounds.
]]
local Carry = {}

-- Tools you carry, besides the torch: the GDD's two plus one (owner, Nov 11, L-20; `OWNER.md`), so
-- a climb still asks which three to take. Every screen and the server read this one number.
Carry.Slots = 3
Carry.PickReach = 8 -- studs from your middle to a tool on the floor: about a door's reach
Carry.GiveReach = 10 -- studs to a friend you hand a tool to: an arm's length each, and a step
-- Studs a dropped tool's clank carries as it hits the floor, for friends and keepers alike (L-15):
-- down the hall you're in and a little round its corner, so letting go of a tool near a keeper is
-- a noise you chose, and setting it down two halls off isn't.
Carry.DropHeard = 40
-- The rate a hand moves at: a burst of quick presses (pick up, switch, switch back) goes through,
-- then one per gap. Each gap earns one back.
Carry.Gap = 0.12 -- seconds
Carry.Burst = 4

export type Carry = {
	slots: { [number]: string }, -- slot (1 to `Slots`) to the id of the tool in it
	active: number, -- the slot your hand is on
	pocketed: boolean, -- its tool put away: your hand is empty (never true on an empty slot)
}

function Carry.new(): Carry
	return { slots = {}, active = 1, pocketed = false }
end

-- The id of the tool in your hand, if any (none while it's pocketed).
function Carry.held(c: Carry): string?
	if c.pocketed then
		return nil
	end
	return c.slots[c.active]
end

-- The slot in your hand for the systems that ask what you hold: your slot, or 0 while its tool is
-- pocketed (no slot is in your hand).
function Carry.hand(c: Carry): number
	return if c.pocketed then 0 else c.active
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
-- every slot is full.
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
-- are full or you already carry it. `keep`: you chose what to hold since you reached for it (a
-- box's find lands as its reveal ends, F-G1e6q2), so it goes into a free slot and your hand stays
-- where you put it, unless that's an empty slot it lands in.
function Carry.take(c: Carry, id: string, keep: boolean?): number?
	if Carry.find(c, id) then
		return nil
	end
	local slot = Carry.room(c)
	if slot == nil then
		return nil
	end
	c.slots[slot] = id
	if keep and slot ~= c.active then
		return slot
	end
	c.active = slot
	c.pocketed = false
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

-- Puts slot `slot`'s tool in your hand (or empties your hand, if that slot is empty), brought up
-- if it was pocketed. Returns whether anything changed.
function Carry.select(c: Carry, slot: number): boolean
	if slot == c.active and not c.pocketed then
		return false
	end
	c.active = slot
	c.pocketed = false
	return true
end

-- Pockets the tool on your slot (`down`) or brings it back up into your hand. Returns whether
-- anything changed: an empty slot has nothing to pocket.
function Carry.pocket(c: Carry, down: boolean): boolean
	if down == c.pocketed then
		return false
	end
	if down and c.slots[c.active] == nil then
		return false
	end
	c.pocketed = down
	return true
end

-- Takes the tool in your hand out of the slots (to drop it or hand it over). Returns its id, or
-- nil if your hand is empty. Your hand stays on that slot, now empty, as Lethal Company's does.
function Carry.release(c: Carry): string?
	local id = Carry.held(c)
	if id == nil then
		return nil
	end
	c.slots[c.active] = nil
	return id
end

-- Takes `id` out of whichever slot it's in (a worn-out tool breaking, S1-08). Your hand stays on
-- its slot, as `release` leaves it. Whether it was there.
function Carry.remove(c: Carry, id: string): boolean
	local slot = Carry.find(c, id)
	if slot == nil then
		return false
	end
	c.slots[slot] = nil
	if c.pocketed and c.slots[c.active] == nil then
		c.pocketed = false -- nothing left on your slot to have pocketed
	end
	return true
end

-- Empties every slot (you died or left): every id, slot order.
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
	c.pocketed = false
	return out
end

-- Takes every find out of the slots (S1-06: the gate shut with you aboard, so they're yours for
-- good), leaving the tools where they are. Returns the finds' ids, slot order. Your hand stays on
-- its slot, as `release` leaves it: empty, if a find was in it.
function Carry.keep(c: Carry, isFind: (id: string) -> boolean): { string }
	local out = {}
	for i = 1, Carry.Slots do
		local id = c.slots[i]
		if id and isFind(id) then
			table.insert(out, id)
			c.slots[i] = nil
		end
	end
	if c.pocketed and c.slots[c.active] == nil then
		c.pocketed = false -- nothing left on your slot to have pocketed
	end
	return out
end

-- What a thing in your slots is worth to the Packrat (S2-06c), from its catalog row: a find's
-- worth in cash (F-G1a, the item catalog's), the glass lamp before the teddy; a find without one
-- by its heft; a tool 0, worth taking only with no find; nil for what it leaves (both hands'
-- things: the ladder on your shoulder, the big find), or no row.
function Carry.worth(
	row: { find: boolean?, heft: number?, bothHands: boolean?, worth: number? }?
): number?
	if not row or row.bothHands then
		return nil
	elseif not row.find then
		return 0
	end
	return math.max(row.worth or row.heft or 0, 0.01)
end

-- The slot the Packrat takes from when it reaches you (S2-06c, GDD "What counts as something to
-- carry"): `keys` are your slots' catalog keys ("" or nil empty), `hand` the slot you're on, and
-- `worth` says each one's (`Carry.worth`'s rule). The most valuable find, else a tool, the one in
-- your hand when it's a tie; never what `worth` leaves. Your flashlight isn't in a slot. 0: nothing
-- it takes, so it catches you.
function Carry.prize(keys: { string }, hand: number, worth: (key: string) -> number?): number
	local best, most = 0, -1
	for i = 1, Carry.Slots do
		local key = keys[i]
		if key and key ~= "" then
			local w = worth(key)
			if w and (w > most or (w == most and i == hand)) then
				best, most = i, w
			end
		end
	end
	return best
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
