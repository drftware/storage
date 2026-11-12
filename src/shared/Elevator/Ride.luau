--!strict
--[[
	The ride (L-08a): the gate shuts, the car climbs one floor with whoever is aboard, and its
	gate opens on the next hall, as Dandy's World's elevator carries the team between floors. The
	breath between floors: relief as the car takes you, then dread as the counter turns over to the
	floor you're about to face.

	It runs on the server's clock, as the gate's does. The instant the shut gate hits its post the
	server writes one replicated value on the elevator (`Attribute`: that moment and the floors from
	and to), and every rider's screen draws the whole ride from it, second for second alike:

	- The car sits a beat, then its brakes let go: a clunk, the lamp dips as the motor takes the
	  load, the car drops a hair on its cables and pulls up (the lurch).
	- It gathers speed, climbs, and slows to level with the next floor, on a smooth S-curve.
	  Through the gate the hall goes dark and the shaft slides down past: the landing you left, its
	  header beam, bare concrete with the next floor's number painted on it, the next landing's
	  apron and sill, then that landing's dark mouth, level with you (RideView builds it on riders'
	  screens only; the car itself never moves, so nothing jitters).
	- Its sway is gentle and slow, and the only sharp things are the cable clanks, each a single
	  damped knock you hear as you feel it. No noise is ever added to the view.
	- The car's floor readout, and the clock's plate in the top bar, show the floor you left until
	  the brakes start to bite, then tick over to the next (a relay's click).
	- It levels with a bounce on its cables and the brake's clunk, the elevator's bell rings, the
	  dark lifts off the hall, and the gate folds open on it.

	Pure numbers and curves, so Lune checks them; the server keeps the clock (Elevators), and the
	screens draw it (RideView: the shaft, the sway, the sounds; ElevatorView: the lamp and the
	car's readout; GateClock: the plate).
]]
local Ride = {}

-- The ride, on the elevator: when it left (server time the gate hit its post) and the floors
-- from and to. Absent while the car stands at a floor.
Ride.Attribute = "Ride"
-- The floor the car stands at, on the elevator: what its readout shows at rest.
Ride.FloorAttribute = "Floor"
-- Studio only: a number in Workspace's attribute of this name holds every ride at that many
-- seconds in, on the server (the car never arrives) and on every screen, so a frame can be
-- looked at (docs/STUDIO.md, "Testing the ride from the MCP").
Ride.Hold = "DevRideHold"

-- The timeline, in seconds after the shut gate hits its post:
-- the car sits still for `Wait` (the gate's slam rings out, everyone's aboard and sealed in) ...
Ride.Wait = 0.8
-- ... then the brakes let go and it gathers speed over `Speedup`, smooth, as a heavy car does ...
Ride.Speedup = 1.8
-- ... climbs at full speed for `Cruise` (the shaft sliding past, two cable clanks) ...
Ride.Cruise = 4.6
-- ... and slows over `Slowdown` to level with the next floor. Long enough to feel the brakes bite
-- and read the new number before the car stops.
Ride.Slowdown = 2.4
-- Studs from floor to floor: how far the shaft slides past the gate. The car is 9.6 tall inside
-- and the landing's mouth 9.2, so this leaves a band of bare shaft wall to watch go by.
Ride.Rise = 16
-- Seconds after the car levels that the gate starts to fold open: the brake's clunk and the bell
-- first, the dark lifting off the hall, then the gate.
Ride.Open = 0.7
-- Seconds the gate stays open once it has folded, before it shuts behind the team (the climb's
-- runner arms it for the floor then): long enough to walk out, short enough that nobody camps
-- in the car.
Ride.Linger = 6

-- The lurch as the brakes let go: the car drops `LurchDrop` studs on its cables and springs back
-- at `LurchHz`, dying away over about `LurchFade` seconds; the view nods down with it.
Ride.LurchDrop = 0.08
Ride.LurchNod = math.rad(0.35)
Ride.LurchHz = 1.8
Ride.LurchFade = 0.28
-- Your body's weight: the view sinks this many studs for each stud per second per second the car
-- gathers speed, and floats as it slows. Heavy, never sharp.
Ride.Inertia = 0.03
-- Levelling: the car bobs up `SettleLift` studs on its cables at `SettleHz` and settles over
-- about `SettleFade` seconds.
Ride.SettleLift = 0.05
Ride.SettleHz = 2.4
Ride.SettleFade = 0.3
-- The cable clanks (seconds after the gate hit its post, inside the cruise): each a single knock,
-- `ClankLift` studs and `ClankNod` down at `ClankHz`, gone in about `ClankFade` seconds.
Ride.Clanks = { 3.9, 6.1 }
Ride.ClankLift = 0.02
Ride.ClankNod = math.rad(0.1)
Ride.ClankHz = 6
Ride.ClankFade = 0.09
-- The slow sway at full speed: a roll and a nod, each a slow sine, so the car feels hung on a
-- cable rather than bolted down. Too slow and small to read as shaking.
Ride.SwayRoll = math.rad(0.12)
Ride.SwayRollHz = 0.37
Ride.SwayNod = math.rad(0.07)
Ride.SwayNodHz = 0.53

-- The car's lamp as the motor takes the load: down to `ReleaseDip` of its brightness as the brakes
-- let go, back over about `ReleaseBack` seconds with one more flicker; a little at each clank;
-- and again as the brakes bite at the top.
Ride.ReleaseDip = 0.3
Ride.ReleaseBack = 0.16
Ride.ClankDip = 0.8
Ride.BrakeDip = 0.6

-- The hall beyond the gate goes dark over `DarkIn` seconds as the brakes let go (under the lamp's
-- dip, so you see the light fail rather than a screen fade), and the next hall's dark lifts over
-- the `Open` seconds after the car levels.
Ride.DarkIn = 0.3

-- The full speed, in studs a second, that climbs `Rise` over the ramps and the cruise.
Ride.Speed = Ride.Rise / (Ride.Speedup / 2 + Ride.Cruise + Ride.Slowdown / 2)

-- When the brakes let go, the car reaches full speed, starts to slow, and levels.
function Ride.moves(): number
	return Ride.Wait
end
function Ride.cruising(): number
	return Ride.Wait + Ride.Speedup
end
-- The readout ticks over to the next floor here, as the brakes start to bite.
function Ride.tick(): number
	return Ride.Wait + Ride.Speedup + Ride.Cruise
end
function Ride.arrives(): number
	return Ride.Wait + Ride.Speedup + Ride.Cruise + Ride.Slowdown
end
-- The gate starts to fold open, and the shaft is gone: the ride is over.
function Ride.opens(): number
	return Ride.arrives() + Ride.Open
end

-- Studs the car has climbed `since` seconds after the gate hit its post: still, then an S-curve
-- up to full speed, the cruise, and an S-curve down to level.
function Ride.climbed(since: number): number
	local v = Ride.Speed
	local t = since - Ride.Wait
	if t <= 0 then
		return 0
	end
	local up = Ride.Speedup
	if t < up then
		local u = t / up
		return v * up / 2 * (u - math.sin(math.pi * u) / math.pi)
	end
	local base = v * up / 2
	t -= up
	if t < Ride.Cruise then
		return base + v * t
	end
	base += v * Ride.Cruise
	t -= Ride.Cruise
	local down = Ride.Slowdown
	if t < down then
		local u = t / down
		return base + v * down / 2 * (u + math.sin(math.pi * u) / math.pi)
	end
	return Ride.Rise
end

-- The car's speed (studs a second) and its acceleration (studs a second a second) `since`
-- seconds after the gate hit its post.
function Ride.speed(since: number): (number, number)
	local v = Ride.Speed
	local t = since - Ride.Wait
	if t <= 0 then
		return 0, 0
	end
	local up = Ride.Speedup
	if t < up then
		local u = t / up
		return v * (1 - math.cos(math.pi * u)) / 2, v * math.pi / (2 * up) * math.sin(math.pi * u)
	end
	t -= up
	if t < Ride.Cruise then
		return v, 0
	end
	t -= Ride.Cruise
	local down = Ride.Slowdown
	if t < down then
		local u = t / down
		return v * (1 + math.cos(math.pi * u)) / 2,
			-v * math.pi / (2 * down) * math.sin(math.pi * u)
	end
	return 0, 0
end

-- The car's speed as a share of full speed: what the motor's pitch and the sway follow.
function Ride.share(since: number): number
	local v = Ride.speed(since)
	return v / Ride.Speed
end

-- Seconds a knock takes to get going: it eases out of rest rather than starting at full speed,
-- so even the lurch is a heavy shove and never a snap.
Ride.Onset = 0.05

-- A single damped knock `t` seconds after it starts: eased out of rest, out to about `size` and
-- back, dying away over about `fade` seconds. Zero before it starts.
local function knock(t: number, size: number, hz: number, fade: number): number
	if t <= 0 then
		return 0
	end
	local ease = 1 - math.exp(-t / Ride.Onset)
	return size * ease * math.exp(-t / fade) * math.sin(2 * math.pi * hz * t)
end

-- How the view sits `since` seconds after the gate hit its post: lifted (studs, + up), nodded
-- (radians, + up) and rolled (radians). Zero while the car stands still, smooth throughout.
function Ride.sway(since: number): (number, number, number)
	local released = since - Ride.Wait
	if released <= 0 then
		return 0, 0, 0
	end
	-- the lurch: the cables stretch as the brakes let go, so the car drops a hair first
	local lurch = knock(released, 1, Ride.LurchHz, Ride.LurchFade)
	local lift = -Ride.LurchDrop * lurch
	local nod = -Ride.LurchNod * lurch
	-- your weight against the car's pull
	local _, accel = Ride.speed(since)
	lift -= Ride.Inertia * accel
	-- levelling: the cables give, so the car bobs up and settles
	local settle = knock(since - Ride.arrives(), 1, Ride.SettleHz, Ride.SettleFade)
	lift += Ride.SettleLift * settle
	nod += Ride.LurchNod * 0.5 * settle
	-- each cable clank
	for _, at in Ride.Clanks do
		local k = knock(since - at, 1, Ride.ClankHz, Ride.ClankFade)
		lift -= Ride.ClankLift * k
		nod -= Ride.ClankNod * k
	end
	-- the slow sway of a car hung on a cable, only while it moves
	local share = Ride.share(since)
	local roll = Ride.SwayRoll * share * math.sin(2 * math.pi * Ride.SwayRollHz * released)
	nod += Ride.SwayNod * share * math.sin(2 * math.pi * Ride.SwayNodHz * released + 1)
	return lift, nod, roll
end

-- A dip of the lamp to `low` at once, back over about `back` seconds; 0 before it starts.
local function dip(t: number, low: number, back: number): number
	if t < 0 then
		return 0
	end
	return (1 - low) * math.exp(-t / back)
end

-- The car's lamp, as a share of its brightness, `since` seconds after the gate hit its post: it
-- dips as the brakes let go (with a second flicker a fifth of a second later), a little at each
-- clank, and as the brakes bite at the top.
function Ride.lamp(since: number): number
	local release = since - Ride.Wait
	local loss = dip(release, Ride.ReleaseDip, Ride.ReleaseBack)
		+ dip(release - 0.2, 0.75, 0.06)
		+ dip(since - Ride.arrives(), Ride.BrakeDip, Ride.ReleaseBack)
	for _, at in Ride.Clanks do
		loss += dip(since - at, Ride.ClankDip, 0.05)
	end
	return math.clamp(1 - loss, 0, 1)
end

-- How dark the hall you left is, through the gate (0 as it was, 1 black): it goes as the brakes
-- let go.
function Ride.leaving(since: number): number
	return math.clamp((since - Ride.Wait) / Ride.DarkIn, 0, 1)
end

-- How dark the next hall is, through the gate: black until the car levels, lifting as the bell
-- rings, gone as the gate starts to fold.
function Ride.arriving(since: number): number
	return math.clamp(1 - (since - Ride.arrives()) / Ride.Open, 0, 1)
end

-- The floor the readout shows: the one you left until the brakes start to bite, then the next.
function Ride.shown(since: number, from: number, to: number): number
	return if since < Ride.tick() then from else to
end

-- The front office's floor (L-08e1b1): a lobby car stands at it, and its ride goes from it to
-- floor 1. Its readout shows L, as a lift's ground floor does.
Ride.Lobby = 0

-- The readout's two characters for floor `n`: a lone digit right-aligned, as the clock's are; L
-- for the lobby.
function Ride.text(n: number): string
	local floor = math.clamp(math.floor(n), 0, 99)
	if floor == Ride.Lobby then
		return " L"
	end
	return string.format("%2d", floor)
end

-- The ride as its replicated value: when the gate hit its post, and the floors from and to.
function Ride.encode(at: number, from: number, to: number): string
	return string.format("%.3f|%d|%d", at, from, to)
end

-- The ride from its value: when, from, to. A missing or broken value is nil.
function Ride.decode(value: unknown): (number?, number, number)
	if type(value) ~= "string" then
		return nil, 0, 0
	end
	local at, from, to = string.match(value, "^([%d%.]+)|(%d+)|(%d+)$")
	local t, a, b = tonumber(at), tonumber(from), tonumber(to)
	if not (t and a and b) then
		return nil, 0, 0
	end
	return t, a, b
end

--[[
	The shaft riders see through the gate, in the elevator's frame (studs; the origin on the lobby
	floor at the middle of the threshold, the car behind, +Z): a thin sleeve between the landing's
	frame (its back at 0.5) and the car's front (0.59), so nothing real is in its way. Laid as the
	car stands at the floor you leave, it slides down by `climbed` until the next landing's mouth
	sits where this one's was.
]]
Ride.Shaft = {
	Plane = 0.53, -- its middle (Z)
	Depth = 0.04,
	Width = 13.2, -- past the car's posts either side
	Mouth = 9.2, -- a landing's mouth, as tall as the lobby's opening
	Header = 0.7, -- the steel beam over each mouth
	Apron = 1.5, -- the steel apron hanging under each landing's sill
	Sill = 0.14,
	Below = 6, -- shaft wall under the landing you leave, and over the next one's header
	-- the formwork lines across the bare wall, as heights over the header
	Seams = { 1.4, 2.9 },
	-- the next floor's number, painted on the bare wall left of the middle as you face out (clear
	-- of the torch in your right hand); the box is this tall, its digit about two thirds of it
	Number = { X = -2.8, Height = 3.6, Above = 0.4 },
	-- colours as red, green, blue (0 to 255)
	Colours = {
		Wall = { 78, 75, 70 },
		Seam = { 46, 44, 41 },
		Steel = { 52, 52, 54 },
		Apron = { 96, 92, 84 },
		Sill = { 160, 160, 156 },
		Dark = { 3, 3, 4 },
		Paint = { 214, 206, 186 },
	},
}

