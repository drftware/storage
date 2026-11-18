--!strict
--[[
	ArrangeView: making your home your own (S5-03e3a, D-310; the home doc's idea 12). The moment: in
	your unit you tap Arrange and the camera eases up into the corner by the door, the whole room
	under it like a dollhouse, a faint grid on the floor, your job box's finds in a tray along the
	bottom. Slide your lava lamp up out of the tray and it lifts with a whoosh, outlined white,
	ticking from square to square under your thumb; it glows green on the job box, red in the shelf.
	Place, and it drops with a soft knock and a puff of dust, there for every friend. Tap one
	already set out and it lifts the same way: drag it, Turn it, or Put away. Bloxburg's build mode,
	on a phone.

	The Arrange button shows only to a home's holder while they stand inside it. Arranging takes the
	whole screen: your character stands still (touch controls hidden, the keys sunk), the mouse
	goes free (FreeCursor), and Done eases the camera back.

	The screen judges as the server does: it builds the same room (`Arrange.room`) and loads the
	finds set out from what the server drew (their pose attributes), so the ghost's green or red is
	the server's answer before it's asked. The server still judges every move (Arranging): Place and
	Put away fire its remotes, and a refusal slides the find back where it came from, quietly. The
	tray is the server's count of your box (`Arrange.BoxRemote`), sent as Arrange opens and after
	every move.

	Furniture (S5-03g4c2, D-337): the counter's pieces in your box sit first in the tray, their
	painted art in warm wood rims, and lift out of it as a find does. The job box's Set out comes
	here through `hold`: Arrange rises with the piece already lifted out of the box, gliding down
	to the floor's middle under your thumb, green where it fits. Set down, it lands with a deeper
	knock than a find's; tapped where it stands, it lifts, moves, turns or goes back to the box.

	Only the lifted find steps (its follow, while it's lifted); everything else is tweens.
]]
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Arranged = require(ReplicatedStorage.Shared.Home.Arranged)
local BoxPanel = require(ReplicatedStorage.Shared.Home.BoxPanel)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local FreeCursor = require(script.Parent.FreeCursor)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local FurnitureTab = require(script.Parent.FurnitureTab)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local Grades = require(ReplicatedStorage.Shared.Grades)
local Home = require(ReplicatedStorage.Shared.Home)
local Layout = require(ReplicatedStorage.Shared.Home.Layout)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Looks = require(ReplicatedStorage.Shared.Home.Looks)
local LooksTab = require(script.Parent.LooksTab)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local ToolPicture = require(script.Parent.ToolPicture)
local Tools = require(ReplicatedStorage.Shared.Tools)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

local Feel = Arrange.Feel

-- The job box's panel colours (BoxPanelView, D-287): calm, the box's own dusty blue (D-263).
local PANEL = Color3.fromRGB(29, 40, 45)
local CARD = Color3.fromRGB(43, 57, 63)
local RIM = Color3.fromRGB(106, 138, 147)
local INK = Lobby.Ink
local FITS = Color3.fromRGB(126, 214, 150) -- a soft green: it can stand there
local REFUSED = Color3.fromRGB(232, 92, 80) -- red: it can't
local HEAVY = Font.fromEnum(Enum.Font.BuilderSansExtraBold)

local RISE = TweenInfo.new(Feel.Rise, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LAND = TweenInfo.new(Feel.Land, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BACK = TweenInfo.new(Feel.Back, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local FILL = TweenInfo.new(Feel.Fill, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local HONEY = Color3.fromRGB(247, 201, 120) -- the limit bar's fill: warm, the home's own light
local WOOD = Color3.fromRGB(205, 160, 112) -- a piece of furniture's rim, as the job box draws it

-- A button pressed: the job box panel's click.
local PRESS: Arrange.Sound = {
	id = BoxPanel.Click.id,
	from = 0,
	length = 0.3,
	volume = BoxPanel.Click.volume,
	pitch = BoxPanel.Click.pitch,
}

-- A card pressed while the room holds all it can: the same click, low and dull.
local REFUSE: Arrange.Sound = {
	id = BoxPanel.Click.id,
	from = 0,
	length = 0.3,
	volume = BoxPanel.Click.volume,
	pitch = (BoxPanel.Click.pitch or 1) * 0.62,
}

-- A piece of furniture set down: the find's knock, lower and fuller, a heavy thing on concrete.
local THUD: Arrange.Sound = table.clone(Arrange.Knock)
THUD.pitch = (Arrange.Knock.pitch or 1) * 0.68
THUD.volume = (Arrange.Knock.volume or 0.5) * 1.3

local STILL = "ArrangeStill"
local BODY = "ArrangeBody"
-- What first person draws in front of the camera (ToolView's and InfraredView's held things),
-- hidden with your body while arranging: they ride up with the camera.
local VIEWS = { "YourTool", "YourInfrared" }
-- Your torch is FlashlightView's, which sets its own transparency every frame: it puts it out of
-- sight while this is set on the camera (CaughtLunge's, for a catch; its light is left as it was).
local SEIZED = "CaughtSeized"
-- Above the default controls' bindings, so a key held while arranging moves nobody.
local STILL_PRIORITY = Enum.ContextActionPriority.High.Value + 50
local STILL_KEYS = {
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
	Enum.KeyCode.Up,
	Enum.KeyCode.Down,
	Enum.KeyCode.Left,
	Enum.KeyCode.Right,
	Enum.KeyCode.Space,
}
-- How far past an area's edge a finger still aims at it (studs): a find dragged toward a wall
-- slides along it, flush, rather than stopping short.
local REACH = 2.5
-- How far a finger moves on a tray card before it's a drag (pixels): up lifts, sideways scrolls.
local SLOP = 14
-- The tray's height with the finds in it, and how far under the screen's foot it slides away:
-- far enough that its tabs, standing on its top edge, go with it.
local TRAY = 92
-- The tray's tabs, left to right: the finds, the room's looks, your front (S5-03g3a2).
local FINDS, ROOM, FRONT = 1, 2, 3
local AWAY = 190

-- A find lifted off the floor or out of the tray, as a ghost the finger drags.
type Lifted = {
	what: string, -- what Place sends: the id set out when it's moved, the find's name from the box
	id: string, -- the id the judge checks it as (the next free one for a find from the box)
	name: string,
	shape: Brix.PlacementShape,
	spot: Spots.Spot,
	ghost: Model,
	size: Vector3,
	centre: Vector3,
	highlight: Highlight,
	original: Model?, -- the drawn find, hidden while it's lifted
	starter: string?, -- a home's own piece's kind (`Layout.kind`): it stands by its spec box
	kept: boolean, -- the job box: it moves, never away, so it has no Put away
	riders: { Model }, -- what stands on it, drawn, hidden while copies ride in the ghost (D-338)
	from: CFrame, -- where the ghost began
	pose: Brix.PlacementPose?, -- where it would stand now, snapped
	turn: number,
	fits: boolean,
	target: CFrame,
	asking: string?, -- "place" or "away" while the server's answer is awaited
}

-- A press on a tray card that isn't a drag yet.
type Pending = { key: string, input: InputObject, start: Vector2 }

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function play(spec: Arrange.Sound, parent: Instance)
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = spec.volume
	local pitch = spec.pitch or 1
	s.PlaybackSpeed = pitch
	s.TimePosition = spec.from
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, spec.length / pitch + 0.1)
end

-- Makes `model` scenery the screen alone sees: never collides, touched or picked.
local function inert(model: Model)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		elseif d:IsA("Light") then
			d.Enabled = false
		elseif d:IsA("Sound") or d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
end

-- Hides or shows a drawn find on this screen only.
local function hide(model: Model, hidden: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local ArrangeView = {}

-- The system, and `hold`: opens Arrange holding a piece of furniture from your box by its id,
-- rising from `from` (the job box) when given (S5-03g4c2).
function ArrangeView.new(need: FreeCursor.Need): (Brix.System, (piece: string, from: CFrame?) -> ())
	local me = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local unitWatch: { [Instance]: RBXScriptConnection } = {}
	local home: Model? = nil
	local inside: { face: CFrame, centre: Vector3, size: Vector3 }? = nil
	local running = false
	local open = false
	local room: Arrange.Room? = nil
	local tops: { [string]: boolean } = {} -- finds set out whose top takes another
	local lifted: Lifted? = nil
	local dragInput: InputObject? = nil
	local pending: Pending? = nil
	local follow: RBXScriptConnection? = nil
	local grid: Part? = nil
	local savedCamera: CFrame? = nil
	local touchControls = true
	local lastTick = 0
	local snap = Brix.PlacementSnap.grid({ step = Arrange.Step, turn = Arrange.Turn })

	local gui: ScreenGui? = nil
	local arrangeGroup: CanvasGroup? = nil
	local arrangeScale: UIScale? = nil
	local shown = false
	local doneButton: TextButton? = nil
	local tray: Frame? = nil
	local list: ScrollingFrame? = nil
	local verbs: Frame? = nil
	local placeButton: TextButton? = nil
	local awayButton: TextButton? = nil
	local turnButton: TextButton? = nil
	local cards: { [string]: TextButton } = {}
	-- The tray's three tabs (FINDS, ROOM: the paint tab, FRONT: your door; LooksTab's pages),
	-- which one shows (kept between opens), and where each tab's things rest in the tray (they
	-- slide in to there).
	local roomTab: LooksTab.Tab? = nil
	local frontTab: LooksTab.Tab? = nil
	local tabs: { TextButton } = {}
	local onTab = FINDS
	local listAt, looksAt = UDim2.new(), UDim2.new()
	-- What moves the camera now (the ease over the room, its swing between tabs, the ease back):
	-- a new move stops it, so two never fight over the camera.
	local moving: Tween? = nil
	-- The limit bar: how many finds are set out of the most the home holds (the server's count,
	-- sent with the box), and whether that's all (then a card in the tray won't lift).
	local meter: Frame? = nil
	local meterFill: Frame? = nil
	local meterCount: TextLabel? = nil
	local setOut, most, full = 0, Spots.limit(Spots.Start), false

	local function remote(name: string): RemoteEvent?
		local folder = ReplicatedStorage:FindFirstChild(Spots.RemoteFolder)
		local r = folder and folder:FindFirstChild(name)
		return if r and r:IsA("RemoteEvent") then r else nil
	end

	local function placed(): Instance?
		return if home then home:FindFirstChild(Arrange.Folder) else nil
	end

	-- The sound's parent: the screen's gui (sounds there play for this player only, unplaced).
	local function sounds(): Instance
		return gui or me
	end

	local function tick()
		local now = os.clock()
		if now - lastTick > 0.04 then
			lastTick = now
			play(Arrange.Tick, sounds())
		end
	end

	-- The button's pop when pressed.
	local function press(button: GuiObject)
		local scale = button:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 0.88
			TweenService:Create(scale, POP, { Scale = 1 }):Play()
		end
		play(PRESS, sounds())
	end

	----------------------------------------------------------------------------------------------
	-- The judge, as the server's

	-- Builds the room's judge and loads what's set out in it from what the server drew.
	local function build(): Arrange.Room?
		local unit = home
		local n = if unit then unit:GetAttribute(Arrange.SlotAttribute) else nil
		local slot = if type(n) == "number" then Arrange.slot(n) else nil
		if not (unit and slot) then
			return nil
		end
		-- the home's size, as the server set it from the holder's save (S5-03h1)
		local sized = unit:GetAttribute(Spots.SizeAttribute)
		local r =
			Arrange.room(slot, Lobby.Origin, if type(sized) == "string" then sized else Spots.Start)
		table.clear(tops)
		local waiting: { { id: string, on: string, at: Vector3, model: Model } } = {}
		local folder = placed()
		local children: { Instance } = if folder then folder:GetChildren() else {}
		for _, m in children do
			local id, on, at =
				m:GetAttribute(Spots.IdAttribute),
				m:GetAttribute(Arrange.OnAttribute),
				m:GetAttribute(Arrange.AtAttribute)
			if
				m:IsA("Model")
				and m:GetAttribute(Spots.OwnerAttribute) == me.UserId
				and type(id) == "string"
				and type(on) == "string"
				and typeof(at) == "Vector3"
			then
				table.insert(waiting, { id = id, on = on, at = at, model = m })
			end
		end
		-- what stands on another find goes in after it
		local progress = true
		while progress and #waiting > 0 do
			progress = false
			for i = #waiting, 1, -1 do
				local w = waiting[i]
				local shape = Arrange.shapeOf(w.id)
				if shape and (r.frames[w.on] or r.placements:poseOf(w.on)) then
					r.placements:place(
						w.id,
						shape,
						{ on = w.on, x = w.at.X, y = w.at.Y, turn = w.at.Z }
					)
					local size = Arranged.bounds(w.model)
					if size then
						r.heights[w.id] = size.Y
					end
					if shape.top then
						tops[w.id] = true
					end
					table.remove(waiting, i)
					progress = true
				end
			end
		end
		r.placements:takeEvents() -- the screen draws nothing from these
		return r
	end

	-- Whether `id` stands, however high up, on `base`.
	local function rides(r: Arrange.Room, id: string, base: string): boolean
		local on = id
		for _ = 1, 32 do
			local pose = r.placements:poseOf(on)
			if not pose then
				return false
			elseif pose.on == base then
				return true
			end
			on = pose.on
		end
		return false
	end

	-- The area under screen point `at` that the lifted find fits, nearest first, and the point on
	-- it (`x`, `y` from its middle). Nil over nothing it fits.
	local function aim(r: Arrange.Room, l: Lifted, at: Vector2): (string?, number, number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return nil, 0, 0
		end
		local ray = camera:ScreenPointToRay(at.X, at.Y)
		local best: string? = nil
		local nearest, bx, by = math.huge, 0, 0
		-- something hung from the ceiling follows the finger over the floor under it, as The Sims
		-- hangs a ceiling light from the tile you point at: the corner camera looks down on the
		-- room, so the ceiling itself is seldom on the screen (S5-03g4d)
		local under = r.frames.Floor
		local function try(on: string, f: CFrame, area: Brix.PlacementArea)
			if not table.find(l.shape.fits, area.kind) then
				return
			end
			local plane = if area.kind == Spots.Kinds.Ceiling and under then under else f
			local n = plane.YVector
			local facing = ray.Direction:Dot(n)
			if facing > -1e-4 then
				return -- seen from behind or edge on
			end
			local t = (plane.Position - ray.Origin):Dot(n) / facing
			if t <= 0 or t >= nearest then
				return
			end
			local p = f:PointToObjectSpace(ray.Origin + ray.Direction * t)
			local x, y = p.X, -p.Z
			if math.abs(x) > area.width / 2 + REACH or math.abs(y) > area.depth / 2 + REACH then
				return
			end
			best, nearest, bx, by = on, t, x, y
		end
		for on, f in r.frames do
			local area = r.placements:areaOf(on)
			if area then
				try(on, f, area)
			end
		end
		for id in tops do
			if id ~= l.id and not rides(r, id, l.id) then
				local shape = Arrange.shapeOf(id)
				local f = Arrange.frameOn(r, id)
				if shape and shape.top and f then
					try(id, f, shape.top)
				end
			end
		end
		return best, bx, by
	end

	-- The area `on`'s size, a room's or a find's top.
	local function areaOf(r: Arrange.Room, on: string): Brix.PlacementArea?
		local area = r.placements:areaOf(on)
		if area then
			return area
		end
		local shape = Arrange.shapeOf(on)
		return if shape then shape.top else nil
	end

	-- `x`, `y` on area `on` snapped to the grid and kept inside it, the find turned `turn`.
	local function settle(
		r: Arrange.Room,
		l: Lifted,
		on: string,
		x: number,
		y: number
	): Brix.PlacementPose?
		local area = areaOf(r, on)
		if not area then
			return nil
		end
		local w, d = l.shape.width, l.shape.depth
		if l.turn % 180 == 90 then
			w, d = d, w
		end
		local hx, hy = math.max(0, (area.width - w) / 2), math.max(0, (area.depth - d) / 2)
		local sx, sy, st =
			snap:snap(area, l.shape, math.clamp(x, -hx, hx), math.clamp(y, -hy, hy), l.turn)
		local pose =
			{ on = on, x = math.clamp(sx, -hx, hx), y = math.clamp(sy, -hy, hy), turn = st }
		local kind, floor = l.starter, r.placements:areaOf("Floor")
		if kind and floor and Layout.Lean[kind] then
			-- the mirror finds the wall nearest the finger and turns its back to it (D-348)
			local leant = Layout.leanTo(kind, pose, floor)
			if leant then
				l.turn = leant.turn
				return leant
			end
		elseif kind and floor then
			return Layout.clearOf(kind, pose, floor) -- the job box keeps its lid's room
		end
		return pose
	end

	-- Whether `l` may stand at `pose`: Brix's judge, and the mirror against a wall, as the
	-- server's.
	local function fitsAt(r: Arrange.Room, l: Lifted, pose: Brix.PlacementPose): boolean
		if r.placements:check(l.id, l.shape, pose) ~= nil then
			return false
		end
		local kind, floor = l.starter, r.placements:areaOf("Floor")
		return not (kind and floor) or Layout.stands(kind, pose, floor)
	end

	-- Where the find's pivot stands at `pose`, and the area's normal (out of it, into the room).
	local function standAt(r: Arrange.Room, l: Lifted, pose: Brix.PlacementPose): (CFrame?, Vector3)
		local a = Arrange.frameOn(r, pose.on)
		if not a then
			return nil, Vector3.yAxis
		end
		local t = Arranged.pose(a, pose.x, pose.y, pose.turn)
		local kind = l.starter
		if kind then -- by its spec box, as the server draws it (the mirror keeps its lean)
			return Arrange.starterPivot(t, kind), t.YVector
		end
		return Arranged.pivot(t, l.spot, l.size, l.centre), t.YVector
	end

	----------------------------------------------------------------------------------------------
	-- The lifted find

	local function paint(l: Lifted)
		local h = l.highlight
		h.OutlineColor = if l.fits then Color3.new(1, 1, 1) else REFUSED
		h.FillColor = if l.fits then FITS else REFUSED
		h.FillTransparency = if l.fits then 0.78 else 0.55
		local p = placeButton
		if p then
			TweenService:Create(p, QUICK, {
				BackgroundColor3 = if l.fits then FITS else CARD,
				TextTransparency = if l.fits then 0 else 0.55,
			}):Play()
		end
	end

	-- Moves the lifted find to `pose`, hovering over it, and judges it there.
	local function setPose(r: Arrange.Room, l: Lifted, pose: Brix.PlacementPose)
		local at, normal = standAt(r, l, pose)
		if not at then
			return
		end
		local was = l.pose
		local moved = not was
			or was.on ~= pose.on
			or was.x ~= pose.x
			or was.y ~= pose.y
			or was.turn ~= pose.turn
		l.pose = pose
		l.fits = fitsAt(r, l, pose)
		l.target = at + normal * Feel.Hover
		paint(l)
		if moved and was then
			tick()
		end
	end

	local function aimAt(at: Vector2)
		local r, l = room, lifted
		if not (r and l) or l.asking then
			return
		end
		local on, x, y = aim(r, l, at)
		local pose = if on then settle(r, l, on, x, y) else nil
		if pose then
			setPose(r, l, pose)
		end
	end

	local function stopFollow()
		if follow then
			follow:Disconnect()
			follow = nil
		end
	end

	-- The ghost eases after its target each frame while it's lifted (the one thing that steps).
	local function startFollow()
		if follow then
			return
		end
		follow = RunService.RenderStepped:Connect(function(dt: number)
			local l = lifted
			if not l or l.asking then
				stopFollow()
				return
			end
			l.ghost:PivotTo(l.ghost:GetPivot():Lerp(l.target, 1 - 0.5 ^ (dt / Feel.Follow)))
		end)
	end

	-- The verbs pop in at the corner while a find is lifted, and the tray slides down out of the
	-- way so the floor by the door shows; it slides back up when the find is set down or let go.
	local function showVerbs(l: Lifted?)
		local v = verbs
		if v then
			local was = v.Visible
			v.Visible = l ~= nil
			local scale = v:FindFirstChildOfClass("UIScale")
			if scale and l and not was then
				scale.Scale = 0.8
				TweenService:Create(scale, POP, { Scale = 1 }):Play()
			end
		end
		local t = tray
		if t and open then
			TweenService:Create(t, QUICK, {
				Position = UDim2.new(0.5, 0, 1, if l then AWAY else -10),
			}):Play()
		end
		local a = awayButton
		if a then
			a.Visible = l ~= nil and l.original ~= nil and not l.kept
		end
		local turner = turnButton
		if turner then -- the mirror turns itself to the wall it's carried to
			turner.Visible = not (l and l.starter and Layout.Lean[l.starter])
		end
		local s = list
		if s then
			s.ScrollingEnabled = l == nil
		end
	end

	-- Lets the ghost go: gone, the drawn find shown again (unless it was put away).
	local function letGo(l: Lifted, showOriginal: boolean)
		if lifted == l then
			lifted = nil
			stopFollow()
			showVerbs(nil)
		end
		l.ghost:Destroy()
		if l.original and showOriginal then
			hide(l.original, false)
			for _, m in l.riders do
				hide(m, false)
			end
		end
	end

	-- What stands on `id`, however high up, as drawn here, into `out`.
	local function ridersOf(r: Arrange.Room, id: string, out: { Model }): { Model }
		local folder = placed()
		for _, rider in r.placements:standingOn(id) do
			local m = if folder then folder:FindFirstChild(rider) else nil
			if m and m:IsA("Model") then
				table.insert(out, m)
			end
			ridersOf(r, rider, out)
		end
		return out
	end

	-- Makes the ghost of `source` (a drawn find, or a fresh copy from the box) and lifts it.
	local function lift(what: string, id: string, name: string, ghost: Model, original: Model?)
		local r = room
		local shape = Arrange.shapeOf(id)
		local size, centre = Arranged.bounds(ghost)
		if not (r and shape and size and centre) then
			ghost:Destroy()
			return
		end
		inert(ghost)
		for _, tag in ghost:GetTags() do
			ghost:RemoveTag(tag)
		end
		local highlight = Instance.new("Highlight")
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- seen through the shelf it's in
		highlight.OutlineTransparency = 0
		highlight.Adornee = ghost
		highlight.Parent = ghost
		ghost.Parent = Workspace.CurrentCamera
		local from = ghost:GetPivot()
		local kind = Layout.kind(id)
		local row = if kind then Furniture.byId(kind) else nil
		local l: Lifted = {
			what = what,
			id = id,
			name = name,
			shape = shape,
			spot = Spots.spot(name),
			ghost = ghost,
			size = size,
			centre = centre,
			highlight = highlight,
			original = original,
			starter = kind,
			kept = row ~= nil and row.kept == true,
			riders = {},
			from = from,
			pose = nil,
			turn = 0,
			fits = false,
			target = from,
			asking = nil,
		}
		lifted = l
		if original then
			hide(original, true)
			-- the moon lamp on the pallet rides with it: a copy in the ghost, the drawn one hidden
			for _, m in ridersOf(r, id, {}) do
				local copy = m:Clone()
				inert(copy)
				for _, tag in copy:GetTags() do
					copy:RemoveTag(tag)
				end
				copy.Parent = ghost
				hide(m, true)
				table.insert(l.riders, m)
			end
			local pose = r.placements:poseOf(id)
			if pose then
				l.turn = pose.turn
				setPose(r, l, { on = pose.on, x = pose.x, y = pose.y, turn = pose.turn })
			end
		end
		play(Arrange.Lift, sounds())
		showVerbs(l)
		startFollow()
	end

	-- Lifts find `id`, drawn as `model`, off where it stands.
	local function liftDrawn(model: Model)
		local id = model:GetAttribute(Spots.IdAttribute)
		local name = if type(id) == "string" then Spots.name(id) else nil
		if not (type(id) == "string" and name) then
			return
		end
		local ghost = model:Clone()
		ghost:PivotTo(model:GetPivot())
		lift(id, id, name, ghost, model)
	end

	-- The spot nearest its middle where `l` fits on the first of its starting areas with room
	-- (`Spots.starts`: the floor; the ceiling; the back wall, then the sides), in rings of grid
	-- steps outward; the first area's middle when none does (it shows red, and the thumb takes it
	-- from there).
	local function freeSpot(r: Arrange.Room, l: Lifted): Brix.PlacementPose?
		local starts = Spots.starts(l.spot)
		local first = settle(r, l, starts[1], 0, 0)
		local step = Arrange.Step
		for _, on in starts do
			local area = areaOf(r, on)
			if not area then
				continue
			end
			local reach = math.ceil(math.max(area.width, area.depth) / 2 / step)
			for ring = 0, reach do
				for i = -ring, ring do
					for j = -ring, ring do
						if math.max(math.abs(i), math.abs(j)) == ring then
							local pose = settle(r, l, on, i * step, j * step)
							if pose and fitsAt(r, l, pose) then
								return pose
							end
						end
					end
				end
			end
		end
		return first
	end

	-- Lifts a find, or a piece of furniture by its placed name, out of the box: under screen point
	-- `at`, or from `from` (the job box, for the panel's Set out) down onto the floor's middle.
	local function liftBoxed(key: string, at: Vector2?, from: CFrame?)
		if full then
			return -- the room holds all it can: the card dims and won't lift
		end
		local r = room
		local piece = Furniture.ofPlaced(key)
		local template = if piece then Home.template() else nil
		local base = if piece then nil else Gold.base(key)
		local ghost: Model? = nil
		if r and piece and template and piece.id == "Mirror" and Home.has(template, piece.id) then
			-- leaning on its foot, pivoted upright there, as the server draws it
			local m = Home.mirrorAt(template, CFrame.identity, Workspace)
			m.WorldPivot = CFrame.identity
			ghost = m
		elseif r and piece and template and Home.has(template, piece.id) then
			ghost = Home.piece(template, piece.id, CFrame.identity, Workspace)
		elseif r and not piece then
			ghost = Tools.clone(base or key, CFrame.identity)
		end
		if not (r and ghost) then
			return
		end
		if base then
			Gold.gild(ghost)
		end
		local id = Spots.nextId(key, function(each: string): boolean
			return r.placements:poseOf(each) ~= nil
		end)
		local camera = Workspace.CurrentCamera
		if from then -- it rises out of the job box
			ghost:PivotTo(from + Vector3.yAxis * 1.5)
		elseif camera and at then -- it rises out of the tray toward the room
			local ray = camera:ScreenPointToRay(at.X, at.Y)
			ghost:PivotTo(CFrame.new(ray.Origin + ray.Direction * 6))
		end
		lift(key, id, key, ghost, nil)
		if at then
			aimAt(at)
		end
		local l = lifted
		if l and not l.pose then -- over nothing it fits: start it on the floor's middle
			-- out of the job box with no thumb on it: the free spot nearest the middle, so it
			-- arrives green (S5-03g4c2)
			local pose = if from
				then freeSpot(r, l)
				else settle(r, l, Spots.starts(l.spot)[1], 0, 0)
			if pose then
				setPose(r, l, pose)
			end
		end
	end

	-- Slides the lifted find back where it came from (refused, cancelled) or, for one from the
	-- box, shrinks it away, quietly.
	local function slideBack(l: Lifted)
		l.asking = "back"
		stopFollow()
		play(Arrange.Slide, sounds())
		l.highlight.Enabled = false
		if l.original then
			local cf = Instance.new("CFrameValue")
			cf.Value = l.ghost:GetPivot()
			cf.Changed:Connect(function(v: CFrame)
				l.ghost:PivotTo(v)
			end)
			local t = TweenService:Create(cf, BACK, { Value = l.from })
			t.Completed:Once(function()
				cf:Destroy()
				letGo(l, true)
			end)
			t:Play()
		else
			local scale = Instance.new("NumberValue")
			scale.Value = 1
			scale.Changed:Connect(function(v: number)
				if v > 0.02 then
					l.ghost:ScaleTo(v)
				end
			end)
			local t = TweenService:Create(scale, BACK, { Value = 0.05 })
			t.Completed:Once(function()
				scale:Destroy()
				letGo(l, false)
			end)
			t:Play()
		end
		showVerbs(nil)
		lifted = nil
	end

	-- A puff of dust where a find lands.
	local function puff(at: CFrame)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.CFrame = at
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(214, 202, 182))
		e.LightEmission = 0
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1.1),
		})
		e.Lifetime = NumberRange.new(0.4, 0.7)
		e.Speed = NumberRange.new(2, 3.5)
		e.Drag = 6
		e.SpreadAngle = Vector2.new(90, 90)
		e.EmissionDirection = Enum.NormalId.Top
		e.Rate = 0
		e.Parent = p
		p.Parent = Workspace.CurrentCamera
		e:Emit(Feel.Puff)
		Debris:AddItem(p, 1.2)
	end

	-- Place: the ghost drops onto its spot with a knock and a puff; the server's answer keeps it.
	local function placeNow()
		local r, l = room, lifted
		local ask = remote(Spots.PlaceRemote)
		if not (r and l and ask) or l.asking or not l.fits then
			return -- red, or already asked: the press does nothing
		end
		local pose = l.pose
		local at = if pose then (standAt(r, l, pose)) else nil
		if not (pose and at) then
			return
		end
		l.asking = "place"
		stopFollow()
		showVerbs(nil)
		ask:FireServer(l.what, pose.on, pose.x, pose.y, pose.turn)
		task.delay(3, function()
			if lifted == l and l.asking == "place" then
				slideBack(l) -- no answer: as if refused
			end
		end)
		local cf = Instance.new("CFrameValue")
		cf.Value = l.ghost:GetPivot()
		cf.Changed:Connect(function(v: CFrame)
			l.ghost:PivotTo(v)
		end)
		local t = TweenService:Create(cf, LAND, { Value = at })
		t.Completed:Once(function()
			cf:Destroy()
			if l.ghost.Parent then
				play(if Furniture.ofPlaced(l.name) then THUD else Arrange.Knock, sounds())
				local stand = Arrange.frameOn(r, pose.on)
				puff(if stand then Arranged.pose(stand, pose.x, pose.y, pose.turn) else at)
				TweenService
					:Create(l.highlight, QUICK, { OutlineTransparency = 1, FillTransparency = 1 })
					:Play()
			end
		end)
		t:Play()
	end

	local function turnNow()
		local r, l = room, lifted
		if not (r and l) or l.asking then
			return
		end
		l.turn = (l.turn + Arrange.Turn) % 360
		local pose = l.pose
		if pose then
			local fresh = settle(r, l, pose.on, pose.x, pose.y)
			if fresh then
				setPose(r, l, fresh)
			end
		end
	end

	-- Put away: the find shrinks back toward the tray; the server's answer puts it in the box.
	local function awayNow()
		local l = lifted
		local ask = remote(Spots.PutAwayRemote)
		if not (l and l.original and ask) or l.asking or l.kept then
			return -- the job box holds everything: it has no Put away
		end
		l.asking = "away"
		stopFollow()
		showVerbs(nil)
		ask:FireServer(l.id)
		task.delay(3, function()
			if lifted == l and l.asking == "away" then
				letGo(l, true) -- no answer: it stays where it was
			end
		end)
		play(Arrange.Slide, sounds())
		l.highlight.Enabled = false
		local scale = Instance.new("NumberValue")
		scale.Value = 1
		scale.Changed:Connect(function(v: number)
			if v > 0.02 and l.ghost.Parent then
				l.ghost:ScaleTo(v)
			end
		end)
		local t = TweenService:Create(scale, BACK, { Value = 0.05 })
		t.Completed:Once(function()
			scale:Destroy()
			l.ghost.Parent = nil -- gone; the answer lets it go
		end)
		t:Play()
	end

	-- Waits (briefly) for the server's drawn find to stand where the ghost landed, then lets the
	-- ghost go, so there's never a gap.
	local function settleOnto(l: Lifted, id: string)
		task.spawn(function()
			local deadline = os.clock() + 1.5
			while os.clock() < deadline do
				local folder = placed()
				local drawn = if l.original
					then l.original
					else if folder then folder:FindFirstChild(id) else nil
				if drawn and drawn:IsA("Model") then
					if drawn:GetPivot().Position:FuzzyEq(l.ghost:GetPivot().Position, 0.05) then
						break
					end
				end
				task.wait(0.05)
			end
			letGo(l, true)
		end)
	end

	-- The server's answer to a Place or a Put away: kept, or slid back quietly.
	local function answered(what: unknown, id: unknown, refusal: unknown)
		local r, mine = room, lifted
		if
			not (r and mine and mine.asking)
			or type(what) ~= "string"
			or type(id) ~= "string"
			or type(refusal) ~= "string"
			or mine.what ~= what
		then
			return
		end
		local pose = mine.pose
		if mine.asking == "place" then
			if refusal == "" and id ~= "" and pose then
				r.placements:place(id, mine.shape, pose)
				r.placements:takeEvents()
				r.heights[id] = mine.size.Y
				if mine.shape.top then
					tops[id] = true
				end
				settleOnto(mine, id)
			else
				slideBack(mine)
			end
		elseif mine.asking == "away" then
			if refusal == "" then
				local function away(each: string)
					for _, rider in r.placements:standingOn(each) do
						away(rider)
					end
					r.placements:remove(each)
					r.heights[each] = nil
					tops[each] = nil
				end
				away(mine.id)
				r.placements:takeEvents()
				letGo(mine, false)
			else
				letGo(mine, true)
			end
		end
	end

	----------------------------------------------------------------------------------------------
	-- The tray: what's in your job box

	-- Dims a tray card while the room holds all it can (no words: it just won't lift), or brings it
	-- back; eased when it changes as you watch.
	local function dim(card: TextButton, on: boolean, eased: boolean)
		local function to(inst: Instance?, goal: { [string]: number })
			if not inst then
				return
			elseif eased then
				TweenService:Create(inst, FILL, goal):Play()
			else
				for k, v in goal do
					(inst :: any)[k] = v -- any: a property named by the goal, as a tween sets it
				end
			end
		end
		to(card, { BackgroundTransparency = if on then 0.55 else 0 })
		to(
			card:FindFirstChildOfClass("ViewportFrame"),
			{ ImageTransparency = if on then 0.6 else 0 }
		)
		to(card:FindFirstChildOfClass("UIStroke"), { Transparency = if on then 0.7 else 0 })
		to(card:FindFirstChildOfClass("TextLabel"), { TextTransparency = if on then 0.6 else 0 })
	end

	-- A dimmed card pressed: it shakes its head, the bar pulses, a dull click. That's the answer:
	-- the bar is full.
	local function refuse(card: TextButton)
		play(REFUSE, sounds())
		card.Rotation = 0
		local shake =
			TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true)
		TweenService:Create(card, shake, { Rotation = 7 }):Play()
		local m = meter
		local mScale = if m then m:FindFirstChildOfClass("UIScale") else nil
		if mScale then
			mScale.Scale = 1.14
			TweenService:Create(mScale, POP, { Scale = 1 }):Play()
		end
		local f = meterFill
		if f then
			f.BackgroundColor3 = Color3.new(1, 1, 1)
			TweenService:Create(f, FILL, { BackgroundColor3 = HONEY }):Play()
		end
	end

	-- Rebuilds the tray's cards from the box's counts, rarest first.
	local function fillTray(
		counts: { [string]: number },
		dimmedBefore: boolean,
		pieces: { [string]: number }
	)
		local s = list
		if not s then
			return
		end
		for _, c in cards do
			c:Destroy()
		end
		table.clear(cards)
		local template = Home.template()
		-- the furniture first, then the finds
		local dealt: { BoxPanel.Card } = {}
		for _, card in BoxPanel.pieces(pieces) do
			if BoxPanel.settable(card) then
				table.insert(dealt, card)
			end
		end
		for _, card in BoxPanel.cards(counts, Tools.Catalog :: any) do -- any: its rows carry more than Row
			table.insert(dealt, card)
		end
		for i, card in dealt do
			local piece = card.piece
			if piece and not (template and Home.has(template, piece)) then
				continue -- the place lacks its art: nothing to stand
			elseif not piece and not Tools.template(card.base or card.key) then
				continue -- not in the place yet: nothing to stand
			end
			local b = Instance.new("TextButton")
			b.Name = card.key
			b.Text = ""
			b.AutoButtonColor = false
			b.LayoutOrder = i
			b.Size = UDim2.fromOffset(72, 72)
			b.BackgroundColor3 = CARD
			corner(b, UDim.new(0, 12))
			local rim = Instance.new("UIStroke")
			local rgb = Grades.Colours[card.grade]
			rim.Color = if piece
				then WOOD
				elseif rgb then Color3.fromRGB(rgb[1], rgb[2], rgb[3])
				else RIM
			rim.Thickness = 2
			rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			rim.Parent = b
			local vp = Instance.new("ViewportFrame")
			vp.BackgroundTransparency = 1
			vp.Size = UDim2.fromScale(1, 1)
			vp.Parent = b
			if piece then
				FurnitureTab.picture(vp, piece)
			else
				ToolPicture.draw(vp, card.key)
			end
			if card.count > 1 then
				local badge = Instance.new("TextLabel")
				badge.BackgroundTransparency = 1
				badge.AnchorPoint = Vector2.new(1, 1)
				badge.Position = UDim2.new(1, -5, 1, -2)
				badge.Size = UDim2.fromOffset(40, 18)
				badge.TextXAlignment = Enum.TextXAlignment.Right
				badge.FontFace = HEAVY
				badge.TextSize = 15
				badge.TextColor3 = INK
				badge.Text = BoxPanel.badge(card.count)
				badge.Parent = b
			end
			b.InputBegan:Connect(function(input: InputObject)
				local t = input.UserInputType
				local pressed = t == Enum.UserInputType.Touch
					or t == Enum.UserInputType.MouseButton1
				if pressed and full and not lifted then
					refuse(b)
				elseif pressed and not lifted and not pending then
					pending = {
						key = card.key,
						input = input,
						start = Vector2.new(input.Position.X, input.Position.Y),
					}
				end
			end)
			b.Parent = s
			cards[card.key] = b
			if full then
				dim(b, true, not dimmedBefore) -- it fills up as you watch: the cards dim, eased
			elseif dimmedBefore then
				dim(b, true, false) -- room again: they light back up
				dim(b, false, true)
			end
		end
	end

	-- The limit bar shows `count` set out of `limit`: the fill eases there, the count pops when it
	-- changes, and the cards dim at the limit.
	local function showMeter(count: number, limit: number)
		local changed = count ~= setOut or limit ~= most
		setOut, most = count, limit
		local f, isFull = Spots.fill(count, limit)
		full = isFull
		local fill, label = meterFill, meterCount
		if fill then
			TweenService:Create(fill, FILL, { Size = UDim2.fromScale(f, 1) }):Play()
		end
		if label then
			label.Text = `{count}/{limit}`
			TweenService:Create(label, FILL, { TextColor3 = if isFull then HONEY else INK }):Play()
			local pop = label:FindFirstChildOfClass("UIScale")
			if pop and changed then
				pop.Scale = 1.25
				TweenService:Create(pop, POP, { Scale = 1 }):Play()
			end
		end
	end

	-- The box's counts, then how many finds are set out of the most the home holds, then the
	-- furniture in the box by piece id (D-336).
	local function onBox(counts: unknown, out: unknown, limit: unknown, pieces: unknown)
		local read = BoxPanel.read(counts)
		if not (read and open) then
			return
		end
		local before = full
		if
			type(out) == "number"
			and type(limit) == "number"
			and out == out // 1
			and limit == limit // 1
			and out >= 0
			and out <= 1000
			and limit >= 0
			and limit <= 1000
		then
			showMeter(out, limit)
		end
		fillTray(read, before, BoxPanel.read(pieces) or {})
	end

	----------------------------------------------------------------------------------------------
	-- Opening and closing

	local function showButton(on: boolean)
		local g, s = arrangeGroup, arrangeScale
		if not (g and s) or on == shown then
			return
		end
		shown = on
		g.Visible = true
		TweenService:Create(g, QUICK, { GroupTransparency = if on then 0 else 1 }):Play()
		local t =
			TweenService:Create(s, if on then POP else QUICK, { Scale = if on then 1 else 0.7 })
		t.Completed:Once(function()
			if not shown then
				g.Visible = false
			end
		end)
		t:Play()
	end

	-- The camera high in the corner by the door, the room under it.
	local function view(r: Arrange.Room): CFrame
		local c, s = r.centre, r.size
		local eye = r.face * Vector3.new(c.X, c.Y + s.Y / 2 - Feel.Below, c.Z - s.Z / 2 + Feel.In)
		local look = r.face * Vector3.new(c.X, c.Y - s.Y / 2, c.Z + s.Z * Feel.Look)
		return CFrame.lookAt(eye, look)
	end

	-- The camera on the front tab: near the back of the room, a little over head height, facing
	-- the door; the doorway's head and an open door's coil in view above the tray (S5-03g3a2).
	local function front(r: Arrange.Room): CFrame
		local c, s = r.centre, r.size
		local door, floor = c.Z - s.Z / 2, c.Y - s.Y / 2
		local back = math.min(Feel.FrontBack, s.Z - 1)
		local eye = r.face * Vector3.new(c.X, floor + Feel.FrontEye, door + back)
		local look = r.face * Vector3.new(c.X, floor + Feel.FrontAim, door)
		return CFrame.lookAt(eye, look)
	end

	local function stopMoving()
		local m = moving
		moving = nil
		if m then
			m:Cancel()
		end
	end

	-- Where a camera at `cf` stands in the room's frame, and its heading and tilt (radians).
	local function heading(cf: CFrame, face: CFrame): (Vector3, number, number)
		local l = face:ToObjectSpace(cf)
		local look = l.LookVector
		return l.Position, math.atan2(-look.X, -look.Z), math.asin(math.clamp(look.Y, -1, 1))
	end

	-- Swings the camera from where it is to `goal` over `Feel.Rise`: its place, heading and tilt
	-- eased apart, so the half turn from the dollhouse corner round to the door never rolls the
	-- picture over, as one tween of the whole CFrame would.
	local function swing(r: Arrange.Room, goal: CFrame)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		stopMoving()
		local face = r.face
		local p0, y0, t0 = heading(camera.CFrame, face)
		local p1, y1, t1 = heading(goal, face)
		local turn = (y1 - y0 + math.pi) % (2 * math.pi) - math.pi -- the short way round
		if math.abs(turn) > math.pi - 0.05 then
			turn = math.pi -- a half turn: always round by the left, never a shudder between ways
		end
		local value = Instance.new("NumberValue")
		value.Changed:Connect(function(a: number)
			camera.CFrame = face
				* CFrame.new(p0:Lerp(p1, a))
				* CFrame.Angles(0, y0 + turn * a, 0)
				* CFrame.Angles(t0 + (t1 - t0) * a, 0, 0)
		end)
		local tween = TweenService:Create(value, RISE, { Value = 1 })
		tween.Completed:Once(function()
			value:Destroy()
			if moving == tween then
				moving = nil
			end
		end)
		moving = tween
		tween:Play()
	end

	-- The faint grid on the floor, a line each `Feel.Grid` studs from its edges.
	local function makeGrid(r: Arrange.Room): Part?
		local f = r.frames.Floor
		local area = r.placements:areaOf("Floor")
		if not (f and area) then
			return nil
		end
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(area.width, 0.05, area.depth)
		p.CFrame = f * CFrame.new(0, Feel.GridLift, 0)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Top
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 24
		sg.LightInfluence = 0
		sg.Adornee = p
		sg.Parent = p
		local function line(alongX: boolean, at: number)
			local l = Instance.new("Frame")
			l.BorderSizePixel = 0
			l.BackgroundColor3 = Color3.new(1, 1, 1)
			l.BackgroundTransparency = 1
			l.AnchorPoint = Vector2.new(0.5, 0.5)
			l.Size = if alongX
				then UDim2.new(0, Feel.GridLine, 1, 0)
				else UDim2.new(1, 0, 0, Feel.GridLine)
			l.Position = if alongX then UDim2.fromScale(at, 0.5) else UDim2.fromScale(0.5, at)
			l.Parent = sg
			TweenService:Create(l, RISE, { BackgroundTransparency = Feel.GridFade }):Play()
		end
		for i = 1, math.floor(area.width / Feel.Grid - 1e-6) do
			line(true, i * Feel.Grid / area.width)
		end
		for i = 1, math.floor(area.depth / Feel.Grid - 1e-6) do
			line(false, i * Feel.Grid / area.depth)
		end
		p.Parent = Workspace.CurrentCamera
		return p
	end

	local function still(on: boolean)
		if on then
			touchControls = GuiService.TouchControlsEnabled
			GuiService.TouchControlsEnabled = false
			ContextActionService:BindActionAtPriority(STILL, function(): Enum.ContextActionResult
				return Enum.ContextActionResult.Sink
			end, false, STILL_PRIORITY, table.unpack(STILL_KEYS))
		else
			GuiService.TouchControlsEnabled = touchControls
			ContextActionService:UnbindAction(STILL)
		end
	end

	-- Your own body (and what you hold or wear) hidden from your eyes while you arrange: the camera
	-- hangs over where you stand, and your head would hide the floor by the door. Roblox's camera
	-- scripts set each part's LocalTransparencyModifier as the camera moves, so while it rises this
	-- holds them hidden each frame after the camera's step; once it's still, nothing rewrites them.
	local hiddenParts: { BasePart } = {}
	local hiddenDecals: { Decal } = {}
	local bodyRun = 0
	local function fade(value: number)
		for _, p in hiddenParts do
			p.LocalTransparencyModifier = value
		end
		for _, d in hiddenDecals do
			d.LocalTransparencyModifier = value
		end
	end
	local function body(hidden: boolean)
		RunService:UnbindFromRenderStep(BODY)
		bodyRun += 1
		local run = bodyRun
		if hidden then
			table.clear(hiddenParts)
			table.clear(hiddenDecals)
			local roots: { Instance } = {}
			for _, name in VIEWS do
				local held = Workspace:FindFirstChild(name)
				if held then
					table.insert(roots, held)
				end
			end
			if me.Character then
				table.insert(roots, me.Character)
			end
			for _, root in roots do
				for _, d in root:GetDescendants() do
					if d:IsA("BasePart") then
						table.insert(hiddenParts, d)
					elseif d:IsA("Decal") then
						table.insert(hiddenDecals, d)
					end
				end
			end
			RunService:BindToRenderStep(BODY, Enum.RenderPriority.Camera.Value + 1, function()
				fade(1)
			end)
			task.delay(Feel.Rise + 0.1, function()
				if run == bodyRun then
					RunService:UnbindFromRenderStep(BODY)
				end
			end)
		else
			fade(0)
			table.clear(hiddenParts)
			table.clear(hiddenDecals)
		end
	end

	-- Where the limit bar rests on tab `n`: over the room, or up off the screen on the front tab,
	-- where it would cover the door's coil and has no finds to count (-60 still peeks into the
	-- top bar's strip, which the gui doesn't own but draws over).
	local function meterAt(n: number): UDim2
		return UDim2.new(0.5, 0, 0, if n == FRONT then -120 else 20)
	end

	-- The tray's height on tab `n`.
	local function trayHeight(n: number): number
		return if n == ROOM
			then LooksTab.Heights.room
			elseif n == FRONT then LooksTab.Heights.front
			else TRAY
	end

	-- Shows tab `n` of the tray: the tray grows or shrinks to fit, the tab's things slide in from
	-- the side it lies on (the looks pop in chip by chip), and the tab you're on lights up. The
	-- front tab swings the camera round to face your door, the others back over the room.
	local function showTab(n: number, eased: boolean)
		local was = onTab
		local changed = n ~= was
		onTab = n
		pending = nil
		local t, s = tray, list
		local pages: { [number]: GuiObject? } = {
			[FINDS] = s,
			[ROOM] = if roomTab then roomTab.root else nil,
			[FRONT] = if frontTab then frontTab.root else nil,
		}
		if t then
			local size = UDim2.new(1, -28, 0, trayHeight(n))
			if eased then
				TweenService:Create(t, QUICK, { Size = size }):Play()
			else
				t.Size = size
			end
		end
		for i = FINDS, FRONT do
			local page = pages[i]
			if page then
				page.Visible = i == n
			end
		end
		if eased and changed then
			local coming = pages[n]
			local at = if n == FINDS then listAt else looksAt
			if coming then
				coming.Position = at + UDim2.fromOffset(if n > was then 28 else -28, 0)
				TweenService:Create(coming, QUICK, { Position = at }):Play()
			end
			local lt = if n == ROOM then roomTab elseif n == FRONT then frontTab else nil
			if lt then
				lt.reveal()
			end
		end
		local r, m = room, meter
		if open and r and changed and (n == FRONT or was == FRONT) then
			swing(r, if n == FRONT then front(r) else view(r))
			if m then -- the limit bar counts finds: it rises off the top while you face the door
				TweenService:Create(m, RISE, { Position = meterAt(n) }):Play()
			end
		end
		-- The tab you're on wears the white ring a worn look's chip does; the others stay solid
		-- enough that the wallpaper's pattern doesn't muddy their icons (S5-03g2b3).
		for i, b in tabs do
			local on = i == n
			local icon = b:FindFirstChild("Icon")
			local edge = b:FindFirstChildOfClass("UIStroke")
			local faded = if on then 0 else 0.35
			local ring = {
				Color = if on then Color3.new(1, 1, 1) else RIM,
				Transparency = if on then 0 else 0.5,
				Thickness = if on then 2 else 1,
			}
			if eased then
				if icon then
					TweenService:Create(icon, QUICK, { GroupTransparency = faded }):Play()
				end
				if edge then
					TweenService:Create(edge, QUICK, ring):Play()
				end
			else
				if icon and icon:IsA("CanvasGroup") then
					icon.GroupTransparency = faded
				end
				if edge then
					edge.Color, edge.Transparency, edge.Thickness =
						ring.Color, ring.Transparency, ring.Thickness
				end
			end
		end
	end

	-- Whose look and door the paint and front tabs show and ring (nil: none, while closed).
	local function attachTabs(u: Model?)
		local a, b = roomTab, frontTab
		if a then
			a.attach(u)
		end
		if b then
			b.attach(u)
		end
	end

	local function openNow()
		local camera = Workspace.CurrentCamera
		if open or not camera then
			return
		end
		local r = build()
		if not r then
			return
		end
		room = r
		open = true
		still(true)
		body(true)
		me:SetAttribute(Tools.StowAttribute, true) -- the tool wheel slides away, clear of the room
		camera:SetAttribute(SEIZED, true)
		need("ArrangeView", true)
		showButton(false)
		savedCamera = camera.CFrame
		camera.CameraType = Enum.CameraType.Scriptable
		stopMoving()
		local rise = TweenService:Create(
			camera,
			RISE,
			{ CFrame = if onTab == FRONT then front(r) else view(r) }
		)
		moving = rise
		rise:Play()
		grid = makeGrid(r)
		local d, t, m = doneButton, tray, meter
		if d then
			d.Visible = true
		end
		if m then
			m.Visible = true
			m.Position = UDim2.new(0.5, 0, 0, -60)
			TweenService:Create(m, RISE, { Position = meterAt(onTab) }):Play()
		end
		if t then
			t.Visible = true
			t.Size = UDim2.new(1, -28, 0, trayHeight(onTab))
			t.Position = UDim2.new(0.5, 0, 1, AWAY)
			TweenService:Create(t, RISE, { Position = UDim2.new(0.5, 0, 1, -10) }):Play()
		end
		attachTabs(home) -- their rings follow the home's look and door while you arrange
		local ask = remote(Arrange.BoxRemote)
		if ask then
			ask:FireServer()
		end
	end

	local function closeNow()
		if not open then
			return
		end
		local l = lifted
		if l and not l.asking then
			slideBack(l)
		end
		open = false
		pending = nil
		dragInput = nil
		attachTabs(nil)
		still(false)
		body(false)
		me:SetAttribute(Tools.StowAttribute, nil) -- the wheel comes back up
		local seized = Workspace.CurrentCamera
		if seized then
			seized:SetAttribute(SEIZED, nil)
		end
		need("ArrangeView", false)
		local camera = Workspace.CurrentCamera
		if camera then
			local back = savedCamera
			stopMoving()
			if back then
				local t = TweenService:Create(camera, RISE, { CFrame = back })
				moving = t
				t.Completed:Once(function()
					if not open then
						camera.CameraType = Enum.CameraType.Custom
					end
				end)
				t:Play()
			else
				camera.CameraType = Enum.CameraType.Custom
			end
		end
		local g = grid
		grid = nil
		if g then
			Debris:AddItem(g, 0)
		end
		local d, t, m = doneButton, tray, meter
		if d then
			d.Visible = false
		end
		if m then
			local tw = TweenService:Create(m, QUICK, { Position = UDim2.new(0.5, 0, 0, -60) })
			tw.Completed:Once(function()
				if not open then
					m.Visible = false
				end
			end)
			tw:Play()
		end
		if t then
			local tw = TweenService:Create(t, QUICK, { Position = UDim2.new(0.5, 0, 1, AWAY) })
			tw.Completed:Once(function()
				if not open then
					t.Visible = false
				end
			end)
			tw:Play()
		end
		showVerbs(nil)
	end

	----------------------------------------------------------------------------------------------
	-- The screen

	local function pill(text: string, width: number, colour: Color3, parent: Instance): TextButton
		local b = Instance.new("TextButton")
		b.AutoButtonColor = false
		b.Size = UDim2.fromOffset(width, 48)
		b.BackgroundColor3 = colour
		b.FontFace = HEAVY
		b.TextSize = 20
		b.TextColor3 = INK
		b.Text = text
		corner(b, UDim.new(0.5, 0))
		local stroke = Instance.new("UIStroke")
		stroke.Color = RIM
		stroke.Transparency = 0.4
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = b
		Instance.new("UIScale").Parent = b
		b.Parent = parent
		return b
	end

	local function makeGui(): ScreenGui
		local g = Instance.new("ScreenGui")
		g.Name = "Arrange"
		g.ResetOnSpawn = false
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		g.DisplayOrder = 5

		-- The Arrange button: four squares, one lifted and outlined (a find picked up), its word under.
		-- Top right, where Done stands while arranging (the torch's switch is under it, S5-03e3a2).
		local group = Instance.new("CanvasGroup")
		group.BackgroundTransparency = 1
		group.AnchorPoint = Vector2.new(1, 0)
		group.Position = UDim2.new(1, -14, 0, 4)
		group.Size = UDim2.fromOffset(74, 92)
		group.GroupTransparency = 1
		group.Visible = false
		group.Parent = g
		local scale = Instance.new("UIScale")
		scale.Scale = 0.7
		scale.Parent = group
		arrangeGroup, arrangeScale = group, scale
		local b = Instance.new("TextButton")
		b.AutoButtonColor = false
		b.Text = ""
		b.Size = UDim2.fromOffset(66, 66)
		b.AnchorPoint = Vector2.new(0.5, 0)
		b.Position = UDim2.fromScale(0.5, 0)
		b.BackgroundColor3 = PANEL
		b.BackgroundTransparency = 0.1
		corner(b, UDim.new(0.5, 0))
		local stroke = Instance.new("UIStroke")
		stroke.Color = RIM
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = b
		Instance.new("UIScale").Parent = b
		for i, at in { { -9, 9 }, { 9, 9 }, { -9, -9 }, { 10, -11 } } do
			local sq = Instance.new("Frame")
			sq.AnchorPoint = Vector2.new(0.5, 0.5)
			sq.Position = UDim2.new(0.5, at[1], 0.5, at[2])
			sq.Size = UDim2.fromOffset(14, 14)
			sq.BackgroundColor3 = if i == 4 then INK else RIM
			sq.BorderSizePixel = 0
			corner(sq, UDim.new(0, 3))
			if i == 4 then
				local o = Instance.new("UIStroke")
				o.Color = Color3.new(1, 1, 1)
				o.Thickness = 2
				o.Parent = sq
			end
			sq.Parent = b
		end
		b.Parent = group
		local word = Instance.new("TextLabel")
		word.BackgroundTransparency = 1
		word.AnchorPoint = Vector2.new(0.5, 1)
		word.Position = UDim2.fromScale(0.5, 1)
		word.Size = UDim2.new(1, 0, 0, 22)
		word.FontFace = HEAVY
		word.TextSize = 16
		word.TextColor3 = INK
		word.TextStrokeTransparency = 0.6
		word.Text = "Arrange"
		word.Parent = group
		b.Activated:Connect(function()
			if shown then
				press(b)
				openNow()
			end
		end)

		-- Done, top right, while arranging.
		local done = pill("Done", 104, PANEL, g)
		done.AnchorPoint = Vector2.new(1, 0)
		done.Position = UDim2.new(1, -14, 0, 14)
		done.Visible = false
		done.Activated:Connect(function()
			press(done)
			closeNow()
		end)
		doneButton = done

		-- The limit bar, top middle while arranging: four squares (the Arrange button's), a track
		-- that fills honey as you set finds out, and the count. Bloxburg's build budget bar.
		local m = Instance.new("Frame")
		m.AnchorPoint = Vector2.new(0.5, 0)
		m.Position = UDim2.new(0.5, 0, 0, -60)
		m.Size = UDim2.fromOffset(176, 36)
		m.BackgroundColor3 = PANEL
		m.BackgroundTransparency = 0.1
		m.Visible = false
		corner(m, UDim.new(0.5, 0))
		local mStroke = Instance.new("UIStroke")
		mStroke.Color = RIM
		mStroke.Transparency = 0.4
		mStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		mStroke.Parent = m
		Instance.new("UIScale").Parent = m
		m.Parent = g
		meter = m
		for i, at in { { -4, 4 }, { 4, 4 }, { -4, -4 }, { 4, -4 } } do
			local sq = Instance.new("Frame")
			sq.AnchorPoint = Vector2.new(0.5, 0.5)
			sq.Position = UDim2.new(0, 24 + at[1], 0.5, at[2])
			sq.Size = UDim2.fromOffset(7, 7)
			sq.BackgroundColor3 = if i == 4 then HONEY else RIM
			sq.BorderSizePixel = 0
			corner(sq, UDim.new(0, 2))
			sq.Parent = m
		end
		local track = Instance.new("Frame")
		track.AnchorPoint = Vector2.new(0, 0.5)
		track.Position = UDim2.new(0, 40, 0.5, 0)
		track.Size = UDim2.fromOffset(78, 10)
		track.BackgroundColor3 = CARD
		track.BorderSizePixel = 0
		track.ClipsDescendants = true
		corner(track, UDim.new(0.5, 0))
		track.Parent = m
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(0, 1)
		fill.BackgroundColor3 = HONEY
		fill.BorderSizePixel = 0
		corner(fill, UDim.new(0.5, 0))
		fill.Parent = track
		meterFill = fill
		local count = Instance.new("TextLabel")
		count.BackgroundTransparency = 1
		count.AnchorPoint = Vector2.new(1, 0.5)
		count.Position = UDim2.new(1, -12, 0.5, 0)
		count.Size = UDim2.fromOffset(46, 22)
		count.TextXAlignment = Enum.TextXAlignment.Right
		count.FontFace = HEAVY
		count.TextSize = 16
		count.TextColor3 = INK
		count.Text = `{setOut}/{most}`
		Instance.new("UIScale").Parent = count
		count.Parent = m
		meterCount = count

		-- The tray along the bottom: the box's finds.
		local t = Instance.new("Frame")
		t.AnchorPoint = Vector2.new(0.5, 1)
		t.Position = UDim2.new(0.5, 0, 1, AWAY)
		t.Size = UDim2.new(1, -28, 0, TRAY)
		t.BackgroundColor3 = PANEL
		t.BackgroundTransparency = 0.08
		t.Visible = false
		corner(t, UDim.new(0, 16))
		local tStroke = Instance.new("UIStroke")
		tStroke.Color = RIM
		tStroke.Transparency = 0.5
		tStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		tStroke.Parent = t
		t.Parent = g
		tray = t
		local s = Instance.new("ScrollingFrame")
		s.BackgroundTransparency = 1
		s.BorderSizePixel = 0
		s.Position = UDim2.fromOffset(10, 10)
		s.Size = UDim2.new(1, -20, 1, -20)
		s.ScrollingDirection = Enum.ScrollingDirection.X
		s.AutomaticCanvasSize = Enum.AutomaticSize.X
		s.CanvasSize = UDim2.new()
		s.ScrollBarThickness = 0
		s.Parent = t
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 10)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = s
		list = s
		listAt = s.Position

		-- The paint tab's papers, paints, floors and floor colours, and the front tab's door
		-- colours (LooksTab's two pages), in the same tray.
		local host: LooksTab.Host = {
			press = press,
			pick = function(kind: Looks.Kind, id: string)
				local r = remote(Looks.Remote)
				if r then
					r:FireServer(kind, id)
				end
			end,
			rim = RIM,
		}
		local lt = LooksTab.new(t, host, "room")
		roomTab = lt
		frontTab = LooksTab.new(t, host, "front")
		looksAt = lt.root.Position

		-- The tray's tabs on its top edge, at the left: the finds (the Arrange button's four
		-- squares), the looks (a fan of paint chips) and your front (a little roll-up door). They
		-- ride with the tray. Bloxburg's build mode tabs.
		for i = FINDS, FRONT do
			local tab = Instance.new("TextButton")
			tab.Name = if i == FINDS then "FindsTab" elseif i == ROOM then "LooksTab" else "FrontTab"
			tab.Text = ""
			tab.AutoButtonColor = false
			tab.AnchorPoint = Vector2.new(0, 1)
			tab.Position = UDim2.fromOffset((i - 1) * 62, -6)
			tab.Size = UDim2.fromOffset(56, 44)
			tab.BackgroundColor3 = PANEL
			tab.BackgroundTransparency = 0.08
			corner(tab, UDim.new(0, 14))
			local edge = Instance.new("UIStroke")
			edge.Color = RIM
			edge.Transparency = 0.5
			edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			edge.Parent = tab
			Instance.new("UIScale").Parent = tab
			local icon = Instance.new("CanvasGroup")
			icon.Name = "Icon"
			icon.BackgroundTransparency = 1
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.Size = UDim2.fromOffset(36, 32)
			icon.Parent = tab
			if i == FINDS then
				for j, at in { { -6, 6 }, { 6, 6 }, { -6, -6 }, { 7, -8 } } do
					local sq = Instance.new("Frame")
					sq.AnchorPoint = Vector2.new(0.5, 0.5)
					sq.Position = UDim2.new(0.5, at[1], 0.5, at[2])
					sq.Size = UDim2.fromOffset(10, 10)
					sq.BackgroundColor3 = if j == 4 then INK else RIM
					sq.BorderSizePixel = 0
					corner(sq, UDim.new(0, 2))
					sq.Parent = icon
				end
			elseif i == ROOM then
				LooksTab.icon(icon, PANEL)
			else
				LooksTab.frontIcon(icon, PANEL)
			end
			tab.Activated:Connect(function()
				press(tab)
				if not lifted then
					showTab(i, true)
				end
			end)
			tab.Parent = t
			tabs[i] = tab
		end
		showTab(onTab, false)

		-- What you do with the lifted find: a corner cluster under the right thumb (the tray slides
		-- away while a find is lifted, so the whole room shows). Place where the jump button sits,
		-- Turn above it, Put away beside Place, × beside Turn.
		local v = Instance.new("Frame")
		v.BackgroundTransparency = 1
		v.AnchorPoint = Vector2.new(1, 1)
		v.Position = UDim2.new(1, -14, 1, -14)
		v.Size = UDim2.fromOffset(238, 106)
		v.Visible = false
		v.Parent = g
		Instance.new("UIScale").Parent = v
		verbs = v
		local function at(button: TextButton, right: number, up: number)
			button.AnchorPoint = Vector2.new(1, 1)
			button.Position = UDim2.new(1, -right, 1, -up)
		end
		local cancel = pill("×", 48, PANEL, v)
		cancel.TextSize = 30
		at(cancel, 122, 58)
		cancel.Activated:Connect(function()
			local l = lifted
			if l and not l.asking then
				press(cancel)
				slideBack(l)
			end
		end)
		local away = pill("Put away", 116, PANEL, v)
		at(away, 122, 0)
		away.Activated:Connect(function()
			press(away)
			awayNow()
		end)
		awayButton = away
		local turn = pill("Turn", 112, PANEL, v)
		at(turn, 0, 58)
		turn.Activated:Connect(function()
			press(turn)
			turnNow()
		end)
		turnButton = turn
		local placeB = pill("Place", 112, FITS, v)
		at(placeB, 0, 0)
		placeB.TextColor3 = PANEL
		placeB.Activated:Connect(function()
			local l = lifted
			if l and l.fits and not l.asking then
				press(placeB)
				placeNow()
			end
		end)
		placeButton = placeB
		return g
	end

	----------------------------------------------------------------------------------------------
	-- Fingers

	-- The find of yours under screen point `at`, if any.
	local function pickAt(at: Vector2): Model?
		local camera = Workspace.CurrentCamera
		local folder = placed()
		if not (camera and folder) then
			return nil
		end
		local ray = camera:ScreenPointToRay(at.X, at.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { folder }
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 200, params)
		local inst: Instance? = if hit then hit.Instance else nil
		while inst and inst.Parent ~= folder do
			inst = inst.Parent
		end
		if inst and inst:IsA("Model") and inst:GetAttribute(Spots.OwnerAttribute) == me.UserId then
			return inst
		end
		return nil
	end

	local function pointer(t: Enum.UserInputType): boolean
		return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1
	end

	local function began(input: InputObject, processed: boolean)
		if not open or processed or not pointer(input.UserInputType) then
			return
		end
		local at = Vector2.new(input.Position.X, input.Position.Y)
		local l = lifted
		if (l and l.asking) or (not l and onTab == FRONT) then
			return -- facing the door, the room's finds aren't to hand: they lift from the others
		end
		local model = pickAt(at)
		if model and (not l or model ~= l.original) then
			if l then
				slideBack(l)
			end
			liftDrawn(model)
		elseif not l then
			return -- a tap on the empty room
		end
		dragInput = input
	end

	local function changed(input: InputObject)
		local p = pending
		if p then
			local dragged = input == p.input
				or (
					input.UserInputType == Enum.UserInputType.MouseMovement
					and p.input.UserInputType == Enum.UserInputType.MouseButton1
				)
			if dragged then
				local at = Vector2.new(input.Position.X, input.Position.Y)
				local d = at - p.start
				if -d.Y > SLOP and -d.Y > math.abs(d.X) then
					pending = nil -- up out of the tray: lift it
					liftBoxed(p.key, at)
					dragInput = p.input
				elseif math.abs(d.X) > SLOP then
					pending = nil -- sideways: the tray scrolls
				end
			end
			return
		end
		local drag = dragInput
		if not drag then
			return
		end
		if
			input == drag
			or (
				input.UserInputType == Enum.UserInputType.MouseMovement
				and drag.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			aimAt(Vector2.new(input.Position.X, input.Position.Y))
		end
	end

	local function ended(input: InputObject)
		local p = pending
		if p and input == p.input then
			pending = nil -- a tap on a card: lift it into the room's middle
			local camera = Workspace.CurrentCamera
			if camera then
				liftBoxed(p.key, camera.ViewportSize / 2)
			end
		end
		if dragInput == input then
			dragInput = nil
		end
	end

	----------------------------------------------------------------------------------------------
	-- Your home

	local function findHome()
		local mine: Model? = nil
		for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
			if inst:IsA("Model") and inst:GetAttribute(Door.HolderAttribute) == me.UserId then
				mine = inst
				break
			end
		end
		if mine == home then
			return
		end
		closeNow()
		home = mine
		inside = nil
		local n = if mine then mine:GetAttribute(Arrange.SlotAttribute) else nil
		local slot = if type(n) == "number" then Arrange.slot(n) else nil
		if slot then
			local face = Arranged.face(Lobby.Origin, slot.Door, slot.Out)
			local c, s = Arranged.inside(Lobby.Origin, face, slot.Inside.Centre, slot.Inside.Size)
			inside = {
				face = face,
				centre = Vector3.new(c[1], c[2], c[3]),
				size = Vector3.new(s[1], s[2], s[3]),
			}
		end
	end

	local function watchUnit(inst: Instance)
		if inst:IsA("Model") and not unitWatch[inst] then
			unitWatch[inst] = inst:GetAttributeChangedSignal(Door.HolderAttribute):Connect(findHome)
		end
		findHome()
	end

	-- Whether you stand inside your own home now.
	local function standingIn(): boolean
		local box = inside
		local character = me.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not (box and root and root:IsA("BasePart")) then
			return false
		end
		local p = box.face:PointToObjectSpace(root.Position) - box.centre
		local h = box.size / 2
		return math.abs(p.X) <= h.X and math.abs(p.Z) <= h.Z and math.abs(p.Y) <= h.Y + 2
	end

	-- The job box's Set out (S5-03g4c2): Arrange rises on the finds' tab with the piece lifted out
	-- of the box, gliding down to the floor's middle. Nothing outside your home, for a piece that
	-- isn't a floor piece, or while something's already lifted.
	local function hold(piece: string, from: CFrame?)
		local p = Furniture.byId(piece)
		if not (running and p) or lifted or not (open or standingIn()) then
			return
		end
		if onTab ~= FINDS then
			showTab(FINDS, false)
		end
		openNow()
		if open then
			liftBoxed(Furniture.placed(piece), nil, from)
		end
	end

	local system: Brix.System = {
		name = "ArrangeView",
		start = function(_: any)
			running = true
			local g = makeGui()
			gui = g
			g.Parent = me:WaitForChild("PlayerGui")
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(watchUnit)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(UnitKit.Tag)
					:Connect(function(inst: Instance)
						local w = unitWatch[inst]
						if w then
							w:Disconnect()
							unitWatch[inst] = nil
						end
						findHome()
					end)
			)
			for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
				watchUnit(inst)
			end
			table.insert(connections, UserInputService.InputBegan:Connect(began))
			table.insert(connections, UserInputService.InputChanged:Connect(changed))
			table.insert(connections, UserInputService.InputEnded:Connect(ended))
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Spots.RemoteFolder, 60)
				local answer = folder and folder:WaitForChild(Spots.AnswerRemote, 60)
				local box = folder and folder:WaitForChild(Arrange.BoxRemote, 60)
				if not running then
					return
				end
				if answer and answer:IsA("RemoteEvent") then
					-- any: a remote's arguments, checked in `answered`
					table.insert(
						connections,
						answer.OnClientEvent:Connect(function(what: any, id: any, refusal: any)
							answered(what, id, refusal)
						end)
					)
				end
				if box and box:IsA("RemoteEvent") then
					table.insert(connections, box.OnClientEvent:Connect(onBox))
				end
			end)
			-- whether you stand in your home, four times a second (the button's only step)
			task.spawn(function()
				while running do
					if not open then
						showButton(standingIn())
					end
					task.wait(0.25)
				end
			end)
		end,
		stop = function(_: any)
			running = false
			closeNow()
			stopFollow()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, w in unitWatch do
				w:Disconnect()
			end
			table.clear(unitWatch)
			if gui then
				gui:Destroy()
				gui = nil
			end
		end,
	}
	return system, hold
end

return ArrangeView
