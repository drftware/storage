--!strict
--[[
	CarPanel: the host's panel in a lobby car (L-08e1b2, GDD "The lobby", D-121), as DOORS' lobby
	elevators do. The first one aboard hosts: on the car's panel they pick Open or Friends only and
	1 to 6 players, see the difficulty, and can press Go at any time. Everyone else aboard sees the
	same panel, greyed.

	- Its button hangs inside the car on the keypad's side, just behind the gate (the keypad itself
	  faces the room, out of reach from inside), and reaches the whole car, so the host can tap it
	  from wherever they stand. It shows only to those aboard: "Host" for the host, "View" for the
	  rest.
	- The panel slides in right of centre, clear of the jump button, as the keypad's pad does
	  (KeypadPad). A press dips its key with a click at once and goes to the server (Boarding's
	  rules, LobbyCars); the panel draws only what the car says (its replicated choices), so every
	  screen aboard shows the same: the switch slides, the count pops, the seats fill. A press that
	  can't go (not the host, already 6) barely moves, with a dull click.
	- Go: the count runs out now, the gate shuts with the climb's slam, and the panel slides away.
	  It also goes when you step out, the gate starts to shut, you die, or E or B (a pad); the ×
	  closes it on a phone.
	- Turned away at a car's gate (full, or Friends only and not the host's friend), the server
	  sets you down outside and this says why in a short headline, with a dull click.
	- On a computer the mouse goes free while it's open (FreeCursor's `need`), so you can click.
]]
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local FreeCursor = require(script.Parent.FreeCursor)
local SoundPrimer = require(script.Parent.SoundPrimer)

-- The panel's button, in the car's frame: on the keypad's side wall, at the keypad's height, just
-- behind the gate's plane (the gate stacks on the other side). It reaches the whole car.
local BUTTON_AT = CFrame.new(-5.75, 4, 1.6)
local BUTTON_REACH = 18

-- The panel's design size, in pixels before it's scaled to the screen: who hosts, the Open /
-- Friends switch, the player count between - and + over its six seats, the difficulty, Go.
local EDGE, GAP = 12, 8
local WIDTH = 228
local INNER = WIDTH - EDGE * 2
local HEAD_H, SWITCH_H, COUNT_H, LEVEL_H, GO_H = 22, 40, 48, 28, 48
local HEIGHT = EDGE * 2 + HEAD_H + SWITCH_H + COUNT_H + LEVEL_H + GO_H + GAP * 4
local STEP_W = 54 -- the - and + keys
-- It fills at most this share of the screen's height (below the top bar), scaled no smaller or
-- larger than these, and never wider than the room right of `ACROSS` less the jump button's.
local FILL = 0.92
local MIN_SCALE, MAX_SCALE = 0.55, 1.25
local ACROSS, DOWN = 0.58, 0.5
local JUMP_ROOM = 110
-- Arriving it slides this many pixels in from the right as it fades up; leaving, back out.
local SLIDE = 24
local SLIDE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- A pressed key dips to this size at once and springs back; one that can't go barely moves.
local KEY_DIP, DEAD_DIP = 0.9, 0.97
local KEY_BACK = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- The switch's light slides across; the count pops from this size as it changes.
local SWITCH_SLIDE = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local COUNT_POP = 1.3
local POP_BACK = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SEAT_FADE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- How far the panel's controls fade for those who can't change them, and how quickly.
local GREY = 0.55
local GREY_FADE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- The click of a press (Roblox's "UI Bright Click"): bright for one that goes, dull for one that
-- can't.
local CLICK_SOUND = "rbxassetid://15675059323"
local CLICK_PITCH, CLICK_VOLUME = 1.1, 0.3
local DULL_PITCH, DULL_VOLUME = 0.55, 0.3
-- Turned away: a headline a third of the way down, in with a pop, held, then out.
local TOLD_SIZE = 30
local TOLD_IN = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TOLD_HOLD = 1.6
local TOLD_OUT = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TOLD: { [string]: string } = { Full = "Car full", Friends = "Friends only" }

local STEEL = Color3.fromRGB(28, 28, 31)
local RIM = Color3.fromRGB(78, 78, 84)
local KEY = Color3.fromRGB(60, 60, 65)
local KEY_RIM = Color3.fromRGB(100, 100, 106)
local WELL = Color3.fromRGB(16, 16, 18) -- the switch's and the count's dark wells
local INK = Color3.fromRGB(232, 226, 214) -- warm off-white, as FreeCursor's hint
local DIM_INK = Color3.fromRGB(150, 146, 138)
local LIGHT = Color3.fromRGB(88, 88, 95) -- the switch's light under the chosen side
local WARM = Elevator.Lamp.Colour -- who hosts, in the car lamp's light
local GO = Color3.fromRGB(46, 150, 72) -- Go: the readout's green, deepened to read under ink
local GO_RIM = Elevator.ReadoutRight
local RED = Color3.fromRGB(226, 70, 56) -- the game's warning red (ButtonView)
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local HEAVY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)

