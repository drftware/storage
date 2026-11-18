--!strict
--[[
	Take: a find taken straight from where it stands in your home (S5-03i2a, D-350). The moment:
	you walk up to the teddy in your shelf, press Take, and it hops off its cubby into your hand
	with its pick-up sound, as a find on a climb comes up off the floor.

	The server (Takes, Shelves, Arranging) puts a Take button on each find standing in a cubby or
	set out; only its holder's screen shows it (HomeTakeView), and only its holder's press counts.
	A take stamps the standing copy with its taker (`Attribute`), and it stays a moment, unseen, so
	every screen flies its own copy into the taker's hand.
]]
local Take = {}

Take.Verb = "Take" -- the button's one word, as a find's on a climb (Slots' lying finds)
Take.Reach = 8 -- studs: how near you stand to take one, a climb find's reach (Carry.PickReach)
Take.Slack = 3 -- studs past it the server allows, for a screen a beat behind
Take.Attribute = "TakenBy" -- on the standing copy: the UserId of who took it, once taken
Take.Linger = 1.2 -- seconds a taken copy stays (unseen) so a screen a beat behind still flies it

-- Feel: the hop off its spot, then the flight into the hand.
Take.Hop = 0.55 -- studs it jumps up off its spot: plainly picked up, not slid away
Take.HopTime = 0.12 -- seconds of that hop: quick, a hand's snatch
Take.Fly = 0.3 -- seconds from the top of the hop into the hand
Take.Spin = 0.35 -- turns it makes on the way (a quarter-and-a-bit), so it reads as tossed, not towed
Take.Heard = 24 -- studs: a friend's take heard from about across a home

return Take
