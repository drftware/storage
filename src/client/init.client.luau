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
local BatteryView = require(script.BatteryView)
local BreakerView = require(script.BreakerView)
local FeedView = require(script.FeedView)
local FreeFriendView = require(script.FreeFriendView)
local CoinView = require(script.CoinView)
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
local DriveView = require(script.DriveView)
local DriverBodies = require(script.DriverBodies)
local InfraredView = require(script.InfraredView)
local ChipView = require(script.ChipView)
local FindUseView = require(script.FindUseView)
local HornView = require(script.HornView)
local FreeCursor = require(script.FreeCursor)
local GateClock = require(script.GateClock)
local HallHaze = require(script.HallHaze)
local HallLights = require(script.HallLights)
local HeadView = require(script.HeadView)
local HomeCards = require(script.HomeCards)
local HomeLights = require(script.HomeLights)
local KeeperSounds = require(script.KeeperSounds)
local KeeperView = require(script.KeeperView)
local KeypadPad = require(script.KeypadPad)
local KneelView = require(script.KneelView)
local MinimapView = require(script.MinimapView)
local MirrorView = require(script.MirrorView)
local ShelfView = require(script.ShelfView)
local StrandView = require(script.StrandView)
local JobBoxView = require(script.JobBoxView)
local BoxPanelView = require(script.BoxPanelView)
local ArrangeView = require(script.ArrangeView)
local SettleView = require(script.SettleView)
local LadderView = require(script.LadderView)
local LobbyView = require(script.LobbyView)
local MachineMenu = require(script.MachineMenu)
local MachineView = require(script.MachineView)
local MarkedBoxView = require(script.MarkedBoxView)
local NotePlaces = require(script.NotePlaces)
local NoteView = require(script.NoteView)
local FaintMarkView = require(script.FaintMarkView)
local PadlockView = require(script.PadlockView)
local SawView = require(script.SawView)
local ToolView = require(script.ToolView)
local KeepView = require(script.KeepView)
local TripView = require(script.TripView)
local RideView = require(script.RideView)
local ShopView = require(script.ShopView)
local TapView = require(script.TapView)
local UnderDoor = require(script.UnderDoor)
local UnitLights = require(script.UnitLights)
local WatchView = require(script.WatchView)
local Drive = require(ReplicatedStorage.Shared.Finds.Drive)
local Use = require(ReplicatedStorage.Shared.Finds.Use)
local Wrap = require(ReplicatedStorage.Shared.Tools.Wrap)
local WrapView = require(script.WrapView)

local cameraShake, kick, holdView = CameraShake.new()
local freeCursor, needCursor = FreeCursor.new()
local elevatorView, pressKeypad = ElevatorView.new(kick)
local keeperSounds, keeperHeard = KeeperSounds.new()
local toolView, myHand = ToolView.new(needCursor, kick)
local wrapView, lay = WrapView.new(myHand, kick)
local findUseView, findUse = FindUseView.new(myHand)
-- the button's presses with a tool or find in hand other than the horn: each answers on your
-- screen first (the wrap laid, the lantern clicking on)
local presses: { [string]: () -> boolean } = { [Wrap.Key] = lay }
for key in Use.Rows do
	presses[key] = function(): boolean
		return findUse.press(key)
	end
end
-- the RC car's Drive (F-G1b3c2c): the button hides while you drive
local driveView, driving = DriveView.new(myHand, kick)
presses[Drive.Key] = driving.press
-- your torch is put away while your view is on the car you drive
local flashlightView, myBeam = FlashlightView.new(driving.viewing)
local function can(key: string): boolean
	if key == Drive.Key then
		return driving.can()
	end
	return findUse.can(key)
