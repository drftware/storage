--!strict
--[[
	Ladders: the ladder leaned on a unit's front and climbed (L-13b2a), a system on the server's Host
	clock. Every unit's front gets a Lean button up by its top edge beside the door (R, R2 on a pad),
	shown only to whoever has the ladder in hand (ToolView). Pressed, the ladder leaves your hand
	(`Slots:place`) and goes up against the front at the 4-to-1 rule; every screen plays it swinging
	up and its fly running out (LadderView), and once it's up it has a Climb button (E) and a Take
	button (F) at its foot for anyone. One ladder per front.

	Climb: the game takes you up it and over the edge onto your belly on the steel top
	(`Leaning.up`), in a spot of your own along the front, as the crawl takes you through a hole:
	your character carries `Leaned.ClimbTag` and the move's attributes, your own screen moves your
	body and every screen plays it. Up there a Climb down button sits just ahead of you; pressed,
	the game takes you back down the ladder into the hall. One climber on the ladder at a time
	("Wait for them"); as many on the top as fit across the unit ("No room up there").

	Up there you crawl (L-13b2c): your screen steers your lying body along the tops (`Tops.step`),
	and the server checks the place it claims every fifth of a second (on the tops, at lying height,
	no faster than a crawl), putting you back where you last were if not. Once you're up you're off
	the ladder: it can be taken, and you can come down any ladder's Climb down or drop off any unit's
	front (Drop down, F): the game takes you over the edge and down into the hall.

	A top sawn through (`holed`, from Saws) comes off the tops' map: nobody crawls over its hole,
	your head may go out over it to look down, and anyone lying across it as it goes through slides
	off its edge onto the steel. The ladder's lying spots on the hole, or across it from the
	ladder, are out; the first, by the ladder, is always clear of it (L-13b2d2c).

	Take: the fly runs in and the ladder's back on your shoulder (`Slots:handBack`), refused while
	anyone's on it ("Someone's on it"). Those up top drop down instead.

	Every press is checked here: a living character within the button's reach (plus lag), not
	pressing faster than a hand can, the ladder in hand to lean it, hands free of it to climb. If
	your screen never moved you, the server puts you where the move ends. Keepers never get these
	buttons, so they can't climb. `climbed` fires as a ladder goes up and as anyone climbs, with how
	far it's heard, for keepers (L-06b), and so do every other pull along the tops and a landing.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Prompts = require(script.Parent.Prompts)
local RollUpDoor = require(ReplicatedStorage.Shared.StorageUnit.RollUpDoor)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local TopHole = require(ReplicatedStorage.Shared.StorageUnit.TopHole)
local Tops = require(ReplicatedStorage.Shared.Tops)
local UnitKit = require(ReplicatedStorage.Shared.StorageUnit.UnitKit)

local Leaning = require(ReplicatedStorage.Shared.Tools.Leaning)
local Leaned = require(ReplicatedStorage.Shared.Tools.Leaned)

local Catalog = Tools.Catalog

local KEY = "Ladder" -- the catalog row that leans
local FOLDER = "Ladders" -- where leaned ladders stand in the Workspace
local BUTTON_DOWN = 0.6 -- the Lean button: this far under the top edge
local BUTTON_OUT = 0.35 -- and this far out from the front's face
local FOOT_UP = 3.5 -- Climb and Take: this high up the ladder, at a standing player's chest
local FOOT_OUT = 0.8 -- and this far out from its middle, on its rungs
-- Climb down and Drop down: just out over the front's edge, a little above the steel, so they're
-- on screen whether you look ahead along the top or down over the edge into the hall (a button
-- back on the steel was behind your view as you looked down)
local EDGE_OUT = 0.6
local EDGE_UP = 0.3
local SPOT_CLEAR = 1.6 -- studs from a crawler's root that a lying spot counts as taken
local SIDE_PIXELS = 150 -- Take beside Climb on screen, as a door's buttons sit (a button's width)
local NEAR_SPOT = 3 -- studs from where a move ends that count as there

export type ClimbEvent = {
	player: Player,
	unit: Model,
	kind: "Raise" | "Up" | "Down" | "Crawl" | "Drop",
	at: Vector3,
	reach: number, -- studs it's heard to: a keeper within it hears it
}

export type Ladders = Brix.System & {
	climbed: Brix.Signal<ClimbEvent>,
	-- whether `player` is lying up on the tops, crawling (not on the rungs or dropping down)
	crawling: (self: Ladders, player: Player) -> boolean,
	-- `unit`'s top just sawn through: its hole off the tops' map, anyone lying on it slid off
	holed: (self: Ladders, unit: Model) -> (),
}

type Stand = {
	id: string, -- the tool's id in Slots
	model: Model,
	front: Front,
	ready: boolean, -- up, its buttons on
	busyUntil: number, -- os.clock() until which a climber is on the rungs
	spots: { [number]: Player }, -- who lies in each spot on the top
	foot: Attachment?,
	top: Attachment?, -- its Climb down button, on the top above it
	parts: { Instance }, -- its buttons' attachments
}
type Front = {
	unit: Model,
	frame: CFrame, -- RollUpDoor.frame
	size: string,
	fit: Leaning.Fit,
	at: Attachment,
	prompt: ProximityPrompt,
	drop: Attachment, -- its Drop down button, for those up on the tops
	stand: Stand?,
}
type Move = "Up" | "Top" | "Down" | "Drop"
type Climb = {
	player: Player,
	character: Model,
	stand: Stand?, -- the ladder you're on, going up or down; nil while you crawl the tops
	front: Front, -- your move's front: the ladder's going up or down, the unit's as you drop
	spot: number,
	move: Move,
	ends: number, -- os.clock() at which the move is over
	check: number?, -- os.clock() at which the server checks your screen moved you
	standUp: number,
	-- crawling the tops: the map under you, your last checked place, how far you've crawled
	map: Tops.Map?,
	origin: CFrame,
	lyingY: number,
	last: CFrame?,
	lastAt: number,
	nextCheck: number,
	travel: number,
	dropX: number,
}

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

-- Your root's height standing: your Humanoid's hip height plus half your root.
local function standUpOf(character: Model, root: BasePart): number
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return (if humanoid then humanoid.HipHeight else 2) + root.Size.Y / 2
end

-- A ladder's buttons' name, put back after a refusal.
local function ladderName(): string
	return "Ladder"
end

local function flyWeld(model: Model): Weld?
	local fly = model:FindFirstChild(KEY .. "Fly")
	local weld = fly and fly:FindFirstChild("FlyWeld")
	return if weld and weld:IsA("Weld") then weld else nil
end

local Ladders = {}

function Ladders.new(): Ladders
	local fronts: { [Model]: Front } = {}
	local climbs: { [Player]: Climb } = {}
	local lastPress: { [Player]: number } = {}
	local connections: { RBXScriptConnection } = {}
	local climbed = Brix.Signal.new() :: Brix.Signal<ClimbEvent>
	local slots: Slots.Slots? = nil
	local folder: Folder? = nil

	-- The rate check: a press closer than a hand can to your last is dropped.
	local function pressOk(player: Player): boolean
		local t = os.clock()
		local last = lastPress[player]
		if last and t - last < Leaning.RepeatSeconds then
			return false
		end
		lastPress[player] = t
		return true
	end

	local function inReach(root: BasePart, at: Vector3, reach: number): boolean
		return (root.Position - at).Magnitude <= reach + Leaning.RangeSlack
	end

	-- The row of what's in `player`'s hand, if anything.
	local function heldRow(player: Player): Tools.Row?
		local s = slots
		if not s then
			return nil
		end
		local keys, hand = s:carried(player)
		return Catalog[keys[hand] or ""]
	end

	local function lyingAt(c: Climb): CFrame
		local x, y, z, p = Leaning.lying(c.front.fit, c.spot)
		return Leaned.pose(c.front.frame, x, y, z, p)
	end

	local function stoodAt(c: Climb): CFrame
		local x, y, z, p = Leaning.stood(c.front.fit, c.standUp)
		return Leaned.pose(c.front.frame, x, y, z, p)
	end

	-- Where a drop off `c.front` lands you, standing in the hall facing out.
	local function landedAt(c: Climb): CFrame
		local fit = c.front.fit
		local x, y, z, p =
			Tops.drop(Tops.DropSeconds, c.dropX, fit.faceZ, fit.topY, Leaning.ProneUp, c.standUp)
		return Leaned.outward(c.front.frame, x, y, z, p)
	end

	--[[
		Whether spot `i` on `front` is clear of every sawn hole: the body lying there all on the
		steel, and the roll from the ladder onto it never over a hole (on a sawn top the spots on
		the hole, or past it from the ladder, are out).
	]]
	local function spotClear(front: Front, i: number): boolean
		local fit = front.fit
		local x, y, z, p = Leaning.lying(fit, i)
		local lying = Leaned.pose(front.frame, x, y, z, p)
		local map, origin = Leaned.tops(lying.Position)
		if not (map and origin) or #map.holes == 0 then
			return true
		end
		local _, top = Leaning.span(fit, 0) -- where the climb tops out doesn't hang on your height
		local ax, ay, az = Leaning.onLadder(fit, top)
		local a = origin:PointToObjectSpace(front.frame * Vector3.new(ax, ay, az))
		local b = origin:PointToObjectSpace(lying.Position)
		local head = origin:VectorToObjectSpace(lying.UpVector)
		local yaw = Tops.yawOf(head.X, head.Z)
		return Tops.fits(map, b.X, b.Z, yaw) and Tops.pathClear(map, a.X, a.Z, b.X, b.Z, yaw)
	end

	--[[
		A crawler whose body no longer lies all on the steel (a top sawn through under them) slides
		off the hole's edge to the nearest place it does: the server moves them and tells their
		screen as it does putting anyone back, and their screen glides them there. True if moved.
	]]
	local function settle(c: Climb, root: BasePart): boolean
		local map = c.map
		if not map then
			return false
		end
		local cf = root.CFrame
		local q = c.origin:PointToObjectSpace(cf.Position)
		local head = c.origin:VectorToObjectSpace(cf.UpVector)
		local yaw = Tops.yawOf(head.X, head.Z)
		if Tops.fits(map, q.X, q.Z, yaw) then
			return false
		end
		local x, z = Tops.settle(map, q.X, q.Z, yaw)
		if not (x and z) then
			return false
		end
		local to = c.origin
			* CFrame.new(x, q.Y, z)
			* CFrame.Angles(0, yaw, 0)
			* CFrame.Angles(-math.pi / 2, 0, 0)
		c.character:PivotTo(to)
		c.character:SetAttribute(Leaned.FixAttribute, to)
		c.last = to
		c.lastAt = os.clock()
		return true
	end

	-- A climber off the ladder for good: their spot free, the tag off their character.
	local function clear(c: Climb)
		if climbs[c.player] == c then
			climbs[c.player] = nil
		end
		local stand = c.stand
		if stand and stand.spots[c.spot] == c.player then
			stand.spots[c.spot] = nil
		end
		local character = c.character
		if character.Parent then
			character:RemoveTag(Leaned.ClimbTag)
			for _, name in
				{
					Leaned.MoveAttribute,
					Leaned.MoveStartAttribute,
					Leaned.FrontAttribute,
					Leaned.SizeAttribute,
					Leaned.SpotAttribute,
					Leaned.DropAttribute,
					Leaned.FixAttribute,
				}
			do
				character:SetAttribute(name, nil)
			end
		end
	end

	local function setMove(c: Climb, move: Move, restart: boolean)
		c.move = move
		c.character:SetAttribute(Leaned.MoveAttribute, move)
		if restart then
			c.character:SetAttribute(Leaned.MoveStartAttribute, now())
		end
	end

	-- A ladder's buttons and tag off, its climbers cleared (they're sent down or it's gone).
	local function dismantle(stand: Stand)
		for _, inst in stand.parts do
			inst:Destroy()
		end
		table.clear(stand.parts)
		stand.foot = nil
		stand.top = nil
		stand.ready = false
		local model = stand.model
		model:RemoveTag(Leaned.Tag)
		model:SetAttribute(Leaned.StartAttribute, nil)
		model:SetAttribute(Leaned.FromAttribute, nil)
		model:SetAttribute(Leaned.ToAttribute, nil)
		for _, c in climbs do
			if c.stand == stand then
				clear(c)
			end
		end
		local front = stand.front
		if front.stand == stand then
			front.stand = nil
			front.prompt.Enabled = true
		end
	end

	local function climbUp(stand: Stand, player: Player, refuse: (string) -> ())
		if not (stand.ready and pressOk(player)) then
			return
		end
		local root = rootOf(player)
		local character = player.Character
		local foot = stand.foot
		if not (root and character and foot) then
			return
		end
		if not inReach(root, foot.WorldPosition, Leaning.ClimbReach) or climbs[player] then
			return
		end
		local front = stand.front
		local held = heldRow(player)
		if held and held.bothHands then
			refuse(`Drop the {string.lower(held.name)} first`)
			return
		end
		local t = os.clock()
		if t < stand.busyUntil then
			refuse("Wait for them")
			return
		end
		-- the first spot nobody's climbing to, no crawler lies on and no sawn hole reaches
		local spot: number? = nil
		for i = 1, #front.fit.spots do
			if not stand.spots[i] and spotClear(front, i) then
				local x, y, z, p = Leaning.lying(front.fit, i)
				local at = Leaned.pose(front.frame, x, y, z, p).Position
				local free = true
				for _, other in climbs do
					local r = if other.move == "Top" then rootOf(other.player) else nil
					if r and ((r.Position - at) * Vector3.new(1, 0, 1)).Magnitude < SPOT_CLEAR then
						free = false
						break
					end
				end
				if free then
					spot = i
					break
				end
			end
		end
		if not spot then
			refuse("No room up there")
			return
		end
		local standUp = standUpOf(character, root)
		local up = Leaning.upSeconds(front.fit, standUp)
		stand.busyUntil = t + Leaning.upBusy(front.fit, standUp)
		stand.spots[spot] = player
		local x, y, z, p = Leaning.lying(front.fit, spot)
		local c: Climb = {
			player = player,
			character = character,
			stand = stand,
			front = front,
			spot = spot,
			move = "Up",
			ends = t + up,
			check = nil,
			standUp = standUp,
			map = nil,
			origin = CFrame.identity,
			lyingY = Leaned.pose(front.frame, x, y, z, p).Position.Y,
			last = nil,
			lastAt = 0,
			nextCheck = 0,
			travel = 0,
			dropX = 0,
		}
		climbs[player] = c
		character:SetAttribute(Leaned.FrontAttribute, front.frame)
		character:SetAttribute(Leaned.SizeAttribute, front.size)
		character:SetAttribute(Leaned.SpotAttribute, spot)
		setMove(c, "Up", true)
		character:AddTag(Leaned.ClimbTag)
		climbed:fire({
			player = player,
			unit = front.unit,
			kind = "Up",
			at = foot.WorldPosition,
			reach = Leaning.ClimbHeard,
		})
	end

	-- Your move's front set on your character, so every screen plays the move against it.
	local function setFront(c: Climb, front: Front, spot: number)
		c.front = front
		c.spot = spot
		c.character:SetAttribute(Leaned.FrontAttribute, front.frame)
		c.character:SetAttribute(Leaned.SizeAttribute, front.size)
		c.character:SetAttribute(Leaned.SpotAttribute, spot)
	end

	-- Climb down at a ladder's top, from wherever you crawled to by it.
	local function climbDown(stand: Stand, player: Player, refuse: (string) -> ())
		local c = climbs[player]
		if not (c and c.move == "Top" and stand.ready and pressOk(player)) then
			return
		end
		local root = rootOf(player)
		local top = stand.top
		if not (root and top and inReach(root, top.WorldPosition, Leaning.DownReach)) then
			return
		end
		local t = os.clock()
		if t < stand.busyUntil then
			refuse("Wait for them")
			return
		end
		local down = Leaning.downSeconds(stand.front.fit, c.standUp)
		stand.busyUntil = t + down
		c.stand = stand
		c.ends = t + down
		c.check = nil
		setFront(c, stand.front, 1)
		setMove(c, "Down", true)
		local foot = stand.foot
		climbed:fire({
			player = player,
			unit = stand.front.unit,
			kind = "Down",
			at = if foot then foot.WorldPosition else root.Position,
			reach = Leaning.ClimbHeard,
		})
	end

	-- Drop down off a unit's front: lying by its edge, over it and down into the hall.
	local function dropDown(front: Front, player: Player)
		local c = climbs[player]
		if not (c and c.move == "Top" and pressOk(player)) then
			return
		end
		local root = rootOf(player)
		if not (root and inReach(root, front.drop.WorldPosition, Tops.DropReach)) then
			return
		end
		local fit = front.fit
		local p = front.frame:PointToObjectSpace(root.Position)
		local width = Leaned.width(front.size)
		if
			math.abs(p.X) > width / 2 + 0.5
			or p.Z < fit.faceZ - 1
			or p.Z > fit.faceZ + Tops.DropNear + Leaning.RangeSlack
			or math.abs(p.Y - (fit.topY + Leaning.ProneUp)) > Tops.HeightSlack
		then
			return
		end
		local t = os.clock()
		c.stand = nil
		c.dropX = Tops.dropX(p.X, width)
		c.ends = t + Tops.DropSeconds
		c.check = nil
		c.character:SetAttribute(Leaned.DropAttribute, c.dropX)
		setFront(c, front, 1)
		setMove(c, "Drop", true)
		climbed:fire({
			player = player,
			unit = front.unit,
			kind = "Drop",
			at = landedAt(c).Position,
			reach = Tops.DropHeard,
		})
	end

	local function take(stand: Stand, player: Player, refuse: (string) -> ())
		local s = slots
		if not (s and stand.ready and pressOk(player)) then
			return
		end
		local root = rootOf(player)
		local foot = stand.foot
		if not (root and foot and inReach(root, foot.WorldPosition, Leaning.ClimbReach)) then
			return
		end
		if climbs[player] then
			return
		end
		-- those up top can drop down or take another ladder, so only a climber on it waits
		for _, c in climbs do
			if c.stand == stand then
				refuse("Someone's on it")
				return
			end
		end
		local weld = flyWeld(stand.model)
		if weld then
			weld.C0 = Leaned.fly(0)
		end
		local refusal = s:handBack(player, stand.id)
		if refusal then
			if weld then
				weld.C0 = Leaned.fly(1)
			end
			if refusal ~= "" then
				refuse(refusal)
			end
			return
		end
		dismantle(stand)
	end

	-- The ladder up: in place, the fly run out, its buttons on.
	local function raised(stand: Stand)
		local front = stand.front
		if front.stand ~= stand then
			return
		end
		local model = stand.model
		local body = Tools.body(model)
		if not body then
			return
		end
		model:PivotTo(Leaned.pivot(front.frame, front.fit))
		local weld = flyWeld(model)
		if weld then
			weld.C0 = Leaned.fly(1)
		end
		local fit = front.fit
		local s, c = math.sin(Leaning.Angle), math.cos(Leaning.Angle)
		local centre = fit.ox - fit.leanX
		local along = (fit.oy + FOOT_OUT * c - FOOT_UP) / s
		local foot = Instance.new("Attachment")
		foot.Name = "LadderButtons"
		foot.Parent = body
		foot.WorldPosition = Leaned.point(front.frame, fit, centre, FOOT_OUT, along)
		table.insert(stand.parts, foot)
		stand.foot = foot
		local climb = Prompts.make(foot, {
			objectText = "Ladder",
			actionText = "Climb",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Leaning.ClimbReach,
		})
		local refuseClimb = Prompts.refuser(climb, ladderName)
		climb.Triggered:Connect(function(player: Player)
			climbUp(stand, player, refuseClimb)
		end)
		local takeIt = Prompts.make(foot, {
			objectText = "Ladder",
			actionText = "Take",
			key = Enum.KeyCode.F,
			pad = Enum.KeyCode.ButtonB,
			reach = Leaning.ClimbReach,
		})
		takeIt.UIOffset = Vector2.new(-SIDE_PIXELS, 0)
		local refuseTake = Prompts.refuser(takeIt, ladderName)
		takeIt.Triggered:Connect(function(player: Player)
			take(stand, player, refuseTake)
		end)
		-- Climb down on the top above it, out of reach from the hall below, for those up there
		local at = Instance.new("Attachment")
		at.Name = "LadderDown"
		at.Parent = body
		at.WorldPosition = front.frame
			* Vector3.new(fit.leanX, fit.topY + EDGE_UP, fit.faceZ - EDGE_OUT)
		table.insert(stand.parts, at)
		stand.top = at
		local down = Prompts.make(at, {
			objectText = "Ladder",
			actionText = "Climb down",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Leaning.DownReach,
		})
		-- lying up there your view is low over the steel, the button just past the edge's lip
		down.RequiresLineOfSight = false
		down:AddTag(Leaned.TopButtonTag)
		local refuseDown = Prompts.refuser(down, ladderName)
		down.Triggered:Connect(function(player: Player)
			climbDown(stand, player, refuseDown)
		end)
		stand.ready = true
	end

	local function lean(front: Front, player: Player)
		local s = slots
		local f = folder
		if not (s and f and front.stand == nil and pressOk(player)) then
			return
		end
		local root = rootOf(player)
		if not (root and inReach(root, front.at.WorldPosition, Leaning.LeanReach)) then
			return
		end
		if climbs[player] then
			return
		end
		local id, model = s:place(player, KEY)
		if not (id and model) then
			return -- the ladder isn't in your hand (your screen shows the button only when it is)
		end
		local from = model:GetPivot()
		local to = Leaned.pivot(front.frame, front.fit)
		local weld = flyWeld(model)
		if weld then
			weld.C0 = Leaned.fly(0)
		end
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		model.Parent = f
		model:SetAttribute(Leaned.StartAttribute, now())
		model:SetAttribute(Leaned.FromAttribute, from)
		model:SetAttribute(Leaned.ToAttribute, to)
		model:AddTag(Leaned.Tag)
		local stand: Stand = {
			id = id,
			model = model,
			front = front,
			ready = false,
			busyUntil = 0,
			spots = {},
			foot = nil,
			top = nil,
			parts = {},
		}
		front.stand = stand
		front.prompt.Enabled = false
		task.delay(Leaning.Raised, function()
			raised(stand)
		end)
		climbed:fire({
			player = player,
			unit = front.unit,
			kind = "Raise",
			at = to.Position,
			reach = Leaning.RaiseHeard,
		})
	end

	local function addFront(unit: Instance)
		if not (unit:IsA("Model") and unit:IsDescendantOf(Workspace)) or fronts[unit] then
			return
		end
		local root = unit.PrimaryPart
		if not root then
			return
		end
		local frame = RollUpDoor.frame(unit)
		local size = (unit:GetAttribute("UnitSize") :: string?) or "M"
		local fit = Leaned.fit(size)
		local at = Instance.new("Attachment")
		at.Name = "LeanButton"
		at.Parent = root
		at.WorldPosition = frame
			* Vector3.new(fit.leanX, fit.edgeY - BUTTON_DOWN, fit.faceZ - BUTTON_OUT)
		local number = string.match(unit.Name, "^Unit(.+)$") or unit.Name
		local name = `Unit {number}`
		local p = Prompts.make(at, {
			objectText = name,
			actionText = "Lean",
			key = Enum.KeyCode.R,
			pad = Enum.KeyCode.ButtonR2, -- R1 is the torch's (D-047)
			reach = Leaning.LeanReach,
		})
		p:AddTag(Tools.LeanTag)
		-- Drop down, over the middle of the front's edge, for those up there (L-13b2c)
		local drop = Instance.new("Attachment")
		drop.Name = "DropButton"
		drop.Parent = root
		drop.WorldPosition = frame * Vector3.new(0, fit.topY + EDGE_UP, fit.faceZ - EDGE_OUT)
		local d = Prompts.make(drop, {
			objectText = name,
			actionText = "Drop down",
			key = Enum.KeyCode.F,
			pad = Enum.KeyCode.ButtonB,
			reach = Tops.DropReach,
		})
		d.RequiresLineOfSight = false
		d:AddTag(Leaned.TopButtonTag)
		local front: Front = {
			unit = unit,
			frame = frame,
			size = size,
			fit = fit,
			at = at,
			prompt = p,
			drop = drop,
			stand = nil,
		}
		fronts[unit] = front
		p.Triggered:Connect(function(player: Player)
			lean(front, player)
		end)
		d.Triggered:Connect(function(player: Player)
			dropDown(front, player)
		end)
	end

	-- A unit gone (a floor taken down): its ladder falls flat at its feet, anyone on it let go.
	local function removeFront(unit: Instance)
		local front = fronts[unit :: Model]
		if not front then
			return
		end
		fronts[unit :: Model] = nil
		local stand = front.stand
		if stand then
			dismantle(stand)
			local s = slots
			if s then
				local _, yaw = front.frame:ToOrientation()
				local feet = front.frame * Vector3.new(front.fit.leanX, 0, front.fit.faceZ - 2)
				s:lower(stand.id, feet, math.deg(yaw) + 90)
			end
		end
		front.at:Destroy()
		front.drop:Destroy()
		for _, c in climbs do
			if c.front == front and c.move ~= "Top" then
				clear(c)
			end
		end
	end

	local system = {
		name = "Ladders",
		climbed = climbed,
	}

	function system.crawling(_: any, player: Player): boolean
		local c = climbs[player]
		return c ~= nil and c.move == "Top"
	end

	function system.holed(_: any, unit: Model)
		local hole = TopHole.frame(unit)
		-- the floor (or test hall) whose tops' map this unit's top is on
		local container: Instance? = unit.Parent
		while container and not container:HasTag(Tops.Tag) do
			container = container.Parent
		end
		if not (hole and container) then
			return
		end
		local text = container:GetAttribute(Tops.MapAttribute)
		local origin = container:GetAttribute(Tops.OriginAttribute)
		if type(text) ~= "string" or typeof(origin) ~= "CFrame" then
			return
		end
		local map = Tops.decode(text)
		if not map then
			return
		end
		local r = TopHole.Rect
		local a = origin:PointToObjectSpace(hole * Vector3.new(r.left, 0, r.front))
		local b = origin:PointToObjectSpace(hole * Vector3.new(r.right, 0, r.back))
		table.insert(map.holes, {
			x0 = math.min(a.X, b.X),
			x1 = math.max(a.X, b.X),
			z0 = math.min(a.Z, b.Z),
			z1 = math.max(a.Z, b.Z),
		})
		container:SetAttribute(Tops.MapAttribute, Tops.encode(map.tops, map.lips, map.holes))
		-- every crawler checked against the new map, anyone lying across the hole slid off it
		for _, c in climbs do
			local root = rootOf(c.player)
			if c.move == "Top" and root then
				local fresh, at = Leaned.tops(root.Position)
				if fresh and at then
					c.map = fresh
					c.origin = at
				end
				settle(c, root)
			end
		end
	end

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; Slots fills this slot (init.server)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots?
		local f = Workspace:FindFirstChild(FOLDER)
		if not f then
			f = Instance.new("Folder")
			f.Name = FOLDER
			f.Parent = Workspace
		end
		folder = f :: Folder
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(UnitKit.Tag):Connect(addFront)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(UnitKit.Tag):Connect(removeFront)
		)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				lastPress[player] = nil
				local c = climbs[player]
				if c then
					clear(c)
				end
			end)
		)
		for _, unit in CollectionService:GetTagged(UnitKit.Tag) do
			addFront(unit)
		end
	end

	-- A crawler's place, checked: on the tops (the map), at lying height, no faster than a crawl.
	-- Off any of those, the server puts you back where you last were and tells your screen.
	local function checkCrawl(c: Climb, root: BasePart, t: number)
		c.nextCheck = t + Tops.CheckEvery
		local p = root.Position
		local last = c.last
		local map = c.map
		local on = true
		if map then
			local q = c.origin:PointToObjectSpace(p)
			on = Tops.near(map, q.X, q.Z, Tops.Slack)
		end
		local moved = if last then ((p - last.Position) * Vector3.new(1, 0, 1)).Magnitude else 0
		local fastest = Tops.Speed * (1 + Tops.Surge) * Tops.FastSlack * (t - c.lastAt)
			+ Tops.LagStuds
		if on and math.abs(p.Y - c.lyingY) <= Tops.HeightSlack and moved <= fastest then
			c.last = root.CFrame
			c.lastAt = t
			c.travel += moved
			-- every other pull's boom is what a keeper below hears
			while c.travel >= Tops.Pull * 2 do
				c.travel -= Tops.Pull * 2
				climbed:fire({
					player = c.player,
					unit = c.front.unit,
					kind = "Crawl",
					at = p,
					reach = Tops.Heard,
				})
			end
		elseif last then
			c.lastAt = t
			c.character:PivotTo(last)
			c.character:SetAttribute(Leaned.FixAttribute, last)
		end
	end

	-- Only climbers: a move over, the server's check that your screen moved you, a crawler's place,
	-- or the climber dead or gone.
	function system.step(_: any, _dt: number)
		if next(climbs) == nil then
			return
		end
		local t = os.clock()
		for _, c in climbs do
			local root = rootOf(c.player)
			if c.player.Character ~= c.character or not root then
				clear(c)
			elseif c.move == "Up" and t >= c.ends then
				-- up: off the ladder, your spot free for the next once you crawl from it
				setMove(c, "Top", false)
				local stand = c.stand
				if stand and stand.spots[c.spot] == c.player then
					stand.spots[c.spot] = nil
				end
				c.stand = nil
				c.check = t + Leaning.EndSlack
				local lying = lyingAt(c)
				local map, origin = Leaned.tops(lying.Position)
				c.map = map
				c.origin = origin or CFrame.identity
			elseif c.move == "Top" and c.check and t >= c.check then
				-- your screen moved you up there (or you're already crawling); if not, the server does
				c.check = nil
				local lying = lyingAt(c)
				local map = c.map
				local q = c.origin:PointToObjectSpace(root.Position)
				local onTops = math.abs(root.Position.Y - c.lyingY) <= Tops.HeightSlack
					and (if map then Tops.near(map, q.X, q.Z, Tops.Slack) else false)
				if (root.Position - lying.Position).Magnitude > NEAR_SPOT and not onTops then
					c.character:PivotTo(lying)
					c.character:SetAttribute(Leaned.FixAttribute, lying)
					c.last = lying
				else
					c.last = root.CFrame
				end
				c.lastAt = t
				c.nextCheck = t + Tops.CheckEvery
				-- a top sawn through under your spot as you climbed: off its edge
				settle(c, root)
			elseif c.move == "Top" and c.last and t >= c.nextCheck then
				checkCrawl(c, root, t)
			elseif c.move == "Down" and t >= c.ends + Leaning.EndSlack then
				local stood = stoodAt(c)
				clear(c)
				if (root.Position - stood.Position).Magnitude > NEAR_SPOT then
					c.character:PivotTo(stood)
				end
			elseif c.move == "Drop" and t >= c.ends + Leaning.EndSlack then
				local landed = landedAt(c)
				clear(c)
				if (root.Position - landed.Position).Magnitude > NEAR_SPOT then
					c.character:PivotTo(landed)
				end
			end
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for _, c in climbs do
			clear(c)
		end
		for unit in fronts do
			removeFront(unit)
		end
		climbed:disconnectAll()
	end

	return system :: any -- any: the table is the Ladders shape built field by field above
end

return Ladders
