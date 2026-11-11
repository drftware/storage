--!strict
--[[
	CaughtView: a keeper's catch and getting kept, on the caught player's own screen (L-06b3c,
	L-07a). The server tells only them (Remotes.Caught, from Keepers). Their view jerks
	(CameraShake), the screen drops half dark at once and closes to black, "Caught" comes up in the
	dark through the 2-second wrap, and they can't move. In the black the server stores them in a
	unit (KeptPlayers), so the screen opens on its dark inside, facing the door (the game is
	always first person), and "Wait for a friend" comes up. They stay held, their body not turning
	with the camera, every prompt hidden, until the server lets them out (`Kept.Attribute`
	cleared): then their walk, their turn and the prompts come back. The film the server wraps
	them in (L-07b) is for friends to see: on their own screen it's never drawn, so their view of
	the dark inside stays clear.
	Every number and the curves are `Caught`'s and `Kept`'s. The sting and its sounds are
	L-06b4b's.

	It steps only while a catch is on the screen or they're kept.
]]
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Kept = require(ReplicatedStorage.Shared.Kept)

-- The headline's size (pixels), as the gate's "Going up" (GateClock).
local HEADLINE_SIZE = 34
-- The hint's size (pixels): read at a glance, smaller than a headline.
local HINT_SIZE = 22

type Screen = {
	gui: ScreenGui,
	black: Frame,
	headline: TextLabel,
	stroke: UIStroke,
	hint: TextLabel,
	hintStroke: UIStroke,
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
	-- low on the screen, clear of the thumbs' buttons' height, over the dark of the door
	local hint, hintStroke = label("Hint", HINT_SIZE, 0.78, Kept.Hint)
	gui.Parent = parent
	return {
		gui = gui,
		black = black,
		headline = headline,
		stroke = stroke,
		hint = hint,
		hintStroke = hintStroke,
	}
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

	-- Nothing of the catch left: the screen off, walk and turn back, prompts back.
	local function finish()
		since, awake = -1, -1
		if screen then
			screen.gui.Enabled = false
			screen.hint.TextTransparency, screen.hintStroke.Transparency = 1, 1
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
			screen = makeScreen(player:WaitForChild("PlayerGui"))
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
				-- awake inside: the black gone, "Wait for a friend" coming up
				if awake < 0 then
					awake = 0
				end
				awake += dt
				s.black.BackgroundTransparency = 1
				s.headline.TextTransparency, s.stroke.Transparency = 1, 1
				local clear = 1 - math.min(awake / Kept.HintIn, 1)
				s.hint.TextTransparency, s.hintStroke.Transparency = clear, clear
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
				screen = nil
			end
		end,
	}
end

return CaughtView
