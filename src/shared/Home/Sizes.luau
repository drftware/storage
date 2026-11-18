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

return table.freeze(Sizes)
