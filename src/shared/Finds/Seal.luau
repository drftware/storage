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
-- A find lower than this share of both its width and its depth is flat (the fairy lights' coil):
-- it lies on its back in its blister (`tipped`), so the window shows its face, not its edge.
Seal.FlatRatio = 2.5
-- The model attribute every screen reads: true while the find is still in its packaging.
Seal.Attribute = "Sealed"

-- The Player attribute that says slot `i` holds a find still sealed, set before its key and
-- cleared after it, so no screen draws it unwrapped for a moment (as a Gold's mark is).
function Seal.slotAttribute(i: number): string
	return `Slot{i}Sealed`
end

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

-- Whether a find of size `find` is flat (the fairy lights' coil): its height under its width and
-- its depth over `FlatRatio`. It lies on its back in its pack, its top to the window, the way a
-- blister card lies on a shop's counter: the pack's back faces down wherever the find lies flat.
function Seal.tipped(find: { number }): boolean
	return find[2] * Seal.FlatRatio < math.min(find[1], find[3])
end

-- Whether a find of size `find` sits turned a quarter round in its pack (`TurnRatio`). A flat one
-- is tipped instead, never both.
function Seal.turned(find: { number }): boolean
	return not Seal.tipped(find) and find[3] > Seal.TurnRatio * find[1]
end

export type Way = "Upright" | "Turned" | "Tipped"

-- How a find of size `find` sits in its pack: "Tipped" (`tipped`), "Turned" (`turned`) or
-- "Upright". Packs face the way finds do (Roblox's -Z), so upright its front shows.
function Seal.way(find: { number }): Way
	if Seal.tipped(find) then
		return "Tipped"
	end
	return if Seal.turned(find) then "Turned" else "Upright"
end

-- The find's size as its pack holds it: turned, its width and depth swap; tipped, its height and
-- depth.
function Seal.held(find: { number }): { number }
	local way = Seal.way(find)
	if way == "Tipped" then
		return { find[1], find[3], find[2] }
	elseif way == "Turned" then
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

-- How far a sealed find's lowest point sits above its pack's lowest point, with the find lying as
-- a loose one lies (its own up, up): the pack under it holds it that high off the floor. Packed
-- upright or turned, the pack stands on its bottom (its pivot) under the room; tipped, it lies on
-- its back, `back` studs behind its pivot (the pack's own depth, halved). `find` is the find's own
-- size; the pack's `room`, `centre` (the room's middle from its pivot), `pad` and `stretch` are
-- `Finds/PackFit`'s.
function Seal.lift(
	find: { number },
	room: { number },
	centre: { number },
	pad: number,
	stretch: number,
	back: number
): number
	local held = Seal.held(find)
	local s = Seal.fit(held, room, pad, stretch)
	if Seal.tipped(find) then
		return s[3] * (back - centre[3]) - held[3] / 2
	end
	return s[2] * centre[2] - held[2] / 2
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

--[[
	Kept sealed (S5-02b2c, D-427). A sealed find is kept in the save's `finds` as a name of its
	own, the find's name with `Mark` after it ("Teddy:Sealed"), the way a Gold is ("Teddy:Gold",
	Home/Gold): the shelf, the job box, what's set out and a trip each hold one particular find, so
	each knows which of your teddies is the sealed one, and the save's shape is unchanged. Its
	catalog row is its find's (`base`); what's sealed about it is drawn (`Finds/Pack`) and priced
	(`worth`, `BoxPanel.price`). The book's sealed page (`Save.keep`) is stamped by the find's name.
]]
-- After a find's name, its sealed one's: never in a find's own name (letters only), never a
-- Gold's (a Gold is never sealed).
Seal.Mark = ":Sealed"

-- The sealed one of find `name`: its name in the save.
function Seal.key(name: string): string
	return name .. Seal.Mark
end

-- The find a sealed one's `key` is of, or nil when `key` isn't a sealed one's.
function Seal.base(key: string): string?
	local n = #Seal.Mark
	if #key > n and string.sub(key, -n) == Seal.Mark then
		return string.sub(key, 1, -n - 1)
	end
	return nil
end

return table.freeze(Seal)
