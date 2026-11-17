--!strict
--[[
	Decorating: each held home's paint, paper and floor (S5-03g2b, D-326; idea 18, Animal
	Crossing's wallpaper and flooring), and its door's colour (S5-03g3a, D-329; idea 18, Animal
	Crossing's house front). The moment: you pick a paper and it rolls round the room from the back
	wall to the door, for you and every friend in there; it's still up after a rejoin. Pick Mustard
	and your door rolls mustard down its slats, and the whole hall sees whose door it is.

	A home wears its look on its own panels (Home.fbx's PanelFloor, PanelLeft, PanelBack,
	PanelRight, PanelFront, `Specs.Panels`), laid over the lobby's shared walls and floor only once
	the home's look isn't a new home's: the walls' four when its paint or paper is picked, the floor
	when its floor is. Each wears a clone of its set's swatch's SurfaceAppearance (`Specs.Swatches`:
	a game script can't write a SurfaceAppearance's maps) and the paint or floor colour as its part
	Color (Overlay). They cast no shadow, and clicks and the screen's rays pass through them.

	PickLook(kind, id) (`Looks.Remote`) is rate-limited before its payload is read, then checked
	for type and length (`Looks.ask`), then judged (`Looks.pick`: a look of that kind, a floor
	colour of the chosen floor's own) for the asker's own home only. Every look is free for now
	(D-326). The pick goes into the save at once; the unit takes the new look in `Looks.Attribute`
	with the wipe's start, and the panels change `Looks.Wipe` seconds later, under the screens'
	wipes (LooksView), then `Looks.WornAttribute` says so. A pick during a wipe starts it again.

	The door goes apart from the room (D-329): a door pick puts its id in `Looks.DoorAttribute`,
	every screen rolls the colour down the slats (LooksView, RollUpDoor.paint), and the server
	paints the door itself `Looks.DoorAfter` seconds on (`Home.paintDoor`), on its own timer, so a
	door pick never restarts a wall's wipe. A home let go goes back to clay.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Arranged = require(ReplicatedStorage.Shared.Home.Arranged)
local Holding = require(ReplicatedStorage.Shared.Home.Holding)
local Home = require(ReplicatedStorage.Shared.Home)
local Looks = require(ReplicatedStorage.Shared.Home.Looks)
local Specs = require(ReplicatedStorage.Shared.Home.Specs)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local FrontOffice = require(script.Parent.FrontOffice)
local Saving = require(script.Parent.Saving)

-- One held home: its unit and frame, what it wears, its panels once laid (walls, floor), and
-- the change waiting for its wipe to cross the room.
type Held = {
	unit: Model,
	frame: CFrame,
	chosen: Looks.Chosen,
	folder: Folder,
	walls: { MeshPart },
	floor: { MeshPart },
	pending: thread?,
	doorPending: thread?, -- the door's paint, waiting for every screen's roll
}

local Decorating = {}

local ATTRIBUTES = {
	Looks.Attribute,
	Looks.SinceAttribute,
	Looks.WornAttribute,
	Looks.FrameAttribute,
	Looks.DoorAttribute,
}

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

-- The panel `spec` laid in the unit at `frame`, bare (its set and colour come with `wear`).
local function panel(template: Model, spec: Specs.Panel, frame: CFrame, folder: Folder): MeshPart?
	local source = template:FindFirstChild(spec.Part, true)
	if not (source and source:IsA("MeshPart")) then
		return nil
	end
	local p = source:Clone()
	for _, d in p:GetChildren() do
		d:Destroy()
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.CFrame = frame * CFrame.new(vec(spec.At)) * CFrame.Angles(0, math.rad(spec.Turn), 0)
	p.Parent = folder
	return p
end

-- Dresses `parts` in `wear`: the set's swatch's SurfaceAppearance and the part's colour.
local function wear(template: Model, parts: { MeshPart }, w: Looks.Wear)
	local swatch = template:FindFirstChild(Specs.Swatches[w.set] or "", true)
	local look = if swatch then swatch:FindFirstChildOfClass("SurfaceAppearance") else nil
	local colour = if w.colour ~= "" then Color3.fromHex(w.colour) else Color3.new(1, 1, 1)
	for _, p in parts do
		local old = p:FindFirstChildOfClass("SurfaceAppearance")
		if old then
			old:Destroy()
		end
		if look then
			look:Clone().Parent = p
		end
		p.Color = colour
	end
end

export type DecoratingSystem = Brix.System

function Decorating.new(): DecoratingSystem
	local homes: { [Player]: Held } = {}
	local connections: { RBXScriptConnection } = {}
	local signals: { Brix.SignalConnection } = {}
	local plotWatch: { [Player]: RBXScriptConnection } = {}
	local made: { Instance } = {}
	local limit = Brix.RateLimit.bucket(Looks.Limit)
	local frontOffice: FrontOffice.FrontOffice? = nil
	local saving: Saving.SavingSystem? = nil

	-- `player`'s home unit and its frame, if they hold one.
	local function unitOf(player: Player): (Model?, CFrame?)
		local plot = player:GetAttribute("Plot")
		local n = if type(plot) == "string" then Holding.number(plot) else nil
		local laid = if frontOffice then frontOffice:laid() else nil
		local slot = if n then Arrange.slot(n) else nil
		local unit = if n and laid then laid.units[n] else nil
		if not (unit and slot and laid) then
			return nil, nil
		end
		return unit, Arranged.face(laid.pivot, slot.Door, slot.Out)
	end

	-- Puts the home's panels in what it has chosen, laying any it needs first.
	local function dress(home: Held)
		local template = Home.template()
		if not template then
			return
		end
		local start = Looks.start()
		local wallsOff, floorOff = Looks.changes(start, home.chosen)
		if wallsOff and #home.walls == 0 then
			for _, spec in Specs.Panels.Walls do
				local p = panel(template, spec, home.frame, home.folder)
				if p then
					table.insert(home.walls, p)
				end
			end
		end
		if floorOff and #home.floor == 0 then
			local p = panel(template, Specs.Panels.Floor, home.frame, home.folder)
			if p then
				table.insert(home.floor, p)
			end
		end
		local walls, floor = Looks.wear(home.chosen)
		wear(template, home.walls, walls)
		wear(template, home.floor, floor)
		home.unit:SetAttribute(Looks.WornAttribute, Looks.encode(home.chosen))
	end

	local function clear(player: Player)
		local home = homes[player]
		if not home then
			return
		end
		homes[player] = nil
		if home.pending then
			task.cancel(home.pending)
		end
		if home.doorPending then
			task.cancel(home.doorPending)
		end
		home.folder:Destroy()
		Home.paintDoor(home.unit, Home.Paint.Door) -- let go: clay again, as every spare home is
		for _, name in ATTRIBUTES do
			home.unit:SetAttribute(name, nil)
		end
		CollectionService:RemoveTag(home.unit, Looks.Tag)
	end

	-- Dresses `player`'s home from their save, once it has loaded and they hold a unit; anew
	-- when they're handed another.
	local function lay(player: Player)
		local data = if saving then saving:data(player) else nil
		local unit, frame = unitOf(player)
		local have: Held? = homes[player]
		if have and have.unit ~= unit then
			clear(player)
			have = nil
		end
		if have or not (data and unit and frame and player.Parent) then
			return
		end
		local folder = Instance.new("Folder")
		folder.Name = Looks.Folder
		folder.Parent = unit
		local home: Held = {
			unit = unit,
			frame = frame,
			chosen = Looks.tidy(data.looks),
			folder = folder,
			walls = {},
			floor = {},
			pending = nil,
			doorPending = nil,
		}
		homes[player] = home
		dress(home)
		Home.paintDoor(unit, Color3.fromHex(Looks.doorOf(home.chosen.door)))
		unit:SetAttribute(Looks.DoorAttribute, home.chosen.door) -- before the tag: no roll on a join
		unit:SetAttribute(Looks.FrameAttribute, frame)
		unit:SetAttribute(Looks.Attribute, Looks.encode(home.chosen))
		CollectionService:AddTag(unit, Looks.Tag)
	end

	-- `player` picks `id` for `kind` in their own home. "" when it's taken (or already worn),
	-- else why not.
	local function pick(player: Player, kind: Looks.Kind, id: string): string
		local home = homes[player]
		local data = if saving then saving:data(player) else nil
		if not (home and data) then
			return Spots.Refusals.NotYours
		end
		local after = Looks.pick(home.chosen, kind, id)
		if not after then
			return "notALook"
		end
		local before = home.chosen
		if Looks.same(after, before) then
			return ""
		end
		home.chosen = after
		data.looks = table.clone(after) -- the autosave and the leave keep it
		if after.door ~= before.door then
			home.unit:SetAttribute(Looks.DoorAttribute, after.door) -- every screen rolls it
			if home.doorPending then
				task.cancel(home.doorPending)
			end
			home.doorPending = task.delay(Looks.DoorAfter, function()
				home.doorPending = nil
				if homes[player] == home then
					Home.paintDoor(home.unit, Color3.fromHex(Looks.doorOf(home.chosen.door)))
				end
			end)
			return ""
		end
		home.unit:SetAttribute(Looks.SinceAttribute, Workspace:GetServerTimeNow())
		home.unit:SetAttribute(Looks.Attribute, Looks.encode(after))
		if home.pending then
			task.cancel(home.pending)
		end
		home.pending = task.delay(Looks.Wipe, function()
			home.pending = nil
			if homes[player] == home then
				dress(home)
			end
		end)
		return ""
	end

	local function onPick(player: Player, kind: unknown, id: unknown)
		if not limit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local k, i = Looks.ask(kind, id)
		if k and i then
			pick(player, k :: Looks.Kind, i) -- the solver widens the refined kind back to a string
		end
	end

	local function watch(player: Player)
		plotWatch[player] = player:GetAttributeChangedSignal("Plot"):Connect(function()
			lay(player)
		end)
		lay(player)
	end

	return {
		name = "Decorating",
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			frontOffice = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice
			saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above

			local folder = ReplicatedStorage:FindFirstChild(Spots.RemoteFolder)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = Spots.RemoteFolder
				folder.Parent = ReplicatedStorage
			end
			local remote = Instance.new("RemoteEvent")
			remote.Name = Looks.Remote
			remote.Parent = folder
			table.insert(made, remote)
			table.insert(connections, remote.OnServerEvent:Connect(onPick))

			-- Studio only: `ServerStorage.LookTest:Invoke(player, kind, id)` picks as the screen
			-- does, unthrottled, and answers "" or the refusal; `:Invoke(player)` answers the
			-- save's look encoded, and its door. No client reaches it.
			if RunService:IsStudio() then
				local test = Instance.new("BindableFunction")
				test.Name = "LookTest"
				-- any: a BindableFunction's arguments, checked here as a remote's are
				test.OnInvoke = function(player: any, kind: any, id: any): ...any
					if not (typeof(player) == "Instance" and player:IsA("Player")) then
						return nil
					end
					if kind == nil then
						local data = if saving then saving:data(player) else nil
						if not data then
							return nil
						end
						return Looks.encode(data.looks), data.looks.door
					end
					local k, i = Looks.ask(kind, id)
					return if k and i then pick(player, k :: Looks.Kind, i) else "badAsk"
				end
				test.Parent = ServerStorage
				table.insert(made, test)
			end

			local s = saving :: Saving.SavingSystem
			table.insert(
				signals,
				s.loaded:connect(function(each: Saving.Loaded)
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
			for player in homes do
				clear(player)
			end
			for _, m in made do
				m:Destroy()
			end
			table.clear(made)
		end,
	}
end

return Decorating
