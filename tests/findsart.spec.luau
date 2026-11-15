--!strict
-- lune run tests/findsart.spec
-- How a find's motion plays (Finds/Art, the same sums as art/finds/kit/ease.py): every easing
-- starts at 0 and ends at 1; Back overshoots and the rest never do; a track holds its first value
-- before it starts and its last after it ends, passes through every key, and eases between them
-- the way the key says (the tea light's flame: lit from nothing, then a wobble that settles).
local Art = require("../src/shared/Finds/Art")

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
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local STYLES = { "Linear", "Sine", "Quad", "Cubic", "Quart", "Back" }
local DIRECTIONS = { "In", "Out", "InOut" }

do -- the ends, and overshoot only for Back
	for _, s in STYLES do
		for _, d in DIRECTIONS do
			ok(near(Art.ease(s, d, 0), 0), `{s} {d} starts at 0`)
			ok(near(Art.ease(s, d, 1), 1), `{s} {d} ends at 1`)
			ok(near(Art.ease(s, d, -1), 0) and near(Art.ease(s, d, 2), 1), `{s} {d} clamps`)
			local over = false
			for i = 1, 99 do
				local v = Art.ease(s, d, i / 100)
				if v > 1 + 1e-9 or v < -1e-9 then
					over = true
				end
			end
			ok(over == (s == "Back"), `{s} {d} overshoots only if Back`)
		end
	end
	ok(near(Art.ease("Linear", "In", 0.25), 0.25), "Linear is straight")
	ok(near(Art.ease("Sine", "InOut", 0.5), 0.5), "InOut is halfway at half time")
	ok(
		Art.ease("Quad", "In", 0.5) < 0.5 and Art.ease("Quad", "Out", 0.5) > 0.5,
		"In starts slow, Out fast"
	)
end

do -- a track: the flame lit from nothing, climbing too tall, then settling
	local keys: { Art.Key } = {
		{ 0, 0, "Sine", "InOut" },
		{ 0.06, 0.32, "Quad", "Out" },
		{ 0.18, 0.24, "Sine", "InOut" },
		{ 0.5, 1, "Quad", "Out" },
	}
	ok(Art.sample(keys, -1) == 0, "before it starts: the first value")
	ok(Art.sample(keys, 9) == 1, "after it ends: the last value")
	for _, k in keys do
		ok(near(Art.sample(keys, k[1]), k[2]), `passes through the key at {k[1]}`)
	end
	local mid = Art.sample(keys, 0.34)
	ok(mid > 0.24 and mid < 1, "between keys: between their values")
	ok(Art.sample(keys, 0.34) > 0.24 + (1 - 0.24) / 2, "Quad Out: past halfway at half time")
	ok(Art.sample({ { 0, 5, "Linear", "In" } }, 3) == 5, "one key holds")
end

print(`findsart: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} findsart checks failed`)
end
