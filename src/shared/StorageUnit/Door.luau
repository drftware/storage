--!strict
--[[
	Door: the GDD's door ("Doors") as a state machine. Pure, so Lune checks every state, action and
	side; the server's Doors system asks it before moving any door, and shows only what it offers.

	The door's state comes from what it's doing (its Motion) and its padlock:

		Closed    down and still; the building can't see in
		Peeking   lifted a foot, or on its way there
		Opening   rising for the full reveal
		Lifting   heaved up from inside (6 s): nobody outside can shut it on you meanwhile
		Open      up at the stop bolts
		Closing   pulled down by hand
		Slamming  falling and bouncing; over in half a second
		Locked    padlocked shut: tried, it rattles against the bolt; bolt cutters take it off

	What a player can do depends on where they stand: in the hall, or inside the unit.

		Peek, Open           from the hall, on a shut door
		Close, Slam          on a door that's up, from either side (shut yourself in to hide)
		Lift                 from inside, on a shut door: always possible unless padlocked
		Cut                  bolt cutters on a padlock, from the hall
		Lock                 a padlock on a shut door, from the hall (the padlock tool's use)

	A refusal the player can see says why in a word or three ("Padlocked", "Need bolt cutters"). An
	ask the door never offered (a stale tap, an exploit) is refused silently.
]]

-- a string require, as Brix's modules do, so Lune can load this module for its tests too
local Motion = require("./Motion")

export type State =
	"Closed"
	| "Peeking"
	| "Opening"
	| "Lifting"
	| "Open"
	| "Closing"
	| "Slamming"
	| "Locked"
export type Action = "Peek" | "Open" | "Close" | "Slam" | "Lift" | "Cut" | "Lock"
export type Side = "Hall" | "Inside"
export type Tool = "BoltCutters" | "Padlock"
-- What a player carries.
export type Tools = { BoltCutters: boolean, Padlock: boolean }

export type Verdict = {
	ok: boolean,
	motion: Motion.Kind?, -- the door's motion: the action's own, or a padlocked door's rattle
	lock: boolean?, -- the padlock goes on (true) or comes off (false)
	refusal: string?, -- shown on the prompt when refused; nil when refused silently
}

local Door = {}

Door.States = {
	"Closed",
	"Peeking",
	"Opening",
	"Lifting",
	"Open",
	"Closing",
	"Slamming",
	"Locked",
} :: { State }
Door.Actions = { "Peek", "Open", "Close", "Slam", "Lift", "Cut", "Lock" } :: { Action }
Door.Sides = { "Hall", "Inside" } :: { Side }

--[[
	Each button's place on screen, in prompt widths from the middle (-1 left, 0 middle, 1 right).
	Fixed per action, so a thumb learns them, and laid out so the spot a tap hit is empty after it
	(Open's middle spot is gone while it opens; Slam's right spot while it falls) and a double tap
	can't fire something else. Peek and Close share the left spot as a toggle: tap to peek, tap
	again to drop it.
]]
Door.Slots = {
	Peek = -1,
	Open = 0,
	Close = -1,
	Slam = 1,
	Lift = 0,
	Cut = 1,
	Lock = 1,
} :: { [Action]: number }

-- What each action plays.
local MOTIONS: { [Action]: Motion.Kind } = {
	Peek = "Peek",
	Open = "Open",
	Close = "Close",
	Slam = "Slam",
	Lift = "LiftInside",
}

-- A door counts as shut below this rise (studs), and as open within it of the top.
local SHUT = 0.05

-- What the hall-side buttons offer in each state, left to right.
local HALL: { [State]: { Action } } = {
	Closed = { "Peek", "Open" },
	Peeking = { "Close", "Open", "Slam" },
	Opening = { "Close", "Slam" },
	Lifting = {},
	Open = { "Close", "Slam" },
	Closing = { "Open", "Slam" },
	Slamming = {},
	Locked = { "Open", "Cut" },
}
-- And the button inside, against the door: only Lift, only while it's down.
local INSIDE: { [State]: { Action } } = {
	Closed = { "Lift" },
	Peeking = { "Lift" },
	Locked = { "Lift" },
}
local NOTHING: { Action } = {}

-- Actions that work from inside as well as from the hall: the door is up, so both reach it.
local EITHER_SIDE: { [State]: true } = { Opening = true, Open = true, Closing = true }

local REFUSED: Verdict = { ok = false }

local function carries(tools: Tools, tool: Tool): boolean
	return if tool == "BoltCutters" then tools.BoltCutters else tools.Padlock
end

local function refuse(refusal: string, motion: Motion.Kind?): Verdict
	return { ok = false, refusal = refusal, motion = motion }
end

-- The door's state now: its motion (kind, from, to, seconds since it started) and its padlock.
function Door.stateOf(
	kind: Motion.Kind,
	from: number,
	to: number,
	elapsed: number,
	fullStroke: number,
	locked: boolean
): State
	if locked then
		return "Locked"
	end
	if elapsed < Motion.duration(kind, from, to, fullStroke) then
		if kind == "Slam" then
			return "Slamming"
		elseif kind == "LiftInside" then
			return "Lifting"
		elseif kind == "Peek" then
			return "Peeking"
		elseif kind ~= "Rattle" then
			return if to > from then "Opening" else "Closing"
		end
	end
	if to < SHUT then
		return "Closed"
	elseif to >= fullStroke - SHUT then
		return "Open"
	end
	return "Peeking"
end

-- The buttons shown at the door's hall-side point or its inside point, left to right.
function Door.offers(state: State, point: Side): { Action }
	local list = if point == "Hall" then HALL[state] else INSIDE[state]
	return list or NOTHING
end

-- The state an action puts the door in as it starts.
function Door.after(action: Action): State
	if action == "Peek" then
		return "Peeking"
	elseif action == "Open" then
		return "Opening"
	elseif action == "Close" then
		return "Closing"
	elseif action == "Slam" then
		return "Slamming"
	elseif action == "Lift" then
		return "Lifting"
	elseif action == "Lock" then
		return "Locked"
	end
	return "Closed" -- Cut: the padlock's off and the door still down
end

--[[
	Whether a player standing on `side` may do `action` to a door in `state`, carrying `tools`,
	and what happens: the motion to play, the padlock going on or off, or the refusal to show.
]]
function Door.decide(state: State, action: Action, side: Side, tools: Tools): Verdict
	local inHall = side == "Hall"
	if state == "Locked" then
		if action == "Cut" and inHall then
			if not carries(tools, "BoltCutters") then
				return refuse("Need bolt cutters")
			end
			return { ok = true, lock = false }
		elseif (action == "Open" or action == "Peek") and inHall then
			return refuse("Padlocked", "Rattle")
		elseif action == "Lift" and not inHall then
			return refuse("Padlocked", "Rattle")
		end
		return REFUSED
	end
	if action == "Lock" then
		if not inHall then
			return REFUSED
		elseif state ~= "Closed" then
			return refuse("Shut it first")
		elseif not carries(tools, "Padlock") then
			return refuse("Need a padlock")
		end
		return { ok = true, lock = true }
	end
	if action == "Lift" then
		if not inHall and (state == "Closed" or state == "Peeking") then
			return { ok = true, motion = "LiftInside" }
		end
		return REFUSED
	end
	if state == "Lifting" and (action == "Close" or action == "Slam") and inHall then
		return refuse("Being lifted")
	end
	if not inHall and not EITHER_SIDE[state] then
		return REFUSED
	end
	if table.find(HALL[state], action) == nil then
		return REFUSED
	end
	return { ok = true, motion = MOTIONS[action] }
end

return Door
