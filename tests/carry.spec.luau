--!strict
-- lune run tests/carry.spec
-- Your two slots (L-11b): a tool you take lands in your hand, in the empty slot you're on or else
-- the other one; full hands refuse; a switch picks a slot; dropping or handing over takes what's
-- in your hand and leaves that hand empty; a slot from the wire must be a whole 1 or 2; clearing
-- gives every tool back; and a hand moves no faster than a quick thumb. Plus the catalog's rows
-- are whole, each a dealt tool with its built art's sizes.
local fs = require("@lune/fs")

local Carry = require("../src/shared/Tools/Carry")
local Catalog = require("../src/shared/Tools/Catalog")
local Deal = require("../src/shared/Deal")

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

-- the first tool goes in your hand; the second goes in the other slot and into your hand
do
	local c = Carry.new()
	ok(Carry.take(c, "a") == 1, "first tool into slot 1")
	ok(Carry.held(c) == "a", "and it's in your hand")
	ok(Carry.take(c, "b") == 2, "second tool into slot 2")
	ok(Carry.held(c) == "b" and c.active == 2, "the second is now in your hand")
	ok(Carry.count(c) == 2, "two carried")
	ok(Carry.room(c) == nil, "no room with both full")
	ok(Carry.take(c, "c") == nil, "a third is refused")
	ok(Carry.held(c) == "b" and Carry.find(c, "c") == nil, "the refusal changed nothing")
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
	ok(#all == 2 and all[1] == "a" and all[2] == "b", "clear gives both, slot order")
	ok(Carry.count(c) == 0 and c.active == 1, "and empties the carry")
end

-- a slot from the wire
do
	ok(Carry.slot(1) == 1 and Carry.slot(2) == 2, "1 and 2 are slots")
	for _, bad in { 0, 3, -1, 1.5, 0 / 0, math.huge, "1", true, nil, {} } :: { any } do
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

-- the catalog: every row whole, a tool the deal hands out (so a dealt one is laid), with the
-- sizes its art build writes (Tools.specs reads them by key)
for key, row in Catalog do
	ok(type(row.name) == "string" and #row.name > 0, `{key}: a name`)
	ok(table.find(Deal.Tools, key) ~= nil, `{key}: one of the deal's tools`)
	ok(fs.isFile(`src/shared/Tools/Specs/{key}.luau`), `{key}: its generated Specs`)
	ok(#row.hold == 3 and #row.holdTurn == 3 and #row.inHand == 3, `{key}: hold, turn, hand`)
	ok(#row.use == 3 and #row.useTurn == 3, `{key}: its use pose`)
	ok(#row.icon == 4, `{key}: icon`)
	for _, s in { row.pickUp, row.drop } do
		ok(string.find(s.id, "^rbxassetid://%d+$") ~= nil, `{key}: a sound id`)
		ok(s.length > 0 and s.from >= 0 and s.volume > 0, `{key}: a sound's stretch`)
	end
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

print(`carry: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
