--!strict
-- lune run tests/worldbutton.spec
-- One look for every button in the world (L-19a): its motion as pure numbers.
local WorldButton = require("../src/shared/WorldButton")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- a phone's chip is a thumb's target
ok(WorldButton.TouchChip >= 44, "a phone's chip is at least 44 points")
ok(WorldButton.TouchChip + WorldButton.Hit >= 48, "a tap lands a little round it too")

-- swelling in: from small and clear to whole, past whole a touch on the way (a spring)
do
	local a0, s0 = WorldButton.presence(0, true)
	local a1, s1 = WorldButton.presence(1, true)
	ok(a0 == 0 and near(s0, WorldButton.InScale), "starts clear and small")
	ok(a1 == 1 and near(s1, 1), "ends whole")
	local over = false
	for i = 1, 19 do
		local _, s = WorldButton.presence(i / 20, true)
		if s > 1 then
			over = true
		end
	end
	ok(over, "springs past whole on the way in")
	local ag, sg = WorldButton.presence(0, false)
	ok(ag == 0 and near(sg, WorldButton.OutScale), "goes clear, shrinking a touch")
	local _, sl = WorldButton.presence(2, true)
	ok(near(sl, 1), "levels past 1 hold whole")
end

-- a press: squashed at once, a flash, back to whole
do
	local s0, f0 = WorldButton.pop(0)
	ok(near(s0, WorldButton.PopScale) and near(f0, 1), "a press squashes and flashes")
	local s1, f1 = WorldButton.pop(WorldButton.Pop)
	ok(s1 == 1 and f1 == 0, "over after its time")
	local sn, fn = WorldButton.pop(-0.1)
	ok(sn == 1 and fn == 0, "nothing before it")
end

-- a refusal's shake: swings both ways, biggest early, still at the end
do
	local most, left, right = 0, false, false
	for i = 0, 100 do
		local x = WorldButton.shake(WorldButton.Shake * i / 100)
		most = math.max(most, math.abs(x))
		if x < -0.5 then
			left = true
		elseif x > 0.5 then
			right = true
		end
	end
	ok(left and right, "swings both ways")
	ok(most <= WorldButton.ShakePoints, "never past its first swing")
	ok(
		WorldButton.shake(WorldButton.Shake) == 0 and WorldButton.shake(0) == 0,
		"starts and ends still"
	)
	ok(
		math.abs(WorldButton.shake(WorldButton.Shake * 0.07))
			> math.abs(WorldButton.shake(WorldButton.Shake * 0.79)),
		"dies away"
	)
end

-- a refusal's red: the words for a beat, then the verb back, the red easing out
do
	local r0, words0 = WorldButton.red(0)
	ok(r0 == 1 and words0, "red words at once")
	local r1, words1 = WorldButton.red(WorldButton.Refusal - 0.01)
	ok(r1 == 1 and words1, "held for the beat")
	local r2, words2 = WorldButton.red(WorldButton.Refusal + WorldButton.Calm / 2)
	ok(near(r2, 0.5) and not words2, "the verb back, easing out of red")
	local r3 = WorldButton.red(WorldButton.Refusal + WorldButton.Calm + 1)
	ok(r3 == 0, "its own colour after")
	ok(
		WorldButton.refusing(0) and not WorldButton.refusing(WorldButton.Refusal + WorldButton.Calm),
		"moving only while it shows"
	)
	ok(WorldButton.Shake < WorldButton.Refusal, "the shake is over before the words go")
end

-- the hold ring: empty, half (the right half whole), full
do
	local l0, r0 = WorldButton.halves(0)
	ok(l0 == 180 and r0 == 0, "empty")
	local lh, rh = WorldButton.halves(0.5)
	ok(lh == 180 and rh == 180, "half: the right half whole, the left empty")
	local l1, r1 = WorldButton.halves(1)
	ok(l1 == 360 and r1 == 180, "full")
	local lq, rq = WorldButton.halves(0.25)
	ok(lq == 180 and rq == 90, "a quarter: to three o'clock")
	ok(WorldButton.holding(0.5, 1) == 0.5 and WorldButton.holding(2, 1) == 1, "fills over the hold")
	ok(WorldButton.holding(0.1, 0) == 1, "a tap is full at once")
	ok(
		WorldButton.draining(0.8, 0) == 0.8 and WorldButton.draining(0.8, WorldButton.Drain) == 0,
		"a let-go hold empties"
	)
end

-- words from the wire
do
	ok(WorldButton.words("Padlocked") == "Padlocked", "a refusal draws as sent")
	ok(
		WorldButton.words(5) == nil
			and WorldButton.words("") == nil
			and WorldButton.words(nil) == nil,
		"nothing else draws"
	)
	local long = WorldButton.words(string.rep("a", 200))
	ok(long ~= nil and #long == WorldButton.MaxWords, "long words cut")
end

print(`worldbutton: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
