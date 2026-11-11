--!strict
--[[
	DoorSounds: every roll-up door's sounds on this player's screen, and the slam's shake. The
	server moves a door by setting its motion (RollUpDoor.play) and locks it with an attribute;
	this hears both on every unit and answers from DoorSound's rules:

	- While a door moves, its roll rattles at the door, louder and higher as it speeds up.
	- When it hits something (Motion.strikes) its cue plays on that instant: the slam's bang with a
	  thump under it and a jolt to anyone nearby, the bounce's clatter, a close settling, the stop
	  bolts at the top. A lift from shut starts with the latch.
	- Locking shoots the bolt and snaps the padlock; unlocking pops it and slides the bolt back.

	Everything is timed off the server's clock (the motion's start), so every player hears a door
	land when they see it land. A cue that's due already plays at once if it's only a network
	delay late, and is skipped if it's long past (a door streaming in after its slam). Each door
	gets its sounds the first time it makes one, and only moving doors are stepped.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Shake = require(ReplicatedStorage.Shared.Shake)
local SoundPrimer = require(script.Parent.SoundPrimer)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

local ATTR_MOTION = "DoorMotion"
local ATTR_LOCKED = "DoorLocked"
local ROLL: DoorSound.SoundName = "Roll"
local ROLL_ROW = DoorSound.Sounds[ROLL]

type Door = {
	unit: Model,
	origin: BasePart,
	at: CFrame, -- where its sounds come from: the middle of the doorway
	fullStroke: number,
	emitter: Attachment?, -- made with its first sound
	sounds: { [DoorSound.SoundName]: Sound },
	fades: { [Sound]: Tween },
	kind: Motion.Kind,
	from: number,
	to: number,
	start: number,
	dur: number,
	motions: number, -- counts its motions, so a new one cancels the last one's cues still to come
	level: number, -- the roll's volume now, eased toward what the motion asks
	pitch: number, -- this motion's pick from the roll's pitch range
	locked: boolean,
	alive: boolean,
	conns: { RBXScriptConnection },
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local DoorSounds = {}

-- `kick` shakes this player's view (CameraShake's).
function DoorSounds.new(kick: (amount: number) -> ()): Brix.System
	local doors: { [Model]: Door } = {}
	local rolling: { [Door]: true } = {}
	local connections: { RBXScriptConnection } = {}
	local random = Random.new()

	local function soundFor(door: Door, name: DoorSound.SoundName): Sound
		local existing = door.sounds[name]
		if existing then
			return existing
		end
		local emitter = door.emitter
		if not emitter then
			local a = Instance.new("Attachment")
			a.Name = "DoorSounds"
			a.Parent = door.origin
			a.WorldCFrame = door.at
			door.emitter = a
			emitter = a
		end
		local row = DoorSound.Sounds[name]
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = row.Id
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = row.Near
		s.RollOffMaxDistance = row.Reach
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(row.Start, row.Stop)
		if name == "Roll" then
			s.LoopRegion = NumberRange.new(row.Start, row.Stop)
			s.Looped = true
		end
		s.Parent = emitter
		door.sounds[name] = s
		return s
	end

	-- Where this player hears from: their character, or the camera without one.
	local function listener(): Vector3?
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
		local camera = Workspace.CurrentCamera
		return if camera then camera.CFrame.Position else nil
	end

	local function play(door: Door, cue: DoorSound.Cue)
		local row = DoorSound.Sounds[cue.sound]
		local s = soundFor(door, cue.sound)
		local fading = door.fades[s]
		if fading then
			fading:Cancel()
			door.fades[s] = nil
		end
		local pitch = random:NextNumber(row.PitchMin, row.PitchMax) * cue.pitch
		s.PlaybackSpeed = pitch
		s.Volume = row.Volume * cue.gain
		s.TimePosition = row.Start
		s:Play()
		if row.Fade > 0 then
			-- fade out over the stretch's last Fade seconds (at this pitch), so the cut is silent
			local length = row.Stop - row.Start
			local info = TweenInfo.new(
				row.Fade / pitch,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In,
				0,
				false,
				math.max(length - row.Fade, 0) / pitch
			)
			local tween = TweenService:Create(s, info, { Volume = 0 })
			tween:Play()
			door.fades[s] = tween
		end
		if cue.shake > 0 then
			local from = listener()
			if from then
				local d = (from - door.at.Position).Magnitude
				kick(cue.shake * Shake.falloff(d, DoorSound.ShakeNear, DoorSound.ShakeReach))
			end
		end
	end

	-- Plays `cue` `wait` seconds from now while `current()` holds; at once if it's only a little late.
	local function schedule(door: Door, cue: DoorSound.Cue, wait: number, current: () -> boolean)
		if wait < -DoorSound.LateCue then
			return
		elseif wait <= 0 then
			play(door, cue)
			return
		end
		task.delay(wait, function()
			if door.alive and current() then
				play(door, cue)
			end
		end)
	end

	-- The server started a motion on this door: roll and cue it.
	local function moved(door: Door)
		local kind: Motion.Kind, from: number, to: number, start: number =
			Motion.decode(door.unit:GetAttribute(ATTR_MOTION) :: string?)
		door.motions += 1
		door.kind, door.from, door.to, door.start = kind, from, to, start
		door.dur = Motion.duration(kind, from, to, door.fullStroke)
		local elapsed = now() - start
		if elapsed >= door.dur then
			return -- long over: a door streaming in already where it ended up
		end
		local mine = door.motions
		local function current(): boolean
			return door.motions == mine
		end
		for _, cue in DoorSound.cues(kind, from, to, door.fullStroke) do
			schedule(door, cue, cue.at - elapsed, current)
		end
		if DoorSound.Actions[kind].Gain <= 0 then
			return -- a padlocked door's rattle: its cue is the whole sound, no roll
		end
		local row = ROLL_ROW
		local roll = soundFor(door, ROLL)
		roll.RollOffMaxDistance = DoorSound.Actions[kind].Reach
		door.pitch = random:NextNumber(row.PitchMin, row.PitchMax)
		if not roll.IsPlaying then
			-- somewhere new in the loop each time, so no two opens sound the same
			roll.TimePosition = random:NextNumber(row.Start, math.max(row.Start, row.Stop - 2))
			roll.Volume = 0
			door.level = 0
			roll:Play()
		end
		rolling[door] = true
	end

	local function lockChanged(door: Door)
		local locked = door.unit:GetAttribute(ATTR_LOCKED) == true
		if locked == door.locked then
			return
		end
		door.locked = locked
		local function current(): boolean
			return door.locked == locked
		end
		for _, cue in DoorSound.lockCues(locked) do
			schedule(door, cue, cue.at, current)
		end
	end

	local function remove(inst: Instance)
		local door = doors[inst :: Model]
		if not door then
			return
		end
		doors[inst :: Model] = nil
		rolling[door] = nil
		door.alive = false
		for _, c in door.conns do
			c:Disconnect()
		end
		for _, tween in door.fades do
			tween:Cancel()
		end
		if door.emitter then
			door.emitter:Destroy()
		end
	end

	local function add(inst: Instance)
		-- only units in the world: a tagged template in ReplicatedStorage makes no sound
		if not inst:IsA("Model") or doors[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local origin = inst:FindFirstChild("DoorOrigin", true)
		if not (origin and origin:IsA("BasePart")) then
			return
		end
		local spec = RollUpDoor.spec(inst)
		local door: Door = {
			unit = inst,
			origin = origin,
			at = RollUpDoor.frame(inst) * CFrame.new(0, spec.DoorHeight * 0.5, 0),
			fullStroke = spec.Rise.Open,
			emitter = nil,
			sounds = {},
			fades = {},
			kind = "Close",
			from = 0,
			to = 0,
			start = 0,
			dur = 0,
			motions = 0,
			level = 0,
			pitch = 1,
			locked = inst:GetAttribute(ATTR_LOCKED) == true,
			alive = true,
			conns = {},
		}
		doors[inst] = door
		table.insert(
			door.conns,
			inst:GetAttributeChangedSignal(ATTR_MOTION):Connect(function()
				moved(door)
			end)
		)
		table.insert(
			door.conns,
			inst:GetAttributeChangedSignal(ATTR_LOCKED):Connect(function()
				lockChanged(door)
			end)
		)
		if inst:GetAttribute(ATTR_MOTION) ~= nil then
			moved(door) -- mid-motion as it streams in: roll on, with only the cues still to come
		end
	end

	-- Every door sound loaded and played once silently up front (SoundPrimer), so the first slam
	-- bangs on the instant it hits, not a third of a second after.
	local function preload()
		local ids: { string } = {}
		for _, row in DoorSound.Sounds do
			table.insert(ids, row.Id)
		end
		SoundPrimer.prime(ids)
	end

	return {
		name = "DoorSounds",
		start = function(_: any, _context: Brix.Context)
			task.spawn(preload)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(UnitKit.Tag):Connect(remove)
			)
			for _, unit in CollectionService:GetTagged(UnitKit.Tag) do
				add(unit)
			end
		end,
		step = function(_: any, dt: number)
			local t = now()
			for door in rolling do
				local roll = door.sounds[ROLL]
				if not roll then
					rolling[door] = nil
					continue
				end
				local elapsed = t - door.start
				local target, pitch =
					DoorSound.roll(door.kind, door.from, door.to, elapsed, door.fullStroke)
				local ease = if target > door.level
					then DoorSound.RollAttack
					else DoorSound.RollRelease
				door.level += (target - door.level) * math.min(1, dt / ease)
				roll.Volume = ROLL_ROW.Volume * door.level
				roll.PlaybackSpeed = pitch * door.pitch
				if elapsed >= door.dur and door.level < 0.005 then
					roll:Stop()
					door.level = 0
					rolling[door] = nil
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for unit in doors do
				remove(unit)
			end
		end,
	}
end

return DoorSounds
