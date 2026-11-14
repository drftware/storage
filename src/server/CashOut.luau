--!strict
--[[
	CashOut (S1-12, the GDD's "Coins, cash and finds"): the coins you didn't spend become cash you
	keep, a system. The moment it serves: the climb ends, and when the black lifts in the lobby the
	board on the car's wall counts up the cash your saved coins made (CarResults); it's yours for good.

	As a climb ends (ClimbEnds' `ended`, once an end), every coin count stops where it is (Coins'
	`close`, which hands each count over only once a climb, so a second end can't pay twice) and each
	player's coins turn into cash (`Cash.from`). It goes straight into their save (`Save.earn`) and
	the save is written at once, so it's kept whatever happens next: a player who leaves before the
	results go up, or mid-count, has their save let go with the cash in it; a server that shuts down
	writes every save it holds first (Saving). A player whose save hasn't loaded yet (only just
	joined) has their cash held here and added the moment it loads.

	Each player's cash goes on them (`Cash.EarnedAttribute`) for ClimbEnds to pin on the results
	board beside their photo; the end clears it. The coin counts stay on screen through the end, so
	the last gate's pay still lands in them, and go as the end covers every screen (Coins' `clear`).
	`cashed` fires for each player who made any (Recording, S1-02).

	A climb that never ends for someone (they leave mid-climb, or the server shuts down under it)
	turns nothing into cash: the coins only ever counted inside the climb (D-151).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Cash = require(ReplicatedStorage.Shared.Cash)
local Save = require(ReplicatedStorage.Shared.Save)
local ClimbEnds = require(script.Parent.ClimbEnds)
local Coins = require(script.Parent.Coins)
local Saving = require(script.Parent.Saving)

local CashOut = {}

-- A player's coins turned into cash as a climb ended: the coins, the cash, their saved total after
-- (nil while their save is still loading), and the floor the climb ended on.
export type Cashed = {
	player: Player,
	coins: number,
	cash: number,
	total: number?,
	floor: number,
}

export type CashOutSystem = Brix.System & {
	-- Fires for each player whose coins made cash as a climb ended, once it's in their save.
	cashed: Brix.Signal<Cashed>,
}

function CashOut.new(): CashOutSystem
	local cashedSignal = Brix.Signal.new() :: Brix.Signal<Cashed>
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local waiting: { [Player]: Cashed } = {} -- cash for a save not loaded yet
	local coins: Coins.CoinsSystem? = nil
	local saving: Saving.SavingSystem? = nil

	-- Puts `each.cash` into its player's save and writes it, or holds it until the save loads.
	local function store(each: Cashed)
		local s = saving
		local data = if s then s:data(each.player) else nil
		if not (s and data) then
			local held = waiting[each.player]
			if held then
				held.coins += each.coins
				held.cash += each.cash
				held.floor = each.floor
			else
				waiting[each.player] = each
			end
			return
		end
		each.total = Save.earn(data, each.cash)
		task.spawn(function()
			s:save(each.player)
		end)
		cashedSignal:fire(each)
		if RunService:IsStudio() then
			print(
				`CashOut: {each.player.Name}'s {each.coins} coins made {Cash.text(each.cash)}, now {Cash.text(
					each.total or 0
				)}`
			)
		end
	end

	local function onEnded(ended: ClimbEnds.Ended)
		local c = coins
		if not c then
			return
		end
		local counts = c:close() -- empty if this climb's counts were already handed over
		if next(counts) == nil then
			return
		end
		for _, ending in ended.endings do
			local player = ending.player
			local left = counts[player] or 0
			local cash = Cash.from(left)
			player:SetAttribute(Cash.EarnedAttribute, cash)
			if cash > 0 then
				store({ player = player, coins = left, cash = cash, floor = ended.floor })
			end
		end
	end

	local system = { name = "CashOut", cashed = cashedSignal }

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		coins = (registry:get("coins") :: any) :: Coins.CoinsSystem
		saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
		local ends = (registry:get("climbEnds") :: any) :: ClimbEnds.ClimbEndsSystem -- any: as above

		table.insert(signals, ends.ended:connect(onEnded))
		table.insert(
			signals,
			ends.covered:connect(function()
				local c = coins
				if c then
					c:clear()
				end
			end)
		)
		local s = saving :: Saving.SavingSystem
		table.insert(
			signals,
			s.loaded:connect(function(each: Saving.Loaded)
				local held = waiting[each.player]
				if held then
					waiting[each.player] = nil
					store(held)
				end
			end)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				waiting[player] = nil -- gone before their save loaded: no save to put it in
			end)
		)
	end

	function system.stop(_: any)
		for _, connection in signals do
			connection:disconnect()
		end
		table.clear(signals)
		for _, connection in connections do
			connection:Disconnect()
		end
		table.clear(connections)
		table.clear(waiting)
	end

	return system
end

return CashOut
