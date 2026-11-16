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

	Prices are never here: Roblox's are read each time an offer is shown (Brix's Marketplace).
	Whatever a row grants, `offers` also counts the purchase in the save's `bought`, the same
	change as Brix's ledger, so a purchase counted once is a purchase granted once. Nothing random
	is ever a product (GDD: nothing random is sold, for Robux or for cash).
]]
local Save = require("./Save")

-- any: Brix's sale, as `Brix.PurchaseSale<Player>`; only `offer` is read here.
type Sale = any
type Grant = (sale: Sale, data: Save.Data) -> string?

export type Row = {
	title: string,
	switch: string,
	grant: Grant?,
	ownerOnly: boolean?,
	forAnother: boolean?,
}

-- The shape of each offer handed to `Brix.Purchases.new` (`Brix.PurchaseOffer<Save.Data, Player>`).
export type Offer = {
	product: number,
	grant: Grant,
	forAnother: boolean?,
}

local Products = {}

-- Every product, by offer name. Step 3's products (Free Everyone, then wrap colours) join as
-- S3-03 and S3-04 put them on sale.
Products.Rows = table.freeze({
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
	-- The owner's test: a real purchase on the published place that grants nothing but its count,
	-- for Brix's ENG-23e phone test (a forced save failure, a server hop), so the test never
	-- touches cash or anything a player plays for.
	testPurchase = table.freeze({
		title = "Test purchase",
		switch = "sellTestPurchase",
		ownerOnly = true,
	}),
} :: { [string]: Row })

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
-- grant runs the row's own, then counts the purchase in `bought`.
function Products.offers(ids: { [string]: number }): { [string]: Offer }
	local offers: { [string]: Offer } = {}
	for name, row in Products.Rows do
		local product = ids[name]
		if product == nil then
			continue
		end
		local own = row.grant
		offers[name] = {
			product = product,
			forAnother = row.forAnother,
			grant = function(sale: Sale, data: Save.Data): string?
				local why = if own then own(sale, data) else nil
				if why ~= nil then
					return why
				end
				data.bought[name] = (data.bought[name] or 0) + 1
				return nil
			end,
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
