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

-- The wrap you can see (L-07b): drawn round a default R15 body, scaled per axis to the kept one.
-- The generated Specs build Vector3s, which Lune hasn't: read the numbers from the text.
local fs = require("@lune/fs")
local SPECS = fs.readFile("src/shared/KeptWrap/Specs.luau")
local function box(key: string): Kept.Box
	local line = string.match(SPECS, "\n%s*" .. key .. " = (%b{})")
	assert(line, `{key} not in the wrap's Specs`)
	local function v3(field: string): { number }
		local a, b, c =
			string.match(line, field .. " = Vector3%.new%(([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+)%)")
		assert(a and b and c, `{key}.{field} not in the wrap's Specs`)
		return { tonumber(a) :: number, tonumber(b) :: number, tonumber(c) :: number }
	end
	return { size = v3("Size"), centre = v3("Centre") }
end
local drawn, wrap = box("Body"), box("Wrap")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end
-- Whether box `outer` holds box `inner` whole.
local function holds(outer: Kept.Box, inner: Kept.Box): boolean
	for i = 1, 3 do
		local o0, o1 = outer.centre[i] - outer.size[i] / 2, outer.centre[i] + outer.size[i] / 2
		local i0, i1 = inner.centre[i] - inner.size[i] / 2, inner.centre[i] + inner.size[i] / 2
		if i0 < o0 - 1e-6 or i1 > o1 + 1e-6 then
			return false
		end
	end
	return true
end

ok(holds(wrap, drawn), "drawn, the wrap holds the body it was drawn round")
local same = Kept.fit(drawn, drawn, wrap)
ok(
	near(same.size[1], wrap.size[1])
		and near(same.size[2], wrap.size[2])
		and near(same.size[3], wrap.size[3])
		and near(same.centre[2], wrap.centre[2]),
	"the body it was drawn round wears it as drawn"
)
-- a taller, slimmer body (an Rthro-like one), standing higher on its root
local tall: Kept.Box = { size = { 2.6, 6.4, 1.2 }, centre = { 0, -0.2, 0 } }
local onTall = Kept.fit(tall, drawn, wrap)
ok(holds(onTall, tall), "a taller, slimmer body is held whole")
ok(onTall.size[2] > wrap.size[2] and onTall.size[1] < wrap.size[1], "taller and slimmer to fit it")
ok(near(onTall.size[2] / wrap.size[2], tall.size[2] / drawn.size[2]), "scaled by the body's height")
-- a small one (a child-sized avatar)
local small: Kept.Box = { size = { 2.2, 3.4, 0.9 }, centre = { 0, -0.9, -0.05 } }
ok(holds(Kept.fit(small, drawn, wrap), small), "a small body is held whole")
-- something odd: a wing as wide as a hall stays a person's wrap, not a tent
local odd: Kept.Box = { size = { 40, 5.19, 1.41 }, centre = { 0, -0.405, -0.105 } }
local onOdd = Kept.fit(odd, drawn, wrap)
ok(onOdd.size[1] <= wrap.size[1] * Kept.FitMax + 1e-6, "never stretched past FitMax")
local flat: Kept.Box = { size = { 0, 0, 0 }, centre = { 0, 0, 0 } }
local onFlat = Kept.fit(flat, drawn, wrap)
ok(
	onFlat.size[1] >= wrap.size[1] * Kept.FitMin - 1e-6 and onFlat.size[2] > 0,
	"a body with no size still gets a wrap"
)

-- The squeal (L-07b): through the whole wrap, heard down the hall.
ok(Kept.Squeal.from >= 0 and Kept.Squeal.length > 0, "the squeal is a stretch of its recording")
ok(
	Kept.Squeal.length / (Kept.Squeal.pitch or 1) >= 1.6,
	"it squeals through most of the 2-second wrap"
)
ok(Kept.SquealReach >= 20 and Kept.SquealReach <= 80, "heard by friends near, not the floor")

