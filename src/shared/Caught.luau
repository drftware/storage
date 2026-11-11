--!strict
--[[
	Caught: a keeper's catch on the caught player's screen (L-06b3c, L-06c2), as numbers and the
	pure curves the server and the screen share. Pure, so Lune tests it (tests/caught.spec.luau).

	The moment: the worst thing that can happen to you, as Five Nights at Freddy's and Piggy end a
	run: the face rushes the camera with a scream, no blood. Its hand closes and everything goes
	quiet: the chase music cuts, the hall falls silent, and your view is wrenched round to its
	blank face, right there over you (`Seize`). For a breath it doesn't move (`Dread`). Then it
	throws itself at you: its face rushes your eyes as the view crash-zooms in (`Lunge`), with a
	scream, a sting and its own body's creak, and its hollow head hits you with a thunk and a hard
	jolt, filling the screen (`Hit`). Then the black (`Dark`), cut, not faded. "Caught" sits in
	the dark while the film screeches round you (`Hold`); the server has stored you in a unit by
	then (KeptPlayers). You come to slowly (`Wake`): your eyes crack open, drop shut, then open on
	the dark inside, the view blurred and grey as it clears.
]]

local Caught = {}

-- Where the server's catch reaches the caught player's screen: ReplicatedStorage.Remotes.Caught,
-- fired to that player alone with the keeper's body that caught them (a Model, which the screen
-- checks; nil if the server has none). Server to client only.
Caught.RemoteFolder = "Remotes"
Caught.Remote = "Caught"

-- The timeline, in seconds from the catch.

-- How long your view takes to be wrenched round to its face, fastest at the start: a hand
-- turning your head, not you looking.
Caught.Seize = 0.12
-- From the catch to the lunge: dead silence, its face over you, still. Long enough to see what
-- has you; short enough that the lunge still comes before you're ready.
Caught.Dread = 0.48
-- How long its face takes to rush your eyes: a twitch back, then faster and faster.
Caught.Lunge = 0.32
-- How long its face fills the screen, shaking, before the black.
Caught.Hit = 0.16
-- From the catch to the cut to black. The server stores you in a unit then (KeptPlayers).
Caught.Dark = Caught.Dread + Caught.Lunge + Caught.Hit
-- Seconds the screen stays black: "Caught" in the dark while the film screeches round you.
Caught.Hold = 1.25
-- The wake, as (seconds into it, how black) keys, eased between: your eyes crack open on the
-- dark inside, drop shut, stay shut a moment, then open slowly. Coming to, not a fade back in.
Caught.Wake = {
	{ 0, 1 },
	{ 0.45, 0.45 },
	{ 0.7, 0.93 },
	{ 0.95, 0.93 },
	{ 1.75, 0.12 },
	{ 2.2, 0 },
}
-- Seconds the wake takes, its last key.
Caught.Lift = Caught.Wake[#Caught.Wake][1]
-- From the catch to waking clear in the unit: keepers leave you alone from the catch until
-- you're let out (`Kept.Attribute`).
Caught.Wrap = Caught.Dark + Caught.Hold + Caught.Lift

-- How hard the view jerks as it seizes you (CameraShake trauma, 0 to 1): enough to feel the
-- grab, not so much you can't read its face.
Caught.Kick = 0.55
-- How hard the view is hit as its face reaches you: the most a kick gives.
Caught.HitKick = 1
-- How far its face lunges back before it comes (as a share of the rush; 0 for none): the
-- twitch that tells your body something is coming a split second before it does.
Caught.Windup = 0.8
-- Studs from your eye to the middle of its head when it lands: close enough that its face is
-- taller than your screen, far enough that you still see its outline, cocked over.
Caught.Near = 1.5
-- And as it holds the screen, pushed in to this: its face pressing at your eye.
Caught.Close = 0.85
-- Degrees its head is cocked over as it hits, as its walk lolls it.
Caught.Cock = 26
-- The knock as its face lands: how far your view is yanked toward its face (studs), tipped up
-- and rolled (degrees), at once and dying away through the hit, so its face slams into the
-- screen rather than bouncing off it. CameraShake's shiver goes on top.
Caught.KnockPull = 0.2
Caught.KnockTilt = 4
Caught.KnockRoll = 7
-- Seconds the knock takes to land: about two frames, a blow, not a push.
Caught.KnockIn = 0.03
-- How fast it dies away after (per second, as an exponent): mostly gone by the black.
Caught.KnockOut = 12
-- Its face is lit as it comes, as if by your own eyes widening in the dark: a light hung just
-- in front of its face (studs ahead of the head's middle, and below), dim in the dread, full at
-- the hit, so its blank face reads and isn't a black shape. It costs one light for a second.
Caught.GlowAhead = 1.6
Caught.GlowBelow = 0.35
Caught.GlowRange = 3.4
Caught.GlowDread = 0.5
Caught.GlowHit = 3
Caught.GlowColor = { 255, 232, 206 }
-- Your view's width as a share of your own, crept to through the dread (tunnel vision as you
-- freeze), then at the hit (a crash zoom, so its face fills a wide phone screen).
Caught.Tunnel = 0.86
Caught.Crash = 0.48
-- The wake's blur (a BlurEffect's Size) and how grey the world is (ColorCorrection Saturation,
-- below 0) as you open your eyes, both clearing by the end of the wake.
Caught.Blur = 22
Caught.Grey = -0.75

