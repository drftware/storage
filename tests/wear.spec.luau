--!strict
-- lune run tests/wear.spec
-- Tools wear out (S1-08, GDD "Tools wear out"): bolt cutters cut 3 padlocks, the saw 2 holes, the
-- air horn 3 blasts, and the use that spends the last breaks it; the ladder never wears, and the
-- padlock and the bubble wrap are used up whole as they're placed, so they carry no wear. The
-- slot's mark: one notch a use, the lit ones the uses left, the last one warning; none for a tool
-- that never wears. A breaking tool comes out of whichever slot it's in.
local Carry = require("../src/shared/Tools/Carry")
local Catalog = require("../src/shared/Tools/Catalog")
local Wear = require("../src/shared/Tools/Wear")

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

-- the GDD's table
ok(Wear.full("BoltCutters") == 3, "bolt cutters: 3 padlocks")
ok(Wear.full("Saw") == 2, "the saw: 2 holes")
ok(Wear.full("AirHorn") == 3, "the air horn: 3 blasts")
ok(Wear.full("Ladder") == nil, "the ladder never wears out")
ok(Wear.full("Padlock") == nil, "a padlock is used up whole on its door, no wear")
ok(Wear.full("BubbleWrap") == nil, "the roll is used up whole as it's laid, no wear")
ok(Wear.full("Television") == nil, "a find never wears out")
ok(Wear.full("Nothing") == nil, "an unknown key wears nothing")

-- spending: each use takes one, and the one that spends the last breaks it
local function useUp(key: string): (number, number?)
	local left = Wear.full(key)
	local uses = 0
	while uses < 20 do
		if not Wear.usable(left) then
			break
		end
		uses += 1
		local broke
		left, broke = Wear.spend(left)
		if broke then
			return uses, left
		end
	end
	return uses, left
end
for key, row in Catalog do
	local w = row.wear
	if w then
		local uses, left = useUp(key)
		ok(uses == w.uses, `{key}: breaks on use {w.uses} (broke on {uses})`)
		ok(left == 0, `{key}: nothing left once broken`)
		ok(not Wear.usable(left), `{key}: a broken one doesn't work`)
	end
end
do
	local left, broke = Wear.spend(3)
	ok(left == 2 and not broke, "a first cut leaves 2, unbroken")
	left, broke = Wear.spend(2)
	ok(left == 1 and not broke, "a second leaves 1, unbroken")
	left, broke = Wear.spend(1)
	ok(left == 0 and broke, "the third breaks them")
	left, broke = Wear.spend(0)
	ok(left == 0 and not broke, "a spent one never breaks twice")
	local n, b = Wear.spend(nil)
	ok(n == nil and not b, "a tool that never wears spends nothing")
	ok(Wear.usable(nil), "a tool that never wears always works")
	ok(Wear.usable(1) and not Wear.usable(0), "one use left works; none doesn't")
end

-- the slot's mark
do
	local n, lit, last = Wear.mark("BoltCutters", 3)
	ok(n == 3 and lit == 3 and not last, "new cutters: three notches, all lit")
	n, lit, last = Wear.mark("BoltCutters", 2)
	ok(n == 3 and lit == 2 and not last, "after a cut: two lit")
	n, lit, last = Wear.mark("BoltCutters", 1)
	ok(n == 3 and lit == 1 and last, "on their last: one lit, warning")
	n, lit, last = Wear.mark("Saw", 1)
	ok(n == 2 and lit == 1 and last, "a saw with one hole left warns")
	n, lit, last = Wear.mark("Ladder", 0)
	ok(n == 0 and lit == 0 and not last, "the ladder: no mark")
	n = Wear.mark("Padlock", 0)
	ok(n == 0, "a padlock: no mark")
	n, lit = Wear.mark("AirHorn", 9)
	ok(n == 3 and lit == 3, "never more lit than notches")
	n, lit = Wear.mark("AirHorn", -2)
	ok(n == 3 and lit == 0, "never fewer than none")
	ok(Wear.slotAttribute(2) == "ToolUses2", "slot 2's attribute")
end

-- each wearing row is whole: uses, a short beat before it breaks, a real sound, bits in range
for key, row in Catalog do
	local w = row.wear
	if w then
		ok(w.uses >= 2 and w.uses == math.floor(w.uses), `{key}: a whole number of uses, 2 or more`)
		ok(w.late > 0 and w.late <= 1, `{key}: breaks within a second of its last use`)
		ok(string.match(w.snap.id, "^rbxassetid://%d+$") ~= nil, `{key}: its snap is an asset`)
		ok(w.snap.length > 0 and w.snap.volume > 0, `{key}: its snap plays`)
		for _, c in w.bits do
			ok(#c == 3, `{key}: a bit's colour is red, green, blue`)
			for _, v in c do
				ok(v >= 0 and v <= 255, `{key}: a bit's colour in range`)
			end
		end
		ok(row.find ~= true, `{key}: a find never wears`)
	end
end

-- a breaking tool comes out of whichever slot it's in, your hand staying put
do
	local c = Carry.new()
	Carry.take(c, "a")
	Carry.take(c, "b")
	ok(Carry.held(c) == "b", "the second taken is in hand")
	ok(Carry.remove(c, "a"), "the one not in hand comes out")
	ok(Carry.find(c, "a") == nil and Carry.held(c) == "b", "the hand still holds the other")
	ok(not Carry.remove(c, "a"), "nothing to remove twice")
	ok(Carry.remove(c, "b"), "the one in hand comes out")
	ok(Carry.held(c) == nil and c.active == 2, "the hand stays on its now empty slot")
	local d = Carry.new()
	Carry.take(d, "x")
	Carry.pocket(d, true)
	ok(d.pocketed, "pocketed")
	Carry.remove(d, "x")
	ok(not d.pocketed, "nothing left pocketed on an empty slot")
end

print(`wear: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
