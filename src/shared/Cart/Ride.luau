--!strict
--[[
	Cart.Ride: pure. Riding a platform cart across the lobby (L-08e4b1, GDD "The lobby"), as
	Roblox's classic skateboard kick-pushes and R.E.P.O.'s carts roll.

	You stand on the deck facing the handle, and the cart rolls handle first. Push the stick (or
	W) and the cart heads where you look, as walking does: your back leg kicks on its own in a
	steady rhythm while you hold it, each kick a push that adds less the faster you go; tapping
	is never faster than holding. Let go and it coasts to a stop. Push away from the way it rolls
	and you drag your foot: it slows in a straight line, then turns round. A wall, a cart or a
	friend head on stops it dead with a clank; met at a slant it scrapes and slides along. Nothing
	here moves up or down, so a cart can't launch anyone.

	Directions are on the floor (X, Z). A heading is radians about Y as `CFrame.Angles(0, h, 0)`
	turns its LookVector: the way (-sin h, -cos h).
]]

local Ride = {}

-- The speeds. A walk is 16 studs a second.
Ride.Cap = 28 -- studs a second, the most a cart ever rolls; held, the kicks cruise about 22
Ride.Kick = 10.5 -- what one kick adds from a standstill; less as you near the cap
Ride.KickEvery = 0.55 -- seconds from one kick to the next while you hold: the rhythm
-- (from a standstill: 15 a second after one second, 20 after one and a half)
Ride.Reach = 0.12 -- seconds your foot takes to find the floor before it pushes
Ride.Push = 0.22 -- seconds the push lasts: the kick's surge, not a jump in speed
Ride.Roll = 4.5 -- studs a second, lost each second to the casters while you coast
Ride.Drag = 0.12 -- and this share of the speed, each second: from a cruise, 45 studs in 4 s
Ride.Brake = 24 -- studs a second lost each second while you drag your foot: a second from full
Ride.Still = 0.2 -- below this, coasting, it has stopped
Ride.TurnScrub = 0.12 -- a tight turn scrubs speed off: this, times the turn rate, times speed

-- The stick. Below `Dead` it's let go; a kick needs the stick out past `KickPush`.
Ride.Dead = 0.25
Ride.KickPush = 0.5
-- you kick while the way you push is within this of the cart's: square across still kicks, so
-- a cart that can't swing yet (in the rack, against a wall) rolls out straight, then curves
Ride.KickCone = math.rad(100)
Ride.BrakeCone = math.rad(125) -- and drag your foot past this

-- The turn. Rates are radians a second; a standing cart swivels round on its casters faster
-- than a rolling one turns, so a turn at speed is a wide arc (about 27 studs across cruising).
Ride.TurnStill = math.rad(130)
Ride.TurnFast = math.rad(95)
Ride.TurnGain = 5 -- the turn rate wanted for each radian still to turn: it settles, no wobble
Ride.TurnEase = 0.12 -- seconds the turn takes to come in: the cart's weight
Ride.PivotBelow = 3 -- dragging your foot, it turns only once slower than this
-- It turns about its fixed casters at the handle end, as a real cart does (they can't slide
-- sideways), so you, standing by the handle, turn nearly on the spot while its tail swings:
-- studs from the cart's middle toward the handle (Specs.Casters[3].Axle.Z).
Ride.Pivot = 1.75

-- Bumps. `into` is the speed straight into what was hit.
Ride.Glance = 0.5 -- met flatter than this (the cosine: 30 degrees off the wall) it slides along
Ride.ScrapeKeep = 0.85 -- the share of the speed along the wall a slide keeps
Ride.Nudge = 1 -- into-speed below this stops it without a sound

-- Stepping. A frame is run in steps no longer than `StepMax`, so a cart feels the same on any
-- screen; a hitch longer than `FrameMax` loses the rest rather than throwing the cart.
Ride.StepMax = 1 / 60
Ride.FrameMax = 0.25

-- Hopping off at speed you keep this much of it (studs a second): a step off, not a dive.
Ride.HopCarry = 8

-- The cars' striped band, from the bay wall (Lobby frame, studs along -Z): a cart touching it
-- puts its rider off onto the stripes and stops there (art/lobby/spec.py PAINT_DEPTH).
Ride.Band = 3.2

