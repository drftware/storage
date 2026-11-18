--!strict
--[[
	A sealed find's packaging, on the find itself (S5-02b2b1, D-425; the rules are `Finds/Seal`).

	The server wraps its find the moment it's dealt sealed, in its box or loose, so everyone sees
	it in its pack on the floor and in a friend's hand; each screen wraps its own copies the same
	way (the box's reveal, your hand's view). `wrap` stretches its size's shared pack
	(`Finds/PackFit`, art/finds/packs) round the find as the art fits it (`Seal.fit`), the find in
	the room's middle: upright, turned a quarter round when it's much deeper than wide, or lying on
	its back in its blister when it's flat (`Seal.way`). The pack's board and film are welded to the
	find's own root, weightless and passing through everything, so the find still carries, lies and
	is taken as itself. `lift` is how high the pack holds a lying find off the floor.

	The pack's sounds: a press answered with the plastic's crinkle (it's still sealed: nothing
	happens but the pack shaking in your hand, `Rattle`), and a soft cardboard thud as it's set
	down in place of the find's own clank. Let go hard (`Seal.tears`), the pack tears off as it lands
	(`tear`, S5-02b2b2): a rip, its board and film flung apart with a few scraps, and a plain find.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PackFit = require("./PackFit")
local Seal = require("./Seal")

local Pack = {}

-- The pack's model inside a wrapped find.
Pack.Name = "Pack"

export type Box = { Size: Vector3, Centre: Vector3 }
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }

-- A press on a sealed find, at your hand: "Plastic Bag Handling Crunchy Cellophane 8" (the try-on
-- film's crinkle, Kept.Heap, measured for S2-07) from its first crunch, cut short and pitched up
-- for a small pack. Heard by you and whoever stands next to you.
Pack.Crinkle = table.freeze({
	id = "rbxassetid://9117409739",
	from = 0.36,
	length = 0.35,
	volume = 1.8,
	pitch = 1.3,
})
Pack.CrinkleHeard = 12
-- A sealed find set down: the marked box's flaps' cardboard slap (Boxes.Sounds.Flaps) from its hit,
-- lower and softer, a pack landing on its bottom instead of the find's clank.
Pack.Thud = table.freeze({
	id = "rbxassetid://9113579352",
	from = 0.8,
	length = 0.4,
	volume = 0.65,
	pitch = 0.8,
})
-- The pack shaking in your hand as you press it: how long (s), how far it rocks (degrees) and how
-- fast (rocks a second). Small and quick: a hand testing a sealed box, not a refusal.
Pack.Rattle = table.freeze({ seconds = 0.3, degrees = 7, rate = 26 })

-- How each way turns the pack round the find's middle (Seal.way): turned, the pack's across runs
-- along the find's depth; tipped, the pack's front faces the find's top (it lies on its back).
local TURN: { [Seal.Way]: CFrame } = {
	Upright = CFrame.identity,
	Turned = CFrame.Angles(0, math.pi / 2, 0),
	Tipped = CFrame.Angles(math.pi / 2, 0, 0),
}

local function three(v: Vector3): { number }
	return { v.X, v.Y, v.Z }
end

-- The pack template for catalog size `size`, and its fit; nil when the place lacks it (imported by
-- PIPELINE step 6) or the size has none.
local function templateOf(size: string?): (Model?, PackFit.Pack?)
	local key = Seal.packOf(size)
	local fit = if key then PackFit[key] else nil
	local props = ReplicatedStorage:FindFirstChild("Props")
	local finds = props and props:FindFirstChild("Finds")
	local template = if fit and finds then finds:FindFirstChild(fit.template) else nil
	if template and template:IsA("Model") then
		return template, fit
	end
	return nil, nil
end

-- Wraps `model` (a find of catalog size `size`, its root `body`, its own box `box` from its pivot,
-- `Tools.bounds`) in its pack as it stands now, and marks it sealed (`Seal.Attribute`). False if it
-- has no pack, the place lacks the template, or it's wrapped already.
function Pack.wrap(model: Model, body: BasePart, size: string?, box: Box): boolean
	local template, fit = templateOf(size)
	if not (template and fit) or model:FindFirstChild(Pack.Name) then
		return false
	end
	local find = three(box.Size)
	local s = Seal.fit(Seal.held(find), three(fit.room), fit.pad, fit.stretch)
	local scale = Vector3.new(s[1], s[2], s[3])
	local at = model:GetPivot()
		* CFrame.new(box.Centre)
		* TURN[Seal.way(find)]
		* CFrame.new(-fit.roomCentre * scale)
	local origin = template:GetPivot()
	local pack = Instance.new("Model")
	pack.Name = Pack.Name
	for _, part in template:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		local copy = part:Clone()
		for _, joint in copy:GetChildren() do
			if joint:IsA("JointInstance") or joint:IsA("WeldConstraint") then
				joint:Destroy()
			end
		end
		-- the pack's parts stand square to its pivot, so each stretches along the pack's own axes
		local rel = origin:ToObjectSpace(part.CFrame)
		copy.Size = part.Size * scale
		copy.CFrame = at * CFrame.new(rel.Position * scale) * rel.Rotation
		copy.Anchored = false
		copy.Massless = true
		copy.CanCollide = false
		copy.CanQuery = false
		copy.CanTouch = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = copy
		weld.Parent = copy
		copy.Parent = pack
	end
	pack.Parent = model
	model:SetAttribute(Seal.Attribute, true)
	return true
end

-- A sealed find's outside size packed (`Seal.outer`), for whether it still goes in a marked box
-- (`Deal.packs`); its own size when it has no pack.
function Pack.outer(size: string?, box: Box): { number }
	local template, fit = templateOf(size)
	if not (template and fit) then
		return three(box.Size)
	end
	local s = Seal.fit(Seal.held(three(box.Size)), three(fit.room), fit.pad, fit.stretch)
	local _, extent = template:GetBoundingBox()
	return Seal.outer(three(extent), s)
end

-- How far up a sealed find of catalog size `size` and box `box` lies, over where it would lie
-- loose: its pack under it (`Seal.lift`). 0 with no pack.
function Pack.lift(size: string?, box: Box): number
	local template, fit = templateOf(size)
	if not (template and fit) then
		return 0
	end
	local at, extent = template:GetBoundingBox()
	local back = template:GetPivot():PointToObjectSpace(at.Position).Z + extent.Z / 2
	return math.max(
		0,
		Seal.lift(
			three(box.Size),
			three(fit.room),
			three(fit.roomCentre),
			fit.pad,
			fit.stretch,
			back
		)
	)
end

-- A hard drop tearing the pack off (S5-02b2b2): Kept.Rip's sheet torn hard ("Plastic Sheet Impacts
-- Rips Paper Tears 9" from 0.31 s), cut to its first tear and pitched up a little for a smaller
-- pack. Heard as far as a dropped find's clank, so a monster hears it too.
Pack.Rip = table.freeze({
	id = "rbxassetid://9117625280",
	from = 0.31,
	length = 0.55,
	volume = 1.15,
	pitch = 1.12,
})
-- How the torn pack comes apart: its board and film flung opposite ways (`speed` studs a second
-- out, `up` up, tumbling at up to `spin` radians a second), `scraps` torn bits of card and film
-- (`scrap` studs across) thrown wider, all lying `lies` seconds then fading over `fade`. Quick and
-- small: the pack is gone in two seconds and the find lies bare where it landed.
Pack.Torn = table.freeze({
	speed = { 4, 7 },
	up = { 6, 10 },
	spin = 9,
	scraps = 7,
	scrap = { 0.1, 0.24 },
	scrapSpeed = { 6, 12 },
	lies = 1.4,
	fade = 0.5,
})
-- The scraps' colours: the card's grey-brown core where it tore and its white print face, and the
-- film's clear plastic.
local CARD = { Color3.fromRGB(170, 140, 104), Color3.fromRGB(232, 228, 218) }
local FILM = Color3.fromRGB(220, 232, 240)

local function between(r: { number }): number
	return r[1] + math.random() * (r[2] - r[1])
end

-- The collision group a torn pack's pieces are in: they land on the floor and bump people, never
-- each other, so a scrap made inside the board isn't shot out of it.
Pack.TornGroup = "TornPack"

local function tornGroup(): string
	local name = Pack.TornGroup
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
		PhysicsService:CollisionGroupSetCollidable(name, name, false)
	end
	return name
end

-- `part` loose from everything and ready to be thrown: it falls, lands on the floor (a lying find
-- has no collision to push it about) and touches nothing else that matters.
local function loosen(part: BasePart, group: string)
	part.Anchored = false
	part.Massless = false
	part.CanCollide = true
	part.CanQuery = false
	part.CanTouch = false
	part.CollisionGroup = group
end

-- Throws `part` at `velocity`, tumbling, the server's to move so every screen sees the same throw.
local function fling(part: BasePart, velocity: Vector3)
	local spin = Pack.Torn.spin
	pcall(function() -- pcall: refused if the engine still has it joined to something anchored
		part:SetNetworkOwner(nil)
	end)
	part.AssemblyLinearVelocity = velocity
	part.AssemblyAngularVelocity = Vector3.new(
		(math.random() * 2 - 1) * spin,
		(math.random() * 2 - 1) * spin,
		(math.random() * 2 - 1) * spin
	)
end

-- A random way out across the floor, `speed` fast, with `up` thrown in.
local function outward(a: number, speed: { number }): Vector3
	return Vector3.new(math.cos(a), 0, math.sin(a)) * between(speed)
		+ Vector3.new(0, between(Pack.Torn.up), 0)
end

-- Tears `model`'s pack off as it lands hard (the server's own find, S5-02b2b2): its board and film
-- come away from the find and fly apart with a few scraps, lie a moment and fade; the find is
-- marked sealed no longer. The rip's sound and the bare find settling to the floor are the
-- caller's. False if it had no pack.
function Pack.tear(model: Model): boolean
	model:SetAttribute(Seal.Attribute, nil)
	local pack = model:FindFirstChild(Pack.Name)
	if not (pack and pack:IsA("Model")) then
		return false
	end
	local torn = Pack.Torn
	local group = tornGroup()
	local middle = pack:GetBoundingBox().Position
	pack.Name = "TornPack"
	pack.Parent = workspace
	local throws: { { part: BasePart, velocity: Vector3 } } = {}
	local first = math.random() * 2 * math.pi
	for _, part in pack:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		for _, weld in part:GetChildren() do
			if weld:IsA("WeldConstraint") then
				weld:Destroy()
			end
		end
		loosen(part, group)
		-- the board one way, the film the other, a little either side: pulled apart as they tear
		local a = first + #throws * math.pi + (math.random() - 0.5) * 0.8
		table.insert(throws, { part = part, velocity = outward(a, torn.speed) })
	end
	for i = 1, torn.scraps do
		local film = i % 3 == 0
		local bit = Instance.new("Part")
		bit.Name = "Scrap"
		bit.Size = Vector3.new(between(torn.scrap), 0.03, between(torn.scrap))
		bit.Color = if film then FILM else CARD[i % #CARD + 1]
		bit.Material = if film then Enum.Material.Glass else Enum.Material.Cardboard
		bit.Transparency = if film then 0.55 else 0
		bit.CastShadow = false
		bit.CFrame = CFrame.new(middle)
			* CFrame.Angles(math.random() * 6.28, math.random() * 6.28, math.random() * 6.28)
		loosen(bit, group)
		bit.Parent = pack
		table.insert(throws, {
			part = bit :: BasePart,
			velocity = outward(math.random() * 2 * math.pi, torn.scrapSpeed),
		})
	end
	-- a weld's end reaches the physics only at its next step: thrown before, a piece would still be
	-- part of the anchored find and go nowhere (seen in Studio Play)
	task.spawn(function()
		RunService.Heartbeat:Wait()
		for _, th in throws do
			if th.part.Parent then
				fling(th.part, th.velocity)
			end
		end
	end)
	task.delay(torn.lies, function()
		if not pack.Parent then
			return
		end
		local fade = TweenInfo.new(torn.fade, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, part in pack:GetDescendants() do
			if part:IsA("BasePart") then
				TweenService:Create(part, fade, { Transparency = 1 }):Play()
			end
		end
		task.delay(torn.fade + 0.1, function()
			pack:Destroy()
		end)
	end)
	return true
end

return table.freeze(Pack)
