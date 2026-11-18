--!strict
--[[
	HaulSteps (S4-05b2a, D-416): the steps of whoever hauls a floor's big find. One friend staggers
	out of the unit with the jukebox held low, and every step lands heavy: a thud and the rattle
	of its insides at them, heard down the hall by everyone near (`Haul.Reach`), so the friends
	watching the halls know where the hauler is without looking, and the hauler's own view dips
	with each one. As Lethal Company's heavy scrap clanks with every step of whoever carries it.

	Who hauls is read from each player's slot attributes (the server's, `Tools`), a few times a
	second; each frame only the haulers are stepped (`Haul.step`), by how far their body moved
	along the floor while it stands on something. Nothing is made between steps.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local Carry = require(ReplicatedStorage.Shared.Tools.Carry)
local Haul = require(ReplicatedStorage.Shared.Haul)
local Tools = require(ReplicatedStorage.Shared.Tools)

local LOOK = 0.25 -- seconds between reads of who hauls a big find

type Hauler = { walked: number, steps: number }

local HaulSteps = {}

-- `jolt` dips your view as your own step lands (CameraShake's trauma).
function HaulSteps.new(jolt: ((amount: number) -> ())?): Brix.System
	local me = Players.LocalPlayer
	local haulers: { [Player]: Hauler } = {}
	local looked = 0

	-- whether `player` holds a big find out in their hands, by their slots
	local function hauls(player: Player): boolean
		if player:GetAttribute(Tools.PocketedAttribute) == true then
			return false
		end
		local hand = player:GetAttribute(Tools.HandAttribute)
		if type(hand) ~= "number" or hand < 1 or hand > Carry.Slots then
			return false
		end
		local key = player:GetAttribute(Tools.slotAttribute(hand))
		return type(key) == "string" and Haul.big(key)
	end

	local function look()
		for _, player in Players:GetPlayers() do
			if hauls(player) then
				if not haulers[player] then
					haulers[player] = { walked = 0, steps = 0 }
				end
			else
				haulers[player] = nil
			end
		end
		for player in haulers do
			if player.Parent ~= Players then
				haulers[player] = nil
			end
		end
	end

	local system = { name = "HaulSteps" }

	function system.start(_: any, _context: Brix.Context) end

	function system.step(_: any, dt: number)
		looked -= dt
		if looked <= 0 then
			looked = LOOK
			look()
		end
		for player, h in haulers do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not (root and root:IsA("BasePart") and humanoid) then
				continue
			end
			if humanoid.FloorMaterial == Enum.Material.Air then
				continue -- falling or jumping: no step till it lands
			end
			local v = root.AssemblyLinearVelocity
			local speed = math.sqrt(v.X * v.X + v.Z * v.Z)
			local walked, lands = Haul.step(h.walked, speed * dt, speed)
			h.walked = walked
			if lands then
				h.steps += 1
				Tools.play(Haul.Thud, root, Haul.Reach)
				Tools.play(Haul.rattle(h.steps), root, Haul.Reach)
				if player == me and jolt then
					jolt(Haul.Jolt)
				end
			end
		end
	end

	function system.stop(_: any)
		table.clear(haulers)
	end

	return system :: any -- any: a plain Brix system built field by field
end

return HaulSteps
