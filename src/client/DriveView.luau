--!strict
--[[
	Client system: the RC car on this screen (F-G1b3c2c, D-252).

	Yours: Drive (the round button, a click, L2; `press`) clicks the transmitter and the server sets
	the car down. When the server says you drive it (its `Driver`), Brix's Driving takes your move
	stick (keys, a gamepad, a phone's thumbstick, through `Drive.controls`) and steers the car from
	this device, and your view swoops down onto its hood, low and wide (`Drive.Drop`), riding it
	from there: a ramp tilts it, a bump or a wall jolts it (CameraShake), and a move the server
	put back (`PutBack`) jolts it hard. Back is the jump button, as Roblox's own vehicle seats are
	left, or the Back button top left: your view is back in your own eyes, the car stays where it
	is. While your car is out, the transmitter in your view's hand has no car on it; while you
	drive, your view's hand is hidden (it's back at your body).

	Everyone's: each car out turns its wheels as it rolls and points its front wheels into a turn
	(yours from your stick, at once; a friend's from how it turns), leans on its springs, and
	whines while someone drives it, rising with speed. A car taken back clacks into its
	transmitter, which is posed whole again.
]]
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Catalog = require(ReplicatedStorage.Shared.Tools.Catalog)
local Drive = require(ReplicatedStorage.Shared.Finds.Drive)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Pose = require(ReplicatedStorage.Shared.Finds.Pose)
local ToolView = require(script.Parent.ToolView)
local Tools = require(ReplicatedStorage.Shared.Tools)

local player = Players.LocalPlayer

-- Studs from your view past which a car's wheels, springs and whine aren't kept up.
local NEAR = 90
-- Seconds after a drive starts in which a jump isn't Back (the press that started it).
local BACK_AFTER = 0.3
-- The springs: the most they lean (degrees), and how fast they settle on it (per second).
local LEAN_MOST = 5
local LEAN_RATE = 10
-- How fast the front wheels follow the steer (per second): `Drive.Handling.steerTime`'s ease.
local STEER_RATE = 1 / Drive.Handling.steerTime * 3
local BACK_ACTION = "DriveBack"
-- Studs over your root Roblox's first-person view rides (`Kneel.CameraOverRoot`): where `leave`
-- puts your view.
local EYE = 1.5
-- Studio only: the player attribute a test steers with, the stick as a Vector3 (x right, z back)
local STICK = "DriveStick"

type Car = {
	model: Model,
	parts: { BasePart }, -- its parts, to find their find again once it's taken back
	spin: { [string]: number }, -- each wheel's turn so far, degrees
	steer: number, -- the front wheels' angle now, degrees, right positive
	pitch: number,
	roll: number,
	speed: number, -- last frame's speed ahead
	velocity: Vector3, -- last frame's velocity (the driver's jolt)
	whine: Sound?,
	pitchNow: number,
	values: Pose.Values,
}

type Driving = {
	car: Car,
	hull: BasePart,
	wheels: Brix.DrivingClient,
	steer: number, -- the stick's steer, as last read
	since: number, -- os.clock as it started
	from: CFrame, -- your view as it started, for the swoop
	fromFov: number,
	savedType: Enum.CameraType,
	savedFov: number,
	view: CFrame?, -- the hood's view as last drawn
	putBack: number, -- the last put back seen, server clock
}

export type Api = {
	-- a press of Drive with the RC car in hand: true if the server should be told
	press: () -> boolean,
	-- whether a press would do anything now (not while you drive)
	can: () -> boolean,
	-- whether your view is on the car you drive (DriverBodies shows your body then)
	viewing: () -> boolean,
	-- caught (CaughtView, before the lunge takes your view): out of the car at once, your view
	-- back in your head, so the lunge turns you from your own eyes to what caught your body
	leave: () -> (),
}

local DriveView = {}

