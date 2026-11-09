--!strict
-- lune run tests/crawling.spec
-- Crawling through a sawn hole (L-12b3): who may start, the path through the hole, the view, the
-- arms and the sounds, every step of the way.
local fs = require("@lune/fs")
local Crawling = require("../src/shared/StorageUnit/CrawlHole/Crawling")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end
local function near(a: number, b: number, by: number?): boolean
	return math.abs(a - b) < (by or 1e-6)
end

-- who may start
ok(Crawling.decide(false, false).ok, "free hole, not crawling: go")
ok(not Crawling.decide(true, false).ok, "already crawling: no")
ok(Crawling.decide(true, false).refusal == nil, "already crawling: refused silently")
ok(not Crawling.decide(false, true).ok, "someone in the hole: no")
ok(Crawling.decide(false, true).refusal == "Wait for them", "someone in the hole: wait for them")

-- about a second, as the ticket's moment wants
ok(Crawling.Seconds >= 1 and Crawling.Seconds <= 1.6, "the move takes about a second")
ok(Crawling.EndSlack > 0.3, "the server waits past the move for the screen")

-- The generated Specs build Vector3s, which Lune hasn't: read the numbers from the text.
local function number(path: string, key: string): number
	local text = fs.readFile(path)
	local v = string.match(text, "\n%s*" .. key .. " = (%-?[%d%.]+)")
	assert(v, `{key} not in {path}`)
	return tonumber(v) :: number
end
local HOLE = "src/shared/StorageUnit/CrawlHole/Specs.luau"

-- the path
local STAND = 3 -- R15's root standing: HipHeight 2 plus half its 2-stud height
local wallHalf = 0.1 -- the wall is 0.2 thick
local lip, top = number(HOLE, "Bottom"), number(HOLE, "Top")
ok(
	Crawling.StartAlong + Crawling.HeadPast < -wallHalf,
	"lying down, your head starts short of the wall"
)
ok(Crawling.EndAlong - Crawling.FeetPast > wallHalf, "your feet are through before you stand")
ok(Crawling.ProneUp - 0.5 >= lip - 0.05, "your belly rides at the hole's lip")
ok(Crawling.ProneUp + 0.5 <= top - 0.5, "your back clears the hole's top")
local headLying = Crawling.ProneUp + 0.6
ok(
	headLying + Crawling.EyeLift + Crawling.Bob < top - 0.3,
	"your raised head clears the hole's top"
)
-- both units fit the body, even the small one: lying before the wall, standing after it
local inside = number("src/shared/StorageUnit/Specs/S.luau", "Width") - wallHalf * 2
ok(
	-Crawling.StartAlong + Crawling.FeetPast < inside,
	"a small unit fits you lying down before the hole"
)
ok(Crawling.StandAlong + 0.5 < inside, "a small unit fits you standing up past it")
ok(Crawling.EndAlong + Crawling.HeadPast < inside, "a small unit fits your head lying past it")

-- every frame of the move, in steps of a hundredth of a second
local lastAlong = -math.huge
local forward, inHole, smoothAll = true, true, true
local lastA, lastU, lastP = nil :: number?, nil :: number?, nil :: number?
local t = 0
while t <= Crawling.Seconds + 0.05 do
	local along, up, pitch, blend = Crawling.pose(t, STAND)
	if blend >= 1 then
		if along < lastAlong - 1e-9 then
			forward = false
		end
		lastAlong = along
	end
	-- while any of you is in the wall's plane, you're lying flat at the hole's height
	local head, feet = along + Crawling.HeadPast, along - Crawling.FeetPast
	if blend >= 1 and head > -wallHalf and feet < wallHalf then
		if not (near(pitch, math.pi / 2) and near(up, Crawling.ProneUp)) then
			inHole = false
		end
	end
	if lastA and lastU and lastP and blend >= 1 then
		-- no jumps: a hundredth of a second never moves you more than half a stud
		if
			math.abs(along - lastA) > 0.5
			or math.abs(up - lastU) > 0.5
			or math.abs(pitch - lastP) > 0.3
		then
			smoothAll = false
		end
	end
	lastA, lastU, lastP = along, up, pitch
	t += 0.01
end
ok(forward, "the move only ever goes forward")
ok(inHole, "anywhere in the wall's plane you're flat at the hole's height")
ok(smoothAll, "no jumps in the move")

