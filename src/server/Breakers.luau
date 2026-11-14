--!strict
--[[
	Breakers: the server owns every floor's breaker box (S2-02b, GDD "The breaker"; the rules are
	`Breaker`'s). FloorBuilder hangs one on each floor it lays, tagged `Breaker.Tag`, its power on.

	`throw(box)` cuts it: every hall light on its floor goes out and stays deaf to motion
	(`MotionLights:cut` on each of its power zones); the elevator keeps its own light. The box's
	`Breaker.OnAttribute` turns false and each screen's BreakerView answers: the lever snaps down
	with one heavy clunk heard across the floor, the pilot lamp red. A Mannequin will throw it
	(S2-02c); for now the dev command does (Studio only: set Workspace's `ThrowBreakers` true from
	the Server's command bar and every box is thrown).

	Thrown, the grip shows a one-second hold button. The server marks the box `Straining` while
	anyone holds it (every screen creeps the lever up under their hand) and judges the hold when it
	lands (`Breaker.judge`: the hold's length seen here, the presser's reach to the grip, up and
	free, one press per breath). A hold that stands switches it back on: the lights come on all at
	once, as real motion lights do when their power returns, then go dark on their own timers;
	every screen hears the hum and sees the lamp go green. A refused hold is ignored: the lever
	falls back under the hand, which says enough.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Breaker = require(ReplicatedStorage.Shared.Breaker)
local Brix = require(ReplicatedStorage.Brix)
local MotionLights = require(script.Parent.MotionLights)
local Prompts = require(script.Parent.Prompts)

local DEV_THROW = "ThrowBreakers" -- Workspace's attribute the dev command sets (Studio only)

type Box = {
	model: Model,
	on: boolean,
	zones: { string },
	grip: Vector3, -- the grip's middle with the lever down, the world's: where the hand goes
	prompt: ProximityPrompt,
	began: { [Player]: number }, -- each holder's hold start, the server's clock
	conns: { RBXScriptConnection },
}

export type Breakers = Brix.System & {
	-- Throws `box` (a placed breaker): its floor's hall lights out. False if it was thrown already.
	throw: (self: any, box: Model) -> boolean,
	-- Every placed box on a floor under `within`, power on or not.
	within: (self: any, within: Instance) -> { Model },
}

local Breakers = {}

local function vec(v: { number }): Vector3
	return Vector3.new(v[1], v[2], v[3])
end

function Breakers.new(): Breakers
	local boxes: { [Model]: Box } = {}
	local last: { [Player]: number } = {} -- each player's last judged press, the server's clock
	local connections: { RBXScriptConnection } = {}
	local lights: MotionLights.MotionLights? = nil

	local function setPower(b: Box, on: boolean)
		b.on = on
		b.model:SetAttribute(Breaker.OnAttribute, on)
		b.prompt.Enabled = not on
		local l = lights
		if l then
			for _, zone in b.zones do
				l:cut(zone, not on)
			end
			if on and b.model.Parent then
				l:flash(b.model.Parent) -- the floor the box hangs on
			end
		end
	end

	local function setStrain(b: Box)
		b.model:SetAttribute(Breaker.StrainAttribute, next(b.began) ~= nil)
	end

	local function switchOn(b: Box, player: Player)
		local now = Workspace:GetServerTimeNow()
		local began = b.began[player]
		b.began[player] = nil
		setStrain(b)
		local since = last[player]
		last[player] = now
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local why = Breaker.judge({
			on = b.on,
			wrapped = Prompts.wrapped(player),
			alive = humanoid ~= nil and humanoid.Health > 0,
			held = if began then now - began else nil,
			since = if since then now - since else nil,
			reach = if root and root:IsA("BasePart")
				then (root.Position - b.grip).Magnitude
				else math.huge,
		})
		if why then
			if RunService:IsStudio() then
				print(`Breakers: {player.Name}'s switch-on refused ({why})`)
			end
			return
		end
		setPower(b, true)
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or boxes[inst] or not inst:IsDescendantOf(Workspace) then
			return -- a tagged template in ReplicatedStorage is no box
		end
		local holder = inst.PrimaryPart
		if not holder then
			warn(`Breakers: {inst:GetFullName()} has no PrimaryPart, so it can't be switched`)
			return
		end
		local zones: { string } = {}
		local listed = inst:GetAttribute(Breaker.ZonesAttribute)
		if type(listed) == "string" then
			for zone in string.gmatch(listed, "[^,]+") do
				table.insert(zones, zone)
			end
		end
		local frame = inst:GetPivot()
		local at = Instance.new("Attachment")
		at.Name = "BreakerGrip"
		at.Parent = holder
		at.WorldCFrame = frame * CFrame.new(vec(Breaker.Specs.GripDown))
		local prompt = Prompts.make(at, {
			actionText = "Switch on",
			key = Enum.KeyCode.E,
			pad = Enum.KeyCode.ButtonX,
			reach = Breaker.Reach,
			hold = Breaker.HoldSeconds,
		})
		prompt.RequiresLineOfSight = false -- the lever's own grip would block it
		local b: Box = {
			model = inst,
			on = inst:GetAttribute(Breaker.OnAttribute) ~= false,
			zones = zones,
			grip = at.WorldPosition,
			prompt = prompt,
			began = {},
			conns = {},
		}
		prompt.Enabled = not b.on
		boxes[inst] = b
		table.insert(
			b.conns,
			prompt.PromptButtonHoldBegan:Connect(function(player: Player)
				if b.on or Prompts.wrapped(player) then
					return
				end
				b.began[player] = Workspace:GetServerTimeNow()
				setStrain(b)
			end)
		)
		table.insert(
			b.conns,
			prompt.PromptButtonHoldEnded:Connect(function(player: Player)
				local began = b.began[player]
				-- a hold let go early never counts toward a later trigger
				if
					began
					and Workspace:GetServerTimeNow() - began
						< Breaker.HoldSeconds - Breaker.HoldSlack
				then
					b.began[player] = nil
				end
				setStrain(b)
			end)
		)
		table.insert(
			b.conns,
			prompt.Triggered:Connect(function(player: Player)
				switchOn(b, player)
			end)
		)
		if not b.on then
			setPower(b, false)
		end
	end

	local function remove(inst: Instance)
		local b = boxes[inst :: any] -- any: the removed signal hands back an Instance
		if not b then
			return
		end
		boxes[inst :: any] = nil
		for _, c in b.conns do
			c:Disconnect()
		end
		-- a floor cleared away thrown leaves no zone cut for the next floor to bear its name
		local l = lights
		if not b.on and l then
			for _, zone in b.zones do
				l:cut(zone, false)
			end
		end
	end

	local system = {} :: Breakers
	system.name = "Breakers"

	function system.start(_: any, context: Brix.Context)
		-- any: the registry hands back a plain System; MotionLights fills this slot (init.server)
		lights = (context.registry:get("motionLights") :: any) :: MotionLights.MotionLights
		table.insert(
			connections,
			CollectionService:GetInstanceAddedSignal(Breaker.Tag):Connect(add)
		)
		table.insert(
			connections,
			CollectionService:GetInstanceRemovedSignal(Breaker.Tag):Connect(remove)
		)
		for _, inst in CollectionService:GetTagged(Breaker.Tag) do
			add(inst)
		end
		table.insert(
			connections,
			Players.PlayerRemoving:Connect(function(player: Player)
				last[player] = nil
				for _, b in boxes do
					if b.began[player] then
						b.began[player] = nil
						setStrain(b)
					end
				end
			end)
		)
		if RunService:IsStudio() then
			table.insert(
				connections,
				Workspace:GetAttributeChangedSignal(DEV_THROW):Connect(function()
					if Workspace:GetAttribute(DEV_THROW) ~= true then
						return
					end
					Workspace:SetAttribute(DEV_THROW, false)
					for model in boxes do
						system:throw(model)
					end
				end)
			)
		end
	end

	function system.stop(_: any)
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		for model in boxes do
			remove(model)
		end
	end

	function system.throw(_: any, box: Model): boolean
		local b = boxes[box]
		if not b or not b.on then
			return false
		end
		table.clear(b.began)
		setStrain(b)
		setPower(b, false)
		return true
	end

	function system.within(_: any, within: Instance): { Model }
		local found: { Model } = {}
		for model in boxes do
			if model:IsDescendantOf(within) then
				table.insert(found, model)
			end
		end
		return found
	end

	return system
end

return Breakers
