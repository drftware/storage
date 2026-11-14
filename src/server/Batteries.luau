--!strict
--[[
	Batteries on the server (S1-07b): the batteries lying on the floors, a system. The moment it
	serves: your beam is stuttering, you lift a door, and there's a battery on the floor; one tap,
	a clack and a click, and your light snaps back full with the ring sweeping round.

	`Deals` lays a unit's battery as its door first lifts (`lay`, at the spot DealSpot keeps clear
	of whatever else the unit holds, its coins too): the battery MeshPart from
	`ReplicatedStorage.Props.Battery` on its side in the bulb's pool, rolled a little, a faint glint
	on its steel button, and one "Take" button. A take is checked as every press is: a living
	player who isn't wrapped (GDD "Earning nothing"), within `Battery.Reach` of it, not through a
	shut door, then the rate (`Battery.allow`), then their torch: `Flashlights:fill` refuses a torch
	whose ring is still full (`Battery.wants`), and the battery stays where it lies for a friend
	(each screen hides its button from a full torch, BatteryView, so that press is rare).

	A taken battery is stamped with its taker (`Battery.TakenAttribute`) and stays
	`Battery.Linger` seconds so every screen throws it into the taker's torch, then it goes.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Battery = require(ReplicatedStorage.Shared.Battery)
local BatterySpecs = require(ReplicatedStorage.Shared.Battery.Specs)
local Brix = require(ReplicatedStorage.Brix)
local Prompts = require(script.Parent.Prompts)
local StorageUnit = require(ReplicatedStorage.Shared.StorageUnit)

local REACH_SLACK = 2 -- studs the server allows past the button's reach (lag, a long arm)

-- The glint: now and then a spark on its steel button, so it reads from the doorway on a phone.
local GLINT_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

export type Taken = { player: Player, unit: Model }

export type Batteries = Brix.System & {
	-- Fires as someone takes a battery, after their torch is full.
	taken: Brix.Signal<Taken>,
	-- Lays a battery for unit `unit` at `place` (on the floor, facing as DealSpot turns it, the
	-- battery lying along its X), into the unit's hall piece. False when the place lacks its art.
	lay: (self: any, unit: Model, place: CFrame) -> boolean,
	-- How a battery lies at `place` rolled `roll` degrees: its middle a radius up, along X.
	lie: (self: any, place: CFrame, roll: number) -> CFrame,
}

-- What fills a torch: Flashlights, reached through the registry (S1-09).
type Filler = { fill: (self: any, player: Player) -> boolean }

type Lying = {
	part: BasePart,
	unit: Model,
	at: Vector3, -- where it lies, on the floor
	prompt: ProximityPrompt,
}

type Rate = { last: number?, burst: number }

local Batteries = {}

function Batteries.new(): Batteries
	local lying: { [BasePart]: Lying } = {}
	local rates: { [Player]: Rate } = {}
	local connections: { RBXScriptConnection } = {}
	local flashlights: Filler? = nil
	local warned = false
	local taken = Brix.Signal.new() :: Brix.Signal<Taken>

	local function template(): BasePart?
		local props = ReplicatedStorage:FindFirstChild("Props")
		local found = props and props:FindFirstChild(Battery.Template)
		if found and found:IsA("BasePart") then
			return found
		end
		if not warned then
			warned = true
			warn(`Batteries: no ReplicatedStorage.Props.{Battery.Template}, so none are laid`)
		end
		return nil
	end

	local function rootOf(player: Player): BasePart?
		local character = player.Character
		if not character then
			return nil
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return root
		end
		return nil
	end

	local function take(battery: Lying, player: Player)
		-- type: Triggered hands us a Player. Range: a battery still lying there, a living player
		-- who isn't wrapped, near it, on its side of the door.
		if lying[battery.part] ~= battery or not battery.part.Parent then
			return
		end
		if Prompts.wrapped(player) then
			return -- wrapped: no hands to take anything with
		end
		local root = rootOf(player)
		if not root or (root.Position - battery.at).Magnitude > Battery.Reach + REACH_SLACK then
			return
		end
		if
			battery.unit:FindFirstChild("DoorOrigin", true)
			and StorageUnit.RollUpDoor.keepsApart(battery.unit, root.Position, battery.at)
		then
			return -- a shut door between you and it
		end
		-- rate
		local rate = rates[player] or { last = nil, burst = 0 }
		local now = os.clock()
		local may, left = Battery.allow(rate.last, rate.burst, now)
		if not may then
			return
		end
		rates[player] = { last = now, burst = left }
		-- ownership of the light: their torch takes it only with room in it; else it stays here
		if not (flashlights and flashlights:fill(player)) then
			return
		end

		lying[battery.part] = nil
		battery.prompt.Enabled = false
		battery.part:SetAttribute(Battery.TakenAttribute, player.UserId)
		taken:fire({ player = player, unit = battery.unit })
		if RunService:IsStudio() then
			print(`Batteries: {player.Name} took the battery in {battery.unit.Name}, torch full`)
		end
		local part = battery.part
		task.delay(Battery.Linger, function()
			part:Destroy()
		end)
	end

	local function glint(part: BasePart)
		local at = Instance.new("Attachment")
		at.Name = "Glint"
		-- its button, at the battery's +Y end
		at.Position = Vector3.new(0, BatterySpecs.Battery.Size.Y / 2 - 0.03, 0)
		at.Parent = part
		local p = Instance.new("ParticleEmitter")
		p.Name = "Glint"
		p.Texture = GLINT_TEXTURE
		p.Rate = Battery.GlintRate
		p.Lifetime = NumberRange.new(0.3, 0.45)
		p.Speed = NumberRange.new(0)
		p.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.35, 0.5),
			NumberSequenceKeypoint.new(1, 0),
		})
		p.Rotation = NumberRange.new(0, 90)
		p.RotSpeed = NumberRange.new(-90, 90)
		p.Color = ColorSequence.new(Color3.fromRGB(236, 240, 255)) -- steel's cold white
		p.LightEmission = 1
		p.LightInfluence = 0.4 -- brighter in the bulb's light, still there in the dark
		p.Brightness = 2
		p.ZOffset = 0.4
		p.Parent = at
	end

	local system = { name = "Batteries", taken = taken }

	function system.lie(_: any, place: CFrame, roll: number): CFrame
		-- on its side: its length (Y) turned along X, the plus (its X faces) up, then rolled
		return place
			* CFrame.new(0, BatterySpecs.Battery.Radius, 0)
			* CFrame.Angles(0, 0, math.rad(90))
			* CFrame.Angles(0, math.rad(roll), 0)
	end

	function system.lay(_: any, unit: Model, place: CFrame): boolean
		local art = template()
		if not art then
			return false
		end
		local part = art:Clone()
		part.Name = Battery.Template
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false -- no ray stops on it: drops, torches, the keepers' eyes
		part.CFrame = system.lie(system, place, (math.random() * 2 - 1) * Battery.Roll)
		glint(part)
		local at = Instance.new("Attachment")
		at.Name = "Take"
		at.Parent = part
		at.WorldPosition = place.Position + Vector3.new(0, 0.5, 0)
		local prompt = Prompts.make(at, {
			actionText = "Take",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Battery.Reach,
		})
		prompt.RequiresLineOfSight = false -- low on the floor: a box mustn't hide it
		-- which unit's door decides your reach, for screens to hide the Take as this refuses it
		local inUnit = Instance.new("ObjectValue")
		inUnit.Name = Battery.UnitValue
		inUnit.Value = unit
		inUnit.Parent = part
		CollectionService:AddTag(part, Battery.Tag)

		local battery: Lying = { part = part, unit = unit, at = place.Position, prompt = prompt }
		lying[part] = battery
		prompt.Triggered:Connect(function(player: Player)
			take(battery, player)
		end)
		part.Destroying:Once(function()
			if lying[part] == battery then
				lying[part] = nil
			end
		end)
		part.Parent = unit.Parent or unit
		return true
	end

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back plain Systems; Flashlights fills this (init.server)
		flashlights = (context.registry:get("flashlights") :: any) :: Filler?
		table.insert(
			connections,
			game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
				rates[player] = nil
			end)
		)
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		table.clear(lying)
		taken:disconnectAll()
	end

	return system :: any -- any: the table is the Batteries shape built field by field above
end

return Batteries
