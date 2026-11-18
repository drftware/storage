--!strict
--[[
	Grow, pure (S5-03h2, D-341; the home doc's ideas 30 and 31): your home grown at the counter.
	The moment: back from a good climb you've saved up, and the counter sells you a bigger unit;
	your cash ticks down, the plan on its card opens out with the steel's roll, and your home is
	Medium. Bloxburg's and Adopt Me's house upgrades are bought this way, Animal Crossing's house
	loan too: a bigger home is the thing you save for.

	Everyone starts Small (`Sizes.Start`). Medium is sold for cash; Large and XL for Robux
	(S5-03h3a, D-342), as Adopt Me sells its bigger houses, so a cash sale refuses them as "robux".
	A size is never sold smaller than you have, never twice.

	The cash sale is the server's (Growing): `check` says why it can't happen, `buy` takes the
	price and writes the size in one step (so a save written at any moment holds both or neither),
	and `unbuy` undoes it whole when the save's write fails, keeping what else happened meanwhile.

	A Robux size is a developer product (`Robux`: its offer name in `Products`), sold through the
	game's purchases (Purchasing, Brix's Purchases): `owns` keeps its prompt from going up once the
	home is that size or bigger, and `grant` writes the size into the save Brix writes before the
	purchase counts as granted. A grant only ever grows the home, so a late receipt for a size you
	already have (two prompts bought at once) changes nothing and is still granted: the Robux are
	spent. The counter's screen (UnitsTab) shows `ladder`'s cards, each in `card`'s state, a Robux
	size only while it's on sale to you (`Shelf.robux`, Roblox's price).
]]
local Pay = require("../Pay")
local Sizes = require("./Sizes")

local Grow = {}

-- Why a sale can't happen: not a size, you're that size or bigger, it's a Robux size, short of
-- cash.
export type Refusal = "unknown" | "had" | "robux" | "cash"

-- A save as the sale reads it: its cash and its home's size.
export type Wallet = { cash: number, homeSize: string }

-- A size's card at the counter: the size you have (or smaller), the price to Buy, the price
-- dimmed (short), Roblox's price to Buy (a Robux size).
export type Card = "yours" | "buy" | "short" | "robux"

-- What the counter's screen is answered: your cash, your home's size, and each Robux size on sale
-- to you now at Roblox's price (0 while Roblox's isn't in yet); a size missing isn't on sale.
export type Shelf = { cash: number, size: string, robux: { [string]: number } }

-- One floor's pay at its gate, the first floor's: the yardstick the price is counted in, as the
-- furniture's are (D-333), so it moves with the climb's pay.
local GATE = Pay.forFloor(1)

-- The sizes sold for cash and their prices (a feel number; the owner's to set, `OWNER.md`).
-- Medium is 250 first-floor gates, 2,500 cash: ten neon moons, the dearest piece of furniture,
-- so it's the thing you save up for over a run of good climbs, not a buy on the way home.
Grow.Cash = table.freeze({
	Medium = GATE * 250,
} :: { [string]: number })

-- The sizes sold for Robux, each a developer product: its offer name in `Products` (the product's
-- Dashboard title, its live switch and its grant are there). Their prices are Roblox's, read each
-- time the counter opens; never in code.
Grow.Robux = table.freeze({
	Large = "homeLarge",
	XL = "homeXL",
} :: { [string]: string })

-- The remotes, in ReplicatedStorage.Remotes. `GrowHome` (client to server) carries a size's name;
-- `HomeGrown` (server to client) answers the asker the size asked for, their cash, their home's
-- size, and "" once it's theirs and written, else why not (a `Refusal`, "busy" while a sale's
-- write is out, "save" when the write failed, "notLoaded").
Grow.Remote = "GrowHome"
Grow.GrownRemote = "HomeGrown"
-- `HomeSizeShelf` (a RemoteFunction, nothing carried) answers the counter's screen a `Shelf`.
Grow.ShelfRemote = "HomeSizeShelf"
-- Asks per second a player may make, and a short burst: a tap and a nervous second tap.
Grow.Limit = table.freeze({ perSecond = 1, burst = 2 })
Grow.ShelfLimit = table.freeze({ perSecond = 2, burst = 4 })

-- The longest name the remote reads: a size's name is far shorter.
local NAME_MAX = 16

-- Size `name`'s cash price, or nil when it isn't sold for cash.
function Grow.price(name: string): number?
	return Grow.Cash[name]
end

-- Size `name`'s offer name, or nil when it isn't sold for Robux.
function Grow.offer(name: string): string?
	return Grow.Robux[name]
end

-- The size the offer named `offer` sells, or nil when it isn't a home size's offer.
function Grow.size(offer: string): string?
	for name, each in Grow.Robux do
		if each == offer then
			return name
		end
	end
	return nil
