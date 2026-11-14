--!strict
--[[
	Cash (S1-12, the GDD's "Coins, cash and finds"): the coins you didn't spend become cash you keep.
	The moment it serves: the climb is over, the black lifts on the car's wall, and under your photo
	a gold figure counts up from nothing with a run of little chinks, landing with a jingle: that's
	yours, for good. It's the same number your coin count showed, so the board teaches the swap with
	no words: the coins you saved are the cash you keep. Dandy's World does the same with Ichor, one
	money for its in-run shop and for keeping (from memory); the tally counting up on the results is
	DOORS' end-of-run Knobs (from memory).

	Pure. The server's CashOut turns each player's coins into cash as the climb ends (`from`) and
	adds it to their save (`Save.earn`); the car's results board (CarResults) shows each friend's,
	counting up (`countFor`, `text`).
]]

local Cash = {}

-- What one coin left at the climb's end is worth in cash. One for one, so the number in your coin
-- count is the cash on the results board (the owner's call, OWNER.md).
Cash.PerCoin = 1
-- The most cash one climb's coins can make: a guard against a count gone wrong, far past any climb.
Cash.Most = 100000

-- On each Player, set as a climb ends: the cash their coins turned into (0 for none), read into the
-- results board as the group is stood back in its car, and cleared with the end (ClimbEnds).
Cash.EarnedAttribute = "CashEarned"

-- The cash `coins` left at a climb's end turn into: a whole number from 0 to `Most`.
function Cash.from(coins: number): number
	if coins ~= coins or coins <= 0 then
		return 0 -- none, a negative or not a number
	end
	return math.min(math.floor(coins * Cash.PerCoin), Cash.Most)
end

-- The count-up on the board: the figure runs from $0 to what you earned, fast and then slowing as a
-- slot machine's reels do, so the last few dollars land one by one. Bigger amounts run longer, up to
-- a point, so even a big climb lands while you're still looking.
Cash.CountAt = 1.05 -- seconds after the black lifts: as the last photo is pinned (CarResults)
Cash.CountLeast = 0.55 -- the shortest run, for a dollar or two
Cash.CountEach = 0.045 -- seconds more for each dollar
Cash.CountMost = 2.2 -- the longest run, however much
Cash.TickGap = 0.05 -- the fewest seconds between two ticks: a fast run is a rattle, never a buzz
Cash.TickRise = 0.5 -- how much higher the last tick is than the first: a run up to the landing
Cash.Pop = 1.3 -- how big the figure swells as it lands, then settles

-- Seconds the count-up of `amount` takes: 0 for nothing to count.
function Cash.countFor(amount: number): number
	if amount ~= amount or amount <= 0 then
		return 0
	end
	return math.min(Cash.CountLeast + Cash.CountEach * math.floor(amount), Cash.CountMost)
end

-- What the board says of `amount`: dollars, whole, with a comma every three digits ("$1,204"),
-- as most games show money.
function Cash.text(amount: number): string
	local whole = if amount == amount then math.max(0, math.floor(amount)) else 0
	local digits = tostring(whole)
	local out = string.reverse((string.gsub(string.reverse(digits), "(%d%d%d)", "%1,")))
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return `${out}`
end

return table.freeze(Cash)
