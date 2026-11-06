--!strict
-- Renders every storage unit's roll-up door the server moves (see RollUpDoor).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

StorageUnit.RollUpDoor.watchTagged(StorageUnit.UnitKit.Tag)
