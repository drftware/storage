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
local PackratSpecs = require("./Packrat/Specs")

--- How a keeper that collects finds goes about it (S2-06b1, the Packrat): told what lies loose on
--- its floor (`Keeper.lying`), it walks to the nearest, reaches, takes it, carries it home to its
--- pile and comes out for the next, seeing and hearing no one while its arms are full.
export type Collect = {
	-- How far from a find it stops to reach for it, its feet to the floor under the find (studs):
	-- its long arm's span (D-177), so its fingertips land on it rather than it walking onto it.
	grab: number,
	-- Seconds it stands with its arm out over the find before its hands close on it: a beat you
	-- see coming, long enough to snatch the find from under its hand if you're right there.
	reach: number,
	-- Seconds its hands close on it, pulling it in to its chest, before it turns for home.
	take: number,
	-- Seconds it stands crouched over its pile, laying the find down, before it comes out again.
	putDown: number,
	-- Its walk with its arms full, as a share of its walk with them empty: slower, laden.
	laden: number,
}

export type Row = {
	name: string,
	-- The lowest floor it can turn up on (GDD "Floor rules"): it's never on a floor below it.
	lowest: number,
	-- From its lowest floor up, the chance a floor has it at all (`KeeperMix`, S4-02), 0 to 1:
	-- under 1, two climbs meet it on different floors, as DOORS' entities turn up at random past
	-- the door each starts at. A floor version can lean it (S4-03).
	share: number,
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
	-- Seconds a new sound stops it dead where it stands, turned to face it, before it goes to look
	-- (`Keeper.hear`): its walk breaks off, and whoever made the noise hears that it heard.
	startle: number,
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
	-- Whether a hall light over it wakes as it walks, as one over a player does (S2-06b2b, the
	-- Packrat: you see it coming, and a Mannequin near it freezes; `OWNER.md` asks). None: it
	-- walks the dark (the Mannequin, which would freeze in its own light).
	tripsLights: boolean?,
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
	-- How it gives itself away by sound (L-06b4b2, L-06c1; KeeperTell): the beats its walk lands,
	-- its body creaking as it turns, and its answer as a door lifted on it standing in a unit first
	-- shows its feet, from its body on every screen near.
	tell: KeeperTell.Tell,
	-- How it sounds with its arms full (S2-06e, `KeeperTell.full`), so a player knows from round a
	-- corner whether it's coming for them or hauling something home; nil: as `tell` always.
	full: KeeperTell.Tell?,
	-- It carries the floor's finds home (`Collect`, S2-06b1); none: it never picks one up.
	collects: Collect?,
}

