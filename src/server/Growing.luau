--!strict
--[[
	Growing: a bigger home bought for cash at the counter (S5-03h2, D-341; the home doc's ideas 30
	and 31). The moment: back from a good climb you've saved up, and the counter sells you a bigger
	unit; your cash ticks down and your home is Medium, everything you'd set out where it was.
	Bloxburg's and Adopt Me's house upgrades, Animal Crossing's house loan. The sizes and the
	sale's rules are `Home.Grow`'s and `Home.Sizes`'.

	`GrowHome` (`Grow.Remote`, a size's name) is rate-limited before its payload is read, then
	checked: a short string naming a size (`Grow.ask`), then the buyer's size and cash
	(`Grow.buy`). One sale at a time per player: a second while the first's write is out is
	answered "busy". A sale takes the price and writes the size in one step, so any write of the
	save from that moment (this one, the autosave, a leave) holds both or neither; then the save is
	written at once, and only once the write is answered is the home set up again at its new size
	(`Arranging`'s relay, which carries the rows laid at the old size) and the buyer told
	(`Grow.GrownRemote`: the size asked for, their cash, their home's size, and "" or why not). A
	write that fails undoes the sale whole (`Grow.unbuy`), and the buyer is told "save": never a
	bigger home that a rejoin would take away, never cash gone with nothing for it. Growing only
	ever writes `homeSize` (D-340): if the server stops before the relay, the next lay, on any
	server, carries the rows.

	`HomeSizeShelf` (`Grow.ShelfRemote`, a RemoteFunction, rate-limited) answers the counter's
	screen (UnitsTab) the asker's cash and home's size. In Studio,
	`ServerStorage.GrowTest:Invoke(player, name)` sells as the remote does, unthrottled, and answers
	"" or the refusal; `:Invoke(player)` answers the save's cash and home's size; `:Invoke(player,
	"cash", n)` sets the save's cash to `n` (for trying a sale) and answers it.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brix = require(ReplicatedStorage.Brix)
local Grow = require(ReplicatedStorage.Shared.Home.Grow)
local Arranging = require(script.Parent.Arranging)
local Saving = require(script.Parent.Saving)

local REMOTE_FOLDER = "Remotes"
local STUDIO_TEST = "GrowTest"

local Growing = {}

export type GrowingSystem = Brix.System

function Growing.new(): GrowingSystem
	local connections: { RBXScriptConnection } = {}
	local made: { Instance } = {}
	local limit = Brix.RateLimit.bucket(Grow.Limit)
	local shelfLimit = Brix.RateLimit.bucket(Grow.ShelfLimit)
	local saving: Saving.SavingSystem? = nil
	local arranging: Arranging.ArrangingSystem? = nil
	local grown: RemoteEvent? = nil
	local selling: { [Player]: true } = {} -- a sale's write is out

	-- Sells size `name` to `player`: "" once sold, written and the home set up at it, else why not.
	local function sell(player: Player, name: string): string
		local s = saving
		local data = if s then s:data(player) else nil
		if not (s and data) then
			return "notLoaded"
		end
		if selling[player] then
			return "busy"
		end
		local refusal, was = Grow.buy(data, name)
		if refusal then
			return refusal
		end
		selling[player] = true
		local problem = s:save(player) -- yields while the store answers
		selling[player] = nil
		if problem then
			Grow.unbuy(data, name, was) -- undone whole: the next write keeps neither
			warn(`Growing: {player.Name}'s {name} undone, the save wasn't written: {problem}`)
			return "save"
		end
		if RunService:IsStudio() then
			print(`Growing: {player.Name}'s home is {name} now, cash {data.cash}`)
		end
		if arranging and player.Parent then
			arranging:relay(player) -- the rows carried to the new size, the save written so
		end
		return ""
	end

	local function onGrow(player: Player, value: unknown)
		if not limit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local name = Grow.ask(value)
		if not name then
			return
		end
		local answer = sell(player, name)
		local data = if saving then saving:data(player) else nil
		local remote = grown
		if remote and player.Parent then
			local shelf = if data then Grow.shelf(data) else nil
			remote:FireClient(
				player,
				name,
				if shelf then shelf.cash else 0,
				if shelf then shelf.size else "",
				answer
			)
		end
	end

	return {
		name = "Growing",
		start = function(_: any, context: Brix.Context)
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			saving = (context.registry:get("saving") :: any) :: Saving.SavingSystem
			arranging = (context.registry:get("arranging") :: any) :: Arranging.ArrangingSystem

			local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = REMOTE_FOLDER
				folder.Parent = ReplicatedStorage
			end
			local ask = Instance.new("RemoteEvent")
			ask.Name = Grow.Remote
			ask.Parent = folder
			local answer = Instance.new("RemoteEvent")
			answer.Name = Grow.GrownRemote
			answer.Parent = folder
			grown = answer
			local shelf = Instance.new("RemoteFunction")
			shelf.Name = Grow.ShelfRemote
			shelf.OnServerInvoke = function(player: Player): Grow.Shelf?
				if not shelfLimit:take(player, os.clock()) then
					return nil
				end
				local data = if saving then saving:data(player) else nil
				return if data then Grow.shelf(data) else nil
			end
			shelf.Parent = folder
			table.insert(made, ask)
			table.insert(made, answer)
			table.insert(made, shelf)
			table.insert(connections, ask.OnServerEvent:Connect(onGrow))

			-- Studio only (see the header). No client reaches it.
			if RunService:IsStudio() then
				local test = Instance.new("BindableFunction")
				test.Name = STUDIO_TEST
				-- any: a BindableFunction's arguments, checked here as a remote's are
				test.OnInvoke = function(player: any, name: any, amount: any): ...any
					if not (typeof(player) == "Instance" and player:IsA("Player")) then
						return nil
					end
					if name == "cash" then
						local data = if saving then saving:data(player) else nil
						if
							data
							and type(amount) == "number"
							and amount == amount
							and amount >= 0
						then
							data.cash = math.floor(amount)
						end
						return if data then data.cash else nil
					end
					if name == nil then
						local data = if saving then saving:data(player) else nil
						return if data then data.cash else nil, if data then data.homeSize else nil
					end
					local size = Grow.ask(name)
					return if size then sell(player, size) else "unknown"
				end
				test.Parent = ServerStorage
				table.insert(made, test)
			end

			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					limit:forget(player)
					shelfLimit:forget(player)
					selling[player] = nil
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
			grown = nil
		end,
	}
end

return Growing
