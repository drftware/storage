--!strict
--[[
	Home: the home's kit in the game (D-259, D-263, D-266; art/home/README.md). The ground floor's
	twelve units are little homes, not the climb's lockups: a sage wall with an oak-cased doorway
	and a clean clay door, a light switch inside by the door and a round lamp overhead, a rug, a
	beanbag and a floor lamp waiting; plants by every door, benches between, planters to sit round.

	The art is one imported model (art/home/out/Home.fbx), kept in the place at
	ReplicatedStorage.Props.Home and made a template once in Edit by `Home.prepare`: afterwards the
	template's pivot is the identity, so each part's CFrame is where it stands in a unit's frame
	(the front's parts) or on a piece's own origin (the furnishings).

	`Home.dress(unit, face)` turns a copy of the climb's M unit (walls dropped) into a home's front:
	the M's door rig keeps rolling as on a climb, wearing HomeDoor; the M's facade, frame, padlock
	and number plate give way to the home's. `Home.piece` stands one furnishing.

	The light (S5-03a2b3): the switch by the door flips the unit's lamps (the ceiling lamp and the
	starter floor lamp) with a click, the rocker rocking and the light easing up or down. The server
	owns the state (`LightAttribute` on the unit, FrontOffice), every screen draws it (HomeLights).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Specs = require(script.Specs)

local Home = {}
Home.Specs = Specs
Home.Holding = require(script.Holding)
Home.JobBox = require(script.JobBox)
Home.BoxPanel = require(script.BoxPanel)
Home.Gold = require(script.Gold)
Home.Taken = require(script.Taken)

-- A home's name card over its door (Lobby lays it, FrontOffice letters its holder's name on it,
-- HomeCards sprays the name on): the card's part carries this tag and its slot's number.
Home.CardTag = "HomeCard"
Home.CardSlot = "HomeSlot"

-- The paints, the sheets' own (art/lobby/build.py HOME_TINT): a tinted part shows its Color where
-- its map is clear (AlphaMode Overlay), so one bake serves every colour the owner might pick.
Home.Paint = {
	Facade = Color3.fromHex("#93A68F"), -- the front's wall: the room's sage
	FacadeBack = Color3.fromHex("#E8DFCF"), -- its inside: the units' warm white
	Door = Color3.fromHex("#B5684E"), -- clay: warm, homely, plainly not the climb's oxblood
	Pot = Color3.fromHex("#E9E2D3"), -- cream
	Planter = Color3.fromHex("#D8CCB6"), -- a pale stone
	Beanbag = Color3.fromHex("#B98A3C"), -- mustard, the rug's own
	LampShade = Color3.fromHex("#F1E8D6"), -- a linen drum
	Switch = Color3.fromHex("#F2EEE6"), -- the plate and its rocker: off-white plastic
	ShelfBack = Color3.fromHex("#EFE6D4"), -- the shelf's painted back: a warm cream behind finds
	Sparkle = Color3.fromHex("#FFE296"), -- a new find's glints: the kept glint's warm gold
	Word = Color3.fromHex("#FFF6E2"), -- the "New" over a kind never owned: warm white
	WordEdge = Color3.fromHex("#B5684E"), -- its outline: the door's clay, so it reads on cream
	-- The job box's powder coat (D-287): a dusty blue, calm beside the sage and the clay door, and
	-- the gold sparkle reads on it. Its handles, hasp and hinge a soft graphite steel.
	JobBox = Color3.fromHex("#6A8A93"),
	Fittings = Color3.fromHex("#4A4E52"),
	-- The mirror (D-314): its glass's bevelled edge a pale cool glass with a sheen round the
	-- picture; the felt it stands on a soft brown.
	Bevel = Color3.fromHex("#DCE4E6"),
	Felt = Color3.fromHex("#5A4E44"),
	-- The clothes rail's castors (D-315): a soft dark rubber; its bar and hooks are the
	-- job box's graphite steel.
	Rubber = Color3.fromHex("#2B2826"),
	-- The counter's furniture (D-323, D-324, D-335), the furniture sheet's own paints
	-- (art/home/build.py TINTS, art/home/front.py PLAIN): a mustard milk crate, a sage steel
	-- shelf, a pale folding table, a mover's blue blanket with a cream binding, a camp bed's
	-- olive canvas and cream pillow on bright aluminium.
	Crate = Color3.fromHex("#D2A23A"),
	SteelShelf = Color3.fromHex("#93A88E"),
	Zinc = Color3.fromHex("#8C8F8C"),
	FoldingTable = Color3.fromHex("#E5DFD2"),
	Blanket = Color3.fromHex("#4F6F8F"),
	Binding = Color3.fromHex("#D8C9A6"),
	Canvas = Color3.fromHex("#9C9A78"),
	Pillow = Color3.fromHex("#EDE6D8"),
	Aluminium = Color3.fromHex("#B8BABD"),
	Cable = Color3.fromHex("#141414"),
	Standoff = Color3.fromHex("#BFC2C4"),
	Acrylic = Color3.fromHex("#D9E6EB"),
}
-- The milk crates' colours, a crate at a time in the order you set them out (D-335): the sheet's
-- mustard, teal and terracotta, so a stack of them reads as a hangout, not a warehouse.
Home.CrateColours = { Home.Paint.Crate, Color3.fromHex("#5E8C7E"), Color3.fromHex("#B8613F") }
local TINTED: { [string]: Color3 } = {
	Facade = Home.Paint.Facade,
	FacadeBack = Home.Paint.FacadeBack,
	Pot = Home.Paint.Pot,
	Planter = Home.Paint.Planter,
	Beanbag = Home.Paint.Beanbag,
	LampShade = Home.Paint.LampShade,
	ShelfBack = Home.Paint.ShelfBack,
	JobBox = Home.Paint.JobBox,
	JobBoxLid = Home.Paint.JobBox,
	SteelShelf = Home.Paint.SteelShelf,
	FoldingTable = Home.Paint.FoldingTable,
	Blanket = Home.Paint.Blanket,
	BlanketBinding = Home.Paint.Binding,
	CampBed = Home.Paint.Canvas,
	CampBedPillow = Home.Paint.Pillow,
}
-- Imported with no map: the game gives them their look, a material and a colour (and the neon
-- sign's acrylic backing, how clear it is).
local PLAIN: { [string]: { material: Enum.Material, colour: Color3, clear: number? } } = {
	Switch = { material = Enum.Material.SmoothPlastic, colour = Home.Paint.Switch },
	SwitchToggle = { material = Enum.Material.SmoothPlastic, colour = Home.Paint.Switch },
	Lamp = { material = Enum.Material.SmoothPlastic, colour = Color3.fromRGB(214, 208, 196) },
	JobBoxFittings = { material = Enum.Material.Metal, colour = Home.Paint.Fittings },
	MirrorBevel = { material = Enum.Material.SmoothPlastic, colour = Home.Paint.Bevel },
	MirrorPads = { material = Enum.Material.Fabric, colour = Home.Paint.Felt },
	RailSteel = { material = Enum.Material.Metal, colour = Home.Paint.Fittings },
	RailWheels = { material = Enum.Material.SmoothPlastic, colour = Home.Paint.Rubber },
	MilkCrate = { material = Enum.Material.Plastic, colour = Home.Paint.Crate },
	SteelShelfBolts = { material = Enum.Material.Metal, colour = Home.Paint.Zinc },
	FoldingTableLegs = { material = Enum.Material.Metal, colour = Home.Paint.Fittings },
	CampBedFrame = { material = Enum.Material.Metal, colour = Home.Paint.Aluminium },
	StringLights = { material = Enum.Material.SmoothPlastic, colour = Home.Paint.Cable },
	-- The lit pieces' tubes and bulbs glow in their light's own colour (Specs.Glows), even unlit.
	StringBulbs = {
		material = Enum.Material.Neon,
		colour = Color3.fromHex(Specs.Glows.StringLights.Colour),
	},
	NeonSignTube = {
		material = Enum.Material.Neon,
		colour = Color3.fromHex(Specs.Glows.NeonSign.Colour),
	},
	-- not Glass: Roblox's Glass reads as a grey card in a picture and black from a lit room
	NeonSignBack = {
		material = Enum.Material.SmoothPlastic,
		colour = Home.Paint.Acrylic,
		clear = 0.85,
	},
	NeonSignFittings = { material = Enum.Material.Metal, colour = Home.Paint.Standoff },
}

-- The home front's own parts, set into a unit in place of the M's facade and frame.
Home.FrontParts = { "Facade", "FacadeBack", "Casing", "Frame", "Switch", "SwitchToggle", "Lamp" }
-- The M's parts a home has no use for (the home's own stand in for the first three; its owner's
-- name hangs over it, D-266). The M's padlock stays on the latch, drawn only while the door is
-- padlocked: a spare home's, rented out (the home doc's idea 2, D-275); yours wears none.
Home.Replaced = { "Facade", "FacadeBack", "Frame", "NumberPlate" }
-- The M's door rig, re-dressed in HomeDoor: the same meshes, the DoorKit's own UV layout.
Home.DoorParts =
	{ "CurtainClosed", "Slat_A", "Slat_B", "Slat_C", "BottomBar", "LatchBolt", "Hardware", "Drum" }

