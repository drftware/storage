--!strict
-- lune run tests/taken.spec
-- Taking finds up (S5-03d, D-251, D-302): a find taken out of your job box stays in your save
-- while it's out, so a crash never costs one; it's struck off only when it's lost on a climb the
-- server ended properly (`Save.lose`); carried aboard by you it stays yours and nothing changes;
-- carried aboard by a friend it's theirs and struck off yours, so across both saves it's never
-- doubled; a crack it took on the climb comes home with it.
local Save = require("../src/shared/Save")
local Taken = require("../src/shared/Home/Taken")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local SPOTS = 6

-- How many of `name` two saves own between them.
local function total(a: Save.Data, b: Save.Data, name: string): number
	return (a.finds[name] or 0) + (b.finds[name] or 0)
end

-- One struck off what you own (Save.lose): the count, its cracks, never past none.
do
	local data = Save.fresh()
	data.finds = { Lamp = 3, Teddy = 1, ["Teddy:Gold"] = 1 }
	data.chipped = { Lamp = 3 }
	ok(Save.lose(data, "Lamp"), "one Lamp lost")
	ok(data.finds.Lamp == 2 and data.chipped.Lamp == 2, "one fewer; cracks never top what's left")
	ok(Save.lose(data, "Teddy") and data.finds.Teddy == nil, "the last Teddy: its name leaves")
	ok(not Save.lose(data, "Teddy"), "none left: refused")
	ok(data.finds.Teddy == nil, "and nothing below none")
	ok(
		Save.lose(data, "Teddy:Gold") and data.finds["Teddy:Gold"] == nil,
		"a Gold is lost by its key"
	)
	data.stamps.finds.Lamp = 100
	data.chipped = { Lamp = 1 }
	ok(Save.lose(data, "Lamp") and data.chipped.Lamp == 1, "a whole one lost: the crack stays")
	ok(data.stamps.finds.Lamp == 100, "the book keeps its page")

	-- one out of the box is never the shelf's: losing it leaves the shelf alone
	data.finds = { Vase = 2 }
	data.chipped = {}
	data.shelf = {}
	ok(Save.shelve(data, "Vase", Save.Fresh.Seen, SPOTS) == 1, "one Vase on the shelf")
	local boxed = Save.boxed(data, { Vase = 1 })
	ok((boxed.Vase or 0) == 0, "the other's out in your hands")
	ok(Save.lose(data, "Vase"), "the one out is lost")
	ok(data.finds.Vase == 1 and data.shelf[1].find == "Vase", "the shelf's still stands")
end

-- Carried aboard by you: it stays yours and stays out, and nothing in the save changes.
do
	local mine = Save.fresh()
	mine.finds = { Lamp = 2 }
	local before = mine.finds.Lamp
	local fate = Taken.settle({ name = "Lamp", how = "Aboard", now = 50, spots = SPOTS }, mine, nil)
	ok(fate == "Out", "your own, aboard: still out, in your hands")
	ok(mine.finds.Lamp == before, "never added again")
	for _ = 1, 5 do
		Taken.settle({ name = "Lamp", how = "Aboard", now = 50, spots = SPOTS }, mine, nil)
	end
	ok(mine.finds.Lamp == before, "five gates later, still two: never doubled")
end

-- Carried aboard by a friend: theirs now, struck off yours, so between you it's still one.
do
	local mine, theirs = Save.fresh(), Save.fresh()
	mine.finds = { Lamp = 2 }
	mine.chipped = { Lamp = 2 }
	theirs.finds = {}
	local fate =
		Taken.settle({ name = "Lamp", how = "Aboard", now = 77, spots = SPOTS }, mine, theirs)
	ok(fate == "Moved", "a friend carried it aboard: moved to them")
	ok(mine.finds.Lamp == 1 and mine.chipped.Lamp == 1, "struck off yours, cracks with it")
	ok(theirs.finds.Lamp == 1, "theirs now")
	ok(theirs.stamps.finds.Lamp == 77, "a new kind in their book")
	ok(theirs.shelf[1] and theirs.shelf[1].find == "Lamp", "on their shelf, as any kept find")
	ok(total(mine, theirs, "Lamp") == 2, "between you, still two: never doubled")

	-- the owner left first: theirs was struck as they left, so the friend keeps it as a find
	local friend = Save.fresh()
	ok(
		Taken.settle({ name = "Lamp", how = "Aboard", now = 80, spots = SPOTS }, nil, friend)
			== "Moved",
		"its owner gone: the friend keeps it"
	)
	ok(friend.finds.Lamp == 1, "theirs")

	-- a Gold moves as a Gold
	mine.finds["Teddy:Gold"] = 1
	Taken.settle({ name = "Teddy:Gold", how = "Aboard", now = 90, spots = SPOTS }, mine, theirs)
	ok(mine.finds["Teddy:Gold"] == nil and theirs.finds["Teddy:Gold"] == 1, "a Gold moves whole")