local CLOSE_ACTION = "CarPanelClose"
local PRIORITY = Enum.ContextActionPriority.High.Value

type Entry = {
	model: Model,
	prompt: ProximityPrompt,
	at: Attachment,
	conns: { RBXScriptConnection },
}

-- The car as its replicated values say, for this player.
type Seen = {
	group: { number },
	friends: boolean,
	players: number,
	departs: number?,
	host: boolean, -- this player hosts
	aboard: boolean, -- this player is in the group
}

type Key = {
	button: TextButton,
	scale: UIScale,
	tweens: { Tween },
	solid: boolean, -- it has a face of its own (the switch's sides and × are see-through)
}

type Ui = {
	screen: ScreenGui,
	panel: CanvasGroup,
	scale: UIScale,
	body: Frame,
	hostLine: TextLabel,
	close: Key,
	open: Key,
	friends: Key,
	light: Frame,
	minus: Key,
	plus: Key,
	count: TextLabel,
	countScale: UIScale,
	seats: { Frame },
	level: TextLabel,
	go: Key,
	told: TextLabel,
	toldStroke: UIStroke,
	toldScale: UIScale,
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function rim(parent: Instance, colour: Color3, thickness: number, transparency: number)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = colour
	s.Thickness = thickness
	s.Transparency = transparency
	s.Parent = parent
end

local function key(
	parent: Instance,
	name: string,
	text: string,
	position: UDim2,
	size: UDim2,
	colour: Color3?
): Key
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = position
	b.Size = size
	b.AutoButtonColor = false
	b.BackgroundColor3 = colour or KEY
	b.FontFace = HEAVY
	b.Text = text
	b.TextSize = 24
	b.TextColor3 = INK
	b.ZIndex = 3
	corner(b, UDim.new(0, 8))
	rim(b, KEY_RIM, 1, 0.4)
	local s = Instance.new("UIScale")
	s.Parent = b
	b.Parent = parent
	return { button = b, scale = s, tweens = {}, solid = true }
end

local CarPanel = {}

-- `need` frees the mouse (FreeCursor).
function CarPanel.new(need: FreeCursor.Need): Brix.System
	local entries: { [Model]: Entry } = {}
	local connections: { RBXScriptConnection } = {}
	local ui: Ui? = nil
	local openOn: Entry? = nil
	local shown: Seen? = nil -- what the open panel shows
	local slide: Tween? = nil
	local remote: RemoteEvent? = nil
	local lastChoice = -math.huge
	local click: Sound? = nil
	local toldToken = 0
	local me = Players.LocalPlayer

	local function panelRemote(): RemoteEvent?
		if remote and remote.Parent then
			return remote
		end
		local folder = ReplicatedStorage:FindFirstChild(Boarding.RemoteFolder)
		local r = folder and folder:FindFirstChild(Boarding.RemoteName)
		remote = if r and r:IsA("RemoteEvent") then r else nil
		return remote
	end

	local function sound(pitch: number, volume: number)
		local s = click
		if s then
			s.PlaybackSpeed = pitch
			s.Volume = volume
			SoundService:PlayLocalSound(s)
		end
	end

	local function see(model: Model): Seen
		local group = Boarding.decode(model:GetAttribute(Boarding.GroupAttribute))
		local friends, players = Boarding.choices(
			model:GetAttribute(Boarding.FriendsAttribute),
			model:GetAttribute(Boarding.PlayersAttribute)
		)
		local departs = model:GetAttribute(Departure.Attribute)
		return {
			group = group,
			friends = friends,
			players = players,
			departs = if type(departs) == "number" then departs else nil,
			host = group[1] == me.UserId,
			aboard = table.find(group, me.UserId) ~= nil,
		}
	end

	local function shutting(seen: Seen): boolean
		local departs = seen.departs
		return departs ~= nil and now() >= departs
	end

	-- The size for this screen: FILL of its height, never wider than the room on its right.
	local function fit()
		local u = ui
		if not u then
			return
		end
		local size = u.screen.AbsoluteSize
		local tall = size.Y * FILL / HEIGHT
		local wide = (size.X * (1 - ACROSS) - JUMP_ROOM) / WIDTH
		u.scale.Scale = math.clamp(math.min(tall, wide), MIN_SCALE, MAX_SCALE)
	end

	local function dip(k: Key, depth: number)
		for _, t in k.tweens do
			t:Cancel()
		end
		table.clear(k.tweens)
		k.scale.Scale = depth
		local t = TweenService:Create(k.scale, KEY_BACK, { Scale = 1 })
		table.insert(k.tweens, t)
		t:Play()
	end

	-- A key that can't be pressed now fades; one that can is bright.
	local function live(k: Key, on: boolean)
		local goal: { [string]: any } = { TextTransparency = if on then 0 else GREY } -- any: a tween's goals
		if k.solid then
			goal.BackgroundTransparency = if on then 0 else GREY * 0.6
		end
		TweenService:Create(k.button, GREY_FADE, goal):Play()
	end

	-- Draws `seen` on the open panel, answering what changed since it last drew.
	local function draw(seen: Seen)
		local u = ui
		if not u then
			return
		end
		local was = shown
		shown = seen
		local host = seen.group[1]
		local hostPlayer = host and Players:GetPlayerByUserId(host)
		u.hostLine.Text = if seen.host
			then "You host"
			elseif hostPlayer then `{hostPlayer.DisplayName} hosts`
			else ""
		-- the switch's light under the chosen side
		local lightAt = UDim2.fromScale(if seen.friends then 0.5 else 0, 0)
		if was then
			TweenService:Create(u.light, SWITCH_SLIDE, { Position = lightAt }):Play()
		else
			u.light.Position = lightAt
		end
		u.open.button.TextColor3 = if seen.friends then DIM_INK else INK
		u.friends.button.TextColor3 = if seen.friends then INK else DIM_INK
		-- the count, popping as it changes, and its seats: aboard, room, and none past it
		u.count.Text = tostring(seen.players)
		if was and was.players ~= seen.players then
			u.countScale.Scale = COUNT_POP
			TweenService:Create(u.countScale, POP_BACK, { Scale = 1 }):Play()
		end
		for i, seat in u.seats do
			local aboard = i <= #seen.group
			local room = i <= seen.players
			local stroke = seat:FindFirstChildWhichIsA("UIStroke")
			local goal = {
				BackgroundTransparency = if aboard then 0 else 1,
				BackgroundColor3 = INK,
			}
			if was then
				TweenService:Create(seat, SEAT_FADE, goal):Play()
			else
				seat.BackgroundTransparency = goal.BackgroundTransparency
			end
			if stroke then
				stroke.Transparency = if room then 0.15 else 0.8
			end
		end
		-- the host's keys bright, the rest greyed; Go only while the count runs
		local mine = seen.host and not shutting(seen)
		local low, high = Boarding.playerRange({
			group = seen.group,
			departs = seen.departs,
			friends = seen.friends,
			players = seen.players,
		})
		live(u.open, mine)
		live(u.friends, mine)
		live(u.minus, mine and seen.players > low)
		live(u.plus, mine and seen.players < high)
		live(u.go, mine and seen.departs ~= nil)
	end

	local function showPrompt(entry: Entry)
		local seen = see(entry.model)
		entry.prompt.ActionText = if seen.host then "Host" else "View"
		entry.prompt.Enabled = seen.aboard and openOn ~= entry and not shutting(seen)
	end

	local function slideTo(on: boolean)
		local u = ui
		if not u then
			return
		end
		if slide then
			slide:Cancel()
		end
		local p = u.panel
		local tween = TweenService:Create(p, if on then SLIDE_IN else SLIDE_OUT, {
			GroupTransparency = if on then 0 else 1,
			Position = UDim2.new(ACROSS, if on then 0 else SLIDE, DOWN, 0),
		})
		slide = tween
		if on then
			p.Visible = true
		else
			tween.Completed:Once(function(status: Enum.PlaybackState)
				if status == Enum.PlaybackState.Completed and not openOn then
					p.Visible = false
				end
			end)
		end
		tween:Play()
	end

	local function close()
		local entry = openOn
		if not entry then
			return
		end
		openOn = nil
		shown = nil
		ContextActionService:UnbindAction(CLOSE_ACTION)
		need("CarPanel", false)
		local u = ui
		local selected = GuiService.SelectedObject
		if u and selected and selected:IsDescendantOf(u.panel) then
			GuiService.SelectedObject = nil
		end
		slideTo(false)
		showPrompt(entry)
	end

	local function closeAction(_: string, input: Enum.UserInputState, _object: InputObject)
		if input == Enum.UserInputState.Begin then
			close()
		end
		return Enum.ContextActionResult.Sink
	end

	local function open(entry: Entry)
		local u = ui
		if openOn or not u then
			return
		end
		local seen = see(entry.model)
		if not seen.aboard or shutting(seen) then
			return
		end
		openOn = entry
		showPrompt(entry)
		fit()
		draw(seen)
		need("CarPanel", true)
		ContextActionService:BindActionAtPriority(
			CLOSE_ACTION,
			closeAction,
			false,
			PRIORITY,
			Enum.KeyCode.E,
			Enum.KeyCode.ButtonB
		)
		if UserInputService:GetLastInputType().Name:find("Gamepad") then
			GuiService.SelectedObject = if seen.host then u.go.button else u.close.button
		end
		slideTo(true)
	end

	-- A press of one of the host's keys: answered at once, sent if it can go.
	local function choose(k: Key, choice: string, value: (boolean | number)?, can: boolean)
		local entry, seen = openOn, shown
		if not (entry and seen) then
			return
		end
		if not (can and seen.host and not shutting(seen)) then
			dip(k, DEAD_DIP)
			sound(DULL_PITCH, DULL_VOLUME)
			return
		end
		dip(k, KEY_DIP)
		sound(CLICK_PITCH, CLICK_VOLUME)
		local t = os.clock()
		if t - lastChoice < Boarding.ChoiceSeconds then
			return
		end
		lastChoice = t
		local r = panelRemote()
		if r then
			r:FireServer(entry.model, choice, value)
		end
	end

	-- The server turned this player away at `model`'s gate, for `why`.
	local function told(_model: unknown, why: unknown)
		local u = ui
		local text = if type(why) == "string" then TOLD[why] else nil
		if not (u and text) then
			return
		end
		sound(DULL_PITCH, DULL_VOLUME)
		toldToken += 1
		local token = toldToken
		local label = u.told
		label.Text = text
		u.toldScale.Scale = 0.8
		TweenService:Create(label, TOLD_IN, { TextTransparency = 0 }):Play()
		TweenService:Create(u.toldStroke, TOLD_IN, { Transparency = 0.45 }):Play()
		TweenService:Create(u.toldScale, TOLD_IN, { Scale = 1 }):Play()
		task.delay(TOLD_IN.Time + TOLD_HOLD, function()
			if toldToken ~= token then
				return
			end
			TweenService:Create(label, TOLD_OUT, { TextTransparency = 1 }):Play()
			TweenService:Create(u.toldStroke, TOLD_OUT, { Transparency = 1 }):Play()
		end)
	end

	-- The car's group, choices or count changed: its button, and the panel if it's open on it.
	local function changed(entry: Entry)
		showPrompt(entry)
		if openOn ~= entry then
			return
		end
		local seen = see(entry.model)
		if not seen.aboard or shutting(seen) then
			close()
			return
		end
		draw(seen)
	end

	local function remove(inst: Instance)
		local entry = entries[inst :: Model]
		if not entry then
			return
		end
		if openOn == entry then
			close()
		end
		entries[inst :: Model] = nil
		for _, c in entry.conns do
			c:Disconnect()
		end
		entry.at:Destroy()
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or entries[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		if inst:GetAttribute(Boarding.CarAttribute) == nil then
			return -- a climb's car: its keypad is KeypadPad's
		end
		local keypad = inst:FindFirstChild("Keypad")
		if not (keypad and keypad:IsA("BasePart")) then
			return
		end
		local at = Instance.new("Attachment")
		at.Name = "CarPanel"
		at.Parent = keypad
		at.WorldCFrame = inst:GetPivot() * BUTTON_AT
		local p = Instance.new("ProximityPrompt")
		p.Style = Enum.ProximityPromptStyle.Custom -- drawn by ButtonView
		p.ObjectText = ""
		p.ActionText = "View"
		p.KeyboardKeyCode = Enum.KeyCode.E
		p.GamepadKeyCode = Enum.KeyCode.ButtonX
		p.HoldDuration = 0
		p.MaxActivationDistance = BUTTON_REACH
		p.RequiresLineOfSight = false
		p.Enabled = false
		p.Parent = at
		local entry: Entry = { model = inst, prompt = p, at = at, conns = {} }
		entries[inst] = entry
		table.insert(
			entry.conns,
			p.Triggered:Connect(function()
				open(entry)
			end)
		)
		for _, name in
			{
				Boarding.GroupAttribute,
				Boarding.FriendsAttribute,
				Boarding.PlayersAttribute,
				Departure.Attribute,
			}
		do
			table.insert(
				entry.conns,
				inst:GetAttributeChangedSignal(name):Connect(function()
					changed(entry)
				end)
			)
		end
		showPrompt(entry)
	end

	local function build(): Ui
		local screen = Instance.new("ScreenGui")
		screen.Name = "CarPanel"
		screen.ResetOnSpawn = false
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local p = Instance.new("CanvasGroup")
		p.Name = "Panel"
		p.AnchorPoint = Vector2.new(0, 0.5)
		p.Position = UDim2.new(ACROSS, SLIDE, DOWN, 0)
		p.Size = UDim2.fromOffset(WIDTH, HEIGHT)
		p.BackgroundTransparency = 1
		p.GroupTransparency = 1
		p.Visible = false
		local s = Instance.new("UIScale")
		s.Parent = p

		-- the steel plate, inset so its rim isn't clipped by the group
		local body = Instance.new("Frame")
		body.Name = "Body"
		body.AnchorPoint = Vector2.new(0.5, 0.5)
		body.Position = UDim2.fromScale(0.5, 0.5)
		body.Size = UDim2.new(1, -4, 1, -4)
		body.BackgroundColor3 = STEEL
		body.SelectionGroup = true -- a gamepad's D-pad stays on the panel
		corner(body, UDim.new(0, 14))
		rim(body, RIM, 1.5, 0.2)
		body.Parent = p

		local x = EDGE - 2
		local y = EDGE - 2

		-- who hosts, and the close key
		local hostLine = Instance.new("TextLabel")
		hostLine.Name = "Host"
		hostLine.BackgroundTransparency = 1
		hostLine.Position = UDim2.fromOffset(x + 2, y)
		hostLine.Size = UDim2.fromOffset(INNER - HEAD_H - 6, HEAD_H)
		hostLine.FontFace = BOLD
		hostLine.TextSize = 17
		hostLine.TextColor3 = WARM
		hostLine.TextXAlignment = Enum.TextXAlignment.Left
		hostLine.TextTruncate = Enum.TextTruncate.AtEnd
		hostLine.Text = ""
		hostLine.Parent = body
		local closeKey = key(
			body,
			"Close",
			"×",
			UDim2.fromOffset(x + INNER - HEAD_H - 4, y - 2),
			UDim2.fromOffset(HEAD_H + 4, HEAD_H + 4)
		)
		closeKey.button.TextSize = 22
		closeKey.button.BackgroundTransparency = 1
		closeKey.solid = false
		local closeRim = closeKey.button:FindFirstChildWhichIsA("UIStroke")
		if closeRim then
			closeRim.Transparency = 1
		end
		y += HEAD_H + GAP

		-- Open or Friends only: one well, a light under the chosen side
		local switch = Instance.new("Frame")
		switch.Name = "Switch"
		switch.Position = UDim2.fromOffset(x, y)
		switch.Size = UDim2.fromOffset(INNER, SWITCH_H)
		switch.BackgroundColor3 = WELL
		corner(switch, UDim.new(0, 10))
		rim(switch, Color3.new(0, 0, 0), 1, 0.3)
		switch.Parent = body
		local light = Instance.new("Frame")
		light.Name = "Light"
		light.Size = UDim2.fromScale(0.5, 1)
		light.BackgroundColor3 = LIGHT
		light.ZIndex = 2
		corner(light, UDim.new(0, 10))
		rim(light, KEY_RIM, 1, 0.4)
		light.Parent = switch
		local openKey = key(switch, "Open", "Open", UDim2.fromScale(0, 0), UDim2.fromScale(0.5, 1))
		local friendsKey =
			key(switch, "Friends", "Friends", UDim2.fromScale(0.5, 0), UDim2.fromScale(0.5, 1))
		for _, k in { openKey, friendsKey } do
			k.button.BackgroundTransparency = 1
			k.solid = false
			k.button.TextSize = 19
			local r = k.button:FindFirstChildWhichIsA("UIStroke")
			if r then
				r:Destroy()
			end
		end
		y += SWITCH_H + GAP

		-- the player count between - and +, its six seats under it
		local minus =
			key(body, "Minus", "−", UDim2.fromOffset(x, y), UDim2.fromOffset(STEP_W, COUNT_H))
		local plus = key(
			body,
			"Plus",
			"+",
			UDim2.fromOffset(x + INNER - STEP_W, y),
			UDim2.fromOffset(STEP_W, COUNT_H)
		)
		local middle = Instance.new("Frame")
		middle.Name = "Count"
		middle.Position = UDim2.fromOffset(x + STEP_W + 6, y)
		middle.Size = UDim2.fromOffset(INNER - STEP_W * 2 - 12, COUNT_H)
		middle.BackgroundColor3 = WELL
		corner(middle, UDim.new(0, 8))
		rim(middle, Color3.new(0, 0, 0), 1, 0.3)
		middle.Parent = body
		local count = Instance.new("TextLabel")
		count.Name = "Players"
		count.BackgroundTransparency = 1
		count.AnchorPoint = Vector2.new(0.5, 0)
		count.Position = UDim2.new(0.5, 0, 0, 2)
		count.Size = UDim2.new(1, 0, 0, COUNT_H - 16)
		count.FontFace = HEAVY
		count.TextSize = 28
		count.TextColor3 = INK
		count.Text = "6"
		local countScale = Instance.new("UIScale")
		countScale.Parent = count
		count.Parent = middle
		local seats: { Frame } = {}
		local SEAT, SEAT_GAP = 9, 5
		local seatsW = SEAT * Boarding.Capacity + SEAT_GAP * (Boarding.Capacity - 1)
		for i = 1, Boarding.Capacity do
			local seat = Instance.new("Frame")
			seat.Name = `Seat{i}`
			seat.AnchorPoint = Vector2.new(0, 1)
			seat.Position = UDim2.new(0.5, -seatsW / 2 + (i - 1) * (SEAT + SEAT_GAP), 1, -6)
			seat.Size = UDim2.fromOffset(SEAT, SEAT)
			seat.BackgroundColor3 = INK
			seat.BackgroundTransparency = 1
			corner(seat, UDim.new(0.5, 0))
			rim(seat, INK, 1.5, 0.15)
			seat.Parent = middle
			seats[i] = seat
		end
		y += COUNT_H + GAP

		-- the difficulty: one, nothing to change
		local level = Instance.new("TextLabel")
		level.Name = "Difficulty"
		level.Position = UDim2.fromOffset(x, y)
		level.Size = UDim2.fromOffset(INNER, LEVEL_H)
		level.BackgroundColor3 = WELL
		level.BackgroundTransparency = 0.3
		level.FontFace = BOLD
		level.TextSize = 17
		level.TextColor3 = DIM_INK
		level.Text = Boarding.Difficulties[1]
		corner(level, UDim.new(0, 8))
		level.Parent = body
		y += LEVEL_H + GAP

		local go = key(body, "Go", "Go", UDim2.fromOffset(x, y), UDim2.fromOffset(INNER, GO_H), GO)
		go.button.TextSize = 26
		local goRim = go.button:FindFirstChildWhichIsA("UIStroke")
		if goRim then
			goRim.Color = GO_RIM
			goRim.Transparency = 0.5
		end

		p.Parent = screen

		-- turned away: the headline, over the whole screen
		local toldLabel = Instance.new("TextLabel")
		toldLabel.Name = "Told"
		toldLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		toldLabel.Position = UDim2.fromScale(0.5, 0.3)
		toldLabel.Size = UDim2.new(0.9, 0, 0, TOLD_SIZE + 12)
		toldLabel.BackgroundTransparency = 1
		toldLabel.FontFace = HEAVY
		toldLabel.TextSize = TOLD_SIZE
		toldLabel.TextColor3 = RED
		toldLabel.TextTransparency = 1
		toldLabel.Text = ""
		local toldStroke = Instance.new("UIStroke")
		toldStroke.Color = Color3.new(0, 0, 0)
		toldStroke.Thickness = 2
		toldStroke.Transparency = 1
		toldStroke.Parent = toldLabel
		local toldScale = Instance.new("UIScale")
		toldScale.Parent = toldLabel
		toldLabel.Parent = screen

		return {
			screen = screen,
			panel = p,
			scale = s,
			body = body,
			hostLine = hostLine,
			close = closeKey,
			open = openKey,
			friends = friendsKey,
			light = light,
			minus = minus,
			plus = plus,
			count = count,
			countScale = countScale,
			seats = seats,
			level = level,
			go = go,
			told = toldLabel,
			toldStroke = toldStroke,
			toldScale = toldScale,
		}
	end

	-- The keys' presses: each the host's choice, or closing the panel.
	local function wire(u: Ui)
		local function on(k: Key, press: () -> ())
			table.insert(connections, k.button.Activated:Connect(press))
		end
		on(u.close, function()
			dip(u.close, KEY_DIP)
			close()
		end)
		on(u.open, function()
			local seen = shown
			choose(u.open, "Friends", false, seen ~= nil and seen.friends)
		end)
		on(u.friends, function()
			local seen = shown
			choose(u.friends, "Friends", true, seen ~= nil and not seen.friends)
		end)
		on(u.minus, function()
			local seen = shown
			if not seen then
				return
			end
			local low = math.max(#seen.group, 1)
			choose(u.minus, "Players", seen.players - 1, seen.players > low)
		end)
		on(u.plus, function()
			local seen = shown
			if not seen then
				return
			end
			choose(u.plus, "Players", seen.players + 1, seen.players < Boarding.Capacity)
		end)
		on(u.go, function()
			local seen = shown
			choose(u.go, "Go", nil, seen ~= nil and seen.departs ~= nil)
		end)
	end

	return {
		name = "CarPanel",
		start = function(_: any, _context: Brix.Context)
			local u = build()
			u.screen.Parent = me:WaitForChild("PlayerGui")
			ui = u
			wire(u)
			local s = Instance.new("Sound")
			s.Name = "CarPanelClick"
			s.SoundId = CLICK_SOUND
			s.Parent = u.screen
			click = s
			task.spawn(SoundPrimer.prime, { CLICK_SOUND })
			table.insert(
				connections,
				u.screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
			)
			fit()
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Elevator.Tag) do
				add(inst)
			end
			-- the server's remote is made as it starts; it may not be there yet
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Boarding.RemoteFolder, 30)
				local r = folder and folder:WaitForChild(Boarding.RemoteName, 30)
				if r and r:IsA("RemoteEvent") and ui then
					remote = r
					table.insert(connections, r.OnClientEvent:Connect(told))
				end
			end)
		end,
		step = function(_: any, _dt: number)
			local entry = openOn
			if not entry then
				return
			end
			-- dying, losing the character or the gate starting to shut closes it
			local character = me.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local seen = shown
			if not humanoid or humanoid.Health <= 0 or (seen and shutting(seen)) then
				close()
			end
		end,
		stop = function(_: any)
			close()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in entries do
				remove(model)
			end
			if ui then
				ui.screen:Destroy()
				ui = nil
			end
			click, slide = nil, nil
		end,
	}
end

return CarPanel
