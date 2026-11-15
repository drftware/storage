--!strict
--[[
	Deal: what's behind each door (L-04d), the rules alone. Every door is a gamble: the next one
	could hold the saw you need, nothing, or something that's been waiting. Nothing here touches an
	Instance, so Lune tests it (tests/deal.spec.luau); L-04e lays the deal on the floor.

	Two moments, as the GDD's "What's behind the door" splits them:
	- When a floor is laid (`Deal.new`), the search is made real: the floor's code, the notes that
	  carry it, spread across the floor, which doors start padlocked, which note is guarded, and
	  the keepers asleep in their units (S2-01), there before anyone touches a door, so one can
	  wake behind a shut door or be let out by a wrong code, as Left 4 Dead's Witch is already
	  sitting in her spot, asleep, before the team turns the corner.
	- When a door first lifts, a peek or an open (`Deal.open`), the director deals the rest: a tool,
	  nothing, a find, or a keeper awake, the odds set by its mood; a unit with a sleeper hands it
	  back. Left 4 Dead's director paces a run the same way, placing items and infected as the team
	  moves rather than up front.

	Each unit's own roll is drawn when the floor is laid, so the same seed deals a unit the same
	kind of thing in the same mood whatever order the doors are opened in; only which tool comes
	out of the bag depends on the order. Odds are out of 100 and live here with what they do.
]]

local Breaker = require("./Breaker")
local Catalog = require("./Tools/Catalog")
local Floor = require("./Floor")
local Grades = require("./Grades")

type Floor = Floor.Floor
type Random = Floor.Random

export type Mood = "Build" | "Peak" | "Relief"
export type Kind = "Nothing" | "Find" | "Tool" | "Asleep" | "Awake"
export type Tool = "Saw" | "BoltCutters" | "Padlock" | "Ladder" | "BubbleWrap" | "AirHorn"

-- What the director knows when a door lifts: its mood, and how many keepers are awake now.
export type Situation = { mood: Mood, awake: number }

-- What a unit holds once dealt: a tool says which, a find which, a keeper which and whether it's
-- awake; `coins`, how many coins lie on its floor besides (0 to 3, S1-04a); `stuff`, somebody's
-- stuff standing in a unit with nothing to take (S1-04b2), a name in `Deal.Stuff`. `beside`, a
-- keeper standing in a padlocked unit with its find or tool (S1-07a): "Asleep" or "Awake", its
-- name in `keeper`. `Deal.keeperIn` reads a unit's keeper either way. `battery`, a battery lying
-- on its floor besides (S1-07b).
export type Contents = {
	kind: Kind,
	tool: Tool?,
	find: string?,
	keeper: string?,
	beside: Kind?,
	coins: number,
	stuff: string?,
	battery: boolean?,
	-- the finds of its own the Packrat sleeps among (S2-06b2b), names in `Deal.Finds`, laid round
	-- it; nil in any other unit
	pile: { string }?,
}

