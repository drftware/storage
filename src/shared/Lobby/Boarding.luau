--!strict
--[[
	Boarding: a lobby car's group and its count (L-08e1b1, GDD "The lobby", D-112), as DOORS' lobby
	elevators do. Step through a car's gate and you're in its group; step back out and you've left
	it. The first step in starts the count, 20 s; once six are aboard it drops to 5. At zero the
	gate shuts with the climb's own ratchet and slam, and whoever is inside as it hits its post
	rides up to floor 1. Pure, so Lune checks it; the server keeps the groups (LobbyCars), the
	climb's gate and clock machinery does the rest (Elevators, Departure).

	Two replicated values on a lobby car:
	- `CarAttribute`: its bay, 1 to 6. Marks it a lobby car: its keypad never wakes, and its clock
	  shows only on the screens of those aboard.
	- `GroupAttribute`: the UserIds aboard, in the order they stepped in. Absent when it's empty.
]]
local Departure = require("../Elevator/Departure")

local Boarding = {}

-- How a readout cell is lit: Readout.Tone's four, spelled out here as a cross-folder require's
-- types don't reach every screen's checker.
export type Tone = "Off" | "Rest" | "Lit" | "Right"

Boarding.CarAttribute = "LobbyCar"
Boarding.GroupAttribute = "Group"

-- Seconds the count runs from the first step in: the GDD's 20, DOORS' lobby wait. Long enough to
-- wave a friend over from the door (under 3 s at a run) and let them pick the car; short enough
-- that nobody stands about.
Boarding.Seconds = 20
-- Once the car is full the count drops to this: everyone's in, so go.
Boarding.FullSeconds = 5
-- Players a car takes: the climb's party (GDD, 1 to 6).
Boarding.Capacity = 6
-- Seconds you must be out of the car before you've left it: a heel over the sill as you turn
-- doesn't drop you from the group and chime you back in.
Boarding.LeaveGrace = 0.35
-- Seconds after it left that a car stands open in its bay again, empty, for the next group: the
-- ride up (Ride.opens, about 10 s) and a beat for those who rode to be on floor 1.
Boarding.Back = 12

export type Car = {
	group: { number }, -- UserIds, in the order they stepped in
	departs: number?, -- server time the gate starts to shut; nil while nobody's aboard
}

function Boarding.new(): Car
	return { group = {}, departs = nil }
end

-- Whether the count has run out at server time `t`: the gate is shutting or gone, and the group
-- is what it is (whoever is inside at the post rides).
function Boarding.shutting(car: Car, t: number): boolean
	local departs = car.departs
	return departs ~= nil and t >= departs
end

-- `id` steps in at `t`. False (nothing changes) if they're in already, the car is full, or its
-- gate is shutting. The first one in starts the count; the one who fills it cuts it to
-- `FullSeconds`, unless less is left already.
function Boarding.join(car: Car, id: number, t: number): boolean
	if
		table.find(car.group, id)
		or #car.group >= Boarding.Capacity
		or Boarding.shutting(car, t)
	then
		return false
	end
	table.insert(car.group, id)
	local departs = car.departs or t + Boarding.Seconds
	if #car.group >= Boarding.Capacity then
		departs = math.min(departs, t + Boarding.FullSeconds)
	end
	car.departs = departs
	return true
end

-- `id` steps out at `t`. False if they weren't in or the gate is shutting. The count runs on
-- (it never climbs back up); the last one out stops it.
function Boarding.leave(car: Car, id: number, t: number): boolean
	local i = table.find(car.group, id)
	if not i or Boarding.shutting(car, t) then
		return false
	end
	table.remove(car.group, i)
	if #car.group == 0 then
		car.departs = nil
	end
	return true
end

-- Starts the count again at `t` for a car whose count was held (while another group's climb ran
-- on this server, L-08e1b1's stand-in): the full count, or `FullSeconds` if it's full. Nothing
-- for an empty car or one already counting.
function Boarding.resume(car: Car, t: number)
	if car.departs or #car.group == 0 then
		return
	end
	local full = #car.group >= Boarding.Capacity
	car.departs = t + (if full then Boarding.FullSeconds else Boarding.Seconds)
end

-- Who rides, of those `inside` (UserIds) as the gate hits its post: the group first, in the order
-- they stepped in, then anyone who dived in under the shutting gate, up to `Capacity`.
function Boarding.riders(group: { number }, inside: { number }): { number }
	local out: { number } = {}
	for _, id in group do
		if #out < Boarding.Capacity and table.find(inside, id) then
			table.insert(out, id)
		end
	end
	for _, id in inside do
		if #out < Boarding.Capacity and not table.find(out, id) then
			table.insert(out, id)
		end
	end
	return out
end

-- The group as its replicated value, or nil for an empty one.
function Boarding.encode(group: { number }): string?
	if #group == 0 then
		return nil
	end
	local parts = table.create(#group)
	for i, id in group do
		parts[i] = string.format("%d", id)
	end
	return table.concat(parts, ",")
end

-- The group from its value. A missing or broken value is empty.
function Boarding.decode(value: unknown): { number }
	local ids: { number } = {}
	if type(value) ~= "string" then
		return ids
	end
	for id in string.gmatch(value, "%d+") do
		table.insert(ids, tonumber(id) :: number)
	end
	return ids
end

-- The car's readout (the keypad's four LED digits beside its gate), cell `i`, with `left` seconds
-- on the count (nil while nobody's aboard): dim dashes at rest, as the climb's keypad; the count
-- in the middle two cells, green, then red from the warning as the gate clock turns; 0 once it's
-- shutting.
function Boarding.readout(left: number?, i: number): (string, Tone)
	if left == nil then
		return "-", "Rest"
	end
	if i == 1 or i == 4 then
		return " ", "Off"
	end
	local text = Departure.text(math.max(left, 0))
	local char = string.sub(text, i - 1, i - 1)
	if char == " " then
		return " ", "Off"
	end
	return char, if left > Departure.Warning then "Right" else "Lit"
end

return Boarding
