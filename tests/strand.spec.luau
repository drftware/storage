--!strict
-- lune run tests/strand.spec
-- The fairy lights laid along a hall (F-G1e5c, Finds/Strand): the string runs ahead unless a
-- way is clearly longer, lies as the coil when boxed in, holds a Mannequin all along its length
-- with no gap wider than its reach, has the art's twenty LEDs on its 8 studs, runs out from the
-- box and settles, and leaves the box and ends where it was laid.
local Strand = require("../src/shared/Finds/Strand")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- which way: ahead when ahead is as good as any
ok(Strand.pick({ 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 }) == 1, "open floor: ahead")
-- facing a wall 1 stud off in a hall running left to right: across, the first side tried
ok(Strand.pick({ 1, 1.2, 1.2, 2, 2, 8, 8, 2, 2, 8 }) == 6, "facing a wall: along the hall")
-- a doorway to the side a little longer than the hall ahead: still ahead
ok(Strand.pick({ 7, 8, 7, 7, 7, 7, 7, 7, 7, 7 }) == 1, "a little longer to the side: ahead")
-- ahead much shorter than back the way it came: back
ok(Strand.pick({ 2, 2, 2, 2, 2, 2, 2, 2, 2, 8 }) == 10, "ahead blocked: back down the hall")
-- boxed in: the coil
ok(Strand.pick({ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }) == nil, "boxed in: no string")
ok(#Strand.Ways == 10 and Strand.Ways[1] == 0, "ten ways, ahead first")

-- where along it a Mannequin is held: both ends, never more than its reach apart
for _, run in { 1.5, 4, 5, 8, 12.3 } do
	local h = Strand.holds(run, Strand.Reach)
	ok(h[1] == 0 and math.abs(h[#h] - run) < 1e-9, `holds on {run}: both ends`)
	local widest = 0
	for i = 2, #h do
		widest = math.max(widest, h[i] - h[i - 1])
	end
	ok(widest <= Strand.Reach + 1e-9, `holds on {run}: gaps within reach ({widest})`)
end
ok(#Strand.holds(8, 4) == 3, "8 studs, reach 4: three holds")

-- the LEDs: the art's twenty on its 8 studs, 0.4 apart
local beads = Strand.beads(8)
ok(#beads == 20, `twenty LEDs on 8 studs ({#beads})`)
ok(math.abs(beads[2] - beads[1] - 0.4) < 1e-9, "0.4 apart")
ok(#Strand.beads(1.5) == 4, "a short run: the LEDs that fit")

-- running out: from nothing to all of it in RunOut, quick first, never back
ok(Strand.out(0) == 0 and Strand.out(-1) == 0, "nothing out as it lands")
ok(Strand.out(Strand.RunOut) == 1 and Strand.out(5) == 1, "all out by RunOut")
local was, quickFirst = 0, Strand.out(Strand.RunOut / 2) > 0.5
for i = 1, 30 do
	local now = Strand.out(Strand.RunOut * i / 30)
	ok(now >= was, `runs out, never back ({i})`)
	was = now
end
ok(quickFirst, "quick off the box")

-- its loose lie: none at the box or its end, never past Sway
ok(
	Strand.sway(0, 8) == 0 and math.abs(Strand.sway(8, 8)) < 1e-9,
	"leaves the box and ends where laid"
)
local widest = 0
for i = 0, 80 do
	widest = math.max(widest, math.abs(Strand.sway(i / 10, 8)))
end
ok(widest <= Strand.Sway and widest > Strand.Sway * 0.5, `wanders, within Sway ({widest})`)
ok(Strand.sway(1, 0) == 0, "no run, no sway")

print(`strand.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