-- The unit's light: on (true) or off, the server's to set; a unit is laid with it on, so the first
-- look into your home is a lit room waiting (D-263).
Home.LightAttribute = "HomeLight"
Home.LampTag = "HomeLamp" -- the starter floor lamp's light, on the same switch

-- Feel numbers for the switch.
Home.Switch = {
	Ease = 0.2, -- seconds the light takes to warm up or fade: a soft LED, not a stuttering bulb
	Rock = 0.07, -- seconds the rocker takes to rock over: a snap you see
	Cooldown = 0.2, -- the server drops a unit's flips closer than this (someone mashing it)
	Reach = 6, -- studs: from just inside the door
	ClickVolume = 0.5, -- the climb bulb's toggle click, a touch louder: it's the whole answer
}

-- The floor lamp's own light: a warm pool by the beanbag, under the ceiling lamp's spread.
Home.FloorLamp = {
	Colour = Color3.fromRGB(255, 196, 132),
	Brightness = 0.9,
	Range = 10, -- the rug and the beanbag, not the far wall
	Glow = Color3.fromHex("#FFF1D8"), -- the shade lit from inside (Neon is too hot on a phone)
	-- A phone draws a floor lamp's real light only in the homes nearest you (S5-03a2c, the GDD's
	-- cap on real lights): the two nearest a point just ahead of the camera, within Reach. The
	-- rest keep their shades' glow; their 10-stud pool only shows from in or at a home's door.
	Near = 2,
	Reach = 32, -- studs: from your doorway, your lamp and your neighbour's
	Fade = 0.4, -- seconds a lamp's real light takes to come or go, so the pick never pops
}

