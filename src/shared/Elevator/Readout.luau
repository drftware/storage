--!strict
--[[
	What the keypad's readout shows (L-05b1c): four red LED digits of seven segments each, as a
	real door keypad has. Pure, so Lune checks it; LedReadout draws it on the wall (ElevatorView)
	and on the screen keypad (KeypadPad), so the two always agree.

	At rest each cell shows a dim dash, the middle bar lit low. A digit lights red the moment it's
	punched. A wrong code blinks its digits, and the status light with them, for as long as the
	alarm rings; the right code turns them green and they stay green. Unlit segments still show
	faintly, as a real LED's do under its glass.
]]
local Keypad = require("./Keypad")

-- How a cell (or the status light) is lit: not at all (only the faint unlit segments), the dim
-- red of a dash at rest, the bright red of a punched digit, or the green of the right code.
export type Tone = "Off" | "Rest" | "Lit" | "Right"

local Readout = {}

-- The seven segments in the usual order: a top, b top right, c bottom right, d bottom, e bottom
-- left, f top left, g the middle bar.
Readout.Segments = 7

-- Seconds each half of the wrong code's blink lasts, on then off: a quick, alarmed flash, in step
-- with the bell, that still reads as the digits you got wrong.
Readout.BlinkSeconds = 0.2

local LIT: { [string]: string } = {
	["0"] = "abcdef",
	["1"] = "bc",
	["2"] = "abdeg",
	["3"] = "abcdg",
	["4"] = "bcfg",
	["5"] = "acdfg",
	["6"] = "acdefg",
	["7"] = "abc",
	["8"] = "abcdefg",
	["9"] = "abcdfg",
	["-"] = "g",
	[" "] = "",
}

-- Each character's segments, worked out once: lit or not, a to g.
local PATTERNS: { [string]: { boolean } } = {}
for char, lit in LIT do
	local p = table.create(Readout.Segments, false)
	for i = 1, Readout.Segments do
		p[i] = string.find(lit, string.char(96 + i), 1, true) ~= nil
	end
	PATTERNS[char] = table.freeze(p)
end

-- Which of the seven segments `char` lights (a digit, "-" or " "; anything else is blank). The
-- table is shared and frozen: read it, never keep or change it.
function Readout.pattern(char: string): { boolean }
	return PATTERNS[char] or PATTERNS[" "]
end

-- Whether the wrong code's blink is on `since` seconds after the alarm started: on first.
local function blinkOn(since: number): boolean
	return math.floor(math.max(since, 0) / Readout.BlinkSeconds) % 2 == 0
end

-- Cell `i` (1 to Keypad.Length) for a keypad in `state`, `since` seconds after its last event:
-- the character it shows and how it's lit.
function Readout.cell(state: Keypad.State, i: number, since: number): (string, Tone)
	local typed = state.typed
	if i > #typed then
		return "-", "Rest"
	end
	local char = string.sub(typed, i, i)
	if state.event == "Right" then
		return char, "Right"
	elseif state.event == "Wrong" then
		return char, if blinkOn(since) then "Lit" else "Off"
	end
	return char, "Lit"
end

-- The keypad's status light: red, green once the code is right, blinking with the digits while
-- the alarm rings.
function Readout.light(state: Keypad.State, since: number): Tone
	if state.event == "Right" then
		return "Right"
	elseif state.event == "Wrong" then
		return if blinkOn(since) then "Lit" else "Off"
	end
	return "Lit"
end

-- Whether a keypad in `state` changes by itself from frame to frame (the wrong code's blink), so
-- a screen steps it; otherwise it changes only when its state does.
function Readout.blinking(state: Keypad.State): boolean
	return state.event == "Wrong"
end

-- Whether the keypad takes presses in `state`: not while the alarm rings, nor once it's opened
-- the gate. The server decides; a screen uses this to show its keys dead.
function Readout.live(state: Keypad.State): boolean
	return state.event ~= "Wrong" and state.event ~= "Right"
end

return Readout
