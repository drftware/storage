--!strict
--[[
	CaughtView: a keeper's catch and getting kept, on the caught player's own screen (L-06b3c,
	L-07a). The server tells only them (Remotes.Caught, from Keepers). Their view jerks
	(CameraShake), the screen drops half dark at once and closes to black, "Caught" comes up in the
	dark through the 2-second wrap, and they can't move. In the black the server stores them in a
	unit (KeptPlayers), so the screen opens on its dark inside, facing the door (the game is
	always first person), and a big Bang button comes up (L-07c): on a phone under the right
	thumb, elsewhere low in the middle with its key under it (a click, Space, a gamepad's A or R2).
	Each press jolts the view at once and asks the server to bang the door (`Remotes.Bang`); the
	door's thud and shake come back from the server. Presses faster than a bang can land wait for
	the next (one held, as a fighting game buffers an input), so mashing hammers at the door's own
	pace. They stay held, their body not turning with the camera, every prompt hidden, until the
	server lets them out (`Kept.Attribute` cleared): then their walk, their turn and the prompts
	come back. The film the server wraps
	them in (L-07b) is for friends to see: on their own screen it's never drawn, so their view of
	the dark inside stays clear.
	Every number and the curves are `Caught`'s and `Kept`'s. The sting and its sounds are
	L-06b4b's.

	It steps only while a catch is on the screen or they're kept.
]]
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Kept = require(ReplicatedStorage.Shared.Kept)

-- The headline's size (pixels), as the gate's "Going up" (GateClock).
local HEADLINE_SIZE = 34

-- The Bang button: the horn's round button, bigger, as the one thing to do in the dark.
local ACTION = "KeptBang"
local INK = Color3.fromRGB(232, 226, 214) -- the buttons' warm off-white
local BUTTON_SEE = 0.45 -- its dark background's transparency, fully in
local RING_SEE = 0.35 -- its ring's
local PHONE_SIDE = 0.27 -- on a phone, its side as a share of the screen's height: a thumb's pad
local PHONE_MIN, PHONE_MAX = 96, 140 -- points
local PHONE_EDGE = 0.045 -- of the screen's width, in from the right and up from the bottom
local DESK_SIDE = 0.14 -- elsewhere, a share of the height: a target to read, not to thumb
local DESK_MIN, DESK_MAX = 76, 104
local BUTTON_LOW = 0.76 -- elsewhere, its foot as a share of the screen's height: its key clear of the slots' bar
local CAPTION_SIZE = 18
local PRESS = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PRESSED = 0.84 -- the button's scale at a press, springing back

type Screen = {
	gui: ScreenGui,
	black: Frame,
	headline: TextLabel,
	stroke: UIStroke,
	bangGui: ScreenGui, -- its own, within the phone's safe area, over the black
	holder: Frame, -- the button and its key under it, placed together
	button: TextButton,
	ring: UIStroke,
	pop: UIScale,
	caption: TextLabel,
}

local function makeScreen(parent: Instance): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "Caught"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 30 -- over everything, the gate's fade included
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	local black = Instance.new("Frame")
	black.Name = "Black"
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BackgroundTransparency = 1
	black.BorderSizePixel = 0
	black.Active = false
	black.ZIndex = 1
	black.Parent = gui
	local function label(name: string, size: number, y: number, text: string): (TextLabel, UIStroke)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, y)
		l.Size = UDim2.new(0.9, 0, 0, size + 12)
		l.BackgroundTransparency = 1
		l.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		l.TextSize = size
		l.TextColor3 = Color3.fromRGB(214, 206, 196)
		l.TextTransparency = 1
		l.Text = text
		l.ZIndex = 2
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 2
		stroke.Transparency = 1
		stroke.Parent = l
		l.Parent = gui
		return l, stroke
	end
	local headline, stroke = label("Headline", HEADLINE_SIZE, 0.45, "Caught")
	gui.Parent = parent

	local bangGui = Instance.new("ScreenGui")
	bangGui.Name = "Bang"
	bangGui.ResetOnSpawn = false
	bangGui.DisplayOrder = 31
	bangGui.Enabled = false
	local holder = Instance.new("Frame")
	holder.Name = "Bang"
	holder.BackgroundTransparency = 1
	holder.Parent = bangGui
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.fromScale(1, 1)
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.new(0, 0, 0)
	button.Font = Enum.Font.GothamBold
	button.Text = "Bang"
	button.TextColor3 = INK
	button.TextScaled = true
	button.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.2, 0), UDim.new(0.2, 0)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.33, 0), UDim.new(0.33, 0)
	pad.Parent = button
	local ring = Instance.new("UIStroke")
	ring.Color = INK
	ring.Thickness = 3
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Parent = button
	local pop = Instance.new("UIScale")
	pop.Parent = button
	-- the key, under the button where there's no thumb to press it (beside the button, not in
	-- it: the button's padding would pull it inside)
	local caption = Instance.new("TextLabel")
	caption.Name = "Key"
	caption.AnchorPoint = Vector2.new(0.5, 0)
	caption.Position = UDim2.new(0.5, 0, 1, 6)
	caption.Size = UDim2.fromOffset(160, CAPTION_SIZE + 6)
	caption.BackgroundTransparency = 1
	caption.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	caption.TextSize = CAPTION_SIZE
	caption.TextColor3 = INK
	caption.Parent = holder
	bangGui.Parent = parent
	return {
		gui = gui,
		black = black,
		headline = headline,
		stroke = stroke,
		bangGui = bangGui,
		holder = holder,
		button = button,
		ring = ring,
		pop = pop,
		caption = caption,
	}
