--!strict
--[[
	Shelves: stands what each player has brought home on their home's shelf (S5-03c1b, D-284). The
	moment: your door goes up after a climb and the finds you kept stand in the shelf's cubbies,
	sparkling, with nothing to press. Precedents: Animal Crossing's museum, Lethal Company's ship
	shelf, Fortnite's locker marking what's new.

	A player's home is the unit for their `Plot` attribute (Brix's PlayerPlots, FrontOffice), and its
	shelf their Shelf row as Arranging draws it (S5-03i1b, D-346); the finds stand in it, so they
	go wherever it's set, and come back when it's set out again. Each spot of their save's `shelf` (Save.keep lands a kept find on
	the first empty one) gets a copy of that find, inert, fitted into its cubby (Shelf.fit: shrunk,
	never grown, its bottom on the board), tagged Shelf.Tag with its spot, its owner and how new it
	is. It's laid when the save loads, when they're handed a home, and each time GatePay keeps finds
	for them (on the climb: it's there when they come home); it goes when they leave.

	Every screen sparkles the new ones (ShelfView). Your own screen plays the walk-up and asks
	Seen(spot) (Shelf.Remote): checked for its type and range, that the spot holds a new find of
	yours, that you stand within reach of it, and rate-limited; then the save marks it seen
	(Save.seen) and the find stops sparkling for everyone. The autosave keeps that.

	Each find in a cubby has a Take button (S5-03i2a, D-350; Takes), shown on its holder's screen
	only. A press counts only from the shelf's holder, rate-limited, within reach, not wrapped,
	with a hand free (else it's ignored): the copy is stamped taken (every screen flies it into
	their hand), the cubby is emptied (`Save.unshelf`) and the find goes into their hands out of
	their box (`Slots:unbox`) in the same step, so it's never lost or doubled.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brix = require(ReplicatedStorage.Brix)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local HomeSpecs = require(ReplicatedStorage.Shared.Home.Specs)
local Save = require(ReplicatedStorage.Shared.Save)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local Tools = require(ReplicatedStorage.Shared.Tools)
local GatePay = require(script.Parent.GatePay)
local Saving = require(script.Parent.Saving)
local Slots = require(script.Parent.Slots)
local Takes = require(script.Parent.Takes)

-- The home's pieces as Arranging draws them (any: its type would require it, and it requires
-- the systems that require this one).
type Pieces = {
	drawn: Brix.Signal<Player>,
	pieceOf: (self: any, player: Player, kind: string) -> Model?,
}

-- One player's shelf as laid: the shelf piece, and the find standing on each spot.
type Standing = { shelf: Model, finds: { [number]: Model } }

local Shelves = {}

export type ShelvesSystem = Brix.System & {
	-- Fires each time a player's home finds are laid from their save (it loaded, they were handed
	-- a home, a gate or the test hook kept finds for them): the job box follows it (JobBoxes).
	laid: Brix.Signal<Player>,
	-- Lays `player`'s shelf from their save now: a find shelved from the job box (JobBoxes).
	lay: (self: any, player: Player) -> (),
	-- Where spot `i` of `player`'s home shelf is in the world, or nil when they hold no home.
	spot: (self: any, player: Player, i: number) -> Vector3?,
}

local SPOTS = HomeSpecs.Shelf.Spots
local ROOM = HomeSpecs.Shelf.Room

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

-- Spot `i`'s place on `shelf`: its middle on its board, square to the shelf, front out.
local function spotAt(shelf: Model, i: number): CFrame
	return shelf:GetPivot() * CFrame.new(vec(SPOTS[i]) + Vector3.new(0, Shelf.Lift, 0))
end

-- Find `key` standing in a cubby at `at` (Shelf.fit), inert and still: a copy as a hand holds it,
-- its lights off (a find on a shelf isn't switched on, and a phone's lights are few). Not parented.
local function stand(key: string, at: CFrame): Model?
	local base = Gold.base(key) -- a Gold ("Teddy:Gold") stands as its find, gilded
	local model = Tools.clone(base or key, CFrame.identity)
	if not model then
		return nil
	end
	if base then
		Gold.gild(model) -- solid gold, catching the bulb's light
	end
	local pivot = model:GetPivot()
	local low = Vector3.one * math.huge
	local high = -low
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			if d.Transparency < 1 then
				local cf = pivot:ToObjectSpace(d.CFrame)
				local h = d.Size / 2
				for _, x in { -1, 1 } do
					for _, y in { -1, 1 } do
						for _, z in { -1, 1 } do
							local p = cf * Vector3.new(h.X * x, h.Y * y, h.Z * z)
							low = low:Min(p)
							high = high:Max(p)
						end
					end
				end
			end
		elseif d:IsA("Light") then
			d.Enabled = false
		elseif d:IsA("Sound") then
			d:Destroy()
		end
	end
	if low.X > high.X then
		model:Destroy()
		return nil -- nothing to see
	end
	local fit = Shelf.fit({ low.X, low.Y, low.Z }, { high.X, high.Y, high.Z }, ROOM)
	if fit.scale < 1 then
		model:ScaleTo(model:GetScale() * fit.scale)
	end
	model:PivotTo(at * CFrame.Angles(0, math.rad(fit.turn), 0) * CFrame.new(vec(fit.offset)))
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- a screen gets it whole or not at all
	return model
