--!strict
-- lune run tests/stock.spec
-- The machine's stock on a ride (S1-10c1): batteries in the bottom row every ride; three or four
-- different tools above, each one the machine can sell, in bays that change from ride to ride;
-- every price fits its window; the attribute's text round-trips and anything else is refused.
local Brix = require("../vendor/brix/src")
local Catalog = require("../src/shared/Tools/Catalog")
local Specs = require("../src/shared/Machine/Specs")
local Stock = require("../src/shared/Machine/Stock")

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

-- every tool it sells is a tool the game has, priced to fit two LED digits
for _, key in Stock.Tools do
	ok((Catalog :: any)[key] ~= nil, `{key} has a row in Tools.Catalog`)
	local price = Stock.Prices[key]
	ok(price ~= nil and price > 0 and price <= Stock.MaxPrice, `{key} has a price that fits`)
end
ok(Stock.Prices[Stock.Battery] == 3, "a battery costs 3")
ok(Stock.Prices.Padlock == 6 and Stock.Prices.BoltCutters == 10, "the GDD's guesses")

local batteryBays, toolBays = 0, 0
for _, bay in Specs.Bays do
	if bay.Row == Stock.BatteryRow then
		batteryBays += 1
	else
		toolBays += 1
	end
end
ok(
	batteryBays == 2 and toolBays == 4,
	`two battery bays and four tool bays: {batteryBays}, {toolBays}`
)

-- many rides' deals
local RIDES = 2000
local fours, changed = 0, 0
local seen: { [string]: { [number]: boolean } } = {}
local last: string? = nil
for seed = 1, RIDES do
	local stock = Stock.deal(Brix.Random.new({ seed = seed }))
	local tools: { [string]: boolean } = {}
	local count = 0
	for i, bay in Specs.Bays do
		local s = stock[i]
		if bay.Row == Stock.BatteryRow then
			ok(
				s ~= nil and s.key == Stock.Battery and s.count == Stock.Batteries and s.price == 3,
				`ride {seed}: bay {i} holds batteries`
			)
		elseif s then
			count += 1
			ok(table.find(Stock.Tools, s.key) ~= nil, `ride {seed}: bay {i} holds a tool it sells`)
			ok(not tools[s.key], `ride {seed}: {s.key} twice`)
			ok(s.count == 1 and s.price == Stock.Prices[s.key], `ride {seed}: {s.key} one, priced`)
			tools[s.key] = true
			seen[s.key] = seen[s.key] or {}
			seen[s.key][i] = true
		end
	end
	ok(count == 3 or count == 4, `ride {seed}: three or four tools, not {count}`)
	if count == 4 then
		fours += 1
	end
	local text = Stock.encode(stock)
	if last and text ~= last then
		changed += 1
	end
	last = text
end
local share = fours / RIDES
ok(math.abs(share - Stock.FourShare) < 0.05, `about half the rides have four tools: {share}`)
ok(changed >= RIDES * 0.95, `the stock changes from ride to ride: {changed} of {RIDES - 1}`)
for _, key in Stock.Tools do
	local bays = seen[key]
	local n = 0
	for _ in bays or {} do
		n += 1
	end
	ok(n == toolBays, `{key} turns up in every tool bay over many rides: {n}`)
end

-- the attribute's text round-trips
for seed = 1, 50 do
	local stock = Stock.deal(Brix.Random.new({ seed = seed }))
	local back = Stock.decode(Stock.encode(stock))
	ok(back ~= nil, `ride {seed}: decodes`)
	if back then
		for i in Specs.Bays do
			local a, b = stock[i], back[i]
			ok(
				(a == nil and b == nil)
					or (
						a ~= nil
						and b ~= nil
						and a.key == b.key
						and a.price == b.price
						and a.count == b.count
					),
				`ride {seed}: bay {i} the same after the round trip`
			)
		end
	end
end
local sold = Stock.decode("Battery:3:0/Battery:3:2/Saw:8:0///")
ok(sold ~= nil and sold[1].count == 0 and sold[3].count == 0 and sold[4] == nil, "sold out decodes")
local empty = Stock.decode("")
ok(empty ~= nil and next(empty) == nil, "an empty machine decodes")

-- anything else is refused
for _, bad in
	{
		(nil :: any) :: unknown,
		5,
		{},
		"Battery:3:2/Battery:3:2/Saw:8:1//Padlock:6:1/AirHorn:7:1/Saw:8:1", -- a seventh bay
		"Ladder:5:1", -- not sold here
		"Robux:1:1",
		"Battery:100:1", -- three digits
		"Battery:3:10",
		"Battery:-3:1",
		"Battery:3.5:1",
		"Battery:3",
		"Battery::1",
		"battery:3:1",
		" Battery:3:1",
		string.rep("a", 300),
	}
do
	ok(Stock.decode(bad) == nil, `refused: {tostring(bad)}`)
end

-- a price as its window's two digits
local a, b = Stock.digits(3)
ok(a == " " and b == "3", `3 shows as " 3": "{a}{b}"`)
a, b = Stock.digits(10)
ok(a == "1" and b == "0", `10 shows as "10": "{a}{b}"`)
a, b = Stock.digits(250)
ok(a == "9" and b == "9", `too dear shows 99: "{a}{b}"`)

print(`stock: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
