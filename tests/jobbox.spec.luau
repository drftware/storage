--!strict
-- lune run tests/jobbox.spec
-- The home's job box (S5-03c2a): its lid opens from shut to the lift, eased, never past it; from
-- part-way it takes only the part left; it falls shut, gathering speed, lands at the landing time,
-- kicks up a little and rests at 0; and its hinge sits on the box's back top edge.
local JobBox = require("../src/shared/Home/JobBox")
local Specs = require("../src/shared/Home/Specs")

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

local lid = JobBox.Lid

-- Opening from shut: eased in and out, all the way, never past.
do
	local a0, done0 = JobBox.angle(true, 0, 0)
	ok(near(a0, 0) and not done0, "a lid opening starts shut")
	local mid = JobBox.angle(true, 0, lid.Open / 2)
	ok(near(mid, lid.Lift / 2), "halfway through, it's halfway up")
	local early = JobBox.angle(true, 0, lid.Open * 0.1)
	ok(early < lid.Lift * 0.1, "it starts slow (eased in)")
	local last, done = JobBox.angle(true, 0, lid.Open)
	ok(near(last, lid.Lift) and done, "it rests at the lift")
	local later = JobBox.angle(true, 0, lid.Open * 3)
	ok(near(later, lid.Lift), "and never goes past it")
	local high = 0
	for i = 0, 100 do
		high = math.max(high, (JobBox.angle(true, 0, lid.Open * i / 100)))
	end
	ok(high <= lid.Lift + 1e-9, "no step of the opening passes the lift")
end

-- Opening again from part-way (pressed while it fell): only the part left, as fast as ever.
do
	local from = lid.Lift / 2
	local a, done = JobBox.angle(true, from, lid.Open / 2)
	ok(near(a, lid.Lift) and done, "from halfway up it takes half the time")
	local _, openDone = JobBox.angle(true, lid.Lift, 0)
	ok(openDone, "already up, it's at rest at once")
end

-- Closing: it falls, gathering speed, lands, kicks up a little, and rests shut.
do
	local land = JobBox.landing(lid.Lift)
	ok(near(land, lid.Close), "a full drop takes the close's time")
	ok(JobBox.landing(lid.Lift / 4) < land / 1.9, "a quarter drop lands in about half the time")
	local early = JobBox.angle(false, lid.Lift, land * 0.25)
	ok(early > lid.Lift * 0.9, "it's slow to start falling")
	local atLand = JobBox.angle(false, lid.Lift, land)
	ok(near(atLand, 0), "it's shut as it lands")
	local kick = JobBox.angle(false, lid.Lift, land + lid.Bounce.Seconds / 2)
	ok(near(kick, lid.Bounce.Degrees), "it kicks up its bounce as it lands")
	local rest, done = JobBox.angle(false, lid.Lift, land + lid.Bounce.Seconds + 1e-6)
	ok(near(rest, 0) and done, "then it rests shut")
	local small =
		JobBox.angle(false, lid.Lift / 4, JobBox.landing(lid.Lift / 4) + lid.Bounce.Seconds / 2)
	ok(small < lid.Bounce.Degrees / 2, "a short drop kicks less")
	local _, shutDone = JobBox.angle(false, 0, 0)
	ok(shutDone, "already shut, it's at rest at once")
end

-- The hinge: on the box's back top edge, behind the body and level with the lid's skirt.
do
	local hinge = Specs.JobBox.Hinge
	local body = Specs.Parts.JobBox
	local lidPart = Specs.Parts.JobBoxLid
	ok(near(hinge[1], 0, 1e-3), "the hinge line's middle is the box's middle across")
	ok(hinge[3] >= body.Centre[3] + body.Size[3] / 2, "it's at or behind the body's back")
	ok(
		near(hinge[3], lidPart.Centre[3] + lidPart.Size[3] / 2, 0.01),
		"on the lid's back face, so the lid swings clear of the body"
	)
	ok(
		hinge[2] > lidPart.Centre[2] - lidPart.Size[2] / 2 - 0.01
			and hinge[2] < body.Centre[2] + body.Size[2] / 2,
		"between the lid's foot and the body's top"
	)
end

print(`jobbox: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
