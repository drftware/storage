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
}
local TINTED: { [string]: Color3 } = {
	Facade = Home.Paint.Facade,
	FacadeBack = Home.Paint.FacadeBack,
	Pot = Home.Paint.Pot,
	Planter = Home.Paint.Planter,
	Beanbag = Home.Paint.Beanbag,
	LampShade = Home.Paint.LampShade,
}
-- Imported with no map: the game gives them their look.
local PLAIN: { [string]: boolean } = { Switch = true, SwitchToggle = true, Lamp = true }

-- The home front's own parts, set into a unit in place of the M's facade and frame.
Home.FrontParts = { "Facade", "FacadeBack", "Casing", "Frame", "Switch", "SwitchToggle", "Lamp" }
-- The M's parts a home has no use for (the home's own stand in for the first three; a home's door
-- latches and its owner's name hangs over it, D-266).
Home.Replaced = { "Facade", "FacadeBack", "Frame", "Padlock", "NumberPlate" }
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
}

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
		p.Color = TINTED[name] or Color3.new(1, 1, 1)
		local look = p:FindFirstChildOfClass("SurfaceAppearance")
		if look and TINTED[name] then
			look.AlphaMode = Enum.AlphaMode.Overlay -- the paint shows where the map is clear
		end
		if PLAIN[name] then
			if look then
				look:Destroy()
			end
			p.Material = Enum.Material.SmoothPlastic
			p.Color = if name == "Lamp" then Color3.fromRGB(214, 208, 196) else Home.Paint.Switch
		end
		-- flat things and things up high shade nothing that matters; the lamp's glow casts none
		if name == "Rug" or name == "Lamp" or name == "Switch" or name == "SwitchToggle" then
			p.CastShadow = false
		end
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
				d.Color = Home.Paint.Door
			elseif TINTED[n] then
				d.Color = TINTED[n]
			elseif not PLAIN[n] and n ~= "DoorCollider" and n ~= "DoorOrigin" then
				d.Color = Color3.new(1, 1, 1)
			end
		end
	end
	unit:SetAttribute(Home.LightAttribute, true)
end

-- One furnishing (Specs.Pieces: Plant, Bench, Planter, Rug, Beanbag, FloorLamp) standing at `at`,
-- its front looking the way `at` does, in a Model named for it: its meshes (the solid ones collide
-- as boxes), its Seats, and the floor lamp's light (tagged LampTag, off until a screen lights it).
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
	end
	model.WorldPivot = at
	model.Parent = parent
	return model
end

return Home
