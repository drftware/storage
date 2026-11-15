--!strict
--[[
	KeeperMotion: how a keeper's movement reaches every screen (L-06b4a). Pure: nothing here
	touches an Instance, so Lune tests it (tests/keepermotion.spec.luau).

	The moment: it comes down the hall at you and every screen, a phone included, sees one smooth,
	stiff-limbed walk, not a body hopping between the server's updates.

	The server's brain (`Keeper`) moves a keeper every step. Instead of sending each step, the
	server sends a short record of its motion, and only when that changes: where its feet are, the
	way it faces and walks, how fast, how far it walks before it stops, how far it has walked (its
	walk's pose), its state, and the server's time. Every screen carries it on from there, the way
	a door's `DoorMotion` record carries RollUpDoor's motion. This is dead reckoning, the way
	shooters move other players between updates: each step the server works out where screens
	show it (`predict`, from the record they hold) and sends a new record (`due`) when that drifts,
	or it starts, stops, turns, changes pace or changes state, or walks on past where the last one
	said it stops (a hunter's says it stops at arm's length from where you are now, and you run);
	at most one each `Gap`, except that a new state always goes at once. A stop sent up to a `Gap`
	late is never walked past: each record says how far it walks before it stops (`left`), and
	screens stop there.

	Each screen (`follow`, `receive`, `update`) shows it `Delay` behind the server's time, so a
	turn or a stop usually arrives before the screen gets there and is shown exactly, never walked
	past. A record that arrives late moves where it should be; the screen eases the difference out
	over `Settle` (more than `Snap` studs is a snap, not a slide) and never carries it past where it
	stops (`left`). Its turns ease over `Turn`, and its pose follows how far it has walked, never
	backward.

	Your own torch's beam is the one thing a screen knows before the server (L-06b4b3): the moment
	your screen sees it land on a keeper that freezes in light, it holds where it's shown, as it's
	shown (`hold`), as SCP-173 and FNAF's animatronics hold the moment you look. The server's stop
	follows a round trip later, a little further on (it walked while your look travelled, and the
	screen shows it `Delay` behind); the screen keeps its own place while the light holds it, never
	sliding, and makes the gap up only as it walks again, over its first stride (`CatchUp`) or
	before the stop its record says it walks to, whichever comes first. If
	no stop comes within its `patience` (a wall the screen missed), it walks on the same way.

	Positions are the world's; a keeper's position is its feet. `update` allocates nothing, and each
	follower reuses its few records.
]]

local KeeperMotion = {}

-- Each screen's feel:
-- How far behind the server's time each screen shows it (seconds). A turn or stop that reaches a
-- screen within this is shown exactly; later ones are eased in. More hides more lag, but shows it
-- further back from where it truly is (1.6 studs at a full run per 0.1 s).
KeeperMotion.Delay = 0.1
-- How long a late correction takes to ease out (seconds; about two thirds of it in this time).
-- Shorter reads as a hop, longer as a slide.
KeeperMotion.Settle = 0.12
-- How long a turn takes to ease (seconds; about two thirds of it in this time): a quick, stiff
-- pivot at a corner rather than a pop.
KeeperMotion.Turn = 0.06
-- A correction bigger than this (studs) snaps rather than slides: it was stood somewhere new.
KeeperMotion.Snap = 4
-- Held by your own beam: how long your screen holds it on your beam's word alone (seconds), plus
-- two of your pings, before deciding the server didn't agree and letting it walk on. Longer
-- forgives a slow network; shorter lets a body your screen wrongly stopped walk on sooner.
KeeperMotion.Patience = 0.15
-- No longer than this, however slow the network (seconds).
KeeperMotion.MostPatience = 0.5
-- Once it walks again, how many studs it takes to make up where your hold left it behind the
-- server (about two thirds of it in this distance): its stride, two steps, so it closes the gap
-- a little quicker than it walks rather than lunging.
KeeperMotion.CatchUp = 5.4

-- What it costs to send:
-- The least time between two records in one state (seconds): at most 12.5 a second, even for a
-- hunter at arm's length stepping in and stopping as you shuffle.
KeeperMotion.Gap = 0.08
-- How far screens may drift from where it is (studs) before the server sends a record.
KeeperMotion.Drift = 0.25
-- How far it turns (radians) before the server sends a record.
KeeperMotion.Swing = math.rad(4)
-- How much its pace may change (studs a second) before the server sends a record.
KeeperMotion.Pace = 0.25

-- A trip longer than this (studs) is as good as endless: `left` is capped here so it encodes.
local FAR = 999
-- Close enough to count as there (studs; radians for a turn).
local SETTLED = 0.005
local FACED = 0.002
-- Records each screen keeps: those newer than the time it shows, and the one it shows from.
local RING = 8

local SNAP2 = KeeperMotion.Snap * KeeperMotion.Snap
local DRIFT2 = KeeperMotion.Drift * KeeperMotion.Drift
local SWING_COS = math.cos(KeeperMotion.Swing)
local SETTLED2 = SETTLED * SETTLED
local TAU = 2 * math.pi

--- One record of its motion, as the server sends it and screens read it.
export type Record = {
	t: number, -- the server's time it was true at (seconds)
	at: vector, -- where its feet were
	facing: vector, -- the way it faced and walked: flat, length 1
	speed: number, -- how fast it walked (studs a second); 0 standing
	left: number, -- how far it walks this way before it stops, if nothing changes (studs)
	travelled: number, -- studs walked since it was stood up: its walk's pose
	state: string, -- its state (Keeper.State)
}

--- How a screen poses it (as Pose.How): slack, walking, stopped mid-stride, or at a breaker box
--- with its hand up on the grip or dragging the lever down (S2-02d2). The Packrat (S2-06b2) also
--- reaches for a find (Reach), pulls it in (Take), sets it on its pile (PutDown), and walks
--- (Carry) or stands (Hold) with its arms full.
export type How =
	"Still"
	| "Walk"
	| "Stop"
	| "Reach"
	| "Pull"
	| "Take"
	| "PutDown"
	| "Carry"
	| "Hold"

--- One screen's view of one keeper: the last few records, and where it's shown.
export type Follow = {
	records: { Record }, -- the latest few, a ring
	count: number, -- how many the ring holds
	head: number, -- the newest's place in the ring
	scratch: Record, -- where an arriving record is read before it's kept
	at: vector, -- where it's shown
	facing: vector, -- the way it's shown facing
	travelled: number, -- how far it's shown having walked: its pose, never going back
	state: string, -- the state shown
	speed: number, -- how fast it's shown walking
	offset: vector, -- what's left of a late correction, easing out
	held: boolean, -- your own beam holds it on this screen (`hold`)
	heldAt: number, -- the time this screen showed as the hold began
	patience: number, -- how long the hold waits for the server's stop (seconds)
	stopped: number, -- the time of the server's stop that answered the hold (0: none yet)
	behind: vector, -- what's left of a hold, made up as it walks (`CatchUp`)
	behindWalk: number, -- and how far its pose is behind (studs walked)
	base: number, -- how far its records had it walking at the last update
}

--- A blank record, to read into.
function KeeperMotion.record(): Record
	return {
		t = 0,
		at = vector.zero,
		facing = vector.create(0, 0, -1),
		speed = 0,
		left = 0,
		travelled = 0,
		state = "Asleep",
	}
end

--- One record as the attribute carries it: a short line of text.
function KeeperMotion.encode(
	t: number,
	at: vector,
	facing: vector,
	speed: number,
	left: number,
	travelled: number,
	state: string
): string
	return string.format(
		"%s %.3f %.2f %.2f %.2f %.4f %.4f %.2f %.2f %.2f",
		state,
		t,
		at.x,
		at.y,
		at.z,
		facing.x,
		facing.z,
		speed,
		math.min(math.max(left, 0), FAR),
		travelled
	)
end

local function finite(n: number?): boolean
	return n ~= nil and n == n and n ~= math.huge and n ~= -math.huge
end

local PATTERN = "^(%a+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)$"

--- Reads a record into `into`. False, leaving `into` as it was, if it isn't one.
function KeeperMotion.decode(encoded: string, into: Record): boolean
	local state, t, x, y, z, fx, fz, speed, left, travelled = string.match(encoded, PATTERN)
	local nt, nx, ny, nz = tonumber(t), tonumber(x), tonumber(y), tonumber(z)
	local nfx, nfz, ns, nl, ntr =
		tonumber(fx), tonumber(fz), tonumber(speed), tonumber(left), tonumber(travelled)
	if
		not (state and nt and nx and ny and nz and nfx and nfz and ns and nl and ntr)
		or not (finite(nt) and finite(nx) and finite(ny) and finite(nz) and finite(nfx))
		or not (finite(nfz) and finite(ns) and finite(nl) and finite(ntr))
	then
		return false
	end
	local m = math.sqrt(nfx * nfx + nfz * nfz)
	if m < 1e-6 then
		return false
	end
	into.state = state
	into.t = nt
	into.at = vector.create(nx, ny, nz)
	into.facing = vector.create(nfx / m, 0, nfz / m)
	into.speed = math.max(ns, 0)
	into.left = math.max(nl, 0)
	into.travelled = ntr
	return true
end

--- Where a record says it is at time `t`, and how far it has walked: carried on the way it walks,
--- never past where it stops.
function KeeperMotion.predict(r: Record, t: number): (vector, number)
	local d = 0
	if r.speed > 0 and t > r.t then
		d = math.min(r.speed * (t - r.t), r.left)
	end
	return r.at + r.facing * d, r.travelled + d
end

--- The server's rule: whether to send a record now, at time `t`, for a keeper at `at` facing
--- `facing`, walking at `speed` (0 standing) in `state`, when screens hold `last` (as they read it).
function KeeperMotion.due(
	last: Record?,
	t: number,
	at: vector,
	facing: vector,
	speed: number,
	state: string
): boolean
	if not last then
		return true
	end
	if state ~= last.state then
		return true
	end
	if t - last.t < KeeperMotion.Gap then
		return false
	end
	if (speed > 0) ~= (last.speed > 0) then
		return true
	end
	-- still walking, and screens would reach where the last record stops it within a Gap: a new
	-- one now, so screens never stall at that stop while it walks on
	if speed > 0 and last.left - last.speed * (t - last.t) < last.speed * KeeperMotion.Gap then
		return true
	end
	local p = KeeperMotion.predict(last, t)
	local miss = at - p
	if vector.dot(miss, miss) > DRIFT2 then
		return true
	end
	if vector.dot(facing, last.facing) < SWING_COS then
		return true
	end
	return math.abs(speed - last.speed) > KeeperMotion.Pace
end

--- How a screen poses it, in `state` walking at `speed`.
function KeeperMotion.how(state: string, speed: number): How
	if state == "Asleep" then
		return "Still"
	elseif state == "Reaching" then
		return "Reach" -- `Keeper.shown`: its hand on a breaker's lever
	elseif state == "Pulling" then
		return "Pull"
	elseif state == "Taking" then
		return "Take" -- `Keeper.shown`: the Packrat's hands closed on a find
	elseif state == "PuttingDown" then
		return "PutDown"
	elseif state == "Carrying" then
		return if speed > 0 then "Carry" else "Hold"
	end
	return if speed > 0 then "Walk" else "Stop"
end

--- A screen's new, empty view of one keeper.
function KeeperMotion.follow(): Follow
	local records: { Record } = table.create(RING)
	for i = 1, RING do
		records[i] = KeeperMotion.record()
	end
	return {
		records = records,
		count = 0,
		head = 0,
		scratch = KeeperMotion.record(),
		at = vector.zero,
		facing = vector.create(0, 0, -1),
		travelled = 0,
		state = "Asleep",
		speed = 0,
		offset = vector.zero,
		held = false,
		heldAt = 0,
		patience = 0,
		stopped = 0,
		behind = vector.zero,
		behindWalk = 0,
		base = 0,
	}
end

--- How long a hold waits for the server's stop on a screen whose ping is `ping` seconds.
function KeeperMotion.patience(ping: number): number
	local p = if ping == ping and ping > 0 then ping else 0
	return math.min(KeeperMotion.Patience + 2 * p, KeeperMotion.MostPatience)
end

--- Your own beam just landed on it on this screen, showing time `t`: it holds where it's shown,
--- as it's shown, at once, waiting up to `patience` seconds (`KeeperMotion.patience`) for the
--- server's stop. Only a body shown walking can be held. Whether it took hold.
function KeeperMotion.hold(f: Follow, t: number, patience: number): boolean
	if f.held or f.count == 0 or f.state == "Asleep" or f.speed <= 0 then
		return false
	end
	f.held, f.heldAt, f.patience, f.stopped = true, t, patience, 0
	f.speed = 0
	return true
end

-- Where the records held put it at time `t`, how far it has walked, and the record it's shown by:
-- carried on from the newest at or before `t`, bent to meet the next one exactly when that one
-- says (unless the two are more than `Snap` apart: then it jumps when the next one comes). With
-- every record newer than `t`, it stands as the oldest says. Needs a record.
local function target(f: Follow, t: number): (vector, number, Record)
	local records = f.records
	local i = f.head
	local later: Record? = nil
	for _ = 1, f.count do
		local r = records[i]
		if r.t <= t then
			local at, travelled = KeeperMotion.predict(r, t)
			if later then
				local endAt, endTravelled = KeeperMotion.predict(r, later.t)
				local miss = later.at - endAt
				if vector.dot(miss, miss) <= SNAP2 then
					local span = later.t - r.t
					local w = if span > 1e-6 then (t - r.t) / span else 1
					at += miss * w
					travelled += (later.travelled - endTravelled) * w
				end
			end
			return at, travelled, r
		end
		later = r
		i = if i == 1 then RING else i - 1
	end
	local oldest = later :: Record
	return oldest.at, oldest.travelled, oldest
end

--- A screen got a record (`encoded`) while showing time `t`. Where it's shown doesn't jump: the
--- difference eases out over `Settle`, unless it's more than `Snap` studs. The first record shows
--- it exactly. False if it isn't a record or is no newer than the last.
function KeeperMotion.receive(f: Follow, encoded: string, t: number): boolean
	local r = f.scratch
	if not KeeperMotion.decode(encoded, r) then
		return false
	end
	if f.count > 0 and r.t <= f.records[f.head].t then
		return false
	end
	local before: vector? = nil
	if f.count > 0 then
		before = target(f, t)
	end
	local head = f.head % RING + 1
	f.scratch, f.records[head] = f.records[head], r
	f.head, f.count = head, math.min(f.count + 1, RING)
	if not before then
		local at, travelled, now = target(f, t)
		f.at, f.facing, f.travelled = at, now.facing, travelled
		f.state, f.speed, f.offset = now.state, now.speed, vector.zero
		return true
	end
	local offset = f.offset + (before - target(f, t))
	f.offset = if vector.dot(offset, offset) > SNAP2 then vector.zero else offset
	return true
end

-- Whether your beam's hold on it stands at time `t`, `now` being the record it's shown by: until
-- the server's stop answers it within its patience, then until the screen reaches the server
-- letting it walk on. A stop far from where it's held (stood somewhere new) lets go at once.
local function stillHeld(f: Follow, t: number, now: Record): boolean
	if f.stopped == 0 then
		local records = f.records
		local i = f.head
		for _ = 1, f.count do
			local r = records[i]
			if r.t <= f.heldAt then
				break
			end
			if r.speed <= 0 then
				f.stopped = r.t -- the earliest stop after the hold: the server's freeze
			end
			i = if i == 1 then RING else i - 1
		end
		if f.stopped == 0 then
			return t - f.heldAt < f.patience
		end
	end
	local newest = f.records[f.head]
	local miss = newest.at - f.at
	if newest.speed <= 0 and vector.dot(miss, miss) > SNAP2 then
		return false
	end
	return not (now.t > f.stopped and now.speed > 0)
end

-- Turns the way it's shown facing toward `want`, eased over `Turn`. Whether it's still turning.
local function turn(f: Follow, want: vector, dt: number): boolean
	local have = f.facing
	local a = math.atan2(have.x, have.z)
	local d = (math.atan2(want.x, want.z) - a + math.pi) % TAU - math.pi
	if math.abs(d) < FACED then
		f.facing = want
		return false
	end
	local h = a + d * (1 - math.exp(-dt / KeeperMotion.Turn))
	f.facing = vector.create(math.sin(h), 0, math.cos(h))
	return true
end

--- Moves a screen's view on to time `t`, `dt` seconds after the last: where it's shown, the way
--- it faces, how far it has walked, its state and pace. Whether it's still moving on this screen
--- (walking, a newer record still to reach, a correction or a turn still easing out); once not,
--- it needn't be stepped until the next record.
function KeeperMotion.update(f: Follow, t: number, dt: number): boolean
	if f.count == 0 then
		return false
	end
	local at, travelled, now = target(f, t)
	if f.held and not stillHeld(f, t, now) then
		-- let go: what the hold left behind is made up as it walks, unless it's a jump
		f.held = false
		local gap = f.at - at
		local newest = f.records[f.head]
		local miss = newest.at - f.at
		if vector.dot(gap, gap) > SNAP2 or newest.speed <= 0 and vector.dot(miss, miss) > SNAP2 then
			f.behind, f.behindWalk = vector.zero, 0
		else
			f.behind, f.behindWalk = gap, math.max(travelled - f.travelled, 0)
		end
		f.offset, f.base = vector.zero, travelled
	end
	if f.held then
		-- held where it was shown, as it was shown; only its state follows the server
		f.state, f.speed = now.state, 0
		return true
	end
	local walked = travelled - f.base
	f.base = travelled
	if walked > 0 and (f.behind ~= vector.zero or f.behindWalk > 0) then
		local keep = math.exp(-walked / KeeperMotion.CatchUp)
		if now.speed > 0 then
			-- made up by the time it stops, if its record says it stops sooner (a hunter's at
			-- arm's length from you): it closes in a little quicker, but never stands short
			local left = now.left - math.max(t - now.t, 0) * now.speed
			keep = math.min(keep, if left > 0 then left / (left + walked) else 0)
		end
		local behind = f.behind * keep
		if vector.dot(behind, behind) < SETTLED2 then
			f.behind, f.behindWalk = vector.zero, 0
		else
			f.behind, f.behindWalk = behind, f.behindWalk * keep
		end
	end
	travelled -= f.behindWalk
	local offset = f.offset
	if offset ~= vector.zero then
		offset *= math.exp(-dt / KeeperMotion.Settle)
		if vector.dot(offset, offset) < SETTLED2 then
			offset = vector.zero
		end
		f.offset = offset
	end
	f.at = at + offset + f.behind
	if travelled > f.travelled then
		f.travelled = travelled
	end
	f.state, f.speed = now.state, now.speed
	local turning = turn(f, now.facing, dt)
	local newest = f.records[f.head]
	return now ~= newest or newest.speed > 0 or offset ~= vector.zero or turning
end

return KeeperMotion
