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

	A unit's top is sawn the same way (L-13b2d2b, as Rainbow Six Siege's floor hatches): its Saw
	button sits over the hole's spot (`TopHole.frame`), only for someone lying up on the tops
	(LadderView) with a saw. The checks are a crawler's: up on this unit's top (Ladders), in reach,
	not lying on the hole, the saw in hand; crawl off, drop down, switch tools or die and the cut
	stops. Through, `TopHole.saw` swaps the top and the panel drops ten studs into the unit.

	`sawing` fires as the motor starts and again as the panel falls, with how far each is heard, so
	keepers (L-06b) hear the saw from anywhere on the floor.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local CrawlHole = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole)
local Ladders = require(script.Parent.Ladders)
local Leaned = require(ReplicatedStorage.Shared.Tools.Leaned)
local Prompts = require(script.Parent.Prompts)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Sawing = require(ReplicatedStorage.Shared.StorageUnit.CrawlHole.Sawing)
local Slots = require(script.Parent.Slots)
local Specs = require(ReplicatedStorage.Shared.StorageUnit.Specs)
local TopHole = require(ReplicatedStorage.Shared.StorageUnit.TopHole)
local Tools = require(ReplicatedStorage.Shared.Tools)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

export type SawEvent = {
	kind: Sawing.Kind, -- a wall between two units, or a unit's top
	from: Model, -- the unit sawn from (a top: the unit lain on)
	into: Model, -- the unit the hole leads into (a top: the same)
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
-- A top's button: over the hole's middle, a little above the steel, where you look lying by it.
local TOP_BUTTON_UP = 0.3
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
-- A place a saw can cut: the wall two units share (a button each side), or a unit's top (one).
type Job = {
	kind: Sawing.Kind,
	part: BasePart, -- the wall, or the unit's top: it carries the Sawing tag while it's sawn
	holder: Model, -- the unit standing it
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
-- Seen from above, so it's also whether `at` is over the unit's top.
local function inside(unit: Model, at: Vector3): boolean
	local size = (unit:GetAttribute("UnitSize") :: string?) or "M"
	local spec = Specs[size] or Specs.M
	local p = RollUpDoor.frame(unit):PointToObjectSpace(at)
	return p.Z > 0
		and p.Z < spec.Depth + INSIDE_SLACK
		and math.abs(p.X) < spec.Width / 2 + INSIDE_SLACK
end

-- Whether a crawler's middle at `at` lies on the hole of the top whose hole frame is `hole`.
local function onHole(hole: CFrame, at: Vector3): boolean
	local q = hole:PointToObjectSpace(at)
	local r = TopHole.Rect
	return Sawing.onHole(q.X, q.Z, r.left, r.right, r.front, r.back)
end

local function unitName(unit: Model): string
	local number = string.match(unit.Name, "^Unit(.+)$") or unit.Name
	return `Unit {number}`
end

function Saws.new(): Saws
	local units: { [Model]: true } = {}
	local jobs: { [BasePart]: Job } = {} -- each wall or top a saw can cut, by the part
	local cutting: { [Job]: true } = {} -- jobs being sawn: only these are stepped
	local lastPress: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local sawing = Brix.Signal.new() :: Brix.Signal<SawEvent>
	local slots: Slots.Slots? = nil
	local ladders: Ladders.Ladders? = nil

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

	-- The hole's middle: in the wall, or in the top's steel.
	local function holeAt(job: Job): Vector3
		if job.kind == "Top" then
			local r = TopHole.Rect
			local hole = TopHole.frame(job.holder) or job.part.CFrame
			return hole * Vector3.new((r.left + r.right) / 2, r.top, (r.front + r.back) / 2)
		end
		local r = CrawlHole.Rect
		return CrawlHole.frame(job.holder, job.part)
			* Vector3.new(0, (r.bottom + r.top) / 2, (r.from + r.to) / 2)
	end

	local function holed(job: Job): boolean
		if job.kind == "Top" then
			return job.part:GetAttribute(TopHole.Attribute) == true
		end
		return job.part:GetAttribute(CrawlHole.Attribute) ~= nil
	end

	--[[
		Whether `player` may still be sawing from `side`: alive, in reach, the saw in hand. A wall:
		standing inside the unit you saw from. A top: lying up on the tops (Ladders), over this
		unit's top and above its steel, not on the hole (unless `onHoleOk`: the press, which
		refuses it out loud).
	]]
	local function placed(player: Player, job: Job, side: Side, onHoleOk: boolean?): boolean
		local root = rootOf(player)
		if not root then
			return false
		end
		local reach = Sawing.Reach + Sawing.RangeSlack
		if (root.Position - side.at.WorldPosition).Magnitude > reach then
			return false
		end
		if not inside(side.from, root.Position) then
			return false
		end
		if job.kind == "Wall" then
			return true
		end
		local hole = TopHole.frame(job.holder)
		return hole ~= nil
			and ladders ~= nil
			and ladders:crawling(player)
			and hole:PointToObjectSpace(root.Position).Y > TopHole.Rect.top
			and (onHoleOk == true or not onHole(hole, root.Position))
	end

	local function stopCut(job: Job)
		job.cut = nil
		cutting[job] = nil
		local part = job.part
		if part.Parent then
			part:RemoveTag(Sawing.Tag)
			part:SetAttribute(Sawing.StartAttribute, nil)
			part:SetAttribute(Sawing.ByAttribute, nil)
			part:SetAttribute(Sawing.FromAttribute, nil)
			part:SetAttribute(Sawing.FrameAttribute, nil)
			part:SetAttribute(Sawing.KindAttribute, nil)
		end
	end

	local function drop(job: Job)
		if jobs[job.part] ~= job then
			return
		end
		jobs[job.part] = nil
		stopCut(job)
		for _, c in job.conns do
			c:Disconnect()
		end
		for _, side in job.sides do
			side.at:Destroy()
		end
	end

	-- The hold's start: checked, then the motor runs for everyone.
	local function begin(job: Job, side: Side, player: Player)
		local t = os.clock()
		local last = lastPress[player]
		if last and t - last < Sawing.RepeatSeconds then
			return
		end
		if not placed(player, job, side, true) then
			return
		end
		-- lying on the hole is refused out loud, not dropped: you're where you should be otherwise
		local root = rootOf(player)
		local hole = if job.kind == "Top" then TopHole.frame(job.holder) else nil
		local lyingOn = hole ~= nil and root ~= nil and onHole(hole, root.Position)
		lastPress[player] = t
		local verdict = Sawing.decide(holding(player), holed(job), job.cut ~= nil, lyingOn)
		if not verdict.ok then
			if verdict.refusal then
				side.refuse(verdict.refusal)
			end
			return
		end
		local frame = if job.kind == "Top"
			then TopHole.cutFrame(job.holder)
			else CrawlHole.frame(job.holder, job.part)
		if not frame then
			return
		end
		local started = now()
		job.cut = { player = player, side = side, started = started, released = false }
		cutting[job] = true
		local part = job.part
		part:SetAttribute(Sawing.StartAttribute, started)
		part:SetAttribute(Sawing.ByAttribute, player.UserId)
		-- which face the saw is on, in the frame's X: the sparks fly that side (a top's: up)
		part:SetAttribute(
			Sawing.FromAttribute,
			if job.kind == "Top"
					or frame:PointToObjectSpace(side.from:GetPivot().Position).X > 0
				then 1
				else -1
		)
		part:SetAttribute(Sawing.FrameAttribute, frame)
		part:SetAttribute(Sawing.KindAttribute, job.kind)
		part:AddTag(Sawing.Tag)
		sawing:fire({
			kind = job.kind,
			from = side.from,
			into = side.into,
			player = player,
			done = false,
			at = holeAt(job),
			reach = Sawing.Heard,
		})
	end

	-- The hold ran its time: checked again, then the hole goes through.
	local function finish(job: Job, side: Side, player: Player)
		local cut = job.cut
		if not (cut and cut.player == player and cut.side == side) then
			return
		end
		if not Sawing.finished(now() - cut.started) then
			return
		end
		if not (placed(player, job, side) and holding(player) == "Hand") then
			stopCut(job)
			return
		end
		local at = holeAt(job)
		stopCut(job)
		-- the old wall or top goes (its Destroying drops this job and its buttons)
		local through = if job.kind == "Top"
			then TopHole.saw(job.holder, now())
			else CrawlHole.saw(side.from, side.into, now())
		if through and job.kind == "Top" and ladders then
			-- its hole off the tops' map, anyone lying across it slid off its edge
			ladders:holed(job.holder)
		end
		if through then
			sawing:fire({
				kind = job.kind,
				from = side.from,
				into = side.into,
				player = player,
				done = true,
				at = at,
				reach = if job.kind == "Top" then Sawing.DropHeard else Sawing.ClangHeard,
			})
		end
	end

	local function released(job: Job, player: Player)
		local cut = job.cut
		if not (cut and cut.player == player) then
			return
		end
		if Sawing.finished(now() - cut.started) then
			cut.released = true -- the cut may be on its way (Triggered): step drops it if not
		else
			stopCut(job)
		end
	end

	-- A Saw button at `cf` for sawing `job` from `from` into `into`.
	local function addSide(job: Job, from: Model, into: Model, cf: CFrame)
		local root = from.PrimaryPart
		if not root then
			return
		end
		local at = Instance.new("Attachment")
		at.Name = "SawButton"
		at.Parent = root
		at.WorldCFrame = cf
		local name = unitName(into)
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
		if job.kind == "Top" then
			p:AddTag(Leaned.TopButtonTag) -- shown only to someone up on the tops (LadderView)
		end
		local side: Side = {
			from = from,
			into = into,
			at = at,
			prompt = p,
			refuse = Prompts.refuser(p, function()
				return name
			end),
		}
		table.insert(job.sides, side)
		table.insert(
			job.conns,
			p.PromptButtonHoldBegan:Connect(function(player: Player)
				begin(job, side, player)
			end)
		)
		table.insert(
			job.conns,
			p.PromptButtonHoldEnded:Connect(function(player: Player)
				released(job, player)
			end)
		)
		table.insert(
			job.conns,
			p.Triggered:Connect(function(player: Player)
				finish(job, side, player)
			end)
		)
	end

	-- A job's part sawn (or swapped by anything else): its buttons go with it.
	local function watch(job: Job)
		local part = job.part
		table.insert(
			job.conns,
			part.Destroying:Connect(function()
				drop(job)
			end)
		)
		table.insert(
			job.conns,
			part.AncestryChanged:Connect(function()
				if not part:IsDescendantOf(Workspace) then
					drop(job)
				end
			end)
		)
	end

	-- Two units side by side in a row: a Saw button each side of the wall they share.
	local function link(a: Model, b: Model)
		local holder, wall = CrawlHole.between(a, b)
		if not (holder and wall) or jobs[wall] then
			return
		end
		if wall:GetAttribute(CrawlHole.Attribute) ~= nil then
			return -- holed already (the test hall's)
		end
		local job: Job =
			{ kind = "Wall", part = wall, holder = holder, sides = {}, cut = nil, conns = {} }
		jobs[wall] = job
		local frame = CrawlHole.frame(holder, wall)
		local r = CrawlHole.Rect
		for _, s in { { a, b }, { b, a } } do
			local out = if frame:PointToObjectSpace(s[1]:GetPivot().Position).X > 0 then 1 else -1
			-- the hole's front third, so the button sits where the cut begins
			addSide(
				job,
				s[1],
				s[2],
				frame * CFrame.new(out * BUTTON_OUT, BUTTON_UP, r.from + (r.to - r.from) / 3)
			)
		end
		watch(job)
	end

	-- A unit's top: one Saw button over its hole's spot, for a crawler lying beside it.
	local function addTop(unit: Model)
		local top = unit:FindFirstChild("Top")
		local hole = TopHole.frame(unit)
		if not (top and top:IsA("BasePart") and hole) or jobs[top] or TopHole.sawn(unit) then
			return
		end
		local job: Job =
			{ kind = "Top", part = top, holder = unit, sides = {}, cut = nil, conns = {} }
		jobs[top] = job
		local r = TopHole.Rect
		addSide(
			job,
			unit,
			unit,
			hole * CFrame.new((r.left + r.right) / 2, r.top + TOP_BUTTON_UP, (r.front + r.back) / 2)
		)
		watch(job)
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
		addTop(unit)
	end

	local function remove(inst: Instance)
		local unit = inst :: Model
		if not units[unit] then
			return
		end
		units[unit] = nil
		local gone = {}
		for _, job in jobs do
			for _, side in job.sides do
				if side.from == unit then
					table.insert(gone, job)
					break
				end
			end
		end
		for _, job in gone do
			drop(job)
		end
	end

	local system = {
		name = "Saws",
		sawing = sawing,
	}

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Slots and Ladders fill these (init.server)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		ladders = (context.registry:get("ladders") :: any) :: Ladders.Ladders?
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

	-- Only jobs being sawn: the sawer walked or crawled off, dropped the saw, died, or the cut
	-- never came.
	function system.step(_: any, _dt: number)
		if next(cutting) == nil then
			return
		end
		local t = now()
		for job in cutting do
			local cut = job.cut
			if not cut then
				cutting[job] = nil
			elseif
				t - cut.started > Sawing.Seconds + Sawing.StaleSeconds
				or not placed(cut.player, job, cut.side)
				or holding(cut.player) ~= "Hand"
			then
				stopCut(job)
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		local all = {}
		for _, job in jobs do
			table.insert(all, job)
		end
		for _, job in all do
			drop(job)
		end
		table.clear(units)
		sawing:disconnectAll()
	end

	return system
end

return Saws
