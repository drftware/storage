--!strict
--[[
	The freight elevator's sounds and when they play (L-05b1c). Pure, so Lune checks the timing;
	ElevatorView plays them on every player's screen.

	The keypad: a beep for every press, heard by anyone near (every beep is noise, GDD). A wrong
	code buzzes, then the elevator's alarm bell rings across the floor for as long as the keypad is
	dead, fading as it clears. The right code double-dings; the latch lets go; then the gate's fold
	ratchets faster and faster into its slam, which lands the instant the gate hits the stack.

	Every recording is Pro Sound Effects from Roblox's licensed library, so it loads in any game.
	Start and Stop pick the stretch to play; they were found by measuring each recording's loudness
	in Studio (docs/STUDIO.md, "The keypad's sounds, measured").
]]
local Gate = require("./Gate")
local Keypad = require("./Keypad")

export type SoundName = "Beep" | "Buzzer" | "Bell" | "Ding" | "Latch" | "Fold"
-- Where a sound comes from: the keypad's face, or the middle of the gate.
export type Source = "Keypad" | "Gate"

export type Sound = {
	Id: string,
	Source: Source,
	Start: number, -- seconds into the recording where its stretch starts
	Stop: number, -- and where it ends
	Fade: number, -- seconds it fades out over before Stop, so a cut never clicks
	Volume: number,
	Near: number, -- full volume within this many studs
	Reach: number, -- silent beyond this many studs
	Timed: boolean, -- keeps its place in time: a late start skips ahead so its slam still lands
}

export type Cue = {
	at: number, -- seconds after the keypad's event, or after the gate starts moving (can be < 0)
	sound: SoundName,
	from: number, -- seconds into the recording it plays from
	pitch: number,
}

local Sounds = {}

-- The fold's recording is silent to here, then ratchets up to its slam at `FoldSlam` (seconds).
Sounds.FoldQuiet = 0.6
Sounds.FoldSlam = 2.2

-- Seconds after a code's last beep that its verdict sounds: the beep first, then the answer.
Sounds.VerdictAfter = 0.12
-- Seconds after a wrong code that the bell starts, over the buzzer's tail: a buzz, then the alarm.
Sounds.BellAfter = 0.4
-- Where in the bell's recording it starts: just before it rings up, so it swells in.
Sounds.BellFrom = 0.15
-- Seconds before the gate moves that the latch lets go: its clack lands as the gate starts.
Sounds.LatchLead = 0.3
-- The clear key's beep, a little lower than a digit's, so a wipe sounds unlike a press.
Sounds.ClearPitch = 0.84
-- A gate this shut (or more) is latched: opening it lets the latch go, shutting it catches.
Sounds.Latched = 0.999
-- The jolt to a player right beside the gate as it slams (Shake trauma; a door's slam is 0.75 and
-- the gate is lighter), fading from `ShakeNear` studs to nothing at `ShakeReach`.
Sounds.SlamShake = 0.5
Sounds.ShakeNear = 5
Sounds.ShakeReach = 24
-- A cue this late (seconds) still plays, at once; any later and it's skipped, so an elevator
-- streaming in never replays a slam from long ago.
Sounds.LateCue = 0.25

