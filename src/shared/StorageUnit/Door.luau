--!strict
--[[
	Door: the GDD's door ("Doors") as a state machine. Pure, so Lune checks every state, action and
	side; the server's Doors system asks it before moving any door, and shows only what it offers.

	The door's state comes from what it's doing (its Motion) and its padlock:

		Closed    down and still; the building can't see in
		Peeking   lifted a foot, or on its way there
		Opening   rising for the full reveal
		Lifting   heaved up from inside (6 s), or burst up by a keeper trapped inside: nobody
		          outside can shut it meanwhile
		Open      up at the stop bolts
		Closing   pulled down by hand
		Slamming  falling and bouncing; over in half a second
		Locked    padlocked shut: tried, it rattles against the bolt; bolt cutters take it off

	What a player can do depends on where they stand: in the hall, or inside the unit.

		Peek, Open           from the hall, on a shut door
		Close, Slam          on a door that's up, from either side (shut yourself in to hide)
		Lift                 from inside, on a shut door: always possible unless padlocked,
		                     when it rattles and says "Saw a wall"
		Cut                  bolt cutters on a padlock, from the hall, the cutters in your hand
		Lock                 a padlock on a shut door, from the hall, the padlock in your hand

	A tool works only in your hand, as Lethal Company's do: one in your other slot gets "Hold the
	cutters", not "Need bolt cutters". A refusal the player can see says why in a word or
	three ("Padlocked", "Need a padlock"). An ask the door never offered (a stale tap, an exploit)
	is refused silently.
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
-- Where a player has a tool: in their hand, in their other slot, or nowhere.
export type Holding = "Hand" | "Slot" | "None"
export type Tools = { BoltCutters: Holding, Padlock: Holding }

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
	Where on the door each button sits, where your hand would go (the owner's layout, L-19b):
	- Middle, at the door's middle: Open, and Close and Slam side by side.
	- Low, by the ground at the lift handle: Peek, as you'd crouch and lift it a foot.
	- Latch, on the padlock at the door's bottom corner: the padlock's Lock and the cutters' Cut.
	- Inside, just behind a shut door: Lift, for someone shut in.
]]
export type Spot = "Middle" | "Low" | "Latch" | "Inside"
Door.Spots = { "Middle", "Low", "Latch", "Inside" } :: { Spot }

local SPOT: { [Action]: Spot } = {
	Peek = "Low",
	Open = "Middle",
	Close = "Middle",
	Slam = "Middle",
	Cut = "Latch",
	Lock = "Latch",
	Lift = "Inside",
}

-- Screen points between neighbours' centres in the middle row (the server's `UIOffset`): a chip
-- and a short verb, with a little air before the next chip.
Door.Step = 130

--[[
	The middle row in each state, in steps from the door's middle (-1 left, 1 right): one button
	alone sits in the middle; Close and Slam side by side, half a step each way; three in a row a
	whole step apart. Laid out so the place a tap hit is empty after it (Open's middle is empty
	while the door rises, Close's left while it falls), so a double tap can't fire something else.
]]
local ROW: { [State]: { [Action]: number } } = {
	Closed = { Open = 0 },
	Peeking = { Close = -1, Open = 0, Slam = 1 },
	Opening = { Close = -0.5, Slam = 0.5 },
	Open = { Close = -0.5, Slam = 0.5 },
	Closing = { Open = 0, Slam = 1 },
	Locked = { Open = 0 },
}

-- Where `action`'s button sits while the door is in `state`: its spot on the door, and its place
-- across the middle row in steps (0 anywhere else).
function Door.place(state: State, action: Action): (Spot, number)
	local row = ROW[state]
	return SPOT[action], row and row[action] or 0
end

-- The buttons you hold rather than tap (a tool at work takes a moment), so a double tap on the
-- spot can't fire them: Lock and then Cut share the latch.
Door.Holds = { Cut = true, Lock = true } :: { [Action]: true }

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

-- Every door button carries this tag, so a screen can hide them all at once: lying up on the
-- tops, the door below is in a button's reach but never yours to use (L-16b1).
Door.ButtonTag = "DoorButton"

-- What a padlocked door says to someone trying to lift it from inside.
Door.ShutIn = "Saw a wall"

-- What the hall-side buttons offer in each state, left to right.
local HALL: { [State]: { Action } } = {
	Closed = { "Peek", "Open", "Lock" },
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

-- The refusal for a tool not in hand: hold it if it's in your other slot, else find one.
local function missing(tools: Tools, tool: Tool): string?
	local holding = if tool == "BoltCutters" then tools.BoltCutters else tools.Padlock
	if holding == "Hand" then
		return nil
	elseif tool == "BoltCutters" then
		return if holding == "Slot" then "Hold the cutters" else "Need bolt cutters"
	end
	return if holding == "Slot" then "Hold the padlock" else "Need a padlock"
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
		if kind == "Slam" or kind == "Drop" then
			return "Slamming"
		elseif kind == "LiftInside" or kind == "Burst" then
			return "Lifting" -- a trapped keeper's burst too: nobody outside can pull it back down
		elseif kind == "Peek" then
			return "Peeking"
		elseif kind ~= "Rattle" and kind ~= "Bang" then -- a rattle or a bang leaves it where it was
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
			local need = missing(tools, "BoltCutters")
			if need then
				return refuse(need)
			end
			return { ok = true, lock = false }
		elseif (action == "Open" or action == "Peek") and inHall then
			return refuse("Padlocked", "Rattle")
		elseif action == "Lift" and not inHall then
			-- the button already reads "Padlocked" and the padlock is on the hall side, out of
			-- reach: say the way out that's yours, a saw through a side wall (a friend's cutters
			-- are the other)
			return refuse(Door.ShutIn, "Rattle")
		end
		return REFUSED
	end
	if action == "Lock" then
		if not inHall then
			return REFUSED
		elseif state ~= "Closed" then
			return refuse("Shut it first")
		end
		local need = missing(tools, "Padlock")
		if need then
			return refuse(need)
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
