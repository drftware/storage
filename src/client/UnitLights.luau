--!strict
--[[
	UnitLights: draws each unit's bulb on this player's screen (L-04b, D-033). The bulb is wired to
	the door (ShutIn.bulb), and every screen already knows where every door is from its replicated
	motion (RollUpDoor.rise), so the server sends nothing for it:

	- The door starts up (an open, a peek, a lift from inside): the switch clicks and the bulb
	  stutters on (UnitLight.Flicker), then holds, humming faintly.
	- The door lands shut (a close, the slam's bang): the bulb is out on that frame, silently,
	  and stays out through the slam's bounce.

	Only doors in motion are sampled each frame. Only the lit bulbs nearest a point ahead of the
	camera throw real light and hum (UnitLight.NearBulbs); the rest glow. A home's bulb (the ground
	floor's units, UnitLight.Home) throws light whenever it's lit. On the floor the team picked
	with the power out (S4-03c3, `NextFloor.dark`: its version, and its breaker's word on the
	floor's model) a lifting door's switch clicks and the bulb stays dead; when the breaker's
	thrown back on, every open unit's bulb stutters on, each a moment apart. A unit that streams in
	with its door already up just shows lit. Lights are set only through UnitLight, so they carry
	HallLight's tag and BehindDoors dims them for whoever is shut in another unit; this runs before
	BehindDoors each frame, so that dimming lands on a stuttering bulb too.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Breaker = require(ReplicatedStorage.Shared.Breaker)
local Brix = require(ReplicatedStorage.Brix)
local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local NextFloor = require(ReplicatedStorage.Shared.NextFloor)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local ShutIn = require(ReplicatedStorage.Shared.StorageUnit.ShutIn)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tops = require(ReplicatedStorage.Shared.Tops)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)
local UnitLight = require(ReplicatedStorage.Shared.UnitLight)

local ATTR_MOTION = "DoorMotion" -- the door's replicated motion (RollUpDoor)

-- One unit's bulb on this screen.
type Shown = {
	unit: Model,
	glass: BasePart,
	click: Sound,
	hum: Sound,
	on: boolean, -- the switch's state (ShutIn.bulb)
	real: boolean, -- throws real light and hums (one of the nearest lit bulbs)
	to: number, -- where the door's motion is heading
	ends: number, -- server time its motion ends; sampled each frame until then
	flicker: number?, -- the next step of its stutter, nil once steady
	since: number, -- seconds since it tripped
	changed: RBXScriptConnection,
	power: Power?, -- its laid floor's power (none for a home or the test hall's)
}

-- A laid floor's power, as its units' bulbs see it (S4-03c3): shared by its units on this screen.
type Power = {
	model: Instance, -- the floor's model (it carries the tops map, `Tops.Tag`)
	dead: boolean, -- `NextFloor.dark`: the power's out and its breaker is off
	units: { [Shown]: true },
	conns: { RBXScriptConnection },
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local UnitLights = {}

function UnitLights.new(): Brix.System
	local shown: { [Model]: Shown } = {}
	local moving: { [Shown]: true } = {} -- doors in motion
	local flickering: { [Shown]: true } = {}
	local ranked: { Shown } = {} -- reused each time the nearest lit bulbs are picked
	local nearness: { [Shown]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local random = Random.new()
	local untilPick = 0
	local powers: { [Instance]: Power } = {}

	-- Whether a bulb shows lit: its switch on, and power to it.
	local function lit(s: Shown): boolean
		local p = s.power
		return s.on and not (p and p.dead)
	end

	local function byNearness(a: Shown, b: Shown): boolean
		return nearness[a] < nearness[b]
	end

	local function setReal(s: Shown, real: boolean)
		if real == s.real then
			return
		end
		s.real = real
		if not s.flicker then
			UnitLight.light(s.glass, if lit(s) then 1 else 0, real)
		end
		if real and lit(s) and not s.flicker then
			-- a random place in the loop, so two humming units never pulse together
			s.hum.TimePosition = random:NextNumber(0, math.max(s.hum.TimeLength - 1, 0))
			s.hum:Play()
		else
			s.hum:Stop()
		end
	end

	-- Gives real light to the lit bulbs nearest the camera and takes it from the rest.
	local function pick()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local look = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
		local from = camera.CFrame.Position
			+ (if look.Magnitude > 1e-3 then look.Unit * UnitLight.NearLead else Vector3.zero)
		table.clear(ranked)
		for _, s in shown do
			if lit(s) and UnitLight.isHome(s.glass) then
				setReal(s, true) -- a home's bulb throws its light whenever it's lit
			elseif lit(s) then
				-- one already lit keeps its light until another is clearly nearer
				nearness[s] = (s.glass.Position - from).Magnitude
					- (if s.real then UnitLight.NearMargin else 0)
				table.insert(ranked, s)
			end
		end
		table.sort(ranked, byNearness)
		for i, s in ranked do
			setReal(s, i <= UnitLight.NearBulbs)
		end
		table.clear(nearness)
	end

	-- The switch flips: on, with the click and the stutter; off, dark at once and silent.
	local function switch(s: Shown, on: boolean)
		s.on = on
		if on then
			local pitch = UnitLight.ClickPitch
			s.click.PlaybackSpeed = random:NextNumber(pitch.Min, pitch.Max)
			s.click.TimePosition = 0
			s.click:Play()
			if not lit(s) then
				return -- the power's out: the switch clicks and nothing comes on
			end
			s.flicker, s.since = 1, 0
			flickering[s] = true
			-- pick now, so a bulb coming on beside you throws real light from its first flash
			untilPick = 0
		else
			s.flicker = nil
			flickering[s] = nil
			s.real = false
			s.hum:Stop()
			UnitLight.light(s.glass, 0)
		end
	end

	-- Reads the door's motion: where it's heading and until when it moves. `first` is a unit just
	-- seen, shown as it stands with no click.
	local function follow(s: Shown, first: boolean)
		local kind: Motion.Kind, from: number, to: number, start: number =
			Motion.decode(s.unit:GetAttribute(ATTR_MOTION) :: string?)
		local spec = RollUpDoor.spec(s.unit)
		s.to = to
		s.ends = start + Motion.duration(kind, from, to, spec.Rise.Open)
		local was = if first then from > ShutIn.BulbOffRise else s.on
		local on = ShutIn.bulb(to, RollUpDoor.rise(s.unit, now()), was)
		if first then
			s.on = on
			UnitLight.light(s.glass, if lit(s) then 1 else 0, false)
			untilPick = 0
		elseif on ~= s.on then
			switch(s, on)
		end
		if now() < s.ends then
			moving[s] = true
		else
			moving[s] = nil
		end
	end

	-- The floor's power changed (its version or its breaker): cut, every lit bulb on it dies at
	-- once with no click, as the halls' tubes do; back, each open unit's bulb stutters on, each
	-- up to `UnitLight.BackRagged` late, with no click (its switch never moved).
	local function repower(p: Power)
		local dead = NextFloor.dark(
			p.model:GetAttribute(NextFloor.Attribute),
			p.model:GetAttribute(Breaker.FloorAttribute)
		)
		if dead == p.dead then
			return
		end
		p.dead = dead
		for s in p.units do
			if not s.on then
				continue
			elseif dead then
				s.flicker = nil
				flickering[s] = nil
				s.real = false
				s.hum:Stop()
				UnitLight.light(s.glass, 0)
			else
				s.flicker, s.since = 1, -random:NextNumber(0, UnitLight.BackRagged)
				flickering[s] = true
				untilPick = 0
			end
		end
	end

	-- Joins `s` to its laid floor's power (the nearest ancestor carrying the floor's tops map).
	local function join(s: Shown)
		local at = s.unit.Parent
		while at and at ~= Workspace and not at:HasTag(Tops.Tag) do
			at = at.Parent
		end
		if not at or at == Workspace then
			return
		end
		local floor: Instance = at
		local p = powers[floor]
		if not p then
			local made: Power = { model = floor, dead = false, units = {}, conns = {} }
			for _, name in { NextFloor.Attribute, Breaker.FloorAttribute } do
				table.insert(
					made.conns,
					floor:GetAttributeChangedSignal(name):Connect(function()
						repower(made)
					end)
				)
			end
			made.dead = NextFloor.dark(
				floor:GetAttribute(NextFloor.Attribute),
				floor:GetAttribute(Breaker.FloorAttribute)
			)
			powers[floor] = made
			p = made
		end
		p.units[s] = true
		s.power = p
	end

	local function leave(s: Shown)
		local p = s.power
		if not p then
			return
		end
		s.power = nil
		p.units[s] = nil
		if next(p.units) == nil then
			for _, c in p.conns do
				c:Disconnect()
			end
			powers[p.model] = nil
		end
	end

	local function add(inst: Instance)
		-- a tagged template in ReplicatedStorage is no unit (docs/STUDIO.md)
		if not inst:IsA("Model") or shown[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local bulb = inst:FindFirstChild("Bulb")
		local glass = bulb and bulb:FindFirstChild("Glass")
		if not (glass and glass:IsA("BasePart")) then
			return -- a unit hung without its bulb (FloorBuilder says why)
		end
		local click = Instance.new("Sound")
		click.Name = "BulbClick"
		click.SoundId = UnitLight.ClickSound
		click.Volume = UnitLight.ClickVolume
		click.RollOffMode = Enum.RollOffMode.InverseTapered
		click.RollOffMinDistance = UnitLight.ClickNear
		click.RollOffMaxDistance = UnitLight.ClickReach
		click.Parent = glass
		local hum = Instance.new("Sound")
		hum.Name = "BulbHum"
		hum.SoundId = UnitLight.HumSound
		hum.Volume = UnitLight.HumVolume
		hum.Looped = true
		hum.RollOffMode = Enum.RollOffMode.InverseTapered
		hum.RollOffMinDistance = UnitLight.HumNear
		hum.RollOffMaxDistance = UnitLight.HumReach
		hum.Parent = glass
		local s: Shown
		s = {
			unit = inst,
			glass = glass,
			click = click,
			hum = hum,
			on = false,
			real = false,
			to = 0,
			ends = 0,
			flicker = nil,
			since = 0,
			changed = inst:GetAttributeChangedSignal(ATTR_MOTION):Connect(function()
				follow(s, false)
			end),
		}
		shown[inst] = s
		join(s)
		follow(s, true)
	end

	local function remove(inst: Instance)
		local s = shown[inst :: any] -- any: the removed signal hands back an Instance
		if s then
			s.changed:Disconnect()
			leave(s)
			s.click:Destroy()
			s.hum:Destroy()
			moving[s] = nil
			flickering[s] = nil
			shown[inst :: any] = nil
		end
	end

	-- Moves one bulb's stutter on by `dt`.
	local function animate(s: Shown, dt: number)
		s.since += dt
		local step = s.flicker
		while step do
			local flash = UnitLight.Flicker[step]
			if not flash then
				-- caught: it holds, and hums if it's one of the near ones
				UnitLight.light(s.glass, 1, s.real)
				if s.real then
					s.hum.TimePosition = random:NextNumber(0, math.max(s.hum.TimeLength - 1, 0))
					s.hum:Play()
				end
				step = nil
			elseif s.since >= flash.at then
				UnitLight.light(s.glass, flash.level, s.real)
				step += 1
			else
				break
			end
		end
		s.flicker = step
		if not step then
			flickering[s] = nil
		end
	end

	return {
		name = "UnitLights",
		start = function(_: any, _context: Brix.Context)
			-- the first unit light's click and hum on time, not a third of a second late
			task.spawn(SoundPrimer.prime, { UnitLight.ClickSound, UnitLight.HumSound })
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(function(inst)
					-- Deferred so a unit streaming in has its bulb before it's looked up.
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
			local t = now()
			for s in moving do
				local on = ShutIn.bulb(s.to, RollUpDoor.rise(s.unit, t), s.on)
				if on ~= s.on then
					switch(s, on)
				end
				if t >= s.ends then
					moving[s] = nil
				end
			end
			-- picked before animating, so a bulb that just came on has its light from its first flash
			untilPick -= dt
			if untilPick <= 0 then
				untilPick = UnitLight.NearSeconds
				pick()
			end
			for s in flickering do
				animate(s, dt)
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

return UnitLights
