--!strict
--[[
	Kept: getting kept (L-07a, the GDD's "Getting kept"), as pure rules the server's KeptPlayers
	uses. Pure, so Lune tests it (tests/kept.spec.luau).

	The moment: the keeper's hands close, its face rushes you and the screen goes black (`Caught`),
	and you wake wrapped in a unit somewhere on the floor, the door down in front of you, until a
	friend lets you out. Dead by Daylight's hook and Flee the Facility's freeze pods are the
	precedent: caught, stored, a teammate frees you. Stored in a random unit and never the nearest
	is the GDD's own twist on the hook, so friends have to look.

	Which unit: one whose door is all the way down (not padlocked, not open), with no keeper in it
	(nor the guard's place, D-072) and nobody kept in it already. Never the nearest of those to
	where you were caught while another will do. One nobody has seen into ahead of one that's been
	opened, so you're behind a door friends haven't tried yet, and it holds only you.
]]

local Kept = {}

-- The player attribute the server sets while they're kept (true) and clears when they're let
-- out: keepers leave them alone, and doors, tools, crawls and ladders refuse them. Only the
-- server sets it, so a screen can read it but never fake it.
Kept.Attribute = "Kept"

-- How far into the unit you wake, a share of its depth from the door: past the middle, so the
-- door fills your view and the dark sits between you and it, and off the back wall.
Kept.Back = 0.62

-- Banging (L-07c): alone in the dark, wrapped, you hammer on your door. Down the hall your
-- friends hear it thud and see which door, and so might a keeper. Dead by Daylight's hook is the
-- precedent: everyone sees where you hang, and a teammate comes.

-- Where a kept player's press reaches the server: ReplicatedStorage.Remotes.Bang. It carries
-- nothing; the server knows who's kept and where.
Kept.BangRemote = "Bang"
-- Seconds between bangs that land: the door's own jolt (0.5 s, `Motion`) plays out whole each
-- time, so mashing the button gives two heavy thuds a second, never a rattle.
Kept.BangEvery = 0.55
-- Seconds of that gap the server forgives: presses sent a full gap apart can arrive closer on a
-- jittery connection. Anything faster is a spam and is refused.
Kept.BangSlack = 0.15
-- Seconds each bang marks your unit on friends' screens and the corner map: long enough for a
-- friend mid-hall to look up, find it and set off. The last `BangFade` of it fades out.
Kept.BangMark = 8
Kept.BangFade = 2
-- How hard each press jolts your own view, at once; the door's own shake follows with its thud.
Kept.BangKick = 0.14
-- Seconds the Bang button takes to come up once the screen has opened on the inside.
Kept.BangIn = 1
-- A keeper hears a kept player's bang as far as it hears a trapped keeper's: the same door's
-- thud (DoorSound's Bang, 70 studs along the halls, D-092's hearing).

-- On a laid floor's model (the one the corner map reads, `Minimap.Tag`), from the server: its
-- units' latest bangs (`encodeBangs`), so every screen marks them however far off they are.
Kept.BangsAttribute = "KeptBangs"
-- Under a kept player, from the server once they're inside their unit: an ObjectValue holding
-- it, so their own screen can draw the hall's light under its door.
Kept.InsideValue = "KeptIn"

-- One unit's latest bang: its slot on the floor (what the corner map names it by), who banged
-- (a UserId), when (the server's clock) and where its door's outer face meets the floor.
export type Bang = { slot: number, user: number, at: number, x: number, y: number, z: number }

--- Whether a bang may land at `now` after the last one at `last` (nil: none yet). `slack` (the
--- server's `BangSlack`) forgives a little; a screen asks with none, so it never sends early.
function Kept.ready(last: number?, now: number, slack: number?): boolean
	return last == nil or now - last >= Kept.BangEvery - (slack or 0)
end

--- How strongly a unit is marked `since` seconds after its latest bang: 1, then fading to 0
--- over the last `BangFade` of `BangMark`. A clock a little behind the server's reads as fresh.
function Kept.mark(since: number): number
	if since >= Kept.BangMark then
		return 0
	end
	return math.clamp((Kept.BangMark - since) / Kept.BangFade, 0, 1)
end

--- The bangs still marking units at `now`, as text for the floor's attribute, in slot order:
--- `slot,user,at,x,y,z` joined by `;`.
function Kept.encodeBangs(bangs: { [number]: Bang }, now: number): string
	local slots: { number } = {}
	for slot, b in bangs do
		if Kept.mark(now - b.at) > 0 then
			table.insert(slots, slot)
		end
	end
	table.sort(slots)
	local parts: { string } = {}
	for _, slot in slots do
		local b = bangs[slot]
		table.insert(
			parts,
			string.format("%d,%d,%.2f,%.1f,%.1f,%.1f", b.slot, b.user, b.at, b.x, b.y, b.z)
		)
	end
	return table.concat(parts, ";")
end

--- The bangs in `text` (`encodeBangs`'), skipping any that don't read.
function Kept.decodeBangs(text: string): { Bang }
	local out: { Bang } = {}
	for _, part in string.split(text, ";") do
		local f = string.split(part, ",")
		if #f == 6 then
			local n: { number } = {}
			for i = 1, 6 do
				local v = tonumber(f[i])
				if v == nil or v ~= v then
					break
				end
				n[i] = v
			end
			if #n == 6 and n[1] >= 1 and n[1] % 1 == 0 then
				table.insert(
					out,
					{ slot = n[1], user = n[2], at = n[3], x = n[4], y = n[5], z = n[6] }
				)
			end
		end
	end
	return out
end

-- A unit as the choice sees it: where it stands on the floor (x, z: any one frame, the catch's
-- too), whether its door is all the way down and not padlocked (`shut`), whether anyone has seen
-- into it (`dealt`), whether a keeper is in it or the guard's place is kept there (`keeper`), and
-- whether someone is kept in it now (`holding`).
export type Unit = {
	x: number,
	z: number,
	shut: boolean,
	dealt: boolean,
	keeper: boolean,
	holding: boolean,
}

-- Brix's Random, as `Floor` takes it.
export type Random = {
	nextNumber: (self: any) -> number,
	nextInteger: (self: any, min: number, max: number) -> number,
}

-- The wrap you can see (L-07b): clear stretch film in bands round you head to foot, drawn in
-- Blender round Roblox's default R15 body (art/keptwrap, its numbers in `KeptWrap.Specs`) and
-- scaled per axis to the kept one's box, so friends who open your unit find you wrapped.

-- The film's part in a kept character, and its template's name under ReplicatedStorage.Props.
Kept.Wrap = "KeptWrap"

-- The film's part Transparency. Its see-through look is its colour map's alpha (AlphaMode
-- Transparency), but Roblox only blends that alpha on a part above 0 Transparency; at 0 it cuts
-- the film into hard white shreds (seen in Studio, docs/STUDIO.md). Just above 0, so it blends.
Kept.WrapBlend = 0.02

-- A box as the wrap's fit reads it: its size and its middle (x, y, z, studs), from the
-- character's root, in the root's frame.
export type Box = { size: { number }, centre: { number } }

-- How far the wrap stretches or shrinks on any one axis to fit a body. Past these a body is
-- something odd (a part as wide as a hall, or none at all), and the wrap keeps a person's shape.
Kept.FitMin = 0.5
Kept.FitMax = 2.5

--- The wrap's box for a kept `body` at rest: the wrap as drawn (`wrap`) round the body it was
--- drawn round (`drawn`), stretched on each axis by how much bigger `body` is, and moved with it.
function Kept.fit(body: Box, drawn: Box, wrap: Box): Box
	local size: { number }, centre: { number } = {}, {}
	for i = 1, 3 do
		local s = if body.size[i] > 0 and drawn.size[i] > 0
			then math.clamp(body.size[i] / drawn.size[i], Kept.FitMin, Kept.FitMax)
			else 1
		size[i] = wrap.size[i] * s
		centre[i] = (if body.size[i] > 0 then body.centre[i] else drawn.centre[i])
			+ (wrap.centre[i] - drawn.centre[i]) * s
	end
	return { size = size, centre = centre }
end

-- The film's squeal as the keeper wraps you (L-07b), through the black: a tape screeching off
-- its roll, heard by you in the dark and from where you stood by anyone near. Pro Sound
-- Effects' "Duct Tape Richard Epilates Himself 2": a steady peel from 0.6 to 2.6 s at -24 to
-- -12 dB, centred near 1.5 kHz (measured, docs/STUDIO.md); a touch slow, so it drags.
Kept.Squeal = {
	id = "rbxassetid://9114200236",
	from = 0.6,
	length = 1.9,
	volume = 1.6,
	pitch = 0.92,
}
-- Studs the squeal carries from where you were caught: down your stretch of hall, not the floor.
Kept.SquealReach = 45

-- The film winding on (L-06c2), on every screen but the caught one's: as a pallet wrapper's
-- turntable spins a load in film, the caught body turns once round while the film climbs it from
-- the feet and clouds over it, in the time their own screen shows its face rushing them
-- (`Caught.Dark`, passed in by the screen). The last a friend sees of them before they're gone.
-- How many times round they turn.
Kept.WindTurns = 1
-- How much of the film's height is on at the start, from the feet: a band round the ankles.
Kept.WindFrom = 0.12
-- How much of the wind the film takes to cloud in from clear.
Kept.WindCloud = 0.35

--- The film winding on, `t` of the way through (0 to 1): how much of its height is on (from the
--- feet, climbing fast and settling over the head), how far round the body has turned (radians,
--- spinning up and slowing to a stop facing the way it began) and how clear the film still is
--- (1 unseen, 0 as it's drawn).
function Kept.wind(t: number): (number, number, number)
	t = math.clamp(t, 0, 1)
	local up = 1 - (1 - t) * (1 - t)
	local rise = Kept.WindFrom + (1 - Kept.WindFrom) * up
	local turn = 2 * math.pi * Kept.WindTurns * t * t * (3 - 2 * t)
	local clear = 1 - math.min(t / Kept.WindCloud, 1)
	return rise, turn, clear
end

-- Cut free (L-07d): a friend at your open door holds Cut free and tears the film off you, as Dead
-- by Daylight's teammate lifts you off the hook. While they hold, the film strains round you
-- (`Pull`); when the hold lands it rips (`Rip`), shreds burst toward them, and the wrap slumps
-- down your body to a heap at your ankles over a beat (`Tear`), then fades. You're on your feet
-- the moment it rips.

-- Seconds a friend holds Cut free: long enough to mean it, short enough with a keeper near.
Kept.CutHold = 1
-- Seconds of that hold the server forgives: the hold's start and its end reach it with the same
-- lag, but either can arrive a little late on a jittery connection.
Kept.CutSlack = 0.25
-- Studs from the cut point a friend's Cut free shows: from the doorway of a big unit, or anywhere
-- inside a small one. The server forgives `CutReachSlack` more (a friend stepping as the hold
-- lands, a position a moment old).
Kept.CutReach = 7
Kept.CutReachSlack = 2
-- The cut point, from the kept body's root: a little up and out in front of the chest, toward
-- the door, so the button sits on the film where a friend's hands would grab it, clear of the
-- body for the button's line of sight.
Kept.CutUp = 0.6
Kept.CutAhead = 1.2
-- Studs into the hall in front of the unit a friend may stand and still cut: a stride.
Kept.CutOut = 3
-- The button's one word for what it does.
Kept.CutText = "Cut free"

-- What stops a cut, as the server judges a friend's Cut free when the hold lands: the cutter is
-- the kept player (`Self`), kept too (`Kept`), down or bodiless (`Dead`); the kept player isn't
-- in their unit yet (`Away`, still in the black on the way) or their door isn't all the way up
-- (`Shut`); the hold was too short (`Short`); the cutter isn't in front of the unit or in it
-- (`Outside`: through a wall, on the tops) or is too far from the cut point (`Far`).
export type CutRefusal = "Self" | "Kept" | "Dead" | "Away" | "Shut" | "Short" | "Outside" | "Far"

-- A friend's Cut free as the server sees it when the hold lands. Places are in the kept unit's
-- frame: `x` across the door from its middle, `y` up from the floor, `z` in from the door's outer
-- face (the hall is below 0).
export type Cut = {
	self: boolean, -- the cutter is the kept player
	alive: boolean, -- the cutter's body stands, its health above 0
	kept: boolean, -- the cutter is kept too
	inside: boolean, -- the kept player stands in their unit
	open: boolean, -- the kept player's door is all the way up
	held: number?, -- seconds since the cutter's hold began, nil with none
	at: { number }, -- the cutter's body (its root): x, y, z
	cut: { number }, -- the cut point: x, y, z
	width: number, -- the unit's, wall to wall
	depth: number, -- the unit's, door to back wall
}

--- Whether cut `c` may go: nil when it may, else what stops it (`CutRefusal`).
function Kept.cut(c: Cut): CutRefusal?
	if c.self then
		return "Self"
	elseif c.kept then
		return "Kept"
	elseif not c.alive then
		return "Dead"
	elseif not c.inside then
		return "Away"
	elseif not c.open then
		return "Shut"
	elseif c.held == nil or c.held < Kept.CutHold - Kept.CutSlack then
		return "Short"
	end
	local x, z = c.at[1], c.at[3]
	if math.abs(x) > c.width / 2 or z < -Kept.CutOut or z > c.depth then
		return "Outside"
	end
	local dx, dy, dz = x - c.cut[1], c.at[2] - c.cut[2], z - c.cut[3]
	if math.sqrt(dx * dx + dy * dy + dz * dz) > Kept.CutReach + Kept.CutReachSlack then
		return "Far"
	end
	return nil
end

-- The film's strain while a friend holds Cut free: the wrap's own peel (`Squeal`), slowed and
-- deepened, heard round the body, swelling from a third to full over the hold so the rip lands
-- on a peak. Heard by the kept player too: the one thing of the hold they get (they see none).
Kept.Pull = {
	id = Kept.Squeal.id,
	from = 0.6,
	length = 1.6,
	volume = 1.3,
	pitch = 0.74,
}
Kept.PullReach = 30
-- The strain's volume, a share of `Pull.volume`, `t` seconds into a hold.
function Kept.pull(t: number): number
	return 0.35 + 0.65 * math.clamp(t / Kept.CutHold, 0, 1)
end

-- The rip as the hold lands: Pro Sound Effects' "Plastic Sheet Impacts Rips Paper Tears 9", a
-- sheet torn hard from 0.31 s (a -5 dB peak at once) with bursts to 1.1 s (measured,
-- docs/STUDIO.md): the film tearing open and coming down. Heard down the hall, as the squeal is.
Kept.Rip = {
	id = "rbxassetid://9117625280",
	from = 0.31,
	length = 0.85,
	volume = 1.2,
	pitch = 1,
}
Kept.RipReach = 50
-- The heap landing round your ankles: "Plastic Bag Handling Crunchy Cellophane 8", its crunch
-- from 0.36 s, quiet in the recording (-30 to -35 dB), so turned up. Plays as the slump lands.
Kept.Heap = {
	id = "rbxassetid://9117409739",
	from = 0.36,
	length = 0.6,
	volume = 2.5,
	pitch = 0.9,
}
Kept.HeapReach = 25

-- How hard the rip jolts the freed player's view (the catch's own is 0.85), and the cutter's: a
-- yank on the film they were pulling.
Kept.FreedKick = 0.5
Kept.CutterKick = 0.2
-- Degrees the freed player's view widens as the film falls away (the world opening back up),
-- seconds it takes to open, and to settle back.
Kept.FreedWiden = 7
Kept.WidenIn = 0.12
Kept.WidenOut = 0.7

--- How far open the freed player's view is `t` seconds after the rip, 0 to 1 of `FreedWiden`:
--- snapping open, then easing back.
function Kept.widen(t: number): number
	if t <= 0 or t >= Kept.WidenIn + Kept.WidenOut then
		return 0
	elseif t < Kept.WidenIn then
		return math.sin(math.pi / 2 * t / Kept.WidenIn)
	end
	local u = (t - Kept.WidenIn) / Kept.WidenOut
	return 1 - u * u * (3 - 2 * u)
end
-- Film shreds burst from the tear toward the cutter: how many.
Kept.Shreds = 18
-- Seconds the Bang button takes to fade as you're let out.
Kept.BangOut = 0.3

-- The film coming off, the same on every screen: torn, it bulges (the yank), then slumps down the
-- body under its own weight to a heap at the ankles, settles, lies a moment and fades. Never a
-- vanish. Seconds and shares of the wrap's own size.
Kept.Tear = {
	yank = 0.08, -- the bulge as it's torn
	bulge = 0.12, -- how much wider at the bulge's peak
	fall = 0.48, -- the slump to the ankles, gathering speed as it goes
	heap = 0.16, -- its height once down, a share of its own
	-- the heap gathered round the ankles: narrower than the shoulders it hung from, its loops
	-- lying out in front and behind, so it reads as film where someone stood, not a flat body
	wide = 0.8,
	deep = 1.6,
	settle = 0.14, -- a squash as it lands
	tilt = 11, -- degrees it lists toward the door as it goes
	rest = 0.75, -- lying there
	fade = 0.6, -- fading out
	see = 0.35, -- its part Transparency once down, before it fades
}

-- The wrap `t` seconds after the tear: its height (`squash`), width (`wide`, across the door)
-- and depth (`deep`) as shares of its own, its part Transparency (`see`), and how far it lists
-- (`lean`, 0 upright to 1 the full `Tear.tilt`). Its foot stays on the floor throughout.
export type TearPose = { squash: number, wide: number, deep: number, see: number, lean: number }

--- Seconds from the tear until the wrap is gone.
function Kept.tearLength(): number
	local T = Kept.Tear
	return T.yank + T.fall + T.settle + T.rest + T.fade
end

--- The wrap's pose `t` seconds after the tear (`TearPose`).
function Kept.tearPose(t: number): TearPose
	local T = Kept.Tear
	if t <= 0 then
		return { squash = 1, wide = 1, deep = 1, see = Kept.WrapBlend, lean = 0 }
	elseif t >= Kept.tearLength() then
		return { squash = T.heap, wide = T.wide, deep = T.deep, see = 1, lean = 1 }
	end
	if t < T.yank then
		local u = t / T.yank
		local b = 1 + T.bulge * math.sin(math.pi * u)
		return { squash = 1 - 0.04 * u, wide = b, deep = b, see = Kept.WrapBlend, lean = 0 }
	end
	t -= T.yank
	if t < T.fall then
		local e = (t / T.fall) ^ 2 -- falling: slow off the body, fast at the bottom
		return {
			squash = 0.96 + (T.heap - 0.96) * e,
			wide = 1 + (T.wide - 1) * e,
			deep = 1 + (T.deep - 1) * e,
			see = Kept.WrapBlend + (T.see - Kept.WrapBlend) * e,
			lean = e,
		}
	end
	t -= T.fall
	if t < T.settle then
		local s = math.sin(math.pi * t / T.settle)
		return {
			squash = T.heap * (1 - 0.3 * s),
			wide = T.wide * (1 + 0.06 * s),
			deep = T.deep * (1 + 0.06 * s),
			see = T.see,
			lean = 1,
		}
	end
	t -= T.settle
	local fade = if t <= T.rest then 0 else math.min((t - T.rest) / T.fade, 1)
	return {
		squash = T.heap,
		wide = T.wide,
		deep = T.deep,
		see = T.see + (1 - T.see) * fade * fade,
		lean = 1,
	}
end

-- The wrap's tag (every one the server puts on, so screens find it however it streams in) and
-- its attributes, set by the server: how many friends are holding Cut free on it now
-- (`PullAttribute`), and once it's torn, when (`TornAttribute`, the server's clock), who it freed
-- and who cut (`FreedAttribute`, `CutterAttribute`: UserIds, 0 for none) and which way round it
-- lists (`LeanAttribute`, radians about the up axis from straight toward the door).
Kept.WrapTag = "KeptWrap"
-- When the film went on (the server's clock): at the catch, where they stood (L-06c2).
Kept.WoundAttribute = "KeptWound"
Kept.PullAttribute = "KeptPull"
Kept.TornAttribute = "KeptTorn"
Kept.FreedAttribute = "KeptFreed"
Kept.CutterAttribute = "KeptCutter"
Kept.LeanAttribute = "KeptLean"

-- The padlock (L-07e, the GDD's "Left too long"): left kept too long, the building padlocks your
-- door, and only a friend's bolt cutters get it open again. Dead by Daylight's hook stages are the
-- precedent: wait too long and it gets worse, and everyone can feel the clock. A hand nobody sees
-- works a padlock at your door first (`Handle`), a line counts it down for you and every friend,
-- then the bolt shoots and the shackle clicks shut.

-- Seconds of counted time (`counts`) before the building padlocks you: the GDD's "a few minutes".
-- Long enough for a friend to finish the unit they're in and come; short enough that nobody can
-- leave you for the whole floor.
Kept.PadlockAfter = 150
-- Seconds of warning before it: the hand at your door and the countdown. Enough for a friend a
-- hall or two away to run there; short enough that it's a sprint.
Kept.PadlockWarn = 20
-- A Workspace attribute, read in Studio only: a short clock's whole length in seconds, so a test
-- needn't wait minutes (as DevFloorSeed picks the floor).
Kept.DevPadlock = "DevPadlockSeconds"

-- On a kept player, from the server: the server time the padlock goes on, while its warning runs
-- (nil before it, while the door is up, and once it's on); and true while their door is
-- padlocked (`PadlockedAttribute`), by the building or by hand, until it's cut or they're out.
Kept.WarnAttribute = "KeptWarn"
Kept.PadlockedAttribute = "KeptPadlocked"

--- The padlock's clock for one keep: its length (Studio's short clock when `dev` is a positive
--- number, else `PadlockAfter`) and its warning's lead, never longer than the whole clock.
function Kept.clock(dev: number?): (number, number)
	local after = if dev and dev > 0 then dev else Kept.PadlockAfter
	return after, math.min(Kept.PadlockWarn, after)
end

--- Whether the padlock's clock runs while your door is in `state` (a `Door.State`): only while
--- it's down, shut or open a crack or coming down. Never while it's going up or up (a friend has
--- come: Cut free is on offer), nor once it's padlocked.
function Kept.counts(state: string): boolean
	return state == "Closed" or state == "Peeking" or state == "Closing" or state == "Slamming"
end

--- Whether the building can padlock a door in `state` now: all the way down and still.
function Kept.lockable(state: string): boolean
	return state == "Closed"
end

--- One step of a keep's clock: `left` seconds before the padlock, its warning's `lead`, `dt`
--- seconds on with the door in `state`. Returns the seconds left now, whether the warning shows
--- (the clock counting and inside its lead, or run out with the door not yet down), and whether
--- the padlock goes on now (run out, the door down and still).
function Kept.tick(
	left: number,
	lead: number,
	dt: number,
	state: string
): (number, boolean, boolean)
	local counting = Kept.counts(state)
	if counting then
		left = math.max(left - dt, 0)
	end
	return left, counting and left <= lead, left <= 0 and Kept.lockable(state)
end

--- The whole seconds a countdown shows with `left` to go: up from any fraction (19.2 shows 20),
--- 0 once it's out.
function Kept.seconds(left: number): number
	return math.max(math.ceil(left - 1e-6), 0)
end

-- The hand at your door: Pro Sound Effects' "Keys In Padlock" (keys worked in a padlock on a
-- cage, metal clinking), three takes measured (docs/STUDIO.md): quiet recordings, -24 to -36 dB
-- under clanks to -12, so turned up; a touch slow, so it's a heavy lock on a steel door.
Kept.Handle = {
	-- 4: a clank at 0.35 s, then a long jangle to 2.6 s
	{ id = "rbxassetid://9116176269", from = 0.2, length = 2.4, volume = 2.6, pitch = 0.85 },
	-- 5: a hard clank at once (-6 to -12 dB), then the shackle worked to 1.6 s
	{ id = "rbxassetid://9116176337", from = 0.33, length = 1.35, volume = 2.6, pitch = 0.85 },
	-- 2: a steady working of the keys, 0.25 to 2.45 s
	{ id = "rbxassetid://9116176107", from = 0.25, length = 2.2, volume = 2.6, pitch = 0.85 },
}
-- Studs the hand is heard from the door: your own stretch of hall, so a friend passing knows.
Kept.HandleReach = 40
-- How hard each handling jolts the kept player's own view: the door trembling under the hand.
Kept.HandleKick = 0.06

-- One handling: when it starts (seconds left on the clock), which take, and how loud (a share
-- of the take's volume).
export type Handling = { left: number, take: number, loud: number }

-- The warning's handlings: far apart and quieter at first, closer and louder near the end, as a
-- hand that's found the right key; the last ends about 1.4 s before the bolt, a breath of
-- silence before the click.
Kept.Handlings = {
	{ left = 19.5, take = 1, loud = 0.7 },
	{ left = 14, take = 2, loud = 0.8 },
	{ left = 9.5, take = 3, loud = 0.85 },
	{ left = 6, take = 1, loud = 1 },
	{ left = 3, take = 2, loud = 1 },
} :: { Handling }
-- Seconds between handlings once the time's out with the door not yet down: the hand waits.
Kept.HandleAgain = 3

--- The handlings that start as the clock goes from `before` to `after` seconds left (`after`
--- below `before`), in order: the warning's own, then past 0 one every `HandleAgain`, taking
--- turns at full loudness.
function Kept.handlings(before: number, after: number): { Handling }
	local out: { Handling } = {}
	if after >= before then
		return out
	end
	for _, h in Kept.Handlings do
		if h.left <= before and h.left > after then
			table.insert(out, h)
		end
	end
	if after < 0 then
		-- the marks at -k * HandleAgain (k from 1) with after < mark <= before
		local first = math.max(math.ceil(-before / Kept.HandleAgain), 1)
		local last = math.ceil(-after / Kept.HandleAgain) - 1
		for k = first, last do
			local take = (k - 1) % #Kept.Handle + 1
			table.insert(out, { left = -k * Kept.HandleAgain, take = take, loud = 1 })
		end
	end
	return out
end

-- The click shut, on the kept player's screen as the shackle snaps (DoorSound's PadlockShut,
-- `DoorSound.lockCues`): their view jolts and a low hit sounds, APM's "Evil Mind 9" (dark, from
-- 0.1 s, loud to 0.8 s and dying over 3 s; most of it over 150 Hz, so a phone plays it; measured,
-- docs/STUDIO.md). Friends' screens hear it quieter (`DreadFriends`), wherever they are.
Kept.ClickKick = 0.35
Kept.Dread = { id = "rbxassetid://1846887425", from = 0, length = 3.4, volume = 0.9, pitch = 1 }
Kept.DreadFriends = 0.35

--- Whether unit `u` can hold a kept player now.
function Kept.free(u: Unit): boolean
	return u.shut and not u.keeper and not u.holding
end

--- Which of `units` the building stores someone caught at (`x`, `z`) in: its index, or nil when
--- none is free. Never the nearest free one while another will do; an unopened one ahead of one
--- that's been seen into; at random among those.
function Kept.choose(units: { Unit }, x: number, z: number, random: Random): number?
	local free: { number } = {}
	local nearest, best = 0, math.huge
	for i, u in units do
		if Kept.free(u) then
			table.insert(free, i)
			local dx, dz = u.x - x, u.z - z
			local d = dx * dx + dz * dz
			if d < best then
				nearest, best = i, d
			end
		end
	end
	if #free == 0 then
		return nil
	elseif #free == 1 then
		return free[1]
	end
	local unopened: { number } = {}
	local opened: { number } = {}
	for _, i in free do
		if i ~= nearest then
			table.insert(if units[i].dealt then opened else unopened, i)
		end
	end
	local pool = if #unopened > 0 then unopened else opened
	return pool[random:nextInteger(1, #pool)]
end

return table.freeze(Kept)
