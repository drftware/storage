--!strict
--[[
	ButtonView: every button in the world drawn one way, on this screen (L-19a, D-114).

	A button in the world is a ProximityPrompt whose `Style` is Custom (the server's `Prompts` and
	the client's own prompts set it), so Roblox draws nothing and this draws the look `WorldButton`
	describes: a round key chip, the verb beside it, the thing's name above only where it's news.
	Roblox still decides when a button shows (near enough, in sight, one per key), so this only
	answers its shown and hidden signals, its holds and its presses.

	- Shown: it swells in on its point (with the prompt's `UIOffset`, which spaces a door's buttons).
	  The chip carries the key on a keyboard, the button's picture on a pad, and nothing on a phone,
	  where a tap on it (or a click, for a clickable prompt) presses the prompt.
	- A hold fills a ring round the chip; letting go empties it. A press pops the chip with a flash.
	- A refusal (`refuse`, or the server's `Remotes.Refused` to this player alone) shakes it and
	  turns the verb into the refusal's words in red for a beat, with a dull tick.
	- Hidden: gone in a blink. Its drawing goes back in a small pool for the next button.

	Only buttons in motion are stepped.

	Hiding a button on this screen (was ButtonReach, L-16b1, D-111): `hide(prompt, reason, hidden)`
	takes it out of reach (`MaxActivationDistance` 0), so Roblox never shows it and no key presses
	it, for any number of reasons at once, and gives the server's reach back once nothing hides it.
	The server never changes a button's reach after making it but does turn buttons on and off
	(`Enabled`) as a door moves, which would undo a screen's own switch. Only a hidden button is
	remembered, in plain tables, and forgotten the moment nothing hides it or it leaves the world.
	Never key these by the button in a weak table: Roblox lets go of a weakly held Instance's entry
	while the Instance is still in the world (L-16b2, D-113), so the server's reach was lost and
	every door button stayed hidden after climbing down off the tops.
]]
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local Brix = require(ReplicatedStorage.Brix)
local WorldButton = require(ReplicatedStorage.Shared.WorldButton)

local INK = Color3.fromRGB(232, 226, 214) -- warm off-white, the game's ink (FreeCursor's hint)
local BACKING = Color3.fromRGB(12, 12, 14)
local RED = Color3.fromRGB(226, 70, 56) -- the game's warning red (PadlockView)
local NAME_INK = Color3.fromRGB(196, 192, 184) -- the name: the ink, dimmer
local CHIP_SEE = 0.3 -- the chip's fill transparency: dark enough to read the key on a lit wall
local EDGE_SEE = 0.55 -- its thin rim's
local TEXT_EDGE_SEE = 0.45 -- the dark edge round the words, so they read on any wall
local DOT = 10 -- a phone's chip: one small dot, nothing written
local DOT_SEE = 0.25
local RING_IMAGE = "rbxasset://textures/ui/Controls/RadialFill.png" -- Roblox's own prompt ring
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local HEAVY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
local MEDIUM = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
local REFUSE_SOUND = "rbxassetid://15675059323" -- Roblox's "UI Bright Click", pitched down dull
local REFUSE_PITCH = 0.55
local REFUSE_VOLUME = 0.35
local POOL = 8 -- drawings kept for reuse

-- One button's drawing: made once, reused for whichever button needs it next.
type Look = {
	gui: BillboardGui,
	shove: Frame, -- everything, moved sideways by a refusal's shake
	size: UIScale,
	chip: Frame,
	tap: TextButton, -- the chip's target, a little bigger than it: a tap or click presses the button
	chipEdge: UIStroke,
	key: TextLabel,
	pad: ImageLabel,
	dot: Frame,
	ringLeft: ImageLabel,
	ringRight: ImageLabel,
	leftCut: UIGradient,
	rightCut: UIGradient,
	verb: TextLabel,
	verbEdge: UIStroke,
	name: TextLabel,
	nameEdge: UIStroke,
	conns: { RBXScriptConnection },
}

-- A button drawn now.
type Drawn = {
	prompt: ProximityPrompt,
	look: Look,
	coming: boolean, -- swelling in (else going)
	level: number, -- 0 gone to 1 fully shown
	holdAt: number, -- os.clock a hold began, or -1
	drainFrom: number,
	drainAt: number, -- os.clock a hold was let go or fired, or -1
	poppedAt: number, -- os.clock of the last press, or -1
	refusedAt: number, -- os.clock of the last refusal, or -1
	refusal: string,
	down: boolean, -- a tap or click of ours is holding the prompt
	watch: { RBXScriptConnection },
}

local ButtonView = {}

-- The buttons drawn now, by prompt; those in motion; the drawings waiting for reuse.
local drawn: { [ProximityPrompt]: Drawn } = {}
local moving: { [Drawn]: true } = {}
local pool: { Look } = {}
-- What each drawing is drawing now (its chip's tap reads it).
local owner: { [Look]: Drawn } = {}
local holder: ScreenGui? = nil
local refuseSound: Sound? = nil

local function edge(parent: Instance, thickness: number, color: Color3): UIStroke
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = parent
	return s
end

local function round(parent: Instance)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = parent
end

local function words(name: string, font: Font, size: number): (TextLabel, UIStroke)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.FontFace = font
	l.TextSize = size
	l.TextColor3 = INK
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.AutomaticSize = Enum.AutomaticSize.X
	l.Size = UDim2.fromOffset(0, size + 4)
	l.Text = ""
	return l, edge(l, 1.5, BACKING)
end

-- One half of the hold ring: the ring's picture clipped to the left or right half, with the
-- gradient that sweeps it in.
local function ringHalf(parent: Instance, left: boolean): (ImageLabel, UIGradient)
	local clip = Instance.new("Frame")
	clip.Name = if left then "Left" else "Right"
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Size = UDim2.fromScale(0.5, 1)
	clip.Position = UDim2.fromScale(if left then 0 else 0.5, 0)
	clip.Parent = parent
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = RING_IMAGE
	image.ImageColor3 = INK
	image.Size = UDim2.fromScale(2, 1)
	image.Position = UDim2.fromScale(if left then 0 else -1, 0)
	image.Parent = clip
	local cut = Instance.new("UIGradient")
	cut.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4999, 0),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	cut.Parent = image
	return image, cut
end

local function makeLook(): Look
	local gui = Instance.new("BillboardGui")
	gui.Name = "Button"
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.ClipsDescendants = false
	gui.Size = UDim2.fromOffset(WorldButton.Width, WorldButton.Height)

	local shove = Instance.new("Frame")
	shove.Name = "Shove"
	shove.BackgroundTransparency = 1
	shove.Size = UDim2.fromScale(1, 1)
	shove.Parent = gui

	-- the chip's centre is the anchor everything hangs off, so its size can change with the screen
	local anchor = Instance.new("Frame")
	anchor.Name = "Anchor"
	anchor.BackgroundTransparency = 1
	anchor.AnchorPoint = Vector2.new(0.5, 0.5)
	anchor.Position = UDim2.new(0.5, -WorldButton.Shift, 0.5, 0)
	anchor.Size = UDim2.fromOffset(0, 0)
	anchor.Parent = shove
	local size = Instance.new("UIScale")
	size.Parent = anchor

	local tap = Instance.new("TextButton")
	tap.Name = "Tap"
	tap.Text = ""
	tap.AutoButtonColor = false
	tap.BackgroundTransparency = 1
	tap.AnchorPoint = Vector2.new(0.5, 0.5)
	tap.Selectable = false
	tap.Parent = anchor
	local chip = Instance.new("Frame")
	chip.Name = "Chip"
	chip.AnchorPoint = Vector2.new(0.5, 0.5)
	chip.BackgroundColor3 = BACKING
	chip.BorderSizePixel = 0
	chip.Parent = anchor
	round(chip)
	local chipEdge = edge(chip, 1.5, INK)
	chipEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.BackgroundTransparency = 1
	key.Size = UDim2.fromScale(1, 1)
	key.FontFace = HEAVY
	key.TextSize = WorldButton.Key
	key.TextColor3 = INK
	key.TextScaled = false
	key.Parent = chip

	local pad = Instance.new("ImageLabel")
	pad.Name = "Pad"
	pad.BackgroundTransparency = 1
	pad.AnchorPoint = Vector2.new(0.5, 0.5)
	pad.Position = UDim2.fromScale(0.5, 0.5)
	pad.Size = UDim2.fromScale(0.78, 0.78)
	pad.Parent = chip

	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(DOT, DOT)
	dot.BackgroundColor3 = INK
	dot.BorderSizePixel = 0
	dot.Parent = chip
	round(dot)

	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.BackgroundTransparency = 1
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.new(1, WorldButton.Ring, 1, WorldButton.Ring)
	ring.Parent = chip
	local ringLeft, leftCut = ringHalf(ring, true)
	local ringRight, rightCut = ringHalf(ring, false)

	local verb, verbEdge = words("Verb", BOLD, WorldButton.Verb)
	verb.AnchorPoint = Vector2.new(0, 0.5)
	verb.Parent = anchor
	local name, nameEdge = words("Name", MEDIUM, WorldButton.Name)
	name.AnchorPoint = Vector2.new(0, 1)
	name.TextColor3 = NAME_INK
	name.Parent = anchor

	local look: Look = {
		gui = gui,
		shove = shove,
		size = size,
		chip = chip,
		tap = tap,
		chipEdge = chipEdge,
		key = key,
		pad = pad,
		dot = dot,
		ringLeft = ringLeft,
		ringRight = ringRight,
		leftCut = leftCut,
		rightCut = rightCut,
		verb = verb,
		verbEdge = verbEdge,
		name = name,
		nameEdge = nameEdge,
		conns = {},
	}

	-- a tap (or a click, on a clickable prompt) on the chip presses the button it draws
	local function isPress(input: InputObject): boolean
		local t = input.UserInputType
		return t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1
	end
	table.insert(
		look.conns,
		tap.InputBegan:Connect(function(input: InputObject)
			local d = owner[look]
			if
				d
				and d.coming
				and not d.down
				and isPress(input)
				and input.UserInputState ~= Enum.UserInputState.Change
			then
				d.down = true
				d.prompt:InputHoldBegin()
			end
		end)
	)
	table.insert(
		look.conns,
		tap.InputEnded:Connect(function(input: InputObject)
			local d = owner[look]
			if d and d.down and isPress(input) then
				d.down = false
				d.prompt:InputHoldEnd()
			end
		end)
	)
	return look
end

-- Sizes the drawing for a chip `side` points across (its target `hit` more all round), and lays
-- the words off it.
local function fit(look: Look, side: number, hit: number)
	look.chip.Size = UDim2.fromOffset(side, side)
	look.tap.Size = UDim2.fromOffset(side + hit * 2, side + hit * 2)
	local right = side / 2 + WorldButton.Gap
	look.verb.Position = UDim2.fromOffset(right, 0)
	look.name.Position = UDim2.fromOffset(right, -WorldButton.Verb / 2 + 1)
end

-- A transparency `base` when fully shown, at opacity `alpha`.
local function see(base: number, alpha: number): number
	return 1 - (1 - base) * alpha
end

-- Every transparency and colour of `d` at its level, red and flash.
local function paint(d: Drawn, alpha: number, red: number, flash: number, fill: number)
	local look = d.look
	local ink = if red > 0 then INK:Lerp(RED, red) else INK
	local fillColour = if flash > 0 then BACKING:Lerp(INK, flash * 0.85) else BACKING
	look.chip.BackgroundColor3 = if red > 0 then fillColour:Lerp(RED, red * 0.35) else fillColour
	look.chip.BackgroundTransparency = see(CHIP_SEE * (1 - flash) + 0.05 * flash, alpha)
	look.chipEdge.Color = ink
	look.chipEdge.Transparency = see(EDGE_SEE * (1 - red), alpha)
	local keyInk = if flash > 0 then INK:Lerp(BACKING, flash * 0.85) else INK
	look.key.TextColor3 = keyInk
	look.key.TextTransparency = see(0, alpha)
	look.pad.ImageTransparency = see(0, alpha)
	look.dot.BackgroundColor3 = keyInk
	look.dot.BackgroundTransparency = see(DOT_SEE, alpha)
	look.verb.TextColor3 = ink
	look.verb.TextTransparency = see(0, alpha)
	look.verbEdge.Transparency = see(TEXT_EDGE_SEE, alpha)
	look.name.TextTransparency = see(0, alpha)
	look.nameEdge.Transparency = see(TEXT_EDGE_SEE, alpha)
	local ringSee = if fill > 0 then see(0, alpha) else 1
	look.ringLeft.ImageTransparency = ringSee
	look.ringRight.ImageTransparency = ringSee
	look.ringLeft.ImageColor3 = ink
	look.ringRight.ImageColor3 = ink
	if fill > 0 then
		local left, right = WorldButton.halves(fill)
		look.leftCut.Rotation = left
		look.rightCut.Rotation = right
	end
end

-- Whether `d` carries its name: only the leftmost of the buttons on one point that share it (a
-- padlocked door's "Padlocked" heads its row once).
local function named(d: Drawn): boolean
	local prompt = d.prompt
	local name = prompt.ObjectText
	if name == "" then
		return false
	end
	local parent = prompt.Parent
	local x = prompt.UIOffset.X
	for other, o in drawn do
		if
			other ~= prompt
			and o.coming
			and other.Parent == parent
			and other.ObjectText == name
			and other.UIOffset.X < x
		then
			return false
		end
	end
	return true
end

-- The buttons drawn on `prompt`'s point besides it redraw: one came or went, so which of them
-- carries the name may have changed.
local function neighbours(prompt: ProximityPrompt)
	local parent = prompt.Parent
	for other, o in drawn do
		if other ~= prompt and other.Parent == parent then
			moving[o] = true
		end
	end
end

-- The words a drawn button shows now: its refusal's for a beat, else its verb.
local function wording(d: Drawn, now: number)
	local _, refusing = WorldButton.red(if d.refusedAt >= 0 then now - d.refusedAt else -1)
	local text = if refusing then d.refusal else d.prompt.ActionText
	if d.look.verb.Text ~= text then
		d.look.verb.Text = text
	end
	local name = d.prompt.ObjectText
	if d.look.name.Text ~= name then
		d.look.name.Text = name
	end
	d.look.name.Visible = not refusing and named(d)
end

-- Draws `d` for this moment; whether it's still in motion.
local function draw(d: Drawn, now: number, dt: number): boolean
	local look = d.look
	local moved = false
	-- in or out
	local target = if d.coming then 1 else 0
	if d.level ~= target then
		local rate = 1 / (if d.coming then WorldButton.In else WorldButton.Out)
		d.level = if d.coming
			then math.min(1, d.level + dt * rate)
			else math.max(0, d.level - dt * rate)
		moved = true
	end
	local alpha, scale = WorldButton.presence(d.level, d.coming)
	-- the hold ring
	local fill = 0
	if d.holdAt >= 0 then
		fill = WorldButton.holding(now - d.holdAt, d.prompt.HoldDuration)
		scale *= WorldButton.Held
		moved = true
	elseif d.drainAt >= 0 then
		fill = WorldButton.draining(d.drainFrom, now - d.drainAt)
		if fill > 0 then
			moved = true
		else
			d.drainAt = -1
		end
	end
	-- a press
	local flash = 0
	if d.poppedAt >= 0 then
		local s, f = WorldButton.pop(now - d.poppedAt)
		scale *= s
		flash = f
		if f > 0 or s ~= 1 then
			moved = true
		else
			d.poppedAt = -1
		end
	end
	-- a refusal
	local red, shove = 0, 0
	if d.refusedAt >= 0 then
		local since = now - d.refusedAt
		red = WorldButton.red(since)
		shove = WorldButton.shake(since)
		if WorldButton.refusing(since) then
			moved = true
		else
			d.refusedAt = -1
		end
	end
	look.shove.Position = UDim2.fromOffset(shove, 0)
	look.size.Scale = scale
	wording(d, now)
	paint(d, alpha, red, flash, fill)
	return moved
end

local function startMoving(d: Drawn)
	moving[d] = true
end

local function holderGui(): ScreenGui?
	local h = holder
	if h and h.Parent then
		return h
	end
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	local g = Instance.new("ScreenGui")
	g.Name = "WorldButtons"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.Parent = pg
	holder = g
	return g
end

-- What the chip carries for `input`: the key, the pad's picture, or (a phone) a dot.
local function dress(d: Drawn, input: Enum.ProximityPromptInputType)
	local look, prompt = d.look, d.prompt
	local touch = input == Enum.ProximityPromptInputType.Touch
	look.key.Visible = false
	look.pad.Visible = false
	look.dot.Visible = false
	if touch then
		look.dot.Visible = true
	elseif input == Enum.ProximityPromptInputType.Gamepad then
		local ok, image = pcall(function(): string
			return UserInputService:GetImageForKeyCode(prompt.GamepadKeyCode)
		end)
		if ok and image ~= "" then
			look.pad.Image = image
			look.pad.Visible = true
		else
			look.key.Text = string.gsub(prompt.GamepadKeyCode.Name, "^Button", "")
			look.key.Visible = true
		end
	else
		local ok, text = pcall(function(): string
			return UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
		end)
		look.key.Text = if ok and text ~= "" then text else prompt.KeyboardKeyCode.Name
		look.key.TextSize = if #look.key.Text > 1 then WorldButton.Key - 5 else WorldButton.Key
		look.key.Visible = true
	end
	-- a tap a little round the chip still lands; a mouse gets the chip alone
	fit(
		look,
		if touch then WorldButton.TouchChip else WorldButton.Chip,
		if touch then WorldButton.Hit else 0
	)
	local clickable = touch or prompt.ClickablePrompt
	look.gui.Active = clickable
	look.tap.Active = clickable
	look.tap.Interactable = clickable
end

-- Puts `look` on `prompt`'s point, its UIOffset kept in screen points.
local function place(look: Look, prompt: ProximityPrompt)
	local o = prompt.UIOffset
	look.gui.SizeOffset = Vector2.new(o.X / WorldButton.Width, o.Y / WorldButton.Height)
	look.gui.Adornee = prompt.Parent :: any -- any: an Attachment or a BasePart, both adorn
end

local function release(d: Drawn)
	for _, c in d.watch do
		c:Disconnect()
	end
	table.clear(d.watch)
	if d.down then
		d.down = false
		pcall(function()
			d.prompt:InputHoldEnd()
		end)
	end
	local look = d.look
	owner[look] = nil
	-- any: the definitions type Adornee as never nil, but nil is how a BillboardGui lets go
	(look.gui :: any).Adornee = nil
	if #pool < POOL then
		look.gui.Parent = nil
		table.insert(pool, look)
	else
		for _, c in look.conns do
			c:Disconnect()
		end
		look.gui:Destroy()
	end
	if drawn[d.prompt] == d then
		drawn[d.prompt] = nil
	end
	moving[d] = nil
end

local hidden: (prompt: ProximityPrompt) -> ()

local function show(prompt: ProximityPrompt, input: Enum.ProximityPromptInputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
		return
	end
	local d = drawn[prompt]
	if d then
		-- shown again (the input changed, or back before it had gone): carry on from where it is
		d.coming = true
		dress(d, input)
		place(d.look, prompt)
		startMoving(d)
		neighbours(prompt)
		return
	end
	local parent = holderGui()
	if not parent then
		return
	end
	local look = table.remove(pool) or makeLook()
	local fresh: Drawn = {
		prompt = prompt,
		look = look,
		coming = true,
		level = 0,
		holdAt = -1,
		drainFrom = 0,
		drainAt = -1,
		poppedAt = -1,
		refusedAt = -1,
		refusal = "",
		down = false,
		watch = {},
	}
	owner[look] = fresh
	drawn[prompt] = fresh
	dress(fresh, input)
	place(look, prompt)
	look.shove.Position = UDim2.fromOffset(0, 0)
	look.verb.Text = ""
	look.name.Text = ""
	wording(fresh, os.clock())
	paint(fresh, 0, 0, 0, 0)
	-- the words or the spacing changed while it shows (a door's Restore power, a padlock's name)
	local function changed()
		local now = drawn[prompt]
		if now then
			place(now.look, prompt)
			startMoving(now)
		end
	end
	table.insert(fresh.watch, prompt:GetPropertyChangedSignal("ActionText"):Connect(changed))
	table.insert(fresh.watch, prompt:GetPropertyChangedSignal("ObjectText"):Connect(changed))
	table.insert(fresh.watch, prompt:GetPropertyChangedSignal("UIOffset"):Connect(changed))
	-- destroyed or streamed out while it shows: the next step lets its drawing go
	table.insert(
		fresh.watch,
		prompt.AncestryChanged:Connect(function()
			if not prompt:IsDescendantOf(game) then
				hidden(prompt)
			end
		end)
	)
	look.gui.Parent = parent
	startMoving(fresh)
	neighbours(prompt)
end

function hidden(prompt: ProximityPrompt)
	local d = drawn[prompt]
	if not d then
		return
	end
	d.coming = false
	d.holdAt = -1
	if d.down then
		d.down = false
		pcall(function()
			d.prompt:InputHoldEnd()
		end)
	end
	startMoving(d)
	neighbours(prompt)
end

local function holdBegan(prompt: ProximityPrompt)
	local d = drawn[prompt]
	if d then
		d.holdAt = os.clock()
		d.drainAt = -1
		startMoving(d)
	end
end

local function holdEnded(prompt: ProximityPrompt)
	local d = drawn[prompt]
	if d and d.holdAt >= 0 then
		local now = os.clock()
		d.drainFrom = WorldButton.holding(now - d.holdAt, prompt.HoldDuration)
		d.drainAt = now
		d.holdAt = -1
		startMoving(d)
	end
end

local function triggered(prompt: ProximityPrompt)
	local d = drawn[prompt]
	if d then
		local now = os.clock()
		if d.holdAt >= 0 then
			d.drainFrom = 1
			d.drainAt = now
			d.holdAt = -1
		end
		d.poppedAt = now
		startMoving(d)
	end
end

--- Shows `text` as `prompt`'s refusal on this screen (a shake, the words in red for a beat, a
--- dull tick), if it's drawn. The server's refusals arrive here by `Remotes.Refused`.
function ButtonView.refuse(prompt: ProximityPrompt, text: string)
	local d = drawn[prompt]
	if not d or not d.coming then
		return
	end
	local now = os.clock()
	if d.holdAt >= 0 then
		d.drainFrom = WorldButton.holding(now - d.holdAt, prompt.HoldDuration)
		d.drainAt = now
		d.holdAt = -1
	end
	d.refusal = text
	d.refusedAt = now
	startMoving(d)
	local s = refuseSound
	if s then
		s.TimePosition = 0
		s:Play()
	end
end

-- Hiding buttons on this screen (was ButtonReach): each hidden button's reach from the server,
-- taken when the first reason hides it; what hides it; its leaving the world.
local base: { [ProximityPrompt]: number } = {}
local hiders: { [ProximityPrompt]: { [string]: true } } = {}
local gone: { [ProximityPrompt]: RBXScriptConnection } = {}

local restore: (prompt: ProximityPrompt) -> ()

local function forget(prompt: ProximityPrompt)
	base[prompt] = nil
	hiders[prompt] = nil
	local c = gone[prompt]
	if c then
		c:Disconnect()
		gone[prompt] = nil
	end
end

--- Hide `prompt` on this screen for `reason` (`hidden` true), or stop hiding it for that reason.
--- A hidden button draws nothing and no key presses it.
function ButtonView.hide(prompt: ProximityPrompt, reason: string, hide: boolean)
	local set = hiders[prompt]
	if hide then
		if not set then
			set = {}
			hiders[prompt] = set
			base[prompt] = prompt.MaxActivationDistance
			gone[prompt] = prompt.AncestryChanged:Connect(function()
				if not prompt:IsDescendantOf(game) then
					restore(prompt)
				end
			end)
		end
		set[reason] = true
		if prompt.MaxActivationDistance ~= 0 then
			prompt.MaxActivationDistance = 0
		end
	elseif set and set[reason] then
		set[reason] = nil
		if next(set) == nil then
			restore(prompt)
		end
	end
end

-- Nothing hides `prompt` now: its reach back, and forgotten.
function restore(prompt: ProximityPrompt)
	local reach = base[prompt]
	forget(prompt)
	if reach and prompt.MaxActivationDistance ~= reach then
		prompt.MaxActivationDistance = reach
	end
end

function ButtonView.new(): Brix.System
	local connections: { RBXScriptConnection } = {}
	local system = { name = "ButtonView" }

	function system.start(_: any, _context: Brix.Context)
		local s = Instance.new("Sound")
		s.Name = "ButtonRefused"
		s.SoundId = REFUSE_SOUND
		s.PlaybackSpeed = REFUSE_PITCH
		s.Volume = REFUSE_VOLUME
		s.Parent = SoundService
		refuseSound = s
		table.insert(
			connections,
			ProximityPromptService.PromptShown:Connect(
				function(prompt: ProximityPrompt, input: Enum.ProximityPromptInputType)
					show(prompt, input)
				end
			)
		)
		table.insert(connections, ProximityPromptService.PromptHidden:Connect(hidden))
		table.insert(
			connections,
			ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt: ProximityPrompt)
				holdBegan(prompt)
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptButtonHoldEnded:Connect(function(prompt: ProximityPrompt)
				holdEnded(prompt)
			end)
		)
		table.insert(
			connections,
			ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
				triggered(prompt)
			end)
		)
		-- the server's refusals, to this player alone
		task.spawn(function()
			local folder = ReplicatedStorage:WaitForChild(WorldButton.RemoteFolder, 30)
			local remote = folder and folder:WaitForChild(WorldButton.Remote, 30)
			if not (remote and remote:IsA("RemoteEvent")) then
				return
			end
			table.insert(
				connections,
				remote.OnClientEvent:Connect(function(prompt: unknown, text: unknown)
					local w = WorldButton.words(text)
					if typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") and w then
						ButtonView.refuse(prompt, w)
					end
				end)
			)
		end)
	end

	function system.step(_: any, dt: number)
		if next(moving) == nil then
			return
		end
		local now = os.clock()
		for d in moving do
			if drawn[d.prompt] ~= d or not d.prompt.Parent then
				release(d)
				continue
			end
			if not draw(d, now, dt) then
				moving[d] = nil
				if not d.coming and d.level <= 0 then
					release(d)
				end
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, d in drawn do
			release(d)
		end
		for _, look in pool do
			for _, c in look.conns do
				c:Disconnect()
			end
			look.gui:Destroy()
		end
		table.clear(pool)
		local s = refuseSound
		if s then
			s:Destroy()
			refuseSound = nil
		end
		local h = holder
		if h then
			h:Destroy()
			holder = nil
		end
	end

	return system :: any -- any: a plain Brix system built field by field
end

return ButtonView
