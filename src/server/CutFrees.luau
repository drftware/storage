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

	Free a Friend (S3-03b) is the same for a friend: a free player's press (Remotes.FreeFriend,
	carrying the friend's UserId) is checked no faster than `CutFree.AskEvery`, then that the
	UserId is a player in this server, not them, and caught now. A spare Free a Friend in the
	buyer's save frees the friend at once; otherwise the prompt goes up for that friend
	(Purchasing, the friend's save key as its recipient). The grant is a spare in the buyer's
	save; once saved, this spends it freeing the friend the sale names, counted as cut by the
	buyer. A friend already out (freed by someone, gone) leaves it waiting for the buyer's next
	press. In Studio, with no product of its name, a press frees the friend for nothing.

	Free Everyone (S3-03c) is the wipe's: once everyone's caught, ClimbEnds holds the results
	(`ClimbEnd.WaitAttribute` on Workspace) while the offer is on sale (`offers`: Free Everyone,
	or Cut Free for a player alone), and longer while a prompt from either is open (`asking`). A
	caught player's press (Remotes.FreeEveryone, carrying nothing) is checked: no faster than
	`CutFree.AskEvery`, caught now, the wipe waiting. A spare in their save frees every caught
	player at once (each cut by the buyer); otherwise the prompt goes up. The grant is a spare in
	the buyer's save, spent freeing everyone still caught, or kept for their next wipe. Nobody is
	freed once the end has begun (`ClimbEnd.Attribute`): the black is coming down, and a spare
	spent under it would be a purchase lost.
]]
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local ClimbEnd = require(ReplicatedStorage.Shared.ClimbEnd)
local CutFree = require(ReplicatedStorage.Shared.CutFree)
local Kept = require(ReplicatedStorage.Shared.Kept)
local KeptPlayers = require(script.Parent.KeptPlayers)
local Purchasing = require(script.Parent.Purchasing)
local Save = require(ReplicatedStorage.Shared.Save)
local Saving = require(script.Parent.Saving)
local Watching = require(script.Parent.Watching)

