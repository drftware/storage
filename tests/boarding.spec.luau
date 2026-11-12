--!strict
-- lune run tests/boarding.spec
-- A lobby car's group and count (L-08e1b1): the first step in starts 20 s; the sixth cuts it to
-- 5 unless less is left; it never climbs back up; the last one out stops it; nobody joins or
-- leaves once the gate is shutting; a seventh is turned away; who rides puts the group first and
-- caps the car at six; the group's value round-trips; the car's readout shows dashes at rest, the
-- count in its middle two cells, green then red from the warning, 0 once it's shutting.
local Boarding = require("../src/shared/Lobby/Boarding")
local Departure = require("../src/shared/Elevator/Departure")

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

-- the count
do
	local car = Boarding.new()
	ok(car.departs == nil and not Boarding.shutting(car, 0), "an empty car counts nothing")
	ok(Boarding.join(car, 1, 100), "the first steps in")
	ok(car.departs == 100 + Boarding.Seconds, "the first step in starts the count")
	ok(not Boarding.join(car, 1, 101), "stepping in twice is one step in")
	ok(
		Boarding.join(car, 2, 105) and car.departs == 100 + Boarding.Seconds,
		"a friend joins the same count"
	)
	ok(
		Boarding.leave(car, 2, 106) and car.departs == 100 + Boarding.Seconds,
		"one out, the count runs on"
	)
	ok(not Boarding.leave(car, 2, 107), "stepping out twice is one step out")
	ok(Boarding.leave(car, 1, 108) and car.departs == nil, "the last one out stops it")
	ok(#car.group == 0, "and the car is empty")
	ok(
		Boarding.join(car, 3, 200) and car.departs == 200 + Boarding.Seconds,
		"the next one in starts it afresh"
	)
end

-- full: the drop to five, never back up
do
	local car = Boarding.new()
	for id = 1, 5 do
		Boarding.join(car, id, 0)
	end
	ok(car.departs == Boarding.Seconds, "five aboard: the full count")
	ok(Boarding.join(car, 6, 2), "the sixth steps in")
	ok(car.departs == 2 + Boarding.FullSeconds, "full: five seconds from now")
	ok(not Boarding.join(car, 7, 3), "a seventh is turned away")
	ok(#car.group == Boarding.Capacity, "six aboard")
	ok(
		Boarding.leave(car, 6, 4) and car.departs == 2 + Boarding.FullSeconds,
		"one out: it doesn't climb back up"
	)
	ok(Boarding.join(car, 7, 5), "the seventh takes the place")
	ok(car.departs == 2 + Boarding.FullSeconds, "full again with less left: it keeps the less")

	local late = Boarding.new()
	for id = 1, 5 do
		Boarding.join(late, id, 0)
	end
	Boarding.join(late, 6, Boarding.Seconds - 2)
	ok(late.departs == Boarding.Seconds, "full with 2 s left: still 2 s, not 5")
end

-- shutting: the group is what it is
do
	local car = Boarding.new()
	Boarding.join(car, 1, 0)
	local zero = Boarding.Seconds
	ok(not Boarding.shutting(car, zero - 0.01) and Boarding.shutting(car, zero), "zero shuts it")
	ok(Boarding.join(car, 2, zero - 2), "the last one sprints in at 2")
	ok(not Boarding.join(car, 3, zero + 0.1), "no joining once it's shutting")
	ok(not Boarding.leave(car, 1, zero + 0.1), "no leaving once it's shutting")
	ok(#car.group == 2 and car.departs == zero, "the group and the count stand")
end

-- held and started again
do
	local car = Boarding.new()
	Boarding.resume(car, 0)
	ok(car.departs == nil, "an empty car doesn't start")
	Boarding.join(car, 1, 0)
	car.departs = nil -- held
	Boarding.resume(car, 50)
	ok(car.departs == 50 + Boarding.Seconds, "a held count starts again from the full count")
	Boarding.resume(car, 60)
	ok(car.departs == 50 + Boarding.Seconds, "a running count isn't restarted")
	for id = 2, 6 do
		Boarding.join(car, id, 61)
	end
	car.departs = nil
	Boarding.resume(car, 70)
	ok(car.departs == 70 + Boarding.FullSeconds, "a full car starts again at five")
end

-- who rides
do
	local r = Boarding.riders({ 5, 3, 9 }, { 9, 3, 5 })
	ok(#r == 3 and r[1] == 5 and r[2] == 3 and r[3] == 9, "the group, in the order they stepped in")
	local stepped = Boarding.riders({ 5, 3 }, { 3 })
	ok(#stepped == 1 and stepped[1] == 3, "one who stepped out under the gate stays")
	local dived = Boarding.riders({ 5 }, { 8, 5 })
	ok(#dived == 2 and dived[1] == 5 and dived[2] == 8, "one who dived in under the gate rides too")
	local crowd = Boarding.riders({ 1, 2, 3, 4, 5, 6 }, { 7, 1, 2, 3, 4, 5, 6 })
	ok(
		#crowd == Boarding.Capacity and not table.find(crowd, 7),
		"a full group rides; the seventh doesn't"
	)
	ok(#Boarding.riders({ 1 }, {}) == 0, "nobody inside, nobody rides")
end

-- the group's value
do
	ok(Boarding.encode({}) == nil, "an empty group has no value")
	local back = Boarding.decode(Boarding.encode({ 123, 4567890123, 8 }))
	ok(
		#back == 3 and back[1] == 123 and back[2] == 4567890123 and back[3] == 8,
		"a group round-trips"
	)
	ok(#Boarding.decode(nil) == 0 and #Boarding.decode(7) == 0, "no value, or a broken one: empty")
end

-- the car's readout
do
	local function shows(left: number?): (string, { string })
		local text, tones = "", {}
		for i = 1, 4 do
			local char, tone = Boarding.readout(left, i)
			text ..= char
			tones[i] = tone
		end
		return text, tones
	end
	local rest, restTones = shows(nil)
	ok(rest == "----" and restTones[1] == "Rest" and restTones[4] == "Rest", "at rest: dim dashes")
	local full, fullTones = shows(Boarding.Seconds)
	ok(full == " 20 " and fullTones[2] == "Right" and fullTones[3] == "Right", "20, green")
	ok(fullTones[1] == "Off" and fullTones[4] == "Off", "the outer cells dark")
	local one, oneTones = shows(Departure.Warning - 0.5)
	ok(one == " 10 " and oneTones[2] == "Lit", "in the warning: red")
	local five, fiveTones = shows(4.2)
	ok(
		five == "  5 " and fiveTones[2] == "Off" and fiveTones[3] == "Lit",
		"a lone digit, its blank cell dark"
	)
	local zero = shows(-0.8)
	ok(zero == "  0 ", "shutting: 0")
end

print(`boarding: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
