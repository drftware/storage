--!strict
--[[
	The machine in the car (S1-10b, GDD "The ride"): a self-storage supply vending machine in the
	back-right corner of every car, dark when the car stands at a floor, waking on every ride but
	the first (`Wake`), and selling tools and batteries for coins (S1-10c). Imported from
	art/machine/ (its README); `prepare` readies the import once, in Edit, into the template at
	ReplicatedStorage.Props.Machine; `place` stands a copy in a car, tagged so every rider's screen
	lights it (MachineView).

	The template, its pivot on the floor under its middle, its front toward its LookVector (-Z):
	- `Cabinet`, the one part that collides (a box), with `Glass` over the bays, the `Flap` over
	  the bin hung from its hinge, and a `Coil{i}` and `Button{i}` for each bay (1 to 6, bottom
	  row first, left to right as you face it; `Specs.Bays`).
	- `Tube{row}`, one cylinder per row (1 bottom to 3 top), so the rows catch one at a time.
	- `Sign`, the lit panel under the cap, its keyhole-coin emblem printed on (no words).
	- `Prices`, the six red price windows, a `Window{i}` frame for each in its `Digits` SurfaceGui.
	- On the glass, one SurfaceLight, off: `CarLight`, the cold spill into the car.
	On a ride that wakes it the server writes its stock on it (`Stock.Attribute`, S1-10c).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Buy = require(script.Buy)
local Specs = require(script.Specs)
local Stock = require(script.Stock)
local Wake = require(script.Wake)

local Machine = {}
Machine.Buy = Buy
Machine.Specs = Specs
Machine.Stock = Stock
Machine.Wake = Wake

-- Tagged on every machine standing in a car, so each screen lights it (MachineView). The
-- template carries no tag.
Machine.Tag = "VendingMachine"
Machine.Template = "Machine" -- its Model in ReplicatedStorage.Props

-- Its tubes: a cold fluorescent white when lit (a share of it as they flicker and dip), milky
-- glass when dark.
Machine.TubeLit = Color3.fromRGB(222, 236, 248)
Machine.TubeDark = Color3.fromRGB(128, 134, 138)
-- The sign: a backlit panel a touch softer than the tubes (a bright Neon strip blooms into a
-- blob on a phone), grey plastic when dark; its emblem printed in the cabinet's oxblood.
Machine.SignLit = Color3.fromRGB(206, 216, 224)
Machine.SignDark = Color3.fromRGB(107, 102, 92)
Machine.Ink = Color3.fromRGB(92, 20, 18)
-- The price windows' dark red glass.
Machine.PriceGlass = Color3.fromRGB(40, 8, 8)

-- Its one real light, off but on a ride that wakes it (a low-end phone's budget: only one car is
-- ever lit on a screen): the cold spill from the glass across the car and over your friends'
-- faces. The bays read by their Neon tubes; a second light shone back into the cabinet blacked
-- out every other light on screen (docs/STUDIO.md).
Machine.Light = {
	Colour = Color3.fromRGB(205, 225, 255),
	Car = { Brightness = 0.8, Range = 12, Angle = 140 },
}

-- The sounds, Pro Sound Effects' (measured, docs/STUDIO.md): each starter's tink as its tube
-- tries ("Toggle Switches Moviola Editing Machine 17", a hollow metal snap that's gone in a
-- tenth of a second, pitched up to a starter's small tink, a touch higher for each row up); the
-- sign's buzz as it stutters on ("Light Bulb Buzz 3", steady from 0.23 s, looped while the sign
-- starts and gated by its flicker); and the ballasts' hum ("Transformer Hum 1", a steady 36 s
-- loop at about -29 dB, longer than a ride), as loud as the share of the machine that's lit.
-- Heard in the car (`Heard` studs), from the machine's corner.
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number }
Machine.Tink = {
	id = "rbxassetid://9120089728",
	from = 0,
	length = 0.3,
	volume = 0.5,
	pitch = 1.45,
} :: Sound
Machine.TinkRise = 0.07 -- pitch added per row up (the sign's is the top row's and one more)
Machine.Buzz = {
	id = "rbxassetid://9116270244",
	from = 0.3,
	length = 2.7,
	volume = 0.4,
	pitch = 1,
} :: Sound
Machine.Hum = {
	id = "rbxassetid://9112889082",
	from = 0,
	length = 36,
	volume = 0.6,
	pitch = 1,
} :: Sound
Machine.Heard = 18

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function part(parent: Instance, name: string): BasePart
	local p = parent:FindFirstChild(name)
	assert(p and p:IsA("BasePart"), `the machine has no {name}`)
	return p
