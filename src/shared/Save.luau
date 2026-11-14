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

	Nothing writes these yet; the tickets that earn them do (GDD "Saving", "The collection book").

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
	}
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

	return brix.SaveFormat.versioned({
		versions = {
			{ schema = first },
		},
		fresh = Save.fresh(),
	})
end

return table.freeze(Save)
