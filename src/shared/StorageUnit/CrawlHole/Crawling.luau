--!strict
--[[
	Crawling: the rules and feel numbers of crawling through a sawn hole (L-12b3), pure so Lune
	checks them (tests/crawling.spec.luau). The moment: the keeper's footsteps behind you, you drop
	to the hole, drag yourself through on your belly in two pulls, the cut steel scraping past, and
	stand up in the next unit while it stands in the one you left.

	A short move the game makes for you once you press Crawl, as DOORS' and Pressure's vents take you
	low through a gap no one can walk: down onto your belly at the hole's mouth, two pulls through,
	up on your feet. A keeper is far too tall for the hole, so it can't follow.

	Every number here is in the crawl's own frame: its origin on the wall's middle plane at the
	hole's middle, on the floor; `along` is studs past the wall the way you crawl (negative before
	it), `up` is studs above the floor. Your root lies `pitch` radians forward of standing (pi/2 is
	flat on your belly, head first).
]]

local Arrival = require("../../Arrival")

local Crawling = {}

-- Studs from the button you can be to press it: crouched at the hole, not across the unit.
Crawling.Reach = 5
-- Studs past the button's reach the server still accepts: a moving player's lag.
Crawling.RangeSlack = 3
-- A press closer than this to your last one is dropped: a double tap.
Crawling.RepeatSeconds = 0.3
-- Studs past a unit's side and back walls that still count as inside it.
Crawling.InsideSlack = 0.5

-- The move, in three parts. Short enough that a keeper a second behind you (about 16 studs at the
-- Mannequin's hunt as you press) loses you once you're through the wall, long enough to read as
-- squeezing through and not as a teleport (L-12c, D-085: one closer catches you at the mouth).
Crawling.Drop = 0.3 -- down onto your belly at the hole's mouth
Crawling.Through = 0.75 -- two pulls through the hole
Crawling.Rise = 0.35 -- up on your feet in the next unit
Crawling.Seconds = Crawling.Drop + Crawling.Through + Crawling.Rise
-- The server waits this long past the move for your screen to have moved you before it checks
-- you're through.
Crawling.EndSlack = 0.6
Crawling.Pulls = 2
-- How much each pull surges: 0 a steady slide, 1 stopping dead between pulls. Most of a pull's
-- distance comes in its middle, as arms reach, then haul.
Crawling.Surge = 0.75

-- The path. R15's root is 2 tall and 1 deep; standing, your head's top is 2.3 above it and your
-- feet 3 below it. The hole's lip is 0.3 off the floor and its top 2.9 (CrawlHole.Rect).
Crawling.ProneUp = 0.8 -- the root lying down: your belly level with the lip, your back well under the top
Crawling.StartAlong = -2.6 -- lying down before the wall: your head just short of it
Crawling.EndAlong = 3.2 -- still lying down past it: your feet just through
Crawling.StandAlong = 3.6 -- standing in the next unit: where your head came through, a step on
-- The body's half-length past the root each way, for the checks: head first, feet last.
Crawling.HeadPast = 2.3
Crawling.FeetPast = 3

-- Your view while you crawl (first person).
Crawling.EyeUp = 1.5 -- Roblox's first-person camera above the root, along your body
-- and half a stud behind that point, looking out: Roblox's first-person camera rests there (its
-- closest zoom), so the view hands back without a jump
Crawling.EyeBack = 0.5
Crawling.EyeLift = 0.25 -- your head raised off the floor to look ahead, lying down
Crawling.LookDrop = math.rad(-16) -- looking down at the hole as you get down to it
Crawling.LookThrough = math.rad(-5) -- looking through it as you pull
Crawling.Bob = 0.08 -- studs your head dips on each pull
Crawling.Roll = math.rad(3.5) -- your view rocking toward the arm that pulls
-- Kicks to your view (Shake trauma): your belly hitting the floor, the cut steel catching you.
Crawling.Thud = 0.2
Crawling.Catch = 0.12

-- A friend's arms as they crawl (R15 shoulders, turned about X; pi/2 is straight ahead, pi past
-- the head): reaching out ahead of them, each hauling in turn. Lying down, an arm at about 140
-- degrees puts its hand on the floor and one at 184 holds it a hand's height up (Studio, the
-- default avatar), so the hauling hand plants and the other reaches.
Crawling.ArmReach = math.rad(162)
Crawling.ArmSwing = math.rad(22)
-- And each arm tucked in toward the head (about Z): the upper arms come through the hole inside its
-- sides, the hands meeting ahead of the head (Studio: at 20 or 30 degrees they graze its edges).
Crawling.ArmTuck = math.rad(35)

-- Studs a keeper hears you crawl from (L-06b): the steel scraping, about one unit each way.
Crawling.Heard = 35