-- Banging (L-07c): a bang lands no faster than the door's jolt plays, the server forgives a
-- little jitter but not a spam, and each one marks the unit for a while, then fades.
ok(Kept.ready(nil, 0), "the first bang always lands")
ok(not Kept.ready(10, 10 + Kept.BangEvery - 0.01), "a screen never sends a bang early")
ok(Kept.ready(10, 10 + Kept.BangEvery), "a bang lands a full gap after the last")
ok(
	Kept.ready(10, 10 + Kept.BangEvery - Kept.BangSlack, Kept.BangSlack),
	"the server forgives a jittery connection its slack"
)
ok(
	not Kept.ready(10, 10 + Kept.BangEvery - Kept.BangSlack - 0.01, Kept.BangSlack),
	"but refuses anything faster"
)
ok(Kept.BangEvery >= 0.5, "every bang's jolt (0.5 s) plays out whole")
ok(Kept.BangEvery - Kept.BangSlack >= 0.3, "a spam can't land more than about three a second")
-- a spam: a press every frame for two seconds lands only as fast as the gap allows
local last: number? = nil
local landed = 0
for frame = 0, 119 do
	local t = frame / 60
	if Kept.ready(last, t, Kept.BangSlack) then
		last, landed = t, landed + 1
	end
end
ok(
	landed <= math.ceil(2 / (Kept.BangEvery - Kept.BangSlack)),
	"a press every frame is held to the rate"
)
ok(landed >= 3, "but mashing still bangs")

ok(Kept.mark(0) == 1 and Kept.mark(-0.3) == 1, "a fresh bang marks fully, a clock behind too")
ok(Kept.mark(Kept.BangMark - Kept.BangFade) == 1, "full until its fade")
ok(near(Kept.mark(Kept.BangMark - Kept.BangFade / 2), 0.5), "fading out over the last stretch")
ok(Kept.mark(Kept.BangMark) == 0 and Kept.mark(100) == 0, "then gone")

