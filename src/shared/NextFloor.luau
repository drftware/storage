--!strict
--[[
	NextFloor: the team picks the next floor on the elevator's own buttons (S4-03, the GDD's "The
	team's choice, on the elevator's own buttons", the owner's answer of Nov 13), the rules alone,
	so Lune tests them (tests/nextfloor.spec.luau). The owner calls them the next-floor cards.

	The moment: the car lurches off and three buttons light up on its panel, each a version of the
	floor you're riding to and what it pays: the power's out, twice the monsters, anyone caught
	there goes back to the lobby, twice the padlocks. Friends jab at them and change their minds;
	on the cable's second knock the losers go dark and the winner flares, and that's the floor the
	car stops at. It lasts that one floor: a bad pick is over when its gate shuts. Some rides all
	three are bad and the team takes the one it can live with.

	Proven: Hades shows each door's reward before you pick it; Deep Rock Galactic's mission
	warnings make a mission harder and pay more for it; most presses wins, as a lobby's map vote
	does, and a tie goes at random.

	- `Versions` are data rows, so the list grows (GDD). Each has the lowest floor it's dealt for,
	  how it bends the floor (the deal, the lights and the catch read these: S4-03c) and its pay,
	  a share of the floor's own gate pay more (`payOf`).
	- `deal` is pure: three versions for floor `number`, from a Random off the climb's seed and
	  that floor (`seedOf`), so one seed always offers the same three. None for floor 1 (its ride
	  comes up from the lobby, with no choice), and only versions whose lowest floor it has reached.
	- `winner` counts the presses: most wins; a tie, and a ride nobody pressed on (every version
	  tied at none), at random among the tied.
	The server's NextFloors runs the vote on the riding car; Climbs deals the floor the winner
	names. Each press is a version's name over `Remote`; what screens draw comes from the car's
	attributes (`OfferAttribute`, `PressesAttribute`, `PickedAttribute`).
]]
local Climb = require("./Climb")
local Floor = require("./Floor")
local KeeperMix = require("./KeeperMix")
local Pay = require("./Pay")
local Ride = require("./Elevator/Ride")

type Random = Floor.Random

--- A version of a floor the team can pick on the ride up to it. A bend left out leaves that
--- part of the floor as the floor rules lay it.
export type Version = {
	name: string,
	-- The lowest floor it's dealt for: never floor 1, whose ride comes from the lobby.
	lowest: number,
	-- The coins it pays each rider at its gate, on top of the floor's own, as a share of them:
	-- 0.5 pays half again. A harder floor pays more (GDD).
	pay: number,
	-- The power's out: the floor's lights stay off.
	dark: boolean?,
	-- Times the monsters the floor rules wake on it: 2 is twice the monsters.
	monsters: number?,
	-- Times the doors the floor rules padlock on it: 2 is twice the padlocks.
	padlocks: number?,
	-- Anyone caught on it goes back to the lobby, out of the climb, not wrapped for friends to free.
	caughtToLobby: boolean?,
	-- Brings a monster or keeps one away (`KeeperMix.on`'s lean): its chance on this floor, 0 to 1.
	lean: KeeperMix.Lean?,
	-- Its card's face: a picture of the floor, rendered from the game's own models by
	-- art/cards/build.py. No words on it. The image inside the Decal art/cards/assets.json names
	-- (`InsertService:LoadAsset`, art/cards/README.md).
	face: string,
	-- Its face's own colour of light, red, green and blue from 0 to 1, as art/cards/spec.py lights
	-- it: the card glows in it when pressed and as it wins, so the three tell apart at a glance.
	light: { number },
}

local NextFloor = {}

-- How many versions light up on a ride: the GDD's three buttons.
NextFloor.Offered = 3

-- Seconds into the ride the vote ends: on the cable's second knock, the losers go dark and the
-- winner flares. About nine seconds to pick, and room left before the riders are handed to the
-- next floor's car (`Climb.HandOff`) for that floor to be dealt as picked and streamed to them.
NextFloor.Closes = Ride.Clanks[2]

-- How fast one rider may press: a thumb changing its mind, never a flood (the server drops the
-- rest).
NextFloor.Limit = { perSecond = 3, burst = 5 }

-- The remote a rider's press comes over, in ReplicatedStorage.Remotes: a version's name.
NextFloor.RemoteFolder = "Remotes"
NextFloor.Remote = "NextFloorPress"

-- On the riding car: the versions lit on its panel, in order (`encodeOffer`; "" with no vote).
NextFloor.OfferAttribute = "NextFloorOffer"
-- On the riding car: who's pressed which (`encodePresses`).
NextFloor.PressesAttribute = "NextFloorPresses"
-- On the riding car: the version that won, once the vote has ended ("" before).
NextFloor.PickedAttribute = "NextFloorPicked"
-- On a laid floor's model: the version it was dealt as, if the team picked one.
NextFloor.Attribute = "FloorVersion"

-- Every version, in the order a floor's deal draws from them. Defaults the owner checks
-- (OWNER.md): the GDD's four, their lowest floors and their pay.
NextFloor.Versions = table.freeze({
	-- a dead caged bulb hanging in the dark
	table.freeze({
		name = "PowerOut",
		lowest = 2,
		pay = 0.5,
		dark = true,
		face = "rbxassetid://91517401639848",
		light = { 0.42, 0.58, 1.0 }, -- cold moonlight
	}) :: Version,
	-- two padlocks hanging on a steel door
	table.freeze({
		name = "TwicePadlocks",
		lowest = 2,
		pay = 0.5,
		padlocks = 2,
		face = "rbxassetid://131197171716537",
		light = { 1.0, 0.62, 0.32 }, -- the warm bulb
	}) :: Version,
	-- the Packrat comes too, from its own lowest floor on (KeeperMix never brings one below it);
	-- two Mannequins standing at the end of a dark hall
	table.freeze({
		name = "TwiceMonsters",
		lowest = 2,
		pay = 1,
		monsters = 2,
		lean = table.freeze({ Packrat = 1 }),
		face = "rbxassetid://94818091969519",
		light = { 0.70, 1.0, 0.78 }, -- a sick fluorescent
	}) :: Version,
	-- the harshest: a team meets being caught and freed on floors 1 and 2 first; looking down the
	-- shaft at the car far below, lit red
	table.freeze({
		name = "CaughtToLobby",
		lowest = 3,
		pay = 1,
		caughtToLobby = true,
		face = "rbxassetid://72304998325928",
		light = { 1.0, 0.16, 0.10 }, -- the emergency red
	}) :: Version,
})

local byName: { [string]: Version } = {}
for _, version in NextFloor.Versions do
	byName[version.name] = version
end

-- Added to a floor's own seed for its offer, far from the floor's layout and deal (`Climb.seedOf`
-- steps a million a floor) and from its monsters' mix (KeeperMix's 2^40).
local SALT = 3 * 2 ^ 40

