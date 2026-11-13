--!strict
--[[
	CartRide: riding a platform cart, on your own screen (L-08e4b1, Cart.Ride). Tap Ride and the
	server stands you on the deck facing the handle (its Seat) and hands the cart to this screen;
	from then this screen rolls it, as the server watches its pace (Carts).

	Stepping on: a thud on the mat and your view swings round to the way the cart rolls. Push the
	stick (or W) and it heads where you look: your back leg kicks in rhythm while you hold it,
	each plant a scuff and a dip of your view; at speed the casters shiver under you, your view
	widens a little and leans into turns. Let go and it coasts. A box swept ahead of the cart each
	frame finds what it would meet: head on, a clank, a jolt and a dead stop; at a slant, a scrape
	and a slide along. Turning in place into something doesn't turn. Reach the cars' striped band
	and you hop off onto it. Jump hops you off anywhere, keeping a little of the speed; the cart
	rolls on to a stop on this screen until the server parks it.

	The cart is placed each drawn frame just before the camera follows you, in even steps
	(Ride.advance), and held there before each physics step, as the crawl is (D-118).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Cart = require(ReplicatedStorage.Shared.Cart)
local CameraShake = require(script.Parent.CameraShake)
local CartView = require(script.Parent.CartView)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Ride = require(ReplicatedStorage.Shared.Cart.Ride)

local MOVE = "CartRideMove" -- before the camera follows you
local TURN = "CartRideTurn" -- after it: your view swung round as you step on
local SKIN = 0.05 -- studs kept between the cart and what it met
local LIFT = 0.3 -- the swept box starts this far off the floor, so the floor is never a bump
local HIGH = 3 -- and stands this tall: the deck and the handle
local FOV_BACK = 0.3 -- seconds your view takes to narrow back once you're off
-- A turn that would scrape tries these shuffles back (studs a frame) before it gives up.
local BACK_OFF = { 0, 0.05, 0.12 }

type Mode = "Off" | "Riding" | "Coasting"

local CartRide = {}

local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

function CartRide.new(
	own: (model: Model?, state: Ride.State?) -> (),
	told: (model: Model, what: CartView.Told, loud: number) -> (),
	kick: (amount: number) -> (),
	hold: (pose: CameraShake.Pose?) -> ()
): Brix.System
	local player = Players.LocalPlayer
	local View = Ride.View
	local bounds = Cart.Specs.Parts.Bounds.Size
	local halfW, halfL = bounds.X / 2, bounds.Z / 2
	-- The box swept ahead is a hair inside the cart; the box a turn is checked with is a hair
	-- bigger than that, so a turn that passes never leaves the next sweep starting inside a wall
	-- (a sweep can't see what it starts in: L-08e4b1's cart through the wall)
	local box = Vector3.new(bounds.X, HIGH, bounds.Z) - Vector3.new(0.1, 0.1, 0.1)
	local snug = box + Vector3.new(0.04, 0, 0.04)
	local floorY = Lobby.Origin.Position.Y
	local bandZ = Lobby.Origin.Position.Z - Ride.Band

	local mode: Mode = "Off"
	local cart: Model? = nil
	local body: BasePart? = nil
	local unpivot = CFrame.identity -- the body from the cart's pivot
	local state: Ride.State? = nil
	local pos = Vector3.zero -- the cart's pivot, on the floor
	local placed: CFrame? = nil -- the body where this frame put it
	local float: VectorForce? = nil -- holds the rolling cart up: it touches nothing (Cart.anchor)
	local coastSince = 0
	local dipAt = -math.huge
	local turning = false
	local turnAt, turnFrom, turnTo = 0, 0, 0
	local fovBase: number? = nil
	local fovBackAt: number? = nil
	local hinted = false
	local connections: { RBXScriptConnection } = {}
	local bound = false

	local world = RaycastParams.new()
	world.FilterType = Enum.RaycastFilterType.Exclude
	world.RespectCanCollide = true
	local riders = RaycastParams.new() -- other rolling carts, whose decks don't collide
	riders.FilterType = Enum.RaycastFilterType.Include
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.RespectCanCollide = true
	local decks: { Instance } = {}

	-- The hint, once a session as you first step on.
	local function hint()
		if hinted then
			return
		end
		hinted = true
		local gui = player:FindFirstChildOfClass("PlayerGui")
		if not gui then
			return
		end
		local screen = Instance.new("ScreenGui")
		screen.Name = "CartHint"
		screen.ResetOnSpawn = false
		screen.IgnoreGuiInset = true
		screen.DisplayOrder = 15
		local labels = {}
		for i, words in { View.Hint, View.HintOff } do
			local label = Instance.new("TextLabel")
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = UDim2.fromScale(0.5, if i == 1 then 0.6 else 0.66)
			label.Size = UDim2.new(0.9, 0, 0, if i == 1 then 30 else 24)
			label.BackgroundTransparency = 1
			label.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
			label.TextSize = if i == 1 then 24 else 18
			label.TextColor3 = Lobby.Ink
			label.TextTransparency = 1
			label.Text = words
			local stroke = Instance.new("UIStroke")
			stroke.Color = Color3.new(0, 0, 0)
			stroke.Thickness = 2
			stroke.Transparency = 1
			stroke.Parent = label
			label.Parent = screen
			table.insert(labels, { label = label, stroke = stroke })
		end
		screen.Parent = gui
		local into = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, l in labels do
			TweenService:Create(l.label, into, { TextTransparency = 0 }):Play()
			TweenService:Create(l.stroke, into, { Transparency = 0.4 }):Play()
		end
		task.delay(View.HintFor, function()
			local out = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			for _, l in labels do
				TweenService:Create(l.label, out, { TextTransparency = 1 }):Play()
				TweenService:Create(l.stroke, out, { Transparency = 1 }):Play()
			end
			task.delay(0.6, function()
				screen:Destroy()
			end)
		end)
	end

	-- What your view does on the cart, over Roblox's camera (CameraShake's hold).
	local function viewPose(): CFrame?
		local s = state
		if not s or mode ~= "Riding" then
			return nil
		end
		local t = os.clock()
		local f = math.clamp(s.speed / Ride.Cap, 0, 1)
		local dip = 0
		local since = t - dipAt
		if since < View.DipTime then
			dip = -View.Dip * math.sin(math.pi * since / View.DipTime)
		end
		local sx = View.Shiver * f * math.noise(t * 14, 0.3)
		local sy = View.Shiver * f * math.noise(0.7, t * 17)
		return CFrame.new(sx, dip + sy, 0)
			* CFrame.fromOrientation(dip * 0.08, 0, s.yawRate * View.Lean)
	end

	local function boxAt(at: Vector3, heading: number): CFrame
		return CFrame.new(at.X, floorY + LIFT + HIGH / 2, at.Z) * CFrame.Angles(0, heading, 0)
	end

	-- Whether the cart at `at`, turned to `heading`, would be in something or over the band.
	local function blocked(at: Vector3, heading: number): boolean
		if at.Z + Ride.reachZ(heading, halfW, halfL) > bandZ + 0.01 then
			return true
		end
		local parts = Workspace:GetPartBoundsInBox(boxAt(at, heading), snug, overlap)
		return #parts > 0
	end

	-- The nearest thing the cart's box meets moving `d` from where it stands.
	local function sweep(heading: number, d: Vector3): RaycastResult?
		local from = boxAt(pos, heading)
		local hit = Workspace:Blockcast(from, box, d, world)
		table.clear(decks)
		for _, m in CollectionService:GetTagged(Cart.Tag) do
			if m ~= cart and m:IsA("Model") then
				local deck = m:FindFirstChild(Cart.Deck)
				if deck and deck:IsA("BasePart") and not deck.Anchored then
					table.insert(decks, deck)
				end
			end
		end
		if #decks > 0 then
			riders.FilterDescendantsInstances = decks
			local other = Workspace:Blockcast(from, box, d, riders)
			if other and (not hit or other.Distance < hit.Distance) then
				hit = other
			end
		end
		return hit
	end

	local function finish()
		if float then
			float:Destroy()
			float = nil
		end
		mode = "Off"
		cart, body, state, placed = nil, nil, nil, nil
		turning = false
		own(nil, nil)
		hold(nil)
		ProximityPromptService.Enabled = true
		if fovBase and not fovBackAt then
			fovBackAt = os.clock()
		end
	end

	-- Off the cart: by a jump, the band, a respawn or the server. It rolls on to a stop.
	local function hopOff(atBand: boolean)
		local s = state
		mode = "Coasting"
		coastSince = os.clock()
		turning = false
		hold(nil)
		ProximityPromptService.Enabled = true
		fovBackAt = os.clock()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if atBand and humanoid then
			humanoid.Sit = false
		end
		if root and root:IsA("BasePart") and s then
			-- you step off with a little of its speed, never flung
			local x, z = Ride.way(s.heading)
			local carry = math.min(s.speed, Ride.HopCarry)
			local v = root.AssemblyLinearVelocity
			local up = if atBand then 18 else v.Y
			root.AssemblyLinearVelocity = Vector3.new(x * carry, up, z * carry)
		end
	end

	local function begin(model: Model)
		local b = model:FindFirstChild(Cart.Body)
		if not (b and b:IsA("BasePart")) then
			return
		end
		local character = player.Character
		if not character then
			return
		end
		mode = "Riding"
		cart, body = model, b
		unpivot = b.PivotOffset:Inverse()
		local pivot = model:GetPivot()
		local lv = pivot.LookVector
		local s = Ride.new(Ride.headingOf(-lv.X, -lv.Z)) -- the handle's way
		state = s
		pos = Vector3.new(pivot.Position.X, floorY, pivot.Position.Z)
		if not float then
			local found = b:FindFirstChild("CartFloat")
			local at: Attachment
			if found and found:IsA("Attachment") then
				at = found
			else
				at = Instance.new("Attachment")
				at.Name = "CartFloat"
				at.Parent = b
			end
			local f = Instance.new("VectorForce")
			f.Attachment0 = at
			f.RelativeTo = Enum.ActuatorRelativeTo.World
			f.ApplyAtCenterOfMass = true
			f.Parent = b
			float = f
		end
		world.FilterDescendantsInstances = { character, model }
		overlap.FilterDescendantsInstances = { character, model }
		own(model, s)
		-- your view swings round to the way it rolls
		local camera = Workspace.CurrentCamera
		if camera then
			local look = camera.CFrame.LookVector
			turnFrom, turnTo = Ride.headingOf(look.X, look.Z), s.heading
			turnAt = os.clock()
			turning = true
			fovBase = fovBase or camera.FieldOfView
			fovBackAt = nil
		end
		hold(nil)
		ProximityPromptService.Enabled = false
		hint()
	end

	local function place()
		local s = state
		local b = body
		if not (s and b) then
			return
		end
		local pivot = CFrame.new(pos) * CFrame.Angles(0, s.heading + math.pi, 0)
		local cf = pivot * unpivot
		b.CFrame = cf
		placed = cf
	end

	local function drive(dt: number)
		local s = state
		local m = cart
		if not (s and m) then
			return
		end
		-- the way you push, on the floor: Roblox's controls turn the stick or keys by your view
		-- into the Humanoid's MoveDirection, which still updates while you stand on the seat
		local wx, wz = 0, 0
		if mode == "Riding" then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local d = humanoid.MoveDirection
				wx, wz = d.X, d.Z
			end
		end
		local h0 = s.heading
		local dx, dz, event = Ride.advance(s, wx, wz, dt)
		-- a turn into something, or over the band: it shuffles back a little as it swings, as
		-- you'd pull a cart off a wall; if even that won't clear, it doesn't turn
		if s.heading ~= h0 then
			local bx, bz = Ride.way(h0)
			local free = false
			for _, back in BACK_OFF do
				local tx, tz = dx - bx * back, dz - bz * back
				if not blocked(pos + Vector3.new(tx, 0, tz), s.heading) then
					dx, dz = tx, tz
					free = true
					break
				end
			end
			if not free then
				s.heading, s.yawRate = h0, 0
				dx, dz = bx * s.speed * dt, bz * s.speed * dt
			end
		end
		-- the cars' band: you hop off onto the stripes, the cart stops at their edge
		local reach = Ride.reachZ(s.heading, halfW, halfL)
		local atBand = false
		if dz > 0 and pos.Z + dz + reach > bandZ then
			local allowed = math.max(0, bandZ - reach - pos.Z)
			local f = allowed / dz
			dx, dz = dx * f, dz * f
			s.speed, s.yawRate, s.push = 0, 0, 0
			atBand = true
		end
		-- what's ahead, swept from where it stands as it stood (clear of everything)
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist > 1e-4 then
			local dir = Vector3.new(dx / dist, 0, dz / dist)
			local hit = sweep(h0, dir * dist)
			if hit then
				local n = hit.Normal
				local kind, loud = Ride.hit(s, n.X, n.Z)
				local go = math.max(0, hit.Distance - SKIN)
				dx, dz = dir.X * go, dir.Z * go
				if kind == "Clank" then
					told(m, "Clank", loud)
					if mode == "Riding" then
						kick(View.Jolt * loud)
					end
				elseif kind == "Scrape" then
					told(m, "Scrape", loud)
					if mode == "Riding" then
						kick(View.Jolt * 0.3 * loud)
					end
				end
			end
		end
		-- a bump that cut the move short (or slid it along) leaves the turn checked again there
		if s.heading ~= h0 and blocked(pos + Vector3.new(dx, 0, dz), s.heading) then
			s.heading, s.yawRate = h0, 0
		end
		pos += Vector3.new(dx, 0, dz)
		place()
		if event == "Plant" then
			told(m, "Plant", 0)
			dipAt = os.clock()
		end
		if atBand and mode == "Riding" then
			hopOff(true)
		end
	end

	-- Each drawn frame, before the camera follows you.
	local function frame(dt: number)
		local camera = Workspace.CurrentCamera
		-- your view narrowing back once you're off
		local back = fovBackAt
		if back and fovBase and camera then
			local t = (os.clock() - back) / FOV_BACK
			if t >= 1 then
				camera.FieldOfView = fovBase
				fovBackAt, fovBase = nil, nil
			else
				camera.FieldOfView += (fovBase - camera.FieldOfView) * smooth(t)
			end
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local on: Model? = nil
		if seat and seat.Name == Cart.Seat then
			local m = seat.Parent
			if m and m:IsA("Model") and m:HasTag(Cart.Tag) then
				on = m
			end
		end
		if on then
			if mode ~= "Riding" or cart ~= on then
				begin(on)
			end
		elseif mode == "Riding" then
			hopOff(false)
		end
		local m = cart
		local b = body
		if mode == "Off" or not (m and b) then
			return
		end
		-- the server took it back, or someone else has it, or it's long stopped
		local coast = m:GetAttribute(Cart.CoastAttribute)
		local rider = m:GetAttribute(Cart.RiderAttribute)
		if
			not m.Parent
			or b.Anchored
			or (mode == "Coasting" and (rider ~= nil or (coast ~= nil and coast ~= player.UserId)))
			or (mode == "Coasting" and os.clock() - coastSince > Ride.CoastMax + 1)
		then
			finish()
			return
		end
		drive(dt)
		local s = state
		if mode == "Riding" and s and camera and fovBase then
			local f = math.clamp(s.speed / Ride.Cap, 0, 1)
			camera.FieldOfView = fovBase + View.Widen * f ^ 1.5
		end
	end

	-- After the camera: the swing round as you step on.
	local function turnView()
		if not turning then
			return
		end
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local t = (os.clock() - turnAt) / View.Turn
		local f = if t >= 1 then 1 else smooth(t)
		local look = camera.CFrame.LookVector
		local pitch = math.asin(math.clamp(look.Y, -1, 1))
		local yaw = turnFrom + Ride.wrap(turnTo - turnFrom) * f
		local x, z = Ride.way(yaw)
		local c = math.cos(pitch)
		local eye = camera.CFrame.Position
		camera.CFrame = CFrame.lookAt(eye, eye + Vector3.new(x * c, math.sin(pitch), z * c))
		if t >= 1 then
			turning = false
			hold(viewPose)
		end
	end

	-- Before each physics step: the cart held where the frame put it, rolling as it rolls.
	local function holdCart()
		local b = body
		local cf = placed
		local s = state
		if mode == "Off" or not (b and cf and s) or b.Anchored then
			return
		end
		b.CFrame = cf
		local f = float
		if f then
			-- this screen's own copy, against gravity, for whatever rides on it now
			f.Force = Vector3.new(0, b.AssemblyMass * Workspace.Gravity, 0)
		end
		local x, z = Ride.way(s.heading)
		b.AssemblyLinearVelocity = Vector3.new(x * s.speed, 0, z * s.speed)
		b.AssemblyAngularVelocity = Vector3.new(0, s.yawRate, 0)
	end

	return {
		name = "CartRide",
		start = function(_: any, _context: Brix.Context)
			RunService:BindToRenderStep(MOVE, Enum.RenderPriority.Camera.Value - 2, frame)
			RunService:BindToRenderStep(TURN, Enum.RenderPriority.Camera.Value + 1, turnView)
			bound = true
			table.insert(connections, RunService.PreSimulation:Connect(holdCart))
		end,
		stop = function(_: any)
			if bound then
				RunService:UnbindFromRenderStep(MOVE)
				RunService:UnbindFromRenderStep(TURN)
				bound = false
			end
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			if mode ~= "Off" then
				finish()
			end
		end,
	}
end

return CartRide