-- On a crawling character (the server's, for every screen): the tag, the server time the move
-- began, and the crawl's frame (a CFrame looking the way you crawl), so a screen plays the move.
Crawling.Tag = "Crawling"
Crawling.StartAttribute = "CrawlStart"
Crawling.FrameAttribute = "CrawlFrame"
-- Every Crawl button carries this tag and its side's crawl frame (FrameAttribute): through the
-- hole you can see the far side's button, so a screen shows each only to someone on its side.
Crawling.ButtonTag = "CrawlButton"
-- The collision group your body is in while the game moves you: it touches nothing, so the hole's
-- edges and the floor can't snag a body squeezing through.
Crawling.CollisionGroup = "Crawling"

export type Verdict = { ok: boolean, refusal: string? }

--[[
	Whether a player may start crawling through a hole: not crawling already (a stale press,
	refused silently), and nobody else in the hole right now ("Wait for them": one body fits).
]]
function Crawling.decide(crawling: boolean, busy: boolean): Verdict
	if crawling then
		return { ok = false }
	elseif busy then
		return { ok = false, refusal = "Wait for them" }
	end
	return { ok = true }
end

--- Whether `p` is inside a unit `width` wide and `depth` deep, in its door's frame (+Z in from the
--- door's plane, X across it): past the door, between its side walls, short of its back wall.
function Crawling.inside(p: vector, width: number, depth: number): boolean
	return p.z > 0
		and p.z < depth + Crawling.InsideSlack
		and math.abs(p.x) < width / 2 + Crawling.InsideSlack
end

--- Whether a press of the Crawl button counts: the presser's root at `at`, moving at `velocity`,
--- is inside the unit and within reach of the button at `button`, where the server sees it or a
--- moment on (`Arrival`: run in with a keeper behind you and press Crawl as you reach the hole,
--- and the server may still see you in the doorway, L-12c). All in the unit's door frame
--- (`inside`); `width` and `depth` are the unit's.
function Crawling.counts(
	at: vector,
	velocity: vector,
	button: vector,
	width: number,
	depth: number
): boolean
	local reach = Crawling.Reach + Crawling.RangeSlack
	return Arrival.counts(function(seconds: number): boolean
		local p = at + velocity * seconds
		return Crawling.inside(p, width, depth) and vector.magnitude(p - button) <= reach
	end)
end

local function smooth(k: number): number
	local c = math.clamp(k, 0, 1)
	return c * c * (3 - 2 * c)
end

-- How far through the pulls you are (0 to 1) at `u` (0 to 1) of the pulling: always forward,
-- slow as your arms reach, fast as they haul.
function Crawling.progress(u: number): number
	local c = math.clamp(u, 0, 1)
	local w = 2 * math.pi * Crawling.Pulls
	return c - Crawling.Surge * math.sin(w * c) / w
end

--[[
	Where your root is `t` seconds into the move, in the crawl's frame: along, up, pitch, and how
	far to go from where you stood toward that (`blend`, 0 to 1: getting down to the hole, you come
	from wherever you pressed Crawl). `standUp` is your root's height standing (your Humanoid's
	HipHeight plus half your root).
]]
function Crawling.pose(t: number, standUp: number): (number, number, number, number)
	local half = math.pi / 2
	if t < Crawling.Drop then
		return Crawling.StartAlong, Crawling.ProneUp, half, smooth(t / Crawling.Drop)
	end
	local s = t - Crawling.Drop
	if s < Crawling.Through then
		local p = Crawling.progress(s / Crawling.Through)
		return Crawling.StartAlong + (Crawling.EndAlong - Crawling.StartAlong) * p,
			Crawling.ProneUp,
			half,
			1
	end
	local k = smooth((s - Crawling.Through) / Crawling.Rise)
	return Crawling.EndAlong + (Crawling.StandAlong - Crawling.EndAlong) * k,
		Crawling.ProneUp + (standUp - Crawling.ProneUp) * k,
		half * (1 - k),
		1
end

-- Which pull you're in (1 or 2, 0 outside the pulling) and how far through it (0 to 1).
function Crawling.pull(t: number): (number, number)
	local s = t - Crawling.Drop
	if s < 0 or s >= Crawling.Through then
		return 0, 0
	end
	local x = s / Crawling.Through * Crawling.Pulls
	local i = math.floor(x)
	return i + 1, x - i
end

--[[
	Your view `t` seconds in: its pitch (radians, negative looking down), how far your head dips
	(studs), its roll (radians), and how far your head lifts off the floor to look ahead.
]]
function Crawling.view(t: number): (number, number, number, number)
	if t < Crawling.Drop then
		local k = smooth(t / Crawling.Drop)
		return Crawling.LookDrop * k, 0, 0, Crawling.EyeLift * k
	end
	local s = t - Crawling.Drop
	if s < Crawling.Through then
		local i, phase = Crawling.pull(t)
		local k = smooth(s / (Crawling.Through * 0.3)) -- eyes coming up off the hole's lip
		local look = Crawling.LookDrop + (Crawling.LookThrough - Crawling.LookDrop) * k
		local wave = math.sin(math.pi * phase)
		local side = if i % 2 == 1 then 1 else -1
		return look, Crawling.Bob * wave, Crawling.Roll * wave * side, Crawling.EyeLift
	end
	local k = smooth((s - Crawling.Through) / Crawling.Rise)
	return Crawling.LookThrough * (1 - k), 0, 0, Crawling.EyeLift * (1 - k)