end

-- The Bang button's place and size for this screen: under the right thumb on a phone, low in
-- the middle elsewhere, with its key under it.
local function placeButton(s: Screen, touch: boolean)
	local camera = Workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local b = s.holder
	if touch then
		local side = math.clamp(math.round(view.Y * PHONE_SIDE), PHONE_MIN, PHONE_MAX)
		local edge = math.round(view.X * PHONE_EDGE)
		b.AnchorPoint = Vector2.new(1, 1)
		b.Position = UDim2.new(1, -edge, 1, -edge)
		b.Size = UDim2.fromOffset(side, side)
	else
		local side = math.clamp(math.round(view.Y * DESK_SIDE), DESK_MIN, DESK_MAX)
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.Position = UDim2.fromScale(0.5, BUTTON_LOW)
		b.Size = UDim2.fromOffset(side, side)
	end
end

-- The key under the button for the input in use: none for a thumb.
local function keyFor(input: Enum.UserInputType): string
	if input == Enum.UserInputType.Touch then
		return ""
	elseif string.find(input.Name, "Gamepad") then
		return "A"
	end
	return "Click"
end

-- The button's look `level` of the way in (0 out, 1 in).
local function showButton(s: Screen, level: number)
	local out = 1 - level
	s.button.BackgroundTransparency = BUTTON_SEE + (1 - BUTTON_SEE) * out
	s.button.TextTransparency = out
	s.ring.Transparency = RING_SEE + (1 - RING_SEE) * out
	s.caption.TextTransparency = out
end

-- Who's held still, and their own walk, jump and turn to give back. Held by the Humanoid's own
-- walk and jump set to 0 on this screen, which owns the character's movement: the PlayerModule's
-- switches don't hold it any more (docs/STUDIO.md). Its turn with the camera is off too, so a
-- kept body stays facing the door the server stood it at while you look round.
type Held = {
	humanoid: Humanoid,
	walk: number,
	jumpHeight: number,
	jumpPower: number,
	autoRotate: boolean,
}

local function hold(): Held?
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local held = {
		humanoid = humanoid,
		walk = humanoid.WalkSpeed,
		jumpHeight = humanoid.JumpHeight,
		jumpPower = humanoid.JumpPower,
		autoRotate = humanoid.AutoRotate,
	}
	humanoid.WalkSpeed, humanoid.JumpHeight, humanoid.JumpPower = 0, 0, 0
	humanoid.AutoRotate = false
	return held
end

-- Gives back their walk and jump, unless something else set them meanwhile (a heavy tool's pace,
-- from the server).
local function letGo(held: Held)
	local humanoid = held.humanoid
	if humanoid.WalkSpeed == 0 then
		humanoid.WalkSpeed = held.walk
	end
	if humanoid.JumpHeight == 0 then
		humanoid.JumpHeight = held.jumpHeight
	end
	if humanoid.JumpPower == 0 then
		humanoid.JumpPower = held.jumpPower
	end
	humanoid.AutoRotate = held.autoRotate
end

-- Turns the camera the way your body faces: where the server stood you, facing the door.
local function faceTheDoor()
	local cam = Workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if cam and root and root:IsA("BasePart") then
		local at = cam.CFrame.Position
		cam.CFrame = CFrame.lookAt(at, at + root.CFrame.LookVector)
	end
end

local CaughtView = {}

