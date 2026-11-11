--!strict
--[[
	The server's entry point: one Brix Host running the systems that decide, stepped every Heartbeat
	and stopped when the server closes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local ClimbEnds = require(script.ClimbEnds)
local Climbs = require(script.Climbs)
local Crawls = require(script.Crawls)
local Deals = require(script.Deals)
local DevCorridor = require(script.DevCorridor)
local Doors = require(script.Doors)
local Elevators = require(script.Elevators)
local Flashlights = require(script.Flashlights)
local Horns = require(script.Horns)
local Keepers = require(script.Keepers)
local KeptPlayers = require(script.KeptPlayers)
local Kneels = require(script.Kneels)
local Minimaps = require(script.Minimaps)
local Ladders = require(script.Ladders)
local MotionLights = require(script.MotionLights)
local Saws = require(script.Saws)
local Slots = require(script.Slots)
local Watching = require(script.Watching)
local Wraps = require(script.Wraps)

local systems: { Brix.HostEntry } = {
	-- The building's motion lights: which fixtures are lit, for every player.
	{ slot = "motionLights", system = MotionLights.new() },
	-- Every unit's roll-up door: its buttons, the checks on a press, its events.
	{ slot = "doors", system = Doors.new() },
	{ slot = "kneels", system = Kneels.new() },
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
	-- Getting kept: a caught player's things dropped, them stored in a unit, let out as its door lifts.
	{ slot = "keptPlayers", system = KeptPlayers.new() },
	-- Blowing the air horn: its gap between blows, the blast on every screen, keepers coming to it.
	{ slot = "horns", system = Horns.new() },
	-- Laying bubble wrap: a Lay checked against the halls, the roll spent, a sheet across the hall.
	{ slot = "wraps", system = Wraps.new() },
	{ slot = "minimaps", system = Minimaps.new() },
	-- The climb: each floor dealt and laid while the team rides up to it, the one below cleared.
	{ slot = "watching", system = Watching.new() },
	{ slot = "climbs", system = Climbs.new() },
	-- The climb's end: everyone kept or left, or the top; the results under it, and "Again".
	{ slot = "climbEnds", system = ClimbEnds.new() },
	-- The test hall and its "Walk a floor" post: the only way into a climb until the lobby
	-- (L-08e) exists, so it runs on live servers too, for testing on phones (D-109). It must
	-- give way to the lobby before the game goes public.
	{ slot = "devCorridor", system = DevCorridor.new() },
}

local host = Brix.Host.new({ systems = systems })
host:start()

local beats = RunService.Heartbeat:Connect(function(dt: number)
	host:advance(dt)
end)

game:BindToClose(function()
	beats:Disconnect()
	host:stop()
end)
