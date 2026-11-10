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

	Only bodies moving on this screen are stepped; a standing one is left alone until its next
	record. Nothing allocates per frame. The Host steps this just before each frame renders, after
	the frame's replicated changes have landed, so what's drawn is always this screen's place.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local KeeperMotion = require(ReplicatedStorage.Shared.KeeperMotion)
local Mannequin = require(ReplicatedStorage.Shared.Mannequin)
local Pose = require(ReplicatedStorage.Shared.Mannequin.Pose)

local TAG = "Keeper" -- on each keeper's body (the server's Keepers)
local MOTION_ATTRIBUTE = "KeeperMotion"
local ROW_ATTRIBUTE = "Keeper"

-- How each kind of keeper is posed: its joints, the frame it shows, each frame's turns.
type Kit = {
	motors: (model: Model) -> { Motor6D }?,
	frame: (travelled: number, how: KeeperMotion.How) -> number,
	transforms: (frame: number) -> { CFrame },
	tell: (last: number?, travelled: number, how: KeeperMotion.How) -> (Pose.Sound?, number),
}
local KITS: { [string]: Kit } = {
	Mannequin = {
		motors = Mannequin.motors,
		frame = Pose.frame,
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
	follow: KeeperMotion.Follow,
	frame: number, -- the frame it was last posed in (0: none yet)
	told: number?, -- what its kit's `tell` last returned (nil: not posed yet)
	conns: { RBXScriptConnection },
}

local KeeperView = {}

-- `heard` plays a body's footfall or knock (KeeperSounds).
function KeeperView.new(heard: (model: Model, sound: Pose.Sound) -> ()): Brix.System
	local views: { [Model]: View } = {}
	local moving: { [Model]: View } = {} -- the ones to step
	local connections: { RBXScriptConnection } = {}

	-- The time this screen shows keepers at: the server's, `Delay` behind.
	local function showing(): number
		return Workspace:GetServerTimeNow() - KeeperMotion.Delay
	end

	-- Puts it where its records say at time `t`, `dt` after the last, posed. Whether it still moves.
	local function show(view: View, t: number, dt: number): boolean
		local f = view.follow
		local going = KeeperMotion.update(f, t, dt)
		local at, facing = f.at, f.facing
		view.root.CFrame = CFrame.lookAt(
			Vector3.new(at.x, at.y, at.z),
			Vector3.new(at.x + facing.x, at.y, at.z + facing.z)
		) * view.rootOffset
		local how: KeeperMotion.How = KeeperMotion.how(f.state, f.speed)
		local frame = view.kit.frame(f.travelled, how)
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
		return going
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
		local root = model.PrimaryPart
		local motors = kit and kit.motors(model)
		if not (kit and root and motors) then
			warn(`KeeperView: can't move {model:GetFullName()}: no such keeper, root or joints`)
			return
		end
		local view: View = {
			model = model,
			root = root,
			rootOffset = root.PivotOffset:Inverse(),
			motors = motors,
			kit = kit,
			follow = KeeperMotion.follow(),
			frame = 0,
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
