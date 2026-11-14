--!strict
--[[
	InFlight: what's still flying to a player's hands on this screen (S1-10c2b). The server hands
	a bought thing over the moment it's paid for, but on every screen it first drops behind the
	machine's flap and flies to the buyer; until it lands, the screens that show the change hold
	it back: ToolView keeps the new tool out of your view, FlashlightView keeps your torch (or a
	friend's) as dim as it was, and MachineVend keeps a friend's new tool out of their hand.

	A hold is counted per player and per hand (`"tool"` the left, `"torch"` the right), so two
	quick buys each land on their own. Whoever holds lands it, always: when the thing reaches the
	hand, or when its vend is cut short.
]]

export type Hand = "tool" | "torch"

local InFlight = {}

local holds: { [Player]: { tool: number, torch: number } } = {}

-- Something is now flying to `player`'s `hand`.
function InFlight.hold(player: Player, hand: Hand)
	local h = holds[player]
	if not h then
		h = { tool = 0, torch = 0 }
		holds[player] = h
	end
	h[hand] += 1
end

-- It reached `player`'s `hand` (or never will).
function InFlight.land(player: Player, hand: Hand)
	local h = holds[player]
	if not h then
		return
	end
	h[hand] = math.max(0, h[hand] - 1)
	if h.tool == 0 and h.torch == 0 then
		holds[player] = nil
	end
end

-- Whether something is still flying to `player`'s `hand`.
function InFlight.held(player: Player, hand: Hand): boolean
	local h = holds[player]
	return h ~= nil and h[hand] > 0
end

return InFlight
