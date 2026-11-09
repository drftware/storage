--!strict
--[[
	Client system: your two tool slots on this screen (L-11b, D-048), as Lethal Company's slots.

	The slots' bar sits at the bottom of the screen: two squares, each showing the tool in it as a
	real 3D picture, the one in your hand lit and raised. A tap on a square (or 1 and 2, or the
	gamepad's d-pad left and right) puts that slot in your hand; G, the d-pad's down or the round
	Drop button beside the bar drops what you hold at your feet. A tool's name shows above the bar
	for a moment as it comes into your hand, as Minecraft's hotbar names what you switch to; a
	friend's handover reads "Bolt cutters from Sam".

	What's in your hand is drawn low on the left of your first-person view (the torch has the right),
	swaying with the torch's own sway (`Torch.step`). A new tool swings up into view from below;
	switching swings the old one down and the new one up. Your switch answers at once on your
	screen (with a soft clank) and the server is told; the server decides pick-ups, drops and
	handovers, and their clanks are its sounds, heard by everyone near.

	Friends: a "Give" prompt on each friend while you hold a tool. If their hands are full it says
	so on the prompt.
]]
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Flashlight = require(ReplicatedStorage.Shared.Flashlight)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Torch = Flashlight.Torch
local Carry = Tools.Carry
local Catalog = Tools.Catalog

local player = Players.LocalPlayer

local RENDER = "ToolHold"
local RAD = math.pi / 180
local INK = Color3.fromRGB(232, 226, 214) -- the hints' warm off-white, as the torch button's
local SWING_IN = 0.3 -- seconds a tool takes to come up into your view
local SWING_OUT = 0.14 -- seconds it takes to drop out of it
local SWING_FROM = Vector3.new(0.2, -0.95, 0.3) -- where it comes up from: below your view
local SWING_TILT = -50 -- degrees it's pitched down there, jaw low
local PREDICT = 0.6 -- seconds your screen trusts your own switch before the server's word
local SWITCH_VOLUME = 0.45 -- of the pick-up clank: drawing a tool from your belt is quieter
local SLOT_OF_HEIGHT = 0.12 -- a slot's size, of the screen's height
local SLOT_MIN, SLOT_MAX = 56, 88 -- pixels
local GAP = 0.14 -- of a slot, between the squares
local LIFT = 1.08 -- the slot in your hand, raised
local NAME_SECONDS = 1.4 -- the name above the bar, before it fades
local FADE = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local REFUSAL_SECONDS = 1.2
-- At a door: while you hold Cut or Lock with the right tool, it comes down to the latch
-- (`Catalog` row's `use`), and the moment it works it jerks: the jaw clamping, the shackle shut.
local WORK_RATE = 9 -- how fast it moves to the latch and back (of the way, a second)
local WORK_LINGER = 0.3 -- seconds it stays at the latch after it worked
local KICK_DECAY = 6 -- of the jerk, a second
local KICK_PITCH = 9 -- degrees the jerk tips it
local KICK_PUSH = 0.07 -- studs it pushes forward
-- The buttons a tool works (a door's `DoorAction`, a wall's `Tools.ActionAttribute`), and the
-- tool each needs in your hand.
local WORKS: { [string]: string } = { Cut = "BoltCutters", Lock = "Padlock", Saw = "Saw" }
-- While a running saw is out at the wall it shakes in your hand: studs, and how fast it changes.
local SAW_SHAKE = 0.018
local SAW_SHAKE_TURN = 0.6 -- degrees

type SlotView = {
	button: TextButton,
	stroke: UIStroke,
	scale: UIScale,
	frame: ViewportFrame,
	hint: TextLabel,
	key: string, -- what's drawn in it ("" for empty)
}

type Give = { prompt: ProximityPrompt, friend: Player, shown: number }

local function backOut(t: number): number
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

-- The slots as the server last said: the key in each ("" for empty), and the slot in hand.
local function serverSlots(): ({ string }, number)
	local keys = {}
	for i = 1, Carry.Slots do
		local k = player:GetAttribute(Tools.slotAttribute(i))
		keys[i] = if type(k) == "string" then k else ""
	end
	local hand = player:GetAttribute(Tools.HandAttribute)
	return keys, if type(hand) == "number" then hand else 1
end

-- Whether `friend` has room for a tool, by their attributes.
local function hasRoom(friend: Player): boolean
	for i = 1, Carry.Slots do
		local k = friend:GetAttribute(Tools.slotAttribute(i))
		if type(k) ~= "string" or k == "" then
			return true
		end
	end
	return false
end

-- A 3D picture of `key`'s tool in `frame` (empty for "").
local function picture(frame: ViewportFrame, key: string)
	frame:ClearAllChildren()
	local row = Catalog[key]
	if not row then
		return
	end
	local model = Tools.clone(key, CFrame.identity)
	if not model then
		return
	end
	local body = Tools.body(model)
	local length = if body then body.Size.Magnitude else 2
	local centre = if body then body.Position else Vector3.zero
	local i = row.icon
	-- the tool tipped towards the camera (its top to the front), then laid across the square
	model:PivotTo(CFrame.Angles(0, 0, i[4] * RAD) * CFrame.Angles(i[2] * RAD, i[3] * RAD, 0))
	centre = if body then body.Position else centre
	model.Parent = frame
	local cam = Instance.new("Camera")
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(centre + Vector3.new(0, 0, length * i[1] * 2.2), centre)
	cam.Parent = frame
	frame.CurrentCamera = cam
end

local function makeBar(): (ScreenGui, Frame, { SlotView }, TextButton, TextLabel)
	local gui = Instance.new("ScreenGui")
	gui.Name = "Slots"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.BackgroundTransparency = 1
	bar.Parent = gui
	local views: { SlotView } = {}
	for i = 1, Carry.Slots do
		local b = Instance.new("TextButton")
		b.Name = `Slot{i}`
		b.Text = ""
		b.AutoButtonColor = false
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.BackgroundColor3 = Color3.new(0, 0, 0)
		b.BackgroundTransparency = 0.5
		b.Parent = bar
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.16, 0)
		corner.Parent = b
		local stroke = Instance.new("UIStroke")
		stroke.Color = INK
		stroke.Transparency = 0.7
		stroke.Thickness = 1.5
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = b
		local scale = Instance.new("UIScale")
		scale.Parent = b
		local vf = Instance.new("ViewportFrame")
		vf.AnchorPoint = Vector2.new(0.5, 0.5)
		vf.Position = UDim2.fromScale(0.5, 0.5)
		vf.Size = UDim2.fromScale(0.92, 0.92)
		vf.BackgroundTransparency = 1
		vf.Ambient = Color3.fromRGB(150, 145, 140)
		vf.LightColor = Color3.fromRGB(255, 240, 220)
		vf.LightDirection = Vector3.new(-0.4, -1, -0.6)
		vf.Parent = b
		local hint = Instance.new("TextLabel")
		hint.Name = "Key"
		hint.AnchorPoint = Vector2.new(0, 0)
		hint.Position = UDim2.fromScale(0.07, 0.04)
		hint.Size = UDim2.fromScale(0.3, 0.3)
		hint.BackgroundTransparency = 1
		hint.Font = Enum.Font.GothamBold
		hint.Text = tostring(i)
		hint.TextColor3 = INK
		hint.TextTransparency = 0.35
		hint.TextScaled = true
		hint.TextXAlignment = Enum.TextXAlignment.Left
		hint.Parent = b
		table.insert(
			views,
			{ button = b, stroke = stroke, scale = scale, frame = vf, hint = hint, key = "" }
		)
	end
	-- Drop: a round button beside the bar, shown while you hold a tool
	local drop = Instance.new("TextButton")
	drop.Name = "Drop"
	drop.AutoButtonColor = false
	drop.AnchorPoint = Vector2.new(0, 0.5)
	drop.BackgroundColor3 = Color3.new(0, 0, 0)
	drop.BackgroundTransparency = 0.5
	drop.Font = Enum.Font.GothamBold
	drop.Text = "Drop"
	drop.TextColor3 = INK
	drop.TextScaled = true
	drop.Visible = false
	drop.Parent = bar
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0.5, 0)
	dc.Parent = drop
	local dpad = Instance.new("UIPadding")
	dpad.PaddingLeft = UDim.new(0.18, 0)
	dpad.PaddingRight = UDim.new(0.18, 0)
	dpad.PaddingTop = UDim.new(0.3, 0)
	dpad.PaddingBottom = UDim.new(0.3, 0)
	dpad.Parent = drop
	local ds = Instance.new("UIStroke")
	ds.Color = INK
	ds.Transparency = 0.6
	ds.Thickness = 1.5
	ds.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ds.Parent = drop
	-- the name above the bar
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.Text = ""
	name.TextColor3 = INK
	name.TextScaled = true
	name.TextTransparency = 1
	name.TextStrokeTransparency = 1
	name.TextStrokeColor3 = Color3.new(0, 0, 0)
	name.Parent = bar
	return gui, bar, views, drop, name
