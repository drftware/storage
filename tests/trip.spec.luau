--!strict
-- lune run tests/trip.spec
-- A lobby car's trip to a server of its own (L-08e1c): the data round-trips; data that isn't ours
-- (wrong version, a group that's empty, too big, holed, repeated or not UserIds) is nobody's word
-- for a group; an unknown difficulty reads as the first; the group's car waits for everyone or
-- `Wait` after the first; only a busy server or a blip is tried again, and only `Tries` times;
-- the screens are black before the send and open mid-ride; six spots in the car, all different.
-- The car they left in (L-08e2) goes along; version 1 and a car that doesn't read come back as
-- the first bay, Open and six.
local Boarding = require("../src/shared/Lobby/Boarding")
local Ride = require("../src/shared/Elevator/Ride")
local Trip = require("../src/shared/Lobby/Trip")

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

-- the data
do
	local group = { 101, 7, 33 }
	local data = Trip.encode(group, "Normal")
	group[1] = 5
	ok(data.group[1] == 101, "the data keeps its own copy of the group")
	local back = Trip.decode(data)
	ok(back ~= nil, "our data reads back")
	if back then
		ok(
			back.group[1] == 101 and back.group[2] == 7 and back.group[3] == 33,
			"the group, in order"
		)
		ok(#back.group == 3, "the whole group and no more")
		ok(back.difficulty == "Normal", "the difficulty")
		ok(back.v == Trip.Version, "the version")
	end
	ok(Trip.decode(nil) == nil, "no data")
	ok(Trip.decode("group") == nil, "not a table")
	ok(
		Trip.decode({ v = Trip.Version + 1, group = { 1 }, difficulty = "Normal" }) == nil,
		"another version"
	)
	ok(Trip.decode({ group = { 1 }, difficulty = "Normal" }) == nil, "no version")
	ok(Trip.decode({ v = Trip.Version, difficulty = "Normal" }) == nil, "no group")
	ok(
		Trip.decode({ v = Trip.Version, group = {}, difficulty = "Normal" }) == nil,
		"an empty group"
	)
	local seven = {}
	for i = 1, Boarding.Capacity + 1 do
		seven[i] = i
	end
	ok(
		Trip.decode({ v = Trip.Version, group = seven, difficulty = "Normal" }) == nil,
		"more than a car holds"
	)
	local six = table.clone(seven)
	six[#six] = nil
	ok(Trip.decode({ v = Trip.Version, group = six, difficulty = "Normal" }) ~= nil, "a full car")
	ok(
		Trip.decode({ v = Trip.Version, group = { 1, 1 }, difficulty = "Normal" }) == nil,
		"someone twice"
	)
	ok(Trip.decode({ v = Trip.Version, group = { 1, 0 }, difficulty = "Normal" }) == nil, "a zero")
	ok(
		Trip.decode({ v = Trip.Version, group = { 1, -4 }, difficulty = "Normal" }) == nil,
		"below zero"
	)
	ok(
		Trip.decode({ v = Trip.Version, group = { 1, 2.5 }, difficulty = "Normal" }) == nil,
		"a fraction"
	)
	ok(
		Trip.decode({ v = Trip.Version, group = { 1, 0 / 0 }, difficulty = "Normal" }) == nil,
		"not a number"
	)
	ok(
		Trip.decode({ v = Trip.Version, group = { 1, "2" }, difficulty = "Normal" }) == nil,
		"a string"
	)
	ok(
		Trip.decode({ v = Trip.Version, group = { 1, math.huge }, difficulty = "Normal" }) == nil,
		"endless"
	)
	ok(
		Trip.decode({ v = Trip.Version, group = { [1] = 1, [3] = 3 }, difficulty = "Normal" })
			== nil,
		"a hole in the group"
	)
	ok(
		Trip.decode({ v = Trip.Version, group = { 1, 2, x = 3 }, difficulty = "Normal" }) == nil,
		"a key besides the group's places"
	)
	local odd = Trip.decode({ v = Trip.Version, group = { 1 }, difficulty = "Nightmare" })
	ok(
		odd ~= nil and odd.difficulty == Boarding.Difficulties[1],
		"an unknown difficulty is the first"
	)
	local none = Trip.decode({ v = Trip.Version, group = { 1 } })
	ok(none ~= nil and none.difficulty == Boarding.Difficulties[1], "no difficulty is the first")
end

-- the car they left in (L-08e2): its bay and the host's choices go along and come back
do
	local car =
		Trip.decode(Trip.encode({ 4, 9 }, "Normal", { bay = 5, friends = true, players = 3 }))
	ok(car ~= nil, "data with a car reads back")
	if car then
		ok(car.bay == 5, "the bay")
		ok(car.friends == true, "Friends only")
		ok(car.players == 3, "the player count")
	end
	local plain = Trip.encode({ 4 }, "Normal")
	ok(
		plain.bay == 1 and plain.friends == false and plain.players == Boarding.Capacity,
		"no car given: the first bay, Open and six"
	)
	local old = Trip.decode({ v = 1, group = { 4, 9 }, difficulty = "Normal" })
	ok(old ~= nil, "version 1 still reads")
	if old then
		ok(old.group[1] == 4 and old.group[2] == 9, "version 1's group")
		ok(
			old.bay == 1 and old.friends == false and old.players == Boarding.Capacity,
			"version 1: the first bay, Open and six"
		)
		ok(old.v == Trip.Version, "read as today's version")
	end
	local function carOf(bay: unknown, friends: unknown, players: unknown): Trip.Data?
		return Trip.decode({
			v = Trip.Version,
			group = { 4 },
			difficulty = "Normal",
			bay = bay,
			friends = friends,
			players = players,
		})
	end
	for _, bad in { { 0, false, 6 }, { 7, false, 6 }, { 2.5, false, 6 }, { "2", false, 6 } } do
		local d = carOf(bad[1], bad[2], bad[3])
		ok(d ~= nil and d.bay == 1, `a bay that doesn't read ({bad[1]}) is the first`)
	end
	for _, bad in { { 3, "yes", 6 }, { 3, false, 0 }, { 3, false, 7 }, { 3, false, 0 / 0 } } do
		local d = carOf(bad[1], bad[2], bad[3])
		ok(
			d ~= nil and d.bay == 1 and d.friends == false and d.players == Boarding.Capacity,
			`choices that don't read ({bad[2]}, {bad[3]}): the first bay, Open and six`
		)
	end
	local edge = carOf(Trip.Bays, false, 1)
	ok(edge ~= nil and edge.bay == Trip.Bays and edge.players == 1, "the last bay, one player")
end

-- the group's car goes once everyone's here, or `Wait` after the first
do
	local group = { 1, 2, 3 }
	ok(not Trip.ready(group, {}, nil, 100), "nobody here: it waits")
	ok(not Trip.ready(group, {}, 100, 1000), "nobody here, however long: it waits")
	ok(not Trip.ready(group, { 1 }, 100, 101), "one of three: it waits")
	ok(
		not Trip.ready(group, { 3, 1 }, 100, 100 + Trip.Wait - 0.01),
		"two of three, just before the wait's up"
	)
	ok(Trip.ready(group, { 3, 1 }, 100, 100 + Trip.Wait), "two of three, the wait's up: it goes")
	ok(Trip.ready(group, { 2, 3, 1 }, 100, 100.5), "everyone, in any order: it goes at once")
	ok(Trip.ready(group, { 2, 3, 1, 9 }, 100, 100.5), "everyone and a stranger: it goes")
	ok(not Trip.ready(group, { 2, 9, 1 }, 100, 100.5), "a stranger doesn't stand in for a friend")
	ok(Trip.ready({ 4 }, { 4 }, 100, 100), "alone: it goes at once")
end

-- trying again
do
	ok(Trip.retry("Failure", 1) == 1, "a blip: again in a second")
	ok(Trip.retry("Flooded", 1) == 3, "a busy server: again in three")
	ok(Trip.retry("Flooded", Trip.Tries - 1) ~= nil, "the last try still goes")
	ok(Trip.retry("Failure", Trip.Tries) == nil, "no more than `Tries`")
	for _, reason in { "Unauthorized", "GameFull", "GameEnded", "GameNotFound", "IsTeleporting" } do
		ok(Trip.retry(reason, 1) == nil, `{reason} isn't tried again`)
	end
	ok(Trip.Tries >= 2, "a failure worth it is tried again at least once")
	ok(Trip.FallbackAfter >= 1, "a lobby falls back only after a trip has failed")
end

-- the timing
do
	ok(Trip.FadeAt >= Ride.Wait, "the car moves before the screens fade")
	ok(math.abs(Trip.Send - (Trip.FadeAt + Trip.Fade)) < 1e-9, "the send waits for black")
	ok(
		Trip.Send < Ride.Wait + Ride.Speedup + Ride.Cruise,
		"they leave before the lobby car would level"
	)
	ok(Trip.Since >= Ride.Wait + Ride.Speedup, "they open at full speed")
	ok(Ride.arrives() - Trip.Since >= 4, "with a few seconds of ride still to feel")
	ok(Trip.GiveUp > Trip.Send, "the give-up is after the send")
	ok(Trip.CoverMost > Trip.Wait + 10, "the cover's limit outlasts the wait for friends")
	ok(#Trip.CoverText > 0 and #Trip.CoverText <= 12, "a few words under the black")
end

-- the spots in the car
do
	local seen: { [string]: boolean } = {}
	for i = 1, Boarding.Capacity do
		local x, z = Trip.spot(i)
		local key = `{x},{z}`
		ok(not seen[key], `spot {i} is its own`)
		seen[key] = true
		ok(math.abs(x) <= 4.5, `spot {i} is inside the car's sides`)
		ok(z >= 3 and z <= 10, `spot {i} is behind the gate, inside the back`)
	end
	local x1, z1 = Trip.spot(1)
	ok(x1 == 0 and z1 == 4, "the host at the front middle")
	local x7, z7 = Trip.spot(Boarding.Capacity + 1)
	ok(x7 == x1 and z7 == z1, "past six it starts again")
end

print(`trip: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
