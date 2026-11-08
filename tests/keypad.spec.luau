--!strict
-- lune run tests/keypad.spec
-- The freight elevator's keypad and its gate moving (L-05b1a): the keypad takes one digit at a
-- time and checks the code on the fourth, a wrong code and no code never open it, the readout
-- shows dashes for what's still to come, its state survives the wire, and only real keys and
-- codes pass. The gate gathers speed into its slam, recoils a hair and settles exactly where it
-- was sent, its value survives the wire, and a reused pose matches a fresh one.
local Gate = require("../src/shared/Elevator/Gate")
local Keypad = require("../src/shared/Elevator/Keypad")

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

-- Punches `digits` in turn; returns what the readout shows and the verdict, if any.
local function punch(digits: string, code: { number }?, typed: string?): (string, string?)
	local shown, verdict = typed or "", nil
	for i = 1, #digits do
		shown, verdict = Keypad.enter(shown, tonumber(string.sub(digits, i, i)) :: number, code)
	end
	return shown, verdict
end

-- The keypad
local CODE = { 7, 2, 4, 1 }
do
	local shown, verdict = punch("724", CODE)
	ok(
		shown == "724" and verdict == nil,
		`three digits wait for the fourth (got {shown}, {verdict})`
	)
	shown, verdict = punch("7241", CODE)
	ok(shown == "7241" and verdict == "Right", "the right code is Right, its digits still showing")
	shown, verdict = punch("7242", CODE)
	ok(shown == "7242" and verdict == "Wrong", "a wrong last digit is Wrong")
	shown, verdict = punch("2741", CODE)
	ok(verdict == "Wrong", "the right digits in the wrong order are Wrong")
	shown, verdict = punch("7241", nil)
	ok(verdict == "Wrong", "with no code yet, nothing opens it")
	shown, verdict = punch("1", CODE, "7241")
	ok(shown == "1" and verdict == nil, "a digit after a full readout starts a new code")
	shown, verdict = punch("0000", { 0, 0, 0, 0 })
	ok(verdict == "Right", "zeros count as digits")
end

ok(Keypad.readout("") == "- - - -", `at rest the readout is dashes (got "{Keypad.readout("")}")`)
ok(Keypad.readout("72") == "7 2 - -", `mid-code: "{Keypad.readout("72")}"`)
ok(Keypad.readout("7241") == "7 2 4 1", "a full code fills every cell")

for d = 0, 9 do
	ok(Keypad.isKey(d), `{d} is a key`)
end
ok(Keypad.isKey("Clear"), "Clear is a key")
for _, bad: any in { -1, 10, 2.5, 0 / 0, math.huge, "7", "clear", true, {}, nil } do
	ok(not Keypad.isKey(bad), `{tostring(bad)} is not a key`)
end
ok(Keypad.isCode(CODE), "a four-digit code is a code")
for _, bad: any in
	{ { 1, 2, 3 }, { 1, 2, 3, 4, 5 }, { 1, 2, 3, 10 }, { 1, 2, "Clear", 4 }, "7241", nil }
do
	ok(not Keypad.isCode(bad), "not a code: a short, long, out-of-range or non-table code")
end

-- the state on the wire
do
	local states: { Keypad.State } = {
		{ count = 0, typed = "", event = "Rest" },
		{ count = 12, typed = "72", event = "Press", digit = 2, by = 123456789 },
		{ count = 13, typed = "7241", event = "Wrong", digit = 1, by = -1 },
		{ count = 14, typed = "", event = "Clear" },
		{ count = 15, typed = "7241", event = "Right", digit = 1, by = 9 },
	}
	for _, s in states do
		local back = Keypad.decode(Keypad.encode(s))
		ok(
			back.count == s.count
				and back.typed == s.typed
				and back.event == s.event
				and back.digit == s.digit
				and back.by == s.by,
			`{Keypad.encode(s)} survives the wire`
		)
	end
	for _, bad: any in { nil, 5, "", "x;Press;72;2;1", "3;Open;72;;", "3;Press;72345;;" } do
		local back = Keypad.decode(bad)
		ok(back.event == "Rest" and back.typed == "", `a broken value ({tostring(bad)}) is at rest`)
	end
