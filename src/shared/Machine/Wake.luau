--!strict
--[[
	The machine waking on a ride (S1-10b2): the gate slams, the car shudders, and in the back corner
	the dark machine blinks awake. Each row's fluorescent tube has its own starter: it tinks, the
	tube flashes once or twice and fails, then catches and warms up to full, bottom row first, so
	the light climbs the glass a row at a time; then the sign over the glass buzzes on. The machine
	is on the car's circuit, so it dips with the car's lamp as the brakes let go, at each cable
	clank and as they bite at the top, and it all cuts out as the gate starts to fold (the car
	docked, its power back to the building's). Old vending machines' tubes start just this way;
	the waking is the cue that the ride is the time to shop (S1-10c), as Dandy's World's elevator
	ride is its shop.

	Dark on the first ride (from the lobby up to floor 1): nobody has coins yet, so it sleeps,
	and wakes from floor 1 on (GDD "The ride").

	Pure: shares of each light's brightness from seconds into the ride, so Lune checks them and
	every rider's screen draws the same flicker at the same moment (MachineView).
]]
local Ride = require("../Elevator/Ride")

local Wake = {}

-- A starter's try: `At` seconds after the tube's start, a flash `For` seconds long at `Level` of
-- full. A starter clicks (`Click`) at each try, the fluorescent tink.
export type Flash = { At: number, For: number, Level: number }
-- One light's waking: when it starts (seconds after the gate hits its post), its failed flashes,
-- and when it catches.
export type Start = { At: number, Flashes: { Flash }, Catch: number }

--[[
	The rows' tubes, bottom row first. They start once the brakes have let go (0.8 s) and the lurch
	has passed, so the slam, then the lurch, then the tink of the first starter each land alone.
	Each row's tries differ (two, one, three), so it reads as three old tubes and not a sequence.
]]
Wake.Tubes = {
	{
		At = 1.2,
		Flashes = { { At = 0, For = 0.06, Level = 0.55 }, { At = 0.22, For = 0.05, Level = 0.8 } },
		Catch = 0.5,
	},
	{
		At = 2.0,
		Flashes = { { At = 0, For = 0.05, Level = 0.7 } },
		Catch = 0.28,
	},
	{
		At = 2.75,
		Flashes = {
			{ At = 0, For = 0.05, Level = 0.45 },
			{ At = 0.17, For = 0.07, Level = 0.85 },
			{ At = 0.46, For = 0.04, Level = 0.6 },
		},
		Catch = 0.72,
	},
} :: { Start }

-- The sign buzzes on last, as the car reaches full speed: two stutters, then it holds.
Wake.Sign = {
	At = 3.75,
	Flashes = { { At = 0, For = 0.09, Level = 0.6 }, { At = 0.16, For = 0.12, Level = 0.9 } },
	Catch = 0.36,
} :: Start

-- A tube that has just caught glows at `Warm` of full and comes up over about `WarmUp` seconds,
-- as a cold fluorescent does: the light keeps swelling a moment after the flicker stops.
Wake.Warm = 0.72
Wake.WarmUp = 0.6

-- How much the machine dips with the car's lamp (a share of the lamp's own dip): it's on the
-- same circuit, but its tubes hold a little better than the bulb.
Wake.Sag = 0.7

-- As the gate starts to fold the power drops: the tubes are gone in `Fade` seconds (a
-- fluorescent's ends glow a breath after the cut), and the sign a beat after them.
Wake.Fade = 0.12
Wake.SignLate = 0.1
Wake.SignFade = 0.25

-- One light's share (0 dark to 1 full) `t` seconds after its start: dark before it, its flashes,
-- then caught and warming.
local function lit(start: Start, t: number): number
	if t < 0 then
		return 0
	end
	if t >= start.Catch then
		local w = t - start.Catch
		return Wake.Warm + (1 - Wake.Warm) * (1 - math.exp(-w / (Wake.WarmUp / 3)))
	end
	for _, f in start.Flashes do
		if t >= f.At and t < f.At + f.For then
			return f.Level
		end
	end
	return 0
end

-- The car's power, as a share, `since` seconds into the ride: full but for the lamp's dips.
function Wake.power(since: number): number
	return 1 - (1 - Ride.lamp(since)) * Wake.Sag
end

-- Whether a ride from floor `from` wakes the machine at all: never on the first ride, from the
-- lobby.
function Wake.wakes(from: number): boolean
	return from ~= Ride.Lobby
end

-- What's left of the light `since` seconds into the ride once the power has dropped, cut `late`
-- seconds after the gate starts to fold and gone over `fade`.
local function cut(since: number, late: number, fade: number): number
	local t = since - Ride.opens() - late
	if t <= 0 then
		return 1
	end
	return math.max(0, 1 - t / fade)
end

-- Row `row`'s tube (1 bottom to 3 top), as a share of full, `since` seconds into a ride from
-- floor `from`.
function Wake.tube(row: number, since: number, from: number): number
	local start = Wake.Tubes[row]
	if not start or not Wake.wakes(from) then
		return 0
	end
	return lit(start, since - start.At) * Wake.power(since) * cut(since, 0, Wake.Fade)
end

-- The sign, as a share of full, `since` seconds into a ride from floor `from`.
function Wake.sign(since: number, from: number): number
	if not Wake.wakes(from) then
		return 0
	end
	local start = Wake.Sign
	return lit(start, since - start.At)
		* Wake.power(since)
		* cut(since, Wake.SignLate, Wake.SignFade)
end

-- The machine's hum, as a share of its full loudness: it grows as each tube catches and the
-- sign comes on (each light a quarter), and dips and dies with them.
function Wake.hum(since: number, from: number): number
	local sum = Wake.sign(since, from)
	for row in Wake.Tubes do
		sum += Wake.tube(row, since, from)
	end
	return sum / (#Wake.Tubes + 1)
end

-- When it's all dark again for good, in seconds into the ride.
function Wake.over(): number
	return Ride.opens() + math.max(Wake.Fade, Wake.SignLate + Wake.SignFade)
end

-- Whether the machine is still changing `since` seconds into a ride from `from` (the screen
-- steps it only then): until it's dark again, on a ride that wakes it. A screen whose clock reads
-- a hair before the slam steps it too, so it never misses the waking.
function Wake.changing(since: number, from: number): boolean
	return Wake.wakes(from) and since < Wake.over()
end

-- Every starter's click on a ride that wakes it: seconds into the ride and which light (a row,
-- or 0 for the sign), in time order. The screen plays a tink at each as `since` passes it.
export type Click = { At: number, Light: number }
Wake.Clicks = {} :: { Click }
for row, start in Wake.Tubes do
	for _, f in start.Flashes do
		table.insert(Wake.Clicks, { At = start.At + f.At, Light = row })
	end
end
for _, f in Wake.Sign.Flashes do
	table.insert(Wake.Clicks, { At = Wake.Sign.At + f.At, Light = 0 })
end
table.sort(Wake.Clicks, function(a: Click, b: Click): boolean
	return a.At < b.At
end)

-- When each light catches, in seconds into the ride: a row's (1 to 3) or the sign's (0).
function Wake.catches(light: number): number
	local start = if light == 0 then Wake.Sign else Wake.Tubes[light]
	return start.At + start.Catch
end

return Wake
