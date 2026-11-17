--!strict
--[[
	HeadView: the find you wear on your head never fills your own view (F-G1b4a1, D-282).
	The moment: you put the hard hat on and look ahead down a dark hall, its lamp lighting the way
	from your brow, with no shell or brim in your eye. Your friends see the hat on you, and so does
	the mirror at home (MirrorView's copy keeps its own look).

	The server welds the hat to your head (`Slots`), so it's part of your character. Roblox hides
	your body in first person only while its own camera runs: under a camera the game holds (a
	crawl under a door, a held shot) a hat put on then showed, its shell over your view. So here,
	each frame after the camera has moved, your own worn find is hidden from your eye alone
	(`LocalTransparencyModifier`, eased by `Head.hidden` and `Head.fade`) while the camera is at
	your head, and kept at least as hidden as your head is (a view that hides your whole body hides
	the hat with it). Nothing is sent to the server, and its lights stay on: a part's local
	transparency never touches a light.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Head = require(ReplicatedStorage.Shared.Finds.Head)

-- after the camera's own step and CameraShake's kick (Camera + 1), so the camera is where it draws
local STEP = "HeadViewOwnEye"
local PRIORITY = Enum.RenderPriority.Camera.Value + 2

local HeadView = {}

function HeadView.new(): Brix.System
	local player = Players.LocalPlayer
	local worn: Model? = nil -- the find on your head now
	local parts: { BasePart } = {} -- what of it draws
	local decals: { Decal } = {}
	local hide = 0 -- how hidden from your eye it is now (eased)

	-- Hands a find that left your head back to whoever draws it next (on the floor, in a slot).
	local function release()
		for _, p in parts do
			p.LocalTransparencyModifier = 0
		end
		for _, d in decals do
			d.LocalTransparencyModifier = 0
		end
		table.clear(parts)
		table.clear(decals)
		worn = nil
	end

	local function wear(model: Model)
		release()
		worn = model
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
			elseif d:IsA("Decal") then
				table.insert(decals, d)
			end
		end
	end

	local function step(dt: number)
		local character = player.Character
		local found = if character then character:FindFirstChild(Head.ModelName) else nil
		local model = if found
				and found:IsA("Model")
				and found:GetAttribute(Head.WornAttribute) == player.UserId
			then found
			else nil
		if model ~= worn then
			if model then
				wear(model)
				-- a hat put on with the camera already at your head starts hidden, never pops in
				hide = 1
			else
				release()
			end
		end
		local head = if character and model then character:FindFirstChild("Head") else nil
		local camera = Workspace.CurrentCamera
		if not (head and head:IsA("BasePart") and camera) then
			return
		end
		local goal = Head.hidden((camera.CFrame.Position - head.Position).Magnitude)
		hide = Head.fade(hide, goal, dt)
		local amount = math.max(hide, head.LocalTransparencyModifier)
		for _, p in parts do
			if p.LocalTransparencyModifier ~= amount then
				p.LocalTransparencyModifier = amount
			end
		end
		for _, d in decals do
			if d.LocalTransparencyModifier ~= amount then
				d.LocalTransparencyModifier = amount
			end
		end
	end

	return {
		name = "HeadView",
		start = function(_: any, _context: Brix.Context)
			RunService:BindToRenderStep(STEP, PRIORITY, step)
		end,
		stop = function(_: any)
			RunService:UnbindFromRenderStep(STEP)
			release()
		end,
	}
end

return HeadView
