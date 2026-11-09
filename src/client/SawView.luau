--!strict
--[[
	SawView: a crawl hole being sawn, on every screen (L-12b2). While a wall carries the server's
	`Sawing.Tag`, the saw's motor whines and its blade chatters at the cut, heard across the floor,
	and a bright line of hot steel crawls round the hole as the hold goes on, sparks flying off the
	blade on the sawer's side. Your own saw buzzes your view while it runs. Let go and the motor
	winds down and the line cools away; go through and the cut-out panel tips over on the far side
	and slaps flat on the concrete with a clang that jolts everyone near it.

	A unit's top is sawn the same way (L-13b2d2b): the line laid flat round its hole on the steel's
	face, the sparks fountaining up off the top. Through, the cut-out panel hangs a beat in the hole, drops ten studs into the unit and
	lands on the concrete with a heavy clang the whole floor hears.

	Only cuts being sawn and panels falling are stepped (one or two at a time), and a cut's five
	parts are made once and moved, not remade, each frame.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CrawlHole = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole)
local Sawing = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Sawing)
local Shake = require(ReplicatedStorage.Shared.Shake)
local SoundPrimer = require(script.Parent.SoundPrimer)
local TopHole = require(ReplicatedStorage.Shared.StorageUnit.TopHole)

-- The bright line: steel cut by a saw glows only where the blade just was, so the line is hot
-- orange-white, thin, and proud of both faces of the wall so a friend on the far side sees it.
local LINE_COLOUR = Color3.fromRGB(255, 142, 52)
local HEAD_COLOUR = Color3.fromRGB(255, 226, 160) -- the blade's spot: hottest
local LINE_THICK = 0.11 -- studs across: about 3 pixels on a phone from where you stand
local LINE_DEPTH = 0.36 -- through the wall: its sheet and ribs, a hair proud each side
local LINE_X = -0.05 -- the line's middle, in the kit's X: the wall's box's middle
local HEAD_SIZE = 0.2
local JITTER = 0.035 -- studs the blade's spot shakes along the cut: the stroke
local COOL_SECONDS = 0.6 -- the line fading after the motor stops
local COOL = TweenInfo.new(COOL_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- Sparks off the blade, on the sawer's side only: few, short, falling.
local SPARK_RATE = 70
local SPARK_SPEED = NumberRange.new(5, 11)
local SPARK_LIFE = NumberRange.new(0.12, 0.3)
local SPARK_SIZE = NumberSequence.new(0.14, 0)
local SPARK_SPREAD = Vector2.new(40, 40)
local SPARK_FALL = Vector3.new(0, -40, 0)
-- The panel's fall: tipping over from the hole onto the floor, faster as it goes, then a small
-- bounce as it slaps down.
local FALL_SECONDS = 0.32
local BOUNCE_SECONDS = 0.18
local BOUNCE = 0.05 -- of its fall's angle, back up on the bounce
local FRESH = 1.5 -- seconds after a cut a panel still falls on a screen that just got it
-- A top's line: lying by it you look almost along the steel, so a line through it (as a wall's)
-- shows its depth as a thick glowing band (Studio). It's a thin line on the ribs' top face instead,
-- about as thick seen from lying there as a wall's is seen standing.
local TOP_DEPTH = 0.08 -- studs tall
local TOP_LINE_X = TopHole.Rect.top + 0.02 - TOP_DEPTH / 2 - TopHole.SteelMiddle -- in the cut frame
local TOP_RECT =
	Sawing.flat(TopHole.Rect.left, TopHole.Rect.right, TopHole.Rect.front, TopHole.Rect.back)
-- A top's panel: it hangs a beat in the hole as the last of the cut lets go, falls at the game's
-- gravity (ten studs, about a third of a second), and hops a little as it slaps down.
local TOP_HANG = 0.1
local TOP_HOP = 0.12 -- studs it bounces back up
local TOP_HOP_SECONDS = 0.16

