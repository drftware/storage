--!strict
-- lune run tests/trip.spec
-- A lobby car's trip to a server of its own (L-08e1c): the data round-trips; data that isn't ours
-- (wrong version, a group that's empty, too big, holed, repeated or not UserIds) is nobody's word
-- for a group; an unknown difficulty reads as the first; the group's car waits for everyone or
-- `Wait` after the first; only a busy server or a blip is tried again, and only `Tries` times;
-- the screens are black before the send and open mid-ride; six spots in the car, all different.
-- The car they left in (L-08e2) goes along; version 1 and a car that doesn't read come back as
-- the first bay, Open and six. Share and follow (L-08e3b): the group's server and lobby go along;
-- an invite sends a friend on only while it's fresh and names a real server; word of a floor
-- reads back only if it names a server and a whole floor.
local Boarding = require("../src/shared/Lobby/Boarding")
local Ride = require("../src/shared/Elevator/Ride")
local Taken = require("../src/shared/Home/Taken")
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
	ok(Trip.FadeAt >= Ride.cruising(), "the car is seen at full speed before the black")
	ok(Trip.LoadMost >= Trip.Wait, "a loading screen is waited for at least as long as a body")
	ok(Trip.LoadMost + 5 < Trip.CoverMost, "the cover never lifts on its own before the ride")
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

-- share and follow (L-08e3b): the group's server and lobby go along and read back; an old
-- lobby's data still reads, naming none; anything that isn't a GUID names none
do
	local server = "0A1B2C3D-4E5F-6789-ABCD-EF0123456789"
	local lobby = "8f14e45f-ceea-467e-a2b1-0123456789ab"
	ok(Trip.isServer(server) and Trip.isServer(lobby), "a GUID, either case, is a server")
	ok(not Trip.isServer(""), "nothing isn't a server")
	ok(not Trip.isServer("{" .. server .. "}"), "a GUID in braces isn't one")
	ok(not Trip.isServer(server .. "0"), "too long isn't one")
	ok(not Trip.isServer(string.gsub(server, "%-", "")), "no dashes isn't one")
	ok(not Trip.isServer("0A1B2C3D-4E5F-6789-ABCD-EF012345678G"), "a non-hex digit isn't one")
	ok(not Trip.isServer(12), "a number isn't one")

	local car = { bay = 4, friends = true, players = 3 }
	local back =
		Trip.decode(Trip.encode({ 9, 8 }, "Normal", car, { server = server, lobby = lobby }))
	ok(back ~= nil, "data naming the server and lobby reads back")
	if back then
		ok(back.server == server, "the group's server")
		ok(back.lobby == lobby, "the lobby they left")
		ok(back.by == 0, "nobody invited a group")
		ok(back.bay == 4 and back.players == 3, "the car still")
	end
	local none = Trip.encode({ 9 }, "Normal")
	ok(none.server == "" and none.lobby == "" and none.by == 0, "no route names nothing")
	local bad = Trip.decode({
		v = Trip.Version,
		group = { 9 },
		difficulty = "Normal",
		server = "my server",
		lobby = 5,
		by = -1,
	})
	ok(
		bad ~= nil and bad.server == "" and bad.lobby == "" and bad.by == 0,
		"a server, lobby or inviter that doesn't read names nobody, and the group still goes"
	)
	local old = Trip.decode({
		v = 2,
		group = { 9, 8 },
		difficulty = "Normal",
		bay = 2,
		friends = false,
		players = 6,
		server = server,
	})
	ok(old ~= nil, "an old lobby's data still reads")
	if old then
		ok(old.server == "" and old.lobby == "", "an old lobby's data names no server")
		ok(old.bay == 2, "and keeps its car")
	end

	-- a friend sent on alone: who invited them goes along; nobody invites themselves
	local follow =
		Trip.decode(Trip.encode({ 77 }, "Normal", nil, { server = server, lobby = "", by = 9 }))
	ok(follow ~= nil and follow.by == 9, "a friend sent on keeps who invited them")
	ok(follow ~= nil and follow.server == server, "and the server they were sent to")
	local selfish =
		Trip.decode({ v = Trip.Version, group = { 77 }, difficulty = "Normal", by = 77 })
	ok(selfish ~= nil and selfish.by == 0, "inviting yourself names nobody")
end

-- the invite's launch data
do
	local server = "0A1B2C3D-4E5F-6789-ABCD-EF0123456789"
	local t = 1_800_000_000
	local from = Trip.invite(9, server, t + 0.7)
	ok(from.by == 9 and from.to == server and from.at == t, "an invite from a group's server")
	local lobby = Trip.invite(9, nil, t)
	ok(
		lobby.by == 9 and lobby.to == nil and lobby.at == nil,
		"an invite from a lobby names no server"
	)
	ok(Trip.invite(9, "nope", t).to == nil, "a server that isn't one isn't carried")

	-- what JSON gives back is a plain table
	local read = Trip.readInvite({ by = 9, to = server, at = t }, 77, t + 30)
	ok(read ~= nil and read.by == 9 and read.to == server, "a fresh invite sends the friend on")
	local stale = Trip.readInvite({ by = 9, to = server, at = t }, 77, t + Trip.FollowFor + 1)
	ok(stale ~= nil and stale.by == 9 and stale.to == nil, "a stale one only points them")
	local early = Trip.readInvite({ by = 9, to = server, at = t + 600 }, 77, t)
	ok(early ~= nil and early.to == nil, "one from the future only points them")
	local undated = Trip.readInvite({ by = 9, to = server }, 77, t)
	ok(undated ~= nil and undated.to == nil, "one with no time only points them")
	local nan = Trip.readInvite({ by = 9, to = server, at = 0 / 0 }, 77, t)
	ok(nan ~= nil and nan.to == nil, "a time that isn't a number only points them")
	ok(Trip.readInvite({ by = 77 }, 77, t) == nil, "your own invite is nothing")
	ok(Trip.readInvite({ by = 1.5 }, 77, t) == nil, "a sender that isn't a UserId is nothing")
	ok(Trip.readInvite({ to = server, at = t }, 77, t) == nil, "no sender is nothing")
	ok(Trip.readInvite("by=9", 77, t) == nil, "not a table is nothing")
	local forged = Trip.readInvite({ by = 9, to = "../x", at = t }, 77, t)
	ok(forged ~= nil and forged.to == nil, "a forged server only points them")

	-- Roblox's limit on launch data is 200 characters; the longest we send, spelled out as JSON
	local json = `\{"by":{2 ^ 53 - 1},"to":"{server}","at":{t}\}`
	ok(#json <= 200, "the longest invite fits Roblox's launch data")
	ok(Trip.followText("Sam") == "Joining Sam", "you're told whose group you're joining")
	ok(Trip.followText("") == Trip.CoverText, "or just that you're going up")
	ok(Trip.FailedHold > 0.5 and Trip.FailedHold < 3, "a failure is readable, then gone")
end

-- word of the floor
do
	local server = "0A1B2C3D-4E5F-6789-ABCD-EF0123456789"
	local lobby = "8f14e45f-ceea-467e-a2b1-0123456789ab"
	local topic = Trip.topic(lobby)
	ok(#topic >= 1 and #topic <= 80, "a lobby's topic fits MessagingService's 80 characters")
	ok(Trip.topic(lobby) ~= Trip.topic(server), "each lobby hears its own")
	local w = Trip.readWord(Trip.word(server, 7))
	ok(w ~= nil and w.server == server and w.floor == 7, "a floor reads back")
	local over = Trip.readWord(Trip.word(server, 0))
	ok(over ~= nil and over.floor == 0, "the climb's end reads back")
	ok(Trip.readWord({ server = server, floor = -1 }) == nil, "no floor below nothing")
	ok(Trip.readWord({ server = server, floor = 2.5 }) == nil, "no half floors")
	ok(Trip.readWord({ server = server, floor = 0 / 0 }) == nil, "no floor that isn't a number")
	ok(
		Trip.readWord({ server = server, floor = Trip.MostFloor + 1 }) == nil,
		"no floor past any real one"
	)
	ok(Trip.readWord({ server = "x", floor = 3 }) == nil, "no word from a server that isn't one")
	ok(Trip.readWord(nil) == nil, "no word from nothing")
	ok(Trip.WordStale > Trip.WordEvery * 2, "a lobby forgets only after two words are missed")
end

-- a new character on a group's own server stood at the car (S3-05a): a respawn or a late arrival
-- still on the front office's spawn is; a friend left behind, being carried up to wake wrapped
-- in a unit (or already held in one), never is, wherever their body stands meanwhile
do
	ok(Trip.standsLate(true, false, false), "a respawn on the spawn is stood at the car")
	ok(not Trip.standsLate(false, false, false), "a body stood elsewhere by the climb stays put")
	ok(
		not Trip.standsLate(true, true, false),
		"a friend being carried up is never stood at the car"
	)
	ok(not Trip.standsLate(true, false, true), "a friend held in a unit is never stood at the car")
	ok(not Trip.standsLate(false, true, true), "nor once they're in their unit")
end

-- taken-up finds across the trip (S5-03d4, D-358): each rider's finds out of a job box go in the
-- data, checked as they arrive; a bad entry is dropped on its own, never the whole group
do
	local group = { 101, 7 }
	local ups: { Taken.Up } = {
		{ owner = 101, name = "Boombox", holder = 101, cracked = false, worn = false },
		{ owner = 101, name = "Teddy:Gold", holder = 7, cracked = true, worn = false },
		{ owner = 7, name = "HardHat", holder = 7, cracked = false, worn = true },
	}
	local data = Trip.encode(group, "Normal", nil, nil, ups)
	ups[1].name = "Lamp"
	ok(data.finds[1].name == "Boombox", "the data keeps its own copy of the finds")
	local back = Trip.decode(data)
	ok(back ~= nil and #back.finds == 3, "every taken-up find reads back")
	if back then
		local a, b, c = back.finds[1], back.finds[2], back.finds[3]
		ok(a.owner == 101 and a.name == "Boombox" and a.holder == 101, "whose, what, who holds it")
		ok(b.name == "Teddy:Gold" and b.holder == 7 and b.cracked, "a friend holds a cracked Gold")
		ok(c.worn and not c.cracked, "one worn on the head")
	end
	ok(#Trip.encode(group, "Normal").finds == 0, "no finds: none carried")

	local raw = {
		v = Trip.Version,
		group = { 101, 7 },
		difficulty = "Normal",
		finds = {
			{ owner = 101, name = "Lamp", holder = 101, cracked = false, worn = false },
			{ owner = 55, name = "Lamp", holder = 101, cracked = false, worn = false },
			{ owner = 101, name = "Lamp", holder = 55, cracked = false, worn = false },
			{ owner = 101, name = "", holder = 101, cracked = false, worn = false },
			{ owner = 101, name = 4, holder = 101, cracked = false, worn = false },
			{
				owner = 101,
				name = string.rep("x", Trip.NameMost + 1),
				holder = 101,
				cracked = false,
				worn = false,
			},
			{ owner = 101, name = "Lamp", holder = 101, cracked = "yes", worn = false },
			{ owner = 101, name = "Lamp", holder = 101, cracked = false },
			"Lamp",
			{ owner = 7, name = "Skates", holder = 101, cracked = true, worn = false },
		},
	}
	local read = Trip.decode(raw)
	ok(read ~= nil, "a group with bad finds still reads")
	if read then
		ok(#read.finds == 2, "only the two good finds are kept")
		ok(read.finds[1].name == "Lamp" and read.finds[2].name == "Skates", "in order")
	end
	raw.finds = "Lamp" :: any
	local notList = Trip.decode(raw)
	ok(notList ~= nil and #notList.finds == 0, "finds that aren't a list: none")
	local many = {}
	for i = 1, Trip.UpsMost + 5 do
		many[i] = { owner = 101, name = `Find{i}`, holder = 101, cracked = false, worn = false }
	end
	raw.finds = many
	local capped = Trip.decode(raw)
	ok(capped ~= nil and #capped.finds == Trip.UpsMost, "never more than the most a group carries")
	local old = Trip.decode({
		v = 3,
		group = { 101 },
		difficulty = "Normal",
		server = "",
		lobby = "",
		by = 0,
		finds = { { owner = 101, name = "Lamp", holder = 101, cracked = false, worn = false } },
	})
	ok(old ~= nil and #old.finds == 0, "version 3 carried no finds")
end

print(`trip: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
