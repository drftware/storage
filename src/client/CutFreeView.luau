--!strict
--[[
	CutFreeView: a friend cutting someone free (L-07d), on every screen near. The moment: a friend
	in your doorway grabs the film and pulls; it strains round you for a second, then rips. Film
	shreds burst out toward them, the wrap sags down your body to a heap round your ankles,
	crunches as it lands, lies a moment and fades. Your view jolts and opens up as you're let go;
	theirs jolts too, a yank on the film they were pulling.

	All of it comes from the wrap the server put on (`Kept.WrapTag`) and its attributes, so
	nothing extra goes over the network and a screen that streams the wrap in late joins the beat
	where it is: while friends hold Cut free on it (`Kept.PullAttribute`) its strain plays there
	(`Kept.Pull`, swelling over the hold); once torn (`Kept.TornAttribute`, the server's clock) it
	plays the rip (`Kept.Rip`), the shreds and the slump (`Kept.tearPose`), the heap's crunch
	(`Kept.Heap`) as it lands, and the kicks for whoever it freed and whoever cut
	(`Kept.FreedAttribute`, `CutterAttribute`). The server took the wrap off the body and left it
	anchored where they stood, so every change here is this screen's own; it's gone from the
	server once the beat has played.

	It steps only while a strain or a tear is playing.
]]
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Kept = require(ReplicatedStorage.Shared.Kept)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tools = require(ReplicatedStorage.Shared.Tools)

-- Seconds late a screen may see a tear and still play its rip: past that it only shows the film.
local LATE = 0.3
-- Seconds the strain takes to die as a friend lets go.
local PULL_OUT = 0.08

-- The shreds: scraps of the film's own texture flung from the tear toward the door.
local SHRED_SIZE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.36, 0.12),
	NumberSequenceKeypoint.new(1, 0.2, 0.06),
})
-- stretched every which way: torn strips of film, not squares
local SHRED_SQUASH = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.2, 1.2),
	NumberSequenceKeypoint.new(1, 0.5, 1),
})
local SHRED_SEE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.15),
	NumberSequenceKeypoint.new(0.6, 0.35),
	NumberSequenceKeypoint.new(1, 1),
})

-- A strain playing on a wrap: its sound, how long it has played, and whether it's dying.
type Pull = { sound: Sound, t: number, out: number? }

-- A tear playing: the wrap, seconds since it tore, its size whole, its foot (on the floor,
-- upright, facing as it stood), which way round it lists, and whether the heap's crunch played.
type Tear = {
	wrap: BasePart,
	t: number,
	size: Vector3,
	foot: CFrame,
	lean: number,
	landed: boolean,
	quiet: boolean, -- seen too late for its sounds
}

local CutFreeView = {}