type Cut = {
	wall: BasePart, -- the wall or the top being sawn
	frame: CFrame, -- the cut's frame on it (Sawing.FrameAttribute)
	rect: Sawing.Hole, -- the hole in that frame
	lineX: number, -- the line's middle through the steel, in the frame's X
	depth: number, -- and how far through it reaches
	start: number,
	mine: boolean, -- sawn by this screen's player
	folder: Folder,
	edges: { Part },
	head: BasePart,
	sparks: ParticleEmitter,
	sounds: { Sound },
	drawn: { number },
}
type Fall = {
	panel: BasePart,
	hinge: CFrame,
	rest: CFrame,
	angle: number,
	at: number,
	landed: boolean,
}
-- A top's panel (a Model: the panel and its rim) dropping from the hole to where it lies.
type Drop = {
	model: Model,
	from: CFrame, -- its pivot in the hole, before it fell
	rest: CFrame, -- and where it lies
	seconds: number, -- the fall, at the game's gravity
	at: number,
	landed: boolean,
}

local SawView = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function bright(name: string, colour: Color3, size: Vector3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = colour
	p.Size = size
	p.Transparency = 1
	p.Parent = parent
	return p
end

local function sound(s: Sawing.Sound, parent: Instance): Sound
	local snd = Instance.new("Sound")
	snd.SoundId = s.id
	snd.Volume = s.volume
	snd.PlaybackSpeed = s.pitch
	snd.RollOffMode = Enum.RollOffMode.InverseTapered
	snd.RollOffMinDistance = s.near
	snd.RollOffMaxDistance = s.reach
	snd.PlaybackRegionsEnabled = true
	local stop = s.loopTo or (s.from + (s.length or 1))
	snd.PlaybackRegion = NumberRange.new(s.from, stop)
	if s.loopFrom and s.loopTo then
		snd.LoopRegion = NumberRange.new(s.loopFrom, s.loopTo)
		snd.Looped = true
	end
	snd.Parent = parent
	return snd
end

function SawView.new(kick: (amount: number) -> ()): Brix.System
	local cuts: { [BasePart]: Cut } = {}
	local falls: { [BasePart]: Fall } = {}
	local drops: { [Model]: Drop } = {}
	local connections: { RBXScriptConnection } = {}
	local player = Players.LocalPlayer

	local function begin(inst: Instance)
		if not inst:IsA("BasePart") or cuts[inst] then
			return
		end
		local wall = inst
		local frame = wall:GetAttribute(Sawing.FrameAttribute)
		local start = wall:GetAttribute(Sawing.StartAttribute)
		local from = wall:GetAttribute(Sawing.FromAttribute)
		if typeof(frame) ~= "CFrame" or type(start) ~= "number" then
			return
		end
		local side = if type(from) == "number" and from < 0 then -1 else 1
		local top = wall:GetAttribute(Sawing.KindAttribute) == "Top"
		local depth = if top then TOP_DEPTH else LINE_DEPTH
		local folder = Instance.new("Folder")
		folder.Name = "SawCut"
		local edges: { Part } = {}
		for i = 1, 4 do
			-- 1 and 3 run up the wall (across a top), 2 and 4 along it
			local size = if i % 2 == 1
				then Vector3.new(depth, 0.01, LINE_THICK)
				else Vector3.new(depth, LINE_THICK, 0.01)
			edges[i] = bright("Edge" .. i, LINE_COLOUR, size, folder)
		end
		local head = bright("Blade", HEAD_COLOUR, Vector3.one * HEAD_SIZE, folder)
		head.Shape = Enum.PartType.Ball
		head.Transparency = 0
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color = ColorSequence.new(HEAD_COLOUR, LINE_COLOUR)
		sparks.LightEmission = 1
		sparks.LightInfluence = 0
		sparks.Rate = SPARK_RATE
		sparks.Speed = SPARK_SPEED
		sparks.Lifetime = SPARK_LIFE
		sparks.Size = SPARK_SIZE
		sparks.SpreadAngle = SPARK_SPREAD
		sparks.Acceleration = SPARK_FALL
		sparks.EmissionDirection = if side > 0 then Enum.NormalId.Right else Enum.NormalId.Left
		sparks.Parent = head
		local sounds = {}
		for _, s in { Sawing.Sounds.Whine, Sawing.Sounds.Chatter } do
			local snd = sound(s, head)
			snd.TimePosition = s.from
			snd:Play()
			table.insert(sounds, snd)
		end
		folder.Parent = Workspace
		local mine = wall:GetAttribute(Sawing.ByAttribute) == player.UserId
		if mine then
			kick(Sawing.Buzz) -- the motor catching in your hands
		end
		cuts[wall] = {
			wall = wall,
			frame = frame,
			rect = if top then TOP_RECT else CrawlHole.Rect,
			lineX = if top then TOP_LINE_X else LINE_X,
			depth = depth,
			start = start,
			mine = mine,
			folder = folder,
			edges = edges,
			head = head,
			sparks = sparks,
			sounds = sounds,
			drawn = { 0, 0, 0, 0 },
		}
	end

	-- The motor winds down and the line cools away.
	local function finish(inst: Instance)
		local cut = cuts[inst :: BasePart]
		if not cut then
			return
		end
		cuts[inst :: BasePart] = nil
		cut.sparks.Enabled = false
		for _, snd in cut.sounds do
			TweenService:Create(
				snd,
				TweenInfo.new(Sawing.SpinDown, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ PlaybackSpeed = snd.PlaybackSpeed * Sawing.SpinDownPitch, Volume = 0 }
			):Play()
		end
		for _, p in cut.edges do
			if p.Transparency < 1 then
				TweenService:Create(p, COOL, { Transparency = 1 }):Play()
			end
		end
		TweenService:Create(cut.head, COOL, { Transparency = 1 }):Play()
		local folder = cut.folder
		task.delay(math.max(COOL_SECONDS, Sawing.SpinDown) + 0.1, function()
			folder:Destroy()
		end)
	end

	local function draw(cut: Cut, t: number)
		local r = cut.rect
		local along, up = Sawing.line(Sawing.progress(t - cut.start), r, cut.drawn)
		local w, h = r.to - r.from, r.top - r.bottom
		local f = cut.frame
		local d = cut.drawn
		local x, depth = cut.lineX, cut.depth
		-- each edge from where the cut began on it to as far as it's got
		local e1, e2, e3, e4 = cut.edges[1], cut.edges[2], cut.edges[3], cut.edges[4]
		local l1, l2, l3, l4 = h * d[1], w * d[2], h * d[3], w * d[4]
		e1.Transparency = if l1 > 0 then 0 else 1
		e1.Size = Vector3.new(depth, math.max(l1, 0.01), LINE_THICK)
		e1.CFrame = f * CFrame.new(x, r.top - l1 / 2, r.from)
		e2.Transparency = if l2 > 0 then 0 else 1
		e2.Size = Vector3.new(depth, LINE_THICK, math.max(l2, 0.01))
		e2.CFrame = f * CFrame.new(x, r.bottom, r.from + l2 / 2)
		e3.Transparency = if l3 > 0 then 0 else 1
		e3.Size = Vector3.new(depth, math.max(l3, 0.01), LINE_THICK)
		e3.CFrame = f * CFrame.new(x, r.bottom + l3 / 2, r.to)
		e4.Transparency = if l4 > 0 then 0 else 1
		e4.Size = Vector3.new(depth, LINE_THICK, math.max(l4, 0.01))
		e4.CFrame = f * CFrame.new(x, r.top, r.to - l4 / 2)
		-- the blade's spot, shaking with its stroke
		local jitter = (math.random() * 2 - 1) * JITTER
		cut.head.CFrame = f * CFrame.new(x, up + jitter * 0.5, along + jitter)
	end

	local function fell(inst: Instance)
		if not inst:IsA("BasePart") or falls[inst] then
			return
		end
		local panel = inst
		local at = panel:GetAttribute(CrawlHole.CutAtAttribute)
		local hinge = panel:GetAttribute(CrawlHole.HingeAttribute)
		local angle = panel:GetAttribute(CrawlHole.FallAttribute)
		if type(at) ~= "number" or typeof(hinge) ~= "CFrame" or type(angle) ~= "number" then
			return
		end
		if now() - at > FRESH then
			return -- an old hole streaming in: it lies where it fell
		end
		local fall: Fall = {
			panel = panel,
			hinge = hinge,
			rest = hinge:ToObjectSpace(panel.CFrame),
			angle = angle,
			at = os.clock(),
			landed = false,
		}
		panel.CFrame = hinge * CFrame.Angles(0, 0, angle) * fall.rest
		falls[panel] = fall
	end

	-- The clang where a panel lands (`s`: the wall's tip-over or the top's drop), and the jolt for
	-- everyone near it.
	local function clang(at: Vector3, s: Sawing.Sound)
		local spot = Instance.new("Attachment")
		spot.Name = "PanelClang"
		spot.WorldPosition = at
		spot.Parent = Workspace.Terrain
		local snd = sound(s, spot)
		snd.TimePosition = s.from
		snd:Play()
		task.delay((s.length or 1) / s.pitch + 0.3, function()
			spot:Destroy()
		end)
		local camera = Workspace.CurrentCamera
		if camera then
			local d = (camera.CFrame.Position - at).Magnitude
			kick(Sawing.Jolt * Shake.falloff(d, Sawing.JoltNear, Sawing.JoltReach))
		end
	end

	-- A top's panel just cut out (the server lays it where it fell): put it back in the hole and
	-- drop it from there.
	local function dropped(inst: Instance)
		if not inst:IsA("Model") or drops[inst] then
			return
		end
		local model = inst
		local at = model:GetAttribute(TopHole.CutAtAttribute)
		local unit = model.Parent
		if type(at) ~= "number" or not (unit and unit:IsA("Model")) then
			return
		end
		if now() - at > FRESH then
			return -- an old hole streaming in: it lies where it fell
		end
		local hole = TopHole.frame(unit)
		if not hole then
			return
		end
		local rest = model:GetPivot()
		local from = TopHole.unfallen(hole, rest)
		local height = math.max(from.Position.Y - rest.Position.Y, 0)
		drops[model] = {
			model = model,
			from = from,
			rest = rest,
			seconds = math.sqrt(2 * height / math.max(Workspace.Gravity, 1)),
			at = os.clock(),
			landed = false,
		}
		model:PivotTo(from)
	end

	local system = { name = "SawView" }

	function system.start(_: any, _context: Brix.Context)
		SoundPrimer.prime({
			Sawing.Sounds.Whine.id,
			Sawing.Sounds.Chatter.id,
			Sawing.Sounds.Clang.id,
			Sawing.Sounds.Drop.id,
		})
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Sawing.Tag):Connect(begin)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Sawing.Tag):Connect(finish)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(CrawlHole.PanelTag):Connect(fell)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(CrawlHole.PanelTag)
				:Connect(function(inst: Instance)
					falls[inst :: BasePart] = nil
				end)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(TopHole.PanelTag):Connect(dropped)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(TopHole.PanelTag)
				:Connect(function(inst: Instance)
					drops[inst :: Model] = nil
				end)
		)
		for _, inst in CollectionService:GetTagged(Sawing.Tag) do
			begin(inst)
		end
	end

	function system.step(_: any, dt: number)
		if next(cuts) ~= nil then
			local t = now()
			for _, cut in cuts do
				draw(cut, t)
				if cut.mine then
					-- hold the buzz against the shake's decay while your saw runs
					kick(Shake.Decay * dt)
				end
			end
		end
		if next(falls) ~= nil then
			local c = os.clock()
			for panel, fall in falls do
				local s = c - fall.at
				local turn: number
				if s < FALL_SECONDS then
					local k = s / FALL_SECONDS
					turn = fall.angle * (1 - k * k) -- falling faster as it goes
				else
					if not fall.landed then
						fall.landed = true
						clang(fall.panel.Position, Sawing.Sounds.Clang)
					end
					local b = (s - FALL_SECONDS) / BOUNCE_SECONDS
					turn = if b < 1 then fall.angle * BOUNCE * math.sin(b * math.pi) else 0
					if b >= 1 then
						falls[panel] = nil
					end
				end
				panel.CFrame = fall.hinge * CFrame.Angles(0, 0, turn) * fall.rest
			end
		end
		if next(drops) ~= nil then
			local c = os.clock()
			for model, d in drops do
				local s = c - d.at - TOP_HANG
				if s < d.seconds then
					-- falling faster as it goes: it leaves the hole flat and turns as it nears the floor
					local k = if s > 0 then s / d.seconds else 0
					model:PivotTo(d.from:Lerp(d.rest, k * k))
				else
					if not d.landed then
						d.landed = true
						clang(d.rest.Position, Sawing.Sounds.Drop)
					end
					local b = (s - d.seconds) / TOP_HOP_SECONDS
					if b < 1 then
						model:PivotTo(d.rest + Vector3.new(0, TOP_HOP * math.sin(b * math.pi), 0))
					else
						model:PivotTo(d.rest)
						drops[model] = nil
					end
				end
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for wall in cuts do
			finish(wall)
		end
		for _, fall in falls do
			fall.panel.CFrame = fall.hinge * fall.rest
		end
		table.clear(falls)
		for model, d in drops do
			model:PivotTo(d.rest)
		end
		table.clear(drops)
	end

	return system
end

return SawView
