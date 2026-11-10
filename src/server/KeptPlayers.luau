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
	middle facing the door (`Kept.Back`), and their screen opens on the dark inside.

	They're let out when their unit's door goes all the way up: the stand-in until L-07d's Cut
	free. Leaving, dying or a new character lets them go too, as does their floor going away. A
	catch on a floor this doesn't know, or with no unit free, holds them through the wrap and lets
	them go where they stand.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Caught = require(ReplicatedStorage.Shared.Caught)
local Deal = require(ReplicatedStorage.Shared.Deal)
local Deals = require(script.Parent.Deals)
local Doors = require(script.Parent.Doors)
local FloorBuilder = require(script.Parent.FloorBuilder)
local Keepers = require(script.Parent.Keepers)
local Kept = require(ReplicatedStorage.Shared.Kept)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)

export type KeptPlayers = Brix.System & {
	-- A laid floor's deck and its units, each by its slot's index (FloorBuilder's `Laid.slots`):
	-- players caught on it are stored in its units, until `floor` (the floor's model) is destroyed.
	add: (self: any, deck: Deal.Deck, units: { [Model]: number }, floor: Instance) -> (),
}

type Floor = { deck: Deal.Deck, units: { Model }, slots: { [Model]: number } }

-- Someone kept: the character they were caught in, its root (anchored while kept), and the unit
-- they're stored in (nil when there was none).
type Held = { character: Model, root: BasePart, unit: Model?, gone: { RBXScriptConnection } }

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
		local h: Held = { character = character, root = root, unit = unit, gone = {} }
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
			if RunService:IsStudio() then
				print(`KeptPlayers: {player.Name} is wrapped and kept in {unit.Name}`)
			end
		end)
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
		floors[floor] = { deck = deck, units = units, slots = laid }
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
