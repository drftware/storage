--!strict
--[[
	The client's entry point: one Brix Host running this player's presentation systems. A client
	Host is stepped just before each frame renders (Brix DESIGN, "Server, client and the wire").
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local BangMarks = require(script.BangMarks)
local BehindDoors = require(script.BehindDoors)
local ButtonView = require(script.ButtonView)
local CameraShake = require(script.CameraShake)
local CaughtView = require(script.CaughtView)
local KeptWrapOn = require(script.KeptWrapOn)
local ChaseMusic = require(script.ChaseMusic)
local CrawlView = require(script.CrawlView)
local CutFreeView = require(script.CutFreeView)
local DoorSounds = require(script.DoorSounds)
local DoorView = require(script.DoorView)
local ElevatorView = require(script.ElevatorView)
local EndView = require(script.EndView)
local FlashlightView = require(script.FlashlightView)
local HornView = require(script.HornView)
local FreeCursor = require(script.FreeCursor)
local GateClock = require(script.GateClock)
local HallHaze = require(script.HallHaze)
local HallLights = require(script.HallLights)
local KeeperSounds = require(script.KeeperSounds)
local KeeperView = require(script.KeeperView)
local KeypadPad = require(script.KeypadPad)
local KneelView = require(script.KneelView)
local MinimapView = require(script.MinimapView)
local LadderView = require(script.LadderView)
local NoteView = require(script.NoteView)
local PadlockView = require(script.PadlockView)
local SawView = require(script.SawView)
local ToolView = require(script.ToolView)
local RideView = require(script.RideView)
local UnderDoor = require(script.UnderDoor)
local UnitLights = require(script.UnitLights)
local WatchView = require(script.WatchView)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)
local WrapView = require(script.WrapView)

local cameraShake, kick, holdView = CameraShake.new()
local freeCursor, needCursor = FreeCursor.new()
local elevatorView, pressKeypad = ElevatorView.new(kick)
local keeperSounds, keeperHeard = KeeperSounds.new()
local flashlightView, myBeam = FlashlightView.new()
local toolView, myHand = ToolView.new()
local wrapView, lay = WrapView.new(myHand, kick)

local host = Brix.Host.new({
	systems = {
		{ slot = "doorView", system = DoorView.new() },
		-- before KeeperView, so a body is ready to be heard by the time KeeperView first poses it
		{ slot = "keeperSounds", system = keeperSounds },
		{ slot = "keeperView", system = KeeperView.new(keeperHeard, myBeam) },
		{ slot = "doorSounds", system = DoorSounds.new(kick) },
		-- before BehindDoors, so its dimming of the hall lands on a flickering tube each frame
		{ slot = "hallLights", system = HallLights.new() },
		-- before BehindDoors too, so a unit's stuttering bulb is dimmed for whoever is shut in next door
		{ slot = "unitLights", system = UnitLights.new() },
		{ slot = "behindDoors", system = BehindDoors.new() },
		{ slot = "elevatorView", system = elevatorView },
		{ slot = "keypadPad", system = KeypadPad.new(pressKeypad, needCursor) },
		-- every button in the world, drawn one way (L-19a)
		{ slot = "buttonView", system = ButtonView.new() },
		{ slot = "gateClock", system = GateClock.new() },
		{ slot = "rideView", system = RideView.new(holdView) },
		{ slot = "minimapView", system = MinimapView.new() },
		{ slot = "caughtView", system = CaughtView.new(kick) },
		{ slot = "chaseMusic", system = ChaseMusic.new() },
		{ slot = "keptWrapOn", system = KeptWrapOn.new() },
		{ slot = "cutFreeView", system = CutFreeView.new(kick) },
		{ slot = "bangMarks", system = BangMarks.new() },
		{ slot = "padlockView", system = PadlockView.new(kick) },
		{ slot = "underDoor", system = UnderDoor.new() },
		{ slot = "noteView", system = NoteView.new() },
		{ slot = "flashlightView", system = flashlightView },
		{ slot = "toolView", system = toolView },
		-- after ToolView, so its button lands beside a bar that's there
		{ slot = "hornView", system = HornView.new(myHand, kick, { [Wrap.Key] = lay }) },
		{ slot = "wrapView", system = wrapView },
		{ slot = "sawView", system = SawView.new(kick) },
		{ slot = "crawlView", system = CrawlView.new(kick) },
		{ slot = "ladderView", system = LadderView.new(kick) },
		{ slot = "kneelView", system = KneelView.new() },
		{ slot = "freeCursor", system = freeCursor },
		{ slot = "hallHaze", system = HallHaze.new() },
		-- left behind (L-08c): its camera runs between CameraShake's undo and apply
		{ slot = "watchView", system = WatchView.new(kick, needCursor) },
		-- the climb's end (L-08d): over everything, the results and "Again"
		{ slot = "endView", system = EndView.new(needCursor) },
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
