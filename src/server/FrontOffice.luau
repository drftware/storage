--!strict
--[[
	FrontOffice: lays Everkeep's front office (the lobby, L-08e1a) at `Lobby.Origin` on every
	server, from the template in the place (ReplicatedStorage.Props.Lobby) and the art's Specs.
	For now the test hall's "Go to the lobby" post is the way in (DevCorridor); L-08e1b1 makes it
	where everyone loads in, its cars the way into a climb.
]]
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
			laid = Lobby.lay(Lobby.Origin, Workspace)
			if laid then
				print(`FrontOffice: the lobby is laid, {#laid.cars} cars in their bays`)
			end
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
