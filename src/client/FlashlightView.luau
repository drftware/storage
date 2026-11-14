--!strict
--[[
	Client system: the flashlights on this screen (L-11a, D-047).

	Yours: held low on the right of your first-person view (`Torch.Hold`), swaying as you walk,
	trailing a hard turn and dipping as your thumb clicks it, its beam leaving its lens. It's drawn
	small and near your eye so it never pokes through a wall, a door or the steel, pulling back and
	ducking out of view with your nose to one; the beam still leaves where the full-size lens would
	be, but never from past a surface (`Hands`, D-060). A right
	click, a gamepad's R1 or the round button above the phone's jump button switches it: the click,
	the lens and the beam answer at once on your screen, and the server is told the state you want
	(it decides for everyone else). While it's on, where you look (its pitch and heading) goes to
	the server a few times a second, so friends see your torch point where you look and keepers
	that freeze in light are tested along it; a big swing goes sooner, and the moment your screen
	sees your beam land on a keeper (`Beam.landed`, from KeeperView), at once (L-06b4b3).

	Friends': the server's torch in their right hand (`Flashlights`), its lens lit and its beam
	drawn here from the `On` attribute, their arm raised to their `Aim` (each screen poses other
	players' shoulders after their animation, so the beam points where they look), the click heard
	near them. Only the nearest few cast real light (`Torch.budget`): the rest show their lit lens.
	A friend's beam never starts past a surface either: lying on the steel or pressed to a door,
	their torch doesn't light the unit behind it.

	It runs down (S1-09, D-142): the server says what's left in whole seconds on each Player
	(`Charge.Attribute`); this screen follows it smoothly between ticks. A ring of ticks round the
	button shows yours, going out one by one, red for the last half minute. Then the beam
	flickers (`Charge.glow`): a long stutter first, then quick ones far apart, closing in and going
	darker as the light sags and browns, the filament buzzing in your hand while it stutters, until
	it browns out to nothing and clicks off by itself. A friend's dying torch flickers and buzzes on
	your screen the same way. Pressed while it's dead, the button only clicks dully, the torch dips
	in your hand and the button shakes: nothing explains it.
]]
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Charge = require(ReplicatedStorage.Shared.Flashlight.Charge)
local Flashlight = require(ReplicatedStorage.Shared.Flashlight)
local HandRoom = require(script.Parent.HandRoom)
local InFlight = require(script.Parent.InFlight)
local Hands = require(ReplicatedStorage.Shared.Hands)
local Joints = require(script.Parent.Joints)
local Kept = require(ReplicatedStorage.Shared.Kept)
local SoundPrimer = require(script.Parent.SoundPrimer)

local Torch = Flashlight.Torch
local Specs = Flashlight.Specs

local player = Players.LocalPlayer

local RENDER = "FlashlightHold"
-- On the camera while a catch's lunge has your view (CaughtLunge): your torch is put out of
-- sight, so nothing sits between you and its face. Its light is left as it was.
local SEIZED = "CaughtSeized"
local ACTION = "Flashlight"
-- The phone's button: about three quarters of the jump button, a thumb's width above it.
local BUTTON_OF_JUMP = 0.74
local BUTTON_MIN, BUTTON_MAX = 52, 92 -- pixels
local BUTTON_GAP = 0.18 -- of the button, between it and the jump button
local INK = Color3.fromRGB(232, 226, 214) -- the hints' warm off-white
local WARM = Color3.fromRGB(255, 214, 140) -- the glyph lit
local COLD = Color3.fromRGB(255, 96, 84) -- the ring's last ticks, dying (the tools' warning red)
-- On a keyboard or a gamepad, where there's no jump button: the button in the screen's bottom
-- right corner, the ring on it showing what's left (a click on it switches it too).
local DESK_OF_HEIGHT = 0.1 -- of the screen's height
local DESK_MIN, DESK_MAX = 48, 80 -- pixels
local DESK_MARGIN = 0.35 -- of the button, from the screen's edges
-- The ring: ticks round the button's inside edge, like a clock face.
local RING = 0.41 -- the ticks' middles, from the button's middle (of its size)
local TICK_WIDE, TICK_LONG = 0.055, 0.12 -- of the button's size
local TICK_LIT = 0.08 -- a lit tick's transparency
local TICK_DARK = 0.8 -- a spent tick: a faint ghost, so the ring's whole shape still shows
local TICK_FADE = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TICK_SWEEP = 0.035 -- seconds between ticks lighting as it's filled: the ring sweeps round
local WARN_PULSE = 5 -- the red ticks' breath (radians a second)
local WARN_FADE = 0.55 -- how far they fade at the bottom of each breath
local GLOW_MOST = 0.28 -- the glow behind the glyph at full light (1 - its transparency)
local DULL = 0.6 -- the glyph's transparency while it's dead
local SHAKE = { -10, 8, -6, 4, -2, 0 } -- degrees the button wobbles, a frame or two each
local PRESS = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local GLOW = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BUDGET_EVERY = 0.25 -- seconds between choosing which friends' beams are real
local RAD = math.pi / 180

