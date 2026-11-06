--!strict
--[[
	The client's entry point: one Brix Host running this player's presentation systems. A client
	Host is stepped just before each frame renders (Brix DESIGN, "Server, client and the wire").
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local BehindDoors = require(script.BehindDoors)
local DoorView = require(script.DoorView)

local host = Brix.Host.new({
	systems = {
		{ slot = "doorView", system = DoorView.new() },
		{ slot = "behindDoors", system = BehindDoors.new() },
	},
})
host:start()

local frames = RunService.RenderStepped:Connect(function(dt: number)
	host:advance(dt)
end)

-- The script lives as long as the player's session; this covers anything that destroys it early.
script.Destroying:Connect(function()
	frames:Disconnect()
	host:stop()
end)
