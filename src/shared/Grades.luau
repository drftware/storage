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
	The chance of each grade, out of 100, for a find dealt on floors 1, 10 and 25 (the catalog's
	three bands; each floor between moves evenly from one to the next, `odds`). Higher floors hold
	rarer finds, so going up is how you hunt the good stuff: a Legendary is 1 find in 200 on floor
	1, about 1 in 100 by floor 5 and 1 in 25 from floor 25. No Secret below floor 10.
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

--[[
	Each grade's chance, out of 100 (more past `SecretDoubles`), for a find dealt on floor `number`
	(S5-02a). The catalog's odds stand on the floor each band starts (1, 10, 25), and between two
	of those floors every floor moves evenly from one band's odds to the next: floor 5's finds are
	better than floor 4's, not only floor 10's than floor 9's, as Lethal Company's scrap is worth
	more on each riskier moon and Diablo's items get better level by level. So a team that pushes
	two floors higher opens doors on better things. A grade a band has none of stays none until
	the band that has it (no Secret below 10); the rest share its chance out evenly, so the odds
	still add to 100. Past the last band the odds hold, and the Secret chance doubles from
	`SecretDoubles`.
]]
function Grades.odds(number: number): { [string]: number }
	local bands = Grades.Bands
	local band, after = bands[1], nil
	for i, b in bands do
		if number >= b.from then
			band, after = b, bands[i + 1]
		end
	end
	local odds = table.clone(band.odds)
	if after then
		local t = (number - band.from) / (after.from - band.from)
		local total = 0
		for _, grade in Grades.Names do
			local from = band.odds[grade]
			local chance = if from > 0 then from + (after.odds[grade] - from) * t else 0
			odds[grade] = chance
			total += chance
		end
		for _, grade in Grades.Names do
			odds[grade] = odds[grade] * 100 / total
		end
	end
	if number >= Grades.SecretDoubles then
		odds.Secret *= 2
	end
	return odds
end

return Grades
