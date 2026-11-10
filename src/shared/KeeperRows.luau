--!strict
--[[
	KeeperRows: each keeper as a row of data (the GDD's "one chase engine, keepers as data"; D-064).
	A new keeper is a model, its animations and a row here, never new brain code (`Keeper` reads
	the row). Each number says what it does to the player. The GDD gives the rules (no keeper
	outruns a running player); the numbers it doesn't give are defaults the owner tunes in play
	(OWNER.md).
]]
local KeeperMap = require("./KeeperMap")
local KeeperTell = require("./KeeperTell")
local MannequinSpecs = require("./Mannequin/Specs")

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
	-- Seconds it stands where it heard something, facing it, before it wanders off. Long enough to
	-- make whoever made the noise hold their breath behind the door.
	linger: number,
	-- Once out, it roams the halls between noises and never goes home (D-071): it walks at its
	-- looking pace to a hall piece's middle whose trip along the halls is from `roamNear` to
	-- `roamFar` studs, stands there `roamLinger` seconds, and picks again, never one of the last
	-- `roamMemory` places it stood in.
	roamNear: number,
	roamFar: number,
	roamLinger: number,
	roamMemory: number,
	-- How far it sees a player, in studs, in a straight line the map clears (never through a wall
	-- or a shut door), and how wide: degrees either side of the way it faces. Seen, it hunts them
	-- at its top speed; hunting, it keeps them in sight any way it faces, out to `sight`.
	sight: number,
	sightAngle: number,
	-- Whether it moves only while no light is on it (the GDD's Mannequin): a lit hall light over
	-- it or a torch's beam on it holds it where it stands, mid-stride, until no light is.
	freezesInLight: boolean,
	-- How tall it stands (studs): a torch's beam on it anywhere from its feet to its head counts.
	height: number,
	-- Its grasp (L-06b3c): hunting, it catches the one it hunts once their feet are within `reach`
	-- studs of its own along the halls, within `reachAngle` degrees either side of the way it
	-- faces, along a line the map clears, and no higher than its head. A little past `Keeper.Close`,
	-- where its hunt stops, so standing still at arm's length is caught, and a step away as it
	-- arrives isn't always enough.
	reach: number,
	reachAngle: number,
	-- Trapped (L-06b3d): a door it was standing behind came down from all the way up. It goes to
	-- stand against the door and bangs on it from inside: the first blow `bangFirst` seconds after
	-- the door came down, then one every `bangEvery` seconds, closing to `bangEveryLast` as its time
	-- runs out, each gap a random `bangJitter` share longer or shorter. At `breakOut` seconds it
	-- bursts the door up, unless it's padlocked, and goes after the last thing it heard.
	bangFirst: number,
	bangEvery: number,
	bangEveryLast: number,
	bangJitter: number,
	breakOut: number,
	-- How it gives itself away by sound (L-06b4b2; KeeperTell): a footfall each step its walk
	-- lands and a knock of its joints each pass, from its body on every screen near, and one
	-- knock as a door lifted on it standing in a unit first shows its feet.
	tell: KeeperTell.Tell,
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
	-- at least about two hall pieces off, so it visibly moves on and you lose track of it, rather
	-- than shuffling about the door it looked at
	roamNear = 40,
	-- at most about five, some 17 s at its walk: it works one part of the floor for a while, so
	-- you can learn where it went, instead of crossing the floor each time
	roamFar = 120,
	-- long enough to read as stopping to look, short enough that it's soon moving again
	roamLinger = 3,
	-- the last four places it stood: it doesn't pace back and forth between two halls
	roamMemory = 4,
	-- two hall pieces: round a corner into its hall and it has you; a hall further off and you
	-- can still slip past a junction unseen
	sight = 48,
	-- a wide look ahead (120 degrees across) but blind behind: you can creep up on one that walks
	-- away from you, never on one coming toward you
	sightAngle = 60,
	-- the GDD's signature scare: keep a light on it, by moving under the hall's lights or by
	-- pointing your torch at it, and it can't come for you
	freezesInLight = true,
	height = MannequinSpecs.Height,
	-- a stud past arm's length: its hand closes on you as it arrives, unless you're already moving
	-- away at a run (it's slower than you, so you pull clear)
	reach = 3.5,
	-- both arms reaching ahead, 90 degrees across: it has to turn to you to grab, so it can't catch
	-- you as you slip past its side
	reachAngle = 45,
	-- you slam it and, a breath later, it hits the door: you know it's in there and it's angry
	bangFirst = 1.2,
	-- slow, heavy blows at first, so a minute and a half of them doesn't wear you out
	bangEvery = 5,
	-- faster and faster near the end: you hear its time running out without a clock
	bangEveryLast = 2,
	-- never a metronome: each gap up to a quarter longer or shorter
	bangJitter = 0.25,
	-- the GDD's "about 90 seconds": long enough to loot the floor, short enough that a slam only
	-- buys time
	breakOut = 90,
	tell = {
		-- a stiff, flat clack of fibreglass on concrete each step it lands: Pro Sound Effects'
		-- "Wood Drop Light" 4 and 2 (a light board dropped flat on concrete), each cut to its first
		-- hit, measured at about 860 Hz, where a phone's speaker plays it
		footfall = {
			takes = {
				{ id = "rbxassetid://9120864768", start = 1.445, stop = 1.695 },
				{ id = "rbxassetid://9120864539", start = 0.97, stop = 1.145 },
			},
			fade = 0.05,
			-- the beat of its walk: the loudest thing it does
			volume = 0.75,
			-- a little lower than the board: heavier, and never the same clack twice
			pitchMin = 0.88,
			pitchMax = 0.98,
			near = 6,
			-- about three hall pieces: past the 48 it sees, so you hear it coming before it can
			-- see you, and a hall further off it's only a tapping in the dark
			reach = 70,
		},
		-- a thin, hollow knock at its joints each pass of its legs: "Knock Slap Plastic" 9 and 7 (a
		-- hand knocking a thin plastic shell), each a single knock, about 700 Hz
		knock = {
			takes = {
				{ id = "rbxassetid://9116201805", start = 0.145, stop = 0.45 },
				{ id = "rbxassetid://9116201611", start = 0.145, stop = 0.45 },
			},
			fade = 0.1,
			-- under the footfalls (about 6 dB): the texture between the beats, not a second beat
			volume = 0.55,
			pitchMin = 0.95,
			pitchMax = 1.08,
			near = 4,
			-- heard closer than its feet: the knocking means it's near
			reach = 40,
		},
		-- under a frame: a late record that jumps its pose makes one sound, not a burst
		gap = 0.08,
		-- the curtain's edge a few inches up, clearing its feet: the knock lands as a crouched
		-- peek first sees them (a peek lifts 1.15)
		revealRise = 0.4,
		-- louder and deeper than its walking knock: one deliberate knock, its joints settling as
		-- if it heard you
		revealGain = 1.5,
		revealPitch = 0.85,
		-- a peek, a drop and a peek again in quick succession knocks once
		revealGap = 3,
	},
}

local KeeperRows: { [string]: Row } = {
	Mannequin = Mannequin,
}

return table.freeze(KeeperRows)