do
	local along, up, pitch, blend = Crawling.pose(0, STAND)
	ok(blend == 0, "at the press you're where you stood")
	ok(
		near(along, Crawling.StartAlong) and near(pitch, math.pi / 2),
		"heading for the hole's mouth"
	)
	ok(up == Crawling.ProneUp, "on your belly")
	local _, _, _, b2 = Crawling.pose(Crawling.Drop, STAND)
	ok(b2 == 1, "down at the hole once the drop is done")
	local a3, u3, p3 = Crawling.pose(Crawling.Seconds, STAND)
	ok(near(a3, Crawling.StandAlong) and near(u3, STAND) and near(p3, 0), "standing at the end")
	local a4, u4, p4 = Crawling.pose(Crawling.Seconds + 5, STAND)
	ok(near(a4, Crawling.StandAlong) and near(u4, STAND) and near(p4, 0), "and staying stood")
end

-- the pulls
ok(near(Crawling.progress(0), 0) and near(Crawling.progress(1), 1), "the pulls start and finish")
ok(near(Crawling.progress(-1), 0) and near(Crawling.progress(2), 1), "clamped outside the pulling")
local mid = Crawling.progress(0.25) - Crawling.progress(0.2)
local edge = Crawling.progress(0.05) - Crawling.progress(0)
ok(mid > edge * 2, "each pull surges in its middle")
local i1, f1 = Crawling.pull(Crawling.Drop + 0.01)
local i2 = Crawling.pull(Crawling.Drop + Crawling.Through * 0.75)
ok(i1 == 1 and f1 < 0.1, "the first pull starts as you land")
ok(i2 == 2, "then the second")
ok((Crawling.pull(0.1)) == 0, "no pull while dropping")
ok((Crawling.pull(Crawling.Seconds)) == 0, "no pull while rising")

-- reaching a point
for _, along in { -2, -1.5, 0, 1, 2.5 } do
	local at = Crawling.reaches(along)
	local got = Crawling.pose(at, STAND)
	ok(near(got, along, 1e-3), `reaches {along} at the right moment`)
end

-- the view
do
	local look0, bob0, roll0, lift0 = Crawling.view(0)
	ok(look0 == 0 and bob0 == 0 and roll0 == 0 and lift0 == 0, "the view starts as yours")
	local look1 = Crawling.view(Crawling.Drop * 0.99)
	ok(look1 < Crawling.LookThrough, "looking down at the hole as you drop")
	local _, bob2, roll2 = Crawling.view(Crawling.Drop + Crawling.Through * 0.25)
	local _, _, roll3 = Crawling.view(Crawling.Drop + Crawling.Through * 0.75)
	ok(bob2 > 0, "your head dips with a pull")
	ok(roll2 * roll3 < 0, "your view rocks one way, then the other")
	local look4, bob4, roll4, lift4 = Crawling.view(Crawling.Seconds)
	ok(look4 == 0 and bob4 == 0 and roll4 == 0 and lift4 == 0, "and ends level, as yours again")
end

-- the arms
do
	local _, _, w0 = Crawling.arms(0)
	ok(w0 == 0, "arms start as they were")
	local r1, l1, w1 = Crawling.arms(Crawling.Drop + Crawling.Through * 0.25)
	ok(w1 == 1 and r1 < l1, "the right arm hauls first")
	local r2, l2 = Crawling.arms(Crawling.Drop + Crawling.Through * 0.75)
	ok(l2 < r2, "then the left")
	local _, _, w3 = Crawling.arms(Crawling.Seconds)
	ok(w3 == 0, "arms back to themselves standing")
end

-- the sounds
do
	local cues = Crawling.cues()
	ok(#cues == 2 + Crawling.Pulls, "a thud, the steel, a drag per pull")
	local sorted = true
	for i, c in cues do
		if i > 1 and c.at < cues[i - 1].at then
			sorted = false
		end
		ok(c.at >= 0 and c.at < Crawling.Seconds, `cue {i} plays during the move`)
		ok(c.sound.length > 0 and c.sound.reach >= c.sound.near, `cue {i} is a real stretch`)
	end
	ok(sorted, "cues in order")
	local steel = 0
	for _, c in cues do
		if c.sound == Crawling.Sounds.Steel then
			steel = c.at
		end
	end
	ok(
		steel > Crawling.Drop and steel < Crawling.Drop + Crawling.Through,
		"the steel while you pull"
	)
	ok(
		steel + Crawling.Sounds.Steel.length / Crawling.Sounds.Steel.pitch <= Crawling.Seconds,
		"the steel done before you stand"
	)
end

if failures > 0 then
	error(`crawling: {failures} of {checks} checks failed`)
end
print(`crawling: {checks} checks passed`)
