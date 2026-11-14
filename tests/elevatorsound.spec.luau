--!strict
-- lune run tests/elevatorsound.spec
-- The freight elevator's sounds (L-05b1c): someone else's press beeps here, your own echo doesn't;
-- a wrong code buzzes, then the bell rings exactly as long as the keypad is dead; the right one
-- dings, the latch lets go before the gate moves, and the fold's slam lands the instant the gate
-- hits, whatever distance it travels. Every stretch is a real stretch of its recording.
local Gate = require("../src/shared/Elevator/Gate")
local Keypad = require("../src/shared/Elevator/Keypad")
local Sounds = require("../src/shared/Elevator/Sounds")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		if failures <= 30 then
			print("FAIL " .. what)
		end
	end
end
local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end

local function names(cues: { Sounds.Cue }): string
	local list = {}
	for _, c in cues do
		table.insert(list, c.sound)
	end
	return table.concat(list, ",")
end

local function inOrder(cues: { Sounds.Cue }): boolean
	for i = 2, #cues do
		if cues[i].at < cues[i - 1].at then
			return false
		end
	end
	return true
end

-- The rows
for name, row in Sounds.Sounds do
	ok(string.match(row.Id, "^rbxassetid://%d+$") ~= nil, `{name}: a library id`)
	ok(row.Stop > row.Start and row.Start >= 0, `{name}: its stretch runs forward`)
	ok(row.Fade >= 0 and row.Fade <= row.Stop - row.Start, `{name}: fades inside its stretch`)
	ok(row.Volume > 0 and row.Volume <= 10, `{name}: a volume Roblox plays`)
	ok(row.Reach > row.Near and row.Near > 0, `{name}: heard farther than it's loud`)
end
ok(Sounds.Sounds.Beep.Reach == Keypad.Heard.Press, "a beep carries as far as keepers hear it")
ok(Sounds.Sounds.Bell.Reach == Keypad.Heard.Wrong, "the bell carries as far as keepers hear it")
ok(Sounds.Sounds.Fold.Timed and not Sounds.Sounds.Beep.Timed, "only the fold keeps its time")

-- The keypad
ok(names(Sounds.keypad("Press", true)) == "Beep", "someone else's press beeps here")
ok(#Sounds.keypad("Press", false) == 0, "your own press's echo is silent: it beeped already")
ok(#Sounds.keypad("Rest", true) == 0, "the keypad clearing after the alarm is silent")
do
	local clear = Sounds.keypad("Clear", true)
	ok(names(clear) == "Beep" and clear[1].pitch == Sounds.ClearPitch, "a clear beeps lower")
	ok(Sounds.press("Clear").pitch < Sounds.press(4).pitch, "the clear key beeps under a digit")
	ok(Sounds.press(4).at == 0, "a press beeps at once")

	local wrong = Sounds.keypad("Wrong", true)
	ok(
		names(wrong) == "Beep,Buzzer,Bell,Bell,Bell,Bell" and inOrder(wrong),
		`wrong: beep, buzz, then the bell struck for the longest lock ({names(wrong)})`
	)
	ok(
		names(Sounds.keypad("Wrong", false)) == "Buzzer,Bell,Bell,Bell,Bell",
		"your wrong code: buzz, bell"
	)
	local bell = Sounds.Sounds.Bell
	local ring = bell.Stop - bell.Start
	-- every lock is whole rings, and a strike's clang ends just as the keypad clears
	for nth = 1, 4 do
		local dead = Keypad.dead(nth)
		local strikes = 0
		local last = 0
		for _, c in wrong do
			if c.sound == "Bell" and c.at < dead then
				strikes += 1
				last = math.max(last, c.at + ring)
			end
		end
		ok(near(last, dead), `wrong code {nth}: the last strike rings out as the keypad clears`)
		ok(strikes == math.round(dead / Keypad.Dead[1]), `wrong code {nth}: {strikes} strikes`)
	end
	ok(Keypad.dead(1) < Keypad.dead(2) and Keypad.dead(2) < Keypad.dead(3), "each lock is longer")
	ok(Keypad.dead(9) == Keypad.dead(3), "the third lock holds for every one after")
	ok(Sounds.BellAfter > Sounds.VerdictAfter, "the buzz comes before the bell")

	local right = Sounds.keypad("Right", true)
	ok(names(right) == "Beep,Ding" and inOrder(right), `right: beep, then ding ({names(right)})`)
	ok(right[2].at > 0, "the ding waits for the last beep")
end

-- The gate
ok(
	near(Sounds.FoldSlam - Sounds.FoldQuiet, Gate.OpenSeconds),
	"the fold's ratchet builds for exactly a whole open"
)
for _, seconds in { 0.05, 0.4, 1, Gate.OpenSeconds, Gate.ShutSeconds, 2.2, 3 } do
	local from, wait = Sounds.foldStart(seconds)
	ok(from >= 0 and wait >= 0, `{seconds} s: starts in the recording, never before the gate`)
	ok(near(wait + Sounds.FoldSlam - from, seconds), `{seconds} s: the slam lands as the gate hits`)
end
do
	local open = Sounds.gate(1, 0)
	ok(names(open) == "Latch,Fold" and inOrder(open), `a whole open: latch, fold ({names(open)})`)
	ok(
		open[1].at < 0 and -open[1].at < Gate.Delay,
		"the latch goes after the code, before the gate"
	)
	ok(Gate.Delay - Sounds.LatchLead > Sounds.VerdictAfter, "the ding comes before the latch")
	ok(open[2].at == 0 and near(open[2].from, Sounds.FoldQuiet), "the fold starts with the gate")

	ok(names(Sounds.gate(0.5, 0)) == "Fold", "a half-shut gate opens with no latch to let go")
	local shut = Sounds.gate(0, 1)
	ok(names(shut) == "Fold,Latch", `a whole shut: fold, latch ({names(shut)})`)
	ok(near(shut[2].at, Gate.duration(0, 1)), "shutting, the latch catches as it slams")
	ok(names(Sounds.gate(0, 0.6)) == "Fold", "stopping short of shut catches no latch")
	ok(#Sounds.gate(0.3, 0.3) == 0, "a gate going nowhere is silent")
end

print(`{checks - failures}/{checks} elevator sound checks passed`)
if failures > 0 then
	error(`{failures} elevator sound checks failed`)
end
