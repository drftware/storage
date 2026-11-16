--!strict
-- lune run tests/deal.spec
-- The deal (L-04d) over 200 seeds on floors 1, 3 and 6: the same seed deals the same; the code's
-- notes show every digit once, lie past the lobby's hall, one to a wing, spread out, and from
-- floor 6 one sits behind a padlock; padlocks are the right few, never in the lobby's hall; the
-- odds land where they say; a padlock always holds a find or a tool, with the best chance of a
-- keeper standing with it (S1-07a); about one unit in twelve holds a tool; never more keepers awake than the cap, none
-- woken in a chase or after one (the guarded note's keeper aside: guard.spec), none in the lobby's hall on floors 1 and 2; the bag deals every tool before any comes round again, a saw
-- first on floors 1 and 2; a door lifted again holds what it held. The sleepers (S2-01) are placed
-- as the floor is laid, the same for the same seed, about `Deal.Asleep` in 100 units (twice that
-- behind a padlock), never the guard's unit nor the lobby's hall on floors 1 and 2, and each door
-- hands its sleeper back asleep whatever the mood or the cap. From floor 3 one Packrat sleeps
-- among a pile of two or three different finds of its own (S2-06b2b), never in a note's, a
-- padlocked or another sleeper's unit, and its door hands the pile back.
local Brix = require("../vendor/brix/src")
local Floor = require("../src/shared/Floor")
local Deal = require("../src/shared/Deal")
local FloorRules = require("../src/shared/FloorRules")

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
-- The keepers standing with a padlocked unit's find or tool ("Nothing" for none), in Build, at
-- the cap and in a chase; and every unit's tools, padlocked or not, on floors 1 to 3 and on 6.
local beside, besideCapped, besidePeak = tally(), tally(), tally()
local toolsLow, toolsHigh = tally(), tally()
-- The units that could hold a sleeper and how many do, ordinary and padlocked (S2-01).
local sleepOpen, sleepLocked = { could = 0, did = 0 }, { could = 0, did = 0 }
local closest = math.huge

-- What every seed lays before a door lifts (code, notes, padlocks, guard, each unit's rolls and
-- coins, the bag), folded into one number for seeds 1 to 60: S1-07a changed what a door deals,
-- not what a floor lays, so this is what it was before S1-07a. It changes only when a ticket
-- means to move what a seed lays.
local LAID = 730595903
local LAID_SEEDS = 60
local laid = 7
local function feed(s: string)
	for i = 1, #s do
		laid = (laid * 131 + string.byte(s, i)) % 4294967291
	end
end

for seed = 1, SEEDS do
	for _, number in FLOORS do
		local floor, deck = lay(seed, number)
		local _, twin = lay(seed, number)
		local units = unitsOf(floor)
		local where = `seed {seed} floor {number}`
		if seed <= LAID_SEEDS then
			feed(table.concat(deck.code, ","))
			for _, note in deck.notes do
				feed(`n{note.slot}:{table.concat(note.places, ",")}`)
			end
			feed(`g{deck.guarded}b{table.concat(deck.bag, ",")}`)
			for _, i in units do
				local lock = if deck.padlocked[i] then "L" else ""
				feed(`{i}:{math.floor(deck.rolls[i] * 1e6)},{math.floor(deck.picks[i] * 1e6)}`)
				feed(`{deck.coins[i]}{lock}`)
			end
		end

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
		ok(
			#deck.notes == FloorRules.at(number).notes,
			`{where}: {FloorRules.at(number).notes} notes`
		)
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
		if FloorRules.at(number).padlockedNote then
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
		local want = math.max(1, math.round(#units * FloorRules.at(number).padlocks))
		ok(locks == want, `{where}: {want} padlocks, got {locks}`)

		-- The sleepers, placed before a door lifts (S2-01).
		for i, name in deck.sleepers do
			ok(
				floor.slots[i] ~= nil and floor.slots[i].kind == "Unit",
				`{where}: a sleeper in a unit`
			)
			ok(i ~= deck.guarded, `{where}: no sleeper in the guard's unit`)
			ok(
				not FloorRules.at(number).teaching or not inLobbyHall(floor, units, wingCount, i),
				`{where}: no sleeper in the first hall`
			)
			local joined = name == Deal.Packrat.name and number >= Deal.Packrat.from
			for _, keeper in Deal.Keepers do
				joined = joined or (keeper.name == name and keeper.from <= number)
			end
			ok(joined, `{where}: a sleeper that has joined`)
		end

		-- The Packrat (S2-06b2b): one on every floor from 3, asleep among two or three finds of
		-- its own, in a medium unit, never a note's, a padlocked or another sleeper's.
		local packrats, piles = 0, 0
		for i, name in deck.sleepers do
			if name == Deal.Packrat.name then
				packrats += 1
				local noted = false
				for _, note in deck.notes do
					noted = noted or note.slot == i
				end
				ok(not noted and not deck.padlocked[i], `{where}: the Packrat's unit`)
				ok(floor.slots[i].size == "M", `{where}: the Packrat in a medium unit`)
				local pile = deck.piles[i]
				ok(pile ~= nil, `{where}: the Packrat sleeps among a pile`)
				if pile then
					ok(
						#pile >= Deal.PileMin and #pile <= Deal.PileMax,
						`{where}: a pile of {Deal.PileMin} to {Deal.PileMax}, got {#pile}`
					)
					for n, find in pile do
						ok(table.find(Deal.Finds, find) ~= nil, `{where}: a pile of finds`)
						ok(table.find(pile, find) == n, `{where}: no find twice in a pile`)
					end
					ok(
						table.concat(pile, ",") == table.concat(twin.piles[i] or {}, ","),
						`{where}: the same pile`
					)
				end
			end
		end
		for i in deck.piles do
			piles += 1
			ok(deck.sleepers[i] == Deal.Packrat.name, `{where}: a pile only round the Packrat`)
		end
		local want = if number >= Deal.Packrat.from then 1 else 0
		ok(packrats == want and piles == want, `{where}: {want} Packrat, got {packrats}`)

		for _, i in units do
			ok(deck.sleepers[i] == twin.sleepers[i], `{where}: the same sleepers`)
			if Deal.sleeperShare(deck, i) > 0 and deck.sleepers[i] ~= Deal.Packrat.name then
				local t = if deck.padlocked[i] then sleepLocked else sleepOpen
				t.could += 1
				t.did += if deck.sleepers[i] then 1 else 0
			end
		end

		-- The bag: a saw first on floors 1 and 2; then every tool in each bag of 9.
		local bagSize = 0
		for _, tool in Deal.Tools do
			bagSize += Deal.Bag[tool]
		end
		local _, bagDeck = lay(seed, number)
		for b = 1, 2 do
			local seen = {}
			for t = 1, bagSize do
				local tool = Deal.drawTool(bagDeck)
				if b == 1 and t == 1 and FloorRules.at(number).teaching then
					ok(tool == "Saw", `{where}: the first tool is a saw`)
				end
				seen[tool] = (seen[tool] or 0) + 1
			end
			for _, tool in Deal.Tools do
				ok(seen[tool] == Deal.Bag[tool], `{where}: bag {b} holds {Deal.Bag[tool]} {tool}`)
			end
		end

		-- Dealing in Build: the odds, the same kinds in reverse order, a door lifted again. The
		-- guarded note's unit is dealt first each time (it holds a place for itself until it's
		-- dealt: guard.spec) and its keeper, always awake, is left out of the odds.
		local guard = deck.guarded :: number
		local _, reverse = lay(seed, number)
		Deal.open(reverse, guard, BUILD)
		for k = #units, 1, -1 do
			Deal.open(reverse, units[k], BUILD)
		end
		Deal.open(deck, guard, BUILD)
		Deal.open(twin, guard, BUILD)
		for _, i in units do
			local before = #deck.bag
			local got = Deal.open(deck, i, BUILD)
			if deck.sleepers[i] then
				ok(
					Deal.keeperIn(got) == "Asleep" and got.keeper == deck.sleepers[i],
					`{where}: a door hands back its sleeper`
				)
				ok(
					(got.beside ~= nil) == (deck.padlocked[i] == true),
					`{where}: a padlock's sleeper stands with its find or tool`
				)
			end
			ok(got.pile == deck.piles[i], `{where}: a door hands back its pile`)
			local packrat = deck.sleepers[i] == Deal.Packrat.name
			-- a note's unit holds its note in place of a find or tool (B-04a): not in the odds
			if i ~= guard and not packrat and Deal.noteIn(deck, i) == nil then
				add(if deck.padlocked[i] then locked else open, got.kind)
				if deck.padlocked[i] then
					add(beside, got.beside or "Nothing")
				end
				add(if number < 6 then toolsLow else toolsHigh, got.kind)
			end
			ok(
				got.beside == nil or deck.padlocked[i] == true,
				`{where}: a keeper stands with a find only behind a padlock`
			)
			if got.beside then
				ok(
					(got.kind == "Find" or got.kind == "Tool" or Deal.noteIn(deck, i) ~= nil)
						and got.keeper ~= nil,
					`{where}: a keeper beside a find, tool or note's box, named`
				)
			end
			ok(Deal.open(twin, i, BUILD).kind == got.kind, `{where}: the same seed deals the same`)
			ok(
				reverse.dealt[i].kind == got.kind and reverse.dealt[i].beside == got.beside,
				`{where}: the order of doors doesn't change the kind`
			)
			ok(
				Deal.open(deck, i, { mood = "Relief", awake = 9 }) == got,
				`{where}: lifted again, the same`
			)
			if FloorRules.at(number).teaching and inLobbyHall(floor, units, wingCount, i) then
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
				local joined = packrat and got.kind == "Asleep"
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
			if i ~= guard and deck.sleepers[i] ~= Deal.Packrat.name then
				local cap =
					{ mood = "Build", awake = FloorRules.at(number).awake } :: Deal.Situation
				local c = Deal.open(atCap, i, cap)
				local p = Deal.open(inPeak, i, { mood = "Peak", awake = 0 })
				if deck.sleepers[i] then
					ok(
						Deal.keeperIn(c) == "Asleep" and Deal.keeperIn(p) == "Asleep",
						`{where}: a sleeper is asleep at the cap and in a chase`
					)
				end
				add(capped, c.kind)
				add(peak, p.kind)
				if deck.padlocked[i] then
					add(besideCapped, c.beside or "Nothing")
					add(besidePeak, p.beside or "Nothing")
				end
				add(relief, Deal.open(inRelief, i, { mood = "Relief", awake = 0 }).kind)
			end
		end
	end
end

-- Every find the deal hands out has its art (art/finds/): the bedroom set's generated Specs or
-- a kit-built set's (the fixture loads them, since they build Vector3s, which Lune lacks).
local FindBoxes = require("./fixtures/finds").boxes
for _, name in Deal.Finds do
	ok(FindBoxes[name] ~= nil, `{name} is a built find`)
end

ok(laid == LAID, `every seed lays what it did before S1-07a ({laid}, was {LAID})`)

-- The odds, over every unlocked door in Build: each kind within 3 in 100 of its odds.
-- The sleepers count with the rest: the others' odds are out of the 90 in 100 they leave.
for _, kind in Deal.Kinds do
	local want = (if kind == "Asleep" then Deal.Asleep else Deal.Odds.Build[kind]) / 100
	ok(
		math.abs(share(open, kind) - want) < 0.03,
		`Build deals {kind} about {want}: {share(open, kind)}`
	)
end
-- Behind a padlock (S1-07a): always a find or a tool, each within 3 in 100 of its odds; a keeper
-- with it about twice as often as behind an ordinary door, asleep and awake each within 3 in 100.
ok(locked.Nothing + locked.Asleep + locked.Awake == 0, "a padlock always holds a find or a tool")
for kind, odds in Deal.PadlockedHolds do
	local want = odds / 100
	ok(
		math.abs(share(locked, kind) - want) < 0.03,
		`a padlock holds {kind} about {want}: {share(locked, kind)}`
	)
end
for _, kind in { "Asleep", "Awake" } do
	local want = (if kind == "Asleep" then Deal.Asleep else Deal.Odds.Build[kind])
		* Deal.PadlockedKeeper
		/ 100
	ok(
		math.abs(share(beside, kind) - want) < 0.03,
		`a keeper {kind} beside a padlock's find about {want}: {share(beside, kind)}`
	)
end
ok(
	share(beside, "Asleep") + share(beside, "Awake")
		> share(open, "Asleep") + share(open, "Awake") + 0.1,
	"a padlock has the highest chance of a keeper"
)
ok(locked.total > 1000, `enough padlocked doors to judge: {locked.total}`)
-- At the cap a padlock's keeper is asleep; in a chase none wakes there either.
ok(besideCapped.Awake == 0, "at the cap a padlock's keeper is asleep")
ok(
	share(besideCapped, "Asleep") > share(beside, "Asleep") + 0.05,
	"at the cap a padlock's keeper is dealt asleep instead"
)
ok(besidePeak.Awake == 0, "in a chase no padlock's keeper is awake")
-- Tools (GDD "Doors": about one unit in twelve): over every unit but the guard's, between one in
-- fifteen and one in ten on floors 1 and 3, and on floor 6, with more padlocks.
for _, t in { toolsLow, toolsHigh } do
	local got = share(t, "Tool")
	ok(got > 1 / 15 and got < 1 / 10, `about one unit in twelve holds a tool: 1 in {1 / got}`)
end
-- The cap turns a keeper asleep, not away.
ok(capped.Awake == 0, "at the cap nothing wakes")
ok(
	share(capped, "Asleep") > share(open, "Asleep") + 0.02,
	"at the cap a keeper is dealt asleep instead"
)
ok(peak.Awake == 0 and relief.Awake == 0, "nothing wakes in a chase or after one")
-- The sleepers: about `Deal.Asleep` in 100 of the units that can hold one, twice behind a padlock.
local sleptOpen = sleepOpen.did / math.max(1, sleepOpen.could)
local sleptLocked = sleepLocked.did / math.max(1, sleepLocked.could)
ok(
	math.abs(sleptOpen - Deal.Asleep / 100) < 0.02,
	`about {Deal.Asleep} in 100 units hold a sleeper: {sleptOpen}`
)
ok(
	math.abs(sleptLocked - Deal.Asleep * Deal.PadlockedKeeper / 100) < 0.03,
	`twice as many behind a padlock: {sleptLocked}`
)
-- Notes stand apart: the nearest two on any floor (the rule bends only with room nowhere).
ok(closest >= Deal.NoteSpacing, `two notes at least {Deal.NoteSpacing} studs apart: {closest}`)

if failures > 0 then
	print(`deal: {failures} of {checks} checks failed`)
	error("deal spec failed")
end
print(
	`deal: {checks} checks passed (nearest two notes {math.floor(closest)} studs; a tool 1 in {math.round(
		1 / share(toolsLow, "Tool") * 10
	) / 10} on floors 1 and 3, 1 in {math.round(1 / share(toolsHigh, "Tool") * 10) / 10} on 6; a keeper with a padlock find {math.round(
		(share(beside, "Asleep") + share(beside, "Awake")) * 100
	)} in 100)`
)
