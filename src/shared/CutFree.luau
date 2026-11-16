--!strict
--[[
	Cut Free (S3-03a, GDD "Getting caught"): caught, you pay Robux and you're out at once, the way
	DOORS' revive brings you straight back. Wrapped in a unit, the film rips off you and the door
	hauls itself up on the hall; carried up after the car left without you, you're standing in
	the car beside your friends as it reaches the next floor, not wrapped in a unit waiting to be
	found. Only the screen you see while caught offers it, never over play, and nothing bought
	with coins does the same.

	A purchase is never lost: its grant puts a spare in the save (`Products`' `cutFree` row), and
	the server spends that spare as it frees you (CutFrees). One that lands after a friend has
	already freed you waits in the save, and your next press uses it with no prompt.

	The press reaches the server through ReplicatedStorage.Remotes.CutFree, carrying nothing. Its
	`OnAttribute` says whether the button stands on the screen: true while the offer is on sale
	here (always in Studio, where it's free while no product of its name exists).
]]
local Save = require("./Save")

local CutFree = {}

-- The offer's name in `Products` and in the save's `spares`.
CutFree.Offer = "cutFree"
-- Where a caught player's press reaches the server, in ReplicatedStorage.Remotes.
CutFree.Remote = "CutFree"
-- On the remote: whether the button stands on the caught screen and the watch bar.
CutFree.OnAttribute = "On"
-- Seconds between presses the server takes: a second tap while Roblox's prompt comes up is
-- dropped rather than putting a second prompt behind the first.
CutFree.AskEvery = 1.5
-- Seconds after the film rips that the unit's door starts hauling itself up: the rip lands on its
-- own, then the door's rattle and the hall's light pour in.
CutFree.DoorAfter = 0.45
-- Seconds between the server's looks at whether the offer is on sale (the live switch, a
-- product made while the server runs): quick enough that a switch flipped off hides the button
-- within a breath.
CutFree.LookEvery = 2

-- The button (S3-03a2): the one warm thing on the caught screen, beside Bang, and on the watch
-- bar. One word on it; Roblox's own prompt shows the price, so nothing else is written.
CutFree.Word = "Cut Free"
-- Its warm ink (the word and its ring) and its dark, warm fill: the hall's light seen through the
-- crack under the door, against Bang's cold off-white. 0 to 255 each (Color3.fromRGB on screen;
-- plain numbers so the Lune specs can load this).
CutFree.Ink = table.freeze({ r = 255, g = 206, b = 150 })
CutFree.Fill = table.freeze({ r = 44, g = 28, b = 14 })
-- The fill's and ring's transparency fully in: a touch more solid than Bang's, so it reads as
-- the way out rather than one more thing to hit.
CutFree.FillSee = 0.3
CutFree.RingSee = 0.2
-- Seconds after Bang starts coming up that Cut Free starts: Bang lands first as the thing you do,
-- then the way out eases in beside it, never both popping at once.
CutFree.InAfter = 0.35
-- Its size beside Bang: its height as a share of Bang's side, its width as a share of its own
-- height. Smaller than Bang, so a mashing thumb finds Bang and Cut Free is a choice.
CutFree.Tall = 0.46
CutFree.Wide = 2.15
-- The gap between it and Bang, as a share of Bang's side: on a phone about a thumb's width, so
-- the right thumb hammering Bang never lands on it.
CutFree.Gap = 0.42
-- A press: the button springs to this scale and back (as Bang's press), and its look drops to
-- this share of fully in while the press is out (`AskEvery`), so a second tap reads as taken.
CutFree.Pressed = 0.86
CutFree.Dim = 0.45
-- Seconds the dim takes to fall and to come back: quick, so the press reads at once.
CutFree.DimTime = 0.12
-- Its click (Roblox's "UI Bright Click", as the car's panel), a little lower and warmer than the
-- panel's.
CutFree.Click = { id = "rbxassetid://15675059323", pitch = 0.9, volume = 0.35 }

-- Free a Friend (S3-03b, GDD "Getting caught"): you're free, a friend is caught somewhere on
-- the floor, and you pay to free them from wherever you're standing. Their film rips and their
-- door hauls up exactly as their own Cut Free would; left behind, they're standing in the car at
-- the next floor. Bought for them (Brix's recipients, D-206), granted as a spare in the buyer's
-- save and spent as the friend is freed, so one that lands after they're already out waits for
-- the buyer's next press, with no prompt.

-- The offer's name in `Products` and in the save's `spares`.
CutFree.FriendOffer = "freeFriend"
-- Where a press for a friend reaches the server, in ReplicatedStorage.Remotes, carrying the
-- friend's UserId. Its `OnAttribute` is the same flag as Cut Free's, for this offer.
CutFree.FriendRemote = "FreeFriend"
-- The pill's one word, beside the friend's face.
CutFree.FriendWord = "Free"
-- Most caught friends with a pill at once, the longest caught first: three stacked pills still
-- clear a landscape phone's bottom edge under the corner map.
CutFree.FriendMost = 3
-- Seconds after a friend is caught before their pill eases in: the catch lands first (its
-- scream, their dot gone off the map), then the way to pay for them.
CutFree.FriendInAfter = 0.8
-- The pill's height in points (above Apple's 44-point tap minimum), its width as a share of
-- that, and the points between pills and under the corner map.
CutFree.FriendTall = 46
CutFree.FriendWide = 2.5
CutFree.FriendGap = 8
-- Seconds the pill takes to ease in (sliding from the screen's edge) and to fade out.
CutFree.FriendIn = 0.32
CutFree.FriendOut = 0.25
-- Your friend freed by your press: the film's rip, quieter than in the hall (it's across the
-- floor), and the pill's swell (scale) as it goes.
CutFree.FriendRipVolume = 0.45
CutFree.FriendFreedSwell = 1.12
-- Seconds a press stays yours: a friend freed this long after it plays the rip on your screen.
-- A purchase can take a while to land, and a friend freed by somebody else after that isn't
-- yours to hear.
CutFree.FriendHeardFor = 60

-- Free Everyone (S3-03c, GDD "Getting caught", 149 Robux): the whole team is caught, and before
-- the results come down every caught screen's pill reads Free Everyone. One press, one purchase,
-- and every film on the floor rips at once, every door goes up, and the climb carries on from
-- this floor. Granted as a spare in the buyer's save and spent as it frees them, so one that lands
-- after the results keeps for the buyer's next wipe. Playing alone, the pill stays Cut Free: it
-- does the same for you, and a dearer button for the same thing would be a trick.

-- The offer's name in `Products` and in the save's `spares`.
CutFree.EveryoneOffer = "freeEveryone"
-- Where a caught player's press reaches the server, in ReplicatedStorage.Remotes, carrying
-- nothing. Its `OnAttribute` is the same flag as Cut Free's, for this offer.
CutFree.EveryoneRemote = "FreeEveryone"
-- The pill's words while the wipe waits.
CutFree.EveryoneWord = "Free Everyone"
-- Its width as a share of its height: wider than Cut Free's so the words keep Cut Free's size.
CutFree.EveryoneWide = 3.45
-- The swap: as everyone's caught, the pill grows into its new words over `SwapTime` seconds,
-- swelling to `Swell` and settling, with its click pitched down to `SwapPitch` (not a press:
-- a chance), so a player who wasn't looking at it hears the way out change.
CutFree.SwapTime = 0.35
CutFree.Swell = 1.08
CutFree.SwapPitch = 0.62
CutFree.SwapVolume = 0.28

-- The offer every caught screen shows while a wipe waits, with `players` in the server: Cut Free
-- alone (it frees you, the whole team), Free Everyone with friends.
function CutFree.wipeOffer(players: number): string
	return if players <= 1 then CutFree.Offer else CutFree.EveryoneOffer
end

-- How many of the offer named `offer` (Cut Free by default) `data` holds paid for and unused.
function CutFree.spares(data: Save.Data, offer: string?): number
	local held: number? = data.spares[offer or CutFree.Offer]
	return held or 0
end

-- Spends one of `data`'s spares of `offer` (Cut Free by default): whether there was one. Never
-- goes below none.
function CutFree.spend(data: Save.Data, offer: string?): boolean
	local name = offer or CutFree.Offer
	local held = CutFree.spares(data, name)
	if held <= 0 then
		return false
	end
	if held == 1 then
		data.spares[name] = nil
	else
		data.spares[name] = held - 1
	end
	return true
end

-- The friend a Free a Friend press names, checked as the remote hands it over: a whole,
-- non-zero UserId Roblox could give (Studio's test players have negative ones), or nil.
function CutFree.friendId(value: unknown): number?
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then
		return nil
	end
	if value == 0 or math.abs(value) > 2 ^ 53 then
		return nil
	end
	return value
end

return table.freeze(CutFree)
