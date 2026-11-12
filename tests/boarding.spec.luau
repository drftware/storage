--!strict
-- lune run tests/boarding.spec
-- A lobby car's group and count (L-08e1b1): the first step in starts 20 s; the sixth cuts it to
-- 5 unless less is left; it never climbs back up; the last one out stops it; nobody joins or
-- leaves once the gate is shutting; a seventh is turned away; who rides puts the group first and
-- caps the car at six; the first one in hosts and their choices (Friends only, the player count,
-- Go) are theirs alone, within range, only before the gate shuts; the group's value round-trips; the car's readout shows dashes at rest, the
-- count in its middle two cells, green then red from the warning, 0 once it's shutting. Back in
-- your car (L-08e2): the group in its old order with its choices, the count held until they're
-- stood in it, then the full count; anyone aboard meanwhile after them, up to six. A player in
-- no car is pointed to the fullest that will take them, the inviter's first (L-08e3).
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
	local function with(group: { number }): Boarding.Car
		local car = Boarding.new()
		for _, id in group do
			table.insert(car.group, id)
		end
		return car
	end
	local function nobody(_: number): boolean?
		return false
	end
	local r = Boarding.riders(with({ 5, 3, 9 }), { 9, 3, 5 }, nobody)
	ok(#r == 3 and r[1] == 5 and r[2] == 3 and r[3] == 9, "the group, in the order they stepped in")
	local stepped = Boarding.riders(with({ 5, 3 }), { 3 }, nobody)
	ok(#stepped == 1 and stepped[1] == 3, "one who stepped out under the gate stays")
	local dived = Boarding.riders(with({ 5 }), { 8, 5 }, nobody)
	ok(#dived == 2 and dived[1] == 5 and dived[2] == 8, "one who dived in under the gate rides too")
	local crowd = Boarding.riders(with({ 1, 2, 3, 4, 5, 6 }), { 7, 1, 2, 3, 4, 5, 6 }, nobody)
	ok(
		#crowd == Boarding.Capacity and not table.find(crowd, 7),
		"a full group rides; the seventh doesn't"
	)
	ok(#Boarding.riders(with({ 1 }), {}, nobody) == 0, "nobody inside, nobody rides")
	local two = with({ 1, 2 })
	two.players = 2
	local capped = Boarding.riders(two, { 1, 2, 3 }, nobody)
	ok(#capped == 2 and not table.find(capped, 3), "a diver past the host's count stays behind")
	local closed = with({ 1 })
	closed.friends = true
	local pals = Boarding.riders(closed, { 1, 4, 5, 6 }, function(id: number): boolean?
		return if id == 4 then true elseif id == 5 then false else nil
	end)
	ok(
		#pals == 2 and pals[2] == 4,
		"Friends only: a friend who dived in rides; a stranger or one not known yet doesn't"
	)
end

-- the host and their choices
do
	local car = Boarding.new()
	ok(Boarding.host(car) == nil, "an empty car has no host")
	Boarding.join(car, 1, 0)
	Boarding.join(car, 2, 1)
	ok(Boarding.host(car) == 1, "the first one in hosts")
	ok(not Boarding.setFriends(car, 2, true, 2), "only the host chooses")
	ok(Boarding.setFriends(car, 1, true, 2) and car.friends, "the host makes it Friends only")
	ok(not Boarding.setFriends(car, 1, true, 2), "choosing it twice changes nothing")
	ok(Boarding.refusal(car, 3, 3, nil) == "Asking", "Friends only: a stranger waits to be asked")
	ok(Boarding.refusal(car, 3, 3, false) == "Friends", "Friends only: a stranger is turned away")
	ok(not Boarding.join(car, 3, 3, false), "and isn't let in")
	ok(Boarding.join(car, 4, 3, true), "the host's friend steps in")
	ok(Boarding.refusal(car, 4, 3, nil) == "In", "aboard already")
	local low, high = Boarding.playerRange(car)
	ok(low == 3 and high == Boarding.Capacity, "never fewer players than are aboard")
	ok(not Boarding.setPlayers(car, 1, 2, 4), "below those aboard: no")
	ok(not Boarding.setPlayers(car, 1, 7, 4), "past six: no")
	ok(not Boarding.setPlayers(car, 1, 3.5, 4), "half a player: no")
	ok(not Boarding.setPlayers(car, 1, 0 / 0, 4), "not a number: no")
	ok(not Boarding.setPlayers(car, 2, 4, 4), "only the host sets the count")
	ok(Boarding.setPlayers(car, 1, 4, 4) and car.players == 4, "the host takes four")
	ok(car.departs == Boarding.Seconds, "room left: the count runs on")
	ok(Boarding.refusal(car, 5, 5, true) == nil, "a friend may still step in")
	ok(
		Boarding.join(car, 5, 5, true) and car.departs == 5 + Boarding.FullSeconds,
		"the fourth fills it: 5"
	)
	ok(Boarding.refusal(car, 6, 6, true) == "Full", "a full car turns even a friend away")
	ok(
		Boarding.leave(car, 1, 7) and Boarding.host(car) == 2,
		"the host steps out: the next one in hosts"
	)
	ok(car.friends and car.players == 4, "their choices stay with the car")
	ok(not Boarding.setFriends(car, 1, false, 7), "the old host chooses nothing now")
	ok(Boarding.setFriends(car, 2, false, 7) and Boarding.join(car, 9, 7), "Open: anyone steps in")
	for _, id in { 2, 4, 5, 9 } do
		Boarding.leave(car, id, 8)
	end
	ok(
		car.departs == nil and not car.friends and car.players == Boarding.Capacity,
		"the last one out: the next group starts Open and 6"
	)
	-- filling it by the count
	local three = Boarding.new()
	Boarding.join(three, 1, 0)
	Boarding.join(three, 2, 0)
	ok(
		Boarding.setPlayers(three, 1, 2, 1) and three.departs == 1 + Boarding.FullSeconds,
		"down to those aboard: full, 5"
	)
	ok(
		Boarding.setPlayers(three, 1, 6, 2) and three.departs == 1 + Boarding.FullSeconds,
		"back up: the count never climbs"
	)
end

-- Go
do
	local car = Boarding.new()
	ok(not Boarding.go(car, 1, 0), "nobody aboard: no Go")
	Boarding.join(car, 1, 0)
	Boarding.join(car, 2, 0)
	ok(not Boarding.go(car, 2, 3), "only the host goes")
	ok(Boarding.go(car, 1, 3) and car.departs == 3, "Go: the gate starts to shut now")
	ok(Boarding.shutting(car, 3), "and it's shutting")
	ok(not Boarding.go(car, 1, 4), "Go twice: nothing")
	ok(not Boarding.setFriends(car, 1, true, 4), "no choosing once it's shutting")
	local held = Boarding.new()
	Boarding.join(held, 1, 0)
	held.departs = nil -- held while another group climbs
	ok(not Boarding.go(held, 1, 1), "a held count: no Go")
end

-- the choices' values
do
	local car = Boarding.new()
	local friends, players = Boarding.encodeChoices(car)
	ok(friends == nil and players == nil, "Open and 6: no values")
	car.friends, car.players = true, 2
	local f, n = Boarding.choices(Boarding.encodeChoices(car))
	ok(f == true and n == 2, "the choices round-trip")
	local f2, n2 = Boarding.choices("yes", 9)
	ok(f2 == false and n2 == Boarding.Capacity, "broken values: Open and 6")
	local _, n3 = Boarding.choices(nil, 0)
	ok(n3 == Boarding.Capacity, "no zero players")
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

-- back in your car (L-08e2)
do
	local car = Boarding.new()
	local over = Boarding.back(car, { 30, 10, 20 }, true, 4)
	ok(#over == 0, "a group of three fits")
	ok(car.group[1] == 30 and car.group[2] == 10 and car.group[3] == 20, "their old order")
	ok(Boarding.host(car) == 30, "the old host hosts")
	ok(car.friends == true and car.players == 4, "the host's choices as they left")
	ok(car.departs == nil, "the count waits until they're stood in it")
	Boarding.welcome(car, 100)
	ok(car.departs == 100 + Boarding.Seconds, "then the full count")
	Boarding.welcome(car, 105)
	ok(car.departs == 100 + Boarding.Seconds, "welcomed twice: the count runs on")

	local full = Boarding.new()
	Boarding.back(full, { 1, 2 }, false, 2)
	Boarding.welcome(full, 50)
	ok(full.departs == 50 + Boarding.Seconds, "a full car back still gets the full count")
	ok(Boarding.leave(full, 2, 52), "anyone can step out")
	ok(full.departs == 50 + Boarding.Seconds, "the count runs on")
	ok(Boarding.join(full, 2, 53), "and back in")
	ok(full.departs == 53 + Boarding.FullSeconds, "full again: down to five")

	local busy = Boarding.new()
	Boarding.join(busy, 7, 10)
	Boarding.join(busy, 8, 11)
	local o = Boarding.back(busy, { 1, 2, 3, 4, 5 }, false, 6)
	ok(#busy.group == 6, "the car takes six")
	ok(busy.group[1] == 1 and busy.group[5] == 5, "the group back first")
	ok(busy.group[6] == 7, "someone who stepped in meanwhile keeps a place after them")
	ok(#o == 1 and o[1] == 8, "the one who doesn't fit is named")
	ok(busy.departs == nil, "their count waits too")

	local raised = Boarding.new()
	Boarding.back(raised, { 1, 2, 3 }, false, 2)
	ok(raised.players == 3, "the count is raised to as many as came back")
	local odd = Boarding.new()
	Boarding.back(odd, { 1 }, false, 2.5)
	ok(odd.players == Boarding.Capacity, "a broken count is six")
	local twice = Boarding.new()
	Boarding.back(twice, { 4, 4, 5 }, false, 6)
	ok(#twice.group == 2, "nobody twice")
	local none = Boarding.new()
	Boarding.back(none, {}, true, 3)
	ok(#none.group == 0 and none.friends == false, "nobody back: an empty car is Open")
	Boarding.welcome(none, 10)
	ok(none.departs == nil, "an empty car doesn't count")

	local seen: { [string]: boolean } = {}
	for i = 1, Boarding.Capacity do
		local x, z = Boarding.backSpot(i)
		local key = `{x},{z}`
		ok(not seen[key], `back spot {i} is its own`)
		seen[key] = true
		ok(math.abs(x) <= 4.5, `back spot {i} is inside the car's sides`)
		ok(z >= 3 and z <= 9, `back spot {i} is inside the car, clear of the wall`)
	end
	local x1, z1 = Boarding.backSpot(1)
	local x4, z4 = Boarding.backSpot(4)
	ok(x1 == 0 and z4 < z1 and x4 == 0, "the host in front, nearest the wall")
end

-- a player alone is pointed to the fullest car that will take them (L-08e3)
do
	local function car(group: { number }, departs: number?, friends: boolean?, players: number?)
		local c = Boarding.new()
		c.group = group
		c.departs = departs
		c.friends = friends == true
		c.players = players or Boarding.Capacity
		return c
	end
	local function nobody(_host: number): boolean?
		return false
	end
	local function everyone(_host: number): boolean?
		return true
	end
	local function unknown(_host: number): boolean?
		return nil
	end
	local t = 100
	ok(Boarding.fullest({}, 9, t, nobody) == nil, "no cars, no pointer")
	ok(
		Boarding.fullest({ car({}), car({}) }, 9, t, nobody) == nil,
		"empty cars: no pointer (any car will do)"
	)
	ok(
		Boarding.fullest({ car({ 1 }, t + 15), car({ 2, 3 }, t + 15), car({}) }, 9, t, nobody) == 2,
		"the fullest car"
	)
	ok(
		Boarding.fullest({ car({ 1, 2 }, t + 8), car({ 3, 4 }, t + 15) }, 9, t, nobody) == 2,
		"a tie: the one with more time left"
	)
	ok(
		Boarding.fullest({ car({ 1 }, t + 15), car({ 2, 3 }, t + 3) }, 9, t, nobody) == 1,
		"not a car shutting before you'd reach it"
	)
	ok(
		Boarding.fullest({ car({ 1 }, t + 15), car({ 2, 3 }, t - 1) }, 9, t, nobody) == 1,
		"not a car whose gate is shutting"
	)
	ok(
		Boarding.fullest({ car({ 1 }, t + 15), car({ 2, 3 }, t + 15, false, 2) }, 9, t, nobody) == 1,
		"not a full car (the host's count)"
	)
	ok(
		Boarding.fullest({ car({ 1 }, t + 15), car({ 2, 3 }, t + 15, true) }, 9, t, nobody) == 1,
		"not Friends only, for a stranger"
	)
	ok(
		Boarding.fullest({ car({ 1 }, t + 15), car({ 2, 3 }, t + 15, true) }, 9, t, everyone) == 2,
		"Friends only, for the host's friend"
	)
	ok(
		Boarding.fullest({ car({ 1 }, t + 15), car({ 2, 3 }, t + 15, true) }, 9, t, unknown) == 1,
		"Friends only waits while it isn't known"
	)
	ok(
		Boarding.fullest({ car({ 1, 2, 3 }, t + 15), car({ 4 }, t + 15) }, 9, t, nobody, 4) == 2,
		"the inviter's car first"
	)
	ok(
		Boarding.fullest({ car({ 1, 2, 3 }, t + 15), car({ 4 }, t + 15, true) }, 9, t, nobody, 4)
			== 1,
		"not the inviter's car if it won't take you"
	)
	local full = table.create(Boarding.Capacity, 0)
	for i = 1, Boarding.Capacity do
		full[i] = i
	end
	ok(Boarding.fullest({ car(full, t + 15) }, 9, t, nobody) == nil, "not a car of six")
end

print(`boarding: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