-- The server's watch on a ridden cart's speed: over any stretch it may cover the cap times
-- `Slack`, plus `Leeway` studs for the network bunching its updates.
Ride.Slack = 1.3
Ride.Leeway = 4
Ride.CheckEvery = 0.5 -- seconds between the server's looks
Ride.StillFor = 0.4 -- seconds a riderless cart stands before the server parks it
Ride.CoastMax = 8 -- seconds a riderless cart may roll at most

-- What riding looks like on the rider's screen.
Ride.View = {
	Turn = 0.35, -- seconds your view takes to swing round to the way the cart rolls as you step on
	Dip = 0.12, -- studs your view drops as a kicking foot plants...
	DipTime = 0.3, -- ...and comes back up over this
	Lean = 0.05, -- radians of lean into a turn for each radian a second of turn
	Widen = 7, -- degrees the view widens at the cap: speed you feel at the edges
	Shiver = 0.012, -- studs of the casters' shiver at the cap
	Jolt = 0.6, -- a full-speed clank's jolt (camera trauma, 0 to 1)
	Hint = "Hold forward to roll", -- once a session, as you first step on
	HintOff = "Jump to hop off",
	HintFor = 3.5, -- seconds the hint stays
}

-- The cart's sounds (Roblox's licensed library, measured in Edit, docs/STUDIO.md): each an id,
-- the stretch of the recording played, its volume and pitch.
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number }
Ride.Sounds = (
	{
		-- the casters on the concrete, looped: Pro Sound Effects' "Gurney Rolling 1", a steady
		-- metal-wheel rattle from 2 to 15 s, mostly mids a phone plays
		Roll = { id = "rbxassetid://9114736569", from = 2, length = 13, volume = 0.9, pitch = 1 } :: Sound,
		-- a kick's scuff: "Paint Canvas 21", one dry-brush stroke, pitched down to a sole's grit
		Scuff = {
			id = "rbxassetid://9117188688",
			from = 0,
			length = 0.37,
			volume = 0.8,
			pitch = 0.8,
		} :: Sound,
		-- your foot dragging, looped: "Paint Canvas 5"'s steady stroke from 0.75 to 1 s
		Drag = {
			id = "rbxassetid://9117187117",
			from = 0.75,
			length = 0.25,
			volume = 0.6,
			pitch = 0.7,
		} :: Sound,
		-- a bump: "Shopping Cart 5", a cart into a curb, the hit at 4 s and its rattle
		Clank = { id = "rbxassetid://9119083245", from = 3.9, length = 1.3, volume = 1, pitch = 1 } :: Sound,
		-- sliding along a wall: "Skateboard Tail Grinds Scrapes 1"
		Scrape = {
			id = "rbxassetid://9125957009",
			from = 0,
			length = 1.2,
			volume = 0.6,
			pitch = 0.9,
		} :: Sound,
		-- stepping on or off: "Rubber Mat Hits Drops Impacts 9", one thud on the mat
		Step = { id = "rbxassetid://9118733086", from = 0, length = 0.4, volume = 1, pitch = 1 } :: Sound,
	} :: any
) :: { [string]: Sound } -- any: a table of named sounds, read by name
Ride.Hear = 60 -- studs a cart's sounds carry

-- The casters' rattle at `speed`: its volume and pitch, rising together (silent standing).
function Ride.rumble(speed: number): (number, number)
	local f = math.clamp(speed / Ride.Cap, 0, 1)
	return Ride.Sounds.Roll.volume * f ^ 0.7, 0.75 + 0.5 * f
end

export type State = {
	speed: number, -- studs a second along the heading, never below 0
	heading: number, -- the way it rolls (handle first), radians about Y
	yawRate: number, -- radians a second, eased
	sinceKick: number, -- seconds since the last kick began
	push: number, -- the speed a second this kick's push adds, while it pushes
	dragging: boolean, -- your foot is down, slowing it
}

-- What a step heard: "Plant" as a kicking foot meets the floor.
export type Event = "Plant" | "None"

-- A bump: "Clank" stopped it, "Scrape" slid it along, "Stop" stopped it softly.
export type Bump = "Clank" | "Scrape" | "Stop" | "None"

local TAU = 2 * math.pi

local function wrap(a: number): number
	return (a + math.pi) % TAU - math.pi
end
Ride.wrap = wrap

-- A cart standing still, facing `heading`.
function Ride.new(heading: number): State
	return {
		speed = 0,
		heading = wrap(heading),
		yawRate = 0,
		sinceKick = math.huge,
		push = 0,
		dragging = false,
	}
end

