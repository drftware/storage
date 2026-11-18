--!strict
--[[
	ClimbEnds: the climb's end and "Again" on the server (L-08d, ClimbEnd, the GDD's "Whole team
	kept"), a system. The smallest stand-in for Brix's round loop's results (ENG-13, unbuilt).

	- Kept (a loss): nobody left climbing, everyone kept in a unit, left behind watching or being
	  carried up to the next floor's units (`ClimbEnd.look`, Climbs' `carrying`; `ClimbEnd.over`;
	  in Studio a stand-in friend counts as climbing). It ends on the last free friend's catch
	  cutting to black (`ClimbEnd.AfterCatch` after they were kept); from then the carries stop
	  where they are (Climbs' `ending`), so nobody is handed a new character under the black.
	  While the wipe's offer is on sale (CutFrees' `offers`: Free Everyone, or Cut Free alone,
	  S3-03c) it waits first: `ClimbEnd.WaitAttribute` on Workspace from the moment everyone's
	  caught tells every caught screen to show it, and the end comes `ClimbEnd.OfferFor` after
	  the catch, later while a prompt is open (`ClimbEnd.ends`). Anyone freed meanwhile and the
	  climb carries on from this floor.
	- Top (an escape): the car leaves the top floor with friends aboard (Climbs' `topped`). It ends
	  from the moment the gate hit its post, so the ride plays out first.
	- Each player's fate goes on them (`ClimbEnd.FateAttribute`: out, kept or left, and the floor
	  they were lost on, are kept on now, or reached), then the end on Workspace (`ClimbEnd.Attribute`), so every
	  screen plays it from the same moment (EndView).
	- At `ClimbEnd.cover`, when every screen is covered: whatever anyone carries drops, the climb
	  stops and its floors go (Climbs' `finish`), the watchers are let go of (Watching's
	  `release`), and every character goes, so nothing can reach anyone behind the results
	  (`covered` fires: CashOut takes the coin counts off screen).
	- The results board carries each friend's cash from the climb (`Cash.EarnedAttribute`, set by
	  CashOut as it ended, S1-12), cleared with the end.
	- "Again" (`Remotes.Again`, checked: the results are up, the player hasn't pressed, the rate):
	  marks them in (`ClimbEnd.InAttribute`). Once everyone's in, or `ClimbEnd.AgainWait` after the
	  first press (`ClimbEnd.StartAttribute`, so every screen counts down), `go`: back in the lobby
	  (L-08e2), the climb's group given characters standing in the car they left from, facing its
	  back wall, the rest at the front office (LobbyCars' `home`); then the results go on the car's
	  wall and its count runs (`welcome`), the end is cleared and every screen lifts onto the car.
	  A climb no lobby car started (the test hall's, in Studio) goes on to floor 1 of a fresh
	  building instead, everyone side by side in its lobby.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Cash = require(ReplicatedStorage.Shared.Cash)
local Climb = require(ReplicatedStorage.Shared.Climb)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Left = require(ReplicatedStorage.Shared.Left)
local ToLobby = require(ReplicatedStorage.Shared.ToLobby)
local Climbs = require(script.Parent.Climbs)
local CutFrees = require(script.Parent.CutFrees)
local LobbyCars = require(script.Parent.LobbyCars)
local Slots = require(script.Parent.Slots)
local Watching = require(script.Parent.Watching)

-- No climb; a climb on; its end showing, before the screens are covered; the results up; the
-- next climb being laid.
type Phase = "Idle" | "Climbing" | "Ending" | "Results" | "Starting"

local STUDIO = RunService:IsStudio()
-- Seconds the next climb waits for every new character before it lifts the screens anyway.
local LOAD_WAIT = 10

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Studio only: the living stand-in friends (Left.StandInTag), who count as friends climbing.
local function standIns(): number
	if not STUDIO then
		return 0
	end
	local n = 0
	for _, inst in CollectionService:GetTagged(Left.StandInTag) do
		if inst:IsA("Model") and inst:IsDescendantOf(Workspace) then
			local humanoid = inst:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				n += 1
			end
		end
	end
	return n
end

local ClimbEnds = {}

-- How the climb ended for one player: their fate and the floor it happened on.
export type Ending = { player: Player, fate: ClimbEnd.Fate, floor: number }

-- The climb's end: how (everyone kept or left, or the top), on which floor, and for each player.
export type Ended = { how: ClimbEnd.How, floor: number, endings: { Ending } }

export type ClimbEndsSystem = Brix.System & {
	-- Fires as a climb ends, after each player's fate is on them (Recording, S1-02).
	ended: Brix.Signal<Ended>,
	-- Fires as a player's press of Again is taken.
	again: Brix.Signal<Player>,
	-- Fires as every screen is covered and the climb is taken from under them.
	covered: Brix.Signal<nil>,
}

function ClimbEnds.new(): ClimbEndsSystem
	local endedSignal = Brix.Signal.new() :: Brix.Signal<Ended>
	local againSignal = Brix.Signal.new() :: Brix.Signal<Player>
	local coveredSignal = Brix.Signal.new() :: Brix.Signal<nil>
	local climbs: Climbs.Climbs? = nil
	local watching: Watching.Watching? = nil
	local slots: Slots.Slots? = nil
	local lobbyCars: LobbyCars.LobbyCars? = nil
	local cutFrees: CutFrees.CutFrees? = nil
	local remote: RemoteEvent? = nil
	local connections: { RBXScriptConnection } = {}
	local topping: Brix.SignalConnection? = nil
	local phase: Phase = "Idle"
	local lost: { [Player]: ClimbEnd.Lost? } = {}
	local overSince: number? = nil -- server time nobody was seen climbing
	local startAt: number? = nil -- server time the next climb starts, once someone pressed Again
	local asked: { [Player]: number } = {} -- os.clock() of each player's last press taken
	local since = 0 -- seconds since the last look
	local ends = 0 -- which end it is; a delayed cover from an earlier one stops when it sees another

	-- Who is still climbing, kept, left behind or being carried up (`ClimbEnd.look`); each one
	-- lost is noted with the floor it happened on, or the floor they're carried up to.
	local function look(floor: number): { ClimbEnd.State }
		local states: { ClimbEnd.State } = {}
		local c, w = climbs, watching
		for _, player in Players:GetPlayers() do
			local state, l = ClimbEnd.look(
				lost[player],
				floor,
				player:GetAttribute(Kept.Attribute) == true,
				w ~= nil and w:isOut(player),
				c and c:carrying(player),
				player:GetAttribute(ToLobby.Attribute) ~= nil
			)
			lost[player] = l
			table.insert(states, state)
		end
		return states
	end

	-- Every screen is covered: the climb goes from under it, and everyone's character with it.
	local function cover()
		phase = "Results"
		local s, c, w = slots, climbs, watching
		for _, player in Players:GetPlayers() do
			if s and player.Character then
				s:dropAll(player) -- and they go with the floor
			end
		end
		if c then
			c:finish()
		end
		if w then
			w:release()
		end
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character then
				player.Character = nil
				character:Destroy()
			end
			-- sent down to the lobby (S4-03c4): over with the climb, their fate noted already
			player:SetAttribute(ToLobby.Attribute, nil)
			player:SetAttribute(ToLobby.StoodAttribute, nil)
		end
		coveredSignal:fire(nil)
	end

	local function endClimb(how: ClimbEnd.How, floor: number, at: number)
		if phase ~= "Climbing" then
			return
		end
		phase = "Ending"
		ends += 1
		local mine = ends
		overSince = nil
		look(floor)
		local c = climbs
		if c then
			c:ending()
		end
		local began = (c and c:startedAt()) or at
		local endings: { Ending } = {}
		for _, player in Players:GetPlayers() do
			local l = lost[player]
			local fate: ClimbEnd.Fate = if l then l.fate elseif how == "Top" then "Out" else "Left"
			local on = if l then l.floor else floor
			table.insert(endings, { player = player, fate = fate, floor = on })
			player:SetAttribute(ClimbEnd.FateAttribute, ClimbEnd.encodeFate(fate, on))
			player:SetAttribute(ClimbEnd.InAttribute, nil)
			player:SetAttribute(ClimbEnd.StoodAttribute, nil)
		end
		startAt = nil
		Workspace:SetAttribute(ClimbEnd.StartAttribute, nil)
		Workspace:SetAttribute(ClimbEnd.LobbyAttribute, nil)
		Workspace:SetAttribute(ClimbEnd.Attribute, ClimbEnd.encode(at, how, floor, at - began))
		endedSignal:fire({ how = how, floor = floor, endings = endings })
		if STUDIO then
			print(
				`ClimbEnds: the climb ended ({how}) on floor {floor} after {ClimbEnd.clock(
					at - began
				)}`
			)
		end
		task.delay(math.max(at + ClimbEnd.cover(how) - now(), 0), function()
			if ends == mine and (phase :: Phase) == "Ending" then
				cover()
			end
		end)
	end

	-- Gives every player a character at once, `at[player]` where they're stood (else wherever
	-- they spawn), the `i`th of the rest given `fallback(i)`, and streams the world round them to
	-- their screen (the lobby streams out during a climb: lifted at once, its car would open dark
	-- and half there); returns once they're all in or `LOAD_WAIT` has passed. Yields.
	local function load(at: { [Player]: CFrame }, fallback: ((i: number) -> CFrame)?)
		local players = Players:GetPlayers()
		table.sort(players, function(a: Player, b: Player)
			return a.UserId < b.UserId
		end)
		local loading = #players
		local rest = 0
		for _, player in players do
			local where = at[player]
			if not where and fallback then
				rest += 1
				where = fallback(rest)
			end
			task.spawn(function()
				local ok, err = pcall(function()
					player:LoadCharacter()
				end)
				local character = player.Character
				if ok and character and player.Parent then
					if where then
						character:PivotTo(where)
						player:SetAttribute(ClimbEnd.StoodAttribute, where)
					end
					local around = character:GetPivot().Position
					local streamed, why = pcall(function()
						player:RequestStreamAroundAsync(around, Climb.StreamWait)
					end)
					if not streamed and player.Parent then
						warn(`ClimbEnds: couldn't stream {player.Name}'s spot to them: {why}`)
					end
				elseif not ok and player.Parent then
					warn(`ClimbEnds: couldn't give {player.Name} a character: {err}`)
				end
				loading -= 1
			end)
		end
		local waited = 0
		while loading > 0 and waited < LOAD_WAIT do
			waited += task.wait()
		end
	end

	-- The end is over: the next climb (or the lobby) is under everyone, so every screen lifts.
	local function cleared(after: Phase)
		for _, player in Players:GetPlayers() do
			player:SetAttribute(ClimbEnd.FateAttribute, nil)
			player:SetAttribute(ClimbEnd.InAttribute, nil)
			player:SetAttribute(Cash.EarnedAttribute, nil)
		end
		table.clear(lost)
		startAt, overSince = nil, nil
		Workspace:SetAttribute(ClimbEnd.StartAttribute, nil)
		Workspace:SetAttribute(ClimbEnd.Attribute, nil)
		phase = after
	end

	-- Back in the lobby (L-08e2): the climb's group stood in the car they left from (`group`,
	-- LobbyCars' `home`), everyone else at the front office; then the results on the car's wall
	-- and its count running.
	local function backInLobby(group: { LobbyCars.Back })
		local _, how, floor, seconds = ClimbEnd.decode(Workspace:GetAttribute(ClimbEnd.Attribute))
		local rows: { ClimbEnd.Result } = {}
		local at: { [Player]: CFrame } = {}
		for _, back in group do
			at[back.player] = back.at
			local fate, on = ClimbEnd.decodeFate(back.player:GetAttribute(ClimbEnd.FateAttribute))
			if fate then
				local cash = back.player:GetAttribute(Cash.EarnedAttribute)
				local row: ClimbEnd.Result = {
					userId = back.player.UserId,
					fate = fate :: ClimbEnd.Fate,
					floor = on,
					cash = if type(cash) == "number" then cash else 0,
				}
				table.insert(rows, row)
			end
		end
		Workspace:SetAttribute(ClimbEnd.LobbyAttribute, true)
		load(at, nil)
		local l = lobbyCars
		if l then
			l:welcome(ClimbEnd.encodeResults(how :: ClimbEnd.How, floor, seconds, rows))
		end
		cleared("Idle")
		if STUDIO then
			print(`ClimbEnds: back in the lobby, {#group} in their car`)
		end
	end

	-- Floor 1 of a fresh building, everyone side by side in its lobby: where Again leads from a
	-- climb no lobby car started (the test hall's, in Studio).
	local function freshFloor()
		local c = climbs
		local o = c and c:last()
		local on = nil
		local seed = Random.new():NextInteger(1, 2 ^ 31 - 1)
		if c and o then
			on = c:begin({ seed = seed, number = 1, origin = o.origin, parent = o.parent })
		end
		if not on then
			warn("ClimbEnds: the next climb couldn't be laid; the results stay up")
			phase = "Results"
			startAt = nil
			Workspace:SetAttribute(ClimbEnd.StartAttribute, nil)
			for _, player in Players:GetPlayers() do
				player:SetAttribute(ClimbEnd.InAttribute, nil)
			end
			return
		end
		local where = on.origin * Climbs.Arrival
		load({}, function(i: number): CFrame
			local x, z = ClimbEnd.spot(i)
			return where * CFrame.new(x, 0, z)
		end)
		cleared("Climbing")
		if STUDIO then
			print(`ClimbEnds: again, from floor 1 (seed {seed})`)
		end
	end

	-- Where "Again" leads: back in the lobby's car the climb started from, else a fresh floor 1.
	local function go()
		phase = "Starting"
		Workspace:SetAttribute(ClimbEnd.StartAttribute, now())
		task.spawn(function()
			local l = lobbyCars
			local group = l and l:home()
			if group then
				backInLobby(group)
			else
				freshFloor()
			end
		end)
	end

	-- A screen's press of Again: checked (the results are up, they haven't pressed, its rate).
	local function press(player: Player)
		if phase ~= "Results" or player:GetAttribute(ClimbEnd.InAttribute) == true then
			return
		end
		local t = os.clock()
		if t - (asked[player] or -math.huge) < ClimbEnd.AskEvery then
			return
		end
		asked[player] = t
		player:SetAttribute(ClimbEnd.InAttribute, true)
		if not startAt then
			startAt = now() + ClimbEnd.AgainWait
			Workspace:SetAttribute(ClimbEnd.StartAttribute, startAt)
		end
		if STUDIO then
			print(`ClimbEnds: {player.Name} is in for another climb`)
		end
		againSignal:fire(player)
	end

	local system =
		{ name = "ClimbEnds", ended = endedSignal, again = againSignal, covered = coveredSignal }

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		local c = (registry:get("climbs") :: any) :: Climbs.Climbs
		climbs = c
		watching = (registry:get("watching") :: any) :: Watching.Watching -- any: as above
		slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
		-- any: as above; LobbyCars starts after this, but every slot is filled before any starts
		lobbyCars = (registry:get("lobbyCars") :: any) :: LobbyCars.LobbyCars
		cutFrees = (registry:get("cutFrees") :: any) :: CutFrees.CutFrees -- any: as above
		topping = c.topped:connect(function(t: Climbs.Topped)
			endClimb("Top", t.from.number, t.at)
		end)
		local folder = ReplicatedStorage:FindFirstChild(Keypad.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Keypad.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local r = Instance.new("RemoteEvent")
		r.Name = ClimbEnd.Remote
		r.Parent = folder
		remote = r
		table.insert(connections, r.OnServerEvent:Connect(press))
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				lost[player] = nil
				asked[player] = nil
			end)
		)
	end

	function system.step(_: any, dt: number)
		since += dt
		if since < ClimbEnd.CheckEvery then
			return
		end
		since = 0
		local c = climbs
		if not c then
			return
		end
		if phase == "Idle" then
			if c:current() then
				phase = "Climbing"
				table.clear(lost)
			end
			return
		elseif phase == "Results" then
			local pressed, total = 0, 0
			for _, player in Players:GetPlayers() do
				total += 1
				if player:GetAttribute(ClimbEnd.InAttribute) == true then
					pressed += 1
				end
			end
			if ClimbEnd.ready(pressed, total, now(), startAt) then
				go()
			end
			return
		elseif phase ~= "Climbing" then
			return
		end
		local on = c:current()
		if not on then
			phase = "Idle"
			overSince = nil
			Workspace:SetAttribute(ClimbEnd.WaitAttribute, nil)
			return
		end
		if ClimbEnd.over(look(on.number), standIns()) then
			-- the last friend was kept just now: the end lands as their catch cuts to black, or
			-- once the wipe's offer has waited on every caught screen (S3-03c)
			local t = now()
			local first = overSince or t
			overSince = first
			local cf = cutFrees
			local offered = cf ~= nil and cf:offers()
			local waits = Workspace:GetAttribute(ClimbEnd.WaitAttribute)
			if offered and waits == nil then
				Workspace:SetAttribute(ClimbEnd.WaitAttribute, first)
				if STUDIO then
					print(`ClimbEnds: everyone's caught on floor {on.number}; the offer waits`)
				end
			end
			if ClimbEnd.ends(t - first, offered, if cf then cf:asking() else nil) then
				Workspace:SetAttribute(ClimbEnd.WaitAttribute, nil)
				endClimb("Kept", on.number, t)
			end
		else
			if overSince and Workspace:GetAttribute(ClimbEnd.WaitAttribute) ~= nil then
				Workspace:SetAttribute(ClimbEnd.WaitAttribute, nil)
				if STUDIO then
					print("ClimbEnds: freed before the results; the climb carries on")
				end
			end
			overSince = nil
		end
	end

	function system.stop(_: any)
		ends += 1
		for _, conn in connections do
			conn:Disconnect()
		end
		table.clear(connections)
		if topping then
			topping:disconnect()
			topping = nil
		end
		if remote then
			remote:Destroy()
			remote = nil
		end
		Workspace:SetAttribute(ClimbEnd.Attribute, nil)
		Workspace:SetAttribute(ClimbEnd.WaitAttribute, nil)
		Workspace:SetAttribute(ClimbEnd.StartAttribute, nil)
		table.clear(lost)
		table.clear(asked)
	end

	return system
end

return ClimbEnds
