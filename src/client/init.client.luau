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
local CarDial = require(script.CarDial)
local CarPanel = require(script.CarPanel)
local CarResults = require(script.CarResults)
local CartRide = require(script.CartRide)
local CartView = require(script.CartView)
local CameraShake = require(script.CameraShake)
local CaughtView = require(script.CaughtView)
local KeptWrapOn = require(script.KeptWrapOn)
local ChaseMusic = require(script.ChaseMusic)
local CrawlView = require(script.CrawlView)
local CutFreeView = require(script.CutFreeView)
local DoorSounds = require(script.DoorSounds)
local DoorSpotView = require(script.DoorSpotView)
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
local LobbyView = require(script.LobbyView)
local NoteView = require(script.NoteView)
local PadlockView = require(script.PadlockView)
local SawView = require(script.SawView)
local ToolView = require(script.ToolView)
local TripView = require(script.TripView)
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
local toolView, myHand = ToolView.new(needCursor)
local wrapView, lay = WrapView.new(myHand, kick)
local cartView, ownCart, cartTold = CartView.new()

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
		-- a lobby car's panel: the host's choices and Go (L-08e1b2)
		{ slot = "carPanel", system = CarPanel.new(needCursor) },
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
		-- a door's buttons kept in view where your hand would go (L-19b), after the view drops
		{ slot = "doorSpotView", system = DoorSpotView.new() },
		{ slot = "freeCursor", system = freeCursor },
		{ slot = "hallHaze", system = HallHaze.new() },
		-- left behind (L-08c): its camera runs between CameraShake's undo and apply
		{ slot = "watchView", system = WatchView.new(kick, needCursor) },
		-- the climb's end (L-08d): over everything, the results and "Again"
		{ slot = "endView", system = EndView.new(needCursor) },
		{ slot = "cameraShake", system = cameraShake },
		-- arriving at the lobby's spawn: the camera turns to the six cars (L-08e1b1)
		{ slot = "lobbyView", system = LobbyView.new() },
		-- a lobby car's trip to the group's own server: the black, and the climb opening out of it
		{ slot = "tripView", system = TripView.new() },
		-- back in your car after the climb (L-08e2): the results on its back wall
		{ slot = "carResults", system = CarResults.new() },
		-- a dial over each lobby car, and the pointer to the fullest for a player in none (L-08e3)
		{ slot = "carDial", system = CarDial.new() },
		-- the lobby's platform carts: every cart rolling, and riding one yourself (L-08e4b1)
		{ slot = "cartView", system = cartView },
		{ slot = "cartRide", system = CartRide.new(ownCart, cartTold, kick, holdView) },
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
