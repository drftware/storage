--!strict
--[[
	FreeCursor: Left Alt lets go of a computer player's mouse and Alt again takes it back. First
	person pins the mouse to the middle of the screen, so without this you can't grab a screenshot
	or reach another window. The mouse is either the view or a cursor, never both: while it turns
	the view no cursor is drawn, and when Alt frees it the cursor appearing is the answer. The first
	time you spawn, a small hint shows the key, then fades. Mouse players only: a phone or a gamepad
	gets none of it.

	The mouse goes free while a visible GuiButton has Modal set. Holding the right mouse button
	still turns the view while it's free, so the cursor hides for that too. A screen you click on
	(the elevator's keypad, KeypadPad) asks for the mouse with `need` while it's open, and gets it
	back as it was when it closes. Roblox's own menu shows
	its cursor whatever we set (docs/STUDIO.md, "Freeing the mouse"). Brix has no input piece, so
	this one is the game's own.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Brix = require(ReplicatedStorage.Brix)

-- The key that lets go of the mouse and takes it back (Option on a Mac). Named in OWNER.md.
local KEY = Enum.KeyCode.LeftAlt
-- Seconds after you first spawn before the hint shows: a moment to look around first, and it's up
-- before you'd go looking for the cursor.
local HINT_DELAY = 3
-- Seconds the hint stays fully up: long enough to read two words twice, gone before it's furniture.
local HINT_HOLD = 6
-- How the hint arrives: a short fade while it rises a few pixels, so it eases in and never pops.
local HINT_IN = 0.35
local HINT_RISE = 8
-- How the hint leaves, in seconds: slower than it came, so it melts back into the dark.
local HINT_OUT = 0.9
-- How far the hint sits above the bottom edge, in pixels: clear of a hotbar row.
local HINT_LIFT = 72

local INK = Color3.fromRGB(232, 226, 214) -- warm off-white, like the tubes' light on paper
local BACKING = Color3.fromRGB(12, 12, 14)

local FreeCursor = {}

local function label(text: string, weight: Enum.Font, size: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AutomaticSize = Enum.AutomaticSize.X
	l.Size = UDim2.fromOffset(0, 22)
	l.Font = weight
	l.TextSize = size
	l.TextColor3 = INK
	l.Text = text
	return l
end

-- The hint: a key cap and one word on a dark pill, starting invisible and a little low.
local function makeHint(): CanvasGroup
	local hint = Instance.new("CanvasGroup")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -HINT_LIFT + HINT_RISE)
	hint.AutomaticSize = Enum.AutomaticSize.XY
	hint.BackgroundColor3 = BACKING
	hint.BackgroundTransparency = 0.25
	hint.GroupTransparency = 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = hint
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = hint
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.Padding = UDim.new(0, 8)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = hint

	local cap = label("Alt", Enum.Font.BuilderSansBold, 14)
	cap.Name = "Key"
	cap.LayoutOrder = 1
	local capCorner = Instance.new("UICorner")
	capCorner.CornerRadius = UDim.new(0, 5)
	capCorner.Parent = cap
	local capStroke = Instance.new("UIStroke")
	capStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	capStroke.Color = INK
	capStroke.Transparency = 0.45
	capStroke.Parent = cap
	local capPadding = Instance.new("UIPadding")
	capPadding.PaddingLeft = UDim.new(0, 7)
	capPadding.PaddingRight = UDim.new(0, 7)
	capPadding.Parent = cap
	cap.Parent = hint

	local word = label("Cursor", Enum.Font.BuilderSansMedium, 16)
	word.Name = "Word"
	word.LayoutOrder = 2
	word.Parent = hint
	return hint
end

-- What a screen calls to have the mouse free while it's open (`on`) and to let it go (`who`
-- names the screen, so two can ask at once).
export type Need = (who: string, on: boolean) -> ()

-- The system, and `need`.
function FreeCursor.new(): (Brix.System, Need)
	local gui: ScreenGui? = nil
	local release: TextButton? = nil
	local hint: CanvasGroup? = nil
	local hintThread: thread? = nil
	local free = false
	local needed: { [string]: true } = {} -- screens open that need the mouse
	local turning = false -- the right mouse button is down, so the mouse turns the view
	local iconWas = true -- the cursor's visibility before start, put back on stop
	local connections: { RBXScriptConnection } = {}

	-- Free when Alt let it go or a screen needs it.
	local function isFree(): boolean
		return free or next(needed) ~= nil
	end

	-- A cursor is drawn only while it's a cursor: free, and not turning the view. The button
	-- whose Modal frees it shows exactly then.
	local function drawCursor()
		local on = isFree()
		if release then
			release.Visible = on
		end
		if gui then
			UserInputService.MouseIconEnabled = on and not turning
		end
	end

	-- Fades the hint out and lets it go; it never comes back this session.
	local function leave()
		local h = hint
		if not h then
			return
		end
		hint = nil
		local out = TweenService:Create(
			h,
			TweenInfo.new(HINT_OUT, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ GroupTransparency = 1 }
		)
		out.Completed:Once(function()
			h:Destroy()
		end)
		out:Play()
	end

	local function showHint()
		local h = hint
		if not h then
			return
		end
		TweenService:Create(
			h,
			TweenInfo.new(HINT_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ GroupTransparency = 0, Position = UDim2.new(0.5, 0, 1, -HINT_LIFT) }
		):Play()
		task.wait(HINT_IN + HINT_HOLD)
		hintThread = nil
		leave()
	end

	local function scheduleHint()
		if hint and not hintThread then
			hintThread = task.delay(HINT_DELAY, showHint)
		end
	end

	-- Whoever presses the key has found it, so the hint, shown or still waiting, goes.
	local function dismissHint()
		if hintThread then
			task.cancel(hintThread)
			hintThread = nil
		end
		leave()
	end

	local function setFree(on: boolean)
		free = on
		drawCursor()
		dismissHint()
	end

	local function need(who: string, on: boolean)
		if on then
			needed[who] = true
		else
			needed[who] = nil
		end
		drawCursor()
	end

	local system: Brix.System = {
		name = "FreeCursor",
		start = function(_: any, _context: Brix.Context)
			-- No mouse, nothing to free: phones and gamepads never see the key or the hint.
			if not UserInputService.MouseEnabled then
				return
			end
			local player = Players.LocalPlayer
			local screen = Instance.new("ScreenGui")
			screen.Name = "FreeCursor"
			screen.ResetOnSpawn = false -- a free cursor and a used-up hint survive a respawn
			screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

			-- Invisible, one pixel in the corner, and shown only while the mouse is free: Modal is
			-- what lets the mouse go. It takes no clicks you'd miss and is never a gamepad target.
			local button = Instance.new("TextButton")
			button.Name = "Release"
			button.Size = UDim2.fromOffset(1, 1)
			button.BackgroundTransparency = 1
			button.Text = ""
			button.AutoButtonColor = false
			button.Selectable = false
			button.Modal = true
			button.Visible = false
			button.Parent = screen
			release = button

			local h = makeHint()
			h.Parent = screen
			hint = h

			screen.Parent = player:WaitForChild("PlayerGui")
			gui = screen

			iconWas = UserInputService.MouseIconEnabled
			drawCursor()

			table.insert(
				connections,
				UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
					-- The right button turns the view wherever the cursor is, even over a button.
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						turning = true
						drawCursor()
						return
					end
					-- Processed means a text box or Roblox's own menu has the key. While a screen
					-- has the mouse, Alt is that screen's (Arrange's Free, S5-03j2b2b): it must not
					-- leave the mouse let go behind it when the screen closes.
					if processed or input.KeyCode ~= KEY or next(needed) ~= nil then
						return
					end
					setFree(not free)
				end)
			)
			table.insert(
				connections,
				UserInputService.InputEnded:Connect(function(input: InputObject)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						turning = false
						drawCursor()
					end
				end)
			)
			-- Leaving the window can swallow the button's release; don't strand a hidden cursor.
			table.insert(
				connections,
				UserInputService.WindowFocusReleased:Connect(function()
					turning = false
					drawCursor()
				end)
			)
			if player.Character then
				scheduleHint()
			else
				table.insert(connections, player.CharacterAdded:Once(scheduleHint))
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			if hintThread then
				task.cancel(hintThread)
				hintThread = nil
			end
			if gui then
				gui:Destroy() -- the mouse goes back to the camera with the button
				gui = nil
				UserInputService.MouseIconEnabled = iconWas
			end
			release = nil
			hint = nil
			free = false
			table.clear(needed)
			turning = false
		end,
	}
	return system, need
end

return FreeCursor