-- The parts of a home's front only its insides see (S5-03a2c): the drum the door rolls onto and
-- its head plates and axle, above the doorway behind the front wall. A screen draws them only
-- while its camera is in that home or within InsideMargin studs out of its doorway: from the
-- lobby all twelve were 16k of the spawn view's 160k triangles, every one behind a wall.
-- The mirror (S5-03b, D-280; its frame S5-03f1, D-314): a full-length floor mirror in a
-- moulded oak frame leaning on the unit's left wall by the rug, its glass toward the room, so you
-- turn from the rug and see yourself with your unit behind you. Where it stands, its lean and its
-- glass's size and place are the art's (Specs.Mirror, art/home/home_spec.py).
Home.Mirror = {
	Oak = Color3.fromHex("#B98A5E"), -- the home's oak trim
	Backing = Color3.fromHex("#C9D3D6"), -- the glass where no picture is drawn: cool, pale
	-- The room's walls as the mirror shows them (S5-03b seen): the real ones are merged into the
	-- lobby's meshes, which run behind the glass and can't be copied, so MirrorView stands plain
	-- walls in the picture (art/lobby's unit shells). Studs: their height, the front wall's
	-- inside in from the door face, the doorway's width (the home's facade fills it), the wood
	-- baseboard's height and the partitions' thickness. Wall: the units' warm white.
	Room = { Height = 10, Front = 0.29, Gap = 12, Base = 0.55, Partition = 0.25 },
	Wall = Color3.fromHex("#E8DFCF"),
}
Home.InsideOnly = { "Drum", "Hardware" }
Home.InsideMargin = 2