-- A note: the unit it lies in (an index into the floor's slots) and the places of the code it
-- shows, 1 to 4, in order. The note itself shows them in their slots, "_ 7 _ _" (`Deal.noteText`).
export type Note = { slot: number, places: { number } }

export type Deck = {
	floor: Floor,
	code: { number }, -- the four digits, 0 to 9
	notes: { Note },
	padlocked: { [number]: boolean }, -- by slot index
	firstHall: { [number]: boolean }, -- the units in the lobby's hall, by slot index
	rolls: { [number]: number }, -- each unit's roll for what kind of thing it holds, 0 to 1
	picks: { [number]: number }, -- each unit's roll for which find or keeper, 0 to 1
	dealt: { [number]: Contents }, -- what each unit got, once its door has lifted
	coins: { [number]: number }, -- the coins on each unit's floor, 0 to 3, by slot index
	batteries: { [number]: boolean }, -- the units with a battery on their floor, by slot index
	-- the unit of the guarded note (D-072), by slot index: it's always dealt a keeper, awake, and
	-- holds one of the floor's awake places from the floor's start (`Deal.odds`)
	guarded: number?,
	-- the note's unit whose door frame carries the floor's faint mark (S1-11), by slot index, or
	-- nil on a floor without one (`Deal.markFrom`)
	marked: number?,
	-- the keepers asleep in their units from the floor's start (S2-01), each its keeper's name by
	-- slot index: all an ordinary unit holds, or standing with a padlocked unit's find or tool.
	-- `Deal.open` hands each back as its door first lifts.
	sleepers: { [number]: string },
	-- the Packrat's pile (S2-06b2b): the finds of its own it sleeps among, by its unit's slot
	-- index (one unit at most, from floor `Deal.Packrat.from`); its name is in `sleepers` too
	piles: { [number]: { string } },
	-- where the floor's one breaker box hangs (S2-02b), or nil on a floor with nowhere outside
	-- the lobby's hall to hang it (`Breaker.spots`)
	breaker: Breaker.Spot?,
	bag: { Tool }, -- the tools left in the bag, the next one last
	random: Random,
}

local Deal = {}

local KINDS: { Kind } = { "Nothing", "Find", "Tool", "Asleep", "Awake" }
Deal.Kinds = KINDS

--[[
	The sleepers (S2-01, D-152): 10 in 100 units hold a keeper asleep, placed when the floor is
	laid, whatever the mood a door later lifts in (GDD "What changed here": the director still
	chooses coins, finds and tools as a door opens, not sleepers). Never in the guarded note's unit
	(its keeper is awake) nor in the lobby's hall on floors 1 and 2; behind a padlock, twice as
	often (`PadlockedKeeper`), standing with its find or tool.
]]
Deal.Asleep = 10

--[[
	The odds behind a door with no sleeper, out of the 90 in 100 the sleepers leave (`Asleep`), by
	the director's mood (GDD "The director"). Build, while you search, deals riskier doors: now and
	then something is awake. Peak, during a chase, wakes nothing new and leans on tools to get away
	with. Relief, after one, deals finds and lets you breathe. Until the director exists (Phase 2)
	the floor deals in Build. "Asleep" here is only what the cap turns an awake keeper into.

	Tools are rare (S1-07a, GDD "Doors": about one unit in twelve, a starting guess), so finding
	one is a good moment and the machine on the ride is where a team stocks up: 6 in 100 behind an
	ordinary door, and the padlocked doors' tools (below) bring a floor to about one in twelve.
]]
Deal.Odds = {
	Build = { Nothing = 54, Find = 25, Tool = 6, Awake = 5 },
	Peak = { Nothing = 60, Find = 15, Tool = 15, Awake = 0 },
	Relief = { Nothing = 49, Find = 35, Tool = 6, Awake = 0 },
} :: { [Mood]: { [string]: number } } -- string keys: Luau won't index by a union of words

--[[
	Behind a padlock (S1-07a, GDD "Doors"): always something good, the best chance of something
	great and the highest chance of a monster. Escape from Tarkov's locked rooms hold its best loot
	the same way, and Lethal Company's best scrap lies where its monsters are. So a padlocked unit
	never deals nothing: it holds a find or a tool, out of 100, whatever the mood (a find most
	often: the great ones, once finds have grades, ROADMAP "rarity ladder"). And a keeper may
	stand in there with it, twice as often as an ordinary door's (`PadlockedKeeper`): 20 in 100
	asleep, placed with the floor, and in Build 10 awake, the cap and the guard's place as anywhere.
	You cut the lock, the door rolls up on a boombox in the bulb's light, and behind it something
	stands in the dark.
]]
Deal.PadlockedHolds = { Find = 70, Tool = 30 } :: { [string]: number }
Deal.PadlockedKeeper = 2

-- How many keepers the deal will have awake at once, by floor (GDD "The director": each band caps
-- them; the tech plan caps them for low-end phones). Past it a keeper is dealt asleep instead, so
-- a door is as risky but the hall isn't flooded, as Left 4 Dead's director caps its specials.
function Deal.awakeCap(number: number): number
	return if number <= 2 then 1 elseif number <= 4 then 2 else 3
end

-- The keepers a door can hold, each from the floor it joins on (GDD "The building"). A keeper
-- joins this list when its ticket builds it: the Mannequin first (L-06). Dale and the Moth are
-- their floors' set pieces and are never dealt.
Deal.Keepers = {
	{ name = "Mannequin", from = 1 },
} :: { { name: string, from: number } }

--[[
	The Packrat (S2-06b2b, GDD "The monsters"): one on every floor from 3, never more, so it's not
	in `Keepers`' draw. It's placed with the floor, asleep in a unit of its own among a pile of
	two or three finds it has already carried home, as Lethal Company's Hoarding Bug sits on its
	nest of scrap: you lift a door on something tall standing among stuff that isn't yours. Never
	a note's unit (its tall body would hide the note from the doorway), a padlocked one (a lock
	shuts its way home) or another sleeper's, and always a medium unit while the floor has one: a
	small one has room at the back for it and one big find, not its pile (tests/dealspot). Its
	finds are all different, from `Deal.Finds`.
]]
Deal.Packrat = { name = "Packrat", from = 3 }
Deal.PileMin = 2
Deal.PileMax = 3

