--!strict
--[[
	MachineVend: one sale at the car's machine as every screen in the car sees it (S1-10c2), for
	MachineView, timed by `Machine.Buy.Vend`. The bay's button sinks with a click and comes back
	up; its coil turns one loop with a geared whine, creeping its things forward; the front thing
	rides off the coil's tip, tips over and drops into the bin with its own clunk; the flap knocks
	out and swings back; then the thing is gone from the bin (taken). The others in the coil each
	move up into the place of the one ahead.

	Moving the machine's parts here stays on this screen: the server never moves them. Everything
	ends where it began but the sold thing, which is destroyed.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Battery = require(ReplicatedStorage.Shared.Battery)
local Machine = require(ReplicatedStorage.Shared.Machine)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Buy = Machine.Buy
local Specs = Machine.Specs
local V = Buy.Vend

-- The thing's way down, in the machine's frame: it falls in the gap between the coils and the
-- glass, to rest on the bin's floor behind the flap, inside the flap's width.
local FALL_Z = -0.8
local REST_Y = 0.85
local BIN_X = { -0.45, 1.8 }
-- Degrees it tips forward riding off the tip, and has tumbled by the time it lands.
local TIP = 55
local TUMBLE = 100
-- Degrees the flap knocks out as the thing lands, and how many swings it dies over.
local KNOCK = 18
local SWINGS = 1.5

export type Vend = {
	start: number,
	frame: CFrame, -- the machine's pivot
	key: string,
	thing: PVInstance?,
	pivot: CFrame, -- the thing's pivot as it stood
	centre: Vector3, -- its middle then, world
	push: number, -- studs it rides forward to leave the tip
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

local function ease(u: number): number
	return u * u * (3 - 2 * u)
end

--[[
	Starts the sale of bay `bay` (its catalog key `key`) at `machine`, `things` its things on this
	screen front first (MachineStock's), at `now` (os.clock). Takes the front thing out of
	`things`. `sunk`: this screen pressed the button a moment ago, so it's already down.
]]
function MachineVend.start(
	machine: Model,
	bay: number,
	key: string,
	things: { Instance },
	now: number,
	sunk: boolean
): Vend
	local frame = machine:GetPivot()
	local front = table.remove(things, 1)
	local thing: PVInstance? = if front and front:IsA("PVInstance") then front else nil
	local pivot = if thing then thing:GetPivot() else CFrame.identity
	local centre = if thing then middle(thing) else Vector3.zero
	-- how far its middle is behind the coil's front, in the machine's frame, and a little past
	local coilFront = Specs.Bays[bay].Coil[3] + Specs.CoilFront
	local local0 = frame:PointToObjectSpace(centre)
	local push = math.max(local0.Z - coilFront, 0) + 0.12
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
	return {
		start = now,
		frame = frame,
		key = key,
		thing = thing,
		pivot = pivot,
		centre = centre,
		push = push,
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
		tip = if u > 0.7 then TIP * ease((u - 0.7) / 0.3) else 0
	else
		local u = math.min((t - turnEnd) / V.Fall, 1)
		local top = c0 + Vector3.new(0, 0, -v.push)
		local x = math.clamp(top.X, BIN_X[1], BIN_X[2])
		at = Vector3.new(
			top.X + (x - top.X) * u,
			top.Y + (REST_Y - top.Y) * u * u,
			top.Z + (FALL_Z - top.Z) * u
		)
		tip = TIP + (TUMBLE - TIP) * u
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
	-- the thing: off the tip, down into the bin
	local thing = v.thing
	if thing and thing.Parent then
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
	if t >= landed + V.Flap + V.Gone then
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
end

return MachineVend
