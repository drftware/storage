--!strict
-- lune run tests/climbend.spec
-- The climb ends (L-08d): it's over only when nobody is still climbing; every screen is covered
-- before the server clears the climb; a wipe's black is whole before the caught friend's eyes
-- would open; an escape's ride plays out untouched until the cable's second knock and is cleared
-- before the car could open on the floor again; the screen's parts come in order and settle; the
-- next climb starts when everyone's in or the wait runs out; friends stand apart in its lobby; the
-- values the server writes read back, the results on a car's back wall too (L-08e2).
local Caught = require("../src/shared/Caught")
local Climb = require("../src/shared/Climb")
local ClimbEnd = require("../src/shared/ClimbEnd")
local Ride = require("../src/shared/Elevator/Ride")

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
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end

-- who's still climbing
ok(not ClimbEnd.over({}), "nobody in the game: nothing to end")
ok(ClimbEnd.over({ "Kept" }), "the only friend kept: it's over")
ok(ClimbEnd.over({ "Kept", "Left", "Kept" }), "everyone kept or left: it's over")
ok(not ClimbEnd.over({ "Kept", "Climbing" }), "one friend still climbing: not over")
ok(not ClimbEnd.over({ "Left" }, 1), "a stand-in friend still climbing (Studio): not over")
ok(ClimbEnd.over({ "Left" }, 0), "no stand-ins: over")

-- one player at each look, under S3-01's rules: nobody is out of the climb (S3-01b)
do
	-- plays out a run of looks for one player: each is { floor, kept, out, carriedTo }
	type Look = { floor: number, kept: boolean, out: boolean, carried: number? }
	local function run(looks: { Look }): (ClimbEnd.State, ClimbEnd.Lost?)
		local state: ClimbEnd.State, was: ClimbEnd.Lost? = "Climbing", nil
		for _, l in looks do
			state, was = ClimbEnd.look(was, l.floor, l.kept, l.out, l.carried)
		end
		return state, was
	end
	local function lost(l: ClimbEnd.Lost?, fate: ClimbEnd.Fate, floor: number): boolean
		return l ~= nil and l.fate == fate and l.floor == floor
	end

	local state, l = run({ { floor = 2, kept = false, out = false } })
	ok(state == "Climbing" and l == nil, "climbing: nothing noted")

	state, l = run({ { floor = 2, kept = true, out = false } })
	ok(state == "Kept" and lost(l, "Kept", 2), "kept on floor 2")

	-- kept on 2, then left behind as the car goes: still floor 2, and the ride goes on to 3
	state, l = run({
		{ floor = 2, kept = true, out = false },
		{ floor = 2, kept = false, out = true },
		{ floor = 3, kept = false, out = true },
	})
	ok(
		state == "Left" and lost(l, "Left", 2),
		"watching the ride: left on the floor you were lost on"
	)

	-- the car arrives on 3: carried up, they count as kept there before the unit streams in
	local wrapped = {
		{ floor = 2, kept = false, out = true },
		{ floor = 3, kept = false, out = true, carried = 3 },
		{ floor = 3, kept = false, out = false, carried = 3 }, -- out of the watch, no unit yet
	}
	state, l = run(wrapped)
	ok(state == "Kept" and lost(l, "Kept", 3), "between the black and the unit: kept, on floor 3")
	ok(state ~= "Climbing", "a carried friend never counts as climbing, so a wipe can land")

	-- stood in the unit: the kept mark, and the carry's over; floor 3 stays
	table.insert(wrapped, { floor = 3, kept = true, out = false })
	state, l = run(wrapped)
	ok(state == "Kept" and lost(l, "Kept", 3), "kept on the floor they were carried to")

	-- left behind again on 3 and carried to 4: the photo follows them up
	table.insert(wrapped, { floor = 3, kept = false, out = true })
	table.insert(wrapped, { floor = 4, kept = false, out = true, carried = 4 })
	table.insert(wrapped, { floor = 4, kept = true, out = false })
	state, l = run(wrapped)
	ok(lost(l, "Kept", 4), "carried twice: kept on floor 4")

	-- no unit free on the new floor: stood in its lobby, climbing again
	state, l = run({
		{ floor = 3, kept = false, out = true, carried = 3 },
		{ floor = 3, kept = false, out = false },
	})
	ok(state == "Climbing" and l == nil, "no unit for them: back in the lobby, climbing")

	-- cut free on 3, then caught on 4: floor 4
	state, l = run({
		{ floor = 3, kept = true, out = false },
		{ floor = 3, kept = false, out = false },
		{ floor = 4, kept = true, out = false },
	})
	ok(lost(l, "Kept", 4), "cut free, then caught again: the floor of the second catch")

	-- the moment: the last free friend is caught on 3 while a friend is still in the carry's black
	local carriedFriend = ClimbEnd.look({ fate = "Left", floor = 2 }, 3, false, false, 3)
	local lastFree = ClimbEnd.look(nil, 3, true, false, nil)
	ok(
		ClimbEnd.over({ carriedFriend, lastFree }),
		"the last free friend caught: a wipe, carry or not"
	)
	local stillFree = ClimbEnd.look(nil, 3, false, false, nil)
	ok(not ClimbEnd.over({ carriedFriend, stillFree }), "a friend still free on 3: not over")
	ok(not ClimbEnd.over({ carriedFriend }, 1), "a stand-in still free (Studio): not over")

	-- playing alone: one catch ends it
	ok(ClimbEnd.over({ (ClimbEnd.look(nil, 1, true, false, nil)) }), "alone: one catch ends it")
