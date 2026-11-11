--!strict
--[[
	Crawls: crawling through a sawn hole into the unit beside you (L-12b3, GDD "The hole trap"), a
	system on the server's Host clock. Every holed wall (`CrawlHole.Tag`: a saw cut it) gets a
	Crawl button on each side at the hole (E, X on a pad). Press it and the game takes you through
	(`Crawling`): down onto your belly, two pulls, up on your feet in the next unit, under a second
	and a half, as DOORS' and Pressure's vents take you low through a gap. A keeper is far too tall
	for the hole and never gets the button, so it can't follow.

	The press is checked here (you're inside the unit you crawl from, within reach of the button,
	where the server sees you or a moment on, since it sees a run late: `Crawling.counts`;
	not pressing faster than a hand can, not crawling already, nobody else in the hole), then your
	character carries the `Crawling.Tag` tag, the server time and the crawl's frame, and your own
	screen moves your body along the path (CrawlView: Roblox gives each player's screen its own
	body to move). If you're still in the unit you crawled from once the move is over (your screen
	never moved you), the server puts you through itself.

	`crawled` fires as a crawl begins, with how far it's heard, so keepers (L-06b) hear the steel.
]]
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CrawlHole = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole)
local Crawling = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Crawling)
local Prompts = require(script.Parent.Prompts)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local Tools = require(ReplicatedStorage.Shared.Tools)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

export type CrawlEvent = {
	player: Player,
	from: Model, -- the unit crawled out of
	into: Model, -- the unit crawled into
	at: Vector3, -- the hole's middle
	reach: number, -- studs it's heard to: a keeper within it hears the steel
}

export type Crawls = Brix.System & {
	crawled: Brix.Signal<CrawlEvent>,
}

-- Where the button sits: at the hole's middle, a little above it, just off the wall, so it marks
-- the hole and shows while you look at it from standing or crouched.
local BUTTON_UP = 1.7
local BUTTON_OUT = 0.6 -- studs off the wall's middle plane, clear of its collider
local NEAR = 20 -- units further apart than this (their pivots) can't share a wall

type Side = {
	from: Model,
	into: Model,
	frame: CFrame, -- the crawl's frame from this side (Crawling)
	at: Attachment,
	refuse: (string) -> (),
}
type Hole = {
	wall: BasePart,
	sides: { Side },
	busyUntil: number, -- os.clock() until which someone is in it
	conns: { RBXScriptConnection },
}
type Crawl = {
	player: Player,
	character: Model,
	side: Side,
	ends: number, -- os.clock() at which the server checks you're through
}

local Crawls = {}

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

-- A unit's width and depth (studs, its Specs').
local function measure(unit: Model): (number, number)
	local size = (unit:GetAttribute("UnitSize") :: string?) or "M"
	local spec = Specs[size] or Specs.M
	return spec.Width, spec.Depth
end

local function toVector(v: Vector3): vector
	return vector.create(v.X, v.Y, v.Z)
end

-- Whether `at` is inside `unit`: past its door, between its side walls, short of its back wall.
local function inside(unit: Model, at: Vector3): boolean
	local width, depth = measure(unit)
	return Crawling.inside(toVector(RollUpDoor.frame(unit):PointToObjectSpace(at)), width, depth)
end

-- The crawl's frame from `from` through `wall` (stood by `holder`): on the wall's middle plane at
-- the hole's middle, on the floor, looking from `from`'s side to the other.
local function crawlFrame(holder: Model, wall: BasePart, from: Model): CFrame
	local f = CrawlHole.frame(holder, wall)
	local r = CrawlHole.Rect
	local origin = f * Vector3.new(0, 0, (r.from + r.to) / 2)
	local out = if f:PointToObjectSpace(from:GetPivot().Position).X > 0 then 1 else -1
	return CFrame.lookAt(origin, origin - f.XVector * out, f.YVector)
end

-- The collision group a crawling body is in: it touches nothing while the game moves it.
local function registerGroup()
	local name = Crawling.CollisionGroup
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
	for _, g in PhysicsService:GetRegisteredCollisionGroups() do
		PhysicsService:CollisionGroupSetCollidable(name, g.name, false)
	end
end

