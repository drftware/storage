--!strict
--[[
	LobbyView: you load in facing the lobby's six cars (L-08e1b1). The server stands you just inside
	the front door turned to them (FrontOffice's spawn), but a camera keeps its old look across a
	new character or a move, so the frame you arrive at that spot, the camera turns the way the
	spawn faces: the cars ahead, level. Coming from the test hall's post (Studio) lands you there
	too.

	Each frame it reads where you stand, after the camera has moved, so the turn it makes is the
	look the camera starts from next frame. Nothing is made per frame.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Lobby = require(ReplicatedStorage.Shared.Lobby)

-- An arrival: you're this close to the spawn (studs) having been this far from it a frame ago,
-- or on your first frame with a character. A walk never covers that in a frame.
local NEAR = 4
local JUMP = 20
-- The turn is made on this many frames in a row, so a camera that resets itself to a new
-- character a frame late still ends up facing the cars.
local FRAMES = 3
local BIND = "LobbyViewTurn"

local LobbyView = {}

function LobbyView.new(): Brix.System
	local spawn = Lobby.spawn(Lobby.Origin)
	local at, look = spawn.Position, spawn.LookVector
	local last: Vector3? = nil -- where you stood last frame; nil with no character
	local turning = 0 -- frames of the turn still to make
	local connections: { RBXScriptConnection } = {}

	local function frame()
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			last = nil
			return
		end
		local p = root.Position
		local before = last
		last = p
		if (p - at).Magnitude <= NEAR and (before == nil or (p - before).Magnitude >= JUMP) then
			turning = FRAMES
		end
		if turning > 0 then
			turning -= 1
			local camera = Workspace.CurrentCamera
			if camera then
				local eye = camera.CFrame.Position
				camera.CFrame = CFrame.lookAt(eye, eye + look)
			end
		end
	end

	return {
		name = "LobbyView",
		start = function(_: any, _context: Brix.Context)
			-- after the camera's own update, so this frame shows the turn
			RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, frame)
			table.insert(
				connections,
				Players.LocalPlayer.CharacterAdded:Connect(function()
					last = nil
				end)
			)
		end,
		stop = function(_: any)
			RunService:UnbindFromRenderStep(BIND)
			for _, c in connections do
				c:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

return LobbyView
