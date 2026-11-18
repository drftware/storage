--!strict
--[[
	HeadlampView: the hard hat's own beam on this screen (F-G1b4a2, D-420), as Phasmophobia's head
	torch is. The moment: you pull the hat on and the hall ahead snaps into a hard white cone that
	follows your eyes, your hands free for the jukebox or a tool.

	Yours leaves your brow (`Headlamp.EyeUp`, just ahead of your face) and points wherever your
	camera looks, up and down too, nodding with your stride (`Torch.step`, fed no turns so it never
	lags) and swinging up from your feet into place as the hat goes on (`Headlamp.swing`), from the
	moment its bulb lights. With your view away from your head (the RC car you drive), it leaves
	the lamp along your head instead. Friends' leave the lamp on their brow along their aim (their
	torch's `Aim`, which their screen sends while they wear the hat), and their hat drops onto
	their head with a little settle (its weld eased on this screen alone). These beams replace the
	hat's warm art light while it's worn (FindUseView leaves a worn find's lights out); its bulb
	still glows on the brow. Only yours and the nearest two friends' are real lights
	(`Headlamp.budget`), from a pool made once.

	Its minute running down (F-G1b4b, D-421): for its last seconds the beam stutters and sags as a
	dying torch does, the filament's buzz heard in the stutters (`Headlamp.light`), and a friend's
	bulb dims with their beam; then the bulb's own run-down (the art's `RunDown`) carries the beam
	out with it. Spent, the server takes it off the head and breaks it, and the beam is simply gone.

	Studio only: `workspace:SetAttribute("HeadlampTest", "friend")` draws your own hat as a friend
	sees it (its beam from the lamp along your aim, the settle as it goes on), for one-player Play.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Art = require(ReplicatedStorage.Shared.Finds.Art)
local Brix = require(ReplicatedStorage.Brix)
local Charge = require(ReplicatedStorage.Shared.Flashlight.Charge)
local Finds = require(ReplicatedStorage.Shared.Finds)
local HandRoom = require(script.Parent.HandRoom)
local Head = require(ReplicatedStorage.Shared.Finds.Head)
local Headlamp = require(ReplicatedStorage.Shared.Finds.Headlamp)
local Torch = require(ReplicatedStorage.Shared.Flashlight.Torch)
local Use = require(ReplicatedStorage.Shared.Finds.Use)

-- after the camera, its shake and HeadView (Camera + 2), so your beam leaves where you see from
local STEP = "HeadlampOwnBeam"
local PRIORITY = Enum.RenderPriority.Camera.Value + 3
local TEST = "HeadlampTest"
local BUDGET_EVERY = 0.25 -- seconds between choosing which friends' headlamps are real
local RAD = math.pi / 180
local COLOR = Color3.fromRGB(Headlamp.Color[1], Headlamp.Color[2], Headlamp.Color[3])

type Rig = { part: BasePart, at: Attachment, spot: SpotLight, spill: PointLight?, buzz: Sound }

-- A worn hat on a friend's head, as this screen draws it.
type Worn = {
	model: Model,
	owner: Player,
	character: Model,
	lamp: Attachment?, -- the art's spot's attachment: where the lens is
	weld: Weld?,
	base: CFrame, -- the weld's seat, as the server set it
	settleAt: number?, -- os.clock() it appeared, while it settles
	k: number, -- their head's size against a standard one
	pitch: number, -- their aim on this screen, eased, degrees
	flicker: Charge.Flicker, -- its run-down's stutter on this screen
	level: number, -- its light this frame (0 to 1), as it runs down
	stuttering: boolean,
	look: SurfaceAppearance?, -- its bulb's, dimmed with its beam as it stutters
}

-- The filament fighting, looped quietly at a lamp (the torch's buzz, `Charge.Buzz`); heard only
-- while it stutters.
local function buzzSound(parent: Instance): Sound
	local s = Instance.new("Sound")
	s.Name = "HeadlampBuzz"
	s.SoundId = Charge.Buzz.id
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(Charge.Buzz.from, Charge.Buzz.from + Charge.Buzz.length)
	s.LoopRegion = s.PlaybackRegion
	s.Looped = true
	s.Volume = 0
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = Charge.BuzzNear
	s.RollOffMaxDistance = Charge.BuzzReach
	s.Parent = parent
	return s
end

-- A lamp's buzz this frame: loudest in a stutter's dips, retuned each blink so it crackles,
-- silent while it burns steady, stopped once it's out.
local function drive(s: Sound, stuttering: boolean, level: number, f: Charge.Flicker)
	if not stuttering then
		if s.IsPlaying then
			s:Stop()
		end
		return
	end
	if not s.IsPlaying then
		s.TimePosition = Charge.Buzz.from
		s:Play()
	end
	local v = Charge.BuzzVolume * (1 - 0.5 * level)
	if math.abs(s.Volume - v) > 0.02 then
		s.Volume = v
	end
	local pitch = Charge.buzzPitch(f)
	if s.PlaybackSpeed ~= pitch then
		s.PlaybackSpeed = pitch
	end
end

local HeadlampView = {}

function HeadlampView.new(): Brix.System
	local player = Players.LocalPlayer
	local studio = RunService:IsStudio()
	local connections: { RBXScriptConnection } = {}
	local folder: Folder? = nil
	local mine: Rig? = nil
	local pool: { Rig } = {}
	local sway, pose = Torch.sway(), Torch.pose()
	local wornWas: Model? = nil
	local appeared = 0 -- server time your hat last came onto your head
	local friends: { [Model]: Worn } = {}
	local order: { Worn } = {}
	local distances: { number } = {}
	local real: { boolean } = {}
	local bare: { [Model]: boolean } = {} -- characters seen with nothing on their head last step
	local bareNow: { [Model]: boolean } = {}
	local budgetIn = 0
	local durations: { [string]: { [string]: number } } = {}
	local bulbs: { [string]: { Art.Key }? } = {} -- each worn find's bulb's run-down keys
	local flicker = Charge.flicker(player.UserId + 1) -- your own hat's run-down

	local function testing(): boolean
		return studio and Workspace:GetAttribute(TEST) == "friend"
	end

	local function makeRig(spill: boolean): Rig
		local part = Instance.new("Part")
		part.Name = "Headlamp"
		part.Anchored = true
		part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.one * 0.2
		local at = Instance.new("Attachment")
		at.Parent = part
		local spot = Instance.new("SpotLight")
		spot.Angle, spot.Range, spot.Color = Headlamp.Angle, Headlamp.Range, COLOR
		spot.Brightness, spot.Shadows, spot.Enabled = 0, true, false
		spot.Parent = at
		local buzz = buzzSound(part)
		local p: PointLight? = nil
		if spill then
			local s = Instance.new("PointLight")
			s.Range, s.Color, s.Shadows, s.Enabled = Headlamp.SpillRange, COLOR, false, false
			s.Parent = at
			p = s
		end
		part.Parent = folder
		return { part = part, at = at, spot = spot, spill = p, buzz = buzz }
	end

	local function shine(r: Rig, light: number)
		local on = light > 0.001
		r.spot.Brightness = Headlamp.Brightness * light
		if r.spot.Enabled ~= on then
			r.spot.Enabled = on
		end
		local s = r.spill
		if s then
			s.Brightness = Headlamp.SpillBrightness * light
			if s.Enabled ~= on then
				s.Enabled = on
			end
		end
	end

	-- The bulb's glow keys in `key`'s run-down (`Headlamp.RunDown`), or nil if it has none.
	local function bulbKeys(key: string): { Art.Key }?
		if bulbs[key] ~= nil then
			return bulbs[key]
		end
		local find = Finds.art(key)
		local m = if find then find.Motions[Headlamp.RunDown] else nil
		local keys: { Art.Key }? = nil
		if m then
			for _, track in m.Tracks do
				if track.Part == Headlamp.Bulb and track.Channel == "glow" then
					keys = track.Keys
				end
			end
		end
		bulbs[key] = keys
		return keys
	end

	--[[
		Whether `model` (the find `key` on a head) is giving light now, its press's server time,
		the seconds of its minute left (0 or under once it's out) and, in its run-down, its bulb's
		glow (0 to 1); not lit once spent.
	]]
	local function litOf(model: Model, key: unknown): (boolean, number, number, number?)
		local row = if type(key) == "string" then Use.Rows[key] else nil
		local s = Use.read(
			model:GetAttribute(Use.StateAttribute),
			model:GetAttribute(Use.AtAttribute),
			model:GetAttribute(Use.LeftAttribute),
			model:GetAttribute(Use.CountAttribute)
		)
		if not (row and s and type(key) == "string") then
			return false, 0, 0, nil
		end
		local d = durations[key]
		if not d then
			d = Finds.durations(key)
			durations[key] = d
		end
		local played = Use.played(row, Workspace:GetServerTimeNow() - s.at, nil)
		local f = Use.frame(row, s, played, d)
		if f.spent then
			return false, s.at, 0, nil
		elseif f.lit then
			return true, s.at, s.left - played, nil
		elseif f.motion == Headlamp.RunDown then
			local keys = bulbKeys(key)
			return true, s.at, 0, if keys then Art.sample(keys, f.t) else 0
		end
		return false, s.at, 0, nil
	end

	local function lampOf(model: Model): Attachment?
		for _, d in model:GetDescendants() do
			local parent = d.Parent
			if d:IsA("SpotLight") and parent and parent:IsA("Attachment") then
				return parent
			end
		end
		return nil
	end

	local function wornOn(character: Model, owner: Player): Model?
		local found = character:FindFirstChild(Head.ModelName)
		return if found
				and found:IsA("Model")
				and found:GetAttribute(Head.WornAttribute) == owner.UserId
			then found
			else nil
	end

	-- Each frame after the camera: your beam from your brow along your look.
	local function own(dt: number)
		local r = mine
		local camera = Workspace.CurrentCamera
		local character = player.Character
		local model = if character then wornOn(character, player) else nil
		local now = Workspace:GetServerTimeNow()
		if model ~= wornWas then
			wornWas = model
			appeared = now
		end
		if not (r and camera and character and model) or testing() then
			if r then
				shine(r, 0)
				drive(r.buzz, false, 0, flicker)
			end
			return
		end
		local lit, at, left, bulb = litOf(model, player:GetAttribute(Head.Attribute))
		if not lit then
			shine(r, 0)
			drive(r.buzz, false, 0, flicker)
			return
		end
		local level, stuttering = Headlamp.light(flicker, left, dt, bulb)
		drive(r.buzz, stuttering, level, flicker)
		local down, light = Headlamp.swing(now - math.max(at + Headlamp.LightAt, appeared))
		light *= level
		local speed = 0
		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if
			root
			and root:IsA("BasePart")
			and humanoid
			and humanoid.FloorMaterial ~= Enum.Material.Air
		then
			local v = root.AssemblyLinearVelocity
			speed = Vector3.new(v.X, 0, v.Z).Magnitude
		end
		local p = Torch.step(sway, dt, speed, 0, 0, pose)
		local nod, weave = Headlamp.bob(p)
		local turn = CFrame.Angles(nod - down * RAD, weave, 0)
		local cam = camera.CFrame
		local head = character:FindFirstChild("Head")
		if
			head
			and head:IsA("BasePart")
			and (cam.Position - head.Position).Magnitude > Head.HideFar
		then
			-- your view is away from your head: the lamp lights along your head, as a friend sees
			local lamp = lampOf(model)
			local from = if lamp then lamp.WorldPosition else head.Position
			r.at.WorldCFrame = CFrame.new(from) * head.CFrame.Rotation * turn
		else
			local want = (cam * CFrame.new(0, Headlamp.EyeUp, -Headlamp.EyeAhead)).Position
			r.at.WorldCFrame = CFrame.new(HandRoom.clear(cam.Position, want)) * cam.Rotation * turn
		end
		shine(r, light)
	end

	local function add(model: Model, owner: Player, character: Model, settle: boolean): Worn
		local head = character:FindFirstChild("Head")
		local found = model:FindFirstChild(Head.WeldName, true)
		local weld = if found and found:IsA("Weld") then found else nil
		local w: Worn = {
			model = model,
			owner = owner,
			character = character,
			lamp = lampOf(model),
			weld = weld,
			base = if weld then weld.C0 else CFrame.identity,
			settleAt = if settle and weld then os.clock() else nil,
			k = if head and head:IsA("BasePart") then head.Size.Y / Head.Standard else 1,
			pitch = 0,
			flicker = Charge.flicker(owner.UserId + 2),
			level = 1,
			stuttering = false,
			look = nil,
		}
		local bulb = model:FindFirstChild(Headlamp.Bulb, true)
		w.look = if bulb then bulb:FindFirstChildOfClass("SurfaceAppearance") else nil
		friends[model] = w
		if weld and w.settleAt then
			-- lifted at once, so it's never drawn on its seat for a frame before it drops
			local up, tilt = Headlamp.settle(0, w.k)
			weld.C0 = w.base * CFrame.new(0, up, 0) * CFrame.Angles(tilt * RAD, 0, 0)
		end
		return w
	end

	local function seat(w: Worn)
		local weld = w.weld
		if weld and w.settleAt and weld.Parent then
			weld.C0 = w.base
		end
		w.settleAt = nil
	end

	-- Friends' hats: found, settled as they go on, and the nearest few lit for real.
	local function drawFriends(dt: number)
		table.clear(order)
		table.clear(bareNow)
		local test = testing()
		for _, other in Players:GetPlayers() do
			local character = other.Character
			if character and (other ~= player or test) then
				local model = wornOn(character, other)
				if not model then
					bareNow[character] = true
				else
					local w = friends[model]
					if not w or w.character ~= character then
						-- dropped onto a head this screen saw bare: it settles; else it's just there
						w = add(model, other, character, bare[character] == true)
					end
					table.insert(order, w)
				end
			end
		end
		bare, bareNow = bareNow, bare
		for model, w in friends do
			if model.Parent ~= w.character or (w.owner == player and not test) then
				seat(w)
				friends[model] = nil
			end
		end
		-- each one's light as it runs down; its bulb dimmed with it while it stutters through its
		-- minute (in the bulb's own run-down, FindUseView plays the bulb and the beam follows)
		for _, w in order do
			local key = w.owner:GetAttribute(Head.Attribute)
			local lit, _, left, bulb = litOf(w.model, key)
			if lit then
				w.level, w.stuttering = Headlamp.light(w.flicker, left, dt, bulb)
			else
				w.level, w.stuttering = 0, false
			end
			local look = w.look
			local find = if type(key) == "string" then Finds.art(key) else nil
			local glow = if find then find.Glow else nil
			-- only in its last stretch: before it, FindUseView's own pull-on lights the bulb
			if look and glow and lit and left > 0 and left <= Headlamp.Shape.flicker then
				local want = glow.Strength * w.level
				if math.abs(look.EmissiveStrength - want) > 0.05 then
					look.EmissiveStrength = want
				end
			end
		end
		local camera = Workspace.CurrentCamera
		budgetIn -= dt
		if budgetIn <= 0 and camera then
			budgetIn = BUDGET_EVERY
			table.clear(distances)
			local eye = camera.CFrame.Position
			for i, w in order do
				local lit = w.level > 0 or w.stuttering -- a dip to black is still lit
				distances[i] = if lit
					then (w.model:GetPivot().Position - eye).Magnitude
					else math.huge
			end
			Headlamp.budget(distances, real)
		end
		local used = 0
		for i, w in order do
			local torch = w.character:FindFirstChild(Torch.ModelName)
			local aim = if torch then torch:GetAttribute(Torch.AimAttribute) else nil
			local target = if type(aim) == "number" then aim else 0
			w.pitch = target + (w.pitch - target) * math.exp(-Torch.AimFollow * dt)
			local lamp = w.lamp
			local root = w.character:FindFirstChild("HumanoidRootPart")
			if real[i] and lamp and root and root:IsA("BasePart") and used < #pool then
				if w.level > 0 or w.stuttering then
					used += 1
					local _, yaw = root.CFrame:ToOrientation()
					local r = pool[used]
					r.at.WorldCFrame = CFrame.new(lamp.WorldPosition)
						* CFrame.fromEulerAnglesYXZ(w.pitch * RAD, yaw, 0)
					shine(r, w.level)
					drive(r.buzz, w.stuttering, w.level, w.flicker)
				end
			end
		end
		for j = used + 1, #pool do
			shine(pool[j], 0)
			drive(pool[j].buzz, false, 0, flicker)
		end
	end

	-- Before physics: a hat just dropped onto a friend's head falls, hops and rocks level.
	local function settle()
		for _, w in friends do
			local weld, at = w.weld, w.settleAt
			if weld and at then
				local up, tilt, done = Headlamp.settle(os.clock() - at, w.k)
				if done then
					seat(w)
				elseif weld.Parent then
					weld.C0 = w.base * CFrame.new(0, up, 0) * CFrame.Angles(tilt * RAD, 0, 0)
				end
			end
		end
	end

	local system = { name = "HeadlampView" }

	function system.start(_: any, _context: Brix.Context)
		-- a folder of this screen's own: a light under the camera draws nothing
		local f = Instance.new("Folder")
		f.Name = "Headlamps"
		f.Parent = Workspace
		folder = f
		mine = makeRig(true)
		for _ = 1, Headlamp.RealBeams - 1 do
			table.insert(pool, makeRig(false))
		end
		RunService:BindToRenderStep(STEP, PRIORITY, own)
		table.insert(connections, RunService.PreSimulation:Connect(settle))
	end

	function system.step(_: any, dt: number)
		drawFriends(dt)
	end

	function system.stop(_: any)
		RunService:UnbindFromRenderStep(STEP)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, w in friends do
			seat(w)
		end
		table.clear(friends)
		table.clear(order)
		table.clear(pool)
		mine = nil
		if folder then
			folder:Destroy()
			folder = nil
		end
	end

	return system :: any -- any: a plain Brix system built field by field
end

return HeadlampView