-- The sounds, heard on riders' screens only and alike in the car (from no one place), all from
-- Pro Sound Effects' library and measured in Studio (docs/STUDIO.md, "Sounds measured for the
-- ride"). Each plays a stretch of its recording.
export type Recording = {
	Id: string,
	Start: number, -- seconds into the recording its stretch starts
	Stop: number, -- and ends
	Fade: number, -- seconds it fades out over before Stop
	Volume: number,
}
export type SoundName =
	"Release"
	| "Motor"
	| "Rumble"
	| "Clank"
	| "Tick"
	| "MotorStop"
	| "Brake"
	| "Bell"

-- "Freight Elevator 3": the brakes letting go, a clunk at 1.13 s with most of its weight at
-- 470 Hz to 2 kHz, where a phone plays it.
local Release: Recording =
	{ Id = "rbxassetid://9114533164", Start = 0.7, Stop = 2.4, Fade = 0.6, Volume = 1.6 }
-- "Conveyor Belt 5": a clanky motor, steady from 0.5 to 13 s, nine tenths of it 190 Hz to
-- 2 kHz: the motor a phone can play. Swells with the car's speed, its pitch with it.
local Motor: Recording =
	{ Id = "rbxassetid://9113910297", Start = 0.45, Stop = 12.4, Fade = 0, Volume = 0.6 }
