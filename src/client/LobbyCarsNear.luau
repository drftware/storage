--!strict
--[[
	LobbyCarsNear: a lobby car's lamp cage drawn only on a screen near enough to see it
	(S5-03a2d, D-359). On a cheap phone the ground floor's six cars are its heaviest models; their
	lamps' wire cages hang behind the fascia, and from across the room not a pixel of them shows.
	So each car's `Lobby.CarNear.Parts` are hidden (LocalTransparencyModifier, this screen only)
	while the camera is farther than `Lobby.CarNear.Reach` from that car's threshold, and drawn
	again as it comes within it, where they first peek out under the fascia as a hairline. The
	lamp's glass and light are never touched.

	Only lobby cars (Boarding.CarAttribute) are watched: a climb floor's car is the one you ride.
	Cars stream in whole (Atomic), so their parts are there when the tag arrives. Checked a few
	times a second (UnitLight.NearSeconds), as HomeLights checks the fronts' drums.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Boarding = require(ReplicatedStorage.Shared.Lobby.Boarding)
local Brix = require(ReplicatedStorage.Brix)
local Elevator = require(ReplicatedStorage.Shared.Elevator)
local Lobby = require(ReplicatedStorage.Shared.Lobby)
local UnitLight = require(ReplicatedStorage.Shared.UnitLight)

type Car = {
	at: Vector3, -- the threshold's middle (the car's pivot)
	parts: { BasePart },
	near: boolean?, -- whether the camera was within reach at the last check (nil: not yet)
}

local LobbyCarsNear = {}

function LobbyCarsNear.new(): Brix.System
	local cars: { [Instance]: Car } = {}
	local connections: { RBXScriptConnection } = {}
	local untilCheck = 0

	local function show(car: Car, near: boolean)
		car.near = near
		for _, p in car.parts do
			p.LocalTransparencyModifier = if near then 0 else 1
		end
	end

	local function add(inst: Instance)
		if not inst:IsA("Model") or inst:GetAttribute(Boarding.CarAttribute) == nil then
			return
		end
		local parts = {}
		for _, name in Lobby.CarNear.Parts do
			local p = inst:FindFirstChild(name, true)
			if p and p:IsA("BasePart") then
				table.insert(parts, p)
			end
		end
		cars[inst] = { at = inst:GetPivot().Position, parts = parts, near = nil }
		untilCheck = 0 -- check now, so a car streaming in is right from its first frame
	end

	local function remove(inst: Instance)
		local car = cars[inst]
		if car then
			cars[inst] = nil
			show(car, true)
		end
	end

	local function check()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local eye = camera.CFrame.Position
		local reach = Lobby.CarNear.Reach
		for _, car in cars do
			local near = (eye - car.at).Magnitude <= reach
			if near ~= car.near then
				show(car, near)
			end
		end
	end

	return {
		name = "LobbyCarsNear",
		start = function(_: any, _context: Brix.Context)
			table.insert(
				connections,
				CollectionService:GetInstanceAddedSignal(Elevator.Tag):Connect(add)
			)
			table.insert(
				connections,
				CollectionService:GetInstanceRemovedSignal(Elevator.Tag):Connect(remove)
			)
			for _, inst in CollectionService:GetTagged(Elevator.Tag) do
				add(inst)
			end
		end,
		step = function(_: any, dt: number)
			untilCheck -= dt
			if untilCheck <= 0 then
				untilCheck = UnitLight.NearSeconds
				check()
			end
		end,
		stop = function(_: any)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
			for inst in cars do
				remove(inst)
			end
		end,
	}
end

return LobbyCarsNear
