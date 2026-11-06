--!strict
--[[
	How a roll-up door moves: rise (studs) over time for each door action. Timings are the
	GDD's door table ("Doors"), for a full stroke; a partial stroke scales by distance.

		Peek        1 s    lift a foot and crouch; quiet
		Open        2 s    the full reveal; loud rattle
		Close       1.6 s  pulled down by hand
		Slam        drop   pulled hard: falls like a dropped curtain, bangs, bounces once
		LiftInside  6 s    lifted from inside, heaving: always possible, never fast

	Pure functions of (kind, from, to, elapsed), so the server and every client agree on where
	a door is without streaming positions: the server sends one Motion, everyone samples it.
]]

export type Kind = "Peek" | "Open" | "Close" | "Slam" | "LiftInside"

local Motion = {}

local KINDS: { [string]: Kind } = {
	Peek = "Peek",
	Open = "Open",
	Close = "Close",
	Slam = "Slam",
	LiftInside = "LiftInside",
}

local FULL = {
	Peek = 1.0,
	Open = 2.0,
	Close = 1.6,
	LiftInside = 6.0,
}
local SLAM_G = 200 -- studs/s^2: gravity plus a hard pull (a full stroke lands in 0.28 s)
local BOUNCE_T = 0.26 -- s
local MIN_T = 0.12

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
	local h = math.abs(to - from)
	if kind == "Slam" then
		if h < 1e-4 then
			return 0
		end
		return math.sqrt(2 * h / SLAM_G) + BOUNCE_T
	end
	if h < 1e-4 then
		return 0
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
	if kind == "Slam" then
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
	elseif kind == "Close" then
		return from + h * inOutCubic(t)
	elseif kind == "LiftInside" then
		-- three heaves: the climb speeds up and stalls three times, never slipping back
		local heave = math.sin(t * math.pi * 6) * 0.025 * (1 - t)
		return from + h * clamp01(t + heave)
	end
	return from + h * lift(t)
end

-- True for the five door actions (guards anything a remote might pass in).
function Motion.isKind(kind: any): boolean
	return type(kind) == "string" and KINDS[kind] ~= nil
end

-- Where each action heads, given the size's rise table.
function Motion.target(kind: Kind, rise: { Peek: number, Open: number }): number
	if kind == "Peek" then
		return rise.Peek
	elseif kind == "Open" or kind == "LiftInside" then
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
