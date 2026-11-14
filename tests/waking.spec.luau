--!strict
-- lune run tests/waking.spec
-- Sleeping monsters wake (S2-03a, GDD "Sleeping monsters wake"): nothing wakes before four
-- minutes on floors 1 and 2; then three, three more every two minutes; higher up it starts sooner
-- and wakes more at once, within its floors' limits. A step never wakes more than are owed, more
-- than are left asleep, or past the phone cap, and what the cap held back wakes once there's room.
-- Picks are distinct sleepers, every door as likely as any other. One a wave woke breaks out only
-- while the floor has room under its limit on loose monsters (S2-07a2, `Deal.awakeCap`), the
-- longest shut in first.
local Deal = require("../src/shared/Deal")
local Waking = require("../src/shared/Waking")

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

-- A seeded roll from 1 to k (Park-Miller, so the spec is the same every run).
local function roller(seed: number): (number) -> number
	local state = seed
	return function(k: number): number
		state = (state * 48271) % 2147483647
		return 1 + state % k
	end
end

-- The numbers the ticket names: four minutes, three at a time, two minutes apart, on floors 1-2.
for _, floor in { 1, 2 } do
	ok(Waking.first(floor) == 240, `floor {floor}: first wave at four minutes`)
	ok(Waking.gap(floor) == 120, `floor {floor}: two minutes between waves`)
	ok(Waking.size(floor) == 3, `floor {floor}: three at a time`)
	ok(Waking.owed(floor, 239.9) == 0, `floor {floor}: nothing owed just before four minutes`)
	ok(Waking.owed(floor, 240) == 3, `floor {floor}: three owed at four minutes`)
	ok(Waking.owed(floor, 359.9) == 3, `floor {floor}: still three just before six minutes`)
	ok(Waking.owed(floor, 360) == 6, `floor {floor}: six owed at six minutes`)
	ok(Waking.owed(floor, 480) == 9, `floor {floor}: nine owed at eight minutes`)
end

-- Higher up: sooner, closer together, more at once; never past the limits.
local lastFirst, lastGap, lastSize = math.huge, math.huge, 0
for floor = 1, 40 do
	local first, gap, size = Waking.first(floor), Waking.gap(floor), Waking.size(floor)
	ok(first <= lastFirst, `floor {floor}: the first wave never comes later than a floor below`)
	ok(gap <= lastGap, `floor {floor}: waves never further apart than a floor below`)
	ok(size >= lastSize, `floor {floor}: never fewer at once than a floor below`)
	ok(first >= Waking.FirstLeast, `floor {floor}: at least {Waking.FirstLeast} s of quiet`)
	ok(gap >= Waking.GapLeast, `floor {floor}: waves at least {Waking.GapLeast} s apart`)
	ok(size <= Waking.SizeMost, `floor {floor}: at most {Waking.SizeMost} at once`)
	ok(Waking.owed(floor, first - 0.01) == 0, `floor {floor}: nothing owed before the first wave`)
	ok(Waking.owed(floor, first) == size, `floor {floor}: one wave owed at the first`)
	lastFirst, lastGap, lastSize = first, gap, size
end
ok(Waking.first(3) < Waking.first(2), "floor 3 starts sooner than floor 2")
ok(Waking.size(4) > Waking.size(3), "floor 4 wakes more at once than floor 3")
ok(Waking.first(40) == Waking.FirstLeast, "high up the first wave sits at its least")
ok(Waking.gap(40) == Waking.GapLeast, "high up the gap sits at its least")
ok(Waking.size(40) == Waking.SizeMost, "high up a wave is its most")

-- A step: what's owed less what's woken, held by sleepers left and by the phone cap.
ok(Waking.now(1, 100, 0, 0, 10) == 0, "nothing wakes before the first wave")
ok(Waking.now(1, 240, 0, 0, 10) == 3, "three wake at the first wave")
ok(Waking.now(1, 250, 3, 3, 7) == 0, "those three aren't woken twice")
ok(Waking.now(1, 240, 0, 0, 2) == 2, "only the sleepers left wake")
ok(Waking.now(1, 240, 0, 0, 0) == 0, "a floor with no sleepers stays quiet")
ok(Waking.now(1, 240, 0, Waking.AwakeMost, 10) == 0, "nothing wakes past the phone cap")
ok(Waking.now(1, 240, 0, Waking.AwakeMost - 1, 10) == 1, "one wakes into the last room")
ok(Waking.now(1, 240, 0, Waking.AwakeMost + 2, 10) == 0, "over the cap is never negative")
ok(Waking.now(1, 600, 3, 2, 7) == 4, "held-back wakes come due once there's room")

