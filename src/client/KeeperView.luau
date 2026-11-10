--!strict
--[[
	KeeperView: moves and poses every keeper's body on this screen (L-06b4a), as they stream in and
	out.

	The moment: it comes down the hall at you and you see one smooth, stiff-limbed walk, a phone
	included, not a body hopping between the server's updates.

	The server sends each keeper's motion as a short record on its body's `KeeperMotion` attribute,
	only when that changes (`KeeperMotion.due`). Here each body follows its records
	(`KeeperMotion.follow`): carried on between them, shown a little behind the server so a turn or
	a stop lands exactly, a late correction eased out, a turn eased. Its root is moved here each
	frame it moves, overriding the server's coarse placing, and it's posed here through its joints'
	`Transform` (the server leaves them at rest), one of a few fixed frames of its walk
	(`Pose.frame`), so a joint is turned only when the frame changes and nothing per joint
	replicates.

	Each key its walk lands as it's shown here is passed to `heard` (KeeperSounds), which plays
	its footfall or the knock of its joints (`Pose.tell`, L-06b4b2): every screen hears the walk
	it shows, and nothing more crosses the network.

	Your own torch is the one thing this screen knows before the server (L-06b4b3): each frame
	your torch is on, a body shown walking that freezes in light is tested against your beam (the
	brain's own test, `Torch.lights` at `Keeper.beamPoint`, with a raycast for the line where the
	brain uses its map), and the frame your beam lands on it, it stops dead here
	(`KeeperMotion.hold`), on the key a light freezes it on, and your aim goes to the server at
	once (`Beam.landed`) so the server's freeze follows a round trip later. In Studio, Output says
	when it held, when the server's stop answered and how far on, and when it walked on.

	Only bodies moving on this screen are stepped; a standing one is left alone until its next
	record. Nothing allocates per frame. The Host steps this just before each frame renders, after
	the frame's replicated changes have landed, so what's drawn is always this screen's place.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Keeper = require(ReplicatedStorage.Shared.Keeper)
local KeeperMotion = require(ReplicatedStorage.Shared.KeeperMotion)
local KeeperRows = require(ReplicatedStorage.Shared.KeeperRows)
local Mannequin = require(ReplicatedStorage.Shared.Mannequin)
local Pose = require(ReplicatedStorage.Shared.Mannequin.Pose)
local Torch = require(ReplicatedStorage.Shared.Flashlight.Torch)

local TRACE = RunService:IsStudio() -- Output says when your beam holds one, and how it ends

local TAG = "Keeper" -- on each keeper's body (the server's Keepers)
local MOTION_ATTRIBUTE = "KeeperMotion"
local ROW_ATTRIBUTE = "Keeper"

-- How each kind of keeper is posed: its joints, the frame it shows, each frame's turns.
type Kit = {
	motors: (model: Model) -> { Motor6D }?,
	along: (travelled: number, how: KeeperMotion.How) -> number, -- how far along its walk
	frameAt: (along: number) -> number, -- the frame for that
	transforms: (frame: number) -> { CFrame },
	tell: (last: number?, travelled: number, how: KeeperMotion.How) -> (Pose.Sound?, number),
}
local KITS: { [string]: Kit } = {
	Mannequin = {
		motors = Mannequin.motors,
		along = Pose.along,
		frameAt = Pose.frameAt,
		transforms = Mannequin.transforms,
		tell = Pose.tell,
	},
}

type View = {
	model: Model,
	root: BasePart,
	rootOffset: CFrame, -- from its pivot (its feet) to its root part
	motors: { Motor6D },
	kit: Kit,
	row: string,
	height: number, -- how tall it stands (its row's), for your beam
	freezes: boolean, -- whether light freezes it (its row's)
	follow: KeeperMotion.Follow,
	frame: number, -- the frame it was last posed in (0: none yet)
	along: number, -- the furthest along its walk it has been shown (Pose.along)
	heldWhen: number, -- when your beam held it (os.clock), for Output
	answered: boolean, -- the server's stop has answered that hold
	told: number?, -- what its kit's `tell` last returned (nil: not posed yet)
	conns: { RBXScriptConnection },
}

-- Your torch, as FlashlightView tells it: whether it's on on your screen, and a way to have your
-- aim sent to the server at once.
type Beam = {
	on: () -> boolean,
	landed: () -> (),
}

local KeeperView = {}

-- `heard` plays a body's footfall or knock (KeeperSounds); `beam` is your torch (FlashlightView).
function KeeperView.new(heard: (model: Model, sound: Pose.Sound) -> (), beam: Beam): Brix.System
	local views: { [Model]: View } = {}
	local moving: { [Model]: View } = {} -- the ones to step
	local connections: { RBXScriptConnection } = {}
	local player = Players.LocalPlayer
	local rays = RaycastParams.new()
	rays.FilterType = Enum.RaycastFilterType.Exclude
	rays.RespectCanCollide = true -- walls and doors, not the invisible volumes the halls carry
	local rayCharacter: Model? = nil

	-- The time this screen shows keepers at: the server's, `Delay` behind.
	local function showing(): number
		return Workspace:GetServerTimeNow() - KeeperMotion.Delay
	end

	-- Poses it as its follower shows it now, and plays what its walk lands.
	local function pose(view: View)
		local f = view.follow
		local how: KeeperMotion.How = KeeperMotion.how(f.state, f.speed)
		local frame = 1
		if how ~= "Still" then
			view.along = math.max(view.along, view.kit.along(f.travelled, how))
			frame = view.kit.frameAt(view.along)
		end
		local sound: Pose.Sound?, told: number = view.kit.tell(view.told, f.travelled, how)
		view.told = told
		if sound then
			heard(view.model, sound)
		end
		if frame ~= view.frame then
			view.frame = frame
			local turns = view.kit.transforms(frame)
			for i, motor in view.motors do
				motor.Transform = turns[i]
			end
		end
	end

	-- Output: your beam's hold on one began, was answered, or ended.
	local function trace(view: View, what: string)
		local f = view.follow
		print(
			`KeeperView: {what} the {view.row} at ({string.format("%.2f", f.at.x)}, `
				.. `{string.format("%.2f", f.at.z)}), server time {string.format(
					"%.3f",
					Workspace:GetServerTimeNow()
				)}`
		)
	end

	-- Puts it where its records say at time `t`, `dt` after the last, posed. Whether it still moves.
	local function show(view: View, t: number, dt: number): boolean
		local f = view.follow
		local wasHeld = f.held
		local going = KeeperMotion.update(f, t, dt)
		if TRACE and wasHeld then
			if f.stopped ~= 0 and not view.answered then
				view.answered = true
				local newest = f.records[f.head]
				local d = vector.magnitude(newest.at - f.at)
				local after = os.clock() - view.heldWhen
				trace(
					view,
					`the server's stop came {string.format("%.2f", d)} studs on, `
						.. `{string.format("%.3f", after)} s after your beam held`
				)
			end
			if not f.held then
				trace(view, if f.stopped ~= 0 then "the light let go of" else "no stop came for")
			end
		end
		local at, facing = f.at, f.facing
		view.root.CFrame = CFrame.lookAt(
			Vector3.new(at.x, at.y, at.z),
			Vector3.new(at.x + facing.x, at.y, at.z + facing.z)
		) * view.rootOffset
		pose(view)
		return going
	end

	-- Whether your beam, leaving `eye` along `aim`, lights it as this screen shows it: a point up
	-- its middle in the beam (the brain's test) with nothing solid between (the brain's map line,
	-- here a ray).
	local function lit(view: View, eye: vector, aim: vector): boolean
		local at = view.follow.at
		local origin = Vector3.new(eye.x, eye.y, eye.z)
		for i = 1, Keeper.BeamPoints do
			local point = Keeper.beamPoint(at, view.height, i)
			if Torch.lights(eye, aim, point) then
				local hit =
					Workspace:Raycast(origin, Vector3.new(point.x, point.y, point.z) - origin, rays)
				if not hit or hit.Instance:IsDescendantOf(view.model) then
					return true
				end
			end
		end
		return false
	end

	-- Your beam on the bodies walking on this screen: the frame it lands on one, it stops.
	local function watch(t: number)
		if not beam.on() then
			return
		end
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		local camera = Workspace.CurrentCamera
		if not (character and head and head:IsA("BasePart") and camera) then
			return
		end
		if rayCharacter ~= character then
			rayCharacter = character
			rays.FilterDescendantsInstances = { character }
		end
		local e, l = head.Position, camera.CFrame.LookVector
		local eye, aim = vector.create(e.X, e.Y, e.Z), vector.create(l.X, l.Y, l.Z)
		local patience: number? = nil
		for _, view in moving do
			local f = view.follow
			if view.freezes and not f.held and f.speed > 0 and lit(view, eye, aim) then
				patience = patience or KeeperMotion.patience(player:GetNetworkPing())
				if KeeperMotion.hold(f, t, patience :: number) then
					pose(view) -- on the key a light freezes it on, this frame
					beam.landed()
					view.heldWhen, view.answered = os.clock(), false
					if TRACE then
						trace(view, "your beam holds")
					end
				end
			end
		end
	end

	local function receive(view: View)
		local encoded = view.model:GetAttribute(MOTION_ATTRIBUTE)
		if type(encoded) ~= "string" then
			return
		end
		local t = showing()
		if KeeperMotion.receive(view.follow, encoded, t) then
			-- placed at once, so nothing shows a frame out of place
			if show(view, t, 0) then
				moving[view.model] = view
			else
				moving[view.model] = nil
			end
		end
	end

	local function unbind(inst: Instance)
		local view = views[inst :: Model]
		if not view then
			return
		end
		views[view.model], moving[view.model] = nil, nil
		for _, c in view.conns do
			c:Disconnect()
		end
	end

	local function bind(inst: Instance)
		-- only bodies in the world: a tagged template elsewhere stays untouched
		if not inst:IsA("Model") or views[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local model = inst
		local row = model:GetAttribute(ROW_ATTRIBUTE)
		local kit = if type(row) == "string" then KITS[row] else nil
		local rowOf = if type(row) == "string" then KeeperRows[row] else nil
		local root = model.PrimaryPart
		local motors = kit and kit.motors(model)
		if not (kit and rowOf and root and motors) then
			warn(`KeeperView: can't move {model:GetFullName()}: no such keeper, root or joints`)
			return
		end
		local view: View = {
			model = model,
			root = root,
			rootOffset = root.PivotOffset:Inverse(),
			motors = motors,
			kit = kit,
			row = rowOf.name,
			height = rowOf.height,
			freezes = rowOf.freezesInLight,
			follow = KeeperMotion.follow(),
			frame = 0,
			along = -1,
			heldWhen = 0,
			answered = false,
			told = nil,
			conns = {},
		}
		views[model] = view
		table.insert(
			view.conns,
			model:GetAttributeChangedSignal(MOTION_ATTRIBUTE):Connect(function()
				receive(view)
			end)
		)
		table.insert(
			view.conns,
			model.Destroying:Connect(function()
				unbind(model)
			end)
		)
		receive(view)
	end

	return {
		name = "KeeperView",
		start = function(_: any, _context: Brix.Context)
			table.insert(connections, CollectionService:GetInstanceAddedSignal(TAG):Connect(bind))
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(TAG):Connect(unbind)
			)
			for _, inst in CollectionService:GetTagged(TAG) do
				bind(inst)
			end
		end,
		step = function(_: any, dt: number)
			if next(moving) == nil then
				return
			end
			local t = showing()
			for model, view in moving do
				if not show(view, t, dt) then
					moving[model] = nil
				end
			end
			watch(t)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in views do
				unbind(model)
			end
		end,
	}
end

return KeeperView