end

local ToolView = {}

function ToolView.new(): Brix.System
	local connections: { RBXScriptConnection } = {}
	local gui: ScreenGui? = nil
	local bar: Frame? = nil
	local views: { SlotView } = {}
	local dropButton: TextButton? = nil
	local nameLabel: TextLabel? = nil
	local nameShown = 0
	local switchRemote: RemoteEvent? = nil
	local dropRemote: RemoteEvent? = nil
	local giveRemote: RemoteEvent? = nil
	local predicted: number? = nil
	local predictedAt = -math.huge
	local lastKeys: { string } = {}
	local gives: { [Model]: Give } = {}
	local viewFolder: Folder? = nil
	-- your view's tool
	local sway = Torch.sway()
	local pose = Torch.pose()
	local lastYaw: number?, lastPitch = nil, 0
	local shownKey = ""
	local shownModel: Model? = nil
	local shownBody: BasePart? = nil
	local bodyOff = CFrame.identity
	local swing = 0
	local rising = true
	local switchSound: Sound? = nil
	-- at a door
	local working = false
	local workUntil = 0
	local work = 0
	local kick = 0
	local lockReach: { [ProximityPrompt]: number } = {} -- each Lock button's reach from the server
	local sawReach: { [ProximityPrompt]: number } = {} -- and each wall's Saw button's

	local function alive(): boolean
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.Health > 0
	end

	local function active(): number
		local _, hand = serverSlots()
		if predicted and os.clock() - predictedAt < PREDICT then
			return predicted
		end
		predicted = nil
		return hand
	end

	local function heldKey(): string
		local keys = serverSlots()
		return keys[active()] or ""
	end

	-- A line above the bar for a moment: a tool's name, or a notice.
	local function say(text: string)
		local label = nameLabel
		if not label then
			return
		end
		nameShown += 1
		local mine = nameShown
		label.Text = text
		label.TextTransparency = 0
		label.TextStrokeTransparency = 0.6
		task.delay(NAME_SECONDS, function()
			if nameShown == mine then
				TweenService
					:Create(label, FADE, { TextTransparency = 1, TextStrokeTransparency = 1 })
					:Play()
			end
		end)
	end

	-- Sizes the bar for this screen: phone first.
	local function layout()
		local b = bar
		local camera = Workspace.CurrentCamera
		if not (b and camera) then
			return
		end
		local h = camera.ViewportSize.Y
		local size = math.clamp(math.floor(h * SLOT_OF_HEIGHT), SLOT_MIN, SLOT_MAX)
		local gap = math.floor(size * GAP)
		local width = size * Carry.Slots + gap * (Carry.Slots - 1)
		b.Size = UDim2.fromOffset(width, size)
		b.Position = UDim2.new(0.5, 0, 1, -math.floor(size * 0.22))
		for i, v in views do
			v.button.Size = UDim2.fromOffset(size, size)
			v.button.Position = UDim2.fromOffset((i - 1) * (size + gap) + size / 2, size / 2)
		end
		local d = dropButton
		if d then
			local ds = math.floor(size * 0.62)
			d.Size = UDim2.fromOffset(math.floor(ds * 1.25), ds)
			d.Position = UDim2.new(1, gap, 0.5, 0)
		end
		local n = nameLabel
		if n then
			n.Size = UDim2.fromOffset(width * 2, math.floor(size * 0.3))
			n.Position = UDim2.new(0.5, 0, 0, -math.floor(size * 0.12))
		end
		-- key hints only with a keyboard and no touch
		local keys = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
		for _, v in views do
			v.hint.Visible = keys
		end
	end

	-- Draws the bar from the slots: each square's picture, the one in hand raised and lit.
	local function refresh()
		local keys = serverSlots()
		local hand = active()
		for i, v in views do
			local key = keys[i] or ""
			if v.key ~= key then
				v.key = key
				picture(v.frame, key)
			end
			local on = i == hand
			v.stroke.Transparency = if on then 0.05 else 0.7
			v.stroke.Thickness = if on then 2.5 else 1.5
			v.button.BackgroundTransparency = if on then 0.3 else 0.5
			TweenService:Create(v.scale, PRESS, { Scale = if on then LIFT else 1 }):Play()
		end
		local d = dropButton
		if d then
			d.Visible = (keys[hand] or "") ~= ""
		end
		-- a Give prompt on each friend only while you hold something
		local holding = (keys[hand] or "") ~= ""
		for _, g in gives do
			g.prompt.Enabled = holding
		end
		-- a door's Lock button only while a padlock's in your hand (on this screen only: the
		-- server never changes a button's reach, so this stays)
		local padlock = keys[hand] == "Padlock"
		for p, reach in lockReach do
			p.MaxActivationDistance = if padlock then reach else 0
		end
		-- a wall's Saw button while you carry a saw in either slot: in the other one, the button
		-- says "Hold the saw"
		local saw = table.find(keys, "Saw") ~= nil
		for p, reach in sawReach do
			p.MaxActivationDistance = if saw then reach else 0
		end
		-- a slot newly filled: name it as it comes into your hand
		for i = 1, Carry.Slots do
			local was, now = lastKeys[i] or "", keys[i] or ""
			if was == "" and now ~= "" and i == hand then
				local row = Catalog[now]
				if row then
					say(row.name)
				end
			end
		end
		lastKeys = keys
	end

	local function pick(slot: number)
		if not alive() or slot == active() then
			return
		end
		-- both hands on a big tool (the ladder): the server refuses too
		local held = Catalog[heldKey()]
		if held and held.bothHands then
			say(`Drop the {string.lower(held.name)} first`)
			return
		end
		predicted, predictedAt = slot, os.clock()
		local r = switchRemote
		if r then
			r:FireServer(slot)
		end
		local keys = serverSlots()
		local row = Catalog[keys[slot] or ""]
		if row then
			say(row.name)
			local s = switchSound
			if s then
				s.SoundId = row.pickUp.id
				s.PlaybackRegion =
					NumberRange.new(row.pickUp.from, row.pickUp.from + row.pickUp.length)
				s.Volume = row.pickUp.volume * SWITCH_VOLUME
				s.TimePosition = row.pickUp.from
				s:Play()
			end
		end
		refresh()
	end

	local function drop()
		if not alive() or heldKey() == "" then
			return
		end
		local r = dropRemote
		if r then
			r:FireServer()
		end
	end

	-- The prompt on a friend: "Give" while you hold a tool.
	local function addFriend(friend: Player, character: Model)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if not (root and root:IsA("BasePart")) or not character.Parent then
			return
		end
		local p = Instance.new("ProximityPrompt")
		p.Name = "Give"
		p.ActionText = "Give"
		p.ObjectText = friend.DisplayName
		p.KeyboardKeyCode = Enum.KeyCode.E
		p.GamepadKeyCode = Enum.KeyCode.ButtonX
		p.MaxActivationDistance = Carry.GiveReach
		p.RequiresLineOfSight = false
		p.HoldDuration = 0
		p.Enabled = heldKey() ~= ""
		p.Parent = root
		local g: Give = { prompt = p, friend = friend, shown = 0 }
		gives[character] = g
		p.Triggered:Connect(function()
			if not hasRoom(friend) then
				g.shown += 1
				local mine = g.shown
				p.ObjectText = "Hands full"
				task.delay(REFUSAL_SECONDS, function()
					if g.shown == mine and p.Parent then
						p.ObjectText = friend.DisplayName
					end
				end)
				return
			end
			local r = giveRemote
			if r then
				r:FireServer(friend)
			end
		end)
		character.Destroying:Connect(function()
			gives[character] = nil
		end)
	end

	local function watchFriend(friend: Player)
		if friend == player then
			return
		end
		table.insert(
			connections,
			friend.CharacterAdded:Connect(function(character: Model)
				addFriend(friend, character)
			end)
		)
		local character = friend.Character
		if character then
			task.spawn(addFriend, friend, character)
		end
	end

	-- Your view's tool: `key`'s model, or none.
	local function show(key: string)
		if shownModel then
			shownModel:Destroy()
		end
		shownModel, shownBody, shownKey = nil, nil, key
		if key == "" or not viewFolder then
			return
		end
		local model = Tools.clone(key, CFrame.identity)
		if not model then
			return
		end
		local body = Tools.body(model)
		if not body then
			model:Destroy()
			return
		end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CastShadow = false
			end
		end
		bodyOff = body.PivotOffset:Inverse()
		model.Parent = viewFolder
		shownModel, shownBody = model, body
	end

	-- Each frame, after the camera: the tool in your hand where your left hand holds it, swinging
	-- in and out as it changes.
	local function hold(dt: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local want = if alive() then heldKey() else ""
		if want ~= shownKey then
			-- the old one drops out of view, then the new one comes up
			rising = false
			swing -= dt / SWING_OUT
			if swing <= 0 or shownModel == nil then
				swing = 0
				rising = true
				show(want)
			end
		elseif swing < 1 then
			rising = true
			swing = math.min(1, swing + dt / SWING_IN)
		end
		local body = shownBody
		if not body then
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
		local row = Catalog[shownKey]
		local e = if rising then backOut(swing) else swing * swing
		local away = 1 - e
		-- down to the door's latch while you hold its button, and the jerk as it works
		local target = if working or os.clock() < workUntil then 1 else 0
		work += (target - work) * math.min(1, dt * WORK_RATE)
		kick = math.max(0, kick - dt * KICK_DECAY)
		local w = work * work * (3 - 2 * work)
		local h = vec(row.hold):Lerp(vec(row.use), w)
		local t0, t1 = row.holdTurn, row.useTurn
		local yawT = t0[1] + (t1[1] - t0[1]) * w
		-- a running saw out at the wall shakes in your hand (its motor; SawView buzzes your view)
		local buzz, buzzTurn = Vector3.zero, 0
		if shownKey == "Saw" and working and w > 0.5 then
			buzz = Vector3.new(
				(math.random() * 2 - 1) * SAW_SHAKE,
				(math.random() * 2 - 1) * SAW_SHAKE,
				0
			)
			buzzTurn = (math.random() * 2 - 1) * SAW_SHAKE_TURN
		end
		local pitchT = t0[2] + (t1[2] - t0[2]) * w + KICK_PITCH * kick + buzzTurn
		local rollT = t0[3] + (t1[3] - t0[3]) * w
		local grip = cam
			* CFrame.new(h + SWING_FROM * away + Vector3.new(0, 0, -KICK_PUSH * kick) + buzz)
			-- mirrored: the left hand's sway leans the other way
			* CFrame.new(-p.x, p.y, p.z)
			* CFrame.fromEulerAnglesYXZ(
				(pitchT + SWING_TILT * away) * RAD + p.pitch,
				yawT * RAD - p.yaw,
				rollT * RAD - p.roll
			)
		-- the whole model, so a second part (the ladder's fly) moves with it
		local model = shownModel
		if model then
			model:PivotTo(grip)
		else
			body.CFrame = grip * bodyOff
		end
	end

	local function onAction(
		name: string,
		state: Enum.UserInputState,
		_input: InputObject
	): Enum.ContextActionResult
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if name == "ToolSlot1" then
			pick(1)
		elseif name == "ToolSlot2" then
			pick(2)
		elseif name == "ToolDrop" then
			drop()
		end
		return Enum.ContextActionResult.Sink
	end

	local system = { name = "ToolView" }

	function system.start(_: any, _context: Brix.Context)
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		task.spawn(SoundPrimer.prime, Tools.soundIds())
		local folder = Instance.new("Folder")
		folder.Name = "YourTool"
		folder.Parent = Workspace
		viewFolder = folder
		local s = Instance.new("Sound")
		s.Name = "ToolSwitch"
		s.PlaybackRegionsEnabled = true
		s.Parent = folder
		switchSound = s
		local g, b, v, d, n = makeBar()
		gui, bar, views, dropButton, nameLabel = g, b, v, d, n
		for i, view in views do
			table.insert(
				connections,
				view.button.Activated:Connect(function()
					pick(i)
				end)
			)
		end
		table.insert(connections, d.Activated:Connect(drop))
		g.Parent = player:WaitForChild("PlayerGui")
		g.Enabled = true
		layout()
		local camera = Workspace.CurrentCamera
		if camera then
			table.insert(
				connections,
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
			)
		end
		table.insert(connections, UserInputService.LastInputTypeChanged:Connect(layout))
		for i = 1, Carry.Slots do
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Tools.slotAttribute(i)):Connect(refresh)
			)
		end
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Tools.HandAttribute):Connect(function()
				-- the server agreed (or overruled): its word from here
				local _, hand = serverSlots()
				if predicted == hand then
					predicted = nil
				end
				refresh()
			end)
		)
		-- the door buttons your tool works: your view follows your hold on them
		local function works(prompt: ProximityPrompt): boolean
			local action = prompt:GetAttribute("DoorAction")
				or prompt:GetAttribute(Tools.ActionAttribute)
			return type(action) == "string" and WORKS[action] ~= nil and WORKS[action] == heldKey()
		end
		table.insert(
			connections,
			ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt)
				if works(prompt) then
					working = true
				end
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptButtonHoldEnded:Connect(function(_prompt: ProximityPrompt)
				working = false
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
				if works(prompt) then
					kick = 1
					workUntil = os.clock() + WORK_LINGER
				end
			end)
		)
		local function addLock(inst: Instance)
			if inst:IsA("ProximityPrompt") and lockReach[inst] == nil then
				lockReach[inst] = inst.MaxActivationDistance
				if heldKey() ~= "Padlock" then
					inst.MaxActivationDistance = 0
				end
			end
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Tools.LockTag):Connect(addLock)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Tools.LockTag)
				:Connect(function(inst: Instance)
					lockReach[inst :: ProximityPrompt] = nil
				end)
		)
		for _, inst in CollectionService:GetTagged(Tools.LockTag) do
			addLock(inst)
		end
		local function addSaw(inst: Instance)
			if inst:IsA("ProximityPrompt") and sawReach[inst] == nil then
				sawReach[inst] = inst.MaxActivationDistance
				if table.find(serverSlots(), "Saw") == nil then
					inst.MaxActivationDistance = 0
				end
			end
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Tools.SawTag):Connect(addSaw)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Tools.SawTag)
				:Connect(function(inst: Instance)
					sawReach[inst :: ProximityPrompt] = nil
				end)
		)
		for _, inst in CollectionService:GetTagged(Tools.SawTag) do
			addSaw(inst)
		end
		lastKeys = serverSlots()
		refresh()
		ContextActionService:BindAction(
			"ToolSlot1",
			onAction,
			false,
			Enum.KeyCode.One,
			Enum.KeyCode.DPadLeft
		)
		ContextActionService:BindAction(
			"ToolSlot2",
			onAction,
			false,
			Enum.KeyCode.Two,
			Enum.KeyCode.DPadRight
		)
		ContextActionService:BindAction(
			"ToolDrop",
			onAction,
			false,
			Enum.KeyCode.G,
			Enum.KeyCode.DPadDown
		)
		RunService:BindToRenderStep(RENDER, Enum.RenderPriority.Camera.Value + 2, hold)
		table.insert(connections, Players.PlayerAdded:Connect(watchFriend))
		for _, friend in Players:GetPlayers() do
			watchFriend(friend)
		end
		task.spawn(function()
			local remotes = ReplicatedStorage:WaitForChild(Tools.RemoteFolder, 30)
			if not remotes then
				return
			end
			local function get(name: string): RemoteEvent?
				local r = remotes:WaitForChild(name, 30)
				return if r and r:IsA("RemoteEvent") then r else nil
			end
			switchRemote = get(Tools.SwitchRemote)
			dropRemote = get(Tools.DropRemote)
			giveRemote = get(Tools.GiveRemote)
			local notice = get(Tools.NoticeRemote)
			if notice then
				table.insert(
					connections,
					notice.OnClientEvent:Connect(function(text: unknown)
						if type(text) == "string" then
							say(text)
						end
					end)
				)
			end
		end)
	end

	function system.stop(_: any)
		RunService:UnbindFromRenderStep(RENDER)
		for _, name in { "ToolSlot1", "ToolSlot2", "ToolDrop" } do
			ContextActionService:UnbindAction(name)
		end
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, g in gives do
			g.prompt:Destroy()
		end
		table.clear(gives)
		if gui then
			gui:Destroy()
		end
		if viewFolder then
			viewFolder:Destroy()
		end
	end

	return system
end

return ToolView
