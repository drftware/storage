--!strict
-- lune run tests/deal.spec
-- The deal (L-04d) over 200 seeds on floors 1, 3 and 6: the same seed deals the same; the code's
-- notes show every digit once, lie past the lobby's hall, one to a wing, spread out, and from
-- floor 6 one sits behind a padlock; padlocks are the right few, never in the lobby's hall; the
-- odds land where they say, worse behind a padlock; never more keepers awake than the cap, none
-- woken in a chase or after one, none in the lobby's hall on floors 1 and 2; the bag deals every tool before any comes round again, a saw
-- first on floors 1 and 2; a door lifted again holds what it held.
local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local Deal = require("../src/shared/Deal")
local fs = require("@lune/fs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

local SEEDS = 200
local FLOORS = { 1, 3, 6 }

local function lay(seed: number, number: number)
	local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
	return floor, Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
end

local unitsOf = Deal.units

-- Whether unit `i` stands in the lobby's hall: its zone, or on a floor with no fork (no wings) the
-- first doors out from the lobby.
local function inLobbyHall(floor: Floor.Floor, units: { number }, wings: number, i: number): boolean
	if wings > 0 then
		return floor.cells[floor.slots[i].cell].zone == "Lobby"
	end
	return (table.find(units, i) or 0) <= Deal.FirstDoors
end

local BUILD: Deal.Situation = { mood = "Build", awake = 0 }

-- Tallies of each kind dealt, unlocked and padlocked, in one situation.
type Tally = { [string]: number }
local function tally(): Tally
	return { Nothing = 0, Find = 0, Tool = 0, Asleep = 0, Awake = 0, total = 0 }
end
local function add(t: Tally, kind: string)
	t[kind] += 1
	t.total += 1
end
local function share(t: Tally, kind: string): number
	return t[kind] / math.max(1, t.total)
end

local open, locked = tally(), tally()
local capped, peak, relief = tally(), tally(), tally()
local closest = math.huge

for seed = 1, SEEDS do
	for _, number in FLOORS do
		local floor, deck = lay(seed, number)
		local _, twin = lay(seed, number)
		local units = unitsOf(floor)
		local where = `seed {seed} floor {number}`

		-- The same seed lays the same.
		ok(table.concat(deck.code, "") == table.concat(twin.code, ""), `{where}: the same code`)
		ok(#deck.notes == #twin.notes, `{where}: as many notes`)
		for k, note in deck.notes do
			ok(twin.notes[k].slot == note.slot, `{where}: note {k} in the same unit`)
		end
		for _, i in units do
			ok(deck.padlocked[i] == twin.padlocked[i], `{where}: the same padlocks`)
		end

		-- The code.
		ok(#deck.code == 4, `{where}: four digits`)
		for _, d in deck.code do
			ok(d >= 0 and d <= 9 and d == math.floor(d), `{where}: a digit is 0 to 9`)
		end

		-- The notes.
		ok(#deck.notes == Deal.noteCount(number), `{where}: {Deal.noteCount(number)} notes`)
		local shown, zones, slots = {}, {}, {}
		local wings = {}
		for _, i in units do
			local zone = floor.cells[floor.slots[i].cell].zone
			if zone ~= "Lobby" then
				wings[zone] = true
			end
		end
		local wingCount = 0
		for _ in wings do
			wingCount += 1
		end
		local lockedNote = false
		for _, note in deck.notes do
			local slot = floor.slots[note.slot]
			ok(slot ~= nil and slot.kind == "Unit", `{where}: a note lies in a unit`)
			ok(not slots[note.slot], `{where}: one note to a unit`)
			slots[note.slot] = true
			local zone = floor.cells[slot.cell].zone
			ok(
				not inLobbyHall(floor, units, wingCount, note.slot),
				`{where}: no note in the lobby's hall`
			)
			if wingCount >= #deck.notes then
				ok(not zones[zone], `{where}: one note to a wing while there are wings enough`)
			end
			zones[zone] = true
			ok(#note.places == 4 // #deck.notes, `{where}: a note shows its share of the digits`)
			for _, p in note.places do
				ok(not shown[p], `{where}: each digit on one note`)
				shown[p] = true
			end
			lockedNote = lockedNote or deck.padlocked[note.slot] == true
			for _, other in deck.notes do
				if other ~= note then
					local o = floor.slots[other.slot]
					closest = math.min(closest, math.sqrt((slot.x - o.x) ^ 2 + (slot.z - o.z) ^ 2))
				end
			end
			local text = Deal.noteText(deck, note)
			ok(#string.split(text, " ") == 4, `{where}: a note reads as four places`)
			for _, p in note.places do
				ok(
					string.split(text, " ")[p] == tostring(deck.code[p]),
					`{where}: a note's digit in its place`
				)
			end
		end
		for p = 1, 4 do
			ok(shown[p] == true, `{where}: digit {p} is on a note`)
		end
		if number >= Deal.PadlockedNoteFrom then
			ok(lockedNote, `{where}: a note behind a padlock`)
		end

		-- The padlocks.
		local locks = 0
		for i in deck.padlocked do
			locks += 1
			ok(floor.slots[i].kind == "Unit", `{where}: only units padlocked`)
			ok(
				not inLobbyHall(floor, units, wingCount, i),
				`{where}: no padlock in the lobby's hall`
			)
		end
		local want = math.max(1, math.round(#units * Deal.padlockShare(number)))
		ok(locks == want, `{where}: {want} padlocks, got {locks}`)

		-- The bag: a saw first on floors 1 and 2; then every tool in each bag of 11.
		local bagSize = 0
		for _, tool in Deal.Tools do
			bagSize += Deal.Bag[tool]
		end
		local _, bagDeck = lay(seed, number)
		for b = 1, 2 do
			local seen = {}
			for t = 1, bagSize do
				local tool = Deal.drawTool(bagDeck)
				if b == 1 and t == 1 and number <= Deal.TeachingFloors then
					ok(tool == "Saw", `{where}: the first tool is a saw`)
				end
				seen[tool] = (seen[tool] or 0) + 1
			end
			for _, tool in Deal.Tools do
				ok(seen[tool] == Deal.Bag[tool], `{where}: bag {b} holds {Deal.Bag[tool]} {tool}`)
			end
		end

		-- Dealing in Build: the odds, the same kinds in reverse order, a door lifted again.
		local _, reverse = lay(seed, number)
		for k = #units, 1, -1 do
			Deal.open(reverse, units[k], BUILD)
		end
		for _, i in units do
			local before = #deck.bag
			local got = Deal.open(deck, i, BUILD)
			add(if deck.padlocked[i] then locked else open, got.kind)
			ok(Deal.open(twin, i, BUILD).kind == got.kind, `{where}: the same seed deals the same`)
			ok(
				reverse.dealt[i].kind == got.kind,
				`{where}: the order of doors doesn't change the kind`
			)
			ok(
				Deal.open(deck, i, { mood = "Relief", awake = 9 }) == got,
				`{where}: lifted again, the same`
			)
			if number <= Deal.TeachingFloors and inLobbyHall(floor, units, wingCount, i) then
				ok(
					got.kind ~= "Asleep" and got.kind ~= "Awake",
					`{where}: no keeper in the first hall`
				)
			end
			ok(
				deck.firstHall[i] == (inLobbyHall(floor, units, wingCount, i) or nil),
				`{where}: the first hall`
			)
			if got.kind ~= "Tool" then
				ok(#deck.bag == before, `{where}: only a tool comes out of the bag`)
			end
			if got.kind == "Tool" then
				ok(
					got.tool ~= nil and Deal.Bag[got.tool :: Deal.Tool] ~= nil,
					`{where}: a tool from the bag`
				)
			elseif got.kind == "Find" then
				ok(
					got.find ~= nil and table.find(Deal.Finds, got.find) ~= nil,
					`{where}: a find from the deal's list`
				)
			elseif got.kind == "Asleep" or got.kind == "Awake" then
				local joined = false
				for _, keeper in Deal.Keepers do
					joined = joined or (keeper.name == got.keeper and keeper.from <= number)
				end
				ok(joined, `{where}: only a keeper that has joined`)
			end
		end

		-- At the cap, in a chase and after one: nothing more wakes.
		local _, atCap = lay(seed, number)
		local _, inPeak = lay(seed, number)
		local _, inRelief = lay(seed, number)
		for _, i in units do
			add(capped, Deal.open(atCap, i, { mood = "Build", awake = Deal.awakeCap(number) }).kind)
			add(peak, Deal.open(inPeak, i, { mood = "Peak", awake = 0 }).kind)
			add(relief, Deal.open(inRelief, i, { mood = "Relief", awake = 0 }).kind)
		end
	end
end

-- Every find the deal hands out has its art (art/finds/), read from its generated Specs (they
-- build Vector3s, which Lune lacks).
local findSpecs = fs.readFile("src/shared/Finds/Specs.luau")
for _, name in Deal.Finds do
	ok(string.find(findSpecs, "\n\t" .. name .. " = {", 1, true) ~= nil, `{name} is a built find`)
end

-- The odds, over every unlocked door in Build: each kind within 3 in 100 of its odds.
for _, kind in Deal.Kinds do
	local want = Deal.Odds.Build[kind] / 100
	ok(
		math.abs(share(open, kind) - want) < 0.03,
		`Build deals {kind} about {want}: {share(open, kind)}`
	)
end
-- Behind a padlock: more finds, more keepers, less nothing.
ok(share(locked, "Find") > share(open, "Find") + 0.1, "a padlock holds more finds")
ok(
	share(locked, "Asleep") + share(locked, "Awake")
		> share(open, "Asleep") + share(open, "Awake") + 0.05,
	"a padlock holds more keepers"
)
ok(share(locked, "Nothing") < share(open, "Nothing") - 0.2, "a padlock is rarely empty")
ok(locked.total > 1000, `enough padlocked doors to judge: {locked.total}`)
-- The cap turns a keeper asleep, not away.
ok(capped.Awake == 0, "at the cap nothing wakes")
ok(
	share(capped, "Asleep") > share(open, "Asleep") + 0.02,
	"at the cap a keeper is dealt asleep instead"
)
ok(peak.Awake == 0 and relief.Awake == 0, "nothing wakes in a chase or after one")
-- Notes stand apart: the nearest two on any floor (the rule bends only with room nowhere).
ok(closest >= Deal.NoteSpacing, `two notes at least {Deal.NoteSpacing} studs apart: {closest}`)

if failures > 0 then
	print(`deal: {failures} of {checks} checks failed`)
	error("deal spec failed")
end
print(`deal: {checks} checks passed (nearest two notes {math.floor(closest)} studs)`)