--[[
	The tools behind doors come out of a shuffled bag, as Tetris deals its pieces: every tool in a
	bag turns up before any comes round again, so a floor never starves you of bolt cutters or
	buries you in ladders. These are the counts in one bag, in a fixed order so a seed always
	shuffles the same. Only built tools: every one here has its row in `Tools.Catalog`, or its
	door would open on an empty unit (tests/carry.spec checks). No flashlight: everyone carries
	one (GDD Tools). The moving blanket and glow sticks were cut (D-091) and left the bag (L-14e).
]]
local TOOLS: { Tool } = {
	"Saw",
	"BoltCutters",
	"Padlock",
	"Ladder",
	"BubbleWrap",
	"AirHorn",
}
Deal.Tools = TOOLS
Deal.Bag = {
	Saw = 2, -- the hole trap's tool, the loop's best move
	BoltCutters = 2, -- a padlocked unit, or a friend padlocked in one
	Padlock = 2, -- keeps a trapped keeper in for the floor
	Ladder = 1, -- up onto the unit tops, out of a keeper's reach
	BubbleWrap = 1, -- a tripwire you lay behind you
	AirHorn = 1, -- one blast that draws the keepers in reach and wakes sleepers
} :: { [string]: number }

--[[
	The finds a door can hold (S1-05, F-G1a), each a catalog row with its grade, worth and the floor
	it's dealt from (`Tools.Catalog`). The 1980s bedroom set (D-035) and the finds built overnight
	on Nov 15 (art/finds/WAVES.md): the Lights, the cars and the first wind-ups. Which one a unit
	holds is `Deal.findFrom`'s roll: a grade by the floor, then a find of that grade.

	The theatre spotlight is built but not dealt: six studs tall, it's one of the catalog's big
	finds (both hands, the floor's big find behind the code door), which no floor has yet.
]]
Deal.Finds = {
	"Boombox",
	"Television",
	"Teddy",
	"Skates",
	"NightLight",
	"TeaLight",
	"DeskLamp",
	"GlowSticks",
	"FairyLights",
	"CampLantern",
	"MoonLamp",
	"BlobLamp",
	"OilLamp",
	"DiscoBall",
	"NeonSign",
	"HardHat",
	"FireflyJar",
	"StainedGlassLamp",
	"UnpluggedLamp",
	"DiecastCar",
	"RCCar",
	"CymbalMonkey",
	"JackInTheBox",
} :: { string }

--[[
	Which find a unit on floor `number` holds, from its roll `pick` (0 to 1): first a grade, by the
	floor's odds (`Grades.odds`) among the grades with a find that floor can deal, then one find
	of that grade, each as likely. `taken` (the finds already in the Packrat's pile) are left out.
	Nil only if nothing is left to deal.
]]
function Deal.findFrom(number: number, pick: number, taken: { string }?): string?
	local byGrade: { [string]: { string } } = {}
	for _, name in Deal.Finds do
		local row = Catalog[name]
		if
			row
			and row.grade
			and (row.from or 1) <= number
			and not (taken and table.find(taken, name))
		then
			local list = byGrade[row.grade] or {}
			byGrade[row.grade] = list
			table.insert(list, name)
		end
	end
	local odds = Grades.odds(number)
	local total = 0
	for _, grade in Grades.Names do
		if byGrade[grade] then
			total += odds[grade]
		end
	end
	if total <= 0 then
		return nil
	end
	local at = math.clamp(pick, 0, 1) * total
	local last: { string }? = nil
	for _, grade in Grades.Names do
		local list = byGrade[grade]
		local chance = odds[grade]
		if list and chance > 0 then
			last = list
			if at < chance then
				return list[math.min(#list, math.floor(at / chance * #list) + 1)]
			end
			at -= chance
		end
	end
	return if last then last[#last] else nil -- a pick of exactly 1
end

-- Floors 1 and 2 teach the lights, the doors and the hole trap (GDD "The building"), so on them
-- the first tool out of the bag is a saw, and the lobby's hall deals no keepers: your first doors
-- teach you to open them before one bites (the director's breathing room, GDD).
Deal.TeachingFloors = 2

--[[
	Coins (S1-04a): about seven units in ten have one to three coins lying on the floor (GDD
	"Doors", a starting guess), as DOORS has gold in most of its drawers but not all: most doors
	pay something, so every door is worth the noise of opening it, and an empty one stings. A
	unit's coins are its own draw, beside whatever else it holds (a tool, a find, a note, a
	keeper). Whoever taps them first takes them.
]]
Deal.CoinShare = 0.7 -- the share of units with coins on the floor
-- Of the units with coins, how many lie there, out of 100: one most often, three a little treat.
-- About 1.75 a paying unit, so about 37 on a floor 1 of 30 units if every door is opened.
Deal.CoinSpread = { 45, 35, 20 } :: { number }

-- How many coins a unit holds from its two draws, each 0 to 1: `share` against CoinShare, then
-- `spread` across CoinSpread.
function Deal.coinsFrom(share: number, spread: number): number
	if share >= Deal.CoinShare then
		return 0
	end
	local total = 0
	for _, weight in Deal.CoinSpread do
		total += weight
	end
	local at = spread * total
	for count, weight in Deal.CoinSpread do
		if at < weight then
			return count
		end
		at -= weight
	end
	return #Deal.CoinSpread
end

--[[
	Batteries (S1-07b): about one unit in ten has a battery lying on its floor (GDD "Your
	flashlight", the owner's default), as DOORS hides batteries in its drawers: often enough that a
	dying torch sends you opening doors, rare enough that finding one is a moment. A unit's battery
	is its own draw, beside whatever else it holds, as its coins are; a unit with one holds no
	stuff (it has something to take).
]]
Deal.BatteryShare = 0.1 -- the share of units with a battery on the floor

--[[
	The faint mark (S1-11, GDD "At most one faint mark on a floor"): one note's door frame may
	carry a small chalk mark that only shows from a few steps away with your torch on it
	(FaintMark), as Phasmophobia's fingerprints show on a door only under the light you hold. The
	other notes have none and some floors have none at all, so it's a reward for sweeping your beam
	along the frames, never a trail to follow. Never on the guarded note's unit: that one already
	shows itself to a peek (the feet in the light), so the mark always points somewhere new. Floors 1
	and 2 always have one, so the first floors a team plays are where it meets the mark.
]]
Deal.MarkShare = 0.6 -- above floors 1 and 2, the share of floors with a mark (a starting guess)

-- The unit (slot index) whose door frame carries the floor's faint mark, or nil for none: on a
-- floor `number` with these `notes` and its `guarded` unit, from two draws, each 0 to 1: `share`
-- against MarkShare (floors 1 and 2 always have one), `pick` across the notes not guarded.
function Deal.markFrom(
	number: number,
	notes: { Note },
	guarded: number?,
	share: number,
	pick: number
): number?
	if number > Deal.TeachingFloors and share >= Deal.MarkShare then
		return nil
	end
	local pool: { number } = {}
	for _, note in notes do
		if note.slot ~= guarded then
			table.insert(pool, note.slot)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[math.min(#pool, math.floor(pick * #pool) + 1)]
end

--[[
	Somebody's stuff (S1-04b2, GDD "Doors"): of the units with nothing to take (no coins, battery,
	tool, find or keeper, no note), some are bare and some are full of things only there to look at, so
	even a door with nothing behind it shows you somebody's life: a stained mattress leaning on the
	back wall, boxes stacked nearly to the bulb. Lethal Company's rooms and DOORS' drawers are full
	of junk around the few things worth taking the same way; a bare one still stings.

	The stuff takes no draw of its own: it's read from the unit's pick, the roll that says which
	find or keeper a unit holds, which a unit with nothing in it never uses. So adding it moved
	nothing a seed lays or deals (tests/stuffdeal.spec checks every seed's deal against before).
]]
Deal.StuffShare = 0.5 -- of the units with nothing to take, the share with somebody's stuff
-- The things, each a name in `Stuff.Pieces` or `Stuff.Stacks` (tests/stuffdeal.spec checks), as
-- likely as each other. Deals stands the first that fits the unit from the one drawn on (a small
-- unit's crawl hole spots leave room for the rolled rug alone).
Deal.Stuff = { "Mattress", "Carpet", "Tower", "Wall", "Heap", "Column" } :: { string }

-- The stuff a unit with nothing to take holds from its pick (0 to 1), or nil for a bare unit.
function Deal.stuffFrom(pick: number): string?
	if pick >= Deal.StuffShare then
		return nil
	end
	return Deal.Stuff[math.floor(pick / Deal.StuffShare * #Deal.Stuff) + 1]
end

-- The share of a floor's units that start padlocked: a few on floors 1 and 2, where you learn the
-- doors (about 4 of 60), more above (about 10 of 80). None in the lobby's own hall: the first
-- doors you meet open, so the hole trap can be learned there.
function Deal.padlockShare(number: number): number
	return if number <= 2 then 0.06 else 0.12
end

--[[
	The code's notes (GDD "Codes"): two on floors 1 and 2 with two digits each, so they go fast;
	four above with one each. Every digit is on exactly one note. They lie past the lobby's hall,
	one to each wing in turn, so a team splits up to find them, as DOORS spreads its door-50 code
	through the library's books. Within a wing a note keeps this far (straight line) from the
	others where it can: two hall pieces.
]]
Deal.NoteSpacing = 48
-- From this floor, at least one note lies behind a padlock (GDD "Codes").
Deal.PadlockedNoteFrom = 6

function Deal.noteCount(number: number): number
	return if number <= 2 then 2 else 4
end

local function shuffle(list: { any }, random: Random) -- any: shuffles any list in place
	for i = #list, 2, -1 do
		local j = random:nextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
end

local function zoneOf(floor: Floor, index: number): string
	return floor.cells[floor.slots[index].cell].zone
end

local function distance(floor: Floor, a: number, b: number): number
	local sa, sb = floor.slots[a], floor.slots[b]
	return math.sqrt((sa.x - sb.x) ^ 2 + (sa.z - sb.z) ^ 2)
end

-- The nearest of `chosen` notes to unit `index`, in studs (huge with none chosen).
local function nearest(floor: Floor, index: number, chosen: { Note }): number
	local best = math.huge
	for _, note in chosen do
		best = math.min(best, distance(floor, index, note.slot))
	end
	return best
end

-- Units numbered from the lobby this far count as its hall on a floor with no fork, one long
-- winding hall (about 1 in 50 floors): the first doors you meet.
Deal.FirstDoors = 8

local function refill(deck: Deck)
	local bag: { Tool } = {}
	for _, tool in TOOLS do
		for _ = 1, Deal.Bag[tool] do
			table.insert(bag, tool)
		end
	end
	shuffle(bag, deck.random)
	deck.bag = bag
end

-- The name of a keeper that has joined by ``floor`, from `pick` (0 to 1), or nil if none.
local function keeperFrom(floor: Floor, pick: number): string?
	local joined = {}
	for _, keeper in Deal.Keepers do
		if keeper.from <= floor.number then
			table.insert(joined, keeper.name)
		end
	end
	return if #joined == 0 then nil else joined[math.floor(pick * #joined) + 1]
end

-- A floor's units as indexes into its slots, in number order: the order you meet them walking out
-- from the lobby.
function Deal.units(floor: Floor): { number }
	local units: { number } = {}
	for i, slot in floor.slots do
		if slot.kind == "Unit" then
			table.insert(units, i)
		end
	end
	table.sort(units, function(a: number, b: number): boolean
		return (tonumber(floor.slots[a].number) or 0) < (tonumber(floor.slots[b].number) or 0)
	end)
	return units
end

--[[
	Lays a floor's deal from its seed: `random` is a fresh Brix Random for this floor (not the one
	`Floor.generate` used up), so the deal and the layout each repeat from their seeds.
]]
function Deal.new(floor: Floor, random: Random): Deck
	local units = Deal.units(floor)

	local code = {}
	for place = 1, 4 do
		code[place] = random:nextInteger(0, 9)
	end

	-- The padlocks, past the lobby's hall (`units` is in number order: the order you meet them).
	local outside: { number } = {}
	local firstHall: { [number]: boolean } = {}
	for _, i in units do
		if zoneOf(floor, i) ~= "Lobby" then
			table.insert(outside, i)
		else
			firstHall[i] = true
		end
	end
	if #outside == 0 then
		outside = table.move(units, Deal.FirstDoors + 1, #units, 1, {})
		firstHall = {}
		for k = 1, math.min(Deal.FirstDoors, #units) do
			firstHall[units[k]] = true
		end
	end
	local lockPool = table.clone(outside)
	shuffle(lockPool, random)
	local padlocked: { [number]: boolean } = {}
	local locks =
		math.min(#lockPool, math.max(1, math.round(#units * Deal.padlockShare(floor.number))))
	for k = 1, locks do
		padlocked[lockPool[k]] = true
	end

	-- The notes: which places each shows, then a wing each in turn.
	local count = Deal.noteCount(floor.number)
	local places = { 1, 2, 3, 4 }
	shuffle(places, random)
	local per = 4 // count
	local byZone: { [string]: { number } } = {}
	local zones: { string } = {}
	for _, i in outside do
		local zone = zoneOf(floor, i)
		if not byZone[zone] then
			byZone[zone] = {}
			table.insert(zones, zone)
		end
		table.insert(byZone[zone], i)
	end
	table.sort(zones)
	shuffle(zones, random)
	local notes: { Note } = {}
	local used: { [number]: boolean } = {}
	for k = 1, count do
		local shown = table.move(places, (k - 1) * per + 1, k * per, 1, {})
		table.sort(shown)
		-- This note's wing, or the next with room: a unit there at least NoteSpacing from every
		-- note so far, at random. The padlocked note is the first, behind a padlock. With room
		-- nowhere, the unit farthest from the notes.
		local wantLock = k == 1 and floor.number >= Deal.PadlockedNoteFrom
		local pool: { number } = {}
		for z = 0, #zones - 1 do
			local zone = zones[(k - 1 + z) % #zones + 1]
			for _, i in byZone[zone] do
				if
					not used[i]
					and (not wantLock or padlocked[i])
					and nearest(floor, i, notes) >= Deal.NoteSpacing
				then
					table.insert(pool, i)
				end
			end
			if #pool > 0 then
				break
			end
		end
		local slot: number
		if #pool > 0 then
			slot = pool[random:nextInteger(1, #pool)]
		else
			local best = -1
			slot = outside[1]
			for _, i in outside do
				local d = nearest(floor, i, notes)
				if not used[i] and (not wantLock or padlocked[i]) and d > best then
					best, slot = d, i
				end
			end
		end
		used[slot] = true
		table.insert(notes, { slot = slot, places = shown })
	end

	-- Every unit's own rolls.
	local rolls: { [number]: number } = {}
	local picks: { [number]: number } = {}
	for _, i in units do
		rolls[i] = random:nextNumber()
		picks[i] = random:nextNumber()
	end

	local deck: Deck = {
		floor = floor,
		code = code,
		notes = notes,
		padlocked = padlocked,
		firstHall = firstHall,
		rolls = rolls,
		picks = picks,
		dealt = {},
		coins = {},
		batteries = {},
		bag = {},
		sleepers = {},
		piles = {},
		random = random,
	}
	--[[
		The guarded note (D-072): one note's unit always holds a keeper, awake, so no floor is
		cleared without a chase, as DOORS puts the library's code hints in the room Figure walks.
		The peek is how you find it (feet standing in the light), and a padlocked door can't be
		peeked, so the guard takes a note behind an unlocked door wherever there is one. Drawn after
		everything the floor lays and before the bag (D-098), so the guard changes nothing else a
		seed lays, and changing the bag's tools or counts never moves a seed's guard.
	]]
	local open: { number } = {}
	for _, note in notes do
		if not padlocked[note.slot] then
			table.insert(open, note.slot)
		end
	end
	if #open == 0 then
		for _, note in notes do
			table.insert(open, note.slot)
		end
	end
	deck.guarded = open[random:nextInteger(1, #open)]

	refill(deck)
	if floor.number <= Deal.TeachingFloors then
		-- The bag's next tool is its last: swap a saw there.
		local bag = deck.bag
		local saw = table.find(bag, "Saw") :: number
		bag[saw], bag[#bag] = bag[#bag], bag[saw]
	end
	-- The coins, drawn last, so adding them moved nothing else a seed lays (its guard, its bag).
	for _, i in units do
		deck.coins[i] = Deal.coinsFrom(random:nextNumber(), random:nextNumber())
	end
	-- The batteries, drawn after the coins, so adding them moved nothing else a seed lays.
	for _, i in units do
		if random:nextNumber() < Deal.BatteryShare then
			deck.batteries[i] = true
		end
	end
	-- The faint mark, drawn last, so adding it moved nothing else a seed lays.
	local share = random:nextNumber()
	deck.marked = Deal.markFrom(floor.number, notes, deck.guarded, share, random:nextNumber())
	-- The sleepers (S2-01), drawn last, so placing them moved nothing else a seed lays. Every
	-- unit draws its two whether it can hold one or not, so a change to which can never moves
	-- another unit's sleeper.
	for _, i in units do
		local roll, pick = random:nextNumber(), random:nextNumber()
		local keeper = keeperFrom(floor, pick)
		if keeper and roll < Deal.sleeperShare(deck, i) then
			deck.sleepers[i] = keeper
		end
	end
	-- The breaker box (S2-02b), drawn last, so placing it moved nothing else a seed lays.
	deck.breaker = Breaker.pick(Breaker.spots(floor), random:nextNumber())
	-- The Packrat (S2-06b2b), drawn last, so placing it moved nothing else a seed lays. It draws
	-- its five on every floor, so a floor without one draws as many as a floor with one.
	local where, size = random:nextNumber(), random:nextNumber()
	local finds = { random:nextNumber(), random:nextNumber(), random:nextNumber() }
	Deal.packratIn(deck, where, size, finds)
	return deck
end

-- The units the Packrat may sleep in on `deck`'s floor, in number order: none below its floor,
-- never a note's unit, a padlocked one or another sleeper's, and only medium units if any are.
function Deal.packratUnits(deck: Deck): { number }
	local out: { number } = {}
	if deck.floor.number < Deal.Packrat.from then
		return out
	end
	local noted: { [number]: boolean } = {}
	for _, note in deck.notes do
		noted[note.slot] = true
	end
	local small: { number } = {}
	for _, i in Deal.units(deck.floor) do
		if not (noted[i] or deck.padlocked[i] or deck.sleepers[i]) then
			table.insert(if deck.floor.slots[i].size == "M" then out else small, i)
		end
	end
	return if #out > 0 then out else small
end

-- Places the Packrat asleep in a unit of `deck`'s floor among its pile, from three rolls (0 to
-- 1): `where` its unit, `count` two finds or three, `picks` each find, none twice. Its unit, or
-- nil on a floor without one.
function Deal.packratIn(deck: Deck, where: number, count: number, picks: { number }): number?
	local units = Deal.packratUnits(deck)
	if #units == 0 then
		return nil
	end
	local index = units[math.floor(where * #units) + 1]
	local pile: { string } = {}
	local size = Deal.PileMin + math.floor(count * (Deal.PileMax - Deal.PileMin + 1))
	-- each by the floor's grades, as a unit's find is: a hoard of junk, now and then a gem
	for n = 1, size do
		local find = Deal.findFrom(deck.floor.number, picks[n], pile)
		if find then
			table.insert(pile, find)
		end
	end
	deck.sleepers[index] = Deal.Packrat.name
	deck.piles[index] = pile
	return index
end

-- The chance, 0 to 1, that unit `index` holds a sleeper from the floor's start (`Deal.Asleep`):
-- none in the guarded note's unit, nor in the lobby's hall on floors 1 and 2; twice an ordinary
-- unit's behind a padlock.
function Deal.sleeperShare(deck: Deck, index: number): number
	if index == deck.guarded then
		return 0
	elseif deck.floor.number <= Deal.TeachingFloors and deck.firstHall[index] then
		return 0
	end
	local share = Deal.Asleep / 100
	return if deck.padlocked[index] then share * Deal.PadlockedKeeper else share
end

-- The next tool out of the bag, a fresh shuffled bag when it's empty.
function Deal.drawTool(deck: Deck): Tool
	if #deck.bag == 0 then
		refill(deck)
	end
	return table.remove(deck.bag) :: Tool
end

-- Moves one kind's odds onto another.
local function move(odds: { [string]: number }, from: Kind, to: Kind)
	odds[to] += odds[from]
	odds[from] = 0
end

-- The director's two limits on keepers, on any odds (`Deal.Kinds` keys): none in the lobby's hall
-- on floors 1 and 2, and none awake past the floor's cap (the guard's place counted, below).
local function limit(odds: { [string]: number }, deck: Deck, index: number, situation: Situation)
	local guard = deck.guarded
	local awake = situation.awake + (if guard and not deck.dealt[guard] then 1 else 0)
	if deck.floor.number <= Deal.TeachingFloors and deck.firstHall[index] then
		move(odds, "Asleep", "Nothing")
		move(odds, "Awake", "Nothing")
	elseif awake >= Deal.awakeCap(deck.floor.number) then
		move(odds, "Awake", "Asleep")
	end
end

--[[
	The odds behind unit `index` in `situation`, out of their total, in `Deal.Kinds` order.
	An ordinary unit with a sleeper holds it alone (padlocked, it stands with the find or tool:
	`besideOdds`). The guarded note's unit is always a keeper awake, whatever the mood and however many are
	loose. Every other door counts the guard among those awake from the floor's start, before
	anyone has found it: until its unit is dealt (and the guard is counted with the rest), its
	place is kept. So on floors 1 and 2, which allow one awake, every other keeper is dealt
	asleep until the guard is trapped behind a door.
]]
function Deal.odds(deck: Deck, index: number, situation: Situation): { [string]: number }
	local odds: { [string]: number } = {}
	if index == deck.guarded then
		for _, kind in KINDS do
			odds[kind] = 0
		end
		odds.Awake = 1
		return odds
	elseif deck.sleepers[index] and not deck.padlocked[index] then
		-- placed with the floor: it's all this unit holds
		for _, kind in KINDS do
			odds[kind] = 0
		end
		odds.Asleep = 1
		return odds
	end
	local base = if deck.padlocked[index] then Deal.PadlockedHolds else Deal.Odds[situation.mood]
	for _, kind in KINDS do
		odds[kind] = base[kind] or 0
	end
	limit(odds, deck, index, situation)
	return odds
end

--[[
	The odds of a keeper standing in padlocked unit `index` with its find or tool, in `situation`,
	out of their total, keyed as `Deal.Kinds`: "Nothing" for none, "Asleep", "Awake". All on
	"Nothing" for any other unit, all on "Asleep" for one with a sleeper. Without one, out of the
	80 in 100 padlocked units the sleepers leave, the mood's awake odds times `PadlockedKeeper`.
]]
function Deal.besideOdds(deck: Deck, index: number, situation: Situation): { [string]: number }
	local odds: { [string]: number } = { Nothing = 1, Find = 0, Tool = 0, Asleep = 0, Awake = 0 }
	if not deck.padlocked[index] or index == deck.guarded then
		return odds
	elseif deck.sleepers[index] then
		odds.Nothing, odds.Asleep = 0, 1
		return odds
	end
	odds.Awake = Deal.Odds[situation.mood].Awake * Deal.PadlockedKeeper
	odds.Nothing = math.max(0, 100 - Deal.Asleep * Deal.PadlockedKeeper - odds.Awake)
	limit(odds, deck, index, situation)
	return odds
end

-- The kind `roll` (0 to 1) lands on across `odds`, and where in that kind's share it landed, 0
-- to 1: as random as a fresh roll and free of which kind it was, so one roll can make a second
-- choice without a draw of its own (and without moving any seed's other draws).
local function landOn(odds: { [string]: number }, roll: number): (Kind, number)
	local total = 0
	for _, kind in KINDS do
		total += odds[kind]
	end
	local at = roll * total
	for _, k in KINDS do
		if at < odds[k] then
			return k :: Kind, at / odds[k] -- the loop widens KINDS' words to string
		end
		at -= odds[k]
	end
	return "Nothing", 0
end

--[[
	What comes in the marked box (B-03a, D-205): a unit's find or tool waits inside its one marked
	box, never seen until someone opens it, if it packs into one turned any way, as you'd pack a
	moving box; bigger, or too long (a tall lamp, the saw, the ladder), it stands loose on the
	floor as before, since a box it couldn't have come out of would read as a trick.
]]
-- Studs the box's cardboard takes on each side, top and bottom too: a real 18-inch box is about
-- 17.6 inside. A little more and the skates and the hard hat would stand loose for want of a
-- hair; less and a find would rise out of a box narrower than itself.
Deal.BoxWall = 0.05

-- Whether a thing of size `thing` packs into a box of size `box` (each three sizes, studs, in any
-- order), turned whichever way it fits, `Deal.BoxWall` taken off every side of the box.
function Deal.packs(thing: { number }, box: { number }): boolean
	local a, b = table.clone(thing), table.clone(box)
	table.sort(a)
	table.sort(b)
	for i = 1, 3 do
		if a[i] > b[i] - 2 * Deal.BoxWall then
			return false
		end
	end
	return true
end

-- The keeper in a dealt unit, "Asleep" or "Awake", whether it's all the unit holds or stands
-- with a padlocked unit's find or tool; nil for none.
function Deal.keeperIn(contents: Contents): Kind?
	local kind = contents.kind
	if kind == "Asleep" or kind == "Awake" then
		return kind
	end
	return contents.beside
end

--[[
	Deals unit `index` the first time its door lifts and returns what it holds; after that, the
	same every time (a door shut and lifted again holds what it held).
]]
function Deal.open(deck: Deck, index: number, situation: Situation): Contents
	local dealt = deck.dealt[index]
	if dealt then
		return dealt
	end
	local roll = deck.rolls[index]
	assert(roll, "Deal.open: not a unit")

	local kind: Kind, within: number = landOn(Deal.odds(deck, index, situation), roll)

	local contents: Contents = {
		kind = kind,
		coins = deck.coins[index] or 0,
		battery = if deck.batteries[index] then true else nil,
		pile = deck.piles[index],
	}
	if kind == "Tool" then
		contents.tool = Deal.drawTool(deck)
	elseif kind == "Find" then
		contents.find = Deal.findFrom(deck.floor.number, deck.picks[index])
		if not contents.find then
			contents.kind = "Nothing" -- never: the floor-1 commons are always left to deal
		end
	elseif kind == "Asleep" or kind == "Awake" then
		contents.keeper = deck.sleepers[index] or keeperFrom(deck.floor, deck.picks[index])
		if not contents.keeper then
			contents.kind = "Nothing"
		end
	end
	if deck.padlocked[index] and (kind == "Find" or kind == "Tool") then
		-- the keeper standing with it, from where the unit's roll fell within its find or tool
		local beside, which = landOn(Deal.besideOdds(deck, index, situation), within)
		if beside == "Asleep" or beside == "Awake" then
			contents.keeper = deck.sleepers[index] or keeperFrom(deck.floor, which)
			contents.beside = if contents.keeper then beside else nil
		end
	end
	if contents.kind == "Nothing" and contents.coins == 0 and not contents.battery then
		local note = false
		for _, n in deck.notes do
			note = note or n.slot == index
		end
		if not note then
			contents.stuff = Deal.stuffFrom(deck.picks[index])
		end
	end
	deck.dealt[index] = contents
	return contents
end

-- A note as the player sees it: its digits in their places, the rest blank. "_ 7 _ _"
function Deal.noteText(deck: Deck, note: Note): string
	local shown = { "_", "_", "_", "_" }
	for _, place in note.places do
		shown[place] = tostring(deck.code[place])
	end
	return table.concat(shown, " ")
end

return Deal