-- your torch drawn small and near (`Hands`): its parts from the grip, and its box's half size
local SCALE = Hands.Scale
local BODY_OFF = CFrame.new(Specs.Body.Centre * SCALE)
local LENS_OFF = CFrame.new(Specs.Lens.Centre * SCALE)
local BODY_HALF = Specs.Body.Size * (SCALE / 2)
-- where the beam leaves the full-size lens, from the grip (as `Flashlight`'s rig puts it), and the
-- drawn lens's face
local BEAM_OFF = CFrame.new(Specs.LensFront + Vector3.new(0, 0, -0.04))
local LENS_FRONT = CFrame.new(Specs.LensFront * SCALE)
local HOLD = Vector3.new(Torch.Hold[1], Torch.Hold[2], Torch.Hold[3])
local HOLD_TURN = Vector3.new(Torch.HoldTurn[1], Torch.HoldTurn[2], Torch.HoldTurn[3]) * RAD

type Click = { on: Sound, off: Sound }

-- A friend's torch as this screen draws it.
type Friend = {
	rig: Flashlight.Rig,
	on: boolean,
	pitch: number, -- shown, following their aim
	raise: number, -- how far their arm is up, 0 to 1
	click: Click?,
	shoulder: Joints.Joint?,
	elbow: Joints.Joint?,
	wrist: Joints.Joint?,
	head: BasePart?,
	beamAt: Attachment?, -- the beam's mount, moved short of a surface
	beamHome: CFrame, -- the mount's place on the torch
	skip: RaycastParams, -- their own body, for the beam's check
	owner: Player,
	left: number, -- their charge as this screen follows it
	flicker: Charge.Flicker,
	buzz: Sound?, -- made the first time their torch flickers here
}

local function clickSound(
	parent: Instance,
	which: { id: string, from: number, length: number }
): Sound
	local s = Instance.new("Sound")
	s.SoundId = which.id
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(which.from, which.from + which.length)
	s.Volume = Torch.ClickVolume
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = Torch.ClickNear
	s.RollOffMaxDistance = Torch.ClickReach
	s.Parent = parent
	return s
end

local function clicks(parent: Instance): Click
	return { on = clickSound(parent, Torch.OnSound), off = clickSound(parent, Torch.OffSound) }
end

local function play(c: Click, on: boolean)
	local s = if on then c.on else c.off
	local which = if on then Torch.OnSound else Torch.OffSound
	s.TimePosition = which.from
	s:Play()
end

type Ui = {
	gui: ScreenGui,
	button: GuiButton,
	glyph: { GuiObject },
	glow: Frame,
	press: UIScale,
	ticks: { Frame },
}

-- The phone's button: a dark round button like the jump button, with a torch drawn on it that
-- lights warm while yours is on, and the ring of ticks round its inside edge.
local function makeButton(): Ui
	local gui = Instance.new("ScreenGui")
	gui.Name = "Flashlight"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local button = Instance.new("TextButton")
	button.Name = "Switch"
	button.Text = ""
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.BackgroundColor3 = Color3.new(0, 0, 0)
	button.BackgroundTransparency = 0.5
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = INK
	stroke.Transparency = 0.55
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local scale = Instance.new("UIScale")
	scale.Parent = button
	-- the glow behind the torch while it's on
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(0.86, 0.86)
	glow.BackgroundColor3 = WARM
	glow.BackgroundTransparency = 1
	glow.Parent = button
	local gc = Instance.new("UICorner")
	gc.CornerRadius = UDim.new(0.5, 0)
	gc.Parent = glow
	-- the torch, tipped forward to the upper right: its tube, its flared head, its lens
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.52)
	holder.Size = UDim2.fromScale(0.6, 0.6)
	holder.BackgroundTransparency = 1
	holder.Rotation = 40
	holder.Parent = button
	local parts: { GuiObject } = {}
	local function piece(x: number, y: number, w: number, h: number, round: number): Frame
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(x, y)
		f.Size = UDim2.fromScale(w, h)
		f.BackgroundColor3 = INK
		f.BorderSizePixel = 0
		f.Parent = holder
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(round, 0)
		c.Parent = f
		table.insert(parts, f)
		return f
	end
	piece(0.5, 0.64, 0.26, 0.6, 0.3) -- the tube
	piece(0.5, 0.26, 0.42, 0.2, 0.2) -- the head
	local lens = piece(0.5, 0.15, 0.36, 0.06, 0.5) -- the lens's edge
	lens.BackgroundColor3 = Color3.new(0, 0, 0)
	lens.BackgroundTransparency = 0.3
	table.remove(parts) -- the lens keeps its own colour
	-- the ring: clockwise from the top, each tick along the line from the middle
	local ticks: { Frame } = {}
	for i = 1, Charge.Ticks do
		local a = (i - 0.5) / Charge.Ticks * 2 * math.pi
		local t = Instance.new("Frame")
		t.Name = `Tick{i}`
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.fromScale(0.5 + RING * math.sin(a), 0.5 - RING * math.cos(a))
		t.Size = UDim2.fromScale(TICK_WIDE, TICK_LONG)
		t.Rotation = math.deg(a)
		t.BackgroundColor3 = INK
		t.BackgroundTransparency = TICK_DARK -- the ring sweeps on as it's first shown
		t.BorderSizePixel = 0
		t.Parent = button
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = t
		table.insert(ticks, t)
	end
	return {
		gui = gui,
		button = button,
		glyph = parts,
		glow = glow,
		press = scale,
		ticks = ticks,
	}