-- The seats (Roblox Seats): where you sit, in a piece's own frame (its front toward -Z), each
-- turned so you face out the way the piece does. Studs: x, seat's top, z; Turn about Y in degrees.
Home.Seats = {
	Bench = { { -1.4, 1.7, -0.25, 0 }, { 1.4, 1.7, -0.25, 0 } },
	Planter = {
		{ 0, 1.7, -3.15, 0 },
		{ 3.15, 1.7, 0, -90 },
		{ 0, 1.7, 3.15, 180 },
		{ -3.15, 1.7, 0, 90 },
	},
	Beanbag = { { 0, 1.25, 0.1, 0 } },
} :: { [string]: { { number } } }
-- Which pieces' meshes stop you (as boxes): the rug and the leaves don't.
local SOLID: { [string]: boolean } = {
	Pot = true,
	Bench = true,
	Planter = true,
	PlanterSeat = true,
	Beanbag = true,
	FloorLamp = true,
	Shelf = true,
	JobBox = true,
	JobBoxLid = true,
	MirrorFrame = true,
	Rail = true,
}

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

local function part(model: Instance, name: string): BasePart
	local found = model:FindFirstChild(name, true)
	assert(found and found:IsA("BasePart"), `Home: {model:GetFullName()} has no {name}`)
	return found
end

function Home.template(): Model?
	local props = ReplicatedStorage:FindFirstChild("Props")
	local found = if props then props:FindFirstChild("Home") else nil
	return if found and found:IsA("Model") then found else nil
end

-- Gives one of the template's parts its look by its name: a tinted part its paint over its map,
-- a plain part its material and colour (its map dropped), the rest white under their maps.
-- `prepare` runs it on every part; on its own it repaints a template already in the place when
-- the paints change (art/home/README.md, "Into Studio").
function Home.paint(p: BasePart)
	local name = p.Name
	p.Color = TINTED[name] or Color3.new(1, 1, 1)
	local look = p:FindFirstChildOfClass("SurfaceAppearance")
	if look and TINTED[name] then
		look.AlphaMode = Enum.AlphaMode.Overlay -- the paint shows where the map is clear
	end
	local plain = PLAIN[name]
	if plain then
		if look then
			look:Destroy()
		end
		p.Material = plain.material
		p.Color = plain.colour
		p.Transparency = plain.clear or 0
	end
	if name == "MirrorBevel" then
		p.Reflectance = 0.3 -- it catches the light as a bevelled edge does
	end
	-- flat things and things up high shade nothing that matters; the lamp's glow casts none
	if name == "Rug" or name == "Lamp" or name == "Switch" or name == "SwitchToggle" then
		p.CastShadow = false
	end
end

