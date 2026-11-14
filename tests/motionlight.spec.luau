--!strict
-- lune run tests/motionlight.spec
local Brix = require("../vendor/brix/src")
local MotionLight = require("../src/shared/MotionLight")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local FREE = Brix.Pathing.free()
local HOLD = MotionLight.HoldSeconds
local TICK = MotionLight.TickSeconds
local LENGTH, WIDTH, HEIGHT =
	MotionLight.WatchLength, MotionLight.WatchWidth, MotionLight.WatchHeight
local REACH = MotionLight.Reach

-- A test hall along X like the dev corridor's: fixtures every 24 studs, each watching the box
-- under it. Returns the watch and each fixture's id.
local function hall(xs: { number }): (MotionLight.Watch, { number })
	local watch = MotionLight.watch()
	local ids = {}
	for _, x in xs do
		local area = Brix.Zone.box(MotionLight.watchBox(FREE, x, 0, 0, MotionLight.turnOf(1, 0)))
		table.insert(ids, watch:add(area, x, 0, REACH))
	end
	return watch, ids
end

local function has(list: { number }, id: number): boolean
	return table.find(list, id) ~= nil
end

local function at(x: number, z: number?): vector
	return vector.create(x, 3, z or 0)
end

-- Steps one body along `path` (a position a tick, starting at `t0`), returning the time after.
local function walk(watch: MotionLight.Watch, path: { vector }, t0: number): number
	local t = t0
	for _, p in path do
		watch:step(t, { me = p })
		t += TICK
	end
	return t
end

