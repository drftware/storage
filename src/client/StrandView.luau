--!strict
--[[
	StrandView: the fairy lights laid along a hall, on every screen (F-G1e5c, D-294).

	The moment: you let the lit fairy lights fall in a dark hall and the string slithers out along
	the floor from the box, a dotted line of warm LEDs lighting the concrete; a Mannequin coming
	down the hall stops dead where it meets the line. Picked up, it's the coil in your hand again.

	The server lays it (`FindUses`: tagged `Strand.Tag`, its line from `Strand.FromAttribute` to
	`Strand.ToAttribute`, laid at `Strand.AtAttribute`). Here each one is drawn in a folder of its
	own, never inside the find: its twenty LEDs (small neon drops that glow with no light of their
	own), the copper wire between them, lying loose (`Strand.sway`), and one dim real light at its
	far half (the coil's own lights the box end), so a whole string costs one light more. The coil
	is hidden while it's laid out. Just laid, it runs out from the box over `Strand.RunOut` with its
	slither, stepped only while one is running out; one seen later is drawn whole, in silence.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Strand = require(ReplicatedStorage.Shared.Finds.Strand)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Use = require(ReplicatedStorage.Shared.Finds.Use)

local WIRE = Color3.fromRGB(184, 104, 60) -- the enamelled copper (the art's wire)
local LED = Color3.fromRGB(255, 184, 116) -- warm white, the art's glow tint
-- an LED drop: bolder than life (the art's is 0.022 long) so each reads as a point on a phone
local BEAD = Vector3.new(0.07, 0.07, 0.11)
local WIRE_WIDTH = 0.022 -- the wire, as the art draws it (twice life, so it reads)
local LIFT = 0.04 -- studs above the floor the string lies (on it, never in it)
-- the one real light along it, at its far half: dim and short, as the art's coil (range 9,
-- brightness 0.6) is round the box, so the line reads as one glow on the floor
local LAMP_AT, LAMP_RANGE, LAMP_BRIGHTNESS, LAMP_HEIGHT = 0.7, 7, 0.55, 0.6
local HEARD = 40 -- studs its slither carries
local JUST = 1 -- seconds after it was laid that a screen seeing it still plays it running out

type Drawn = {
	folder: Folder,
	beads: { BasePart },
	along: { number }, -- each bead's share of the way along
	wires: { Beam },
	light: PointLight,
	at: number, -- the server clock it was laid
	coil: BasePart?, -- the coil, hidden while it's laid out
}

local StrandView = {}

function StrandView.new(): Brix.System
	local root: Folder? = nil
	local drawn: { [Instance]: Drawn } = {}
	local running = 0 -- how many are running out now
	local stepping: RBXScriptConnection? = nil
	local connections: { RBXScriptConnection } = {}

	-- how far each of `d`'s beads and wires shows `t` seconds after it was laid
	local function show(d: Drawn, out: number)
		for i, bead in d.beads do
			bead.Transparency = if d.along[i] <= out then 0 else 1
		end
		for i, wire in d.wires do
			wire.Enabled = (if i == 1 then 0 else d.along[i - 1]) <= out
		end
		d.light.Brightness = LAMP_BRIGHTNESS * out
	end

	local function step()
		local now = Workspace:GetServerTimeNow()
		running = 0
		for _, d in drawn do
			local out = Strand.out(now - d.at)
			show(d, out)
			if out < 1 then
				running += 1
			end
		end
		if running == 0 and stepping then
			stepping:Disconnect()
			stepping = nil
		end
	end

	local function undraw(model: Instance)
		local d = drawn[model]
		if not d then
			return
		end
		drawn[model] = nil
		d.folder:Destroy()
		if d.coil then
			d.coil.LocalTransparencyModifier = 0
		end
	end

	local function draw(model: Instance)
		undraw(model)
		local a = model:GetAttribute(Strand.FromAttribute)
		local b = model:GetAttribute(Strand.ToAttribute)
		local at = model:GetAttribute(Strand.AtAttribute)
		local parent = root
		if
			not (model:IsA("Model") and typeof(a) == "Vector3" and typeof(b) == "Vector3")
			or type(at) ~= "number"
			or not parent
		then
			return
		end
		local run = (b - a).Magnitude
		if run < 1e-3 then
			return
		end
		local key = model:GetAttribute(Use.KeyAttribute)
		local row = if type(key) == "string" then Use.Rows[key] else nil
		local art = if type(key) == "string" then Finds.art(key) else nil
		local dir = (b - a).Unit
		local side = dir:Cross(Vector3.yAxis).Unit
		local function point(d: number): Vector3
			return a + dir * d + side * Strand.sway(d, run) + Vector3.new(0, LIFT, 0)
		end

		local folder = Instance.new("Folder")
		folder.Name = model.Name
		-- one still part holds the wire's ends and the light
		local hold = Instance.new("Part")
		hold.Name = "Hold"
		hold.Anchored, hold.CanCollide, hold.CanQuery, hold.CanTouch = true, false, false, false
		hold.Transparency, hold.Size, hold.CastShadow = 1, Vector3.one * 0.05, false
		hold.CFrame = CFrame.new(a)
		hold.Parent = folder
		local function attach(p: Vector3): Attachment
			local at0 = Instance.new("Attachment")
			at0.WorldPosition = p
			at0.Parent = hold
			return at0
		end
		local beads: { BasePart }, along: { number }, wires: { Beam } = {}, {}, {}
		local last = attach(point(0))
		for _, d in Strand.beads(run) do
			local p = point(d)
			local ahead = point(math.min(d + 0.05, run))
			local bead = Instance.new("Part")
			bead.Name = "Bead"
			bead.Anchored, bead.CanCollide, bead.CanQuery, bead.CanTouch = true, false, false, false
			bead.Material, bead.Color, bead.CastShadow = Enum.Material.Neon, LED, false
			bead.Size = BEAD
			bead.CFrame = CFrame.lookAt(p, if (ahead - p).Magnitude > 1e-4 then ahead else p + dir)
			bead.Transparency = 1
			bead.Parent = folder
			table.insert(beads, bead)
			table.insert(along, d / run)
			local here = attach(p)
			local wire = Instance.new("Beam")
			wire.Attachment0, wire.Attachment1 = last, here
			wire.Width0, wire.Width1, wire.FaceCamera, wire.Segments =
				WIRE_WIDTH, WIRE_WIDTH, true, 1
			wire.Color = ColorSequence.new(WIRE)
			wire.LightInfluence, wire.Transparency = 1, NumberSequence.new(0)
			wire.Enabled = false
			wire.Parent = hold
			table.insert(wires, wire)
			last = here
		end
		local lamp = attach(point(run * LAMP_AT) + Vector3.new(0, LAMP_HEIGHT, 0))
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Shadows, light.Brightness = LED, LAMP_RANGE, false, 0
		light.Parent = lamp

		-- the coil, hidden while it's laid out
		local glow = art and art.Glow
		local found = if glow then model:FindFirstChild(glow.Part, true) else nil
		local coil = if found and found:IsA("BasePart") then found else nil
		if coil then
			coil.LocalTransparencyModifier = 1
		end
		folder.Parent = parent
		local d: Drawn = {
			folder = folder,
			beads = beads,
			along = along,
			wires = wires,
			light = light,
			at = at,
			coil = coil,
		}
		drawn[model] = d
		local since = Workspace:GetServerTimeNow() - at
		if since < JUST and row and row.lays then
			Tools.play(row.lays.sound, hold, HEARD)
		end
		show(d, Strand.out(since))
		if since < Strand.RunOut and not stepping then
			stepping = RunService.Heartbeat:Connect(step)
		end
	end

	return {
		name = "StrandView",
		start = function(_: any, _context: Brix.Context)
			local f = Instance.new("Folder")
			f.Name = "LaidStrands"
			f.Parent = Workspace
			root = f
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Strand.Tag):Connect(draw)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Strand.Tag):Connect(undraw)
			)
			for _, model in CollectionService:GetTagged(Strand.Tag) do
				draw(model)
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			if stepping then
				stepping:Disconnect()
				stepping = nil
			end
			for model in drawn do
				undraw(model)
			end
			if root then
				root:Destroy()
				root = nil
			end
		end,
	}
end

return StrandView