end

-- The gate moving
ok(
	near(Gate.duration(1, 0), Gate.OpenSeconds) and near(Gate.duration(0, 1), Gate.ShutSeconds),
	"a whole fold takes OpenSeconds, a whole shut ShutSeconds"
)
ok(near(Gate.duration(1, 0.5), Gate.OpenSeconds / 2), "half a fold takes half as long")
ok(Gate.settles(1, 1) == 0, "a gate sent nowhere is already still")
for _, run in { { 1, 0 }, { 0, 1 }, { 0.6, 0.1 } } do
	local from, to = run[1], run[2]
	local d = Gate.duration(from, to)
	ok(
		Gate.at(from, to, -0.3) == from and Gate.at(from, to, 0) == from,
		"before it starts, it's at rest"
	)
	ok(near(Gate.at(from, to, d), to), `it reaches {to} at the end of its travel`)
	ok(Gate.at(from, to, Gate.settles(from, to)) == to, "it settles exactly where it was sent")
	ok(Gate.at(from, to, 99) == to, "and stays there")
	local last, lastStep = from, 0
	local gathering = true
	for i = 1, 40 do
		local x = Gate.at(from, to, d * i / 40)
		local step = math.abs(x - last)
		gathering = gathering and (to - from) * (x - last) >= 0 and step >= lastStep - 1e-9
		last, lastStep = x, step
	end
	ok(gathering, `from {from} to {to} it only gathers speed until it hits`)
	local recoil = 0
	for i = 1, 20 do
		local x = Gate.at(from, to, d + Gate.BounceSeconds * i / 21)
		recoil = math.max(recoil, math.abs(x - to))
		ok(
			x >= 0 and x <= 1 and (x - to) * (to - from) <= 0,
			"the recoil goes back the way it came"
		)
	end
	ok(
		recoil > 0 and recoil <= Gate.BounceShare * math.abs(to - from) + 1e-9,
		`it recoils a hair ({recoil})`
	)
end

do
	local from, to, start = Gate.decode(Gate.encode(1, 0, 12345.678))
	ok(
		from == 1 and to == 0 and near(start, 12345.678, 1e-3),
		"the gate's motion survives the wire"
	)
	from, to, start = Gate.decode(Gate.encode(0.25, 0.75, 9.5))
	ok(near(from, 0.25) and near(to, 0.75) and near(start, 9.5, 1e-3), "a part-way motion too")
	for _, bad: any in { nil, 7, "", "1,0", "a,b,c" } do
		from, to, start = Gate.decode(bad)
		ok(
			from == 1 and to == 1 and start == 0,
			`a broken value ({tostring(bad)}) is the gate shut`
		)
	end
end

-- a reused pose matches a fresh one, and keeps its tables
do
	local pose = Gate.pose(0)
	local pickets, straps, first = pose.Pickets, pose.Straps, pose.Straps[1]
	for _, shut in { 0.8, 0.13, 1, 0, 0.5 } do
		local fresh = Gate.pose(shut)
		local reused = Gate.pose(shut, pose)
		local same = reused == pose
			and reused.Pickets == pickets
			and reused.Straps == straps
			and reused.Straps[1] == first
			and near(reused.Pitch, fresh.Pitch)
			and near(reused.Angle, fresh.Angle)
			and #reused.Straps == #fresh.Straps
		for i, x in fresh.Pickets do
			same = same and near(reused.Pickets[i], x)
		end
		for i, s in fresh.Straps do
			local r = reused.Straps[i]
			same = same
				and near(r.X, s.X)
				and near(r.Y, s.Y)
				and near(r.Z, s.Z)
				and near(r.Angle, s.Angle)
		end
		ok(same, `a reused pose at {shut} matches a fresh one in its own tables`)
	end
end

print(`{checks - failures}/{checks} keypad checks passed`)
if failures > 0 then
	error(`{failures} keypad checks failed`)
end
