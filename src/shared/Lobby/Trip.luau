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
	- Share and follow (L-08e3b): the data names the group's own server (`server`, its reserved
	  id) and the lobby they left (`lobby`, its JobId). An invite or share link from a group's own
	  server carries that id (`invite`), so the public lobby a friend lands in sends them on to it
	  (`readInvite`), and the group's server sends the floor they're on back to its lobby (`word`,
	  MessagingService on the lobby's `topic`), where the car they left from shows it.
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

-- On Workspace on a group's own server, for every screen: its reserved id, which an invite or
-- share link from there carries so a friend's lobby can send them on (absent where it's unknown).
Trip.ServerAttribute = "TripServer"
-- On a player on a lobby, for their screen: they came by an invite from a friend on a group's own
-- server and are being sent on to it; the friend's name ("" if Roblox didn't say). Cleared if the
-- trip failed for good (their screen says so).
Trip.FollowAttribute = "Following"

-- The data's shape version: a server reading data it doesn't know takes nobody's word for a group.
-- 3 added the group's own server, the lobby they left and who invited a friend sent on (L-08e3b);
-- 2 added the car (L-08e2); 2 and 1 still read (a lobby server still running an old version sends
-- them while an update rolls out): 1 as the first bay with Open and six, both with no server or
-- lobby named.
Trip.Version = 3
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
-- speed, the shaft sliding past, with the last clank, the slowdown, the bell and the gate still
-- to come (about 6 s), so the ride they left in reads as the ride they arrive in. The first ride
-- has no machine to spend at (GDD "The ride"), so its middle is the black of the trip.
Trip.Since = Ride.arrives() - 6.2
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
-- Under the black when a trip didn't go and you're still here (a friend's invite you were being
-- sent on by).
Trip.FailedText = "Teleport failed"
-- Seconds the failure stays under the black before it lifts.
Trip.FailedHold = 1.4

-- Seconds an invite or share link from a group's own server sends a friend on to it: past this
-- the group has most likely moved on, and the friend stays in the lobby they land in. A share
-- link from there expires then too (a link from a lobby keeps Roblox's day).
Trip.FollowFor = 2 * 60 * 60
-- Seconds a share key press waits before another is taken (the sheet takes a moment to open).
Trip.ShareEvery = 4
-- The line on Roblox's invite sheet over your friends (dropped if it's too long to fit), and under
-- a share link's preview.
Trip.InviteLine = "Ride up with us"

-- Word of a group's floor to the lobby they left: sent as the floor changes and every this many
-- seconds while it doesn't, so a lobby that hears nothing for `WordStale` knows they're gone (the
-- group's server shut, or the word was lost) and its dial forgets them.
Trip.WordEvery = 60
Trip.WordStale = 150
-- The highest floor a word may name (the climb has no top; this is past any real one).
Trip.MostFloor = 9999

export type Data = {
	v: number,
	group: { number }, -- UserIds in the order they stepped in; the first hosted
	difficulty: string,
	bay: number, -- the lobby car they left in, 1 to `Bays`
	friends: boolean, -- the host's Friends only, as it left
	players: number, -- the host's player count, as it left
	server: string, -- the group's own server's reserved id ("": not named)
	lobby: string, -- the JobId of the lobby they left, for word of their floor ("": none)
	by: number, -- a friend sent on by an invite: who invited them (0: nobody)
}

-- The car a group left in, as the data carries it: its bay and the host's choices.
export type Car = { bay: number, friends: boolean, players: number }
-- Where the group goes and whom it reports to: its own server's reserved id, the lobby's JobId,
-- and who invited a friend sent on alone.
export type Route = { server: string, lobby: string, by: number? }

-- Whether `s` reads as a GUID (HttpService:GenerateGUID(false), a JobId): eight, four, four,
-- four and twelve hex digits, with dashes.
local GUID = "^"
	.. string.rep("%x", 8)
	.. "%-"
	.. string.rep("%x", 4)
	.. "%-"
	.. string.rep("%x", 4)
	.. "%-"
	.. string.rep("%x", 4)
	.. "%-"
	.. string.rep("%x", 12)
	.. "$"
function Trip.isServer(s: unknown): boolean
	return type(s) == "string" and string.match(s, GUID) ~= nil
end

-- Whether `n` is a UserId: a whole number above zero.
local function isId(n: unknown): boolean
	return type(n) == "number" and n == n and n >= 1 and n < 2 ^ 53 and n % 1 == 0
end

-- The data a car's riders take: `group` (UserIds, the host first), the host's difficulty, the
-- car they left in (nil: the first bay, Open and six) and where they go (nil: nothing named).
function Trip.encode(group: { number }, difficulty: string, car: Car?, route: Route?): Data
	local by = if route and route.by and isId(route.by) then route.by else 0
	return {
		v = Trip.Version,
		group = table.clone(group),
		difficulty = difficulty,
		bay = if car then car.bay else 1,
		friends = if car then car.friends else false,
		players = if car then car.players else Boarding.Capacity,
		server = if route and Trip.isServer(route.server) then route.server else "",
		lobby = if route and Trip.isServer(route.lobby) then route.lobby else "",
		by = by,
	}
end

-- Whether `n` is a whole number from `low` to `high`.
local function whole(n: unknown, low: number, high: number): boolean
	return type(n) == "number" and n == n and n % 1 == 0 and n >= low and n <= high
end

-- The data a player arrived with, checked: nil unless it's ours, at our version (or 2 or 1), with
-- a group of 1 to `Boarding.Capacity` distinct UserIds. An unknown difficulty reads as the first
-- one; a car that doesn't read (or version 1's, which has none) as the first bay, Open and six; a
-- server or lobby that isn't a GUID (or before version 3) as none, and an inviter that isn't a
-- UserId (or is the first of the group) as nobody.
-- `data`: Player:GetJoinData().TeleportData, which passed through the player's device.
function Trip.decode(data: unknown): Data?
	if type(data) ~= "table" then
		return nil
	end
	local t = data :: { [unknown]: unknown }
	if (t.v ~= Trip.Version and t.v ~= 2 and t.v ~= 1) or type(t.group) ~= "table" then
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
	local route: Route? = nil
	if t.v == Trip.Version then
		local by = if isId(t.by) and t.by ~= group[1] then t.by :: number else nil
		route = {
			server = if Trip.isServer(t.server) then t.server :: string else "",
			lobby = if Trip.isServer(t.lobby) then t.lobby :: string else "",
			by = by,
		}
	end
	return Trip.encode(group, difficulty, car, route)
