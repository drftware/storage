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

	The screen is wired from parts, each its own module (S5-03j7b): the build camera
	(ArrangeCamera), the hand that lifts one thing (ArrangeHand), the box that selects several
	(ArrangeBox) and the group that carries them (ArrangeGroup), the ring of buttons (ArrangeRing),
	the turn keys and Free switch (ArrangeTurn), Undo and Redo (ArrangeUndo), the tray and limit bar
	(ArrangeTray), the front tab's camera (ArrangeFront), the floor grid (ArrangeGrid), standing still
	and hidden (ArrangeStill), your home (ArrangeHome) and the Arrange button (ArrangeButton). This
	file only joins them: who hears whose press, and what opens and closes together.

	Only the lifted find steps (its follow, while it's lifted); everything else is tweens.
]]
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local BoxPanel = require(ReplicatedStorage.Shared.Home.BoxPanel)
local FreeCursor = require(script.Parent.FreeCursor)
local Feedback = require(ReplicatedStorage.Shared.Home.Feedback)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local Group = require(ReplicatedStorage.Shared.Home.Group)
local History = require(ReplicatedStorage.Shared.Home.History)
local Layout = require(ReplicatedStorage.Shared.Home.Layout)
local Ring = require(ReplicatedStorage.Shared.Home.Ring)
local Looks = require(ReplicatedStorage.Shared.Home.Looks)
local ArrangeBox = require(script.Parent.ArrangeBox)
local ArrangeButton = require(script.Parent.ArrangeButton)
local ArrangeCamera = require(script.Parent.ArrangeCamera)
local ArrangeFront = require(script.Parent.ArrangeFront)
local ArrangeGrid = require(script.Parent.ArrangeGrid)
local ArrangeGroup = require(script.Parent.ArrangeGroup)
local ArrangeHand = require(script.Parent.ArrangeHand)
local ArrangeHome = require(script.Parent.ArrangeHome)
local ArrangeStill = require(script.Parent.ArrangeStill)
local PlaceAim = require(script.Parent.PlaceAim)
local ArrangeRing = require(script.Parent.ArrangeRing)
local ArrangeTray = require(script.Parent.ArrangeTray)
local ArrangeTurn = require(script.Parent.ArrangeTurn)
local ArrangeTaps = require(script.Parent.ArrangeTaps)
local ArrangeUndo = require(script.Parent.ArrangeUndo)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local WallHang = require(ReplicatedStorage.Shared.Home.WallHang)

local Palette = ArrangeTray.Palette
local PANEL, RIM, INK, HONEY, HEAVY =
	Palette.panel, Palette.rim, Palette.ink, Palette.honey, Palette.font
local FINDS, FRONT = ArrangeTray.Finds, ArrangeTray.Front
local TRAY = ArrangeTray.Height

local POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- A button pressed: the job box panel's click.
local PRESS: Arrange.Sound = {
	id = BoxPanel.Click.id,
	from = 0,
	length = 0.3,
	volume = BoxPanel.Click.volume,
	pitch = BoxPanel.Click.pitch,
}

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local play = ArrangeHand.play

local ArrangeView = {}