-- A whole floor, stepped every half second for fifteen minutes on many floors: wakes come only
-- at wave times, never more than owed or left, never past the cap once under it.
for floor = 1, 12 do
	for left0 = 0, 12, 3 do
		local woken, awake, left = 0, 1, left0
		local wakeTimes = {}
		for step = 0, 1800 do
			local t = step * 0.5
			local n = Waking.now(floor, t, woken, awake, left)
			ok(n >= 0, `floor {floor}: never a negative wake`)
			if n > 0 then
				table.insert(wakeTimes, t)
			end
			woken += n
			awake += n
			left -= n
			ok(left >= 0, `floor {floor}: never wakes a sleeper that isn't there`)
			ok(awake <= Waking.AwakeMost, `floor {floor}: never past the phone cap`)
			ok(woken <= Waking.owed(floor, t), `floor {floor}: never more than owed`)
		end
		for _, t in wakeTimes do
			local since = t - Waking.first(floor)
			ok(
				since >= 0 and since % Waking.gap(floor) == 0,
				`floor {floor}: wakes land on wave times ({t})`
			)
		end
		if left0 > 0 then
			ok(#wakeTimes > 0, `floor {floor}: something wakes in fifteen minutes`)
		end
	end
end

-- Picks: the right count, distinct, all from the list, the list untouched, and fair.
local slots = { 4, 9, 13, 21, 30, 31 }
for seed = 1, 50 do
	local roll = roller(seed)
	for n = 0, 8 do
		local picked = Waking.pick(slots, n, roll)
		ok(#picked == math.min(n, #slots), `pick {n}: the right count`)
		local seen = {}
		for _, slot in picked do
			ok(not seen[slot], `pick {n}: no slot twice`)
			seen[slot] = true
			ok(table.find(slots, slot) ~= nil, `pick {n}: only sleepers' slots`)
		end
	end
end
ok(#slots == 6 and slots[1] == 4 and slots[6] == 31, "picking leaves the list as it was")
ok(#Waking.pick({}, 3, roller(1)) == 0, "no sleepers, no picks")

local counts: { [number]: number } = {}
local roll = roller(7)
local TRIALS = 6000
for _ = 1, TRIALS do
	for _, slot in Waking.pick(slots, 3, roll) do
		counts[slot] = (counts[slot] or 0) + 1
	end
end
local fair = TRIALS * 3 / #slots
for _, slot in slots do
	local c = counts[slot] or 0
	ok(math.abs(c - fair) < fair * 0.1, `slot {slot} picked about as often as any ({c} of ~{fair})`)
end

-- S2-07a2: a woken one bursts out only while the floor's loose ones, and the woken ones ahead of
-- it (longer shut in, or already bursting), leave room under the deal's cap.
ok(Waking.free(1, 0, 0), "floor 1, nobody loose: it may burst")
ok(not Waking.free(1, 1, 0), "floor 1, one loose already: it pounds on")
ok(not Waking.free(1, 0, 1), "floor 1, one ahead of it: it pounds on")
ok(Waking.free(3, 1, 0), "floor 3 allows two: one loose, it may burst")
ok(not Waking.free(3, 1, 1), "floor 3, one loose and one ahead: it pounds on")
ok(not Waking.free(9, 3, 0), "floor 9 allows three: three loose, it pounds on")
for floor = 1, 40 do
	local cap = Deal.awakeCap(floor)
	for loose = 0, 6 do
		for ahead = 0, 6 do
			ok(
				Waking.free(floor, loose, ahead) == (loose + ahead < cap),
				`floor {floor}, {loose} loose, {ahead} ahead: free only under the cap`
			)
		end
	end
	-- a wave of six on a floor with nobody loose: only the cap's worth get out, the rest pound
	local out = 0
	for ahead = 0, 5 do
		if Waking.free(floor, 0, ahead) then
			out += 1
		end
	end
	ok(out == math.min(cap, 6), `floor {floor}: a wave lets out {cap}, never more ({out})`)
end

if failures > 0 then
	error(`waking: {failures} of {checks} checks failed`)
end
print(`waking: all {checks} checks passed`)
