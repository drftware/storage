--!strict
-- lune run tests/doorsound.spec
local DoorSound = require("../src/shared/StorageUnit/DoorSound")
local Shake = require("../src/shared/Shake")

local FULL, PEEK = 7.65, 1.15
local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number, what: string, tol: number?)
	ok(math.abs(a - b) <= (tol or 1e-6), string.format("%s (%.5f vs %.5f)", what, a, b))
end

local function names(cues: { DoorSound.Cue }): string
	local list = {}
	for _, c in cues do
		table.insert(list, c.sound)
	end
	return table.concat(list, ",")
end

-- every sound row is a stretch of its recording, playable as given
for name, row in DoorSound.Sounds do
	ok(row.Stop > row.Start and row.Start >= 0, `{name}: a stretch of the recording`)
	ok(row.Fade >= 0 and row.Fade < row.Stop - row.Start, `{name}: fades within its stretch`)
	ok(row.PitchMin <= row.PitchMax and row.PitchMin > 0, `{name}: a pitch range`)
	ok(row.Near < row.Reach, `{name}: fades out beyond full volume`)
	ok(string.match(row.Id, "^rbxassetid://%d+$") ~= nil, `{name}: an asset id`)
end

-- the GDD's noise: a peek quiet and short-reaching, an open and a lift loud and far
local A = DoorSound.Actions
ok(
	A.Peek.Gain < A.Close.Gain and A.Close.Gain < A.Open.Gain,
	"peek quiet, close between, open loud"
)
ok(A.LiftInside.Gain >= A.Open.Gain, "lifting from inside is loud")
ok(A.Peek.Reach < A.Open.Reach, "a peek carries less far than an open")
ok(DoorSound.Sounds.Bang.Reach >= A.Open.Reach, "the bang carries farthest")

-- cues: the one-shots of each motion
local open = DoorSound.cues("Open", 0, FULL, FULL)
ok(
	names(open) == "Latch,Thump",
	"an open from shut: the latch, then the stop bolts (" .. names(open) .. ")"
)
near(open[1].at, 0, "the latch as the door breaks away")
near(open[2].at, 2.0, "the stop bolts when the open ends")
ok(open[2].shake == 0, "an open shakes nobody")

local peek = DoorSound.cues("Peek", 0, PEEK, FULL)
ok(names(peek) == "Latch", "a peek: only the latch")
ok(peek[1].gain < open[1].gain, "a peek slides the latch quietly")

ok(names(DoorSound.cues("Open", PEEK, FULL, FULL)) == "Thump", "an open from a peek: no latch")

local fall = math.sqrt(2 * FULL / 200)
local slam = DoorSound.cues("Slam", FULL, 0, FULL)
ok(#slam == 3 and slam[3].sound == "Clatter", "a slam: bang and thump, then the bounce's clatter")
local bang, thump
for _, c in slam do
	if c.sound == "Bang" then
		bang = c
	elseif c.sound == "Thump" then
		thump = c
	end
end
ok(bang ~= nil and thump ~= nil, "a slam bangs with a thump under it")
if bang and thump then
	near(bang.at, fall, "the bang lands with the door")
	near(thump.at, fall, "the thump too")
	near(bang.shake, DoorSound.SlamShake, "the bang shakes nearby cameras")
	ok(thump.pitch < 1, "the thump is pitched down")
end
near(slam[3].at, fall + 0.26, "the clatter when the bounce lands")
ok(slam[3].shake > 0 and slam[3].shake < DoorSound.SlamShake, "the bounce shakes a little")

local soft = DoorSound.cues("Slam", PEEK, 0, FULL)
ok(soft[1].gain < 1 and soft[1].shake < DoorSound.SlamShake, "a slam from a peek bangs softer")

local close = DoorSound.cues("Close", FULL, 0, FULL)
ok(
	names(close) == "Clatter,Thump" or names(close) == "Thump,Clatter",
	"a close settles with a clatter"
)
for _, c in close do
	near(c.at, 1.6, "when the close ends")
	ok(c.shake == 0, "a close shakes nobody")
end

ok(#DoorSound.cues("Slam", 0, 0, FULL) == 0, "slamming a shut door: silence")
ok(#DoorSound.cues("Close", 0, 0, FULL) == 0, "closing a shut door: silence")

-- locking: the bolt then the padlock; unlocking: the padlock then the bolt; about a second
ok(names(DoorSound.lockCues(true)) == "Latch,PadlockShut", "locking")
ok(names(DoorSound.lockCues(false)) == "PadlockOpen,Latch", "unlocking")
for _, locked in { true, false } do
	for _, c in DoorSound.lockCues(locked) do
		ok(c.at >= 0 and c.at < 1, "a padlock's sounds within its second")
	end
end

-- the roll follows the door's speed
local v0 = DoorSound.roll("Open", 0, FULL, -0.1, FULL)
ok(v0 == 0, "silent before the door moves")
ok(DoorSound.roll("Open", 0, FULL, 2.0, FULL) == 0, "silent once it stops")
local vMid, pMid = DoorSound.roll("Open", 0, FULL, 1.0, FULL)
local vEnd, pEnd = DoorSound.roll("Open", 0, FULL, 1.95, FULL)
local vStart = DoorSound.roll("Open", 0, FULL, 0.02, FULL)
near(vMid, A.Open.Gain, "an open rattles at full volume mid-way")
ok(vStart > 0.5 * vMid, "it breaks away with a jolt")
ok(vEnd < 0.1 * vMid, "and falls quiet as it eases into the stop bolts")
ok(pMid > pEnd, "higher while it's fast")
local loudestPeek = 0
for i = 0, 99 do
	loudestPeek = math.max(loudestPeek, (DoorSound.roll("Peek", 0, PEEK, i / 100, FULL)))
end
ok(loudestPeek <= A.Peek.Gain + 1e-9 and loudestPeek > 0, "a peek's roll stays quiet")

-- a lift from inside surges with each of its three heaves
local dips, prev, falling = 0, -1, false
for i = 1, 599 do
	local v = DoorSound.roll("LiftInside", 0, FULL, i / 100, FULL)
	if prev >= 0 then
		if v < prev then
			falling = true
		elseif v > prev and falling then
			falling = false
			if prev < 0.97 * A.LiftInside.Gain then
				dips += 1
			end
		end
	end
	prev = v
end
ok(dips == 3, `a lift from inside heaves three times ({dips})`)

-- the slam's shake reaches the friend beside it, not the far end of the hall
near(
	Shake.falloff(DoorSound.ShakeNear, DoorSound.ShakeNear, DoorSound.ShakeReach),
	1,
	"full beside it"
)
near(
	Shake.falloff(DoorSound.ShakeReach, DoorSound.ShakeNear, DoorSound.ShakeReach),
	0,
	"none at its reach"
)

-- a padlocked door tried: its rattle and nothing else, as far as its sound carries
ok(names(DoorSound.cues("Rattle", 0, 0, FULL)) == "Rattle", "a tried padlock rattles")
local rv = DoorSound.roll("Rattle", 0, 0, 0.2, FULL)
near(rv, 0, "and never rolls")
ok(A.Rattle.Reach == DoorSound.Sounds.Rattle.Reach, "keepers hear a rattle as far as players")
ok(A.Rattle.Reach > A.Peek.Reach, "a rattle carries farther than a peek")

print(string.format("doorsound: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("doorsound spec failed")
end
