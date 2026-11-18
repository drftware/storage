--!strict
--[[
	Arranging: the finds each player has set out in their home (S5-03e2b, D-308). The moment: you set
	your lava lamp on the job box and it stays there, for you and every friend who walks in, after a
	rejoin too; a cheat can't drop it in a wall or in a friend's unit. Precedents: Bloxburg's build
	mode (floor, wall and tabletop items), Animal Crossing's things on tables.

	Each held home gets one Brix Placements (D-306), the judge of every move: the room's areas from
	its slot's inside box at its size (`Arrange.room`) with the ceiling's lamp stood in it first.
	It's loaded from the save's `placed`, trimmed to what you own (`Spots.owned`); what no longer
	fits goes back in the job box and the save is written so. A save newer than this server is never
	written over: that home refuses every move (`notYours`).

	The home's own pieces (the job box, shelf, mirror, rail, rug, beanbag and floor lamp) are rows
	too (S5-03i1b, D-346), one each and free of the limit, drawn as bought pieces are: a home laid
	before them adopts them where they stood (`Layout.adopt`, then the save's `starterLaid`), a
	home that grew keeps them on their walls (`Layout.grow`), the job box always loads first and is
	never put away (`kept`). A spare's set (Lobby.front's `Starter`) is taken away while the home
	is held and put back when it's let go. `drawn` fires after each lay and change, so the shelf's
	finds, the job box's button and the rail's hangers find their piece (`pieceOf`).

	A find set out is still yours, in `finds`; `Save.boxed` takes it off the job box, so it's never
	in the box and set out at once, and nothing is ever lost: a refused or unsaved move leaves it in
	the box. Each change is written into the save's `placed` (the autosave and the leave keep it)
	and drawn in the unit: a copy of the find as a hand holds it, gilded for a Gold, inert but
	pickable (e3's screen taps it), its lights off, tagged `Spots.Tag`. Riders follow a moved find.

	The remotes (Spots' names): Place(what, on, x, y, turn) and PutAway(id), each rate-limited
	before its payload is read, then checked for type and range (`Spots.ask`, `Spots.askId`), then
	ownership (only the asker's own home, a name only while one is in their box, an id only while
	it's set out). Arranged(what, id, refusal) answers the asker: the id it now stands as and ""
	when it stood; "" and "" when one was put away. ArrangeBox (`Arrange.BoxRemote`, S5-03e3a)
	sends the asker's job box (counts by name), how many finds they have set out and the limit
	(the screen's limit bar, S5-03e3b) when the screen asks, and after every change. A find drawn
	by a move carries the server's time (`Arrange.WhenAttribute`), so another screen settles it in
	with a knock rather than letting it appear; one drawn as the home is laid carries none.
	The room's set-up is shared with the screen (`Arrange.room`), so both judge alike.

	Each find set out (not furniture, not the home's own pieces) has a Take button (S5-03i2a,
	D-350; Takes), shown on its holder's screen only. A press counts only from its holder, rate-
	limited, within reach, not wrapped, with a hand free (else it's ignored): the copy is stamped
	taken (every screen flies it into their hand), its row and whatever rides on it go back to the
	box (`Spots.lift`), and the find goes into their hands out of the box (`Slots:unbox`) in the
	same step, so it's never lost or doubled.

	In Arrange a find lifts straight out of your shelf's cubby (S5-03i2b, D-352): Place and PutAway
	carry the cubby's spot after their own words (Place(what, on, x, y, turn, spot), PutAway(what,
	spot)), `what` then the find's name as it stands there. Set down, it comes off the spot and onto
	a row in one step (`Spots.offShelf`), refused it's back in its cubby; put away, it goes into the
	box (`Save.unshelf`). Either way `drawn` fires and the shelf is laid again.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Home = require(ReplicatedStorage.Shared.Home)
local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Arranged = require(ReplicatedStorage.Shared.Home.Arranged)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local Holding = require(ReplicatedStorage.Shared.Home.Holding)
local Layout = require(ReplicatedStorage.Shared.Home.Layout)
local LobbySpecs = require(ReplicatedStorage.Shared.Lobby.Specs)
local Save = require(ReplicatedStorage.Shared.Save)
local Shelf = require(ReplicatedStorage.Shared.Home.Shelf)
local HomeSpecs = require(ReplicatedStorage.Shared.Home.Specs)
local Sizes = require(ReplicatedStorage.Shared.Home.Sizes)
local Spots = require(ReplicatedStorage.Shared.Home.Spots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local FindUses = require(script.Parent.FindUses)
local FrontOffice = require(script.Parent.FrontOffice)
local HomeUses = require(script.Parent.HomeUses)
local Saving = require(script.Parent.Saving)
local Slots = require(script.Parent.Slots)
local Takes = require(script.Parent.Takes)

-- A find as drawn: its model, and its box (`Arranged.bounds`) measured once; a starter piece's
-- kind, which stands by its spec box instead (`Arrange.starterPivot`).
type Drawn = { model: Model, size: Vector3, centre: Vector3, starter: string? }

-- One held home: its unit, its room (`Arrange.room`: its judge, each area's frame), how many
-- finds it holds set out, what's drawn, and whether its save is newer than this server (then it's
-- never written).
type HomeSet = {
	unit: Model,
	room: Arrange.Room,
	placements: Brix.Placements,
	limit: number,
	drawn: { [string]: Drawn },
	folder: Folder,
	stale: boolean,
	spare: Instance?, -- the spare's set (Lobby.front's Starter), put back when the home is let go
}

local Arranging = {}

export type ArrangingSystem = Brix.System & {
	-- Sets `player`'s home up again from their save, as a rejoin does: after its size was written
	-- (a sale at the counter, Growing; S5-03h2), so its rows are carried to the new size.
	relay: (self: any, player: Player) -> (),
	-- Fires after a player's home is laid, changed or let go (S5-03i1b): the shelf's finds, the
	-- job box's button and the rail's hangers follow their pieces (Shelves, JobBoxes, Rails).
	drawn: Brix.Signal<Player>,
	-- Starter piece `kind`'s model in `player`'s home as drawn (S5-03i1b), nil when it's put away
	-- or they hold none.
	pieceOf: (self: any, player: Player, kind: string) -> Model?,
}

local FOLDER = Arrange.Folder
local SPOTS = HomeSpecs.Shelf.Spots -- the shelf's cubbies, in order

local shapeOf = Arrange.shapeOf

function Arranging.new(): ArrangingSystem
	local homes: { [Player]: HomeSet } = {}
	local drawnSignal = Brix.Signal.new() :: Brix.Signal<Player>
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local plotWatch: { [Player]: RBXScriptConnection } = {}
	local limit = Brix.RateLimit.bucket(Spots.Limit)
	local made: { Instance } = {}
	local answerRemote: RemoteEvent? = nil
	local boxRemote: RemoteEvent? = nil
	local frontOffice: FrontOffice.FrontOffice? = nil
	local saving: Saving.SavingSystem? = nil
	local slots: Slots.Slots? = nil
	local findUses: FindUses.FindUsesSystem? = nil
	local takeOut: (player: Player, id: string, model: Model) -> ()
	local pressOut: (holder: Player, player: Player, id: string, model: Model, key: string) -> ()

	-- `player`'s home unit and its slot, if they hold one.
	local function unitOf(player: Player): (Model?, LobbySpecs.Slot?)
		local plot = player:GetAttribute("Plot")
		local n = if type(plot) == "string" then Holding.number(plot) else nil
		local laid = if frontOffice then frontOffice:laid() else nil
		local unit = if n and laid then laid.units[n] else nil
		return unit, if n then Arrange.slot(n) else nil
	end

	-- What `player` holds out of their box (in hands or lying somewhere), by name.
	local function outOf(player: Player): Save.Counts
		local s = slots
		return if s then s:fromBox(player) else {}
	end

	local function poseFrame(home: HomeSet, id: string): CFrame?
		return Arrange.poseFrame(home.room, id)
	end

	-- Makes the counter's furniture piece `kind` set out as `id` (D-336): the home's own art, as
	-- the starter set stands (`Home.piece`), every part solid as a box and pickable by a tap, its
	-- names and tag as a find's. Nil when the place's art lacks it.
	local function drawPiece(home: HomeSet, id: string, kind: string, owner: Player): Drawn?
		local template = Home.template()
		if not (template and Home.has(template, kind)) then
			return nil
		end
		local row = Furniture.byId(kind)
		local starter = row ~= nil and row.starter == true
		local model: Model
		if kind == "Mirror" then
			-- the frame leaning on its foot with its glass (MirrorView draws on it), pivoted upright
			-- at the foot so the lean rides every move; the glass knows the unit's door for the
			-- walls it stands in the picture
			local glass: Part
			model, glass = Home.mirrorAt(template, CFrame.identity, home.folder)
			model.WorldPivot = CFrame.identity
			glass:SetAttribute("Face", home.room.face)
		else
			model = Home.piece(template, kind, CFrame.identity, home.folder)
		end
		local n = tonumber(string.match(id, "#(%d+)$")) or 1
		local hung = row ~= nil and row.stands ~= "Floor" -- the string lights, the neon moon (g4d)
		local crate = Home.CrateColours[(n - 1) % #Home.CrateColours + 1] -- each crate the next colour
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") and d.Name == "MilkCrate" then
				d.Color = crate
			end
			if d:IsA("BasePart") then
				-- a bed or a shelf stops you, as the starter set's pieces do; what hangs on a wall
				-- or from the ceiling is never walked into, and its lit parts are Home.paint's; a
				-- starter piece's are Home.piece's (the rug and a seat never stop you)
				if not starter then
					d.CanCollide = not hung
				end
				d.CanTouch = false
				d.CanQuery = true
			end
		end
		local size, centre = Arranged.bounds(model)
		if not (size and centre) then
			model:Destroy()
			return nil
		end
		model.Name = id
		model:SetAttribute(Spots.IdAttribute, id)
		model:SetAttribute(Spots.OwnerAttribute, owner.UserId)
		model:AddTag(Spots.Tag)
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		local drawn: Drawn = {
			model = model,
			size = size,
			centre = centre,
			starter = if starter then kind else nil,
		}
		home.drawn[id] = drawn
		home.room.heights[id] = size.Y
		return drawn
	end

	-- What `player` may set out, by name: their finds less the shelf's and what's out of the box
	-- (`Save.settable`), and each piece of furniture they own by its placed name (D-336), every
	-- home's own pieces one each (D-346).
	local function settable(player: Player, data: Save.Data): Save.Counts
		local out = Save.settable(data, outOf(player))
		for name, n in Layout.settable(data.furniture) do
			out[name] = n
		end
		return out
	end

	-- The furniture in `data`'s job box, by piece id: owned less set out, and the home's own pieces
	-- put away (D-346).
	local function boxedPieces(data: Save.Data): { [string]: number }
		return Layout.boxed(data.furniture, Save.placedCounts(data))
	end

	-- Draws find `id` where it stands now (made the first time), then whatever stands on it.
	-- `moved`: by a Place, just now (stamped, so other screens settle it in), not as it's laid.
	local function draw(home: HomeSet, id: string, owner: Player, moved: boolean)
		local name = Spots.name(id)
		local t = poseFrame(home, id)
		if not (name and t) then
			return
		end
		local drawn: Drawn? = home.drawn[id]
		local piece = Furniture.ofPlaced(name)
		if not drawn and piece then
			drawn = drawPiece(home, id, piece.id, owner)
		end
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
			local each = model
			Takes.offer(model, function(by: Player)
				takeOut(by, id, each)
			end)
			-- its own button, for anyone in the home (S5-03i3, D-351): Switch, Play, Wind...
			local key = base or name
			HomeUses.offer(model, key, function(by: Player)
				pressOut(owner, by, id, each, key)
			end)
			drawn = { model = model, size = size, centre = centre }
			home.drawn[id] = drawn
			home.room.heights[id] = size.Y -- a top's height is the drawn box's
		end
		local d = drawn :: Drawn
		d.model:PivotTo(
			if d.starter
				then Arrange.starterPivot(t, d.starter)
				else Arranged.pivot(t, Spots.spot(name), d.size, d.centre)
		)
		local pose = home.placements:poseOf(id)
		if pose then -- the owner's screen loads its judge from these (ArrangeView)
			d.model:SetAttribute(Arrange.OnAttribute, pose.on)
			d.model:SetAttribute(Arrange.AtAttribute, Vector3.new(pose.x, pose.y, pose.turn))
		end
		if moved then
			d.model:SetAttribute(Arrange.WhenAttribute, Workspace:GetServerTimeNow())
		end
		d.model.Parent = home.folder
		for _, rider in home.placements:standingOn(id) do
			draw(home, rider, owner, moved)
		end
	end

	-- Draws what changed since the last take: placed and moved finds (and their riders), and
	-- removed ones taken away. The room's own things are never drawn. `moved` as `draw`'s.
	local function apply(home: HomeSet, owner: Player, moved: boolean)
		for _, e in home.placements:takeEvents() do
			if e.kind == "removed" then
				local drawn = home.drawn[e.id]
				if drawn then
					drawn.model:Destroy()
					home.drawn[e.id] = nil
				end
				home.room.heights[e.id] = nil
			elseif Spots.name(e.id) then
				draw(home, e.id, owner, moved)
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
		data.placedSize = home.room.sizeName -- laid at the room's size now (S5-03h1)
		data.starterLaid = true -- its own pieces are rows now (D-346)
	end

	local function clear(player: Player)
		local home = homes[player]
		if home then
			homes[player] = nil
			home.folder:Destroy()
			home.unit:SetAttribute(Spots.SizeAttribute, nil)
			if home.spare and home.unit.Parent then
				home.spare.Parent = home.unit -- a spare again: its set back as Lobby.front laid it
			end
			drawnSignal:fire(player)
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
		-- the home's size from its holder's save (S5-03h1, D-340); rows laid at another size (it
		-- grew, or a save from before sizes) carried to it, what it doesn't hold back in the box
		local size = Sizes.of(data.homeSize).name
		local room = Arrange.room(slot, laid.pivot, size)
		local most = room.limit
		local placements = room.placements
		local folder = Instance.new("Folder")
		folder.Name = FOLDER
		HomeUses.room(folder, room.face * CFrame.new(room.centre), room.size)
		folder.Parent = unit
		-- its own pieces are rows (D-346): a home laid before them adopts them where they stood
		-- (`Layout.adopt`, once); a home that grew keeps its pieces on their walls (`Layout.grow`)
		local saved = data.placed.rows
		local resized = data.placedSize ~= size
		local adopting = not data.starterLaid
		local _, to = Arrange.areas(slot, laid.pivot, size)
		if resized then
			local _, from = Arrange.areas(slot, laid.pivot, data.placedSize)
			saved = if adopting then Spots.carry(saved, from, to) else Layout.grow(saved, from, to)
		end
		local mended = false
		if adopting then
			saved = Layout.adopt(saved, to)
		else -- the job box always stands: a save that lost it gets it back (D-349)
			local whole = Layout.withBox(saved, to)
			mended, saved = whole ~= saved, whole
		end
		local rows = Spots.owned(Layout.boxFirst(saved), settable(player, data))
		local dropped = placements:load({ form = data.placed.form, rows = rows }, shapeOf)
		local home: HomeSet = {
			unit = unit,
			room = room,
			placements = placements,
			limit = most,
			drawn = {},
			folder = folder,
			stale = dropped == nil,
			spare = unit:FindFirstChild("Starter"),
		}
		homes[player] = home
		if home.spare then
			home.spare.Parent = nil -- the spare's set goes: the holder's own rows stand instead
		end
		unit:SetAttribute(Spots.SizeAttribute, size)
		if
			dropped and (resized or adopting or mended or #dropped > 0 or #rows < #data.placed.rows)
		then
			keep(home, data) -- what no longer fits is back in the box
		end
		apply(home, player, false)
		drawnSignal:fire(player)
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
		elseif Furniture.ofPlaced(what) then
			local piece = Furniture.ofPlaced(what) :: Furniture.Piece
			local template = Home.template()
			if (boxedPieces(data)[piece.id] or 0) < 1 then
				return "", Spots.Refusals.NotInBox
			elseif
				not piece.starter and Spots.setOut(home.placements:save().rows) >= home.limit
			then
				return "", "full" -- as a find's, below
			elseif not (template and Home.has(template, piece.id)) then
				return "", Spots.Refusals.Unknown
			end
			id = Spots.nextId(what, function(each: string): boolean
				return home.placements:poseOf(each) ~= nil
			end)
		else
			if Spots.setOut(home.placements:save().rows) >= home.limit then
				return "", "full" -- the starter pieces are free, so Brix's own count runs over
			elseif (Save.boxed(data, outOf(player))[what] or 0) < 1 then
				return "", Spots.Refusals.NotInBox
			elseif not Tools.template(Gold.base(what) or what) then
				return "", Spots.Refusals.Unknown
			end
			id = Spots.nextId(what, function(each: string): boolean
				return home.placements:poseOf(each) ~= nil
			end)
		end
		-- the mirror leans on a wall: only on the floor, its back to one at its lean (D-348)
		local kind = Layout.kind(id)
		local floor = home.placements:areaOf("Floor")
		if kind and floor and not Layout.stands(kind, pose, floor) then
			return "", Spots.Refusals.Wall
		end
		local shape = shapeOf(id)
		local refusal = if shape then home.placements:place(id, shape, pose) else "badShape"
		if refusal then
			return "", refusal
		end
		keep(home, data)
		apply(home, player, true)
		drawnSignal:fire(player)
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
		local kind = Layout.kind(id)
		local piece = if kind then Furniture.byId(kind) else nil
		if piece and piece.kept then
			return Spots.Refusals.Kept -- the job box holds everything: it moves, never away
		end
		Spots.lift(home.placements, id)
		keep(home, data)
		apply(home, player, true)
		drawnSignal:fire(player)
		return ""
	end

	-- Place from a cubby (S5-03i2b, D-352): find `what`, lifted out of their shelf's spot `i`, set
	-- at `pose`, off the spot and onto a row in one step; refused, it's back in its cubby.
	local function placeShelved(
		player: Player,
		what: string,
		i: number,
		pose: Brix.PlacementPose
	): (string, string)
		local home = homes[player]
		local data = if saving then saving:data(player) else nil
		if not (home and data) or home.stale then
			return "", Spots.Refusals.NotYours
		end
		return Spots.offShelf(data, i, what, function(): (string, string)
			return place(player, what, pose) -- fires `drawn` when it stands: the shelf's laid again
		end)
	end

	-- Put away from a cubby: find `what` on their shelf's spot `i` goes into the job box. "" or
	-- the refusal.
	local function awayShelved(player: Player, what: string, i: number): string
		local home = homes[player]
		local data = if saving then saving:data(player) else nil
		if not (home and data) or home.stale then
			return Spots.Refusals.NotYours
		elseif not Save.unshelf(data, i, what) then
			return Spots.Refusals.NotShelved
		end
		drawnSignal:fire(player) -- the shelf's laid again: the cubby empties
		return ""
	end

	-- Sends `player` what's in their job box now (counts by name), for the screen's tray, and how
	-- many finds they have set out of the most their home holds, for its limit bar.
	local function sendBox(player: Player)
		local data = if saving then saving:data(player) else nil
		local home = homes[player]
		if boxRemote and data then
			local out = if home then Spots.setOut(home.placements:save().rows) else 0
			local most = if home then home.limit else Spots.limit(Spots.Start)
			boxRemote:FireClient(
				player,
				Save.boxed(data, outOf(player)),
				out,
				most,
				boxedPieces(data)
			)
		end
	end

	-- Take on find `id` set out (`model`), pressed by `player`: only their own, as drawn now.
	function takeOut(player: Player, id: string, model: Model)
		if not limit:take(player, os.clock()) then
			return
		end
		local home = homes[player]
		local data = if saving then saving:data(player) else nil
		local drawn = if home then home.drawn[id] else nil
		local name = Spots.takeable(id)
		local s = slots
		if
			not (home and data and drawn and name and s)
			or home.stale
			or drawn.model ~= model
			or not Takes.near(player, model)
			or not s:room(player)
		then
			return -- a friend's press, a far one, or full hands: nothing happens
		end
		home.drawn[id] = nil -- it flies from here: the removal below leaves it to Takes
		Takes.leave(model, player)
		Spots.lift(home.placements, id)
		keep(home, data)
		apply(home, player, true)
		s:unbox(player, name)
		drawnSignal:fire(player)
		sendBox(player)
	end

	-- A find's own button on find `id` set out (`model`) in `holder`'s home, pressed by `player`,
	-- the holder or a friend (S5-03i3, D-351): its press plays if it's still drawn there and they
	-- stand in the home within reach (`HomeUses.near`). FindUses keeps each player's pace.
	function pressOut(holder: Player, player: Player, id: string, model: Model, key: string)
		local home = homes[holder]
		local drawn = if home then home.drawn[id] else nil
		local f = findUses
		if
			not (home and drawn and f)
			or drawn.model ~= model
			or not HomeUses.near(player, model)
		then
			return -- a far press, from next door, or one already taken: nothing happens
		end
		f:setOut(player, model, key)
	end

	-- Answers the asker, then sends their box when the move changed it.
	local function answer(player: Player, what: string, id: string, refusal: string)
		if answerRemote then
			answerRemote:FireClient(player, what, id, refusal)
		end
		if refusal == "" then
			sendBox(player)
		end
	end

	-- The screen asks what's in the box as Arrange opens.
	local function onBox(player: Player)
		if limit:take(player, os.clock()) then
			sendBox(player)
		end
	end

	local function onPlace(
		player: Player,
		what: unknown,
		on: unknown,
		x: unknown,
		y: unknown,
		turn: unknown,
		spot: unknown
	)
		if not limit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local w, pose = Spots.ask(what, on, x, y, turn)
		if not (w and pose) then
			return
		elseif spot == nil then
			local id, refusal = place(player, w, pose)
			answer(player, w, id, refusal)
			return
		end
		local i = Shelf.spot(spot, #SPOTS) -- out of a cubby: a whole spot on the shelf, or nothing
		if i then
			local id, refusal = placeShelved(player, w, i, pose)
			answer(player, w, id, refusal)
		end
	end

	local function onPutAway(player: Player, id: unknown, spot: unknown)
		if not limit:take(player, os.clock()) then
			return
		end
		if spot == nil then
			local w = Spots.askId(id)
			if w then
				answer(player, w, "", putAway(player, w))
			end
			return
		end
		local w, i = Spots.askName(id), Shelf.spot(spot, #SPOTS) -- out of a cubby: a find's name
		if w and i then
			answer(player, w, "", awayShelved(player, w, i))
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
		drawn = drawnSignal,
		pieceOf = function(_: any, player: Player, kind: string): Model?
			local home = homes[player]
			local drawn = if home then home.drawn[Layout.id(kind)] else nil
			return if drawn then drawn.model else nil
		end,
		relay = function(_: any, player: Player)
			clear(player)
			lay(player)
			sendBox(player)
		end,
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			frontOffice = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice
			saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
			slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
			findUses = (registry:get("findUses") :: any) :: FindUses.FindUsesSystem -- any: as above

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
			local box = remote(Arrange.BoxRemote)
			boxRemote = box
			table.insert(connections, box.OnServerEvent:Connect(onBox))

			-- Studio only: `ServerStorage.ArrangeTest:Invoke(player, "place", what, on, x, y, turn)`
			-- asks as the screen does, unthrottled, and answers (id, refusal);
			-- `:Invoke(player, "putAway", id)` answers the refusal or ""; `:Invoke(player, "rows")`
			-- answers the save's placed rows and the job box's counts; `:Invoke(player, "relay")`
			-- sets the home up again from the save, as a rejoin does; `:Invoke(player, "own", piece)`
			-- puts one more of furniture `piece` in their job box, saved as a buy is (S5-03g4d, for
			-- a piece not in this week's stock); `:Invoke(player, "size", name)` makes their home
			-- that size (a `Home.Sizes` name) and sets it up again, as a resize will (S5-03h1);
			-- `:Invoke(player, "take", id)` presses find `id`'s Take as them (S5-03i2a);
			-- `:Invoke(player, "fromShelf", spot, on, x, y, turn)` sets the find on their shelf's
			-- `spot` there, and `:Invoke(player, "shelfAway", spot)` puts it in the box (S5-03i2b).
			-- No client reaches it.
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
					elseif verb == "fromShelf" or verb == "shelfAway" then
						local data = if saving then saving:data(player) else nil
						local i = Shelf.spot(a, #SPOTS)
						local name = if data and i and data.shelf[i] then data.shelf[i].find else ""
						if not (i and name ~= "") then
							return "", "badAsk"
						elseif verb == "shelfAway" then
							return awayShelved(player, name, i)
						end
						local _, pose = Spots.ask(name, b, c, d, e)
						if not pose then
							return "", "badAsk"
						end
						return placeShelved(player, name, i, pose)
					elseif verb == "take" then
						-- presses find `a`'s Take as `player`: true when it went into their hands
						local home = homes[player]
						local drawn = if home and type(a) == "string" then home.drawn[a] else nil
						if drawn then
							takeOut(player, a, drawn.model)
						end
						return drawn ~= nil and home ~= nil and home.drawn[a] == nil
					elseif verb == "putAway" then
						local w = Spots.askId(a)
						return if w then putAway(player, w) else "badAsk"
					elseif verb == "rows" then
						local data = if saving then saving:data(player) else nil
						return if data then data.placed.rows else nil,
							if data then Save.boxed(data, outOf(player)) else nil,
							if data then boxedPieces(data) else nil
					elseif verb == "own" then
						local data = if saving then saving:data(player) else nil
						if not (data and type(a) == "string" and Furniture.byId(a)) then
							return false
						end
						data.furniture[a] = (data.furniture[a] or 0) + 1
						sendBox(player)
						return true
					elseif verb == "relay" then
						clear(player)
						lay(player)
						return homes[player] ~= nil
					elseif verb == "size" then
						local data = if saving then saving:data(player) else nil
						if not (data and type(a) == "string" and table.find(Sizes.Names, a)) then
							return false
						end
						data.homeSize = a
						clear(player)
						lay(player)
						sendBox(player)
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
			boxRemote = nil
		end,
	}
end

return Arranging
