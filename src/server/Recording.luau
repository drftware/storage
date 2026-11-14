--!strict
--[[
	Recording (S1-02, the GDD's "What the game needs to record"): what every player earns and does,
	sent to Roblox's AnalyticsService through Brix's Analytics, a system. Nothing on screen: the
	records reach the experience's Creator Dashboard once the place is published (Studio sends
	nothing on), so every coin, door, catch, find and floor has a known worth before anything is
	priced.

	What's recorded and the plan it's checked against are `Record`'s (shared, pure, with a spec);
	this only listens where things happen and hands each moment to Record's book: a player joining
	or leaving, a climb beginning and each floor reached (Climbs), a unit opened and what it held
	(Deals' `dealt`, with who opened it), coins into a count (Coins' `earned`) and out of it at the
	car's machine (`spent`), a battery taken from a unit (Batteries' `taken`), a gate shutting with
	riders aboard (Climbs' `shut`), finds kept there (GatePay's `kept`), a catch (Keepers' `caught`),
	a friend cutting someone free (KeptPlayers' `freed`), the climb's end and each Again
	(ClimbEnds), and a lobby car leaving (LobbyCars' `departed`). A floor is the climb's floor now,
	0 off a climb (Studio's test hall).

	A record Brix refuses (one the plan doesn't declare, or past Roblox's 120 a minute plus 20 a
	player) is dropped and the game goes on: the first few problems are warned in full, then a
	count once a minute, so a busy server never floods its output. In Studio each record sent is
	printed as a line, since nothing else shows it.
]]
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Record = require(ReplicatedStorage.Shared.Record)
local Batteries = require(script.Parent.Batteries)
local ClimbEnds = require(script.Parent.ClimbEnds)
local Climbs = require(script.Parent.Climbs)
local Coins = require(script.Parent.Coins)
local Deals = require(script.Parent.Deals)
local GatePay = require(script.Parent.GatePay)
local Keepers = require(script.Parent.Keepers)
local KeptPlayers = require(script.Parent.KeptPlayers)
local LobbyCars = require(script.Parent.LobbyCars)

local STUDIO = RunService:IsStudio()
-- Different problems warned in full a server; past these, only the minute's count.
local TELL_MOST = 8
-- Seconds between counts of the records dropped since the last.
local COUNT_EVERY = 60

export type RecordingSystem = Brix.System & {
	-- How many records were dropped since the server started, for whatever reason.
	dropped: (self: any) -> number,
}

local Recording = {}

-- A record as one line of Studio's output.
local function line(record: Brix.AnalyticsRecord<Player>): string
	local parts: { string } = {}
	local labels: { Brix.AnalyticsFieldLabel } = record.fields
	for _, f in labels do
		table.insert(parts, `{f.name} {f.label}`)
	end
	local fields = if #parts > 0 then ` ({table.concat(parts, ", ")})` else ""
	local who = record.player.Name
	if record.kind == "event" then
		return `{who}: {record.name} {record.value}{fields}`
	elseif record.kind == "economy" then
		return `{who}: {record.flow} {record.amount} {record.currency} ({record.reason}), now {record.balance}{fields}`
	elseif record.kind == "funnel" then
		return `{who}: {record.funnel} funnel, step {record.step} {record.stepName}`
	end
	return `{who}: {record.path} floor {record.level} {record.status}`
end

function Recording.new(): RecordingSystem
	local climbs: Climbs.Climbs? = nil
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local dropped = 0
	local heard: { [string]: boolean } = {}
	local told = 0
	local uncounted = 0 -- dropped since the last count was warned
	local countedAt = os.clock()

	local function onProblem(problem: string)
		dropped += 1
		if told < TELL_MOST and not heard[problem] then
			heard[problem] = true
			told += 1
			warn(`Recording: a record was dropped: {problem}`)
			return
		end
		uncounted += 1
		local t = os.clock()
		if t - countedAt >= COUNT_EVERY then
			warn(`Recording: {uncounted} more records dropped in the last minute, {dropped} in all`)
			uncounted, countedAt = 0, t
		end
	end

	-- The climb's floor now; 0 off a climb.
	local function floorNow(): number
		local on = climbs and climbs:current()
		return if on then on.number else 0
	end

	local function on<T>(signal: Brix.Signal<T>?, handler: (T) -> ())
		if signal then
			table.insert(signals, signal:connect(handler))
		end
	end

	local system = { name = "Recording" }

	function system.dropped(_: any): number
		return dropped
	end

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		local sink = Brix.Roblox.AnalyticsSink.analyticsService()
		local send: Brix.AnalyticsSink<Player> = sink
		if STUDIO then
			send = {
				send = function(_: any, record: Brix.AnalyticsRecord<Player>): string?
					local problem = sink:send(record)
					if problem == nil then
						print(`Recording: {line(record)}`)
					end
					return problem
				end,
			}
		end
		local analytics = Brix.Analytics.new({
			plan = Record.plan(Brix),
			sink = send,
			onProblem = onProblem,
		})
		local b = Record.new(analytics)

		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		local c = (registry:get("climbs") :: any) :: Climbs.Climbs?
		climbs = c
		local coins = (registry:get("coins") :: any) :: Coins.CoinsSystem? -- any: as above
		local deals = (registry:get("deals") :: any) :: Deals.Deals? -- any: as above
		local batteries = (registry:get("batteries") :: any) :: Batteries.Batteries? -- any: as above
		local gatePay = (registry:get("gatePay") :: any) :: GatePay.GatePaySystem? -- any: as above
		local keepers = (registry:get("keepers") :: any) :: Keepers.Keepers? -- any: as above
		local kept = (registry:get("keptPlayers") :: any) :: KeptPlayers.KeptPlayers? -- any: as above
		local ends = (registry:get("climbEnds") :: any) :: ClimbEnds.ClimbEndsSystem? -- any: as above
		local cars = (registry:get("lobbyCars") :: any) :: LobbyCars.LobbyCars? -- any: as above

		for _, player in Players:GetPlayers() do
			b:joined(player, os.clock())
		end
		table.insert(
			connections,
			Players.PlayerAdded:Connect(function(player: Player)
				b:joined(player, os.clock())
			end)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				b:gone(player)
			end)
		)

		if c then
			on(c.began, function(floor: Climbs.OnFloor)
				b:began(Players:GetPlayers(), floor.number, HttpService:GenerateGUID(false))
			end)
			on(c.handedOff, function(h: Climbs.HandOff)
				b:reached(h.riders, h.to.number)
			end)
			on(c.shut, function(s: Climbs.Shut)
				b:rode(s.riders, s.from.number)
			end)
		end
		on(deals and deals.dealt, function(d: Deals.Dealt)
			local player = d.player
			if player and player.Parent then
				b:opened(player, floorNow(), d.contents, os.clock())
			end
		end)
		on(coins and coins.earned, function(e: Coins.Earned)
			b:earned(e.player, e.amount, e.balance, e.reason, floorNow())
		end)
		on(coins and coins.spent, function(e: Coins.Spent)
			b:spent(e.player, e.amount, e.balance, e.item, "machine", floorNow())
		end)
		on(batteries and batteries.taken, function(t: Batteries.Taken)
			b:battery(t.player, floorNow())
		end)
		on(gatePay and gatePay.kept, function(k: GatePay.Kept)
			b:kept(k.player, k.finds, k.floor)
		end)
		on(keepers and keepers.caught, function(catch: Keepers.Catch)
			b:caught(catch.player, floorNow())
		end)
		on(kept and kept.freed, function(f: KeptPlayers.Freed)
			b:freed(f.player, floorNow())
		end)
		on(ends and ends.ended, function(e: ClimbEnds.Ended)
			b:ended(e.endings)
		end)
		on(ends and ends.again, function(player: Player)
			b:again(player)
		end)
		on(cars and cars.departed, function(aboard: { Player })
			b:carLeft(aboard, os.clock())
		end)
	end

	function system.stop(_: any)
		for _, s in signals do
			s:disconnect()
		end
		table.clear(signals)
		for _, conn in connections do
			conn:Disconnect()
		end
		table.clear(connections)
	end

	return system
end

return Recording
