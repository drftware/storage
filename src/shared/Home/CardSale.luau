--!strict
--[[
	CardSale (S5-03g3d, D-360): the name card's other styles sold at the counter, beside the
	furniture. The moment: you see a friend's neon card glowing over their door, walk to the
	counter, buy one, and the next time you open Arrange its chip is yours and picks with the plate
	swinging down. Precedents: Animal Crossing's Nook's Cranny selling wallpaper beside the
	furniture, Bloxburg's and Adopt Me's house signs, Roblox games' Robux cosmetics bought once and
	kept (this game's own wrap colours, S3-04a).

	The styles are `Specs.Cards` (D-322): the stencil is every home's (Starter), the painted board
	and the chalk slate sell for cash, the neon for Robux. Cash prices are counted in floors' pay
	(`Pay.forFloor`), as the furniture's are, and are defaults for the owner (`OWNER.md`). The
	neon's price is Roblox's, read each time it's shown (the developer product "Neon Name Card").

	A save keeps the styles you own in `cards`, by style id, stamped with when you first owned it:
	once owned, owned for good. `buy` takes the price and adds the style in one step (so a save
	written at any moment holds both or neither), `unbuy` undoes it whole when the save's write
	fails, `own` is the Robux grant. `Looks.cardLock` reads `cards`, so the paint tab's mark goes
	and the server's pick takes it the moment it's saved. Nothing random is ever sold.
]]
local Pay = require("../Pay")
local Specs = require("./Specs")

local CardSale = {}

-- Why a buy can't happen: not a style the counter sells for cash, already yours, short of cash.
export type Refusal = "unknown" | "had" | "cash"
-- A save as the buy reads it: its cash and the styles it owns, by id (when first owned).
export type Wallet = { cash: number, cards: { [string]: number } }
-- What the counter's screen is answered: your cash, the styles you own, and each Robux style's
-- price on Roblox now (0 while it isn't in, missing when it's off sale).
export type Shelf = { cash: number, owned: { [string]: boolean }, robux: { [string]: number } }
-- A style's card at the counter: its price to Buy, dimmed (short of cash), or Owned.
export type Card = "buy" | "short" | "owned"

-- One floor's pay at its gate, the first floor's: the yardstick every cash price is counted in.
local GATE = Pay.forFloor(1)

-- Cash prices in floors' pay. The painted board is a good climb's pay, near the camp bed; the
-- chalk slate, framed in oak, is saved up for, as the neon moon is. Defaults for the owner.
CardSale.Floors = table.freeze({
	Painted = 12,
	Chalk = 20,
}) :: { [string]: number }

-- The Robux styles' offers (`Products`), by style id: "Neon Name Card" on the Creator Dashboard.
CardSale.Offers = table.freeze({
	Neon = "neonCard",
}) :: { [string]: string }

-- The remotes, in ReplicatedStorage.Remotes. `BuyCard` (client to server) carries a style's id;
-- `CardBought` (server to the buyer) answers once the save is written or the prompt is closed:
-- the id, the buyer's cash, and "" or why not (a `Refusal`, "save" when the write failed and the
-- buy was undone, "busy" while one is out, "closed" for a Robux prompt shut unbought, "off" when
-- it isn't on sale). `CardShelf` (a RemoteFunction, nothing carried) answers a `Shelf`.
CardSale.Remote = "BuyCard"
CardSale.BoughtRemote = "CardBought"
CardSale.ShelfRemote = "CardShelf"
-- The styles a player owns, on their Player for every screen of theirs (the paint tab's marks):
-- ids joined by commas, the Starter ones left out.
CardSale.Attribute = "CardStyles"
-- How often one player's buys and shelf asks are heard: a tap every so often, an open or two.
CardSale.Limit = table.freeze({ perSecond = 2, burst = 3 })
CardSale.ShelfLimit = table.freeze({ perSecond = 2, burst = 4 })

local ID_MAX = 32

local function styleOf(id: string): Specs.CardStyle?
	for _, style in Specs.Cards do
		if style.Id == id then
			return style
		end
	end
	return nil
end

-- The styles the counter sells, in the plate's order: cash ones then the Robux one.
CardSale.Sold = table.freeze((function(): { string }
	local out = {}
	for _, style in Specs.Cards do
		if style.Sold == "Cash" and CardSale.Floors[style.Id] then
			table.insert(out, style.Id)
		end
	end
	for _, style in Specs.Cards do
		if style.Sold == "Robux" and CardSale.Offers[style.Id] then
			table.insert(out, style.Id)
		end
	end
	return out
end)()) :: { string }

-- Style `id`'s cash price, or nil for one not sold for cash.
function CardSale.price(id: string): number?
	local floors = CardSale.Floors[id]
	local style = styleOf(id)
	if floors and style and style.Sold == "Cash" then
		return GATE * floors
	end
	return nil
end

-- The offer style `id` sells under for Robux, or nil.
function CardSale.offer(id: string): string?
	local style = styleOf(id)
	return if style and style.Sold == "Robux" then CardSale.Offers[id] else nil
end

-- The style a Robux offer sells, or nil for any other offer.
function CardSale.styleFor(offer: string): string?
	for id, o in CardSale.Offers do
		if o == offer then
			return id
		end
	end
	return nil
end

-- Whether `cards` (a save's) has style `id`: a Starter style is everyone's.
function CardSale.owns(cards: { [string]: number }, id: string): boolean
	local style = styleOf(id)
	if not style then
		return false
	end
	return style.Sold == "Starter" or cards[id] ~= nil
end

-- Why `data` can't buy style `id` for cash, or nil when it can.
function CardSale.check(data: Wallet, id: string): Refusal?
	local price = CardSale.price(id)
	if not price then
		return "unknown"
	end
	if CardSale.owns(data.cards, id) then
		return "had"
	end
	if data.cash < price then
		return "cash"
	end
	return nil
end

-- Buys cash style `id` into `data` at `now`: the price off and the style on, in one step. Nil
-- once bought, else why not (and `data` untouched).
function CardSale.buy(data: Wallet, id: string, now: number): Refusal?
	local refusal: Refusal? = CardSale.check(data, id)
	if refusal ~= nil then
		return refusal
	end
	data.cash -= CardSale.price(id) :: number
	data.cards[id] = math.floor(now)
	return nil
end

-- Undoes a buy of `id` whose save failed: the price back, the style off.
function CardSale.unbuy(data: Wallet, id: string)
	local price = CardSale.price(id)
	if price and data.cards[id] ~= nil then
		data.cash += price
		data.cards[id] = nil
	end
end

-- The Robux grant: style `id` owned for good, stamped at `now` (kept as it was if owned already).
function CardSale.own(data: Wallet, id: string, now: number)
	if styleOf(id) and data.cards[id] == nil then
		data.cards[id] = math.floor(now)
	end
end

-- A card's state for style `id` with `cash`, and whether it's `owned`.
function CardSale.card(id: string, cash: number, owned: boolean): Card
	if owned then
		return "owned"
	end
	local price = CardSale.price(id)
	return if price and cash < price then "short" else "buy"
end

-- The styles a save owns, as the Player's attribute carries them ("Painted,Neon"), known ones
-- only, in the plate's order.
function CardSale.encode(cards: { [string]: number }): string
	local out = {}
	for _, style in Specs.Cards do
		if style.Sold ~= "Starter" and cards[style.Id] ~= nil then
			table.insert(out, style.Id)
		end
	end
	return table.concat(out, ",")
end

-- The attribute read back as owned styles (each stamped 0): anything odd or unknown dropped.
function CardSale.decode(text: unknown): { [string]: number }
	local out: { [string]: number } = {}
	if type(text) ~= "string" or #text > 256 then
		return out
	end
	for id in string.gmatch(text, "[^,]+") do
		if styleOf(id) then
			out[id] = 0
		end
	end
	return out
end

-- The shelf the screen was answered, read safely (plain data typed at the one boundary).
function CardSale.read(value: unknown): Shelf?
	if type(value) ~= "table" then
		return nil
	end
	local t = value :: { [string]: unknown }
	local cash, owned, robux = t.cash, t.owned, t.robux
	if
		type(cash) ~= "number"
		or cash ~= cash
		or type(owned) ~= "table"
		or type(robux) ~= "table"
	then
		return nil
	end
	local shelf: Shelf = { cash = math.max(0, math.floor(cash)), owned = {}, robux = {} }
	for id, yes in owned :: { [unknown]: unknown } do
		if type(id) == "string" and styleOf(id) and yes == true then
			shelf.owned[id] = true
		end
	end
	for id, price in robux :: { [unknown]: unknown } do
		if
			type(id) == "string"
			and CardSale.Offers[id]
			and type(price) == "number"
			and price == price
		then
			shelf.robux[id] = math.max(0, math.floor(price))
		end
	end
	return shelf
end

-- The value the remote carried, as a style the counter sells, or nil: never trusts the client.
function CardSale.ask(value: unknown): string?
	if type(value) ~= "string" or #value > ID_MAX then
		return nil
	end
	for _, id in CardSale.Sold do
		if id == value then
			return id
		end
	end
	return nil
end

return table.freeze(CardSale)
