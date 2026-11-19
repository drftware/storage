--!strict
--[[
	ArrangeHand (S5-03j2a, D-448): the hand in Arrange, the room editor (D-436). Everything that
	lifts a find, a piece of furniture or one of the home's own pieces, carries it over the room and
	sets it down: the ghost that follows the finger, the judge's green or red as it moves, the knock
	and puff as it lands, the slide back when the server says no, and the server's answer itself.

	It was ArrangeView's middle; it lives on its own so the room editor's next pieces (selecting,
	turning, snapping, undo) build on one small hand instead of a 2,000-line screen. ArrangeView
	owns one, gives it the room's judge and its gui's few answers (`Options`), and calls it from its
	buttons and the tray; the build camera's one Gestures reader hands it the room's fingers.

	Only the lifted find steps (its follow, while it's lifted); everything else is tweens.
]]
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local ArrangeBlockers = require(script.Parent.ArrangeBlockers)
local ArrangeGuides = require(script.Parent.ArrangeGuides)
local PlaceAim = require(script.Parent.PlaceAim)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Arranged = require(ReplicatedStorage.Shared.Home.Arranged)
local Feedback = require(ReplicatedStorage.Shared.Home.Feedback)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local Home = require(ReplicatedStorage.Shared.Home)
local History = require(ReplicatedStorage.Shared.Home.History)
local HomeSpecs = require(ReplicatedStorage.Shared.Home.Specs)
local Layout = require(ReplicatedStorage.Shared.Home.Layout)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Settle = require(ReplicatedStorage.Shared.Home.Settle)
local Snapping = require(ReplicatedStorage.Shared.Home.Snapping)
local Turning = require(ReplicatedStorage.Shared.Home.Turning)
local WallHang = require(ReplicatedStorage.Shared.Home.WallHang)

local Feel = Arrange.Feel

local FITS = Feel.Fits -- soft green: it can stand there
local REFUSED = Feel.Refused -- red: it can't
local QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LAND = TweenInfo.new(Feel.Land, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BACK = TweenInfo.new(Feel.Back, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Free's soft tick every 15 degrees of a twist: the step's tick, fainter and higher, so a turn
-- by eye still feels its way round without the grid's ratchet (S5-03j2b2b).
local SOFT: Arrange.Sound = table.clone(Arrange.Tick)
SOFT.pitch = (Arrange.Tick.pitch or 1) * 1.2
SOFT.volume = (Arrange.Tick.volume or 0.12) * 0.75
-- A rider coming back down on its piece as the piece lands (S5-03j2b2c): the find's knock, small,
-- high and quiet, a cup on a table.
local CLINK: Arrange.Sound = table.clone(Arrange.Knock)
CLINK.pitch = (Arrange.Knock.pitch or 1) * 1.45
CLINK.volume = (Arrange.Knock.volume or 0.5) * 0.45
-- A carried thing hopping up onto a top, or down off one, as it's dragged (S5-03j3b; the plan's
-- "onto a table" row): the knock, higher, shorter and quieter still, a cup's foot tocking on wood.
-- It takes the step's tick's place for that move, so a hop is one clear sound, not two.
local TOCK: Arrange.Sound = table.clone(Arrange.Knock)
TOCK.pitch = (Arrange.Knock.pitch or 1) * 1.25
TOCK.volume = (Arrange.Knock.volume or 0.5) * 0.35
TOCK.length = 0.18
-- A dragged thing first pressing into something (S5-03j4b2; the plan's "blocked" row, once per
-- red spell, no phone tap): the knock, low and soft, a dull bump against the thing that now glows.
-- It takes the step's tick's place for that move, as the tock does.
local BUMP: Arrange.Sound = table.clone(Arrange.Knock)
BUMP.pitch = (Arrange.Knock.pitch or 1) * 0.7
BUMP.volume = (Arrange.Knock.volume or 0.5) * 0.5
BUMP.length = 0.3

-- A find lifted off the floor or out of the tray, as a ghost the finger drags.
export type Lifted = {
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
	copies: { Model }, -- those copies in the ghost, in the riders' order: they hop as it lands
	still: number, -- the clock when its riders are still again after a landing (0: no landing)
	from: CFrame, -- where the ghost began
	pose: Brix.PlacementPose?, -- where it would stand now, snapped
	turn: number,
	fits: boolean,
	target: CFrame,
	asking: string?, -- "place" or "away" while the server's answer is awaited
	shelf: number?, -- the shelf's spot it was lifted out of (S5-03i2b), sent with Place and Put away
	shrink: number?, -- out of a cubby: the size it stood there, as a share of its own
	-- A run of Turn presses: where it began and where the last one left it. Each turn settles from
	-- where the run began, so a turn that pushed the thing off a wall is undone by turning back
	-- (four quarter turns bring it home, S5-03j2b1b); a move starts a new run.
	turnRun: { from: Brix.PlacementPose, to: Brix.PlacementPose? }?,
	-- Snapping (S5-03j3a2, D-455): whether it turns its back to a wall it's pushed to (furniture
	-- that isn't flat, and not the leaning mirror); the wall it's against now, if any (lifted
	-- off one, it starts against it, so lifting never turns it); and Brix's line-up with its
	-- neighbours, made once per lift and filled again on every move (the guide lines to draw).
	backs: boolean,
	wall: number?,
	lines: Brix.PlacementAlignment,
	-- Where it stood when lifted (nil: out of the box or a cubby), for undo (S5-03j4a).
	before: Brix.PlacementPose?,
	-- An undo or redo carried out by the hand (`replay`): told the server's word once, instead
	-- of the change being recorded as a new step.
	finished: ((ok: boolean, id: string?) -> ())?,
}

-- What the hand needs from the screen that owns it.
export type Options = {
	-- The room's judge, as the server's (ArrangeView builds it as Arrange opens).
	room: () -> Arrange.Room?,
	-- Finds set out whose top takes another, filled with the judge (the same table, shared).
	tops: { [string]: boolean },
	-- The folder your finds are drawn in.
	placed: () -> Instance?,
	-- Where the screen's sounds play (for this player only).
	sounds: () -> Instance,
	-- One of the home's remotes by name.
	remote: (name: string) -> RemoteEvent?,
	-- Whether the room holds all it can (a card won't lift, a cubby find won't come out).
	full: () -> boolean,
	-- The ring of buttons round the thing selected (ArrangeRing), shown for `l`, or put away for
	-- nil; while a finger is `carrying` it, the ring hides but the tray stays out of the way.
	showRing: (l: Lifted?, carrying: boolean?) -> (),
	-- A thing is carried under gui point `x`, `y` this frame: near the screen's edge the build
	-- camera slides that way (`ArrangeCamera.follow`).
	follow: (x: number, y: number) -> (),
	-- Whether gui point `x`, `y` is over the tray's place (the tray is away while a thing is
	-- carried): a thing let go there floats back, a card's into its card.
	overTray: (x: number, y: number) -> boolean,
	-- A phone tap (ArrangeTaps; nothing off a phone).
	tap: (tap: Feedback.Tap) -> (),
	-- Where the tray card for `name` is now (gui points, its middle), or where it would come in,
	-- for a thing put away to fly into; nil when the tray isn't showing.
	cardAt: (name: string) -> Vector2?,
	-- The card for `name` bumps as a thing lands in it.
	bump: (name: string) -> (),
	-- Whether Free is on (Alt held, or the corner switch, ArrangeTurn): the carried thing goes
	-- off the grid, where the finger has it, at any whole degree (S5-03j2b2b).
	free: () -> boolean,
	-- A change the server accepted (S5-03j4a): what was `idBefore` at `before` is now `idAfter` at
	-- `after`; nil, nil is the box. Undo and redo's own asks aren't reported.
	changed: (
		name: string,
		idBefore: string?,
		before: Brix.PlacementPose?,
		idAfter: string?,
		after: Brix.PlacementPose?
	) -> (),
}

-- The hand, as ArrangeView and the build camera call it.
export type Hand = {
	-- The thing lifted now, if any.
	lifted: () -> Lifted?,
	-- What a press at gui point `at` takes (the build camera's Gestures `pick`): the lifted thing,
	-- or your find under it; nil for the room.
	pick: (at: Vector2) -> Model?,
	-- One of the room's intents (gui points): drags on a thing, and taps.
	intent: (i: Brix.GestureIntent<Model>) -> (),
	-- A card dragged up out of the tray at gui point `at`, carried by a touch or a mouse.
	carryBoxed: (key: string, at: Vector2, touch: boolean) -> (),
	-- A finger held on one of your things before Arrange opened (S5-03j5b2): `t` (a find set out,
	-- or one in your shelf's cubby) lifts as a press on it would, and that finger (a touch when
	-- `touch`) at gui point `at` carries it on. False if it didn't lift.
	carryHeld: (t: Model, at: Vector2, touch: boolean) -> boolean,
	-- The card's finger moved, and let go.
	move: (x: number, y: number) -> (),
	release: () -> (),
	-- A tapped card, or the job box's Set out: out of the box and down on the nearest free spot.
	setOut: (key: string, at: Vector2?, from: CFrame?) -> (),
	-- Sends the lifted thing back where it came from.
	slideBack: (l: Lifted) -> (),
	-- The ring's buttons for the selected thing: Turn, Put away, and Another (it's set down and
	-- one more of the same lifts out of your box beside it, selected).
	turnNow: () -> (),
	awayNow: () -> (),
	another: () -> (),
	-- The height handle (S5-03j3c2, D-459), for a selected thing that hangs on a wall: `raiseStart`
	-- as the finger goes down on it (false: nothing to raise), `raiseBy` with the finger's move
	-- since (screen points), `raiseStop` as it lifts. The thing stays selected, as after Turn;
	-- letting it go places it the usual way.
	raiseStart: () -> boolean,
	raiseBy: (dx: number, dy: number) -> (),
	raiseStop: () -> (),
	-- The server's answer to a Place or a Put away.
	answered: (what: unknown, id: unknown, refusal: unknown) -> (),
	-- Stops the lifted thing's follow.
	stopFollow: () -> (),
	-- Free went on or off: a carried thing settles again at once, onto the grid or off it.
	freeChanged: () -> (),
	-- Undo or Redo (S5-03j4a): carries `ask` out as a finger would, lifting the thing and setting
	-- it on `ask.to` (or putting it away), with the usual glide and knock. False when it can't
	-- start (something is lifted, the thing isn't drawn, the room is full); otherwise `finished`
	-- hears the server's word once.
	replay: (ask: History.Ask, finished: (ok: boolean, id: string?) -> ()) -> boolean,
}

local ArrangeHand = {}

-- Plays `spec` once in `parent`.
function ArrangeHand.play(spec: Arrange.Sound, parent: Instance)
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
local play = ArrangeHand.play

-- A puff of dust where a thing lands: as much as its weight's band raises (`Feedback`). Shared
-- with placing by hand (HandPlaceView).
function ArrangeHand.puff(at: CFrame, band: Feedback.Band)
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
		NumberSequenceKeypoint.new(0, 0.3 * band.spread),
		NumberSequenceKeypoint.new(1, 1.1 * band.spread),
	})
	e.Lifetime = NumberRange.new(0.4, 0.7)
	e.Speed = NumberRange.new(2, 3.5)
	e.Drag = 6
	e.SpreadAngle = Vector2.new(90, 90)
	e.EmissionDirection = Enum.NormalId.Top
	e.Rate = 0
	e.Parent = p
	p.Parent = Workspace.CurrentCamera
	e:Emit(band.motes)
	Debris:AddItem(p, 1.2)
