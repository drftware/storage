--!strict
-- lune run tests/carry.spec
-- Your three slots (L-11b, L-20a): a tool you take lands in your hand, in the empty slot you're on
-- or else a free one; full hands refuse; a switch picks a slot; dropping or handing over takes
-- what's in your hand and leaves that hand empty; a pocketed tool stays yours but out of your hand
-- until a switch or a lift brings it up; a slot from the wire must be a whole 1 to 3; clearing
-- gives every tool back; and a hand moves no faster than a quick thumb. Plus the catalog's rows
-- are whole, each a dealt tool with its built art's sizes, or a dealt find (S1-05) with its grip,
-- inside its art's box, and its heft. A find rides the same slots: it takes one, full slots
-- refuse it, and a catch drops it with your tools (GDD "Finds").
local fs = require("@lune/fs")

local Carry = require("../src/shared/Tools/Carry")
local Catalog = require("../src/shared/Tools/Catalog")
local Deal = require("../src/shared/Deal")
local Drive = require("../src/shared/Finds/Drive")
local Grades = require("../src/shared/Grades")
local Use = require("../src/shared/Finds/Use")

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

-- empty hands: nothing held, room in your hand
do
	local c = Carry.new()
	ok(Carry.held(c) == nil, "a new carry holds nothing")
	ok(Carry.count(c) == 0, "a new carry counts none")
	ok(Carry.room(c) == 1, "room is your hand's slot")
end

-- three slots, as the owner's wheel note says (L-20)
ok(Carry.Slots == 3, "three slots")

-- the first tool goes in your hand; each next one goes in a free slot and into your hand
do
	local c = Carry.new()
	ok(Carry.take(c, "a") == 1, "first tool into slot 1")
	ok(Carry.held(c) == "a", "and it's in your hand")
	ok(Carry.take(c, "b") == 2, "second tool into slot 2")
	ok(Carry.held(c) == "b" and c.active == 2, "the second is now in your hand")
	ok(Carry.take(c, "c") == 3, "third tool into slot 3")
	ok(Carry.held(c) == "c" and c.active == 3, "the third is now in your hand")
	ok(Carry.count(c) == 3, "three carried")
	ok(Carry.room(c) == nil, "no room with every slot full")
	ok(Carry.take(c, "d") == nil, "a fourth is refused")
	ok(Carry.held(c) == "c" and Carry.find(c, "d") == nil, "the refusal changed nothing")
	ok(Carry.take(c, "a") == nil, "a tool you carry can't be taken twice")
end

-- your hand on an empty slot takes the new tool there, even with the other slot free
do
	local c = Carry.new()
	Carry.select(c, 2)
	ok(Carry.take(c, "a") == 2, "into the empty slot in your hand")
	ok(c.slots[1] == nil, "slot 1 left free")
end

-- a full hand puts the new tool in the free slot and switches to it
do
	local c = Carry.new()
	Carry.take(c, "a")
	ok(Carry.room(c) == 2, "room is the other slot when your hand is full")
	Carry.take(c, "b")
	Carry.select(c, 1)
	ok(Carry.held(c) == "a", "switch back to the first")
	Carry.release(c)
	ok(Carry.held(c) == nil and c.active == 1, "released: your hand is empty, still on slot 1")
	ok(Carry.take(c, "c") == 1, "the next tool fills the empty hand")
end

-- switching
do
	local c = Carry.new()
	ok(not Carry.select(c, 1), "selecting the slot you're on changes nothing")
	ok(Carry.select(c, 2), "selecting the other slot changes")
	ok(Carry.held(c) == nil, "an empty slot is an empty hand")
end

-- pocketing: the tool stays on your slot, your hand is empty, a lift or a switch brings it up
do
	local c = Carry.new()
	ok(not Carry.pocket(c, true), "an empty slot has nothing to pocket")
	ok(not c.pocketed and Carry.hand(c) == 1, "and your hand stays on it")
	Carry.take(c, "a")
	ok(Carry.pocket(c, true), "pocket the tool in your hand")
	ok(Carry.held(c) == nil and Carry.find(c, "a") == 1, "pocketed: an empty hand, still yours")
	ok(Carry.hand(c) == 0 and c.active == 1, "no slot in your hand, still on slot 1")
	ok(not Carry.pocket(c, true), "pocketing twice changes nothing")
	ok(Carry.release(c) == nil and Carry.find(c, "a") == 1, "a pocketed tool can't be dropped")
	ok(Carry.pocket(c, false), "bring it back up")
	ok(Carry.held(c) == "a" and Carry.hand(c) == 1, "it's in your hand again")
	ok(not Carry.pocket(c, false), "lifting a lifted tool changes nothing")
	Carry.pocket(c, true)
	ok(Carry.select(c, 1), "picking your own slot brings its pocketed tool up")
	ok(Carry.held(c) == "a", "up in your hand")
	Carry.pocket(c, true)
	ok(Carry.select(c, 2) and not c.pocketed, "switching away lifts: an empty hand on slot 2")
	Carry.select(c, 1)
	Carry.pocket(c, true)
	ok(Carry.take(c, "b") == 2, "a pick-up while pocketed goes in a free slot")
	ok(Carry.held(c) == "b" and not c.pocketed, "and comes up into your hand")
	ok(Carry.find(c, "a") == 1, "the pocketed one stays yours")
	Carry.pocket(c, true)
	Carry.clear(c)
	ok(not c.pocketed and Carry.count(c) == 0, "clearing leaves nothing pocketed")
