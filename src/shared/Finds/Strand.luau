--!strict
--[[
	Strand: the fairy lights laid along a hall (F-G1e5c, D-294).

	The moment: you set the lit fairy lights down in a dark hall, or let them fall at your heels as
	you run, and the string runs out along the floor, a dotted line of warm LEDs. A Mannequin coming
	down that hall freezes where it meets the line. As Minecraft's torches are laid along a tunnel
	to light the way, with the game's own rule that light stops a Mannequin (the item catalog's
	Switch row: "Set it down lit and it lights the space round it").

	The server lays it (`FindUses`, the longest clear way, preferring the way it was let go) and
	holds Mannequins along it (`Keepers`); every screen draws it (`StrandView`), its beads glowing
	with no light of their own past one dim lamp at its far half. Picked up, it's the coil again.
	Pure: which way it runs, where along it a Mannequin is held, where its beads lie, how far it
	has run out and how it lies loose.
]]
local Strand = {}

-- The tag on a find lying laid out, and its attributes: where its string starts and ends on the
-- floor (Vector3s), and the server clock it was laid (every screen plays it running out from then).
Strand.Tag = "LaidStrand"
Strand.FromAttribute = "StrandFrom"
Strand.ToAttribute = "StrandTo"
Strand.AtAttribute = "StrandAt"

-- The ways the server tries a string, as turns from the way it was let go (degrees), most wanted
-- first: ahead, a little either side, across, then back the way it came.
Strand.Ways = { 0, 30, -30, 60, -60, 90, -90, 135, -135, 180 }

-- A way counts as long as the longest if its clear run is within this share of it. What it does
-- to the player: dropped facing down a hall, the string runs on ahead even where a doorway off to
-- the side gives a run a little longer.
Strand.Near = 0.85

-- The shortest run worth laying (studs): boxed in tighter than this, it lies as the coil.
Strand.Least = 1.5

-- Studs from the string a Mannequin is held: a dim light, under half a lamp's hold (a camp
-- lantern's is about 10). What it does to the player: laid along a hall, it fills most of the
-- hall's width, so a Mannequin coming down it stops at the line's end.
Strand.Reach = 4

-- Seconds the string takes to run out from the box to its end as it lands: quick enough to land
-- with the drop, slow enough to see it pay out.
Strand.RunOut = 0.6

-- The LEDs along it: the art's (art/finds/lights/spec.py, FAIRY.bead), 0.4 studs apart from the
-- far end, the first 0.2 from the box.
Strand.Every = 0.4
Strand.First = 0.2

-- How far the loose wire wanders either side of a straight line, at most (studs): laid by hand,
-- never ruled straight.
Strand.Sway = 0.18

--[[
	Which way the string is laid: `runs` are each of `Ways`' clear runs (studs, each at most the
	string's length), in `Ways`' order. The first within `Near` of the longest; nil if even the
	longest is under `Least`.
]]
function Strand.pick(runs: { number }): number?
	local best = 0
	for _, r in runs do
		best = math.max(best, r)
	end
	if best < Strand.Least then
		return nil
	end
	for i, r in runs do
		if r >= best * Strand.Near then
			return i
		end
	end
	return nil
end

-- Distances along a run of `run` studs where a Mannequin is held, each `reach` round: both ends
-- and evenly between, never more than `reach` apart, so the holds join into one line of light.
function Strand.holds(run: number, reach: number): { number }
	local gaps = math.max(1, math.ceil(run / reach))
	local out = table.create(gaps + 1)
	for i = 0, gaps do
		out[i + 1] = run * i / gaps
	end
	return out
end

-- Distances along a run of `run` studs of each LED: `Every` apart from `First`, as many as fit.
function Strand.beads(run: number): { number }
	local out = {}
	local d = Strand.First
	while d <= run + 1e-6 do
		table.insert(out, d)
		d += Strand.Every
	end
	return out
end

-- How far out the string has run (0 to 1) `t` seconds after it landed: quick off the box,
-- easing as the last of it settles.
function Strand.out(t: number): number
	if t <= 0 then
		return 0
	elseif t >= Strand.RunOut then
		return 1
	end
	local s = 1 - t / Strand.RunOut
	return 1 - s * s
end

-- How far to the side the loose wire lies `d` studs along a run of `run` (studs): a lazy wave, none
-- at either end, so it leaves the box and ends where the server laid it.
function Strand.sway(d: number, run: number): number
	if run <= 0 then
		return 0
	end
	return Strand.Sway * math.sin(d * 1.3 + 0.7) * math.sin(math.pi * math.clamp(d / run, 0, 1))
end

return Strand
