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

	Take: the fly runs in and the ladder's back on your shoulder (`Slots:handBack`), refused while
	anyone's on it or lying at its top ("Someone's up there"), so nobody is stranded.

	Every press is checked here: a living character within the button's reach (plus lag), not
	pressing faster than a hand can, the ladder in hand to lean it, hands free of it to climb. If
	your screen never moved you, the server puts you where the move ends. Keepers never get these
	buttons, so they can't climb. `climbed` fires as a ladder goes up and as anyone climbs, with how
	far it's heard, for keepers (L-06b).
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
local DOWN_AHEAD = 3.6 -- Climb down: this far into the unit from a lying root (past the head)
local DOWN_UP = 1 -- and this high above the steel top
local SIDE_PIXELS = 150 -- Take beside Climb on screen, as a door's buttons sit (a button's width)
local NEAR_SPOT = 3 -- studs from where a move ends that count as there

export type ClimbEvent = {
	player: Player,
	unit: Model,
	kind: "Raise" | "Up" | "Down",
	at: Vector3,
	reach: number, -- studs it's heard to: a keeper within it hears it
}

export type Ladders = Brix.System & {
	climbed: Brix.Signal<ClimbEvent>,
}

type Stand = {
	id: string, -- the tool's id in Slots
	model: Model,
	front: Front,
	ready: boolean, -- up, its buttons on
	busyUntil: number, -- os.clock() until which a climber is on the rungs
	spots: { [number]: Player }, -- who lies in each spot on the top
	foot: Attachment?,
	parts: { Instance }, -- its buttons' attachments
}
type Front = {
	unit: Model,
	frame: CFrame, -- RollUpDoor.frame
	size: string,
	fit: Leaning.Fit,
	at: Attachment,
	prompt: ProximityPrompt,
	stand: Stand?,
}
type Climb = {
	player: Player,
	character: Model,
	stand: Stand,
	spot: number,
	move: "Up" | "Top" | "Down",
	ends: number, -- os.clock() at which the move is over
	check: number?, -- os.clock() at which the server checks your screen moved you
	standUp: number,
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
		local x, y, z, p = Leaning.lying(c.stand.front.fit, c.spot)
		return Leaned.pose(c.stand.front.frame, x, y, z, p)
	end

	local function stoodAt(c: Climb): CFrame
		local x, y, z, p = Leaning.stood(c.stand.front.fit, c.standUp)
		return Leaned.pose(c.stand.front.frame, x, y, z, p)
	end

	-- A climber off the ladder for good: their spot free, the tag off their character.
	local function clear(c: Climb)
		if climbs[c.player] == c then
			climbs[c.player] = nil
		end
		if c.stand.spots[c.spot] == c.player then
			c.stand.spots[c.spot] = nil
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
				}
			do
				character:SetAttribute(name, nil)
			end
		end
	end

	local function setMove(c: Climb, move: "Up" | "Top" | "Down", restart: boolean)
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
		local spot: number? = nil
		for i = 1, #front.fit.spots do
			if not stand.spots[i] then
				spot = i
				break
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
		local c: Climb = {
			player = player,
			character = character,
			stand = stand,
			spot = spot,
			move = "Up",
			ends = t + up,
			check = nil,
			standUp = standUp,
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

	local function climbDown(stand: Stand, player: Player, refuse: (string) -> ())
		local c = climbs[player]
		if not (c and c.stand == stand and c.move == "Top" and pressOk(player)) then
			return
		end
		local root = rootOf(player)
		if not root or (root.Position - lyingAt(c).Position).Magnitude > NEAR_SPOT + 1 then
			return
		end
		local t = os.clock()
		if t < stand.busyUntil then
			refuse("Wait for them")
			return
		end
		local down = Leaning.downSeconds(stand.front.fit, c.standUp)
		stand.busyUntil = t + down
		c.ends = t + down
		c.check = nil
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
		for _, c in climbs do
			if c.stand == stand then
				refuse(if c.move == "Top" then "Someone's up there" else "Someone's on it")
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
		-- a Climb down button ahead of each lying spot, out of reach from the hall below
		for i = 1, #fit.spots do
			local x, _, z = Leaning.lying(fit, i)
			local at = Instance.new("Attachment")
			at.Name = "LadderDown"
			at.Parent = body
			at.WorldPosition = front.frame * Vector3.new(x, fit.topY + DOWN_UP, z + DOWN_AHEAD)
			table.insert(stand.parts, at)
			local p = Prompts.make(at, {
				objectText = "Ladder",
				actionText = "Climb down",
				key = Enum.KeyCode.E,
				pad = Enum.KeyCode.ButtonX,
				reach = Leaning.DownReach,
			})
			-- lying up there your view is low over the steel, the button just ahead of it
			p.RequiresLineOfSight = false
			local refuseDown = Prompts.refuser(p, ladderName)
			p.Triggered:Connect(function(player: Player)
				climbDown(stand, player, refuseDown)
			end)
		end
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
		local front: Front = {
			unit = unit,
			frame = frame,
			size = size,
			fit = fit,
			at = at,
			prompt = p,
			stand = nil,
		}
		fronts[unit] = front
		p.Triggered:Connect(function(player: Player)
			lean(front, player)
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
	end

	local system = {
		name = "Ladders",
		climbed = climbed,
	}

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

	-- Only climbers: a move over, the server's check that your screen moved you, or the climber
	-- dead or gone.
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
				setMove(c, "Top", false)
				c.check = t + Leaning.EndSlack
			elseif c.move == "Top" and c.check and t >= c.check then
				c.check = nil
				local lying = lyingAt(c)
				if (root.Position - lying.Position).Magnitude > NEAR_SPOT then
					c.character:PivotTo(lying)
				end
			elseif c.move == "Down" and t >= c.ends + Leaning.EndSlack then
				local stood = stoodAt(c)
				clear(c)
				if (root.Position - stood.Position).Magnitude > NEAR_SPOT then
					c.character:PivotTo(stood)
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
