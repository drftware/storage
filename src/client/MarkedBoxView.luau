--!strict
--[[
	Marked boxes on every screen (B-02a). The moment: a door goes up and one box in the unit has
	two thin warm lines of light along its tape and a soft hum close to; you press Open, the tape
	rips across the middle, its halves whip back and the flaps burst up with a slap. Friends near
	hear the rip from down the hall and see it from the doorway. Then the held breath (B-02b): the
	flaps stay shut, trembling, the box rocking, a light in the find's grade colour building inside
	and leaking out with its own rising sound; the flaps burst, the light flares and dies, and the
	find rises out over the rim, turns once and flies into the opener's hand (or lands beside the
	box if their hands were full). A Legendary is heard well down the hall.

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

	The reveal reads what the server stamped with the open (`Opening.Grade`, `Opening.Find`,
	`Opening.LaidAt`, all arriving before `OpenedAt`): the grade's hold, light and sounds
	(`Opening.Reveals`, `Boxes.Reveal`, `Grades.Colours`), a Neon glow just under the flaps with one
	PointLight in it while the reveal runs (one light a box, only for its two or three seconds),
	and a copy of the find on this screen only (`Tools.clone`), gone as the server's own reaches the
	hand. The opener sees it fly to where a held find sits in their view.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Boxes = require(ReplicatedStorage.Shared.Boxes)
local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Grades = require(ReplicatedStorage.Shared.Grades)
local NoteCard = require(ReplicatedStorage.Shared.Elevator.NoteCard)
local NoteSpot = require(ReplicatedStorage.Shared.Elevator.NoteSpot)
local Pack = require(ReplicatedStorage.Shared.Finds.Pack)
local Tools = require(ReplicatedStorage.Shared.Tools)
local SoundPrimer = require(script.Parent.SoundPrimer)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local Opening = require(ReplicatedStorage.Shared.Boxes.Opening)
local Marked = Boxes.Marked
local Open = Marked.Motions.Open

-- The glow under the flaps: inset from the box's walls, just under the shut flaps, its Neon
-- see-through while held (light leaking through the gaps) and solid at the burst.
local GLOW_INSET = 0.12
local GLOW_UNDER = 0.08
local GLOW_SEEN = 0.65 -- the glow's opacity at the flare's top over the light's share of it
local FLOOR_UP = 0.04 -- studs over the box's bottom a find stands inside it (the board under it)
-- The code's note coming out (B-04a): its paper's middle hangs this far over the find's hover
-- height, rocking this many degrees this fast, as a loose sheet does in the air; it flies to the
-- opener's eyes, this many studs in front of their camera, where their card lifts (NoteView).
local PAPER_ABOVE = 0.35
local PAPER_ROCK, PAPER_ROCK_RATE = 7, 9
local PAPER_NEAR = 1.6
-- The note's light: warm, the colour of the unit's bulb on yellow paper, not a grade's.
local NOTE_LIGHT = Color3.fromRGB(255, 214, 140)

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
	base: CFrame, -- the body's pivot as it stands (the box rocks about it while held)
	-- the reveal, once opened: the grade's numbers and sounds, what's inside and who opened it
	grade: string,
	reveal: Opening.Reveal,
	find: string?,
	sealed: boolean?, -- its find still in its packaging (S5-02b2b1): the copy rises in its pack
	note: string?, -- the code's note it holds, its writing (B-04a)
	laidAt: Vector3?,
	opener: Player?,
	glow: BasePart?,
	light: PointLight?,
	copy: Model?, -- this screen's copy of the find, while it comes out
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

-- Plays `spec` once at the box, heard `heard` studs off (down the hall by default), cleaned up
-- when it's done. `from`, if given, starts it later in its window.
local function once(spec: Boxes.Sound, parent: Instance, heard: number?, from: number?)
	local s = sound(spec, parent)
	if from then
		s.PlaybackRegion = NumberRange.new(from, spec.from + spec.length)
	end
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 6
	s.RollOffMaxDistance = heard or Opening.Heard
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

-- Plays a held breath's sound so its loudest lands as the flaps burst, `hold` seconds on.
local function building(spec: Boxes.Sound, parent: Instance, heard: number, hold: number)
	local pitch = spec.pitch or 1
	local from = math.max(spec.from, (spec.peak or spec.from) - hold * pitch)
	once(spec, parent, heard, from)
end

-- Where a find's model pivot goes to stand its bottom's middle at `at`, turned `yaw` radians.
local function standing(key: string, at: Vector3, yaw: number): CFrame
	local piece = Tools.bounds(key)
	return CFrame.new(at + Vector3.new(0, piece.Size.Y / 2 - piece.Centre.Y, 0))
		* CFrame.Angles(0, yaw, 0)
		* CFrame.new(-piece.Centre.X, 0, -piece.Centre.Z)
end

local function colour(grade: string): Color3
	if grade == Opening.NoteGrade then
		return NOTE_LIGHT
	end
	local c = Grades.Colours[grade] or Grades.Colours.Common
	return Color3.fromRGB(c[1], c[2], c[3])
end

local MarkedBoxView = {}

function MarkedBoxView.new(): Brix.System
	local me = Players.LocalPlayer
	local boxes: { [Instance]: Box } = {}
	local moving: { Box } = {}
	local connections: { RBXScriptConnection } = {}
	local pose: { [string]: number } = {}
	local light: PointLight? = nil

	-- Every moving part of `b` as it stands `t` seconds into the open: held through the grade's
	-- hold, trembling, the box rocking on its base.
	local function poseAt(b: Box, t: number)
		local hold = b.reveal.Hold
		Opening.pose(Open, t, pose, hold)
		local shake = Opening.shake(t, hold) * b.reveal.Shake
		local tremble = Opening.Tremble
		local pivot = b.base
		if shake > 0 then
			local rock = math.rad(shake * tremble.Rock)
			local w = 2 * math.pi * tremble.RockRate * t
			pivot = b.base * CFrame.Angles(rock * 0.4 * math.sin(w * 1.3), 0, rock * math.sin(w))
		end
		b.body:PivotTo(pivot)
		for i, track in Open.Tracks do
			if shake > 0 and Opening.Held[track.Part] then
				-- each flap lifts at its edge, out of step with the others
				local lift = 0.5 + 0.5 * math.sin(2 * math.pi * tremble.Rate * t + i * 1.9)
				pose[track.Part] += shake * lift
			end
		end
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
		-- what's inside, stamped in the same batch before OpenedAt
		local m = b.model
		local grade = m:GetAttribute(Opening.Grade)
		b.grade = if type(grade) == "string" and Opening.Reveals[grade] then grade else "Common"
		b.reveal = Opening.Reveals[b.grade]
		local find = m:GetAttribute(Opening.Find)
		b.find = if type(find) == "string" and Tools.Catalog[find] then find else nil
		b.sealed = m:GetAttribute(Opening.Sealed) == true
		local note = m:GetAttribute(Opening.Note)
		b.note = if type(note) == "string" and note ~= "" then note else nil
		local laid = m:GetAttribute(Opening.LaidAt)
		b.laidAt = if typeof(laid) == "Vector3" then laid else nil
		local by = m:GetAttribute(Opening.OpenedBy)
		b.opener = if type(by) == "number" then Players:GetPlayerByUserId(by) else nil
		local t = now - start
		if t >= Opening.done(b.reveal.Hold) then
			-- opened before it reached this screen: it stands open
			poseAt(b, Open.Duration + b.reveal.Hold)
			return
		end
		b.last = 0
		table.insert(moving, b)
	end

	-- The grade's glow and light inside `b`, made as its reveal starts.
	local function lit(b: Box): (BasePart, PointLight)
		local glow, l = b.glow, b.light
		if glow and l then
			return glow, l
		end
		local size = Marked.Size
		local g = Instance.new("Part")
		g.Name = "RevealGlow"
		g.Material = Enum.Material.Neon
		g.Color = colour(b.grade)
		g.Transparency = 1
		g.Size = Vector3.new(size.X - GLOW_INSET, 0.02, size.Z - GLOW_INSET)
		g.CFrame = b.base * CFrame.new(0, size.Y - GLOW_UNDER, 0)
		g.Anchored = true
		g.CanCollide = false
		g.CanQuery = false
		g.CanTouch = false
		g.CastShadow = false
		local p = Instance.new("PointLight")
		p.Color = g.Color
		p.Range = b.reveal.Range
		p.Brightness = 0
		p.Shadows = false
		p.Parent = g
		g.Parent = b.model
		b.glow, b.light = g, p
		return g, p
	end

	-- Where the find goes as it leaves the box: the opener's hand (where a held find sits in your
	-- view, if it's yours), or the floor beside the box when their hands were full.
	local function bound(b: Box, key: string, from: CFrame, face: number): CFrame?
		local laid = b.laidAt
		if laid then
			return standing(key, laid, face)
		end
		local opener = b.opener
		if opener == me then
			local camera = Workspace.CurrentCamera
			local row = Tools.Catalog[key]
			local hold = row.hold
			if camera and hold then
				return camera.CFrame * CFrame.new(hold[1], hold[2], hold[3])
			end
		end
		local character = opener and opener.Character
		local hand = character
			and (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"))
		if hand and hand:IsA("BasePart") then
			return CFrame.new(hand.Position) * from.Rotation
		end
		return nil
	end

	-- The code's note `text` coming out of `b`, `t` seconds in: the paper rises out of the box,
	-- rocking, turns once facing the opener, and flies to their eyes (on their screen) or their
	-- hand (on friends'), gone as the server puts it in their pocket.
	local function paperOut(b: Box, text: string, t: number, hold: number)
		if not b.copy then
			local template = Elevator.noteTemplate()
			if not template then
				b.note = nil -- the place lacks the note's art: nothing to show
				return
			end
			local made = template:Clone()
			made:ScaleTo(NoteSpot.Scale) -- as big as one stuck on a wall was
			Elevator.write(made, text)
			for _, d in made:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
				end
			end
			b.copy = made
			made.Parent = Workspace
		end
		local copy = b.copy :: Model
		if copy.Parent == nil then
			return -- in the pocket already
		end
		local up, turn, go = Opening.lift(t, hold)
		local middle = NoteCard.Middle * NoteSpot.Scale -- from the paper's pivot to its middle
		local at = b.base.Position
		local floor = at.Y + FLOOR_UP + middle
		local top = at.Y + Marked.Size.Y + Opening.Out.Above + PAPER_ABOVE
		local face = 0
		local opener = b.opener
		local character = opener and opener.Character
		if character then
			local d = character:GetPivot().Position - at
			if d.X * d.X + d.Z * d.Z > 0.01 then
				face = math.atan2(-d.X, -d.Z)
			end
		end
		local rock = math.rad(PAPER_ROCK) * math.sin(t * PAPER_ROCK_RATE) * (1 - go)
		local hover = CFrame.new(at.X, floor + (top - floor) * up, at.Z)
			* CFrame.Angles(0, face + math.rad(turn), rock)
			* CFrame.new(0, -middle, 0)
		local to: CFrame? = nil
		if go > 0 then
			local camera = Workspace.CurrentCamera
			local hand = character
				and (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"))
			if opener == me and camera then
				to = camera.CFrame
					* CFrame.new(0, 0, -PAPER_NEAR)
					* CFrame.Angles(0, math.pi, 0)
					* CFrame.new(0, -middle, 0)
			elseif hand and hand:IsA("BasePart") then
				to = CFrame.new(hand.Position) * hover.Rotation
			end
		end
		copy:PivotTo(if to then hover:Lerp(to, go) else hover)
		if go >= 1 then
			copy:Destroy() -- in their pocket: on the opener's screen, their card lifts now
		end
	end

	-- The reveal `t` seconds in: the light, the glow and the find's copy coming out.
	local function reveal(b: Box, t: number)
		local hold = b.reveal.Hold
		if t >= Opening.Beats.Tear then
			local glow, l = lit(b)
			local share = Opening.glow(t, hold)
			l.Brightness = b.reveal.Glow * share
			l.Enabled = share > 0
			glow.Transparency = 1 - math.min(1, share / Opening.Flare / GLOW_SEEN)
		end
		local key = b.find
		local text = b.note
		if text and not key and t >= Opening.burst(hold) then
			paperOut(b, text, t, hold)
			return
		end
		if not key or t < Opening.burst(hold) then
			return
		end
		if not b.copy then
			local made = Tools.clone(key, b.base)
			if not made then
				b.find = nil -- the place lacks its art: nothing to show
				return
			end
			-- sealed, it rises still in its pack, its window to the opener, as the server's will be
			local body = if b.sealed then Tools.body(made) else nil
			if body then
				Pack.wrap(made, body, Tools.Catalog[key].size, Tools.bounds(key))
			end
			b.copy = made
			made.Parent = Workspace
		end
		local copy = b.copy :: Model
		if copy.Parent == nil then
			return -- in the hand already
		end
		local up, turn, go = Opening.lift(t, hold)
		local floor = b.base.Position.Y + FLOOR_UP
		local top = b.base.Position.Y + Marked.Size.Y + Opening.Out.Above
		local at = b.base.Position
		local face = 0
		local opener = b.opener
		local character = opener and opener.Character
		if character then
			local d = character:GetPivot().Position - at
			if d.X * d.X + d.Z * d.Z > 0.01 then
				face = math.atan2(-d.X, -d.Z)
			end
		end
		local hover = standing(
			key,
			Vector3.new(at.X, floor + (top - floor) * up, at.Z),
			face + math.rad(turn)
		)
		local to = if go > 0 then bound(b, key, hover, face) else nil
		copy:PivotTo(if to then hover:Lerp(to, go) else hover)
		if go >= 1 and not b.laidAt then
			copy:Destroy() -- in the hand: the server's own is there now
		end
	end

	-- Done with `b`'s reveal (or the box going): the copy, glow and light gone, the box at rest.
	local function finish(b: Box)
		if b.copy then
			b.copy:Destroy()
			b.copy = nil
		end
		if b.glow then
			b.glow:Destroy()
			b.glow, b.light = nil, nil
		end
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
			base = body:GetPivot(),
			grade = "Common",
			reveal = Opening.Reveals.Common,
			find = nil,
			laidAt = nil,
			opener = nil,
			glow = nil,
			light = nil,
			copy = nil,
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
		finish(b)
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
		local ids = { s.Tear.id, s.Flaps.id, s.Hum.id }
		for _, r in Boxes.Reveal do
			for _, spec in { r.hold, r.rise, r.burst } do
				if spec and not table.find(ids, spec.id) then
					table.insert(ids, spec.id)
				end
			end
		end
		task.spawn(SoundPrimer.prime, ids)
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
			local hold = b.reveal.Hold
			local sounds = Boxes.Reveal[b.grade]
			for _, beat in Opening.due(b.last, t, hold) do
				if beat == "Hold" then
					if sounds.hold then
						building(sounds.hold, b.body, b.reveal.Heard, hold)
					end
					if sounds.rise then
						building(sounds.rise, b.body, b.reveal.Heard, hold)
					end
				elseif beat == "Burst" then
					once(sounds.burst, b.body, b.reveal.Heard)
				else
					once(Boxes.Sounds[beat], b.body)
				end
			end
			b.last = t
			if t >= Opening.done(hold) then
				poseAt(b, Open.Duration + hold)
				finish(b)
				table.remove(moving, i)
			else
				poseAt(b, math.min(t, Open.Duration + hold))
				reveal(b, t)
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
