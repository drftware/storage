--!strict
-- lune run tests/dent.spec
-- The dent (L-06b3d2): a trapped keeper's blows bow its door out toward the hall. The server keeps
-- the share of its break-out time gone at its latest blow on the door, never going back; every
-- screen shows the baked step that share reaches. No dent before a blow; the first blow already
-- shows; worse at each half-minute peek through a trap (30, 60 and 85 s of the Mannequin's 90);
-- the last step at the burst. And the Mannequin's real blow clock (its row's gaps, jittered either
-- way) lands a blow in every step's stretch, so each step is seen before the burst.
local Dent = require("../src/shared/StorageUnit/Dent")
local KeeperRows = require("../src/shared/KeeperRows")

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

local STEPS = 3 -- art/unit/dent.py's steps, as the unit Specs list them (Dent)
local ROW = KeeperRows.Mannequin

-- The share of its time gone
do
	ok(Dent.share(0, 90) == 0, "no time gone at the slam")
	ok(math.abs(Dent.share(45, 90) - 0.5) < 1e-9, "half its time at 45 s of 90")
	ok(Dent.share(120, 90) == 1, "never past all of it")
	ok(Dent.share(-3, 90) == 0, "never below none")
	ok(Dent.share(5, 0) == 1, "a keeper with no time to wait is out at once: all of it")
end

-- Never back
do
	ok(Dent.raise(0.6, 0.3) == 0.6, "a smaller share never pulls the door back in")
	ok(Dent.raise(0.3, 0.6) == 0.6, "a bigger one dents it further")
	ok(Dent.raise(0, 1.7) == 1, "clamped to all of it")
	ok(Dent.raise(-1, -1) == 0, "clamped to none")
	local was = 0
	local seed = 7
	for _ = 1, 500 do
		seed = (seed * 1103515245 + 12345) % 2147483648 -- a plain LCG: Lune has no Random
		local now = Dent.raise(was, -0.2 + 1.4 * seed / 2147483648)
		ok(now >= was and now >= 0 and now <= 1, `raise never goes back ({was} to {now})`)
		was = now
	end
end

-- Steps
do
	ok(Dent.Lands[1] == 0, "the first step lands on the first blow")
	for i = 2, #Dent.Lands do
		ok(Dent.Lands[i] > Dent.Lands[i - 1], `step {i} lands after step {i - 1}`)
	end
	ok(#Dent.Lands == STEPS, "a landing share for each of the art's steps")
	ok(Dent.step(0, STEPS) == 0, "no dent before a blow")
	ok(Dent.step(-0.5, STEPS) == 0, "none for a bad share")
	ok(Dent.step(0 / 0, STEPS) == 0, "none for NaN")
	ok(Dent.step(ROW.bangFirst / ROW.breakOut, STEPS) == 1, "the first blow shows: dented")
	ok(
		Dent.step(Dent.share(ROW.breakOut, ROW.breakOut), STEPS) == STEPS,
		"the burst: the worst step"
	)
	ok(Dent.step(0.9, 0) == 0, "no art, no dent")
	ok(Dent.step(0.9, 2) == 2, "never past the art's steps")
	local last = 0
	for i = 0, 1000 do
		local s = Dent.step(i / 1000, STEPS)
		ok(s >= last and s <= STEPS, `steps never go back ({i / 1000})`)
		last = s
	end
	-- the ticket's peeks through one trap: worse each time
	local at30 = Dent.step(Dent.share(30, ROW.breakOut), STEPS)
	local at60 = Dent.step(Dent.share(60, ROW.breakOut), STEPS)
	local at85 = Dent.step(Dent.share(85, ROW.breakOut), STEPS)
	ok(
		at30 >= 1 and at60 > at30 and at85 > at60,
		`worse at 30, 60 and 85 s ({at30}, {at60}, {at85})`
	)
end

-- The Mannequin's blows reach every step before it bursts out, its gaps jittered either way
for _, jitter in { -1, 0, 1 } do
	local seen: { [number]: number } = {}
	local t = ROW.bangFirst
	local dent = 0
	while t < ROW.breakOut do
		dent = Dent.raise(dent, Dent.share(t, ROW.breakOut))
		local s = Dent.step(dent, STEPS)
		seen[s] = seen[s] or t
		local share = Dent.share(t, ROW.breakOut)
		local base = ROW.bangEvery + (ROW.bangEveryLast - ROW.bangEvery) * share
		t += base * (1 + ROW.bangJitter * jitter)
	end
	for s = 1, STEPS do
		ok(seen[s] ~= nil, `jitter {jitter}: a blow shows step {s} before the burst`)
	end
	ok((seen[STEPS] or math.huge) <= 85, `jitter {jitter}: buckling by 85 s ({seen[STEPS]})`)
	ok((seen[2] or math.huge) <= 60, `jitter {jitter}: bowed by 60 s ({seen[2]})`)
	ok((seen[1] or math.huge) <= 2, `jitter {jitter}: dented on the first blow ({seen[1]})`)
end

if failures > 0 then
	error(`dent: {failures} of {checks} checks failed`)
end
print(`dent: all {checks} checks passed`)