-- Makes an inserted Home.fbx model the template, once, in Edit (art/home/README.md, "Into
-- Studio"): squared on the unit's frame from Specs, anchored and out of physics, painted, its
-- pivot at the identity. Returns how far the worst part stood from where Specs puts it (a check
-- that the frame was read right: under a hundredth of a stud).
function Home.prepare(model: Model): (Model, number)
	local frame = part(model, "Facade").CFrame * CFrame.new(-vec(Specs.Parts.Facade.Centre))
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
	local worst = 0
	for name, spec in Specs.Parts do
		local p = part(model, name)
		local at = frame * CFrame.new(vec(spec.Centre))
		worst = math.max(worst, (p.Position - at.Position).Magnitude)
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		if p:IsA("MeshPart") then
			p.CollisionFidelity = Enum.CollisionFidelity.Box
		end
		p.CFrame = at
		Home.paint(p)
	end
	model.WorldPivot = frame
	model:PivotTo(CFrame.identity)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Home", true)
	return model, worst
end

-- Turns `unit`, a copy of the climb's M unit with its walls dropped standing at `face` (its
-- doorway's outer face, looking out onto the floor), into a home's front: the home's facade,
-- casing, frame, switch and lamp set in; the door re-dressed in HomeDoor and painted clay; the
-- light on. The door stays the M's rig, so Doors and RollUpDoor run it exactly as on a climb.
function Home.dress(template: Model, unit: Model, face: CFrame)
	for _, name in Home.Replaced do
		local old = unit:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	for _, name in Home.FrontParts do
		local p = part(template, name):Clone()
		p.CFrame = face * p.CFrame
		p.Parent = unit
	end
	for _, name in Home.DoorParts do
		local p = unit:FindFirstChild(name)
		local look = part(template, name):FindFirstChildOfClass("SurfaceAppearance")
		if p and look then
			local old = p:FindFirstChildOfClass("SurfaceAppearance")
			if old then
				old:Destroy()
			end
			look:Clone().Parent = p
		end
	end
	for _, d in unit:GetDescendants() do
		if d:IsA("BasePart") and d.Parent == unit then
			local n = d.Name
			if n == "CurtainClosed" or n:sub(1, 5) == "Slat_" then
				continue -- the door: painted below
			elseif TINTED[n] then
				d.Color = TINTED[n]
			elseif not PLAIN[n] and n ~= "DoorCollider" and n ~= "DoorOrigin" then
				d.Color = Color3.new(1, 1, 1)
			end
		end
	end
	Home.paintDoor(unit, Home.Paint.Door)
	unit:SetAttribute(Home.LightAttribute, true)
end

-- Paints a home's door `colour` (the server's word, S5-03g3a): the shut door's one mesh and the
-- three slats every screen's moving door is cloned from (RollUpDoor recolours a moving chain
-- when they change). Tinted parts: the colour shows where the door's map is clear.
function Home.paintDoor(unit: Model, colour: Color3)
	for _, name in { "CurtainClosed", "Slat_A", "Slat_B", "Slat_C" } do
		local p = unit:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Color = colour
		end
	end
end

-- Whether the place's home template has every part of furnishing `kind` (a piece added to the art
-- before the place's Home is re-imported, as the shelf was, D-284, is left out with a warning).
local warned: { [string]: boolean } = {}
function Home.has(template: Model, kind: string): boolean
	local names: { string } = Specs.Pieces[kind] or {}
	for _, name in names do
		if not template:FindFirstChild(name, true) then
			if not warned[kind] then
				warned[kind] = true
				warn(`Home: the place's Home has no {name}; re-import it (art/home/README.md)`)
			end
			return false
		end
	end
	return true
end

-- One furnishing (Specs.Pieces: Plant, Bench, Planter, Rug, Beanbag, FloorLamp, Shelf, JobBox)
-- standing at `at`, its front looking the way `at` does, in a Model named for it: its meshes (the
-- solid ones collide as boxes), its Seats, the floor lamp's light (tagged LampTag, off until a
-- screen lights it), and the job box tagged JobBox.Tag (its lid swings on every screen).
function Home.piece(template: Model, kind: string, at: CFrame, parent: Instance): Model
	local names = Specs.Pieces[kind]
	assert(names, `Home: no piece {kind}`)
	local model = Instance.new("Model")
	model.Name = kind
	for _, name in names do
		local p = part(template, name):Clone()
		p.CFrame = at * p.CFrame
		if SOLID[name] then
			p.CanCollide = true
			p.CanQuery = true
		end
		p.Parent = model
	end
	local seats: { { number } } = Home.Seats[kind] or {}
	for i, s in seats do
		local seat = Instance.new("Seat")
		seat.Name = `Seat{i}`
		seat.Anchored = true
		seat.CanCollide = false
		seat.Transparency = 1
		seat.CastShadow = false
		seat.Size = Vector3.new(1.6, 0.2, 1.4)
		seat.CFrame = at * CFrame.new(s[1], s[2] - 0.1, s[3]) * CFrame.Angles(0, math.rad(s[4]), 0)
		seat.Parent = model
	end
	if kind == "FloorLamp" then
		local shade = part(model, "LampShade")
		local light = Instance.new("PointLight")
		light.Name = "Light"
		light.Color = Home.FloorLamp.Colour
		light.Brightness = Home.FloorLamp.Brightness
		light.Range = Home.FloorLamp.Range
		light.Shadows = false
		light.Enabled = false
		light:AddTag(Home.LampTag)
		light.Parent = shade
	elseif kind == "JobBox" then
		model:AddTag(Home.JobBox.Tag)
	end
	model.WorldPivot = at
	model.Parent = parent
	return model
