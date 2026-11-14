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
