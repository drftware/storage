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

-- How many Cut Frees `data` holds paid for and unused.
function CutFree.spares(data: Save.Data): number
	local held: number? = data.spares[CutFree.Offer]
	return held or 0
end

-- Spends one of `data`'s spare Cut Frees: whether there was one. Never goes below none.
function CutFree.spend(data: Save.Data): boolean
	local held = CutFree.spares(data)
	if held <= 0 then
		return false
	end
	if held == 1 then
		data.spares[CutFree.Offer] = nil
	else
		data.spares[CutFree.Offer] = held - 1
	end
	return true
end

return table.freeze(CutFree)
