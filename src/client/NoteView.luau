--!strict
--[[
	NoteView: the code notes on this screen.

	Their hand. The notes are written in Kalam, a hand Roblox ships but loads on first use, and a
	note that arrives before its hand has loaded can stay blank until its writing is redrawn
	(docs/STUDIO.md, "A SurfaceGui draws on an invisible part"). So this client loads Kalam as it
	starts, before anyone can reach a unit, and redraws any note that streamed in while it loaded.

	Reading one (L-05b1d; owner, Nov 8, D-044). On the wall a note's digit is a speck from the
	doorway, so each note has a "Read" button, as DOORS holds a library book's hint up to you: two
	steps into its unit the button shows under the note, and a tap lifts the note into the middle
	of your screen, crooked as it hangs, its slots written big in its own hand (`NoteCard`), with
	a paper flap. A tap on it, Read again (E, or X on a gamepad), B, a click, walking off or dying
	drops it away. You can still walk and look while it's up: a keeper doesn't wait.

	The card's paper is the note's own mesh drawn in a ViewportFrame. A SurfaceGui draws nothing
	there (seen in Studio, L-05b1d), so the slots are written over the paper on the screen.
]]
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local NoteCard = require(ReplicatedStorage.Shared.Elevator.NoteCard)
local SoundPrimer = require(script.Parent.SoundPrimer)

-- Arriving, the card rises from this share of its side below where it rests, this many degrees
-- more crooked and this much smaller, and settles with a little overshoot: a hand bringing it up.
local LIFT_FROM, LIFT_TURN, LIFT_SCALE = 0.45, 9, 0.86
local LIFT = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local LIFT_FADE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Leaving, it drops this share of its side and turns away this many degrees as it fades.
local DROP_TO, DROP_TURN = 0.55, -7
local DROP = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
-- For this long after it lifts, a tap or a key doesn't drop it: the tap that pressed Read, or an
-- impatient second one, never throws away the note you came for.
local GRACE = 0.3
-- The world behind the card darkens to this transparency of black: the note stands out, and
-- you still see what's coming.
local DIM = 0.55
local DIM_FADE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- The paper's light: warm and from the upper left, like the unit's bulb overhead, so it's the
-- same yellow as the note on the wall, only brighter. Tuned on the Galaxy A16 (L-05b1d): whiter
-- light drew it a pale lemon beside the wall's orange.
local AMBIENT = Color3.fromRGB(135, 120, 98)
local LIGHT = Color3.fromRGB(255, 226, 178)
local LIGHT_FROM = Vector3.new(-0.45, -0.65, 1)
-- A narrow lens, so the paper is drawn nearly flat and the slots line up with its writing area.
local LENS = 8
-- The paper itself, if the place has lost the note's template (then Output warns as it lays notes).
local PAPER = Color3.fromRGB(241, 217, 87)

-- The flap of a sheet of paper (Pro Sound Effects, "File Folder Movement 5", 1.75 s): one sharp
-- flap at 0.78 to 0.88 s, measured in Studio, and nearly silent around it.
local FLAP = {
	Id = "rbxassetid://9114409576",
	Start = 0.74,
	Stop = 1.0,
	Volume = 0.55,
}
-- Lifting it, the flap a little bright; dropping it, lower and softer.
local LIFT_PITCH, DROP_PITCH, DROP_VOLUME = 1.08, 0.86, 0.7

local CLOSE_ACTION = "NoteViewClose"
-- Over the game's other bindings, so Read again drops the card instead of reaching something else.
local PRIORITY = Enum.ContextActionPriority.High.Value

type Entry = {
	model: Model,
	at: Attachment,
	prompt: ProximityPrompt,
	conns: { RBXScriptConnection },
}

type Card = {
	screen: ScreenGui,
	dim: Frame,
	card: ImageButton,
	scale: UIScale,
	paper: GuiObject, -- the ViewportFrame, or a plain square if the template is missing
	writing: Frame,
	labels: { TextLabel },
	flap: Sound,
}

local NoteView = {}

-- The note's writing, off and on again, so it lays out its text in the loaded hand.
local function redraw(notes: { Instance })
	local guis: { SurfaceGui } = {}
	for _, note in notes do
		local gui = note:FindFirstChild("Digits", true)
		if gui and gui:IsA("SurfaceGui") and gui.Enabled then
			gui.Enabled = false
			table.insert(guis, gui)
		end
	end
	if #guis == 0 then
		return
	end
	task.wait() -- a frame off, or the toggle is never seen
	for _, gui in guis do
		if gui.Parent then
			gui.Enabled = true
		end
	end
