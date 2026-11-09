--!strict
--[[
	Leaned: what the server (Ladders) and every screen (LadderView) share about a ladder leaned on a
	unit's front (L-13b2a): the tags and attributes they talk through, and `Leaning`'s numbers made
	into places in the world. `Leaning` is the pure part; this reads the generated Specs.
]]
local Leaning = require(script.Parent.Leaning)
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
	local wire = spec.Colliders.WireTop
	local fit = Leaning.fit(shape, {
		edgeY = header.Position.Y + header.Size.Y / 2,
		-- the colliders are in the unit's frame, whose doorway is the curtain's plane out
		faceZ = header.Position.Z - header.Size.Z / 2 - spec.CurtainPlane,
		wireY = wire.Position.Y + wire.Size.Y / 2,
		doorWidth = spec.DoorWidth,
		width = spec.Width,
	})
	fits[size] = fit
	return fit
end

-- A body's root at a `Leaning` pose on `front`: facing into the unit, tipped forward `pitch`.
function Leaned.pose(front: CFrame, x: number, y: number, z: number, pitch: number): CFrame
	return front * CFrame.new(x, y, z) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(pitch, 0, 0)
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
