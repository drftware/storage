--!strict
--[[
	Kept: getting kept (L-07a, the GDD's "Getting kept"), as pure rules the server's KeptPlayers
	uses. Pure, so Lune tests it (tests/kept.spec.luau).

	The moment: the keeper's hands close, the screen goes dark through the 2-second wrap (`Caught`),
	and you wake wrapped in a unit somewhere on the floor, the door down in front of you, until a
	friend lets you out. Dead by Daylight's hook and Flee the Facility's freeze pods are the
	precedent: caught, stored, a teammate frees you. Stored in a random unit and never the nearest
	is the GDD's own twist on the hook, so friends have to look.

	Which unit: one whose door is all the way down (not padlocked, not open), with no keeper in it
	(nor the guard's place, D-072) and nobody kept in it already. Never the nearest of those to
	where you were caught while another will do. One nobody has seen into ahead of one that's been
	opened, so you're behind a door friends haven't tried yet, and it holds only you.
]]

local Kept = {}

-- The player attribute the server sets while they're kept (true) and clears when they're let
-- out: keepers leave them alone, and doors, tools, crawls and ladders refuse them. Only the
-- server sets it, so a screen can read it but never fake it.
Kept.Attribute = "Kept"

-- How far into the unit you wake, a share of its depth from the door: past the middle, so the
-- door fills your view and the dark sits between you and it, and off the back wall.
Kept.Back = 0.62

-- The line on a kept player's screen once they wake inside, until they're let out: what to do
-- now, in few words (L-07c makes it the Bang button's).
Kept.Hint = "Wait for a friend"
-- Seconds the line takes to come up once the screen has opened on the inside.
Kept.HintIn = 1

-- A unit as the choice sees it: where it stands on the floor (x, z: any one frame, the catch's
-- too), whether its door is all the way down and not padlocked (`shut`), whether anyone has seen
-- into it (`dealt`), whether a keeper is in it or the guard's place is kept there (`keeper`), and
-- whether someone is kept in it now (`holding`).
export type Unit = {
	x: number,
	z: number,
	shut: boolean,
	dealt: boolean,
	keeper: boolean,
	holding: boolean,
}

-- Brix's Random, as `Floor` takes it.
export type Random = {
	nextNumber: (self: any) -> number,
	nextInteger: (self: any, min: number, max: number) -> number,
}

--- Whether unit `u` can hold a kept player now.
function Kept.free(u: Unit): boolean
	return u.shut and not u.keeper and not u.holding
end

--- Which of `units` the building stores someone caught at (`x`, `z`) in: its index, or nil when
--- none is free. Never the nearest free one while another will do; an unopened one ahead of one
--- that's been seen into; at random among those.
function Kept.choose(units: { Unit }, x: number, z: number, random: Random): number?
	local free: { number } = {}
	local nearest, best = 0, math.huge
	for i, u in units do
		if Kept.free(u) then
			table.insert(free, i)
			local dx, dz = u.x - x, u.z - z
			local d = dx * dx + dz * dz
			if d < best then
				nearest, best = i, d
			end
		end
	end
	if #free == 0 then
		return nil
	elseif #free == 1 then
		return free[1]
	end
	local unopened: { number } = {}
	local opened: { number } = {}
	for _, i in free do
		if i ~= nearest then
			table.insert(if units[i].dealt then opened else unopened, i)
		end
	end
	local pool = if #unopened > 0 then unopened else opened
	return pool[random:nextInteger(1, #pool)]
end

return table.freeze(Kept)