end

-- A framed mirror (Specs.Mirror's art) standing on `at`, its glass looking along the foot's front
-- and its top leaning back as the art leans, under `parent`: the art's oak frame, bevel and felt
-- pads from the place's Home `template` (left out with a warning if it predates them), and its
-- glass, a plain part tagged Mirror.Tag whose Front face is the picture, set in the frame where the
-- art says. MirrorView draws the reflection on it; the server only stands it. Its glass is returned
-- too, for what the room round it is (`Home.mirror`; the counter's, Lobby.lay).
function Home.mirrorAt(template: Model, at: CFrame, parent: Instance): (Model, Part)
	local m = Specs.Mirror
	local foot = at * CFrame.Angles(math.rad(m.Lean), 0, 0) -- its top back against the wall
	local model = if Home.has(template, "Mirror")
		then Home.piece(template, "Mirror", foot, parent)
		else Instance.new("Model")
	model.Name = "Mirror"
	local thick = 0.04
	local glass = Instance.new("Part")
	glass.Name = "Glass"
	glass.Size = Vector3.new(m.GlassSize[1], m.GlassSize[2], thick)
	glass.CFrame = foot * CFrame.new(vec(m.Glass) + Vector3.new(0, 0, thick / 2))
	glass.Color = Home.Mirror.Backing
	glass.Material = Enum.Material.SmoothPlastic
	glass.Anchored = true
	glass.CanTouch = false
	glass.CanQuery = false
	glass.CastShadow = false
	glass.Reflectance = 0.2
	glass.TopSurface = Enum.SurfaceType.Smooth
	glass.BottomSurface = Enum.SurfaceType.Smooth
	glass:AddTag("Mirror")
	glass.Parent = model
	model.WorldPivot = foot
	model.Parent = parent
	return model, glass
end

-- The mirror (Specs.Mirror) in `unit`, whose doorway's outer face is `face`: leaning on the unit's
-- left wall by the rug (`Home.mirrorAt`), its glass marked with the door's face for the walls
-- MirrorView stands in the picture.
function Home.mirror(template: Model, unit: Model, face: CFrame): Model
	local m = Specs.Mirror
	local at = face * CFrame.new(vec(m.At)) * CFrame.Angles(0, math.rad(m.Turn), 0) -- the glass looks across the unit, off its wall
	local model, glass = Home.mirrorAt(template, at, unit)
	glass:SetAttribute("Face", face) -- the unit's door face, for the walls MirrorView stands
	return model
end

-- The clothes rail (Specs.Rail, S5-03f2a, D-315) in `unit`, whose doorway's outer face is `face`:
-- a rolling oak garment rail along the mirror's wall past it, its front toward the room, from the
-- place's Home `template`. Nil when the template predates it.
function Home.rail(template: Model, unit: Model, face: CFrame): Model?
	if not Home.has(template, "Rail") then
		return nil
	end
	local r = Specs.Rail
	local at = face * CFrame.new(vec(r.At)) * CFrame.Angles(0, math.rad(r.Turn), 0)
	return Home.piece(template, "Rail", at, unit)
end

return Home
