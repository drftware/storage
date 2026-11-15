--!strict
--[[
	WatchView: left behind on your own screen (L-08c, Left). The server marks you left the instant
	the gate hits its post with you outside it, or kept (`Left.Attribute`), and from that moment:

	- The sting: the car's lamp draws away up the shaft (ElevatorView) and its motor swells and
	  fades above you, muffled by the building; your legs give up (the controls go) as "Left
	  behind" comes up over a low hit and a jolt; then the black comes down, whole before your
	  floor is cleared under you. Under the black the bell rings far above.
	- Watching: the black lifts on a friend's shoulder as their car levels on the new floor, and
	  the gate folds open without you. The camera follows them from behind, over their right
	  shoulder, smoothed so their steps and the network never shake it, pulled in short of walls;
	  drag (or hold the right mouse button, or the right stick) to swing round them. At the bottom,
	  who you're watching, the arrows to switch (Q and E, the arrow keys, the bumpers), and how
	  you get back in. A switch dips to black and lifts on the next friend once they've streamed
	  in, with a tick. In Studio a Cut Free button lets you back in (the product isn't made yet).
	- Carried up (S3-01a): a beat after the gate opens on the new floor (`Left.CarryAttribute`)
	  the view dips to black as the film squeals round you, and a roll-up door slams down in the
	  dark; the black holds until you're stood wrapped in a unit there, and CaughtView opens your
	  eyes on its dark inside.
	- Back in: the black lifts on your new character in your friends' lobby, with the film's rip
	  for Cut Free, and "Back in". The climb's end lets you go without it: the results screen is
	  where you're back (EndView).

	Your character is gone while you watch (the server), so the play HUD is gone with it; this
	frees the mouse for the buttons (FreeCursor) and turns the touch controls off.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Left = require(ReplicatedStorage.Shared.Left)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local RideClock = require(script.Parent.RideClock)
local SoundPrimer = require(script.Parent.SoundPrimer)

local STUDIO = RunService:IsStudio()
local CAMERA_STEP = "WatchCamera"
local INK = Color3.fromRGB(214, 206, 196)
local NAME_INK = Color3.fromRGB(244, 238, 230)
-- "Left behind" in a cold red; "Back in" in the car lamp's warm light, as "Going up" is (GateClock).
local COLD = Color3.fromRGB(255, 96, 84)
local WARM = Color3.fromRGB(255, 206, 150)
-- The play HUD's screens (ToolView's slots, the corner map, the gate's clock, a padlock's count),
-- hidden from the moment your legs give up until you're back in. The touch buttons that follow
-- the jump button go with your character.
local HUD = { "Slots", "Minimap", "GateClock", "PadlockLines" }
local MUTED = Color3.fromRGB(150, 144, 136)
-- Seconds "Back in" stays up once you're back, and how long the black takes to lift off you.
local BACK_HOLD = 1.6
local BACK_LIFT = 0.9
-- Seconds the sting's black takes to clear when the car comes back after all.
local CANCEL_FADE = 0.6
-- Carried up: seconds the kept mark must have been on before the black hands over to the caught
-- screen under it (CaughtView's black is up by then), and the most the black waits for it.
local CARRY_HANDOVER = 0.1
local CARRY_WAIT = 8
-- The door that slams on you in the carry's black: a roll-up door's bang and the thump under it,
-- low and close (EndView's far slams borrow the same).
local SLAM_BANG_NAME: DoorSound.SoundName = "Bang"
local SLAM_THUMP_NAME: DoorSound.SoundName = "Thump"
local SLAM_BANG = DoorSound.Sounds[SLAM_BANG_NAME]
local SLAM_THUMP = DoorSound.Sounds[SLAM_THUMP_NAME]
-- Seconds between counts of the friends you could switch to (the arrows dim with one).
local COUNT_EVERY = 0.5

local function smooth(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

type Screen = {
	dark: ScreenGui,
	black: Frame,
	title: TextLabel,
	titleStroke: UIStroke,
	titleScale: UIScale,
	edges: Frame,
	bar: ScreenGui,
	group: CanvasGroup,
	back: TextButton,
	nextButton: TextButton,
	name: TextLabel,
	namePop: UIScale,
	cutFree: TextButton?,
}

local function round(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(radius, 0)
	c.Parent = parent
end

local function text(
	parent: Instance,
	name: string,
	size: number,
	colour: Color3,
	body: string,
	bold: boolean
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.FontFace = Font.fromEnum(if bold then Enum.Font.BuilderSansBold else Enum.Font.BuilderSans)
	l.TextSize = size
	l.TextColor3 = colour
	l.Text = body
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = parent
	return l
end

local function arrow(parent: Instance, name: string, glyph: string, x: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(x, 0.5)
	b.Position = UDim2.fromScale(x, 0.5)
	b.Size = UDim2.fromOffset(52, 52)
	b.BackgroundColor3 = Color3.new(0, 0, 0)
	b.BackgroundTransparency = 0.35
	b.AutoButtonColor = false
	b.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	b.TextSize = 34
	b.TextColor3 = NAME_INK
	b.Text = glyph
	round(b, 1)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = INK
	stroke.Transparency = 0.7
	stroke.Thickness = 1.5
	stroke.Parent = b
	local pop = Instance.new("UIScale")
	pop.Parent = b
	b.Parent = parent
	return b
end

local function makeScreen(parent: Instance): Screen
	-- the black and the title: the whole screen, under the notch too
	local dark = Instance.new("ScreenGui")
	dark.Name = "LeftBehind"
	dark.ResetOnSpawn = false
	dark.IgnoreGuiInset = true
	dark.DisplayOrder = 40 -- over everything: the caught screen, the gate's fade
	dark.Enabled = false
	local black = Instance.new("Frame")
	black.Name = "Black"
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BackgroundTransparency = 1
	black.BorderSizePixel = 0
	black.Parent = dark
	-- a cutscene's bars: the top and bottom darken, over the HUD, the middle clear
	local edges = Instance.new("Frame")
	edges.Name = "Edges"
	edges.Size = UDim2.fromScale(1, 1)
	edges.BackgroundColor3 = Color3.new(0, 0, 0)
	edges.BackgroundTransparency = 1
	edges.BorderSizePixel = 0
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.24, 1),
		NumberSequenceKeypoint.new(0.72, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	fade.Parent = edges
	edges.Parent = dark
	local title = text(dark, "Title", 50, COLD, Left.Copy.Title, true)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.42)
	title.Size = UDim2.new(0.9, 0, 0, 60)
	title.TextTransparency = 1
	title.ZIndex = 2
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.new(0, 0, 0)
	titleStroke.Thickness = 2
	titleStroke.Transparency = 1
	titleStroke.Parent = title
	local titleScale = Instance.new("UIScale")
	titleScale.Parent = title
	dark.Parent = parent

	-- the watching bar: inside the phone's safe area, at the bottom where the thumbs are
	local bar = Instance.new("ScreenGui")
	bar.Name = "WatchingBar"
	bar.ResetOnSpawn = false
	bar.DisplayOrder = 41
	bar.Enabled = false
	local group = Instance.new("CanvasGroup")
	group.Name = "Bar"
	group.AnchorPoint = Vector2.new(0.5, 1)
	group.Position = UDim2.new(0.5, 0, 1, -14)
	group.Size = UDim2.new(0.94, 0, 0, 72)
	group.BackgroundTransparency = 1
	group.GroupTransparency = 1
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(440, 72)
	limit.Parent = group
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(1, -124, 1, 0)
	panel.BackgroundColor3 = Color3.new(0, 0, 0)
	panel.BackgroundTransparency = 0.45
	round(panel, 0.25)
	panel.Parent = group
	local caption = text(panel, "Caption", 12, MUTED, Left.Copy.Watching, true)
	caption.Position = UDim2.fromOffset(0, 8)
	caption.Size = UDim2.new(1, 0, 0, 14)
	local name = text(panel, "Name", 24, NAME_INK, "", true)
	name.Position = UDim2.fromOffset(8, 22)
	name.Size = UDim2.new(1, -16, 0, 26)
	local namePop = Instance.new("UIScale")
	namePop.Parent = name
	local line = text(panel, "Until", 13, INK, Left.Copy.Until, false)
	line.Position = UDim2.fromOffset(0, 49)
	line.Size = UDim2.new(1, 0, 0, 16)
	if Left.Copy.Until == "" then
		-- no line under the name (S3-01a): the caption and name sit in the panel's middle
		line.Visible = false
		caption.Position = UDim2.fromOffset(0, 15)
		name.Position = UDim2.fromOffset(8, 29)
	end
	local back = arrow(group, "Back", "‹", 0)
	local nextButton = arrow(group, "Next", "›", 1)
	group.Parent = bar
	local cutFree: TextButton? = nil
	if STUDIO then
		-- the product isn't made yet (OWNER.md): Studio lets you feel the way back in
		local b = Instance.new("TextButton")
		b.Name = "CutFree"
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.Position = UDim2.new(0.5, 0, 1, -96)
		b.Size = UDim2.fromOffset(150, 40)
		b.BackgroundColor3 = Color3.fromRGB(28, 26, 24)
		b.BackgroundTransparency = 0.2
		b.AutoButtonColor = true
		b.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		b.TextSize = 18
		b.TextColor3 = NAME_INK
		b.Text = Left.Copy.CutFree
		round(b, 0.5)
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = INK
		stroke.Transparency = 0.6
		stroke.Parent = b
		b.Parent = bar
		cutFree = b
	end
	bar.Parent = parent
	return {
		dark = dark,
		black = black,
		title = title,
		titleStroke = titleStroke,
		titleScale = titleScale,
		edges = edges,
		bar = bar,
		group = group,
		back = back,
		nextButton = nextButton,
		name = name,
		namePop = namePop,
		cutFree = cutFree,
	}
end

-- A 2D sound for one recording, in SoundService.
local function sound(name: string, id: string): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = 0
	s.Parent = SoundService
	return s
end

local WatchView = {}

-- `kick` jolts the view; `need` asks FreeCursor for the mouse while the bar is up.
function WatchView.new(
	kick: (amount: number) -> (),
	need: (who: string, on: boolean) -> ()
): Brix.System
	local player = Players.LocalPlayer
	local screen: Screen? = nil
	local connections: { RBXScriptConnection } = {}
	local sounds: { Sound } = {}
	local motor: Sound? = nil
	local dread: Sound? = nil
	local bell: Sound? = nil
	local tick: Sound? = nil
	local rip: Sound? = nil
	local squealSound: Sound? = nil
	local slamBang: Sound? = nil
	local slamThump: Sound? = nil
	local remote: RemoteEvent? = nil
	local controls: any = nil -- any: Roblox's PlayerModule ControlModule, untyped Lua
	local frozen = false
	local cursor = false
	local bound = false

	-- the sting and the watch
	local at: number? = nil -- server time the car left us
	local played: { [string]: boolean } = {}
	local watchBegan: number? = nil -- os.clock() the black began lifting on a friend
	local subject: Model? = nil -- the friend the camera follows
	local dipAt: number? = nil -- os.clock() a switch's dip began
	local landed: number? = nil -- os.clock() the dip found its friend
	local cancelAt: number? = nil -- os.clock() the sting was called off
	local cancelFrom = 0
	local shownBlack = 0
	local backAt: number? = nil -- os.clock() we were let back in
	local backWhy = ""
	local backSeen: number? = nil -- os.clock() our new character turned up
	local carryAt: number? = nil -- server time the carry's dip began (S3-01a)
	local keptSeen: number? = nil -- os.clock() the kept mark was first seen after a carry
	local friends = 0
	local counted = 0

	-- the follow camera
	local focus: Vector3? = nil
	local heading = 0
	local reach = Left.Back
	local orbitYaw, orbitPitch = 0, 0
	local stick = Vector2.zero
	local orbiting = false
	local touches: { [InputObject]: true } = {}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true

	local function setControls(on: boolean)
		if frozen == not on then
			return
		end
		frozen = not on
		if not controls then
			local scripts = player:FindFirstChild("PlayerScripts")
			local module = scripts and scripts:FindFirstChild("PlayerModule")
			if module and module:IsA("ModuleScript") then
				local ok, playerModule = pcall(require, module)
				if ok and playerModule then
					controls = (playerModule :: any):GetControls() -- any: as above
				end
			end
		end
		if controls then
			if on then
				controls:Enable()
			else
				controls:Disable()
			end
		end
	end

	local function setCursor(on: boolean)
		if cursor ~= on then
			cursor = on
			need("Watch", on)
		end
	end

	local plays: { [Sound]: number } = {} -- each sound's latest play, so an old stop can't cut it
	local function play(s: Sound?, from: number, length: number, volume: number, pitch: number)
		if not s then
			return
		end
		local n = (plays[s] or 0) + 1
		plays[s] = n
		s.TimePosition = from
		s.PlaybackSpeed = pitch
		s.Volume = volume
		s:Play()
		task.delay(length / pitch, function()
			if plays[s] == n then
				s:Stop()
			end
		end)
	end

	local function once(key: string, since: number, due: number, f: () -> ())
		if played[key] or since < due then
			return
		end
		played[key] = true
		-- a moment learned of late is skipped, not played out of time
		if since < due + 0.4 then
			f()
		end
	end

	local function ask(what: Left.Ask)
		local r = remote
		if not r then
			local folder = ReplicatedStorage:FindFirstChild(Keypad.RemoteFolder)
			local found = folder and folder:FindFirstChild(Left.Remote)
			if found and found:IsA("RemoteEvent") then
				r = found
				remote = found
			end
		end
		if r then
			r:FireServer(what)
		end
	end

	-- A press on an arrow: the tick and the button's pop now; the dip comes with the server's answer.
	local function switch(what: Left.Ask)
		local s = screen
		if not (s and watchBegan) then
			return
		end
		local row = Ride.Sounds.Tick
		play(tick, row.Start, row.Stop - row.Start, row.Volume * 1.2, 1.15)
		local button = if what == "Next" then s.nextButton else s.back
		local pop = button:FindFirstChildOfClass("UIScale")
		if pop then
			pop.Scale = 0.86
		end
		ask(what)
	end

	local function watchValue(): ObjectValue?
		local v = player:FindFirstChild(Left.WatchValue)
		return if v and v:IsA("ObjectValue") then v else nil
	end

	local function rootOf(model: Model?): BasePart?
		local root = model and model:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root else nil
	end

	-- The friend the server points us at, once their character has streamed in.
	local function targetOf(value: ObjectValue?): Model?
		local target = if value then value.Value else nil
		return if target and target:IsA("Model") and rootOf(target) then target else nil
	end

	local function nameOf(value: ObjectValue?): string
		local named = if value then value:GetAttribute(Left.NameAttribute) else nil
		return if type(named) == "string" then named else Left.Copy.Nobody
	end

	-- The camera behind `subject`'s shoulder. `snap` cuts to it.
	local function follow(dt: number, snap: boolean)
		local camera = Workspace.CurrentCamera
		local model = subject
		local root = rootOf(model)
		if not (camera and model and root) then
			return
		end
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		local head = model:FindFirstChild("Head")
		local eye = if head and head:IsA("BasePart")
			then head.Position
			else root.Position + Vector3.new(0, 1.5, 0)
		local look = root.CFrame.LookVector
		local facing = Left.heading(look.X, look.Z)
		local f = focus
		local cut = snap or f == nil or (eye - (f :: Vector3)).Magnitude > Left.Cut
		if cut then
			focus = eye
			heading = facing
		else
			focus = (f :: Vector3):Lerp(eye, Left.ease(Left.Follow, dt))
			heading = Left.turn(heading, facing, Left.Turn, dt)
		end
		orbitYaw -= stick.X * Left.OrbitStick * dt
		orbitPitch += stick.Y * Left.OrbitStick * dt
		orbitPitch = math.clamp(orbitPitch, Left.PitchLow - Left.Pitch, Left.PitchHigh - Left.Pitch)
		local turn = CFrame.fromEulerAnglesYXZ(Left.Pitch + orbitPitch, heading + orbitYaw, 0)
		local offset = turn:VectorToWorldSpace(Vector3.new(Left.Side, Left.Up, Left.Back))
		local length = offset.Magnitude
		local from = focus :: Vector3
		local hit = Workspace:Raycast(from, offset, params)
		local allowed = if hit
			then math.clamp((hit.Position - from).Magnitude - Left.Clear, Left.Near, length)
			else length
		if cut or allowed < reach then
			reach = allowed
		else
			reach += (allowed - reach) * Left.ease(Left.Ease, dt)
		end
		camera.CFrame = CFrame.new(from + offset * (reach / length)) * turn
		camera.Focus = CFrame.new(from)
	end

	-- Puts the camera on `model` from now.
	local function aim(model: Model)
		subject = model
		params.FilterDescendantsInstances = { model }
		orbitYaw, orbitPitch = 0, 0
		follow(0, true)
	end

	local function countFriends(): number
		local n = 0
		for _, other in Players:GetPlayers() do
			if
				other ~= player
				and other.Character
				and other:GetAttribute(Left.Attribute) == nil
			then
				n += 1
			end
		end
		if STUDIO then
			n += #CollectionService:GetTagged(Left.StandInTag)
		end
		return n
	end

	local function showBar(share: number, s: Screen)
		local on = share > 0.01
		s.bar.Enabled = on
		s.group.GroupTransparency = 1 - share
		setCursor(on)
	end

	-- The play HUD off while you're out of the climb, and back as it was.
	local hud: { [ScreenGui]: boolean } = {}
	local function hideHud(on: boolean)
		local gui = player:FindFirstChild("PlayerGui")
		if on and gui then
			for _, name in HUD do
				local g = gui:FindFirstChild(name)
				if g and g:IsA("ScreenGui") and hud[g] == nil then
					hud[g] = g.Enabled
					g.Enabled = false
				end
			end
		elseif not on and next(hud) ~= nil then
			for g, was in hud do
				if g.Parent then
					g.Enabled = was
				end
			end
			table.clear(hud)
		end
	end

	-- Everything off: back to playing.
	local function rest(s: Screen)
		s.dark.Enabled = false
		s.black.BackgroundTransparency = 1
		s.edges.BackgroundTransparency = 1
		s.title.Text = Left.Copy.Title
		s.title.TextColor3 = COLD
		hideHud(false)
		s.title.TextTransparency, s.titleStroke.Transparency = 1, 1
		showBar(0, s)
		if motor and motor.IsPlaying then
			motor:Stop()
		end
	end

	local function onLeft()
		local value = player:GetAttribute(Left.Attribute)
		local was = at
		at = if type(value) == "number" then value else nil
		if at and not was then
			table.clear(played)
			watchBegan, subject, dipAt, landed, cancelAt, focus = nil, nil, nil, nil, nil, nil
			carryAt, keptSeen = nil, nil
		elseif was and not at then
			-- out of the watch: the climb is over (the results are where you're back, EndView),
			-- back in (Cut Free), or the car came back after all
			local s = screen
			if Workspace:GetAttribute(ClimbEnd.Attribute) ~= nil and s then
				local camera = Workspace.CurrentCamera
				if camera then
					camera.CameraType = Enum.CameraType.Custom
				end
				watchBegan, subject, cancelAt, backAt = nil, nil, nil, nil
				rest(s)
			elseif watchBegan then
				local camera = Workspace.CurrentCamera
				if camera then
					camera.CameraType = Enum.CameraType.Custom
				end
				watchBegan, subject = nil, nil
				-- carried up: the black holds for the caught screen under it (step)
				backAt, backSeen, backWhy = os.clock(), nil, if carryAt then "Carried" else ""
			else
				cancelAt, cancelFrom = os.clock(), shownBlack
			end
			setControls(true)
			if motor and motor.IsPlaying then
				motor:Stop()
			end
		end
	end

	local function onCarry()
		local value = player:GetAttribute(Left.CarryAttribute)
		if type(value) == "number" then
			carryAt = value
		end
	end

	local function onBack()
		local _, why = Left.decodeBack(player:GetAttribute(Left.BackAttribute))
		backWhy = why
	end

	local function step(_: any, dt: number)
		local s = screen
		if not s then
			return
		end
		local clock = os.clock()
		-- carried up: the film squeals round you as the dip begins, and a door slams in the black
		local carryFrom = carryAt
		if carryFrom then
			local t = Workspace:GetServerTimeNow() - carryFrom
			once("carrySqueal", t, 0, function()
				local q = Kept.Squeal
				play(squealSound, q.from, q.length, q.volume * 0.8, q.pitch)
			end)
			once("carrySlam", t, Left.CarrySlam, function()
				local b, th = SLAM_BANG, SLAM_THUMP
				play(slamBang, b.Start, b.Stop - b.Start, 0.85, 0.82)
				play(slamThump, th.Start, th.Stop - th.Start, 1.2, 0.7)
				kick(0.3)
			end)
		end
		local bAt = backAt
		if bAt and backWhy == "Carried" then
			-- the black holds until we're kept on the new floor and the caught screen is up under it
			s.dark.Enabled = true
			s.black.BackgroundTransparency = 0
			s.title.TextTransparency, s.titleStroke.Transparency = 1, 1
			showBar(0, s)
			if player:GetAttribute(Kept.Attribute) == true then
				keptSeen = keptSeen or clock
				if clock - (keptSeen :: number) >= CARRY_HANDOVER then
					backAt, carryAt, keptSeen = nil, nil, nil
					local camera = Workspace.CurrentCamera
					local humanoid = player.Character
						and (player.Character :: Model):FindFirstChildOfClass("Humanoid")
					if camera and humanoid then
						camera.CameraSubject = humanoid
						camera.CameraType = Enum.CameraType.Custom
					end
					rest(s)
				end
			elseif clock - bAt > CARRY_WAIT then
				-- no unit for us: we stand in the lobby, and the black lifts as for a let-in
				backWhy, carryAt = "", nil
			end
			return
		end
		-- back in: the black lifts off your new character, with the rip and "Back in"
		if bAt then
			if not backSeen and player.Character then
				backSeen = clock
				local camera = Workspace.CurrentCamera
				local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid")
				if camera and humanoid then
					camera.CameraSubject = humanoid
					camera.CameraType = Enum.CameraType.Custom
				end
				if backWhy == "CutFree" then
					play(rip, Kept.Rip.from, Kept.Rip.length, Kept.Rip.volume, Kept.Rip.pitch)
				end
			end
			local seen = backSeen
			local t = if seen then clock - seen else 0
			s.dark.Enabled = true
			s.black.BackgroundTransparency = smooth(t / BACK_LIFT)
			s.edges.BackgroundTransparency = 1 - Left.Edges * (1 - smooth(t / BACK_LIFT))
			local shown = if seen then smooth(t / 0.3) * (1 - smooth((t - BACK_HOLD) / 0.6)) else 0
			s.title.Text = Left.Copy.Back
			s.title.TextColor3 = WARM
			s.titleScale.Scale = 1 + 0.15 * (1 - smooth(t / 0.3))
			s.title.TextTransparency, s.titleStroke.Transparency = 1 - shown, 1 - shown
			showBar(0, s)
			if seen and t > BACK_LIFT * 0.5 then
				hideHud(false)
			end
			-- done, or no character came after all: let the screen go
			if (seen and t > BACK_HOLD + 0.7) or clock - bAt > 15 then
				backAt = nil
				rest(s)
			end
			return
		end
		-- the car came back after all: the black clears
		local cAt = cancelAt
		if cAt and not at then
			local u = smooth((clock - cAt) / CANCEL_FADE)
			s.black.BackgroundTransparency = 1 - cancelFrom * (1 - u)
			s.edges.BackgroundTransparency = 1 - Left.Edges * (1 - u)
			s.title.TextTransparency, s.titleStroke.Transparency = 1, 1
			if u >= 1 then
				cancelAt = nil
				rest(s)
			end
			return
		end
		local a = at
		if not a then
			return
		end
		-- the ride's clock: in Studio `DevRideHold` holds the sting with the ride, a frame to look at
		local since = RideClock(a)
		s.dark.Enabled = true
		local value = watchValue()
		local black = 0
		-- the bell, far above, as their car levels: under the black, or as it lifts
		once("bell", since, Ride.arrives() + 0.15, function()
			local row = Ride.Sounds.Bell
			play(bell, row.Start, row.Stop - row.Start, row.Volume * Left.BellVolume, 0.84)
		end)
		if not watchBegan then
			-- the sting
			black = Left.black(since)
			s.edges.BackgroundTransparency = 1 - Left.edges(since)
			local shown, size = Left.title(since)
			s.title.TextTransparency, s.titleStroke.Transparency = 1 - shown, 1 - shown
			s.titleScale.Scale = size
			if since >= Left.Freeze then
				setControls(false)
				hideHud(true)
			end
			local m = motor
			local away = Left.away(since)
			if m then
				if away > 0.001 and since < Ride.arrives() then
					if not m.IsPlaying then
						m.TimePosition = Ride.position(Ride.Motor, since - Ride.Wait)
							or Ride.Motor.Start
						m:Play()
					end
					m.Volume = Ride.Motor.Volume * Left.MotorVolume * away
					m.PlaybackSpeed = 0.8 + 0.25 * Ride.share(since)
				elseif m.IsPlaying and since > Ride.Wait + 1 then
					m:Stop()
				end
			end
			once("dread", since, Left.HitAt, function()
				play(dread, Kept.Dread.from, Kept.Dread.length, Kept.Dread.volume, Kept.Dread.pitch)
				kick(0.35)
			end)
			local target = targetOf(value)
			if target and since >= Left.LiftAt then
				watchBegan = clock
				aim(target)
			end
			s.name.Text = nameOf(value)
			showBar(0, s)
		end
		local began = watchBegan
		if began then
			-- watching
			local nameText = nameOf(value)
			if s.name.Text ~= nameText then
				s.name.Text = nameText
				s.namePop.Scale = 1.12
			end
			local target = targetOf(value)
			if target ~= subject then
				if not dipAt then
					dipAt, landed = clock, nil
				end
				if dipAt and clock - dipAt >= Left.DipIn and target then
					aim(target)
					landed = clock
				end
			elseif dipAt and not landed then
				landed = clock -- it came back before the dip was whole
			end
			follow(dt, false)
			hideHud(true)
			black = Left.lift(clock - began)
			s.edges.BackgroundTransparency = 1 - Left.Edges * black
			local d = dipAt
			if d then
				local dip = Left.dip(clock - d, if landed then clock - landed else nil)
				black = math.max(black, dip)
				if landed and clock - landed >= Left.DipOut then
					dipAt, landed = nil, nil
				end
			end
			s.title.TextTransparency, s.titleStroke.Transparency = 1, 1
			showBar(smooth((clock - began - Left.LiftIn * 0.6) / Left.BarIn), s)
			if clock - counted >= COUNT_EVERY then
				counted = clock
				friends = countFriends()
			end
			local dim = if friends > 1 then 0 else 0.6
			s.back.TextTransparency, s.nextButton.TextTransparency = dim, dim
			s.namePop.Scale += (1 - s.namePop.Scale) * Left.ease(14, dt)
			local settle = Left.ease(16, dt)
			local backPop = s.back:FindFirstChildOfClass("UIScale")
			if backPop then
				backPop.Scale += (1 - backPop.Scale) * settle
			end
			local nextPop = s.nextButton:FindFirstChildOfClass("UIScale")
			if nextPop then
				nextPop.Scale += (1 - nextPop.Scale) * settle
			end
		end
		local carrying = carryAt
		if carrying and watchBegan then
			black = math.max(black, Left.carry(Workspace:GetServerTimeNow() - carrying))
		end
		shownBlack = black
		s.black.BackgroundTransparency = 1 - black
	end

	local function onInput(input: InputObject, processed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			orbiting = not processed and watchBegan ~= nil
		end
		if not watchBegan or processed then
			return
		end
		local key = input.KeyCode
		if
			key == Enum.KeyCode.E
			or key == Enum.KeyCode.Right
			or key == Enum.KeyCode.ButtonR1
			or key == Enum.KeyCode.DPadRight
		then
			switch("Next")
		elseif
			key == Enum.KeyCode.Q
			or key == Enum.KeyCode.Left
			or key == Enum.KeyCode.ButtonL1
			or key == Enum.KeyCode.DPadLeft
		then
			switch("Back")
		elseif input.UserInputType == Enum.UserInputType.Touch then
			touches[input] = true
		end
	end

	local function onChanged(input: InputObject, _processed: boolean)
		if not watchBegan then
			return
		end
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseMovement and orbiting then
			orbitYaw -= input.Delta.X * Left.OrbitMouse
			orbitPitch -= input.Delta.Y * Left.OrbitMouse
		elseif kind == Enum.UserInputType.Touch and touches[input] then
			orbitYaw -= input.Delta.X * Left.OrbitTouch
			orbitPitch -= input.Delta.Y * Left.OrbitTouch
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local p = input.Position
			stick = if p.Magnitude > 0.2 then Vector2.new(p.X, p.Y) else Vector2.zero
		end
	end

	local function onEnded(input: InputObject, _processed: boolean)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			orbiting = false
		end
		touches[input] = nil
	end

	local system: Brix.System = {
		name = "WatchView",
		start = function(_: any, _context: Brix.Context)
			local gui = player:WaitForChild("PlayerGui")
			local s = makeScreen(gui)
			screen = s
			local m = sound("LeftMotor", Ride.Motor.Id)
			-- the ride outlasts the recording's steady stretch: go round it, as RideView does
			m.PlaybackRegionsEnabled = true
			m.PlaybackRegion = NumberRange.new(Ride.Motor.Start, Ride.Motor.Stop)
			m.Looped = true
			m.LoopRegion = NumberRange.new(Ride.Motor.Loop or Ride.Motor.Start, Ride.Motor.Stop)
			motor = m
			local eq = Instance.new("EqualizerSoundEffect")
			eq.HighGain = Left.Muffle
			eq.MidGain = -4
			eq.LowGain = 2
			eq.Parent = motor
			dread = sound("LeftDread", Kept.Dread.id)
			bell = sound("LeftBell", Ride.Sounds.Bell.Id)
			local bellEq = Instance.new("EqualizerSoundEffect")
			bellEq.HighGain = Left.Muffle * 0.6
			bellEq.Parent = bell
			tick = sound("WatchTick", Ride.Sounds.Tick.Id)
			rip = sound("BackRip", Kept.Rip.id)
			squealSound = sound("CarrySqueal", Kept.Squeal.id)
			slamBang = sound("CarrySlam", SLAM_BANG.Id)
			slamThump = sound("CarryThump", SLAM_THUMP.Id)
			-- the slam is behind the unit's door, close: its top end dulled
			for _, x in { slamBang, slamThump } do
				local dull = Instance.new("EqualizerSoundEffect")
				dull.HighGain = Left.Muffle * 0.7
				dull.Parent = x
			end
			for _, x in { motor, dread, bell, tick, rip, squealSound, slamBang, slamThump } do
				table.insert(sounds, x :: Sound)
			end
			task.spawn(SoundPrimer.prime, {
				Kept.Dread.id,
				Ride.Sounds.Tick.Id,
				Kept.Rip.id,
				Kept.Squeal.id,
				SLAM_BANG.Id,
				SLAM_THUMP.Id,
			})
			table.insert(
				connections,
				s.nextButton.Activated:Connect(function()
					switch("Next")
				end)
			)
			table.insert(
				connections,
				s.back.Activated:Connect(function()
					switch("Back")
				end)
			)
			local cut = s.cutFree
			if cut then
				table.insert(
					connections,
					cut.Activated:Connect(function()
						if watchBegan then
							ask("CutFree")
						end
					end)
				)
			end
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Left.Attribute):Connect(onLeft)
			)
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Left.BackAttribute):Connect(onBack)
			)
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Left.CarryAttribute):Connect(onCarry)
			)
			table.insert(connections, UserInputService.InputBegan:Connect(onInput))
			table.insert(connections, UserInputService.InputChanged:Connect(onChanged))
			table.insert(connections, UserInputService.InputEnded:Connect(onEnded))
			-- the camera between CameraShake's undo and its apply, so a jolt still lands on it
			RunService:BindToRenderStep(
				CAMERA_STEP,
				Enum.RenderPriority.Camera.Value,
				function(dt: number)
					step(nil, dt)
				end
			)
			bound = true
			onLeft()
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			if bound then
				RunService:UnbindFromRenderStep(CAMERA_STEP)
				bound = false
			end
			for _, x in sounds do
				x:Destroy()
			end
			table.clear(sounds)
			setControls(true)
			setCursor(false)
			local s = screen
			if s then
				s.dark:Destroy()
				s.bar:Destroy()
				screen = nil
			end
		end,
	}
	return system
end

return WatchView