local STUDIO = RunService:IsStudio()
-- Tries, and the seconds between, at freeing someone whose Cut Free landed while they were
-- caught but not yet somewhere to be freed from (in the black while they're put in a unit).
local SETTLE_TRIES = 12
local SETTLE_WAIT = 0.5

local CutFrees = {}

export type CutFrees = Brix.System & {
	-- Whether the offer a wipe holds for is on sale now: Free Everyone, or Cut Free alone.
	offers: (self: any) -> boolean,
	-- Seconds since the newest Cut Free or Free Everyone prompt still open was put up, or nil.
	asking: (self: any) -> number?,
}

function CutFrees.new(): CutFrees
	local kept: KeptPlayers.KeptPlayers? = nil
	local watching: Watching.Watching? = nil
	local purchasing: Purchasing.PurchasingSystem? = nil
	local saving: Saving.SavingSystem? = nil
	local remote: RemoteEvent? = nil
	local friendRemote: RemoteEvent? = nil
	local everyoneRemote: RemoteEvent? = nil
	local asked: { [Player]: number } = {} -- os.clock() of each player's last press taken
	local askedFriend: { [Player]: number } = {} -- the same, for Free a Friend
	local askedEveryone: { [Player]: number } = {} -- the same, for Free Everyone
	-- os.clock() a Cut Free or Free Everyone prompt went up for each player, till it's answered
	local prompted: { [Player]: number } = {}
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local looked = math.huge -- seconds since the on-sale look, so the first step looks

	-- Whether `player` is caught now: wrapped, or out of the climb (left behind, watching the
	-- ride, being carried up).
	local function caught(player: Player): boolean
		return player:GetAttribute(Kept.Attribute) ~= nil
			or (watching ~= nil and watching:isOut(player))
	end

	-- Frees `player` from wherever they're caught, cut by `by` (themselves, or the friend who
	-- paid): whether they were.
	local function free(player: Player, by: Player): boolean
		if kept and kept:cutFree(player, by) then
			return true
		end
		return watching ~= nil and watching:cutFree(player)
	end

	-- Whether the climb's end has begun: its black is coming down, so nobody is freed under it.
	local function ending(): boolean
		return Workspace:GetAttribute(ClimbEnd.Attribute) ~= nil
	end

	-- Frees every caught player, cut by `buyer`: how many were.
	local function freeAll(buyer: Player): number
		local n = 0
		for _, p in Players:GetPlayers() do
			if caught(p) and free(p, buyer) then
				n += 1
			end
		end
		return n
	end

	-- Spends one of `buyer`'s spares of Free Everyone freeing every caught player, if they hold
	-- one and someone can be freed now: whether it did.
	local function useEveryone(buyer: Player): boolean
		local data = if saving then saving:data(buyer) else nil
		if ending() or not (data and CutFree.spares(data, CutFree.EveryoneOffer) > 0) then
			return false
		end
		local n = freeAll(buyer)
		if n == 0 then
			return false
		end
		CutFree.spend(data, CutFree.EveryoneOffer)
		local left = CutFree.spares(data, CutFree.EveryoneOffer)
		print(`[CutFrees] {buyer.Name} freed everyone ({n} freed, {left} spare Free Everyone left)`)
		return true
	end

	-- Spends one of `buyer`'s spares of `offer` on freeing `who` (themselves for Cut Free, a
	-- friend for Free a Friend), if they hold one and `who` can be freed now: whether it did.
	local function useSpare(buyer: Player, who: Player, offer: string): boolean
		local data = if saving then saving:data(buyer) else nil
		if ending() or not (data and CutFree.spares(data, offer) > 0 and free(who, buyer)) then
			return false
		end
		CutFree.spend(data, offer)
		local left = CutFree.spares(data, offer)
		if who == buyer then
			print(`[CutFrees] {buyer.Name} cut free ({left} spare left)`)
		else
			print(`[CutFrees] {buyer.Name} freed {who.Name} ({left} spare Free a Friend left)`)
		end
		return true
	end

	-- The player in this server whose save key is `key`, if any.
	local function whoseKey(key: string?): Player?
		if key == nil then
			return nil
		end
		for _, p in Players:GetPlayers() do
			if Save.key(p.UserId) == key then
				return p
			end
		end
		return nil
	end

	-- A caught player's press, from either screen: checked, then a spare spent or the prompt up.
	local function ask(player: Player)
		local t = os.clock()
		if t - (asked[player] or -math.huge) < CutFree.AskEvery then
			return
		end
		asked[player] = t
		if not caught(player) or ending() or useSpare(player, player, CutFree.Offer) then
			return
		end
		local p = purchasing
		if p and p:sells(CutFree.Offer) then
			task.spawn(function() -- the prompt yields
				local listing, refused = p:prompt(player, CutFree.Offer)
				if listing then
					prompted[player] = os.clock()
				elseif refused then
					print(`[CutFrees] no prompt for {player.Name}: {refused.reason}`)
				end
			end)
		elseif STUDIO and free(player, player) then
			print(`[CutFrees] {player.Name} cut free (Studio, no "Cut Free" product to prompt)`)
		end
	end

	-- A free player's press for a caught friend: checked, then a spare spent or the prompt up.
	local function askFriend(player: Player, value: unknown)
		local t = os.clock()
		if t - (askedFriend[player] or -math.huge) < CutFree.AskEvery then
			return
		end
		askedFriend[player] = t
		local id = CutFree.friendId(value)
		local friend = if id then Players:GetPlayerByUserId(id) else nil
		if friend == nil or friend == player or not caught(friend) then
			return
		end
		if useSpare(player, friend, CutFree.FriendOffer) then
			return
		end
		local p = purchasing
		if p and p:sells(CutFree.FriendOffer) then
			task.spawn(function() -- the prompt yields
				local listing, refused =
					p:prompt(player, CutFree.FriendOffer, Save.key(friend.UserId))
				if listing == nil and refused then
					print(`[CutFrees] no Free a Friend prompt for {player.Name}: {refused.reason}`)
				end
			end)
		elseif STUDIO and free(friend, player) then
			print(
				`[CutFrees] {player.Name} freed {friend.Name} (Studio, no "Free a Friend" product to prompt)`
			)
		end
	end

	-- A caught player's press while the wipe waits: checked, then a spare spent or the prompt up.
	local function askEveryone(player: Player)
		local t = os.clock()
		if t - (askedEveryone[player] or -math.huge) < CutFree.AskEvery then
			return
		end
		askedEveryone[player] = t
		if not caught(player) or Workspace:GetAttribute(ClimbEnd.WaitAttribute) == nil then
			return
		end
		if useEveryone(player) then
			return
		end
		local p = purchasing
		if p and p:sells(CutFree.EveryoneOffer) then
			task.spawn(function() -- the prompt yields
				local listing, refused = p:prompt(player, CutFree.EveryoneOffer)
				if listing then
					prompted[player] = os.clock()
				elseif refused then
					print(`[CutFrees] no Free Everyone prompt for {player.Name}: {refused.reason}`)
				end
			end)
		elseif STUDIO and not ending() then
			local n = freeAll(player)
			print(
				`[CutFrees] {player.Name} freed everyone ({n}; Studio, no "Free Everyone" product)`
			)
		end
	end

	-- A spare Free Everyone just saved into `buyer`'s save: spent freeing everyone caught now,
	-- trying a few times while someone's caught but not yet somewhere to be freed from; then
	-- those still in the black are freed on the same purchase. Nobody caught, it's kept.
	local function settleEveryone(buyer: Player)
		local spent = false
		for _ = 1, SETTLE_TRIES do
			if not buyer.Parent or ending() then
				break
			end
			local anyone = false
			for _, p in Players:GetPlayers() do
				anyone = anyone or caught(p)
			end
			if not anyone then
				break
			end
			if not spent then
				spent = useEveryone(buyer)
			else
				freeAll(buyer)
			end
			task.wait(SETTLE_WAIT)
		end
		if buyer.Parent and not spent then
			print(`[CutFrees] {buyer.Name}'s Free Everyone waits in their save for their next wipe`)
		end
	end

	-- A spare of `offer` just saved into `buyer`'s save: spend it freeing `who` now, trying a
	-- few times while they're caught but not yet somewhere to be freed from, or leave it there.
	local function settle(buyer: Player, who: Player?, offer: string, waits: string)
		for _ = 1, SETTLE_TRIES do
			if not buyer.Parent then
				return
			end
			if not (who and who.Parent and caught(who)) then
				break
			end
			if useSpare(buyer, who, offer) then
				return
			end
			task.wait(SETTLE_WAIT)
		end
		if buyer.Parent then
			print(`[CutFrees] {buyer.Name}'s {waits}`)
		end
	end

	-- A Cut Free or Free a Friend bought and saved: spent on freeing whoever it's for now, or
	-- kept as a spare.
	local function onGranted(sale: Purchasing.Sale)
		local buyer = sale.buyer
		prompted[buyer] = nil
		if sale.offer == CutFree.EveryoneOffer then
			task.spawn(settleEveryone, buyer)
		elseif sale.offer == CutFree.Offer then
			task.spawn(
				settle,
				buyer,
				buyer,
				CutFree.Offer,
				"Cut Free waits in their save for their next catch"
			)
		elseif sale.offer == CutFree.FriendOffer then
			-- Brix never names the buyer as their own recipient; Studio's made-up receipts may, so
			-- one player can feel a friend's purchase land on themselves
			task.spawn(
				settle,
				buyer,
				whoseKey(sale.recipient),
				CutFree.FriendOffer,
				"Free a Friend waits in their save for their next press"
			)
		end
	end

	-- The remote a press reaches, in the Remotes folder, showing its button in Studio.
	local function makeRemote(folder: Instance, name: string): RemoteEvent
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r:SetAttribute(CutFree.OnAttribute, STUDIO)
		r.Parent = folder
		return r
	end

	local system = { name = "CutFrees" }

	-- Whether the offer a wipe holds for is on sale with this many players here.
	function system.offers(_: any): boolean
		local offer = CutFree.wipeOffer(#Players:GetPlayers())
		local p = purchasing
		return STUDIO or (p ~= nil and p:sells(offer))
	end

	function system.asking(_: any): number?
		local newest: number? = nil
		for _, at in prompted do
			if newest == nil or at > newest then
				newest = at
			end
		end
		return if newest then os.clock() - newest else nil
	end

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
		local r = makeRemote(folder, CutFree.Remote)
		remote = r
		table.insert(
			connections,
			r.OnServerEvent:Connect(function(player: Player)
				ask(player)
			end)
		)
		local fr = makeRemote(folder, CutFree.FriendRemote)
		friendRemote = fr
		table.insert(
			connections,
			fr.OnServerEvent:Connect(function(player: Player, value: unknown)
				askFriend(player, value)
			end)
		)
		local er = makeRemote(folder, CutFree.EveryoneRemote)
		everyoneRemote = er
		table.insert(
			connections,
			er.OnServerEvent:Connect(function(player: Player)
				askEveryone(player)
			end)
		)
		-- a prompt closed unbought stops holding the wipe; bought, it holds till the grant lands
		-- (or `ClimbEnd.OfferPrompt` runs out, should the grant never come)
		table.insert(
			connections,
			MarketplaceService.PromptProductPurchaseFinished:Connect(
				function(userId: number, _product: number, bought: boolean)
					local who = Players:GetPlayerByUserId(userId)
					if who and not bought then
						prompted[who] = nil
					end
				end
			)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				asked[player] = nil
				askedFriend[player] = nil
				askedEveryone[player] = nil
				prompted[player] = nil
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
		local p = purchasing
		local on = STUDIO or (p ~= nil and p:sells(CutFree.Offer))
		if r:GetAttribute(CutFree.OnAttribute) ~= on then
			r:SetAttribute(CutFree.OnAttribute, on)
		end
		local fr = friendRemote
		local friendOn = STUDIO or (p ~= nil and p:sells(CutFree.FriendOffer))
		if fr and fr:GetAttribute(CutFree.OnAttribute) ~= friendOn then
			fr:SetAttribute(CutFree.OnAttribute, friendOn)
		end
		local er = everyoneRemote
		local everyoneOn = STUDIO or (p ~= nil and p:sells(CutFree.EveryoneOffer))
		if er and er:GetAttribute(CutFree.OnAttribute) ~= everyoneOn then
			er:SetAttribute(CutFree.OnAttribute, everyoneOn)
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
		table.clear(askedFriend)
		table.clear(askedEveryone)
		table.clear(prompted)
		if everyoneRemote then
			everyoneRemote:Destroy()
			everyoneRemote = nil
		end
		if remote then
			remote:Destroy()
			remote = nil
		end
		if friendRemote then
			friendRemote:Destroy()
			friendRemote = nil
		end
	end

	return system
end

return CutFrees
