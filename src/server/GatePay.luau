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

	Each paid rider's screen is told what they got (`Pay.Remote`: coins, then the kept finds' keys)
	before their count changes, so the coins are already on their way when it rises (CoinView) and
	each kept find rises out of its slot (KeepView). A rider whose save hasn't loaded yet (only just
	joined) has their kept finds held here and added the moment it loads, so nothing kept is lost.

	Finds taken up out of a job box (S5-03d2, D-302, D-304) are settled here through
	`Home.Taken.settle`, every touched save written at once. One out of a friend's box carried
	aboard (Slots' `keep` hands it back apart) is the rider's now: kept into their save as any find
	and struck off its owner's in the same step. One lost on the climb (left with a floor, the
	climb over, used up, its owner gone mid-climb) is struck off its owner's save, and one back in
	its owner's box brings home its crack (Slots' `taken`). A leaving owner's strike rides in their
	save's last write (Saving's `leaving`). A server stopping settles nothing.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local Pay = require(ReplicatedStorage.Shared.Pay)
local Save = require(ReplicatedStorage.Shared.Save)
local Taken = require(ReplicatedStorage.Shared.Home.Taken)
local Climbs = require(script.Parent.Climbs)
local Coins = require(script.Parent.Coins)
local Prompts = require(script.Parent.Prompts)
local Saving = require(script.Parent.Saving)
local Slots = require(script.Parent.Slots)

-- Shelf spots a find kept walks onto at home (D-284; every home small until the sizes, S5-03h).
local SPOTS = #Home.Specs.Shelf.Spots

local GatePay = {}

-- Finds a rider kept at a floor's gate, by name, and the floor (Recording, S1-02).
export type Kept = { player: Player, finds: { string }, floor: number }

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

	local function ending(name: string, how: Taken.How, cracked: boolean): Taken.Ending
		return { name = name, how = how, cracked = cracked, now = os.time(), spots = SPOTS }
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
				Taken.settle(ending(m.name, Taken.Hows.Aboard, m.cracked), owner, theirs)
				touched[rider] = true
			else
				-- their save hasn't loaded: held with the rest they kept, struck off its owner's now
				store(rider, { m.name }, if m.cracked then { m.name } else {})
				Taken.settle(ending(m.name, Taken.Hows.Lost, m.cracked), owner, nil)
			end
			local ownerPlayer = Players:GetPlayerByUserId(m.home)
			if ownerPlayer then
				touched[ownerPlayer] = true
			end
		end
		writeAll(touched)
	end

	-- A find taken up was lost on the climb or is back in its owner's box (Slots' `taken`). Settled
	-- a step later, in the same frame: a server stopping settles nothing (D-302).
	local function onTaken(t: Slots.Taken)
		task.defer(function()
			local s = saving
			if closing or not s then
				return
			end
			local owner = s:leaving(t.home)
			if not owner then
				return
			end
			local fate = Taken.settle(ending(t.name, t.how, t.cracked), owner, nil)
			local player = Players:GetPlayerByUserId(t.home)
			if player and (fate == "Lost" or (fate == "Back" and t.cracked)) then
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
		for _, player in event.riders do
			if not (player.Parent and alive(player)) or Prompts.wrapped(player) then
				continue -- wrapped (or gone): nothing for this floor
			end
			local mine = paid[player] or {}
			paid[player] = mine
			local owed = Pay.owed(mine, event.from.number, false)
			local kept, chipped, moved = sl:keep(player)
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
				remote:FireClient(player, owed, shown)
			end
			c:pay(player, owed)
			if #kept > 0 then
				store(player, kept, chipped)
			end
			if #moved > 0 then
				settleMoved(player, moved)
			end
			if #shown > 0 then
				keptSignal:fire({ player = player, finds = shown, floor = event.from.number })
			end
			if RunService:IsStudio() then
				local list = if #shown > 0 then table.concat(shown, ", ") else "no finds"
				print(
					`GatePay: {player.Name} paid {owed} for floor {event.from.number}, kept {list}`
				)
			end
		end
	end

	local system = { name = "GatePay", kept = keptSignal }

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		coins = (registry:get("coins") :: any) :: Coins.CoinsSystem
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
