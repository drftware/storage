--!strict
-- lune run tests/shop.spec
-- The counter's shop (S3-04b): a remote's name is taken only when it's a colour (or, for Wear,
-- empty for the plain film), never anything else; each colour's card reads Buy until it's owned,
-- Wear once it is, Worn while it's worn; the shelf lists every colour in order with its price
-- only while it's for sale; and a shelf answer that isn't one is refused.
local Shop = require("../src/shared/Shop")
local WrapColours = require("../src/shared/WrapColours")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local blue = WrapColours.Shelf[1].name
local red = WrapColours.Shelf[2].name

-- What a remote may carry.
do
	ok(Shop.name(blue, false) == blue, "a colour's name is taken for Buy")
	ok(Shop.name(blue, true) == blue, "a colour's name is taken for Wear")
	ok(Shop.name("", true) == "", "empty is the plain film for Wear")
	ok(Shop.name("", false) == nil, "the plain film can't be bought")
	ok(Shop.name("cutFree", false) == nil, "another offer's name isn't a colour")
	ok(Shop.name(5, true) == nil, "a number isn't a name")
	ok(Shop.name(nil, true) == nil, "nothing isn't a name")
	ok(Shop.name({}, true) == nil, "a table isn't a name")
	ok(Shop.name(string.rep("a", 40), true) == nil, "a long string is refused")
end

-- A card's state.
do
	ok(Shop.state({ name = blue, owned = false }, "") == "buy", "not owned: Buy")
	ok(Shop.state({ name = blue, owned = true }, "") == "wear", "owned, not worn: Wear")
	ok(Shop.state({ name = blue, owned = true }, blue) == "worn", "owned and worn: Worn")
	ok(Shop.state({ name = blue, owned = false }, blue) == "buy", "worn but not owned: Buy")
end

-- The shelf for a save.
do
	local data = { wraps = { [blue] = 100 }, wornWrap = blue }
	local prices = { [blue] = 99, [red] = 99, cutFree = 49 }
	local shelf = Shop.shelf(data, prices)
	ok(#shelf.items == #WrapColours.Shelf, "every colour is on the shelf")
	ok(shelf.worn == blue, "what's worn")
	for i, item in shelf.items do
		ok(item.name == WrapColours.Shelf[i].name, `colour {i} in the shelf's order`)
	end
	ok(shelf.items[1].owned and shelf.items[1].price == nil, "an owned colour has no price")
	ok(not shelf.items[2].owned and shelf.items[2].price == 99, "a colour for sale has its price")
	ok(shelf.items[3].price == nil, "a colour with no product has no price")
	local gone = Shop.shelf({ wraps = {}, wornWrap = blue }, {})
	ok(gone.worn == "", "a worn colour no longer owned wears the plain film")
end

-- Reading the server's answer on the screen.
do
	ok(Shop.read(nil) == nil, "nothing isn't a shelf")
	ok(Shop.read({ worn = 1, items = {} }) == nil, "a shelf's worn is a string")
	local read = Shop.read({
		worn = blue,
		items = {
			{ name = blue, owned = true },
			{ name = "notAColour", owned = true },
			{ name = red, owned = false, price = 149 },
			{ name = red, owned = "yes" },
			5,
		},
	})
	ok(read ~= nil and #read.items == 2, "only well-formed colours are read")
	ok(read ~= nil and read.items[2].price == 149, "a price is read")
end

print(`shop.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
