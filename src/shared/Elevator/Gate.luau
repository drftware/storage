--!strict
-- The freight elevator's folding gate, posed: what art/elevator/spec.py's gate_pose does for the
-- look sheets, in Roblox's frame. Pure (plain numbers), so Lune checks it.
--
-- A collapsible lattice gate, as old freight cars have: thirteen pickets, the last the lead with
-- the pull, spread evenly from the first (fixed to the left post as you face the car, the
-- elevator's +X) to the lead. In each bay two straps cross, pinned at their middles,
-- their ends riding up and down the pickets' channels, so for any spread a strap's angle from
-- level is acos(pitch / its length) and its ends stay on the pickets. `shut` 0 is folded open,
-- 1 is shut.

local Specs = require("./Specs")

local G = Specs.Gate

export type Strap = {
	X: number, -- its middle pin, across the elevator
	Y: number, -- the row of tongs it's in
	Z: number, -- its layer, in front of the pickets
	Angle: number, -- its turn about the elevator's Z axis (radians)
}
export type Pose = {
	Pickets: { number }, -- each picket's middle (X), the first fixed, the last the lead
	Pitch: number, -- picket to picket (studs)
	Angle: number, -- the straps' angle from level (radians)
	Straps: { Strap }, -- bay by bay, row by row: the rising strap, then the falling one
}

local Gate = {}

-- The lead's middle (X) with the gate `shut` of the way closed.
function Gate.lead(shut: number): number
	local t = math.clamp(shut, 0, 1)
	return G.Open + (G.Closed - G.Open) * t
end

-- How far the gate is shut (0 to 1) with its lead at `x`: the inverse of `lead`.
function Gate.shutAt(x: number): number
	return math.clamp((x - G.Open) / (G.Closed - G.Open), 0, 1)
end

function Gate.pose(shut: number): Pose
	local lead = Gate.lead(shut)
	local n = G.Pickets
	local step = (lead - G.Stack) / (n - 1)
	local pitch = math.abs(step)
	local angle = math.acos(math.min(pitch / G.Strap, 1))
	local pickets = table.create(n) :: { number }
	for i = 1, n do
		pickets[i] = G.Stack + (i - 1) * step
	end
	local straps = table.create((n - 1) * #G.Rows * 2) :: { Strap }
	-- The gate closes toward -X, so a strap rising toward the lead turns the other way from
	-- one rising toward +X; the front layer's straps rise toward the lead.
	local rise = if step < 0 then -angle else angle
	for i = 1, n - 1 do
		local x = (pickets[i] + pickets[i + 1]) / 2
		for _, y in G.Rows do
			table.insert(straps, { X = x, Y = y, Z = G.Layers[1], Angle = rise })
			table.insert(straps, { X = x, Y = y, Z = G.Layers[2], Angle = -rise })
		end
	end
	return { Pickets = pickets, Pitch = pitch, Angle = angle, Straps = straps }
end

-- The gap the lead still has to close (studs): what the last one aboard dives through. 0 shut.
function Gate.gap(shut: number): number
	return math.abs(Gate.lead(shut) - G.Closed)
end

return Gate