end

function Shelves.new(): ShelvesSystem
	local laidSignal = Brix.Signal.new() :: Brix.Signal<Player>
	local standing: { [Player]: Standing } = {}
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local plotWatch: { [Player]: RBXScriptConnection } = {}
	local limit = Brix.RateLimit.bucket(Shelf.Limit)
	local remote: RemoteEvent? = nil
	local shelfTest: BindableFunction? = nil
	local saving: Saving.SavingSystem? = nil
	local slots: Slots.Slots? = nil
	local pieces: Pieces? = nil
	local take: (player: Player, i: number, model: Model) -> ()

	-- `player`'s home shelf: their Shelf row as drawn in the unit they hold, if it's set out.
	local function shelfOf(player: Player): Model?
		return if pieces then pieces:pieceOf(player, "Shelf") else nil
	end

	local function clear(player: Player)
		local st: Standing? = standing[player]
		if st then
			standing[player] = nil
			for _, model in st.finds do
				model:Destroy()
			end
		end
	end

	-- Lays `player`'s shelf from their save: each spot's find stood (or kept, when it's already
	-- there), how new it is brought up to date, and any find no longer there taken away.
	local function lay(player: Player)
		local data = if saving then saving:data(player) else nil
		local shelf = shelfOf(player)
		local st: Standing? = standing[player]
		if st and st.shelf ~= shelf then
			clear(player)
			st = nil
		end
		if not (data and shelf and player.Parent) then
			return
		end
		local mine: Standing = st or { shelf = shelf, finds = {} }
		standing[player] = mine
		for i = 1, #SPOTS do
			local saved = data.shelf[i]
			local key = if saved then saved.find else ""
			local have: Model? = mine.finds[i]
			if have and have:GetAttribute(Tools.KindAttribute) ~= key then
				have:Destroy()
				mine.finds[i] = nil
				have = nil
			end
			if saved and key ~= "" then
				if have then
					have:SetAttribute(Shelf.FreshAttribute, saved.fresh)
				else
					local model = stand(key, spotAt(shelf, i))
					if model then
						model.Name = `ShelfFind{i}`
						model:SetAttribute(Shelf.SpotAttribute, i)
						model:SetAttribute(Shelf.OwnerAttribute, player.UserId)
						model:SetAttribute(Shelf.FreshAttribute, saved.fresh)
						model:AddTag(Shelf.Tag)
						Takes.offer(model, function(by: Player)
							take(by, i, model)
						end)
						model.Parent = shelf
						mine.finds[i] = model
					end
				end
			end
		end
		laidSignal:fire(player)
	end

	-- Seen(spot): `player` walked up to the new find on their shelf's spot `spot`.
	local function seen(player: Player, spot: unknown)
		if not limit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local i = Shelf.spot(spot, #SPOTS)
		local st: Standing? = standing[player]
		local model = if i and st then st.finds[i] else nil
		local data = if saving then saving:data(player) else nil
		if not (i and st and model and data) then
			return
		end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if not (root and root:IsA("BasePart")) then
			return
		end
		if (root.Position - spotAt(st.shelf, i).Position).Magnitude > Shelf.Reach + Shelf.Slack then
			return -- not near it: a screen can't mark finds seen from across the floor
		end
		if Save.seen(data, i) then
			model:SetAttribute(Shelf.FreshAttribute, Save.Fresh.Seen)
		end
	end

	-- Take on the find standing on spot `i` (`model`), pressed by `player`: only their own.
	function take(player: Player, i: number, model: Model)
		if not limit:take(player, os.clock()) then
			return
		end
		local st: Standing? = standing[player]
		local data = if saving then saving:data(player) else nil
		local saved = if data then data.shelf[i] else nil
		local s = slots
		if
			not (st and data and saved and s and st.finds[i] == model)
			or saved.find == ""
			or not Takes.near(player, model)
			or not s:room(player)
		then
			return -- a friend's press, a far one, or full hands: nothing happens
		end
		local name = saved.find
		st.finds[i] = nil
		Takes.leave(model, player)
		Save.unshelf(data, i, name)
		s:unbox(player, name)
		lay(player)
	end

	local function watch(player: Player)
		plotWatch[player] = player:GetAttributeChangedSignal("Plot"):Connect(function()
			lay(player)
		end)
		lay(player)
	end

	return {
		name = "Shelves",
		laid = laidSignal,
		lay = function(_: any, player: Player)
			lay(player)
		end,
		spot = function(_: any, player: Player, i: number): Vector3?
			local shelf = shelfOf(player)
			return if shelf and SPOTS[i] then spotAt(shelf, i).Position else nil
		end,
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
			local gatePay = (registry:get("gatePay") :: any) :: GatePay.GatePaySystem -- any: as above
			local arranging = (registry:get("arranging") :: any) :: Pieces -- any: as above
			slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
			pieces = arranging

			local folder = ReplicatedStorage:FindFirstChild(Shelf.RemoteFolder)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = Shelf.RemoteFolder
				folder.Parent = ReplicatedStorage
			end
			local r = Instance.new("RemoteEvent")
			r.Name = Shelf.Remote
			r.Parent = folder
			remote = r
			table.insert(connections, r.OnServerEvent:Connect(seen))

			-- Studio only: `ServerStorage.ShelfTest:Invoke(player, key)` keeps find `key` for
			-- `player` as a gate does (Save.keep), so a test sees it land without a climb;
			-- `ShelfTest:Invoke(player, "", i)` empties cubby `i`, its find back in the job box, so
			-- a test can shelve one; `ShelfTest:Invoke(player, "take", i)` presses cubby `i`'s Take
			-- as `player` (true when it came off). A BindableFunction on the server: no client
			-- reaches it.
			if RunService:IsStudio() then
				local test = Instance.new("BindableFunction")
				test.Name = "ShelfTest"
				-- any: a BindableFunction's arguments, checked here
				test.OnInvoke = function(player: any, key: any, spot: any): boolean
					local data = if saving
							and typeof(player) == "Instance"
							and player:IsA("Player")
						then saving:data(player)
						else nil
					if data and key == "take" and type(spot) == "number" then
						local st: Standing? = standing[player]
						local model = if st then st.finds[spot] else nil
						if model then
							take(player, spot, model)
						end
						return model ~= nil and (data.shelf[spot] or { find = "" }).find == ""
					end
					if data and key == "" and type(spot) == "number" then
						local cubby = data.shelf[spot]
						if not (cubby and cubby.find ~= "") then
							return false
						end
						cubby.find = ""
						lay(player)
						return true
					end
					if not (data and type(key) == "string" and Tools.template(key)) then
						return false
					end
					Save.keep(data, { key }, os.time(), #SPOTS)
					lay(player)
					return true
				end
				test.Parent = ServerStorage
				shelfTest = test
			end

			-- deferred: GatePay hears the same load first and lands what it held for them
			local s = saving :: Saving.SavingSystem
			table.insert(
				signals,
				s.loaded:connect(function(each: Saving.Loaded)
					task.defer(lay, each.player)
				end)
			)
			-- the shelf drawn, moved or put away (S5-03i1b): its finds follow it
			table.insert(signals, arranging.drawn:connect(lay))
			table.insert(
				signals,
				gatePay.kept:connect(function(each: GatePay.Kept)
					task.defer(lay, each.player)
				end)
			)
			table.insert(connections, Players.PlayerAdded:Connect(watch))
			for _, player in Players:GetPlayers() do
				watch(player)
			end
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					local w = plotWatch[player]
					if w then
						w:Disconnect()
						plotWatch[player] = nil
					end
					clear(player)
					limit:forget(player)
				end)
			)
		end,
		stop = function(_: any)
			for _, s in signals do
				s:disconnect()
			end
			table.clear(signals)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for _, w in plotWatch do
				w:Disconnect()
			end
			table.clear(plotWatch)
			for player in standing do
				clear(player)
			end
			if remote then
				remote:Destroy()
				remote = nil
			end
			if shelfTest then
				shelfTest:Destroy()
				shelfTest = nil
			end
		end,
	}
end

return Shelves
