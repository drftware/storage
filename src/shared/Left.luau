--!strict
--[[
	Left behind (L-08c, the GDD's "Left behind"): when the elevator's gate shuts, anyone still kept
	or still out on the floor is out of the climb. They watch their friends go on without them, as
	Lethal Company's dead crew watch the living from behind their shoulders, until the climb ends
	(L-08d, ClimbEnd: the results screen) or they Cut Free back in (DOORS' revive), which puts them on their friends' floor.

	The moment, on a left player's screen, timed from the gate hitting its post (the car leaving):
	"Left behind" slams up in a cold red as the screen's top and bottom darken (`title`, `edges`);
	the lamp draws away up the shaft (ElevatorView) and the motor groans and fades as the car climbs
	out of earshot, muffled by the building (`away`); as the light goes a low hit lands and your
	legs give up; you stand frozen in the dark lobby as the motor fades far above; the screen goes
	black (`black`) before the floor below is cleared under you, 13.4 s in (Climb.HandOff); under the black the bell rings far above; and the black lifts on a friend's
	shoulder as their car levels on the new floor and its gate folds open without you.

	From then the camera follows a friend from behind and over their shoulder, smoothed so their
	steps and the network's jitter never shake it (`ease`, `turn`), pulled in short of any wall
	behind them; a drag swings it round them. Arrows switch friend (`cycle`), with a dip to black
	while the next one streams in. Your own character is gone (nothing can hurt or see you); the
	server streams the world around whoever you watch.

	Pure numbers, so Lune checks them; the server decides who's left and who they watch (Watching),
	each screen draws it (WatchView).
]]
local Departure = require("./Elevator/Departure")
local Ride = require("./Elevator/Ride")

local Left = {}

-- On the player: the server time the car left them (the gate hit its post). Set as it leaves
-- them, cleared only when they're back in the climb.
Left.Attribute = "LeftBehind"
-- An ObjectValue in the player, once their floor has gone under them and they're watching: its
-- Value is the friend's character (nil on their screen until it streams in), and its `Friend`
-- attribute the friend's name, written first, so the name shows while the camera waits.
Left.WatchValue = "Watching"
Left.NameAttribute = "Friend"
-- On the player as they're let back in: "<server time>|<why>", so their screen plays the moment
-- (`encodeBack`).
Left.BackAttribute = "BackIn"
-- ReplicatedStorage.Remotes.Watch: a watcher's screen asks for the next friend, the one before,
-- or (Studio only until the product exists) Cut Free.
Left.Remote = "Watch"
export type Ask = "Next" | "Back" | "CutFree"
-- Seconds between asks the server takes from one player: faster than a thumb taps the arrows is
-- spam.
Left.AskEvery = 0.2
-- Studio only: a model tagged this (a Humanoid and its root, as a stand-in friend in the Cut free
-- recipe) counts as a friend aboard the car when it leaves, rides up and can be watched, so one
-- player can be left behind (docs/STUDIO.md).
Left.StandInTag = "StandInFriend"

-- The sting, in seconds after the car left you.
-- "Left behind" slams up with the gate (just after its clang), in over `TitleIn` as it settles from
-- `TitlePop` times its size; the screen dims to `Dim` black behind it so the words read on any
-- hall, and its top and bottom darken to `Edges` (where the play HUD is) by `Freeze`.
Left.TitleAt = 0.15
Left.TitleIn = 0.35
Left.TitlePop = 1.3
Left.Dim = 0.35
Left.Edges = 0.92
-- The low hit lands as the car's light has gone up the shaft, and your legs give up with it: the
-- controls go and the play HUD with them.
Left.HitAt = Departure.LampAway
Left.Freeze = Departure.LampAway
-- The black comes down over `DarkIn`, whole well before the floor is cleared at the hand-off (the
-- ride's last cable knock); until then you stand in the dark lobby hearing the car grind away.
Left.DarkAt = Ride.Clanks[#Ride.Clanks] - 3
Left.DarkIn = 1.2
-- The black lifts on your friend over `LiftIn`, starting as their car brakes to level, so the bell
-- rings in the dark and you see the gate fold open on the new floor (Ride.opens, 19.5 s).
Left.LiftAt = Ride.arrives() - 0.5
Left.LiftIn = 1.1
-- Seconds the watching bar takes to come up once the black has lifted.
Left.BarIn = 0.5
-- The car's bell heard from far below it: a share of the riders' volume.
Left.BellVolume = 0.35
-- How loud the motor sounds as the car leaves you, as a share of the riders' (it's above you,
-- through the shaft), and how much of its top end the building takes off (dB, EqualizerSoundEffect).
Left.MotorVolume = 0.9
Left.Muffle = -14

-- Switching friend: the dip to black, in and out (seconds).
Left.DipIn = 0.1
Left.DipOut = 0.35

-- The follow camera, in studs and radians.
-- Behind the friend's head, up over it, and to one side: over their right shoulder, so they never
-- hide the middle of the hall ahead of them.
Left.Back = 6
Left.Up = 1.4
Left.Side = 1.1
-- Looking down a touch, at what they're about to walk into.
Left.Pitch = math.rad(-10)
-- How fast the camera catches up (per second, exponential): its spot, and its heading as the
-- friend turns (slower, so a friend spinning to look round swings the view, not snaps it).
Left.Follow = 9
Left.Turn = 4
-- A friend moving further than this in a frame (moved into the next car, a respawn) is a cut.
Left.Cut = 25
-- Pulled in short of a wall by this much, never nearer their head than `Near`; it eases back out
-- at `Ease` a second once the wall's gone.
Left.Clear = 0.4
Left.Near = 1.2
Left.Ease = 3
-- A drag swings the view round them: radians a pixel (touch, mouse with the right button) and a
-- second at full stick; up and down no further than these.
Left.OrbitTouch = 0.008
Left.OrbitMouse = 0.005
Left.OrbitStick = 2.4
Left.PitchLow = math.rad(-55)
Left.PitchHigh = math.rad(30)

-- The words. Few, and the way back in said plainly.
Left.Copy = {
	Title = "Left behind",
	Watching = "WATCHING",
	Until = "Back in when they finish",
	CutFree = "Cut Free",
	Back = "Back in",
	Nobody = "Waiting for a friend",
}

local function smooth(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- How black the screen is `since` seconds after the car left you: clear, dimmed behind the title,
-- then black to the end of the sting (the watch lifts it, `lift`).
function Left.black(since: number): number
	if since < Left.TitleAt then
		return 0
	end
	local dim = Left.Dim * smooth((since - Left.TitleAt) / Left.TitleIn)
	if since < Left.DarkAt then
		return dim
	end
	local u = (since - Left.DarkAt) / Left.DarkIn
	return dim + (1 - dim) * smooth(u)
end

-- How dark the top and bottom of the screen are `since` seconds after the car left you: a
-- cutscene's bars coming in over the HUD as your legs give up.
function Left.edges(since: number): number
	return Left.Edges * smooth((since - Left.TitleAt) / (Left.Freeze - Left.TitleAt))
end

-- How visible the title is `since` seconds after the car left you, and its size (a share): it
-- slams up and settles, holds, and goes under the black.
function Left.title(since: number): (number, number)
	if since < Left.TitleAt then
		return 0, Left.TitlePop
	end
	local u = math.min((since - Left.TitleAt) / Left.TitleIn, 1)
	local shown = smooth(u)
	local eased = 1 - (1 - u) * (1 - u) * (1 - u) -- out fast, settling
	local size = Left.TitlePop + (1 - Left.TitlePop) * eased
	local gone = smooth((since - Left.DarkAt) / (Left.DarkIn * 0.8))
	return shown * (1 - gone), size
end

-- The motor's loudness (a share) `since` seconds after the car left you: it swells as the car gets
-- going and fades as it climbs away up the shaft, gone well before the car levels.
function Left.away(since: number): number
	if since <= Ride.Wait then
		return 0
	end
	local going = Ride.share(since)
	local far = Ride.climbed(since) / Ride.Rise
	return math.max(going, 0.35 * smooth((since - Ride.Wait) / 0.4)) * (1 - smooth(far * 1.6))
end

-- How black the screen still is `t` seconds after the watch began lifting.
function Left.lift(t: number): number
	return 1 - smooth(t / Left.LiftIn)
end

-- How black a switch's dip is `t` seconds into it: it holds black while the next friend hasn't
-- streamed in (`waitedSince` nil), and lifts once they have, `waitedSince` seconds ago.
function Left.dip(t: number, waitedSince: number?): number
	local down = smooth(t / Left.DipIn)
	if waitedSince == nil then
		return down
	end
	return down * (1 - smooth(waitedSince / Left.DipOut))
end

-- The share of the way to its target a smoothed value covers in `dt` seconds at `rate` a second:
-- the same path at any frame rate.
function Left.ease(rate: number, dt: number): number
	return 1 - math.exp(-rate * math.max(dt, 0))
end

-- A heading (radians) turned toward `target` the short way round, at `rate` a second.
function Left.turn(heading: number, target: number, rate: number, dt: number): number
	local d = (target - heading + math.pi) % (2 * math.pi) - math.pi
	return heading + d * Left.ease(rate, dt)
end

-- The heading (radians, 0 along -Z, turning left positive) that a look direction faces.
function Left.heading(x: number, z: number): number
	return math.atan2(-x, -z)
end

-- The friend after (`step` 1) or before (-1) `current` in `keys`, in sorted order, wrapping round;
-- the first if `current` isn't among them; nil if there's nobody.
function Left.cycle(keys: { string }, current: string?, step: number): string?
	local n = #keys
	if n == 0 then
		return nil
	end
	local sorted = table.clone(keys)
	table.sort(sorted)
	local at = if current then table.find(sorted, current) else nil
	if not at then
		return sorted[1]
	end
	return sorted[(at - 1 + (if step < 0 then -1 else 1)) % n + 1]
end

-- The back-in value: when, and why ("CutFree").
function Left.encodeBack(at: number, why: string): string
	return string.format("%.3f|%s", at, why)
end

function Left.decodeBack(value: unknown): (number?, string)
	if type(value) ~= "string" then
		return nil, ""
	end
	local at, why = string.match(value, "^([%d%.%-]+)|(%a*)$")
	local t = if at then tonumber(at) else nil
	return t, why or ""
end

return Left
