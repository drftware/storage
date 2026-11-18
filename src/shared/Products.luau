--!strict
--[[
	What this game sells for Robux (S3-02a, GDD "Monetization"): the one table of products. The
	moment it serves: a player pays and gets what they paid for at once, exactly once, never lost.

	Each row is one developer product, under the offer name the game and its records use:

	- `title`: the product's name on the Creator Dashboard, exactly. The server finds each
	  product's id by this name (S3-02b), so making a product there with this name is all it takes
	  to sell it; renaming one there stops it selling until the row changes too.
	- `switch`: its key in the live config (Brix's LiveConfig over Roblox's experience configs).
	  On by default; set to false there and the offer is off on every server within a minute, no
	  update needed.
	- `grant`: what it puts in the buyer's save, answering why it can't before changing anything
	  (Brix's grant rules: never throw, never yield). Nil for an offer whose effect lands at once
	  on the server, such as Cut Free (S3-03), heard from Purchases' `onGranted`.
	- `ownerOnly`: prompted only by the place's owner's dev prompt, never shown to players.
	- `forAnother`: bought for another player, named as the prompt goes up (Brix's recipients,
	  D-206); its grant still lands in the buyer's save, and the sale's `recipient` says who.
	- `owned`: for a thing bought once and kept (a wrap colour), whether the save already has it:
	  an owned thing is never put on sale to that player again.
	- `gift` and `away`: for a thing given into a friend's save (a bigger home, S5-03h3b), Brix's
	  gift: `gift` changes the friend's save, written before the buyer's purchase counts, when this
	  server holds it; `away` changes the buyer's instead when it doesn't (the friend left). Such a
	  row has no `grant`.

	Prices are never here: Roblox's are read each time an offer is shown (Brix's Marketplace).
	Whatever a row grants, `offers` also counts the purchase in the save's `bought`, the same
	change as Brix's ledger, so a purchase counted once is a purchase granted once. Nothing random
	is ever a product (GDD: nothing random is sold, for Robux or for cash).
]]
local Grow = require("./Home/Grow")
local Save = require("./Save")
local WrapColours = require("./WrapColours")

-- any: Brix's sale, as `Brix.PurchaseSale<Player>`; only `offer` is read here.
type Sale = any
type Grant = (sale: Sale, data: Save.Data) -> string?

export type Row = {
	title: string,
	switch: string,
	grant: Grant?,
	ownerOnly: boolean?,
	forAnother: boolean?,
	owned: ((data: Save.Data) -> boolean)?,
	gift: Grant?,
	away: Grant?,
}

-- The shape of each offer handed to `Brix.Purchases.new` (`Brix.PurchaseOffer<Save.Data, Player>`).
export type Offer = {
	product: number,
	grant: Grant?,
	forAnother: boolean?,
	gift: Grant?,
	away: Grant?,
}

local Products = {}

-- Every product, by offer name; the wrap colours are added after, one row each.
local rows: { [string]: Row } = {
	-- Cut Free (S3-03a, GDD "Getting caught", DOORS' revive): caught, you pay and you're out at
	-- once. Granted as a spare in the save, which the server spends as it frees you (CutFrees),
	-- so one that lands after a friend already freed you waits for your next catch.
	cutFree = table.freeze({
		title = "Cut Free",
		switch = "sellCutFree",
		grant = function(_sale: Sale, data: Save.Data): string?
			data.spares.cutFree = (data.spares.cutFree or 0) + 1
			return nil
		end,
	}),
	-- Free a Friend (S3-03b, GDD "Getting caught"): you pay to free a caught friend from
	-- wherever you're standing. Bought for them, but granted as a spare in the buyer's save,
	-- which the server spends as it frees the friend (CutFrees): one that lands after they're
	-- already out waits for the buyer's next press, so the purchase is never lost.
	freeFriend = table.freeze({
		title = "Free a Friend",
		switch = "sellFreeFriend",
		forAnother = true,
		grant = function(_sale: Sale, data: Save.Data): string?
			data.spares.freeFriend = (data.spares.freeFriend or 0) + 1
			return nil
		end,
	}),
	-- Free Everyone (S3-03c, GDD "Getting caught"): the whole team is caught, and before the
	-- results one player pays to free every caught player at once. Granted as a spare in the
	-- buyer's save, which the server spends as it frees them (CutFrees): one that lands after the
	-- results waits for the buyer's next wipe, so the purchase is never lost.
	freeEveryone = table.freeze({
		title = "Free Everyone",
		switch = "sellFreeEveryone",
		grant = function(_sale: Sale, data: Save.Data): string?
			data.spares.freeEveryone = (data.spares.freeEveryone or 0) + 1
			return nil
		end,
	}),
	-- The owner's test: a real purchase on the published place that grants nothing but its count,
	-- for Brix's ENG-23e phone test (a forced save failure, a server hop), so the test never
	-- touches cash or anything a player plays for.
	testPurchase = table.freeze({
		title = "Test purchase",
		switch = "sellTestPurchase",
		ownerOnly = true,
	}),
}

-- Wrap colours (S3-04a, GDD "Monetization"): one product each, "Blue Wrap" and so on, bought once
-- and kept. The grant owns it for good and puts it on at once (`WrapColours`), a permanent thing
-- in the save, never a spare; one bought again (two prompts open at once) is still granted, worn
-- and counted, never refused, since the Robux are spent.
for _, colour in WrapColours.Shelf do
	local name = colour.name
	rows[name] = table.freeze({
		title = `{colour.label} Wrap`,
		switch = `sell{string.upper(string.sub(name, 1, 1))}{string.sub(name, 2)}`,
		grant = function(_sale: Sale, data: Save.Data): string?
			WrapColours.own(data, name, os.time())
			return nil
		end,
		owned = function(data: Save.Data): boolean
			return WrapColours.owns(data, name)
		end,
	})
end

-- Your home's Robux sizes (S5-03h3a, D-342; the home doc's idea 30): "Large Unit" and "XL Unit",
-- as Adopt Me sells its bigger houses. The grant grows your home to the size in the save Brix
-- writes before the purchase counts (`Grow.grant`), so the counter's answer and the bigger room
-- come only once it's kept. Owned at that size or bigger, so it's never prompted then; a late one
-- (two prompts bought at once) is still granted and counted, never refused, since the Robux are
-- spent, and the home stays the bigger size.
for size, offer in Grow.Robux do
	rows[offer] = table.freeze({
		title = `{size} Unit`,
		switch = `sell{string.upper(string.sub(offer, 1, 1))}{string.sub(offer, 2)}`,
		grant = function(_sale: Sale, data: Save.Data): string?
			Grow.grant(data, size)
			return nil
		end,
		owned = function(data: Save.Data): boolean
			return Grow.owns(data, size)
		end,
	})
