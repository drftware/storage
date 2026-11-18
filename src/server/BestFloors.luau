--!strict
--[[
	BestFloors (S6-01a, D-432): your best floor and your badges, a system. The moment it serves:
	you ride the car up onto floor 10 for the first time and Roblox's own badge toast pops, as
	DOORS' and Pressure's milestone badges do; back in the lobby the dial over your car and the
	plaque beside it read your best (S6-01b, from the `BestFloor` attribute set here).

	- A floor reached raises the best floor in your save (`Save.reached`): as the car carrying you
	  arrives on it (Climbs' `handedOff`), and at the climb's end on the floor you were lost on
	  (ClimbEnds' `ended`: a team caught on floor 1 has still reached it).
	- As a gate shuts, every rider aboard and standing free (as the gate pays them, GatePay) gets
	  the kinds of monster the team shut in on that floor stamped in their book (`Save.trapped`).
	- Each player's `Badges.BestAttribute` (their best floor, replicated to every screen) is set as
	  their save loads and each time it rises.
	- Badges: on load and after each of those, every badge the save has earned (`Badges.earned`)
	  that has an id (`Badges.Ids`, the owner's) and hasn't been sent this visit goes to Roblox:
	  asked first whether they hold it (`UserHasBadgeAsync`), awarded if not (`AwardBadge`), one
	  player at a time, off the step. A failure warns once and is tried again next visit. A badge
	  earned before its id was filled in is awarded the next time they play.
	- In Studio nothing is sent: Output says each badge earned this visit and each new best.

	Everything here is the server's: no remote, nothing a screen can ask for.
]]
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Badges = require(ReplicatedStorage.Shared.Badges)
local Brix = require(ReplicatedStorage.Brix)
local ClimbEnds = require(script.Parent.ClimbEnds)
local Climbs = require(script.Parent.Climbs)
local Keepers = require(script.Parent.Keepers)
local Prompts = require(script.Parent.Prompts)
local Rows = require(ReplicatedStorage.Shared.Finds.Rows)
local Save = require(ReplicatedStorage.Shared.Save)
local Saving = require(script.Parent.Saving)

-- Every set of finds, by name, worked out once.
local SETS = Badges.sets(Rows)

local BestFloors = {}

export type BestFloorsSystem = Brix.System & {}

-- Whether the player stands free in the world (not caught, not wrapped): a rider the gate pays.
local function free(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and not Prompts.wrapped(player)
end

function BestFloors.new(): BestFloorsSystem
	local studio = RunService:IsStudio()
	local saving: Saving.SavingSystem? = nil
	local keepers: Keepers.Keepers? = nil
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	-- The badges each player has been sent, found held, or seen earned this visit, by key.
	local done: { [Player]: { [string]: boolean } } = {}
	-- A player whose badges are being sent now, and one whose save changed meanwhile.
	local busy: { [Player]: boolean } = {}
	local again: { [Player]: boolean } = {}

	-- Sends whatever `player` has earned and not been sent this visit. Yields: run it off the step.
	local function send(player: Player)
		local s = saving
		local data = if s then s:data(player) else nil
		if not data then
			return
		end
		local sent = done[player]
		if not sent then
			sent = {}
			done[player] = sent
		end
		local earned = Badges.earned(data.bestFloor, data.stamps.finds, data.stamps.keepers, SETS)
		local awards = Badges.toAward(earned, Badges.Ids, sent)
		for _, key in earned do
			if not sent[key] then
				sent[key] = true
				if studio then
					local id = Badges.Ids[key] or 0
					local note = if id > 0 then "" else " (no badge id yet)"
					print(`BestFloors: {player.Name} has earned the {key} badge{note}`)
				end
			end
		end
		if studio then
			return
		end
		for _, award in awards do
			if not player.Parent then
				return
			end
			local asked, has =
				pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, award.id)
			if asked and has == true then
				continue
			end
			local given, result =
				pcall(BadgeService.AwardBadge, BadgeService, player.UserId, award.id)
			if not given or result ~= true then
				warn(`BestFloors: the {award.key} badge ({award.id}) wasn't awarded: {result}`)
			end
		end
	end

	-- Sends `player`'s badges off the step; one run at a time each, run again if asked meanwhile.
	local function check(player: Player)
		if busy[player] then
			again[player] = true
			return
		end
		busy[player] = true
		task.spawn(function()
			repeat
				again[player] = nil
				send(player)
			until not again[player] or not player.Parent
			busy[player] = nil
		end)
	end

	-- `player` reached floor `floor`: a new best is saved, shown and may earn a badge.
	local function reached(player: Player, floor: number)
		local s = saving
		local data = if s then s:data(player) else nil
		if not data or not Save.reached(data, floor) then
			return
		end
		player:SetAttribute(Badges.BestAttribute, data.bestFloor)
		if studio then
			print(`BestFloors: {player.Name}'s best floor is now {data.bestFloor}`)
		end
		check(player)
	end

	local system = { name = "BestFloors" }

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		saving = (registry:get("saving") :: any) :: Saving.SavingSystem
		keepers = (registry:get("keepers") :: any) :: Keepers.Keepers -- any: as above
		local climbs = (registry:get("climbs") :: any) :: Climbs.Climbs -- any: as above
		local ends = (registry:get("climbEnds") :: any) :: ClimbEnds.ClimbEndsSystem -- any: as above
		local s = saving :: Saving.SavingSystem

		table.insert(
			signals,
			s.loaded:connect(function(each: Saving.Loaded)
				each.player:SetAttribute(Badges.BestAttribute, each.data.bestFloor)
				check(each.player)
			end)
		)
		table.insert(
			signals,
			climbs.handedOff:connect(function(event: Climbs.HandOff)
				for _, player in event.riders do
					reached(player, event.to.number)
				end
			end)
		)
		table.insert(
			signals,
			climbs.shut:connect(function(event: Climbs.Shut)
				-- read now, while the floor's keepers stand where the team shut them in
				local k = keepers
				local kinds = if k then k:trappedKindsOn(event.from.model) else {}
				local stamp = os.time()
				for _, player in event.riders do
					local data = s:data(player)
					if data and player.Parent and free(player) then
						if #kinds > 0 then
							Save.trapped(data, kinds, stamp)
						end
						-- after the gate's pay has kept their finds (GatePay, on this same shut)
						task.defer(check, player)
					end
				end
			end)
		)
		table.insert(
			signals,
			ends.ended:connect(function(event: ClimbEnds.Ended)
				for _, ending in event.endings do
					if ending.player.Parent then
						reached(ending.player, ending.floor)
					end
				end
			end)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				done[player] = nil
				again[player] = nil
			end)
		)
	end

	function system.stop(_: any)
		for _, sig in signals do
			sig:disconnect()
		end
		table.clear(signals)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
	end

	return system
end

return BestFloors
