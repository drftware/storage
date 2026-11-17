--!strict
--[[
	HomeLights: draws each home's light on this player's screen (S5-03a2b3, D-266). A home's lamps
	aren't wired to its door as a climb unit's bulb is: the switch inside by the door turns them,
	and the server keeps which way it's set on the unit (Home.LightAttribute, FrontOffice), so the
	server sends nothing else for it.

	- The switch flips: a click at the plate, the rocker rocks over (top in for on), and the
	  ceiling lamp and the floor lamp warm up together, or fade, over Home.Switch.Ease: a calm,
	  clean light, never the climb bulb's stutter.
	- Shut in with it off, the unit is dark: the hall's light is kept out by BehindDoors.

	A unit that streams in shows as it's set, with no click. Only lamps easing are stepped. The
	ceiling lamp is lit through UnitLight (a home's bulb), so it carries HallLight's tag and
	BehindDoors leaves your own whole while it dims your neighbours'. Runs before BehindDoors.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local SoundPrimer = require(script.Parent.SoundPrimer)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)
local UnitLight = require(ReplicatedStorage.Shared.UnitLight)

-- One home's light on this screen.
type Shown = {
	unit: Model,
	lamp: BasePart,
	toggle: BasePart?,
	rest: CFrame, -- the rocker as laid (upright); it rocks about its own X from here
	click: Sound?,
	lights: { PointLight }, -- the floor lamp's
	shades: { BasePart }, -- the floor lamp's shade, glowing a little when lit
	on: boolean,
	from: number,
	to: number,
	t: number, -- 0 to 1 through the ease
	level: number,
	changed: RBXScriptConnection,
}

local TILT = math.rad(Home.Specs.Switch.Tilt)
local ROCK = TweenInfo.new(Home.Switch.Rock, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local HomeLights = {}

function HomeLights.new(): Brix.System
	local shown: { [Model]: Shown } = {}
	local easing: { [Shown]: true } = {}
	local connections: { RBXScriptConnection } = {}
	local random = Random.new()

	local function draw(s: Shown, level: number)
		s.level = level
		UnitLight.light(s.lamp, level, true)
		for _, light in s.lights do
			light.Brightness = Home.FloorLamp.Brightness * level
			light.Enabled = level > 0
		end
		for _, shade in s.shades do
			shade.Color = Home.Paint.LampShade:Lerp(Home.FloorLamp.Glow, level)
		end
	end

	local function rock(s: Shown, on: boolean, instant: boolean)
		local toggle = s.toggle
		if not toggle then
			return
		end
		-- top in (toward the wall, the unit's -Z) for on
		local target = s.rest * CFrame.Angles(if on then -TILT else TILT, 0, 0)
		if instant then
			toggle.CFrame = target
		else
			TweenService:Create(toggle, ROCK, { CFrame = target }):Play()
		end
	end

	local function follow(s: Shown, first: boolean)
		local on = s.unit:GetAttribute(Home.LightAttribute) == true
		if first then
			s.on = on
			rock(s, on, true)
			draw(s, if on then 1 else 0)
			return
		end
		if on == s.on then
			return
		end
		s.on = on
		rock(s, on, false)
		local click = s.click
		if click then
			local pitch = UnitLight.ClickPitch
			click.PlaybackSpeed = random:NextNumber(pitch.Min, pitch.Max)
			click.TimePosition = 0
			click:Play()
		end
		s.from, s.to, s.t = s.level, if on then 1 else 0, 0
		easing[s] = true
	end

	local function add(inst: Instance)
		-- a tagged template in ReplicatedStorage is no unit (docs/STUDIO.md)
		if not inst:IsA("Model") or shown[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local lamp = inst:FindFirstChild("Lamp")
		if not (lamp and lamp:IsA("BasePart") and UnitLight.isHome(lamp)) then
			return -- a climb unit: UnitLights draws its bulb
		end
		local toggle = inst:FindFirstChild("SwitchToggle")
		local plate = inst:FindFirstChild("Switch")
		local click: Sound? = nil
		if plate and plate:IsA("BasePart") then
			local c = Instance.new("Sound")
			c.Name = "SwitchClick"
			c.SoundId = UnitLight.ClickSound
			c.Volume = Home.Switch.ClickVolume
			c.RollOffMode = Enum.RollOffMode.InverseTapered
			c.RollOffMinDistance = UnitLight.ClickNear
			c.RollOffMaxDistance = UnitLight.ClickReach
			c.Parent = plate
			click = c
		end
		local lights, shades = {}, {}
		for _, d in inst:GetDescendants() do
			if d:IsA("PointLight") and d:HasTag(Home.LampTag) then
				table.insert(lights, d)
				local shade = d.Parent
				if shade and shade:IsA("BasePart") then
					table.insert(shades, shade)
				end
			end
		end
		local t = if toggle and toggle:IsA("BasePart") then toggle else nil
		local s: Shown
		s = {
			unit = inst,
			lamp = lamp,
			toggle = t,
			rest = if t then t.CFrame else CFrame.identity,
			click = click,
			lights = lights,
			shades = shades,
			on = false,
			from = 0,
			to = 0,
			t = 1,
			level = 0,
			changed = inst:GetAttributeChangedSignal(Home.LightAttribute):Connect(function()
				follow(s, false)
			end),
		}
		shown[inst] = s
		follow(s, true)
	end

	local function remove(inst: Instance)
		local s = shown[inst :: any] -- any: the removed signal hands back an Instance
		if s then
			s.changed:Disconnect()
			if s.click then
				s.click:Destroy()
			end
			easing[s] = nil
			shown[inst :: any] = nil
		end
	end

	return {
		name = "HomeLights",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, { UnitLight.ClickSound })
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(function(inst)
					-- deferred so a unit streaming in has its lamps before they're looked up
					task.defer(add, inst)
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(UnitKit.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, dt: number)
			for s in easing do
				s.t = math.min(1, s.t + dt / Home.Switch.Ease)
				local k = 1 - (1 - s.t) * (1 - s.t) -- eases out: quick to answer, soft to settle
				draw(s, s.from + (s.to - s.from) * k)
				if s.t >= 1 then
					easing[s] = nil
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for unit in shown do
				remove(unit)
			end
		end,
	}
end

return HomeLights
