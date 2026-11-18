--!strict
--[[
	HomeSitView: sitting on a home's furniture, on this screen (S5-03i4, D-353). The moment: you
	walk up to the milk crate in your home and press Sit; your view glides down into the seat with
	a hollow knock. The beanbag gives under you with a soft puff, on the blanket you sit
	cross-legged, and a friend lands on the camp bed beside you with the canvas taking up the slack.

	- The buttons: the server's Sit (Sits) shows here only while this screen's player stands in
	  that home (its folder's room, `Press.inside`), Arrange isn't open (your tools are stowed then),
	  you aren't sat already, and the seat is free. Checked a few times a second.
	- Every screen, as anyone lands: the seat's sound (`Sit.Sounds`) where they land, and the part
	  under them squashes and comes back up (`give`); getting up plays the sound softer.
	- Every screen: a body on a floor seat (the blanket) sits cross-legged, its legs turned past the
	  sit animation before physics (`Joints`, as KneelView's kneel), eased in.
	- Your own landing: the view glides from where you stood into the seat (`Humanoid.CameraOffset`
	  eased back to nothing over `Sit.Ease`) instead of dropping in one frame.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Press = require(ReplicatedStorage.Shared.Home.Press)
local Sit = require(ReplicatedStorage.Shared.Home.Sit)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Joints = require(script.Parent.Joints)
local SoundPrimer = require(script.Parent.SoundPrimer)

type Joint = Joints.Joint

-- Seconds between looks at who's in which home and which seats are free.
local LOOK = 0.2
-- Studs: a landing's sound is full within this and gone past the far one (a friend beside you
-- hears it, the next unit doesn't).
local NEAR, FAR = 6, 40

-- A seat on this screen with its Sit button.
type Held = {
	seat: Seat,
	model: Model,
	prompt: ProximityPrompt,
	row: Sit.Row,
	sat: Humanoid?, -- who sits on it now, as this screen last saw
	changed: RBXScriptConnection,
}

-- A body sat cross-legged on this screen: its leg joints, how far into the pose (0 to 1), and
-- what this screen wrote to each last frame.
type Crossed = {
	joints: { [Joint]: CFrame },
	level: number,
	written: { [Joint]: CFrame },
}

-- Each leg joint of R15 body `character` and its turn sat cross-legged.
local function crossed(character: Model): { [Joint]: CFrame }
	local c = Sit.Cross
	local joints: { [Joint]: CFrame } = {}
	for _, side in { "Left", "Right" } do
		local m = if side == "Left" then 1 else -1 -- the right leg mirrors the left
		local function add(part: string, name: string, to: CFrame)
			local j = Joints.find(character, `{side}{part}`, `{side}{name}`)
			if j then
				joints[j] = to
			end
		end
		add(
			"UpperLeg",
			"Hip",
			CFrame.Angles(0, -m * c.Out, 0)
				* CFrame.Angles(c.Pitch, 0, 0)
				* CFrame.Angles(0, 0, m * c.Roll)
		)
		add("LowerLeg", "Knee", CFrame.Angles(c.Knee, 0, 0))
		add("Foot", "Ankle", CFrame.Angles(0, 0, m * c.Ankle))
	end
	return joints
end

-- The seat's landing sound at `seat`, at `share` of its volume, its end faded.
local function thump(seat: Seat, spec: Sit.Sound, share: number)
	local snd = Instance.new("Sound")
	snd.SoundId = spec.id
	snd.Volume = spec.volume * share
	snd.PlaybackSpeed = spec.pitch
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = NEAR
	snd.RollOffMaxDistance = FAR
	snd.PlaybackRegionsEnabled = true
	snd.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
	snd.TimePosition = spec.from
	snd.Parent = seat
	snd:Play()
	local seconds = spec.length / spec.pitch
	local fade = math.min(0.12, seconds / 2)
	TweenService:Create(
		snd,
		TweenInfo.new(
			fade,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In,
			0,
			false,
			seconds - fade
		),
		{ Volume = 0 }
	):Play()
	task.delay(seconds + 0.2, function()
		snd:Destroy()
	end)
end

-- The part under a lander squashes by `squash` of its height, its foot staying put, and comes back
-- up to rest; nothing if the piece has no such part.
local function give(model: Model, name: string, squash: number)
	local p = model:FindFirstChild(name)
	if not (p and p:IsA("BasePart")) or p:GetAttribute("SitGiving") then
		return
	end
	local size, cf = p.Size, p.CFrame
	local drop = size.Y * squash
	local down =
		{ Size = size - Vector3.new(0, drop, 0), CFrame = cf * CFrame.new(0, -drop / 2, 0) }
	p:SetAttribute("SitGiving", true)
	local tween = TweenService:Create(
		p,
		TweenInfo.new(Sit.Down, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		down
	)
	tween.Completed:Once(function()
		local back = TweenService:Create(
			p,
			TweenInfo.new(Sit.Back, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Size = size, CFrame = cf }
		)
		back.Completed:Once(function()
			p:SetAttribute("SitGiving", nil)
		end)
		back:Play()
	end)
	tween:Play()
end

local HomeSitView = {}

function HomeSitView.new(): Brix.System
	local me = Players.LocalPlayer
	local held: { [Seat]: Held } = {}
	local bodies: { [Model]: Crossed } = {}
	local inHome: { [Instance]: boolean } = {} -- per home folder, this look: am I in it
	local connections: { RBXScriptConnection } = {}
	local since = 0
	local stood: Vector3? = nil -- where your root was, the last frame you weren't sat
	local easing: Tween? = nil

	-- Your own landing: the view starts where you stood and glides into the seat.
	local function glide(humanoid: Humanoid)
		local from = stood
		task.defer(function()
			local root = humanoid.RootPart
			if not (from and root) or humanoid.SeatPart == nil then
				return
			end
			if easing then
				easing:Cancel()
			end
			humanoid.CameraOffset = root.CFrame:VectorToObjectSpace(from - root.Position)
			local t = TweenService:Create(
				humanoid,
				TweenInfo.new(Sit.Ease, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CameraOffset = Vector3.zero }
			)
			easing = t
			t:Play()
		end)
	end

	local function occupied(h: Held)
		local now = h.seat.Occupant
		local was = h.sat
		if now == was then
			return
		end
		h.sat = now
		local spec = Sit.Sounds[h.row.sound]
		if was then
			thump(h.seat, spec, Sit.Up)
			local body = was.Parent
			if body and body:IsA("Model") then
				bodies[body] = nil
			end
		end
		if now then
			thump(h.seat, spec, 1)
			if h.row.give and h.row.squash > 0 then
				give(h.model, h.row.give, h.row.squash)
			end
			local body = now.Parent
			if h.row.pose == "Floor" and body and body:IsA("Model") then
				bodies[body] = { joints = crossed(body), level = 0, written = {} }
			end
			if body == me.Character then
				glide(now)
			end
		end
	end

	local function look()
		local character = me.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if humanoid then humanoid.RootPart else nil
		local at = if root then root.Position else nil
		local free = humanoid ~= nil and humanoid.Health > 0 and humanoid.SeatPart == nil
		local stowed = me:GetAttribute(Tools.StowAttribute) == true
		table.clear(inHome)
		for seat, h in held do
			local folder = h.model.Parent
			local here = false
			if folder and at and free and not stowed then
				local known = inHome[folder]
				if known == nil then
					local middle = folder:GetAttribute(Press.RoomAttribute)
					local half = folder:GetAttribute(Press.HalfAttribute)
					known = false
					if typeof(middle) == "CFrame" and typeof(half) == "Vector3" then
						local p = middle:PointToObjectSpace(at)
						known = Press.inside(p.X, p.Z, half.X, half.Z)
					end
					inHome[folder] = known
				end
				here = known == true
			end
			local shown = here and seat.Occupant == nil
			if h.prompt.Enabled ~= shown then
				h.prompt.Enabled = shown
			end
		end
	end

	local function added(inst: Instance)
		if not inst:IsA("Model") or not inst:IsDescendantOf(Workspace) then
			return
		end
		local model = inst
		for _, d in model:GetDescendants() do
			if not d:IsA("Seat") or held[d] then
				continue
			end
			local kind, index =
				d:GetAttribute(Sit.KindAttribute), d:GetAttribute(Sit.IndexAttribute)
			local row = if type(kind) == "string" and type(index) == "number"
				then Sit.row(kind, index)
				else nil
			local at = d:FindFirstChild(Sit.Name)
			local prompt = if at then at:FindFirstChildOfClass("ProximityPrompt") else nil
			if not (row and prompt) then
				continue
			end
			local seat = d
			local h: Held
			h = {
				seat = seat,
				model = model,
				prompt = prompt,
				row = row,
				sat = nil,
				changed = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
					occupied(h)
				end),
			}
			held[seat] = h
			if seat.Occupant then
				occupied(h) -- someone already sat as this screen arrives: pose them, quietly or not
			end
		end
	end

	local function removed(inst: Instance)
		if not inst:IsA("Model") then
			return
		end
		for seat, h in held do
			if h.model == inst then
				h.changed:Disconnect()
				held[seat] = nil
			end
		end
	end

	-- Before physics: bodies on floor seats cross their legs (eased in), and where you stand is
	-- noted for your next landing.
	local function step(dt: number)
		local character = me.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if humanoid then humanoid.RootPart else nil
		if humanoid and root and humanoid.SeatPart == nil then
			stood = root.Position
		end
		for body, b in bodies do
			if not body.Parent then
				bodies[body] = nil
				continue
			end
			b.level = math.min(1, b.level + dt / Sit.Ease)
			local w = 1 - (1 - b.level) * (1 - b.level) -- eased out
			for j, to in b.joints do
				local now = Joints.get(j)
				-- a joint no animation drives still holds this screen's last turn: start from rest
				local from = if now == b.written[j] then CFrame.identity else now
				local set = from:Lerp(to, w)
				Joints.set(j, set)
				b.written[j] = set
			end
		end
	end

	local system = { name = "HomeSitView" }

	function system.start(_: any, _context: Brix.Context)
		task.spawn(SoundPrimer.prime, { Sit.Sounds.Wood.id, Sit.Sounds.Cushion.id })
		for _, inst in CollectionService:GetTagged(Spots.Tag) do
			added(inst)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Spots.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Spots.Tag):Connect(removed)
		)
		table.insert(connections, RunService.PreSimulation:Connect(step))
		table.insert(
			connections,
			RunService.Heartbeat:Connect(function(dt: number)
				since += dt
				if since >= LOOK then
					since = 0
					look()
				end
			end)
		)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, h in held do
			h.changed:Disconnect()
		end
		table.clear(held)
		table.clear(bodies)
	end

	return system
end

return HomeSitView
