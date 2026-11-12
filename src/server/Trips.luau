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
	  `Trip.Wait` after the first, each is streamed floor 1's car and they're stood in it
	  `Trip.Since` into its ride (Climbs' `arrive`); their screens open on the shaft sliding past.
	- Anyone after that (a slow phone; someone who respawned at the front office) is stood on the
	  floor the climb is on, in front of its car (Climbs' `arrival`), once there's one to stand on.
	- Once that climb is over the group is back in its lobby car (`home`, L-08e2, LobbyCars) and
	  this server is a lobby of their own: nobody is stood in a climb any more, and their next
	  climb rides up from the car on this server.

	Stepped every frame, but only the lobby's waits on riders and the group's wait cost anything.
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Climb = require(ReplicatedStorage.Shared.Climb)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local Trip = require(ReplicatedStorage.Shared.Lobby.Trip)
local Climbs = require(script.Parent.Climbs)
local FrontOffice = require(script.Parent.FrontOffice)

-- The trip's data (Trip.Data), spelled out here as a cross-folder require's types don't reach
-- every caller's checker.
export type Data = {
	v: number,
	group: { number },
	difficulty: string,
	bay: number,
	friends: boolean,
	players: number,
}

export type Trips = Brix.System & {
	-- Whether this is a group's own server: its climb starts in floor 1's car, no lobby cars.
	own: (self: any) -> boolean,
	-- Whether this lobby sends its cars' groups to servers of their own (else they ride here).
	sends: (self: any) -> boolean,
	-- Sends `players` to a new server of their own with `data`. `failed` is called once for each
	-- of them still here whose trip failed for good. Doesn't yield.
	send: (self: any, players: { Player }, data: Data, failed: (player: Player) -> ()) -> (),
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
}
type Sending = { sent: Sent, tries: number, deadline: number }

local STUDIO = RunService:IsStudio()
-- Studs from the front office's spawn within which a new character on a group's own server has
-- spawned there (a respawn) rather than been stood in the climb by whoever loaded it.
local AT_SPAWN = 40
-- Seconds the group's server waits at most for floor 1's car to stream to the riders' screens.
local STREAM_MOST = 4

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
	local placing: { [Player]: true } = {} -- being stood on the climb's floor now
	local spawnAt: Vector3? = nil -- the front office's spawn
	local folder: Folder? = nil
	local homed = false -- the first climb is over: the group is in the lobby

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
		if sent.open == 0 then
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
			if player.Parent and character then
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
	-- climb loads itself (the end's Again, a friend cut free) is moved off the spawn in the same
	-- frame, so a frame later it isn't there.
	local function newCharacter(player: Player)
		if not placed[player] or homed then
			return
		end
		task.defer(function()
			task.wait()
			local root = rootOf(player)
			local s = spawnAt
			if root and s and (root.Position - s).Magnitude <= AT_SPAWN then
				standLate(player)
			end
		end)
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
			data = d or Trip.encode({ player.UserId }, Boarding.Difficulties[1]) :: Data
		end
		firstAt = firstAt or now()
		table.insert(here, player)
		table.insert(
			connections,
			player.CharacterAdded:Connect(function()
				newCharacter(player)
			end)
		)
		if rodeAt and not homed then
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

	-- This server becomes a group's own: floor 1 laid now, arrivals waited for.
	local function becomeOwn()
		if isOwn then
			return
		end
		isOwn = true
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
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					resolve(player, true) -- a rider leaving the lobby went on their trip
					placed[player], placing[player] = nil, nil
					local i = table.find(here, player)
					if i then
						table.remove(here, i)
					end
				end)
			)
			local reserved = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
			if reserved or dev == "Arrive" then
				becomeOwn()
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
			for _, player in here do
				if not rootOf(player) and now() < (firstAt :: number) + Trip.Wait then
					return -- a character still loading, while there's time to wait for it
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
			-- a new reserved server for this group: the first teleport with a new id makes it
			options.ReservedServerId = HttpService:GenerateGUID(false)
			options:SetTeleportData(d)
			local sent: Sent = { options = options, failed = failed, open = #going, gone = 0 }
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
		end,
		difficulty = function(_: any): string?
			local d = data
			return if isOwn and d then d.difficulty else nil
		end,
		data = function(_: any): Data?
			return if isOwn then data else nil
		end,
		home = function(_: any)
			homed = true
			table.clear(placed)
		end,
	}
	return system
end

return Trips
