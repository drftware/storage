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

	The floor's big find (S4-05b2b, D-417) is a pink diamond: on its unit the instant the door
	rolls up by itself, three rings going out from it so the whole team looks; then where it lies,
	or round its hauler's dot while someone carries it, a ring each time it changes hands or is
	put down, held on the edge the way it lies while it's off the window, as the car's mark is
	(the server's `BigFind` attributes on the floor's model, from BigFinds). Lethal Company's ship
	radar shows the crew; Among Us's map shows where the task is.

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

local BigFind = require(ReplicatedStorage.Shared.BigFind)
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
local BIG = Color3.fromRGB(255, 92, 168) -- the big find's mark: hot pink, apart from the car's amber, friends' blue, your white
local BIG_SIZE = 10 -- points: its diamond's side on its unit or where it lies, a step over a friend's dot
local BIG_HELD = 13 -- points: round its hauler's dot, which shows inside it
local BIG_RING = 3.2 -- each of its rings grows to this many diamonds across
local BIG_RING_TIME = 0.7 -- seconds a ring of its takes; one follows another
local BIG_POP = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
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
	-- its big find, from the server (BigFind's attributes on the model)
	big: BigFind.Mark?,
	bigSlot: number?,
	bigHolder: number?,
	bigAt: Vector3?,
	bigWatch: { RBXScriptConnection },
	bigRang: number, -- os.clock its rings started, or -1
	bigRings: number, -- how many go out from then
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

	-- the floor's big find: a pink diamond, its rings going out from under it
	local bigRing = dot(BIG_SIZE, BIG, 3)
	bigRing.Name = "BigFindRing"
	bigRing.BackgroundTransparency = 1
	bigRing.Visible = false
	local bigRingStroke = Instance.new("UIStroke")
	bigRingStroke.Color = BIG
	bigRingStroke.Thickness = 2
	bigRingStroke.Parent = bigRing
	bigRing.Parent = window
	local bigMark = Instance.new("Frame")
	bigMark.Name = "BigFind"
	bigMark.AnchorPoint = Vector2.new(0.5, 0.5)
	bigMark.Size = UDim2.fromOffset(BIG_SIZE, BIG_SIZE)
	bigMark.Rotation = 45
	bigMark.BackgroundColor3 = BIG
	bigMark.BorderSizePixel = 0
	bigMark.ZIndex = 3 -- under a friend's dot, so its hauler shows inside it
	bigMark.Visible = false
	local bigCorner = Instance.new("UICorner")
	bigCorner.CornerRadius = UDim.new(0, 2)
	bigCorner.Parent = bigMark
	local bigRim = Instance.new("UIStroke")
	bigRim.Color = YOU
	bigRim.Thickness = 1.5
	bigRim.Parent = bigMark
	local bigPop = Instance.new("UIScale")
	bigPop.Parent = bigMark
	bigMark.Parent = window

	-- its mark pops in as it shows: grown from nothing, a little past its size and back
	local function popBig()
		bigPop.Scale = 0
		TweenService:Create(bigPop, BIG_POP, { Scale = 1 }):Play()
	end

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
		bigMark.Visible, bigRing.Visible = false, false
		if not a then
			slide(false)
			return
		end
		if a.big then
			-- arriving on a floor whose big find is out: its rings, so you look
			a.bigRang, a.bigRings = os.clock(), BigFind.Rings
			popBig()
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

	-- Where the floor's big find is, from the server; its rings as that changes.
	local function readBig(a: Area)
		local m = a.model
		local slot = m:GetAttribute(BigFind.SlotAttribute)
		local holder = m:GetAttribute(BigFind.HolderAttribute)
		local at = m:GetAttribute(BigFind.AtAttribute)
		local s: number? = if type(slot) == "number" then slot else nil
		local h: number? = if type(holder) == "number" then holder else nil
		local p: Vector3? = if typeof(at) == "Vector3" then at else nil
		local was = a.big
		local now = BigFind.mark(s, h, p ~= nil)
		local moved = now ~= was or h ~= a.bigHolder or p ~= a.bigAt
		a.big, a.bigSlot, a.bigHolder, a.bigAt = now, s, h, p
		if not moved then
			return
		end
		local rings = BigFind.rings(was, now)
		if rings > 0 then
			a.bigRang, a.bigRings = os.clock(), rings
			if was == nil and shown == a then
				popBig()
			end
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
			big = nil,
			bigWatch = {},
			bigRang = -1,
			bigRings = 0,
		}
		for _, name in { BigFind.SlotAttribute, BigFind.HolderAttribute, BigFind.AtAttribute } do
			table.insert(
				a.bigWatch,
				model:GetAttributeChangedSignal(name):Connect(function()
					local now = areas[model]
					if now then
						readBig(now)
					end
				end)
			)
		end
		areas[model] = a
		readOpened(a)
		readBangs()
		readBig(a)
		a.bigRang = -1 -- what was out before you joined rings as its floor shows (`show`)
	end

	local function removed(model: Instance)
		local a = areas[model]
		if not a then
			return
		end
		areas[model] = nil
		a.watch:Disconnect()
		a.bangWatch:Disconnect()
		for _, c in a.bigWatch do
			c:Disconnect()
		end
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

		-- the floor's big find: round its hauler, where it lies, or on its unit
		local kind = a.big
		local bx, bz, bigOn = 0, 0, false
		if kind == "Held" then
			local hauler = if a.bigHolder then Players:GetPlayerByUserId(a.bigHolder) else nil
			local r = if hauler then rootOf(hauler) else nil
			if r then
				local p = a.origin:PointToObjectSpace(r.Position)
				bx, bz, bigOn = p.X, p.Z, true
			end
		elseif kind == "Lying" and a.bigAt then
			local p = a.origin:PointToObjectSpace(a.bigAt)
			bx, bz, bigOn = p.X, p.Z, true
		elseif kind == "Unit" and a.bigSlot then
			local u = a.units[a.bigSlot]
			if u then
				bx, bz, bigOn = u.X, u.Y, true
			end
		end
		bigMark.Visible = bigOn
		if bigOn then
			local ex, ey = Minimap.edge((bx - x) * scale, (bz - z) * scale, half - EDGE)
			local place = UDim2.fromOffset(half + ex, half + ey)
			bigMark.Position, bigRing.Position = place, place
			local across = if kind == "Held" then BIG_HELD else BIG_SIZE
			bigMark.Size = UDim2.fromOffset(across, across)
		end
		local rung = if a.bigRang >= 0 then (clock - a.bigRang) / BIG_RING_TIME else math.huge
		if bigOn and rung < a.bigRings then
			local f = rung % 1
			local grown = BIG_SIZE * (1 + (BIG_RING - 1) * (1 - (1 - f) * (1 - f)))
			bigRing.Size = UDim2.fromOffset(grown, grown)
			bigRingStroke.Transparency = f
			bigRing.Visible = true
		else
			if rung >= a.bigRings then
				a.bigRang = -1
			end
			bigRing.Visible = false
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
