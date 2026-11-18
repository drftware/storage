--!strict
--[[
	LooksTab: the paint tab on the Arrange screen (S5-03g2b3, D-328; the home doc's idea 18). The
	moment: you open Arrange, tap the paint tab and your home's papers and floors sit there as
	little swatches; tap Leaves and it rolls round the room as the chip presses in. Animal
	Crossing's wallpaper and flooring, Bloxburg's paint dots.

	Two rows, the walls over the floor as the room stands: the papers, then the paints; the floors,
	then the chosen floor's colours. A paper's or floor's chip is its set's colour map over the
	colour it would wear if you tapped it (the panels' Overlay: the map's clear bits show the
	colour); a dot is a paint or a floor colour. What the home wears is ringed white. A tap fires
	`Looks.Remote` (kind, id) through the host; the wipe round the room is the answer (LooksView)
	and the ring moves when the unit's `Looks.Attribute` changes. No words. ArrangeView hosts it in
	its tray, beside the finds.

	The same tab, on its "front" page, is your door's colours (S5-03g3a2, D-330): one row of dots,
	the door's id read from the unit's `Looks.DoorAttribute`, the roll down the slats the answer
	(RollUpDoor.paint). Under them, your name card's styles (S5-03g3c, D-357): each chip a little
	plate with your name on it in that style's paint, font and ink (Animal Crossing's catalogue),
	the style read from `Looks.CardAttribute`. One you don't have yet wears a small coin or the
	Robux mark (`Looks.cardLock`) and a tap only shakes it and pops the mark: no popup, no words.
	Bought at the counter (S5-03g3d, D-360), the mark pops away and the shade lifts as the tray
	next shows, read from the styles you own on your Player (`CardSale.Attribute`).
	A door or card tap also asks the host to show what it changes (`focus`): the door from inside,
	the plate from the hall, where it swings down into place (HomeCards).

	Chips are ImageLabels of the colour maps LooksView fetches once a home is near, not
	ViewportFrames: twelve 3D views in a tray cost a low-end phone a frame each, and a flat map at
	46 px reads the pattern as well.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CardPlate = require(ReplicatedStorage.Shared.Home.CardPlate)
local CardSale = require(ReplicatedStorage.Shared.Home.CardSale)
local Home = require(ReplicatedStorage.Shared.Home)
local Looks = require(ReplicatedStorage.Shared.Home.Looks)
local LooksView = require(script.Parent.LooksView)
local Specs = require(ReplicatedStorage.Shared.Home.Specs)

-- What the tab needs from the screen hosting it.
export type Page = "room" | "front" -- the room's walls and floor, or your door from the hall
export type Host = {
	press: (button: GuiObject) -> (), -- the button's pop and soft click
	pick: (kind: Looks.Kind, id: string) -> (), -- asks the server for the look
	focus: (kind: Looks.Kind) -> (), -- a door or card chip tapped: show the door, or the plate
	rim: Color3, -- an unworn chip's faint outline
}
export type Tab = {
	root: Frame,
	attach: (unit: Model?) -> (), -- whose look to show and ring (nil: none, while closed)
	reveal: () -> (), -- the chips pop in, as the tab opens
}
type Chip = {
	button: TextButton,
	kind: Looks.Kind,
	id: string,
	stroke: UIStroke,
	scale: UIScale,
	mark: GuiObject?, -- a card style's coin or Robux mark, while it isn't yours
	dim: GuiObject?, -- the shade over a card style not yours yet
	locked: boolean?, -- a card style not yours yet: a tap only shakes it
	leaving: boolean?, -- bought since its mark last showed: the mark leaves as the tray reveals
}

local LooksTab = {}

local CHIP = 46 -- a paper's or floor's chip, square: past a thumb's 44 points
local DOT = 44 -- a paint's or floor colour's dot
local ROW = 54 -- a row's height: room round a chip for its ring
local GAP = 6 -- between chips: eight paints and four papers fit a Galaxy A16's tray
local PAD = 6 -- above and below the rows
local PLATE = Vector2.new(100, 44) -- a card style's chip: the plate's long shape, a thumb tall
local MARK = 18 -- a locked style's coin or Robux mark, on the chip's top right corner
-- The tray's height on each page: two rows each, the walls over the floor, the door over its card.
LooksTab.Heights = table.freeze({ room = ROW * 2 + PAD * 2, front = ROW * 2 + PAD * 2 })

local RING = Color3.new(1, 1, 1) -- what the home wears
local QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TINT = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local GONE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local SHAKE = TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
-- A bought style's mark leaving its chip: it pops in on itself as the shade lifts.
local MARK_OUT = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local ROBUX = utf8.char(0xE002) -- Roblox's own Robux mark in its fonts
local COIN = Color3.fromHex("#F2C14E") -- a locked cash style's coin, and its rim
local COIN_RIM = Color3.fromHex("#A8741A")
local OAK = Color3.fromHex("#8A6A44") -- the chalk slate's moulded frame

-- A pop that waits `delay` seconds: the chips land one after another.
local function pop(delay: number): TweenInfo
	return TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, delay)
end

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function colour(hex: string): Color3
	return if hex == "" then Color3.new(1, 1, 1) else Color3.fromHex(hex) -- "": baked, white
end

-- What the chosen look has for `kind`.
local function current(chosen: Looks.Chosen, kind: Looks.Kind): string
	if kind == "paint" then
		return chosen.paint
	elseif kind == "paper" then
		return chosen.paper
	elseif kind == "floor" then
		return chosen.floor
	elseif kind == "door" then
		return chosen.door
	elseif kind == "card" then
		return chosen.card
	end
	return chosen.floorColour
end

-- The colour a paper's or floor's chip shows: what that surface would wear were it tapped.
local function tint(chosen: Looks.Chosen, kind: Looks.Kind, id: string): Color3
	local walls, floor = Looks.wear(Looks.pick(chosen, kind, id) or chosen)
	return colour(if kind == "paper" then walls.colour else floor.colour)
end

-- A card style's plate drawn into `b`, a frame `LooksTab.Plate` in size: the style's paint (its
-- map over it, as the plate's Overlay shows the paint), your name in its font and ink, the neon's
-- glowing; the slate's oak frame; the steel's bolts and the board's screws as dots at its ends.
-- The paint tab's chips and the counter's style cards (StyleCards) both wear it.
LooksTab.Plate = PLATE
function LooksTab.plateFace(b: GuiObject, style: Specs.CardStyle, template: Model)
	b.BackgroundColor3 = if style.Paint then Color3.fromHex(style.Paint) else Color3.new(1, 1, 1)
	b.BorderSizePixel = 0
	local radius = UDim.new(0, 6)
	corner(b, radius)
	local first = template:FindFirstChild(style.Parts[1], true)
	local look = if first then first:FindFirstChildOfClass("SurfaceAppearance") else nil
	-- any: ColorMapContent (a Content) isn't in every type definition yet
	local content = if look then (look :: any).ColorMapContent else nil
	local uri = if content then content.Uri else nil
	if type(uri) == "string" and uri ~= "" then
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromScale(1, 1)
		image.Image = uri
		image.ScaleType = Enum.ScaleType.Crop
		image.ZIndex = 1
		corner(image, radius)
		image.Parent = b
	end
	if style.Parts[2] == "CardChalkFrame" then -- the slate's oak frame, inside the ring
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.new(1, -6, 1, -6)
		frame.BackgroundTransparency = 1
		frame.ZIndex = 2
		corner(frame, UDim.new(0, 4))
		local edge = Instance.new("UIStroke")
		edge.Color = OAK
		edge.Thickness = 3
		edge.Parent = frame
		frame.Parent = b
	end
	local fixing = CardPlate.Plain[style.Parts[2] or ""]
	if fixing and fixing.colour:sub(1, 1) == "#" then -- the bolts or screws at its ends
		for _, x in { 0, 1 } do
			local dot = Instance.new("Frame")
			dot.AnchorPoint = Vector2.new(x, 0.5)
			dot.Position = UDim2.new(x, if x == 0 then 5 else -5, 0.5, 0)
			dot.Size = UDim2.fromOffset(4, 4)
			dot.BackgroundColor3 = Color3.fromHex(fixing.colour)
			dot.BorderSizePixel = 0
			dot.ZIndex = 2
			corner(dot, UDim.new(0.5, 0))
			dot.Parent = b
		end
	end
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.AnchorPoint = Vector2.new(0.5, 0.5)
	name.Position = UDim2.fromScale(0.5, 0.5)
	name.Size = UDim2.new(1, -20, 1, -14)
	name.BackgroundTransparency = 1
	name.Text = Home.Holding.words(Players.LocalPlayer.DisplayName)
	name.TextScaled = true
	name.FontFace = Font.fromName(style.Font, CardPlate.weight(style.Weight))
	name.TextColor3 = Color3.fromHex(style.Ink)
	name.ZIndex = 3
	if style.Glow then
		local glow = Instance.new("UIStroke")
		glow.Name = "Glow"
		glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		glow.Color = Color3.fromHex(style.Glow)
		glow.Thickness = 1.5
		glow.Transparency = CardPlate.Neon.Haze
		glow.Parent = name
	end
	name.Parent = b
end

-- The tab's icon, into a 36 by 32 frame: a fan of three paint chips from one corner, a decorator's
-- colour card, edged in `edge` so they read apart.
function LooksTab.icon(into: GuiObject, edge: Color3)
	local fan = { -- the front one last
		{ id = "Terracotta", turn = -24 },
		{ id = "DuckEgg", turn = 24 },
		{ id = "Butter", turn = 0 },
	}
	for i, each in fan do
		local hex = "#FFFFFF"
		for _, paint in Specs.Looks.Paints do
			if paint.Id == each.id then
				hex = paint.Colour
			end
		end
		local turn = each.turn
		local a = math.rad(turn)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		-- turned about the fan's foot (18, 29), half a chip's 20 above it
		f.Position = UDim2.fromOffset(18 + math.sin(a) * 10, 29 - math.cos(a) * 10)
		f.Size = UDim2.fromOffset(12, 20)
		f.Rotation = turn
		f.ZIndex = i
		f.BackgroundColor3 = Color3.fromHex(hex)
		f.BorderSizePixel = 0
		corner(f, UDim.new(0, 3))
		local stroke = Instance.new("UIStroke")
		stroke.Color = edge
		stroke.Thickness = 1.5
		stroke.Parent = f
		f.Parent = into
	end
end

-- The front tab's icon, into a 36 by 32 frame: a little roll-up door in the start's clay, three
-- slat lines across it in `edge`, and the bar along its foot.
function LooksTab.frontIcon(into: GuiObject, edge: Color3)
	local door = Instance.new("Frame")
	door.AnchorPoint = Vector2.new(0.5, 0.5)
	door.Position = UDim2.fromOffset(18, 16)
	door.Size = UDim2.fromOffset(24, 24)
	door.BackgroundColor3 = Color3.fromHex(Specs.Looks.Doors[1].Colour)
	door.BorderSizePixel = 0
	corner(door, UDim.new(0, 4))
	local stroke = Instance.new("UIStroke")
	stroke.Color = edge
	stroke.Thickness = 1.5
	stroke.Parent = door
	for i = 1, 3 do
		local slat = Instance.new("Frame")
		slat.AnchorPoint = Vector2.new(0.5, 0.5)
		slat.Position = UDim2.fromOffset(12, 6 * i - 1)
		slat.Size = UDim2.fromOffset(18, 2)
		slat.BackgroundColor3 = edge
		slat.BackgroundTransparency = 0.25
		slat.BorderSizePixel = 0
		corner(slat, UDim.new(0.5, 0))
		slat.Parent = door
	end
	local bar = Instance.new("Frame") -- the bottom bar: heavier, so it reads as a door's foot
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.fromOffset(12, 22)
	bar.Size = UDim2.fromOffset(20, 3)
	bar.BackgroundColor3 = edge
	bar.BorderSizePixel = 0
	corner(bar, UDim.new(0.5, 0))
	bar.Parent = door
	door.Parent = into
end

function LooksTab.new(tray: Frame, host: Host, page: Page): Tab
	local root = Instance.new("Frame")
	root.Name = if page == "front" then "Front" else "Looks"
	root.BackgroundTransparency = 1
	root.Position = UDim2.fromOffset(10, PAD)
	root.Size = UDim2.new(1, -20, 1, -PAD * 2)
	root.Visible = false
	local stack = Instance.new("UIListLayout")
	stack.FillDirection = Enum.FillDirection.Vertical
	stack.SortOrder = Enum.SortOrder.LayoutOrder
	stack.Parent = root
	root.Parent = tray

	local unit: Model? = nil
	local watches: { RBXScriptConnection } = {}
	local chosen = Looks.start()
	local built = false
	local chips: { Chip } = {} -- papers, paints and floors: built once
	local dots: { Chip } = {} -- the chosen floor's colours: built again when the floor changes
	local dotsOf: string? = nil -- the floor `dots` are the colours of
	local floors: ScrollingFrame? = nil
	local divider: Frame? = nil -- between the floors and their colours

	local function row(order: number): ScrollingFrame
		local s = Instance.new("ScrollingFrame")
		s.BackgroundTransparency = 1
		s.BorderSizePixel = 0
		s.LayoutOrder = order
		s.Size = UDim2.new(1, 0, 0, ROW)
		s.ScrollingDirection = Enum.ScrollingDirection.X
		s.AutomaticCanvasSize = Enum.AutomaticSize.X
		s.CanvasSize = UDim2.new()
		s.ScrollBarThickness = 0
		local pad = Instance.new("UIPadding") -- room for the end chips' rings
		pad.PaddingLeft = UDim.new(0, 4)
		pad.PaddingRight = UDim.new(0, 4)
		pad.Parent = s
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, GAP)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = s
		s.Parent = root
		return s
	end

	local function line(parent: Instance, order: number): Frame
		local f = Instance.new("Frame")
		f.LayoutOrder = order
		f.Size = UDim2.fromOffset(2, 28)
		f.BackgroundColor3 = host.rim
		f.BackgroundTransparency = 0.5
		f.BorderSizePixel = 0
		corner(f, UDim.new(0.5, 0))
		f.Parent = parent
		return f
	end

	local function ring(c: Chip, worn: boolean, eased: boolean)
		local goal = {
			Color = if worn then RING else host.rim,
			Transparency = if worn then 0 else 0.5,
			Thickness = if worn then 3 else 2,
		}
		if eased then
			TweenService:Create(c.stroke, QUICK, goal):Play()
		else
			c.stroke.Color, c.stroke.Transparency, c.stroke.Thickness =
				goal.Color, goal.Transparency, goal.Thickness
		end
	end

	-- A locked style tapped: the chip shakes its head and its mark pops, and nothing is asked.
	local function nope(c: Chip)
		local b = c.button
		local mark = c.mark
		if mark then
			host.press(mark) -- the mark's pop and the soft click: it's what stands in the way
		end
		local out = TweenService:Create(b, SHAKE, { Rotation = 5 })
		out.Completed:Once(function(state: Enum.PlaybackState)
			if state ~= Enum.PlaybackState.Completed then
				return
			end
			local back = TweenService:Create(b, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
				Rotation = -4,
			})
			back.Completed:Once(function(s: Enum.PlaybackState)
				if s == Enum.PlaybackState.Completed then
					TweenService:Create(b, SHAKE, { Rotation = 0 }):Play()
				end
			end)
			back:Play()
		end)
		out:Play()
	end

	local function tapped(c: Chip)
		if c.locked then
			nope(c)
			return
		end
		host.press(c.button)
		if current(chosen, c.kind) ~= c.id then
			host.pick(c.kind, c.id)
		end -- the look it wears already: the press is the whole answer
		if c.kind == "door" or c.kind == "card" then
			host.focus(c.kind)
		end
	end

	-- A chip or dot: `uri` (a set's colour map) over `fill`, round when it's a dot.
	local function chip(
		into: Instance,
		order: number,
		kind: Looks.Kind,
		id: string,
		fill: Color3,
		uri: string?
	): Chip
		local size = if uri then CHIP else DOT
		local b = Instance.new("TextButton")
		b.Name = `{kind}{id}`
		b.Text = ""
		b.AutoButtonColor = false
		b.LayoutOrder = order
		b.Size = UDim2.fromOffset(size, size)
		b.BackgroundColor3 = fill
		b.BorderSizePixel = 0
		local radius = if uri then UDim.new(0, 10) else UDim.new(0.5, 0)
		corner(b, radius)
		if uri then
			local image = Instance.new("ImageLabel")
			image.BackgroundTransparency = 1
			image.Size = UDim2.fromScale(1, 1)
			image.Image = uri
			corner(image, radius)
			image.Parent = b
		end
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = b
		local scale = Instance.new("UIScale")
		scale.Parent = b
		local c: Chip = { button = b, kind = kind, id = id, stroke = stroke, scale = scale }
		ring(c, false, false)
		b.Activated:Connect(function()
			tapped(c)
		end)
		b.Parent = into
		return c
	end

	-- A card style's chip: the plate (`LooksTab.plateFace`) with a coin or the Robux mark while
	-- it's locked.
	local function plate(
		into: Instance,
		order: number,
		style: Specs.CardStyle,
		template: Model
	): Chip
		local b = Instance.new("TextButton")
		b.Name = `card{style.Id}`
		b.Text = ""
		b.AutoButtonColor = false
		b.LayoutOrder = order
		b.Size = UDim2.fromOffset(PLATE.X, PLATE.Y)
		local radius = UDim.new(0, 6)
		LooksTab.plateFace(b, style, template)
		local lock = Looks.cardLock(style.Id)
		local mark: Frame? = nil
		local shade: Frame? = nil
		if lock then
			local dim = Instance.new("Frame") -- not yours yet: a shade darker than the rest
			shade = dim
			dim.Size = UDim2.fromScale(1, 1)
			dim.BackgroundColor3 = Color3.new(0, 0, 0)
			dim.BackgroundTransparency = 0.7
			dim.ZIndex = 4
			corner(dim, radius)
			dim.Parent = b
			local m = Instance.new("Frame")
			m.Name = "Mark"
			m.AnchorPoint = Vector2.new(0.5, 0.5)
			m.Position = UDim2.new(1, -4, 0, 4)
			m.Size = UDim2.fromOffset(MARK, MARK)
			m.BackgroundColor3 = if lock == "Cash" then COIN else Color3.fromHex("#1F2328")
			m.BorderSizePixel = 0
			m.ZIndex = 5
			corner(m, UDim.new(0.5, 0))
			local rim = Instance.new("UIStroke")
			rim.Color = if lock == "Cash" then COIN_RIM else Color3.new(1, 1, 1)
			rim.Thickness = 1.5
			rim.Parent = m
			if lock == "Cash" then -- the coin's inner ring, so it reads as a coin, not a dot
				local inner = Instance.new("Frame")
				inner.AnchorPoint = Vector2.new(0.5, 0.5)
				inner.Position = UDim2.fromScale(0.5, 0.5)
				inner.Size = UDim2.fromOffset(MARK - 8, MARK - 8)
				inner.BackgroundTransparency = 1
				inner.ZIndex = 6
				corner(inner, UDim.new(0.5, 0))
				local ring2 = Instance.new("UIStroke")
				ring2.Color = COIN_RIM
				ring2.Thickness = 1
				ring2.Transparency = 0.3
				ring2.Parent = inner
				inner.Parent = m
			else
				local r = Instance.new("TextLabel")
				r.BackgroundTransparency = 1
				r.Size = UDim2.fromScale(1, 1)
				r.Text = ROBUX
				r.TextScaled = true
				r.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
				r.TextColor3 = Color3.new(1, 1, 1)
				r.ZIndex = 6
				r.Parent = m
			end
			Instance.new("UIScale").Parent = m -- host.press pops it
			m.Parent = b
			mark = m
		end
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = b
		local scale = Instance.new("UIScale")
		scale.Parent = b
		local c: Chip = {
			button = b,
			kind = "card",
			id = style.Id,
			stroke = stroke,
			scale = scale,
			mark = mark,
			dim = shade,
			locked = nil, -- `locks` reads what you own
		}
		ring(c, false, false)
		b.Activated:Connect(function()
			tapped(c)
		end)
		b.Parent = into
		return c
	end

	local function build(): boolean
		local template = Home.template()
		if built or not template then
			return built
		end
		built = true
		if page == "front" then
			local d, n = row(1), row(2) -- the door's colours over the name card's styles
			for i, door in Specs.Looks.Doors do
				table.insert(chips, chip(d, i, "door", door.Id, colour(door.Colour)))
			end
			for i, style in Specs.Cards do
				table.insert(chips, plate(n, i, style, template))
			end
			return true
		end
		local w, f = row(1), row(2)
		floors = f
		local order = 0
		local function nextOrder(): number
			order += 1
			return order
		end
		for _, paper in Specs.Looks.Papers do
			local uri = LooksView.mapOf(template, paper.Set)
			local fill = tint(chosen, "paper", paper.Id)
			table.insert(chips, chip(w, nextOrder(), "paper", paper.Id, fill, uri))
		end
		line(w, nextOrder())
		for _, paint in Specs.Looks.Paints do
			table.insert(chips, chip(w, nextOrder(), "paint", paint.Id, colour(paint.Colour)))
		end
		for _, floor in Specs.Looks.Floors do
			local uri = LooksView.mapOf(template, floor.Set)
			local fill = tint(chosen, "floor", floor.Id)
			table.insert(chips, chip(f, nextOrder(), "floor", floor.Id, fill, uri))
		end
		divider = line(f, nextOrder())
		return true
	end

	-- The chosen floor's colours as dots. When the floor changes, the old dots shrink away at the
	-- row's end (so nothing shifts) as the new ones pop in where they stood, one after another.
	local function colours(eased: boolean)
		local f = floors
		if not f or dotsOf == chosen.floor then
			return
		end
		dotsOf = chosen.floor
		for _, old in dots do
			local b = old.button
			b.LayoutOrder += 1000
			b.Active = false
			local t = TweenService:Create(old.scale, GONE, { Scale = 0 })
			t.Completed:Once(function()
				b:Destroy()
			end)
			t:Play()
		end
		table.clear(dots)
		local floor = Looks.floorOf(chosen.floor)
		local list: { Specs.Swatch } = if floor then floor.Colours else {}
		for i, each in list do
			local d = chip(f, 100 + i, "floorColour", each.Id, colour(each.Colour))
			table.insert(dots, d)
			if eased then
				d.scale.Scale = 0
				TweenService:Create(d.scale, pop(0.08 + 0.03 * i), { Scale = 1 }):Play()
			end
		end
		local bar = divider -- gone with no colours to divide off (the oak boards)
		if bar then
			local goal = { BackgroundTransparency = if #list > 0 then 0.5 else 1 }
			if eased then
				TweenService:Create(bar, QUICK, goal):Play()
			else
				bar.BackgroundTransparency = goal.BackgroundTransparency
			end
		end
	end

	-- Reads the unit's look and shows it: tints, the floor's colours, the rings.
	-- A bought style's mark pops away and its shade lifts: the chip is yours now.
	local function unmark(c: Chip)
		c.leaving = false
		local m, d = c.mark, c.dim
		if m then
			local s = m:FindFirstChildOfClass("UIScale")
			if s then
				local out = TweenService:Create(s, MARK_OUT, { Scale = 0 })
				out.Completed:Once(function(state: Enum.PlaybackState)
					if state == Enum.PlaybackState.Completed and not c.locked then
						m.Visible = false
						s.Scale = 1
					end
				end)
				out:Play()
			else
				m.Visible = false
			end
		end
		if d and d:IsA("Frame") then
			TweenService:Create(d, MARK_OUT, { BackgroundTransparency = 1 }):Play()
		end
	end

	-- Each card style's mark from what you own (`CardSale.Attribute` on you, S5-03g3d): one bought
	-- since it showed leaves where you can see it, now or as the tray next reveals.
	local function locks()
		local owned = CardSale.decode(Players.LocalPlayer:GetAttribute(CardSale.Attribute))
		for _, c in chips do
			if c.kind ~= "card" or not c.mark then
				continue
			end
			local was = c.locked
			c.locked = Looks.cardLock(c.id, owned) ~= nil
			if c.locked then
				c.leaving = false
				local m, d = c.mark, c.dim
				if m then
					m.Visible = true
				end
				if d and d:IsA("Frame") then
					d.BackgroundTransparency = 0.7
				end
			elseif was == nil then -- yours already as the tray is built: no mark at all
				local m, d = c.mark, c.dim
				if m then
					m.Visible = false
				end
				if d and d:IsA("Frame") then
					d.BackgroundTransparency = 1
				end
			elseif was then
				c.leaving = true
				if root.Visible then
					unmark(c)
				end
			end
		end
	end

	local function refresh(eased: boolean)
		local u = unit
		local read = if u
			then Looks.decode(
				u:GetAttribute(Looks.Attribute),
				u:GetAttribute(Looks.DoorAttribute),
				u:GetAttribute(Looks.CardAttribute)
			)
			else nil
		chosen = Looks.tidy(read or Looks.start())
		if not build() then
			return
		end
		colours(eased)
		locks()
		for _, list in { chips, dots } do
			for _, c in list do
				if c.kind == "paper" or c.kind == "floor" then
					local fill = tint(chosen, c.kind, c.id)
					if eased then
						TweenService:Create(c.button, TINT, { BackgroundColor3 = fill }):Play()
					else
						c.button.BackgroundColor3 = fill
					end
				end
				ring(c, current(chosen, c.kind) == c.id, eased)
			end
		end
	end

	local tab: Tab = {
		root = root,
		attach = function(u: Model?)
			for _, w in watches do
				w:Disconnect()
			end
			table.clear(watches)
			unit = u
			if u then
				if page == "front" then -- a style bought at the counter
					table.insert(
						watches,
						Players.LocalPlayer
							:GetAttributeChangedSignal(CardSale.Attribute)
							:Connect(function()
								locks()
							end)
					)
				end
				local names: { string } = if page == "front"
					then { Looks.DoorAttribute, Looks.CardAttribute }
					else { Looks.Attribute }
				for _, name in names do
					table.insert(
						watches,
						u:GetAttributeChangedSignal(name):Connect(function()
							refresh(true)
						end)
					)
				end
				refresh(false)
			end
		end,
		reveal = function()
			local n = 0
			for _, list in { chips, dots } do
				for _, c in list do
					n += 1
					c.scale.Scale = 0.6
					TweenService:Create(c.scale, pop(0.012 * n), { Scale = 1 }):Play()
					if c.leaving then
						task.delay(0.25 + 0.012 * n, function()
							if c.leaving then
								unmark(c)
							end
						end)
					end
				end
			end
		end,
	}
	return tab
end

return LooksTab
