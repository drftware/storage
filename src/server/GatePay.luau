--!strict
--[[
	GatePay (S1-06, GDD "When the gate shuts"): pay and keeping as a floor's gate shuts, a system.
	The moment it serves: the gate slams with you aboard, coins pour into your count, and the
	boombox in your slot is yours for good as it leaves the slot.

	The instant a floor's gate hits its post with friends aboard (Climbs' `shut`), each rider who is
	alive and not wrapped is paid the floor's coins (`Pay.owed`: the same for everyone, a little
	more each floor, once a floor a climb) into their count (Coins' `pay`), and the finds in their
	slots are kept (Slots' `keep`): out of the slots and into their save (`Save.keep`, landing on
	the shelf at home as well, D-284), which is
	written at once, since a find kept is worth keeping. A wrapped rider gets nothing for the floor
	(GDD "Earning nothing"), and keeps the finds in their slots for a later gate, if they have any.

	Trapping pays (S4-04, D-402): each monster the team has shut in a unit on that floor as the
	gate shuts (Keepers' `trappedOn`; one freed before then, or one the floor woke behind its own
	door, doesn't count) adds `Pay.Trap` to every paid rider's coins.

	The floor's big find (S4-05b3, D-418) counts in the arms of a rider who is paid, or set down on
	the car's floor with a paid rider aboard (S4-05b4: taken up off it in a glint, kept by its last
	hauler if they ride, else the rider nearest it, BigFinds' `aboard`): then every paid rider
	gets `Pay.bigOf` more, and its keeper keeps it as any find in their slots. Anywhere else, it's
	left behind with the floor, and every paid rider's screen is told so.

	Each paid rider's screen is told what they got (`Pay.Remote`: coins, the kept finds' keys, how
	many monsters shut in the coins count, the picked version's name and its coins, then the big
	find's key and its coins, 0 for one left behind) before
	their count changes, so the coins are already on their way when it rises (CoinView) and
	each kept find rises out of its slot (KeepView). A rider whose save hasn't loaded yet (only just
	joined) has their kept finds held here and added the moment it loads, so nothing kept is lost.

	Finds taken up out of a job box (S5-03d2, D-302, D-304) are settled here through
	`Home.Taken.settle`, every touched save written at once. One out of a friend's box carried
	aboard (Slots' `keep` hands it back apart) is the rider's now: kept into their save as any find
	and struck off its owner's in the same step. One lost on the climb (left with a floor, the
	climb over, used up, its owner gone mid-climb) is struck off its owner's save, and one back in
	its owner's box brings home its crack (Slots' `taken`). A leaving owner's strike rides in their
	save's last write (Saving's `leaving`). A server stopping settles nothing: each is settled on
	the server's next step, and a stopping server steps no more (D-305).

	A find still sealed (S5-02b2c, D-427) is kept sealed: Slots' `keep` names it "Teddy:Sealed"
	(Finds/Seal), so it lands on the shelf and in the box in its pack, worth Seal.Times. One out of
	a job box whose pack tore on the climb settles plain (`Taken`'s `torn`).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local NextFloor = require(ReplicatedStorage.Shared.NextFloor)
local Pay = require(ReplicatedStorage.Shared.Pay)
local Save = require(ReplicatedStorage.Shared.Save)
local Seal = require(ReplicatedStorage.Shared.Finds.Seal)
local Taken = require(ReplicatedStorage.Shared.Home.Taken)
local Tally = require(ReplicatedStorage.Shared.Tally)
local BigFinds = require(script.Parent.BigFinds)
local Climbs = require(script.Parent.Climbs)
local Coins = require(script.Parent.Coins)
local Keepers = require(script.Parent.Keepers)
local Prompts = require(script.Parent.Prompts)
local Saving = require(script.Parent.Saving)
local Slots = require(script.Parent.Slots)

-- Shelf spots a find kept walks onto at home (D-284; every home small until the sizes, S5-03h).
local SPOTS = #Home.Specs.Shelf.Spots

local GatePay = {}

-- Finds a rider kept at a floor's gate, by name, and the floor (Recording, S1-02). `found`: those
-- of them the climb dealt (not a friend's find taken up from home), each marked if it cracked on
-- the way: the haul the results value one at a time (S5-01a, D-428).
export type Kept = { player: Player, finds: { string }, floor: number, found: { Tally.Find } }

export type GatePaySystem = Brix.System & {
	-- Fires for each rider who kept finds as a gate shut, after they're out of the slots.
	kept: Brix.Signal<Kept>,
}

local function alive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function GatePay.new(): GatePaySystem
	local keptSignal = Brix.Signal.new() :: Brix.Signal<Kept>
	local paid: { [Player]: { [number]: boolean } } = {} -- the floors each player was paid for
	-- kept finds for a save not loaded yet, and those of them with cracked glass (F-G1e5e)
	local waiting: { [Player]: { kept: { string }, chipped: { string } } } = {}
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local remote: RemoteEvent? = nil
	local coins: Coins.CoinsSystem? = nil
	local keepers: Keepers.Keepers? = nil
	local bigFinds: BigFinds.BigFinds? = nil
	local slots: Slots.Slots? = nil
	local saving: Saving.SavingSystem? = nil
	local closing = false

	-- Puts `kept` into `player`'s save and writes it, or holds them until it loads. `chipped`: the
	-- names among them with cracked glass, each worth half (F-G1e5e, `Save.chip`).
	local function store(player: Player, kept: { string }, chipped: { string })
		local s = saving
		local data = if s then s:data(player) else nil
		if not (s and data) then
			local held = waiting[player] or { kept = {}, chipped = {} }
			table.move(kept, 1, #kept, #held.kept + 1, held.kept)
			table.move(chipped, 1, #chipped, #held.chipped + 1, held.chipped)
			waiting[player] = held
			return
		end
		-- each lands on the shelf at home too, its first empty spot (D-284; every home is small
		-- until the sizes come, S5-03h)
		Save.keep(data, kept, os.time(), #Home.Specs.Shelf.Spots)
		Save.chip(data, chipped)
		task.spawn(function()
			s:save(player)
		end)
	end

	-- Writes each player's save in `touched` (one still here), all in the same step.
	local function writeAll(touched: { [Player]: true })
		local s = saving
		if not s then
			return
		end
		for player in touched do
			if player.Parent then
				task.spawn(function()
					s:save(player)
				end)
			end
		end
	end

	local function ending(
		name: string,
		how: Taken.How,
		cracked: boolean,
		torn: boolean
	): Taken.Ending
		return {
			name = name,
			how = how,
			cracked = cracked,
			torn = torn,
			now = os.time(),
			spots = SPOTS,
		}
	end

	-- `rider` carried friends' finds taken up aboard as a gate shut: theirs now, struck off each
	-- owner's save in the same step (D-302).
	local function settleMoved(rider: Player, moved: { Slots.Moved })
		local s = saving
		if not s then
			return
		end
		local theirs = s:data(rider)
		local touched: { [Player]: true } = {}
		for _, m in moved do
			local owner = s:leaving(m.home)
			if theirs then
				Taken.settle(ending(m.name, Taken.Hows.Aboard, m.cracked, m.torn), owner, theirs)
				touched[rider] = true
			else
				-- their save hasn't loaded: held with the rest they kept, struck off its owner's now
				-- torn on the climb, it's theirs plain (D-427)
				local kept = if m.torn then Seal.base(m.name) or m.name else m.name
				store(rider, { kept }, if m.cracked then { kept } else {})
				Taken.settle(ending(m.name, Taken.Hows.Lost, m.cracked, m.torn), owner, nil)
			end
			local ownerPlayer = Players:GetPlayerByUserId(m.home)
			if ownerPlayer then
				touched[ownerPlayer] = true
			end
		end
		writeAll(touched)
	end

	-- A find taken up was lost on the climb or is back in its owner's box (Slots' `taken`). Settled
	-- on the server's next step, so a server stopping settles nothing (D-302): it steps no more.
	-- A stop removes everyone before its close begins, with no step between (seen in Studio,
	-- S5-03d3, D-305), so settling within that frame struck a find as the server stopped. A real
	-- leave still settles a frame on, in time for their save's last write (the store answers later).
	local function onTaken(t: Slots.Taken)
		task.spawn(function()
			RunService.Heartbeat:Wait()
			local s = saving
			if closing or not s then
				return
			end
			local owner = s:leaving(t.home)
			if not owner then
				return
			end
			local fate = Taken.settle(ending(t.name, t.how, t.cracked, t.torn), owner, nil)
			local player = Players:GetPlayerByUserId(t.home)
			if player and (fate == "Lost" or (fate == "Back" and (t.cracked or t.torn))) then
				writeAll({ [player] = true })
			end
			if RunService:IsStudio() then
				print(`GatePay: {t.name} out of {t.home}'s job box: {fate}`)
			end
		end)
	end

	local function onShut(event: Climbs.Shut)
		local c, sl = coins, slots
		if not (c and sl) then
			return
		end
		-- the monsters shut in as the gate hits its post, the same for every rider
		local k = keepers
		local trapped = if k then k:trappedOn(event.from.model) else 0
		-- the version the team picked for the floor pays its share more (S4-03c1); on your screen
		-- its card pops last and bursts into those coins (S4-03c2), so the remote says which
		local version = event.from.version
		local picked = if version then NextFloor.payOf(version, event.from.number) else nil
		local versionName = if version then version.name else ""
		-- who is paid for the floor: aboard, alive, not wrapped
		local paidRiders: { Player } = {}
		for _, player in event.riders do
			if player.Parent and alive(player) and not Prompts.wrapped(player) then
				table.insert(paidRiders, player)
			end
		end
		-- the floor's big find counts in a paid rider's arms (S4-05b3), or set down on the car's
		-- floor with one aboard (S4-05b4), taken up off it now for its keeper; else it's left behind
		local b = bigFinds
		local big = if b then b:aboard(event.from.model, paidRiders) else nil
		local keeper = if big then big.keeper else nil
		local setDown: string?, setDownChipped = nil, false
		if keeper and big and big.lying then
			setDown, setDownChipped = sl:takeUp(big.lying)
			if not setDown then
				keeper = nil -- picked up or lost in the same frame: as it was, left behind
			end
		end
		local counted = keeper ~= nil
		local bigCoins = if counted then Pay.bigOf(event.from.number) else nil
		local bigKey = if big then big.key else ""
		for _, player in event.riders do
			if not table.find(paidRiders, player) then
				continue -- wrapped (or gone): nothing for this floor
			end
			local mine = paid[player] or {}
			paid[player] = mine
			local owed = Pay.owed(mine, event.from.number, false, trapped, picked, bigCoins)
			local kept, chipped, moved = sl:keep(player)
			if player == keeper and setDown then
				-- the big find they set down in the car, kept as one held
				table.insert(kept, setDown)
				if setDownChipped then
					table.insert(chipped, big and big.key or setDown)
				end
			end
			-- everything that rose out of their slots, a friend's taken-up finds too
			local shown = kept
			if #moved > 0 then
				shown = table.clone(kept)
				for _, m in moved do
					table.insert(shown, m.name)
				end
			end
			if owed == 0 and #shown == 0 then
				continue
			end
			if remote then
				local paidIt = owed > 0
				remote:FireClient(
					player,
					owed,
					shown,
					if paidIt then trapped else 0,
					if paidIt then versionName else "",
					if paidIt then picked or 0 else 0,
					if paidIt then bigKey else "",
					if paidIt then bigCoins or 0 else 0
				)
			end
			c:pay(player, owed)
			if #kept > 0 then
				store(player, kept, chipped)
			end
			if #moved > 0 then
				settleMoved(player, moved)
			end
			if #shown > 0 then
				-- the climb's own finds, each cracked one marked (as many as `chipped` names)
				local cracks: { [string]: number } = {}
				for _, name in chipped do
					cracks[name] = (cracks[name] or 0) + 1
				end
				local found: { Tally.Find } = {}
				for _, name in kept do
					local left = cracks[name] or 0
					cracks[name] = left - 1
					table.insert(found, {
						userId = player.UserId,
						key = name,
						cracked = if left > 0 then true else nil,
					})
				end
				keptSignal:fire({
					player = player,
					finds = shown,
					floor = event.from.number,
					found = found,
				})
			end
			if RunService:IsStudio() then
				local list = if #shown > 0 then table.concat(shown, ", ") else "no finds"
				local found = if bigKey == ""
					then "no big find"
					elseif counted and setDown then `the {bigKey} set down aboard`
					elseif counted then `the {bigKey} aboard`
					else `the {bigKey} left behind`
				print(
					`GatePay: {player.Name} paid {owed} for floor {event.from.number} ({trapped} shut in, {found}), kept {list}`
				)
			end
		end
	end

	local system = { name = "GatePay", kept = keptSignal }

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		coins = (registry:get("coins") :: any) :: Coins.CoinsSystem
		keepers = (registry:get("keepers") :: any) :: Keepers.Keepers -- any: as above
		bigFinds = (registry:get("bigFinds") :: any) :: BigFinds.BigFinds -- any: as above
		slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
		saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
		local climbs = (registry:get("climbs") :: any) :: Climbs.Climbs -- any: as above

		local folder = ReplicatedStorage:FindFirstChild(Pay.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Pay.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local r = Instance.new("RemoteEvent")
		r.Name = Pay.Remote
		r.Parent = folder
		remote = r

		table.insert(signals, climbs.shut:connect(onShut))
		table.insert(signals, (slots :: Slots.Slots).taken:connect(onTaken))
		table.insert(
			signals,
			climbs.began:connect(function()
				table.clear(paid) -- a new climb: every floor pays again
			end)
		)
		local s = saving :: Saving.SavingSystem
		table.insert(
			signals,
			s.loaded:connect(function(each: Saving.Loaded)
				local held = waiting[each.player]
				if held then
					waiting[each.player] = nil
					store(each.player, held.kept, held.chipped)
				end
			end)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				paid[player] = nil
				waiting[player] = nil
			end)
		)
	end

	function system.stop(_: any)
		closing = true -- the server stopping: nothing taken up is settled from here (D-302)
		for _, s in signals do
			s:disconnect()
		end
		table.clear(signals)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		if remote then
			remote:Destroy()
			remote = nil
		end
	end

	return system
end

return GatePay