end

-- Makes `model` scenery the screen alone sees: never collides, touched, picked or sat on, and
-- shows no buttons.
function ArrangeHand.inert(model: Model)
	for _, d in model:GetDescendants() do
		if
			d:IsA("Seat")
			or d:IsA("ProximityPrompt")
			or d:IsA("Sound")
			or d:IsA("Script")
			or d:IsA("LocalScript")
		then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		elseif d:IsA("Light") then
			d.Enabled = false
		end
	end
end

local inert = ArrangeHand.inert

-- Hides or shows a drawn find on this screen only.
local function hide(model: Model, hidden: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

function ArrangeHand.new(options: Options): Hand
	local me = Players.LocalPlayer
	local tops = options.tops
	local placed, sounds, remote, showRing =
		options.placed, options.sounds, options.remote, options.showRing
	local lifted: Lifted? = nil
	local follow: RBXScriptConnection? = nil
	local lastTick = 0
	-- Where a blocked thing may slide when let go, and where one set out with no finger starts.
	local slideSearch = Brix.PlacementSearch.grid({ step = Arrange.Step, reach = Feel.SlideReach })
	local startSearch = Brix.PlacementSearch.grid({ step = Arrange.Step, reach = Feel.StartReach })
	-- A finger carrying the lifted thing: where it is (gui points), how far above it the thing
	-- hangs, and where the camera stood when the thing last aimed (it slides under a still finger
	-- near the screen's edge, so the thing aims again).
	local carrying = false
	local fingerX, fingerY, thumb = 0, 0, 0
	local aimedFrom = CFrame.identity

	local function tick(sound: Arrange.Sound?)
		local now = os.clock()
		if now - lastTick > 0.04 then
			lastTick = now
			play(sound or Arrange.Tick, sounds())
			options.tap(if sound == TOCK then Feedback.Taps.Tap else Feedback.Taps.Tick)
		end
	end

	-- The button's pop when pressed.

	-- The shared aim and judge (PlaceAim), with this hand's camera, tops and Free.
	local fitsAt = PlaceAim.fitsAt
	local standAt = PlaceAim.standAt
	local function aim(r: Arrange.Room, l: Lifted, at: Vector2): (string?, number, number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return nil, 0, 0
		end
		return PlaceAim.aim(r, l, camera:ScreenPointToRay(at.X, at.Y), tops)
	end
	local function settle(
		r: Arrange.Room,
		l: Lifted,
		on: string,
		x: number,
		y: number
	): Brix.PlacementPose?
		return PlaceAim.settle(r, l, on, x, y, options.free())
	end

	----------------------------------------------------------------------------------------------
	-- The lifted find

	-- The soft shadow under the lifted thing, where it would land: one part made at the first lift
	-- and kept, moved only as the thing's spot changes; rounded layers darken toward its middle.
	local shadow: Part? = nil
	-- The faint lines where it lines up with a neighbour (ArrangeGuides), laid on each move.
	local guides = ArrangeGuides.new()
	-- What's in the way of a red ghost, lit (ArrangeBlockers), and the list Brix fills on each
	-- move to say what that is (kept for the hand's life, so a drag allocates nothing for it).
	local blockers = ArrangeBlockers.new()
	local inTheWay: { string } = table.create(Feel.BlockerMost)
	local function shadowPart(): Part
		local made = shadow
		if made then
			return made
		end
		local part = Instance.new("Part")
		part.Name = "ArrangeShadow"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Top
		g.LightInfluence = 0
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 24
		g.Parent = part
		local layers = #Feel.ShadowLayers
		for _, share in Feel.ShadowLayers do
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.Size = UDim2.fromScale(share, share)
			f.BackgroundColor3 = Color3.new(0, 0, 0)
			-- each layer a share of the darkness, so they stack to `ShadowDark` in the middle
			f.BackgroundTransparency = (1 - Feel.ShadowDark) ^ (1 / layers)
			f.BorderSizePixel = 0
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0.5, 0)
			c.Parent = f
			f.Parent = g
		end
		shadow = part
		return part
	end

	-- Lays the shadow where `l` would stand at `pose`, a hair off the surface.
	local function shade(r: Arrange.Room, l: Lifted, pose: Brix.PlacementPose)
		local a = Arrange.frameOn(r, pose.on)
		if not a then
			return
		end
		local part = shadowPart()
		local t = Arranged.pose(a, pose.x, pose.y, pose.turn)
		part.Size = Vector3.new(l.shape.width, 0.05, l.shape.depth) * Feel.ShadowSize
		part.CFrame = t + t.YVector * 0.05
		part.Parent = Workspace.CurrentCamera
	end

	local function paint(l: Lifted)
		local h = l.highlight
		h.OutlineColor = if l.fits then Color3.new(1, 1, 1) else REFUSED
		h.FillColor = if l.fits then FITS else REFUSED
		h.FillTransparency = if l.fits then Feel.FitsWash else Feel.RefusedWash
	end

	-- Whether moving from area `from` to area `to` is a hop up or down: both face up and stand at
	-- different heights (the floor to a table's top, a top to a shelf's tier). Read from the areas'
	-- frames, so any piece with a top, a room's own or a find's, hops the same way; a wall or the
	-- ceiling never does.
	local function hops(r: Arrange.Room, from: string, to: string): boolean
		local a, b = Arrange.frameOn(r, from), Arrange.frameOn(r, to)
		return a ~= nil
			and b ~= nil
			and a.YVector.Y > 0.9
			and b.YVector.Y > 0.9
			and math.abs(a.Position.Y - b.Position.Y) > Feel.Hop
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
		l.target = at + normal * (if carrying then Feel.Hover else Feel.Hair)
		paint(l)
		shade(r, l, pose)
		-- red for pressing into something: light what it is (Brix's `blocking`, D-462)
		if not l.fits and r.placements:check(l.id, l.shape, pose) == "overlaps" then
			r.placements:blocking(l.id, l.shape, pose, inTheWay)
		else
			table.clear(inTheWay)
		end
		local bumped = blockers:show(inTheWay, placed())
		local a = if carrying and l.lines.count > 0 then Arrange.frameOn(r, pose.on) else nil
		if a then
			guides:show(a, l.lines)
		else
			guides:hide()
		end
		if bumped then
			play(BUMP, sounds())
			lastTick = os.clock() -- the bump is this move's one sound
		elseif moved and was then
			tick(if was.on ~= pose.on and hops(r, was.on, pose.on) then TOCK else nil)
		end
	end

	local function aimAt(at: Vector2)
		local r, l = options.room(), lifted
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
		local part = shadow
		if part then
			part.Parent = nil
		end
		guides:hide()
		blockers:clear()
		if follow then
			follow:Disconnect()
			follow = nil
		end
	end

	-- Turn's little overshoot: since when it spins (-1: not), and about which axis, the way the
	-- quarter turn went.
	local spinAt, spinAxis = -1, Vector3.yAxis

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
			if carrying then
				-- near the screen's edge the camera slides, the thing aiming again under the finger
				options.follow(fingerX, fingerY)
				local camera = Workspace.CurrentCamera
				if camera and camera.CFrame ~= aimedFrom then
					aimedFrom = camera.CFrame
					aimAt(Vector2.new(fingerX, fingerY - thumb))
				end
			end
			local goal = l.target
			if spinAt >= 0 then
				-- past the quarter and back: a bump that peaks a third of the way in, at
				-- `Overshoot` degrees (sin(pi k)(1 - k) peaks near 0.47)
				local k = (os.clock() - spinAt) / Feel.Spin
				if k >= 1 then
					spinAt = -1
				else
					local a = math.rad(Feel.Overshoot) * math.sin(math.pi * k) * (1 - k) / 0.47
					goal = CFrame.new(goal.Position)
						* CFrame.fromAxisAngle(spinAxis, a)
						* goal.Rotation
				end
			end
			l.ghost:PivotTo(l.ghost:GetPivot():Lerp(goal, 1 - 0.5 ^ (dt / Feel.Follow)))
		end)
	end

	-- Lets the ghost go: gone, the drawn find shown again (unless it was put away).
	-- Tells an undo or redo carried out on `l` the server's word, once.
	local function finish(l: Lifted, ok: boolean, id: string?)
		local f = l.finished
		if f then
			l.finished = nil
			f(ok, id)
		end
	end

	local function letGo(l: Lifted, showOriginal: boolean)
		finish(l, false, nil) -- (kept, it was told already)
		if lifted == l then
			blockers:clear()
			lifted = nil
			stopFollow()
			showRing(nil)
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
		local r = options.room()
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
		local piece = Furniture.ofPlaced(name)
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
			copies = {},
			still = 0,
			from = from,
			pose = nil,
			turn = 0,
			fits = false,
			target = from,
			asking = nil,
			shelf = nil,
			shrink = nil,
			backs = piece ~= nil and not Snapping.Flat[piece.id] and not Layout.Lean[piece.id],
			wall = nil,
			lines = PlaceAim.lines(),
			before = nil,
			finished = nil,
		}
		lifted = l
		carrying = false
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
				table.insert(l.copies, copy)
			end
			local pose = r.placements:poseOf(id)
			if pose then
				l.before = { on = pose.on, x = pose.x, y = pose.y, turn = pose.turn }
				l.turn = pose.turn
				-- lifted off a wall, it starts against it: the first move keeps the turn it has
				local floor = r.placements:areaOf("Floor")
				if l.backs and floor and pose.on == "Floor" then
					local rx, ry = Turning.reach(shape.width, shape.depth, pose.turn)
					l.wall = Snapping.wall(floor, pose.x, pose.y, rx, ry, pose.turn, nil)
				end
				setPose(r, l, { on = pose.on, x = pose.x, y = pose.y, turn = pose.turn })
			end
		end
		play(Arrange.Lift, sounds())
		options.tap(Feedback.Taps.Light)
		showRing(l)
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

	-- The free spot nearest `pose` (on its area, at its turn) within `search`'s reach where `l`
	-- may stand: Brix's judge finds it (`nearestFree`, ENG-26c), settled and judged again here for
	-- what only this game knows (the mirror against its wall, the job box's lid). Nil if none.
	local function freeNear(
		r: Arrange.Room,
		l: Lifted,
		pose: Brix.PlacementPose,
		search: Brix.PlacementSearch
	): Brix.PlacementPose?
		local free = r.placements:nearestFree(l.id, l.shape, pose, search)
		local settled = if free then settle(r, l, free.on, free.x, free.y) else nil
		return if settled and fitsAt(r, l, settled) then settled else nil
	end

	-- Where `l` starts with no finger on it: the free spot nearest the middle of the first of its
	-- starting areas with room (`Spots.starts`: the floor; the ceiling; the back wall, then the
	-- sides); the first area's middle when none has (it shows red).
	local function startSpot(r: Arrange.Room, l: Lifted): Brix.PlacementPose?
		local starts = Spots.starts(l.spot)
		for _, on in starts do
			local middle = settle(r, l, on, 0, 0)
			local free = if middle and fitsAt(r, l, middle)
				then middle
				elseif middle then freeNear(r, l, middle, startSearch)
				else nil
			if free then
				return free
			end
		end
		return settle(r, l, starts[1], 0, 0)
	end

	-- Eases `ghost` from `from` times its size to `to` (a cubby find growing as it lifts out, or
	-- shrinking back in), about its pivot.
	local function grow(ghost: Model, from: number, to: number)
		local scale = Instance.new("NumberValue")
		scale.Value = from
		scale.Changed:Connect(function(v: number)
			if ghost.Parent and v > 0.01 then
				ghost:ScaleTo(v)
			end
		end)
		local t = TweenService:Create(scale, QUICK, { Value = to })
		t.Completed:Once(function()
			scale:Destroy()
		end)
		t:Play()
	end

	-- Lifts a find, or a piece of furniture by its placed name, out of the box: under screen point
	-- `at`, or from `from` (the job box, for the panel's Set out) down onto the floor's middle; or
	-- out of the shelf's cubby `shelved` stands in (S5-03i2b, D-352), growing from its cubby's size
	-- as it rises toward your finger.
	local function liftBoxed(key: string, at: Vector2?, from: CFrame?, shelved: Model?)
		if options.full() then
			return -- the room holds all it can: the card dims and won't lift
		end
		local r = options.room()
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
		if shelved then -- it rises out of its cubby, where it stood
			ghost:PivotTo(shelved:GetPivot())
		elseif from then -- it rises out of the job box
			ghost:PivotTo(from + Vector3.yAxis * 1.5)
		elseif camera and at then -- it rises out of the tray toward the room
			local ray = camera:ScreenPointToRay(at.X, at.Y)
			ghost:PivotTo(CFrame.new(ray.Origin + ray.Direction * 6))
		end
		local whole = ghost:GetScale()
		lift(key, id, key, ghost, shelved) -- measured whole, before it's shrunk to its cubby
		local l = lifted
		if l and shelved and l.ghost == ghost then
			l.shelf = Shelf.spot(shelved:GetAttribute(Shelf.SpotAttribute), #HomeSpecs.Shelf.Spots)
			local share = math.clamp(shelved:GetScale() / whole, 0.05, 1)
			l.shrink = share
			ghost:ScaleTo(whole * share)
			grow(ghost, whole * share, whole)
		end
		if at then
			aimAt(at)
		end
		if l and not l.pose then -- over nothing it fits: start it on the floor's middle
			-- out of the job box (or a cubby) with no thumb on it: the free spot nearest the
			-- middle, so it arrives green (S5-03g4c2)
			local pose = if from or shelved
				then startSpot(r, l)
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
			local shrink = l.shrink
			if shrink then -- back into its cubby, at the size it stood there
				local whole = l.ghost:GetScale()
				grow(l.ghost, whole, whole * shrink)
			end
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
		showRing(nil)
		lifted = nil
	end

	local puff = ArrangeHand.puff

	-- The riders settle as their piece lands (S5-03j2b2c, D-338): each copy in the ghost jolts up
	-- off the piece and drops back with a clink, a beat after the one before, bounces once lower,
	-- then stands still (`Settle`). Only the copies are stepped, only until they're still; the
	-- ghost waits for them (`l.still`) before it gives way to what the server drew.
	local function bounce(l: Lifted)
		local copies = l.copies
		local count = #copies
		if count == 0 then
			return
		end
		local start, length = os.clock(), Settle.length(count)
		l.still = start + length
		local rest: { CFrame } = table.create(count)
		for i, c in copies do
			rest[i] = c:GetPivot()
		end
		local clinked = 0
		local step: RBXScriptConnection
		step = RunService.RenderStepped:Connect(function()
			local t = os.clock() - start
			if not l.ghost.Parent then
				step:Disconnect()
				return
			end
			local done = t >= length
			for i, c in copies do
				-- (up against gravity, whatever the piece's top faces)
				c:PivotTo(if done then rest[i] else rest[i] + Vector3.yAxis * Settle.height(t, i))
			end
			while clinked < count and t >= Settle.landsAt(clinked + 1) do
				clinked += 1
				play(CLINK, sounds())
			end
			if done then
				step:Disconnect()
			end
		end)
	end

	-- Place: the ghost drops onto its spot with a knock and a puff; the server's answer keeps it.
	local function placeNow()
		local r, l = options.room(), lifted
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
		showRing(nil)
		ask:FireServer(l.what, pose.on, pose.x, pose.y, pose.turn, l.shelf) -- nil but out of a cubby
		task.delay(3, function()
			if lifted == l and l.asking == "place" then
				slideBack(l) -- no answer: as if refused
			end
		end)
		-- (the ghost stays till its riders are still: an upper bound, `bounce` sets it exactly)
		l.still = os.clock() + Feel.Land + Settle.length(#l.copies)
		local cf = Instance.new("CFrameValue")
		cf.Value = l.ghost:GetPivot()
		cf.Changed:Connect(function(v: CFrame)
			l.ghost:PivotTo(v)
		end)
		local t = TweenService:Create(cf, LAND, { Value = at })
		t.Completed:Once(function()
			cf:Destroy()
			if l.ghost.Parent then
				local band = Feedback.landing(l.name) -- how heavy it is, from its row
				play(band.thud, sounds())
				options.tap(band.tap)
				local stand = Arrange.frameOn(r, pose.on)
				puff(if stand then Arranged.pose(stand, pose.x, pose.y, pose.turn) else at, band)
				bounce(l)
				TweenService
					:Create(l.highlight, QUICK, { OutlineTransparency = 1, FillTransparency = 1 })
					:Play()
			end
		end)
		t:Play()
	end

	-- A ratchet's click-click, as its pawl jumps a tooth: each quarter a turn clicks into.
	local function ratchet()
		play(Arrange.Ratchet, sounds())
		options.tap(Feedback.Taps.Tick)
		task.delay(0.07, play, Arrange.Ratchet, sounds())
	end

	-- The little spin past a quarter and back, the way `l` just turned from `was` (its target).
	local function spinFrom(l: Lifted, was: CFrame)
		local axis, angle = (l.target.Rotation * was.Rotation:Inverse()):ToAxisAngle()
		if angle > 0.01 then
			spinAt, spinAxis = os.clock(), axis.Unit
		end
	end

	-- A twist going on (two fingers, or the wheel on a carried thing): the turn it began at, and
	-- all it has twisted since, as the face sees it (radians). Nil between twists.
	local twistFrom: number? = nil
	local twistSum = 0

	-- Two fingers twisting the carried thing, or a wheel notch (a quarter): it turns from where it
	-- stood when the twist began, as Turning has it. On the grid it clicks round in quarters, a
	-- ratchet and a little spin past at each; with Free it follows the fingers to the degree,
	-- ticking softly every 15 (S5-03j2b2b).
	local function twist(angle: number)
		local r, l, camera = options.room(), lifted, Workspace.CurrentCamera
		local pose = if l then l.pose else nil
		if not (r and l and pose and camera and carrying) or l.asking then
			return
		end
		local face = Arrange.frameOn(r, pose.on)
		local facing = if face then camera.CFrame.LookVector:Dot(face.YVector) else -1
		local from = twistFrom or pose.turn
		if not twistFrom then
			twistFrom, twistSum = from, 0
		end
		twistSum += Turning.seen(angle, facing)
		local free = options.free()
		local turn = Turning.twisted(from, twistSum, free)
		if turn == pose.turn then
			return
		end
		local was = l.target
		l.turn = turn
		lastTick = os.clock() -- the turn's own click below, not the step's tick
		aimAt(Vector2.new(fingerX, fingerY - thumb))
		local now = l.pose
		if not now or now.turn == pose.turn then
			return -- (a mirror stays leant on its wall)
		elseif not free then
			spinFrom(l, was)
			ratchet()
		elseif
			Turning.notch(now.turn, Turning.FreeTick) ~= Turning.notch(pose.turn, Turning.FreeTick)
		then
			play(SOFT, sounds())
		end
	end

	-- Turn (and R): a quarter turn with a ratchet's click-click, spinning a little past and back;
	-- on the grid on to the next quarter (a thing set askew comes square), with Free a quarter
	-- from where it is.
	local function turnNow()
		local r, l = options.room(), lifted
		if not (r and l) or l.asking then
			return
		end
		twistFrom = nil
		l.turn = Turning.press(if l.pose then l.pose.turn else l.turn, options.free())
		local pose, was = l.pose, l.target
		if pose then
			local run = l.turnRun
			local from = if run and run.to == pose then run.from else pose
			local fresh = settle(r, l, from.on, from.x, from.y)
			if fresh then
				lastTick = os.clock() -- the ratchet, not the step's tick
				setPose(r, l, fresh)
				l.turnRun = { from = from, to = l.pose }
			end
		end
		spinFrom(l, was)
		ratchet()
	end

	-- The height handle's drag (S5-03j3c2, D-459): the height the thing hung at as the finger went
	-- down, and where one stud up its wall shows on the screen then (the camera holds still: the
	-- handle's button sinks the press). Nil between drags.
	local raiseFrom: number? = nil
	local raiseUp = Vector2.zero

	local function raiseStart(): boolean
		local r, l, camera = options.room(), lifted, Workspace.CurrentCamera
		local pose = if l then l.pose else nil
		local area = if r and pose then r.placements:areaOf(pose.on) else nil
		local f = if r and pose then Arrange.frameOn(r, pose.on) else nil
		if
			not (r and l and pose and area and f and camera)
			or l.asking
			or carrying
			or area.kind ~= Spots.Kinds.Wall
		then
			return false
		end
		-- the wall point the thing hangs at and one stud above it (a wall's `y` runs up it, the
		-- frame's -Z), both to the screen
		local at = f * Vector3.new(pose.x, 0, -pose.y)
		local a = camera:WorldToScreenPoint(at)
		local b = camera:WorldToScreenPoint(at - f.ZVector)
		if a.Z <= 0 or b.Z <= 0 then
			return false
		end
		raiseFrom, raiseUp = pose.y, Vector2.new(b.X - a.X, b.Y - a.Y)
		twistFrom = nil
		return true
	end

	local function raiseBy(dx: number, dy: number)
		local r, l, from = options.room(), lifted, raiseFrom
		local pose = if l then l.pose else nil
		local area = if r and pose then r.placements:areaOf(pose.on) else nil
		if not (r and l and pose and area and from) or l.asking then
			return
		end
		local by = WallHang.along(dx, dy, raiseUp.X, raiseUp.Y)
		local step = if options.free() then 0 else Arrange.Step
		local y = WallHang.raise(from, by, step, area.depth, l.shape.depth)
		local fresh = settle(r, l, pose.on, pose.x, y)
		if fresh and (fresh.y ~= pose.y or fresh.x ~= pose.x) then
			setPose(r, l, fresh) -- its tick: one per height it moves to
		end
	end

	local function raiseStop()
		raiseFrom = nil
	end

	-- Free went on or off: a carried thing settles again where the finger has it, on the grid or
	-- off it, and a twist going on starts over from there.
	local function freeChanged()
		twistFrom = nil
		if carrying and lifted then
			aimAt(Vector2.new(fingerX, fingerY - thumb))
		end
	end

	-- Put away's flight (the plan's row: "shrinks and flies down into its tray card"): the ghost
	-- flies from where it stands to its card's point on screen, shrinking as it goes, then pops in
	-- and the card bumps. The card's point is read each step, so a camera still easing keeps it on
	-- the card. With no tray showing it shrinks where it stands, as before.
	local function flyAway(l: Lifted)
		local ghost, name = l.ghost, l.name
		local whole = ghost:GetScale()
		local from = ghost:GetPivot()
		local turned = from.Rotation
		local seconds = if options.cardAt(name) then Feedback.Fly else Feel.Back
		local share = Instance.new("NumberValue")
		share.Changed:Connect(function(t: number)
			if not ghost.Parent then
				return
			end
			local camera = Workspace.CurrentCamera
			local card = options.cardAt(name)
			if card and camera then
				local ray = camera:ScreenPointToRay(card.X, card.Y)
				local to = ray.Origin + ray.Direction * Feedback.FlyDepth
				ghost:PivotTo(CFrame.new(from.Position:Lerp(to, t)) * turned)
				ghost:ScaleTo(whole * (1 - (1 - Feedback.FlyEnd) * t))
			elseif t < 0.98 then
				ghost:ScaleTo(whole * (1 - t))
			end
		end)
		local t = TweenService:Create(
			share,
			TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Value = 1 }
		)
		t.Completed:Once(function()
			share:Destroy()
			ghost.Parent = nil -- gone; the answer lets it go
			if options.cardAt(name) then
				play(Feedback.Pop, sounds())
				options.tap(Feedback.Taps.Tap)
				options.bump(name)
			end
		end)
		t:Play()
	end

	-- Put away: the find flies into its tray card; the server's answer puts it in the box.
	local function awayNow()
		local l = lifted
		if l and not (l.original or l.asking or l.kept or carrying) then
			showRing(nil) -- one fresh out of the box (Another once too often) floats back into it
			slideBack(l)
			return
		end
		local ask = remote(Spots.PutAwayRemote)
		if not (l and l.original and ask) or l.asking or l.kept then
			return -- the job box holds everything: it has no Put away
		end
		l.asking = "away"
		stopFollow()
		showRing(nil)
		if l.shelf then
			ask:FireServer(l.what, l.shelf) -- out of a cubby: its name and spot, into the box
		else
			ask:FireServer(l.id)
		end
		task.delay(3, function()
			if lifted == l and l.asking == "away" then
				letGo(l, true) -- no answer: it stays where it was
			end
		end)
		play(Arrange.Slide, sounds())
		l.highlight.Enabled = false
		flyAway(l)
	end

	-- Waits (briefly) for the server's drawn find to stand where the ghost landed, then lets the
	-- ghost go, so there's never a gap.
	local function settleOnto(l: Lifted, id: string)
		task.spawn(function()
			local deadline = os.clock() + 1.5
			while os.clock() < deadline do
				local folder = placed()
				local drawn = if l.original and not l.shelf
					then l.original
					else if folder then folder:FindFirstChild(id) else nil
				if drawn and drawn:IsA("Model") then
					if drawn:GetPivot().Position:FuzzyEq(l.ghost:GetPivot().Position, 0.05) then
						break
					end
				end
				task.wait(0.05)
			end
			local riding = l.still - os.clock() -- its riders still hopping
			if riding > 0 then
				task.wait(riding)
			end
			letGo(l, true)
		end)
	end

	-- The server's answer to a Place or a Put away: kept, or slid back quietly.
	local function answered(what: unknown, id: unknown, refusal: unknown)
		local r, mine = options.room(), lifted
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
				if mine.shape.tops then
					tops[id] = true
				end
				if mine.finished then
					finish(mine, true, id)
				else
					local from = mine.original ~= nil and mine.shelf == nil
					options.changed(
						mine.name,
						if from then mine.id else nil,
						if from then mine.before else nil,
						id,
						{ on = pose.on, x = pose.x, y = pose.y, turn = pose.turn }
					)
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
				local stood = r.placements:poseOf(mine.id)
				if stood then -- out of a cubby, it was never set out here
					away(mine.id)
				end
				if mine.finished then
					finish(mine, true, nil)
				elseif stood then
					options.changed(mine.name, mine.id, mine.before, nil, nil)
				end
				r.placements:takeEvents()
				letGo(mine, false)
			else
				letGo(mine, true)
			end
		end
	end

	----------------------------------------------------------------------------------------------
	-- Fingers

	-- The find in one of your shelf's cubbies that the ray from `origin` along `dir` meets first
	-- (S5-03i2b, D-352), and how far along: they stand unpickable, so their boxes are tested.
	local function cubbyOn(origin: Vector3, dir: Vector3): (Model?, number)
		local best, nearest = nil, math.huge
		for _, inst in CollectionService:GetTagged(Shelf.Tag) do
			if
				inst:IsA("Model")
				and inst:GetAttribute(Shelf.OwnerAttribute) == me.UserId
				and inst:IsDescendantOf(Workspace)
			then
				local cf, size = inst:GetBoundingBox()
				local o, d, h = cf:PointToObjectSpace(origin), cf:VectorToObjectSpace(dir), size / 2
				local t = Shelf.hit({ o.X, o.Y, o.Z }, { d.X, d.Y, d.Z }, { h.X, h.Y, h.Z })
				if t and t < nearest then
					best, nearest = inst, t
				end
			end
		end
		return best, nearest
	end

	-- The find of yours under screen point `at`, if any: one set out, or one standing in your
	-- shelf's cubby, nearer than whatever's behind it (its spot second). Not from a cubby while the
	-- room holds all it can: then the tap lifts the shelf.
	local function pickAt(at: Vector2): (Model?, number?)
		local camera = Workspace.CurrentCamera
		local folder = placed()
		if not (camera and folder) then
			return nil, nil
		end
		local ray = camera:ScreenPointToRay(at.X, at.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { folder }
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 200, params)
		if not options.full() then
			local cubby, t = cubbyOn(ray.Origin, ray.Direction)
			local behind = if hit then (hit.Position - ray.Origin).Magnitude else math.huge
			local spot = if cubby then cubby:GetAttribute(Shelf.SpotAttribute) else nil
			if cubby and type(spot) == "number" and t <= behind + Feel.CubbySlack then
				return cubby, spot
			end
		end
		local inst: Instance? = if hit then hit.Instance else nil
		while inst and inst.Parent ~= folder do
			inst = inst.Parent
		end
		if inst and inst:IsA("Model") and inst:GetAttribute(Spots.OwnerAttribute) == me.UserId then
			return inst, nil
		end
		return nil, nil
	end

	----------------------------------------------------------------------------------------------
	-- Letting go (S5-03j2a, D-448): no Place button. Whatever the hand lets go of does something
	-- good, as Animal Crossing's and The Sims' room editors do: it lands, or hops to the nearest
	-- free spot and lands, or floats back where it came from. Nothing is left red in the air.

	-- Whether `l` would land just where it stood (a find tapped and let be): nothing to ask.
	local function unmoved(r: Arrange.Room, l: Lifted): boolean
		local now, was = l.pose, r.placements:poseOf(l.id)
		return l.original ~= nil
			and l.shelf == nil
			and now ~= nil
			and was ~= nil
			and now.on == was.on
			and now.x == was.x
			and now.y == was.y
			and now.turn == was.turn
	end

	-- Sets `l` back down just where it stood, with its knock: no server ask.
	local function stay(l: Lifted)
		l.asking = "back"
		stopFollow()
		showRing(nil)
		lifted = nil
		l.highlight.Enabled = false
		local cf = Instance.new("CFrameValue")
		cf.Value = l.ghost:GetPivot()
		cf.Changed:Connect(function(v: CFrame)
			l.ghost:PivotTo(v)
		end)
		local t = TweenService:Create(cf, LAND, { Value = l.from })
		t.Completed:Once(function()
			cf:Destroy()
			local band = Feedback.landing(l.name)
			play(band.thud, sounds())
			options.tap(band.tap)
			if #l.copies > 0 then
				bounce(l)
				task.delay(Settle.length(#l.copies), letGo, l, true)
			else
				letGo(l, true)
			end
		end)
		t:Play()
	end

	-- Lets go of `l`: it lands where it hovers if it may stand there; blocked, it hops to the
	-- nearest free spot within `Feel.SlideReach` and lands there; nothing free near, or over
	-- nothing it fits, it floats back where it came from (a card's back into the tray).
	local function drop(l: Lifted)
		local r = options.room()
		carrying = false
		if not r or l.asking or lifted ~= l then
			return
		end
		local pose = l.pose
		if pose and not l.fits then
			local free = freeNear(r, l, pose, slideSearch)
			if free then
				setPose(r, l, free)
			end
		end
		if not (l.pose and l.fits) then
			slideBack(l)
		elseif unmoved(r, l) then
			stay(l)
		else
			placeNow()
		end
	end

	-- The little stretch as a thing comes up under the finger: it swells and settles back.
	local function stretch(l: Lifted)
		if not l.shrink then -- out of a cubby it grows as it comes already
			local whole = l.ghost:GetScale()
			grow(l.ghost, whole * Feel.Stretch, whole)
		end
	end

	-- Lifts thing `t` (a find set out, or one in your shelf's cubby): true if it's lifted now.
	local function take(t: Model, at: Vector2?): boolean
		local name = t:GetAttribute(Shelf.FindAttribute)
		if CollectionService:HasTag(t, Shelf.Tag) and type(name) == "string" then
			liftBoxed(name, at, nil, t) -- out of its cubby
		else
			liftDrawn(t)
		end
		return lifted ~= nil
	end

	-- The carrying finger moved to gui point `x`, `y`: the thing aims a thumb's offset above it.
	local function move(x: number, y: number)
		if not carrying then
			return
		end
		fingerX, fingerY = x, y
		local camera = Workspace.CurrentCamera
		if camera then
			aimedFrom = camera.CFrame
		end
		aimAt(Vector2.new(x, y - thumb))
	end

	-- A finger (a touch when `touch`) at gui point `x`, `y` takes the lifted thing along.
	-- Nothing but the thing and its shadow while a finger carries it, as The Sims clears its
	-- buttons mid-drag: a tapped thing's buttons go as it's dragged (S5-03j2a2's captures).
	local function carry(touch: boolean, x: number, y: number)
		carrying = true
		showRing(lifted, true)
		thumb = if touch then Feel.Thumb else 0
		move(x, y)
	end

	-- What a press at gui point `at` takes: the lifted thing when the press is on it, else your find
	-- under it (one set out, or one in a cubby). Nil for the room, which the camera takes.
	local function pick(at: Vector2): Model?
		local l = lifted
		local camera = Workspace.CurrentCamera
		if l and l.asking then
			return nil
		elseif l and camera then
			local ray = camera:ScreenPointToRay(at.X, at.Y)
			local cf, size = l.ghost:GetBoundingBox()
			local o, d, h =
				cf:PointToObjectSpace(ray.Origin), cf:VectorToObjectSpace(ray.Direction), size / 2
			if Shelf.hit({ o.X, o.Y, o.Z }, { d.X, d.Y, d.Z }, { h.X, h.Y, h.Z }) then
				return l.ghost
			end
		end
		return (pickAt(at))
	end

	-- The room's fingers, from the build camera's one Gestures reader: a drag on a thing carries
	-- it and its release lets go; a tap lifts a thing (Turn, Put away) and a tap on the room, or on
	-- another thing, sets down what's lifted.
	local function intent(i: Brix.GestureIntent<Model>)
		local l = lifted
		if i.kind == "dragBegan" then
			local t = i.target
			if not t or (l and l.asking) then
				return
			end
			if not (l and (t == l.ghost or t == l.original)) then
				if l then
					drop(l)
				end
				if lifted or not take(t, Vector2.new(i.x, i.y)) then
					return
				end
				local now = lifted
				if now then
					stretch(now)
				end
			end
			twistFrom = nil
			carry(i.button == "touch", i.x, i.y)
		elseif i.kind == "dragMoved" then
			move(i.x, i.y)
		elseif i.kind == "twist" then
			-- (only ever the carried thing's: Gestures twists a thing only while it's dragged)
			if i.target ~= nil then
				twist(i.angle)
			end
		elseif i.kind == "dragEnded" then
			twistFrom = nil
			if carrying and l then
				if i.cancelled or options.overTray(i.x, i.y) then
					slideBack(l)
				else
					drop(l)
				end
			end
			carrying = false
		elseif i.kind == "tap" or i.kind == "doubleTap" then
			local t = i.target
			-- (a thing fresh out of the box has no original: a tap on the bare room, no target,
			-- must still let it go)
			if l and (l.asking or (t ~= nil and (t == l.ghost or t == l.original))) then
				return
			end
			if l then
				drop(l)
			end
			if t and not lifted and take(t, Vector2.new(i.x, i.y)) then
				local now = lifted
				if now then
					stretch(now) -- selected: it comes up a hair with the stretch, and its ring
				end
			end
		end
	end

	-- Another (The Sims' eyedropper): the selected thing is set down, and once it has landed one
	-- more of the same lifts out of your box beside it, turned the same way, selected, so a row of
	-- chairs is Another, Another, Another.
	local function another()
		local l = lifted
		if not l or l.asking or l.kept or carrying then
			return
		end
		local key, pose, from = l.name, l.pose, l.ghost:GetPivot()
		drop(l)
		task.spawn(function()
			local deadline = os.clock() + 3
			while lifted and os.clock() < deadline do
				task.wait(0.05) -- the first one's landing (and the server's word on it)
			end
			if lifted then
				return
			end
			liftBoxed(key, nil, from)
			local copy, r = lifted, options.room()
			if not (copy and r and pose) or copy.name ~= key then
				return
			end
			copy.turn = pose.turn
			local beside = freeNear(r, copy, pose, startSearch)
			if beside then
				setPose(r, copy, beside)
			end
			stretch(copy)
		end)
	end

	-- Undo or Redo (S5-03j4a, D-460): the thing is lifted as a finger would lift it and sent on
	-- the ordinary ask, so the server judges it as any move. Moved, it glides from where it
	-- stands onto `ask.to` and lands with its knock or thud; out of the box, it pops up just over
	-- its spot and drops in; into the box, it shrinks away as Put away does.
	local function replay(ask: History.Ask, finished: (ok: boolean, id: string?) -> ()): boolean
		local r = options.room()
		local to, id = ask.to, ask.id
		if lifted or carrying or not r then
			return false
		end
		if id then
			local folder = placed()
			local drawn = if folder then folder:FindFirstChild(id) else nil
			if not (drawn and drawn:IsA("Model")) then
				return false
			end
			liftDrawn(drawn)
		elseif to then
			liftBoxed(ask.name, nil, nil)
		end
		local l = lifted
		if not l or (id and l.id ~= id) then
			return false
		end
		l.finished = finished
		if not to then
			awayNow()
			return true
		end
		setPose(r, l, { on = to.on, x = to.x, y = to.y, turn = to.turn })
		l.turn = to.turn
		if not (l.pose and l.fits) then
			slideBack(l) -- taken since: it floats back, and the step is dropped
			return true
		end
		if not id then
			local whole = l.ghost:GetScale()
			l.ghost:PivotTo(l.target + Vector3.yAxis * Feel.Hover)
			grow(l.ghost, whole * Feel.UndoPop, whole)
		end
		placeNow()
		return true
	end

	-- A card dragged up out of the tray: `key` lifts out of your box under gui point `at` and the
	-- finger (a touch when `touch`) carries it.
	local function carryBoxed(key: string, at: Vector2, touch: boolean)
		if lifted then
			return
		end
		liftBoxed(key, at)
		local l = lifted
		if l then
			stretch(l)
			carry(touch, at.X, at.Y)
		end
	end

	-- A finger held on thing `t` as Arrange opened (S5-03j5b2): it lifts as a drag on it would, and
	-- the same finger carries it on, so the let-go, undo and the server's Place are the usual ones.
	local function carryHeld(t: Model, at: Vector2, touch: boolean): boolean
		if lifted or not take(t, at) then
			return false
		end
		local l = lifted
		if l then
			stretch(l)
		end
		carry(touch, at.X, at.Y)
		return true
	end

	-- The carrying finger let go: the thing lands, hops free, or floats back (always back when
	-- let go over the tray's place, as a card dragged up and brought back down changes nothing).
	local function release()
		local l = lifted
		if carrying and l then
			if options.overTray(fingerX, fingerY) then
				slideBack(l)
			else
				drop(l)
			end
		end
		carrying = false
	end

	-- Lifts `key` out of your box with no finger on it, under gui point `at` (a tapped card: the
	-- room's middle) or out of the job box at `from`, and after a beat sets it down on the free
	-- spot nearest there: it never waits in the air.
	local function setOut(key: string, at: Vector2?, from: CFrame?)
		if lifted then
			return
		end
		liftBoxed(key, at, from)
		local l, r = lifted, options.room()
		if not (l and r) then
			return
		end
		local pose = l.pose
		if pose and not l.fits then
			local free = freeNear(r, l, pose, startSearch)
			if free then
				setPose(r, l, free)
			end
		end
		task.delay(Feel.SetOut, function()
			if lifted == l and not l.asking and not carrying then
				drop(l)
			end
		end)
	end

	return {
		lifted = function(): Lifted?
			return lifted
		end,
		pick = pick,
		intent = intent,
		carryBoxed = carryBoxed,
		carryHeld = carryHeld,
		move = move,
		release = release,
		setOut = setOut,
		slideBack = slideBack,
		turnNow = turnNow,
		awayNow = awayNow,
		another = another,
		raiseStart = raiseStart,
		raiseBy = raiseBy,
		raiseStop = raiseStop,
		answered = answered,
		replay = replay,
		stopFollow = stopFollow,
		freeChanged = freeChanged,
	}
end

return ArrangeHand