local Mannequin: Row = {
	name = "Mannequin",
	-- every floor: it stands guard over a note on each (D-072), and it's the only one that hunts,
	-- so it's in every mix until a second hunter joins and can take its place on some floors
	lowest = 1,
	share = 1,
	-- just under your run: when it hunts (L-06b3) it closes in only while you stop or slow
	speed = 0.9,
	-- going to look, about 0.45 of your run: a slam two halls off gives you about seven seconds
	-- to get behind a door before it's standing outside it
	looking = 0.5,
	abilities = {}, -- it only walks: no ladders, no crawl holes (D-068)
	hearing = 1,
	linger = 5,
	-- about two of its steps missing from the limp: long enough that the stop reads as listening,
	-- short enough not to hand back the time the noise cost you
	startle = 0.8,
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
		sounds = {
			-- the hollow fibreglass foot hitting concrete, the beat that carries down the halls: Pro
			-- Sound Effects' "Plastic Impacts Dish Shaped Planter" 5, 23, 27 and 22 (a big plastic
			-- dish dropped on asphalt), each cut to its one hit, 320 to 680 Hz
			Shell = {
				takes = {
					{ id = "rbxassetid://9117557254", start = 0.625, stop = 0.78 },
					{ id = "rbxassetid://9117570260", start = 0.085, stop = 0.3 },
					{ id = "rbxassetid://9117571208", start = 0.565, stop = 0.72 },
					{ id = "rbxassetid://9117570079", start = 0.155, stop = 0.25 },
				},
				fade = 0.04,
				-- under the weight up close; out past the weight's reach it's all you hear
				volume = 0.55,
				-- lower than the recording: a hollow body, not a toy
				pitchMin = 0.74,
				pitchMax = 0.86,
				near = 6,
				-- about three hall pieces: past the 48 it sees, so you hear it coming before it can
				-- see you, and a hall further off it's a slow hollow knocking in the dark
				reach = 70,
				farGain = 1,
				farPitch = 1,
			},
			-- the body's weight landing on that foot: "Plastic Cooler 6" (a big hollow plastic box
			-- hitting the floor, mostly 190 to 470 Hz, where a phone still plays), "Body Impact 2" (a
			-- body's hard thump) and "Wood Drop Wood Log 2" (a railroad tie dropped on pavement)
			Weight = {
				takes = {
					{ id = "rbxassetid://9117451558", start = 0.055, stop = 0.42 },
					{ id = "rbxassetid://9113524237", start = 0.025, stop = 0.36 },
					{ id = "rbxassetid://9120871246", start = 0.485, stop = 0.72 },
				},
				fade = 0.08,
				-- the loudest thing it does, once it's on top of you
				volume = 0.9,
				pitchMin = 0.84,
				pitchMax = 0.96,
				near = 8,
				reach = 50,
				-- far off the weight is all but gone and a little higher: a tap down the hall that
				-- turns into a thud in your own
				farGain = 0.1,
				farPitch = 1.15,
			},
			-- its dragged foot grinding along the concrete: "Rock Scrape On Concrete Constant
			-- Dragging Dry 2", three strokes cut from it, raised into what a phone plays
			Scrape = {
				takes = {
					{ id = "rbxassetid://9125883658", start = 0.15, stop = 0.5 },
					{ id = "rbxassetid://9125883658", start = 0.78, stop = 1.13 },
					{ id = "rbxassetid://9125883658", start = 1.745, stop = 2.1 },
				},
				fade = 0.12,
				volume = 0.8,
				pitchMin = 1.1,
				pitchMax = 1.3,
				near = 6,
				-- heard nearer than its steps: the scrape means it's in your hall
				reach = 45,
				farGain = 0.4,
				farPitch = 1,
			},
			-- its stiff body straining as it turns: "Gas Pedal Cu Slow Pressing Movements
			-- Squeezing 1" (a rubber pedal pressed, a ratcheting creak) and two stretches of "Tire
			-- Squeak Cu Creak Rub Together Rubber 1", pitched down into a groan
			Creak = {
				takes = {
					{ id = "rbxassetid://9125571873", start = 1.095, stop = 1.45 },
					{ id = "rbxassetid://9120078794", start = 0.195, stop = 0.55 },
					{ id = "rbxassetid://9120078794", start = 1.05, stop = 1.42 },
				},
				fade = 0.1,
				volume = 0.7,
				pitchMin = 0.68,
				pitchMax = 0.8,
				near = 4,
				-- only close: a creak means it's turning right there in the dark
				reach = 32,
				farGain = 0.5,
				farPitch = 1,
			},
		},
		beats = {
			-- its good foot planted: the hollow thunk, and the weight behind it
			Footfall = {
				{ sound = "Shell", gain = 1, pitch = 1 },
				{ sound = "Weight", gain = 1, pitch = 1 },
			},
			-- its stiff foot dragged through
			Drag = { { sound = "Scrape", gain = 1, pitch = 1 } },
			-- the stiff leg's heel landing: harder and lighter than the plant, so the walk limps
			Heel = {
				{ sound = "Shell", gain = 0.9, pitch = 1.1 },
				{ sound = "Weight", gain = 0.35, pitch = 1.05 },
			},
			Creak = { { sound = "Creak", gain = 1, pitch = 1 } },
			-- a door lifted on it: one deep thunk as its weight shifts, and its body creaking, as
			-- if it heard you
			Reveal = {
				{ sound = "Shell", gain = 1.6, pitch = 0.82 },
				{ sound = "Creak", gain = 1.2, pitch = 0.9 },
			},
			-- its catch, in your ears only (L-06c2): its stiff body wrenching into the lunge, a
			-- groan of strained plastic, its foot tearing at the concrete as it pushes off
			Lunge = {
				{ sound = "Creak", gain = 1.4, pitch = 0.85 },
				{ sound = "Scrape", gain = 1.2, pitch = 0.9 },
			},
			-- it heard you (L-15): it stops dead on its good foot, a deep hollow thunk with its weight
			-- behind it, and its stiff body wrenches round toward the sound with a groan. Far off only
			-- the thunk carries, and the limp you were hearing stops.
			Heard = {
				{ sound = "Shell", gain = 1.7, pitch = 0.78 },
				{ sound = "Weight", gain = 1, pitch = 0.9 },
				{ sound = "Creak", gain = 1.4, pitch = 0.82 },
			},
			-- and its hollow head hitting your face: the deepest thunk it makes, its weight behind it
			Catch = {
				{ sound = "Shell", gain = 1.8, pitch = 0.72 },
				{ sound = "Weight", gain = 1.1, pitch = 0.85 },
			},
		},
		-- full weight within about a unit's width; just a tap from about two hall pieces off
		heavyNear = 10,
		heavyFar = 40,
		-- under a frame: a late record that jumps its pose makes one beat, not a burst
		gap = 0.08,
		-- a corner, or turning to come at you, creaks; walking its line never does
		turn = 40,
		-- one creak to a turn, never a rattle of them
		turnGap = 0.9,
		-- the curtain's edge a few inches up, clearing its feet: the answer lands as a crouched
		-- peek first sees them (a peek lifts 1.15)
		revealRise = 0.4,
		-- a peek, a drop and a peek again in quick succession answers once
		revealGap = 3,
	},
}

