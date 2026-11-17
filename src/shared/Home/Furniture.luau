--!strict
--[[
	Furniture (S5-03g4a, idea 19): the counter's furniture, sold for cash in a weekly stock. The
	moment: back from a climb with cash, you see this week's pieces at the counter, buy the camp
	bed, and it's in your job box waiting to be set out. Precedents: Animal Crossing's Nook's
	Cranny and Fortnite's item shop (a stock that changes, the same for everyone, back again
	soon), Lethal Company's ship store (furniture bought with what the run earned).

	The eight pieces are the home's art (D-323, D-324; `Specs.Pieces` names their parts), each a
	row here: its id (its art piece's name), its cash price, how it stands (on the floor, on a wall
	or from the ceiling) and how many of it one player may own. Prices are defaults for the owner
	(`OWNER.md`), counted in floors' pay (`Pay.forFloor`) so they move with the climb's pay.

	The stock is worked out from the date alone (`stock`): every server shows the same pieces all
	week, a new stock each Monday at midnight UTC, and never a random roll anyone pays for (the
	store's rules: you always see exactly what you buy). The pieces sit on a ring (`Ring`); a week
	shows `Shown` of them in a row round it, and each Monday the window turns `Slide` places on, so
	a piece out this week is always back next week, and any two weeks running show them all.

	The buy is the server's (Furnishing): `check` says why it can't happen, `buy` takes the price
	and adds the piece in one step (so a save written at any moment holds both or neither), and
	`unbuy` undoes it whole when the save's write fails.
]]
local Pay = require("../Pay")
local Specs = require("./Specs")

local Furniture = {}

-- How a piece stands in a home (Arrange sets it out by this, S5-03g4c).
export type Stands = "Floor" | "Wall" | "Ceiling"

-- One piece at the counter.
export type Piece = {
	id: string, -- its art piece's name in `Specs.Pieces`, and what a save counts it by
	parts: { string }, -- its MeshParts in the home's art
	price: number, -- cash, whole
	stands: Stands,
	cap: number, -- the most of it one player may own
}

-- Why a buy can't happen: not a piece, not in this week's stock, owned as many as you may, or
-- short of cash.
export type Refusal = "unknown" | "notStocked" | "capped" | "cash"

-- A save as the buy reads it: its cash and the furniture owned, by id.
export type Wallet = { cash: number, furniture: { [string]: number } }

-- One floor's pay at its gate, the first floor's: the yardstick every price is counted in.
local GATE = Pay.forFloor(1)

local function row(id: string, floors: number, stands: Stands, cap: number): Piece
	return table.freeze({
		id = id,
		parts = table.freeze(table.clone(Specs.Pieces[id] or {})),
		price = GATE * floors,
		stands = stands,
		cap = cap,
	})
end

-- The pieces, cheapest first (the order the counter lists them in). Prices in floors' pay: a
-- climb of a few floors, with its coins and a find or two sold, buys a crate or a blanket on the
-- way home; the camp bed is a good climb's pay; the neon moon is saved up for. Caps fill a home
-- as a player would (seats round a table, a bed or two, a few lights) without one buying the
-- counter bare. All defaults for the owner (`OWNER.md`).
Furniture.Pieces = table.freeze({
	row("MilkCrate", 3, "Floor", 6), -- a seat and a stand: the first thing anyone buys
	row("Blanket", 4, "Floor", 4), -- a floor cushion round the coffee table
	row("FoldingTable", 6, "Floor", 2), -- a table to gather round
	row("Pallet", 8, "Floor", 2), -- the coffee table
	row("SteelShelf", 10, "Floor", 3), -- four tiers of finds on show
	row("CampBed", 15, "Floor", 2), -- the sleepover: a good climb's pay
	row("StringLights", 18, "Ceiling", 4), -- warm bulbs across the ceiling
	row("NeonSign", 25, "Wall", 2), -- the glowing moon: saved up for
}) :: { Piece }

local byId: { [string]: Piece } = {}
for _, p in Furniture.Pieces do
	byId[p.id] = p
end

-- The ring the stock turns round, set by hand so every week mixes a cheap seat or cushion with
-- something to save for, and a light most weeks.
Furniture.Ring = table.freeze({
	"MilkCrate",
	"CampBed",
	"Blanket",
	"StringLights",
	"FoldingTable",
	"NeonSign",
	"Pallet",
	"SteelShelf",
}) :: { string }

