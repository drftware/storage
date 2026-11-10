--!strict
-- lune run tests/chase.spec
-- What the hunted player hears (L-06b4b1): the sting on a fresh sighting only (not a glance back
-- within `Regain` of a keeper losing you, not within `StingGap` of the last sting, never in a
-- catch's hush), and the bed rising over `BedIn` while any keeper hunts you and fading over
-- `BedOut` once none does, cut at once by a catch.
local Chase = require("../src/shared/Chase")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

-- the numbers hold together
ok(Chase.Regain < Chase.StingGap, "a glance back is shorter than the gap between stings")
ok(Chase.BedIn < Chase.BedOut, "the bed comes up faster than it fades")
ok(Chase.Hush > 0 and Chase.Bed.from < Chase.Bed.to, "a hush, and a stretch to loop")
ok(Chase.Sting.volume > Chase.Bed.volume, "the sting is louder than the bed")

-- silence before anything happens
do
	local m = Chase.new()
	ok(Chase.quiet(m), "quiet at first")
	ok(Chase.bed(m, 10) == 0, "no bed at first")
	ok(Chase.quiet(m), "still quiet after asking")
end

-- the first sighting stings and brings the bed up; losing it fades the bed
do
	local m = Chase.new()
	ok(Chase.bed(m, 0) == 0, "silent before")
	ok(Chase.hunted(m, 1, 0), "a keeper sees you: the sting")
	ok(not Chase.quiet(m), "not quiet while hunted")
	ok(Chase.bed(m, 0) == 0, "the bed starts from nothing")
	local half = Chase.bed(m, Chase.BedIn / 2)
	ok(near(half, 0.25), "halfway up, a quarter as loud (" .. half .. ")")
	ok(Chase.bed(m, Chase.BedIn) == 1, "full by BedIn")
	ok(Chase.bed(m, 30) == 1, "held full while it hunts you")
	ok(not Chase.hunted(m, 1, 31), "told the same again: no sting")
	ok(not Chase.hunted(m, 0, 40), "it loses you: no sting")
	ok(Chase.bed(m, 40) == 1, "the fade starts from full")
	ok(near(Chase.bed(m, 40 + Chase.BedOut / 2), 0.25), "half the fade, a quarter as loud")
	ok(not Chase.quiet(m), "not quiet while fading")
	ok(Chase.bed(m, 40 + Chase.BedOut) == 0, "faded out by BedOut")
	ok(Chase.quiet(m), "quiet once faded")
	ok(Chase.bed(m, 100) == 0, "stays silent")
end

-- a glance back within Regain: no sting, the bed comes back up from where it had fallen to
do
	local m = Chase.new()
	Chase.hunted(m, 1, 0)
	Chase.bed(m, 5)
	Chase.hunted(m, 0, 10)
	local fell = Chase.bed(m, 11)
	ok(fell < 1 and fell > 0, "fading a second after it lost you")
	ok(not Chase.hunted(m, 1, 11), "seen again a second later: no sting")
	ok(Chase.bed(m, 11) == fell, "the bed picks up where it was")
	ok(Chase.bed(m, 11 + Chase.BedIn) == 1, "and comes back up")
	Chase.hunted(m, 0, 20)
	ok(not Chase.hunted(m, 1, 20 + Chase.Regain - 0.01), "just inside Regain: still a glance back")
end

-- seen again after Regain, past the gap: a fresh sighting stings
do
	local m = Chase.new()
	ok(Chase.hunted(m, 1, 0), "first sting")
	Chase.hunted(m, 0, 2)
	ok(not Chase.hunted(m, 1, 2 + Chase.Regain), "past Regain but inside the gap: no sting")
	Chase.hunted(m, 0, 9)
	ok(Chase.hunted(m, 1, 9 + Chase.Regain), "past Regain and the gap: a fresh sting")
end

-- a second keeper: inside the gap it only adds; after the gap it stings; one of two losing you
-- keeps the bed up, and its seeing you again soon after is a glance back
do
	local m = Chase.new()
	ok(Chase.hunted(m, 1, 0), "the first keeper stings")
	ok(not Chase.hunted(m, 2, 3), "a second keeper 3 s later: no second sting")
	ok(not Chase.hunted(m, 1, 5), "one of two loses you: no sting")
	ok(Chase.bed(m, 6) == 1, "the bed stays up while one still hunts you")
	ok(not Chase.hunted(m, 2, 6), "it sees you again a second later: a glance back")
	ok(Chase.hunted(m, 3, 20), "a third keeper long after: a fresh sting")
end

-- caught: the bed cuts at once, nothing in the hush, and the next sighting after it stings
do
	local m = Chase.new()
	Chase.hunted(m, 1, 0)
	Chase.bed(m, 3)
	Chase.caught(m, 3)
	ok(Chase.bed(m, 3) == 0, "caught: the bed cuts at once")
	ok(not Chase.hunted(m, 0, 3), "the catch's loss: no sting")
	ok(Chase.quiet(m), "quiet in the black")
	ok(not Chase.hunted(m, 1, 3 + Chase.Hush / 2), "seen in the hush: no sting")
	ok(Chase.bed(m, 3 + Chase.Hush - 0.01) == 0, "no bed in the hush, though it hunts you")
	ok(near(Chase.bed(m, 3 + Chase.Hush + Chase.BedIn), 1), "the bed rises once the hush is over")
	Chase.hunted(m, 0, 6)
	local m2 = Chase.new()
	Chase.hunted(m2, 1, 0)
	Chase.caught(m2, 1)
	Chase.hunted(m2, 0, 1.01) -- the server's word of the loss lands just after the catch
	ok(
		Chase.hunted(m2, 1, 1 + Chase.Hush + 0.1),
		"the first sighting after the hush stings, though it's inside Regain and the gap"
	)
end

-- a fade cut short by a sighting, then lost again: it falls from where it rose to, evenly
do
	local m = Chase.new()
	Chase.hunted(m, 1, 0)
	Chase.bed(m, 1)
	Chase.hunted(m, 0, 1)
	Chase.hunted(m, 1, 1 + Chase.BedOut / 4) -- level 0.75
	Chase.hunted(m, 0, 1 + Chase.BedOut / 4 + Chase.BedIn / 8) -- back up to 0.875
	ok(near(Chase.bed(m, 1 + Chase.BedOut / 4 + Chase.BedIn / 8), 0.875 * 0.875), "level 0.875")
	ok(
		near(Chase.bed(m, 1 + Chase.BedOut / 4 + Chase.BedIn / 8 + Chase.BedOut * 0.875), 0),
		"falls the rest in its share of BedOut"
	)
end

-- time running backwards (a stale clock) changes nothing
do
	local m = Chase.new()
	Chase.hunted(m, 1, 10)
	local level = Chase.bed(m, 10.4)
	ok(Chase.bed(m, 10.2) == level, "an earlier time doesn't move the bed")
end

print(`chase: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} chase checks failed`)
end
