--!strict
--[[
	Drive: driving the RC car (F-G1b3c2c, D-252), the numbers and sums the server and every screen
	share. Pure: nothing here touches Roblox.

	Drive (the find's one word) sets the car down in front of you and your view drops to its hood,
	low and wide; the transmitter stays in your hands. The move stick drives it through Brix's
	Handling and Driving (Rainbow Six Siege's drones): the driver's own device moves it, so it
	answers at once, walls and shut doors stop it as they stop you, and the server checks every
	move. Back (the jump button, as Roblox's own vehicle seats are left, or the Back button) brings
	you back to your own eyes, and the car stays where it is. Walk to it with the transmitter in
	your hand and it's back in your hands. Drive again and you're back on its hood, wherever it is.

	Here: the names on the models, the handling's feel numbers, the check's slack, the hood
	camera, the whine, how the stick maps to throttle and steering (`controls`), which of the
	find's parts are the car (`carParts`), and the sums for the wheels, the whine and the take
	back.
]]

local Art = require("./Art")

local Drive = {}

Drive.Key = "RCCar" -- the find's catalog key
Drive.Verb = "Drive" -- the press's one word

-- Names. The car out on the floor is its own model, tagged; while someone drives it, its
-- `Driver` is their UserId. Its `PutBack` is the server clock of the last move the server took
-- back (a jolt on the driver's screen). The find (the transmitter's model) says `CarOut` while
-- its car is out, so every screen leaves the car off the transmitter in its hand.
Drive.Tag = "DrivenCar"
Drive.DriverAttribute = "Driver"
Drive.PutBackAttribute = "PutBack"
Drive.OutAttribute = "CarOut"
Drive.CarName = "RCCarOut" -- the car's model out on the floor
Drive.HullName = "RCCar_Hull" -- the invisible box it slides on and bumps walls with
Drive.RemoteFolder = "Driving"
Drive.BackRemote = "DriveBack" -- the driver's client: take me back to my own eyes

--[[
	The handling (Brix's `Handling.car`), what each number does to the player. It leaps off: from
	standing to flat out in half a second, quicker than you run, so a scout down a hall and back
	is quick, and slow enough to steer between unit doors. It can't turn standing still, as a car
	can't (`SideThrottle` below lets a phone's sideways push still turn it).
]]
Drive.Handling = {
	top = 18, -- studs a second flat out: a little quicker than you run (16)
	reverse = 7, -- backing up, slower, as a toy car's gearing is
	speedUp = 0.5, -- seconds from standing to flat out: it leaps off at once
	coast = 0.8, -- seconds from flat out to a stop, let go: it rolls on a moment
	brake = 0.3, -- seconds from flat out to a stop, pushed back: it stops short at a door
	turnRadius = 2.2, -- studs: round a corner in about two of its own lengths
	fastestTurn = 3.2, -- radians a second at most: flat out it sweeps a wide arc, not a spin
	steerTime = 0.15, -- seconds from straight to full lock: quick, never a twitch
}

-- How much faster than its top the server lets it move before it's put back (lag and a bump's
-- shove, never a cheat's speed); how far it may fall a second; how long a burst of moves sent at
-- once is forgiven (Brix's `MoveCheck.ground`).
Drive.CheckSlack = 1.25
Drive.CheckFall = 80
Drive.CheckBunch = 0.5

-- A sideways push with nothing forward still turns it: this share of the push goes in as
-- throttle (E-079), so a phone thumb pushed left from rest pulls it round to the left.
Drive.SideThrottle = 0.35

-- Studs ahead of your middle the car is set down, facing where you face: past your toes.
Drive.SetAhead = 2.4

-- The hull: an invisible box from the floor up to the chassis's top, as wide as the rear wheels
-- and as long as the shell, so it stops flush at a wall with no wheel or nose through it. It
-- slides on the floor with no friction; the handling alone moves and stops it.
Drive.HullWidth = 1.0
Drive.HullHeight = 0.42
Drive.HullLength = 1.48

-- The hood camera, in the car's frame (its front is -Z): just above the hood, low and wide, the
-- floor rushing under it. `HoodDown` tilts it a little to the floor ahead; `Fov` is wide for
-- speed. `Drop` is the seconds your view takes to swoop from your eyes down to the hood.
Drive.HoodUp = 0.52
Drive.HoodAhead = -0.28
Drive.HoodDown = 4 -- degrees
Drive.Fov = 88
Drive.Drop = 0.35
-- How fast the view settles on the car's pitch and roll (per second): a bump jolts it, a ramp
-- tilts it, never a shiver.
Drive.Settle = 18

-- A jolt on a bump: the car's speed lost (or its fall stopped) in one frame, beyond this many
-- studs a second, kicks your view by `Jolt` per stud a second, up to `JoltMost`. Put back by the
-- server, a big one.
Drive.BumpAt = 4
Drive.Jolt = 0.05
Drive.JoltMost = 0.9
Drive.PutBackJolt = 1
-- A put back stamped longer ago than this is old news: no jolt.
Drive.Fresh = 1

-- The whine (Pro Sound Effects' "Servo Long Slow Bursts Whir Mostly Constant 2", its steady
-- middle looped): pitch and volume rising with speed, from a low idle hum while you drive
-- standing still to a high whine flat out. Heard as far as `Reach`.
Drive.Whine = {
	id = "rbxassetid://9125924630",
	from = 2.4,
	length = 2.5,
	volume = 0.5,
	pitch = 1, -- its own pitch; the whine's speed sets it as it plays
}
Drive.IdlePitch = 0.7
Drive.TopPitch = 1.6
Drive.IdleVolume = 0.25 -- of the whine's volume, at a standstill
Drive.Reach = 60
-- How fast the pitch follows the speed (per second): it rises as it leaps off.
Drive.PitchRate = 10

-- Take it back: walk to it with its transmitter in your hand. Studs from your feet to the car
-- along the floor, and up or down.
Drive.TakeReach = 3
Drive.TakeHeight = 4
-- Or drive it home to your feet (F-G1b3c2d): once it has been this many studs from your feet
-- since the drive began, coming back within `TakeReach` takes it back. It's set down closer than
-- that, so it doesn't snap straight back into your hands as you start.
Drive.HomeAway = 4.5

--[[
	The driver's body (F-G1b3c2d): while you drive, every screen, yours included, crouches your
	body over the transmitter, as a drone pilot squats over their controller in Rainbow Six Siege.
	Your character carries `BodyTag` from the server. The transmitter is a pistol-grip one: your
	left hand round its grip, finger on the trigger, your right on the wheel at its side, its aerial
	up past your bowed head, and the torch in your right hand pointed at the floor ahead.
	Radians about each joint's own across axis, as `Kneel.Pose` turns them (a hanging arm or leg
	swings forward for positive; the body over the root pitches forward for negative); `Sink` and
	`Back` are shares of the hip height, so the feet stay flat on the floor on any avatar's legs.
	`In` turns an arm in across the chest; each hand's `Pitch` and `Yaw` are its turn against your
	body, whatever the arm above it does. Tuned in Studio on a standard avatar (hip height 2): the
	left hand mid-chest, a stud and a half ahead; the right on the wheel within a tenth of a stud.
]]
Drive.BodyTag = "DrivingCar"
Drive.Crouch = {
	Down = 0.45, -- seconds to crouch, and to stand back up: a settle, not a drop
	Sink = 0.42,
	Back = 0.15,
	Lean = math.rad(-20), -- hunched over it
	Waist = math.rad(-10),
	Neck = math.rad(-5), -- the head bowed over the transmitter
	Hip = math.rad(105), -- thighs out ahead, nearly level
	HipOut = math.rad(15), -- knees a little apart
	Knee = math.rad(-110),
	Ankle = math.rad(25), -- feet flat
	Left = {
		Shoulder = math.rad(62),
		In = math.rad(65),
		Elbow = math.rad(82),
		-- the transmitter upright, facing ahead, its wheel to your right: the find's quarter turn in
		-- the hand and the art's 18 degrees undone
		Pitch = 0,
		Yaw = math.rad(-72),
	},
	Right = {
		Shoulder = math.rad(55),
		In = math.rad(65),
		Elbow = math.rad(60),
		-- the torch pointed 30 degrees down at the floor ahead, clear of the transmitter
		Pitch = math.rad(-60),
		Yaw = math.rad(-180),
	},
}

-- What the stick says, as throttle and steering (each -1 to 1), from the control module's move
-- vector (`across` right, `along` its z: forward is negative). A diagonal counts as full on both,
-- as Brix's own controls do, so W and D together drive flat out; then a push to the side alone
-- gets `SideThrottle` of throttle, unless it's backing.
function Drive.controls(across: number, along: number): (number, number)
	local forward = -along
	local larger = math.max(math.abs(across), math.abs(forward))
	if larger <= 1e-3 then
		return 0, 0
	end
	local stretch = math.min(math.sqrt(across * across + forward * forward), 1) / larger
	local throttle, steer = forward * stretch, across * stretch
	if throttle >= 0 then
		throttle = math.max(throttle, math.abs(steer) * Drive.SideThrottle)
	end
	return math.clamp(throttle, -1, 1), math.clamp(steer, -1, 1)
end

-- The find's parts that are the car: its drive's `Body` and every part riding on it, in the
-- art's order. The rest (the transmitter) stays in your hand.
function Drive.carParts(find: Art.Find): { string }
	local drive = find.Drive
	if not drive then
		return {}
	end
	local parents: { [string]: string? } = {}
	for _, part in find.Parts do
		parents[part.Name] = part.Parent
	end
	local out = {}
	for _, part in find.Parts do
		local name: string? = part.Name
		while name and name ~= drive.Body do
			name = parents[name]
		end
		if name then
			table.insert(out, part.Name)
		end
	end
	return out
end

-- The whine's pitch and volume share at `speed` studs a second (either way).
function Drive.whine(speed: number): (number, number)
	local share = math.clamp(math.abs(speed) / Drive.Handling.top, 0, 1)
	return Drive.IdlePitch + (Drive.TopPitch - Drive.IdlePitch) * share,
		Drive.IdleVolume + (1 - Drive.IdleVolume) * share
end

-- How far the front wheels are turned (degrees, right positive, up to `lock`) for a car going
-- `speed` studs a second ahead and turning right at `turn` radians a second, with `wheelbase`
-- studs between its axles: the angle a car's wheels take to drive that circle. Rolling backward
-- the nose swings the other way, so the wheels point the other way too. Standing still: 0.
function Drive.steerFrom(speed: number, turn: number, wheelbase: number, lock: number): number
	if math.abs(speed) < 0.3 then
		return 0
	end
	local angle = math.deg(math.atan(turn * wheelbase / math.abs(speed)))
	if speed < 0 then
		angle = -angle
	end
	return math.clamp(angle, -lock, lock)
end

-- How far a wheel of `radius` studs turns (degrees) as the car rolls `distance` studs.
function Drive.spin(distance: number, radius: number): number
	return math.deg(distance / radius)
end

-- The jolt for a frame in which the car lost `lost` studs a second of speed (or stopped a fall):
-- nil below a bump.
function Drive.jolt(lost: number): number?
	if lost < Drive.BumpAt then
		return nil
	end
	return math.min(lost * Drive.Jolt, Drive.JoltMost)
end

-- Whether a car `dx`, `dy`, `dz` studs from your feet is close enough to take back.
function Drive.takes(dx: number, dy: number, dz: number): boolean
	return dx * dx + dz * dz <= Drive.TakeReach * Drive.TakeReach
		and math.abs(dy) <= Drive.TakeHeight
end

-- A car you drive, `dx`, `dy`, `dz` studs from your feet, `away` if it has been `HomeAway` from
-- them since the drive began: whether it has been away now, and whether it's home (taken back).
function Drive.home(away: boolean, dx: number, dy: number, dz: number): (boolean, boolean)
	if not away then
		away = dx * dx + dz * dz >= Drive.HomeAway * Drive.HomeAway
			or math.abs(dy) > Drive.TakeHeight
	end
	return away, away and Drive.takes(dx, dy, dz)
end

return Drive
