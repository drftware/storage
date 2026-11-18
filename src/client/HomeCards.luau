--!strict
--[[
	HomeCards: the names over the homes' doors on this player's screen (S5-03a3b, D-275). The server
	letters a holder's name on their home's card (FrontOffice); this plays its arrival, the
	moment you're handed your home:

	- A name going up is sprayed on through the stencil: the lettering comes up from nothing,
	  shrinking onto the card from a touch big as it lands, the fresh ink glowing and settling to
	  the card's own over Holding.Card.Settle, with a can's short hiss at the card that carries
	  across the floor (friends hear a home taken).
	- A name blanked as its holder leaves fades off the card.
	- A home's light switch shows only on its holder's screen (D-263): the server answers only
	  their press, so nobody else sees a button that does nothing.
	- A card given a new style (S5-03g3c, D-357) has its new plate swing down into place on its
	  top edge and bounce off the wall with a metal clack (`Holding.Card.Swing`), on every screen
	  near enough to see it: the answer to a card picked on the front tab, and to a home taken.
	- A neon card washes the wall round it in pink (D-332), but only the few nearest you
	  (CardPlate.Neon.Near) throw that light on this screen, made as you come and faded out and
	  gone as you leave, so twelve neon cards never cost a phone twelve lights (D-271).

	A card already lettered as it streams in shows as it is, with no spray. Tweens do the motion;
	the step only picks the nearest neon cards a few times a second, and only while there are any.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CardPlate = require(ReplicatedStorage.Shared.Home.CardPlate)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Home = require(ReplicatedStorage.Shared.Home)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)
local UnitLight = require(ReplicatedStorage.Shared.UnitLight)

local CARD = Home.Holding.Card
local SPRAY = TweenInfo.new(CARD.Spray, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SETTLE = TweenInfo.new(CARD.Settle, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local FADE = TweenInfo.new(CARD.Fade, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local NEON = CardPlate.Neon
local WASH = TweenInfo.new(NEON.Fade, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local SWING = CARD.Swing
-- Bounce's out ease: the plate falls to the wall and bounces twice off it, as a hung sign does.
local FALL = TweenInfo.new(SWING.Seconds, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local LIGHT = Home.Specs.CardLight

-- A neon card on this screen: its wall light exists only while it's one of the nearest.
type Wash = {
	at: Vector3, -- where its light hangs
	glow: Color3,
	near: boolean,
	distance: number, -- from the camera's lead point, at the last pick
	light: PointLight?,
	tween: Tween?,
}

local function byNearness(a: Wash, b: Wash): boolean
	return a.distance < b.distance
end

export type HomeCards = Brix.System

local HomeCards = {}

function HomeCards.new(): HomeCards
	local conns: { [Instance]: { RBXScriptConnection } } = {}
	local top: { RBXScriptConnection } = {}
	local settling: { [BasePart]: Tween } = {} -- fresh ink settling to the card's own
	local swinging: { [BasePart]: () -> () } = {} -- a plate swinging down: puts it at rest
	local washes: { [BasePart]: Wash } = {}
	local ranked: { Wash } = {} -- reused at each pick
	local untilPick = 0

	local function hiss(at: BasePart)
		local s = Instance.new("Sound")
		s.SoundId = CARD.Sound
		s.Volume = CARD.Volume
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = CARD.Near
		s.RollOffMaxDistance = CARD.Reach
		s.TimePosition = CARD.Start
		s.Parent = at
		s:Play()
		task.delay(CARD.Stop - CARD.Start, function()
			s:Destroy()
		end)
	end

	-- A card's new plate swings down onto the wall on its top edge, the card's writing with it.
	-- The parts are the server's, anchored: this moves them on this screen only and leaves each
	-- exactly where the server put it, so nothing is left out of place.
	local function swing(card: BasePart)
		local stop = swinging[card]
		if stop then
			stop()
		end
		local camera = Workspace.CurrentCamera
		local wall = card:GetAttribute(CardPlate.WallAttribute)
		local plate = card:FindFirstChild(CardPlate.Plate)
		if
			not (camera and typeof(wall) == "CFrame" and plate)
			or (camera.CFrame.Position - card.Position).Magnitude > SWING.Reach
		then
			return
		end
		-- the card's rest is worked out as the server places it, never read: a pick in the middle
		-- of another's swing would otherwise keep the swung place as its rest
		local face = CardPlate.style(card:GetAttribute(CardPlate.StyleAttribute)).Face
		local parts: { BasePart } = { card }
		local rest: { CFrame } = { wall * CFrame.new(face[1], face[2], face[3]) }
		local height = card.Size.Y / 2
		for _, p in plate:GetChildren() do
			if p:IsA("BasePart") then
				table.insert(parts, p)
				table.insert(rest, p.CFrame)
				height = math.max(height, wall:ToObjectSpace(p.CFrame).Y + p.Size.Y / 2)
			end
		end
		local hinge = wall * CFrame.new(0, height, 0) -- the plate's top edge on the wall
		local value = Instance.new("NumberValue")
		local function place(a: number)
			-- turned on the hinge out into the hall (the card's front is -Z)
			local turn = hinge
				* CFrame.Angles(math.rad(SWING.Lift * (1 - a)), 0, 0)
				* hinge:Inverse()
			for i, p in parts do
				p.CFrame = turn * rest[i]
			end
		end
		place(0)
		value.Changed:Connect(place)
		local t = TweenService:Create(value, FALL, { Value = 1 })
		local function finish()
			if swinging[card] ~= finish then
				return
			end
			swinging[card] = nil
			t:Cancel()
			value:Destroy()
			for i, p in parts do
				p.CFrame = rest[i]
			end
		end
		swinging[card] = finish
		t.Completed:Once(finish)
		local s = Instance.new("Sound")
		s.SoundId = SWING.Sound
		s.Volume = SWING.Volume
		s.PlaybackSpeed = SWING.Pitch
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = CARD.Near
		s.RollOffMaxDistance = CARD.Reach
		s.TimePosition = SWING.From
		s.Parent = card
		-- Bounce's first touch of the wall is at 1/2.75 of the fall: the clack lands on it
		task.delay(math.max(SWING.Seconds / 2.75 - SWING.Hit, 0), function()
			if s.Parent then
				s:Play()
			end
		end)
		task.delay(SWING.Seconds / 2.75 + SWING.Length, function()
			s:Destroy()
		end)
		t:Play()
	end

	-- The fresh ink settles to the lettering's own light in the style the card wears now (the
	-- neon's stays lit), from wherever it is.
	local function settle(card: BasePart, gui: SurfaceGui)
		local old = settling[card]
		if old then
			old:Cancel()
		end
		local t = TweenService:Create(gui, SETTLE, { LightInfluence = CardPlate.inkLight(card) })
		settling[card] = t
		t.Completed:Once(function()
			if settling[card] == t then
				settling[card] = nil
			end
		end)
		t:Play()
	end

	-- Sprays `label`'s new name on.
	local function spray(card: BasePart, label: TextLabel, gui: SurfaceGui)
		local scale = label:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		scale.Scale = CARD.Swell
		scale.Parent = label
		label.TextTransparency = 1
		gui.LightInfluence = 0 -- the fresh ink glows
		TweenService:Create(label, SPRAY, { TextTransparency = 0 }):Play()
		TweenService:Create(scale, SPRAY, { Scale = 1 }):Play()
		local halo = label:FindFirstChild(CardPlate.Halo)
		if halo and halo:IsA("UIStroke") then
			halo.Transparency = 1
			TweenService:Create(halo, SPRAY, { Transparency = NEON.Haze }):Play()
		end
		settle(card, gui)
		hiss(card)
	end

	-- Fades `old`, the name just blanked, off the card, the neon's halo with it.
	local function fadeOff(label: TextLabel, old: string)
		local ghost = label:Clone()
		for _, c in ghost:GetChildren() do
			if c.Name ~= CardPlate.Halo then
				c:Destroy()
			end
		end
		ghost.Text = old
		ghost.Parent = label.Parent
		local halo = ghost:FindFirstChild(CardPlate.Halo)
		if halo and halo:IsA("UIStroke") then
			TweenService:Create(halo, FADE, { Transparency = 1 }):Play()
		end
		local t = TweenService:Create(ghost, FADE, { TextTransparency = 1 })
		t.Completed:Once(function()
			ghost:Destroy()
		end)
		t:Play()
	end

	-- Brings `w`'s wall light up as it becomes one of the nearest, or fades it and lets it go.
	local function shine(w: Wash, card: BasePart, on: boolean)
		local tween = w.tween
		if tween then
			tween:Cancel()
		end
		local light = w.light
		if on and not light then
			local a = Instance.new("Attachment")
			a.Name = "NeonWash"
			a.Position = card.CFrame:PointToObjectSpace(w.at)
			local l = Instance.new("PointLight")
			l.Color = w.glow
			l.Range = LIGHT.Range
			l.Brightness = 0
			l.Shadows = false
			l.Parent = a
			a.Parent = card
			w.light = l
			light = l
		end
		if not light then
			return
		end
		local made: PointLight = light
		local t =
			TweenService:Create(made, WASH, { Brightness = if on then LIGHT.Brightness else 0 })
		w.tween = t
		if not on then
			t.Completed:Once(function(state: Enum.PlaybackState)
				if state == Enum.PlaybackState.Completed and w.light == made then
					w.light = nil
					local a = made.Parent
					if a then
						a:Destroy()
					end
				end
			end)
		end
		t:Play()
	end

	-- Lets `card`'s wash go: faded out when it stops being neon, at once when it streams out.
	local function dropWash(card: BasePart, fade: boolean)
		local w = washes[card]
		if not w then
			return
		end
		washes[card] = nil
		if fade then
			shine(w, card, false)
			return
		end
		local tween = w.tween
		if tween then
			tween:Cancel()
		end
		local light = w.light
		if light and light.Parent then
			(light.Parent :: Instance):Destroy()
		end
		w.light = nil
	end

	-- Watches `card` for being neon: a neon card joins the pick, any other leaves it.
	local function restyle(card: BasePart)
		local style = CardPlate.style(card:GetAttribute(CardPlate.StyleAttribute))
		local at = CardPlate.lightAt(card)
		local glow = style.Glow
		if glow and at then
			if not washes[card] then
				washes[card] = {
					at = at.Position,
					glow = Color3.fromHex(glow),
					near = false,
					distance = math.huge,
				}
				untilPick = 0 -- picked on the next frame
			end
		else
			dropWash(card, true)
		end
	end

	-- The neon cards nearest a point just ahead of the camera light their walls (as the floor
	-- lamps, HomeLights): a card already lit keeps it until another is clearly nearer.
	local function pick()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local view = camera.CFrame
		local look = view.LookVector * Vector3.new(1, 0, 1)
		local from = view.Position
			+ (if look.Magnitude > 1e-3 then look.Unit * UnitLight.NearLead else Vector3.zero)
		table.clear(ranked)
		for _, w in washes do
			w.distance = (w.at - from).Magnitude - (if w.near then UnitLight.NearMargin else 0)
			if w.distance <= NEON.Reach then
				table.insert(ranked, w)
			end
		end
		table.sort(ranked, byNearness)
		for card, w in washes do
			local near = false
			for i = 1, math.min(NEON.Near, #ranked) do
				if ranked[i] == w then
					near = true
					break
				end
			end
			if near ~= w.near then
				w.near = near
				shine(w, card, near)
			end
		end
	end

	local function addCard(inst: Instance)
		if not inst:IsA("BasePart") or conns[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local gui = inst:FindFirstChildOfClass("SurfaceGui")
		local label = gui and gui:FindFirstChildOfClass("TextLabel")
		if not (gui and label) then
			return
		end
		local shown = label.Text
		conns[inst] = {
			label:GetPropertyChangedSignal("Text"):Connect(function()
				local now = label.Text
				if now == shown then
					return
				end
				if now ~= "" then
					spray(inst, label, gui)
				elseif shown ~= "" then
					fadeOff(label, shown)
				end
				shown = now
			end),
			inst:GetAttributeChangedSignal(CardPlate.StyleAttribute):Connect(function()
				restyle(inst)
				swing(inst)
				if settling[inst] then
					settle(inst, gui) -- a new plate under fresh ink: settle onto its own light
				end
			end),
		}
		restyle(inst)
	end

	-- A home's own buttons, the switch's, the job box's (JobBoxes) and the clothes rail's (Rails),
	-- shown only to its holder.
	local function showSwitch(unit: Model)
		local me = Players.LocalPlayer
		local mine = me ~= nil and unit:GetAttribute(Door.HolderAttribute) == me.UserId
		for _, name in { "SwitchSpot", Home.JobBox.Spot } do
			local spot = unit:FindFirstChild(name)
			local prompt = spot and spot:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Enabled = mine
			end
		end
		local rail = unit:FindFirstChild("Rail")
		if rail then
			for _, d in rail:GetDescendants() do
				if d:IsA("ProximityPrompt") then
					d.Enabled = mine
				end
			end
		end
	end

	local function addUnit(inst: Instance)
		if
			not inst:IsA("Model")
			or conns[inst]
			or inst:GetAttribute(Door.HolderAttribute) == nil
		then
			return
		end
		local unit = inst
		conns[unit] = {
			unit:GetAttributeChangedSignal(Door.HolderAttribute):Connect(function()
				showSwitch(unit)
			end),
			-- the button streams in after its unit
			unit.DescendantAdded:Connect(function(d: Instance)
				if d:IsA("ProximityPrompt") then
					showSwitch(unit)
				end
			end),
		}
		showSwitch(unit)
	end

	local function remove(inst: Instance)
		local list = conns[inst]
		if list then
			for _, c in list do
				c:Disconnect()
			end
			conns[inst] = nil
		end
		if inst:IsA("BasePart") then
			dropWash(inst, false)
			settling[inst] = nil
			local stop = swinging[inst]
			if stop then
				stop()
			end
		end
	end

	return {
		name = "HomeCards",
		start = function(_: any)
			local function watch(tag: string, add: (Instance) -> ())
				table.insert(top, CollectionService:GetInstanceAddedSignal(tag):Connect(add))
				table.insert(top, CollectionService:GetInstanceRemovedSignal(tag):Connect(remove))
				for _, inst in CollectionService:GetTagged(tag) do
					add(inst)
				end
			end
			watch(Home.CardTag, addCard)
			watch(UnitKit.Tag, addUnit)
		end,
		step = function(_: any, dt: number)
			if next(washes) == nil then
				return
			end
			untilPick -= dt
			if untilPick <= 0 then
				untilPick = UnitLight.NearSeconds
				pick()
			end
		end,
		stop = function(_: any)
			for _, c in top do
				c:Disconnect()
			end
			table.clear(top)
			for inst in conns do
				remove(inst)
			end
		end,
	}
end

return HomeCards
