--!strict
--[[
	MinimapDrawing: one floor's map drawn as Frames (L-10), apart from the window it sits in, so a
	full map behind a button can draw the same thing bigger. Made from `Minimap.from`'s pieces: the
	lobby and the car drawn from the start, every other hall and its units dark until `walk` fills
	them in, each easing in over `Minimap.Reveal`; an opened unit (`open`) gets a tick that pops
	in once its hall is drawn.

	The canvas covers the floor's bounds; everything on it sits by scale, so `scale` (points a
	stud) changes only the canvas's size. `place` puts a floor point at a point of the parent.
	Nothing here runs each frame.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Minimap = require(ReplicatedStorage.Shared.Minimap)

-- The look, read at phone size against a dark window.
local HALL = Color3.fromRGB(176, 170, 156) -- concrete under the tubes
local HALL_SHOWN = 0.12 -- its transparency once drawn
local LOBBY = Color3.fromRGB(206, 200, 184) -- a shade lighter: where you came in
local CAR = Color3.fromRGB(236, 184, 62) -- the gate's amber: where you're going
local UNIT = Color3.fromRGB(62, 60, 56) -- a shut unit, darker than the hall it opens onto
local UNIT_OPENED = Color3.fromRGB(86, 132, 80) -- an opened one: green, the sign that reads at phone size
local UNIT_SHOWN = 0.08
local UNIT_INSET = 0.7 -- studs in from each side, so neighbours read as two squares
local TICK = Color3.fromRGB(236, 248, 230) -- the tick on it: searched (thin, so it shows on bigger maps)
local TICK_FROM = 1.8 -- the tick pops in from this size, settling to its square

export type Drawing = {
	canvas: Frame,
	-- Fills in piece `piece` and its units, eased. True if it wasn't drawn before.
	walk: (self: Drawing, piece: number) -> boolean,
	-- Ticks each unit in `opened` (by slot) not ticked yet; one in a dark hall pops in with it.
	open: (self: Drawing, opened: { [number]: boolean }) -> (),
	-- Points a stud.
	scale: (self: Drawing, pointsPerStud: number) -> (),
	-- Puts floor point (x, z) at (px, py) in the parent's points.
	place: (self: Drawing, px: number, py: number, x: number, z: number) -> (),
	destroy: (self: Drawing) -> (),
}

type UnitEntry = { box: Frame, tick: TextLabel, pop: UIScale, piece: number, ticked: boolean }

local MinimapDrawing = {}

local REVEAL = TweenInfo.new(Minimap.Reveal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local POP = TweenInfo.new(Minimap.Tick, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

function MinimapDrawing.new(map: Minimap.Map, parent: Instance): Drawing
	local b = map.bounds
	local bw, bh = b.x1 - b.x0, b.z1 - b.z0
	local s = 1

	local canvas = Instance.new("Frame")
	canvas.Name = "Floor"
	canvas.BackgroundTransparency = 1
	canvas.BorderSizePixel = 0
	canvas.Size = UDim2.fromOffset(bw, bh)

	-- a rectangle on the floor as a Frame on the canvas, by scale
	local function box(r: Minimap.Rect, inset: number, colour: Color3, z: number): Frame
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = colour
		f.BackgroundTransparency = 1
		f.Position = UDim2.fromScale((r.x0 + inset - b.x0) / bw, (r.z0 + inset - b.z0) / bh)
		f.Size = UDim2.fromScale((r.x1 - r.x0 - 2 * inset) / bw, (r.z1 - r.z0 - 2 * inset) / bh)
		f.ZIndex = z
		f.Parent = canvas
		return f
	end

	local pieces: { { Frame } } = {}
	local unitsOf: { { UnitEntry } } = {}
	local shown: { [number]: number } = {} -- each piece's drawn transparency
	for i, p in map.pieces do
		local colour = if p.kind == "Elevator" then CAR elseif p.kind == "Lobby" then LOBBY else HALL
		local frames: { Frame } = {}
		for _, r in p.rects do
			table.insert(frames, box(r, 0, colour, 1))
		end
		pieces[i] = frames
		unitsOf[i] = {}
		shown[i] = if p.kind == "Elevator" then 0 else HALL_SHOWN
	end
	local bySlot: { [number]: UnitEntry } = {}
	for _, u in map.units do
		local f = box(u.rect, UNIT_INSET, UNIT, 2)
		local tick = Instance.new("TextLabel")
		tick.BackgroundTransparency = 1
		tick.Size = UDim2.fromScale(1, 1)
		tick.Text = "✓"
		tick.TextScaled = true
		tick.FontFace = Font.fromEnum(Enum.Font.BuilderSansBold)
		tick.TextColor3 = TICK
		tick.TextTransparency = 1
		tick.ZIndex = 3
		local pop = Instance.new("UIScale")
		pop.Scale = TICK_FROM
		pop.Parent = tick
		tick.Parent = f
		local entry: UnitEntry =
			{ box = f, tick = tick, pop = pop, piece = u.piece, ticked = false }
		bySlot[u.slot] = entry
		table.insert(unitsOf[u.piece], entry)
	end

	local walked: { [number]: boolean } = {}

	local function popTick(e: UnitEntry, eased: boolean)
		if eased then
			TweenService:Create(e.tick, POP, { TextTransparency = 0 }):Play()
			TweenService:Create(e.pop, POP, { Scale = 1 }):Play()
			TweenService:Create(e.box, REVEAL, { BackgroundColor3 = UNIT_OPENED }):Play()
		else
			e.tick.TextTransparency = 0
			e.pop.Scale = 1
			e.box.BackgroundColor3 = UNIT_OPENED
		end
	end

	local function fill(piece: number, eased: boolean)
		walked[piece] = true
		local goal = shown[piece]
		for _, f in pieces[piece] do
			if eased then
				TweenService:Create(f, REVEAL, { BackgroundTransparency = goal }):Play()
			else
				f.BackgroundTransparency = goal
			end
		end
		for _, e in unitsOf[piece] do
			if eased then
				TweenService:Create(e.box, REVEAL, { BackgroundTransparency = UNIT_SHOWN }):Play()
			else
				e.box.BackgroundTransparency = UNIT_SHOWN
			end
			if e.ticked then
				popTick(e, eased)
			end
		end
	end

	-- the lobby and the car from the start, with the lobby's units
	fill(map.lobby, false)
	fill(map.elevator, false)
	canvas.Parent = parent

	local drawing = { canvas = canvas }

	function drawing.walk(_: Drawing, piece: number): boolean
		if walked[piece] or not pieces[piece] then
			return false
		end
		fill(piece, true)
		return true
	end

	function drawing.open(_: Drawing, opened: { [number]: boolean })
		for slot in opened do
			local e = bySlot[slot]
			if e and not e.ticked then
				e.ticked = true
				if walked[e.piece] then
					popTick(e, true)
				end
			end
		end
	end

	function drawing.scale(_: Drawing, pointsPerStud: number)
		s = pointsPerStud
		canvas.Size = UDim2.fromOffset(bw * s, bh * s)
	end

	function drawing.place(_: Drawing, px: number, py: number, x: number, z: number)
		canvas.Position = UDim2.fromOffset(px - (x - b.x0) * s, py - (z - b.z0) * s)
	end

	function drawing.destroy(_: Drawing)
		canvas:Destroy()
	end

	return (drawing :: any) :: Drawing -- any: the table above is a Drawing, built a field at a time
end

return MinimapDrawing
