--!strict
-- lune run tests/wrapcolours.spec
-- Wrap colours (S3-04a): each colour is a product of its own, bought once and kept; bought, it's
-- owned for good and worn at once; one bought again is still granted (the Robux are spent) but
-- owned once; only an owned colour (or the plain film) can be worn; a worn name that's no longer a
-- colour or no longer owned wears as the plain film; and nothing on the shelf is the plain film.
local Products = require("../src/shared/Products")
local Save = require("../src/shared/Save")
local WrapColours = require("../src/shared/WrapColours")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- The shelf: every colour named once, a product row of its own titled "<label> Wrap", tinted.
do
	local seen = {}
	ok(#WrapColours.Shelf >= 1, "the shelf has colours")
	for _, colour in WrapColours.Shelf do
		ok(seen[colour.name] == nil, `{colour.name} is on the shelf once`)
		seen[colour.name] = true
		local row = Products.Rows[colour.name]
		ok(row ~= nil, `{colour.name} is a product`)
		ok(
			row ~= nil and row.title == `{colour.label} Wrap`,
			`{colour.name} is titled for the Dashboard`
		)
		ok(row ~= nil and row.owned ~= nil, `{colour.name} is bought once and kept`)
		ok(row ~= nil and row.forAnother == nil, `{colour.name} is bought for yourself`)
		local rgb = colour.rgb
		ok(
			#rgb == 3 and not (rgb[1] == 255 and rgb[2] == 255 and rgb[3] == 255),
			`{colour.name} isn't the plain film`
		)
		ok(WrapColours.rgb(colour.name) == rgb, `{colour.name} tints the film its own colour`)
		ok(WrapColours.get(colour.name) == colour, `{colour.name} is found by name`)
	end
	ok(WrapColours.get("") == nil and WrapColours.get(nil) == nil, "the plain film isn't a colour")
	ok(WrapColours.rgb("") == WrapColours.Plain, "the plain film keeps its own colour")
	ok(WrapColours.rgb("wrapNothing") == WrapColours.Plain, "a name that isn't a colour is plain")
end

-- Bought through its product's grant: owned for good, worn at once, counted.
local first = WrapColours.Shelf[1]
local second = WrapColours.Shelf[2]
do
	local data = Save.fresh()
	ok(WrapColours.worn(data) == "", "a new player wears the plain film")
	local offers = Products.offers({ [first.name] = 9101, [second.name] = 9102 })
	local why = offers[first.name].grant({ offer = first.name }, data)
	ok(why == nil, "a colour's grant is never refused")
	ok(WrapColours.owns(data, first.name), "bought, it's owned")
	ok(data.wraps[first.name] ~= nil and data.wraps[first.name] > 0, "owned, stamped with when")
	ok(WrapColours.worn(data) == first.name, "bought, it's worn at once")
	ok(data.bought[first.name] == 1, "the purchase is counted")
	ok(Products.Rows[first.name].owned(data), "an owned colour is never sold to them again")
	ok(not Products.Rows[second.name].owned(data), "another colour is still for sale")

	-- a second colour: both owned, the newest worn
	offers[second.name].grant({ offer = second.name }, data)
	ok(WrapColours.owns(data, first.name) and WrapColours.owns(data, second.name), "both owned")
	ok(WrapColours.worn(data) == second.name, "the newest is worn")

	-- the first bought again (two prompts open at once): granted, counted, owned from the first time
	local stamp = 1794800000
	data.wraps[first.name] = stamp
	ok(offers[first.name].grant({ offer = first.name }, data) == nil, "bought again, still granted")
	ok(data.bought[first.name] == 2, "bought again, counted again")
	ok(data.wraps[first.name] == stamp, "bought again, owned from the first time")
	ok(WrapColours.worn(data) == first.name, "bought again, worn again")
end

-- Wearing: an owned colour or the plain film; anything else refused and nothing changed.
do
	local data = Save.fresh()
	ok(WrapColours.wear(data, first.name) == "notOwned", "a colour not owned can't be worn")
	ok(data.wornWrap == "", "a refused colour changes nothing")
	ok(
		WrapColours.wear(data, "wrapNothing") == "notAColour",
		"a name that isn't a colour can't be worn"
	)
	WrapColours.own(data, first.name, 1794800000)
	ok(
		WrapColours.wear(data, "") == nil and WrapColours.worn(data) == "",
		"the plain film, put back on"
	)
	ok(
		WrapColours.wear(data, first.name) == nil and WrapColours.worn(data) == first.name,
		"an owned colour, worn"
	)
	ok(WrapColours.rgb(WrapColours.worn(data)) == first.rgb, "worn, its tint is the film's")
end

-- A save that names a colour gone from the shelf, or one it doesn't own, wears the plain film.
do
	local data = Save.fresh()
	data.wraps.wrapRetired = 1794800000
	data.wornWrap = "wrapRetired"
	ok(WrapColours.worn(data) == "", "a colour gone from the shelf wears as the plain film")
	data.wornWrap = first.name
	ok(WrapColours.worn(data) == "", "a colour worn but not owned wears as the plain film")
end

print(`wrapcolours.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
