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

-- The gate's pose `shut` of the way closed. With `into`, refills that pose's own tables and
-- returns it, so a gate animated every frame makes no garbage.
function Gate.pose(shut: number, into: Pose?): Pose
	local lead = Gate.lead(shut)
	local n = G.Pickets
	local step = (lead - G.Stack) / (n - 1)
	local pitch = math.abs(step)
	local angle = math.acos(math.min(pitch / G.Strap, 1))
	local pose: Pose = into
		or {
			Pickets = table.create(n, 0),
			Pitch = 0,
			Angle = 0,
			Straps = table.create((n - 1) * #G.Rows * 2),
		}
	local pickets = pose.Pickets
	for i = 1, n do
		pickets[i] = G.Stack + (i - 1) * step
	end
	-- The gate closes toward -X, so a strap rising toward the lead turns the other way from
	-- one rising toward +X; the front layer's straps rise toward the lead.
	local rise = if step < 0 then -angle else angle
	local straps = pose.Straps
	local k = 0
	for i = 1, n - 1 do
		local x = (pickets[i] + pickets[i + 1]) / 2
		for _, y in G.Rows do
			for layer = 1, 2 do
				k += 1
				local s = straps[k]
				if not s then
					s = { X = 0, Y = 0, Z = 0, Angle = 0 }
					straps[k] = s
				end
				s.X, s.Y, s.Z = x, y, G.Layers[layer]
				s.Angle = if layer == 1 then rise else -rise
			end
		end
	end
	pose.Pitch, pose.Angle = pitch, angle
	return pose
end

-- The gap the lead still has to close (studs): what the last one aboard dives through. 0 shut.
function Gate.gap(shut: number): number
	return math.abs(Gate.lead(shut) - G.Closed)
end

--[[
	The gate moving (L-05b1a): the server decides where it goes and when, and writes it as one
	replicated value on the elevator (`Attribute`); each player's screen folds the gate from it
	(ElevatorView), and the server sizes the gate's collider from the same numbers, so what you see
	is what stops you.

	It travels as a gate does when it's yanked: from rest it gathers speed and slams into the
	stack (open) or the keypad's post (shut), then recoils a hair and settles. The fold's recording
	builds to its slam the same way.
]]
Gate.Attribute = "Gate"
-- Seconds for a whole fold open: the right code's reward, quick enough to dive through, long
-- enough to hear the ratchet build to the slam (its recording's slam lands 1.6 s in).
Gate.OpenSeconds = 1.6
-- Seconds for a whole shut (L-05b2): faster than it opens, a slam, as Dandy's World's doors drop.
Gate.ShutSeconds = 1.2
-- Seconds between the right code and the gate starting to move: the chime, then the latch lets go.
Gate.Delay = 0.55
-- The recoil after it hits: this share of its travel back, over these seconds, then still.
Gate.BounceShare = 0.025
Gate.BounceSeconds = 0.22

-- The gate's motion as its replicated value: from and to (how far shut, 0 to 1) and the server
-- time it starts moving.
function Gate.encode(from: number, to: number, start: number): string
	return string.format("%.4f,%.4f,%.3f", from, to, start)
end

-- The motion from its value: from, to, start. A missing or broken value is a gate at rest shut.
function Gate.decode(value: unknown): (number, number, number)
	if type(value) == "string" then
		local a, b, c = string.match(value, "^([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)$")
		local from, to, start = tonumber(a), tonumber(b), tonumber(c)
		if from and to and start then
			return math.clamp(from, 0, 1), math.clamp(to, 0, 1), start
		end
	end
	return 1, 1, 0
end

-- Seconds of travel from `from` to `to`, before the recoil.
function Gate.duration(from: number, to: number): number
	local seconds = if to < from then Gate.OpenSeconds else Gate.ShutSeconds
	return math.abs(to - from) * seconds
end

-- Seconds from the motion's start until the gate is still.
function Gate.settles(from: number, to: number): number
	if from == to then
		return 0
	end
	return Gate.duration(from, to) + Gate.BounceSeconds
end

-- How far shut the gate is `elapsed` seconds into a motion from `from` to `to`: at rest before it
-- starts, gathering speed until it hits, a short recoil, then at `to`.
function Gate.at(from: number, to: number, elapsed: number): number
	if elapsed <= 0 or from == to then
		return if elapsed <= 0 then from else to
	end
	local d = Gate.duration(from, to)
	if elapsed >= d + Gate.BounceSeconds then
		return to
	end
	if elapsed < d then
		local u = elapsed / d
		return from + (to - from) * u * u
	end
	local b = (elapsed - d) / Gate.BounceSeconds
	return to - (to - from) * Gate.BounceShare * math.sin(math.pi * b)
end

return Gate
