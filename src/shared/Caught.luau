--!strict
--[[
	Caught: what a keeper's catch looks like on the caught player's screen (L-06b3c), as numbers
	and one pure curve that the server and the screen share. Pure, so Lune tests it
	(tests/caught.spec.luau).

	The moment: you stood still too long in the dark and its hand closes on you. Your view jerks
	(CameraShake), the screen drops half dark at once and closes to black, "Caught" comes up in the
	dark, and you can't move. Until L-07's wrap and storage, the stand-in takes over in the black:
	the server puts you back in the floor's lobby once the screen is black (`Dark`), and the screen
	opens again there. No blood and no screamer (the GDD's "Getting kept"); the sting and its
	sounds are L-06b4b's.
]]

local Caught = {}

-- Where the server's catch reaches the caught player's screen: ReplicatedStorage.Remotes.Caught,
-- fired to that player alone, carrying nothing. Server to client only.
Caught.RemoteFolder = "Remotes"
Caught.Remote = "Caught"

-- How hard the view jerks as its hand closes (CameraShake trauma, 0 to 1): near the most a slam
-- gives, so it reads as a hand on you, not a door.
Caught.Kick = 0.85
-- How dark the screen drops the instant it has you (0 clear, 1 black): a blink you can't help.
Caught.Jolt = 0.55
-- Seconds from the jolt to full black, closing faster at the end, like passing out.
Caught.Dark = 0.4
-- Seconds the screen stays black: "Caught" sits in the dark while the stand-in moves you.
Caught.Hold = 0.9
-- Seconds the screen takes to open again on the lobby.
Caught.Lift = 0.7
-- Seconds keepers leave a caught player alone from the catch: the whole blackout, so the one that
-- caught you can't catch you again before you're moved. About the GDD's 2-second wrap, which
-- L-07 puts here.
Caught.Out = Caught.Dark + Caught.Hold + Caught.Lift

--- How black the caught player's screen is `since` seconds after the catch, 0 (clear) to 1:
--- `Jolt` at once, closing to black over `Dark`, black for `Hold`, then clear again over `Lift`.
--- 0 before the catch and once it's over.
function Caught.blackout(since: number): number
	if since < 0 then
		return 0
	elseif since < Caught.Dark then
		local t = since / Caught.Dark
		return Caught.Jolt + (1 - Caught.Jolt) * t * t
	end
	local lifts = Caught.Dark + Caught.Hold
	if since <= lifts then
		return 1
	end
	return math.max(1 - (since - lifts) / Caught.Lift, 0)
end

--- How clear "Caught" is `since` seconds after the catch, 0 (unseen) to 1: it comes up over the
--- second half of the close to black, and goes with the dark as the screen opens.
function Caught.headline(since: number): number
	local half = Caught.Dark / 2
	if since < half then
		return 0
	elseif since < Caught.Dark then
		return (since - half) / half
	end
	local lifts = Caught.Dark + Caught.Hold
	if since <= lifts then
		return 1
	end
	return math.max(1 - (since - lifts) / (Caught.Lift / 2), 0)
end

--- Whether the screen still has anything of the catch on it `since` seconds after it.
function Caught.showing(since: number): boolean
	return since >= 0 and since < Caught.Out
end

return table.freeze(Caught)
