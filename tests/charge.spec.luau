--!strict
-- lune run tests/charge.spec
-- The flashlight runs down (S1-09, GDD "The flashlight runs down"): only while it's on, about
-- five minutes from full; its last half minute flickers, the stutters closer and darker toward the
-- end and the light sagging, dying to nothing as the charge ends; switched off while it's dying,
-- it's dead. Each screen follows the server's whole seconds smoothly, and the ring on the button
-- lights a tick for any part of its share left.
local Charge = require("../src/shared/Flashlight/Charge")

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

-- a full torch: five minutes, or the Studio dev number when it's a real one
ok(Charge.full(nil) == 300, "a full torch holds five minutes")
ok(Charge.full(40) == 40, "the dev number holds that many seconds")
ok(Charge.full("40") == 300, "a dev string is ignored")
ok(Charge.full(0) == 300 and Charge.full(-5) == 300, "a dev number of none or less is ignored")
ok(Charge.full(0 / 0) == 300 and Charge.full(math.huge) == 300, "not a real number: ignored")

-- it drains only by the time it's on
ok(Charge.drain(300, 1) == 299, "a second on takes a second")
ok(Charge.drain(0.5, 1) == 0, "never below empty")
ok(Charge.drain(10, -1) == 10, "a backwards step takes nothing")
do
	-- the server's step at 60 a second: dead at five minutes, not before
	local left, t = Charge.full(nil), 0
	local at299 = 0
	while left > 0 and t < 400 do
		left = Charge.drain(left, 1 / 60)
		t += 1 / 60
		if near(t, 299, 1 / 120) then
			at299 = left
		end
	end
	ok(at299 > 0.9, "still a second left at 299 s on")
	ok(near(t, 300, 1 / 30), `dead at five minutes on (at {t})`)
end

-- switched off: a dying torch is dead, a living one keeps what's left
ok(Charge.off(1.0) == 0, "switched off with a second left: dead")
ok(Charge.off(Charge.Spent - 0.01) == 0, "just under spent: dead")
ok(Charge.off(10) == 10, "switched off with ten seconds: keeps them")

-- what the server writes: whole seconds, rounded up, so 0 means dead
ok(Charge.written(29.2) == 30, "29.2 s reads 30")
ok(Charge.written(0.001) == 1, "a sliver reads 1, not dead")
ok(Charge.written(0) == 0, "dead reads 0")
ok(Charge.written(300) == 300, "full reads 300")

-- a screen's reckoning between the server's ticks
ok(near(Charge.follow(30, 30, 0.25, true), 29.75), "drains on screen while on")
ok(Charge.follow(29.5, 30, 0.25, false) == 29.5, "holds while off")
ok(Charge.follow(28.5, 30, 0.1, true) == 29, "never below the second the server wrote")
ok(Charge.follow(30.6, 30, 0.1, true) == 30, "never above it")
ok(Charge.follow(12, 300, 0.1, false) == 299, "a battery lifts it at once")
ok(Charge.follow(0.2, 1, 0.5, true) == 0, "on screen it can die with the last second")
ok(Charge.follow(5, 0, 0.1, true) == 0, "the server's 0 is dead")

-- the last half minute
ok(not Charge.flickering(31), "steady above half a minute")
ok(Charge.flickering(30), "flickers from half a minute")
ok(Charge.flickering(0.2), "flickers to the end")
ok(not Charge.flickering(0), "dead: no flicker")
ok(Charge.urgency(60) == 0 and Charge.urgency(30) == 0, "no urgency before the flicker")
ok(near(Charge.urgency(15), 0.5) and Charge.urgency(0) == 1, "urgency climbs to dead")

-- the ring: twelve ticks, a tick for any part of its share left
ok(Charge.lit(300, 300) == 12, "full: every tick")
ok(Charge.lit(150, 300) == 6, "half: half the ring")
ok(Charge.lit(25, 300) == 1, "a tick's share exactly: one")
ok(Charge.lit(30, 300) == 2, "as the flicker begins: two ticks")
ok(Charge.lit(0.01, 300) == 1, "the last tick holds to the end")
ok(Charge.lit(0, 300) == 0, "dead: none")
ok(Charge.lit(20, 40) == 6, "on the dev number too")

