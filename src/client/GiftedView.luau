--!strict
--[[
	GiftedView: a friend grew your home (S5-03h3b2, D-344). The moment, as Pet Simulator's and
	Adopt Me's gifts land: wherever you stand, the steel's roll starts, a banner drops in at the top
	of your screen with your friend's face and a little wrapped gift on it, "More room!" and their
	name under it; the roll lands on the knock, the banner bounces, holds, and eases away. Your
	walls growing in front of you is S5-03h6's; here the arrival is the whole of it.

	The server tells you only once your save holds the new size and your home is set up at it
	(`Grow.GiftedRemote`: the size, the giver's UserId and their name, each read as untrusted).
	This view listens from boot, so no gift waits for a screen to be opened. A second gift landing
	while one shows takes its place.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local GiftMark = require(script.Parent.GiftMark)
local Grow = require(ReplicatedStorage.Shared.Home.Grow)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Shop = require(ReplicatedStorage.Shared.Shop)
local SoundPrimer = require(script.Parent.SoundPrimer)

local INK = Lobby.Ink
local INK_WARM = Color3.fromRGB(CutFree.Ink.r, CutFree.Ink.g, CutFree.Ink.b)
local GOLD = Color3.fromRGB(240, 196, 92) -- the Units tab's gold: money and "More room!"
local CARD = Color3.fromRGB(40, 35, 31) -- the shop's card: the home's calm
local WELL = Color3.fromRGB(12, 12, 14)
local NAME_MAX = 32 -- a display name is at most 20; anything longer isn't one

local DROP = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local LIFT = TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BOUNCE = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local GiftedView = {}

function GiftedView.new(): Brix.System
	local gui: ScreenGui? = nil
	local banner: Frame? = nil
	local pop: UIScale? = nil
	local face: ImageLabel? = nil
	local from: TextLabel? = nil
	local roll: Sound? = nil
	local knock: Sound? = nil
	local link: RBXScriptConnection? = nil
	local shown = 0 -- which arrival is on screen, so an older one's timers leave a newer alone
	local alive = true

	local function sound(spec: typeof(Shop.GrowRoll), parent: Instance): Sound
		local s = Instance.new("Sound")
		s.SoundId = spec.id
		s.Volume = spec.volume
		s.PlaybackSpeed = spec.pitch or 1
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
		s.Parent = parent
		return s
	end

	-- The banner, built once: a dark pill hung under the top bar, the face at its left.
	local function build(): Frame
		local g = Instance.new("ScreenGui")
		g.Name = "Gifted"
		g.ResetOnSpawn = false
		g.DisplayOrder = 30 -- over the shop, should the gift land while it's open
		g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		gui = g

		local b = Instance.new("Frame")
		b.Name = "Banner"
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.BackgroundColor3 = CARD
		b.BackgroundTransparency = 0.04
		b.BorderSizePixel = 0
		b.Visible = false
		b.Parent = g
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = b
		local rim = Instance.new("UIStroke")
		rim.Color = GOLD
		rim.Thickness = 2
		rim.Transparency = 0.15
		rim.Parent = b
		local s = Instance.new("UIScale")
		s.Parent = b
		pop = s

		local f = Instance.new("ImageLabel")
		f.Name = "Face"
		f.AnchorPoint = Vector2.new(0, 0.5)
		f.Position = UDim2.new(0, 6, 0.5, 0)
		f.Size = UDim2.new(1, -12, 1, -12)
		f.SizeConstraint = Enum.SizeConstraint.RelativeYY
		f.BackgroundColor3 = WELL
		f.Parent = b
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0.5, 0)
		fc.Parent = f
		local ring = Instance.new("UIStroke")
		ring.Color = GOLD
		ring.Thickness = 1.5
		ring.Parent = f
		face = f

		-- the wrapped gift on the face's corner: whose face this is, and why
		local badge = Instance.new("Frame")
		badge.Name = "Badge"
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.fromScale(0.86, 0.84)
		badge.Size = UDim2.fromScale(0.46, 0.46)
		badge.BackgroundColor3 = CARD
		badge.ZIndex = 2
		badge.Parent = f
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0.5, 0)
		bc.Parent = badge
		local inner = Instance.new("Frame")
		inner.BackgroundTransparency = 1
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.Position = UDim2.fromScale(0.5, 0.52)
		inner.Size = UDim2.fromScale(0.66, 0.66)
		inner.ZIndex = 2
		inner.Parent = badge
		GiftMark.new(inner, 3).paint(GOLD, INK_WARM)

		local headline = Instance.new("TextLabel")
		headline.Name = "Headline"
		headline.BackgroundTransparency = 1
		headline.AnchorPoint = Vector2.new(0, 0)
		headline.Position = UDim2.fromScale(0.3, 0.12)
		headline.Size = UDim2.fromScale(0.64, 0.46)
		headline.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
		headline.TextScaled = true
		headline.TextXAlignment = Enum.TextXAlignment.Left
		headline.TextColor3 = GOLD
		headline.Text = Shop.Words.grown
		headline.Parent = b

		local name = Instance.new("TextLabel")
		name.Name = "From"
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromScale(0.3, 0.56)
		name.Size = UDim2.fromScale(0.64, 0.3)
		name.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = INK
		name.TextTransparency = 0.15
		name.Parent = b
		from = name

		roll = sound(Shop.GrowRoll, g)
		knock = sound(Shop.GrowKnock, g)
		banner = b
		return b
	end

	-- The banner for this screen's size: a thumb's height on a phone, never wider than the screen.
	local function fit(b: Frame)
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local tall = math.floor(math.clamp(view.Y * 0.17, 52, 84))
		b.Size = UDim2.fromOffset(math.min(math.floor(tall * 4.1), math.floor(view.X - 24)), tall)
	end

	local function arrive(size: unknown, giverId: unknown, giverName: unknown)
		local name = Grow.ask(size)
		local id = Grow.friendId(giverId)
		if not (alive and name and id) or (giverName ~= nil and type(giverName) ~= "string") then
			return
		end
		local who = if type(giverName) == "string" then string.sub(giverName, 1, NAME_MAX) else ""
		local b = banner or build()
		local s, f, n = pop :: UIScale, face :: ImageLabel, from :: TextLabel
		local r, k = roll :: Sound, knock :: Sound
		shown += 1
		local mine = shown
		fit(b)
		f.Image = `rbxthumb://type=AvatarHeadShot&id={math.abs(id)}&w=150&h=150`
		n.Text = who
		-- hung above the screen's top, then dropped to just under the top bar
		b.Position = UDim2.fromScale(0.5, 0)
		b.Visible = true
		s.Scale = 1
		TweenService:Create(b, DROP, { Position = UDim2.new(0.5, 0, 0, b.Size.Y.Offset + 10) })
			:Play()
		r.TimePosition = Shop.GrowRoll.from
		r:Play()
		task.delay(Shop.GrowTime, function()
			if shown ~= mine or not alive then
				return
			end
			r:Stop()
			k.TimePosition = Shop.GrowKnock.from
			k:Play()
			s.Scale = 1.08
			TweenService:Create(s, BOUNCE, { Scale = 1 }):Play()
		end)
		task.delay(Shop.GiftedFor, function()
			if shown ~= mine or not alive then
				return
			end
			TweenService:Create(b, LIFT, { Position = UDim2.fromScale(0.5, 0) }):Play()
			task.delay(LIFT.Time, function()
				if shown == mine and alive then
					b.Visible = false
				end
			end)
		end)
	end

	return {
		name = "GiftedView",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, { Shop.GrowRoll.id, Shop.GrowKnock.id })
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Shop.RemoteFolder, 60)
				local r = if folder then folder:WaitForChild(Grow.GiftedRemote, 60) else nil
				if alive and r and r:IsA("RemoteEvent") then
					link = r.OnClientEvent:Connect(arrive)
				end
			end)
		end,
		stop = function(_: any)
			alive = false
			if link then
				link:Disconnect()
				link = nil
			end
			if gui then
				gui:Destroy()
				gui = nil
			end
		end,
	}
end

return GiftedView