end

-- The filament fighting, looped quietly on a torch; heard only while it stutters (`drive`).
local function buzzSound(parent: Instance): Sound
	local s = Instance.new("Sound")
	s.Name = "FlashlightBuzz"
	s.SoundId = Charge.Buzz.id
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(Charge.Buzz.from, Charge.Buzz.from + Charge.Buzz.length)
	s.LoopRegion = s.PlaybackRegion
	s.Looped = true
	s.Volume = 0
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = Charge.BuzzNear
	s.RollOffMaxDistance = Charge.BuzzReach
	s.Parent = parent
	return s
end

-- A torch's buzz this frame: running through its last half minute while it's lit, heard while it
-- stutters, loudest in the dips, retuned at each blink so it crackles.
local function drive(s: Sound, lit: boolean, stuttering: boolean, level: number, f: Charge.Flicker)
	if not lit then
		if s.IsPlaying then
			s:Stop()
		end
		return
	end
	if not s.IsPlaying then
		s.TimePosition = Charge.Buzz.from
		s:Play()
	end
	local v = if stuttering then Charge.BuzzVolume * (1 - 0.5 * level) else 0
	if math.abs(s.Volume - v) > 0.02 then
		s.Volume = v
	end
	if stuttering then
		local pitch = Charge.buzzPitch(f)
		if s.PlaybackSpeed ~= pitch then
			s.PlaybackSpeed = pitch
		end
	end
end

-- Seconds of light in a full torch on this screen: five minutes, or Studio's dev number.
local function fullCharge(): number
	return Charge.full(if RunService:IsStudio() then Workspace:GetAttribute(Charge.Dev) else nil)
end

local FlashlightView = {}

-- Your torch as other systems on this screen see it.
export type Beam = {
	on: () -> boolean, -- whether it's on, on your screen
	landed: () -> (), -- your screen saw your beam land on a keeper: send where you look at once
	light: () -> number, -- the light it gives this frame, 0 to 1 (it flickers and sags dying)
}