local function alive(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function hullOf(model: Model): BasePart?
	local hull = model:FindFirstChild(Drive.HullName)
	return if hull and hull:IsA("BasePart") then hull else nil
end

local function approach(now: number, goal: number, rate: number, dt: number): number
	return goal + (now - goal) * math.exp(-rate * dt)
end

function DriveView.new(hand: ToolView.Hand, kick: (amount: number) -> ()): (Brix.System, Api)
	local art = Finds.art(Drive.Key)
	local spec = art and art.Drive
	local carNames: { string } = if art then Drive.carParts(art) else {}
	local handling = Brix.Handling.car(Drive.Handling)
	local cars: { [Model]: Car } = {}
	local connections: { RBXScriptConnection } = {}
	local driving: Driving? = nil
	local backRemote: RemoteEvent? = nil
	local gui: ScreenGui? = nil
	local shownView: Model? = nil -- your view's copy as last hidden or shown
	local shownHidden = -1 -- 0 whole, 1 car hidden, 2 all hidden

	local function click()
		local character = player.Character
		local held = character and character:FindFirstChild(Tools.HeldName)
		local body = held and held:IsA("Model") and Tools.body(held)
		local row = Catalog[Drive.Key]
		if body and row then
			Tools.play(row.pickUp, body, 30)
		end
	end

	local function stopDriving(told: boolean)
		local d = driving
		if not d then
			return
		end
		driving = nil
		if not told and d.hull.Parent then
			-- yours to move till the server takes it: stopped, so it doesn't slide on
			d.hull.AssemblyLinearVelocity = Vector3.zero
			d.hull.AssemblyAngularVelocity = Vector3.zero
		end
		d.wheels:stop()
		ContextActionService:UnbindAction(BACK_ACTION)
		local camera = Workspace.CurrentCamera
		if camera then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			camera.CameraType = if d.savedType == Enum.CameraType.Scriptable
				then Enum.CameraType.Custom
				else d.savedType
			if humanoid then
				camera.CameraSubject = humanoid
			end
			camera.FieldOfView = d.savedFov
		end
		local g = gui
		if g then
			g.Enabled = false
		end
	end

	local function back()
		local d = driving
		if not d or os.clock() - d.since < BACK_AFTER then
			return
		end
		local r = backRemote
		if r then
			r:FireServer()
		end
		click()
		stopDriving(false)
	end

	local function startDriving(car: Car)
		local hull = hullOf(car.model)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local camera = Workspace.CurrentCamera
		if driving or not (hull and humanoid and camera) then
			return
		end
		local d: Driving
		local wheels = Brix.Roblox.Driving.client({
			body = car.model,
			handling = handling,
			frames = RunService.PreSimulation,
			humanoid = humanoid,
			-- the stick: this place's PlayerModule hands out no move vector (docs/STUDIO.md), so
			-- the Humanoid's MoveDirection, which Roblox turns by your view, turned back by the
			-- hood's facing (as CartRide reads it)
			input = function(): vector
				-- Studio only: a test steers by setting the player's `DriveStick` (Studio's
				-- simulated keys don't reliably reach the game)
				if RunService:IsStudio() then
					local stick = player:GetAttribute(STICK)
					if typeof(stick) == "Vector3" then
						return vector.create(stick.X, 0, stick.Z)
					end
				end
				local view = Workspace.CurrentCamera
				if not view then
					return vector.zero
				end
				local push = humanoid.MoveDirection
				local look = view.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z)
				if flat.Magnitude < 1e-3 then
					return vector.zero
				end
				flat = flat.Unit
				local right = Vector3.new(-flat.Z, 0, flat.X)
				return vector.create(push:Dot(right), 0, -push:Dot(flat))
			end,
			controls = function(move: vector): (number, number)
				local throttle, steer = Drive.controls(move.x, move.z)
				d.steer = steer
				return throttle, steer
			end,
		})
		d = {
			car = car,
			hull = hull,
			wheels = wheels,
			steer = 0,
			since = os.clock(),
			from = camera.CFrame,
			fromFov = camera.FieldOfView,
			savedType = camera.CameraType,
			savedFov = camera.FieldOfView,
			view = nil,
			putBack = Workspace:GetServerTimeNow(),
		}
		driving = d
		wheels:start()
		ContextActionService:BindAction(BACK_ACTION, function(_, state: Enum.UserInputState)
			if state == Enum.UserInputState.Begin then
				back()
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.Backspace)
		local g = gui
		if g then
			g.Enabled = true
		end
	end

	-- The server says who drives `car`: you, someone else, or nobody.
	local function onDriver(car: Car)
		local driver = car.model:GetAttribute(Drive.DriverAttribute)
		local d = driving
		if driver == player.UserId then
			if not d then
				startDriving(car)
			end
		elseif d and d.car == car then
			stopDriving(true)
		end
	end

	local function addCar(model: Model)
		if cars[model] or not model:IsA("Model") then
			return
		end
		local parts: { BasePart } = {}
		for _, name in carNames do
			local part = model:WaitForChild(name, 5)
			if part and part:IsA("BasePart") then
				table.insert(parts, part)
			end
		end
		if model.Parent == nil then
			return
		end
		local car: Car = {
			model = model,
			parts = parts,
			spin = {},
			steer = 0,
			pitch = 0,
			roll = 0,
			speed = 0,
			velocity = Vector3.zero,
			whine = nil,
			pitchNow = Drive.IdlePitch,
			values = {},
		}
		local hull = hullOf(model)
		if hull then
			local whine = Tools.sound(Drive.Whine, hull, Drive.Reach)
			whine.Looped = true
			whine.LoopRegion =
				NumberRange.new(Drive.Whine.from, Drive.Whine.from + Drive.Whine.length)
			car.whine = whine
		end
		cars[model] = car
		table.insert(
			connections,
			model:GetAttributeChangedSignal(Drive.DriverAttribute):Connect(function()
				onDriver(car)
			end)
		)
		onDriver(car)
	end

	local function removeCar(model: Instance)
		local car = cars[model :: Model]
		if not car then
			return
		end
		cars[model :: Model] = nil
		local d = driving
		if d and d.car == car then
			stopDriving(true)
		end
		if car.whine then
			car.whine:Destroy()
		end
		-- taken back: once its parts are in their find, the find stands whole again, clacking
		task.defer(function()
			local part = car.parts[1]
			local find = part and part.Parent
			if find and find:IsA("Model") and find ~= model then
				Finds.joints(find, Drive.Key, Finds.rest(Drive.Key), 1, false)
				local body = Tools.body(find)
				local row = Catalog[Drive.Key]
				if body and row then
					Tools.play(row.pickUp, body, 40)
				end
			end
		end)
	end

	-- Each wheel, knuckle and the springs of `car` posed at its speed and turn this frame.
	local function pose(car: Car, speed: number, steer: number, turn: number, dt: number)
		if not spec then
			return
		end
		local values = car.values
		for _, wheel in spec.Wheels do
			local spin = ((car.spin[wheel.Part] or 0) + Drive.spin(speed * dt, wheel.Radius)) % 360
			car.spin[wheel.Part] = spin
			local v: { [string]: number } = values[wheel.Part] or {}
			v.turn = spin
			values[wheel.Part] = v
			if wheel.Steer then
				local k: { [string]: number } = values[wheel.Steer] or {}
				k.turn = -steer -- about its kingpin, which points up: a right turn is clockwise
				values[wheel.Steer] = k
			end
		end
		local ahead = (speed - car.speed) / math.max(dt, 1e-3)
		local pitch = math.clamp(ahead * spec.Pitch, -LEAN_MOST, LEAN_MOST)
		local roll = math.clamp(speed * turn * spec.Roll, -LEAN_MOST, LEAN_MOST)
		car.pitch = approach(car.pitch, pitch, LEAN_RATE, dt)
		car.roll = approach(car.roll, roll, LEAN_RATE, dt)
		local sprung: { [string]: number } = values[spec.Sprung] or {}
		sprung.pitch = car.pitch
		sprung.roll = car.roll
		values[spec.Sprung] = sprung
		Finds.joints(car.model, Drive.Key, values, 1, false)
	end

	-- Your view's copy of the transmitter: no car on it while yours is out, nothing while you drive.
	local function hideView()
		local view, key = hand.model()
		local character = player.Character
		local held = character and character:FindFirstChild(Tools.HeldName)
		local out = held ~= nil and held:GetAttribute(Drive.OutAttribute) == true
		local hidden = if driving then 2 elseif key == Drive.Key and out then 1 else 0
		if view == shownView and hidden == shownHidden then
			return
		end
		shownView, shownHidden = view, hidden
		if not view then
			return
		end
		local isCar: { [string]: boolean } = {}
		if key == Drive.Key then
			for _, name in carNames do
				isCar[name] = true
			end
		end
		for _, part in view:GetDescendants() do
			if part:IsA("BasePart") then
				local hide = hidden == 2 or (hidden == 1 and isCar[part.Name] == true)
				part.LocalTransparencyModifier = if hide then 1 else 0
			end
		end
	end

	-- Your view on the hood of the car you drive.
	local function hood(d: Driving, dt: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local hull = d.hull
		local target = hull.CFrame
			* CFrame.new(0, Drive.HoodUp - Drive.HullHeight / 2, Drive.HoodAhead)
			* CFrame.Angles(-math.rad(Drive.HoodDown), 0, 0)
		local rot = target.Rotation
		local was = d.view
		if was then
			rot = was.Rotation:Lerp(target.Rotation, 1 - math.exp(-Drive.Settle * dt))
		end
		local view = rot + target.Position
		d.view = view
		camera.CameraType = Enum.CameraType.Scriptable
		local t = (os.clock() - d.since) / Drive.Drop
		if t < 1 then
			local e = 1 - (1 - t) * (1 - t) * (1 - t)
			camera.CFrame = d.from:Lerp(view, e)
			camera.FieldOfView = d.fromFov + (Drive.Fov - d.fromFov) * e
		else
			camera.CFrame = view
			camera.FieldOfView = Drive.Fov
		end
		-- a bump or a wall: the speed lost (or a fall stopped) this frame
		local velocity = hull.AssemblyLinearVelocity
		local lost = (d.car.velocity - velocity).Magnitude
		local jolt = Drive.jolt(lost)
		if jolt and t >= 1 then
			kick(jolt)
		end
		local put = d.car.model:GetAttribute(Drive.PutBackAttribute)
		if type(put) == "number" and put > d.putBack then
			d.putBack = put
			if Workspace:GetServerTimeNow() - put < Drive.Fresh then
				kick(Drive.PutBackJolt)
			end
		end
	end

	local function makeGui()
		local pg = player:WaitForChild("PlayerGui")
		local g = Instance.new("ScreenGui")
		g.Name = "DriveBack"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = false
		g.Enabled = false
		g.DisplayOrder = 5
		local b = Instance.new("TextButton")
		b.Name = "Back"
		b.Text = "Back"
		b.AutoButtonColor = true
		b.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
		b.TextSize = 20
		b.TextColor3 = Color3.new(1, 1, 1)
		b.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
		b.BackgroundTransparency = 0.45
		b.Size = UDim2.fromOffset(92, 44)
		b.Position = UDim2.fromOffset(12, 12)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = b
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 0.6
		stroke.Thickness = 1.5
		stroke.Parent = b
		b.Parent = g
		b.Activated:Connect(back)
		g.Parent = pg
		gui = g
	end

	local api: Api = {
		press = function(): boolean
			if driving or not alive() then
				return false
			end
			click()
			return true
		end,
		can = function(): boolean
			return driving == nil and alive()
		end,
		viewing = function(): boolean
			return driving ~= nil
		end,
		leave = function()
			if not driving then
				return
			end
			stopDriving(false)
			local camera = Workspace.CurrentCamera
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if camera and root and root:IsA("BasePart") then
				local look = root.CFrame.LookVector
				local eye = root.Position + Vector3.new(0, EYE, 0)
				camera.CFrame = CFrame.lookAt(eye, eye + Vector3.new(look.X, 0, look.Z))
			end
		end,
	}

	local system = { name = "DriveView" }

	function system.start(_: any)
		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(Drive.RemoteFolder, 30)
			local r = folder and folder:WaitForChild(Drive.BackRemote, 30)
			if r and r:IsA("RemoteEvent") then
				backRemote = r
			end
		end)
		task.spawn(makeGui)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Drive.Tag):Connect(function(m: Instance)
				task.spawn(addCar, m :: Model)
			end)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Drive.Tag):Connect(removeCar)
		)
		for _, m in CollectionService:GetTagged(Drive.Tag) do
			task.spawn(addCar, m :: Model)
		end
		table.insert(
			connections,
			UserInputService.JumpRequest:Connect(function()
				if driving then
					back()
				end
			end)
		)
	end

	function system.step(_: any, dt: number)
		local camera = Workspace.CurrentCamera
		local eye = if camera then camera.CFrame.Position else Vector3.zero
		local d = driving
		if d and (d.hull.Parent == nil or not alive()) then
			stopDriving(true)
			d = nil
		end
		for _, car in cars do
			local hull = hullOf(car.model)
			if hull and (hull.Position - eye).Magnitude < NEAR then
				local frame = hull.CFrame
				local velocity = hull.AssemblyLinearVelocity
				local look = frame.LookVector
				local speed, turn, steer
				if d and d.car == car then
					local asked, askedTurn = d.wheels:asked()
					speed, turn = asked, askedTurn
					local lock = if spec then spec.SteerLock else 26
					car.steer = approach(car.steer, d.steer * lock, STEER_RATE, dt)
					steer = car.steer
				else
					speed = velocity:Dot(look)
					turn = -hull.AssemblyAngularVelocity.Y
					local goal = Drive.steerFrom(
						speed,
						turn,
						if spec then spec.Wheelbase else 1,
						if spec then spec.SteerLock else 26
					)
					car.steer = approach(car.steer, goal, STEER_RATE, dt)
					steer = car.steer
				end
				if
					math.abs(speed) > 0.05
					or math.abs(car.speed) > 0.05
					or math.abs(steer) > 0.05
				then
					pose(car, speed, steer, turn, dt)
				end
				local whine = car.whine
				if whine then
					local driven = car.model:GetAttribute(Drive.DriverAttribute) ~= nil
					if driven then
						local pitch, share = Drive.whine(speed)
						car.pitchNow = approach(car.pitchNow, pitch, Drive.PitchRate, dt)
						whine.PlaybackSpeed = car.pitchNow
						whine.Volume = Drive.Whine.volume * share
						if not whine.IsPlaying then
							whine.TimePosition = Drive.Whine.from
							whine:Play()
						end
					elseif whine.IsPlaying then
						whine:Stop()
						car.pitchNow = Drive.IdlePitch
					end
				end
				if d and d.car == car then
					hood(d, dt)
				end
				car.speed = speed
				car.velocity = velocity
			elseif car.whine and car.whine.IsPlaying then
				car.whine:Stop()
			end
		end
		hideView()
	end

	function system.stop(_: any)
		stopDriving(true)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, car in cars do
			if car.whine then
				car.whine:Destroy()
			end
		end
		table.clear(cars)
		if gui then
			gui:Destroy()
			gui = nil
		end
	end

	return system :: any, api -- any: a plain Brix system built field by field
end

return DriveView
