--!strict
--[[
	RollUpDoor: one number drives the whole door.

	Server (authoritative; the GDD's door state machine calls these after its own checks):
		RollUpDoor.play(unit, "Open")         -- Peek | Open | Close | Slam | LiftInside
		RollUpDoor.setLocked(unit, true)      -- shoots the bolt, hangs the padlock (shut doors)
		RollUpDoor.rise(unit) --> number      -- where the door is right now, in studs
		RollUpDoor.dent(unit, share)          -- a trapped keeper's blow bows it out (never back)

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

	The dent (L-06b3d2): a door a trapped keeper beats on keeps its chain, and the dent's step
	(`Dent.step` of the unit's `DoorDent`) swaps in that step's bowed ribs from
	ReplicatedStorage.Props.DoorDent_<Size> (art/unit/dent.py), each while it hangs below the
	doorway's top; rolling up, a rib goes flat as it passes behind the header, so the coil stays
	round. The collider never changes.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Curtain = require(script.Parent.Curtain)
local Dent = require(script.Parent.Dent)
local Motion = require(script.Parent.Motion)
local Specs = require(script.Parent.Specs)

type Spec = Specs.Spec

local ATTR_MOTION = "DoorMotion"
local ATTR_LOCKED = "DoorLocked"
local ATTR_SIZE = "UnitSize"
local ATTR_OFFSET = "DoorOffset" -- CFrame, stored by UnitKit.prepare on each moving part
local SHUT = 1e-4
local DENT_KIT = "DoorDent_" -- ReplicatedStorage.Props.DoorDent_<Size>: the dent's bowed ribs

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
	dent: number, -- the dent's step shown, 0 for none
	bowed: { [number]: BasePart }, -- by chain index: that step's bowed rib, cloned from the kit
	bowedOffsets: { [number]: CFrame },
	showBowed: { [number]: boolean }, -- whether the bowed rib stands in for the plain one now
	pose: (self: Rig, rise: number, locked: boolean?, moving: boolean?) -> (),
	setDent: (self: Rig, step: number) -> (),
	destroy: (self: Rig) -> (),
}

local RollUpDoor = {}

--[[
	How deep the door's invisible collider is, centred on the curtain. A player pushing into a shut
	door stops half this (plus their torso) short of the slats. At 1.2 someone in the hall stops
	flush with the facade, whose face is 0.55 in front of the curtain. A running arm still swings
	about 0.8 past the slats (measured in Play: docs/STUDIO.md, "Arms through a shut door"), so
	BehindDoors hides anyone on the far side of a shut door from you.
]]
RollUpDoor.ColliderDepth = 1.2

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
		dent = 0,
		bowed = {},
		bowedOffsets = {},
		showBowed = {},
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
				for i, b in self.bowed do
					if spec.SlatOrder[i] == v then
						b.Color = t.Color
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

-- The size's dent kit, or nil (said once) when the place has none: its doors then never dent.
local dentKits: { [string]: Model } = {}
local dentMissing: { [string]: boolean } = {}
local function dentKitFor(spec: Spec): Model?
	local kit = dentKits[spec.Size]
	if kit then
		return kit
	end
	local props = ReplicatedStorage:FindFirstChild("Props")
	local found = props and props:FindFirstChild(DENT_KIT .. spec.Size)
	if found and found:IsA("Model") then
		dentKits[spec.Size] = found
		return found
	end
	if not dentMissing[spec.Size] then
		dentMissing[spec.Size] = true
		warn(
			`RollUpDoor: no ReplicatedStorage.Props.{DENT_KIT}{spec.Size}, so its doors never dent (art/unit/README.md, "The dent")`
		)
	end
	return nil
end

-- Let go of the bowed ribs, showing the plain ones they stood in for.
local function dropDent(self: Rig)
	for i, shown in self.showBowed do
		local s = self.slats[i]
		if shown and s then
			s.Transparency = 0
		end
	end
	for _, b in self.bowed do
		b:Destroy()
	end
	table.clear(self.bowed)
	table.clear(self.bowedOffsets)
	table.clear(self.showBowed)
end

-- Clone the dent step's bowed ribs into the chain, in the unit's paint; hidden until posed.
local function buildDent(self: Rig)
	local chain = self.chain
	local row = self.spec.Dent[self.dent]
	local kit = dentKitFor(self.spec)
	if not (chain and row and kit) or next(self.bowed) ~= nil then
		return
	end
	for i = row.First, row.Last do
		local src = kit:FindFirstChild(`Dent{self.dent}_{i}`, true)
		local offset = src and src:GetAttribute(ATTR_OFFSET)
		local template = self.templates[self.spec.SlatOrder[i]]
		if not (src and src:IsA("BasePart") and typeof(offset) == "CFrame" and template) then
			continue -- an unprepared kit: that rib stays plain
		end
		local b = src:Clone()
		b.Name = "Dent" .. i
		b.Color = template.Color
		b.Transparency = 1
		b.Parent = chain
		self.bowed[i] = b
		self.bowedOffsets[i] = offset
		self.showBowed[i] = false
	end
end

local function dropChain(self: Rig)
	dropDent(self)
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
	-- a dented door keeps its chain: the merged curtain is the plain door
	local useChain = isMoving == true or rise > SHUT or not self.closed or self.dent > 0
	local parts, cframes = self.parts, self.cframes
	local f = self.frame
	local n = 0
	local drumAngle = 0
	if useChain then
		buildChain(self)
		if self.dent > 0 then
			buildDent(self)
		end
		local st = self.curtain:slats(rise, self.buf, self.phi)
		self.phi = st.phi
		drumAngle = self.curtain:drumAngle(st)
		local buf = self.buf
		-- a bowed rib shows while its top is below the doorway's top, in the hall's sight
		local hangs = spec.DoorHeight - spec.Curtain.BottomClosed - rise
		local pitch = spec.Curtain.Pitch
		for i, s in self.slats do
			local j = 4 * (i - 1)
			local dz, dy = buf[j + 3], buf[j + 4]
			-- rotation about X taking +Y up the curtain: (dirY, -dirZ) in door-local Y/Z
			local at = f * CFrame.new(0, buf[j + 2], -buf[j + 1], 1, 0, 0, 0, dy, dz, 0, -dz, dy)
			n += 1
			local b = self.bowed[i]
			if b then
				local show = i * pitch <= hangs
				if show ~= self.showBowed[i] then
					self.showBowed[i] = show
					b.Transparency = if show then 0 else 1
					s.Transparency = if show then 1 else 0
				end
				if show then
					parts[n] = b
					cframes[n] = at * self.bowedOffsets[i]
					continue
				end
			end
			parts[n] = s
			cframes[n] = at * self.slatOffsets[i]
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

--[[
	Show the dent's step `step` (0: none; `Dent.step` of the unit's `DoorDent`). The next pose
	puts its bowed ribs in. Without the size's dent kit the door stays plain.
]]
function Rig.setDent(self: Rig, step: number)
	step = math.clamp(step, 0, #self.spec.Dent)
	if step > 0 and not dentKitFor(self.spec) then
		step = 0
	end
	if step == self.dent then
		return
	end
	dropDent(self)
	self.dent = step
end

-- Put the unit back as imported (shut, merged curtain) and stop listening.
function Rig.destroy(self: Rig)
	for _, c in self.conns do
		c:Disconnect()
	end
	table.clear(self.conns)
	self.dent = 0
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

-- Size the collider to the curtain's bottom edge at `rise`: it fills the opening below the drum.
local function placeCollider(col: BasePart?, spec: Spec, frame: CFrame, rise: number)
	if not col then
		return
	end
	local bottom = spec.Gap + rise
	local h = math.max(spec.DoorHeight - bottom, 0.05)
	col.CanCollide = h > 0.25
	col.Size = Vector3.new(spec.DoorWidth, h, RollUpDoor.ColliderDepth)
	col.CFrame = frame * CFrame.new(0, bottom + h / 2, 0)
end

-- The unit's size spec (its UnitSize attribute; M when unset).
function RollUpDoor.spec(unit: Model): Spec
	return specFor(unit)
end

--[[
	Fit the door's collider to where the door is now. UnitKit.prepare calls it; so does anything
	placing units, so a template prepared before a change to ColliderDepth still gets the new depth.
]]
function RollUpDoor.fitCollider(unit: Model)
	local col = unit:FindFirstChild("DoorCollider") :: BasePart?
	placeCollider(col, specFor(unit), RollUpDoor.frame(unit), RollUpDoor.rise(unit))
end

local function serverStep()
	local t = now()
	for unit, m in serverMoving do
		if not unit.Parent then
			serverMoving[unit] = nil
			continue
		end
		placeCollider(
			m.col,
			m.spec,
			m.frame,
			Motion.sample(m.kind, m.from, m.to, t - m.start, m.spec.Rise.Open)
		)
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
	-- a keeper's bang jolts the door where it is, peeked or shut
	local to = if kind == "Bang" then from else Motion.target(kind, spec.Rise)
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
	placeCollider(m.col, spec, frame, from)
	serverMoving[unit] = m
	if not serverConn then
		serverConn = RunService.Heartbeat:Connect(serverStep)
	end
	return dur
end

--[[
	Server: a trapped keeper's blow, `share` of its time to break out gone (`Dent.share`), dents
	its door that far if that's worse than it is; never back. Every screen shows the matching step
	from the unit's `DoorDent`. A door keeps its dent for the floor, lifted or burst.
]]
function RollUpDoor.dent(unit: Model, share: number)
	local was = unit:GetAttribute(Dent.Attribute)
	local worse = Dent.raise(if type(was) == "number" then was else 0, share)
	if worse ~= was then
		unit:SetAttribute(Dent.Attribute, worse)
	end
end

-- Server: lock or unlock. Locking needs the door down and still; returns whether it took.
function RollUpDoor.setLocked(unit: Model, locked: boolean): boolean
	if locked and (serverMoving[unit] or RollUpDoor.rise(unit) > 0.05) then
		return false
	end
	unit:SetAttribute(ATTR_LOCKED, locked)
	return true
end

--[[
	Edit time: ready an inserted dent kit (DoorDent_<size>.fbx; art/unit/README.md, "The dent")
	to live at ReplicatedStorage.Props.DoorDent_<size>. Measures each bowed rib against where its
	chain index hangs when the door is shut and keeps that as its DoorOffset (the importer moves
	and turns things), dresses it in the size's slat look from ReplicatedStorage.Units.<size>, and
	drops the frame markers. Returns how many ribs it readied.
]]
function RollUpDoor.prepareDent(kit: Model, size: string): number
	local spec = Specs[size]
	assert(spec, `RollUpDoor.prepareDent: no spec for size {size}`)
	local units = ReplicatedStorage:FindFirstChild("Units")
	local unit = units and units:FindFirstChild(size)
	local look = unit and unit:FindFirstChild("Slat_A", true)
	assert(
		look and look:IsA("BasePart"),
		`RollUpDoor.prepareDent: no ReplicatedStorage.Units.{size}.Slat_A`
	)
	local link = kit:FindFirstChildOfClass("PackageLink")
	if link then
		link:Destroy()
	end
	local frame = RollUpDoor.frame(kit)
	local buf = table.create(spec.Curtain.Count * 4, 0)
	curtainFor(spec):slats(0, buf, nil)
	local count = 0
	for _, d in kit:GetDescendants() do
		if not d:IsA("BasePart") then
			continue
		end
		local index = string.match(d.Name, "^Dent%d+_(%d+)$")
		local i = tonumber(index)
		if not i then
			d:Destroy() -- DoorOrigin and Drum: only for measuring
			continue
		end
		local j = 4 * (i - 1)
		local dz, dy = buf[j + 3], buf[j + 4]
		local rest = CFrame.new(0, buf[j + 2], -buf[j + 1], 1, 0, 0, 0, dy, dz, 0, -dz, dy)
		d:SetAttribute(ATTR_OFFSET, rest:Inverse() * frame:ToObjectSpace(d.CFrame))
		d.Anchored = true
		d.CanCollide = false
		d.CanTouch = false
		d.CanQuery = false
		d.Massless = true
		d.CastShadow = look.CastShadow
		d.Material = look.Material
		d.Reflectance = look.Reflectance
		for _, c in d:GetChildren() do
			if c:IsA("SurfaceAppearance") then
				c:Destroy()
			end
		end
		local skin = look:FindFirstChildOfClass("SurfaceAppearance")
		if skin then
			skin:Clone().Parent = d
		end
		count += 1
	end
	kit.Name = DENT_KIT .. size
	return count
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
	local dent = unit:GetAttribute(Dent.Attribute)
	rig:setDent(Dent.step(if type(dent) == "number" then dent else 0, #rig.spec.Dent))
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
		unit:GetAttributeChangedSignal(Dent.Attribute):Connect(function()
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