-- "Freight Elevator 2": the run's deep hum, 15 to 24.5 s, three quarters under 190 Hz: weight
-- in headphones, under the motor.
local Rumble: Recording =
	{ Id = "rbxassetid://9114533808", Start = 15, Stop = 24.5, Fade = 0, Volume = 1.2 }
-- The motor's own start knock, hard and bright, its hit at 0.24 s: a cable clank, pitched down.
local Clank: Recording =
	{ Id = "rbxassetid://9113910297", Start = 0.2, Stop = 0.65, Fade = 0.25, Volume = 0.25 }
-- The readout's relay ticking over (the unit lights' toggle click).
local Tick: Recording =
	{ Id = "rbxassetid://9117028600", Start = 0, Stop = 0.4, Fade = 0.1, Volume = 0.55 }
-- The motor winding down, its stop at 13.0 s landing as the car levels.
local MotorStop: Recording = {
	Id = "rbxassetid://9113910297",
	Start = 12.4,
	Stop = 13.7,
	Fade = 0.4,
	Volume = 0.6,
}
-- "Freight Elevator 3" again: its stop clunk at 15.15 s, the brake setting as the car levels.
local Brake: Recording =
	{ Id = "rbxassetid://9114533164", Start = 14.6, Stop = 16.6, Fade = 0.7, Volume = 0.9 }