-- A recording the catch plays on the caught screen only, as your own sound (not from anywhere
-- in the hall): its stretch, how loud and pitched, when (seconds from the catch) and how many
-- seconds it fades out over at the end of what's heard.
export type Clip = {
	id: string,
	from: number,
	length: number,
	volume: number,
	pitch: number,
	at: number,
	fade: number,
}

-- The catch's sting, all on the instant the face starts its rush (measured, docs/STUDIO.md
-- "Sounds measured for the catch"): the scream, Pro Sound Effects' "Creature Screech Pterodactyl
-- Vocals Screams 1" (loud within 60 ms, 470 Hz to 6 kHz, all of it on a phone's speaker),
-- pitched down until it's no animal's and the loudest thing on a phone; APM's "Razormorph K",
-- full in 20 ms and the loudest recording measured, a huge hit (half of it under 190 Hz, for
-- headphones) that rings into the black under the film's squeal; and Pro Sound Effects' "Whoosh Fast Swish By 5", started
-- where it rises, so the air rushing at you peaks as its face lands. Its own body's creak and
-- thunk are on its row (`KeeperRows` tell, the Lunge and Catch beats).
Caught.Sting = {
	{
		id = "rbxassetid://9125474229",
		from = 0,
		length = 0.92,
		volume = 2.4,
		pitch = 0.8,
		at = Caught.Dread,
		fade = 0.2,
	},
	{
		id = "rbxassetid://1846681042",
		from = 0,
		length = 3.2,
		volume = 0.9,
		pitch = 1,
		at = Caught.Dread,
		fade = 1.6,
	},
	{
		id = "rbxassetid://9120714365",
		from = 0.12,
		length = 0.75,
		volume = 1.3,
		pitch = 1,
		at = Caught.Dread,
		fade = 0.25,
	},
} :: { Clip }

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

local function smooth(t: number): number
	t = clamp01(t)
	return t * t * (3 - 2 * t)
end

--- How far your view has been turned to its face, 0 (where you looked) to 1 (on its face),
--- `since` seconds after the catch: fastest at the start, settled by `Seize`.
function Caught.turn(since: number): number
	local u = clamp01(since / Caught.Seize)
	local left = 1 - u
	return 1 - left * left * left
end

--- How far its head has come from where it stood to its place before your eye, `since` seconds
--- after the catch: 0 through the dread, then a twitch back (below 0, at most about a tenth of
--- `Windup`) and faster and faster to 1 as it hits, held at 1 after.
function Caught.reach(since: number): number
	local u = (since - Caught.Dread) / Caught.Lunge
	if u <= 0 then
		return 0
	elseif u >= 1 then
		return 1
	end
	local k = Caught.Windup
	return u * u * ((k + 1) * u - k)
