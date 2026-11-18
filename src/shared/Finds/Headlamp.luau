--!strict
--[[
	Headlamp (F-G1b4a2, D-420): the hard hat's own beam, as Phasmophobia's head torch is. The
	moment: you pull the hat on and the hall ahead snaps into a hard white cone that follows your
	eyes, your hands free for the jukebox or a tool.

	Yours leaves your eyes and goes wherever you look, up and down too, nodding with your stride
	(`Torch.step`'s, with no lag: it's on your head, not in your hand). As the hat goes on it swings
	up from your feet into place. A friend's leaves the lamp on their brow along their aim (their
	torch's `Aim`, sent while they wear it), and the hat drops onto their head with a little settle.
	It replaces the hat's warm art light while worn; only the nearest few cast real light.

	Its minute runs down as the flashlight dies (F-G1b4b, D-421): deep in a dark hall the white
	cone starts to stutter and buzz, the stutters closing in as it sags, then its bulb sputters
	out; spent, the hat slips off your head and cracks apart on the floor (D-141's break), leaving
	you in the dark with whatever's coming. The server owns the minute and the break; each screen
	draws the stutter from what's left (`light`).
	Pure numbers and curves, so Lune tests them: `HeadlampView` draws them.
]]

local Charge = require("../Flashlight/Charge")
local Torch = require("../Flashlight/Torch")

local Headlamp = {}

-- The beam: tighter and whiter than the torch's (54 degrees, an old bulb's warm yellow), a hard
-- cone you aim with your eyes, not a pool you sweep with your hand.
Headlamp.Angle = 34 -- degrees, full width
Headlamp.Range = 48 -- studs: a little past the torch's, an LED's throw
Headlamp.Brightness = 2.8
Headlamp.Color = { 236, 243, 255 } -- a white LED's cold white with a breath of blue
-- Yours only, no shadows: a faint ring so a wall right in front of you is lit at low graphics,
-- where a spotlight lights nothing nearer than about 3 studs (as the torch's spill, Torch.Spill*).
Headlamp.SpillRange = 4.5
Headlamp.SpillBrightness = 0.25
-- Studs above your eye the lamp sits (your brow): enough that what it lights casts a sliver of
-- shadow you can see, so the cone reads as a light on your head and not your own eyes glowing.
Headlamp.EyeUp = 0.3
-- Studs ahead of your eye: past your face and the hat's brim (hidden from you, HeadView), so
-- nothing of your own head ever stands in its light.
Headlamp.EyeAhead = 0.7

-- The stride on your head: of the torch's nod at each footfall, and degrees the cone weaves side
-- to side once a stride. Slight: you feel yourself walking, the cone never wanders off your look.
Headlamp.Nod = 1.3
Headlamp.Weave = 0.6

-- The pull-on: seconds after Wear's press the bulb lights (the hat's SwitchOn lights it at 0.155,
-- `Sets/Lights`); then the LED's rise, and the cone swinging up from your feet into place as the
-- hat comes down over your brow, a touch past your look and back.
Headlamp.LightAt = 0.155
Headlamp.RampSeconds = 0.06 -- an LED: near instant, but never a pop
Headlamp.SwingFrom = 55 -- degrees below your look it starts: lighting your feet
Headlamp.SwingSeconds = 0.45
Headlamp.SwingBack = 1.4 -- how far past your look it rises (an ease's overshoot; ~4 degrees)

-- A friend's hat dropping onto their head: from this many studs over its seat (for a standard
-- head; grown with theirs), falling in `DropSeconds`, tipped back `Tilt` degrees as it lands; a
-- small hop of `Hop` studs over `HopSeconds` as it rocks level, then still.
Headlamp.DropFrom = 0.7
Headlamp.DropSeconds = 0.16
Headlamp.Tilt = 7
Headlamp.Hop = 0.05
Headlamp.HopSeconds = 0.22

