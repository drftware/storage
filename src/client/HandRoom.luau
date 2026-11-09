--!strict
--[[
	The world side of `Hands` (L-13b2c2, D-060): how much room there is ahead of your eye for what
	you hold, how far ahead of your eye a held thing reaches, and where a torch's beam can start
	without being past a surface. Only solid things count (`RespectCanCollide`): a zone or a
	button's part never pushes your hands about. One shared check, no tables made per frame.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Hands = require(ReplicatedStorage.Shared.Hands)

local HandRoom = {}

local mine = RaycastParams.new()
mine.FilterType = Enum.RaycastFilterType.Exclude
mine.RespectCanCollide = true
local filtered: Model? = nil

-- The check that skips your own body (refreshed only when your body changes).
local function own(): RaycastParams
	local character = Players.LocalPlayer.Character
	if character ~= filtered then
		filtered = character
		mine.FilterDescendantsInstances = if character then { character } else {}
	end
	return mine
end

-- A check that skips a friend's own body, for their beam (made once per friend).
function HandRoom.skipping(character: Model): RaycastParams
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.RespectCanCollide = true
	p.FilterDescendantsInstances = { character }
	return p
end

--[[
	How far ahead of your eye (`cam`) the nearest solid surface is, if it's within `reach` and the
	margin; nil when there's room. The check starts behind your eye, inside your head, so a wall
	your nose is against still counts.
]]
function HandRoom.room(cam: CFrame, reach: number): number?
	local look = cam.LookVector
	local hit = Workspace:Spherecast(
		cam.Position - look * Hands.Back,
		Hands.Radius,
		look * (Hands.Back + reach + Hands.Margin),
		own()
	)
	return if hit then hit.Distance - Hands.Back else nil
end

-- How far ahead of your eye a box reaches: `box` its middle from your eye (camera space, already
-- drawn small), `half` its half size.
function HandRoom.reach(box: CFrame, half: Vector3): number
	local far = 0
	for i = 0, 7 do
		local corner = box
			* Vector3.new(
				if i % 2 == 0 then -half.X else half.X,
				if i % 4 < 2 then -half.Y else half.Y,
				if i < 4 then -half.Z else half.Z
			)
		if -corner.Z > far then
			far = -corner.Z
		end
	end
	return far
end

--[[
	Where a light meant for `want` can sit, seen along the line from `from`: `want` itself, or just
	short of the first solid thing on the way. `params` skips whose body the line starts in (your
	own when nil).
]]
function HandRoom.clear(from: Vector3, want: Vector3, params: RaycastParams?): Vector3
	local line = want - from
	local far = line.Magnitude
	if far < 1e-4 then
		return want
	end
	local hit = Workspace:Raycast(from, line, params or own())
	if not hit then
		return want
	end
	return from + line * (Hands.lightAt(far, hit.Distance) / far)
end

return HandRoom
