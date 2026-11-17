--!strict
--[[
	Rails: what each player can wear, standing on their home's clothes rail, and wearing it from
	there (S5-03f2b, D-316). The moment: walk up to the rail, press the hard hat and you're wearing
	it, its knock and its lamp's click; turn to the mirror and it's on you. Press again and it
	hangs back up. Lethal Company's suit rack.

	Each kind you own that you wear (`Rail.places`: the hard hat and its Gold on the hat shelf) has
	a place on its row of the unit's `Rail`. While one of it is in your job box (Save.boxed: owned,
	less the shelf, what's set out and what's out of the box) a copy stands there, inert, at the
	size you wear it; a visitor sees it too. Each place has one press, shown only on your screen
	(HomeCards): Wear while it stands there and your head is free; Hang up while you wear that kind
	out of your own box.

	A press is checked here: rate-limited, not wrapped, your home, your root near the place, and
	what the place offers now (never the button's words). Wear makes the find out of your box
	straight onto your head (`Slots:boxToHead`, marked as from your box as a take to hand is, so
	the save isn't written and it's off the rail at once) and stamps its press (`FindUses:wearLit`):
	every screen plays its knock and click and lights it, for good at home. Hang up takes it off
	your head in a glint and back into the box (`Slots:hangUp`), and it stands on the rail again
	with its knock. Worn into a lobby car it's taken up like any find out of your box (D-251).

	A save from before the rail kept the hard hat on the shelf: it's lifted off as the save loads
	(`Save.unshelve`), so it stands on the rail instead.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Catalog = require(ReplicatedStorage.Shared.Tools.Catalog)
local Door = require(ReplicatedStorage.Shared.StorageUnit.Door)
local Gold = require(ReplicatedStorage.Shared.Home.Gold)
local Head = require(ReplicatedStorage.Shared.Finds.Head)
local Holding = require(ReplicatedStorage.Shared.Home.Holding)
local HomeSpecs = require(ReplicatedStorage.Shared.Home.Specs)
local Rail = require(ReplicatedStorage.Shared.Home.Rail)
local Save = require(ReplicatedStorage.Shared.Save)
local Tools = require(ReplicatedStorage.Shared.Tools)
local FindUses = require(script.Parent.FindUses)
local FrontOffice = require(script.Parent.FrontOffice)
local Prompts = require(script.Parent.Prompts)
local Saving = require(script.Parent.Saving)
local Shelves = require(script.Parent.Shelves)
local Slots = require(script.Parent.Slots)

-- Seconds between sweeps that catch what no signal tells (a hat sold out of the box).
local SWEEP = 2
-- Studs over its row's top a place's press sits: about the middle of a hat standing there.
local PRESS_UP = 0.45
-- Studs the knock of a hat hung up carries: your room and the hall outside.
local HEARING = 30

-- One place on a player's rail: its press, and the find standing there (nil while none is in
-- the box).
type Spot = {
	place: Rail.Place,
	part: Part,
	prompt: ProximityPrompt,
	pressed: RBXScriptConnection,
	find: Model?,
}
type Mine = { unit: Model, rail: Model, spots: { [string]: Spot } }

local Rails = {}

function Rails.new(): Brix.System
	local mine: { [Player]: Mine } = {}
	local signals: { Brix.SignalConnection } = {}
	local connections: { RBXScriptConnection } = {}
	local plotWatch: { [Player]: RBXScriptConnection } = {}
	local limit = Brix.RateLimit.bucket(Rail.Limit)
	local frontOffice: FrontOffice.FrontOffice? = nil
	local saving: Saving.SavingSystem? = nil
	local slots: Slots.Slots? = nil
	local findUses: FindUses.FindUsesSystem? = nil
	local sweeping = true

	-- `player`'s home unit and its rail, if they hold one and its rail stands.
	local function railOf(player: Player): (Model?, Model?)
		local plot = player:GetAttribute("Plot")
		local n = if type(plot) == "string" then Holding.number(plot) else nil
		local laid = if frontOffice then frontOffice:laid() else nil
		local unit = if n and laid then laid.units[n] else nil
		local rail = if unit then unit:FindFirstChild("Rail") else nil
		if unit and rail and rail:IsA("Model") then
			return unit, rail
		end
		return nil, nil
	end

	-- Where place `p` of `rail` is: its middle on its row's top, the rail's front ahead.
	local function placeAt(rail: Model, p: Rail.Place): CFrame
		local top = Rail.height(p.row, HomeSpecs.Rail) + Rail.Lift
		return rail.WorldPivot * CFrame.new(p.x, top, 0)
	end

	-- A copy of find `name` standing at `at` (its bottom's middle there), inert and still, at the
	-- size you wear it, as worn (its hidden parts gone), its lights off. Not parented.
	local function stand(name: string, at: CFrame): Model?
		local base = Gold.base(name)
		local key = base or name
		local fit = Head.fit(key)
		local model = Tools.clone(key, CFrame.identity)
		if not (model and fit) then
			if model then
				model:Destroy()
			end
			return nil
		end
		if base then
			Gold.gild(model)
		end
		for _, part in fit.hide do
			local p = model:FindFirstChild(part, true)
			if p then
				p:Destroy()
			end
		end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
			elseif d:IsA("Light") then
				d.Enabled = false
			elseif d:IsA("Sound") then
				d:Destroy()
			end
		end
		model:ScaleTo(fit.scale)
		model:PivotTo(at * CFrame.Angles(0, math.rad(Rail.Turn), 0))
		local box, size = model:GetBoundingBox()
		model:PivotTo(
			model:GetPivot() + Vector3.new(0, at.Position.Y - (box.Position.Y - size.Y / 2), 0)
		)
		model.Name = `RailFind{name}`
		model:SetAttribute(Tools.KindAttribute, name)
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		return model
	end

	-- A place gone: its press, its spot and the find standing there.
	local function drop(s: Spot)
		s.pressed:Disconnect()
		s.prompt:Destroy()
		s.part:Destroy()
		if s.find then
			s.find:Destroy()
		end
	end

	local function clear(player: Player)
		local m = mine[player]
		if not m then
			return
		end
		mine[player] = nil
		for _, s in m.spots do
			drop(s)
		end
	end

	local press: (Player, string) -> ()

	-- A place's press spot on `rail`: an invisible part over the place, its press made but not up.
	local function spotFor(player: Player, rail: Model, p: Rail.Place): Spot
		local part = Instance.new("Part")
		part.Name = `RailPress{p.name}`
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Transparency = 1
		part.Size = Vector3.one * 0.2
		part.CFrame = placeAt(rail, p) + Vector3.new(0, PRESS_UP, 0)
		local at = Instance.new("Attachment")
		at.Name = "RailButton"
		at.Parent = part
		local prompt = Prompts.make(at, {
			actionText = Rail.Wear,
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Rail.Reach,
		})
		prompt.Parent = nil -- up only while it offers something
		local name = p.name
		local pressed = prompt.Triggered:Connect(function(who: Player)
			if who == player then
				press(who, name)
			end
		end)
		part.Parent = rail
		return { place = p, part = part, prompt = prompt, pressed = pressed, find = nil }
	end

	-- Lays `player`'s rail from their save and what they wear: a find standing on each place with
	-- one in the box, each press up with the word it offers now, places no longer owned gone.
	local function lay(player: Player)
		local data = if saving then saving:data(player) else nil
		local s = slots
		local unit, rail = railOf(player)
		local m: Mine? = mine[player]
		if m and m.rail ~= rail then
			clear(player)
			m = nil
		end
		if not (data and s and unit and rail and player.Parent) then
			return
		end
		local here: Mine = m or { unit = unit, rail = rail, spots = {} }
		mine[player] = here
		local boxed = Save.boxed(data, s:fromBox(player))
		local worn, fromMine = s:onHead(player)
		local seen: { [string]: boolean } = {}
		for _, p in Rail.places(data.finds) do
			seen[p.name] = true
			local spot: Spot? = here.spots[p.name]
			if spot and spot.place.x ~= p.x then
				drop(spot)
				spot = nil
			end
			if not spot then
				spot = spotFor(player, rail, p)
				here.spots[p.name] = spot
			end
			local sp = spot :: Spot
			local standing = (boxed[p.name] or 0) >= 1
			if standing and not sp.find then
				local model = stand(p.name, placeAt(rail, p))
				if model then
					model:SetAttribute(Rail.OwnerAttribute, player.UserId)
					model:AddTag(Rail.Tag)
					model.Parent = rail
					sp.find = model
				end
			elseif not standing and sp.find then
				sp.find:Destroy()
				sp.find = nil
			end
			local word: string? = nil
			if worn == p.name and fromMine then
				word = Rail.HangUp
			elseif worn == nil and sp.find then
				word = Rail.Wear
			end
			if word then
				sp.prompt.ActionText = word
				sp.prompt.Parent = sp.part:FindFirstChild("RailButton")
			else
				sp.prompt.Parent = nil
			end
		end
		for name, spot in here.spots do
			if not seen[name] then
				drop(spot)
				here.spots[name] = nil
			end
		end
	end

	press = function(player: Player, name: string)
		if not limit:take(player, os.clock()) or Prompts.wrapped(player) then
			return
		end
		local m = mine[player]
		local spot = if m then m.spots[name] else nil
		local s = slots
		local data = if saving then saving:data(player) else nil
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if
			not (m and spot and s and data and root and root:IsA("BasePart"))
			or m.unit:GetAttribute(Door.HolderAttribute) ~= player.UserId
		then
			return
		end
		if (root.Position - spot.part.Position).Magnitude > Rail.Reach + Rail.Slack then
			return -- not at the rail
		end
		local worn, fromMine = s:onHead(player)
		if worn == name and fromMine then
			if s:hangUp(player, name) then
				local row = Catalog[Gold.base(name) or name]
				if row and row.pickUp then
					Tools.play(row.pickUp, spot.part, HEARING) -- its knock as it lands on the rail
				end
			end
		elseif worn == nil and (Save.boxed(data, s:fromBox(player))[name] or 0) >= 1 then
			local model = s:boxToHead(player, name)
			if model and findUses then
				findUses:wearLit(player, model, Gold.base(name) or name)
			end
		end
		lay(player)
	end

	local function watch(player: Player)
		plotWatch[player] = player:GetAttributeChangedSignal("Plot"):Connect(function()
			lay(player)
		end)
		lay(player)
	end

	return {
		name = "Rails",
		start = function(_: any, context: Brix.Context)
			local registry = context.registry
			-- any: the registry hands back plain Systems; each slot is filled by its system (init.server)
			frontOffice = (registry:get("frontOffice") :: any) :: FrontOffice.FrontOffice
			saving = (registry:get("saving") :: any) :: Saving.SavingSystem -- any: as above
			slots = (registry:get("slots") :: any) :: Slots.Slots -- any: as above
			findUses = (registry:get("findUses") :: any) :: FindUses.FindUsesSystem -- any: as above
			local shelves = (registry:get("shelves") :: any) :: Shelves.ShelvesSystem -- any: as above

			local sv = saving :: Saving.SavingSystem
			table.insert(
				signals,
				sv.loaded:connect(function(each: Saving.Loaded)
					local data = sv:data(each.player)
					if data and Save.unshelve(data) > 0 then
						shelves:lay(each.player) -- its old spot empties
					end
					task.defer(lay, each.player)
				end)
			)
			table.insert(
				signals,
				shelves.laid:connect(function(player: Player)
					lay(player)
				end)
			)
			table.insert(
				signals,
				(slots :: Slots.Slots).changed:connect(function(change: Slots.Change)
					lay(change.player)
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
			task.spawn(function()
				while sweeping do
					task.wait(SWEEP)
					for player in mine do
						lay(player)
					end
				end
			end)
		end,
		stop = function(_: any)
			sweeping = false
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
			for player in mine do
				clear(player)
			end
		end,
	}
end

return Rails
