--!strict
--[[
	DoorView: draws every storage unit's roll-up door on this client, wherever the server has moved
	it, as units stream in and out. The door's motion is RollUpDoor's; this system only starts and
	stops the watching with the Host.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local DoorView = {}

function DoorView.new(): Brix.System
	local stopWatching: (() -> ())? = nil
	return {
		name = "DoorView",
		start = function(_: any, _context: Brix.Context)
			stopWatching = StorageUnit.RollUpDoor.watchTagged(StorageUnit.UnitKit.Tag)
		end,
		stop = function(_: any)
			if stopWatching then
				stopWatching()
				stopWatching = nil
			end
		end,
	}
end

return DoorView
