--!strict
--[[
	Pay and keeping at the gate (S1-06, GDD "When the gate shuts"), the rules alone, so Lune tests
	them (tests/pay.spec.luau). The moment: the gate slams with you aboard, a burst of coins spills
	across your screen and pours into your count, chink after chink, and the boombox you carried
	rises out of your slot, glinting, and is gone: it's yours for good.

	The instant the gate hits its post, everyone standing in the car who isn't wrapped is paid the
	same coins for the floor, a little more each floor (`forFloor`), and the finds in their slots
	become theirs for good (`Carry.keep`, `Save.keep`): out of the slots, into the save, slots free
	for the next floor. A wrapped player, or anyone not inside, gets nothing for that floor (GDD
	"Earning nothing"). A floor pays each player once a climb (`owed`), so a ride that comes back
	to the same floor never pays twice.

	The server's GatePay does it and tells each paid player's screen (`Remote`): their coins pour
	into the count (CoinView) and each kept find leaves its slot (KeepView). Untested bets left
	out: trapped monsters raising the pay, and a harder floor picked on the ride paying more (both
	in `OWNER.md`).
]]
local Pay = {}

-- Coins for floor 1: about three batteries at the ride's machine, and a good handful next to
-- the ~37 lying behind every door of a floor 1 (Deal.CoinSpread), so the gate is worth reaching
-- but the doors are still worth opening. A default (`OWNER.md`).
Pay.Base = 10
-- More coins for each floor above the first: the higher the team gets, the more each gate is
-- worth, so pushing one more floor always tempts. A default (`OWNER.md`).
Pay.Rise = 2

-- The coins floor `floor` pays each player aboard as its gate shuts.
function Pay.forFloor(floor: number): number
	local n = math.max(1, math.floor(floor))
	return Pay.Base + Pay.Rise * (n - 1)
end

-- What a player standing aboard is paid as floor `floor`'s gate shuts: nothing while wrapped, or
-- for a floor `paid` says they were paid for already this climb (a ride that came back). Marks
-- the floor paid in `paid` when it pays.
function Pay.owed(paid: { [number]: boolean }, floor: number, wrapped: boolean): number
	if wrapped or paid[floor] then
		return 0
	end
	paid[floor] = true
	return Pay.forFloor(floor)
end

-- The coins drawn flying for a pay of `total`: at most `most` of them, each worth a share, the
-- shares as even as they can be with the bigger ones last (the run ends on its biggest landings),
-- adding up to `total`. Empty for nothing.
function Pay.split(total: number, most: number): { number }
	local whole = math.max(0, math.floor(total))
	local n = math.min(whole, math.max(1, math.floor(most)))
	local out = table.create(n, 0)
	if n == 0 then
		return out
	end
	local each = whole // n
	local extra = whole - each * n
	for i = 1, n do
		out[i] = each + (if i > n - extra then 1 else 0)
	end
	return out
end

-- The one remote: server to a paid player's screen, with the coins paid and the catalog keys of
-- the finds kept, slot order. Nothing is ever sent the other way.
Pay.RemoteFolder = "Remotes"
Pay.Remote = "GatePay"

-- The feel of the pay on your screen (CoinView). Times in seconds, places as shares of the screen.
Pay.Delay = 0.35 -- after the gate hits its post: the slam lands first, then the reward
Pay.Flyers = 12 -- the most coins drawn: a bigger pay makes each one worth more, never a longer wait
Pay.From = { 0.5, 0.44 } -- where the coins burst from: a little above the middle, over your finds
Pay.Spread = 0.17 -- how far the burst throws them, as a share of the screen's height
Pay.Scatter = 0.34 -- the burst throwing them out, overshooting a little and settling
Pay.Hang = 0.16 -- the burst hangs a beat, glinting, before the first one flies to the count
Pay.Gap = 0.055 -- between one coin setting off for the count and the next: a quick pour
Pay.Plus = 1.1 -- the "+10" by your count holds this long after the last coin lands, then fades

-- The pour: Pro Sound Effects' "Coin Throws 3", a handful of coins thrown on concrete, one dense
-- burst in its first 0.6 s with a tail to 0.9 s (measured, docs/STUDIO.md). On your screen only.
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }
Pay.Pour = { id = "rbxassetid://9113849651", from = 0, length = 1.0, volume = 0.7 } :: Sound

-- The feel of a kept find on your screen (KeepView).
Pay.KeepAfter = 0.55 -- after the gate hits its post: as the first coins burst, not before the slam
Pay.KeepGap = 0.35 -- between one kept find and the next, so each gets its own beat
Pay.KeepRise = 0.42 -- rising out of its slot, growing, overshooting and settling
Pay.KeepHold = 0.75 -- held up over your slots, turning, glinting: yours
Pay.KeepAway = 0.4 -- shrinking and flying up off the top of the screen, gone for good
Pay.KeepGrow = 2.1 -- how big it shows held up, against your slot's box
Pay.KeepUp = 0.22 -- how far up it rises, as a share of the screen's height: under the coins
-- The sparkle as it's kept: the bright chink of a coin, pitched up, and the find's own pick-up
-- sound under it (its catalog row), on your screen only.
Pay.KeepChink = {
	id = "rbxassetid://9113849162",
	from = 1.08,
	length = 0.4,
	volume = 0.55,
	pitch = 1.35,
} :: Sound

return table.freeze(Pay)