-- The elevator's bell (the right code's double-ding), lower: the same bell that counted you
-- out rings you in.
local Bell: Recording =
	{ Id = "rbxassetid://9119642644", Start = 0, Stop = 2.4, Fade = 1.2, Volume = 6 }

-- Every sound by name, and their names in the order they're laid out.
Ride.Sounds = {
	Release = Release,
	Motor = Motor,
	Rumble = Rumble,
	Clank = Clank,
	Tick = Tick,
	MotorStop = MotorStop,
	Brake = Brake,
	Bell = Bell,
} :: { [string]: Recording }
local NAMES: { SoundName } =
	{ "Release", "Motor", "Rumble", "Clank", "Tick", "MotorStop", "Brake", "Bell" }
Ride.Names = NAMES
-- The two the screens tune each frame, following the car's speed.
Ride.Motor = Motor
Ride.Rumble = Rumble

-- Where in each recording its moment is (measured at 20 ms): the Release's, the Brake's and the
-- Clank's hits, and MotorStop's stop. A cue is timed so this lands on the moment it marks.
Ride.Clunk = { Release = 1.13, Brake = 15.15, MotorStop = 13.0, Clank = 0.24 }

-- Seconds the motor hands over to its own winding-down (MotorStop), fading out under it.
Ride.MotorHandOver = 0.4

