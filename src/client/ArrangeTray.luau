--!strict
--[[
	ArrangeTray (S5-03j7b, taken out of ArrangeView): the tray along the bottom of Arrange and the
	limit bar over the room. Bloxburg's build mode: the job box's finds and furniture as cards
	(rarest first, furniture in warm wood rims), slid up out of the tray to lift one or tapped to set
	one out in the room's middle; three tabs on the tray's top edge (the finds, the room's looks,
	your front: LooksTab's pages); and Bloxburg's build budget bar, filling honey as you set finds
	out. At the limit the cards dim and won't lift: a pressed one shakes its head, the bar pulses,
	a dull click. No words.

	ArrangeView makes one with its gui, opens and closes it with Arrange, slides it aside while a
	thing is selected, feeds it the server's box counts (`onBox`) and hands it the fingers' moves
	first (`changed`, `ended`: a card's drag is its own gui input, which Gestures never sees). The
	tray hands back a card lifted (`lift`) or tapped (`setOut`), and a tab swinging the camera to or
	from your door (`faced`).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local ArrangeHand = require(script.Parent.ArrangeHand)
local BoxPanel = require(ReplicatedStorage.Shared.Home.BoxPanel)
local Feedback = require(ReplicatedStorage.Shared.Home.Feedback)
local FurnitureTab = require(script.Parent.FurnitureTab)
local Grades = require(ReplicatedStorage.Shared.Grades)
local Home = require(ReplicatedStorage.Shared.Home)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Looks = require(ReplicatedStorage.Shared.Home.Looks)
local LooksTab = require(script.Parent.LooksTab)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local ToolPicture = require(script.Parent.ToolPicture)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Feel = Arrange.Feel

-- The job box's panel colours (BoxPanelView, D-287): calm, the box's own dusty blue (D-263).
-- Arrange's other buttons (Done, the ring, Free, Undo) wear the same.
local PANEL = Color3.fromRGB(29, 40, 45)
local CARD = Color3.fromRGB(43, 57, 63)
local RIM = Color3.fromRGB(106, 138, 147)
local INK = Lobby.Ink
local HEAVY = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
local HONEY = Color3.fromRGB(247, 201, 120) -- the limit bar's fill: warm, the home's own light
local WOOD = Color3.fromRGB(205, 160, 112) -- a piece of furniture's rim, as the job box draws it

local RISE = TweenInfo.new(Feel.Rise, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FILL = TweenInfo.new(Feel.Fill, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- A card pressed while the room holds all it can: the job box panel's click, low and dull.
local REFUSE: Arrange.Sound = {
	id = BoxPanel.Click.id,
	from = 0,
	length = 0.3,
	volume = BoxPanel.Click.volume,
	pitch = (BoxPanel.Click.pitch or 1) * 0.62,
}

-- How far a finger moves on a tray card before it's a drag (pixels): up lifts, sideways scrolls.
local SLOP = 14
-- The tray's height with the finds in it, and how far under the screen's foot it slides away:
-- far enough that its tabs, standing on its top edge, go with it.
local TRAY = 92
local AWAY = 190
-- The tray's tabs, left to right: the finds, the room's looks, your front (S5-03g3a2).
local FINDS, ROOM, FRONT = 1, 2, 3

-- A press on a tray card that isn't a drag yet.
type Pending = { key: string, input: InputObject, start: Vector2 }

export type Host = {
	parent: Instance, -- the screen's gui
	press: (button: GuiObject) -> (), -- the screen's pop and click
	sounds: () -> Instance, -- where a sound plays for this player only
	lifted: () -> boolean, -- whether the hand holds something now (then cards don't press)
	-- A card slid up out of the tray at `at` by `input`: the hand carries it on.
	lift: (key: string, at: Vector2, input: InputObject) -> (),
	-- A card tapped: out into the room's middle, and down.
	setOut: (key: string) -> (),
	-- A look chip tapped (LooksTab's own).
	pick: (kind: Looks.Kind, id: string) -> (),
	focus: (kind: Looks.Kind) -> (),
	-- The front tab opened (true) or left (false) while arranging: the camera swings to or from
	-- your door. False when it couldn't (no room).
	faced: (front: boolean) -> boolean,
}

export type ArrangeTray = {
	-- Slides the tray up and the bar down as Arrange opens (true), away as it closes (false).
	open: (on: boolean) -> (),
	-- Slides the tray down out of the way while a thing is selected or carried, back up after.
	aside: (away: boolean) -> (),
	-- Whether a finger can scroll the cards (not while a thing is lifted).
	scrolls: (on: boolean) -> (),
	-- Shows tab `n` (`ArrangeTray.Finds`, `.Room`, `.Front`), eased when you watch it change.
	showTab: (n: number, eased: boolean) -> (),
	tab: () -> number,
	-- Whose look and door the paint and front tabs show and ring (nil: none, while closed).
	attach: (u: Model?) -> (),
	-- The server's box: its counts, how many finds are set out of the most, its furniture.
	onBox: (counts: unknown, out: unknown, limit: unknown, pieces: unknown) -> (),
	-- Whether the home holds all the finds it can.
	full: () -> boolean,
	-- How many of a card's find or piece your box holds.
	count: (name: string) -> number,
	-- Where a thing put away flies to (its card's middle, kept inside the list), and the card's
	-- bump as it lands.
	cardAt: (name: string) -> Vector2?,
	bump: (name: string) -> (),
	-- The fingers, first: true when a card press took the move.
	changed: (input: InputObject) -> boolean,
	ended: (input: InputObject) -> (),
	-- The limit bar, for the ring to keep off.
	meter: GuiObject,
}

local ArrangeTray = {}

ArrangeTray.Finds, ArrangeTray.Room, ArrangeTray.Front = FINDS, ROOM, FRONT
-- The tray's height on the finds tab, resting 10 off the screen's foot.
ArrangeTray.Height = TRAY
-- The screen's colours, for Arrange's other buttons.
ArrangeTray.Palette = table.freeze({
	panel = PANEL,
	rim = RIM,
	ink = INK,
	honey = HONEY,
	font = HEAVY,
})

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
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
	to(card:FindFirstChildOfClass("ViewportFrame"), { ImageTransparency = if on then 0.6 else 0 })
	to(card:FindFirstChildOfClass("UIStroke"), { Transparency = if on then 0.7 else 0 })
	to(card:FindFirstChildOfClass("TextLabel"), { TextTransparency = if on then 0.6 else 0 })
end

function ArrangeTray.new(host: Host): ArrangeTray
	local g = host.parent
	local isOpen = false
	local onTab = FINDS
	local pending: Pending? = nil
	local boxCount: { [string]: number } = {}
	local cards: { [string]: TextButton } = {}
	local tabs: { TextButton } = {}
	local setOut, most, full = 0, Spots.limit(Spots.Start), false

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
	local meterFill = Instance.new("Frame")
	meterFill.Size = UDim2.fromScale(0, 1)
	meterFill.BackgroundColor3 = HONEY
	meterFill.BorderSizePixel = 0
	corner(meterFill, UDim.new(0.5, 0))
	meterFill.Parent = track
	local meterCount = Instance.new("TextLabel")
	meterCount.BackgroundTransparency = 1
	meterCount.AnchorPoint = Vector2.new(1, 0.5)
	meterCount.Position = UDim2.new(1, -12, 0.5, 0)
	meterCount.Size = UDim2.fromOffset(46, 22)
	meterCount.TextXAlignment = Enum.TextXAlignment.Right
	meterCount.FontFace = HEAVY
	meterCount.TextSize = 16
	meterCount.TextColor3 = INK
	meterCount.Text = `{setOut}/{most}`
	Instance.new("UIScale").Parent = meterCount
	meterCount.Parent = m

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
	local listAt = s.Position

	-- The paint tab's papers, paints, floors and floor colours, and the front tab's door
	-- colours (LooksTab's two pages), in the same tray.
	local looksHost: LooksTab.Host = {
		press = host.press,
		pick = host.pick,
		focus = host.focus,
		rim = RIM,
	}
	local roomTab = LooksTab.new(t, looksHost, "room")
	local frontTab = LooksTab.new(t, looksHost, "front")
	local looksAt = roomTab.root.Position

	-- A dimmed card pressed: it shakes its head, the bar pulses, a dull click. That's the answer:
	-- the bar is full.
	local function refuse(card: TextButton)
		ArrangeHand.play(REFUSE, host.sounds())
		card.Rotation = 0
		local shake =
			TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true)
		TweenService:Create(card, shake, { Rotation = 7 }):Play()
		local mScale = m:FindFirstChildOfClass("UIScale")
		if mScale then
			mScale.Scale = 1.14
			TweenService:Create(mScale, POP, { Scale = 1 }):Play()
		end
		meterFill.BackgroundColor3 = Color3.new(1, 1, 1)
		TweenService:Create(meterFill, FILL, { BackgroundColor3 = HONEY }):Play()
	end

	-- Rebuilds the tray's cards from the box's counts, rarest first.
	local function fillTray(
		counts: { [string]: number },
		dimmedBefore: boolean,
		pieces: { [string]: number }
	)
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
				local kind = input.UserInputType
				local pressed = kind == Enum.UserInputType.Touch
					or kind == Enum.UserInputType.MouseButton1
				if pressed and full and not host.lifted() then
					refuse(b)
				elseif pressed and not host.lifted() and not pending then
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
		TweenService:Create(meterFill, FILL, { Size = UDim2.fromScale(f, 1) }):Play()
		meterCount.Text = `{count}/{limit}`
		TweenService:Create(meterCount, FILL, { TextColor3 = if isFull then HONEY else INK }):Play()
		local pop = meterCount:FindFirstChildOfClass("UIScale")
		if pop and changed then
			pop.Scale = 1.25
			TweenService:Create(pop, POP, { Scale = 1 }):Play()
		end
	end

	-- Shows tab `n` of the tray: the tray grows or shrinks to fit, the tab's things slide in from
	-- the side it lies on (the looks pop in chip by chip), and the tab you're on lights up. The
	-- front tab swings the camera round to face your door, the others back over the room.
	local function showTab(n: number, eased: boolean)
		local was = onTab
		local changed = n ~= was
		onTab = n
		pending = nil
		local pages: { [number]: GuiObject } = {
			[FINDS] = s,
			[ROOM] = roomTab.root,
			[FRONT] = frontTab.root,
		}
		local size = UDim2.new(1, -28, 0, trayHeight(n))
		if eased then
			TweenService:Create(t, QUICK, { Size = size }):Play()
		else
			t.Size = size
		end
		for i = FINDS, FRONT do
			pages[i].Visible = i == n
		end
		if eased and changed then
			local coming = pages[n]
			local at = if n == FINDS then listAt else looksAt
			coming.Position = at + UDim2.fromOffset(if n > was then 28 else -28, 0)
			TweenService:Create(coming, QUICK, { Position = at }):Play()
			local lt = if n == ROOM then roomTab elseif n == FRONT then frontTab else nil
			if lt then
				lt.reveal()
			end
		end
		if isOpen and changed and (n == FRONT or was == FRONT) and host.faced(n == FRONT) then
			-- the limit bar counts finds: it rises off the top while you face the door
			TweenService:Create(m, RISE, { Position = meterAt(n) }):Play()
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
			host.press(tab)
			if not host.lifted() then
				showTab(i, true)
			end
		end)
		tab.Parent = t
		tabs[i] = tab
	end
	showTab(onTab, false)

	return {
		open = function(on: boolean)
			isOpen = on
			pending = nil
			if on then
				m.Visible = true
				m.Position = UDim2.fromOffset(14, -60)
				TweenService:Create(m, RISE, { Position = meterAt(onTab) }):Play()
				t.Visible = true
				t.Size = UDim2.new(1, -28, 0, trayHeight(onTab))
				t.Position = UDim2.new(0.5, 0, 1, AWAY)
				TweenService:Create(t, RISE, { Position = UDim2.new(0.5, 0, 1, -10) }):Play()
				return
			end
			local mt = TweenService:Create(m, QUICK, { Position = UDim2.new(0.5, 0, 0, -60) })
			mt.Completed:Once(function()
				if not isOpen then
					m.Visible = false
				end
			end)
			mt:Play()
			local tt = TweenService:Create(t, QUICK, { Position = UDim2.new(0.5, 0, 1, AWAY) })
			tt.Completed:Once(function()
				if not isOpen then
					t.Visible = false
				end
			end)
			tt:Play()
		end,
		aside = function(away: boolean)
			if isOpen then
				TweenService:Create(t, QUICK, {
					Position = UDim2.new(0.5, 0, 1, if away then AWAY else -10),
				}):Play()
			end
		end,
		scrolls = function(on: boolean)
			s.ScrollingEnabled = on
		end,
		showTab = showTab,
		tab = function(): number
			return onTab
		end,
		attach = function(u: Model?)
			roomTab.attach(u)
			frontTab.attach(u)
		end,
		onBox = function(counts: unknown, out: unknown, limit: unknown, pieces: unknown)
			local read = BoxPanel.read(counts)
			if not (read and isOpen) then
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
		end,
		full = function(): boolean
			return full
		end,
		count = function(name: string): number
			return boxCount[name] or 0
		end,
		-- The card's middle, kept inside the tray's list (a card scrolled out of sight takes the
		-- list's nearest edge); a thing with no card yet (the box held none) flies to the list's
		-- middle, where the new card comes in.
		cardAt = function(name: string): Vector2?
			if not (t.Visible and s.Visible and onTab == FINDS) then
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
		-- A card's drag in the tray: up out of the tray lifts it, sideways lets the tray scroll.
		changed = function(input: InputObject): boolean
			local p = pending
			if not p then
				return false
			end
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
					host.lift(p.key, at, p.input)
				elseif math.abs(d.X) > SLOP then
					pending = nil -- sideways: the tray scrolls
				end
			end
			return true
		end,
		ended = function(input: InputObject)
			local p = pending
			if p and input == p.input then
				pending = nil -- a tap on a card: out into the room's middle, and down
				host.setOut(p.key)
			end
		end,
		meter = m,
	}
end

return ArrangeTray
