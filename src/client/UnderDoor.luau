--!strict
--[[
	UnderDoor: the hall's light under your door, while you're kept (L-07c). Alone in the dark,
	facing the shut door, a thin warm line shows where the door meets the floor, with a faint
	spill across the floor inside, but only while the hall light outside it is on. The hall's
	motion lights trip for anyone walking by (MotionLight; never for the Mannequin, GDD "Lights"),
	so the line flickering on means someone is out there. As the tube flickers on, so does the
	line (`HallLight.Flicker`); as it cuts out, the line goes.

	The server names the unit you're kept in (`Kept.InsideValue`, an ObjectValue under you, from
	KeptPlayers); the line is this screen's own, two parts no one else has, gone as you're let
	out. No real light: a glowing strip and a fading spill (the GDD's cap on lights).

	It steps only while you're kept inside a unit.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Floor = require(ReplicatedStorage.Shared.Floor)
local HallLight = require(ReplicatedStorage.Shared.HallLight)
local Kept = require(ReplicatedStorage.Shared.Kept)
local MotionLight = require(ReplicatedStorage.Shared.MotionLight)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)

local WARM = Color3.fromRGB(255, 212, 158) -- the hall's tube through a crack: warmer than it looks in the hall
local STRIP_HIGH = 0.05 -- studs: the gap under the door
local STRIP_DEEP = 0.08
local STRIP_SEE = 0.15 -- the line's transparency, full on: bright, but not a lamp
local SPILL = 1.6 -- studs the spill reaches across the floor inside
local SPILL_SEE = 0.78 -- the spill's transparency at the door, full on: a hint of light, not a pool
local BEHIND = 0.25 -- studs in from the curtain to the bottom bar's inner face, if the door has no bar
local NEAR = 18 -- studs from the hall outside your door to a fixture whose light reaches under it
local OFF = 0.15 -- seconds the line takes to go as the tube cuts out
local FIND_EVERY = 0.5 -- seconds between looks for the fixture, until it's streamed in

type Shown = {
	unit: Model,
	strip: BasePart,
	spill: Frame,
	fixture: Instance?,
	findIn: number,
	lit: number, -- os.clock the fixture was last seen coming on, or -1 while it's dark
	level: number,
}

-- The parts for `unit`'s door, drawn on this screen only.
local function build(unit: Model): (BasePart, Frame)
	local spec = RollUpDoor.spec(unit)
	local frame = RollUpDoor.frame(unit) -- looking out to the hall: +Z is inside
	-- right against the door's bottom bar, on the inside (the collider is deeper than the door)
	local behind = BEHIND
	local bar = unit:FindFirstChild("BottomBar", true)
	if bar and bar:IsA("BasePart") then
		local depth = math.abs(frame:VectorToObjectSpace(bar.CFrame:VectorToWorldSpace(bar.Size)).Z)
		behind = frame:PointToObjectSpace(bar.Position).Z + depth / 2
	end
	local strip = Instance.new("Part")
	strip.Name = "UnderDoor"
	strip.Anchored = true
	strip.CanCollide, strip.CanTouch, strip.CanQuery = false, false, false
	strip.CastShadow = false
	strip.Material = Enum.Material.Neon
	strip.Color = WARM
	strip.Transparency = 1
	strip.Size = Vector3.new(spec.DoorWidth, STRIP_HIGH, STRIP_DEEP)
	strip.CFrame = frame * CFrame.new(0, STRIP_HIGH / 2, behind + STRIP_DEEP / 2)
	local floor = Instance.new("Part")
	floor.Name = "UnderDoorSpill"
	floor.Anchored = true
	floor.CanCollide, floor.CanTouch, floor.CanQuery = false, false, false
	floor.CastShadow = false
	floor.Transparency = 1
	floor.Size = Vector3.new(spec.DoorWidth, 0.02, SPILL)
	floor.CFrame = frame * CFrame.new(0, 0.015, behind + SPILL / 2)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.Parent = floor
	local spill = Instance.new("Frame")
	spill.Size = UDim2.fromScale(1, 1)
	spill.BorderSizePixel = 0
	spill.BackgroundColor3 = WARM
	spill.BackgroundTransparency = 1
	spill.Parent = gui
	local fade = Instance.new("UIGradient")
	-- brightest at the door, gone across the floor: a Top face's x runs along the part's depth
	-- from its inside end (seen in Studio), so the gradient is turned to start at the door
	fade.Rotation = 180
	fade.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	fade.Parent = spill
	local camera = Workspace.CurrentCamera
	strip.Parent = camera
	floor.Parent = camera
	return strip, spill
end

-- The motion light over the hall outside `unit`'s door, if it's streamed in.
local function fixtureFor(unit: Model): Instance?
	local hall = RollUpDoor.frame(unit)
		* Vector3.new(0, 0, -(RollUpDoor.spec(unit).CurtainPlane + Floor.HallWidth / 2))
	local best, near = nil :: Instance?, NEAR
	for _, f in CollectionService:GetTagged(MotionLight.Tag) do
		if f:IsA("Model") then
			local d = f:GetPivot().Position - hall
			local flat = Vector2.new(d.X, d.Z).Magnitude
			if flat < near and math.abs(d.Y) < 16 then
				best, near = f, flat
			end
		end
	end
	return best
end

-- How bright a tube is `since` seconds after it tripped, as HallLight flickers it on.
local function flicker(since: number): number
	local level = 0
	for _, step in HallLight.Flicker do
		if since >= step.at then
			level = step.level
		end
	end
	return level
end

local UnderDoor = {}

function UnderDoor.new(): Brix.System
	local me = Players.LocalPlayer
	local shown: Shown? = nil
	local connections: { RBXScriptConnection } = {}
	local watching: RBXScriptConnection? = nil

	local function hide()
		local s = shown
		if s then
			shown = nil
			s.strip:Destroy()
			local spillPart = s.spill:FindFirstAncestorWhichIsA("BasePart")
			if spillPart then
				spillPart:Destroy()
			end
		end
	end

	-- Shows the line under the door of the unit `value` names, or none.
	local function show(value: ObjectValue?)
		local unit = value and value.Value
		if shown and shown.unit == unit then
			return
		end
		hide()
		if not (unit and unit:IsA("Model")) then
			return
		end
		local ok, strip, spill = pcall(build, unit)
		if not ok then
			warn(`UnderDoor: can't draw the light under {unit:GetFullName()}'s door: {strip}`)
			return
		end
		shown = {
			unit = unit,
			strip = strip,
			spill = spill,
			fixture = nil,
			findIn = 0,
			lit = -1,
			level = 0,
		}
	end

	local function watch(child: Instance)
		if child.Name ~= Kept.InsideValue or not child:IsA("ObjectValue") then
			return
		end
		if watching then
			watching:Disconnect()
		end
		watching = child.Changed:Connect(function()
			show(child)
		end)
		show(child)
	end

	local system = { name = "UnderDoor" }

	function system.start(_: any, _context: Brix.Context)
		table.insert(connections, me.ChildAdded:Connect(watch))
		table.insert(
			connections,
			me.ChildRemoved:Connect(function(child: Instance)
				if child.Name == Kept.InsideValue then
					if watching then
						watching:Disconnect()
						watching = nil
					end
					show(nil)
				end
			end)
		)
		local value = me:FindFirstChild(Kept.InsideValue)
		if value then
			watch(value)
		end
	end

	function system.step(_: any, dt: number)
		local s = shown
		if not s then
			return
		end
		if not s.unit.Parent then
			hide()
			return
		end
		local f = s.fixture
		if not (f and f.Parent) then
			s.fixture = nil
			s.findIn -= dt
			if s.findIn <= 0 then
				s.findIn = FIND_EVERY
				s.fixture = fixtureFor(s.unit)
			end
			f = s.fixture
		end
		local on = f ~= nil and f:GetAttribute(MotionLight.StateAttribute) == "Lit"
		local level: number
		if on then
			if s.lit < 0 then
				s.lit = os.clock()
			end
			level = flicker(os.clock() - s.lit)
		else
			s.lit = -1
			level = math.max(0, s.level - dt / OFF)
		end
		if level == s.level then
			return
		end
		s.level = level
		s.strip.Transparency = 1 - (1 - STRIP_SEE) * level
		s.spill.BackgroundTransparency = 1 - (1 - SPILL_SEE) * level
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		if watching then
			watching:Disconnect()
			watching = nil
		end
		hide()
	end

	return system :: any -- any: a plain Brix system built field by field
end

return UnderDoor
