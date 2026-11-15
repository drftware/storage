--!strict
--[[
	KeeperSounds: how each keeper gives itself away on this screen (L-06b4b2, L-06c1), heard by
	everyone near it, as a door is.

	The moment: you hear it before you see it, and it sounds heavy and wrong. Its walk limps: a
	hollow fibreglass thunk as its good foot lands, its stiff foot scraping the concrete, the hard
	tock of its heel, then nothing. Far off it's a slow hollow knocking; as it nears, the body's
	weight comes in under each step until it thuds, as Five Nights at Freddy's footsteps swell as
	an animatronic comes down the hall. Its body creaks as it turns a corner or turns to you. Held
	in your light it makes no sound at all. And a door lifted on one standing in a unit answers
	with a thunk and a creak as the curtain's edge clears its feet: before your light finds it,
	you know something stands in there. And when it hears something new (L-15), its limp breaks
	off on one deep thunk and its body groans round toward the sound: you hear that it heard.

	Nothing new crosses the network. Each screen's KeeperView poses the body from its records and
	calls `heard` as each key of its walk lands (`Pose.tell`) and as it turns; a door's motion is
	already on every screen (its `DoorMotion`), so the reveal is timed off the server's clock and
	lands as the door is seen to clear its feet. The numbers are on the keeper's row (`KeeperRows`,
	`KeeperTell`).

	Only bodies streamed to this screen are heard, each walk beat at most one per its `gap`, each
	creak one per its `turnGap`, and no layer from past its reach. A body's sounds, every take of
	both its tells, are made on its root as it streams in (S2-06e2): a Sound made and played at
	once starts about 0.28 s late, so its first steps into earshot, and its first steps with its
	arms full, would land late and clipped by their fade.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
local KeeperMotion = require(ReplicatedStorage.Shared.KeeperMotion)
local KeeperRows = require(ReplicatedStorage.Shared.KeeperRows)
local KeeperTell = require(ReplicatedStorage.Shared.KeeperTell)
local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local SoundPrimer = require(script.Parent.SoundPrimer)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

local TAG = "Keeper" -- on each keeper's body (the server's Keepers)
local ROW_ATTRIBUTE = "Keeper"
local STATE_ATTRIBUTE = "KeeperState"
local MOTION_ATTRIBUTE = "DoorMotion" -- on each unit (RollUpDoor.play)

-- One take of one sound on a body, and the fade it ends with (made once, replayed each time).
type Voice = { sound: Sound, fade: Tween }

