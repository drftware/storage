--!strict
--[[
	ArrangeUndo (S5-03j4a, D-460): Undo and Redo in Arrange, the room editor (D-436). The moment,
	The Sims 4's build mode: you shove the bed into the wrong corner, tap Undo and it glides back;
	Redo sends it again. Two round buttons beside Done, a curved arrow each way and no words, dim
	while there's nothing to take back or do again; Ctrl+Z and Ctrl+Y (Ctrl+Shift+Z too, and Cmd
	on a Mac) on a keyboard.

	What a step holds and what each press asks is `Home.History`, on Brix's two-sided list
	(`Brix.UndoList`, ENG-28c). The hand carries each ask out as a finger would (`Hand.replay`): the
	thing lifts, glides and lands with its knock, or shrinks into the box, and the server judges it
	as any move. A refused one floats back, as any refused move does, and its step is dropped.

	Undo with a thing selected and not yet set down puts it back where it was first: that is the
	change not yet made. Only while Arrange is open; closing forgets the list.

	ArrangeView makes one with its gui, opens it with Arrange, passes the hand's accepted changes to
	`record`, and keeps the ring clear of `buttons`.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Brix = require(ReplicatedStorage.Brix)
local History = require(ReplicatedStorage.Shared.Home.History)

local POP = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local QUICK = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- How many steps one stay in Arrange keeps: far more than anyone takes back.
local LIMIT = 100
-- The buttons' size and the gap between them (points): Done's height, so they sit in its row.
local SIZE, GAP = 48, 8
-- How see-through a button and its arrow are with nothing to do: plainly asleep, still seen.
local DIM_FILL, DIM_ICON = 0.5, 0.65

export type Options = {
	parent: Instance, -- the screen's gui
	at: UDim2, -- where Redo's top right corner stands (Undo is just left of it)
	colour: Color3, -- the buttons' fill (the ring's)
	rim: Color3,
	ink: Color3, -- the arrows
	-- The pop and click of a press (the screen's own).
	press: (button: GuiObject) -> (),
	-- The thing lifted now, if any, and whether its ask waits for the server.
	lifted: () -> (boolean, boolean),
	-- Puts the selected thing back where it was (a change not yet made).
	putBack: () -> (),
	-- Carries an undo or redo out (`Hand.replay`, or a group's `ArrangeGroup.replay`): `finished`
	-- hears the server's word once, with the group's other things' ids in `more`.
	replay: (
		ask: History.Ask,
		finished: (ok: boolean, id: string?, more: { string? }?) -> ()
	) -> boolean,
}

export type ArrangeUndo = {
	-- Shows the buttons and listens to the keys while Arrange is open; closing forgets the list.
	open: (on: boolean) -> (),
	-- A change the server accepted (`Hand`'s `changed`).
	record: (
		name: string,
		idBefore: string?,
		before: History.Pose?,
		idAfter: string?,
		after: History.Pose?
	) -> (),
	-- Several changes the server accepted as one group ask: one step (`History.recordGroup`).
	recordGroup: (changes: { History.Change }) -> (),
	-- A thing was selected or let go: Undo lights to put it back, Redo sleeps.
	refresh: () -> (),
	-- The two buttons, for the ring to keep off.
	buttons: { GuiObject },
	destroy: () -> (),
}

local ArrangeUndo = {}

-- A curved arrow in `parent`: the top half of a ring, its head at the left end for Undo (`back`)
-- or the right for Redo, pointing down where the turn ends. Answers the group that fades it.
local function arrow(parent: GuiObject, ink: Color3, back: boolean): CanvasGroup
	local icon = Instance.new("CanvasGroup")
	icon.Name = "Arrow"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 2)
	icon.Size = UDim2.fromOffset(30, 26)
	icon.Parent = parent
	-- the arc: a ring's top half, clipped by its own group
	local clip = Instance.new("CanvasGroup")
	clip.BackgroundTransparency = 1
	clip.Position = UDim2.fromOffset(3, 2)
	clip.Size = UDim2.fromOffset(24, 12)
	clip.Parent = icon
	local ring = Instance.new("Frame")
	ring.BackgroundTransparency = 1
	ring.Position = UDim2.fromOffset(1.5, 1.5)
	ring.Size = UDim2.fromOffset(21, 21)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = ring
	local line = Instance.new("UIStroke")
	line.Thickness = 3
	line.Color = ink
	line.Parent = ring
	ring.Parent = clip
	-- the head: two short strokes meeting in a point under the arc's end
	local tipX = if back then 6 else 24
	for _, lean in { -1, 1 } do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Size = UDim2.fromOffset(10, 3)
		bar.Position = UDim2.fromOffset(tipX + lean * 3, 17)
		bar.Rotation = lean * -45
		bar.BackgroundColor3 = ink
		bar.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = bar
		bar.Parent = icon
	end
	return icon
end

local function button(options: Options, name: string, back: boolean): (TextButton, CanvasGroup)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.AutoButtonColor = false
	b.AnchorPoint = Vector2.new(1, 0)
	b.Size = UDim2.fromOffset(SIZE, SIZE)
	b.BackgroundColor3 = options.colour
	b.BackgroundTransparency = 0.1
	b.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = b
	local rim = Instance.new("UIStroke")
	rim.Color = options.rim
	rim.Transparency = 0.25
	rim.Thickness = 2
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = b
	Instance.new("UIScale").Parent = b
	local icon = arrow(b, options.ink, back)
	b.Parent = options.parent
	return b, icon
end

function ArrangeUndo.new(options: Options): ArrangeUndo
	local list: Brix.UndoList<History.Step> = Brix.UndoList.new({ limit = LIMIT })
	local history = History.new(list)
	local undoButton, undoIcon = button(options, "Undo", true)
	local redoButton, redoIcon = button(options, "Redo", false)
	redoButton.Position = options.at
	undoButton.Position = options.at - UDim2.fromOffset(SIZE + GAP, 0)
	local inputs: { RBXScriptConnection } = {}
	local shown = false
	local lit = { [undoButton] = true, [redoButton] = true }

	-- Each button lit while it has something to do, asleep otherwise; eased.
	local function paint(b: TextButton, icon: CanvasGroup, on: boolean)
		if lit[b] == on then
			return
		end
		lit[b] = on
		TweenService:Create(b, QUICK, { BackgroundTransparency = if on then 0.1 else DIM_FILL })
			:Play()
		TweenService:Create(icon, QUICK, { GroupTransparency = if on then 0 else DIM_ICON }):Play()
	end

	local function refresh()
		local free = not history.waiting()
		local held = options.lifted()
		paint(undoButton, undoIcon, free and (held or history.canUndo()))
		paint(redoButton, redoIcon, free and not held and history.canRedo())
	end

	local function run(ask: History.Ask?)
		if not ask then
			return
		end
		local started = options.replay(ask, function(ok: boolean, id: string?, more: { string? }?)
			history.answered(ok, id, more)
			refresh()
		end)
		if not started then
			history.answered(false, nil) -- gone or out of reach: that step is dropped
		end
		refresh()
	end

	local function undo()
		local held, asking = options.lifted()
		if asking or history.waiting() then
			return
		elseif held then
			options.putBack()
			refresh()
			return
		end
		run(history.undo())
	end

	local function redo()
		local held = options.lifted()
		if held or history.waiting() then
			return
		end
		run(history.redo())
	end

	undoButton.Activated:Connect(function()
		if lit[undoButton] then
			options.press(undoButton)
			undo()
		end
	end)
	redoButton.Activated:Connect(function()
		if lit[redoButton] then
			options.press(redoButton)
			redo()
		end
	end)

	local function modifier(): boolean
		return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.LeftSuper)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightSuper)
	end
	local function shift(): boolean
		return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	end

	local function stopListening()
		for _, c in inputs do
			c:Disconnect()
		end
		table.clear(inputs)
	end

	local function open(on: boolean)
		stopListening()
		history.clear()
		shown = on
		for _, b in { undoButton, redoButton } do
			b.Visible = on
			if on then
				local scale = b:FindFirstChildOfClass("UIScale")
				if scale then -- pops in with Arrange
					scale.Scale = 0.5
					TweenService:Create(scale, POP, { Scale = 1 }):Play()
				end
			end
		end
		if not on then
			return
		end
		refresh()
		table.insert(
			inputs,
			UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
				local k = input.KeyCode
				if processed or UserInputService:GetFocusedTextBox() or not modifier() then
					return
				end
				if k == Enum.KeyCode.Z and not shift() then
					if lit[undoButton] then
						options.press(undoButton)
					end
					undo()
				elseif k == Enum.KeyCode.Y or k == Enum.KeyCode.Z then
					if lit[redoButton] then
						options.press(redoButton)
					end
					redo()
				end
			end)
		)
	end

	return {
		open = open,
		record = function(
			name: string,
			idBefore: string?,
			before: History.Pose?,
			idAfter: string?,
			after: History.Pose?
		)
			if shown then
				history.record(name, idBefore, before, idAfter, after)
				refresh()
			end
		end,
		recordGroup = function(changes: { History.Change })
			if shown then
				history.recordGroup(changes)
				refresh()
			end
		end,
		refresh = function()
			if shown then
				refresh()
			end
		end,
		buttons = { undoButton, redoButton },
		destroy = function()
			stopListening()
			undoButton:Destroy()
			redoButton:Destroy()
		end,
	}
end

return ArrangeUndo
