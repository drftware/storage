--!strict
--[[
	KeptSqueal: the film's squeal as a keeper wraps someone (L-07b), on every screen. The moment:
	its hands close on you and in the black you hear the film screech round you; a friend down
	the hall hears it too and knows someone's been taken.

	Each player's `Kept` attribute turns on at the catch (Keepers sets it; only the server can).
	On the caught player's own screen the squeal plays close, as their own sound in the black; on
	everyone else's it plays from where that player stood when they were caught, heard to
	`Kept.SquealReach` studs. Nothing extra goes over the network for it. The recording and its
	stretch are `Kept.Squeal`'s.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Kept = require(ReplicatedStorage.Shared.Kept)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tools = require(ReplicatedStorage.Shared.Tools)

local KeptSqueal = {}

function KeptSqueal.new(): Brix.System
	local was: { [Player]: boolean } = {} -- each player's kept flag as last seen
	local watching: { [Player]: RBXScriptConnection } = {}
	local connections: { RBXScriptConnection } = {}

	local function squeal(player: Player)
		if player == Players.LocalPlayer then
			Tools.play(Kept.Squeal, SoundService, Kept.SquealReach)
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return -- streamed out: too far off to hear
		end
		-- where they stood, not their body: the server moves it into a unit in the black
		local at = Instance.new("Attachment")
		at.Name = "KeptSqueal"
		at.WorldPosition = root.Position
		at.Parent = Workspace.Terrain
		Tools.play(Kept.Squeal, at, Kept.SquealReach)
		task.delay(Kept.Squeal.length / (Kept.Squeal.pitch or 1) + 1, function()
			at:Destroy()
		end)
	end

	local function watch(player: Player)
		was[player] = player:GetAttribute(Kept.Attribute) == true
		watching[player] = player:GetAttributeChangedSignal(Kept.Attribute):Connect(function()
			local now = player:GetAttribute(Kept.Attribute) == true
			if now and not was[player] then
				squeal(player)
			end
			was[player] = now
		end)
	end

	return {
		name = "KeptSqueal",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, { Kept.Squeal.id })
			for _, player in Players:GetPlayers() do
				watch(player)
			end
			table.insert(connections, Players.PlayerAdded:Connect(watch))
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					local c = watching[player]
					if c then
						c:Disconnect()
					end
					watching[player], was[player] = nil, nil
				end)
			)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, c in watching do
				c:Disconnect()
			end
			table.clear(watching)
			table.clear(was)
		end,
	}
end

return KeptSqueal
