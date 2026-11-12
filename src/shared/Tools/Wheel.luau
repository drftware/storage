--!strict
--[[
	The inventory wheel's shape and rules (L-20a), as GTA V's and Red Dead Redemption 2's weapon
	wheels. One round button sits at the bottom middle of the screen; a tap fans your slots out over
	it on an arc (slot 1 on the left, rising over the top and down the right) and a tap on one puts
	it in your hand and folds the wheel away. A small box beside the button shows the slot your hand
	is on; a tap on the box pockets its tool or brings it back up (as Rust's hotbar holsters on a
	second press of a slot's key). A pad's d-pad steps round the slots.

	Pure (tests/wheel.spec.luau): where each slot sits, how a press reads, the motion's timings.
	`ToolView` draws it and sends the server the result.
]]
local Wheel = {}

-- Sizes, as fractions of the round button's size (ToolView sizes the button from the screen).
Wheel.SlotOfButton = 0.86 -- a slot on the wheel: still a full thumb's target on a phone
Wheel.BoxOfButton = 0.8 -- the box beside the button
Wheel.Gap = 0.14 -- between the button, the box and the Drop button
Wheel.Radius = 1.5 -- from the button's middle to each slot's: the arc clears the button and box
-- The angle between two slots' middles on the arc, and the most the arc may spread in all (six
-- slots, L-20b, close up to fit).
Wheel.Step = math.rad(45)
Wheel.Spread = math.rad(150)
-- The least distance between two slots' middles, of a slot's size: a thumb never hits two.
Wheel.Room = 1.3

-- The motion: open in a beat, never slow (the owner's "never slow").
Wheel.Open = 0.12 -- seconds a slot takes to fan out from the button to its place
Wheel.Stagger = 0.02 -- seconds between slots fanning out, each with its own tick
Wheel.Close = 0.08 -- seconds the slots take to fold back into the button
Wheel.Fly = 0.1 -- seconds the slot you picked takes to fly into the box
Wheel.Folded = 0.25 -- a slot's size, of its own, folded into the button
-- Seconds a wheel nobody touches stays open before it folds itself away.
Wheel.Linger = 4

-- The angle of slot `i` of `n` on the arc, from straight up (positive to the right).
function Wheel.angle(i: number, n: number): number
	if n <= 1 then
		return 0
	end
	local step = math.min(Wheel.Step, Wheel.Spread / (n - 1))
	return (i - (n + 1) / 2) * step
end

-- The arc's radius in pixels for a button `size` across: `Radius`, or wider when many slots
-- would crowd each other.
function Wheel.radius(n: number, size: number): number
	local r = size * Wheel.Radius
	if n <= 1 then
		return r
	end
	local step = math.min(Wheel.Step, Wheel.Spread / (n - 1))
	local slot = size * Wheel.SlotOfButton
	return math.max(r, slot * Wheel.Room / (2 * math.sin(step / 2)))
end

-- Where slot `i` of `n` sits from the button's middle, in pixels (y down, as the screen's).
function Wheel.place(i: number, n: number, size: number): (number, number)
	local a = Wheel.angle(i, n)
	local r = Wheel.radius(n, size)
	return r * math.sin(a), -r * math.cos(a)
end

-- The box's middle from the button's middle, in pixels: to its right, a gap between them.
function Wheel.boxAt(size: number): number
	return size / 2 + math.floor(size * Wheel.Gap) + math.floor(size * Wheel.BoxOfButton) / 2
end

-- The slot `dir` (1 or -1) round from `slot` of `n`, wrapping: a pad's d-pad steps through them.
function Wheel.step(slot: number, dir: number, n: number): number
	return (slot - 1 + dir) % n + 1
end

-- What a press on slot `slot` does, with your hand on `active` (its tool `pocketed` or not) and
-- `filled` saying whether `slot` holds a tool. `again` is true for a press that toggles on your
-- own slot (its number key, the box): a lifted tool goes in your pocket. A pick on the wheel
-- doesn't: picking the slot you hold just folds the wheel away.
export type Press = "Switch" | "Lift" | "Pocket" | "None"

function Wheel.press(
	slot: number,
	active: number,
	pocketed: boolean,
	filled: boolean,
	again: boolean
): Press
	if slot ~= active then
		return "Switch"
	elseif pocketed then
		return "Lift"
	elseif again and filled then
		return "Pocket"
	end
	return "None"
end

return Wheel