end

-- a wipe
local k = ClimbEnd.Kept
ok(ClimbEnd.black("Kept", 0) == 0, "the black starts clear, over the catch")
ok(ClimbEnd.black("Kept", k.Cover) >= 0.999, "every screen is black before the climb is cleared")
ok(ClimbEnd.cover("Kept") == k.Cover, "the server clears it at the wipe's cover")
ok(
	k.BlackIn <= Caught.Hold,
	"the black is whole before the caught friend's eyes would open in the unit"
)
ok(ClimbEnd.AfterCatch == Caught.Dark, "a wipe ends on the catch's cut to black")
ok(
	k.Cover < k.Slams[1] and k.Slams[1] < k.Slams[2] and k.Slams[2] < k.TitleAt,
	"a beat of quiet, the doors far off, then the title"
)
ok(k.Slams[1] - k.Cover >= 0.8, "the silence is long enough to feel")
ok(
	k.TitleAt < k.PhotosAt and k.PhotosAt < k.StatsAt and k.StatsAt < k.AgainAt,
	"the title, the photos, the stats, then the button"
)
local last = 0
for i = 0, 800 do
	local t = i * 0.01
	local b = ClimbEnd.black("Kept", t)
	ok(b >= last - 1e-9 and b >= 0 and b <= 1, `a wipe's black only deepens ({t})`)
	ok(ClimbEnd.white("Kept", t) == 0, `no white in a wipe ({t})`)
	last = b
end

-- an escape
local top = ClimbEnd.Top
ok(top.WhiteAt == Climb.HandOff, "the light floods in on the cable's second knock")
for i = 0, math.floor(Climb.HandOff * 100) - 1 do
	local t = i * 0.01
	ok(
		ClimbEnd.white("Top", t) == 0 and ClimbEnd.black("Top", t) == 0,
		`the ride plays out untouched until the knock ({t})`
	)
end
ok(ClimbEnd.white("Top", top.WhiteAt + top.WhiteIn) >= 0.999, "the white is whole")
ok(top.WhiteAt + top.WhiteIn <= top.Cover, "the white is whole before the climb is cleared")
ok(ClimbEnd.cover("Top") == top.Cover, "the server clears it at the escape's cover")
ok(
	top.Cover < Ride.opens(),
	"the climb is cleared before the car could open on the top floor again"
)
ok(
	top.BellAt > top.Cover and top.BellAt < top.TitleAt,
	"the bell rings in the white, before the title"
)
for i = 0, 600 do
	local t = top.Cover + i * 0.01
	local covered = math.max(ClimbEnd.white("Top", t), ClimbEnd.black("Top", t))
	ok(covered >= 0.999, `the screen stays covered once it's cleared ({t})`)
end
ok(ClimbEnd.white("Top", top.SettleAt + top.SettleIn) <= 1e-6, "the white settles away whole")
ok(
	top.TitleAt < top.PhotosAt and top.PhotosAt < top.StatsAt and top.StatsAt < top.AgainAt,
	"the title, the photos, the stats, then the button (escape)"
)

