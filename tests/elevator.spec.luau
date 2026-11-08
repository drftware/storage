--!strict
-- lune run tests/elevator.spec
-- The elevator's folding gate (L-05a): at every spread from folded open to shut, thirteen
-- pickets run evenly from the fixed one to the lead and never overlap; every strap's two end
-- pins land on the pickets either side of its bay and stay within the pickets' channels; the
-- front straps rise toward the lead; the lead travels from Open to Closed and the gap it leaves
-- shrinks to nothing; the car and the opening fit the Mannequin.
local Specs = require("../src/shared/Elevator/Specs")
local Gate = require("../src/shared/Elevator/Gate")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end

local G = Specs.Gate
local MANNEQUIN = 6.3 -- the tallest keeper (art/mannequin/spec.py), which must pass the gate

ok(near(Gate.lead(0), G.Open) and near(Gate.lead(1), G.Closed), "the lead runs from Open to Closed")
ok(
	near(Gate.gap(1), 0) and Gate.gap(0) > 8,
	`folded open the gap is {Gate.gap(0)}, shut it's {Gate.gap(1)}`
)
ok(G.Head - 0.3 > MANNEQUIN + 1, "the track clears the Mannequin's head")
ok(
	Specs.Car.Height > MANNEQUIN + 2 and Specs.Opening.Height > MANNEQUIN + 2,
	"the car fits the Mannequin"
)

local lastLead, lastGap = math.huge, math.huge
for k = 0, 40 do
	local shut = k / 40
	local p = Gate.pose(shut)
	local tag = `at {shut}`
	ok(#p.Pickets == G.Pickets, `{tag}: {#p.Pickets} pickets`)
	ok(near(p.Pickets[1], G.Stack), `{tag}: the first picket stays on the post`)
	ok(near(p.Pickets[G.Pickets], Gate.lead(shut)), `{tag}: the last picket is the lead`)
	ok(near(Gate.shutAt(Gate.lead(shut)), shut, 1e-9), `{tag}: shutAt undoes lead`)
	ok(p.Pitch >= G.PicketWidth + 0.03, `{tag}: pickets {p.Pitch} apart overlap`)
	ok(p.Angle > 0 and p.Angle < math.pi / 2, `{tag}: strap angle {p.Angle}`)
	local lead = math.abs(Gate.lead(shut) - G.Closed)
	ok(lead <= lastLead + 1e-9, `{tag}: the lead never backs off`)
	ok(Gate.gap(shut) <= lastGap + 1e-9, `{tag}: the gap never widens`)
	lastLead, lastGap = lead, Gate.gap(shut)
	ok(#p.Straps == (G.Pickets - 1) * #G.Rows * 2, `{tag}: {#p.Straps} straps`)
	local half = G.Strap / 2
	for i, s in p.Straps do
		local bay = (i - 1) // (#G.Rows * 2) + 1
		local a, b = p.Pickets[bay], p.Pickets[bay + 1]
		local dx, dy = half * math.cos(s.Angle), half * math.sin(s.Angle)
		local x0, x1 = s.X - dx, s.X + dx
		local onPickets = (near(x0, math.min(a, b), 1e-6) and near(x1, math.max(a, b), 1e-6))
		ok(onPickets, `{tag}: strap {i}'s pins at {x0}, {x1} miss pickets {a}, {b}`)
		ok(
			s.Y - math.abs(dy) > G.Foot + 0.2 and s.Y + math.abs(dy) < G.Head - 0.2,
			`{tag}: strap {i} rides out of its pickets' channels`
		)
		-- the front layer rises toward the lead (toward Closed), as the look sheets show; a
		-- strap turned by a positive angle about Z rises toward +X
		local risesTowardLead = s.Angle * math.sign(G.Closed - G.Open) > 0
		ok(risesTowardLead == (s.Z == G.Layers[1]), `{tag}: strap {i} leans the wrong way`)
	end
end

print(`{checks - failures}/{checks} elevator checks passed`)
if failures > 0 then
	error(`{failures} elevator checks failed`)
end
