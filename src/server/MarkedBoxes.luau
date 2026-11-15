--!strict
--[[
	Marked boxes on the server (B-02a): the one box in a unit with something in it, and its Open.
	The moment: you press Open and the tape rips, the flaps burst; everyone near hears and sees
	it (MarkedBoxView plays it on every screen), then a held breath in the grade's light and the
	find rises out, turns once and flies into the opener's hand (B-02b). The deal stands one in a
	unit whose find or tool packs into it (Deals, `Deal.packs`, B-03a).

	`stand` puts a marked box (`Boxes.cloneMarked`) at a place in a unit's hall piece, tagged
	`Opening.Tag`, with the unit in an ObjectValue for screens' door checks and one "Open" button
	on its lid. A press is checked as every press is (`Opening.refuse`): not opened yet, a living
	player who isn't wrapped, within `Opening.Reach` of the button, not through a shut door; then
	the rate (`Opening.allow`). Whoever's press arrives first opens it, once: the button goes, and
	the box is stamped with the server's time and the opener (`OpenedAt`, `OpenedBy`). The server
	never moves a flap: its copy stays shut, and only the body is solid, so nothing changes for
	anyone walking into it. An opened box stays where it stood, open, for the rest of the floor.

	What's inside (B-02b) is the server's alone until the open: only then is the box stamped with
	the find's key and grade (`Find`, `Grade`; a tool's key too, B-03a, whose row has no grade,
	so it opens as a Common), in the same batch before `OpenedAt` so every
	screen has them as it starts the reveal. If the opener's hands are full as they open it, the
	box is stamped `LaidAt` too: the find comes out and lands on the floor beside the box, toward
	them, to take as any find is. Otherwise it goes into their hand (`Slots.give`) the moment the
	reveal brings it there (`Opening.handAt`, the grade's hold in it), or lands at that spot if
	their hands filled or they died in the meantime.

	Studio's Workspace `DevBox` deals the next unit any find or tool in one, whatever its size,
	to see every grade's reveal (Deals).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Boxes = require(ReplicatedStorage.Shared.Boxes)
local Brix = require(ReplicatedStorage.Brix)
local Slots = require(script.Parent.Slots)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Prompts = require(script.Parent.Prompts)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local Opening = Boxes.Opening

-- The button sits this far above the lid: over the box, where a thumb finds it.
local BUTTON_ABOVE = 0.4

export type Opened = {
	box: Model,
	unit: Model,
	player: Player,
	find: string?, -- the find's or tool's catalog key, nil for an empty box
}

export type MarkedBoxes = Brix.System & {
	-- Fires as a box is opened, after it's stamped (the find is given later, at `handAt`).
	opened: Brix.Signal<Opened>,
	-- Stands a shut marked box at `place` (the middle of its bottom on the floor, its printed side
	-- facing the place's LookVector) in unit `unit`, into the unit's hall piece, holding find or
	-- tool `find` (a catalog key). Nil when the place lacks the template.
	stand: (self: any, unit: Model, place: CFrame, find: string?) -> Model?,
}

type Standing = {
	box: Model,
	unit: Model,
	button: Vector3,
	prompt: ProximityPrompt,
	find: string?,
}

-- Studs from the box's middle to where a find lands beside it (toward the opener): clear of the
-- box and its open flaps, still within a Take's reach.
local LAID_OUT = 1.9

type Rate = { last: number?, burst: number }

local MarkedBoxes = {}

function MarkedBoxes.new(): MarkedBoxes
	local standing: { [Model]: Standing } = {}
	local rates: { [Player]: Rate } = {}
	local connections: { RBXScriptConnection } = {}
	local opened = Brix.Signal.new() :: Brix.Signal<Opened>
	local slots: Slots.Slots? = nil
	local stopped = false

	-- Whether `player` has a free hand for a find: a slot free, and nothing two-handed held.
	local function room(player: Player): boolean
		local s = slots
		if not s then
			return false
		end
		local keys, hand = s:carried(player)
		local held = Tools.Catalog[keys[hand] or ""]
		return table.find(keys, "") ~= nil and not (held and held.bothHands)
	end

	-- Where a find lands beside the box, toward `from`, and the turn (degrees) that faces it there.
	local function besideBox(box: Model, from: Vector3): (Vector3, number)
		local pivot = box:GetPivot()
		local d = Vector3.new(from.X - pivot.X, 0, from.Z - pivot.Z)
		local dir = if d.Magnitude > 0.1 then d.Unit else pivot.LookVector
		return pivot.Position + dir * LAID_OUT, math.deg(math.atan2(-dir.X, -dir.Z))
	end

	-- The reveal has brought find `key` to `player`'s hand: into it, or onto the floor at `at`.
	local function grant(player: Player, key: string, laid: boolean, at: Vector3, yaw: number)
		local s = slots
		if stopped or not s then
			return
		end
		if not laid and player.Parent and s:give(player, key) then
			return
		end
		s:lay(key, at, yaw)
	end

	local function open(s: Standing, player: Player)
		-- type: Triggered hands us a Player. Range: a box still shut and standing, then the checks.
		if standing[s.box] ~= s or not s.box.Parent then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local alive = humanoid ~= nil
			and humanoid.Health > 0
			and root ~= nil
			and root:IsA("BasePart")
		local at = if alive and root and root:IsA("BasePart") then root.Position else s.button
		local refusal = Opening.refuse({
			opened = s.box:GetAttribute(Opening.OpenedAt) ~= nil,
			alive = alive,
			wrapped = Prompts.wrapped(player),
			distance = (at - s.button).Magnitude,
			apart = alive
				and s.unit:FindFirstChild("DoorOrigin", true) ~= nil
				and StorageUnit.RollUpDoor.keepsApart(s.unit, at, s.button),
		})
		if refusal then
			return -- nothing on any screen: each refusal is plain where the player stands
		end
		-- rate
		local rate = rates[player] or { last = nil, burst = 0 }
		local now = os.clock()
		local may, left = Opening.allow(rate.last, rate.burst, now)
		if not may then
			return
		end
		rates[player] = { last = now, burst = left }

		standing[s.box] = nil
		s.prompt.Enabled = false
		-- what's inside reaches screens only now, before the stamp, in the same batch
		local key = s.find
		local row = if key then Tools.Catalog[key] else nil
		local grade = if row
				and row.grade
				and Opening.Reveals[row.grade]
			then row.grade
			else "Common"
		local laid = key ~= nil and not room(player)
		local spot, yaw = besideBox(s.box, at)
		if key then
			s.box:SetAttribute(Opening.Find, key)
		end
		s.box:SetAttribute(Opening.Grade, grade)
		if laid then
			s.box:SetAttribute(Opening.LaidAt, spot)
		end
		s.box:SetAttribute(Opening.OpenedBy, player.UserId)
		s.box:SetAttribute(Opening.OpenedAt, Workspace:GetServerTimeNow())
		local button = s.prompt.Parent
		s.prompt:Destroy()
		if button then
			button:Destroy()
		end
		if RunService:IsStudio() then
			print(`MarkedBoxes: {player.Name} opened the box in {s.unit.Name}: {key or "nothing"}`)
		end
		if key then
			task.delay(
				Opening.handAt(Opening.Reveals[grade].Hold),
				grant,
				player,
				key,
				laid,
				spot,
				yaw
			)
		end
		opened:fire({ box = s.box, unit = s.unit, player = player, find = key })
	end

	local system = { name = "MarkedBoxes", opened = opened }

	function system.stand(_: any, unit: Model, place: CFrame, find: string?): Model?
		-- set up out of the world, then parented once into the hall piece
		local box = Boxes.cloneMarked(place)
		if not box then
			return nil
		end
		local body = box.PrimaryPart :: BasePart
		local unitValue = Instance.new("ObjectValue")
		unitValue.Name = Opening.UnitValue
		unitValue.Value = unit
		unitValue.Parent = box
		local at = Instance.new("Attachment")
		at.Name = "Open"
		at.Parent = body
		local button = place.Position + Vector3.new(0, Boxes.Marked.Size.Y + BUTTON_ABOVE, 0)
		at.WorldPosition = button
		local prompt = Prompts.make(at, {
			actionText = "Open",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Opening.Reach,
		})
		-- low in a unit full of somebody's stuff: a box mustn't hide another's button (a shut door
		-- still stops a press, on the server and on screens)
		prompt.RequiresLineOfSight = false
		CollectionService:AddTag(box, Opening.Tag)

		local s: Standing =
			{ box = box, unit = unit, button = button, prompt = prompt, find = find }
		standing[box] = s
		prompt.Triggered:Connect(function(player: Player)
			open(s, player)
		end)
		box.Destroying:Once(function()
			if standing[box] == s then
				standing[box] = nil
			end
		end)
		box.Parent = unit.Parent or unit
		return box
	end

	function system.start(_: any, context: Brix.Context)
		slots = (context.registry:get("slots") :: any) :: Slots.Slots? -- any: the registry is untyped
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				rates[player] = nil
			end)
		)
	end

	function system.stop(_: any)
		stopped = true
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		table.clear(standing)
		table.clear(rates)
		opened:disconnectAll()
	end

	return system
end

return MarkedBoxes
