--!strict
--[[
	Batteries on every screen (S1-07b). The moment: your beam is stuttering, you lift a door, and
	there's a battery on the floor; one tap and it hops up end over end and flies into your torch,
	a heavy clack and a bright click, and your light snaps back full with the ring sweeping round
	its button. Each flight is held in `InFlight` until it lands, as the machine's are: your torch
	comes up out of the bottom of your view to take it if it was let down, and the ring sweeps
	and the light fills as it clacks in, not before (FlashlightView; D-435).

	Its button: shown only while your torch's ring has lost a tick (`Battery.wants`, read from the
	charge the server writes on you). With a full ring the battery lies there with no button for
	you, so it stays for the friend whose torch is dying; nothing on screen says why. Nor while
	its unit's shut door stands between you and it (S2-07b1, `RollUpDoor.keepsApart`, the
	server's own rule): a peek's crack is no way in for a hand.

	A take, on every screen: the server stamps its taker (`Battery.TakenAttribute`); the battery
	throws off a few sparks, hops, and flies into the taker's torch, shrinking as it slides in, and
	the clack-click plays at that torch: yours in your hand, a friend's heard from close by.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Battery = require(ReplicatedStorage.Shared.Battery)
local Brix = require(ReplicatedStorage.Brix)
local Charge = require(ReplicatedStorage.Shared.Flashlight.Charge)
local HandAt = require(script.Parent.HandAt)
local InFlight = require(script.Parent.InFlight)
local SoundPrimer = require(script.Parent.SoundPrimer)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local SPARKS = 4 -- sparks thrown off its button as it's taken
-- How often (seconds) your screen looks for a shut door between you and the batteries near you
-- (studs, past the Take's reach), hiding the Take while one is (S2-07b1; the server refuses it).
local REACH_EVERY = 0.2
local REACH_NEAR = 16

type Lying = {
	part: BasePart,
	prompt: ProximityPrompt?,
	size: Vector3, -- its size as laid
	glint: ParticleEmitter?,
	reach: boolean, -- no shut door between you and it, as last looked
}

type Flight = {
	part: BasePart,
	size: Vector3,
	from: CFrame, -- where it lay
	taker: Player,
	start: number,
	axis: Vector3, -- what it turns end over end about, in the world
	sounded: boolean,
}

local function sound(spec: Battery.Sound, parent: Instance, heard: number?): Sound
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = spec.volume
	s.PlaybackSpeed = spec.pitch
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
	if heard then
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 4
		s.RollOffMaxDistance = heard
	end
	s.Parent = parent
	return s
end

-- Plays `spec` once at `parent`, cleaned up when it's done.
local function once(spec: Battery.Sound, parent: Instance, heard: number?)
	local s = sound(spec, parent, heard)
	s.Ended:Once(function()
		s:Destroy()
	end)
	s:Play()
	task.delay(spec.length / spec.pitch + 0.5, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function fullCharge(): number
	return Charge.full(if RunService:IsStudio() then Workspace:GetAttribute(Charge.Dev) else nil)
end

-- Up fast and easing over the top.
local function hopCurve(p: number): number
	return 1 - (1 - p) * (1 - p)
end

-- Slow off the top, then quicker into the torch.
local function flyCurve(p: number): number
	return p * p * (3 - 2 * p) * 0.4 + p * p * 0.6
end

local BatteryView = {}

function BatteryView.new(): Brix.System
	local me = Players.LocalPlayer
	local lying: { [BasePart]: Lying } = {}
	local flights: { Flight } = {}
	local connections: { RBXScriptConnection } = {}
	local perBattery: { [BasePart]: { RBXScriptConnection } } = {}
	local wants = false -- whether your torch would take a battery now

	-- Every battery's button for you: there while your torch would take one.
	local function showButtons()
		for _, b in lying do
			local prompt = b.prompt
			if prompt and b.part:GetAttribute(Battery.TakenAttribute) == nil then
				local show = wants and b.reach
				if prompt.Enabled ~= show then
					prompt.Enabled = show
				end
			end
		end
	end

	local function charged()
		local left = me:GetAttribute(Charge.Attribute)
		local full = fullCharge()
		local now = type(left) == "number" and Battery.wants(left, full)
		if now ~= wants then
			wants = now
			showButtons()
		end
	end

	local function hide(b: Lying)
		b.part.LocalTransparencyModifier = 1
		if b.glint then
			b.glint.Enabled = false
		end
	end

	local function taken(b: Lying)
		if not lying[b.part] then
			return
		end
		lying[b.part] = nil
		if b.prompt then
			b.prompt.Enabled = false
		end
		local id = b.part:GetAttribute(Battery.TakenAttribute)
		local taker = if type(id) == "number" then Players:GetPlayerByUserId(id) else nil
		if not taker then
			hide(b)
			return
		end
		local glint = b.glint
		if glint then
			glint:Emit(SPARKS)
			glint.Enabled = false
		end
		-- end over end: about the floor's line across its length
		local length = b.part.CFrame.UpVector
		local across = length:Cross(Vector3.yAxis)
		InFlight.hold(taker, "torch") -- landed when its flight ends, whichever way
		table.insert(flights, {
			part = b.part,
			size = b.size,
			from = b.part.CFrame,
			taker = taker,
			start = os.clock(),
			axis = if across.Magnitude > 1e-3 then across.Unit else Vector3.xAxis,
			sounded = false,
		})
	end

	local function added(inst: Instance)
		if not inst:IsA("BasePart") or lying[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local at = inst:FindFirstChild("Take")
		local prompt = at and at:FindFirstChildOfClass("ProximityPrompt")
		local glintAt = inst:FindFirstChild("Glint")
		local glint = glintAt and glintAt:FindFirstChildOfClass("ParticleEmitter")
		local b: Lying =
			{ part = inst, prompt = prompt, size = inst.Size, glint = glint, reach = true }
		lying[inst] = b
		if inst:GetAttribute(Battery.TakenAttribute) ~= nil then
			-- taken before it reached this screen: gone at once
			lying[inst] = nil
			hide(b)
			return
		end
		if prompt then
			prompt.Enabled = wants
		end
		perBattery[inst] = {
			inst:GetAttributeChangedSignal(Battery.TakenAttribute):Connect(function()
				taken(b)
			end),
		}
	end

	local function removed(inst: Instance)
		if not inst:IsA("BasePart") then
			return
		end
		lying[inst] = nil
		local list = perBattery[inst]
		if list then
			for _, c in list do
				c:Disconnect()
			end
		end
		perBattery[inst] = nil
	end

	-- One flight's frame; true once it's over.
	local function stepFlight(f: Flight, now: number): boolean
		local part = f.part
		if not part.Parent then
			return true
		end
		local t = now - f.start
		local hopEnd = Battery.HopTime
		local done = hopEnd + Battery.Fly
		local turn = math.min(t / done, 1) * Battery.Turns * 2 * math.pi
		local spin = CFrame.fromAxisAngle(f.axis, turn)
		local rot = spin * f.from.Rotation
		if t < hopEnd then
			local up = Battery.Hop * hopCurve(t / hopEnd)
			part.CFrame = CFrame.new(f.from.Position + Vector3.new(0, up, 0)) * rot
			return false
		end
		local top = f.from.Position + Vector3.new(0, Battery.Hop, 0)
		local target = HandAt.torch(f.taker)
		if t >= done or not target then
			part.LocalTransparencyModifier = 1
			if not f.sounded then
				f.sounded = true
				local at = target or CFrame.new(top)
				local mine = f.taker == me
				local holder = Instance.new("Attachment")
				holder.WorldPosition = at.Position
				holder.Parent = Workspace.Terrain
				once(Battery.Clack, holder, if mine then nil else Battery.Heard)
				task.delay(Battery.SnapAfter, function()
					once(Battery.Snap, holder, if mine then nil else Battery.Heard)
				end)
				task.delay(1.5, function()
					holder:Destroy()
				end)
			end
			return true
		end
		local p = flyCurve((t - hopEnd) / Battery.Fly)
		local k = 1 + (Battery.Shrink - 1) * p
		part.Size = f.size * k
		part.CFrame = CFrame.new(top:Lerp(target.Position, p)) * rot
		return false
	end

	local system = { name = "BatteryView" }

	function system.start(_: any, _context: Brix.Context)
		for _, inst in CollectionService:GetTagged(Battery.Tag) do
			added(inst)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Battery.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Battery.Tag):Connect(removed)
		)
		table.insert(connections, me:GetAttributeChangedSignal(Charge.Attribute):Connect(charged))
		table.insert(connections, Workspace:GetAttributeChangedSignal(Charge.Dev):Connect(charged))
		charged()
		task.spawn(SoundPrimer.prime, { Battery.Clack.id, Battery.Snap.id })
	end

	-- Whether a shut door keeps you from each battery near you, its Take shown only while none
	-- does. One whose unit hasn't streamed in yet is reachable, as before.
	local reachAt = 0
	local function lookReach()
		local character = me.Character
		local root = character and character.PrimaryPart
		local changed = false
		for _, b in lying do
			local reach = true
			if root and (b.part.Position - root.Position).Magnitude <= REACH_NEAR then
				local v = b.part:FindFirstChild(Battery.UnitValue)
				local unit = if v and v:IsA("ObjectValue") then v.Value else nil
				if
					unit
					and unit:IsA("Model")
					and unit:FindFirstChild("DoorOrigin", true)
					and StorageUnit.RollUpDoor.keepsApart(unit, root.Position, b.part.Position)
				then
					reach = false
				end
			end
			if reach ~= b.reach then
				b.reach = reach
				changed = true
			end
		end
		if changed then
			showButtons()
		end
	end

	function system.step(_: any, _dt: number)
		local t = os.clock()
		if t - reachAt >= REACH_EVERY then
			reachAt = t
			lookReach()
		end
		if #flights == 0 then
			return
		end
		local now = os.clock()
		for i = #flights, 1, -1 do
			local f = flights[i]
			if stepFlight(f, now) then
				InFlight.land(f.taker, "torch")
				table.remove(flights, i)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, list in perBattery do
			for _, c in list do
				c:Disconnect()
			end
		end
		table.clear(perBattery)
		table.clear(lying)
		for _, f in flights do
			InFlight.land(f.taker, "torch")
		end
		table.clear(flights)
	end

	return system
end

return BatteryView
