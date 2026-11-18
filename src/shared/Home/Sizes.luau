--!strict
--[[
	Sizes, pure (S5-03h1, D-340): the four sizes your home comes in and the box each takes in its
	slot. The moment they serve: back from a good climb you pay to grow your home, the partitions
	grind back, and everything you'd set out stays where it was, with room for more (Animal
	Crossing's house upgrades, Bloxburg's bigger plot, Adopt Me's bigger homes; the home doc's
	ideas 30 and 31).

	Everyone starts Small; Medium is bought with cash, Large and XL with Robux (D-259). Every slot
	in the lobby is built at XL, and a smaller home stands inside it behind partitions: its box is
	the XL one cut down (`inside`), its front at the door and centred across, as real storage
	buildings make units of any size out of movable steel walls.

	No requires, so the save (`Save`) and the room (`Spots`) can both read it.
]]

export type Vec = { number }

-- A size: its name (what the save holds), its box inside across and deep (studs, wall to wall,
-- door to back wall), and how many finds it holds set out (idea 15, D-259's starting guesses).
export type Size = { name: string, across: number, deep: number, limit: number }

local Sizes = {}

-- Smallest first. Across by deep (the home doc: small "snug", medium the climb's own unit's size).
Sizes.List = table.freeze({
	table.freeze({ name = "Small", across = 8, deep = 8, limit = 25 }),
	table.freeze({ name = "Medium", across = 12, deep = 12, limit = 50 }),
	table.freeze({ name = "Large", across = 16, deep = 20, limit = 100 }),
	table.freeze({ name = "XL", across = 20, deep = 30, limit = 150 }),
} :: { Size })

-- Their names, smallest first (the save's choices).
Sizes.Names = table.freeze((function(): { string }
	local names: { string } = {}
	for _, s in Sizes.List do
		table.insert(names, s.name)
	end
	return names
end)())

-- Everyone's home starts here.
Sizes.Start = "Small"
-- Every slot is built at it: the lobby's `Slots[n].Inside` is its box.
Sizes.Biggest = "XL"

-- Size `name`, or the smallest for a name not known.
function Sizes.of(name: string): Size
	for _, s in Sizes.List do
		if s.name == name then
			return s
		end
	end
	return Sizes.List[1]
end

-- Where size `name` stands, smallest 1; a name not known ranks as the smallest.
function Sizes.rank(name: string): number
	for i, s in Sizes.List do
		if s.name == name then
			return i
		end
	end
	return 1
end

-- Size `name`'s box inside, in the unit's frame (X across, Y up, Z in from the door), from the
-- slot's XL box there (its middle `centre`, its size `size` across, tall, deep): as tall, its
-- front where the XL's is (the door's frame), centred across, and as much smaller each way as
-- the size is than XL. New tables.
function Sizes.inside(name: string, centre: Vec, size: Vec): (Vec, Vec)
	local s, xl = Sizes.of(name), Sizes.of(Sizes.Biggest)
	local across = size[1] - (xl.across - s.across)
	local deep = size[3] - (xl.deep - s.deep)
	local front = centre[3] - size[3] / 2
	return { centre[1], centre[2], front + deep / 2 }, { across, size[2], deep }
end

-- How far size `name`'s walls stand in from the slot's (S5-03h5, D-354): each partition
-- `side` studs in across, the back wall `back` studs toward the door. Nothing for XL.
function Sizes.inset(name: string): (number, number)
	local s, xl = Sizes.of(name), Sizes.of(Sizes.Biggest)
	return (xl.across - s.across) / 2, xl.deep - s.deep
end

-- The M door's opening every home's rig is (D-266), and Small's own doorway in its wall: the S
-- door's (S5-03h5b, D-355; `art/home/home_spec.py` SMALL_DOOR).
Sizes.Door = 8
Sizes.SmallDoor = 6

-- How far each side of size `name`'s doorway stands in from the M's: a stud each side at Small,
-- whose room (8 across) is narrower than the M's opening; nothing from Medium up.
function Sizes.doorIn(name: string): number
	return if Sizes.of(name).name == Sizes.Start then (Sizes.Door - Sizes.SmallDoor) / 2 else 0
end

-- Where something on wall `wall` stands at size `name`, from where it stands in the XL slot
-- (`at`, the unit's frame: X across, + on your left as you walk in; Z in from the door): "Left"
-- and "Right" ride their partitions in, "Back" rides the back wall toward the door, "Middle"
-- (the ceiling's lamp) stays halfway between the door and the back wall; anything else (the
-- floor, the front wall) stays put. A new table.
function Sizes.onWall(name: string, wall: string, at: Vec): Vec
	local side, back = Sizes.inset(name)
	return Sizes.onInset(side, back, wall, at)
end

-- `onWall` with the walls stood `side` studs in across and `back` toward the door (`inset`'s,
-- or a blend of two sizes' as the walls grind back, `between`). A new table.
function Sizes.onInset(side: number, back: number, wall: string, at: Vec): Vec
	local x, y, z = at[1], at[2], at[3]
	if wall == "Left" then
		x -= side
	elseif wall == "Right" then
		x += side
	elseif wall == "Back" then
		z -= back
	elseif wall == "Middle" then
		z -= back / 2
	end
	return { x, y, z }
end

-- The walls part way from size `from` to size `to` as a home grows (S5-03h6, D-356): with the
-- slide `k` along (0 at `from`, 1 at `to`, clamped), each partition's inset across, the back
-- wall's toward the door, and the doorway's sides' in from the M's.
function Sizes.between(from: string, to: string, k: number): (number, number, number)
	local t = math.clamp(k, 0, 1)
	local sa, ba = Sizes.inset(from)
	local sb, bb = Sizes.inset(to)
	local da, db = Sizes.doorIn(from), Sizes.doorIn(to)
	return sa + (sb - sa) * t, ba + (bb - ba) * t, da + (db - da) * t
end

-- How far along the slide is at `t` of its time (0 to 1): steel on rails, slow to get going,
-- slow to settle (an ease in and out), so the walls lurch free, run, and grind home.
function Sizes.slide(t: number): number
	local x = math.clamp(t, 0, 1)
	return if x < 0.5 then 4 * x * x * x else 1 - (2 - 2 * x) ^ 3 / 2
end

-- How fast the slide runs at `t`, 0 standing to 1 at its fastest (halfway): the grind's pitch
-- and loudness follow it.
function Sizes.slideSpeed(t: number): number
	local x = math.clamp(t, 0, 1)
	return (if x < 0.5 then 12 * x * x else 3 * (2 - 2 * x) ^ 2) / 3
end

return table.freeze(Sizes)
