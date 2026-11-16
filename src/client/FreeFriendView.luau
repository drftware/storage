--!strict
--[[
	FreeFriendView: Free a Friend on a free player's screen (S3-03b, GDD "Getting caught"). The
	moment: you're creeping down a hall when a friend's scream cuts off somewhere across the floor
	and their dot drops off the corner map. A beat later a warm pill eases in under the map with
	their face on it: "Free". Tap it, pay, and far off their film rips (you hear it, faint) as the
	pill swells and goes. DOORS' revive, bought for a friend from wherever you stand.

	One pill per caught friend (wrapped, or out of the climb), the longest caught first, at most
	`CutFree.FriendMost`, eased in `CutFree.FriendInAfter` after the catch. Shown only while you're
	free and Free a Friend is on sale here (the FreeFriend remote's `On`, as Cut Free's). A press
	answers at once: Cut Free's click, a spring, and the pill dims for `CutFree.AskEvery` while
	Roblox's prompt comes up (the server drops a second press as fast). A tap, or a click with a
	freed mouse (Left Alt); Y on a gamepad presses the top one, its key shown beside it. No price
	and no computer key: it never grabs at a player mid-chase. Cut Free's warm ink and fill.

	Studio only: Workspace's `DevFreeFriend`, set to a UserId, stands up a pill for that player as
	if they were a caught friend, so one player can see and press it (the server ignores the press:
	nobody of that id is here). Nothing is stepped: signals and tweens do it all.
]]
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Left = require(ReplicatedStorage.Shared.Left)
local Minimap = require(ReplicatedStorage.Shared.Minimap)

