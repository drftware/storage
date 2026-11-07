--!strict
--[[
	HallHaze: keeps the dust under each lit hall tube (HallLight's haze, D-018) as thick on a
	low-graphics phone as at full quality. Roblox thins an emitter's steady puffs with graphics
	quality, to about (level ÷ 21) of its Rate: a phone on low graphics held under one puff per
	tube where full quality held six (docs/STUDIO.md, "Particles in the hall"). It never thins
	`Emit`, so the server leaves each emitter's Rate at 0 and this client emits a lit tube's puffs
	itself, one at a time at `HallLight.HazeRate`.

	A tube already lit when this client first gets it (joining, or the tube streaming in) throws
	a burst, so its air is dusty from the first look; the server throws the same burst when a tube
	comes on in front of you.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brix = require(ReplicatedStorage.Brix)
local HallLight = require(ReplicatedStorage.Shared.HallLight)
local Pace = require(ReplicatedStorage.Shared.Pace)

local HallHaze = {}

function HallHaze.new(): Brix.System
	-- Each fixture's dust in reach, and the part of its next puff carried between frames.
	local carried: { [ParticleEmitter]: number } = {}
	local connections: { RBXScriptConnection } = {}

	local function add(inst: Instance)
		if not inst:IsA("ParticleEmitter") or carried[inst] ~= nil then
			return
		end
		-- Fixtures start out of step, so the hall's puffs don't arrive in time with each other.
		carried[inst] = math.random()
		if inst.Enabled then
			inst:Emit(HallLight.HazeBurst)
		end
	end

	local function remove(inst: Instance)
		if inst:IsA("ParticleEmitter") then
			carried[inst] = nil
		end
	end

	return {
		name = "HallHaze",
		start = function(_: any, _context: Brix.Context)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(HallLight.HazeTag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(HallLight.HazeTag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(HallLight.HazeTag) do
				add(inst)
			end
		end,
		step = function(_: any, dt: number)
			-- A dark fixture's emitter is disabled (HallLights), so its air stays clear.
			for dust, carry in carried do
				if dust.Enabled then
					local puff, left = Pace.step(carry, dt, HallLight.HazeRate)
					carried[dust] = left
					if puff then
						dust:Emit(1)
					end
				end
			end
		end,
		stop = function(_: any)
			for _, connection in connections do
				connection:Disconnect()
			end
			table.clear(connections)
			table.clear(carried)
		end,
	}
end

return HallHaze
