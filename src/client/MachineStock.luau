--!strict
--[[
	MachineStock: the machine's stock standing in its coils on this screen (S1-10c1), for
	MachineView. Each bay's things are cloned from the game's own art (the tools' templates, the
	battery's) and posed the way a vending machine displays them: a tool stood in the front loop
	of its coil, face to the glass, the long ones across the bay and leaning a little, so each
	reads from the car's gate on a phone; batteries upright, two along each bottom coil. A thing
	rests on the coil's wire where the wire runs along the bottom of its loop (`Specs.CoilFront`,
	`CoilPitch`), so the coil's front loop curls in front of it, as a real machine's do.

	Each row's things live in a folder of their own, parented in only while that row is shown
	(MachineView shows a row as its tube first flashes), so a hidden row costs nothing to draw.
	Nothing here collides, is touched, is hit by a ray or throws a shadow.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Battery = require(ReplicatedStorage.Shared.Battery)
local BatterySpecs = require(ReplicatedStorage.Shared.Battery.Specs)
local Specs = require(ReplicatedStorage.Shared.Machine.Specs)
local Stock = require(ReplicatedStorage.Shared.Machine.Stock)
local Tools = require(ReplicatedStorage.Shared.Tools)

--[[
	How each tool stands in its coil. `long` and `tall` are the tool's own axes (its Specs frame)
	that run across the bay (the machine's +X, your left as you face it) and up; the third faces
	away from the glass. `scale` sizes it for the bay (1.9 wide, about 1.2 to the shelf above):
	the long tools shrink to about 1.7 across, the padlock grows a little so it reads at a phone's
	distance. `lean` tips it, degrees, its left end up, as a long thing propped in a coil sits.
]]
type Pose = { long: Vector3, tall: Vector3, scale: number, lean: number }
local POSES: { [string]: Pose } = {
	-- the jaw on your left, the head's plates to the glass
	BoltCutters = { long = -Vector3.zAxis, tall = Vector3.xAxis, scale = 0.66, lean = 14 },
	-- the blade's tip on your left, teeth down
	Saw = { long = -Vector3.zAxis, tall = Vector3.yAxis, scale = 0.58, lean = 8 },
	-- face on, shackle up
	Padlock = { long = Vector3.xAxis, tall = Vector3.yAxis, scale = 1.35, lean = 0 },
	-- on its side, the trumpet on your left, the can's print to the glass
	AirHorn = { long = Vector3.yAxis, tall = -Vector3.xAxis, scale = 0.85, lean = 10 },
	-- the roll across the bay, its taped end to the glass
	BubbleWrap = { long = Vector3.xAxis, tall = Vector3.yAxis, scale = 0.92, lean = 0 },
}

-- Studs a thing stands above the shelf: on the coil's wire.
local LIFT = 0.03
-- Studs between a thing's front and the coil's tip, so it never hangs over the drop.
local CLEAR = 0.02

export type Shown = {
	rows: { [number]: Folder }, -- each row's things, by row (1 bottom)
	bays: { [number]: { Instance } }, -- each bay's things, front first
}

local MachineStock = {}

local function quiet(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
end

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

-- Half a box of `size` turned by `turn`, along the machine's Y and Z.
local function half(turn: CFrame, size: Vector3): (number, number)
	local x, y, z = turn.XVector, turn.YVector, turn.ZVector
	return 0.5 * (math.abs(x.Y) * size.X + math.abs(y.Y) * size.Y + math.abs(z.Y) * size.Z),
		0.5 * (math.abs(x.Z) * size.X + math.abs(y.Z) * size.Y + math.abs(z.Z) * size.Z)
end

-- Where a thing's middle stands in bay `bay` (machine frame), `back` loops behind the front one,
-- for a thing `hy` half tall and `hz` half deep.
local function stand(bay: Specs.Bay, hy: number, hz: number, back: number): Vector3
	local coil = vec(bay.Coil)
	local front = coil.Z + Specs.CoilFront
	local z = front + math.max(Specs.CoilPitch, hz + CLEAR) + back * Specs.CoilPitch
	return Vector3.new(coil.X, bay.Middle[2] + hy + LIFT, z)
end

-- A tool posed in `bay`, in `frame` (the machine's pivot). Nil if the place lacks its art.
local function tool(key: string, bay: Specs.Bay, frame: CFrame): Model?
	local pose = POSES[key]
	local model = pose and Tools.clone(key, CFrame.identity)
	if not (pose and model) then
		return nil
	end
	local box = Tools.bounds(key)
	model:ScaleTo(pose.scale)
	-- the tool's axes from the machine's (its `long` across the bay, `tall` up), turned round to
	-- stand it in the machine, then the lean
	local toTool = CFrame.fromMatrix(Vector3.zero, pose.long, pose.tall, pose.long:Cross(pose.tall))
	local turn = CFrame.Angles(0, 0, math.rad(pose.lean)) * toTool:Inverse()
	local hy, hz = half(turn, box.Size * pose.scale)
	local at = stand(bay, hy, hz, 0)
	model:PivotTo(frame * CFrame.new(at) * turn * CFrame.new(-box.Centre * pose.scale))
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			quiet(d)
		end
	end
	return model
end

-- `count` batteries upright along `bay`'s coil, front first (at most the two the coil holds).
local function batteries(count: number, bay: Specs.Bay, frame: CFrame, into: { Instance })
	local props = ReplicatedStorage:FindFirstChild("Props")
	local template = props and props:FindFirstChild(Battery.Template)
	if not (template and template:IsA("BasePart")) then
		return
	end
	local size = BatterySpecs.Battery.Size
	for k = 1, math.min(count, Stock.Batteries) do
		local b = template:Clone()
		quiet(b)
		-- each in every other loop: a battery is wider than one
		local at = stand(bay, size.Y / 2, size.X / 2, (k - 1) * 2)
		b.CFrame = frame * CFrame.new(at)
		table.insert(into, b)
	end
end

--[[
	Fills `machine`'s coils with `stock` (MachineView calls it as the stock arrives or changes),
	each row's things in a folder of their own, none parented in yet (`show`). Returns what it
	made, for `show` and `clear`.
]]
function MachineStock.fill(machine: Model, stock: Stock.Stock): Shown
	local frame = machine:GetPivot()
	local shown: Shown = { rows = {}, bays = {} }
	for i, bay in Specs.Bays do
		local s = stock[i]
		local things: { Instance } = {}
		if s and s.count > 0 then
			if s.key == Stock.Battery then
				batteries(s.count, bay, frame, things)
			else
				local model = tool(s.key, bay, frame)
				if model then
					table.insert(things, model)
				end
			end
		end
		local folder: Folder
		local had = shown.rows[bay.Row]
		if had then
			folder = had
		else
			folder = Instance.new("Folder")
			folder.Name = `StockRow{bay.Row}`
			shown.rows[bay.Row] = folder
		end
		for _, thing in things do
			thing.Parent = folder
		end
		shown.bays[i] = things
	end
	return shown
end

-- Row `row`'s things in the machine, or out of it.
function MachineStock.show(shown: Shown, machine: Model, row: number, on: boolean)
	local folder = shown.rows[row]
	if folder then
		local parent: Instance? = if on then machine else nil
		if folder.Parent ~= parent then
			folder.Parent = parent
		end
	end
end

-- Everything `fill` made, gone.
function MachineStock.clear(shown: Shown)
	for _, folder in shown.rows do
		folder:Destroy()
	end
	table.clear(shown.rows)
	table.clear(shown.bays)
end

return MachineStock
