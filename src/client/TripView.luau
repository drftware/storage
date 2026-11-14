--!strict
--[[
	TripView: the black as a lobby car takes your group to a server of its own (L-08e1c), and the
	climb opening out of it there, as if the ride had never stopped.

	- On a lobby: riding a car that's taking its group away (`Trip.Attribute` on it, you aboard),
	  the cover fades in from `Trip.FadeAt` into the ride, "Going up" under the black, before the
	  server sends you. Its opaque twin is the teleport's own screen (SetTeleportGui), so the black
	  carries across. If the car comes back for you instead (the trip failed), the cover fades off
	  at once and the panel says why (CarPanel's "Teleport failed").
	- On a group's own server (Workspace's `Trip.OwnAttribute`): you arrive under the black
	  (ReplicatedFirst's TripCover kept it from the trip, or it's laid at once). When the server
	  stands you in the climb (`Trip.ArrivedAttribute`: where it stood you), your camera turns the
	  way you were stood and the cover fades off on the shaft sliding past the gate.
	- Sent on to a friend (L-08e3b): you joined a lobby by an invite from a friend on their group's
	  own server, and the server is sending you on (`Trip.FollowAttribute` on you, their name).
	  The black comes down at once, "Joining Sam" under it, and carries across the teleport, so
	  you open beside them. If it fails for good, "Teleport failed" under the black, then it lifts.
	- It never covers a screen for more than `Trip.CoverMost`.

	Nothing runs per frame but the three-frame camera turn as the cover lifts.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Trip = require(ReplicatedStorage.Shared.Lobby.Trip)

-- The cover's name in PlayerGui: ReplicatedFirst's TripCover keeps an arriving one under it.
local COVER = "TripCover"
local INK = Color3.fromRGB(232, 226, 214) -- warm off-white, the game's ink (FreeCursor's hint)
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local TEXT_SIZE = 20
-- How faint "Going up" sits on the black: there, not shouting.
local TEXT_SHOWN = 0.35
-- Studs from where the server stood you within which your character has been moved there on
-- this screen; seconds to wait for that at most before lifting the cover anyway.
local THERE = 8
local THERE_MOST = 2
-- Seconds to wait at most for the server's ready remote on a group's own server (it's made as
-- the server becomes one, before it says so).
local READY_WAIT = 20
-- Frames the camera is turned on as the cover lifts, so a camera that resets a frame late still
-- ends up facing the way you were stood (as LobbyView's turn).
local TURN_FRAMES = 3
local BIND = "TripViewTurn"

type Cover = { gui: ScreenGui, black: Frame, text: TextLabel }

-- A cover: a full-screen black over everything, "Going up" low in the middle; `shown` lays it
-- opaque, else clear.
local function makeCover(shown: boolean): Cover
	local gui = Instance.new("ScreenGui")
	gui.Name = COVER
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000 -- over every screen of ours, the end's included
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local black = Instance.new("Frame")
	black.Name = "Black"
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BorderSizePixel = 0
	black.BackgroundTransparency = if shown then 0 else 1
	black.Active = shown -- swallows taps while it's up
	black.Parent = gui
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.AnchorPoint = Vector2.new(0.5, 1)
	text.Position = UDim2.new(0.5, 0, 1, -56)
	text.Size = UDim2.new(1, -32, 0, TEXT_SIZE + 8)
	text.BackgroundTransparency = 1
	text.FontFace = BOLD
	text.TextSize = TEXT_SIZE
	text.TextColor3 = INK
	text.Text = Trip.CoverText
	text.TextTransparency = if shown then TEXT_SHOWN else 1
	text.Parent = black
	return { gui = gui, black = black, text = text }
end

-- The cover ReplicatedFirst kept from the trip, if it's ours and whole.
local function arrivingCover(playerGui: Instance): Cover?
	local gui = playerGui:FindFirstChild(COVER)
	local black = gui and gui:FindFirstChild("Black")
	local text = black and black:FindFirstChild("Text")
	if
		gui
		and gui:IsA("ScreenGui")
		and black
		and black:IsA("Frame")
		and text
		and text:IsA("TextLabel")
	then
		return { gui = gui, black = black, text = text }
	end
	return nil
end

local TripView = {}

function TripView.new(): Brix.System
	local player = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local cars: { [Model]: { RBXScriptConnection } } = {}
	local cover: Cover? = nil
	local twin: Cover? = nil -- the teleport's own screen: always black
	local going: Model? = nil -- the car taking you away
	local token = 0 -- the latest fade; an older one's wait stops when it sees another
	local own = false
	local lifting = false
	local followed = false -- being sent on to a friend's group

	local function fade(to: number, seconds: number)
		local c = cover
		if not c then
			return
		end
		token += 1
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		TweenService:Create(c.black, info, { BackgroundTransparency = 1 - to }):Play()
		TweenService:Create(c.text, info, { TextTransparency = 1 - to * (1 - TEXT_SHOWN) }):Play()
		c.black.Active = to > 0
	end

	-- Off the screen: the cover fades away.
	local function lift(seconds: number)
		going = nil
		fade(0, seconds)
	end

	-- A lobby car's ride or trip changed: the black comes down as it takes you away, and lifts if
	-- it comes back for you.
	local function check(model: Model)
		local trip = model:GetAttribute(Trip.Attribute) == true
		local leftAt, ids = Departure.decodeAboard(model:GetAttribute(Departure.AboardAttribute))
		local mine = leftAt ~= nil and table.find(ids, player.UserId) ~= nil
		if trip and mine and going ~= model and leftAt then
			going = model
			local c, t = cover, twin
			if c then
				c.text.Text = Trip.CoverText
			end
			if t then
				t.text.Text = Trip.CoverText
				-- set again for each trip: Roblox keeps it for one teleport
				pcall(function()
					TeleportService:SetTeleportGui(t.gui)
				end)
			end
			token += 1
			local mineToken = token
			local wait = leftAt + Trip.FadeAt - Workspace:GetServerTimeNow()
			task.delay(math.max(wait, 0), function()
				if token == mineToken and going == model then
					fade(1, Trip.Fade)
				end
			end)
			-- still here long after the send, with no word: lift it (the server's give-up says why)
			local most = leftAt + Trip.Send + Trip.GiveUp + 5 - Workspace:GetServerTimeNow()
			task.delay(math.max(most, 0), function()
				if going == model then
					lift(Trip.Reveal)
				end
			end)
		elseif going == model and not trip then
			lift(Trip.Reveal * 0.5)
		end
	end

	local function addCar(inst: Instance)
		if
			not inst:IsA("Model")
			or cars[inst]
			or inst:GetAttribute(Boarding.CarAttribute) == nil
		then
			return
		end
		local model = inst :: Model
		cars[model] = {
			model:GetAttributeChangedSignal(Trip.Attribute):Connect(function()
				check(model)
			end),
			model:GetAttributeChangedSignal(Departure.AboardAttribute):Connect(function()
				check(model)
			end),
		}
		check(model)
	end

	local function removeCar(inst: Instance)
		local list = cars[inst :: Model]
		if list then
			for _, c in list do
				c:Disconnect()
			end
			cars[inst :: Model] = nil
		end
	end

	-- You're being sent on to a friend's group (their name on you), or that failed (it's gone).
	local function following()
		local name = player:GetAttribute(Trip.FollowAttribute)
		local c = cover
		if not c then
			return
		end
		if type(name) == "string" then
			if followed then
				return
			end
			followed = true
			local line = Trip.followText(name)
			c.text.Text = line
			local t = twin
			if t then
				t.text.Text = line
				pcall(function()
					TeleportService:SetTeleportGui(t.gui)
				end)
			end
			fade(1, Trip.Fade)
			-- still here long after every try, with no word: lift it
			task.delay(Trip.Fade + (Trip.GiveUp + 3) * Trip.Tries, function()
				if followed then
					followed = false
					lift(Trip.Reveal)
				end
			end)
		elseif followed then
			followed = false
			c.text.Text = Trip.FailedText
			token += 1
			local mine = token
			task.delay(Trip.FailedHold, function()
				if token == mine then
					lift(Trip.Reveal)
				end
			end)
		end
	end

	-- The server stood you in the climb at `at`: the camera turns that way and the cover lifts.
	local function arrived(at: CFrame)
		if lifting then
			return
		end
		lifting = true
		task.spawn(function()
			local until_ = os.clock() + THERE_MOST
			while os.clock() < until_ do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if
					root
					and root:IsA("BasePart")
					and (root.Position - at.Position).Magnitude <= THERE
				then
					break
				end
				task.wait()
			end
			local look = Vector3.new(at.LookVector.X, 0, at.LookVector.Z)
			if look.Magnitude > 1e-3 then
				local frames = TURN_FRAMES
				RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, function()
					local camera = Workspace.CurrentCamera
					if camera then
						local eye = camera.CFrame.Position
						camera.CFrame = CFrame.lookAt(eye, eye + look.Unit)
					end
					frames -= 1
					if frames <= 0 then
						RunService:UnbindFromRenderStep(BIND)
					end
				end)
			end
			lift(Trip.Reveal)
		end)
	end

	-- This is a group's own server: you're under the black until the server stands you in it.
	local function becomeOwn(playerGui: Instance)
		if own then
			return
		end
		own = true
		local c = arrivingCover(playerGui) or makeCover(true)
		c.black.BackgroundTransparency = 0
		c.black.Active = true
		c.text.TextTransparency = TEXT_SHOWN
		c.gui.Parent = playerGui
		cover = c
		-- tell the server once this screen has loaded, so it stands the group in the car only
		-- when this screen can show the last of the ride
		task.spawn(function()
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end
			local remotes = ReplicatedStorage:WaitForChild(Trip.RemoteFolder, READY_WAIT)
			local r = remotes and remotes:WaitForChild(Trip.ReadyRemote, READY_WAIT)
			if r and r:IsA("RemoteEvent") then
				r:FireServer()
			end
		end)
		local function seen()
			local at = player:GetAttribute(Trip.ArrivedAttribute)
			if typeof(at) == "CFrame" then
				arrived(at)
			end
		end
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Trip.ArrivedAttribute):Connect(seen)
		)
		seen()
		task.delay(Trip.CoverMost, function()
			if not lifting then
				lifting = true
				lift(Trip.Reveal)
			end
		end)
	end

	return {
		name = "TripView",
		start = function(_: any, _context: Brix.Context)
			local playerGui = player:WaitForChild("PlayerGui")
			if Workspace:GetAttribute(Trip.OwnAttribute) == true then
				becomeOwn(playerGui)
				return
			end
			-- a cover that came with a teleport onto a lobby: off it goes
			local stray = arrivingCover(playerGui)
			if stray then
				cover = stray
				lift(Trip.Reveal)
			end
			-- Studio's test teleports make a server a group's own as its first player arrives
			table.insert(
				connections,
				Workspace:GetAttributeChangedSignal(Trip.OwnAttribute):Connect(function()
					if Workspace:GetAttribute(Trip.OwnAttribute) == true then
						becomeOwn(playerGui)
					end
				end)
			)
			local c = makeCover(false)
			c.gui.Parent = playerGui
			cover = c
			twin = makeCover(true)
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Trip.FollowAttribute):Connect(following)
			)
			following()
			for _, inst in CollectionService:GetTagged(Elevator.Tag) do
				addCar(inst)
			end
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(addCar)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(removeCar)
			)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in cars do
				removeCar(model)
			end
			pcall(function()
				RunService:UnbindFromRenderStep(BIND)
			end)
			if cover then
				cover.gui:Destroy()
				cover = nil
			end
			if twin then
				twin.gui:Destroy()
				twin = nil
			end
		end,
	}
end

return TripView
