--!strict
--[[
	ArrangeCamera (S5-03j1a, D-439): Arrange's build camera, The Sims 4's build-mode camera over
	your home. The moment: Arrange swoops up out of your eyes over the room; one finger slides the
	floor, two pinch, twist and tilt; it glides and settles, a flick drifting on; the walls between
	you and the room's middle melt away as it turns, and come back as it turns on.

	It is Brix's `OrbitCamera` (springs, soft stops) fed by Brix's `Gestures` (one
	intent at a time from fingers, mouse, wheel and gamepad); this module only wires Roblox to
	them and adds what is about this home:
	- while its orbit is the view the roof and the world go from your screen (`ArrangeStage`,
	  D-444), so the eye rises anywhere within `Around` of the walls and looks down into the
	  open-topped room; the focus shows in the middle of the band the tray and top bar leave
	  clear (`aim`), so the room is never half under the tray;
	- the home's own walls, and what hangs on them, fade as the eye passes them (`BuildView.sideOf`
	  sorts the pieces, the fade eases on top of the springs);
	- opening swoops from your eyes, closing swoops back, and the front tab's fixed shots (your
	  door, your plate from the hall) swing or dip through black, as before (D-436).

	ArrangeView owns one and calls `open`, `show`, `close`. Its one Gestures reader is the room's only
	reader of fingers (S5-03j2a): `pick` is the hand's answer to what's under a press (ArrangeHand),
	and every intent with a thing for its target, and every tap, goes to `hand`; the rest move the
	camera.
	Nothing steps while Arrange is shut; while open, one render step reads the hands and moves the
	camera, and does next to nothing once the camera and the walls are still.
]]
local GuiService = game:GetService("GuiService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local BuildView = require(ReplicatedStorage.Shared.Home.BuildView)
local Walls = require(ReplicatedStorage.Shared.Home.Walls)
local ArrangeStage = require(script.Parent.ArrangeStage)

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
	-- The thing of yours under gui point `x`, `y` that a press there takes (ArrangeHand's `pickAt`),
	-- or nil for the room itself: a drag on a thing is the hand's, on the room the camera's.
	pick: (x: number, y: number) -> Model?,
	-- The hand's intents, in gui points: every one with a thing for its target, and every tap (a
	-- tap on the empty room sets down what the hand holds).
	hand: (intent: Brix.GestureIntent<Model>) -> (),
	-- The band of the screen no menu covers: its top and bottom, in viewport points.
	clear: () -> (number, number),
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
	-- Where the room's focus shows, in gui points: the middle of the band the menus leave clear,
	-- on the screen the camera draws (D-446). A card tapped in the tray lifts to here.
	middle: () -> (number, number),
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

-- The orbit for `room`: its focus kept over the floor inside the walls, starting on the home view:
-- from a front corner on the side the player stands (`from`, their eyes, in the room's frame;
-- `BuildView.homeView`), high over the open-topped room at `HomeTilt` (D-444), as near as the
-- room's floor fills the clear band of `screen` (`BuildView.fit`, S5-03j1d2, D-446). Also answers where
-- down the band the focus shows (0 its top, 1 its bottom) so the room sits in its middle, and
-- the box the eye may stand in: `Around` past the walls, or out to the home view if that's further.
local function orbitFor(
	room: Room,
	from: Vector3,
	screen: BuildView.Screen
): (Brix.OrbitCamera, number, BuildView.Box)
	local box = room.inside
	local face, c, s = box.face, box.centre, box.size
	local floor = c.Y - s.Y / 2
	local focus = face * Vector3.new(c.X, floor + Cam.FocusUp, c.Z)
	local wide = BuildView.eyeBox(s.X / 2, s.Z / 2, -Cam.Around, Cam.Around)
	local angle = BuildView.homeView(
		s.X / 2,
		s.Z / 2,
		Cam.Clear,
		wide,
		if from.X < 0 then -1 else 1,
		Cam.Slant
	)
	local reach, aimAt = BuildView.fit(
		s.X / 2,
		s.Z / 2,
		Cam.FocusUp,
		math.min(Cam.FitHigh, s.Y),
		angle,
		Cam.HomeTilt,
		screen
	)
	reach = math.max(reach, Cam.Near)
	local flat, rise = reach * math.cos(Cam.HomeTilt), reach * math.sin(Cam.HomeTilt)
	local out = math.max(Cam.Around, flat - math.min(s.X, s.Z) / 2 + 1)
	local eyeBox = BuildView.eyeBox(s.X / 2, s.Z / 2, -out, out)
	local eye = face
		* Vector3.new(
			c.X + flat * math.sin(angle),
			floor + Cam.FocusUp + rise,
			c.Z - flat * math.cos(angle)
		)
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
		heading = math.atan2(off.X, off.Z),
		tilt = math.clamp(math.asin(off.Y / distance), Cam.LowTilt, Cam.HighTilt),
		distance = distance,
		near = Cam.Near,
		far = math.max(distance, math.min(math.max(s.X, s.Z) + Cam.FarPast, Cam.FarMost)),
		lowTilt = Cam.LowTilt,
		highTilt = Cam.HighTilt,
		eyeArea = Brix.Zone.box({
			pathing = Brix.Pathing.floor(),
			center = toVector(
				face
					* Vector3.new(
						c.X + (eyeBox.left + eyeBox.right) / 2,
						c.Y,
						c.Z + (eyeBox.front + eyeBox.back) / 2
					)
			),
			-- tall enough that the eye's height never counts, only where it stands
			size = toVector(
				Vector3.new(eyeBox.right - eyeBox.left, s.Y * 4, eyeBox.back - eyeBox.front)
			),
			turn = math.atan2(-across.Z, across.X),
		}),
		settle = Cam.Settle,
		drift = Cam.Drift,
		fadeDepth = Cam.FadeDepth,
	}),
		(aimAt - screen.top) / math.max(screen.bottom - screen.top, 1),
		eyeBox
