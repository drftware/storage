--!strict
-- lune run tests/kitrows.spec
-- Each kit find's game row comes from its art (F-G1f, D-265): art/finds/rows.py writes every
-- set's GAME rows (art/finds/<set>/spec.py) into the generated `Finds/Rows`. The generated rows
-- hold every value the hand-written ones did (tests/fixtures/kitrows, frozen as they were): each
-- kit find's name, grade, worth, lowest floor, grip, heft, size in your view, sounds and verb, and
-- its press step for step, in the deal's order; the Old lamp keeps the catalog's rules (floor 25
-- up, loose only); and the game's catalog, presses and deal hold every generated row.
local Catalog = require("../src/shared/Tools/Catalog")
local Deal = require("../src/shared/Deal")
local Rows = require("../src/shared/Finds/Rows")
local Use = require("../src/shared/Finds/Use")
local Was = require("./fixtures/kitrows") :: any -- a frozen literal: read field by field below

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

-- Whether two values are the same all the way down (tables key by key, both ways).
local function same(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not same(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- Where each size sits in your view (`Tools.Catalog`'s HOLD), as the hand-written rows had it.
local HOLD: { [string]: { number } } = {
	Small = { -0.95, -0.62, -1.7 },
	Medium = { -1.2, -0.72, -2.0 },
	Large = { -1.55, -0.8, -2.4 },
}

-- The generated rows are the hand-written ones, in the deal's order.
ok(#Rows == #Was.order, `{#Rows} generated rows for {#Was.order} hand-written`)
for i, row in Rows do
	local key = row.key
	ok(key == Was.order[i], `row {i}: {key}, where the deal had {Was.order[i]}`)
	local was = Was.rows[key]
	if not was then
		continue
	end
	local c = was.catalog
	ok(row.judged, `{key}: judged (its line in WAVES.md ticked built)`)
	for _, field in { "name", "grade", "worth", "from", "grip", "heft", "pickUp", "drop", "verb" } do
		ok(same((row :: any)[field], c[field]), `{key}: {field} as it was`)
	end
	ok(same(HOLD[row.size], c.hold), `{key}: sits in your view as it did ({row.size})`)
	-- a press it had is kept step for step; one added where there was none is new data (V1 on)
	if was.press then
		ok(same(row.press, was.press), `{key}: its press as it was`)
	end
end

-- The catalog's rules for the Old lamp: found lit, from floor 25, loose only.
local lamp = nil
for _, row in Rows do
	if row.key == "UnpluggedLamp" then
		lamp = row
	end
end
ok(lamp ~= nil and lamp.from == 25 and lamp.loose == true, "the Old lamp: floor 25 up, loose only")
ok(lamp ~= nil and lamp.press == nil, "the Old lamp: found lit, no press")

-- The game holds every generated row: its catalog row, its press, its place in the deal.
local kit = {}
for _, name in Deal.Finds do
	if
		Catalog[name]
		and not ({ Boombox = true, Television = true, Teddy = true, Skates = true })[name]
	then
		table.insert(kit, name)
	end
end
for i, row in Rows do
	local c = Catalog[row.key]
	ok(c ~= nil and c.find == true and c.template == row.key, `{row.key}: a find's catalog row`)
	ok(c ~= nil and c.verb == row.verb, `{row.key}: the catalog's verb is its row's`)
	ok(same(Use.Rows[row.key], row.press), `{row.key}: Finds/Use plays its row's press`)
	ok(kit[i] == row.key, `{row.key}: dealt in its place ({kit[i]})`)
end
ok(#kit == #Rows, `the deal's kit finds ({#kit}) are the generated rows ({#Rows})`)
for key in Use.Rows do
	local found = false
	for _, row in Rows do
		found = found or row.key == key
	end
	ok(found, `{key}: a press with a generated row`)
end

print(`kitrows: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
