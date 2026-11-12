--!strict
--[[
	TripCover: you arrive on your group's own server under the black you left the lobby in
	(L-08e1c). Roblox shows the teleport's screen (TripView set it) while this server loads, then
	drops it; this keeps it up, opaque, until TripView lifts it as the climb opens around you.
	Runs first, before anything else of ours, so no frame of the front office shows through.
]]
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")

local ok, gui = pcall(function()
	return TeleportService:GetArrivingTeleportGui()
end)
if ok and gui and gui:IsA("ScreenGui") then
	ReplicatedFirst:RemoveDefaultLoadingScreen()
	gui.Name = "TripCover" -- TripView looks for it by this name
	gui.ResetOnSpawn = false
	local black = gui:FindFirstChild("Black")
	if black and black:IsA("Frame") then
		black.BackgroundTransparency = 0
	end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end
