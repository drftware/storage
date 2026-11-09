--!strict
--[[
	Saws: sawing a crawl hole into the unit beside you (L-12b2, GDD "The hole trap"), a system on
	the server's Host clock. For every two units side by side in a row (`CrawlHole.between`), each
	unit gets a Saw button on its side of the wall they share, at the hole's spot: hold it (R, R2 on
	a pad, as Cut and Lock) with the saw in your hand, and four seconds later the hole is through
	(`CrawlHole.saw`) and its panel clangs down on the far side. Only screens whose player carries a
	saw show the button (ToolView); a saw in your other slot gets "Hold the saw".

	While someone saws, the wall carries the `Sawing.Tag` tag and the hold's start, so every screen
	plays the motor and draws the line growing round the cut (SawView). Every check runs before the
	motor starts, and again before the hole goes through: you're inside the unit you saw from,
	within reach of the button, the saw in your hand, not pressing faster than a hand can, and the
	hold ran its time (a faked press can't cut early). Walk off, drop the saw or die and the cut
	stops.

	`sawing` fires as the motor starts and again as the panel falls, with how far each is heard, so
	keepers (L-06b) hear the saw from anywhere on the floor.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CrawlHole = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole)
local Prompts = require(script.Parent.Prompts)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Sawing = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Sawing)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local Tools = require(ReplicatedStorage.Shared.Tools)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

export type SawEvent = {
	from: Model, -- the unit sawn from
	into: Model, -- the unit the hole leads into
	player: Player,
	done: boolean, -- false as the motor starts, true as the panel falls
	at: Vector3, -- the hole's middle
	reach: number, -- studs it's heard to: a keeper within it hears the saw
}

export type Saws = Brix.System & {
	sawing: Brix.Signal<SawEvent>,
}

-- Where the button sits on the wall: the hole's front third, a little above its middle, so it
-- marks the spot and still shows while you look at the wall from standing.
local BUTTON_UP = 2.2
local BUTTON_OUT = 0.6 -- studs off the wall's middle plane, clear of its collider
-- Units further apart than this (their pivots) can't share a wall.
local NEAR = 20
local INSIDE_SLACK = 0.5 -- studs past a unit's side walls that still count as inside it

type Side = {
	from: Model,
	into: Model,
	at: Attachment,
	prompt: ProximityPrompt,
	refuse: (string) -> (),
}
type Cut = {
	player: Player,
	side: Side,
	started: number, -- server time the motor started
	released: boolean, -- the button let go after its time: waiting on the cut
}
type Pair = {
	wall: BasePart,
	holder: Model, -- the unit standing the wall
	sides: { Side },
	cut: Cut?,
	conns: { RBXScriptConnection },
}

local Saws = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return root
	end
	return nil
end

-- Whether `at` is inside `unit`: past its door, between its side walls, short of its back wall.
local function inside(unit: Model, at: Vector3): boolean
	local size = (unit:GetAttribute("UnitSize") :: string?) or "M"
	local spec = Specs[size] or Specs.M
	local p = RollUpDoor.frame(unit):PointToObjectSpace(at)
	return p.Z > 0
		and p.Z < spec.Depth + INSIDE_SLACK
		and math.abs(p.X) < spec.Width / 2 + INSIDE_SLACK
end