-- The system; `kick` jerks the view (CameraShake's).
function CaughtView.new(kick: (amount: number) -> ()): Brix.System
	local player = Players.LocalPlayer
	local screen: Screen? = nil
	local since = -1 -- seconds since the catch on screen, or -1 with none
	local kept = false -- the server has us kept (`Kept.Attribute`)
	local awake = -1 -- seconds since the screen opened on the unit's inside, or -1
	local held: Held? = nil -- held still while the catch is on screen or we're kept
	local wrap: BasePart? = nil -- the film round us while we're kept, once it's on
	local running = false
	local connections: { RBXScriptConnection } = {}
	local bangRemote: RemoteEvent? = nil
	local touch = false
	local bound = false -- the Bang keys are bound
	local lastBang: number? = nil -- os.clock of our last bang sent
	local queued = false -- a press waiting for the next bang

	-- Bangs now: the view jolts, the button springs, and the server is asked.
	local function bang()
		lastBang, queued = os.clock(), false
		local r = bangRemote
		if r then
			r:FireServer()
		end
		kick(Kept.BangKick)
		local s = screen
		if s then
			s.pop.Scale = PRESSED
			TweenService:Create(s.pop, PRESS, { Scale = 1 }):Play()
		end
	end

	-- A press of the button or a key: it bangs if a bang can land now, else waits for the next.
	local function press()
		if not (kept and since < 0 and awake >= 0) then
			return
		end
		if Kept.ready(lastBang, os.clock()) then
			bang()
		else
			queued = true
		end
	end

	local function onAction(
		_: string,
		state: Enum.UserInputState,
		_input: InputObject
	): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin then
			press()
		end
		return Enum.ContextActionResult.Sink
	end

	-- Nothing of the catch left: the screen off, walk and turn back, prompts back.
	local function finish()
		since, awake = -1, -1
		queued = false
		if bound then
			bound = false
			ContextActionService:UnbindAction(ACTION)
		end
		if screen then
			screen.gui.Enabled = false
			screen.bangGui.Enabled = false
			showButton(screen, 0)
		end
		if held then
			letGo(held)
			held = nil
		end
		wrap = nil
		ProximityPromptService.Enabled = true
	end

	local function onCaught()
		since, awake = 0, -1
		kick(Caught.Kick)
		if not held then
			held = hold()
		end
		if screen then
			screen.gui.Enabled = true
		end
	end

	local function onKept()
		local now = player:GetAttribute(Kept.Attribute) == true
		if now == kept then
			return
		end
		kept = now
		if kept then
			-- no prompt answers a wrapped player; hide them so none is offered either
			ProximityPromptService.Enabled = false
			if not held then
				held = hold()
			end
		elseif since < 0 then
			finish()
		end
	end

	return {
		name = "CaughtView",
		start = function(_: any, _context: Brix.Context)
			running = true
			local s = makeScreen(player:WaitForChild("PlayerGui"))
			screen = s
			touch = UserInputService.TouchEnabled
			placeButton(s, touch)
			showButton(s, 0)
			s.caption.Text = keyFor(UserInputService:GetLastInputType())
			table.insert(connections, s.button.Activated:Connect(press))
			table.insert(
				connections,
				UserInputService.LastInputTypeChanged:Connect(function(input: Enum.UserInputType)
					s.caption.Text = keyFor(input)
				end)
			)
			local camera = Workspace.CurrentCamera
			if camera then
				table.insert(
					connections,
					camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
						placeButton(s, touch)
					end)
				)
			end
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Kept.Attribute):Connect(onKept)
			)
			onKept()
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Caught.RemoteFolder, 30)
				local remote = folder and folder:WaitForChild(Caught.Remote, 30)
				if running and remote and remote:IsA("RemoteEvent") then
					table.insert(connections, remote.OnClientEvent:Connect(onCaught))
				end
				local bangs = folder and folder:WaitForChild(Kept.BangRemote, 30)
				if running and bangs and bangs:IsA("RemoteEvent") then
					bangRemote = bangs
				end
			end)
		end,
		step = function(_: any, dt: number)
			local s = screen
			if since >= 0 then
				since += dt
				local lifts = Caught.Dark + Caught.Hold
				if kept and since >= Caught.Dark and since <= lifts then
					faceTheDoor() -- in the black, where the server has put us by now
				end
				if not Caught.showing(since) then
					since = -1
					if not kept then
						finish()
						return
					end
					awake = 0
				elseif s then
					s.black.BackgroundTransparency = 1 - Caught.blackout(since)
					local clear = 1 - Caught.headline(since)
					s.headline.TextTransparency = clear
					s.stroke.Transparency = clear
				end
			end
			if kept then
				-- the film the server wrapped us in: never drawn on our own screen. Every frame,
				-- as the camera's own first-person fade writes this too
				local w = wrap
				if not (w and w.Parent) then
					local character = player.Character
					local found = character and character:FindFirstChild(Kept.Wrap)
					w = if found and found:IsA("BasePart") then found else nil
					wrap = w
				end
				if w and w.LocalTransparencyModifier ~= 1 then
					w.LocalTransparencyModifier = 1
				end
			end
			if since < 0 and kept and s then
				-- awake inside: the black gone, the Bang button coming up
				if awake < 0 then
					awake = 0
				end
				if not bound then
					bound = true
					s.bangGui.Enabled = true
					ContextActionService:BindActionAtPriority(
						ACTION,
						onAction,
						false,
						Enum.ContextActionPriority.High.Value,
						Enum.UserInputType.MouseButton1,
						Enum.KeyCode.Space,
						Enum.KeyCode.ButtonA,
						Enum.KeyCode.ButtonR2
					)
				end
				if awake <= Kept.BangIn then
					s.black.BackgroundTransparency = 1
					s.headline.TextTransparency, s.stroke.Transparency = 1, 1
					showButton(s, math.min((awake + dt) / Kept.BangIn, 1))
				end
				awake += dt
				if queued and Kept.ready(lastBang, os.clock()) then
					bang()
				end
			end
		end,
		stop = function(_: any)
			running = false
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			finish()
			if screen then
				screen.gui:Destroy()
				screen.bangGui:Destroy()
				screen = nil
			end
		end,
	}
end

return CaughtView
