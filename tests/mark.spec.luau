--!strict
-- lune run tests/mark.spec
-- The faint mark (S1-11): over 300 seeds on floors 1, 2, 3 and 6, at most one per floor, always on
-- a note's unit and never the guarded one, always one on floors 1 and 2, about MarkShare of
-- floors above, spread over the notes, the same seed marking the same unit; and the seeing: only
-- in your beam's middle, from a few steps, from in front of it, fading in and out.
local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local Deal = require("../src/shared/Deal")
local FloorRules = require("../src/shared/FloorRules")
local FaintMark = require("../src/shared/FaintMark")

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

local SEEDS = 300

local function lay(seed: number, number: number)
	local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
	return floor, Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
end

-- The pure rule.
local notes: { Deal.Note } = {
	{ slot = 4, places = { 1, 2 } },
	{ slot = 9, places = { 3, 4 } },
}
ok(Deal.markFrom(1, notes, 4, 0.99, 0) == 9, "floor 1 always marks, past the guarded note")
ok(Deal.markFrom(2, notes, 9, 0.99, 0.99) == 4, "floor 2 always marks")
ok(Deal.markFrom(3, notes, 4, Deal.MarkShare, 0) == nil, "floor 3 at the share has none")
ok(Deal.markFrom(3, notes, 4, Deal.MarkShare - 0.01, 0.5) == 9, "floor 3 under the share has one")
ok(Deal.markFrom(1, { notes[1] }, 4, 0, 0) == nil, "only the guarded note: no mark")
ok(Deal.markFrom(1, {}, nil, 0, 0) == nil, "no notes: no mark")
local four: { Deal.Note } = {
	{ slot = 1, places = { 1 } },
	{ slot = 2, places = { 2 } },
	{ slot = 3, places = { 3 } },
	{ slot = 5, places = { 4 } },
}
ok(Deal.markFrom(6, four, 2, 0, 0) == 1, "the first draw picks the first open note")
ok(Deal.markFrom(6, four, 2, 0, 0.999) == 5, "the top draw picks the last")
ok(Deal.markFrom(6, four, 2, 0, 0.5) == 3, "the middle draw picks the middle")

-- Over real floors.
for _, number in { 1, 2, 3, 6 } do
	local marked = 0
	local onSlot: { [number]: number } = {}
	for seed = 1, SEEDS do
		local _, deck = lay(seed, number)
		local m = deck.marked
		if m then
			marked += 1
			local isNote = false
			for k, note in deck.notes do
				if note.slot == m then
					isNote = true
					onSlot[k] = (onSlot[k] or 0) + 1
				end
			end
			ok(isNote, `floor {number} seed {seed}: the mark is on a note's unit`)
			ok(m ~= deck.guarded, `floor {number} seed {seed}: never the guarded note's unit`)
		elseif FloorRules.at(number).teaching then
			ok(false, `floor {number} seed {seed}: a teaching floor always has a mark`)
		end
		local _, again = lay(seed, number)
		ok(again.marked == deck.marked, `floor {number} seed {seed}: the same seed marks the same`)
	end
	if not FloorRules.at(number).teaching then
		local share = marked / SEEDS
		ok(
			math.abs(share - Deal.MarkShare) < 0.08,
			`floor {number}: {math.round(share * 100)}% of floors marked, want about {Deal.MarkShare * 100}%`
		)
	end
	-- every note but the guarded one gets marked sometimes (on floors with four notes, each)
	local count = FloorRules.at(number).notes
	local seen = 0
	for k = 1, count do
		if (onSlot[k] or 0) > 0 then
			seen += 1
		end
	end
	ok(seen == count, `floor {number}: marks land on every note in turn ({seen} of {count})`)
end

-- The seeing. A mark at the origin facing -Z (into the hall); you stand out in the hall.
local point = vector.create(0, 4.4, 0)
local facing = vector.create(0, 0, -1)
local function at(x: number, z: number): vector
	return vector.create(x, 4.6, z)
end
local function toward(eye: vector, target: vector): vector
	return vector.normalize(target - eye)
