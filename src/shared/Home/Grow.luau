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

	Large and XL are also gifts (S5-03h3b, D-343), as Pet Simulator and Adopt Me let you gift Robux
	things: a product each (`Gifts`), bought for a friend here through Brix's gift, which grows
	their home in their save and writes it before the buyer's purchase counts. One whose friend left
	before it landed is a spare in the buyer's save (`spares`), given on their next Gift press:
	`give` grows the friend's home first, `ungive` undoes it when the friend's save isn't written,
	and only once it is does `spend` take the buyer's spare, so a gift is never lost and never given
	to a home that big. The counter's shelf carries the gifts on sale, the spares held and the
	friends here with their sizes (`friends`); `giftable` says whether a size's Gift shows.
]]
local Pay = require("../Pay")
local Sizes = require("./Sizes")

local Grow = {}

-- Why a sale can't happen: not a size, you're that size or bigger, it's a Robux size, short of
-- cash.
-- For a gift's spare: "none" when the buyer holds no spare of that size.
export type Refusal = "unknown" | "had" | "robux" | "cash" | "none"

-- A save as the sale reads it: its cash and its home's size (and its spares, for the gifts).
export type Wallet = { cash: number, homeSize: string, spares: { [string]: number }? }

-- Another player here, as the counter's Gift lists them: their UserId, the name they show, their
-- home's size.
export type Friend = { id: number, name: string, size: string }

-- A size's card at the counter: the size you have (or smaller), the price to Buy, the price
-- dimmed (short), Roblox's price to Buy (a Robux size).
export type Card = "yours" | "buy" | "short" | "robux"

-- What the counter's screen is answered: your cash, your home's size, and each Robux size on sale
-- to you now at Roblox's price (0 while Roblox's isn't in yet); a size missing isn't on sale. Then
-- the gifts the same way, the gift spares you hold by size, and the friends here.
export type Shelf = {
	cash: number,
	size: string,
	robux: { [string]: number },
	gifts: { [string]: number },
	spares: { [string]: number },
	friends: { Friend },
}

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

-- The sizes given to a friend for Robux, each a developer product bought for another player.
Grow.Gifts = table.freeze({
	Large = "giftLarge",
	XL = "giftXL",
} :: { [string]: string })

-- The most friends the counter's Gift lists: a lobby's few, each a row a thumb can hit on a phone.
Grow.FriendsMost = 6
-- The longest name a friend's row reads (Roblox's display names are at most 20).
local FRIEND_NAME_MAX = 32

-- The remotes, in ReplicatedStorage.Remotes. `GrowHome` (client to server) carries a size's name;
-- `HomeGrown` (server to client) answers the asker the size asked for, their cash, their home's
-- size, and "" once it's theirs and written, else why not (a `Refusal`, "busy" while a sale's
-- write is out, "save" when the write failed, "notLoaded"). A gift: `GrowHome` carries the
-- friend's UserId after the size, and `HomeGrown` answers it last ("gone" when the friend left
-- before it landed: it waits as a spare).
Grow.Remote = "GrowHome"
Grow.GrownRemote = "HomeGrown"
-- `HomeGifted` (server to client) tells a friend their home just grew from a gift: the size, the
-- giver's UserId and the name they show.
Grow.GiftedRemote = "HomeGifted"
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

-- Size `name`'s gift offer, or nil when it isn't given as a gift.
function Grow.giftOffer(name: string): string?
	return Grow.Gifts[name]
end

-- The size the gift offer named `offer` gives, or nil when it isn't a gift.
function Grow.giftSize(offer: string): string?
	for name, each in Grow.Gifts do
		if each == offer then
			return name
		end
	end
	return nil
end

-- How many gifts of size `name` the save holds as spares (paid for, its friend gone).
function Grow.spares(data: { spares: { [string]: number }? }, name: string): number
	local offer = Grow.Gifts[name]
	local held = if offer and data.spares then data.spares[offer] else nil
	return if held and held > 0 then held else 0
end

-- The value the remote carried as a friend's UserId, or nil when it isn't one: never trusted. A
-- whole number other than 0; negative too, as Studio's test players' are (Player2 is -2), which
-- in a live game simply matches nobody here.
function Grow.friendId(value: unknown): number?
	if type(value) ~= "number" or value ~= value or value == 0 or math.abs(value) >= 2 ^ 53 then
		return nil
	end
	return if value == math.floor(value) then value else nil
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

-- Gives one of `buyer`'s spare gifts of size `name` to `friend`: the friend's home grows now, the
-- spare stays until the friend's save is written (`spend`), or `ungive` when it isn't. Nil once
-- given, else why not (both untouched); and the size the friend's home was.
function Grow.give(
	buyer: { spares: { [string]: number }? },
	friend: { homeSize: string },
	name: string
): (Refusal?, string)
	local was = friend.homeSize
	if Grow.Gifts[name] == nil then
		return "unknown", was
	end
	if Grow.owns(friend, name) then
		return "had", was
	end
	if Grow.spares(buyer, name) < 1 then
		return "none", was
	end
	friend.homeSize = name
	return nil, was
end

