--!strict
-- lune run tests/cash.spec
-- Cash (S1-12): the coins left at a climb's end turn into cash one for one, whole, never below
-- nothing and never past the guard; a save's cash only ever grows by it; the board's count-up runs
-- longer for more, within its bounds; and the figure reads as dollars with commas.
local Cash = require("../src/shared/Cash")
local Save = require("../src/shared/Save")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- the swap
ok(Cash.from(38) == 38 * Cash.PerCoin, "coins left turn into cash at the rate")
ok(Cash.from(0) == 0, "no coins, no cash")
ok(Cash.from(-5) == 0, "a count below nothing makes nothing")
ok(Cash.from(0 / 0) == 0, "a count that isn't a number makes nothing")
ok(Cash.from(7.9) == math.floor(7.9 * Cash.PerCoin), "whole cash only")
ok(Cash.from(math.huge) == Cash.Most, "a count gone wrong stops at the guard")
ok(Cash.from(999) == 999 * Cash.PerCoin, "Studio's biggest dev count is paid in full")

-- into the save
do
	local data = Save.fresh()
	ok(Save.earn(data, 38) == 38 and data.cash == 38, "a first climb's cash is saved")
	ok(Save.earn(data, 12) == 50, "the next climb's adds to it")
	ok(Save.earn(data, 0) == 50, "nothing earned changes nothing")
	ok(Save.earn(data, -20) == 50, "cash is never taken away by earning")
	ok(Save.earn(data, 0 / 0) == 50, "a value that isn't a number changes nothing")
	ok(Save.earn(data, 2.6) == 52, "whole cash only")
	local brix = require("../vendor/brix/src")
	local format = Save.format(brix)
	local stored, problem = format:encode(data)
	ok(stored ~= nil and problem == nil, "a save with earned cash still writes")
	if stored ~= nil then
		local back = format:decode(format:latest(), stored)
		ok(back ~= nil and back.cash == 52, "and reads back with it")
	end
end

-- the count-up
ok(Cash.countFor(0) == 0, "nothing to count, no count")
ok(Cash.countFor(-3) == 0 and Cash.countFor(0 / 0) == 0, "nothing odd is counted")
ok(Cash.countFor(1) >= Cash.CountLeast, "even a dollar is a short run")
ok(Cash.countFor(10) < Cash.countFor(30), "more runs longer")
ok(Cash.countFor(5000) == Cash.CountMost, "however much, it lands in time")
ok(Cash.CountMost / Cash.TickGap <= 60, "a run is a rattle of ticks, never a buzz")

-- the figure
ok(Cash.text(0) == "$0", "nothing")
ok(Cash.text(38) == "$38", "a climb's cash")
ok(Cash.text(999) == "$999", "no comma under a thousand")
ok(Cash.text(1204) == "$1,204", "a comma every three digits")
ok(Cash.text(1234567) == "$1,234,567", "and again")
ok(Cash.text(100000) == "$100,000", "a round number")
ok(Cash.text(-4) == "$0" and Cash.text(0 / 0) == "$0", "never below nothing")
ok(Cash.text(12.8) == "$12", "whole dollars")

print(`cash: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