-- The system, and your torch for KeeperView and FaintMarkView.
function FlashlightView.new(): (Brix.System, Beam)
	local connections: { RBXScriptConnection } = {}
	local own: Flashlight.Rig? = nil
	local ownBeam: Attachment? = nil
	local ownPull = 0 -- how far your torch is pulled back from a wall, studs
	local ownClick: Click? = nil
	local sway = Torch.sway()
	local pose = Torch.pose()
	local mine = false -- what your torch is, on your screen
	local lastSwitch: number? = nil
	local burst = Torch.Burst
	local sentAt = -math.huge -- when the state was last sent
	local aimSent: number? = nil -- the pitch last sent (whole degrees), nil since it went on
	local headingSent = 0 -- and the heading
	local aimAt = -math.huge
	local soon = false -- your beam landed on a keeper since the last send
	local lastYaw: number?, lastPitch = nil, 0
	local friends: { [Model]: Friend } = {}
	local order: { Friend } = {}
	local distances: { number } = {}
	local real: { boolean } = {}
	local budgetIn = 0
	local switchRemote: RemoteEvent? = nil
	local aimRemote: UnreliableRemoteEvent? = nil
	local ui: Ui? = nil
	local jump: GuiObject? = nil
	local findJumpIn = 0
	-- your torch's charge: what the server last wrote, and this screen's reckoning between ticks
	local written = Charge.Full
	local left = Charge.Full
	local flicker = Charge.flicker(player.UserId % 100000 + 17)
	local level = 1 -- the light your torch gave last frame (the button's glow follows it)
	local buzz: Sound? = nil
	local deadClick: Sound? = nil
	local refuseClick: Sound? = nil
	local litShown = -1 -- the ring as drawn: lit ticks, and whether they're the red ones
	local warnShown = false
	local deadShown = false
	local clock = 0
	local shaking = 0

	local function alive(): boolean
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.Health > 0
	end

	local function showButton()
		local u = ui
		if not u then
			return
		end
		TweenService
			:Create(u.glow, GLOW, { BackgroundTransparency = if mine then 1 - GLOW_MOST else 1 })
			:Play()
		local dead = left <= 0
		for _, p in u.glyph do
			TweenService:Create(p, GLOW, {
				BackgroundColor3 = if mine then WARM else INK,
				BackgroundTransparency = if dead then DULL else 0,
			}):Play()
		end
		deadShown = dead
	end

	-- The ring: what's left lit, the rest a faint ghost; red and breathing for the last half
	-- minute. A fill sweeps round lighting them; a drain lets each go softly.
	local function drawRing(dt: number)
		local u = ui
		if not u then
			return
		end
		clock += dt
		local lit = Charge.lit(left, fullCharge())
		local warn = Charge.flickering(left)
		if lit ~= litShown or warn ~= warnShown then
			-- only the ticks that change: a red one's breath is written below, never tweened
			local from = math.max(litShown, 0)
			for i, t in u.ticks do
				local was, on = i <= litShown, i <= lit
				local wasRed, red = was and warnShown, on and warn
				if red and not wasRed then
					t.BackgroundColor3 = COLD
				elseif on and not red and (not was or wasRed) then
					local delay = if was then 0 else (i - from) * TICK_SWEEP
					TweenService:Create(
						t,
						TweenInfo.new(
							0.25,
							Enum.EasingStyle.Quad,
							Enum.EasingDirection.Out,
							0,
							false,
							delay
						),
						{ BackgroundColor3 = INK, BackgroundTransparency = TICK_LIT }
					):Play()
				elseif was and not on then
					TweenService:Create(
						t,
						TICK_FADE,
						{ BackgroundColor3 = INK, BackgroundTransparency = TICK_DARK }
					):Play()
				end
			end
			litShown, warnShown = lit, warn
		end
		if warn and lit > 0 then
			-- the red ones breathe, the last the deepest
			local breath = 0.5 - 0.5 * math.cos(clock * WARN_PULSE)
			for i = 1, lit do
				u.ticks[i].BackgroundTransparency = TICK_LIT + WARN_FADE * breath * (i / lit)
			end
		end
		if (left <= 0) ~= deadShown then
			showButton()
		end
	end

	local function send()
		local r = switchRemote
		if r then
			r:FireServer(mine)
			sentAt = os.clock()
		end
	end

	-- A press on a dead torch: the button only clicks dully, the torch dips in your hand under
	-- your thumb, and the button wobbles. Nothing lights.
	local function refuse()
		Torch.click(sway)
		local c = refuseClick
		if c then
			c.TimePosition = Torch.OffSound.from
			c:Play()
		end
		local u = ui
		if not u then
			return
		end
		shaking += 1
		local me = shaking
		local b = u.button
		task.spawn(function()
			for _, deg in SHAKE do
				if shaking ~= me then
					return
				end
				b.Rotation = deg
				task.wait(0.03)
			end
		end)
	end

	-- Your thumb on the button.
	local function switch()
		if not alive() then
			return
		end
		if not mine and left <= 0 then
			refuse()
			return
		end
		local t = os.clock()
		local may, spare = Torch.allow(lastSwitch, burst, t)
		if not may then
			return
		end
		lastSwitch, burst = t, spare
		mine = not mine
		Torch.click(sway)
		if mine then
			Charge.rewind(flicker) -- a dying torch sputters as it catches
		end
		if own then
			Flashlight.light(own, mine, true)
		end
		if ownClick then
			play(ownClick, mine)
		end
		local u = ui
		if u then
			u.press.Scale = 0.86
			TweenService:Create(u.press, PRESS, { Scale = 1 }):Play()
		end
		showButton()
		aimSent = nil
		send()
	end

	-- Your torch dies in your hand: it has already browned out to nothing, so it only clicks off
	-- by itself, duller than your thumb's click.
	local function dies()
		mine = false
		level = 0
		if own then
			Flashlight.light(own, false, true)
		end
		local c = deadClick
		if c then
			c.TimePosition = Torch.OffSound.from
			c:Play()
		end
		local b = buzz
		if b and b.IsPlaying then
			b:Stop()
		end
		showButton()
		send()
	end

	-- Each frame your torch is lit: the light it gives as it runs down, and its buzz. Dead, it
	-- goes out.
	local function runDown(dt: number)
		-- a battery bought at the car's machine fills it only once it has flown in (MachineVend)
		local goal = if InFlight.held(player, "torch") then math.min(written, left) else written
		left = Charge.follow(left, goal, dt, mine)
		if mine and left <= 0 and alive() then
			dies()
			return
		end
		local r = own
		local stuttering = false
		if mine and r then
			level, stuttering = Charge.glow(flicker, left, dt)
			Flashlight.glow(r, level, Charge.urgency(left))
			local u = ui
			if u and Charge.flickering(left) then
				u.glow.BackgroundTransparency = 1 - GLOW_MOST * level
			end
		end
		local b = buzz
		if b then
			drive(b, mine and Charge.flickering(left), stuttering, level, flicker)
		end
	end

	local function onAction(
		_: string,
		state: Enum.UserInputState,
		_input: InputObject
	): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin then
			switch()
		end
		return Enum.ContextActionResult.Pass
	end

	-- Off and back in your hand whenever you get a new character.
	local function respawned()
		mine = false
		local b = buzz
		if b and b.IsPlaying then
			b:Stop()
		end
		lastSwitch, burst = nil, Torch.Burst
		if own then
			Flashlight.light(own, false, true)
		end
		showButton()
	end

	-- The phone's button sits over the jump button, sized from it, once the touch controls exist.
	-- It goes with the jump button, and while you're kept in a unit (L-17): there the Bang button
	-- takes the jump's place, and a torch switch over it would take the odd mashed press.
	local function placeButton()
		local u = ui
		if not u then
			return
		end
		local b, g = u.button, u.gui
		local kept = player:GetAttribute(Kept.Attribute) == true
		if not UserInputService.TouchEnabled then
			-- a keyboard or gamepad: in the bottom right corner, for its ring
			local camera = Workspace.CurrentCamera
			if not camera then
				return
			end
			local size =
				math.clamp(math.round(camera.ViewportSize.Y * DESK_OF_HEIGHT), DESK_MIN, DESK_MAX)
			local margin = math.round(size * DESK_MARGIN)
			b.Size = UDim2.fromOffset(size, size)
			b.Position = UDim2.new(1, -(margin + math.round(size / 2)), 1, -margin)
			g.Enabled = alive() and not kept
			return
		end
		local j = jump
		if not j then
			return
		end
		local touch = j:FindFirstAncestorOfClass("ScreenGui")
		if touch then
			g.IgnoreGuiInset = touch.IgnoreGuiInset
			g.ScreenInsets = touch.ScreenInsets
		end
		local size =
			math.clamp(math.round(j.AbsoluteSize.X * BUTTON_OF_JUMP), BUTTON_MIN, BUTTON_MAX)
		b.Size = UDim2.fromOffset(size, size)
		local at = j.AbsolutePosition
		b.Position = UDim2.fromOffset(at.X + j.AbsoluteSize.X / 2, at.Y - size * BUTTON_GAP)
		g.Enabled = j.Visible and not kept
	end

	local function findJump()
		local pg = player:FindFirstChildOfClass("PlayerGui")
		local touch = pg and pg:FindFirstChild("TouchGui")
		local frame = touch and touch:FindFirstChild("TouchControlFrame")
		local j = frame and frame:FindFirstChild("JumpButton")
		if not (j and j:IsA("GuiObject")) or j == jump then
			return
		end
		jump = j
		for _, prop in { "AbsolutePosition", "AbsoluteSize", "Visible" } do
			table.insert(connections, j:GetPropertyChangedSignal(prop):Connect(placeButton))
		end
		placeButton()
	end

	-- Each frame, after the camera (and its shake): your torch where your hand holds it.
	local function hold(dt: number)
		runDown(dt)
		local r = own
		local camera = Workspace.CurrentCamera
		if not (r and camera) then
			return
		end
		local cam = camera.CFrame
		local pitch, yaw = cam:ToOrientation()
		local turnYaw, turnPitch = 0, 0
		if lastYaw then
			turnYaw = (yaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
			turnPitch = pitch - lastPitch
		end
		lastYaw, lastPitch = yaw, pitch
		local speed = 0
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if
			root
			and root:IsA("BasePart")
			and humanoid
			and humanoid.FloorMaterial ~= Enum.Material.Air
		then
			local v = root.AssemblyLinearVelocity
			speed = Vector3.new(v.X, 0, v.Z).Magnitude
		end
		local p = Torch.step(sway, dt, speed, turnYaw, turnPitch, pose)
		local turn = CFrame.fromEulerAnglesYXZ(
			HOLD_TURN.Y + p.pitch,
			HOLD_TURN.X + p.yaw,
			HOLD_TURN.Z + p.roll
		)
		-- where your hand holds it at full size, from your eye
		local at = HOLD + Vector3.new(p.x, p.y, p.z)
		-- drawn small and near, it looks the same; nose to a wall it pulls back and ducks
		local small = CFrame.new(at * SCALE) * turn
		local reach = HandRoom.reach(small * BODY_OFF, BODY_HALF)
		ownPull = Hands.follow(ownPull, Hands.pull(HandRoom.room(cam, reach), reach), dt)
		local grip = cam * CFrame.new(0, -Hands.Duck * ownPull, ownPull) * small
		r.body.CFrame = grip * BODY_OFF
		r.lens.CFrame = grip * LENS_OFF
		-- the beam where the full-size lens would be, so it falls as it always did; but it reaches
		-- there from the drawn lens only as far as it's clear, so it never starts past a surface
		-- (over a unit's front looking down, it still lights the hall below, not the steel)
		local beamAt = ownBeam
		if beamAt then
			local full = cam * CFrame.new(at) * turn * BEAM_OFF
			local from = (grip * LENS_FRONT).Position
			beamAt.WorldCFrame = full.Rotation + HandRoom.clear(from, full.Position)
		end
		local shown = alive()
		local t = if shown and camera:GetAttribute(SEIZED) ~= true then 0 else 1
		if r.body.LocalTransparencyModifier ~= t then
			r.body.LocalTransparencyModifier = t
			r.lens.LocalTransparencyModifier = t
			if not shown then
				Flashlight.light(r, false, true)
			end
		end
	end

	-- A friend's torch, found in their character the first time it's there.
	local function friendOf(other: Player, character: Model): Friend?
		local model = character:FindFirstChild(Torch.ModelName)
		if not (model and model:IsA("Model")) then
			return nil
		end
		local f = friends[model]
		if f then
			return f
		end
		local rig = Flashlight.rigOf(model)
		if not rig then
			return nil
		end
		local mount = rig.beam.Parent
		local beamAt = if mount and mount:IsA("Attachment") then mount else nil
		local head = character:FindFirstChild("Head")
		local made: Friend = {
			rig = rig,
			on = model:GetAttribute(Torch.OnAttribute) == true,
			pitch = 0,
			raise = 0,
			click = nil,
			shoulder = Joints.find(character, "RightUpperArm", "RightShoulder"),
			elbow = Joints.find(character, "RightLowerArm", "RightElbow"),
			wrist = Joints.find(character, "RightHand", "RightWrist"),
			head = if head and head:IsA("BasePart") then head else nil,
			beamAt = beamAt,
			beamHome = if beamAt then beamAt.CFrame else CFrame.identity,
			skip = HandRoom.skipping(character),
			owner = other,
			left = Charge.Full,
			flicker = Charge.flicker(other.UserId % 100000 + 29),
			buzz = nil,
		}
		local w = other:GetAttribute(Charge.Attribute)
		if type(w) == "number" then
			made.left = w
		end
		friends[model] = made
		return made
	end

	-- Friends' torches: lit from their state, the nearest few with real light.
	local function drawFriends(dt: number)
		table.clear(order)
		for _, other in Players:GetPlayers() do
			local character = other.Character
			if other ~= player and character then
				local f = friendOf(other, character)
				if f then
					table.insert(order, f)
				end
			end
		end
		for model in friends do
			if not model.Parent then
				friends[model] = nil
			end
		end
		budgetIn -= dt
		local camera = Workspace.CurrentCamera
		if budgetIn <= 0 and camera then
			budgetIn = BUDGET_EVERY
			table.clear(distances)
			local eye = camera.CFrame.Position
			for i, f in order do
				distances[i] = if f.on then (f.rig.body.Position - eye).Magnitude else math.huge
			end
			Torch.budget(distances, real)
		end
		for i, f in order do
			local model = f.rig.model
			local on = model:GetAttribute(Torch.OnAttribute) == true
			if on ~= f.on then
				f.on = on
				if not f.click then
					f.click = clicks(f.rig.body)
				end
				play(f.click :: Click, on)
				if on then
					budgetIn = 0 -- find it a real beam now, not in a quarter second
					Charge.rewind(f.flicker)
				end
			end
			Flashlight.light(f.rig, on, real[i] == true)
			-- their torch running down: it flickers and buzzes here as it does on their screen
			local w = f.owner:GetAttribute(Charge.Attribute)
			local goal = if type(w) == "number" then w else Charge.Full
			if InFlight.held(f.owner, "torch") then
				goal = math.min(goal, f.left) -- their bought battery is still on its way
			end
			f.left = Charge.follow(f.left, goal, dt, on)
			local dying = on and Charge.flickering(f.left)
			local k, stuttering = 1, false
			if on then
				k, stuttering = Charge.glow(f.flicker, f.left, dt)
				Flashlight.glow(f.rig, k, Charge.urgency(f.left))
			end
			if dying and not f.buzz then
				f.buzz = buzzSound(f.rig.body)
			end
			local fb = f.buzz
			if fb then
				drive(fb, dying, stuttering, k, f.flicker)
			end
			-- a real beam never starts past a surface (their lens through the steel or a door)
			local beamAt, head = f.beamAt, f.head
			if beamAt and head and on and real[i] == true then
				local want = f.rig.body.CFrame * f.beamHome
				beamAt.WorldCFrame = want.Rotation
					+ HandRoom.clear(head.Position, want.Position, f.skip)
			end
			local aim = model:GetAttribute(Torch.AimAttribute)
			local target = if type(aim) == "number" then aim else 0
			f.pitch = target + (f.pitch - target) * math.exp(-Torch.AimFollow * dt)
			local step = dt / Torch.ArmBlend
			f.raise = math.clamp(f.raise + (if on then step else -step), 0, 1)
		end
	end

	-- After other players' animations, before the frame: their right arm raised to their aim.
	local function poseArms()
		for _, f in order do
			local w = f.raise
			if w > 0 then
				local k = w * w * (3 - 2 * w)
				local s, e, wr = f.shoulder, f.elbow, f.wrist
				if s then
					Joints.bend(s, CFrame.Angles(Torch.raise(f.pitch), 0, 0), k)
				end
				if e then
					Joints.bend(e, CFrame.identity, k)
				end
				if wr then
					Joints.bend(wr, CFrame.identity, k)
				end
			end
		end
	end

	-- Your aim, a few times a second while your torch is on; and the server told again if it
	-- disagrees with you for long (a refused or lost message).
	local function report()
		local character = player.Character
		local model = character and character:FindFirstChild(Torch.ModelName)
		local now = os.clock()
		if model then
			local theirs = model:GetAttribute(Torch.OnAttribute) == true
			if theirs ~= mine and alive() and now - sentAt > Torch.Resend then
				send()
			end
		end
		local camera = Workspace.CurrentCamera
		local r = aimRemote
		if not (mine and camera and r) then
			return
		end
		local pitch = math.deg(math.asin(math.clamp(camera.CFrame.LookVector.Y, -1, 1)))
		local _, yaw = camera.CFrame:ToOrientation()
		local heading = math.deg(yaw)
		local sent = aimSent
		local moved = if sent then Torch.moved(pitch, heading, sent, headingSent) else nil
		if Torch.shouldSend(moved, now - aimAt, soon) then
			r:FireServer(pitch, heading)
			aimSent, headingSent, aimAt = math.round(pitch), math.round(heading), now
			soon = false
		end
	end

	local system = { name = "FlashlightView" }

	function system.start(_: any, _context: Brix.Context)
		SoundPrimer.prime({ Torch.OnSound.id, Torch.OffSound.id, Charge.Buzz.id })
		-- your torch in a folder of this screen's own: a light under the camera draws nothing
		local folder = Instance.new("Folder")
		folder.Name = "YourFlashlight"
		folder.Parent = Workspace
		local r = Flashlight.clone(CFrame.identity, folder, true)
		if r then
			-- drawn small and near your eye (`Hands`); its lights keep their reach
			r.model:ScaleTo(SCALE)
			local mount = r.beam.Parent
			ownBeam = if mount and mount:IsA("Attachment") then mount else nil
			own = r
			ownClick = clicks(r.body)
			buzz = buzzSound(r.body)
			local dc = clickSound(r.body, Torch.OffSound)
			dc.PlaybackSpeed = Charge.DeadSpeed
			deadClick = dc
			local no = clickSound(r.body, Torch.OffSound)
			no.PlaybackSpeed = Charge.RefuseSpeed
			no.Volume = Torch.ClickVolume * Charge.RefuseVolume
			refuseClick = no
		end
		-- what's left, as the server ticks it; your torch follows it each frame (`runDown`), after
		-- every change that came with it has landed: a battery bought at the car's machine is
		-- written with its sale, and the sale holds the fill until the battery flies in
		local function charged()
			local w = player:GetAttribute(Charge.Attribute)
			if type(w) == "number" then
				written = w
			end
		end
		charged()
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Charge.Attribute):Connect(charged)
		)
		task.spawn(function()
			local remotes = ReplicatedStorage:WaitForChild(Torch.RemoteFolder, 30)
			local s = remotes and remotes:WaitForChild(Torch.SwitchRemote, 30)
			local a = remotes and remotes:WaitForChild(Torch.AimRemote, 30)
			if s and s:IsA("RemoteEvent") then
				switchRemote = s
			end
			if a and a:IsA("UnreliableRemoteEvent") then
				aimRemote = a
			end
		end)
		local u = makeButton()
		ui = u
		table.insert(
			connections,
			u.button.InputBegan:Connect(function(input: InputObject)
				local t = input.UserInputType
				if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
					switch()
				end
			end)
		)
		u.gui.Parent = player:WaitForChild("PlayerGui")
		placeButton()
		ContextActionService:BindAction(
			ACTION,
			onAction,
			false,
			Enum.UserInputType.MouseButton2,
			Enum.KeyCode.ButtonR1
		)
		table.insert(connections, player.CharacterAdded:Connect(respawned))
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Kept.Attribute):Connect(placeButton)
		)
		RunService:BindToRenderStep(RENDER, Enum.RenderPriority.Camera.Value + 2, hold)
		table.insert(connections, RunService.PreSimulation:Connect(poseArms))
	end

	function system.step(_: any, dt: number)
		findJumpIn -= dt
		if findJumpIn <= 0 then
			findJumpIn = 1
			findJump()
			if not UserInputService.TouchEnabled then
				placeButton()
			end
		end
		drawRing(dt)
		drawFriends(dt)
		report()
	end

	function system.stop(_: any)
		RunService:UnbindFromRenderStep(RENDER)
		ContextActionService:UnbindAction(ACTION)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		if own then
			local folder = own.model.Parent
			own.model:Destroy()
			if folder then
				folder:Destroy()
			end
			own = nil
		end
		local u = ui
		if u then
			u.gui:Destroy()
			ui = nil
		end
		table.clear(friends)
		table.clear(order)
	end

	local beam: Beam = {
		on = function(): boolean
			return mine
		end,
		landed = function()
			soon = mine
		end,
		light = function(): number
			return if mine then level else 0
		end,
	}

	return system :: any, beam -- any: a plain Brix system built field by field
end

return FlashlightView
