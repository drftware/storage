--!strict
-- lune run tests/door.spec
local Door = require("../src/shared/StorageUnit/Door")
local Motion = require("../src/shared/StorageUnit/Motion")
local WorldButton = require("../src/shared/WorldButton")

local FULL, PEEK = 7.65, 1.15
local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local NONE: Door.Tools = { BoltCutters = "None", Padlock = "None" }
local BOTH: Door.Tools = { BoltCutters = "Hand", Padlock = "Hand" }
local STOWED: Door.Tools = { BoltCutters = "Slot", Padlock = "Slot" }

local function has(list: { Door.Action }, action: Door.Action): boolean
	return table.find(list, action) ~= nil
end

-- --- the door's state from its motion -------------------------------------------------------

local function stateAt(kind: Motion.Kind, from: number, to: number, elapsed: number): Door.State
	return Door.stateOf(kind, from, to, elapsed, FULL, false)
end
ok(Door.stateOf("Close", 0, 0, 0, FULL, false) == "Closed", "a door that never moved is closed")
ok(stateAt("Peek", 0, PEEK, 0.5) == "Peeking", "peeking while it lifts a foot")
ok(stateAt("Peek", 0, PEEK, 5) == "Peeking", "and once it's there")
ok(stateAt("Open", 0, FULL, 1) == "Opening", "opening on the way up")
ok(stateAt("Open", 0, FULL, 5) == "Open", "open at the top")
ok(stateAt("Open", PEEK, FULL, 0.5) == "Opening", "opening from a peek")
ok(stateAt("Close", FULL, 0, 1) == "Closing", "closing on the way down")
ok(stateAt("Close", FULL, 0, 5) == "Closed", "closed once down")
ok(stateAt("Slam", FULL, 0, 0.1) == "Slamming", "slamming while it falls")
ok(stateAt("Slam", FULL, 0, 0.45) == "Slamming", "and while it bounces")
ok(stateAt("Slam", FULL, 0, 2) == "Closed", "closed once it settles")
ok(stateAt("LiftInside", 0, FULL, 3) == "Lifting", "lifting from inside")
ok(stateAt("LiftInside", 0, FULL, 7) == "Open", "open once lifted")
ok(stateAt("Rattle", 0, 0, 0.2) == "Closed", "a rattle leaves the door where it was")
ok(Door.stateOf("Open", 0, FULL, 0.5, FULL, true) == "Locked", "the padlock wins over any motion")
ok(Door.stateOf("Rattle", 0, 0, 0.2, FULL, true) == "Locked", "a padlocked door rattling is locked")

-- --- every state, action and side -----------------------------------------------------------

for _, state in Door.States do
	for _, side in Door.Sides do
		local offered = Door.offers(state, side)
		for _, action in offered do
			-- an offered button always answers: it acts, or says why not
			for _, tools in { NONE, BOTH } do
				local v = Door.decide(state, action, side, tools)
				ok(
					v.ok or v.refusal ~= nil,
					`{state}, {side}: {action} offered but refused silently`
				)
				ok(
					not v.ok or v.motion ~= nil or v.lock ~= nil,
					`{state}: {action} ok but does nothing`
				)
			end
			-- no two buttons crowd each other: on one spot, at least a step apart across the row
			local spot, at = Door.place(state, action)
			for _, other in offered do
				local otherSpot, otherAt = Door.place(state, other)
				if other ~= action and otherSpot == spot then
					ok(
						math.abs(at - otherAt) >= 1 - 1e-9,
						`{state}, {side}: {action} and {other} crowd one spot`
					)
				end
			end
		end
		for _, action in Door.Actions do
			local v = Door.decide(state, action, side, BOTH)
			-- an action no button offers never moves the door (a stale tap or an exploit)
			local shown = has(Door.offers(state, "Hall"), action)
				or has(Door.offers(state, "Inside"), action)
			if not shown then
				ok(not v.ok, `{state}, {side}: {action} acts though not offered`)
			end
			-- refusals are a headline, never a sentence
			if v.refusal then
				local words = #string.split(v.refusal, " ")
				ok(words <= 3, `{state}: refusal "{v.refusal}" is short`)
			end
		end
	end
end

-- the thumb: after a tap, the place it hit holds nothing else, so a double tap can't misfire. A
-- phone's chip takes taps within its target (`TouchChip` and `Hit` all round), so another chip on
-- the same spot must sit at least that far across.
local TARGET = (WorldButton.TouchChip + 2 * WorldButton.Hit) / Door.Step -- in steps
for _, state in Door.States do
	for _, action in Door.offers(state, "Hall") do
		local v = Door.decide(state, action, "Hall", BOTH)
		if v.ok then
			local spot, at = Door.place(state, action)
			local next = Door.after(action)
			for _, other in Door.offers(next, "Hall") do
				local otherSpot, otherAt = Door.place(next, other)
				-- a held button can't be fired by a second tap
				if otherSpot == spot and not Door.Holds[other] then
					ok(
						math.abs(otherAt - at) >= TARGET - 1e-9,
						`{state}: {action} then {other} under the same thumb`
					)
				end
			end
		end
	end
end

-- the owner's layout: Open in the middle and Peek low on a shut door, Close and Slam side by side
-- in the middle of an open one, the padlock's and the cutters' buttons on the latch
local function placed(state: Door.State, action: Door.Action): string
	local spot, at = Door.place(state, action)
	return `{spot} {at}`
