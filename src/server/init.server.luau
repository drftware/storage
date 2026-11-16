--!strict
--[[
	The server's entry point: one Brix Host running the systems that decide, stepped every Heartbeat
	and stopped when the server closes.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Breakers = require(script.Breakers)
local Feeds = require(script.Feeds)
local Carts = require(script.Carts)
local CashOut = require(script.CashOut)
local ClimbEnds = require(script.ClimbEnds)
local Batteries = require(script.Batteries)
local Coins = require(script.Coins)
local Climbs = require(script.Climbs)
local Crawls = require(script.Crawls)
local Deals = require(script.Deals)
local DevCorridor = require(script.DevCorridor)
local Doors = require(script.Doors)
local Elevators = require(script.Elevators)
local Flashlights = require(script.Flashlights)
local FrontOffice = require(script.FrontOffice)
local GatePay = require(script.GatePay)
local Horns = require(script.Horns)
local Keepers = require(script.Keepers)
local LobbyCars = require(script.LobbyCars)
local KeptPlayers = require(script.KeptPlayers)
local Kneels = require(script.Kneels)
local Machines = require(script.Machines)
local MarkedBoxes = require(script.MarkedBoxes)
local Minimaps = require(script.Minimaps)
local Pockets = require(script.Pockets)
local Prompts = require(script.Prompts)
local Live = require(script.Live)
local Purchasing = require(script.Purchasing)
local CutFrees = require(script.CutFrees)
local Recording = require(script.Recording)
local Ladders = require(script.Ladders)
local MotionLights = require(script.MotionLights)
local Saving = require(script.Saving)
local Saws = require(script.Saws)
local Slots = require(script.Slots)
local Taps = require(script.Taps)
local Trips = require(script.Trips)
local Watching = require(script.Watching)
local Wraps = require(script.Wraps)

local systems: { Brix.HostEntry } = {
	-- Each player's save, held by this server while they play (first, so it stops last).
	{ slot = "saving", system = Saving.new() },
	-- The building's motion lights: which fixtures are lit, for every player.
	{ slot = "motionLights", system = MotionLights.new() },
	-- Each floor's breaker box: thrown, its hall lights out; a held lever switches them back on.
	{ slot = "breakers", system = Breakers.new() },
	-- Security camera feeds: a floor's corner maps cut to a camera watching a monster do something.
	{ slot = "feeds", system = Feeds.new() },
	-- Every unit's roll-up door: its buttons, the checks on a press, its events.
	{ slot = "doors", system = Doors.new() },
	{ slot = "kneels", system = Kneels.new() },
	-- Each floor's freight elevator: its keypad, the code check, the alarm, its gate.
	{ slot = "elevators", system = Elevators.new() },
	{ slot = "flashlights", system = Flashlights.new() },
	-- Everyone's two tool slots: tools on floors, picked up, switched, dropped, handed over.
	{ slot = "slots", system = Slots.new() },
	-- The deal on the floor: each unit's contents dealt and laid as its door first lifts or a saw holes it.
	{ slot = "deals", system = Deals.new() },
	-- The coins on the floors and everyone's count: a pile laid as a door first lifts, a tap takes it.
	{ slot = "coins", system = Coins.new() },
	-- The batteries on the floors: one laid as a door first lifts, a tap fills a torch that needs it.
	{ slot = "batteries", system = Batteries.new() },
	-- The marked boxes: the one box in a unit with something in it, its Open checked and stamped.
	{ slot = "markedBoxes", system = MarkedBoxes.new() },
	-- The machine in each floor's car: every waking ride's stock dealt once, shown in its coils.
	{ slot = "machines", system = Machines.new() },
	{ slot = "saws", system = Saws.new() },
	-- Crawling through a sawn hole: its Crawl buttons, the checks on a press, the move's start.
	{ slot = "crawls", system = Crawls.new() },
	{ slot = "ladders", system = Ladders.new() },
	-- The keepers' brain: each floor's map kept in step with its doors, what each keeper hears, its walk.
	{ slot = "keepers", system = Keepers.new() },
	-- The tap as a door comes down on a sleeping monster: its window, its remote, a soft or a bang.
	{ slot = "taps", system = Taps.new() },
	-- Getting kept: a caught player's things dropped, them stored in a unit, let out as its door lifts.
	{ slot = "keptPlayers", system = KeptPlayers.new() },
	-- The code's notes players carry: pinned beside the keypad as they reach it, dropped as they're caught or leave.
	{ slot = "pockets", system = Pockets.new() },
	-- Blowing the air horn: its gap between blows, the blast on every screen, keepers coming to it.
	{ slot = "horns", system = Horns.new() },
	-- Laying bubble wrap: a Lay checked against the halls, the roll spent, a sheet across the hall.
	{ slot = "wraps", system = Wraps.new() },
	{ slot = "minimaps", system = Minimaps.new() },
	-- The climb: each floor dealt and laid while the team rides up to it, the one below cleared.
	{ slot = "watching", system = Watching.new() },
	{ slot = "climbs", system = Climbs.new() },
	-- Pay and keeping as a floor's gate shuts: coins to everyone aboard, their finds theirs for good.
	{ slot = "gatePay", system = GatePay.new() },
	-- The climb's end: everyone kept or left, or the top; the results under it, and "Again".
	{ slot = "climbEnds", system = ClimbEnds.new() },
	-- The coins left as a climb ends turned into cash, into each player's save at once.
	{ slot = "cashOut", system = CashOut.new() },
	-- Everkeep's front office, the lobby: where everyone loads in, facing its six cars.
	{ slot = "frontOffice", system = FrontOffice.new() },
	-- The lobby's platform carts: Ride, handed to the rider's screen, its pace watched, parked again.
	{ slot = "carts", system = Carts.new() },
	-- A lobby car's group to a server of its own; on that server, the group stood in floor 1's car.
	{ slot = "trips", system = Trips.new() },
	-- The lobby's cars: step in to join a group, the count, the gate's slam, the ride to floor 1.
	{ slot = "lobbyCars", system = LobbyCars.new() },
	-- What every player earns and does, sent to Roblox's analytics (last: it only listens).
	{ slot = "recording", system = Recording.new() },
	-- The live config: each product's switch, changed on every server without an update.
	{ slot = "live", system = Live.new() },
	-- Robux purchases: Roblox's receipts granted into saves exactly once (after recording: it
	-- hands Brix's Purchases Recording's analytics).
	{ slot = "purchasing", system = Purchasing.new() },
	-- Cut Free: the caught screen's press, its prompt, and the grant that frees you (after
	-- purchasing, keptPlayers, watching and saving: it hears and calls all four).
	{ slot = "cutFrees", system = CutFrees.new() },
}
-- The test hall and its "Walk a floor" post: Studio only now the lobby is the way in (D-109).
if RunService:IsStudio() then
	table.insert(systems, { slot = "devCorridor", system = DevCorridor.new() })
end

-- a refused press's remote, there before any screen looks for it (L-19a)
Prompts.ready()

local host = Brix.Host.new({ systems = systems })
host:start()

local beats = RunService.Heartbeat:Connect(function(dt: number)
	host:advance(dt)
end)

game:BindToClose(function()
	beats:Disconnect()
	host:stop()
end)
