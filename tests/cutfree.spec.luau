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

-- Free a Friend (S3-03b): bought for a friend, granted as a spare in the buyer's save, spent
-- apart from Cut Free's; a press names its friend by a whole, non-zero UserId only.
do
	local row = Products.Rows[CutFree.FriendOffer]
	ok(row ~= nil and row.forAnother == true, "Free a Friend is a product bought for another")
	local offers = Products.offers({ [CutFree.FriendOffer] = 202, [CutFree.Offer] = 101 })
	local offer = offers[CutFree.FriendOffer]
	ok(offer.forAnother == true, "and Brix hears it's for another")
	ok(offers[CutFree.Offer].forAnother == nil, "Cut Free is for yourself")
	local data = Save.fresh()
	ok(
		offer.grant({ offer = CutFree.FriendOffer, recipient = "Player_2" }, data) == nil,
		"it never refuses"
	)
	ok(CutFree.spares(data, CutFree.FriendOffer) == 1, "a purchase is one spare, the buyer's")
	ok(CutFree.spares(data) == 0, "not a Cut Free")
	ok(data.bought[CutFree.FriendOffer] == 1, "counted as bought")
	ok(not CutFree.spend(data), "spending a Cut Free leaves it alone")
	ok(CutFree.spend(data, CutFree.FriendOffer), "freeing a friend spends it")
	ok(data.spares[CutFree.FriendOffer] == nil, "and none is left")

	ok(CutFree.friendId(12345) == 12345, "a UserId names a friend")
	ok(CutFree.friendId(-2) == -2, "so does a Studio test player's")
	ok(CutFree.friendId(0) == nil, "0 is nobody")
	ok(CutFree.friendId(1.5) == nil, "a fraction is nobody")
	ok(CutFree.friendId(0 / 0) == nil, "NaN is nobody")
	ok(CutFree.friendId(math.huge) == nil, "infinity is nobody")
	ok(CutFree.friendId(2 ^ 60) == nil, "past Roblox's ids is nobody")
	ok(CutFree.friendId("12345") == nil, "text is nobody")
	ok(CutFree.friendId(nil) == nil, "nothing is nobody")
end

-- Free Everyone (S3-03c): a spare in the buyer's save, spent once however many it frees; alone,
-- the wipe's offer is Cut Free, which does the same for you.
do
	ok(Products.Rows[CutFree.EveryoneOffer] ~= nil, "Free Everyone is a product")
	local offers = Products.offers({ [CutFree.EveryoneOffer] = 103 })
	local offer = offers[CutFree.EveryoneOffer]
	local data = Save.fresh()
	ok(offer.grant({ offer = CutFree.EveryoneOffer }, data) == nil, "its grant never refuses")
	ok(CutFree.spares(data, CutFree.EveryoneOffer) == 1, "a purchase is one spare")
	ok(CutFree.spares(data) == 0, "not a Cut Free")
	ok(CutFree.spend(data, CutFree.EveryoneOffer), "freeing everyone spends it")
	ok(not CutFree.spend(data, CutFree.EveryoneOffer), "once")
	ok(CutFree.wipeOffer(1) == CutFree.Offer, "alone, the wipe offers Cut Free")
	ok(CutFree.wipeOffer(0) == CutFree.Offer, "and with nobody counted")
	ok(CutFree.wipeOffer(2) == CutFree.EveryoneOffer, "with a friend, Free Everyone")
	ok(CutFree.EveryoneWide > CutFree.Wide, "its pill is wider than Cut Free's")
end

print(`cutfree.spec: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
