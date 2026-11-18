--!strict
--[[
	EndView: the climb's end on your screen (L-08d, ClimbEnd), from the server's end on Workspace
	(`ClimbEnd.Attribute`), played from the same moment on every friend's screen:

	- Kept (a loss): the black comes down over the last friend's catch; the building goes quiet
	  (every sound in the world, as the catch silences the hall: the listener taken far away);
	  a beat of nothing; far off two doors come down, the second further; then "Caught" lands in
	  cold red with a low hit and the screen jolts under it; the team's photos drop in one by one,
	  each with the floor it was lost on, greyed; how far you got and how long it took; and one
	  warm button, "Again".
	- Top (an escape): the ride plays out until the cable's second knock, then light floods the
	  screen, slow and then all at once; the motor is gone under it, and the bell rings clear in
	  the white; the white settles into a warm dark and "Made it" rises in the lamp's light, the
	  photos of those who rode out in full colour.
	- Again: a press squashes the button with the keypad's beep and reads "Waiting"; each friend
	  who is in lights up warm (their photo's colour back) with a tick; the first press starts
	  "Back in 10" on every screen, and the elevator's chime sounds as it goes. Enter, Space or the
	  gamepad's A press it too.
	- Back in: once your new character stands in your lobby car (L-08e2: the results on its back
	  wall, CarResults, and its count popping in with the chime, GateClock), the black lifts off it,
	  the camera turned the way you face. Where Again leads to a fresh floor 1 instead (the test
	  hall's climb, in Studio), it lifts with the bell and "Floor 1" in the lamp's light.

	The screen is over everything (the left-behind sting, the catch); it only covers the world
	from the moment it draws something, so the ride's controls answer until then. The mouse is
	freed for the button (FreeCursor).
]]
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local DoorSound = require(ReplicatedStorage.Shared.StorageUnit.DoorSound)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local ElevatorSounds = require(ReplicatedStorage.Shared.Elevator.Sounds)
local Keypad = require(ReplicatedStorage.Shared.Elevator.Keypad)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)
local RideClock = require(script.Parent.RideClock)
local SoundPrimer = require(script.Parent.SoundPrimer)

local HEAVY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local PLAIN = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
-- The game's own colours: "Kept" in the cold red of "Left behind"; "Made it", the button and
-- whoever's in, in the car lamp's warm light (WatchView, GateClock).
local COLD = Color3.fromRGB(255, 96, 84)
local WARM = Color3.fromRGB(255, 206, 150)
local INK = Color3.fromRGB(236, 228, 218)
local MUTED = Color3.fromRGB(150, 144, 136)
local BUTTON_INK = Color3.fromRGB(34, 24, 14)
-- A lost friend's photo, dimmed and drained toward grey, and the floor it was lost on.
local LOST_PHOTO = Color3.fromRGB(118, 112, 108)
local LOST_FLOOR = Color3.fromRGB(214, 104, 92)
-- The backdrops: a wipe's cold black, faintly red above; an escape's warm dark under the lamp.
local KEPT_TOP, KEPT_BOTTOM = Color3.fromRGB(26, 14, 13), Color3.fromRGB(5, 4, 4)
local TOP_TOP, TOP_BOTTOM = Color3.fromRGB(58, 42, 26), Color3.fromRGB(10, 8, 6)
local WHITE = Color3.fromRGB(255, 250, 240)
local WHITE_INK = Color3.new(1, 1, 1)
local FAR = CFrame.new(0, 1e6, 0)
-- The recordings it borrows: a roll-up door's slam (its bang and the thump under it), the
-- keypad's beep.
local BANG_NAME: DoorSound.SoundName = "Bang"
local THUMP_NAME: DoorSound.SoundName = "Thump"
local BEEP_NAME: ElevatorSounds.SoundName = "Beep"
local BANG = DoorSound.Sounds[BANG_NAME]
local THUMP = DoorSound.Sounds[THUMP_NAME]
local BEEP = ElevatorSounds.Sounds[BEEP_NAME]
-- A photo card's width as a share of its height (the photo square, the name and floor below,
-- big enough to read on a phone).
local CARD_ASPECT = 0.66
local CARD_GAP = 14
-- A moment learned this late (seconds) is skipped, not played out of time (a late join).
local LATE = 0.4
-- As the black lifts, the camera is turned the way the server stood your new character
-- (`ClimbEnd.StoodAttribute`) on this many frames in a row, after the camera's own update: a
-- camera keeps its old look across a new character (out through the gate you rode in facing), and
-- in first person the body turns to the camera, so without this you'd come back facing away from
-- the results; one that resets a frame late still ends up turned.
local TURN_FRAMES = 4
local TURN_BIND = "EndViewTurn"
-- Back in your lobby car the turn looks at the results board's middle, not level (S5-01d, D-431):
-- the board hangs high, and a level look leaves its title under the top bar and the count. The car
-- is the lobby car whose middle is nearest where you were stood, within this many studs.
local CAR_REACH = 16

