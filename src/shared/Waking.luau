--!strict
--[[
	When sleeping monsters wake (S2-03a, GDD "Sleeping monsters wake"). After the team has been on
	a floor a while, a few of the keepers still asleep behind doors nobody has lifted wake and
	pound on their doors from inside; a while later more do, and higher up it starts sooner and
	wakes more at a time. There is no clock on screen and no words: the pounding is the only sign
	that time on this floor is running out, as Left 4 Dead's director sends a horde when a team
	lingers (from memory), and a pounding one breaks out on the trapped keeper's own clock
	(`KeeperRows` `breakOut`, 90 seconds) unless its door is padlocked.

	Pure: the server's keepers' brain asks it each step how many to wake now and which.
	The numbers are feel numbers; each says what it does to the player.
]]

local FloorRules = require("./FloorRules")

local Waking = {}

-- Seconds on floors 1 and 2 before the first sleepers wake: four minutes is about a calm floor's
-- length, so a team that searches well is in the elevator before anything pounds.
Waking.First = 240
-- Each floor above 2 starts this many seconds sooner, so the pressure climbs with the building.
Waking.FirstPerFloor = 15
-- Never sooner than this: even high up you get two and a half minutes of quiet searching.
Waking.FirstLeast = 150

-- Seconds between one wave of waking and the next on floors 1 and 2: two minutes is long enough
-- to finish what you were doing, short enough that a team that ignores the first pounding hears
-- more before it's out.
Waking.Gap = 120
-- Each floor above 2 closes the gap by this many seconds.
Waking.GapPerFloor = 10
-- Never closer than this: waves never run together into one long racket.
Waking.GapLeast = 75

-- How many wake at once on floors 1 to 3: three doors pounding is enough that you can't tell
-- which, few enough that a padlock or two answers it.
Waking.Size = 3
-- One more at a time every this many floors.
Waking.SizeEvery = 3
-- Never more at once than this.
Waking.SizeMost = 5

-- The most keepers stepping on a floor at once, loose or pounding, for low-end phones (GDD tech
-- plan): past it a wave waits, and those it owes wake as room opens. Six leaves room for one
-- pounding behind a door past the director's highest cap for loose keepers (the floor rules'
-- `awake`, five from floor 25), since pounding ones stand still.
Waking.AwakeMost = 6

--- Seconds on `floor` before the first sleepers wake.
function Waking.first(floor: number): number
	local soon = Waking.First - Waking.FirstPerFloor * math.max(floor - 2, 0)
	return math.max(soon, Waking.FirstLeast)
end

--- Seconds between one wave and the next on `floor`.
function Waking.gap(floor: number): number
	local gap = Waking.Gap - Waking.GapPerFloor * math.max(floor - 2, 0)
	return math.max(gap, Waking.GapLeast)
end

--- How many sleepers wake at once on `floor`.
function Waking.size(floor: number): number
	local size = Waking.Size + (math.max(floor, 1) - 1) // Waking.SizeEvery
	return math.min(size, Waking.SizeMost)
end

--- How many sleepers should have woken on `floor` after `seconds` there: none before the first
--- wave, then a wave's `size` more every `gap`.
function Waking.owed(floor: number, seconds: number): number
	local first = Waking.first(floor)
	if seconds < first then
		return 0
	end
	local waves = 1 + (seconds - first) // Waking.gap(floor)
	return waves * Waking.size(floor)
end

--- How many sleepers to wake now on `floor`, `seconds` after the team arrived: what's owed less
--- those already `woken`, no more than are still `left` asleep behind shut doors, and never past
--- `AwakeMost` with `awake` keepers already stepping there (loose or pounding).
function Waking.now(
	floor: number,
	seconds: number,
	woken: number,
	awake: number,
	left: number
): number
	local due = Waking.owed(floor, seconds) - woken
	local room = Waking.AwakeMost - awake
	return math.max(math.min(due, room, left), 0)
end

--[[
	Whether one a wave woke may burst out of its unit now, at its time (S2-07a2): only while the
	floor's `loose` keepers and the woken ones `ahead` of it (shut in longer, or already bursting)
	leave room under the deal's cap on loose keepers (the floor rules' `awake`). Else it pounds on past its
	time (`Keeper.hold`), and the longest shut in is the first out when a place opens. So a wave
	never sets more loose than the floor allows, as Left 4 Dead's director holds a special back
	until one of its places is free (from memory). Held, it pounds until its time as ever, then
	falls quiet behind its door (`Keeper.hold`) until it bursts out. Waking stays capped by `AwakeMost` above (pounding ones stand
	still); this caps only the ones a wave sets loose.
]]
function Waking.free(floor: number, loose: number, ahead: number): boolean
	return loose + ahead < FloorRules.at(floor).awake
end

--- Which of the `slots` (units with a sleeper behind a door never lifted) wake: `n` of them, each
--- picked by `roll(k)`, which returns a whole number from 1 to k. Any slot is as likely as any
--- other, so the team never learns which door goes first. A new list; `slots` is untouched.
function Waking.pick(slots: { number }, n: number, roll: (number) -> number): { number }
	local pool = table.clone(slots)
	local picked = table.create(math.min(n, #pool))
	for _ = 1, math.min(n, #pool) do
		local i = roll(#pool)
		table.insert(picked, pool[i])
		pool[i] = pool[#pool]
		pool[#pool] = nil
	end
	return picked
end

return Waking
