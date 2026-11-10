--!strict
--[[
	The server's entry point: one Brix Host running the systems that decide, stepped every Heartbeat
	and stopped when the server closes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Crawls = require(script.Crawls)
local Deals = require(script.Deals)
local DevCorridor = require(script.DevCorridor)
local Doors = require(script.Doors)
local Elevators = require(script.Elevators)
local Flashlights = require(script.Flashlights)
local Keepers = require(script.Keepers)
local Ladders = require(script.Ladders)
local MotionLights = require(script.MotionLights)
local Saws = require(script.Saws)
local Slots = require(script.Slots)

local systems: { Brix.HostEntry } = {
	-- The building's motion lights: which fixtures are lit, for every player.
	{ slot = "motionLights", system = MotionLights.new() },
	-- Every unit's roll-up door: its buttons, the checks on a press, its events.
	{ slot = "doors", system = Doors.new() },
	-- Each floor's freight elevator: its keypad, the code check, the alarm, its gate.
	{ slot = "elevators", system = Elevators.new() },
	{ slot = "flashlights", system = Flashlights.new() },
	-- Everyone's two tool slots: tools on floors, picked up, switched, dropped, handed over.
	{ slot = "slots", system = Slots.new() },
	-- The deal on the floor: each unit's contents dealt and laid as its door first lifts or a saw holes it.
	{ slot = "deals", system = Deals.new() },
	{ slot = "saws", system = Saws.new() },
	-- Crawling through a sawn hole: its Crawl buttons, the checks on a press, the move's start.
	{ slot = "crawls", system = Crawls.new() },
	{ slot = "ladders", system = Ladders.new() },
	-- The keepers' brain: each floor's map kept in step with its doors, what each keeper hears, its walk.
	{ slot = "keepers", system = Keepers.new() },
}
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
