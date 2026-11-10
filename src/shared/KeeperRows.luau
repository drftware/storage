--!strict
--[[
	KeeperRows: each keeper as a row of data (the GDD's "one chase engine, keepers as data"; D-064).
	A new keeper is a model, its animations and a row here, never new brain code (`Keeper` reads
	the row). Each number says what it does to the player. The GDD gives the rules (no keeper
	outruns a running player); the numbers it doesn't give are defaults the owner tunes in play
	(OWNER.md).
]]
local KeeperMap = require("./KeeperMap")

export type Row = {
	name: string,
	-- Its top speed, as a share of a player's full run. The GDD's speed rule: never over 1, so
	-- nothing outruns you in a straight hall; the maze, a slow door and greed catch you instead.
	speed: number,
	-- Going to look at a sound and going back, as a share of its top speed: a walk, not the hunt.
	looking: number,
	-- What it can do beyond walking (KeeperMap.Ability): the passages it may use (D-068).
	abilities: { KeeperMap.Ability },
	-- How far it hears, as a share of each sound's reach (DoorSound): 1 hears a door exactly as
	-- far as a player does, 0 hears nothing.
	hearing: number,
	-- Seconds it stands where it heard something, facing it, before it goes back. Long enough to
	-- make whoever made the noise hold their breath behind the door.
	linger: number,
}

local Mannequin: Row = {
	name = "Mannequin",
	-- just under your run: when it hunts (L-06b3) it closes in only while you stop or slow
	speed = 0.9,
	-- going to look, about 0.45 of your run: a slam two halls off gives you about seven seconds
	-- to get behind a door before it's standing outside it
	looking = 0.5,
	abilities = {}, -- it only walks: no ladders, no crawl holes (D-068)
	hearing = 1,
	linger = 5,
}

local KeeperRows: { [string]: Row } = {
	Mannequin = Mannequin,
}

return table.freeze(KeeperRows)