function Crawls.new(): Crawls
	local holes: { [BasePart]: Hole } = {}
	local waiting: { [BasePart]: true } = {} -- holed walls whose other unit isn't laid yet
	local crawls: { [Player]: Crawl } = {}
	local lastPress: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local crawled = Brix.Signal.new() :: Brix.Signal<CrawlEvent>
	local slots: Slots.Slots? = nil

	local function clear(c: Crawl)
		crawls[c.player] = nil
		local character = c.character
		if character.Parent then
			character:RemoveTag(Crawling.Tag)
			character:SetAttribute(Crawling.StartAttribute, nil)
			character:SetAttribute(Crawling.FrameAttribute, nil)
		end
	end

	-- The move is over: if you never left the unit you crawled from, the server puts you through.
	local function finish(c: Crawl)
		clear(c)
		local root = rootOf(c.player)
		if not (root and c.player.Character == c.character) then
			return
		end
		if inside(c.side.from, root.Position) then
			local humanoid = c.character:FindFirstChildOfClass("Humanoid")
			local standUp = (if humanoid then humanoid.HipHeight else 2) + root.Size.Y / 2
			c.character:PivotTo(c.side.frame * CFrame.new(0, standUp, -Crawling.StandAlong))
		end
	end

	local function crawl(hole: Hole, side: Side, player: Player)
		local t = os.clock()
		local last = lastPress[player]
		if last and t - last < Crawling.RepeatSeconds then
			return
		end
		local root = rootOf(player)
		local character = player.Character
		if not (root and character) then
			return
		end
		-- inside the unit and in reach, where the server sees you or a moment on: it sees a run late,
		-- and a press made as you reach the hole with a keeper behind you must never be lost
		local frame = RollUpDoor.frame(side.from)
		local width, depth = measure(side.from)
		if
			not Crawling.counts(
				toVector(frame:PointToObjectSpace(root.Position)),
				toVector(frame:VectorToObjectSpace(root.AssemblyLinearVelocity)),
				toVector(frame:PointToObjectSpace(side.at.WorldPosition)),
				width,
				depth
			)
		then
			return
		end
		lastPress[player] = t
		-- a big tool (the ladder) won't go through the hole with you
		local s = slots
		if s then
			local keys, hand = s:carried(player)
			local row = Tools.Catalog[keys[hand] or ""]
			if row and row.bothHands then
				side.refuse(`Drop the {string.lower(row.name)} first`)
				return
			end
		end
		local verdict = Crawling.decide(crawls[player] ~= nil, t < hole.busyUntil)
		if not verdict.ok then
			if verdict.refusal then
				side.refuse(verdict.refusal)
			end
			return
		end
		hole.busyUntil = t + Crawling.Seconds
		crawls[player] = {
			player = player,
			character = character,
			side = side,
			ends = t + Crawling.Seconds + Crawling.EndSlack,
		}
		character:SetAttribute(Crawling.FrameAttribute, side.frame)
		character:SetAttribute(Crawling.StartAttribute, now())
		character:AddTag(Crawling.Tag)
		crawled:fire({
			player = player,
			from = side.from,
			into = side.into,
			at = side.frame.Position
				+ Vector3.new(0, (CrawlHole.Rect.bottom + CrawlHole.Rect.top) / 2, 0),
			reach = Crawling.Heard,
		})
	end

	local function drop(hole: Hole)
		if holes[hole.wall] ~= hole then
			return
		end
		holes[hole.wall] = nil
		for _, c in hole.conns do
			c:Disconnect()
		end
		for _, side in hole.sides do
			side.at:Destroy()
		end
	end

	local function addSide(hole: Hole, holder: Model, from: Model, into: Model)
		local root = from.PrimaryPart
		if not root then
			return
		end
		local wall = hole.wall
		local f = CrawlHole.frame(holder, wall)
		local r = CrawlHole.Rect
		local out = if f:PointToObjectSpace(from:GetPivot().Position).X > 0 then 1 else -1
		local at = Instance.new("Attachment")
		at.Name = "CrawlButton"
		at.Parent = root
		at.WorldCFrame = f * CFrame.new(out * BUTTON_OUT, BUTTON_UP, (r.from + r.to) / 2)
		local number = string.match(into.Name, "^Unit(.+)$") or into.Name
		local name = `Unit {number}`
		local p = Prompts.make(at, {
			objectText = name,
			actionText = "Crawl",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Crawling.Reach,
		})
		local frame = crawlFrame(holder, wall, from)
		p:SetAttribute(Crawling.FrameAttribute, frame)
		p:AddTag(Crawling.ButtonTag)
		local side: Side = {
			from = from,
			into = into,
			frame = frame,
			at = at,
			refuse = Prompts.refuser(p, function()
				return name
			end),
		}
		table.insert(hole.sides, side)
		table.insert(
			hole.conns,
			p.Triggered:Connect(function(player: Player)
				if Prompts.wrapped(player) then
					return
				end
				crawl(hole, side, player)
			end)
		)
	end

	-- A holed wall: the unit standing it and the one it leads into, a Crawl button each side.
	local function add(wall: BasePart): boolean
		if holes[wall] or not wall:IsDescendantOf(Workspace) then
			return true
		end
		local holder = wall.Parent
		if not (holder and holder:IsA("Model") and holder:HasTag(UnitKit.Tag)) then
			return true -- not a unit's wall: nothing to crawl between
		end
		local at = holder:GetPivot().Position
		local other: Model? = nil
		for _, inst in CollectionService:GetTagged(UnitKit.Tag) do
			if
				inst ~= holder
				and inst:IsA("Model")
				and (inst:GetPivot().Position - at).Magnitude < NEAR
			then
				local _, shared = CrawlHole.between(holder, inst)
				if shared == wall then
					other = inst
					break
				end
			end
		end
		if not other then
			return false
		end
		local hole: Hole = { wall = wall, sides = {}, busyUntil = 0, conns = {} }
		holes[wall] = hole
		addSide(hole, holder, holder, other)
		addSide(hole, holder, other, holder)
		table.insert(
			hole.conns,
			wall.AncestryChanged:Connect(function()
				if not wall:IsDescendantOf(Workspace) then
					drop(hole)
				end
			end)
		)
		return true
	end

	local function tagged(inst: Instance)
		if not inst:IsA("BasePart") then
			return
		end
		local wall = inst
		-- after the saw's swap settles (the old wall gone, the new one in its place)
		task.defer(function()
			if not add(wall) then
				waiting[wall] = true
			end
		end)
	end

	local function untagged(inst: Instance)
		waiting[inst :: BasePart] = nil
		local hole = holes[inst :: BasePart]
		if hole then
			drop(hole)
		end
	end

	-- A unit laid after its holed neighbour: try the walls still waiting for theirs.
	local function unitAdded(_: Instance)
		if next(waiting) == nil then
			return
		end
		task.defer(function()
			for wall in waiting do
				if not wall:IsDescendantOf(Workspace) or add(wall) then
					waiting[wall] = nil
				end
			end
		end)
	end

	local system = {
		name = "Crawls",
		crawled = crawled,
	}

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Slots fills this slot (init.server)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		registerGroup()
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(CrawlHole.Tag):Connect(tagged)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(CrawlHole.Tag):Connect(untagged)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(unitAdded)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				lastPress[player] = nil
				local c = crawls[player]
				if c then
					clear(c)
				end
			end)
		)
		for _, inst in CollectionService:GetTagged(CrawlHole.Tag) do
			tagged(inst)
		end
	end

	-- Only players crawling: the move over, or the crawler caught, dead or gone.
	function system.step(_: any, _dt: number)
		if next(crawls) == nil then
			return
		end
		local t = os.clock()
		for _, c in crawls do
			-- gone, or caught: a caught crawler's crawl ends where they are, never put through;
			-- KeptPlayers has them now
			if
				c.player.Character ~= c.character
				or not rootOf(c.player)
				or Prompts.wrapped(c.player)
			then
				clear(c)
			elseif t >= c.ends then
				finish(c)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		local all = {}
		for _, hole in holes do
			table.insert(all, hole)
		end
		for _, hole in all do
			drop(hole)
		end
		for _, c in crawls do
			clear(c)
		end
		table.clear(waiting)
		crawled:disconnectAll()
	end

	return system
end

return Crawls
