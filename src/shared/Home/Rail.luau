--!strict
--[[
	Rail: the rules for what you wear standing on your home's clothes rail (S5-03f2b, D-316), pure
	so Lune tests them. The moment: everything you own that you can wear stands on your rail; you
	press the hard hat and you're wearing it, its knock and its lamp's click, and you turn to the
	mirror and see it on you. Press again and it hangs back up. Lethal Company's suit rack.

	A find you wear has a row on the rail (`row`): on your head, the hat shelf on top; clothes on
	the hangers and shoes on the rack once there are some. Each kind you own that you can wear
	gets a place along its row (`places`), and stands there while one of it is in your job box
	(Save.boxed). The server (Rails) stands it and puts one press on each place, shown only to
	you: Wear while it stands there, Hang up while you wear that kind out of your own box.
]]
local Gold = require("./Gold")
local Head = require("../Finds/Head")

local Rail = {}

Rail.Tag = "RailFind" -- on each find standing on a rail, for every screen
Rail.OwnerAttribute = "Owner" -- the UserId whose rail it stands on
Rail.Wear = Head.Verb -- the press on a find standing there
Rail.HangUp = "Hang up" -- the press while you wear that kind out of your own box
-- Studs from the place a press counts from: the prompt's reach, and the server's slack on it.
Rail.Reach = 7
Rail.Slack = 4
-- Presses a player may make: a quick wear and hang up, never a flood.
Rail.Limit = { perSecond = 3, burst = 4 }
-- Degrees a find stands turned about its up from the rail's front, so the hat's lamp looks
-- into the room (seen in Studio).
Rail.Turn = 0
Rail.Lift = 0.02 -- studs a find stands above its row, so its bottom never flickers into it

-- Each row's places along it, in the Rail piece's frame (studs across from its middle): the
-- first kind in the middle, the next either side. More kinds than places are left off.
Rail.Places = {
	Shelf = { 0, -1.35, 1.35 },
} :: { [string]: { number } }

-- The row find `name` (a save's name: "HardHat", a Gold's "HardHat:Gold") stands on, or nil
-- when it isn't worn. Anything worn on the head goes on the hat shelf.
function Rail.row(name: string): string?
	local key = Gold.base(name) or name
	return if Head.fit(key) then "Shelf" else nil
end

export type Place = { name: string, row: string, i: number, x: number }

-- The places on a rail for `owned` (finds by name, as a save counts them): each kind worn
-- somewhere that you own one or more of, a place on its row in name order. Allocates a list.
function Rail.places(owned: { [string]: number }): { Place }
	local names: { string } = {}
	for name, count in owned do
		if count >= 1 and Rail.row(name) then
			table.insert(names, name)
		end
	end
	table.sort(names)
	local used: { [string]: number } = {}
	local places: { Place } = {}
	for _, name in names do
		local row = Rail.row(name) :: string
		local i = (used[row] or 0) + 1
		local xs = Rail.Places[row]
		if xs and xs[i] then
			used[row] = i
			table.insert(places, { name = name, row = row, i = i, x = xs[i] })
		end
	end
	return places
end

-- How high a row's top stands in the Rail piece's frame, from the art's `specs` (Specs.Rail).
function Rail.height(row: string, specs: { Shelf: number, Bar: number, Rack: number }): number
	if row == "Shelf" then
		return specs.Shelf
	elseif row == "Bar" then
		return specs.Bar
	end
	return specs.Rack
end

return table.freeze(Rail)
