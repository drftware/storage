--!strict
--[[
	ArrangeCamera (S5-03j1a, D-439): Arrange's build camera, The Sims 4's build-mode camera over
	your home. The moment: Arrange swoops up out of your eyes over the room; one finger slides the
	floor, two pinch, twist and tilt; it glides and settles, a flick drifting on; the walls between
	you and the room's middle melt away as it turns, and come back as it turns on.

	It is Brix's `OrbitCamera` (springs, soft stops, the ceiling) fed by Brix's `Gestures` (one
	intent at a time from fingers, mouse, wheel and gamepad); this module only wires Roblox to
	them and adds what is about this home:
	- the eye stays inside the lobby slot your home stands in, and goes only a little way out into
	  the hall through your door (`BuildView.keepIn`): the slot's own walls and ceiling are the
	  lobby's, shared by every unit, so they can't fade;
	- the home's own walls, and what hangs on them, fade as the eye passes them (`BuildView.sideOf`
	  sorts the pieces, the fade eases on top of the springs);
	- opening swoops from your eyes, closing swoops back, and the front tab's fixed shots (your
	  door, your plate from the hall) swing or dip through black, as before (D-436).

	ArrangeView owns one and calls `open`, `show`, `close`; `taken` is its answer to whether a press
	at a point takes a find (a lifted one, or one under the finger): the camera leaves those alone.
	Nothing steps while Arrange is shut; while open, one render step reads the hands and moves the
	camera, and does next to nothing once the camera and the walls are still.
]]
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local BuildView = require(ReplicatedStorage.Shared.Home.BuildView)

local Feel = Arrange.Feel
local Cam = Arrange.Camera