local STUDIO = RunService:IsStudio()
local DEV_ATTRIBUTE = "DevFreeFriend"
local ACTION = "FreeFriendPad"
local MAP_GAP = 10 -- the corner map's points from the top bar and the right edge (MinimapView)
local INK = Color3.fromRGB(CutFree.Ink.r, CutFree.Ink.g, CutFree.Ink.b)
local FILL = Color3.fromRGB(CutFree.Fill.r, CutFree.Fill.g, CutFree.Fill.b)
local WORD_MAX = 22 -- the word's largest size (pixels), so a big screen's pill stays a pill
local SLIDE = 28 -- points right of its place a pill eases in from
local EASE_IN = TweenInfo.new(CutFree.FriendIn, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EASE_OUT = TweenInfo.new(CutFree.FriendOut, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local MOVE = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local DIM = TweenInfo.new(CutFree.DimTime)

type Pill = {
	id: number,
	group: CanvasGroup,
	pop: UIScale,
	slot: number, -- its place in the column, from 1 at the top
	pressedAt: number, -- os.clock() of its last press taken
	going: boolean,
}

-- Whether `player` is caught now: wrapped, or out of the climb (left behind, carried up).
local function isCaught(player: Player): boolean
	return player:GetAttribute(Kept.Attribute) == true or player:GetAttribute(Left.Attribute) ~= nil
end

local function tween(target: Instance, info: TweenInfo, goal: { [string]: any }) -- any: tween goals
	TweenService:Create(target, info, goal):Play()
end

local FreeFriendView = {}

function FreeFriendView.new(): Brix.System
	local me = Players.LocalPlayer
	local gui: ScreenGui? = nil
	local column: Frame? = nil
	local keyLabel: TextLabel? = nil
	local click: Sound? = nil
	local rip: Sound? = nil
	local remote: RemoteEvent? = nil
	local pills: { [number]: Pill } = {} -- by the friend's UserId
	local since: { [number]: number } = {} -- os.clock() each friend was first seen caught
	local devSince = 0
	local bound = false
	local connections: { RBXScriptConnection } = {}
	local watched: { [Player]: { RBXScriptConnection } } = {}
	local refresh: () -> ()

	local function connect(c: RBXScriptConnection)
		table.insert(connections, c)
	end

	-- The column's place: right under the corner map, its right edge on the map's.
	local function layout()
		local c = column
		local camera = Workspace.CurrentCamera
		if not c or not camera then
			return
		end
		local view = camera.ViewportSize
		local side = math.floor(math.clamp(view.Y * Minimap.Side, Minimap.MinSide, Minimap.MaxSide))
		local bar = GuiService.TopbarInset
		local top = if bar.Height > 0 then bar.Max.Y + MAP_GAP else MAP_GAP
		local right = view.X - MAP_GAP
		if bar.Width > 0 then
			right = math.min(right, bar.Max.X)
		end
		c.Position = UDim2.fromOffset(right, top + side + CutFree.FriendGap)
	end

	local function yOf(slot: number): number
		return (slot - 1) * (CutFree.FriendTall + CutFree.FriendGap)
	end

	-- The gamepad's Y beside the top pill, only while a gamepad is what's in your hands.
	local function showKey()
		local k = keyLabel
		if not k then
			return
		end
		local pad = UserInputService:GetLastInputType().Name:find("Gamepad") ~= nil
		local any = false
		for _, pill in pills do
			if not pill.going then
				any = true
				break
			end
		end
		k.Visible = pad and any
	end

	local function press(pill: Pill)
		local now = os.clock()
		local r = remote
		if not r or pill.going or now - pill.pressedAt < CutFree.AskEvery then
			return
		end
		pill.pressedAt = now
		if click then
			click:Play()
		end
		pill.pop.Scale = CutFree.Pressed
		tween(pill.pop, PRESS, { Scale = 1 })
		tween(pill.group, DIM, { GroupTransparency = 1 - CutFree.Dim })
		task.delay(CutFree.AskEvery, function()
			if not pill.going then
				tween(pill.group, DIM, { GroupTransparency = 0 })
			end
		end)
		r:FireServer(pill.id)
	end

	local function makePill(id: number, slot: number): Pill
		local tall = CutFree.FriendTall
		local group = Instance.new("CanvasGroup")
		group.Name = `Friend{id}`
		group.AnchorPoint = Vector2.new(1, 0)
		group.Size = UDim2.fromOffset(math.floor(tall * CutFree.FriendWide), tall)
		group.Position = UDim2.new(1, SLIDE, 0, yOf(slot))
		group.BackgroundTransparency = 1
		group.GroupTransparency = 1
		local pop = Instance.new("UIScale")
		pop.Parent = group
		local button = Instance.new("TextButton")
		button.Name = "Button"
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Position = UDim2.fromScale(0.5, 0.5)
		button.Size = UDim2.new(1, -4, 1, -4) -- room for the ring inside the group's clip
		button.AutoButtonColor = false
		button.BackgroundColor3 = FILL
		button.BackgroundTransparency = CutFree.FillSee
		button.Text = ""
		button.Parent = group
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = button
		local ring = Instance.new("UIStroke")
		ring.Color = INK
		ring.Thickness = 2
		ring.Transparency = CutFree.RingSee
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Parent = button
		local faceSide = tall - 14
		local face = Instance.new("ImageLabel")
		face.Name = "Face"
		face.AnchorPoint = Vector2.new(0, 0.5)
		face.Position = UDim2.new(0, 5, 0.5, 0)
		face.Size = UDim2.fromOffset(faceSide, faceSide)
		face.BackgroundColor3 = INK
		face.BackgroundTransparency = 0.75
		face.Image = `rbxthumb://type=AvatarHeadShot&id={math.abs(id)}&w=48&h=48`
		face.Parent = button
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = face
		local word = Instance.new("TextLabel")
		word.Name = "Word"
		word.BackgroundTransparency = 1
		word.Position = UDim2.new(0, faceSide + 9, 0.22, 0)
		word.Size = UDim2.new(1, -(faceSide + 21), 0.56, 0)
		word.Font = Enum.Font.GothamBold
		word.Text = CutFree.FriendWord
		word.TextColor3 = INK
		word.TextScaled = true
		word.Parent = button
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = WORD_MAX
		limit.Parent = word
		local pill: Pill = {
			id = id,
			group = group,
			pop = pop,
			slot = slot,
			pressedAt = -math.huge,
			going = false,
		}
		button.Activated:Connect(function()
			press(pill)
		end)
		group.Parent = column
		tween(group, EASE_IN, { Position = UDim2.new(1, 0, 0, yOf(slot)), GroupTransparency = 0 })
		return pill
	end

	-- Takes `pill` away: with the far-off rip and a swell when the friend it named was just freed
	-- after your press, otherwise a quiet fade.
	local function goOut(pill: Pill, freed: boolean)
		pill.going = true
		pills[pill.id] = nil
		if freed then
			local r = rip
			if r then
				r.TimePosition = Kept.Rip.from
				r:Play()
				task.delay(Kept.Rip.length, function()
					r:Stop()
				end)
			end
			tween(pill.pop, EASE_OUT, { Scale = CutFree.FriendFreedSwell })
		end
		local out = TweenService:Create(pill.group, EASE_OUT, { GroupTransparency = 1 })
		out.Completed:Once(function()
			pill.group:Destroy()
		end)
		out:Play()
	end

	-- Matches the pills to who's caught now: new ones eased in, the freed taken away, the rest
	-- slid into place, longest caught at the top.
	function refresh()
		local now = os.clock()
		for _, p in Players:GetPlayers() do
			if p ~= me then
				if isCaught(p) then
					if since[p.UserId] == nil then
						since[p.UserId] = now
						task.delay(CutFree.FriendInAfter + 0.05, refresh)
					end
				else
					since[p.UserId] = nil
				end
			end
		end
		for id in since do
			local p = Players:GetPlayerByUserId(id)
			if p == nil or p == me then
				since[id] = nil
			end
		end
		local dev = if STUDIO then Workspace:GetAttribute(DEV_ATTRIBUTE) else nil
		local devId = if type(dev) == "number" then CutFree.friendId(dev) else nil

		local wanted: { { id: number, at: number } } = {}
		local r = remote
		local on = r ~= nil and r:GetAttribute(CutFree.OnAttribute) == true and not isCaught(me)
		if on then
			for id, at in since do
				if now - at >= CutFree.FriendInAfter then
					table.insert(wanted, { id = id, at = at })
				end
			end
			if devId and since[devId] == nil then
				table.insert(wanted, { id = devId, at = devSince })
			end
			table.sort(wanted, function(a, b)
				return a.at < b.at
			end)
		end
		local slotOf: { [number]: number } = {}
		for i, w in wanted do
			if i > CutFree.FriendMost then
				break
			end
			slotOf[w.id] = i
		end
		for id, pill in pills do
			if slotOf[id] == nil then
				local friend = Players:GetPlayerByUserId(id)
				local freed = on
					and friend ~= nil
					and since[id] == nil
					and now - pill.pressedAt <= CutFree.FriendHeardFor
				goOut(pill, freed)
			end
		end
		for id, slot in slotOf do
			local pill = pills[id]
			if pill == nil then
				pills[id] = makePill(id, slot)
			elseif pill.slot ~= slot then
				pill.slot = slot
				tween(pill.group, MOVE, { Position = UDim2.new(1, 0, 0, yOf(slot)) })
			end
		end
		local top: Pill? = nil
		for _, pill in pills do
			if pill.slot == 1 then
				top = pill
			end
		end
		local wantBound = top ~= nil
		if wantBound ~= bound then
			bound = wantBound
			if bound then
				ContextActionService:BindAction(
					ACTION,
					function(_: string, state: Enum.UserInputState): Enum.ContextActionResult
						if state ~= Enum.UserInputState.Begin then
							return Enum.ContextActionResult.Pass
						end
						for _, pill in pills do
							if pill.slot == 1 then
								press(pill)
								return Enum.ContextActionResult.Sink
							end
						end
						return Enum.ContextActionResult.Pass
					end,
					false,
					Enum.KeyCode.ButtonY
				)
			else
				ContextActionService:UnbindAction(ACTION)
			end
		end
		showKey()
	end

	local function watch(player: Player)
		if watched[player] then
			return
		end
		watched[player] = {
			player:GetAttributeChangedSignal(Kept.Attribute):Connect(refresh),
			player:GetAttributeChangedSignal(Left.Attribute):Connect(refresh),
		}
	end

	local function unwatch(player: Player)
		local list = watched[player]
		if list then
			for _, c in list do
				c:Disconnect()
			end
		end
		watched[player] = nil
	end

	local function found(r: Instance)
		if r.Name == CutFree.FriendRemote and r:IsA("RemoteEvent") then
			remote = r
			connect(r:GetAttributeChangedSignal(CutFree.OnAttribute):Connect(refresh))
			refresh()
		end
	end

	local system = { name = "FreeFriendView" }

	function system.start(_: any, _context: Brix.Context)
		local g = Instance.new("ScreenGui")
		g.Name = "FreeFriend"
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
		g.DisplayOrder = 4 -- the corner map's
		local c = Instance.new("Frame")
		c.Name = "Column"
		c.AnchorPoint = Vector2.new(1, 0)
		c.Size = UDim2.fromOffset(math.floor(CutFree.FriendTall * CutFree.FriendWide), 1)
		c.BackgroundTransparency = 1
		c.Parent = g
		local k = Instance.new("TextLabel")
		k.Name = "Key"
		k.AnchorPoint = Vector2.new(1, 0.5)
		k.Position = UDim2.fromOffset(-8, CutFree.FriendTall / 2)
		k.Size = UDim2.fromOffset(28, 28)
		k.BackgroundColor3 = FILL
		k.BackgroundTransparency = CutFree.FillSee
		k.Font = Enum.Font.GothamBold
		k.Text = "Y"
		k.TextSize = 18
		k.TextColor3 = INK
		k.Visible = false
		k.Parent = c
		local kc = Instance.new("UICorner")
		kc.CornerRadius = UDim.new(0.5, 0)
		kc.Parent = k
		local s = Instance.new("Sound")
		s.Name = "FreeFriendClick"
		s.SoundId = CutFree.Click.id
		s.PlaybackSpeed = CutFree.Click.pitch
		s.Volume = CutFree.Click.volume
		s.Parent = g
		local rs = Instance.new("Sound")
		rs.Name = "FreeFriendRip"
		rs.SoundId = Kept.Rip.id
		rs.PlaybackSpeed = Kept.Rip.pitch
		rs.Volume = CutFree.FriendRipVolume
		rs.Parent = g
		g.Parent = me:WaitForChild("PlayerGui")
		gui, column, keyLabel, click, rip = g, c, k, s, rs
		layout()

		local camera = Workspace.CurrentCamera
		if camera then
			connect(camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout))
		end
		connect(GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layout))
		connect(UserInputService.LastInputTypeChanged:Connect(showKey))
		for _, p in Players:GetPlayers() do
			watch(p)
		end
		connect(Players.PlayerAdded:Connect(function(p: Player)
			watch(p)
			refresh()
		end))
		connect(Players.PlayerRemoving:Connect(function(p: Player)
			unwatch(p)
			task.defer(refresh)
		end))
		if STUDIO then
			connect(Workspace:GetAttributeChangedSignal(DEV_ATTRIBUTE):Connect(function()
				devSince = os.clock()
				refresh()
			end))
		end
		local folder = ReplicatedStorage:FindFirstChild(Caught.RemoteFolder)
		if folder then
			connect(folder.ChildAdded:Connect(found))
			for _, r in folder:GetChildren() do
				found(r)
			end
		else
			connect(ReplicatedStorage.ChildAdded:Connect(function(f: Instance)
				if f.Name == Caught.RemoteFolder then
					connect(f.ChildAdded:Connect(found))
					for _, r in f:GetChildren() do
						found(r)
					end
				end
			end))
		end
		refresh()
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for p in watched do
			unwatch(p)
		end
		if bound then
			ContextActionService:UnbindAction(ACTION)
			bound = false
		end
		table.clear(pills)
		table.clear(since)
		if gui then
			gui:Destroy()
			gui = nil
		end
	end

	return system
end

return FreeFriendView
