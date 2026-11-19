--!strict
--[[
	RecipeRows (S5-03k1, D-476): every recipe the game has, as data, and the kinds and looks they
	pick from. A recipe is what one thing does to another at home: an egg put in the incubator warms,
	wobbles and hatches a chick (Stardew Valley's incubator; its 1.6 update's one machine data file,
	which modders extend without code). Brix's Recipes checks and files the rows (`book`); the server
	(S5-03k2) runs them, the screens (S5-03k4) draw each stage's look.

	The moment: the egg you carried home from a climb fits the incubator, and a new egg joins the
	hatch later by one tag on its catalog row (`art/finds/rows.py`'s `tags`), with no code.

	The file is two parts. The data part (the rows, the looks, the kinds still to come) is the only
	place in the game's recipe code that names a find. The code part, below its marker line, names
	none: tests/reciperows.spec fails if it does, and every later recipe file is held to the same.

	- `Rows`: Brix's recipe rows (`vendor/brix/docs/modules/Recipes.md` says every word). Only the
	  hatch ships; other recipes are new design, the owner's (OWNER.md).
	- `Looks`: each stage's look by name, from a closed set of parts every recipe may use: a
	  `motion` from the thing's own art kit, a `glow`, a `sound`, and `grows` (harder toward the
	  stage's end). Brix reads only the names; the screens read the parts.
	- `Events`: the game's own happenings a stage may wait for. None yet.
	- `Coming`: kinds a shipped row names whose art and catalog row a later ticket builds (S5-03k3),
	  each with its tags and a default worth for the money report. A kind leaves this list the
	  session its real row lands (the spec fails while it's in both).
]]
local FindRows = require("../Finds/Rows")
local Furniture = require("./Furniture")

local RecipeRows = {}

local HOUR = 3600
local MINUTE = 60

-- A row's shape: Brix's `RecipeRow`, its words as plain strings (the book checks every word).
export type Match = { kind: string?, tag: string? }
export type Stage = {
	look: string,
	ends: string,
	seconds: number?,
	count: number?,
	verb: string?,
	near: Match?,
	given: Match?,
	useUp: boolean?,
	event: string?,
}
export type Result = {
	does: string,
	of: string?,
	into: string?,
	kind: string?,
	count: number?,
	at: string?,
	outcomes: { { odds: number, results: { Result } } }?,
}
export type Row = {
	id: string,
	on: Match,
	held: Match?,
	start: string,
	verb: string,
	stages: { Stage },
	results: { Result },
}

-- ===== Data: the only part that names finds =====

local rows: { Row } = {
	{
		-- Any egg into an incubator: warms 2 hours under the lamp, wobbles 10 minutes, and a chick
		-- comes out beside it (D-436's defaults, OWNER.md). The incubator stays for the next egg.
		id = "hatch",
		on = { kind = "Incubator" },
		held = { tag = "egg" },
		start = "put",
		verb = "Place",
		stages = {
			{ look = "warming", ends = "time", seconds = 2 * HOUR },
			{ look = "wobbling", ends = "time", seconds = 10 * MINUTE },
		},
		results = {
			{ does = "useUp", of = "in" },
			{ does = "make", kind = "Chick", at = "beside" },
		},
	},
}
RecipeRows.Rows = table.freeze(rows)

-- Each part a look may have. A new look is one entry below; a new part is code (the screens').
export type Look = {
	motion: string?, -- a motion from the thing's own art kit (S5-03k3 names them)
	glow: string?, -- a glow the thing gives off
	sound: string?, -- a sound it makes, looped while the stage lasts
	grows: boolean?, -- the look gets stronger as the stage nears its end (the wobble harder)
}

local looks: { [string]: Look } = {
	warming = table.freeze({ glow = "warm", sound = "hum" }), -- the lamp glows over the egg
	wobbling = table.freeze({ motion = "wobble", grows = true }), -- the egg rocks, harder near the end
}
RecipeRows.Looks = table.freeze(looks)

local events: { string } = {}
RecipeRows.Events = table.freeze(events)

-- A kind a row names before its art exists: its tags and its worth in cash (a default, OWNER.md).
export type Coming = { tags: { string }, worth: number }

local coming: { [string]: Coming } = {
	Incubator = { tags = {}, worth = 0 }, -- a furniture piece at the counter (S5-03k3)
	Egg = { tags = { "egg" }, worth = 12 }, -- dealt on climbs, Uncommon (S5-03k3)
	Chick = { tags = {}, worth = 30 }, -- a find set out where it lands, Rare (S5-03k3)
}
RecipeRows.Coming = table.freeze(coming)

-- ===== Code: names no find, no recipe, no stage (the no-names check reads from here down) =====

-- Every kind a row may name, with its tags in the order a lookup tries them: each kit find (its
-- catalog row's tags), each furniture piece, and each kind still to come. Built fresh per call;
-- the book keeps its own frozen copy.
function RecipeRows.kinds(): { [string]: { string } }
	local kinds: { [string]: { string } } = {}
	for _, row in FindRows do
		kinds[row.key] = if row.tags then table.clone(row.tags) else {}
	end
	for _, piece in Furniture.Pieces do
		kinds[piece.id] = {}
	end
	for kind, later in RecipeRows.Coming do
		if kinds[kind] == nil then
			kinds[kind] = table.clone(later.tags)
		end
	end
	return kinds
end

-- What a kind is worth in cash: its catalog row's worth, a kind to come's default, 0 for furniture
-- (never sold back). Read by the money report.
function RecipeRows.worth(kind: string): number
	for _, row in FindRows do
		if row.key == kind then
			return row.worth
		end
	end
	local later = RecipeRows.Coming[kind]
	return if later then later.worth else 0
end

-- The recipe book over the game's rows, kinds, looks and events, and the rows it left out.
-- any: Brix's package, reached by a different path on the server and under Lune (as `Save.format`).
function RecipeRows.book(brix: any): (any, { any })
	return brix.Recipes.book({
		rows = RecipeRows.Rows,
		kinds = RecipeRows.kinds(),
		looks = RecipeRows.Looks,
		events = RecipeRows.Events,
	})
end

return table.freeze(RecipeRows)