function Saws.new(): Saws
	local units: { [Model]: true } = {}
	local walls: { [BasePart]: Pair } = {} -- each shared wall's pair, by the wall
	local cutting: { [Pair]: true } = {} -- pairs being sawn: only these are stepped
	local lastPress: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local sawing = Brix.Signal.new() :: Brix.Signal<SawEvent>
	local slots: Slots.Slots? = nil

	-- Where `player` has the saw: in hand, in the other slot, or not at all.
	local function holding(player: Player): Sawing.Holding
		if not slots then
			return "None"
		end
		local keys, hand = slots:carried(player)
		local found: Sawing.Holding = "None"
		for i, key in keys do
			if key == "Saw" then
				if i == hand then
					return "Hand"
				end
				found = "Slot"
			end
		end
		return found
	end

	local function holeAt(pair: Pair): Vector3
		local r = CrawlHole.Rect
		return CrawlHole.frame(pair.holder, pair.wall)
			* Vector3.new(0, (r.bottom + r.top) / 2, (r.from + r.to) / 2)
	end

	-- Whether `player` may still be sawing from `side`: alive, inside, in reach, saw in hand.
	local function placed(player: Player, side: Side): boolean
		local root = rootOf(player)
		if not root then
			return false
		end
		local reach = Sawing.Reach + Sawing.RangeSlack
		return (root.Position - side.at.WorldPosition).Magnitude <= reach
			and inside(side.from, root.Position)
	end

	local function stopCut(pair: Pair)
		pair.cut = nil
		cutting[pair] = nil
		local wall = pair.wall
		if wall.Parent then
			wall:RemoveTag(Sawing.Tag)
			wall:SetAttribute(Sawing.StartAttribute, nil)
			wall:SetAttribute(Sawing.ByAttribute, nil)
			wall:SetAttribute(Sawing.FromAttribute, nil)
			wall:SetAttribute(Sawing.FrameAttribute, nil)
		end
	end

	local function drop(pair: Pair)
		if walls[pair.wall] ~= pair then
			return
		end
		walls[pair.wall] = nil
		stopCut(pair)
		for _, c in pair.conns do
			c:Disconnect()
		end
		for _, side in pair.sides do
			side.at:Destroy()
		end
	end

	-- The hold's start: checked, then the motor runs for everyone.
	local function begin(pair: Pair, side: Side, player: Player)
		local t = os.clock()
		local last = lastPress[player]
		if last and t - last < Sawing.RepeatSeconds then
			return
		end
		if not placed(player, side) then
			return
		end
		lastPress[player] = t
		local holed = pair.wall:GetAttribute(CrawlHole.Attribute) ~= nil
		local verdict = Sawing.decide(holding(player), holed, pair.cut ~= nil)
		if not verdict.ok then
			if verdict.refusal then
				side.refuse(verdict.refusal)
			end
			return
		end
		local started = now()
		pair.cut = { player = player, side = side, started = started, released = false }
		cutting[pair] = true
		local frame = CrawlHole.frame(pair.holder, pair.wall)
		local wall = pair.wall
		wall:SetAttribute(Sawing.StartAttribute, started)
		wall:SetAttribute(Sawing.ByAttribute, player.UserId)
		-- which face of the wall the saw is on, in the frame's X: the sparks fly that side
		wall:SetAttribute(
			Sawing.FromAttribute,
			if frame:PointToObjectSpace(side.from:GetPivot().Position).X > 0 then 1 else -1
		)
		wall:SetAttribute(Sawing.FrameAttribute, frame)
		wall:AddTag(Sawing.Tag)
		sawing:fire({
			from = side.from,
			into = side.into,
			player = player,
			done = false,
			at = holeAt(pair),
			reach = Sawing.Heard,
		})
	end

	-- The hold ran its time: checked again, then the hole goes through.
	local function finish(pair: Pair, side: Side, player: Player)
		local cut = pair.cut
		if not (cut and cut.player == player and cut.side == side) then
			return
		end
		if not Sawing.finished(now() - cut.started) then
			return
		end
		if not (placed(player, side) and holding(player) == "Hand") then
			stopCut(pair)
			return
		end
		local at = holeAt(pair)
		stopCut(pair)
		-- the old wall goes (its Destroying drops this pair and both buttons)
		if CrawlHole.saw(side.from, side.into, now()) then
			sawing:fire({
				from = side.from,
				into = side.into,
				player = player,
				done = true,
				at = at,
				reach = Sawing.ClangHeard,
			})
		end
	end

	local function released(pair: Pair, player: Player)
		local cut = pair.cut
		if not (cut and cut.player == player) then
			return
		end
		if Sawing.finished(now() - cut.started) then
			cut.released = true -- the cut may be on its way (Triggered): step drops it if not
		else
			stopCut(pair)
		end
	end

	local function addSide(pair: Pair, from: Model, into: Model, frame: CFrame)
		local root = from.PrimaryPart
		if not root then
			return
		end
		local r = CrawlHole.Rect
		local out = if frame:PointToObjectSpace(from:GetPivot().Position).X > 0 then 1 else -1
		local at = Instance.new("Attachment")
		at.Name = "SawButton"
		at.Parent = root
		-- the hole's front third, so the button sits where the cut begins
		at.WorldCFrame = frame
			* CFrame.new(out * BUTTON_OUT, BUTTON_UP, r.from + (r.to - r.from) / 3)
		local number = string.match(into.Name, "^Unit(.+)$") or into.Name
		local name = `Unit {number}`
		local p = Prompts.make(at, {
			objectText = name,
			actionText = "Saw",
			key = Enum.KeyCode.R,
			pad = Enum.KeyCode.ButtonR2, -- R1 is the torch's (D-047)
			reach = Sawing.Reach,
			hold = Sawing.Seconds,
		})
		p:SetAttribute(Tools.ActionAttribute, "Saw")
		p:AddTag(Tools.SawTag)
		local side: Side = {
			from = from,
			into = into,
			at = at,
			prompt = p,
			refuse = Prompts.refuser(p, function()
				return name
			end),
		}
		table.insert(pair.sides, side)
		table.insert(
			pair.conns,
			p.PromptButtonHoldBegan:Connect(function(player: Player)
				begin(pair, side, player)
			end)
		)
		table.insert(
			pair.conns,
			p.PromptButtonHoldEnded:Connect(function(player: Player)
				released(pair, player)
			end)
		)
		table.insert(
			pair.conns,
			p.Triggered:Connect(function(player: Player)
				finish(pair, side, player)
			end)
		)
	end

	-- Two units side by side in a row: a Saw button each side of the wall they share.
	local function link(a: Model, b: Model)
		local holder, wall = CrawlHole.between(a, b)
		if not (holder and wall) or walls[wall] then
			return
		end
		if wall:GetAttribute(CrawlHole.Attribute) ~= nil then
			return -- holed already (the test hall's)
		end
		local pair: Pair = { wall = wall, holder = holder, sides = {}, cut = nil, conns = {} }
		walls[wall] = pair
		local frame = CrawlHole.frame(holder, wall)
		addSide(pair, a, b, frame)
		addSide(pair, b, a, frame)
		-- sawn (or swapped by anything else): its buttons go with it
		table.insert(
			pair.conns,
			wall.Destroying:Connect(function()
				drop(pair)
			end)
		)
		table.insert(
			pair.conns,
			wall.AncestryChanged:Connect(function()
				if not wall:IsDescendantOf(Workspace) then
					drop(pair)
				end
			end)
		)
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or units[inst] or not inst:IsDescendantOf(Workspace) then
			return
		end
		local unit = inst
		if not unit.PrimaryPart then
			return
		end
		units[unit] = true
		local at = unit:GetPivot().Position
		for other in units do
			if other ~= unit and (other:GetPivot().Position - at).Magnitude < NEAR then
				link(unit, other)
			end
		end
	end

	local function remove(inst: Instance)
		local unit = inst :: Model
		if not units[unit] then
			return
		end
		units[unit] = nil
		local gone = {}
		for _, pair in walls do
			for _, side in pair.sides do
				if side.from == unit then
					table.insert(gone, pair)
					break
				end
			end
		end
		for _, pair in gone do
			drop(pair)
		end
	end

	local system = {
		name = "Saws",
		sawing = sawing,
	}

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Slots fills this slot (init.server)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(add)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(UnitKit.Tag):Connect(remove)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				lastPress[player] = nil
			end)
		)
		for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
			add(inst)
		end
	end

	-- Only walls being sawn: the sawer walked off, dropped the saw, died, or the cut never came.
	function system.step(_: any, _dt: number)
		if next(cutting) == nil then
			return
		end
		local t = now()
		for pair in cutting do
			local cut = pair.cut
			if not cut then
				cutting[pair] = nil
			elseif
				t - cut.started > Sawing.Seconds + Sawing.StaleSeconds
				or not placed(cut.player, cut.side)
				or holding(cut.player) ~= "Hand"
			then
				stopCut(pair)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		local all = {}
		for _, pair in walls do
			table.insert(all, pair)
		end
		for _, pair in all do
			drop(pair)
		end
		table.clear(units)
		sawing:disconnectAll()
	end

	return system
end

return Saws
