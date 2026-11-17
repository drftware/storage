--!strict
-- lune run tests/drive.spec
-- Driving the RC car (F-G1b3c2c, Finds/Drive): the stick drives it flat out on a diagonal and
-- turns it from a sideways push alone; the car is the drive's body and what rides on it, never
-- the transmitter; the wheels point the way it turns, either way it rolls; the whine rises with
-- speed; a bump jolts, a nudge doesn't; and it's taken back only from close by.
local Fixture = require("./fixtures/finds")
local Drive = require("../src/shared/Finds/Drive")

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

-- the stick
do
	local t, s = Drive.controls(0, 0)
	ok(t == 0 and s == 0, "a stick at rest asks for nothing")
	t, s = Drive.controls(0, -1)
	ok(near(t, 1) and near(s, 0), "forward is full throttle")
	t, s = Drive.controls(0, 1)
	ok(near(t, -1) and near(s, 0), "back is full reverse")
	local d = math.sqrt(0.5)
	t, s = Drive.controls(d, -d)
	ok(near(t, 1) and near(s, 1), "W and D together: flat out and full right")
	t, s = Drive.controls(-1, 0)
	ok(near(t, Drive.SideThrottle) and near(s, -1), "a push left alone turns it left, rolling")
	t, s = Drive.controls(-d, d)
	ok(near(t, -1) and near(s, -1), "backing and left: no throttle mixed in")
	t, s = Drive.controls(0.2, -0.1)
	ok(t > 0 and t <= 1 and s > 0 and s <= 1, "a light push stays light")
	t, s = Drive.controls(5, -5)
	ok(t <= 1 and s <= 1, "past full counts as full")
end

