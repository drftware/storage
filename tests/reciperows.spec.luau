--!strict
-- lune run tests/reciperows.spec
-- The game's recipes (S5-03k1, D-476): the shipped rows make a book with no problems; a bad row is
-- caught; test-only rows (never shipped) use every word of the vocabulary through the game's own
-- kinds and looks and run with no code written for them; no recipe code file names a find, a
-- recipe or a look (only data rows may); no recipe earns more an hour than the ceiling; kinds still
-- to come leave `Coming` once their real row lands.
local fs = require("@lune/fs")

local Brix = require("../vendor/brix/src")
local FindRows = require("../src/shared/Finds/Rows")
local Furniture = require("../src/shared/Home/Furniture")
local RecipeMoney = require("../src/shared/Home/RecipeMoney")
local RecipeRows = require("../src/shared/Home/RecipeRows")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- any: Brix's problem rows, printed whole when a check fails.
local function said(problems: { any }): string
	local out = {}
	for _, p in problems do
		table.insert(out, `{p.id or p.index}: {p.field} {p.reason}`)
	end
	return table.concat(out, "; ")
end

-- The shipped rows: every one filed, none left out.
do
	local book, problems = RecipeRows.book(Brix)
	ok(#problems == 0, `the shipped rows have no problems ({said(problems)})`)
	ok(book:count() == #RecipeRows.Rows, "every shipped row is filed")
	for _, row in RecipeRows.Rows do
		for _, stage in row.stages do
			ok(
				RecipeRows.Looks[stage.look] ~= nil,
				`{row.id}'s stage look {stage.look} is in Looks`
			)
		end
	end
end

-- Kinds still to come are none of the catalog's: each leaves `Coming` the session its row lands.
do
	for kind in RecipeRows.Coming do
		local found = false
		for _, row in FindRows do
			found = found or row.key == kind
		end
		ok(not found and Furniture.byId(kind) == nil, `{kind} is still to come, not yet a real row`)
	end
end

-- A bad row is caught, with the field at fault: an unknown find, an unknown look, a stage that can
-- never end. any: rows written wrong on purpose.
local function caught(row: any, field: string, reason: string)
	local _, problems = Brix.Recipes.book({
		rows = { row },
		kinds = RecipeRows.kinds(),
		looks = RecipeRows.Looks,
		events = RecipeRows.Events,
	})
	local p = problems[1]
	ok(
		#problems == 1 and p.field == field and p.reason == reason,
		`{row.id} is caught at {field} as {reason} ({said(problems)})`
	)
end

local function hatchLike(): any
	local row = table.clone(RecipeRows.Rows[1] :: any)
	row.stages = table.clone(row.stages)
	row.results = table.clone(row.results)
	return row
end

do
	local unknownFind = hatchLike()
	unknownFind.id = "unknownFind"
	unknownFind.results[2] = { does = "make", kind = "NoSuchFind", at = "beside" }
	caught(unknownFind, "results[2].kind", "unknownKind")

	local unknownLook = hatchLike()
	unknownLook.id = "unknownLook"
	unknownLook.stages[2] = { look = "sparkling", ends = "time", seconds = 60 }
	caught(unknownLook, "stages[2].look", "unknownLook")

	local neverEnds = hatchLike()
	neverEnds.id = "neverEnds"
	neverEnds.stages[1] = { look = "warming", ends = "time", seconds = 0 }
	caught(neverEnds, "stages[1].seconds", "cannotEnd")

	local nothingNear = hatchLike()
	nothingNear.id = "nothingNear"
	nothingNear.stages[1] = { look = "warming", ends = "near", near = { tag = "nosuchtag" } }
	caught(nothingNear, "stages[1].near.tag", "unknownTag")
end

-- Test-only rows, never shipped: every start, stage end and result, over the game's own kinds and
-- looks, with a few test kinds added as a new find's catalog row would add them. No code is
-- written for any of them; Brix runs each as it runs the hatch.
do
	local kinds = RecipeRows.kinds()
	kinds.ClayPot = { "pot" }
	kinds.Acorn = { "seed" }
	kinds.WateringCan = { "water" }
	kinds.Sapling = {}
	kinds.Charger = {}
	kinds.Cell = { "cell" }
	kinds.Flour = {}
	kinds.Jug = {}
	kinds.Dough = {}
	kinds.MusicBox = {}
	table.insert(kinds.DeskLamp, "light") -- a catalog find given a tag, as a new row would
	local warming, wobbling = "warming", "wobbling" -- the game's looks, reused as they stand

	local rows = {
		{ -- put; time, given (used up, twice), near; become
			id = "sprout",
			on = { tag = "pot" },
			held = { tag = "seed" },
			start = "put",
			verb = "Plant",
			stages = {
				{ look = warming, ends = "time", seconds = 600 },
				{
					look = wobbling,
					ends = "given",
					given = { tag = "water" },
					verb = "Water",
					count = 2,
					useUp = true,
				},
				{ look = warming, ends = "near", near = { tag = "light" } },
			},
			results = { { does = "become", of = "in", into = "Sapling" } },
		},
		{ -- use; presses, event; give back
			id = "charge",
			on = { kind = "Charger" },
			held = { tag = "cell" },
			start = "use",
			verb = "Charge",
			stages = {
				{ look = wobbling, ends = "presses", count = 3, verb = "Wind" },
				{ look = warming, ends = "event", event = "climbed" },
			},
			results = { { does = "giveBack", of = "in" } },
		},
		{ -- put with no stages: two things combined at once; use up, become the thing it's on
			id = "dough",
			on = { kind = "Jug" },
			held = { kind = "Flour" },
			start = "put",
			verb = "Mix",
			stages = {},
			results = {
				{ does = "useUp", of = "in" },
				{ does = "become", of = "on", into = "Dough" },
			},
		},
		{ -- the game's own egg tag on a real furniture piece; a chance that may bring nothing
			id = "lucky",
			on = { kind = "MilkCrate" },
			held = { tag = "egg" },
			start = "put",
			verb = "Place",
			stages = { { look = warming, ends = "time", seconds = 60 } },
			results = {
				{
					does = "chance",
					outcomes = {
						{
							odds = 0.5,
							results = { { does = "make", kind = "Chick", at = "stored" } },
						},
						{ odds = 0.5, results = {} },
					},
				},
			},
		},
		{ -- press with empty hands; starts over by itself
			id = "tune",
			on = { kind = "MusicBox" },
			start = "press",
			verb = "Wind",
			stages = { { look = wobbling, ends = "time", seconds = 20 } },
			results = { { does = "again" } },
		},
	}
	for _, row in RecipeRows.Rows do
		table.insert(rows, row :: any)
	end
	local book, problems = Brix.Recipes.book({
		rows = rows,
		kinds = kinds,
		looks = RecipeRows.Looks,
		events = { "climbed" },
	})
	ok(#problems == 0, `the test-only rows file with the shipped ones ({said(problems)})`)

	-- Every word of the vocabulary is used by some row here.
	local used: { [string]: boolean } = {}
	for _, row in rows do
		used[row.start] = true
		for _, stage in row.stages do
			used[stage.ends] = true
		end
		local function mark(results: { any })
			for _, result in results do
				used[result.does] = true
				if result.outcomes then
					for _, outcome in result.outcomes do
						mark(outcome.results)
					end
				end
			end
		end
		mark(row.results)
	end
	for _, list in { { "put", "use", "press" }, { "time", "presses", "near", "given", "event" } } do
		for _, w in list do
			ok(used[w] == true, `a test row uses {w}`)
		end
	end
	for _, w in { "become", "make", "useUp", "giveBack", "chance", "again" } do
		ok(used[w] == true, `a test row uses {w}`)
	end

	local found = {}
	book:find("ClayPot", "Acorn", found)
	ok(#found == 1 and found[1].id == "sprout", "a seed in a pot finds the sprout by tags alone")
	book:find("Incubator", "Egg", found)
	ok(#found == 1 and found[1].id == "hatch", "any egg in the incubator finds the hatch")
	book:find("MilkCrate", "Egg", found)
	ok(#found == 1 and found[1].id == "lucky", "the egg tag reaches a test row too")

	-- The sprout: ten minutes, two waterings (each can used up), a lamp near; a sapling.
	local t = 1000
	local sprout = book:start("sprout", t, 11)
	local step = book:advance(sprout, t + 600)
	ok(step.passed == 1 and sprout.stage == 2, "the sprout's first stage ends on the clock")
	step = book:advance(sprout, t + 601, { kind = "given", thing = "WateringCan", verb = "Water" })
	ok(step.counted and step.usedUp and sprout.stage == 2, "one watering counts and takes the can")
	book:advance(sprout, t + 602, { kind = "given", thing = "WateringCan", verb = "Water" })
	ok(sprout.stage == 3, "two waterings end the stage")
	step = book:advance(sprout, t + 603, { kind = "near", thing = "DeskLamp" })
	ok(
		step.ended == 1 and step.results[1].does == "become" and step.results[1].into == "Sapling",
		"a lamp near it ends the sprout: a sapling"
	)

	-- The charge: three winds and a climb; the cell comes back.
	local charge = book:start("charge", t, 3)
	for _ = 1, 3 do
		book:advance(charge, t + 1, { kind = "press", verb = "Wind" })
	end
	step = book:advance(charge, t + 2, { kind = "event", name = "climbed" })
	ok(
		step.ended == 1 and step.results[1].does == "giveBack",
		"three winds and a climb give the cell back"
	)

	-- The dough: done the moment it starts.
	local _, doughStep = book:start("dough", t, 5)
	ok(doughStep.ended == 1 and #doughStep.results == 2, "flour and a jug combine at once")

	-- The lucky crate: the same seed rolls the same, rejoin or not.
	local a = book:start("lucky", t, 42)
	local b = book:start("lucky", t, 42)
	local stepA = book:advance(a, t + 60)
	local first = #stepA.results
	local stepB = book:advance(b, t + 60)
	ok(stepA.ended == 1 and first == #stepB.results, "a chance rolls the same from the same seed")

	-- The tune: a minute away plays it three times over and leaves it running.
	local tune = book:start("tune", t, 9)
	step = book:advance(tune, t + 65)
	ok(step.ended == 3 and tune.stage == 1, "a tune that starts over catches up a minute away")

	-- The hatch itself: 2 hours 10 minutes; the egg goes, a chick comes out beside.
	local hatch = book:start("hatch", t, 1)
	ok(book:due(hatch) == t + 7200, "the hatch is due when warming ends")
	step = book:advance(hatch, t + 7800)
	ok(
		step.ended == 1
			and step.results[1].does == "useUp"
			and step.results[2].kind == "Chick"
			and step.results[2].at == "beside",
		"the hatch ends: the egg used up, a chick beside"
	)
end

-- The money report: no shipped row earns more an hour than the ceiling.
do
	local lines = RecipeMoney.report(RecipeRows.Rows, RecipeRows.kinds(), RecipeRows.worth)
	ok(#lines >= 1, "the hatch is in the money report")
	for _, line in lines do
		ok(
			line.perHour <= RecipeMoney.Ceiling,
			`{line.id} earns {math.floor(line.perHour * 10) / 10} an hour, at most {RecipeMoney.Ceiling}`
		)
	end
	local greedy = hatchLike()
	greedy.stages = { { look = "warming", ends = "time", seconds = 60 } }
	local greedyLine = RecipeMoney.report({ greedy }, RecipeRows.kinds(), RecipeRows.worth)[1]
	ok(
		greedyLine.perHour > RecipeMoney.Ceiling,
		"a minute's hatch would beat the ceiling: the check bites"
	)
end

-- The no-names check: recipe code names no find, no furniture piece, no recipe and no look. Only
-- data may: RecipeRows above its code marker. Every later recipe file (its name holds "Recipe")
-- is read whole.
local NAMED: { [string]: boolean } = {}
for _, row in FindRows do
	NAMED[row.key] = true
end
for _, piece in Furniture.Pieces do
	NAMED[piece.id] = true
end
for kind in RecipeRows.Coming do
	NAMED[kind] = true
end
for _, row in RecipeRows.Rows do
	NAMED[row.id] = true
end
for look in RecipeRows.Looks do
	NAMED[look] = true
end
for _, first in { "Boombox", "Television", "Teddy", "Skates" } do -- `Finds.Names`, the first four
	NAMED[first] = true
end

local MARKER = "-- ===== Code:"

-- The code of a file's text with its comments and the data part (above the marker) left out.
local function codeOf(text: string): string
	local at = string.find(text, MARKER, 1, true)
	if at then
		text = string.sub(text, at)
	end
	text = string.gsub(text, "%-%-%[(=*)%[.-%]%1%]", "")
	text = string.gsub(text, "%-%-[^\n]*", "")
	return text
end

-- The names a piece of code names, as whole words.
local function namesIn(code: string): { string }
	local found = {}
	for word in string.gmatch(code, "[%a_][%w_]*") do
		if NAMED[word] then
			table.insert(found, word)
		end
	end
	return found
end

do
	ok(
		#namesIn(codeOf('local x = 1\nif kind == "Incubator" then end')) == 1,
		"the check catches a named kind"
	)
	ok(
		#namesIn(codeOf("-- the Incubator in a comment\nlocal y = 2")) == 0,
		"a comment may name things"
	)
	local text = fs.readFile("src/shared/Home/RecipeRows.luau")
	ok(string.find(text, MARKER, 1, true) ~= nil, "RecipeRows has its code marker")

	local files = {}
	local function walk(dir: string)
		for _, entry in fs.readDir(dir) do
			local path = `{dir}/{entry}`
			if fs.isDir(path) then
				walk(path)
			elseif string.find(entry, "Recipe", 1, true) and string.match(entry, "%.luau$") then
				table.insert(files, path)
			end
		end
	end
	walk("src")
	ok(#files >= 2, "the recipe code files are found")
	for _, path in files do
		local names = namesIn(codeOf(fs.readFile(path)))
		ok(
			#names == 0,
			`{path} names no find, recipe or look (it names {table.concat(names, ", ")})`
		)
	end
end

print(`reciperows.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
