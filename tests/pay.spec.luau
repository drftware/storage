--!strict
-- lune run tests/pay.spec
-- Pay and keeping at the gate (S1-06, GDD "When the gate shuts"): every floor pays the same to
-- each player aboard, a little more each floor; a wrapped player is paid nothing; a floor pays a
-- player once a climb, so a ride that comes back never pays twice. The coins drawn flying add up
-- to the pay, never more than the most drawn, the biggest last. Keeping takes the finds out of
-- the slots and leaves the tools; your hand stays on its slot. The kept finds land in the save:
-- one more of each, the book stamped only the first time, and the save still writes.
local Brix = require("../vendor/brix/src")
local Carry = require("../src/shared/Tools/Carry")
local Pay = require("../src/shared/Pay")
local Save = require("../src/shared/Save")

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

-- The pay climbs with the floor, a little each time.
do
	ok(Pay.forFloor(1) == Pay.Base, "floor 1 pays the base")
	ok(Pay.forFloor(2) == Pay.Base + Pay.Rise, "floor 2 pays a little more")
	local last = 0
	local rising = true
	for floor = 1, 100 do
		local coins = Pay.forFloor(floor)
		if coins <= last or coins - last > Pay.Rise and floor > 1 then
			rising = false
		end
		last = coins
	end
	ok(rising, "each floor pays more than the one below, by no more than the rise")
	ok(Pay.forFloor(0) == Pay.Base and Pay.forFloor(-3) == Pay.Base, "no floor pays below floor 1")
	ok(Pay.forFloor(2.7) == Pay.forFloor(2), "a floor is a whole number")
	ok(Pay.Base >= 1 and Pay.Rise >= 1, "every gate pays something, and more higher up")
end

-- Each player aboard is paid once a floor; wrapped, nothing.
do
	local amy: { [number]: boolean } = {}
	local ben: { [number]: boolean } = {}
	ok(Pay.owed(amy, 3, false) == Pay.forFloor(3), "aboard on floor 3: paid floor 3's coins")
	ok(Pay.owed(ben, 3, false) == Pay.owed({}, 3, false), "everyone aboard is paid the same")
	ok(Pay.owed(amy, 3, false) == 0, "a ride that comes back to floor 3 pays nothing again")
	ok(Pay.owed(amy, 4, false) == Pay.forFloor(4), "the next floor pays again")
	local cara: { [number]: boolean } = {}
	ok(Pay.owed(cara, 3, true) == 0, "wrapped as the gate shuts: paid nothing")
	ok(cara[3] == nil, "being wrapped doesn't use up the floor")
	ok(Pay.owed(cara, 3, false) == Pay.forFloor(3), "cut free and aboard when it comes back: paid")
end

-- Each monster shut in a unit as the gate shuts pays everyone aboard a little more (S4-04): one,
-- three, none; never while wrapped, never twice for a floor. The screen splits what came in back
-- into the floor's pour and one pop per monster.
do
	ok(Pay.owed({}, 1, false, 0) == Pay.forFloor(1), "nothing shut in: the floor's pay alone")
	ok(Pay.owed({}, 1, false) == Pay.forFloor(1), "no count given: nothing shut in")
	ok(Pay.owed({}, 1, false, 1) == Pay.forFloor(1) + Pay.Trap, "one shut in: its coins on top")
	ok(
		Pay.owed({}, 4, false, 3) == Pay.forFloor(4) + 3 * Pay.Trap,
		"three shut in: three times over"
	)
	ok(Pay.owed({}, 4, true, 3) == 0, "wrapped as the gate shuts: nothing, traps or not")
	local back: { [number]: boolean } = {}
	Pay.owed(back, 2, false, 1)
	ok(Pay.owed(back, 2, false, 2) == 0, "a ride back to the floor pays its traps no more")
	ok(Pay.owed({}, 1, false, -2) == Pay.forFloor(1), "a count never goes below none")
	ok(Pay.owed({}, 1, false, 1.7) == Pay.forFloor(1) + Pay.Trap, "a count is a whole number")
	ok(Pay.Trap >= 1, "a monster shut in always pays something")
	local floorPart, pops = Pay.parts(Pay.owed({}, 3, false, 2), 2)
	ok(floorPart == Pay.forFloor(3) and pops == 2, "the floor's pour, then two pops")
	local f0, p0 = Pay.parts(10, 0)
	ok(f0 == 10 and p0 == 0, "nothing shut in: the pour alone")
	local f1, p1 = Pay.parts(7, 3)
	ok(p1 == 1 and f1 + p1 * Pay.Trap == 7, "more pops than the coins hold: only what fits")
	local f2, p2 = Pay.parts(10, -1)
	ok(f2 == 10 and p2 == 0, "a count below none pops nothing")
	local f3, p3 = Pay.parts(10, 0 / 0)
	ok(f3 == 10 and p3 == 0, "a count that isn't a number pops nothing")
end

