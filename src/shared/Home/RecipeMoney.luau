--!strict
--[[
	RecipeMoney (S5-03k1, D-476): what each recipe is worth per hour of the thing it runs on, against
	a ceiling, so no recipe at home out-earns climbing. A recipe that waits on the clock earns while
	you're away, as Grow a Garden's plants do; past a point that pays more than playing does and the
	climb stops mattering. tests/reciperows.spec fails a shipped row above `Ceiling`.

	Pure, and names no find: it reads rows and a worth for each kind (`RecipeRows.worth`).
	The report takes the best case: the cheapest thing a row's `held` match takes, the results'
	worth (a chance weighed by its odds, an `again` row by its round), over the time its timed
	stages take. Rows with no timed stage wait on players, not the clock, and are left out.
]]
local Pay = require("../Pay")

local RecipeMoney = {}

-- The most cash an hour one recipe may earn on one thing, from the clock alone: a floor 1 gate's
-- pay (`Pay.forFloor`), so an incubator left all night is a nice surprise, never better than one
-- climb. Raising it makes home machines a reason to log in; too high and they replace the climb.
-- A default (OWNER.md).
RecipeMoney.Ceiling = Pay.forFloor(1)

export type Line = { id: string, perHour: number, seconds: number }

-- any: a result as a row writes it (Brix's RecipeResult), read field by field.
local function worthOf(results: { any }, worth: (string) -> number, inWorth: number): number
	local total = 0
	for _, result in results do
		if result.does == "make" then
			total += worth(result.kind) * (result.count or 1)
		elseif result.does == "become" then
			-- the thing it's on is furniture, never sold: only what's in it counts as spent
			total += worth(result.into) - (if result.of == "in" then inWorth else 0)
		elseif result.does == "useUp" and result.of == "in" then
			total -= inWorth
		elseif result.does == "chance" then
			for _, outcome in result.outcomes do
				total += outcome.odds * worthOf(outcome.results, worth, inWorth)
			end
		end
	end
	return total
end

-- The cheapest kind a match takes, among `kinds` (kind to its tags).
local function cheapest(
	match: any,
	kinds: { [string]: { string } },
	worth: (string) -> number
): number
	if match == nil then
		return 0
	end
	if match.kind then
		return worth(match.kind)
	end
	local least = math.huge
	for kind, tags in kinds do
		if table.find(tags, match.tag) then
			least = math.min(least, worth(kind))
		end
	end
	return if least == math.huge then 0 else least
end

-- One line per row with timed stages: its id, cash an hour, and the seconds one round takes.
-- any: rows as the game writes them (Brix's RecipeRow), already checked by the book.
function RecipeMoney.report(
	rows: { any },
	kinds: { [string]: { string } },
	worth: (string) -> number
): { Line }
	local lines: { Line } = {}
	for _, row in rows do
		local seconds = 0
		for _, stage in row.stages do
			if stage.ends == "time" then
				seconds += stage.seconds
			end
		end
		if seconds > 0 then
			local gain = worthOf(row.results, worth, cheapest(row.held, kinds, worth))
			table.insert(lines, { id = row.id, perHour = gain * 3600 / seconds, seconds = seconds })
		end
	end
	return lines
end

return table.freeze(RecipeMoney)
