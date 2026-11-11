--!strict
--[[
	MinimapView: the corner map (L-10, D-094). Deep in the building with a keeper behind you, a
	glance at the top-right corner shows the way back to the lobby and the gate. It slides in as
	you arrive on a floor and out as you leave it. The window follows you, so you're always its
	middle, an arrow pointing the way you look; the halls you walk fill in (`MinimapDrawing`), the
	lobby and the car are drawn from the start, and while the car is off the window an amber
	marker waits on the edge the way it lies. Units anyone has opened are ticked (the server's
	list, `Minimap.OpenedAttribute`). Friends are blue dots, held on the edge when they're off it,
	as Lethal Company's ship radar shows the crew (`Minimap.Friends`, D-091). Never keepers or
	lit lights: that's the office light board's job.

	A friend kept in a unit drops off the map (L-07c): they're found by their banging. Each bang
	(`Kept.BangsAttribute`, from KeptPlayers) puts a bigger blue dot on their unit with a ring
	going out from it, held on the edge the way it lies while it's off the window, as the car's
	mark is; it fades `Kept.BangMark` seconds after the last bang, as BangMarks' mark over the door.

	Each floor's map comes from its model (`Minimap.Tag`, from `Minimaps` on the server) and is
	drawn the first time you stand on it; what you walked stays drawn if you're caught or leave and
	come back. Each frame it only reads where you stand, unless a map shows.
]]
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Minimap = require(ReplicatedStorage.Shared.Minimap)
local MinimapDrawing = require(script.Parent.MinimapDrawing)

