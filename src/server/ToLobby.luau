--!strict
--[[
	ToLobby: caught on the back-to-the-lobby card's floor (S4-03c4, D-409, shared `ToLobby`), a
	system on the server. KeptPlayers leaves such a catch alone (no unit, no film); this takes it.

	At the catch (Keepers' `caught`, the caught screen already told): whatever they carried drops
	where they stood (`Slots:dropAll`, as any catch), they're held still (their root anchored), and
	`ToLobby.Attribute` goes on them with the catch's server time, so their screen plays the fall
	(ToLobbyView) and the end counts them caught on this floor for good (`ClimbEnd.look`). Keepers
	has marked them kept already, so no keeper sees them and no prompt answers them.

	At `ToLobby.Swap`, under the landing's black: a new character stood in the lobby car the climb
	started from, facing out of its gate (LobbyCars' `teamCar`: on a group's own server the car its
	trip names, on a lobby riding here the car that took the group up, else the first car: the
	test hall's climb in Studio), the world streamed round them, `ToLobby.StoodAttribute` set so
	their screen lifts, and the kept mark off. Trips never stands them back in the climb
	(`mayStand`). Each one sent down takes the next of the car's standing spots.

	Waiting there (S4-03c4c, D-411): LobbyCars never takes them into a car's group, so the car
	never counts down and its gate stays up; its dial shows the floor the team is on. Again, at
	the climb's end, stands the whole team back in that car.

	Not swapped: once the climb's end is on (the last friend caught: the end takes everyone, Again
	brings the team back to the car), or they left. The end clears both attributes as it covers.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Climb = require(ReplicatedStorage.Shared.Climb)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local Kept = require(ReplicatedStorage.Shared.Kept)
local NextFloor = require(ReplicatedStorage.Shared.NextFloor)
local ToLobbyRules = require(ReplicatedStorage.Shared.ToLobby)
local FrontOffice = require(script.Parent.FrontOffice)
local Keepers = require(script.Parent.Keepers)
local LobbyCars = require(script.Parent.LobbyCars)
local Slots = require(script.Parent.Slots)

local ToLobby = {}

local STUDIO = RunService:IsStudio()

function ToLobby.new(): Brix.System
	local connections: { Brix.SignalConnection } = {}
	local joins: { RBXScriptConnection } = {}
	local context: Brix.Context? = nil
	local slots: Slots.Slots? = nil
	local sent: { [Player]: number } = {} -- each one sent down, by their catch's server time

	-- any: the registry hands back plain Systems; FrontOffice and LobbyCars start after this one,
	-- so they're looked up as they're needed
	local function get(slot: string): any
		local c = context
		return if c then c.registry:get(slot) else nil
	end

	-- Where the `n`th one sent down this climb stands: in the lobby car the climb started from
	-- (LobbyCars' `teamCar`, whose dial shows the team's floor), facing out of its gate (+Z is
	-- into the car, in its own frame). Nil with no lobby laid.
	local function spot(n: number): CFrame?
		local office = get("frontOffice") :: FrontOffice.FrontOffice?
		local laid = office and office:laid()
		if not (laid and #laid.cars > 0) then
			return nil
		end
		local cars = get("lobbyCars") :: LobbyCars.LobbyCars?
		local into = (cars and cars:teamCar()) or laid.cars[1]
		local x, z = Boarding.backSpot(n)
		local at = Vector3.new(x, 3, z)
		return into:GetPivot() * CFrame.lookAt(at, at - Vector3.zAxis)
	end

	local function swap(player: Player, at: number)
		if sent[player] ~= at or not player.Parent then
			return
		end
		-- the last friend caught: the end takes everyone, and Again brings the team to the car
		if
			Workspace:GetAttribute(ClimbEnd.Attribute) ~= nil
			or Workspace:GetAttribute(ClimbEnd.WaitAttribute) ~= nil
		then
			return
		end
		local n = 0
		for other in sent do
			if other:GetAttribute(ToLobbyRules.StoodAttribute) ~= nil then
				n += 1
			end
		end
		local where = spot(n + 1)
		local ok, err = pcall(function()
			player:LoadCharacter()
		end)
		local character = player.Character
		if not (ok and character and player.Parent) then
			warn(`ToLobby: couldn't give {player.Name} a character in the lobby: {err}`)
			return
		end
		if where then
			character:PivotTo(where)
		end
		player:SetAttribute(Kept.Attribute, nil)
		local stood = where or character:GetPivot()
		local streamed, why = pcall(function()
			player:RequestStreamAroundAsync(stood.Position, Climb.StreamWait)
		end)
		if not streamed and player.Parent then
			warn(`ToLobby: couldn't stream the lobby car to {player.Name}: {why}`)
		end
		if player.Parent and sent[player] == at then
			player:SetAttribute(ToLobbyRules.StoodAttribute, stood)
		end
		if STUDIO then
			print(`ToLobby: {player.Name} is back in the lobby car`)
		end
	end

	local function onCaught(catch: Keepers.Catch)
		local player = catch.player
		if not ToLobbyRules.sends(catch.floor:GetAttribute(NextFloor.Attribute)) then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (player.Parent and root and root:IsA("BasePart")) then
			return
		end
		-- what you carried drops where you stood, before you're held
		local s = slots
		if s then
			s:dropAll(player)
		end
		root.Anchored = true
		local at = Workspace:GetServerTimeNow()
		sent[player] = at
		player:SetAttribute(ToLobbyRules.Attribute, at)
		player:SetAttribute(ToLobbyRules.StoodAttribute, nil)
		if STUDIO then
			print(`ToLobby: {player.Name} caught on a back-to-the-lobby floor; down the shaft`)
		end
		task.delay(ToLobbyRules.Swap, swap, player, at)
	end

	return {
		name = "ToLobby",
		start = function(_: any, ctx: Brix.Context)
			context = ctx
			slots = (ctx.registry:get("slots") :: any) :: Slots.Slots? -- any: as `get`
			local keepers = (ctx.registry:get("keepers") :: any) :: Keepers.Keepers? -- any: as `get`
			if keepers then
				table.insert(connections, keepers.caught:connect(onCaught))
			end
			table.insert(
				joins,
				Players.PlayerRemoving:Connect(function(player: Player)
					sent[player] = nil
				end)
			)
		end,
		-- the climb's end clears the mark as it covers: forget them then
		step = function(_: any, _dt: number)
			for player in sent do
				if player:GetAttribute(ToLobbyRules.Attribute) == nil then
					sent[player] = nil
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:disconnect()
			end
			table.clear(connections)
			for _, c in joins do
				c:Disconnect()
			end
			table.clear(joins)
			table.clear(sent)
		end,
	} :: Brix.System
end

return ToLobby
