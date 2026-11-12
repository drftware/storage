--!strict
--[[
	CarDial: a dial over each lobby car's gate, and the pointer for a player in no car (L-08e3,
	GDD "The lobby": "The dial over each car shows who's aboard, or which floor a climbing party
	has reached"; "Players alone are pointed to the fullest open car"), as DOORS' lobby elevators
	show who's in each over its door.

	- The dial stands over the gate where the bay's number plate is, wider, and keeps the number:
	  six round seats either side of it, three and three. A seat with someone in it shows their
	  photo in a warm ring and pops in as they step in; an empty one is a dark socket; seats past
	  the host's player count fade nearly away. From the door the seats read as lit and dark
	  dots: how full the car is. Under the number, one short line: "Friends only" (warm), "Full",
	  "Going up" while it takes its group to a server of their own, or "Floor N" (the readout's
	  green) while the group it took up climbs on this server (`Boarding.FloorAttribute`).
	- The pointer: a player in no car's group, standing in the front office, is pointed to the
	  fullest car that would take them (`Boarding.fullest`: room, not shutting before they'd get
	  there, Friends only only if they're the host's friend; the friend whose invite they came by
	  first). Its dial's rim glows warm and breathes, and the seat they'd take glows with it. It
	  moves as cars fill and empty, and goes the moment they step into a car.

	Each dial is a plain client part with a SurfaceGui, built once; it changes only when its car's
	values do. The pointer is worked out four times a second, not every frame.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Departure = require(ReplicatedStorage.Shared.Elevator.Departure)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local Trip = require(ReplicatedStorage.Shared.Lobby.Trip)

local HEAVY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)
local BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)

-- The dial, in the lobby's frame: centred on the bay's number plate (Specs.Cards, 11.95 up, its
-- face 0.185 off the bay wall) and just in front of it, so it covers it; facing the room (-Z).
-- 10.4 by 3 studs: wider than the gate's opening is tall, so from the door (about 42 studs) the
-- seats read as dots on a phone and the line under the number reads from the room's middle; its
-- foot hides the number plate's worn edge.
local HEIGHT_UP, OFF_WALL = 11.85, 0.32
local SIZE = Vector3.new(10.4, 3, 0.05)
-- Pixels a stud: the canvas is 520 by 150.
local PER_STUD = 50
local W, H = SIZE.X * PER_STUD, SIZE.Y * PER_STUD
-- The plate sits this far inside the canvas so its rim (and the pointer's glow) isn't clipped.
local INSET = 12
-- The seats: round, this wide (px), this far apart, the outer ones this far from the canvas's
-- ends, centred on the number's height.
local SEAT, SEAT_GAP, SEAT_EDGE = 58, 9, 26
local SEAT_Y = 54
local NUMBER_SIZE = 84
local LINE_Y, LINE_SIZE = 115, 34
-- How much the room's light shades it: as the bay's number plates (Lobby.InkLight).
local LIGHT = Lobby.InkLight
local MAX_DISTANCE = 220

-- A seat taken pops in from this size; a photo fades in and out over these.
local SEAT_POP = 0.55
local POP_IN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- The line under the number pops from this size as it changes (a new floor, Friends only).
local LINE_POP = 1.25
-- The pointer: the rim warms over this, then breathes (brighter, dimmer) every this many seconds.
local GLOW_IN = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BREATHE = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local RIM_THICK, GLOW_THICK = 3, 10
-- And a soft chevron hangs in its doorway at head height, just in front of the gate, bobbing
-- this far down and back: where to go, gone the moment you step in.
local CHEVRON_AT = CFrame.new(0, 7.6, -1.2) -- in the bay's frame
local CHEVRON_SIZE = 2 -- studs
local BOB = 0.35
local BOB_TWEEN = TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local CHEVRON_SHOWN = 0.12 -- its arms' transparency
-- Seconds between working out where the pointer goes.
local POINT_EVERY = 0.25
-- The front office, in its own frame: you're "in the lobby" inside this box (it's 120 by 48).
local ROOM_X, ROOM_Z, ROOM_Y = 60, 48, 20

