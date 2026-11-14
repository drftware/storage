--!strict
--[[
	MachineVend: one sale at the car's machine as every screen in the car sees it (S1-10c2), for
	MachineView, timed by `Machine.Buy.Vend`. The bay's button sinks with a click and comes back
	up; its coil turns one loop with a geared whine, creeping its things forward; the front thing
	rides off the coil's tip, tips over and drops into the bin with its own clunk; the flap knocks
	out and swings back. As it swings widest, the thing lifts out through the flap and arcs to the
	buyer (`Buy.Attribute` names them): a tool into their left hand, where it then shows, with its
	pick-up sound; a battery into their torch, shrinking as it slides in, with the clack-click,
	and the torch snaps full. Until it lands, every screen holds the change back (InFlight): a
	friend's new tool is hidden in their hand here, your own stays out of your view (ToolView),
	the torch stays as dim as it was (FlashlightView). With nobody to fly to, the thing is just
	gone from the bin. The others in the coil each move up into the place of the one ahead.

	Moving the machine's parts here stays on this screen: the server never moves them. Everything
	ends where it began but the sold thing, which is destroyed.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Battery = require(ReplicatedStorage.Shared.Battery)
local Machine = require(ReplicatedStorage.Shared.Machine)
local Tools = require(ReplicatedStorage.Shared.Tools)
local HandAt = require(script.Parent.HandAt)
local InFlight = require(script.Parent.InFlight)

local Buy = Machine.Buy
local Specs = Machine.Specs
local V = Buy.Vend

-- The thing's way down, in the machine's frame: it falls in the gap between the coils and the
-- glass (halfway between the glass and the coils' tips), to rest on the bin's floor behind the
-- flap, inside the flap's width.
local FALL_Z = (Specs.Glass.Centre[3] + Specs.Bays[1].Coil[3] + Specs.CoilFront) / 2
local REST_Y = 0.85
-- The bin behind the flap runs this deep (art/machine/spec.py's BIN_BACK less the flap's face):
-- a deep thing, lying down once it has tumbled, lands further back so it stays inside it.
local BIN_DEEP = 0.8
local BIN_CLEAR = 0.02
local BIN_X = { -0.45, 1.8 }
-- Degrees it tips forward riding off the tip, and has tumbled by the time it lands: a long thing
-- less, so no part of it crosses the glass (`Buy.tumble`; S2-07b2, the saw's corner did).
local TIP = 55
local TUMBLE = 100
-- Degrees the flap knocks out as the thing lands, and how many swings it dies over.
local KNOCK = 18
local SWINGS = 1.5
-- The arc out of the bin to the hand bows up this much at its middle (half of it at the top).
local UP = Vector3.new(0, Buy.TakeLift, 0)
local me = Players.LocalPlayer

export type Vend = {
	start: number,
	frame: CFrame, -- the machine's pivot
	key: string,
	thing: PVInstance?,
	pivot: CFrame, -- the thing's pivot as it stood
	centre: Vector3, -- its middle then, world
	push: number, -- studs it rides forward to leave the tip
	fallZ: number, -- where its middle lands in the bin, machine frame (`landing`)
	tip: number, -- degrees it tips riding off the tip (TIP, or less if it's long)
	tumble: number, -- and has tumbled to as it lands
	restY: number, -- its middle's height in the bin, raised as much as it stands taller leaning
	rest: { PVInstance }, -- the others in the coil, front first
	from: { CFrame },
	to: { CFrame },
	coil: BasePart?,
	coilAt: CFrame,
	button: BasePart?,
	buttonAt: CFrame,
	flap: BasePart?,
	flapAt: CFrame,
	sink: boolean, -- this screen still sinks the button (not already sunk by a press here)
	stage: number, -- the sounds played so far: 1 the motor, 2 the clunk
	buyer: Player?, -- who it flies to
	hand: InFlight.Hand, -- which of their hands: a battery the torch's, a tool the left
	holding: boolean, -- InFlight holds the buyer's hand until it lands
	binAt: CFrame?, -- its pose in the bin as it lifted out
	size: Vector3, -- a battery's size, shrinking into the torch
	hidden: Model?, -- the friend's new tool in their hand, hidden here until it lands
	hiddenParts: { BasePart },
}

local MachineVend = {}

local function partOf(model: Model, name: string): BasePart?
	local p = model:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

local function middle(thing: PVInstance): Vector3
	if thing:IsA("Model") then
		return (thing:GetBoundingBox()).Position
	end
	return thing:GetPivot().Position
end

-- Half a thing's height and depth as it stands, along the machine's Y and Z.
local function halves(thing: PVInstance, frame: CFrame): (number, number)
	local box, size
	if thing:IsA("Model") then
		box, size = thing:GetBoundingBox()
	elseif thing:IsA("BasePart") then
		box, size = thing.CFrame, thing.Size
	else
		return 0, 0
	end
	local turn = frame.Rotation:ToObjectSpace(box.Rotation)
	local x, y, z = turn.XVector, turn.YVector, turn.ZVector
	return 0.5 * (math.abs(x.Y) * size.X + math.abs(y.Y) * size.Y + math.abs(z.Y) * size.Z),
		0.5 * (math.abs(x.Z) * size.X + math.abs(y.Z) * size.Y + math.abs(z.Z) * size.Z)
end

-- Where a thing's middle lands in the bin along the machine's Z: as near the glass as FALL_Z, but
-- with its front behind the flap once it has tumbled (its height swings toward the glass), and
-- its middle in the bin's middle if it's longer than the bin is deep.
local function landing(hy: number, hz: number): number
	local a = math.rad(TUMBLE)
	local h = math.abs(math.cos(a)) * hz + math.abs(math.sin(a)) * hy
	local flap = Specs.FlapHinge[3]
	local lo, hi = flap + h + BIN_CLEAR, flap + BIN_DEEP - h
	return if lo <= hi then math.clamp(FALL_Z, lo, hi) else flap + BIN_DEEP / 2
end

local function ease(u: number): number
	return u * u * (3 - 2 * u)
end

-- Slow off the bin, then quicker into the hand (as a battery flies to a torch, BatteryView).
local function flyCurve(p: number): number
	return p * p * (3 - 2 * p) * 0.4 + p * p * 0.6
end

--[[
	Starts the sale of bay `bay` (its catalog key `key`) at `machine`, `things` its things on this
	screen front first (MachineStock's), at `now` (os.clock). Takes the front thing out of
	`things`. `sunk`: this screen pressed the button a moment ago, so it's already down. `buyer`:
	who it flies to (nil: nobody, it's just gone from the bin).
]]
function MachineVend.start(
	machine: Model,
	bay: number,
	key: string,
	things: { Instance },
	now: number,
	sunk: boolean,
	buyer: Player?
): Vend
	local frame = machine:GetPivot()
	local front = table.remove(things, 1)
	local thing: PVInstance? = if front and front:IsA("PVInstance") then front else nil
	local pivot = if thing then thing:GetPivot() else CFrame.identity
	local centre = if thing then middle(thing) else Vector3.zero
	-- how far its middle is behind the coil's front, in the machine's frame, and a little past
	local coilFront = Specs.Bays[bay].Coil[3] + Specs.CoilFront
	local local0 = frame:PointToObjectSpace(centre)
	local hy, hz = 0, 0
	if thing then
		hy, hz = halves(thing, frame)
	end
	-- a little past the tip, but a big thing stops short of where its corner would reach through
	-- the glass as it tips and tumbles (its reach is about its box's half diagonal), never short
	-- of leaving the tip
	local reach = math.sqrt(hy * hy + hz * hz)
	local stop = math.max(
		coilFront - 0.12,
		math.min(Specs.Glass.Centre[3] + reach + BIN_CLEAR, coilFront - 0.02)
	)
	local push = math.max(local0.Z - stop, 0)
	-- tipping and tumbling no further than its reach fits behind the glass, at the nearest its
	-- middle comes to the glass on the way (where it leaves the tip, or where it lands)
	local fallZ = if thing then landing(hy, hz) else FALL_Z
	local room = math.min(local0.Z - push, fallZ) - Specs.Glass.Centre[3] - BIN_CLEAR
	local tumble = if thing then Buy.tumble(hy, hz, room, TUMBLE) else TUMBLE
	local function tall(deg: number): number
		local a = math.rad(deg)
		return math.abs(math.sin(a)) * hz + math.abs(math.cos(a)) * hy
	end
	local restY = REST_Y + math.max(tall(tumble) - tall(TUMBLE), 0)
	local rest: { PVInstance } = {}
	local from: { CFrame } = {}
	local to: { CFrame } = {}
	local ahead = pivot
	for _, other in things do
		if other:IsA("PVInstance") then
			local at = other:GetPivot()
			table.insert(rest, other)
			table.insert(from, at)
			-- into the place of the one ahead: its spot, keeping its own turn
			table.insert(to, CFrame.new(ahead.Position) * at.Rotation)
			ahead = at
		end
	end
	local coil = partOf(machine, `Coil{bay}`)
	local button = partOf(machine, `Button{bay}`)
	local flap = partOf(machine, "Flap")
	if button and not sunk then
		Tools.play(Buy.Click, button, Buy.Heard)
	end
	local hand: InFlight.Hand = if key == Machine.Stock.Battery then "torch" else "tool"
	local holding = buyer ~= nil and thing ~= nil
	if holding then
		InFlight.hold(buyer :: Player, hand)
	end
	return {
		start = now,
		frame = frame,
		key = key,
		thing = thing,
		pivot = pivot,
		centre = centre,
		push = push,
		fallZ = fallZ,
		tip = math.min(TIP, tumble),
		tumble = tumble,
		restY = restY,
		rest = rest,
		from = from,
		to = to,
		coil = coil,
		coilAt = if coil then coil:GetPivot() else CFrame.identity,
		button = button,
		buttonAt = if button then button:GetPivot() else CFrame.identity,
		flap = flap,
		flapAt = if flap then flap:GetPivot() else CFrame.identity,
		sink = not sunk,
		stage = 0,
		buyer = if thing then buyer else nil,
		hand = hand,
		holding = holding,
		binAt = nil,
		size = if thing and thing:IsA("BasePart") then thing.Size else Vector3.one,
		hidden = nil,
		hiddenParts = {},
	}
end

-- The button pressed on this screen: down with its click, back up after (`press` before the
-- server's answer; a sale that follows doesn't sink it again).
function MachineVend.press(machine: Model, bay: number): (BasePart?, CFrame)
	local button = partOf(machine, `Button{bay}`)
	if button then
		Tools.play(Buy.Click, button, Buy.Heard)
		return button, button:GetPivot()
	end
	return nil, CFrame.identity
end

-- A button `at` rest, `t` seconds after it was pressed: sunk, then back.
function MachineVend.sinkAt(at: CFrame, t: number): CFrame
	local down = if t < V.Sink
		then t / V.Sink
		elseif t < V.Up then 1
		else math.max(0, 1 - (t - V.Up) / V.Sink)
	return at * CFrame.new(0, 0, Specs.ButtonTravel * down)
end

-- The thing `t` seconds into the vend (machine frame turn about its middle), and where its middle
-- is (world), and whether it has landed.
local function path(v: Vend, t: number): (CFrame, boolean)
	local f = v.frame
	local c0 = f:PointToObjectSpace(v.centre)
	local turnEnd = V.Turn + V.Turning
	local tip, at
	if t < V.Turn then
		return CFrame.new(v.centre) * f.Rotation * CFrame.new(), false
	elseif t < turnEnd then
		local u = (t - V.Turn) / V.Turning
		at = c0 + Vector3.new(0, 0, -v.push * u)
		tip = if u > 0.7 then v.tip * ease((u - 0.7) / 0.3) else 0
	else
		local u = math.min((t - turnEnd) / V.Fall, 1)
		local top = c0 + Vector3.new(0, 0, -v.push)
		local x = math.clamp(top.X, BIN_X[1], BIN_X[2])
		at = Vector3.new(
			top.X + (x - top.X) * u,
			top.Y + (v.restY - top.Y) * u * u,
			top.Z + (v.fallZ - top.Z) * u
		)
		tip = v.tip + (v.tumble - v.tip) * u
		if u >= 1 then
			return CFrame.new(f:PointToWorldSpace(at)) * f.Rotation * CFrame.Angles(
				math.rad(-tip),
				0,
				0
			),
				true
		end
	end
	return CFrame.new(f:PointToWorldSpace(at)) * f.Rotation * CFrame.Angles(math.rad(-tip), 0, 0),
		false
end

-- The friend's tool shown again in their hand.
local function unhide(v: Vend)
	for _, part in v.hiddenParts do
		part.LocalTransparencyModifier = 0
	end
	table.clear(v.hiddenParts)
	v.hidden = nil
end

-- While it's on its way, the friend's new tool stays out of their hand on this screen (the
-- server put it there at once). Yours is ToolView's to hold back.
local function hideHeld(v: Vend)
	local buyer = v.buyer
	if not (buyer and v.holding and v.hand == "tool" and buyer ~= me) then
		return
	end
	local character = buyer.Character
	local found = character and character:FindFirstChild(Tools.HeldName)
	local held = if found and found:IsA("Model") then found else nil
	if held == v.hidden then
		return
	end
	unhide(v)
	if held then
		v.hidden = held
		for _, d in held:GetDescendants() do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = 1
				table.insert(v.hiddenParts, d)
			end
		end
	end
end

-- The buyer's hand is free to show what the server gave it.
local function release(v: Vend)
	if v.holding then
		v.holding = false
		InFlight.land(v.buyer :: Player, v.hand)
	end
	unhide(v)
end

-- It reached the buyer's hand `at`: gone, with its sound there (a tool's pick-up; a battery's
-- clack-click into the torch), and the hand shows what it holds.
local function arrive(v: Vend, at: CFrame)
	local thing = v.thing
	if thing then
		thing:Destroy()
		v.thing = nil
	end
	release(v)
	local holder = Instance.new("Attachment")
	holder.Name = "Bought"
	holder.WorldPosition = at.Position
	holder.Parent = Workspace.Terrain
	if v.hand == "torch" then
		Tools.play(Battery.Clack, holder, Battery.Heard)
		task.delay(Battery.SnapAfter, function()
			if holder.Parent then
				Tools.play(Battery.Snap, holder, Battery.Heard)
			end
		end)
	else
		local row = (Tools.Catalog :: any)[v.key] -- any: the catalog is keyed by text
		if row then
			Tools.play(row.pickUp, holder, Buy.Heard)
		end
	end
	task.delay(2, function()
		holder:Destroy()
	end)
end

-- The thing `p` of the way from the bin to the buyer's hand.
local function fly(v: Vend, thing: PVInstance, p: number)
	local buyer = v.buyer :: Player
	local from = v.binAt
	if not from then
		from = thing:GetPivot()
		v.binAt = from
	end
	local target = if v.hand == "torch" then HandAt.torch(buyer) else HandAt.tool(buyer, v.key)
	if p >= 1 or not target then
		arrive(v, target or from :: CFrame)
		return
	end
	local e = flyCurve(p)
	local at = Buy.arc((from :: CFrame).Position, target.Position, UP, e)
	thing:PivotTo(CFrame.new(at) * (from :: CFrame).Rotation:Lerp(target.Rotation, ease(p)))
	if v.hand == "torch" and thing:IsA("BasePart") then
		thing.Size = v.size * (1 + (Battery.Shrink - 1) * e)
	end
end

-- Steps `v` to `now`. True once it's over (everything back, the thing gone).
function MachineVend.step(v: Vend, now: number): boolean
	local t = now - v.start
	local turnEnd = V.Turn + V.Turning
	local landed = turnEnd + V.Fall
	-- the button
	local button = v.button
	if button and v.sink then
		button:PivotTo(MachineVend.sinkAt(v.buttonAt, t))
	end
	-- the coil, one loop, and the others creeping up
	local coil = v.coil
	local u = math.clamp((t - V.Turn) / V.Turning, 0, 1)
	if coil then
		coil:PivotTo(v.coilAt * CFrame.Angles(0, 0, -2 * math.pi * ease(u)))
	end
	for i, other in v.rest do
		if other.Parent then
			other:PivotTo(v.from[i]:Lerp(v.to[i], ease(u)))
		end
	end
	if v.stage == 0 and t >= V.Turn then
		v.stage = 1
		if coil then
			Tools.play(Buy.Motor, coil, Buy.Heard)
		end
	end
	hideHeld(v)
	-- the thing: off the tip, down into the bin, then out to the buyer's hand
	local thing = v.thing
	local takeAt = landed + Buy.TakeAfter
	if thing and thing.Parent and v.buyer and t >= takeAt then
		fly(v, thing, (t - takeAt) / Buy.Take)
	elseif thing and thing.Parent then
		local pose, down = path(v, math.min(t, landed))
		-- turned about its middle: its pivot follows
		local rel = (CFrame.new(v.centre) * v.frame.Rotation):ToObjectSpace(v.pivot)
		thing:PivotTo(pose * rel)
		if down and v.stage == 1 then
			v.stage = 2
			local drop = if v.key == Machine.Stock.Battery
				then Battery.Clack
				else (Tools.Catalog :: any)[v.key].drop -- any: the catalog is keyed by text
			local flap = v.flap
			Tools.play(drop, flap or coil or thing, Buy.Heard)
			if flap then
				Tools.play(Buy.Knock, flap, Buy.Heard)
			end
		end
	end
	-- the flap, knocked out as it lands, swinging back
	local flap = v.flap
	if flap and t >= landed then
		local s = math.min((t - landed) / V.Flap, 1)
		local swing = KNOCK * math.sin(2 * math.pi * SWINGS * s) * (1 - s) ^ 2
		flap:PivotTo(v.flapAt * CFrame.Angles(math.rad(swing), 0, 0))
	end
	if t >= Buy.ends() then
		MachineVend.finish(v)
		return true
	end
	return false
end

-- Everything back where it stood, the sold thing gone (the vend's end, or the machine cleared).
function MachineVend.finish(v: Vend)
	if v.button and v.sink then
		v.button:PivotTo(v.buttonAt)
	end
	if v.coil then
		v.coil:PivotTo(v.coilAt)
	end
	if v.flap then
		v.flap:PivotTo(v.flapAt)
	end
	for i, other in v.rest do
		if other.Parent then
			other:PivotTo(v.to[i])
		end
	end
	local thing = v.thing
	if thing then
		thing:Destroy()
		v.thing = nil
	end
	release(v)
end

return MachineVend
