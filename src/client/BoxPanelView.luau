--!strict
--[[
	BoxPanelView: the job box's panel on its holder's screen (S5-03c2b1, BoxPanel, D-291). The
	moment: you open the job box and, as the lid lifts, the panel rises with it, everything you own
	dealt onto it, each kind once with how many (x2); type, or tap a rarity, and it narrows at once;
	Close, a tap outside it, or walking off, and it falls away with the lid.

	It rides the lid: the server (JobBoxes) sends the box and your finds as the lid opens; the panel
	rises over the lid's own lift on the lid's own curve (eased in and out, `JobBox.Lid.Open`), and
	when the box's Lid goes to 0, for any reason, it falls on the lid's curve (gathering speed,
	`JobBox.landing`), gone as the clunk lands. Its X and a tap outside ask the server to shut the
	box (`BoxPanel.CloseRemote`): the panel goes with the lid, never before it.

	Each card is the find as your slots draw it (ToolPicture), its rim in its rarity's colour
	(Grades.Colours), its name, and x2 for two or more. Rarest first. On a computer the mouse goes
	free while it's open (FreeCursor's `need`). Nothing steps: tweens only, made as it opens.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local FreeCursor = require(script.Parent.FreeCursor)
local Grades = require(ReplicatedStorage.Shared.Grades)
local Home = require(ReplicatedStorage.Shared.Home)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local ToolPicture = require(script.Parent.ToolPicture)
local Tools = require(ReplicatedStorage.Shared.Tools)

local BoxPanel = require(ReplicatedStorage.Shared.Home.BoxPanel)
local JobBox = Home.JobBox

-- The box's own dusty blue (D-287), deepened: the panel reads as the box's inside, calm (D-263).
local PANEL = Color3.fromRGB(29, 40, 45)
local CARD = Color3.fromRGB(43, 57, 63)
local WELL = Color3.fromRGB(19, 27, 31)
local RIM = Color3.fromRGB(106, 138, 147)
local INK = Lobby.Ink
local DARK = Color3.fromRGB(24, 22, 20)

local RISE = TweenInfo.new(JobBox.Lid.Open, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local POP = TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SETTLE = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SPRING = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local GLOW = TweenInfo.new(0.15)

-- A card on the panel: what it shows and its parts.
type Shown = { card: BoxPanel.Card, frame: Frame, pop: UIScale }
-- A chip: its rarity (nil for All), its button, its pop.
type Chip = { grade: Grades.Grade?, button: TextButton, pop: UIScale, colour: Color3 }

local function colourOf(grade: Grades.Grade): Color3
	local c = Grades.Colours[grade] or Grades.Colours.Common
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local BoxPanelView = {}

function BoxPanelView.new(need: FreeCursor.Need): Brix.System
	local connections: { RBXScriptConnection } = {}
	local watching: { RBXScriptConnection } = {} -- the open box's lid and its leaving
	local gui: ScreenGui? = nil
	local box: Model? = nil -- the box the panel is open for
	local openedAt = 0
	local generation = 0 -- each open and close; a late deal from an older one does nothing
	local shown: { Shown } = {}
	local all: { BoxPanel.Card } = {} -- every card on the panel, in its order
	local chips: { Chip } = {}
	local grade: Grades.Grade? = nil

	-- built in start
	local backdrop: TextButton
	local panel: Frame
	local search: TextBox
	local searchRim: UIStroke
	local chipRow: ScrollingFrame
	local closeButton: TextButton
	local closePop: UIScale
	local grid: ScrollingFrame
	local cells: UIGridLayout
	local message: TextLabel
	local click: Sound

	local function play(pitch: number)
		click.PlaybackSpeed = BoxPanel.Click.pitch * pitch
		click.TimePosition = 0
		click:Play()
	end

	local function spring(scale: UIScale)
		scale.Scale = BoxPanel.Pressed
		TweenService:Create(scale, SPRING, { Scale = 1 }):Play()
	end

	local function size(): (number, number, number)
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		local range = BoxPanel.HeightRange
		local width = math.floor(math.min(view.X * BoxPanel.Width, BoxPanel.WidthMax))
		local height = math.floor(math.clamp(view.Y * BoxPanel.Height, range[1], range[2]))
		return width, height, view.Y
	end

	-- Sizes everything for this screen: phone first (a Galaxy A16 is 685 by 338 points).
	local function layout()
		local width, height, screen = size()
		panel.Size = UDim2.fromOffset(width, height)
		local header = math.floor(math.clamp(height * 0.15, 30, 46))
		local pad = math.floor(header * 0.28)
		search.Position = UDim2.fromOffset(pad, pad)
		search.Size = UDim2.fromOffset(math.floor(math.min(width * 0.28, 220)), header)
		search.TextSize = math.floor(header * 0.48)
		closeButton.Size = UDim2.fromOffset(header, header)
		closeButton.Position = UDim2.new(1, -pad, 0, pad)
		closeButton.TextSize = math.floor(header * 0.5)
		local chipsAt = pad * 2 + search.Size.X.Offset
		chipRow.Position = UDim2.fromOffset(chipsAt, pad)
		chipRow.Size = UDim2.fromOffset(width - chipsAt - header - pad * 2, header)
		for _, chip in chips do
			chip.button.Size = UDim2.fromOffset(0, math.floor(header * 0.84))
			chip.button.TextSize = math.floor(header * 0.44)
		end
		local list = chipRow:FindFirstChildWhichIsA("UIListLayout")
		if list then
			list.Padding = UDim.new(0, math.floor(pad * 0.8))
		end
		local card = BoxPanel.Card
		local h = math.floor(math.clamp(screen * card.Height, card.Range[1], card.Range[2]))
		local gap = math.floor(h * card.Gap)
		cells.CellSize = UDim2.fromOffset(math.floor(h * card.Aspect), h)
		cells.CellPadding = UDim2.fromOffset(gap, gap)
		local top = header + pad * 2
		grid.Position = UDim2.fromOffset(pad, top)
		grid.Size = UDim2.fromOffset(width - pad * 2, height - top - pad)
		local gp = grid:FindFirstChildWhichIsA("UIPadding")
		if gp then
			gp.PaddingTop, gp.PaddingBottom = UDim.new(0, gap), UDim.new(0, gap)
			gp.PaddingLeft = UDim.new(0, math.floor(gap / 2))
		end
		message.TextSize = math.floor(header * 0.55)
		message.Position = UDim2.fromOffset(0, top)
		message.Size = UDim2.new(1, 0, 1, -top - pad)
	end

	local function paintChips()
		for _, chip in chips do
			local on = chip.grade == grade
			local b = chip.button
			b.BackgroundColor3 = if on then chip.colour else WELL
			b.BackgroundTransparency = if on then 0 else 0.15
			b.TextColor3 = if on then DARK else chip.colour
			local rim = b:FindFirstChildWhichIsA("UIStroke")
			if rim then
				rim.Transparency = if on then 1 else 0.45
			end
		end
	end

	-- Shows the cards the search and the chip leave, re-dealt quickly so the change reads.
	local function narrow(ripple: boolean)
		local keep = BoxPanel.shown(all, search.Text, grade)
		local wanted: { [BoxPanel.Card]: true } = {}
		for _, card in keep do
			wanted[card] = true
		end
		local n = 0
		for _, s in shown do
			local on = wanted[s.card] == true
			s.frame.Visible = on
			if on and ripple then
				n += 1
				s.pop.Scale = 0.86
				local tween = TweenService:Create(s.pop, SETTLE, { Scale = 1 })
				task.delay(math.min(n, 24) * BoxPanel.Ripple, function()
					tween:Play()
				end)
			end
		end
		grid.CanvasPosition = Vector2.zero
		message.Visible = #keep == 0
		message.Text = if #shown == 0 then BoxPanel.Words.empty else BoxPanel.Words.none
	end

	local function makeCard(card: BoxPanel.Card, order: number): Shown
		local colour = colourOf(card.grade)
		local frame = Instance.new("Frame")
		frame.Name = card.key
		frame.LayoutOrder = order
		frame.BackgroundColor3 = CARD
		frame.BorderSizePixel = 0
		corner(frame, UDim.new(0.1, 0))
		local rim = Instance.new("UIStroke")
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Color = colour
		rim.Thickness = 1.5
		rim.Transparency = 0.25
		rim.Parent = frame
		local tint = Instance.new("UIGradient") -- its rarity's colour rising faintly from the foot
		tint.Rotation = 90
		tint.Color = ColorSequence.new(CARD, CARD:Lerp(colour, 0.22))
		tint.Parent = frame
		local pop = Instance.new("UIScale")
		pop.Scale = 0
		pop.Parent = frame

		local picture = Instance.new("ViewportFrame")
		picture.Name = "Picture"
		picture.BackgroundTransparency = 1
		picture.Position = UDim2.fromScale(0.06, 0.04)
		picture.Size = UDim2.fromScale(0.88, 0.7)
		picture.Ambient = Color3.fromRGB(150, 145, 140)
		picture.LightColor = Color3.fromRGB(255, 240, 220)
		picture.LightDirection = Vector3.new(-0.4, -1, -0.6)
		picture.Parent = frame
		ToolPicture.draw(picture, card.key)

		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromScale(0.06, 0.76)
		name.Size = UDim2.fromScale(0.88, 0.17)
		name.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		name.TextScaled = true
		name.TextColor3 = INK
		name.Text = card.name
		name.Parent = frame
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 17
		cap.MinTextSize = 8
		cap.Parent = name

		local badge = BoxPanel.badge(card.count)
		if badge ~= "" then
			local b = Instance.new("TextLabel")
			b.Name = "Count"
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.fromScale(0.95, 0.04)
			b.Size = UDim2.fromScale(0.36, 0.16)
			b.BackgroundColor3 = INK
			b.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
			b.TextScaled = true
			b.TextColor3 = DARK
			b.Text = badge
			b.Parent = frame
			corner(b, UDim.new(0.5, 0))
			local bp = Instance.new("UIPadding")
			bp.PaddingTop, bp.PaddingBottom = UDim.new(0.12, 0), UDim.new(0.12, 0)
			bp.Parent = b
		end
		frame.Parent = grid
		return { card = card, frame = frame, pop = pop }
	end

	local function makeChip(chipGrade: Grades.Grade?, order: number): Chip
		local colour = if chipGrade then colourOf(chipGrade) else INK
		local b = Instance.new("TextButton")
		b.Name = chipGrade or "All"
		b.LayoutOrder = order
		b.AutomaticSize = Enum.AutomaticSize.X
		b.AutoButtonColor = false
		b.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		b.Text = if chipGrade then chipGrade else BoxPanel.Words.all
		b.Parent = chipRow
		corner(b, UDim.new(0.5, 0))
		local p = Instance.new("UIPadding")
		p.PaddingLeft, p.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
		p.Parent = b
		local rim = Instance.new("UIStroke")
		rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rim.Color = colour
		rim.Parent = b
		local pop = Instance.new("UIScale")
		pop.Parent = b
		local chip: Chip = { grade = chipGrade, button = b, pop = pop, colour = colour }
		table.insert(
			watching,
			b.Activated:Connect(function()
				-- the lit chip again goes back to All
				grade = if grade == chipGrade then nil else chipGrade
				spring(pop)
				play(if grade then 1 else 0.9)
				paintChips()
				narrow(true)
			end)
		)
		return chip
	end

	local function clear()
		for _, c in watching do
			c:Disconnect()
		end
		table.clear(watching)
		for _, s in shown do
			s.frame:Destroy()
		end
		table.clear(shown)
		table.clear(all)
		for _, chip in chips do
			chip.button:Destroy()
		end
		table.clear(chips)
	end

	-- Falls away with the lid: on the lid's curve, as far as the lid has risen.
	local function close()
		local was = box
		if not was then
			return
		end
		box = nil
		generation += 1
		local mine = generation
		need("BoxPanel", false)
		search:ReleaseFocus()
		local up = JobBox.angle(true, 0, os.clock() - openedAt)
		local fall = math.max(JobBox.landing(up), 0.12)
		local _, height = size()
		local drop = TweenInfo.new(fall, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(panel, drop, { Position = UDim2.new(0.5, 0, 1, height + 12) }):Play()
		TweenService:Create(backdrop, drop, { BackgroundTransparency = 1 }):Play()
		task.delay(fall, function()
			if generation == mine then
				panel.Visible = false
				backdrop.Visible = false
				clear()
			end
		end)
	end

	-- The server opened `model` for us with `finds` in it: rise with its lid.
	local function openFor(model: Model, finds: { [string]: number })
		if box then
			close()
		end
		clear()
		box = model
		openedAt = os.clock()
		generation += 1
		local mine = generation
		grade = nil
		search.Text = ""
		all = BoxPanel.cards(finds, Tools.Catalog :: any) -- any: its rows carry more than Row
		for i, card in all do
			table.insert(shown, makeCard(card, i))
		end
		table.insert(chips, makeChip(nil, 0))
		for i, g in BoxPanel.grades(all) do
			table.insert(chips, makeChip(g :: Grades.Grade, i)) -- the frozen module widens it to string
		end
		paintChips()
		layout()
		narrow(false)
		table.insert(
			watching,
			model:GetAttributeChangedSignal(JobBox.LidAttribute):Connect(function()
				local lid = model:GetAttribute(JobBox.LidAttribute)
				if not (type(lid) == "number" and lid > 0) and box == model then
					close()
				end
			end)
		)
		table.insert(
			watching,
			model.AncestryChanged:Connect(function()
				if not model:IsDescendantOf(Workspace) and box == model then
					close()
				end
			end)
		)
		need("BoxPanel", true)
		local _, height = size()
		panel.Position = UDim2.new(0.5, 0, 1, height + 12)
		panel.Visible = true
		backdrop.BackgroundTransparency = 1
		backdrop.Visible = true
		TweenService:Create(panel, RISE, { Position = UDim2.new(0.5, 0, 1, -8) }):Play()
		TweenService:Create(backdrop, RISE, { BackgroundTransparency = BoxPanel.Dim }):Play()
		-- dealt as it rises, left to right, the whole deal never longer than DealMost
		local every = math.min(BoxPanel.DealEvery, BoxPanel.DealMost / math.max(#shown, 1))
		for i, s in shown do
			task.delay(JobBox.Lid.Open * BoxPanel.DealFrom + (i - 1) * every, function()
				if generation == mine then
					TweenService:Create(s.pop, POP, { Scale = 1 }):Play()
				end
			end)
		end
	end

	local function askClose()
		spring(closePop)
		play(0.8)
		local folder = ReplicatedStorage:FindFirstChild(BoxPanel.RemoteFolder)
		local remote = folder and folder:FindFirstChild(BoxPanel.CloseRemote)
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer()
		end
	end

	local system = { name = "BoxPanelView" }

	function system.start(_: any)
		local g = Instance.new("ScreenGui")
		g.Name = "JobBoxPanel"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.DisplayOrder = 18
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui = g

		click = Instance.new("Sound")
		click.SoundId = BoxPanel.Click.id
		click.Volume = BoxPanel.Click.volume
		click.Parent = g

		backdrop = Instance.new("TextButton")
		backdrop.Name = "Backdrop"
		backdrop.AutoButtonColor = false
		backdrop.Text = ""
		backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
		backdrop.BackgroundTransparency = 1
		backdrop.Size = UDim2.fromScale(1, 1)
		backdrop.Visible = false
		backdrop.Parent = g

		panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.AnchorPoint = Vector2.new(0.5, 1)
		panel.BackgroundColor3 = PANEL
		panel.BackgroundTransparency = 0.03
		panel.Visible = false
		panel.Parent = g
		corner(panel, UDim.new(0, 14))
		local ps = Instance.new("UIStroke")
		ps.Color = RIM
		ps.Transparency = 0.35
		ps.Thickness = 1.5
		ps.Parent = panel

		search = Instance.new("TextBox")
		search.Name = "Search"
		search.BackgroundColor3 = WELL
		search.ClearTextOnFocus = false
		search.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		search.PlaceholderText = BoxPanel.Words.search
		search.PlaceholderColor3 = INK:Lerp(PANEL, 0.5)
		search.Text = ""
		search.TextColor3 = INK
		search.TextXAlignment = Enum.TextXAlignment.Left
		search.Parent = panel
		corner(search, UDim.new(0.5, 0))
		local sp = Instance.new("UIPadding")
		sp.PaddingLeft, sp.PaddingRight = UDim.new(0, 14), UDim.new(0, 10)
		sp.Parent = search
		searchRim = Instance.new("UIStroke")
		searchRim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		searchRim.Color = RIM
		searchRim.Transparency = 0.5
		searchRim.Parent = search

		chipRow = Instance.new("ScrollingFrame")
		chipRow.Name = "Chips"
		chipRow.BackgroundTransparency = 1
		chipRow.BorderSizePixel = 0
		chipRow.ScrollingDirection = Enum.ScrollingDirection.X
		chipRow.AutomaticCanvasSize = Enum.AutomaticSize.X
		chipRow.CanvasSize = UDim2.new()
		chipRow.ScrollBarThickness = 0
		chipRow.Parent = panel
		local cl = Instance.new("UIListLayout")
		cl.FillDirection = Enum.FillDirection.Horizontal
		cl.VerticalAlignment = Enum.VerticalAlignment.Center
		cl.SortOrder = Enum.SortOrder.LayoutOrder
		cl.Parent = chipRow
		local cp = Instance.new("UIPadding") -- room for a chip's pop and its rim
		cp.PaddingLeft, cp.PaddingRight = UDim.new(0, 2), UDim.new(0, 4)
		cp.Parent = chipRow

		closeButton = Instance.new("TextButton")
		closeButton.Name = "Close"
		closeButton.AnchorPoint = Vector2.new(1, 0)
		closeButton.AutoButtonColor = false
		closeButton.BackgroundColor3 = WELL
		closeButton.FontFace = Font.fromEnum(Enum.Font.BuilderSansExtraBold)
		closeButton.Text = "X"
		closeButton.TextColor3 = INK
		closeButton.Parent = panel
		corner(closeButton, UDim.new(0.5, 0))
		closePop = Instance.new("UIScale")
		closePop.Parent = closeButton

		grid = Instance.new("ScrollingFrame")
		grid.Name = "Finds"
		grid.BackgroundTransparency = 1
		grid.BorderSizePixel = 0
		grid.ScrollingDirection = Enum.ScrollingDirection.Y
		grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
		grid.CanvasSize = UDim2.new()
		grid.ScrollBarThickness = 4
		grid.ScrollBarImageColor3 = RIM
		grid.Parent = panel
		cells = Instance.new("UIGridLayout")
		cells.SortOrder = Enum.SortOrder.LayoutOrder
		cells.HorizontalAlignment = Enum.HorizontalAlignment.Left
		cells.Parent = grid
		local gp = Instance.new("UIPadding")
		gp.Parent = grid

		message = Instance.new("TextLabel")
		message.Name = "Message"
		message.BackgroundTransparency = 1
		message.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		message.TextColor3 = INK:Lerp(PANEL, 0.45)
		message.Visible = false
		message.Parent = panel

		table.insert(
			connections,
			search:GetPropertyChangedSignal("Text"):Connect(function()
				local cut = BoxPanel.search(search.Text)
				if cut ~= search.Text then
					search.Text = cut -- comes straight back here, cut
					return
				end
				if box then
					narrow(true)
				end
			end)
		)
		table.insert(
			connections,
			search.Focused:Connect(function()
				play(1.3)
				TweenService:Create(searchRim, GLOW, { Transparency = 0, Thickness = 2 }):Play()
			end)
		)
		table.insert(
			connections,
			search.FocusLost:Connect(function()
				TweenService:Create(searchRim, GLOW, { Transparency = 0.5, Thickness = 1 }):Play()
			end)
		)
		table.insert(connections, closeButton.Activated:Connect(askClose))
		table.insert(connections, backdrop.Activated:Connect(askClose))

		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(BoxPanel.RemoteFolder, 60)
			local remote = folder and folder:WaitForChild(BoxPanel.ListRemote, 60)
			if gui == g and remote and remote:IsA("RemoteEvent") then
				table.insert(
					connections,
					-- any: a remote's arguments, checked here
					remote.OnClientEvent:Connect(function(model: any, finds: any)
						local list = BoxPanel.read(finds)
						if typeof(model) == "Instance" and model:IsA("Model") and list then
							openFor(model, list)
						end
					end)
				)
			end
		end)
		local camera = Workspace.CurrentCamera
		if camera then
			table.insert(
				connections,
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					if box then
						layout()
					end
				end)
			)
		end
		g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	function system.stop(_: any)
		close()
		clear()
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		if gui then
			gui:Destroy()
			gui = nil
		end
	end

	return system
end

return BoxPanelView
