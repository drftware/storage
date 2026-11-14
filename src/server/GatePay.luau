--!strict
--[[
	GatePay (S1-06, GDD "When the gate shuts"): pay and keeping as a floor's gate shuts, a system.
	The moment it serves: the gate slams with you aboard, coins pour into your count, and the
	boombox in your slot is yours for good as it leaves the slot.

	The instant a floor's gate hits its post with friends aboard (Climbs' `shut`), each rider who is
	alive and not wrapped is paid the floor's coins (`Pay.owed`: the same for everyone, a little
	more each floor, once a floor a climb) into their count (Coins' `pay`), and the finds in their
	slots are kept (Slots' `keep`): out of the slots and into their save (`Save.keep`), which is
	written at once, since a find kept is worth keeping. A wrapped rider gets nothing for the floor
	(GDD "Earning nothing"), and keeps the finds in their slots for a later gate, if they have any.

	Each paid rider's screen is told what they got (`Pay.Remote`: coins, then the kept finds' keys)
	before their count changes, so the coins are already on their way when it rises (CoinView) and
	each kept find rises out of its slot (KeepView). A rider whose save hasn't loaded yet (only just
	joined) has their kept finds held here and added the moment it loads, so nothing kept is lost.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Pay = require(ReplicatedStorage.Shared.Pay)
local Save = require(ReplicatedStorage.Shared.Save)
local Climbs = require(script.Parent.Climbs)
local Coins = require(script.Parent.Coins)
local Prompts = require(script.Parent.Prompts)
local Saving = require(script.Parent.Saving)
local Slots = require(script.Parent.Slots)

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
	local waiting: { [Player]: { string } } = {} -- kept finds for a save not loaded yet
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local remote: RemoteEvent? = nil
	local coins: Coins.CoinsSystem? = nil
	local slots: Slots.Slots? = nil
	local saving: Saving.SavingSystem? = nil

	-- Puts `kept` into `player`'s save and writes it, or holds them until it loads.
	local function store(player: Player, kept: { string })
		local s = saving
		local data = if s then s:data(player) else nil
		if not (s and data) then
			local held = waiting[player] or {}
			table.move(kept, 1, #kept, #held + 1, held)
			waiting[player] = held
			return
		end
		Save.keep(data, kept, os.time())
		task.spawn(function()
			s:save(player)
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
			local kept = sl:keep(player)
			if owed == 0 and #kept == 0 then
				continue
			end
			if remote then
				remote:FireClient(player, owed, kept)
			end
			c:pay(player, owed)
			if #kept > 0 then
				store(player, kept)
				keptSignal:fire({ player = player, finds = kept, floor = event.from.number })
			end
			if RunService:IsStudio() then
				local list = if #kept > 0 then table.concat(kept, ", ") else "no finds"
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
					store(each.player, held)
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
