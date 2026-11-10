--!strict
--[[
	Blowing the air horn (L-14a2, D-087), as Lethal Company's air horn draws the monsters that hunt
	by sound: you press Blow with the horn in your hand, it blasts, and every keeper whose way to you
	along the halls is inside the blast's reach comes to where you blew it and looks. A sleeper in
	reach wakes (GDD: "Wakes dormant things nearby"); a keeper hunting you keeps its eyes on you and
	hears nothing, as it hears no door (D-069); nothing hears it through a shut door.

	Pure: the numbers and the rules, Lune-tested (tests/horn.spec.luau). The server's `Horns` checks
	a press and tells keepers (`Keepers:hearHorn`); `HornView` is the press, the blast and the raise on
	each screen.
]]
local Keeper = require("../Keeper")

local Horn = {}

-- The catalog key of the tool this is.
Horn.Key = "AirHorn"

-- How far the blast carries, in studs along the halls (keepers) and through the air (players,
-- where it fades to nothing): the loudest thing on a floor, a door bursting open's reach (130),
-- past an open's or a slam's 110. About five hall pieces: blown two halls off a walking keeper,
-- it comes; but any sleeper in an open unit that near wakes too.
Horn.Reach = 130
-- Heard at full loudness this close (studs): the hall you're in.
Horn.Near = 14

-- Seconds between blows: the blast and its echo, then a breath, so one horn can't be held on a
-- keeper like a leash. The server takes a press this much early (a press sent on time reaching it
-- a little sooner than the last).
Horn.Gap = 2.5
Horn.Slack = 0.15

-- The blast: Pro Sound Effects' "Air Horn Various Lengths 4", a stadium horn's one long blast
-- (1.1 s, from 0.94 s, peaks near -2 dB) and its echo dying away (-40 dB by 2.4 s), measured by
-- AudioAnalyzer.
Horn.Blast = {
	id = "rbxassetid://9113071891",
	from = 0.92,
	length = 1.55,
	volume = 1,
	pitch = 1,
}

-- Your view: the horn comes up to blow as you press, stays up through the blast, then goes back
-- down (ToolView's `use` pose, from the catalog row). Seconds held up.
Horn.Up = 1.1
-- Your view's jolt as it blasts (CameraShake's trauma, 0 to 1): a kick, not a hit.
Horn.Kick = 0.32

-- A friend blowing it: their left arm raised up and forward (radians about the shoulder's X, as
-- the torch raises the right; a level arm is a quarter turn), eased up in `ArmIn` and down in
-- `ArmOut` (seconds), held up for `Up`.
Horn.Arm = math.rad(135)
Horn.ArmIn = 0.12
Horn.ArmOut = 0.35

-- On the horn's model while it's carried: the server's clock (GetServerTimeNow) at its latest
-- blast, so every screen plays it and raises the arm that blew it. A blast older than `Fresh`
-- seconds when a screen learns of it (streamed in late) isn't played.
Horn.BlownAttribute = "Blown"
Horn.Fresh = 0.5

--- Whether a blow `now` (seconds) may follow the last one, at `last` (nil: never blown). The
--- server takes it `Slack` early.
function Horn.allow(last: number?, now: number, slack: number?): boolean
	return last == nil or now - last >= Horn.Gap - (slack or 0) - 1e-9
end

--- How far up a friend's arm is (0 down, 1 up), `since` seconds after their blast: eased up, held
--- through the blast, eased down.
function Horn.arm(since: number): number
	if since < 0 then
		return 0
	end
	local w
	if since < Horn.ArmIn then
		w = since / Horn.ArmIn
	elseif since < Horn.Up then
		w = 1
	else
		w = 1 - (since - Horn.Up) / Horn.ArmOut
	end
	w = math.clamp(w, 0, 1)
	return w * w * (3 - 2 * w)
end

--- Keeper `k` hears a blast at `p` (the floor's coordinates): it comes to look, waking if it
--- slept, as for a door (`Keeper.heardAt`). How far off it heard it along the map, or nil.
function Horn.heard(k: Keeper.Keeper, p: vector): number?
	return Keeper.heardAt(k, p, Horn.Reach)
end

return Horn
