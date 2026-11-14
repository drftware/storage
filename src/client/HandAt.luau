--!strict
--[[
	HandAt: where a player's hands are on this screen, for the things that fly into them: a battery
	into the torch in the right hand (BatteryView, MachineVend), a bought tool into the left
	(MachineVend). Yours are where you see them in your view; a friend's are on their character.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Tools = require(ReplicatedStorage.Shared.Tools)
local Torch = require(ReplicatedStorage.Shared.Flashlight.Torch)

-- Where your own torch sits on your screen when its drawn copy can't be found: low and to the
-- right of your view, as you hold it (studs from the camera).
local OWN_TORCH = CFrame.new(0.55, -0.45, -1.4)
local RAD = math.pi / 180

local me = Players.LocalPlayer

local HandAt = {}

-- Where `player`'s torch is on this screen: yours as drawn in your hand, a friend's in theirs.
function HandAt.torch(player: Player): CFrame?
	if player == me then
		local folder = Workspace:FindFirstChild("YourFlashlight") -- FlashlightView's own torch
		local model = folder and folder:FindFirstChildWhichIsA("Model")
		if model then
			return model:GetPivot()
		end
		local camera = Workspace.CurrentCamera
		return if camera then camera.CFrame * OWN_TORCH else nil
	end
	local character = player.Character
	if not character then
		return nil
	end
	local model = character:FindFirstChild(Torch.ModelName)
	if model and model:IsA("Model") then
		return model:GetPivot()
	end
	local hand = character:FindFirstChild("RightHand") or character.PrimaryPart
	return if hand and hand:IsA("BasePart") then hand.CFrame else nil
end

--[[
	Where tool `key` sits once it's in `player`'s left hand, as its pivot. Yours: where ToolView
	holds it in your view, at full size (it draws it small and near your eye, which looks the same
	from here). A friend's: the real tool in their hand (the server's), or their hand itself.
]]
function HandAt.tool(player: Player, key: string): CFrame?
	local row = (Tools.Catalog :: any)[key] -- any: the catalog is keyed by text
	if player == me then
		local camera = Workspace.CurrentCamera
		if not (camera and row) then
			return nil
		end
		local h, t = row.hold :: { number }, row.holdTurn :: { number }
		return camera.CFrame
			* CFrame.new(h[1], h[2], h[3])
			* CFrame.fromEulerAnglesYXZ(t[2] * RAD, t[1] * RAD, t[3] * RAD)
	end
	local character = player.Character
	if not character then
		return nil
	end
	local held = character:FindFirstChild(Tools.HeldName)
	if held and held:IsA("Model") then
		return held:GetPivot()
	end
	local hand = character:FindFirstChild("LeftHand") or character.PrimaryPart
	return if hand and hand:IsA("BasePart") then hand.CFrame else nil
end

return HandAt
