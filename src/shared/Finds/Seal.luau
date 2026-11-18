--!strict
--[[
	Sealed finds (S5-02b, D-424): now and then a find is still in its packaging, worth three times
	the loose one, the way Pet Simulator's shiny pets and Grow a Garden's gold crops are a small
	chance on any drop of a variant worth far more. The moment: a box's lid lifts on a find still
	in its blister, and you carry it home like it's glass.

	About one find in twenty is dealt sealed (`sealed`), read from the unit's own pick in
	`Deal.open`, so the same seed deals the same sealed finds and nothing else in the deal moves.
	Each find size has one shared pack (`Finds/PackFit`, built in art/finds/packs): a card-backed
	blister for a Small find, a window box for a Medium one, a taped carton for a Large one
	(`packOf`). The pack stretches round the find (`fit`, the same rule as art/finds/packs/spec.py),
	and a find much deeper than it is wide is turned a quarter round so its long side faces the
	window (`turned`). Sealed, it takes no press, and a hard drop (the crack's own measure,
	`Chip.hard`) tears the pack off, leaving a plain find (`tears`). Its worth: `worth`.

	Pure. Sizes are three numbers in Roblox's axes: across (X), up (Y), deep (Z).
]]
local Chip = require("./Chip")

local Seal = {}

-- The share of dealt finds still sealed: about one in twenty (ROADMAP S5-02). Higher and a sealed
-- one stops being a surprise; lower and a team climbs a dozen floors without seeing one.
Seal.Share = 0.05
-- What the unit's pick is multiplied by before its fraction is read, so whether a find is sealed
-- has nothing to do with its grade or which find of the grade (both read the pick as it is) or
-- with the unit's stuff (the pick times 89): a large prime spreads even a rare grade's narrow
-- band of picks across sealed and not.
Seal.Scramble = 7919
-- A sealed find's worth over the same find loose.
Seal.Times = 3
-- A find deeper than this many times its width is turned a quarter round in its pack, so its
-- long side faces the window (the kazoo, the die-cast car), the way a shop hangs them.
Seal.TurnRatio = 1.5
-- The model attribute every screen reads: true while the find is still in its packaging.
Seal.Attribute = "Sealed"

-- Whether a find dealt from pick `pick` (the unit's roll, 0 to 1) is still sealed.
function Seal.sealed(pick: number): boolean
	if pick ~= pick then
		return false
	end
	return (math.clamp(pick, 0, 1) * Seal.Scramble) % 1 < Seal.Share
end

-- The pack a find of catalog size `size` is sealed in (its key in `Finds/PackFit`), or nil when
-- it never is: a floor's big find (it stands alone, taller than you) or a tool.
function Seal.packOf(size: string?): string?
	if size == "Small" or size == "Medium" or size == "Large" then
		return size
	end
	return nil
end

-- Whether a find of size `find` sits turned a quarter round in its pack (`TurnRatio`).
function Seal.turned(find: { number }): boolean
	return find[3] > Seal.TurnRatio * find[1]
end

-- The find's size as its pack holds it: turned, its width and depth swap.
function Seal.held(find: { number }): { number }
	if Seal.turned(find) then
		return { find[3], find[2], find[1] }
	end
	return { find[1], find[2], find[3] }
end

-- How much a pack scales on each axis to hold a find of size `find` (as `held` gives it) in its
-- `room`: each axis at least what the find needs with `pad` round it, and none less than the
-- largest over `stretch`, so the pack's print never squashes past that (spec.py's `fit`).
function Seal.fit(find: { number }, room: { number }, pad: number, stretch: number): { number }
	local need = table.create(3, 0) :: { number }
	local top = 0
	for i = 1, 3 do
		need[i] = (find[i] + 2 * pad) / room[i]
		top = math.max(top, need[i])
	end
	for i = 1, 3 do
		need[i] = math.max(need[i], top / stretch)
	end
	return need
end

-- The packed find's outside size: the pack's own size `pack` scaled by `scale` (`fit`). The deal
-- boxes a sealed find by this, not the find's own (`Deal.packs`): a carton too big for the marked
-- box stands loose on the unit's floor.
function Seal.outer(pack: { number }, scale: { number }): { number }
	return { pack[1] * scale[1], pack[2] * scale[2], pack[3] * scale[3] }
end

-- What a find worth `worth` in cash is worth still sealed: three times. Unsealed, its worth. A
-- sealed find is never cracked: a hard drop tears its pack instead (`tears`).
function Seal.worth(worth: number, sealed: boolean): number
	if not sealed or worth ~= worth or worth <= 0 then
		return worth
	end
	return worth * Seal.Times
end

-- Whether a sealed find's pack tears as it lands: you let it go hard (`Chip.hard`: running,
-- falling, or from high up). Set down standing, it never does; unsealed, there's nothing to tear.
function Seal.tears(sealed: boolean, speed: number, fall: number): boolean
	return sealed and Chip.hard(speed, fall)
end

return table.freeze(Seal)
