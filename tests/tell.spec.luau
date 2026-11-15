--!strict
-- lune run tests/tell.spec
-- How a keeper gives itself away by sound (L-06b4b2, L-06c1): its limp's beats as its walk lands
-- them (a footfall, its dragged foot's scrape, its stiff heel, then nothing), each key heard once,
-- the moment a screen shows it (`Pose.tell`); steps heavier the nearer it is; a creak as it turns;
-- and an answer as a lifted door first clears the feet of one standing in a unit (`KeeperTell`).
local KeeperRows = require("../src/shared/KeeperRows")
local KeeperTell = require("../src/shared/KeeperTell")
local Motion = require("../src/shared/StorageUnit/Motion")
local Pose = require("../src/shared/Mannequin/Pose")
local PackratPose = require("../src/shared/Packrat/Pose")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local STEP, KEYS = Pose.Walk.Step, #Pose.Walk.Keys
local PER_KEY = Pose.Walk.Settle + Pose.Walk.Snaps

-- the key a frame shows (0-based within the cycle), or nil for Still
local function keyOf(frame: number): number?
	return if frame <= 1 then nil else (frame - 2) // PER_KEY
end

-- where each key lands in a stride, in studs, and the stride
local STARTS, STRIDE = {}, 0
for i, span in Pose.Walk.Spans do
	STARTS[i] = STRIDE
	STRIDE += span * STEP
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

-- a walk: the limp's three beats each stride, in its order, and nothing as the good leg swings
do
	local heard, landings = walk(0, STRIDE * 3, 0.05, "Walk")
	ok(landings == KEYS * 3, `three strides land {KEYS * 3} keys ({landings})`)
	ok(#heard == 3 * 3, `and make three beats a stride ({#heard})`)
	local order: { Pose.Sound } = { "Drag", "Heel", "Footfall" }
	local inOrder = true
	for i, h in heard do
		if h.sound ~= order[(i - 1) % 3 + 1] then
			inOrder = false
		end
	end
	ok(inOrder, "from a planted step: the drag, the heel, the next footfall, over and over")
	-- each lands where the snap shows the next key, late in its key's span: after the hold
	local ahead = heard[1].at / (Pose.Walk.Spans[1] * STEP)
	ok(ahead > Pose.Walk.Holds[1] and ahead <= 1, `the first lands late in its span ({ahead})`)
	-- the limp: the beats land unevenly, the drag's gap the longest
	local plantToDrag = heard[1].at
	local dragToHeel = heard[2].at - heard[1].at
	local heelToPlant = heard[3].at - heard[2].at
	ok(dragToHeel > plantToDrag * 1.4, `the drag takes longest ({plantToDrag}, {dragToHeel})`)
	ok(heelToPlant > plantToDrag, "the good leg's swing through is silent, a pause in the beat")
end

-- the same walk sounds the same however a screen's frames fall
do
	local fine = walk(0, STRIDE * 2, 0.01, "Walk")
	local coarse = walk(0, STRIDE * 2, 0.4, "Walk")
	ok(#fine == #coarse, `fine and coarse frames hear as many beats ({#fine}, {#coarse})`)
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
	local heel = STARTS[3] + 0.2 -- holding its third key, the stiff heel
	local sound, after = Pose.tell(last, heel, "Walk")
	ok(sound == "Heel", `a jump to its third key lands the heel once ({sound})`)
	ok(after == 2, "and remembers that key")
	local again = Pose.tell(after, heel + 0.1, "Walk")
	ok(again == nil, "nothing more until the next key")
end

-- caught by a light mid-snap: it lands the next key at once (heard), and isn't heard again as it
-- walks on through the rest of that snap
do
	local span, hold = Pose.Walk.Spans[1] * STEP, Pose.Walk.Holds[1]
	local mid = span * (hold + (1 - hold) * 0.4) -- 40% into the first snap
	local _, last = Pose.tell(nil, mid, "Walk")
	local frozen: Pose.Sound?
	frozen, last = Pose.tell(last, mid, "Stop")
	ok(frozen == "Drag", "freezing mid-snap lands the drag it snapped into")
	local walking: Pose.Sound?
	walking, last = Pose.tell(last, mid + 0.05, "Walk")
	ok(walking == nil, "walking on from inside that snap is silent")
	local heard: { Pose.Sound } = {}
	local t = mid + 0.05
	while t < STRIDE - 0.3 do -- short of where the next footfall lands
		t += 0.05
		local s: Pose.Sound?
		s, last = Pose.tell(last, t, "Walk")
		if s then
			table.insert(heard, s)
		end
	end
	ok(#heard == 1 and heard[1] == "Heel", `then only the heel is heard ({#heard})`)
end

-- caught while holding a key: it stays on it, silent; frozen, it stays silent however long
do
	local held = Pose.Walk.Spans[1] * STEP * Pose.Walk.Holds[1] * 0.5
	local _, last = Pose.tell(nil, held, "Walk")
	local s: Pose.Sound?
	s, last = Pose.tell(last, held, "Stop")
	ok(s == nil, "freezing while it holds a key is silent")
	local quiet = true
	for _ = 1, 50 do
		s, last = Pose.tell(last, held, "Stop")
		quiet = quiet and s == nil
	end
	ok(quiet, "and held in the light it makes no sound at all")
end

-- slack, then into a stride: its body creaks as it jerks out of its shop pose
do
	local _, last = Pose.tell(nil, 0, "Still")
	local sound, after = Pose.tell(last, 0, "Walk")
	ok(sound == "Creak", "waking from slack into its stride creaks")
	ok(after == 0, "on its first key")
	local s2 = Pose.tell(last, 0, "Stop")
	ok(s2 == "Creak", "so does waking into a held stride (watching)")
	local _, slack = Pose.tell(after, 0, "Still")
	ok(Pose.tell(slack, 0, "Still") == nil, "standing slack is silent")
end

-- nearer, heavier: the heft eases from nothing far off to all of it up close
do
	local tell = KeeperRows.Mannequin.tell
	ok(KeeperTell.heft(tell, 0) == 1 and KeeperTell.heft(tell, tell.heavyNear) == 1, "close: all")
	ok(KeeperTell.heft(tell, tell.heavyFar) == 0 and KeeperTell.heft(tell, 500) == 0, "far: none")
	local prev, smooth = 1, true
	for d = tell.heavyNear, tell.heavyFar, 0.5 do
		local h = KeeperTell.heft(tell, d)
		if h > prev + 1e-12 or prev - h > 0.06 then
			smooth = false
		end
		prev = h
	end
	ok(smooth, "it only ever gets lighter going away, never in a jump")
	local weight = tell.sounds.Weight
	local g1, p1 = KeeperTell.weigh(weight, 1)
	local g0, p0 = KeeperTell.weigh(weight, 0)
	ok(g1 == 1 and p1 == 1, "up close the weight plays as itself")
	ok(g0 == weight.farGain and p0 == weight.farPitch, "far off, at its far gain and pitch")
	local gm, pm = KeeperTell.weigh(weight, 0.5)
	ok(gm > g0 and gm < g1 and pm < p0 and pm > p1, "and between, between")
end

-- its body creaks once it has turned far enough
do
	ok(not KeeperTell.turned(0, -1, 0, -1, 40), "facing the same way: no creak")
	ok(not KeeperTell.turned(0, -1, math.sin(math.rad(30)), -math.cos(math.rad(30)), 40), "30: no")
	ok(KeeperTell.turned(0, -1, math.sin(math.rad(50)), -math.cos(math.rad(50)), 40), "50: creaks")
	ok(KeeperTell.turned(0, -1, -1, 0, 40), "a corner creaks either way")
	ok(KeeperTell.turned(1, 0, -1, 0, 40), "turning round to you creaks")
	ok(not KeeperTell.turned(0, 0, 1, 0, 40), "no facing yet: no creak")
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
	ok(peek < 0.7, `a peek answers well before it's up ({peek})`)
	ok(KeeperTell.reveal("Open", 1.15, full, full, rise) == nil, "opening after a peek: shown")
	ok(KeeperTell.reveal("Open", 0, 0.3, full, rise) == nil, "a lift short of its feet: hidden")
	for _, kind in { "Close", "Slam", "Rattle", "Bang", "Burst" } :: { Motion.Kind } do
		ok(KeeperTell.reveal(kind, 0, full, full, rise) == nil, `{kind} never reveals`)
	end
end

-- every keeper's numbers hold together
do
	for name, row in KeeperRows do
		local t = row.tell
		local problems = KeeperTell.check(t)
		ok(#problems == 0, `{name}'s tell: {table.concat(problems, "; ")}`)
		local function reach(beat: KeeperTell.Beat): number
			local r = 0
			for _, l in t.beats[beat] do
				r = math.max(r, t.sounds[l.sound].reach)
			end
			return r
		end
		ok(reach("Footfall") > row.sight, `{name}: you hear it coming before it can see you`)
		ok(reach("Drag") < reach("Footfall"), `{name}: the scrape is heard nearer than its steps`)
		ok(reach("Creak") < reach("Drag"), `{name}: a creak is heard only close`)
		ok(t.heavyFar < reach("Footfall"), `{name}: far off, its steps are light taps`)
		-- nearer, heavier: some layer of its footfall is quieter and higher far off than near
		local heavier = false
		for _, l in t.beats.Footfall do
			local s = t.sounds[l.sound]
			if s.farGain < 1 and s.farPitch > 1 then
				heavier = true
			end
		end
		ok(heavier, `{name}: its steps get heavier as it nears`)
		-- its planted foot is the heaviest beat, the heel lighter, so the walk limps
		local function loud(beat: KeeperTell.Beat): number
			local v = 0
			for _, l in t.beats[beat] do
				v += t.sounds[l.sound].volume * l.gain
			end
			return v
		end
		ok(loud("Footfall") > loud("Heel"), `{name}: the heel is lighter than the footfall`)
		ok(t.revealRise < 1.15, `{name}: a peek clears its feet`)
		-- at its top pace, two keys land more than `gap` apart, so no beat is dropped (a
		-- player's full run is 16 studs a second: the chase measured 14.4 at 0.9)
		local fastest = row.speed * 16
		local shortest = math.huge
		for _, span in Pose.Walk.Spans do
			shortest = math.min(shortest, span * STEP)
		end
		ok(
			t.gap < shortest / fastest,
			`{name}: its gap ({t.gap}) never drops a beat at its top pace`
		)
		-- every fade is timed for the fastest it plays
		for sname, s in t.sounds do
			ok(KeeperTell.fastest(t, sname) >= s.pitchMax, `{name}: {sname}'s fastest`)
		end
	end
	local bad = KeeperTell.check({
		sounds = {
			Shell = {
				takes = { { id = "9120864768", start = 0.2, stop = 0.21 } },
				fade = 0.05,
				volume = 1.4,
				pitchMin = 1.1,
				pitchMax = 1,
				near = 80,
				reach = 70,
				farGain = 2,
				farPitch = 0,
			},
			Empty = {
				takes = {},
				fade = 0.1,
				volume = 0.8,
				pitchMin = 1,
				pitchMax = 1,
				near = 4,
				reach = 40,
				farGain = 1,
				farPitch = 1,
			},
		},
		beats = {
			Footfall = { { sound = "Nothing", gain = 1, pitch = 1 } },
			Drag = { { sound = "Empty", gain = 2, pitch = 1 } },
			Heel = {},
		},
		heavyNear = 40,
		heavyFar = 10,
		gap = 0,
		turn = 200,
		turnGap = 0,
		revealRise = 0,
		revealGap = 0,
	} :: any) -- any: a deliberately broken row, missing beats included
	ok(#bad >= 16, `a broken tell is caught ({#bad}: {table.concat(bad, "; ")})`)
end

-- The Packrat (S2-06e): each walk's keys land as a foot, a pass, the other foot, then nothing,
-- each heard once; streaming in, or its arms filling or emptying, is silent until its next key;
-- its arm going out creaks once; standing, taking or putting down it makes no sound.
do
	local function stride(walk: PackratPose.Walk, how: string): { string }
		local step = PackratPose.Walk.Step[walk]
		local heard = {}
		local _, last = PackratPose.tell(walk, nil, 0, how)
		local t = 0
		while t < 8 * step - 0.01 do
			t += step / 20
			local sound
			sound, last = PackratPose.tell(walk, last, t, how)
			if sound then
				table.insert(heard, sound)
			end
		end
		return heard
	end
	local empty = table.concat(stride("Empty", "Walk"), " ")
	ok(empty == "Drag Heel Footfall Drag Heel Footfall", `empty walk's beats: {empty}`)
	local full = table.concat(stride("Full", "Carry"), " ")
	ok(full == "Drag Heel Footfall Drag Heel Footfall", `full walk's beats: {full}`)
	ok(PackratPose.tell("Empty", nil, 9.3, "Walk") == nil, "streaming in mid-walk is silent")

	-- a late record that jumps two keys makes one sound, the last key's
	local _, last = PackratPose.tell("Empty", nil, 0, "Walk")
	local jumped = PackratPose.tell("Empty", last, 2 * PackratPose.Walk.Step.Empty, "Walk")
	ok(jumped == "Heel", `a jump of keys lands its last: {tostring(jumped)}`)

	-- whether a walk heard anything over its next two keys, from `last` at `from` studs
	local function heardSoon(walk: PackratPose.Walk, last: number, from: number, how: string)
		local step = PackratPose.Walk.Step[walk]
		local a, l = PackratPose.tell(walk, last, from + step, how)
		local b = PackratPose.tell(walk, l, from + 2 * step, how)
		return a ~= nil or b ~= nil
	end

	-- arms filling: silent as it switches, then the full walk's next key is heard
	local _, e = PackratPose.tell("Empty", nil, 40, "Walk")
	local s1, f = PackratPose.tell("Full", e, 40.05, "Carry")
	ok(s1 == nil, "switching to the full walk is silent")
	ok(heardSoon("Full", f, 40.05, "Carry"), "the full walk's next keys are heard")
	-- and emptying back at a count far below the full walk's
	local s3, e2 = PackratPose.tell("Empty", f, 41, "Walk")
	ok(s3 == nil, "switching back is silent")
	ok(heardSoon("Empty", e2, 41, "Walk"), "the empty walk's next keys are heard, not held back")

	-- reaching creaks once; the held poses are silent
	local _, w = PackratPose.tell("Empty", nil, 5, "Walk")
	local r1, r = PackratPose.tell("Empty", w, 5, "Reach")
	ok(r1 == "Creak", "its arm going out creaks")
	ok(PackratPose.tell("Empty", r, 5, "Reach") == nil, "once")
	for _, how in { "Still", "Take", "PutDown" } do
		local s = PackratPose.tell("Full", w, 5 + 10, how)
		ok(s == nil, `{how} is silent`)
	end
	ok(PackratPose.tell("Empty", nil, 5, "Reach") == nil, "streamed in reaching: silent")
end

-- Its arms are full walking (Carry) or standing (Hold) with a find, and only then does a row's
-- `full` tell play; a row without one always plays its `tell`.
do
	for _, how in { "Carry", "Hold" } do
		ok(KeeperTell.full(how), `{how}: arms full`)
	end
	for _, how in { "Walk", "Stop", "Still", "Reach", "Take", "PutDown", "Pull" } do
		ok(not KeeperTell.full(how), `{how}: arms not full`)
	end
	local rat = KeeperRows.Packrat
	ok(KeeperTell.of(rat.tell, rat.full, true) == rat.full, "the Packrat full plays its full tell")
	ok(KeeperTell.of(rat.tell, rat.full, false) == rat.tell, "and empty its own")
	local man = KeeperRows.Mannequin
	ok(
		KeeperTell.of(man.tell, man.full, true) == man.tell,
		"a row with no full tell plays its tell"
	)
end

-- Full and empty sound apart, each heard before it's seen, full the heavier tread.
do
	local rat = KeeperRows.Packrat
	local full = rat.full
	ok(full ~= nil, "the Packrat has a full tell")
	if full then
		local problems = KeeperTell.check(full)
		ok(#problems == 0, `the Packrat's full tell: {table.concat(problems, "; ")}`)
		local ids = {}
		for _, sound in rat.tell.sounds do
			for _, take in sound.takes do
				ids[take.id] = true
			end
		end
		for name, sound in full.sounds do
			for _, take in sound.takes do
				ok(not ids[take.id], `full's {name} shares no recording with the empty walk`)
			end
		end
		local function reach(t: KeeperTell.Tell, beat: KeeperTell.Beat): number
			local r = 0
			for _, l in t.beats[beat] do
				r = math.max(r, t.sounds[l.sound].reach)
			end
			return r
		end
		local function loud(t: KeeperTell.Tell, beat: KeeperTell.Beat): number
			local v = 0
			for _, l in t.beats[beat] do
				v += t.sounds[l.sound].volume * l.gain
			end
			return v
		end
		ok(reach(full, "Footfall") > rat.sight, "full, it's heard before it's seen")
		ok(reach(full, "Footfall") >= reach(rat.tell, "Footfall"), "its load carries as far")
		ok(loud(full, "Footfall") > loud(rat.tell, "Footfall"), "full, its tread is heavier")
		ok(loud(full, "Footfall") > loud(full, "Heel"), "full, its lead foot lands heavier")
		for sname, s in full.sounds do
			ok(KeeperTell.fastest(full, sname) >= s.pitchMax, `full's {sname}'s fastest`)
		end
	end
end

print(`tell: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
