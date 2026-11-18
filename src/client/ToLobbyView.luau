--!strict
--[[
	ToLobbyView: sent down to the lobby, on your own screen (S4-03c4, D-409, shared `ToLobby`).
	Caught on the floor the team picked with the "back to the lobby" card: the keeper's hands close
	and its face rushes you as any catch's do (CaughtView); at the cut to black, where a keep's
	"Caught" would come up, the card's own picture comes up out of the black instead (the shaft
	from above, the car far down it, lit red) with the card's own low hit, and rushes at you,
	faster and faster, the car at its middle filling the screen: you're falling down that shaft.
	It cuts to black on the gate's slam, pitched heavy, with a jolt: you've landed on the car. Once
	the server has stood you in the lobby car (`ToLobby.StoodAttribute`) the black lifts over
	`ToLobby.LiftIn` with the car's ding, your view turned out of its gate to the lobby. No words.
	Then the car hums low from its ceiling while you wait in it for your team (S4-03c4c, D-411),
	until the climb's end clears your mark.

	Over the catch's screen (DisplayOrder 45: CaughtView's is 30) and under the end's (50): if
	you were the last friend caught, the end comes down over the fall and takes you from there.
	It steps only while a fall is on the screen.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local NextFloor = require(ReplicatedStorage.Shared.NextFloor)
local Sounds = require(ReplicatedStorage.Shared.Elevator.Sounds)
local ToLobby = require(ReplicatedStorage.Shared.ToLobby)
local SoundPrimer = require(script.Parent.SoundPrimer)

local ToLobbyView = {}

-- Where the lit car sits in the card's picture (a share of its width and height): the fall
-- rushes at it, so it stays where it was on the card as the picture grows round it.
local CAR = Vector2.new(0.56, 0.46)
-- The landing: the gate's slam, pitched down so it lands heavier than a gate shutting.
local SLAM_PITCH = 0.78
local SLAM_LENGTH = 1.1
local FOLD = Sounds.Sounds["Fold" :: Sounds.SoundName]
local DING = Sounds.Sounds["Ding" :: Sounds.SoundName]

