--!strict
--[[
	Joints: a player's body turned past its animation, on this screen. Every view that poses a
	body (a friend's torch arm raised, a horn blown, a crawl's reaching arms, a peek's kneel) finds
	the joints here and turns them here, so none of them can miss a kind of joint again.

	An avatar's joint is a Motor6D on older bodies and an AnimationConstraint on Roblox's newer
	avatar joints (the shoulders on the players here: docs/STUDIO.md, "Avatar joints are
	AnimationConstraints"). Both turn by `Transform`, and a write before physics (PreSimulation)
	holds through the frame.
]]

export type Joint = Motor6D | AnimationConstraint

local Joints = {}

-- The joint `name` in `character`'s part `part`, whichever kind it is; nil if it has none.
function Joints.find(character: Model, part: string, name: string): Joint?
	local p = character:FindFirstChild(part)
	local j = p and p:FindFirstChild(name)
	if j and j:IsA("Motor6D") then
		return j
	elseif j and j:IsA("AnimationConstraint") then
		return j
	end
	return nil
end

-- The joint's turn now (its animation's, or what a view set this frame).
function Joints.get(j: Joint): CFrame
	-- any: both classes have Transform, but Luau can't index a property through their union
	return (j :: any).Transform
end

-- Sets the joint's turn.
function Joints.set(j: Joint, to: CFrame)
	-- any: as in `get`
	(j :: any).Transform = to
end

-- Turns the joint `w` of the way (0 to 1) from its animation to `to`.
function Joints.bend(j: Joint, to: CFrame, w: number)
	Joints.set(j, Joints.get(j):Lerp(to, w))
end

return Joints