-- Undoes a gift of `name` to `friend` whose save wasn't written: back to `was`, unless the home
-- has since grown past it.
function Grow.ungive(friend: { homeSize: string }, name: string, was: string)
	if friend.homeSize == name then
		friend.homeSize = was
	end
end

-- Takes one spare gift of size `name` from `buyer`, once the friend's save holds it.
function Grow.spend(buyer: { spares: { [string]: number }? }, name: string)
	local offer = Grow.Gifts[name]
	local spares = buyer.spares
	if offer and spares and Grow.spares(buyer, name) > 0 then
		spares[offer] = Grow.spares(buyer, name) - 1
		if spares[offer] == 0 then
			spares[offer] = nil
		end
	end
end

-- The friends the counter's Gift lists from the players `here`: everyone but `me`, by name, a few.
function Grow.friends(here: { Friend }, me: number): { Friend }
	local out: { Friend } = {}
	for _, each in here do
		if each.id ~= me then
			table.insert(out, each)
		end
	end
	table.sort(out, function(a: Friend, b: Friend): boolean
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.id < b.id
	end)
	while #out > Grow.FriendsMost do
		table.remove(out)
	end
	return out
end

-- Whether size `name`'s Gift shows on `shelf`: its gift on sale (or a spare held) and someone
-- here whose home is smaller.
function Grow.giftable(shelf: Shelf, name: string): boolean
	if Grow.Gifts[name] == nil or (shelf.gifts[name] == nil and (shelf.spares[name] or 0) < 1) then
		return false
	end
	for _, friend in shelf.friends do
		if not Grow.owns({ homeSize = friend.size }, name) then
			return true
		end
	end
	return false
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
-- for Robux when `robux` (the shelf's) has it (a name not known reads as the smallest). A size in
-- `gifts` (giftable now) is dealt too, in size order, even one smaller than yours.
function Grow.ladder(
	have: string,
	robux: { [string]: number }?,
	gifts: { [string]: boolean }?
): { string }
	local from = Sizes.rank(have)
	local out = {}
	for i, size in Sizes.List do
		local name = size.name
		local gift = gifts ~= nil and gifts[name] == true and Grow.Gifts[name] ~= nil
		if
			i == from
			or (i < from and gift)
			or (
				i > from
				and (Grow.Cash[name] or (Grow.Robux[name] and robux and robux[name]) or gift)
			)
		then
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
-- unknown) for the sizes on sale to that player now, `gifts` the same for the gifts, and the
-- `friends` here (as `friends` lists them).
function Grow.shelf(
	data: Wallet,
	robux: { [string]: number }?,
	gifts: { [string]: number }?,
	friends: { Friend }?
): Shelf
	local none: { [string]: number } = {}
	local prices: { [string]: number } = {}
	for name, price in robux or none do
		if Grow.Robux[name] then
			prices[name] = price
		end
	end
	local giftPrices: { [string]: number } = {}
	for name, price in gifts or none do
		if Grow.Gifts[name] then
			giftPrices[name] = price
		end
	end
	local spares: { [string]: number } = {}
	for name in Grow.Gifts do
		local held = Grow.spares(data, name)
		if held > 0 then
			spares[name] = held
		end
	end
	return {
		cash = data.cash,
		size = Sizes.of(data.homeSize).name,
		robux = prices,
		gifts = giftPrices,
		spares = spares,
		friends = friends or {},
	}
end

-- Prices by size from `said` (the shelf's robux or gifts), only for the sizes in `sizes`.
local function readPrices(said: unknown, sizes: { [string]: string }): { [string]: number }
	local out: { [string]: number } = {}
	if type(said) ~= "table" then
		return out
	end
	local prices = said :: { [unknown]: unknown }
	for name in sizes do
		local price = prices[name]
		if type(price) == "number" and price == price and price >= 0 and price < math.huge then
			out[name] = math.floor(price)
		end
	end
	return out
end

-- The friends the shelf carried, read safely: a whole UserId each, a name cut short, a size.
local function readFriends(said: unknown): { Friend }
	local out: { Friend } = {}
	if type(said) ~= "table" then
		return out
	end
	for _, each in said :: { unknown } do
		if #out >= Grow.FriendsMost then
			break
		end
		if type(each) ~= "table" then
			continue
		end
		local t = each :: { [string]: unknown }
		local id = Grow.friendId(t.id)
		if id == nil or (t.name ~= nil and type(t.name) ~= "string") then
			continue
		end
		local name = if type(t.name) == "string" then string.sub(t.name, 1, FRIEND_NAME_MAX) else ""
		local size = if type(t.size) == "string" then t.size else ""
		table.insert(out, { id = id, name = name, size = Sizes.of(size).name })
	end
	return out
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
	local spares: { [string]: number } = {}
	for name, count in readPrices(t.spares, Grow.Gifts) do
		if count > 0 then
			spares[name] = count
		end
	end
	return {
		cash = math.max(0, math.floor(cash)),
		size = Sizes.of(if type(size) == "string" then size else "").name,
		robux = readPrices(t.robux, Grow.Robux),
		gifts = readPrices(t.gifts, Grow.Gifts),
		spares = spares,
		friends = readFriends(t.friends),
	}
end

return table.freeze(Grow)
