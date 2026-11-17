--!strict
--[[
	Arranging: the finds each player has set out in their home (S5-03e2b, D-308). The moment: you set
	your lava lamp on the job box and it stays there, for you and every friend who walks in, after a
	rejoin too; a cheat can't drop it in a wall or in a friend's unit. Precedents: Bloxburg's build
	mode (floor, wall and tabletop items), Animal Crossing's things on tables.

	Each held home gets one Brix Placements (D-306), the judge of every move: the room's areas from
	its slot's inside box (`Spots.room`), the shelf's and the job box's tops, and the room's own
	things stood in it first so nothing is set inside them (`Spots.blocks`: the starter pieces on the
	floor, the ceiling's lamp, the mirror). It's loaded from the save's `placed`, trimmed to what you
	own (`Spots.owned`); what no longer fits goes back in the job box and the save is written so. A
	save newer than this server is never written over: that home refuses every move (`notYours`).

	A find set out is still yours, in `finds`; `Save.boxed` takes it off the job box, so it's never
	in the box and set out at once, and nothing is ever lost: a refused or unsaved move leaves it in
	the box. Each change is written into the save's `placed` (the autosave and the leave keep it)
	and drawn in the unit: a copy of the find as a hand holds it, gilded for a Gold, inert but
	pickable (e3's screen taps it), its lights off, tagged `Spots.Tag`. Riders follow a moved find.

	The remotes (Spots' names): Place(what, on, x, y, turn) and PutAway(id), each rate-limited
	before its payload is read, then checked for type and range (`Spots.ask`, `Spots.askId`), then
	ownership (only the asker's own home, a name only while one is in their box, an id only while
	it's set out). Arranged(what, id, refusal) answers the asker: the id it now stands as and ""
	when it stood; "" and "" when one was put away.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brix = require(ReplicatedStorage.Brix)
local Arranged = require(ReplicatedStorage.Shared.Home.Arranged)
local Finds = require(ReplicatedStorage.Shared.Finds)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local Holding = require(ReplicatedStorage.Shared.Home.Holding)
local Home = require(ReplicatedStorage.Shared.Home)
local HomeSpecs = require(ReplicatedStorage.Shared.Home.Specs)
local LobbySpecs = require(ReplicatedStorage.Shared.Lobby.Specs)
local Save = require(ReplicatedStorage.Shared.Save)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local FrontOffice = require(script.Parent.FrontOffice)
local Saving = require(script.Parent.Saving)
local Slots = require(script.Parent.Slots)

-- A find as drawn: its model, and its box (`Arranged.bounds`) measured once.
type Drawn = { model: Model, size: Vector3, centre: Vector3 }

-- One held home: its unit, its judge, each area's frame, what's drawn, and whether its save is
-- newer than this server (then it's never written).
type HomeSet = {
	unit: Model,
	placements: Brix.Placements,
	frames: { [string]: CFrame },
	drawn: { [string]: Drawn },
	folder: Folder,
	stale: boolean,
}

local Arranging = {}

export type ArrangingSystem = Brix.System

-- The folder in a unit that holds what's set out in it.
local FOLDER = "Placed"

local slotOf: { [number]: LobbySpecs.Slot } = {}
for _, slot in LobbySpecs.Slots do
	slotOf[slot.Number] = slot
end

-- What's fixed in every home besides its starter pieces: the round lamp in the ceiling, and the
-- mirror leaning on the right wall (its glass on the wall, its foot on the floor).
local FIXED: { Spots.Fixed } = (function()
	local lamp = HomeSpecs.Parts.Lamp
	local m = Home.Mirror
	local wide = m.Glass[1] + 2 * m.Border
	local tall = m.Glass[2] + 2 * m.Border
	return {
		{
			id = "Lamp",
			on = "Ceiling",
			at = HomeSpecs.Lamp,
			width = lamp.Size[1],
			depth = lamp.Size[3],
		},
		{
			id = "Mirror",
			on = "RightWall",
			at = { m.At[1], tall / 2, m.At[3] },
			width = wide,
			depth = tall,
		},
		{ id = "MirrorFoot", on = "Floor", at = m.At, width = 1.5, depth = wide },
	}
end)()

-- Find `name`'s art box as Spots takes it (across, up, front to back), nil when the place lacks it.
local function boxOf(name: string): Spots.Vec?
	local box = Finds.box(Gold.base(name) or name)
	return if box then { box.Size.X, box.Size.Y, box.Size.Z } else nil
end

-- The footprint of what id `id` names (a find set out), for Brix to judge it by.
local function shapeOf(id: string): Brix.PlacementShape?
	local name = Spots.name(id)
	return if name then Spots.shape(name, boxOf(name)) else nil
end

function Arranging.new(): ArrangingSystem
	local homes: { [Player]: HomeSet } = {}
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local plotWatch: { [Player]: RBXScriptConnection } = {}
	local limit = Brix.RateLimit.bucket(Spots.Limit)
	local made: { Instance } = {}
	local answerRemote: RemoteEvent? = nil
	local frontOffice: FrontOffice.FrontOffice? = nil
	local saving: Saving.SavingSystem? = nil
	local slots: Slots.Slots? = nil

	-- `player`'s home unit and its slot, if they hold one.
	local function unitOf(player: Player): (Model?, LobbySpecs.Slot?)
		local plot = player:GetAttribute("Plot")
		local n = if type(plot) == "string" then Holding.number(plot) else nil
		local laid = if frontOffice then frontOffice:laid() else nil
		local unit = if n and laid then laid.units[n] else nil
		return unit, if n then slotOf[n] else nil
	end

	-- What `player` holds out of their box (in hands or lying somewhere), by name.
	local function outOf(player: Player): Save.Counts
		local s = slots
		return if s then s:fromBox(player) else {}
	end

	local poseFrame: (home: HomeSet, id: string) -> CFrame?

	-- The frame of area or top `on`: a room or furniture area's, or a find's own top.
	local function frameOn(home: HomeSet, on: string): CFrame?
		local frame = home.frames[on]
		if frame then
			return frame
		end
		local t = poseFrame(home, on)
		local name = Spots.name(on)
		if not (t and name) then
			return nil
		end
		local drawn = home.drawn[on]
		return Arranged.top(t, if drawn then drawn.size.Y else Spots.topHeight(boxOf(name)))
	end

	function poseFrame(home: HomeSet, id: string): CFrame?
		local pose = home.placements:poseOf(id)
		local a = if pose then frameOn(home, pose.on) else nil
		return if pose and a then Arranged.pose(a, pose.x, pose.y, pose.turn) else nil
	end

	-- Draws find `id` where it stands now (made the first time), then whatever stands on it.
	local function draw(home: HomeSet, id: string, owner: Player)
		local name = Spots.name(id)
		local t = poseFrame(home, id)
		if not (name and t) then
			return
		end
		local drawn = home.drawn[id]
		if not drawn then
			local base = Gold.base(name) -- a Gold ("Teddy:Gold") stands as its find, gilded
			local model = Tools.clone(base or name, CFrame.identity)
			if not model then
				return
			end
			if base then
				Gold.gild(model)
			end
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false -- nobody trips on a lamp or is boxed in by a shelf of them
					d.CanTouch = false
					d.CanQuery = true -- e3's screen picks it up by a tap
				elseif d:IsA("Light") then
					d.Enabled = false -- a phone's lights are few (D-308)
				elseif d:IsA("Sound") then
					d:Destroy()
				end
			end
			local size, centre = Arranged.bounds(model)
			if not (size and centre) then
				model:Destroy()
				return -- nothing to see
			end
			model.Name = id
			model:SetAttribute(Spots.IdAttribute, id)
			model:SetAttribute(Spots.OwnerAttribute, owner.UserId)
			model:AddTag(Spots.Tag)
			model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- a screen gets it whole
			drawn = { model = model, size = size, centre = centre }
			home.drawn[id] = drawn
		end
		local d = drawn :: Drawn
		d.model:PivotTo(Arranged.pivot(t, Spots.spot(name), d.size, d.centre))
		d.model.Parent = home.folder
		for _, rider in home.placements:standingOn(id) do
			draw(home, rider, owner)
		end
	end

	-- Draws what changed since the last take: placed and moved finds (and their riders), and
	-- removed ones taken away. The room's own things are never drawn.
	local function apply(home: HomeSet, owner: Player)
		for _, e in home.placements:takeEvents() do
			if e.kind == "removed" then
				local drawn = home.drawn[e.id]
				if drawn then
					drawn.model:Destroy()
					home.drawn[e.id] = nil
				end
			elseif Spots.name(e.id) then
				draw(home, e.id, owner)
			end
		end
	end

	-- Writes what's set out into `data.placed`, the room's own things left out. Never for a save
	-- newer than this server.
	local function keep(home: HomeSet, data: Save.Data)
		if home.stale then
			return
		end
		local saved = home.placements:save()
		local rows: { Save.PlacedRow } = {}
		for _, row in saved.rows do
			if Spots.name(row.id) then
				table.insert(
					rows,
					{ id = row.id, on = row.on, x = row.x, y = row.y, turn = row.turn }
				)
			end
		end
		data.placed = { form = saved.form, rows = rows }
	end

	local function clear(player: Player)
		local home = homes[player]
		if home then
			homes[player] = nil
			home.folder:Destroy()
		end
	end

	-- Sets up `player`'s home from their save, once it has loaded and they hold a unit; anew when
	-- they're handed another.
	local function lay(player: Player)
		local data = if saving then saving:data(player) else nil
		local unit, slot = unitOf(player)
		local have: HomeSet? = homes[player]
		if have and have.unit ~= unit then
			clear(player)
			have = nil
		end
		local laid = if frontOffice then frontOffice:laid() else nil
		if have or not (data and unit and slot and laid and player.Parent) then
			return
		end
		local face = Arranged.face(laid.pivot, slot.Door, slot.Out)
		local centre, size = Arranged.inside(laid.pivot, face, slot.Inside.Centre, slot.Inside.Size)
		local room = Spots.room(centre, size)
		local areas: { [string]: Brix.PlacementArea } = {}
		local frames: { [string]: CFrame } = {}
		for name, r in room do
			areas[name] = { kind = r.kind, width = r.width, depth = r.depth }
			frames[name] = Arranged.area(face, r)
		end
		local starter = unit:FindFirstChild("Starter")
		local present: { HomeSpecs.Placed } = {}
		for _, s in HomeSpecs.Starter do
			if starter and starter:FindFirstChild(s.Kind) then
				table.insert(present, s)
			end
		end
		for name, f in Spots.Furniture do
			local piece = if starter then starter:FindFirstChild(f.piece) else nil
			local part = HomeSpecs.Parts[f.part]
			if piece and piece:IsA("Model") and part then
				areas[name] = (Spots.furnitureTop(part.Size, part.Centre))
				frames[name] = Arranged.furniture(piece:GetPivot(), part.Size, part.Centre)
			end
		end
		local blocks = Spots.blocks(room, present, HomeSpecs.Pieces, HomeSpecs.Parts, FIXED)
		local placements =
			Brix.Placements.new({ areas = areas, limit = Spots.limit(Spots.Start) + #blocks })
		for _, b in blocks do
			local refusal = placements:place(b.id, b.shape, b.pose)
			if refusal then
				warn(`Arranging: the room's {b.id} doesn't stand in unit {slot.Number} ({refusal})`)
			end
		end
		local folder = Instance.new("Folder")
		folder.Name = FOLDER
		folder.Parent = unit
		local rows = Spots.owned(data.placed.rows, Save.settable(data, outOf(player)))
		local dropped = placements:load({ form = data.placed.form, rows = rows }, shapeOf)
		local home: HomeSet = {
			unit = unit,
			placements = placements,
			frames = frames,
			drawn = {},
			folder = folder,
			stale = dropped == nil,
		}
		homes[player] = home
		if dropped and (#dropped > 0 or #rows < #data.placed.rows) then
			keep(home, data) -- what no longer fits is back in the box
		end
		apply(home, player)
	end

	-- Place: sets `what` (a find's name, out of the box; or an id set out, moved) at `pose`. The id
	-- it stands as and "", or "" and the refusal.
	local function place(player: Player, what: string, pose: Brix.PlacementPose): (string, string)
		local home = homes[player]
		local data = if saving then saving:data(player) else nil
		if not (home and data) or home.stale then
			return "", Spots.Refusals.NotYours
		end
		local id = what
		if Spots.name(what) then
			if not home.placements:poseOf(what) then
				return "", "notPlaced" -- not set out: nothing of yours to move
			end
		else
			if (Save.boxed(data, outOf(player))[what] or 0) < 1 then
				return "", Spots.Refusals.NotInBox
			elseif not Tools.template(Gold.base(what) or what) then
				return "", Spots.Refusals.Unknown
			end
			id = Spots.nextId(what, function(each: string): boolean
				return home.placements:poseOf(each) ~= nil
			end)
		end
		local shape = shapeOf(id)
		local refusal = if shape then home.placements:place(id, shape, pose) else "badShape"
		if refusal then
			return "", refusal
		end
		keep(home, data)
		apply(home, player)
		return id, ""
	end

	-- PutAway: puts find `id` back in the box, whatever stands on it first. "" or the refusal.
	local function putAway(player: Player, id: string): string
		local home = homes[player]
		local data = if saving then saving:data(player) else nil
		if not (home and data) or home.stale then
			return Spots.Refusals.NotYours
		elseif not home.placements:poseOf(id) then
			return "notPlaced"
		end
		local function away(each: string)
			for _, rider in home.placements:standingOn(each) do
				away(rider)
			end
			home.placements:remove(each)
		end
		away(id)
		keep(home, data)
		apply(home, player)
		return ""
	end

	local function answer(player: Player, what: string, id: string, refusal: string)
		if answerRemote then
			answerRemote:FireClient(player, what, id, refusal)
		end
	end

	local function onPlace(
		player: Player,
		what: unknown,
		on: unknown,
		x: unknown,
		y: unknown,
		turn: unknown
	)
		if not limit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local w, pose = Spots.ask(what, on, x, y, turn)
		if w and pose then
			local id, refusal = place(player, w, pose)
			answer(player, w, id, refusal)
		end
	end

	local function onPutAway(player: Player, id: unknown)
		if not limit:take(player, os.clock()) then
			return
		end
		local w = Spots.askId(id)
		if w then
			answer(player, w, "", putAway(player, w))
		end
	end

	local function watch(player: Player)
		plotWatch[player] = player:GetAttributeChangedSignal("Plot"):Connect(function()
			lay(player)
		end)
		lay(player)
	end

	return {
		name = "Arranging",
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			frontOffice = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice
			saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
			slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above

			local folder = ReplicatedStorage:FindFirstChild(Spots.RemoteFolder)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = Spots.RemoteFolder
				folder.Parent = ReplicatedStorage
			end
			local function remote(name: string): RemoteEvent
				local r = Instance.new("RemoteEvent")
				r.Name = name
				r.Parent = folder
				table.insert(made, r)
				return r
			end
			table.insert(connections, remote(Spots.PlaceRemote).OnServerEvent:Connect(onPlace))
			table.insert(connections, remote(Spots.PutAwayRemote).OnServerEvent:Connect(onPutAway))
			answerRemote = remote(Spots.AnswerRemote)

			-- Studio only: `ServerStorage.ArrangeTest:Invoke(player, "place", what, on, x, y, turn)`
			-- asks as the screen does, unthrottled, and answers (id, refusal);
			-- `:Invoke(player, "putAway", id)` answers the refusal or ""; `:Invoke(player, "rows")`
			-- answers the save's placed rows and the job box's counts; `:Invoke(player, "relay")`
			-- sets the home up again from the save, as a rejoin does. No client reaches it.
			if RunService:IsStudio() then
				local test = Instance.new("BindableFunction")
				test.Name = "ArrangeTest"
				-- any: a BindableFunction's arguments, checked here as a remote's are
				test.OnInvoke = function(
					player: any,
					verb: any,
					a: any,
					b: any,
					c: any,
					d: any,
					e: any
				): ...any
					if not (typeof(player) == "Instance" and player:IsA("Player")) then
						return nil
					end
					if verb == "place" then
						local w, pose = Spots.ask(a, b, c, d, e)
						if not (w and pose) then
							return "", "badAsk"
						end
						return place(player, w, pose)
					elseif verb == "putAway" then
						local w = Spots.askId(a)
						return if w then putAway(player, w) else "badAsk"
					elseif verb == "rows" then
						local data = if saving then saving:data(player) else nil
						return if data then data.placed.rows else nil,
							if data then Save.boxed(data, outOf(player)) else nil
					elseif verb == "relay" then
						clear(player)
						lay(player)
						return homes[player] ~= nil
					end
					return nil
				end
				test.Parent = ServerStorage
				table.insert(made, test)
			end

			-- deferred: Shelves and GatePay hear the same load first
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
			answerRemote = nil
		end,
	}
end

return Arranging
