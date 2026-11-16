--!strict
--[[
	Wearing (S3-04a): what each player wears, from their save onto their Player for every system
	and screen, a system. So far, their wrap colour: the film a keeper wraps them in is tinted it
	(KeptPlayers), so the friend who lifts their door finds them in their colour.

	The colour goes on the Player as the `WrapColour` attribute (`WrapColours.Attribute`): an offer
	name, or empty for the plain film. It's set as their save loads (a save that's already loaded
	when this starts too) and again as a wrap colour's purchase is granted, since the grant puts it
	on at once. The save stays the one record; the attribute only mirrors `WrapColours.worn`.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Save = require(ReplicatedStorage.Shared.Save)
local WrapColours = require(ReplicatedStorage.Shared.WrapColours)
local Purchasing = require(script.Parent.Purchasing)
local Saving = require(script.Parent.Saving)

local Wearing = {}

function Wearing.new(): Brix.System
	local signals: { Brix.SignalConnection } = {}

	-- Mirrors what `player` wears from their save `data` onto them.
	local function dress(player: Player, data: Save.Data)
		local worn = WrapColours.worn(data)
		if player:GetAttribute(WrapColours.Attribute) ~= worn then
			player:SetAttribute(WrapColours.Attribute, worn)
		end
	end

	local system = { name = "Wearing" }

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		local s = (registry:get("saving") :: any) :: Saving.SavingSystem
		local purchasing = (registry:get("purchasing") :: any) :: Purchasing.PurchasingSystem? -- any: as above
		table.insert(
			signals,
			s.loaded:connect(function(each: Saving.Loaded)
				dress(each.player, each.data)
			end)
		)
		if purchasing then
			table.insert(
				signals,
				purchasing.granted:connect(function(sale: Purchasing.Sale)
					if WrapColours.get(sale.offer) == nil then
						return
					end
					local data = s:data(sale.buyer)
					if data then
						dress(sale.buyer, data)
					end
				end)
			)
		end
		-- saves that loaded before this started
		for _, player in Players:GetPlayers() do
			local data = s:data(player)
			if data then
				dress(player, data)
			end
		end
	end

	function system.stop(_: any)
		for _, c in signals do
			c:disconnect()
		end
		table.clear(signals)
	end

	return system
end

return Wearing