end

-- How crooked a note hangs as you face it, in degrees clockwise (a GuiObject's Rotation).
local function tiltOf(model: Model): number
	local pivot = model:GetPivot()
	local right = (-pivot.LookVector):Cross(Vector3.yAxis)
	if right.Magnitude < 1e-3 then
		return 0
	end
	local up = pivot.UpVector
	return math.deg(math.atan2(up:Dot(right.Unit), up.Y))
end

-- The note's paper, drawn face on in a ViewportFrame, or a plain square of its colour.
local function paperView(parent: GuiObject): GuiObject
	local template = Elevator.noteTemplate()
	if not template then
		local square = Instance.new("Frame")
		square.Name = "Paper"
		square.AnchorPoint = Vector2.new(0.5, 0.5)
		square.Position = UDim2.fromScale(0.5, 0.5)
		square.Size = UDim2.fromScale(NoteCard.Paper, NoteCard.Paper)
		square.BackgroundColor3 = PAPER
		square.BorderSizePixel = 0
		square.BackgroundTransparency = 1 -- faded in with its ink as it lifts
		square.Parent = parent
		return square
	end
	local view = Instance.new("ViewportFrame")
	view.Name = "Paper"
	view.Size = UDim2.fromScale(1, 1)
	view.BackgroundTransparency = 1
	view.ImageTransparency = 1 -- faded in with its ink as it lifts
	view.Ambient = AMBIENT
	view.LightColor = LIGHT
	view.LightDirection = LIGHT_FROM
	local note = template:Clone()
	local writing = note:FindFirstChild("Writing")
	if writing then
		writing:Destroy() -- its SurfaceGui draws nothing in here; the card writes the slots
	end
	note:PivotTo(CFrame.new())
	note.Parent = view
	-- Frame the note across the card: `Studs` of it in view at its writing's face.
	local face = Elevator.Specs.Note.Write.Centre[3]
	local distance = NoteCard.Studs / 2 / math.tan(math.rad(LENS / 2))
	local camera = Instance.new("Camera")
	camera.FieldOfView = LENS
	camera.CFrame = CFrame.lookAt(
		Vector3.new(0, NoteCard.Middle, face - distance),
		Vector3.new(0, NoteCard.Middle, face)
	)
	camera.Parent = view
	view.CurrentCamera = camera
	view.Parent = parent
	return view
end

local function build(): Card
	local screen = Instance.new("ScreenGui")
	screen.Name = "NoteCard"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true -- the dim covers the top bar too; NoteCard keeps the card below it
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Active = false -- touches pass to the thumbstick: you can walk off reading
	dim.Visible = false
	dim.Parent = screen

	-- The card is one big button: a tap anywhere on the note drops it.
	local card = Instance.new("ImageButton")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundTransparency = 1
	card.Image = ""
	card.AutoButtonColor = false
	card.Selectable = false
	card.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = card
	local paper = paperView(card)

	local writing = Instance.new("Frame")
	writing.Name = "Writing"
	writing.Size = UDim2.fromScale(1, 1)
	writing.BackgroundTransparency = 1
	writing.Parent = card
	card.Parent = screen

	local flap = Instance.new("Sound")
	flap.Name = "NoteFlap"
	flap.SoundId = FLAP.Id
	flap.PlaybackRegionsEnabled = true
	flap.PlaybackRegion = NumberRange.new(FLAP.Start, FLAP.Stop)
	flap.Parent = SoundService

	return {
		screen = screen,
		dim = dim,
		card = card,
		scale = scale,
		paper = paper,
		writing = writing,
		labels = {},
		flap = flap,
	}
end

function NoteView.new(): Brix.System
	local loading: thread? = nil
	local entries: { [Model]: Entry } = {}
	local waiting: { [Model]: RBXScriptConnection } = {} -- notes whose paper hasn't streamed in
	local connections: { RBXScriptConnection } = {}
	local view: Card? = nil
	local openOn: Entry? = nil
	local openedAt = -math.huge -- os.clock() when the card last lifted
	local moving: { Tween } = {}
	local rest = UDim2.new()
	local side = 0

	local function stopMoving()
		for _, t in moving do
			t:Cancel()
		end
		table.clear(moving)
	end

	local function tween(object: Instance, info: TweenInfo, goal: { [string]: any }): Tween
		-- `goal` is a property table, as TweenService takes it
		local t = TweenService:Create(object, info, goal)
		table.insert(moving, t)
		t:Play()
		return t
	end

	local function flap(pitch: number, volume: number)
		local v = view
		if not v then
			return
		end
		v.flap.PlaybackSpeed = pitch
		v.flap.Volume = FLAP.Volume * volume
		v.flap.TimePosition = FLAP.Start
		v.flap:Play()
	end

	-- The paper and its slots fade together (a ViewportFrame's image, the labels' ink).
	local function fadeTo(info: TweenInfo, transparency: number)
		local v = view
		if not v then
			return
		end
		if v.paper:IsA("ViewportFrame") then
			tween(v.paper, info, { ImageTransparency = transparency })
		else
			tween(v.paper, info, { BackgroundTransparency = transparency })
		end
		for _, label in v.labels do
			tween(label, info, { TextTransparency = transparency })
		end
	end

	-- Lays the card out for this screen and `count` slots, written with `marks`.
	local function fit(marks: { string }?)
		local v = view
		if not v then
			return
		end
		local size = v.screen.AbsoluteSize
		local count = if marks then #marks else #v.labels
		local layout = NoteCard.layout(size.X, size.Y, GuiService:GetGuiInset().Y, count)
		side = layout.side
		rest = UDim2.fromOffset(layout.x, layout.y)
		v.card.Size = UDim2.fromOffset(side, side)
		local ink = Elevator.Specs.Note.Ink
		while #v.labels < count do
			local label = Instance.new("TextLabel")
			label.Name = `Slot{#v.labels + 1}`
			label.BackgroundTransparency = 1
			label.FontFace = Font.new(Elevator.Specs.Note.Font, Enum.FontWeight.Bold)
			label.TextColor3 = Color3.fromRGB(ink[1], ink[2], ink[3])
			label.TextTransparency = 1
			label.Parent = v.writing
			table.insert(v.labels, label)
		end
		while #v.labels > count do
			local label = table.remove(v.labels)
			if label then
				label:Destroy()
			end
		end
		for i, label in v.labels do
			local slot = layout.slots[i]
			label.Position = UDim2.fromOffset(slot.x, slot.y)
			label.Size = UDim2.fromOffset(slot.w, slot.h)
			label.TextSize = layout.text
			if marks then
				label.Text = marks[i]
			end
		end
	end

	-- A Read button shows on every note but the one held up, and none while one is.
	local function showPrompts()
		for _, entry in entries do
			entry.prompt.Enabled = openOn == nil
		end
	end

	local close: () -> ()

	-- A tap, a click or Read again drops the card, once it has settled.
	local function letGo()
		if os.clock() - openedAt >= GRACE then
			close()
		end
	end

	local function closeKey(_: string, input: Enum.UserInputState, _object: InputObject)
		if input == Enum.UserInputState.Begin then
			letGo()
		end
		return Enum.ContextActionResult.Sink
	end

	close = function()
		local v = view
		if not openOn or not v then
			return
		end
		openOn = nil
		ContextActionService:UnbindAction(CLOSE_ACTION)
		stopMoving()
		local fall = rest + UDim2.fromOffset(0, side * DROP_TO)
		local drop =
			tween(v.card, DROP, { Position = fall, Rotation = v.card.Rotation + DROP_TURN })
		fadeTo(DROP, 1)
		tween(v.dim, DROP, { BackgroundTransparency = 1 })
		drop.Completed:Once(function(status: Enum.PlaybackState)
			if status == Enum.PlaybackState.Completed and not openOn then
				v.card.Visible = false
				v.dim.Visible = false
			end
		end)
		flap(DROP_PITCH, DROP_VOLUME)
		showPrompts()
	end

	local function open(entry: Entry)
		local v = view
		local text = Elevator.read(entry.model)
		if openOn or not v or not text then
			return
		end
		openOn = entry
		openedAt = os.clock()
		showPrompts()
		fit(NoteCard.slots(text))
		local tilt = tiltOf(entry.model)
		stopMoving()
		v.card.Position = rest + UDim2.fromOffset(0, side * LIFT_FROM)
		v.card.Rotation = tilt + LIFT_TURN
		v.scale.Scale = LIFT_SCALE
		v.card.Visible = true
		v.dim.Visible = true
		tween(v.card, LIFT, { Position = rest, Rotation = tilt })
		tween(v.scale, LIFT, { Scale = 1 })
		fadeTo(LIFT_FADE, 0)
		tween(v.dim, DIM_FADE, { BackgroundTransparency = DIM })
		local keys: { Enum.KeyCode | Enum.UserInputType } =
			{ Enum.KeyCode.E, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonB }
		if UserInputService.MouseEnabled then
			table.insert(keys, Enum.UserInputType.MouseButton1) -- a click anywhere, cursor locked or not
		end
		ContextActionService:BindActionAtPriority(
			CLOSE_ACTION,
			closeKey,
			false,
			PRIORITY,
			table.unpack(keys)
		)
		flap(LIFT_PITCH, 1)
	end

	local function remove(inst: Instance)
		local pending = waiting[inst :: Model]
		if pending then
			pending:Disconnect()
			waiting[inst :: Model] = nil
		end
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
		local paper = inst:FindFirstChild("Paper")
		if not (paper and paper:IsA("BasePart")) then
			-- streamed in without its paper yet: try again when it arrives
			if not waiting[inst] then
				waiting[inst] = inst.ChildAdded:Connect(function()
					local pending = waiting[inst]
					if pending and inst:FindFirstChild("Paper") then
						pending:Disconnect()
						waiting[inst] = nil
						add(inst)
					end
				end)
			end
			return
		end
		local pivot = inst:GetPivot()
		local half = Elevator.Specs.Note.Side * inst:GetScale() / 2
		local at = Instance.new("Attachment")
		at.Name = "ReadPrompt"
		at.Parent = paper
		at.WorldCFrame = CFrame.new(
			pivot.Position
				+ pivot.LookVector * NoteCard.ButtonOut
				- pivot.UpVector * (half + NoteCard.ButtonBelow)
		)
		local p = Instance.new("ProximityPrompt")
		p.Style = Enum.ProximityPromptStyle.Custom -- drawn by ButtonView
		p.ObjectText = ""
		p.ActionText = "Read"
		p.KeyboardKeyCode = Enum.KeyCode.E
		p.GamepadKeyCode = Enum.KeyCode.ButtonX
		p.HoldDuration = 0
		p.MaxActivationDistance = NoteCard.Reach
		p.RequiresLineOfSight = true -- a shut door hides it (docs/STUDIO.md)
		p.Enabled = openOn == nil
		p.Parent = at
		local entry: Entry = { model = inst, at = at, prompt = p, conns = {} }
		entries[inst] = entry
		table.insert(
			entry.conns,
			p.Triggered:Connect(function()
				open(entry)
			end)
		)
	end

	return {
		name = "NoteView",
		start = function(_: any, _context: Brix.Context)
			local v = build()
			v.screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
			view = v
			table.insert(connections, v.card.Activated:Connect(letGo))
			table.insert(
				connections,
				v.screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					if openOn then
						fit(nil)
						v.card.Position = rest
					end
				end)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.NoteTag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.NoteTag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Elevator.NoteTag) do
				add(inst)
			end
			loading = task.spawn(function()
				-- Measuring text in a font loads it: the async measure waits for its files.
				local params = Instance.new("GetTextBoundsParams")
				params.Text = "0123456789 _"
				params.Font = Font.new(Elevator.Specs.Note.Font, Enum.FontWeight.Bold)
				params.Size = 48
				local ok, err = pcall(TextService.GetTextBoundsAsync, TextService, params)
				if not ok then
					warn(`NoteView: Kalam didn't load ({err}); a note may show blank until redrawn`)
				end
				redraw(CollectionService:GetTagged(Elevator.NoteTag))
				-- the flap's first play would otherwise come late (SoundPrimer)
				SoundPrimer.prime({ FLAP.Id })
				loading = nil
			end)
		end,
		step = function(_: any, _dt: number)
			local entry = openOn
			if not entry then
				return
			end
			-- walking off, dying, losing the character or the note leaving drops it
			local character = Players.LocalPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if
				not (root and root:IsA("BasePart"))
				or not humanoid
				or humanoid.Health <= 0
				or not entry.model:IsDescendantOf(Workspace)
				or (root.Position - entry.model:GetPivot().Position).Magnitude > NoteCard.LetGo
			then
				close()
			end
		end,
		stop = function(_: any)
			if loading and coroutine.status(loading) ~= "dead" then
				task.cancel(loading)
			end
			loading = nil
			close()
			stopMoving()
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in entries do
				remove(model)
			end
			for model in waiting do
				remove(model)
			end
			local v = view
			if v then
				v.screen:Destroy()
				v.flap:Destroy()
				view = nil
			end
		end,
	}
end

return NoteView
