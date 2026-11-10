--!strict
--[[
	KeeperSounds: how each keeper gives itself away on this screen (L-06b4b2), heard by everyone
	near it, as a door is.

	The moment: in the dark you hear it before you see it. Each step its walk lands is a stiff
	clack of its foot on the concrete and each pass of its legs a hollow knock at its joints, as
	Five Nights at Freddy's footsteps tell you an animatronic moved. And a door lifted on one
	standing in a unit knocks once as the curtain's edge clears its feet: before your light finds
	it, you know something stands in there.

	Nothing new crosses the network. Each screen's KeeperView poses the body from its records and
	calls `heard` as each key of its walk lands (`Pose.tell`); a door's motion is already on every
	screen (its `DoorMotion`), so the reveal is timed off the server's clock and lands as the door
	is seen to clear its feet. The numbers are on the keeper's row (`KeeperRows`, `KeeperTell`).

	Only bodies streamed to this screen are heard, each at most one sound per its `gap`, and none
	from past its reach. A body's sounds are made the first time it makes each one, on its root.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
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
	tell: KeeperTell.Tell,
	voices: { [KeeperTell.Name]: { [number]: Voice } }, -- by take, made as each first plays
	took: { [KeeperTell.Name]: number }, -- the take each sound last played
	last: number?, -- os.clock() of its last sound
	revealed: number?, -- os.clock() of its last reveal
	unit: Model?, -- the unit it stands in, while it stands in one
	lifts: number, -- counts that unit's door motions, so a newer one cancels a reveal to come
	unitConn: RBXScriptConnection?,
	alive: boolean,
	conns: { RBXScriptConnection },
}

local KeeperSounds = {}

-- The system, and `heard` (for KeeperView): a body's walk landed a key that makes `sound`.
function KeeperSounds.new(): (Brix.System, (model: Model, sound: KeeperTell.Name) -> ())
	local bodies: { [Model]: Body } = {}
	local connections: { RBXScriptConnection } = {}
	local random = Random.new()

	local function voiceFor(body: Body, name: KeeperTell.Name, i: number): Voice
		local byTake = body.voices[name]
		local existing = byTake[i]
		if existing then
			return existing
		end
		local row = KeeperTell.sound(body.tell, name)
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
		-- timed for its highest pitch, so even the quickest play is silent before it's cut
		local length = (take.stop - take.start) / row.pitchMax
		local fade = TweenService:Create(
			s,
			TweenInfo.new(
				row.fade / row.pitchMax,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				0,
				false,
				math.max(length - row.fade / row.pitchMax, 0)
			),
			{ Volume = 0 }
		)
		local voice = { sound = s, fade = fade }
		byTake[i] = voice
		return voice
	end

	-- Plays one of its sounds, `gain` and `pitch` times the row's, if it's due and near enough.
	local function play(body: Body, name: KeeperTell.Name, gain: number, pitch: number)
		local now = os.clock()
		if not KeeperTell.due(body.last, now, body.tell.gap) then
			return
		end
		local row = KeeperTell.sound(body.tell, name)
		local camera = Workspace.CurrentCamera -- where this screen hears from
		if not camera or (camera.CFrame.Position - body.root.Position).Magnitude > row.reach then
			return
		end
		body.last = now
		local i = KeeperTell.take(#row.takes, body.took[name], random:NextNumber())
		body.took[name] = i
		local voice = voiceFor(body, name, i)
		local s = voice.sound
		voice.fade:Cancel()
		s.PlaybackSpeed = random:NextNumber(row.pitchMin, row.pitchMax) * pitch
		s.Volume = row.volume * gain
		s.TimePosition = row.takes[i].start
		s:Play()
		voice.fade:Play()
	end

	local function heard(model: Model, sound: KeeperTell.Name)
		local body = bodies[model]
		if body then
			play(body, sound, 1, 1)
		end
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

	-- Its unit's door started a motion: if it lifts the curtain past its feet, knock as it does.
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
				play(body, "Knock", body.tell.revealGain, body.tell.revealPitch)
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

	local function unbind(inst: Instance)
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

	local function bind(inst: Instance)
		-- only bodies in the world: a tagged template elsewhere stays silent
		if not inst:IsA("Model") or bodies[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local model = inst
		local name = model:GetAttribute(ROW_ATTRIBUTE)
		local row = if type(name) == "string" then KeeperRows[name] else nil
		local root = model.PrimaryPart
		if not (row and root) then
			return -- KeeperView says why
		end
		local body: Body = {
			model = model,
			root = root,
			tell = row.tell,
			voices = { Footfall = {}, Knock = {} },
			took = {},
			last = nil,
			revealed = nil,
			unit = nil,
			lifts = 0,
			unitConn = nil,
			alive = true,
			conns = {},
		}
		bodies[model] = body
		table.insert(
			body.conns,
			model:GetAttributeChangedSignal(STATE_ATTRIBUTE):Connect(function()
				settle(body)
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
			for _, sound in { row.tell.footfall, row.tell.knock } do
				for _, take in sound.takes do
					table.insert(out, take.id)
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
		end,
	}
	return system, heard
end

return KeeperSounds
