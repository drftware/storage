--!strict
--[[
	ShelfView: the finds on every home's shelf, on this screen (S5-03c1b, D-284). The server
	(Shelves) stands them, tagged Shelf.Tag; this draws what's new and plays your own walk-up.

	- A new find (Fresh above 0) sparkles: a slow twinkle of the kept glint's warm gold, so you see
	  from the door that something came home. Everyone sees it; visitors too.
	- Walk up to a new one on your own shelf (within Shelf.Reach, looked for every Shelf.Every
	  seconds, never per frame) and it answers: the sparkle bursts and stops with a soft tink. A kind
	  you'd never owned chimes instead (the box reveal's falling twinkles), turns once slowly on its
	  spot and shows a small "New" over it that pops in, holds and fades.
	- Then it tells the server (Shelf.Remote), which checks you're near and marks it seen; the
	  sparkle is gone for everyone.

	Only finds turning are stepped. A find streaming out takes its sparkle and word with it.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local Save = require(ReplicatedStorage.Shared.Save)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tools = require(ReplicatedStorage.Shared.Tools)

type Shown = {
	model: Model,
	spot: Attachment, -- at the find's middle, on its body: where it sparkles, sounds and shows "New"
	top: number, -- studs from its middle up to the top of its box
	sparkle: ParticleEmitter?,
	played: boolean, -- your walk-up has played (it waits on the server's word from here)
	changed: RBXScriptConnection,
	rest: CFrame?, -- its pivot as the server stood it, while it turns
	about: CFrame, -- its middle as it began to turn: it turns about its up through here
	t: number, -- 0 to 1 through its turn
}

local GLINT = "rbxasset://textures/particles/sparkles_main.dds" -- the kept glint's (Slots)
local HEAVY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
local POP = TweenInfo.new(Shelf.Word.Pop, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(Shelf.Word.Fade, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local ShelfView = {}

local function fresh(model: Model): number
	local f = model:GetAttribute(Shelf.FreshAttribute)
	return if type(f) == "number" then f else Save.Fresh.Seen
end

-- The slow twinkle on a new find.
local function sparkle(spot: Attachment): ParticleEmitter
	local p = Instance.new("ParticleEmitter")
	p.Name = "ShelfSparkle"
	p.Texture = GLINT
	p.Rate = Shelf.Sparkle.Rate
	p.Lifetime = NumberRange.new(0.8, 1.3)
	p.Speed = NumberRange.new(0.3, 0.7)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Drag = 1.5
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.35, Shelf.Sparkle.Size),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Rotation = NumberRange.new(0, 90)
	p.RotSpeed = NumberRange.new(-90, 90)
	p.Color = ColorSequence.new(Home.Paint.Sparkle)
	p.LightEmission = 1
	p.LightInfluence = 0.3
	p.Brightness = 2.5
	p.Parent = spot
	return p
end

-- The small "New" over a kind never owned: pops in, holds, fades, gone.
local function word(s: Shown)
	local w = Shelf.Word
	local gui = Instance.new("BillboardGui")
	gui.Name = "ShelfNew"
	gui.Size = UDim2.fromScale(w.Height * 2.6, w.Height)
	gui.StudsOffsetWorldSpace = Vector3.new(0, s.top + w.Above, 0)
	gui.AlwaysOnTop = true -- the board above a low cubby never hides it
	gui.LightInfluence = 0
	gui.MaxDistance = 40
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = w.Text
	label.TextScaled = true
	label.FontFace = HEAVY
	label.TextColor3 = Home.Paint.Word
	label.Parent = gui
	local edge = Instance.new("UIStroke")
	edge.Color = Home.Paint.WordEdge
	edge.Thickness = 2
	edge.Parent = label
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = label
	gui.Parent = s.spot
	TweenService:Create(scale, POP, { Scale = 1 }):Play()
	task.delay(w.Pop + w.Hold, function()
		if gui.Parent then
			TweenService:Create(label, FADE, { TextTransparency = 1 }):Play()
			TweenService:Create(edge, FADE, { Transparency = 1 }):Play()
			task.delay(w.Fade, function()
				gui:Destroy()
			end)
		end
	end)
end

function ShelfView.new(): Brix.System
	local shown: { [Model]: Shown } = {}
	local turning: { [Shown]: true } = {}
	local connections: { RBXScriptConnection } = {}
	local remote: RemoteEvent? = nil
	local untilLook = 0
	local me = Players.LocalPlayer

	local function stopSparkle(s: Shown, burst: boolean)
		local p = s.sparkle
		if not p then
			return
		end
		s.sparkle = nil
		if burst then
			-- the walk-up's answer: a quick spray from the find, like the kept glint, then still
			p.Speed = NumberRange.new(2, 4.5)
			p.Drag = 4
			p.Lifetime = NumberRange.new(0.4, 0.7)
			p:Emit(Shelf.Sparkle.Burst)
		end
		p.Rate = 0
		task.delay(1.2, function()
			p:Destroy()
		end)
	end

	-- Sparkles a new find, stops one seen.
	local function follow(s: Shown)
		local f = fresh(s.model)
		if f == Save.Fresh.Seen then
			s.played = false
			stopSparkle(s, false)
		elseif not s.played and not s.sparkle then
			s.sparkle = sparkle(s.spot)
		end
	end

	-- Your walk-up to new find `s`: its answer, then the word to the server.
	local function play(s: Shown)
		s.played = true
		stopSparkle(s, true)
		local spot = s.model:GetAttribute(Shelf.SpotAttribute)
		if fresh(s.model) == Save.Fresh.Kind then
			Tools.play(Shelf.Chime, s.spot, Shelf.Hearing)
			s.rest = s.model:GetPivot()
			s.about = CFrame.new(s.spot.WorldPosition)
			s.t = 0
			turning[s] = true
			word(s)
		else
			Tools.play(Shelf.Tink, s.spot, Shelf.Hearing)
		end
		if remote and type(spot) == "number" then
			remote:FireServer(spot)
		end
	end

	local function look()
		local character = me.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not (root and root:IsA("BasePart")) then
			return
		end
		local at = root.Position
		for _, s in shown do
			if
				not s.played
				and s.model:GetAttribute(Shelf.OwnerAttribute) == me.UserId
				and fresh(s.model) ~= Save.Fresh.Seen
				and (s.spot.WorldPosition - at).Magnitude <= Shelf.Reach
			then
				play(s)
			end
		end
	end

	local function add(inst: Instance)
		if shown[inst :: any] or not (inst:IsA("Model") and inst.Parent) then -- any: a tagged Instance
			return
		end
		local model = inst :: Model
		local body = Tools.body(model) or model:FindFirstChildWhichIsA("BasePart", true)
		if not body then
			return
		end
		local box, size = model:GetBoundingBox()
		local spot = Instance.new("Attachment")
		spot.Name = "ShelfSpot"
		spot.CFrame = body.CFrame:ToObjectSpace(CFrame.new(box.Position))
		spot.Parent = body
		local s: Shown = {
			model = model,
			spot = spot,
			top = size.Y / 2,
			sparkle = nil,
			played = false,
			changed = model:GetAttributeChangedSignal(Shelf.FreshAttribute):Connect(function()
				local now = shown[model]
				if now then
					follow(now)
				end
			end),
			rest = nil,
			about = CFrame.identity,
			t = 0,
		}
		shown[model] = s
		follow(s)
	end

	local function remove(inst: Instance)
		local s = shown[inst :: any] -- any: the removed signal hands back an Instance
		if not s then
			return
		end
		shown[s.model] = nil
		s.changed:Disconnect()
		if turning[s] then
			turning[s] = nil
			if s.rest and s.model.Parent then
				s.model:PivotTo(s.rest)
			end
		end
		s.spot:Destroy()
	end

	return {
		name = "ShelfView",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, { Shelf.Tink.id, Shelf.Chime.id })
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Shelf.RemoteFolder)
				local r = folder:WaitForChild(Shelf.Remote)
				if r:IsA("RemoteEvent") then
					remote = r
				end
			end)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Shelf.Tag):Connect(function(inst)
					-- deferred so a find streaming in has all its parts before it's measured
					task.defer(add, inst)
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Shelf.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Shelf.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, dt: number)
			untilLook -= dt
			if untilLook <= 0 then
				untilLook = Shelf.Every
				look()
			end
			for s in turning do
				local rest = s.rest
				if not rest then
					turning[s] = nil
					continue
				end
				s.t = math.min(1, s.t + dt / Shelf.Turn.Seconds)
				local k = (1 - math.cos(math.pi * s.t)) / 2 -- eased in and out: a slow, even turn
				local about = s.about
				s.model:PivotTo(
					about * CFrame.Angles(0, math.pi * 2 * k, 0) * about:Inverse() * rest
				)
				if s.t >= 1 then
					s.model:PivotTo(rest)
					s.rest = nil
					turning[s] = nil
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in shown do
				remove(model)
			end
		end,
	}
end

return ShelfView