end
local cartView, ownCart, cartTold = CartView.new()
local machineView, pressMachine = MachineView.new()

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
		-- a home's lamps on its switch (S5-03a2b3), before BehindDoors for the same reason
		{ slot = "homeLights", system = HomeLights.new() },
		{ slot = "homeCards", system = HomeCards.new() },
		-- the mirror in your home: you, the right way round, your unit behind you (S5-03b)
		{ slot = "mirrorView", system = MirrorView.new() },
		{ slot = "shelfView", system = ShelfView.new() },
		{ slot = "jobBoxView", system = JobBoxView.new() },
		{ slot = "boxPanelView", system = BoxPanelView.new(needCursor) },
		-- lift, drag and set down your finds in your home (S5-03e3a)
		{ slot = "arrangeView", system = ArrangeView.new(needCursor) },
		-- a friend's find set out drops into place with a knock (S5-03e3b)
		{ slot = "settleView", system = SettleView.new() },
		-- the find on your head kept out of your own eye, still on you for friends and the mirror
		{ slot = "headView", system = HeadView.new() },
		-- the fairy lights laid along a hall, on every screen (F-G1e5c)
		{ slot = "strandView", system = StrandView.new() },
		-- a cracked find's crack on your view's copy of it (F-G1e5e)
		{ slot = "chipView", system = ChipView.new(myHand) },
		{ slot = "behindDoors", system = BehindDoors.new() },
		{ slot = "elevatorView", system = elevatorView },
		{ slot = "keypadPad", system = KeypadPad.new(pressKeypad, needCursor) },
		-- a lobby car's panel: the host's choices and Go (L-08e1b2)
		{ slot = "carPanel", system = CarPanel.new(needCursor) },
		-- every button in the world, drawn one way (L-19a)
		{ slot = "buttonView", system = ButtonView.new() },
		{ slot = "gateClock", system = GateClock.new() },
		{ slot = "rideView", system = RideView.new(holdView) },
		-- the machine in the car, waking on the ride (S1-10b2)
		{ slot = "machineView", system = machineView },
		-- the machine's menu: its one button opens its front on your screen (S1-10d1)
		{ slot = "machineMenu", system = MachineMenu.new(pressMachine, needCursor) },
		{ slot = "minimapView", system = MinimapView.new() },
		-- the coins: a pile's take on every screen, and your count by the top bar (S1-04a2)
		{ slot = "coinView", system = CoinView.new() },
		-- the batteries: a button only while your torch needs one, a take thrown into its torch
		{ slot = "batteryView", system = BatteryView.new() },
		-- the marked boxes: a shut one's lit seam and hum, an open played on every screen (B-02a)
		{ slot = "markedBoxView", system = MarkedBoxView.new() },
		-- each floor's breaker box: the clunk and red lamp thrown, the lever under the hand, the hum
		{ slot = "breakerView", system = BreakerView.new(kick) },
		-- a security camera's feed over the corner map: a monster doing something, seen (S2-02d);
		-- after the keepers' bodies and the box are posed, so its picture shows this frame's
		{ slot = "feedView", system = FeedView.new() },
		-- caught while driving the RC car, your view leaves its hood first
		{ slot = "caughtView", system = CaughtView.new(kick, driving.leave) },
		-- a caught friend's face under the corner map, to pay to free them (S3-03b)
		{ slot = "freeFriendView", system = FreeFriendView.new() },
		{ slot = "chaseMusic", system = ChaseMusic.new() },
		{ slot = "keptWrapOn", system = KeptWrapOn.new() },
		{ slot = "cutFreeView", system = CutFreeView.new(kick) },
		{ slot = "bangMarks", system = BangMarks.new() },
		{ slot = "padlockView", system = PadlockView.new(kick) },
		{ slot = "underDoor", system = UnderDoor.new() },
		-- the tap's bar as your door comes down on a sleeping monster (S2-05a)
		{ slot = "tapView", system = TapView.new() },
		{ slot = "noteView", system = NoteView.new() },
		{ slot = "notePlaces", system = NotePlaces.new() },
		-- the faint mark on one note's door frame, shown only in your beam (S1-11)
		{ slot = "faintMarkView", system = FaintMarkView.new(myBeam) },
		{ slot = "flashlightView", system = flashlightView },
		{ slot = "toolView", system = toolView },
		-- after ToolView: your finds kept at the gate rise out of its slots (S1-06)
		{ slot = "keepView", system = KeepView.new() },
		-- after ToolView, so its button lands beside a bar that's there
		{ slot = "hornView", system = HornView.new(myHand, kick, presses, can) },
		-- a pressed find's motions, light and sound on every screen; yours on your view's copy too
		{ slot = "findUseView", system = findUseView },
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
		-- the RC car: your view on its hood while you drive, between CameraShake's undo and apply
		{ slot = "driveView", system = driveView },
		-- every driver crouched over the transmitter; yours shown only while your view is on the
		-- car, so after the drive view in the same frame
		{ slot = "driverBodies", system = DriverBodies.new(driving.viewing) },
		-- the car's view in the dark (F-G1b3c2e): after the drive view has put the camera on the
		-- hood, so its lamp rides there this frame
		{ slot = "infraredView", system = InfraredView.new(driving.hull) },
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
		-- the counter's shop: its prompt, the lobby's Shop button, the wrap colours (S3-04b)
		{ slot = "shopView", system = ShopView.new() },
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
