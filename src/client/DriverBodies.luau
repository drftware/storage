--!strict
--[[
	DriverBodies: every RC car driver's body on this screen, yours included (F-G1b3c2d, the pose
	in `Drive.Crouch`).

	While someone drives, the server tags their character `Drive.BodyTag`, and here it crouches
	over the transmitter, eased down over `Crouch.Down` with a rustle of clothes: hunched on its
	heels, the transmitter held up at the chest in both hands, the aerial up past the bowed head,
	the torch pointed at the floor ahead. A friend sees them crouched and still, busy somewhere
	else; when the drive ends they ease back up with the same rustle.

	Yours too, so the car's hood sees you crouched when you drive it back to your feet. Your body
	is hidden in first person, so it's shown only while your view is on the car (`viewing`), and
	hidden again the moment your view comes home. Not your torch: on your screen it's held to
	your view (FlashlightView), which is on the car's hood.

	Posed by the joints' `Transform` after the animations, before physics (PreSimulation), as the
	peek's kneel is (KneelView). Each hand's turn is worked out against the body, so the
	transmitter stands upright and the torch points down whatever the arms above them do.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Drive = require(ReplicatedStorage.Shared.Finds.Drive)
local Joints = require(script.Parent.Joints)
local KneelView = require(script.Parent.KneelView)
local Torch = require(ReplicatedStorage.Shared.Flashlight.Torch)

local CROUCH = Drive.Crouch

type Joint = Joints.Joint

type Body = {
	character: Model,
	level: number, -- 0 standing, 1 crouched
	down: boolean,
	joints: { [Joint]: CFrame }, -- each joint and its turn crouched
	written: { [Joint]: CFrame }, -- what this screen last wrote, to tell whether the Animator has since
}

local DriverBodies = {}

type Arm = {
	Shoulder: number,
	In: number,
	Elbow: number,
	Pitch: number,
	Yaw: number,
}

-- Each joint of an R15 body and its turn crouched, for a body of hip height `hip`.
local function crouching(character: Model, hip: number): { [Joint]: CFrame }
	local joints: { [Joint]: CFrame } = {}
	local function add(part: string, name: string, to: CFrame)
		local j = Joints.find(character, part, name)
		if j then
			joints[j] = to
		end
	end
	local lean = CFrame.Angles(CROUCH.Lean, 0, 0)
	local waist = CFrame.Angles(CROUCH.Waist, 0, 0)
	add("LowerTorso", "Root", CFrame.new(0, -CROUCH.Sink * hip, CROUCH.Back * hip) * lean)
	add("UpperTorso", "Waist", waist)
	add("Head", "Neck", CFrame.Angles(CROUCH.Neck, 0, 0))
	for _, side in { "Left", "Right" } do
		local left = side == "Left"
		add(
			`{side}UpperLeg`,
			`{side}Hip`,
			CFrame.fromEulerAnglesYXZ(CROUCH.Hip, if left then -CROUCH.HipOut else CROUCH.HipOut, 0)
		)
		add(`{side}LowerLeg`, `{side}Knee`, CFrame.Angles(CROUCH.Knee, 0, 0))
		add(`{side}Foot`, `{side}Ankle`, CFrame.Angles(CROUCH.Ankle, 0, 0))
		local arm: Arm = if left then CROUCH.Left else CROUCH.Right
		local shoulder =
			CFrame.fromEulerAnglesYXZ(arm.Shoulder, if left then -arm.In else arm.In, 0)
		local elbow = CFrame.Angles(arm.Elbow, 0, 0)
		add(`{side}UpperArm`, `{side}Shoulder`, shoulder)
		add(`{side}LowerArm`, `{side}Elbow`, elbow)
		-- the hand turned against the body, undoing the arm's own turn above it
		local above = (lean * waist * shoulder * elbow).Rotation
		add(
			`{side}Hand`,
			`{side}Wrist`,
			above:Inverse() * CFrame.fromEulerAnglesYXZ(arm.Pitch, arm.Yaw, 0)
		)
	end
	return joints
end

-- `viewing`: whether your view is on the car you drive now (DriveView's).
function DriverBodies.new(viewing: () -> boolean): Brix.System
	local player = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local bodies: { [Model]: Body } = {}
	-- your body's parts shown while you drive, and how hidden each was before
	local shown: { [BasePart]: number } = {}
	local shownOn: Model? = nil

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
			joints = crouching(character, humanoid.HipHeight),
			written = {},
		}
		bodies[character] = b
		return b
	end

	local function tagged(inst: Instance)
		if inst:IsA("Model") then
			local b = body(inst)
			if b and not b.down then
				b.down = true
				KneelView.rustle(inst)
			end
		end
	end

	local function untagged(inst: Instance)
		local b = bodies[inst :: Model]
		if b and b.down then
			b.down = false
			KneelView.rustle(b.character)
		end
	end

	local function hide()
		for part, was in shown do
			if part.Parent then
				part.LocalTransparencyModifier = was
			end
		end
		table.clear(shown)
		shownOn = nil
	end

	-- After the animations, before physics: each driver crouched or standing back up.
	local function pose(dt: number)
		if next(bodies) == nil then
			return
		end
		for character, b in bodies do
			if not character.Parent then
				bodies[character] = nil
				continue
			end
			local step = dt / CROUCH.Down
			b.level = math.clamp(b.level + (if b.down then step else -step), 0, 1)
			local w = b.level * b.level * (3 - 2 * b.level)
			for j, to in b.joints do
				local now = Joints.get(j)
				-- a joint no animation drives still holds this screen's last turn: start from rest
				local from = if now == b.written[j] then CFrame.identity else now
				local set = from:Lerp(to, w)
				Joints.set(j, set)
				b.written[j] = set
			end
			if b.level == 0 and not b.down then
				bodies[character] = nil
			end
		end
	end

	local system = { name = "DriverBodies" }

	function system.start(_: any, _context: Brix.Context)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Drive.BodyTag):Connect(tagged)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Drive.BodyTag):Connect(untagged)
		)
		for _, inst in CollectionService:GetTagged(Drive.BodyTag) do
			tagged(inst)
		end
		table.insert(connections, RunService.PreSimulation:Connect(pose))
	end

	-- Each frame after the camera's own step (which hides your body in first person): your body
	-- shown while your view is on the car, hidden as it was once your view is home.
	function system.step(_: any, _dt: number)
		local character = player.Character
		if not (viewing() and character) then
			if shownOn then
				hide()
			end
			return
		end
		if shownOn ~= character then
			hide()
			shownOn = character
			local torch = character:FindFirstChild(Torch.ModelName)
			for _, part in character:GetDescendants() do
				if part:IsA("BasePart") and not (torch and part:IsDescendantOf(torch)) then
					shown[part] = part.LocalTransparencyModifier
				end
			end
		end
		for part in shown do
			part.LocalTransparencyModifier = 0
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		hide()
		table.clear(bodies)
	end

	return system :: any -- any: a plain Brix system built field by field
end

return DriverBodies