end

function Machine.template(): Model?
	local folder = ReplicatedStorage:FindFirstChild("Props")
	local m = folder and folder:FindFirstChild(Machine.Template)
	return if m and m:IsA("Model") then m else nil
end

-- Collides with nothing and throws no shadow: everything but the cabinet.
local function quiet(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
end

local function light(
	name: string,
	face: Enum.NormalId,
	spec: { [string]: number },
	parent: Instance
)
	local l = Instance.new("SurfaceLight")
	l.Name = name
	l.Face = face
	l.Color = Machine.Light.Colour
	l.Brightness = 0
	l.Range = spec.Range
	l.Angle = spec.Angle
	l.Shadows = false
	l.Enabled = false
	l.Parent = parent
end

-- The sign's keyhole coin, printed on its panel: a coin's ring with a keyhole through its middle
-- (the game's coin, art/coin/), and a rule running out to either side of it.
local function emblem(sign: BasePart)
	local size = Specs.Sign.Size
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Emblem"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 100
	gui.LightInfluence = 1 -- ink: lit by the car, dark on the glowing panel
	gui.ClipsDescendants = true
	local function shape(
		name: string,
		x: number,
		y: number,
		w: number,
		h: number,
		round: number,
		parent: Instance
	)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset(x, y)
		f.Size = UDim2.fromOffset(w, h)
		f.BackgroundColor3 = Machine.Ink
		f.BorderSizePixel = 0
		if round > 0 then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(round, 0)
			c.Parent = f
		end
		f.Parent = parent
		return f
	end
	local w, h = size[1] * 100, size[2] * 100
	local cx, cy = w / 2, h / 2
	local d = h * 0.74 -- the coin's width
	local coin = shape("Coin", cx, cy, d, d, 0.5, gui)
	coin.BackgroundTransparency = 1
	local ring = Instance.new("UIStroke")
	ring.Color = Machine.Ink
	ring.Thickness = d * 0.11
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Parent = coin
	-- the keyhole: a round head over a flared foot, as the coin's is stamped
	shape("KeyHead", cx, cy - d * 0.09, d * 0.26, d * 0.26, 0.5, gui)
	shape("KeyFoot", cx, cy + d * 0.12, d * 0.13, d * 0.34, 0.15, gui)
	-- the rules either side, stopping short of the coin and of the panel's ends
	local gap, edge = d * 0.75, w * 0.08
	local len = cx - gap - edge
	shape("RuleLeft", edge + len / 2, cy, len, h * 0.05, 0.5, gui)
	shape("RuleRight", w - edge - len / 2, cy, len, h * 0.05, 0.5, gui)
	gui.Parent = sign
end

-- The price windows' frames on the prices' face, one per bay (MachineView draws their LED
-- digits as the machine wakes). A SurfaceGui on a Front face reads left to right toward -X.
local function windows(prices: BasePart)
	local spec = Specs.Parts.MachinePrices
	local size, centre = spec.Size, spec.Centre
	local pps = 160
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Digits"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pps
	gui.LightInfluence = 0 -- the LEDs make their own light
	for i, bay in Specs.Bays do
		local f = Instance.new("Frame")
		f.Name = `Window{i}`
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromOffset(
			(size[1] / 2 - (bay.Price[1] - centre[1])) * pps,
			(size[2] / 2 - (bay.Price[2] - centre[2])) * pps
		)
		f.Size = UDim2.fromOffset(Specs.PriceSize[1] * pps, Specs.PriceSize[2] * pps)
		f.BackgroundTransparency = 1
		f.Parent = gui
	end
	gui.Parent = prices
end

--[[
	The import's last step, once, in Edit (CollisionFidelity can't be set while the game runs).
	Every part arrives with its pivot on its own origin and the import's turn; a part's own CFrame
	carries the machine's axes (docs/STUDIO.md), so the frame is the cabinet's pivot's position and
	its CFrame's turn. Squares each part by `Specs.Parts`, clones a coil and a button into every
	bay, hangs the flap, draws the tubes as cylinders, prints the sign, frames the price windows
	and adds its light, then sets the whole at the origin. Returns the model, named
	`Machine` and unparented.
]]
function Machine.prepare(model: Model): Model
	local cabinet = part(model, "Machine")
	local frame = CFrame.new(cabinet:GetPivot().Position) * cabinet.CFrame.Rotation
	for _, d in model:GetDescendants() do
		if d:IsA("PackageLink") then
			d:Destroy()
		end
	end
	for _, tag in model:GetTags() do
		if tag:sub(1, 10) == "Assistant:" then
			model:RemoveTag(tag) -- the MCP's insert marks what it adds
		end
	end
	model.WorldPivot = frame
	for name, spec in Specs.Parts do
		local p = part(model, name) :: MeshPart
		quiet(p)
		p.CollisionFidelity = Enum.CollisionFidelity.Box
		p.PivotOffset = CFrame.new(-vec(spec.Centre)) -- its pivot on its origin, square to the machine
		p.CFrame = frame * CFrame.new(vec(spec.Centre))
	end

	-- the cabinet: the one part you bump into, see the torch land on, and that shadows the car
	cabinet.Name = "Cabinet"
	cabinet.CanCollide = true
	cabinet.CanQuery = true
	cabinet.CastShadow = true

	-- a coil and a button in every bay, each a clone (one draw for the six), the flap on its hinge
	local coil, button = part(model, "MachineCoil"), part(model, "MachineButton")
	for i, bay in Specs.Bays do
		local c = coil:Clone()
		c.Name = `Coil{i}`
		c:PivotTo(frame * CFrame.new(vec(bay.Coil)))
		c.Parent = model
		local b = button:Clone()
		b.Name = `Button{i}`
		b:PivotTo(frame * CFrame.new(vec(bay.Button)))
		b.Parent = model
	end
	coil:Destroy()
	button:Destroy()
	local flap = part(model, "MachineFlap")
	flap.Name = "Flap"
	flap:PivotTo(frame * CFrame.new(vec(Specs.FlapHinge)))

	-- the glass, and the light it carries
	local glass = part(model, "MachineGlass")
	glass.Name = "Glass"
	glass.Material = Enum.Material.Glass
	glass.Transparency = 0.72
	glass.Reflectance = 0.06
	light("CarLight", Enum.NormalId.Front, Machine.Light.Car, glass)

	-- the tubes: one cylinder per row in the mesh's place, dark until MachineView lights them
	part(model, "MachineTubes"):Destroy()
	for row, at in Specs.Tubes do
		local t = Instance.new("Part")
		t.Name = `Tube{row}`
		t.Shape = Enum.PartType.Cylinder -- its axis along X, as the tubes run
		t.Size = Vector3.new(Specs.TubeLength, Specs.TubeRadius * 2, Specs.TubeRadius * 2)
		t.CFrame = frame * CFrame.new(vec(at))
		t.Material = Enum.Material.SmoothPlastic
		t.Color = Machine.TubeDark
		t.TopSurface = Enum.SurfaceType.Smooth
		t.BottomSurface = Enum.SurfaceType.Smooth
		quiet(t)
		t.Parent = model
	end

	local sign = part(model, "MachineSign")
	sign.Name = "Sign"
	sign.Material = Enum.Material.SmoothPlastic
	sign.Color = Machine.SignDark
	emblem(sign)

	local prices = part(model, "MachinePrices")
	prices.Name = "Prices"
	prices.Material = Enum.Material.SmoothPlastic
	prices.Color = Machine.PriceGlass
	windows(prices)

	model.Name = Machine.Template
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- streams in whole, with its car
	model:PivotTo(CFrame.identity)
	model.Parent = nil
	return model
end

-- A copy of the template standing in `car` (a floor's elevator, `Elevator.clone`'s; not a lobby
-- car, whose back wall carries the climb's results, CarResults), at its place in the car's frame
-- (`Specs.InCar`), tagged for MachineView. Posed before it's parented, so nothing crosses the
-- wire twice. Nil, after a warning, if the place has no template.
function Machine.place(car: Model): Model?
	local template = Machine.template()
	if not template then
		warn("Machine: no template at ReplicatedStorage.Props.Machine (art/machine/README.md)")
		return nil
	end
	local m = template:Clone()
	m:PivotTo(car:GetPivot() * CFrame.new(vec(Specs.InCar)))
	m:AddTag(Machine.Tag)
	m.Parent = car
	return m
end

return Machine
