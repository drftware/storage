--!strict
--[[
	The gate's clock (L-05b2). The right code folds the gate open, and once it has slammed open a
	30-second clock starts for everyone on the floor; at zero the gate folds shut on its own and
	the car leaves with whoever is aboard, as Dandy's World's elevator does. Nobody can send it
	early (GDD, "Codes, the elevator and the roof"). Pure numbers, so Lune checks the timing; the
	server keeps the clock (Elevators), and every screen shows it (GateClock, ElevatorView).

	Two replicated values on the elevator carry it:
	- `Attribute`: the server time the gate starts to shut. Absent while no clock runs.
	- `AboardAttribute`: written the instant the shut gate hits its post: that moment, and the
	  UserIds of everyone inside the car then. Absent until the car leaves.

	What the clock does to the floor, second by second:
	- At the start the PA chimes for the whole floor and the clock shows on every screen there.
	- From `Warning` seconds left the clock turns red, the car's lamp starts to blink (slowly, then
	  faster and faster), and a heartbeat starts under everything, quickening as it runs down, as
	  Dandy's World plays a heartbeat over its elevator's timer.
	- In the last `Final` seconds the elevator's bell rings once each second.
	- At zero the gate folds shut with its own ratchet and slam (Sounds.gate); those inside ride
	  (Ride, L-08a).
]]
local Gate = require("./Gate")
local Specs = require("./Specs")

local Departure = {}

Departure.Attribute = "Departs"
Departure.AboardAttribute = "Aboard"

-- Seconds the clock runs: the GDD's 30, Dandy's World's elevator timer. Long enough to run back
-- from the far end of a floor if you go at once; short enough that nobody finishes a search.
Departure.Seconds = 30
-- From this many seconds left: the clock goes red, the lamp blinks and the heartbeat starts. The
-- moment a friend still out on the floor should be running, not looking.
Departure.Warning = 10
-- The last seconds, each rung on the elevator's bell: the count you dive to.
Departure.Final = 5
-- How far from the elevator the clock is heard and shown (studs): a whole floor. A floor's
-- farthest hall is about 195 studs from the elevator (measured over 300 seeds, floors 3 to 10).
Departure.Heard = 240

-- The car's lamp in the warning: lit for `BlinkOn` of each blink, dimmed to `BlinkLow` of its
-- brightness for the rest; each blink lasts `SlowBlink` seconds at the warning's start, shrinking
-- steadily to `FastBlink` at zero. The safe light starting to panic.
Departure.SlowBlink = 0.9
Departure.FastBlink = 0.16
Departure.BlinkOn = 0.55
Departure.BlinkLow = 0.12

-- The heartbeat under the warning: from `HeartQuiet` volume at its normal pace to `HeartLoud`
-- and `HeartFast` times its pace (and pitch) at zero; it fades out over `HeartFade` seconds once
-- the gate starts to shut. The recording beats about 78 times a minute (measured), so 113 at zero.
Departure.HeartQuiet = 0.2
Departure.HeartLoud = 0.6
Departure.HeartFast = 1.45
Departure.HeartFade = 1.2

-- The car leaving, as those left in the lobby see it: its lamp draws away over `LampAway`
-- seconds, slow and then fast, as a light rising up a shaft does, and the lobby is dark.
Departure.LampAway = 1.6