-- the flicker
do
	-- above the last half minute: steady, full light, no stutter
	local f = Charge.flicker(7)
	local steady = true
	for _ = 1, 600 do
		local k, s = Charge.glow(f, 120, 1 / 60)
		if k ~= 1 or s then
			steady = false
		end
	end
	ok(steady, "steady and full above half a minute")
	ok(Charge.glow(f, 0, 1 / 60) == 0, "dead gives no light")
end

-- a half minute played out at 60 frames a second, draining as it goes
local function playOut(seed: number): { k: { number }, s: { boolean }, left: { number } }
	local f = Charge.flicker(seed)
	local out = { k = {}, s = {}, left = {} }
	local left = 30
	while left > 0 do
		local k, s = Charge.glow(f, left, 1 / 60)
		table.insert(out.k, k)
		table.insert(out.s, s)
		table.insert(out.left, left)
		left = Charge.drain(left, 1 / 60)
	end
	return out
end

do
	local run = playOut(11)
	local n = #run.k
	ok(n >= 1790 and n <= 1810, `half a minute of frames ({n})`)
	local inRange = true
	for _, k in run.k do
		if k < 0 or k > 1 then
			inRange = false
		end
	end
	ok(inRange, "the light is always between none and full")
	-- the first frame of the half minute stutters, and dips
	ok(run.s[1] and run.k[1] < 0.5, "the half minute opens with a dip")
	-- the first stutter is the long one
	local first = 0
	while run.s[first + 1] do
		first += 1
	end
	ok(
		near(first / 60, Charge.FirstStutter, 0.05),
		`the first stutter lasts its time ({first / 60})`
	)
	-- stutters come closer together toward the end, and are darker
	local function stats(from: number, to: number): (number, number, number)
		local starts, dark, frames = 0, 0, 0
		for i = 1, n do
			local left = run.left[i]
			if left <= from and left > to then
				frames += 1
				if run.s[i] and not run.s[i - 1] then
					starts += 1
				end
				if run.k[i] < 0.05 then
					dark += 1
				end
			end
		end
		return starts, dark / math.max(frames, 1), frames
	end
	local earlyStarts, earlyDark = stats(29, 19)
	local lateStarts, lateDark = stats(10, 0)
	ok(earlyStarts >= 1 and earlyStarts <= 4, `a few stutters early on ({earlyStarts})`)
	ok(lateStarts > earlyStarts * 2, `many more near the end ({lateStarts} vs {earlyStarts})`)
	ok(lateDark > earlyDark + 0.1, `far darker near the end ({lateDark} vs {earlyDark})`)
	-- between stutters the light sags as it starves
	local function steadyAt(left: number): number
		for i = 1, n do
			if run.left[i] <= left and not run.s[i] then
				return run.k[i]
			end
		end
		return -1
	end
	ok(near(steadyAt(29), 1, 0.01), "steady near full as the flicker begins")
	local late = steadyAt(3)
	ok(late > 0 and late < 0.65, `sagged near the end ({late})`)
	-- and over its last moments it dies to nothing
	local last = run.k[n]
	ok(last < 0.05, `all but dark on its last frame ({last})`)
end

-- each torch stutters on its own
do
	local a, b, c = playOut(3), playOut(3), playOut(4)
	local same, differ = true, false
	for i = 1, #a.k do
		if a.k[i] ~= b.k[i] then
			same = false
		end
		if a.k[i] ~= c.k[i] then
			differ = true
		end
	end
	ok(same, "the same seed flickers the same")
	ok(differ, "two torches never stutter together")
end

-- switched back on in the half minute, it sputters as it catches
do
	local f = Charge.flicker(5)
	for _ = 1, 120 do
		Charge.glow(f, 20, 1 / 60)
	end
	-- run until it's between stutters
	local guard = 0
	local _, s = Charge.glow(f, 20, 1 / 60)
	while s and guard < 600 do
		_, s = Charge.glow(f, 20, 1 / 60)
		guard += 1
	end
	Charge.rewind(f)
	local k2, s2 = Charge.glow(f, 20, 1 / 60)
	ok(s2 and k2 < 0.5, "rewound: the next frame sputters")
	-- refilled past the half minute and run down again: it opens with the long stutter again
	Charge.glow(f, 300, 1 / 60)
	local _, s3 = Charge.glow(f, 30, 1 / 60)
	ok(s3, "refilled, the next half minute opens with a stutter")
end

print(`charge: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
