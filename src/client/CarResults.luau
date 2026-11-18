--!strict
--[[
	CarResults: how the last climb went, on the back wall of the lobby car its group came back to
	(L-08e2, GDD "The lobby": "results on the wall"). The black lifts and you're standing in the
	car with your friends, facing a board: "Caught" in the end's cold red (or "Made it" in the lamp's
	warm light), how far you got and how long it took, and the team's photos pinned in a row, each
	with the floor it was lost on, a lost friend's greyed and askew, as the end's screen showed
	them (EndView) and the Missing board will.

	Under each photo, the cash that friend's leftover coins made (S1-12, `Cash`): every figure runs
	up from nothing together once the photos are pinned, fast and then slowing; yours is the bright
	one, ticking higher with each dollar from the board and landing with a swell and a jingle. A
	friend who spent every coin shows a dim $0.

	From the car's `Boarding.ResultsAttribute` (ClimbEnd.encodeResults), which the server sets as
	the group is stood back in and clears as the car next leaves. Anyone in the lobby can see it.
	Each board is a plain client part on the car's back wall with a SurfaceGui (kept in your
	PlayerGui, shown on the part), sized to read on a phone from the back of the car; the photos
	drop onto it one after another as the black lifts.
	Nothing runs per frame: a board is built when its value changes, its tweens play once (a figure
	counting up is a tween too, its text set as its value moves).

	Then the haul (S5-01b, D-429; `Tally`): once the cash has landed, the page turns over and what
	the team carried home flips up card by card in the board's middle, cheapest first, as Lethal
	Company's end of day tallies the scrap brought in: each card its 3D picture, its name, its
	grade's colour and what it sells for at your chest, with a flap; it drops into the row along
	the board's foot as the next flips up, and the total beside it ticks higher with each. A
	Secret, the floor's big find, a find still sealed or a Legendary hits the board: a bang under
	its grade's own burst (a sealed pack's crinkle), a flash of its colour, a swell, a beat of
	quiet. The best stays face up as the total lands. A tap (or a click) near the board skips to
	the next sting card, the cards between landing at once; a long haul rattles through its cheap
	ones (`Tally.times`). One picture is drawn at a time (the stage card's), and the haul's clock
	steps only while its cards are coming up.

	Last, who carried what (S5-01c, `Tally.lines`): the total stands a moment, then the page turns
	again to it held at the top and a line for each friend sliding in from the left with a soft
	knock, the smallest haul first and filling up from the bottom, so the best comes last into
	the top place with a glint across it and its worth swelling, as Lethal Company's end of day
	reports how each player did. A line: their photo, their name, a chip for each find they
	brought home (a Secret or the floor's big find called out by name on its own chip), and what
	it's all worth. No ranking words: the order and the glint say it. A tap brings the rest in.
	Every page keeps clear of the board's foot (`CLEAR`), where a phone's round action button sits.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local BoxPanel = require(ReplicatedStorage.Shared.Home.BoxPanel)
local Boxes = require(ReplicatedStorage.Shared.Boxes)
local Brix = require(ReplicatedStorage.Brix)
local Cash = require(ReplicatedStorage.Shared.Cash)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local Coins = require(ReplicatedStorage.Shared.Coins)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Grades = require(ReplicatedStorage.Shared.Grades)
local Pack = require(ReplicatedStorage.Shared.Finds.Pack)
local Tally = require(ReplicatedStorage.Shared.Tally)
local ToolPicture = require(script.Parent.ToolPicture)

local HEAVY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local PLAIN = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
-- The end screen's colours (EndView): a wipe's cold red, the lamp's warm light, the ink.
local COLD = Color3.fromRGB(255, 96, 84)
local WARM = Color3.fromRGB(255, 206, 150)
local INK = Color3.fromRGB(236, 228, 218)
local LOST_PHOTO = Color3.fromRGB(118, 112, 108)
local LOST_FLOOR = Color3.fromRGB(214, 104, 92)
-- Cash: your own figure in the coin count's gold (CoinView), a friend's a softer gold, none dim.
local GOLD = Color3.fromRGB(255, 214, 120)
local FRIEND_GOLD = Color3.fromRGB(214, 184, 122)
local NONE = Color3.fromRGB(128, 120, 112)
local KEPT_TOP, KEPT_BOTTOM = Color3.fromRGB(34, 18, 16), Color3.fromRGB(10, 8, 8)
local TOP_TOP, TOP_BOTTOM = Color3.fromRGB(62, 46, 30), Color3.fromRGB(14, 11, 8)

-- The board on the car's back wall, in the elevator's frame (+Z into the car from its gate): just
-- above the wall's upper wooden rail (it stands proud of the wall to about 2.9 studs up and would
-- cut the board's foot), its face just proud of the wall (the inside face is at Z 12, Elevator
-- Specs' CarBack). The game is first person: from the front row (Boarding.backSpot, 5.5 studs off
-- the wall) the whole board fits the view, a little room round it.
local SIZE = Vector3.new(9.6, 5.2, 0.05)
local AT = CFrame.new(0, Boarding.BoardHeight, Boarding.BoardDepth)
-- Pixels a stud: the canvas is SIZE times this (538 by 291). The title's 76 px is 1.4 studs.
local PER_STUD = 56
-- How much the car lamp's light shades the board: a little, so it sits in the car rather than
-- glowing like a screen, but always reads.
local LIGHT = 0.25
-- A photo card: the square, then the name, the floor and the cash under it (px), and the gap
-- between cards.
local PHOTO = 66
local UNDER = 78
local CARD_GAP = 12
-- The photos drop onto the board as the black lifts: from this far above (px), the first after
-- `DROP_AT` seconds and each `DROP_EVERY` after, each over `DROP_IN`.
local DROP = 18
local DROP_AT = 0.5
local DROP_EVERY = 0.12
local DROP_IN = 0.32
-- Every page's content ends above this (px down the canvas): stood in the car facing the board,
-- a phone's round action button sits over the board's foot in the middle of the screen, so the
-- strip below this is left bare (the conductor's look at S5-01b's capture).
local CLEAR = 244
-- The haul's page (S5-01b), px on the canvas: the stage card face up left of the middle (its
-- centre, size, and the picture's height inside it), the total centred to its right, and the row
-- of landed chips under the stage (its left, width, top and the chips' height).
local STAGE_X, STAGE_Y = 186, 96
local STAGE_W, STAGE_H = 172, 180
local PICTURE_H = 100
local TOTAL_X, TOTAL_W = 412, 210
local ROW_X, ROW_W, ROW_Y, CHIP_H = 16, 506, 196, 44
-- Each friend's line (S5-01c): the haul's total held at the top (its height and the gap under
-- it), the lines across the board's width (their left and width), the widest a find's chip gets
-- in a line, the called-out find's chip at most, and the worth's width at the line's right end.
local HEADER_H, HEADER_GAP = 44, 12
local LINE_X, LINE_W = 16, 506
local LINE_CHIP = 22
local CALLOUT_W = 116
local WORTH_W = 104
local NAME_W = 124
-- The card's face, and how far its picture's backdrop and a chip lean from its grade's colour
-- towards the dark: the picture sits on a deep wash of it, a chip is the colour itself, dimmed.
local CARD = Color3.fromRGB(26, 22, 20)
local BACKDROP = 0.72
local CHIP = 0.3
local CRACKED = Color3.fromRGB(214, 104, 92)
-- Studs from the board within which your tap skips its haul ahead: anywhere in the car.
local SKIP_REACH = 14
-- Seconds between one skipped card's chip popping into the row and the next: a ripple.
local RIPPLE = 0.012

type Board = {
	value: string,
	part: Part,
	gui: SurfaceGui,
	tweens: { Tween },
	stops: { () -> () },
	skip: (() -> ())?,
}

local function gradeColour(grade: string): Color3
	local c = Grades.Colours[grade] or Grades.Colours.Common
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function corner(parent: Instance, px: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = parent
end

-- A sound on the board from one of the coins' recordings (Coins' sounds), heard from the wall.
local function sound(spec: Tally.Sound, parent: Instance): Sound
	local s = Instance.new("Sound")
	s.SoundId = spec.id
	s.Volume = spec.volume
	s.PlaybackSpeed = spec.pitch or 1
	s.PlaybackRegionsEnabled = true
	s.PlaybackRegion = NumberRange.new(spec.from, spec.from + spec.length)
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = 40
	s.Parent = parent
	return s
end

local function headshot(userId: number): string
	return `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
end

local function label(
	parent: Instance,
	name: string,
	font: Font,
	colour: Color3,
	size: number
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.FontFace = font
	l.TextColor3 = colour
	l.TextSize = size
	l.TextXAlignment = Enum.TextXAlignment.Center
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = parent
	return l
end

local CarResults = {}

function CarResults.new(): Brix.System
	local folder: Folder? = nil
	local boards: { [Model]: Board } = {}
	local watched: { [Model]: RBXScriptConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local names: { [number]: string } = {} -- UserId → display name, once known
	local me = Players.LocalPlayer.UserId

	local function remove(model: Model)
		local b = boards[model]
		if b then
			for _, stop in b.stops do
				stop()
			end
			for _, tween in b.tweens do
				tween:Cancel()
			end
			b.gui:Destroy()
			b.part:Destroy()
			boards[model] = nil
		end
	end

	-- A friend's name for their card: their display name if they're here, else Roblox's answer.
	local function nameFor(userId: number, into: TextLabel)
		local known = names[userId]
		if known then
			into.Text = known
			return
		end
		local here = Players:GetPlayerByUserId(userId)
		if here then
			names[userId] = here.DisplayName
			into.Text = here.DisplayName
			return
		end
		task.spawn(function()
			local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
			if ok and type(name) == "string" then
				names[userId] = name
				if into.Parent then
					into.Text = name
				end
			end
		end)
	end

	-- A figure counting up from $0 to `amount` once the photos are pinned (Cash), fast and then
	-- slowing. Yours ticks from the board as it rises, higher and higher, and lands with a swell, a
	-- chink and a jingle; a friend's counts in silence.
	local function count(
		part: Part,
		figure: TextLabel,
		amount: number,
		mine: boolean,
		tweens: { Tween }
	)
		local value = Instance.new("NumberValue")
		value.Name = "Counted"
		value.Parent = figure
		local swell = Instance.new("UIScale")
		swell.Parent = figure
		-- two ticks taking turns, so a fast run isn't cut short each time one starts again
		local ticks: { Sound } = if mine
			then { sound(Coins.Tick, part), sound(Coins.Tick, part) }
			else {}
		local shown, turn, last = 0, 0, -math.huge
		value.Changed:Connect(function(v: number)
			local n = math.min(math.floor(v + 0.5), amount) -- rounded: the last dollar doesn't stall
			if n == shown then
				return
			end
			shown = n
			figure.Text = `+{Cash.text(n)}`
			local now = os.clock()
			if #ticks > 0 and now - last >= Cash.TickGap then
				last = now
				turn = turn % #ticks + 1
				local tick = ticks[turn]
				tick.PlaybackSpeed = (Coins.Tick.pitch or 1) + Cash.TickRise * (n / amount)
				tick:Play()
			end
		end)
		local run = TweenService:Create(
			value,
			TweenInfo.new(
				Cash.countFor(amount),
				Enum.EasingStyle.Cubic,
				Enum.EasingDirection.Out,
				0,
				false,
				Cash.CountAt
			),
			{ Value = amount }
		)
		table.insert(tweens, run)
		run.Completed:Connect(function(state: Enum.PlaybackState)
			if state ~= Enum.PlaybackState.Completed or not figure.Parent then
				return
			end
			figure.Text = `+{Cash.text(amount)}`
			if not mine then
				return
			end
			swell.Scale = Cash.Pop
			local settle = TweenService:Create(
				swell,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			table.insert(tweens, settle)
			settle:Play()
			sound(Coins.Chink, part):Play()
			sound(Coins.Jingle, part):Play()
		end)
		run:Play()
	end

	-- A one-shot sound from the board, gone once played.
	local function once(spec: Tally.Sound, part: Part, pitch: number?)
		local s = sound(spec, part)
		if pitch then
			s.PlaybackSpeed = pitch
		end
		s.Ended:Once(function()
			s:Destroy()
		end)
		s:Play()
	end

	-- Each friend's line (S5-01c): the page turns from the haul to the team's lines, the total
	-- held at the top. A line for each friend slides in from the left with a soft knock, the
	-- cheapest haul first, filling from the bottom so the best lands last in the top place, under
	-- the total, with a glint across it and its worth swelling. Each line: their photo, their
	-- name, a chip for each find they brought home (their Secret or the big find called out on its
	-- own chip, by name), and what it's all worth.
	local function teamLines(
		part: Part,
		back: Frame,
		haul: Frame,
		cards: { Tally.Card },
		rows: { ClimbEnd.Result },
		final: number,
		board: Board
	)
		local tweens = board.tweens
		local function play(inst: Instance, info: TweenInfo, goal: { [string]: any }) -- any: tween goals
			local t = TweenService:Create(inst, info, goal)
			table.insert(tweens, t)
			t:Play()
		end
		local fates: { [number]: ClimbEnd.Fate } = {}
		local team: { number } = {}
		for _, r in rows do
			fates[r.userId] = r.fate
			table.insert(team, r.userId)
		end
		local lines = Tally.lines(cards, team)
		local n = #lines
		local h, gap = Tally.lineSize(n, CLEAR - HEADER_H - HEADER_GAP - 4)
		local block = n * h + (n - 1) * gap
		local top = math.max((CLEAR - (HEADER_H + HEADER_GAP + block)) / 2, 2)
		local firstY = top + HEADER_H + HEADER_GAP

		local page = Instance.new("Frame")
		page.Name = "Lines"
		page.BackgroundTransparency = 1
		page.Size = UDim2.fromScale(1, 1)
		page.Position = UDim2.fromScale(0, 1)
		page.Parent = back
		local header = label(page, "Total", HEAVY, GOLD, HEADER_H)
		header.AnchorPoint = Vector2.new(0.5, 0)
		header.Position = UDim2.new(0.5, 0, 0, top)
		header.Size = UDim2.fromOffset(320, HEADER_H)
		header.Text = Cash.text(final)

		-- line i (cheapest first) has its place counted from the bottom: the best's is the top
		local function place(i: number): UDim2
			return UDim2.fromOffset(LINE_X + LINE_W / 2, firstY + (n - i) * (h + gap) + h / 2)
		end
		local inset = math.max(3, math.floor(h * 0.08))
		local chipH = math.floor(h * 0.62)
		local stripX = h + 6 + NAME_W + 8
		local stripW = LINE_W - 10 - WORTH_W - 8 - stripX
		local made: { Frame } = {}
		local scales: { UIScale } = {}
		local figures: { TextLabel } = {}
		for i, line in lines do
			local mine = line.userId == me
			local fate = fates[line.userId]
			local lost = fate ~= nil and fate ~= "Out"
			local f = Instance.new("Frame")
			f.Name = `Line{i}`
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Size = UDim2.fromOffset(LINE_W, h)
			-- waiting off the board's left edge (the board clips it) until its turn
			f.Position = place(i) - UDim2.fromOffset(LINE_W + LINE_X + 8, 0)
			f.BackgroundColor3 = CARD
			f.BackgroundTransparency = 0.3
			f.BorderSizePixel = 0
			f.ZIndex = 2
			f.Visible = false
			f.Parent = page
			corner(f, math.min(10, math.floor(h * 0.25)))
			local scale = Instance.new("UIScale")
			scale.Parent = f

			local photo = Instance.new("ImageLabel")
			photo.Name = "Photo"
			photo.Position = UDim2.fromOffset(inset, inset)
			photo.Size = UDim2.fromOffset(h - inset * 2, h - inset * 2)
			photo.BackgroundColor3 = Color3.fromRGB(34, 31, 28)
			photo.BorderSizePixel = 0
			photo.ScaleType = Enum.ScaleType.Crop
			photo.ImageColor3 = if lost then LOST_PHOTO else Color3.new(1, 1, 1)
			photo.Image = headshot(line.userId)
			photo.ZIndex = 2
			photo.Parent = f
			local pc = Instance.new("UICorner")
			pc.CornerRadius = UDim.new(0.12, 0)
			pc.Parent = photo
			local ring = Instance.new("UIStroke")
			ring.Color = if lost then LOST_FLOOR else WARM
			ring.Thickness = 2
			ring.Transparency = 0.15
			ring.Parent = photo

			local name = label(f, "Name", BOLD, INK, math.min(22, math.floor(h * 0.6)))
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Position = UDim2.fromOffset(h + 6, 0)
			name.Size = UDim2.fromOffset(NAME_W, h)
			name.ZIndex = 2
			nameFor(line.userId, name)

			-- what they brought home: a chip a find, cheapest first, against their called-out one
			local right = stripX + stripW
			local callout = line.callout
			if callout then
				local colour = gradeColour(callout.grade)
				local cw = math.min(CALLOUT_W, math.floor(stripW * 0.6))
				local c = Instance.new("Frame")
				c.Name = "Callout"
				c.AnchorPoint = Vector2.new(1, 0.5)
				c.Position = UDim2.fromOffset(right, h / 2)
				c.Size = UDim2.fromOffset(cw, h - inset * 2)
				c.BackgroundColor3 = colour:Lerp(Color3.new(0, 0, 0), CHIP)
				c.BorderSizePixel = 0
				c.ZIndex = 2
				c.Parent = f
				corner(c, 6)
				local e = Instance.new("UIStroke")
				e.Color = colour
				e.Thickness = 2
				e.Parent = c
				local t = label(c, "Name", BOLD, INK, 17)
				t.Position = UDim2.fromOffset(4, 0)
				t.Size = UDim2.new(1, -8, 1, 0)
				t.TextScaled = true
				t.ZIndex = 2
				local most = Instance.new("UITextSizeConstraint")
				most.MaxTextSize = 17
				most.Parent = t
				t.Text = if callout.sealed then `{BoxPanel.Sealed} {callout.name}` else callout.name
				right -= cw + 6
			end
			local many = #line.chips
			local w, g = Tally.row(many, right - stripX)
			w = math.min(w, LINE_CHIP)
			local left = right - (many * w + math.max(many - 1, 0) * g)
			for j, card in line.chips do
				local c = Instance.new("Frame")
				c.Name = `Chip{j}`
				c.AnchorPoint = Vector2.new(0, 0.5)
				c.Position = UDim2.fromOffset(left + (j - 1) * (w + g), h / 2)
				c.Size = UDim2.fromOffset(w, chipH)
				c.BackgroundColor3 = gradeColour(card.grade):Lerp(Color3.new(0, 0, 0), CHIP)
				c.BorderSizePixel = 0
				c.ZIndex = 2
				corner(c, if w >= 10 then 4 else 2)
				c.Parent = f
			end

			-- their worth: yours bright, a friend's softer, nothing dim
			local figure = label(
				f,
				"Worth",
				if mine then HEAVY else BOLD,
				if line.worth == 0 then NONE elseif mine then GOLD else FRIEND_GOLD,
				math.min(if mine then 28 else 24, math.floor(h * 0.72))
			)
			figure.AnchorPoint = Vector2.new(1, 0.5)
			figure.TextXAlignment = Enum.TextXAlignment.Right
			figure.Position = UDim2.fromOffset(LINE_W - 10, h / 2)
			figure.Size = UDim2.fromOffset(WORTH_W, h)
			figure.ZIndex = 2
			figure.Text = Cash.text(line.worth)
			made[i], scales[i], figures[i] = f, scale, figure
		end

		-- a line slides in from the left; skipped to, it pops into its place
		local function slide(i: number, quick: boolean, k: number)
			local f = made[i]
			f.Visible = true
			if not quick then
				play(
					f,
					TweenInfo.new(Tally.LineIn, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ Position = place(i) }
				)
				return
			end
			f.Position = place(i)
			scales[i].Scale = 0
			play(
				scales[i],
				TweenInfo.new(
					0.18,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out,
					0,
					false,
					k * RIPPLE * 4
				),
				{ Scale = 1 }
			)
		end
		-- the best haul's flourish: a glint passes across its line, a gold edge comes up round it,
		-- the line and its worth swell, a bright chink over the jingle
		local function flourish()
			local f, scale, figure = made[n], scales[n], figures[n]
			local glint = Instance.new("Frame")
			glint.Name = "Glint"
			glint.Size = UDim2.fromScale(1, 1)
			glint.BackgroundColor3 = Color3.fromRGB(255, 240, 212)
			glint.BorderSizePixel = 0
			glint.ZIndex = 3
			glint.Parent = f
			corner(glint, math.min(10, math.floor(h * 0.25)))
			local band = Instance.new("UIGradient")
			band.Rotation = 16
			band.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.4, 1),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(0.6, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
			band.Offset = Vector2.new(-1, 0)
			band.Parent = glint
			play(
				band,
				TweenInfo.new(Tally.Flourish, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Offset = Vector2.new(1, 0) }
			)
			local edge = Instance.new("UIStroke")
			edge.Color = GOLD
			edge.Thickness = 2
			edge.Transparency = 1
			edge.Parent = f
			play(edge, TweenInfo.new(0.3), { Transparency = 0.2 })
			scale.Scale = 1.05
			play(
				scale,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			local pop = Instance.new("UIScale")
			pop.Scale = Cash.Pop
			pop.Parent = figure
			play(
				pop,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			once(Tally.Shine, part)
			once(Coins.Jingle, part)
		end

		local starts, flourishAt, ends = Tally.lineTimes(n)
		local began = 0
		local shown, knocked, flourished, skipping = 0, 0, false, false
		local loop: RBXScriptConnection? = nil
		local alive = true
		local function stop()
			if loop then
				loop:Disconnect()
				loop = nil
			end
			board.skip = nil
		end
		local function knock(i: number)
			once(Tally.Knock, part, (Tally.Knock.pitch or 1) + Tally.KnockRise * (i - 1))
		end
		local function step()
			local t = os.clock() - began
			local up = shown
			while up < n and starts[up + 1] <= t + 1e-6 do
				up += 1
			end
			if up > shown then
				for j = shown + 1, up do
					slide(j, skipping, j - shown)
				end
				if skipping then
					knocked = up -- the lines popped in at once share one knock
					knock(up)
				end
				shown = up
			end
			-- each sliding line's knock as it comes to rest
			while knocked < shown and t >= starts[knocked + 1] + Tally.LineIn * 0.35 do
				knocked += 1
				knock(knocked)
			end
			if not flourished and t >= flourishAt then
				flourished = true
				flourish()
			end
			if t >= ends then
				stop()
			end
		end
		-- a tap: the rest of the lines in at once, the best's flourish straight after
		local function skip()
			local t = os.clock() - began
			local to = starts[n] + Tally.LineIn
			if to <= t then
				return
			end
			began -= to - t
			skipping = true
			step()
			skipping = false
		end
		table.insert(board.stops, function()
			alive = false
			stop()
		end)

		-- the page turns again: the haul lifts off and the lines' page rises into its place
		play(
			haul,
			TweenInfo.new(Tally.Turn, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.fromScale(0, -1) }
		)
		play(
			page,
			TweenInfo.new(
				Tally.Turn,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out,
				0,
				false,
				Tally.Turn * 0.35
			),
			{ Position = UDim2.fromScale(0, 0) }
		)
		once(Tally.Flap, part, 0.8)
		task.delay(Tally.Turn * 1.3, function()
			if not alive then
				return
			end
			haul.Visible = false -- off the board: its picture stops drawing
			began = os.clock()
			loop = RunService.Heartbeat:Connect(step)
			board.skip = skip
			step()
		end)
	end

	-- The haul on the board (S5-01b): the page turns from the team to it `at` seconds in, then each
	-- card flips up on the stage, drops into the row as the next comes, and the total ticks up.
	-- Once it has landed and stood a moment, the page turns to each friend's line (S5-01c).
	local function tally(
		part: Part,
		back: Frame,
		team: Frame,
		cards: { Tally.Card },
		rows: { ClimbEnd.Result },
		at: number,
		board: Board
	)
		local n = #cards
		local starts, ends = Tally.times(cards)
		local final = 0
		for _, card in cards do
			final += card.worth
		end
		final = math.max(math.floor(final), 1)
		local tweens = board.tweens
		local function play(inst: Instance, info: TweenInfo, goal: { [string]: any }) -- any: tween goals
			local t = TweenService:Create(inst, info, goal)
			table.insert(tweens, t)
			t:Play()
		end
		back.ClipsDescendants = true

		local page = Instance.new("Frame")
		page.Name = "Haul"
		page.BackgroundTransparency = 1
		page.Size = UDim2.fromScale(1, 1)
		page.Position = UDim2.fromScale(0, 1)
		page.Parent = back

		-- the stage: the card face up, flipped open by its width
		local stage = Instance.new("Frame")
		stage.Name = "Stage"
		stage.AnchorPoint = Vector2.new(0.5, 0.5)
		stage.Position = UDim2.fromOffset(STAGE_X, STAGE_Y)
		stage.Size = UDim2.fromOffset(0, STAGE_H)
		stage.BackgroundColor3 = CARD
		stage.ClipsDescendants = true
		stage.Visible = false
		stage.ZIndex = 3
		stage.Parent = page
		corner(stage, 12)
		local edge = Instance.new("UIStroke")
		edge.Thickness = 3
		edge.Parent = stage
		local swell = Instance.new("UIScale")
		swell.Parent = stage
		local picture = Instance.new("ViewportFrame")
		picture.Name = "Picture"
		picture.Position = UDim2.fromOffset(8, 8)
		picture.Size = UDim2.new(1, -16, 0, PICTURE_H)
		picture.BorderSizePixel = 0
		picture.ZIndex = 3
		picture.Parent = stage
		local function line(
			name: string,
			font: Font,
			colour: Color3,
			size: number,
			y: number,
			h: number
		): TextLabel
			local l = label(stage, name, font, colour, size)
			l.Position = UDim2.fromOffset(6, y)
			l.Size = UDim2.new(1, -12, 0, h)
			l.TextScaled = true
			l.ZIndex = 3
			local most = Instance.new("UITextSizeConstraint")
			most.MaxTextSize = size
			most.Parent = l
			return l
		end
		local named = line("Name", BOLD, INK, 22, PICTURE_H + 12, 24)
		local graded = line("Grade", BOLD, INK, 18, PICTURE_H + 36, 18)
		local worth = line("Worth", HEAVY, GOLD, 26, PICTURE_H + 54, 28)

		-- the total, beside the stage
		local caption = label(page, "Caption", PLAIN, INK, 24)
		caption.AnchorPoint = Vector2.new(0.5, 0)
		caption.Position = UDim2.fromOffset(TOTAL_X, 50)
		caption.Size = UDim2.fromOffset(TOTAL_W, 28)
		caption.TextTransparency = 0.25
		caption.Text = Tally.Copy.Total
		local total = label(page, "Total", HEAVY, GOLD, 64)
		total.AnchorPoint = Vector2.new(0.5, 0)
		total.Position = UDim2.fromOffset(TOTAL_X, 78)
		total.Size = UDim2.fromOffset(TOTAL_W, 68)
		total.TextScaled = true
		local most = Instance.new("UITextSizeConstraint")
		most.MaxTextSize = 64
		most.Parent = total
		total.Text = Cash.text(0)
		local totalSwell = Instance.new("UIScale")
		totalSwell.Parent = total

		-- a sting card's flash of its grade's colour, over the whole page
		local flash = Instance.new("Frame")
		flash.Name = "Flash"
		flash.Size = UDim2.fromScale(1, 1)
		flash.BackgroundTransparency = 1
		flash.BorderSizePixel = 0
		flash.ZIndex = 5
		flash.Parent = page

		-- the row: every card but the last ends there as a chip of its grade's colour
		local chipW, gap = Tally.row(n - 1, ROW_W)
		local span = (n - 1) * chipW + math.max(n - 2, 0) * gap
		local rowLeft = ROW_X + (ROW_W - span) / 2
		local function slot(i: number): UDim2
			return UDim2.fromOffset(
				rowLeft + (i - 1) * (chipW + gap) + chipW / 2,
				ROW_Y + CHIP_H / 2
			)
		end
		local function chip(i: number): Frame
			local card = cards[i]
			local c = Instance.new("Frame")
			c.Name = `Chip{i}`
			c.AnchorPoint = Vector2.new(0.5, 0.5)
			c.BackgroundColor3 = gradeColour(card.grade):Lerp(Color3.new(0, 0, 0), CHIP)
			c.BorderSizePixel = 0
			c.ZIndex = 2
			corner(c, if chipW >= 14 then 6 else 2)
			if chipW >= 34 then
				local w = label(c, "Worth", BOLD, INK, 16)
				w.Size = UDim2.fromScale(1, 1)
				w.ZIndex = 2
				w.Text = Cash.text(card.worth)
			end
			c.Parent = page
			return c
		end
		-- the card on the stage turns over to its colour and drops into its place in the row
		local function fly(i: number, within: number)
			local c = chip(i)
			c.Position = UDim2.fromOffset(STAGE_X, STAGE_Y)
			c.Size = UDim2.fromOffset(STAGE_W, STAGE_H)
			play(
				c,
				TweenInfo.new(
					math.min(Tally.Drop, within * 0.8),
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),
				{ Position = slot(i), Size = UDim2.fromOffset(chipW, CHIP_H) }
			)
		end
		-- a card skipped past lands in the row at once, popping in
		local function pop(i: number, k: number)
			local c = chip(i)
			c.Position = slot(i)
			c.Size = UDim2.fromOffset(chipW, CHIP_H)
			local grow = Instance.new("UIScale")
			grow.Scale = 0
			grow.Parent = c
			play(
				grow,
				TweenInfo.new(
					0.16,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out,
					0,
					false,
					k * RIPPLE
				),
				{ Scale = 1 }
			)
		end
		local rank: { [string]: number } = {}
		for r, g in Grades.Names do
			rank[g] = r
		end
		-- the next card flips up on the stage, its picture drawn as it opens
		local function flip(i: number)
			local card = cards[i]
			local colour = gradeColour(card.grade)
			ToolPicture.draw(picture, card.key)
			picture.BackgroundColor3 = colour:Lerp(CARD, BACKDROP)
			picture.ImageTransparency = 1
			edge.Color = colour
			named.Text = if card.sealed then `{BoxPanel.Sealed} {card.name}` else card.name
			graded.Text = if card.cracked
				then `{card.grade} · {Tally.Copy.Cracked}`
				else card.grade
			graded.TextColor3 = if card.cracked then CRACKED else colour
			worth.Text = Cash.text(card.worth)
			stage.Visible = true
			stage.Size = UDim2.fromOffset(0, STAGE_H)
			swell.Scale = 1
			local open = TweenInfo.new(Tally.Land, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			play(stage, open, { Size = UDim2.fromOffset(STAGE_W, STAGE_H) })
			play(picture, TweenInfo.new(Tally.Land), { ImageTransparency = 0 })
			once(
				Tally.Flap,
				part,
				(Tally.Flap.pitch or 1) - Tally.FlapDrop * ((rank[card.grade] or 1) - 1)
			)
		end
		-- a sting card hits the board: a bang under its grade's burst, a flash, a swell
		local function sting(i: number)
			local card = cards[i]
			local colour = gradeColour(card.grade)
			once(Tally.Hit, part)
			if card.sting == "Sealed" then
				once(Pack.Crinkle, part)
			else
				local b = (Boxes.Reveal[card.grade] or Boxes.Reveal.Common).burst
				once({
					id = b.id,
					from = b.from,
					length = b.length,
					volume = b.volume,
					pitch = b.pitch,
				}, part)
			end
			flash.BackgroundColor3 = colour
			flash.BackgroundTransparency = Tally.FlashFrom
			play(
				flash,
				TweenInfo.new(Tally.Flash, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 1 }
			)
			swell.Scale = Tally.Swell
			play(
				swell,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			edge.Thickness = 7
			play(
				edge,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Thickness = 3 }
			)
		end

		-- the total's tick, two taking turns, higher as it climbs
		local ticks = { sound(Coins.Tick, part), sound(Coins.Tick, part) }
		local turn, lastTick = 0, -math.huge
		local function tick(share: number)
			local now = os.clock()
			if now - lastTick < Cash.TickGap then
				return
			end
			lastTick = now
			turn = turn % #ticks + 1
			local t = ticks[turn]
			t.PlaybackSpeed = (Coins.Tick.pitch or 1) + Cash.TickRise * share
			t:Play()
		end

		local began = 0
		local shown, stung, figure = 0, 0, 0
		local loop: RBXScriptConnection? = nil
		local alive = true
		local function finish()
			if loop then
				loop:Disconnect()
				loop = nil
			end
			board.skip = nil
			total.Text = Cash.text(final)
			totalSwell.Scale = Cash.Pop
			play(
				totalSwell,
				TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			once(Coins.Chink, part)
			once(Coins.Jingle, part)
			-- the total stands a moment, then the page turns to each friend's line (a tap: now)
			local turned = false
			local function onward()
				if turned or not alive then
					return
				end
				turned = true
				board.skip = nil
				teamLines(part, back, page, cards, rows, final, board)
			end
			board.skip = onward
			task.delay(Tally.LinesAfter, onward)
		end
		local function step()
			local t = os.clock() - began
			local up = shown
			while up < n and starts[up + 1] <= t + 1e-6 do
				up += 1
			end
			if up > shown then
				if shown > 0 then
					fly(shown, (starts[up + 1] or ends) - starts[up])
				end
				for j = shown + 1, up - 1 do
					pop(j, j - shown)
				end
				flip(up)
				shown = up
			end
			if shown > stung and t >= starts[shown] + Tally.Land then
				stung = shown
				if cards[shown].sting then
					sting(shown)
				end
			end
			local v = if t >= ends then final else Tally.total(cards, starts, ends, t)
			if v ~= figure then
				figure = v
				total.Text = Cash.text(v)
				tick(v / final)
			end
			if t >= ends then
				finish()
			end
		end
		local function skip()
			local t = os.clock() - began
			local to = Tally.skip(cards, starts, ends, t)
			if to <= t + 0.05 then
				return
			end
			began -= to - t
			once(Tally.Flap, part, 1.4)
			step()
		end
		table.insert(board.stops, function()
			alive = false
			board.skip = nil
			if loop then
				loop:Disconnect()
				loop = nil
			end
		end)
		task.delay(at, function()
			if not alive then
				return
			end
			-- the page turns: the team lifts off the board and the haul rises into its place
			play(
				team,
				TweenInfo.new(Tally.Turn, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.fromScale(0, -1) }
			)
			play(
				page,
				TweenInfo.new(
					Tally.Turn,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out,
					0,
					false,
					Tally.Turn * 0.35
				),
				{ Position = UDim2.fromScale(0, 0) }
			)
			once(Tally.Flap, part, 0.8)
			task.delay(Tally.Turn * 1.3, function()
				if not alive then
					return
				end
				began = os.clock()
				loop = RunService.Heartbeat:Connect(step)
				board.skip = skip
				step()
			end)
		end)
	end

	local function build(model: Model, results: ClimbEnd.Results, value: string)
		local f = folder
		if not f then
			return
		end
		local kept = results.how == "Kept"
		local part = Instance.new("Part")
		part.Name = "Results"
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = SIZE
		part.CFrame = model:GetPivot() * AT

		local gui = Instance.new("SurfaceGui")
		gui.Name = "Board"
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = PER_STUD
		gui.LightInfluence = LIGHT
		gui.Brightness = 1
		gui.MaxDistance = 120
		-- held in your PlayerGui and shown on the part: a ViewportFrame (the haul's picture) draws
		-- nothing on a SurfaceGui parented into the Workspace (STUDIO.md)
		gui.ResetOnSpawn = false
		gui.Adornee = part

		local back = Instance.new("Frame")
		back.Name = "Back"
		back.Size = UDim2.fromScale(1, 1)
		back.BackgroundColor3 = Color3.new(1, 1, 1)
		back.Parent = gui
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Color = if kept
			then ColorSequence.new(KEPT_TOP, KEPT_BOTTOM)
			else ColorSequence.new(TOP_TOP, TOP_BOTTOM)
		gradient.Parent = back
		corner(back, 14)
		local stroke = Instance.new("UIStroke")
		stroke.Color = if kept then LOST_FLOOR else WARM
		stroke.Transparency = 0.55
		stroke.Thickness = 3
		stroke.Parent = back

		-- the team's page: who made it, how far, the photos and their cash; the haul turns it over
		local team = Instance.new("Frame")
		team.Name = "Team"
		team.BackgroundTransparency = 1
		team.Size = UDim2.fromScale(1, 1)
		team.Parent = back

		local title = label(team, "Title", HEAVY, if kept then COLD else WARM, 66)
		title.Position = UDim2.fromOffset(0, 4)
		title.Size = UDim2.new(1, 0, 0, 64)
		title.Text = if kept then ClimbEnd.Copy.Caught else ClimbEnd.Copy.Top
		local stats = label(team, "Stats", PLAIN, INK, 28)
		stats.Position = UDim2.fromOffset(0, 68)
		stats.Size = UDim2.new(1, 0, 0, 30)
		stats.Text = `{string.format(ClimbEnd.Copy.Floor, results.floor)}   ·   {ClimbEnd.clock(
			results.seconds
		)}`

		local row = Instance.new("Frame")
		row.Name = "Row"
		row.BackgroundTransparency = 1
		row.AnchorPoint = Vector2.new(0.5, 0)
		row.Position = UDim2.new(0.5, 0, 0, 102)
		row.Size = UDim2.fromOffset(
			math.max(#results.rows, 1) * (PHOTO + CARD_GAP) - CARD_GAP,
			PHOTO + UNDER
		)
		row.Parent = team
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Padding = UDim.new(0, CARD_GAP)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = row

		local tweens: { Tween } = {}
		local board: Board =
			{ value = value, part = part, gui = gui, tweens = tweens, stops = {}, skip = nil }
		-- the page holds until the photos are pinned and the last cash has landed (with its swell)
		local settled = DROP_AT + math.max(#results.rows - 1, 0) * DROP_EVERY + DROP_IN
		for i, r in results.rows do
			local lost = r.fate ~= "Out"
			local holder = Instance.new("Frame")
			holder.Name = `Card{i}`
			holder.LayoutOrder = i
			holder.BackgroundTransparency = 1
			holder.Size = UDim2.fromOffset(PHOTO, PHOTO + UNDER)
			holder.Parent = row
			local inner = Instance.new("Frame")
			inner.Name = "Inner"
			inner.BackgroundTransparency = 1
			inner.Size = UDim2.fromScale(1, 1)
			inner.Position = UDim2.fromOffset(0, -DROP)
			inner.Parent = holder
			local photo = Instance.new("ImageLabel")
			photo.Name = "Photo"
			photo.Size = UDim2.fromOffset(PHOTO, PHOTO)
			photo.BackgroundColor3 = Color3.fromRGB(34, 31, 28)
			photo.BackgroundTransparency = 1
			photo.ImageTransparency = 1
			photo.ScaleType = Enum.ScaleType.Crop
			photo.ImageColor3 = if lost then LOST_PHOTO else Color3.new(1, 1, 1)
			photo.Image = headshot(r.userId)
			-- a lost friend's photo is pinned up askew, as on a Missing board
			photo.Rotation = if lost then ((i * 5) % 7 - 3) * 1.1 else 0
			photo.Parent = inner
			local pc = Instance.new("UICorner")
			pc.CornerRadius = UDim.new(0.08, 0)
			pc.Parent = photo
			local ring = Instance.new("UIStroke")
			ring.Color = if lost then LOST_FLOOR else WARM
			ring.Thickness = 3
			ring.Transparency = 1
			ring.Parent = photo
			local name = label(inner, "Name", BOLD, INK, 20)
			name.Position = UDim2.new(-0.15, 0, 0, PHOTO + 3)
			name.Size = UDim2.new(1.3, 0, 0, 22)
			name.TextTransparency = 1
			nameFor(r.userId, name)
			local floor = label(inner, "Floor", PLAIN, if lost then LOST_FLOOR else WARM, 20)
			floor.Position = UDim2.fromOffset(0, PHOTO + 25)
			floor.Size = UDim2.new(1, 0, 0, 22)
			floor.TextTransparency = 1
			floor.Text = string.format(ClimbEnd.Copy.Floor, r.floor)
			-- the cash their coins made: yours bright and counted aloud, a friend's softer, none dim
			local mine = r.userId == me
			local cash = math.max(math.floor(r.cash or 0), 0)
			local figure = label(
				inner,
				"Cash",
				if mine then HEAVY else BOLD,
				if cash == 0 then NONE elseif mine then GOLD else FRIEND_GOLD,
				if mine then 26 else 22
			)
			figure.Position = UDim2.new(-0.15, 0, 0, PHOTO + 48)
			figure.Size = UDim2.new(1.3, 0, 0, 26)
			figure.TextTransparency = 1
			figure.Text = if cash > 0 then `+{Cash.text(0)}` else Cash.text(0)
			if cash > 0 then
				count(part, figure, cash, mine, tweens)
				settled = math.max(settled, Cash.CountAt + Cash.countFor(cash) + 0.4)
			end
			-- dropped on one after another, pinned with a little give
			local info = TweenInfo.new(
				DROP_IN,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out,
				0,
				false,
				DROP_AT + (i - 1) * DROP_EVERY
			)
			local fade = TweenInfo.new(
				DROP_IN * 0.6,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out,
				0,
				false,
				DROP_AT + (i - 1) * DROP_EVERY
			)
			for _, t in
				{
					TweenService:Create(inner, info, { Position = UDim2.fromOffset(0, 0) }),
					TweenService:Create(
						photo,
						fade,
						{ ImageTransparency = 0, BackgroundTransparency = 0 }
					),
					TweenService:Create(ring, fade, { Transparency = 0.15 }),
					TweenService:Create(name, fade, { TextTransparency = 0 }),
					TweenService:Create(floor, fade, { TextTransparency = 0 }),
					TweenService:Create(figure, fade, { TextTransparency = 0 }),
				}
			do
				table.insert(tweens, t)
				t:Play()
			end
		end

		local cards = Tally.cards(Tally.decode(results.haul))
		if #cards > 0 then
			tally(part, back, team, cards, results.rows, settled + Tally.Read, board)
		end

		part.Parent = f
		gui.Parent = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") or part
		boards[model] = board
	end

	-- The car's results changed (or it streamed in): its board built afresh, or taken down.
	local function check(model: Model)
		local value = model:GetAttribute(Boarding.ResultsAttribute)
		local b = boards[model]
		if b and b.value == value then
			return
		end
		remove(model)
		local results = ClimbEnd.decodeResults(value)
		if results and type(value) == "string" then
			build(model, results, value)
		end
	end

	local function added(inst: Instance)
		if not inst:IsA("Model") or watched[inst] then
			return
		end
		local model = inst :: Model
		if model:GetAttribute(Boarding.CarAttribute) == nil then
			return -- a climb's car: no board
		end
		watched[model] = model
			:GetAttributeChangedSignal(Boarding.ResultsAttribute)
			:Connect(function()
				check(model)
			end)
		check(model)
	end

	local function removed(inst: Instance)
		if not inst:IsA("Model") then
			return
		end
		local model = inst :: Model
		local c = watched[model]
		if c then
			c:Disconnect()
			watched[model] = nil
		end
		remove(model)
	end

	return {
		name = "CarResults",
		start = function(_: any, _context: Brix.Context)
			local f = Instance.new("Folder")
			f.Name = "CarResults"
			f.Parent = Workspace
			folder = f
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(added)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(removed)
			)
			for _, inst in CollectionService:GetTagged(Elevator.Tag) do
				added(inst)
			end
			-- a tap or a click anywhere skips the nearest running haul ahead, for you alone
			local function tapped()
				local character = Players.LocalPlayer.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				if not (root and root:IsA("BasePart")) then
					return
				end
				local best: Board?, nearest = nil, SKIP_REACH
				for _, b in boards do
					local d = (b.part.Position - root.Position).Magnitude
					if b.skip and d < nearest then
						best, nearest = b, d
					end
				end
				local go = if best then best.skip else nil
				if go then
					go()
				end
			end
			table.insert(
				connections,
				UserInputService.TouchTap:Connect(function(_, processed: boolean)
					if not processed then
						tapped()
					end
				end)
			)
			table.insert(
				connections,
				UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
					if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
						tapped()
					end
				end)
			)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model, c in watched do
				c:Disconnect()
				remove(model)
			end
			table.clear(watched)
			if folder then
				folder:Destroy()
				folder = nil
			end
		end,
	}
end

return CarResults
