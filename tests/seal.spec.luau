--!strict
-- lune run tests/seal.spec
-- Sealed finds (S5-02b2a, Finds/Seal): about one find in twenty is dealt still in its packaging,
-- read from the unit's own pick so the seed deals the same ones, whatever the find's grade and
-- whatever stuff stands in the unit; never the big find, a tool or a note's unit. Its pack fits
-- round it as spec.py fits it (a deep find turned to show its side), it's worth three times the
-- loose one, a hard drop tears it, and a packed Small find still goes in the marked box.
local Brix = require("../vendor/brix/src")
local Deal = require("../src/shared/Deal")
local Fixture = require("./fixtures/finds")
local Floor = require("../src/shared/Floor")
local Seal = require("../src/shared/Finds/Seal")
local Catalog = require("../src/shared/Tools/Catalog")
local fs = require("@lune/fs")
local luau = require("@lune/luau")

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
local function near(a: number, b: number, by: number?): boolean
	return math.abs(a - b) <= (by or 1e-6)
end

-- PackFit, loaded with Lune's Vector3 (the generated module builds them)
-- any: a generated table, read field by field
local PackFit: any = luau.load(fs.readFile("src/shared/Finds/PackFit.luau"), {
	environment = { Vector3 = Fixture.Vector3 },
})()
local function three(v: any): { number } -- any: a Lune Vector3
	return { v.X, v.Y, v.Z }
