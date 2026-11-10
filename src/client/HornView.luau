--!strict
--[[
	Client system: the air horn on this screen (L-14a2, D-087).

	Yours: while it's in your hand, a click, a gamepad's L2 or the round Blow button (on a phone,
	left of the jump button, under your right thumb; otherwise beside the slots' bar) blows it. Your
	screen answers at once: the blast at your horn, the horn brought up in your view (ToolView's
	`use`) and a kick to your view (CameraShake). The server is told (ToolUse) and decides for
	everyone else. Your screen keeps the server's gap between blows (`Horn.allow`): the button dims
	until the horn is ready again.

	Friends': when the server stamps a carried horn as blown (`Horn.BlownAttribute`), the blast
	plays at its bell, heard as far as keepers hear it (`Horn.Reach`), and the arm holding it rises
	up and forward through the blast (their left shoulder, posed after their animation, as
	FlashlightView raises a torch arm).
]]
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Horn = require(ReplicatedStorage.Shared.Tools.Horn)
local SoundPrimer = require(script.Parent.SoundPrimer)
local ToolView = require(script.Parent.ToolView)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Carry = Tools.Carry
local Catalog = Tools.Catalog

local player = Players.LocalPlayer

local ACTION = "ToolUse"
local INK = Color3.fromRGB(232, 226, 214) -- the hints' warm off-white, as the other buttons'
local PRESS = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local READY = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- The phone's button: the torch button's size, a thumb's width left of the jump button.
local BUTTON_OF_JUMP = 0.74
local BUTTON_MIN, BUTTON_MAX = 52, 92 -- pixels
local BUTTON_GAP = 0.22 -- of the button, between it and the jump button
local DIM = 0.75 -- the button's background and words while the horn isn't ready yet

-- A joint an animation turns: a Motor6D, or the AnimationConstraint newer rigs' shoulders are.
-- any: both have Transform, but Luau can't index a property through their union.
type Joint = any

-- A friend's arm raised, on this screen.
type Arm = {
	since: number, -- os.clock of their blast
	shoulder: Joint?,
	elbow: Joint?,
}

local function joint(character: Model, part: string, name: string): Joint?
	local p = character:FindFirstChild(part)
	local j = p and p:FindFirstChild(name)
	if j and (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) then
		return j
	end
	return nil
end

-- The round button, as the Drop button: dark, an off-white ring and one word.
local function makeButton(): (ScreenGui, TextButton, UIScale, UIStroke)
	local gui = Instance.new("ScreenGui")
	gui.Name = "HornPress"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local b = Instance.new("TextButton")
	b.Name = "Use"
	b.AutoButtonColor = false
	b.AnchorPoint = Vector2.new(1, 0.5)
	b.BackgroundColor3 = Color3.new(0, 0, 0)
	b.BackgroundTransparency = 0.5
	b.Font = Enum.Font.GothamBold
	b.Text = "Blow"
	b.TextColor3 = INK
	b.TextScaled = true
	b.Visible = false
	b.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.18, 0)
	pad.PaddingRight = UDim.new(0.18, 0)
	pad.PaddingTop = UDim.new(0.3, 0)
	pad.PaddingBottom = UDim.new(0.3, 0)
	pad.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Color = INK
	stroke.Transparency = 0.55
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	local scale = Instance.new("UIScale")
	scale.Parent = b
	return gui, b, scale, stroke
end

local HornView = {}

