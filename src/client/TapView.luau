--!strict
--[[
	Client system: the tap's bar on the puller's screen (S2-05; ShutTap). The moment: your thumb
	hovering while the door hangs a foot over something that might open its eyes.

	The server opens it ("Open" on Remotes.ShutTap: the unit, the pull's moment, the zone's left
	edge) as your door starts easing down over a sleeping monster. It rises in with a sharp metal
	tick (Dead by Daylight's warning tick) just under the door's Close button, where your thumb or
	eye already is, and every other button on the screen steps aside: the door's own buttons (and
	any door's close by) can't be pressed at all, so a thumb going for the bar can't land on Slam.
	The marker runs on the server's clock (`ShutTap.marker`), so it's where the server judges it,
	trailing a short glow. One tap (a click, a touch anywhere not on a button, F as the pull was,
	or a gamepad's A or B) freezes the marker with a flick. The server's answer ("Done"): a hit
	lights the zone pale green and the bar pops, then sinks away while the door settles and latches
	softly; a miss turns it red, shakes it and drops it as the door bangs. No words.

	Only stepped while the bar is up.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local ButtonView = require(script.Parent.ButtonView)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local ShutTap = require(ReplicatedStorage.Shared.StorageUnit.ShutTap)
local SoundPrimer = require(script.Parent.SoundPrimer)

-- Size, judged at phone size: big enough to read from the corner of your eye, small enough that
-- the door and the gap under it stay in view.
local BAR_WIDTH = 0.46 -- of the screen's width, held between the two below (px)
local BAR_MIN, BAR_MAX = 240, 400
local PAD = 12 -- px of room each side of the track, for the shake and the marker's ends
local HOLDER_HEIGHT = 52 -- px: the track, with the marker standing out above and below it
local TRACK_HEIGHT = 18 -- px
local MARKER_WIDTH, MARKER_HEIGHT = 4, 38 -- px
local TRAIL = 0.12 -- of the bar: the glow the marker drags behind it

-- Where it comes up: this far under the Close button's spot on screen, so the door's edge and the
-- gap under it stay in sight; kept inside the middle of the screen and clear of its edges.
local BELOW = 40 -- px
local MIDDLE_X = 0.25 -- of the screen's width: no nearer the sides than this
local TOP_Y, BOTTOM_Y = 0.42, 0.78 -- of the screen's height: between the door and the thumbs
local FALLBACK_Y = 0.64 -- where it sits when the button is off screen
local EDGE = 16 -- px kept clear at the screen's sides

-- Motion.
local RISE = 18 -- px it rises from, as it comes up
local RISE_TIME = 0.2 -- s, overshooting a touch as it lands (Back)
local FADE_IN = 0.1 -- s
local RISE_SCALE = 0.82 -- its size as it starts rising in
local FLICK = 0.06 -- s the marker takes to stretch when you tap, and again to come back
local FLICK_HEIGHT = 48 -- px
local POP = 1.1 -- the bar's size at a hit's pop
local POP_TIME = 0.08 -- s out, and the same back
local SHAKE_TIME = 0.26 -- s a miss shakes it
local SHAKE_PX = 7 -- px at its strongest
local SHAKE_SPEED = 75 -- radians a second: a hard rattle, not a sway
local SHOW_ANSWER = 0.4 -- s the answer stays before the bar goes
local OUT_TIME = 0.22 -- s it takes to go
local OUT_HIT = 8 -- px a hit sinks as it fades: settling, as the door does
local OUT_MISS = 22 -- px a miss drops as it fades: falling, as the door does
local GONE_TIME = 0.15 -- s it takes to go when the door went another way first
local GIVE_UP = 1.5 -- s past the window with no answer: the bar goes anyway

-- Door buttons this close to the pulled door (studs) hide with the bar, so F taps the bar
-- and can't open the next door along.
local NEAR = 20
local ATTR_ACTION = "DoorAction" -- a door button's action (the server's Doors.ActionAttribute)

local INK = Color3.fromRGB(232, 226, 214) -- the game's ink (ButtonView)
local BACKING = Color3.fromRGB(12, 12, 14)
local HIT_COLOR = Color3.fromRGB(150, 230, 160)
local MISS_COLOR = Color3.fromRGB(226, 70, 56) -- the game's warning red (ButtonView)
local MARKER_COLOR = Color3.fromRGB(255, 255, 255)
-- The zone's fill: nearly solid, so the target is the brightest thing in a dark hall (seen in Play:
-- at 0.3 it read as a dull grey block).
local ZONE_SEE = 0.08

local TAPS: { [Enum.KeyCode]: true } = {
	[Enum.KeyCode.F] = true,
	[Enum.KeyCode.ButtonA] = true,
	[Enum.KeyCode.ButtonB] = true,
}

local RISE_INFO = TweenInfo.new(RISE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE_INFO = TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FLICK_INFO = TweenInfo.new(FLICK, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
local POP_INFO = TweenInfo.new(POP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
local LIGHT_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local OUT_INFO = TweenInfo.new(OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local GONE_INFO = TweenInfo.new(GONE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

export type TapView = Brix.System

type Look = {
	gui: ScreenGui,
	spot: Frame, -- where the bar comes up; the bar's own Position is only its rise and fall
	bar: CanvasGroup,
	scale: UIScale,
	track: Frame,
	rim: UIStroke,
	zone: Frame,
	zoneRim: UIStroke,
	trail: Frame,
	marker: Frame,
}

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function build(): Look
	local g = Instance.new("ScreenGui")
	g.Name = "ShutTap"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 5
	g.Enabled = false
	local spot = Instance.new("Frame")
	spot.Name = "Spot"
	spot.BackgroundTransparency = 1
	spot.Size = UDim2.fromOffset(0, 0)
	spot.Parent = g
	local bar = Instance.new("CanvasGroup")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.GroupTransparency = 1
	local scale = Instance.new("UIScale")
	scale.Parent = bar
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.5)
	track.Size = UDim2.new(1, -2 * PAD, 0, TRACK_HEIGHT)
	track.BackgroundColor3 = BACKING
	track.BackgroundTransparency = 0.15
	track.BorderSizePixel = 0
	corner(track, TRACK_HEIGHT // 2)
	local rim = Instance.new("UIStroke")
	rim.Color = INK
	rim.Transparency = 0.45
	rim.Thickness = 1.5
	rim.Parent = track
	local zone = Instance.new("Frame")
	zone.Name = "Zone"
	zone.Size = UDim2.fromScale(ShutTap.ZoneWidth, 1)
	zone.BackgroundColor3 = INK
	zone.BackgroundTransparency = ZONE_SEE
	zone.BorderSizePixel = 0
	corner(zone, 3)
	local zoneRim = Instance.new("UIStroke")
	zoneRim.Color = INK
	zoneRim.Transparency = 0
	zoneRim.Thickness = 1.5
	zoneRim.Parent = zone
	zone.Parent = track
	-- the glow behind the marker: clear at its tail, brightest at the marker
	local trail = Instance.new("Frame")
	trail.Name = "Trail"
	trail.AnchorPoint = Vector2.new(1, 0.5)
	trail.Size = UDim2.fromScale(0, 1)
	trail.BackgroundColor3 = MARKER_COLOR
	trail.BorderSizePixel = 0
	trail.ZIndex = 2
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new(1, 0.55)
	fade.Parent = trail
	trail.Parent = track
	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.AnchorPoint = Vector2.new(0.5, 0.5)
	marker.Size = UDim2.fromOffset(MARKER_WIDTH, MARKER_HEIGHT)
	marker.BackgroundColor3 = MARKER_COLOR
	marker.BorderSizePixel = 0
	marker.ZIndex = 3
	corner(marker, 2)
	local edge = Instance.new("UIStroke")
	edge.Color = BACKING
	edge.Transparency = 0.2
	edge.Thickness = 1.5
	edge.Parent = marker
	marker.Parent = track
	track.Parent = bar
	bar.Parent = spot
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return {
		gui = g,
		spot = spot,
		bar = bar,
		scale = scale,
		track = track,
		rim = rim,
		zone = zone,
		zoneRim = zoneRim,
		trail = trail,
		marker = marker,
	}
end

local TapView = {}

function TapView.new(): TapView
	local connections: { RBXScriptConnection } = {}
	local remote: RemoteEvent? = nil
	local look: Look? = nil
	local tickSound: Sound? = nil
	-- the open window: its door, the pull's moment, and when (server's clock) you tapped, if you did
	local unit: Instance? = nil
	local start = 0
	local tapped: number? = nil
	local done = false -- the server has answered: no more taps
	local up = false -- the bar is on screen (rising, running, answering or going)
	local shown = 0 -- counts each bar shown, so a late hide can't take the next one down
	local shaking = 0 -- s of a miss's shake left
	local hidden: { ProximityPrompt } = {} -- the door buttons the bar hides
	local tweens: { [string]: Tween } = {}

	-- One tween at a time for each job (`key`): a new one cancels the last.
	-- any: TweenService takes a table of any properties
	local function tween(
		key: string,
		inst: Instance,
		info: TweenInfo,
		goal: { [string]: any }
	): Tween
		local last = tweens[key]
		if last then
			last:Cancel()
		end
		local t = TweenService:Create(inst, info, goal)
		tweens[key] = t
		t:Play()
		return t
	end

	local function showButtons()
		for _, p in hidden do
			ButtonView.hide(p, "Tap", false)
		end
		table.clear(hidden)
		ButtonView.aside("Tap", false)
	end

	-- The pulled door's buttons and any door's close by: no key presses them, nothing draws them.
	-- Every other button steps aside. Returns the pulled door's Close button, if it has one.
	local function hideButtons(u: Instance): ProximityPrompt?
		showButtons()
		ButtonView.aside("Tap", true)
		local root = if u:IsA("Model") then u.PrimaryPart else nil
		local close: ProximityPrompt? = nil
		for _, p in CollectionService:GetTagged(Door.ButtonTag) do
			local a = p.Parent
			if p:IsA("ProximityPrompt") and a and a:IsA("Attachment") then
				local mine = p:IsDescendantOf(u)
				if mine or (root and (a.WorldPosition - root.Position).Magnitude < NEAR) then
					ButtonView.hide(p, "Tap", true)
					table.insert(hidden, p)
				end
				if mine and p:GetAttribute(ATTR_ACTION) == "Close" then
					close = p
				end
			end
		end
		return close
	end

	-- Where the bar comes up (px): just under the Close button you pressed, kept in the middle.
	local function placeFor(close: ProximityPrompt?, width: number): Vector2
		local camera = Workspace.CurrentCamera
		local size = camera.ViewportSize
		local fallback = Vector2.new(size.X / 2, size.Y * FALLBACK_Y)
		local a = close and close.Parent
		if not (a and a:IsA("Attachment")) then
			return fallback
		end
		local p, onScreen = camera:WorldToViewportPoint(a.WorldPosition)
		if not onScreen then
			return fallback
		end
		local left = math.max(width / 2 + EDGE, size.X * MIDDLE_X)
		local right = math.min(size.X - width / 2 - EDGE, size.X * (1 - MIDDLE_X))
		local x = if left <= right then math.clamp(p.X, left, right) else size.X / 2
		return Vector2.new(x, math.clamp(p.Y + BELOW, size.Y * TOP_Y, size.Y * BOTTOM_Y))
	end

	-- Takes the bar off the screen at once and gives the buttons back.
	local function hide()
		unit, tapped, done, up, shaking = nil, nil, false, false, 0
		showButtons()
		local l = look
		if l then
			l.gui.Enabled = false
		end
	end

	-- The bar goes: sinking (a hit), dropping (a miss) or quickly (gone), unless another has come up.
	local function goOut(info: TweenInfo, fall: number)
		local l = look
		if not l then
			return
		end
		local which = shown
		done = true
		local rise = tweens.rise
		if rise then
			rise:Cancel()
		end
		tween("scale", l.scale, info, { Scale = 0.94 })
		tween("fade", l.bar, info, { GroupTransparency = 1, Position = UDim2.fromOffset(0, fall) }).Completed:Once(
			function(state: Enum.PlaybackState)
				if state == Enum.PlaybackState.Completed and shown == which then
					hide()
				end
			end
		)
	end

	local function opened(u: Instance, at: number, zone: number)
		local l = look
		if not l then
			return
		end
		shown += 1
		unit, start, tapped, done, up, shaking = u, at, nil, false, true, 0
		local width =
			math.clamp(Workspace.CurrentCamera.ViewportSize.X * BAR_WIDTH, BAR_MIN, BAR_MAX)
		local spot = placeFor(hideButtons(u), width)
		l.spot.Position = UDim2.fromOffset(spot.X, spot.Y)
		l.bar.Size = UDim2.fromOffset(width, HOLDER_HEIGHT)
		l.bar.Position = UDim2.fromOffset(0, RISE)
		l.bar.GroupTransparency = 1
		l.scale.Scale = RISE_SCALE
		l.track.Position = UDim2.fromScale(0.5, 0.5)
		l.zone.Position = UDim2.fromScale(zone, 0)
		l.zone.BackgroundColor3 = INK
		l.zone.BackgroundTransparency = ZONE_SEE
		l.zoneRim.Color = INK
		l.rim.Color = INK
		l.rim.Transparency = 0.45
		l.marker.BackgroundColor3 = MARKER_COLOR
		l.marker.Size = UDim2.fromOffset(MARKER_WIDTH, MARKER_HEIGHT)
		l.marker.Position = UDim2.fromScale(0, 0.5)
		l.trail.Position = UDim2.fromScale(0, 0.5)
		l.trail.Size = UDim2.fromScale(0, 1)
		l.gui.Enabled = true
		tween("rise", l.bar, RISE_INFO, { Position = UDim2.fromOffset(0, 0) })
		tween("fade", l.bar, FADE_INFO, { GroupTransparency = 0 })
		tween("scale", l.scale, RISE_INFO, { Scale = 1 })
		local s = tickSound
		if s then
			s.TimePosition = 0
			s:Play()
		end
		local which = shown
		task.delay(ShutTap.Window + ShutTap.MaxLag + GIVE_UP, function()
			if shown == which and up and not done then
				goOut(GONE_INFO, 0)
			end
		end)
	end

	local function answered(u: Instance, hit: boolean)
		local l = look
		if u ~= unit or done or not l then
			return
		end
		done = true
		local color = if hit then HIT_COLOR else MISS_COLOR
		tween("zone", l.zone, LIGHT_INFO, { BackgroundColor3 = color, BackgroundTransparency = 0 })
		tween("zoneRim", l.zoneRim, LIGHT_INFO, { Color = color })
		tween("rim", l.rim, LIGHT_INFO, { Color = color, Transparency = 0.1 })
		if hit then
			tween("scale", l.scale, POP_INFO, { Scale = POP })
		else
			l.marker.BackgroundColor3 = MISS_COLOR
			shaking = SHAKE_TIME
		end
		local which = shown
		task.delay(SHOW_ANSWER, function()
			if shown == which then
				goOut(OUT_INFO, if hit then OUT_HIT else OUT_MISS)
			end
		end)
	end

	local function tap()
		local r, u, l = remote, unit, look
		if not (r and u and l) or tapped or done then
			return
		end
		local t = Workspace:GetServerTimeNow()
		tapped = t
		r:FireServer(u, t)
		-- the marker stops dead with a flick: you see where it stopped before the answer comes
		tween(
			"marker",
			l.marker,
			FLICK_INFO,
			{ Size = UDim2.fromOffset(MARKER_WIDTH + 2, FLICK_HEIGHT) }
		)
	end

	local system = { name = "TapView" }

	function system.start(_: any, _context: Brix.Context)
		look = build()
		local s = Instance.new("Sound")
		s.Name = "ShutTapTick"
		s.SoundId = ShutTap.TickSound
		s.Volume = ShutTap.TickVolume
		s.PlaybackSpeed = ShutTap.TickPitch
		s.Parent = SoundService
		tickSound = s
		-- made once and replayed: a Sound made and played at once starts late (STUDIO.md)
		task.spawn(SoundPrimer.prime, { ShutTap.TickSound })
		local folder = ReplicatedStorage:WaitForChild(ShutTap.RemoteFolder)
		local r = folder:WaitForChild(ShutTap.Remote) :: RemoteEvent
		remote = r
		table.insert(
			connections,
			-- unknown: whatever the server's message carries, checked before use
			r.OnClientEvent:Connect(function(what: unknown, u: unknown, a: unknown, b2: unknown)
				if typeof(u) ~= "Instance" then
					return
				end
				if what == "Open" and type(a) == "number" and type(b2) == "number" then
					opened(u, a, b2)
				elseif what == "Done" and type(a) == "boolean" then
					answered(u, a)
				elseif what == "Gone" and u == unit and not done then
					goOut(GONE_INFO, 0)
				end
			end)
		)
		table.insert(
			connections,
			UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
				if not unit or processed then
					return
				end
				local t = input.UserInputType
				if
					t == Enum.UserInputType.MouseButton1
					or t == Enum.UserInputType.Touch
					or TAPS[input.KeyCode]
				then
					tap()
				end
			end)
		)
	end

	-- Only while the bar is up: the marker where the server's clock says, frozen once you tap, and a
	-- miss's shake.
	function system.step(_: any, dt: number)
		local l = look
		if not up or not l then
			return
		end
		if unit then
			local at = tapped or Workspace:GetServerTimeNow()
			local x = ShutTap.marker(at - start)
			l.marker.Position = UDim2.fromScale(x, 0.5)
			l.trail.Position = l.marker.Position
			l.trail.Size = UDim2.fromScale(if tapped then 0 else math.min(x, TRAIL), 1)
		end
		if shaking > 0 then
			shaking = math.max(shaking - dt, 0)
			local strength = shaking / SHAKE_TIME
			l.track.Position =
				UDim2.new(0.5, math.sin(shaking * SHAKE_SPEED) * SHAKE_PX * strength, 0.5, 0)
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, t in tweens do
			t:Cancel()
		end
		table.clear(tweens)
		showButtons()
		local l = look
		if l then
			l.gui:Destroy()
		end
		local s = tickSound
		if s then
			s:Destroy()
		end
		look, tickSound, unit, up = nil, nil, nil, false
	end

	return system
end

return TapView