-- The heading whose way is (x, z).
function Ride.headingOf(x: number, z: number): number
	return math.atan2(-x, -z)
end

-- The way a heading points: x, z.
function Ride.way(heading: number): (number, number)
	return -math.sin(heading), -math.cos(heading)
end

-- What one kick adds at `speed`: the full kick from a standstill, nothing at the cap.
function Ride.kickGain(speed: number): number
	local f = speed / Ride.Cap
	return Ride.Kick * math.max(0, 1 - f * f)
end

-- The fastest the cart turns at `speed`.
function Ride.turnLimit(speed: number): number
	local f = math.clamp(speed / Ride.Cap, 0, 1)
	return Ride.TurnStill + (Ride.TurnFast - Ride.TurnStill) * f
end

--[[
	One step of `h` seconds (no longer than StepMax). (wx, wz) is the way you push, on the floor,
	its length how far the stick is out (0 to 1; 0 when riderless). Returns how far the cart
	moved (dx, dz) and whether a kicking foot met the floor.
]]
function Ride.step(s: State, wx: number, wz: number, h: number): (number, number, Event)
	local m = math.min(math.sqrt(wx * wx + wz * wz), 1)
	local want = m >= Ride.Dead
	local diff = 0
	if want then
		diff = wrap(Ride.headingOf(wx, wz) - s.heading)
	end
	local off = math.abs(diff)
	local brake = want and off >= Ride.BrakeCone
	local ahead = want and off <= Ride.KickCone and m >= Ride.KickPush

	-- the turn: toward the way you push, eased in; straight with no push, or dragging at speed
	local target = 0
	if want and not (brake and s.speed >= Ride.PivotBelow) then
		local limit = Ride.turnLimit(s.speed)
		target = math.clamp(diff * Ride.TurnGain, -limit, limit)
	end
	s.yawRate += (target - s.yawRate) * math.min(1, h / Ride.TurnEase)
	local ox, oz = Ride.way(s.heading)
	s.heading = wrap(s.heading + s.yawRate * h)
	local nx, nz = Ride.way(s.heading)
	-- the middle swings round the fixed axle
	local swingX, swingZ = Ride.Pivot * (ox - nx), Ride.Pivot * (oz - nz)

	-- the kick: one each KickEvery while you push ahead; it bites after Reach, for Push
	local event: Event = "None"
	local before = s.sinceKick
	if ahead and before >= Ride.KickEvery then
		before = 0
		s.sinceKick = 0
		s.push = Ride.kickGain(s.speed) / Ride.Push
	end
	local after = before + h
	s.sinceKick = after
	if before <= Ride.Reach and after > Ride.Reach then
		event = "Plant"
	end
	local pushStart, pushEnd = Ride.Reach, Ride.Reach + Ride.Push
	local pushing = math.max(0, math.min(after, pushEnd) - math.max(before, pushStart))
	s.speed += s.push * pushing

	-- the losses: the casters, the turn's scrub, your foot
	local v = s.speed
	local loss = (Ride.Roll + Ride.Drag * v + Ride.TurnScrub * math.abs(s.yawRate) * v) * h
	s.dragging = brake and v > 0
	if s.dragging then
		loss += Ride.Brake * h
	end
	v = math.max(0, v - loss)
	if v < Ride.Still and pushing <= 0 then
		v = 0
	end
	s.speed = math.min(v, Ride.Cap)

	return nx * s.speed * h + swingX, nz * s.speed * h + swingZ, event
end

--[[
	A frame of `dt` seconds, in even steps no longer than StepMax (a hitch past FrameMax loses the
	rest). Returns the whole frame's move and whether a foot met the floor in it.
]]
function Ride.advance(s: State, wx: number, wz: number, dt: number): (number, number, Event)
	local t = math.min(dt, Ride.FrameMax)
	if t <= 0 then
		return 0, 0, "None"
	end
	local n = math.ceil(t / Ride.StepMax - 1e-9)
	local h = t / n
	local dx, dz = 0, 0
	local event: Event = "None"
	for _ = 1, n do
		local x: number, z: number, e: Event = Ride.step(s, wx, wz, h)
		dx += x
		dz += z
		if e ~= "None" then
			event = e
		end
	end
	return dx, dz, event
end

