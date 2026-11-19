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
local Walls = require(ReplicatedStorage.Shared.Home.Walls)
local BoxPanel = require(ReplicatedStorage.Shared.Home.BoxPanel)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local FreeCursor = require(script.Parent.FreeCursor)
local Feedback = require(ReplicatedStorage.Shared.Home.Feedback)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local FurnitureTab = require(script.Parent.FurnitureTab)
local Grades = require(ReplicatedStorage.Shared.Grades)
local Home = require(ReplicatedStorage.Shared.Home)
local Layout = require(ReplicatedStorage.Shared.Home.Layout)
local Ring = require(ReplicatedStorage.Shared.Home.Ring)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local CardPlate = require(ReplicatedStorage.Shared.Home.CardPlate)
local Looks = require(ReplicatedStorage.Shared.Home.Looks)
local ArrangeCamera = require(script.Parent.ArrangeCamera)
local ArrangeHand = require(script.Parent.ArrangeHand)
local PlaceAim = require(script.Parent.PlaceAim)
local ArrangeRing = require(script.Parent.ArrangeRing)
local ArrangeTurn = require(script.Parent.ArrangeTurn)
local ArrangeTaps = require(script.Parent.ArrangeTaps)
local ArrangeUndo = require(script.Parent.ArrangeUndo)
local LooksTab = require(script.Parent.LooksTab)
local Sizes = require(ReplicatedStorage.Shared.Home.Sizes)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local WallHang = require(ReplicatedStorage.Shared.Home.WallHang)
local ToolPicture = require(script.Parent.ToolPicture)
local Tools = require(ReplicatedStorage.Shared.Tools)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

local Feel = Arrange.Feel

-- The job box's panel colours (BoxPanelView, D-287): calm, the box's own dusty blue (D-263).
local PANEL = Color3.fromRGB(29, 40, 45)
local CARD = Color3.fromRGB(43, 57, 63)
local RIM = Color3.fromRGB(106, 138, 147)
local INK = Lobby.Ink
local HEAVY = Font.fromEnum(Enum.Font.BuilderSansExtraBold)

local RISE = TweenInfo.new(Feel.Rise, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
	Enum.KeyCode.Thumbstick1, -- the left stick slides the build camera (ArrangeCamera)
	Enum.KeyCode.Thumbstick2,
}
-- How far a finger moves on a tray card before it's a drag (pixels): up lifts, sideways scrolls.
local SLOP = 14
-- The tray's height with the finds in it, and how far under the screen's foot it slides away:
-- far enough that its tabs, standing on its top edge, go with it.
local TRAY = 92
-- The tray's tabs, left to right: the finds, the room's looks, your front (S5-03g3a2).
local FINDS, ROOM, FRONT = 1, 2, 3
local AWAY = 190

-- A press on a tray card that isn't a drag yet.
type Pending = { key: string, input: InputObject, start: Vector2 }

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local play = ArrangeHand.play

local ArrangeView = {}

