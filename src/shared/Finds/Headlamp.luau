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
	Pure numbers and curves, so Lune tests them: `HeadlampView` draws them.
]]

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

local RAD = math.pi / 180

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
