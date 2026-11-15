--!strict
--[[
	CaughtLunge: the catch's jump scare on the caught player's own screen (L-06c2), run by
	CaughtView. The moment: the worst thing that can happen to you, as Five Nights at Freddy's and
	Piggy end a run, their face rushing the camera with a scream, no blood.

	At the catch (`seize`) the hall goes silent: this screen hears the world from far off
	(SoundService's listener moved away), so only your own sounds play; the chase music cuts itself
	(ChaseMusic). Your view is taken from you (the camera Scriptable) and wrenched round to its face
	(`Caught.turn`). The keeper's real body is hidden on this screen and a copy of it stands in its
	place in the same stride (the Mannequin's template, its joints' `Transform`s copied), so nothing
	seems to change. It holds still through the dread. Then it snaps into its lunge (`Pose.Poses.
	Lunge`) and its head flies at your eye (`Caught.reach`), the body hanging off it, while the view
	crash-zooms in (`Caught.lens`): the scream, the sting and the rush (`Caught.Sting`) and its own
	body's groan (its row's Lunge beat) all at that instant. Its head lands a few inches from your
	eye, cocked over, with its hollow thunk (the Catch beat) and the hardest kick; at `Caught.Dark`
	the screen is black (CaughtView), the copy is gone, the real body shows again and the view is
	yours. The hall stays silent until you wake (`hear`).

	A body the server didn't send, or one streamed out, is looked for near your eye; with none, a
	copy stands before you. Its render step runs only through the lunge.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Caught = require(ReplicatedStorage.Shared.Caught)
local KeeperRows = require(ReplicatedStorage.Shared.KeeperRows)
local KeeperTell = require(ReplicatedStorage.Shared.KeeperTell)
local Mannequin = require(ReplicatedStorage.Shared.Mannequin)
local Pose = require(ReplicatedStorage.Shared.Mannequin.Pose)
local SoundPrimer = require(script.Parent.SoundPrimer)

local STEP = "CaughtLunge"
local TAG = "Keeper" -- on each keeper's body (the server's Keepers)
local ROW_ATTRIBUTE = "Keeper" -- its row's name, on the body
-- Where this screen hears the hall from while you're seized: nowhere near it.
local FAR = CFrame.new(0, 1e6, 0)
-- Studs from your eye a keeper's body is looked for when the server's didn't come.
local SEARCH = 12
-- Studs before your eye a stand-in stands when there's no body at all: about a keeper's reach.
local STAND_IN = 3.5
-- Studio only: Workspace's `DevCatchHold` (seconds after the catch) stops the catch's clock at
-- that moment, the lunge and the black both, to look at one frame; clear it and the catch runs on
-- from there (docs/STUDIO.md, "Testing the catch from the MCP").
local DEV_HOLD = "DevCatchHold"
-- On the camera from the rush to the black: FlashlightView puts your torch out of sight.
local SEIZED = "CaughtSeized"

-- Screens left up through the lunge: the catch's own. Everything else (the slots, the corner
-- map, the gate clock) is put away so nothing sits over its face.
local KEEP = { Caught = true, Bang = true }
local GLOW_COLOR = Color3.fromRGB(Caught.GlowColor[1], Caught.GlowColor[2], Caught.GlowColor[3])

-- Its head in the lunge pose, from its root: the copy is flown by its head.
local LUNGE_HEAD = Mannequin.head(Pose.Poses.Lunge)
local HEAD_TO_ROOT = LUNGE_HEAD:Inverse()

-- A sting recording, made once, played at each catch.
type Voice = { sound: Sound, fade: Tween, clip: Caught.Clip }

-- One catch on the screen.
type Seized = {
	camera: Camera,
	eye: CFrame, -- your view as it was taken
	look: CFrame, -- your view on its face
	fov: number, -- your own view's width
	cameraType: Enum.CameraType,
	copy: Model?, -- the copy of its body flown at you
	root: BasePart?, -- the copy's root
	motors: { Motor6D }?,
	real: { BasePart }, -- the real body's parts, hidden on this screen meanwhile
	headTo: CFrame, -- its head's place before your eye as it lands
	headClose: CFrame, -- and pressed in, as it holds the screen
	headFrom: CFrame?, -- its head where it stood, in the lunge pose, once posed
	glow: PointLight?, -- the light on its face
	guis: { ScreenGui }, -- the screens put away for the lunge, to bring back
	row: KeeperRows.Row?,
	lunged: boolean,
	landed: boolean,
}

