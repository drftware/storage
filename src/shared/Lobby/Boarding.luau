--!strict
--[[
	Boarding: a lobby car's group and its count (L-08e1b1, GDD "The lobby", D-112), as DOORS' lobby
	elevators do. Step through a car's gate and you're in its group; step back out and you've left
	it. The first step in starts the count, 20 s; once six are aboard it drops to 5. At zero the
	gate shuts with the climb's own ratchet and slam, and whoever is inside as it hits its post
	rides up to floor 1. Pure, so Lune checks it; the server keeps the groups (LobbyCars), the
	climb's gate and clock machinery does the rest (Elevators, Departure).

	The first one in hosts (L-08e1b2), as DOORS' lobby elevators: on the car's panel they pick
	Open or Friends only and 1 to 6 players, and can press Go at any time. If they step out, the
	next one in hosts. A stranger the host's choices turn away (a full car, or Friends only) isn't
	let in; the server sets them down at the gate and says why.

	Replicated values on a lobby car:
	- `CarAttribute`: its bay, 1 to 6. Marks it a lobby car: its keypad never wakes, and its clock
	  shows only on the screens of those aboard.
	- `GroupAttribute`: the UserIds aboard, in the order they stepped in. Absent when it's empty.
	  The first is the host.
	- `FriendsAttribute`: true while the host has it Friends only; absent while it's Open.
	- `PlayersAttribute`: how many players the host takes, 1 to 5; absent at the full 6.
	- `ResultsAttribute`: how the last climb from this car went (ClimbEnd.encodeResults), on its
	  back wall for everyone (CarResults) from the group's return until the car next leaves.

	Back in your car (L-08e2): when the climb ends, its group comes back standing in the car they
	left from, in their old order (the host first) with the host's choices as they were (`back`),
	facing the results on its back wall (`backSpot`), and the full count runs for another go
	(`welcome`). Anyone can step out and back in, as at any car.
]]
local Departure = require("../Elevator/Departure")

local Boarding = {}

-- How a readout cell is lit: Readout.Tone's four, spelled out here as a cross-folder require's
-- types don't reach every screen's checker.
export type Tone = "Off" | "Rest" | "Lit" | "Right"

Boarding.CarAttribute = "LobbyCar"
Boarding.GroupAttribute = "Group"
Boarding.FriendsAttribute = "FriendsOnly"
Boarding.PlayersAttribute = "Players"
Boarding.ResultsAttribute = "Results"

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
-- The host's panel's remote, ReplicatedStorage.Remotes.CarPanel: a choice to the server
-- (car, "Friends" | "Players" | "Go", value), a refusal to a stranger turned away at the gate
-- (car, "Full" | "Friends").
Boarding.RemoteFolder = "Remotes"
Boarding.RemoteName = "CarPanel"
-- The fastest a host's choices are taken, seconds apart: a quick thumb on + or -.
Boarding.ChoiceSeconds = 0.12

-- Seconds after it left that a car stands open in its bay again, empty, for the next group: the
-- ride up (Ride.opens, about 10 s) and a beat for those who rode to be on floor 1.
Boarding.Back = 12

-- The difficulties a host picks from. Only one until the climb has tiers (the GDD's auction-board
-- tiers; their names wait on the owner, OWNER.md): the panel shows it, with nothing to change.
Boarding.Difficulties = { "Normal" }

export type Car = {
	group: { number }, -- UserIds, in the order they stepped in; the first hosts
	departs: number?, -- server time the gate starts to shut; nil while nobody's aboard
	friends: boolean, -- the host's Friends only: only the host's friends may step in
	players: number, -- the host's player count: the car is full at this many
}

-- Why someone may not step into a car (`refusal`). In: they're aboard already. Shutting: the
-- gate's shutting. Full: the host's player count is reached. Friends: Friends only, and they
-- aren't the host's friend. Asking: Friends only, and whether they're friends isn't known yet
-- (the server is asking Roblox).
export type Refusal = "In" | "Shutting" | "Full" | "Friends" | "Asking"

