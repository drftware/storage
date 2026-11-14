--!strict
--[[
	The buy at the car's machine (S1-10c2, GDD "The ride"): mid-ride, the machine awake, you press
	a lit button by its price; the button sinks with a click, the coil turns its thing out, it
	drops with a clunk behind the flap, the flap swings, and it's yours: a tool in a free slot, or
	a battery that snaps your torch full. Dandy's World's elevator is its shop the same way: the
	ride between floors is when you spend.

	The server owns the buy (Machines): a press is checked for its bay and the rider's reach, that
	they're aboard that car on a ride that wakes it, that the bay's row is lit and the power not
	yet cut (`open`), that the coil holds something and they can pay (`check`), then the rate
	(`allow`). It charges, lowers the bay's count and hands the thing over in one step, so a coin
	is never taken for nothing. Every screen reads the sale off the stock (`sold`) and the buyer
	off `Attribute`, and plays the vend as `Vend` times it.

	Pure, so Lune checks it (tests/buy.spec.luau).
]]
local Pay = require("../Pay")
local Ride = require("../Elevator/Ride")
local Specs = require("./Specs")
local Stock = require("./Stock")
local Wake = require("./Wake")

local Buy = {}

-- On a machine: the last buy at it, `encode`d (its bay, a count that only rises, the buyer's
-- UserId), so every screen sends the thing to the right hand. Written just before the stock.
Buy.Attribute = "Bought"

-- Studs from the machine's one button (`point`, the middle of its glass) that it reaches: from
-- anywhere in the car's back half, so a friend standing in front of it never blocks you (S1-10d1).
-- Its menu closes a stud short of this, so a pick made at the edge still counts.
Buy.Reach = 8
-- Studs the button hangs out from the glass, so it shows on the glass's face.
Buy.Out = 0.4
-- Studs the server allows past it (lag, a long arm).
Buy.Slack = 2

