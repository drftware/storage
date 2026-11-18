--!strict
--[[
	ToLobby: caught on the floor the team picked with the "back to the lobby" card (S4-03c4,
	D-409), as DOORS' and Piggy's catch sends you out of the run while the friends left carry on.
	The card's picture is the shaft from above, the car far down it, lit red; a catch there makes
	it come true. The keeper's hands close and its face rushes you as any catch does (Caught); then,
	where any other catch cuts to black and wraps you for friends to free, the screen drops down
	that shaft (the card's own picture rushing up at you), slams on the car, and the black lifts
	in the lobby car the climb started from. Nobody can free you: you're out of this climb, your
	coins still counted at its end with the team's (CashOut), whatever you carried dropped where
	you were caught, as any catch drops it.

	Pure numbers and words, so Lune checks them: the server sends you down (server ToLobby), your
	screen plays the fall (ToLobbyView), the end counts you caught on that floor (`ClimbEnd.look`).
]]
local Caught = require("./Caught")
local NextFloor = require("./NextFloor")

local ToLobby = {}

-- On a player sent down, from the catch until the climb's end clears it: the server time of the
-- catch. The end counts them caught on that floor; the climb never stands them back in it.
ToLobby.Attribute = "SentDownAt"
-- On a player once the server has stood their new character in the lobby car: where (a CFrame).
-- Their screen lifts its black once it's set, facing out of the car's gate.
ToLobby.StoodAttribute = "SentDownTo"

-- The fall, in seconds from the catch. From the cut to black (`Caught.Dark`) the card's picture
-- comes up out of the black, already falling, faster and faster for `Fall`: long enough to read
-- the red car rushing up, short enough to feel like a drop.
ToLobby.Fall = 1.45
-- Seconds the picture takes to come out of the black.
ToLobby.Reveal = 0.14
-- How far the picture has grown by the landing (a share of the screen): the car at its middle
-- rushing up to fill it.
ToLobby.Zoom = 3.4
-- The landing: the picture cuts to black with the gate's slam, and the screen jolts (CameraShake
-- trauma, the size a slammed door's jolt is).
ToLobby.Land = Caught.Dark + ToLobby.Fall
ToLobby.Jolt = 0.75
-- Seconds after the catch the server swaps your body for one in the lobby car, under the black.
ToLobby.Swap = ToLobby.Land + 0.1
-- Seconds the black takes to lift once you're stood in the car, with the car's ding.
ToLobby.LiftIn = 1.1
-- Seconds after the catch the screen lifts anyway, stood or not (a lost stream, a slow server).
ToLobby.Most = 12
-- Seconds after the catch a screen still plays the fall (one arriving late, or a rejoin, doesn't).
ToLobby.Fresh = 4

-- Whether a catch on a floor of version `name` (the floor model's `FloorVersion`) sends the
-- caught player down to the lobby.
function ToLobby.sends(name: unknown): boolean
	if type(name) ~= "string" then
		return false
	end
	local version = NextFloor.find(name)
	return version ~= nil and version.caughtToLobby == true
end

local function smooth(u: number): number
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

-- The fall `since` seconds after the catch: how shown the card's picture is (0 to 1), its size (a
-- share of the screen), and how black the screen is behind it (0 to 1). Nothing before the cut to
-- black; the picture over a whole black through the fall, growing faster and faster; from the
-- landing, black alone.
function ToLobby.fall(since: number): (number, number, number)
	local into = since - Caught.Dark
	if into < 0 then
		return 0, 1, 0
	elseif into >= ToLobby.Fall then
		return 0, ToLobby.Zoom, 1
	end
	local u = into / ToLobby.Fall
	return smooth(into / ToLobby.Reveal), 1 + (ToLobby.Zoom - 1) * u * u * u, 1
end

-- How black the screen is `t` seconds after you were stood in the car: whole, then lifting.
function ToLobby.lift(t: number): number
	return 1 - smooth(t / ToLobby.LiftIn)
end

-- Whether a catch `ago` seconds old is still worth playing the fall for.
function ToLobby.fresh(ago: number): boolean
	return ago >= 0 and ago < ToLobby.Fresh
end

return table.freeze(ToLobby)