-- The PA's sounds, heard alike by everyone on the floor (from no one place): a chime as the
-- clock starts, so a friend at the far end knows to run; the elevator's bell for each of the last
-- seconds (the right code's double-ding, cut short); and the heartbeat. All from Roblox's licensed
-- libraries, so they load in any game; measured in Studio (docs/STUDIO.md).
export type Recording = {
	Id: string,
	Start: number, -- seconds into the recording its stretch starts
	Stop: number, -- and ends
	Fade: number, -- seconds it fades out over before Stop
	Volume: number,
}
-- Two synth tones, up then down, an elevator's chime (Pro Sound Effects); both rung by 0.35 s.
Departure.Chime = {
	Id = "rbxassetid://9114302479",
	Start = 0.1,
	Stop = 2,
	Fade = 0.6,
	Volume = 1,
} :: Recording
-- The double-ding, 30 dB under the others (hence the volume), held for most of a second.
Departure.Bell = {
	Id = "rbxassetid://9119642644",
	Start = 0,
	Stop = 0.95,
	Fade = 0.4,
	Volume = 6,
} :: Recording
-- Each bell this much higher than the one before: the count climbing to the slam.
Departure.BellRise = 0.04
-- A clean lub-dub at about 78 a minute (APM Music's "Heartbeat 01"), looped.
Departure.Heart = {
	Id = "rbxassetid://9043365727",
	Start = 0,
	Stop = 60,
	Fade = 0,
	Volume = 1,
} :: Recording

export type Phase = "Folding" | "Counting" | "Warning" | "Final" | "Shutting" | "Gone"

-- The server time the gate starts to shut, for a right code at `rightAt` with the gate `from` of
-- the way shut: the gate's latch and fold open, then the full clock.
function Departure.departs(rightAt: number, from: number): number
	return rightAt + Gate.Delay + Gate.duration(from, 0) + Departure.Seconds
end

-- When the clock starts (the gate has slammed open), for a gate that starts to shut at `departs`.
function Departure.starts(departs: number): number
	return departs - Departure.Seconds
end

-- When the shutting gate hits its post: the moment the car leaves and who's aboard is decided.
function Departure.leaves(departs: number): number
	return departs + Gate.duration(0, 1)
end

-- Seconds left on the clock (can be negative once the gate is shutting), `t` in server time.
function Departure.left(departs: number, t: number): number
	return departs - t
end

-- Where the clock stands with `left` seconds to go.
function Departure.phase(left: number): Phase
	if left > Departure.Seconds then
		return "Folding"
	elseif left > Departure.Warning then
		return "Counting"
	elseif left > Departure.Final then
		return "Warning"
	elseif left > 0 then
		return "Final"
	elseif left > -Gate.duration(0, 1) then
		return "Shutting"
	end
	return "Gone"
end

-- The whole seconds the clock shows: 30 at its start, 1 in its last second, 0 at zero.
function Departure.shown(left: number): number
	return math.clamp(math.ceil(left), 0, Departure.Seconds)
end

-- The clock's two digits as its readout shows them: a lone digit right-aligned, no leading zero,
-- as an LED timer blanks it.
function Departure.text(left: number): string
	return string.format("%2d", Departure.shown(left))
end

-- Blinks done `s` seconds into the warning, each one's length shrinking steadily from SlowBlink
-- to FastBlink: the integral of one over that length.
local function blinks(s: number): number
	local slow, fast, w = Departure.SlowBlink, Departure.FastBlink, Departure.Warning
	local length = slow + (fast - slow) * s / w
	return w / (fast - slow) * math.log(length / slow)
end

-- The car's lamp, as a share of its brightness, with `left` seconds to go: steady until the
-- warning, blinking ever faster through it, steady again once the gate shuts.
function Departure.lamp(left: number): number
	if left > Departure.Warning or left <= 0 then
		return 1
	end
	local n = blinks(Departure.Warning - left)
	return if n - math.floor(n) < Departure.BlinkOn then 1 else Departure.BlinkLow
end

-- The car's lamp `since` seconds after the car left, as a share of its brightness, for those
-- left behind: it draws away, gathering speed, and is gone.
function Departure.away(since: number): number
	if since <= 0 then
		return 1
	end
	local u = math.min(since / Departure.LampAway, 1)
	return 1 - u * u
end

-- The heartbeat with `left` seconds to go: its volume and its pace, or nil while it's silent.
function Departure.heart(left: number): (number?, number)
	if left > Departure.Warning then
		return nil, 1
	end
	if left > 0 then
		local u = 1 - left / Departure.Warning
		local volume = Departure.HeartQuiet + (Departure.HeartLoud - Departure.HeartQuiet) * u
		return volume, 1 + (Departure.HeartFast - 1) * u
	end
	local fade = 1 + left / Departure.HeartFade
	if fade <= 0 then
		return nil, Departure.HeartFast
	end
	return Departure.HeartLoud * fade, Departure.HeartFast
end

-- The seconds left at which the bell rings: each whole second of the last few.
function Departure.bells(): { number }
	local at = {}
	for s = Departure.Final, 1, -1 do
		table.insert(at, s)
	end
	return at
end

-- The bell's pitch as the clock shows `shown`: its own at 5, a little higher each second after.
function Departure.bellPitch(shown: number): number
	return 1 + Departure.BellRise * (Departure.Final - shown)
end

-- The car, in the elevator's frame: wall to wall, from the gate's pickets back to the car's back
-- wall, floor to ceiling. Whoever's middle is in it as the gate hits its post rode.
function Departure.car(): ({ number }, { number })
	local c = Specs.Car
	local front = Specs.Gate.Plane
	return { 0, c.Height / 2, (front + c.Back) / 2 }, { c.Width, c.Height, c.Back - front }
end

-- The options for Brix's Zone.box over the car of an elevator whose frame stands at (x, y, z),
-- turned `turn` about the upright axis (MotionLight.turnOf of its X axis). `pathing` is what the
-- box measures along (Brix's free pathing).
function Departure.carBox<P>(
	pathing: P,
	x: number,
	y: number,
	z: number,
	turn: number
): { pathing: P, center: vector, size: vector, turn: number }
	local centre, size = Departure.car()
	-- the elevator's +Z (into the car) after the turn
	local back = centre[3]
	return {
		pathing = pathing,
		center = vector.create(x + back * math.sin(turn), y + centre[2], z + back * math.cos(turn)),
		size = vector.create(size[1], size[2], size[3]),
		turn = turn,
	}
end

-- The car's leaving as its replicated value: when the gate hit its post, and who was aboard.
function Departure.encodeAboard(at: number, ids: { number }): string
	local parts = table.create(#ids)
	for i, id in ids do
		parts[i] = string.format("%d", id)
	end
	return string.format("%.3f|", at) .. table.concat(parts, ",")
end

-- The leaving from its value: when, and who (UserIds). A missing or broken value is nil.
function Departure.decodeAboard(value: unknown): (number?, { number })
	local ids: { number } = {}
	if type(value) ~= "string" then
		return nil, ids
	end
	local at, rest = string.match(value, "^([%d%.]+)|([%d,]*)$")
	local t = tonumber(at)
	if not t or rest == nil then
		return nil, ids
	end
	for id in string.gmatch(rest, "%d+") do
		table.insert(ids, tonumber(id) :: number)
	end
	return t, ids
end

return Departure
