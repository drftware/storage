--!strict
-- lune run tests/tell.spec
-- How a keeper gives itself away by sound (L-06b4b2): a footfall as each step of its walk lands
-- and a knock of its joints as each pass lands, each key heard once, the moment a screen shows it
-- (`Pose.tell`); and one knock as a lifted door first clears the feet of one standing in a unit
-- (`KeeperTell`).
local KeeperRows = require("../src/shared/KeeperRows")
local KeeperTell = require("../src/shared/KeeperTell")
local Motion = require("../src/shared/StorageUnit/Motion")
local Pose = require("../src/shared/Mannequin/Pose")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local STEP, KEYS, SNAPS = Pose.Walk.Step, #Pose.Walk.Keys, Pose.Walk.Snaps

-- the key a frame shows (0-based within the cycle), or nil for Still
local function keyOf(frame: number): number?
	return if frame <= 1 then nil else (frame - 2) // SNAPS
end

-- Walks a body from `from` to `to` studs in steps of `by`, as a screen poses it, and returns each
-- sound with where it was heard, and how many frames landed on a new key (what a player sees).
local function walk(
	from: number,
	to: number,
	by: number,
	how: Pose.How
): ({ { sound: Pose.Sound, at: number } }, number)
	local heard = {}
	local _, last = Pose.tell(nil, from, how)
	local frame = Pose.frame(from, how)
	local landings = 0
	local t = from
	while t < to - 1e-9 do
		t = math.min(t + by, to)
		local sound: Pose.Sound?
		sound, last = Pose.tell(last, t, how)
		local f = Pose.frame(t, how)
		if keyOf(f) ~= keyOf(frame) then
			landings += 1
		end
		frame = f
		if sound then
			table.insert(heard, { sound = sound, at = t })
		end
	end
	return heard, landings
end

-- its first pose on a screen is silent, walking or standing
do
	ok(Pose.tell(nil, 0, "Walk") == nil, "streaming in mid-walk is silent")
	ok(Pose.tell(nil, 7.3, "Stop") == nil, "streaming in stopped is silent")
	ok(Pose.tell(nil, 0, "Still") == nil, "streaming in slack is silent")
end