-- The system; `hold`: opens Arrange holding a piece of furniture from your box by its id,
-- rising from `from` (the job box) when given (S5-03g4c2); and `grab`: opens Arrange with one of
-- your things lifted under the finger or mouse press `input` that was held on it (S5-03j5b2).
function ArrangeView.new(need: FreeCursor.Need): (Brix.System, (piece: string, from: CFrame?) -> (), (
	thing: Model,
	input: InputObject
) -> ())
	local me = Players.LocalPlayer
	local connections: { RBXScriptConnection } = {}
	local running = false
	local open = false
	local room: Arrange.Room? = nil
	local tops: { [string]: boolean } = {} -- finds set out whose top takes another
	-- The finger or mouse carrying a lifted thing (a card slid up, or a thing held to open).
	local dragInput: InputObject? = nil
	local grid: Part? = nil
	local savedCamera: CFrame? = nil

	local gui: ScreenGui? = nil
	local doneButton: TextButton? = nil
	-- The parts made with the gui (see the header).
	local arrangeButton: ArrangeButton.ArrangeButton? = nil
	local tray: ArrangeTray.ArrangeTray? = nil
	local buttonRing: ArrangeRing.ArrangeRing? = nil
	local turnKeys: ArrangeTurn.ArrangeTurn? = nil
	local undoKeys: ArrangeUndo.ArrangeUndo? = nil
	-- The phone taps (ArrangeTaps), made as they're first felt.
	local taps = ArrangeTaps.new()
	local stillness = ArrangeStill.new()
	local closeNow: () -> ()
	local mine = ArrangeHome.new(function()
		closeNow()
	end)
	-- The hand's answers to the build camera's one reader (set once the hand is made, below): what
	-- a press takes, and the room's intents for it.
	local pickThing: (at: Vector2) -> Model? = function(_: Vector2): Model?
		return nil
	end
	local toHand: (i: Brix.GestureIntent<Model>) -> () = function(_: Brix.GestureIntent<Model>) end
	-- The box that selects several things (ArrangeBox, S5-03j6a), set once it's made below.
	local toBox: (i: Brix.GestureIntent<Model>) -> boolean = function(
		_: Brix.GestureIntent<Model>
	): boolean
		return false
	end
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
		box = function(i: Brix.GestureIntent<Model>): boolean
			return toBox(i)
		end,
		-- Under the top bar and over the tray's tabs where they rest (the tray 10 off the foot,
		-- `TRAY` tall, its 44-point tabs 6 above it), in viewport points (D-443).
		clear = function(): (number, number)
			local inset = GuiService:GetGuiInset()
			local tall = if gui then gui.AbsoluteSize.Y else 280
			return inset.Y, inset.Y + tall - (10 + TRAY + 6 + 44)
		end,
	})
	-- The front tab's camera: your door, or your plate out in the hall (S5-03g3c).
	local front = ArrangeFront.new({
		home = mine.home,
		facing = function(): Arrange.Room?
			return if open and tray and tray.tab() == FRONT then room else nil
		end,
		show = function(at: CFrame, through: boolean)
			buildCam.show(at, through)
		end,
	})

	local function remote(name: string): RemoteEvent?
		local folder = ReplicatedStorage:FindFirstChild(Spots.RemoteFolder)
		local r = folder and folder:FindFirstChild(name)
		return if r and r:IsA("RemoteEvent") then r else nil
	end

	local function placed(): Instance?
		local home = mine.home()
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

	local function full(): boolean
		return tray ~= nil and tray.full()
	end
	local function cardAt(name: string): Vector2?
		return if tray and gui then tray.cardAt(name) else nil
	end
	local function bump(name: string)
		if tray then
			tray.bump(name)
		end
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
				local left = (if tray then tray.count(l.name) else 0)
					- (if l.original then 0 else 1)
				which = {
					away = not l.kept, -- one fresh out of the box floats back into it
					turn = not (l.starter and Layout.Lean[l.starter]), -- the mirror turns itself
					another = not l.kept and not full() and left > 0,
					-- the height handle, for a thing that hangs on a wall (read from its shape)
					raise = WallHang.only(l.shape.fits, Spots.Kinds.Wall),
				}
			end
			o.show(if which and l then l.ghost else nil, which)
		end
		local t = tray
		if t then
			t.aside(l ~= nil)
			t.scrolls(l == nil)
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
		full = full,
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
		cardAt = cardAt,
		bump = bump,
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
	-- Several at once (ArrangeBox): a finger held on the bare room and dragged boxes things; a tap,
	-- or a drag on a thing, lets the box's things go (moving them together is S5-03j6b).
	-- Whether the group (below) is moving or waiting: then no box starts.
	local groupBusy: () -> boolean = function(): boolean
		return false
	end
	local selectBox = ArrangeBox.new({
		gui = function(): ScreenGui?
			return gui
		end,
		room = function(): Arrange.Room?
			return room
		end,
		placed = placed,
		sounds = sounds,
		tap = function(t: Feedback.Tap)
			taps.tap(t)
		end,
		busy = function(): boolean
			return hand.lifted() ~= nil or groupBusy()
		end,
	})
	-- The lit things carried, turned and put away as one (ArrangeGroup).
	local several = ArrangeGroup.new({
		room = function(): Arrange.Room?
			return room
		end,
		tops = tops,
		placed = placed,
		sounds = sounds,
		remote = remote,
		tap = function(t: Feedback.Tap)
			taps.tap(t)
		end,
		ids = selectBox.ids,
		dim = selectBox.dim,
		clear = selectBox.clear,
		ring = function(thing: Model?, which: ArrangeRing.Which?)
			local u = undoKeys
			if u then
				task.defer(u.refresh)
			end
			local o = buttonRing
			if o then
				o.show(thing, which)
			end
			local t = tray
			if t then
				t.aside(thing ~= nil or groupBusy()) -- kept away while the group is carried, as for one thing
			end
		end,
		follow = function(x: number, y: number)
			buildCam.follow(x, y)
		end,
		cardAt = cardAt,
		bump = bump,
		changed = function(changes: { History.Change })
			local u = undoKeys
			if u then
				u.recordGroup(changes)
			end
		end,
	})
	groupBusy = several.busy
	-- A drag that began on a lit thing belongs to the group until it ends.
	local groupDrag = false
	pickThing = hand.pick
	toBox = function(i: Brix.GestureIntent<Model>): boolean
		local took = selectBox.intent(i)
		if i.kind == "dragEnded" then
			several.shown() -- the box let go: the ring comes round what it lit
		end
		return took
	end
	toHand = function(i: Brix.GestureIntent<Model>)
		if i.kind == "dragBegan" and not hand.lifted() and several.owns(i.target) then
			groupDrag = true
		end
		if groupDrag then
			several.intent(i)
			if i.kind == "dragEnded" then
				groupDrag = false
			end
			return
		elseif several.busy() then
			return -- the group is landing or waiting for its answer
		end
		if i.kind == "tap" or i.kind == "doubleTap" or i.kind == "dragBegan" then
			selectBox.clear()
			several.hide()
		end
		hand.intent(i)
	end

	----------------------------------------------------------------------------------------------
	-- Opening and closing

	local function openNow()
		local eyes = Workspace.CurrentCamera
		local h = mine.home()
		if open or not (eyes and h) then
			return
		end
		local r = PlaceAim.room(h, tops) -- the one judge Arrange and placing by hand share
		if not r then
			return
		end
		room = r
		open = true
		stillness.set(true)
		need("ArrangeView", true)
		local b = arrangeButton
		if b then
			b.show(false)
		end
		savedCamera = eyes.CFrame
		front.reset()
		local box = { face = r.face, centre = r.centre, size = r.size }
		buildCam.open({
			inside = box,
			slot = mine.slot() or box,
			unit = h,
		}, if tray and tray.tab() == FRONT then front.door(r) else nil)
		grid = ArrangeGrid.make(r)
		if doneButton then
			doneButton.Visible = true
		end
		local t = tray
		if t then
			t.open(true)
			t.attach(h) -- the looks' rings follow the home's look and door while you arrange
		end
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

	closeNow = function()
		if not open then
			return
		end
		local l = hand.lifted()
		if l and not l.asking then
			hand.slideBack(l)
		end
		open = false
		dragInput = nil
		selectBox.clear()
		several.hide()
		local t = tray
		if t then
			t.attach(nil)
			t.open(false)
		end
		if turnKeys then
			turnKeys.open(false)
		end
		if undoKeys then
			undoKeys.open(false)
		end
		stillness.set(false)
		need("ArrangeView", false)
		buildCam.close(savedCamera) -- swoops back into your eyes
		local g = grid
		grid = nil
		if g then
			Debris:AddItem(g, 0)
		end
		if doneButton then
			doneButton.Visible = false
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

		arrangeButton = ArrangeButton.new({
			parent = g,
			colour = PANEL,
			rim = RIM,
			ink = INK,
			font = HEAVY,
			press = press,
			pressed = function()
				openNow()
			end,
		})

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

		-- The tray and the limit bar: a card slid up lifts into the hand, a tap sets it out in the
		-- room's middle; the look chips ask the server; the front tab turns the camera to your door.
		local t = ArrangeTray.new({
			parent = g,
			press = press,
			sounds = sounds,
			lifted = function(): boolean
				return hand.lifted() ~= nil
			end,
			lift = function(key: string, at: Vector2, input: InputObject)
				hand.carryBoxed(key, at, input.UserInputType == Enum.UserInputType.Touch)
				dragInput = input
			end,
			setOut = function(key: string)
				local x, y = buildCam.middle()
				hand.setOut(key, Vector2.new(x, y))
			end,
			pick = function(kind: Looks.Kind, id: string)
				local r = remote(Looks.Remote)
				if r then
					r:FireServer(kind, id)
				end
			end,
			focus = front.focus,
			faced = function(toFront: boolean): boolean
				local r = room
				if not r then
					return false
				end
				-- in or out of the hall through black, never the wall; to the door and back a swing
				buildCam.show(if toFront then front.view(r) else nil, front.inHall())
				return true
			end,
		})
		tray = t

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
				if several.active() then
					several.awayNow()
				else
					hand.awayNow()
				end
			end,
			turn = function()
				if several.active() then
					several.turnNow()
				else
					hand.turnNow()
				end
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
				boxOf(t.meter, limitBox)
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
				if several.active() then
					several.turnNow()
				else
					hand.turnNow()
				end
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
				return l ~= nil, (l ~= nil and l.asking ~= nil) or several.busy()
			end,
			putBack = function()
				local l = hand.lifted()
				if l and not l.asking then
					hand.slideBack(l)
				end
			end,
			-- a group's step (`more`) is carried out by the group, one thing's by the hand
			replay = function(
				ask: History.Ask,
				finished: (ok: boolean, id: string?, more: { string? }?) -> ()
			): boolean
				if ask.more and #ask.more > 0 then
					return several.replay(ask, finished)
				end
				return hand.replay(ask, function(ok: boolean, id: string?)
					finished(ok, id, nil)
				end)
			end,
		})
		return g
	end

	----------------------------------------------------------------------------------------------
	-- Fingers: a card dragged out of the tray, or a thing held to open, carried by its own input
	-- (Gestures never sees a press a button sank).

	local function changed(input: InputObject)
		if tray and tray.changed(input) then
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
		if tray then
			tray.ended(input)
		end
		if dragInput == input then
			dragInput = nil
			hand.release()
		end
	end

	----------------------------------------------------------------------------------------------
	-- Opening from elsewhere

	-- Arrange rises on the finds' tab.
	local function onFinds()
		local t = tray
		if t and t.tab() ~= FINDS then
			t.showTab(FINDS, false)
		end
	end

	-- The job box's Set out (S5-03g4c2): Arrange rises on the finds' tab with the piece lifted out
	-- of the box, gliding down to the floor's middle. Nothing outside your home, for a piece that
	-- isn't a floor piece, or while something's already lifted.
	local function hold(piece: string, from: CFrame?)
		local p = Furniture.byId(piece)
		if not (running and p) or hand.lifted() or not (open or mine.standingIn()) then
			return
		end
		onFinds()
		openNow()
		if open then
			hand.setOut(Furniture.placed(piece), nil, from)
		end
	end

	-- A finger held on one of your things while Arrange is shut (HomeHoldView, S5-03j5b2): Arrange
	-- rises on the finds' tab and the thing comes up under that finger, which carries it on until
	-- it lets go (this view's own `changed` and `ended`, as a card dragged out of the tray). Only
	-- standing in your own home, and only when nothing else is lifted.
	local function grab(thing: Model, input: InputObject)
		if not running or open or hand.lifted() or not mine.standingIn() then
			return
		end
		onFinds()
		openNow()
		local at = Vector2.new(input.Position.X, input.Position.Y)
		if open and hand.carryHeld(thing, at, input.UserInputType == Enum.UserInputType.Touch) then
			dragInput = input
		end
	end

	local system: Brix.System = {
		name = "ArrangeView",
		start = function(_: any)
			running = true
			local g = makeGui()
			gui = g
			g.Parent = me:WaitForChild("PlayerGui")
			mine.start()
			table.insert(connections, UserInputService.InputChanged:Connect(changed))
			table.insert(connections, UserInputService.InputEnded:Connect(ended))
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Spots.RemoteFolder, 60)
				local answer = folder and folder:WaitForChild(Spots.AnswerRemote, 60)
				local box = folder and folder:WaitForChild(Arrange.BoxRemote, 60)
				local groupAnswer = folder and folder:WaitForChild(Group.Remote, 60)
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
					table.insert(
						connections,
						box.OnClientEvent:Connect(
							function(counts: unknown, out: unknown, limit: unknown, pieces: unknown)
								if tray then
									tray.onBox(counts, out, limit, pieces)
								end
							end
						)
					)
				end
				if groupAnswer and groupAnswer:IsA("RemoteEvent") then
					-- any: a remote's arguments, checked in `answered`
					table.insert(
						connections,
						groupAnswer.OnClientEvent:Connect(
							function(verb: any, refusal: any, ids: any)
								several.answered(verb, refusal, ids)
							end
						)
					)
				end
			end)
			-- whether you stand in your home, four times a second (the button's only step)
			task.spawn(function()
				while running do
					local b = arrangeButton
					if b and not open then
						b.show(mine.standingIn())
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
			mine.stop()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			if gui then
				local o = buttonRing
				if o then
					o.destroy()
					buttonRing = nil
				end
				local tk = turnKeys
				if tk then
					tk.destroy()
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
				tray, arrangeButton, doneButton = nil, nil, nil
			end
		end,
	}
	return system, hold, grab
end

return ArrangeView
