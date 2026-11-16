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
export type Counts = { [string]: number }
-- When each page was first stamped, by name, in `os.time` seconds.
export type Stamps = { [string]: number }

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
}

-- The parts of Brix's SaveFormat contract the server and the spec call (`Brix.SaveFormat<Data>`).
export type Format = {
	latest: (self: any) -> number,
	fresh: (self: any) -> Data,
	encode: (self: any, data: Data) -> (unknown?, string?),
	decode: (self: any, version: number, stored: unknown) -> (Data?, string?),
}

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
	}
end

-- Finds kept at the gate (S1-06): one more of each name in `names` in `data.finds`, and the
-- book's finds page stamped `now` for any name never stamped before. Returns the names stamped
-- for the first time, in order, each once.
function Save.keep(data: Data, names: { string }, now: number): { string }
	local fresh: { string } = {}
	for _, name in names do
		data.finds[name] = (data.finds[name] or 0) + 1
		if data.stamps.finds[name] == nil then
			data.stamps.finds[name] = math.max(0, math.floor(now))
			table.insert(fresh, name)
		end
	end
	return fresh
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
		},
		fresh = Save.fresh(),
	})
end

return table.freeze(Save)