-- a walk: one sound per key landed, a footfall for each step and a knock for each pass, in turn
do
	local heard, landings = walk(0, STEP * KEYS * 3, 0.05, "Walk")
	ok(#heard == KEYS * 3, `three cycles of the walk land {KEYS * 3} keys ({#heard})`)
	ok(landings == #heard, `a sound for each key the screen shows landing ({landings}, {#heard})`)
	local footfalls, alternates = 0, true
	for i, h in heard do
		if h.sound == "Footfall" then
			footfalls += 1
		end
		if i > 1 and heard[i - 1].sound == h.sound then
			alternates = false
		end
	end
	ok(footfalls == KEYS * 3 / 2, "half of them footfalls: one per step, two per stride")
	ok(alternates, "footfall, knock, footfall: never two of one kind in a row")
	ok(heard[1].sound == "Knock", "from its first key (a step) the next to land is a pass")
	-- each lands where the snap shows the next key, late in the step: after the hold
	local ahead = heard[1].at / STEP
	ok(ahead > Pose.Walk.Hold and ahead <= 1, `the first lands late in its step ({ahead})`)
end

-- the same walk sounds the same however a screen's frames fall
do
	local fine = walk(0, STEP * KEYS * 2, 0.01, "Walk")
	local coarse = walk(0, STEP * KEYS * 2, 0.4, "Walk")
	ok(#fine == #coarse, `fine and coarse frames hear as many keys ({#fine}, {#coarse})`)
	local same = true
	for i, h in fine do
		if not coarse[i] or coarse[i].sound ~= h.sound then
			same = false
		end
	end
	ok(same, "and the same sounds in the same order")
end

-- a late record jumping several keys at once makes one sound, the last key's
do
	local _, last = Pose.tell(nil, 0.1, "Walk")
	local sound, after = Pose.tell(last, STEP * 3 + 0.1, "Walk")
	ok(sound == "Knock", `a jump to its fourth key (a pass) knocks once ({sound})`)
	ok(after == 3, "and remembers that key")
	local again = Pose.tell(after, STEP * 3 + 0.2, "Walk")
	ok(again == nil, "nothing more until the next key")
end

-- caught by a light mid-snap: it lands the next key at once (heard), and isn't heard again as it
-- walks on through the rest of that snap
do
	local mid = STEP * (Pose.Walk.Hold + (1 - Pose.Walk.Hold) * 0.4) -- 40% into the first snap
	local _, last = Pose.tell(nil, mid, "Walk")
	local frozen: Pose.Sound?
	frozen, last = Pose.tell(last, mid, "Stop")
	ok(frozen == "Knock", "freezing mid-snap lands the pass it snapped into")
	local walking: Pose.Sound?
	walking, last = Pose.tell(last, mid + 0.05, "Walk")
	ok(walking == nil, "walking on from inside that snap is silent")
	local heard: { Pose.Sound } = {}
	local t = mid + 0.05
	while t < STEP * 2.9 do -- short of where the next pass lands
		t += 0.05
		local s: Pose.Sound?
		s, last = Pose.tell(last, t, "Walk")
		if s then
			table.insert(heard, s)
		end
	end
	ok(#heard == 1 and heard[1] == "Footfall", `then only the next step is heard ({#heard})`)
end

-- caught while holding a key: it stays on it, silent
do
	local held = STEP * Pose.Walk.Hold * 0.5
	local _, last = Pose.tell(nil, held, "Walk")
	ok(Pose.tell(last, held, "Stop") == nil, "freezing while it holds a key is silent")
end

-- slack, then into a stride: its joints knock as it jerks out of its shop pose
do
	local _, last = Pose.tell(nil, 0, "Still")
	local sound, after = Pose.tell(last, 0, "Walk")
	ok(sound == "Knock", "waking from slack into its stride knocks")
	ok(after == 0, "on its first key")
	local s2 = Pose.tell(last, 0, "Stop")
	ok(s2 == "Knock", "so does waking into a held stride (watching)")
	local _, slack = Pose.tell(after, 0, "Still")
	ok(Pose.tell(slack, 0, "Still") == nil, "standing slack is silent")
end

-- frames are what they were before the walk learned to sound (the same keys and snaps)
do
	local same = true
	for i = 0, 400 do
		local t = i * 0.037
		for _, how in { "Walk", "Stop" } :: { Pose.How } do
			local frame = Pose.frame(t, how)
			local q = t / STEP
			local k = math.floor(q)
			local f = q - k
			local s = 0
			if f > Pose.Walk.Hold then
				s = if how == "Stop"
					then SNAPS
					else math.floor((f - Pose.Walk.Hold) / (1 - Pose.Walk.Hold) * SNAPS + 0.5)
			end
			if s >= SNAPS then
				k, s = k + 1, 0
			end
			if frame ~= 2 + (k % KEYS) * SNAPS + s then
				same = false
			end
		end
	end
	ok(same, "Pose.frame unchanged")
end

-- small rules
do
	ok(KeeperTell.due(nil, 0, 0.08), "a body's first sound is due")
	ok(not KeeperTell.due(1, 1.05, 0.08), "not within its gap")
	ok(KeeperTell.due(1, 1.08, 0.08), "due at its gap")

	ok(KeeperTell.take(1, 1, 0.9) == 1, "one take: always it")
	local never, spread = true, {}
	for i = 0, 99 do
		local r = i / 100
		local t = KeeperTell.take(3, 2, r)
		if t == 2 then
			never = false
		end
		spread[t] = true
		ok(KeeperTell.take(2, 1, r) == 2 and KeeperTell.take(2, 2, r) == 1, "two takes: in turn")
	end
	ok(never and spread[1] and spread[3], "three takes: never the last, both others")
	ok(KeeperTell.take(2, nil, 0) == 1 and KeeperTell.take(2, nil, 0.99) == 2, "first: either")

	ok(KeeperTell.standing("Asleep") and KeeperTell.standing("Watching"), "asleep or watching")
	for _, state in { "Going", "Hunting", "Trapped", "Looking", 3 } :: { any } do
		ok(not KeeperTell.standing(state), `{state} isn't standing in a unit`)
	end
	ok(not KeeperTell.standing(nil), "no state: not standing")

	ok(KeeperTell.inside(0, 6, 12, 12), "the middle of a unit")
	ok(KeeperTell.inside(5.9, 11.9, 12, 12), "its back corner")
	ok(not KeeperTell.inside(0, -2, 12, 12), "the hall in front of the door")
	ok(not KeeperTell.inside(6.5, 6, 12, 12), "the next unit along")
	ok(not KeeperTell.inside(0, 12.5, 12, 12), "behind its back wall")
end

-- the reveal: as a lift first takes the curtain's edge past its feet
do
	local full, rise = 7.65, 0.4
	for _, kind in { "Peek", "Open", "LiftInside" } :: { Motion.Kind } do
		local to = if kind == "Peek" then 1.15 else full
		local at = KeeperTell.reveal(kind, 0, to, full, rise)
		ok(at ~= nil, `{kind} from shut reveals`)
		if at then
			local dur = Motion.duration(kind, 0, to, full)
			ok(at > 0 and at < dur, `{kind}: during the lift ({at} of {dur})`)
			ok(Motion.sample(kind, 0, to, at, full) >= rise, `{kind}: up past its feet by then`)
			ok(Motion.sample(kind, 0, to, at - 0.005, full) < rise, `{kind}: not before`)
		end
	end
	local peek = KeeperTell.reveal("Peek", 0, 1.15, full, rise) or 0
	ok(peek < 0.7, `a peek knocks well before it's up ({peek})`)
	ok(KeeperTell.reveal("Open", 1.15, full, full, rise) == nil, "opening after a peek: shown")
	ok(KeeperTell.reveal("Open", 0, 0.3, full, rise) == nil, "a lift short of its feet: hidden")
	for _, kind in { "Close", "Slam", "Rattle", "Bang", "Burst" } :: { Motion.Kind } do
		ok(KeeperTell.reveal(kind, 0, full, full, rise) == nil, `{kind} never reveals`)
	end
end

-- every keeper's numbers hold together
do
	for name, row in KeeperRows do
		local problems = KeeperTell.check(row.tell)
		ok(#problems == 0, `{name}'s tell: {table.concat(problems, "; ")}`)
		local t = row.tell
		ok(t.footfall.reach > row.sight, `{name}: you hear it coming before it can see you`)
		ok(t.knock.reach <= t.footfall.reach, `{name}: the knocking is heard nearer than its feet`)
		ok(t.knock.volume < t.footfall.volume, `{name}: the knock sits under its footfalls`)
		ok(t.revealRise < 1.15, `{name}: a peek clears its feet`)
		-- at its top pace, two keys land more than `gap` apart, so no footfall is dropped
		-- (a player's full run is 16 studs a second: the chase measured 14.4 at 0.9)
		local fastest = row.speed * 16
		ok(t.gap < STEP / fastest, `{name}: its gap ({t.gap}) never drops a key at its top pace`)
	end
	local bad = KeeperTell.check({
		footfall = {
			takes = { { id = "9120864768", start = 0.2, stop = 0.21 } },
			fade = 0.05,
			volume = 1.4,
			pitchMin = 1.1,
			pitchMax = 1,
			near = 80,
			reach = 70,
		},
		knock = {
			takes = {},
			fade = 0.1,
			volume = 0.8,
			pitchMin = 1,
			pitchMax = 1,
			near = 4,
			reach = 40,
		},
		gap = 0,
		revealRise = 0,
		revealGain = 2,
		revealPitch = 1,
		revealGap = 0,
	})
	ok(#bad >= 9, `a broken tell is caught ({#bad}: {table.concat(bad, "; ")})`)
end

print(`tell: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
