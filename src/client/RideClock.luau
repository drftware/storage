--!strict
--[[
	RideClock: seconds into a ride on this screen, read off the server's clock, or in Studio the
	moment Workspace's `Ride.Hold` attribute holds every ride at (for looking at a frame). Shared by
	everything that draws the ride (RideView, ElevatorView, GateClock), so a held frame is whole.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Ride = require(ReplicatedStorage.Shared.Elevator.Ride)

local STUDIO = RunService:IsStudio()

-- Seconds since the ride that began at server time `at` (or `t`, the server time now, if given).
return function(at: number, t: number?): number
	if STUDIO then
		local held = Workspace:GetAttribute(Ride.Hold)
		if type(held) == "number" then
			return held
		end
	end
	return (t or Workspace:GetServerTimeNow()) - at
end
