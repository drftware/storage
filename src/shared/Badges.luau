--!strict
--[[
	Badges (S6-01a, D-432): the Roblox badges a climb earns, worked out from what the save already
	holds. Roblox's own milestone badges, as DOORS and Pressure award one for reaching a door or a
	depth: the badge pops on Roblox's own toast the moment you earn it, and stays on your profile.

	- A floor badge for reaching floors 10, 25, 50 and 100 (`Floors`): your best floor
	  (`Save.Data.bestFloor`) at or past it.
	- A badge for each kind of monster the team has shut in a unit while you rode the gate out
	  (the book's monsters page, `stamps.keepers`, by keeper row name: "Mannequin").
	- A badge for each set of finds finished: every find of the set stamped in your book
	  (`stamps.finds`). A set is the finds' own family for now (`Finds/Rows`' `set`: the
	  night-lights, the squishies, the wind-ups) until the collection book (S5-04) names its own.

	A badge is known by a key ("Floor10", "Trapped:Mannequin", "Set:Lights") and awarded on Roblox by
	the id in `Ids`. The owner makes each badge on the Creator Dashboard and fills its id in here
	(OWNER.md); a key with no id is earned but never sent, and is sent the next time the player
	plays once the id is in. Pure: the server (BestFloors) asks Roblox and awards.
]]

local Game = require("./Finds/Game")

local Badges = {}

-- The floors whose reaching earns a badge: a first long climb (10), then each a real stretch past
-- the last. A player's best floor at or past one has earned it.
Badges.Floors = table.freeze({ 10, 25, 50, 100 })

-- A player's attribute holding their best floor (a whole number, 0 before a climb), set by the
-- server from their save as it loads and as it rises: every screen reads it for the lobby's dial
-- and plaque (S6-01b).
Badges.BestAttribute = "BestFloor"

-- Each badge's id on Roblox, by key. 0 until the owner makes the badge on the Creator Dashboard
-- (Creations, this experience, Badges) and pastes its id here: a 0 is never awarded. A monster
-- kind or a set with no line here earns no badge.
Badges.Ids = table.freeze({
	Floor10 = 0,
	Floor25 = 0,
	Floor50 = 0,
	Floor100 = 0,
	["Trapped:Mannequin"] = 0,
	["Trapped:Packrat"] = 0,
	["Set:Lights"] = 0,
	["Set:Squishies"] = 0,
	["Set:Windups"] = 0,
	["Set:Figures"] = 0,
	["Set:Big"] = 0, -- the big finds, one a floor (S4-05)
} :: { [string]: number })

-- The finds of each set, by set name, each set's names in row order. Only finds the deal can hand
-- out count (`judged`): a set never waits on a find nobody can find yet.
export type Sets = { [string]: { string } }

function Badges.floorKey(floor: number): string
	return `Floor{floor}`
end

function Badges.trappedKey(kind: string): string
	return `Trapped:{kind}`
end

function Badges.setKey(set: string): string
	return `Set:{set}`
end

-- Every set's finds from the find rows.
function Badges.sets(rows: { Game.Row }): Sets
	local out: Sets = {}
	for _, row in rows do
		if row.judged then
			local names = out[row.set]
			if not names then
				names = {}
				out[row.set] = names
			end
			table.insert(names, row.key)
		end
	end
	return out
end

-- Whether every find of `names` is stamped in the book's finds page.
local function finished(names: { string }, finds: { [string]: number }): boolean
	if #names == 0 then
		return false
	end
	for _, name in names do
		if finds[name] == nil then
			return false
		end
	end
	return true
end

-- Every badge a save has earned, by key, sorted: the floors first, then the monsters, then the
-- sets. From its best floor and its book's finds and monsters pages (`Save.Data`'s `bestFloor`,
-- `stamps.finds`, `stamps.keepers`). Earned whether or not it has an id yet.
function Badges.earned(
	bestFloor: number,
	finds: { [string]: number },
	keepers: { [string]: number },
	sets: Sets
): { string }
	local out: { string } = {}
	for _, floor in Badges.Floors do
		if bestFloor >= floor then
			table.insert(out, Badges.floorKey(floor))
		end
	end
	local kinds: { string } = {}
	for kind in keepers do
		table.insert(kinds, kind)
	end
	table.sort(kinds)
	for _, kind in kinds do
		table.insert(out, Badges.trappedKey(kind))
	end
	local names: { string } = {}
	for set in sets do
		table.insert(names, set)
	end
	table.sort(names)
	for _, set in names do
		if finished(sets[set], finds) then
			table.insert(out, Badges.setKey(set))
		end
	end
	return out
end

-- A badge to send to Roblox: its key and its id.
export type Award = { key: string, id: number }

-- The badges of `earned` still to send: each with an id in `ids` (above 0, a whole number) and not
-- in `done` (already given or found held this visit), in `earned`'s order.
function Badges.toAward(
	earned: { string },
	ids: { [string]: number },
	done: { [string]: boolean }
): { Award }
	local out: { Award } = {}
	for _, key in earned do
		local id = ids[key]
		if id and id > 0 and id == math.floor(id) and not done[key] then
			table.insert(out, { key = key, id = id })
		end
	end
	return out
end

return table.freeze(Badges)
