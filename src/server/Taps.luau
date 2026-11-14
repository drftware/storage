--!strict
--[[
	Taps: the tap when you pull a door down on a sleeping monster (S2-05a, the GDD's "The tap"), a
	system on the server's Host clock. As Dead by Daylight's skill checks: a bar comes up by itself,
	one tap in its zone.

	- A Close pressed on a door well up (`ShutTap.MinRise`) over a monster standing loose in its
	  unit, asleep or awake but not hunting the presser (`Keepers.inside`, `ShutTap.earns`), earns
	  the tap: Doors eases the door down to hang a foot up instead (Motion's "Ease") and calls
	  `begin`. One window a door and one a player: a second pull while one runs is a plain close.
	- The window is the puller's alone: a fresh zone rolled for it, sent to their screen only
	  (Remotes.ShutTap, "Open").
	- Their tap comes back on the same remote, checked in order: its type (a unit and a number);
	  its range (`ShutTap.heard`: a finite time, held to the window and a fair lag); that a window on
	  that door is theirs and still open; and no faster than `ShutTap.Gap`. The first tap decides.
	- A hit: the door settles the last foot, slow and soft (Doors' `move`, "Settle"), unheard by
	  keepers; the monster sleeps on. A miss, or no tap by the bar's end and a late tap's trip
	  (`ShutTap.due`): the monster wakes shut in and pounds (`Keepers.wakeShut`), and the door drops
	  with a slam's bang (`move`, "Drop") that the floor's other keepers hear as a slam. The screen
	  is told which ("Done").
	- The door going another way first ends the window: a slam is the miss's bang, so its monster
	  wakes shut in the same; anything else (opened again, lifted from inside) just ends it ("Gone").
	  The puller leaving lets the door settle quietly.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Doors = require(script.Parent.Doors)
local Keepers = require(script.Parent.Keepers)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local ShutTap = require(ReplicatedStorage.Shared.StorageUnit.ShutTap)

local TRACE = RunService:IsStudio() -- Output says each tap's window and what decided it

type Window = {
	unit: Model,
	player: Player,
	start: number, -- the pull, on the server's clock
	zone: number, -- the zone's left edge along the bar (ShutTap.zone)
}

export type Taps = Brix.System & {
	-- Whether `player` pulling `unit`'s door down now earns the tap (Doors asks before a Close).
	earns: (self: any, unit: Model, player: Player) -> boolean,
	-- `unit`'s door has started easing down for `player`: their window opens now.
	begin: (self: any, unit: Model, player: Player) -> (),
}

local Taps = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

function Taps.new(): Taps
	local windows: { [Model]: Window } = {}
	local mine: { [Player]: Window } = {}
	local lastTap: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local signals: { Brix.SignalConnection } = {}
	local random = Random.new()
	local remote: RemoteEvent? = nil
	local doors: Doors.Doors? = nil
	local keepers: Keepers.Keepers? = nil
	local landing = false -- this system is moving a door itself: its own `acted` isn't news

	local function close(w: Window)
		windows[w.unit] = nil
		if mine[w.player] == w then
			mine[w.player] = nil
		end
	end

	local function tell(w: Window, what: string, hit: boolean?)
		local r = remote
		if r and w.player.Parent == Players then
			r:FireClient(w.player, what, w.unit, hit)
		end
	end

	-- What decided it: the door settles soft on a hit; on a miss its monster wakes shut in, then the
	-- door drops with a bang (woken first, so it's trapped and doesn't count its own door's bang).
	local function land(w: Window, result: ShutTap.Result, why: string)
		close(w)
		local d, k = doors, keepers
		local woke = false
		landing = true
		if result == "Hit" then
			if d then
				d:move(w.unit, "Settle")
			end
		else
			woke = k ~= nil and k:wakeShut(w.unit)
			if d then
				d:move(w.unit, "Drop")
			end
		end
		landing = false
		tell(w, "Done", result == "Hit")
		if TRACE then
			local wakes = if result == "Hit"
				then "it settles soft"
				elseif woke then "it bangs down and the monster wakes pounding"
				else "it bangs down"
			print(`Taps: {w.player.Name}'s tap on {w.unit.Name}: {result} ({why}); {wakes}`)
		end
	end

	local function onTap(player: Player, unit: unknown, claimed: unknown)
		-- type first: whatever a screen sends
		if typeof(unit) ~= "Instance" or type(claimed) ~= "number" then
			return
		end
		local t = now()
		local last = lastTap[player]
		if last and t - last < ShutTap.Gap then
			return
		end
		lastTap[player] = t
		-- theirs, and still open
		local w = windows[unit :: Model]
		if not w or w.player ~= player then
			return
		end
		-- range: held to the window and a fair lag
		local at = ShutTap.heard(w.start, t, claimed)
		if not at then
			return
		end
		local tapped = at - w.start
		land(w, ShutTap.judge(w.zone, tapped), `tapped {math.floor(tapped * 100) / 100} s in`)
	end

	-- A door with a window moved some other way first (not this system's own landing): a slam is
	-- the miss's bang; anything else ends the window with nothing more.
	local function onActed(event: Doors.DoorEvent)
		local w = windows[event.unit]
		if landing or not w or event.motion == "Ease" or event.motion == nil then
			return
		end
		close(w)
		if event.motion == "Slam" then
			local k = keepers
			if k then
				k:wakeShut(w.unit)
			end
			tell(w, "Done", false)
		else
			tell(w, "Gone")
		end
		if TRACE then
			print(`Taps: {w.unit.Name}'s door went another way ({event.motion}); its tap is over`)
		end
	end

	local system = { name = "Taps" }

	function system.earns(_: any, unit: Model, player: Player): boolean
		local k = keepers
		if not k or windows[unit] or mine[player] or not unit.Parent then
			return false
		end
		local asleep, saw = k:inside(unit, player)
		return ShutTap.earns(asleep, saw, RollUpDoor.rise(unit, now()))
	end

	function system.begin(_: any, unit: Model, player: Player)
		if windows[unit] or mine[player] then
			return
		end
		local w: Window = {
			unit = unit,
			player = player,
			start = now(),
			zone = ShutTap.zone(random:NextNumber()),
		}
		windows[unit] = w
		mine[player] = w
		local r = remote
		if r then
			r:FireClient(player, "Open", unit, w.start, w.zone)
		end
		if TRACE then
			print(
				`Taps: {player.Name} pulls {unit.Name}'s door down over a monster; the bar's zone is at {math.floor(
					w.zone * 100
				)}%`
			)
		end
	end

	function system.start(_: any, context: Brix.Context)
		local folder = ReplicatedStorage:FindFirstChild(ShutTap.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = ShutTap.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local r = Instance.new("RemoteEvent")
		r.Name = ShutTap.Remote
		r.Parent = folder
		remote = r
		table.insert(connections, r.OnServerEvent:Connect(onTap))
		-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
		doors = (context.registry:get("doors") :: any) :: Doors.Doors?
		keepers = (context.registry:get("keepers") :: any) :: Keepers.Keepers? -- any: as above
		local d = doors
		if d then
			table.insert(signals, d.acted:connect(onActed))
		end
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				lastTap[player] = nil
				local w = mine[player]
				if w then
					-- nobody left to tap: it settles, and nobody pays for a dropped connection
					land(w, "Hit", "the puller left")
				end
			end)
		)
	end

	-- Only while a window is open: one past its bar and a late tap's trip is a miss.
	function system.step(_: any, _dt: number)
		if next(windows) == nil then
			return
		end
		local t = now()
		for unit, w in windows do
			if not unit.Parent then
				close(w)
			elseif ShutTap.due(w.start, t) then
				land(w, "Miss", "no tap")
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, c in signals do
			c:disconnect()
		end
		table.clear(signals)
		table.clear(windows)
		table.clear(mine)
		table.clear(lastTap)
		local r = remote
		if r then
			r:Destroy()
			remote = nil
		end
	end

	return system
end

return Taps
