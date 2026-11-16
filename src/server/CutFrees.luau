--!strict
--[[
	CutFrees (S3-03a): Cut Free sold and used on the server, a system. The moment it serves:
	caught, you press Cut Free, pay, and you're out at once. Wrapped in a unit, the film rips off
	you and the door hauls itself up on the hall (KeptPlayers' `cutFree`); left behind or carried
	up, you're standing in the car beside your friends as it reaches the next floor (Watching's
	`cutFree`). The GDD's "Getting caught", DOORS' revive.

	The press comes from the caught screen (ReplicatedStorage.Remotes.CutFree, carrying nothing)
	or the watch bar (Watching hands its ask over). Each is checked: no faster than
	`CutFree.AskEvery`, and only from someone caught now (wrapped, or out of the climb). Then a
	spare Cut Free in their save is spent at once with no prompt; otherwise Roblox's purchase
	prompt goes up (Purchasing). Its grant puts a spare in the save before the save is written
	(`Products`), and once it is, this spends it to free them; if they're already free (a friend
	got there first) it waits in the save for their next catch, so a purchase is never lost.

	The remote's `On` attribute (`CutFree.OnAttribute`) tells screens whether to show the button:
	on while Cut Free is on sale here (a product titled "Cut Free" exists and its live switch,
	`sellCutFree`, is on), checked every `CutFree.LookEvery`. In Studio it's always on, and with
	no product of its name to prompt a press frees you for nothing, so its moment can be felt.
	Every use prints one line in the server's log.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local Kept = require(ReplicatedStorage.Shared.Kept)
local KeptPlayers = require(script.Parent.KeptPlayers)
local Purchasing = require(script.Parent.Purchasing)
local Saving = require(script.Parent.Saving)
local Watching = require(script.Parent.Watching)

local STUDIO = RunService:IsStudio()
-- Tries, and the seconds between, at freeing someone whose Cut Free landed while they were
-- caught but not yet somewhere to be freed from (in the black while they're put in a unit).
local SETTLE_TRIES = 12
local SETTLE_WAIT = 0.5

local CutFrees = {}

function CutFrees.new(): Brix.System
	local kept: KeptPlayers.KeptPlayers? = nil
	local watching: Watching.Watching? = nil
	local purchasing: Purchasing.PurchasingSystem? = nil
	local saving: Saving.SavingSystem? = nil
	local remote: RemoteEvent? = nil
	local asked: { [Player]: number } = {} -- os.clock() of each player's last press taken
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local looked = math.huge -- seconds since the on-sale look, so the first step looks

	-- Whether `player` is caught now: wrapped, or out of the climb (left behind, watching the
	-- ride, being carried up).
	local function caught(player: Player): boolean
		return player:GetAttribute(Kept.Attribute) ~= nil
			or (watching ~= nil and watching:isOut(player))
	end

	-- Frees `player` from wherever they're caught: whether they were.
	local function free(player: Player): boolean
		if kept and kept:cutFree(player) then
			return true
		end
		return watching ~= nil and watching:cutFree(player)
	end

	-- Spends one of `player`'s spare Cut Frees on freeing them, if they hold one and can be
	-- freed now: whether it did.
	local function useSpare(player: Player): boolean
		local data = if saving then saving:data(player) else nil
		if not (data and CutFree.spares(data) > 0 and free(player)) then
			return false
		end
		CutFree.spend(data)
		print(`[CutFrees] {player.Name} cut free ({CutFree.spares(data)} spare left)`)
		return true
	end

	-- A caught player's press, from either screen: checked, then a spare spent or the prompt up.
	local function ask(player: Player)
		local t = os.clock()
		if t - (asked[player] or -math.huge) < CutFree.AskEvery then
			return
		end
		asked[player] = t
		if not caught(player) or useSpare(player) then
			return
		end
		local p = purchasing
		if p and p:sells(CutFree.Offer) then
			task.spawn(function() -- the prompt yields
				local listing, refused = p:prompt(player, CutFree.Offer)
				if listing == nil and refused then
					print(`[CutFrees] no prompt for {player.Name}: {refused.reason}`)
				end
			end)
		elseif STUDIO and free(player) then
			print(`[CutFrees] {player.Name} cut free (Studio, no "Cut Free" product to prompt)`)
		end
	end

	-- A Cut Free bought and saved: spend it on freeing the buyer now, or keep it as a spare.
	local function onGranted(sale: Purchasing.Sale)
		if sale.offer ~= CutFree.Offer then
			return
		end
		local buyer = sale.buyer
		task.spawn(function()
			for _ = 1, SETTLE_TRIES do
				if not buyer.Parent or useSpare(buyer) then
					return
				end
				if not caught(buyer) then
					break
				end
				task.wait(SETTLE_WAIT)
			end
			if buyer.Parent then
				print(`[CutFrees] {buyer.Name}'s Cut Free waits in their save for their next catch`)
			end
		end)
	end

	local system = { name = "CutFrees" }

	function system.start(_: any, context: Brix.Context)
		local registry = context.registry
		-- any: the registry hands back a plain System; each slot is filled by its system (init.server)
		kept = (registry:get("keptPlayers") :: any) :: KeptPlayers.KeptPlayers
		watching = (registry:get("watching") :: any) :: Watching.Watching -- any: as above
		purchasing = (registry:get("purchasing") :: any) :: Purchasing.PurchasingSystem -- any: as above
		saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
		local folder = ReplicatedStorage:FindFirstChild(Caught.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Caught.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local r = Instance.new("RemoteEvent")
		r.Name = CutFree.Remote
		r:SetAttribute(CutFree.OnAttribute, STUDIO)
		r.Parent = folder
		remote = r
		table.insert(
			connections,
			r.OnServerEvent:Connect(function(player: Player)
				ask(player)
			end)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				asked[player] = nil
			end)
		)
		if watching then
			watching:onCutFree(ask)
		end
		if purchasing then
			table.insert(signals, purchasing.granted:connect(onGranted))
		end
	end

	function system.step(_: any, dt: number)
		looked += dt
		local r = remote
		if looked < CutFree.LookEvery or not r then
			return
		end
		looked = 0
		local on = STUDIO or (purchasing ~= nil and purchasing:sells(CutFree.Offer))
		if r:GetAttribute(CutFree.OnAttribute) ~= on then
			r:SetAttribute(CutFree.OnAttribute, on)
		end
	end

	function system.stop(_: any)
		for _, c in signals do
			c:disconnect()
		end
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(signals)
		table.clear(connections)
		table.clear(asked)
		if remote then
			remote:Destroy()
			remote = nil
		end
	end

	return system
end

return CutFrees