end

-- A crawler's shoulders `t` seconds in (right, left, radians about X) and how much of that pose
-- shows over their animation (0 to 1): arms up past the head, hauling one then the other.
function Crawling.arms(t: number): (number, number, number)
	if t < Crawling.Drop then
		return Crawling.ArmReach, Crawling.ArmReach, smooth(t / Crawling.Drop)
	end
	local s = t - Crawling.Drop
	if s < Crawling.Through then
		local x = s / Crawling.Through * Crawling.Pulls
		local haul = Crawling.ArmSwing * math.sin(math.pi * x)
		return Crawling.ArmReach - haul, Crawling.ArmReach + haul, 1
	end
	local k = smooth((s - Crawling.Through) / Crawling.Rise)
	return Crawling.ArmReach, Crawling.ArmReach, 1 - k
end

--[[
	When your root first reaches `along` (seconds into the move), found by halving: the pulls'
	surge has no neat inverse. Only for points the pulling passes (StartAlong to EndAlong).
]]
function Crawling.reaches(along: number): number
	local lo, hi = 0, 1
	local span = Crawling.EndAlong - Crawling.StartAlong
	for _ = 1, 30 do
		local mid = (lo + hi) / 2
		if Crawling.StartAlong + span * Crawling.progress(mid) < along then
			lo = mid
		else
			hi = mid
		end
	end
	return Crawling.Drop + (lo + hi) / 2 * Crawling.Through
end

-- A stretch of a recording (as Sawing's): played once from `from` for `length` seconds.
export type Sound = {
	id: string,
	from: number,
	length: number,
	volume: number,
	pitch: number,
	near: number, -- full volume within this
	reach: number, -- heard to this many studs
}

Crawling.Sounds = {
	-- Pro Sound Effects' "Body Fall Master 28": one hard body hit on the floor at 0 s (-6 dB),
	-- rolling to 0.5 s: you dropping onto your belly
	Thud = {
		id = "rbxassetid://9113475819",
		from = 0,
		length = 0.55,
		volume = 0.55,
		pitch = 1.05,
		near = 6,
		reach = Crawling.Heard,
	} :: Sound,
	-- Pro Sound Effects' "Sand Bag Slide 6": its middle slide, 0.62 to 1.05 s (-30 to -18 dB, no
	-- hit): a body hauled over concrete, once per pull
	Drag = {
		id = "rbxassetid://9118767703",
		from = 0.62,
		length = 0.43,
		volume = 1.8,
		pitch = 1.05,
		near = 6,
		reach = Crawling.Heard,
	} :: Sound,
	-- Pro Sound Effects' "Metal Scrapes 1": a stretch of its long hollow drag (-12 to -6 dB,
	-- steady from 0.1 s to 5.5 s), a little higher: your shoulders scraping the cut steel
	Steel = {
		id = "rbxassetid://9116818437",
		from = 2,
		length = 0.45,
		volume = 0.5,
		pitch = 1.2,
		near = 6,
		reach = Crawling.Heard,
	} :: Sound,
}
-- The steel's last stretch fades this long rather than stopping dead.
Crawling.Fade = 0.15
-- The second pull's drag a little higher than the first, so two pulls don't sound like one clip.
Crawling.SecondPull = 1.12

-- What plays as the move goes, in order: each `at` seconds in, a sound, how its pitch is turned
-- (times the sound's own), and a kick to the crawler's view (0 for none).
export type Cue = { at: number, sound: Sound, pitch: number, kick: number }

--[[
	The move's cues: your belly hitting the floor as you land at the hole, a drag on each pull, and
	the steel as your shoulders reach the wall.
]]
function Crawling.cues(): { Cue }
	local each = Crawling.Through / Crawling.Pulls
	local list: { Cue } = {
		{
			at = Crawling.Drop * 0.85,
			sound = Crawling.Sounds.Thud,
			pitch = 1,
			kick = Crawling.Thud,
		},
		{
			-- the shoulders (1.5 ahead of the root) at the wall
			at = Crawling.reaches(-1.5),
			sound = Crawling.Sounds.Steel,
			pitch = 1,
			kick = Crawling.Catch,
		},
	}
	for i = 1, Crawling.Pulls do
		table.insert(list, {
			at = Crawling.Drop + (i - 1) * each,
			sound = Crawling.Sounds.Drag,
			pitch = if i % 2 == 0 then Crawling.SecondPull else 1,
			kick = 0,
		})
	end
	table.sort(list, function(a: Cue, b: Cue): boolean
		return a.at < b.at
	end)
	return list
end

return Crawling
