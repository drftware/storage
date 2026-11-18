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
	- A phone's budget (S5-03a2c): only the floor lamps nearest you throw real light
	  (Home.FloorLamp.Near), easing in and out; the rest glow. A front's drum and head plates
	  (Home.InsideOnly) are drawn only while the camera is in that home.

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
local LobbySpecs = require(ReplicatedStorage.Shared.Lobby.Specs)
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
	hidden: { BasePart }, -- Home.InsideOnly's parts, drawn only while the camera is inside
	room: CFrame?, -- the inside's middle on the floor, looking in from the door (nil: no hiding)
	half: Vector3, -- the inside's half width (X) and half depth plus InsideMargin (Z)
	inside: boolean?, -- whether the camera was inside at the last pick
	floorAt: Vector3?, -- the floor lamp's shade, for nearness
	near: boolean, -- its floor lamp is one of the nearest: it throws real light here
	real: number, -- 0 to 1: how much of that real light shows, easing toward `near`
	distance: number, -- from the camera's lead point, at the last pick
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
	local fading: { [Shown]: true } = {} -- floor lamps gaining or losing their real light
	local ranked: { Shown } = {} -- reused each time the nearest floor lamps are picked
	local untilPick = 0
	local connections: { RBXScriptConnection } = {}
	local random = Random.new()

	local function floorLight(s: Shown)
		local brightness = Home.FloorLamp.Brightness * s.level * s.real
		for _, light in s.lights do
			light.Brightness = brightness
			light.Enabled = brightness > 0
		end
	end

	local function draw(s: Shown, level: number)
		s.level = level
		UnitLight.light(s.lamp, level, true)
		floorLight(s)
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

	local function byNearness(a: Shown, b: Shown): boolean
		return a.distance < b.distance
	end

	-- Shows each front's inside-only parts to a camera inside it, and gives real light to the
	-- floor lamps nearest a point just ahead of the camera.
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
		for _, s in shown do
			local room = s.room
			if room then
				local at = room:PointToObjectSpace(view.Position)
				local inside = math.abs(at.X) <= s.half.X and math.abs(at.Z) <= s.half.Z
				if inside ~= s.inside then
					s.inside = inside
					for _, p in s.hidden do
						p.LocalTransparencyModifier = if inside then 0 else 1
					end
				end
			end
			local floorAt = s.floorAt
			if floorAt then
				-- a lamp already lit keeps it until another is clearly nearer
				s.distance = (floorAt - from).Magnitude
					- (if s.near then UnitLight.NearMargin else 0)
				if s.distance <= Home.FloorLamp.Reach then
					table.insert(ranked, s)
				end
			end
		end
		table.sort(ranked, byNearness)
		for _, s in shown do
			local near = false
			for i = 1, math.min(Home.FloorLamp.Near, #ranked) do
				if ranked[i] == s then
					near = true
					break
				end
			end
			if near ~= s.near then
				s.near = near
				fading[s] = true
			end
		end
	end

	-- The inside's frame and half size, from where the door stands and the lamp hangs (the lamp
	-- is over the inside's middle) and the lobby slot's inside box; nil off the lobby.
	local function roomOf(unit: Model, lamp: BasePart): (CFrame?, Vector3)
		local number = unit:GetAttribute("LobbySlot")
		local slot: LobbySpecs.Slot? = nil
		for _, each in LobbySpecs.Slots do
			if each.Number == number then
				slot = each
			end
		end
		local door = unit:GetPivot().Position
		local middle = Vector3.new(lamp.Position.X, door.Y, lamp.Position.Z)
		local inward = (middle - door) * Vector3.new(1, 0, 1)
		if not slot or inward.Magnitude < 1 then
			return nil, Vector3.zero
		end
		local size, out = slot.Inside.Size, slot.Out
		local width = if math.abs(out[1]) > 0.5 then size[3] else size[1]
		local half = Vector3.new(width / 2, 0, inward.Magnitude + Home.InsideMargin)
		return CFrame.lookAt(middle, middle + inward), half
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
		local lights, shades, hidden = {}, {}, {}
		for _, name in Home.InsideOnly do
			local p = inst:FindFirstChild(name)
			if p and p:IsA("BasePart") then
				table.insert(hidden, p)
			end
		end
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
		local room, half = roomOf(inst, lamp)
		local s: Shown
		s = {
			unit = inst,
			lamp = lamp,
			toggle = t,
			rest = if t then t.CFrame else CFrame.identity,
			click = click,
			lights = lights,
			shades = shades,
			hidden = hidden,
			room = room,
			half = half,
			inside = nil,
			floorAt = if shades[1] then shades[1].Position else nil,
			near = false,
			real = 0,
			distance = 0,
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
		untilPick = 0 -- pick now, so a home streaming in beside you is whole from its first frame
	end

	local function remove(inst: Instance)
		local s = shown[inst :: any] -- any: the removed signal hands back an Instance
		if s then
			s.changed:Disconnect()
			if s.click then
				s.click:Destroy()
			end
			for _, p in s.hidden do
				p.LocalTransparencyModifier = 0
			end
			easing[s] = nil
			fading[s] = nil
			shown[inst :: any] = nil
		end
	end

	-- The floor lamp is a row its holder sets out, drawn after the home is shown and again each
	-- time it's set out (S5-03i1b): its light joins its home's switch as it comes, and leaves it as
	-- it's put away.
	local function lampAdded(inst: Instance)
		if not (inst:IsA("PointLight") and inst:HasTag(Home.LampTag)) then
			return
		end
		for unit, s in shown do
			if inst:IsDescendantOf(unit) and not table.find(s.lights, inst) then
				table.insert(s.lights, inst)
				local shade = inst.Parent
				if shade and shade:IsA("BasePart") then
					table.insert(s.shades, shade)
					s.floorAt = shade.Position
				end
				follow(s, true)
				return
			end
		end
	end

	local function lampRemoved(inst: Instance)
		for _, s in shown do
			local i = table.find(s.lights, inst :: any) -- any: a removed light is a PointLight
			if i then
				table.remove(s.lights, i)
				local shade = inst.Parent
				local j = if shade then table.find(s.shades, shade :: any) else nil -- any: as above
				if j then
					table.remove(s.shades, j)
				end
				s.floorAt = if s.shades[1] then s.shades[1].Position else nil
				return
			end
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
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Home.LampTag):Connect(function(inst)
					task.defer(lampAdded, inst)
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Home.LampTag):Connect(lampRemoved)
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
			untilPick -= dt
			if untilPick <= 0 then
				untilPick = UnitLight.NearSeconds
				pick()
			end
			for s in fading do
				local target = if s.near then 1 else 0
				local d = dt / Home.FloorLamp.Fade
				s.real = if target > s.real
					then math.min(target, s.real + d)
					else math.max(target, s.real - d)
				floorLight(s)
				if s.real == target then
					fading[s] = nil
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
