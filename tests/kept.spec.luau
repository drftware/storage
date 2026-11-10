--!strict
-- lune run tests/kept.spec
-- Getting kept (L-07a): where the building stores you once the keeper has wrapped you. Only a unit
-- whose door is all the way down, not padlocked, with no keeper in it (nor the guard's place) and
-- nobody kept in it already; never the nearest one to where you were caught while another will
-- do; one nobody has opened before ahead of one that's been seen into; and spread at random over
-- the rest, so your friends have to look.
local Brix = require("../vendor/brix/src")
local Kept = require("../src/shared/Kept")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function unit(
	x: number,
	z: number,
	changes: { [string]: any }?
): Kept.Unit -- any: test overrides
	local u: Kept.Unit =
		{ x = x, z = z, shut = true, dealt = false, keeper = false, holding = false }
	if changes then
		for k, v in changes do
			(u :: any)[k] = v -- any: a test's override of one field
		end
	end
	return u
end

-- Which units can hold you.
ok(Kept.free(unit(0, 0)), "a shut, empty unit nobody's in holds you")
ok(not Kept.free(unit(0, 0, { shut = false })), "not one whose door isn't all the way down")
ok(not Kept.free(unit(0, 0, { keeper = true })), "not one a keeper is in")
ok(not Kept.free(unit(0, 0, { holding = true })), "not one already holding someone")
ok(Kept.free(unit(0, 0, { dealt = true })), "one already seen into will do")

local random = Brix.Random.new({ seed = 7 })

-- Nothing free: nowhere to put you.
ok(Kept.choose({ unit(0, 0, { shut = false }) }, 0, 0, random) == nil, "nil with no unit free")
ok(Kept.choose({}, 0, 0, random) == nil, "nil on a floor with no units")

-- One free unit: it, even though it's the nearest (better kept than left standing there).
ok(
	Kept.choose({ unit(5, 0), unit(1, 0, { keeper = true }) }, 0, 0, random) == 1,
	"the only one free"
)

-- Never the nearest while another will do, and every other free one comes up.
local floor = {
	unit(2, 0), -- 1: the nearest to the catch
	unit(40, 0), -- 2
	unit(0, 30), -- 3
	unit(-25, -25), -- 4
	unit(3, 0, { shut = false }), -- 5: near but open
	unit(60, 60, { holding = true }), -- 6: someone's in it
}
local seen: { [number]: number } = {}
for _ = 1, 400 do
	local i = Kept.choose(floor, 0, 0, random)
	if i then
		seen[i] = (seen[i] or 0) + 1
	end
end
ok(seen[1] == nil, "never the nearest")
ok(seen[5] == nil and seen[6] == nil, "never one that can't hold you")
ok((seen[2] or 0) > 60 and (seen[3] or 0) > 60 and (seen[4] or 0) > 60, "spread over the rest")

-- One nobody has opened before ahead of one that's been seen into.
local mixed = {
	unit(2, 0), -- 1: nearest, unopened
	unit(30, 0, { dealt = true }), -- 2: seen into
	unit(50, 0), -- 3: unopened
}
local unopened = true
for _ = 1, 100 do
	if Kept.choose(mixed, 0, 0, random) ~= 3 then
		unopened = false
	end
end
ok(unopened, "an unopened unit (not the nearest) ahead of a seen-into one")
-- Only seen-into units left: one of those, still not the nearest.
local seenOnly =
	{ unit(2, 0, { dealt = true }), unit(30, 0, { dealt = true }), unit(9, 9, { shut = false }) }
ok(Kept.choose(seenOnly, 0, 0, random) == 2, "a seen-into one when no unopened one is free")
-- The nearest is the nearest of all the free ones, not just of the unopened ones.
local nearSeen = { unit(2, 0, { dealt = true }), unit(30, 0) }
ok(Kept.choose(nearSeen, 0, 0, random) == 2, "the unopened one, the seen-into one nearer")
local nearUnopened = { unit(2, 0), unit(30, 0, { dealt = true }) }
ok(Kept.choose(nearUnopened, 0, 0, random) == 2, "never the nearest, even if it's the unopened one")

-- Where in the unit you wake: past its middle, facing the door, the dark between you and it.
ok(Kept.Back > 0.5 and Kept.Back < 0.85, `past the middle, off the back wall ({Kept.Back})`)
ok(type(Kept.Attribute) == "string" and #Kept.Attribute > 0, "the player's kept flag has a name")

print(string.format("kept: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("kept spec failed")
end
