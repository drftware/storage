--!strict
--[[
	How a roll-up door moves: rise (studs) over time for each door action. Timings are the
	GDD's door table ("Doors"), for a full stroke; a partial stroke scales by distance.

		Peek        1 s    lift a foot and crouch; quiet
		Open        2 s    the full reveal; loud rattle
		Close       1.6 s  pulled down by hand
		Slam        drop   pulled hard: falls like a dropped curtain, bangs, bounces once
		LiftInside  6 s    lifted from inside, heaving: always possible, never fast
		Rattle      0.7 s  a padlocked door tried: it jerks against the bolt and drops back
		Bang        0.5 s  a keeper trapped inside hits it: it jumps on its rail and drops back
		Burst       0.6 s  a trapped keeper bursts it up from inside: torn free, flung to the top
		Ease        1.85 s pulled down over a sleeping monster (S2-05a): most of the way as a close
		                   is, caught, then a creep to hang a foot up while the tap's bar runs
		                   (`ShutTap`)
		Settle      0.9 s  the tap hit: eased the last foot onto the concrete, landing soft
		Drop        drop   the tap missed: it slips from the hand and bangs down, as hard as a slam

	Pure functions of (kind, from, to, elapsed), so the server and every client agree on where
	a door is without streaming positions: the server sends one Motion, everyone samples it.
]]

export type Kind =
	"Peek"
	| "Open"
	| "Close"
	| "Slam"
	| "LiftInside"
	| "Rattle"
	| "Bang"
	| "Burst"
	| "Ease"
	| "Settle"
	| "Drop"

local Motion = {}

local KINDS: { [string]: Kind } = {
	Peek = "Peek",
	Open = "Open",
	Close = "Close",
	Slam = "Slam",
	LiftInside = "LiftInside",
	Rattle = "Rattle",
	Bang = "Bang",
	Burst = "Burst",
	Ease = "Ease",
	Settle = "Settle",
	Drop = "Drop",
}

