--!strict
--[[
	Saving on the server (S1-01): each player's save, held by this server while they play, a system.
	Nothing shows on screen. What it buys is that everything a climb earns from here on (cash, the
	finds you keep, the collection book, your best floor; `Save` says what each is) is still yours
	when you come back, on whatever server you land.

	Built on Brix's saves: `Brix.Saves` holds each save on one server at a time (a lease written
	with the data, so two servers never both write it), `Brix.Roblox.PlayerSaves` claims a save as
	its player joins, writes it every `AUTOSAVE` seconds, lets it go as they leave and lets go of
	every save as the server closes, and `Brix.Roblox.SaveStore.dataStore` keeps them in a
	DataStore. A player whose save this server can't hold (another server still holds it past its
	lease, a save from a newer version of the game) is kicked with a line saying to rejoin, Brix's
	default, so nothing they earn is ever lost unsaved.

	Later systems read a player's save with `data(player)` (nil until it has loaded, which takes a
	moment after joining, or longer when hopping from another server that's still letting go) and
	`loaded`, change it in place, and call `save(player)` after something worth keeping at once,
	such as a purchase. Nothing changes it yet.

	Studio keeps its saves in their own DataStore, `STUDIO_STORE`, so a test never touches a live
	player's save. If Studio can't reach DataStores (Game Settings > Security > "Enable Studio
	Access to API Services" off), it keeps them in memory for the session instead, with one warning
	saying so. Studio prints one line per write (a claim, a save, a let-go), so a test can see each;
	a live server prints its claims and let-gos only, in its log (F9 > Server).
]]
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Save = require(ReplicatedStorage.Shared.Save)

-- The DataStores saves are kept in. Never rename LIVE_STORE once players have saves in it.
local LIVE_STORE = "Saves"
local STUDIO_STORE = "Saves.studio"
-- Seconds between a save's automatic writes, and how long a write holds it for this server. The
-- lease outlives a crashed server by at most this long, which is how long a player who crashed
-- with it waits to load elsewhere; Brix's defaults, 30 and 90.
local AUTOSAVE = 30
local LEASE = 90

-- A player whose save this server now holds, and its data.
export type Loaded = Brix.LoadedSave<Save.Data>

export type SavingSystem = Brix.System & {
	-- A player's save was claimed and its data is ready.
	loaded: Brix.Signal<Loaded>,
	-- A player's save while this server holds it: nil before it has loaded and after they leave.
	data: (self: any, player: Player) -> Save.Data?,
	-- Writes a player's save now, after something worth keeping at once. May yield.
	save: (self: any, player: Player) -> (),
}

local Saving = {}

-- A record's lease, read loosely: the store hands records over as plain data.
local function leaseOf(record: unknown): (string?, number?, boolean)
	if type(record) ~= "table" then
		return nil, nil, false
	end
	local lease = (record :: { [string]: unknown }).lease
	if type(lease) ~= "table" then
		return nil, nil, false
	end
	local fields = lease :: { [string]: unknown }
	local server = fields.server
	local session = fields.session
	return if type(server) == "string" then server else nil,
		if type(session) == "number" then session else nil,
		fields.released == true
end

-- What a write did to a save, in a few words: from whether a record was there, the lease it had
-- (read before the change, which may rewrite the record in place) and the record written.
local function described(
	existed: boolean,
	server: string?,
	session: number?,
	after: unknown
): string
	local afterServer, afterSession, released = leaseOf(after)
	if released then
		return "let go of"
	elseif not existed then
		return "made a new save for"
	elseif server ~= afterServer or session ~= afterSession then
		return "claimed"
	end
	return "saved"
end