-- Seconds after a row's tube catches before its buttons work: its prices have finished their
-- LED test (MachineView's 0.18), so you never buy something whose price you haven't seen.
Buy.Settle = 0.2
-- Seconds before the power cuts (the gate starts to fold, `Ride.opens`) the last buy is taken,
-- so its thing has dropped and the flap swung while the machine is still lit.
Buy.Last = 1.2

-- The vend, seconds from the press reaching a screen. The button sinks at once and comes back
-- up; the coil turns one loop (its things creep forward a pitch); as the turn ends the front
-- thing tips off the coil's tip and falls into the bin with a clunk; the flap swings out and
-- settles as a hand reaches in.
Buy.Vend = {
	Sink = 0.06, -- the button down
	Up = 0.22, -- and back up after
	Turn = 0.1, -- the coil starts turning
	Turning = 0.6, -- one loop, a geared motor's steady grind
	Fall = 0.32, -- from the coil's tip to the bin's floor
	Flap = 0.45, -- the flap's swing out and back
	Gone = 0.15, -- after the flap swings, the thing is gone from the bin (nobody to fly to)
}

-- The remotes. `Remote` (S1-10c2b): server to the buyer's screen, just before the coins leave
-- their count, with the machine, the bay and the price. `Pick` (S1-10d1): a screen's pick on the
-- machine's menu, with the machine and the bay; the server checks it all (Machines).
Buy.RemoteFolder = "Remotes"
Buy.Remote = "MachineBuy"
Buy.Pick = "MachinePick"

-- Where the machine's one button is, in the world, for a machine whose pivot is `frame`: the middle
-- of its glass, `Out` in front of it. The server measures a pick's reach from here.
function Buy.point(frame: CFrame): Vector3
	local g = Specs.Glass.Centre
	-- its own axes, not a new Vector3, so Lune checks it too (the frame's back is -LookVector)
	return frame.Position
		+ frame.RightVector * g[1]
		+ frame.UpVector * g[2]
		- frame.LookVector * (g[3] - Buy.Out)
end

-- The coins paid, on the buyer's screen (CoinView): one after another they leave the little
-- count in the corner, ticking it down, and fly into the machine's coin slot, each with a clink.
-- All in before the thing has dropped, so paying reads first.
Buy.Coins = 8 -- the most coins drawn: a dearer thing makes each worth more, never a longer wait
Buy.CoinGap = 0.06 -- between one coin leaving the count and the next: a quick feed
Buy.CoinFly = 0.3 -- from the count to the slot, shrinking and turning edge-on to go in
Buy.CoinDown = 0.4 -- each coin leaving ticks lower, first to last: counting down

-- The thing, out of the bin into the buyer's hand on every screen (MachineVend): a beat after it
-- lands, as the flap swings widest, it lifts out through the flap and arcs to their left hand
-- (a tool, which then shows there) or into their torch (a battery: the clack-click, and the torch
-- snaps full). Until it lands there, every screen holds the change back (InFlight).
Buy.TakeAfter = 0.08 -- after it lands in the bin
Buy.Take = 0.42 -- from the bin to the hand: quick, a little slow off the start
Buy.TakeLift = 0.9 -- studs its arc bows up over the straight line, turning into how it's held

-- Seconds from a sale reaching a screen to the thing landing in the bin.
function Buy.lands(): number
	local v = Buy.Vend
	return v.Turn + v.Turning + v.Fall
end

-- Seconds from a sale reaching a screen to its vend being over: the flap settled and the thing
-- in the buyer's hand (or gone from the bin, with nobody to fly to).
function Buy.ends(): number
	local v = Buy.Vend
	return Buy.lands() + math.max(v.Flap + v.Gone, Buy.TakeAfter + Buy.Take)
end

-- The coins drawn for a price: at most `Buy.Coins`, adding up to it (Pay's split).
function Buy.coins(price: number): { number }
	return Pay.split(price, Buy.Coins)
end

-- A point `p` (0 to 1) along the arc from `from` to `to`, bowed `up` (studs, a vector) at its
-- middle.
function Buy.arc(from: Vector3, to: Vector3, up: Vector3, p: number): Vector3
	local mid = (from + to) * 0.5 + up * 2
	local q = 1 - p
	return from * (q * q) + mid * (2 * q * p) + to * (p * p)
end

-- The vend's sounds, all heard round the car (`Heard` studs), each from the game's own measured
-- recordings (docs/STUDIO.md): the button's click (UnitLight's switch, pitched up to a small
-- plastic key); the coil's geared motor (the machine's own ballast hum, pitched up to a whine,
-- for the turn); the flap's clack as the thing hits it (the starter's tink, pitched down to a
-- hollow plastic knock). The thing's own clunk in the bin is its drop sound (a tool's, the
-- battery's clack). Too few coins: the button clicks and the machine gives one short dull buzz
-- (the sign's buzz, pitched down) while the price blinks.
export type Sound = { id: string, from: number, length: number, volume: number, pitch: number }
Buy.Click =
	{ id = "rbxassetid://9117028600", from = 0, length = 0.25, volume = 0.6, pitch = 1.5 } :: Sound
Buy.Motor =
	{ id = "rbxassetid://9112889082", from = 2, length = 0.6, volume = 0.9, pitch = 2.4 } :: Sound
Buy.Knock =
	{ id = "rbxassetid://9120089728", from = 0, length = 0.3, volume = 0.5, pitch = 0.8 } :: Sound
Buy.Nope =
	{ id = "rbxassetid://9116270244", from = 0.3, length = 0.3, volume = 0.5, pitch = 0.7 } :: Sound
Buy.Heard = 18
-- Seconds the price blinks for someone who can't pay, and blinks a second.
Buy.Blink = 0.6
Buy.BlinkHz = 8

-- The press rate: a burst of two, then one every half second (a button mashed is not a stream).
Buy.Gap = 0.5
Buy.Burst = 2

export type Check = "ok" | "empty" | "poor"

--[[
	How a bay shows on the menu (S1-10d1) and what a pick on it does: "dark" its row isn't lit yet
	or the power is about to cut (a dead press); "empty" its coil is empty (dashes, a dead press);
	"full" a battery for a torch whose ring is full (`wants` false: dim, a dead press, left for a
	friend); "poor" too few coins (its price dim; a pick clicks, buzzes and blinks it); "ok".
]]
export type Tile = "dark" | "empty" | "full" | "poor" | "ok"
function Buy.tile(bay: Stock.Bay?, lit: boolean, coins: number?, wants: boolean): Tile
	local tile: Tile = "ok"
	if not lit then
		tile = "dark"
	elseif bay == nil or bay.count <= 0 then
		tile = "empty"
	elseif bay.key == Stock.Battery and not wants then
		tile = "full"
	elseif Buy.check(bay, coins) == "poor" then
		tile = "poor"
	end
	return tile
end

-- Whether bay row `row`'s buttons work `since` seconds into a ride from floor `from`: the ride
-- wakes the machine, the row's prices are lit, and the power isn't about to cut.
function Buy.open(row: number, since: number, from: number): boolean
	if not Wake.wakes(from) or Wake.Tubes[row] == nil then
		return false
	end
	return since >= Wake.catches(row) + Buy.Settle and since < Ride.opens() - Buy.Last
end

-- Whether a press on `bay` (its stock, nil for an empty coil) sells to someone with `coins`.
function Buy.check(bay: Stock.Bay?, coins: number?): Check
	if bay == nil or bay.count <= 0 then
		return "empty"
	end
	if coins == nil or coins < bay.price then
		return "poor"
	end
	return "ok"
end

-- Whether a press at `now` may go ahead, given the last allowed one at `last` (nil: none yet)
-- and `burst` presses banked then; and the presses banked after this one.
function Buy.allow(last: number?, burst: number, now: number): (boolean, number)
	if last == nil then
		return true, Buy.Burst - 1
	end
	local earned = math.floor((now - last) / Buy.Gap)
	local have = math.min(Buy.Burst, burst + math.max(earned, 0))
	if have <= 0 then
		return false, 0
	end
	return true, have - 1
end

-- The attribute's text for a buy at bay `bay`, the `serial`th at this machine, by `userId`.
function Buy.encode(bay: number, serial: number, userId: number): string
	return `{bay}|{serial}|{userId}`
end

-- The bay, serial and buyer's UserId from the attribute's text, or nil for anything else.
function Buy.decode(value: unknown): (number?, number, number)
	if type(value) ~= "string" or #value > 64 then
		return nil, 0, 0
	end
	local b, s, u = string.match(value, "^(%d+)|(%d+)|(%d+)$")
	local bay, serial, user = tonumber(b), tonumber(s), tonumber(u)
	if not (bay and serial and user) or bay < 1 or bay > #Specs.Bays then
		return nil, 0, 0
	end
	return bay, serial, user
end

--[[
	How the stock went from `was` to `now`: the things sold out of each bay (bay -> how many), if
	`now` is `was` with only counts lowered; nil if it's a different stock (a new ride's, or the
	first one), which a screen fills afresh.
]]
function Buy.sold(was: Stock.Stock?, now: Stock.Stock?): { [number]: number }?
	if was == nil or now == nil then
		return nil
	end
	local sold: { [number]: number } = {}
	for i, before in was do
		local after = now[i]
		if after == nil or after.key ~= before.key or after.price ~= before.price then
			return nil
		end
		if after.count > before.count then
			return nil
		end
		if after.count < before.count then
			sold[i] = before.count - after.count
		end
	end
	for i in now do
		if was[i] == nil then
			return nil
		end
	end
	return sold
end

return table.freeze(Buy)
