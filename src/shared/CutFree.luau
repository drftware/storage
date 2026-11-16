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
