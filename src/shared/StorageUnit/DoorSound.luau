--!strict
--[[
	What a roll-up door sounds like, and when (GDD "Doors": the door table's Noise column). Pure
	rules, so they're tested in Lune; the client's DoorSounds system plays them at each door.

	Two kinds of sound:
	- The roll: the curtain's rattle while it moves, one looping recording whose volume and pitch
	  follow the door's speed every frame. It can't drift from what you see: a slow start sounds
	  slow, the three heaves of a lift from inside surge three times, and it falls quiet as the door
	  eases to a stop.
	- Cues: one-shots at the moments Motion.strikes says the door hits something (the slam's bang
	  and bounce, a close settling, a lift meeting the stop bolts), plus the latch as a lift starts,
	  the padlock, and a padlocked door rattling against its bolt when someone tries it.

	Every recording is from Roblox's licensed audio library (Pro Sound Effects), so it loads in any
	game. Start and Stop pick the stretch of the recording to play; they were found by measuring
	each recording's loudness over time in Studio (docs/STUDIO.md, "Measuring a sound").
]]

-- a string require, as Brix's modules do, so Lune can load this module for its tests too
local Motion = require("./Motion")

export type SoundName =
	"Roll"
	| "Bang"
	| "Thump"
	| "Clatter"
	| "Latch"
	| "PadlockShut"
	| "PadlockOpen"
	| "Snap"
	| "PadlockFall"
	| "Rattle"

export type Sound = {
	Id: string,
	Start: number, -- seconds into the recording where it starts
	Stop: number, -- and where it ends
	Fade: number, -- seconds it fades out over before Stop, so a cut never clicks
	Volume: number,
	PitchMin: number, -- each play picks a pitch in this range, so repeats never sound identical
	PitchMax: number,
	Near: number, -- full volume within this many studs
	Reach: number, -- silent beyond this many studs: the loud ones carry farther
}

export type Cue = {
	at: number, -- seconds after the motion (or the lock) starts
	sound: SoundName,
	gain: number, -- times the sound's Volume
	pitch: number, -- times its picked pitch
	shake: number, -- camera shake for someone right beside the door (Shake trauma), 0 for none
}

local DoorSound = {}

DoorSound.Sounds = {
	-- The curtain rolling: a truck's rear roll-up door, the same slatted curtain on a drum
	-- (Pro Sound Effects "Truck Trailer Door 3"). This is its steady 4 s stretch, looped.
	Roll = {
		Id = "rbxassetid://9120273047",
		Start = 1.2,
		Stop = 5.2,
		Fade = 0,
		Volume = 0.9,
		PitchMin = 0.97,
		PitchMax = 1.03,
		Near = 8,
		Reach = 110, -- each action sets its own (Actions below)
	},
	-- The slam's bang: a gas tank dropped on loose metal ("Vehicle Gas Tank Drop On Loose Metal
	-- 2"): one sharp, resonant hit and a rattle, cut before the recording's second hit. The
	-- loudest thing a door does, heard two halls away.
	Bang = {
		Id = "rbxassetid://9120381070",
		Start = 0.36,
		Stop = 1.78,
		Fade = 0.4,
		Volume = 1,
		PitchMin = 0.92,
		PitchMax = 1.02,
		Near = 12,
		Reach = 160,
	},
	-- Weight under the bang: a car door slammed ("Vehicle Door Bump Slamming Metal Door 4"),
	-- pitched down to a thump you feel. Pitched up and quiet, it's the stop bolts at the top.
	Thump = {
		Id = "rbxassetid://9120370893",
		Start = 0.07,
		Stop = 1.5,
		Fade = 0.3,
		Volume = 0.7,
		PitchMin = 0.96,
		PitchMax = 1.04,
		Near = 10,
		Reach = 120,
	},
	-- The slats clattering after a hit (impacts on a real garage door, "Wood Drops Impacts On
	-- Garage Door Clattering 58"): the slam's bounce, a close settling on the floor.
	Clatter = {
		Id = "rbxassetid://9126258354",
		Start = 0.05,
		Stop = 1.23,
		Fade = 0.25,
		Volume = 0.6,
		PitchMin = 0.94,
		PitchMax = 1.08,
		Near = 8,
		Reach = 80,
	},
	-- The latch bar sliding ("Prison Door 1": a big metal latch, jiggled). The recording is quiet,
	-- hence the volume over 1.
	Latch = {
		Id = "rbxassetid://9117910424",
		Start = 0.22,
		Stop = 0.9,
		Fade = 0.15,
		Volume = 1.6,
		PitchMin = 0.95,
		PitchMax = 1.06,
		Near = 6,
		Reach = 45,
	},
	-- The padlock's shackle snapping shut ("Padlock Open Lock Pick Up Throw Down 1", its lock).
	PadlockShut = {
		Id = "rbxassetid://9117185722",
		Start = 0.39,
		Stop = 0.62,
		Fade = 0.08,
		Volume = 0.9,
		PitchMin = 0.97,
		PitchMax = 1.03,
		Near = 5,
		Reach = 30,
	},
	-- ... and popping open (the same recording, its open).
	PadlockOpen = {
		Id = "rbxassetid://9117185722",
		Start = 0.02,
		Stop = 0.38,
		Fade = 0.08,
		Volume = 0.8,
		PitchMin = 0.97,
		PitchMax = 1.03,
		Near = 5,
		Reach = 30,
	},
	-- The cutters' jaw biting through the shackle: one crisp metal snap ("Scissors Snap 28", a
	-- single snap at its start, measured), played at half speed so it's a hardened bar going, not
	-- scissors. Loud enough to carry: keepers hear a cut (GDD: they hear doors).
	Snap = {
		Id = "rbxassetid://9118829487",
		Start = 0,
		Stop = 0.3,
		Fade = 0.08,
		Volume = 2,
		PitchMin = 0.5,
		PitchMax = 0.56,
		Near = 6,
		Reach = 40,
	},
	-- The cut padlock hitting the hall floor: the cutters' concrete clank ("Crowbar Impact
	-- Dropping To Concrete 1") played faster, a small heavy lump of steel and its bounce.
	PadlockFall = {
		Id = "rbxassetid://9114008989",
		Start = 0,
		Stop = 0.9,
		Fade = 0.2,
		Volume = 0.7,
		PitchMin = 1.6,
		PitchMax = 1.8,
		Near = 5,
		Reach = 30,
	},
	-- A padlocked door yanked against its bolt (Pro Sound Effects "Door Shake 4"): the first of
	-- its two shakes, from its onset at 0.15 s through the loudest stretch, cut as it starts to
	-- ring out. Loud on purpose: trying a padlocked door is a risk (GDD: keepers hear doors).
	Rattle = {
		Id = "rbxassetid://9114152830",
		Start = 0.14,
		Stop = 0.9,
		Fade = 0.18,
		Volume = 1,
		PitchMin = 0.94,
		PitchMax = 1.06,
		Near = 6,
		Reach = 70,
	},
} :: { [SoundName]: Sound }

--[[
	How loud each action's roll is and how far it carries (the GDD: peek quiet, open a loud rattle
	that keepers hear, lift from inside loud). Gain scales the roll; Pitch sets its character (a
	slow scrape low, a slam's fall high); Reach is where it fades to nothing, in studs. A hall is
	about 40 studs between turns, so 35 stays with the friend beside you and 110 reaches the next
	hall. The keepers' hearing (L-06) should take each action's loudness from here too.
]]
DoorSound.Actions = {
	Peek = { Gain = 0.3, Pitch = 0.86, Reach = 35 },
	Open = { Gain = 1, Pitch = 1, Reach = 110 },
	Close = { Gain = 0.75, Pitch = 1.05, Reach = 80 },
	Slam = { Gain = 0.9, Pitch = 1.22, Reach = 110 },
	LiftInside = { Gain = 1, Pitch = 0.84, Reach = 110 },
	-- A padlocked door doesn't roll: Gain 0 keeps the roll silent, and its Rattle cue is the sound.
	-- Reach is the Rattle row's, so a keeper hears it exactly as far as a player does.
	Rattle = { Gain = 0, Pitch = 1, Reach = 70 },
	-- A trapped keeper's blow from inside (L-06b3d) doesn't roll either: its cues are the sound.
	-- It carries as far as a rattle: a hall and a half, so keepers that far off come to look.
	Bang = { Gain = 0, Pitch = 1, Reach = 70 },
	-- Its burst: the loudest lift there is, flung up fast, so the roll runs high and carries past
	-- the next hall.
	Burst = { Gain = 1, Pitch = 1.18, Reach = 130 },
	-- The tap's door (S2-05a). Pulled down over a sleeper it rolls as a close does, softer as it
	-- slows to its creep; its settle onto the concrete is barely there; a miss's drop rolls and
	-- carries as a slam (keepers hear it as far).
	Ease = { Gain = 0.6, Pitch = 1, Reach = 60 },
	Settle = { Gain = 0.2, Pitch = 0.92, Reach = 20 },
	Drop = { Gain = 0.9, Pitch = 1.22, Reach = 110 },
} :: { [Motion.Kind]: { Gain: number, Pitch: number, Reach: number } }

-- The roll is at full volume once the door moves at this fraction of its action's average speed;
-- slower than that (easing in and out, a lift from inside between heaves) it fades with the speed.
DoorSound.RollKnee = 1
-- The roll's pitch runs from Slow (barely moving) to Fast (at 2.5 times the average speed, a
-- curve's quickest point): a door speeding up sounds it.
DoorSound.RollPitchSlow = 0.9
DoorSound.RollPitchFast = 1.12

-- Seconds the roll takes to swell to a louder target, and to sink to a quieter one: quick enough
-- to track the heaves, slow enough that no frame-to-frame step clicks.
DoorSound.RollAttack = 0.03
DoorSound.RollRelease = 0.08

-- Camera shake (Shake trauma) for someone right beside a slam from fully open, and for its bounce.
-- Squared on screen: 0.75 gives a sharp jolt (0.6 measured too faint in Play: 0.3 degrees), a
-- bounce of 0.2 a faint second shiver.
DoorSound.SlamShake = 0.75
DoorSound.BounceShake = 0.2
-- A trapped keeper's blow (L-06b3d): the slam's boom, quieter and lower, a body's thump under it,
-- and a jolt for whoever is at the door (squared on screen: about a third of a slam's). Its burst
-- lands as a full slam's boom as it tears free, and hits the stop bolts hard at the top.
DoorSound.BangGain = 0.55
DoorSound.BangShake = 0.45
DoorSound.BurstTopShake = 0.35
-- The shake reaches everyone within Near studs in full (inside the unit, or at its door) and
-- fades to nothing by Reach (a few units down the hall).
DoorSound.ShakeNear = 6
DoorSound.ShakeReach = 30

-- A cue this late (seconds) is still played, at once; any later and it's skipped. Covers the
-- network's delay without a door that streamed in replaying a bang from long ago.
DoorSound.LateCue = 0.25

-- A door counts as shut below this rise (studs), so lifting it slides the latch first.
local SHUT = 0.05

local function clamp01(x: number): number
	return if x < 0 then 0 elseif x > 1 then 1 else x
end

local function cue(at: number, sound: SoundName, gain: number, pitch: number, shake: number?): Cue
	return { at = at, sound = sound, gain = gain, pitch = pitch, shake = shake or 0 }
end

local function byTime(a: Cue, b: Cue): boolean
	return a.at < b.at
end

-- The one-shots of a door motion, in time order.
function DoorSound.cues(kind: Motion.Kind, from: number, to: number, fullStroke: number): { Cue }
	if kind == "Rattle" then
		return { cue(0, "Rattle", 1, 1) }
	elseif kind == "Bang" then
		return {
			cue(0, "Bang", DoorSound.BangGain, 0.82, DoorSound.BangShake),
			cue(0, "Thump", 0.8, 0.62),
		}
	end
	local cues: { Cue } = {}
	if kind == "Burst" then
		-- the blow that tears it free, as hard as a slam
		table.insert(cues, cue(0, "Bang", 1, 0.78, DoorSound.SlamShake))
		table.insert(cues, cue(0, "Thump", 1, 0.6))
	end
	if from < SHUT and to > from then
		-- the latch slides as the door breaks away; quietly for a peek
		table.insert(cues, cue(0, "Latch", if kind == "Peek" then 0.45 else 1, 1))
	end
	for _, strike in Motion.strikes(kind, from, to, fullStroke) do
		local s = strike.strength
		if strike.what == "Floor" and (kind == "Slam" or kind == "Drop") then
			table.insert(cues, cue(strike.at, "Bang", s, 1, DoorSound.SlamShake * s))
			table.insert(cues, cue(strike.at, "Thump", s, 0.74))
		elseif strike.what == "Bounce" then
			table.insert(cues, cue(strike.at, "Clatter", 0.75 * s, 1, DoorSound.BounceShake * s))
		elseif strike.what == "Floor" and kind == "Settle" then
			-- the tap hit (S2-05a): set down on the concrete, a touch you hear only standing there
			table.insert(cues, cue(strike.at, "Thump", 0.12, 0.85))
		elseif strike.what == "Floor" then
			-- pulled down by hand: it settles with a rattle, no bang
			table.insert(cues, cue(strike.at, "Clatter", 0.8, 0.9))
			table.insert(cues, cue(strike.at, "Thump", 0.25, 0.9))
		elseif strike.what == "Top" and kind == "Burst" then
			table.insert(cues, cue(strike.at, "Bang", 0.6, 1.1, DoorSound.BurstTopShake))
			table.insert(cues, cue(strike.at, "Clatter", 0.8, 1))
		elseif strike.what == "Top" then
			table.insert(cues, cue(strike.at, "Thump", 0.35, 1.2))
		end
	end
	table.sort(cues, byTime)
	return cues
end

-- The one-shots of locking (the bolt shoots, then the padlock snaps shut), quiet; or of the
-- padlock coming off, which only bolt cutters do: the jaw's snap, the padlock hitting the floor
-- a moment later, then the bolt slid back. A jolt for whoever's right at the door.
DoorSound.CutShake = 0.18
function DoorSound.lockCues(locked: boolean): { Cue }
	if locked then
		return { cue(0, "Latch", 0.8, 1.05), cue(0.32, "PadlockShut", 1, 1) }
	end
	return {
		cue(0, "Snap", 1, 1, DoorSound.CutShake),
		cue(0.2, "PadlockFall", 1, 1), -- as it lands (DoorView throws it)
		cue(0.55, "Latch", 0.6, 0.95),
	}
end

--[[
	The roll's volume (before the Roll sound's own Volume) and pitch at `elapsed` seconds into a
	motion. Silent when the door isn't moving.
]]
function DoorSound.roll(
	kind: Motion.Kind,
	from: number,
	to: number,
	elapsed: number,
	fullStroke: number
): (number, number)
	local action = DoorSound.Actions[kind]
	local dur = Motion.duration(kind, from, to, fullStroke)
	if action.Gain <= 0 or dur <= 0 or elapsed < 0 or elapsed >= dur then
		return 0, action.Pitch
	end
	local pace = Motion.speed(kind, from, to, elapsed, fullStroke) / (math.abs(to - from) / dur)
	local volume = action.Gain * clamp01(pace / DoorSound.RollKnee)
	local fast = clamp01(pace / 2.5)
	local pitch = action.Pitch
		* (DoorSound.RollPitchSlow + (DoorSound.RollPitchFast - DoorSound.RollPitchSlow) * fast)
	return volume, pitch
end

return DoorSound
