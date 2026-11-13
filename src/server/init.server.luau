--!strict
--[[
	The server's entry point: one Brix Host running the systems that decide, stepped every Heartbeat
	and stopped when the server closes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Carts = require(script.Carts)
local ClimbEnds = require(script.ClimbEnds)
local Climbs = require(script.Climbs)
local Crawls = require(script.Crawls)
local Deals = require(script.Deals)
local DevCorridor = require(script.DevCorridor)
local Doors = require(script.Doors)
local Elevators = require(script.Elevators)
local Flashlights = require(script.Flashlights)
local FrontOffice = require(script.FrontOffice)
local Horns = require(script.Horns)
local Keepers = require(script.Keepers)
local LobbyCars = require(script.LobbyCars)
local KeptPlayers = require(script.KeptPlayers)
local Kneels = require(script.Kneels)
local Minimaps = require(script.Minimaps)
local Prompts = require(script.Prompts)
local Ladders = require(script.Ladders)
local MotionLights = require(script.MotionLights)
local Saws = require(script.Saws)
local Slots = require(script.Slots)
local Trips = require(script.Trips)
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
	-- Everkeep's front office, the lobby: where everyone loads in, facing its six cars.
	{ slot = "frontOffice", system = FrontOffice.new() },
	-- The lobby's platform carts: Ride, handed to the rider's screen, its pace watched, parked again.
	{ slot = "carts", system = Carts.new() },
	-- A lobby car's group to a server of its own; on that server, the group stood in floor 1's car.
	{ slot = "trips", system = Trips.new() },
	-- The lobby's cars: step in to join a group, the count, the gate's slam, the ride to floor 1.
	{ slot = "lobbyCars", system = LobbyCars.new() },
}
-- The test hall and its "Walk a floor" post: Studio only now the lobby is the way in (D-109).
if RunService:IsStudio() then
	table.insert(systems, { slot = "devCorridor", system = DevCorridor.new() })
end

-- a refused press's remote, there before any screen looks for it (L-19a)
Prompts.ready()

local host = Brix.Host.new({ systems = systems })
host:start()

local beats = RunService.Heartbeat:Connect(function(dt: number)
	host:advance(dt)
end)

game:BindToClose(function()
	beats:Disconnect()
	host:stop()
end)
