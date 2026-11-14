--!strict
-- lune run tests/buy.spec
-- The buy at the car's machine (S1-10c2): a row's buttons work only once its prices are lit and
-- never on the lobby ride or as the power cuts; a press sells only from a stocked coil to someone
-- who can pay; mashing is rate-limited; the buyer's attribute round-trips; and a screen tells a
-- sale (counts lowered) from a new stock (refill).
local roblox = require("@lune/roblox")

local Buy = require("../src/shared/Machine/Buy")
local Ride = require("../src/shared/Elevator/Ride")
local Specs = require("../src/shared/Machine/Specs")
local Stock = require("../src/shared/Machine/Stock")
local Wake = require("../src/shared/Machine/Wake")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end

-- open: from a row's prices settling to a beat before the cut
local FROM = 2
for row = 1, 3 do
	local lit = Wake.catches(row) + Buy.Settle
	ok(not Buy.open(row, lit - 0.01, FROM), `row {row} shut before its prices settle`)
	ok(Buy.open(row, lit + 0.01, FROM), `row {row} open once its prices show`)
	ok(
		Buy.open(row, Ride.opens() - Buy.Last - 0.01, FROM),
		`row {row} open just before the last call`
	)
	ok(not Buy.open(row, Ride.opens() - Buy.Last, FROM), `row {row} shut at the last call`)
	ok(not Buy.open(row, Ride.opens() + 1, FROM), `row {row} shut after the cut`)
	ok(not Buy.open(row, 8, Ride.Lobby), `row {row} shut on the lobby ride`)
end
ok(not Buy.open(4, 8, FROM), "no fourth row")
ok(not Buy.open(0, 8, FROM), "no row 0")
-- the window is long enough to shop: most of the ride
ok(Ride.opens() - Buy.Last - (Wake.catches(3) + Buy.Settle) > 12, "over 12 s to shop")

-- check
local saw = { key = "Saw", price = 8, count = 1 }
ok(Buy.check(saw, 8) == "ok", "exactly enough buys")
ok(Buy.check(saw, 20) == "ok", "more than enough buys")
ok(Buy.check(saw, 7) == "poor", "a coin short doesn't")
ok(Buy.check(saw, nil) == "poor", "no count (off a climb) doesn't")
ok(Buy.check(nil, 50) == "empty", "an empty coil sells nothing")
ok(Buy.check({ key = "Saw", price = 8, count = 0 }, 50) == "empty", "a sold-out coil neither")

-- tile: how a bay shows on the menu, and what a pick on it does
local cell = { key = "Battery", price = 3, count = 2 }
ok(Buy.tile(saw, false, 50, true) == "dark", "a row not lit yet is dark")
ok(Buy.tile(nil, true, 50, true) == "empty", "an empty coil shows empty")
ok(Buy.tile({ key = "Saw", price = 8, count = 0 }, true, 50, true) == "empty", "a sold-out one too")
ok(Buy.tile(cell, true, 50, false) == "full", "a battery for a full torch is left for a friend")
ok(Buy.tile(cell, true, 50, true) == "ok", "and sells to a dying one")
ok(Buy.tile(saw, true, 7, false) == "poor", "a coin short is poor, whatever the torch")
ok(Buy.tile(saw, true, 8, false) == "ok", "exactly enough buys a tool with a full torch")
ok(Buy.tile(cell, true, 1, false) == "full", "a full torch outranks too few coins")
-- the menu reaches from the car's back half, past the friends in front of the machine
ok(Buy.Reach >= 7, "reach covers a crowd")
local spot = Buy.point(roblox.CFrame.new(0, 0, 0))
ok(spot.Z < Specs.Glass.Centre[3] and spot.Y > 3, "the button hangs on the glass's face")

-- allow: a burst of two, then one a gap
local may, left = Buy.allow(nil, 0, 0)
ok(may and left == Buy.Burst - 1, "the first press goes")
may, left = Buy.allow(0, left, 0.05)
ok(may and left == 0, "a second at once goes")
may = Buy.allow(0.05, 0, 0.1)
ok(not may, "a third at once doesn't")
may = Buy.allow(0.05, 0, 0.05 + Buy.Gap)
ok(may, "one goes after a gap")

-- the attribute
local b, s, u = Buy.decode(Buy.encode(3, 12, 4567))
ok(b == 3 and s == 12 and u == 4567, "the buy round-trips")
ok(Buy.decode("7|1|1") == nil, "a seventh bay is refused")
ok(Buy.decode("0|1|1") == nil, "bay 0 is refused")
ok(Buy.decode("x|1|1") == nil, "nonsense is refused")
ok(Buy.decode(nil) == nil, "nothing is refused")
ok(Buy.decode(string.rep("1", 80)) == nil, "something long is refused")

-- sold
local function stock(): Stock.Stock
	return {
		[1] = { key = "Battery", price = 3, count = 2 },
		[2] = { key = "Battery", price = 3, count = 2 },
		[3] = { key = "Saw", price = 8, count = 1 },
		[5] = { key = "Padlock", price = 6, count = 1 },
	}
end
local was, now = stock(), stock()
now[1].count = 1
now[3].count = 0
local sold = Buy.sold(was, now)
ok(sold ~= nil and sold[1] == 1 and sold[3] == 1 and sold[2] == nil, "a sale reads off the counts")
ok(next(Buy.sold(stock(), stock()) :: any) == nil, "the same stock sold nothing")
ok(Buy.sold(nil, stock()) == nil, "the first stock is a fill")
ok(Buy.sold(stock(), nil) == nil, "no stock is no sale")
now = stock()
now[3] = { key = "BoltCutters", price = 10, count = 1 }
ok(Buy.sold(stock(), now) == nil, "a different tool is a new stock")
now = stock()
now[4] = { key = "AirHorn", price = 7, count = 1 }
ok(Buy.sold(stock(), now) == nil, "a coil filled is a new stock")
now = stock()
now[1].count = 2
was = stock()
was[1].count = 1
ok(Buy.sold(was, now) == nil, "a count that rises is a new stock")

-- the buy's flights (S1-10c2b): the coins drawn add up to the price, never more than the most;
-- paying is done before the thing drops; the thing reaches the hand before the vend ends
for _, price in { 1, 3, 7, 8, 10, 25 } do
	local sum, n = 0, 0
	for _, worth in Buy.coins(price) do
		sum += worth
		n += 1
	end
	ok(sum == price, `the coins for {price} add up`)
	ok(n == math.min(price, Buy.Coins), `{price} draws {math.min(price, Buy.Coins)} coins`)
end
ok(
	(Buy.Coins - 1) * Buy.CoinGap + Buy.CoinFly < Buy.lands(),
	"the last coin is in the slot before the thing lands"
)
ok(Buy.ends() >= Buy.lands() + Buy.TakeAfter + Buy.Take, "the vend lasts until it's in the hand")
ok(Buy.ends() >= Buy.lands() + Buy.Vend.Flap, "and until the flap has settled")
local V3 = roblox.Vector3
local a, b, up = V3.new(0, 1, 0), V3.new(4, 1, 2), V3.new(0, 1, 0)
ok((Buy.arc(a, b, up, 0) - a).Magnitude < 1e-6, "the arc starts in the bin")
ok((Buy.arc(a, b, up, 1) - b).Magnitude < 1e-6, "and ends in the hand")
ok(math.abs(Buy.arc(a, b, up, 0.5).Y - 2) < 1e-6, "bowed its lift up at its middle")

print(`buy: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
