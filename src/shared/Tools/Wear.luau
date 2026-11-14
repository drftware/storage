--!strict
--[[
	Tools wear out (S1-08, GDD "Tools wear out"), as Minecraft's tools do: each works a set number
	of times (its catalog row's `wear`), and the use that spends the last breaks it in your hand.
	A mark on its slot shows the uses left, as Minecraft's bar under a worn tool does: one notch a
	use, the last one red, so running out is never a surprise.

	Pure. The server keeps each tool's uses with the tool itself, so a dropped or handed-over tool
	keeps its wear (`Slots`); every screen reads them from the player's `ToolUses` attributes
	(`ToolView`), and the horn's view reads its model's `Uses` for the last blast (`HornView`).
]]
local Catalog = require("./Catalog")

local Wear = {}

-- On each Player: `ToolUses1` to `ToolUses3`, the uses left of the tool in that slot (0 for an
-- empty slot or a tool that never wears out).
Wear.SlotAttribute = "ToolUses"
-- On a carried tool's model: its uses left, once it has spent one.
Wear.ModelAttribute = "Uses"

function Wear.slotAttribute(i: number): string
	return Wear.SlotAttribute .. tostring(i)
end

-- The uses a new tool of catalog key `key` has, or nil if it never wears out.
function Wear.full(key: string): number?
	local row = Catalog[key]
	local w = row and row.wear
	return if w then w.uses else nil
end

-- One use spent from `left`: the uses left after it, and whether that use broke it. A tool that
-- never wears out (nil) stays nil and never breaks; one already spent stays at 0.
function Wear.spend(left: number?): (number?, boolean)
	if left == nil then
		return nil, false
	end
	if left <= 0 then
		return 0, false
	end
	local now = left - 1
	return now, now == 0
end

-- Whether a tool with `left` uses still works: one with none left is breaking in your hand.
function Wear.usable(left: number?): boolean
	return left == nil or left > 0
end

-- A slot's mark for a tool of catalog key `key` with `left` uses: how many notches, how many of
-- them still lit, and whether it's on its last (the one lit notch warns). No notches for a tool
-- that never wears out, nor for one that's used up whole on its one use.
function Wear.mark(key: string, left: number): (number, number, boolean)
	local full = Wear.full(key)
	if full == nil or full < 2 then
		return 0, 0, false
	end
	local lit = math.clamp(math.floor(left), 0, full)
	return full, lit, lit == 1
end

return Wear
