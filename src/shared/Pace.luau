--!strict
--[[
	Pace: something that happens at a steady rate, stepped by frame time (the hall's dust puffs,
	HallHaze). It carries the fraction of the next event from frame to frame. A long frame (a
	hitch, a phone pausing the game) fires it once and drops the backlog, keeping its rhythm, so
	nothing piles up and lands at once.
]]
local Pace = {}

-- Adds `dt` seconds at `perSecond` events a second to `carry` (the fraction carried so far, 0 to
-- under 1). Returns whether the event happens this frame and the fraction carried on.
function Pace.step(carry: number, dt: number, perSecond: number): (boolean, number)
	local total = carry + dt * perSecond
	if total < 1 then
		return false, total
	end
	return true, (total - 1) % 1
end

return Pace
