--!strict
--[[
	Marked boxes on every screen (B-02a). The moment: a door goes up and one box in the unit has
	two thin warm lines of light along its tape and a soft hum close to; you press Open, the tape
	rips across the middle, its halves whip back and the flaps burst up with a slap. Friends near
	hear the rip from down the hall and see it from the doorway. B-02b brings the find out of it.

	A shut box (no `OpenedAt`): its seam's Neon lines lit (`Specs.Marked.Cue`), its hum looped
	while you're within `Opening.HumNear`, and the nearest within `Opening.GlowNear` gets the
	cue's warm light (one light on a screen). Its Open hidden while a shut door stands between you
	and it (the server's own rule, `RollUpDoor.keepsApart`).

	Opened: the server stamps `OpenedAt`; this screen plays `Specs.Marked.Motions.Open` from the
	stamp (`Opening.clock`: fresh, from its first frame; seen late, caught up), stepping only the
	boxes in motion. Each part turns about its hinge; the seam shrinks to nothing as the tape
	snaps, the hum and light going with it; the rip and the slap play on their beats
	(`Opening.Beats`), skipped if this screen got there too late to keep them in step. A box
	streamed in already open stands open.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Boxes = require(ReplicatedStorage.Shared.Boxes)
local Brix = require(ReplicatedStorage.Brix)
local SoundPrimer = require(script.Parent.SoundPrimer)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local Opening = Boxes.Opening
local Marked = Boxes.Marked
local Open = Marked.Motions.Open

-- How often (seconds) this screen looks at which boxes are near: their hum, the light, a shut
-- door between you and an Open.
local LOOK_EVERY = 0.2

type PartSpec = typeof(Marked.Parts[1])

type Box = {
	model: Model,
	body: BasePart,
	parts: { [string]: BasePart },
	seam: BasePart?,
	seamSize: Vector3, -- the seam's size and pivot offset as the template has them
	seamOffset: CFrame,
	unit: Model?,
	button: Vector3, -- about where its Open is, over the lid
	hum: Sound?,
	start: number?, -- the server time its open plays from, once opened
	last: number, -- seconds into the open at the last frame
	connections: { RBXScriptConnection },
}

local specs: { [string]: PartSpec } = {}
for _, spec in Marked.Parts do
	specs[spec.Name] = spec
end

local function sound(spec: Boxes.Sound, parent: Instance): Sound
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = spec.volume
	s.PlaybackSpeed = spec.pitch or 1
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
	s.Parent = parent
	return s
end

-- Plays `spec` once at the box, heard down the hall, cleaned up when it's done.
local function once(spec: Boxes.Sound, parent: Instance)
	local s = sound(spec, parent)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 6
	s.RollOffMaxDistance = Opening.Heard
	s.Ended:Once(function()
		s:Destroy()
	end)
	s:Play()
	task.delay(spec.length / (spec.pitch or 1) + 0.5, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

-- The cue's warm light, for the one shut box nearest you.
local function newLight(): PointLight
	local cue = Marked.Cue.Light
	local l = Instance.new("PointLight")
	l.Color = cue.Color
	l.Brightness = cue.Brightness
	l.Range = cue.Range
	l.Shadows = false
	return l
end

local MarkedBoxView = {}

function MarkedBoxView.new(): Brix.System
	local me = Players.LocalPlayer
	local boxes: { [Instance]: Box } = {}
	local moving: { Box } = {}
	local connections: { RBXScriptConnection } = {}
	local pose: { [string]: number } = {}
	local light: PointLight? = nil

	-- Every moving part of `b` as it stands `t` seconds into the open.
	local function poseAt(b: Box, t: number)
		Opening.pose(Open, t, pose)
		local pivot = b.body:GetPivot()
		for _, track in Open.Tracks do
			local part = b.parts[track.Part]
			local spec = specs[track.Part]
			if not (part and spec) then
				continue
			end
			local v = pose[track.Part]
			if track.Channel == "turn" then
				local axis = spec.Axis or Vector3.xAxis
				part:PivotTo(
					pivot * CFrame.new(spec.Pivot) * CFrame.fromAxisAngle(axis, math.rad(v))
				)
			elseif part == b.seam then
				-- the lines shrink into the tape's middle as it snaps, then they're gone
				local base = b.seamSize
				part.Size = Vector3.new(
					Opening.thin(base.X, v),
					Opening.thin(base.Y, v),
					Opening.thin(base.Z, v)
				)
				part.PivotOffset = CFrame.new(b.seamOffset.Position * v) * b.seamOffset.Rotation
				part:PivotTo(pivot * CFrame.new(spec.Pivot))
				part.Transparency = if v <= 0.02 then 1 else Marked.Cue.Transparency
			end
		end
		local hum = b.hum
		if hum then
			local share = Opening.hum(t)
			if share <= 0 then
				hum:Destroy()
				b.hum = nil
			else
				hum.Volume = Boxes.Sounds.Hum.volume * share
			end
		end
		if t >= Opening.Beats.Tear and light and light.Parent == b.body then
			light.Enabled = false
		end
	end

	local function opened(b: Box)
		if b.start then
			return
		end
		local at = b.model:GetAttribute(Opening.OpenedAt)
		if type(at) ~= "number" then
			return
		end
		local now = Workspace:GetServerTimeNow()
		local start = Opening.clock(at, now)
		b.start = start
		local t = now - start
		if Opening.settled(Open, t) then
			poseAt(b, Open.Duration) -- opened before it reached this screen: it stands open
			return
		end
		b.last = 0
		table.insert(moving, b)
	end

	local function added(inst: Instance)
		if not inst:IsA("Model") or boxes[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local body = inst.PrimaryPart
		if not body then
			return
		end
		local parts: { [string]: BasePart } = {}
		for name in specs do
			local part = inst:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				parts[name] = part
			end
		end
		local seam = parts[Marked.Cue.Part]
		local unitValue = inst:FindFirstChild(Opening.UnitValue)
		local unit = if unitValue and unitValue:IsA("ObjectValue") then unitValue.Value else nil
		local b: Box = {
			model = inst,
			body = body,
			parts = parts,
			seam = seam,
			seamSize = if seam then seam.Size else Vector3.one,
			seamOffset = if seam then seam.PivotOffset else CFrame.identity,
			unit = if unit and unit:IsA("Model") then unit else nil,
			button = body:GetPivot().Position + Vector3.new(0, Marked.Size.Y, 0),
			hum = nil,
			start = nil,
			last = 0,
			connections = {},
		}
		boxes[inst] = b
		table.insert(
			b.connections,
			inst:GetAttributeChangedSignal(Opening.OpenedAt):Connect(function()
				opened(b)
			end)
		)
		if inst:GetAttribute(Opening.OpenedAt) ~= nil then
			opened(b)
			return
		end
		-- shut, something inside: the lines lit and the hum ready for when you come near
		if seam then
			seam.Transparency = Marked.Cue.Transparency
		end
		local hum = sound(Boxes.Sounds.Hum, body)
		hum.Looped = true
		hum.LoopRegion = hum.PlaybackRegion
		hum.RollOffMode = Enum.RollOffMode.InverseTapered
		hum.RollOffMinDistance = Opening.HumFull
		hum.RollOffMaxDistance = Opening.HumHeard
		b.hum = hum
	end

	local function removed(inst: Instance)
		local b = if inst:IsA("Model") then boxes[inst] else nil
		if not b then
			return
		end
		boxes[inst] = nil
		for _, c in b.connections do
			c:Disconnect()
		end
		local i = table.find(moving, b)
		if i then
			table.remove(moving, i)
		end
		if b.hum then
			b.hum:Destroy()
		end
	end

	-- Which shut boxes are near you: each one's hum, the warm light on the nearest, and whether a
	-- shut door keeps you from its Open.
	local function look()
		local character = me.Character
		local root = character and character.PrimaryPart
		if not root then
			return
		end
		local from = root.Position
		local nearest: Box? = nil
		local nearestAt = Opening.GlowNear
		for _, b in boxes do
			if b.start then
				continue
			end
			local d = (b.button - from).Magnitude
			local hum = b.hum
			if hum then
				local near = d <= Opening.HumNear
				if near and not hum.IsPlaying then
					hum.TimePosition = math.random() * Boxes.Sounds.Hum.length -- out of step
					hum:Play()
				elseif not near and hum.IsPlaying then
					hum:Stop()
				end
			end
			if d < nearestAt then
				nearest, nearestAt = b, d
			end
			local open = b.model:FindFirstChild("Open", true)
			local prompt = open and open:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				local unit = b.unit
				local apart = d <= Opening.HumNear
					and unit ~= nil
					and unit:FindFirstChild("DoorOrigin", true) ~= nil
					and StorageUnit.RollUpDoor.keepsApart(unit, from, b.button)
				if prompt.Enabled == apart then
					prompt.Enabled = not apart
				end
			end
		end
		if nearest then
			local l = light
			if l == nil or l.Parent == nil then
				l = newLight()
				light = l
			end
			if l then
				l.Parent = nearest.body
				l.Enabled = true
			end
		elseif light then
			light.Enabled = false
		end
	end

	local system = { name = "MarkedBoxView" }

	function system.start(_: any, _context: Brix.Context)
		for _, inst in CollectionService:GetTagged(Opening.Tag) do
			added(inst)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Opening.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Opening.Tag):Connect(removed)
		)
		local s = Boxes.Sounds
		task.spawn(SoundPrimer.prime, { s.Tear.id, s.Flaps.id, s.Hum.id })
	end

	local lookAt = 0
	function system.step(_: any, _dt: number)
		local clock = os.clock()
		if clock - lookAt >= LOOK_EVERY then
			lookAt = clock
			look()
		end
		if #moving == 0 then
			return
		end
		local now = Workspace:GetServerTimeNow()
		for i = #moving, 1, -1 do
			local b = moving[i]
			local t = now - (b.start :: number)
			for _, beat in Opening.due(b.last, t) do
				once(Boxes.Sounds[beat], b.body)
			end
			b.last = t
			if Opening.settled(Open, t) then
				poseAt(b, Open.Duration)
				table.remove(moving, i)
			else
				poseAt(b, t)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for inst in boxes do
			removed(inst)
		end
		table.clear(moving)
		if light then
			light:Destroy()
			light = nil
		end
	end

	return system
end

return MarkedBoxView