-- The window's look.
local WINDOW = Color3.fromRGB(14, 14, 16)
local WINDOW_SEE = 0.15 -- its background's transparency: a little of the hall, not enough to tint it
local RIM = Color3.fromRGB(230, 226, 214)
local RIM_SEE = 0.65
local GAP = 10 -- points between the window and the top bar, and the screen's right edge
local YOU = Color3.fromRGB(250, 248, 240)
local YOU_SIZE = 9 -- points across your dot (its nose points the way you look): a door beside you still shows
local FRIEND = Color3.fromRGB(110, 186, 255)
local FRIEND_SIZE = 8
local FRIEND_HELD = 0.35 -- a friend held on the edge shows this see-through, a step back
local CAR_MARK = Color3.fromRGB(236, 184, 62)
local BANG_SIZE = 11 -- points: a kept friend's banging unit, a step bigger than a friend's dot
local BANG_RING = 3 -- a bang's ring grows to this many dots across
local BANG_RING_TIME = 0.75 -- seconds, as the mark over the door
local CAR_SIZE = 10
local EDGE = 7 -- points in from the window's edge a held marker sits
local MOVED = 0.5 -- studs you move before the map checks which hall you're on again
local MARK_FADE = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SLIDE = TweenInfo.new(Minimap.Slide, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

type Area = {
	model: Instance,
	map: Minimap.Map,
	origin: CFrame,
	opened: { [number]: boolean },
	drawing: MinimapDrawing.Drawing?,
	carX: number, -- the car's middle, on the floor
	carZ: number,
	watch: RBXScriptConnection,
	bangs: { Kept.Bang }, -- its units' latest bangs, from the server
	bangWatch: RBXScriptConnection,
	units: { [number]: Vector2 }, -- each unit's middle on the floor, by slot
}

-- A banging unit's dot on the window, with the ring each bang sends out.
type BangDot = {
	dot: Frame,
	rim: UIStroke,
	ring: Frame,
	ringStroke: UIStroke,
	at: number, -- the bang it last rang for (the server's clock)
	rang: number, -- os.clock of its ring, or -1
	seen: boolean, -- still on the list this frame
}

local MinimapView = {}

function MinimapView.new(): Brix.System
	local me = Players.LocalPlayer
	local areas: { [Instance]: Area } = {}
	local connections: { RBXScriptConnection } = {}
	local friends: { [Player]: Frame } = {}
	local shown: Area? = nil
	local out = true -- slid off the screen
	local side, scale = 0, 1
	local lastX, lastZ = math.huge, math.huge

	local gui = Instance.new("ScreenGui")
	gui.Name = "Minimap"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 4

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.AnchorPoint = Vector2.new(1, 0)
	window.BackgroundColor3 = WINDOW
	window.BackgroundTransparency = WINDOW_SEE
	window.ClipsDescendants = true
	window.Visible = false
	window.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = window
	local rim = Instance.new("UIStroke")
	rim.Color = RIM
	rim.Transparency = RIM_SEE
	rim.Thickness = 1.5
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = window

	local function dot(size: number, colour: Color3, z: number): Frame
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromOffset(size, size)
		f.BackgroundColor3 = colour
		f.BorderSizePixel = 0
		f.ZIndex = z
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
		return f
	end

	-- you: a dot with a nose, turned the way you look
	local you = Instance.new("Frame")
	you.Name = "You"
	you.AnchorPoint = Vector2.new(0.5, 0.5)
	you.Position = UDim2.fromScale(0.5, 0.5)
	you.Size = UDim2.fromOffset(YOU_SIZE, YOU_SIZE)
	you.BackgroundTransparency = 1
	you.ZIndex = 6
	you.Parent = window
	local body = dot(YOU_SIZE, YOU, 7)
	body.Position = UDim2.fromScale(0.5, 0.5)
	local ring = Instance.new("UIStroke")
	ring.Color = WINDOW
	ring.Thickness = 1.5
	ring.Parent = body
	body.Parent = you
	local nose = Instance.new("Frame")
	nose.AnchorPoint = Vector2.new(0.5, 0.5)
	nose.Size = UDim2.fromOffset(YOU_SIZE * 0.62, YOU_SIZE * 0.62)
	nose.Position = UDim2.new(0.5, 0, 0.5, -YOU_SIZE * 0.5)
	nose.Rotation = 45
	nose.BackgroundColor3 = YOU
	nose.BorderSizePixel = 0
	nose.ZIndex = 6
	nose.Parent = you

	-- the car, while it's off the window: an amber mark on the edge the way it lies
	local carMark = dot(CAR_SIZE, CAR_MARK, 5)
	carMark.Name = "Gate"
	carMark.BackgroundTransparency = 1
	local carRim = Instance.new("UIStroke")
	carRim.Color = WINDOW
	carRim.Thickness = 1.5
	carRim.Transparency = 1
	carRim.Parent = carMark
	carMark.Parent = window
	local carHeld = false

	-- kept friends' banging units, by slot, on the floor shown
	local bangDots: { [number]: BangDot } = {}

	local function bangDot(): BangDot
		local halo = dot(BANG_SIZE, CAR_MARK, 5)
		halo.Name = "BangRing"
		halo.BackgroundTransparency = 1
		local haloStroke = Instance.new("UIStroke")
		haloStroke.Color = FRIEND
		haloStroke.Thickness = 2
		haloStroke.Transparency = 1
		haloStroke.Parent = halo
		halo.Parent = window
		local d = dot(BANG_SIZE, FRIEND, 5)
		d.Name = "Banging"
		local outline = Instance.new("UIStroke")
		outline.Color = YOU
		outline.Thickness = 1.5
		outline.Parent = d
		d.Parent = window
		return {
			dot = d,
			rim = outline,
			ring = halo,
			ringStroke = haloStroke,
			at = -math.huge,
			rang = -1,
			seen = false,
		}
	end

	local function clearBangs()
		for slot, b in bangDots do
			b.dot:Destroy()
			b.ring:Destroy()
			bangDots[slot] = nil
		end
	end

	local function fadeMark(on: boolean)
		if on == carHeld then
			return
		end
		carHeld = on
		local to = if on then 0 else 1
		TweenService:Create(carMark, MARK_FADE, { BackgroundTransparency = to }):Play()
		TweenService:Create(carRim, MARK_FADE, { Transparency = to }):Play()
	end

	-- The window's size and its place for this screen: top right, under the top bar.
	local function places(): (UDim2, UDim2)
		local camera = Workspace.CurrentCamera
		local view = if camera then camera.ViewportSize else Vector2.new(1280, 720)
		side = math.floor(math.clamp(view.Y * Minimap.Side, Minimap.MinSide, Minimap.MaxSide))
		scale = side / Minimap.Span
		local free = GuiService.TopbarInset
		local top = if free.Height > 0 then free.Max.Y + GAP else GAP
		local right = view.X - GAP
		if free.Width > 0 then
			right = math.min(right, free.Max.X)
		end
		return UDim2.fromOffset(right, top), UDim2.fromOffset(view.X + side + GAP, top)
	end

	local function layout()
		local inPlace, offScreen = places()
		window.Size = UDim2.fromOffset(side, side)
		window.Position = if out then offScreen else inPlace
		local a = shown
		if a and a.drawing then
			a.drawing:scale(scale)
		end
		lastX = math.huge -- re-place the canvas
	end

	local function slide(on: boolean)
		if out == not on then
			return
		end
		out = not on
		local inPlace, offScreen = places()
		if on then
			window.Visible = true
		end
		local tween =
			TweenService:Create(window, SLIDE, { Position = if on then inPlace else offScreen })
		tween:Play()
	end

	local function show(a: Area?)
		local was = shown
		if was == a then
			return
		end
		if was and was.drawing then
			was.drawing.canvas.Visible = false
		end
		clearBangs()
		shown = a
		lastX = math.huge
		if not a then
			slide(false)
			return
		end
		local d = a.drawing or MinimapDrawing.new(a.map, window)
		a.drawing = d
		d:scale(scale)
		d:open(a.opened)
		d.canvas.Visible = true
		slide(true)
	end

	local function readOpened(a: Area)
		local text = a.model:GetAttribute(Minimap.OpenedAttribute)
		a.opened = if type(text) == "string" then Minimap.decodeOpened(text) else {}
		local d = a.drawing
		if d then
			d:open(a.opened)
		end
	end

	local function added(model: Instance)
		if areas[model] then
			return
		end
		local text = model:GetAttribute(Minimap.LayoutAttribute)
		local origin = model:GetAttribute(Minimap.OriginAttribute)
		local map = if type(text) == "string" then Minimap.decode(text) else nil
		if not (map and typeof(origin) == "CFrame") then
			warn(`MinimapView: {model:GetFullName()} has no map to draw`)
			return
		end
		local car = map.pieces[map.elevator].rects[1]
		local units: { [number]: Vector2 } = {}
		for _, u in map.units do
			units[u.slot] = Vector2.new((u.rect.x0 + u.rect.x1) / 2, (u.rect.z0 + u.rect.z1) / 2)
		end
		local function readBangs()
			local now = areas[model]
			if now then
				local said = model:GetAttribute(Kept.BangsAttribute)
				now.bangs = if type(said) == "string" then Kept.decodeBangs(said) else {}
			end
		end
		local a: Area = {
			model = model,
			map = map,
			origin = origin,
			opened = {},
			drawing = nil,
			carX = (car.x0 + car.x1) / 2,
			carZ = (car.z0 + car.z1) / 2,
			watch = model:GetAttributeChangedSignal(Minimap.OpenedAttribute):Connect(function()
				local now = areas[model]
				if now then
					readOpened(now)
				end
			end),
			bangs = {},
			bangWatch = model:GetAttributeChangedSignal(Kept.BangsAttribute):Connect(readBangs),
			units = units,
		}
		areas[model] = a
		readOpened(a)
		readBangs()
	end

	local function removed(model: Instance)
		local a = areas[model]
		if not a then
			return
		end
		areas[model] = nil
		a.watch:Disconnect()
		a.bangWatch:Disconnect()
		if shown == a then
			show(nil)
		end
		local d = a.drawing
		if d then
			d:destroy()
		end
	end

	-- the floor a world point stands on, and where on it
	local function standing(at: Vector3): (Area?, number, number)
		local a = shown
		if a then
			local p = a.origin:PointToObjectSpace(at)
			if
				math.abs(p.Y) <= Minimap.Height and Minimap.near(a.map, p.X, p.Z, Minimap.Margin)
			then
				return a, p.X, p.Z
			end
		end
		for _, b in areas do
			local p = b.origin:PointToObjectSpace(at)
			if
				math.abs(p.Y) <= Minimap.Height and Minimap.near(b.map, p.X, p.Z, Minimap.Margin)
			then
				return b, p.X, p.Z
			end
		end
		return nil, 0, 0
	end

	local function rootOf(player: Player): BasePart?
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		return if root and root:IsA("BasePart") then root else nil
	end

	local function joined(player: Player)
		if player == me or friends[player] or not Minimap.Friends then
			return
		end
		local f = dot(FRIEND_SIZE, FRIEND, 4)
		f.Name = "Friend"
		f.Visible = false
		local r = Instance.new("UIStroke")
		r.Color = WINDOW
		r.Thickness = 1
		r.Parent = f
		f.Parent = window
		friends[player] = f
	end

	local function left(player: Player)
		local f = friends[player]
		if f then
			f:Destroy()
			friends[player] = nil
		end
	end

	local system = { name = "MinimapView" }

	function system.start(_: any, _context: Brix.Context)
		-- the map owns the top-right corner, where Roblox's player list would open over it
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		gui.Parent = me:WaitForChild("PlayerGui")
		layout()
		local camera = Workspace.CurrentCamera
		if camera then
			table.insert(
				connections,
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
			)
		end
		table.insert(
			connections,
			GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layout)
		)
		for _, model in CollectionService:GetTagged(Minimap.Tag) do
			added(model)
		end
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Minimap.Tag):Connect(added)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Minimap.Tag):Connect(removed)
		)
		for _, p in Players:GetPlayers() do
			joined(p)
		end
		table.insert(connections, Players.PlayerAdded:Connect(joined))
		table.insert(connections, Players.PlayerRemoving:Connect(left))
	end

	function system.step(_: any, _dt: number)
		local root = rootOf(me)
		if not root then
			show(nil)
			return
		end
		local a, x, z = standing(root.Position)
		show(a)
		if not a then
			return
		end
		local d = a.drawing
		if not d then
			return
		end
		local half = side / 2
		if math.abs(x - lastX) + math.abs(z - lastZ) >= MOVED then
			lastX, lastZ = x, z
			local piece = Minimap.at(a.map, x, z)
			if piece then
				d:walk(piece)
			end
		end
		d:place(half, half, x, z)

		-- the way you look, on the map: +X right, +Z down
		local camera = Workspace.CurrentCamera
		if camera then
			local look = a.origin:VectorToObjectSpace(camera.CFrame.LookVector)
			if look.X * look.X + look.Z * look.Z > 1e-4 then
				you.Rotation = math.deg(math.atan2(look.X, -look.Z))
			end
		end

		local cx, cy, held = Minimap.edge((a.carX - x) * scale, (a.carZ - z) * scale, half - EDGE)
		fadeMark(held)
		if held then
			carMark.Position = UDim2.fromOffset(half + cx, half + cy)
		end

		-- kept friends' units, as they bang
		local now = Workspace:GetServerTimeNow()
		local clock = os.clock()
		for _, b in bangDots do
			b.seen = false
		end
		for _, bang in a.bangs do
			local level = Kept.mark(now - bang.at)
			local at = a.units[bang.slot]
			if bang.user == me.UserId or level <= 0 or not at then
				continue
			end
			local b = bangDots[bang.slot]
			if not b then
				b = bangDot()
				bangDots[bang.slot] = b
			end
			b.seen = true
			if bang.at > b.at then
				b.at, b.rang = bang.at, clock
			end
			local bx, by = Minimap.edge((at.X - x) * scale, (at.Y - z) * scale, half - EDGE)
			local place = UDim2.fromOffset(half + bx, half + by)
			b.dot.Position, b.ring.Position = place, place
			b.dot.BackgroundTransparency = 1 - level
			b.rim.Transparency = 1 - level
			local p = if b.rang >= 0 then (clock - b.rang) / BANG_RING_TIME else 1
			if p < 1 then
				local across = BANG_SIZE * (1 + (BANG_RING - 1) * (1 - (1 - p) * (1 - p)))
				b.ring.Size = UDim2.fromOffset(across, across)
				b.ringStroke.Transparency = 1 - (1 - p) * level
			elseif b.rang >= 0 then
				b.rang = -1
				b.ringStroke.Transparency = 1
			end
		end
		for slot, b in bangDots do
			if not b.seen then
				b.dot:Destroy()
				b.ring:Destroy()
				bangDots[slot] = nil
			end
		end

		for player, f in friends do
			local r = rootOf(player)
			-- a kept friend is found by their banging, not their dot
			local p = if r and player:GetAttribute(Kept.Attribute) ~= true
				then a.origin:PointToObjectSpace(r.Position)
				else nil
			if
				p
				and math.abs(p.Y) <= Minimap.Height
				and Minimap.near(a.map, p.X, p.Z, Minimap.Margin)
			then
				local fx, fy, away = Minimap.edge((p.X - x) * scale, (p.Z - z) * scale, half - EDGE)
				f.Position = UDim2.fromOffset(half + fx, half + fy)
				f.BackgroundTransparency = if away then FRIEND_HELD else 0
				f.Visible = true
			else
				f.Visible = false
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for model in areas do
			removed(model)
		end
		clearBangs()
		gui:Destroy()
	end

	return system :: any -- any: a plain Brix system built field by field
end

return MinimapView
