--!strict
--[[
	The client's entry point: one Brix Host running this player's presentation systems. A client
	Host is stepped just before each frame renders (Brix DESIGN, "Server, client and the wire").
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local BehindDoors = require(script.BehindDoors)
local CameraShake = require(script.CameraShake)
local DoorSounds = require(script.DoorSounds)
local DoorView = require(script.DoorView)
local FreeCursor = require(script.FreeCursor)
local HallHaze = require(script.HallHaze)
local HallLights = require(script.HallLights)
local UnitLights = require(script.UnitLights)

local cameraShake, kick = CameraShake.new()

local host = Brix.Host.new({
	systems = {
		{ slot = "doorView", system = DoorView.new() },
		{ slot = "doorSounds", system = DoorSounds.new(kick) },
		-- before BehindDoors, so its dimming of the hall lands on a flickering tube each frame
		{ slot = "hallLights", system = HallLights.new() },
		-- before BehindDoors too, so a unit's stuttering bulb is dimmed for whoever is shut in next door
		{ slot = "unitLights", system = UnitLights.new() },
		{ slot = "behindDoors", system = BehindDoors.new() },
		{ slot = "freeCursor", system = FreeCursor.new() },
		{ slot = "hallHaze", system = HallHaze.new() },
		{ slot = "cameraShake", system = cameraShake },
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
