--!strict
-- lune run tests/wrongcode.spec
-- A wrong code lets monsters out (S2-04, GDD "A wrong code"): one unit on a floor's first wrong
-- code, three on the second, five on every one after; sleepers first, then monsters already
-- awake behind shut doors; never more sleepers than the floor has room for on their feet; each
-- pick distinct and fair; the doors start rolling one after another once the alarm has sounded.
local WrongCode = require("../src/shared/WrongCode")

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

local function set(list: { number }): { [number]: boolean }
	local s: { [number]: boolean } = {}
	for _, v in list do
		s[v] = true
	end
	return s
end

-- the ticket's numbers
ok(WrongCode.opens(1) == 1, "the first wrong code opens one")
ok(WrongCode.opens(2) == 3, "the second opens three")
ok(WrongCode.opens(3) == 5, "the third opens five")
ok(WrongCode.opens(12) == 5, "and every one after opens five")
ok(WrongCode.opens(0) == 0, "no wrong code opens nothing")

-- sleepers first, then the held, never past the count
local asleep = { 3, 8, 11, 14, 20, 22 }
local held = { 5, 9 }
do
	local roll = roller(7)
	local first = WrongCode.pick(asleep, held, 1, 6, roll)
	ok(#first == 1 and set(asleep)[first[1]], "the first wrong code wakes one sleeper")
	local second = WrongCode.pick(asleep, held, 2, 6, roll)
	ok(#second == 3, "the second picks three")
	for _, u in second do
		ok(set(asleep)[u] == true, "with sleepers to spare, all three are sleepers")
	end
	local distinct = 0
	for _ in set(second) do
		distinct += 1
	end
	ok(distinct == 3, "three different units")
end
do
	-- two sleepers left: both, then the held fill the rest, sleepers rolling first
	local picked = WrongCode.pick({ 4, 6 }, held, 3, 6, roller(3))
	ok(#picked == 4, "two sleepers and two held: four of the five asked for")
	ok(set({ 4, 6 })[picked[1]] and set({ 4, 6 })[picked[2]], "the sleepers roll first")
	ok(set(held)[picked[3]] and set(held)[picked[4]], "then the held")
end
do
	-- the floor's cap on monsters on their feet: only `room` sleepers wake, the held still go
	local picked = WrongCode.pick(asleep, held, 3, 1, roller(11))
	local sleepers, kept = 0, 0
	for _, u in picked do
		if set(asleep)[u] then
			sleepers += 1
		elseif set(held)[u] then
			kept += 1
		end
	end
	ok(sleepers == 1 and kept == 2, `room for one: one sleeper and both held ({sleepers}, {kept})`)
	ok(#WrongCode.pick(asleep, {}, 3, 0, roller(1)) == 0, "no room and none held: nothing opens")
	ok(#WrongCode.pick(asleep, {}, 3, -2, roller(1)) == 0, "over the cap counts as no room")
	ok(#WrongCode.pick({}, {}, 2, 6, roller(1)) == 0, "no monsters shut in: nothing opens")
end
do
	-- the pool given isn't changed
	local pool = { 1, 2, 3 }
	WrongCode.pick(pool, {}, 2, 6, roller(5))
	ok(#pool == 3 and pool[1] == 1 and pool[3] == 3, "the caller's list is left as it was")
end
do
	-- fair: over many floors, each sleeper is the first wrong code's pick about as often
	local counts: { [number]: number } = {}
	local roll = roller(2026)
	local runs = 6000
	for _ = 1, runs do
		local u = WrongCode.pick(asleep, held, 1, 6, roll)[1]
		counts[u] = (counts[u] or 0) + 1
	end
	local each = runs / #asleep
	for _, u in asleep do
		local c = counts[u] or 0
		ok(math.abs(c - each) < each * 0.15, `unit {u} picked {c} times of about {each}`)
	end
end

-- the doors roll one after another, after the alarm has sounded
ok(WrongCode.rollAt(1) == WrongCode.FirstAfter, "the first door waits for the alarm")
ok(WrongCode.FirstAfter >= 0.5, "the buzz and the bell come before any door")
ok(WrongCode.rollAt(2) - WrongCode.rollAt(1) == WrongCode.Between, "then a door a beat apart")
ok(WrongCode.rollAt(5) < 5, "even five have all started rolling within a few seconds")

print(`wrongcode: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