-- When MotorStop starts: timed so its stop lands as the car levels.
function Ride.motorStops(): number
	return Ride.arrives() - (Ride.Clunk.MotorStop - MotorStop.Start)
end

-- The motor's pitch and its volume (a share of Motor.Volume) `since` seconds after the gate hit
-- its post: low and quiet as it takes the load, its own at full speed, and fading out under its
-- winding-down as the car levels. The rumble's volume follows the speed alone.
function Ride.motor(since: number): (number, number)
	local share = Ride.share(since)
	local hand = math.clamp(1 - (since - Ride.motorStops()) / Ride.MotorHandOver, 0, 1)
	return 0.82 + 0.18 * share, (0.35 + 0.65 * share) * hand
end

export type Cue = { sound: SoundName, at: number, pitch: number, volume: number }

-- Every sound of the ride, in order: when it starts (seconds after the gate hit its post), its
-- pitch and a share of its volume. The motor and the rumble then follow the car's speed.
function Ride.cues(): { Cue }
	local cues: { Cue } = {
		{
			sound = "Release",
			at = Ride.Wait - (Ride.Clunk.Release - Release.Start),
			pitch = 1,
			volume = 1,
		},
		{ sound = "Motor", at = Ride.Wait, pitch = 1, volume = 1 },
		{ sound = "Rumble", at = Ride.Wait, pitch = 1, volume = 1 },
	}
	for i, at in Ride.Clanks do
		local pitch = if i % 2 == 1 then 0.8 else 0.72
		local lead = (Ride.Clunk.Clank - Clank.Start) / pitch
		table.insert(cues, { sound = "Clank", at = at - lead, pitch = pitch, volume = 1 })
	end
	table.insert(cues, { sound = "Tick", at = Ride.tick(), pitch = 1, volume = 1 })
	local arrive = Ride.arrives()
	table.insert(cues, { sound = "MotorStop", at = Ride.motorStops(), pitch = 1, volume = 1 })
	table.insert(cues, {
		sound = "Brake",
		at = arrive - (Ride.Clunk.Brake - Brake.Start),
		pitch = 1,
		volume = 1,
	})
	table.insert(cues, { sound = "Bell", at = arrive + 0.15, pitch = 0.84, volume = 1 })
	table.sort(cues, function(a: Cue, b: Cue): boolean
		return a.at < b.at
	end)
	return cues
end

return Ride
