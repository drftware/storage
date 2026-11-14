--!strict
--[[
	Horns: blowing the air horn on the server (L-14a2, D-087), a system. A Blow comes in as
	`Slots.used` (a living player with the horn in hand, the press's rate already checked); here it
	must wait out the horn's gap since that player's last blow (`Horn.allow`, a little lenient for
	the network). Then the blast: the horn's model is stamped with the server's clock
	(`Horn.BlownAttribute`), which every screen plays at its bell and raises the arm that blew it
	(`HornView`); and every keeper on the floor hears it at the bell's mouth (`Keepers:hearHorn`),
	coming to look where it was blown.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Horn = require(ReplicatedStorage.Shared.Tools.Horn)
local Keepers = require(script.Parent.Keepers)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.Tools.Specs.AirHorn)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Horns = {}

function Horns.new(): Brix.System
	local connections: { Brix.SignalConnection } = {}
	local leaving: RBXScriptConnection? = nil
	local last: { [Player]: number } = {} -- each player's last blow, os.clock
	local keepers: Keepers.Keepers? = nil
	local slots: Slots.Slots? = nil

	local function onUsed(use: Slots.Use)
		if use.key ~= Horn.Key then
			return
		end
		local player = use.player
		local t = os.clock()
		if not Horn.allow(last[player], t, Horn.Slack) then
			return
		end
		last[player] = t
		-- a blast spent (S1-08), before the stamp: every screen hearing it knows if it was the last
		if slots then
			slots:wear(player, Horn.Key)
		end
		-- the bell's mouth in the world, from the grip (the body's pivot)
		local body = Tools.body(use.model)
		local mouth = if body
			then (body.CFrame * body.PivotOffset):PointToWorldSpace(Specs.Mouth)
			else use.model:GetPivot().Position
		use.model:SetAttribute(Horn.BlownAttribute, Workspace:GetServerTimeNow())
		local heard = if keepers then keepers:hearHorn(mouth) else 0
		if heard == 0 and RunService:IsStudio() then
			print(`Horns: {player.Name} blew the air horn; no keeper heard it`)
		end
	end

	local system = { name = "Horns" }

	function system.start(_: any, context: Brix.Context)
		local s = (context.registry:get("slots") :: any) :: Slots.Slots? -- any: the registry's
		slots = s
		keepers = (context.registry:get("keepers") :: any) :: Keepers.Keepers?
		if s then
			table.insert(connections, s.used:connect(onUsed))
		else
			warn("Horns: no Slots system, so nobody can blow a horn")
		end
		leaving = Players.PlayerRemoving:Connect(function(player: Player)
			last[player] = nil
		end)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		if leaving then
			leaving:Disconnect()
			leaving = nil
		end
		table.clear(last)
	end

	return system :: any -- any: a plain Brix system built field by field
end

return Horns
