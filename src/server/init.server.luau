--!strict
--[[
	The server's entry point: one Brix Host running the systems that decide, stepped every Heartbeat
	and stopped when the server closes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local DevCorridor = require(script.DevCorridor)

local systems: { Brix.HostEntry } = {}
if RunService:IsStudio() then
	-- A test hall of real units to try the doors in. Never on a live server.
	table.insert(systems, { slot = "devCorridor", system = DevCorridor.new() })
end

local host = Brix.Host.new({ systems = systems })
host:start()

local beats = RunService.Heartbeat:Connect(function(dt: number)
	host:advance(dt)
end)

game:BindToClose(function()
	beats:Disconnect()
	host:stop()
end)