-- Headlamps with real light on a screen at once: yours and the nearest two friends' within
-- `Seen` studs (on top of the torches' four, `Torch.RealBeams`). The rest glow on their brow.
-- What it does: a squad all in hard hats stays smooth on a low-end phone (the GDD's cap).
Headlamp.RealBeams = 3
Headlamp.Seen = 140

-- Running down (F-G1b4b), as the torch's last half minute (D-142) squeezed into the end of a
-- minute: its last `flicker` seconds stutter, a long first one you notice, then short ones far
-- apart (`gapFirst` seconds) closing in, darker, as the LED sags to `1 - sag` of its light. No
-- fade of its own (`fade` 0): the bulb's run-down after the minute (the art's `RunDown`, 3 s of
-- sputter) carries the beam out with it, on every screen the same. What it does to the player:
-- fifteen seconds' warning to get back to a friend's light before you're in the dark.
Headlamp.Shape = {
	flicker = 15,
	sag = 0.4,
	fade = 0,
	gapFirst = 4,
	firstStutter = 0.6,
} :: Charge.Shape
-- The hat's motion after its minute: its bulb sputtering out (Finds/Sets/Lights).
Headlamp.RunDown = "RunDown"
-- The bulb's glow channel the beam follows through that run-down.
Headlamp.Bulb = "HardHat_Bulb"
-- Studio only: a number on Workspace makes a hat worn on a climb hold that many seconds of light
-- (to see it run down without waiting a minute).
Headlamp.Dev = "DevHatSeconds"

-- Spent, it falls off your head and breaks (D-141's break, as a worn-out saw does): it slips off
-- forward with a small hop (studs a second up and ahead), and cracks apart as it hits the floor,
-- its bits flying in its colours (safety yellow shell, the lamp's black, the lens), heard by
-- monsters as a dropped tool. The crack: the finds kit's CRUNCH, lower, a plastic shell giving way.
Headlamp.FallUp = 4
Headlamp.FallAhead = 2.5
Headlamp.Crack = {
	id = "rbxassetid://9119075637",
	from = 0,
	length = 0.7,
	volume = 1.3,
	pitch = 0.72,
}
Headlamp.Bits = { { 222, 172, 38 }, { 38, 38, 42 }, { 214, 222, 230 } }

local RAD = math.pi / 180

-- The seconds of light a hat worn on a climb starts with: `left` as pressed, or Studio's dev
-- number (`Dev`'s value) when that's a real number over zero. At home it burns for good anyway.
function Headlamp.minute(dev: unknown, left: number): number
	if left == math.huge then
		return left
	end
	if type(dev) == "number" and dev == dev and dev > 0 and dev < math.huge then
		return dev
	end
	return left
end

--[[
	The beam's light this frame (0 to 1) and whether it's stuttering (the buzz): `left` seconds
	of its minute still to burn, then (at 0 or under) the bulb's own glow in its run-down (`bulb`,
	0 to 1, the art's track; nil once it's over). Steady until its last `Shape.flicker` seconds;
	then it stutters as a dying torch does; through the run-down it follows the bulb from where
	the sag left it, so the beam and the bulb on the brow sputter out together. Allocates nothing.
]]
function Headlamp.light(
	f: Charge.Flicker,
	left: number,
	dt: number,
	bulb: number?
): (number, boolean)
	if left > 0 then
		return Charge.glow(f, left, dt, Headlamp.Shape)
	end
	if bulb and bulb > 0.001 then
		return math.min(bulb, 1) * (1 - Headlamp.Shape.sag), true
	end
	return 0, false
end

-- The cone as the hat goes on, `t` seconds after its bulb lit: degrees below your look (a little
-- under 0 as it rises past it) and its light (0 to 1).
function Headlamp.swing(t: number): (number, number)
	if t < 0 then
		return Headlamp.SwingFrom, 0
	end
	local light = math.min(t / Headlamp.RampSeconds, 1)
	local x = t / Headlamp.SwingSeconds
	if x >= 1 then
		return 0, light
	end
	-- an ease out with an overshoot (easeOutBack): up past your look, back level at the end
	local c = Headlamp.SwingBack
	local u = x - 1
	local eased = 1 + (c + 1) * u * u * u + c * u * u
	return Headlamp.SwingFrom * (1 - eased), light
end

-- The stride's nod and weave for your beam, from the torch's sway this frame (`Torch.step`, fed
-- no turns so it never lags your look): radians up and round (left).
function Headlamp.bob(p: Torch.Pose): (number, number)
	local across = if Torch.BobAcross > 0 then p.x / Torch.BobAcross else 0
	return p.pitch * Headlamp.Nod, -across * Headlamp.Weave * RAD
end

-- A friend's hat settling onto their head, `t` seconds after it appeared there, on a head grown
-- `k` times a standard one: studs over its seat, degrees tipped back, and whether it's done.
function Headlamp.settle(t: number, k: number): (number, number, boolean)
	local drop, hop = Headlamp.DropSeconds, Headlamp.HopSeconds
	if t < 0 then
		return Headlamp.DropFrom * k, Headlamp.Tilt, false
	elseif t < drop then
		local x = t / drop
		return Headlamp.DropFrom * k * (1 - x * x), Headlamp.Tilt, false -- falling, faster
	elseif t < drop + hop then
		local u = (t - drop) / hop
		local tilt = Headlamp.Tilt * (1 - u) * (1 - u) * math.cos(2 * math.pi * u)
		return Headlamp.Hop * k * 4 * u * (1 - u), tilt, false
	end
	return 0, 0, true
end

-- Which friends' headlamps get real light: the nearest within `Seen`, up to `RealBeams - 1`.
function Headlamp.budget(distances: { number }, into: { boolean }): { boolean }
	return Torch.budget(distances, into, Headlamp.RealBeams - 1, Headlamp.Seen)
end

return Headlamp
