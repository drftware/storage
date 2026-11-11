--!strict
--[[
	CrawlView: crawling through a sawn hole, on every screen (L-12b3). While the server tags a
	character `Crawling.Tag`, that player is crawling through the hole its attributes name.

	Your own crawl: your screen moves your body along the path (Roblox lets each screen move its
	own player's body, so friends see it move smoothly), the body touching nothing while it goes so
	the hole's edges can't snag it, and your view rides with your head: down low to the hole's
	mouth, a thud as your belly hits the floor, rocking with each pull as the cut steel scrapes
	past, then rising as you stand in the next unit, looking on the way you crawled.

	A Crawl button shows only on your side of its wall (you can see the far one through the hole)
	and none while you crawl.

	Everyone's crawl, on every screen: their arms reach up past their head and haul in turn, and
	the drop, the two drags and the steel play at the hole, heard about a unit each way.

	Caught mid-crawl (`Kept.Attribute`), your body is let go where it is at once: the server holds
	it from then (KeptPlayers), and the view is the catch's (CaughtLunge), which gives you your own
	camera back at the black.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Crawling = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Crawling)
local Joints = require(script.Parent.Joints)
local Kept = require(ReplicatedStorage.Shared.Kept)
local SoundPrimer = require(script.Parent.SoundPrimer)

local CAMERA_STEP = "CrawlCamera"
local SPOT_UP = 1 -- studs above the floor at the hole where its sounds play: a body's height
local LINGER = 1.2 -- seconds the sounds' spot outlives the move: the last sound's tail
local SIDE_EVERY = 0.1 -- seconds between checks of which side of each hole you're on

-- How your own crawl ends: through to the far side, cut short (you died, or a new crawl), or caught.
type Ending = "Through" | "Cut" | "Caught"

-- Your own crawl: what the screen needs to move you and put you back.
type Mine = {
	root: BasePart,
	humanoid: Humanoid,
	from: CFrame, -- where your root stood as you pressed
	eyeFrom: CFrame, -- your view then
	standUp: number, -- your root's height standing
	groups: { [BasePart]: string }, -- each part's collision group before the move
}
type Crawl = {
	character: Model,
	frame: CFrame, -- the crawl's frame (Crawling)
	start: number, -- os.clock() on this screen at which the move began
	cue: number, -- the next of the move's cues to play
	spot: Attachment,
	right: Joints.Joint?,
	left: Joints.Joint?,
	mine: Mine?,
}

local CrawlView = {}

-- Your root `t` seconds in: along the path, coming from where you stood as you got down.
local function rootAt(c: Crawl, m: Mine, t: number): CFrame
	local along, up, pitch, blend = Crawling.pose(t, m.standUp)
	local target = c.frame * CFrame.new(0, up, -along) * CFrame.Angles(-pitch, 0, 0)
	return if blend < 1 then m.from:Lerp(target, blend) else target
end

-- One of the move's sounds at the hole, its stretch played once, the end faded.
local function play(cue: Crawling.Cue, spot: Attachment)
	local s = cue.sound
	local snd = Instance.new("Sound")
	snd.SoundId = s.id
	snd.Volume = s.volume
	snd.PlaybackSpeed = s.pitch * cue.pitch
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = s.near
	snd.RollOffMaxDistance = s.reach
	snd.PlaybackRegionsEnabled = true
	snd.PlaybackRegion = NumberRange.new(s.from, s.from + s.length)
	snd.TimePosition = s.from
	snd.Parent = spot
	snd:Play()
	local seconds = s.length / snd.PlaybackSpeed
	TweenService:Create(
		snd,
		TweenInfo.new(
			Crawling.Fade,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			0,
			false,
			math.max(0, seconds - Crawling.Fade)
		),
		{ Volume = 0 }
	):Play()
end

function CrawlView.new(kick: (amount: number) -> ()): Brix.System
	local crawls: { [Model]: Crawl } = {}
	local cues = Crawling.cues()
	local connections: { RBXScriptConnection } = {}
	local player = Players.LocalPlayer
	local mine: Crawl? = nil -- your own crawl, while the screen moves you
	local bound = false
	local buttons: { [ProximityPrompt]: CFrame } = {} -- each Crawl button, by its crawl frame
	local sideIn = 0 -- seconds to the next check of which side you're on

	-- A Crawl button shows to you only from its own side of the wall, and not while you crawl.
	local function showButton(p: ProximityPrompt, frame: CFrame, at: Vector3?)
		p.Enabled = at ~= nil and mine == nil and frame:PointToObjectSpace(at).Z > 0
	end

	local function myRoot(): Vector3?
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root.Position else nil
	end

	local function addButton(inst: Instance)
		if not inst:IsA("ProximityPrompt") then
			return
		end
		local frame = inst:GetAttribute(Crawling.FrameAttribute)
		if typeof(frame) == "CFrame" then
			buttons[inst] = frame
			showButton(inst, frame, myRoot())
		end
	end

	-- Your view, each frame of your crawl: at your head, looking the way you crawl.
	local function cameraStep()
		local c = mine
		local m = c and c.mine
		local camera = Workspace.CurrentCamera
		if not (c and m and camera) then
			return
		end
		local t = math.min(os.clock() - c.start, Crawling.Seconds)
		local look, bob, roll, lift = Crawling.view(t)
		local head = rootAt(c, m, t) * CFrame.new(0, Crawling.EyeUp, 0)
		local ahead = CFrame.lookAt(Vector3.zero, c.frame.LookVector, Vector3.yAxis)
			* CFrame.Angles(look, 0, roll)
		local _, _, _, blend = Crawling.pose(t, m.standUp)
		-- getting down, your view turns from where it was looking
		local turn = if blend < 1 then m.eyeFrom.Rotation:Lerp(ahead, blend) else ahead
		local eye = head.Position
			+ Vector3.new(0, lift - bob, 0)
			- turn.LookVector * Crawling.EyeBack
		camera.CFrame = CFrame.new(eye) * turn
	end

	-- Your crawl over: your body yours again, and your view too unless a keeper caught you (the
	-- catch has it then, and turns it to the keeper's face from where it was).
	local function release(c: Crawl, ending: Ending)
		local m = c.mine
		if not m then
			return
		end
		c.mine = nil
		if mine == c then
			mine = nil
		end
		if bound then
			RunService:UnbindFromRenderStep(CAMERA_STEP)
			bound = false
		end
		local through = ending == "Through"
		local standing = c.frame * CFrame.new(0, m.standUp, -Crawling.StandAlong)
		if through and m.humanoid.Health > 0 then
			m.root.CFrame = standing
			m.root.AssemblyLinearVelocity = Vector3.zero
			m.root.AssemblyAngularVelocity = Vector3.zero
		end
		m.humanoid.PlatformStand = false
		for part, group in m.groups do
			if part.Parent then
				part.CollisionGroup = group
			end
		end
		local camera = Workspace.CurrentCamera
		if camera and ending ~= "Caught" then
			if through then
				local ahead = c.frame.LookVector
				local eye = (standing * CFrame.new(0, Crawling.EyeUp, 0)).Position
					- ahead * Crawling.EyeBack
				camera.CFrame = CFrame.lookAt(eye, eye + ahead)
			end
			camera.CameraType = Enum.CameraType.Custom
		end
	end

	-- Your own crawl starting: your body the screen's to move, touching nothing; your view too.
	local function takeOver(c: Crawl)
		local character = c.character
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local camera = Workspace.CurrentCamera
		if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 and camera) then
			return
		end
		if player:GetAttribute(Kept.Attribute) == true then
			return -- caught: the server has your body now
		end
		local old = mine
		if old then
			release(old, "Cut")
		end
		local groups: { [BasePart]: string } = {}
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") then
				groups[d] = d.CollisionGroup
				d.CollisionGroup = Crawling.CollisionGroup
			end
		end
		-- the Humanoid stops standing itself up and its animations stop (Animate), so the path
		-- and the arms below are all that move you
		humanoid.PlatformStand = true
		c.mine = {
			root = root,
			humanoid = humanoid,
			from = root.CFrame,
			eyeFrom = camera.CFrame,
			standUp = humanoid.HipHeight + root.Size.Y / 2,
			groups = groups,
		}
		mine = c
		sideIn = 0
		camera.CameraType = Enum.CameraType.Scriptable
		-- with the camera's own step (Scriptable, it moves nothing), before CameraShake's kick
		RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value, cameraStep)
		bound = true
	end

	local function begin(inst: Instance)
		if not inst:IsA("Model") then
			return
		end
		local character = inst
		local frame = character:GetAttribute(Crawling.FrameAttribute)
		local started = character:GetAttribute(Crawling.StartAttribute)
		if typeof(frame) ~= "CFrame" or type(started) ~= "number" then
			return
		end
		local isMine = character == player.Character
		-- your own plays whole however late the word came; a friend's keeps to the server's clock
		local late = if isMine then 0 else math.max(0, Workspace:GetServerTimeNow() - started)
		if late >= Crawling.Seconds then
			return -- a crawl streaming in that's already over
		end
		local spot = Instance.new("Attachment")
		spot.Name = "CrawlSounds"
		spot.Parent = Workspace.Terrain
		spot.WorldPosition = frame.Position + Vector3.new(0, SPOT_UP, 0)
		task.delay(Crawling.Seconds - late + LINGER, function()
			spot:Destroy()
		end)
		local c: Crawl = {
			character = character,
			frame = frame,
			start = os.clock() - late,
			cue = 1,
			spot = spot,
			right = Joints.find(character, "RightUpperArm", "RightShoulder"),
			left = Joints.find(character, "LeftUpperArm", "LeftShoulder"),
			mine = nil,
		}
		while c.cue <= #cues and cues[c.cue].at < late do
			c.cue += 1
		end
		crawls[character] = c
		if isMine then
			takeOver(c)
		end
	end

	-- The server's word that a crawl is over: a friend's arms are theirs again. Your own runs to
	-- its end on your screen's clock whatever the server says.
	local function ended(inst: Instance)
		local c = crawls[inst :: Model]
		if c and not c.mine then
			crawls[inst :: Model] = nil
		end
	end

	-- Before physics: your body on the path; then everyone's arms over their animations.
	local function bodyStep()
		local c = mine
		local m = c and c.mine
		if c and m then
			local t = os.clock() - c.start
			if t >= Crawling.Seconds then
				release(c, "Through")
			elseif m.humanoid.Health <= 0 or not c.character.Parent then
				release(c, "Cut")
			else
				m.root.CFrame = rootAt(c, m, t)
				m.root.AssemblyLinearVelocity = Vector3.zero
				m.root.AssemblyAngularVelocity = Vector3.zero
			end
		end
		local clock = os.clock()
		for _, cr in crawls do
			local right, left, w = Crawling.arms(clock - cr.start)
			if w > 0 then
				local r, l = cr.right, cr.left
				if r then
					Joints.bend(
						r,
						CFrame.Angles(0, 0, Crawling.ArmTuck) * CFrame.Angles(right, 0, 0),
						w
					)
				end
				if l then
					Joints.bend(
						l,
						CFrame.Angles(0, 0, -Crawling.ArmTuck) * CFrame.Angles(left, 0, 0),
						w
					)
				end
			end
		end
	end

	local system = { name = "CrawlView" }

	function system.start(_: any, _context: Brix.Context)
		SoundPrimer.prime({
			Crawling.Sounds.Thud.id,
			Crawling.Sounds.Drag.id,
			Crawling.Sounds.Steel.id,
		})
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Crawling.Tag):Connect(begin)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Crawling.Tag):Connect(ended)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Crawling.ButtonTag):Connect(addButton)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Crawling.ButtonTag)
				:Connect(function(inst: Instance)
					buttons[inst :: ProximityPrompt] = nil
				end)
		)
		table.insert(connections, RunService.PreSimulation:Connect(bodyStep))
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Kept.Attribute):Connect(function()
				local c = mine
				if c and player:GetAttribute(Kept.Attribute) == true then
					release(c, "Caught")
				end
			end)
		)
		for _, inst in CollectionService:GetTagged(Crawling.ButtonTag) do
			addButton(inst)
		end
		for _, inst in CollectionService:GetTagged(Crawling.Tag) do
			begin(inst)
		end
	end

	-- Which Crawl buttons you see; the move's sounds as their moments come, the kicks to your own
	-- view, and crawls done.
	function system.step(_: any, dt: number)
		sideIn -= dt
		if sideIn <= 0 and next(buttons) ~= nil then
			sideIn = SIDE_EVERY
			local at = myRoot()
			for p, frame in buttons do
				showButton(p, frame, at)
			end
		end
		if next(crawls) == nil then
			return
		end
		local clock = os.clock()
		for character, c in crawls do
			local t = clock - c.start
			while c.cue <= #cues and cues[c.cue].at <= t do
				local cue = cues[c.cue]
				c.cue += 1
				play(cue, c.spot)
				if c.mine and cue.kick > 0 then
					kick(cue.kick)
				end
			end
			if t >= Crawling.Seconds and not c.mine then
				crawls[character] = nil
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		local c = mine
		if c then
			release(c, "Cut")
		end
		for _, cr in crawls do
			cr.spot:Destroy()
		end
		table.clear(crawls)
	end

	return system
end

return CrawlView