local FULL = {
	Peek = 1.0,
	Open = 2.0,
	Close = 1.6,
	LiftInside = 6.0,
	-- a full stroke in 0.6 s, fastest at the start: something heavy threw it up from inside (L-06b3d)
	Burst = 0.6,
}
-- The tap's door (S2-05a). It eases down over EASE_T whatever height it started from, longer than
-- the tap's whole window and a late tap's trip to the server (ShutTap: 1.55 + 0.25 s), so it is
-- still creeping, never at rest a foot up, whenever the tap lands. Its settle takes SETTLE_T for
-- the last foot, slow at both ends, so it touches the concrete with almost no speed.
local EASE_T = 1.85
local SETTLE_T = 0.9
-- The ease is pulled down as a close is for EASE_CATCH_T, caught EASE_CREEP studs above where it
-- hangs, then crept down the rest, slowing all the way: by the time the marker crosses the bar
-- it hangs about a foot up, still moving a little.
local EASE_CATCH_T = 0.6
local EASE_CREEP = 0.45
-- Where it hangs while the bar runs (studs): about a foot, under a peek's 1.15. The light under
-- the door shows the monster's feet; the door is a foot from shutting on it.
Motion.Hover = 0.9
local SLAM_G = 200 -- studs/s^2: gravity plus a hard pull (a full stroke lands in 0.28 s)
local BOUNCE_T = 0.26 -- s
local MIN_T = 0.12
-- A padlocked door yanked: three jerks against the bolt, each a little smaller, over the length of
-- its sound (DoorSound's Rattle). The lift is a few centimetres: the light under the door flickers.
local RATTLE_T = 0.7 -- s
local RATTLE_LIFT = 0.12 -- studs at the first jerk
local RATTLE_JERKS = 3
-- A trapped keeper's blow from inside (L-06b3d): the door jumps on its rail, drops back and
-- bounces once, over the length of its boom. Higher than a rattle's jerk: a body hit it.
local BANG_T = 0.5 -- s
local BANG_LIFT = 0.4 -- studs: the jump peaks at a little over half this

local function clamp01(x: number): number
	return if x < 0 then 0 elseif x > 1 then 1 else x
end

-- Ease curves on 0..1.
local function outQuart(t: number): number
	local u = 1 - t
	return 1 - u * u * u * u
end

local function inOutCubic(t: number): number
	return if t < 0.5 then 4 * t * t * t else 1 - (-2 * t + 2) ^ 3 / 2
end

-- Spring-balanced lift: a quick break-away, a steady climb, eased into the stop bolts.
local function lift(t: number): number
	return 0.8 * inOutCubic(t) + 0.2 * outQuart(t)
end

-- Bounce height after a slam lands, for a stroke of `h` studs.
local function bounceHeight(h: number): number
	return math.min(0.32, 0.045 * h)
end

function Motion.duration(kind: Kind, from: number, to: number, fullStroke: number): number
	if kind == "Rattle" then
		return RATTLE_T
	elseif kind == "Bang" then
		return BANG_T
	end
	local h = math.abs(to - from)
	if kind == "Slam" or kind == "Drop" then
		if h < 1e-4 then
			return 0
		end
		return math.sqrt(2 * h / SLAM_G) + BOUNCE_T
	end
	if h < 1e-4 then
		return 0
	elseif kind == "Ease" then
		return EASE_T
	elseif kind == "Settle" then
		return SETTLE_T
	end
	local base = FULL[kind] or FULL.Open
	local frac = if kind == "Peek" then 1 else math.min(1, h / math.max(fullStroke, 1e-3))
	return math.max(MIN_T, base * frac)
end

-- Rise at `elapsed` seconds into a motion from `from` to `to`.
function Motion.sample(
	kind: Kind,
	from: number,
	to: number,
	elapsed: number,
	fullStroke: number
): number
	local dur = Motion.duration(kind, from, to, fullStroke)
	if dur <= 0 or elapsed >= dur then
		return to
	end
	if elapsed <= 0 then
		return from
	end
	local h = to - from
	if kind == "Rattle" then
		local t = elapsed / dur
		return from + RATTLE_LIFT * math.abs(math.sin(math.pi * RATTLE_JERKS * t)) * (1 - t)
	elseif kind == "Bang" then
		-- one jump and a small bounce, dying fast
		local t = elapsed / dur
		return from + BANG_LIFT * math.abs(math.sin(math.pi * 2 * t)) * (1 - t) ^ 3
	end
	if kind == "Slam" or kind == "Drop" then
		local fall = math.sqrt(2 * math.abs(h) / SLAM_G)
		if elapsed < fall then
			return from + h * (elapsed / fall) ^ 2
		end
		-- one damped bounce off the floor, then settle
		local b = (elapsed - fall) / BOUNCE_T
		return to + bounceHeight(math.abs(h)) * math.sin(math.pi * b) * (1 - b) ^ 1.5
	end
	local t = clamp01(elapsed / dur)
	if kind == "Peek" then
		return from + h * outQuart(t)
	elseif kind == "Close" or kind == "Settle" then
		return from + h * inOutCubic(t)
	elseif kind == "Ease" then
		-- pulled down as a close is, caught just above its foot, then let down slower and slower
		local catch = if from > to then math.min(from, to + EASE_CREEP) else to
		if elapsed < EASE_CATCH_T then
			return from + (catch - from) * inOutCubic(elapsed / EASE_CATCH_T)
		end
		local u = 1 - clamp01((elapsed - EASE_CATCH_T) / math.max(dur - EASE_CATCH_T, 1e-3))
		return catch + (to - catch) * (1 - u * u)
	elseif kind == "Burst" then
		-- torn free at its fastest, then slowing only as it nears the stop bolts
		local u = 1 - t
		return from + h * (1 - u * u * u)
	elseif kind == "LiftInside" then
		-- three heaves: the climb speeds up and stalls three times, never slipping back
		local heave = math.sin(t * math.pi * 6) * 0.025 * (1 - t)
		return from + h * clamp01(t + heave)
	end
	return from + h * lift(t)
end

-- How fast the door is moving at `elapsed` seconds in (studs/s, either direction): the curve's
-- slope over 2 ms. Zero before the motion starts and once it has ended.
function Motion.speed(
	kind: Kind,
	from: number,
	to: number,
	elapsed: number,
	fullStroke: number
): number
	local dur = Motion.duration(kind, from, to, fullStroke)
	if dur <= 0 or elapsed < 0 or elapsed >= dur then
		return 0
	end
	local a, b = math.max(elapsed - 0.001, 0), math.min(elapsed + 0.001, dur)
	local ya = Motion.sample(kind, from, to, a, fullStroke)
	local yb = Motion.sample(kind, from, to, b, fullStroke)
	return math.abs(yb - ya) / (b - a)
end

--[[
	The moments a door hits something during a motion, in order. Sounds and the slam's shake are
	timed off these, so they land exactly when the door does.

		Floor   a slam lands, or a close settles on the concrete
		Bounce  a slam's one bounce comes back down
		Top     a lift reaches the stop bolts at the top

	Strength (0..1) is how hard: a slam from fully open lands at 1; one from a peek's height,
	falling less far, lands softer (impact speed grows with the square root of the drop).
]]
export type Strike = { at: number, what: "Floor" | "Bounce" | "Top", strength: number }

function Motion.strikes(kind: Kind, from: number, to: number, fullStroke: number): { Strike }
	local h = math.abs(to - from)
	if h < 1e-4 then
		return {}
	end
	if kind == "Slam" or kind == "Drop" then
		local fall = math.sqrt(2 * h / SLAM_G)
		-- a drop lands as hard as a slam from all the way up: the bang is the point (S2-05a)
		local strength = if kind == "Drop"
			then 1
			else math.min(1, math.sqrt(h / math.max(fullStroke, 1e-3)))
		return {
			{ at = fall, what = "Floor", strength = strength },
			{ at = fall + BOUNCE_T, what = "Bounce", strength = strength },
		}
	end
	local dur = Motion.duration(kind, from, to, fullStroke)
	if to < 1e-4 then
		return { { at = dur, what = "Floor", strength = 1 } }
	elseif kind ~= "Peek" and to > from and to >= fullStroke - 1e-3 then
		return { { at = dur, what = "Top", strength = 1 } }
	end
	return {}
end

-- True for the eleven door motions (guards anything a remote might pass in).
function Motion.isKind(kind: any): boolean
	return type(kind) == "string" and KINDS[kind] ~= nil
end

-- Where each action heads, given the size's rise table.
function Motion.target(kind: Kind, rise: { Peek: number, Open: number }): number
	if kind == "Peek" then
		return rise.Peek
	elseif kind == "Ease" then
		return math.min(Motion.Hover, rise.Peek)
	elseif kind == "Open" or kind == "LiftInside" or kind == "Burst" then
		return rise.Open
	end
	return 0
end

-- The motion attribute: one string so kind, endpoints and start time replicate together.
function Motion.encode(kind: Kind, from: number, to: number, start: number): string
	return string.format("%s|%.4f|%.4f|%.4f", kind, from, to, start)
end

function Motion.decode(s: string?): (Kind, number, number, number)
	if type(s) ~= "string" then
		return "Close", 0, 0, 0
	end
	local name, a, b, c = string.match(s, "^(%a+)|([%-%d%.]+)|([%-%d%.]+)|([%-%d%.]+)$")
	local kind: Kind? = if name then KINDS[name] else nil
	if not kind then
		return "Close", 0, 0, 0
	end
	return kind, tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end

return Motion
