--!strict
--[[
	Watching: left behind on the server (L-08c, Left, the GDD's "Left behind"), a system. When the
	car leaves a floor with friends aboard, everyone else still on that floor, out in the halls or
	kept in a unit, is out of the climb, as DOORS' dead are out of the run.

	- `strand`, as the car leaves: they're marked (`Left.Attribute`, when it left them), and their
	  screens play the moment (WatchView). A ride that doesn't go on after all (the next floor
	  wasn't ready, the car comes back) un-marks them (`unstrand`).
	- `watch`, as their floor is cleared under them (the hand-off, 13.4 s in): whatever they carried
	  drops where they stood (it goes with the floor), and their character goes, so nothing can hurt
	  them, nothing can see them and no prompt answers them. They get `Left.WatchValue`: the friend
	  they watch, by character and name. The server streams the world around that friend to them
	  (`ReplicationFocus`, and a request to stream it in at once), so the camera has something to
	  follow wherever the friend goes.
	- Their screen asks for the next friend or the one before (`Remotes.Watch`, checked as every
	  remote is: its type, that they're watching, its rate). A friend who goes (left, kept on
	  and cleared, gone from the game) or comes back as a new character is followed to the next.
	- Back in: Cut Free (the GDD's revive, DOORS' model) puts them on their friends' floor, in its
	  lobby, as soon as there's a floor to stand on (not between two floors mid-ride): a new
	  character, `Left.BackAttribute` for their screen's moment. The developer product isn't made
	  yet, so only Studio takes the ask (`OWNER.md`).
	- The climb's end takes everyone watching with it (`release`, L-08d): the results screen is
	  where they're back (ClimbEnds), and "Again" gives them a character in the next climb.

	In Studio, a model tagged `Left.StandInTag` (a stand-in friend) can be watched, so one player
	can be left behind (Climbs carries it up with the car).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Left = require(ReplicatedStorage.Shared.Left)
local Slots = require(script.Parent.Slots)

export type Watching = Brix.System & {
	-- The car left `players` behind at server time `at`: their screens start the moment.
	strand: (self: any, players: { Player }, at: number) -> (),
	-- The car came back after all: they're still in the climb.
	unstrand: (self: any, players: { Player }) -> (),
	-- Their floor is going: they drop what they carry, lose their character and watch a friend.
	watch: (self: any, players: { Player }, at: number) -> (),
	-- Whether `player` is out of the climb (left, or watching).
	isOut: (self: any, player: Player) -> boolean,
	-- The climb is over: everyone out of it stops watching, with no character given back (the
	-- results screen is where they are; ClimbEnds gives everyone one in the next climb).
	release: (self: any) -> (),
	-- Where someone let back in stands, on the floor the climb is on now; nil while there's no
	-- floor to stand on (no climb, or a ride between two floors). Climbs sets it.
	setArrival: (self: any, arrival: () -> CFrame?) -> (),
}

-- A friend who can be watched: a player in the climb, or a stand-in in Studio.
type Friend = {
	key: string, -- sorts players by UserId, stand-ins after them
	model: Model,
	root: BasePart,
	name: string,
}

type Entry = {
	at: number,
	value: ObjectValue?, -- once watching
	key: string?, -- the friend watched
	asked: number, -- os.clock() of the last ask taken
	rejoining: boolean,
}

local STUDIO = RunService:IsStudio()
-- Seconds between the server's looks at who each watcher follows (a friend gone, respawned or
-- moved on): quick enough that the screen never holds a dead view for long.
local CHECK_EVERY = 0.25
-- Seconds a let-in waits for a floor to stand on (a ride is between floors for at most about 10).
local FLOOR_WAIT = 20
-- Seconds the server waits for the friend's surroundings to stream in to a watcher.
local STREAM_WAIT = 5

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- A living character's model and root, or nil.
local function living(model: Model?): BasePart?
	if not (model and model.Parent) then
		return nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local Watching = {}

function Watching.new(): Watching
	local left: { [Player]: Entry } = {}
	local connections: { RBXScriptConnection } = {}
	local slots: Slots.Slots? = nil
	local arrival: (() -> CFrame?)? = nil
	local remote: RemoteEvent? = nil
	local since = 0 -- seconds since the last look

	-- Everyone who can be watched now, by key.
	local function friends(): { [string]: Friend }
		local out: { [string]: Friend } = {}
		for _, player in Players:GetPlayers() do
			if left[player] then
				continue
			end
			local model = player.Character
			local root = living(model)
			if model and root then
				local key = string.format("p%015d", player.UserId)
				out[key] = { key = key, model = model, root = root, name = player.DisplayName }
			end
		end
		if STUDIO then
			for _, inst in CollectionService:GetTagged(Left.StandInTag) do
				if inst:IsA("Model") and inst:IsDescendantOf(Workspace) then
					local root = living(inst)
					if root then
						local key = "s" .. inst.Name
						out[key] = { key = key, model = inst, root = root, name = inst.Name }
					end
				end
			end
		end
		return out
	end

	local function keysOf(list: { [string]: Friend }): { string }
		local keys = {}
		for key in list do
			table.insert(keys, key)
		end
		return keys
	end

	-- `player` follows `friend` (or nobody): their screen's value, and the world streamed round them.
	local function point(player: Player, entry: Entry, friend: Friend?)
		local value = entry.value
		if not value then
			return
		end
		entry.key = if friend then friend.key else nil
		-- the name first, so it shows while the friend streams in
		value:SetAttribute(Left.NameAttribute, if friend then friend.name else nil)
		value.Value = if friend then friend.model else nil
		player.ReplicationFocus = if friend then friend.root else nil
		if friend then
			local at = friend.root.Position
			task.spawn(function()
				pcall(function()
					player:RequestStreamAroundAsync(at, STREAM_WAIT)
				end)
			end)
		end
	end

	-- Lets `player` back into the climb on its floor (yields until there's a floor to stand on).
	local function letIn(player: Player, why: string)
		local entry = left[player]
		if not entry or entry.rejoining then
			return
		end
		entry.rejoining = true
		task.spawn(function()
			local spot: CFrame? = nil
			local waited = 0
			while player.Parent and left[player] == entry do
				spot = if arrival then arrival() else nil
				if spot or waited >= FLOOR_WAIT then
					break
				end
				waited += task.wait(0.25)
			end
			if not (player.Parent and left[player] == entry) then
				return
			end
			left[player] = nil
			if entry.value then
				entry.value:Destroy()
			end
			player.ReplicationFocus = nil
			player:SetAttribute(Left.Attribute, nil)
			player:LoadCharacter()
			local character = player.Character
			if spot and character then
				character:PivotTo(spot)
			end
			player:SetAttribute(Left.BackAttribute, Left.encodeBack(now(), why))
			if STUDIO then
				print(`Watching: {player.Name} is back in the climb ({why})`)
			end
		end)
	end

	-- A watcher's ask: checked (its type, that they're watching, its rate), then done.
	local function ask(player: Player, what: unknown)
		if what ~= "Next" and what ~= "Back" and what ~= "CutFree" then
			return
		end
		local entry = left[player]
		if not (entry and entry.value and not entry.rejoining) then
			return
		end
		local t = os.clock()
		if t - entry.asked < Left.AskEvery then
			return
		end
		entry.asked = t
		if what == "CutFree" then
			-- the developer product isn't made yet: Studio only, until it is (OWNER.md)
			if STUDIO then
				letIn(player, "CutFree")
			end
			return
		end
		local list = friends()
		local key = Left.cycle(keysOf(list), entry.key, if what == "Next" then 1 else -1)
		point(player, entry, if key then list[key] else nil)
	end

	-- Each watcher still follows a living friend, on their current character: or the next one.
	-- With nobody left to watch, the climb is over (ClimbEnds ends it).
	local function check()
		local list: { [string]: Friend }? = nil
		for player, entry in left do
			local value = entry.value
			if not value or entry.rejoining then
				continue
			end
			local all = list or friends()
			list = all
			local friend = if entry.key then all[entry.key] else nil
			if not friend then
				local key = Left.cycle(keysOf(all), entry.key, 1)
				friend = if key then all[key] else nil
			end
			if
				friend ~= nil
				and (value.Value ~= friend.model or player.ReplicationFocus ~= friend.root)
			then
				point(player, entry, friend)
			elseif friend == nil and entry.key ~= nil then
				point(player, entry, nil)
			end
		end
	end

	local system = { name = "Watching" }

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Slots fills this slot (init.server)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots
		local folder = ReplicatedStorage:FindFirstChild(Keypad.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Keypad.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local r = Instance.new("RemoteEvent")
		r.Name = Left.Remote
		r.Parent = folder
		remote = r
		table.insert(connections, r.OnServerEvent:Connect(ask))
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				left[player] = nil
			end)
		)
	end

	function system.step(_: any, dt: number)
		if next(left) == nil then
			return
		end
		since += dt
		if since < CHECK_EVERY then
			return
		end
		check()
		since = 0
		-- a character that turns up while watching (not by a let-in): they're back at the spawn,
		-- out of the watch
		for player, entry in left do
			if entry.value and not entry.rejoining and player.Character then
				left[player] = nil
				entry.value:Destroy()
				player.ReplicationFocus = nil
				player:SetAttribute(Left.Attribute, nil)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		if remote then
			remote:Destroy()
			remote = nil
		end
		for player, entry in left do
			if entry.value then
				entry.value:Destroy()
			end
			if player.Parent then
				player.ReplicationFocus = nil
			end
		end
		table.clear(left)
	end

	function system.strand(_: any, players: { Player }, at: number)
		for _, player in players do
			if player.Parent and not left[player] then
				left[player] = { at = at, value = nil, key = nil, asked = 0, rejoining = false }
				player:SetAttribute(Left.Attribute, at)
			end
		end
	end

	function system.unstrand(_: any, players: { Player })
		for _, player in players do
			local entry = left[player]
			if entry and not entry.value then
				left[player] = nil
				if player.Parent then
					player:SetAttribute(Left.Attribute, nil)
				end
			end
		end
	end

	function system.watch(_: any, players: { Player }, at: number)
		for _, player in players do
			if not player.Parent then
				continue
			end
			local entry = left[player]
			if entry and entry.value then
				continue -- watching already
			end
			if not entry then
				entry = { at = at, value = nil, key = nil, asked = 0, rejoining = false }
				left[player] = entry
				player:SetAttribute(Left.Attribute, at)
			end
			local e = entry :: Entry
			-- whatever they carried drops where they stood, and goes with the floor
			if slots then
				slots:dropAll(player)
			end
			local character = player.Character
			player.Character = nil
			if character then
				character:Destroy()
			end
			local value = Instance.new("ObjectValue")
			value.Name = Left.WatchValue
			value.Parent = player
			e.value = value
			local list = friends()
			local key = Left.cycle(keysOf(list), nil, 1)
			point(player, e, if key then list[key] else nil)
			if STUDIO then
				print(
					`Watching: {player.Name} was left behind and watches {if key
						then list[key].name
						else "nobody yet"}`
				)
			end
		end
	end

	function system.isOut(_: any, player: Player): boolean
		return left[player] ~= nil
	end

	function system.release(_: any)
		for player, entry in left do
			if entry.value then
				entry.value:Destroy()
			end
			if player.Parent then
				player.ReplicationFocus = nil
				player:SetAttribute(Left.Attribute, nil)
			end
		end
		-- a let-in waiting for a floor sees it's no longer theirs and stops
		table.clear(left)
	end

	function system.setArrival(_: any, f: () -> CFrame?)
		arrival = f
	end

	return system
end

return Watching
