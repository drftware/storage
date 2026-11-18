--!strict
-- lune run tests/homepress.spec
-- Every find set out in a home keeps its own button (S5-03i3, D-345, D-351): the climb's word
-- for its press (Switch, Play, Wind, Squeeze...), every find at once; a wind-up plays where it
-- stands; a press that needs the find in your hand, or only rolls it off, gets none.
local Drive = require("../src/shared/Finds/Drive")
local Head = require("../src/shared/Finds/Head")
local Press = require("../src/shared/Home/Press")
local Use = require("../src/shared/Finds/Use")

local failures, checks = 0, 0
local function ok(cond: boolean, what: string)
	checks += 1
	if not cond then
		failures += 1
		print("FAIL " .. what)
	end
end

-- The owner's lamp and the others: the climb's own word.
do
	ok(Press.verb("MoonLamp") == "Switch", "the moon lamp switches")
	ok(Press.verb("DeskLamp") == "Switch", "the desk lamp switches")
	ok(Press.verb("Boombox") == "Play", "the boombox plays")
	ok(Press.verb("Teddy") == "Hug", "the teddy is hugged")
	ok(Press.verb("RubberDuck") == "Squeeze", "the duck is squeezed")
	ok(Press.verb("JackInTheBox") == "Wind", "the jack is wound")
	ok(Press.verb("TeaLight") == "Light", "the tea light is lit")
end

-- None where the press needs your hand or only sends the find off, or there's no press at all.
do
	ok(Press.verb(Drive.Key) == nil, "the RC car's Drive needs its transmitter in hand")
	ok(Press.verb("HardHat") == nil, "Wear needs it in your hand")
	ok(Press.verb("DiecastCar") == nil, "a push that rolls it off would stop dead")
	ok(Press.verb("UnpluggedLamp") == nil, "the lamp found lit has no press")
	ok(Press.verb("Nope") == nil, "an unknown find has none")
	ok(Press.verb("EndTable:Furniture#1") == nil, "furniture has none")
end

-- Every find at once: each press row gets its button but the few above.
do
	local shown, without = 0, 0
	for key, row in Use.Rows do
		local verb = Press.verb(key)
		local hand = key == Drive.Key or row.verb == Head.Verb or (row.down and not row.walks)
		if hand then
			without += 1
			ok(verb == nil, `{key}: no button at home`)
		else
			shown += 1
			ok(verb == row.verb, `{key}: its climb word, {row.verb}`)
		end
	end
	ok(shown >= 30, `most finds get a button ({shown})`)
	ok(without <= 4, `only the few need a hand ({without})`)
end

-- A wind-up walks on where it stands; the rest play as they would anywhere.
do
	local mouse = Press.row("WindupMouse")
	ok(mouse ~= nil and Press.stop(mouse) == 0, "the wind-up mouse is stopped where it stands")
	if mouse then
		local elapsed, travel = Use.played(mouse, 2, Press.stop(mouse))
		ok(elapsed == 2 and travel == 0, "it plays on, going nowhere")
	end
	local lamp = Press.row("MoonLamp")
	ok(lamp ~= nil and Press.stop(lamp) == nil, "a lamp isn't stopped")
end

-- At home a light switched on never runs down; a toy's play is its own length.
do
	local lamp = Press.row("MoonLamp")
	if lamp then
		local state, left = Use.press(lamp, nil, 0, {})
		ok(state == "On", "the first press switches it on")
		ok(Use.home(lamp, state :: Use.State, left) == Use.Forever, "lit for good at home")
	else
		ok(false, "the moon lamp has a press")
	end
	local duck = Press.row("RubberDuck")
	if duck then
		local state, left = Use.press(duck, nil, 0, {})
		ok(state ~= nil and Use.home(duck, state :: Use.State, left) == left, "a toy plays as long")
	else
		ok(false, "the duck has a press")
	end
end

-- Only a player in the home sees and presses: inside its walls or in its doorway, not next door.
do
	ok(Press.inside(0, 0, 10, 14.9), "the middle of the room")
	ok(Press.inside(9.5, -14.5, 10, 14.9), "a front corner")
	ok(Press.inside(0, -15.9, 10, 14.9), "in the doorway")
	ok(not Press.inside(0, -18, 10, 14.9), "out in the hall")
	ok(not Press.inside(11, 0, 10, 14.9), "through the wall, next door")
end

print(`homepress: {checks - failures}/{checks} checks passed`)
if failures > 0 then
	error(`{failures} failed`)
end
