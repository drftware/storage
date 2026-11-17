--!strict
--[[
	A player's save (S1-01): what lasts between visits, and every shape it has had. Players never see
	it as such; they see what it holds, kept when they leave and there when they come back:

	- `cash`: what selling finds earned, spent in the store. A whole number from 0.
	- `finds`: the finds kept in your unit in the lobby, by name (`Finds.Names`, "Boombox"), each
	  with how many. `sealed`: the same for finds still in their packaging, worth three times as much.
	  A name is listed only while you keep at least one.
	- `stamps`: the collection book, its pages stamped by name with when (`os.time`) each was first
	  stamped: `finds` for each kind of find you've had, `sealed` for each you've had still sealed,
	  `keepers` for each kind of monster you've trapped (the code calls monsters keepers).
	- `bestFloor`: the highest floor you've reached, 0 before your first climb.
	- `purchases`: the ids of the Robux purchases already granted into this save, newest last
	  (Brix's Purchases keeps the newest 100), so a receipt Roblox sends again never grants twice.
	- `recipients`: who the next purchase of an offer bought for a friend is for, by offer name
	  (Brix's Purchases names them just before the prompt).
	- `bought`: how many of each offer this player has bought, by offer name (`Products`).
	- `spares`: offers paid for and not yet used, by offer name: a Cut Free whose purchase landed
	  once you were already free waits here, and your next Cut Free press uses it (S3-03a).
	- `wraps`: the wrap colours you own, for good, by offer name, stamped with when each was first
	  bought (`WrapColours`, S3-04a).
	- `wornWrap`: the wrap colour you wear when caught, an offer name in `wraps`, or empty for the
	  plain clear film.
	- `shelf`: your home's shelf (S5-03c1a, D-284), its spots in order, each with the find on show
	  there by name ("" for an empty spot) and how new it is (`Fresh`): seen, new (it sparkles
	  till you walk up), or a kind you'd never owned (it chimes and turns as well). What's on the
	  shelf is counted in `finds` too: the shelf shows finds you own, never more of one than you
	  have.
	- `boxFresh`: how new what went into your home's job box since you last opened it is (S5-03c2a,
	  D-287), as `Fresh`: seen when nothing did; new, or a kind you'd never owned. A find kept with
	  the shelf full goes in the box (it holds every find in `finds`), and its lid sparkles till you
	  open it. What's in it is what you own less the shelf's and what's out of it (`boxed`, D-293):
	  a find taken out into your hands is still yours here, never written as gone or kept twice.
	- `chipped`: how many of the finds you keep (`finds`) have cracked glass, by name (F-G1e5e,
	  D-296: a fragile find dropped hard, `Finds/Chip`): each is worth half. Never more of a name
	  than you keep; listed only while one or more is.
	- `placed`: the finds you've set out in your home (S5-03e2, D-308): Brix's Placements saved form,
	  its `form` and a row for each find out (its id, `Spots.id`: the find's name and a number, and
	  where it stands). A find set out is still yours and still in `finds`; it's simply not in the
	  job box (`boxed` takes it off, as it does the shelf's), so it's never counted twice.
	- `looks`: your home's paint, paper, floor and floor colour (S5-03g2b, D-326), your door's
	  colour (S5-03g3a, D-329), ids from `Home.Specs.Looks` (`Home.Looks`), and your name card's
	  style (S5-03g3b, D-331), an id from `Home.Specs.Cards`; a new home's are the first of each.

	The tickets that earn each write it (GDD "Saving", "The collection book"). So far: `finds` and
	the book's `finds` page, as finds are kept at the gate (S1-06, `keep`), `cash`, as the coins
	left at a climb's end turn into it (S1-12, `earn`), and the three purchase fields, written by
	Brix's Purchases and `Products`' grants (S3-02a), and the two wrap fields, by the wrap colours'
	grants (S3-04a).

	The save keeps every version it has had, oldest first, through Brix's versioned SaveFormat: a save
	written at an older version is brought up to the newest as it loads. To change the shape, add a
	version with a `migrate` from the one before, and a sample of the old save to save.spec, so a
	migration that breaks is caught before it ships. Never edit a version already shipped: saves
	written at it still sit in the DataStore.

	Brix is handed in (`Save.format(Brix)`), since the server reaches it at `ReplicatedStorage.Brix`
	and the Lune spec at `vendor/brix/src`.
]]

-- How many of each find you keep, by its name.
-- your home's paint, paper and floor (S5-03g2b)
local Looks = require("./Home/Looks")

export type Counts = { [string]: number }
-- When each page was first stamped, by name, in `os.time` seconds.
export type Stamps = { [string]: number }

-- One spot on your home's shelf: the find there by name ("" for none) and how new it is.
export type Spot = { find: string, fresh: number }

-- One find set out in your home, as Brix's Placements saves it (`Brix.PlacementRow`): its id
-- (`Spots.id`), the area or find it stands `on`, its middle `x` and `y` there and its `turn`.
export type PlacedRow = { id: string, on: string, x: number, y: number, turn: number }
-- Everything set out in your home: Brix's saved form (`Brix.PlacementsSaved`).
export type Placed = { form: number, rows: { PlacedRow } }

export type Data = {
	cash: number,
	finds: Counts,
	sealed: Counts,
	stamps: {
		finds: Stamps,
		sealed: Stamps,
		keepers: Stamps,
	},
	bestFloor: number,
	purchases: { string },
	recipients: { [string]: string },
	bought: Counts,
	spares: Counts,
	wraps: Stamps,
	wornWrap: string,
	shelf: { Spot },
	boxFresh: number,
	chipped: Counts,
	placed: Placed,
	looks: Looks.Chosen,
}

-- The parts of Brix's SaveFormat contract the server and the spec call (`Brix.SaveFormat<Data>`).
export type Format = {
	latest: (self: any) -> number,
	fresh: (self: any) -> Data,
	encode: (self: any, data: Data) -> (unknown?, string?),
	decode: (self: any, version: number, stored: unknown) -> (Data?, string?),
}

-- what you wear goes on your clothes rail, never the shelf (S5-03f2b, D-316)
local Rail = require("./Home/Rail")

local Save = {}

-- The key a player's save sits under, by their UserId, and the UserId back from a key (Roblox
-- records it with every write, so it can find a player's data when asked to erase it).
function Save.key(userId: number): string
	return `player_{userId}`
end

function Save.userId(key: string): number?
	local digits = string.match(key, "^player_(%d+)$")
	return if digits then tonumber(digits) else nil
end

-- What a new player starts with: nothing yet. A new table each call.
function Save.fresh(): Data
	return {
		cash = 0,
		finds = {},
		sealed = {},
		stamps = { finds = {}, sealed = {}, keepers = {} },
		bestFloor = 0,
		purchases = {},
		recipients = {},
		bought = {},
		spares = {},
		wraps = {},
		wornWrap = "",
		shelf = {},
		boxFresh = 0,
		chipped = {},
		placed = { form = 1, rows = {} },
		looks = Looks.start(),
	}
end

-- How new a find on the shelf is (D-284): seen; new, sparkling till you walk up to it; or a kind
-- you'd never owned before it came home, which chimes and turns as you come near as well.
Save.Fresh = table.freeze({ Seen = 0, New = 1, Kind = 2 })
-- The most spots any shelf has (the XL unit's, D-259): what the save holds at most.
Save.ShelfMost = 24
-- The most finds any home holds set out (the XL unit's limit, D-259 idea 15): what the save holds
-- at most. `Spots.Sizes` keeps every size's limit at or under it.
Save.PlacedMost = 150

-- The name a placed row's id carries (`Spots.id`: "Teddy#2", a Gold's "Teddy:Gold#1"), or nil.
local function placedName(id: string): string?
	return string.match(id, "^(.+)#%d+$")
end
Save.placedName = placedName

-- How many of each find you've set out in your home, by name (D-308): `boxed` takes them off
-- what's in the job box.
function Save.placedCounts(data: Data): Counts
	local counts: Counts = {}
	for _, row in data.placed.rows do
		local name = placedName(row.id)
		if name then
			counts[name] = (counts[name] or 0) + 1
		end
	end
	return counts
end

-- Finds kept at the gate (S1-06): one more of each name in `names` in `data.finds`, and the
-- book's finds page stamped `now` for any name never stamped before. Each also lands on the first
-- empty spot of the shelf's first `spots` (D-284: a home's shelf, 6 in a small unit), new, or a
-- kind never owned if it was stamped just now; with the shelf full it stays in `finds` alone (the
-- job box, S5-03c2), its lid marked as new as the newest find that went in (D-287). A find you
-- wear never goes on the shelf: it stands on your clothes rail (D-316), counted in the box. Returns
-- the names stamped for the first time, in order, each once.
function Save.keep(data: Data, names: { string }, now: number, spots: number?): { string }
	local fresh: { string } = {}
	for _, name in names do
		data.finds[name] = (data.finds[name] or 0) + 1
		local kind = data.stamps.finds[name] == nil
		if kind then
			data.stamps.finds[name] = math.max(0, math.floor(now))
			table.insert(fresh, name)
		end
		local level = if kind then Save.Fresh.Kind else Save.Fresh.New
		if Rail.row(name) or not Save.shelve(data, name, level, spots or 0) then
			data.boxFresh = math.max(data.boxFresh, level)
		end
	end
	return fresh
end

-- Puts one `name` on the first empty spot of the shelf's first `spots`, `fresh` as Save.Fresh
-- says, growing the list with empty spots to reach it. Returns the spot, or nil when they're full.
function Save.shelve(data: Data, name: string, fresh: number, spots: number): number?
	local shelf = data.shelf
	for i = 1, math.min(spots, Save.ShelfMost) do
		local spot = shelf[i]
		if spot == nil then
			spot = { find = "", fresh = Save.Fresh.Seen }
			shelf[i] = spot
		end
		if spot.find == "" then
			spot.find = name
			spot.fresh = fresh
			return i
		end
	end
	return nil
end

-- Lifts every find you wear off the shelf (D-316: a save from before the rail kept the hard hat
-- there), so it's in the box and stands on your rail. How many it lifted.
function Save.unshelve(data: Data): number
	local lifted = 0
	for _, spot in data.shelf do
		if spot.find ~= "" and Rail.row(spot.find) then
			spot.find = ""
			spot.fresh = Save.Fresh.Seen
			lifted += 1
		end
	end
	return lifted
end

-- What you may have set out in your home (D-308): each find you own, less those standing on your
-- shelf and those `out` of the box (in someone's hands or lying somewhere, by name), each name
-- listed only while one or more is left. What's set out and what's in the box share it.
function Save.settable(data: Data, out: Counts): Counts
	local shelved: Counts = {}
	for _, spot in data.shelf do
		if spot.find ~= "" then
			shelved[spot.find] = (shelved[spot.find] or 0) + 1
		end
	end
	local left: Counts = {}
	for name, count in data.finds do
		local n = math.floor(count) - (shelved[name] or 0) - math.floor(out[name] or 0)
		if n >= 1 then
			left[name] = n
		end
	end
	return left
end

-- What's in your job box (S5-03c2b2, D-293): each find you own, less those standing on your shelf,
-- those set out in your home (`placed`, D-308) and those `out` of the box (in someone's hands or
-- lying somewhere, by name), each name listed only while one or more is in it. What may come out of
-- the box is exactly this, so no more of a find is ever out, on the shelf, set out or in the box
-- than you own.
function Save.boxed(data: Data, out: Counts): Counts
	local placed = Save.placedCounts(data)
	local boxed: Counts = {}
	for name, count in Save.settable(data, out) do
		local left = count - (placed[name] or 0)
		if left >= 1 then
			boxed[name] = left
		end
	end
	return boxed
end

-- How many of the shelf's first `spots` stand empty (a find from the box can go on one).
function Save.free(data: Data, spots: number): number
	local free = 0
	for i = 1, math.min(spots, Save.ShelfMost) do
		local spot = data.shelf[i]
		if spot == nil or spot.find == "" then
			free += 1
		end
	end
	return free
end

-- Marks spot `i` seen (you walked up to it). Returns whether it was new until now.
function Save.seen(data: Data, i: number): boolean
	local spot = data.shelf[i]
	if spot == nil or spot.find == "" or spot.fresh == Save.Fresh.Seen then
		return false
	end
	spot.fresh = Save.Fresh.Seen
	return true
end

-- You opened your job box (D-287): what went in is seen, its lid quiet again. Returns how new it
-- was (Save.Fresh), so opening it on a kind you'd never owned can chime.
function Save.open(data: Data): number
	local was = data.boxFresh
	data.boxFresh = Save.Fresh.Seen
	return was
end

-- Finds kept with cracked glass (F-G1e5e, D-296): one more of each name in `names` marked
-- chipped, never more of a name than `data.finds` keeps (call it after `keep` has counted them).
function Save.chip(data: Data, names: { string })
	for _, name in names do
		local owned = math.floor(data.finds[name] or 0)
		local chipped = math.min(owned, math.floor(data.chipped[name] or 0) + 1)
		if chipped >= 1 then
			data.chipped[name] = chipped
		end
	end
end

-- A find of yours lost on a climb the server ended properly (S5-03d, D-302): one of `name` struck
-- off what you own (its name gone at none), its cracks never more than what's left. Its book page
-- stays. Never touches the shelf: one out of your box is never the shelf's (`boxed`). Whether
-- there was one to strike.
function Save.lose(data: Data, name: string): boolean
	local owned = math.floor(data.finds[name] or 0)
	if owned < 1 then
		return false
	end
	local left = owned - 1
	if left >= 1 then
		data.finds[name] = left
	else
		data.finds[name] = nil -- the save's counts are one or more
	end
	local cracked = math.min(math.floor(data.chipped[name] or 0), left)
	if cracked >= 1 then
		data.chipped[name] = cracked
	else
		data.chipped[name] = nil
	end
	return true
end

-- Cash earned (S1-12, the coins left at a climb's end): `cash` more in `data.cash`, whole and never
-- below what it was. Returns the total after.
function Save.earn(data: Data, cash: number): number
	if cash == cash and cash > 0 then
		data.cash = math.floor(data.cash) + math.floor(cash)
	end
	return data.cash
end

-- The save's format, every version it has had, built on the Brix package handed in.
-- any: Brix's package, reached by a different path on the server and under Lune (above).
function Save.format(brix: any): Format
	local Schema = brix.Schema
	local name = Schema.string({ nonEmpty = true })
	local count = Schema.number({ min = 1, integer = true })
	local stamped = Schema.number({ min = 0, integer = true })

	-- Version 1 (S1-01, Nov 14): cash, finds kept plain and sealed, the book's stamps, best floor.
	local first = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
	})

	-- Version 2 (S3-02a, Nov 15): version 1 plus what Robux bought: the purchase ledger, who a
	-- friend's purchase is for, and how many of each offer.
	local second = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
	})

	-- Version 3 (S3-03a, Nov 15): version 2 plus the offers paid for and not yet used, by name: a
	-- Cut Free that landed after a friend had already freed you waits here for your next catch.
	local third = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
	})

	-- Version 4 (S3-04a, Nov 15): version 3 plus the wrap colours owned, stamped with when each was
	-- first bought, and the one worn (empty for the plain film).
	local fourth = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
		wraps = Schema.map(name, stamped),
		wornWrap = Schema.string({ maxLength = 64 }),
	})

	-- Version 5 (S5-03c1a, Nov 17): version 4 plus your home's shelf, each spot's find by name
	-- ("" for an empty spot) and how new it is (Save.Fresh).
	local fifth = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
		wraps = Schema.map(name, stamped),
		wornWrap = Schema.string({ maxLength = 64 }),
		shelf = Schema.list(
			Schema.shape({
				find = Schema.string({ maxLength = 64 }),
				fresh = Schema.number({ min = 0, max = 2, integer = true }),
			}),
			{ maxCount = Save.ShelfMost }
		),
	})

	-- Version 6 (S5-03c2a, Nov 17): version 5 plus how new what went into the job box since you
	-- last opened it is (Save.Fresh).
	local sixth = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
		wraps = Schema.map(name, stamped),
		wornWrap = Schema.string({ maxLength = 64 }),
		shelf = Schema.list(
			Schema.shape({
				find = Schema.string({ maxLength = 64 }),
				fresh = Schema.number({ min = 0, max = 2, integer = true }),
			}),
			{ maxCount = Save.ShelfMost }
		),
		boxFresh = Schema.number({ min = 0, max = 2, integer = true }),
	})

	-- Version 7 (F-G1e5e, Nov 17): version 6 plus how many of each find you keep have cracked
	-- glass (fragile, dropped hard), each worth half.
	local seventh = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
		wraps = Schema.map(name, stamped),
		wornWrap = Schema.string({ maxLength = 64 }),
		shelf = Schema.list(
			Schema.shape({
				find = Schema.string({ maxLength = 64 }),
				fresh = Schema.number({ min = 0, max = 2, integer = true }),
			}),
			{ maxCount = Save.ShelfMost }
		),
		boxFresh = Schema.number({ min = 0, max = 2, integer = true }),
		chipped = Schema.map(name, count),
	})

	-- Version 8 (S5-03e2, Nov 17): version 7 plus the finds set out in your home, as Brix's
	-- Placements saves them: ids and area names short, poses finite and bounded (a pose is
	-- within its area, every area under 50 studs; a turn is kept from 0 to 360).
	local where = Schema.string({ nonEmpty = true, maxLength = 80 })
	local eighth = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
		wraps = Schema.map(name, stamped),
		wornWrap = Schema.string({ maxLength = 64 }),
		shelf = Schema.list(
			Schema.shape({
				find = Schema.string({ maxLength = 64 }),
				fresh = Schema.number({ min = 0, max = 2, integer = true }),
			}),
			{ maxCount = Save.ShelfMost }
		),
		boxFresh = Schema.number({ min = 0, max = 2, integer = true }),
		chipped = Schema.map(name, count),
		placed = Schema.shape({
			form = Schema.number({ min = 1, max = 1000, integer = true }),
			rows = Schema.list(
				Schema.shape({
					id = where,
					on = where,
					x = Schema.number({ min = -500, max = 500 }),
					y = Schema.number({ min = -500, max = 500 }),
					turn = Schema.number({ min = -360, max = 360 }),
				}),
				{ maxCount = Save.PlacedMost }
			),
		}),
	})

	-- Version 9 (S5-03g2b, Nov 17): version 8 plus your home's paint, paper, floor and floor
	-- colour, ids from Home.Specs.Looks (a floor colour "" for the boards, baked).
	local look = Schema.string({ nonEmpty = true, maxLength = 32 })
	local ninth = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
		wraps = Schema.map(name, stamped),
		wornWrap = Schema.string({ maxLength = 64 }),
		shelf = Schema.list(
			Schema.shape({
				find = Schema.string({ maxLength = 64 }),
				fresh = Schema.number({ min = 0, max = 2, integer = true }),
			}),
			{ maxCount = Save.ShelfMost }
		),
		boxFresh = Schema.number({ min = 0, max = 2, integer = true }),
		chipped = Schema.map(name, count),
		placed = Schema.shape({
			form = Schema.number({ min = 1, max = 1000, integer = true }),
			rows = Schema.list(
				Schema.shape({
					id = where,
					on = where,
					x = Schema.number({ min = -500, max = 500 }),
					y = Schema.number({ min = -500, max = 500 }),
					turn = Schema.number({ min = -360, max = 360 }),
				}),
				{ maxCount = Save.PlacedMost }
			),
		}),
		looks = Schema.shape({
			paint = look,
			paper = look,
			floor = look,
			floorColour = Schema.string({ maxLength = 32 }),
		}),
	})

	-- Version 10 (S5-03g3a, Nov 17): version 9 plus your door's colour, an id from
	-- Home.Specs.Looks.Doors.
	local tenth = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
		wraps = Schema.map(name, stamped),
		wornWrap = Schema.string({ maxLength = 64 }),
		shelf = Schema.list(
			Schema.shape({
				find = Schema.string({ maxLength = 64 }),
				fresh = Schema.number({ min = 0, max = 2, integer = true }),
			}),
			{ maxCount = Save.ShelfMost }
		),
		boxFresh = Schema.number({ min = 0, max = 2, integer = true }),
		chipped = Schema.map(name, count),
		placed = Schema.shape({
			form = Schema.number({ min = 1, max = 1000, integer = true }),
			rows = Schema.list(
				Schema.shape({
					id = where,
					on = where,
					x = Schema.number({ min = -500, max = 500 }),
					y = Schema.number({ min = -500, max = 500 }),
					turn = Schema.number({ min = -360, max = 360 }),
				}),
				{ maxCount = Save.PlacedMost }
			),
		}),
		looks = Schema.shape({
			paint = look,
			paper = look,
			floor = look,
			floorColour = Schema.string({ maxLength = 32 }),
			door = look,
		}),
	})

	-- Version 11 (S5-03g3b, Nov 17): version 10 plus your name card's style, an id from
	-- Home.Specs.Cards.
	local eleventh = Schema.shape({
		cash = Schema.number({ min = 0, integer = true }),
		finds = Schema.map(name, count),
		sealed = Schema.map(name, count),
		stamps = Schema.shape({
			finds = Schema.map(name, stamped),
			sealed = Schema.map(name, stamped),
			keepers = Schema.map(name, stamped),
		}),
		bestFloor = Schema.number({ min = 0, integer = true }),
		purchases = Schema.list(name),
		recipients = Schema.map(name, name),
		bought = Schema.map(name, count),
		spares = Schema.map(name, count),
		wraps = Schema.map(name, stamped),
		wornWrap = Schema.string({ maxLength = 64 }),
		shelf = Schema.list(
			Schema.shape({
				find = Schema.string({ maxLength = 64 }),
				fresh = Schema.number({ min = 0, max = 2, integer = true }),
			}),
			{ maxCount = Save.ShelfMost }
		),
		boxFresh = Schema.number({ min = 0, max = 2, integer = true }),
		chipped = Schema.map(name, count),
		placed = Schema.shape({
			form = Schema.number({ min = 1, max = 1000, integer = true }),
			rows = Schema.list(
				Schema.shape({
					id = where,
					on = where,
					x = Schema.number({ min = -500, max = 500 }),
					y = Schema.number({ min = -500, max = 500 }),
					turn = Schema.number({ min = -360, max = 360 }),
				}),
				{ maxCount = Save.PlacedMost }
			),
		}),
		looks = Schema.shape({
			paint = look,
			paper = look,
			floor = look,
			floorColour = Schema.string({ maxLength = 32 }),
			door = look,
			card = look,
		}),
	})

	return brix.SaveFormat.versioned({
		versions = {
			{ schema = first },
			{
				schema = second,
				-- any: a version 1 save as Brix hands it over, already checked against `first`
				migrate = function(old: any): any
					return {
						cash = old.cash,
						finds = old.finds,
						sealed = old.sealed,
						stamps = old.stamps,
						bestFloor = old.bestFloor,
						purchases = {},
						recipients = {},
						bought = {},
					}
				end,
			},
			{
				schema = third,
				-- any: a version 2 save as Brix hands it over, already checked against `second`
				migrate = function(old: any): any
					return {
						cash = old.cash,
						finds = old.finds,
						sealed = old.sealed,
						stamps = old.stamps,
						bestFloor = old.bestFloor,
						purchases = old.purchases,
						recipients = old.recipients,
						bought = old.bought,
						spares = {},
					}
				end,
			},
			{
				schema = fourth,
				-- any: a version 3 save as Brix hands it over, already checked against `third`
				migrate = function(old: any): any
					return {
						cash = old.cash,
						finds = old.finds,
						sealed = old.sealed,
						stamps = old.stamps,
						bestFloor = old.bestFloor,
						purchases = old.purchases,
						recipients = old.recipients,
						bought = old.bought,
						spares = old.spares,
						wraps = {},
						wornWrap = "",
					}
				end,
			},
			{
				schema = fifth,
				-- any: a version 4 save as Brix hands it over, already checked against `fourth`
				migrate = function(old: any): any
					return {
						cash = old.cash,
						finds = old.finds,
						sealed = old.sealed,
						stamps = old.stamps,
						bestFloor = old.bestFloor,
						purchases = old.purchases,
						recipients = old.recipients,
						bought = old.bought,
						spares = old.spares,
						wraps = old.wraps,
						wornWrap = old.wornWrap,
						shelf = {},
					}
				end,
			},
			{
				schema = sixth,
				-- any: a version 5 save as Brix hands it over, already checked against `fifth`
				migrate = function(old: any): any
					return {
						cash = old.cash,
						finds = old.finds,
						sealed = old.sealed,
						stamps = old.stamps,
						bestFloor = old.bestFloor,
						purchases = old.purchases,
						recipients = old.recipients,
						bought = old.bought,
						spares = old.spares,
						wraps = old.wraps,
						wornWrap = old.wornWrap,
						shelf = old.shelf,
						boxFresh = 0,
					}
				end,
			},
			{
				schema = seventh,
				-- any: a version 6 save as Brix hands it over, already checked against `sixth`
				migrate = function(old: any): any
					return {
						cash = old.cash,
						finds = old.finds,
						sealed = old.sealed,
						stamps = old.stamps,
						bestFloor = old.bestFloor,
						purchases = old.purchases,
						recipients = old.recipients,
						bought = old.bought,
						spares = old.spares,
						wraps = old.wraps,
						wornWrap = old.wornWrap,
						shelf = old.shelf,
						boxFresh = old.boxFresh,
						chipped = {},
					}
				end,
			},
			{
				schema = eighth,
				-- any: a version 7 save as Brix hands it over, already checked against `seventh`
				migrate = function(old: any): any
					return {
						cash = old.cash,
						finds = old.finds,
						sealed = old.sealed,
						stamps = old.stamps,
						bestFloor = old.bestFloor,
						purchases = old.purchases,
						recipients = old.recipients,
						bought = old.bought,
						spares = old.spares,
						wraps = old.wraps,
						wornWrap = old.wornWrap,
						shelf = old.shelf,
						boxFresh = old.boxFresh,
						chipped = old.chipped,
						placed = { form = 1, rows = {} }, -- nothing set out yet
					}
				end,
			},
			{
				schema = ninth,
				-- any: a version 8 save as Brix hands it over, already checked against `eighth`
				migrate = function(old: any): any
					local start = Looks.start()
					return {
						cash = old.cash,
						finds = old.finds,
						sealed = old.sealed,
						stamps = old.stamps,
						bestFloor = old.bestFloor,
						purchases = old.purchases,
						recipients = old.recipients,
						bought = old.bought,
						spares = old.spares,
						wraps = old.wraps,
						wornWrap = old.wornWrap,
						shelf = old.shelf,
						boxFresh = old.boxFresh,
						chipped = old.chipped,
						placed = old.placed,
						-- the home as it always looked, in version 9's shape (no door yet)
						looks = {
							paint = start.paint,
							paper = start.paper,
							floor = start.floor,
							floorColour = start.floorColour,
						},
					}
				end,
			},
			{
				schema = tenth,
				-- any: a version 9 save as Brix hands it over, already checked against `ninth`
				migrate = function(old: any): any
					local after = table.clone(old)
					after.looks = table.clone(old.looks)
					after.looks.door = Looks.start().door -- the clay door it always had
					return after
				end,
			},
			{
				schema = eleventh,
				-- any: a version 10 save as Brix hands it over, already checked against `tenth`
				migrate = function(old: any): any
					local after = table.clone(old)
					after.looks = table.clone(old.looks)
					after.looks.card = Looks.start().card -- the stencilled steel every home had
					return after
				end,
			},
		},
		fresh = Save.fresh(),
	})
end

return table.freeze(Save)
