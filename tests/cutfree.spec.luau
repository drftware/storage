--!strict
-- Cut Free's purchase is never lost (S3-03a): its grant puts a spare in the save, freeing you
-- spends exactly one, and a spare left over waits for the next catch.
local CutFree = require("../src/shared/CutFree")
local Products = require("../src/shared/Products")
local Save = require("../src/shared/Save")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

do
	ok(Products.Rows[CutFree.Offer] ~= nil, "Cut Free is a product")
	local offers = Products.offers({ [CutFree.Offer] = 101 })
	local offer = offers[CutFree.Offer]
	local data = Save.fresh()
	ok(not CutFree.spend(data), "nothing to spend before a purchase")
	ok(offer.grant({ offer = CutFree.Offer }, data) == nil, "its grant never refuses")
	ok(CutFree.spares(data) == 1, "a purchase is one spare")
	ok(data.bought[CutFree.Offer] == 1, "and counted as bought")
	offer.grant({ offer = CutFree.Offer }, data)
	ok(CutFree.spares(data) == 2, "a second lands beside it")
	ok(CutFree.spend(data) and CutFree.spares(data) == 1, "freeing you spends one")
	ok(CutFree.spend(data) and CutFree.spares(data) == 0, "and the next")
	ok(data.spares[CutFree.Offer] == nil, "none held leaves nothing in the save")
	ok(not CutFree.spend(data) and CutFree.spares(data) == 0, "never below none")
	ok(data.bought[CutFree.Offer] == 2, "spending never touches what was bought")
end

print(`cutfree.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
