--!strict
--[[
	CartView: every platform cart on this screen (L-08e4b1, Cart.Ride). A rolling cart's wheels
	spin by how far it rolls (Specs.WheelRadius), its front casters swing round to trail the way
	each kingpin moves, and its casters rattle louder and higher the faster it goes. Its rider
	stands on the deck facing the handle, leaning over it, the back leg kicking (Ride.leg); a
	thud on the mat as anyone steps on or off.

	Your own cart is told what happens on it (`told`: the exact kicks, bumps and drags your
	screen rolled, CartRide). A friend's is read from how it moves: a surge is a kick, a hard
	slowing a dragged foot, a sudden stop a clank.

	A cart going home by itself (Cart.Home, L-08e4b2) stays anchored where it set off on the
	server; this screen rolls it along the way the server sent, each frame by the server's clock,
	every part placed (its casters and wheels by their turns, since joints don't move anchored
	parts). It rattles like any rolling cart, and noses into the rack with a soft clunk.

	Only rolling carts are stepped. The casters and wheels turn by their joints' Transform before
	physics, after Roblox's animation, like the riders' joints (Joints).
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Cart = require(ReplicatedStorage.Shared.Cart)
local Home = require(ReplicatedStorage.Shared.Cart.Home)
local Joints = require(script.Parent.Joints)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Ride = require(ReplicatedStorage.Shared.Cart.Ride)
local SoundPrimer = require(script.Parent.SoundPrimer)

local Specs = Cart.Specs

-- Reading a friend's cart from its motion (studs a second, each second).
local SURGE = 12 -- speeding up faster than the casters ever do alone: a kick
local SLOWING = -14 -- slowing harder than coasting: a dragged foot
local SMASH = -80 -- a stop this sudden: a bump
local SMOOTH = 0.08 -- seconds the read speed takes to follow the motion
local SWING = 14 -- radians a second a caster swings round at most
local SOUND_EASE = 0.15 -- seconds the rattle takes to follow the speed

export type Told = "Plant" | "Clank" | "Scrape" | "Stop"

type Body = {
	character: Model,
	joints: { [string]: Joints.Joint },
}

-- A caster's part, placed by hand on a cart going home: a fork turns about its kingpin; a wheel
-- turns with its fork (if any) and spins about its axle. `rest` is its place in the template.
type Mover = {
	part: BasePart,
	fork: number?, -- the front caster it turns with (1 or 2), if any
	wheel: number?, -- its wheel's index in Specs.Casters, if a wheel
	pin: CFrame,
	axle: CFrame,
	rest: CFrame,
}

type Look = {
	model: Model,
	body: BasePart,
	seat: Seat?,
	swivels: { Motor6D }, -- the front casters, left and right
	spins: { Motor6D? }, -- each wheel, in Specs.Casters' order
	swivel: { number }, -- the front casters' turns (radians, 0 trailing nose first)
	spin: { number },
	last: CFrame?, -- the pivot last step
	speed: number, -- along the handle's way (studs a second), as read
	accel: number,
	kickAt: number, -- os.clock() a friend's kick was read
	dragging: boolean,
	rolling: boolean,
	sounds: { [string]: Sound },
	rider: Body?,
	occupant: Humanoid?,
	rigid: { BasePart }, -- the parts that move as one with the pivot (body, deck, seat)...
	rels: { CFrame }, -- ...each from the pivot
	rigidAt: { CFrame }, -- (reused each frame)
	movers: { Mover }, -- the casters' parts
	moverParts: { BasePart },
	moverAt: { CFrame }, -- (reused each frame)
	way: Home.Way?, -- going home: its way, and what it was planned from
	wayFrom: Vector3?,
	wayTo: Vector3?,
	wayShape: number?,
	run: Home.Run, -- (reused each frame)
	docked: boolean, -- its clunk into the rack played
}

-- The joints a rider's pose turns: part, joint.
local POSED = {
	{ "LeftUpperLeg", "LeftHip" },
	{ "LeftLowerLeg", "LeftKnee" },
	{ "RightUpperLeg", "RightHip" },
	{ "RightLowerLeg", "RightKnee" },
	{ "UpperTorso", "Waist" },
	{ "LowerTorso", "Root" },
}

-- The rest of a rider's stance (degrees): the standing leg soft, leaning over the handle. The
-- arms are the torch's (FlashlightView holds it out, after this): seen in Play, L-08e4b1.
local STAND_HIP, STAND_KNEE = 6, -14
local LEAN = -12 -- the waist, forward

local CartView = {}

-- The view, and the function your own ride tells it with: `own` names your cart and the ride
-- state your screen rolls it by (nil when you're off it); `told` plays what just happened.
function CartView.new(): (Brix.System, (model: Model?, state: Ride.State?) -> (), (
	model: Model,
	what: Told,
	loud: number
) -> ())
	local looks: { [Model]: Look } = {}
	local connections: { RBXScriptConnection } = {}
	local mine: Model? = nil
	local mineState: Ride.State? = nil

	local function sound(spec: Ride.Sound, parent: Instance, looped: boolean): Sound
		local s = Instance.new("Sound")
		s.SoundId = spec.id
		s.Volume = spec.volume
		s.PlaybackSpeed = spec.pitch
		s.PlaybackRegionsEnabled = true
		s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
		if looped then
			s.Looped = true
			s.LoopRegion = NumberRange.new(spec.from, spec.from + spec.length)
		end
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 6
		s.RollOffMaxDistance = Ride.Hear
		s.Parent = parent
		return s
	end

	local function play(l: Look, name: string, volume: number)
		local s = l.sounds[name]
		local spec = Ride.Sounds[name]
		if s and spec then
			s.Volume = spec.volume * volume
			s.TimePosition = spec.from
			s:Play()
		end
	end

	local function add(model: Instance)
		if not model:IsA("Model") or looks[model] then
			return
		end
		local body = model:FindFirstChild(Cart.Body)
		if not (body and body:IsA("BasePart")) then
			return
		end
		local seat = model:FindFirstChild(Cart.Seat)
		local l: Look = {
			model = model,
			body = body,
			seat = if seat and seat:IsA("Seat") then seat else nil,
			swivels = {},
			spins = {},
			swivel = {},
			spin = {},
			last = nil,
			speed = 0,
			accel = 0,
			kickAt = -math.huge,
			dragging = false,
			rolling = false,
			sounds = {},
			rider = nil,
			occupant = nil,
			rigid = {},
			rels = {},
			rigidAt = {},
			movers = {},
			moverParts = {},
			moverAt = {},
			way = nil,
			wayFrom = nil,
			wayTo = nil,
			wayShape = nil,
			run = { from = 0, speed = 0, to = 0, at = 0 },
			docked = false,
		}
		-- where its casters stand now, read off the parked pose
		local template = Cart.template()
		local frame = model:GetPivot()
		-- its parts, to place by hand while it goes home
		local moving: { [string]: boolean } = {}
		for i, c in Specs.Casters do
			local forkName = c.Fork
			local f = if forkName then (if c.Wheel == Specs.Casters[1].Wheel then 1 else 2) else nil
			local pin = CFrame.new(c.Kingpin)
			local axle = CFrame.new(c.Axle)
			local tw = template and template:FindFirstChild(c.Wheel)
			local wheel = model:FindFirstChild(c.Wheel)
			if wheel and wheel:IsA("BasePart") and tw and tw:IsA("BasePart") then
				moving[c.Wheel] = true
				table.insert(
					l.movers,
					{ part = wheel, fork = f, wheel = i, pin = pin, axle = axle, rest = tw.CFrame }
				)
			end
			local tf = template and forkName and template:FindFirstChild(forkName)
			local fork = forkName and model:FindFirstChild(forkName)
			if forkName and fork and fork:IsA("BasePart") and tf and tf:IsA("BasePart") then
				moving[forkName] = true
				table.insert(
					l.movers,
					{ part = fork, fork = f, wheel = nil, pin = pin, axle = axle, rest = tf.CFrame }
				)
			end
		end
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") and not moving[p.Name] then
				table.insert(l.rigid, p)
				table.insert(l.rels, frame:ToObjectSpace(p.CFrame))
				table.insert(l.rigidAt, p.CFrame)
			end
		end
		for _, m in l.movers do
			table.insert(l.moverParts, m.part)
			table.insert(l.moverAt, m.part.CFrame)
		end
		for i, c in Specs.Casters do
			local wheel = model:FindFirstChild(c.Wheel)
			local spin = wheel and wheel:FindFirstChild(Cart.Spin)
			l.spins[i] = if spin and spin:IsA("Motor6D") then spin else nil
			l.spin[i] = 0
			local forkName = c.Fork
			if forkName then
				local fork = model:FindFirstChild(forkName)
				local joint = fork and fork:FindFirstChild(Cart.Swivel)
				if fork and fork:IsA("BasePart") and joint and joint:IsA("Motor6D") then
					table.insert(l.swivels, joint)
					local turn = 0
					local tf = template and template:FindFirstChild(forkName)
					if tf and tf:IsA("BasePart") then
						local pin = CFrame.new(c.Kingpin)
						local d = pin:Inverse()
							* frame:ToObjectSpace(fork.CFrame)
							* tf.CFrame:Inverse()
							* pin
						local lv = d.LookVector
						turn = math.atan2(-lv.X, -lv.Z)
					end
					table.insert(l.swivel, turn)
				end
			end
		end
		local at = Instance.new("Attachment")
		at.Name = "CartSounds"
		at.Position = body.CFrame:PointToObjectSpace(frame * Vector3.new(0, 0.5, 0))
		at.Parent = body
		for name, spec in Ride.Sounds do
			l.sounds[name] = sound(spec, at, name == "Roll" or name == "Drag")
		end
		looks[model] = l
	end

	local function remove(model: Instance)
		local l = looks[model :: Model]
		if l then
			for _, s in l.sounds do
				s:Destroy()
			end
			looks[model :: Model] = nil
		end
	end

	-- The rider's body, its joints found once.
	local function riderOf(l: Look): Body?
		local seat = l.seat
		local occupant = seat and seat.Occupant
		if occupant ~= l.occupant then
			-- on or off: a thud on the mat
			if (occupant ~= nil) ~= (l.occupant ~= nil) then
				play(l, "Step", if occupant then 1 else 0.7)
			end
			l.occupant = occupant
			l.rider = nil
			local character = occupant and occupant.Parent
			if character and character:IsA("Model") then
				local joints = {}
				for _, p in POSED do
					local j = Joints.find(character, p[1], p[2])
					if j then
						joints[p[2]] = j
					end
				end
				l.rider = { character = character, joints = joints }
			end
		end
		return l.rider
	end

	local function pose(rider: Body, age: number?, dragging: boolean)
		local j = rider.joints
		local hip, out, knee, dip = Ride.leg(age, dragging)
		local function set(name: string, cf: CFrame)
			local joint = j[name]
			if joint then
				Joints.set(joint, cf)
			end
		end
		set("RightHip", CFrame.Angles(math.rad(hip), 0, math.rad(out)))
		set("RightKnee", CFrame.Angles(math.rad(knee), 0, 0))
		set("LeftHip", CFrame.Angles(math.rad(STAND_HIP), 0, 0))
		set("LeftKnee", CFrame.Angles(math.rad(STAND_KNEE), 0, 0))
		set("Root", CFrame.new(0, dip, 0))
		set("Waist", CFrame.Angles(math.rad(LEAN), 0, 0))
	end

	-- The front casters' turns as they stand now (the server set them parking it).
	local function readTurns(l: Look)
		local frame = l.model:GetPivot()
		for _, m in l.movers do
			local f = m.fork
			if f and not m.wheel then
				local d = m.pin:Inverse()
					* frame:ToObjectSpace(m.part.CFrame)
					* m.rest:Inverse()
					* m.pin
				local lv = d.LookVector
				l.swivel[f] = math.atan2(-lv.X, -lv.Z)
			end
		end
	end

	-- A cart going home: placed where its run has it now, by the server's clock (its casters
	-- and wheels after the rolling, `placeMovers`). Returns its speed along the way, or nil if
	-- it isn't going home.
	local function homeAt(l: Look): number?
		local m = l.model
		local at = m:GetAttribute(Cart.HomeAt)
		if type(at) ~= "number" then
			-- parked: one look a frame
			l.way = nil
			return nil
		end
		local runV = m:GetAttribute(Cart.HomeRun)
		local fromV = m:GetAttribute(Cart.HomeFrom)
		local toV = m:GetAttribute(Cart.HomeTo)
		local shape = m:GetAttribute(Cart.HomeShape)
		if
			not (
				typeof(runV) == "Vector3"
				and typeof(fromV) == "Vector3"
				and typeof(toV) == "Vector3"
				and type(shape) == "number"
			)
		then
			l.way = nil
			return nil
		end
		local way = l.way
		if not way or fromV ~= l.wayFrom or toV ~= l.wayTo or shape ~= l.wayShape then
			way = Home.plan(
				{ x = fromV.X, z = fromV.Z, h = fromV.Y },
				{ x = toV.X, z = toV.Z, h = toV.Y },
				shape
			)
			l.way, l.wayFrom, l.wayTo, l.wayShape = way, fromV, toV, shape
			l.docked = false
			readTurns(l)
		end
		local w = way :: Home.Way
		local run = l.run
		run.from, run.speed, run.to, run.at = runV.X, runV.Y, runV.Z, at
		local s, v, done = Home.at(run, w.length, Workspace:GetServerTimeNow())
		if done and not l.docked and not Home.halting(run, w.length) then
			-- nosed into the rack
			l.docked = true
			play(l, "Dock", 1)
		end
		local x, z, h = Home.pose(w, s)
		local pivot = CFrame.new(x, Lobby.Origin.Position.Y, z) * CFrame.Angles(0, h, 0)
		for i, rel in l.rels do
			l.rigidAt[i] = pivot * rel
		end
		Workspace:BulkMoveTo(l.rigid, l.rigidAt, Enum.BulkMoveMode.FireCFrameChanged)
		return v
	end

	-- A cart going home's casters and wheels, placed by hand by their turns.
	local function placeMovers(l: Look)
		local pivot = l.model:GetPivot()
		for i, m in l.movers do
			local f = m.fork
			local at = pivot
			if f then
				at *= m.pin * CFrame.Angles(0, l.swivel[f], 0) * m.pin:Inverse()
			end
			local w = m.wheel
			if w then
				at *= m.axle * CFrame.Angles(l.spin[w], 0, 0) * m.axle:Inverse()
			end
			l.moverAt[i] = at * m.rest
		end
		Workspace:BulkMoveTo(l.moverParts, l.moverAt, Enum.BulkMoveMode.FireCFrameChanged)
	end

	local function stopRolling(l: Look)
		l.rolling = false
		l.last = nil
		l.speed, l.accel = 0, 0
		l.dragging = false
		l.sounds.Roll:Stop()
		l.sounds.Drag:Stop()
	end

	local function step(dt: number)
		if dt <= 0 then
			return
		end
		local now = os.clock()
		for _, l in looks do
			local rider = riderOf(l)
			local homing: number? = nil
			if l.body.Anchored then
				homing = homeAt(l)
				if not homing then
					if l.rolling then
						stopRolling(l)
					end
					continue
				end
			end
			local frame = l.model:GetPivot()
			local own = l.model == mine and mineState or nil
			local last = l.last
			l.last = frame
			if not l.rolling then
				l.rolling = true
				l.sounds.Roll.Volume = 0
				l.sounds.Roll:Play()
			end
			if not last then
				continue
			end
			-- how it moved: along the handle's way, and its turn
			local v = (frame.Position - last.Position) / dt
			local _, yawNow = frame:ToOrientation()
			local _, yawThen = last:ToOrientation()
			local w = Ride.wrap(yawNow - yawThen) / dt
			local vl = frame:VectorToObjectSpace(Vector3.new(v.X, 0, v.Z))
			local before = l.speed
			if own then
				l.speed = own.speed
			elseif homing then
				-- nose first: against the handle's way; its casters' pace even swinging on the spot
				l.speed = -homing
			else
				l.speed += (vl.Z - l.speed) * math.min(1, dt / SMOOTH)
			end
			local a = (l.speed - before) / dt
			l.accel += (a - l.accel) * math.min(1, dt / SMOOTH)

			-- a friend's cart: what its motion says happened (nobody rides one going home)
			if homing then
				l.dragging = false
			elseif not own then
				if l.accel > SURGE and now - l.kickAt > Ride.KickEvery * 0.6 then
					l.kickAt = now
					play(l, "Scuff", 1)
				end
				if a < SMASH and before > Ride.Nudge * 2 then
					play(l, "Clank", math.clamp(before / Ride.Cap, 0.2, 1))
					l.accel = 0
				end
				l.dragging = l.accel < SLOWING and l.speed > 1
			else
				l.dragging = own.dragging
			end

			-- the wheels: the back pair roll with the cart; the front pair trail their kingpins
			local r = Specs.WheelRadius
			for i, c in Specs.Casters do
				if c.Fork then
					local k = c.Kingpin
					local kx, kz = vl.X + w * k.Z, vl.Z - w * k.X
					local m = math.sqrt(kx * kx + kz * kz)
					l.spin[i] -= m * dt / r
					local f = if c.Wheel == Specs.Casters[1].Wheel then 1 else 2
					if m > 0.25 then
						local want = math.atan2(-kx, -kz)
						local d = Ride.wrap(want - l.swivel[f])
						local most = SWING * dt
						l.swivel[f] = Ride.wrap(
							l.swivel[f] + math.clamp(d * math.min(1, dt * 12), -most, most)
						)
					end
				else
					l.spin[i] += vl.Z * dt / r
				end
			end

			-- the rattle, rising with speed; your foot on the floor
			local volume, pitch = Ride.rumble(math.abs(l.speed))
			local roll = l.sounds.Roll
			local e = math.min(1, dt / SOUND_EASE)
			roll.Volume += (volume - roll.Volume) * e
			roll.PlaybackSpeed += (pitch - roll.PlaybackSpeed) * e
			local drag = l.sounds.Drag
			if l.dragging and not drag.IsPlaying then
				drag.TimePosition = Ride.Sounds.Drag.from
				drag:Play()
			elseif not l.dragging and drag.IsPlaying then
				drag:Stop()
			end

			-- the rider: standing, leaning on the handle, kicking
			if rider then
				local age: number? = nil
				if own then
					age = own.sinceKick
				elseif now - l.kickAt < Ride.KickEvery then
					age = now - l.kickAt + Ride.Reach
				end
				pose(rider, age, l.dragging)
			end
		end
		-- every rolling cart's casters and wheels, by their joints (by hand going home: anchored)
		for _, l in looks do
			if l.rolling and l.body.Anchored then
				placeMovers(l)
			elseif l.rolling then
				for f, joint in l.swivels do
					joint.Transform = CFrame.Angles(0, l.swivel[f], 0)
				end
				for i, joint in l.spins do
					if joint then
						joint.Transform = CFrame.Angles(l.spin[i], 0, 0)
					end
				end
			end
		end
	end

	local function own(model: Model?, state: Ride.State?)
		mine, mineState = model, state
	end

	local function told(model: Model, what: Told, loud: number)
		local l = looks[model]
		if not l then
			return
		end
		if what == "Plant" then
			play(l, "Scuff", 1)
		elseif what == "Clank" then
			play(l, "Clank", math.clamp(0.25 + loud, 0.25, 1))
		elseif what == "Scrape" then
			play(l, "Scrape", math.clamp(0.4 + loud, 0.4, 1))
		end
	end

	local system: Brix.System = {
		name = "CartView",
		start = function(_: any, _context: Brix.Context)
			for _, m in CollectionService:GetTagged(Cart.Tag) do
				add(m)
			end
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Cart.Tag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Cart.Tag):Connect(remove)
			)
			-- after Roblox's animation, before physics: the joints hold through the frame
			table.insert(connections, RunService.PreSimulation:Connect(step))
			local ids = {}
			for _, spec in Ride.Sounds do
				table.insert(ids, spec.id)
			end
			task.spawn(SoundPrimer.prime, ids)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for m in looks do
				remove(m)
			end
		end,
	}
	return system, own, told
end

return CartView