local CaughtLunge = {}

export type Lunge = {
	-- Its hand has closed on you: `body` is what the server sent (checked here).
	seize: (body: unknown) -> (),
	-- Seconds since the last catch: the clock the screen's black and wake follow too.
	since: () -> number,
	-- The hall comes back as you wake.
	hear: () -> (),
	-- Everything of it ended at once: the view, the copy and the hall's sounds given back.
	release: () -> (),
	destroy: () -> (),
}

local function voiceFor(clip: Caught.Clip): Voice
	local s = Instance.new("Sound")
	s.Name = "CaughtSting"
	s.SoundId = clip.id
	s.Volume = clip.volume
	s.PlaybackSpeed = clip.pitch
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(clip.from, clip.from + clip.length)
	s.Parent = SoundService -- your own sound: no place in the hall
	local heard = clip.length / clip.pitch
	local fade = TweenService:Create(
		s,
		TweenInfo.new(
			math.max(clip.fade, 0.01),
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			0,
			false,
			math.max(heard - clip.fade, 0)
		),
		{ Volume = 0 }
	)
	return { sound = s, fade = fade, clip = clip }
end

-- A beat of its own body's sounds (its row's tell), close in your ears, each layer at full.
local random = Random.new()
local function beat(row: KeeperRows.Row?, name: KeeperTell.Beat)
	local tell = row and row.tell
	local layers = tell and tell.beats[name]
	if not (tell and layers) then
		return
	end
	for _, layer in layers do
		local spec = tell.sounds[layer.sound]
		if not spec then
			continue
		end
		local take = spec.takes[random:NextInteger(1, #spec.takes)]
		local s = Instance.new("Sound")
		s.Name = "CaughtBody"
		s.SoundId = take.id
		s.Volume = spec.volume * layer.gain
		s.PlaybackSpeed = (spec.pitchMin + spec.pitchMax) / 2 * layer.pitch
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(take.start, take.stop)
		s.Parent = SoundService
		s.TimePosition = take.start
		s:Play()
		local heard = (take.stop - take.start) / s.PlaybackSpeed
		TweenService:Create(
			s,
			TweenInfo.new(
				spec.fade / s.PlaybackSpeed,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				0,
				false,
				math.max(heard - spec.fade / s.PlaybackSpeed, 0)
			),
			{ Volume = 0 }
		):Play()
		task.delay(heard + 0.5, function()
			s:Destroy()
		end)
	end
end

-- The keeper that caught you: the body the server sent if it's one, else the nearest keeper's
-- body this screen has near your eye.
local function bodyOf(sent: unknown, eye: Vector3): Model?
	if typeof(sent) == "Instance" and sent:IsA("Model") and sent:HasTag(TAG) and sent.Parent then
		return sent
	end
	local best, bestDistance = nil, SEARCH
	for _, inst in CollectionService:GetTagged(TAG) do
		if inst:IsA("Model") and inst:IsDescendantOf(Workspace) then
			local d = (inst:GetPivot().Position - eye).Magnitude
			if d < bestDistance then
				best, bestDistance = inst, d
			end
		end
	end
	return best
end

function CaughtLunge.new(kick: (amount: number) -> ()): Lunge
	local voices: { Voice } = {}
	for _, clip in Caught.Sting do
		table.insert(voices, voiceFor(clip))
	end
	local ids: { string } = {}
	for _, clip in Caught.Sting do
		table.insert(ids, clip.id)
	end
	task.spawn(SoundPrimer.prime, ids)

	local seized: Seized? = nil
	local caughtAt = 0 -- os.clock of the last catch
	local studio = RunService:IsStudio()
	local bound = false
	local deaf = false -- the hall's sounds taken away
	local listenType: Enum.ListenerType = Enum.ListenerType.Camera
	local listenAt: any = nil -- any: GetListener's second value, an Instance, a CFrame or nil

	-- Seconds since the catch, held where Studio's dev hold says while it's set.
	local function since(): number
		if studio then
			local hold = Workspace:GetAttribute(DEV_HOLD)
			if type(hold) == "number" then
				caughtAt = os.clock() - hold
			end
		end
		return os.clock() - caughtAt
	end

	local function deafen()
		if deaf then
			return
		end
		deaf = true
		listenType, listenAt = SoundService:GetListener()
		SoundService:SetListener(Enum.ListenerType.CFrame, FAR)
	end

	local function hear()
		if not deaf then
			return
		end
		deaf = false
		if listenType == Enum.ListenerType.Camera or listenAt == nil then
			SoundService:SetListener(Enum.ListenerType.Camera)
		else
			SoundService:SetListener(listenType, listenAt)
		end
	end

	-- The lunge over: the copy gone, the real body shown, the view yours again.
	local function settle()
		if bound then
			bound = false
			RunService:UnbindFromRenderStep(STEP)
		end
		local s = seized
		if not s then
			return
		end
		seized = nil
		if s.copy then
			s.copy:Destroy()
		end
		for _, p in s.real do
			p.LocalTransparencyModifier = 0
		end
		for _, g in s.guis do
			if g.Parent then
				g.Enabled = true
			end
		end
		s.camera.FieldOfView = s.fov
		s.camera.CameraType = s.cameraType
		s.camera:SetAttribute(SEIZED, nil)
	end

	-- Each frame of the lunge, with the camera's own step (Scriptable, it moves nothing), before
	-- CameraShake's kick goes on top.
	local function step(_dt: number)
		local s = seized
		if not s then
			return
		end
		local t = since()
		if t >= Caught.Dark then
			settle()
			return
		end
		local view = s.eye:Lerp(s.look, Caught.turn(t))
		local knock = Caught.knock(t)
		if knock > 0 then
			view *= CFrame.new(0, 0, -Caught.KnockPull * knock) * CFrame.Angles(
				math.rad(Caught.KnockTilt) * knock,
				0,
				math.rad(Caught.KnockRoll) * knock
			)
		end
		s.camera.CFrame = view
		s.camera.FieldOfView = s.fov * Caught.lens(t)
		local glow = s.glow
		if glow then
			glow.Brightness = Caught.glow(t)
		end
		if t >= Caught.Dread and not s.lunged then
			s.lunged = true
			s.camera:SetAttribute(SEIZED, true)
			for _, v in voices do
				v.fade:Cancel()
				v.sound.Volume = v.clip.volume
				v.sound.TimePosition = v.clip.from
				v.sound:Play()
				v.fade:Play()
			end
			beat(s.row, "Lunge")
			local copy, root = s.copy, s.root
			if copy and root then
				-- a stop-motion snap into the lunge, where it stood
				if s.motors then
					for _, m in s.motors do
						m.Transform = CFrame.identity
					end
				end
				Mannequin.pose(copy, Pose.Poses.Lunge)
				s.headFrom = root.CFrame * LUNGE_HEAD
			end
		end
		if t >= Caught.Dread + Caught.Lunge and not s.landed then
			s.landed = true
			kick(Caught.HitKick)
			beat(s.row, "Catch")
		end
		local from, root = s.headFrom, s.root
		if from and root then
			local r = Caught.reach(t)
			local to = s.headTo.Position:Lerp(s.headClose.Position, Caught.press(t))
			local at = from.Position:Lerp(to, r)
			local turned = from.Rotation:Lerp(s.headTo.Rotation, math.clamp(r, 0, 1))
			root.CFrame = (turned + at) * HEAD_TO_ROOT
		end
	end

	-- A copy of its body standing where it stands, in the same stride (or a stand-in before
	-- you), the real one hidden on this screen.
	local function standIn(s: Seized, body: Model?)
		local pivot: CFrame
		if body then
			pivot = body:GetPivot()
		else
			local eye = s.eye.Position
			local flat = Vector3.new(s.eye.LookVector.X, 0, s.eye.LookVector.Z)
			flat = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)
			local character = Players.LocalPlayer.Character
			local you = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local floor = if you
					and you:IsA("BasePart")
					and humanoid
				then you.Position.Y - humanoid.HipHeight - you.Size.Y / 2
				else eye.Y - 4.5
			local feet = Vector3.new(eye.X, floor, eye.Z)
			pivot = CFrame.lookAt(feet + flat * STAND_IN, feet)
		end
		local copy = Mannequin.clone(pivot, Workspace)
		if not copy then
			return
		end
		copy.Name = "CaughtLunge"
		copy:RemoveTag(TAG) -- never a keeper to anything else on this screen
		for _, d in copy:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanQuery, d.CanTouch, d.CanCollide = false, false, false
			end
		end
		local motors = Mannequin.motors(copy)
		local from = body and Mannequin.motors(body)
		if motors and from then
			Mannequin.rest(copy)
			for i, m in motors do
				m.Transform = from[i].Transform
			end
		end
		s.copy, s.motors = copy, motors
		local root = copy.PrimaryPart
		s.root = root
		local head = copy:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			local at = Instance.new("Attachment")
			at.Name = "Glow"
			at.Position = Vector3.new(0, -Caught.GlowBelow, -Caught.GlowAhead) -- its face is -Z
			at.Parent = head
			local light = Instance.new("PointLight")
			light.Range = Caught.GlowRange
			light.Color = GLOW_COLOR
			light.Shadows = false
			light.Brightness = Caught.glow(0)
			light.Parent = at
			s.glow = light
		end
		if body then
			for _, d in body:GetDescendants() do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = 1
					table.insert(s.real, d)
				end
			end
		end
	end

	local function seize(sent: unknown)
		settle()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local eye = camera.CFrame
		local body = bodyOf(sent, eye.Position)
		local name = body and body:GetAttribute(ROW_ATTRIBUTE)
		caughtAt = os.clock()
		local s: Seized = {
			camera = camera,
			eye = eye,
			look = eye,
			fov = camera.FieldOfView,
			-- a scripted view at a catch was a crawl's, which the catch ends (CrawlView): you wake
			-- with your own
			cameraType = if camera.CameraType == Enum.CameraType.Scriptable
				then Enum.CameraType.Custom
				else camera.CameraType,
			real = {},
			guis = {},
			headTo = eye,
			headClose = eye,
			row = if type(name) == "string" then KeeperRows[name] else KeeperRows.Mannequin,
			lunged = false,
			landed = false,
		}
		standIn(s, body)
		-- your view on its face: its real head where this screen shows it, else the copy's
		local head = body and body:FindFirstChild("Head")
		local copyHead = s.copy and s.copy:FindFirstChild("Head")
		local face = if head and head:IsA("BasePart")
			then head.Position
			elseif copyHead and copyHead:IsA("BasePart") then copyHead.Position
			else eye.Position + eye.LookVector * STAND_IN
		s.look = CFrame.lookAt(eye.Position, face)
		-- its head's place before your eye: facing you, cocked over
		local facing = CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, math.rad(Caught.Cock))
		s.headTo = s.look * CFrame.new(0, 0, -Caught.Near) * facing
		s.headClose = s.look * CFrame.new(0, 0, -Caught.Close) * facing
		local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			for _, g in playerGui:GetChildren() do
				if g:IsA("ScreenGui") and g.Enabled and not KEEP[g.Name] then
					g.Enabled = false
					table.insert(s.guis, g)
				end
			end
		end
		seized = s
		deafen()
		camera.CameraType = Enum.CameraType.Scriptable
		if not bound then
			bound = true
			RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value, step)
		end
		kick(Caught.Kick)
	end

	local function release()
		settle()
		hear()
	end

	return {
		seize = seize,
		since = since,
		hear = hear,
		release = release,
		destroy = function()
			release()
			for _, v in voices do
				v.fade:Cancel()
				v.sound:Destroy()
			end
			table.clear(voices)
		end,
	}
end

-- One of a keeper row's beats in your ears only (the Packrat's take, S2-06c, plays its Lunge).
CaughtLunge.beat = beat

return CaughtLunge
