--!strict
--[[
	TryOnView: a wrap colour tried on at a mirror (S5-03f4a, idea 24, D-318), on every screen. The
	server wraps whoever pressed Try on in that colour's film, holds them facing the glass and
	stamps the film with when it went on and the way they faced before (TryOns). From that stamp
	every screen plays the same few seconds (`TryOn.pose`):

	- The wind: the film climbs from a band round the ankles and clouds in while the body turns
	  once round to face the glass, as the catch's wind does (KeptWrapOn), with a quick zip of film
	  off the roll (`TryOn.Zip`).
	- A few seconds wrapped, still, so you can look at yourself in the glass.
	- The peel: it loosens with a crinkle (`TryOn.Crinkle`), slumps to a heap round the ankles with
	  a soft crunch (`TryOn.Land`), lies a moment and fades. Then the server takes it away.

	It works on the real film in the character (its size, its weld's offset, its see-through), not a
	copy, so the mirror's copy of you follows it (MirrorView). The body's turn is this screen's
	alone: the server holds their root anchored, so nothing it sends moves it meanwhile. While your
	own film is on, the mirrors' Try on buttons are hidden on your screen. It steps only while a
	film is on someone.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Mirror = require(ReplicatedStorage.Shared.Mirror)
local SoundPrimer = require(script.Parent.SoundPrimer)
local Tools = require(ReplicatedStorage.Shared.Tools)
local TryOn = require(ReplicatedStorage.Shared.TryOn)

-- Seconds after its moment a sound still plays: a film seen a touch late still zips; later, not.
local LATE = 0.3
-- Your view's turn to the glass: bound just after Roblox's camera has placed it each frame, so the
-- camera starts the next frame from where this leaves it and the turn sticks once it's done.
local LOOK_BIND = "TryOnLook"
local LOOK_PRIORITY = Enum.RenderPriority.Camera.Value + 1

-- A film on someone: the part and its weld, the body's root, where the root stood and the way it
-- ends up facing, the way it faced before, the film's full size and offset on the root, when it
-- went on, and which sounds have played.
type On = {
	film: BasePart,
	weld: Weld,
	root: BasePart,
	at: Vector3,
	from: number,
	to: number,
	size: Vector3,
	offset: CFrame,
	wound: number,
	turning: boolean,
	zipped: boolean,
	crinkled: boolean,
	landed: boolean,
	mine: boolean,
}

local TryOnView = {}

function TryOnView.new(): Brix.System
	local on: { [BasePart]: On } = {}
	local connections: { RBXScriptConnection } = {}
	local running = false
	local looking = false -- your view is turning to a glass

	local function stopLooking()
		if looking then
			looking = false
			RunService:UnbindFromRenderStep(LOOK_BIND)
		end
	end

	-- Your view turned from where it looks now to `target` (the glass's middle) over `TryOn.Look`,
	-- eased out, its position left to the camera (your eye).
	local function lookAt(target: Vector3)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		stopLooking()
		local start = camera.CFrame.Rotation
		local began = os.clock()
		looking = true
		RunService:BindToRenderStep(LOOK_BIND, LOOK_PRIORITY, function()
			local cam = Workspace.CurrentCamera
			if not cam then
				stopLooking()
				return
			end
			local a = math.clamp((os.clock() - began) / TryOn.Look, 0, 1)
			local eased = 1 - (1 - a) ^ 3
			local at = cam.CFrame.Position
			local aim = CFrame.lookAt(at, target).Rotation
			cam.CFrame = CFrame.new(at) * start:Lerp(aim, eased)
			if a >= 1 then
				stopLooking()
			end
		end)
	end

	-- The mirrors' Try on buttons shown (`shown`) or hidden on this screen.
	local function buttons(shown: boolean)
		for _, glass in CollectionService:GetTagged(Mirror.Tag) do
			local prompt = glass:FindFirstChild("TryOn", true)
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Enabled = shown
			end
		end
	end

	local function finish(o: On)
		on[o.film] = nil
		if o.turning and o.root.Parent then
			o.root.CFrame = CFrame.new(o.at) * CFrame.Angles(0, o.to, 0)
		end
		if o.mine then
			buttons(true)
		end
	end

	local function add(inst: Instance)
		if not (running and inst:IsA("BasePart")) or on[inst] then
			return
		end
		local wound = inst:GetAttribute(TryOn.WoundAttribute)
		local from = inst:GetAttribute(TryOn.FromAttribute)
		local weld = inst:FindFirstChildWhichIsA("Weld")
		local character = inst.Parent
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if
			type(wound) ~= "number"
			or type(from) ~= "number"
			or not (weld and root and root:IsA("BasePart"))
			or Workspace:GetServerTimeNow() - wound >= TryOn.length()
		then
			return
		end
		local look = root.CFrame.LookVector
		local me = Players.LocalPlayer
		local mine = me ~= nil and character == me.Character
		on[inst] = {
			film = inst,
			weld = weld,
			root = root,
			at = root.Position,
			from = from,
			to = math.atan2(-look.X, -look.Z),
			size = inst.Size,
			offset = weld.C0,
			wound = wound,
			turning = Workspace:GetServerTimeNow() - wound < TryOn.Wind,
			zipped = false,
			crinkled = false,
			landed = false,
			mine = mine,
		}
		if mine then
			buttons(false)
			local target = inst:GetAttribute(TryOn.LookAttribute)
			if
				typeof(target) == "Vector3"
				and Workspace:GetServerTimeNow() - wound < TryOn.Wind
			then
				lookAt(target)
			end
		end
	end

	local function remove(inst: Instance)
		local o = on[inst :: BasePart]
		if o then
			finish(o)
		end
	end

	-- `spec` played round `o`'s body if `t` is within a beat after its moment `at`.
	local function sound(o: On, spec: Tools.SoundSpec, t: number, at: number): boolean
		if t >= at then
			if t - at < LATE then
				Tools.play(spec, o.root, TryOn.Hearing)
			end
			return true
		end
		return false
	end

	return {
		name = "TryOnView",
		start = function(_: any, _context: Brix.Context)
			running = true
			task.spawn(SoundPrimer.prime, { TryOn.Zip.id, TryOn.Crinkle.id })
			for _, inst in CollectionService:GetTagged(TryOn.Tag) do
				add(inst)
			end
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(TryOn.Tag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(TryOn.Tag):Connect(remove)
			)
		end,
		step = function(_: any, _dt: number)
			if next(on) == nil then
				return
			end
			local now = Workspace:GetServerTimeNow()
			local peel = TryOn.Wind + TryOn.Show
			for _, o in on do
				local t = now - o.wound
				if t >= TryOn.length() or not (o.film.Parent and o.root.Parent) then
					finish(o)
					continue
				end
				local pose = TryOn.pose(t)
				if o.turning then
					o.root.CFrame = CFrame.new(o.at)
						* CFrame.Angles(0, TryOn.turn(o.from, o.to, pose.turned), 0)
					if t >= TryOn.Wind then
						o.turning = false -- facing the glass, where the server holds it
					end
				end
				local size = o.size
				o.film.Size =
					Vector3.new(size.X * pose.wide, size.Y * pose.height, size.Z * pose.deep)
				-- its foot stays on the floor as it climbs and as it slumps
				o.weld.C0 = o.offset * CFrame.new(0, -size.Y * (1 - pose.height) / 2, 0)
				o.film.Transparency = pose.see
				if not o.zipped then
					o.zipped = sound(o, TryOn.Zip, t, 0)
				end
				if not o.crinkled then
					o.crinkled = sound(o, TryOn.Crinkle, t, peel)
				end
				if not o.landed then
					o.landed = sound(o, TryOn.Land, t, peel + TryOn.Peel.yank + TryOn.Peel.fall)
				end
			end
		end,
		stop = function(_: any)
			running = false
			stopLooking()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, o in on do
				finish(o)
			end
		end,
	}
end

return TryOnView