end

-- releasing
do
	local c = Carry.new()
	ok(Carry.release(c) == nil, "an empty hand releases nothing")
	Carry.take(c, "a")
	Carry.take(c, "b")
	ok(Carry.release(c) == "b", "release gives the tool in your hand")
	ok(Carry.count(c) == 1 and Carry.find(c, "a") == 1, "the other stays")
	ok(Carry.release(c) == nil, "nothing left in that hand")
end

-- clearing
do
	local c = Carry.new()
	Carry.take(c, "a")
	Carry.take(c, "b")
	local all = Carry.clear(c)
	ok(#all == 2 and all[1] == "a" and all[2] == "b", "clear gives them all, slot order")
	ok(Carry.count(c) == 0 and c.active == 1, "and empties the carry")
end

-- a slot from the wire
do
	ok(Carry.slot(1) == 1 and Carry.slot(2) == 2 and Carry.slot(3) == 3, "1 to 3 are slots")
	for _, bad in { 0, 4, -1, 1.5, 0 / 0, math.huge, "1", true, nil, {} } :: { any } do
		ok(Carry.slot(bad) == nil, `not a slot: {tostring(bad)}`)
	end
end

-- the hand's rate: a burst, then one per gap
do
	local t = 100
	local last: number? = nil
	local burst = Carry.Burst
	local passed = 0
	for _ = 1, 10 do
		local may, left = Carry.allow(last, burst, t)
		if may then
			passed += 1
			last, burst = t, left
		end
	end
	ok(passed == Carry.Burst, `a burst of {Carry.Burst} at once ({passed})`)
	local may = Carry.allow(last, burst, t + Carry.Gap * 0.5)
	ok(not may, "nothing more within a gap")
	may = Carry.allow(last, burst, t + Carry.Gap * 1.01)
	ok(may, "one more after a gap")
	local _, left = Carry.allow(last, 0, t + Carry.Gap * 100)
	ok(left == Carry.Burst - 1, "a long rest refills the burst, no more")
end

-- a find takes a slot as a tool does (S1-05): one tap, into your hand, beside your tools
do
	local c = Carry.new()
	Carry.take(c, "BoltCutters1")
	Carry.take(c, "Saw2")
	ok(Carry.take(c, "Boombox3") == 3, "a find takes the free slot beside two tools")
	ok(Carry.held(c) == "Boombox3", "and comes into your hand")
	ok(Carry.count(c) == 3, "a find counts as one of your three")
	ok(Carry.room(c) == nil, "two tools and a find: no room")
	ok(Carry.take(c, "Teddy4") == nil, "full slots refuse a find")
	ok(Carry.take(c, "Padlock5") == nil, "and a tool")
	ok(Carry.find(c, "Teddy4") == nil, "the refused find isn't carried")
	-- drop the find and the slot is free for the other
	ok(Carry.release(c) == "Boombox3", "dropping lets go of the find in your hand")
	ok(Carry.take(c, "Teddy4") == 3, "the freed slot takes the next find")
end

-- three finds and no tools: the GDD's trade, carry finds and have nothing to open doors with
do
	local c = Carry.new()
	for i, id in { "Boombox1", "Television2", "Skates3" } do
		ok(Carry.take(c, id) == i, `find {i} into slot {i}`)
	end
	ok(Carry.take(c, "BoltCutters4") == nil, "three finds leave no room for a tool")
end

-- caught: your finds drop with your tools, every one, and your hands are empty
do
	local c = Carry.new()
	Carry.take(c, "Padlock1")
	Carry.take(c, "Teddy2")
	Carry.take(c, "AirHorn3")
	Carry.select(c, 2)
	Carry.pocket(c, true)
	local dropped = Carry.clear(c)
	ok(#dropped == 3, "a catch drops all three")
	ok(table.find(dropped, "Teddy2") ~= nil, "the pocketed find drops too")
	ok(
		table.find(dropped, "Padlock1") ~= nil and table.find(dropped, "AirHorn3") ~= nil,
		"and the tools"
	)
	ok(Carry.count(c) == 0 and Carry.held(c) == nil, "nothing carried after")
	ok(Carry.take(c, "Teddy2") == 1, "a friend's or your own next take starts over")
end

-- the catalog: every row whole. A tool is one the deal hands out (so a dealt one is laid), with
-- the sizes its art build writes (Tools.specs reads them by key); a find is one of the deal's
-- finds, with a grip inside its art's box and a heft
-- (the generated Specs and sets build Vector3s, which Lune lacks: the fixture loads them)
local FindBoxes = require("./fixtures/finds").boxes
for key, row in Catalog do
	ok(type(row.name) == "string" and #row.name > 0, `{key}: a name`)
	if row.find then
		ok(table.find(Deal.Finds, key) ~= nil, `{key}: one of the deal's finds`)
		ok(table.find(Deal.Tools, key) == nil, `{key}: a find, not a tool`)
		local box = FindBoxes[row.template]
		ok(box ~= nil, `{key}: its art's sizes`)
		local g = row.grip
		ok(g ~= nil and #g == 3, `{key}: a grip`)
		if box and g then
			local half, c = box.Size / 2, box.Centre
			ok(
				math.abs(g[1] - c.X) <= half.X
					and g[2] >= 0
					and g[2] <= box.Size.Y
					and math.abs(g[3] - c.Z) <= half.Z,
				`{key}: its grip is on it`
			)
		end
		ok(Grades.Worth[row.grade] ~= nil, `{key}: a grade`)
		local range = Grades.Worth[row.grade]
		ok(
			range ~= nil
				and type(row.worth) == "number"
				and row.worth >= range[1]
				and row.worth <= range[2],
			`{key}: a worth within its grade's`
		)
		ok(type(row.heft) == "number" and row.heft >= 0 and row.heft <= 1, `{key}: a heft, 0 to 1`)
		-- a find takes one hand; it does something only with a press of its own (Finds/Use, or
		-- the RC car's Drive, Finds/Drive)
		local press = Use.Rows[key]
		local word = if press then press.verb elseif key == Drive.Key then Drive.Verb else nil
		ok(not row.bothHands, `{key}: a find takes one hand`)
		ok(row.verb == word, `{key}: its press's word, or none`)
	else
		ok(table.find(Deal.Tools, key) ~= nil, `{key}: one of the deal's tools`)
		ok(fs.isFile(`src/shared/Tools/Specs/{key}.luau`), `{key}: its generated Specs`)
	end
	ok(#row.hold == 3 and #row.holdTurn == 3 and #row.inHand == 3, `{key}: hold, turn, hand`)
	ok(#row.use == 3 and #row.useTurn == 3, `{key}: its use pose`)
	ok(#row.icon == 4, `{key}: icon`)
	for _, s in { row.pickUp, row.drop } do
		ok(string.find(s.id, "^rbxassetid://%d+$") ~= nil, `{key}: a sound id`)
		ok(s.length > 0 and s.from >= 0 and s.volume > 0, `{key}: a sound's stretch`)
	end
end

-- every find the deal hands out has its row, so a find unit never opens on nothing
for _, key in Deal.Finds do
	local row = Catalog[key]
	ok(row ~= nil and row.find == true, `{key}: dealt, so it has a find's row`)
end

-- and the other way round: every tool the deal hands out is built, with a catalog row and its
-- generated Specs, so no door opens on an empty unit (L-14e: the cut blanket and glow sticks
-- were still dealt, and about one tool unit in five opened on nothing)
for _, key in Deal.Tools do
	ok(Catalog[key] ~= nil, `{key}: dealt, so it has a catalog row`)
	ok(fs.isFile(`src/shared/Tools/Specs/{key}.luau`), `{key}: dealt, so it has its Specs`)
	ok((Deal.Bag[key] or 0) >= 1, `{key}: in the bag at least once`)
end
for key in Deal.Bag do
	ok(table.find(Deal.Tools, key) ~= nil, `{key}: in the bag, so one of the deal's tools`)
end

-- What the Packrat takes when it reaches you (S2-06c): the most valuable find, else a tool (the
-- one in your hand first), never the ladder, and nothing from empty slots
local function worth(key: string): number?
	return Carry.worth(Catalog[key])
end
ok(Carry.prize({ "", "", "" }, 1, worth) == 0, "empty slots: nothing to take")
ok(Carry.prize({ "Teddy", "Television", "Skates" }, 1, worth) == 2, "it takes the television")
ok(Carry.prize({ "Boombox", "Skates", "" }, 2, worth) == 1, "the boombox over the skates")
ok(Carry.prize({ "Teddy", "", "" }, 1, worth) == 1, "even a teddy")
local tools: { string } = {}
for key, row in Catalog do
	if not row.find and not row.bothHands then
		table.insert(tools, key)
	elseif row.bothHands then
		ok(Carry.worth(row) == nil, `it never takes the {key}`)
	end
end
table.sort(tools)
ok(#tools >= 2, "two tools to check with")
ok(Carry.prize({ tools[1], "Teddy", tools[2] }, 1, worth) == 2, "a find before a tool")
ok(Carry.prize({ tools[1], "", tools[2] }, 3, worth) == 3, "no find: the tool in your hand")
ok(Carry.prize({ tools[1], tools[2], "" }, 3, worth) == 1, "else the first tool")
ok(Carry.worth(nil) == nil, "nothing for no row")

print(`carry: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
