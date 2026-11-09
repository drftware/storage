--!strict
--[[
	Leaned: what the server (Ladders) and every screen (LadderView) share about a ladder leaned on a
	unit's front (L-13b2a): the tags and attributes they talk through, and `Leaning`'s numbers made
	into places in the world. `Leaning` is the pure part; this reads the generated Specs.
]]
local CollectionService = game:GetService("CollectionService")

local Leaning = require(script.Parent.Leaning)
local Tops = require(script.Parent.Parent.Tops)
local Specs = require(script.Parent.Specs.Ladder)
local UnitSpecs = require(script.Parent.Parent.StorageUnit.Specs)

local Leaned = {}

-- On a leaned ladder's model (the server's): the tag, the server time it began going up, and where
-- it came from (its pivot on the carrier's shoulder) and goes to (leaned), so every screen plays
-- it swinging up and the fly running out.
Leaned.Tag = "LeanedLadder"
Leaned.StartAttribute = "RaiseStart"
Leaned.FromAttribute = "RaiseFrom"
Leaned.ToAttribute = "RaiseTo"

-- On a climber's character (the server's): the tag while they're on a ladder or lying at its
-- top, the move ("Up", "Top" lying there, "Down"), the server time it began, the front's frame,
-- the unit's size and their lying spot, so every screen plays the move.
Leaned.ClimbTag = "OnLadder"
Leaned.MoveAttribute = "LadderMove"
Leaned.MoveStartAttribute = "LadderStart"
Leaned.FrontAttribute = "LadderFront"
Leaned.SizeAttribute = "LadderSize"
Leaned.SpotAttribute = "LadderSpot"
-- Along the tops (L-13b2c): the move is "Top" while you crawl, "Drop" as you drop off a front
-- (the front's frame then the unit's, and this the place along it you go over); the server sets
-- `FixAttribute` to where it puts you back when your screen claims a place off the tops.
Leaned.DropAttribute = "LadderDropX"
Leaned.FixAttribute = "TopsFix"
-- On the buttons only someone up on the tops sees: Climb down at a ladder's top, Drop down at
-- every unit's front.
Leaned.TopButtonTag = "TopsButton"

local fits: { [string]: Leaning.Fit } = {}

-- The ladder's shape, from its generated Specs.
local shape: Leaning.Shape = {
	feetZ = Specs.Feet.Z,
	back = Specs.Bounds.Centre.Y - Specs.Bounds.Size.Y / 2,
	centreX = Specs.Bounds.Centre.X,
	topZ = Specs.Top.Z,
	travel = Specs.Travel,
}

-- The ladder leaned on a unit of size `size`'s front ("S", "M").
function Leaned.fit(size: string): Leaning.Fit
	local cached = fits[size]
	if cached then
		return cached
	end
	local spec = UnitSpecs[size] or UnitSpecs.M
	local header = spec.Colliders.Header
	local top = spec.Colliders.Top
	local fit = Leaning.fit(shape, {
		edgeY = header.Position.Y + header.Size.Y / 2,
		-- the colliders are in the unit's frame, whose doorway is the curtain's plane out
		faceZ = header.Position.Z - header.Size.Z / 2 - spec.CurtainPlane,
		topY = top.Position.Y + top.Size.Y / 2,
		doorWidth = spec.DoorWidth,
		width = spec.Width,
	})
	fits[size] = fit
	return fit
end

-- A unit of size `size`'s inside width, along its front.
function Leaned.width(size: string): number
	return (UnitSpecs[size] or UnitSpecs.M).Width
end

-- A body's root at a `Leaning` pose on `front`: facing into the unit, tipped forward `pitch`.
function Leaned.pose(front: CFrame, x: number, y: number, z: number, pitch: number): CFrame
	return front * CFrame.new(x, y, z) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(pitch, 0, 0)
end

-- A body's root at a pose on `front` facing out into the hall, tipped forward `pitch`.
function Leaned.outward(front: CFrame, x: number, y: number, z: number, pitch: number): CFrame
	return front * CFrame.new(x, y, z) * CFrame.Angles(pitch, 0, 0)
end

type MapEntry = { text: string, map: Tops.Map, origin: CFrame }
local maps: { [Instance]: MapEntry } = {}

--[[
	The tops' map under a point in the world, and the frame it's in: whichever floor (or the test
	hall) has steel there. Read from the tag and attributes the server puts on each (FloorBuilder),
	decoded once per text.
]]
function Leaned.tops(at: Vector3): (Tops.Map?, CFrame?)
	for inst in maps do
		if not inst.Parent then
			maps[inst] = nil
		end
	end
	for _, inst in CollectionService:GetTagged(Tops.Tag) do
		local text = inst:GetAttribute(Tops.MapAttribute)
		local origin = inst:GetAttribute(Tops.OriginAttribute)
		if type(text) ~= "string" or typeof(origin) ~= "CFrame" then
			continue
		end
		local entry = maps[inst]
		if not entry or entry.text ~= text then
			local map = Tops.decode(text)
			if not map then
				continue
			end
			local fresh: MapEntry = { text = text, map = map, origin = origin }
			maps[inst] = fresh
			entry = fresh
		end
		local e = entry
		if not e then
			continue
		end
		local p = e.origin:PointToObjectSpace(at)
		if Tops.near(e.map, p.X, p.Z, Tops.Slack) then
			return e.map, e.origin
		end
	end
	return nil, nil
end

-- The leaned ladder's pivot (its grip) on `front`.
function Leaned.pivot(front: CFrame, fit: Leaning.Fit): CFrame
	return front
		* CFrame.new(fit.ox, fit.oy, fit.oz)
		* CFrame.Angles(0, math.pi, 0)
		* CFrame.Angles(Leaning.Angle, 0, 0)
end

-- A point of the leaned ladder (its own frame) in the world.
function Leaned.point(front: CFrame, fit: Leaning.Fit, lx: number, ly: number, lz: number): Vector3
	local x, y, z = Leaning.point(fit, lx, ly, lz)
	return front * Vector3.new(x, y, z)
end

-- The fly's weld on the base, `out` (0 to 1) of the way run out.
function Leaned.fly(out: number): CFrame
	return CFrame.new(Specs.Fly.Centre - Specs.Body.Centre - Vector3.new(0, 0, Specs.Travel * out))
end

return Leaned