end

local function known(name: string): boolean
	return table.find(Sizes.Names, name) ~= nil
end

-- Whether a home of `data`'s size has size `name` already: it's that size or bigger. Such a size
-- is never prompted (Products' `owned`).
function Grow.owns(data: { homeSize: string }, name: string): boolean
	return known(name) and Sizes.rank(name) <= Sizes.rank(data.homeSize)
end

-- A Robux size's grant: the home grows to size `name` when it's smaller, never shrinks. True when
-- it grew; false when it had the size already (a late receipt), which changes nothing.
function Grow.grant(data: { homeSize: string }, name: string): boolean
	if not known(name) or Grow.owns(data, name) then
		return false
	end
	data.homeSize = name
	return true
end

-- Why `data` can't buy size `name`, or nil when it can.
function Grow.check(data: Wallet, name: string): Refusal?
	if not known(name) then
		return "unknown"
	end
	if Sizes.rank(name) <= Sizes.rank(data.homeSize) then
		return "had"
	end
	local price = Grow.Cash[name]
	if not price then
		return "robux"
	end
	if data.cash < price then
		return "cash"
	end
	return nil
end

-- Sells size `name` into `data`: the price off its cash and the size written, in one step. Nil
-- once sold, else why not (and `data` untouched); and the size it was, for `unbuy`.
function Grow.buy(data: Wallet, name: string): (Refusal?, string)
	local was = data.homeSize
	local refusal: Refusal? = Grow.check(data, name)
	if refusal ~= nil then
		return refusal, was
	end
	data.cash -= Grow.Cash[name]
	data.homeSize = name
	return nil, was
end

-- Undoes a sale of `name` whose save failed: the price back (relative, so cash made meanwhile is
-- kept) and the size back to `was`, unless the home has since grown past `name` (a Robux size
-- granted meanwhile), which it keeps.
function Grow.unbuy(data: Wallet, name: string, was: string)
	local price = Grow.Cash[name]
	if not price then
		return
	end
	data.cash += price
	if data.homeSize == name then
		data.homeSize = was
	end
end

-- The value the remote carried, as a size's name, or nil when it isn't one: never trusts the
-- client.
function Grow.ask(value: unknown): string?
	if type(value) ~= "string" or #value > NAME_MAX then
		return nil
	end
	return if known(value) then value else nil
end

-- The counter's cards for a home of size `have`: it, then each bigger size on sale: for cash, or
-- for Robux when `robux` (the shelf's) has it (a name not known reads as the smallest).
function Grow.ladder(have: string, robux: { [string]: number }?): { string }
	local from = Sizes.rank(have)
	local out = { Sizes.List[from].name }
	for i = from + 1, #Sizes.List do
		local name = Sizes.List[i].name
		if Grow.Cash[name] or (Grow.Robux[name] and robux and robux[name]) then
			table.insert(out, name)
		end
	end
	return out
end

-- Size `name`'s card for a home of size `have` with `cash`: yours at or under your size; a Robux
-- size's Buy; else Buy, or dimmed when you're short.
function Grow.card(name: string, have: string, cash: number): Card
	if Sizes.rank(name) <= Sizes.rank(have) then
		return "yours"
	end
	if Grow.Robux[name] then
		return "robux"
	end
	local price = Grow.Cash[name]
	return if price and cash >= price then "buy" else "short"
end

-- What the screen is answered for a save, with `robux` (a Robux size's price by name, 0 while
-- unknown) for the sizes on sale to that player now.
function Grow.shelf(data: Wallet, robux: { [string]: number }?): Shelf
	local prices: { [string]: number } = {}
	if robux then
		for name, price in robux do
			if Grow.Robux[name] then
				prices[name] = price
			end
		end
	end
	return { cash = data.cash, size = Sizes.of(data.homeSize).name, robux = prices }
end

-- The shelf the screen was answered, read safely (plain data typed at the one boundary): nil if
-- it isn't one. A size not known reads as the smallest.
function Grow.read(value: unknown): Shelf?
	if type(value) ~= "table" then
		return nil
	end
	local t = value :: { [string]: unknown }
	local cash, size = t.cash, t.size
	if type(cash) ~= "number" or cash ~= cash then
		return nil
	end
	local robux: { [string]: number } = {}
	local said = t.robux
	if type(said) == "table" then
		local prices = said :: { [unknown]: unknown }
		for name in Grow.Robux do
			local price = prices[name]
			if type(price) == "number" and price == price and price >= 0 and price < math.huge then
				robux[name] = math.floor(price)
			end
		end
	end
	return {
		cash = math.max(0, math.floor(cash)),
		size = Sizes.of(if type(size) == "string" then size else "").name,
		robux = robux,
	}
end

return table.freeze(Grow)
