--!strict
--[[
	Gold: four of one find in the job box make one Gold of it (S5-03c3b, D-188, D-251, D-298), as
	Pet Simulator's golden machine turns copies of one pet into its golden one. The item catalog's
	variant table: solid gold that catches any light, worth five times the find, every find but the
	Secrets.

	A Gold is kept as a name of its own in the save's `finds`: the find's name with `Mark` after it
	("Teddy:Gold"), so the save's shape is unchanged (no new version) and the box, the shelf and
	the book count it as they count any find. Its catalog row is its find's (`base`); what's gold
	about it is drawn (ToolPicture) and priced (`BoxPanel.price`).
]]
local Grades = require("../Grades")

local Gold = {}

-- After a find's name, its Gold's: never in a find's own name (those are letters only).
Gold.Mark = ":Gold"
-- Of one find in the box that make one Gold: Pet Simulator's machine takes copies of one pet.
Gold.Need = 4
-- A Gold's worth, times its find's (the item catalog's variant table): a little more than the
-- four it took, so making one is a reward and never a loss.
Gold.Times = 5
-- The grade that never comes in gold: the Secrets are the rarest already (the catalog).
Gold.Never = "Secret" :: Grades.Grade

-- What a Gold is called on screen: "Gold Teddy bear".
Gold.Word = "Gold"

-- The Gold of find `name`: its key in the save.
function Gold.key(name: string): string
	return name .. Gold.Mark
end

-- The find a Gold's `key` is made of, or nil when `key` isn't a Gold's.
function Gold.base(key: string): string?
	local n = #Gold.Mark
	if #key > n and string.sub(key, -n) == Gold.Mark then
		return string.sub(key, 1, -n - 1)
	end
	return nil
end

-- Whether a find with catalog `row` can be made Gold: a find, and not a Secret.
function Gold.can(row: { find: boolean?, grade: Grades.Grade? }?): boolean
	return row ~= nil and row.find == true and row.grade ~= Gold.Never
end

return table.freeze(Gold)
