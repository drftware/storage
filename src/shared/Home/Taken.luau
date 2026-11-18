--!strict
--[[
	Taken: what becomes of a find you take up from your job box (S5-03d, D-251, D-302), pure so
	Lune tests it. The moment: you bring your lamp up for the dark floors, get caught on floor 3,
	and your friend grabs it off the floor and sprints for the gate. It's theirs now. Or nobody
	does, the gate shuts, and it's gone for good. Precedents: Minecraft (what you carry drops where
	you die, and you go back for it before something takes it) and Lethal Company (gear left where
	a crewmate died stays on the moon unless someone carries it back).

	A find out of your box stays in your save the whole time it's out (D-293: what's out is
	counted live from the finds themselves, never stored), so a server that crashes or shuts down
	mid-climb never costs you one: you come back and it's in your box. The save changes only when
	the server sees how it ended (`settle`), and writes it at once:
	- **Aboard**, as a gate shuts with it in someone's hands. Yours: it stays out, in your hands,
	  at risk on the next floor too, and your save is unchanged ("Out"). A friend's: it's theirs
	  now, kept into their save as any find they carry aboard, and struck off yours ("Moved"), so
	  between the two saves it's one, never two.
	- **Lost**: it was never carried aboard and the server ended its part of the climb (its floor
	  left behind, the climb over), or you left mid-climb with it out: struck off yours (`Save.lose`).
	- **Back** in your box with the server up (you left at home, or put it back): nothing struck.
	A crack it took on the climb (D-296) comes home with it: into the save of whoever has it.

	Across the trip (S5-03d4, D-358): a live climb runs on a server of its own, so each rider's
	taken-up finds go in the trip's data (`Up`) and the climb's server deals them into their slots,
	already up. That data passed through each rider's device, so the server takes only an owner's
	own word about their own finds, and only what their save still has in the box (`backed`); the
	rest stays in the box. Nothing is written on the way: the save still holds every one of them.
]]
local Save = require("../Save")

local Taken = {}

-- How a find taken up ended, as the server saw it. A crash or a shutdown is no end: nothing is
-- settled and the save keeps what it last held.
export type How = "Aboard" | "Lost" | "Back"
Taken.Hows = table.freeze({
	Aboard = "Aboard" :: How,
	Lost = "Lost" :: How,
	Back = "Back" :: How,
})

-- What it came to: still out in its owner's hands; moved to whoever carried it aboard; struck
-- off its owner's save; back in its owner's box; or nothing to change ("Gone": no owner's save
-- to strike from, none left in it, or nothing that makes sense).
export type Fate = "Out" | "Moved" | "Lost" | "Back" | "Gone"

export type Ending = {
	name: string, -- its key in the save ("Teddy", a Gold's "Teddy:Gold")
	how: How,
	cracked: boolean?, -- its glass cracked on the climb (D-296)
	now: number, -- os.time: a new kind's page in the carrier's book
	spots: number, -- the carrier's shelf spots: a find they keep walks onto their shelf
}

-- A find taken up out of a job box, going with the trip (S5-03d4): whose box it's from (a UserId),
-- its key in the save (a Gold's "Teddy:Gold"), who holds it (a UserId), whether its glass cracked
-- while it was out (D-296), and whether it rides on its holder's head (D-277).
export type Up = { owner: number, name: string, holder: number, cracked: boolean, worn: boolean }

-- Of the finds `ups` carried across the trip, those of `owner`'s that their save backs, in the
-- order given: each takes one of its name from what's in their box (Save.boxed, less `out`, theirs
-- already in the world here). Another rider's word, a name the save hasn't got, or more of one
-- than the box holds is dropped: it stays in the box. Writes nothing.
function Taken.backed(ups: { Up }, owner: number, data: Save.Data, out: Save.Counts): { Up }
	local left = Save.boxed(data, out)
	local dealt: { Up } = {}
	for _, u in ups do
		local n = if u.owner == owner then left[u.name] or 0 else 0
		if n >= 1 then
			left[u.name] = n - 1
			table.insert(dealt, table.clone(u))
		end
	end
	return dealt
end

-- Settles one find taken up from `owner`'s box (their save; nil once they've left, struck as they
-- went), `carrier` the save of someone else who carried it aboard (nil when it's its owner, or
-- when it wasn't carried). Changes only those saves, and only as `how` says.
function Taken.settle(e: Ending, owner: Save.Data?, carrier: Save.Data?): Fate
	local name = e.name
	if type(name) ~= "string" or name == "" then
		return "Gone"
	end
	if e.how == Taken.Hows.Aboard then
		if not carrier then
			return if owner then "Out" else "Gone" -- yours: still out, nothing written
		end
		Save.keep(carrier, { name }, e.now, e.spots)
		if e.cracked then
			Save.chip(carrier, { name })
		end
		if owner then
			Save.lose(owner, name)
		end
		return "Moved"
	elseif e.how == Taken.Hows.Lost then
		return if owner and Save.lose(owner, name) then "Lost" else "Gone"
	elseif e.how == Taken.Hows.Back then
		if not owner then
			return "Gone"
		end
		if e.cracked then
			Save.chip(owner, { name })
		end
		return "Back"
	end
	return "Gone"
end

return Taken