-- The Packrat with its arms full (S2-06e, its row's `full`): it's hauling something home and
-- ignores you. Quicker, heavier steps with its body's weight under them, and the find jostling
-- and rattling in its arms at every step. Busy and bright where the empty walk is soft: you can
-- follow the rattle home.
local PackratFull: KeeperTell.Tell = {
	sounds = {
		-- heavier feet: "Foot Stomp" 2 and 3 (more of the stomp's knock, 470 Hz to 2 kHz)
		Tread = {
			takes = {
				{ id = "rbxassetid://9114523351", start = 0, stop = 0.08 },
				{ id = "rbxassetid://9114523345", start = 0, stop = 0.07 },
			},
			fade = 0.03,
			volume = 0.75,
			pitchMin = 0.62,
			pitchMax = 0.7,
			near = 6,
			reach = 60,
			farGain = 0.4,
			farPitch = 1.1,
		},
		-- the load's weight on each step: "Body Impact 2" (a body's hard thump), only close
		Weight = {
			takes = {
				{ id = "rbxassetid://9113524237", start = 0.02, stop = 0.3 },
			},
			fade = 0.08,
			volume = 0.7,
			pitchMin = 0.9,
			pitchMax = 1,
			near = 8,
			reach = 45,
			farGain = 0.1,
			farPitch = 1.15,
		},
		-- the find jostled in its arms: three bumps of "Bag Drop Bag Bumping Wall 2" (a purse
		-- knocked on a wall, its contents jingling), 470 Hz up, the part a phone plays best
		Jostle = {
			takes = {
				{ id = "rbxassetid://9113244443", start = 0.15, stop = 0.26 },
				{ id = "rbxassetid://9113244443", start = 0.26, stop = 0.4 },
				{ id = "rbxassetid://9113244443", start = 0.45, stop = 0.62 },
			},
			fade = 0.04,
			volume = 0.55,
			pitchMin = 0.85,
			pitchMax = 1,
			near = 6,
			-- the rattle carries furthest: you can follow it home
			reach = 70,
			farGain = 0.7,
			farPitch = 1,
		},
		-- loose things rattling between steps: "Ammo Box Movement 2" (metal rattling in a box)
		-- and "Chair Impact 12" (a plastic chair knocked about), a junk pile's clatter
		Rattle = {
			takes = {
				{ id = "rbxassetid://9113103014", start = 0.24, stop = 0.48 },
				{ id = "rbxassetid://9113771767", start = 0.24, stop = 0.47 },
				{ id = "rbxassetid://9113771767", start = 0.51, stop = 0.71 },
				{ id = "rbxassetid://9113771767", start = 0.74, stop = 0.88 },
			},
			fade = 0.06,
			volume = 0.5,
			pitchMin = 0.9,
			pitchMax = 1.05,
			near = 6,
			reach = 55,
			farGain = 0.7,
			farPitch = 1,
		},
	},
	beats = {
		Footfall = {
			{ sound = "Tread", gain = 1, pitch = 1 },
			{ sound = "Weight", gain = 1, pitch = 1 },
			{ sound = "Jostle", gain = 1, pitch = 1 },
		},
		Drag = { { sound = "Rattle", gain = 1, pitch = 1 } },
		Heel = {
			{ sound = "Tread", gain = 0.9, pitch = 1.06 },
			{ sound = "Weight", gain = 0.8, pitch = 1.05 },
			{ sound = "Jostle", gain = 0.8, pitch = 1.08 },
		},
		-- turning with its arms full: the load shifts
		Creak = { { sound = "Jostle", gain = 1.2, pitch = 0.9 } },
		-- never heard: full, it stands in no unit, hears nothing and catches no one (D-178).
		-- Played as the load shifting, should one ever come.
		Reveal = { { sound = "Jostle", gain = 1.2, pitch = 0.9 } },
		Lunge = { { sound = "Rattle", gain = 1.5, pitch = 0.9 } },
		Heard = {
			{ sound = "Tread", gain = 1.2, pitch = 0.9 },
			{ sound = "Rattle", gain = 1.5, pitch = 0.9 },
		},
		Catch = {
			{ sound = "Tread", gain = 1.3, pitch = 0.85 },
			{ sound = "Weight", gain = 1.2, pitch = 0.9 },
		},
	},
	heavyNear = 10,
	heavyFar = 40,
	gap = 0.08,
	turn = 40,
	turnGap = 0.9,
	revealRise = 0.4,
	revealGap = 3,
}

local Packrat: Row = {
	name = "Packrat",
	-- from floor 3, about three floors in five: often enough that you know it, and on a floor
	-- without it your finds stay where you dropped them (OWNER.md tunes it)
	lowest = 3,
	share = 0.6,
	-- just under your run (the GDD's "just under walking speed"; your walk is your run): with
	-- empty arms it comes for you (S2-06c) and closes in only while you stop or slow
	speed = 0.9,
	-- going about its work at a brisk walk, over half your run: quicker than the Mannequin's
	-- limp, so it gets round the floor, yet you can follow it home at a jog
	looking = 0.6,
	abilities = {}, -- it only walks: no ladders, no crawl holes
	-- with empty arms it hears a door as far as you do; full, it hears nothing (`Keeper.hear`)
	hearing = 1,
	-- a little less than the Mannequin's: it has work to get back to
	linger = 4,
	startle = 0.6,
	roamNear = 40,
	roamFar = 120,
	roamLinger = 2.5,
	roamMemory = 4,
	-- as the Mannequin's: round a corner into its hall with empty arms and it has you
	sight = 48,
	sightAngle = 60,
	-- the GDD: light does nothing to it, so a torch held on a Mannequin won't save your find
	freezesInLight = false,
	-- the halls light up round it as it walks, as for a player (a default in `OWNER.md`)
	tripsLights = true,
	height = PackratSpecs.Height,
	-- one long arm out (D-177) reaches a little further than the Mannequin's two, in a narrower
	-- cone: it has to be facing you
	reach = 4,
	reachAngle = 35,
	-- the GDD: like any monster shut in a unit, it pounds and breaks out after 90 seconds
	bangFirst = 1.2,
	bangEvery = 5,
	bangEveryLast = 2,
	bangJitter = 0.25,
	breakOut = 90,
	-- Its arms empty, it's coming for you, and it's quiet (S2-06e): padded steps (its feet are
	-- sacked in blankets) and, once a stride, a screech of packing tape pulled off a roll, the tape
	-- it wraps you in. You hear the tape before you see it, round a corner, as Left 4 Dead's Witch
	-- is heard before she's seen. Every take measured (docs/STUDIO.md, "Sounds measured for the
	-- Packrat").
	tell = {
		sounds = {
			-- a blanket-sacked foot landing: Pro Sound Effects' "Foot Stomp" 1, 4 and 7 (a stomp on
			-- a hard carpeted floor, mostly 190 to 470 Hz, where a phone still plays), each one hit
			Pad = {
				takes = {
					{ id = "rbxassetid://9114523161", start = 0, stop = 0.09 },
					{ id = "rbxassetid://9114523358", start = 0, stop = 0.08 },
					{ id = "rbxassetid://9114523629", start = 0, stop = 0.08 },
				},
				fade = 0.03,
				volume = 0.6,
				-- pitched down: a big soft body, not a person
				pitchMin = 0.66,
				pitchMax = 0.76,
				near = 6,
				-- past the 48 it sees, so its steps reach you before it can see you
				reach = 60,
				-- far off a soft tap a little higher; close, a muffled thud
				farGain = 0.35,
				farPitch = 1.12,
			},
			-- tape screeching off a roll: three stretches of the steady peel in Pro Sound Effects'
			-- "Duct Tape Richard Epilates Himself 2" (the kept wrap's squeal, L-07b), 1 to 2 kHz
			Tape = {
				takes = {
					{ id = "rbxassetid://9114200236", start = 0.78, stop = 1.08 },
					{ id = "rbxassetid://9114200236", start = 1.2, stop = 1.5 },
					{ id = "rbxassetid://9114200236", start = 1.72, stop = 2.02 },
				},
				fade = 0.08,
				volume = 0.5,
				-- a little slow: drawn out, not ripped
				pitchMin = 0.82,
				pitchMax = 0.96,
				near = 6,
				-- heard nearer than its steps: the tape means it's in your hall
				reach = 50,
				farGain = 0.5,
				farPitch = 1,
			},
			-- the tape on its bundle crackling as it turns: two crackles and a burst from "Duct Tape
			-- Richard Epilates Himself 3"
			Crackle = {
				takes = {
					{ id = "rbxassetid://9114200240", start = 0.03, stop = 0.28 },
					{ id = "rbxassetid://9114200240", start = 1.2, stop = 1.45 },
					{ id = "rbxassetid://9114200240", start = 1.6, stop = 1.85 },
				},
				fade = 0.06,
				volume = 0.55,
				pitchMin = 0.85,
				pitchMax = 1,
				near = 4,
				-- only close: it's turning right there
				reach = 30,
				farGain = 0.6,
				farPitch = 1,
			},
		},
		beats = {
			-- its lead foot down
			Footfall = { { sound = "Pad", gain = 1, pitch = 1 } },
			-- the tape, once a stride
			Drag = { { sound = "Tape", gain = 1, pitch = 1 } },
			-- the trailing foot, a little lighter: the stride lopes
			Heel = { { sound = "Pad", gain = 0.8, pitch = 1.08 } },
			Creak = { { sound = "Crackle", gain = 1, pitch = 1 } },
			-- a door lifted on it among its pile: its weight shifting, and the tape creaking long and
			-- low, as if it heard you
			Reveal = {
				{ sound = "Pad", gain = 1.5, pitch = 0.85 },
				{ sound = "Tape", gain = 1.4, pitch = 0.72 },
			},
			-- its catch, in your ears only (L-06c2): it rears up, the tape tearing off the roll at you
			Lunge = {
				{ sound = "Tape", gain = 1.8, pitch = 1.1 },
				{ sound = "Crackle", gain = 1.6, pitch = 0.8 },
			},
			-- it heard you (L-15): it stops dead on a heavy step and the tape shrieks as it wrenches
			-- round toward the sound
			Heard = {
				{ sound = "Pad", gain = 1.6, pitch = 0.88 },
				{ sound = "Tape", gain = 1.6, pitch = 1.15 },
			},
			-- its weight landing on you
			Catch = {
				{ sound = "Pad", gain = 1.65, pitch = 0.8 },
				{ sound = "Crackle", gain = 1.4, pitch = 0.75 },
			},
		},
		heavyNear = 10,
		heavyFar = 40,
		gap = 0.08,
		turn = 40,
		turnGap = 0.9,
		revealRise = 0.4,
		revealGap = 3,
	},
	-- with its arms full, as `PackratFull` says (S2-06e)
	full = PackratFull,
	collects = {
		-- its reaching fingertips are about 4.2 ahead of its chest (D-177), its chest a little
		-- behind its feet's front: 4 from its feet puts its hand on the find
		grab = 4,
		reach = 0.8,
		take = 0.5,
		-- crouched over the pile long enough to see what it added, if you followed it home
		putDown = 1.2,
		-- the full walk's stride is 72% of the empty one (D-177): at 72% of the pace its feet
		-- keep the same beat, so full reads as weighed down, never as walking in slow motion
		laden = 0.72,
	},
}

local KeeperRows: { [string]: Row } = {
	Mannequin = Mannequin,
	Packrat = Packrat,
}

return table.freeze(KeeperRows)