end

-- An invite's or share link's launch data (JSON-encoded, at most 200 characters): who sent it,
-- and if they're on a group's own server, its reserved id and the server time it was sent at
-- (`Workspace:GetServerTimeNow`), so a friend's lobby can send them on while it's fresh.
export type Invite = { by: number, to: string?, at: number? }
function Trip.invite(by: number, to: string?, at: number): Invite
	if to and Trip.isServer(to) then
		return { by = by, to = to, at = math.floor(at) }
	end
	return { by = by }
end

-- The launch data a player `me` joined with (decoded from its JSON), checked at server time `t`:
-- nil unless `by` is someone else's UserId; `to` is kept only if it's a GUID sent within
-- `FollowFor` (and not from the future, beyond a minute's clock drift). It passed through the
-- sender's device: a forged one only points a screen, or sends its own joiner somewhere.
function Trip.readInvite(data: unknown, me: number, t: number): Invite?
	if type(data) ~= "table" then
		return nil
	end
	local d = data :: { [unknown]: unknown }
	if not isId(d.by) or d.by == me then
		return nil
	end
	local by = d.by :: number
	local at = d.at
	if
		Trip.isServer(d.to)
		and type(at) == "number"
		and at == at
		and at >= t - Trip.FollowFor
		and at <= t + 60
	then
		return { by = by, to = d.to :: string, at = at }
	end
	return { by = by }
end

-- The line under the black as you're sent on to a friend: "Joining Sam", or the trip's own line
-- if Roblox didn't give their name.
function Trip.followText(name: string): string
	return if name ~= "" then `Joining {name}` else Trip.CoverText
end

-- The MessagingService topic a lobby (`lobby`, its JobId) hears its groups' floors on.
function Trip.topic(lobby: string): string
	return "Floor" .. lobby
end

-- Word of a group's floor: their own server's reserved id (the lobby knows which car sent it)
-- and the floor they're on, 0 once their climb is over.
export type Word = { server: string, floor: number }
function Trip.word(server: string, floor: number): Word
	return { server = server, floor = floor }
end

-- A word as it arrives (MessagingService's `Data`), checked: nil unless the server is a GUID and
-- the floor a whole number from 0 to `MostFloor`.
function Trip.readWord(data: unknown): Word?
	if type(data) ~= "table" then
		return nil
	end
	local d = data :: { [unknown]: unknown }
	local floor = d.floor
	if
		not Trip.isServer(d.server)
		or type(floor) ~= "number"
		or floor ~= floor
		or floor % 1 ~= 0
		or floor < 0
		or floor > Trip.MostFloor
	then
		return nil
	end
	return { server = d.server :: string, floor = floor :: number }
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
