--!strict
-- lune run tests/readout.spec
-- The keypad's readout and status light (L-05b1c): each digit lights the right segments, a dash
-- only the middle bar; at rest every cell shows a dim dash, punched digits light red, a wrong code
-- blinks (on first) with the light, the right one goes green and stays. The cells always spell
-- what the keypad's rules say it shows, and only the wrong code needs stepping.
local Keypad = require("../src/shared/Elevator/Keypad")
local Readout = require("../src/shared/Elevator/Readout")

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

local function lit(char: string): string
	local out = ""
	for i, on in Readout.pattern(char) do
		if on then
			out ..= string.char(96 + i)
		end
	end
	return out
end

local function state(event: Keypad.Event, typed: string): Keypad.State
	return { count = 1, event = event, typed = typed }
end

-- The segments
ok(lit("8") == "abcdefg", "8 lights every segment")
ok(lit("1") == "bc", `1 lights the right side only, got {lit("1")}`)
ok(lit("7") == "abc", `7 is the top and the right side, got {lit("7")}`)
ok(lit("0") == "abcdef", "0 is everything but the middle bar")
ok(lit("-") == "g", `a dash is the middle bar alone, got {lit("-")}`)
ok(lit(" ") == "" and lit("x") == "", "a blank or unknown character lights nothing")
do
	local seen: { [string]: string } = {}
	for d = 0, 9 do
		local p = lit(tostring(d))
		ok(#Readout.pattern(tostring(d)) == Readout.Segments, `{d} has seven segments`)
		ok(seen[p] == nil, `{d} looks unlike {seen[p] or "any other digit"}`)
		seen[p] = tostring(d)
	end
	ok(table.isfrozen(Readout.pattern("5")), "a pattern is shared, so it's frozen")
end

-- The cells spell what the keypad shows, at rest and mid-code
for _, typed in { "", "7", "72", "724", "7241" } do
	local s = state("Press", typed)
	local spelled = ""
	for i = 1, Keypad.Length do
		local char, tone = Readout.cell(s, i, 0)
		spelled ..= char
		if i <= #typed then
			ok(tone == "Lit", `"{typed}": cell {i} is a punched digit, lit red`)
		else
			ok(tone == "Rest", `"{typed}": cell {i} is a dim dash`)
		end
	end
	local readout = string.gsub(Keypad.readout(typed), " ", "")
	ok(spelled == readout, `"{typed}" spells {spelled}, the rules say {readout}`)
end
do
	local rest = Keypad.decode(nil)
	for i = 1, Keypad.Length do
		local char, tone = Readout.cell(rest, i, 99)
		ok(char == "-" and tone == "Rest", `at rest cell {i} is a dim dash`)
	end
	ok(Readout.light(rest, 0) == "Lit", "at rest the status light is red")
	ok(not Readout.blinking(rest) and Readout.live(rest), "at rest it's still and takes presses")
end

-- The wrong code blinks, on first, in step with the light; the right one goes green and stays
do
	local wrong = state("Wrong", "0000")
	local b = Readout.BlinkSeconds
	for _, t in { 0, b * 0.5, b * 2.2, b * 4.9 } do
		local _, tone = Readout.cell(wrong, 3, t)
		ok(tone == "Lit", `wrong: lit at {t} s`)
		ok(Readout.light(wrong, t) == "Lit", `wrong: the light is on at {t} s`)
	end
	for _, t in { b * 1.1, b * 3.5 } do
		local char, tone = Readout.cell(wrong, 3, t)
		ok(tone == "Off" and char == "0", `wrong: dark at {t} s, still the digit`)
		ok(Readout.light(wrong, t) == "Off", `wrong: the light is off at {t} s`)
	end
	ok(Readout.blinking(wrong) and not Readout.live(wrong), "wrong: stepped, keys dead")

	local right = state("Right", "5062")
	for i = 1, Keypad.Length do
		local char, tone = Readout.cell(right, i, 7)
		ok(tone == "Right" and char == string.sub("5062", i, i), `right: cell {i} green`)
	end
	ok(Readout.light(right, 0.3) == "Right", "right: the light is green")
	ok(not Readout.blinking(right) and not Readout.live(right), "right: still, and done")
	ok(Readout.live(state("Clear", "")), "a clear takes presses")
end

print(`{checks - failures}/{checks} readout checks passed`)
if failures > 0 then
	error(`{failures} readout checks failed`)
end
