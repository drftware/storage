--!strict
--[[
	BigFind (S4-05b1, D-415): the floor's big find, the rules alone. From floor 2, one a floor: the
	moment the right code goes into the keypad, a unit down the hall rolls up by itself and there
	it stands, too big for any box, carried in both hands, as Lethal Company's apparatus waits in
	its socket for whoever is brave enough to haul it to the ship.

	Which unit is chosen as the code goes in, from the units nobody has opened yet (`fits`), so
	what a team has already searched is never undone, and it's one down the halls rather than in
	the lobby's own when one is left there (`unitFrom`). What it is comes from two rolls drawn
	when the floor is laid: a grade, as the item catalog rolls a big find (Epic 75, Legendary 22,
	Secret 3 in 100: `gradeFrom`), then a find of that grade among the big finds built
	(`findFrom`), the first one built standing in for a grade none has yet. Nothing here touches
	an Instance, so Lune tests it (tests/bigfind.spec.luau).
]]
local Deal = require("./Deal")
local Grades = require("./Grades")
local Rows = require("./Finds/Rows")

local BigFind = {}

BigFind.From = 2 -- the first floor with one (the design doc): floor 1 teaches the code alone
BigFind.Set = "Big" -- the finds set the big finds are built in (art/finds/big/)
-- Where the corner map marks the big find (S4-05b2b), on the floor's model, the server's:
-- once its unit has rolled up, that unit's slot index (cleared as it's gone: kept, lost, or in a
-- monster's arms); while it lies loose, the floor point under it (a world Vector3); while someone
-- hauls it, their UserId. The map shows the first of hauled, lying, in its unit (`mark`).
BigFind.SlotAttribute = "BigFindSlot"
BigFind.AtAttribute = "BigFindAt"
BigFind.HolderAttribute = "BigFindHolder"
BigFind.Rings = 3 -- rings its mark sends out as it shows: the door just rolled up, look here

-- "Held", "Lying" or "Unit": a plain string, as singleton words come out of the frozen table
-- widened on the client
export type Mark = string

-- What the map marks from the floor's three attributes: hauled by `holder`, lying loose, or
-- still in unit `slot` (nil: no mark).
function BigFind.mark(slot: number?, holder: number?, lying: boolean): Mark?
	if holder then
		return "Held"
	elseif lying then
		return "Lying"
	elseif slot then
		return "Unit"
	end
	return nil
end

-- The rings its mark sends out going from `was` to `now`: `Rings` as it shows (the door rolled
-- up, or it's back off a monster's pile), one as it's picked up, dropped or handed on, none as
-- it's dealt where it already stood or goes.
function BigFind.rings(was: Mark?, now: Mark?): number
	if now == nil or (was == "Unit" and now == "Lying") then
		return 0
	elseif was == nil then
		return BigFind.Rings
	end
	return 1
end

-- The grade roll, out of 100 (the item catalog's big finds: an Epic most floors, now and then a
-- Legendary, a Secret a rare story to tell).
BigFind.Odds = {
	{ grade = "Epic" :: Grades.Grade, share = 75 },
	{ grade = "Legendary" :: Grades.Grade, share = 22 },
	{ grade = "Secret" :: Grades.Grade, share = 3 },
}

export type Find = { key: string, grade: Grades.Grade }

-- The big finds built (ticked in WAVES.md), in the rows' order: the first is the stand-in.
BigFind.Finds = {} :: { Find }
for _, row in Rows do
	if row.set == BigFind.Set and row.judged then
		table.insert(BigFind.Finds, { key = row.key, grade = row.grade :: Grades.Grade })
	end
end

-- Whether floor `number` has a big find.
function BigFind.on(number: number): boolean
	return number >= BigFind.From
end

-- The grade a roll of 0 to 1 lands on.
function BigFind.gradeFrom(roll: number): Grades.Grade
	local at = math.clamp(roll, 0, 1) * 100
	for _, o in BigFind.Odds do
		if at < o.share then
			return o.grade
		end
		at -= o.share
	end
	return BigFind.Odds[#BigFind.Odds].grade
end

-- The find two rolls of 0 to 1 deal: a grade by `roll`, then one of that grade by `pick`, or the
-- first of `finds` when none is of that grade. Nil with no big find built. `finds` defaults to
-- every one built.
function BigFind.findFrom(roll: number, pick: number, finds: { Find }?): string?
	local list = finds or BigFind.Finds
	if #list == 0 then
		return nil
	end
	local grade = BigFind.gradeFrom(roll)
	local of: { string } = {}
	for _, f in list do
		if f.grade == grade then
			table.insert(of, f.key)
		end
	end
	if #of == 0 then
		return list[1].key
	end
	return of[math.clamp(math.floor(pick * #of) + 1, 1, #of)]
end

-- Whether unit `index` of `deck` may be the big find's: nobody has opened it, and nothing else is
-- dealt there (no padlock, no note, no monster asleep or guarding, no Packrat's pile, not packed
-- to the ceiling), so the door that rolls up shows the big find alone.
function BigFind.fits(deck: Deal.Deck, index: number): boolean
	return deck.rolls[index] ~= nil
		and deck.dealt[index] == nil
		and deck.big[index] == nil
		and not deck.padlocked[index]
		and deck.guarded ~= index
		and deck.sleepers[index] == nil
		and deck.piles[index] == nil
		and not deck.packed[index]
		and Deal.noteIn(deck, index) == nil
end

-- The unit a `pick` of 0 to 1 chooses among `open`, the units still shut and to be dealt (slot
-- indices, in `Deal.units` order), keeping those that fit: one outside the lobby's hall if any is
-- left, else any. Nil when none fits (every unit searched).
function BigFind.unitFrom(deck: Deal.Deck, open: { number }, pick: number): number?
	local far: { number } = {}
	local near: { number } = {}
	for _, index in open do
		if BigFind.fits(deck, index) then
			table.insert(if deck.firstHall[index] then near else far, index)
		end
	end
	local list = if #far > 0 then far else near
	if #list == 0 then
		return nil
	end
	return list[math.clamp(math.floor(pick * #list) + 1, 1, #list)]
end

return table.freeze(BigFind)
