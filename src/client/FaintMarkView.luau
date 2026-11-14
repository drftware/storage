--!strict
--[[
	FaintMarkView: the faint mark on this screen (S1-11). A floor may carry a small chalk ring on
	one note's door frame (FaintMark; which one, `Deal.markFrom`), stuck on the jamb by the server
	and invisible. This screen shows it only in your own torch's beam and only from a few steps
	away (`FaintMark.seen`), as Phasmophobia's fingerprints show on a door only under the light you
	hold: sweep your beam along the frames as you walk a hall and, close up, one has something
	scrawled on it. It blooms as the beam lands and lingers a moment as the beam moves off; it
	flickers with a dying torch and goes with it. Nothing else says so: no sound, no word, nothing
	on the corner map.

	Your beam is taken from your view (first person: the torch is in your hand at your eye and
	points where you look), as KeeperView takes it. The mark's own face hides it behind walls.
	It does nothing while every mark it knows is out of sight and unlit.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local FaintMark = require(ReplicatedStorage.Shared.FaintMark)

-- Your torch, as FlashlightView tells it: whether it's on on your screen, and the light it gives
-- this frame (0 to 1: a dying torch flickers and sags).
type Beam = {
	on: () -> boolean,
	light: () -> number,
}

-- A mark this screen knows: where it is and which way its face looks (out into the hall), and
-- how much of it shows now (0 to 1).
type Mark = { point: vector, facing: vector, shown: number }

local FaintMarkView = {}

function FaintMarkView.new(beam: Beam): Brix.System
	local marks: { [BasePart]: Mark } = {}
	local connections: { RBXScriptConnection } = {}

	local function add(i: Instance)
		if not i:IsA("BasePart") or marks[i] then
			return
		end
		local cf = i.CFrame
		local p, f = cf.Position, cf.LookVector
		marks[i] = {
			point = vector.create(p.X, p.Y, p.Z),
			facing = vector.create(f.X, f.Y, f.Z),
			shown = 0,
		}
		i.Transparency = 1
	end

	local function remove(i: Instance)
		if i:IsA("BasePart") then
			marks[i] = nil
		end
	end

	local system = { name = "FaintMarkView" }

	function system.start(_: any, _context: Brix.Context)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(FaintMark.Tag):Connect(add)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(FaintMark.Tag):Connect(remove)
		)
		for _, i in CollectionService:GetTagged(FaintMark.Tag) do
			add(i)
		end
	end

	function system.step(_: any, dt: number)
		if next(marks) == nil then
			return
		end
		local on = beam.on()
		local camera = Workspace.CurrentCamera
		local light = if on then beam.light() else 0
		local eye: vector?, aim: vector? = nil, nil
		if on and camera then
			local cf = camera.CFrame
			local e, l = cf.Position, cf.LookVector
			eye, aim = vector.create(e.X, e.Y, e.Z), vector.create(l.X, l.Y, l.Z)
		end
		for part, m in marks do
			local target = if eye and aim then FaintMark.seen(eye, aim, m.point, m.facing) else 0
			if target == 0 and m.shown == 0 then
				continue
			end
			local shown = FaintMark.follow(m.shown, target, dt)
			if target == 0 and shown < 0.004 then
				shown = 0
			end
			m.shown = shown
			part.Transparency = FaintMark.transparency(shown, light)
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		table.clear(marks)
	end

	return system :: any -- any: a plain Brix system built field by field
end

return FaintMarkView
