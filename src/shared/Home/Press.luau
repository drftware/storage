--!strict
--[[
	Press: a find set out in a home keeps its own button (S5-03i3, D-345, D-351). The moment: you
	buy an end table, stand your lamp on it, walk up and press Switch, and the corner glows; a
	friend over at yours squeezes the duck on your crate and it squeaks.

	Each find set out shows the word of its climb press (its `Finds/Use` row: Switch, Play, Wind,
	Squeeze...), every find at once, as Animal Crossing's lamps and Bloxburg's switch where they
	stand. Every screen in the home shows it, a friend's too: a friend may press, never move or take
	(D-345; Animal Crossing's visitors use your things but don't pick them up). The press plays as
	it does in a hand, and at home a light never runs down (D-259, `Use.home`).

	A wind-up whose press sets it down to walk (the wind-up mouse, the chattering teeth) plays on
	where it stands, as one stopped by a wall does on a climb (`stop`). A press that only makes
	sense away from where it stands gets no button here, so Take it first: one that rolls the find
	off (the diecast car's Push, which would just stop dead), Wear (it goes on your head) and the
	RC car's Drive (the find is its transmitter).

	Pure: Lune tests it (tests/homepress.spec).
]]
local Drive = require("../Finds/Drive")
local Head = require("../Finds/Head")
local Use = require("../Finds/Use")

local Press = {}

-- Studs: how near you stand to press a find set out, as near as to take it (`Take.Reach`).
-- What it does to the player: walk up to the lamp and its Switch is there.
Press.Reach = 8
-- Studs past it the server allows, for a screen a beat behind (`Take.Slack`).
Press.Slack = 3
-- Pixels between a find's two buttons when both show (its press left, Take right), a button's
-- width, as a ladder's Take sits beside its Climb.
Press.Side = 150
-- Studs past the room's front a player still counts as in the home: standing in its doorway.
-- What it does to the player: a neighbour through the wall never sees your lamp's Switch.
Press.Doorway = 1.5
-- On a home's folder of finds set out (Arranging): the room's middle on the floor (a CFrame,
-- looking in from the door) and its half size (a Vector3), so every screen and the server judge
-- who is in the home alike.
Press.RoomAttribute = "PressRoom"
Press.HalfAttribute = "PressHalf"
-- The find's own button on its model, beside Take's (the attachment's and the prompt's name).
Press.Name = "Press"

-- The press of find `key` (a Gold's base key) set out at home, nil if it gets none: no press at
-- all (a teacup, the lamp found lit), one that only rolls it off, or one that needs your hand.
function Press.row(key: string): Use.Row?
	local row = Use.Rows[key]
	if not row or key == Drive.Key or row.verb == Head.Verb or (row.down and not row.walks) then
		return nil
	end
	return row
end

-- The word on its button, nil if it gets none.
function Press.verb(key: string): string?
	local row = Press.row(key)
	return if row then row.verb else nil
end

-- Where a press of a find set out stops its travel, in seconds into the press: 0 for a wind-up
-- that would walk off (it plays on where it stands, `Use.played`), nil for the rest.
function Press.stop(row: Use.Row): number?
	return if row.down then 0 else nil
end

-- Whether a point `x`, `z` studs from a home's room middle (in the room's frame, `RoomAttribute`)
-- is in that home, its half size `halfX` by `halfZ`: inside its walls or in its doorway. Only a
-- player in the home sees and presses a find's button there.
function Press.inside(x: number, z: number, halfX: number, halfZ: number): boolean
	return math.abs(x) <= halfX and math.abs(z) <= halfZ + Press.Doorway
end

return Press
