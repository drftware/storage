--!strict
-- The team picks the next floor on the ride (S4-03, the GDD's "The team's choice"): three
-- versions of the floor light up, dealt from the climb's seed so one seed always offers the same
-- three, never on the ride up from the lobby and never a version below its lowest floor; most
-- presses wins and a tie, or nobody pressing, goes at random. Run: lune run tests/nextfloor.spec
local Brix = require("../vendor/brix/src")
local Climb = require("../src/shared/Climb")
local KeeperRows = require("../src/shared/KeeperRows")
local NextFloor = require("../src/shared/NextFloor")
local Pay = require("../src/shared/Pay")

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

local SEEDS = 300
local HIGH = 60

local function deal(seed: number, number: number): { string }
	return NextFloor.deal(number, Brix.Random.new({ seed = NextFloor.seedOf(seed, number) }))
end

local function allowed(number: number): number
	local n = 0
	for _, v in NextFloor.Versions do
		if number >= v.lowest then
			n += 1
		end
	end
	return n
end

-- 1. Every version is a sound row: named once, never on floor 1, paying something, its bends
-- making a floor harder, its lean naming real monsters.
local seen: { [string]: boolean } = {}
for _, v in NextFloor.Versions do
	ok(not seen[v.name], `{v.name} is named once`)
	seen[v.name] = true
	ok(NextFloor.find(v.name) == v, `{v.name} is found by its name`)
	ok(v.lowest >= 2 and v.lowest == math.floor(v.lowest), `{v.name}'s lowest floor is 2 or up`)
	ok(v.pay > 0, `{v.name} pays more than the floor alone`)
	ok(v.monsters == nil or v.monsters > 1, `{v.name} brings more monsters, not fewer`)
	ok(v.padlocks == nil or v.padlocks > 1, `{v.name} padlocks more doors, not fewer`)
	local bends = (v.dark and 1 or 0)
		+ (v.monsters and 1 or 0)
		+ (v.padlocks and 1 or 0)
		+ (v.caughtToLobby and 1 or 0)
		+ (v.lean and 1 or 0)
	ok(bends > 0, `{v.name} changes something about its floor`)
	for name, chance in v.lean or {} do
		ok(KeeperRows[name] ~= nil, `{v.name} leans a real monster ({name})`)
		ok(chance >= 0 and chance <= 1, `{v.name}'s lean on {name} is a chance`)
	end
end
ok(#NextFloor.Versions >= NextFloor.Offered, "there are at least three versions to deal")
ok(allowed(2) >= NextFloor.Offered, "floor 2, the first floor picked, has three to offer")
ok(NextFloor.find("Nothing") == nil, "no version by a made-up name")

-- 2. Never on the ride up from the lobby: floor 1 (and below) is offered nothing.
for seed = 1, SEEDS do
	ok(#deal(seed, 1) == 0, `seed {seed}: floor 1 offers nothing`)
	ok(#deal(seed, 0) == 0, `seed {seed}: no floor 0 offer`)
end

-- 3. Every floor from 2 up: three versions, each once, each allowed on that floor.
for seed = 1, SEEDS do
	for number = 2, HIGH do
		local d = deal(seed, number)
		ok(
			#d == math.min(NextFloor.Offered, allowed(number)),
			`seed {seed} floor {number}: {#d} offered`
		)
		local once: { [string]: boolean } = {}
		for _, name in d do
			local v = NextFloor.find(name)
			ok(v ~= nil, `seed {seed} floor {number}: {name} is a version`)
			ok(not once[name], `seed {seed} floor {number}: {name} offered once`)
			once[name] = true
			ok(v ~= nil and number >= v.lowest, `seed {seed} floor {number}: {name} allowed here`)
		end
	end
end

-- 4. A version only from the floor it's allowed on: the harshest never on floor 2, but on
-- floor 3 up for some seeds.
local caughtOn2, caughtOn3 = 0, 0
for seed = 1, SEEDS do
	if table.find(deal(seed, 2), "CaughtToLobby") then
		caughtOn2 += 1
	end
	if table.find(deal(seed, 3), "CaughtToLobby") then
		caughtOn3 += 1
	end
end
ok(caughtOn2 == 0, `caught to the lobby is never offered on floor 2 ({caughtOn2})`)
ok(caughtOn3 > 0, `caught to the lobby is offered on floor 3 for some climbs ({caughtOn3})`)

-- 5. One seed, the same three in the same order, every time; climbs differ from each other.
local sets: { [string]: boolean } = {}
local shown: { [string]: number } = {}
for seed = 1, SEEDS do
	for number = 2, 12 do
		local a = table.concat(deal(seed, number), ",")
		ok(a == table.concat(deal(seed, number), ","), `seed {seed} floor {number}: same three`)
		if number == 5 then
			sets[a] = true
			for _, name in deal(seed, number) do
				shown[name] = (shown[name] or 0) + 1
			end
		end
	end
end
local kinds = 0
for _ in sets do
	kinds += 1
end
ok(kinds >= 4, `floor 5 is offered differently from climb to climb ({kinds} ways)`)
for _, v in NextFloor.Versions do
	ok((shown[v.name] or 0) > 0, `{v.name} turns up on floor 5 in some climb`)
end
-- the offer shares no seed with the floor's layout or its monsters
ok(NextFloor.seedOf(7, 5) ~= Climb.seedOf(7, 5), "the offer's seed isn't the floor's own")

-- 6. The vote: most presses wins.
local offered = { "PowerOut", "TwiceMonsters", "TwicePadlocks" }
for seed = 1, SEEDS do
	local r = Brix.Random.new({ seed = seed })
	ok(
		NextFloor.winner({ "TwiceMonsters", "TwiceMonsters", "PowerOut" }, offered, r)
			== "TwiceMonsters",
		`seed {seed}: two presses beat one`
	)
	ok(
		NextFloor.winner({ [101] = "TwicePadlocks" }, offered, r) == "TwicePadlocks",
		`seed {seed}: one press alone wins`
	)
end

-- 7. A tie goes at random, only ever to one of the tied, and to each of them sometimes.
local tieWins: { [string]: number } = {}
for seed = 1, SEEDS do
	local w = NextFloor.winner(
		{ "PowerOut", "TwicePadlocks", "PowerOut", "TwicePadlocks", "TwiceMonsters" },
		offered,
		Brix.Random.new({ seed = seed })
	)
	ok(w == "PowerOut" or w == "TwicePadlocks", `seed {seed}: a tie goes to one of the tied`)
	if w then
		tieWins[w] = (tieWins[w] or 0) + 1
	end
end
ok(
	(tieWins.PowerOut or 0) > 0 and (tieWins.TwicePadlocks or 0) > 0,
	"a tie goes either way across climbs"
)

-- 8. Nobody pressed: still a floor, any of the three, each sometimes.
local noneWins: { [string]: number } = {}
for seed = 1, SEEDS do
	local w = NextFloor.winner({}, offered, Brix.Random.new({ seed = seed }))
	ok(w ~= nil and table.find(offered, w) ~= nil, `seed {seed}: no presses still picks one`)
	if w then
		noneWins[w] = (noneWins[w] or 0) + 1
	end
end
for _, name in offered do
	ok((noneWins[name] or 0) > 0, `with no presses {name} is picked sometimes`)
end

-- 9. A press for something not lit counts for nothing; nothing lit picks nothing.
for seed = 1, 50 do
	local r = Brix.Random.new({ seed = seed })
	ok(
		NextFloor.winner({ "CaughtToLobby", "CaughtToLobby", "Nothing", "PowerOut" }, offered, r)
			== "PowerOut",
		`seed {seed}: presses for unlit versions don't count`
	)
	ok(NextFloor.winner({ "PowerOut" }, {}, r) == nil, `seed {seed}: nothing lit, nothing picked`)
end

-- 10. What the car tells screens survives the trip, junk and all.
local presses = { [42] = "PowerOut", [7] = "TwiceMonsters", [-3] = "PowerOut" }
local text = NextFloor.encodePresses(presses)
ok(text == "-3:PowerOut,7:TwiceMonsters,42:PowerOut", `presses in UserId order ({text})`)
local back = NextFloor.decodePresses(text)
ok(
	back[42] == "PowerOut" and back[7] == "TwiceMonsters" and back[-3] == "PowerOut",
	"presses read back"
)
local junk = NextFloor.decodePresses("5:Nothing,x:PowerOut,9:TwicePadlocks,,")
ok(junk[5] == nil and junk[9] == "TwicePadlocks", "junk presses are dropped")
ok(next(NextFloor.decodePresses("")) == nil, "no presses read as none")
ok(NextFloor.encodePresses({}) == "", "no presses written as nothing")
local o = NextFloor.decodeOffer(NextFloor.encodeOffer(offered))
ok(table.concat(o, ",") == table.concat(offered, ","), "the offer reads back in order")
ok(
	table.concat(NextFloor.decodeOffer("PowerOut,Nothing,PowerOut,TwicePadlocks"), ",")
		== "PowerOut,TwicePadlocks",
	"an offer keeps only real versions, each once"
)
ok(#NextFloor.decodeOffer("") == 0, "no offer reads as none")

-- 11. A harder floor pays more: every version adds coins, more higher up, the harshest the most.
for _, v in NextFloor.Versions do
	for number = 2, HIGH do
		local extra = NextFloor.payOf(v, number)
		ok(extra >= 1 and extra == math.floor(extra), `{v.name} floor {number}: pays whole coins`)
		ok(extra >= NextFloor.payOf(v, number - 1), `{v.name} pays no less a floor higher`)
	end
end
local power = NextFloor.find("PowerOut")
local caught = NextFloor.find("CaughtToLobby")
ok(
	power ~= nil and NextFloor.payOf(power, 2) == math.floor(Pay.forFloor(2) * 0.5 + 0.5),
	"the power out pays half floor 2's coins again"
)
ok(
	power ~= nil and caught ~= nil and NextFloor.payOf(caught, 10) > NextFloor.payOf(power, 10),
	"being sent to the lobby pays more than the dark"
)

-- 12. The vote ends with room to deal the picked floor and stream it before the hand-off.
ok(NextFloor.Closes > 0, "the vote runs into the ride")
ok(
	NextFloor.Closes + Climb.StreamWait <= Climb.HandOff - Climb.Lead,
	`the vote ends ({NextFloor.Closes} s) in time for the hand-off ({Climb.HandOff} s)`
)

print(`nextfloor.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
