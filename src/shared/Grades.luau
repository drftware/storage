--!strict
--[[
	Grades (D-188, the item catalog's "Grades: how rare a find is"): six of them, Common to Secret.
	A find's grade says how often it turns up and about what it's worth. A unit dealt a find rolls
	the grade first, by the floor it's on, then one find of that grade (`Deal.findFrom`), the way
	Pet Simulator's eggs roll a rarity and then a pet of it. Pure: Lune tests it
	(tests/findgrade.spec.luau).

	Every number here is the catalog's, a starting guess for the owner to tune.
]]

export type Grade = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Secret"

local Grades = {}

-- Rarest last.
Grades.Names = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret" } :: { Grade }

--[[
	The chance of each grade, out of 100, for a find dealt on floors 1 to 9, 10 to 24 and 25 up.
	Higher floors hold rarer finds, so going up is how you hunt the good stuff: a Legendary is 1
	find in 200 on the first floors and 1 in 25 from floor 25. No Secret below floor 10.
]]
Grades.Bands = {
	{
		from = 1,
		odds = { Common = 62, Uncommon = 25, Rare = 10, Epic = 2.5, Legendary = 0.5, Secret = 0 },
	},
	{
		from = 10,
		odds = { Common = 50, Uncommon = 28, Rare = 14, Epic = 6, Legendary = 1.8, Secret = 0.2 },
	},
	{
		from = 25,
		odds = { Common = 40, Uncommon = 28, Rare = 18, Epic = 9, Legendary = 4, Secret = 1 },
	},
} :: { { from: number, odds: { [string]: number } } }

-- From this floor the Secret chance doubles again, so the best players always have a reason to
-- climb higher (the catalog).
Grades.SecretDoubles = 50

-- What a find of each grade is worth in cash (the catalog's Value column, on the scale where a
-- battery costs 3 coins): each find's own worth (its catalog row's `worth`) lies in its grade's.
Grades.Worth = {
	Common = { 1, 9 },
	Uncommon = { 10, 29 },
	Rare = { 30, 89 },
	Epic = { 90, 299 },
	Legendary = { 300, 999 },
	Secret = { 1000, 12000 },
} :: { [string]: { number } }

--[[
	Each grade's colour (red, green, blue 0 to 255), the light a marked box leaks as it opens on a
	find of that grade (B-02b), as Pet Simulator's eggs and Brawl Stars' Starr Drops tell the prize
	by colour before it shows: Common the box's own warm light, Uncommon green, Rare blue, Epic
	purple, Legendary gold, Secret red. Mid-bright, so a Neon glow keeps its colour on a phone.
]]
Grades.Colours = {
	Common = { 255, 170, 92 },
	Uncommon = { 92, 220, 118 },
	Rare = { 64, 148, 255 },
	Epic = { 178, 92, 255 },
	Legendary = { 255, 196, 56 },
	Secret = { 255, 54, 92 },
} :: { [string]: { number } }

-- Each grade's chance, out of 100 (more past `SecretDoubles`), for a find dealt on floor `number`.
function Grades.odds(number: number): { [string]: number }
	local band = Grades.Bands[1]
	for _, b in Grades.Bands do
		if number >= b.from then
			band = b
		end
	end
	local odds = table.clone(band.odds)
	if number >= Grades.SecretDoubles then
		odds.Secret *= 2
	end
	return odds
end

return Grades
