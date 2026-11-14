--!strict
--[[
	Coins (S1-04a): the coins a door pays out, the rules alone, so Lune tests them
	(tests/coins.spec.luau). The moment: you roll a door up and there's a glint of gold on the
	concrete in the bulb's light; a tap and the coins jump up and are gone with a chink, and the
	little count in the corner of your screen ticks up, one coin at a time.

	The deal says which units have coins and how many (`Deal.CoinShare`, `Deal.CoinSpread`); the
	server's Coins system lays each unit's pile as its door first lifts, with one "Take" button,
	and owns everyone's count. Each player has their own count, for this climb only (GDD "Coins,
	cash and finds"); whoever taps a pile first takes all of it, as DOORS' gold goes to whoever
	grabs it. A player who's wrapped can't take anything (GDD "Earning nothing").

	The coin's art and each pile's layout are generated (`Coins.Specs`, art/coin/): this module
	doesn't require them, so it stays free of Roblox types for Lune.
]]

local Coins = {}

Coins.Tag = "CoinPile" -- a pile of coins lying on a unit's floor
Coins.Template = "Coin" -- the coin's MeshPart in ReplicatedStorage.Props
-- The coin count's icon (CoinView): the coin rendered face on by art/coin/build.py's icon stage
-- (CoinIcon.png, uploaded through Studio; its ID in art/coin/assets.json). A picture rather than a
-- 3D view, so it stays as sharp as the number beside it.
Coins.Icon = "rbxassetid://76801781393109"
-- On each Player: their count this climb. Nil outside a climb, so the count shows only in one.
Coins.Attribute = "Coins"
Coins.CountAttribute = "CoinCount" -- on a pile: how many coins are in it
Coins.TakenAttribute = "TakenBy" -- on a pile: the UserId of whoever took it, once taken

-- Studs from your middle to a pile's button: the reach of a tool on the floor (`Carry.PickReach`),
-- so you step into the unit to take it, past what might be standing at the back.
Coins.Reach = 8
-- Seconds a taken pile stays for every screen to throw its coins up and away before the server
-- removes it: the lift and the vanish, with a little room for a slow phone.
Coins.Linger = 0.9

--[[
	The rate check: no more than `Rate` takes a second, `Burst` at once (a thumb tapping three
	piles side by side). Faster than any player taps; it only stops a script hammering the button.
	Returns whether this take may go ahead, and the burst left after it.
]]
Coins.Rate = 6
Coins.Burst = 3
function Coins.allow(last: number?, burst: number, now: number): (boolean, number)
	if last == nil then
		return true, Coins.Burst - 1
	end
	local left = math.min(Coins.Burst, burst + math.max(0, now - last) * Coins.Rate)
	if left < 1 then
		return false, left
	end
	return true, left - 1
end

-- The feel of a take, on every screen (the client's CoinView).
Coins.Lift = 1.1 -- studs each coin jumps as it's taken
Coins.LiftTime = 0.18 -- seconds to the top of the jump, spinning
Coins.Vanish = 0.2 -- seconds it shrinks away from the top of its jump
Coins.Stagger = 0.06 -- seconds between one coin of a pile and the next: a little ripple
Coins.Spin = 1.5 -- turns each coin spins in its jump and vanish, standing up on its edge: a flash
Coins.Sparks = 5 -- sparkles thrown off the pile as it's taken, from its glint
-- Seconds the count waits for a take's coins to fly in before it simply shows a rise that came
-- without one (a pile taken while it was off your screen): longer than a rise takes to arrive.
Coins.Grace = 0.3
-- On the taker's own screen: a coin flies from where the pile was to your count, one per coin.
Coins.Fly = 0.42 -- seconds a coin takes to reach your count
Coins.Pop = 1.35 -- how big the count swells as a coin lands in it, then settles
Coins.Show = 0.35 -- seconds the count takes to slide in when a climb begins

-- The sounds, from Pro Sound Effects' "Coins In Pocket" (Roblox's licensed library; measured in
-- Studio, docs/STUDIO.md). A take is the second recording's one bright chink, heard by friends
-- close by; a pile of two or three adds the first's jingle under it, quieter, as a handful does.
-- Each coin landing in your count is the chink again, short, small and high, on your screen only.
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number? }
Coins.Chink = { id = "rbxassetid://9113849162", from = 1.08, length = 0.4, volume = 1 } :: Sound
Coins.Jingle = { id = "rbxassetid://9113849100", from = 0.3, length = 0.7, volume = 0.45 } :: Sound
Coins.Tick = {
	id = "rbxassetid://9113849162",
	from = 1.1,
	length = 0.14,
	volume = 0.3,
	pitch = 1.7,
} :: Sound
Coins.Heard = 30 -- studs a take's chink carries: friends in the same stretch of hall hear it
Coins.Climb = 0.07 -- each landing coin of a take ticks this much higher than the last: a run up

-- What the count says: just the number, as most Roblox games show their coins.
function Coins.text(count: number): string
	return tostring(math.max(0, math.floor(count)))
end

return Coins