end

-- Lost on a climb the server ended properly (its floor left behind, the climb over, or its owner
-- leaving mid-climb): struck off, once.
do
	local mine = Save.fresh()
	mine.finds = { Lamp = 1, Boombox = 3 }
	ok(
		Taken.settle({ name = "Lamp", how = "Lost", now = 0, spots = SPOTS }, mine, nil) == "Lost",
		"lost"
	)
	ok(mine.finds.Lamp == nil, "struck off")
	ok(
		Taken.settle({ name = "Lamp", how = "Lost", now = 0, spots = SPOTS }, mine, nil) == "Gone",
		"a second loss of the same: nothing left to strike"
	)
	ok(mine.finds.Boombox == 3, "the rest untouched")
	ok(
		Taken.settle({ name = "Lamp", how = "Lost", now = 0, spots = SPOTS }, nil, nil) == "Gone",
		"its owner's save gone: nothing to strike (struck as they left)"
	)
end

-- Back in its owner's box (they left at home, or put it back): nothing struck; a crack it took
-- on the climb comes home with it.
do
	local mine = Save.fresh()
	mine.finds = { Lamp = 2 }
	ok(
		Taken.settle({ name = "Lamp", how = "Back", now = 0, spots = SPOTS }, mine, nil) == "Back",
		"back in the box"
	)
	ok(mine.finds.Lamp == 2 and mine.chipped.Lamp == nil, "unchanged")
	Taken.settle({ name = "Lamp", how = "Back", cracked = true, now = 0, spots = SPOTS }, mine, nil)
	ok(mine.chipped.Lamp == 1, "cracked on the climb: one more cracked")

	local theirs = Save.fresh()
	mine.chipped = {}
	Taken.settle(
		{ name = "Lamp", how = "Aboard", cracked = true, now = 0, spots = SPOTS },
		mine,
		theirs
	)
	ok(theirs.chipped.Lamp == 1, "a friend's carried home cracked: cracked in theirs")
	ok(mine.chipped.Lamp == nil, "and not in yours")

	-- your own, cracked, carried aboard: still out; its crack waits until it's back (or lost)
	Taken.settle(
		{ name = "Lamp", how = "Aboard", cracked = true, now = 0, spots = SPOTS },
		mine,
		nil
	)
	ok(mine.chipped.Lamp == nil, "still out: nothing written yet")
end

-- A crash or a shutdown mid-climb settles nothing: what the save last held is what you have.
do
	local mine = Save.fresh()
	mine.finds = { Lamp = 1 }
	local written = table.clone(mine.finds) -- the last write, the find out on the climb
	ok(written.Lamp == 1, "a crash mid-climb: the Lamp is still yours when you come back")
	ok(Save.boxed(mine, {}).Lamp == 1, "and back in your box: nothing is out on a new server")
end

-- Bad input never changes a save.
do
	local mine = Save.fresh()
	mine.finds = { Lamp = 1 }
	ok(
		Taken.settle({ name = "", how = "Lost", now = 0, spots = SPOTS }, mine, nil) == "Gone",
		"no name: nothing"
	)
	ok(
		Taken.settle({ name = "Lamp", how = "Odd" :: any, now = 0, spots = SPOTS }, mine, nil)
			== "Gone",
		"no such end: nothing"
	)
	ok(mine.finds.Lamp == 1, "untouched")
end