end
local function aimOff(eye: vector, degrees: number): vector
	local d = toward(eye, point)
	local r = math.rad(degrees)
	-- turn it about Y
	return vector.create(
		d.x * math.cos(r) - d.z * math.sin(r),
		d.y,
		d.x * math.sin(r) + d.z * math.cos(r)
	)
end

local close = at(0, -3)
ok(
	FaintMark.seen(close, toward(close, point), point, facing) > 0.99,
	"three studs, beam on it: fullest"
)
ok(FaintMark.seen(close, aimOff(close, 10), point, facing) > 0.99, "ten degrees off: still fullest")
local mid = FaintMark.seen(close, aimOff(close, 20), point, facing)
ok(mid > 0.05 and mid < 0.95, `twenty degrees off: part shown ({mid})`)
ok(FaintMark.seen(close, aimOff(close, 26), point, facing) == 0, "twenty-six degrees off: none")
ok(FaintMark.seen(close, aimOff(close, 180), point, facing) == 0, "looking away: none")
local far = at(0, -12)
ok(FaintMark.seen(far, toward(far, point), point, facing) == 0, "twelve studs off: none")
local edge = at(0, -8)
local some = FaintMark.seen(edge, toward(edge, point), point, facing)
ok(some > 0 and some < 1, `eight studs: fading in ({some})`)
local behind = at(0, 3)
ok(FaintMark.seen(behind, toward(behind, point), point, facing) == 0, "from behind its face: none")
local along = at(4, -2) -- down the hall beside the door frame, looking back at it
ok(FaintMark.seen(along, toward(along, point), point, facing) > 0.9, "from the side, close: shown")

-- Every lit beam on a screen (S2-07b2): a friend's shows it as yours does.
local friendEye = at(1, -3)
local friend = { eye = friendEye, aim = toward(friendEye, point), light = 1 }
local yoursAway = { eye = close, aim = aimOff(close, 180), light = 1 }
local most, lit = FaintMark.under({ yoursAway, friend }, point, facing)
ok(
	most > 0.99 and lit == 1,
	`your beam away, a friend's on it: fullest in their light ({most}, {lit})`
)
most, lit = FaintMark.under({}, point, facing)
ok(most == 0 and lit == 0, "no torch lit: nothing, and no light to linger in")
local dying = { eye = close, aim = toward(close, point), light = 0.2 }
most, lit = FaintMark.under({ dying, friend }, point, facing)
ok(most > 0.99 and lit == 1, "your dying beam and a friend's steady one: held in theirs")
local friendAway = { eye = friendEye, aim = aimOff(friendEye, 180), light = 0.6 }
most, lit = FaintMark.under({ dying, friendAway }, point, facing)
ok(lit == 0.2, `only your dying beam on it: its light, not the friend's elsewhere ({lit})`)
most, lit = FaintMark.under({ yoursAway, friendAway }, point, facing)
ok(most == 0 and lit == 1, "every beam off it: none, lingering in the brightest lit")
local friendBehind = { eye = at(0, 3), aim = vector.create(0, 0, -1), light = 1 }
most = FaintMark.under({ friendBehind }, point, facing)
ok(most == 0, "a friend's beam from behind the wall: none")

-- Fading.
local shown = 0
for _ = 1, 6 do
	shown = FaintMark.follow(shown, 1, 1 / 60)
end
ok(shown > 0.3 and shown < 0.9, `a tenth of a second into the beam: coming up ({shown})`)
for _ = 1, 60 do
	shown = FaintMark.follow(shown, 1, 1 / 60)
end
ok(shown > 0.99, "a second on: all there")
local leaving = FaintMark.follow(1, 0, 1 / 60)
ok(leaving > FaintMark.follow(0, 1, 1 / 60), "it goes slower than it comes")
ok(FaintMark.transparency(1, 1) == 1 - FaintMark.Most, "fullest: faint chalk")
ok(FaintMark.transparency(0, 1) == 1, "unseen: invisible")
ok(FaintMark.transparency(1, 0) == 1, "a dead torch: invisible")
ok(FaintMark.transparency(1, 1) > 0.02, "never fully solid (AlphaMode Transparency cuts at 0)")

print(`mark: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