local bangs: { [number]: Kept.Bang } = {
	[12] = { slot = 12, user = 4096123456, at = 100.25, x = -35.5, y = 0, z = -120.25 },
	[3] = { slot = 3, user = -1, at = 99, x = 12, y = 10, z = -40 },
	[40] = { slot = 40, user = 7, at = 80, x = 1, y = 2, z = 3 }, -- long gone by 101
}
local text = Kept.encodeBangs(bangs, 101)
local back = Kept.decodeBangs(text)
ok(#back == 2, "a mark long gone isn't sent")
ok(back[1].slot == 3 and back[2].slot == 12, "in slot order")
ok(
	back[2].user == 4096123456 and near(back[2].at, 100.25) and near(back[2].x, -35.5),
	"each bang reads back: who, when, where"
)
ok(back[1].user == -1 and back[1].y == 10, "a Studio test player's id and a top's height too")
ok(#Kept.decodeBangs("") == 0, "no bangs reads as none")
ok(#Kept.decodeBangs("x;3,1,2;0,1,2,3,4,5;2.5,1,1,1,1,1;4,1,nan,1,1,1") == 0, "junk reads as none")
ok(#Kept.decodeBangs(Kept.encodeBangs({}, 0)) == 0, "an empty floor's text is empty")

-- Cut free (L-07d): a friend at your open door, in reach, holding a full second, cuts you free;
-- nobody else does. In a big unit (12 by 12) the kept body's root stands 62% of the way in, 3
-- studs up; the cut point is a little up and out in front of it, toward the door.
local M = { width = 12, depth = 12 }
local S = { width = 8, depth = 8 }
local function cutPoint(u: { width: number, depth: number }): { number }
	return { 0, 3 + Kept.CutUp, u.depth * Kept.Back - Kept.CutAhead }
end
local function cut(
	changes: { [string]: any }?,
	u: { width: number, depth: number }?
): Kept.Cut -- any: test overrides
	local unitSize = u or M
	local c: Kept.Cut = {
		self = false,
		alive = true,
		kept = false,
		inside = true,
		open = true,
		held = Kept.CutHold,
		at = { 0, 3, 1 }, -- a stride inside the door, face on
		cut = cutPoint(unitSize),
		width = unitSize.width,
		depth = unitSize.depth,
	}
	if changes then
		for k, v in changes do
			(c :: any)[k] = v -- any: a test's override of one field
		end
	end
	return c
end

ok(Kept.cut(cut()) == nil, "a friend inside the open door who held a full second cuts you free")
ok(Kept.cut(cut({ self = true })) == "Self", "never yourself")
ok(Kept.cut(cut({ kept = true })) == "Kept", "never a friend who's kept too")
ok(Kept.cut(cut({ alive = false })) == "Dead", "never a friend who's down")
ok(Kept.cut(cut({ inside = false })) == "Away", "not while you're still in the black on the way")
ok(Kept.cut(cut({ open = false })) == "Shut", "only with your door all the way up")
local unheld = cut()
unheld.held = nil
ok(Kept.cut(unheld) == "Short", "a trigger with no hold is refused")
ok(Kept.cut(cut({ held = 0.2 })) == "Short", "a quick tap is refused")
ok(
	Kept.cut(cut({ held = Kept.CutHold - Kept.CutSlack })) == nil,
	"a hold whose start reached the server late still counts"
)
ok(
	Kept.cut(cut({ held = Kept.CutHold - Kept.CutSlack - 0.01 })) == "Short",
	"but not one cut any shorter"
)
-- where a friend may stand
ok(Kept.cut(cut({ at = { 0, 3, 0 } })) == nil, "on the door's line, from a big unit's doorway")
ok(Kept.cut(cut({ at = { 2.5, 3, -0.5 } })) == nil, "just out in the hall, off to one side")
ok(Kept.cut(cut({ at = { 0, 3, 10 } })) == nil, "behind you, at the back wall")
ok(Kept.cut(cut({ at = { 0, 3, -Kept.CutOut - 0.1 } })) == "Outside", "not from across the hall")
ok(Kept.cut(cut({ at = { 6.5, 3, 7 } })) == "Outside", "not through the side wall, next door")
ok(Kept.cut(cut({ at = { 0, 3, 12.5 } })) == "Outside", "not through the back wall")
ok(Kept.cut(cut({ at = { 0, 13, 7 } })) == "Far", "not from up on the tops")
ok(Kept.cut(cut({ at = { 0, 3, -2.9 } })) == "Far", "not from the far side of a stride out")
-- the button shows within CutReach; the server takes a little more, never much more
local c0 = cutPoint(M)
local within = { 0, 3, c0[3] - math.sqrt(Kept.CutReach ^ 2 - Kept.CutUp ^ 2) }
ok(Kept.cut(cut({ at = within })) == nil, "anywhere the button shows, the cut goes")
local slack = Kept.CutReach + Kept.CutReachSlack
local edge = { 0, 3, c0[3] - math.sqrt((slack - 0.01) ^ 2 - Kept.CutUp ^ 2) }
ok(Kept.cut(cut({ at = edge })) == nil, "a friend who stepped back as it landed still cuts")
ok(Kept.CutReachSlack <= 3, "the server's slack is a step, not a hall")
-- the button reaches from the door's line into either size of unit, and from the hall into a small one
local function dist(a: { number }, b: { number }): number
	return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2)
end
ok(dist({ 0, 3, 0 }, cutPoint(M)) <= Kept.CutReach, "a big unit's button shows from its doorway")
ok(dist({ 0, 3, -2 }, cutPoint(S)) <= Kept.CutReach, "a small one's from a step out in the hall")
ok(
	dist({ 0, 3, -Kept.CutOut }, cutPoint(M)) > Kept.CutReach,
	"but not a big one's from across the hall"
)
ok(Kept.CutAhead < S.depth * Kept.Back, "the cut point is inside even a small unit")
ok(Kept.CutHold >= 0.75 and Kept.CutHold <= 1.5, "about a second's hold")

-- The strain under a friend's hold swells to full as the hold lands, and holds there.
ok(near(Kept.pull(0), 0.35), "the strain starts quiet")
ok(Kept.pull(Kept.CutHold / 2) > Kept.pull(0.1), "and swells")
ok(Kept.pull(Kept.CutHold) == 1 and Kept.pull(5) == 1, "full as the hold lands")
ok(
	Kept.Pull.length / Kept.Pull.pitch >= Kept.CutHold + 0.5,
	"the strain plays through a whole hold with time to spare"
)
ok(Kept.Rip.length >= 0.5, "the rip is a tear, not a click")
ok(Kept.RipReach >= Kept.SquealReach, "heard down the hall, as far as the wrap going on")

-- The freed player's view snaps open and eases back, ending exactly where it began.
ok(Kept.widen(0) == 0 and Kept.widen(Kept.WidenIn + Kept.WidenOut) == 0, "it starts and ends shut")
ok(near(Kept.widen(Kept.WidenIn), 1), "fully open almost at once")
ok(Kept.widen(Kept.WidenIn / 2) > 0.6, "snapping open")
ok(Kept.widen(Kept.WidenIn + Kept.WidenOut / 2) < 0.6, "easing back")
ok(Kept.FreedKick > Kept.CutterKick, "the rip jolts the freed harder than the cutter")
ok(Kept.FreedKick < 0.85, "but softer than the catch")

-- The film comes off over a beat, never a vanish: it bulges, slumps down to the ankles, settles,
-- lies there and fades out, every step joined to the last.
local whole = Kept.tearPose(0)
ok(
	whole.squash == 1 and whole.wide == 1 and whole.deep == 1 and whole.see == Kept.WrapBlend,
	"whole at the tear"
)
ok(Kept.tearPose(Kept.Tear.yank / 2).wide > 1.05, "it bulges as it's torn")
local T = Kept.Tear
local down = T.yank + T.fall
ok(near(Kept.tearPose(down).squash, T.heap), "down at the ankles after the slump")
ok(
	Kept.tearPose(T.yank + T.fall / 4).squash > Kept.tearPose(T.yank + T.fall * 3 / 4).squash + 0.2,
	"slumping"
)
local early = 0.96 - Kept.tearPose(T.yank + T.fall / 4).squash
local late = Kept.tearPose(T.yank + T.fall * 3 / 4).squash - Kept.tearPose(down - 0.001).squash
ok(late > early, "slow off the body, fast at the bottom, as a falling thing goes")
ok(Kept.tearPose(down + T.settle / 2).squash < T.heap, "it squashes as it lands")
ok(Kept.tearPose(down + T.settle + T.rest / 2).see < 0.5, "and lies there, still seen")
ok(Kept.tearPose(Kept.tearLength()).see == 1, "then it's gone")
ok(Kept.tearPose(100).see == 1, "and stays gone")
local stepMax, seeDown, lowest, gap = 0, true, math.huge, 0
local prev = Kept.tearPose(0)
for i = 1, 400 do
	local p = Kept.tearPose(Kept.tearLength() * i / 400)
	stepMax = math.max(
		stepMax,
		math.abs(p.squash - prev.squash),
		math.abs(p.wide - prev.wide),
		math.abs(p.deep - prev.deep)
	)
	if p.see < prev.see - 1e-9 then
		seeDown = false
	end
	lowest = math.min(lowest, p.squash)
	gap = math.max(gap, math.abs(p.lean - prev.lean))
	prev = p
end
ok(stepMax < 0.05, "no jump in its shape anywhere: a beat, not a vanish")
ok(gap < 0.05, "nor in its lean")
ok(seeDown, "it never comes back once it starts to clear")
ok(lowest > 0.08, "it never squashes flat to nothing")
local heap = Kept.tearPose(down + T.settle + T.rest / 2)
ok(heap.wide < 1 and heap.deep > 1, "the heap gathers round the ankles, not the shoulders")
ok(Kept.tearLength() >= 1.5 and Kept.tearLength() <= 3, "the whole beat is about two seconds")

print(string.format("kept: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("kept spec failed")
end