-- the title lands and settles
for _, how: ClimbEnd.How in { "Kept", "Top" } do
	local tl = ClimbEnd.timeline(how)
	local shown = ClimbEnd.title(how, tl.TitleAt - 0.01)
	ok(shown == 0, `{how}: no title before its moment`)
	local s, size = ClimbEnd.title(how, tl.TitleAt + 2)
	ok(near(s, 1) and near(size, 1), `{how}: the title is up and settled`)
	local p, drop = ClimbEnd.photo(how, 1, tl.PhotosAt - 0.01)
	ok(p == 0 and drop > 0, `{how}: the first photo waits above its spot`)
	p, drop = ClimbEnd.photo(how, 3, tl.PhotosAt + 3)
	ok(near(p, 1) and near(drop, 0), `{how}: a photo lands and settles`)
	ok(
		ClimbEnd.photoAt(how, 2) > ClimbEnd.photoAt(how, 1),
		`{how}: the photos land one after another`
	)
	local up, below = ClimbEnd.again(how, tl.AgainAt - 0.01)
	ok(up == 0, `{how}: no button before its moment`)
	up, below = ClimbEnd.again(how, tl.AgainAt + 2)
	ok(near(up, 1) and near(below, 0), `{how}: the button is up and still`)
	ok(ClimbEnd.againAt(how) >= ClimbEnd.cover(how), `{how}: no button before the climb is cleared`)
	ok(
		ClimbEnd.stats(how, tl.StatsAt - 0.01) == 0 and near(ClimbEnd.stats(how, tl.StatsAt + 2), 1),
		`{how}: the stats come in`
	)
end
local _, slam = ClimbEnd.title("Kept", k.TitleAt)
ok(slam > 1, "Kept slams down from bigger")
local _, rise = ClimbEnd.title("Top", top.TitleAt)
ok(rise < 1, "Made it rises from smaller")
ok(ClimbEnd.jolt("Kept", k.TitleAt) == 0, "no jolt before the title lands")
ok(
	math.abs(ClimbEnd.jolt("Kept", k.TitleAt + ClimbEnd.Land + 0.001)) > 1,
	"the screen jolts as it lands"
)
ok(
	ClimbEnd.jolt("Kept", k.TitleAt + ClimbEnd.Land + ClimbEnd.JoltOut + 0.01) == 0,
	"the jolt dies away"
)
ok(ClimbEnd.jolt("Top", top.TitleAt + 0.3) == 0, "no jolt in an escape")

-- the lift onto the next climb
ok(ClimbEnd.lift(0) == 1 and ClimbEnd.lift(ClimbEnd.LiftIn) == 0, "the black lifts whole")
ok(ClimbEnd.floorShown(0) == 0, "the floor's number fades in")
ok(ClimbEnd.floorShown(ClimbEnd.FloorHold * 0.6) > 0.95, "the floor's number holds")
ok(ClimbEnd.floorShown(ClimbEnd.FloorHold + 0.7) == 0, "the floor's number goes")

-- the time
ok(ClimbEnd.clock(0) == "0:00", "no time")
ok(ClimbEnd.clock(402.9) == "6:42", "minutes and seconds")
ok(ClimbEnd.clock(3729) == "1:02:09", "past an hour")
ok(ClimbEnd.clock(-3) == "0:00", "never below nothing")
ok(ClimbEnd.countdown(9.2) == 10, "counts whole seconds up")
ok(ClimbEnd.countdown(0.01) == 1, "1 while time's left")
ok(ClimbEnd.countdown(0) == 0 and ClimbEnd.countdown(-2) == 0, "0 once it's gone")

-- the next climb starts
ok(ClimbEnd.ready(2, 2, 0, nil), "everyone's in: it starts")
ok(ClimbEnd.ready(1, 1, 0, nil), "alone and in: it starts")
ok(not ClimbEnd.ready(1, 2, 5, nil), "one of two in, no count yet (can't happen): waits")
ok(not ClimbEnd.ready(1, 2, 5, 6), "one of two in: waits for the count")
ok(ClimbEnd.ready(1, 2, 6, 6), "the count ran out: it starts")
ok(not ClimbEnd.ready(0, 0, 100, nil), "nobody here: nothing starts")
ok(ClimbEnd.AgainWait >= 5 and ClimbEnd.AgainWait <= 15, "the wait after the first press is short")

-- friends stand apart in the lobby
local spots: { [string]: boolean } = {}
for i = 1, 20 do
	local x, z = ClimbEnd.spot(i)
	local key = `{x},{z}`
	ok(not spots[key], `friend {i} stands on their own spot`)
	spots[key] = true
	ok(
		math.abs(x) <= ClimbEnd.Apart * 2 and z <= 0,
		`friend {i} stands in front of the car ({x}, {z})`
	)
end
local x1, z1 = ClimbEnd.spot(1)
ok(x1 == 0 and z1 == 0, "the first friend stands where a let-in stands")