function HornView.new(hand: ToolView.Hand, kick: (amount: number) -> ()): Brix.System
	local connections: { RBXScriptConnection } = {}
	local horns: { [Model]: RBXScriptConnection } = {} -- carried horns, their blasts watched
	local arms: { [Model]: Arm } = {} -- friends' characters with an arm raised
	local useRemote: RemoteEvent? = nil
	local gui: ScreenGui? = nil
	local button: TextButton? = nil
	local press: UIScale? = nil
	local stroke: UIStroke? = nil
	local touch = false -- the button sits by the jump button, not the bar
	local jump: GuiObject? = nil
	local findJumpIn = 0
	local holding = "" -- the catalog key in your hand with a verb, or ""
	local lastBlow: number? = nil -- your last blow, os.clock
	local ready = true

	local function alive(): boolean
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid ~= nil and humanoid.Health > 0
	end

	-- The horn model in `character`'s hand, if they carry one there.
	local function hornIn(character: Model?): Model?
		if not character then
			return nil
		end
		for _, c in character:GetChildren() do
			if c:IsA("Model") and c:GetAttribute(Tools.KindAttribute) == Horn.Key then
				return c
			end
		end
		return nil
	end

	-- The blast, once, at `model`'s bell (its body), `late` seconds into it.
	local function blast(model: Model, late: number)
		local body = Tools.body(model)
		local at: Instance = body or Workspace
		local s = Horn.Blast
		local snd = Tools.sound(s, at, Horn.Reach)
		snd.RollOffMinDistance = Horn.Near
		snd.TimePosition = s.from + math.max(0, late)
		snd:Play()
		task.delay(s.length / (s.pitch or 1) + 0.5, function()
			snd:Destroy()
		end)
	end

	local function showReady(r: boolean)
		local b, st = button, stroke
		if r == ready or not (b and st) then
			ready = r
			return
		end
		ready = r
		TweenService:Create(b, READY, {
			BackgroundTransparency = if r then 0.5 else DIM,
			TextTransparency = if r then 0 else DIM,
		}):Play()
		TweenService:Create(st, READY, { Transparency = if r then 0.55 else 0.85 }):Play()
	end

	-- What's in your hand, as the server last said: the button shows only for a tool with a verb.
	local function refresh()
		local slot = player:GetAttribute(Tools.HandAttribute)
		local key = if type(slot) == "number"
			then player:GetAttribute(Tools.slotAttribute(math.clamp(slot, 1, Carry.Slots)))
			else nil
		local row = if type(key) == "string" then Catalog[key] else nil
		holding = if row and row.verb and key then key :: string else ""
		local b = button
		if b then
			b.Text = if row and row.verb then row.verb else ""
			b.Visible = holding ~= ""
		end
	end

	-- Your press.
	local function blow()
		if holding ~= Horn.Key or not alive() then
			return
		end
		local t = os.clock()
		if not Horn.allow(lastBlow, t) then
			return
		end
		lastBlow = t
		local r = useRemote
		if r then
			r:FireServer()
		end
		local model = hornIn(player.Character)
		if model then
			blast(model, 0)
		end
		hand.use(Horn.Up)
		kick(Horn.Kick)
		local s = press
		if s then
			s.Scale = 0.86
			TweenService:Create(s, PRESS, { Scale = 1 }):Play()
		end
		showReady(false)
	end

	local function onAction(
		_: string,
		state: Enum.UserInputState,
		_input: InputObject
	): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin and holding ~= "" then
			blow()
		end
		return Enum.ContextActionResult.Pass
	end

	-- The server stamped `model` as blown: heard here, and the arm that blew it raised.
	local function onBlown(model: Model)
		local stamp = model:GetAttribute(Horn.BlownAttribute)
		if type(stamp) ~= "number" then
			return
		end
		local late = Workspace:GetServerTimeNow() - stamp
		if late > Horn.Fresh then
			return -- an old blast, learnt of late
		end
		local character = model.Parent
		if character == player.Character then
			-- yours: heard and shown as you pressed, unless the server's word came with none
			if lastBlow and os.clock() - lastBlow < Horn.Gap then
				return
			end
			blast(model, late)
			return
		end
		blast(model, late)
		if character and character:IsA("Model") then
			arms[character] = {
				since = os.clock() - math.max(0, late),
				shoulder = joint(character, "LeftUpperArm", "LeftShoulder"),
				elbow = joint(character, "LeftLowerArm", "LeftElbow"),
			}
		end
	end

	-- A tool came into or left someone's hand: watch a horn's blasts while it's carried.
	local function onChild(child: Instance)
		if
			child:IsA("Model")
			and child:GetAttribute(Tools.KindAttribute) == Horn.Key
			and not horns[child]
		then
			horns[child] = child:GetAttributeChangedSignal(Horn.BlownAttribute):Connect(function()
				onBlown(child)
			end)
		end
	end
	local function onChildGone(child: Instance)
		local c = horns[child :: Model]
		if c then
			c:Disconnect()
			horns[child :: Model] = nil
		end
	end
	local function watchCharacter(character: Model)
		table.insert(connections, character.ChildAdded:Connect(onChild))
		table.insert(connections, character.ChildRemoved:Connect(onChildGone))
		for _, c in character:GetChildren() do
			onChild(c)
		end
	end
	local function watchPlayer(p: Player)
		table.insert(connections, p.CharacterAdded:Connect(watchCharacter))
		if p.Character then
			watchCharacter(p.Character)
		end
	end

	-- After other players' animations, before the frame: a friend's arm raised as they blow.
	local function poseArms()
		local now = os.clock()
		for character, a in arms do
			local since = now - a.since
			if since > Horn.Up + Horn.ArmOut or not character.Parent then
				arms[character] = nil
				continue
			end
			local w = Horn.arm(since)
			local s, e = a.shoulder, a.elbow
			if s then
				local from: CFrame = s.Transform
				s.Transform = from:Lerp(CFrame.Angles(Horn.Arm, 0, 0), w)
			end
			if e then
				local from: CFrame = e.Transform
				e.Transform = from:Lerp(CFrame.identity, w)
			end
		end
	end

	-- On a phone, the button sits left of the jump button, sized from it.
	local function placeButton()
		local j, b, g = jump, button, gui
		if not (touch and j and b and g) then
			return
		end
		local touchGui = j:FindFirstAncestorOfClass("ScreenGui")
		if touchGui then
			g.IgnoreGuiInset = touchGui.IgnoreGuiInset
			g.ScreenInsets = touchGui.ScreenInsets
		end
		local size =
			math.clamp(math.round(j.AbsoluteSize.X * BUTTON_OF_JUMP), BUTTON_MIN, BUTTON_MAX)
		b.Size = UDim2.fromOffset(size, size)
		local at = j.AbsolutePosition
		b.Position = UDim2.fromOffset(at.X - size * BUTTON_GAP, at.Y + j.AbsoluteSize.Y / 2)
		g.Enabled = j.Visible
	end

	local function findJump()
		local pg = player:FindFirstChildOfClass("PlayerGui")
		local touchGui = pg and pg:FindFirstChild("TouchGui")
		local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
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

	local system = { name = "HornView" }

	function system.start(_: any, _context: Brix.Context)
		task.spawn(SoundPrimer.prime, { Horn.Blast.id })
		local g, b, sc, st = makeButton()
		gui, button, press, stroke = g, b, sc, st
		touch = UserInputService.TouchEnabled
		if touch then
			g.Parent = player:WaitForChild("PlayerGui")
		else
			-- beside the slots' bar, as the Drop button is on its other side
			hand.beside(b)
			g:Destroy()
			gui = nil
		end
		table.insert(connections, b.Activated:Connect(blow))
		for i = 1, Carry.Slots do
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Tools.slotAttribute(i)):Connect(refresh)
			)
		end
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Tools.HandAttribute):Connect(refresh)
		)
		refresh()
		ContextActionService:BindAction(
			ACTION,
			onAction,
			false,
			Enum.UserInputType.MouseButton1,
			Enum.KeyCode.ButtonL2
		)
		table.insert(connections, Players.PlayerAdded:Connect(watchPlayer))
		for _, p in Players:GetPlayers() do
			watchPlayer(p)
		end
		table.insert(connections, RunService.PreSimulation:Connect(poseArms))
		task.spawn(function()
			local remotes = ReplicatedStorage:WaitForChild(Tools.RemoteFolder, 30)
			local r = remotes and remotes:WaitForChild(Tools.UseRemote, 30)
			if r and r:IsA("RemoteEvent") then
				useRemote = r
			end
		end)
	end

	function system.step(_: any, dt: number)
		if touch then
			findJumpIn -= dt
			if findJumpIn <= 0 then
				findJumpIn = 1
				findJump()
			end
		end
		if not ready and Horn.allow(lastBlow, os.clock()) then
			showReady(true)
		end
	end

	function system.stop(_: any)
		ContextActionService:UnbindAction(ACTION)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, c in horns do
			c:Disconnect()
		end
		table.clear(horns)
		table.clear(arms)
		if button then
			button:Destroy()
			button = nil
		end
		if gui then
			gui:Destroy()
			gui = nil
		end
	end

	return system :: any -- any: a plain Brix system built field by field
end

return HornView