function ToLobbyView.new(kick: (amount: number) -> ()): Brix.System
	local player = Players.LocalPlayer
	local version = NextFloor.find("CaughtToLobby") :: NextFloor.Version
	local connections: { RBXScriptConnection } = {}
	local gui: ScreenGui? = nil
	local black: Frame? = nil
	local picture: ImageLabel? = nil
	local at: number? = nil -- the catch's server time, while a fall is on the screen
	local cut, landed = false, false
	local stoodAt: number? = nil -- os.clock() the black began to lift
	local hum: BasePart? = nil -- the car's hum while you wait in it, from its ceiling

	local function play(id: string, from: number, length: number, volume: number, pitch: number)
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volume
		s.PlaybackSpeed = pitch
		s.TimePosition = from
		s.Parent = SoundService
		s:Play()
		task.delay(length / pitch + 0.2, function()
			s:Destroy()
		end)
	end

	-- The car's hum dies away: the wait is over.
	local function hush()
		local h = hum
		hum = nil
		if not h then
			return
		end
		local sound = h:FindFirstChildOfClass("Sound")
		if sound then
			TweenService:Create(sound, TweenInfo.new(ToLobby.HumOut), { Volume = 0 }):Play()
		end
		task.delay(ToLobby.HumOut + 0.1, function()
			h:Destroy()
		end)
	end

	-- The car you were stood in starts to hum (`stood`, where you were stood in it), coming up
	-- from nothing under the lift, from its ceiling: it's waiting, and so are you.
	local function hold(stood: CFrame)
		hush()
		local h = Instance.new("Part")
		h.Name = "ToLobbyHum"
		h.Anchored = true
		h.CanCollide = false
		h.CanQuery = false
		h.CanTouch = false
		h.Transparency = 1
		h.Size = Vector3.one
		h.CFrame = CFrame.new(stood.Position + Vector3.yAxis * ToLobby.HumUp)
		local sound = Instance.new("Sound")
		sound.SoundId = ToLobby.Hum
		sound.Looped = true
		sound.Volume = 0
		sound.PlaybackSpeed = ToLobby.HumPitch
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = ToLobby.HumNear
		sound.RollOffMaxDistance = ToLobby.HumFar
		sound.Parent = h
		h.Parent = Workspace
		hum = h
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(ToLobby.HumIn), { Volume = ToLobby.HumVolume })
			:Play()
	end

	local function stop()
		at, stoodAt = nil, nil
		local g = gui
		if g then
			g.Enabled = false
		end
	end

	local function onSent()
		local value = player:GetAttribute(ToLobby.Attribute)
		if type(value) ~= "number" then
			stop()
			hush()
			return
		end
		if at == value or not ToLobby.fresh(Workspace:GetServerTimeNow() - value) then
			return
		end
		at, cut, landed, stoodAt = value, false, false, nil
		local g, b, p = gui, black, picture
		if g and b and p then
			b.BackgroundTransparency = 1
			p.ImageTransparency = 1
			g.Enabled = true
		end
	end

	-- The black starts to lift: you're stood in the car, your view turned out of its gate.
	local function lift(stood: unknown)
		stoodAt = os.clock()
		play(DING.Id, DING.Start, DING.Stop - DING.Start, DING.Volume, 1)
		local camera = Workspace.CurrentCamera
		if camera and typeof(stood) == "CFrame" then
			local from = camera.CFrame.Position
			camera.CFrame = CFrame.lookAt(from, from + stood.LookVector)
		end
		if typeof(stood) == "CFrame" then
			hold(stood)
		end
	end

	return {
		name = "ToLobbyView",
		start = function(_: any, _context: Brix.Context)
			local g = Instance.new("ScreenGui")
			g.Name = "ToLobbyView"
			g.DisplayOrder = 45 -- over the catch (30), under the end (50)
			g.IgnoreGuiInset = true
			g.ResetOnSpawn = false
			g.Enabled = false
			local b = Instance.new("Frame")
			b.Name = "Black"
			b.BackgroundColor3 = Color3.new(0, 0, 0)
			b.BorderSizePixel = 0
			b.Size = UDim2.fromScale(1, 1)
			b.Parent = g
			local p = Instance.new("ImageLabel")
			p.Name = "Shaft"
			p.BackgroundTransparency = 1
			p.Image = version.face
			p.ScaleType = Enum.ScaleType.Crop
			p.AnchorPoint = CAR
			p.Position = UDim2.fromScale(CAR.X, CAR.Y)
			p.Size = UDim2.fromScale(1, 1)
			p.ZIndex = 2
			p.Parent = g
			g.Parent = player:WaitForChild("PlayerGui")
			gui, black, picture = g, b, p
			local ids = { version.face, FOLD.Id, DING.Id, ToLobby.Hum }
			for _, h in version.sound do
				table.insert(ids, h.id)
			end
			task.spawn(SoundPrimer.prime, ids)
			table.insert(
				connections,
				player:GetAttributeChangedSignal(ToLobby.Attribute):Connect(onSent)
			)
			onSent()
		end,
		step = function(_: any, _dt: number)
			local value, g, b, p = at, gui, black, picture
			if not (value and g and b and p) then
				return
			end
			local since = Workspace:GetServerTimeNow() - value
			if since >= Caught.Dark and not cut then
				cut = true
				for _, h in version.sound do
					task.delay(h.at, play, h.id, h.from, h.length, h.volume, h.pitch)
				end
			end
			if since >= ToLobby.Land and not landed then
				landed = true
				play(FOLD.Id, Sounds.FoldSlam - 0.04, SLAM_LENGTH, FOLD.Volume, SLAM_PITCH)
				kick(ToLobby.Jolt)
			end
			local stood = player:GetAttribute(ToLobby.StoodAttribute)
			if not stoodAt and landed and (stood ~= nil or since >= ToLobby.Most) then
				lift(stood)
			end
			local shown, size, dark = ToLobby.fall(since)
			p.ImageTransparency = 1 - shown
			p.Size = UDim2.fromScale(size, size)
			local s = stoodAt
			if s then
				local t = os.clock() - s
				dark = ToLobby.lift(t)
				if t >= ToLobby.LiftIn then
					stop()
					return
				end
			end
			b.BackgroundTransparency = 1 - dark
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			stop()
			hush()
		end,
	} :: Brix.System
end

return ToLobbyView
