--!strict
-- lune run tests/furniture.spec
-- The counter's furniture (S5-03g4a, idea 19): the eight pieces as rows, each one of the home's
-- art pieces at a whole cash price; this week's stock worked out from the date alone, so every
-- server shows the same pieces and every piece is back at least every other week; and the buy:
-- refused for a reason (not a piece, not this week's, owned as many as it may be, short of cash),
-- else the cash taken and the piece added in one step, and undone whole when its save fails.
local Furniture = require("../src/shared/Home/Furniture")
local Pay = require("../src/shared/Pay")
local Specs = require("../src/shared/Home/Specs")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

local DAY = 86400
local WEEK = 7 * DAY
-- Monday 16 November 2026, 00:00 UTC: a week's first second.
local MONDAY = 1794787200

-- The rows: the eight pieces, each an art piece, priced, standing somewhere, capped.
do
	ok(#Furniture.Pieces == 8, "eight pieces at the counter")
	local seen: { [string]: boolean } = {}
	local last = 0
	for _, p in Furniture.Pieces do
		ok(not seen[p.id], `{p.id} is listed once`)
		seen[p.id] = true
		local art = Specs.Pieces[p.id]
		ok(art ~= nil, `{p.id} is one of the home's art pieces`)
		ok(art ~= nil and #p.parts == #art, `{p.id}'s parts are its art piece's`)
		ok(
			p.price == math.floor(p.price) and p.price >= Pay.forFloor(1),
			`{p.id} costs a whole price, at least a floor's pay`
		)
		ok(p.price >= last, `{p.id} is listed cheapest first`)
		last = p.price
		ok(p.cap >= 1 and p.cap == math.floor(p.cap), `{p.id} may be owned at least once`)
		ok(Furniture.byId(p.id) == p, `{p.id} is found by its id`)
	end
	ok(Furniture.byId("Teddy") == nil, "a find isn't a piece")
	local ceiling = Furniture.byId("StringLights")
	local wall = Furniture.byId("NeonSign")
	local bed = Furniture.byId("CampBed")
	ok(ceiling ~= nil and ceiling.stands == "Ceiling", "the string lights hang from the ceiling")
	ok(wall ~= nil and wall.stands == "Wall", "the neon moon hangs on a wall")
	ok(bed ~= nil and bed.stands == "Floor", "the camp bed stands on the floor")
	ok(#Furniture.Ring == #Furniture.Pieces, "the rotation turns every piece")
	for _, id in Furniture.Ring do
		ok(Furniture.byId(id) ~= nil, `{id} in the rotation is a piece`)
	end
end

-- Weeks start Monday at midnight UTC.
do
	local w = Furniture.week(MONDAY)
	ok(Furniture.week(MONDAY + WEEK - 1) == w, "Sunday's last second is the same week")
	ok(Furniture.week(MONDAY - 1) == w - 1, "the second before Monday is the week before")
	ok(Furniture.week(MONDAY + WEEK) == w + 1, "the next Monday starts the next week")
end

-- This week's stock: from the date alone, the same all week, changing each Monday, every piece
-- back at least every other week.
do
	local stock = Furniture.stock(MONDAY + 3 * DAY)
	ok(#stock == Furniture.Shown, `{Furniture.Shown} pieces in stock`)
	local again = Furniture.stock(MONDAY + 3 * DAY)
	local sameAll = #again == #stock
	for i, id in stock do
		sameAll = sameAll and again[i] == id
	end
	ok(sameAll, "the same moment gives the same stock (every server alike)")
	local monday, sunday = Furniture.stock(MONDAY), Furniture.stock(MONDAY + WEEK - 1)
	local sameWeek = #monday == #sunday
	for i, id in monday do
		sameWeek = sameWeek and sunday[i] == id
	end
	ok(sameWeek, "Monday's stock is Sunday's")

	local absent: { [string]: number } = {} -- weeks in a row each piece has been missing
	local changes = 0
	local before: { [string]: boolean }? = nil
	for week = -60, 140 do
		local t = MONDAY + week * WEEK + 5 * 3600
		local now: { [string]: boolean } = {}
		local unique = true
		for _, id in Furniture.stock(t) do
			unique = unique and not now[id] and Furniture.byId(id) ~= nil
			now[id] = true
		end
		ok(unique, `week {week}: each stocked piece is a piece, once`)
		for _, p in Furniture.Pieces do
			absent[p.id] = if now[p.id] then 0 else (absent[p.id] or 0) + 1
			ok(absent[p.id] <= 1, `week {week}: {p.id} missed at most one week in a row`)
		end
		if before then
			local differs = false
			for id in now do
				differs = differs or not before[id]
			end
			changes += if differs then 1 else 0
		end
		before = now
	end
	ok(changes == 200, "the stock changes every Monday")
	ok(
		Furniture.stocked(stock[1], MONDAY + 3 * DAY),
		"a piece in this week's stock is for sale this week"
	)
end

-- The check and the buy.
type Wallet = { cash: number, furniture: { [string]: number } }
do
	local now = MONDAY + 2 * DAY
	local inStock = Furniture.stock(now)
	local here: { [string]: boolean } = {}
	for _, id in inStock do
		here[id] = true
	end
	local gone: string? = nil
	for _, p in Furniture.Pieces do
		if not here[p.id] then
			gone = p.id
			break
		end
	end
	local id = inStock[1]
	local piece = Furniture.byId(id)
	assert(piece and gone, "a stocked piece and one out of stock")

	local rich: Wallet = { cash = 10000, furniture = {} }
	ok(Furniture.check(rich, id, now) == nil, "a stocked piece with cash enough can be bought")
	ok(Furniture.check(rich, "Teddy", now) == "unknown", "a find isn't sold here")
	ok(Furniture.check(rich, gone, now) == "notStocked", "a piece out of this week's stock isn't")
	local poor: Wallet = { cash = piece.price - 1, furniture = {} }
	ok(Furniture.check(poor, id, now) == "cash", "a coin short is refused for cash")
	local full: Wallet = { cash = 10000, furniture = { [id] = piece.cap } }
	ok(Furniture.check(full, id, now) == "capped", "owning as many as you may is refused")

	-- The buy: one step, cash off and the piece on; a refusal leaves the save as it was.
	local data: Wallet = { cash = piece.price + 5, furniture = {} }
	ok(Furniture.buy(data, id, now) == nil, "a buy goes through")
	ok(data.cash == 5 and data.furniture[id] == 1, "the price is taken and the piece is yours")
	ok(Furniture.buy(data, id, now) == "cash", "a second can't be afforded")
	ok(data.cash == 5 and data.furniture[id] == 1, "a refused buy changes nothing")
	Furniture.unbuy(data, id)
	ok(
		data.cash == piece.price + 5 and data.furniture[id] == nil,
		"a buy whose save failed is undone whole: the cash back, the piece gone, no zero left"
	)
	Furniture.unbuy(data, id)
	ok(
		data.cash == piece.price + 5 and data.furniture[id] == nil,
		"undoing a piece you don't own changes nothing"
	)
	local capped: Wallet = { cash = 100000, furniture = {} }
	for _ = 1, piece.cap do
		Furniture.buy(capped, id, now)
	end
	ok(capped.furniture[id] == piece.cap, "bought up to the cap")
	ok(Furniture.buy(capped, id, now) == "capped", "and no further")
	ok(
		capped.cash == 100000 - piece.cap * piece.price,
		"each paid for exactly once, nothing random added"
	)

	-- The turn of the week forgives a screen opened last week for a moment, never longer.
	local lastWeek = Furniture.stock(MONDAY - 1)
	local nowStocked: { [string]: boolean } = {}
	for _, s in Furniture.stock(MONDAY) do
		nowStocked[s] = true
	end
	local leaving: string? = nil
	for _, s in lastWeek do
		if not nowStocked[s] then
			leaving = s
			break
		end
	end
	assert(leaving, "a piece leaves the stock at the turn")
	ok(
		Furniture.check(rich, leaving, MONDAY + Furniture.Grace - 1) == nil,
		"a piece from last week still sells in the moments after the turn"
	)
	ok(
		Furniture.check(rich, leaving, MONDAY + Furniture.Grace + 1) == "notStocked",
		"and not once the moment's past"
	)
end

-- What the remote carries, never trusted: a piece's id, or nothing.
do
	ok(Furniture.ask("CampBed") == "CampBed", "a piece's id is taken")
	ok(Furniture.ask(42) == nil, "a number isn't an id")
	ok(Furniture.ask(nil) == nil, "nothing isn't an id")
	ok(Furniture.ask({ "CampBed" }) == nil, "a table isn't an id")
	ok(Furniture.ask("Teddy") == nil, "a find isn't a piece")
	ok(Furniture.ask(string.rep("x", 1000)) == nil, "a long string is refused unread")
end

-- What the counter's screen is told and reads back (S5-03g4b): cash and owned pieces only.
do
	for _, p in Furniture.Pieces do
		ok(#p.name > 0 and #p.name <= 14, `{p.id} has a short name for its card`)
	end
	local shelf =
		Furniture.shelf({ cash = 298, furniture = { CampBed = 1, Teddy = 3, Pallet = 0 } })
	ok(shelf.cash == 298 and shelf.owned.CampBed == 1, "the shelf answers cash and owned")
	ok(shelf.owned.Teddy == nil and shelf.owned.Pallet == nil, "and only pieces, owned")
	local back = Furniture.read({ cash = 298.6, owned = { CampBed = 2, Teddy = 1, Pallet = "x" } })
	ok(back ~= nil and back.cash == 298 and back.owned.CampBed == 2, "a shelf reads back")
	ok(back ~= nil and back.owned.Teddy == nil and back.owned.Pallet == nil, "odd rows dropped")
	ok(
		Furniture.read(nil) == nil and Furniture.read({ cash = 0 / 0, owned = {} }) == nil,
		"junk isn't one"
	)
	ok(Furniture.read({ cash = "1", owned = {} }) == nil, "cash must be a number")
	ok(Furniture.card("CampBed", 150, 0) == "buy", "enough cash: Buy")
	ok(Furniture.card("CampBed", 149, 0) == "short", "a dollar short: dimmed")
	ok(Furniture.card("CampBed", 9999, 2) == "capped", "at its cap: Owned, whatever the cash")
	ok(Furniture.card("Teddy", 9999, 0) == "capped", "not a piece: never Buy")
end

print(`furniture: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
