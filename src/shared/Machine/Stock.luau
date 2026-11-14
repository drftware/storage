--!strict
--[[
	The machine's stock on a ride (S1-10c, GDD "The ride"): what stands in each bay's coil and its
	price in coins. The gate slams, the machine blinks awake, and as each row's tube flashes the
	coils behind the glass are full: batteries along the bottom row every ride, and above them
	three or four tools, a different lot each ride, so you can't count on bolt cutters being
	there. Dandy's World's elevator is its shop the same way: the ride between floors is when you
	spend.

	The server deals each ride's stock once (`deal`), keeps it, and writes it on the machine in
	every car carrying that ride as one attribute (`Attribute`, `encode`); each rider's screen
	reads it back (`decode`) to fill the coils and light the prices. The prices a buy charges are
	the server's own copy, never the attribute's (S1-10c2).

	Pure, so Lune checks it (tests/stock.spec.luau).
]]
local Specs = require("./Specs")

local Stock = {}

-- On a machine: its stock this ride, `encode`d. None while the car stands at a floor.
Stock.Attribute = "Stock"

-- What the bottom row's coils always hold.
Stock.Battery = "Battery"
-- Which row of bays holds the batteries (Specs.Bays' rows, 1 at the bottom): the short row.
Stock.BatteryRow = 1

--[[
	Prices in coins, all starting guesses (GDD: "a padlock for 6, say, or bolt cutters for 10").
	A team clears about 37 coins from floor 1's units and the gate pays each rider 10 more, so a
	player boards the second ride with about 15 to 25: enough for one good tool or a couple of
	cheap ones, never the lot, and the choice is the fun.
]]
Stock.Prices = {
	Battery = 3, -- a dying torch back to full: cheap, so nobody walks a floor dark for 3 coins
	BubbleWrap = 5, -- a tripwire to lay behind you: cheap insurance
	Padlock = 6, -- keeps a trapped keeper in for the floor (the GDD's guess)
	AirHorn = 7, -- one blast that draws the keepers in reach
	Saw = 8, -- the hole trap's tool, the loop's best move
	BoltCutters = 10, -- a padlocked unit, or a friend padlocked in one (the GDD's guess)
} :: { [string]: number }

-- The tools it can stock, in a fixed order so a seed always deals the same. Only tools that fit a
-- bay (the ladder doesn't); the marker joins when it's built (S4-06, the GDD sells it here).
Stock.Tools = { "Saw", "BoltCutters", "Padlock", "BubbleWrap", "AirHorn" } :: { string }

-- Batteries standing in each battery coil a ride: two coils of two, enough for a team of four to
-- each fill a dying torch once (a starting guess).
Stock.Batteries = 2
-- The share of rides with four tools, not three (the GDD: "three or four"). With three, one
-- tool coil stands empty.
Stock.FourShare = 0.5

-- The most a price or a count may be on the attribute (two LED digits; one coil).
Stock.MaxPrice = 99
Stock.MaxCount = 9

export type Bay = {
	key: string, -- "Battery", or a tool's key (Tools.Catalog)
	price: number, -- coins
	count: number, -- how many stand in the coil (0: sold out)
}
-- By bay (Specs.Bays' order, bottom row first): none where the coil stands empty.
export type Stock = { [number]: Bay }

-- Brix's Random contract (Brix.Random.new({ seed = n }) makes one), typed here so this stays
-- free of Roblox paths. any: the contract types its methods' self that way.
export type Random = {
	nextNumber: (self: any) -> number,
	nextInteger: (self: any, min: number, max: number) -> number,
}

local function shuffle<T>(list: { T }, random: Random)
	for i = #list, 2, -1 do
		local j = random:nextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
end

-- One ride's stock: batteries in every battery bay, then three or four different tools, each in
-- a tool bay of its own picked at random, so the same tool moves about from ride to ride.
function Stock.deal(random: Random): Stock
	local stock: Stock = {}
	local toolBays: { number } = {}
	for i, bay in Specs.Bays do
		if bay.Row == Stock.BatteryRow then
			stock[i] = {
				key = Stock.Battery,
				price = Stock.Prices[Stock.Battery],
				count = Stock.Batteries,
			}
		else
			table.insert(toolBays, i)
		end
	end
	local tools = table.clone(Stock.Tools)
	shuffle(tools, random)
	shuffle(toolBays, random)
	local n = if random:nextNumber() < Stock.FourShare then 4 else 3
	for k = 1, math.min(n, #tools, #toolBays) do
		local key = tools[k]
		stock[toolBays[k]] = { key = key, price = Stock.Prices[key], count = 1 }
	end
	return stock
end

-- The attribute's text: each bay in order, `key:price:count`, split by "/", empty where the coil
-- is ("Battery:3:2/Battery:3:2/Saw:8:1//Padlock:6:1/AirHorn:7:1").
function Stock.encode(stock: Stock): string
	local parts: { string } = table.create(#Specs.Bays, "")
	for i in Specs.Bays do
		local bay = stock[i]
		if bay then
			parts[i] = `{bay.key}:{bay.price}:{bay.count}`
		end
	end
	return table.concat(parts, "/")
end

local function whole(text: string, most: number): number?
	local n = tonumber(text)
	if n and n == math.floor(n) and n >= 0 and n <= most then
		return n
	end
	return nil
end

-- The stock from the attribute's text, or nil for anything that isn't one: a bay too many, a key
-- the machine doesn't sell, a price or count out of range. Empty bays stay empty.
function Stock.decode(value: unknown): Stock?
	if type(value) ~= "string" or #value > 256 then
		return nil
	end
	local stock: Stock = {}
	local i = 0
	for part in string.gmatch(value .. "/", "([^/]*)/") do
		i += 1
		if i > #Specs.Bays then
			return nil
		end
		if part ~= "" then
			local key, price, count = string.match(part, "^(%a+):(%d+):(%d+)$")
			if not (key and price and count and Stock.Prices[key]) then
				return nil
			end
			local p, c = whole(price, Stock.MaxPrice), whole(count, Stock.MaxCount)
			if not (p and c) then
				return nil
			end
			stock[i] = { key = key, price = p, count = c }
		end
	end
	return stock
end

-- A price as its window's two LED digits, right-aligned (" 3", "10").
function Stock.digits(price: number): (string, string)
	local text = string.format("%2d", math.clamp(math.floor(price), 0, Stock.MaxPrice))
	return string.sub(text, 1, 1), string.sub(text, 2, 2)
end

return Stock