type Body = {
	model: Model,
	root: BasePart,
	-- how it sounds (its row's), and with its arms full (S2-06e); its gaps and the reveal's rise
	-- are always its `tell`'s
	tell: KeeperTell.Tell,
	full: KeeperTell.Tell?,
	armsFull: boolean, -- whether the screen last showed its arms full (KeeperView's `heard`)
	voices: { [KeeperTell.Sound]: { [number]: Voice } }, -- by sound, then take, made as each plays
	took: { [KeeperTell.Sound]: number }, -- the take each sound last played
	last: number?, -- os.clock() of its walk's last beat
	creaked: number?, -- os.clock() of its last creak
	revealed: number?, -- os.clock() of its last reveal
	unit: Model?, -- the unit it stands in, while it stands in one
	lifts: number, -- counts that unit's door motions, so a newer one cancels a reveal to come
	unitConn: RBXScriptConnection?,
	alive: boolean,
	conns: { RBXScriptConnection },
}

local KeeperSounds = {}

-- The system, and `heard` (for KeeperView): a body's walk landed a beat, or it turned, shown
-- with its arms full or not.
function KeeperSounds.new(): (Brix.System, (model: Model, beat: KeeperTell.Beat, full: boolean) -> ())
	local bodies: { [Model]: Body } = {}
	local connections: { RBXScriptConnection } = {}
	local random = Random.new()

	local function voiceFor(body: Body, tell: KeeperTell.Tell, name: string, i: number): Voice
		local row = tell.sounds[name]
		local byTake = body.voices[row]
		if not byTake then
			byTake = {}
			body.voices[row] = byTake
		end
		local existing = byTake[i]
		if existing then
			return existing
		end
		local take = row.takes[i]
		local s = Instance.new("Sound")
		s.Name = `Keeper{name}`
		s.SoundId = take.id
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = row.near
		s.RollOffMaxDistance = row.reach
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(take.start, take.stop)
		s.Parent = body.root
		-- timed for its fastest play, so even the quickest is silent before it's cut
		local fastest = KeeperTell.fastest(tell, name)
		local length = (take.stop - take.start) / fastest
		local fade = TweenService:Create(
			s,
			TweenInfo.new(
				row.fade / fastest,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				0,
				false,
				math.max(length - row.fade / fastest, 0)
			),
			{ Volume = 0 }
		)
		local voice = { sound = s, fade = fade }
		byTake[i] = voice
		return voice
	end

	-- Makes every take of a tell on the body now, so each has loaded before its first beat.
	local function ready(body: Body, tell: KeeperTell.Tell)
		for name, row in tell.sounds do
			for i in row.takes do
				voiceFor(body, tell, name, i)
			end
		end
	end

	-- Plays a beat's layers at once, each weighed by how near it is, any within its reach: the
	-- full tell's while its arms are full (S2-06e).
	local function play(body: Body, beat: KeeperTell.Beat)
		local camera = Workspace.CurrentCamera -- where this screen hears from
		if not camera then
			return
		end
		local tell = KeeperTell.of(body.tell, body.full, body.armsFull)
		local distance = (camera.CFrame.Position - body.root.Position).Magnitude
		local heft = KeeperTell.heft(tell, distance)
		for _, layer in tell.beats[beat] do
			local row = tell.sounds[layer.sound]
			if distance > row.reach then
				continue
			end
			local i = KeeperTell.take(#row.takes, body.took[row], random:NextNumber())
			body.took[row] = i
			local voice = voiceFor(body, tell, layer.sound, i)
			local s = voice.sound
			local gain, pitch = KeeperTell.weigh(row, heft)
			voice.fade:Cancel()
			s.PlaybackSpeed = random:NextNumber(row.pitchMin, row.pitchMax) * layer.pitch * pitch
			s.Volume = row.volume * layer.gain * gain
			s.TimePosition = row.takes[i].start
			s:Play()
			voice.fade:Play()
		end
	end

	local function heard(model: Model, beat: KeeperTell.Beat, full: boolean)
		local body = bodies[model]
		if not body then
			return
		end
		body.armsFull = full
		local now = os.clock()
		if beat == "Creak" then
			if not KeeperTell.due(body.creaked, now, body.tell.turnGap) then
				return
			end
			body.creaked = now
		else
			if not KeeperTell.due(body.last, now, body.tell.gap) then
				return
			end
			body.last = now
		end
		play(body, beat)
	end

	-- It heard a new sound at server time `at` (`KeeperTell.HeardAttribute`): its Heard beat, as
	-- this screen shows it stop (KeeperView shows keepers `KeeperMotion.Delay` behind the server).
	-- Its creak as it turns to the sound is in the beat, so the turn doesn't creak again.
	local function startled(body: Body)
		local at = body.model:GetAttribute(KeeperTell.HeardAttribute)
		if type(at) ~= "number" then
			return
		end
		local wait = at + KeeperMotion.Delay - Workspace:GetServerTimeNow()
		if wait < -KeeperMotion.Delay then
			return -- long past (it streamed in later): nothing to hear now
		end
		task.delay(math.max(wait, 0), function()
			if body.alive and body.model:GetAttribute(KeeperTell.HeardAttribute) == at then
				local now = os.clock()
				body.last, body.creaked = now, now
				play(body, "Heard")
			end
		end)
	end

	-- Whether `body`'s feet stand inside `unit`.
	local function standsIn(body: Body, unit: Instance): boolean
		if not (unit:IsA("Model") and unit:IsDescendantOf(Workspace)) then
			return false
		end
		if not unit:FindFirstChild("DoorOrigin", true) then
			return false
		end
		local spec = RollUpDoor.spec(unit)
		local feet = RollUpDoor.frame(unit):PointToObjectSpace(body.model:GetPivot().Position)
		-- the door's frame looks out to the hall: the unit is behind it, along +Z
		return KeeperTell.inside(feet.X, feet.Z, spec.Width, spec.Depth)
	end

	-- Its unit's door started a motion: if it lifts the curtain past its feet, answer as it does.
	local function lifted(body: Body, unit: Model)
		body.lifts += 1
		local mine = body.lifts
		local kind: Motion.Kind, from: number, to: number, start: number =
			Motion.decode(unit:GetAttribute(MOTION_ATTRIBUTE) :: string?)
		local spec = RollUpDoor.spec(unit)
		local at = KeeperTell.reveal(kind, from, to, spec.Rise.Open, body.tell.revealRise)
		if not at then
			return
		end
		local wait = start + at - Workspace:GetServerTimeNow()
		if wait < -DoorSound.LateCue then
			return -- long past: a door streaming in mid-lift
		end
		task.delay(math.max(wait, 0), function()
			if not (body.alive and body.lifts == mine and body.unit == unit) then
				return
			end
			local now = os.clock()
			if KeeperTell.due(body.revealed, now, body.tell.revealGap) then
				body.revealed = now
				play(body, "Reveal")
			end
		end)
	end

	local function leaveUnit(body: Body)
		body.unit = nil
		body.lifts += 1 -- a reveal still to come is called off
		if body.unitConn then
			body.unitConn:Disconnect()
			body.unitConn = nil
		end
	end

	local function enterUnit(body: Body, unit: Model)
		body.unit = unit
		body.unitConn = unit:GetAttributeChangedSignal(MOTION_ATTRIBUTE):Connect(function()
			lifted(body, unit)
		end)
		-- the deal stands a keeper as its door first lifts, so its body reaches this screen just
		-- after that lift began: hear the lift it arrived in, if its feet aren't shown yet
		if unit:GetAttribute(MOTION_ATTRIBUTE) ~= nil then
			lifted(body, unit)
		end
	end

	-- Finds the unit it stands in while it stands in one (asleep or watching), else leaves it.
	local function settle(body: Body)
		if not KeeperTell.standing(body.model:GetAttribute(STATE_ATTRIBUTE)) then
			leaveUnit(body)
			return
		end
		if body.unit then
			return
		end
		for _, unit in CollectionService:GetTagged(UnitKit.Tag) do
			if standsIn(body, unit) then
				enterUnit(body, unit :: Model)
				return
			end
		end
	end

	-- A unit streamed in: a standing body that streamed in first may stand in it.
	local function unitAdded(unit: Instance)
		for _, body in bodies do
			if
				not body.unit
				and KeeperTell.standing(body.model:GetAttribute(STATE_ATTRIBUTE))
				and standsIn(body, unit)
			then
				enterUnit(body, unit :: Model)
			end
		end
	end

	-- Bodies that arrived before their root or their row: bound as the rest arrives, as
	-- KeeperView does, or a monster that streamed in that way would walk silent for good.
	local pending: { [Model]: { RBXScriptConnection } } = {}

	local function unpend(model: Model)
		local conns = pending[model]
		if conns then
			pending[model] = nil
			for _, c in conns do
				c:Disconnect()
			end
		end
	end

	local function unbind(inst: Instance)
		unpend(inst :: Model)
		local body = bodies[inst :: Model]
		if not body then
			return
		end
		bodies[body.model] = nil
		body.alive = false
		leaveUnit(body)
		for _, c in body.conns do
			c:Disconnect()
		end
		for _, byTake in body.voices do
			for _, voice in byTake do
				voice.fade:Cancel()
				voice.sound:Destroy()
			end
		end
	end

	local bind: (inst: Instance) -> ()
	function bind(inst: Instance)
		-- only bodies in the world: a tagged template elsewhere stays silent
		if not inst:IsA("Model") or bodies[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local model = inst
		local name = model:GetAttribute(ROW_ATTRIBUTE)
		local row = if type(name) == "string" then KeeperRows[name] else nil
		local root = model.PrimaryPart
		if not (row and root) then
			-- not all here yet (KeeperView says why if it never comes)
			if not pending[model] then
				local function again()
					bind(model)
				end
				pending[model] = {
					model:GetPropertyChangedSignal("PrimaryPart"):Connect(again),
					model:GetAttributeChangedSignal(ROW_ATTRIBUTE):Connect(again),
				}
			end
			return
		end
		unpend(model)
		local body: Body = {
			model = model,
			root = root,
			tell = row.tell,
			full = row.full,
			armsFull = false,
			voices = {},
			took = {},
			last = nil,
			creaked = nil,
			revealed = nil,
			unit = nil,
			lifts = 0,
			unitConn = nil,
			alive = true,
			conns = {},
		}
		bodies[model] = body
		ready(body, row.tell)
		if row.full then
			ready(body, row.full)
		end
		table.insert(
			body.conns,
			model:GetAttributeChangedSignal(STATE_ATTRIBUTE):Connect(function()
				settle(body)
			end)
		)
		table.insert(
			body.conns,
			model:GetAttributeChangedSignal(KeeperTell.HeardAttribute):Connect(function()
				startled(body)
			end)
		)
		table.insert(
			body.conns,
			model.Destroying:Connect(function()
				unbind(model)
			end)
		)
		settle(body)
	end

	-- Every take of every keeper's sounds, so the first footfall isn't late.
	local function ids(): { string }
		local out = {}
		for _, row in KeeperRows do
			local tells = { row.tell }
			if row.full then
				table.insert(tells, row.full)
			end
			for _, tell in tells do
				for _, sound in tell.sounds do
					for _, take in sound.takes do
						if not table.find(out, take.id) then
							table.insert(out, take.id)
						end
					end
				end
			end
		end
		return out
	end

	local system: Brix.System = {
		name = "KeeperSounds",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, ids())
			table.insert(connections, CollectionService:GetInstanceAddedSignal(TAG):Connect(bind))
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(TAG):Connect(unbind)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(unitAdded)
			)
			for _, inst in CollectionService:GetTagged(TAG) do
				bind(inst)
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in bodies do
				unbind(model)
			end
			for model in pending do
				unpend(model)
			end
		end,
	}
	return system, heard
end

return KeeperSounds
