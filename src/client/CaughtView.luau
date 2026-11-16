--!strict
--[[
	CaughtView: a keeper's catch and getting kept, on the caught player's own screen (L-06b3c,
	L-07a, L-06c2). The server tells only them (Remotes.Caught, from Keepers, with the keeper's
	body). The hall goes silent, their view is seized round to its face and its face rushes their
	eyes (CaughtLunge), then the screen cuts to black and "Caught" comes up in the dark while the
	film screeches round them; they can't move. In the black the server stores them in a unit
	(KeptPlayers), so they come to on its dark inside, facing the door (the game is always first
	person): their eyes crack open, drop shut, then open, the view blurred and grey as it clears
	and the hall's sounds back. Then a big Bang button comes up (L-07c): on a phone under the right
	thumb, elsewhere low in the middle with its key under it (a click, Space, a gamepad's A or R2),
	the one button on the screen: your hands are empty, so the wheel has slid off the bottom
	(ToolView) and the torch's switch has gone with the jump button (FlashlightView, L-17).
	Each press jolts the view at once and asks the server to bang the door (`Remotes.Bang`); the
	door's thud and shake come back from the server. Presses faster than a bang can land wait for
	the next (one held, as a fighting game buffers an input), so mashing hammers at the door's own
	pace. They stay held, their body not turning with the camera, every prompt hidden, until the
	server lets them out (`Kept.Attribute` cleared, L-07d's Cut free): then their walk, their turn
	and the prompts come back and the Bang button fades away. The film the server wraps
	them in (L-07b) is for friends to see: on their own screen it's never drawn, so their view of
	the dark inside stays clear.
	Every number and the curves are `Caught`'s and `Kept`'s.

	Cut Free (S3-03a2, D-220): a beat after Bang comes up, a smaller warm button eases in beside it,
	left of it (on a phone a thumb's width clear of Bang, so mashing never lands on it), its key
	under it on a computer (F, or a gamepad's Y: the mouse is the view in first person, so a key
	reaches it as Click reaches Bang). It stands only while the offer is on sale
	(`Remotes.CutFree`'s `On`). A press springs it, clicks, asks the server (nothing carried) and
	dims it while Roblox's prompt comes up (`CutFree.AskEvery`); once paid, the film rips off you,
	the door hauls up and both buttons fade as you're let out. Every number is `CutFree`'s.

	Free Everyone (S3-03c, D-223): once the whole team is caught the results wait
	(`ClimbEnd.WaitAttribute`), and with friends here the pill grows into "Free Everyone": wider,
	a swell and its click pitched down, so the way out changing is heard as well as seen. A press
	then asks Remotes.FreeEveryone instead; paid, every film on the floor rips at once. Alone it
	stays Cut Free, which does the same for you.

	Carried up (S3-01a): a player who watched the ride and is stood wrapped in a unit on the new
	floor (`Kept.BroughtAttribute`, set just before the kept mark) gets no lunge and no "Caught":
	their screen is already black (WatchView's dip), so it holds black and their eyes open on the
	dark inside as after any catch.

	It steps only while a catch is on the screen or they're kept.
]]
local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local CaughtLunge = require(script.Parent.CaughtLunge)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local Kept = require(ReplicatedStorage.Shared.Kept)
local SoundPrimer = require(script.Parent.SoundPrimer)

-- The headline's size (pixels), as the gate's "Going up" (GateClock).
local HEADLINE_SIZE = 34

-- The Bang button: the horn's round button, bigger, as the one thing to do in the dark.
local ACTION = "KeptBang"
local INK = Color3.fromRGB(232, 226, 214) -- the buttons' warm off-white
local BUTTON_SEE = 0.45 -- its dark background's transparency, fully in
local RING_SEE = 0.35 -- its ring's
local PHONE_SIDE = 0.27 -- on a phone, its side as a share of the screen's height: a thumb's pad
local PHONE_MIN, PHONE_MAX = 96, 140 -- points
local PHONE_EDGE = 0.045 -- of the screen's width, in from the right and up from the bottom
local DESK_SIDE = 0.14 -- elsewhere, a share of the height: a target to read, not to thumb
local DESK_MIN, DESK_MAX = 76, 104
local BUTTON_LOW = 0.76 -- elsewhere, its foot as a share of the screen's height, its key under it
local CAPTION_SIZE = 18
local PRESS = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PRESSED = 0.84 -- the button's scale at a press, springing back
-- Free Everyone's swap settling from its swell (`CutFree.SwapTime`)
local SWAP = TweenInfo.new(CutFree.SwapTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CUT_ACTION = "KeptCutFree"
-- Cut Free's warm ink and fill (`CutFree.Ink`, `CutFree.Fill`)
local INK_WARM = Color3.fromRGB(CutFree.Ink.r, CutFree.Ink.g, CutFree.Ink.b)
local FILL_WARM = Color3.fromRGB(CutFree.Fill.r, CutFree.Fill.g, CutFree.Fill.b)
local CUT_TEXT_MAX = 26 -- the word's largest size (pixels), so a big screen's pill stays a pill

type Screen = {
	gui: ScreenGui,
	black: Frame,
	headline: TextLabel,
	stroke: UIStroke,
	bangGui: ScreenGui, -- its own, within the phone's safe area, over the black
	holder: Frame, -- the button and its key under it, placed together
	button: TextButton,
	ring: UIStroke,
	pop: UIScale,
	caption: TextLabel,
	cutHolder: Frame, -- Cut Free and its key under it, beside Bang
	cut: TextButton,
	cutRing: UIStroke,
	cutPop: UIScale,
	cutKey: TextLabel,
	click: Sound, -- Cut Free's press
	blur: BlurEffect, -- the wake's haze, on this screen only
	grey: ColorCorrectionEffect,
}

local function makeScreen(parent: Instance): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = "Caught"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 30 -- over everything, the gate's fade included
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	local black = Instance.new("Frame")
	black.Name = "Black"
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BackgroundTransparency = 1
	black.BorderSizePixel = 0
	black.Active = false
	black.ZIndex = 1
	black.Parent = gui
	local function label(name: string, size: number, y: number, text: string): (TextLabel, UIStroke)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.Position = UDim2.fromScale(0.5, y)
		l.Size = UDim2.new(0.9, 0, 0, size + 12)
		l.BackgroundTransparency = 1
		l.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		l.TextSize = size
		l.TextColor3 = Color3.fromRGB(214, 206, 196)
		l.TextTransparency = 1
		l.Text = text
		l.ZIndex = 2
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 2
		stroke.Transparency = 1
		stroke.Parent = l
		l.Parent = gui
		return l, stroke
	end
	local headline, stroke = label("Headline", HEADLINE_SIZE, 0.45, "Caught")
	gui.Parent = parent

	local bangGui = Instance.new("ScreenGui")
	bangGui.Name = "Bang"
	bangGui.ResetOnSpawn = false
	bangGui.DisplayOrder = 31
	bangGui.Enabled = false
	local holder = Instance.new("Frame")
	holder.Name = "Bang"
	holder.BackgroundTransparency = 1
	holder.Parent = bangGui
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.fromScale(1, 1)
	button.AutoButtonColor = false
	button.BackgroundColor3 = Color3.new(0, 0, 0)
	button.Font = Enum.Font.GothamBold
	button.Text = "Bang"
	button.TextColor3 = INK
	button.TextScaled = true
	button.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.2, 0), UDim.new(0.2, 0)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.33, 0), UDim.new(0.33, 0)
	pad.Parent = button
	local ring = Instance.new("UIStroke")
	ring.Color = INK
	ring.Thickness = 3
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Parent = button
	local pop = Instance.new("UIScale")
	pop.Parent = button
	-- the key, under the button where there's no thumb to press it (beside the button, not in
	-- it: the button's padding would pull it inside)
	local caption = Instance.new("TextLabel")
	caption.Name = "Key"
	caption.AnchorPoint = Vector2.new(0.5, 0)
	caption.Position = UDim2.new(0.5, 0, 1, 6)
	caption.Size = UDim2.fromOffset(160, CAPTION_SIZE + 6)
	caption.BackgroundTransparency = 1
	caption.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	caption.TextSize = CAPTION_SIZE
	caption.TextColor3 = INK
	caption.Parent = holder

	-- Cut Free: a warm pill beside Bang, its key under it the same way
	local cutHolder = Instance.new("Frame")
	cutHolder.Name = "CutFree"
	cutHolder.BackgroundTransparency = 1
	cutHolder.Visible = false
	cutHolder.Parent = bangGui
	local cut = Instance.new("TextButton")
	cut.Name = "Button"
	cut.Size = UDim2.fromScale(1, 1)
	cut.AutoButtonColor = false
	cut.BackgroundColor3 = FILL_WARM
	cut.Font = Enum.Font.GothamBold
	cut.Text = CutFree.Word
	cut.TextColor3 = INK_WARM
	cut.TextScaled = true
	cut.Parent = cutHolder
	local cutCorner = Instance.new("UICorner")
	cutCorner.CornerRadius = UDim.new(0.5, 0)
	cutCorner.Parent = cut
	local cutPad = Instance.new("UIPadding")
	cutPad.PaddingLeft, cutPad.PaddingRight = UDim.new(0.13, 0), UDim.new(0.13, 0)
	cutPad.PaddingTop, cutPad.PaddingBottom = UDim.new(0.27, 0), UDim.new(0.27, 0)
	cutPad.Parent = cut
	local cutLimit = Instance.new("UITextSizeConstraint")
	cutLimit.MaxTextSize = CUT_TEXT_MAX
	cutLimit.Parent = cut
	local cutRing = Instance.new("UIStroke")
	cutRing.Color = INK_WARM
	cutRing.Thickness = 2
	cutRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cutRing.Parent = cut
	local cutPop = Instance.new("UIScale")
	cutPop.Parent = cut
	local cutKey = Instance.new("TextLabel")
	cutKey.Name = "Key"
	cutKey.AnchorPoint = Vector2.new(0.5, 0)
	cutKey.Position = UDim2.new(0.5, 0, 1, 6)
	cutKey.Size = UDim2.fromOffset(160, CAPTION_SIZE + 6)
	cutKey.BackgroundTransparency = 1
	cutKey.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
	cutKey.TextSize = CAPTION_SIZE
	cutKey.TextColor3 = INK_WARM
	cutKey.Parent = cutHolder
	local click = Instance.new("Sound")
	click.Name = "CutFreeClick"
	click.SoundId = CutFree.Click.id
	click.PlaybackSpeed = CutFree.Click.pitch
	click.Volume = CutFree.Click.volume
	click.Parent = bangGui
	bangGui.Parent = parent
	local blur = Instance.new("BlurEffect")
	blur.Name = "CaughtBlur"
	blur.Size = 0
	blur.Enabled = false
	blur.Parent = Lighting
	local grey = Instance.new("ColorCorrectionEffect")
	grey.Name = "CaughtGrey"
	grey.Enabled = false
	grey.Parent = Lighting
	return {
		gui = gui,
		black = black,
		headline = headline,
		stroke = stroke,
		bangGui = bangGui,
		holder = holder,
		button = button,
		ring = ring,
		pop = pop,
		caption = caption,
		cutHolder = cutHolder,
		cut = cut,
		cutRing = cutRing,
		cutPop = cutPop,
		cutKey = cutKey,
		click = click,
		blur = blur,
		grey = grey,
	}
end

-- The Bang button's place and size for this screen: under the right thumb on a phone, low in
-- the middle elsewhere, with its key under it. Cut Free stands left of it, level with its middle,
-- `CutFree.Gap` of its side clear.
local function placeButton(s: Screen, touch: boolean, wide: number)
	local camera = Workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local b = s.holder
	local c = s.cutHolder
	c.AnchorPoint = Vector2.new(1, 0.5)
	local side
	if touch then
		side = math.clamp(math.round(view.Y * PHONE_SIDE), PHONE_MIN, PHONE_MAX)
		local edge = math.round(view.X * PHONE_EDGE)
		b.AnchorPoint = Vector2.new(1, 1)
		b.Position = UDim2.new(1, -edge, 1, -edge)
		local gap = math.round(side * CutFree.Gap)
		c.Position = UDim2.new(1, -(edge + side + gap), 1, -(edge + math.round(side / 2)))
	else
		side = math.clamp(math.round(view.Y * DESK_SIDE), DESK_MIN, DESK_MAX)
		b.AnchorPoint = Vector2.new(0.5, 1)
		b.Position = UDim2.fromScale(0.5, BUTTON_LOW)
		local gap = math.round(side * CutFree.Gap)
		c.Position =
			UDim2.new(0.5, -(math.round(side / 2) + gap), BUTTON_LOW, -math.round(side / 2))
	end
	b.Size = UDim2.fromOffset(side, side)
	local tall = math.round(side * CutFree.Tall)
	c.Size = UDim2.fromOffset(math.round(tall * wide), tall)
	-- its key on the same line as Bang's: both 6 under Bang's foot, the pill being level with
	-- Bang's middle
	s.cutKey.Position = UDim2.new(0.5, 0, 0.5, math.round(side / 2) + 6)
end

-- The key under Bang for the input in use: none for a thumb.
local function keyFor(input: Enum.UserInputType): string
	if input == Enum.UserInputType.Touch then
		return ""
	elseif string.find(input.Name, "Gamepad") then
		return "A"
	end
	return "Click"
end

-- The key under Cut Free: none for a thumb.
local function cutKeyFor(input: Enum.UserInputType): string
	if input == Enum.UserInputType.Touch then
		return ""
	elseif string.find(input.Name, "Gamepad") then
		return "Y"
	end
	return "F"
end

-- The button's look `level` of the way in (0 out, 1 in).
local function showButton(s: Screen, level: number)
	local out = 1 - level
	s.button.BackgroundTransparency = BUTTON_SEE + (1 - BUTTON_SEE) * out
	s.button.TextTransparency = out
	s.ring.Transparency = RING_SEE + (1 - RING_SEE) * out
	s.caption.TextTransparency = out
end

-- Cut Free's look `level` of the way in (0 out and untouchable, 1 in).
local function showCut(s: Screen, level: number)
	local out = 1 - level
	s.cutHolder.Visible = level > 0
	s.cut.BackgroundTransparency = CutFree.FillSee + (1 - CutFree.FillSee) * out
	s.cut.TextTransparency = out
	s.cutRing.Transparency = CutFree.RingSee + (1 - CutFree.RingSee) * out
	s.cutKey.TextTransparency = out
end

-- `from` moved toward `to` by at most `by`.
local function toward(from: number, to: number, by: number): number
	if from < to then
		return math.min(from + by, to)
	end
	return math.max(from - by, to)
end

-- Who's held still, and their own walk, jump and turn to give back. Held by the Humanoid's own
-- walk and jump set to 0 on this screen, which owns the character's movement: the PlayerModule's
-- switches don't hold it any more (docs/STUDIO.md). Its turn with the camera is off too, so a
-- kept body stays facing the door the server stood it at while you look round.
type Held = {
	humanoid: Humanoid,
	walk: number,
	jumpHeight: number,
	jumpPower: number,
	autoRotate: boolean,
}

local function hold(): Held?
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local held = {
		humanoid = humanoid,
		walk = humanoid.WalkSpeed,
		jumpHeight = humanoid.JumpHeight,
		jumpPower = humanoid.JumpPower,
		autoRotate = humanoid.AutoRotate,
	}
	humanoid.WalkSpeed, humanoid.JumpHeight, humanoid.JumpPower = 0, 0, 0
	humanoid.AutoRotate = false
	return held
end

-- Gives back their walk and jump, unless something else set them meanwhile (a heavy tool's pace,
-- from the server).
local function letGo(held: Held)
	local humanoid = held.humanoid
	if humanoid.WalkSpeed == 0 then
		humanoid.WalkSpeed = held.walk
	end
	if humanoid.JumpHeight == 0 then
		humanoid.JumpHeight = held.jumpHeight
	end
	if humanoid.JumpPower == 0 then
		humanoid.JumpPower = held.jumpPower
	end
	humanoid.AutoRotate = held.autoRotate
end

-- Turns the camera the way your body faces: where the server stood you, facing the door.
local function faceTheDoor()
	local cam = Workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if cam and root and root:IsA("BasePart") then
		local at = cam.CFrame.Position
		cam.CFrame = CFrame.lookAt(at, at + root.CFrame.LookVector)
	end
end

local CaughtView = {}

-- The system; `kick` jerks the view (CameraShake's).
function CaughtView.new(kick: (amount: number) -> ()): Brix.System
	local player = Players.LocalPlayer
	local screen: Screen? = nil
	local lunge = CaughtLunge.new(kick)
	local since = -1 -- seconds since the catch on screen, or -1 with none
	local kept = false -- the server has us kept (`Kept.Attribute`)
	local awake = -1 -- seconds since the screen opened on the unit's inside, or -1
	local carried = false -- the screen's black is a carry's, not a catch's: no lunge, no headline
	local held: Held? = nil -- held still while the catch is on screen or we're kept
	local wrap: BasePart? = nil -- the film round us while we're kept, once it's on
	local running = false
	local connections: { RBXScriptConnection } = {}
	local bangRemote: RemoteEvent? = nil
	local touch = false
	local bound = false -- the Bang keys are bound
	local lastBang: number? = nil -- os.clock of our last bang sent
	local queued = false -- a press waiting for the next bang
	local leaving = 0 -- seconds left of the Bang button fading as we're let out
	local cutRemote: RemoteEvent? = nil
	local cutOn = false -- the offer is on sale here (`CutFree.OnAttribute`)
	local cutShown = 0 -- Cut Free's arrival, 0 to 1
	local cutDim = 1 -- 1, or down toward `CutFree.Dim` while a press is out
	local cutDrawn = -1 -- the look last drawn, so a still frame writes nothing
	local cutAsked = -math.huge -- os.clock of our last press sent
	local cutBound = false -- its keys are bound
	local everyoneRemote: RemoteEvent? = nil
	local everyoneOn = false -- Free Everyone is on sale here
	local waits = false -- a wipe waits on its offer (`ClimbEnd.WaitAttribute`)
	local wantAll = false -- the pill should read Free Everyone: a wipe waits, friends here, on sale
	local cutAll = false -- it does
	local cutWide = CutFree.Wide -- its width as a share of its height, easing on the swap

	-- Whether the pill should read Free Everyone now.
	local function lookAll()
		local alone = CutFree.wipeOffer(#Players:GetPlayers()) == CutFree.Offer
		wantAll = waits and everyoneOn and not alone
	end

	-- Both buttons off at once, no fade: a new catch's black is coming over them.
	local function hideButtons(s: Screen)
		leaving = 0
		s.bangGui.Enabled = false
		showButton(s, 0)
		cutShown, cutDrawn = 0, 0
		showCut(s, 0)
	end

	-- A press of Cut Free or its key: while it's fully up and no press is out, it springs, clicks
	-- and asks the server; Roblox's prompt (or a spare in the save) answers from there.
	local function cutPress()
		local s = screen
		local now = os.clock()
		local on = if cutAll then everyoneOn else cutOn
		if not (s and bound and on and cutShown >= 1) or now - cutAsked < CutFree.AskEvery then
			return
		end
		cutAsked = now
		s.click.PlaybackSpeed, s.click.Volume = CutFree.Click.pitch, CutFree.Click.volume
		s.click.TimePosition = 0
		s.click:Play()
		s.cutPop.Scale = CutFree.Pressed
		TweenService:Create(s.cutPop, PRESS, { Scale = 1 }):Play()
		local r = if cutAll then everyoneRemote else cutRemote
		if r then
			r:FireServer()
		end
	end

	local function onCutAction(
		_: string,
		state: Enum.UserInputState,
		_input: InputObject
	): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin then
			cutPress()
		end
		return Enum.ContextActionResult.Sink
	end

	-- Whether a click at `input` lands on Cut Free (a freed cursor's click): then it's Cut Free's,
	-- not a bang.
	local function onCut(input: InputObject): boolean
		local s = screen
		if
			not (
				s
				and s.cutHolder.Visible
				and input.UserInputType == Enum.UserInputType.MouseButton1
			)
		then
			return false
		end
		local gui = player:FindFirstChildOfClass("PlayerGui")
		if not gui then
			return false
		end
		local at = input.Position
		return table.find(gui:GetGuiObjectsAtPosition(at.X, at.Y), s.cut :: GuiObject) ~= nil
	end

	-- Bangs now: the view jolts, the button springs, and the server is asked.
	local function bang()
		lastBang, queued = os.clock(), false
		local r = bangRemote
		if r then
			r:FireServer()
		end
		kick(Kept.BangKick)
		local s = screen
		if s then
			s.pop.Scale = PRESSED
			TweenService:Create(s.pop, PRESS, { Scale = 1 }):Play()
		end
	end

	-- A press of the button or a key: it bangs if a bang can land now, else waits for the next.
	local function press()
		if not (kept and since < 0 and awake >= 0) then
			return
		end
		if Kept.ready(lastBang, os.clock()) then
			bang()
		else
			queued = true
		end
	end

	local function onAction(
		_: string,
		state: Enum.UserInputState,
		input: InputObject
	): Enum.ContextActionResult
		if state == Enum.UserInputState.Begin and not onCut(input) then
			press()
		end
		return Enum.ContextActionResult.Sink
	end

	-- Nothing of the catch left: the screen off, walk and turn back, prompts back. The Bang
	-- button, if it was up, fades out over `Kept.BangOut` rather than snapping off.
	local function finish()
		since, awake, carried = -1, -1, false
		queued = false
		lunge.release()
		local wasUp = bound
		if bound then
			bound = false
			ContextActionService:UnbindAction(ACTION)
		end
		if screen then
			screen.gui.Enabled = false
			screen.blur.Enabled, screen.grey.Enabled = false, false
			if wasUp and running then
				leaving = Kept.BangOut -- Cut Free fades with it, at the same pace (step)
			else
				hideButtons(screen)
			end
		end
		if held then
			letGo(held)
			held = nil
		end
		wrap = nil
		ProximityPromptService.Enabled = true
	end

	-- unknown: the remote's argument, the keeper's body, which CaughtLunge checks
	local function onCaught(body: unknown)
		since, awake, carried = 0, -1, false
		lunge.seize(body)
		if not held then
			held = hold()
		end
		if screen then
			screen.gui.Enabled = true
			if leaving > 0 then
				hideButtons(screen)
			end
		end
	end

	local function onKept()
		local now = player:GetAttribute(Kept.Attribute) == true
		if now == kept then
			return
		end
		kept = now
		if kept then
			-- no prompt answers a wrapped player; hide them so none is offered either
			ProximityPromptService.Enabled = false
			if not held then
				held = hold()
			end
			local s = screen
			if
				since < 0
				and s
				and Kept.brought(
					player:GetAttribute(Kept.BroughtAttribute),
					Workspace:GetServerTimeNow()
				)
			then
				-- carried up: the black from the cut, then the wake, on our own clock
				since, awake, carried = Caught.Dark, -1, true
				s.gui.Enabled = true
				s.black.BackgroundTransparency = 0
				if leaving > 0 then
					hideButtons(s)
				end
			end
		elseif since < 0 then
			finish()
		end
	end

	return {
		name = "CaughtView",
		start = function(_: any, _context: Brix.Context)
			running = true
			local s = makeScreen(player:WaitForChild("PlayerGui"))
			screen = s
			touch = UserInputService.TouchEnabled
			placeButton(s, touch, cutWide)
			showButton(s, 0)
			showCut(s, 0)
			local last = UserInputService:GetLastInputType()
			s.caption.Text, s.cutKey.Text = keyFor(last), cutKeyFor(last)
			table.insert(connections, s.button.Activated:Connect(press))
			table.insert(connections, s.cut.Activated:Connect(cutPress))
			table.insert(
				connections,
				UserInputService.LastInputTypeChanged:Connect(function(input: Enum.UserInputType)
					s.caption.Text, s.cutKey.Text = keyFor(input), cutKeyFor(input)
				end)
			)
			task.spawn(SoundPrimer.prime, { CutFree.Click.id })
			local camera = Workspace.CurrentCamera
			if camera then
				table.insert(
					connections,
					camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
						placeButton(s, touch, cutWide)
					end)
				)
			end
			table.insert(
				connections,
				player:GetAttributeChangedSignal(Kept.Attribute):Connect(onKept)
			)
			onKept()
			task.spawn(function()
				local folder = ReplicatedStorage:WaitForChild(Caught.RemoteFolder, 30)
				local remote = folder and folder:WaitForChild(Caught.Remote, 30)
				if running and remote and remote:IsA("RemoteEvent") then
					table.insert(connections, remote.OnClientEvent:Connect(onCaught))
				end
				local bangs = folder and folder:WaitForChild(Kept.BangRemote, 30)
				if running and bangs and bangs:IsA("RemoteEvent") then
					bangRemote = bangs
				end
				local sells = folder and folder:WaitForChild(CutFree.Remote, 30)
				if running and sells and sells:IsA("RemoteEvent") then
					cutRemote = sells
					local function look()
						cutOn = sells:GetAttribute(CutFree.OnAttribute) == true
					end
					table.insert(
						connections,
						sells:GetAttributeChangedSignal(CutFree.OnAttribute):Connect(look)
					)
					look()
				end
				local all = folder and folder:WaitForChild(CutFree.EveryoneRemote, 30)
				if running and all and all:IsA("RemoteEvent") then
					everyoneRemote = all
					local function look()
						everyoneOn = all:GetAttribute(CutFree.OnAttribute) == true
						lookAll()
					end
					table.insert(
						connections,
						all:GetAttributeChangedSignal(CutFree.OnAttribute):Connect(look)
					)
					look()
				end
			end)
			local function lookWaits()
				waits = Workspace:GetAttribute(ClimbEnd.WaitAttribute) ~= nil
				lookAll()
			end
			table.insert(
				connections,
				Workspace:GetAttributeChangedSignal(ClimbEnd.WaitAttribute):Connect(lookWaits)
			)
			table.insert(connections, Players.PlayerAdded:Connect(lookAll))
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function()
					task.defer(lookAll) -- once they're gone from the list
				end)
			)
			lookWaits()
		end,
		step = function(_: any, dt: number)
			local s = screen
			if leaving > 0 and s then
				leaving = math.max(leaving - dt, 0)
				showButton(s, leaving / Kept.BangOut)
				if leaving == 0 then
					s.bangGui.Enabled = false
				end
			end
			if since >= 0 then
				-- the lunge's clock, so the black lands on the frame its face goes; a carry's own
				since = if carried then since + dt else lunge.since()
				local lifts = Caught.Dark + Caught.Hold
				if since >= lifts then
					lunge.hear() -- the hall comes back as your eyes open
				end
				if kept and since >= Caught.Dark and since <= lifts then
					faceTheDoor() -- in the black, where the server has put us by now
				end
				if not Caught.showing(since) then
					since, carried = -1, false
					if s then
						s.blur.Enabled, s.grey.Enabled = false, false
					end
					if not kept then
						finish()
						return
					end
					awake = 0
				elseif s then
					s.black.BackgroundTransparency = 1 - Caught.blackout(since)
					local clear = if carried then 1 else 1 - Caught.headline(since)
					s.headline.TextTransparency = clear
					s.stroke.Transparency = clear
					local haze = Caught.haze(since)
					s.blur.Enabled, s.grey.Enabled = haze > 0, haze > 0
					s.blur.Size = Caught.Blur * haze
					s.grey.Saturation = Caught.Grey * haze
				end
			end
			if kept then
				-- the film the server wrapped us in: never drawn on our own screen. Every frame,
				-- as the camera's own first-person fade writes this too
				local w = wrap
				if not (w and w.Parent) then
					local character = player.Character
					local found = character and character:FindFirstChild(Kept.Wrap)
					w = if found and found:IsA("BasePart") then found else nil
					wrap = w
				end
				if w and w.LocalTransparencyModifier ~= 1 then
					w.LocalTransparencyModifier = 1
				end
			end
			if since < 0 and kept and s then
				-- awake inside: the black gone, the Bang button coming up
				if awake < 0 then
					awake = 0
				end
				if not bound then
					bound = true
					s.bangGui.Enabled = true
					ContextActionService:BindActionAtPriority(
						ACTION,
						onAction,
						false,
						Enum.ContextActionPriority.High.Value,
						Enum.UserInputType.MouseButton1,
						Enum.KeyCode.Space,
						Enum.KeyCode.ButtonA,
						Enum.KeyCode.ButtonR2
					)
				end
				if awake <= Kept.BangIn then
					s.black.BackgroundTransparency = 1
					s.headline.TextTransparency, s.stroke.Transparency = 1, 1
					showButton(s, math.min((awake + dt) / Kept.BangIn, 1))
				end
				awake += dt
				if queued and Kept.ready(lastBang, os.clock()) then
					bang()
				end
			end
			if s and (bound or cutShown > 0 or cutBound) then
				-- Free Everyone: the pill grows into its words as the wipe waits (seen, it swells
				-- and its click sounds low); back to Cut Free if the wait ends with us still here
				if wantAll ~= cutAll then
					cutAll = wantAll
					s.cut.Text = if cutAll then CutFree.EveryoneWord else CutFree.Word
					if cutAll and cutShown > 0 then
						s.cutPop.Scale = CutFree.Swell
						TweenService:Create(s.cutPop, SWAP, { Scale = 1 }):Play()
						s.click.PlaybackSpeed, s.click.Volume =
							CutFree.SwapPitch, CutFree.SwapVolume
						s.click.TimePosition = 0
						s.click:Play()
					end
				end
				local wideTo = if cutAll then CutFree.EveryoneWide else CutFree.Wide
				if cutWide ~= wideTo then
					local by = dt * (CutFree.EveryoneWide - CutFree.Wide) / CutFree.SwapTime
					cutWide = if cutShown > 0 then toward(cutWide, wideTo, by) else wideTo
					local tall = s.cutHolder.Size.Y.Offset
					s.cutHolder.Size = UDim2.fromOffset(math.round(tall * cutWide), tall)
				end
				-- Cut Free: up a beat after Bang while it's on sale, out with Bang at Bang's pace
				local on = if cutAll then everyoneOn else cutOn
				local up = bound and on and awake >= CutFree.InAfter
				local want = if up then 1 else 0
				local pace = if want > cutShown then Kept.BangIn else Kept.BangOut
				cutShown = toward(cutShown, want, dt / pace)
				local out = os.clock() - cutAsked < CutFree.AskEvery
				local dimTo = if out then CutFree.Dim else 1
				cutDim = toward(cutDim, dimTo, dt * (1 - CutFree.Dim) / CutFree.DimTime)
				local look = cutShown * cutDim
				if look ~= cutDrawn then
					cutDrawn = look
					showCut(s, look)
				end
				if up ~= cutBound then
					cutBound = up
					if up then
						ContextActionService:BindActionAtPriority(
							CUT_ACTION,
							onCutAction,
							false,
							Enum.ContextActionPriority.High.Value,
							Enum.KeyCode.F,
							Enum.KeyCode.ButtonY
						)
					else
						ContextActionService:UnbindAction(CUT_ACTION)
					end
				end
			end
		end,
		stop = function(_: any)
			running = false
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			finish()
			if cutBound then
				cutBound = false
				ContextActionService:UnbindAction(CUT_ACTION)
			end
			lunge.destroy()
			if screen then
				screen.gui:Destroy()
				screen.bangGui:Destroy()
				screen.blur:Destroy()
				screen.grey:Destroy()
				screen = nil
			end
		end,
	}
end

return CaughtView
