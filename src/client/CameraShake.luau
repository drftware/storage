--!strict
--[[
	CameraShake: jolts this player's view when something heavy hits nearby (the slammed door
	first). `kick(amount)` adds trauma; Shake turns it into a shiver that dies away. `hold(pose)`
	sets a steady motion of the view's own, read each frame (the ride's sway, L-08a), under any
	shake; `hold(nil)` lets it go.

	It sits on top of Roblox's own camera without fighting it: just before the camera updates each
	frame it takes its last offset back off, and just after, it puts the new one on. The camera
	never reads a shaken view, so the shake can't drift your aim, and it costs nothing while still.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Brix = require(ReplicatedStorage.Brix)
local Shake = require(ReplicatedStorage.Shared.Shake)

local UNDO = "CameraShakeUndo"
local APPLY = "CameraShakeApply"

local CameraShake = {}

-- Where a held motion puts the view this frame, in the camera's own space (nil: as it is).
export type Pose = () -> CFrame?

-- The system, the function that kicks the view (amount is Shake trauma, 0..1), and the one that
-- holds a motion of its own on it.
function CameraShake.new(): (Brix.System, (amount: number) -> (), (pose: Pose?) -> ())
	local trauma = 0
	local clock = 0
	local applied: CFrame? = nil -- the offset on the camera now, taken off before it updates
	local held: Pose? = nil
	local bound = false

	local function undo()
		local camera = Workspace.CurrentCamera
		if applied and camera then
			camera.CFrame *= applied:Inverse()
		end
		applied = nil
	end

	local function apply(dt: number)
		if trauma <= 0 and not held then
			return
		end
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local offset = if held then held() else nil
		if trauma > 0 then
			clock += dt
			local pitch, yaw, roll, x, y = Shake.offset(trauma, clock)
			local shake = CFrame.new(x, y, 0) * CFrame.fromOrientation(pitch, yaw, roll)
			offset = if offset then offset * shake else shake
			trauma = Shake.decay(trauma, dt)
		end
		if offset then
			camera.CFrame *= offset
			applied = offset
		end
	end

	local system: Brix.System = {
		name = "CameraShake",
		start = function(_: any, _context: Brix.Context)
			RunService:BindToRenderStep(UNDO, Enum.RenderPriority.Camera.Value - 1, undo)
			RunService:BindToRenderStep(APPLY, Enum.RenderPriority.Camera.Value + 1, apply)
			bound = true
		end,
		stop = function(_: any)
			if bound then
				RunService:UnbindFromRenderStep(UNDO)
				RunService:UnbindFromRenderStep(APPLY)
				bound = false
			end
			undo()
			trauma = 0
		end,
	}

	local function kick(amount: number)
		trauma = Shake.add(trauma, amount)
	end

	local function hold(pose: Pose?)
		held = pose
	end

	return system, kick, hold
end

return CameraShake
