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
	that beat of its limp (`Pose.tell`, L-06b4b2, L-06c1), and so is each turn of its facing past
	its row's `turn` (its body creaks): every screen hears the walk it shows, and nothing more
	crosses the network.

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
local KeeperTell = require(ReplicatedStorage.Shared.KeeperTell)
local Mannequin = require(ReplicatedStorage.Shared.Mannequin)
local Packrat = require(ReplicatedStorage.Shared.Packrat)
local Pose = require(ReplicatedStorage.Shared.Mannequin.Pose)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Torch = require(ReplicatedStorage.Shared.Flashlight.Torch)

local TRACE = RunService:IsStudio() -- Output says when your beam holds one, and how it ends

local TAG = "Keeper" -- on each keeper's body (the server's Keepers)
local MOTION_ATTRIBUTE = "KeeperMotion"
local ROW_ATTRIBUTE = "Keeper"

-- How each kind of keeper is posed: its joints, the frame it shows, each frame's turns.
type How = KeeperMotion.How
type Kit = {
	motors: (model: Model) -> { Motor6D }?,
	along: (travelled: number, how: How) -> number, -- how far along its walk
	frameAt: (along: number, how: How) -> number, -- the frame for that
	held: (how: How) -> number?, -- the frame standing slack, at a lever or with its hands busy
	-- which of its walks it shows (the Packrat's full or empty, S2-06b2): its `along` starts
	-- again when that changes, since each walk counts its own keys
	walk: (how: How) -> number,
	transforms: (frame: number) -> { CFrame },
	tell: (last: number?, travelled: number, how: How) -> (Pose.Sound?, number),
	quiet: boolean, -- no beats and no creak as it turns (the Packrat's sounds come in S2-06e)
	-- where a find it holds sits in a How, in its UpperTorso's frame (a carried find's weld C0),
	-- and how long that find takes to ease there; nil: where the find lay, its hands not yet
	-- closed on it on this screen (the Packrat's, S2-06b2b; the Mannequin never holds one)
	hands: (how: How) -> (CFrame?, number),
}

-- The Mannequin's own poses for a How only the Packrat shows (it never is told those).
local function plain(how: How): Pose.How
	if how == "Carry" then
		return "Walk"
	elseif how == "Hold" then
		return "Stop"
	elseif how == "Take" or how == "PutDown" then
		return "Still"
	end
	return how
end

local PackratPose = Packrat.Pose
-- The Packrat's held frames by How (S2-06b2): reaching for a find, pulling it in, setting it down.
local PACKRAT_HELD: { [string]: number } = {
	Still = PackratPose.held("Still") :: number,
	Pull = PackratPose.held("Still") :: number,
	Reach = PackratPose.held("Reach") :: number,
	Take = PackratPose.held("Take") :: number,
	PutDown = PackratPose.held("PutDown") :: number,
}
local function packratWalk(how: How): "Empty" | "Full"
	return if how == "Carry" or how == "Hold" then "Full" else "Empty"
end
-- Where the Packrat holds a find by How (S2-06b2b): between its palms as they close on it and as
-- it crouches to set it down, against its chest walking or standing full.
local PACKRAT_HANDS: { [string]: CFrame } = {
	Take = Packrat.Grip.Take,
	PutDown = Packrat.Grip.PutDown,
	Carry = Packrat.Chest,
	Hold = Packrat.Chest,
}
local PACKRAT_EASE: { [string]: number } = {
	Take = Packrat.Ease.Take,
	PutDown = Packrat.Ease.PutDown,
	Carry = Packrat.Ease.Chest,
	Hold = Packrat.Ease.Chest,
}

local KITS: { [string]: Kit } = {
	Mannequin = {
		motors = Mannequin.motors,
		along = function(travelled: number, how: How): number
			return Pose.along(travelled, plain(how))
		end,
		frameAt = function(along: number, _: How): number
			return Pose.frameAt(along)
		end,
		held = function(how: How): number?
			return Pose.held(plain(how))
		end,
		walk = function(_: How): number
			return 0
		end,
		transforms = Mannequin.transforms,
		tell = function(last: number?, travelled: number, how: How): (Pose.Sound?, number)
			return Pose.tell(last, travelled, plain(how))
		end,
		quiet = false,
		hands = function(_: How): (CFrame?, number)
			return nil, 0
		end,
	},
	-- glides on its full walk or its empty one by whether its arms are full (D-177); no beats yet
	Packrat = {
		motors = Packrat.motors,
		along = function(travelled: number, how: How): number
			return PackratPose.along(packratWalk(how), travelled)
		end,
		frameAt = function(along: number, how: How): number
			return PackratPose.frameAt(packratWalk(how), along)
		end,
		held = function(how: How): number?
			return PACKRAT_HELD[how]
		end,
		walk = function(how: How): number
			return if packratWalk(how) == "Full" then 1 else 0
		end,
		transforms = Packrat.transforms,
		tell = function(_: number?, _: number, _: How): (Pose.Sound?, number)
			return nil, 0
		end,
		quiet = true,
		hands = function(how: How): (CFrame?, number)
			return PACKRAT_HANDS[how], PACKRAT_EASE[how] or 0
		end,
	},
}

-- An ease out and in (smoothstep): a find leaves where it was gently and settles gently.
local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

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
	walk: number, -- which of its walks that is (its kit's `walk`)
	heldWhen: number, -- when your beam held it (os.clock), for Output
	answered: boolean, -- the server's stop has answered that hold
	told: number?, -- what its kit's `tell` last returned (nil: not posed yet)
	turn: number, -- degrees its facing turns before its body creaks (its row's)
	turnX: number?, -- the facing it measures its next turn from (nil: not shown yet)
	turnZ: number,
	-- a find in its arms (S2-06b2b): the weld holding it to its chest (Slots' `lift`), nil for
	-- none; the chest it rides; where the find is easing to (its kit's `hands`; nil while it's
	-- still held where it lay), from where and since when (os.clock), over how long; whether
	-- it has arrived
	carried: Weld?,
	chest: BasePart?,
	gripTo: CFrame?,
	gripFrom: CFrame,
	fromWorld: CFrame?, -- easing up from where it lay: that, in the world
	gripAt: number,
	gripFor: number,
	gripped: boolean,
	conns: { RBXScriptConnection },
}

-- Your torch, as FlashlightView tells it: whether it's on on your screen, and a way to have your
-- aim sent to the server at once.
type Beam = {
	on: () -> boolean,
	landed: () -> (),
}

local KeeperView = {}

-- `heard` plays a beat of a body's walk, or its creak as it turns (KeeperSounds); `beam` is your
-- torch (FlashlightView).
function KeeperView.new(heard: (model: Model, beat: KeeperTell.Beat) -> (), beam: Beam): Brix.System
	local views: { [Model]: View } = {}
	local moving: { [Model]: View } = {} -- the ones to step
	local holding: { [Model]: View } = {} -- the ones whose find is still moving in its arms
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

	-- The find in its arms on this screen (S2-06b2b): held where it lay until this screen shows
	-- the hands close on it (the server's weld arrives `Delay` ahead of the pose), then eased up
	-- into them; from them to its chest as it walks off; down into its hands as it crouches over
	-- its pile. Stepped every frame (`holding`) until it settles; the weld's C0 is written only
	-- while the find moves.
	local function hold(view: View)
		local weld, chest = view.carried, view.chest
		if not (weld and weld.Parent and chest) then
			view.carried = nil
			holding[view.model] = nil
			return
		end
		local f = view.follow
		local to, ease = view.kit.hands(KeeperMotion.how(f.state, f.speed))
		local from = weld:GetAttribute(Packrat.FromAttribute)
		if to == nil then
			-- not yet in its hands here: where it lay, if the server said (else where it put it)
			view.gripTo, view.gripped = nil, false
			if typeof(from) == "CFrame" then
				weld.C0 = chest.CFrame:ToObjectSpace(from)
				holding[view.model] = view
			else
				holding[view.model] = nil
			end
			return
		end
		if to ~= view.gripTo then
			-- up from the floor in the world, so the hands' snap from reach to take can't jolt it;
			-- between holds in the chest's own frame, so it rides the body as it turns
			local lay = view.gripTo == nil and typeof(from) == "CFrame"
			view.fromWorld = if lay then from :: CFrame else nil
			view.gripTo, view.gripFrom, view.gripAt, view.gripFor = to, weld.C0, os.clock(), ease
			view.gripped = false
		end
		if view.gripped then
			holding[view.model] = nil
			return
		end
		local t = if view.gripFor > 0 then (os.clock() - view.gripAt) / view.gripFor else 1
		if t >= 1 then
			weld.C0 = to
			view.gripped = true
			holding[view.model] = nil
			return
		end
		local e = smooth(t)
		local world = view.fromWorld
		if world then
			local c = chest.CFrame
			weld.C0 = c:ToObjectSpace(world:Lerp(c * to, e))
		else
			weld.C0 = view.gripFrom:Lerp(to, e)
		end
		holding[view.model] = view
	end

	-- A weld holding a find in its arms came or went (Slots' `lift`, `putDown`).
	local function carry(view: View, inst: Instance, came: boolean)
		if not (inst:IsA("Weld") and inst.Name == Tools.CarriedName) then
			return
		end
		if came then
			view.carried, view.gripTo, view.gripped = inst, nil, false
			hold(view) -- this frame, before it's drawn at its chest
		elseif view.carried == inst then
			view.carried = nil
			holding[view.model] = nil
		end
	end

	-- Poses it as its follower shows it now, and plays what its walk lands.
	local function pose(view: View)
		local f = view.follow
		local how: KeeperMotion.How = KeeperMotion.how(f.state, f.speed)
		local held = view.kit.held(how)
		local frame: number
		if held then
			frame = held
		else
			local walk = view.kit.walk(how)
			if walk ~= view.walk then
				view.walk, view.along = walk, -1 -- the other walk's keys: counted afresh
			end
			view.along = math.max(view.along, view.kit.along(f.travelled, how))
			frame = view.kit.frameAt(view.along, how)
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
		if view.carried then
			hold(view)
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
		-- its body creaks once it has turned far enough from where it last creaked
		local turnX = view.turnX
		if turnX == nil or (turnX == 0 and view.turnZ == 0) then
			view.turnX, view.turnZ = facing.x, facing.z -- its first facing, or its first real one
		elseif KeeperTell.turned(turnX, view.turnZ, facing.x, facing.z, view.turn) then
			view.turnX, view.turnZ = facing.x, facing.z
			heard(view.model, "Creak")
		end
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

	-- Bodies this screen has before all of them has arrived (its row, its root or a joint: a
	-- streamed model can come in pieces), bound once the rest is here.
	local pending: { [Model]: { RBXScriptConnection } } = {}

	local function unpend(model: Model)
		local conns = pending[model]
		if conns then
			pending[model] = nil
			for _, c in conns do
				c:Disconnect()
			end
		end
	end

	local function unbind(inst: Instance)
		unpend(inst :: Model)
		local view = views[inst :: Model]
		if not view then
			return
		end
		views[view.model], moving[view.model], holding[view.model] = nil, nil, nil
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
		if type(row) == "string" and not (kit and rowOf) then
			warn(`KeeperView: can't move {model:GetFullName()}: no keeper called {row}`)
			return
		end
		local root = model.PrimaryPart
		local motors = kit and kit.motors(model)
		if not (kit and rowOf and root and motors) then
			-- not all here yet: bound as the rest arrives, so it never stands frozen on this screen
			if not pending[model] then
				local function again()
					bind(model)
				end
				pending[model] = {
					model.DescendantAdded:Connect(again),
					model:GetPropertyChangedSignal("PrimaryPart"):Connect(again),
					model:GetAttributeChangedSignal(ROW_ATTRIBUTE):Connect(again),
				}
			end
			return
		end
		unpend(model)
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
			walk = 0,
			heldWhen = 0,
			answered = false,
			told = nil,
			turn = if kit.quiet then math.huge else rowOf.tell.turn,
			turnX = nil,
			turnZ = 0,
			carried = nil,
			chest = nil,
			gripTo = nil,
			gripFrom = CFrame.identity,
			fromWorld = nil,
			gripAt = 0,
			gripFor = 0,
			gripped = false,
			conns = {},
		}
		views[model] = view
		local chest = model:FindFirstChild("UpperTorso")
		if chest and chest:IsA("BasePart") then
			view.chest = chest
		end
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
		if view.chest then
			-- a find lifted into its arms, and set down again (S2-06b2b)
			table.insert(
				view.conns,
				model.DescendantAdded:Connect(function(added: Instance)
					carry(view, added, true)
				end)
			)
			table.insert(
				view.conns,
				model.DescendantRemoving:Connect(function(going: Instance)
					carry(view, going, false)
				end)
			)
		end
		receive(view)
		if view.chest then
			for _, part in model:GetDescendants() do
				carry(view, part, true) -- one already in its arms as it streams in
			end
		end
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
			for model, view in holding do
				if not moving[model] then
					hold(view) -- standing still, a find still easing in its arms
				end
			end
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
			for model in pending do
				unpend(model)
			end
		end,
	}
end

return KeeperView
