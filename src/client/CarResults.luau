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
	Each board is a plain client part on the car's back wall with a SurfaceGui, sized to read on a
	phone from the back of the car; the photos drop onto it one after another as the black lifts.
	Nothing runs per frame: a board is built when its value changes, its tweens play once (a figure
	counting up is a tween too, its text set as its value moves).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Cash = require(ReplicatedStorage.Shared.Cash)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local Coins = require(ReplicatedStorage.Shared.Coins)
local Elevator = require(ReplicatedStorage.Shared.Elevator)

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
local AT = CFrame.new(0, 5.6, 11.9)
-- Pixels a stud: the canvas is SIZE times this (538 by 291). The title's 76 px is 1.4 studs.
local PER_STUD = 56
-- How much the car lamp's light shades the board: a little, so it sits in the car rather than
-- glowing like a screen, but always reads.
local LIGHT = 0.25
-- A photo card: the square, then the name, the floor and the cash under it (px), and the gap
-- between cards.
local PHOTO = 70
local UNDER = 84
local CARD_GAP = 12
-- The photos drop onto the board as the black lifts: from this far above (px), the first after
-- `DROP_AT` seconds and each `DROP_EVERY` after, each over `DROP_IN`.
local DROP = 18
local DROP_AT = 0.5
local DROP_EVERY = 0.12
local DROP_IN = 0.32

type Board = { value: string, part: Part, tweens: { Tween } }

-- A sound on the board from one of the coins' recordings (Coins' sounds), heard from the wall.
local function sound(spec: Coins.Sound, parent: Instance): Sound
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
			for _, tween in b.tweens do
				tween:Cancel()
			end
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
		gui.Parent = part

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
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 14)
		corner.Parent = back
		local stroke = Instance.new("UIStroke")
		stroke.Color = if kept then LOST_FLOOR else WARM
		stroke.Transparency = 0.55
		stroke.Thickness = 3
		stroke.Parent = back

		local title = label(back, "Title", HEAVY, if kept then COLD else WARM, 76)
		title.Position = UDim2.fromOffset(0, 6)
		title.Size = UDim2.new(1, 0, 0, 78)
		title.Text = if kept then ClimbEnd.Copy.Caught else ClimbEnd.Copy.Top
		local stats = label(back, "Stats", PLAIN, INK, 30)
		stats.Position = UDim2.fromOffset(0, 84)
		stats.Size = UDim2.new(1, 0, 0, 32)
		stats.Text = `{string.format(ClimbEnd.Copy.Floor, results.floor)}   ·   {ClimbEnd.clock(
			results.seconds
		)}`

		local row = Instance.new("Frame")
		row.Name = "Row"
		row.BackgroundTransparency = 1
		row.AnchorPoint = Vector2.new(0.5, 0)
		row.Position = UDim2.new(0.5, 0, 0, 124)
		row.Size = UDim2.fromOffset(
			math.max(#results.rows, 1) * (PHOTO + CARD_GAP) - CARD_GAP,
			PHOTO + UNDER
		)
		row.Parent = back
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Padding = UDim.new(0, CARD_GAP)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = row

		local tweens: { Tween } = {}
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
			local name = label(inner, "Name", BOLD, INK, 22)
			name.Position = UDim2.new(-0.15, 0, 0, PHOTO + 3)
			name.Size = UDim2.new(1.3, 0, 0, 24)
			name.TextTransparency = 1
			nameFor(r.userId, name)
			local floor = label(inner, "Floor", PLAIN, if lost then LOST_FLOOR else WARM, 22)
			floor.Position = UDim2.fromOffset(0, PHOTO + 28)
			floor.Size = UDim2.new(1, 0, 0, 24)
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
				if mine then 28 else 24
			)
			figure.Position = UDim2.new(-0.15, 0, 0, PHOTO + 54)
			figure.Size = UDim2.new(1.3, 0, 0, 28)
			figure.TextTransparency = 1
			figure.Text = if cash > 0 then `+{Cash.text(0)}` else Cash.text(0)
			if cash > 0 then
				count(part, figure, cash, mine, tweens)
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

		part.Parent = f
		boards[model] = { value = value, part = part, tweens = tweens }
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
