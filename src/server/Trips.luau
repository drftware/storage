--!strict
--[[
	Trips: a lobby car's group goes to a server of its own (L-08e1c, GDD "The lobby"), as DOORS'
	lobby elevators send each group to its own server. The smallest stand-in for the matchmaking
	Brix's round loop will own (ENG-13, not built: docs/FRAMEWORK.md). A system on the server.

	On a lobby (a public server):
	- `send` teleports a car's riders, all in one TeleportAsync, to a new reserved server (a fresh
	  GUID as `TeleportOptions.ReservedServerId`), the group and difficulty as its data
	  (Trip.encode). A failure worth it (Trip.retry) is tried again to the same server, so a group
	  never splits over a hiccup; a rider still here `Trip.GiveUp` after their last try has failed
	  too. Each failure is handed back once (LobbyCars puts them back in their car).
	- `sends`: whether this lobby sends groups at all. On a live server, until `Trip.FallbackAfter`
	  trips in a row have failed: then its groups ride to floor 1 on this server (as before
	  L-08e1c), so the game stays playable. In Studio only with Workspace's DevTrip "Send" (it
	  rides here otherwise, D-120).

	On a group's own server (`own`: reserved, with no owner; in Studio, DevTrip "Arrive", or a
	test server whose first player came on a trip):
	- Floor 1 is laid the moment it starts (Climbs' `ready`). Players arrive with black screens
	  (TripView). The first one's data says whom to wait for; once they're all here, or
	  `Trip.Wait` after the first, and every screen here has said it's loaded
	  (`Trip.ReadyRemote`, at most `Trip.LoadMost`), each is streamed floor 1's car and they're
	  stood in it `Trip.Since` into its ride (Climbs' `arrive`); their screens open on the shaft
	  sliding past.
	- Anyone after that (a slow phone; someone who respawned at the front office) is stood on the
	  floor the climb is on, in front of its car (Climbs' `arrival`), once there's one to stand on.
	- Once that climb is over the group is back in its lobby car (`home`, L-08e2, LobbyCars) and
	  this server is a lobby of their own: nobody is stood in a climb any more, and their next
	  climb rides up from the car on this server. Anyone arriving then is in the lobby with them.
	- Share and follow (L-08e3b): the group's reserved id goes on Workspace (`Trip.ServerAttribute`)
	  so an invite from here carries it (CarPanel). Until their first climb is over, the floor
	  they're on goes back to the lobby they left (MessagingService on its `Trip.topic`), as it
	  changes and every `Trip.WordEvery`; 0 once it's over, or as this server shuts.

	Taken-up finds across the trip (S5-03d4, D-358, D-304): as a car's group is sent, each find out
	of a rider's job box that a rider holds or wears goes in the data (Slots' `going`) and leaves
	the lobby with them; a trip that fails for good leaves it in hand (`stay`). On the group's
	server each rider's own word about their own finds is held until their save has loaded (the
	lobby lets it go first), then each one it backs (Home.Taken's `backed`) is dealt into its
	holder's slots, already up: before the screens open as the group is stood in floor 1's car,
	or the moment the save loads after that. The rest stays in the box. The climb's end clears
	what was never dealt.

	A friend's invite from a group's own server, on a lobby (`follow`, called by LobbyCars as
	their launch data arrives): their screen goes black ("Joining Sam") and they're sent on, alone,
	to that server (the same reserved id), with whom they came for; there they're stood beside the
	group (Climbs' `arrival`, as a late arrival) or in the lobby with them. A failure there is
	tried again as a group's is; failing for good, the black lifts in the lobby they landed in.

	Stepped every frame, but only the lobby's waits on riders and the group's wait cost anything.
]]
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserService = game:GetService("UserService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Climb = require(ReplicatedStorage.Shared.Climb)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local ToLobby = require(ReplicatedStorage.Shared.ToLobby)
local Trip = require(ReplicatedStorage.Shared.Lobby.Trip)
local Taken = require(ReplicatedStorage.Shared.Home.Taken)
local Climbs = require(script.Parent.Climbs)
local FrontOffice = require(script.Parent.FrontOffice)
local Saving = require(script.Parent.Saving)
local Slots = require(script.Parent.Slots)

-- The trip's data (Trip.Data), spelled out here as a cross-folder require's types don't reach
-- every caller's checker.
export type Data = {
	v: number,
	group: { number },
	difficulty: string,
	bay: number,
	friends: boolean,
	players: number,
	server: string,
	lobby: string,
	by: number,
	finds: { Slots.Up },
}

export type Trips = Brix.System & {
	-- Whether this is a group's own server: its climb starts in floor 1's car, no lobby cars.
	own: (self: any) -> boolean,
	-- Whether this lobby sends its cars' groups to servers of their own (else they ride here).
	sends: (self: any) -> boolean,
	-- Sends `players` to a new server of their own with `data`. `failed` is called once for each
	-- of them still here whose trip failed for good. Doesn't yield.
	send: (self: any, players: { Player }, data: Data, failed: (player: Player) -> ()) -> (),
	-- Sends `player`, who came by `by`'s invite, on to that friend's group's own server (`to`, its
	-- reserved id). Their screen goes black first; a failure for good lifts it. Yields.
	follow: (self: any, player: Player, to: string, by: number) -> (),
	-- The group's own server's reserved id, where it's known; nil elsewhere.
	server: (self: any) -> string?,
	-- The difficulty the group brought, on a group's own server; nil elsewhere.
	difficulty: (self: any) -> string?,
	-- The data the group came with (its order, the car it left in), on a group's own server; nil
	-- elsewhere.
	data: (self: any) -> Data?,
	-- The group's first climb is over and they're back in the lobby (L-08e2): nobody is stood in
	-- that climb any more (a respawn stays at the front office, as on any lobby).
	home: (self: any) -> (),
}

-- One send: its riders and how they came out.
type Sent = {
	options: TeleportOptions,
	failed: (player: Player) -> (),
	open: number, -- riders not yet gone or failed
	gone: number, -- riders who left for the group's server
	counts: boolean, -- a group's trip, which counts toward the lobby's fallback (a friend's doesn't)
}
type Sending = { sent: Sent, tries: number, deadline: number }

local STUDIO = RunService:IsStudio()
-- Studs from the front office's spawn within which a new character on a group's own server has
-- spawned there (a respawn) rather than been stood in the climb by whoever loaded it.
local AT_SPAWN = 40
-- Seconds the group's server waits at most for floor 1's car to stream to the riders' screens.
local STREAM_MOST = 4
-- Seconds between looks at taken-up finds still waiting on a save to load (S5-03d4).
local DEAL_EVERY = 0.5
-- Studio only, with DevTrip "Arrive": the finds the first player says they took up from their own
-- box ("Boombox,Lamp*": a star for cracked, "^" before a name to wear it), as a live trip's data
-- would carry them.
local DEV_FINDS = "DevTripFinds"

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Streams the world around `at` to each of `players`' screens, all at once; returns when they're
-- in or `most` seconds have passed. Yields.
local function streamTo(players: { Player }, at: Vector3, most: number)
	local left = #players
	for _, player in players do
		task.spawn(function()
			local ok, err = pcall(function()
				player:RequestStreamAroundAsync(at, Climb.StreamWait)
			end)
			if not ok and player.Parent then
				warn(`Trips: couldn't stream the climb to {player.Name}: {err}`)
			end
			left -= 1
		end)
	end
	local until_ = os.clock() + most
	while left > 0 and os.clock() < until_ do
		task.wait()
	end
end

local Trips = {}

function Trips.new(): Trips
	local climbs: Climbs.Climbs? = nil
	local office: FrontOffice.FrontOffice? = nil
	local slots: Slots.Slots? = nil
	local saving: Saving.SavingSystem? = nil
	local connections: { RBXScriptConnection } = {}
	local threads: { thread } = {}
	local isOwn = false
	local dev = if STUDIO then Workspace:GetAttribute(Trip.DevAttribute) else nil

	-- the lobby's side
	local sending: { [Player]: Sending } = {}
	local failedInRow = 0

	-- the group's own server's side
	local data: Data? = nil
	local firstAt: number? = nil
	local here: { Player } = {} -- who's arrived, in the order they came
	local boarding = false -- the group is being stood in its car
	local rodeAt: number? = nil -- server time they were
	local placed: { [Player]: true } = {} -- stood in the climb at least once
	local loaded: { [Player]: true } = {} -- their screen said it has loaded (Trip.ReadyRemote)
	local ready: RemoteEvent? = nil
	local placing: { [Player]: true } = {} -- being stood on the climb's floor now
	local spawnAt: Vector3? = nil -- the front office's spawn
	local folder: Folder? = nil
	local homed = false -- the first climb is over: the group is in the lobby
	local toldFloor: number? = nil -- the floor last sent to the lobby they left
	local toldAt = 0 -- os.clock() it was sent
	-- each owner's own word about the finds they took up, by UserId, not yet dealt (S5-03d4)
	local ups: { [number]: { Slots.Up } } = {}
	local dealAt = 0 -- os.clock() of the next look at them

	local function spawn(f: () -> ())
		local thread = task.spawn(f)
		if coroutine.status(thread) ~= "dead" then
			table.insert(threads, thread)
		end
	end

	-- `player`'s trip came out: gone to the group's server, or failed for good.
	local function resolve(player: Player, gone: boolean)
		local entry = sending[player]
		if not entry then
			return
		end
		sending[player] = nil
		local sent = entry.sent
		sent.open -= 1
		if gone then
			sent.gone += 1
		end
		-- the send's count first, so a failure handed back sees whether this lobby still sends
		if sent.open == 0 and sent.counts then
			if sent.gone > 0 then
				failedInRow = 0
			else
				failedInRow += 1
				if failedInRow == Trip.FallbackAfter then
					warn(
						`Trips: {failedInRow} trips in a row failed; this lobby's groups ride to floor 1 on this server now`
					)
				end
			end
		end
		if not gone and player.Parent then
			local s = slots
			if s then
				s:stay(player) -- what they took up stays in hand
			end
			task.spawn(sent.failed, player)
		end
	end

	-- One teleport of `players` (all of the same send), tried at once. Yields.
	local function teleport(players: { Player }, options: TeleportOptions): (boolean, string?)
		local going: { Player } = {}
		for _, player in players do
			if player.Parent then
				table.insert(going, player)
			end
		end
		if #going == 0 then
			return true, nil
		end
		if dev == "Fail" then
			return false, "Studio's DevTrip is Fail" -- the failed trip, tried in Studio
		end
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, going, options)
		end)
		return ok, if ok then nil else tostring(err)
	end

	-- Roblox couldn't start `player`'s teleport: tried again if it's worth it, else failed.
	local function initFailed(player: Player, result: Enum.TeleportResult, message: string)
		local entry = sending[player]
		if not entry then
			return
		end
		local wait = Trip.retry(result.Name, entry.tries)
		if not wait then
			warn(`Trips: {player.Name}'s trip failed ({result.Name}: {message})`)
			resolve(player, false)
			return
		end
		entry.tries += 1
		entry.deadline = os.clock() + wait + Trip.GiveUp
		spawn(function()
			task.wait(wait)
			if sending[player] ~= entry or not player.Parent then
				return
			end
			local ok, err = teleport({ player }, entry.sent.options)
			if not ok then
				warn(`Trips: {player.Name}'s trip failed again: {err}`)
				resolve(player, false)
			end
		end)
	end

	-- Whether `player`'s character may be stood at the car now (`Trip.standsLate`): still on the
	-- front office's spawn, and neither being carried up by the climb nor held in a unit. A friend
	-- left behind is given a new character on the spawn and stood wrapped in a unit of their own
	-- (KeptPlayers:store); stood at the car instead, two landed on one spot, far from the units
	-- their Cut free is judged at (S3-05a).
	local function mayStand(player: Player): boolean
		local root = rootOf(player)
		if not root then
			return false
		end
		local s, c = spawnAt, climbs
		return Trip.standsLate(
			s == nil or (root.Position - s).Magnitude <= AT_SPAWN,
			c ~= nil and c:carrying(player) ~= nil,
			-- held in a unit, or sent down to the lobby car (S4-03c4): never back in the climb
			player:GetAttribute(Kept.Attribute) == true
				or player:GetAttribute(ToLobby.Attribute) ~= nil
		)
	end

	-- Stands `player` on the floor the climb is on, in front of its car, once there's one to stand
	-- on and the group's car is open (a late arrival, or a respawn at the front office).
	local function standLate(player: Player)
		if placing[player] then
			return
		end
		placing[player] = true
		spawn(function()
			local c = climbs :: Climbs.Climbs
			local spot: CFrame? = nil
			local giveUp = os.clock() + Trip.CoverMost
			while player.Parent and os.clock() < giveUp and not homed do
				local opened = rodeAt ~= nil
					and now() >= (rodeAt :: number) + Ride.opens() - Trip.Since
				spot = if opened then c:arrival() else nil
				if spot and rootOf(player) then
					break
				end
				task.wait(0.25)
			end
			if not (player.Parent and spot) or homed then
				placing[player] = nil
				return
			end
			local at = spot :: CFrame
			streamTo({ player }, at.Position, STREAM_MOST)
			local character = player.Character
			-- asked again after the stream: the climb may have taken them meanwhile
			if player.Parent and character and mayStand(player) then
				character:PivotTo(at)
				placed[player] = true
				player:SetAttribute(Trip.ArrivedAttribute, at)
				if STUDIO then
					print(`Trips: {player.Name} came late; stood on the climb's floor`)
				end
			end
			placing[player] = nil
		end)
	end

	-- A new character on a group's own server: one that spawned at the front office after its
	-- player was stood in the climb (a respawn) goes back to the climb's floor. A character the
	-- climb loads itself (the end's Again, a friend cut free, a friend carried up) is moved off
	-- the spawn in the same frame, so a frame later it isn't there; one carried up is skipped
	-- outright besides (`mayStand`).
	local function newCharacter(player: Player)
		if not placed[player] or homed then
			return
		end
		task.defer(function()
			task.wait()
			if spawnAt and mayStand(player) then
				standLate(player)
			end
		end)
	end

	-- The floor the group is on (0: their climb is over) to the lobby they left, if it's named.
	local function tell(floor: number)
		local d = data
		if not (d and d.lobby ~= "" and d.server ~= "") then
			return
		end
		toldFloor, toldAt = floor, os.clock()
		local topic, word = Trip.topic(d.lobby), Trip.word(d.server, floor)
		task.spawn(function()
			local ok, err = pcall(function()
				MessagingService:PublishAsync(topic, word)
			end)
			if not ok then
				warn(`Trips: couldn't tell the lobby floor {floor}: {err}`)
			end
		end)
	end

	-- `player` arrived after the group's first climb: they're in the lobby with them, wherever
	-- they spawned, and their screen's black lifts there.
	local function inLobby(player: Player)
		spawn(function()
			local giveUp = os.clock() + Trip.CoverMost
			while player.Parent and not player.Character and os.clock() < giveUp do
				task.wait(0.25)
			end
			local character = player.Character
			if player.Parent and character then
				player:SetAttribute(Trip.ArrivedAttribute, character:GetPivot())
			end
		end)
	end

	-- Studio's stand-in for a trip's taken-up finds (DEV_FINDS), all `owner`'s, in their hands.
	local function devFinds(owner: number): { Slots.Up }
		local out: { Slots.Up } = {}
		local said = Workspace:GetAttribute(DEV_FINDS)
		if type(said) ~= "string" then
			return out
		end
		for word in string.gmatch(said, "[^,%s]+") do
			local worn = string.sub(word, 1, 1) == "^"
			local cracked = string.sub(word, -1) == "*"
			local name = string.gsub(word, "[%^%*]", "")
			table.insert(
				out,
				{ owner = owner, name = name, holder = owner, cracked = cracked, worn = worn }
			)
		end
		return out
	end

	-- Deals each owner's taken-up finds whose save has loaded (S5-03d4): only what it backs, each
	-- into its holder's slots (its owner's when the holder isn't here), already up. `quiet`: their
	-- screens are still black. The rest stays in the box.
	local function dealUps(quiet: boolean)
		local s, sv = slots, saving
		if not (s and sv) then
			return
		end
		for owner, list in ups do
			local player = Players:GetPlayerByUserId(owner)
			local save = if player then sv:data(player) else nil
			if not (player and save and rootOf(player)) then
				continue -- their save still on its way from the lobby, or no body yet
			end
			ups[owner] = nil
			local dealt = 0
			for _, u in Taken.backed(list, owner, save, s:fromBox(player)) do
				local holder = Players:GetPlayerByUserId(u.holder)
				local into = if holder
						and table.find(here, holder)
						and rootOf(holder)
					then holder
					else player
				if
					s:carryUp(into, u, quiet) or (into ~= player and s:carryUp(player, u, quiet))
				then
					dealt += 1
				end
			end
			if STUDIO then
				print(`Trips: {dealt} of {#list} finds {player.Name} took up came across the trip`)
			end
		end
	end

	-- `player` arrived on a group's own server.
	local function arrived(player: Player)
		if table.find(here, player) then
			return
		end
		local d: Data? = nil
		local ok, join = pcall(function()
			return player:GetJoinData()
		end)
		if ok and type(join) == "table" then
			-- any: GetJoinData's dictionary; its TeleportData passed through the player's device
			-- and is checked by Trip.decode
			d = Trip.decode((join :: any).TeleportData) :: Data?
		end
		if not data then
			-- the first one's word says whom to wait for; Studio's "Arrive" waits for nobody else
			local first: Data = d
				or Trip.encode({ player.UserId }, Boarding.Difficulties[1]) :: Data
			data = first
			if first.server ~= "" then
				Workspace:SetAttribute(Trip.ServerAttribute, first.server)
			end
		end
		-- their own word about their own finds taken up (anyone's else is theirs to say)
		local finds: { Slots.Up } = if d then d.finds else {}
		if STUDIO and dev == "Arrive" and not d then
			finds = devFinds(player.UserId)
		end
		local mine: { Slots.Up } = {}
		for _, u in finds do
			if u.owner == player.UserId then
				table.insert(mine, u)
			end
		end
		if #mine > 0 and not homed then
			ups[player.UserId] = mine
		end
		-- a friend sent on by an invite: pointed to whoever invited them, once the group's home
		if d and d.by ~= 0 then
			player:SetAttribute(Boarding.InvitedAttribute, d.by)
		end
		firstAt = firstAt or now()
		table.insert(here, player)
		table.insert(
			connections,
			player.CharacterAdded:Connect(function()
				newCharacter(player)
			end)
		)
		if homed then
			inLobby(player)
		elseif rodeAt then
			standLate(player)
		end
	end

	-- Everyone's here (or the wait's up): stood in floor 1's car mid-ride, the host in front.
	local function board(car: Model)
		local d = data :: Data
		local riders: { Player } = {}
		for _, player in here do
			if player.Parent and rootOf(player) then
				table.insert(riders, player)
			end
		end
		table.sort(riders, function(a: Player, b: Player): boolean
			local i = table.find(d.group, a.UserId) or math.huge
			local j = table.find(d.group, b.UserId) or math.huge
			if i ~= j then
				return i < j
			end
			return (table.find(here, a) or 0) < (table.find(here, b) or 0)
		end)
		streamTo(riders, car:GetPivot().Position, STREAM_MOST)
		local c = climbs :: Climbs.Climbs
		local still: { Player } = {}
		for _, player in riders do
			if player.Parent and rootOf(player) then
				table.insert(still, player)
			end
		end
		dealUps(true) -- in their hands before their screens open on the shaft
		if #still == 0 or not c:arrive(still, Trip.Since) then
			boarding = false -- tried again next step
			return
		end
		local t = now()
		rodeAt = t
		for _, player in still do
			placed[player] = true
			local character = player.Character
			if character then
				player:SetAttribute(Trip.ArrivedAttribute, character:GetPivot())
			end
		end
		-- anyone here who wasn't ready (no character yet) comes in as the car opens
		for _, player in here do
			if player.Parent and not placed[player] then
				standLate(player)
			end
		end
		if STUDIO then
			print(
				`Trips: the group's car is riding up to floor 1 ({#still} aboard, {d.difficulty})`
			)
		end
	end

	-- Sends `players` (those not already going) on one teleport with `d`, to the server it names
	-- (else a new one). `counts`: a group's trip, toward the fallback. Doesn't yield.
	local function sendNow(
		players: { Player },
		d: Data,
		counts: boolean,
		failed: (player: Player) -> ()
	)
		local going: { Player } = {}
		for _, player in players do
			if player.Parent and not sending[player] then
				table.insert(going, player)
			end
		end
		if #going == 0 then
			return
		end
		local options = Instance.new("TeleportOptions")
		-- the group's own server: the first teleport with a new id makes it, the same id again
		-- lands on it
		options.ReservedServerId = if d.server ~= ""
			then d.server
			else HttpService:GenerateGUID(false)
		options:SetTeleportData(d)
		local sent: Sent =
			{ options = options, failed = failed, open = #going, gone = 0, counts = counts }
		local deadline = os.clock() + Trip.GiveUp
		for _, player in going do
			sending[player] = { sent = sent, tries = 1, deadline = deadline }
		end
		spawn(function()
			local tries = 1
			while true do
				local ok, err = teleport(going, options)
				if ok then
					return
				end
				local wait = Trip.retry("Failure", tries)
				if not wait then
					warn(`Trips: the trip failed: {err}`)
					for _, player in going do
						resolve(player, false)
					end
					return
				end
				tries += 1
				for _, player in going do
					local entry = sending[player]
					if entry then
						entry.tries = tries
						entry.deadline = os.clock() + wait + Trip.GiveUp
					end
				end
				task.wait(wait)
			end
		end)
	end

	-- This server becomes a group's own: floor 1 laid now, arrivals waited for.
	local function becomeOwn()
		if isOwn then
			return
		end
		isOwn = true
		-- a screen that has loaded says so (it carries nothing to check): the group waits for
		-- it, so a slow phone opens on the ride rather than on a car already open
		local remotes = ReplicatedStorage:FindFirstChild(Trip.RemoteFolder)
		if not remotes then
			remotes = Instance.new("Folder")
			remotes.Name = Trip.RemoteFolder
			remotes.Parent = ReplicatedStorage
		end
		local r = Instance.new("RemoteEvent")
		r.Name = Trip.ReadyRemote
		r.Parent = remotes
		ready = r
		table.insert(
			connections,
			r.OnServerEvent:Connect(function(player: Player)
				loaded[player] = true
			end)
		)
		Workspace:SetAttribute(Trip.OwnAttribute, true)
		local f = Instance.new("Folder")
		f.Name = "GroupClimb"
		f.Parent = Workspace
		folder = f
		local c = climbs :: Climbs.Climbs
		c:ready({
			seed = Random.new():NextInteger(1, 2 ^ 31 - 1),
			number = 1,
			origin = Lobby.ClimbOrigin,
			parent = f,
		})
		local o = office
		local laid = o and o:laid()
		if laid then
			spawnAt = Lobby.spawn(laid.pivot).Position
		end
		table.insert(connections, Players.PlayerAdded:Connect(arrived))
		for _, player in Players:GetPlayers() do
			arrived(player)
		end
		if STUDIO then
			print("Trips: a group's own server; floor 1 is laying, waiting for the group")
		end
	end

	local system: Trips = {
		name = "Trips",
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system
			-- (init.server), and these start before this one
			climbs = (registry:get("climbs") :: any) :: Climbs.Climbs
			office = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice -- any: as above
			slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
			saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					resolve(player, true) -- a rider leaving the lobby went on their trip
					placed[player], placing[player], loaded[player] = nil, nil, nil
					ups[player.UserId] = nil
					local i = table.find(here, player)
					if i then
						table.remove(here, i)
					end
				end)
			)
			local reserved = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
			if reserved or dev == "Arrive" then
				becomeOwn()
				-- shutting mid-climb (the group left): the lobby's dial forgets them now
				game:BindToClose(function()
					local d = data
					if isOwn and not homed and toldFloor and d and d.lobby ~= "" then
						pcall(function()
							MessagingService:PublishAsync(
								Trip.topic(d.lobby),
								Trip.word(d.server, 0)
							)
						end)
					end
				end)
				return
			end
			table.insert(
				connections,
				TeleportService.TeleportInitFailed:Connect(
					function(player: Instance, result: Enum.TeleportResult, message: string)
						if player:IsA("Player") then
							initFailed(player, result, message)
						end
					end
				)
			)
			if STUDIO then
				-- Studio's test teleports open the group's server as a new test server from the
				-- place as last saved (no DevTrip there) and an empty PrivateServerId: there, the
				-- first player arriving on a trip makes it one
				table.insert(
					connections,
					Players.PlayerAdded:Connect(function(player: Player)
						if isOwn or #Players:GetPlayers() > 1 then
							return
						end
						local ok, join = pcall(function()
							return player:GetJoinData()
						end)
						-- any: GetJoinData's dictionary, checked by Trip.decode
						if
							ok
							and type(join) == "table"
							and Trip.decode((join :: any).TeleportData)
						then
							becomeOwn()
						end
					end)
				)
			end
		end,
		step = function(_: any, _dt: number)
			if next(sending) ~= nil then
				local clock = os.clock()
				for player, entry in sending do
					if clock >= entry.deadline then
						warn(
							`Trips: {player.Name} didn't leave within {Trip.GiveUp} s; their trip failed`
						)
						resolve(player, false)
					end
				end
			end
			if isOwn and rodeAt and not homed and next(ups) ~= nil and os.clock() >= dealAt then
				dealAt = os.clock() + DEAL_EVERY
				dealUps(false)
			end
			if isOwn and rodeAt and not homed then
				local c = climbs
				local on = c and c:current()
				if on and (on.number ~= toldFloor or os.clock() >= toldAt + Trip.WordEvery) then
					tell(on.number)
				end
			end
			if not isOwn or rodeAt or boarding then
				return
			end
			local d = data
			local c = climbs
			local car = c and c:readied()
			if not (d and car) then
				return
			end
			local ids: { number } = table.create(#here)
			for i, player in here do
				ids[i] = player.UserId
			end
			if not Trip.ready(d.group, ids, firstAt, now()) then
				return
			end
			local waited = now() - (firstAt :: number)
			for _, player in here do
				if not rootOf(player) and waited < Trip.Wait then
					return -- a character still loading, while there's time to wait for it
				end
				if not loaded[player] and waited < Trip.LoadMost then
					return -- a screen still loading, which would miss the ride
				end
			end
			boarding = true
			spawn(function()
				board(car)
			end)
		end,
		stop = function(_: any)
			for _, conn in connections do
				conn:Disconnect()
			end
			table.clear(connections)
			for _, thread in threads do
				if coroutine.status(thread) ~= "dead" then
					task.cancel(thread)
				end
			end
			table.clear(threads)
			table.clear(sending)
			if ready then
				ready:Destroy()
				ready = nil
			end
			table.clear(loaded)
			if folder then
				folder:Destroy()
				folder = nil
			end
		end,
		own = function(_: any): boolean
			return isOwn
		end,
		sends = function(_: any): boolean
			if isOwn then
				return false
			end
			if STUDIO then
				return (dev == "Send" or dev == "Fail") and failedInRow < Trip.FallbackAfter
			end
			return game.PlaceId ~= 0 and failedInRow < Trip.FallbackAfter
		end,
		send = function(_: any, players: { Player }, d: Data, failed: (player: Player) -> ())
			-- what they took up out of their boxes goes with them (S5-03d4)
			local s = slots
			local withFinds = table.clone(d)
			withFinds.finds = if s then s:going(players) else {}
			sendNow(players, withFinds, true, failed)
		end,
		follow = function(_: any, player: Player, to: string, by: number)
			if isOwn or sending[player] or not Trip.isServer(to) then
				return
			end
			-- their friend's name for the black ("Joining Sam"), if Roblox gives it
			local name = ""
			local ok, infos = pcall(function()
				return UserService:GetUserInfosByUserIdsAsync({ by })
			end)
			local info = if ok and type(infos) == "table" then infos[1] else nil
			if info and type(info.DisplayName) == "string" then
				name = info.DisplayName
			end
			if not player.Parent then
				return
			end
			player:SetAttribute(Trip.FollowAttribute, name)
			task.wait(Trip.Fade + 0.1) -- their screen is black
			if not player.Parent then
				return
			end
			local d = Trip.encode(
				{ player.UserId },
				Boarding.Difficulties[1],
				nil,
				{ server = to, lobby = "", by = by }
			) :: Data
			sendNow({ player }, d, false, function(p: Player)
				p:SetAttribute(Trip.FollowAttribute, nil)
			end)
		end,
		server = function(_: any): string?
			local d = data
			return if isOwn and d and d.server ~= "" then d.server else nil
		end,
		difficulty = function(_: any): string?
			local d = data
			return if isOwn and d then d.difficulty else nil
		end,
		data = function(_: any): Data?
			return if isOwn then data else nil
		end,
		home = function(_: any)
			if not homed and toldFloor then
				tell(0)
			end
			homed = true
			table.clear(placed)
			table.clear(ups) -- never dealt: it stays in the box
		end,
	}
	return system
end

return Trips
