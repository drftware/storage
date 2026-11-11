--!strict
--[[
	KeptPlayers: getting kept on the server (L-07a, the GDD's "Getting kept"), a system. It takes
	`Keepers.caught`: the keeper's hands have closed, the caught player's screen is going black
	(`Caught`, CaughtView), and Keepers has marked them kept (`Kept.Attribute`), so no keeper sees
	them and no prompt answers them (`Prompts.wrapped`).

	At once: everything they carried drops where they stood (`Slots:dropAll`), they're held still
	(their root anchored, so only the server moves them), and the building picks the unit it
	stores them in (`Kept.choose`: a shut unit away from them with nobody and no keeper in it, an
	unopened one first). That unit is never dealt now (`Deals:hold`), so the friend who opens it
	finds only them. Once their screen is black (`Caught.Dark`) they're put inside it, past its
	middle facing the door (`Kept.Back`), and their screen opens on the dark inside. There they
	stand wrapped head to foot in clear film (L-07b): a copy of `Props.KeptWrap` fitted to their
	body at rest (`Kept.fit`), welded on, so the friend who lifts the door finds them in it. Their
	own screen never shows it (CaughtView), and every screen plays the film's squeal (KeptSqueal).

	Inside, they can bang on their door (L-07c, `Remotes.Bang`, `Kept.ready`'s rate): the door
	jolts and thuds as a trapped keeper's does (`Doors:move`, "Bang"), so keepers hear it as they
	hear that, and the floor's model carries the bang (`Kept.BangsAttribute`) so friends' screens
	and corner maps mark the unit however far off they are. They also get `Kept.InsideValue`, the
	unit they're in, for their own screen's light under the door.

	They're let out when their unit's door goes all the way up: the stand-in until L-07d's Cut
	free; the film comes off and their unit's mark goes as they go. Leaving, dying or a new character lets them go too, as
	does their floor going away. A
	catch on a floor this doesn't know, or with no unit free, holds them through the wrap and lets
	them go where they stand.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Deals = require(script.Parent.Deals)
local Doors = require(script.Parent.Doors)
local FloorBuilder = require(script.Parent.FloorBuilder)
local Keepers = require(script.Parent.Keepers)
local Kept = require(ReplicatedStorage.Shared.Kept)
local KeptWrap = require(ReplicatedStorage.Shared.KeptWrap.Specs)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)

export type KeptPlayers = Brix.System & {
	-- A laid floor's deck and its units, each by its slot's index (FloorBuilder's `Laid.slots`):
	-- players caught on it are stored in its units, until `floor` (the floor's model) is destroyed.
	add: (self: any, deck: Deal.Deck, units: { [Model]: number }, floor: Instance) -> (),
}

-- A laid floor: its deck, units and their slots, its model (where its bangs are marked for
-- every screen) and each unit's latest bang, by slot.
type Floor = {
	deck: Deal.Deck,
	units: { Model },
	slots: { [Model]: number },
	model: Instance,
	bangs: { [number]: Kept.Bang },
}

-- Someone kept: the character they were caught in, its root (anchored while kept), the unit
-- they're stored in and its floor (nil when there was none), the film round them and the value
-- naming their unit once they're in it (`inside`), and when their last bang landed.
type Held = {
	character: Model,
	root: BasePart,
	unit: Model?,
	floor: Floor?,
	wrap: BasePart?,
	value: ObjectValue?,
	inside: boolean,
	banged: number?,
	gone: { RBXScriptConnection },
}

local function box(size: Vector3, centre: Vector3): Kept.Box
	return { size = { size.X, size.Y, size.Z }, centre = { centre.X, centre.Y, centre.Z } }
end
local DRAWN = box(KeptWrap.Body.Size, KeptWrap.Body.Centre)
local WRAP = box(KeptWrap.Wrap.Size, KeptWrap.Wrap.Centre)

-- The body's box standing at rest, from its root: each body part (the character's own parts, not
-- its hats or hair) placed by its joints' rest offsets, Motor6D or AnimationConstraint, so an
-- arm caught mid-swing doesn't size the wrap. Nil when no part hangs off the root.
local function restBox(character: Model, root: BasePart): Kept.Box?
	local links: { { a: BasePart, b: BasePart, offset: CFrame } } = {}
	for _, j in character:GetDescendants() do
		if j:IsA("Motor6D") then
			local a, b = j.Part0, j.Part1
			if a and b then
				table.insert(links, { a = a, b = b, offset = j.C0 * j.C1:Inverse() })
			end
		elseif j:IsA("AnimationConstraint") then
			local a0, a1 = j.Attachment0, j.Attachment1
			local a, b = a0 and a0.Parent, a1 and a1.Parent
			if a0 and a1 and a and b and a:IsA("BasePart") and b:IsA("BasePart") then
				table.insert(links, { a = a, b = b, offset = a0.CFrame * a1.CFrame:Inverse() })
			end
		end
	end
	local at: { [BasePart]: CFrame } = { [root] = CFrame.identity }
	local found = true
	while found do
		found = false
		for _, l in links do
			local from = at[l.a]
			if from and not at[l.b] then
				at[l.b] = from * l.offset
				found = true
			end
		end
	end
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for part, cf in at do
		if part ~= root and part.Parent == character then
			local h = part.Size / 2
			for _, c in
				{
					Vector3.new(1, 1, 1),
					Vector3.new(1, 1, -1),
					Vector3.new(1, -1, 1),
					Vector3.new(1, -1, -1),
				}
			do
				local p, q = cf * (h * c), cf * (-h * c)
				lo, hi = lo:Min(p):Min(q), hi:Max(p):Max(q)
			end
		end
	end
	if lo.X > hi.X then
		return nil
	end
	return box(hi - lo, (hi + lo) / 2)
end

local KeptPlayers = {}

function KeptPlayers.new(): KeptPlayers
	local floors: { [Instance]: Floor } = {}
	local held: { [Player]: Held } = {}
	local holding: { [Model]: Player } = {} -- each unit's kept player
	local connections: { Brix.SignalConnection } = {}
	local joins: { RBXScriptConnection } = {}
	local doors: Doors.Doors? = nil
	local deals: Deals.Deals? = nil
	local slots: Slots.Slots? = nil
	local keepers: Keepers.Keepers? = nil
	local random = Brix.Random.new({ seed = os.time() })
	local warned = false
	local bangRemote: RemoteEvent? = nil

	-- Puts `floor`'s marks on its model for every screen: the bangs still showing at `now`.
	local function publishBangs(floor: Floor, now: number)
		for slot, b in floor.bangs do
			if Kept.mark(now - b.at) <= 0 then
				floor.bangs[slot] = nil
			end
		end
		floor.model:SetAttribute(Kept.BangsAttribute, Kept.encodeBangs(floor.bangs, now))
	end

	-- Wraps `h`'s body head to foot in film, fitted to it at rest and welded to its root: what a
	-- friend finds when they lift the door. No collision, weight or shadow: it's only seen.
	local function wrapUp(h: Held)
		local props = ReplicatedStorage:FindFirstChild("Props")
		local template = props and props:FindFirstChild(Kept.Wrap)
		if not (template and template:IsA("BasePart")) then
			if not warned then
				warned = true
				warn(
					"KeptPlayers: no ReplicatedStorage.Props.KeptWrap, so the kept stand unwrapped (art/keptwrap/README.md)"
				)
			end
			return
		end
		local fit = Kept.fit(restBox(h.character, h.root) or DRAWN, DRAWN, WRAP)
		local offset = CFrame.new(fit.centre[1], fit.centre[2], fit.centre[3])
		local wrap = template:Clone()
		wrap.Size = Vector3.new(fit.size[1], fit.size[2], fit.size[3])
		wrap.Anchored = false
		wrap.CanCollide, wrap.CanTouch, wrap.CanQuery = false, false, false
		wrap.Massless = true
		wrap.CastShadow = false
		wrap.Transparency = Kept.WrapBlend
		wrap.CFrame = h.root.CFrame * offset
		local weld = Instance.new("Weld")
		weld.Part0, weld.Part1, weld.C0 = h.root, wrap, offset
		weld.Parent = wrap
		wrap.Parent = h.character
		h.wrap = wrap
	end

	-- Lets `player` go: their root free, the kept mark off (their screen opens up, keepers see
	-- them again), their unit free for the next.
	local function letGo(player: Player, why: string)
		local h = held[player]
		if not h then
			return
		end
		held[player] = nil
		for _, c in h.gone do
			c:Disconnect()
		end
		if h.unit and holding[h.unit] == player then
			holding[h.unit] = nil
		end
		if h.wrap then
			h.wrap:Destroy()
		end
		if h.value then
			h.value:Destroy()
		end
		-- out: their unit stops marking for friends at once
		local floor, unit = h.floor, h.unit
		local slot = if floor and unit then floor.slots[unit] else nil
		if floor and slot and floor.bangs[slot] and floor.model.Parent then
			floor.bangs[slot] = nil
			publishBangs(floor, Workspace:GetServerTimeNow())
		end
		if h.root.Parent then
			h.root.Anchored = false
		end
		if player.Parent then
			player:SetAttribute(Kept.Attribute, nil)
		end
		if RunService:IsStudio() then
			print(`KeptPlayers: {player.Name} is let out ({why})`)
		end
	end

	-- Whether a keeper's feet stand inside `unit` (face: its door's outer face) of `depth` and
	-- `width` studs: a keeper trapped or roaming in it, whatever its deal said.
	local function keeperIn(face: CFrame, width: number, depth: number): boolean
		local k = keepers
		if not k then
			return false
		end
		local found = false
		k:feet(function(_body: Model, at: Vector3)
			local p = face:PointToObjectSpace(at)
			if math.abs(p.X) < width / 2 and p.Z > 0 and p.Z < depth and math.abs(p.Y) < 4 then
				found = true
			end
		end)
		return found
	end

	-- The unit on `floor` the building stores someone caught at `at` in, or nil.
	local function pick(floor: Floor, at: Vector3): Model?
		local d = doors
		if not d then
			return nil
		end
		local deck = floor.deck
		local list: { Kept.Unit } = {}
		for i, unit in floor.units do
			local index = floor.slots[unit]
			local spec = Specs[deck.floor.slots[index].size]
			local face = FloorBuilder.face(unit)
			local contents = deck.dealt[index]
			list[i] = {
				x = face.Position.X,
				z = face.Position.Z,
				shut = d:stateOf(unit) == "Closed",
				dealt = contents ~= nil,
				keeper = (if contents
					then contents.kind == "Asleep" or contents.kind == "Awake"
					else index == deck.guarded) or keeperIn(face, spec.Width, spec.Depth),
				holding = if holding[unit] then true else false,
			}
		end
		local i = Kept.choose(list, at.X, at.Z, random)
		return if i then floor.units[i] else nil
	end

	-- Where in `unit` its kept player stands: past its middle, facing the door, feet on its floor,
	-- for a root `rootHeight` studs over the feet.
	local function inside(floor: Floor, unit: Model, rootHeight: number): CFrame
		local index = floor.slots[unit]
		local spec = Specs[floor.deck.floor.slots[index].size]
		return FloorBuilder.face(unit) * CFrame.new(0, rootHeight, spec.Depth * Kept.Back)
	end

	local function onCaught(catch: Keepers.Catch)
		local player = catch.player
		if held[player] or not player.Parent then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (character and root and root:IsA("BasePart") and humanoid) then
			player:SetAttribute(Kept.Attribute, nil)
			return
		end
		-- what you carried drops where you stood, before you're held
		if slots then
			slots:dropAll(player)
		end
		root.Anchored = true
		local floor = floors[catch.floor]
		local unit = if floor then pick(floor, root.Position) else nil
		local h: Held = {
			character = character,
			root = root,
			unit = unit,
			floor = if unit then floor else nil,
			inside = false,
			gone = {},
		}
		held[player] = h
		table.insert(
			h.gone,
			humanoid.Died:Connect(function()
				letGo(player, "died")
			end)
		)
		table.insert(
			h.gone,
			character.AncestryChanged:Connect(function()
				if not character.Parent then
					letGo(player, "their character went")
				end
			end)
		)
		if not (floor and unit) then
			if RunService:IsStudio() then
				print(
					`KeptPlayers: no unit free for {player.Name}; held through the wrap where they stand`
				)
			end
			task.delay(Caught.Wrap, function()
				if held[player] == h then
					letGo(player, "no unit to keep them in")
				end
			end)
			return
		end
		holding[unit] = player
		if deals then
			deals:hold(unit)
		end
		local to = inside(floor, unit, humanoid.HipHeight + root.Size.Y / 2)
		-- the unit may be far off: start streaming it in around them while the screen goes black;
		-- held anchored, they can't fall if it isn't in yet
		task.spawn(function()
			local ok, err = pcall(function()
				player:RequestStreamAroundAsync(to.Position)
			end)
			if not ok then
				warn(`KeptPlayers: couldn't stream around {unit.Name} for {player.Name}: {err}`)
			end
		end)
		task.delay(Caught.Dark, function()
			if held[player] ~= h or not character.Parent then
				return
			end
			character:PivotTo(to)
			wrapUp(h)
			h.inside = true
			local value = Instance.new("ObjectValue")
			value.Name = Kept.InsideValue
			value.Value = unit
			value.Parent = player
			h.value = value
			if RunService:IsStudio() then
				print(`KeptPlayers: {player.Name} is wrapped and kept in {unit.Name}`)
			end
		end)
	end

	-- Remotes.Bang: a kept player hits their door. Nothing to check for type (it takes nothing);
	-- range: kept and inside their unit (not in the black on the way there); then the rate, one
	-- bang a door's jolt with a little slack (`Kept.ready`). The door jolts and thuds on every
	-- screen near, and keepers hear it, as a trapped keeper's blow (`Doors:move`); the floor marks
	-- the unit for friends' screens and maps.
	local function onBang(player: Player)
		local h = held[player]
		local floor, unit, d = h and h.floor, h and h.unit, doors
		if not (h and h.inside and floor and unit and d) then
			return
		end
		local now = Workspace:GetServerTimeNow()
		if not Kept.ready(h.banged, now, Kept.BangSlack) then
			return
		end
		local was = h.banged
		h.banged = now
		if not d:move(unit, "Bang") then
			return -- its door is on its way up or down: nothing to hit
		end
		local slot = floor.slots[unit]
		local at = FloorBuilder.face(unit).Position
		floor.bangs[slot] =
			{ slot = slot, user = player.UserId, at = now, x = at.X, y = at.Y, z = at.Z }
		publishBangs(floor, now)
		if RunService:IsStudio() and (was == nil or Kept.mark(now - was) <= 0) then
			print(`KeptPlayers: {player.Name} bangs on {unit.Name}'s door`)
		end
	end

	local function onChanged(change: Doors.DoorChange)
		if change.state ~= "Open" then
			return
		end
		local player = holding[change.unit]
		if player then
			letGo(player, `{change.unit.Name}'s door went all the way up`)
		end
	end

	local system = { name = "KeptPlayers" }

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back plain Systems; Doors, Deals, Slots and Keepers fill these
		doors = (context.registry:get("doors") :: any) :: Doors.Doors?
		deals = (context.registry:get("deals") :: any) :: Deals.Deals?
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		keepers = (context.registry:get("keepers") :: any) :: Keepers.Keepers?
		local k = keepers
		if k then
			table.insert(connections, k.caught:connect(onCaught))
		else
			warn("KeptPlayers: no Keepers system, so nobody is ever kept")
		end
		local d = doors
		if d then
			table.insert(connections, d.changed:connect(onChanged))
		end
		table.insert(
			joins,
			Players.PlayerRemoving:Connect(function(player: Player)
				letGo(player, "left")
			end)
		)
		local folder = ReplicatedStorage:FindFirstChild(Caught.RemoteFolder)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = Caught.RemoteFolder
			folder.Parent = ReplicatedStorage
		end
		local remote = Instance.new("RemoteEvent")
		remote.Name = Kept.BangRemote
		remote.Parent = folder
		bangRemote = remote
		table.insert(joins, remote.OnServerEvent:Connect(onBang))
	end

	function system.stop(_: any)
		for _, c in connections do
			c:disconnect()
		end
		table.clear(connections)
		for _, c in joins do
			c:Disconnect()
		end
		table.clear(joins)
		for player in held do
			letGo(player, "the server stopped")
		end
		table.clear(floors)
		if bangRemote then
			bangRemote:Destroy()
			bangRemote = nil
		end
	end

	function system.add(_: any, deck: Deal.Deck, laid: { [Model]: number }, floor: Instance)
		local units: { Model } = {}
		for unit in laid do
			table.insert(units, unit)
		end
		-- a steady order, so a seed's choices don't hang on how the table iterates
		table.sort(units, function(a: Model, b: Model)
			return laid[a] < laid[b]
		end)
		floors[floor] = { deck = deck, units = units, slots = laid, model = floor, bangs = {} }
		floor.Destroying:Once(function()
			floors[floor] = nil
			for player, h in held do
				if h.unit and laid[h.unit] then
					letGo(player, "their floor went")
				end
			end
		end)
	end

	return system
end

return KeptPlayers