-- the values the server writes
local at, how, floor, seconds = ClimbEnd.decode(ClimbEnd.encode(1234.5678, "Top", 3, 402.7))
ok(at ~= nil and near(at :: number, 1234.568, 1e-3), "the end's time reads back")
ok(how == "Top" and floor == 3 and seconds == 402, "how, the floor and the seconds read back")
ok(ClimbEnd.decode(nil) == nil, "no end")
ok(ClimbEnd.decode("12|Won|3|4") == nil, "an end of no known kind")
ok(ClimbEnd.decode("x|Kept|3|4") == nil, "an end with no time")
local fate, lostOn = ClimbEnd.decodeFate(ClimbEnd.encodeFate("Left", 2))
ok(fate == "Left" and lostOn == 2, "a fate reads back")
ok(ClimbEnd.decodeFate("Gone|2") == nil, "a fate of no known kind")
ok(ClimbEnd.decodeFate(7) == nil, "a fate that isn't one")

-- the results on a car's back wall (L-08e2)
do
	local value = ClimbEnd.encodeResults("Kept", 2, 402.9, {
		{ userId = 30, fate = "Kept", floor = 2, cash = 38 },
		{ userId = 10, fate = "Left", floor = 1 },
		{ userId = 20, fate = "Out", floor = 2, cash = 1204.7 },
	})
	local r = ClimbEnd.decodeResults(value)
	ok(r ~= nil, "a board reads back")
	if r then
		ok(r.how == "Kept" and r.floor == 2 and r.seconds == 402, "how, the floor and the time")
		ok(#r.rows == 3, "every friend")
		ok(r.rows[1].userId == 30 and r.rows[2].userId == 10, "in the group's order")
		ok(r.rows[2].fate == "Left" and r.rows[2].floor == 1, "a friend's fate and floor")
		ok(r.rows[1].cash == 38 and r.rows[3].cash == 1204, "each friend's cash, whole (S1-12)")
		ok(r.rows[2].cash == 0, "a friend with no cash reads as none")
	end
	local older = ClimbEnd.decodeResults("Top|3|90|5:Out:3,6:Kept:2:12")
	ok(
		older ~= nil and #older.rows == 2 and older.rows[1].cash == 0 and older.rows[2].cash == 12,
		"a row from before cash (S1-12) reads with none"
	)
	local none = ClimbEnd.decodeResults(ClimbEnd.encodeResults("Top", 3, 90, {}))
	ok(none ~= nil and none.how == "Top" and #none.rows == 0, "a board with nobody on it")
	ok(ClimbEnd.decodeResults(nil) == nil, "no board")
	ok(ClimbEnd.decodeResults("Won|3|4|") == nil, "a board of no known kind")
	local odd = ClimbEnd.decodeResults("Top|3|90|5:Out:3,x:Out:3,6:Gone:2,7:Kept:1")
	ok(odd ~= nil and #odd.rows == 2, "rows that don't read are skipped")
	local many: { ClimbEnd.Result } = {}
	for i = 1, 9 do
		table.insert(many, { userId = i, fate = "Out", floor = 3 })
	end
	local capped = ClimbEnd.decodeResults(ClimbEnd.encodeResults("Top", 3, 90, many))
	ok(capped ~= nil and #capped.rows == ClimbEnd.BoardMost, "at most a car's worth")
	local forged = ClimbEnd.decodeResults("Top|3|90|" .. string.rep("1:Out:3,", 20))
	ok(forged ~= nil and #forged.rows == ClimbEnd.BoardMost, "a long value is capped too")
end

-- the words stay few
for key, text in ClimbEnd.Copy do
	local words = #string.split(text, " ")
	ok(words <= 4, `"{key}" is a few words`)
end

-- A wipe waits on its offer (S3-03c): on the catch's black when nothing's offered, after
-- `OfferFor` when it is, and never while a buyer's prompt is open, up to `OfferPrompt`.
do
	local catch = ClimbEnd.AfterCatch
	ok(not ClimbEnd.ends(catch - 0.05, false, nil), "nothing offered: not before the black")
	ok(ClimbEnd.ends(catch, false, nil), "nothing offered: on the catch's black")
	ok(ClimbEnd.ends(catch, false, 2), "a prompt doesn't hold what isn't offered")
	ok(ClimbEnd.OfferFor > catch + 6, "the offer stands several seconds past the black")
	ok(not ClimbEnd.ends(catch, true, nil), "offered: the black doesn't end it")
	ok(not ClimbEnd.ends(ClimbEnd.OfferFor - 0.1, true, nil), "nor anything before OfferFor")
	ok(ClimbEnd.ends(ClimbEnd.OfferFor, true, nil), "offered and not bought: it ends")
	ok(not ClimbEnd.ends(ClimbEnd.OfferFor + 5, true, 4), "an open prompt holds it")
	ok(
		ClimbEnd.ends(ClimbEnd.OfferFor + 5, true, ClimbEnd.OfferPrompt),
		"until the prompt's been up OfferPrompt"
	)
end

if failures > 0 then
	error(`climbend: {failures} of {checks} checks failed`)
end
print(`climbend: {checks} checks passed`)
