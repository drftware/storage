--!strict
--[[
	LobbyCars: the front office's six cars as the way into a climb (L-08e1b1, GDD "The lobby",
	D-112), as DOORS' lobby elevators do. A system on the server.

	- Each car is the climb's own elevator (Lobby.lay), stood open in its bay by Elevators'
	  `lobby`: its keypad asleep, its readout the count (ElevatorView).
	- Step through its gate and you're in its group (Boarding); a Brix zone over the car decides
	  it, as the climb's car decides who rode (Departure.carBox). Out of it for
	  `Boarding.LeaveGrace` and you've left. The group goes on the car for every screen
	  (`Boarding.GroupAttribute`): only those aboard see and hear its clock (GateClock).
	- The first step in starts the count on the climb's gate clock (Elevators' `count`): 20 s, 5
	  once six are aboard, and floor 1 starts laying out of play (Climbs' `ready`), so it's there
	  long before the car leaves.
	- At zero the gate shuts with the climb's own ratchet and slam; whoever's inside as it hits
	  its post rides (`Boarding.riders`), and the climb carries them up to floor 1 on this server
	  (Climbs' `board`), as a floor's car hands its riders to the next. Anyone else left in the car
	  (a seventh) is set down outside its gate.
	- `Boarding.Back` seconds after it left, the car stands open in its bay again, empty.
	- A server of the group's own (L-08e1c, Trips): on a live server the riders' screens fade to
	  black as the car gathers speed and they're sent, together, to a server made for them, the
	  group and difficulty with them. A trip that fails puts those still here back in the car,
	  the host first and the choices as they were, with "Teleport failed" and the count again.
	  Where trips don't go (Studio, or a lobby whose trips keep failing) the climb carries them up
	  to floor 1 on this server, as below.
	- Back in your car (L-08e2, GDD "The lobby"): when the climb ends, its group comes back
	  standing in the car they left from (`home`, called by ClimbEnds' `go` under the black), in
	  their old order with the host's choices as they were, facing the results on its back wall
	  (`Boarding.ResultsAttribute`); once they're all stood in it the full count runs for another
	  go (`welcome`). On a group's own server that's the car the trip's data names; the cars there
	  open only then (until then the group's climb is starting in floor 1's car, Trips), and their
	  next climb rides up on that server. The results stay on the wall until the car next leaves.
	- One climb at a time on a server riding here: while one a car started is on, the other cars'
	  counts are held (their groups stay) and start again from the full count once it's over.
	- The host's panel (L-08e1b2): the first one aboard hosts; their choices come through the
	  `CarPanel` remote, checked in order: the payload's types (a lobby car of ours, a choice the
	  panel has, its value's type), then range (the car's host, so aboard), then the rate, then
	  Boarding's own rules (within range, before the gate shuts). The choices go on the car for
	  every screen. Go runs the count out now (Elevators' `count`).
	- Turned away: someone stepping into a car its host's choices close to them (full, or Friends
	  only and not the host's friend) is set down outside its gate, and their screen is told why.
	  Whether they're the host's friend is asked of Roblox once, as they step in
	  (`Player:IsFriendsWith` yields), and kept; until it's known they're neither in nor out.
	- The dials (L-08e3, CarDial): while a group a car took up climbs on this server, the car
	  carries the floor they're on (`Boarding.FloorAttribute`). Someone who joins by a friend's
	  invite (Roblox's launch data, CarPanel) is marked with who invited them
	  (`Boarding.InvitedAttribute`), so their screen points them to that friend's car.
	- Share and follow (L-08e3b): an invite from a friend on a group's own server names that
	  server, and the friend who joins by it is sent on to it (Trips' `follow`) while it's fresh
	  (`Trip.readInvite`). A group a car sends away names its own server and this lobby; their
	  server sends back the floor they're on (MessagingService on this lobby's `Trip.topic`), and
	  the car they left from shows it on its dial until their climb is over, or until nothing's
	  been heard for `Trip.WordStale`. Share on the panel, for anyone aboard: Roblox's share sheet
	  with a link to the game (`SocialService:PromptLinkSharingAsync`, server only), naming the
	  group's own server if this is one.

	Every step checks each player against the six cars: a few box tests, no allocation.
]]
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local Trip = require(ReplicatedStorage.Shared.Lobby.Trip)
local Climbs = require(script.Parent.Climbs)
local Elevators = require(script.Parent.Elevators)
local FrontOffice = require(script.Parent.FrontOffice)
local Trips = require(script.Parent.Trips)

type Car = {
	model: Model,
	zone: Brix.Zone,
	state: Boarding.Car,
	out: { [number]: number }, -- UserId → server time they were first seen out of the car
	away: boolean, -- it left and isn't back in its bay yet
	holding: boolean, -- a group is being stood back in it after their climb: not stepped
	leg: number, -- how many times it has left: a return meant for an earlier trip is dropped
	pick: (inside: { Player }) -> { Player },
	far: Far?, -- the group it last sent to a server of their own, while word of them may come
}

-- A group a car sent to a server of their own (L-08e3b): that server's reserved id, the floor
-- they last said they're on, and the server time they were last heard from (or were sent).
type Far = { server: string, floor: number?, heard: number }

-- The group a car took up into a climb on this server, as it left: who rode, in order, and the
-- host's choices.
type Ridden = { car: Car, group: { number }, friends: boolean, players: number }

-- One of a climb's group back in the lobby: where they're stood (in their car, facing its back
-- wall).
export type Back = { player: Player, at: CFrame }

export type LobbyCars = Brix.System & {
	-- Fires as a car leaves the lobby with players aboard, to their own server or up the climb
	-- here, with them in the order they stepped in (Recording, S1-02).
	departed: Brix.Signal<{ Player }>,
	-- The climb is over (ClimbEnds' `go`, under the black): its group goes back into the car they
	-- left from, held there (no count) for `welcome`. Returns where each of them is to be stood,
	-- in their order: empty if their car can't take them (they come back at the front office),
	-- nil if this climb didn't start from a car of this lobby (the test hall's, in Studio).
	home: (self: any) -> { Back }?,
	-- Everyone's stood back in: the results go on the held car's back wall (ClimbEnd's
	-- `encodeResults`) and its full count runs. Nothing if no car is held.
	welcome: (self: any, results: string) -> (),
}

local FREE = Brix.Pathing.free()
local STUDIO = RunService:IsStudio()
-- Seconds between telling the same player why they were turned away: walking in again and again
-- sets them down each time, but the words come at most this often.
local TELL_AGAIN = 2
-- Seconds before asking Roblox again whether two players are friends after the ask failed.
local ASK_AGAIN = 5

-- Where someone left in a car that leaves without them is set down: on the striped zone in
-- front of its gate, facing the room (in the elevator's frame, +Z into the car).
local SET_DOWN = CFrame.new(0, 3, -4) * CFrame.Angles(0, math.pi, 0)

-- An invite's launch data can take a few seconds to reach a joining player (create.roblox.com,
-- "Player invite prompts"): asked this many times, this many seconds apart.
local INVITE_TRIES, INVITE_EVERY = 10, 1

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local LobbyCars = {}

function LobbyCars.new(): LobbyCars
	local cars: { Car } = {}
	local elevators: Elevators.Elevators? = nil
	local climbs: Climbs.Climbs? = nil
	local trips: Trips.Trips? = nil
	local folder: Folder? = nil -- the climbs the lobby starts are laid in here
	local departing: Brix.SignalConnection? = nil
	local connections: { RBXScriptConnection } = {}
	local returns: { thread } = {}
	local departedSignal = Brix.Signal.new() :: Brix.Signal<{ Player }>
	-- a climb a car started is on this server (until L-08e1c), and since when
	local climbing = false
	local boardedAt = 0
	local ridden: Ridden? = nil -- the group the latest climb from a car took up, until it's home
	local holding: Car? = nil -- the car a climb's group is being stood back in
	local homed = false -- a group's own server: its group is back in the lobby (its cars open)
	local remote: RemoteEvent? = nil
	local lastChoice: { [Player]: number } = {} -- os.clock() of each host's last choice taken
	local lastTold: { [number]: number } = {} -- UserId → server time they were last told why
	local lastShare: { [Player]: number } = {} -- os.clock() of each player's last share taken
	local hearing: RBXScriptConnection? = nil -- word of the floors this lobby's groups are on
	-- Friends, as Roblox answered: UserId → UserId → whether they're friends (both ways round).
	local friends: { [number]: { [number]: boolean } } = {}
	local asking: { [number]: { [number]: true } } = {} -- the asks under way, the same way round

	local function know(a: number, b: number, are: boolean?)
		for _, pair in { { a, b }, { b, a } } do
			local row: { [number]: boolean }? = friends[pair[1]]
			if not row then
				local fresh: { [number]: boolean } = {}
				friends[pair[1]] = fresh
				row = fresh
			end
			-- nil forgets it (an ask that failed, asked again later)
			(row :: any)[pair[2]] = are -- any: a nil value clears the entry
		end
	end

	-- Whether `id` is `host`'s friend: true, false, or nil while Roblox is being asked (asked once,
	-- off the step, as IsFriendsWith yields).
	local function friendOf(host: number, id: number): boolean?
		local row = friends[host]
		local known = row and row[id]
		if known ~= nil then
			return known
		end
		local pending: { [number]: true }? = asking[host]
		if pending and pending[id] then
			return nil
		end
		local asks: { [number]: true } = pending or {}
		asking[host] = asks
		asks[id] = true
		task.spawn(function()
			local player = Players:GetPlayerByUserId(id)
			local ok, are = false, nil
			if player then
				ok, are = pcall(player.IsFriendsWith, player, host)
			end
			local p = asking[host]
			if p then
				p[id] = nil
			end
			if ok and type(are) == "boolean" then
				know(host, id, are)
			else
				-- Roblox didn't answer: not a friend for now, asked again in a moment
				know(host, id, false)
				task.delay(ASK_AGAIN, function()
					local r = friends[host]
					if r and r[id] == false then
						know(host, id, nil)
					end
				end)
			end
		end)
		return nil
	end

	-- The car's group and count, as the server holds them now, out to every screen.
	local function publish(car: Car)
		car.model:SetAttribute(Boarding.GroupAttribute, Boarding.encode(car.state.group))
		local on, players = Boarding.encodeChoices(car.state)
		car.model:SetAttribute(Boarding.FriendsAttribute, on)
		car.model:SetAttribute(Boarding.PlayersAttribute, players)
		local e = elevators
		if e then
			e:count(car.model, car.state.departs)
		end
	end

	-- Whether this lobby sends its groups to servers of their own (else they ride here).
	local function sending(): boolean
		local t = trips
		return t ~= nil and t:sends()
	end

	-- Floor 1 starts laying out of play the moment a count starts, so it's there by zero: only
	-- where the group rides up on this server.
	local function ready()
		local c, f = climbs, folder
		if c and f and not climbing and not sending() then
			c:ready({
				seed = Random.new():NextInteger(1, 2 ^ 31 - 1),
				number = 1,
				origin = Lobby.ClimbOrigin,
				parent = f,
			})
		end
	end

	-- The car's group and choices as nobody's aboard, on every screen (its count is Elevators'),
	-- and the last climb's results off its wall: it's leaving, or back in its bay for the next.
	local function empty(car: Car)
		car.state = Boarding.new()
		table.clear(car.out)
		car.model:SetAttribute(Boarding.GroupAttribute, nil)
		car.model:SetAttribute(Boarding.FriendsAttribute, nil)
		car.model:SetAttribute(Boarding.PlayersAttribute, nil)
		car.model:SetAttribute(Boarding.ResultsAttribute, nil)
	end

	-- The floor the group `car` took up is on (nil: none climbing), on its dial.
	local function showFloor(car: Car, floor: number?)
		if car.model:GetAttribute(Boarding.FloorAttribute) ~= floor then
			car.model:SetAttribute(Boarding.FloorAttribute, floor)
		end
	end

	-- Who invited `player` (Roblox's launch data on an invite, CarPanel's `{ by = UserId }`): it
	-- arrives a few seconds after they join, if at all. Only its type is checked: it just points
	-- their screen to that friend's car.
	local function invited(player: Player)
		for _ = 1, INVITE_TRIES do
			if not player.Parent then
				return
			end
			local ok, join = pcall(function(): any
				return player:GetJoinData()
			end)
			-- any: GetJoinData's dictionary, and LaunchData passed through the inviter's device
			local launch = if ok and type(join) == "table" then (join :: any).LaunchData else nil
			if type(launch) == "string" and launch ~= "" then
				local decoded, data = pcall(HttpService.JSONDecode, HttpService, launch)
				local invite = if decoded then Trip.readInvite(data, player.UserId, now()) else nil
				if invite and player.Parent then
					player:SetAttribute(Boarding.InvitedAttribute, invite.by)
					-- from a friend on their group's own server: sent on to it
					local t = trips
					if invite.to and t and not t:own() then
						t:follow(player, invite.to, invite.by)
					end
				end
				return
			end
			task.wait(INVITE_EVERY)
		end
	end

	-- Whether this is a group's own server whose group is still on the climb they arrived for:
	-- its cars wait for them to come home.
	local function waitingForHome(): boolean
		local t = trips
		return t ~= nil and t:own() and not homed
	end

	-- Stands `car` open in its bay again, empty.
	local function back(car: Car)
		car.away = false
		empty(car)
		car.model:SetAttribute(Trip.Attribute, nil)
		local e = elevators
		if e then
			e:lobby(car.model, car.pick)
		end
	end

	-- `player` stepped into `car`, whose host's choices close it to them (`why`): set down
	-- outside its gate, told why (not every time, if they keep at it).
	local function turnAway(car: Car, player: Player, why: Boarding.Refusal, t: number)
		local character = player.Character
		if character then
			character:PivotTo(car.model:GetPivot() * SET_DOWN)
		end
		local id = player.UserId
		local r = remote
		if r and t - (lastTold[id] or -math.huge) >= TELL_AGAIN then
			lastTold[id] = t
			r:FireClient(player, car.model, why)
		end
	end

	-- `player` is inside `car` (true) or not at server time `t`: joins it (or is turned away), or
	-- leaves it once out for the grace. True if the group changed.
	local function see(car: Car, player: Player, inside: boolean, t: number): boolean
		local id = player.UserId
		if inside then
			car.out[id] = nil
			local state = car.state
			local host = Boarding.host(state)
			local friend: boolean? = nil
			if state.friends and host and host ~= id and not table.find(state.group, id) then
				friend = friendOf(host, id)
			end
			local why = Boarding.refusal(state, id, t, friend)
			if why == "Full" or why == "Friends" then
				turnAway(car, player, why, t)
				return false
			end
			return Boarding.join(state, id, t, friend)
		end
		if not table.find(car.state.group, id) then
			return false
		end
		local since = car.out[id]
		if not since then
			car.out[id] = t
			return false
		end
		if t - since < Boarding.LeaveGrace then
			return false
		end
		car.out[id] = nil
		return Boarding.leave(car.state, id, t)
	end

	-- Word from a group's own server of the floor they're on (MessagingService's `Data`): on the
	-- dial of the car that sent them, if it's still the group that car last sent.
	local function heard(data: unknown)
		local word = Trip.readWord(data)
		if not word then
			return
		end
		for _, car in cars do
			local far = car.far
			if far and far.server == word.server then
				if word.floor == 0 then
					car.far = nil
					showFloor(car, nil)
				else
					far.floor, far.heard = word.floor, now()
					showFloor(car, word.floor)
				end
			end
		end
	end

	-- Share: Roblox's share sheet for `player`, with a link to the game naming them (and this
	-- group's own server, while it's fresh). Told if it couldn't open. Yields.
	local function share(player: Player, car: Car)
		local t = trips
		local to = if t then t:server() else nil
		local launch = HttpService:JSONEncode(Trip.invite(player.UserId, to, now()))
		local ok, result = pcall(function(): any
			return SocialService:PromptLinkSharingAsync(player, {
				ExpirationSeconds = if to then Trip.FollowFor else nil,
				PreviewDescription = Trip.InviteLine,
				LaunchData = launch,
			})
		end)
		local fine = ok
			and (
				result == Enum.PromptLinkSharingResult.Success
				or result == Enum.PromptLinkSharingResult.PlayerLeft
			)
		if not fine then
			warn(`LobbyCars: {player.Name}'s share sheet didn't open: {result}`)
			local r = remote
			if r and player.Parent then
				r:FireClient(player, car.model, "Share")
			end
		end
	end

	-- `player`'s trip from `car` (its `leg`th) failed for good: back in the car (stood open in its
	-- bay again if it isn't yet, the choices as they were), in their place in the group as it
	-- left (the host first), told why; the count runs again.
	local function tripFailed(car: Car, was: Boarding.Car, leg: number, player: Player)
		if not player.Parent then
			return
		end
		if car.away and car.leg == leg then
			back(car)
			car.state.friends, car.state.players = was.friends, was.players
		end
		local state = car.state
		local id = player.UserId
		if not table.find(state.group, id) and Boarding.join(state, id, now(), true) then
			-- back in line where they stood as it left; anyone new since goes after
			local function place(of: number): number
				return table.find(was.group, of) or math.huge
			end
			local line = table.clone(state.group)
			table.sort(state.group, function(a: number, b: number): boolean
				local i, j = place(a), place(b)
				if i ~= j then
					return i < j
				end
				return (table.find(line, a) or 0) < (table.find(line, b) or 0)
			end)
		end
		publish(car)
		local r = remote
		if r then
			lastTold[id] = now()
			r:FireClient(player, car.model, "Trip")
		end
		ready() -- in case this lobby has stopped sending: floor 1 for the ride here
	end

	-- The car left with its riders for a server of their own (L-08e1c): their screens fade to
	-- black as it gathers speed (TripView, from the car's `Trip.Attribute`), then they're sent,
	-- together, the group in the order they stepped in.
	local function trip(car: Car, leaving: Elevators.Leaving, was: Boarding.Car, leg: number)
		local t = trips :: Trips.Trips
		car.model:SetAttribute(Trip.Attribute, true)
		local ids: { number } = table.create(#leaving.aboard)
		for i, player in leaving.aboard do
			ids[i] = player.UserId
		end
		-- the group's own server, named here so word of their floor finds this car
		local server = HttpService:GenerateGUID(false)
		local data = Trip.encode(ids, Boarding.Difficulties[1], {
			bay = (car.model:GetAttribute(Boarding.CarAttribute) :: number?) or 1,
			friends = was.friends,
			players = was.players,
		}, { server = server, lobby = game.JobId }) :: Trips.Data
		car.far = { server = server, floor = nil, heard = now() }
		showFloor(car, nil)
		table.insert(
			returns,
			task.delay(math.max(leaving.at + Trip.Send - now(), 0), function()
				t:send(leaving.aboard, data, function(player: Player)
					tripFailed(car, was, leg, player)
				end)
			end)
		)
	end

	-- The car left with `leaving.aboard`: they go to a server of their own, or the climb takes
	-- them up here; anyone else in it is set down outside; the car comes back for the next group.
	local function departed(leaving: Elevators.Leaving)
		local car: Car? = nil
		for _, c in cars do
			if c.model == leaving.elevator then
				car = c
			end
		end
		if not car then
			return
		end
		car.away = true
		car.leg += 1
		local leg = car.leg
		local was = car.state -- the group and choices as it left (empty starts a fresh state)
		empty(car)
		local pivot = car.model:GetPivot()
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if
				root
				and not table.find(leaving.aboard, player)
				and car.zone:contains((root.Position :: any) :: vector)
			then
				local character = player.Character :: Model
				character:PivotTo(pivot * SET_DOWN)
			end
		end
		local c = climbs
		local wait = Boarding.Back
		if #leaving.aboard > 0 then
			departedSignal:fire(table.clone(leaving.aboard))
		end
		if #leaving.aboard == 0 then
			wait = 0 -- nobody rode: it's back at once
		elseif sending() then
			trip(car, leaving, was, leg)
		elseif c and c:board(leaving.elevator, leaving) then
			climbing, boardedAt = true, now()
			local ids: { number } = table.create(#leaving.aboard)
			for i, player in leaving.aboard do
				ids[i] = player.UserId
			end
			ridden = { car = car, group = ids, friends = was.friends, players = was.players }
			-- every other car's count waits for this climb to end
			for _, other in cars do
				if other ~= car and other.state.departs then
					other.state.departs = nil
					publish(other)
				end
			end
		else
			warn("LobbyCars: no floor 1 to ride to; the car comes back")
		end
		for i = #returns, 1, -1 do
			if coroutine.status(returns[i]) == "dead" then
				table.remove(returns, i)
			end
		end
		table.insert(
			returns,
			task.delay(math.max(leaving.at + wait - now(), 0), function()
				if car.away and car.leg == leg then
					back(car)
				end
			end)
		)
	end

	-- A host's choice on their car's panel: checked, then made.
	local function chose(player: Player, model: unknown, choice: unknown, value: unknown)
		-- the payload's types: a lobby car of ours, a choice the panel has, its value's type
		if typeof(model) ~= "Instance" then
			return
		end
		local car: Car? = nil
		for _, c in cars do
			if c.model == model then
				car = c
			end
		end
		if not car or car.away then
			return
		end
		if choice == "Friends" then
			if type(value) ~= "boolean" then
				return
			end
		elseif choice == "Players" then
			if type(value) ~= "number" then
				return
			end
		elseif choice == "Share" then
			if value ~= nil then
				return
			end
			-- range: anyone aboard; rate: one sheet at a time, with a breath between
			if not table.find(car.state.group, player.UserId) then
				return
			end
			local clock = os.clock()
			local last = lastShare[player]
			if last and clock - last < Trip.ShareEvery then
				return
			end
			lastShare[player] = clock
			task.spawn(share, player, car)
			return
		elseif choice ~= "Go" then
			return
		end
		-- range: this car's host (the first aboard, so in it)
		local id = player.UserId
		if Boarding.host(car.state) ~= id then
			return
		end
		-- rate: no faster than a quick thumb (half the panel's own spacing, so two taps sent
		-- `ChoiceSeconds` apart that arrive closer together are both taken)
		local clock = os.clock()
		local last = lastChoice[player]
		if last and clock - last < Boarding.ChoiceSeconds * 0.5 then
			return
		end
		lastChoice[player] = clock
		-- Boarding's own rules: the value's range, and not once the gate is shutting
		local t = now()
		local changed = if choice == "Friends"
			then Boarding.setFriends(car.state, id, value :: boolean, t)
			elseif choice == "Players" then Boarding.setPlayers(
				car.state,
				id,
				value :: number,
				t
			)
			else Boarding.go(car.state, id, t)
		if changed then
			publish(car)
		end
	end

	-- The climb is over: its group back into the car they left from, held for `welcome`.
	local function home(): { Back }?
		local c, t = climbs, trips
		if #cars == 0 or not c then
			return nil
		end
		local car: Car? = nil
		local ids: { number } = {}
		local onlyFriends, players = false, Boarding.Capacity
		local r = ridden
		local last = c:last()
		if r and last and folder and last.parent == folder then
			-- a climb a car of this lobby took up, on this server
			car, ids, onlyFriends, players = r.car, r.group, r.friends, r.players
		elseif t and t:own() and not homed then
			-- the climb this group's own server started for them: the car their data names
			local d = t:data()
			if not d then
				return nil
			end
			for _, each in cars do
				if each.model:GetAttribute(Boarding.CarAttribute) == d.bay then
					car = each
				end
			end
			car = car or cars[1]
			ids = table.clone(d.group)
			onlyFriends, players = d.friends, d.players
			-- anyone else here climbed with them (Studio's "Arrive" lets them in)
			for _, player in Players:GetPlayers() do
				if not table.find(ids, player.UserId) then
					table.insert(ids, player.UserId)
				end
			end
		else
			return nil
		end
		if r then
			showFloor(r.car, nil)
		end
		ridden = nil
		if t and t:own() and not homed then
			homed = true
			t:home()
		end
		local present: { number } = {}
		for _, id in ids do
			if Players:GetPlayerByUserId(id) then
				table.insert(present, id)
			end
		end
		local into = car :: Car
		if into.away then
			-- someone else's group has taken it up meanwhile (a lobby riding here): the first
			-- empty car in its bay instead, or the front office
			local free: Car? = nil
			for _, each in cars do
				if not free and not each.away and not each.holding and #each.state.group == 0 then
					free = each
				end
			end
			if not free then
				return {}
			end
			into = free :: Car
		end
		local t0 = now()
		local over = Boarding.back(into.state, present, onlyFriends, players)
		into.holding = true
		holding = into
		table.clear(into.out)
		for _, id in over do
			local player = Players:GetPlayerByUserId(id)
			if player then
				turnAway(into, player, "Full", t0)
			end
		end
		publish(into)
		local pivot = into.model:GetPivot()
		local out: { Back } = {}
		for i, id in into.state.group do
			local player = Players:GetPlayerByUserId(id)
			if player and table.find(present, id) then
				local x, z = Boarding.backSpot(i)
				local at = Vector3.new(x, 3, z)
				table.insert(
					out,
					{ player = player, at = pivot * CFrame.lookAt(at, at + Vector3.zAxis) }
				)
			end
		end
		if STUDIO then
			print(
				`LobbyCars: {#out} back in car {into.model:GetAttribute(Boarding.CarAttribute)} after their climb`
			)
		end
		return out
	end

	-- Everyone's stood back in the held car: the results on its wall, its full count.
	local function welcome(results: string)
		local car = holding
		if not car then
			return
		end
		holding = nil
		car.holding = false
		car.model:SetAttribute(Boarding.ResultsAttribute, results)
		if not climbing then
			Boarding.welcome(car.state, now())
			if car.state.departs then
				ready()
			end
		end
		publish(car)
	end

	local system: LobbyCars = {
		name = "LobbyCars",
		departed = departedSignal,
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system
			-- (init.server), and these start before this one
			local e = (registry:get("elevators") :: any) :: Elevators.Elevators
			elevators = e
			climbs = (registry:get("climbs") :: any) :: Climbs.Climbs -- any: as above
			local tripSystem = (registry:get("trips") :: any) :: Trips.Trips -- any: as above
			trips = tripSystem
			local office = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice -- any: as above
			local laid = office:laid()
			-- on a group's own server the cars wait for the group to come home (`home`): its first
			-- climb starts in floor 1's car (Trips)
			if not laid then
				return
			end
			local f = Instance.new("Folder")
			f.Name = "LobbyClimb"
			f.Parent = Workspace
			folder = f
			for _, model in laid.cars do
				local at, x = model:GetPivot().Position, model:GetPivot().XVector
				local car: Car
				car = {
					model = model,
					zone = Brix.Zone.box(
						Departure.carBox(FREE, at.X, at.Y, at.Z, MotionLight.turnOf(x.X, x.Z))
					),
					state = Boarding.new(),
					out = {},
					away = false,
					holding = false,
					leg = 0,
					far = nil,
					pick = function(inside: { Player }): { Player }
						local ids = table.create(#inside)
						for i, player in inside do
							ids[i] = player.UserId
						end
						local out: { Player } = {}
						local host = Boarding.host(car.state)
						local function friend(id: number): boolean?
							return if host then friendOf(host, id) else nil
						end
						for _, id in Boarding.riders(car.state, ids, friend) do
							for _, player in inside do
								if player.UserId == id then
									table.insert(out, player)
								end
							end
						end
						return out
					end,
				}
				table.insert(cars, car)
				e:lobby(model, car.pick)
			end
			departing = e.departed:connect(departed)
			local remotes = ReplicatedStorage:FindFirstChild(Boarding.RemoteFolder)
			if not remotes then
				remotes = Instance.new("Folder")
				remotes.Name = Boarding.RemoteFolder
				remotes.Parent = ReplicatedStorage
			end
			local r = Instance.new("RemoteEvent")
			r.Name = Boarding.RemoteName
			r.Parent = remotes
			remote = r
			table.insert(connections, r.OnServerEvent:Connect(chose))
			table.insert(
				connections,
				Players.PlayerAdded:Connect(function(player: Player)
					task.spawn(invited, player)
				end)
			)
			for _, player in Players:GetPlayers() do
				task.spawn(invited, player)
			end
			-- word of the floors this lobby's groups are on, from their own servers (a live lobby:
			-- Studio's JobId names no server)
			if not tripSystem:own() and Trip.isServer(game.JobId) then
				task.spawn(function()
					local ok, conn = pcall(function()
						return MessagingService:SubscribeAsync(
							Trip.topic(game.JobId),
							function(message: any) -- any: MessagingService's message table
								heard(if type(message) == "table" then message.Data else nil)
							end
						)
					end)
					if ok and conn then
						hearing = conn
					else
						warn(`LobbyCars: no word of the groups' floors: {conn}`)
					end
				end)
			end
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					local t = now()
					local gone = player.UserId
					lastChoice[player], lastShare[player] = nil, nil
					lastTold[gone] = nil
					friends[gone], asking[gone] = nil, nil
					for _, row in friends do
						row[gone] = nil
					end
					for _, car in cars do
						car.out[player.UserId] = nil
						if Boarding.leave(car.state, player.UserId, t) then
							publish(car)
						end
					end
				end)
			)
			if STUDIO and not tripSystem:own() then
				print(`LobbyCars: {#cars} cars open; step into one to start its count`)
			end
		end,
		step = function(_: any, _dt: number)
			if #cars == 0 or waitingForHome() then
				return
			end
			local t = now()
			local c = climbs
			-- the climb a car started is over (its end has cleared it): the held counts start again
			local r = ridden
			if climbing and r and c then
				local on = c:current()
				showFloor(r.car, if on then on.number else nil)
			end
			if climbing and c and not c:current() and t > boardedAt + Boarding.Back then
				climbing = false
				if r then
					showFloor(r.car, nil)
				end
				for _, car in cars do
					if not car.away and not car.state.departs and #car.state.group > 0 then
						Boarding.resume(car.state, t)
						publish(car)
						ready()
					end
				end
			end
			-- a group sent away that's said nothing for a while is gone: its dial forgets it
			for _, car in cars do
				local far = car.far
				if far and t - far.heard > Trip.WordStale then
					car.far = nil
					if far.floor then
						showFloor(car, nil)
					end
				end
			end
			local players = Players:GetPlayers() -- one list a step, for all six cars
			for _, car in cars do
				if car.away or car.holding then
					continue
				end
				local counting = car.state.departs ~= nil
				local changed = false
				for _, player in players do
					local root = rootOf(player)
					local inside = root ~= nil
						and car.zone:contains((root.Position :: any) :: vector)
					if see(car, player, inside, t) then
						changed = true
					end
				end
				if changed then
					if climbing then
						car.state.departs = nil -- held while another group climbs
					elseif not counting and car.state.departs then
						ready()
					end
					publish(car)
				end
			end
		end,
		stop = function(_: any)
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			if hearing then
				hearing:Disconnect()
				hearing = nil
			end
			if departing then
				departing:disconnect()
				departing = nil
			end
			for _, thread in returns do
				if coroutine.status(thread) ~= "dead" then
					task.cancel(thread)
				end
			end
			table.clear(returns)
			table.clear(cars)
			ridden, holding = nil, nil
			if remote then
				remote:Destroy()
				remote = nil
			end
			if folder then
				folder:Destroy()
				folder = nil
			end
		end,
		home = function(_: any): { Back }?
			return home()
		end,
		welcome = function(_: any, results: string)
			welcome(results)
		end,
	}
	return system
end

return LobbyCars
