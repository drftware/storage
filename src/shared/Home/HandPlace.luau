--!strict
--[[
	HandPlace: setting a held find down where you look in your own home, without opening Arrange
	(S5-03j5a, D-463). The moment: holding the teddy, you look at the job box's top and a faint
	teddy sits there, snapped and turned to the room; Drop reads Place, and one press sets it down
	with the landing's knock. Precedents: Grow a Garden's held egg or seed shown where it will go in
	your garden, Minecraft's outline of the block before you place it, Animal Crossing's and The
	Sims' place-from-hand.

	Shared by the screen (HandPlaceView, which aims and judges with `PlaceAim`, as Arrange does)
	and the server (Arranging's `onHandPlace`, which judges the ask again as it judges a Place).
	The ask names no find: what's in your hand is the server's to know (`Slots:heldFromBox`).
]]
local HandPlace = {}

HandPlace.Remote = "HandPlace" -- in Spots.RemoteFolder: (on, x, y, turn), the held find set there
HandPlace.Verb = "Place" -- Drop's word while the faint copy shows
-- Studs from you to where it would stand: how far a look still sets a thing down. A step past a
-- find's Take reach (8), so a top across a small room is in reach from the door.
HandPlace.Reach = 10
HandPlace.Slack = 3 -- studs past it the server allows, for a screen a beat behind

-- The faint copy: how see-through it is (0 solid, 1 gone) and how quickly it fades in or out,
-- and how quickly it glides to a new spot (seconds); it never turns green or red (the plan's
-- "green-free": nowhere it fits, it simply isn't there).
-- Seen in Studio at phone size (S5-03j5a2): 0.6 washed out on a grey-green top, 0.4 read as the
-- find already standing there. A white outline was tried and dropped: Roblox draws a Highlight
-- only on opaque parts (STUDIO.md).
HandPlace.Faint = 0.5
-- It breathes, a little more and less see-through, so it reads as where it'd go rather than a
-- find set out: how far (in transparency, each way) and one breath's length (seconds).
HandPlace.Breathe = 0.08
HandPlace.Breath = 1.6
HandPlace.Fade = 0.12
HandPlace.Glide = 0.08

-- The player attribute that says slot `i` holds a find out of their own job box that they may
-- set down by hand (true, or absent), written by Slots beside the slot's key.
function HandPlace.slotAttribute(i: number): string
	return `ToolOwnBox{i}`
end

return table.freeze(HandPlace)
