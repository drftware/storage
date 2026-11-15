--!strict
--[[
	Marked boxes on the server (B-02a): the one box in a unit with something in it, and its Open.
	The moment: you press Open and the tape rips, the flaps burst; everyone near hears and sees
	it (MarkedBoxView plays it on every screen). B-02b brings the find out of it; B-03 deals what
	goes in.

	`stand` puts a marked box (`Boxes.cloneMarked`) at a place in a unit's hall piece, tagged
	`Opening.Tag`, with the unit in an ObjectValue for screens' door checks and one "Open" button
	on its lid. A press is checked as every press is (`Opening.refuse`): not opened yet, a living
	player who isn't wrapped, within `Opening.Reach` of the button, not through a shut door; then
	the rate (`Opening.allow`). Whoever's press arrives first opens it, once: the button goes, and
	the box is stamped with the server's time and the opener (`OpenedAt`, `OpenedBy`). The server
	never moves a flap: its copy stays shut, and only the body is solid, so nothing changes for
	anyone walking into it. An opened box stays where it stood, open, for the rest of the floor.

	Studio stands one for testing until B-03 deals them (Deals, Workspace `DevBox`).
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Boxes = require(ReplicatedStorage.Shared.Boxes)
local Brix = require(ReplicatedStorage.Brix)
local Prompts = require(script.Parent.Prompts)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local Opening = Boxes.Opening

-- The button sits this far above the lid: over the box, where a thumb finds it.
local BUTTON_ABOVE = 0.4

export type Opened = {
	box: Model,
	unit: Model,
	player: Player,
}

export type MarkedBoxes = Brix.System & {
	-- Fires as a box is opened, after it's stamped: B-02b brings out what was in it.
	opened: Brix.Signal<Opened>,
	-- Stands a shut marked box at `place` (the middle of its bottom on the floor, its printed side
	-- facing the place's LookVector) in unit `unit`, into the unit's hall piece. Nil when the
	-- place lacks the template.
	stand: (self: any, unit: Model, place: CFrame) -> Model?,
}

type Standing = {
	box: Model,
	unit: Model,
	button: Vector3,
	prompt: ProximityPrompt,
}

type Rate = { last: number?, burst: number }

local MarkedBoxes = {}

function MarkedBoxes.new(): MarkedBoxes
	local standing: { [Model]: Standing } = {}
	local rates: { [Player]: Rate } = {}
	local connections: { RBXScriptConnection } = {}
	local opened = Brix.Signal.new() :: Brix.Signal<Opened>

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
		s.box:SetAttribute(Opening.OpenedBy, player.UserId)
		s.box:SetAttribute(Opening.OpenedAt, Workspace:GetServerTimeNow())
		local button = s.prompt.Parent
		s.prompt:Destroy()
		if button then
			button:Destroy()
		end
		if RunService:IsStudio() then
			print(`MarkedBoxes: {player.Name} opened the box in {s.unit.Name}`)
		end
		opened:fire({ box = s.box, unit = s.unit, player = player })
	end

	local system = { name = "MarkedBoxes", opened = opened }

	function system.stand(_: any, unit: Model, place: CFrame): Model?
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

		local s: Standing = { box = box, unit = unit, button = button, prompt = prompt }
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

	function system.start(_: any, _context: Brix.Context)
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				rates[player] = nil
			end)
		)
	end

	function system.stop(_: any)
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
