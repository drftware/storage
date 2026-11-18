--!strict
--[[
	CarPlaque (S6-01b, D-433): a brass plate on the bay wall beside each lobby car's gate, at eye
	height opposite its keypad, listing those aboard best first: each one's photo and best floor,
	your own row lit warm, as an arcade cabinet's high-score table lists who's played. Engraved
	rules cross the plate, so an empty car shows a blank board waiting for names.

	A face steps onto it with a pop and slides to its place as the order changes; one who leaves
	shrinks away; a best that rises swells its number. CarDial builds one per car and draws it as
	the car's group or someone's best floor changes (`Bests.rows`); nothing here runs on a step.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Bests = require(ReplicatedStorage.Shared.Lobby.Bests)
local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Lobby = require(ReplicatedStorage.Shared.Lobby)

local HEAVY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.ExtraBold)

-- In the bay's frame: the mirror of the keypad (Elevator Specs' Keypad, its middle 7.8 right of
-- the car's), in the 1.85 studs of wall between the landing frame (6.9) and the post (8.75), its
-- middle at a player's eye height (4.6), its back just clear of the bay wall's ribs (0.015).
local AT = Vector3.new(7.8, 4.6, -0.02)
-- 1.5 by 2.8 studs: six rows of a photo and a floor, each about half a stud tall, read from a
-- step or two away on a phone; from across the room it reads as a lit brass plate with faces.
local SIZE = Vector3.new(1.5, 2.8, 0.05)
local PER_STUD = 120 -- the canvas is 180 by 336
local W, H = SIZE.X * PER_STUD, SIZE.Y * PER_STUD
local PAD = 12 -- the plate's margin inside its bevel (px)
local ROW = (H - PAD * 2) / Boarding.Capacity
local PHOTO = 40
local NUMBER_SIZE = 36
local MAX_DISTANCE = 120

-- A face stepping on pops in from this size; rows slide to a new place over SLIDE; a risen best's
-- number swells from RISE_POP.
local POP = 0.55
local POP_IN = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLIDE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SHRINK = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local RISE_POP = 1.4

local BRASS = Color3.fromRGB(170, 132, 64)
local BRASS_TOP = Color3.fromRGB(214, 178, 104)
local BRASS_EDGE = Color3.fromRGB(96, 70, 30)
local ENGRAVED = Color3.fromRGB(44, 30, 12) -- the numbers and rules cut into the brass
local SCREW = Color3.fromRGB(70, 52, 24)
local MINE = Elevator.Lamp.Colour -- your own row's warm backing

type Row = {
	frame: Frame,
	scale: UIScale,
	backing: Frame,
	number: TextLabel,
	numberScale: UIScale,
	slot: number,
	floor: number,
}

export type Plaque = {
	part: Part,
	plate: Frame,
	rows: { [number]: Row }, -- by UserId
}

local CarPlaque = {}

local function corner(parent: Instance, radius: UDim)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
end

local function slotAt(slot: number): UDim2
	return UDim2.fromOffset(PAD, PAD + (slot - 1) * ROW)
end

-- The plaque for bay `bay`, in `parent`.
function CarPlaque.build(bay: number, parent: Instance): Plaque
	local frame = Lobby.bay(Lobby.Origin, bay)
	local centre = frame * (AT + Vector3.new(0, 0, -SIZE.Z / 2))
	local facing = frame:VectorToWorldSpace(Vector3.new(0, 0, -1))
	local part = Instance.new("Part")
	part.Name = `Plaque{bay}`
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Metal
	part.Color = BRASS_EDGE
	part.Size = SIZE
	part.CFrame = CFrame.lookAt(centre, centre + facing)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PER_STUD
	gui.LightInfluence = Lobby.InkLight
	gui.MaxDistance = MAX_DISTANCE
	gui.Parent = part

	-- the brass face: lighter at the top as the room's light falls on it, a dark bevel round it
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.Size = UDim2.fromScale(1, 1)
	plate.BackgroundColor3 = Color3.new(1, 1, 1)
	corner(plate, UDim.new(0, 6))
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(BRASS_TOP, BRASS)
	gradient.Rotation = 80
	gradient.Parent = plate
	local bevel = Instance.new("UIStroke")
	bevel.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	bevel.Color = BRASS_EDGE
	bevel.Thickness = 3
	bevel.Parent = plate
	plate.Parent = gui

	-- the rules between the rows, engraved, and a screw at each corner
	for i = 1, Boarding.Capacity - 1 do
		local rule = Instance.new("Frame")
		rule.BorderSizePixel = 0
		rule.BackgroundColor3 = ENGRAVED
		rule.BackgroundTransparency = 0.72
		rule.Position = UDim2.fromOffset(PAD + 6, PAD + i * ROW - 1)
		rule.Size = UDim2.fromOffset(W - PAD * 2 - 12, 2)
		rule.Parent = plate
	end
	for _, at in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		local screw = Instance.new("Frame")
		screw.AnchorPoint = at
		screw.Position =
			UDim2.new(at.X, if at.X == 0 then 4 else -4, at.Y, if at.Y == 0 then 4 else -4)
		screw.Size = UDim2.fromOffset(7, 7)
		screw.BackgroundColor3 = SCREW
		screw.BorderSizePixel = 0
		corner(screw, UDim.new(0.5, 0))
		screw.Parent = plate
	end

	part.Parent = parent
	return { part = part, plate = plate, rows = {} }
end

local function newRow(plaque: Plaque, id: number, slot: number): Row
	local frame = Instance.new("Frame")
	frame.Name = `Row{id}`
	frame.BackgroundTransparency = 1
	frame.Position = slotAt(slot)
	frame.Size = UDim2.fromOffset(W - PAD * 2, ROW)
	local scale = Instance.new("UIScale")
	scale.Parent = frame

	local backing = Instance.new("Frame")
	backing.Name = "Mine"
	backing.AnchorPoint = Vector2.new(0.5, 0.5)
	backing.Position = UDim2.fromScale(0.5, 0.5)
	backing.Size = UDim2.new(1, 0, 1, -6)
	backing.BackgroundColor3 = MINE
	backing.BackgroundTransparency = 1
	backing.BorderSizePixel = 0
	corner(backing, UDim.new(0, 8))
	backing.Parent = frame

	local photo = Instance.new("ImageLabel")
	photo.Name = "Photo"
	photo.AnchorPoint = Vector2.new(0, 0.5)
	photo.Position = UDim2.new(0, 6, 0.5, 0)
	photo.Size = UDim2.fromOffset(PHOTO, PHOTO)
	photo.BackgroundColor3 = ENGRAVED
	photo.ScaleType = Enum.ScaleType.Crop
	photo.Image = `rbxthumb://type=AvatarHeadShot&id={id}&w=150&h=150`
	corner(photo, UDim.new(0.5, 0))
	local ring = Instance.new("UIStroke")
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Color = ENGRAVED
	ring.Thickness = 2
	ring.Parent = photo
	photo.Parent = frame

	local number = Instance.new("TextLabel")
	number.Name = "Floor"
	number.BackgroundTransparency = 1
	number.AnchorPoint = Vector2.new(1, 0.5)
	number.Position = UDim2.new(1, -8, 0.5, 0)
	number.Size = UDim2.fromOffset(W - PAD * 2 - PHOTO - 22, NUMBER_SIZE + 4)
	number.FontFace = HEAVY
	number.TextSize = NUMBER_SIZE
	number.TextXAlignment = Enum.TextXAlignment.Right
	number.TextColor3 = ENGRAVED
	local numberScale = Instance.new("UIScale")
	numberScale.Parent = number
	number.Parent = frame

	frame.Parent = plaque.plate
	return {
		frame = frame,
		scale = scale,
		backing = backing,
		number = number,
		numberScale = numberScale,
		slot = slot,
		floor = -1,
	}
end

-- Draw `rows` (Bests.rows: those aboard, best first) on `plaque`, `me`'s row lit; `animate`
-- moves it as it changes rather than setting it.
function CarPlaque.draw(plaque: Plaque, rows: { Bests.Row }, me: number, animate: boolean)
	local present: { [number]: true } = {}
	for slot, r in rows do
		present[r.id] = true
		local found = plaque.rows[r.id]
		local row: Row = found or newRow(plaque, r.id, slot)
		if not found then
			plaque.rows[r.id] = row
			if animate then
				row.scale.Scale = POP
				TweenService:Create(row.scale, POP_IN, { Scale = 1 }):Play()
			end
		elseif row.slot ~= slot then
			row.slot = slot
			if animate then
				TweenService:Create(row.frame, SLIDE, { Position = slotAt(slot) }):Play()
			else
				row.frame.Position = slotAt(slot)
			end
		end
		if row.floor ~= r.floor then
			local rose = row.floor >= 0 and r.floor > row.floor
			row.floor = r.floor
			-- a dash for someone with no best yet: they're on the board, not yet on a floor
			row.number.Text = if r.floor >= 1 then tostring(r.floor) else "–"
			row.number.TextTransparency = if r.floor >= 1 then 0 else 0.5
			if rose and animate then
				row.numberScale.Scale = RISE_POP
				TweenService:Create(row.numberScale, POP_IN, { Scale = 1 }):Play()
			end
		end
		row.backing.BackgroundTransparency = if r.id == me then 0.3 else 1
	end
	for id, row in plaque.rows do
		if not present[id] then
			plaque.rows[id] = nil
			if animate then
				local t = TweenService:Create(row.scale, SHRINK, { Scale = 0 })
				t.Completed:Once(function()
					row.frame:Destroy()
				end)
				t:Play()
			else
				row.frame:Destroy()
			end
		end
	end
end

function CarPlaque.destroy(plaque: Plaque)
	table.clear(plaque.rows)
	plaque.part:Destroy()
end

return CarPlaque