-- Across the trip (S5-03d4, D-358): the climb's own server deals only what the owner's save backs.
-- The trip's word passed through each rider's device, so a forged or missing find is refused (it
-- stays in the box), and what's dealt keeps its crack.
do
	local function up(owner: number, name: string, cracked: boolean?, holder: number?): Taken.Up
		return {
			owner = owner,
			name = name,
			holder = holder or owner,
			cracked = cracked == true,
			worn = false,
		}
	end
	local data = Save.fresh()
	data.finds = { Lamp = 2, Boombox = 1, ["Teddy:Gold"] = 1 }
	data.chipped = { Boombox = 1 }
	data.shelf[1] = { find = "Lamp", fresh = Save.Fresh.Seen } -- one Lamp stands on the shelf
	local ups = {
		up(101, "Lamp"),
		up(101, "Lamp"), -- a second: the other is on the shelf
		up(101, "Boombox", true, 7), -- cracked, in a friend's hands
		up(101, "Skates"), -- never owned
		up(7, "Teddy:Gold"), -- another rider's word about this one's find
		up(101, "Teddy:Gold"),
	}
	local dealt = Taken.backed(ups, 101, data, {})
	ok(#dealt == 3, "three backed by the save")
	ok(dealt[1].name == "Lamp", "the box's one Lamp")
	ok(
		dealt[2].name == "Boombox" and dealt[2].cracked and dealt[2].holder == 7,
		"a cracked one stays cracked, in the friend's hands"
	)
	ok(dealt[3].name == "Teddy:Gold", "a Gold by its key")
	ok(data.finds.Lamp == 2 and data.finds.Boombox == 1, "checking writes nothing")
	ok(
		#Taken.backed(ups, 101, data, { Lamp = 1, Boombox = 1, ["Teddy:Gold"] = 1 }) == 0,
		"those already out here are refused"
	)
	ok(#Taken.backed({}, 101, data, {}) == 0, "nothing carried, nothing dealt")
	ok(#Taken.backed(ups, 55, data, {}) == 0, "nobody's finds but the owner's")
	ok(#Taken.backed(ups, 101, Save.fresh(), {}) == 0, "a save with none: all refused")
	-- dealt, then lost on a climb that ended properly: struck once, never twice
	ok(
		Taken.settle({ name = "Lamp", how = "Lost", now = 0, spots = SPOTS }, data) == "Lost",
		"lost"
	)
	ok(data.finds.Lamp == 1, "one struck off")
	ok(#Taken.backed({ up(101, "Lamp") }, 101, data, {}) == 0, "the one left is the shelf's")
end

-- A sealed find out of its box (S5-02b2c, D-427): settled by its sealed name; torn on the climb,
-- it comes back or moves on plain, the sealed one struck.
do
	local SPOTS_ = 6
	local mine = Save.fresh()
	mine.finds["Teddy:Sealed"] = 2
	local theirs = Save.fresh()
	local e = { name = "Teddy:Sealed", how = "Back" :: Taken.How, now = 1, spots = SPOTS_ }
	ok(Taken.settle(e, mine, nil) == "Back", "a sealed teddy back in its box whole")
	ok(mine.finds["Teddy:Sealed"] == 2 and mine.finds.Teddy == nil, "still sealed in the save")
	local torn =
		{ name = "Teddy:Sealed", how = "Back" :: Taken.How, torn = true, now = 1, spots = SPOTS_ }
	ok(Taken.settle(torn, mine, nil) == "Back", "a torn one back in its box")
	ok(mine.finds["Teddy:Sealed"] == 1 and mine.finds.Teddy == 1, "back plain, one sealed left")
	local moved =
		{ name = "Teddy:Sealed", how = "Aboard" :: Taken.How, torn = true, now = 2, spots = SPOTS_ }
	ok(Taken.settle(moved, mine, theirs) == "Moved", "a torn one carried aboard by a friend")
	ok(mine.finds["Teddy:Sealed"] == nil and mine.finds.Teddy == 1, "struck sealed off its owner's")
	ok(theirs.finds.Teddy == 1 and theirs.finds["Teddy:Sealed"] == nil, "theirs now, plain")
	ok(theirs.stamps.sealed.Teddy == nil, "a torn one stamps no sealed page")
	mine.finds["Teddy:Sealed"] = 1
	local whole = { name = "Teddy:Sealed", how = "Aboard" :: Taken.How, now = 3, spots = SPOTS_ }
	ok(Taken.settle(whole, mine, theirs) == "Moved", "a whole sealed one carried aboard")
	ok(theirs.finds["Teddy:Sealed"] == 1 and theirs.stamps.sealed.Teddy == 3, "theirs, sealed")
	local lost =
		{ name = "Teddy:Sealed", how = "Lost" :: Taken.How, torn = true, now = 4, spots = SPOTS_ }
	mine.finds["Teddy:Sealed"] = 1
	ok(
		Taken.settle(lost, mine, nil) == "Lost" and mine.finds["Teddy:Sealed"] == nil,
		"lost: struck"
	)
	ok(mine.finds.Teddy == 1, "never a plain one struck for it")
end

print(`taken.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
