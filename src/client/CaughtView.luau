--!strict
--[[
	CaughtView: a keeper's catch on the caught player's own screen (L-06b3c). The server tells
	only them (Remotes.Caught, from Keepers). Their view jerks (CameraShake), the screen drops half
	dark at once and closes to black, "Caught" comes up in the dark, and they can't move until it
	opens again (on the lobby, by the stand-in until L-07). Every number and the curves are
	`Caught`'s. The sting and its sounds are L-06b4b's.

	It steps only while a catch is on the screen.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)

-- The headline's size (pixels), as the gate's "Going up" (GateClock).
local HEADLINE_SIZE = 34

type Screen = { gui: ScreenGui, black: Frame, headline: TextLabel, stroke: UIStroke }

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
	local headline = Instance.new("TextLabel")
	headline.Name = "Headline"
	headline.AnchorPoint = Vector2.new(0.5, 0.5)
	headline.Position = UDim2.fromScale(0.5, 0.45)
	headline.Size = UDim2.new(0.9, 0, 0, HEADLINE_SIZE + 12)
	headline.BackgroundTransparency = 1
	headline.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	headline.TextSize = HEADLINE_SIZE
	headline.TextColor3 = Color3.fromRGB(214, 206, 196)
	headline.TextTransparency = 1
	headline.Text = "Caught"
	headline.ZIndex = 2
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = headline
	headline.Parent = gui
	gui.Parent = parent
	return { gui = gui, black = black, headline = headline, stroke = stroke }
end

-- Who's held still, and their own walk and jump to give back. Held by the Humanoid's own walk
-- and jump set to 0 on this screen, which owns the character's movement: the PlayerModule's
-- switches don't hold it any more (docs/STUDIO.md).
type Held = { humanoid: Humanoid, walk: number, jumpHeight: number, jumpPower: number }

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
	}
	humanoid.WalkSpeed, humanoid.JumpHeight, humanoid.JumpPower = 0, 0, 0
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
end

local CaughtView = {}

-- The system; `kick` jerks the view (CameraShake's).
function CaughtView.new(kick: (amount: number) -> ()): Brix.System
	local screen: Screen? = nil
	local since = -1 -- seconds since the catch on screen, or -1 with none
	local held: Held? = nil -- held still while the catch is on screen
	local running = false
	local connection: RBXScriptConnection? = nil

	local function finish()
		since = -1
		if screen then
			screen.gui.Enabled = false
		end
		if held then
			letGo(held)
			held = nil
		end
	end

	local function onCaught()
		since = 0
		kick(Caught.Kick)
		if not held then
			held = hold()
		end
		if screen then
			screen.gui.Enabled = true
		end
	end

	return {
		name = "CaughtView",
		start = function(_: any, _context: Brix.Context)
			running = true
			screen = makeScreen(Players.LocalPlayer:WaitForChild("PlayerGui"))
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Caught.RemoteFolder, 30)
				local remote = folder and folder:WaitForChild(Caught.Remote, 30)
				if running and remote and remote:IsA("RemoteEvent") then
					connection = remote.OnClientEvent:Connect(onCaught)
				end
			end)
		end,
		step = function(_: any, dt: number)
			if since < 0 then
				return
			end
			since += dt
			local s = screen
			if not Caught.showing(since) then
				finish()
			elseif s then
				s.black.BackgroundTransparency = 1 - Caught.blackout(since)
				local clear = 1 - Caught.headline(since)
				s.headline.TextTransparency = clear
				s.stroke.Transparency = clear
			end
		end,
		stop = function(_: any)
			running = false
			if connection then
				connection:Disconnect()
				connection = nil
			end
			finish()
			if screen then
				screen.gui:Destroy()
				screen = nil
			end
		end,
	}
end

return CaughtView
