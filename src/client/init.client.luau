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
local CaughtView = require(script.CaughtView)
local CrawlView = require(script.CrawlView)
local DoorSounds = require(script.DoorSounds)
local DoorView = require(script.DoorView)
local ElevatorView = require(script.ElevatorView)
local FlashlightView = require(script.FlashlightView)
local FreeCursor = require(script.FreeCursor)
local GateClock = require(script.GateClock)
local HallHaze = require(script.HallHaze)
local HallLights = require(script.HallLights)
local KeeperView = require(script.KeeperView)
local KeypadPad = require(script.KeypadPad)
local LadderView = require(script.LadderView)
local NoteView = require(script.NoteView)
local SawView = require(script.SawView)
local ToolView = require(script.ToolView)
local UnitLights = require(script.UnitLights)

local cameraShake, kick = CameraShake.new()
local freeCursor, needCursor = FreeCursor.new()
local elevatorView, pressKeypad = ElevatorView.new(kick)

local host = Brix.Host.new({
	systems = {
		{ slot = "doorView", system = DoorView.new() },
		{ slot = "keeperView", system = KeeperView.new() },
		{ slot = "doorSounds", system = DoorSounds.new(kick) },
		-- before BehindDoors, so its dimming of the hall lands on a flickering tube each frame
		{ slot = "hallLights", system = HallLights.new() },
		-- before BehindDoors too, so a unit's stuttering bulb is dimmed for whoever is shut in next door
		{ slot = "unitLights", system = UnitLights.new() },
		{ slot = "behindDoors", system = BehindDoors.new() },
		{ slot = "elevatorView", system = elevatorView },
		{ slot = "keypadPad", system = KeypadPad.new(pressKeypad, needCursor) },
		{ slot = "gateClock", system = GateClock.new(kick) },
		{ slot = "caughtView", system = CaughtView.new(kick) },
		{ slot = "noteView", system = NoteView.new() },
		{ slot = "flashlightView", system = FlashlightView.new() },
		{ slot = "toolView", system = ToolView.new() },
		{ slot = "sawView", system = SawView.new(kick) },
		{ slot = "crawlView", system = CrawlView.new(kick) },
		{ slot = "ladderView", system = LadderView.new(kick) },
		{ slot = "freeCursor", system = freeCursor },
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
