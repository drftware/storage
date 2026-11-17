--!strict
--[[
	Client system: a cracked find in your own hand shows its crack (F-G1e5e, D-296, `Finds/Chip`).

	The server draws the crack on the find itself, so everyone sees it on the floor and in a
	friend's hand. What's in your own hand is drawn from your view's copy (`ToolView`), made fresh
	from the find's art, so this marks that copy too whenever the find your hand holds is cracked
	(its `Chipped` attribute). Each frame it only looks at your hand until a copy is marked; a copy
	is marked once.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brix = require(ReplicatedStorage.Brix)
local Chip = require(ReplicatedStorage.Shared.Finds.Chip)
local Tools = require(ReplicatedStorage.Shared.Tools)
local ToolView = require(script.Parent.ToolView)

local Catalog = Tools.Catalog

local ChipView = {}

function ChipView.new(hand: ToolView.Hand): Brix.System
	local player = Players.LocalPlayer
	local marked: Model? = nil -- your view's copy already showing its crack
	local stepping: RBXScriptConnection? = nil

	local function step()
		local view, key = hand.model()
		if view == nil or view == marked then
			return
		end
		local character = player.Character
		local held = character and character:FindFirstChild(Tools.HeldName)
		if not held or held:GetAttribute(Chip.Attribute) ~= true then
			return
		end
		local row = Catalog[key]
		local glass = if row then row.fragile else nil
		if glass and Chip.mark(view, glass) then
			marked = view
		end
	end

	return {
		name = "ChipView",
		start = function(_: any, _context: Brix.Context)
			stepping = RunService.Heartbeat:Connect(step)
		end,
		stop = function(_: any)
			if stepping then
				stepping:Disconnect()
				stepping = nil
			end
			marked = nil
		end,
	}
end

return ChipView