end

-- Your home's sizes as gifts (S5-03h3b, D-343): "Large Unit Gift" and "XL Unit Gift", bought for a
-- friend here, as Pet Simulator and Adopt Me let you gift Robux things. Brix's gift grows the
-- friend's home in their save, written before the buyer's purchase counts, so it's never lost
-- and never twice; a late one (the friend already that big) changes nothing. A friend gone before
-- it lands leaves a spare in the buyer's save, given on their next Gift press (Growing). The
-- server never prompts it for a friend already that big; the prompt isn't refused by the buyer's
-- own size, since a big home's owner gives the smaller sizes too.
for size, offer in Grow.Gifts do
	rows[offer] = table.freeze({
		title = `{size} Unit Gift`,
		switch = `sell{string.upper(string.sub(offer, 1, 1))}{string.sub(offer, 2)}`,
		forAnother = true,
		gift = function(_sale: Sale, data: Save.Data): string?
			Grow.grant(data, size)
			return nil
		end,
		away = function(_sale: Sale, data: Save.Data): string?
			data.spares[offer] = (data.spares[offer] or 0) + 1
			return nil
		end,
	})
end
Products.Rows = table.freeze(rows)

-- Every offer name, sorted: the values Recording's `offer` field takes.
Products.Names = (function(): { string }
	local names = {}
	for name in Products.Rows do
		table.insert(names, name)
	end
	table.sort(names)
	return table.freeze(names)
end)()

-- The live config's defaults for the switches: every offer on, by its switch key.
function Products.switches(): { [string]: boolean }
	local on = {}
	for _, row in Products.Rows do
		on[row.switch] = true
	end
	return on
end

-- The offers for Brix's Purchases, from `ids` (product id by offer name, as found on Roblox):
-- an offer with no id isn't sold, and a receipt for it is left for a server that knows it. Each
-- grant (or a gift's away, into the buyer's save) runs the row's own, then counts the purchase in
-- `bought`; a gift given into a friend's save is counted in Brix's records and the ledgers only.
function Products.offers(ids: { [string]: number }): { [string]: Offer }
	local offers: { [string]: Offer } = {}
	for name, row in Products.Rows do
		local product = ids[name]
		if product == nil then
			continue
		end
		local own = if row.gift then row.away else row.grant
		local counted = function(sale: Sale, data: Save.Data): string?
			local why = if own then own(sale, data) else nil
			if why ~= nil then
				return why
			end
			data.bought[name] = (data.bought[name] or 0) + 1
			return nil
		end
		offers[name] = {
			product = product,
			forAnother = row.forAnother,
			grant = if row.gift then nil else counted,
			gift = row.gift,
			away = if row.gift then counted else nil,
		}
	end
	return offers
end

-- Whether the live config `values` has the offer `name` switched on: an unknown name never is.
function Products.switchedOn(values: { [string]: any }, name: string): boolean -- any: config values
	local row = Products.Rows[name]
	return row ~= nil and values[row.switch] ~= false
end

return table.freeze(Products)