-- The store with a line printed for each write: every write in Studio (Play's Output, a test's
-- proof), only claims and let-gos on a live server (its log, F9, without a line per autosave).
local function logged(inner: Brix.SaveStore, everyWrite: boolean): Brix.SaveStore
	return {
		update = function(_: any, key: string, change: Brix.SaveChange): string?
			local what, after: unknown = "", nil
			local problem = inner:update(key, function(current: unknown): unknown
				local server, session = leaseOf(current)
				local nextRecord = change(current)
				what, after = described(current ~= nil, server, session, nextRecord), nextRecord
				return nextRecord
			end)
			if problem then
				warn(`[Saving] {key}: {problem}`)
			elseif after ~= nil and (everyWrite or what ~= "saved") then
				local record = after :: { [string]: any } -- any: the record as Saves wrote it
				local data = record.data
				local cash = if type(data) == "table" then data.cash else "?"
				local best = if type(data) == "table" then data.bestFloor else "?"
				print(
					`[Saving] {what} {key} (version {record.version}, cash {cash}, best floor {best})`
				)
			end
			return problem
		end,
	}
end

-- Whether Studio may use DataStores: one read of a key nobody writes. Yields.
local function studioReachesDataStores(store: DataStore): (boolean, string?)
	local reached, err = pcall(function()
		store:GetAsync("probe")
	end)
	return reached, if reached then nil else tostring(err)
end

function Saving.new(): SavingSystem
	local loaded = Brix.Signal.new() :: Brix.Signal<Loaded>
	local playerSaves: Brix.PlayerSaves<Save.Data>? = nil
	local stopped = false
	local forward: Brix.SignalConnection? = nil

	local function begin(store: Brix.SaveStore)
		if stopped then
			return
		end
		local saves = Brix.Saves.new({
			format = Save.format(Brix),
			store = store,
			now = os.time,
			server = Brix.Roblox.serverId(),
			autosave = AUTOSAVE,
			lease = LEASE,
		})
		local made = Brix.Roblox.PlayerSaves.new({
			saves = saves,
			players = Players,
			keyFor = function(player: Player): string
				return Save.key(player.UserId)
			end,
		})
		forward = made.loaded:connect(function(each: Loaded)
			loaded:fire(each)
		end)
		playerSaves = made
		made:start()
	end

	local function dataStore(name: string): Brix.SaveStore
		return Brix.Roblox.SaveStore.dataStore({
			dataStore = DataStoreService:GetDataStore(name),
			userIds = function(key: string): { number }
				local userId = Save.userId(key)
				return if userId then { userId } else {}
			end,
		})
	end

	local system = {
		name = "Saving",
		loaded = loaded,
	}

	function system.start(_: any, _context: Brix.Context)
		if not RunService:IsStudio() then
			begin(logged(dataStore(LIVE_STORE), false))
			return
		end
		-- Studio: find out whether DataStores answer before choosing where saves go. Players who
		-- join meanwhile are claimed once it starts.
		task.spawn(function()
			local reached, problem =
				studioReachesDataStores(DataStoreService:GetDataStore(STUDIO_STORE))
			if reached then
				print(`[Saving] Studio keeps saves in the DataStore "{STUDIO_STORE}"`)
				begin(logged(dataStore(STUDIO_STORE), true))
			else
				warn(
					`[Saving] Studio can't reach DataStores, so saves last this session only. Turn on Game Settings > Security > Enable Studio Access to API Services. ({problem})`
				)
				begin(logged(Brix.SaveStore.loopback(), true))
			end
		end)
	end

	function system.stop(_: any)
		stopped = true
		if forward then
			forward:disconnect()
			forward = nil
		end
		-- PlayerSaves bound its own stop to the server's closing, which waits for every save to be
		-- let go; a system's stop mustn't yield, so this only starts it.
		local current = playerSaves
		if current then
			task.spawn(function()
				current:stop()
			end)
		end
	end

	function system.data(_: any, player: Player): Save.Data?
		local current = playerSaves
		return if current then current:data(player) else nil
	end

	function system.save(_: any, player: Player)
		local current = playerSaves
		if current then
			current:save(player)
		end
	end

	return system
end

return Saving
