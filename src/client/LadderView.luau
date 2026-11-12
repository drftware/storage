--!strict
--[[
	LadderView: the ladder leaned on a unit's front and climbed, on every screen (L-13b2a).

	A ladder going up (the server tags it `Leaned.Tag`): it swings up off the carrier's shoulder
	against the front, its top lands with a bang, the fly runs out rattling and its locks catch,
	played here from the server's start time so every screen sees the same.

	A climber (the server tags their character `Leaned.ClimbTag`): your own climb, your screen moves
	your body along `Leaning.up` (onto the ladder, up it rung over rung, over the edge onto your
	belly on the steel top) and holds you there until you climb down (`Leaning.down`), your body
	touching nothing while it goes (the crawl's collision group). Roblox's own climb animation plays
	on your body while you're on the rungs, so friends see you climb. Your view stays yours to turn:
	it rides with your head, low over the steel once you lie down. Everyone's climb, on every screen:
	the rungs and the steel top's rattle, heard about a hall's length, and the arms of a friend lying
	up there reaching ahead, hands on the steel.

	Along the tops (L-13b2c): once you're up, the stick steers your lying body over the steel
	(`Tops.step` on the tops' map, so you never slide off or clip a wall), your view low over it,
	dipping and swaying with each pull. Every screen hears each crawler's pulls boom on the steel
	and sees their arms reach and haul in turn. Up there only you see the Climb down and Drop down
	buttons; Drop down takes you over a front's edge and down into the hall with a thud and a jolt.
	Lying at a sawn hole's edge with your head out over it you get Drop in instead: up, legs over
	the hole, straight down through it with your arms up, a crouch on the unit's floor (L-13b2d3a).
	The door below a front is in a button's reach from its edge, so while you lie up there its
	buttons are hidden on your screen (ButtonReach, L-16b1) and the server ignores them.

	Caught on the ladder (`Kept.Attribute`), your body is let go where it is at once, standing
	again: the server holds it from then (KeptPlayers) and ends the climb (Ladders).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local ButtonReach = require(script.Parent.ButtonReach)
local Crawling = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Crawling)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Joints = require(script.Parent.Joints)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Leaned = require(ReplicatedStorage.Shared.Tools.Leaned)
local Leaning = require(ReplicatedStorage.Shared.Tools.Leaning)
local SoundPrimer = require(script.Parent.SoundPrimer)
local TopHole = require(ReplicatedStorage.Shared.StorageUnit.TopHole)
local Tops = require(ReplicatedStorage.Shared.Tops)

local LINGER = 1.6 -- seconds a sounds' spot outlives its move: the last sound's tail
local SPOT_UP = 4 -- studs up the ladder from the floor where a climb's sounds play
local CLIMB_ANIM_RATE = 5 -- Roblox's Animate plays its climb at the climb's speed over this
-- Your view crawling the tops (Humanoid.CameraOffset, in your lying root's frame: X across your
-- back, Z up off the steel): each pull dips your head and sways it toward the hauling arm. A
-- hint only, so the view glides as a walk's does (halved Nov 11; owner: "the view jerks").
local VIEW_DIP = 0.035
local VIEW_SWAY = 0.03
local TELEPORT = 3 -- studs a crawler moves in a frame past which it's a jump, not a crawl
local MAP_EVERY = 0.4 -- seconds between looks for a newer tops' map (a top sawn through) as you crawl
local GLIDE_MAX = 6 -- studs: a put-back nearer than this glides you there; further, you're moved
local OFFER_EVERY = 0.2 -- seconds between looks for a hole your head is out over (its Drop in)
-- A sawn hole about its own middle, where its Drop in button sits (the server's, turned as the
-- hole is), and that middle in the hole's frame.
local HOLE = TopHole.Rect
local IN_X, IN_Z = (HOLE.left + HOLE.right) / 2, (HOLE.front + HOLE.back) / 2
local IN_RECT: Tops.Rect = {
	x0 = HOLE.left - IN_X,
	x1 = HOLE.right - IN_X,
	z0 = HOLE.front - IN_Z,
	z1 = HOLE.back - IN_Z,
}

type Move = "Up" | "Top" | "Down" | "Drop" | "In"

-- A ladder going up.
type Raise = {
	model: Model,
	weld: Weld?,
	from: CFrame,
	to: CFrame,
	start: number, -- os.clock() on this screen at which it began
	cue: number,
	spot: Attachment,
}
-- Your own climb: what the screen needs to move you and give you back.
type Mine = {
	root: BasePart,
	humanoid: Humanoid,
	from: CFrame, -- where your root stood as you pressed Climb
	groups: { [BasePart]: string },
	track: AnimationTrack?,
	-- crawling the tops: the map, the frame it's in, your lying height in it, where you are, and
	-- the server's last word putting you back
	steer: Tops.State?,
	map: Tops.Map?,
	origin: CFrame,
	localY: number,
	fix: CFrame?,
	mapAt: number, -- os.clock() of the last look for a newer map
	glide: CFrame?, -- where the server's word found you, gliding from it to where it put you
	glideAt: number,
}
-- One of a body's legs, for a landing's crouch: its joints and how long it is (from the avatar's
-- own rig attachments, so a long-legged avatar's feet stay put too).
type Leg = {
	hip: Joints.Joint,
	knee: Joints.Joint,
	ankle: Joints.Joint?,
	thigh: number, -- hip to knee
	shin: number, -- knee to ankle
}
type Climb = {
	character: Model,
	move: Move,
	start: number, -- os.clock() on this screen at which the move began
	front: CFrame, -- the move's frame: a unit's front, or dropping in its hole's (TopHole.frame)
	fit: Leaning.Fit,
	spot: number,
	standUp: number,
	cues: { Leaning.Cue },
	cue: number,
	sounds: Attachment,
	right: Joints.Joint?,
	left: Joints.Joint?,
	legs: { Leg },
	mine: Mine?,
	dropX: number,
	-- how far this crawler has crawled on this screen (their pulls' sounds and arms)
	travel: number,
	pulls: number,
	lastPos: Vector3?,
}

local LadderView = {}

local function smooth(k: number): number
	local c = math.clamp(k, 0, 1)
	return c * c * (3 - 2 * c)
end

-- One of the sounds at `spot`, its stretch played once, the end faded (as CrawlView's).
local function play(s: Leaning.Sound, spot: Instance, pitch: number?)
	local snd = Instance.new("Sound")
	snd.SoundId = s.id
	snd.Volume = s.volume
	snd.PlaybackSpeed = s.pitch * (pitch or 1)
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
			Leaning.Fade,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			0,
			false,
			math.max(0, seconds - Leaning.Fade)
		),
		{ Volume = 0 }
	):Play()
	task.delay(seconds + 0.2, function()
		snd:Destroy()
	end)
end

local function spotAt(name: string, at: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.Parent = Workspace.Terrain
	a.WorldPosition = at
	return a
end

local function standUpOf(character: Model): number
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	local half = if root and root:IsA("BasePart") then root.Size.Y / 2 else 1
	return (if humanoid then humanoid.HipHeight else 2) + half
end

-- A body's root `t` seconds into dropping in through the hole whose frame is `hole`, from lying
-- at height `lieY` in that frame, and how far to blend to it from where they lay.
local function inPose(hole: CFrame, t: number, lieY: number, standUp: number): (CFrame, number)
	local x, y, z, p, blend = Tops.dropIn(t, IN_X, IN_Z, HOLE.top, lieY, standUp)
	return Leaned.outward(hole, x, y, z, p), blend
end

-- Studs between two of a part's attachments, if it has both.
local function span(part: Instance?, a: string, b: string): number?
	local x = part and part:FindFirstChild(a)
	local y = part and part:FindFirstChild(b)
	if x and x:IsA("Attachment") and y and y:IsA("Attachment") then
		return (x.Position - y.Position).Magnitude
	end
	return nil
end

-- `character`'s legs that can take a crouch (an R15 body's; none on another kind).
local function legsOf(character: Model): { Leg }
	local legs: { Leg } = {}
	for _, side in { "Left", "Right" } do
		local upper = character:FindFirstChild(side .. "UpperLeg")
		local lower = character:FindFirstChild(side .. "LowerLeg")
		local hip = Joints.find(character, side .. "UpperLeg", side .. "Hip")
		local knee = Joints.find(character, side .. "LowerLeg", side .. "Knee")
		local thigh = span(upper, side .. "HipRigAttachment", side .. "KneeRigAttachment")
		local shin = span(lower, side .. "KneeRigAttachment", side .. "AnkleRigAttachment")
		if hip and knee and thigh and shin then
			table.insert(legs, {
				hip = hip,
				knee = knee,
				ankle = Joints.find(character, side .. "Foot", side .. "Ankle"),
				thigh = thigh,
				shin = shin,
			})
		end
	end
	return legs
end

-- A lander's knees taking the crouch (`dip` studs under standing), their feet kept flat on the
-- floor: the body's held stiff (PlatformStand stops its animation), so without this its feet
-- sank into the floor on every screen.
local function crouch(legs: { Leg }, dip: number)
	for _, leg in legs do
		local hip, knee, ankle = Tops.crouch(dip, leg.thigh, leg.shin)
		Joints.set(leg.hip, CFrame.Angles(hip, 0, 0))
		Joints.set(leg.knee, CFrame.Angles(knee, 0, 0))
		local a = leg.ankle
		if a then
			Joints.set(a, CFrame.Angles(ankle, 0, 0))
		end
	end
end

-- The climb animation Roblox's Animate script plays on this character, if it has one.
local function climbAnimation(character: Model): Animation?
	local animate = character:FindFirstChild("Animate")
	local climb = animate and animate:FindFirstChild("climb")
	local anim = climb and climb:FindFirstChildWhichIsA("Animation")
	return anim
end

function LadderView.new(kick: (amount: number) -> ()): Brix.System
	local raises: { [Model]: Raise } = {}
	local climbs: { [Model]: Climb } = {}
	local connections: { RBXScriptConnection } = {}
	local watched: { [Model]: { RBXScriptConnection } } = {}
	local player = Players.LocalPlayer
	local mine: Climb? = nil
	local buttonsOn = true -- as the server makes them, until the first pass turns them off
	local offered: Instance? = nil -- the Drop in button of the hole your head is out over
	local offerAt = 0 -- os.clock() of the last look for one
	local setButtons: (on: boolean) -> ()

	-- How far into its move a climb is, on this screen.
	local function elapsed(c: Climb): number
		return os.clock() - c.start
	end

	-- Your root's place at `t` into your move (crawling the tops is `steer`'s).
	local function rootAt(c: Climb, m: Mine, t: number): CFrame
		local fit, standUp = c.fit, c.standUp
		if c.move == "Down" then
			local x, y, z, p = Leaning.down(t, fit, c.spot, standUp)
			local target = Leaned.pose(c.front, x, y, z, p)
			-- from wherever you crawled to by the ladder, over onto it
			return if t < Leaning.Slide
				then m.from:Lerp(target, smooth(t / Leaning.Slide))
				else target
		elseif c.move == "Drop" then
			local x, y, z, p, blend =
				Tops.drop(t, c.dropX, fit.faceZ, fit.topY, Leaning.ProneUp, standUp)
			local target = Leaned.outward(c.front, x, y, z, p)
			return if blend < 1 then m.from:Lerp(target, blend) else target
		elseif c.move == "In" then
			local lieY = c.front:PointToObjectSpace(m.from.Position).Y
			local target, blend = inPose(c.front, t, lieY, standUp)
			return if blend < 1 then m.from:Lerp(target, blend) else target
		end
		if c.move == "Top" or t >= Leaning.upSeconds(fit, standUp) then
			local x, y, z, p = Leaning.lying(fit, c.spot)
			return Leaned.pose(c.front, x, y, z, p)
		end
		local x, y, z, p, blend = Leaning.up(t, fit, c.spot, standUp)
		local target = Leaned.pose(c.front, x, y, z, p)
		return if blend < 1 then m.from:Lerp(target, blend) else target
	end

	-- Whether `t` into the move has you on the rungs (the climb animation's time).
	local function onRungs(c: Climb, t: number): boolean
		if c.move == "Up" then
			return t >= Leaning.Mount * 0.5 and t < Leaning.upBusy(c.fit, c.standUp)
		elseif c.move == "Down" then
			return t >= Leaning.Slide * 0.6
				and t < Leaning.Slide + Leaning.downTime(c.fit, c.standUp)
		end
		return false
	end

	-- The buttons only someone up on the tops sees (Climb down, Drop down, Saw): on while you
	-- crawl. Drop in shows only for the hole your head is out over, and Drop down not then: they
	-- share a key, and at a hole's edge looking down it you mean the hole.
	local function showButton(inst: Instance)
		if not inst:IsA("ProximityPrompt") then
			return
		end
		local on = buttonsOn
		if inst:HasTag(Leaned.InButtonTag) then
			on = on and inst == offered
		elseif offered and inst:HasTag(Leaned.DropButtonTag) then
			on = false
		end
		inst.Enabled = on
	end
	local function showButtons()
		for _, inst in CollectionService:GetTagged(Leaned.TopButtonTag) do
			showButton(inst)
		end
	end
	-- A door's button: off your screen while you lie up on the tops, where the door below the
	-- front you lie at is 7 studs off, in its reach (L-16b1).
	local function hideDoor(inst: Instance)
		if inst:IsA("ProximityPrompt") then
			ButtonReach.hide(inst, "Tops", buttonsOn)
		end
	end
	function setButtons(on: boolean)
		if on == buttonsOn then
			return
		end
		buttonsOn = on
		if not on then
			offered = nil
		end
		showButtons()
		for _, inst in CollectionService:GetTagged(Door.ButtonTag) do
			hideDoor(inst)
		end
	end

	-- Lying at `at`: which hole's Drop in is yours to press, the one your head is out over.
	local function offer(at: CFrame)
		local found: Instance? = nil
		for _, inst in CollectionService:GetTagged(Leaned.InButtonTag) do
			local a = inst.Parent
			if a and a:IsA("Attachment") then
				local cf = a.WorldCFrame
				local p = cf:PointToObjectSpace(at.Position)
				-- lying, your root's up is the way your head points
				local h = cf:VectorToObjectSpace(at.UpVector)
				-- the button is a stud down the hole: within a body's height of it is this floor's
				if math.abs(p.Y) < 4 and Tops.atHole(IN_RECT, p.X, p.Z, h.X, h.Z) then
					found = inst
					break
				end
			end
		end
		if found ~= offered then
			offered = found
			showButtons()
		end
	end

	-- The stick's push and the way you look, flat, in the tops' frame `origin`. The push is your
	-- Humanoid's MoveDirection, which Roblox keeps setting from the stick while you lie
	-- PlatformStand (the PlayerModule no longer hands out its move vector: docs/STUDIO.md).
	local function input(origin: CFrame, humanoid: Humanoid): (number, number, number, number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return 0, 0, 0, 0
		end
		local cf = camera.CFrame
		local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if look.Magnitude < 0.2 then
			-- looking straight down over an edge: the top of your view is ahead
			look = Vector3.new(cf.UpVector.X, 0, cf.UpVector.Z)
		end
		if look.Magnitude < 1e-3 then
			return 0, 0, 0, 0
		end
		look = look.Unit
		local push = origin:VectorToObjectSpace(humanoid.MoveDirection)
		local ahead = origin:VectorToObjectSpace(look)
		return push.X, push.Z, ahead.X, ahead.Z
	end

	-- Crawling the tops, a frame: the stick steers your lying body over the steel (`Tops.step`),
	-- your view dipping and swaying with each pull. The server's word putting you back moves you.
	local function steer(c: Climb, m: Mine, dt: number)
		local track = m.track
		if track and track.IsPlaying then
			track:Stop(0.2)
		end
		local fix = c.character:GetAttribute(Leaned.FixAttribute)
		local reset: CFrame? = nil
		if typeof(fix) == "CFrame" and fix ~= m.fix then
			m.fix = fix
			reset = fix
		end
		local state = m.steer
		local now = os.clock()
		if state and not reset and now - m.mapAt >= MAP_EVERY then
			-- a top sawn through since: its hole off your map
			m.mapAt = now
			local fresh = Leaned.tops(m.root.Position)
			if fresh then
				m.map = fresh
			end
		end
		if not state or reset then
			local lx, ly, lz, lp = Leaning.lying(c.fit, c.spot)
			local lying = Leaned.pose(c.front, lx, ly, lz, lp)
			local from = reset or lying
			local map, origin = Leaned.tops(lying.Position)
			m.map = map
			m.mapAt = now
			m.origin = origin or CFrame.identity
			m.localY = m.origin:PointToObjectSpace(lying.Position).Y
			if reset and state then
				-- put back: glide there, not a jump; lying across a hole just sawn, it's the steel
				-- giving under you as you slide off its edge
				local was = m.root.CFrame
				if (was.Position - reset.Position).Magnitude < GLIDE_MAX then
					m.glide = was
					m.glideAt = now
				end
				if map and not Tops.fits(map, state.x, state.z, state.yaw) then
					play(Tops.Sounds.Shift, m.root)
					kick(Tops.SlideKick)
				end
			end
			local p = m.origin:PointToObjectSpace(from.Position)
			local head = m.origin:VectorToObjectSpace(from.UpVector)
			state = {
				x = p.X,
				z = p.Z,
				yaw = Tops.yawOf(head.X, head.Z),
				travel = if state then state.travel else 0,
			}
			setButtons(true)
		end
		local st = state :: Tops.State
		local map = m.map
		if map then
			local mx, mz, lx, lz = input(m.origin, m.humanoid)
			st = Tops.step(map, st, mx, mz, lx, lz, dt)
		end
		m.steer = st
		local at = m.origin
			* CFrame.new(st.x, m.localY, st.z)
			* CFrame.Angles(0, st.yaw, 0)
			* CFrame.Angles(-math.pi / 2, 0, 0)
		local glide = m.glide
		if glide then
			local k = (now - m.glideAt) / Tops.SlideSeconds
			if k < 1 then
				at = glide:Lerp(at, smooth(k))
			else
				m.glide = nil
			end
		end
		m.root.CFrame = at
		m.root.AssemblyLinearVelocity = Vector3.zero
		m.root.AssemblyAngularVelocity = Vector3.zero
		if now - offerAt >= OFFER_EVERY then
			offerAt = now
			offer(at)
		end
		local _, phase = Tops.pull(st.travel)
		local a = 2 * math.pi * phase
		m.humanoid.CameraOffset =
			Vector3.new(VIEW_SWAY * math.sin(a), 0, -VIEW_DIP * (1 - math.cos(a)) / 2)
	end

	-- Your climb over (down in the hall, or cut short): your body yours again.
	local function release(c: Climb, done: boolean)
		local m = c.mine
		if not m then
			return
		end
		c.mine = nil
		if mine == c then
			mine = nil
		end
		local track = m.track
		if track then
			track:Stop(0.15)
		end
		if done and m.humanoid.Health > 0 then
			if c.move == "Drop" then
				local fit = c.fit
				local x, y, z, p = Tops.drop(
					Tops.DropSeconds,
					c.dropX,
					fit.faceZ,
					fit.topY,
					Leaning.ProneUp,
					c.standUp
				)
				m.root.CFrame = Leaned.outward(c.front, x, y, z, p)
			elseif c.move == "In" then
				m.root.CFrame = inPose(c.front, Tops.InSeconds, HOLE.top, c.standUp)
			else
				local x, y, z, p = Leaning.stood(c.fit, c.standUp)
				m.root.CFrame = Leaned.pose(c.front, x, y, z, p)
			end
			m.root.AssemblyLinearVelocity = Vector3.zero
			m.root.AssemblyAngularVelocity = Vector3.zero
		end
		setButtons(false)
		m.humanoid.CameraOffset = Vector3.zero
		m.humanoid.PlatformStand = false
		for part, group in m.groups do
			if part.Parent then
				part.CollisionGroup = group
			end
		end
	end

	-- Your own climb starting: your body the screen's to move, touching nothing.
	local function takeOver(c: Climb)
		local character = c.character
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
			return
		end
		if player:GetAttribute(Kept.Attribute) == true then
			return -- caught: the server has your body now
		end
		local old = mine
		if old and old ~= c then
			release(old, false)
		end
		local groups: { [BasePart]: string } = {}
		for _, d in character:GetDescendants() do
			if d:IsA("BasePart") then
				groups[d] = d.CollisionGroup
				d.CollisionGroup = Crawling.CollisionGroup
			end
		end
		-- the Humanoid stops standing itself up and Animate stops its own tracks
		humanoid.PlatformStand = true
		local track: AnimationTrack? = nil
		local animator = humanoid:FindFirstChildOfClass("Animator")
		local anim = climbAnimation(character)
		if animator and anim then
			local t = animator:LoadAnimation(anim)
			t.Priority = Enum.AnimationPriority.Action
			t.Looped = true
			track = t
		end
		local fix = character:GetAttribute(Leaned.FixAttribute)
		c.mine = {
			root = root,
			humanoid = humanoid,
			from = root.CFrame,
			groups = groups,
			track = track,
			steer = nil,
			map = nil,
			origin = CFrame.identity,
			localY = 0,
			fix = if typeof(fix) == "CFrame" then fix else nil,
			mapAt = 0,
			glide = nil,
			glideAt = 0,
		}
		mine = c
	end

	-- The server's word on a climber: a new move begins (or a late screen catches up).
	local function sync(character: Model)
		local move = character:GetAttribute(Leaned.MoveAttribute)
		local started = character:GetAttribute(Leaned.MoveStartAttribute)
		local front = character:GetAttribute(Leaned.FrontAttribute)
		local size = character:GetAttribute(Leaned.SizeAttribute)
		local spot = character:GetAttribute(Leaned.SpotAttribute)
		local dropX = character:GetAttribute(Leaned.DropAttribute)
		if
			(move ~= "Up" and move ~= "Top" and move ~= "Down" and move ~= "Drop" and move ~= "In")
			or type(started) ~= "number"
			or typeof(front) ~= "CFrame"
			or type(size) ~= "string"
			or type(spot) ~= "number"
		then
			return
		end
		local isMine = character == player.Character
		local c = climbs[character]
		-- "Top" only says the move up is over: a screen already playing it keeps its own clock
		if c and move == "Top" then
			return
		end
		if c and c.move == move then
			return
		end
		local fit = Leaned.fit(size)
		local standUp = standUpOf(character)
		-- your own plays whole however late the word came; a friend's keeps to the server's clock
		local late = if isMine then 0 else math.max(0, Workspace:GetServerTimeNow() - started)
		local kind: Move = if move == "Up"
			then "Up"
			elseif move == "Down" then "Down"
			elseif move == "Drop" then "Drop"
			elseif move == "In" then "In"
			else "Top"
		local cues: { Leaning.Cue } = if kind == "Up" or kind == "Down"
			then Leaning.cues(kind, fit, standUp)
			elseif kind == "Drop" then Tops.dropCues()
			elseif kind == "In" then Tops.inCues()
			else {}
		local x = if type(dropX) == "number" then dropX else 0
		-- a move on another front (down another ladder, off a unit) plays its sounds there
		local same = c and c.front == front and kind ~= "Drop" and kind ~= "In"
		if c and not same then
			local old = c.sounds
			task.delay(LINGER, function()
				old:Destroy()
			end)
		end
		local sounds = if c and same
			then c.sounds
			elseif kind == "Drop" then spotAt(
				"TopsDrop",
				(front * CFrame.new(x, fit.topY, fit.faceZ - Tops.Out)).Position
			)
			elseif kind == "In" then spotAt(
				"TopsDropIn",
				(front * CFrame.new(IN_X, standUp, IN_Z)).Position
			)
			else spotAt(
				"LadderSounds",
				Leaned.point(
					front,
					fit,
					fit.ox - fit.leanX,
					0,
					-(SPOT_UP / math.sin(Leaning.Angle))
				)
			)
		local fresh: Climb = {
			character = character,
			move = kind,
			start = os.clock() - late,
			front = front,
			fit = fit,
			spot = spot,
			standUp = standUp,
			cues = cues,
			cue = 1,
			sounds = sounds,
			right = Joints.find(character, "RightUpperArm", "RightShoulder"),
			left = Joints.find(character, "LeftUpperArm", "LeftShoulder"),
			legs = if kind == "Drop" or kind == "In" then legsOf(character) else {},
			mine = if c then c.mine else nil,
			dropX = x,
			travel = if c then c.travel else 0,
			pulls = if c then c.pulls else 0,
			lastPos = if c then c.lastPos else nil,
		}
		while fresh.cue <= #cues and cues[fresh.cue].at < late do
			fresh.cue += 1
		end
		if c and mine == c then
			mine = fresh
		end
		climbs[character] = fresh
		if isMine and not fresh.mine then
			takeOver(fresh)
		end
		-- off the tops: from wherever you crawled to, your view back to rest
		local fm = fresh.mine
		if fm and (kind == "Down" or kind == "Drop" or kind == "In") then
			fm.from = fm.root.CFrame
			fm.steer = nil
			fm.humanoid.CameraOffset = Vector3.zero
			setButtons(false)
		end
	end

	-- A climber: their moves as the server's attributes change.
	local function begin(inst: Instance)
		if not inst:IsA("Model") or watched[inst] then
			return
		end
		local character = inst
		watched[character] = {
			character:GetAttributeChangedSignal(Leaned.MoveStartAttribute):Connect(function()
				sync(character)
			end),
			character:GetAttributeChangedSignal(Leaned.MoveAttribute):Connect(function()
				sync(character)
			end),
		}
		sync(character)
	end

	-- A climb gone from this screen: its sounds' spot outlives it by the last sound's tail.
	local function forget(c: Climb)
		if climbs[c.character] == c then
			climbs[c.character] = nil
		end
		local sounds = c.sounds
		task.delay(LINGER, function()
			sounds:Destroy()
		end)
	end

	-- The server's word that a climber is off the ladder. Your own climb down runs to its end on
	-- your screen's clock; anything else is let go at once.
	local function ended(inst: Instance)
		local character = inst :: Model
		local conns = watched[character]
		if conns then
			for _, conn in conns do
				conn:Disconnect()
			end
			watched[character] = nil
		end
		local c = climbs[character]
		if not c then
			return
		end
		local t = elapsed(c)
		if
			c.mine
			and (
				(c.move == "Down" and t < Leaning.downSeconds(c.fit, c.standUp))
				or (c.move == "Drop" and t < Tops.DropSeconds)
				or (c.move == "In" and t < Tops.InSeconds)
			)
		then
			return
		end
		release(c, false)
		forget(c)
	end

	local function raiseAdded(inst: Instance)
		if not inst:IsA("Model") or raises[inst] then
			return
		end
		local model = inst
		local started = model:GetAttribute(Leaned.StartAttribute)
		local from = model:GetAttribute(Leaned.FromAttribute)
		local to = model:GetAttribute(Leaned.ToAttribute)
		if type(started) ~= "number" or typeof(from) ~= "CFrame" or typeof(to) ~= "CFrame" then
			return
		end
		local late = math.max(0, Workspace:GetServerTimeNow() - started)
		if late >= Leaning.Raised + 0.5 then
			return -- a ladder streaming in long up: the server's place is its place
		end
		local fly = model:FindFirstChild("LadderFly")
		local weld = fly and fly:FindFirstChild("FlyWeld")
		local r: Raise = {
			model = model,
			weld = if weld and weld:IsA("Weld") then weld else nil,
			from = from,
			to = to,
			start = os.clock() - late,
			cue = 1,
			spot = spotAt("LadderRaise", to.Position),
		}
		local cues = Leaning.raiseCues()
		while r.cue <= #cues and cues[r.cue].at < late do
			r.cue += 1
		end
		raises[model] = r
	end

	local raiseCues = Leaning.raiseCues()

	-- Each frame before the camera: ladders going up, in place on this screen.
	local function raiseStep()
		if next(raises) == nil then
			return
		end
		local clock = os.clock()
		for model, r in raises do
			local t = clock - r.start
			local swing, run = Leaning.raise(t)
			if model.Parent then
				model:PivotTo(r.from:Lerp(r.to, swing))
				local weld = r.weld
				if weld then
					weld.C0 = Leaned.fly(run)
				end
			end
			while r.cue <= #raiseCues and raiseCues[r.cue].at <= t do
				play(raiseCues[r.cue].sound, r.spot)
				r.cue += 1
			end
			if t >= Leaning.Raised then
				raises[model] = nil
				local spot = r.spot
				task.delay(LINGER, function()
					spot:Destroy()
				end)
			end
		end
	end

	-- Before physics: your body on its path; then the arms of everyone lying up top.
	local function bodyStep(dt: number)
		local c = mine
		local m = c and c.mine
		if c and m then
			local t = elapsed(c)
			if m.humanoid.Health <= 0 or not c.character.Parent then
				release(c, false)
			elseif
				(c.move == "Down" and t >= Leaning.downSeconds(c.fit, c.standUp))
				or (c.move == "Drop" and t >= Tops.DropSeconds)
				or (c.move == "In" and t >= Tops.InSeconds)
			then
				release(c, true)
				if not c.character:HasTag(Leaned.ClimbTag) then
					forget(c)
				end
			elseif
				c.move == "Top" or (c.move == "Up" and t >= Leaning.upSeconds(c.fit, c.standUp))
			then
				steer(c, m, dt)
			else
				m.root.CFrame = rootAt(c, m, t)
				m.root.AssemblyLinearVelocity = Vector3.zero
				m.root.AssemblyAngularVelocity = Vector3.zero
				local track = m.track
				if track then
					local rungs = onRungs(c, t)
					if rungs and not track.IsPlaying then
						local speed = if c.move == "Down"
							then Leaning.DownSpeed
							else Leaning.ClimbSpeed
						track:Play(0.1)
						-- down the rungs it plays backwards, as Animate's does
						local sign = if c.move == "Down" then -1 else 1
						track:AdjustSpeed(sign * speed * math.sin(Leaning.Angle) / CLIMB_ANIM_RATE)
					elseif not rungs and track.IsPlaying then
						track:Stop(0.2)
					end
				end
			end
		end
		for _, cl in climbs do
			if cl.move == "Drop" or cl.move == "In" then
				local dip = Tops.landDip(cl.move, elapsed(cl))
				if dip > 0 then
					crouch(cl.legs, dip)
				end
			end
			if cl.move == "In" then
				-- dropping in: your arms from the crawl's reach to up over your head as you fall
				local lift, w = Tops.inArms(elapsed(cl))
				if w > 0 then
					local up =
						CFrame.Angles(Leaning.ArmRest + (Tops.InArm - Leaning.ArmRest) * lift, 0, 0)
					local tuck = Crawling.ArmTuck * (1 - lift)
					local r, l = cl.right, cl.left
					if r then
						Joints.bend(r, CFrame.Angles(0, 0, tuck) * up, w)
					end
					if l then
						Joints.bend(l, CFrame.Angles(0, 0, -tuck) * up, w)
					end
				end
				continue
			end
			local move: "Up" | "Top" | "Down" = if cl.move == "Up"
				then "Up"
				elseif cl.move == "Top" then "Top"
				else "Down"
			local w = Leaning.arms(move, elapsed(cl), cl.fit, cl.standUp)
			if w > 0 then
				-- crawling, one arm reaches while the other hauls
				local sr, sl = Tops.arms(cl.travel)
				local r, l = cl.right, cl.left
				if r then
					local reach = CFrame.Angles(Leaning.ArmRest + sr, 0, 0)
					Joints.bend(r, CFrame.Angles(0, 0, Crawling.ArmTuck) * reach, w)
				end
				if l then
					local reach = CFrame.Angles(Leaning.ArmRest + sl, 0, 0)
					Joints.bend(l, CFrame.Angles(0, 0, -Crawling.ArmTuck) * reach, w)
				end
			end
		end
	end

	local system = { name = "LadderView" }

	function system.start(_: any, _context: Brix.Context)
		local sounds = Leaning.Sounds
		SoundPrimer.prime({
			sounds.Lands.id,
			sounds.RunOut.id,
			sounds.Climb.id,
			sounds.Steel.id,
			Tops.Sounds.Drag.id,
			Tops.Sounds.Land.id,
		})
		setButtons(false)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Leaned.TopButtonTag):Connect(showButton)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Leaned.InButtonTag):Connect(showButton)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Leaned.DropButtonTag):Connect(showButton)
		)
		table.insert(
			connections,
			-- a door streamed in while you lie up there
			CollectionService:GetInstanceAddedSignal(Door.ButtonTag)
				:Connect(function(inst: Instance)
					if buttonsOn then
						hideDoor(inst)
					end
				end)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Leaned.Tag):Connect(raiseAdded)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Leaned.Tag):Connect(function(inst: Instance)
				raises[inst :: Model] = nil
			end)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Leaned.ClimbTag):Connect(begin)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Leaned.ClimbTag):Connect(ended)
		)
		table.insert(connections, RunService.PreSimulation:Connect(bodyStep))
		table.insert(connections, RunService.RenderStepped:Connect(raiseStep))
		table.insert(
			connections,
			player:GetAttributeChangedSignal(Kept.Attribute):Connect(function()
				local c = mine
				if c and player:GetAttribute(Kept.Attribute) == true then
					release(c, false)
				end
			end)
		)
		for _, inst in CollectionService:GetTagged(Leaned.Tag) do
			raiseAdded(inst)
		end
		for _, inst in CollectionService:GetTagged(Leaned.ClimbTag) do
			begin(inst)
		end
	end

	-- A crawler's pulls along the tops, from how far their body moves on this screen: each pull a
	-- soft boom on the steel, every other one a little higher, with a drag of your body on it.
	local function crawlSounds(c: Climb)
		local root = c.character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return
		end
		local p = root.Position
		local last = c.lastPos
		c.lastPos = p
		if not last then
			return
		end
		local d = ((p - last) * Vector3.new(1, 0, 1)).Magnitude
		if d >= TELEPORT then
			return
		end
		c.travel += d
		local pull = math.floor(c.travel / Tops.Pull)
		if pull > c.pulls then
			c.pulls = pull
			local other = pull % 2 == 1
			play(Tops.Sounds.Boom, root, if other then Tops.OtherPull else 1)
			if not other then
				play(Tops.Sounds.Drag, root)
			end
		end
	end

	-- Each climb's sounds as their moments come, and the kicks to your own view.
	function system.step(_: any, _dt: number)
		if next(climbs) == nil then
			return
		end
		for _, c in climbs do
			local t = elapsed(c)
			if c.move == "Top" or (c.move == "Up" and t >= Leaning.upSeconds(c.fit, c.standUp)) then
				crawlSounds(c)
			end
			while c.cue <= #c.cues and c.cues[c.cue].at <= t do
				local cue = c.cues[c.cue]
				c.cue += 1
				play(cue.sound, c.sounds)
				if c.mine and cue.kick > 0 then
					kick(cue.kick)
				end
			end
		end
	end

	function system.stop(_: any)
		for _, conn in connections do
			conn:Disconnect()
		end
		table.clear(connections)
		for _, conns in watched do
			for _, conn in conns do
				conn:Disconnect()
			end
		end
		table.clear(watched)
		local c = mine
		if c then
			release(c, false)
		end
		for _, cl in climbs do
			cl.sounds:Destroy()
		end
		table.clear(climbs)
		for _, r in raises do
			r.spot:Destroy()
		end
		table.clear(raises)
	end

	return system
end

return LadderView
