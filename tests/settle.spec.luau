--!strict
-- lune run tests/settle.spec
-- How the things standing on a piece settle as it lands (S5-03j2b2c, Home/Settle): each stands
-- still until its beat, hops up to `Hop` and back down, bounces once lower, then stands still for
-- good; never sinks into the piece; each starts a beat after the one before; its clink comes as it
-- first comes down; and nothing moves after `length`.
local Settle = require("../src/shared/Home/Settle")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

-- Still until its beat: the first at once, the second a beat later.
do
	ok(Settle.height(0, 1) == 0, "the first stands still at the landing")
	ok(Settle.height(0.01, 1) > 0, "the first is off its piece just after")
	ok(Settle.height(Settle.Beat * 0.9, 2) == 0, "the second waits for its beat")
	ok(Settle.height(Settle.Beat + 0.01, 2) > 0, "the second hops after its beat")
	ok(Settle.height(-1, 1) == 0, "nothing before the landing")
end

-- The hop peaks at `Hop` halfway through its air, for every rider in turn.
do
	for order = 1, 4 do
		local mid = (order - 1) * Settle.Beat + Settle.Air / 2
		ok(near(Settle.height(mid, order), Settle.Hop), "rider " .. order .. " peaks at Hop")
	end
end

-- Never below its piece, and the second bounce lower than the first.
do
	local first, second = 0, 0
	for i = 0, 400 do
		local t = i * 0.002
		local h = Settle.height(t, 1)
		ok(h >= 0, string.format("never sinks at %.3f", t))
		if t < Settle.Air then
			first = math.max(first, h)
		else
			second = math.max(second, h)
		end
	end
	ok(second > 0, "it bounces a second time")
	ok(second < first * 0.5, "the second bounce is well under the first")
end

-- Its clink as it first comes down: back on its piece, a beat after the last one's.
do
	for order = 1, 3 do
		local at = Settle.landsAt(order)
		ok(Settle.height(at, order) < 1e-6, "rider " .. order .. " is down at its clink")
		ok(Settle.height(at - 0.02, order) > 0, "rider " .. order .. " is up just before")
	end
	ok(near(Settle.landsAt(2) - Settle.landsAt(1), Settle.Beat), "clinks a beat apart")
end

-- Still for good after `length`: nothing to step.
do
	ok(Settle.length(0) == 0, "no riders, nothing to wait for")
	for count = 1, 5 do
		local done = Settle.length(count)
		for order = 1, count do
			for i = 0, 20 do
				ok(
					Settle.height(done + i * 0.05, order) == 0,
					"rider " .. order .. " of " .. count .. " still after length"
				)
			end
		end
		ok(
			Settle.height(done - 0.02, count) > 0,
			"the last of " .. count .. " still moving just before"
		)
	end
	ok(near(Settle.length(3) - Settle.length(2), Settle.Beat), "each rider adds a beat")
end

print(string.format("settle: %d checks, %d failed", checks, failures))
if failures > 0 then
	error("settle spec failed")
end