-- The system; `kick` jerks this player's view (CameraShake's).
function CutFreeView.new(kick: (amount: number) -> ()): Brix.System
	local player = Players.LocalPlayer
	local watched: { [BasePart]: { RBXScriptConnection } } = {}
	local pulls: { [BasePart]: Pull } = {}
	local tears: { [BasePart]: Tear } = {}
	local connections: { RBXScriptConnection } = {}
	local shredTexture: string? = nil
	local widen = -1 -- seconds since our view started opening, or -1
	local widenBase = 0 -- the view's field before it opened
	local widenSet = 0 -- the field we last set, so we never fight anything else that moves it

	-- The film's own colour map, for its shreds: read off the template, so a re-upload (new ids)
	-- carries over. A game script can't read `ColorMap` itself (it needs the Plugin capability),
	-- but can its `ColorMapContent` (docs/STUDIO.md). Nil when it can't be read: no shreds then.
	local function findTexture(): string?
		local props = ReplicatedStorage:FindFirstChild("Props")
		local template = props and props:FindFirstChild(Kept.Wrap)
		local look = template and template:FindFirstChildWhichIsA("SurfaceAppearance")
		if not look then
			return nil
		end
		local ok, id = pcall(function(): string?
			return (look :: SurfaceAppearance).ColorMapContent.Uri
		end)
		return if ok and id and id ~= "" then id else nil
	end

	local function stopPull(wrap: BasePart, now: boolean)
		local p = pulls[wrap]
		if not p then
			return
		end
		if now then
			p.sound:Destroy()
			pulls[wrap] = nil
		elseif not p.out then
			p.out = 0
		end
	end

	local function onPull(wrap: BasePart)
		local n = wrap:GetAttribute(Kept.PullAttribute)
		local holding = type(n) == "number" and n > 0
		if holding and not pulls[wrap] and wrap:GetAttribute(Kept.TornAttribute) == nil then
			local sound = Tools.sound(Kept.Pull, wrap, Kept.PullReach)
			sound.Volume = Kept.Pull.volume * Kept.pull(0)
			sound.TimePosition = Kept.Pull.from
			sound:Play()
			pulls[wrap] = { sound = sound, t = 0 }
		elseif not holding then
			stopPull(wrap, false)
		end
	end

	-- A burst of film shreds from the tear, out toward the door.
	local function shred(wrap: BasePart)
		-- looked up at the first tear: at this screen's start the template may not be in yet
		local texture = shredTexture or findTexture()
		shredTexture = texture
		if not texture then
			return
		end
		local at = Instance.new("Attachment")
		at.Name = "Shreds"
		at.CFrame = CFrame.new(0, Kept.CutUp, -wrap.Size.Z * 0.3)
		at.Parent = wrap
		local e = Instance.new("ParticleEmitter")
		e.Texture = texture
		-- the film's own near-white, in its wrap colour (S3-04a): the tint the server gave it
		local look = wrap:FindFirstChildWhichIsA("SurfaceAppearance")
		local tint = if look then look.Color else Color3.new(1, 1, 1)
		e.Color = ColorSequence.new(Color3.new(0.925 * tint.R, 0.941 * tint.G, 0.957 * tint.B))
		e.LightEmission = 0.15
		e.LightInfluence = 0.85
		e.Size = SHRED_SIZE
		e.Squash = SHRED_SQUASH
		e.Transparency = SHRED_SEE
		e.Lifetime = NumberRange.new(0.5, 0.9)
		e.Speed = NumberRange.new(5, 11)
		e.SpreadAngle = Vector2.new(55, 35)
		e.EmissionDirection = Enum.NormalId.Front
		e.Acceleration = Vector3.new(0, -28, 0)
		e.Drag = 3.5
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-420, 420)
		e.Rate = 0
		e.Enabled = false
		e.Parent = at
		e:Emit(Kept.Shreds)
	end

	-- Plays `s` once at `place` (a world point), cleaning up after.
	local function playAt(s: typeof(Kept.Rip), place: Vector3, reach: number)
		local at = Instance.new("Attachment")
		at.Name = "CutFree"
		at.WorldPosition = place
		at.Parent = Workspace.Terrain
		Tools.play(s, at, reach)
		task.delay(s.length / (s.pitch or 1) + 1, function()
			at:Destroy()
		end)
	end

	local function onTorn(wrap: BasePart)
		local torn = wrap:GetAttribute(Kept.TornAttribute)
		if tears[wrap] or type(torn) ~= "number" then
			return
		end
		stopPull(wrap, true)
		local since = math.max(Workspace:GetServerTimeNow() - torn, 0)
		if since >= Kept.tearLength() then
			return -- long over: the server is about to take it away
		end
		local lean = wrap:GetAttribute(Kept.LeanAttribute)
		local quiet = since > LATE
		tears[wrap] = {
			wrap = wrap,
			t = since,
			size = wrap.Size,
			foot = wrap.CFrame * CFrame.new(0, -wrap.Size.Y / 2, 0),
			lean = if type(lean) == "number" then lean else 0,
			landed = quiet,
			quiet = quiet,
		}
		wrap.LocalTransparencyModifier = 0 -- the freed player's own screen hid it while they were kept
		if quiet then
			return
		end
		playAt(Kept.Rip, wrap.Position, Kept.RipReach)
		shred(wrap)
		local me = player.UserId
		if wrap:GetAttribute(Kept.FreedAttribute) == me then
			kick(Kept.FreedKick)
			local camera = Workspace.CurrentCamera
			if camera and widen < 0 then
				widen, widenBase, widenSet = 0, camera.FieldOfView, camera.FieldOfView
			end
		elseif wrap:GetAttribute(Kept.CutterAttribute) == me then
			kick(Kept.CutterKick)
		end
	end

	local function unwatch(wrap: BasePart)
		local conns = watched[wrap]
		if conns then
			for _, c in conns do
				c:Disconnect()
			end
			watched[wrap] = nil
		end
		stopPull(wrap, true)
		tears[wrap] = nil
	end

	local function watch(inst: Instance)
		if not inst:IsA("BasePart") or watched[inst] then
			return
		end
		local wrap = inst
		watched[wrap] = {
			wrap:GetAttributeChangedSignal(Kept.PullAttribute):Connect(function()
				onPull(wrap)
			end),
			wrap:GetAttributeChangedSignal(Kept.TornAttribute):Connect(function()
				onTorn(wrap)
			end),
			wrap.Destroying:Connect(function()
				unwatch(wrap)
			end),
		}
		onPull(wrap)
		onTorn(wrap)
	end

	local function stepWiden(dt: number)
		local camera = Workspace.CurrentCamera
		-- (the field is stored as a 32-bit float, so it reads back a hair off what was set)
		if not camera or math.abs(camera.FieldOfView - widenSet) > 0.01 then
			widen = -1 -- something else moved the view's field: leave it be
			return
		end
		widen += dt
		local open = Kept.widen(widen)
		widenSet = if open > 0 then widenBase + Kept.FreedWiden * open else widenBase
		camera.FieldOfView = widenSet
		if open <= 0 and widen > Kept.WidenIn then
			widen = -1
		end
	end

	return {
		name = "CutFreeView",
		start = function(_: any, _context: Brix.Context)
			task.spawn(SoundPrimer.prime, { Kept.Rip.id, Kept.Heap.id, Kept.Pull.id })
			-- the shreds' texture, loaded now so the first tear's aren't late: a colour map's
			-- first use as an image makes Roblox build one (Output says "being generated")
			task.spawn(function()
				local props = ReplicatedStorage:WaitForChild("Props", 30)
				if props then
					props:WaitForChild(Kept.Wrap, 30)
				end
				local texture = findTexture()
				shredTexture = texture
				if texture then
					local decal = Instance.new("Decal")
					decal.Texture = texture
					pcall(function()
						ContentProvider:PreloadAsync({ decal })
					end)
					decal:Destroy()
				end
			end)
			for _, inst in CollectionService:GetTagged(Kept.WrapTag) do
				watch(inst)
			end
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Kept.WrapTag):Connect(watch)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Kept.WrapTag)
					:Connect(function(inst: Instance)
						if inst:IsA("BasePart") then
							unwatch(inst)
						end
					end)
			)
		end,
		step = function(_: any, dt: number)
			for wrap, p in pulls do
				p.t += dt
				local out = p.out
				if out then
					out += dt
					p.out = out
					p.sound.Volume = Kept.Pull.volume
						* Kept.pull(p.t)
						* math.max(1 - out / PULL_OUT, 0)
					if out >= PULL_OUT then
						stopPull(wrap, true)
					end
				elseif p.t > Kept.Pull.length / Kept.Pull.pitch then
					stopPull(wrap, true) -- a hold the server never heard end
				else
					p.sound.Volume = Kept.Pull.volume * Kept.pull(p.t)
				end
			end
			for wrap, tear in tears do
				tear.t += dt
				if not wrap.Parent or tear.t >= Kept.tearLength() then
					tears[wrap] = nil
					wrap.LocalTransparencyModifier = 0
					wrap.Transparency = 1
					continue
				end
				local pose = Kept.tearPose(tear.t)
				local size = Vector3.new(
					tear.size.X * pose.wide,
					tear.size.Y * pose.squash,
					tear.size.Z * pose.deep
				)
				local tilt = math.rad(Kept.Tear.tilt) * pose.lean
				-- it lists toward the door (its front), turned `lean` round from straight on
				local list = CFrame.Angles(0, tear.lean, 0)
					* CFrame.Angles(-tilt, 0, 0)
					* CFrame.Angles(0, -tear.lean, 0)
				wrap.Size = size
				wrap.CFrame = tear.foot * list * CFrame.new(0, size.Y / 2, 0)
				wrap.Transparency = pose.see
				wrap.LocalTransparencyModifier = 0
				if not tear.landed and tear.t >= Kept.Tear.yank + Kept.Tear.fall then
					tear.landed = true
					playAt(Kept.Heap, tear.foot.Position, Kept.HeapReach)
				end
			end
			if widen >= 0 then
				stepWiden(dt)
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for wrap in watched do
				unwatch(wrap)
			end
			local camera = Workspace.CurrentCamera
			if widen >= 0 and camera and math.abs(camera.FieldOfView - widenSet) <= 0.01 then
				camera.FieldOfView = widenBase
			end
			widen = -1
		end,
	}
end

return CutFreeView