local STEEL = Color3.fromRGB(26, 26, 29)
local STEEL_TOP = Color3.fromRGB(44, 44, 48)
local RIM = Color3.fromRGB(78, 78, 84)
local WELL = Color3.fromRGB(12, 12, 14)
local INK = Lobby.Ink
local DIM = Color3.fromRGB(150, 146, 138)
local WARM = Elevator.Lamp.Colour
local GREEN = Elevator.ReadoutRight

type Seat = { frame: Frame, scale: UIScale, ring: UIStroke, photo: ImageLabel, id: number? }

type Dial = {
	model: Model,
	bay: number,
	part: Part,
	plate: Frame,
	rim: UIStroke,
	line: TextLabel,
	lineScale: UIScale,
	seats: { Seat },
	text: string, -- the line as drawn
	conns: { RBXScriptConnection },
	glow: { Tween },
}

local function headshot(userId: number): string
	return `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
end

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function stroke(
	parent: Instance,
	colour: Color3,
	thickness: number,
	transparency: number
): UIStroke
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = colour
	s.Thickness = thickness
	s.Transparency = transparency
	s.Parent = parent
	return s
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

local CarDial = {}

function CarDial.new(): Brix.System
	local dials: { [Model]: Dial } = {}
	local connections: { RBXScriptConnection } = {}
	local folder: Folder? = nil
	local me = Players.LocalPlayer
	local pointed: Dial? = nil -- the dial the pointer is on
	local pointedSeat: Seat? = nil
	local seatGlow: Tween? = nil
	local since = 0
	-- the chevron in the pointed car's doorway: its part, gui and arms
	local chevron: Part? = nil
	local chevronGui: BillboardGui? = nil
	local arms: { Frame } = {}
	local bob: Tween? = nil
	-- Whether the local player is each host's friend, as Roblox answered (asked once, off the
	-- step: IsFriendsWith yields); `asking` while the ask is out.
	local friends: { [number]: boolean } = {}
	local asking: { [number]: true } = {}

	local function friendOf(host: number): boolean?
		local known = friends[host]
		if known ~= nil then
			return known
		end
		if not asking[host] then
			asking[host] = true
			task.spawn(function()
				local ok, are = pcall(me.IsFriendsWith, me, host)
				asking[host] = nil
				friends[host] = ok and are == true
			end)
		end
		return nil
	end

	-- The car as its replicated values say.
	local function stateOf(model: Model): Boarding.Car
		local friendsOnly, players = Boarding.choices(
			model:GetAttribute(Boarding.FriendsAttribute),
			model:GetAttribute(Boarding.PlayersAttribute)
		)
		local departs = model:GetAttribute(Departure.Attribute)
		return {
			group = Boarding.decode(model:GetAttribute(Boarding.GroupAttribute)),
			departs = if type(departs) == "number" then departs else nil,
			friends = friendsOnly,
			players = players,
		}
	end

	-- The pointer onto a dial (below): drawing a dial it's on moves it to the seat you'd take.
	local point: (dial: Dial?) -> ()

	-- The line under the number, and its colour.
	local function lineFor(model: Model, state: Boarding.Car): (string, Color3)
		local aboard = #state.group
		if model:GetAttribute(Trip.Attribute) == true then
			return "Going up", DIM
		end
		local floor = model:GetAttribute(Boarding.FloorAttribute)
		if aboard == 0 and type(floor) == "number" then
			return `Floor {floor}`, GREEN
		end
		if aboard > 0 and aboard >= state.players then
			return "Full", DIM
		end
		if aboard > 0 and state.friends then
			return "Friends only", WARM
		end
		return "", INK
	end

	-- The seat's look for who's in it (`id`) and whether it's within the host's count.
	local function drawSeat(
		seat: Seat,
		id: number?,
		room: boolean,
		friendsOnly: boolean,
		animate: boolean
	)
		local was = seat.id
		seat.id = id
		if id then
			if was ~= id then
				seat.photo.Image = headshot(id)
				if animate then
					seat.scale.Scale = SEAT_POP
					TweenService:Create(seat.scale, POP_IN, { Scale = 1 }):Play()
				end
			end
			TweenService:Create(seat.photo, FADE, { ImageTransparency = 0 }):Play()
			TweenService:Create(seat.frame, FADE, { BackgroundTransparency = 0 }):Play()
			seat.ring.Color = WARM
			seat.ring.Thickness = 3
			TweenService:Create(seat.ring, FADE, { Transparency = 0 }):Play()
		elseif seat == pointedSeat then
			-- the seat the pointer says is yours: its ring is the pointer's
			TweenService:Create(seat.photo, FADE, { ImageTransparency = 1 }):Play()
		else
			TweenService:Create(seat.photo, FADE, { ImageTransparency = 1 }):Play()
			TweenService
				:Create(seat.frame, FADE, { BackgroundTransparency = if room then 0 else 0.7 })
				:Play()
			seat.ring.Color = if friendsOnly then WARM else INK
			TweenService:Create(seat.ring, FADE, { Transparency = if room then 0.45 else 0.88 })
				:Play()
		end
	end

	local function draw(dial: Dial, animate: boolean)
		local state = stateOf(dial.model)
		for i, seat in dial.seats do
			drawSeat(seat, state.group[i], i <= state.players, state.friends, animate)
		end
		if pointed == dial then
			point(dial) -- the seat you'd take moves as the car fills
		end
		local text, colour = lineFor(dial.model, state)
		dial.line.TextColor3 = colour
		if text ~= dial.text then
			dial.text = text
			dial.line.Text = text
			if animate and text ~= "" then
				dial.line.TextTransparency = 1
				dial.lineScale.Scale = LINE_POP
				TweenService:Create(dial.line, FADE, { TextTransparency = 0 }):Play()
				TweenService:Create(dial.lineScale, POP_IN, { Scale = 1 }):Play()
			end
		end
	end

	local function build(model: Model, bay: number): Dial
		local lobby = Lobby.Origin
		local centre = lobby * Vector3.new(Lobby.Specs.Bays[bay], HEIGHT_UP, -OFF_WALL)
		local facing = lobby:VectorToWorldSpace(Vector3.new(0, 0, -1))
		local part = Instance.new("Part")
		part.Name = `Dial{bay}`
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = SIZE
		part.CFrame = CFrame.lookAt(centre, centre + facing)

		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = PER_STUD
		gui.LightInfluence = LIGHT
		gui.MaxDistance = MAX_DISTANCE
		gui.Parent = part

		local plate = Instance.new("Frame")
		plate.Name = "Plate"
		plate.Position = UDim2.fromOffset(INSET, INSET)
		plate.Size = UDim2.fromOffset(W - INSET * 2, H - INSET * 2)
		plate.BackgroundColor3 = Color3.new(1, 1, 1)
		corner(plate, UDim.new(0, 14))
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(STEEL_TOP, STEEL)
		gradient.Rotation = 90
		gradient.Parent = plate
		local rim = stroke(plate, RIM, RIM_THICK, 0.15)
		plate.Parent = gui

		local number = Instance.new("TextLabel")
		number.Name = "Bay"
		number.BackgroundTransparency = 1
		number.AnchorPoint = Vector2.new(0.5, 0.5)
		number.Position = UDim2.fromOffset(W / 2 - INSET, SEAT_Y - INSET)
		number.Size = UDim2.fromOffset(110, NUMBER_SIZE + 4)
		number.FontFace = HEAVY
		number.TextSize = NUMBER_SIZE
		number.TextColor3 = INK
		number.Text = tostring(bay)
		number.Parent = plate

		local line = Instance.new("TextLabel")
		line.Name = "Line"
		line.BackgroundTransparency = 1
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromOffset(W / 2 - INSET, LINE_Y - INSET)
		line.Size = UDim2.fromOffset(260, LINE_SIZE + 4)
		line.FontFace = BOLD
		line.TextSize = LINE_SIZE
		line.TextColor3 = INK
		line.Text = ""
		local lineScale = Instance.new("UIScale")
		lineScale.Parent = line
		line.Parent = plate

		local seats: { Seat } = {}
		local half = Boarding.Capacity // 2
		for i = 1, Boarding.Capacity do
			local left = i <= half
			local k = if left then i - 1 else i - half - 1
			local x0 = if left
				then SEAT_EDGE
				else W - SEAT_EDGE - (SEAT * half + SEAT_GAP * (half - 1))
			local frame = Instance.new("Frame")
			frame.Name = `Seat{i}`
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position =
				UDim2.fromOffset(x0 + k * (SEAT + SEAT_GAP) + SEAT / 2 - INSET, SEAT_Y - INSET)
			frame.Size = UDim2.fromOffset(SEAT, SEAT)
			frame.BackgroundColor3 = WELL
			corner(frame, UDim.new(0.5, 0))
			local ring = stroke(frame, INK, 3, 0.45)
			local scale = Instance.new("UIScale")
			scale.Parent = frame
			local photo = Instance.new("ImageLabel")
			photo.Name = "Photo"
			photo.BackgroundTransparency = 1
			photo.Size = UDim2.fromScale(1, 1)
			photo.ScaleType = Enum.ScaleType.Crop
			photo.ImageTransparency = 1
			corner(photo, UDim.new(0.5, 0))
			photo.Parent = frame
			frame.Parent = plate
			seats[i] = { frame = frame, scale = scale, ring = ring, photo = photo, id = nil }
		end

		part.Parent = folder
		return {
			model = model,
			bay = bay,
			part = part,
			plate = plate,
			rim = rim,
			line = line,
			lineScale = lineScale,
			seats = seats,
			text = "",
			conns = {},
			glow = {},
		}
	end

	local function buildChevron(): Part
		local part = Instance.new("Part")
		part.Name = "Pointer"
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.one * 0.2
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(CHEVRON_SIZE, CHEVRON_SIZE)
		gui.LightInfluence = 0
		gui.MaxDistance = MAX_DISTANCE
		gui.Enabled = false
		gui.Parent = part
		for _, side in { -1, 1 } do
			local arm = Instance.new("Frame")
			arm.AnchorPoint = Vector2.new(0.5, 0.5)
			arm.Position = UDim2.fromScale(0.5 + side * 0.19, 0.42)
			arm.Size = UDim2.fromScale(0.58, 0.17)
			arm.Rotation = -side * 42
			arm.BackgroundColor3 = WARM
			arm.BackgroundTransparency = 1
			arm.BorderSizePixel = 0
			corner(arm, UDim.new(0.5, 0))
			arm.Parent = gui
			table.insert(arms, arm)
		end
		chevronGui = gui
		part.Parent = folder
		return part
	end

	-- The chevron into `dial`'s doorway, or away.
	local function showChevron(dial: Dial?)
		local part = chevron or buildChevron()
		chevron = part
		local gui = chevronGui :: BillboardGui
		if bob then
			bob:Cancel()
			bob = nil
		end
		if not dial then
			for _, arm in arms do
				TweenService:Create(arm, FADE, { BackgroundTransparency = 1 }):Play()
			end
			return
		end
		part.CFrame = Lobby.bay(Lobby.Origin, dial.bay) * CHEVRON_AT
		gui.Enabled = true
		gui.StudsOffset = Vector3.zero
		for _, arm in arms do
			arm.BackgroundTransparency = 1
			TweenService:Create(arm, GLOW_IN, { BackgroundTransparency = CHEVRON_SHOWN }):Play()
		end
		local t = TweenService:Create(gui, BOB_TWEEN, { StudsOffset = Vector3.new(0, -BOB, 0) })
		bob = t
		t:Play()
	end

	local function stopGlow(dial: Dial)
		for _, t in dial.glow do
			t:Cancel()
		end
		table.clear(dial.glow)
	end

	-- The pointer onto `dial` (nil: off), and onto the seat they'd take there.
	point = function(dial: Dial?)
		local seat: Seat? = nil
		if dial then
			local state = stateOf(dial.model)
			seat = dial.seats[#state.group + 1]
		end
		if dial == pointed and seat == pointedSeat then
			return
		end
		if seatGlow then
			seatGlow:Cancel()
			seatGlow = nil
		end
		local owner, wasSeat = pointed, pointedSeat
		pointedSeat = seat
		if dial ~= pointed then
			local was = pointed
			pointed = dial
			if was then
				stopGlow(was)
				local back = TweenService:Create(
					was.rim,
					GLOW_IN,
					{ Color = RIM, Thickness = RIM_THICK, Transparency = 0.15 }
				)
				back:Play()
			end
			showChevron(dial)
			if dial then
				stopGlow(dial)
				local warm = TweenService:Create(
					dial.rim,
					GLOW_IN,
					{ Color = WARM, Thickness = GLOW_THICK, Transparency = 0 }
				)
				warm:Play()
				table.insert(dial.glow, warm)
				warm.Completed:Once(function(status: Enum.PlaybackState)
					if status == Enum.PlaybackState.Completed and pointed == dial then
						local breathe =
							TweenService:Create(dial.rim, BREATHE, { Transparency = 0.6 })
						table.insert(dial.glow, breathe)
						breathe:Play()
					end
				end)
			end
		end
		if seat then
			seat.ring.Color = WARM
			seat.ring.Thickness = 4
			seat.ring.Transparency = 0
			local t = TweenService:Create(seat.ring, BREATHE, { Transparency = 0.6 })
			seatGlow = t
			t:Play()
		end
		if owner and wasSeat and not wasSeat.id then
			-- the seat it left is an empty socket again, drawn as its car says
			wasSeat.ring.Thickness = 3
			draw(owner, false)
		end
	end

	-- Where the pointer goes now: the fullest car that would take this player, if they're in no
	-- car's group and standing in the front office.
	local function aim()
		local character = me.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and root:IsA("BasePart") and humanoid and humanoid.Health > 0) then
			point(nil)
			return
		end
		local at = Lobby.Origin:PointToObjectSpace(root.Position)
		if math.abs(at.X) > ROOM_X or at.Z > 0 or at.Z < -ROOM_Z or at.Y > ROOM_Y then
			point(nil)
			return
		end
		local order: { Dial } = {}
		local states: { Boarding.Car } = {}
		for _, dial in dials do
			local state = stateOf(dial.model)
			if table.find(state.group, me.UserId) then
				point(nil)
				return
			end
			table.insert(order, dial)
			table.insert(states, state)
		end
		local by = me:GetAttribute(Boarding.InvitedAttribute)
		local i = Boarding.fullest(
			states,
			me.UserId,
			now(),
			friendOf,
			if type(by) == "number" then by else nil
		)
		point(if i then order[i] else nil)
	end

	local function remove(inst: Instance)
		local dial = dials[inst :: Model]
		if not dial then
			return
		end
		if pointed == dial then
			point(nil)
		end
		dials[inst :: Model] = nil
		stopGlow(dial)
		for _, c in dial.conns do
			c:Disconnect()
		end
		dial.part:Destroy()
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or dials[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local bay = inst:GetAttribute(Boarding.CarAttribute)
		if type(bay) ~= "number" or not Lobby.Specs.Bays[bay] then
			return -- a climb's car
		end
		local dial = build(inst, bay)
		dials[inst] = dial
		for _, name in
			{
				Boarding.GroupAttribute,
				Boarding.FriendsAttribute,
				Boarding.PlayersAttribute,
				Boarding.FloorAttribute,
				Trip.Attribute,
			}
		do
			table.insert(
				dial.conns,
				inst:GetAttributeChangedSignal(name):Connect(function()
					draw(dial, true)
				end)
			)
		end
		draw(dial, false)
	end

	return {
		name = "CarDial",
		start = function(_: any, _context: Brix.Context)
			local f = Instance.new("Folder")
			f.Name = "CarDials"
			f.Parent = Workspace
			folder = f
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
		end,
		step = function(_: any, dt: number)
			since += dt
			if since < POINT_EVERY then
				return
			end
			since = 0
			aim()
		end,
		stop = function(_: any)
			point(nil)
			if bob then
				bob:Cancel()
				bob = nil
			end
			table.clear(arms)
			chevron, chevronGui = nil, nil
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for model in dials do
				remove(model)
			end
			if folder then
				folder:Destroy()
				folder = nil
			end
		end,
	}
end

return CarDial