end

--- How far its face has pushed in from `Near` to `Close` as it holds the screen, `since`
--- seconds after the catch: 0 until it lands, then fast and settling, 1 by the black.
function Caught.press(since: number): number
	local u = clamp01((since - Caught.Dread - Caught.Lunge) / Caught.Hit)
	local left = 1 - u
	return 1 - left * left
end

--- How much of the knock is on your view `since` seconds after the catch, 0 to 1: none until
--- its face lands, all of it `KnockIn` later, then dying away.
function Caught.knock(since: number): number
	local into = since - Caught.Dread - Caught.Lunge
	if into < 0 or since >= Caught.Dark then
		return 0
	elseif into < Caught.KnockIn then
		return into / Caught.KnockIn
	end
	return math.exp(-(into - Caught.KnockIn) * Caught.KnockOut)
end

--- How bright the light on its face is `since` seconds after the catch: `GlowDread` through the
--- dread, rising with the rush to `GlowHit`, held through the hit, out from the black.
function Caught.glow(since: number): number
	if since < 0 or since >= Caught.Dark then
		return 0
	end
	local rush = clamp01(Caught.reach(since))
	return Caught.GlowDread + (Caught.GlowHit - Caught.GlowDread) * rush
end

--- Your view's width as a share of your own `since` seconds after the catch: creeping in to
--- `Tunnel` through the dread, crashing in to `Crash` with the rush, held through the hit, and
--- your own again from the black.
function Caught.lens(since: number): number
	if since < 0 or since >= Caught.Dark then
		return 1
	elseif since < Caught.Dread then
		return 1 + (Caught.Tunnel - 1) * smooth(since / Caught.Dread)
	end
	local rush = clamp01(Caught.reach(since))
	return Caught.Tunnel + (Caught.Crash - Caught.Tunnel) * rush
end

--- Whether its face is on the screen (the dread, the rush and the hit), `since` seconds after
--- the catch.
function Caught.lunging(since: number): boolean
	return since >= 0 and since < Caught.Dark
end

--- How black the caught player's screen is `since` seconds after the catch, 0 (clear) to 1:
--- clear through the lunge, cut to black at `Dark`, black for `Hold`, then the wake's keys.
--- 0 before the catch and once it's over.
function Caught.blackout(since: number): number
	if since < Caught.Dark then
		return 0
	end
	local woke = since - Caught.Dark - Caught.Hold
	if woke <= 0 then
		return 1
	end
	local keys = Caught.Wake
	for i = 2, #keys do
		local a, b = keys[i - 1], keys[i]
		if woke <= b[1] then
			return a[2] + (b[2] - a[2]) * smooth((woke - a[1]) / (b[1] - a[1]))
		end
	end
	return 0
end

--- How hazy the world is as you come to, 0 (clear) to 1 (`Blur` and `Grey` in full), `since`
--- seconds after the catch: full from the black, clearing evenly through the wake, so the view
--- is still soft as your eyes open.
function Caught.haze(since: number): number
	if since < Caught.Dark then
		return 0
	end
	local woke = since - Caught.Dark - Caught.Hold
	if woke <= 0 then
		return 1
	end
	return 1 - clamp01(woke / Caught.Lift)
end

--- How clear "Caught" is `since` seconds after the catch, 0 (unseen) to 1: it comes up in the
--- black a beat after the cut and goes as your eyes first crack open.
function Caught.headline(since: number): number
	local into = since - Caught.Dark
	if into < 0.15 then
		return 0
	elseif into < 0.45 then
		return (into - 0.15) / 0.3
	end
	local woke = into - Caught.Hold
	if woke <= 0 then
		return 1
	end
	return math.max(1 - woke / 0.3, 0)
end

--- Whether the screen still has anything of the catch on it `since` seconds after it.
function Caught.showing(since: number): boolean
	return since >= 0 and since < Caught.Wrap
end

return table.freeze(Caught)