do -- walking in wakes the light; holding still under it lets it fall dark
	local watch, ids = hall({ 0 })
	local a = ids[1]
	ok(watch:state(a) == "Dark", "a new fixture is dark")
	local changed = watch:step(0, { me = at(-30) })
	ok(#changed == 0 and watch:state(a) == "Dark", "a body seen for the first time trips nothing")
	watch:step(TICK, { me = at(-30) })
	ok(watch:state(a) == "Dark", "standing still outside trips nothing")
	-- walk in at 16 studs a second
	local t, x = 2 * TICK, -30
	local woke = false
	while x < 0 do
		x += 16 * TICK
		changed = watch:step(t, { me = at(x) })
		if has(changed, a) then
			woke = true
			ok(watch:state(a) == "Lit", "a woken light reports Lit")
			ok(
				x >= -LENGTH / 2 and x < -LENGTH / 2 + 16 * TICK + 1e-9,
				"it wakes as you step into its area (x " .. x .. ")"
			)
			break
		end
		t += TICK
	end
	ok(woke, "walking into the area wakes the light")
	-- freeze right there
	local frozeAt = t
	t += TICK
	while t < frozeAt + HOLD - TICK / 2 do
		changed = watch:step(t, { me = at(x) })
		ok(#changed == 0, "the light stays on while the hold runs (t " .. t .. ")")
		t += TICK
	end
	ok(watch:state(a) == "Lit", "still lit just before the hold runs out")
	changed = watch:step(frozeAt + HOLD + 1e-6, { me = at(x) })
	ok(
		has(changed, a) and watch:state(a) == "Dark",
		"frozen in the area, you go dark to it after the hold"
	)
	changed = watch:step(frozeAt + HOLD + TICK, { me = at(x) })
	ok(#changed == 0, "standing still in the dark wakes nothing")
	changed = watch:step(frozeAt + HOLD + 2 * TICK, { me = at(x + 1) })
	ok(has(changed, a), "the next step wakes it again")
end

do -- moving keeps it lit past the hold; leaving lets it fall dark a hold after the last step inside
	local watch, ids = hall({ 0 })
	local a = ids[1]
	local t = 0
	watch:step(t, { me = at(-4) })
	-- pace back and forth under it for twice the hold
	local x, dir = -4, 1
	while t < 2 * HOLD do
		t += TICK
		x += dir * 0.4
		if math.abs(x) > 4 then
			dir = -dir
		end
		watch:step(t, { me = at(x) })
	end
	ok(watch:state(a) == "Lit", "pacing under it keeps it lit past the hold")
	local lastInside = t
	-- leave towards -X at a run and keep going
	while x > -60 do
		t += TICK
		x -= 2
		watch:step(t, { me = at(x) })
		if x >= -LENGTH / 2 then
			lastInside = t
		end
	end
	local changed = watch:step(lastInside + HOLD + 1e-6, { me = at(x) })
	ok(
		watch:state(a) == "Dark" and has(changed, a),
		"it falls dark a hold after the last step inside"
	)
end

do -- slow creeping and swaying in place
	local watch, ids = hall({ 0 })
	local a = ids[1]
	local t = 0
	watch:step(t, { me = at(-2) })
	local x = -2
	for _ = 1, 30 do
		t += TICK
		x += 0.5 * TICK -- half a stud a second
		watch:step(t, { me = at(x) })
	end
	ok(watch:state(a) == "Dark", "slower than MovingSpeed counts as holding still")
	t += TICK
	watch:step(t, { me = vector.create(x, 3 + MotionLight.MovingSpeed * TICK * 2, 0) })
	ok(watch:state(a) == "Lit", "a jump in place trips it")
end

do -- movement outside the area, even in the same hash cell, trips nothing
	local watch, ids = hall({ 0 })
	local a = ids[1]
	watch:step(0, { me = at(-4, WIDTH / 2 + 1) })
	watch:step(TICK, { me = at(4, WIDTH / 2 + 1) })
	ok(watch:state(a) == "Dark", "walking past behind the doorway, inside a unit, trips nothing")
	watch:step(2 * TICK, { me = vector.create(-4, HEIGHT + 2, 0) })
	watch:step(3 * TICK, { me = vector.create(4, HEIGHT + 2, 0) })
	ok(watch:state(a) == "Dark", "moving above the deck trips nothing")
end

do -- walking the hall: the light ahead wakes before you reach it, those behind fall dark
	local watch, ids = hall({ -24, 0, 24, 48 })
	local t = 0
	local x = -30
	watch:step(t, { me = at(x) })
	local wokeAt: { [number]: number } = {}
	local darkAt: { [number]: number } = {}
	-- on past the last fixture, for longer than the hold since the first
	while x < 130 do
		t += TICK
		x += 16 * TICK
		local changed = watch:step(t, { me = at(x) })
		for _, id in changed do
			if watch:state(id) == "Lit" then
				wokeAt[id] = x
			else
				darkAt[id] = x
			end
		end
	end
	for i, id in ids do
		local fixtureX = -24 + (i - 1) * 24
		local w = wokeAt[id]
		ok(w ~= nil, "fixture " .. i .. " wakes as you walk the hall")
		if w and i > 1 then
			ok(
				fixtureX - w >= 18,
				`fixture {i} wakes 18 studs or more before you reach it ({fixtureX - w})`
			)
			ok(w - (fixtureX - 24) <= 6, `fixture {i} wakes as you pass under the one before it`)
		end
	end
	ok(darkAt[ids[1]] ~= nil, "the first fixture falls dark behind you")
	ok(
		darkAt[ids[4]] == nil and watch:state(ids[4]) == "Lit",
		"the one just behind you is still lit"
	)
	ok(watch:state(ids[1]) == "Dark", "the first is dark by the far end")
end

do -- two bodies: one moving keeps a shared light on while the other freezes
	local watch, ids = hall({ 0 })
	local a = ids[1]
	watch:step(0, { me = at(0), friend = at(4) })
	local t = 0
	for i = 1, 80 do
		t += TICK
		watch:step(t, { me = at(0), friend = at(4 + (i % 2) * 0.5) })
	end
	ok(watch:state(a) == "Lit", "a friend fidgeting keeps the light on over you")
	-- the friend leaves the game: forgotten, so it can't trip anything coming back
	t += TICK
	watch:step(t, { me = at(0) })
	t += TICK
	watch:step(t, { me = at(0), friend = at(-12) })
	t += HOLD + TICK
	local changed = watch:step(t, { me = at(0), friend = at(-12) })
	ok(
		has(changed, a) and watch:state(a) == "Dark",
		"a body that vanished and came back is a first sighting"
	)
end

do -- power: a cut fixture is blind and sees nothing; restored, it's dark until something moves
	local watch, ids = hall({ 0, 24 })
	local a, b = ids[1], ids[2]
	watch:step(0, { me = at(-4) })
	watch:step(TICK, { me = at(-2) })
	ok(watch:state(a) == "Lit", "lit before the cut")
	ok(watch:setPowered(a, false), "cutting a lit fixture changes it")
	ok(watch:state(a) == "Blind", "a cut fixture is blind")
	ok(not watch:setPowered(a, false), "cutting it again changes nothing")
	local changed = watch:step(2 * TICK, { me = at(2) })
	ok(
		not has(changed, a) and watch:state(a) == "Blind",
		"moving under a blind fixture wakes nothing"
	)
	changed = watch:step(2 * TICK + HOLD + 1, { me = at(2) })
	ok(not has(changed, a), "a blind fixture never times out into Dark")
	ok(watch:setPowered(a, true) and watch:state(a) == "Dark", "restored, it's dark")
	changed = watch:step(3 * TICK + HOLD + 1, { me = at(3) })
	ok(has(changed, a) and watch:state(a) == "Lit", "and the next movement wakes it")
	ok(watch:state(b) == "Dark", "its neighbour is untouched")
	local blind = watch:add(
		Brix.Zone.box({
			pathing = FREE,
			center = vector.create(48, HEIGHT / 2, 0),
			size = vector.create(LENGTH, HEIGHT, WIDTH),
		}),
		48,
		0,
		REACH,
		false
	)
	ok(watch:state(blind) == "Blind", "a fixture can be added already cut")
end

do -- a fixture in a hall along Z watches along Z
	local watch = MotionLight.watch()
	local area = Brix.Zone.box(MotionLight.watchBox(FREE, 0, 0, 0, MotionLight.turnOf(0, -1)))
	ok(area:contains(vector.create(0, 3, LENGTH / 2 - 1)), "its area runs along Z")
	ok(not area:contains(vector.create(WIDTH / 2 + 1, 3, 0)), "and is a hall wide across X")
	local id = watch:add(area, 0, 0, REACH)
	watch:step(0, { me = vector.create(0, 3, -15) })
	watch:step(TICK, { me = vector.create(0, 3, -14) })
	ok(watch:state(id) == "Lit", "walking down a Z hall wakes it")
end

do -- a removed fixture is forgotten
	local watch, ids = hall({ 0 })
	local a = ids[1]
	watch:remove(a)
	watch:step(0, { me = at(-4) })
	local changed = watch:step(TICK, { me = at(4) })
	ok(#changed == 0, "a removed fixture never changes")
	watch:remove(a)
	ok(true, "removing twice is harmless")
end

do -- the change list is reused, and a step with nothing to report returns it empty
	local watch = hall({ 0 })
	local first = watch:step(0, {})
	local second = watch:step(TICK, {})
	ok(first == second and #second == 0, "the same empty list each step")
end

do -- the alarm wakes every powered light at once, and they hold and fall dark as any other
	local watch, ids = hall({ 0, 24, 48 })
	local a, b, c = ids[1], ids[2], ids[3]
	ok(watch:setPowered(c, false), "the third light's power is cut")
	local woke = watch:wake(a, 10)
	ok(woke and watch:state(a) == "Lit", "the alarm wakes a dark light")
	ok(watch:wake(b, 10) and not watch:wake(b, 10), "a lit light woken again changes nothing")
	ok(not watch:wake(c, 10) and watch:state(c) == "Blind", "a blind light stays blind")
	local changed = watch:step(10 + HOLD - TICK, {})
	ok(#changed == 0 and watch:state(a) == "Lit", "a woken light holds HoldSeconds")
	changed = watch:step(10 + HOLD, {})
	ok(has(changed, a) and has(changed, b) and watch:state(a) == "Dark", "then it falls dark")
	ok(watch:wake(a, 20) and watch:state(a) == "Lit", "and the next alarm wakes it again")
end

-- A lit fixture's pool (L-06b3b): round it to PoolReach on its floor, and two fixtures 24 apart
-- leave no dark gap between their pools anywhere across an 8-stud hall, out to its walls.
do
	local R = MotionLight.PoolReach
	ok(MotionLight.inPool(0, 0, 0, 0, 0, 0), "right under it is in its pool")
	ok(MotionLight.inPool(0, 0, 0, R - 0.01, 0, 0), "just inside its reach")
	ok(not MotionLight.inPool(0, 0, 0, R + 0.01, 0, 0), "just past its reach")
	ok(MotionLight.inPool(0, 0, 0, 0, 0, -(R - 0.01)), "its reach is round: across too")
	ok(MotionLight.inPool(10, 50, -4, 10, 50, 5), "on its own floor wherever it hangs")
	ok(MotionLight.inPool(0, 0, 0, 1, 7, 1), "a jump is still in it")
	ok(not MotionLight.inPool(0, 0, 0, 1, HEIGHT + 0.5, 1), "a floor above isn't")
	ok(not MotionLight.inPool(0, 0, 0, 1, -1.5, 1), "nor one below")
	local gaps = 0
	for x = 0, 24, 0.25 do
		for z = -4, 4, 0.5 do
			if
				not (MotionLight.inPool(0, 0, 0, x, 0, z) or MotionLight.inPool(24, 0, 0, x, 0, z))
			then
				gaps += 1
			end
		end
	end
	ok(gaps == 0, `two lit fixtures 24 apart light the hall between them end to end ({gaps} dark)`)
end

-- The alarm's lights out (S2-04c): what a fixture shows, whether it has power, when it's back.
do
	local look = MotionLight.look
	ok(look("Blind", false, true) == "Out", "a fixture blind only for the alarm shows Out")
	ok(look("Blind", true, true) == "Blind", "the breaker's cut wins over the alarm's")
	ok(look("Blind", true, false) == "Blind", "the breaker's cut alone shows Blind")
	ok(look("Dark", false, false) == "Dark", "a powered dark fixture shows Dark")
	ok(look("Lit", false, false) == "Lit", "a powered lit fixture shows Lit")
	ok(look("Lit", false, true) == "Lit", "the look follows the watch: only a blind one is Out")
	ok(MotionLight.powered(false, false), "no cut and no alarm: powered")
	ok(not MotionLight.powered(false, true), "the alarm alone takes the power")
	ok(not MotionLight.powered(true, false), "the breaker alone takes the power")
	ok(MotionLight.outEnds(nil, 10, 3.5) == 13.5, "an alarm puts the lights out for its length")
	ok(MotionLight.outEnds(20, 10, 3.5) == 20, "a shorter alarm never cuts a longer one short")
	ok(MotionLight.outEnds(12, 10, 7) == 17, "a longer alarm keeps them out longer")
	ok(MotionLight.outEnds(nil, 10, -1) == 10, "a negative length puts nothing out")

	-- In a watch: out, its light goes and it sees nothing; back, it comes back dark and wakes.
	local watch, ids = hall({ 0 })
	local id = ids[1]
	ok(watch:wake(id, 0), "the alarm's floor had a light lit")
	ok(watch:setPowered(id, MotionLight.powered(false, true)), "the alarm takes its power")
	ok(watch:state(id) == "Blind", "out, it is blind")
	ok(not watch:wake(id, 1), "out, nothing wakes it")
	ok(watch:setPowered(id, MotionLight.powered(false, false)), "the power comes back")
	ok(watch:state(id) == "Dark", "back, it is dark: nothing lights the halls for free")
	ok(watch:wake(id, 2), "back, it wakes again")

	-- Back from the alarm, a light sees who stands under it, still or not (S2-07b1): the player
	-- waiting at the keypad lights up again, holds like any light, then goes dark if they keep
	-- still. Nobody under it, or still blind, it stays as it is.
	local w2, ids2 = hall({ 0, 48 })
	local under, far = ids2[1], ids2[2]
	w2:step(0, { me = at(2) })
	w2:step(TICK, { me = at(2) })
	ok(w2:state(under) == "Dark", "standing still from the start, the light stays dark")
	w2:setPowered(under, false)
	w2:setPowered(far, false)
	ok(not w2:look(under, 1, { me = at(2) }), "still blind, it sees nobody")
	w2:setPowered(under, true)
	w2:setPowered(far, true)
	ok(w2:look(under, 5, { me = at(2) }), "back, it lights for the player standing still under it")
	ok(w2:state(under) == "Lit", "lit")
	ok(not w2:look(far, 5, { me = at(2) }), "a light with nobody under it stays dark")
	ok(w2:state(far) == "Dark", "dark")
	ok(not w2:look(under, 5.5, { me = at(2) }), "a lit light looking again changes nothing")
	local changed = w2:step(5 + HOLD - TICK, { me = at(2) })
	ok(not has(changed, under) and w2:state(under) == "Lit", "it holds like any light")
	changed = w2:step(5 + HOLD, { me = at(2) })
	ok(has(changed, under) and w2:state(under) == "Dark", "kept still, they go dark to it again")
	ok(not w2:look(under, 20, {}), "with no bodies at all, it stays dark")
end

if failures > 0 then
	error(`{failures} of {checks} motion light checks failed`)
end
print(`motionlight: {checks} checks passed`)
