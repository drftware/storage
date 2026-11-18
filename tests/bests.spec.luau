--!strict
-- lune run tests/bests.spec
-- The best floors the lobby shows (S6-01b): the dial reads the best of those aboard (none until
-- someone has climbed); the plaque lists them best first, ties in boarding order; a best that
-- rose and hasn't been shown flips up from what the car's best was; the digits pass through at
-- most a handful of numbers, slowing as they settle; the dial takes turns with Full or Friends
-- only.
local Bests = require("../src/shared/Lobby/Bests")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local function list(xs: { number }): string
	local out = {}
	for _, x in xs do
		table.insert(out, tostring(x))
	end
	return table.concat(out, ",")
end

-- top: the best of those aboard
ok(Bests.top({}, {}) == nil, "nobody aboard: no best")
ok(Bests.top({ 1, 2 }, {}) == nil, "nobody's save loaded yet: no best")
ok(Bests.top({ 1, 2 }, { [1] = 0, [2] = 0 }) == nil, "nobody has climbed: no best")
ok(Bests.top({ 1, 2 }, { [1] = 3, [2] = 12 }) == 12, "the higher of two")
ok(Bests.top({ 1 }, { [1] = 3, [2] = 12 }) == 3, "only those aboard count")
ok(Bests.top({ 2, 1 }, { [1] = 7 }) == 7, "one not loaded yet")

-- rows: best first, ties and the unknown in boarding order
do
	local rows = Bests.rows({ 10, 20, 30, 40 }, { [10] = 2, [20] = 9, [40] = 2 })
	local ids, floors = {}, {}
	for _, r in rows do
		table.insert(ids, r.id)
		table.insert(floors, r.floor)
	end
	ok(list(ids) == "20,10,40,30", `rows best first, ties in order (got {list(ids)})`)
	ok(list(floors) == "9,2,2,0", `rows' floors, unknown as 0 (got {list(floors)})`)
	ok(#Bests.rows({}, {}) == 0, "no rows for an empty car")
end

-- risen: what the car's best was before a rise nobody has been shown
do
	local before: Bests.Bests = {}
	ok(Bests.risen({ 1, 2 }, { [1] = 5, [2] = 3 }, before) == nil, "no rise: no flip")
	before[2] = 3
	ok(
		Bests.risen({ 1, 2 }, { [1] = 5, [2] = 4 }, before) == nil,
		"a friend's rise under the car's best: no flip"
	)
	before[2] = 4
	ok(Bests.risen({ 1, 2 }, { [1] = 5, [2] = 8 }, before) == 5, "a rise past the best: from it")
	before[1] = 5
	ok(
		Bests.risen({ 1, 2 }, { [1] = 7, [2] = 8 }, before) == 5,
		"both rose: from the car's old best"
	)
	ok(Bests.risen({ 3 }, { [3] = 2 }, { [3] = 0 }) == 0, "a first climb flips up from 0")
	ok(Bests.risen({}, {}, { [1] = 1 }) == nil, "nobody aboard: no flip")
	Bests.seen({ 1, 3 }, before)
	ok(before[1] == nil and before[2] == 4, "seen clears only those aboard")
end

-- steps: the numbers the digits pass through
ok(list(Bests.steps(2, 3, 8)) == "3", "one up: one step")
ok(list(Bests.steps(2, 6, 8)) == "3,4,5,6", "a few: every one")
do
	local s = Bests.steps(0, 100, 8)
	ok(#s == 8 and s[8] == 100, `a long way: 8 steps ending on it (got {list(s)})`)
	local up = true
	for i = 2, #s do
		up = up and s[i] > s[i - 1]
	end
	ok(up and s[1] > 0, "a long way: always rising")
end
ok(#Bests.steps(5, 5, 8) == 0 and #Bests.steps(6, 5, 8) == 0, "no steps unless it rose")

-- gap: the clacks slow as the digits settle
do
	local first, last = Bests.gap(1, 8), Bests.gap(8, 8)
	ok(
		first == Bests.Roll.First and math.abs(last - Bests.Roll.Last) < 1e-9,
		"gap from first to last"
	)
	ok(Bests.gap(4, 8) > first and Bests.gap(4, 8) < last, "gap between")
	ok(Bests.gap(1, 1) == Bests.Roll.Last, "a single step lands slow")
end

-- turn: the line takes turns with Full or Friends only
do
	local other, best = Bests.Turn.Other, Bests.Turn.Best
	ok(not Bests.turn(0) and not Bests.turn(other - 0.01), "the other line first")
	ok(Bests.turn(other) and Bests.turn(other + best - 0.01), "then the best")
	ok(not Bests.turn(other + best), "and round again")
end

-- shown and without (S6-01c): an empty car shows the crew that last rode it, until they board
-- another car
do
	ok(list(Bests.shown({ 1, 2 }, { 9 })) == "1,2", "those aboard, whoever rode last")
	ok(list(Bests.shown({}, { 3, 4 })) == "3,4", "nobody aboard: the crew that rode last")
	ok(#Bests.shown({}, {}) == 0, "nobody aboard, nobody rode: nobody")
	ok(list(Bests.without({ 1, 2, 3 }, { 2, 7 })) == "1,3", "one boarded another car")
	ok(list(Bests.without({ 1, 2 }, {})) == "1,2", "nobody boarded elsewhere")
	ok(#Bests.without({ 5 }, { 5 }) == 0, "the whole crew boarded elsewhere")
	-- the landing: a rise seen while the crew walks out of the car
	local best, before = { [1] = 3 }, { [1] = 0 }
	local crew = Bests.shown({}, { 1 })
	ok(Bests.risen(crew, best, before) == 0, "the crew's rise still waits to be seen")
	Bests.seen(crew, before)
	ok(Bests.risen(crew, best, before) == nil, "seen once, it doesn't roll again")
end

print(`bests: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
