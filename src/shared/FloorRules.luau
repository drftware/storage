--!strict
--[[
	The floor rules (S4-01a, GDD "Floor rules"): one table that says, for any floor number, how big
	the floor is, how many doors and notes it has, how many start padlocked, how many monsters can
	be loose at once and how many of its units are packed. The climb has no top floor, so every
	answer holds from floor 1 to 100 and past: a value that grows with the floor stops at its most,
	as Dandy's World's floors grow harder up to a point and then hold.

	Two kinds of rule:
	- **Steps** (`Steps`): a change that lands on one floor and stays, each named for what players
	  meet there ("Full size" on floor 3). A step sets only what it names; the rest carries on from
	  the steps below. A new kind of floor is a new step.
	- **Curves**: a share that grows a little every floor up to its most (`packed`).

	Other per-floor curves live with what they drive, each proved to hold far up by its own spec:
	when sleeping monsters wake (`Waking`), what a floor pays (`Pay`), how keen a Mannequin is on the
	breaker (`Breaker`), how rare its finds are (`Grades`) and the floor each monster joins on
	(`Deal.Keepers`, `Deal.Packrat`). `tests/floorrules.spec` checks them all together from floor
	1 to 300.

	Every number is a feel number with what it does to the player. The server deals every floor
	from these (`Floor`, `Deal`); nothing here reaches the screen.
]]
local FloorRules = {}

-- A floor plan by name: Floor's `Plans` hold what each looks like (halls, loops, how it winds).
export type Plan = "Short" | "Full"

-- Everything the rules say about one floor.
export type Rules = {
	number: number, -- the floor, 1 and up
	step: string, -- the name of the last step that changed something by this floor
	-- Floors that teach the lights, the doors and the hole trap (GDD "The building"): the lobby's
	-- hall holds no monsters and nothing packed, the first tool out of the bag is a saw, and the
	-- faint mark is always there to meet.
	teaching: boolean,
	plan: Plan, -- how big the floor is and how it reads (Floor's `Plans`)
	-- About how many doors the floor keeps of the ones its halls have room for (GDD "Doors": fewer
	-- units). Fewer makes each door a choice and leaves stretches of blank wall to be chased down.
	units: number,
	-- The code's notes: the code's four digits split across them (two digits each on two notes, so
	-- they go fast; one each on four, so a team splits up to find them).
	notes: number,
	-- The share of the floor's units that start padlocked: a few while you learn the doors, more
	-- once a pair of bolt cutters is worth carrying.
	padlocks: number,
	-- One note lies behind a padlock (GDD "Codes"): the cutters become something a team needs.
	padlockedNote: boolean,
	-- The most monsters loose at once (GDD "The director": each band caps them; the tech plan caps
	-- them for low-end phones). Past it a monster is dealt asleep instead, so a door is as risky but
	-- the hall isn't flooded, as Left 4 Dead's director caps its specials.
	awake: number,
	-- The share of medium units packed with somebody's things (B-05b1): more higher up.
	packed: number,
}

-- One step up the climb: from floor `from`, what changes. Each field it leaves out carries on.
export type Step = {
	from: number,
	name: string,
	teaching: boolean?,
	plan: Plan?,
	units: number?,
	notes: number?,
	padlocks: number?,
	padlockedNote: boolean?,
	awake: number?,
}

-- The steps, lowest floor first. The first sets every field.
FloorRules.Steps = {
	{
		from = 1,
		name = "Learning the doors", -- short floors, two notes, one monster loose at a time
		teaching = true,
		plan = "Short",
		units = 30, -- of about 60 the short plan's halls have room for: half the doors, each a pick
		notes = 2,
		padlocks = 0.06, -- about 2 of 30 doors: you meet a padlock, you rarely need one
		padlockedNote = false,
		awake = 1,
	},
	{
		from = 3,
		name = "Full size", -- half as many halls again, four notes, a second monster loose
		teaching = false,
		plan = "Full",
		units = 40, -- of about 80: half, as below, over halls half as long again
		notes = 4,
		padlocks = 0.12, -- about 5 of 40: the bolt cutters start to earn their slot
		awake = 2,
	},
	{
		from = 5,
		name = "Three loose", -- a third monster can be out: the halls stop feeling safe
		awake = 3,
	},
	{
		from = 6,
		name = "A note behind a padlock", -- the code needs bolt cutters, or a saw through the side
		padlockedNote = true,
	},
} :: { Step }

-- The share of medium units packed on floor 1: about one in three.
FloorRules.PackedFirst = 0.3
-- More each floor up, so floor 6 is about two in five.
FloorRules.PackedRise = 0.02
-- Never more than half: an open door must still be the usual.
FloorRules.PackedMost = 0.5

-- Each floor's rules once worked out, by number (a floor's rules never change in a server).
local known: { [number]: Rules } = {}

-- The rules for floor `number` (1 and up; anything lower counts as floor 1). The same table every
-- time for a floor, frozen: read it, never change it.
function FloorRules.at(number: number): Rules
	local n = math.max(1, math.floor(number))
	local already = known[n]
	if already then
		return already
	end
	local first = FloorRules.Steps[1]
	local step: string = first.name
	local teaching: boolean? = first.teaching
	local plan: Plan? = first.plan
	local units: number? = first.units
	local notes: number? = first.notes
	local padlocks: number? = first.padlocks
	local padlockedNote: boolean? = first.padlockedNote
	local awake: number? = first.awake
	for _, s in FloorRules.Steps do
		if s.from > n then
			break
		end
		step = s.name
		if s.teaching ~= nil then
			teaching = s.teaching
		end
		plan = s.plan or plan
		units = s.units or units
		notes = s.notes or notes
		padlocks = s.padlocks or padlocks
		if s.padlockedNote ~= nil then
			padlockedNote = s.padlockedNote
		end
		awake = s.awake or awake
	end
	assert(
		teaching ~= nil
			and plan ~= nil
			and units ~= nil
			and notes ~= nil
			and padlocks ~= nil
			and padlockedNote ~= nil
			and awake ~= nil,
		"FloorRules: the first step must set every rule"
	)
	local made: Rules = {
		number = n,
		step = step,
		teaching = teaching,
		plan = plan,
		units = units,
		notes = notes,
		padlocks = padlocks,
		padlockedNote = padlockedNote,
		awake = awake,
		packed = math.min(
			FloorRules.PackedMost,
			FloorRules.PackedFirst + FloorRules.PackedRise * (n - 1)
		),
	}
	table.freeze(made)
	known[n] = made
	return made
end

return FloorRules
