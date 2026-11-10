--!strict
--[[
	KneelView: the peek's crouch on this screen (L-06b5b, the rule in `Kneel`).

	Your own: the moment you tap Peek your view drops to the foot of gap the door lifts (over
	`Kneel.Down`, eased), so you see the floor under the door first: a keeper's feet, a sleeper's
	slack legs, boxes. The door's buttons come down with you to sit just above your gaze, so Open,
	Close and Slam stay on screen. Step off, jump, press another of the door's buttons, or have the
	door move under someone else's hand, and you stand back up with the same ease. Your body
	isn't posed on your own screen: in first person you never see it, and a torso leant into the
	door would shove you off your knees.

	Everyone else's: a friend the server tags `Kneel.Tag` kneels on your screen, eased the same way,
	on both knees and leaning in, head up to look under the door, hands on the floor.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Brix = require(ReplicatedStorage.Brix)
local Kneel = require(ReplicatedStorage.Shared.StorageUnit.Kneel)
local Motion = require(ReplicatedStorage.Shared.StorageUnit.Motion)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)

local ATTR_MOTION = "DoorMotion" -- a door's move (RollUpDoor, Motion.encode)
local ATTR_ACTION = "DoorAction" -- the door button's action (Doors.ActionAttribute)
local POSE = Kneel.Pose

type Joint = Motor6D | AnimationConstraint

-- A friend's body kneeling, or standing back up, on this screen.
type Body = {
	character: Model,
	level: number, -- 0 standing, 1 down (Kneel.toward)
	down: boolean,
	joints: { [Joint]: CFrame }, -- each joint and its turn kneeling
	written: { [Joint]: CFrame }, -- what this screen last wrote, to tell whether the Animator has since
}

-- Your own peek.
type Mine = {
	unit: Model,
	hold: Kneel.Hold,
	moves: RBXScriptConnection, -- the door's moves while you're down
}

-- The door's buttons brought down to your gaze, until you're all the way back up.
type Lowered = {
	spot: Attachment,
	home: Vector3, -- its position in its part, standing
	world: Vector3, -- and in the world
	by: number, -- studs it comes down with you all the way down
}

local KneelView = {}

local function joint(character: Model, part: string, name: string): Joint?
	local p = character:FindFirstChild(part)
	local j = p and p:FindFirstChild(name)
	if j and j:IsA("Motor6D") then
		return j
	elseif j and j:IsA("AnimationConstraint") then
		return j
	end
	return nil
end

-- Each joint of an R15 body and its turn kneeling, for a body of hip height `hip`.
local function kneeling(character: Model, hip: number): { [Joint]: CFrame }
	local joints: { [Joint]: CFrame } = {}
	local function add(part: string, name: string, to: CFrame)
		local j = joint(character, part, name)
		if j then
			joints[j] = to
		end
	end
	add(
		"LowerTorso",
		"Root",
		CFrame.new(0, -POSE.Sink * hip, POSE.Back * hip) * CFrame.Angles(POSE.Lean, 0, 0)
	)
	add("UpperTorso", "Waist", CFrame.Angles(POSE.Waist, 0, 0))
	add("Head", "Neck", CFrame.Angles(POSE.Neck, 0, 0))
	for _, side in { "Left", "Right" } do
		add(`{side}UpperLeg`, `{side}Hip`, CFrame.Angles(POSE.Hip, 0, 0))
		add(`{side}LowerLeg`, `{side}Knee`, CFrame.Angles(POSE.Knee, 0, 0))
		add(`{side}Foot`, `{side}Ankle`, CFrame.Angles(POSE.Ankle, 0, 0))
		add(`{side}UpperArm`, `{side}Shoulder`, CFrame.Angles(POSE.Shoulder, 0, 0))
		add(`{side}LowerArm`, `{side}Elbow`, CFrame.Angles(POSE.Elbow, 0, 0))
	end
	return joints
end

-- The rustle of clothes at `character`'s root, played once, its end faded.
local function rustle(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local r = Kneel.Rustle
	local snd = Instance.new("Sound")
	snd.SoundId = r.id
	snd.Volume = r.volume
	snd.PlaybackSpeed = r.pitch
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = r.near
	snd.RollOffMaxDistance = r.reach
	snd.PlaybackRegionsEnabled = true
	snd.PlaybackRegion = NumberRange.new(r.from, r.from + r.length)
	snd.TimePosition = r.from
	snd.Parent = root
	snd:Play()
	local seconds = r.length / r.pitch
	TweenService:Create(
		snd,
		TweenInfo.new(
			r.fade,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			0,
			false,
			math.max(0, seconds - r.fade)
		),
		{ Volume = 0 }
	):Play()
	task.delay(seconds + 0.2, function()
		snd:Destroy()
	end)
end

function KneelView.new(): Brix.System
	local player = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local bodies: { [Model]: Body } = {}
	local mine: Mine? = nil
	local level = 0 -- how far down your own view is (Kneel.toward)
	local drop = 0 -- studs your view drops all the way down
	local viewing: Humanoid? = nil -- the humanoid whose CameraOffset this screen is writing
	local lowered: Lowered? = nil

	local function stand()
		local m = mine
		if m then
			m.moves:Disconnect()
			mine = nil
			local character = player.Character
			if character and level > 0 then
				rustle(character)
			end
		end
	end

	local function restore()
		local l = lowered
		if l then
			lowered = nil
			if l.spot.Parent then
				l.spot.Position = l.home
			end
		end
	end

	-- You tapped Peek on `unit`'s buttons at `spot`.
	local function kneel(unit: Model, spot: Attachment)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and root:IsA("BasePart") and humanoid) or humanoid.PlatformStand then
			return
		end
		if mine then
			-- already down at another door: stay down, no second rustle
			(mine :: Mine).moves:Disconnect()
			mine = nil
		else
			rustle(character :: Model)
		end
		local p = root.Position
		local hold = Kneel.start(p.X, p.Y, p.Z, os.clock())
		mine = {
			unit = unit,
			hold = hold,
			moves = unit:GetAttributeChangedSignal(ATTR_MOTION):Connect(function()
				local kind = Motion.decode(unit:GetAttribute(ATTR_MOTION) :: string?)
				local m = mine
				if m and m.hold == hold and not Kneel.doorMoved(hold, kind) then
					stand()
				end
			end),
		}
		drop = Kneel.drop(humanoid.HipHeight, root.Size.Y)
		viewing = humanoid
		local l = lowered
		if l and l.spot ~= spot then
			restore()
		end
		if not lowered then
			local frame = RollUpDoor.frame(unit)
			local world = spot.WorldPosition
			local standing = world.Y - frame.Position.Y
			local out = math.abs(frame:PointToObjectSpace(p).Z)
			lowered = {
				spot = spot,
				home = spot.Position,
				world = world,
				by = standing - Kneel.buttonHeight(out, standing),
			}
		end
	end

	local function pressed(prompt: ProximityPrompt)
		local action = prompt:GetAttribute(ATTR_ACTION)
		if type(action) ~= "string" then
			return
		end
		local spot = prompt.Parent
		local part = spot and spot.Parent
		local unit = part and part.Parent
		if not (spot and spot:IsA("Attachment") and unit and unit:IsA("Model")) then
			return
		end
		if action == "Peek" then
			kneel(unit, spot)
		else
			-- Open, Close, Slam: you stand as you reach for the door, not when the server answers
			stand()
		end
	end

	local function body(character: Model): Body?
		local b = bodies[character]
		if b then
			return b
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return nil
		end
		b = {
			character = character,
			level = 0,
			down = false,
			joints = kneeling(character, humanoid.HipHeight),
			written = {},
		}
		bodies[character] = b
		return b
	end

	local function tagged(inst: Instance)
		if inst:IsA("Model") and inst ~= player.Character then
			local b = body(inst)
			if b and not b.down then
				b.down = true
				rustle(inst)
			end
		end
	end

	local function untagged(inst: Instance)
		local b = bodies[inst :: Model]
		if b and b.down then
			b.down = false
			rustle(b.character)
		end
	end

	-- Your view, eased down or up; your hold checked; the buttons with you.
	local function viewStep(dt: number)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local m = mine
		if m then
			local ok = root and root:IsA("BasePart") and humanoid
			if
				not ok
				or humanoid ~= viewing
				or (humanoid :: Humanoid).PlatformStand
				or (humanoid :: Humanoid).Health <= 0
			then
				-- another move took your body (a climb, a crawl, the catch) or it's gone: up at once
				stand()
				level = 0
			else
				local p = (root :: BasePart).Position
				if not Kneel.holds(m.hold, os.clock(), p.X, p.Y, p.Z) then
					stand()
				end
			end
		end
		if level == 0 and not mine and not viewing then
			return
		end
		level = Kneel.toward(level, mine ~= nil, dt)
		local w = Kneel.weight(level)
		local v = viewing
		if v and v.Parent then
			v.CameraOffset = Vector3.new(0, -drop * w, 0)
		end
		local l = lowered
		if l then
			if not l.spot.Parent then
				lowered = nil
			elseif level == 0 then
				restore()
			else
				l.spot.WorldPosition = l.world - Vector3.new(0, l.by * w, 0)
			end
		end
		if level == 0 then
			viewing = nil
		end
	end

	-- Friends' bodies, kneeling or standing, after their animations each frame.
	local function poseStep(dt: number)
		viewStep(dt)
		if next(bodies) == nil then
			return
		end
		for character, b in bodies do
			if not character.Parent then
				bodies[character] = nil
				continue
			end
			b.level = Kneel.toward(b.level, b.down, dt)
			local w = Kneel.weight(b.level)
			for j, to in b.joints do
				-- any: both classes have Transform, but Luau can't index a property through their union
				local jj = j :: any
				local now: CFrame = jj.Transform
				-- a joint no animation drives still holds this screen's last turn: start from rest
				local from = if now == b.written[j] then CFrame.identity else now
				local set = from:Lerp(to, w)
				jj.Transform = set
				b.written[j] = set
			end
			if b.level == 0 and not b.down then
				bodies[character] = nil
			end
		end
	end

	return {
		name = "KneelView",
		start = function(_: any, _context: Brix.Context)
			table.insert(connections, ProximityPromptService.PromptTriggered:Connect(pressed))
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Kneel.Tag):Connect(tagged)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Kneel.Tag):Connect(untagged)
			)
			for _, inst in CollectionService:GetTagged(Kneel.Tag) do
				tagged(inst)
			end
			table.insert(connections, RunService.PreSimulation:Connect(poseStep))
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			stand()
			restore()
			local v = viewing
			if v and v.Parent then
				v.CameraOffset = Vector3.zero
			end
			viewing = nil
			level = 0
			table.clear(bodies)
		end,
	}
end

return KneelView
