--!strict
--[[
	KeeperMix: which monsters a floor has (S4-02, GDD "Floor rules": every monster has a lowest
	floor, and from that floor up the game mixes it in at random). As DOORS' entities each start
	at a door number and then turn up at random past it, each monster's row (`KeeperRows`) carries
	its lowest floor and its share: the chance a floor above it has it at all. So two climbs in a
	row meet them on different floors: one climb's floor 4 has the Packrat asleep on its pile, the
	next one's floor 4 is only Mannequins and the Packrat is waiting on 5.

	- `on` is pure: a floor's own Random (from `seedOf`, the climb's seed and the floor's number)
	  draws one roll for each monster in `Order`, every time, so the same seed always lays the same
	  floors and a new monster at the end of `Order` moves no old one.
	- A floor version (S4-03, the team's choice on the ride) leans the mix with a `Lean`: its own
	  chance for a monster in place of the row's share, 1 to bring it, 0 to keep it away. Never
	  below the monster's lowest floor, and it moves no other monster's roll.
	- A floor always has one monster that hunts (one that doesn't collect finds), since the guarded
	  note's unit always holds one awake (D-072): if the rolls leave every hunter out, the one whose
	  roll came lowest is in anyway.
	The deal reads the result (`Deal.new`'s `cast`).
]]
local Climb = require("./Climb")
local Floor = require("./Floor")
local KeeperRows = require("./KeeperRows")

type Random = Floor.Random

--- The monsters on a floor, by name.
export type Cast = { [string]: boolean }
--- A floor version's chance for a monster (0 to 1), by name, in place of its row's share.
export type Lean = { [string]: number }

local KeeperMix = {}

-- The order the monsters draw their rolls in: each new monster goes on the end, so a climb's old
-- floors keep their monsters (tests/keepermix.spec checks every row is here).
KeeperMix.Order = table.freeze({ "Mannequin", "Packrat" })

-- Added to a floor's own seed for its mix, far past any floor's seed (`Climb.seedOf` steps a
-- million a floor), so the mix shares no rolls with the floor's layout and deal.
local SALT = 2 ^ 40

-- The seed of floor `number`'s mix in the climb from `seed`.
function KeeperMix.seedOf(seed: number, number: number): number
	return Climb.seedOf(seed, number) + SALT
end

-- Whether monster `name` may be on floor `number` at all: its lowest floor or above.
function KeeperMix.joined(name: string, number: number): boolean
	local row = KeeperRows[name]
	return row ~= nil and number >= row.lowest
end

-- Every monster that may be on floor `number`, as the deal had them before the mix (a floor laid
-- without one, as the specs and the test hall lay them).
function KeeperMix.all(number: number): Cast
	local cast: Cast = {}
	for _, name in KeeperMix.Order do
		if KeeperMix.joined(name, number) then
			cast[name] = true
		end
	end
	return cast
end

-- The monsters on floor `number`, from `random` (a fresh Random from `seedOf`), leaned by a floor
-- version's `lean` if it has one.
function KeeperMix.on(number: number, random: Random, lean: Lean?): Cast
	local cast: Cast = {}
	local closest: string? = nil
	local lowest = math.huge
	for _, name in KeeperMix.Order do
		local row = KeeperRows[name]
		local roll = random:nextNumber() -- drawn whether it has joined or not
		if row and number >= row.lowest then
			local chance = if lean and lean[name] then lean[name] else row.share
			if roll < chance then
				cast[name] = true
			end
			if row.collects == nil and roll < lowest then
				closest, lowest = name, roll
			end
		end
	end
	local hunting = false
	for name in cast do
		hunting = hunting or KeeperRows[name].collects == nil
	end
	if not hunting and closest then
		cast[closest] = true
	end
	return cast
end

return table.freeze(KeeperMix)
