--!strict
--[[
	JobBoxes: the job box in every home (S5-03c2a, D-287). The moment: the shelf's full, you keep one
	more at the gate, and when you come home the job box's lid sparkles; press Open and the lid swings
	up with a soft steel creak. Precedents: Resident Evil's item box, Animal Crossing's house storage,
	Fortnite's locker marks.

	Each home's JobBox piece (the Starter set, Home.piece tags it) gets an Open button in front of
	it, on a spot of its own in the unit (JobBox.Spot) that HomeCards shows to the home's holder
	alone. The server owns the box's two attributes and every screen draws them (JobBoxView):
	- Fresh: how new what went in since its holder last opened it is (Save's `boxFresh`), brought up
	  to date each time Shelves lays that player's home finds and when the home changes hands.
	- Lid: 0 shut; up, 1 plus how new what was in it as it opened (Save.Fresh), so the opener's
	  screen can chime for a kind they'd never owned. One attribute, so a screen never sees the lid
	  up without what it found.
	Open is for the holder only, as the switch is; opening marks what's in it seen (Save.open, kept
	by the autosave). The lid closes on Close, when its holder walks away (JobBox.Away, looked at
	every JobBox.Every seconds while a lid is up) and when the home changes hands.

	The panel (S5-03c2b1, BoxPanel): as the lid opens the holder's screen is sent the box, what's
	in it (Save.boxed: every find they own less the shelf's and those out of it, D-293) and how many
	shelf spots stand free (`BoxPanel.ListRemote`), once. Its X, or a tap outside it, asks
	`CloseRemote` (nothing carried): rate-limited, then it shuts the box only if it's this player's
	and open.

	Taking one out (S5-03c2b2, D-293): `TakeRemote` carries a find's name and a way, Hand or Shelf.
	Rate-limited first, then checked: the types (`BoxPanel.name`, `BoxPanel.way`), this player's
	own box open, a find the catalog knows, one of it in the box (`BoxPanel.canTake` on
	Save.boxed). Hand: into a free slot as a find from this box (Slots' `unbox`); the save is not
	touched, so a crash or a failed save never costs or doubles one. Shelf: onto the first free spot
	(Save.shelve, seen: you put it there), the shelf laid at once; the autosave keeps it, and a crash
	before it only leaves the find in the box. Every take past the type checks is answered on
	`TookRemote`, so the screen lands or settles its picture.

	Selling one (S5-03c3a): Sell is the third way, through the same checks and rate limit. Priced at
	its catalog worth (`BoxPanel.price`), one comes off what the holder owns and the price goes on
	their cash in one step (`BoxPanel.sell`), and the answer carries their new cash. The save is
	written `BoxPanel.SellSave` seconds after a run of sales (one write for the run); it holds the
	sale from the moment it's made, so the autosave, a leave or a shutdown write it too, and a crash
	before any of them undoes the whole sale, never half. The list sent as the lid opens carries
	the holder's cash, so the panel shows it from the start, and how many of each are cracked
	(`BoxPanel.cracked`): a cracked one sells first, at half, one off `chipped` (S5-03c3a2), and
	the furniture in the box (`Furniture.boxed`, S5-03g4c2), which the panel lists to set out.

	Making a Gold (S5-03c3b, D-298): Gold is the fourth way, through the same checks and rate limit,
	for a find that can be made Gold (Home.Gold: not a Secret). Four of it in the box are struck
	and one Gold added in one step (`BoxPanel.gold`), written as a sale is. A Gold's own key
	("Teddy:Gold") sells at Gold.Times its find's price, and comes out to the hand (carried as its
	find, gilded: Slots' `unbox`) and to the shelf (stood gilded: Shelves) as any find does
	(S5-03c3b3); a Gold of a Gold is refused.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Furniture = require(ReplicatedStorage.Shared.Home.Furniture)
local Home = require(ReplicatedStorage.Shared.Home)
local Save = require(ReplicatedStorage.Shared.Save)
local FrontOffice = require(script.Parent.FrontOffice)
local Prompts = require(script.Parent.Prompts)
local Saving = require(script.Parent.Saving)
local Shelves = require(script.Parent.Shelves)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)

local BoxPanel = Home.BoxPanel
local Gold = Home.Gold
local JobBox = Home.JobBox

-- One home's box as wired: its unit, the piece, its button and when it last answered a press.
type Box = { unit: Model, model: Model, prompt: ProximityPrompt, last: number }

-- The Studio-only hook's name in ServerStorage: Invoke(player, name) cracks one of `name` in their
-- save, as a climb's gate does (S5-03c3a2's test).
local STUDIO_CRACK = "StudioCrack"

local JobBoxes = {}

function JobBoxes.new(): Brix.System
	local boxes: { [Model]: Box } = {} -- by unit
	local open: { [Box]: true } = {}
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local saving: Saving.SavingSystem? = nil
	local slots: Slots.Slots? = nil
	local shelves: Shelves.ShelvesSystem? = nil
	local untilLook = 0
	local remotes: { RemoteEvent } = {}
	local listRemote: RemoteEvent? = nil
	local tookRemote: RemoteEvent? = nil
	local limit = Brix.RateLimit.bucket(BoxPanel.Limit)
	local takeLimit = Brix.RateLimit.bucket(BoxPanel.TakeLimit)
	local spots = #Home.Specs.Shelf.Spots -- every home is small until the sizes come (S5-03h)
	local writing: { [Player]: true } = {} -- a write after a sale is waiting
	local crackHook: BindableFunction? = nil -- Studio only (STUDIO_CRACK)

	local function holderOf(box: Box): Player?
		local id = box.unit:GetAttribute(Door.HolderAttribute)
		return if type(id) == "number" and id > 0 then Players:GetPlayerByUserId(id) else nil
	end

	local function isOpen(box: Box): boolean
		local lid = box.model:GetAttribute(JobBox.LidAttribute)
		return type(lid) == "number" and lid > 0
	end

	-- The box's Fresh from its holder's save (quiet with no holder, or no save yet).
	local function show(box: Box)
		local player = holderOf(box)
		local data = if player and saving then saving:data(player) else nil
		box.model:SetAttribute(
			JobBox.FreshAttribute,
			if data then data.boxFresh else Save.Fresh.Seen
		)
	end

	local function shut(box: Box)
		open[box] = nil
		box.model:SetAttribute(JobBox.LidAttribute, 0)
		box.prompt.ActionText = "Open"
	end

	local function press(box: Box, player: Player)
		if
			Prompts.wrapped(player)
			or box.unit:GetAttribute(Door.HolderAttribute) ~= player.UserId
		then
			return -- the holder's own (its button shows only on their screen, HomeCards)
		end
		local t = os.clock()
		if t - box.last < JobBox.Button.Cooldown then
			return
		end
		box.last = t
		if isOpen(box) then
			shut(box)
			return
		end
		local data = if saving then saving:data(player) else nil
		local found = if data then Save.open(data) else Save.Fresh.Seen
		open[box] = true
		box.model:SetAttribute(JobBox.LidAttribute, 1 + found)
		box.model:SetAttribute(JobBox.FreshAttribute, Save.Fresh.Seen)
		box.prompt.ActionText = "Close"
		if listRemote then
			local s = slots
			local boxed = if data and s then Save.boxed(data, s:fromBox(player)) else {}
			local free = if data then Save.free(data, spots) else 0
			local cash = if data then data.cash else 0
			local cracked = if data then BoxPanel.cracked(data.chipped, boxed) else {}
			-- the furniture in the box (D-336), by piece id: owned less set out (S5-03g4c2)
			local pieces = if data
				then Furniture.boxed(data.furniture, Save.placedCounts(data))
				else {}
			listRemote:FireClient(
				player,
				box.model,
				BoxPanel.list(boxed),
				free,
				cash,
				cracked,
				pieces
			)
		end
	end

	-- `player`'s own open box, if they have one open.
	local function openOf(player: Player): Box?
		for box in open do
			if box.unit:GetAttribute(Door.HolderAttribute) == player.UserId then
				return box
			end
		end
		return nil
	end

	-- The save written once a run of sales has settled (BoxPanel.SellSave): one write for the run.
	local function keepSale(player: Player)
		if writing[player] then
			return
		end
		writing[player] = true
		task.delay(BoxPanel.SellSave, function()
			writing[player] = nil
			local s = saving
			if s and player.Parent and s:data(player) then
				s:save(player)
			end
		end)
	end

	-- Take from the panel: one `name` out of `player`'s open box, `way` Hand, Shelf or Sell.
	local function takeAsked(player: Player, name: unknown, way: unknown)
		if not takeLimit:take(player, os.clock()) then
			return -- asked too often: refused before the payload is read
		end
		local key, to = BoxPanel.name(name), BoxPanel.way(way)
		if not (key and to) then
			return
		end
		local function answer(ok: boolean, at: (number | Vector3)?)
			if tookRemote then
				tookRemote:FireClient(player, key, to, ok, at)
			end
		end
		local data = if saving then saving:data(player) else nil
		local s, sh = slots, shelves
		local plain = Gold.base(key) -- a Gold's find, when it's a Gold that's asked for
		local row = (Tools.Catalog :: any)[plain or key] -- any: the catalog is keyed by text
		local boxed = if data and s then Save.boxed(data, s:fromBox(player)) else {}
		if
			not (data and s and sh and openOf(player) and row and row.find)
			or Prompts.wrapped(player)
			or not BoxPanel.canTake(boxed, key)
			or (plain and to == BoxPanel.Ways.Gold) -- never a Gold of a Gold
			or (to == BoxPanel.Ways.Gold and not Gold.can(row))
		then
			answer(false)
			return
		end
		if to == BoxPanel.Ways.Gold then
			local made = BoxPanel.gold(data, boxed, key, data.stamps.finds, os.time())
			if made then
				keepSale(player) -- written as a sale is: one write for a run
				if RunService:IsStudio() then
					print(
						`JobBoxes: {player.Name} made a {made}, {data.finds[key] or 0} {key} left`
					)
				end
			end
			answer(made ~= nil)
			return
		end
		if to == BoxPanel.Ways.Sell then
			local before = data.cash
			-- whole: a cracked one goes first, at half (BoxPanel.sell, S5-03c3a2)
			local cash = BoxPanel.sell(data, boxed, key, BoxPanel.price(row, plain ~= nil))
			if cash then
				keepSale(player)
				if RunService:IsStudio() then
					print(
						`JobBoxes: {player.Name} sold a {key} for {cash - before}, cash now {cash}`
					)
				end
			end
			answer(cash ~= nil, cash)
			return
		end
		if to == BoxPanel.Ways.Hand then
			local slot = s:unbox(player, key)
			answer(slot ~= nil, slot)
			return
		end
		local i = Save.shelve(data, key, Save.Fresh.Seen, spots)
		if not i then
			answer(false)
			return
		end
		sh:lay(player)
		answer(true, sh:spot(player, i))
	end

	-- Close from the panel: `player`'s own open box shuts. Nothing carried, so nothing to read.
	local function closeAsked(player: Player)
		if not limit:take(player, os.clock()) then
			return
		end
		local box = openOf(player)
		if box then
			shut(box)
		end
	end

	-- The box in `unit`'s starter set, its button set in front of it. Nil for a unit with none.
	local function wire(unit: Model): Box?
		local starter = unit:FindFirstChild("Starter")
		local model = if starter then starter:FindFirstChild("JobBox") else nil
		if not (model and model:IsA("Model")) then
			return nil
		end
		-- on a spot of its own in the unit, just in front of the lid: the box's collider would stand
		-- in the way of the line-of-sight check, as the front's wall does for the switch
		local spot = Instance.new("Part")
		spot.Name = JobBox.Spot
		spot.Anchored = true
		spot.CanCollide = false
		spot.CanTouch = false
		spot.CanQuery = false
		spot.CastShadow = false
		spot.Transparency = 1
		spot.Size = Vector3.one * 0.2
		local front = Home.Specs.Parts.JobBox
		spot.CFrame = model.WorldPivot
			* CFrame.new(0, JobBox.Button.Up, -(front.Size[3] / 2 + JobBox.Button.Out))
		spot.Parent = unit
		local at = Instance.new("Attachment")
		at.Name = "JobBoxButton"
		at.Parent = spot
		local prompt = Prompts.make(at, {
			actionText = "Open",
			-- the usual E: the box stands deep in the room, far past the door's own E (Lift)
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = JobBox.Button.Reach,
		})
		local box: Box = { unit = unit, model = model, prompt = prompt, last = -math.huge }
		model:SetAttribute(JobBox.LidAttribute, 0)
		show(box)
		table.insert(
			connections,
			prompt.Triggered:Connect(function(player: Player)
				press(box, player)
			end)
		)
		table.insert(
			connections,
			unit:GetAttributeChangedSignal(Door.HolderAttribute):Connect(function()
				shut(box) -- a home changing hands never keeps the last one's lid up
				show(box)
			end)
		)
		return box
	end

	-- Shut each open lid whose holder has walked away from it, or gone.
	local function look()
		for box in open do
			local player = holderOf(box)
			local character = if player then player.Character else nil
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if
				not (root and root:IsA("BasePart"))
				or (root.Position - box.model.WorldPivot.Position).Magnitude > JobBox.Away
			then
				shut(box)
			end
		end
	end

	return {
		name = "JobBoxes",
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			local frontOffice = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice
			saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
			slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
			local sh = (registry:get("shelves") :: any) :: Shelves.ShelvesSystem -- any: as above
			shelves = sh
			local laid = frontOffice:laid()
			if not laid then
				return -- no lobby in this place: no homes
			end
			local folder = ReplicatedStorage:FindFirstChild(BoxPanel.RemoteFolder)
			if not folder then
				folder = Instance.new("Folder")
				folder.Name = BoxPanel.RemoteFolder
				folder.Parent = ReplicatedStorage
			end
			for _, name in
				{
					BoxPanel.ListRemote,
					BoxPanel.CloseRemote,
					BoxPanel.TakeRemote,
					BoxPanel.TookRemote,
				}
			do
				local r = Instance.new("RemoteEvent")
				r.Name = name
				r.Parent = folder
				table.insert(remotes, r)
			end
			listRemote = remotes[1]
			tookRemote = remotes[4]
			if RunService:IsStudio() then
				-- Studio only, and never a remote: the MCP's Server execute_luau cracks one of a
				-- find in a player's save (as a climb's gate does, Save.chip), so a cracked sale is
				-- tested without a climb (S5-03c3a2). Answers how many of it are cracked now.
				local hook = Instance.new("BindableFunction")
				hook.Name = STUDIO_CRACK
				hook.OnInvoke = function(player: unknown, name: unknown): number?
					local sv = saving
					local data = if sv
							and typeof(player) == "Instance"
							and player:IsA("Player")
						then sv:data(player)
						else nil
					if not (data and type(name) == "string") then
						return nil
					end
					Save.chip(data, { name })
					return data.chipped[name]
				end
				hook.Parent = game:GetService("ServerStorage")
				crackHook = hook
			end
			table.insert(connections, remotes[2].OnServerEvent:Connect(closeAsked))
			table.insert(connections, remotes[3].OnServerEvent:Connect(takeAsked))
			table.insert(
				connections,
				Players.PlayerRemoving:Connect(function(player: Player)
					limit:forget(player)
					takeLimit:forget(player)
					writing[player] = nil -- their save is written as it's let go
				end)
			)
			for _, unit in laid.units do
				local box = wire(unit)
				if box then
					boxes[unit] = box
				end
			end
			-- the box follows each lay of a player's home finds (a load, a home handed over, a keep)
			table.insert(
				signals,
				sh.laid:connect(function(player: Player)
					for _, box in boxes do
						if box.unit:GetAttribute(Door.HolderAttribute) == player.UserId then
							show(box)
						end
					end
				end)
			)
			table.insert(
				connections,
				RunService.Heartbeat:Connect(function(dt: number)
					if next(open) == nil then
						return
					end
					untilLook -= dt
					if untilLook <= 0 then
						untilLook = JobBox.Every
						look()
					end
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
			for _, box in boxes do
				local spot = box.prompt.Parent and box.prompt.Parent.Parent
				if spot then
					spot:Destroy()
				end
			end
			table.clear(boxes)
			table.clear(open)
			table.clear(writing)
			for _, r in remotes do
				r:Destroy()
			end
			table.clear(remotes)
			listRemote = nil
			tookRemote = nil
			if crackHook then
				crackHook:Destroy()
				crackHook = nil
			end
		end,
	}
end

return JobBoxes
