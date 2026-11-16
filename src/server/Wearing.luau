--!strict
--[[
	Wearing (S3-04a): what each player wears, from their save onto their Player for every system
	and screen, a system. So far, their wrap colour: the film a keeper wraps them in is tinted it
	(KeptPlayers), so the friend who lifts their door finds them in their colour.

	The colour goes on the Player as the `WrapColour` attribute (`WrapColours.Attribute`): an offer
	name, or empty for the plain film. It's set as their save loads (a save that's already loaded
	when this starts too) and again as a wrap colour's purchase is granted, since the grant puts it
	on at once. The save stays the one record; the attribute only mirrors `WrapColours.worn`.

	The counter's shop (S3-04b, `Shop`) talks to it through three remotes in
	ReplicatedStorage.Remotes, each no faster than `Shop.AskEvery` per player and checked:
	- `ShopShelf` answers at once whether each colour's owned and what's worn, with the prices
	  Roblox last reported to that player; each ask also fetches fresh ones in the background
	  (Purchasing's `shelf`, which records the look at the shop), since Roblox's prices take a
	  moment and the shop mustn't wait on them. The screen asks again for a missing price.
	- `BuyWrap` takes a colour's name and puts Roblox's prompt for it up (`Purchasing.prompt`,
	  which refuses an owned one). In Studio, with no product of its title on Roblox, the press
	  hands a made-up receipt to Purchasing's `DevReceipt` instead, so the whole grant runs.
	- `WearWrap` takes an owned colour's name, or empty for the plain film, and puts it on
	  (`WrapColours.wear`); the save is written a few seconds after the last change, so a player
	  trying colours on writes once.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brix = require(ReplicatedStorage.Brix)
local Save = require(ReplicatedStorage.Shared.Save)
local Shop = require(ReplicatedStorage.Shared.Shop)
local WrapColours = require(ReplicatedStorage.Shared.WrapColours)
local Purchasing = require(script.Parent.Purchasing)
local Saving = require(script.Parent.Saving)

local STUDIO = RunService:IsStudio()
-- Seconds after a player's last change of colour that their save is written.
local SAVE_AFTER = 5

local Wearing = {}

function Wearing.new(): Brix.System
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local made: { Instance } = {}
	local asked: { [Player]: { [string]: number } } = {} -- each remote's last ask, by player
	local pending: { [Player]: thread } = {} -- a save waiting after a change of colour
	local prices: { [Player]: { [string]: number } } = {} -- what Roblox last reported, by player
	local fetching: { [Player]: true } = {} -- a fetch of their prices is out

	-- Mirrors what `player` wears from their save `data` onto them.
	local function dress(player: Player, data: Save.Data)
		local worn = WrapColours.worn(data)
		if player:GetAttribute(WrapColours.Attribute) ~= worn then
			player:SetAttribute(WrapColours.Attribute, worn)
		end
	end

	-- Whether `player` may ask `remote` now (no faster than `Shop.AskEvery`), noting the ask.
	local function may(player: Player, remote: string): boolean
		local mine = asked[player]
		if mine == nil then
			mine = {}
			asked[player] = mine
		end
		local t = os.clock()
		if t - (mine[remote] or -math.huge) < Shop.AskEvery then
			return false
		end
		mine[remote] = t
		return true
	end

	local function remotes(): Folder
		local found = ReplicatedStorage:FindFirstChild(Shop.RemoteFolder)
		if found and found:IsA("Folder") then
			return found
		end
		local folder = Instance.new("Folder")
		folder.Name = Shop.RemoteFolder
		folder.Parent = ReplicatedStorage
		return folder
	end

	local system = { name = "Wearing" }

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		local s = (registry:get("saving") :: any) :: Saving.SavingSystem
		local purchasing = (registry:get("purchasing") :: any) :: Purchasing.PurchasingSystem? -- any: as above

		-- The counter's shop: the shelf, a Buy, a Wear (Shop; each checked, as above).
		local folder = remotes()
		local shelf = Instance.new("RemoteFunction")
		shelf.Name = Shop.ShelfRemote
		shelf.OnServerInvoke = function(player: Player): Shop.Shelf?
			local data = s:data(player)
			if data == nil or not may(player, Shop.ShelfRemote) then
				return nil
			end
			local p = purchasing
			if p and not fetching[player] then
				fetching[player] = true
				task.spawn(function() -- Roblox's prices yield
					local got = p:shelf(player)
					fetching[player] = nil
					if player.Parent then
						prices[player] = got
					end
				end)
			end
			return Shop.shelf(data, prices[player] or {})
		end
		shelf.Parent = folder
		table.insert(made, shelf)

		local buy = Instance.new("RemoteEvent")
		buy.Name = Shop.BuyRemote
		buy.Parent = folder
		table.insert(made, buy)
		table.insert(
			connections,
			buy.OnServerEvent:Connect(function(player: Player, value: unknown)
				local name = Shop.name(value, false)
				local data = s:data(player)
				if name == nil or data == nil or not may(player, Shop.BuyRemote) then
					return
				end
				if WrapColours.owns(data, name) or purchasing == nil then
					return
				end
				local p = purchasing
				if p:sells(name) then
					task.spawn(function() -- the prompt yields
						local listing, refused = p:prompt(player, name)
						if listing == nil and refused then
							print(`[Wearing] no {name} prompt for {player.Name}: {refused.reason}`)
						end
					end)
				elseif STUDIO then
					-- no product of its title on Roblox: a made-up receipt runs the real grant
					local dev = ServerStorage:FindFirstChild("DevReceipt")
					if dev and dev:IsA("BindableFunction") then
						task.spawn(function()
							local answer = dev:Invoke({ PlayerId = player.UserId, offer = name })
							print(
								`[Wearing] {player.Name} bought {name} (Studio receipt: {answer})`
							)
						end)
					end
				end
			end)
		)

		local wear = Instance.new("RemoteEvent")
		wear.Name = Shop.WearRemote
		wear.Parent = folder
		table.insert(made, wear)
		table.insert(
			connections,
			wear.OnServerEvent:Connect(function(player: Player, value: unknown)
				local name = Shop.name(value, true)
				local data = s:data(player)
				if name == nil or data == nil or not may(player, Shop.WearRemote) then
					return
				end
				if WrapColours.wear(data, name) ~= nil then
					return
				end
				dress(player, data)
				local waiting = pending[player]
				if waiting then
					task.cancel(waiting)
				end
				pending[player] = task.delay(SAVE_AFTER, function()
					pending[player] = nil
					if player.Parent then
						s:save(player)
					end
				end)
			end)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				asked[player] = nil
				prices[player] = nil
				fetching[player] = nil
				-- the save is flushed as they leave (Saving), so a waiting write isn't needed
				local waiting = pending[player]
				if waiting then
					task.cancel(waiting)
					pending[player] = nil
				end
			end)
		)
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
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, i in made do
			i:Destroy()
		end
		table.clear(made)
		for _, waiting in pending do
			task.cancel(waiting)
		end
		table.clear(pending)
		table.clear(asked)
		table.clear(prices)
		table.clear(fetching)
	end

	return system
end

return Wearing