-- the car's parts
do
	local find = Fixture.kit[Drive.Key]
	ok(find ~= nil and find.Drive ~= nil, "the RC car has a drive")
	local parts = Drive.carParts(find)
	local has: { [string]: boolean } = {}
	for _, name in parts do
		has[name] = true
	end
	ok(has[find.Drive.Body] == true, "the car has its body")
	ok(has[find.Drive.Sprung] == true, "the car has what rides its springs")
	for _, wheel in find.Drive.Wheels do
		ok(has[wheel.Part] == true, `the car has {wheel.Part}`)
		if wheel.Steer then
			ok(has[wheel.Steer] == true, `the car has {wheel.Steer}`)
		end
	end
	ok(has[find.Parts[1].Name] == nil, "the transmitter stays in your hand")
	for _, part in find.Parts do
		if not has[part.Name] then
			ok(
				string.find(part.Name, "Remote", 1, true) ~= nil
					or string.find(part.Name, "Trigger", 1, true) ~= nil,
				`{part.Name} is the transmitter's`
			)
		end
	end
	ok(#Drive.carParts({ Parts = { { Name = "A" } } }) == 0, "a find with no drive has no car")
end

-- the wheels
do
	ok(Drive.steerFrom(0, 2, 1, 26) == 0, "standing still, the wheels point ahead")
	local right = Drive.steerFrom(10, 2, 1, 26)
	ok(right > 0 and right <= 26, "turning right ahead, the wheels point right")
	ok(near(Drive.steerFrom(-10, 2, 1, 26), -right), "rolling back, the wheels point the other way")
	ok(Drive.steerFrom(1, 50, 1, 26) == 26, "never past full lock")
	ok(near(Drive.spin(2 * math.pi * 0.5, 0.5), 360), "a wheel turns once a circumference")
end

-- the whine
do
	local idle, quiet = Drive.whine(0)
	local top, loud = Drive.whine(Drive.Handling.top)
	ok(near(idle, Drive.IdlePitch) and near(quiet, Drive.IdleVolume), "a low hum standing still")
	ok(near(top, Drive.TopPitch) and near(loud, 1), "a high whine flat out")
	local mid = Drive.whine(Drive.Handling.top / 2)
	ok(mid > idle and mid < top, "rising with speed")
	ok(
		near((Drive.whine(-Drive.Handling.reverse)), (Drive.whine(Drive.Handling.reverse))),
		"the same backing up"
	)
	ok(near((Drive.whine(1000)), top), "never past the top's pitch")
end

-- the jolt and the take back
do
	ok(Drive.jolt(1) == nil, "a nudge doesn't jolt")
	local j = Drive.jolt(Drive.Handling.top)
	ok(j ~= nil and j > 0 and j <= Drive.JoltMost, "a wall hit flat out jolts")
	ok(Drive.jolt(1e6) == Drive.JoltMost, "never past the most")
	ok(Drive.takes(1, 0, 1), "at your feet, it's yours")
	ok(not Drive.takes(Drive.TakeReach + 0.1, 0, 0), "a step away, it isn't")
	ok(not Drive.takes(0, Drive.TakeHeight + 1, 0), "nor a floor up")
end

-- driving it home to your feet (F-G1b3c2d)
do
	ok(Drive.HomeAway > Drive.TakeReach, "it has to leave your reach to come home")
	ok(Drive.SetAhead < Drive.TakeReach, "set down, it starts inside your reach")
	local away, home = Drive.home(false, Drive.SetAhead, -3, 0)
	ok(not away and not home, "just set down: not home, so the drive starts")
	away, home = Drive.home(false, Drive.TakeReach + 0.5, -3, 0)
	ok(not away and not home, "a nudge out of reach isn't away")
	away, home = Drive.home(away, 1, -3, 0)
	ok(not home, "nor is coming back from it home")
	away, home = Drive.home(false, Drive.HomeAway + 1, -3, 0)
	ok(away and not home, "driven off down the hall")
	away, home = Drive.home(away, 4, -3, 0)
	ok(away and not home, "on its way back, not yet at your feet")
	away, home = Drive.home(away, 1, -3, 1)
	ok(away and home, "driven to your feet: home")
	away, home = Drive.home(true, 1, -3 - Drive.TakeHeight, 0)
	ok(not home, "under you a floor down isn't home")
	away = Drive.home(false, 0, Drive.TakeHeight + 1, 0)
	ok(away, "a floor away counts as away")
end

-- the crouch keeps the feet on the floor
do
	local c = Drive.Crouch
	local foot = c.Lean + c.Hip + c.Knee + c.Ankle
	ok(math.abs(foot) < math.rad(1), "the feet stay flat under the crouch")
	ok(c.Down > 0 and c.Sink > 0 and c.Sink < 0.6, "crouched, not sat on the floor")
end

-- taken (F-G1b3c3): the view rises and tips in the hands, then solid snow, then home and clear
do
	local up0, pitch0, roll0, see0, home0 = Drive.lifted(0)
	ok(up0 == 0 and pitch0 == 0 and roll0 == 0, "it starts where the hood view was")
	ok(see0 == 1 and not home0, "no snow yet as the hands close")
	local half = Drive.lifted(Drive.LiftTime / 2)
	ok(half > Drive.LiftUp / 2, "snatched up: more than half way in half the time")
	local up, pitch, roll, see, home = Drive.lifted(Drive.LiftTime - 1e-3)
	ok(math.abs(up - Drive.LiftUp) < 0.05, "at the chest as the snow cuts in")
	ok(pitch > 0 and roll > 0 and see == 1 and not home, "tipped and turned, still the hall")
	_, _, _, see, home = Drive.lifted(Drive.LiftTime + 0.01)
	ok(see == 0 and not home, "a dead channel's snow, solid")
	local back = Drive.LiftTime + Drive.TakenSnow
	_, _, _, see, home = Drive.lifted(back + 0.001)
	ok(home and see < 0.1, "your own eyes behind the snow as it starts to clear")
	_, _, _, see, home = Drive.lifted(back + Drive.SnowClear)
	ok(home and see == 1, "clear")
	ok(Drive.TakenEnds == back + Drive.SnowClear, "it's over once clear")
end

-- the handling's numbers make sense together
do
	local h = Drive.Handling
	ok(h.top > 16, "quicker than you run")
	ok(h.reverse < h.top and h.brake < h.coast, "backs slower, brakes quicker than it coasts")
	ok(Drive.CheckSlack > 1, "the server's check leaves room for lag")
end

if failures > 0 then
	error(`drive: {failures} of {checks} checks failed`)
end
print(`drive: {checks} checks passed`)
