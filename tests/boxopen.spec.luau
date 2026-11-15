--!strict
-- lune run tests/boxopen.spec
-- Opening a marked box (B-02a): the server's checks on a press, the rate, each screen's clock
-- from the server's stamp, the sounds' beats played once and never stale, the motion's pose from
-- its first frame to settled, and the hum going as the tape tears.
local Opening = require("../src/shared/Boxes/Opening")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

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

-- The generated Specs build Vector3s, which Lune lacks as a global: load them with Lune's own.
local Specs = (luau.load(fs.readFile("src/shared/Boxes/Specs.luau"), {
	environment = { Vector3 = roblox.Vector3, Color3 = roblox.Color3 },
}) :: any)() -- any: a generated table, read field by field below
local Open = Specs.Marked.Motions.Open

-- The checks on a press: a second press does nothing, then the living, the wrapped, the far and
-- the shut door, in that order; nil lets it open.
local good: Opening.Check =
	{ opened = false, alive = true, wrapped = false, distance = 3, apart = false }
local function with(change: { [string]: any }): Opening.Check
	local c = table.clone(good) :: any
	for k, v in change do
		c[k] = v
	end
	return c
end
ok(Opening.refuse(good) == nil, "a living player beside a shut box opens it")
ok(Opening.refuse(with({ opened = true })) == "opened", "an opened box opens once only")
ok(
	Opening.refuse(with({ opened = true, alive = false, wrapped = true, apart = true })) == "opened",
	"an opened box says so before anything else"
)
ok(Opening.refuse(with({ alive = false })) == "dead", "nobody opens a box dead")
ok(Opening.refuse(with({ wrapped = true })) == "wrapped", "a wrapped player has no hands")
ok(Opening.refuse(with({ apart = true })) == "door", "never through a shut door")
ok(
	Opening.refuse(with({ distance = Opening.Reach + Opening.Slack })) == nil,
	"the slack past the button's reach is let in (lag)"
)
ok(
	Opening.refuse(with({ distance = Opening.Reach + Opening.Slack + 0.01 })) == "far",
	"further than the reach and its slack is refused"
)

-- The rate: a few quick presses go through, a script hammering is stopped, time refills it.
do
	local last: number? = nil
	local burst = 0
	local let = 0
	for i = 0, 99 do
		local now = i * 0.01 -- a hundred presses in a second
		local may, left = Opening.allow(last, burst, now)
		if may then
			let += 1
			last, burst = now, left
		end
	end
	ok(let >= Opening.Burst, "a quick burst of presses goes through")
	ok(let <= Opening.Burst + Opening.Rate, `a hammering script is held to the rate ({let})`)
	local may = Opening.allow(last, burst, (last :: number) + 1)
	ok(may, "a second later a press goes through again")
end

-- The clock: a stamp arriving fresh plays from its first frame where it lands (the opener sees
-- the whole tear); one seen late (streamed in, joined) catches up to the server's.
ok(near(Opening.clock(100, 100.15), 100.15), "a fresh stamp starts where it lands")
ok(
	near(Opening.clock(100, 100 + Opening.Fresh + 0.01), 100),
	"a late stamp runs from the server's time"
)
ok(near(Opening.clock(100.05, 100), 100), "a stamp ahead of this clock starts where it lands")

-- The beats: each sound once, in order, across frames; a beat this screen saw too late is
-- skipped rather than played out of step.
do
	local heard: { string } = {}
	local t = 0
	while t < Open.Duration + 0.5 do
		local next = t + 1 / 60
		for _, name in Opening.due(t, next) do
			table.insert(heard, name)
		end
		t = next
	end
	ok(#heard == 2 and heard[1] == "Tear" and heard[2] == "Flaps", "tear, then flaps, once each")
	local jumped = Opening.due(0, Opening.Beats.Flaps + 0.05)
	ok(#jumped == 2 and jumped[1] == "Tear", "a slow frame across both plays both, in order")
	ok(#Opening.due(0, 3) == 0, "a box seen long after it opened plays no sound")
	ok(#Opening.due(-0.2, 0) == 0, "nothing before the open")
end

-- The pose: shut at its first frame, the final keys once settled, the seam gone by the tear.
do
	local pose: { [string]: number } = {}
	Opening.pose(Open, 0, pose)
	local shut = true
	for _, track in Open.Tracks do
		local want = if track.Channel == "scale" then 1 else 0
		shut = shut and near(pose[track.Part], want)
	end
	ok(shut, "the first frame is the box as it stood")
	Opening.pose(Open, Open.Duration + 1, pose)
	local settled = true
	for _, track in Open.Tracks do
		settled = settled and near(pose[track.Part], track.Keys[#track.Keys][2])
	end
	ok(settled, "once over, every part rests on its last key")
	ok(not Opening.settled(Open, Open.Duration - 0.01), "still moving before its end")
	ok(Opening.settled(Open, Open.Duration), "settled at its end")
	Opening.pose(Open, Opening.Beats.Tear, pose)
	ok(near(pose.Marked_Seam, 1), "the seam still glows at the tear's first instant")
	Opening.pose(Open, Opening.Beats.Tear + 0.05, pose)
	ok(pose.Marked_Seam <= 0.01, "the seam's lines are gone just after the tear")
	Opening.pose(Open, Opening.Beats.Flaps, pose)
	ok(pose.Marked_FlapFront > 60, "the flaps are bursting as their slap plays")
end

-- The hum: whole while shut, gone soon after the tear, never coming back.
ok(Opening.hum(0) == 1 and Opening.hum(Opening.Beats.Tear) == 1, "the hum is whole till the tear")
ok(Opening.hum(Opening.Beats.Tear + Opening.HumFade) == 0, "the hum is gone after its fade")
ok(Opening.hum(5) == 0, "and stays gone")
local mid = Opening.hum(Opening.Beats.Tear + Opening.HumFade / 2)
ok(mid > 0 and mid < 1, "it fades rather than cuts")

-- The seam shrinking never reaches zero (a part's size can't).
ok(Opening.thin(0.274, 0.01) >= Opening.Thinnest, "a shrunk line keeps a size")
ok(near(Opening.thin(0.274, 1), 0.274), "a whole line keeps its size")
ok(Opening.thin(0, 1) >= Opening.Thinnest, "a flat axis keeps a size")

print(`boxopen: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