local STEP = "ArrangeCamera"
local DIP = TweenInfo.new(Feel.Dip, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
-- The mouse's buttons, each its own pointer to Gestures (a right drag can go on under a left press).
local MOUSE_LEFT, MOUSE_RIGHT, MOUSE_MIDDLE = "mouseLeft", "mouseRight", "mouseMiddle"
-- The four walls in order, and each one's outward direction in the room's frame (left is +x,
-- the door's wall −z).
local SIDES: { [string]: number } = { left = 1, right = 2, back = 3, front = 4 }
local OUTWARD = {
	Vector3.new(1, 0, 0),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(0, 0, -1),
}

-- A box in the unit's frame: its middle and its size (across, tall, deep), as ArrangeView measures.
export type Box = { face: CFrame, centre: Vector3, size: Vector3 }

-- Your home as the camera sees it: the room inside its walls, the slot it stands in (the XL box,
-- the lobby's walls round it) and the unit whose walls fade.
export type Room = { inside: Box, slot: Box, unit: Model }

export type Options = {
	-- The gui the dip's black hangs in (under the tray and buttons).
	gui: () -> ScreenGui?,
	-- Whether a press at this gui point takes a find (ArrangeView's drag): then it isn't the camera's.
	taken: (x: number, y: number) -> boolean,
}

export type Camera = {
	-- Swoops from where the camera is to the room's home view (or to `shot`, a fixed view: the front
	-- tab's) and takes the hands.
	open: (room: Room, shot: CFrame?) -> (),
	-- Goes to fixed view `shot`, or back to the room's own camera when nil: a swing, or through
	-- black when `dip` (into or out of the hall, which a swing would take through the wall).
	show: (shot: CFrame?, dip: boolean) -> (),
	-- Swoops back to `back` (your eyes) and gives the camera back to Roblox's own.
	close: (back: CFrame?) -> (),
	-- A find is dragged at gui point `x`, `y`: near the screen's edge the camera slides that way.
	follow: (x: number, y: number) -> (),
	-- Lets go of everything, at once.
	destroy: () -> (),
}

type Wall = { parts: { BasePart }, decals: { Decal }, shown: number, written: number }

local ArrangeCamera = {}

-- Brix's `vector` and Roblox's Vector3 are one value under two types; these cross between them.
local function toVector(v: Vector3): vector
	return (v :: any) :: vector -- any: the same value, typed twice
end
local function fromVector(v: vector): Vector3
	return (v :: any) :: Vector3 -- any: the same value, typed twice
end

-- A camera frame's heading and pitch (radians), level and roll-free: straight down takes its
-- heading from its up direction, as the orbit's view keeps it.
local function angles(cf: CFrame): (number, number)
	local look = cf.LookVector
	local yaw = if look.X * look.X + look.Z * look.Z > 1e-6
		then math.atan2(-look.X, -look.Z)
		else math.atan2(-cf.UpVector.X, -cf.UpVector.Z)
	return yaw, math.asin(math.clamp(look.Y, -1, 1))
end

-- `a` eased toward `b` by `t`: the place along a line, the heading the short way round, the
-- pitch apart, so a half turn never rolls the picture over as one CFrame lerp would.
local function blend(a: CFrame, b: CFrame, t: number): CFrame
	local ya, pa = angles(a)
	local yb, pb = angles(b)
	local turn = (yb - ya + math.pi) % (2 * math.pi) - math.pi
	if math.abs(turn) > math.pi - 0.05 then
		turn = math.pi -- a half turn: always round by the left, never a shudder between ways
	end
	return CFrame.new(a.Position:Lerp(b.Position, t))
		* CFrame.Angles(0, ya + turn * t, 0)
		* CFrame.Angles(pa + (pb - pa) * t, 0, 0)
end

-- The orbit for `room`: its focus kept over the floor inside the walls, starting on today's corner
-- view (high by the door, looking in) told as a heading, tilt and distance about the room's middle.
local function orbitFor(room: Room): Brix.OrbitCamera
	local box = room.inside
	local face, c, s = box.face, box.centre, box.size
	local floor = c.Y - s.Y / 2
	local focus = face * Vector3.new(c.X, floor + Cam.FocusUp, c.Z)
	local eye = face * Vector3.new(c.X, c.Y + s.Y / 2 - Feel.Below, c.Z - s.Z / 2 + Feel.In)
	local into = face:VectorToWorldSpace(Vector3.new(0, 0, 1))
	local across = face:VectorToWorldSpace(Vector3.new(1, 0, 0))
	local off = eye - focus
	local distance = math.max(off.Magnitude, Cam.Near)
	return Brix.OrbitCamera.new({
		area = Brix.Zone.box({
			pathing = Brix.Pathing.floor(),
			center = toVector(face * c),
			size = toVector(s),
			turn = math.atan2(-across.Z, across.X),
		}),
		focus = toVector(focus),
		heading = math.atan2(-into.X, -into.Z),
		tilt = math.clamp(math.asin(off.Y / distance), Cam.LowTilt, Cam.HighTilt),
		distance = distance,
		near = Cam.Near,
		far = math.clamp(math.max(s.X, s.Z) + Cam.FarPast, distance, Cam.FarMost),
		lowTilt = Cam.LowTilt,
		highTilt = Cam.HighTilt,
		ceiling = (face * Vector3.new(c.X, floor + s.Y - Cam.UnderCeiling, c.Z)).Y,
		settle = Cam.Settle,
		drift = Cam.Drift,
		fadeDepth = Cam.FadeDepth,
	})
end

function ArrangeCamera.new(options: Options): Camera
	local gestures = Brix.Gestures.new({
		pick = function(x: number, y: number): boolean?
			local inset = GuiService:GetGuiInset()
			return if options.taken(x, y - inset.Y) then true else nil
		end,
		mouseTurn = Cam.MouseTurn,
		stickTurn = Cam.StickTurn,
	})
	local orbit: Brix.OrbitCamera? = nil
	local room: Room? = nil
	-- What the camera shows: the orbit, or a fixed view; gliding there from `from` since `since`.
	local shot: CFrame? = nil
	local from: CFrame? = nil
	local since = 0
	local closing = false
	local bound = false
	local still = false -- the last frame changed nothing: the next writes nothing either
	local inputs: { RBXScriptConnection } = {}
	local mouseDown: { [string]: boolean } = {}
	local dipping: Tween? = nil
	local walls: { Wall } = {}
	local placedWatch: { RBXScriptConnection } = {}
	local regather = false
	-- The room's frame (its middle at the origin) and the eye's box in it, kept while open.
	local roomFrame = CFrame.identity
	local half = Vector3.zero
	local eyeBox: BuildView.Box = { left = 0, right = 0, front = 0, back = 0 }

	local function setFade(w: Wall, value: number)
		w.written = value
		for _, p in w.parts do
			p.LocalTransparencyModifier = value
		end
		for _, d in w.decals do
			d.LocalTransparencyModifier = value
		end
	end

	local function clearWalls()
		for _, w in walls do
			setFade(w, 0)
		end
		table.clear(walls)
	end

	-- Sorts the unit's pieces onto its four walls: its own walls, door and paint by where they
	-- stand, and finds set out on a wall by the wall they hang on.
	local function gather()
		clearWalls()
		regather = false
		local r = room
		if not r then
			return
		end
		for i in OUTWARD do
			walls[i] = { parts = {}, decals = {}, shown = 0, written = 0 }
		end
		local placed = r.unit:FindFirstChild(Arrange.Folder)
		local function add(side: string, part: BasePart)
			local w = walls[SIDES[side]]
			table.insert(w.parts, part)
			for _, d in part:GetChildren() do
				if d:IsA("Decal") then
					table.insert(w.decals, d)
				end
			end
		end
		local function sideOfPart(part: BasePart): string?
			local cf = roomFrame:ToObjectSpace(part.CFrame)
			local s = part.Size / 2
			local r1, u1, l1 = cf.RightVector, cf.UpVector, cf.LookVector
			local ex = math.abs(r1.X) * s.X + math.abs(u1.X) * s.Y + math.abs(l1.X) * s.Z
			local ez = math.abs(r1.Z) * s.X + math.abs(u1.Z) * s.Y + math.abs(l1.Z) * s.Z
			local p = cf.Position
			return BuildView.sideOf(
				p.X - ex,
				p.X + ex,
				p.Z - ez,
				p.Z + ez,
				half.X,
				half.Z,
				Cam.WallBand,
				Cam.FrontBand
			)
		end
		for _, d in r.unit:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 then
				if placed and d:IsDescendantOf(placed) then
					continue
				end
				local side = sideOfPart(d)
				if side then
					add(side, d)
				end
			end
		end
		if placed then
			for _, find in placed:GetChildren() do
				local on = find:GetAttribute(Arrange.OnAttribute)
				if find:IsA("Model") and type(on) == "string" and string.sub(on, -4) == "Wall" then
					local p = roomFrame:PointToObjectSpace(find:GetPivot().Position)
					local x, z = p.X / half.X, p.Z / half.Z
					local side = if z >= math.abs(x)
						then "back"
						elseif x > 0 then "left"
						else "right"
					for _, part in find:GetDescendants() do
						if part:IsA("BasePart") then
							add(side, part)
						end
					end
				end
			end
		end
	end

	-- Eases each wall toward how far the eye stands past it (none when `eye` is nil), writing only
	-- what changed. Whether any wall is still on its way.
	local function fadeWalls(eye: Vector3?, dt: number): boolean
		local moving = false
		local seen = if eye then roomFrame:PointToObjectSpace(eye) else nil
		local k = 1 - 0.5 ^ (dt / Cam.FadeHalf)
		for i, w in walls do
			local want = 0
			if seen then
				local out = OUTWARD[i]
				local past = seen:Dot(out) - (if out.X ~= 0 then half.X else half.Z)
				want = math.clamp(past / Cam.FadeDepth, 0, 1)
			end
			local shown = w.shown + (want - w.shown) * k
			if math.abs(want - shown) < 0.002 then
				shown = want
			else
				moving = true
			end
			w.shown = shown
			if math.abs(shown - w.written) >= 0.01 or (shown == want and w.written ~= want) then
				setFade(w, shown)
			end
		end
		return moving
	end

	-- The eye pulled in along its line of sight until it's inside the slot (or the hall's edge).
	local function keepIn(eye: Vector3, focus: Vector3): Vector3
		local e = roomFrame:PointToObjectSpace(eye)
		local f = roomFrame:PointToObjectSpace(focus)
		local share = BuildView.keepIn(e.X, e.Z, f.X, f.Z, eyeBox)
		return if share < 1 then focus + (eye - focus) * share else eye
	end

	local function screen()
		local camera = Workspace.CurrentCamera
		local o = orbit
		if camera and o then
			o:screen(camera.ViewportSize.X, camera.ViewportSize.Y, math.rad(camera.FieldOfView))
		end
	end

	local function apply(i: Brix.GestureIntent<boolean>)
		local o = orbit
		if not o or shot or closing then
			return
		end
		if i.kind == "slide" then
			o:slide(i.dx, i.dy)
		elseif i.kind == "dragBegan" or i.kind == "dragMoved" then
			if i.target == nil then
				o:slide(i.dx, i.dy)
			end
		elseif i.kind == "dragEnded" then
			if i.target == nil and not i.cancelled then
				o:flick(i.vx, i.vy)
			end
		elseif i.kind == "pinch" then
			o:zoom(i.scale, i.x, i.y)
		elseif i.kind == "twist" then
			if i.target == nil then
				o:turn(i.angle, i.x, i.y)
			end
		elseif i.kind == "tilt" then
			o:tilt(i.amount)
		elseif i.kind == "doubleTap" then
			if i.target == nil then
				o:reset()
			end
		end
	end

	-- WASD and the arrows slide the floor while held, as a finger dragging it would.
	local function keys(dt: number)
		local o = orbit
		if not o or shot or closing or UserInputService:GetFocusedTextBox() then
			return
		end
		local x, y = 0, 0
		if
			UserInputService:IsKeyDown(Enum.KeyCode.W)
			or UserInputService:IsKeyDown(Enum.KeyCode.Up)
		then
			y += 1
		end
		if
			UserInputService:IsKeyDown(Enum.KeyCode.S)
			or UserInputService:IsKeyDown(Enum.KeyCode.Down)
		then
			y -= 1
		end
		if
			UserInputService:IsKeyDown(Enum.KeyCode.A)
			or UserInputService:IsKeyDown(Enum.KeyCode.Left)
		then
			x += 1
		end
		if
			UserInputService:IsKeyDown(Enum.KeyCode.D)
			or UserInputService:IsKeyDown(Enum.KeyCode.Right)
		then
			x -= 1
		end
		if x ~= 0 or y ~= 0 then
			local speed = Cam.KeySlide * dt / math.sqrt(x * x + y * y)
			o:slide(x * speed, y * speed)
		end
	end

	local function unbind()
		if bound then
			RunService:UnbindFromRenderStep(STEP)
			bound = false
		end
	end

	local function finishClose()
		closing = false
		unbind()
		clearWalls()
		for _, c in placedWatch do
			c:Disconnect()
		end
		table.clear(placedWatch)
		room, orbit, shot, from = nil, nil, nil, nil
		local camera = Workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Custom
		end
	end

	local function step(dt: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local now = os.clock()
		gestures:advance(now)
		local heard = false
		for _, intent in gestures:takeIntents() do
			apply(intent)
			heard = true
		end
		keys(dt)
		if regather then
			gather()
			still = false
		end
		local o = orbit
		local goal: CFrame
		local eye: Vector3? = nil
		if shot then
			goal = shot
		elseif o then
			o:step(dt)
			local e, l, u = o:view()
			local look = fromVector(l)
			local seen = keepIn(fromVector(e), look)
			eye = seen
			goal = CFrame.lookAt(seen, look, fromVector(u))
		else
			return
		end
		local fading = fadeWalls(if closing then nil else eye, dt)
		local f = from
		if f then
			local a = math.clamp((now - since) / Feel.Rise, 0, 1)
			camera.CFrame = blend(
				f,
				goal,
				TweenService:GetValue(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			)
			if a >= 1 then
				from = nil
			end
			still = false
		else
			local resting = not heard and not fading and (shot ~= nil or (o ~= nil and o:resting()))
			if not (still and resting) then
				camera.CFrame = goal -- once more as it comes to rest, then nothing till it moves
			end
			still = resting
		end
		if closing and from == nil and not fading then
			finishClose()
		end
	end

	local function bind()
		if not bound then
			bound = true
			still = false
			RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 1, step)
		end
	end

	-- Starts a glide from wherever the camera is now.
	local function glide()
		local camera = Workspace.CurrentCamera
		from = if camera then camera.CFrame else nil
		since = os.clock()
		still = false
	end

	local function point(input: InputObject): (number, number)
		local inset = GuiService:GetGuiInset()
		return input.Position.X, input.Position.Y + inset.Y
	end

	local function began(input: InputObject, processed: boolean)
		local t = input.UserInputType
		if processed then
			return
		end
		local x, y = point(input)
		local now = os.clock()
		if t == Enum.UserInputType.Touch then
			gestures:press(input, x, y, "touch", now)
		elseif t == Enum.UserInputType.MouseButton1 then
			mouseDown[MOUSE_LEFT] = true
			gestures:press(MOUSE_LEFT, x, y, "left", now)
		elseif t == Enum.UserInputType.MouseButton2 then
			mouseDown[MOUSE_RIGHT] = true
			gestures:press(MOUSE_RIGHT, x, y, "right", now)
		elseif t == Enum.UserInputType.MouseButton3 then
			mouseDown[MOUSE_MIDDLE] = true
			gestures:press(MOUSE_MIDDLE, x, y, "middle", now)
		end
	end

	local function changed(input: InputObject, processed: boolean)
		local t = input.UserInputType
		local now = os.clock()
		if t == Enum.UserInputType.Touch then
			local x, y = point(input)
			gestures:move(input, x, y, now)
		elseif t == Enum.UserInputType.MouseMovement then
			local x, y = point(input)
			for key in mouseDown do
				gestures:move(key, x, y, now)
			end
		elseif t == Enum.UserInputType.MouseWheel then
			if not processed then
				local x, y = point(input)
				gestures:wheel(input.Position.Z, x, y, now)
			end
		elseif t == Enum.UserInputType.Gamepad1 then
			local k, p = input.KeyCode, input.Position
			if k == Enum.KeyCode.Thumbstick1 then
				gestures:stick("left", p.X, p.Y, now)
			elseif k == Enum.KeyCode.Thumbstick2 then
				gestures:stick("right", p.X, p.Y, now)
			elseif k == Enum.KeyCode.ButtonR2 then
				gestures:trigger("right", p.Z, now)
			elseif k == Enum.KeyCode.ButtonL2 then
				gestures:trigger("left", p.Z, now)
			end
		end
	end

	local function ended(input: InputObject)
		local t = input.UserInputType
		local now = os.clock()
		local x, y = point(input)
		local key = if t == Enum.UserInputType.MouseButton1
			then MOUSE_LEFT
			elseif t == Enum.UserInputType.MouseButton2 then MOUSE_RIGHT
			elseif t == Enum.UserInputType.MouseButton3 then MOUSE_MIDDLE
			else nil
		if t == Enum.UserInputType.Touch then
			gestures:release(input, x, y, now)
		elseif key then
			mouseDown[key] = nil
			gestures:release(key, x, y, now)
		elseif t == Enum.UserInputType.Gamepad1 then
			local k = input.KeyCode
			if k == Enum.KeyCode.Thumbstick1 then
				gestures:stick("left", 0, 0, now)
			elseif k == Enum.KeyCode.Thumbstick2 then
				gestures:stick("right", 0, 0, now)
			elseif k == Enum.KeyCode.ButtonR2 then
				gestures:trigger("right", 0, now)
			elseif k == Enum.KeyCode.ButtonL2 then
				gestures:trigger("left", 0, now)
			end
		end
	end

	local function letGo()
		for _, c in inputs do
			c:Disconnect()
		end
		table.clear(inputs)
		table.clear(mouseDown)
		gestures:cancel()
		gestures:takeIntents() -- a cancelled drag's end, unheard
	end

	local function stopDip()
		local d = dipping
		dipping = nil
		if d then
			d:Cancel()
		end
	end

	local camera: Camera = {
		open = function(r: Room, fixed: CFrame?)
			local cam = Workspace.CurrentCamera
			if not cam then
				return
			end
			stopDip()
			letGo()
			if closing then
				finishClose()
			end
			room = r
			local inside, slot = r.inside, r.slot
			roomFrame = inside.face * CFrame.new(inside.centre)
			half = inside.size / 2
			-- the slot's box in the room's frame: both share the unit's frame and the door's line
			local s0 = slot.centre - inside.centre
			local sh = slot.size / 2
			eyeBox = {
				left = s0.X - sh.X + Cam.WallGap,
				right = s0.X + sh.X - Cam.WallGap,
				front = -half.Z - Cam.Hall,
				back = s0.Z + sh.Z - Cam.WallGap,
			}
			orbit = orbitFor(r)
			screen()
			shot = fixed
			cam.CameraType = Enum.CameraType.Scriptable
			glide()
			gather()
			local placed = r.unit:FindFirstChild(Arrange.Folder)
			if placed then
				local function again()
					regather = true
				end
				table.insert(placedWatch, placed.ChildAdded:Connect(again))
				table.insert(placedWatch, placed.ChildRemoved:Connect(again))
			end
			table.insert(inputs, UserInputService.InputBegan:Connect(began))
			table.insert(inputs, UserInputService.InputChanged:Connect(changed))
			table.insert(inputs, UserInputService.InputEnded:Connect(ended))
			table.insert(
				inputs,
				UserInputService.WindowFocusReleased:Connect(function()
					gestures:cancel()
					table.clear(mouseDown)
				end)
			)
			table.insert(inputs, cam:GetPropertyChangedSignal("ViewportSize"):Connect(screen))
			bind()
		end,
		show = function(fixed: CFrame?, dip: boolean)
			if not room or closing then
				return
			end
			stopDip()
			gestures:cancel()
			local g = options.gui()
			if not dip or not g then
				shot = fixed
				glide()
				return
			end
			local shade = Instance.new("Frame")
			shade.Name = "Dip"
			shade.Position = UDim2.fromOffset(0, -80) -- over the top bar's inset too
			shade.Size = UDim2.new(1, 0, 1, 80)
			shade.BackgroundColor3 = Color3.new(0, 0, 0)
			shade.BackgroundTransparency = 1
			shade.BorderSizePixel = 0
			shade.ZIndex = 0 -- under every button and the tray
			shade.Parent = g
			local down = TweenService:Create(shade, DIP, { BackgroundTransparency = 0 })
			down.Completed:Once(function(state: Enum.PlaybackState)
				if dipping == down then
					dipping = nil
				end
				if state == Enum.PlaybackState.Completed and room and not closing then
					shot = fixed -- the cut, in the dark
					from = nil
					still = false
				end
				local up = TweenService:Create(shade, DIP, { BackgroundTransparency = 1 })
				up.Completed:Once(function()
					shade:Destroy()
				end)
				up:Play()
			end)
			dipping = down
			down:Play()
		end,
		close = function(back: CFrame?)
			if not room then
				return
			end
			stopDip()
			letGo()
			if not back then
				finishClose()
				return
			end
			shot = back
			closing = true
			glide()
		end,
		follow = function(x: number, y: number)
			local o = orbit
			if o and not shot and not closing then
				local inset = GuiService:GetGuiInset()
				o:follow(x, y + inset.Y)
			end
		end,
		destroy = function()
			stopDip()
			letGo()
			if room then
				finishClose()
			end
			unbind()
		end,
	}
	return camera
end

return ArrangeCamera
