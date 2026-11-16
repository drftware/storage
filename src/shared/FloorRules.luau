--!strict
--[[
	The floor rules (S4-01a, GDD "Floor rules"): one table that says, for any floor number, how big
	the floor is, how many doors and notes it has, how many start padlocked, how many monsters can
	be loose at once and how many of its units are packed. The climb has no top floor, so every
	answer holds from floor 1 to 100 and past: a value that grows with the floor stops at its most,
	as Dandy's World's floors grow harder up to a point and then hold. Here the last step is floor
	25's (S4-01b): above it only the slow curves still rise (what a floor pays, its finds, how soon
	sleepers wake, the packed share).

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
export type Plan = "Short" | "Full" | "Big"

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
	-- How many of the notes lie behind a padlock (GDD "Codes"), always fewer than the notes: one
	-- makes the cutters something a team needs, two makes a team plan for two ways through.
	lockedNotes: number,
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
	lockedNotes: number?,
	awake: number?,
}

-- The steps, lowest floor first. The first sets every field. Each names the hit game it comes
-- from and the moment it makes; `OWNER.md` says what to feel on each step's first floor.
FloorRules.Steps = {
	{
		from = 1,
		name = "Learning the doors", -- short floors, two notes, one monster loose at a time
		teaching = true,
		plan = "Short",
		units = 30, -- of about 60 the short plan's halls have room for: half the doors, each a pick
		notes = 2,
		padlocks = 0.06, -- about 2 of 30 doors: you meet a padlock, you rarely need one
		lockedNotes = 0,
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
		lockedNotes = 1,
	},
	{
		-- More to search before the code is in, as Dandy's World asks for more machines higher up:
		-- the four notes hide among more doors, so the floor runs longer and the monsters have
		-- longer to find you. The blank stretches of wall get shorter.
		from = 8,
		name = "More doors",
		units = 50, -- of about 80: five doors in eight, the most the full plan keeps
		padlocks = 0.15, -- about 8 of 50
	},
	{
		-- A fourth monster can be out, as Dandy's World sends more Twisteds onto higher floors (and
		-- Left 4 Dead's director allows more specials as it ramps): a hall is rarely empty, and
		-- you hide from one while you hear another.
		from = 10,
		name = "Four loose",
		awake = 4,
	},
	{
		-- A bigger building, as Lethal Company's harder moons hold bigger facilities: the far wing
		-- is a long way from the elevator, and the last friend's sprint for the gate is longer.
		from = 12,
		name = "Big floors",
		plan = "Big",
		units = 60, -- of about 100 the big plan's halls have room for: a little over half
	},
	{
		-- Two of the four notes behind padlocks: the same lock as floor 6, twice, so the team needs
		-- two ways through (cutters and a saw, or cutters twice), as Piggy's way out wants more
		-- than one tool found first.
		from = 15,
		name = "Two notes behind padlocks",
		lockedNotes = 2,
		padlocks = 0.18, -- about 11 of 60: locked doors become a common sight
	},
	{
		-- The big floors fill in: more doors on the same long halls, as Dandy's World keeps adding
		-- machines. Every hall has doors, so there's nowhere to stand that isn't next to one.
		from = 20,
		name = "More doors still",
		units = 70, -- of about 100: seven in ten
		padlocks = 0.2, -- about 14 of 70
	},
	{
		-- The most a phone carries (`Waking.AwakeMost`, 6, leaves room for one more pounding behind
		-- a door). From here every floor is as hard as the climb gets; only its pay and its finds
		-- keep rising, as Dandy's World's floors hold once they're at their hardest.
		from = 25,
		name = "Five loose",
		awake = 5,
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
	local lockedNotes: number? = first.lockedNotes
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
		lockedNotes = s.lockedNotes or lockedNotes
		awake = s.awake or awake
	end
	assert(
		teaching ~= nil
			and plan ~= nil
			and units ~= nil
			and notes ~= nil
			and padlocks ~= nil
			and lockedNotes ~= nil
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
		lockedNotes = lockedNotes,
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