function Boarding.new(): Car
	return { group = {}, departs = nil, friends = false, players = Boarding.Capacity }
end

-- The host: the first one aboard, or nil for an empty car.
function Boarding.host(car: Car): number?
	return car.group[1]
end

-- Whether the count has run out at server time `t`: the gate is shutting or gone, and the group
-- is what it is (whoever is inside at the post rides).
function Boarding.shutting(car: Car, t: number): boolean
	local departs = car.departs
	return departs ~= nil and t >= departs
end

-- Why `id` may not step into `car` at `t`, or nil if they may. `friend`: whether they're the
-- host's friend, nil if that isn't known (asked only while it's Friends only).
function Boarding.refusal(car: Car, id: number, t: number, friend: boolean?): Refusal?
	if table.find(car.group, id) then
		return "In"
	end
	if Boarding.shutting(car, t) then
		return "Shutting"
	end
	if #car.group >= car.players then
		return "Full"
	end
	if car.friends and #car.group > 0 then
		if friend == nil then
			return "Asking"
		elseif not friend then
			return "Friends"
		end
	end
	return nil
end

-- The car is full (`players` aboard) at `t`: the count drops to `FullSeconds`, unless less is
-- left already or it's held.
local function cut(car: Car, t: number)
	local departs = car.departs
	if departs and #car.group >= car.players then
		car.departs = math.min(departs, t + Boarding.FullSeconds)
	end
end

-- `id` steps in at `t`. False (nothing changes) if `refusal` says they may not. The first one
-- in starts the count (and hosts); the one who fills it cuts it to `FullSeconds`, unless less is
-- left already.
function Boarding.join(car: Car, id: number, t: number, friend: boolean?): boolean
	if Boarding.refusal(car, id, t, friend) then
		return false
	end
	table.insert(car.group, id)
	car.departs = car.departs or t + Boarding.Seconds
	cut(car, t)
	return true
end

-- `id` steps out at `t`. False if they weren't in or the gate is shutting. The count runs on
-- (it never climbs back up); if the host left, the next one in hosts, the choices as they were;
-- the last one out stops it, and the next group starts from Open and 6.
function Boarding.leave(car: Car, id: number, t: number): boolean
	local i = table.find(car.group, id)
	if not i or Boarding.shutting(car, t) then
		return false
	end
	table.remove(car.group, i)
	if #car.group == 0 then
		car.departs = nil
		car.friends = false
		car.players = Boarding.Capacity
	end
	return true
end

-- The player counts the host may pick now: never fewer than are aboard, never more than six.
function Boarding.playerRange(car: Car): (number, number)
	return math.max(#car.group, 1), Boarding.Capacity
end

-- The host's choices. Each is the host's alone (`by` must be the host), only before the gate
-- starts to shut, and true only if it changed something.

-- Open (false) or Friends only (true). Those already aboard stay.
function Boarding.setFriends(car: Car, by: number, on: boolean, t: number): boolean
	if Boarding.host(car) ~= by or Boarding.shutting(car, t) or car.friends == on then
		return false
	end
	car.friends = on
	return true
end

-- How many players the car takes, within `playerRange`. Down to as many as are aboard fills it,
-- which cuts the count as the last one stepping in does.
function Boarding.setPlayers(car: Car, by: number, n: number, t: number): boolean
	local low, high = Boarding.playerRange(car)
	if
		Boarding.host(car) ~= by
		or Boarding.shutting(car, t)
		or n % 1 ~= 0
		or n < low
		or n > high
		or n == car.players
	then
		return false
	end
	car.players = n
	cut(car, t)
	return true
end

-- Go: the count runs out now, so the gate starts to shut at `t`. Nothing while the count is held
-- (another group's climb on this server, until L-08e1c).
function Boarding.go(car: Car, by: number, t: number): boolean
	local departs = car.departs
	if Boarding.host(car) ~= by or not departs or t >= departs then
		return false
	end
	car.departs = t
	return true
end

-- Starts the count again at `t` for a car whose count was held (while another group's climb ran
-- on this server, L-08e1b1's stand-in): the full count, or `FullSeconds` if it's full. Nothing
-- for an empty car or one already counting.
function Boarding.resume(car: Car, t: number)
	if car.departs or #car.group == 0 then
		return
	end
	local full = #car.group >= car.players
	car.departs = t + (if full then Boarding.FullSeconds else Boarding.Seconds)
end

-- The group a climb took up is back in its car (L-08e2): `ids` in their old order, the first
-- hosting, with the host's choices as they left (`friends`, `players`, the count raised to as
-- many as come back). Anyone who stepped in meanwhile keeps their place after them, up to the
-- car's capacity. The count waits (`departs` nil) until they're stood in it (`welcome`). Returns
-- the UserIds that didn't fit (set down outside the gate), in order.
function Boarding.back(car: Car, ids: { number }, friends: boolean, players: number): { number }
	local group: { number } = {}
	for _, id in ids do
		if #group < Boarding.Capacity and not table.find(group, id) then
			table.insert(group, id)
		end
	end
	local over: { number } = {}
	for _, id in car.group do
		if table.find(group, id) then
			continue
		elseif #group < Boarding.Capacity then
			table.insert(group, id)
		else
			table.insert(over, id)
		end
	end
	car.group = group
	car.departs = nil
	car.friends = friends and #group > 0
	local n = if players % 1 == 0 then players else Boarding.Capacity
	car.players = math.clamp(n, math.max(#group, 1), Boarding.Capacity)
	return over
end

-- The group's back, stood in the car at `t`: the full count, whether or not it's full, so there's
-- time to take in the results on the wall and step out or stay. Nothing for an empty car or one
-- already counting.
function Boarding.welcome(car: Car, t: number)
	if car.departs or #car.group == 0 then
		return
	end
	car.departs = t + Boarding.Seconds
end

-- Where the `i`th of a group stands back in its car, in the elevator's frame (+Z into the car from
-- its gate), facing the results on its back wall: the host in the middle of the row nearer the
-- wall, then either side, then the row behind them, nearer the gate. The front row stands 5.5
-- studs off the wall, so in first person the whole board fits the view with a little round it.
local BACK_SPOTS = { { 0, 6.5 }, { -3.5, 6.5 }, { 3.5, 6.5 }, { 0, 3 }, { -3.5, 3 }, { 3.5, 3 } }
function Boarding.backSpot(i: number): (number, number)
	local s = BACK_SPOTS[(i - 1) % #BACK_SPOTS + 1]
	return s[1], s[2]
end

-- Who rides, of those `inside` (UserIds) as the gate hits its post: the group first, in the order
-- they stepped in, then anyone who dived in under the shutting gate, up to the host's player
-- count. While it's Friends only a diver rides only if `friend(id)` says they're the host's friend.
function Boarding.riders(car: Car, inside: { number }, friend: (id: number) -> boolean?): { number }
	local out: { number } = {}
	for _, id in car.group do
		if #out < car.players and table.find(inside, id) then
			table.insert(out, id)
		end
	end
	local strangers = car.friends and #car.group > 0
	for _, id in inside do
		if
			#out < car.players
			and not table.find(out, id)
			and not (strangers and friend(id) ~= true)
		then
			table.insert(out, id)
		end
	end
	return out
end

-- The host's choices from their replicated values: Friends only, and the player count (a
-- missing or broken value is Open and 6).
function Boarding.choices(friends: unknown, players: unknown): (boolean, number)
	local n = Boarding.Capacity
	if type(players) == "number" and players % 1 == 0 and players >= 1 and players < n then
		n = players
	end
	return friends == true, n
end

-- The choices as their replicated values (`FriendsAttribute`, `PlayersAttribute`).
function Boarding.encodeChoices(car: Car): (boolean?, number?)
	return if car.friends then true else nil,
		if car.players < Boarding.Capacity then car.players else nil
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
