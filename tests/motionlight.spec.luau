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
local REACH = math.sqrt((LENGTH / 2) ^ 2 + (WIDTH / 2) ^ 2)

-- A test hall along X like the dev corridor's: fixtures every 24 studs, each watching the box
-- under it. Returns the watch and each fixture's id.
local function hall(xs: { number }): (MotionLight.Watch, { number })
	local watch = MotionLight.watch()
	local ids = {}
	for _, x in xs do
		local area = Brix.Zone.box({
			pathing = FREE,
			center = vector.create(x, HEIGHT / 2, 0),
			size = vector.create(LENGTH, HEIGHT, WIDTH),
		})
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
	while x < 96 do
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
				fixtureX - w >= 14,
				"fixture "
					.. i
					.. " wakes at least 14 studs before you reach it ("
					.. (fixtureX - w)
					.. ")"
			)
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

if failures > 0 then
	error(`{failures} of {checks} motion light checks failed`)
end
print(`motionlight: {checks} checks passed`)