end
ok(placed("Closed", "Open") == "Middle 0", "a shut door: Open in the middle")
ok(placed("Closed", "Peek") == "Low 0", "and Peek low")
ok(placed("Open", "Close") == "Middle -0.5", "an open door: Close left of the middle")
ok(placed("Open", "Slam") == "Middle 0.5", "and Slam beside it")
ok(placed("Closed", "Lock") == "Latch 0", "Lock on the latch")
ok(placed("Locked", "Cut") == "Latch 0", "Cut on the latch")
ok(placed("Closed", "Lift") == "Inside 0", "Lift inside")
-- side by side: Close's verb ends before Slam's chip starts, on a phone
ok(Door.Step >= WorldButton.TouchChip + WorldButton.Gap + 50 + 8, "a step fits a chip and a verb")

-- --- the GDD's rules ------------------------------------------------------------------------

local function offers(state: Door.State): { Door.Action }
	return Door.offers(state, "Hall")
end
ok(has(offers("Closed"), "Peek") and has(offers("Closed"), "Open"), "a shut door: peek or open")
ok(has(offers("Closed"), "Lock"), "or padlock it (the button shows only to a padlock in hand)")
ok(not has(offers("Peeking"), "Lock"), "not while it's up a foot")
ok(not has(offers("Closed"), "Close") and not has(offers("Closed"), "Slam"), "nothing to shut")
ok(
	not has(offers("Open"), "Open") and not has(offers("Opening"), "Open"),
	"no Open on an open door"
)
ok(has(offers("Open"), "Slam") and has(offers("Open"), "Close"), "an open door slams or closes")
ok(has(offers("Peeking"), "Slam"), "a peek can be slammed")
ok(has(offers("Closing"), "Open") and has(offers("Closing"), "Slam"), "a closing door turns back")
ok(#offers("Slamming") == 0, "a slam is instant: nothing to press")
ok(#offers("Lifting") == 0, "nothing to press while a friend lifts it")

-- lift from inside: only when shut (GDD: always possible, so a slammed friend is never stuck)
for _, state in Door.States do
	local inside = Door.offers(state, "Inside")
	local shut = state == "Closed" or state == "Peeking" or state == "Locked"
	ok(has(inside, "Lift") == shut, `{state}: Lift inside only when shut`)
	ok(#inside <= 1, `{state}: inside offers only Lift`)
end
local lift = Door.decide("Closed", "Lift", "Inside", NONE)
ok(lift.ok and lift.motion == "LiftInside", "lift from inside heaves it open")
ok(not Door.decide("Closed", "Lift", "Hall", NONE).ok, "nobody lifts from inside while outside")
ok(not Door.decide("Closed", "Open", "Inside", NONE).ok, "nobody opens from the hall while inside")
local held = Door.decide("Lifting", "Slam", "Hall", NONE)
ok(not held.ok and held.refusal == "Being lifted", "a friend lifting it can't be slammed shut")
ok(Door.decide("Open", "Slam", "Inside", NONE).ok, "shut yourself in to hide")
ok(Door.decide("Open", "Close", "Inside", NONE).ok, "or pull it down quietly")

-- the padlock: a tried door rattles; bolt cutters cut it; a padlock needs the door shut
for _, action in { "Open", "Peek" } :: { Door.Action } do
	local v = Door.decide("Locked", action, "Hall", BOTH)
	ok(not v.ok and v.motion == "Rattle", `a padlocked door rattles on {action}`)
	ok(v.refusal == "Padlocked", `and says Padlocked on {action}`)
end
local trapped = Door.decide("Locked", "Lift", "Inside", BOTH)
ok(not trapped.ok and trapped.motion == "Rattle", "a padlocked door rattles from inside too")
ok(trapped.refusal == "Saw a wall", "and names the way out that's yours, not the padlock")
local noCutters = Door.decide("Locked", "Cut", "Hall", NONE)
ok(not noCutters.ok and noCutters.refusal == "Need bolt cutters", "no cutters names the fix")
local stowed = Door.decide("Locked", "Cut", "Hall", STOWED)
ok(not stowed.ok and stowed.refusal == "Hold the cutters", "cutters in the other slot: hold them")
ok(Door.decide("Closed", "Lock", "Hall", STOWED).refusal == "Hold the padlock", "and the padlock")
local cutOnly: Door.Tools = { BoltCutters = "Hand", Padlock = "Slot" }
ok(Door.decide("Locked", "Cut", "Hall", cutOnly).ok, "the cutters in hand cut, whatever else")
ok(not Door.decide("Closed", "Lock", "Hall", cutOnly).ok, "but a padlock must be in hand to lock")
for _, a in { "Cut", "Lock" } :: { Door.Action } do
	ok(Door.Holds[a] == true, `{a} is held, not tapped`)
end
local cut = Door.decide("Locked", "Cut", "Hall", BOTH)
ok(cut.ok and cut.lock == false, "bolt cutters take the padlock off")
ok(Door.after("Cut") == "Closed", "a cut door is shut and free")
local lock = Door.decide("Closed", "Lock", "Hall", BOTH)
ok(lock.ok and lock.lock == true, "a padlock goes on a shut door")
ok(Door.decide("Closed", "Lock", "Hall", NONE).refusal == "Need a padlock", "no padlock names it")
ok(Door.decide("Open", "Lock", "Hall", BOTH).refusal == "Shut it first", "an open door can't lock")
ok(not Door.decide("Closed", "Lock", "Inside", BOTH).ok, "the padlock hangs outside")
ok(not Door.decide("Closed", "Cut", "Hall", BOTH).ok, "nothing to cut on a free door")

-- every motion it asks for is one the door can play
for _, state in Door.States do
	for _, action in Door.Actions do
		for _, side in Door.Sides do
			local v = Door.decide(state, action, side, BOTH)
			ok(v.motion == nil or Motion.isKind(v.motion), `{state}: {action} plays a real motion`)
		end
	end
end

print(string.format("door: %d checks, %d failures", checks, failures))
if failures > 0 then
	error("door spec failed")
end
