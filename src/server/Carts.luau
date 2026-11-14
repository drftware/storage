--!strict
--[[
	Carts: the lobby's platform carts on the server (L-08e4b1, GDD "The lobby", Cart.Ride). Each
	parked cart in the rack wears a Ride button on its handle. Tap it and you're stood on its
	deck facing the handle (its hidden Seat), the cart is set free of its anchors and handed to
	your screen, which rolls it (CartRide): your screen moves it, the server watches.

	One rider a cart. The server keeps it honest: every half second it checks the cart hasn't
	gone further than a cart can roll (Ride.tooFast) and is still inside the front office, short
	of the cars' striped band; a cart that fails is taken back where it last passed and its rider
	put off. Jump (or the band) puts you off: the cart rolls on a moment on your screen, then the
	server parks it where it stopped, anchored, its trailing casters as they swung, the button
	back. Leaving, dying or a respawn parks it at once.

	Home again (L-08e4b2, Cart.Home, D-129). A cart parked at the cars' stripes goes home a moment
	later; one parked anywhere else out of the rack goes home after a while. The server picks the
	nearest free slot and a way there clear of walls and parked carts, and sends the way and its
	run once (the cart's Home attributes); every screen rolls the cart along it (CartView), while
	here it stays anchored where it set off. Someone (or a cart) in its way: it brakes and waits,
	then rolls on. Held up too long, or with no way clear, it's put in its slot. No Ride on the
	way home. Arrived, it's anchored in its slot, its casters trailing, the button back.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Cart = require(ReplicatedStorage.Shared.Cart)
local Home = require(ReplicatedStorage.Shared.Cart.Home)
local FrontOffice = require(script.Parent.FrontOffice)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Prompts = require(script.Parent.Prompts)

local Ride = Cart.Ride

-- The button: reached from about a door's reach of the handle.
local REACH = 7
-- A player gets on at most this often (seconds): a hammered button can't flicker a cart.
local MOUNT_GAP = 0.6
-- Where the button sits: just over the handle's grip, clear of the steel for its line of sight.
local BUTTON_RISE = 0.35
-- The way home is checked with the cart's box a hair inside it, lifted clear of the floor and as
-- tall as its deck and handle (as CartRide's sweep).
local LIFT = 0.3
local HIGH = 3
local LOOK_EVERY = 0.1 -- seconds between looks for anyone in a homing cart's way
local SHAPES = { Home.Reach, 0.25, 0.6 } -- the curves tried, in turn, for a way clear of things
local TRY_SLOTS = 3 -- and the nearest free slots tried

type Homing = {
	slot: number,
	way: Home.Way,
	run: Home.Run,
	held: number, -- seconds held up so far, all told
	clearSince: number?, -- os.clock() its way was last seen clear while held
	lookAt: number, -- os.clock() of the last look ahead
}

type Run = {
	model: Model,
	body: BasePart,
	seat: Seat,
	prompt: ProximityPrompt,
	rider: Player?, -- riding it now
	coaster: Player?, -- hopped off; their screen rolls it to a stop
	look: number, -- os.clock() of the last speed look
	lookAt: Vector3, -- where it was then
	good: CFrame, -- its pivot at the last look it passed
	stillAt: Vector3, -- coasting: where it last moved to
	stillSince: number,
	coastSince: number,
	died: RBXScriptConnection?,
	slot: number?, -- the rack's slot it stands in, parked there
	homing: Homing?, -- on its way home
	outSince: number?, -- os.clock() it was parked out of the rack...
	outWait: number, -- ...and how long it stands before it goes home
}

local Carts = {}

local floorY = Lobby.Origin.Position.Y
local bounds = Cart.Specs.Parts.Bounds.Size
local halfW, halfL = bounds.X / 2, bounds.Z / 2
local snug = Vector3.new(bounds.X - 0.1, HIGH, bounds.Z - 0.1) -- a way clear of things
local roomy = Vector3.new(bounds.X + 0.3, HIGH, bounds.Z + 0.3) -- anyone in the way

-- A pose on the floor (Cart.Home) from a cart's pivot, and back.
local function poseOf(at: CFrame): Home.Pose
	local p, look = at.Position, at.LookVector
	return { x = p.X, z = p.Z, h = Ride.headingOf(look.X, look.Z) }
end

local function frameOf(p: Home.Pose): CFrame
	return CFrame.new(p.x, floorY, p.z) * CFrame.Angles(0, p.h, 0)
end

-- What a pose sent in an attribute (a Vector3 of x, heading, z) reads back as on every screen.
local function sent(p: Home.Pose): (Vector3, Home.Pose)
	local v = Vector3.new(p.x, p.h, p.z)
	return v, { x = v.X, z = v.Z, h = v.Y }
end

local function boxAt(x: number, z: number, h: number): CFrame
	return CFrame.new(x, floorY + LIFT + HIGH / 2, z) * CFrame.Angles(0, h, 0)
end

-- Whether a cart parked at `at` stands at the cars' stripes (within a stud of their edge).
local function atBand(at: CFrame): boolean
	local l = Lobby.Origin:ToObjectSpace(at)
	local look = l.LookVector
	local h = Ride.headingOf(look.X, look.Z)
	return l.Position.Z + Ride.reachZ(h, halfW, halfL) >= -Ride.Band - 1
end

-- A pivot stood level on the lobby's floor, keeping only its turn about Y.
local function level(at: CFrame): CFrame
	local look = at.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local p = at.Position
	return CFrame.new(p.X, Lobby.Origin.Position.Y, p.Z) * CFrame.Angles(0, yaw, 0)
end

-- Whether a cart's middle at `p` is inside the front office, short of the cars' band (with a
-- stud's slack for the network).
local function inside(p: Vector3): boolean
	local l = Lobby.Origin:PointToObjectSpace(p)
	local room = Lobby.Specs.Room
	return math.abs(l.X) <= room.Width / 2
		and l.Z >= -room.Depth
		and l.Z <= -Ride.Band + 1
		and math.abs(l.Y) <= 2
end

function Carts.new(): Brix.System
	local runs: { [Model]: Run } = {}
	local riding: { [Player]: Run } = {}
	local mounted: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local slots: { Home.Pose } = {} -- the rack's slots, where each cart was first parked
	local slotFrames: { CFrame } = {}
	-- the world a way home must be clear of (carts and people are checked apart)
	local statics = OverlapParams.new()
	statics.FilterType = Enum.RaycastFilterType.Exclude
	statics.RespectCanCollide = true
	local people = OverlapParams.new()
	people.FilterType = Enum.RaycastFilterType.Include
	local bodies: { Instance } = {}

	-- Every character in the game now.
	local function characters(): { Instance }
		table.clear(bodies)
		for _, p in Players:GetPlayers() do
			local c = p.Character
			if c then
				table.insert(bodies, c)
			end
		end
		return bodies
	end

	-- Where a cart stands now: going home, where its run has it; else its pivot here.
	local function poseNow(r: Run): Home.Pose
		local h = r.homing
		if h then
			local s = Home.at(h.run, h.way.length, Workspace:GetServerTimeNow())
			local x, z, hh = Home.pose(h.way, s)
			return { x = x, z = z, h = hh }
		end
		return poseOf(r.model:GetPivot())
	end

	-- Sends a homing cart's run to every screen.
	local function publish(r: Run, run: Home.Run)
		local h = r.homing
		if not h then
			return
		end
		h.run = run
		r.model:SetAttribute(Cart.HomeRun, Vector3.new(run.from, run.speed, run.to))
		r.model:SetAttribute(Cart.HomeAt, run.at)
	end

	-- No longer going home: its Home attributes cleared (the run first: screens key on it).
	local function unhome(r: Run)
		r.homing = nil
		r.model:SetAttribute(Cart.HomeAt, nil)
		r.model:SetAttribute(Cart.HomeRun, nil)
		r.model:SetAttribute(Cart.HomeFrom, nil)
		r.model:SetAttribute(Cart.HomeTo, nil)
		r.model:SetAttribute(Cart.HomeShape, nil)
	end

	local function unseat(r: Run)
		local weld = r.seat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
	end

	local function release(r: Run)
		local died = r.died
		if died then
			died:Disconnect()
			r.died = nil
		end
		for _, p in { r.rider, r.coaster } do
			if p and riding[p] == r then
				riding[p] = nil
			end
		end
		r.rider, r.coaster = nil, nil
	end

	-- A parked cart: in a slot, or out (and so, after a while, going home).
	local function settle(r: Run)
		local p = poseOf(r.model:GetPivot())
		r.slot = nil
		for i, s in slots do
			if Home.slotted(p, s) then
				r.slot = i
				break
			end
		end
		if r.slot then
			r.outSince = nil
		else
			r.outSince = os.clock()
			r.outWait = if atBand(r.model:GetPivot()) then Home.BandWait else Home.Wait
		end
	end

	-- Stands the cart where `at` says (or where it is), anchored, ready for the next rider.
	local function park(r: Run, at: CFrame?)
		release(r)
		unseat(r)
		local wasHoming = r.homing
		if wasHoming then
			-- stopped on its way home: where its run has it now
			at = frameOf(poseNow(r))
			unhome(r)
		end
		Cart.anchor(r.model, true)
		local where = level(at or r.model:GetPivot())
		r.model:PivotTo(where)
		-- ridden handle first, its trailing casters swung round behind them; pushed home nose
		-- first, trailing the other way
		Cart.swivel(r.model, if wasHoming then { 0, 0 } else { 180, 180 })
		r.good = where
		r.model:SetAttribute(Cart.RiderAttribute, nil)
		r.model:SetAttribute(Cart.CoastAttribute, nil)
		r.prompt.Enabled = true
		settle(r)
	end

	-- Home: anchored in slot `i` as it was first parked, its casters trailing as pushed in.
	local function arrive(r: Run, i: number)
		unhome(r)
		Cart.anchor(r.model, true)
		local where = slotFrames[i]
		r.model:PivotTo(where)
		Cart.swivel(r.model, { 0, 0 })
		r.good = where
		r.prompt.Enabled = true
		r.slot = i
		r.outSince = nil
	end

	-- Whether slot `i` is free for `r`: no other cart in it, going home to it, or standing over it.
	local function slotFree(r: Run, i: number): boolean
		local s = slots[i]
		for _, o in runs do
			if o ~= r then
				local h = o.homing
				if o.slot == i or (h and h.slot == i) then
					return false
				end
				if not h and Home.meet(s, poseNow(o), halfW, halfL) then
					return false
				end
			end
		end
		return true
	end

	-- Whether nobody stands in slot `i` (to put a cart straight into it).
	local function slotEmpty(i: number): boolean
		local s = slots[i]
		people.FilterDescendantsInstances = characters()
		return #Workspace:GetPartBoundsInBox(boxAt(s.x, s.z, s.h), roomy, people) == 0
	end

	-- Whether a way home is clear of walls, the rack and parked carts, up to its run straight in
	-- (the slot's own line, clear by the rack's making).
	local function wayClear(r: Run, way: Home.Way): boolean
		local skip: { Instance } = {}
		for m in runs do
			table.insert(skip, m)
		end
		for _, c in characters() do
			table.insert(skip, c)
		end
		statics.FilterDescendantsInstances = skip
		local s = 0
		while true do
			local x, z, h = Home.pose(way, s)
			if #Workspace:GetPartBoundsInBox(boxAt(x, z, h), snug, statics) > 0 then
				return false
			end
			local p = { x = x, z = z, h = h }
			for _, o in runs do
				if o ~= r and not (o.homing or o.rider or o.coaster) then
					if Home.meet(p, poseOf(o.model:GetPivot()), halfW - 0.05, halfL - 0.05) then
						return false
					end
				end
			end
			if s >= way.inFrom then
				return true
			end
			s = math.min(s + 1, way.inFrom)
		end
	end

	-- Sets a parked cart off home: the nearest free slot it has a clear way to.
	local function goHome(r: Run)
		r.outSince = nil
		local fromV, from = sent(poseOf(r.model:GetPivot()))
		local free = {}
		for i in slots do
			if slotFree(r, i) then
				table.insert(free, i)
			end
		end
		local function far(i: number): number
			local s = slots[i]
			return (s.x - from.x) ^ 2 + (s.z - from.z) ^ 2
		end
		table.sort(free, function(a: number, b: number): boolean
			return far(a) < far(b)
		end)
		for n = 1, math.min(#free, TRY_SLOTS) do
			local i = free[n]
			local toV, to = sent(slots[i])
			for _, reach in SHAPES do
				local way = Home.plan(from, to, reach)
				if wayClear(r, way) then
					r.slot = nil
					r.homing = {
						slot = i,
						way = way,
						run = Home.start(way.length, Workspace:GetServerTimeNow()),
						held = 0,
						clearSince = nil,
						lookAt = os.clock(),
					}
					r.prompt.Enabled = false
					r.model:SetAttribute(Cart.HomeFrom, fromV)
					r.model:SetAttribute(Cart.HomeTo, toV)
					r.model:SetAttribute(Cart.HomeShape, reach)
					publish(r, (r.homing :: Homing).run)
					return
				end
			end
		end
		-- boxed in: straight into the nearest free slot if nobody's in it; else wait again
		local first = free[1]
		if first and slotEmpty(first) then
			warn(`Carts: {r.model.Name} has no way home, put in slot {first}`)
			arrive(r, first)
		else
			r.outSince, r.outWait = os.clock(), Home.Wait
		end
	end

	-- Whether anyone, or any other cart, stands just ahead of a homing cart at `s` along its way.
	local function inWay(r: Run, h: Homing, s: number): boolean
		people.FilterDescendantsInstances = characters()
		local length = h.way.length
		for _, ahead in Home.Look do
			local x, z, hh = Home.pose(h.way, math.min(s + ahead, length))
			if #Workspace:GetPartBoundsInBox(boxAt(x, z, hh), roomy, people) > 0 then
				return true
			end
			local p = { x = x, z = z, h = hh }
			for _, o in runs do
				if o ~= r and Home.meet(p, poseNow(o), halfW, halfL) then
					return true
				end
			end
		end
		return false
	end

	-- A homing cart's moment: home yet; anyone in its way (brake, wait, roll on); held too long.
	local function homeStep(r: Run, h: Homing, t: number)
		local now = Workspace:GetServerTimeNow()
		local length = h.way.length
		local s, _, done = Home.at(h.run, length, now)
		local halting = Home.halting(h.run, length)
		if done and not halting then
			arrive(r, h.slot)
			return
		end
		if t - h.lookAt < LOOK_EVERY then
			return
		end
		if halting then
			h.held += t - h.lookAt
		end
		h.lookAt = t
		if inWay(r, h, s) then
			h.clearSince = nil
			if not halting then
				publish(r, Home.halt(h.run, length, now))
			end
		elseif halting then
			h.clearSince = h.clearSince or t
			if t - (h.clearSince :: number) >= Home.Clear then
				h.clearSince = nil
				publish(r, Home.go(h.run, length, now))
			end
		end
		if h.held >= Home.GiveUp then
			-- held up too long: into its slot if nobody's in it, else it stands where it stopped
			if slotEmpty(h.slot) and slotFree(r, h.slot) then
				arrive(r, h.slot)
			else
				park(r)
			end
		end
	end

	local function alive(player: Player): (Humanoid?, BasePart?)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return humanoid, root
		end
		return nil, nil
	end

	local function mount(r: Run, player: Player)
		-- range: a parked cart, a free, living player in reach, not too soon after their last
		if r.rider or r.coaster or r.homing or not r.body.Anchored or riding[player] then
			return
		end
		if Prompts.wrapped(player) then
			return
		end
		local humanoid, root = alive(player)
		if not (humanoid and root) or humanoid.SeatPart then
			return
		end
		local t = os.clock()
		if t - (mounted[player] or -math.huge) < MOUNT_GAP then
			return
		end
		local button = r.prompt.Parent
		if not (button and button:IsA("Attachment")) then
			return
		end
		if (root.Position - button.WorldPosition).Magnitude > REACH + 3 then
			return
		end
		mounted[player] = t
		-- stood on the mat facing the handle, whatever the body's size: put there first, so
		-- the seat's weld finds you where it holds you and the cart stays in its slot
		local hip = if humanoid.RigType == Enum.HumanoidRigType.R15
			then humanoid.HipHeight + root.Size.Y / 2
			else 3
		local stand = r.seat.CFrame * CFrame.new(0, hip, 0)
		local character = player.Character :: Model
		character:PivotTo(stand * root.CFrame:ToObjectSpace(character:GetPivot()))
		Cart.anchor(r.model, false)
		r.seat:Sit(humanoid)
		local weld = r.seat:FindFirstChild("SeatWeld")
		if not (weld and weld:IsA("Weld")) then
			Cart.anchor(r.model, true)
			return
		end
		weld.C0 = CFrame.new(0, hip, 0)
		weld.C1 = CFrame.identity
		r.body:SetNetworkOwner(player)
		r.rider = player
		r.slot, r.outSince = nil, nil
		riding[player] = r
		local p = r.body.Position
		r.look, r.lookAt = t, p
		r.good = level(r.model:GetPivot())
		r.died = humanoid.Died:Connect(function()
			park(r)
		end)
		r.prompt.Enabled = false
		r.model:SetAttribute(Cart.CoastAttribute, nil)
		r.model:SetAttribute(Cart.RiderAttribute, player.UserId)
	end

	-- The seat lost its rider: a jump, the band, a respawn or a leave.
	local function seatChanged(r: Run)
		local occupant = r.seat.Occupant
		local rider = r.rider
		if occupant then
			-- only Ride seats anyone; anyone else is put off
			local owner = rider and rider.Character
			if not (owner and occupant.Parent == owner) then
				unseat(r)
			end
			return
		end
		if not rider then
			return
		end
		local humanoid = alive(rider)
		if not (humanoid and rider.Parent) or r.body.Anchored then
			park(r)
			return
		end
		-- they hopped off: their screen rolls it on to a stop
		r.rider = nil
		r.coaster = rider
		local t = os.clock()
		r.coastSince, r.stillSince, r.stillAt = t, t, r.body.Position
		r.model:SetAttribute(Cart.RiderAttribute, nil)
		r.model:SetAttribute(Cart.CoastAttribute, rider.UserId)
	end

	local function add(model: Model)
		if runs[model] then
			return
		end
		local body = model:FindFirstChild(Cart.Body)
		if not (body and body:IsA("BasePart")) then
			return
		end
		Cart.rig(model)
		local found = model:FindFirstChild(Cart.Seat)
		if not (found and found:IsA("Seat")) then
			return
		end
		local seat = found
		local button = Instance.new("Attachment")
		button.Name = "RideButton"
		button.Parent = body
		button.WorldCFrame = model:GetPivot()
			* CFrame.new(Cart.Specs.Handle + Vector3.new(0, BUTTON_RISE, 0))
		local prompt = Prompts.make(button, {
			actionText = "Ride",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = REACH,
		})
		local t = os.clock()
		local r: Run = {
			model = model,
			body = body,
			seat = seat,
			prompt = prompt,
			rider = nil,
			coaster = nil,
			look = t,
			lookAt = body.Position,
			good = level(model:GetPivot()),
			stillAt = body.Position,
			stillSince = t,
			coastSince = t,
			died = nil,
			slot = nil,
			homing = nil,
			outSince = nil,
			outWait = Home.Wait,
		}
		runs[model] = r
		-- Cart{i} was laid in slot i: that's the slot, as it was parked
		local i = tonumber(model.Name:match("%d+$"))
		if i then
			slotFrames[i] = model:GetPivot()
			slots[i] = poseOf(slotFrames[i])
			r.slot = i
		end
		table.insert(
			connections,
			prompt.Triggered:Connect(function(player: Player)
				mount(r, player)
			end)
		)
		table.insert(
			connections,
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				seatChanged(r)
			end)
		)
		model:AddTag(Cart.Tag)
	end

	local function gone(player: Player)
		mounted[player] = nil
		local r = riding[player]
		if r then
			park(r)
		end
	end

	return {
		name = "Carts",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back a plain System; FrontOffice fills this slot (init.server)
			local office = (context.registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice
			local laid = office:laid()
			if not laid then
				return
			end
			local dressing = laid.folder:FindFirstChild("Dressing")
			if not dressing then
				return
			end
			for _, m in dressing:GetChildren() do
				if m:IsA("Model") and m.Name:match("^Cart%d+$") then
					add(m)
				end
			end
			table.insert(connections, Players.PlayerRemoving:Connect(gone))
		end,
		-- Only carts out of the rack: a ride's pace and place checked, a coast's end found; a cart
		-- standing out sent home; a homing cart's way watched.
		step = function(_: any, _dt: number)
			local t = os.clock()
			for _, r in runs do
				local h = r.homing
				if h then
					homeStep(r, h, t)
					continue
				end
				if not (r.rider or r.coaster) then
					local out = r.outSince
					if out and t - out >= r.outWait then
						goHome(r)
					end
					continue
				end
				local p = r.body.Position
				if t - r.look >= Ride.CheckEvery then
					local d = Vector3.new(p.X - r.lookAt.X, 0, p.Z - r.lookAt.Z).Magnitude
					if Ride.tooFast(d, t - r.look) or not inside(r.model:GetPivot().Position) then
						-- too far, too fast, or out of the room: back where it last passed
						local who = r.rider or r.coaster
						warn(`Carts: {r.model.Name} taken back from {who and who.Name or "?"}`)
						park(r, r.good)
						continue
					end
					r.look, r.lookAt = t, p
					r.good = level(r.model:GetPivot())
				end
				if r.coaster then
					if (p - r.stillAt).Magnitude > 0.05 then
						r.stillAt, r.stillSince = p, t
					elseif t - r.stillSince >= Ride.StillFor then
						park(r)
						continue
					end
					if t - r.coastSince >= Ride.CoastMax then
						park(r)
					end
				end
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, r in runs do
				local h = r.homing
				if h then
					arrive(r, h.slot)
				elseif r.rider or r.coaster then
					park(r)
				end
				r.model:RemoveTag(Cart.Tag)
			end
			table.clear(runs)
		end,
	}
end

return Carts
