--!strict
--[[
	The freight elevator's keypad, its rules alone (GDD "Codes, the elevator and the roof"). It
	takes one digit at a time and every beep is noise; the code is checked the moment the fourth
	digit goes in. A wrong code sets off the alarm; the right one opens the gate. Pure, so Lune
	checks it: the server's Elevators runs it and every player's screen draws it (ElevatorView,
	KeypadPad).

	The keypad is shared, as a real one is: one readout for the whole team, so you can punch the
	first three digits while a friend runs back with the last. Its state crosses the wire as one
	replicated value on the elevator (`Attribute`), counted so the same press twice still shows.
]]

export type Event = "Rest" | "Press" | "Clear" | "Wrong" | "Right"
export type Key = number | "Clear" -- a digit 0 to 9, or the clear key

export type State = {
	count: number, -- events so far: the same event twice still changes the value
	typed: string, -- the digits punched so far, "" to "7241"
	event: Event, -- what just happened
	digit: number?, -- the key that was pressed, for a Press
	by: number?, -- who pressed it (their UserId), for a press or a clear: their screen already beeped
}

local Keypad = {}

Keypad.Attribute = "Keypad"
-- The remote a press travels on: ReplicatedStorage.Remotes.Keypad, made by the server's
-- Elevators; its payload is the elevator, then a digit or "Clear".
Keypad.RemoteFolder = "Remotes"
Keypad.RemoteName = "Keypad"
-- Digits in a code.
Keypad.Length = 4
-- Studs from the keypad's face a press counts from. The prompt shows nearer (`PromptReach`); the
-- rest is slack for lag and for typing while you back away.
Keypad.Reach = 9
Keypad.PromptReach = 6
-- The fastest a thumb presses, in seconds: twelve presses a second. Anything faster is a script.
Keypad.PressSeconds = 0.08
-- After a wrong code the keypad is dead this long, its readout blinking the wrong digits while
-- the alarm rings, then it clears for another try: long enough to sting, short enough to retry
-- before whatever heard the alarm arrives.
Keypad.AlarmSeconds = 3.5
-- How far each sound carries, in studs: the radius a keeper hears it from (L-06b), as Doors'
-- `acted` reach does. Every beep is noise (GDD); the alarm reaches the whole floor.
Keypad.Heard = {
	Press = 30,
	Clear = 30,
	Wrong = 400,
	Right = 60,
}

-- Whether `key` is a key the keypad has: a whole number 0 to 9, or "Clear".
function Keypad.isKey(key: unknown): boolean
	if key == "Clear" then
		return true
	end
	return type(key) == "number" and key == key and key >= 0 and key <= 9 and key % 1 == 0
end

-- Whether `code` is a floor's code: Length whole numbers 0 to 9.
function Keypad.isCode(code: unknown): boolean
	if type(code) ~= "table" then
		return false
	end
	local t = code :: { [unknown]: unknown }
	if #t ~= Keypad.Length then
		return false
	end
	for i = 1, Keypad.Length do
		local d = t[i]
		if d == "Clear" or not Keypad.isKey(d) then
			return false
		end
	end
	return true
end

--[[
	Punches `digit` into a keypad showing `typed`, for a floor whose code is `code` (nil: no code
	yet, so nothing opens it). Returns what it shows next and, on the last digit, the verdict:
	the digits stay up for the verdict to show; the caller clears them after.
]]
function Keypad.enter(typed: string, digit: number, code: { number }?): (string, Event?)
	if #typed >= Keypad.Length then
		typed = ""
	end
	local now = typed .. tostring(digit)
	if #now < Keypad.Length then
		return now, nil
	end
	local right = code ~= nil and now == table.concat(code)
	return now, if right then "Right" else "Wrong"
end

-- The readout's text: the digits punched so far and a dash for each still to come, spaced so
-- each sits in its cell. "- - - -" at rest, "7 2 - -" mid-code.
function Keypad.readout(typed: string): string
	local cells = table.create(Keypad.Length, "-")
	for i = 1, math.min(#typed, Keypad.Length) do
		cells[i] = string.sub(typed, i, i)
	end
	return table.concat(cells, " ")
end

local EVENTS: { [string]: Event } =
	{ Rest = "Rest", Press = "Press", Clear = "Clear", Wrong = "Wrong", Right = "Right" }

-- The state as its replicated value.
function Keypad.encode(state: State): string
	return string.format(
		"%d;%s;%s;%s;%s",
		state.count,
		state.event,
		state.typed,
		if state.digit then tostring(state.digit) else "",
		if state.by then tostring(state.by) else ""
	)
end

-- The state from its replicated value. A missing or broken value is a keypad at rest.
function Keypad.decode(value: unknown): State
	if type(value) == "string" then
		local count, event, typed, digit, by =
			string.match(value, "^(%d+);(%a+);(%d*);(%d?);(%-?%d*)$")
		local n = tonumber(count)
		local e: Event? = if event then EVENTS[event] else nil
		if n and e and typed and #typed <= Keypad.Length then
			return {
				count = n,
				typed = typed,
				event = e,
				digit = tonumber(digit),
				by = tonumber(by),
			}
		end
	end
	return { count = 0, typed = "", event = "Rest" }
end

return Keypad
