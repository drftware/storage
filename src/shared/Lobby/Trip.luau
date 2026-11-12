--!strict
--[[
	Trip: a lobby car's group going to a server of its own (L-08e1c, GDD "The lobby"), as DOORS'
	lobby elevators send each group to its own server. Pure, so Lune checks it; the server sends
	and receives (Trips), the car's ride and the screens do the rest (LobbyCars, TripView).

	- The gate slams, the car moves off, and as it gathers speed every rider's screen fades to
	  black ("Going up"). At `Send` seconds into the ride the server sends them, all in one
	  teleport, to a reserved server made for this group.
	- What goes with them (`Data`, the teleport's data): who's in the group in the order they
	  stepped in (the first hosted), the difficulty, and the car they left in (its bay and the
	  host's choices), so that after the climb they're back in the same car (L-08e2). A teleport's
	  data passes through each player's device, so the group's server checks it (`decode`) and
	  trusts nothing in it that matters: it only says whom to wait for and where they stand.
	- The group's server lays floor 1 the moment it starts. It waits for the whole group, or
	  `Wait` seconds after the first one arrives (`ready`), then stands them in floor 1's car
	  `Since` seconds into its ride, the shaft still sliding past, and their screens open on it.
	  The car levels, the bell, and the gate opens on a floor that's only theirs.
	- A trip that fails (Roblox says no, or nobody leaves for `GiveUp` seconds) puts those still
	  here back in their car, the host first, with "Teleport failed" and the count again. A failure
	  worth trying again (`retry`) is tried again first, to the same server, so a group never
	  splits over a hiccup.
]]
local Boarding = require("./Boarding")
local Ride = require("../Elevator/Ride")

local Trip = {}

-- On the lobby car, for every screen: true while it's taking its riders to a server of their
-- own (their screens fade to black). Absent once it's back in its bay.
Trip.Attribute = "Trip"
-- On Workspace, for every screen: true on a group's own server (its screens start black and open
-- in floor 1's car).
Trip.OwnAttribute = "OwnServer"
-- On a player on a group's own server: where they were stood in the climb (a CFrame: in floor
-- 1's car, or on the floor if they came late). Their screen turns that way and opens then.
Trip.ArrivedAttribute = "TripArrived"
-- Studio only, on Workspace (set in Edit before Play): "Arrive" makes the server a group's own
-- for whoever joins, to try the arrival without a teleport; "Send" sends lobby cars' riders on
-- the real trip (Studio's test teleports; the group's server they open runs the place as last
-- saved); "Fail" sends them on a trip that always fails. Absent: the lobby rides to floor 1 on this
-- server.
Trip.DevAttribute = "DevTrip"

-- The data's shape version: a server reading data it doesn't know takes nobody's word for a group.
-- 2 added the car (L-08e2); 1 still reads, as the first bay with Open and six (a lobby server
-- still running the old version sends it while an update rolls out).
Trip.Version = 2
-- The lobby's bays, numbered 1 to this from left to right (Lobby.Specs.Bays has one per car).
Trip.Bays = 6

-- Seconds into the ride that the screens start to fade to black: the slam has rung out and the
-- car has started to move (Ride.Wait), so the trip feels like the ride going on.
Trip.FadeAt = 1.6
-- Seconds the fade to black takes.
Trip.Fade = 0.6
-- Seconds into the ride that the server sends the riders: their screens are black by then.
Trip.Send = Trip.FadeAt + Trip.Fade
-- Seconds into the ride the group's car is as their screens open on the group's server: at full
-- speed, the shaft sliding past, with the second clank, the slowdown, the bell and the gate
-- still to come (about 6 s), so the ride they left in reads as the ride they arrive in.
Trip.Since = Ride.Wait + Ride.Speedup + 0.8
-- Seconds the group's server waits for the rest of the group after the first arrives. A phone
-- that loads slower than this is stood on floor 1 as the car opens, as if it had just stepped out.
Trip.Wait = 10
-- Seconds the lobby waits for a rider to leave before it calls their trip failed. A teleport
-- Roblox takes leaves within a few seconds; one it drops can say nothing.
Trip.GiveUp = 15
-- Teleport tries for one trip, the first included, before it's failed.
Trip.Tries = 3
-- Trips in a row that fail before a lobby server stops sending and rides its groups to floor 1
-- itself (the climb on this server, as before L-08e1c), so the game stays playable.
Trip.FallbackAfter = 2
-- Seconds the cover takes to fade off a screen as the climb opens around it.
Trip.Reveal = 0.6
-- Seconds a screen stays black at most waiting to be stood in the climb: past this it opens
-- anyway, so nobody is ever left staring at black.
Trip.CoverMost = 45
-- Under the black, small: what's happening.
Trip.CoverText = "Going up"

export type Data = {
	v: number,
	group: { number }, -- UserIds in the order they stepped in; the first hosted
	difficulty: string,
	bay: number, -- the lobby car they left in, 1 to `Bays`
	friends: boolean, -- the host's Friends only, as it left
	players: number, -- the host's player count, as it left
}

-- The car a group left in, as the data carries it: its bay and the host's choices.
export type Car = { bay: number, friends: boolean, players: number }

-- The data a car's riders take: `group` (UserIds, the host first), the host's difficulty and the
-- car they left in (nil: the first bay, Open and six).
function Trip.encode(group: { number }, difficulty: string, car: Car?): Data
	return {
		v = Trip.Version,
		group = table.clone(group),
		difficulty = difficulty,
		bay = if car then car.bay else 1,
		friends = if car then car.friends else false,
		players = if car then car.players else Boarding.Capacity,
	}
end

-- Whether `n` is a UserId: a whole number above zero.
local function isId(n: unknown): boolean
	return type(n) == "number" and n == n and n >= 1 and n < 2 ^ 53 and n % 1 == 0
end

-- Whether `n` is a whole number from `low` to `high`.
local function whole(n: unknown, low: number, high: number): boolean
	return type(n) == "number" and n == n and n % 1 == 0 and n >= low and n <= high
end

-- The data a player arrived with, checked: nil unless it's ours, at our version (or 1), with a
-- group of 1 to `Boarding.Capacity` distinct UserIds. An unknown difficulty reads as the first
-- one; a car that doesn't read (or version 1's, which has none) as the first bay, Open and six.
-- `data`: Player:GetJoinData().TeleportData, which passed through the player's device.
function Trip.decode(data: unknown): Data?
	if type(data) ~= "table" then
		return nil
	end
	local t = data :: { [unknown]: unknown }
	if (t.v ~= Trip.Version and t.v ~= 1) or type(t.group) ~= "table" then
		return nil
	end
	local raw = t.group :: { [unknown]: unknown }
	local n = #(raw :: { unknown })
	if n < 1 or n > Boarding.Capacity then
		return nil
	end
	local count = 0
	for _ in raw do
		count += 1
	end
	if count ~= n then
		return nil -- holes or keys besides 1..n
	end
	local group: { number } = table.create(n)
	for i = 1, n do
		local id = raw[i]
		if not isId(id) or table.find(group, id :: number) then
			return nil
		end
		group[i] = id :: number
	end
	local difficulty = Boarding.Difficulties[1]
	if type(t.difficulty) == "string" and table.find(Boarding.Difficulties, t.difficulty) then
		difficulty = t.difficulty :: string
	end
	local car: Car = { bay = 1, friends = false, players = Boarding.Capacity }
	if
		whole(t.bay, 1, Trip.Bays)
		and type(t.friends) == "boolean"
		and whole(t.players, 1, Boarding.Capacity)
	then
		car =
			{ bay = t.bay :: number, friends = t.friends :: boolean, players = t.players :: number }
	end
	return Trip.encode(group, difficulty, car)
end

-- Whether the group's car goes at server time `t`: everyone in `group` is in `arrived` (UserIds),
-- or `Wait` has passed since the first arrived at `firstAt`. Nobody arrived: it waits.
function Trip.ready(group: { number }, arrived: { number }, firstAt: number?, t: number): boolean
	if not firstAt or #arrived == 0 then
		return false
	end
	if t >= firstAt + Trip.Wait then
		return true
	end
	for _, id in group do
		if not table.find(arrived, id) then
			return false
		end
	end
	return true
end

-- Seconds to wait before trying a failed teleport again, given Roblox's reason for it
-- (Enum.TeleportResult's name) and how many tries were made: nil if it isn't worth another try.
-- A busy server (Flooded) or a network blip (Failure) is; anything else (the place, the player)
-- won't change by trying again.
function Trip.retry(reason: string, tries: number): number?
	if tries >= Trip.Tries then
		return nil
	end
	if reason == "Failure" then
		return 1
	elseif reason == "Flooded" then
		return 3
	end
	return nil
end

-- Where the `i`th of a group stands in the car as it arrives, in the elevator's frame (+Z into
-- the car from its gate): the host at the front middle, then the front sides, then the back row,
-- each facing the gate.
local SPOTS = { { 0, 4 }, { -3.5, 4 }, { 3.5, 4 }, { 0, 8 }, { -3.5, 8 }, { 3.5, 8 } }
function Trip.spot(i: number): (number, number)
	local s = SPOTS[(i - 1) % #SPOTS + 1]
	return s[1], s[2]
end

return Trip
