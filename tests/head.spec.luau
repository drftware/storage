--!strict
-- lune run tests/head.spec
-- A find on your head (F-G1b4a1, Finds/Head): the hard hat's word is Wear and it fits a head; it
-- has no switch off; its press is the shell's knock, then the lamp's click as its bulb lights;
-- the ground floor is the front office's room and the homes off it, never the climb.
local Head = require("../src/shared/Finds/Head")
local Rows = require("../src/shared/Finds/Rows")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- the hat's row, by its key
local hat = nil
for _, row in Rows do
	if row.key == "HardHat" then
		hat = row
	end
end
ok(hat ~= nil, "the hard hat has a row")
if hat then
	local press = hat.press
	ok(hat.verb == Head.Verb, "the hat's button says Wear")
	ok(press ~= nil and press.verb == Head.Verb, "its press is Wear")
	if press then
		ok(press.off == nil, "no switch off: on your head it burns its minute")
		ok(press.lasts == 60, "it lasts a minute off the ground floor")
		local on = press.on[1]
		ok(on ~= nil and on.motion == "SwitchOn", "it lights with its switch")
		ok(on ~= nil and on.sound ~= nil, "the shell's knock as it goes on")
		local cue = on and on.cues and on.cues[1]
		-- the switch flips over 0.06 to 0.16 s and the bulb lights from 0.155 (Sets/Lights)
		ok(cue ~= nil and cue.at >= 0.1 and cue.at <= 0.2, "the click lands as the switch flips")
	end
end

-- every worn find fits: grown to a head, sat into it, its front tipped only a little
local fit = Head.fit("HardHat")
ok(fit ~= nil, "the hard hat fits a head")
ok(Head.fit("CampLantern") == nil, "a lantern isn't worn")
for key, f in Head.Fits do
	ok(f.scale > 1 and f.scale < 2, `{key}: grown to a Roblox head, not a giant's`)
	ok(f.down > 0 and f.down < 0.8, `{key}: its rim below the top of the head`)
	ok(math.abs(f.tip) <= 15, `{key}: its front tipped a little at most`)
end

-- the ground floor: the room (120 across, 156 back), the homes off its walls; not the climb
local W, D = 120, 156
ok(Head.home(0, 3, -78, W, D), "the middle of the front office")
ok(Head.home(0, 3, -150, W, D), "the spawn at its back")
ok(Head.home(80, 3, -40, W, D), "inside a home off its side wall")
ok(not Head.home(-1600, 3, -1200, W, D), "the climb's floors are far off")
ok(not Head.home(0, 3, -400, W, D), "well past its back wall")
ok(not Head.home(0, 120, -78, W, D), "high over it")

-- your own eye (D-282): wholly hidden with the camera at your head, shown once it's well off,
-- fading smoothly between, and the fade lands on its goal without overshooting
ok(Head.hidden(0) == 1 and Head.hidden(0.5) == 1, "first person hides it wholly")
ok(Head.hidden(Head.HideFar) == 0 and Head.hidden(12) == 0, "a camera well off shows it")
local mid = Head.hidden((Head.HideNear + Head.HideFar) / 2)
ok(mid > 0.45 and mid < 0.55, "halfway out, half hidden")
local prev = 1
local steady = true
for d = Head.HideNear, Head.HideFar, 0.1 do
	local h = Head.hidden(d)
	steady = steady and h <= prev and h >= 0 and h <= 1
	prev = h
end
ok(steady, "the farther the camera, the less it hides")
local f = 0
for _ = 1, 10 do
	f = Head.fade(f, 1, 1 / 60)
	ok(f > 0 and f <= 1, "a fade in stays between shown and hidden")
end
ok(f > 0.8 and f < 1, "a sixth of a second in, nearly hidden but not popped")
for _ = 1, 60 do
	f = Head.fade(f, 1, 1 / 60)
end
ok(f == 1, "it lands on hidden")
ok(Head.fade(0.5, 0, 0) == 0.5, "no time, no change")

print(`head: {checks - failures}/{checks} passed`)
if failures > 0 then
	error(`{failures} failed`)
end