end
-- the marked box (Boxes/Specs' Marked), as Deals measures it
local BOX = { 1.8, 1.6, 1.8 }

-- 1. The share: about one in twenty picks, evenly through the picks.
do
	local n, sealed = 100000, 0
	local fifths = { 0, 0, 0, 0, 0 }
	for i = 0, n - 1 do
		local pick = (i + 0.5) / n
		if Seal.sealed(pick) then
			sealed += 1
			local f = math.floor(pick * 5) + 1
			fifths[f] += 1
		end
	end
	ok(near(sealed / n, Seal.Share, 0.005), `about 1 in 20 picks sealed ({sealed} of {n})`)
	for f, count in fifths do
		ok(near(count / (n / 5), Seal.Share, 0.006), `the {f}th fifth of picks sealed as often`)
	end
	ok(not Seal.sealed(0 / 0), "a bad pick is never sealed")
	ok(Seal.sealed(0.3) == Seal.sealed(0.3), "the same pick, the same answer")
end

-- 2. Whatever the grade, and whatever stuff stands in the unit.
do
	local random = Brix.Random.new({ seed = 4242 })
	for _, number in { 1, 12, 30 } do
		local byGrade: { [string]: { n: number, sealed: number } } = {}
		local withStuff, sealedCount = 0, 0
		for _ = 1, 60000 do
			local pick = random:nextNumber()
			local find = Deal.findFrom(number, pick)
			local row = if find then Catalog[find] else nil
			local grade = if row and row.grade then row.grade else "?"
			local g = byGrade[grade] or { n = 0, sealed = 0 }
			byGrade[grade] = g
			g.n += 1
			if Seal.sealed(pick) then
				g.sealed += 1
				sealedCount += 1
				if Deal.stuffFrom((pick * Deal.StuffScramble) % 1) then
					withStuff += 1
				end
			end
		end
		for grade, g in byGrade do
			if g.n >= 3000 then
				ok(
					near(g.sealed / g.n, Seal.Share, 0.015),
					`floor {number}: a {grade} sealed about 1 in 20 ({g.sealed} of {g.n})`
				)
			end
		end
		ok(
			near(withStuff / sealedCount, Deal.StuffShare, 0.04),
			`floor {number}: a sealed find's unit has stuff as often as any`
		)
	end
end

-- 3. The deal: from the unit's pick, the same seed the same; finds only, never the big find.
do
	local BUILD: Deal.Situation = { mood = "Build", awake = 0 }
	local finds, sealed, tools = 0, 0, 0
	local same = true
	for seed = 1, 150 do
		for _, number in { 1, 3, 6, 12, 20 } do
			local floor = Floor.generate(number, Brix.Random.new({ seed = seed }))
			local deck = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
			local again = Deal.new(floor, Brix.Random.new({ seed = seed + 1000000 }))
			local units = Deal.units(floor)
			local bigAt = units[(seed % #units) + 1]
			deck.big[bigAt] = "Jukebox"
			again.big[bigAt] = "Jukebox"
			for _, i in units do
				local c = Deal.open(deck, i, BUILD)
				local twin = Deal.open(again, i, BUILD)
				if c.sealed ~= twin.sealed then
					same = false
				end
				if i == bigAt then
					ok(c.sealed == nil, `seed {seed} floor {number}: the big find is never sealed`)
				elseif c.kind == "Find" and c.find then
					finds += 1
					local row = Catalog[c.find]
					local can = row ~= nil and Seal.packOf(row.size) ~= nil
					local should = can and Seal.sealed(deck.picks[i])
					ok(
						(c.sealed == true) == should,
						`seed {seed} floor {number} unit {i}: sealed from its own pick`
					)
					if c.sealed then
						sealed += 1
					end
				else
					if c.kind == "Tool" then
						tools += 1
					end
					ok(
						c.sealed == nil,
						`seed {seed} floor {number} unit {i}: only a find is sealed`
					)
				end
			end
		end
	end
	ok(same, "the same seed deals the same sealed finds")
	ok(finds > 2000 and tools > 200, `enough deals to judge ({finds} finds, {tools} tools)`)
	ok(
		near(sealed / finds, Seal.Share, 0.015),
		`about 1 dealt find in 20 sealed ({sealed} of {finds})`
	)
end

-- 4. The fit, as spec.py's: the cymbal monkey in the window box, worked by hand.
do
	local box = PackFit.Medium
	local s = Seal.fit({ 0.686, 1.057, 0.745 }, three(box.room), box.pad, box.stretch)
	ok(near(s[1], 0.746 / 0.836, 1e-4), "the monkey's window box: across")
	ok(near(s[2], 1.117 / 1.336, 1e-4), "the monkey's window box: up")
	ok(near(s[3], 0.805 / 0.836, 1e-4), "the monkey's window box: deep")
	-- a flat find stretches the shortest axis no less than the largest over the stretch
	local flat = Seal.fit({ 0.3, 0.02, 0.3 }, { 1, 1, 1 }, 0, 1.5)
	ok(near(flat[2], 0.2), "a flat find: its thin axis held to the largest over the stretch")
	-- turned: a find much deeper than wide shows its side to the window
	ok(Seal.turned({ 0.2, 0.3, 0.6 }), "a find three times deeper than wide is turned")
	ok(not Seal.turned({ 0.5, 0.3, 0.6 }), "a find about as deep as wide isn't")
	local held = Seal.held({ 0.2, 0.3, 0.6 })
	ok(held[1] == 0.6 and held[2] == 0.3 and held[3] == 0.2, "turned, its width and depth swap")
end

-- 5. Every find that can be sealed fits its pack, and a Small one still goes in the marked box.
local loose: { string } = {}
do
	local fitted = 0
	for key, row in Catalog do
		local size = if row.find then Seal.packOf(row.size) else nil
		local art = Fixture.boxes[key]
		if not (size and art) then
			continue
		end
		local pack = PackFit[size]
		ok(pack ~= nil, `{key}: a pack for {size}`)
		local packArt = Fixture.boxes[pack.template]
		ok(packArt ~= nil, `{key}: the {pack.template}'s art is built`)
		if not (pack and packArt) then
			continue
		end
		local find = Seal.held(three(art.Size))
		local room = three(pack.room)
		local s = Seal.fit(find, room, pack.pad, pack.stretch)
		local top = math.max(s[1], s[2], s[3])
		for i = 1, 3 do
			ok(
				s[i] * room[i] >= find[i] + 2 * pack.pad - 1e-6,
				`{key}: its pack holds it on axis {i}`
			)
			ok(s[i] >= top / pack.stretch - 1e-6, `{key}: axis {i} never squashed past the stretch`)
		end
		local outer = Seal.outer(three(packArt.Size), s)
		-- a palm-sized one (none of it past 0.6 studs) still goes in the box sealed; a long Small
		-- one (the fairy lights' coil, near a stud across) stretches its blister past the box
		if size == "Small" and math.max(find[1], find[2], find[3]) <= 0.6 then
			ok(Deal.packs(outer, BOX), `{key}: a palm-sized find, sealed, still goes in the box`)
		end
		if not Deal.packs(outer, BOX) then
			table.insert(loose, key)
		end
		fitted += 1
	end
	ok(fitted >= 30, `most finds can be sealed ({fitted})`)
	table.sort(loose)
end

-- 6. Worth three times; the tear on a hard drop.
do
	ok(Seal.worth(40, true) == 120, "sealed: 40 to 120")
	ok(Seal.worth(40, false) == 40, "loose: its worth")
	ok(Seal.worth(0, true) == 0, "worth nothing sealed is still nothing")
	ok(Seal.tears(true, 16, 2), "sealed, let go at a run: torn")
	ok(Seal.tears(true, 0, 6), "sealed, let go from high up: torn")
	ok(not Seal.tears(true, 0, 2), "sealed, set down standing: whole")
	ok(not Seal.tears(false, 16, 2), "loose: nothing to tear")
	ok(Seal.packOf("Big") == nil and Seal.packOf(nil) == nil, "a big find or a tool: never sealed")
end

-- 7. How a find lies in its pack (S5-02b2b1): a flat one (the fairy lights' coil) on its back in
-- the blister, its top to the window; a deep one turned; the rest upright. And how high its pack
-- holds it off the floor: always above, never past a carton's floor.
local tipped: { string } = {}
do
	ok(Seal.tipped({ 0.98, 0.11, 0.57 }), "the fairy lights' coil lies flat: tipped")
	ok(not Seal.turned({ 0.98, 0.11, 0.57 }), "tipped, never turned too")
	local held = Seal.held({ 0.98, 0.11, 0.57 })
	ok(held[1] == 0.98 and held[2] == 0.57 and held[3] == 0.11, "tipped: its height and depth swap")
	ok(Seal.way({ 0.98, 0.11, 0.57 }) == "Tipped", "the fairy lights' way: tipped")
	ok(not Seal.tipped({ 0.5, 0.3, 0.6 }), "a squat find isn't flat")
	ok(Seal.way({ 0.5, 0.3, 0.6 }) == "Upright", "a squat find stands upright")
	ok(Seal.turned({ 0.2, 0.3, 0.6 }), "a long thin find is still turned, not tipped")
	ok(Seal.way({ 0.2, 0.3, 0.6 }) == "Turned", "a long thin find's way: turned")
	-- worked by hand: the monkey upright in its window box sits 0.8361 * 0.68 - 1.057 / 2 up
	local box = PackFit.Medium
	local lift = Seal.lift(
		{ 0.686, 1.057, 0.745 },
		three(box.room),
		three(box.roomCentre),
		box.pad,
		box.stretch,
		0.43
	)
	ok(near(lift, (1.117 / 1.336) * 0.68 - 1.057 / 2, 1e-4), "the monkey's lift in its window box")
	for key, row in Catalog do
		local size = if row.find then Seal.packOf(row.size) else nil
		local art = Fixture.boxes[key]
		if not (size and art) then
			continue
		end
		local pack = PackFit[size]
		local packArt = Fixture.boxes[pack.template]
		if not packArt then
			continue
		end
		local find = three(art.Size)
		if Seal.tipped(find) then
			table.insert(tipped, key)
		end
		local up = Seal.lift(
			find,
			three(pack.room),
			three(pack.roomCentre),
			pack.pad,
			pack.stretch,
			packArt.Size.Z / 2
		)
		ok(up > 0, `{key}: its pack holds it off the floor ({up})`)
		ok(up < 0.8, `{key}: no higher than a carton's floor ({up})`)
	end
	table.sort(tipped)
	ok(table.find(tipped, "FairyLights") ~= nil, "the fairy lights are tipped")
	ok(#tipped <= 6, `only flat finds are tipped ({#tipped})`)
end

-- Kept sealed (S5-02b2c, D-427): a name of its own in the save, back to its find, never a Gold's
-- or a find's own name; three times the worth.
do
	ok(Seal.key("Teddy") == "Teddy:Sealed", "a sealed teddy is kept as Teddy:Sealed")
	ok(Seal.base("Teddy:Sealed") == "Teddy", "and back to the teddy")
	ok(Seal.base("Teddy") == nil, "a plain find's name isn't a sealed one's")
	ok(Seal.base("Teddy:Gold") == nil, "nor a Gold's")
	ok(Seal.base(":Sealed") == nil, "the mark alone names no find")
	for key, row in Catalog do
		if row.find then
			ok(Seal.base(key) == nil, `{key}: no find's own name reads as sealed`)
			ok(Seal.base(Seal.key(key)) == key, `{key}: its sealed name goes back to it`)
		end
	end
	ok(Seal.worth(40, true) == 120 and Seal.worth(40, false) == 40, "sealed, three times")
end

if failures > 0 then
	print(`seal: {failures} of {checks} checks failed`)
	error("seal spec failed")
end
print(
	`seal: {checks} checks passed (standing loose: {table.concat(loose, ", ")}; tipped: {table.concat(
		tipped,
		", "
	)})`
)
