--!strict
--[[
	Deal: what's behind each door (L-04d), the rules alone. Every door is a gamble: the next one
	could hold the saw you need, nothing, or something that's been waiting. Nothing here touches an
	Instance, so Lune tests it (tests/deal.spec.luau); L-04e lays the deal on the floor.

	Two moments, as the GDD's "What's behind the door" splits them:
	- When a floor is laid (`Deal.new`), the search is made real: the floor's code, the notes that
	  carry it, spread across the floor, which doors start padlocked, and which note is guarded.
	- When a door first lifts, a peek or an open (`Deal.open`), the director deals the rest: a tool,
	  nothing, a find, or a keeper asleep or awake, the odds set by its mood. Left 4 Dead's director
	  paces a run the same way, placing items and infected as the team moves rather than up front.

	Each unit's own roll is drawn when the floor is laid, so the same seed deals a unit the same
	kind of thing in the same mood whatever order the doors are opened in; only which tool comes
	out of the bag depends on the order. Odds are out of 100 and live here with what they do.
]]

local Floor = require("./Floor")

type Floor = Floor.Floor
type Random = Floor.Random

export type Mood = "Build" | "Peak" | "Relief"
export type Kind = "Nothing" | "Find" | "Tool" | "Asleep" | "Awake"
export type Tool = "Saw" | "BoltCutters" | "Padlock" | "Ladder" | "BubbleWrap" | "AirHorn"

-- What the director knows when a door lifts: its mood, and how many keepers are awake now.
export type Situation = { mood: Mood, awake: number }

-- What a unit holds once dealt: a tool says which, a find which, a keeper which and whether it's
-- awake; `coins`, how many coins lie on its floor besides (0 to 3, S1-04a).
export type Contents = { kind: Kind, tool: Tool?, find: string?, keeper: string?, coins: number }

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
	-- the unit of the guarded note (D-072), by slot index: it's always dealt a keeper, awake, and
	-- holds one of the floor's awake places from the floor's start (`Deal.odds`)
	guarded: number?,
	bag: { Tool }, -- the tools left in the bag, the next one last
	random: Random,
}

local Deal = {}

local KINDS: { Kind } = { "Nothing", "Find", "Tool", "Asleep", "Awake" }
Deal.Kinds = KINDS

--[[
	The odds behind a door, out of 100, by the director's mood (GDD "The director"). Build, while you
	search, deals riskier doors: now and then something wakes. Peak, during a chase, wakes nothing
	new and leans on tools to get away with. Relief, after one, deals finds and lets you breathe.
	Until the director exists (Phase 2) the floor deals in Build.
]]
Deal.Odds = {
	Build = { Nothing = 40, Find = 25, Tool = 20, Asleep = 10, Awake = 5 },
	Peak = { Nothing = 45, Find = 15, Tool = 30, Asleep = 10, Awake = 0 },
	Relief = { Nothing = 40, Find = 35, Tool = 20, Asleep = 5, Awake = 0 },
} :: { [Mood]: { [string]: number } } -- string keys: Luau won't index by a union of words

-- Behind a padlock, the best finds and the worst odds (GDD), as Escape from Tarkov's locked rooms
-- hold its best loot: each kind's odds times this. Build's become about 9 nothing, 45 a find,
-- 18 a tool, 18 a keeper asleep and 9 awake in every 100.
Deal.Padlocked =
	{ Nothing = 0.25, Find = 2, Tool = 1, Asleep = 2, Awake = 2 } :: { [string]: number }

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

-- The finds a door can hold, each a name in `Finds.Names` (art/finds/): the GDD's 1980s bedroom
-- set first (D-035). Each is as likely until Phase 2 deals finds by rarity, the best behind
-- padlocks (ROADMAP "Finds in a run").
Deal.Finds = { "Boombox", "Television", "Teddy", "Skates" } :: { string }

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
		bag = {},
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
	return deck
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

--[[
	The odds behind unit `index` in `situation`, out of their total, in `Deal.Kinds` order.
	The guarded note's unit is always a keeper awake, whatever the mood and however many are
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
	end
	local base = Deal.Odds[situation.mood]
	local locked = deck.padlocked[index] == true
	for _, kind in KINDS do
		odds[kind] = base[kind] * (if locked then Deal.Padlocked[kind] else 1)
	end
	local guard = deck.guarded
	local awake = situation.awake + (if guard and not deck.dealt[guard] then 1 else 0)
	if deck.floor.number <= Deal.TeachingFloors and deck.firstHall[index] then
		move(odds, "Asleep", "Nothing")
		move(odds, "Awake", "Nothing")
	elseif awake >= Deal.awakeCap(deck.floor.number) then
		move(odds, "Awake", "Asleep")
	end
	return odds
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

	local odds = Deal.odds(deck, index, situation)
	local total = 0
	for _, kind in KINDS do
		total += odds[kind]
	end
	local kind: Kind = "Nothing"
	local at = roll * total
	for _, k in KINDS do
		if at < odds[k] then
			kind = k :: Kind -- the loop widens KINDS' words to string
			break
		end
		at -= odds[k]
	end

	local contents: Contents = { kind = kind, coins = deck.coins[index] or 0 }
	if kind == "Tool" then
		contents.tool = Deal.drawTool(deck)
	elseif kind == "Find" then
		contents.find = Deal.Finds[math.floor(deck.picks[index] * #Deal.Finds) + 1]
	elseif kind == "Asleep" or kind == "Awake" then
		local joined = {}
		for _, keeper in Deal.Keepers do
			if keeper.from <= deck.floor.number then
				table.insert(joined, keeper.name)
			end
		end
		if #joined == 0 then
			contents.kind = "Nothing"
		else
			contents.keeper = joined[math.floor(deck.picks[index] * #joined) + 1]
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
