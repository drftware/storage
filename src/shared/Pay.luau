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
	into the count (CoinView) and each kept find leaves its slot (KeepView).

	Trapping pays (S4-04, D-188, D-402): each monster the team has shut in a unit as the gate shuts
	pays everyone aboard `Trap` more coins, as R.E.P.O.'s beaten monsters drop an orb worth money.
	On your screen each one pops its own burst of coins after the floor's pour (`parts`).

	The version the team picked on the ride up (S4-03c, D-406) pays its share more, and on your
	screen it pops last (S4-03c2): its card, small and lit in its own colour, bursts into its
	coins with its own sound, as Balatro scores each joker in turn after the hand.
]]
local Pay = {}

-- Coins for floor 1: about three batteries at the ride's machine, and a good handful next to
-- the ~37 lying behind every door of a floor 1 (Deal.CoinSpread), so the gate is worth reaching
-- but the doors are still worth opening. A default (`OWNER.md`).
Pay.Base = 10
-- More coins for each floor above the first: the higher the team gets, the more each gate is
-- worth, so pushing one more floor always tempts. A default (`OWNER.md`).
Pay.Rise = 2

-- More coins for each monster the team has shut in a unit as the gate shuts, to everyone aboard:
-- slamming a door on one stops being only an escape and becomes something worth going for.
-- The owner's starting guess (D-188): half of floor 1's pay.
Pay.Trap = 5

-- The coins floor `floor` pays each player aboard as its gate shuts.
function Pay.forFloor(floor: number): number
	local n = math.max(1, math.floor(floor))
	return Pay.Base + Pay.Rise * (n - 1)
end

-- A count of monsters, whole and never below none (nothing for a count that isn't a number).
local function count(n: number): number
	return if n == n and n > 0 then math.floor(math.min(n, 1e6)) else 0
end

-- What a player standing aboard is paid as floor `floor`'s gate shuts with `trapped` monsters
-- shut in on it (none if not given), and `picked` coins more for the version the team picked for
-- it on the ride up (`NextFloor.payOf`, S4-03c1; none if not given): nothing while wrapped, or for
-- a floor `paid` says they were paid for already this climb (a ride that came back, traps and
-- all). Marks the floor paid in `paid` when it pays.
function Pay.owed(
	paid: { [number]: boolean },
	floor: number,
	wrapped: boolean,
	trapped: number?,
	picked: number?
): number
	if wrapped or paid[floor] then
		return 0
	end
	paid[floor] = true
	return Pay.forFloor(floor) + Pay.Trap * count(trapped or 0) + count(picked or 0)
end

-- What a pay of `coins` that counted `trapped` monsters shut in and `picked` coins for the
-- version the team picked (none if not given) looks like on your screen: the floor's own coins,
-- poured as ever, how many pops of `Trap` coins follow, one per monster, and the version's coins,
-- its own pop last (S4-03c2). Only as much as `coins` holds, the version's first, then the traps'.
function Pay.parts(coins: number, trapped: number, picked: number?): (number, number, number)
	local total = count(coins)
	local version = math.min(count(picked or 0), total)
	local pops = math.min(count(trapped), (total - version) // Pay.Trap)
	return total - version - pops * Pay.Trap, pops, version
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

-- The one remote: server to a paid player's screen, with the coins paid, the catalog keys of
-- the finds kept (slot order), how many monsters shut in the coins count, and the version the
-- team picked for the floor and its coins in them ("" and 0 for none). Nothing is ever sent the
-- other way.
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

-- The feel of a monster shut in paying out on your screen (S4-04, CoinView): after the floor's
-- pour, one pop each, beside it, left then right then further out: the slam's bang, muffled as
-- from inside a unit, and `Trap` coins burst out of it, hang, and fly to your count, which
-- swells "+10", "+15", "+20" as each lands.
Pay.PopAfter = 0.3 -- after the floor's last coin sets off: the pour has its moment first
Pay.PopGap = 0.55 -- between one monster's pop and the next, so each gets its own beat
Pay.PopSide = 0.17 -- how far beside the pour each pop bursts, as a share of the screen's width
Pay.PopUp = 0.05 -- and how far above it, as a share of the screen's height
Pay.PopSpread = 0.075 -- how far a pop throws its coins: tighter than the pour, a fistful
Pay.PopHang = 0.22 -- a pop hangs a beat, glinting, before its coins fly to the count
Pay.PopClimb = 0.12 -- each pop's landing ticks pitch this much higher than the last pop's
-- The pop: the slam's bang (DoorSound's, a gas tank dropped on loose metal), pitched down and
-- quiet, as a monster's blows sound from inside its unit; the chink of coins on top of it.
Pay.PopBang = {
	id = "rbxassetid://9120381070",
	from = 0.36,
	length = 0.75,
	volume = 0.5,
	pitch = 0.86,
} :: Sound
Pay.PopChink = {
	id = "rbxassetid://9113849162",
	from = 1.08,
	length = 0.4,
	volume = 0.6,
	pitch = 1.15,
} :: Sound

-- The feel of the picked version's pop on your screen (S4-03c2, CoinView): after the traps'
-- pops (or the pour, with none), its card pops up small over the pour, lit in its own colour
-- with its own sound (`NextFloor`'s row), hangs a beat, then flashes and bursts into its coins,
-- which fly to your count; the "+" swells to the whole pay as the last lands.
Pay.PickAfter = 0.4 -- after the last pop sets off (or the pour's last coin): its own beat
Pay.PickUp = 0.15 -- how far above the pour the card pops, as a share of the screen's height
Pay.PickTall = 0.2 -- the card's height, as a share of the screen's height: its picture reads
Pay.PickIn = 0.28 -- the card punching up out of nothing, overshooting and settling
Pay.PickHold = 0.5 -- the card held up, lit, so you see which one it is before it bursts
Pay.PickFlyers = 8 -- the most of its coins drawn: each worth a share
Pay.PickSpread = 0.1 -- how far its burst throws the coins, as a share of the screen's height
Pay.PickHang = 0.2 -- its coins hang a beat, lit in its colour, before they fly to the count
Pay.PickClimb = 0.18 -- its landing ticks start this much higher than the last trap pop's

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
