--!strict
--[[
	Furnishing: the counter's furniture bought for cash (S5-03g4a, D-333; idea 19). The moment:
	back from a climb with cash, this week's pieces are at the counter and you buy the camp bed;
	it's yours, saved, waiting in your job box. Precedents: Animal Crossing's Nook's Cranny and
	Fortnite's item shop (a stock that changes), Lethal Company's ship store (bought with the run's
	pay). The pieces, the weekly stock and the buy's rules are `Home.Furniture`'s.

	`BuyFurniture` (`Furniture.Remote`, a piece's id) is rate-limited before its payload is read,
	then checked: a short string naming a piece (`Furniture.ask`), then this week's stock, the cap
	and the buyer's cash (`Furniture.buy`). One buy at a time per player: a second while the first's
	write is out is answered "busy". A buy takes the price and adds the piece in one step, so any
	write of the save from that moment (this one, the autosave, a leave) holds both or neither;
	then the save is written at once, and only once the write is answered is the buyer told
	(`Furniture.BoughtRemote`: the id, their cash, how many they own, and "" or why not). A write
	that fails undoes the buy whole (`Furniture.unbuy`), and the buyer is told "save": never a
	piece shown as yours that a rejoin would take away, never cash gone with nothing for it.

	`FurnitureShelf` (`Furniture.ShelfRemote`, a RemoteFunction, rate-limited) answers the counter's
	screen (FurnitureTab, S5-03g4b) the asker's cash and owned pieces; it works the stock out
	itself. In Studio, `ServerStorage.FurnitureTest:Invoke(player, id)` buys as
	the remote does, unthrottled, and answers "" or the refusal; `:Invoke(player)` answers this
	week's stock, the save's cash and its furniture.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brix = require(ReplicatedStorage.Brix)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local Saving = require(script.Parent.Saving)

local REMOTE_FOLDER = "Remotes"
local STUDIO_TEST = "FurnitureTest"

local Furnishing = {}

export type FurnishingSystem = Brix.System

function Furnishing.new(): FurnishingSystem
	local connections: { RBXScriptConnection } = {}
	local made: { Instance } = {}
	local limit = Brix.RateLimit.bucket(Furniture.Limit)
	local shelfLimit = Brix.RateLimit.bucket(Furniture.ShelfLimit)
	local saving: Saving.SavingSystem? = nil
	local bought: RemoteEvent? = nil
	local buying: { [Player]: true } = {} -- a buy's write is out

	-- Buys piece `id` for `player`: "" once bought and written, else why not.
	local function buy(player: Player, id: string): string
		local s = saving
		local data = if s then s:data(player) else nil
		if not (s and data) then
			return "notLoaded"
		end
		if buying[player] then
			return "busy"
		end
		local refusal = Furniture.buy(data, id, os.time())
		if refusal then
			return refusal
		end
		buying[player] = true
		local problem = s:save(player) -- yields while the store answers
		buying[player] = nil
		if problem then
			Furniture.unbuy(data, id) -- undone whole: the next write keeps neither
			warn(`Furnishing: {player.Name}'s {id} undone, the save wasn't written: {problem}`)
			return "save"
		end
		if RunService:IsStudio() then
			print(
				`Furnishing: {player.Name} bought a {id}, cash now {data.cash}, owns {data.furniture[id]}`
			)
		end
		return ""
	end

	local function onBuy(player: Player, value: unknown)
		if not limit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local id = Furniture.ask(value)
		if not id then
			return
		end
		local answer = buy(player, id)
		local data = if saving then saving:data(player) else nil
		local remote = bought
		if remote and player.Parent then
			remote:FireClient(
				player,
				id,
				if data then data.cash else 0,
				if data then data.furniture[id] or 0 else 0,
				answer
			)
		end
	end

	return {
		name = "Furnishing",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			saving = (context.registry:get("saving") :: any) :: Saving.SavingSystem

			local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = REMOTE_FOLDER
				folder.Parent = ReplicatedStorage
			end
			local ask = Instance.new("RemoteEvent")
			ask.Name = Furniture.Remote
			ask.Parent = folder
			local answer = Instance.new("RemoteEvent")
			answer.Name = Furniture.BoughtRemote
			answer.Parent = folder
			bought = answer
			local shelf = Instance.new("RemoteFunction")
			shelf.Name = Furniture.ShelfRemote
			shelf.OnServerInvoke = function(player: Player): Furniture.Shelf?
				if not shelfLimit:take(player, os.clock()) then
					return nil
				end
				local data = if saving then saving:data(player) else nil
				return if data then Furniture.shelf(data) else nil
			end
			shelf.Parent = folder
			table.insert(made, ask)
			table.insert(made, answer)
			table.insert(made, shelf)
			table.insert(connections, ask.OnServerEvent:Connect(onBuy))

			-- Studio only (see the header). No client reaches it.
			if RunService:IsStudio() then
				local test = Instance.new("BindableFunction")
				test.Name = STUDIO_TEST
				-- any: a BindableFunction's arguments, checked here as a remote's are
				test.OnInvoke = function(player: any, id: any): ...any
					if not (typeof(player) == "Instance" and player:IsA("Player")) then
						return nil
					end
					if id == nil then
						local data = if saving then saving:data(player) else nil
						return table.concat(Furniture.stock(os.time()), ","),
							if data then data.cash else nil,
							if data then data.furniture else nil
					end
					local piece = Furniture.ask(id)
					return if piece then buy(player, piece) else "unknown"
				end
				test.Parent = ServerStorage
				table.insert(made, test)
			end

			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					limit:forget(player)
					shelfLimit:forget(player)
					buying[player] = nil
				end)
			)
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, m in made do
				m:Destroy()
			end
			table.clear(made)
			bought = nil
		end,
	}
end

return Furnishing
