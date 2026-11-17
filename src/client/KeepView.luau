--!strict
--[[
	KeepView (S1-06): your finds kept as the gate shuts, on your screen. The moment: the gate slams
	with you aboard and the boombox you carried rises out of your slot on a dark gold-rimmed disc,
	a gold ring bursting out behind it and sparks thrown off, turns a little where you can see it,
	then shrinks and flies up off the screen: yours for good.

	The server's GatePay tells this screen which finds you kept (`Pay.Remote`: the coins, which are
	CoinView's, then the finds' catalog keys), as their slots empty. For each, a beat after the
	slam (`Pay.KeepAfter`, then `Pay.KeepGap` between finds), its 3D picture lifts from the box
	beside the slot button (where the thing in your hand shows), growing and overshooting
	(`Pay.KeepRise`), to its own pick-up sound under a bright chink (`Pay.KeepChink`); it hangs,
	swaying (`Pay.KeepHold`), then flies up and away (`Pay.KeepAway`). No words: the thing itself
	says it. Only what's moving is stepped.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local Pay = require(ReplicatedStorage.Shared.Pay)
local Tools = require(ReplicatedStorage.Shared.Tools)
local ToolPicture = require(script.Parent.ToolPicture)

local Catalog = Tools.Catalog
local me = Players.LocalPlayer

local GOLD = Color3.fromRGB(255, 214, 120)
local SPARKS = 7 -- sparks thrown off each kept find as it rises
local SPARK_TIME = 0.55 -- seconds a spark flies out and fades
local RING_TIME = 0.5 -- seconds the gold ring takes to burst out and fade
local BOX_BARE = 64 -- points: a kept find's starting size when the slots can't be found
local TAU = 2 * math.pi

type Spark = { frame: Frame, angle: number, reach: number }

type Kept = {
	key: string,
	at: number, -- when it starts to rise, on this screen's clock
	from: Vector2, -- the slots' box's middle, in this gui's space
	size: number, -- the box's size
	to: Vector2, -- where it hangs
	holder: Frame?,
	disc: Frame?,
	discRim: UIStroke?,
	model: Model?,
	centre: Vector3, -- the model's middle in its picture, turned about
	pose: CFrame, -- the model's pivot as drawn
	ring: Frame?,
	ringRim: UIStroke?,
	sparks: { Spark },
}

local KeepView = {}

-- Out past the end and back: a rise that overshoots and settles.
local function backOut(p: number): number
	local k = 1.7
	local q = p - 1
	return 1 + (k + 1) * q * q * q + k * q * q
end

local function round(parent: Instance, name: string): (Frame, UIStroke)
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = f
	local rim = Instance.new("UIStroke")
	rim.Color = GOLD
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = f
	f.Parent = parent
	return f, rim
end

function KeepView.new(): Brix.System
	local items: { Kept } = {}
	local connections: { RBXScriptConnection } = {}
	local rng = Random.new()

	-- The same screen space as the slots (their ScreenGui's defaults), so the box's place is ours.
	local gui = Instance.new("ScreenGui")
	gui.Name = "KeptFinds"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6 -- over the slots and the coin count

	-- Where the slots' box is now (else the slot button; else the bottom middle): its middle in
	-- this gui's space, and its size.
	local function boxPlace(): (Vector2, number)
		local playerGui = me:FindFirstChildOfClass("PlayerGui")
		local slots = playerGui and playerGui:FindFirstChild("Slots")
		local hud = slots and slots:FindFirstChild("Hud")
		for _, name in { "Box", "Wheel" } do
			local b = hud and hud:FindFirstChild(name)
			if b and b:IsA("GuiObject") and b.AbsoluteSize.X > 4 then
				local middle = b.AbsolutePosition + b.AbsoluteSize / 2 - gui.AbsolutePosition
				return middle, b.AbsoluteSize.X
			end
		end
		local area = gui.AbsoluteSize
		return Vector2.new(area.X / 2, area.Y - BOX_BARE), BOX_BARE
	end

	-- Builds a kept find's picture, disc, ring and sparks as it starts to rise, with its sound.
	local function build(k: Kept)
		local holder = Instance.new("Frame")
		holder.Name = k.key
		holder.AnchorPoint = Vector2.new(0.5, 0.5)
		holder.BackgroundTransparency = 1
		holder.ZIndex = 2
		local disc, discRim = round(holder, "Disc")
		disc.Position = UDim2.fromScale(0.5, 0.5)
		disc.Size = UDim2.fromScale(1, 1)
		disc.BackgroundColor3 = Color3.new(0, 0, 0)
		disc.BackgroundTransparency = 1
		discRim.Thickness = 2
		discRim.Transparency = 1
		local view = Instance.new("ViewportFrame")
		view.Name = "Find"
		view.AnchorPoint = Vector2.new(0.5, 0.5)
		view.Position = UDim2.fromScale(0.5, 0.5)
		view.Size = UDim2.fromScale(0.92, 0.92)
		view.BackgroundTransparency = 1
		view.Ambient = Color3.fromRGB(176, 166, 150)
		view.LightColor = Color3.fromRGB(255, 236, 200)
		view.LightDirection = Vector3.new(-0.4, -1, -0.6)
		view.ZIndex = 3
		view.Parent = holder
		local model = ToolPicture.draw(view, k.key)
		if model then
			k.model = model
			k.pose = model:GetPivot()
			local body = Tools.body(model)
			k.centre = if body then body.Position else k.pose.Position
		end
		holder.Parent = gui
		k.holder, k.disc, k.discRim = holder, disc, discRim

		local ring, ringRim = round(gui, "Ring")
		ring.ZIndex = 1
		k.ring, k.ringRim = ring, ringRim
		for i = 1, SPARKS do
			local f = Instance.new("Frame")
			f.Name = "Spark"
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.BackgroundColor3 = GOLD
			f.BorderSizePixel = 0
			f.Rotation = 45
			f.ZIndex = 1
			f.Parent = gui
			table.insert(k.sparks, {
				frame = f,
				angle = (i - 1) / SPARKS * TAU + rng:NextNumber(-0.35, 0.35),
				reach = k.size * rng:NextNumber(0.9, 1.6),
			})
		end

		local row = Catalog[Gold.base(k.key) or k.key] -- a Gold sounds as its find
		if row then
			Tools.play(row.pickUp, gui, 10) -- on this screen only: a ScreenGui's sound is flat
		end
		Tools.play(Pay.KeepChink :: any, gui, 10) -- any: Pay's sound row is the catalog's shape
	end

	local function clean(k: Kept)
		if k.holder then
			k.holder:Destroy()
		end
		if k.ring then
			k.ring:Destroy()
		end
		for _, s in k.sparks do
			s.frame:Destroy()
		end
		table.clear(k.sparks)
	end

	-- Moves a kept find for this frame; true once it's gone.
	local function stepKept(k: Kept, now: number): boolean
		local t = now - k.at
		if t < 0 then
			return false
		end
		if not k.holder then
			build(k)
		end
		local holder = k.holder :: Frame
		local disc, discRim = k.disc :: Frame, k.discRim :: UIStroke
		local rise, hold, away = Pay.KeepRise, Pay.KeepHold, Pay.KeepAway
		local big = k.size * Pay.KeepGrow
		local point, across, fade
		if t < rise then
			local e = backOut(t / rise)
			point = k.from:Lerp(k.to, e)
			across = k.size + (big - k.size) * e
			fade = 1 - math.min(1, t / rise * 2)
		elseif t < rise + hold then
			local u = t - rise
			point = k.to + Vector2.new(0, math.sin(u * TAU * 0.8) * k.size * 0.04)
			across = big
			fade = 0
		elseif t < rise + hold + away then
			local q = (t - rise - hold) / away
			local e = q * q
			point = k.to:Lerp(Vector2.new(k.to.X, -big), e)
			across = big * (1 - 0.65 * e)
			fade = e
		else
			clean(k)
			return true
		end
		holder.Position = UDim2.fromOffset(point.X, point.Y)
		holder.Size = UDim2.fromOffset(across, across)
		disc.BackgroundTransparency = 0.45 + 0.55 * fade
		discRim.Transparency = 0.15 + 0.85 * fade
		local model = k.model
		if model then
			-- a gentle sway about its middle, so it reads as the real thing, front on
			local turn = math.sin(t * 2.6) * 0.42
			model:PivotTo(
				CFrame.new(k.centre) * CFrame.Angles(0, turn, 0) * CFrame.new(-k.centre) * k.pose
			)
		end

		-- the ring and the sparks burst from where it rose to, then they're gone
		local burst = math.clamp(t / RING_TIME, 0, 1)
		local ring, ringRim = k.ring, k.ringRim
		if ring and ringRim then
			if burst < 1 then
				local r = big * (0.6 + 1.1 * (1 - (1 - burst) ^ 3))
				ring.Position = UDim2.fromOffset(point.X, point.Y)
				ring.Size = UDim2.fromOffset(r, r)
				ringRim.Thickness = 4 * (1 - burst) + 0.5
				ringRim.Transparency = 0.1 + 0.9 * burst
			else
				ring:Destroy()
				k.ring, k.ringRim = nil, nil
			end
		end
		local flown = math.clamp(t / SPARK_TIME, 0, 1)
		if #k.sparks > 0 then
			if flown < 1 then
				local out = 1 - (1 - flown) ^ 3
				local side = math.max(2, k.size * 0.11 * (1 - flown))
				for _, s in k.sparks do
					local d = s.reach * out
					s.frame.Position = UDim2.fromOffset(
						point.X + math.cos(s.angle) * d,
						point.Y + math.sin(s.angle) * d
					)
					s.frame.Size = UDim2.fromOffset(side, side)
					s.frame.BackgroundTransparency = flown * flown
				end
			else
				for _, s in k.sparks do
					s.frame:Destroy()
				end
				table.clear(k.sparks)
			end
		end
		return false
	end

	-- The finds kept as the gate shut: each rises out of the slots in turn.
	local function kept(_coins: unknown, keys: unknown)
		if type(keys) ~= "table" then
			return
		end
		local list: { string } = {}
		for i, key in keys :: { unknown } do
			if i > Tools.Carry.Slots then
				break
			end
			-- a Gold ("Teddy:Gold") by its find's row; drawn gilded (ToolPicture)
			local row = if type(key) == "string" then Catalog[Gold.base(key) or key] else nil
			if row and row.find then
				table.insert(list, key :: string)
			end
		end
		local n = #list
		if n == 0 then
			return
		end
		local from, size = boxPlace()
		local area = gui.AbsoluteSize
		local big = size * Pay.KeepGrow
		local now = os.clock()
		for i, key in list do
			local x = area.X / 2 + (i - (n + 1) / 2) * big * 1.2
			table.insert(items, {
				key = key,
				at = now + Pay.KeepAfter + (i - 1) * Pay.KeepGap,
				from = from,
				size = size,
				to = Vector2.new(x, from.Y - area.Y * Pay.KeepUp),
				holder = nil,
				disc = nil,
				discRim = nil,
				model = nil,
				centre = Vector3.zero,
				pose = CFrame.identity,
				ring = nil,
				ringRim = nil,
				sparks = {},
			})
		end
	end

	local system = { name = "KeepView" }

	function system.start(_: any, _context: Brix.Context)
		gui.Parent = me:WaitForChild("PlayerGui")
		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(Pay.RemoteFolder)
			local remote = folder:WaitForChild(Pay.Remote)
			if remote:IsA("RemoteEvent") then
				table.insert(connections, remote.OnClientEvent:Connect(kept))
			end
		end)
	end

	function system.step(_: any, _dt: number)
		if #items == 0 then
			return
		end
		local now = os.clock()
		for i = #items, 1, -1 do
			if stepKept(items[i], now) then
				table.remove(items, i)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, k in items do
			clean(k)
		end
		table.clear(items)
		gui:Destroy()
	end

	return system :: any -- any: a plain Brix system built field by field
end

return KeepView