--[[
	The cart met something whose face points (nx, nz) (on the floor, toward the cart). Head on it
	stops dead; at a slant it turns to slide along the face, losing a little. Returns what kind of
	bump and how hard (the speed straight in, over the cap: 0 to 1). The speed never grows.
]]
function Ride.hit(s: State, nx: number, nz: number): (Bump, number)
	local len = math.sqrt(nx * nx + nz * nz)
	if len < 1e-6 then
		-- a face with no way along the floor (a lip, a step): it stops
		local loud = s.speed / Ride.Cap
		s.speed, s.yawRate, s.push = 0, 0, 0
		return if loud * Ride.Cap >= Ride.Nudge then "Clank" else "Stop", loud
	end
	nx, nz = nx / len, nz / len
	local x, z = Ride.way(s.heading)
	local c = -(x * nx + z * nz) -- the cosine between the way it rolls and straight in
	if c <= 0 then
		return "None", 0 -- rolling away from it
	end
	local into = s.speed * c
	if c < Ride.Glance and s.speed > 0 then
		-- a slant: turn along the face and keep most of the speed along it
		local tx, tz = x + c * nx, z + c * nz
		local tl = math.sqrt(tx * tx + tz * tz)
		if tl > 1e-6 then
			s.heading = Ride.headingOf(tx / tl, tz / tl)
			s.speed = s.speed * tl * Ride.ScrapeKeep
			s.yawRate = 0
			return "Scrape", into / Ride.Cap
		end
	end
	s.speed, s.yawRate, s.push = 0, 0, 0
	if into < Ride.Nudge then
		return "Stop", into / Ride.Cap
	end
	return "Clank", into / Ride.Cap
end

-- The kicking leg (the right), in degrees at its joints: the hip's swing forward (+) or back,
-- its swing out from the deck, the knee's bend (negative bends), and the body's dip (studs) as
-- the foot pushes. Keyframes by seconds since the kick began; a foot at rest waits on the deck
-- behind the standing one.
export type Leg = { at: number, hip: number, out: number, knee: number }
Ride.Legs = {
	{ at = 0, hip = -8, out = 6, knee = -25 }, -- on the deck behind you
	{ at = Ride.Reach, hip = 18, out = 14, knee = -5 }, -- down beside the deck, ahead
	{ at = Ride.Reach + Ride.Push, hip = -38, out = 14, knee = 0 }, -- pushed back along the floor
	{ at = Ride.Reach + Ride.Push + 0.1, hip = -28, out = 10, knee = -70 }, -- lifted, knee bent
	{ at = Ride.KickEvery, hip = -8, out = 6, knee = -25 }, -- back on the deck for the next
} :: { Leg }
Ride.LegDrag = { at = 0, hip = 14, out = 16, knee = -4 } :: Leg -- planted ahead, dragging
Ride.LegDip = 0.15 -- studs the body sinks through a push

local function smooth(x: number): number
	return x * x * (3 - 2 * x)
end

-- The kicking leg `age` seconds into a kick (nil: no kick lately), or dragging.
function Ride.leg(age: number?, dragging: boolean): (number, number, number, number)
	if dragging then
		local d = Ride.LegDrag
		return d.hip, d.out, d.knee, 0
	end
	local legs = Ride.Legs
	local rest = legs[1]
	if age == nil or age <= 0 or age >= Ride.KickEvery then
		return rest.hip, rest.out, rest.knee, 0
	end
	local dipX = math.clamp((age - Ride.Reach + 0.05) / (Ride.Push + 0.1), 0, 1)
	local dip = -Ride.LegDip * math.sin(math.pi * dipX)
	for i = 1, #legs - 1 do
		local a, b = legs[i], legs[i + 1]
		if age <= b.at then
			local f = smooth((age - a.at) / (b.at - a.at))
			return a.hip + (b.hip - a.hip) * f,
				a.out + (b.out - a.out) * f,
				a.knee + (b.knee - a.knee) * f,
				dip
		end
	end
	return rest.hip, rest.out, rest.knee, 0
end

-- How far along +Z a cart's footprint reaches past its middle: a box `halfWidth` by
-- `halfLength` (along the heading) turned to `heading`. The cars' band is +Z of the room.
function Ride.reachZ(heading: number, halfWidth: number, halfLength: number): number
	return halfLength * math.abs(math.cos(heading)) + halfWidth * math.abs(math.sin(heading))
end

-- Whether `distance` studs in `seconds` is past what a cart can roll (the server's check).
function Ride.tooFast(distance: number, seconds: number): boolean
	return distance > Ride.Cap * seconds * Ride.Slack + Ride.Leeway
end

return Ride