-- The system, and `hold`: opens Arrange holding a piece of furniture from your box by its id,
-- rising from `from` (the job box) when given (S5-03g4c2).
function ArrangeView.new(need: FreeCursor.Need): (Brix.System, (piece: string, from: CFrame?) -> ())
	local me = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local unitWatch: { [Instance]: RBXScriptConnection } = {}
	local home: Model? = nil
	local inside: { face: CFrame, centre: Vector3, size: Vector3 }? = nil
	-- The lobby slot your home stands in, at XL (the lobby's walls round it): the build camera's
	-- eye stays inside it.
	local slotBox: ArrangeCamera.Box? = nil
	local homeSized: RBXScriptConnection? = nil -- your home's size, re-measuring `inside`
	local running = false
	local open = false
	local room: Arrange.Room? = nil
	local tops: { [string]: boolean } = {} -- finds set out whose top takes another
	local dragInput: InputObject? = nil
	local pending: Pending? = nil
	local grid: Part? = nil
	local savedCamera: CFrame? = nil
	local touchControls = true

	local gui: ScreenGui? = nil
	local arrangeGroup: CanvasGroup? = nil
	local arrangeScale: UIScale? = nil
	local shown = false
	local doneButton: TextButton? = nil
	local tray: Frame? = nil
	local list: ScrollingFrame? = nil
	-- The round buttons round the selected thing (ArrangeRing), and how many of each card's find
	-- your box holds (Another shows only while there's one more).
	local buttonRing: ArrangeRing.ArrangeRing? = nil
	-- R, Alt and the Free switch under Done (ArrangeTurn).
	local turnKeys: ArrangeTurn.ArrangeTurn? = nil
	-- Undo and Redo beside Done (ArrangeUndo).
	local undoKeys: ArrangeUndo.ArrangeUndo? = nil
	-- The phone taps (ArrangeTaps), made as they're first felt.
	local taps = ArrangeTaps.new()
	local boxCount: { [string]: number } = {}
	local cards: { [string]: TextButton } = {}
	-- The tray's three tabs (FINDS, ROOM: the paint tab, FRONT: your door; LooksTab's pages),
	-- which one shows (kept between opens), and where each tab's things rest in the tray (they
	-- slide in to there).
	local roomTab: LooksTab.Tab? = nil
	local frontTab: LooksTab.Tab? = nil
	local tabs: { TextButton } = {}
	local onTab = FINDS
	local listAt, looksAt = UDim2.new(), UDim2.new()
	-- The hand's answers to the build camera's one reader (set once the hand is made, below): what
	-- a press takes, and the room's intents for it.
	local pickThing: (at: Vector2) -> Model? = function(_: Vector2): Model?
		return nil
	end
	local toHand: (i: Brix.GestureIntent<Model>) -> () = function(_: Brix.GestureIntent<Model>) end
	-- The build camera (S5-03j1a): it swoops up as Arrange opens, the hands move it, and it hands
	-- a press that takes a thing, and every tap, to the hand (S5-03j2a).
	local buildCam = ArrangeCamera.new({
		gui = function(): ScreenGui?
			return gui
		end,
		pick = function(x: number, y: number): Model?
			return pickThing(Vector2.new(x, y))
		end,
		hand = function(i: Brix.GestureIntent<Model>)
			toHand(i)
		end,
		-- Under the top bar and over the tray's tabs where they rest (the tray 10 off the foot,
		-- `TRAY` tall, its 44-point tabs 6 above it), in viewport points (D-443).
		clear = function(): (number, number)
			local inset = GuiService:GetGuiInset()
			local tall = if gui then gui.AbsoluteSize.Y else 280
			return inset.Y, inset.Y + tall - (10 + TRAY + 6 + 44)
		end,
	})
	-- What the front tab shows (S5-03g3c): the door from inside, or after a card chip your
	-- plate from the hall. Back to the door each time Arrange opens.
	local frontAt: "door" | "card" = "door"
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

	-- Builds the room's judge and loads what's set out in it from what the server drew
	-- (`PlaceAim.room`, the one judge Arrange and placing by hand share).
	local function build(): Arrange.Room?
		local unit = home
		return if unit then PlaceAim.room(unit, tops) else nil
	end

	-- The ring pops in round a selected thing (ArrangeRing), and the tray slides down out of the
	-- way so the floor by the door shows; it slides back up when the thing is set down or let go.
	-- While a finger is `carrying` it, the ring stays hidden: nothing but the thing and its shadow.
	local function showRing(l: ArrangeHand.Lifted?, carrying: boolean?)
		local u = undoKeys
		if u then
			task.defer(u.refresh) -- once the hand has settled what it holds
		end
		local o = buttonRing
		if o then
			local which: ArrangeRing.Which? = nil
			if l and not carrying then
				-- one more of the same while your box holds one past this (a selected thing
				-- straight out of the box is still counted there)
				local left = (boxCount[l.name] or 0) - (if l.original then 0 else 1)
				which = {
					away = not l.kept, -- one fresh out of the box floats back into it
					turn = not (l.starter and Layout.Lean[l.starter]), -- the mirror turns itself
					another = not l.kept and not full and left > 0,
					-- the height handle, for a thing that hangs on a wall (read from its shape)
					raise = WallHang.only(l.shape.fits, Spots.Kinds.Wall),
				}
			end
			o.show(if which and l then l.ghost else nil, which)
		end
		local t = tray
		if t and open then
			TweenService:Create(t, QUICK, {
				Position = UDim2.new(0.5, 0, 1, if l then AWAY else -10),
			}):Play()
		end
		local s = list
		if s then
			s.ScrollingEnabled = l == nil
		end
	end

	-- The hand: everything that lifts, carries and sets down (ArrangeHand).
	local hand = ArrangeHand.new({
		room = function(): Arrange.Room?
			return room
		end,
		tops = tops,
		placed = placed,
		sounds = sounds,
		remote = remote,
		full = function(): boolean
			return full
		end,
		showRing = showRing,
		follow = function(x: number, y: number)
			buildCam.follow(x, y)
		end,
		-- Below the tray's top where it rests (10 off the foot, `TRAY` tall), in gui points.
		overTray = function(_: number, y: number): boolean
			local tall = if gui then gui.AbsoluteSize.Y else 280
			return y >= tall - (10 + TRAY)
		end,
		tap = function(t: Feedback.Tap)
			taps.tap(t)
		end,
		-- The card's middle, kept inside the tray's list (a card scrolled out of sight takes the
		-- list's nearest edge); a thing with no card yet (the box held none) flies to the list's
		-- middle, where the new card comes in.
		cardAt = function(name: string): Vector2?
			local t, s = tray, list
			if not (gui and t and s and t.Visible and s.Visible and onTab == FINDS) then
				return nil
			end
			local lo, size = s.AbsolutePosition, s.AbsoluteSize
			local c = cards[name]
			if not c then
				return lo + size / 2
			end
			local mid = c.AbsolutePosition + c.AbsoluteSize / 2
			return Vector2.new(
				math.clamp(mid.X, lo.X, lo.X + size.X),
				math.clamp(mid.Y, lo.Y, lo.Y + size.Y)
			)
		end,
		bump = function(name: string)
			local c = cards[name]
			if not c then
				return
			end
			local sc = c:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
			sc.Parent = c
			sc.Scale = Feedback.Bump
			TweenService:Create(sc, POP, { Scale = 1 }):Play()
		end,
		free = function(): boolean
			local t = turnKeys
			return t ~= nil and t.free()
		end,
		changed = function(
			name: string,
			idBefore: string?,
			before: Brix.PlacementPose?,
			idAfter: string?,
			after: Brix.PlacementPose?
		)
			local u = undoKeys
			if u then
				u.record(name, idBefore, before, idAfter, after)
			end
		end,
	})
	pickThing, toHand = hand.pick, hand.intent

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
		table.clear(boxCount)
		local template = Home.template()
		-- the furniture first, then the finds
		local dealt: { BoxPanel.Card } = {}
		for _, card in BoxPanel.pieces(pieces) do
			if BoxPanel.settable(card) then
				table.insert(dealt, card)
			end
		end
		for _, card in BoxPanel.cards(counts, Tools.Catalog :: any) do -- any: its rows carry more than Row
			-- a sealed one stays on the shelf or in the box for now: set out standing in its pack
			-- is S5-02b2c2's (D-427), and the server refuses one till then
			if not card.sealed then
				table.insert(dealt, card)
			end
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
				if pressed and full and not hand.lifted() then
					refuse(b)
				elseif pressed and not hand.lifted() and not pending then
					pending = {
						key = card.key,
						input = input,
						start = Vector2.new(input.Position.X, input.Position.Y),
					}
				end
			end)
			b.Parent = s
			cards[card.key] = b
			boxCount[card.key] = card.count
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

	-- The camera on the front tab after a card chip: out in the hall facing your home's plate, a
	-- little under it (S5-03g3c). Nil when the card isn't here (not streamed in).
	local function hall(): CFrame?
		local n = if home then home:GetAttribute(Arrange.SlotAttribute) else nil
		if n == nil then
			return nil
		end
		for _, card in CollectionService:GetTagged(Home.CardTag) do
			local wall = card:GetAttribute(CardPlate.WallAttribute)
			if card:GetAttribute(Home.CardSlot) == n and typeof(wall) == "CFrame" then
				local eye = wall * Vector3.new(0, -Feel.HallBelow, -Feel.HallOut)
				return CFrame.lookAt(eye, wall * Vector3.new(0, -Feel.HallAim, 0))
			end
		end
		return nil
	end

	-- Where the front tab's camera stands now: the plate's, else the door's.
	local function frontView(r: Arrange.Room): CFrame
		return (if frontAt == "card" then hall() else nil) or front(r)
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
	-- Top left, across from Done, so the band over the tray is the room's alone (S5-03j1d2).
	local function meterAt(n: number): UDim2
		return UDim2.fromOffset(14, if n == FRONT then -120 else 14)
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
			-- in or out of the hall through black, never the wall; to the door and back a swing
			buildCam.show(if n == FRONT then frontView(r) else nil, frontAt == "card")
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
		local eyes = Workspace.CurrentCamera
		local h = home
		if open or not (eyes and h) then
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
		eyes:SetAttribute(SEIZED, true)
		need("ArrangeView", true)
		showButton(false)
		savedCamera = eyes.CFrame
		frontAt = "door"
		buildCam.open({
			inside = { face = r.face, centre = r.centre, size = r.size },
			slot = slotBox or { face = r.face, centre = r.centre, size = r.size },
			unit = h,
		}, if onTab == FRONT then front(r) else nil)
		grid = makeGrid(r)
		local d, t, m = doneButton, tray, meter
		if d then
			d.Visible = true
		end
		if m then
			m.Visible = true
			m.Position = UDim2.fromOffset(14, -60)
			TweenService:Create(m, RISE, { Position = meterAt(onTab) }):Play()
		end
		if t then
			t.Visible = true
			t.Size = UDim2.new(1, -28, 0, trayHeight(onTab))
			t.Position = UDim2.new(0.5, 0, 1, AWAY)
			TweenService:Create(t, RISE, { Position = UDim2.new(0.5, 0, 1, -10) }):Play()
		end
		attachTabs(home) -- their rings follow the home's look and door while you arrange
		if turnKeys then
			turnKeys.open(true)
		end
		if undoKeys then
			undoKeys.open(true)
		end
		local ask = remote(Arrange.BoxRemote)
		if ask then
			ask:FireServer()
		end
	end

	local function closeNow()
		if not open then
			return
		end
		local l = hand.lifted()
		if l and not l.asking then
			hand.slideBack(l)
		end
		open = false
		pending = nil
		dragInput = nil
		attachTabs(nil)
		if turnKeys then
			turnKeys.open(false)
		end
		if undoKeys then
			undoKeys.open(false)
		end
		still(false)
		body(false)
		me:SetAttribute(Tools.StowAttribute, nil) -- the wheel comes back up
		local seized = Workspace.CurrentCamera
		if seized then
			seized:SetAttribute(SEIZED, nil)
		end
		need("ArrangeView", false)
		buildCam.close(savedCamera) -- swoops back into your eyes
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
		showRing(nil)
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

		-- The limit bar, top left while arranging: four squares (the Arrange button's), a track
		-- that fills honey as you set finds out, and the count. Bloxburg's build budget bar.
		local m = Instance.new("Frame")
		m.AnchorPoint = Vector2.new(0, 0)
		m.Position = UDim2.fromOffset(14, -60)
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
			focus = function(kind: Looks.Kind)
				local r = room
				local want: "door" | "card" = if kind == "card" then "card" else "door"
				if not (open and r and onTab == FRONT) or want == frontAt then
					return
				end
				if want == "card" and not hall() then
					return -- the plate isn't here to look at: stay on the door
				end
				frontAt = want
				buildCam.show(frontView(r), true)
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
				if not hand.lifted() then
					showTab(i, true)
				end
			end)
			tab.Parent = t
			tabs[i] = tab
		end
		showTab(onTab, false)

		-- The round buttons round a selected thing (S5-03j2b1): Put away, Turn, Another, kept off
		-- Done and the limit bar (filled in place: the ring lays out while the camera moves).
		local doneBox: Ring.Box = { left = 0, top = 0, right = 0, bottom = 0 }
		local limitBox: Ring.Box = { left = 0, top = 0, right = 0, bottom = 0 }
		local freeBox: Ring.Box = { left = 0, top = 0, right = 0, bottom = 0 }
		local undoBox: Ring.Box = { left = 0, top = 0, right = 0, bottom = 0 }
		local redoBox: Ring.Box = { left = 0, top = 0, right = 0, bottom = 0 }
		local keepClear = { doneBox, limitBox, freeBox, undoBox, redoBox }
		local function boxOf(o: GuiObject, into: Ring.Box)
			local at, size = o.AbsolutePosition, o.AbsoluteSize
			into.left, into.top, into.right, into.bottom = at.X, at.Y, at.X + size.X, at.Y + size.Y
		end
		buttonRing = ArrangeRing.new({
			parent = g,
			colour = PANEL,
			rim = RIM,
			ink = INK,
			press = press,
			away = function()
				hand.awayNow()
			end,
			turn = function()
				hand.turnNow()
			end,
			another = function()
				hand.another()
			end,
			raise = {
				start = function(): boolean
					return hand.raiseStart()
				end,
				move = function(dx: number, dy: number)
					hand.raiseBy(dx, dy)
				end,
				stop = function()
					hand.raiseStop()
				end,
			},
			area = function(): Ring.Box
				local size = g.AbsoluteSize
				return { left = 0, top = 0, right = size.X, bottom = size.Y }
			end,
			avoid = function(): { Ring.Box }
				boxOf(done, doneBox)
				boxOf(m, limitBox)
				local keys = turnKeys
				if keys then
					boxOf(keys.button, freeBox)
				end
				local u = undoKeys
				if u then
					boxOf(u.buttons[1], undoBox)
					boxOf(u.buttons[2], redoBox)
				end
				return keepClear
			end,
		})
		turnKeys = ArrangeTurn.new({
			parent = g,
			at = UDim2.new(1, -14, 0, 72), -- under Done (14 down, 48 tall), a 10-point gap
			colour = PANEL,
			rim = RIM,
			ink = INK,
			lit = HONEY,
			press = press,
			turn = function()
				hand.turnNow()
			end,
			changed = function()
				hand.freeChanged()
			end,
		})
		undoKeys = ArrangeUndo.new({
			parent = g,
			at = UDim2.new(1, -128, 0, 14), -- Done's row, left of it (104 wide, a 10-point gap)
			colour = PANEL,
			rim = RIM,
			ink = INK,
			press = press,
			lifted = function(): (boolean, boolean)
				local l = hand.lifted()
				return l ~= nil, l ~= nil and l.asking ~= nil
			end,
			putBack = function()
				local l = hand.lifted()
				if l and not l.asking then
					hand.slideBack(l)
				end
			end,
			replay = hand.replay,
		})
		return g
	end

	----------------------------------------------------------------------------------------------
	-- Fingers

	-- A card's drag in the tray: its own gui input (Gestures never sees a press a button sank),
	-- handed to the hand once it lifts.
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
					hand.carryBoxed(p.key, at, p.input.UserInputType == Enum.UserInputType.Touch)
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
			hand.move(input.Position.X, input.Position.Y)
		end
	end

	local function ended(input: InputObject)
		local p = pending
		if p and input == p.input then
			pending = nil -- a tap on a card: out into the room's middle, and down
			local x, y = buildCam.middle()
			hand.setOut(p.key, Vector2.new(x, y))
		end
		if dragInput == input then
			dragInput = nil
			hand.release()
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
		if homeSized then
			homeSized:Disconnect()
			homeSized = nil
		end
		-- the room inside its walls at its size (S5-03h5, D-354), measured again as it grows
		local function measure()
			inside = nil
			slotBox = nil
			local n = if mine then mine:GetAttribute(Arrange.SlotAttribute) else nil
			local slot = if type(n) == "number" then Arrange.slot(n) else nil
			if mine and slot then
				local face, _, c, s = Arrange.areas(slot, Lobby.Origin, Walls.sizeOf(mine))
				inside = {
					face = face,
					centre = Vector3.new(c[1], c[2], c[3]),
					size = Vector3.new(s[1], s[2], s[3]),
				}
				local xlFace, _, xc, xs = Arrange.areas(slot, Lobby.Origin, Sizes.Biggest)
				slotBox = {
					face = xlFace,
					centre = Vector3.new(xc[1], xc[2], xc[3]),
					size = Vector3.new(xs[1], xs[2], xs[3]),
				}
			end
		end
		measure()
		if mine then
			homeSized = mine:GetAttributeChangedSignal(Spots.SizeAttribute):Connect(function()
				measure()
				-- it grew while you arranged (a friend's gift; S5-03h6, D-356): the room you were
				-- judging is laid again bigger, so the screen closes as it does on a walk away,
				-- a lifted piece sliding back, and the walls grind back round you
				closeNow()
			end)
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
		if not (running and p) or hand.lifted() or not (open or standingIn()) then
			return
		end
		if onTab ~= FINDS then
			showTab(FINDS, false)
		end
		openNow()
		if open then
			hand.setOut(Furniture.placed(piece), nil, from)
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
							hand.answered(what, id, refusal)
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
			buildCam.destroy()
			hand.stopFollow()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, w in unitWatch do
				w:Disconnect()
			end
			table.clear(unitWatch)
			if gui then
				local o = buttonRing
				if o then
					o.destroy()
					buttonRing = nil
				end
				local t = turnKeys
				if t then
					t.destroy()
					turnKeys = nil
				end
				local u = undoKeys
				if u then
					u.destroy()
					undoKeys = nil
				end
				taps.destroy()
				gui:Destroy()
				gui = nil
			end
		end,
	}
	return system, hold
end

return ArrangeView