end

function ArrangeCamera.new(options: Options): Camera
	local gestures = Brix.Gestures.new({
		pick = function(x: number, y: number): Model?
			local inset = GuiService:GetGuiInset()
			return options.pick(x, y - inset.Y)
		end,
		mouseTurn = Cam.MouseTurn,
		stickTurn = Cam.StickTurn,
		-- the wheel on a carried thing turns it a quarter a notch, as R does (S5-03j2b2b)
		wheelTurn = math.pi / 2,
	})
	local orbit: Brix.OrbitCamera? = nil
	local stage = ArrangeStage.new(Cam.Stage, Cam.Void, Cam.Light)
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
	-- The room's frame (its middle at the origin) and its half size, kept while open.
	local roomFrame = CFrame.identity
	local half = Vector3.zero
	-- The screen as the camera draws it (S5-03j1d3, D-446): `ViewportSize` is the device's safe
	-- area, but the camera draws the whole screen round it and measures its field of view on that
	-- (create.roblox.com, Camera.ViewportSize). On the A16 the drawn screen is 779 by 359 round a
	-- 685 by 338 safe area, so an orbit told 338 set the room 10 points low and 6% small. The
	-- orbit and the fit take the drawn screen: `drawnWide` across (its middle at half that, in
	-- viewport points), `drawnTall` high, a viewport point `drawnDown` lower on it.
	local drawnWide, drawnTall, drawnDown = 685, 338, 0

	local function setFade(w: Wall, value: number)
		w.written = value
		for _, p in w.parts do
			p.LocalTransparencyModifier = value
		end
		for _, d in w.decals do
			d.LocalTransparencyModifier = value
		end
	end

	local masks: { BasePart } = {}
	local function clearWalls()
		for _, w in walls do
			setFade(w, 0)
		end
		table.clear(walls)
		for _, m in masks do
			m:Destroy()
		end
		table.clear(masks)
	end

	-- A dark box over a wall's run past the room's corner (S5-03j1d2): `run` flat in the room's
	-- frame, `low` to `high` up it. Neon in the stage's floor colour draws flat whatever lights
	-- it, so against that floor the run is gone and the room ends at its corners. Only this
	-- screen has it (it hangs under the camera).
	local function mask(run: BuildView.Box, low: number, high: number): BasePart
		local hair = Cam.MaskHair
		local m = Instance.new("Part")
		m.Name = "ArrangeMask"
		m.Anchored = true
		m.CanCollide = false
		m.CanQuery = false
		m.CanTouch = false
		m.CastShadow = false
		m.Material = Enum.Material.Neon
		m.Color = Cam.Void
		m.Size = Vector3.new(run.right - run.left, high - low, run.back - run.front)
			+ Vector3.one * hair * 2
		m.CFrame = roomFrame
			* CFrame.new((run.left + run.right) / 2, (low + high) / 2, (run.front + run.back) / 2)
		m.Parent = Workspace.CurrentCamera
		table.insert(masks, m)
		return m
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
		-- Each piece's flat box and height in the room's frame, kept to mask the walls' runs.
		type Piece = { side: string?, box: BuildView.Box, low: number, high: number }
		local pieces: { Piece } = {}
		local function boxOf(part: BasePart): (BuildView.Box, number, number)
			local cf = roomFrame:ToObjectSpace(part.CFrame)
			local e = part.Size / 2
			local r1, u1, l1 = cf.RightVector, cf.UpVector, cf.LookVector
			local ex = math.abs(r1.X) * e.X + math.abs(u1.X) * e.Y + math.abs(l1.X) * e.Z
			local ey = math.abs(r1.Y) * e.X + math.abs(u1.Y) * e.Y + math.abs(l1.Y) * e.Z
			local ez = math.abs(r1.Z) * e.X + math.abs(u1.Z) * e.Y + math.abs(l1.Z) * e.Z
			local p = cf.Position
			return { left = p.X - ex, right = p.X + ex, front = p.Z - ez, back = p.Z + ez },
				p.Y - ey,
				p.Y + ey
		end
		-- The room's outer box: its walls' outer faces (the movable walls' steel when a smaller
		-- home stands in the slot), the door's wall `FrontBand` out.
		local outer: BuildView.Box =
			{ left = -half.X, right = half.X, front = -half.Z - Cam.FrontBand, back = half.Z }
		local movable = r.unit:FindFirstChild(Walls.Folder)
		for _, d in r.unit:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 then
				if placed and d:IsDescendantOf(placed) then
					continue
				end
				local side = sideOfPart(d)
				local b, low, high = boxOf(d)
				-- the room's own pieces too: the floor's paint is the XL's whole floor
				table.insert(pieces, { side = side, box = b, low = low, high = high })
				if side then
					add(side, d)
					if movable and d:IsDescendantOf(movable) then
						if side == "left" then
							outer.right = math.max(outer.right, b.right)
						elseif side == "right" then
							outer.left = math.min(outer.left, b.left)
						elseif side == "back" then
							outer.back = math.max(outer.back, b.back)
						end
					end
				end
			end
		end
		for _, piece in pieces do
			for _, run in BuildView.runs(outer, piece.box, Cam.MaskLeast) do
				local m = mask(run, piece.low, piece.high)
				local side = piece.side
				if side then
					add(side, m)
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
				local over = math.abs(seen.X) <= half.X and math.abs(seen.Z) <= half.Z
				want = BuildView.fade(past, over, Cam.WallGap, Cam.FadeDepth)
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

	-- Shows the focus in the middle of the clear band, told again only when the band moves.
	local aimedY, aimedW = -1, -1
	local aimAt = 0.5 -- where down the band the focus shows (0 its top), from the home view's fit
	local function aim()
		local camera = Workspace.CurrentCamera
		local o = orbit
		if not (camera and o) then
			return
		end
		local top, bottom = options.clear()
		local y, w = top + (bottom - top) * aimAt + drawnDown, drawnWide
		if math.abs(y - aimedY) > 0.5 or math.abs(w - aimedW) > 0.5 then
			aimedY, aimedW = y, w
			o:aim(w / 2, y)
		end
	end

	-- Measures the drawn screen (above) from where the camera's middle and the top of its field
	-- of view show in viewport points: any camera pose will do.
	local function lens()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local cf = camera.CFrame
		local reach = math.tan(math.rad(camera.FieldOfView) / 2)
		local mid = camera:WorldToViewportPoint(cf.Position + cf.LookVector)
		local top = camera:WorldToViewportPoint(cf.Position + cf.LookVector + cf.UpVector * reach)
		local halfTall = mid.Y - top.Y
		if halfTall > 1 and mid.X > 1 then
			drawnWide, drawnTall, drawnDown = 2 * mid.X, 2 * halfTall, halfTall - mid.Y
		else
			local view = camera.ViewportSize
			drawnWide, drawnTall, drawnDown = view.X, view.Y, 0
		end
	end

	local function screen()
		local camera = Workspace.CurrentCamera
		local o = orbit
		lens()
		if camera and o then
			o:screen(drawnWide, drawnTall, math.rad(camera.FieldOfView))
		end
	end

	-- An intent for the hand, its point moved from viewport points into gui points (the intent is
	-- this reader's own table, read once).
	local function toHand(i: Brix.GestureIntent<Model>)
		local up = GuiService:GetGuiInset().Y
		if i.kind == "twist" then
			local y = i.y
			if y then
				i.y = y - up
			end
		elseif
			i.kind == "tap"
			or i.kind == "doubleTap"
			or i.kind == "hold"
			or i.kind == "dragBegan"
			or i.kind == "dragMoved"
			or i.kind == "dragEnded"
		then
			i.y -= up
		end
		options.hand(i)
	end

	local function apply(i: Brix.GestureIntent<Model>)
		local o = orbit
		if not o or shot or closing then
			return
		end
		local target = if i.kind == "slide"
				or i.kind == "pinch"
				or i.kind == "tilt"
			then nil
			else i.target
		if target or i.kind == "tap" then
			toHand(i)
		elseif i.kind == "slide" then
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
			o:zoom(i.scale, i.x, if i.y then i.y + drawnDown else nil)
		elseif i.kind == "twist" then
			if i.target == nil then
				o:turn(i.angle, i.x, if i.y then i.y + drawnDown else nil)
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

	-- Whether prompts showed before Arrange hid them (S5-03j1d2): nil while they aren't hidden.
	local promptsWere: boolean? = nil

	local function finishClose()
		closing = false
		unbind()
		clearWalls()
		stage.drop()
		local was = promptsWere
		promptsWere = nil
		if was ~= nil then
			ProximityPromptService.Enabled = was
		end
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
			aim()
			o:step(dt)
			local e, l, u = o:view()
			local seen = fromVector(e)
			eye = seen
			goal = CFrame.lookAt(seen, fromVector(l), fromVector(u))
		else
			return
		end
		-- The world goes while the orbit is the view, and comes back once a glide has brought a
		-- fixed shot or your eyes (D-444).
		local r = room
		if r and shot == nil and not closing then
			local middle = roomFrame.Position
			stage.lift(r.unit, middle, middle.Y - half.Y)
		elseif from == nil then
			stage.drop()
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

	-- Studio only (S5-03j1b): `ArrangeCamera.CameraTest:Invoke(verb, ...)` from a Client
	-- `execute_luau`, because Studio's MCP mouse is a finger with no wheel or right button. It
	-- feeds Gestures exactly what a mouse would: `"right", x, y, dx, dy, seconds` drags with the
	-- right button, `"wheel", notches, x, y` rolls the wheel, `"tap", x, y` taps (twice quickly
	-- is the reset), `"carry", x, y, dx, dy, { wheel, twist, hold }` turns a dragged thing. `"state"` answers the eye, the look point and each wall's fade (left, right,
	-- back, front) as one line; `"frame"` where the floor's corners and the walls' tops show
	-- against the clear band. Points are viewport points, as Gestures takes them.
	local test: BindableFunction? = nil
	if RunService:IsStudio() then
		local hook = Instance.new("BindableFunction")
		hook.Name = "CameraTest"
		-- any: a BindableFunction's arguments, only ever a Studio session's own
		hook.OnInvoke = function(verb: any, a: any, b: any, c: any, d: any, e: any): string?
			local now = os.clock()
			if verb == "right" or verb == "drag" then
				local id = "cameraTest"
				local seconds = if type(e) == "number" then e else 0.4
				if verb == "right" then
					gestures:press(id, a, b, "right", now)
				else
					gestures:press(id, a, b, "left", now)
				end
				local frames = math.max(1, math.floor(seconds * 60))
				for i = 1, frames do
					task.wait()
					gestures:move(id, a + c * i / frames, b + d * i / frames, os.clock())
				end
				gestures:release(id, a + c, b + d, os.clock())
				return "ok"
			elseif verb == "wheel" then
				gestures:wheel(a, b, c, now)
				return "ok"
			elseif verb == "tap" then
				gestures:press("cameraTest", a, b, "left", now)
				task.wait()
				gestures:release("cameraTest", a, b, os.clock())
				return "ok"
			elseif verb == "carry" then
				-- A carried thing turned mid-drag (S5-03j2b2b2), which the MCP's mouse can't do:
				-- presses at x, y and drags by dx, dy, then `e.wheel` notches of the wheel (a
				-- mouse's press) or a second finger twisted `e.twist` radians round the first
				-- (a finger's press), holds `e.hold` seconds and lets go.
				local how = if type(e) == "table" then e else {}
				local by = if type(how.twist) == "number" then how.twist else nil
				gestures:press("cameraTest", a, b, if by then "touch" else "left", now)
				for i = 1, 20 do
					task.wait()
					gestures:move("cameraTest", a + c * i / 20, b + d * i / 20, os.clock())
				end
				local x, y = a + c, b + d
				if type(how.wheel) == "number" then
					gestures:wheel(how.wheel, x, y, os.clock())
				end
				if by then
					gestures:press("cameraTest2", x + 60, y, "touch", os.clock())
					for i = 1, 20 do
						task.wait()
						local t = by * i / 20
						gestures:move(
							"cameraTest2",
							x + 60 * math.cos(t),
							y + 60 * math.sin(t),
							os.clock()
						)
					end
					gestures:release(
						"cameraTest2",
						x + 60 * math.cos(by),
						y + 60 * math.sin(by),
						os.clock()
					)
				end
				task.wait(if type(how.hold) == "number" then how.hold else 0.3)
				gestures:release("cameraTest", x, y, os.clock())
				return "ok"
			elseif verb == "state" then
				local cam = Workspace.CurrentCamera
				local o = orbit
				if not (cam and o) then
					return "closed"
				end
				local e1, l1 = o:view()
				local eye, look = roomFrame:PointToObjectSpace(cam.CFrame.Position), fromVector(l1)
				local fades = {}
				for i, w in walls do
					fades[i] = string.format("%.2f", w.shown)
				end
				local at = roomFrame:PointToObjectSpace(look)
				local raw = roomFrame:PointToObjectSpace(fromVector(e1))
				return string.format(
					"eye %.1f,%.1f,%.1f (orbit %.1f,%.1f,%.1f) look %.1f,%.1f,%.1f fades %s rest %s",
					eye.X,
					eye.Y,
					eye.Z,
					raw.X,
					raw.Y,
					raw.Z,
					at.X,
					at.Y,
					at.Z,
					table.concat(fades, "/"),
					tostring(o:resting())
				)
			elseif verb == "frame" then
				-- Where the room shows (S5-03j1d3): the floor's corners' and the walls' tops'
				-- reach on screen against the clear band, in viewport points.
				local cam = Workspace.CurrentCamera
				local o = orbit
				if not (cam and o) then
					return "closed"
				end
				local _, look = o:view()
				local top, bottom = options.clear()
				local up, down, left, right, roof =
					math.huge, -math.huge, math.huge, -math.huge, math.huge
				for i = 0, 7 do
					local x = if i % 2 == 0 then half.X else -half.X
					local z = if i % 4 < 2 then half.Z else -half.Z
					local y = if i < 4 then -half.Y else half.Y
					local p = cam:WorldToViewportPoint(roomFrame * Vector3.new(x, y, z))
					if i < 4 then
						up, down = math.min(up, p.Y), math.max(down, p.Y)
						left, right = math.min(left, p.X), math.max(right, p.X)
					else
						roof = math.min(roof, p.Y)
					end
				end
				return string.format(
					"band %.0f..%.0f floor y %.0f..%.0f x %.0f..%.0f walls' tops %.0f distance %.1f",
					top,
					bottom,
					up,
					down,
					left,
					right,
					roof,
					(cam.CFrame.Position - fromVector(look)).Magnitude
				)
			end
			return nil
		end
		hook.Parent = script
		test = hook
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
			-- No world buttons while Arrange is open (the door's Close and Slam, the job box's
			-- Open): your screen only (STUDIO.md, `ProximityPromptService.Enabled`).
			if promptsWere == nil then
				promptsWere = ProximityPromptService.Enabled
			end
			ProximityPromptService.Enabled = false
			local inside = r.inside
			roomFrame = inside.face * CFrame.new(inside.centre)
			half = inside.size / 2
			-- With the world gone (D-444) the eye may stand anywhere within `Around` of the walls
			-- (a gap of −Around reaches that far past every one), or out to the home view.
			local top, bottom = options.clear()
			lens()
			orbit, aimAt = orbitFor(r, roomFrame:PointToObjectSpace(cam.CFrame.Position), {
				width = drawnWide,
				tall = drawnTall,
				tanHalf = math.tan(math.rad(cam.FieldOfView) / 2),
				top = top + drawnDown,
				bottom = bottom + drawnDown,
				roof = Cam.Roof,
				edge = Cam.Edge,
			})
			aimedY, aimedW = -1, -1
			screen()
			aim()
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
			-- Between the orbit and a fixed shot always through black: the world comes back or goes
			-- in the dark, and a swing would cross the building's walls (D-444).
			if (fixed == nil) ~= (shot == nil) then
				dip = true
			end
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
		middle = function(): (number, number)
			local inset = GuiService:GetGuiInset()
			if aimedY >= 0 then
				return aimedW / 2, aimedY - drawnDown - inset.Y
			end
			local cam = Workspace.CurrentCamera
			local view = if cam then cam.ViewportSize else Vector2.new(800, 400)
			return view.X / 2, view.Y / 2
		end,
		follow = function(x: number, y: number)
			local o = orbit
			if o and not shot and not closing then
				local inset = GuiService:GetGuiInset()
				o:follow(x, y + inset.Y + drawnDown)
			end
		end,
		destroy = function()
			stopDip()
			letGo()
			if room then
				finishClose()
			end
			unbind()
			stage.destroy()
			if test then
				test:Destroy()
				test = nil
			end
		end,
	}
	return camera
end

return ArrangeCamera
