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

	Only rolling carts are stepped. The casters and wheels turn by their joints' Transform before
	physics, after Roblox's animation, like the riders' joints (Joints).
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Cart = require(ReplicatedStorage.Shared.Cart)
local Joints = require(script.Parent.Joints)
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
		}
		-- where its casters stand now, read off the parked pose
		local template = Cart.template()
		local frame = model:GetPivot()
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
			if l.body.Anchored then
				if l.rolling then
					stopRolling(l)
				end
				continue
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
			else
				l.speed += (vl.Z - l.speed) * math.min(1, dt / SMOOTH)
			end
			local a = (l.speed - before) / dt
			l.accel += (a - l.accel) * math.min(1, dt / SMOOTH)

			-- a friend's cart: what its motion says happened
			if not own then
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
		-- every rolling cart's casters and wheels, by their joints
		for _, l in looks do
			if l.rolling then
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
