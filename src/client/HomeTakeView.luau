--!strict
--[[
	HomeTakeView: taking a find straight from where it stands in your home, on every screen
	(S5-03i2a, D-350). The moment: you walk up to the teddy in your shelf, press Take, and it hops
	off its cubby and flies into your hand with its pick-up sound, as a find on a climb comes up
	off the floor; the cubby is simply empty after.

	Its button (the server's, Takes): shown only on its holder's screen, on a find in a cubby
	(`Shelf.Tag`) or set out (`Spots.Tag`), and never while Arrange is open (your tools are stowed
	then, `Tools.StowAttribute`). A friend in your home sees no Take on your things.

	A take, on every screen: the server stamps the standing copy with its taker (`Take.Attribute`).
	It goes from view, and a copy of it hops up (`Take.Hop`) and flies into the taker's hand
	(`HandAt.tool`), turning a little and growing back to its own size from a cubby's shrunk one;
	the pick-up sound plays as it lands (yours in your hand, a friend's heard from close by). Your
	own hand stays empty until it lands (InFlight), then it's simply there. Only flights step.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Take = require(ReplicatedStorage.Shared.Home.Take)
local Tools = require(ReplicatedStorage.Shared.Tools)
local HandAt = require(script.Parent.HandAt)
local InFlight = require(script.Parent.InFlight)

-- A find standing in a home on this screen: its button, and whose home it stands in.
type Standing = {
	model: Model,
	prompt: ProximityPrompt?,
	ownerAttribute: string,
	connection: RBXScriptConnection,
}

-- A taken find's copy on its way to a hand.
type Flight = {
	copy: Model,
	from: CFrame,
	fromScale: number,
	key: string,
	taker: Player,
	start: number,
}

local TAU = 2 * math.pi

local function hopCurve(p: number): number
	return 1 - (1 - p) * (1 - p)
end

-- Slow off the top, then quicker into the hand.
local function flyCurve(p: number): number
	return p * p * (3 - 2 * p) * 0.4 + p * p * 0.6
end

local function hide(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
		end
	end
end

-- The find's Take (on its "Take" attachment): a find set out has its own button too (HomeUses).
local function takeOf(model: Model): ProximityPrompt?
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") and d.Parent and d.Parent.Name == "Take" then
			return d
		end
	end
	return nil
end

local HomeTakeView = {}

function HomeTakeView.new(): Brix.System
	local me = Players.LocalPlayer
	local standing: { [Model]: Standing } = {}
	local flights: { Flight } = {}
	local connections: { RBXScriptConnection } = {}
	local stepping: RBXScriptConnection? = nil

	local function show(s: Standing)
		local prompt = s.prompt
		if prompt then
			local want = s.model:GetAttribute(s.ownerAttribute) == me.UserId
				and me:GetAttribute(Tools.StowAttribute) ~= true
				and s.model:GetAttribute(Take.Attribute) == nil
			if prompt.Enabled ~= want then
				prompt.Enabled = want
			end
		end
	end

	-- The copy reached the hand (or the hand is gone): its sound, and your hand shows it.
	local function land(f: Flight, at: CFrame?)
		f.copy:Destroy()
		local row = (Tools.Catalog :: any)[f.key] -- any: the catalog is keyed by text
		if row and row.pickUp then
			local holder = Instance.new("Attachment")
			holder.WorldPosition = if at then at.Position else f.from.Position
			holder.Parent = Workspace.Terrain
			Tools.play(row.pickUp, holder, Take.Heard)
			task.delay(2, function()
				holder:Destroy()
			end)
		end
		if f.taker == me then
			InFlight.land(me, "tool")
		end
	end

	-- One flight's frame; true once it's over.
	local function stepFlight(f: Flight, now: number): boolean
		if not f.copy.Parent then
			if f.taker == me then
				InFlight.land(me, "tool")
			end
			return true
		end
		local t = now - f.start
		local done = Take.HopTime + Take.Fly
		local spin = CFrame.Angles(0, Take.Spin * TAU * math.min(t / done, 1), 0)
		if t < Take.HopTime then
			local up = Take.Hop * hopCurve(t / Take.HopTime)
			f.copy:PivotTo(
				CFrame.new(f.from.Position + Vector3.new(0, up, 0)) * spin * f.from.Rotation
			)
			return false
		end
		local target = HandAt.tool(f.taker, f.key)
		if t >= done or not target then
			land(f, target)
			return true
		end
		local p = flyCurve((t - Take.HopTime) / Take.Fly)
		local top = f.from.Position + Vector3.new(0, Take.Hop, 0)
		local turn = (spin * f.from.Rotation):Lerp(target.Rotation, p)
		if f.fromScale ~= 1 then
			f.copy:ScaleTo(f.fromScale + (1 - f.fromScale) * p)
		end
		f.copy:PivotTo(CFrame.new(top:Lerp(target.Position, p)) * turn)
		return false
	end

	local function step()
		local now = os.clock()
		for i = #flights, 1, -1 do
			if stepFlight(flights[i], now) then
				table.remove(flights, i)
			end
		end
		if #flights == 0 and stepping then
			stepping:Disconnect()
			stepping = nil
		end
	end

	local function taken(s: Standing)
		local model = s.model
		if s.prompt then
			s.prompt.Enabled = false
		end
		local id = model:GetAttribute(Take.Attribute)
		local taker = if type(id) == "number" then Players:GetPlayerByUserId(id) else nil
		local key = model:GetAttribute(Tools.KindAttribute)
		if not (taker and type(key) == "string") then
			hide(model)
			return
		end
		local copy = model:Clone()
		hide(model)
		for _, tag in copy:GetTags() do
			copy:RemoveTag(tag) -- a copy in flight is nobody's shelf find
		end
		for _, d in copy:GetDescendants() do
			if d:IsA("ProximityPrompt") or (d:IsA("Attachment") and d.Name == "Take") then
				d:Destroy()
			end
		end
		copy:SetAttribute(Take.Attribute, nil)
		copy.Name = "TakenFind"
		copy.Parent = Workspace
		if taker == me then
			InFlight.hold(me, "tool") -- your hand stays empty until it lands
		end
		table.insert(flights, {
			copy = copy,
			from = copy:GetPivot(),
			fromScale = copy:GetScale(),
			key = key,
			taker = taker,
			start = os.clock(),
		})
		if not stepping then
			stepping = RunService.RenderStepped:Connect(step)
		end
	end

	local function added(inst: Instance, ownerAttribute: string)
		if not inst:IsA("Model") or standing[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local s: Standing
		s = {
			model = inst,
			prompt = takeOf(inst),
			ownerAttribute = ownerAttribute,
			connection = inst:GetAttributeChangedSignal(Take.Attribute):Connect(function()
				taken(s)
			end),
		}
		standing[inst] = s
		if inst:GetAttribute(Take.Attribute) ~= nil then
			hide(inst) -- taken before it reached this screen: gone at once
		end
		show(s)
	end

	local function removed(inst: Instance)
		if not inst:IsA("Model") then
			return
		end
		local s = standing[inst]
		if s then
			s.connection:Disconnect()
			standing[inst] = nil
		end
	end

	local function watch(tag: string, ownerAttribute: string)
		for _, inst in CollectionService:GetTagged(tag) do
			added(inst, ownerAttribute)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst: Instance)
				added(inst, ownerAttribute)
			end)
		)
		table.insert(connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(removed))
	end

	local system = { name = "HomeTakeView" }

	function system.start(_: any, _context: Brix.Context)
		watch(Shelf.Tag, Shelf.OwnerAttribute)
		watch(Spots.Tag, Spots.OwnerAttribute)
		-- Arrange open: your tools are stowed, and no Take shows over the room
		table.insert(
			connections,
			me:GetAttributeChangedSignal(Tools.StowAttribute):Connect(function()
				for _, s in standing do
					show(s)
				end
			end)
		)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, s in standing do
			s.connection:Disconnect()
		end
		table.clear(standing)
		if stepping then
			stepping:Disconnect()
			stepping = nil
		end
		for _, f in flights do
			land(f, nil)
		end
		table.clear(flights)
	end

	return system
end

return HomeTakeView
