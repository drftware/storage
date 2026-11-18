--!strict
-- lune run tests/homecardsale.spec
-- The name card's styles sold at the counter (S5-03g3d, Home.CardSale, D-360): the painted board
-- and the chalk for cash, the neon for Robux; a buy takes the price and adds the style in one
-- step and undoes whole; owned for good; the paint tab's lock and the server's pick read the
-- save's styles, so a bought style picks and an unbought one never does.
local CardSale = require("../src/shared/Home/CardSale")
local Looks = require("../src/shared/Home/Looks")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print(`FAIL: {what}`)
	end
end

-- What's sold, and how.
ok(#CardSale.Sold == 3, "three styles at the counter")
ok(CardSale.Sold[1] == "Painted" and CardSale.Sold[3] == "Neon", "cash ones first, the neon last")
ok(CardSale.price("Painted") ~= nil and CardSale.price("Chalk") ~= nil, "cash styles have prices")
ok(
	(CardSale.price("Painted") :: number) < (CardSale.price("Chalk") :: number),
	"the chalk costs more"
)
ok(CardSale.price("Neon") == nil and CardSale.price("Stencil") == nil, "no cash price for the rest")
do -- every style at the counter has its card's name (S5-03g3d2), short enough for a phone card
	local named = true
	for _, id in CardSale.Sold do
		local name = CardSale.Names[id]
		named = named and name ~= nil and #name > 0 and #name <= 14
	end
	ok(named, "every style sold has a short name for its card")
end
ok(CardSale.offer("Neon") == "neonCard" and CardSale.offer("Chalk") == nil, "the neon's offer")
ok(
	CardSale.styleFor("neonCard") == "Neon" and CardSale.styleFor("cutFree") == nil,
	"offer to style"
)
ok(CardSale.ask("Chalk") == "Chalk" and CardSale.ask("Neon") == "Neon", "sold styles are asks")
ok(CardSale.ask("Stencil") == nil and CardSale.ask(5) == nil, "the stencil and junk aren't")
ok(CardSale.ask(string.rep("a", 40)) == nil, "a long id isn't")

-- A cash buy, short, owned and undone.
local price = CardSale.price("Painted") :: number
local data = { cash = price - 1, cards = {} }
ok(CardSale.buy(data, "Painted", 100) == "cash" and data.cash == price - 1, "short: nothing taken")
data.cash = price + 5
ok(CardSale.buy(data, "Painted", 100) == nil, "bought")
ok(data.cash == 5 and data.cards.Painted == 100, "the price off and the style on, together")
ok(CardSale.buy(data, "Painted", 101) == "had" and data.cash == 5, "never bought twice")
ok(CardSale.buy(data, "Neon", 101) == "unknown", "the neon isn't sold for cash")
ok(CardSale.buy(data, "Stencil", 101) == "unknown", "the stencil isn't sold")
CardSale.unbuy(data, "Painted")
ok(data.cash == price + 5 and data.cards.Painted == nil, "a failed save's buy undone whole")
CardSale.unbuy(data, "Painted")
ok(data.cash == price + 5, "undoing twice gives nothing back")

-- The Robux grant: owned for good, stamped once.
CardSale.own(data, "Neon", 200)
CardSale.own(data, "Neon", 300)
ok(data.cards.Neon == 200, "the neon owned, stamped when first owned")
ok(
	CardSale.owns(data.cards, "Neon") and CardSale.owns({}, "Stencil"),
	"owned, and the stencil's free"
)
ok(not CardSale.owns({}, "Chalk") and not CardSale.owns({ Gone = 1 }, "Gone"), "not owned")

-- The counter's card states.
ok(CardSale.card("Chalk", 0, true) == "owned", "owned")
ok(CardSale.card("Chalk", 0, false) == "short", "short of cash: dimmed")
ok(CardSale.card("Chalk", 10 ^ 6, false) == "buy", "buy")
ok(CardSale.card("Neon", 0, false) == "buy", "the neon's price is Robux: never short")

-- The attribute, there and back.
ok(CardSale.encode({ Neon = 1, Painted = 2, Stencil = 3, Gone = 4 }) == "Painted,Neon", "encoded")
local back = CardSale.decode("Painted,Neon,Gone,,")
ok(back.Painted ~= nil and back.Neon ~= nil and back.Gone == nil, "decoded, unknown dropped")
ok(next(CardSale.decode(7)) == nil, "junk decodes to none")

-- The shelf read safely.
local shelf =
	CardSale.read({ cash = 12.7, owned = { Chalk = true, Gone = true }, robux = { Neon = 99 } })
ok(
	shelf ~= nil and shelf.cash == 12 and shelf.owned.Chalk and shelf.owned.Gone == nil,
	"shelf read"
)
ok(shelf ~= nil and shelf.robux.Neon == 99, "the neon's price read")
ok(CardSale.read({ cash = "x", owned = {}, robux = {} }) == nil, "a junk shelf refused")

-- The lock and the pick read what's owned.
local start = Looks.start()
ok(Looks.cardLock("Chalk", { Chalk = 1 }) == nil, "a bought chalk has no mark")
ok(Looks.cardLock("Neon", { Chalk = 1 }) == "Robux", "the neon still marked")
ok(Looks.pick(start, "card", "Chalk", { Chalk = 1 }) ~= nil, "a bought style picks")
ok(Looks.pick(start, "card", "Neon", { Chalk = 1 }) == nil, "an unbought one doesn't")
ok(Looks.pick(start, "card", "Chalk") == nil, "no styles given: only the stencil")

if failures > 0 then
	error(`{failures} of {checks} checks failed`)
end
print(`homecardsale: {checks} checks passed`)
