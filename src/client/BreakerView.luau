--!strict
--[[
	BreakerView: every floor's breaker box on this screen (S2-02b; the rules are `Breaker`'s, the
	server's Breakers owns the state). Nothing here decides anything: it draws the box's
	`Breaker.OnAttribute` and `Breaker.StrainAttribute`.

	Thrown: the lever slams down, one heavy clunk carries across the floor (the camera kicks for
	whoever stands near), and the pilot lamp goes red, pulsing slowly so it reads down a dark hall.
	Held: the lever creeps up under the hand, for the holder at once and for every friend as the
	server marks it straining; let go early and it drops back. Caught: it snaps the rest of the way
	up with a click, the lamp turns green and the mains hum swells and dies away as the lights come
	back. Only boxes in motion or thrown are stepped.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Breaker = require(ReplicatedStorage.Shared.Breaker)
local Brix = require(ReplicatedStorage.Brix)

local Specs = Breaker.Specs
local PIVOT = CFrame.new(Specs.Pivot[1], Specs.Pivot[2], Specs.Pivot[3])
local LAMP = Vector3.new(Specs.Lamp[1], Specs.Lamp[2], Specs.Lamp[3])
local GLOW_OUT = Vector3.new(0, 0, -Breaker.GlowOut) -- toward the hall

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end
local LAMP_OFF = rgb(Breaker.LampOff)
local LAMP_ON = rgb(Breaker.LampOn)

type View = {
	model: Model,
	on: boolean,
	straining: boolean,
	mine: boolean, -- this screen's player is holding its button
	angle: number, -- the lever's now, degrees
	from: number, -- a move's start angle
	to: number,
	elapsed: number,
	seconds: number, -- the move's length; 0 when the lever rests
	strain: number, -- seconds into a hold
	pulse: number, -- seconds into the red lamp's pulse
	conns: { RBXScriptConnection },
}

local BreakerView = {}

function BreakerView.new(kick: (amount: number) -> ()): Brix.System
	local views: { [Model]: View } = {}
	local connections: { RBXScriptConnection } = {}

	local function part(v: View, name: string): BasePart?
		local p = v.model:FindFirstChild(name)
		return if p and p:IsA("BasePart") then p else nil
	end

	local function placeLever(v: View)
		local lever = part(v, "BreakerLever")
		if lever then
			lever:PivotTo(v.model:GetPivot() * PIVOT * CFrame.Angles(math.rad(v.angle), 0, 0))
		end
	end

	local function paintLamp(v: View)
		local lamp = part(v, "BreakerLamp")
		if not lamp then
			return
		end
		lamp.Material = Enum.Material.Neon
		lamp.Color = if v.on then LAMP_ON else LAMP_OFF
		lamp.Transparency = if v.on then Breaker.LampOnFaint else Breaker.pulse(v.pulse)
		-- the glow: made the first time the box is thrown, on only while it is
		local at = lamp:FindFirstChild("BreakerGlow")
		local glow = at and at:FindFirstChildOfClass("PointLight")
		if not glow and not v.on then
			-- out in front of the lens, so it washes the door and the board, not grazes them
			local spot = Instance.new("Attachment")
			spot.Name = "BreakerGlow"
			spot.Parent = lamp
			spot.WorldPosition = (v.model:GetPivot() * CFrame.new(LAMP + GLOW_OUT)).Position
			local light = Instance.new("PointLight")
			light.Color = LAMP_OFF
			light.Range = Breaker.GlowRange
			light.Shadows = false
			light.Parent = spot
			glow = light
		end
		if glow and glow:IsA("PointLight") then
			glow.Enabled = not v.on
			local faint = Breaker.pulse(v.pulse) / Breaker.PulseFaint -- 0 at the top, 1 at the bottom
			glow.Brightness = Breaker.GlowBrightness * (1 - 0.6 * faint)
		end
	end

	local function move(v: View, to: number, seconds: number)
		v.from, v.to, v.elapsed, v.seconds = v.angle, to, 0, seconds
	end

	-- A sound at the box (positional where its body has streamed in), let go when it ends.
	local function play(v: View, id: string, volume: number, speed: number, reach: number): Sound
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = volume
		s.PlaybackSpeed = speed
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 12
		s.RollOffMaxDistance = reach
		s.Parent = part(v, "Breaker") or Workspace
		s.Ended:Once(function()
			s:Destroy()
		end)
		s:Play()
		return s
	end

	local function hum(v: View)
		local s = play(v, Breaker.HumSound, 0, Breaker.HumSpeed, 120)
		s.Looped = true
		task.spawn(function()
			local t = 0
			while t < Breaker.HumIn + Breaker.HumOut and s.Parent do
				t += task.wait()
				local swell = if t < Breaker.HumIn
					then t / Breaker.HumIn
					else 1 - (t - Breaker.HumIn) / Breaker.HumOut
				s.Volume = Breaker.HumVolume * math.clamp(swell, 0, 1)
			end
			s:Destroy()
		end)
	end

	-- The box's state from its attributes; `quiet` on first sight draws it without a sound.
	local function update(v: View, quiet: boolean)
		local on = v.model:GetAttribute(Breaker.OnAttribute) ~= false
		local straining = v.model:GetAttribute(Breaker.StrainAttribute) == true or v.mine
		local was, wasStraining = v.on, v.straining
		v.on, v.straining = on, straining and not on
		if quiet then
			v.angle = if on then Specs.Up else Specs.Down
			v.seconds = 0
			placeLever(v)
			paintLamp(v)
			return
		end
		if was and not on then
			move(v, Specs.Down, Breaker.ThrowSeconds)
			v.pulse = 0
			play(v, Breaker.ClunkSound, Breaker.ClunkVolume, Breaker.ClunkSpeed, Breaker.ClunkReach)
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local d = (root.Position - v.model:GetPivot().Position).Magnitude
				if d < Breaker.ShakeReach then
					kick(Breaker.ClunkShake * (1 - d / Breaker.ShakeReach))
				end
			end
		elseif on and not was then
			move(v, Specs.Up, Breaker.CatchSeconds)
			play(v, Breaker.CatchSound, Breaker.CatchVolume, Breaker.CatchSpeed, 90)
			hum(v)
			if v.mine then
				kick(Breaker.ClunkShake / 3)
			end
		elseif v.straining and not wasStraining then
			v.strain, v.seconds = 0, 0
		elseif wasStraining and not v.straining and not on then
			move(v, Specs.Down, Breaker.FallSeconds)
		end
		paintLamp(v)
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or views[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local v: View = {
			model = inst,
			on = true,
			straining = false,
			mine = false,
			angle = Specs.Up,
			from = Specs.Up,
			to = Specs.Up,
			elapsed = 0,
			seconds = 0,
			strain = 0,
			pulse = 0,
			conns = {},
		}
		views[inst] = v
		update(v, true)
		for _, name in { Breaker.OnAttribute, Breaker.StrainAttribute } do
			table.insert(
				v.conns,
				inst:GetAttributeChangedSignal(name):Connect(function()
					update(v, false)
				end)
			)
		end
		-- a part streamed in late is drawn as the box stands now
		table.insert(
			v.conns,
			inst.ChildAdded:Connect(function(child: Instance)
				if child.Name == "BreakerLever" then
					placeLever(v)
				elseif child.Name == "BreakerLamp" then
					paintLamp(v)
				end
			end)
		)
	end

	local function remove(inst: Instance)
		local v = views[inst :: any] -- any: the removed signal hands back an Instance
		if v then
			views[inst :: any] = nil
			for _, c in v.conns do
				c:Disconnect()
			end
		end
	end

	local function holding(prompt: ProximityPrompt, held: boolean)
		for model, v in views do
			if prompt:IsDescendantOf(model) then
				v.mine = held
				update(v, false)
			end
		end
	end

	local system = { name = "BreakerView" }

	function system.start(_: any, _context: Brix.Context)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Breaker.Tag):Connect(add)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Breaker.Tag):Connect(remove)
		)
		for _, inst in CollectionService:GetTagged(Breaker.Tag) do
			add(inst)
		end
		table.insert(
			connections,
			ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt)
				holding(prompt, true)
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt: ProximityPrompt)
				holding(prompt, false)
			end)
		)
	end

	-- Only boxes thrown (the lamp's pulse) or with a lever in motion.
	function system.step(_: any, dt: number)
		for _, v in views do
			if v.on and v.seconds == 0 then
				continue
			end
			if v.straining then
				v.strain += dt
				v.angle = Breaker.strained(v.strain)
				placeLever(v)
			elseif v.seconds > 0 then
				v.elapsed = math.min(v.elapsed + dt, v.seconds)
				local a = v.elapsed / v.seconds
				local eased = a * a -- it accelerates into its stop: a slam, not a glide
				v.angle = v.from + (v.to - v.from) * eased
				placeLever(v)
				if v.elapsed >= v.seconds then
					v.seconds = 0
				end
			end
			if not v.on then
				v.pulse += dt
				paintLamp(v)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for model in views do
			remove(model)
		end
	end

	return system
end

return BreakerView
