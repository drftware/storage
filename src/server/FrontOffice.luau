--!strict
--[[
	FrontOffice: lays Everkeep's front office (the lobby, L-08e1a) at `Lobby.Origin` on every
	server, from the template in the place (ReplicatedStorage.Props.Lobby) and the art's Specs, and
	makes it where everyone loads in (L-08e1b1): a spawn just inside the front door, facing the six
	cars (LobbyCars runs them). The place's own baseplate and spawn pad go: this runs only on a
	running server (Play, or live), on its copy of the place.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Lobby = require(ReplicatedStorage.Shared.Lobby)

export type FrontOffice = Brix.System & {
	-- The lobby as laid, or nil if the place has no template.
	laid: (self: FrontOffice) -> Lobby.Laid?,
}

local FrontOffice = {}

function FrontOffice.new(): FrontOffice
	local laid: Lobby.Laid? = nil
	return {
		name = "FrontOffice",
		start = function(_: any)
			local l = Lobby.lay(Lobby.Origin, Workspace)
			laid = l
			if not l then
				return
			end
			for _, d in Workspace:GetDescendants() do
				if d:IsA("SpawnLocation") then
					d:Destroy()
				end
			end
			local baseplate = Workspace:FindFirstChild("Baseplate")
			if baseplate then
				baseplate:Destroy()
			end
			-- you load in just inside the door, turned to the cars: a spawn's own facing is the
			-- one a new character takes (and LobbyView turns the camera to it)
			local at = Lobby.spawn(l.pivot)
			local spawn = Instance.new("SpawnLocation")
			spawn.Name = "LobbySpawn"
			spawn.Anchored = true
			spawn.CanCollide = false
			spawn.CanQuery = false
			spawn.CanTouch = false
			spawn.Transparency = 1
			spawn.Neutral = true
			spawn.Duration = 0
			spawn.Size = Vector3.new(4, 0.2, 4)
			spawn.CFrame = at - Vector3.new(0, at.Position.Y - l.pivot.Position.Y - 0.1, 0)
			spawn.Parent = l.folder
			-- anyone already in (Studio's Play can load a character first) is put there too
			for _, player in Players:GetPlayers() do
				if player.Character then
					player.Character:PivotTo(at)
				end
			end
			print(`FrontOffice: the lobby is laid, {#l.cars} cars in their bays`)
		end,
		stop = function(_: any)
			if laid then
				laid.folder:Destroy()
				laid = nil
			end
		end,
		laid = function(_: FrontOffice): Lobby.Laid?
			return laid
		end,
	}
end

return FrontOffice