-- Pieces in a week's stock: five of the eight, so the counter is worth a look each week and a
-- piece you want is never more than a week away.
Furniture.Shown = 5
-- Places the stock's window turns each Monday: three new pieces in, two stay. Between
-- `#Ring - Shown` and `Shown` keeps every piece back at least every other week (the spec checks).
Furniture.Slide = 3
-- Seconds after Monday's turn that last week's pieces still sell: a screen opened on Sunday night
-- is never refused at midnight for a piece it shows.
Furniture.Grace = 120

-- The remotes, in ReplicatedStorage.Remotes. `BuyFurniture` (client to server) carries a piece's
-- id. `FurnitureBought` (server to the buyer) answers every buy past the type check, once the
-- save is written: the id, the buyer's cash, how many of it they own, and "" or the refusal
-- ("save" when the write failed and the buy was undone, "busy" while a buy's write is out).
Furniture.Remote = "BuyFurniture"
Furniture.BoughtRemote = "FurnitureBought"
-- How often one player's buys are heard: a tap every so often, never a stream.
Furniture.Limit = table.freeze({ perSecond = 2, burst = 3 })

-- The longest id the remote takes: every piece's is far shorter.
local ID_MAX = 32

-- Seconds in a day and a week, and Monday 5 January 1970, 00:00 UTC: the first Monday after
-- the epoch (a Thursday), where week 0 starts.
local WEEK = 7 * 86400
local MONDAY0 = 4 * 86400

function Furniture.byId(id: string): Piece?
	return byId[id]
end

-- The week `time` (os.time, UTC seconds) falls in, counted from Monday 5 January 1970.
function Furniture.week(time: number): number
	return (math.floor(time) - MONDAY0) // WEEK
end

-- The stock in week `week`: `Shown` pieces in a row round the ring, cheapest first.
local function stockOf(week: number): { string }
	local n = #Furniture.Ring
	local start = (week * Furniture.Slide) % n
	local here: { [string]: boolean } = {}
	for i = 0, Furniture.Shown - 1 do
		here[Furniture.Ring[(start + i) % n + 1]] = true
	end
	local out: { string } = {}
	for _, p in Furniture.Pieces do
		if here[p.id] then
			table.insert(out, p.id)
		end
	end
	return out
end

-- This week's stock at `time`, cheapest first: the same on every server.
function Furniture.stock(time: number): { string }
	return stockOf(Furniture.week(time))
end

-- Whether piece `id` sells at `time`: in this week's stock, or last week's in the moment after
-- the turn (`Grace`).
function Furniture.stocked(id: string, time: number): boolean
	for _, s in Furniture.stock(time) do
		if s == id then
			return true
		end
	end
	if Furniture.week(time - Furniture.Grace) == Furniture.week(time) then
		return false
	end
	for _, s in Furniture.stock(time - Furniture.Grace) do
		if s == id then
			return true
		end
	end
	return false
end

-- Why `data` can't buy piece `id` at `time`, or nil when it can.
function Furniture.check(data: Wallet, id: string, time: number): Refusal?
	local piece = byId[id]
	if not piece then
		return "unknown"
	end
	if not Furniture.stocked(id, time) then
		return "notStocked"
	end
	if (data.furniture[id] or 0) >= piece.cap then
		return "capped"
	end
	if data.cash < piece.price then
		return "cash"
	end
	return nil
end

-- Buys piece `id` into `data` at `time`: the price off its cash and the piece on its count, in
-- one step. Nil once bought, else why not (and `data` untouched).
function Furniture.buy(data: Wallet, id: string, time: number): Refusal?
	local refusal: Refusal? = Furniture.check(data, id, time)
	if refusal ~= nil then
		return refusal
	end
	local piece = byId[id] :: Piece
	data.cash -= piece.price
	data.furniture[id] = (data.furniture[id] or 0) + 1
	return nil
end

-- Undoes one buy of `id` whose save failed: the price back, the piece off (never below none).
function Furniture.unbuy(data: Wallet, id: string)
	local piece = byId[id]
	local owned = data.furniture[id] or 0
	if not piece or owned < 1 then
		return
	end
	data.cash += piece.price
	if owned > 1 then
		data.furniture[id] = owned - 1
	else
		data.furniture[id] = nil
	end
end

-- The value the remote carried, as a piece's id, or nil when it isn't one: never trusts the
-- client.
function Furniture.ask(value: unknown): string?
	if type(value) ~= "string" or #value > ID_MAX then
		return nil
	end
	return if byId[value] then value else nil
end

return table.freeze(Furniture)