-- The seed of floor `number`'s offer in the climb from `seed`.
function NextFloor.seedOf(seed: number, number: number): number
	return Climb.seedOf(seed, number) + SALT
end

-- The version called `name`, or nil if there's none.
function NextFloor.find(name: string): Version?
	return byName[name]
end

-- Up to `Offered` versions for floor `number`, by name, each once, drawn from `random` (a fresh
-- Random from `seedOf`). None for a floor below every version's lowest (floor 1).
function NextFloor.deal(number: number, random: Random): { string }
	local pool: { string } = {}
	for _, version in NextFloor.Versions do
		if number >= version.lowest then
			table.insert(pool, version.name)
		end
	end
	local dealt: { string } = {}
	while #dealt < NextFloor.Offered and #pool > 0 do
		table.insert(dealt, table.remove(pool, random:nextInteger(1, #pool)) :: string)
	end
	return dealt
end

-- The version the team picked from `offered` by `presses` (each rider's press, by whoever
-- pressed): the most presses wins; a tie, or no presses at all, goes to one of the tied drawn
-- from `random`. A press for anything not offered counts for nothing. Nil with nothing offered.
function NextFloor.winner<K>(presses: { [K]: string }, offered: { string }, random: Random): string?
	if #offered == 0 then
		return nil
	end
	local counts: { [string]: number } = {}
	for _, name in presses do
		if table.find(offered, name) then
			counts[name] = (counts[name] or 0) + 1
		end
	end
	local best = -1
	local tied: { string } = {}
	for _, name in offered do
		local n = counts[name] or 0
		if n > best then
			best = n
			tied = { name }
		elseif n == best then
			table.insert(tied, name)
		end
	end
	if #tied == 1 then
		return tied[1]
	end
	return tied[random:nextInteger(1, #tied)]
end

-- The coins `version` pays each rider at floor `floor`'s gate on top of the floor's own: its
-- share of them, rounded, never under one.
function NextFloor.payOf(version: Version, floor: number): number
	return math.max(1, math.floor(Pay.forFloor(floor) * version.pay + 0.5))
end

-- The versions lit on a panel, for the car's attribute.
function NextFloor.encodeOffer(offered: { string }): string
	return table.concat(offered, ",")
end

-- The versions lit on a panel from the car's attribute, keeping only real ones, each once.
function NextFloor.decodeOffer(text: string): { string }
	local offered: { string } = {}
	for name in string.gmatch(text, "[^,]+") do
		if byName[name] and not table.find(offered, name) then
			table.insert(offered, name)
		end
	end
	return offered
end

-- Who's pressed which (by UserId), for the car's attribute, in UserId order.
function NextFloor.encodePresses(presses: { [number]: string }): string
	local ids: { number } = {}
	for id in presses do
		table.insert(ids, id)
	end
	table.sort(ids)
	local parts: { string } = table.create(#ids)
	for i, id in ids do
		parts[i] = `{string.format("%d", id)}:{presses[id]}`
	end
	return table.concat(parts, ",")
end

-- Who's pressed which from the car's attribute, keeping only real versions.
function NextFloor.decodePresses(text: string): { [number]: string }
	local presses: { [number]: string } = {}
	for id, name in string.gmatch(text, "(%-?%d+):([^,]+)") do
		local n = if id then tonumber(id) else nil
		if n and name and byName[name] then
			presses[n] = name
		end
	end
	return presses
end

return table.freeze(NextFloor)