-- The middle of the results board on the lobby car nearest `at` (Boarding's board spot), or nil.
local function boardNear(at: Vector3): Vector3?
	local best: Vector3? = nil
	local bestAway = CAR_REACH
	for _, inst in CollectionService:GetTagged(Elevator.Tag) do
		if inst:IsA("Model") and inst:GetAttribute(Boarding.CarAttribute) ~= nil then
			local frame = inst:GetPivot()
			local away = (frame.Position - at).Magnitude
			if away < bestAway then
				bestAway = away
				best = frame * Vector3.new(0, Boarding.BoardHeight, Boarding.BoardDepth)
			end
		end
	end
	return best
end

type Screen = {
	backGui: ScreenGui,
	back: Frame,
	backGradient: UIGradient,
	white: Frame,
	gui: ScreenGui,
	content: Frame,
	title: TextLabel,
	titleScale: UIScale,
	titleStroke: UIStroke,
	stats: TextLabel,
	row: Frame,
	note: TextLabel,
	button: TextButton,
	buttonScale: UIScale,
	buttonStroke: UIStroke,
}

-- A friend in the end, as the server wrote it on them.
type Row = { userId: number, player: Player, fate: ClimbEnd.Fate, floor: number }

type Card = {
	userId: number,
	player: Player?,
	fate: ClimbEnd.Fate,
	holder: Frame,
	inner: Frame,
	photo: ImageLabel,
	ring: UIStroke,
	name: TextLabel,
	floor: TextLabel,
	lost: boolean,
	key: string, -- its landing's sound
	lit: number, -- 0 to 1, eased toward whether they've pressed Again
	drawnLit: number, -- the `lit` its colours were last drawn at
	wasIn: boolean,
}

local function smooth(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- A friend's photo: their avatar's head and shoulders.
local function headshot(userId: number): string
	return `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
end

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function label(
	parent: Instance,
	name: string,
	font: Font,
	colour: Color3,
	max: number
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.FontFace = font
	l.TextColor3 = colour
	l.TextScaled = true
	l.TextTransparency = 1
	l.Text = ""
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = max
	limit.MinTextSize = 10
	limit.Parent = l
	l.Parent = parent
	return l
end

local function makeScreen(parent: Instance): Screen
	-- the backdrop covers the whole screen, the notch and the home bar too
	local backGui = Instance.new("ScreenGui")
	backGui.Name = "ClimbEndBack"
	backGui.ResetOnSpawn = false
	backGui.IgnoreGuiInset = true
	backGui.ScreenInsets = Enum.ScreenInsets.None
	backGui.DisplayOrder = 50 -- over everything: the catch, the left-behind sting and its bar
	backGui.Enabled = false
	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.new(1, 1, 1)
	back.BackgroundTransparency = 1
	back.BorderSizePixel = 0
	back.Active = true -- nothing under it takes a touch
	back.Parent = backGui
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Parent = back
	local white = Instance.new("Frame")
	white.Name = "White"
	white.Size = UDim2.fromScale(1, 1)
	white.BackgroundColor3 = WHITE
	white.BackgroundTransparency = 1
	white.BorderSizePixel = 0
	white.Parent = backGui
	backGui.Parent = parent

	-- the words and the button stay in the phone's safe area
	local gui = Instance.new("ScreenGui")
	gui.Name = "ClimbEnd"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 51
	gui.Enabled = false
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.AnchorPoint = Vector2.new(0.5, 0.5)
	content.Position = UDim2.fromScale(0.5, 0.5)
	content.Size = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.Parent = gui

	-- sized by `sizeTitle`, not scaled to its box: a scaled text stops at 100 px, so the slam's
	-- scale couldn't grow it on a big screen
	local title = label(content, "Title", HEAVY, COLD, 100)
	title.TextScaled = false
	local fixed = title:FindFirstChildOfClass("UITextSizeConstraint")
	if fixed then
		fixed:Destroy()
	end
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.2)
	title.Size = UDim2.fromScale(0.9, 0.2)
	local titleScale = Instance.new("UIScale")
	titleScale.Parent = title
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.new(0, 0, 0)
	titleStroke.Thickness = 2
	titleStroke.Transparency = 1
	titleStroke.Parent = title

	local stats = label(content, "Stats", PLAIN, MUTED, 30)
	stats.AnchorPoint = Vector2.new(0.5, 0.5)
	stats.Position = UDim2.fromScale(0.5, 0.345)
	stats.Size = UDim2.fromScale(0.9, 0.065)

	local row = Instance.new("Frame")
	row.Name = "Photos"
	row.AnchorPoint = Vector2.new(0.5, 0.5)
	row.Position = UDim2.fromScale(0.5, 0.59)
	row.Size = UDim2.fromScale(0.94, 0.37)
	row.BackgroundTransparency = 1
	row.Parent = content
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, CARD_GAP)
	list.Parent = row

	local note = label(content, "Note", PLAIN, MUTED, 22)
	note.AnchorPoint = Vector2.new(0.5, 0.5)
	note.Position = UDim2.fromScale(0.5, 0.79)
	note.Size = UDim2.fromScale(0.6, 0.05)

	local button = Instance.new("TextButton")
	button.Name = "Again"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.9)
	button.Size = UDim2.fromOffset(220, 60)
	button.BackgroundColor3 = WARM
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.FontFace = BOLD
	button.TextColor3 = BUTTON_INK
	button.TextTransparency = 1
	button.TextScaled = true
	button.Text = ClimbEnd.Copy.Again
	button.Visible = false
	corner(button, UDim.new(0.5, 0))
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.24, 0)
	pad.PaddingBottom = UDim.new(0.24, 0)
	pad.Parent = button
	local buttonScale = Instance.new("UIScale")
	buttonScale.Parent = button
	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	buttonStroke.Color = WARM
	buttonStroke.Thickness = 3
	buttonStroke.Transparency = 1
	buttonStroke.Parent = button
	button.Parent = content
	gui.Parent = parent

	return {
		backGui = backGui,
		back = back,
		backGradient = gradient,
		white = white,
		gui = gui,
		content = content,
		title = title,
		titleScale = titleScale,
		titleStroke = titleStroke,
		stats = stats,
		row = row,
		note = note,
		button = button,
		buttonScale = buttonScale,
		buttonStroke = buttonStroke,
	}
end

-- A 2D sound for one recording, in SoundService: your own, heard the same wherever you are.
local function sound(name: string, id: string, effects: boolean?): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = 0
	if effects then
		-- far off in the building: the top end gone, the hall's long tail on it
		local eq = Instance.new("EqualizerSoundEffect")
		eq.HighGain = -20
		eq.MidGain = -5
		eq.LowGain = 2
		eq.Parent = s
		local reverb = Instance.new("ReverbSoundEffect")
		reverb.DecayTime = 3.5
		reverb.Density = 1
		reverb.Diffusion = 1
		reverb.DryLevel = -8
		reverb.WetLevel = -1
		reverb.Parent = s
	end
	s.Parent = SoundService
	return s
end

local EndView = {}

-- `need` asks FreeCursor for the mouse while the button is up.
function EndView.new(need: (who: string, on: boolean) -> ()): Brix.System
	local player = Players.LocalPlayer
	local screen: Screen? = nil
	local connections: { RBXScriptConnection } = {}
	local sounds: { Sound } = {}
	local bang: Sound? = nil
	local thump: Sound? = nil
	local dread: Sound? = nil
	local bell: Sound? = nil
	local tick: Sound? = nil
	local beep: Sound? = nil
	local chime: Sound? = nil
	local remote: RemoteEvent? = nil

	local at: number? = nil -- server time the climb ended
	local how: ClimbEnd.How = "Kept"
	local cards: { Card } = {}
	local built = false
	local played: { [string]: boolean } = {}
	local quiet = false
	local cursor = false
	local pressedAt: number? = nil -- os.clock() we pressed Again
	local going = false -- the next climb is being laid
	local interactive = false -- the button takes a press
	local counted = -1 -- the "Back in" number on screen
	local clearedAt: number? = nil -- os.clock() the end was cleared (the next climb is ready)
	local liftAt: number? = nil -- os.clock() the black began lifting off our new character
	local turning = 0 -- frames of the camera's turn still to make
	local turnTo: Vector3? = nil -- the way it turns, flat
	local turnAim: Vector3? = nil -- or the point it looks at (the car's board), when there is one

	local plays: { [Sound]: number } = {}
	local function play(s: Sound?, from: number, length: number, volume: number, pitch: number)
		if not s then
			return
		end
		local n = (plays[s] or 0) + 1
		plays[s] = n
		s.TimePosition = from
		s.PlaybackSpeed = pitch
		s.Volume = volume
		s:Play()
		task.delay(length / pitch, function()
			if plays[s] == n then
				s:Stop()
			end
		end)
	end

	-- Whether a moment `at` seconds into the end plays now: once, and never out of time (a moment
	-- learned of late is skipped).
	local function due(key: string, since: number, moment: number): boolean
		if played[key] or since < moment then
			return false
		end
		played[key] = true
		return since < moment + LATE
	end

	local function setCursor(on: boolean)
		if cursor ~= on then
			cursor = on
			need("End", on)
		end
	end

	-- The world's sounds off (the listener far away), and back.
	local function setQuiet(on: boolean)
		if on then
			quiet = true
			-- every frame: the catch puts the listener back as your eyes would open
			local kind = SoundService:GetListener()
			if kind ~= Enum.ListenerType.CFrame then
				SoundService:SetListener(Enum.ListenerType.CFrame, FAR)
			end
		elseif quiet then
			quiet = false
			SoundService:SetListener(Enum.ListenerType.Camera)
		end
	end

	local function clearCards()
		for _, card in cards do
			card.holder:Destroy()
		end
		table.clear(cards)
		built = false
	end

	-- Sizes each card to the row: as tall as the row, narrower when there are many friends.
	local function fit(s: Screen)
		local n = #cards
		if n == 0 then
			return
		end
		local size = s.row.AbsoluteSize
		local h = size.Y
		local w = h * CARD_ASPECT
		local room = (size.X - CARD_GAP * (n - 1)) / n
		if w > room then
			w = room
			h = w / CARD_ASPECT
		end
		for _, card in cards do
			card.holder.Size = UDim2.fromOffset(math.floor(w), math.floor(h))
		end
	end

	-- A card for each friend in the end, in the same order on every screen.
	local function build(s: Screen)
		clearCards()
		built = true
		local rows: { Row } = {}
		for _, p in Players:GetPlayers() do
			local fate, floor = ClimbEnd.decodeFate(p:GetAttribute(ClimbEnd.FateAttribute))
			if fate then
				local row: Row =
					{ userId = p.UserId, player = p, fate = fate :: ClimbEnd.Fate, floor = floor }
				table.insert(rows, row)
			end
		end
		table.sort(rows, function(a: Row, b: Row)
			return a.userId < b.userId
		end)
		for i, r in rows do
			local lost = r.fate ~= "Out"
			local holder = Instance.new("Frame")
			holder.Name = `Card{i}`
			holder.LayoutOrder = i
			holder.BackgroundTransparency = 1
			local inner = Instance.new("Frame")
			inner.Name = "Inner"
			inner.Size = UDim2.fromScale(1, 1)
			inner.BackgroundTransparency = 1
			inner.Parent = holder
			local photo = Instance.new("ImageLabel")
			photo.Name = "Photo"
			photo.Size = UDim2.fromScale(1, CARD_ASPECT)
			photo.BackgroundColor3 = Color3.fromRGB(34, 31, 28)
			photo.BackgroundTransparency = 1
			photo.ImageTransparency = 1
			photo.ScaleType = Enum.ScaleType.Crop
			photo.ImageColor3 = if lost then LOST_PHOTO else WHITE_INK
			if r.userId > 0 then
				photo.Image = headshot(r.userId)
			end
			corner(photo, UDim.new(0.08, 0))
			local ring = Instance.new("UIStroke")
			ring.Color = if lost then LOST_FLOOR else WARM
			ring.Thickness = 2
			ring.Transparency = 1
			ring.Parent = photo
			photo.Parent = inner
			-- a lost friend's photo is pinned up askew, as on a Missing board
			if lost then
				photo.Rotation = ((i * 5) % 7 - 3) * 0.9
			end
			local name = label(inner, "Name", BOLD, INK, 26)
			name.Position = UDim2.fromScale(-0.1, CARD_ASPECT + 0.035)
			name.Size = UDim2.fromScale(1.2, 0.155)
			name.Text = r.player.DisplayName
			local floor = label(inner, "Floor", PLAIN, if lost then LOST_FLOOR else WARM, 22)
			floor.Position = UDim2.fromScale(0, CARD_ASPECT + 0.2)
			floor.Size = UDim2.fromScale(1, 0.13)
			floor.Text = string.format(ClimbEnd.Copy.Floor, r.floor)
			holder.Parent = s.row
			table.insert(cards, {
				userId = r.userId,
				player = r.player,
				fate = r.fate,
				holder = holder,
				inner = inner,
				photo = photo,
				ring = ring,
				name = name,
				floor = floor,
				lost = lost,
				key = `photo{i}`,
				lit = 0,
				drawnLit = -1,
				wasIn = false,
			})
		end
		fit(s)
	end

	-- Everything off: back to playing.
	local function rest(s: Screen)
		s.backGui.Enabled = false
		s.gui.Enabled = false
		s.button.Visible = false
		s.white.BackgroundTransparency = 1
		s.back.BackgroundTransparency = 1
		s.content.Position = UDim2.fromScale(0.5, 0.5)
		clearCards()
		setQuiet(false)
		setCursor(false)
		at, clearedAt, liftAt, pressedAt = nil, nil, nil, nil
		going, interactive, counted = false, false, -1
	end

	local function press()
		local s = screen
		if not (s and at and interactive) or pressedAt or going then
			return
		end
		pressedAt = os.clock()
		local r = BEEP
		play(beep, r.Start, r.Stop - r.Start, r.Volume * 1.4, 0.9)
		local rm = remote
		if rm then
			rm:FireServer()
		end
	end

	local function onEnd()
		local s = screen
		if not s then
			return
		end
		local t, h, floor, seconds = ClimbEnd.decode(Workspace:GetAttribute(ClimbEnd.Attribute))
		if t then
			if at ~= t then
				-- a new end
				at, how = t, h :: ClimbEnd.How
				table.clear(played)
				clearCards()
				clearedAt, liftAt, pressedAt, going, counted = nil, nil, nil, false, -1
				s.title.Text = if h == "Top" then ClimbEnd.Copy.Top else ClimbEnd.Copy.Caught
				s.title.TextColor3 = if h == "Top" then WARM else COLD
				s.stats.Text =
					`{string.format(ClimbEnd.Copy.Floor, floor)}   ·   {ClimbEnd.clock(seconds)}`
				s.stats.TextColor3 = if h == "Top" then WARM else MUTED
				s.backGradient.Color = if h == "Top"
					then ColorSequence.new(TOP_TOP, TOP_BOTTOM)
					else ColorSequence.new(KEPT_TOP, KEPT_BOTTOM)
				s.button.Text = ClimbEnd.Copy.Again
				s.note.Text = ""
				-- the photos load while the end plays, so each lands whole
				local photos: { string } = {}
				for _, p in Players:GetPlayers() do
					if p.UserId > 0 then
						table.insert(photos, headshot(p.UserId))
					end
				end
				task.spawn(function()
					pcall(function()
						ContentProvider:PreloadAsync(photos)
					end)
				end)
			end
		elseif at and not clearedAt then
			-- the next climb is laid and everyone's in its lobby
			clearedAt = os.clock()
		end
	end

	-- The title's size for this screen: a sixth of its height, never past 96 px.
	local function sizeTitle(s: Screen)
		s.title.TextSize = math.floor(math.clamp(s.content.AbsoluteSize.Y * 0.17, 36, 96))
	end

	-- The button's size for this screen: big enough for a thumb, in proportion to the screen.
	local function sizeButton(s: Screen)
		local h = math.clamp(s.content.AbsoluteSize.Y * 0.13, 48, 76)
		s.button.Size = UDim2.fromOffset(math.floor(h * 3.3), math.floor(h))
	end

	local function drawEnd(s: Screen, since: number, dt: number)
		local black = ClimbEnd.black(how, since)
		local white = ClimbEnd.white(how, since)
		local covered = black > 0.001 or white > 0.001
		s.backGui.Enabled = covered
		s.back.BackgroundTransparency = 1 - black
		s.white.BackgroundTransparency = 1 - white
		local tl = ClimbEnd.timeline(how)
		s.gui.Enabled = since >= tl.TitleAt - 0.05
		if since >= ClimbEnd.cover(how) then
			setQuiet(true)
		end
		-- the sounds
		if how == "Kept" then
			-- far off in the building, two doors come down; then the hit as "Kept" lands
			local k = ClimbEnd.Kept
			local b, th = BANG, THUMP
			if due("slam1", since, k.Slams[1]) then
				play(bang, b.Start, b.Stop - b.Start, 0.7, 0.72)
				play(thump, th.Start, th.Stop - th.Start, 1.1, 0.6)
			end
			if due("slam2", since, k.Slams[2]) then
				play(bang, b.Start, b.Stop - b.Start, 0.32, 0.64)
				play(thump, th.Start, th.Stop - th.Start, 0.55, 0.55)
			end
			if due("hit", since, k.TitleAt + ClimbEnd.Land) then
				play(dread, Kept.Dread.from, Kept.Dread.length, Kept.Dread.volume * 1.2, 0.85)
			end
		elseif due("bell", since, ClimbEnd.Top.BellAt) then
			-- the bell, clear in the white
			local r = Ride.Sounds.Bell
			play(bell, r.Start, r.Stop - r.Start, r.Volume, 1)
		end
		-- the title, landing
		local shown, size = ClimbEnd.title(how, since)
		s.title.TextTransparency = 1 - shown
		s.titleStroke.Transparency = 1 - shown * 0.6
		s.titleScale.Scale = size
		s.content.Position = UDim2.new(0.5, 0, 0.5, ClimbEnd.jolt(how, since))
		-- the photos
		if not built and since >= tl.PhotosAt - 0.1 then
			build(s)
		end
		local clock = os.clock()
		local tickSound = Ride.Sounds.Tick
		for i, card in cards do
			local seen, drop = ClimbEnd.photo(how, i, since)
			local p = card.player
			local isIn = p ~= nil
				and p.Parent ~= nil
				and p:GetAttribute(ClimbEnd.InAttribute) == true
			if isIn and not card.wasIn then
				card.wasIn = true
				if p ~= player then
					-- a friend's in: a tick as their photo warms
					play(
						tick,
						tickSound.Start,
						tickSound.Stop - tickSound.Start,
						tickSound.Volume * 0.9,
						1.2
					)
				end
			end
			card.lit += ((if isIn then 1 else 0) - card.lit) * math.min(1, dt * 12)
			local lit = card.lit
			card.inner.Position = UDim2.fromOffset(0, -drop - 4 * lit)
			card.photo.ImageTransparency = 1 - seen
			card.photo.BackgroundTransparency = 1 - seen
			-- a lost friend's photo warms back to colour as they press Again
			if math.abs(lit - card.drawnLit) > 0.002 then
				card.drawnLit = lit
				card.photo.ImageColor3 = (if card.lost then LOST_PHOTO else WHITE_INK):Lerp(
					WHITE_INK,
					lit
				)
				card.ring.Color = (if card.lost then LOST_FLOOR else WARM):Lerp(WARM, lit)
				card.ring.Thickness = 2 + lit
			end
			card.ring.Transparency = 1 - seen * (0.55 + 0.45 * lit)
			card.name.TextTransparency = 1 - seen
			card.floor.TextTransparency = 1 - seen
			if due(card.key, since, ClimbEnd.photoAt(how, i)) then
				play(
					tick,
					tickSound.Start,
					tickSound.Stop - tickSound.Start,
					tickSound.Volume * 0.8,
					0.78
				)
			end
		end
		-- how far you got
		s.stats.TextTransparency = 1 - ClimbEnd.stats(how, since)
		-- the button, and the count to the next climb
		local up, below = ClimbEnd.again(how, since)
		s.button.Visible = up > 0.01
		interactive = up > 0.6 and not pressedAt and not going
		s.button.Position = UDim2.new(0.5, 0, 0.9, below)
		local startAt = Workspace:GetAttribute(ClimbEnd.StartAttribute)
		local now = Workspace:GetServerTimeNow()
		local left = if type(startAt) == "number" then startAt - now else nil
		if left and left <= 0 and not going then
			going = true
			local r = Departure.Chime
			play(chime, r.Start, r.Stop - r.Start, r.Volume, 1)
		end
		local waiting = pressedAt ~= nil or going
		s.button.Text = if going
			then ClimbEnd.Copy.Going
			elseif pressedAt then ClimbEnd.Copy.Waiting
			else ClimbEnd.Copy.Again
		-- pressed: it sinks to an outline, the lamp's light round it
		local fill = if waiting then 0.82 else 0
		s.button.BackgroundTransparency = 1 - up * (1 - fill)
		s.button.TextColor3 = if waiting then WARM else BUTTON_INK
		s.button.TextTransparency = 1 - up
		local breathe = if waiting then 0.15 else 0.35 + 0.3 * math.sin(clock * 2.6)
		s.buttonStroke.Transparency = 1 - up * (1 - breathe)
		local pa = pressedAt
		local squash = if pa then clock - pa else 1
		s.buttonScale.Scale = 1 - 0.08 * (1 - smooth(squash / 0.22)) * math.min(squash / 0.04, 1)
		local count = if left and left > 0 then ClimbEnd.countdown(left) else 0
		if count ~= counted then
			counted = count
			s.note.Text = if count > 0 then string.format(ClimbEnd.Copy.Soon, count) else ""
		end
		s.note.TextTransparency = 1 - up
		setCursor(s.button.Visible and not going)
	end

	local function drawLift(s: Screen, cleared: number)
		local clock = os.clock()
		local la = liftAt
		if not la then
			if player.Character or clock - cleared > ClimbEnd.LiftWait then
				la = clock
				liftAt = clock
				setQuiet(false)
				setCursor(false)
				-- the way the server stood us (else the way the body faces, if it stood us nowhere)
				local stood = player:GetAttribute(ClimbEnd.StoodAttribute)
				local root = player.Character
					and player.Character:FindFirstChild("HumanoidRootPart")
				local look = if typeof(stood) == "CFrame"
					then stood.LookVector
					elseif root and root:IsA("BasePart") then root.CFrame.LookVector
					else nil
				local flat = if look then look * Vector3.new(1, 0, 1) else nil
				local inLobby = Workspace:GetAttribute(ClimbEnd.LobbyAttribute) == true
				local from = if typeof(stood) == "CFrame"
					then stood.Position
					elseif root and root:IsA("BasePart") then root.Position
					else nil
				turnAim = if inLobby and from then boardNear(from) else nil
				if (flat and flat.Magnitude > 0.01) or turnAim then
					turnTo = if flat and flat.Magnitude > 0.01 then flat.Unit else nil
					turning = TURN_FRAMES
				end
				-- back in your lobby car, its count's chime is the sound; on a fresh floor 1, the bell
				if not inLobby then
					local r = Ride.Sounds.Bell
					play(bell, r.Start, r.Stop - r.Start, r.Volume * 0.7, 1)
				end
				s.title.Text = if inLobby then "" else string.format(ClimbEnd.Copy.Floor, 1)
				s.title.TextColor3 = WARM
				s.titleScale.Scale = 1
				s.button.Visible = false
				s.stats.TextTransparency = 1
				s.note.Text = ""
				s.white.BackgroundTransparency = 1
				s.content.Position = UDim2.fromScale(0.5, 0.5)
				for _, card in cards do
					card.holder.Visible = false
				end
			else
				return -- black, waiting for our character
			end
		end
		local t = clock - (la :: number)
		s.back.BackgroundTransparency = 1 - ClimbEnd.lift(t)
		local shown = ClimbEnd.floorShown(t)
		s.gui.Enabled = true
		s.title.TextTransparency = 1 - shown
		s.titleStroke.Transparency = 1 - shown * 0.6
		if t > ClimbEnd.FloorHold + 0.7 and t > ClimbEnd.LiftIn then
			rest(s)
		end
	end

	local function step(_: any, dt: number)
		local s = screen
		if not (s and at) then
			return
		end
		if quiet then
			setQuiet(true) -- held: the catch's wake puts the listener back
		end
		local cleared = clearedAt
		if cleared then
			drawLift(s, cleared)
			return
		end
		drawEnd(s, RideClock(at :: number), dt)
	end

	local function onInput(input: InputObject, processed: boolean)
		if processed then
			return
		end
		local key = input.KeyCode
		if
			key == Enum.KeyCode.Return
			or key == Enum.KeyCode.Space
			or key == Enum.KeyCode.ButtonA
		then
			press()
		end
	end

	return {
		name = "EndView",
		start = function(_: any, _context: Brix.Context)
			local s = makeScreen(player:WaitForChild("PlayerGui"))
			screen = s
			sizeButton(s)
			sizeTitle(s)
			table.insert(connections, s.button.Activated:Connect(press))
			table.insert(
				connections,
				s.content:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					sizeButton(s)
					sizeTitle(s)
					fit(s)
				end)
			)
			table.insert(connections, UserInputService.InputBegan:Connect(onInput))
			local b, th = BANG, THUMP
			bang = sound("EndSlam", b.Id, true)
			thump = sound("EndThump", th.Id, true)
			dread = sound("EndHit", Kept.Dread.id)
			bell = sound("EndBell", Ride.Sounds.Bell.Id)
			tick = sound("EndTick", Ride.Sounds.Tick.Id)
			beep = sound("EndBeep", BEEP.Id)
			chime = sound("EndChime", Departure.Chime.Id)
			for _, x in { bang, thump, dread, bell, tick, beep, chime } do
				if x then
					table.insert(sounds, x)
				end
			end
			task.spawn(SoundPrimer.prime, {
				b.Id,
				th.Id,
				Kept.Dread.id,
				Ride.Sounds.Bell.Id,
				Ride.Sounds.Tick.Id,
				BEEP.Id,
				Departure.Chime.Id,
			})
			table.insert(
				connections,
				Workspace:GetAttributeChangedSignal(ClimbEnd.Attribute):Connect(onEnd)
			)
			onEnd()
			-- after the camera's own update, so the frame shows the turn
			RunService:BindToRenderStep(TURN_BIND, Enum.RenderPriority.Camera.Value + 1, function()
				if turning <= 0 then
					return
				end
				turning -= 1
				local camera = Workspace.CurrentCamera
				if not camera then
					return
				end
				local eye = camera.CFrame.Position
				local aim = turnAim
				local look = if aim and (aim - eye).Magnitude > 0.5
					then (aim - eye).Unit
					else turnTo
				if look then
					camera.CFrame = CFrame.lookAt(eye, eye + look)
				end
			end)
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Keypad.RemoteFolder, 30)
				local r = folder and folder:WaitForChild(ClimbEnd.Remote, 30)
				if r and r:IsA("RemoteEvent") then
					remote = r
				end
			end)
		end,
		step = step,
		stop = function(_: any)
			RunService:UnbindFromRenderStep(TURN_BIND)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			local s = screen
			if s then
				rest(s)
				s.backGui:Destroy()
				s.gui:Destroy()
				screen = nil
			end
			for _, x in sounds do
				x:Destroy()
			end
			table.clear(sounds)
		end,
	}
end

return EndView
