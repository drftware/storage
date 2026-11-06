--!strict
--[[
	RollUpDoor: one number drives the whole door.

	Server (authoritative; the GDD's door state machine calls these after its own checks):
		RollUpDoor.play(unit, "Open")         -- Peek | Open | Close | Slam | LiftInside
		RollUpDoor.setLocked(unit, true)      -- shoots the bolt, hangs the padlock (shut doors)
		RollUpDoor.rise(unit) --> number      -- where the door is right now, in studs

	Client (renders every unit the server moves; the client's DoorView system calls it):
		local stop = RollUpDoor.watchTagged("StorageUnit")

	Anywhere (cutscenes, Studio previews, a viewport):
		local rig = RollUpDoor.rig(unit)
		rig:pose(3.2, false)                  -- any rise, instantly
		rig:destroy()

	How it stays cheap: the server replicates one string attribute per move (Motion.encode)
	and moves an invisible DoorCollider; it never moves a visual part. A shut door is one
	merged mesh (CurtainClosed). Only while a door moves or stands open does its client
	clone the 38-slat chain from three templates, posed with one BulkMoveTo per frame.
	Place and paint units before parenting them to Workspace: rigs cache the door's frame.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Curtain = require(script.Parent.Curtain)
local Motion = require(script.Parent.Motion)
local Specs = require(script.Parent.Specs)

type Spec = Specs.Spec

local ATTR_MOTION = "DoorMotion"
local ATTR_LOCKED = "DoorLocked"
local ATTR_SIZE = "UnitSize"
local ATTR_OFFSET = "DoorOffset" -- CFrame, stored by UnitKit.prepare on each moving part
local SHUT = 1e-4

type Moving = { part: BasePart, offset: CFrame }
type Playing = {
	kind: Motion.Kind,
	from: number,
	to: number,
	start: number,
	dur: number,
	locked: boolean,
}

export type Rig = {
	unit: Model,
	spec: Spec,
	curtain: Curtain.Curtain,
	frame: CFrame,
	slats: { BasePart },
	slatOffsets: { CFrame },
	templates: { [string]: BasePart },
	templateOffsets: { [string]: CFrame },
	chain: Folder?,
	closed: Moving?,
	bar: Moving?,
	bolt: Moving?,
	lock: Moving?,
	drum: Moving?,
	buf: { number },
	phi: number?,
	parts: { BasePart },
	cframes: { CFrame },
	motion: Playing,
	conns: { RBXScriptConnection },
	pose: (self: Rig, rise: number, locked: boolean?, moving: boolean?) -> (),
	destroy: (self: Rig) -> (),
}

local RollUpDoor = {}

local curtains: { [string]: Curtain.Curtain } = {}

local function specFor(unit: Model): Spec
	local size = unit:GetAttribute(ATTR_SIZE)
	local spec = Specs[if type(size) == "string" then size else "M"]
	assert(spec, `RollUpDoor: no spec for unit size {size}`)
	return spec
end

local function curtainFor(spec: Spec): Curtain.Curtain
	local c = curtains[spec.Size]
	if not c then
		c = Curtain.new(spec.Curtain)
		curtains[spec.Size] = c
	end
	return c
end

--[[
	The door-local frame in world space: on DoorOrigin, looking out to the hallway. The look
	direction comes from the drum (always behind the curtain), so the rig is right even if an
	importer turned the helper cube.
]]
function RollUpDoor.frame(unit: Model): CFrame
	local origin = unit:FindFirstChild("DoorOrigin", true) :: BasePart?
	assert(origin, `RollUpDoor: {unit:GetFullName()} has no DoorOrigin`)
	local p = origin.Position
	local look = origin.CFrame.LookVector
	local drum = unit:FindFirstChild("Drum", true) :: BasePart?
	if drum then
		local away = (p - drum.Position) * Vector3.new(1, 0, 1)
		if away.Magnitude > 1e-3 then
			look = away.Unit
		end
	end
	return CFrame.lookAt(p, p + look, Vector3.yAxis)
end

local function restFrame(spec: Spec, name: string): CFrame
	local r = (spec.Rest :: any)[name]
	return CFrame.new(r.Position) * CFrame.Angles(r.RotX, 0, 0)
end

-- How a part sits relative to its logical frame: stored by UnitKit.prepare, else measured now
-- (which assumes the unit is as imported: door shut and locked).
function RollUpDoor.offset(part: BasePart, frame: CFrame, spec: Spec, name: string): CFrame
	local stored = part:GetAttribute(ATTR_OFFSET)
	if typeof(stored) == "CFrame" then
		return stored
	end
	return restFrame(spec, name):Inverse() * frame:ToObjectSpace(part.CFrame)
end

local function moving(unit: Model, frame: CFrame, spec: Spec, name: string): Moving?
	local part = unit:FindFirstChild(name, true) :: BasePart?
	if not part then
		return nil
	end
	return { part = part, offset = RollUpDoor.offset(part, frame, spec, name) }
end

local Rig = {}
Rig.__index = Rig

function RollUpDoor.rig(unit: Model): Rig
	local spec = specFor(unit)
	local frame = RollUpDoor.frame(unit)
	local stale = unit:FindFirstChild("Curtain")
	if stale then
		stale:Destroy() -- a chain cloned along with its unit
	end
	local self = setmetatable({
		unit = unit,
		spec = spec,
		curtain = curtainFor(spec),
		frame = frame,
		slats = {},
		slatOffsets = {},
		templates = {},
		templateOffsets = {},
		chain = nil,
		closed = moving(unit, frame, spec, "CurtainClosed"),
		bar = moving(unit, frame, spec, "BottomBar"),
		bolt = moving(unit, frame, spec, "LatchBolt"),
		lock = moving(unit, frame, spec, "Padlock"),
		drum = moving(unit, frame, spec, "Drum"),
		buf = table.create(spec.Curtain.Count * 4, 0),
		phi = nil,
		parts = {},
		cframes = {},
		motion = { kind = "Close", from = 0, to = 0, start = 0, dur = 0, locked = false },
		conns = {},
	}, Rig) :: any
	for _, v in { "A", "B", "C" } do
		local t = unit:FindFirstChild("Slat_" .. v, true) :: BasePart?
		assert(t, `RollUpDoor: {unit:GetFullName()} has no Slat_{v}`)
		self.templates[v] = t
		self.templateOffsets[v] = RollUpDoor.offset(t, frame, spec, "Slat_" .. v)
		t.Transparency = 1 -- clone sources only
		table.insert(
			self.conns,
			t:GetPropertyChangedSignal("Color"):Connect(function()
				for i, s in self.slats do
					if spec.SlatOrder[i] == v then
						s.Color = t.Color
					end
				end
			end)
		)
	end
	return self :: Rig
end

local function buildChain(self: Rig)
	if self.chain then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Curtain"
	for i, v in self.spec.SlatOrder do
		local s = self.templates[v]:Clone()
		s.Name = "Slat" .. i
		s.Transparency = 0
		s.Parent = folder
		self.slats[i] = s
		self.slatOffsets[i] = self.templateOffsets[v]
	end
	folder.Parent = self.unit
	self.chain = folder
end

local function dropChain(self: Rig)
	table.clear(self.slats)
	table.clear(self.slatOffsets)
	self.phi = nil
	if self.chain then
		self.chain:Destroy()
		self.chain = nil
	end
end

--[[
	Pose the door at `rise`. A door at rest (rise 0, not `moving`) shows its one merged
	CurtainClosed mesh and frees the chain; anything else poses the chain.
]]
function Rig.pose(self: Rig, rise: number, locked: boolean?, isMoving: boolean?)
	local spec = self.spec
	rise = math.clamp(rise, 0, spec.Rise.Open + 0.4)
	local useChain = isMoving == true or rise > SHUT or not self.closed
	local parts, cframes = self.parts, self.cframes
	local f = self.frame
	local n = 0
	local drumAngle = 0
	if useChain then
		buildChain(self)
		local st = self.curtain:slats(rise, self.buf, self.phi)
		self.phi = st.phi
		drumAngle = self.curtain:drumAngle(st)
		local buf = self.buf
		for i, s in self.slats do
			local j = 4 * (i - 1)
			local dz, dy = buf[j + 3], buf[j + 4]
			n += 1
			parts[n] = s
			-- rotation about X taking +Y up the curtain: (dirY, -dirZ) in door-local Y/Z
			cframes[n] = f
				* CFrame.new(0, buf[j + 2], -buf[j + 1], 1, 0, 0, 0, dy, dz, 0, -dz, dy)
				* self.slatOffsets[i]
		end
	else
		dropChain(self)
	end
	if self.closed then
		self.closed.part.Transparency = if useChain then 1 else 0
		if not useChain then
			n += 1
			parts[n] = self.closed.part
			cframes[n] = f * self.closed.offset
		end
	end
	local barCf = f * CFrame.new(0, spec.BarTopClosed + rise, 0)
	if self.bar then
		n += 1
		parts[n] = self.bar.part
		cframes[n] = barCf * self.bar.offset
	end
	if self.bolt then
		n += 1
		parts[n] = self.bolt.part
		cframes[n] = barCf
			* CFrame.new(if locked then 0 else spec.LatchThrow, 0, 0)
			* self.bolt.offset
	end
	if self.lock then
		n += 1
		parts[n] = self.lock.part
		cframes[n] = barCf * self.lock.offset
		self.lock.part.Transparency = if locked then 0 else 1
	end
	if self.drum then
		n += 1
		parts[n] = self.drum.part
		cframes[n] = f
			* CFrame.new(0, spec.Curtain.DrumY, -spec.Curtain.DrumZ)
			* CFrame.Angles(drumAngle, 0, 0)
			* self.drum.offset
	end
	for k = n + 1, #parts do
		parts[k] = nil
		cframes[k] = nil
	end
	Workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

-- Put the unit back as imported (shut, merged curtain) and stop listening.
function Rig.destroy(self: Rig)
	for _, c in self.conns do
		c:Disconnect()
	end
	table.clear(self.conns)
	dropChain(self)
	if self.unit.Parent then
		self:pose(0, self.unit:GetAttribute(ATTR_LOCKED) == true, false)
	end
	if not self.closed then
		for _, t in self.templates do
			t.Transparency = 0
		end
	end
end

-- --- replicated motion ---------------------------------------------------------------------

local function now(): number
	return Workspace:GetServerTimeNow()
end

-- Where a unit's door is at time `t` (default: now), from its motion attribute.
function RollUpDoor.rise(unit: Model, t: number?): number
	local spec = specFor(unit)
	local kind: Motion.Kind, from: number, to: number, start: number =
		Motion.decode(unit:GetAttribute(ATTR_MOTION) :: string?)
	return Motion.sample(kind, from, to, (t or now()) - start, spec.Rise.Open)
end

type ServerMove = {
	spec: Spec,
	frame: CFrame,
	col: BasePart?,
	kind: Motion.Kind,
	from: number,
	to: number,
	start: number,
	ends: number,
}

local serverMoving: { [Model]: ServerMove } = {}
local serverConn: RBXScriptConnection? = nil

local function placeCollider(m: ServerMove, rise: number)
	local col = m.col
	if not col then
		return
	end
	local bottom = m.spec.Gap + rise
	local h = math.max(m.spec.DoorHeight - bottom, 0.05)
	col.CanCollide = h > 0.25
	col.Size = Vector3.new(m.spec.DoorWidth, h, 0.4)
	col.CFrame = m.frame * CFrame.new(0, bottom + h / 2, 0)
end

local function serverStep()
	local t = now()
	for unit, m in serverMoving do
		if not unit.Parent then
			serverMoving[unit] = nil
			continue
		end
		placeCollider(m, Motion.sample(m.kind, m.from, m.to, t - m.start, m.spec.Rise.Open))
		if t >= m.ends then
			serverMoving[unit] = nil
		end
	end
	if next(serverMoving) == nil and serverConn then
		serverConn:Disconnect()
		serverConn = nil
	end
end

--[[
	Server: start a door action from wherever the door is now. Returns its duration in seconds,
	or 0 when refused: a padlocked door won't lift (the GDD's bolt cutters come first).
]]
function RollUpDoor.play(unit: Model, kind: Motion.Kind): number
	assert(RunService:IsServer(), "RollUpDoor.play is server-only")
	assert(Motion.isKind(kind), `RollUpDoor.play: unknown door action {kind}`)
	local spec = specFor(unit)
	local frame = RollUpDoor.frame(unit)
	local t = now()
	local from = RollUpDoor.rise(unit, t)
	local to = Motion.target(kind, spec.Rise)
	if unit:GetAttribute(ATTR_LOCKED) == true and to > from then
		return 0
	end
	local dur = Motion.duration(kind, from, to, spec.Rise.Open)
	unit:SetAttribute(ATTR_MOTION, Motion.encode(kind, from, to, t))
	local m: ServerMove = {
		spec = spec,
		frame = frame,
		col = unit:FindFirstChild("DoorCollider") :: BasePart?,
		kind = kind,
		from = from,
		to = to,
		start = t,
		ends = t + dur,
	}
	placeCollider(m, from)
	serverMoving[unit] = m
	if not serverConn then
		serverConn = RunService.Heartbeat:Connect(serverStep)
	end
	return dur
end

-- Server: lock or unlock. Locking needs the door down and still; returns whether it took.
function RollUpDoor.setLocked(unit: Model, locked: boolean): boolean
	if locked and (serverMoving[unit] or RollUpDoor.rise(unit) > 0.05) then
		return false
	end
	unit:SetAttribute(ATTR_LOCKED, locked)
	return true
end

-- --- client rendering ------------------------------------------------------------------------

local rigs: { [Model]: Rig } = {}
local active: { [Model]: Rig } = {}
local clientConn: RBXScriptConnection? = nil

local function step(rig: Rig, t: number): boolean
	local m = rig.motion
	local el = t - m.start
	local done = el >= m.dur
	rig:pose(Motion.sample(m.kind, m.from, m.to, el, rig.spec.Rise.Open), m.locked, not done)
	return done
end

local function clientStep()
	local t = now()
	for unit, rig in active do
		if step(rig, t) then
			active[unit] = nil
		end
	end
	if next(active) == nil and clientConn then
		clientConn:Disconnect()
		clientConn = nil
	end
end

local function refresh(unit: Model)
	local rig = rigs[unit]
	if not rig then
		return
	end
	local kind: Motion.Kind, from: number, to: number, start: number =
		Motion.decode(unit:GetAttribute(ATTR_MOTION) :: string?)
	rig.motion = {
		kind = kind,
		from = from,
		to = to,
		start = start,
		dur = Motion.duration(kind, from, to, rig.spec.Rise.Open),
		locked = unit:GetAttribute(ATTR_LOCKED) == true,
	}
	if step(rig, now()) then -- pose now, so nothing shows a frame out of place
		active[unit] = nil
		return
	end
	active[unit] = rig
	if not clientConn then
		clientConn = RunService.Heartbeat:Connect(clientStep)
	end
end

local function unbind(unit: Instance)
	local rig = rigs[unit :: Model]
	if not rig then
		return
	end
	rigs[unit :: Model] = nil
	active[unit :: Model] = nil
	rig:destroy()
end

local function bind(unit: Instance)
	-- only units in the world: a tagged template in ReplicatedStorage stays untouched
	if not unit:IsA("Model") or rigs[unit] or not unit:IsDescendantOf(Workspace) then
		return
	end
	local ok, rig = pcall(RollUpDoor.rig, unit)
	if not ok then
		warn(rig)
		return
	end
	rigs[unit] = rig
	table.insert(
		rig.conns,
		unit:GetAttributeChangedSignal(ATTR_MOTION):Connect(function()
			refresh(unit)
		end)
	)
	table.insert(
		rig.conns,
		unit:GetAttributeChangedSignal(ATTR_LOCKED):Connect(function()
			refresh(unit)
		end)
	)
	table.insert(
		rig.conns,
		unit.Destroying:Connect(function()
			unbind(unit)
		end)
	)
	refresh(unit)
end

--[[
	Client: render every unit carrying `tag`, now and as they stream in or out. Returns a
	function that stops watching and lets go of every door it was drawing.
]]
function RollUpDoor.watchTagged(tag: string): () -> ()
	local watching = true
	local function bindWhileWatching(unit: Instance)
		if watching then
			bind(unit)
		end
	end
	local added = CollectionService:GetInstanceAddedSignal(tag):Connect(bindWhileWatching)
	local removed = CollectionService:GetInstanceRemovedSignal(tag):Connect(unbind)
	for _, unit in CollectionService:GetTagged(tag) do
		task.spawn(bindWhileWatching, unit)
	end
	return function()
		watching = false
		added:Disconnect()
		removed:Disconnect()
		for unit in rigs do
			unbind(unit)
		end
	end
end

return RollUpDoor
