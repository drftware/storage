--!strict
--[[
	GateClock: the gate's clock on this player's screen and in their ears (L-05b2), while they're
	on its floor (within Departure.Heard of the elevator). The server sets it (Elevators); this
	shows it, all of it timed off the server's clock so every friend counts the same seconds:

	- The clock: the elevator's own LED digits, in the middle of Roblox's top bar. It pops in with
	  the PA's chime as the gate slams open, green; from the warning it's red and jumps each second.
	- The heartbeat under the warning, swelling and quickening to zero (Dandy's World's), and the
	  elevator's bell on each of the last five seconds, a little higher each time.
	- The car leaving: "Going up" for those aboard, and the plate turns from the clock to the
	  floor counter in the car lamp's amber, ticking over to the next floor as the brakes bite
	  (Ride, L-08a); "Left behind" for everyone else on the floor.

	The car's lamp, which answers the same clock, is ElevatorView's; the rest of the ride is
	RideView's.
]]
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local LedReadout = require(script.Parent.LedReadout)
local Readout = require(ReplicatedStorage.Shared.Elevator.Readout)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local RideClock = require(script.Parent.RideClock)
local SoundPrimer = require(script.Parent.SoundPrimer)

-- The clock's plate: as tall as this share of the top bar's row (or `PLATE_BARE` pixels where
-- there's no top bar), this much wider than tall, the readout's dark glass under the elevator's LED
-- colours. It sits in the middle of the screen, in the top bar's row, nudged clear of Roblox's
-- buttons where they'd meet it.
local PLATE_HEIGHT = 0.8
local PLATE_BARE = 40
local PLATE_ASPECT = 1.5
local PLATE_COLOUR = Color3.fromRGB(22, 6, 5)
local PLATE_RIM = Color3.fromRGB(110, 26, 20)
local LOOK: LedReadout.Look = {
	unlit = Elevator.ReadoutUnlit,
	unlitTransparency = 0.7,
	rest = Elevator.ReadoutLit,
	lit = Elevator.ReadoutLit,
	right = Elevator.ReadoutRight,
}
-- The floor counter on the same plate while you ride: amber, the car lamp's light, as the car's
-- own readout (ElevatorView). It takes over from the clock `FLOOR_AFTER` seconds after the gate
-- hits its post (the 0 has been seen), and goes `FLOOR_HOLD` seconds after the gate starts to
-- open on the next floor.
local FLOOR_LOOK: LedReadout.Look = {
	unlit = Elevator.FloorUnlit,
	unlitTransparency = 0.7,
	rest = Elevator.FloorLit,
	lit = Elevator.FloorLit,
	right = Elevator.FloorLit,
}
local FLOOR_AFTER = 0.45
local FLOOR_HOLD = 1.4
-- The clock pops in from this scale with an overshoot, and fades out when the car has gone.
local POP_FROM = 0.55
local POP = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local GONE = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- Each second of the warning jumps the clock to this scale and back; the final ones further.
local JUMP = 1.14
local JUMP_FINAL = 1.26
local JUMP_BACK = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- The chime plays only for a clock that pops in this soon after it starts: a player walking into
-- reach mid-count sees the clock, but the PA doesn't ring again.
local CHIME_LATE = 0.5
-- The headline: big, plain, a third of the way down; in with a pop, held, then out.
local HEADLINE_SIZE = 34
local HEADLINE_IN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HEADLINE_HOLD = 1.8
local HEADLINE_OUT = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- "Going up" in the car lamp's warm light; "Left behind" in a cold red.
local WARM = Elevator.Lamp.Colour
local COLD = Color3.fromRGB(255, 96, 84)
-- A leaving older than this (seconds) when it arrives is old news (an elevator streaming in).
local STALE = 1.5

type Clock = {
	model: Model,
	departs: number?,
	conns: { RBXScriptConnection },
}

type Ui = {
	place: () -> (),
	clock: CanvasGroup,
	scale: UIScale,
	set: LedReadout.Set,
	seconds: Frame, -- the clock's digits
	floors: Frame, -- the floor counter's, in their place while you ride
	setFloor: LedReadout.Set,
	headline: TextLabel,
	headlineStroke: UIStroke,
	headlineScale: UIScale,
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Where this player is: their character, or the camera without one.
local function listener(): Vector3?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	local camera = Workspace.CurrentCamera
	return if camera then camera.CFrame.Position else nil
end

local function onFloor(model: Model): boolean
	local at = listener()
	return at ~= nil and (at - model:GetPivot().Position).Magnitude <= Departure.Heard
end

local function sound(name: string, row: Departure.Recording): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = row.Id
	s.Volume = row.Volume
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(row.Start, row.Stop)
	s.Parent = SoundService -- no place in the world: heard alike everywhere on the floor
	return s
end

local function build(): Ui
	local parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- the clock, in the top bar's row
	local bar = Instance.new("ScreenGui")
	bar.Name = "GateClock"
	bar.ResetOnSpawn = false
	bar.IgnoreGuiInset = true
	bar.DisplayOrder = 5
	bar.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local clock = Instance.new("CanvasGroup")
	clock.Name = "Clock"
	clock.AnchorPoint = Vector2.new(0.5, 0.5)
	clock.BackgroundTransparency = 1
	clock.GroupTransparency = 1
	clock.Visible = false
	-- Sizes and places the clock for this screen: its middle on the screen's, in the top bar's
	-- row, clear of the buttons either side (GuiService.TopbarInset is the row's free stretch).
	local function place()
		local camera = Workspace.CurrentCamera
		local width = if camera then camera.ViewportSize.X else 0
		local free = GuiService.TopbarInset
		local row = free.Height
		local h = if row > 0 then math.floor(row * PLATE_HEIGHT) else PLATE_BARE
		local w = math.floor(h * PLATE_ASPECT)
		local y = if row > 0 then row / 2 else 8 + h / 2
		local x = width / 2
		if row > 0 and free.Width >= w then
			x = math.clamp(x, free.Min.X + w / 2, free.Max.X - w / 2)
		end
		clock.Size = UDim2.fromOffset(w, h)
		clock.Position = UDim2.fromOffset(x, y)
	end
	place()
	local scale = Instance.new("UIScale")
	scale.Parent = clock
	-- the plate, inset so its rim isn't clipped by the group
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = UDim2.fromScale(0.5, 0.5)
	plate.Size = UDim2.new(1, -4, 1, -4)
	plate.BackgroundColor3 = PLATE_COLOUR
	plate.BackgroundTransparency = 0.12
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.22, 0)
	corner.Parent = plate
	local rim = Instance.new("UIStroke")
	rim.Color = PLATE_RIM
	rim.Thickness = 1.5
	rim.Transparency = 0.35
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = plate
	local function holder(name: string): Frame
		local f = Instance.new("Frame")
		f.Name = name
		f.BackgroundTransparency = 1
		f.Size = UDim2.fromScale(1, 1)
		f.Parent = plate
		return f
	end
	local seconds = holder("Seconds")
	local set = LedReadout.row(seconds, LOOK, 0.66, 0.07, 2)
	local floors = holder("Floors")
	floors.Visible = false
	local setFloor = LedReadout.row(floors, FLOOR_LOOK, 0.66, 0.07, 2)
	plate.Parent = clock
	clock.Parent = bar
	bar.Parent = parent

	-- the headline, over the whole screen
	local screen = Instance.new("ScreenGui")
	screen.Name = "Departure"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 20
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local headline = Instance.new("TextLabel")
	headline.Name = "Headline"
	headline.AnchorPoint = Vector2.new(0.5, 0.5)
	headline.Position = UDim2.fromScale(0.5, 0.32)
	headline.Size = UDim2.new(0.9, 0, 0, HEADLINE_SIZE + 12)
	headline.BackgroundTransparency = 1
	headline.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	headline.TextSize = HEADLINE_SIZE
	headline.TextTransparency = 1
	headline.Text = ""
	headline.ZIndex = 2
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = headline
	local headlineScale = Instance.new("UIScale")
	headlineScale.Parent = headline
	headline.Parent = screen
	screen.Parent = parent

	return {
		place = place,
		clock = clock,
		scale = scale,
		set = set,
		seconds = seconds,
		floors = floors,
		setFloor = setFloor,
		headline = headline,
		headlineStroke = stroke,
		headlineScale = headlineScale,
	}
end

local GateClock = {}

function GateClock.new(): Brix.System
	local clocks: { [Model]: Clock } = {}
	local running: { [Clock]: true } = {} -- clocks set, until their gate has shut
	local connections: { RBXScriptConnection } = {}
	local ui: Ui? = nil
	local chime: Sound? = nil
	local bell: Sound? = nil
	local heart: Sound? = nil
	local tweens: { [Instance]: Tween } = {}

	local showing: Clock? = nil -- the clock on screen
	local lastShown = -1 -- the seconds it showed last frame
	local ride: number? = nil -- server time the car left with this player aboard
	local rideFrom, rideTo = 0, 0 -- its floors, once known (0: not yet)
	local floorShown = 0 -- the floor on the plate, 0 while it shows the clock
	local headlineToken = 0

	local function tween(inst: Instance, info: TweenInfo, goal: { [string]: any }): Tween
		-- any: TweenService takes any property table
		local active = tweens[inst]
		if active then
			active:Cancel()
		end
		local t = TweenService:Create(inst, info, goal)
		tweens[inst] = t
		t:Play()
		return t
	end

	-- Plays `s` (cut to `row`'s stretch) at `pitch`, fading out over its end.
	local function play(s: Sound?, row: Departure.Recording, pitch: number)
		if not s then
			return
		end
		s.PlaybackSpeed = pitch
		s.Volume = row.Volume
		s.TimePosition = row.Start
		s:Play()
		if row.Fade > 0 then
			local length = row.Stop - row.Start
			tween(
				s,
				TweenInfo.new(
					row.Fade / pitch,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In,
					0,
					false,
					math.max(length - row.Fade, 0) / pitch
				),
				{ Volume = 0 }
			)
		end
	end

	local function headline(text: string, colour: Color3)
		local u = ui
		if not u then
			return
		end
		headlineToken += 1
		local token = headlineToken
		local label = u.headline
		label.Text = text
		label.TextColor3 = colour
		u.headlineScale.Scale = 0.8
		tween(label, HEADLINE_IN, { TextTransparency = 0 })
		tween(u.headlineStroke, HEADLINE_IN, { Transparency = 0.45 })
		tween(u.headlineScale, HEADLINE_IN, { Scale = 1 })
		task.delay(HEADLINE_IN.Time + HEADLINE_HOLD, function()
			if headlineToken ~= token then
				return
			end
			tween(label, HEADLINE_OUT, { TextTransparency = 1 })
			tween(u.headlineStroke, HEADLINE_OUT, { Transparency = 1 })
		end)
	end

	local function draw(left: number)
		local u = ui
		if not u then
			return
		end
		local text = Departure.text(left)
		local phase = Departure.phase(left)
		local tone: Readout.Tone = if phase == "Counting" then "Right" else "Lit"
		for i = 1, 2 do
			local char = string.sub(text, i, i)
			u.set(i, char, if char == " " then "Off" else tone)
		end
	end

	local function show(clock: Clock, left: number)
		local u = ui
		if not u then
			return
		end
		showing = clock
		lastShown = Departure.shown(left)
		draw(left)
		u.seconds.Visible, u.floors.Visible = true, false
		u.clock.Visible = true
		u.scale.Scale = POP_FROM
		tween(u.clock, POP, { GroupTransparency = 0 })
		tween(u.scale, POP, { Scale = 1 })
		if Departure.Seconds - left <= CHIME_LATE then
			play(chime, Departure.Chime, 1)
		end
	end

	local function hide()
		showing = nil
		lastShown = -1
		local u = ui
		if not u then
			return
		end
		local t = tween(u.clock, GONE, { GroupTransparency = 1 })
		t.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and showing == nil then
				u.clock.Visible = false
			end
		end)
	end

	-- The clock showed a new second: jump it in the warning, ring the bell in the last five.
	local function second(shown: number)
		local u = ui
		if not u or shown > Departure.Warning then
			return
		end
		local final = shown <= Departure.Final and shown >= 1
		u.scale.Scale = if final then JUMP_FINAL else JUMP
		tween(u.scale, JUMP_BACK, { Scale = 1 })
		if final then
			play(bell, Departure.Bell, Departure.bellPitch(shown))
		end
	end

	local function setHeart(left: number?)
		local s = heart
		if not s then
			return
		end
		local volume: number?, pace: number = nil, 1
		if left then
			volume, pace = Departure.heart(left)
		end
		if volume then
			s.Volume = volume * Departure.Heart.Volume
			s.PlaybackSpeed = pace
			if not s.IsPlaying then
				s.TimePosition = Departure.Heart.Start
				s:Play()
			end
		elseif s.IsPlaying then
			s:Stop()
		end
	end

	-- The ride's floors, from its value on the elevator (written just before who rode).
	local function rideFloors(clock: Clock)
		local at, from, to = Ride.decode(clock.model:GetAttribute(Ride.Attribute))
		local r = ride
		if at and r and math.abs(at - r) < 1e-3 then
			rideFrom, rideTo = from, to
		end
	end

	-- The car left: aboard, the ride begins; on the floor and not aboard, you were left.
	local function leaving(clock: Clock)
		local at, ids = Departure.decodeAboard(clock.model:GetAttribute(Departure.AboardAttribute))
		if not at or now() - at > STALE then
			return
		end
		local r = ride
		if r and math.abs(at - r) < 1e-3 then
			return -- the same ride, taken over by the next floor's car (L-08b): nothing new
		end
		if table.find(ids, Players.LocalPlayer.UserId) then
			ride, rideFrom, rideTo, floorShown = at, 0, 0, 0
			rideFloors(clock)
			headline("Going up", WARM)
		elseif onFloor(clock.model) then
			headline("Left behind", COLD)
		end
	end

	-- The plate while you ride, `since` seconds after the gate hit its post: the clock's 0 a
	-- moment, then the floor you left in amber with a pop, the next with a jump as the brakes
	-- bite, and gone once the gate is opening on it.
	local function floorStep(since: number)
		local u = ui
		if not u then
			return
		end
		if since > Ride.opens() + FLOOR_HOLD then
			ride, floorShown = nil, 0
			hide()
			return
		end
		if since < FLOOR_AFTER or rideFrom <= 0 then
			return
		end
		local n = Ride.shown(since, rideFrom, rideTo)
		if n == floorShown then
			return
		end
		local text = Ride.text(n)
		for i = 1, 2 do
			local char = string.sub(text, i, i)
			u.setFloor(i, char, if char == " " then "Off" else "Lit")
		end
		if floorShown == 0 then
			-- the clock's plate becomes the floor counter
			u.seconds.Visible, u.floors.Visible = false, true
			u.clock.Visible = true
			u.scale.Scale = POP_FROM
			tween(u.clock, POP, { GroupTransparency = 0 })
			tween(u.scale, POP, { Scale = 1 })
		else
			u.scale.Scale = JUMP_FINAL
			tween(u.scale, JUMP_BACK, { Scale = 1 })
		end
		floorShown = n
	end

	local function clockChanged(clock: Clock)
		local departs = clock.model:GetAttribute(Departure.Attribute)
		clock.departs = if type(departs) == "number" then departs else nil
		if clock.departs then
			running[clock] = true
		else
			running[clock] = nil
		end
	end

	local function remove(inst: Instance)
		local clock = clocks[inst :: Model]
		if not clock then
			return
		end
		clocks[inst :: Model] = nil
		running[clock] = nil
		for _, c in clock.conns do
			c:Disconnect()
		end
		if showing == clock then
			hide()
		end
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or clocks[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local clock: Clock = { model = inst, departs = nil, conns = {} }
		clocks[inst] = clock
		table.insert(
			clock.conns,
			inst:GetAttributeChangedSignal(Departure.Attribute):Connect(function()
				clockChanged(clock)
			end)
		)
		table.insert(
			clock.conns,
			inst:GetAttributeChangedSignal(Departure.AboardAttribute):Connect(function()
				leaving(clock)
			end)
		)
		table.insert(
			clock.conns,
			inst:GetAttributeChangedSignal(Ride.Attribute):Connect(function()
				rideFloors(clock)
			end)
		)
		clockChanged(clock)
	end

	local system: Brix.System = {
		name = "GateClock",
		start = function(_: any, _context: Brix.Context)
			local u = build()
			ui = u
			table.insert(
				connections,
				GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(u.place)
			)
			local camera = Workspace.CurrentCamera
			if camera then
				table.insert(
					connections,
					camera:GetPropertyChangedSignal("ViewportSize"):Connect(u.place)
				)
			end
			chime = sound("PaChime", Departure.Chime)
			bell = sound("PaBell", Departure.Bell)
			local h = sound("Heartbeat", Departure.Heart)
			h.Looped = true
			heart = h
			task.spawn(
				SoundPrimer.prime,
				{ Departure.Chime.Id, Departure.Bell.Id, Departure.Heart.Id }
			)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(add)
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
			if next(running) == nil and showing == nil and ride == nil then
				return
			end
			local t = now()
			local r = ride
			if r then
				-- riding: the clock is done, and the plate counts floors
				for clock in running do
					if Departure.phase((clock.departs :: number) - t) == "Gone" then
						running[clock] = nil
					end
				end
				showing, lastShown = nil, -1
				setHeart(nil)
				floorStep(RideClock(r, t))
				return
			end
			-- the clock this player is under: a running one whose floor they're on
			local under: Clock? = nil
			local underLeft = 0
			for clock in running do
				local left = (clock.departs :: number) - t
				local phase = Departure.phase(left)
				if phase == "Gone" then
					running[clock] = nil
				elseif phase ~= "Folding" and onFloor(clock.model) then
					under, underLeft = clock, left
				end
			end
			if under ~= showing then
				if showing then
					hide()
				end
				if under then
					show(under, underLeft)
				end
			end
			if under then
				draw(underLeft)
				local shown = Departure.shown(underLeft)
				if shown ~= lastShown then
					lastShown = shown
					second(shown)
				end
			end
			setHeart(if under then underLeft else nil)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in clocks do
				remove(model)
			end
			for _, t in tweens do
				t:Cancel()
			end
			table.clear(tweens)
			setHeart(nil)
		end,
	}
	return system
end

return GateClock
