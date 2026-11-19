--!strict
--[[
	ArrangeStill (S5-03j7b, taken out of ArrangeView): you stand still and out of sight while you
	arrange. Arranging takes the whole screen (Bloxburg's build mode): the touch controls hide, the
	walking keys are sunk so a key held moves nobody, the tool wheel slides away, your torch goes out
	of sight, and your own body (and what you hold or wear) is hidden from your eyes, since the build
	camera hangs over where you stand and your head would hide the floor by the door.

	ArrangeView calls `set(true)` as Arrange opens and `set(false)` as it closes. Roblox's camera
	scripts set each part's LocalTransparencyModifier as the camera moves, so while the camera rises
	this holds them hidden each frame after the camera's step; once it's still, nothing rewrites
	them and nothing here steps.
]]
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Arrange = require(ReplicatedStorage.Shared.Home.Arrange)
local Tools = require(ReplicatedStorage.Shared.Tools)

local Feel = Arrange.Feel

local STILL = "ArrangeStill"
local BODY = "ArrangeBody"
-- What first person draws in front of the camera (ToolView's and InfraredView's held things),
-- hidden with your body while arranging: they ride up with the camera.
local VIEWS = { "YourTool", "YourInfrared" }
-- Your torch is FlashlightView's, which sets its own transparency every frame: it puts it out of
-- sight while this is set on the camera (CaughtLunge's, for a catch; its light is left as it was).
local SEIZED = "CaughtSeized"
-- Above the default controls' bindings, so a key held while arranging moves nobody.
local STILL_PRIORITY = Enum.ContextActionPriority.High.Value + 50
local STILL_KEYS = {
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
	Enum.KeyCode.Up,
	Enum.KeyCode.Down,
	Enum.KeyCode.Left,
	Enum.KeyCode.Right,
	Enum.KeyCode.Space,
	Enum.KeyCode.Thumbstick1, -- the left stick slides the build camera (ArrangeCamera)
	Enum.KeyCode.Thumbstick2,
}

export type ArrangeStill = {
	-- Still and hidden while arranging (true), yourself again (false).
	set: (on: boolean) -> (),
}

local ArrangeStill = {}

function ArrangeStill.new(): ArrangeStill
	local me = Players.LocalPlayer
	local touchControls = true
	local hiddenParts: { BasePart } = {}
	local hiddenDecals: { Decal } = {}
	local bodyRun = 0

	local function still(on: boolean)
		if on then
			touchControls = GuiService.TouchControlsEnabled
			GuiService.TouchControlsEnabled = false
			ContextActionService:BindActionAtPriority(STILL, function(): Enum.ContextActionResult
				return Enum.ContextActionResult.Sink
			end, false, STILL_PRIORITY, table.unpack(STILL_KEYS))
		else
			GuiService.TouchControlsEnabled = touchControls
			ContextActionService:UnbindAction(STILL)
		end
	end

	local function fade(value: number)
		for _, p in hiddenParts do
			p.LocalTransparencyModifier = value
		end
		for _, d in hiddenDecals do
			d.LocalTransparencyModifier = value
		end
	end

	local function body(hidden: boolean)
		RunService:UnbindFromRenderStep(BODY)
		bodyRun += 1
		local run = bodyRun
		if hidden then
			table.clear(hiddenParts)
			table.clear(hiddenDecals)
			local roots: { Instance } = {}
			for _, name in VIEWS do
				local held = Workspace:FindFirstChild(name)
				if held then
					table.insert(roots, held)
				end
			end
			if me.Character then
				table.insert(roots, me.Character)
			end
			for _, root in roots do
				for _, d in root:GetDescendants() do
					if d:IsA("BasePart") then
						table.insert(hiddenParts, d)
					elseif d:IsA("Decal") then
						table.insert(hiddenDecals, d)
					end
				end
			end
			RunService:BindToRenderStep(BODY, Enum.RenderPriority.Camera.Value + 1, function()
				fade(1)
			end)
			task.delay(Feel.Rise + 0.1, function()
				if run == bodyRun then
					RunService:UnbindFromRenderStep(BODY)
				end
			end)
		else
			fade(0)
			table.clear(hiddenParts)
			table.clear(hiddenDecals)
		end
	end

	return {
		set = function(on: boolean)
			still(on)
			body(on)
			-- the tool wheel slides away, clear of the room, and comes back up
			me:SetAttribute(Tools.StowAttribute, if on then true else nil)
			local eyes = Workspace.CurrentCamera
			if eyes then
				eyes:SetAttribute(SEIZED, if on then true else nil)
			end
		end,
	}
end

return ArrangeStill