-- The version the team picked pays its coins as their own pop, after the pour and the traps'
-- (S4-03c2).
do
	local owed = Pay.owed({}, 2, false, 1, 6)
	local f, p, v = Pay.parts(owed, 1, 6)
	ok(
		f == Pay.forFloor(2) and p == 1 and v == 6,
		"the floor's pour, one trap's pop, then the version's six"
	)
	local f0, p0, v0 = Pay.parts(12, 0)
	ok(f0 == 12 and p0 == 0 and v0 == 0, "no version picked: no version pop")
	local f1, _, v1 = Pay.parts(12, 0, 0)
	ok(f1 == 12 and v1 == 0, "a version that pays nothing: no pop")
	local f2, p2, v2 = Pay.parts(8, 1, 20)
	ok(
		v2 == 8 and p2 == 0 and f2 == 0,
		"more than the pay holds: only what fits, the version first"
	)
	local f3, p3, v3 = Pay.parts(20, 2, 6)
	ok(v3 == 6 and p3 == 2 and f3 == 4, "the version's coins come out before the traps'")
	local f4, _, v4 = Pay.parts(12, 0, 0 / 0)
	ok(f4 == 12 and v4 == 0, "a version's coins that aren't a number pop nothing")
	local f5, _, v5 = Pay.parts(12, 0, 2.7)
	ok(f5 == 10 and v5 == 2, "a version's coins are whole")
end

-- The coins drawn flying add up to the pay.
do
	local all = true
	for total = 0, 120 do
		for most = 1, 16 do
			local shares = Pay.split(total, most)
			local sum, low, high, sorted = 0, math.huge, 0, true
			for i, s in shares do
				sum += s
				low = math.min(low, s)
				high = math.max(high, s)
				if i > 1 and s < shares[i - 1] then
					sorted = false
				end
			end
			if
				sum ~= total
				or #shares ~= math.min(total, most)
				or (#shares > 0 and (low < 1 or high - low > 1))
				or not sorted
			then
				all = false
			end
		end
	end
	ok(all, "the flying coins add up to the pay, at most the most drawn, even, the biggest last")
	ok(#Pay.split(10, Pay.Flyers) == 10, "floor 1's pay: one coin flies for each")
	ok(#Pay.split(Pay.forFloor(20), Pay.Flyers) == Pay.Flyers, "a big pay: no more coins drawn")
	ok(#Pay.split(0, Pay.Flyers) == 0, "nothing paid: nothing flies")
end

-- Keeping: the finds leave the slots, the tools stay.
do
	local isFind = function(id: string): boolean
		return string.sub(id, 1, 4) == "find"
	end
	local c = Carry.new()
	Carry.take(c, "tool:cutters")
	Carry.take(c, "find:boombox")
	Carry.take(c, "find:teddy")
	ok(Carry.held(c) == "find:teddy", "the last take is in your hand")
	local kept = Carry.keep(c, isFind)
	ok(
		#kept == 2 and kept[1] == "find:boombox" and kept[2] == "find:teddy",
		"both finds kept, slot order"
	)
	ok(c.slots[1] == "tool:cutters" and c.slots[2] == nil and c.slots[3] == nil, "the tool stays")
	ok(c.active == 3 and Carry.held(c) == nil, "your hand stays on its slot, now empty")
	ok(Carry.room(c) == 3, "the slots are free for the next floor")
	ok(#Carry.keep(c, isFind) == 0, "nothing more to keep")

	local p = Carry.new()
	Carry.take(p, "find:tv")
	Carry.pocket(p, true)
	Carry.keep(p, isFind)
	ok(p.pocketed == false, "a pocketed find kept: nothing left pocketed")

	local t = Carry.new()
	Carry.take(t, "tool:horn")
	Carry.pocket(t, true)
	Carry.keep(t, isFind)
	ok(t.pocketed and t.slots[1] == "tool:horn", "a pocketed tool stays pocketed")
end

-- The kept finds land in the save.
do
	local format = Save.format(Brix)
	local data = Save.fresh()
	local fresh = Save.keep(data, { "Boombox", "Teddy" }, 1794700000)
	ok(data.finds.Boombox == 1 and data.finds.Teddy == 1, "one of each kept")
	ok(#fresh == 2 and fresh[1] == "Boombox" and fresh[2] == "Teddy", "both stamped new")
	ok(data.stamps.finds.Boombox == 1794700000, "the book stamped when it was first kept")
	local again = Save.keep(data, { "Boombox", "Boombox", "Skates" }, 1794709999.6)
	ok(data.finds.Boombox == 3, "a second and third boombox count up")
	ok(#again == 1 and again[1] == "Skates", "only the new kind is stamped new")
	ok(data.stamps.finds.Boombox == 1794700000, "the first stamp stands")
	ok(data.stamps.finds.Skates == 1794709999, "a stamp is a whole second")
	ok(#Save.keep(data, {}, 1794710000) == 0, "keeping nothing changes nothing")
	local stored, problem = format:encode(data)
	ok(stored ~= nil and problem == nil, `the save with kept finds still writes ({problem})`)
	local back = format:decode(format:latest(), stored)
	ok(back ~= nil and back.finds.Boombox == 3 and back.finds.Skates == 1, "and reads back")
end

print(`pay.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