Sounds.Sounds = {
	-- A keypad's beep (one short blip).
	Beep = {
		Id = "rbxassetid://9114642536",
		Source = "Keypad",
		Start = 0,
		Stop = 0.22,
		Fade = 0.04,
		Volume = 0.7,
		Near = 5,
		Reach = Keypad.Heard.Press,
		Timed = false,
	},
	-- The wrong code's buzz (a short burst).
	Buzzer = {
		Id = "rbxassetid://9113085665",
		Source = "Keypad",
		Start = 0,
		Stop = 0.45,
		Fade = 0.08,
		Volume = 0.8,
		Near = 8,
		Reach = 60,
		Timed = false,
	},
	-- The elevator's alarm bell, heard across the floor. It rings for as long as the keypad is
	-- dead, fading out as it clears.
	Bell = {
		Id = "rbxassetid://9125544264",
		Source = "Keypad",
		Start = Sounds.BellFrom,
		Stop = Sounds.BellFrom + Keypad.AlarmSeconds - Sounds.BellAfter,
		Fade = 1,
		Volume = 1,
		Near = 24,
		Reach = Keypad.Heard.Wrong,
		Timed = false,
	},
	-- The right code's double-ding. The recording is about 30 dB under the others, hence the
	-- volume near the top of Roblox's range; it rings down 18 dB by 2.6 s, faded out over the end.
	Ding = {
		Id = "rbxassetid://9119642644",
		Source = "Keypad",
		Start = 0,
		Stop = 2.6,
		Fade = 0.9,
		Volume = 8,
		Near = 6,
		Reach = Keypad.Heard.Right,
		Timed = false,
	},
	-- The gate's latch letting go (the doors' latch: a big metal bar, jiggled).
	Latch = {
		Id = "rbxassetid://9117910424",
		Source = "Gate",
		Start = 0.22,
		Stop = 0.9,
		Fade = 0.15,
		Volume = 1.6,
		Near = 6,
		Reach = 45,
		Timed = false,
	},
	-- The gate folding: a ratchet that gathers speed into a slam.
	Fold = {
		Id = "rbxassetid://9117907728",
		Source = "Gate",
		Start = 0,
		Stop = 3.3,
		Fade = 0.5,
		Volume = 1,
		Near = 8,
		Reach = 80,
		Timed = true,
	},
} :: { [SoundName]: Sound }

local function cue(at: number, sound: SoundName, from: number?, pitch: number?): Cue
	return { at = at, sound = sound, from = from or Sounds.Sounds[sound].Start, pitch = pitch or 1 }
end

-- The beep of a press of `key` on the keypad, at once.
function Sounds.press(key: Keypad.Key): Cue
	return cue(0, "Beep", nil, if key == "Clear" then Sounds.ClearPitch else 1)
end

--[[
	The keypad's sounds for its `event`, from the moment the event arrives. `pressed` says whether
	the press that made it still needs its beep: true when someone else pressed (their screen beeped
	already, this one hasn't), false when it's this player's own press echoed back.
]]
function Sounds.keypad(event: Keypad.Event, pressed: boolean): { Cue }
	local cues: { Cue } = {}
	if pressed and event ~= "Rest" then
		table.insert(cues, Sounds.press(if event == "Clear" then "Clear" else 0))
	end
	if event == "Wrong" then
		table.insert(cues, cue(Sounds.VerdictAfter, "Buzzer"))
		table.insert(cues, cue(Sounds.BellAfter, "Bell"))
	elseif event == "Right" then
		table.insert(cues, cue(Sounds.VerdictAfter, "Ding"))
	end
	return cues
end

-- Where to start the fold's recording, and how long after the gate starts to start it, so its
-- slam lands as a gate travelling `seconds` hits.
function Sounds.foldStart(seconds: number): (number, number)
	local from = Sounds.FoldSlam - seconds
	if from >= 0 then
		return from, 0
	end
	return 0, -from
end

--[[
	The gate's sounds for a motion from `from` to `to` (how far shut, 0 to 1), timed from when it
	starts moving: opening from latched lets the latch go first; the fold plays so its slam lands
	on the gate's; shutting all the way catches the latch as it slams. (The slam's jolt is the
	screen's, on the frame the gate hits.)
]]
function Sounds.gate(from: number, to: number): { Cue }
	local cues: { Cue } = {}
	if from == to then
		return cues
	end
	local seconds = Gate.duration(from, to)
	if to < from and from >= Sounds.Latched then
		table.insert(cues, cue(-Sounds.LatchLead, "Latch"))
	end
	local start, wait = Sounds.foldStart(seconds)
	table.insert(cues, cue(wait, "Fold", start))
	if to > from and to >= Sounds.Latched then
		table.insert(cues, cue(seconds, "Latch"))
	end
	return cues
end

return Sounds
