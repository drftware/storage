--!strict
--[[
	ElevatorView: every freight elevator on this player's screen, its gate folding and its keypad
	answering, with their sounds (L-05b1c). The server decides everything (Elevators) and writes
	it as two replicated values on the elevator, the gate's motion (`Gate.Attribute`) and the
	keypad's state (`Keypad.Attribute`); this draws both:

	- The gate folds from its motion, posed every frame while it moves (only moving gates are
	  stepped), and jolts the view of anyone beside it the instant it slams.
	- Each press sinks its key into the keypad and back, with a beep. The readout's red LED digits
	  (LedReadout) sit on an invisible card just off the readout's glass: dim dashes at rest, a
	  digit lit as it's punched; a wrong code blinks them, and the status light with them, while
	  the alarm rings; the right one turns the digits, the light and the glow green.
	- The sounds (Elevator.Sounds) are timed off the server's clock, so the fold's slam lands as
	  every player sees the gate hit.
	- The car's lamp answers the gate's clock (Departure, L-05b2): steady while it counts, blinking
	  ever faster through the warning, steady as the gate shuts; once the car leaves, its light
	  draws away for everyone it left in the lobby, and they're in the dark. For those aboard it
	  dips and flickers with the ride (Ride, L-08a): the brakes letting go, the clanks, the stop.
	- The car's floor readout, over the gate inside: two amber LED digits and an arrow, the floor
	  it stands at, ticking over to the next as the brakes bite on the way up (Ride).
	- A lobby car (L-08e1b1, Boarding): its keypad's readout is its count, for everyone in the
	  room: dim dashes while nobody's aboard, the seconds green, then red from the warning; its
	  floor readout says L.

	The screen keypad (KeypadPad) calls `press` to beep and sink a key the instant it's pressed;
	the server's echo of that press names this player (`by`), so it's skipped here.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local LedReadout = require(script.Parent.LedReadout)
local Shake = require(ReplicatedStorage.Shared.Shake)
local SoundPrimer = require(script.Parent.SoundPrimer)

local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Gate = require(ReplicatedStorage.Shared.Elevator.Gate)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Left = require(ReplicatedStorage.Shared.Left)
local Readout = require(ReplicatedStorage.Shared.Elevator.Readout)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local RideClock = require(script.Parent.RideClock)
local Sounds = require(ReplicatedStorage.Shared.Elevator.Sounds)
local Specs = require(ReplicatedStorage.Shared.Elevator.Specs)

-- A pressed key snaps in at once, holds a beat, then springs back out over this.
local KEY_BACK = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.05)
-- The wall readout's LEDs: each digit 78% of the glass's height, 6% of its width apart. The card's
-- pixels a stud (sharp at arm's length) and how far off it still draws (it's lit, so the dashes
-- read from across the lobby).
local CARD_PIXELS = 400
local CARD_REACH = 70
-- Lit LEDs a touch over full brightness, so they glow against the dark glass.
local CARD_BRIGHTNESS = 1.3
local WALL_LOOK: LedReadout.Look = {
	unlit = Elevator.ReadoutUnlit,
	unlitTransparency = 0.6,
	rest = Elevator.ReadoutRest,
	lit = Elevator.ReadoutLit,
	right = Elevator.ReadoutRight,
}
-- The car's floor readout: a dark plate over the gate on the inside of the car's fascia, facing
-- in, its size (studs) and its middle; lit amber like the lamp. `FLOOR_LOOK`'s rest tone is the
-- arrow's while the car stands.
local FLOOR_PLATE = Vector2.new(1.5, 0.56)
local FLOOR_AT =
	CFrame.new(0, 9.02, Specs.Parts.CarFront.Centre[3] + Specs.Parts.CarFront.Size[3] / 2 + 0.004)
local FLOOR_PIXELS = 160
local FLOOR_LOOK: LedReadout.Look = {
	unlit = Elevator.FloorUnlit,
	unlitTransparency = 0.6,
	rest = Elevator.FloorUnlit,
	lit = Elevator.FloorLit,
	right = Elevator.FloorLit,
}
-- Where the gate's sounds come from: the middle of the opening, at chest height, in its plane.
local GATE_SOUNDS = CFrame.new(0, 4.5, Specs.Gate.Plane)

type Key = { part: BasePart, rest: CFrame, tween: Tween? }

type View = {
	model: Model,
	alive: boolean,
	lobby: boolean, -- a lobby car: its readout counts (Boarding)
	countSet: LedReadout.Set?, -- its readout's cells, for the count
	conns: { RBXScriptConnection },
	made: { Instance }, -- what this screen added to the elevator, removed with it
	-- the gate
	from: number,
	to: number,
	start: number,
	motions: number, -- counts its motions, so a new one cancels the last one's sounds still to come
	slammed: boolean,
	-- the keypad
	state: Keypad.State,
	since: number, -- os.clock() when its state last changed
	draw: LedReadout.Draw?,
	keys: { [number]: Key },
	travel: Vector3, -- a key's push into the keypad, in the world
	light: BasePart?,
	glow: PointLight?,
	tone: Readout.Tone?, -- the status light's, as last shown
	-- the car's lamp and the gate's clock
	lamp: PointLight?,
	lampGlass: BasePart?,
	lampColour: Color3,
	lampShare: number, -- of its brightness, as last shown
	departs: number?, -- server time the clock runs out, while one is set
	leftAt: number?, -- server time the car left, once it has
	rode: boolean, -- this player was aboard when it left
	-- the ride and the car's floor readout
	rideAt: number?, -- server time the ride began, while one is set
	rideFrom: number,
	rideTo: number,
	floorSet: LedReadout.Set?,
	arrow: { Frame },
	floorShown: number, -- the floor on the readout, -1 before it shows one
	arrowLit: boolean?,
	-- the sounds
	emitters: { [Sounds.Source]: Attachment },
	sounds: { [Sounds.SoundName]: Sound },
	fades: { [Sound]: Tween },
}

-- What the screen keypad calls on a press: beep and sink that key on `model`'s keypad now.
export type Press = (model: Model, key: Keypad.Key) -> ()

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function find(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

local ElevatorView = {}

-- `kick` shakes this player's view (CameraShake's).
function ElevatorView.new(kick: (amount: number) -> ()): (Brix.System, Press)
	local views: { [Model]: View } = {}
	local moving: { [View]: true } = {}
	local blinking: { [View]: true } = {}
	local lamps: { [View]: true } = {} -- lamps blinking or drawing away
	local riding: { [View]: true } = {} -- floor readouts counting a ride
	local connections: { RBXScriptConnection } = {}

	-- Where this player hears from: their character, or the camera without one.
	local function listener(): Vector3?
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
		local camera = Workspace.CurrentCamera
		return if camera then camera.CFrame.Position else nil
	end

	local function emitter(view: View, source: Sounds.Source): Attachment?
		local existing = view.emitters[source]
		if existing then
			return existing
		end
		local host = find(view.model, if source == "Keypad" then "Keypad" else "Car")
		if not host then
			return nil
		end
		local a = Instance.new("Attachment")
		a.Name = `{source}Sounds`
		a.Parent = host
		a.WorldCFrame = if source == "Keypad"
			then CFrame.new(Elevator.keypadPoint(view.model))
			else view.model:GetPivot() * GATE_SOUNDS
		view.emitters[source] = a
		table.insert(view.made, a)
		return a
	end

	local function soundFor(view: View, name: Sounds.SoundName): Sound?
		local existing = view.sounds[name]
		if existing then
			return existing
		end
		local row = Sounds.Sounds[name]
		local at = emitter(view, row.Source)
		if not at then
			return nil
		end
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = row.Id
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = row.Near
		s.RollOffMaxDistance = row.Reach
		s.PlaybackRegionsEnabled = true
		s.Parent = at
		view.sounds[name] = s
		return s
	end

	-- Plays `cue` now, `late` seconds behind time: a timed sound skips ahead to keep its slam.
	local function play(view: View, cue: Sounds.Cue, late: number)
		local row = Sounds.Sounds[cue.sound]
		local s = soundFor(view, cue.sound)
		if not s then
			return
		end
		local fading = view.fades[s]
		if fading then
			fading:Cancel()
			view.fades[s] = nil
		end
		local from = if row.Timed then cue.from + late * cue.pitch else cue.from
		if from >= row.Stop then
			return
		end
		s.PlaybackRegion = NumberRange.new(from, row.Stop)
		s.PlaybackSpeed = cue.pitch
		s.Volume = row.Volume
		s.TimePosition = from
		s:Play()
		if row.Fade > 0 then
			-- fade out over the stretch's last Fade seconds (at this pitch), so the cut is silent
			local length = row.Stop - from
			local info = TweenInfo.new(
				math.min(row.Fade, length) / cue.pitch,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				0,
				false,
				math.max(length - row.Fade, 0) / cue.pitch
			)
			local tween = TweenService:Create(s, info, { Volume = 0 })
			tween:Play()
			view.fades[s] = tween
		end
	end

	-- Plays `cue` `wait` seconds from now while `current()` holds; at once if it's only a little late.
	local function schedule(view: View, cue: Sounds.Cue, wait: number, current: () -> boolean)
		if wait < -Sounds.LateCue then
			return
		elseif wait <= 0 then
			play(view, cue, -wait)
			return
		end
		task.delay(wait, function()
			if view.alive and current() then
				play(view, cue, 0)
			end
		end)
	end

	-- Sinks key `digit` into the keypad at once and springs it back out.
	local function sink(view: View, digit: number)
		local key = view.keys[digit]
		if not key then
			return
		end
		if key.tween then
			key.tween:Cancel()
		end
		key.part.CFrame = key.rest + view.travel
		local tween = TweenService:Create(key.part, KEY_BACK, { CFrame = key.rest })
		key.tween = tween
		tween:Play()
	end

	-- The status light and the glow: red, green once the code is right, dark between blinks.
	local function showLight(view: View, tone: Readout.Tone)
		if view.tone == tone then
			return
		end
		view.tone = tone
		local light = view.light
		if light then
			light.Color = if tone == "Right"
				then Elevator.KeypadRight
				elseif tone == "Off" then Elevator.KeypadDark
				else Elevator.KeypadLight
		end
		local glow = view.glow
		if glow then
			glow.Color = if tone == "Right"
				then Elevator.KeypadRight
				else Elevator.KeypadGlow.Colour
			glow.Enabled = tone ~= "Off"
		end
	end

	local function draw(view: View)
		local since = os.clock() - view.since
		local d = view.draw
		if d then
			d(view.state, since)
		end
		showLight(view, Readout.light(view.state, since))
	end

	-- The server wrote the keypad's state: draw it and, when it's news, sound it.
	local function keypadChanged(view: View, live: boolean)
		local state = Keypad.decode(view.model:GetAttribute(Keypad.Attribute))
		if live and state.count == view.state.count then
			return
		end
		view.state, view.since = state, os.clock()
		draw(view)
		if Readout.blinking(state) then
			blinking[view] = true
		end
		if not live then
			return -- streaming in: the keypad as it stands, no replayed beeps
		end
		-- this player's own presses beeped and sank when they were made (`press`)
		local mine = state.by ~= nil and state.by == Players.LocalPlayer.UserId
		if state.digit and not mine then
			sink(view, state.digit)
		end
		local pressed = not mine and (state.digit ~= nil or state.event == "Clear")
		local count = state.count
		local function current(): boolean
			return view.state.count == count
		end
		for _, cue in Sounds.keypad(state.event, pressed) do
			schedule(view, cue, cue.at, current)
		end
	end

	-- The server sent the gate somewhere: pose it where it is now, then fold it each frame.
	local function gateChanged(view: View)
		local from, to, start = Gate.decode(view.model:GetAttribute(Gate.Attribute))
		view.from, view.to, view.start = from, to, start
		view.motions += 1
		local elapsed = now() - start
		if elapsed >= Gate.settles(from, to) then
			Elevator.setGate(view.model, to) -- long over: a gate streaming in where it ended up
			moving[view] = nil
			return
		end
		Elevator.setGate(view.model, Gate.at(from, to, elapsed))
		view.slammed = elapsed >= Gate.duration(from, to)
		moving[view] = true
		local mine = view.motions
		local function current(): boolean
			return view.motions == mine
		end
		for _, cue in Sounds.gate(from, to) do
			schedule(view, cue, cue.at - elapsed, current)
		end
	end

	-- The gate hit the stack or the post: jolt the view of anyone beside it.
	local function slam(view: View)
		local from = listener()
		if from then
			local d = (from - (view.model:GetPivot() * GATE_SOUNDS).Position).Magnitude
			kick(Sounds.SlamShake * Shake.falloff(d, Sounds.ShakeNear, Sounds.ShakeReach))
		end
	end

	-- The car's lamp at `share` of its brightness: its light and its glowing glass.
	local function showLamp(view: View, share: number)
		if view.lampShare == share then
			return
		end
		view.lampShare = share
		local light = view.lamp
		if light then
			light.Brightness = Elevator.Lamp.Brightness * share
			light.Enabled = share > 0
		end
		local glass = view.lampGlass
		if glass then
			local c = view.lampColour
			glass.Color = Color3.new(c.R * share, c.G * share, c.B * share)
		end
	end

	-- The lamp at server time `t`, and whether it's still changing.
	local function lampAt(view: View, t: number): (number, boolean)
		local rideAt = view.rideAt
		if rideAt and view.rode then
			local since = RideClock(rideAt, t)
			return Ride.lamp(since), since < Ride.opens()
		end
		local leftAt = view.leftAt
		if leftAt and not view.rode then
			local since = t - leftAt
			return Departure.away(since), since < Departure.LampAway
		end
		local departs = view.departs
		if departs then
			local left = departs - t
			return Departure.lamp(left), left > 0
		end
		return 1, false
	end

	-- A lobby car's readout at server time `t`: its count, or dashes while nobody's aboard.
	local function countStep(view: View, t: number)
		local set = view.countSet
		if not set then
			return
		end
		local departs = view.departs
		local left = if departs then departs - t else nil
		for i = 1, Keypad.Length do
			local char: string, tone: Boarding.Tone = Boarding.readout(left, i)
			set(i, char, tone)
		end
	end

	local function lampStep(view: View, t: number)
		if view.lobby then
			countStep(view, t) -- stepped with the lamp, which changes all through the count
		end
		local share, changing = lampAt(view, t)
		showLamp(view, share)
		if changing then
			lamps[view] = true
		else
			lamps[view] = nil
		end
	end

	-- The server set the gate's clock running, or cleared it (the elevator armed again).
	local function clockChanged(view: View)
		local departs = view.model:GetAttribute(Departure.Attribute)
		view.departs = if type(departs) == "number" then departs else nil
		lampStep(view, now())
	end

	-- The car left (or, cleared, is back for the next floor): who rode decides the lamp. Left
	-- behind and watching a friend (L-08c), every car is seen as its riders see it: the lamp the
	-- ride's, never drawing away (the car that left you drew away before you watched).
	local function aboardChanged(view: View)
		local at, ids = Departure.decodeAboard(view.model:GetAttribute(Departure.AboardAttribute))
		local me = Players.LocalPlayer
		view.leftAt = at
		view.rode = at ~= nil
			and (table.find(ids, me.UserId) ~= nil or me:FindFirstChild(Left.WatchValue) ~= nil)
		lampStep(view, now())
	end

	-- Watching began or ended: every car's lamp is decided again.
	local function watchChanged(child: Instance)
		if child.Name == Left.WatchValue then
			for _, view in views do
				aboardChanged(view)
			end
		end
	end

	-- The car's floor readout at server time `t`: the floor it stands at, or the ride's; the
	-- arrow lit while it climbs. Touches the gui only when what it shows changes.
	local function floorStep(view: View, t: number)
		local set = view.floorSet
		if not set then
			riding[view] = nil
			return
		end
		local n, up = 0, false
		local rideAt = view.rideAt
		local since = if rideAt then RideClock(rideAt, t) else math.huge
		if since < Ride.opens() then
			n = Ride.shown(since, view.rideFrom, view.rideTo)
			up = Ride.share(since) > 0.02
			riding[view] = true
		else
			local floor = view.model:GetAttribute(Ride.FloorAttribute)
			n = if type(floor) == "number" then floor else 0
			riding[view] = nil
		end
		if n ~= view.floorShown then
			view.floorShown = n
			local text = if n > 0 or (view.lobby and n == Ride.Lobby) then Ride.text(n) else "  "
			for i = 1, 2 do
				local char = string.sub(text, i, i)
				set(i, char, if char == " " then "Off" else "Lit")
			end
		end
		if up ~= view.arrowLit then
			view.arrowLit = up
			for _, f in view.arrow do
				f.BackgroundColor3 = if up then Elevator.FloorLit else Elevator.FloorUnlit
				f.BackgroundTransparency = if up then 0 else 0.6
			end
		end
	end

	-- The ride began (or, cleared, is over): its floors for the readout.
	local function rideChanged(view: View)
		local at, from, to = Ride.decode(view.model:GetAttribute(Ride.Attribute))
		view.rideAt, view.rideFrom, view.rideTo = at, from, to
		local t = now()
		lampStep(view, t)
		floorStep(view, t)
	end

	-- The car's floor readout: a dark plate on an invisible card on the inside of the fascia over
	-- the gate, facing into the car, an arrow and two LED digits.
	local function makeFloorReadout(view: View)
		local card = Instance.new("Part")
		card.Name = "FloorReadout"
		card.Size = Vector3.new(FLOOR_PLATE.X, FLOOR_PLATE.Y, 0.002)
		card.CFrame = view.model:GetPivot() * FLOOR_AT
		card.Transparency = 1
		card.Anchored = true
		card.CanCollide = false
		card.CanTouch = false
		card.CanQuery = false
		card.CastShadow = false
		card.Massless = true
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Floor"
		gui.Face = Enum.NormalId.Back -- into the car
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = FLOOR_PIXELS
		gui.LightInfluence = 0 -- the LEDs make their own light
		gui.Brightness = CARD_BRIGHTNESS
		gui.MaxDistance = CARD_REACH
		local plate = Instance.new("Frame")
		plate.Name = "Plate"
		plate.Size = UDim2.fromScale(1, 1)
		plate.BackgroundColor3 = Color3.fromRGB(14, 10, 8)
		plate.BorderSizePixel = 0
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.14, 0)
		corner.Parent = plate
		local rim = Instance.new("UIStroke")
		rim.Color = Color3.fromRGB(70, 62, 52)
		rim.Thickness = 3
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Parent = plate
		-- the arrow: three LED rows stepped into a point, at the plate's left
		local arrow: { Frame } = {}
		for row = 1, 3 do
			local f = Instance.new("Frame")
			f.Name = `Arrow{row}`
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale(0.2, 0.3 + 0.18 * (row - 1))
			f.Size = UDim2.fromScale(0.05 + 0.065 * (row - 1), 0.13)
			f.BorderSizePixel = 0
			f.BackgroundColor3 = Elevator.FloorUnlit
			f.BackgroundTransparency = 0.6
			f.Parent = plate
			table.insert(arrow, f)
		end
		local digits = Instance.new("Frame")
		digits.Name = "Digits"
		digits.BackgroundTransparency = 1
		digits.AnchorPoint = Vector2.new(1, 0)
		digits.Position = UDim2.fromScale(0.94, 0)
		digits.Size = UDim2.fromScale(0.62, 1)
		digits.Parent = plate
		view.floorSet = LedReadout.row(digits, FLOOR_LOOK, 0.7, 0.08, 2)
		view.arrow = arrow
		plate.Parent = gui
		gui.Parent = card
		card.Parent = view.model
		table.insert(view.made, card)
	end

	-- The readout's digits on an invisible card just off its glass, facing the lobby.
	local function makeReadout(view: View)
		local glass = Specs.Parts.KeypadReadout
		local front = glass.Centre[3] - glass.Size[3] / 2
		local card = Instance.new("Part")
		card.Name = "ReadoutDigits"
		card.Size = Vector3.new(glass.Size[1], glass.Size[2], 0.002)
		-- its front face 0.003 off the glass, as the note's card is off its paper
		card.CFrame = view.model:GetPivot()
			* CFrame.new(glass.Centre[1], glass.Centre[2], front - 0.002)
		card.Transparency = 1
		card.Anchored = true
		card.CanCollide = false
		card.CanTouch = false
		card.CanQuery = false
		card.CastShadow = false
		card.Massless = true
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Digits"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = CARD_PIXELS
		gui.LightInfluence = 0 -- the LEDs make their own light
		gui.Brightness = CARD_BRIGHTNESS
		gui.MaxDistance = CARD_REACH
		gui.Parent = card
		if view.lobby then
			view.countSet = LedReadout.row(gui, WALL_LOOK, 0.78, 0.06, Keypad.Length)
		else
			view.draw = LedReadout.new(gui, WALL_LOOK, 0.78, 0.06)
		end
		card.Parent = view.model
		table.insert(view.made, card)
	end

	local function remove(inst: Instance)
		local view = views[inst :: Model]
		if not view then
			return
		end
		views[inst :: Model] = nil
		moving[view] = nil
		blinking[view] = nil
		lamps[view] = nil
		riding[view] = nil
		view.alive = false
		for _, c in view.conns do
			c:Disconnect()
		end
		for _, tween in view.fades do
			tween:Cancel()
		end
		for _, key in view.keys do
			if key.tween then
				key.tween:Cancel()
			end
		end
		for _, made in view.made do
			made:Destroy()
		end
	end

	local function add(inst: Instance)
		-- only elevators in the world: the template in ReplicatedStorage draws nothing
		if not inst:IsA("Model") or views[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local pivot = inst:GetPivot()
		local keys: { [number]: Key } = {}
		for digit = 0, 9 do
			local p = find(inst, `Key{digit}`)
			if p then
				keys[digit] = { part = p, rest = p.CFrame, tween = nil }
			end
		end
		local keypad = find(inst, "Keypad")
		local glowAt = keypad and keypad:FindFirstChild("Glow")
		local glow = glowAt and glowAt:FindFirstChildWhichIsA("PointLight")
		local lampGlass = find(inst, "LampGlass")
		local lampHolder = lampGlass and lampGlass:FindFirstChild("LampLight")
		local lamp = lampHolder and lampHolder:FindFirstChildWhichIsA("PointLight")
		local view: View = {
			model = inst,
			alive = true,
			lobby = inst:GetAttribute(Boarding.CarAttribute) ~= nil,
			countSet = nil,
			conns = {},
			made = {},
			from = 1,
			to = 1,
			start = 0,
			motions = 0,
			slammed = true,
			state = Keypad.decode(nil),
			since = os.clock(),
			draw = nil,
			keys = keys,
			travel = pivot:VectorToWorldSpace(Vector3.new(0, 0, Specs.Keypad.Travel)),
			light = find(inst, "KeypadLight"),
			glow = glow,
			tone = nil,
			lamp = lamp,
			lampGlass = lampGlass,
			lampColour = Elevator.Lamp.Colour,
			lampShare = 1,
			departs = nil,
			leftAt = nil,
			rode = false,
			rideAt = nil,
			rideFrom = 0,
			rideTo = 0,
			floorSet = nil,
			arrow = {},
			floorShown = -1,
			arrowLit = nil,
			emitters = {},
			sounds = {},
			fades = {},
		}
		views[inst] = view
		if find(inst, "KeypadReadout") then
			makeReadout(view)
		end
		if find(inst, "CarFront") then
			makeFloorReadout(view)
		end
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Gate.Attribute):Connect(function()
				gateChanged(view)
			end)
		)
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Keypad.Attribute):Connect(function()
				keypadChanged(view, true)
			end)
		)
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Departure.Attribute):Connect(function()
				clockChanged(view)
			end)
		)
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Departure.AboardAttribute):Connect(function()
				aboardChanged(view)
			end)
		)
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Ride.Attribute):Connect(function()
				rideChanged(view)
			end)
		)
		table.insert(
			view.conns,
			inst:GetAttributeChangedSignal(Ride.FloorAttribute):Connect(function()
				floorStep(view, now())
			end)
		)
		gateChanged(view) -- mid-motion as it streams in: folding on, with only the sounds still to come
		keypadChanged(view, false)
		clockChanged(view)
		aboardChanged(view)
		rideChanged(view)
	end

	-- Readies every elevator sound up front, so the first slam isn't late (SoundPrimer).
	local function preload()
		local ids: { string } = {}
		for _, row in Sounds.Sounds do
			table.insert(ids, row.Id)
		end
		SoundPrimer.prime(ids)
	end

	local function press(model: Model, key: Keypad.Key)
		local view = views[model]
		if not view then
			return
		end
		play(view, Sounds.press(key), 0)
		if type(key) == "number" then
			sink(view, key)
		end
	end

	local system: Brix.System = {
		name = "ElevatorView",
		start = function(_: any, _context: Brix.Context)
			task.spawn(preload)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(add)
			)
			local me = Players.LocalPlayer
			table.insert(connections, me.ChildAdded:Connect(watchChanged))
			table.insert(
				connections,
				me.ChildRemoved:Connect(function(child: Instance)
					task.defer(watchChanged, child)
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Elevator.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, _dt: number)
			if next(moving) ~= nil then
				local t = now()
				for view in moving do
					local elapsed = t - view.start
					if elapsed <= 0 then
						continue -- still waiting on the latch: posed where it rests
					end
					if not view.slammed and elapsed >= Gate.duration(view.from, view.to) then
						view.slammed = true
						slam(view)
					end
					if elapsed >= Gate.settles(view.from, view.to) then
						Elevator.setGate(view.model, view.to)
						moving[view] = nil
					else
						Elevator.setGate(view.model, Gate.at(view.from, view.to, elapsed))
					end
				end
			end
			for view in blinking do
				draw(view)
				if not Readout.blinking(view.state) then
					blinking[view] = nil
				end
			end
			if next(lamps) ~= nil then
				local t = now()
				for view in lamps do
					lampStep(view, t)
				end
			end
			if next(riding) ~= nil then
				local t = now()
				for view in riding do
					floorStep(view, t)
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in views do
				remove(model)
			end
		end,
	}
	return system, press
end

return ElevatorView
